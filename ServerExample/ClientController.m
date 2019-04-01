//
//  ClientController.m
//  ServerExample
//
//  Created by zhangsp on 2019/3/7.
//  Copyright © 2019 zsp. All rights reserved.
//

#import "ClientController.h"
#import "GCDAsyncSocket.h"
#import "NSString+Extension.h"
#import "MJExtension.h"
#import "BMJavaDataOutputStream.h"
#import "BMJavaDataInputStream.h"
#define kFileName @"2048Mac.dmg"
#define kFilePath [[NSBundle mainBundle] pathForResource:@"2048Mac" ofType:@"dmg"]
#define socketCount 1
@interface ClientController ()
@property (weak, nonatomic) IBOutlet UITextField *ipField;
@property (weak, nonatomic) IBOutlet UITextField *portField;
@property (weak, nonatomic) IBOutlet UITextField *sendMsgField;
@property (weak, nonatomic) IBOutlet UITextView *reciveMsgTextView;


//客户端socket
@property (nonatomic) GCDAsyncSocket *clientSocket;
@property (strong, nonatomic) NSFileHandle *outfile;
@property (strong, nonatomic) NSMutableArray *sections; // startIndex-endIndex-finishIndex
//@property (strong, nonatomic) NSMutableArray *portArray;
@property (strong, nonatomic) NSMutableArray *fileClientSocketArray;
@property (strong, nonatomic) NSMutableArray *fileConnectedSocketArray;
@property (strong, nonatomic) NSString *fileHash;
@property (strong, nonatomic) NSString *fileName;
@property (nonatomic) GCDAsyncSocket *sock;

@property (strong, nonatomic) NSString *addressIP;
@property (strong, nonatomic) NSString *fileInfoPort;
@property (strong, nonatomic) NSString *fileContentPort;
@property (assign, nonatomic) NSInteger totalLength;
@property (assign, nonatomic) NSInteger finishedLength;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) NSMutableArray *fileSocketArray;
@property (strong, nonatomic) NSFileHandle *inFile;
@property (assign, nonatomic) long long devidePart; // 每部分大小
@property (assign, nonatomic) long long fileSize;// 文件大小
@end

@implementation ClientController

-(NSMutableArray *)sections
{
    if (!_sections) {
        NSMutableArray *divideDetailArr = [NSMutableArray array];
        for (int i = 0; i<socketCount; i++) {
            NSInteger startIndex = i*self.devidePart;
            NSInteger endIndex = (i+1)*self.devidePart-1;
            if (i == socketCount-1) {
                endIndex = self.fileSize -1;
            }
            NSInteger finishIndex = startIndex;
            NSMutableDictionary *item = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger: startIndex],@"startIndex",[NSNumber numberWithInteger:endIndex],@"endIndex",[NSNumber numberWithInteger:finishIndex],@"finishIndex",nil] mutableCopy];
            NSString *item2 = [NSString stringWithFormat:@"fileDivideDetail%ld-%ld-%ld",(long)startIndex,(long)endIndex,(long)finishIndex];
            NSLog(@"%@",item2);
            [divideDetailArr addObject:item];
        }
        _sections = divideDetailArr;
    }
    return _sections;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //1、初始化
    self.ipField.text = @"192.168.2.70";
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    self.fileClientSocketArray = [NSMutableArray array];
    self.fileConnectedSocketArray = [NSMutableArray array];
    
    self.fileSocketArray = [NSMutableArray array];
    self.inFile = [NSFileHandle fileHandleForReadingAtPath:kFilePath];
    self.fileSize = [NSString fileSizeAtPath:kFilePath];
    self.devidePart = [NSString fileSizeAtPath:kFilePath] / socketCount;
}

- (IBAction)startSend:(UIButton *)sender {
    [self sendFileInfoType:@1];
}
- (IBAction)suspendSend:(UIButton *)sender {
    //暂停
    for (int i =0; i<self.fileClientSocketArray.count; i++) {
        GCDAsyncSocket *cSocket = self.fileClientSocketArray[i];
        [cSocket disconnect];
    }
    [self.fileClientSocketArray removeAllObjects];
}
- (IBAction)continueSend:(UIButton *)sender {
    // 发送文件信息
    [self sendFileInfoType:@3];
}

// 发送文件信息
-(void)sendFileInfoType:(NSNumber *)type
{
    // 发文件信息
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:type,@"type", nil];
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
    [dataDic setValue:kFileName forKey:@"fileName"];
    [dataDic setValue:[NSString stringWithFormat:@"%lld",[NSString fileSizeAtPath:kFilePath]] forKey:@"fileSize"];
    
    [dataDic setValue:[NSString md5WithFilePath:kFilePath] forKey:@"fileHash"];
//    [dataDic setValue:self.sections forKey:@"sections"];
    // 传输文件socket 端口号
    [dic setValue:dataDic forKey:@"data"];

    [self.clientSocket writeData:[BMJavaDataOutputStream toByteDataWithDic:dic] withTimeout:-1 tag:0];
}




- (IBAction)linkButtonAction:(id)sender {
    //连接服务器
    self.addressIP = self.ipField.text;
    self.fileInfoPort = self.portField.text;
    [self.clientSocket connectToHost:self.ipField.text onPort:self.portField.text.integerValue withTimeout:-1 error:nil];
    
}
- (IBAction)sendMsgButtonAction:(id)sender {
    NSData *data = [self.sendMsgField.text dataUsingEncoding:NSUTF8StringEncoding];
    //withTimeout -1 :无穷大
    //tag： 消息标记
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
    
}

- (void)showMessageWithText:(NSString *)text {
    self.reciveMsgTextView.text = [self.reciveMsgTextView.text stringByAppendingFormat:@"%@\n", text];
}

-(void)updateFinishedLength
{
    NSInteger finishTotal = 0;
    for (int i =0; i < self.sections.count; i++) {
        NSMutableDictionary *item = self.sections[i];
        NSInteger length = ((NSNumber *)item[@"finishIndex"]).integerValue - ((NSNumber *)item[@"startIndex"]).integerValue;
        finishTotal += length;
    }
    self.finishedLength = finishTotal;
}

#pragma mark - GCDAsynSocket Delegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    if (port != self.fileInfoPort.integerValue) {
        [self.fileConnectedSocketArray addObject:self.fileInfoPort];
        [sock readDataWithTimeout:-1 tag:0];
        if (self.fileConnectedSocketArray.count == socketCount) { // 全部连接成功
            [self updateFinishedLength];
            // 发送文件内容
            NSInteger stepPart = 1024 *10;
            for (int i = 0; i<socketCount; i++) {
                GCDAsyncSocket *cSocket = self.fileClientSocketArray[i]; dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    // 发文件信息
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString md5WithFilePath:kFilePath],@"fileHash", nil];
                    [dic addEntriesFromDictionary:self.sections[i]];
                    
                    [cSocket writeData:[BMJavaDataOutputStream toByteDataWithDic:dic] withTimeout:-1 tag:0];
                    
                    while (1) {
                        NSMutableDictionary *detailDic = [self.sections[i] mutableCopy];
                        NSInteger finishIndex = ((NSNumber *)detailDic[@"finishIndex"]).integerValue;
                        NSInteger endIndex = ((NSNumber *)detailDic[@"endIndex"]).integerValue;
                        if ((finishIndex-1) >= endIndex) {
                            break;
                        }
                        if (self.fileClientSocketArray.count <socketCount) { // 暂停传输
                            break;
                        }
                        
                        [self.inFile seekToFileOffset:finishIndex];
                        NSInteger length = 0;
                        if ((endIndex-finishIndex +1) > stepPart) {
                            length = stepPart;
                        }
                        else{
                            length = endIndex-finishIndex +1;
                        }
                        NSLog(@"finishIndex--%ld length--%ld----portList[i]--%ld",(long)finishIndex,(long)length,(long)i);
                        
                        NSLog(@"self.inFile.offsetInFile before ==  %llu",self.inFile.offsetInFile);
                        
                        NSData *dataFile = [self.inFile readDataOfLength:length];
                        
                        NSLog(@"self.inFile.offsetInFile after ==  %llu",self.inFile.offsetInFile);
                        [cSocket writeData:dataFile withTimeout:-1 tag:(10+length)];
                        finishIndex = finishIndex + length;

                        [detailDic setValue:[NSNumber numberWithInteger:finishIndex] forKey:@"finishIndex"];
                        self.sections[i] = detailDic;
                        NSLog(@"self.inFile.offsetInFile ==  %llu ---portList[i]--%d",self.inFile.offsetInFile,i);
                        if (self.inFile.offsetInFile == endIndex) {
                            NSLog(@"self.inFile.offsetInFile == endIndex -- %ld",(long)endIndex);
                        }
                    }
                });
            }
        }
    }
    [self showMessageWithText:@"链接成功"];
    [self showMessageWithText:[NSString stringWithFormat:@"服务器IP ： %@", host]];
    [sock readDataToLength:2 withTimeout:-1 tag:1];
}

//收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    if (tag == 1) {
        [sock readDataToLength:[BMJavaDataInputStream readLengthWithData:data] withTimeout:-1 tag:2];
    }
    else if(tag == 2){
        NSString * str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSMutableDictionary *dictionary = str.mj_JSONObject;
        NSNumber *type = dictionary[@"type"];
        if ([type isEqualToNumber:@2]){// 确认是否接收
            NSNumber *isAccept = dictionary[@"data"][@"isAccept"];
            if ([isAccept isEqualToNumber:@1]) { // 同意接收
                NSLog(@" 同意接收");
                NSString *port = dictionary[@"data"][@"sendPort"];
                self.fileContentPort = port;
                for (int i =0; i<socketCount; i++) {
                    GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
                    [self.fileClientSocketArray addObject:socket];
                    
                    //连接服务器
                    [socket connectToHost:self.addressIP onPort:port.integerValue withTimeout:-1 error:nil];
                }
            }
            else{
                NSLog(@"拒绝");
            }
        }
        else if ([type isEqualToNumber:@4]){// 暂停后开始
            self.sections = [dictionary[@"data"][@"sections"] mutableCopy];
            for (int i =0; i<socketCount; i++) {
                GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
                [self.fileClientSocketArray addObject:socket];
                
                //连接服务器
                [socket connectToHost:self.addressIP onPort:self.fileContentPort.integerValue withTimeout:-1 error:nil];
            }
        }
        
        [sock readDataToLength:2 withTimeout:-1 tag:1];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    
    if (sock.connectedPort != self.portField.text.integerValue) {
        [self disconnect];
    }
    NSLog(@"socketDidDisconnect");
}

-(void)disconnect
{
    [self.fileConnectedSocketArray removeAllObjects];
    
    [self.fileClientSocketArray removeAllObjects];
}


- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSLog(@"didAcceptNewSocket");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    if (tag >10) {
        self.finishedLength = self.finishedLength + (tag - 10);
        [self updateProgress];
    }
//    [self updateProgress];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}


// 进度刷新
-(void)updateProgress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger finishTotal = self.finishedLength;
        NSInteger totalLength = 0;
        NSInteger tempLength = 0;
        for (int i =0; i < self.sections.count; i++) {
            NSMutableDictionary *item = self.sections[i];
            tempLength = tempLength <((NSNumber *)item[@"endIndex"]).integerValue?((NSNumber *)item[@"endIndex"]).integerValue:tempLength;
        }
        totalLength = tempLength;
        NSLog(@"receive progress--%lf", (double)finishTotal/(totalLength+1));
        self.progressView.progress = (double)finishTotal/totalLength;
        
        NSLog(@"receive finishTotal--%ld -- totalLength%ld", (long)finishTotal,(long)totalLength);
        if (finishTotal == totalLength+1) {
            [self.outfile closeFile];
            [self showMessageWithText:[NSString stringWithFormat:@"send finishTotal--%ld", (long)finishTotal]];
            [self disconnect];
        }
    });
}

@end
