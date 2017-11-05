//
//  SRMasterSearchManager.h
//  SpeakinRecorder
//
//  Created by west on 2017/10/11.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRMasterSearchManager;

@protocol SRMasterSearchManagerDelegate <NSObject>

- (void)masterSearch:(SRMasterSearchManager *)masterSearcher onFoundSlaves:(NSArray *)slaves;

@optional

- (void)masterSearch:(SRMasterSearchManager *)masterSearcher onFoundNewSalve:(NSString *)slaveIp userInfo:(NSDictionary *)slaveInfo;

@end

@interface SRMasterSearchManager : NSObject

@property (nonatomic, weak) id<SRMasterSearchManagerDelegate>delegate;

- (instancetype)initWithSlaveCount:(NSUInteger)slaveCount teamId:(NSString *)teamId taskId:(NSString *)taskId;

- (void)start;

- (void)stop;

@end
