//
//  MasterControlManager.m
//  SpeakinRecorder
//
//  Created by west on 2017/10/13.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import "MasterControlManager.h"
#import "SRMasterSearchManager.h"
#import "NetWorkUtil.h"
#import "SpeakinRecorder-Swift.h"

#import "ControlDefine.h"

@interface MasterControlManager()<SRMasterSearchManagerDelegate, TelegraphServerDelegate>
{
    SRMasterSearchManager *_masterSearchManager;
    TelegraphServer *_webSocketServer;
    BOOL _isRunning;
}
@end

@implementation MasterControlManager

- (void)start {
    if (_isRunning) {
        return;
    }
    [self startSearch];
    [self startServer];
    _isRunning = YES;
}

- (void)stop {
    [self startSearch];
    [self stopServer];
    _isRunning = NO;
}

- (void)startSearch  {
    _masterSearchManager = [[SRMasterSearchManager alloc] initWithSlaveCount:SLAVE_COUNT teamId:TEAMID taskId:TASKID];
    _masterSearchManager.delegate = self;
    [_masterSearchManager start];
}

- (void)stopSearch {
    [_masterSearchManager stop];
    _masterSearchManager.delegate = nil;
    _masterSearchManager = nil;
}

- (void)startServer {
    _webSocketServer = [[TelegraphServer alloc] init];
    _webSocketServer.delegate = self;
    [_webSocketServer startOnPort:SERVER_PORT];
    [_masterSearchManager start];
}

- (void)stopServer {
    [_webSocketServer stopServer];
    _webSocketServer.delegate = nil;
    _webSocketServer = nil;
}

- (void)sendToAll:(NSString *)message {
    if (!_webSocketServer) {
        NSLog(@"no running");
        return;
    }
    [_webSocketServer sendToAllWithMessage:message];
}

#pragma mark -

- (void)masterSearch:(SRMasterSearchManager *)masterSearcher onFoundNewSalve:(NSString *)slaveIp userInfo:(NSDictionary *)slaveInfo{
    NSLog(@"found slave %@, info=%@", slaveIp, slaveInfo);
    if (self.delagate) {
        
    }
}

- (void)masterSearch:(SRMasterSearchManager *)masterSearcher onFoundSlaves:(NSArray *)slaves {
    NSLog(@"found slaves count=%ld", slaves.count);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_masterSearchManager stop];
    });
    
}

#pragma mark -

- (void)server:(TelegraphServer * _Nonnull)server webSocket:(TelWebSocket * _Nonnull)webSocket didReceiveMessage:(NSString * _Nonnull)message {
    NSLog(@"server receive: %@", message);
    if (self.delagate) {
        [self.delagate controlManager:self didReceiveMsg:message fromClient:@""];
    }
}

- (void)server:(TelegraphServer * _Nonnull)server webSocket:(TelWebSocket * _Nonnull)webSocket didSendMessage:(NSString * _Nonnull)message {
    NSLog(@"didSendMessage");
}

- (void)server:(TelegraphServer * _Nonnull)server webSocketDidConnect:(TelWebSocket * _Nonnull)webSocket {
    NSLog(@"server webSocketDidConnect");
    if (self.delagate) {
        [self.delagate controlManager:self clientDidConnect:@"client"];
    }
    [webSocket sendWithText:@"你好。 I am server"];
}

- (void)server:(TelegraphServer * _Nonnull)server webSocketDidDisconnect:(TelWebSocket * _Nonnull)webSocket error:(NSError * _Nullable)error {
    NSLog(@"server webSocketDidDisconnect error %@", error);
    if (self.delagate) {
        [self.delagate controlManager:self clientDidDisconnect:@"disconnect"];
    }
}

@end
