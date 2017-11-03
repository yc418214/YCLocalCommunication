//
//  YCLocalResponseHandler.m
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#import "YCLocalResponseHandler.h"

//protocol
#import "YCLocalResponseHandlerProtocol.h"
//subclass
#import "YCLocalResponseHandlerSubclass.h"
//key
#import "YCLocalLogFileResponseHandlerKey.h"

static NSMutableArray *registerHandlerClassesArray;

@interface YCLocalResponseHandler () <YCLocalResponseHandlerProtocol>

@property (strong, nonatomic, readwrite) YCLocalResponseHTTPInfo *HTTPInfo;

@property (strong, nonatomic) NSFileHandle *fileHandle;

@end

@implementation YCLocalResponseHandler

+ (void)load {
    [self registerClass];
}

+ (instancetype)handlerWithRequest:(CFHTTPMessageRef)request fileHandle:(NSFileHandle *)fileHandle {
    YCLocalResponseHTTPInfo *HTTPInfo = [YCLocalResponseHTTPInfo infoWithRequest:request];
    NSString *requestURLPath = HTTPInfo.requestURLComponents.URL.path;
    Class handlerClass = [self handlerClassWithURLPathString:requestURLPath];
    if (!handlerClass) {
        NSLog(@"no handler can response to URL : %@ path : %@", HTTPInfo.requestURLComponents.URL, requestURLPath);
        return nil;
    }
    YCLocalResponseHandler *responseHandler = [[handlerClass alloc] init];
    responseHandler.HTTPInfo = HTTPInfo;
    responseHandler.fileHandle = fileHandle;
    return responseHandler;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self configFileHandle];
    }
    return self;
}

- (void)dealloc {
    [self stopResponse];
}

#pragma mark - public methods

- (void)startResponse {
    YCLocalResponseHTTPInfo *HTTPInfo = self.HTTPInfo;
    NSLog(@"%@ URL : %@, METHOD : %@", NSStringFromSelector(_cmd), HTTPInfo.requestURLComponents.URL, HTTPInfo.requestMethod);
    
    NSData *bodyData = [self bodyData];
    NSData *headerData = [self headerDataWithContentLength:bodyData.length];
    
    @try {
        [self.fileHandle writeData:headerData];
        [self.fileHandle writeData:bodyData];
    } @catch (NSException *exception) {
        NSLog(@"response error : %@", exception);
    } @finally {
        [self stopResponse];
    }
}

#pragma mark - private methods

+ (Class)handlerClassWithURLPathString:(NSString *)URLPathString {
    for (Class handlerClass in registerHandlerClassesArray) {
        if ([handlerClass canHandleResponseWithURLPathString:URLPathString]) {
            return handlerClass;
        }
    }
    return nil;
}

- (void)configFileHandle {
    //go on waiting for data
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fileHandleDidReceiveAvailableData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:_fileHandle];
    [_fileHandle waitForDataInBackgroundAndNotify];
}

- (void)fileHandleDidReceiveAvailableData:(NSNotification *)notification {
    NSFileHandle *fileHandle = notification.object;
    NSData *availableData = fileHandle.availableData;
    if (!availableData || availableData.length == 0) {
        [self stopResponse];
        return;
    }
    [fileHandle waitForDataInBackgroundAndNotify];
}

- (void)stopResponse {
    if (_fileHandle) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSFileHandleDataAvailableNotification
                                                      object:_fileHandle];
        [_fileHandle closeFile];
        _fileHandle = nil;
    }
    if (_stopResponseBlock) {
        _stopResponseBlock(self);
    }
}

- (NSString *)homePageHTMLString {
    NSString *bodyLineString =
    [NSString stringWithFormat:@"<div align=\"center\">\r\n<a target=\"_self\" href=\"/%@/\">%@</a>\r\n</div>", kURLPathLogFileKey, @"Log files list"];
    NSString *homePageHTMLString =
    [NSString stringWithFormat:@"<!DOCTYPE html>\r\n<html>\r\n<head>\r\n<meta charset=\"utf-8\">\r\n<title>Local</title>\r\n</head>\r\n<body>\r\n%@\r\n</body>\r\n</html>", bodyLineString];
    return homePageHTMLString;
}

#pragma mark - YCLocalResponseHandlerSubclass

+ (void)registerClass {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registerHandlerClassesArray = [NSMutableArray array];
    });
    [registerHandlerClassesArray addObject:[self class]];
}

- (NSData *)HTTPHeaderDataWithStatuCode:(NSInteger)statusCode headerFieldDictionary:(NSDictionary<NSString *, NSString *> *)headerFieldDictionary {
    CFHTTPMessageRef headerMessageRef = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, NULL, kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(headerMessageRef, (__bridge CFStringRef)@"Connection", (__bridge CFStringRef)@"close");
    [headerFieldDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        CFHTTPMessageSetHeaderFieldValue(headerMessageRef, (__bridge CFStringRef)key, (__bridge CFStringRef)obj);
    }];
    CFDataRef headerDataRef = CFHTTPMessageCopySerializedMessage(headerMessageRef);
    //handle memory by ARC, no need to release headerDataRef
    NSData *headerData = (__bridge_transfer NSData *)headerDataRef;
    CFRelease(headerMessageRef);
    return headerData;
}

#pragma mark - YCLocalResponseHandlerProtocol

+ (BOOL)canHandleResponseWithURLPathString:(NSString *)URLPathString {
    return [URLPathString isEqualToString:@"/"];
}

- (NSData *)headerDataWithContentLength:(NSUInteger)contentLength {
    NSDictionary *headerFieldDictionary = @{ @"Content-Type" : @"text/html",
                                             @"Content-Length" : [NSString stringWithFormat:@"%zd", contentLength] };
    return [self HTTPHeaderDataWithStatuCode:200 headerFieldDictionary:headerFieldDictionary];
}

- (NSData *)bodyData {
    NSString *homePageHTMLString = [self homePageHTMLString];
    return [homePageHTMLString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
