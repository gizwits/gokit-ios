/**
 * IoTDeviceController.m
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "IoTDeviceController.h"
#import <itoast.h>

typedef enum
{
    // writable
    IoTDeviceWriteUpdateData = 0,   //更新数据
    IoTDeviceWriteLED_R_onOff,      //LED R开关
    IoTDeviceWriteLED_Color,        //LED 组合颜色
    IoTDeviceWriteLED_R,            //LED R值
    IoTDeviceWriteLED_G,            //LED G值
    IoTDeviceWriteLED_B,            //LED B值
    IoTDeviceWriteMotorSpeed,       //电机转速
    
    // readonly
    IoTDeviceReadIR,                //红外
    IoTDeviceReadTemperature,       //温度
    IoTDeviceReadHumidity,          //湿度
    
    // alarm
    IoTDeviceAlarm1,                //报警1
    IoTDeviceAlarm2,                //报警2
    
    // fault
    IoTDeviceFaultLED,              //LED故障
    IoTDeviceFaultMotor,            //电机故障
    IoTDeviceFaultSensor,           //温湿度传感器故障
    IoTDeviceFaultIR,               //红外故障
}IoTDeviceDataPoint;

typedef enum
{
    IoTDeviceCommandWrite = 1,      //写
    IoTDeviceCommandRead = 2,       //读
    IoTDeviceCommandResponse = 3,   //读响应
    IoTDeviceCommandNotify = 4,     //通知
}IoTDeviceCommand;

#define DATA_CMD                        @"cmd"      //命令
#define DATA_ENTITY                     @"entity0"  //实体
#define DATA_ATTR_LED_R_ONOFF           @"attr0"    //属性：LED R开关
#define DATA_ATTR_LED_COLOR             @"attr1"    //属性：LED 组合颜色
#define DATA_ATTR_LED_R                 @"attr2"    //属性：LED R值
#define DATA_ATTR_LED_G                 @"attr3"    //属性：LED G值
#define DATA_ATTR_LED_B                 @"attr4"    //属性：LED B值
#define DATA_ATTR_MOTORSPEED            @"attr5"    //属性：电机转速
#define DATA_ATTR_IR                    @"attr6"    //属性：红外探测
#define DATA_ATTR_TEMPERATURE           @"attr7"    //属性：温度
#define DATA_ATTR_HUMIDITY              @"attr8"    //属性：湿度

@interface IoTDeviceController ()
{
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
    NSTimer *remainTimer;
    NSMutableArray *updateCtrl;
}

@property (readonly, nonatomic) XPGWifiDevice *device;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (assign) BOOL isToasted;

@end

@implementation IoTDeviceController

- (id)initWithDevice:(XPGWifiDevice *)device
{
    self = [super init];
    if(self)
    {
        if(nil == device || !device.isConnected)
            return nil;
        
        _device = device;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:@"align"];
    image = [IoTAppDelegate imageWithImage:image scaledToSize:CGSizeMake(25, 20)];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(rightMenu)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //大循环判断设备是否在线
    if(!self.device.isOnline && !self.device.isLAN)
    {
        [_alertView dismissWithClickedButtonIndex:0 animated:YES];
        _alertView = [[UIAlertView alloc] initWithTitle:@"警告" message:@"设备不在线，你不可以控制设备，但你可以解除绑定信息。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [_alertView show];
        self.view.userInteractionEnabled = NO;
    }
    
    //初始化信息
    self.navigationItem.title = _device.productName;

    [XPGWifiSDK sharedInstance].delegate = self;
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
    if(!remainTimer)
        remainTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onRemainTimer) userInfo:nil repeats:YES];
    updateCtrl = [NSMutableArray array];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _device.delegate = nil;
    [XPGWifiSDK sharedInstance].delegate = nil;
    [remainTimer invalidate];
    remainTimer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if(nil == cell)
    {
        UINib *nib = nil;
        if([reuseIndentifer isEqualToString:slider_id])
            nib = [UINib nibWithNibName:@"IoTDeviceSliderCell" bundle:nil];
        else if([reuseIndentifer isEqualToString:label_id])
            nib = [UINib nibWithNibName:@"IoTDeviceLabelCell" bundle:nil];
        else if([reuseIndentifer isEqualToString:bool_id])
            nib = [UINib nibWithNibName:@"IoTDeviceBoolCell" bundle:nil];
        else if([reuseIndentifer isEqualToString:enum_id])
            nib = [UINib nibWithNibName:@"IoTDeviceEnumCell" bundle:nil];
        
        if(nib)
        {
            [tableView registerNib:nib forCellReuseIdentifier:reuseIndentifer];
            cell = [tableView dequeueReusableCellWithIdentifier:reuseIndentifer];
        }
    }
    
    if(!cell)
        return cell;
    
    switch (indexPath.row) {
        case 0:
        {
            IoTDeviceBoolCell *boolCell = (IoTDeviceBoolCell *)cell;
            boolCell.title = @"开启/关闭红色灯";
            boolCell.value = iLedR;
            boolCell.tag = indexPath.row;
            boolCell.delegate = self;
            break;
        }
        case 1:
        {
            IoTDeviceEnumCell *enumCell = (IoTDeviceEnumCell *)cell;
            enumCell.title = @"设定LED组合颜色";
            enumCell.values = @[@"自定义", @"黄色", @"紫色", @"粉色"];
            enumCell.index = iledColor;
            enumCell.tag = indexPath.row;
            enumCell.delegate = self;
            break;
        }
        case 2:
        {
            IoTDeviceSliderCell *sliderCell = (IoTDeviceSliderCell *)cell;
            sliderCell.title = @"设定LED颜色R值";
            sliderCell.min = 0;
            sliderCell.max = 254;
            sliderCell.value = fLedR;
            sliderCell.step = 1;
            sliderCell.tag = indexPath.row;
            sliderCell.delegate = self;
            sliderCell.userInteractionEnabled = bLedCtrl;
            break;
        }
        case 3:
        {
            IoTDeviceSliderCell *sliderCell = (IoTDeviceSliderCell *)cell;
            sliderCell.title = @"设定LED颜色G值";
            sliderCell.min = 0;
            sliderCell.max = 254;
            sliderCell.value = fLedG;
            sliderCell.step = 1;
            sliderCell.tag = indexPath.row;
            sliderCell.delegate = self;
            sliderCell.userInteractionEnabled = bLedCtrl;
            break;
        }
        case 4:
        {
            IoTDeviceSliderCell *sliderCell = (IoTDeviceSliderCell *)cell;
            sliderCell.title = @"设定LED颜色B值";
            sliderCell.min = 0;
            sliderCell.max = 254;
            sliderCell.value = fLedB;
            sliderCell.step = 1;
            sliderCell.tag = indexPath.row;
            sliderCell.delegate = self;
            sliderCell.userInteractionEnabled = bLedCtrl;
            break;
        }
        case 5:
        {
            IoTDeviceSliderCell *sliderCell = (IoTDeviceSliderCell *)cell;
            sliderCell.title = @"设定电机转速";
            sliderCell.min = -5;
            sliderCell.max = 5;
            sliderCell.value = fMonitorSpeed;
            sliderCell.step = 1;
            sliderCell.tag = indexPath.row;
            sliderCell.delegate = self;
            break;
        }
        case 6:
        {
            IoTDeviceBoolCell *boolCell = (IoTDeviceBoolCell *)cell;
            boolCell.title = @"红外探测";
            boolCell.value = iir;
            boolCell.tag = indexPath.row;
            boolCell.delegate = self;
            boolCell.userInteractionEnabled = NO;
            break;
        }
        case 7:
        {
            IoTDeviceLabelCell *sliderCell = (IoTDeviceLabelCell *)cell;
            sliderCell.title = @"温度";
            if(fTemperature < 0)
                sliderCell.value = @"-";
            else
                sliderCell.value = [NSString stringWithFormat:@"%@", @(fTemperature)];
            break;
        }
        case 8:
        {
            IoTDeviceLabelCell *sliderCell = (IoTDeviceLabelCell *)cell;
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

#pragma mark - Data Point
- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value
{
    NSDictionary *data = nil;
    switch (dataPoint) {
        case IoTDeviceWriteUpdateData:
            data = @{DATA_CMD: @(IoTDeviceCommandRead)};
            break;
        case IoTDeviceWriteLED_R_onOff:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_LED_R_ONOFF: value}};
            break;
        case IoTDeviceWriteLED_Color:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_LED_COLOR: value}};
            break;
        case IoTDeviceWriteLED_R:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_LED_R: value}};
            break;
        case IoTDeviceWriteLED_G:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_LED_G: value}};
            break;
        case IoTDeviceWriteLED_B:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_LED_B: value}};
            break;
        case IoTDeviceWriteMotorSpeed:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_MOTORSPEED: value}};
            break;
        default:
            NSLog(@"Error: write invalid datapoint, skip.");
            return;
    }
    
    NSLog(@"Write data: %@", data);
    [self.device write:data];
}

- (id)readDataPoint:(IoTDeviceDataPoint)dataPoint data:(NSDictionary *)data
{
    if(![data isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read data, error data format.");
        return nil;
    }
    
    NSNumber *nCommand = [data valueForKey:DATA_CMD];
    if(![nCommand isKindOfClass:[NSNumber class]])
    {
        NSLog(@"Error: could not read cmd, error cmd format.");
        return nil;
    }
    
    int nCmd = [nCommand intValue];
    if(nCmd != IoTDeviceCommandResponse && nCmd != IoTDeviceCommandNotify)
    {
        NSLog(@"Error: command is invalid, skip.");
        return nil;
    }
    
    NSDictionary *attributes = [data valueForKey:DATA_ENTITY];
    if(![attributes isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read attributes, error attributes format.");
        return nil;
    }
    
    switch (dataPoint) {
        case IoTDeviceWriteLED_R_onOff:
            return [attributes valueForKey:DATA_ATTR_LED_R_ONOFF];
        case IoTDeviceWriteLED_Color:
            return [attributes valueForKey:DATA_ATTR_LED_COLOR];
        case IoTDeviceWriteLED_R:
            return [attributes valueForKey:DATA_ATTR_LED_R];
        case IoTDeviceWriteLED_G:
            return [attributes valueForKey:DATA_ATTR_LED_G];
        case IoTDeviceWriteLED_B:
            return [attributes valueForKey:DATA_ATTR_LED_B];
        case IoTDeviceWriteMotorSpeed:
            return [attributes valueForKey:DATA_ATTR_MOTORSPEED];
        case IoTDeviceReadIR:
            return [attributes valueForKey:DATA_ATTR_IR];
        case IoTDeviceReadTemperature:
            return [attributes valueForKey:DATA_ATTR_TEMPERATURE];
        case IoTDeviceReadHumidity:
            return [attributes valueForKey:DATA_ATTR_HUMIDITY];
        default:
            NSLog(@"Error: read invalid datapoint, skip.");
            break;
    }
    return nil;
}

- (void)rightMenu
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"断开连接",@"解除绑定",@"获取设备状态",
                                  nil];
    actionSheet.tag = 1;
    [actionSheet showInView:self.view];
}

#pragma mark - Callbacks
- (void)IoTDeviceSliderDidUpdateValue:(IoTDeviceSliderCell *)cell value:(CGFloat)value
{
    switch (cell.tag) {
        case 2:
            fLedR = value;
            [self writeDataPoint:IoTDeviceWriteLED_R value:@(value)];
            [self addRemainElement:cell.tag];
            break;
        case 3:
            fLedG = value;
            [self writeDataPoint:IoTDeviceWriteLED_G value:@(value)];
            [self addRemainElement:cell.tag];
            break;
        case 4:
            fLedB = value;
            [self writeDataPoint:IoTDeviceWriteLED_B value:@(value)];
            [self addRemainElement:cell.tag];
            break;
        case 5:
            fMonitorSpeed = value;
            [self writeDataPoint:IoTDeviceWriteMotorSpeed value:@(value)];
            [self addRemainElement:cell.tag];
            break;
        default:
            return;
    }
    [self addRemainElement:cell.tag];
}

- (void)IoTDeviceSwitchDidUpdateValue:(IoTDeviceBoolCell *)cell value:(BOOL)value
{
    switch (cell.tag) {
        case 0:
            iLedR = value;
            [self writeDataPoint:IoTDeviceWriteLED_R_onOff value:@(value)];
            [self addRemainElement:cell.tag];
            break;
        default:
            break;
    }
}

- (void)IoTDeviceDidSelectedEnum:(IoTDeviceEnumCell *)cell
{
    IoTDeviceEnumSelection *selectController = [[IoTDeviceEnumSelection alloc] initWithEnumCell:cell];
    [self.navigationController pushViewController:selectController animated:YES];
}

- (void)IoTDeviceEnumDidSelectedValue:(IoTDeviceEnumCell *)cell index:(NSInteger)index
{
    switch (cell.tag) {
        case 1:
            iledColor = index;
            [self writeDataPoint:IoTDeviceWriteLED_Color value:@(index)];
            [self addRemainElement:cell.tag];
            break;
        default:
            break;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case 1://控制页面
        {
            switch (buttonIndex) {
                case 0:
                    //断开链接
                    [self popViewController];
                    break;
                case 1:
                {
                    //解绑
                    MBProgressHUD *hud = AppDelegate.hud;
                    hud.labelText = @"与服务器解除绑定...";
                    [hud show:YES];
                    [[XPGWifiSDK sharedInstance] unbindDeviceWithUid:AppDelegate.uid token:AppDelegate.token did:self.device.did passCode:nil];
                    break;
                }
                case 2:
                {
                    //更新数据
                    [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (CGFloat)prepareForUpdateFloatRows:(NSString *)str value:(CGFloat)value rows:(NSMutableArray *)rows index:(NSInteger)index
{
    if([self isElementRemaining:index])
        return value;
    
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        CGFloat newValue = [str floatValue];
        if(newValue != value)
        {
            value = newValue;
            [rows addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }
    return value;
}

- (NSInteger)prepareForUpdateIntegerRows:(NSString *)str value:(NSInteger)value rows:(NSMutableArray *)rows index:(NSInteger)index
{
    if([self isElementRemaining:index])
        return value;
    
    if([str isKindOfClass:[NSNumber class]] ||
        ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        NSInteger newValue = [str integerValue];
        if(newValue != value)
        {
            value = newValue;
            [rows addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }
    return value;
}

- (BOOL)XPGWifiDevice:(XPGWifiDevice *)device didReceiveData:(NSDictionary *)data result:(int)result
{
    /**
     * 数据部分
     */
    NSDictionary *_data = [data valueForKey:@"data"];
    
    NSString *ledRonOff = [self readDataPoint:IoTDeviceWriteLED_R_onOff data:_data];
    NSString *ledColor = [self readDataPoint:IoTDeviceWriteLED_Color data:_data];
    NSString *ledR = [self readDataPoint:IoTDeviceWriteLED_R data:_data];
    NSString *ledG = [self readDataPoint:IoTDeviceWriteLED_G data:_data];
    NSString *ledB = [self readDataPoint:IoTDeviceWriteLED_B data:_data];
    NSString *motorSpeed = [self readDataPoint:IoTDeviceWriteMotorSpeed data:_data];
    NSString *ir = [self readDataPoint:IoTDeviceReadIR data:_data];
    NSString *temperature = [self readDataPoint:IoTDeviceReadTemperature data:_data];
    NSString *humidity = [self readDataPoint:IoTDeviceReadHumidity data:_data];
    
    NSMutableArray *rows = [NSMutableArray array];
    
    iLedR = [self prepareForUpdateIntegerRows:ledRonOff value:iLedR rows:rows index:0];
    iledColor = [self prepareForUpdateIntegerRows:ledColor value:iledColor rows:rows index:1];
    
    fLedR = [self prepareForUpdateFloatRows:ledR value:fLedR rows:rows index:2];
    fLedG = [self prepareForUpdateFloatRows:ledG value:fLedG rows:rows index:3];
    fLedB = [self prepareForUpdateFloatRows:ledB value:fLedB rows:rows index:4];
    
    fMonitorSpeed = [self prepareForUpdateFloatRows:motorSpeed value:fMonitorSpeed rows:rows index:5];
    iir = [self prepareForUpdateIntegerRows:ir value:iir rows:rows index:6];
    fTemperature = [self prepareForUpdateFloatRows:temperature value:fTemperature rows:rows index:7] + 13;//y=x+13
    fHumidity = [self prepareForUpdateFloatRows:humidity value:fHumidity rows:rows index:8];
    
    if(rows.count > 0)
        [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationNone];
    
    // 如果 LED 组合颜色不是自定义，则 LED 不可控制
    if(iledColor > 0)
        [self setCustomLEDMode:NO];
    else
        [self setCustomLEDMode:YES];
    
    /**
     * 报警和错误
     */
    if([self.navigationController.viewControllers lastObject] != self ||
       self.isToasted)
        return YES;
    
    NSString *str = @"";
    NSArray *alerts = [data valueForKey:@"alerts"];
    NSArray *faults = [data valueForKey:@"faults"];
    
    if(alerts.count == 0 && faults.count == 0)
        return YES;
    
    if(alerts.count > 0)
    {
        str = @"设备报警：";
        for(NSDictionary *dict in alerts)
        {
            for(NSString *name in dict.allKeys)
            {
                if(str.length > 0)
                    str = [str stringByAppendingString:@"\n"];
                NSNumber *value = [dict valueForKey:name];
                NSString *alert = [NSString stringWithFormat:@"%@ 错误码：%@", name, value];
                str = [str stringByAppendingString:alert];
            }
        }
    }
    
    if(faults.count > 0)
    {
        if(str.length > 0)
            str = [str stringByAppendingString:@"\n"];
        str = [str stringByAppendingString:@"设备错误："];
        
        for(NSDictionary *dict in faults)
        {
            for(NSString *name in dict.allKeys)
            {
                if(str.length > 0)
                    str = [str stringByAppendingString:@"\n"];
                NSNumber *value = [dict valueForKey:name];
                NSString *fault = [NSString stringWithFormat:@"%@ 错误码：%@", name, value];
                str = [str stringByAppendingString:fault];
            }
        }
    }
    
    [self performSelectorInBackground:@selector(toast:) withObject:str];
    
    return YES;
}

- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device
{
    if(AppDelegate.hud.alpha == 0)
    {
        [_alertView dismissWithClickedButtonIndex:0 animated:YES];
        _alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"连接已断开" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [_alertView show];
        [self performSelector:@selector(popViewController) withObject:nil afterDelay:0.5];
    }
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUnbindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    if([self.device.did isEqualToString:did])
    {
        //为了防止解除绑定和断开连接的时间冲突，先把 device.delegate 赋空
        self.device.delegate = nil;
        
        //处理解绑事件
        [AppDelegate.hud hide:YES];
        NSDictionary *params = ([error intValue] == 0)?
        @{@"title": @"已成功解除绑定",
          @"delegate": self}:
        @{@"title": @"解除绑定失败"};
        [[[UIAlertView alloc] initWithTitle:[params valueForKey:@"title"] message:@"" delegate:[params valueForKey:@"delegate"] cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
        [self performSelector:@selector(popViewController) withObject:nil afterDelay:0.5];
    }
}

#pragma mark - others
- (void)setCustomLEDMode:(BOOL)mode
{
    //设置 LED 的 RGB 值是否可用
    bLedCtrl = mode;
    NSArray *leds = @[[NSIndexPath indexPathForRow:2 inSection:0],
                      [NSIndexPath indexPathForRow:3 inSection:0],
                      [NSIndexPath indexPathForRow:4 inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:leds withRowAnimation:UITableViewRowAnimationNone];
}

- (void)toast:(NSString *)strToast
{
    //弹出一段字符，最多不超过3行
    self.isToasted = YES;
    iToast *toast = [iToast makeText:strToast];
    [toast performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    sleep(3);
    self.isToasted = NO;
}

- (void)popViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 发控制指令后一段时间内禁止推送
- (void)addRemainElement:(NSInteger)row
{
    BOOL isEqual = NO;
    NSNumber *timeout = @3;    // 发控制指令后，等待3s后才可接收指定控件的变更
    
    for(NSMutableDictionary *dict in updateCtrl)
    {
        NSNumber *object = [dict valueForKey:@"object"];
        if([object intValue] == row)
        {
            [dict setValue:timeout forKey:@"remaining"];
            isEqual = YES;
            break;
        }
    }
    
    if(!isEqual)
    {
        NSMutableDictionary *mdict = [NSMutableDictionary dictionaryWithDictionary:@{@"object": @(row), @"remaining": timeout}];
        [updateCtrl addObject:mdict];
    }
}

- (void)onRemainTimer
{
    //根据系统的 Timer 去更新控件可以变更的剩余时间
    NSMutableArray *removeCtrl = [NSMutableArray array];
    for(NSMutableDictionary *dict in updateCtrl)
    {
        int remainTime = [[dict valueForKey:@"remaining"] intValue] - 1;
        if(remainTime != 0)
            [dict setValue:@(remainTime) forKey:@"remaining"];
        else
            [removeCtrl addObject:dict];
    }
    [updateCtrl removeObjectsInArray:removeCtrl];
}

- (BOOL)isElementRemaining:(NSInteger)row
{
    //判断某个控件是否能更新内容
    for(NSMutableDictionary *dict in updateCtrl)
    {
        NSNumber *object = [dict valueForKey:@"object"];
        if([object intValue] == row)
            return YES;
    }
    return NO;
}

@end
