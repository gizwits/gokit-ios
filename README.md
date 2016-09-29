# 智云物联网APP开源框架工程

## 目录结构说明：


> Lib：包括 GizWifiSDK 在内的的第三方库目录

> GizOpenSourceModules：组成模块

>> CommonModule // 公共方法类、资源文件 及 自定义 Cell
    
>> ConfigModule // 设备配置模块，包含 AirLink 及 SoftAP
    
>> UserModule // 用户模块，包含 用户登录、用户注册、找回密码
    
>> DeviceModule // 设备模块，包含 设备列表
    
>> SettingsModule // 设置模块，包含 设置菜单 及其 包含的子菜单项（关于等）

>> PushModule // 推送模块，包含 百度和极光的推送SDK 集成封装
    
    
***

## 其他说明：

### 1. 默认程序入口
默认程序入口在 UserModule 中的 LoginViewController。

### 2. 更改启动后的载入界面
如果要启动程序直接进入设备列表，可在 LoginViewController.m 文件的 “- (void)viewDidLoad” 方法中打开最后一行代码的注释:

	[self toDeviceListWithoutLogin:nil]


### 3. 加载控制界面
代码位于 AppDelegate.m 文件中的 didFinishLaunchingWithOptions 方法第一行:

	[GosCommon sharedInstance].controlHandler = ^(GizWifiDevice device, UIViewController deviceListController) {
		GosDeviceController *devCtrl = [[GosDeviceController alloc] initWithDevice:device];
		[deviceListController.navigationController pushViewController:devCtrl animated:YES];
	};

修改 GosDeviceController 类为开发者自己编写的控制界面的类即可。

### 4. 设置界面
设置界面位于 SettingsModule 中的 GosSettingsViewController，按照 UITableView 实现官方的委托代理方法即可。

### 5. 配置文件说明
配置文件可对程序样式及机智云appid等进行配置。
配置参数有：

	app_id：机智云 app id
	app_secret：机智云 app secret
	product_key：机智云 product key
	wifi_type_select：默认配置模块wifi模组选择功能是否开启
	tencent_app_id：qq登录 app id
	wechat_app_id：微信登录 app id
	wechat_app_secret：微信登录 app secret
	push_type：推送类型 【0：关闭，1：极光，2：百度】
	jpush_app_key：极光推送 app key
	bpush_app_key：百度推送 app key
	openAPI_URL：openAPI 域名及端口，格式：“api.gizwits.com:80”，不写端口默认80
	site_URL：site 域名及端口，格式：“site.gizwits.com:80”，不写端口默认80
	push_URL：推送绑定服务器 域名及端口，格式：“push.gizwits.com:80”，不写端口默认80
	buttonColor：按钮颜色
	buttonTextColor：按钮文字颜色
	navigationBarColor：导航栏颜色
	navigationBarTextColor：导航栏文字颜色
	configProgressViewColor：配置中界面 progress view 颜色
	statusBarStyle：状态文字栏颜色 【0：黑色，1：白色】
	addDeviceTitle：添加设备界面 导航栏标题文字

具体细节可以参考【开源框架工程使用文档】。
    
