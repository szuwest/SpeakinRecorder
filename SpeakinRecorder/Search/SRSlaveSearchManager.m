//
//  SRSlaveSearchManager.m
//  SpeakinRecorder
//
//  Created by west on 2017/10/11.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import "SRSlaveSearchManager.h"
#import "GCDAsyncUdpSocket.h"
#import "ControlDefine.h"

@interface SRSlaveSearchManager() <GCDAsyncUdpSocketDelegate>

@property (nonatomic, copy) NSString *teamId;
@property (nonatomic, copy) NSString *taskId;

@property (strong, nonatomic) GCDAsyncUdpSocket* asynUDPSocket;
@property (strong, nonatomic) NSData* packageContent;
@property (assign, nonatomic) long packageTag;
@property (atomic) BOOL isStop;

@end

@implementation SRSlaveSearchManager

- (instancetype)initWithTeamId:(NSString *)teamId taskId:(NSString *)taskId {
    if (self = [super init]) {
        self.taskId = taskId;
        self.teamId = teamId;
    }
    return self;
}

- (NSString *)message {
    NSString *dataString = [NSString stringWithFormat:@"{\"type\":\"slave\",\"teamId\":\"%@\",\"taskId\":\"%@\"}", self.teamId, self.taskId];
    return dataString;
}

- (void)start {
    if (self.asynUDPSocket) {
        NSLog(@"already started");
        return;
    }
    self.asynUDPSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    if (![_asynUDPSocket bindToPort:SLAVE_LISTEN_PORT error:&error]) {
        NSLog(@"Error binding: %@", error);
        [self stop];
        return;
    }
    if (![_asynUDPSocket beginReceiving:&error]){
        [self stop];
        NSLog(@"Error beginReceiving: %@", error);
        return;
    }
    self.isStop = NO;
    NSLog(@"Ready, listening");
}

- (void)replyToMaster:(NSString *)masterIp port:(NSUInteger)port {
    NSString *dataString = [self message];
    self.packageContent = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [self.asynUDPSocket sendData:self.packageContent toHost:masterIp port:port withTimeout:600 tag:self.packageTag];
}

- (void)stop {
    self.isStop = YES;
    [self.asynUDPSocket close];
    self.asynUDPSocket = nil;
}


#pragma mark - GCDAsyncUdpSocketDelegate
/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"tag=%ld, error=%@", tag, error);
}

/**
 * Called when the socket has received the requested datagram.
 **/
/** 正确回包：
 * {"type":"master","teamId":"Speakin","port":9001,"taskId":"Test"}
 *
 */
- (void)udpSocket:(GCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    if (self.isStop) {
        return;
    }
    
    __block NSString *fromIP = [GCDAsyncUdpSocket hostFromAddress:address];
    NSUInteger fromPort = [GCDAsyncUdpSocket portFromAddress:address];
    NSString *content = [[self class] stringWithData:data encoding:nil];
    NSLog(@"onUdpSocket successful, tag=%ld, content=%@", self.packageTag, content);
    if ([fromIP hasPrefix:@"::ffff:"]) {
        fromIP = [fromIP substringFromIndex:7];
    }
    NSLog(@"from ip： %@，Port：%ld", fromIP,fromPort);
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
    if ([jsonObject isKindOfClass:[NSDictionary class]]){
        NSString *type = jsonObject[@"type"];
        NSString *teamId = jsonObject[@"teamId"];
        NSString *taskId = jsonObject[@"taskId"];
        if ([type isEqualToString:@"master"] && [teamId isEqualToString:self.teamId] && [taskId isEqualToString:self.taskId]) {
            [self replyToMaster:fromIP port:MASTER_LISTEN_PORT];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate slaveSearcher:self onFoundMaster:fromIP userInfo:jsonObject];
            });
        }
    }
}

+ (NSString *)stringWithData:(NSData *)data encoding:(NSString *)encoding
{
    NSStringEncoding e;
    if (encoding == nil || [[encoding lowercaseString] isEqualToString:@"utf-8"]) {
        e = NSUTF8StringEncoding;
    } else {
        e = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_CN);
    }
    return [[NSString alloc] initWithData:data encoding:e];
}

@end
