//
//  NSString+Extension.h
//  ServerExample
//
//  Created by zhangsp on 2019/3/5.
//  Copyright © 2019 zsp. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Extension)

// 获取设备IP地址
+(NSString *)getIPAddress;

-(NSString *)base64EncodeString;

-(NSString *)base64DecodeString;

+ (long long)fileSizeAtPath:(NSString*)filePath;

/** 根据文件路径 获取文件md5 */
+ (NSString *)md5WithFilePath:(NSString *)filePath;
@end

NS_ASSUME_NONNULL_END
