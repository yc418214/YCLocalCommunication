//
//  YCLocalResponseHTTPInfo.h
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCLocalResponseHTTPInfo : NSObject

@property (strong, nonatomic) NSDictionary *headerFieldsDictionary;

@property (strong, nonatomic) NSURLComponents *requestURLComponents;

@property (copy, nonatomic) NSString *requestMethod;

+ (instancetype)infoWithRequest:(CFHTTPMessageRef)request;

- (NSString *)queryItemValueForKey:(NSString *)queryItemKey;

@end
