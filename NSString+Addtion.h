//
//  NSString+Addtion.h
//  360safe
//
//  Created by yanrui on 12-11-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const AppName;
extern NSString * const AppIconPath;
extern NSString * const AppSmallIconPath;
extern NSString * const AppID;
extern NSString * const AppVersion;
extern NSString * const AppBinaryMd5;
extern NSString * const AppPath;

@interface NSString (AppLock)

- (NSDictionary *)appInfo;

@end
