//
//  ViewController.m
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#import "ViewController.h"

#import "YCLogFileManager.h"
#import "YCLocalCommunicationManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    YCLogFileManager *logFileManager = [YCLogFileManager sharedManager];
    
    NSString *fileOneContent = @"This is file one.";
    [logFileManager writeData:[fileOneContent dataUsingEncoding:NSUTF8StringEncoding] fileName:@"FileOne"];
    NSString *fileTwoContent = @"This is file two.";
    [logFileManager writeData:[fileTwoContent dataUsingEncoding:NSUTF8StringEncoding] fileName:@"FileTwo"];
    
    YCLocalCommunicationManager *localCommunicationManager = [YCLocalCommunicationManager sharedManager];
    [localCommunicationManager startListening];
}

@end
