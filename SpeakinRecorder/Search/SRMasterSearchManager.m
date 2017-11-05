//
//  SRMasterSearchManager.m
//  SpeakinRecorder
//
//  Created by west on 2017/10/11.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import "SRMasterSearchManager.h"
#import "GCDAsyncUdpSocket.h"
#import "NetWorkUtil.h"
#import "ControlDefine.h"

#define BROADCAST_INTERVAL  5

@interface SRMasterSearchManager () <GCDAsyncUdpSocketDelegate>
{
    NSTimer *_timer;
}
@property (nonatomic, copy) NSString *teamId;
@property (nonatomic, copy) NSString *taskId;

@property (strong, nonatomic) GCDAsyncUdpSocket* asynUDPSocket;
@property (strong, nonatomic) NSData* packageContent;
@property (assign, nonatomic) long packageTag;
@property (strong, nonatomic) NSMutableArray* slaveList;
@property (assign, nonatomic) NSUInteger minSlaveCount;
@property (atomic) BOOL isStop;

@property (nonatomic, assign) BOOL isBroadcastEnable;
@end

@implementation SRMasterSearchManager

- (instancetype)initWithSlaveCount:(NSUInteger)slaveCount teamId:(NSString *)teamId taskId:(NSString *)taskId {
    if (self = [super init]) {
        self.taskId = taskId;
        self.teamId = teamId;
        self.slaveList = [NSMutableArray new];
        self.minSlaveCount = slaveCount;
        self.isBroadcastEnable = NO;
    }
    return self;
}

- (NSString *)message {
    NSString *dataString = [NSString stringWithFormat:@"{\"type\":\"master\",\"teamId\":\"%@\",\"taskId\":\"%@\"}", self.teamId, self.taskId];
    return dataString;
}

- (void)stop {
    self.isStop = YES;
    [self stopTimer];
    [self.asynUDPSocket close];
    self.asynUDPSocket = nil;
}

- (void)start {
    if (self.asynUDPSocket) {
        NSLog(@"already started");
        return;
    }
    self.asynUDPSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    [_asynUDPSocket bindToPort:MASTER_LISTEN_PORT error:&error];
    if (error) {
        NSLog(@"Error binding: %@", error);
        return;
    }
    /*self.isBroadcastEnable = */[self.asynUDPSocket enableBroadcast:YES error:&error];
    if (error) {
        NSLog(@"Error enableBroadcast: %@", error);
        return;
    }
    [_asynUDPSocket beginReceiving:&error];
    if (error){
        [_asynUDPSocket close];
        NSLog(@"Error beginReceiving: %@", error);
        return;
    }
    NSString *dataString = [self message];
    self.packageContent = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [self.slaveList removeAllObjects];
    self.isStop = NO;
    [self startTimer];
//    [self onTimer:nil];
    NSLog(@"Ready");
}

- (void)startTimer {
    _timer = [NSTimer scheduledTimerWithTimeInterval:BROADCAST_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [_timer fire];
}

- (void)stopTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void)onTimer:(id) sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doBroadcast];
    });
}

- (void)doBroadcast {
    if (self.isBroadcastEnable) {
        ++self.packageTag;
        NSString *ipAddrString = @"255.255.255.255";
        if ([NetWorkUtil iSOpenHotSpot]) {
            ipAddrString = @"192.168.43.255";
        }
//        NSString *ipAddrString = [NSString stringWithFormat:@"%d.%d.%d.%d", ipAddr1, ipAddr2, ipAddr3, 255];
        [self.asynUDPSocket sendData:self.packageContent toHost:ipAddrString port:SLAVE_LISTEN_PORT withTimeout:600 tag:self.packageTag];
        NSLog(@"broadcast msg to %@", ipAddrString);
    } else {//广播不能发就单播，遍历发送
        UInt8 ipAddr1 = 192;
        UInt8 ipAddr2 = 168;
        UInt8 ipAddr3 = 1;
        UInt8 ipAddr4 = 2;
        
        NSString *localIP = [NetWorkUtil getIPAddress:YES];
        //    NSLog(@"localIp=%@", localIP);
        if (localIP.length > 0) {
            NSArray *ipArray = [localIP componentsSeparatedByString:@"."];
            if (ipArray.count == 4) {
                ipAddr1 = (UInt8)[ipArray[0] integerValue];
                ipAddr2 = (UInt8)[ipArray[1] integerValue];
                ipAddr3 = (UInt8)[ipArray[2] integerValue];
                ipAddr4 = (UInt8)[ipArray[3] integerValue];
            }
        }
        
        for (int i = 1; i < 255; i++) {
            if (i == ipAddr4) {
                continue;
            }
            
            ++self.packageTag;
            NSString *ipAddrString = [NSString stringWithFormat:@"%d.%d.%d.%d", ipAddr1, ipAddr2, ipAddr3, i];
            NSLog(@"send data to ip=%@", ipAddrString);
            [self.asynUDPSocket sendData:self.packageContent toHost:ipAddrString port:SLAVE_LISTEN_PORT withTimeout:5 tag:self.packageTag];
        }
    }
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(BROADCAST_INTERVAL * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self onTimer:nil];
//    });
}

#pragma mark - GCDAsyncUdpSocketDelegate
/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"didSendDataWithTag = %ld", tag);
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
 * {"type":"slave","teamId":"Speakin","port":9001,"taskId":"Test"}
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
    NSLog(@"onUdpSocket successful, tag=%ld, fromIP=%@, port=%lu, content=%@", self.packageTag, fromIP, (unsigned long)fromPort, content);
    if ([fromIP hasPrefix:@"::ffff:"]) {
        fromIP = [fromIP substringFromIndex:7];
        NSLog(@"ip %@", fromIP);
    }
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
    if ([jsonObject isKindOfClass:[NSDictionary class]]){
        NSString *type = jsonObject[@"type"];
        NSString *teamId = jsonObject[@"teamId"];
        NSString *taskId = jsonObject[@"taskId"];
        if ([type isEqualToString:@"slave"] && [teamId isEqualToString:self.teamId] && [taskId isEqualToString:self.taskId]) {
            if (![self.slaveList containsObject:fromIP]) {
                [self.slaveList addObject:fromIP];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(masterSearch:onFoundNewSalve:userInfo:)]) {
                        [self.delegate masterSearch:self onFoundNewSalve:fromIP userInfo:jsonObject];
                    }
                });
                
            }
            if (self.slaveList.count >= self.minSlaveCount) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate masterSearch:self onFoundSlaves:self.slaveList];
                });
            }
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
