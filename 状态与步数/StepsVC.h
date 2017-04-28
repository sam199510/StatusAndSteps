//
//  StepsVC.h
//  状态与步数
//
//  Created by 飞 on 2017/4/26.
//  Copyright © 2017年 Sam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>

@interface StepsVC : UIViewController<UITextFieldDelegate>

@property (strong, nonatomic) HKHealthStore *healthStore;

@end
