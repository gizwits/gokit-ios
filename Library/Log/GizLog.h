/**
 *   GizWits log module
 *
 * Copyright (c) 2015 GizWits. *
 * @file
 * @brief GizWits log module.
 * @author Trevor <trevortao@gizwits.com>
 * @date 2015/11/26
 *
 *   Change Logs:
 * Date          Author      Notes
 * 2015-11-26    Trevor      the first version
 */
#ifndef __GizLog_h__
#define __GizLog_h__

#ifdef __cplusplus
//extern "C" {
#endif

#include <stdio.h>
#include <string.h>

#ifdef __ANDROID__
#define LOG_TAG                 "GizLog"
#include <android/log.h>
#endif

#define LOG_MAX_RENAME_SYS_TIME     (10 * 60)
#define LOG_MAX_SYS_FILE_SIZE       (100 * 1024)
#define LOG_MAX_PATH_LEN            (256)
#define LOG_MAX_LEN                 (10 * 1024)
#define LOG_COLUMN_PER_LINE         (16)
#define LOG_FILE_NAME               "GizLogFile"

#define LOG_HTTP_TIMEOUT            (5)
#define LOG_IP_BUF_LENGTH           (16)
#define LOG_READ_BUF_LENGTH         (4096)
#define LOG_SEND_BUF_LENGTH         (4096)
#define LOG_HTTP_STATUS_OK          (200)
#define LOG_HTTP_BOUNDARY           "----GizLogBoundaryGizWits"

#define __FILENAME__    ((strrchr(__FILE__, '/') ?: __FILE__ - 1) + 1)  //如果__FILE__编译为绝对路径（如xCode上），则只截取文件名

/**
 * @brief 输出APP业务日志.
 * @param[in] businessCode- 业务码.
 * @param[in] result- 执行结果.
 * @param[in] fmt, args...- 描述(和printf一样的输入参数).
 * @see 输出结果举例:[APPBIZ][2015-11-24 11:20:49.309][usr_login_req][SUCCESS][用户登录请求]
 *
 */
#define GIZ_LOG_BIZ(businessCode, result, fmt, args...)  GizPrintBiz(businessCode, result, "[" fmt"]", ##args)


/**
 * @brief 输出APP错误日志.
 * @param[in] fmt, args...- 描述(和printf一样的输入参数).
 * @see 输出结果举例:[APPSYS][ERROR][2015-11-24 11:20:49.309][tool.c:937 connect] [conect 192.168.1.108:12906 failed, connection refused]
 *
 */
#define GIZ_LOG_ERROR(fmt, args...)  GizPrintError("[APPSYS][ERROR][%s][%s:%d %s][" fmt"]", GizTimeStr(), __FILENAME__, __LINE__, __FUNCTION__, ##args)

/**
 * @brief 输出APP调试日志.
 * @param[in] fmt, args...- 描述(和printf一样的输入参数).
 * @see 输出结果举例:[APPSYS][DEBUG][2015-11-24 11:20:49.309][tool.c:937 connect] [conect 192.168.1.108:12906 success, fd 127]
 *
 */
#define GIZ_LOG_DEBUG(fmt, args...)  GizPrintDebug("[APPSYS][DEBUG][%s][%s:%d %s][" fmt"]", GizTimeStr(), __FILENAME__, __LINE__, __FUNCTION__, ##args)
    
/*
 * 日志信息结构体
 */
typedef struct _GizLog_t {
    int printLevel; //日志打印到屏幕的级别(0:不打印屏幕,1:打印error+busi,2:打印error+debug+busi,默认2)
    int port; //日志服务器端口
    int uploadSystemLog; //是否上传系统日志
    int uploadBusinessLog; //是否上传业务日志
    time_t latestCreatThreadTimestamp; //最新创建线程的时间戳
    time_t latestCreatSysLogTimestamp; //最新创建系统日志文件的时间戳
    char dir[LOG_MAX_PATH_LEN + 1]; //日志文件存储目录
    char *sysInfoJson; //系统信息(Json字符串，例:{"phone_id":"AE27466D-9C8F-4184-A6A3-2A0CDEDAA4FD","os":"iOS","os_ver":"9.2","app_version":"1.5.1","phone_model":"iPhone 6 (A1549/A1586)"}).
    char *domain; //日志服务器域名
    char *appID; //应用标识
    char *uid; //用户标识
    char *token; //用户令牌
    FILE *fileBiz; //业务日志文件句柄
    FILE *fileSys; //系统日志文件句柄
} GizLog_t;


//内部使用
char *GizTimeStr(void);
void GizPrintBiz(const char *businessCode, const char *result, const char *format, ...);
void GizPrintError(const char *format, ...);
void GizPrintDebug(const char *format, ...);

#ifdef __cplusplus
//}
#endif
#endif
