//
//  MasterControlManager.h
//  SpeakinRecorder
//
//  Created by west on 2017/10/13.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MasterControlManager;

@protocol MasterControlDelegate <NSObject>

- (void)controlManager:(MasterControlManager *)manager clientDidConnect:(NSString *)client;
- (void)controlManager:(MasterControlManager *)manager clientDidDisconnect:(NSString *)client;
- (void)controlManager:(MasterControlManager *)manager didReceiveMsg:(NSString *)message fromClient:(NSString *)client;

@end

@interface MasterControlManager : NSObject

@property (nonatomic, weak)id<MasterControlDelegate> delagate;

- (void)start;

- (void)stop;

- (void)sendToAll:(NSString *)message;

@end
