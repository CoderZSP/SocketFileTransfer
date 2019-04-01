//
//  ServerController.m
//  ServerExample
//
//  Created by zhangsp on 2019/3/7.
//  Copyright © 2019 zsp. All rights reserved.
//

#import "ServerController.h"
#import "GCDAsyncSocket.h"
#import "NSString+Extension.h"
#import "BMJavaDataInputStream.h"
#import "BMJavaDataOutputStream.h"
#import "MJExtension.h"
#define kSendFilePort @"8081"
@interface ServerController ()<GCDAsyncSocketDelegate>

/** 端口号 **/
@property (weak, nonatomic) IBOutlet UITextField *portField;

/** 发送消息 **/
@property (weak, nonatomic) IBOutlet UITextField *sendMsgField;

/** 连接端口号按钮 **/
@property (weak, nonatomic) IBOutlet UIButton *linkPortButton;

/** 发送消息按钮 **/
@property (weak, nonatomic) IBOutlet UIButton *sendMsgButton;

/** 接受消息 **/
@property (weak, nonatomic) IBOutlet UITextView *reciveMsgTextView;

@property (weak, nonatomic) IBOutlet UILabel *ownIP;


//服务器socket（开放端口，监听客户端socket的链接）
@property (nonatomic) GCDAsyncSocket *serverSocket;

//保护客户端socket
@property (nonatomic) GCDAsyncSocket *clientSocket;
@property (weak, nonatomic) IBOutlet UITextField *serverIP;
@property (weak, nonatomic) IBOutlet UITextField *serverPort;
@property (strong, nonatomic) NSMutableArray *fileSocketArray;
@property (strong, nonatomic) NSMutableArray *fileClientSocketArray;
@property (strong, nonatomic) NSFileHandle *inFile;
@property (assign, nonatomic) long long devidePart; // 每部分大小
@property (assign, nonatomic) long long fileSize;// 文件大小
@property (assign, nonatomic) NSInteger writeProcessSize; // 已经传完文件大小

@property (strong, nonatomic) NSMutableArray *sections;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) NSFileHandle *outfile;

@property (assign, nonatomic) NSInteger totalLength;
@property (strong, nonatomic) NSString *fileHash;
@property (strong, nonatomic) NSString *fileName;

@property (strong, nonatomic) NSMutableDictionary *fileInfoDictionary;
@end

@implementation ServerController

- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化服务器socket
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // 本机IP
    NSString *ipStr = [NSString getIPAddress];
    self.ownIP.text = [NSString stringWithFormat:@"本机IP:%@",ipStr];
    self.fileSocketArray = [NSMutableArray array];
    self.fileClientSocketArray = [NSMutableArray array];
    self.sections = [NSMutableArray array];
    NSLog(@"self.fileSize - %lld",self.fileSize);
}

/** 连接端口 **/
- (IBAction)linkPortButtonAction:(id)sender {
    NSError *error = nil;
    BOOL result = [self.serverSocket acceptOnPort:self.portField.text.integerValue error:&error];
    if (result && error == nil) {
        //开放成功
        [self showMessageWithText:@"连接成功"];
    }
    
    GCDAsyncSocket *serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.fileSocketArray addObject:serverSocket];
    NSString *port = kSendFilePort;
    
    BOOL fileResult = [serverSocket acceptOnPort:port.integerValue error:&error];
    if (fileResult && error == nil) {
        //开放成功
        [self showMessageWithText:@"fileSocket连接成功"];
    }
}


/** 发消息 **/
- (IBAction)sendMsgButtonAction:(id)sender {
//    NSData *data = [self.sendMsgField.text dataUsingEncoding:NSUTF8StringEncoding];
//    //withTimeout -1:  一直等
//    //tag:消息标记
//    [self.clientSocket writeData:data withTimeout:-1 tag:0];
}
// 发送文件
- (IBAction)sendFile:(id)sender {
    
}

- (void)showMessageWithText:(NSString *)text {
    self.reciveMsgTextView.text = [self.reciveMsgTextView.text stringByAppendingFormat:@"%@\n",text];
}

// 连接服务器
- (IBAction)connectServer:(id)sender {
    //连接服务器
    //    [self.clientSocket connectToHost:self.serverIP.text onPort:self.serverPort.text.integerValue withTimeout:-1 error:nil];
}


#pragma mark - 服务器socket Delegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    if (sock.localPort == self.portField.text.integerValue) { // 传文件基本信息端口
        //保存客户端的socket
        self.clientSocket = newSocket;
        [self showMessageWithText:@"链接成功"];
        [self showMessageWithText:[NSString stringWithFormat:@"客户端地址：%@ -端口： %d", newSocket.connectedHost, newSocket.connectedPort]];
        [self.clientSocket readDataToLength:2 withTimeout:-1 tag:1];
    }
    else{// 文件传输socket
        [self.fileClientSocketArray addObject:newSocket];
        [self showMessageWithText:@"文件socket链接成功"];
        [self showMessageWithText:[NSString stringWithFormat:@"客户端地址：%@ -端口： %d", newSocket.connectedHost, newSocket.connectedPort]];
        [newSocket readDataToLength:2 withTimeout:-1 tag:3];
    }
}

//收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    if (tag == 1) {
        [sock readDataToLength:[BMJavaDataInputStream readLengthWithData:data] withTimeout:-1 tag:2];
    }
    else if(tag == 2){
        NSString * str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSMutableDictionary *dictionary = str.mj_JSONObject;
        NSLog(@"didReadData-%@",dictionary);
        if (dictionary) {
            self.fileInfoDictionary = [dictionary mutableCopy];
            NSNumber *type = dictionary[@"type"];
            if ([type isEqualToNumber:@1]) {// 文件信息
                self.fileHash = [dictionary[@"data"][@"fileHash"] mutableCopy];
                self.fileName = [dictionary[@"data"][@"fileName"] mutableCopy];
                NSString *fileNameStr = dictionary[@"data"][@"fileName"];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"是否接收" message:fileNameStr preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    NSLog(@"点击取消按钮");
                    NSMutableDictionary *param = [dictionary mutableCopy];
                    [param setValue:@2 forKey:@"type"];
                    [param[@"data"] setValue:@NO forKey:@"isAccept"];
                    [self.clientSocket writeData:[BMJavaDataOutputStream toByteDataWithDic:param] withTimeout:-1 tag:0];
                }]];
                
                [alert addAction:[UIAlertAction actionWithTitle:@"接收" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    NSLog(@"接收");
                    NSString *homePath = NSHomeDirectory();
                    NSString *outPath = [homePath stringByAppendingPathComponent:self.fileName];
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    if (![fileManager fileExistsAtPath:outPath])
                    {
                        BOOL sucess = [fileManager createFileAtPath:outPath contents:nil attributes:nil];
                        if (!sucess)
                        {
                            return;
                        }
                    }
                    NSLog(@"outPath--%@",outPath);
                    self.outfile = [NSFileHandle fileHandleForWritingAtPath:outPath];
                    
                    NSMutableDictionary *param = [dictionary mutableCopy];
                    [param setValue:@2 forKey:@"type"];
                    NSMutableDictionary *dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@YES, @"isAccept", kSendFilePort,@"sendPort",nil];
                    [param setValue:dataDic forKey:@"data"];
                    
                    [self.clientSocket writeData:[BMJavaDataOutputStream toByteDataWithDic:param] withTimeout:-1 tag:0];
                }]];
                
                [self presentViewController:alert animated:YES completion:nil];
            }
            else if ([type isEqualToNumber:@2]) { // 确认是否接收
            }
            else if ([type isEqualToNumber:@3]) {// 暂停后开始任务
                NSString *fileHash = dictionary[@"data"][@"fileHash"];
                if ([self.fileHash isEqualToString:fileHash]) { // 同一个文件
                    
                    NSMutableDictionary *param = [dictionary mutableCopy];
                    [param setValue:@4 forKey:@"type"];
                    NSMutableDictionary *dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.sections, @"sections",nil];
                    [param setValue:dataDic forKey:@"data"];
                    
                    [self.clientSocket writeData:[BMJavaDataOutputStream toByteDataWithDic:param] withTimeout:-1 tag:0];
                    [self.sections removeAllObjects];
                }
                else{
                    NSLog(@"不是同一文件");
                }
            }
        }
        [sock readDataToLength:2 withTimeout:-1 tag:1];
    }
    else if(tag == 3){ // 接收文件内容头部长度
        [sock readDataToLength:[BMJavaDataInputStream readLengthWithData:data] withTimeout:-1 tag:4];
    }
    else if(tag == 4){ // 接收文件内容头部json
        NSString * str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSMutableDictionary *dictionary = str.mj_JSONObject;
        
        if ([self.fileHash isEqualToString:dictionary[@"fileHash"]]) {
            NSMutableDictionary *detailDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:dictionary[@"startIndex"],@"startIndex", dictionary[@"endIndex"],@"endIndex",dictionary[@"finishIndex"],@"finishIndex",nil];
            [self.sections addObject:detailDic];
            [sock readDataWithTimeout:-1 tag:(10 + self.sections.count - 1)];
        }
        else{
            NSLog(@"fileHash 不一致");
        }
    }
    else if(tag >=10){ // 接收文件内容
        if ((tag -10) >= self.sections.count ) {
            NSLog(@"error");
            return;
        }
        NSMutableDictionary *detailDic = self.sections[tag -10];
        NSInteger finishIndex = ((NSNumber *)detailDic[@"finishIndex"]).integerValue;
        [self.outfile seekToFileOffset:finishIndex];
        [self.outfile writeData:data];
        finishIndex = finishIndex + data.length;
        [detailDic setValue:[NSNumber numberWithInteger:finishIndex] forKey:@"finishIndex"];
        self.sections[tag -10] = detailDic;

        [self updateProgress];
        [self showLengthInfo:data.length];
        [sock readDataWithTimeout:-1 tag:tag];
    }
}

-(void)showLengthInfo:(NSInteger)dataLength
{
    self.totalLength += dataLength;
    NSLog(@"self.totalLength--%ld",(long)self.totalLength);
}

- (IBAction)suspendClick:(id)sender {
    [self disconnect];
}

-(void)disconnect
{
    //暂停
    for (int i =0; i<self.fileClientSocketArray.count; i++) {
        GCDAsyncSocket *cSocket = self.fileClientSocketArray[i];
        [cSocket disconnect];
    }
    [self.fileClientSocketArray removeAllObjects];
}


// 继续传输
- (IBAction)continueClick:(id)sender {
    // 发送文件信息
//    [self sendFileInfo];
    NSMutableDictionary *param = [self.fileInfoDictionary mutableCopy];
    [param setValue:@4 forKey:@"type"]; //继续传输
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.sections, @"sections",nil];
    [param setValue:dataDic forKey:@"data"];
    [self.clientSocket writeData:[BMJavaDataOutputStream toByteDataWithDic:param] withTimeout:-1 tag:0];
    [self.sections removeAllObjects];
}


// 更新进度
-(void)updateProgress
{
        NSInteger finishTotal = 0;
        NSInteger totalLength = 0;
        for (int i =0; i < self.sections.count; i++) {
            NSMutableDictionary *detailDic = self.sections[i];
            NSInteger startIndex = ((NSNumber *)detailDic[@"startIndex"]).integerValue;
            NSInteger finishIndex = ((NSNumber *)detailDic[@"finishIndex"]).integerValue;
            NSInteger endIndex = ((NSNumber *)detailDic[@"endIndex"]).integerValue;
            
            NSInteger length = finishIndex - startIndex;
            finishTotal += length;
            if (i == self.sections.count -1) {
                totalLength = endIndex;
            }
        }
        NSLog(@"send progress--%lf---finishTotal%ld", (double)finishTotal/totalLength,(long)finishTotal);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"finishTotal--%ld",(long)finishTotal);
            self.progressView.progress = (double)finishTotal/totalLength;
        });
    
    
    NSLog(@"receive progress--%lf", (double)finishTotal/totalLength);
    [self showMessageWithText:[NSString stringWithFormat:@"send progress--%lf", (double)finishTotal/totalLength]];
    self.progressView.progress = (double)finishTotal/totalLength;
    
    NSLog(@"receive finishTotal--%ld -- totalLength%ld", (long)finishTotal,(long)totalLength);
    if (finishTotal == totalLength+1) {
        [self.outfile closeFile];
        [self showMessageWithText:[NSString stringWithFormat:@"send finishTotal--%ld", (long)finishTotal]];
        
        NSString *homePath = NSHomeDirectory();
        NSString *outPath = [homePath stringByAppendingPathComponent:self.fileName];
        [self showMessageWithText:[NSString stringWithFormat:@"source -fileHash%@, recent fileHash-%@",self.fileHash,[NSString md5WithFilePath:outPath]]];
        
    }
}


@end
