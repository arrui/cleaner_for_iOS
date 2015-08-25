//
//  NSString+Addtion.m
//  360safe
//
//  Created by yanrui on 12-11-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NSString+Addtion.h"
#define SPRINGBOARDPATH @"/System/Library/CoreServices/SpringBoard.app/"

NSString * const AppName            = @"AppName";
NSString * const AppIconPath        = @"AppIconPath";
NSString * const AppSmallIconPath   = @"AppSmallIconPath";
NSString * const AppID              = @"AppID";
NSString * const AppVersion         = @"AppVersion";
NSString * const AppBinaryMd5       = @"AppBinaryMd5";
NSString * const AppPath            = @"AppPath";


@implementation NSString (AppLock)
- (NSDictionary *)appInfo {
    NSMutableDictionary *info = nil;

    NSString *appName       = nil;
    NSString *iconPath      = nil;
    NSString *smallIconPath = nil;
    NSString *appID         = nil;
    NSString *appVersion    = nil;
    NSString *appBinaryMd5  = nil;
    NSString *appPath       = nil;
    
    NSFileManager *fileManager      = [NSFileManager defaultManager];
    
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:self isDirectory:&isDir] && isDir) {
        NSBundle *appBundle             = [NSBundle bundleWithPath:self];
        NSDictionary *plistDictionary   = [[NSDictionary alloc] initWithContentsOfFile:[appBundle pathForResource:@"Info" ofType:@"plist"]];
        NSString *identitifer           = [plistDictionary objectForKey:@"CFBundleIdentifier"];
        
        //id
        appID = identitifer;
        
        //name
        if ([identitifer isEqualToString:@"com.apple.mobileslideshow"])
            identitifer = @"com.apple.mobileslideshow-Photos";
        if (NSLocalizedStringFromTableInBundle(identitifer, @"LocalizedApplicationNames", [NSBundle bundleWithPath:SPRINGBOARDPATH], @"") != identitifer) {
            appName = NSLocalizedStringFromTableInBundle(identitifer, @"LocalizedApplicationNames", [NSBundle bundleWithPath:SPRINGBOARDPATH], @"");
        } else {
            appName = NSLocalizedStringFromTableInBundle(@"CFBundleDisplayName~iphone", @"InfoPlist", appBundle, @""); // iOS4, MobilePhone Name
            if ([appName isEqualToString:@"CFBundleDisplayName~iphone"]) {
                appName = NSLocalizedStringFromTableInBundle(@"CFBundleDisplayName", @"InfoPlist", appBundle, @"");
                if ([appName isEqualToString:@"CFBundleDisplayName"]) {
                    appName = NSLocalizedStringFromTableInBundle(@"UISettingsDisplayName", @"InfoPlist", appBundle, @"");
                    if ([appName isEqualToString:@"UISettingsDisplayName"]) {
                        appName = NSLocalizedStringFromTableInBundle(@"CFBundleName", @"InfoPlist", appBundle, @"");
                        if ([appName isEqualToString:@"CFBundleName"]) {
                            if ([[plistDictionary objectForKey:@"CFBundleDisplayName"] length] > 0)
                                appName = [plistDictionary objectForKey:@"CFBundleDisplayName"];
                            else if ([[plistDictionary objectForKey:@"CFBundleName"] length] > 0)
                                appName = [plistDictionary objectForKey:@"CFBundleName"];
                            else
                                appName = [plistDictionary objectForKey:@"CFBundleExecutable"];
                        }
                    }
                }			
            }
        }
        
        if ([identitifer isEqualToString:@"com.apple.mobileslideshow-Photos"]) {
            // iOS 3.x
            NSString *camera = NSLocalizedStringFromTableInBundle(@"Camera", @"UIRoleDisplayNames", appBundle, @"");
            
            // iOS 4.1
            if ([camera isEqualToString:@"Camera"]) {
                camera = NSLocalizedStringFromTableInBundle(@"Camera", @"Purple", appBundle, @"");
            }
            
            // if ([[[UIDevice currentDevice] systemVersion] compare:@"4.2"] == NSOrderedAscending)
            //     appName = [NSString stringWithFormat:@"%@(%@)", appName, camera];
        }
        
        if ([appName isEqualToString:@"MobileMusicPlayer"])
            appName = @"iPod";	// iOS4, iPod Name
        
        
        //icon
        NSString *iconName = nil;
        id iconNameArray = [plistDictionary objectForKey:@"CFBundleIconFiles"];
        if(iconNameArray && [iconNameArray isKindOfClass:[NSArray class]] && ([iconNameArray count]>0)){
            iconName = [iconNameArray objectAtIndex:0];
            if ([(NSArray *)iconNameArray containsObject:@"Icon.png"]
                || [(NSArray *)iconNameArray containsObject:@"Icon@2x.png"]
                || [(NSArray *)iconNameArray containsObject:@"Icon"]
                || [(NSArray *)iconNameArray containsObject:@"Icon@2x"]) {
                iconName = @"Icon.png";
            }
        } else {
            iconName = [plistDictionary objectForKey:@"CFBundleIconFile"];
            if([iconName isKindOfClass:[NSString class]]){
            }else if(iconName){
                ////NSLog(@"icon name is nil %@", iconName);
                iconName = nil;
            } else { //add for ios 5.1 camera, photo
                NSDictionary *bundleIcons = [plistDictionary objectForKey:@"CFBundleIcons"];
                if ([bundleIcons isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *primaryIcon = [bundleIcons objectForKey:@"CFBundlePrimaryIcon"];
                    if ([primaryIcon isKindOfClass:[NSDictionary class]]) {
                        id iconFiles = [primaryIcon objectForKey:@"CFBundleIconFiles"];
                        if ([iconFiles isKindOfClass:[NSArray class]]) {
                            for(id name in (NSArray *)iconFiles) {
                                if ([name isKindOfClass:[NSString class]]) {
                                    NSString *path = [self stringByAppendingPathComponent:name];
                                    BOOL isDirectory = NO;
                                    if ( [fileManager fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory) {
                                        iconName = name;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if([iconName hasSuffix:@".png"]){
        }else
            iconName = [iconName stringByAppendingString:@".png"];
        
        iconPath = [self stringByAppendingPathComponent:iconName];
        BOOL isDirectory = NO;
        if (![fileManager fileExistsAtPath:iconPath isDirectory:&isDirectory] || isDirectory)
        {
            if ([fileManager fileExistsAtPath:[self stringByAppendingPathComponent:@"Icon.png"]])
                iconPath = [self stringByAppendingPathComponent:@"Icon.png"];
            else if ([fileManager fileExistsAtPath:[self stringByAppendingPathComponent:@"icon.png"]])
                iconPath = [self stringByAppendingPathComponent:@"icon.png"];
            else if ([fileManager fileExistsAtPath:[self stringByAppendingPathComponent:@"icon-MediaPlayer.png"]])
                iconPath = [self stringByAppendingPathComponent:@"icon-MediaPlayer.png"]; // iPod
            else if ([fileManager fileExistsAtPath:[self stringByAppendingPathComponent:@"icon-Photos.png"]])
                iconPath = [self stringByAppendingPathComponent:@"icon-Photos.png"];
            else if ([fileManager fileExistsAtPath:[self stringByAppendingPathComponent:@"icon@2x.png"]]) 
                iconPath = [self stringByAppendingPathComponent:@"icon@2x.png"];
            else if ([fileManager fileExistsAtPath:[self stringByAppendingPathComponent:@"Icon@2x.png"]]) 
                iconPath = [self stringByAppendingPathComponent:@"Icon@2x.png"];
            else if ([fileManager fileExistsAtPath:[self stringByAppendingPathComponent:@"icon@2x~iphone.png"]]) 
                iconPath = [self stringByAppendingPathComponent:@"icon@2x~iphone.png"];
            else if ([fileManager fileExistsAtPath:[self stringByAppendingPathComponent:@"icon~iphone.png"]]) 
                iconPath = [self stringByAppendingPathComponent:@"icon~iphone.png"];
            else iconPath = nil;
        }
        
        NSString *stringSmallIconName = @"Icon-Small.png";
        smallIconPath = [self stringByAppendingPathComponent:stringSmallIconName];
        BOOL isDirectory2 = NO;
        if (![fileManager fileExistsAtPath:smallIconPath isDirectory:&isDirectory2] || isDirectory2)
        {
            smallIconPath = iconPath;
        }
        //version & path
        if ([self hasPrefix:@"/Applications/"]) {
            appVersion = [plistDictionary objectForKey:@"CFBundleShortVersionString"];
            appPath = self;
        }else if([self hasPrefix:@"/var/mobile/Applications/"]){
            appVersion = [plistDictionary objectForKey:@"CFBundleVersion"];
            appPath = [self stringByDeletingLastPathComponent];
        }
        
        //binary md5
        // appBinaryMd5 = [[plistDictionary objectForKey:@"CFBundleExecutable"] QHMd5String];

        
        if (appID && appName) {
            info = [NSMutableDictionary dictionaryWithCapacity:5];
            
            [info setValue:appName forKey:AppName];
            [info setValue:iconPath forKey:AppIconPath];
            [info setValue:smallIconPath forKey:AppSmallIconPath];
            [info setValue:appID forKey:AppID];
            [info setValue:appVersion forKey:AppVersion];
            // [info setValue:appBinaryMd5 forKey:AppBinaryMd5];
            [info setValue:appPath forKey:AppPath];
        }
    }
    
    return info;
}
@end
