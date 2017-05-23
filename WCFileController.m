//
//  WCFileController.m
//  IMDemo
//
//  Created by ziwen on 14-8-14.
//  Copyright (c) 2014年 wc. All rights reserved.
//
#include <sys/stat.h>
#include <dirent.h>

#import "WCFileController.h"
#include <sys/param.h>
#include <sys/mount.h>

// 获取时间间隔
#define TICK  CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

#define TOCK   CFAbsoluteTime end = CFAbsoluteTimeGetCurrent(); \
NSLog(@"time=%f",end -start);

//获取沙盒Cache目录路径
#define WC_CACHE_PATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]

// 获取home目录路径
#define WC_HOME_PATH NSHomeDirectory()
static NSNumber *im_appid;
static NSNumber *im_uid;
static NSString *bim_rootPath = nil;
static NSString *bim_sharePath = nil;

@implementation WCFileController

+ (void)setupWithAppid:(NSNumber *)appid andUk:(NSNumber *)uk {
    if (appid && uk)
    {
        im_appid = appid;
        im_uid = uk;
        bim_rootPath = [[[WC_CACHE_PATH stringByAppendingPathComponent:@"com.wc/"] stringByAppendingFormat:@"/%@/", im_appid] stringByAppendingString:[im_uid stringValue]];
        [self setup];
    }
    else
    {
        im_appid = appid;
        im_uid = uk;
        bim_rootPath = nil;
    }
}

+ (void)setup {

    //不存在根目录，创建根目录
    //    if (![[NSFileManager defaultManager] fileExistsAtPath:bim_rootPath isDirectory:&isDir] || !isDir){
    //        [[NSFileManager defaultManager] createDirectoryAtPath:bim_rootPath withIntermediateDirectories:YES attributes:nil error:nil];
    //    }

    @try {
        NSString *dbDirPath = [bim_rootPath stringByAppendingPathComponent:@"db"];
        [[self class] createDir:dbDirPath];

        NSString *dataDirPath = [bim_rootPath stringByAppendingPathComponent:@"data"];
        [[self class] createDir:dataDirPath];

        NSString *logDirPath = [bim_rootPath stringByAppendingPathComponent:@"log"];
        [[self class] createDir:logDirPath];

        //公共目录文件
        //不存在share目录，创建share目录
        NSString *sharePath = [WCFileController sharePath];
        NSString *imgDirPath = [sharePath stringByAppendingPathComponent:@"img"];
        [[self class] createDir:imgDirPath];

        NSString *videoDirPath = [sharePath stringByAppendingPathComponent:@"video"];
        [[self class] createDir:videoDirPath];

        NSString *audioDirPath = [sharePath stringByAppendingPathComponent:@"audio"];
        [[self class] createDir:audioDirPath];

        NSString *crashDirPath = [sharePath stringByAppendingPathComponent:@"log"];
        [[self class] createDir:crashDirPath];

        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[self class] moveAndDeleteImgSourceFile];
            [[self class] moveAndDeleteAudioSourceFile];
            [[self class] moveAndDeleteVideoSourceFile];
        });

    }
    @catch (NSException *exception) {

    }
}


+ (void)createDir:(NSString *)path {
    BOOL isDir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] || !isDir){
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (void)moveAndDeleteImgSourceFile {
    [[self class] moveFilesAndDelFolder:[bim_rootPath stringByAppendingPathComponent:@"img"] toPath:[[self class] imagePath]];
}

+  (void)moveAndDeleteAudioSourceFile {
    [[self class] moveFilesAndDelFolder:[bim_rootPath stringByAppendingPathComponent:@"audio"] toPath:[[self class] audioPath]];
}

+  (void)moveAndDeleteVideoSourceFile {
    [[self class] moveFilesAndDelFolder:[bim_rootPath stringByAppendingPathComponent:@"video"] toPath:[[self class] videoPath]];
}

+ (void)moveFilesAndDelFolder:(NSString *)sourcePath toPath:(NSString *)destPath {
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:sourcePath isDirectory:&isDir] && isDir){
        NSDirectoryEnumerator *subfilePaths = [[NSFileManager defaultManager] enumeratorAtPath:sourcePath];
        NSString *subfilePath = nil;
        BOOL isMoved = YES;
        while ((subfilePath = [subfilePaths nextObject]) != nil){
            NSString *filePath = [sourcePath stringByAppendingPathComponent:subfilePath];
            isMoved &= [[self class] moveMissingFile:filePath toPath:destPath];
        }
        if (isMoved) {
            [[NSFileManager defaultManager] removeItemAtPath:sourcePath error:nil];
        }
    }
}

+ (BOOL)moveMissingFile:(NSString *)sourceFilePath toPath:(NSString *)toPath {
    BOOL retVal = YES; // If the file already exists, we'll return success…
    NSString * finalLocation = [toPath stringByAppendingPathComponent:[sourceFilePath lastPathComponent]];
    BOOL isDir = NO;
    BOOL fileExit = [[NSFileManager defaultManager] fileExistsAtPath:finalLocation isDirectory:&isDir];
    if (!fileExit) {
        retVal = [[NSFileManager defaultManager] moveItemAtPath:sourceFilePath toPath:finalLocation error:NULL];
    }
    //    else if(fileExit && !isDir){//exist && !Document , cover it
    //        retVal = [[NSFileManager defaultManager] removeItemAtPath:finalLocation error:NULL];
    //        retVal &= [[NSFileManager defaultManager] moveItemAtPath:sourceFilePath toPath:finalLocation error:NULL];
    //    }
    return retVal;
}

+ (NSString *)imagePath {
    return [[[self class] sharePath] stringByAppendingPathComponent:@"img"];
}

+ (NSString *)audioPath {
    return [[[self class] sharePath] stringByAppendingPathComponent:@"audio"];
}

+ (NSString *)videoPath {
    return [[[self class] sharePath] stringByAppendingPathComponent:@"video"];
}

+ (NSString *)sharePath {
    if (!bim_sharePath) {
        bim_sharePath = [WC_CACHE_PATH stringByAppendingPathComponent:@"com.wc/share"];
    }
    return  bim_sharePath;
}

+ (BOOL)deleteCachedImages {
    return [[self class] deleteFilesInFolder:[[self class] imagePath] maxDeleteTime:nil];
}


+ (BOOL)deleteCachedAudioes {
    return [[self class] deleteFilesInFolder:[[self class] audioPath] maxDeleteTime:nil];
}

+ (BOOL)deleteCachedVideoes {
    return [[self class] deleteFilesInFolder:[[self class] videoPath] maxDeleteTime:nil];
}

+ (BOOL)deleteCachedImagesFor3MonthAgo{
    NSNumber *maxDeleteTime = [[self class] maxTimeOf3Month];
    return [[self class] deleteFilesInFolder:[[self class] imagePath] maxDeleteTime:maxDeleteTime];
}

+ (BOOL)deleteCachedAudioesFor3MonthAgo{
    NSNumber *maxDeleteTime = [[self class] maxTimeOf3Month];
    return [[self class] deleteFilesInFolder:[[self class] audioPath] maxDeleteTime:maxDeleteTime];
}

+ (BOOL)deleteCachedVideoesFor3MonthAgo{
    NSNumber *maxDeleteTime = [[self class] maxTimeOf3Month];
    return [[self class] deleteFilesInFolder:[[self class] videoPath] maxDeleteTime:maxDeleteTime];
}

+ (BOOL)deleteCachedForderFor3MonthAgo
    {
        BOOL success = YES;
        success &= [self deleteCachedImagesFor3MonthAgo];
        success &=  [self deleteCachedAudioesFor3MonthAgo];
        success &=  [self deleteCachedVideoesFor3MonthAgo];
        return success;
    }

+ (BOOL)deleteCachedForder
    {
        BOOL success = YES;
        success &= [self deleteCachedImages];
        success &= [self deleteCachedAudioes];
        success &= [self deleteCachedVideoes];
        return success;
    }

+(NSNumber *)maxTimeOf3Month{
    int64_t maxTime = ([[NSDate date] timeIntervalSince1970] - 3 * 30 * 24 * 60 * 60 ) * 1000000 ;
    return @(maxTime);
}

+ (BOOL)deleteFilesInFolder:(NSString *)folderPath maxDeleteTime:(NSNumber *)maxDeleteTime{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    BOOL deleteSuccess = YES;
    while ((filename = [e nextObject]))
    {
        BOOL shouldDelete = YES;
        if (maxDeleteTime)
        {
            NSComparisonResult result = [filename compare:[maxDeleteTime stringValue]];
            if (result == NSOrderedDescending)//小于三个月不删
            {
                shouldDelete = NO;
            }
        }

        if (shouldDelete)
        {
            deleteSuccess &= [[NSFileManager defaultManager] removeItemAtPath:[folderPath stringByAppendingPathComponent:filename] error:NULL];
        }
    }
    return deleteSuccess;
}

    // 1000 个文件 平均时间：0.00487 和用OC的差15倍
+ (int64_t)imageFolderSize {
    return  [[self class] sizeOfFolder:[[self class] imagePath] ];
}

+ (int64_t)audioFolderSize {
    return [[self class] sizeOfFolder:[[self class] audioPath] ];
}

+ (int64_t)videoFolderSize {
    return [[self class] sizeOfFolder:[[self class] videoPath] ];
}

+ (int64_t)folderSizeFor3MonthAgo{
    NSNumber *maxTime = [[self class] maxTimeOf3Month];
    int64_t folderSize = 0;
    folderSize += [self folderSizeAtPath:[[[self class] videoPath] cStringUsingEncoding:NSUTF8StringEncoding] maxTime:maxTime];
    folderSize += [self folderSizeAtPath:[[[self class] audioPath] cStringUsingEncoding:NSUTF8StringEncoding] maxTime:maxTime];
    folderSize += [self folderSizeAtPath:[[[self class] imagePath] cStringUsingEncoding:NSUTF8StringEncoding] maxTime:maxTime];
    return folderSize;
}

+ (int64_t)cachedFolderSize
    {
        int64_t folderSize = 0;
        folderSize += [self imageFolderSize];
        folderSize += [self audioFolderSize];
        folderSize += [self videoFolderSize];
        return folderSize;
    }

+ (int64_t)sizeOfFolder:(NSString *)folderPath {
    return [self folderSizeAtPath:[folderPath cStringUsingEncoding:NSUTF8StringEncoding] maxTime:nil];
}

    // 方法3：完全使用unix c函数 性能最好
    //实测  1000个文件速度 0.005896
+ (int64_t)folderSizeAtPath:(const char *)folderPath maxTime:(NSNumber *)maxTime{

    CFAbsoluteTime startTime =CFAbsoluteTimeGetCurrent();

    int64_t folderSize = 0;
    DIR* dir = opendir(folderPath);


    if (dir == NULL) return 0;
    struct dirent* child;
    while ((child = readdir(dir))!=NULL) {
        if (child->d_type == DT_DIR && (
                                        (child->d_name[0] == '.' && child->d_name[1] == 0) || // 忽略目录 .
                                        (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0) // 忽略目录 ..
                                        )) continue;

        int64_t folderPathLength = strlen(folderPath);

        // 子文件的路径地址
        char childPath[1024];
        stpcpy(childPath, folderPath);

        if (folderPath[folderPathLength-1] != '/') {
            childPath[folderPathLength] = '/';
            folderPathLength++;
        }

        stpcpy(childPath+folderPathLength, child->d_name);
        childPath[folderPathLength + child->d_namlen] = 0;

        if (child->d_type == DT_DIR) { // directory
            // 递归调用子目录
            folderSize += [[self class] folderSizeAtPath:childPath maxTime:maxTime];

            // 把目录本身所占的空间也加上
            struct stat st;
            if(lstat(childPath, &st) == 0) folderSize += st.st_size;
        }else if (child->d_type == DT_REG || child->d_type == DT_LNK) { // file or link
            //特殊处理几个月前的内容
            if (maxTime) {
                BOOL shouldCountSize = YES;
                char *p = child->d_name;
                NSString *fileName = [NSString stringWithCString:p encoding:NSUTF8StringEncoding];
                NSComparisonResult result = [fileName compare:[maxTime stringValue]];
                if (result == NSOrderedDescending)//小于三个月不统计
                {
                    shouldCountSize = NO;
                }

                if (!shouldCountSize) {
                    continue;
                }
            }

            struct stat st;
            if(lstat(childPath, &st) == 0) folderSize += st.st_size;
        }
    }
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
     NSLog(@"ttttttttttt:%s,%f,%lld",__func__,endTime-startTime,folderSize);
    return folderSize;
}

    // 方法1：使用NSFileManager来实现获取文件大小
+ (long long)fileSizeAtPath1:(NSString *)filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

    // 方法1：使用unix c函数来实现获取文件大小
+ (long long)fileSizeAtPath2:(NSString *)filePath{
    struct stat st;
    if(lstat([filePath cStringUsingEncoding:NSUTF8StringEncoding], &st) == 0){
        return st.st_size;
    }
    return 0;
}

#pragma mark 获取目录大小


    //实测 ：1000个文件 读取 平均时间为：0.079914
    // 方法1：循环调用fileSizeAtPath1
+ (long long)folderSizeAtPath1:(NSString *)folderPath{
    CFAbsoluteTime startTime =CFAbsoluteTimeGetCurrent();
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        //        if ([self fileSizeAtPath1:fileAbsolutePath] != [self fileSizeAtPath2:fileAbsolutePath]){
        //            BIMLogWarn(@"%@, %lld, %lld", fileAbsolutePath,
        //                  [self fileSizeAtPath1:fileAbsolutePath],
        //                  [self fileSizeAtPath2:fileAbsolutePath]);
        //        }
        folderSize += [self fileSizeAtPath1:fileAbsolutePath];
    }
    CFAbsoluteTime endTime =CFAbsoluteTimeGetCurrent();
    NSLog(@"ttttttttttt:%s,%f,%lld",__func__,endTime-startTime,folderSize);
    return folderSize;
}

    // 1000个文件平均时间为：0.02653
    // 方法2：循环调用fileSizeAtPath2
+ (long long)folderSizeAtPath2:(NSString *)folderPath{
    TICK
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath2:fileAbsolutePath];
    }
    TOCK
    return folderSize;
}


+ (NSString *)getCachesDirectoryPath
    {
        NSArray * path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        return [path lastObject];
    }

    //获取当前任务所占用的内存（单位：MB）
+ (float)appUsedSpace
    {
        float usedSpace = 0;
        usedSpace += [[self class] folderSizeAtPath:[WC_HOME_PATH cStringUsingEncoding:NSUTF8StringEncoding] maxTime:nil];
        return usedSpace;
    }

    //0.000117 + 0.000082   //效率提高1倍
+ (float)availableDiskSpace {
    struct statfs buf;
    long long freespace = -1;
    if(statfs("/var", &buf) >= 0){
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }

    return freespace;
}

+ (float)freeDiskSpace {
    return [[self class] availableDiskSpace];


    //TICK  // 0.000222 + 0.000147
    //    float freeSpace;
    //    NSError * error;
    //    NSDictionary * infoDic = [[NSFileManager defaultManager] attributesOfFileSystemForPath: NSHomeDirectory() error: &error];
    //    if (infoDic) {
    //        NSNumber * fileSystemSizeInBytes = [infoDic objectForKey: NSFileSystemFreeSize];
    //        freeSpace = [fileSystemSizeInBytes floatValue];
    //         TOCK
    //        return freeSpace;
    //    } else {
    //        //NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    //        return 0;
    //    }
}

    //硬盘容量,0.000412 +0.000278
+ (float)totalDiskSpace {
    TICK
    float totalSpace;
    NSError * error;
    NSDictionary * infoDic = [[NSFileManager defaultManager] attributesOfFileSystemForPath: NSHomeDirectory() error: &error];
    if (infoDic) {
        NSNumber * fileSystemSizeInBytes = [infoDic objectForKey: NSFileSystemSize];
        totalSpace = [fileSystemSizeInBytes floatValue];
        TOCK
        return totalSpace;
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
        return 0;
    }
}



+ (NSString *)getStringWithStorage:(float)size decimalplaces:(NSInteger)decimalplaces {
    //四舍五入
    NSDecimalNumberHandler *roundBankers = [NSDecimalNumberHandler
                                            decimalNumberHandlerWithRoundingMode:NSRoundBankers
                                            scale:decimalplaces
                                            raiseOnExactness:NO
                                            raiseOnOverflow:NO
                                            raiseOnUnderflow:NO
                                            raiseOnDivideByZero:YES];

    NSDecimalNumber *origin = [[NSDecimalNumber alloc] initWithFloat:size];
    NSDecimalNumber *div = nil;

    NSString *sub = @"";

    if (size>1024*1024*1024)
    {
        div =[[NSDecimalNumber alloc] initWithFloat:1024.0*1024.0*1024.0];
        sub = @"G";
    }
    else if(size<1024*1024*1024&&size>=1024*1024)//大于1M，则转化成M单位的字符串
    {
        div =[[NSDecimalNumber alloc] initWithFloat:1024.0*1024.0];
        sub = @"M";
    }
    else if(size>=1024&&size<1024*1024) //不到1M,但是超过了1KB，则转化成KB单位
    {
        div =[[NSDecimalNumber alloc] initWithFloat:1024.0];
        sub = @"K";
    }
    else//剩下的都是小于1K的，则转化成B单位
    {
        div =[[NSDecimalNumber alloc] initWithFloat:1.0];
        sub = @"";
    }
    
    NSDecimalNumber *number = [origin decimalNumberByDividingBy:div withBehavior:roundBankers];
    return [NSString stringWithFormat:@"%@%@",number,sub];
}
    @end
