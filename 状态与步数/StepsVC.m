//
//  StepsVC.m
//  状态与步数
//
//  Created by 飞 on 2017/4/26.
//  Copyright © 2017年 Sam. All rights reserved.
//

#import "StepsVC.h"
#import "UITextField+DatePicker.h"
#import "FMDatabase.h"

@interface StepsVC ()

{
    NSInteger _startCount;
    NSInteger _endCount;
    NSInteger _difCountOfStartStepAndEndStep;
    
    //设定数据库模型
    FMDatabase *_mDB;
}

@property (strong, nonatomic) IBOutlet UILabel *txtNumberOfSteps;
@property (strong, nonatomic) IBOutlet UITextField *txtSelectDate;
@property (strong, nonatomic) IBOutlet UILabel *txtQueryResult;

- (IBAction)startRecord:(id)sender;
- (IBAction)stopRecord:(id)sender;
- (IBAction)btnSelectStepCount:(id)sender;

@end

@implementation StepsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //键盘收回
    self.view.userInteractionEnabled = YES;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fingetTap:)];
    [self.view addGestureRecognizer:singleTap];
    
    //获取屏幕宽度
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    //定义一个toolBar
    UIToolbar *toolBar=[[UIToolbar alloc] init];
    toolBar.frame=CGRectMake(0, 0, width, 38);
    UIBarButtonItem *cancelBtn=[[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(pressCancel:)];
    UIBarButtonItem *spaceBtn=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *configBtn=[[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(pressCancel:)];
    toolBar.items=@[cancelBtn,spaceBtn,configBtn];
    
    //查询文本框
    _txtSelectDate.clearButtonMode = UITextFieldViewModeWhileEditing;
    _txtSelectDate.delegate = self;
    _txtSelectDate.datePickerInput = YES;
    _txtSelectDate.inputAccessoryView = toolBar;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    //获取权限
    [self getGrant];
    [self createDB];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)btnSelectStepCount:(id)sender {
    [self selectDB];
}

- (IBAction)startRecord:(id)sender {
    [self readStartStepCount];
}


- (IBAction)stopRecord:(id)sender {
    [self readEndStepCount];
}


//键盘收回
-(void) fingetTap:(UITapGestureRecognizer *)gestureRecognizer{
    [self.view endEditing:YES];
}


//定义取消事件
-(void)pressCancel:(UITapGestureRecognizer *)gestureRecognizer{
    [self fingetTap:gestureRecognizer];
}


-(void) getGrant{
    //查看该设备上是否支持HealthKit
    if (![HKHealthStore isHealthDataAvailable]) {
        self.txtNumberOfSteps.text = @"此设备不支持HealthKit";
    }
    
    //创建healthStore对象
    self.healthStore = [[HKHealthStore alloc] init];
    //设置需要获取的权限 仅设置了步数
    HKObjectType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSSet *healthSet = [NSSet setWithObjects:stepType, nil];
    
    //从健康应用中获取权限
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [self readStepCount];
        } else {
            self.txtNumberOfSteps.text = @"获取步数权限失败";
        }
    }];
}


-(void) readStepCount {
    //查询采样信息
    HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    //NSSortDescription告诉healthStore如何将结束排序
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    //获取当前时间
    NSDate *now = [NSDate date];
    NSCalendar *calender = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponent = [calender components:unitFlags fromDate:now];
    NSInteger hour = [dateComponent hour];
    NSInteger minute = [dateComponent minute];
    NSInteger second = [dateComponent second];
    NSDate *nowDay = [NSDate dateWithTimeIntervalSinceNow: -(hour*3600 + minute*60 + second)];
    //时间结果与想象中的不同是因为它显示的是0区
    NSDate *nextDay = [NSDate dateWithTimeIntervalSinceNow: -(hour*3600 + minute*60 + second) + 86400];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:nowDay endDate:nextDay options:(HKQueryOptionNone)];
    
    /*查询的基类是HKQuery，这是一个抽象类，能够实现每一种查询目标，这里我们需要查询的步数是一个HKSample类所以对应的查询类是HKSampleQuery。下面的limit参数传1表示查询最近一条数据，查询多条数据只要设置limit的参数值就可以了*/
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:0 sortDescriptors:@[start, end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        //设置一个int变量来作为步数统计
        int allStepCount = 0;
        for (int i = 0; i < results.count; i++) {
            //把结果转换为字符串类型
            HKQuantitySample *result = results[i];
            HKQuantity *quantity = result.quantity;
            NSMutableString *stepCount = (NSMutableString *)quantity;
            NSString *stepStr = [NSString stringWithFormat:@"%@", stepCount];
            //获取count此类字符串前面的数字
            NSString *str = [stepStr componentsSeparatedByString:@" "][0];
            int stepNum = [str intValue];
            //把一天中所有时间段中的步数加到一起
            allStepCount = allStepCount + stepNum;
        }
        
        //查询要放在多线程中进行，如果要对UI进行刷新，要回到主线程
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.txtNumberOfSteps.text = [NSString stringWithFormat:@"%d步", allStepCount];
        }];
    }];
    
    //执行查询
    [self.healthStore executeQuery:sampleQuery];
}


-(void) readStartStepCount {
    //查询采样信息
    HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    //NSSortDescription告诉healthStore如何将结束排序
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    //获取当前时间
    NSDate *now = [NSDate date];
    NSCalendar *calender = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponent = [calender components:unitFlags fromDate:now];
    NSInteger hour = [dateComponent hour];
    NSInteger minute = [dateComponent minute];
    NSInteger second = [dateComponent second];
    NSDate *nowDay = [NSDate dateWithTimeIntervalSinceNow: -(hour*3600 + minute*60 + second)];
    //时间结果与想象中的不同是因为它显示的是0区
    NSDate *nextDay = [NSDate dateWithTimeIntervalSinceNow: -(hour*3600 + minute*60 + second) + 86400];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:nowDay endDate:nextDay options:(HKQueryOptionNone)];
    
    /*查询的基类是HKQuery，这是一个抽象类，能够实现每一种查询目标，这里我们需要查询的步数是一个HKSample类所以对应的查询类是HKSampleQuery。下面的limit参数传1表示查询最近一条数据，查询多条数据只要设置limit的参数值就可以了*/
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:0 sortDescriptors:@[start, end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        //设置一个int变量来作为步数统计
        int allStepCount = 0;
        for (int i = 0; i < results.count; i++) {
            //把结果转换为字符串类型
            HKQuantitySample *result = results[i];
            HKQuantity *quantity = result.quantity;
            NSMutableString *stepCount = (NSMutableString *)quantity;
            NSString *stepStr = [NSString stringWithFormat:@"%@", stepCount];
            //获取count此类字符串前面的数字
            NSString *str = [stepStr componentsSeparatedByString:@" "][0];
            int stepNum = [str intValue];
            //把一天中所有时间段中的步数加到一起
            allStepCount = allStepCount + stepNum;
        }
        
        _startCount = allStepCount;
        
        //查询要放在多线程中进行，如果要对UI进行刷新，要回到主线程
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.txtNumberOfSteps.text = [NSString stringWithFormat:@"%d步", allStepCount];
        }];
    }];
    
    //执行查询
    [self.healthStore executeQuery:sampleQuery];
}


-(void) readEndStepCount {
    //查询采样信息
    HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    //NSSortDescription告诉healthStore如何将结束排序
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    //获取当前时间
    NSDate *now = [NSDate date];
    NSCalendar *calender = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponent = [calender components:unitFlags fromDate:now];
    NSInteger hour = [dateComponent hour];
    NSInteger minute = [dateComponent minute];
    NSInteger second = [dateComponent second];
    NSDate *nowDay = [NSDate dateWithTimeIntervalSinceNow: -(hour*3600 + minute*60 + second)];
    //时间结果与想象中的不同是因为它显示的是0区
    NSDate *nextDay = [NSDate dateWithTimeIntervalSinceNow: -(hour*3600 + minute*60 + second) + 86400];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:nowDay endDate:nextDay options:(HKQueryOptionNone)];
    
    /*查询的基类是HKQuery，这是一个抽象类，能够实现每一种查询目标，这里我们需要查询的步数是一个HKSample类所以对应的查询类是HKSampleQuery。下面的limit参数传1表示查询最近一条数据，查询多条数据只要设置limit的参数值就可以了*/
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:0 sortDescriptors:@[start, end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        //设置一个int变量来作为步数统计
        int allStepCount = 0;
        for (int i = 0; i < results.count; i++) {
            //把结果转换为字符串类型
            HKQuantitySample *result = results[i];
            HKQuantity *quantity = result.quantity;
            NSMutableString *stepCount = (NSMutableString *)quantity;
            NSString *stepStr = [NSString stringWithFormat:@"%@", stepCount];
            //获取count此类字符串前面的数字
            NSString *str = [stepStr componentsSeparatedByString:@" "][0];
            int stepNum = [str intValue];
            //把一天中所有时间段中的步数加到一起
            allStepCount = allStepCount + stepNum;
        }
        
        _endCount = allStepCount;
        
        [self countDif];
        
        //查询要放在多线程中进行，如果要对UI进行刷新，要回到主线程
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.txtNumberOfSteps.text = [NSString stringWithFormat:@"%d步", allStepCount];
        }];
    }];
    
    //执行查询
    [self.healthStore executeQuery:sampleQuery];
}


-(void) countDif{
    _difCountOfStartStepAndEndStep = _endCount - _startCount;
    [self insertDB:_difCountOfStartStepAndEndStep];
}


-(void)createDB{
    //        NSHomeDirectory()：获取手机APP的沙盒路径
    NSString *strPath=[NSHomeDirectory() stringByAppendingString:@"/Documents/db01.db"];
    //        创建并且打开数据库，如果路径下面没有数据库，创建指定的数据库，如果路径下已经存在数据库，加载数据库到内存
    _mDB=[FMDatabase databaseWithPath:strPath];
    
    if (_mDB!=nil) {
        NSLog(@"数据库创建成功");
    }
    
    BOOL isOpen=[_mDB open];
    
    if (isOpen) {
        NSLog(@"打开数据库成功");
    }
    
    //        创建一个字符串，将SQL创建语句写到字符串中
    NSString *strCreateTable=@"create table if not exists health(stepNum integer,stepDate varchar(12));";
    
    //        执行SQL语句，SQL有效才能执行成功，如果执行成功，返回一个有效值YES，如果失败，则为NO
    BOOL isCreate = [_mDB executeUpdate:strCreateTable];
    
    if (isCreate==YES) {
        NSLog(@"创建数据表成功");
    }
    
    BOOL isClose=[_mDB close];
    
    if (isClose) {
        NSLog(@"关闭数据库成功");
    }
}


-(void) insertDB:(NSInteger) difCount {
    
    NSString *strPath=[NSHomeDirectory() stringByAppendingString:@"/Documents/db01.db"];
    //        创建并且打开数据库，如果路径下面没有数据库，创建指定的数据库，如果路径下已经存在数据库，加载数据库到内存
    _mDB=[FMDatabase databaseWithPath:strPath];
    
    //        确保数据库被加载
    if (_mDB!=nil) {
        //            打开数据库
        if ([_mDB open]) {
            
            NSDate *now = [NSDate date];
            NSCalendar *calender = [NSCalendar currentCalendar];
            NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
            NSDateComponents *dateComponent = [calender components:unitFlags fromDate:now];
            
            NSInteger year = [dateComponent year];
            NSInteger month = [dateComponent month];
            NSInteger day = [dateComponent day];
            
            NSString *strMonth = [NSString stringWithFormat:@"%ld", month];
            NSString *strDay = [NSString stringWithFormat:@"%ld", day];
            
            NSString *strDate;
            
            if (strMonth.length == 1) {
                if (strDay.length == 1) {
                    strDate = [NSString stringWithFormat:@"%ld-0%ld-0%ld",year,month,day];
                } else if (strDay.length == 2) {
                    strDate = [NSString stringWithFormat:@"%ld-0%ld-%ld",year,month,day];
                }
            } else if (strMonth.length == 2) {
                if (strDay.length == 1) {
                    strDate = [NSString stringWithFormat:@"%ld-%ld-0%ld",year,month,day];
                } else if (strDay.length == 2) {
                    strDate = [NSString stringWithFormat:@"%ld-%ld-%ld",year,month,day];
                }
            }
            
            NSString *strInsert = [NSString stringWithFormat:@"insert into health values(%ld,'%@');",_difCountOfStartStepAndEndStep,strDate];
            
            NSLog(@"%@",strInsert);
            
            BOOL isInsertOK = [_mDB executeUpdate:strInsert];
            
            if (isInsertOK==YES) {
                NSLog(@"添加数据成功");
            }
        }
    }
    
    BOOL isClose=[_mDB close];
    
    if (isClose) {
        NSLog(@"关闭数据库成功");
    }
}


-(void) selectDB{
    NSString *strPath=[NSHomeDirectory() stringByAppendingString:@"/Documents/db01.db"];
    //        创建并且打开数据库，如果路径下面没有数据库，创建指定的数据库，如果路径下已经存在数据库，加载数据库到内存
    _mDB=[FMDatabase databaseWithPath:strPath];
    
    BOOL isOpen=[_mDB open];
    
    if (isOpen) {
        NSString *strSelectDate = self.txtSelectDate.text;
        
        NSString *strSelectQuery = [NSString stringWithFormat:@"select sum(stepNum) as sumStepNum from health where stepDate='%@';",strSelectDate];
        
        //            执行查找，查找成功的结果用ResultSet返回
        FMResultSet *rs=[_mDB executeQuery:strSelectQuery];
        
        //            遍历所有结果
        while ([rs next]) {
            
            NSInteger sumStepNum = [rs longForColumn:@"sumStepNum"];
            
            if (sumStepNum == 0) {
                NSString *strInfo = [NSString stringWithFormat:@"这天没有步行记录！"];
                
                self.txtQueryResult.text = strInfo;
            } else {
                NSString *strInfo = [NSString stringWithFormat:@"选择的日期是：%@，这天总计走了%ld步",strSelectDate,sumStepNum];
                
                self.txtQueryResult.text = strInfo;
            }
        }
    }
    
    BOOL isClose=[_mDB close];
    
    if (isClose) {
        NSLog(@"关闭数据库成功");
    }
}



@end
