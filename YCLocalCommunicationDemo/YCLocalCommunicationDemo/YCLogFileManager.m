//
//  YCLogFileManager.m
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#import "YCLogFileManager.h"

@interface YCLogFileManager ()

@property (strong, nonatomic) NSFileManager *fileManager;

@property (copy, nonatomic) NSString *fileDirectoryPath;

@end

@implementation YCLogFileManager

+ (instancetype)sharedManager {
    static YCLogFileManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YCLogFileManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
        [self configFileDirectory];
    }
    return self;
}

#pragma mark - public methods

- (void)writeData:(NSData *)fileData fileName:(NSString *)fileName {
    if (!fileData || fileData.length == 0) {
        return;
    }
    if (!self.fileDirectoryPath) {
        return;
    }
    [fileData writeToFile:[self filePathWithName:fileName] atomically:YES];
}

- (NSArray<NSString *> *)allLogFileNamesArray {
    NSMutableArray *fileNamesArray = [NSMutableArray array];
    NSArray *filePathsArray = [self.fileManager contentsOfDirectoryAtPath:self.fileDirectoryPath error:NULL];
    for (NSString *filePath in filePathsArray) {
        [fileNamesArray addObject:filePath.lastPathComponent];
    }
    return [fileNamesArray copy];
}

- (NSString *)filePathWithName:(NSString *)fileName {
    return [self.fileDirectoryPath stringByAppendingPathComponent:fileName];
}

#pragma mark - private methods

- (void)configFileDirectory {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _fileDirectoryPath = [documentPath stringByAppendingPathComponent:@"LogFile"];
    BOOL isDirectory;
    BOOL isFileDirectoryExist = [_fileManager fileExistsAtPath:_fileDirectoryPath isDirectory:&isDirectory];
    if (!isFileDirectoryExist || !isDirectory) {
        BOOL createDirectory = [_fileManager createDirectoryAtPath:_fileDirectoryPath withIntermediateDirectories:YES attributes:nil error:NULL];
        NSLog(@"createDirectory result : %i", createDirectory);
    }
}

@end
