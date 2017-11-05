//
//  SlaveControlManager.h
//  SpeakinRecorder
//
//  Created by west on 2017/10/13.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SlaveControlManager;

@protocol SlaveControlDelegate <NSObject>

- (void)controlManager:(SlaveControlManager *)manager didFoundMaster:(NSString *)masterIP userInfo:(NSDictionary *)masterInfo;
- (void)controlManager:(SlaveControlManager *)manager didConnectMaster:(NSString *)masterIp error:(NSError *)error;
- (void)controlManager:(SlaveControlManager *)manager didDisconnectMaster:(NSString *)masterIp error:(NSError *)error;
- (void)controlManager:(SlaveControlManager *)manager didReceiveMsg:(NSString *)message;

@end

@interface SlaveControlManager : NSObject

@property (nonatomic, weak)id<SlaveControlDelegate> delegate;

- (void)start;

- (void)stop;

- (void)send:(NSString *)message;

@end
