
/**
 *   Copyright © 2017年 Beijing Kungeek Science & Technology Ltd. All rights reserved.
 */

/*!
 * 文件名: NSString+FtspDeviceInfo.h
 * 项目名: FtspiOSClient
 * 描述:
 * @author 陈夏阳 chenxiayang@kungeek.com
 * @version 1.0.0
 * 创建日期 2017/5/11
 * 修改记录
 *    修改后版本:     修改人：  修改日期:     修改内容:
 *
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (MHSDeviceInfo)

/*!
 *  获取手机机型
 *
 */
+ (NSString*)ftsp_getDeviceVersion;

/*!
 *  获取手机分辨率
 *
 */
+ (NSString *)ftsp_getResolutionRatio;

/// 屏幕宽度
+ (CGFloat)ftsp_getDeviceScreenWidth;

/// 屏幕高度
+ (CGFloat)ftsp_getDeviceScreenHeight;

/// 获取iPhone名称
+ (NSString *)ftsp_getiPhoneName;

/// 获取app版本号
+ (NSString *)ftsp_getAPPVerion;

/// 获取电池电量
+ (CGFloat)ftsp_getBatteryLevel;

/// 当前系统名称
+ (NSString *)ftsp_getSystemName;

/// 当前系统版本号
+ (NSString *)ftsp_getSystemVersion;

/// 通用唯一识别码UUID
+ (NSString *)ftsp_getUUID;

/// 获取当前设备IP
+ (NSString *)ftsp_getDeviceIPAdress;

/// 获取当前语言
+ (NSString *)ftsp_getDeviceLanguage;

/*!
 *  获取IP地址
 *
 *  @param preferIPv4 是否只在ipv4
 *
 *  @return 返回ip地址
 */
+ (NSString *)ftsp_getIPAddress:(BOOL)preferIPv4;

/**
 *  获取随机码
 *
 *  @return 返回随机码的字段
 */
+ (NSString *)ftsp_getUniqueStringByUUID;


/**
 对渠道信息拼接UUID

 @return 返回拼接的结果
 */
+ (NSString *)ftsp_channelAppendingUUID;
@end


