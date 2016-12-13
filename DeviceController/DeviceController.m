//
//  GizDeviceController.m
//  GBOSA
//
//  Created by Zono on 16/5/6.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "DeviceController.h"
#import "GizLog.h"
#import "GosCommon.h"
#import "GosTipView.h"

typedef enum
{
    // writable
    GizDeviceWriteLED_R_onOff,      //LED R开关
    GizDeviceWriteLED_Color,        //LED 组合颜色
    GizDeviceWriteLED_R,            //LED R值
    GizDeviceWriteLED_G,            //LED G值
    GizDeviceWriteLED_B,            //LED B值
    GizDeviceWriteMotorSpeed,       //电机转速
    
    // readonly
    GizDeviceReadIR,                //红外
    GizDeviceReadTemperature,       //温度
    GizDeviceReadHumidity,          //湿度
    
    // alarm
    GizDeviceAlarm1,                //报警1
    GizDeviceAlarm2,                //报警2
    
    // fault
    GizDeviceFaultLED,              //LED故障
    GizDeviceFaultMotor,            //电机故障
    GizDeviceFaultSensor,           //温湿度传感器故障
    GizDeviceFaultIR,               //红外故障
} GizDeviceDataPoint;

#define DATA_ATTR_LED_R_ONOFF           @"LED_OnOff"        //属性：LED R开关
#define DATA_ATTR_LED_COLOR             @"LED_Color"        //属性：LED 组合颜色
#define DATA_ATTR_LED_R                 @"LED_R"            //属性：LED R值
#define DATA_ATTR_LED_G                 @"LED_G"            //属性：LED G值
#define DATA_ATTR_LED_B                 @"LED_B"            //属性：LED B值
#define DATA_ATTR_MOTORSPEED            @"Motor_Speed"      //属性：电机转速
#define DATA_ATTR_IR                    @"Infrared"         //属性：红外探测
#define DATA_ATTR_TEMPERATURE           @"Temperature"      //属性：温度
#define DATA_ATTR_HUMIDITY              @"Humidity"         //属性：湿度

@interface DeviceController ()
{
    UIAlertView *_alertView;
    
    // 这些变量用于数据更新
    NSInteger iLedR;
    NSInteger iledColor;
    CGFloat fLedR;
    CGFloat fLedG;
    CGFloat fLedB;
    CGFloat fMonitorSpeed;
    NSInteger iir;
    CGFloat fTemperature;
    CGFloat fHumidity;
}

@property (readonly, nonatomic) GizWifiDevice *device;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

// 网络检测线程
@property (nonatomic, strong) NSOperationQueue *queue;
//提示框
@property (nonatomic, strong) GosTipView *tipView;

@end

@implementation DeviceController 

- (id)initWithDevice:(GizWifiDevice *)device
{
    self = [super init];
    if (self)
    {
        _device = device;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(menuBtnPressed)];
    
    _device.delegate = self;
    [self.tipView showLoadTipWithMessage:NSLocalizedString(@"Waiting for device ready", @"HUD loading title")];
    [self checkDeviceStatus];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 日志输出
    GIZ_LOG_BIZ("device_control_page_show", "success", "device control page is shown");
    
    //初始化信息    
    NSString *devName = _device.alias;
    if (devName == nil || devName.length == 0)
    {
        devName = _device.productName;
    }
    self.navigationItem.title = devName;
    
    iLedR = 0;
    iledColor = -1;
    fLedG = 0;
    fLedB = 0;
    iir = 0;
    fMonitorSpeed = 0;
    fTemperature = -1;
    fHumidity = -1;
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    GIZ_LOG_BIZ("device_control_page_hide", "success", "device control page is hiden");
}

#pragma mark 检查设备状态
- (void)checkDeviceStatus
{
    if (self.device.netStatus == GizDeviceControlled)
    {
        // 设备可控获取设备状态
//        [self.tipView hideTipView];
        [self.device getDeviceStatus];
        
        return;
    }
    
    // 开启一个子线程 检测设备状态
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    
    __weak NSBlockOperation *weakOperation = operation;
    [operation addExecutionBlock:^{
        int timeInterval = self.device.isLAN ? 10 : 20;
        
        // 小循环延时 10s / 大循环延时 20s
        [NSThread sleepForTimeInterval:timeInterval];
        
        if (![weakOperation isCancelled])
        {
            if (self.device.netStatus != GizDeviceControlled)
            {
                // 10s后 设备不可控，退到设备列表
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 退到设备列表
                    if (self.navigationController.viewControllers.lastObject == self)
                    {
                        [self.tipView showLoadTipWithMessage:NSLocalizedString(@"No response from device,Please check the running state of device", @"HUD loading title") delay:1 completion:^{
                            [self performSelector:@selector(onBack)];
                        }];
                    }
                });
                
            }
            else
            {
                // 可控，获取设备状态
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.device getDeviceStatus];
                    
                });
            }
            // 关闭所有线程
            [self.queue cancelAllOperations];
        }
        
    }];
    
    // 取消其它所有正在检测设备网络状态的线程
    if (self.queue.operationCount > 0)
    {
        [self.queue cancelAllOperations];
    }
    [self.queue addOperation:operation];
    
}

- (void)menuBtnPressed
{
    UIActionSheet *actionSheet = nil;
    if (self.device.isLAN)
    {
        actionSheet = [[UIActionSheet alloc]
                       initWithTitle:nil
                       delegate:self
                       cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                       destructiveButtonTitle:nil
                       otherButtonTitles:NSLocalizedString(@"get device status", nil), NSLocalizedString(@"get device hardware info", nil), NSLocalizedString(@"set device info", nil), nil];
    }
    else
    {
        actionSheet = [[UIActionSheet alloc]
                       initWithTitle:nil
                       delegate:self
                       cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                       destructiveButtonTitle:nil
                       otherButtonTitles:NSLocalizedString(@"get device status", nil), NSLocalizedString(@"set device info", nil), nil];
    }
    
    actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

#pragma mark - actionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [self.tipView showLoadTipWithMessage:nil];
        [self.device getDeviceStatus];
    }
    else if (buttonIndex == 1 && self.device.isLAN)
    {
        [self.device getHardwareInfo];
    }
    else if ((buttonIndex == 1 && !self.device.isLAN) || (buttonIndex == 2 && self.device.isLAN))
    {

        UIAlertView *customAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"set alias and remark", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        
        [customAlertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        
        UITextField *aliasField = [customAlertView textFieldAtIndex:0];
        aliasField.placeholder = NSLocalizedString(@"input alias", nil);
        aliasField.text = self.device.alias;
        
        UITextField *remarkField = [customAlertView textFieldAtIndex:1];
        [remarkField setSecureTextEntry:NO];
        remarkField.placeholder = NSLocalizedString(@"input remark", nil);
        remarkField.text = self.device.remark;
        
        [customAlertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
    {
        UITextField *aliasField = [alertView textFieldAtIndex:0];
        UITextField *remarkField = [alertView textFieldAtIndex:1];
        [aliasField resignFirstResponder];
        [remarkField resignFirstResponder];
        [self.tipView showLoadTipWithMessage:nil];
        [self.device setCustomInfo:remarkField.text alias:aliasField.text];
    }
}

- (void)device:(GizWifiDevice *)device didSetCustomInfo:(NSError *)result
{
    [self.tipView hideTipView];
    if (result.code == GIZ_SDK_SUCCESS)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"set successful", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
    }
    else
    {
        NSString *info = [[GosCommon sharedInstance] checkErrorCode:result.code];
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:info delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
    }
}

- (void)device:(GizWifiDevice *)device didGetHardwareInfo:(NSError *)result hardwareInfo:(NSDictionary *)hardwareInfo
{
    NSString *hardWareInfo = [NSString stringWithFormat:@"WiFi Hardware Version: %@,\nWiFi Software Version: %@,\nMCU Hardware Version: %@,\nMCU Software Version: %@,\nFirmware Id: %@,\nFirmware Version: %@,\nProduct Key: %@,\nDevice ID: %@,\nDevice IP: %@,\nDevice MAC: %@"
                              , [hardwareInfo valueForKey:@"wifiHardVersion"]
                              , [hardwareInfo valueForKey:@"wifiSoftVersion"]
                              , [hardwareInfo valueForKey:@"mcuHardVersion"]
                              , [hardwareInfo valueForKey:@"mcuSoftVersion"]
                              , [hardwareInfo valueForKey:@"wifiFirmwareId"]
                              , [hardwareInfo valueForKey:@"wifiFirmwareVer"]
                              , [hardwareInfo valueForKey:@"productKey"]
                              , self.device.did, self.device.ipAddress, self.device.macAddress];
    dispatch_async(dispatch_get_main_queue(), ^{
        _alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"device hardware info", nil) message:hardWareInfo delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [_alertView show];
    });
}

#pragma mark - event
- (void)onBack
{
    NSLog(@"****************************解除订阅****************************");
    [self.device setSubscribe:NO];
    _device.delegate = nil;
    [_alertView dismissWithClickedButtonIndex:0 animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onBackControl {
    [self.navigationController popViewControllerAnimated:YES];
    [self.device getDeviceStatus];
}

#pragma mark - tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 9;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 2:
        case 3:
        case 4:
        case 5:
            return 70;
        default:
            break;
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *slider_id = @"SliderCell";
    static NSString *label_id = @"LabelCell";
    static NSString *bool_id = @"BoolCell";
    static NSString *enum_id = @"EnumCell";
    
    NSString *reuseIndentifer = @"";
    
    switch (indexPath.row)
    {
        case 0:
        case 6:
            reuseIndentifer = bool_id;
            break;
        case 1:
            reuseIndentifer = enum_id;
            break;
        case 2:
        case 3:
        case 4:
        case 5:
           reuseIndentifer = slider_id;
            break;
        case 7:
        case 8:
            reuseIndentifer = label_id;
            break;
        default:
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIndentifer];
    if (nil == cell)
    {
        UINib *nib = nil;
        if([reuseIndentifer isEqualToString:slider_id])
        {
            nib = [UINib nibWithNibName:@"GizDeviceSliderCell" bundle:nil];
        }
        else if([reuseIndentifer isEqualToString:label_id])
        {
            nib = [UINib nibWithNibName:@"GizDeviceLabelCell" bundle:nil];
        }
        else if([reuseIndentifer isEqualToString:bool_id])
        {
            nib = [UINib nibWithNibName:@"GizDeviceBoolCell" bundle:nil];
        }
        else if([reuseIndentifer isEqualToString:enum_id])
        {
            nib = [UINib nibWithNibName:@"GizDeviceEnumCell" bundle:nil];
        }
        
        if (nib)
        {
            [tableView registerNib:nib forCellReuseIdentifier:reuseIndentifer];
            cell = [tableView dequeueReusableCellWithIdentifier:reuseIndentifer];
        }
    }
    
    if (!cell) return cell;
    
    switch (indexPath.row) {
        case 0: {
            GizDeviceBoolCell *boolCell = (GizDeviceBoolCell *)cell;
            boolCell.title = @"开启/关闭红色灯";
            boolCell.value = iLedR;
            boolCell.tag = indexPath.row;
            boolCell.delegate = self;
            boolCell.userInteractionEnabled = YES;
            break;
        }
        case 1: {
            GizDeviceEnumCell *enumCell = (GizDeviceEnumCell *)cell;
            enumCell.title = @"设定LED组合颜色";
            enumCell.values = @[@"自定义", @"黄色", @"紫色", @"粉色"];
            enumCell.index = iledColor;
            enumCell.tag = indexPath.row;
            enumCell.delegate = self;
            break;
        }
        case 2: {
            GizDeviceSliderCell *sliderCell = (GizDeviceSliderCell *)cell;
            sliderCell.title = @"设定LED颜色R值";
            sliderCell.min = 0;
            sliderCell.max = 254;
            sliderCell.value = fLedR;
            sliderCell.step = 1;
            sliderCell.tag = indexPath.row;
            sliderCell.delegate = self;
            sliderCell.userInteractionEnabled = YES;
            break;
        }
        case 3: {
            GizDeviceSliderCell *sliderCell = (GizDeviceSliderCell *)cell;
            sliderCell.title = @"设定LED颜色G值";
            sliderCell.min = 0;
            sliderCell.max = 254;
            sliderCell.value = fLedG;
            sliderCell.step = 1;
            sliderCell.tag = indexPath.row;
            sliderCell.delegate = self;
            sliderCell.userInteractionEnabled = YES;
            break;
        }
        case 4: {
            GizDeviceSliderCell *sliderCell = (GizDeviceSliderCell *)cell;
            sliderCell.title = @"设定LED颜色B值";
            sliderCell.min = 0;
            sliderCell.max = 254;
            sliderCell.value = fLedB;
            sliderCell.step = 1;
            sliderCell.tag = indexPath.row;
            sliderCell.delegate = self;
            sliderCell.userInteractionEnabled = YES;
            break;
        }
        case 5: {
            GizDeviceSliderCell *sliderCell = (GizDeviceSliderCell *)cell;
            sliderCell.title = @"设定电机转速";
            sliderCell.min = -5;
            sliderCell.max = 5;
            sliderCell.value = fMonitorSpeed;
            sliderCell.step = 1;
            sliderCell.tag = indexPath.row;
            sliderCell.delegate = self;
            break;
        }
        case 6: {
            GizDeviceBoolCell *boolCell = (GizDeviceBoolCell *)cell;
            boolCell.title = @"红外探测";
            boolCell.value = iir;
            boolCell.tag = indexPath.row;
            boolCell.delegate = self;
            boolCell.userInteractionEnabled = NO;
            break;
        }
        case 7: {
            GizDeviceLabelCell *sliderCell = (GizDeviceLabelCell *)cell;
            sliderCell.title = @"温度";
            if(fTemperature < 0)
                sliderCell.value = @"-";
            else
                sliderCell.value = [NSString stringWithFormat:@"%@", @(fTemperature)];
            break;
        }
        case 8: {
            GizDeviceLabelCell *sliderCell = (GizDeviceLabelCell *)cell;
            sliderCell.title = @"湿度";
            if(fHumidity < 0)
                sliderCell.value = @"-";
            else
                sliderCell.value = [NSString stringWithFormat:@"%@", @(fHumidity)];
            break;
        }
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Data Point
- (void)writeDataPoint:(GizDeviceDataPoint)dataPoint value:(NSObject *)value {
    NSDictionary *data = nil;
    switch (dataPoint) {
        case GizDeviceWriteLED_R_onOff:
            GIZ_LOG_BIZ("device_control_LED_OnOff", "success", "device control LED_OnOff %s, device mac is %s, did is %s, LAN is %s", value.description.UTF8String, self.device.macAddress.UTF8String, self.device.did.UTF8String, self.device.isLAN?"true":"false");
            data = @{DATA_ATTR_LED_R_ONOFF: value};
            break;
        case GizDeviceWriteLED_Color:
            GIZ_LOG_BIZ("device_control_LED_Color", "success", "device control LED_Color %s, device mac is %s, did is %s, LAN is %s", value.description.UTF8String, self.device.macAddress.UTF8String, self.device.did.UTF8String, self.device.isLAN?"true":"false");
            data = @{DATA_ATTR_LED_COLOR: value};
            break;
        case GizDeviceWriteLED_R:
            GIZ_LOG_BIZ("device_control_LED_R", "success", "device control LED_R %s, device mac is %s, did is %s, LAN is %s", value.description.UTF8String, self.device.macAddress.UTF8String, self.device.did.UTF8String, self.device.isLAN?"true":"false");
            data = @{DATA_ATTR_LED_R: value};
            break;
        case GizDeviceWriteLED_G:
            GIZ_LOG_BIZ("device_control_LED_G", "success", "device control LED_G %s, device mac is %s, did is %s, LAN is %s", value.description.UTF8String, self.device.macAddress.UTF8String, self.device.did.UTF8String, self.device.isLAN?"true":"false");
            data = @{DATA_ATTR_LED_G: value};
            break;
        case GizDeviceWriteLED_B:
            GIZ_LOG_BIZ("device_control_LED_B", "success", "device control LED_B %s, device mac is %s, did is %s, LAN is %s", value.description.UTF8String, self.device.macAddress.UTF8String, self.device.did.UTF8String, self.device.isLAN?"true":"false");
            data = @{DATA_ATTR_LED_B: value};
            break;
        case GizDeviceWriteMotorSpeed:
            GIZ_LOG_BIZ("device_control_Motor_Speed", "success", "device control Motor_Speed %s, device mac is %s, did is %s, LAN is %s", value.description.UTF8String, self.device.macAddress.UTF8String, self.device.did.UTF8String, self.device.isLAN?"true":"false");
            data = @{DATA_ATTR_MOTORSPEED: value};
            break;
        default:
            GIZ_LOG_ERROR("Error: write invalid datapoint, skip.");
            return;
    }
    
    GIZ_LOG_DEBUG("Write data: %s", data.description.UTF8String);
    [self.device write:data withSN:0];
}

- (id)readDataPoint:(GizDeviceDataPoint)dataPoint data:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        GIZ_LOG_ERROR("Error: could not read data, error data format.");
        return nil;
    }
    
    switch (dataPoint) {
        case GizDeviceWriteLED_R_onOff:
            return [data valueForKey:DATA_ATTR_LED_R_ONOFF];
        case GizDeviceWriteLED_Color:
            return [data valueForKey:DATA_ATTR_LED_COLOR];
        case GizDeviceWriteLED_R:
            return [data valueForKey:DATA_ATTR_LED_R];
        case GizDeviceWriteLED_G:
            return [data valueForKey:DATA_ATTR_LED_G];
        case GizDeviceWriteLED_B:
            return [data valueForKey:DATA_ATTR_LED_B];
        case GizDeviceWriteMotorSpeed:
            return [data valueForKey:DATA_ATTR_MOTORSPEED];
        case GizDeviceReadIR:
            return [data valueForKey:DATA_ATTR_IR];
        case GizDeviceReadTemperature:
            return [data valueForKey:DATA_ATTR_TEMPERATURE];
        case GizDeviceReadHumidity:
            return [data valueForKey:DATA_ATTR_HUMIDITY];
        default:
            GIZ_LOG_ERROR("Error: read invalid datapoint, skip.");
            break;
    }
    return nil;
}

#pragma mark - Callbacks
- (void)GizDeviceSliderDidUpdateValue:(GizDeviceSliderCell *)cell value:(CGFloat)value {
    switch (cell.tag) {
        case 2:
            fLedR = value;
            [self writeDataPoint:GizDeviceWriteLED_R value:@(value)];
            break;
        case 3:
            fLedG = value;
            [self writeDataPoint:GizDeviceWriteLED_G value:@(value)];
            break;
        case 4:
            fLedB = value;
            [self writeDataPoint:GizDeviceWriteLED_B value:@(value)];
            break;
        case 5:
            fMonitorSpeed = value;
            [self writeDataPoint:GizDeviceWriteMotorSpeed value:@(value)];
            break;
        default:
            return;
    }
}

- (void)GizDeviceSwitchDidUpdateValue:(GizDeviceBoolCell *)cell value:(BOOL)value
{
    switch (cell.tag)
    {
        case 0:
            iLedR = value;
            [self writeDataPoint:GizDeviceWriteLED_R_onOff value:@(value)];
            break;
        default:
            break;
    }
}

- (void)GizDeviceDidSelectedEnum:(GizDeviceEnumCell *)cell
{
    GizDeviceEnumSelection *selectController = [[GizDeviceEnumSelection alloc] initWithEnumCell:cell];
    [selectController.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onBackControl)]];
    [self.navigationController pushViewController:selectController animated:YES];
}

- (void)GizDeviceEnumDidSelectedValue:(GizDeviceEnumCell *)cell index:(NSInteger)index
{
    switch (cell.tag) {
        case 1:
            iledColor = index;
            [self writeDataPoint:GizDeviceWriteLED_Color value:@(index)];
            break;
        default:
            break;
    }
}

- (NSInteger)prepareForUpdateColorRows:(NSString *)str value:(NSInteger)value rows:(NSMutableArray *)rows index:(NSInteger)index
{
    NSInteger newValue = [str integerValue];
    if (newValue != value)
    {
        value = newValue;
        [rows addObject:[NSIndexPath indexPathForRow:index inSection:0]];
    }
    return value;
}

#pragma mark - GizWifiDeviceDelegate
- (void)device:(GizWifiDevice *)device didReceiveData:(NSError *)result data:(NSDictionary *)data withSN:(NSNumber *)sn {
    
    [self.tipView hideTipView];
    
    const char *strMacAddr = device.macAddress.UTF8String;
    const char *strDid = device.did.UTF8String;
    const char *strIsLAN = device.isLAN?"true":"false";
    
    // 8308 GIZ_SDK_REQUEST_TIMEOUT
    if (result.code != GIZ_SDK_SUCCESS)
    {
        NSString *info = [NSString stringWithFormat:@"%@ - %@", @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
        GIZ_LOG_BIZ("device_notify_error", "failed", "device notify error, result is %s, device mac is %s, did is %s, LAN is %s", info.UTF8String, strMacAddr, strDid, strIsLAN);
        return;
    }
    
    /**
     * 数据部分
     */
    NSDictionary *_data = [data valueForKey:@"data"];
    if (!_data || _data.count == 0)
    {
        return;
    }
    
    NSString *ledRonOff = [self readDataPoint:GizDeviceWriteLED_R_onOff data:_data];
    NSString *ledColor = [self readDataPoint:GizDeviceWriteLED_Color data:_data];
    NSString *ledR = [self readDataPoint:GizDeviceWriteLED_R data:_data];
    NSString *ledG = [self readDataPoint:GizDeviceWriteLED_G data:_data];
    NSString *ledB = [self readDataPoint:GizDeviceWriteLED_B data:_data];
    NSString *motorSpeed = [self readDataPoint:GizDeviceWriteMotorSpeed data:_data];
    NSString *ir = [self readDataPoint:GizDeviceReadIR data:_data];
    NSString *temperature = [self readDataPoint:GizDeviceReadTemperature data:_data];
    NSString *humidity = [self readDataPoint:GizDeviceReadHumidity data:_data];
    
    NSMutableArray *rows = [NSMutableArray array];
    
    iLedR = [ledRonOff integerValue];
    
    iledColor = [self prepareForUpdateColorRows:ledColor value:iledColor rows:rows index:1];
    fLedR = [ledR integerValue];
    fLedG = [ledG integerValue];
    fLedB = [ledB integerValue];
    
    fMonitorSpeed = [motorSpeed integerValue];
    iir = [ir integerValue];
    fTemperature = [temperature integerValue];
    fHumidity = [humidity integerValue];
    
    GIZ_LOG_BIZ("device_notify_LED_OnOff", "success", "device notify LED_OnOff %i, errorCode is %i, device mac is %s, did is %s, LAN is %s", iLedR, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_LED_Color", "success", "device notify LED_Color %i, errorCode is %i, device mac is %s, did is %s, LAN is %s", iledColor, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_LED_R", "success", "device notify LED_R %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fLedR, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_LED_G", "success", "device notify LED_G %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fLedG, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_LED_B", "success", "device notify LED_B %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fLedB, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_Motor_Speed", "success", "device notify Motor_Speed %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fMonitorSpeed, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_Temperature", "success", "device notify Temperature %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fTemperature, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_Humidity", "success", "device notify Humidity %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fHumidity, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_Infrared", "success", "device notify Infrared %i, errorCode is %i, device mac is %s, did is %s, LAN is %s", iir, result, strMacAddr, strDid, strIsLAN);
    
    [self.tableView reloadData];
    
    /**
     * 报警和错误
     */
    if ([self.navigationController.viewControllers lastObject] != self) return;
    
    NSString *str = @"";
    NSArray *alerts = [data valueForKey:@"alerts"];
    NSArray *faults = [data valueForKey:@"faults"];
    
    if (alerts.count == 0 && faults.count == 0) return;
    if (alerts.count > 0)
    {
        BOOL isFirst = YES;
        for (NSString *name in alerts)
        {
            NSNumber *value = [alerts valueForKey:name];
            
            if (![value isKindOfClass:[NSNumber class]]) continue;
            if ([value integerValue] == 0) continue;
           
            if ([name isEqualToString:@"Alert_1"])
            {
                GIZ_LOG_BIZ("device_notify_Alert_1", "success", "device notify Alert_1 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            } else if ([name isEqualToString:@"Alert_2"])
            {
                GIZ_LOG_BIZ("device_notify_Alert_2", "success", "device notify Alert_2 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            }
            
            if (isFirst)
            {
                str = @"设备报警：";
                isFirst = NO;
            }
            
            if (str.length > 0)
            {
                str = [str stringByAppendingString:@"\n"];
            }
            
            NSString *alert = [NSString stringWithFormat:@"%@ 错误码：%@", name, value];
            str = [str stringByAppendingString:alert];
        }
    }
    
    if (faults.count > 0)
    {
        BOOL isFirst = YES;
        
        for (NSString *name in faults)
        {
            NSNumber *value = [faults valueForKey:name];
            
            if (![value isKindOfClass:[NSNumber class]]) continue;
            if ([value integerValue] == 0) continue;
            
            if ([name isEqualToString:@"Fault_LED"])
            {
                GIZ_LOG_BIZ("device_notify_Fault_LED", "success", "device notify Fault_LED 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            } else if ([name isEqualToString:@"Fault_Motor"])
            {
                GIZ_LOG_BIZ("device_notify_Fault_Motor", "success", "device notify Fault_Motor 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            } else if ([name isEqualToString:@"Fault_TemHum"])
            {
                GIZ_LOG_BIZ("device_notify_Fault_TemHum", "success", "device notify Fault_TemHum 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            } else if ([name isEqualToString:@"Fault_IR"])
            {
                GIZ_LOG_BIZ("device_notify_Fault_IR", "success", "device notify Fault_IR 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            }

            if (isFirst)
            {
                if (str.length > 0)
                {
                    str = [str stringByAppendingString:@"\n"];
                }
                str = [str stringByAppendingString:@"设备错误："];
                isFirst = NO;
            }
            
            if (str.length > 0)
            {
                str = [str stringByAppendingString:@"\n"];
            }
            
            NSString *fault = [NSString stringWithFormat:@"%@ 错误码：%@", name, value];
            str = [str stringByAppendingString:fault];
        }
    }
    
    if (str.length > 0)
    {
        [[GosCommon sharedInstance] showAlert:str disappear:YES];
    }
}

- (void)device:(GizWifiDevice *)device didUpdateNetStatus:(GizWifiDeviceNetStatus)netStatus
{
    NSLog(@"netStatus = %d", netStatus);
    if (netStatus != GizDeviceControlled)
    {
        GIZ_LOG_BIZ("device_notify_disconnected", "success", "device notify disconnected, device mac is %s, did is %s, LAN is %s", self.device.macAddress.UTF8String, self.device.did.UTF8String, self.device.isLAN?"true":"false");
        [self.tipView showLoadTipWithMessage:NSLocalizedString(@"connection dropped", nil) delay:1 completion:^{
            [self performSelector:@selector(onBack)];
        }];
    }
    else
    {
        NSLog(@"SDK版本 = %@", [GizWifiSDK getVersion]);
        [self.tipView hideTipView];
        [self.device getDeviceStatus];
    }
}

#pragma mark - Properity
- (NSOperationQueue *)queue
{
    if (_queue == nil)
    {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

- (GosTipView *)tipView
{
    if (_tipView == nil)
    {
        _tipView = [GosTipView sharedInstance];
    }
    return _tipView;
}

@end
