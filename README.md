gokit-ios
=========

Gizwits GoKit iOS Demo App

GoKit iOS App, 一款使用XPGWifiSDK的示例APP

    GoKit项目，是一个使用XPGWifiSDK的开源代码示例，可以帮助开发者快速入手，使用XPGWifiSDK开发GAgent物联APP。


项目功能介绍

    GoKit主要展示如何使用XPGWifiSDK，开发基于GAgent智能硬件APP。项目中用到了大部分主要SDK接口，供使用XPGWifiSDK的开发者参考。主要功能如下：
	▪	初始化SDK
	▪	匿名登录到云端
	▪	设备配置入网
	▪	搜索设备列表
	▪	绑定或解绑设备
	▪	设备登录
	▪	设备控制


项目依赖和安装

	▪	XPGWifiSDK框架
	  登录机智云官方网站http://gizwits.com的开发者中心下载并解压最新版本的SDK。如果您还尚未下载，请 点击这里下载 。
	  下载后，把压缩包中的XPGWifiSDK.framework拖动并复制到项目的 Frameworks 目录。

	  您也可以使用CocoaPods来安装XPGWifiSDK框架：
		source 'http://site.gizwits.com/generated/sdk/XPGWifiSDK-iOS-14.10.21.zip' pod 'GizwitsWiFiSDK', '~> 1.0.0'
	▪	OpenSSL组件
	  如果您尚未下载，请到这里下载：https://github.com/krzyzanowskim/OpenSSL/archive/master.zip
	  下载后，将OpenSSL的头文件和库文件添加到项目中。直接把include-ios和lib-ios目录拖到项目中即可。
	  
	▪	添加系统自带的libc++.dylib
	  在项目工程Targets的Build Phases里，在Link Binary With Libraries中直接添加libc++.dylib即可。

    上述依赖库添加完之后，在工程项目Targets的Build Phases中，Link Binary With Libraries会出现XPGWifiSDK.framework、libcrypto.a、libssl.a、libcrypto.a。



GoKit硬件依赖
    GoKit项目调试，需要有调试设备的支持，您可以使用虚拟设备或者实体设备搭建调试环境。

	▪	虚拟设备
	  机智云官网提供GoKit虚拟设备的支持，链接地址：
	http://site.gizwits.com/developer/product/631/virtualdevice

	▪	实体设备
	  GoKit开发板。您可以在机智云官方网站上免费预约申请（限量10000台）：http://gizwits.com/zh-cn/gokit
	  GoKit开发板提供MCU开源代码供智能硬件设计者参考，请去此处下载：https://github.com/gizwits/gokit-mcu



问题反馈
邮箱：janel@gizwits.com

