//
//  UITextField+DatePicker.h
//  studentInfo
//
//  Created by Expero on 2016/12/24.
//  Copyright © 2016年 Expero. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (DatePicker)
@property (nonatomic, assign) BOOL datePickerInput;

+ (UIDatePicker *)sharedDatePicker;
@end
