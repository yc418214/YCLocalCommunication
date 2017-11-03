//
//  YCLocalLogFileResponseHandler.m
//  YCLocalCommunicationDemo
//
//  Created by 陈煜钏 on 2017/11/3.
//  Copyright © 2017年 陈煜钏. All rights reserved.
//

#import "YCLocalLogFileResponseHandler.h"

//subclass
#import "YCLocalResponseHandlerSubclass.h"
//key
#import "YCLocalLogFileResponseHandlerKey.h"
//logFile
#import "YCLogFileManager.h"

@interface YCLocalLogFileResponseHandler ()

@property (strong, nonatomic) YCLogFileManager *logFileManager;

@end

@implementation YCLocalLogFileResponseHandler

+ (void)load {
    [self registerClass];
}

#pragma mark - YCLocalResponseHandlerProtocol

+ (BOOL)canHandleResponseWithURLPathString:(NSString *)URLPathString {
    return [URLPathString isEqualToString:[NSString stringWithFormat:@"/%@", kURLPathLogFileKey]];
}

- (NSData *)headerDataWithContentLength:(NSUInteger)contentLength {
    NSString *fileName = [self queryFileName];
    NSString *contentTypeString = (fileName && fileName.length != 0) ? @"text/plain" : @"text/html";
    NSDictionary *headerFieldDictionary = @{ @"Content-Type" : contentTypeString,
                                             @"Content-Length" : [NSString stringWithFormat:@"%zd", contentLength] };
    return [self HTTPHeaderDataWithStatuCode:200 headerFieldDictionary:headerFieldDictionary];
}

- (NSData *)bodyData {
    NSString *fileName = [self queryFileName];
    if (!fileName || fileName.length == 0) {
        return [self fileListData];
    }
    return [self fileContentDataWithFileName:fileName];
}

#pragma mark - private methods

- (NSData *)fileListData {
    NSMutableArray *bodyLineStringArray = [NSMutableArray array];
    NSArray *fileNamesArray = [self.logFileManager allLogFileNamesArray];
    for (NSString *fileName in fileNamesArray) {
        NSString *bodyLineString =
        [NSString stringWithFormat:@"<div align=\"center\">\r\n<a target=\"_blank\" href=\"/%@?%@=%@\">%@</a>\r\n</div>",
         kURLPathLogFileKey, KURLQueryItemFileNameKey, fileName, fileName];
        [bodyLineStringArray addObject:bodyLineString];
    }
    NSString *bodyContent = [[bodyLineStringArray copy] componentsJoinedByString:@"\r\n"];
    NSString *fileListHTMLString =
    [NSString stringWithFormat:@"<!DOCTYPE html>\r\n<html>\r\n<head>\r\n<meta charset=\"utf-8\">\r\n<title>日志列表</title>\r\n</head>\r\n<body>\r\n%@\r\n</body>\r\n</html>", bodyContent];
    return [fileListHTMLString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)fileContentDataWithFileName:(NSString *)fileName {
    NSString *filePath = [self.logFileManager filePathWithName:fileName];
    return [NSData dataWithContentsOfFile:filePath];
}

- (NSString *)queryFileName {
    return [self.HTTPInfo queryItemValueForKey:KURLQueryItemFileNameKey];
}

#pragma mark - getter

- (YCLogFileManager *)logFileManager {
    if (_logFileManager) {
        return _logFileManager;
    }
    _logFileManager = [YCLogFileManager sharedManager];
    return _logFileManager;
}

@end
