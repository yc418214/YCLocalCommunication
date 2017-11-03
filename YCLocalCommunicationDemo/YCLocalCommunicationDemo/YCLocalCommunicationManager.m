//
//  YCLocalCommunicationManager.m
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#import "YCLocalCommunicationManager.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <CFNetwork/CFNetwork.h>

//responseHandler
#import "YCLocalResponseHandler.h"

@interface YCLocalCommunicationManager ()

@property (strong, nonatomic) NSFileHandle *listeningFileHandle;

@property (assign, nonatomic) CFSocketRef socketRef;

// <NSFileHandle *, CFHTTPMessageRef *>
@property (assign, nonatomic) CFMutableDictionaryRef requestDictionaryRef;

@property (strong, nonatomic) NSMutableSet *responseHandlerSet;

@end

@implementation YCLocalCommunicationManager

+ (instancetype)sharedManager {
    static YCLocalCommunicationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YCLocalCommunicationManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestDictionaryRef = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                          0,
                                                          &kCFTypeDictionaryKeyCallBacks,
                                                          &kCFTypeDictionaryValueCallBacks);
        _responseHandlerSet = [NSMutableSet set];
    }
    return self;
}

#pragma mark - public methods

- (void)startListening {
    self.socketRef = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, NULL, NULL);
    if (!self.socketRef) {
        return;
    }
    int reuse = true;
    CFSocketNativeHandle fileDescriptor = CFSocketGetNative(self.socketRef);
    //set socket options
    if (setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR, (void *)&reuse, sizeof(int)) != 0) {
        return;
    }
    struct sockaddr_in socketAddress;
    //fill with 0
    memset(&socketAddress, 0, sizeof(socketAddress));
    socketAddress.sin_len = sizeof(socketAddress);
    socketAddress.sin_family = AF_INET;
    socketAddress.sin_addr.s_addr = htonl(INADDR_ANY);
    socketAddress.sin_port = htons(12345);
    //transform to CFDataRef
    CFDataRef socketAddressDataRef = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&socketAddress, sizeof(socketAddress));
    //set socket address
    if (CFSocketSetAddress(self.socketRef, socketAddressDataRef) != kCFSocketSuccess) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fileHandleDidAcceptConnection:)
                                                 name:NSFileHandleConnectionAcceptedNotification
                                               object:nil];
    
    self.listeningFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:YES];
    [self.listeningFileHandle acceptConnectionInBackgroundAndNotify];
}

- (void)stopListening {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleConnectionAcceptedNotification
                                                  object:nil];
    [self.responseHandlerSet removeAllObjects];
    //release listeningFileHandle
    [self.listeningFileHandle closeFile];
    self.listeningFileHandle = nil;
    
    for (NSFileHandle *receivedFileHandle in [(__bridge NSDictionary *)self.requestDictionaryRef copy]) {
        [self stopReceivingDataForFileHandle:receivedFileHandle close:YES];
    }
    
    if (self.socketRef) {
        CFSocketInvalidate(self.socketRef);
        CFRelease(self.socketRef);
        self.socketRef = nil;
    }
}

#pragma mark - private methods

- (void)fileHandleDidAcceptConnection:(NSNotification *)notification {
    NSLog(@"%@ notification : %@", NSStringFromSelector(_cmd), notification);
    NSFileHandle *receivedFileHandle = notification.userInfo[NSFileHandleNotificationFileHandleItem];
    if (receivedFileHandle) {
        CFDictionaryAddValue(self.requestDictionaryRef,
                             (__bridge const void *)receivedFileHandle,
                             (__bridge const void *)((__bridge id)CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE)));
        //register notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fileHandleDidReceiveAvailableData:)
                                                     name:NSFileHandleDataAvailableNotification
                                                   object:receivedFileHandle];
        //wait for available data
        [receivedFileHandle waitForDataInBackgroundAndNotify];
    }
    [self.listeningFileHandle acceptConnectionInBackgroundAndNotify];
}

- (void)fileHandleDidReceiveAvailableData:(NSNotification *)notification {
    NSLog(@"%@ notification : %@", NSStringFromSelector(_cmd), notification);
    NSFileHandle *receivedFileHandle = notification.object;
    NSData *availableData = receivedFileHandle.availableData;
    if (!availableData || availableData.length == 0) {
        [self stopReceivingDataForFileHandle:receivedFileHandle close:NO];
        return;
    }
    CFHTTPMessageRef requestRef = (CFHTTPMessageRef)CFDictionaryGetValue(self.requestDictionaryRef, (__bridge const void *)receivedFileHandle);
    if (!requestRef) {
        [self stopReceivingDataForFileHandle:receivedFileHandle close:YES];
        return;
    }
    // https://developer.apple.com/documentation/cfnetwork/1387288-cfhttpmessageappendbytes?language=objc
    if (!CFHTTPMessageAppendBytes(requestRef, availableData.bytes, availableData.length)) {
        [self stopReceivingDataForFileHandle:receivedFileHandle close:YES];
        return;
    }
    //header isn't complete
    if (!CFHTTPMessageIsHeaderComplete(requestRef)) {
        [receivedFileHandle waitForDataInBackgroundAndNotify];
        return;
    }
    YCLocalResponseHandler *responseHandler = [YCLocalResponseHandler handlerWithRequest:requestRef
                                                                              fileHandle:receivedFileHandle];
    if (!responseHandler) {
        [self stopReceivingDataForFileHandle:receivedFileHandle close:YES];
        return;
    }
    __weak typeof(self) weakSelf = self;
    responseHandler.stopResponseBlock = ^(YCLocalResponseHandler *responseHandler) {
        [weakSelf.responseHandlerSet removeObject:responseHandler];
    };
    //save handler
    [self.responseHandlerSet addObject:responseHandler];
    //stop receiving data
    [self stopReceivingDataForFileHandle:receivedFileHandle close:NO];
    //response
    [responseHandler startResponse];
}

- (void)stopReceivingDataForFileHandle:(NSFileHandle *)receivedFileHandle close:(BOOL)close {
    if (close) {
        [receivedFileHandle closeFile];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleDataAvailableNotification
                                                  object:receivedFileHandle];
    CFDictionaryRemoveValue(self.requestDictionaryRef, (__bridge const void*)receivedFileHandle);
}

@end
