//
//  SRSlaveSearchManager.h
//  SpeakinRecorder
//
//  Created by west on 2017/10/11.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import <Foundation/Foundation.h>


@class SRSlaveSearchManager;

@protocol SRSlaveSearchManagerDelegate  <NSObject>

- (void)slaveSearcher:(SRSlaveSearchManager *)slaveSearcher onFoundMaster:(NSString *)masterIp userInfo:(NSDictionary *)info;

@end

@interface SRSlaveSearchManager : NSObject

@property (nonatomic, weak) id<SRSlaveSearchManagerDelegate> delegate;

- (instancetype)initWithTeamId:(NSString *)teamId taskId:(NSString *)taskId;

- (void)start;

- (void)stop;

@end
