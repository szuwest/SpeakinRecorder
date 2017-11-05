//
//  NetWorkUtil.h
//  TimeCloud
//
//  Created by west on 15/8/11.
//  Copyright (c) 2015年 Xunlei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetWorkUtil : NSObject

+ (NSString *)getIPAddress:(BOOL)preferIPv4;

+ (NSString *)getBroadcastIPAddr;

+ (BOOL)iSOpenHotSpot;

+ (NSString *)getLocalNetmask;

+ (NSString *)int2Ip:(uint32_t)ipInt;

+ (uint32_t)ip2Int:(NSString *)ipString;

@end
