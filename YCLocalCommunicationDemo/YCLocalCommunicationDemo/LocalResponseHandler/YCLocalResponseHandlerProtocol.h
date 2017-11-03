//
//  YCLocalResponseHandlerProtocol.h
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#ifndef YCLocalResponseHandlerProtocol_h
#define YCLocalResponseHandlerProtocol_h

@protocol YCLocalResponseHandlerProtocol <NSObject>

+ (BOOL)canHandleResponseWithURLPathString:(NSString *)URLPathString;

- (NSData *)headerDataWithContentLength:(NSUInteger)contentLength;

- (NSData *)bodyData;

@end

#endif /* YCLocalResponseHandlerProtocol_h */
