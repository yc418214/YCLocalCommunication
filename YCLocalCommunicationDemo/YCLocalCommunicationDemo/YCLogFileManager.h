//
//  YCLogFileManager.h
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCLogFileManager : NSObject

+ (instancetype)sharedManager;

- (void)writeData:(NSData *)fileData fileName:(NSString *)fileName;

- (NSArray<NSString *> *)allLogFileNamesArray;

- (NSString *)filePathWithName:(NSString *)fileName;

@end
