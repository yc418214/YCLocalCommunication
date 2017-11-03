//
//  YCLocalResponseHTTPInfo.m
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#import "YCLocalResponseHTTPInfo.h"

@implementation YCLocalResponseHTTPInfo

+ (instancetype)infoWithRequest:(CFHTTPMessageRef)request {
    YCLocalResponseHTTPInfo *info = [[YCLocalResponseHTTPInfo alloc] init];
    info.headerFieldsDictionary = (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(request);
    NSURL *requestURL = (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL(request);
    info.requestURLComponents = [NSURLComponents componentsWithURL:requestURL resolvingAgainstBaseURL:YES];
    info.requestMethod = (__bridge_transfer NSString *)CFHTTPMessageCopyRequestMethod(request);
    return info;
}

- (NSString *)queryItemValueForKey:(NSString *)queryItemKey {
    __block NSString *queryItemValue;
    [self.requestURLComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem *queryItem, NSUInteger idx, BOOL *stop) {
        if ([queryItem.name isEqualToString:queryItemKey]) {
            queryItemValue = queryItem.value;
            *stop = YES;
        }
    }];
    return queryItemValue;
}

@end
