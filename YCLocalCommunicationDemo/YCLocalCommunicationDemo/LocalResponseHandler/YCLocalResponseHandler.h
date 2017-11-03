//
//  YCLocalResponseHandler.h
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CFNetwork/CFNetwork.h>
//HTTPInfo
#import "YCLocalResponseHTTPInfo.h"

@class YCLocalResponseHandler;

typedef void(^YCLocalResponseHandlerStopResponseBlock)(YCLocalResponseHandler *responseHandler);

@interface YCLocalResponseHandler : NSObject

@property (strong, nonatomic, readonly) YCLocalResponseHTTPInfo *HTTPInfo;

@property (copy, nonatomic) YCLocalResponseHandlerStopResponseBlock stopResponseBlock;

+ (instancetype)handlerWithRequest:(CFHTTPMessageRef)request
                        fileHandle:(NSFileHandle *)fileHandle;

- (void)startResponse;

@end
