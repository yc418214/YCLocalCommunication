//
//  YCLocalCommunicationManager.h
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCLocalCommunicationManager : NSObject

+ (instancetype)sharedManager;

- (void)startListening;

- (void)stopListening;

@end
