//
//  ViewController.m
//  SpeakinRecorder
//
//  Created by west on 2017/10/10.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import "ViewController.h"
#import "MasterControlManager.h"
#import "SlaveControlManager.h"
#import "NetWorkUtil.h"
#import "ControlDefine.h"

@interface ViewController () <MasterControlDelegate, SlaveControlDelegate> {
    MasterControlManager *_masterControlManager;
    SlaveControlManager *_slaveControlManager;
    BOOL _flag;
}

@property (weak, nonatomic) IBOutlet UILabel *localIpLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.localIpLabel.text = [NetWorkUtil getIPAddress:YES];
    _masterControlManager = [[MasterControlManager alloc] init];
    _masterControlManager.delagate = self;
    _slaveControlManager = [[SlaveControlManager alloc] init];
    _slaveControlManager.delegate = self;
}

- (IBAction)startMaster:(id)sender {
    [_masterControlManager start];
    _flag = YES;
}

- (IBAction)startSlave:(id)sender {
    [_slaveControlManager start];
}

- (IBAction)sendMessage:(id)sender {
    if (_flag ) {
        NSString *messge = [NSString stringWithFormat:@"Hello, I am master, %ld", (long)[[NSDate date] timeIntervalSince1970] ];
        [_masterControlManager sendToAll:messge];
    } else {
        NSString *messge = [NSString stringWithFormat:@"Hello, I am slave, %ld", (long)[[NSDate date] timeIntervalSince1970] ];
        [_slaveControlManager send:messge];
    }
}

- (IBAction)stopBtnTap:(id)sender {
    if (_flag) {
        [_masterControlManager stop];
    } else {
        [_slaveControlManager stop];
    }
}

#pragma mark - master

- (void)controlManager:(MasterControlManager *)manager clientDidConnect:(NSString *)client {
    self.infoLabel.text = [NSString stringWithFormat:@"client connected:%@",client];
}

- (void)controlManager:(MasterControlManager *)manager clientDidDisconnect:(NSString *)client {
    self.infoLabel.text = [NSString stringWithFormat:@"clientDidDisconnect:%@",client];
}

- (void)controlManager:(MasterControlManager *)manager didReceiveMsg:(NSString *)message fromClient:(NSString *)client {
    self.infoLabel.text = [NSString stringWithFormat:@"client:%@ message:%@",client, message];
}

#pragma mark - slave

- (void)controlManager:(SlaveControlManager *)manager didConnectMaster:(NSString *)masterIp error:(NSError *)error {
    self.infoLabel.text = [NSString stringWithFormat:@"master connected:%@",masterIp];
}

- (void)controlManager:(SlaveControlManager *)manager didDisconnectMaster:(NSString *)masterIp error:(NSError *)error {
    self.infoLabel.text = [NSString stringWithFormat:@"didDisconnectMaster:%@",masterIp];
}

- (void)controlManager:(SlaveControlManager *)manager didFoundMaster:(NSString *)masterIP userInfo:(NSDictionary *)masterInfo {
    self.infoLabel.text = [NSString stringWithFormat:@"didFoundMaster:%@",masterIP];
}

- (void)controlManager:(SlaveControlManager *)manager didReceiveMsg:(NSString *)message {
    self.infoLabel.text = [NSString stringWithFormat:@"cmessage:%@",message];
}

@end
