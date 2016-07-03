#include <time.h>
#include <stdio.h>
#include <errno.h>
#include <netdb.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <arpa/inet.h>
#include <netinet/ip.h>
#include <sys/socket.h>

#ifdef __cplusplus
extern "C" {
#endif

#include "GizLog.h"

#ifdef TARGET_OS_IPHONE
#import <Foundation/Foundation.h>
#endif

static GizLog_t gGizLog = { 3 };   //默认打印error+debug+data+busi
static pthread_mutex_t gMutexGizLog; //加锁防止多线程同时修改GizLog造成异常
static char gTimeStr[32] = { 0 };  //时间格式化输出字符串

static void mutexLock(void)
{
    pthread_mutex_lock(&gMutexGizLog);
}

static void mutexUnlock(void)
{
    pthread_mutex_unlock(&gMutexGizLog);
}

static int setSockTime(int fd, int readSec, int writeSec)
{
    int iRet = 0;
    struct timeval sendTimeout;
    struct timeval recvTimeout;
    
    if (fd <= 0) return -1;
    
    sendTimeout.tv_sec = writeSec < 0 ? 0 : writeSec;
    sendTimeout.tv_usec = 0;
    recvTimeout.tv_sec = readSec < 0 ? 0 : readSec;
    recvTimeout.tv_usec = 0;
    
    if (setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, (const char *)&sendTimeout, sizeof(sendTimeout))) {
        GIZ_LOG_ERROR("setsockopt<SO_SNDTIMEO> errno %d: %s", errno, strerror(errno));
        iRet = -2;
    } else {
        if (setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, (const char *)&recvTimeout, sizeof(recvTimeout))) {
            GIZ_LOG_ERROR("setsockopt<SO_RCVTIMEO> errno %d: %s", errno, strerror(errno));
            iRet = -3;
        }
    }
    
    return iRet;
}

static double getDiffTime(struct timeval start, struct timeval end)
{
    double diffTime = 0;
    
    diffTime = end.tv_sec - start.tv_sec + (double)(end.tv_usec - start.tv_usec) / 1000000;
    
    return diffTime;
}

static void getIPByDomain(const char *domain, char ip[LOG_IP_BUF_LENGTH])
{
    int error = 0;
    struct timeval end;
    struct timeval start;
    struct addrinfo hints;
    struct addrinfo *result = NULL;
    struct addrinfo *pAddrInfo = NULL;
    
    if (!domain || !domain[0] || !ip) {
        GIZ_LOG_ERROR("Invalid parameter, domain %s, ip %s", domain, ip);
        return;
    }
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    
    gettimeofday(&start, NULL);
    error = getaddrinfo(domain, 0, &hints, &result);
    if (error) {
        GIZ_LOG_ERROR("getaddrinfo failed, error %d: %s", error, gai_strerror(error));
    } else {
        pAddrInfo = result;
        while (pAddrInfo) {
            if (AF_INET == pAddrInfo->ai_family) {
                inet_ntop(AF_INET, &((struct sockaddr_in *)pAddrInfo->ai_addr)->sin_addr, ip, LOG_IP_BUF_LENGTH);
                break;
            }
            
            pAddrInfo = pAddrInfo->ai_next;
        }
    }
    gettimeofday(&end, NULL);
    GIZ_LOG_DEBUG("get IP %s from damain %s elapsed %.6fs", ip, domain, getDiffTime(start, end));
    
    if (result) freeaddrinfo(result);
}

static int createThread(void *(*pFunc)(void *), void *shareBuf)
{
    int iRet = 0;
    
    pthread_t threadID;
    if (pthread_create(&threadID, NULL, pFunc, shareBuf)) {
        iRet = -1;
    }
    
    return iRet;
}

void GizPrintBiz(const char *businessCode, const char *result, const char *format, ...)
{
    size_t index = 0;
    char *pEnd = NULL;
    char *pNewLine = NULL;
    char buf[LOG_MAX_LEN + 1] = { 0 }; //__android_log_print最多只能输出LOG_MAX_LEN(=1024)字节的日志
    char tmpBuf[LOG_MAX_LEN + 1] = { 0 };
    
    snprintf(buf, sizeof(buf), "[APPBIZ][%s][%s][%s]", GizTimeStr(), businessCode, result);
    index = strlen(buf);
    
    //日志格式化
    va_list args;
    va_start(args, format);
    vsnprintf(buf + index, LOG_MAX_LEN - index, format, args);
    va_end(args);
    
    if (buf[LOG_MAX_LEN - 2]) buf[LOG_MAX_LEN - 2] = ']'; //缓存区占满情况下追加结束符
    
    //遇到换行符的情况下将换行符后的内容当做详细日志单独打印(不用[]包)
    strcpy(tmpBuf, buf);
    pNewLine = strchr(buf, '\n');
    if (pNewLine) {
        pEnd = strchr(pNewLine, ']');
        pNewLine[0] = ']';
        pNewLine[1] = '\n';
        memcpy(pNewLine + 2, tmpBuf + (pNewLine - buf) + 1, pEnd - pNewLine - 1);
    }
    
    mutexLock();
    
    //屏幕输出
    if (gGizLog.printLevel >= 1) {
#ifdef __ANDROID__
        __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "%s", buf);
#else
#ifdef TARGET_OS_IPHONE
        NSLog(@"%@", [[NSString alloc] initWithUTF8String:buf]);
#else
        fprintf(stdout, "%s\n", buf);
#endif
#endif
    }
    
    mutexUnlock();
}

void GizPrintError(const char *format, ...)
{
    char *pEnd = NULL;
    char *pNewLine = NULL;
    char buf[LOG_MAX_LEN + 1] = { 0 }; //__android_log_print最多只能输出LOG_MAX_LEN(=1024)字节的日志
    char tmpBuf[LOG_MAX_LEN + 1] = { 0 };
    
    //日志格式化
    va_list args;
    va_start(args, format);
    vsnprintf(buf, LOG_MAX_LEN, format, args);
    va_end(args);
    
    if (buf[LOG_MAX_LEN - 2]) buf[LOG_MAX_LEN - 2] = ']'; //缓存区占满情况下追加结束符
    
    //遇到换行符的情况下将换行符后的内容当做详细日志单独打印(不用[]包)
    strcpy(tmpBuf, buf);
    pNewLine = strchr(buf, '\n');
    if (pNewLine) {
        pEnd = strchr(pNewLine, ']');
        pNewLine[0] = ']';
        pNewLine[1] = '\n';
        memcpy(pNewLine + 2, tmpBuf + (pNewLine - buf) + 1, pEnd - pNewLine - 1);
    }
    
    mutexLock();
    
    //屏幕输出
    if (gGizLog.printLevel >= 1) {
#ifdef __ANDROID__
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "%s", buf);
#else
#ifdef TARGET_OS_IPHONE
        NSLog(@"%@", [[NSString alloc] initWithUTF8String:buf]);
#else
        fprintf(stderr, "%s\n", buf);
#endif
#endif
    }
    
    mutexUnlock();
}

void GizPrintDebug(const char *format, ...)
{
    char *pEnd = NULL;
    char *pNewLine = NULL;
    char buf[LOG_MAX_LEN + 1] = { 0 }; //__android_log_print最多只能输出LOG_MAX_LEN(=1024)字节的日志
    char tmpBuf[LOG_MAX_LEN + 1] = { 0 };
    
    //日志格式化
    va_list args;
    va_start(args, format);
    vsnprintf(buf, LOG_MAX_LEN, format, args);
    va_end(args);
    
    if (buf[LOG_MAX_LEN - 2]) buf[LOG_MAX_LEN - 2] = ']'; //缓存区占满情况下追加结束符
    
    //遇到换行符的情况下将换行符后的内容当做详细日志单独打印(不用[]包)
    strcpy(tmpBuf, buf);
    pNewLine = strchr(buf, '\n');
    if (pNewLine) {
        pEnd = strchr(pNewLine, ']');
        pNewLine[0] = ']';
        pNewLine[1] = '\n';
        memcpy(pNewLine + 2, tmpBuf + (pNewLine - buf) + 1, pEnd - pNewLine - 1);
    }
    
    mutexLock();
    
    //屏幕输出
    if (gGizLog.printLevel >= 2) {
#ifdef __ANDROID__
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "%s", buf);
#else
#ifdef TARGET_OS_IPHONE
        NSLog(@"%@", [[NSString alloc] initWithUTF8String:buf]);
#else
        fprintf(stdout, "%s\n", buf);
#endif
#endif
    }
    
    mutexUnlock();
}

char *GizTimeStr(void)
{
    time_t tvSec = 0;
    struct timeval now;
    struct tm *ptm = NULL;
    char buf[32] = { 0 };
    
    gettimeofday(&now, NULL);
    tvSec = now.tv_sec;
    ptm = localtime(&tvSec);
    strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", ptm);
    snprintf(gTimeStr, sizeof(gTimeStr), "%s.%03d", buf, (int )(now.tv_usec / 1000));
    
    return gTimeStr;
}

#ifdef __cplusplus
}
#endif
