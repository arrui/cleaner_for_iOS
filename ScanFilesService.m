//
//  ScanFilesService.m
//  
//
//  Created by yanrui on 12-11-1.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ScanFilesService.h"
#import "NSString+Addtion.h"
#include	<stdio.h>
#include    <sys/stat.h>
#include	<sys/types.h>
#include	<dirent.h>

#define USER_APP_PATH       "/var/mobile/Applications"
#define SCAN_LIST_PATH      "/var/mobile/Library/cleaner/scanList.txt"
#define CONFIG_PATH         @"/var/mobile/Library/cleaner/cleanConfig.plist"
#define kLogFile            @"log_file"
#define kCacheFile          @"cache_file"
#define kTmpFile            @"tmp_file"
#define kAppFile            @"app_file"
#define kFilePath           @"file_path"
#define kDirPath            @"dir_path"
#define kExceptFile         @"except_file"
#define kExceptFilePrefix   @"except_file_prefix"
#define kJunkSize           @"JunkSize"
#define kJunkCount          @"JunkCount"
#define kJunkArray          @"JunkArray"

#define debug_mode 1
#define log_mode 0
#define clean_mode 1

static ScanFilesService* scanService = nil;

@interface ScanFilesService(private) 
-(BOOL)hasSuffix:(const char*)suffix withPath:(char*)path;
-(NSMutableArray*)scanDirPath:(NSString*)dirPath withSuffix:(NSString*)suffix;
-(NSMutableArray*)scanDirPath:(NSString*)dirPath withExceptArray:(NSArray*)exceptArray;
-(NSMutableArray*)removeFiles:(NSMutableArray *)filesArray withExceptPrefixArray:(NSArray *)exceptPrefixArray;
-(NSString*)scanSpecifiedFilePath:(NSString*)specailFilePath;
-(void)reset;
-(void)scanOneApp:(NSString*)appPath withAppInfo:(NSDictionary*)appInfo;
-(void)scanUserAppCache:(char*)dir_path;
-(void)scanLogsWithPaths:(NSArray*)pathArray;
-(void)scanCachesWithPaths:(NSArray*)pathArray;
-(void)scanTempFilesWithPaths:(NSArray*)pathArray;
@end

@implementation ScanFilesService
@synthesize appResultArray;
@synthesize allFilesArray;
@synthesize logFilesArray;
@synthesize tmpFilesArray;
@synthesize cacheFilesArray;
@synthesize isCleaning;
@synthesize total_size;
@synthesize total_count;

+(id)sharedService{
    @synchronized(self){
        if (scanService == nil) {
            scanService = [[ScanFilesService alloc] init];
        }
    }
    return scanService;
}

-(id)init{
    if (self = [super init]) {
        //init
        appResultArray = [[NSMutableArray alloc] init];
        allFilesArray = [[NSMutableArray alloc] init];
        logFilesArray = [[NSMutableArray alloc] init];
        tmpFilesArray = [[NSMutableArray alloc] init];
        cacheFilesArray = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc{
    [logFilesArray release];
    [tmpFilesArray release];
    [cacheFilesArray release];
    [appResultArray release];
    [allFilesArray release];
    [super dealloc];
}


#pragma mark - scan files
/*
 * This function is to check whether the current file has 'suffix'
 */
-(BOOL)hasSuffix:(const char*)suffix withPath:(char*)path{
    return [[NSString stringWithUTF8String:path] hasSuffix:[NSString stringWithUTF8String:suffix]];
}

/*
 * This function is to scan files with 'suffix' in a dir
 * Use '*' to scan all files
 */
-(NSMutableArray*)scanDirPath:(NSString*)dirPath withSuffix:(NSString*)suffix{
    NSMutableArray* matchedArray = [[[NSMutableArray alloc] init] autorelease];
    
    const char* dir_path = [dirPath UTF8String];
    DIR *dir_ptr = NULL;
	struct dirent *direntp = NULL;
    dir_ptr = opendir(dir_path);
    if (dir_ptr) {
        while ((direntp = readdir(dir_ptr)) != NULL){
            if (strcmp(direntp->d_name, ".")==0 || strcmp(direntp->d_name, "..") == 0) {
                continue;
            }
            char* file_path = NULL;
            asprintf(&file_path, "%s/%s",dir_path,direntp->d_name);
            struct stat file_info;
            stat(file_path, &file_info);
            mode_t mode = file_info.st_mode;
            off_t size = file_info.st_size;
            NSString* filePath = [NSString stringWithUTF8String:file_path];
            if (S_ISDIR(mode)) {
                [self scanDirPath:filePath withSuffix:suffix];
            }
            else if (S_ISREG(mode)) {
                if ([suffix isEqualToString:@"*"] || [filePath hasSuffix:suffix]) {
                    total_size += size;
                    total_count += 1;
#if debug_mode
                    NSLog(@"%s  %lld",file_path,size);
#endif
#if log_mode
                    FILE* file = fopen(SCAN_LIST_PATH, "a+");
                    if (file) {
                        fwrite(file_path, strlen(file_path), 1, file);
                        fwrite("\n", 1, 1, file);
                        fclose(file);
                    }
#endif
                    [allFilesArray addObject:filePath];
                    [matchedArray addObject:filePath];
                }
            }
            free(file_path);
        }
        closedir(dir_ptr);
    }
    
    return matchedArray;
}


/*
 * This function is to scan a dir with except files
 */
-(NSMutableArray*)scanDirPath:(NSString*)dirPath withExceptArray:(NSArray*)exceptArray{
    NSMutableArray* matchedArray = [[[NSMutableArray alloc] init] autorelease];
    
    const char* dir_path = [dirPath UTF8String];
    DIR *dir_ptr = NULL;
	struct dirent *direntp = NULL;
    dir_ptr = opendir(dir_path);
    if (dir_ptr) {
        while ((direntp = readdir(dir_ptr)) != NULL){
            if (strcmp(direntp->d_name, ".")==0 || strcmp(direntp->d_name, "..") == 0) {
                continue;
            }
            char* file_path = NULL;
            asprintf(&file_path, "%s/%s",dir_path,direntp->d_name);
            struct stat file_info;
            stat(file_path, &file_info);
            mode_t mode = file_info.st_mode;
            off_t size = file_info.st_size;
            NSString* filePath = [NSString stringWithUTF8String:file_path];
            if (S_ISDIR(mode)) {
                [self scanDirPath:filePath withExceptArray:exceptArray];
            }
            else if (S_ISREG(mode)) {
                BOOL needClean = YES;
                if (exceptArray && [exceptArray count]>0) {
                    for (NSString* exceptFile in exceptArray) {
                        if ([exceptFile isEqualToString:filePath]) {
                            needClean = NO;
                            break;
                        }
                    }
                }
                
                //neend clean
                if (needClean) {
                    total_size += size;
                    total_count += 1;
#if debug_mode
                    NSLog(@"%s  %lld",file_path,size);
#endif
#if log_mode
                    FILE* file = fopen(SCAN_LIST_PATH, "a+");
                    if (file) {
                        fwrite(file_path, strlen(file_path), 1, file);
                        fwrite("\n", 1, 1, file);
                        fclose(file);
                    }
#endif
                    [allFilesArray addObject:filePath];
                    [matchedArray addObject:filePath];
                }
            }
            free(file_path);
        }
        closedir(dir_ptr);
    }
    
    return matchedArray;
}

/*
 * This function is to remove files in dir with specified prefix
 */
-(NSMutableArray*)removeFiles:(NSMutableArray *)filesArray withExceptPrefixArray:(NSArray *)exceptPrefixArray{
    NSMutableArray* returnArray = [[[NSMutableArray alloc] init] autorelease];
    
    for (NSString* filePath in filesArray) {
        for (NSString* exceptPrefix in exceptPrefixArray) {
            if ([filePath hasPrefix:exceptPrefix]) {
                const char* file_path = [filePath UTF8String];
                struct stat file_info;
                stat(file_path, &file_info);
                mode_t mode = file_info.st_mode;
                off_t size = file_info.st_size;
                total_size -= size;
                total_count -= 1;
#if debug_mode
                NSLog(@"!!!kickout!!! %s  %lld",file_path,size);
#endif
                [returnArray addObject:filePath];
                [allFilesArray removeObject:filePath];
                break;
            }
        }
    }
    return returnArray;
}

/*
 * This function is to scan a specified file with path
 */
-(NSString*)scanSpecifiedFilePath:(NSString*)specifiedFilePath{
    NSString* matchedFile = nil;
    
    const char* file_path = [specifiedFilePath UTF8String];
    struct stat file_info;
    stat(file_path, &file_info);
    off_t size = file_info.st_size;
    if (access(file_path, 0)==0) {
        total_size += size;
        total_count += 1;
#if debug_mode
        NSLog(@"%s  %lld",file_path,size);
#endif
#if log_mode
        FILE* file = fopen(SCAN_LIST_PATH, "a+");
        if (file) {
            fwrite(file_path, strlen(file_path), 1, file);
            fwrite("\n", 1, 1, file);
            fclose(file);
        }
#endif
        [allFilesArray addObject:specifiedFilePath];
        matchedFile = specifiedFilePath;
    }
    
    return matchedFile;
}

-(void)reset{
#if log_mode
    char* cmd = NULL;
    asprintf(&cmd, "rm -f \"%s\"", SCAN_LIST_PATH);
    system(cmd);
    free(cmd);
#endif
    isCleaning = YES;
    total_size = 0;
    total_count = 0;
    [allFilesArray removeAllObjects];
    [appResultArray removeAllObjects];
    [logFilesArray removeAllObjects];
    [tmpFilesArray removeAllObjects];
    [cacheFilesArray removeAllObjects];
}



/*
 * Scan for each app 
 */
-(void)scanOneApp:(NSString*)appPath withAppInfo:(NSDictionary*)appInfo{
    //TODO UI notify scaning which app ...
    
    NSMutableArray* appJunkArray = [[[NSMutableArray alloc] init] autorelease];
    SInt64 one_size = total_size;
    SInt32 one_count = total_count;
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:CONFIG_PATH];
    NSArray* appArray = [config objectForKey:kAppFile];

    for (NSDictionary* pathDic in appArray) {
        NSString* dir_path = [pathDic objectForKey:kDirPath];
        NSArray* except_file = [pathDic objectForKey:kExceptFile];
        NSMutableArray* junkArray = [self scanDirPath:[NSString stringWithFormat:dir_path,appPath] withExceptArray:except_file];
        [appJunkArray addObjectsFromArray:junkArray];
    }

    one_size = total_size - one_size;
    one_count = total_count - one_count;
    [appInfo setValue:[NSString stringWithFormat:@"%lld",one_size] forKey:kJunkSize];
    [appInfo setValue:[NSString stringWithFormat:@"%d",one_count] forKey:kJunkCount];
    [appInfo setValue:appJunkArray forKey:kJunkArray];
    [appResultArray addObject:appInfo];
}

-(void)scanUserAppCache:(char*)dir_path{
    DIR *dir_ptr = NULL;
	struct dirent *direntp = NULL;
    dir_ptr = opendir(dir_path);
    if (dir_ptr) {
        while ((direntp = readdir(dir_ptr)) != NULL){
            if (strcmp(direntp->d_name, ".")==0 || strcmp(direntp->d_name, "..") == 0) {
                continue;
            }
            
            char* file_path = NULL;
            asprintf(&file_path, "%s/%s",dir_path,direntp->d_name);
            struct stat file_info;
            stat(file_path, &file_info);
            mode_t mode = file_info.st_mode;
            off_t size = file_info.st_size;
            
            //get app info & display name
            if (S_ISDIR(mode)) {
                if ([self hasSuffix:".app" withPath:file_path]) {
                    NSDictionary *appInfo = nil;
                    if ((appInfo =  [[NSString stringWithUTF8String:file_path] appInfo])) {
                        [self scanOneApp:[appInfo objectForKey:AppPath] withAppInfo:appInfo];
                        continue;
                    }
                }else{
                    [self scanUserAppCache:file_path];
                }
            }

            free(file_path);
        }
        closedir(dir_ptr);
    }

}

-(void)scanLogsWithPaths:(NSArray*)pathArray{
    for (NSDictionary* pathDic in pathArray) {
        NSString* dir_path = [pathDic objectForKey:kDirPath];
        NSArray* except_file = [pathDic objectForKey:kExceptFile];
        NSString* file_path = [pathDic objectForKey:kFilePath];
        if (dir_path) {
            NSMutableArray* array = [self scanDirPath:dir_path withExceptArray:except_file];
            [logFilesArray addObjectsFromArray:array];
        }else if(file_path){
            NSString* file = [self scanSpecifiedFilePath:dir_path];
            if (file && [file length]>0) {
                [logFilesArray addObject:file];
            }
        }
    }
}

-(void)scanCachesWithPaths:(NSArray*)pathArray{
    for (NSDictionary* pathDic in pathArray) {
        NSString* dir_path = [pathDic objectForKey:kDirPath];
        NSArray* except_file = [pathDic objectForKey:kExceptFile];
        NSString* file_path = [pathDic objectForKey:kFilePath];
        if (dir_path) {
            NSMutableArray* array = [self scanDirPath:dir_path withExceptArray:except_file];
            [cacheFilesArray addObjectsFromArray:array];
        }else if(file_path){
            NSString* file = [self scanSpecifiedFilePath:dir_path];
            if (file && [file length]>0) {
                [cacheFilesArray addObject:file];
            }
        }
    }
}

-(void)scanTempFilesWithPaths:(NSArray*)pathArray{
    for (NSDictionary* pathDic in pathArray) {
        NSString* dir_path = [pathDic objectForKey:kDirPath];
        NSArray* except_file = [pathDic objectForKey:kExceptFile];
        NSArray* except_file_prefix = [pathDic objectForKey:kExceptFilePrefix];
        NSString* file_path = [pathDic objectForKey:kFilePath];
        if (dir_path) {
            NSMutableArray* array = [self scanDirPath:dir_path withExceptArray:except_file];
            array = [self removeFiles:array withExceptPrefixArray:except_file_prefix];
            [tmpFilesArray addObjectsFromArray:array];
        }else if(file_path){
            NSString* file = [self scanSpecifiedFilePath:dir_path];
            if (file && [file length]>0) {
                [tmpFilesArray addObject:file];
            }
        }
    }
}


-(void)scanAllPaths{
    [self reset];
    
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:CONFIG_PATH];
    NSArray* logArray = [config objectForKey:kLogFile];
    NSArray* cacheArray = [config objectForKey:kCacheFile];
    NSArray* tmpArray = [config objectForKey:kTmpFile];
    [self scanUserAppCache:USER_APP_PATH];
    [self scanLogsWithPaths:logArray];
    [self scanCachesWithPaths:cacheArray];
    [self scanTempFilesWithPaths:tmpArray];
#if debug_mode
    NSLog(@"============total_size:%lld,total_count:%ld============",total_size,total_count);
#endif
#if log_mode
    char* total_info = NULL;
    asprintf(&total_info, "total_size:%lld,total_count:%ld",total_size,total_count);
    FILE* file = fopen(SCAN_LIST_PATH, "a+");
    if (file) {
        fwrite(total_info, strlen(total_info), 1, file);
        fwrite("\n", 1, 1, file);
        fclose(file);
    }
    free(total_info);
#endif
    isCleaning = NO;
}


#pragma mark - clean files
-(void)cleanFiles{
#if clean_mode
    //TODO: deal with allFilesArray to kick out the unselected items
    
    for (NSString* file in allFilesArray) {
        char* cmd = NULL;
        asprintf(&cmd, "rm -f \"%s\"", [file UTF8String]);
#if debug_mode
        NSLog(@"rm -f \"%@\"",file);
#endif
        system(cmd);
        free(cmd);
    }
#if debug_mode
    NSLog(@"============clean done total_size:%lld,total_count:%ld============",total_size,total_count);
#endif
#endif
}

@end
