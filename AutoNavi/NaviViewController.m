//
//  NaviViewController.m
//  AutoNavi
//
//  Created by YYQ on 16/5/12.
//  Copyright © 2016年 YYQ. All rights reserved.
//

#import "NaviViewController.h"
#import "NaviViewController.h"
#import <MapKit/MapKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>
//#import <MAMapKit/MAMapKit.h>
#import <AMapNaviKit/AMapNaviKit.h>
#import <AMapNaviKit/MAMapKit.h>
#import "iflyMSC/IFlySpeechError.h"
#import "iflyMSC/IFlySpeechSynthesizer.h"
#import "iflyMSC/IFlySpeechSynthesizerDelegate.h"
#import <AudioToolbox/AudioToolbox.h>

@interface NaviViewController ()<AMapNaviViewControllerDelegate,AMapNaviManagerDelegate,IFlySpeechSynthesizerDelegate>

@property (nonatomic, strong) AMapNaviViewController *naviViewController;
@property (nonatomic, strong) AMapNaviManager *naviManager;
@property (nonatomic, strong) IFlySpeechSynthesizer *iFlySpeechSynthesizer;

@end

@implementation NaviViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *arr = @[@"to map",@"百度导航(外)",@"百度导航(内)",@"高德地图(外)",@"高德地图(内)",@"to apple"];
    [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(10, 100 + idx * (44 + 20), 150, 44)];
        [btn setTag:idx + 1000];
        [btn setBackgroundColor:[UIColor lightGrayColor]];
        [btn setTitle:arr[idx] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        
    }];
    
    
    [self initNaviManager];
    [self initIFlySpeech];
    [self initNaviViewController];
}
- (void)initNaviManager
{
    if (self.naviManager == nil)
    {
        self.naviManager = [[AMapNaviManager alloc] init];
    }
    
    [self.naviManager setDelegate:self];
}
- (void)initIFlySpeech
{
    if (self.iFlySpeechSynthesizer == nil)
    {
        _iFlySpeechSynthesizer = [IFlySpeechSynthesizer sharedInstance];
    }
    
    _iFlySpeechSynthesizer.delegate = self;
}
- (void)initNaviViewController
{
    [AMapNaviServices sharedServices].apiKey = @"381ca4efa250b1f3c0cb5d988e46528b";
    if (self.naviViewController == nil)
    {
        self.naviViewController = [[AMapNaviViewController alloc] initWithDelegate:self];
    }
    [self.naviViewController setDelegate:self];
}
- (void)btnClick:(UIButton *)btn{
    NSInteger index = btn.tag - 1000;
    CLLocation *targetLocation = [[CLLocation alloc]initWithLatitude:[@"40.220248" doubleValue] longitude:[@"116.233538" doubleValue]];
    //[BaiduLocation sharedInstance].currentLocation;
    if (index == 0) {
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"xianyiwangApp://"]]) {
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"xianyiwangApp://"]];
        }
    }else if (index == 1){
        //        百度地图
        CLLocationCoordinate2D coor = targetLocation.coordinate;//原始坐标
        NSDictionary* testdic = BMKConvertBaiduCoorFrom(coor,BMK_COORDTYPE_COMMON);
        testdic = BMKConvertBaiduCoorFrom(coor,BMK_COORDTYPE_GPS);
        CLLocationCoordinate2D coordinate = BMKCoorDictionaryDecode(testdic);//转换后的百度坐标
        NSString *urlString = [[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=北京西站&mode=driving&coord_type=bd09ll",coordinate.latitude, coordinate.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }else{
            NaviViewController *naviVC = [NaviViewController new];
            [self.navigationController pushViewController:naviVC animated:YES];
        }
    }else if (index == 2){
        //            应用内导航
        NaviViewController *naviVC = [NaviViewController new];
        [self.navigationController pushViewController:naviVC animated:YES];
        
    }else if (index == 3){
        NSLog(@"高德导航");
        NSString *urlScheme = @"foo4://";
        NSString *appName = @"我的应用";
        CLLocationCoordinate2D coordinate = MACoordinateConvert(CLLocationCoordinate2DMake(targetLocation.coordinate.latitude,targetLocation.coordinate.longitude),MACoordinateTypeGPS);
        NSString *urlString = [[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2",appName,urlScheme,coordinate.latitude, coordinate.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }else{
            NSLog(@"没有安装高德地图客户端");
        }
    }else if (index == 4){
        CLLocationCoordinate2D coordinate = MACoordinateConvert(CLLocationCoordinate2DMake(targetLocation.coordinate.latitude,targetLocation.coordinate.longitude),MACoordinateTypeGPS);
        NSArray *endPoints = @[[AMapNaviPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude]];
        [self.naviManager calculateDriveRouteWithEndPoints:endPoints wayPoints:nil drivingStrategy:0];
        
    }else if (index == 5){
        NSLog(@"苹果自带地图导航 使用高德地图的坐标系统");
        CLLocationCoordinate2D coordinate = MACoordinateConvert(CLLocationCoordinate2DMake(targetLocation.coordinate.latitude,targetLocation.coordinate.longitude),MACoordinateTypeGPS);
        MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
        MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil]];
        [MKMapItem openMapsWithItems:@[currentLocation, toLocation]
                       launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                                       MKLaunchOptionsShowsTrafficKey: [NSNumber numberWithBool:YES]}];
    }
    
}
//- (void)calculateRoute
//{
//    NSArray *endPoints = @[[AMapNaviPoint ]];
//
//    [self.naviManager calculateDriveRouteWithEndPoints:endPoints wayPoints:nil drivingStrategy:0];
//}

//路径规划成功
- (void)naviManagerOnCalculateRouteSuccess:(AMapNaviManager *)naviManager
{
    NSLog(@"OnCalculateRouteSuccess");
    
    if (self.naviViewController == nil)
    {
        [self initNaviViewController];
    }
    
    [self.naviManager presentNaviViewController:self.naviViewController animated:YES];
}

#pragma mark -语音
- (void)naviManager:(AMapNaviManager *)naviManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    if (soundStringType == AMapNaviSoundTypePassedReminder)
    {
        //用系统自带的声音做简单例子，播放其他提示音需要另外配置
        AudioServicesPlaySystemSound(1009);
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [_iFlySpeechSynthesizer startSpeaking:soundString];
        });
    }
}

- (void)naviManagerDidUpdateTrafficStatuses:(AMapNaviManager *)naviManager
{
    NSLog(@"DidUpdateTrafficStatuses");
}

#pragma mark - AManNaviViewController Delegate

- (void)naviViewControllerCloseButtonClicked:(AMapNaviViewController *)naviViewController
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_iFlySpeechSynthesizer stopSpeaking];
    });
    
    [self.naviManager stopNavi];
    
    [self.naviManager dismissNaviViewControllerAnimated:YES];
}

- (void)naviViewControllerMoreButtonClicked:(AMapNaviViewController *)naviViewController
{
    if (self.naviViewController.viewShowMode == AMapNaviViewShowModeCarNorthDirection)
    {
        self.naviViewController.viewShowMode = AMapNaviViewShowModeMapNorthDirection;
    }
    else
    {
        self.naviViewController.viewShowMode = AMapNaviViewShowModeCarNorthDirection;
    }
}

- (void)naviViewControllerTurnIndicatorViewTapped:(AMapNaviViewController *)naviViewController
{
    [self.naviManager readNaviInfoManual];
}

#pragma mark - iFlySpeechSynthesizer Delegate

- (void)onCompleted:(IFlySpeechError *)error
{
    NSLog(@"Speak Error:{%d:%@}", error.errorCode, error.errorDesc);
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self newAlertViewController];
    //1. 检查版本
    if ([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
        [self inputUserinfo];
        return;
    }
    
    //2. 检查是否支持指纹识别
    LAContext *context = [[LAContext alloc] init];
    /** 这个属性用来设置指纹错误后的弹出框的按钮文字
     *  不设置默认文字为“输入密码”
     *  设置@""将不会显示指纹错误后的弹出框
     */
    context.localizedFallbackTitle = @"验证密码";
    
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:NULL])
    {
        NSLog(@"支持指纹识别");
        
        // 异步输入指纹
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"购买" reply:^(BOOL success, NSError *error) {
            NSLog(@"%d \n%@ \n%@ \n\n %ld", success, error, [NSThread currentThread], error.code);
            if (success)
            {
                [self purchase];
                NSLog(@"恭喜您购物成功！");
            }
            else if (error.code == LAErrorAppCancel)
            {
                NSLog(@"失败 LAErrorAppCancel %ld", LAErrorAppCancel);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self inputUserinfo];
                });
            }else if (error.code == LAErrorUserCancel)
            {
                NSLog(@"失败 LAErrorUserCancel %ld", error.code);
            }else if (error.code == LAErrorSystemCancel)
            {
                NSLog(@"失败 LAErrorSystemCancel %ld", error.code);
            }else if (error.code == LAErrorUserFallback)
            {
                NSLog(@"失败 LAErrorUserFallback %ld", error.code);
            }else if (error.code == LAErrorInvalidContext)
            {
                NSLog(@"失败 LAErrorInvalidContext %ld", error.code);
            }else if (error.code == LAErrorPasscodeNotSet)
            {
                NSLog(@"失败 LAErrorPasscodeNotSet %ld", error.code);
            }else if (error.code == LAErrorTouchIDLockout)
            {
                NSLog(@"失败 LAErrorTouchIDLockout %ld", error.code);
            }else if (error.code == LAErrorTouchIDNotEnrolled)
            {
                NSLog(@"失败 LAErrorTouchIDNotEnrolled %ld", error.code);
            }else if (error.code == LAErrorTouchIDNotAvailable)
            {
                NSLog(@"失败 LAErrorTouchIDNotAvailable %ld", error.code);
            }else if (error.code == LAErrorAuthenticationFailed)
            {
                NSLog(@"失败 LAErrorAuthenticationFailed %ld", error.code);
            }
            
        }];
    } else {
        [self inputUserinfo];
    }
}

///  输入用户信息
- (void)inputUserinfo
{
    //    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"cancel" message:@"purchase" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"purchase", nil];
    //    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    //
    //    [alertView show];
}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    NSLog(@"%zd", buttonIndex);
//
//    if (buttonIndex == 0)
//    {
//        return;
//    }
//
//    UITextField *usernameText = [alertView textFieldAtIndex:0];
//    UITextField *pwdText = [alertView textFieldAtIndex:1];
//
//    if ([usernameText.text isEqualToString:@"zhang"] && [pwdText.text isEqualToString:@"123"])
//    {
//        [self purchase];
//    }
//    else
//    {
//        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"用户名或密码错误" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil] show];
//    }
//}

///  购买
- (void)purchase
{
    NSLog(@"购买");
}

-(void)newAlertViewController{
    UIAlertController *alterC = [UIAlertController alertControllerWithTitle:@"title" message:@"alert message" preferredStyle:UIAlertControllerStyleAlert];
    [alterC addAction:[UIAlertAction actionWithTitle:@"定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction*action) {
        NSLog(@"点击了确定按钮");
    }]];
    [alterC addAction:[UIAlertAction actionWithTitle:@"消"style:UIAlertActionStyleCancel handler:^(UIAlertAction*action) {
        NSLog(@"点击了取消按钮");
    }]];
    //    [alterC addAction:[UIAlertAction actionWithTitle:@"消2"style:UIAlertActionStyleDefault handler:^(UIAlertAction*action) {
    //        NSLog(@"点击了取消按钮2");
    //    }]];
    [self presentViewController:alterC animated:YES completion:^{
        
    }];
    
}



@end
