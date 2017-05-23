//
//  WCFileController.h
//  IMDemo
//
//  Created by ziwen on 14-8-14.
//  Copyright (c) 2014年 wc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WCFileController : NSObject

+ (void)setupWithAppid:(NSNumber *)appid andUk:(NSNumber *)uk;

/**
 *  @brief  视频文件目录的路径
 *
 *  @return 视频目录路径
 */
+ (NSString *)videoPath;

/**
 *  @brief  图片文件目录的路径
 *
 *  @return 图片目录路径
 */
+ (NSString *)imagePath;

/**
 *  @brief  db目录路径
 *
 *  @return db目录路径
 */
+ (NSString *)dbPath;

/**
 *  @brief  音频目录路径
 *
 *  @return 音频目录路径
 */
+ (NSString *)audioPath;


/**
 *  @brief  删除图片文件缓存
 *
 *  @return 删除成功失败
 */
+ (BOOL)deleteCachedImages;
+ (BOOL)deleteCachedImagesFor3MonthAgo;

/**
 *  @brief  删除音频文件缓存
 *
 *  @return 删除成功失败
 */
+ (BOOL)deleteCachedAudioes;
+ (BOOL)deleteCachedAudioesFor3MonthAgo;

/**
 *  @brief  删除视频文件缓存
 *
 *  @return 删除成功失败
 */
+ (BOOL)deleteCachedVideoes;
+ (BOOL)deleteCachedVideoesFor3MonthAgo;

/**
 *  @brief  删除3个月前的图片、语音、视频数据
 */
+ (BOOL)deleteCachedForderFor3MonthAgo;
/**
 *  @brief  删除图片、语音、视频数据
 */
+ (BOOL)deleteCachedForder;
/**
 *  @brief  图片文件夹大小,单位字节B（Byte）
 */
+ (int64_t)imageFolderSize;

/**
 *  @brief  音频文件夹大小，单位字节B（Byte）
 */
+ (int64_t)audioFolderSize;

/**
 *  @brief  视频文件夹大小，单位字节B（Byte）
 */
+ (int64_t)videoFolderSize;

/**
 *  三个月前的图片、语音、视频文件大小，单位字节B（Byte）
 */
+ (int64_t)folderSizeFor3MonthAgo;
/**
 * 图片、语音、视频的文件大小，单位字节B（Byte）
 */
+ (int64_t)cachedFolderSize;

/**
 *  @brief  系统总容量，单位:B
 */
+ (float)totalDiskSpace;

/**
 *  @brief  系统剩余可用空间大小，单位:B
 */
+ (float)freeDiskSpace;

/**
 *  @brief  当前应用使用的硬盘空间，耗时操作，单位:B
 */
+ (float)appUsedSpace;

/**
 *  @brief  获取指定存储小数位数的浮点数，单位G,M,K  
 *   显示规则如下
 *      1.大于1G,转换为G单位的字符串+小数位数
 *      2.大于1M，则转化成M单位的字符串+ 小数位数
 *      3.不到1M,但是超过了1KB，则转化成KB单位+ 小数位数
 *      4.剩下的都是小于1K的，则转化成B单位
 *
 *  @param size          原值大小
 *  @param decimalplaces 指定小数位数大小
 *
 *  @return 获取指定存储小数位数的浮点数，单位G,M,K
 */
+ (NSString *)getStringWithStorage:(float)size decimalplaces:(NSInteger)decimalplaces;
@end
