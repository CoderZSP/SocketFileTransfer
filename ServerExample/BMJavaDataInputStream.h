//
//  BMJavaDataInputStream.h
//  BMJavaIOStream
//
//  Created by 李 岩 on 13-6-28.
//  Copyright (c) 2013年 BigMy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMJavaDataInputStream : NSObject

- (id)initWithData:(NSData *)data;

+ (id)dataInputStreamWithData:(NSData *)data;

-(int32_t)read;

- (int8_t)readChar;

- (int16_t)readShort;

- (int32_t)readInt;

- (int64_t)readLong;

- (NSString *)readUTF;

-(float_t)readFloat;

-(NSData *)readData;

-(double)readDouble;

+ (int16_t)readLengthWithData:(NSData *)data;
@end
