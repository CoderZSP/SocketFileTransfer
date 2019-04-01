//
//  BMJavaDataInputStream.m
//  BMJavaIOStream
//
//  Created by 李 岩 on 13-6-28.
//  Copyright (c) 2013年 BigMy. All rights reserved.
//

#import "BMJavaDataInputStream.h"
@interface BMJavaDataInputStream()
{
    NSData *data;
    NSInteger length;
}
@end

@implementation BMJavaDataInputStream
- (id)initWithData:(NSData *)aData {
    self = [self init];
    if(self != nil){
        data = [[NSData alloc] initWithData:aData];
    }
    return self;
}

- (id)init{
    self = [super init];
    if(self != nil){
        length = 0;
    }
    return self;
}

+ (id)dataInputStreamWithData:(NSData *)aData {
    BMJavaDataInputStream *dataInputStream = [[self alloc] initWithData:aData];
    return dataInputStream;
}

- (int32_t)read{
    int8_t v;
    [data getBytes:&v range:NSMakeRange(length,1)];
    length++;
    return ((int32_t)v & 0x0ff);
}

- (int8_t)readChar {
    int8_t v;
    [data getBytes:&v range:NSMakeRange(length,1)];
    length++;
    return (v & 0x0ff);
}

- (int16_t)readShort {
    int32_t ch1 = [self read];
    int32_t ch2 = [self read];
    if ((ch1 | ch2) < 0){
        @throw [NSException exceptionWithName:@"Exception" reason:@"EOFException" userInfo:nil];
    }
    return (int16_t)((ch1 << 8) + (ch2 << 0));
    
}

- (int32_t)readInt {
    if (length==[data length]) {
        return 0;
    }
    int32_t ch1 = [self read];
    int32_t ch2 = [self read];
    int32_t ch3 = [self read];
    int32_t ch4 = [self read];
    if ((ch1 | ch2 | ch3 | ch4) < 0){
        @throw [NSException exceptionWithName:@"Exception" reason:@"EOFException" userInfo:nil];
    }
    return ((ch1 << 24) + (ch2 << 16) + (ch3 << 8) + (ch4 << 0));
}

- (int64_t)readLong {
    int8_t ch[8];
    [data getBytes:&ch range:NSMakeRange(length,8)];
    length = length + 8;
    
    return (((int64_t)ch[0] << 56) +
            ((int64_t)(ch[1] & 255) << 48) +
            ((int64_t)(ch[2] & 255) << 40) +
            ((int64_t)(ch[3] & 255) << 32) +
            ((int64_t)(ch[4] & 255) << 24) +
            ((ch[5] & 255) << 16) +
            ((ch[6] & 255) <<  8) +
            ((ch[7] & 255) <<  0));
    
}

- (NSString *)readUTF {
    if (length==[data length]-4) {
        return nil;
    }
    short utfLength = [self readShort];
    NSData *d = [data subdataWithRange:NSMakeRange(length,utfLength)];
    NSString *str = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    length = length + utfLength;
    return str;
}




-(float_t)readFloat
{
    NSSwappedFloat bigEndianFloat;
    NSData *d = [data subdataWithRange:NSMakeRange(length,4)];
    memcpy(&bigEndianFloat, [d bytes], 4);
    float floatValue = NSSwapBigFloatToHost(bigEndianFloat);
    length+=4;
    return floatValue;
}

-(NSData *)readData
{
    int dataLen=[self readInt];
    
    NSRange range=NSMakeRange(length, dataLen);
    UInt8 bytes[range.length];
    [data getBytes:&bytes range:range];
    NSData *subedSourceBin = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    length+=dataLen;
    
    return subedSourceBin;
}

-(double)readDouble
{
    Byte buf[8];
    double resultDouble=0.0;
    [data getBytes:&buf range:NSMakeRange(length, 8)];
    length+=8;
    
    Byte tempBuf[8];
	for (int i=0; i<8; i++) {
		tempBuf[i] = buf[i];
	}
	for (int i=0; i<8; i++) {
		buf[i] = tempBuf[7-i];
	}
    
    NSData *tempData=[[NSData alloc] initWithBytes:buf length:8];
    [tempData getBytes:&resultDouble length:8];
    return resultDouble;
}


+ (int16_t)readLengthWithData:(NSData *)data
{
    BMJavaDataInputStream *stream = [[self alloc] initWithData:data];
    int16_t length = [stream readShort];
    return length;
}
@end
