//
//  StatusVC.m
//  状态与步数
//
//  Created by 飞 on 2017/4/26.
//  Copyright © 2017年 Sam. All rights reserved.
//

#import "StatusVC.h"
#import <CoreMotion/CoreMotion.h>

#define JD 0.1
#define JSD 0.005

@interface StatusVC ()

{
    NSTimer *_updateTimer;
}

@property (strong, nonatomic) CMMotionManager *motionManager;

@property (strong, nonatomic) IBOutlet UILabel *xAxle;
@property (strong, nonatomic) IBOutlet UILabel *yAxle;
@property (strong, nonatomic) IBOutlet UILabel *zAxle;

@property (strong, nonatomic) IBOutlet UILabel *leftRight;
@property (strong, nonatomic) IBOutlet UILabel *frontBack;
@property (strong, nonatomic) IBOutlet UILabel *upDown;

@end

@implementation StatusVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //创建CMotionManager对象
    self.motionManager = [[CMMotionManager alloc] init];
    
    //判断motionManager是否支持陀螺仪
    if (self.motionManager.gyroAvailable) {
        [self.motionManager startGyroUpdates];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"此设备不支持陀螺仪" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil];
        [alertView show];
    }
    
    //判断是否支持移动
    if (self.motionManager.deviceMotionAvailable) {
        [self.motionManager startDeviceMotionUpdates];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"此设备不支持位置变化装置" delegate:self cancelButtonTitle:@"好" otherButtonTitles: nil];
        [alertView show];
    }
    
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


-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_updateTimer) {
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateData) userInfo:nil repeats:YES];
    }
}


-(void) updateData {
    //若陀螺仪可用
    if (self.motionManager.gyroAvailable) {
        //主动请求陀螺仪数据
        CMGyroData *gyroData = self.motionManager.gyroData;
        
        float x = gyroData.rotationRate.x;
        float y = gyroData.rotationRate.y;
        float z = gyroData.rotationRate.z;
        
        if (x > JD) {
            self.xAxle.text = @"手机抬起";
        } else if (x < -JD) {
            self.xAxle.text = @"手机放下";
        } else {
            self.xAxle.text = @"该方向静止";
        }
        
        if (y > JD) {
            self.yAxle.text = @"左侧抬起";
        } else if (y < -JD) {
            self.yAxle.text = @"右侧抬起";
        } else {
            self.yAxle.text = @"该方向静止";
        }
        
        if (z > JD) {
            self.zAxle.text = @"逆时针旋转";
        } else if (z < -JD) {
            self.zAxle.text = @"顺时针旋转";
        } else {
            self.zAxle.text = @"该方向静止";
        }
    }
    
    //若加速器可用
    if (self.motionManager.deviceMotionAvailable) {
        //主动请求获取加速器
        CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
        
        float x = deviceMotion.userAcceleration.x;
        float y = deviceMotion.userAcceleration.y;
        float z = deviceMotion.userAcceleration.z;
        
        if (x > JSD) {
            self.leftRight.text = @"向右移动";
        } else if (x < -JSD){
            self.leftRight.text = @"向左移动";
        } else {
            self.leftRight.text = @"该方向无移动";
        }
        
        if (y > JSD) {
            self.frontBack.text = @"向前移动";
        } else if (y < -JSD) {
            self.frontBack.text = @"向后移动";
        } else {
            self.frontBack.text = @"该方向无移动";
        }
        
        if (z > JSD) {
            self.upDown.text = @"向上移动";
        } else if (z < -JSD) {
            self.upDown.text = @"向下移动";
        } else {
            self.upDown.text = @"该方向无移动";
        }
        
        //self.leftRight.text = [NSString stringWithFormat:@"%.3f",x];
    }
}

@end
