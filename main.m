#import <Foundation/Foundation.h>
#import "ScanFilesService.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <time.h>


int main(int argc, char* argv[]){
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    [[ScanFilesService sharedService] scanAllPaths];
	if(argc > 1 && strcmp(argv[1],"-c")==0){
	    [[ScanFilesService sharedService] cleanFiles];
	}
	
    //printf("test print\n");
	// CFRunLoopRun();
    [pool release];
	return 0;
}


