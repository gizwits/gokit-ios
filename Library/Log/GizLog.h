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
    
#define GIZ_CLOSE(fd)    GizClose(fd, __FILENAME__, __LINE__, __FUNCTION__)

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

/**
 * @brief 日志初始化.
 * @param[in] sysInfoJson- 系统信息(Json字符串，例:{"phone_id":"AE27466D-9C8F-4184-A6A3-2A0CDEDAA4FD","os":"iOS","os_ver":"9.2","app_version":"1.5.1","phone_model":"iPhone 6 (A1549/A1586)"}).
 * @param[in] logDir- 存储日志目录的路径(推荐采用程序私有目录,例:/var/mobile/Containers/Data/Application/1D7A5CD8-70D2-4B46-A76A-8B9BE5CBC88C/Documents").
 * @param[in] printLevel- 日志打印到屏幕的级别(0:不打印屏幕,1:打印error+busi,2:打印error+debug+busi).
 * @return 返回日志初始化结果,0:成功,1:sysInfoJson非法,2:logDir指定错误(目录为空、不存在或无法创建文件等),3:printLevel非法.
 *
 */
int GizLogInit(const char *sysInfoJson, const char *logDir, int printLevel);

/**
 * @brief 日志上传检测,如要上传则新建线程上传日志.
 * @param[in] domain- 日志待上传的服务器域名地址.
 * @param[in] port- 日志待上传的服务器端口.
 * @param[in] appID- 指定应用标识地址.
 * @param[in] uid- 指定用户标识码地址.
 * @param[in] token- 指定远程用户令牌地址.
 * @return 日志上传检测结果,0:成功,1:失败.
 *
 */
int GizLogProvision(const char *domain, int port, const char *appID, const char *uid, const char *token);

/**
 * @brief 打印来至上层的业务日志.
 * @param[in] content- 业务日志内容.
 * @see content内容格式为[BIZ][时间][业务码][执行结果][描述]
 * @see 例:[BIZ][2015-11-24 11:20:49.309][usr_login_req][SUCCESS][用户登录请求]
 *
 */
void GizPrintBizFromUp(const char *content);

/**
 * @brief 打印来至上层的错误日志.
 * @param[in] content- 错误日志内容.
 * @see content内容格式为[SYS][ERROR][时间][文件名:行号 函数名][日志体]
 * @see 例:[SYS][ERROR][2015-11-24 11:20:49.309][tool.c:937 connect] [conect 192.168.1.108:12906 failed, connection refused]
 *
 */
void GizPrintErrorFromUp(const char *content);

/**
 * @brief 打印来至上层的调试日志.
 * @param[in] content- 调试日志内容.
 * @see content内容格式为[SYS][DEBUG][时间][文件名:行号 函数名][日志体]
 * @see 例:[SYS][DEBUG][2015-11-24 11:20:49.309][tool.c:937 connect] [conect 192.168.1.108:12906 success, fd 127]
 *
 */
void GizPrintDebugFromUp(const char *content);

//内部使用
char *GizTimeStr(void);
void GizClose(int fd, const char *file, int line, const char *function);
void GizPrintBiz(const char *businessCode, const char *result, const char *format, ...);
void GizPrintError(const char *format, ...);
void GizPrintDebug(const char *format, ...);

#ifdef __cplusplus
//}
#endif
#endif
