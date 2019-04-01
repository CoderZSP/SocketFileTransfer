//
//  BMJavaDataOutputStream.h
//  BMJavaIOStream
//
//  Created by 李 岩 on 13-6-28.
//  Copyright (c) 2013年 BigMy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMJavaDataOutputStream : NSObject

// 将一个 char 值以 1-byte 值形式写入基础输出流中，先写入高字节。
- (void)writeChar:(int8_t)v;

//将一个 short 值以 2-byte 值形式写入基础输出流中，先写入高字节。
- (void)writeShort:(int16_t)v;

//将一个 int 值以 4-byte 值形式写入基础输出流中，先写入高字节。
- (void)writeInt:(int32_t)v;

//将一个 long 值以 8-byte 值形式写入基础输出流中，先写入高字节。
- (void)writeLong:(int64_t)v;

//以与机器无关方式使用 UTF-8 修改版编码将一个字符串写入基础输出流。
- (void)writeUTF:(NSString *)v;

//将一个 NSData byte数组写入输出流中，先写入高字节。
- (void)writeBytes:(NSData *)v;

- (void)writeBytes2:(NSData *)v;

//将此转换为 byte 序列。
- (NSData *)toByteArray;

// NSDictionary 转byte 序列。
+(NSData *)toByteDataWithDic:(NSDictionary *)param;

-(void)writeBoolaen:(bool)v;

-(void)writeFloat:(float_t)v;
@end
