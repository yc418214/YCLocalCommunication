//
//  YCLocalResponseHandlerSubclass.h
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

//subclass interface, implemented in YCLocalResponseHandler
@interface YCLocalResponseHandler (Subclass)

+ (void)registerClass;

- (NSData *)HTTPHeaderDataWithStatuCode:(NSInteger)statusCode headerFieldDictionary:(NSDictionary<NSString *, NSString *> *)headerFieldDictionary;

@end
