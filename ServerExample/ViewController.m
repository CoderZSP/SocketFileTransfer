//
//  ViewController.m
//  ServerExample
//
//  Created by zhangsp on 2019/3/7.
//  Copyright © 2019 zsp. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "NSString+Extension.h"

#define portList [NSArray arrayWithObjects:@"8081",@"8082", nil]
@interface ViewController ()<GCDAsyncSocketDelegate>

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
@property (assign, nonatomic) NSInteger devidePart; // 每部分大小
@property (assign, nonatomic) NSInteger fileSize;// 文件大小
@property (assign, nonatomic) NSInteger writeProcessSize; // 已经传完文件大小

@property (strong, nonatomic) NSMutableArray *fileDivideDetail; // startIndex-endIndex-finishIndex
@end

@implementation ViewController

//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do any additional setup after loading the view, typically from a nib.
//    
//    //初始化服务器socket
//    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
//    
//    // 本机IP
//    NSString *ipStr = [NSString getIPAddress];
//    self.ownIP.text = [NSString stringWithFormat:@"本机IP:%@",ipStr];
//    self.fileSocketArray = [NSMutableArray array];
//    self.fileClientSocketArray = [NSMutableArray array];
//    self.fileDivideDetail = [NSMutableArray array];
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
//    self.inFile = [NSFileHandle fileHandleForReadingAtPath:filePath];
//    self.fileSize = [NSString fileSizeAtPath:filePath];
//    self.devidePart = [NSString fileSizeAtPath:filePath] / portList.count;
//    
//}
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//    
//
//}
//
///** 连接端口 **/
//- (IBAction)linkPortButtonAction:(id)sender {
//    NSError *error = nil;
//    BOOL result = [self.serverSocket acceptOnPort:self.portField.text.integerValue error:&error];
//    if (result && error == nil) {
//        //开放成功
//        [self showMessageWithText:@"连接成功"];
//    }
//}
//
//
///** 发消息 **/
//- (IBAction)sendMsgButtonAction:(id)sender {
//    NSData *data = [self.sendMsgField.text dataUsingEncoding:NSUTF8StringEncoding];
//    //withTimeout -1:  一直等
//    //tag:消息标记
//    [self.clientSocket writeData:data withTimeout:-1 tag:0];
//}
//// 发送文件
//- (IBAction)sendFile:(id)sender {
//    // 开启文件传输socket
//    NSInteger socketCount = portList.count;
//    for (NSInteger i = 0; i<socketCount; i++) {
//        GCDAsyncSocket *serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
//        [self.fileSocketArray addObject:serverSocket];
//        NSString *port = portList[i];
//        
//        NSError *error = nil;
//        BOOL result = [serverSocket acceptOnPort:port.integerValue error:&error];
//        if (result && error == nil) {
//            //开放成功
//            [self showMessageWithText:@"fileSocket连接成功"];
//        }
//    }
//    
//    // 发文件信息
//    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"1",@"type", nil];
//    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
//    [dataDic setValue:@"test.mp4" forKey:@"fileName"];
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"text" ofType:@"txt"];
//    [dataDic setValue:[NSString stringWithFormat:@"%lld",[NSString fileSizeAtPath:filePath]] forKey:@"fileSize"];
//    
//    [dataDic setValue:[NSString md5WithFilePath:filePath] forKey:@"fileHash"];
//    [dataDic setValue:@"1" forKey:@"isReceive"];
//    
//    NSMutableArray *divideDetailArr = [NSMutableArray array];
//    for (int i = 0; i<portList.count; i++) {
//        NSInteger startIndex = i*self.devidePart;
//        NSInteger endIndex = (i+1)*self.devidePart;
//        if (i == portList.count-1) {
//            endIndex = self.fileSize;
//        }
//        NSInteger finishIndex = startIndex;
//        NSString *item = [NSString stringWithFormat:@"%ld-%ld-%ld",startIndex,endIndex,finishIndex];
//        [divideDetailArr addObject:item];
//    }
//    self.fileDivideDetail = divideDetailArr;
//    [dataDic setValue:divideDetailArr forKey:@"fileDivideDetail"];
//    // 传输文件socket 端口号
//    [dataDic setValue:portList forKey:@"portList"];
//    [dic setValue:dataDic forKey:@"data"];
//    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
//    [self.clientSocket writeData:data withTimeout:-1 tag:0];
//    
//    
//}
//
//- (void)showMessageWithText:(NSString *)text {
//    self.reciveMsgTextView.text = [self.reciveMsgTextView.text stringByAppendingFormat:@"%@\n",text];
//}
//
//// 连接服务器
//- (IBAction)connectServer:(id)sender {
//    //连接服务器
////    [self.clientSocket connectToHost:self.serverIP.text onPort:self.serverPort.text.integerValue withTimeout:-1 error:nil];
//}
//
//
//#pragma mark - 服务器socket Delegate
//- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
//    if (sock.localPort == self.portField.text.integerValue) { // 传文件基本信息端口
//        //保存客户端的socket
//        self.clientSocket = newSocket;
//        [self showMessageWithText:@"链接成功"];
//        
//        [self showMessageWithText:[NSString stringWithFormat:@"客户端地址：%@ -端口： %d", newSocket.connectedHost, newSocket.connectedPort]];
//        [self.clientSocket readDataWithTimeout:-1 tag:0];
//    }
//    else{// 文件传输socket
//        [self.fileClientSocketArray addObject:newSocket];
//        [self showMessageWithText:@"文件socket链接成功"];
//        [self showMessageWithText:[NSString stringWithFormat:@"客户端地址：%@ -端口： %d", newSocket.connectedHost, newSocket.connectedPort]];
//        [newSocket readDataWithTimeout:-1 tag:0];
//    }
//}
//
////收到消息
//- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
//    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
//    NSLog(@"didReadData-%@",dictionary);
//    if (dictionary) {
//        NSString *type = dictionary[@"type"];
//        if ([type isEqualToString:@"2"]) {
//            NSString *isReceive = dictionary[@"data"][@"isReceive"];
//            if ([isReceive isEqualToString:@"1"]) { // 接受
//                // 发送文件
//                NSInteger stepPart = 1024;
//                for (int i = 0; i<portList.count; i++) {
//                    
//                    GCDAsyncSocket *cSocket = self.fileClientSocketArray[i];
//                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                        while (1) {
//                            NSString *detailStr = self.fileDivideDetail[i];
//                            NSMutableArray *detailArr = [[detailStr componentsSeparatedByString:@"-"] mutableCopy];
//                            NSInteger finishIndex = ((NSString *)[detailArr lastObject]).integerValue;
//                            NSInteger endIndex = ((NSString *)detailArr[1]).integerValue;
//                            if (finishIndex >= endIndex) {
//                                break;
//                            }
//                            [self.inFile seekToFileOffset:finishIndex];
//                            NSInteger length = 0;
//                            if ((endIndex-finishIndex) > stepPart) {
//                                length = stepPart;
//                            }
//                            else{
//                                length = endIndex-finishIndex;
//                            }
//                            NSLog(@"length--%ld----portList[i]--%ld",(long)length,(long)i);
//                            NSData *dataFile = [self.inFile readDataOfLength:length];
//                            [cSocket writeData:dataFile withTimeout:-1 tag:0];
//                            
//                            finishIndex = finishIndex + length;
//                            detailArr[2] = [NSString stringWithFormat:@"%ld", finishIndex];
//                            self.fileDivideDetail[i] = [NSString stringWithFormat:@"%@-%@-%@",detailArr[0],detailArr[1],detailArr[2]];
//                            [self updateProgress];
//                        }
//                        
////                        CGFloat partSize = i == (portList.count-1)?(self.fileSize - (self.devidePart *(portList.count -1))):self.devidePart;
////                        GCDAsyncSocket *cSocket = self.fileClientSocketArray[i];
////                        while (stepPart*j <partSize) {
////                            [self.inFile seekToFileOffset:(i*self.devidePart + stepPart*j)];
////                            NSData *data = [self.inFile readDataOfLength:stepPart];
////                            [cSocket writeData:data withTimeout:-1 tag:0];
////                            [self updateProgress];
////                            j++;
////                        }
////                        if (stepPart*(j-1) < partSize) {
////                            [self.inFile seekToFileOffset:(i*self.devidePart + stepPart*(j-1))];
////                            NSData *data = [self.inFile readDataToEndOfFile];
////                            [cSocket writeData:data withTimeout:-1 tag:0];
////                            [self updateProgress];
////                            [self.inFile closeFile];
////                        }
//                    });
//                    
//                }
//            }
//        }
//    }
//    
//    
//    [self.clientSocket readDataWithTimeout:-1 tag:0];
//}
//// 更新进度
//-(void)updateProgress
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSInteger finishTotal = 0;
//        NSInteger totalLength = 0;
//        for (int i =0; i < self.fileDivideDetail.count; i++) {
//            NSString *detail = self.fileDivideDetail[i];
//            NSArray *detailArray = [detail componentsSeparatedByString:@"-"];
//            NSString *startIndex = detailArray[0];
//            NSString *endIndex = detailArray[1];
//            NSString *finishIndex = detailArray[2];
//            NSInteger length = finishIndex.integerValue - startIndex.integerValue;
//            finishTotal += length;
//            if (i == self.fileDivideDetail.count -1) {
//                totalLength = endIndex.integerValue;
//            }
//        }
//        NSLog(@"progress--%lf---finishTotal%ld", (double)finishTotal/totalLength,(long)finishTotal);
//    });
//}


@end
