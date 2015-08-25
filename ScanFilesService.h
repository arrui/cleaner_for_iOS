//
//  ScanFilesService.h
//  
//
//  Created by yanrui on 12-11-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>


@interface ScanFilesService : NSObject{
    SInt64 total_size;
    SInt32 total_count;
    NSMutableArray* appResultArray;             //every app info
    NSMutableArray* allFilesArray;              //files to be cleaned
    NSMutableArray* logFilesArray;
    NSMutableArray* tmpFilesArray;
    NSMutableArray* cacheFilesArray;
    BOOL isCleaning;
}
@property(retain,nonatomic)NSMutableArray* appResultArray;
@property(retain,nonatomic)NSMutableArray* allFilesArray;
@property(retain,nonatomic)NSMutableArray* logFilesArray;
@property(retain,nonatomic)NSMutableArray* tmpFilesArray;
@property(retain,nonatomic)NSMutableArray* cacheFilesArray;
@property(assign,nonatomic)BOOL isCleaning;
@property(assign,nonatomic)SInt64 total_size;
@property(assign,nonatomic)SInt32 total_count;

+(id)sharedService;
-(void)scanAllPaths;
-(void)cleanFiles;

@end
