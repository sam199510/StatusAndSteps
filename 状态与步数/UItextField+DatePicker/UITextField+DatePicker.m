//
//  UITextField+DatePicker.m
//  studentInfo
//
//  Created by Expero on 2016/12/24.
//  Copyright © 2016年 Expero. All rights reserved.
//

#import "UITextField+DatePicker.h"

@implementation UITextField (DatePicker)
// 1
+ (UIDatePicker *)sharedDatePicker;
{
    static UIDatePicker *daterPicker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        daterPicker = [[UIDatePicker alloc] init];
        daterPicker.datePickerMode = UIDatePickerModeDate;
    });
    
    return daterPicker;
}

// 2
- (void)datePickerValueChanged:(UIDatePicker *)sender
{
    if (self.isFirstResponder)
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        self.text = [formatter stringFromDate:sender.date];
    }
}

// 3
- (void)setDatePickerInput:(BOOL)datePickerInput
{
    if (datePickerInput)
    {
        self.inputView = [UITextField sharedDatePicker];
        [[UITextField sharedDatePicker] addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    else
    {
        self.inputView = nil;
        [[UITextField sharedDatePicker] removeTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
}

// 4
- (BOOL)datePickerInput
{
    return [self.inputView isKindOfClass:[UIDatePicker class]];
}

@end
