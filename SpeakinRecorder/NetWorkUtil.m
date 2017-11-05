//
//  NetWorkUtil.m
//  TimeCloud
//
//  Created by west on 15/8/11.
//  Copyright (c) 2015年 Xunlei. All rights reserved.
//

#import "NetWorkUtil.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/sysctl.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

typedef NS_ENUM(NSInteger, NetWorkInfoType) {
    NetWorkInfoType_IpAddress = 0,              //本地IP
    NetWorkInfoType_NetMask = 1,                //子网掩码
    NetWorkInfoType_BroadcastAddress = 2,       //广播地址
};

@implementation NetWorkUtil


+ (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
//    @[ IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv4] :
//    @[ IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv6] ;
    @[ IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv6] :
    @[ IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv4];
    
    NSDictionary *addresses = [NetWorkUtil getIPAddresses];
//    DDLogDebug(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

/**
 *  判断是否开启热点
 */
+ (BOOL)iSOpenHotSpot
{
    NSDictionary *dict = [NetWorkUtil getIPAddresses];
    if ( dict ) {
        NSArray *keys = dict.allKeys;
        for ( NSString *key in keys) {
            if ([key containsString:@"bridge"] )
                return YES;
        }
    }
    return NO;
}

+ (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

+ (NSString *)getNetInfoWithType:(NetWorkInfoType)infoType {
    NSString *info = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                
                switch (infoType) {
                    case NetWorkInfoType_NetMask:
                        if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                            info = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                        }
                        break;
                        
                    case NetWorkInfoType_IpAddress:
                        info = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                        break;
                        
                    case NetWorkInfoType_BroadcastAddress:
                        info = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)];
                        break;
                        
                    default:
                        break;
                }
                
                if (infoType == NetWorkInfoType_BroadcastAddress) {
                    if (info.length > 4 && ![info isEqualToString:@"127.0.0.1"]) {
                        break;
                    }
                } else if (info.length > 0) {
                    break;
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    return info;
}


+ (NSString *)getBroadcastIPAddr {
    return [self getNetInfoWithType:NetWorkInfoType_BroadcastAddress];
}

+ (NSString *)getLocalNetmask {
    return [self getNetInfoWithType:NetWorkInfoType_NetMask];
}

+ (uint32_t)ip2Int:(NSString *)ipString {
    struct in_addr addr;
    if (inet_aton([ipString UTF8String], &addr) != 0) {
        uint32_t ip = ntohl(addr.s_addr);
        return ip;
    }
    return -1;
}

+ (NSString *)int2Ip:(uint32_t)ipInt {
    uint32_t ip = ipInt;
    int part1, part2, part3, part4;
    
    part1 = ip/16777216;
    ip = ip%16777216;
    part2 = ip/65536;
    ip = ip%65536;
    part3 = ip/256;
    ip = ip%256;
    part4 = ip;
    
    NSString *fullIP = [NSString stringWithFormat:@"%d.%d.%d.%d", part1, part2, part3, part4];
    
    return fullIP;
}

@end
