//
//  SlaveControlManager.m
//  SpeakinRecorder
//
//  Created by west on 2017/10/13.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import "SlaveControlManager.h"

#import "SRSlaveSearchManager.h"
#import "SpeakinRecorder-Swift.h"
#import "NetWorkUtil.h"
#import "ControlDefine.h"
#import "SocketRocket/SocketRocket.h"

@interface SlaveControlManager ()<SRSlaveSearchManagerDelegate, TelegraphSlaveDelegate, SRWebSocketDelegate>
{
    SRSlaveSearchManager *_slaveSearchManager;
    SRWebSocket *_webSocketClient;
//    TelegraphSlave *_webSocketClient;
    BOOL _isRunning;
}

@property (nonatomic, copy) NSString *serverIp;
@property (nonatomic, assign) NSUInteger serverPort;

@end

@implementation SlaveControlManager

- (instancetype)init {
    if (self = [super init]) {
        self.serverPort = SERVER_PORT;
    }
    return self;
}

#pragma mark -

- (void)start {
    if (_isRunning) {
        NSLog(@"is running");
        return;
    }
    [self startSearch];
    _isRunning = YES;
}

- (void)stop {
    [self stopSearch];
    [self stopConnect];
    _isRunning = NO;
}

- (void)startSearch {
    _slaveSearchManager = [[SRSlaveSearchManager alloc] initWithTeamId:TEAMID taskId:TASKID];
    _slaveSearchManager.delegate = self;
    [_slaveSearchManager start];
}

- (void)stopSearch {
    [_slaveSearchManager stop];
    _slaveSearchManager.delegate = nil;
    _slaveSearchManager = nil;
}

- (void)startConnect {
    _webSocketClient.delegate = nil;
    [_webSocketClient close];
    NSString *url = [NSString stringWithFormat:@"ws://%@:%lu", self.serverIp, (unsigned long)self.serverPort];
    _webSocketClient = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:url] protocols:@[WEBSOCKET_PROTOCOL]];
    _webSocketClient.delegate = self;
    
    NSLog(@"Opening Connection...");
    [_webSocketClient open];
}

- (void)stopConnect {
    [_webSocketClient close];
    _webSocketClient.delegate = nil;
    _webSocketClient = nil;
}

- (void)send:(NSString *)message {
    if (!_webSocketClient) {
        NSLog(@"not connected");
        return;
    }
    [_webSocketClient send:message];
}

#pragma mark -

- (void)slaveSearcher:(SRSlaveSearchManager *)slaveSearcher onFoundMaster:(NSString *)masterIp userInfo:(NSDictionary *)info{
    self.serverIp = masterIp;
    if ([self.delegate respondsToSelector:@selector(controlManager:didFoundMaster:userInfo:)]) {
        [self.delegate controlManager:self didFoundMaster:masterIp userInfo:info];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startSearch];
        [self startConnect];
    });
}

#pragma mark -

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"Websocket Connected");
    if ([self.delegate respondsToSelector:@selector(controlManager:didConnectMaster:error:)]) {
        [self.delegate controlManager:self didConnectMaster:self.serverIp error:nil];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webSocketClient send:@"Hello Server!"];
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@":( Websocket Failed With Error %@", error);
    if (error && [self.delegate respondsToSelector:@selector(controlManager:didConnectMaster:error:)]) {
        [self.delegate controlManager:self didConnectMaster:self.serverIp error:error];
    }
    _isRunning = NO;
    _webSocketClient = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"WebSocket closed");
    _isRunning = NO;
    if ([self.delegate respondsToSelector:@selector(controlManager:didDisconnectMaster:error:)]) {
        NSError *err = [[NSError alloc] initWithDomain:reason.length?reason:@"normally close" code:code userInfo:nil];
        [self.delegate controlManager:self didDisconnectMaster:self.serverIp error:err];
    }
    _webSocketClient = nil;
}
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSLog(@"WebSocket received pong");
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"Received \"%@\"", message);
    if ([self.delegate respondsToSelector:@selector(controlManager:didReceiveMsg:)]) {
        [self.delegate controlManager:self didReceiveMsg:message];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_webSocketClient send:@"Hello Server!"];
    });
}

#pragma mark -

- (void)telegraphSlave:(TelegraphSlave * _Nonnull)client didConnectToHost:(NSString * _Nonnull)host {
    NSLog(@"slave didConnectToHost %@", host);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *localIp = [NetWorkUtil getIPAddress:YES];
        [client sendMessageWithMessage:[NSString stringWithFormat:@"你好。I am client%@", localIp]];
    });
}

- (void)telegraphSlave:(TelegraphSlave * _Nonnull)client didDisconnectWithError:(NSError * _Nullable)error {
    NSLog(@"slave didDisconnectWithError %@", error);
//    [_webSocketClient stopConnect];
    _webSocketClient =  nil;
}

- (void)telegraphSlave:(TelegraphSlave * _Nonnull)client didReceiveData:(NSData * _Nonnull)data {
    NSLog(@"slave receive data");
}

- (void)telegraphSlave:(TelegraphSlave * _Nonnull)client didReceiveText:(NSString * _Nonnull)text {
    NSLog(@"slave receive: %@", text);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_webSocketClient send:@"Hello Server!"];
    });
}


@end
