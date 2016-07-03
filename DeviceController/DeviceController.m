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

//#import "GizSDKInstance.h"

typedef enum {
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

@interface DeviceController () {
    UIAlertView *_alertView;
    
    // 这些变量用于数据更新
    BOOL bLedCtrl;
    NSInteger iLedR;
    NSInteger iledColor;
    CGFloat fLedR;
    CGFloat fLedG;
    CGFloat fLedB;
    CGFloat fMonitorSpeed;
    NSInteger iir;
    CGFloat fTemperature;
    CGFloat fHumidity;
    
    // 暂停数据更新
//    NSTimer *remainTimer;
    NSMutableArray *updateCtrl;
    MBProgressHUD *hud;
}

@property (readonly, nonatomic) GizWifiDevice *device;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation DeviceController 

- (id)initWithDevice:(GizWifiDevice *)device {
    self = [super init];
    if (self) {
        _device = device;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(menuBtnPressed)];
}

- (void)viewWillAppear:(BOOL)animated {
    GIZ_LOG_BIZ("device_control_page_show", "success", "device control page is shown");
    [super viewWillAppear:animated];
    
    //大循环判断设备是否在线
//    if (!self.device.isOnline && !self.device.isLAN) {
//        [_alertView dismissWithClickedButtonIndex:0 animated:YES];
//        _alertView = [[UIAlertView alloc] initWithTitle:@"警告" message:@"设备不在线，你不可以控制设备，但你可以解除绑定信息。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
//        [_alertView show];
//        self.view.userInteractionEnabled = NO;
//    }
    
    //初始化信息    
    NSString *devName = _device.alias;
    if (devName == nil || devName.length == 0) {
        devName = _device.productName;
    }
    self.navigationItem.title = devName;

    _device.delegate = self;
    
    iLedR = 0;
    iledColor = -1;
    fLedG = 0;
    fLedB = 0;
    iir = 0;
    fMonitorSpeed = 0;
    fTemperature = -1;
    fHumidity = -1;
    
    //暂停更新页面的计时器
//    if (!remainTimer) {
//        remainTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onRemainTimer) userInfo:nil repeats:YES];
//    }
    updateCtrl = [NSMutableArray array];
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = NSLocalizedString(@"Waiting for device ready", @"HUD loading title");
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    GIZ_LOG_BIZ("device_control_page_hide", "success", "device control page is hiden");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [remainTimer invalidate];
//    remainTimer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)menuBtnPressed {
    UIActionSheet *actionSheet = nil;
    if (self.device.isLAN) {
        actionSheet = [[UIActionSheet alloc]
                       initWithTitle:nil
                       delegate:self
                       cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                       destructiveButtonTitle:nil
                       otherButtonTitles:NSLocalizedString(@"get device status", nil), NSLocalizedString(@"get device hardware info", nil), NSLocalizedString(@"set device info", nil), nil];
    }
    else {
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
    if (buttonIndex == 0) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self.device getDeviceStatus];
    }else if (buttonIndex == 1 && self.device.isLAN) {
        [self.device getHardwareInfo];
    }else if ((buttonIndex == 1 && !self.device.isLAN) || (buttonIndex == 2 && self.device.isLAN)){
//        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:@"暂不支持" delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
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

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        UITextField *aliasField = [alertView textFieldAtIndex:0];
        UITextField *remarkField = [alertView textFieldAtIndex:1];
        [aliasField resignFirstResponder];
        [remarkField resignFirstResponder];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self.device setCustomInfo:remarkField.text alias:aliasField.text];
    }
}

- (void)device:(GizWifiDevice *)device didSetCustomInfo:(NSError *)result {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"set successful", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
//        [self toast:NSLocalizedString(@"success", nil)];
    }
    else {
        NSString *info = [NSString stringWithFormat:@"%@\n%@ - %@", NSLocalizedString(@"set failed", nil), @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:info delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
//        [self toast:info];
    }
}

- (void)device:(GizWifiDevice *)device didGetHardwareInfo:(NSError *)result hardwareInfo:(NSDictionary *)hardwareInfo {
    NSString *hardWareInfo = [NSString stringWithFormat:@"WiFi Hardware Version: %@,\nWiFi Software Version: %@,\nFirmware Id: %@,\nFirmware Version: %@,\nMCU Hardware Version: %@,\nMCU Software Version: %@,\nProduct Key: %@,\nDevice ID: %@,\nDevice IP: %@,\nDevice MAC: %@"
                              , [hardwareInfo valueForKey:@"wifiHardVersion"]
                              , [hardwareInfo valueForKey:@"wifiSoftVersion"]
                              , [hardwareInfo valueForKey:@"wifiFirmwareId"]
                              , [hardwareInfo valueForKey:@"wifiFirmwareVer"]
                              , [hardwareInfo valueForKey:@"mcuHardVersion"]
                              , [hardwareInfo valueForKey:@"mcuSoftVersion"]
                              , [hardwareInfo valueForKey:@"productKey"]
                              , self.device.did, self.device.ipAddress, self.device.macAddress];
    dispatch_async(dispatch_get_main_queue(), ^{
        _alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"device hardware info", nil) message:hardWareInfo delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [_alertView show];
    });
}

#pragma mark - event
- (void)onBack {
    [self.device setSubscribe:NO];
    _device.delegate = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onBackControl {
    [self.navigationController popViewControllerAnimated:YES];
    [self.device getDeviceStatus];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 9;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *slider_id = @"SliderCell";
    static NSString *label_id = @"LabelCell";
    static NSString *bool_id = @"BoolCell";
    static NSString *enum_id = @"EnumCell";
    
    NSString *reuseIndentifer = @"";
    
    switch (indexPath.row) {
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
    if (nil == cell) {
        UINib *nib = nil;
        if([reuseIndentifer isEqualToString:slider_id])
            nib = [UINib nibWithNibName:@"GizDeviceSliderCell" bundle:nil];
        else if([reuseIndentifer isEqualToString:label_id])
            nib = [UINib nibWithNibName:@"GizDeviceLabelCell" bundle:nil];
        else if([reuseIndentifer isEqualToString:bool_id])
            nib = [UINib nibWithNibName:@"GizDeviceBoolCell" bundle:nil];
        else if([reuseIndentifer isEqualToString:enum_id])
            nib = [UINib nibWithNibName:@"GizDeviceEnumCell" bundle:nil];
        
        if (nib) {
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
//            sliderCell.userInteractionEnabled = bLedCtrl;
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
//            sliderCell.userInteractionEnabled = bLedCtrl;
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
//            sliderCell.userInteractionEnabled = bLedCtrl;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
            [self addRemainElement:cell.tag];
            break;
        case 3:
            fLedG = value;
            [self writeDataPoint:GizDeviceWriteLED_G value:@(value)];
            [self addRemainElement:cell.tag];
            break;
        case 4:
            fLedB = value;
            [self writeDataPoint:GizDeviceWriteLED_B value:@(value)];
            [self addRemainElement:cell.tag];
            break;
        case 5:
            fMonitorSpeed = value;
            [self writeDataPoint:GizDeviceWriteMotorSpeed value:@(value)];
            [self addRemainElement:cell.tag];
            break;
        default:
            return;
    }
    [self addRemainElement:cell.tag];
}

- (void)GizDeviceSwitchDidUpdateValue:(GizDeviceBoolCell *)cell value:(BOOL)value {
    switch (cell.tag) {
        case 0:
            iLedR = value;
            [self writeDataPoint:GizDeviceWriteLED_R_onOff value:@(value)];
            [self addRemainElement:cell.tag];
            break;
        default:
            break;
    }
}

- (void)GizDeviceDidSelectedEnum:(GizDeviceEnumCell *)cell {
    GizDeviceEnumSelection *selectController = [[GizDeviceEnumSelection alloc] initWithEnumCell:cell];
    [selectController.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_arrow.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onBackControl)]];
    [self.navigationController pushViewController:selectController animated:YES];
}

- (void)GizDeviceEnumDidSelectedValue:(GizDeviceEnumCell *)cell index:(NSInteger)index {
    switch (cell.tag) {
        case 1:
            iledColor = index;
            [self writeDataPoint:GizDeviceWriteLED_Color value:@(index)];
            [self addRemainElement:cell.tag];
            break;
        default:
            break;
    }
}

- (CGFloat)prepareForUpdateFloatRows:(NSString *)str value:(CGFloat)value rows:(NSMutableArray *)rows index:(NSInteger)index {
    if ([self isElementRemaining:index]) return value;
    
    if ([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0)) {
        CGFloat newValue = [str floatValue];
        if (newValue != value) {
            value = newValue;
            [rows addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }
    return value;
}

- (NSInteger)prepareForUpdateIntegerRows:(NSString *)str value:(NSInteger)value rows:(NSMutableArray *)rows index:(NSInteger)index {
    if ([self isElementRemaining:index]) return value;
    
    if ([str isKindOfClass:[NSNumber class]] || ([str isKindOfClass:[NSString class]] && str.length > 0)) {
        NSInteger newValue = [str integerValue];
        if (newValue != value) {
            value = newValue;
            [rows addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }
    return value;
}

- (NSInteger)prepareForUpdateColorRows:(NSString *)str value:(NSInteger)value rows:(NSMutableArray *)rows index:(NSInteger)index {
    if ([str isKindOfClass:[NSString class]] && str.length > 0) {
        NSInteger newValue = -1;
        if ([str isEqualToString:@"自定义"]) newValue = 0;
        else if ([str isEqualToString:@"黄色"]) newValue = 1;
        else if ([str isEqualToString:@"紫色"]) newValue = 2;
        else if ([str isEqualToString:@"粉色"]) newValue = 3;
        if (newValue != value) {
            value = newValue;
            [rows addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }
    return value;
}

#pragma mark - GizWifiDeviceDelegate
- (void)device:(GizWifiDevice *)device didReceiveData:(NSError *)result data:(NSDictionary *)data withSN:(NSNumber *)sn {
    
    const char *strMacAddr = device.macAddress.UTF8String;
    const char *strDid = device.did.UTF8String;
    const char *strIsLAN = device.isLAN?"true":"false";
    
    // 8308 GIZ_SDK_REQUEST_TIMEOUT
    
    if (result.code != GIZ_SDK_SUCCESS) {
        NSString *info = [NSString stringWithFormat:@"%@ - %@", @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
        GIZ_LOG_BIZ("device_notify_error", "failed", "device notify error, result is %s, device mac is %s, did is %s, LAN is %s", info.UTF8String, strMacAddr, strDid, strIsLAN);
//        [self toast:[NSString stringWithFormat:@"状态回调错误：%@", info]];
        return;
    }
    
    [hud hideAnimated:YES];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    /**
     * 数据部分
     */
    NSDictionary *_data = [data valueForKey:@"data"];
    if (!_data || _data.count == 0) {
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
    
//    iLedR = [self prepareForUpdateIntegerRows:ledRonOff value:iLedR rows:rows index:0];
    iLedR = [ledRonOff integerValue];
    
    iledColor = [self prepareForUpdateColorRows:ledColor value:iledColor rows:rows index:1];
    fLedR = [ledR integerValue];
    fLedG = [ledG integerValue];
    fLedB = [ledB integerValue];
    
//    fLedR = [self prepareForUpdateFloatRows:ledR value:fLedR rows:rows index:2];
//    fLedG = [self prepareForUpdateFloatRows:ledG value:fLedG rows:rows index:3];
//    fLedB = [self prepareForUpdateFloatRows:ledB value:fLedB rows:rows index:4];
    
    fMonitorSpeed = [motorSpeed integerValue];
    iir = [ir integerValue];
    fTemperature = [temperature integerValue];
    fHumidity = [humidity integerValue];
    
//    fMonitorSpeed = [self prepareForUpdateFloatRows:motorSpeed value:fMonitorSpeed rows:rows index:5];
//    iir = [self prepareForUpdateIntegerRows:ir value:iir rows:rows index:6];
//    fTemperature = [self prepareForUpdateFloatRows:temperature value:fTemperature rows:rows index:7];
//    fHumidity = [self prepareForUpdateFloatRows:humidity value:fHumidity rows:rows index:8];
    
    
    GIZ_LOG_BIZ("device_notify_LED_OnOff", "success", "device notify LED_OnOff %i, errorCode is %i, device mac is %s, did is %s, LAN is %s", iLedR, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_LED_Color", "success", "device notify LED_Color %i, errorCode is %i, device mac is %s, did is %s, LAN is %s", iledColor, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_LED_R", "success", "device notify LED_R %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fLedR, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_LED_G", "success", "device notify LED_G %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fLedG, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_LED_B", "success", "device notify LED_B %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fLedB, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_Motor_Speed", "success", "device notify Motor_Speed %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fMonitorSpeed, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_Temperature", "success", "device notify Temperature %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fTemperature, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_Humidity", "success", "device notify Humidity %f, errorCode is %i, device mac is %s, did is %s, LAN is %s", fHumidity, result, strMacAddr, strDid, strIsLAN);
    GIZ_LOG_BIZ("device_notify_Infrared", "success", "device notify Infrared %i, errorCode is %i, device mac is %s, did is %s, LAN is %s", iir, result, strMacAddr, strDid, strIsLAN);
    
//    if (rows.count > 0) {
//        [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationNone];
//    }
    [self.tableView reloadData];
    
    // 如果 LED 组合颜色不是自定义，则 LED 不可控制
    if (iledColor > 0) {
        [self setCustomLEDMode:NO];
    } else {
        [self setCustomLEDMode:YES];
    }
    
    /**
     * 报警和错误
     */
    if ([self.navigationController.viewControllers lastObject] != self) return;
    
    NSString *str = @"";
    NSArray *alerts = [data valueForKey:@"alerts"];
    NSArray *faults = [data valueForKey:@"faults"];
    
    if (alerts.count == 0 && faults.count == 0) return;
    if (alerts.count > 0) {
        BOOL isFirst = YES;
        for (NSString *name in alerts) {
            NSNumber *value = [alerts valueForKey:name];
            
            if (![value isKindOfClass:[NSNumber class]]) continue;
            if ([value integerValue] == 0) continue;
           
            if ([name isEqualToString:@"Alert_1"]) {
                GIZ_LOG_BIZ("device_notify_Alert_1", "success", "device notify Alert_1 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            } else if ([name isEqualToString:@"Alert_2"]) {
                GIZ_LOG_BIZ("device_notify_Alert_2", "success", "device notify Alert_2 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            }
            
            if (isFirst) {
                str = @"设备报警：";
                isFirst = NO;
            }
            
            if (str.length > 0) {
                str = [str stringByAppendingString:@"\n"];
            }
            
            NSString *alert = [NSString stringWithFormat:@"%@ 错误码：%@", name, value];
            str = [str stringByAppendingString:alert];
        }
    }
    
    if (faults.count > 0) {
        BOOL isFirst = YES;
        
        for (NSString *name in faults) {
            NSNumber *value = [faults valueForKey:name];
            
            if (![value isKindOfClass:[NSNumber class]]) continue;
            if ([value integerValue] == 0) continue;
            
            if ([name isEqualToString:@"Fault_LED"]) {
                GIZ_LOG_BIZ("device_notify_Fault_LED", "success", "device notify Fault_LED 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            } else if ([name isEqualToString:@"Fault_Motor"]) {
                GIZ_LOG_BIZ("device_notify_Fault_Motor", "success", "device notify Fault_Motor 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            } else if ([name isEqualToString:@"Fault_TemHum"]) {
                GIZ_LOG_BIZ("device_notify_Fault_TemHum", "success", "device notify Fault_TemHum 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            } else if ([name isEqualToString:@"Fault_IR"]) {
                GIZ_LOG_BIZ("device_notify_Fault_IR", "success", "device notify Fault_IR 1, device mac is %s, did is %s, LAN is %s", strMacAddr, strDid, strIsLAN);
            }

            if (isFirst) {
                if (str.length > 0) {
                    str = [str stringByAppendingString:@"\n"];
                }
                str = [str stringByAppendingString:@"设备错误："];
                isFirst = NO;
            }
            
            if (str.length > 0) {
                str = [str stringByAppendingString:@"\n"];
            }
            
            NSString *fault = [NSString stringWithFormat:@"%@ 错误码：%@", name, value];
            str = [str stringByAppendingString:fault];
        }
    }
    
    //    NSLog(@"str = \"%@\"", str);
    
    if (str.length > 0) {
        [self performSelectorInBackground:@selector(toast:) withObject:str];
    }
}

- (void)device:(GizWifiDevice *)device didUpdateNetStatus:(GizWifiDeviceNetStatus)netStatus {
    if (netStatus == GizDeviceOffline || netStatus == GizDeviceUnavailable) {
        GIZ_LOG_BIZ("device_notify_disconnected", "success", "device notify disconnected, device mac is %s, did is %s, LAN is %s", self.device.macAddress.UTF8String, self.device.did.UTF8String, self.device.isLAN?"true":"false");
        [_alertView dismissWithClickedButtonIndex:0 animated:YES];
        _alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"连接已断开" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [_alertView show];
        [self performSelector:@selector(onBack) withObject:nil afterDelay:0.5];
    }
//    else if (netStatus == GizDeviceControlled) {
//        [MBProgressHUD hideHUDForView:self.view animated:YES];
//        [self.device getDeviceStatus];
//    }
}

#pragma mark - others
- (void)setCustomLEDMode:(BOOL)mode {
    //设置 LED 的 RGB 值是否可用
    bLedCtrl = mode;
    NSArray *leds = @[[NSIndexPath indexPathForRow:2 inSection:0],
                      [NSIndexPath indexPathForRow:3 inSection:0],
                      [NSIndexPath indexPathForRow:4 inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:leds withRowAnimation:UITableViewRowAnimationNone];
}

- (void)toast:(NSString *)strToast {
    //弹出一段字符，最多不超过3行
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:strToast delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alertView show];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(3);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:YES];
        });
    });
}

#pragma mark - 发控制指令后一段时间内禁止推送
- (void)addRemainElement:(NSInteger)row {
    BOOL isEqual = NO;
    NSNumber *timeout = @3;    // 发控制指令后，等待3s后才可接收指定控件的变更
    
    for (NSMutableDictionary *dict in updateCtrl) {
        NSNumber *object = [dict valueForKey:@"object"];
        if ([object intValue] == row) {
            [dict setValue:timeout forKey:@"remaining"];
            isEqual = YES;
            break;
        }
    }
    
    if (!isEqual) {
        NSMutableDictionary *mdict = [NSMutableDictionary dictionaryWithDictionary:@{@"object": @(row), @"remaining": timeout}];
        [updateCtrl addObject:mdict];
    }
}
/*
- (void)onRemainTimer {
    //根据系统的 Timer 去更新控件可以变更的剩余时间
    NSMutableArray *removeCtrl = [NSMutableArray array];
    for (NSMutableDictionary *dict in updateCtrl) {
        int remainTime = [[dict valueForKey:@"remaining"] intValue] - 1;
        if (remainTime != 0) {
            [dict setValue:@(remainTime) forKey:@"remaining"];
        } else {
            [removeCtrl addObject:dict];
        }
    }
    [updateCtrl removeObjectsInArray:removeCtrl];
}
*/
- (BOOL)isElementRemaining:(NSInteger)row {
    //判断某个控件是否能更新内容
    for (NSMutableDictionary *dict in updateCtrl) {
        NSNumber *object = [dict valueForKey:@"object"];
        if ([object intValue] == row) return YES;
    }
    return NO;
}

@end
