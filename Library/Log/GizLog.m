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

/*
 * 32 个字节的 ICMP 包，包含包头
 */
typedef struct _ICMPPHead_t {
    unsigned char type;
    unsigned char code;
    unsigned short crc;
    unsigned short id;
    unsigned short seq;
    unsigned long timestamp;
} ICMPPHead_t;

static GizLog_t gGizLog = { 3 };   //默认打印error+debug+data+busi
static char gInitedGizLogMutex = 0; //是否初始化过日志锁
static pthread_mutex_t gMutexGizLog; //加锁防止多线程同时修改GizLog造成异常
static char gTimeStr[32] = { 0 };  //时间格式化输出字符串
static char gSysInfoLogBuf[LOG_MAX_LEN] = { 0 }; //缓存系统信息，每创建一个新文件时存入文件首行供排查问题用
static const char *gGizLogVersion = "1.0.0.16011500"; //GizWits日志版本号

static void mutexLock(void)
{
    pthread_mutex_lock(&gMutexGizLog);
}

static void mutexUnlock(void)
{
    pthread_mutex_unlock(&gMutexGizLog);
}

static int writen(int fd, const void *buf, size_t n)
{
    int nwritten;
    size_t nleft;
    const char *ptr;
    
    ptr = (const char *) buf;
    nleft = n;
    while (nleft > 0) {
        if ((nwritten = (int)send(fd, ptr, nleft, 0)) <= 0) {
            if (nwritten < 0 && errno == EINTR)
                nwritten = 0;
            else
                return (-1);
        }
        nleft -= nwritten;
        ptr += nwritten;
    }
    
    return (int)n;
}

static int readn(int fd, void *buf, size_t n)
{
    char *ptr;
    int nread;
    size_t nleft;
    
    ptr = (char *) buf;
    nleft = n;
    while (nleft > 0) {
        if ((nread = (int)recv(fd, ptr, nleft, 0)) < 0) {
            if (EINTR == errno)
                nread = 0;
            else
                
                return -1;
        } else if (nread == 0) {
            break;
        }
        
        nleft -= nread;
        ptr += nread;
    }
    
    return (int)(n - nleft);
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

static int newICMPSocket(void)
{
    int fd = 0;
    int iRet = 0;
    struct timeval timeout = { 2, 500000 }; //2.5s 超时
    
    fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
    if(fd <= 0) {
        GIZ_LOG_ERROR("socket failed errno %d: %s", errno, strerror(errno));
        iRet = -1;
    } else {
        if (setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, (const char *)&timeout, sizeof(timeout))) {
            GIZ_LOG_ERROR("setsockopt<SO_SNDTIMEO> errno %d: %s", errno, strerror(errno));
            iRet = -2;
        } else {
            if (setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, (const char *)&timeout, sizeof(timeout))) {
                GIZ_LOG_ERROR("setsockopt<SO_RCVTIMEO> errno %d: %s", errno, strerror(errno));
                iRet = -3;
            }
        }
    }
    
    return fd > 0 ? fd : iRet;
}

static inline unsigned short getICMPChecksum(const ICMPPHead_t *addr, int len)
{
    int sum = 0;
    int nleft = len;
    unsigned short answer = 0;
    unsigned short *w = (unsigned short *)addr;
    
    while(nleft > 1) {
        sum += *w++;
        nleft -= 2;
    }
    
    if( 1 == nleft) {
        *(unsigned char *)(&answer) = *(unsigned char *)w;
        sum += answer;
    }
    
    sum = (sum >> 16) + (sum & 0xffff);
    sum += (sum >> 16);
    answer = ~sum;
    
    return answer;
}

static inline void getCurTimestamp(unsigned long *pts)
{
    struct timeval ts = { 0 };
    
    gettimeofday(&ts, NULL);
    
    *pts = ts.tv_sec * 1000000 + ts.tv_usec;
}

static int sendICMPReq(int fd, const struct sockaddr *addr, unsigned short id,
                       unsigned short seq, int len, unsigned long *pts)
{
    char *packetICMP = NULL;
    ICMPPHead_t *pPacket = NULL;
    int iRet = 0;
    int packetLen = sizeof(ICMPPHead_t) + len;
    
    packetICMP = (char *)calloc(packetLen, 1);
    if (!packetICMP) {
        GIZ_LOG_ERROR("calloc %d bytes spaces failed, errno %d: %s", packetLen, strerror(errno));
        return -1;
    }
    
    getCurTimestamp(pts);
    pPacket = (ICMPPHead_t *)packetICMP;
    pPacket->type = 8;
    pPacket->id = id;
    pPacket->seq = seq;
    pPacket->timestamp = *pts;
    pPacket->crc = getICMPChecksum(pPacket, sizeof(ICMPPHead_t));
    
    iRet= (int)sendto(fd, packetICMP, packetLen, 0, addr, sizeof(struct sockaddr));
    free(packetICMP);
    
    if(iRet != packetLen) {
        if(ETIMEDOUT == errno || EAGAIN == errno) {
            GIZ_LOG_ERROR("packet send timeout");
            iRet = -2;
        } else {
            GIZ_LOG_ERROR("packet send failed, expect %d, return %d, errno %d: %s",
                          packetLen, iRet, errno, strerror(errno));
            iRet = -3;
        }
    }
    
    return iRet;
}

static int recvICMPResp(int fd, const struct sockaddr *pAddrOut, unsigned short id,
                        unsigned short seq, int len, unsigned long *pts)
{
    char *ipPacket = NULL;
    ICMPPHead_t packet = { 0 };
    struct sockaddr_in addrIn = { 0 };
    int iRet = 0;
    int addrLen = sizeof(struct sockaddr);
    int packetLen = sizeof(struct ip) + sizeof(ICMPPHead_t) + len;
    
    ipPacket = (char *)calloc(packetLen, 1);
    if(!ipPacket) {
        GIZ_LOG_ERROR("calloc %d bytes spaces failed, errno %d: %s", errno, strerror(errno));
        return -1;
    }
    
    iRet = (int)recvfrom(fd, ipPacket, packetLen, 0, (struct sockaddr *)&addrIn, (socklen_t *)&addrLen);
    if (iRet != packetLen) {
        if(ETIMEDOUT == errno || EAGAIN == errno) {
            GIZ_LOG_ERROR("packet recv timeout, errno %d: %s", errno, strerror(errno));
            iRet = -2;
        } else {
            GIZ_LOG_ERROR("packet send failed, expect %d, return %d, errno %d: %s",
                          packetLen, iRet, errno, strerror(errno));
            iRet = -3;
        }
    } else {
        packet = *(ICMPPHead_t *)(ipPacket + sizeof(struct ip));
        
        //IP与type判断
        if(memcmp(&addrIn.sin_addr, &((struct sockaddr_in *)pAddrOut)->sin_addr, sizeof(struct in_addr))) {
            GIZ_LOG_ERROR("addr is not equal");
            iRet = -4;
        } else if (packet.type != 0) {
            GIZ_LOG_ERROR("type invalid");
            iRet = -5;
        } else if (getICMPChecksum(&packet, sizeof(ICMPPHead_t)) != 0) {
            GIZ_LOG_ERROR("checksum failed");
            iRet = -6;
        } else if (packet.id != id) {
            GIZ_LOG_ERROR("id not match");
            iRet = -7;
        } else if (packet.seq != seq) {
            GIZ_LOG_DEBUG("seq not match, continue...");
        }
    }
    
    free(ipPacket);
    getCurTimestamp(pts); //记录结束时间(微秒数)
    
    return iRet;
}

static void pingBaidu(double *elapsed)
{
    unsigned short id = 0;
    int i = 0;
    int iRet = 0;
    int len = 32; //请求的包长度
    int count = 4; //次数
    int pingCount = 0; //已请求的次数
    int fd = newICMPSocket(); //建立ICMP套接字
    unsigned long tsSum = 0; //总延迟
    unsigned long tsEnd = 0; //结束时间
    unsigned long tsStart = 0; //开始时间
    unsigned long tsElapsed = 0; //单次延时
    struct sockaddr_in addr = { 0 };
    char ip[LOG_IP_BUF_LENGTH + 1] = { 0 };
    const char *errorStr = NULL;
    
    if(fd < 0) return;
    
    //DNS解析
    getIPByDomain("www.baidu.com", ip);
    if (!ip[0]) {
        close(fd);
        GIZ_LOG_ERROR("getIPByDomain failed");
        return;
    }
    
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr(ip);
    
    id = (unsigned short)pthread_self();
    
    //业务日志
    GIZ_LOG_BIZ("ping_baidu_start", "", "ping baidu: ip = %s", ip);
    GIZ_LOG_DEBUG("Try to ping www.baidu.com, ip %s, id %d", ip, id);
    
    for (i = 0; i < count; i++) {
        iRet = (int)sendICMPReq(fd, (struct sockaddr *)&addr, id, i, len, &tsStart);
        if(-5 == iRet) continue;
        if(iRet < 0) break;
        
        iRet = (int)recvICMPResp(fd, (struct sockaddr *)&addr, id, i, len, &tsEnd);
        if(-4 == iRet) continue;
        if(iRet < 0) break;
        
        //计算延迟
        tsElapsed = tsEnd - tsStart;
        GIZ_LOG_DEBUG("ping %s, id: %i, seq: %i, elapsed: %.3lfms",
                      ip, id, i, tsElapsed / 1000.0);
        tsSum += tsElapsed;
        
        //成功接收ping的次数
        ++pingCount;
    }
    
    //求平均值，清理
    *elapsed = tsSum / ((double)pingCount) / 1000.0;
    close(fd);
    
    //发送或者接收失败，则不改相应的错误码
    if(iRet >= 0) {
        iRet = 0;
        errorStr = "GIZ_LOG_SUCCESS";
    } else if (-1 == iRet) {
        errorStr = "GIZ_LOG_MEMORY_MALLOC_FAILED";
    } else if (-2 == iRet) {
        errorStr = "GIZ_LOG_SEND_OR_RECV_TIMEOUT";
    } else {
        errorStr = "GIZ_LOG_PING_ERROR";
    }
    
    //业务日志
    GIZ_LOG_BIZ("ping_baidu_result", errorStr, "ping baidu time elapsed: %.3lf ms", *elapsed);
    GIZ_LOG_ERROR("ping %s, id %d, iRet %i, average %.3lfms", ip, id, iRet, *elapsed);
}

static void *pingBaiduSync(void *argv)
{
    double timeout = 0.0;
    
    signal(SIGPIPE, SIG_IGN);
    pthread_detach(pthread_self());
    
    pingBaidu(&timeout);
    
    return NULL;
}

static void pingBaiduAsync(void)
{
    //启动线程
    if (createThread(pingBaiduSync, NULL)) {
        GIZ_LOG_ERROR("createThread pingBaiduSync failed errno %d: %s",
                      errno, strerror(errno));
    }
}

static int connectByIPPort(const char *ip, int port, int timeoutSec)
{
    int fd = 0;
    int yes = 1;
    struct timeval end;
    struct timeval start;
    struct sockaddr_in addr;
    
    if (!ip || !ip[0] || port <= 0) {
        GIZ_LOG_ERROR("Invalid parameter, ip %s, port %d", ip, port);
        return -1;
    }
    
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr(ip);
    addr.sin_port = htons(port);
    
    fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd <= 0) {
        GIZ_LOG_ERROR("new a socket failed errno %d: %s", errno, strerror(errno));
        return -1;
    }
    
    //允许端口复用
    if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (const char *)&yes, sizeof(int))) {
        GIZ_LOG_ERROR("setsockopt<SO_REUSEADDR> errno %d: %s", errno, strerror(errno));
        GIZ_CLOSE(fd);
        return -2;
    }
    
    if (setSockTime(fd, timeoutSec, timeoutSec)) {
        GIZ_LOG_ERROR("setSockTime failed errno %d: %s", errno, strerror(errno));
        GIZ_CLOSE(fd);
        return -3;
    }
    
    gettimeofday(&start, NULL);
    if (connect(fd, (struct sockaddr*) &addr, sizeof(struct sockaddr_in))) {
        gettimeofday(&end, NULL);
        GIZ_LOG_ERROR("connect to %s, port %d failed errno %d: %s, elapsed %.6fs",
                      ip, port, errno, strerror(errno), getDiffTime(start, end));
        GIZ_CLOSE(fd);
        
        if (ETIMEDOUT == errno) {
            pingBaiduAsync();
        }
        
        return -4;
    } else {
        gettimeofday(&end, NULL);
        GIZ_LOG_DEBUG("connect to %s, port %d success, fd %d, elapsed %.6fs",
                      ip, port, fd, getDiffTime(start, end));
    }
    
    return fd;
}

static char *httpPost(const char *domain, int port, int timeoutSec, const char *dest, const char *headCustom,
                      const char *content, int *answerLen, int *responseCode)
{
    int fd = 0;
    int iRet = 0;
    int iLen = 0;
    int index = 0;
    int headLen = 0;
    int contentLen = 0;
    int remainLength = 0;
    char isTransferEncoding = 0;
    char *pEnd = NULL;
    char *answer = NULL;
    char *pStart = NULL;
    char ip[LOG_IP_BUF_LENGTH + 1] = { 0 };
    char buf[LOG_SEND_BUF_LENGTH + 1] = { 0 };
    
    if (!domain || !domain[0] || !dest || !dest[0] || port < 0|| !answerLen) {
        GIZ_LOG_ERROR("Invalid parameter, domain %s, dest %s, port %d, answerLen %p",
                      domain, dest, port, answerLen);
        return NULL;
    }
    
    //初始化,取Content-Length
    *responseCode = 0;
    contentLen = (int)(content ? strlen(content) : 0);
    
    //组HTTP请求行+信息报头数据包
    snprintf(buf, sizeof(buf), "POST %s HTTP/1.1\r\n"
             "Host: %s\r\n"
             "Content-Length: %d\r\n"
             "%s"
             "Connection: keep-alive\r\n\r\n",
             dest, domain, contentLen, headCustom ? headCustom : "");
    headLen = (int)strlen(buf);
    
    //通过域名获取对应的IP
    getIPByDomain(domain, ip);
    if (!ip[0]) {
        GIZ_LOG_ERROR("getIPByDomain failed, domain:%s", domain);
    } else {
        //通过IP，端口创建限时的TCP套接字
        fd = connectByIPPort(ip, port, timeoutSec);
        if (fd > 0) {
            //发送请求数据
            iRet = writen(fd, buf, headLen);
            if (iRet != headLen) {
                GIZ_LOG_ERROR("writen to fd %d failed, expect %d, return %d, errno %d: %s",
                              fd, headLen, iRet, errno, strerror(errno));
            } else {
                iRet = writen(fd, content ? content : "", contentLen);
                if (iRet != contentLen) {
                    GIZ_LOG_ERROR("writen to fd %d failed, expect %d, return %d, errno %d: %s",
                                  fd, contentLen, iRet, errno, strerror(errno));
                } else {
                    memset(buf, 0, sizeof(buf));
                    headLen = 0;
                    
                    //读取完整的HTTP返回包数据
                    while (!strstr(buf, "\r\n\r\n")) {
                        iRet = (int)recv(fd, buf + headLen, sizeof(buf) - headLen - 1, 0);
                        headLen += iRet;
                        if (iRet <= 0 || headLen >= sizeof(buf) - 1) {
                            break;
                        }
                    }
                    
                    //解析收到的数据包
                    if (iRet > 0) {
                        //取到HTTP回复的状态码
                        pStart = strstr(buf, " ");
                        pEnd = strstr(++pStart, " ");
                        if (pEnd) {
                            pEnd[0] = '\0';
                        }
                        *responseCode = atoi(pStart);
                        if  (pEnd) {
                            pEnd[0] = ' ';
                        }
                        
                        //Content-Length方式解析HTTP包体长度
                        pStart = strstr(buf, "Content-Length:");
                        if (pStart) {
                            pEnd = strstr(pStart, "\r\n");
                            if (pEnd) {
                                pEnd[0] = '\0';
                                iLen = atoi(pStart + strlen("Content-Length:"));
                                pEnd[0] = '\r';
                                pEnd = strstr(pEnd, "\r\n\r\n");
                                if (pEnd) {
                                    pEnd += strlen("\r\n\r\n");
                                }
                            }
                        }
                        
                        //Transfer-Encoding方式解析HTTP包体长度（只考虑chunked size指定整个包体长度的情况，即不考虑分包）
                        pStart = strstr(buf, "Transfer-Encoding:");
                        if (pStart) {
                            isTransferEncoding = 1;
                            pEnd = strstr(pStart, "\r\n\r\n");
                            if (pEnd) {
                                pStart = pEnd + strlen("\r\n\r\n");
                                pEnd = strstr(pStart, "\r\n");
                                if (pEnd) {
                                    pEnd[0] = '\0';
                                    //chuncked size为16进制字符串表示
                                    sscanf(pStart, "%x", &iLen);
                                    pEnd += strlen("\r\n");
                                }
                            }
                        }
                    } else {
                        GIZ_LOG_ERROR("read failed, return %d, errno %d: %s", iRet, errno, strerror(errno));
                    }
                    
                    //解析正文数据
                    if (iLen > 0 && pEnd) {
                        GIZ_LOG_DEBUG("Http Content-Length or first ChunckedSize: %d", iLen);
                        *answerLen = iLen;
                        remainLength = (int)(iLen - (headLen - (pEnd - buf)));
                        answer = (char *) malloc(iLen + 1);
                        if (answer) {
                            memset(answer, 0, iLen + 1);
                            if (remainLength > 0) {
                                memcpy(answer, pEnd, headLen - (pEnd - buf));
                                iRet = readn(fd, answer + headLen - (pEnd - buf), remainLength);
                                if (iRet != remainLength) {
                                    free(answer);
                                    answer = NULL;
                                    GIZ_LOG_ERROR("readn return %d, expect %d, errno %d: %s",
                                                  iRet, remainLength, errno, strerror(errno));
                                } else {
                                    if (isTransferEncoding) {
                                        //循环读取Transfer-Encoding方式传输的后续分包
                                        memset(buf, 0, sizeof(buf));
                                        while (index < sizeof(buf) && 1 == readn(fd, buf + index, 1)) {
                                            ++index;
                                            
                                            if ((pEnd = strstr(buf + 1, "\r\n"))) {
                                                pEnd[0] = '\0';
                                                //偏移"\r\n"到下一包的长度部分
                                                sscanf(buf + strlen("\r\n"), "%x", &remainLength);
                                                if (remainLength <= 0) {
                                                    break;
                                                }
                                                
                                                *answerLen += remainLength;
                                                answer = (char *)realloc(answer, iLen + remainLength + 1);
                                                if (answer) {
                                                    answer[iLen + remainLength] = '\0';
                                                    iRet = readn(fd, answer + iLen, remainLength);
                                                    if (iRet != remainLength) {
                                                        GIZ_LOG_ERROR("readn return %d, expect %d, errno %d: %s",
                                                                      iRet, remainLength, errno, strerror(errno));
                                                        free(answer);
                                                        answer = NULL;
                                                        break;
                                                    } else {
                                                        iLen += remainLength;
                                                    }
                                                } else {
                                                    GIZ_LOG_ERROR("realloc a size of %d space failed, errno %d: %s",
                                                                  iLen + remainLength + 1, errno, strerror(errno));
                                                    break;
                                                }
                                                
                                                index = 0;
                                                memset(buf, 0, sizeof(buf));
                                            }
                                        }
                                    }
                                }
                            } else {
                                //remainLength小于或等于0意味着一次性读完了所有HTTP包体
                                //iRet - (pEnd - buf)会大于或等于answser空间长度，直接拷贝iLen长度才行
                                memcpy(answer, pEnd, iLen);
                            }
                        } else {
                            GIZ_LOG_ERROR("malloc a size of %d space failed, errno %d: %s",
                                          iLen + 1, errno, strerror(errno));
                        }
                    }
                }
            }
            
            GIZ_CLOSE(fd);
        } else {
            GIZ_LOG_ERROR("connectByIPPort %s:%d failed, return %d", ip, port, fd);
        }
    }
    
    if (!answer && iLen != 0) {
        *answerLen = 0;
    }
    
    return answer;
}

/**
 * @brief 日志初始化.
 * @param[in] sysInfoJson- 系统信息(Json字符串，例:{"phone_id":"AE27466D-9C8F-4184-A6A3-2A0CDEDAA4FD","os":"iOS","os_ver":"9.2","app_version":"1.5.1","phone_model":"iPhone 6 (A1549/A1586)"}).
 * @param[in] logDir- 存储日志目录的路径(推荐采用程序私有目录,例:/var/mobile/Containers/Data/Application/1D7A5CD8-70D2-4B46-A76A-8B9BE5CBC88C/Documents").
 * @param[in] printLevel- 日志打印到屏幕的级别(0:不打印屏幕,1:打印error+busi,2:打印error+debug+busi).
 * @return 返回日志初始化结果,0:成功,1:sysInfoJson非法,2:logDir指定错误(目录为空、不存在或无法创建文件等),3:printLevel非法.
 *
 */
int GizLogInit(const char *sysInfoJson, const char *logDir, int printLevel)
{
    int iRet = 0;
    char curPath[LOG_MAX_PATH_LEN] = { 0 };
    char addFolderLogDir[LOG_MAX_PATH_LEN] = { 0 };
    
    if (!sysInfoJson || !sysInfoJson[0]) iRet = 1;
    if (!logDir || !logDir[0]) iRet = 2;
    if (printLevel < 0 || printLevel > 3) iRet = 3;
    
    //创建日志目录
    if (0 == iRet) {
        if (!gInitedGizLogMutex) {
            gInitedGizLogMutex = 1;
            pthread_mutex_init(&gMutexGizLog, NULL);
        }
        if (logDir[strlen(logDir) - 1] != '/') {
            snprintf(addFolderLogDir, sizeof(addFolderLogDir), "%s/GizLogFolder/", logDir);
        } else {
            snprintf(addFolderLogDir, sizeof(addFolderLogDir), "%sGizLogFolder/", logDir);
        }
        if (access(addFolderLogDir, 0)) mkdir(addFolderLogDir, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
        if (access(addFolderLogDir, 0)) iRet = 2;
    }
    
    if (0 == iRet) {
        mutexLock();
        
        if (gGizLog.fileBiz) {
            fclose(gGizLog.fileBiz);  //重新设置日志参数统一先关闭已打开的业务日志文件
            gGizLog.fileBiz = NULL;
        }
        
        if (gGizLog.fileSys) {
            fclose(gGizLog.fileSys);  //重新设置日志参数统一先关闭已打开的系统日志文件
            gGizLog.fileSys = NULL;
        }
        
        if (gGizLog.sysInfoJson) {
            free(gGizLog.sysInfoJson);
            gGizLog.sysInfoJson = NULL;
        }
        
        snprintf(curPath, sizeof(curPath), "%s%s.biz", addFolderLogDir, LOG_FILE_NAME);
        //a：以写的方式打开业务日志文件，如果业务日志文件不存在则创建，如果存在则将新内容追加到文件末端
        gGizLog.fileBiz = fopen(curPath, "a");
        if (NULL == gGizLog.fileBiz) {
            //创建业务日志文件失败尝试使用上次的路径
            if (gGizLog.dir[0]) {
                snprintf(curPath, sizeof(curPath), "%s%s.biz", gGizLog.dir, LOG_FILE_NAME);
                gGizLog.fileBiz = fopen(curPath, "a");
                if (gGizLog.fileBiz) {
                    //a：以写的方式打开系统日志文件，如果系统日志文件不存在则创建，如果存在则将新内容追加到文件末端
                    snprintf(curPath, sizeof(curPath), "%s%s.sys", addFolderLogDir, LOG_FILE_NAME);
                    gGizLog.fileSys = fopen(curPath, "a");
                    gGizLog.latestCreatSysLogTimestamp = time(NULL);
                    
                    gGizLog.sysInfoJson = (char *)malloc(strlen(sysInfoJson) + 1);
                    if (gGizLog.sysInfoJson) {
                        strcpy(gGizLog.sysInfoJson, sysInfoJson);
                        gGizLog.printLevel = printLevel;
                    } else {
                        iRet = 1;
                    }
                }
            }
            
            iRet = 2;
        } else {
            //a：以写的方式打开系统日志文件，如果系统日志文件不存在则创建，如果存在则将新内容追加到文件末端
            snprintf(curPath, sizeof(curPath), "%s%s.sys", addFolderLogDir, LOG_FILE_NAME);
            gGizLog.fileSys = fopen(curPath, "a");
            gGizLog.latestCreatSysLogTimestamp = time(NULL);
            
            gGizLog.sysInfoJson = (char *)malloc(strlen(sysInfoJson) + 1);
            if (gGizLog.sysInfoJson) {
                strcpy(gGizLog.sysInfoJson, sysInfoJson);
            } else {
                iRet = 1;
            }
            gGizLog.printLevel = printLevel;
            strncpy(gGizLog.dir, addFolderLogDir, sizeof(gGizLog.dir) - 1);
        }
        
        mutexUnlock();
        
        //记录系统信息
        if (0 == iRet) {
            snprintf(gSysInfoLogBuf, sizeof(gSysInfoLogBuf), "[SYS][DEBUG][%s][%s:%d %s][GizLog Version:%s, sysInfoJson:%s]",
                     GizTimeStr(), __FILENAME__, __LINE__, __FUNCTION__, gGizLogVersion, gGizLog.sysInfoJson);
            GIZ_LOG_DEBUG("GizLog Version:%s, sysInfoJson:%s", gGizLogVersion, gGizLog.sysInfoJson);
        }
    }
    
    return iRet;
}

static void listenFileForUploadByPath(const char *path)
{
    FILE *file = NULL;
    int answerLen = 0;
    int httpBodyLen = 0;
    int responseCode = 0;
    char *answer = NULL;
    char *httpBody = NULL;
    char *fileContent = NULL;
    struct stat fileStat = { 0 };
    char httpHeadCustom[LOG_SEND_BUF_LENGTH] = { 0 };
    
    if (!stat(path, &fileStat)) {
        file = fopen(path, "r");
        if (file) {
            fileContent = (char *)malloc((size_t)fileStat.st_size + 1);
            if (fileContent) {
                fread(fileContent, 1, (size_t)fileStat.st_size, file);
                fileContent[fileStat.st_size] = 0;
            } else {
                GIZ_LOG_ERROR("malloc %d bytes space filed, errno %d: %s",
                              fileStat.st_size + 1, errno, strerror(errno));
            }
            
            fclose(file);
        }
    }
    
    if (fileContent) {
        snprintf(httpHeadCustom, sizeof(httpHeadCustom),
                 "X-Gizwits-Application-Id: %s\r\n"
                 "X-Gizwits-User-token: %s\r\n"
                 "Content-Type: multipart/form-data; boundary=%s\r\n",
                 gGizLog.appID, gGizLog.token, LOG_HTTP_BOUNDARY);
        httpBodyLen = (int)strlen(fileContent) + 1024; //填充boundary部分新增1K足够
        httpBody = (char *)malloc(httpBodyLen);
        if (httpBody) {
            snprintf(httpBody, httpBodyLen, "--%s\r\n"
                     "Content-Disposition: form-data; name=\"logfile\"; filename=\"GizLogFile.old\"\r\n"
                     "Content-Type: application/octet-stream\r\n\r\n"
                     "%s"
                     "\r\n"
                     "--%s--\r\n",
                     LOG_HTTP_BOUNDARY, fileContent, LOG_HTTP_BOUNDARY);
            
            answer = httpPost(gGizLog.domain, gGizLog.port, LOG_HTTP_TIMEOUT,
                              "/app/logging", httpHeadCustom, httpBody, &answerLen, &responseCode);
            //打印结果
            GIZ_LOG_DEBUG("Upload Log HTTP responseCode:%d, body:%s", responseCode, answer);
            
            if (LOG_HTTP_STATUS_OK == responseCode) {
                remove(path);
            }
            if (answer) free(answer);
            free(httpBody);
        } else {
            GIZ_LOG_ERROR("malloc %d bytes space filed, errno %d: %s",
                          httpBodyLen, errno, strerror(errno));
        }
        
        free(fileContent);
    }
}

static void *threadProvision(void *argv)
{
    int answerLen = 0;
    int responseCode = 0;
    char *pEnd = NULL;
    char *pStart = NULL;
    char *answer = NULL;
    time_t createThreadTimestamp = time(NULL);
    char oldPath[LOG_MAX_PATH_LEN] = { 0 };
    char httpHeadCustom[LOG_SEND_BUF_LENGTH] = { 0 };
    
    signal(SIGPIPE, SIG_IGN);
    pthread_detach(pthread_self());
    
    gGizLog.latestCreatThreadTimestamp = createThreadTimestamp;
    
    //Provision
    snprintf(httpHeadCustom, sizeof(httpHeadCustom),
             "Content-Type: application/json\r\n"
             "X-Gizwits-Application-Id: %s\r\n"
             "X-Gizwits-User-token: %s\r\n", gGizLog.appID, gGizLog.token);
    answer = httpPost(gGizLog.domain, gGizLog.port, LOG_HTTP_TIMEOUT,
                      "/app/provision", httpHeadCustom, gGizLog.sysInfoJson, &answerLen, &responseCode);
    GIZ_LOG_DEBUG("Provision sysInfoJson: %s", gGizLog.sysInfoJson);
    
    if (answer && LOG_HTTP_STATUS_OK == responseCode) {
        GIZ_LOG_BIZ("provision_resp", "GIZ_LOG_SUCCESS", "provision %s response %s",
                    gGizLog.sysInfoJson, answer);
        
        //解析saveSystemLog
        pStart = strstr(answer, "\"sys_log\":");
        if (pStart) {
            pEnd = strchr(pStart, ',');
            if (!pEnd) pEnd = strchr(pStart, '}');
            if (pEnd) {
                pEnd[0] = '\0';
                gGizLog.uploadSystemLog = atoi(pStart + strlen("\"sys_log\":"));
                pEnd[0] = ',';
            }
        }
        
        //解析saveBusinessLog
        pStart = strstr(answer, "\"biz_log\":");
        if (pStart) {
            pEnd = strchr(pStart, ',');
            if (!pEnd) pEnd = strchr(pStart, '}');
            if (pEnd) {
                pEnd[0] = '\0';
                gGizLog.uploadBusinessLog = atoi(pStart + strlen("\"biz_log\":"));
                pEnd[0] = ',';
            }
        }
    } else {
        GIZ_LOG_BIZ("provision_resp", "GIZ_LOG_HTTP_REQUEST_FAILED", "provision response code %d",
                    responseCode);
    }
    
    //临时绕过provision时打开如下注释
    //gGizLog.uploadSystemLog = 1;
    //gGizLog.uploadBusinessLog = 1;
    
    //打印结果
    GIZ_LOG_DEBUG("Provision HTTP responseCode:%d, body:%s", responseCode, answer);
    
    //释放资源
    if (answer) free(answer);
    
    //需要上传则一直上传日志
    while (1) {
        snprintf(oldPath, sizeof(oldPath), "%s%s.gagent.old", gGizLog.dir, LOG_FILE_NAME);
        listenFileForUploadByPath(oldPath);
        
        if (gGizLog.uploadBusinessLog) {
            snprintf(oldPath, sizeof(oldPath), "%s%s.biz.old", gGizLog.dir, LOG_FILE_NAME);
            listenFileForUploadByPath(oldPath);
        }
        
        if (gGizLog.uploadSystemLog) {
            snprintf(oldPath, sizeof(oldPath), "%s%s.sys.old", gGizLog.dir, LOG_FILE_NAME);
            listenFileForUploadByPath(oldPath);
        }
        
        sleep(1);
        
        if (createThreadTimestamp != gGizLog.latestCreatThreadTimestamp) {
            GIZ_LOG_DEBUG("again calll GizLogProvision, create this thread at %d, create the latest thread at %d",
                          createThreadTimestamp, gGizLog.latestCreatThreadTimestamp);
            break;
        }
    }
    
    return NULL;
}

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
int GizLogProvision(const char *domain, int port, const char *appID, const char *uid, const char *token)
{
    int iRet = 0;
    const char *errStr = "GIZ_LOG_MEMORY_MALLOC_FAILED";
    const char *createThreadErrStr = "GIZ_LOG_THREAD_CREATE_FAILED";
    
    if (!domain || !domain[0] || port <= 0 || !appID || !appID[0] || !uid || !uid[0] || !token || !token[0]) {
        GIZ_LOG_BIZ("provision_req", "GIZ_LOG_PARAM_FORM_INVALID",
                    "provision request failed, domain %s, port %d, appID %s, uid %s, token %s",
                    domain, port, appID, uid, token);
        return iRet;
    }
    
    gGizLog.domain = (char *)malloc(strlen(domain) + 1);
    if (gGizLog.domain) {
        strcpy(gGizLog.domain, domain);
    } else {
        iRet = 1;
    }
    
    gGizLog.appID = (char *)malloc(strlen(appID) + 1);
    if (gGizLog.appID) {
        strcpy(gGizLog.appID, appID);
    } else {
        iRet = 1;
    }
    
    gGizLog.uid = (char *)malloc(strlen(uid) + 1);
    if (gGizLog.uid) {
        strcpy(gGizLog.uid, uid);
    } else {
        iRet = 1;
    }
    
    gGizLog.token = (char *)malloc(strlen(token) + 1);
    if (gGizLog.token) {
        strcpy(gGizLog.token, token);
    } else {
        iRet = 1;
    }
    
    gGizLog.port = port;
    
    if (!iRet) {
        //启动线程
        if (createThread(threadProvision, NULL)) {
            GIZ_LOG_ERROR("createThread threadProvision failed errno %d: %s",
                          errno, strerror(errno));
            errStr = createThreadErrStr;
        }
    }
    
    if (iRet) {
        if (gGizLog.domain) {
            free(gGizLog.domain);
            gGizLog.domain = NULL;
        }
        if (gGizLog.appID) {
            free(gGizLog.appID);
            gGizLog.appID = NULL;
        }
        if (gGizLog.uid) {
            free(gGizLog.uid);
            gGizLog.uid = NULL;
        }
        if (gGizLog.token) {
            free(gGizLog.token);
            gGizLog.token = NULL;
        }
    }
    
    if (iRet) {
        GIZ_LOG_BIZ("provision_req", errStr, "provision request");
    } else {
        GIZ_LOG_BIZ("provision_req", "GIZ_LOG_SUCCESS", "provision request");
    }
    
    return iRet;
}

static void logCheckSys(void)
{
    char curPath[LOG_MAX_PATH_LEN] = { 0 };
    char oldPath[LOG_MAX_PATH_LEN] = { 0 };
    struct stat statBuf;
    
    snprintf(curPath, sizeof(curPath), "%s%s.sys", gGizLog.dir, LOG_FILE_NAME);
    if (!gGizLog.fileSys) {
        gGizLog.latestCreatSysLogTimestamp = time(NULL);
        gGizLog.fileSys = fopen(curPath, "a");  //上次fopen打开失败则再次尝试打开
        if (gGizLog.fileSys) {
            fprintf(gGizLog.fileSys, "%s\n", gSysInfoLogBuf);
            fflush(gGizLog.fileSys);
        }
    }
    stat(curPath, &statBuf);
    //如果检测到当前日志文件大于上限或者已存在的时间超过最大重命名时间，将当前文件重命名为老文件，再新建一个文件存储新日志
    if (statBuf.st_size > LOG_MAX_SYS_FILE_SIZE ||
        (gGizLog.latestCreatSysLogTimestamp && time(NULL) - gGizLog.latestCreatSysLogTimestamp > LOG_MAX_RENAME_SYS_TIME)) {
        //处理系统日志文件
        if (gGizLog.fileSys) fclose(gGizLog.fileSys);
        snprintf(oldPath, sizeof(oldPath), "%s.old", curPath);
        remove(oldPath);  //先删除旧的日志文件
        rename(curPath, oldPath);  //再将当前日志文件重命名为老的日志文件
        gGizLog.fileSys = fopen(curPath, "a");  //新建文件存储新新日志
        if (gGizLog.fileSys) {
            gGizLog.latestCreatSysLogTimestamp = time(NULL);
            fprintf(gGizLog.fileSys, "%s\n", gSysInfoLogBuf);
            fflush(gGizLog.fileSys);
        }
        
        //处理业务日志文件(由于系统日志数量远大于业务日志数量,故业务日志处理时机以系统日志的为准)
        if (gGizLog.fileBiz) fclose(gGizLog.fileBiz);
        snprintf(curPath, sizeof(curPath), "%s%s.biz", gGizLog.dir, LOG_FILE_NAME);
        snprintf(oldPath, sizeof(oldPath), "%s.old", curPath);
        remove(oldPath);  //先删除旧的日志文件
        rename(curPath, oldPath);  //再将当前日志文件重命名为老的日志文件
        gGizLog.fileBiz = fopen(curPath, "a");  //新建文件存储新新日志
        if (gGizLog.fileBiz) {
            gGizLog.latestCreatSysLogTimestamp = time(NULL);
        }
    }
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
    
    //保存文件
    if (gGizLog.fileBiz) {
        fprintf(gGizLog.fileBiz, "%s\n", buf);
        fflush(gGizLog.fileBiz);
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
    
    logCheckSys();  //如果日志大小超出上限则删除原文件并重现创建文件
    //保存文件
    if (gGizLog.fileSys) {
        fprintf(gGizLog.fileSys, "%s\n", buf);
        fflush(gGizLog.fileSys);
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
    
    //保存文件
    logCheckSys(); //如果日志大小超出上限则删除原文件并重现创建文件
    if (gGizLog.fileSys) {
        fprintf(gGizLog.fileSys, "%s\n", buf);
        fflush(gGizLog.fileSys);
    }
    
    mutexUnlock();
}

/**
 * @brief 打印来至上层的业务日志.
 * @param[in] content- 业务日志内容.
 * @see content内容格式为[BIZ][时间][业务码][执行结果][描述]
 * @see 例:[BIZ][2015-11-24 11:20:49.309][usr_login_req][SUCCESS][用户登录请求]
 *
 */
void GizPrintBizFromUp(const char *content)
{
    mutexLock();
    
    //屏幕输出
    if (gGizLog.printLevel >= 1) {
#ifdef __ANDROID__
        __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "%s", content);
#else
#ifdef TARGET_OS_IPHONE
        NSLog(@"%@", [[NSString alloc] initWithUTF8String:content]);
#else
        fprintf(stdout, "%s\n", content);
#endif
#endif
    }
    
    //保存文件
    if (gGizLog.fileBiz) {
        fprintf(gGizLog.fileBiz, "%s\n", content);
        fflush(gGizLog.fileBiz);
    }
    
    mutexUnlock();
}

/**
 * @brief 打印来至上层的错误日志.
 * @param[in] content- 错误日志内容.
 * @see content内容格式为[SYS][ERROR][时间][文件名:行号 函数名][日志体]
 * @see 例:[SYS][ERROR][2015-11-24 11:20:49.309][tool.c:937 connect] [conect 192.168.1.108:12906 failed, connection refused]
 *
 */
void GizPrintErrorFromUp(const char *content)
{
    mutexLock();
    
    //屏幕输出
    if (gGizLog.printLevel >= 1) {
#ifdef __ANDROID__
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "%s", content);
#else
#ifdef TARGET_OS_IPHONE
        NSLog(@"%@", [[NSString alloc] initWithUTF8String:content]);
#else
        fprintf(stderr, "%s\n", content);
#endif
#endif
    }
    
    logCheckSys();  //如果日志大小超出上限则删除原文件并重现创建文件
    //保存文件
    if (gGizLog.fileSys) {
        fprintf(gGizLog.fileSys, "%s\n", content);
        fflush(gGizLog.fileSys);
    }
    
    mutexUnlock();
}

/**
 * @brief 打印来至上层的调试日志.
 * @param[in] content- 调试日志内容.
 * @see content内容格式为[SYS][DEBUG][时间][文件名:行号 函数名][日志体]
 * @see 例:[SYS][DEBUG][2015-11-24 11:20:49.309][tool.c:937 connect] [conect 192.168.1.108:12906 success, fd 127]
 *
 */
void GizPrintDebugFromUp(const char *content)
{
    mutexLock();
    
    //屏幕输出
    if (gGizLog.printLevel >= 2) {
#ifdef __ANDROID__
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "%s", content);
#else
#ifdef TARGET_OS_IPHONE
        NSLog(@"%@", [[NSString alloc] initWithUTF8String:content]);
#else
        fprintf(stdout, "%s\n", content);
#endif
#endif
    }
    
    logCheckSys();  //如果日志大小超出上限则删除原文件并重现创建文件
    //保存文件
    if (gGizLog.fileSys) {
        fprintf(gGizLog.fileSys, "%s\n", content);
        fflush(gGizLog.fileSys);
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

void GizClose(int fd, const char *file, int line, const char *function)
{
    if (fd > 0) {
        close(fd);
        GIZ_LOG_DEBUG("closed fd %d in <%s:%d %s> success", fd, file, line, function);
    }
}

#ifdef __cplusplus
}
#endif
