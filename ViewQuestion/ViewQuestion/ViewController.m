//
//  ViewController.m
//  ViewQuestion
//
//  Created by 杨 on 15/12/28.
//  Copyright © 2015年 杨. All rights reserved.
//

#import "ViewController.h"
#import <Mixpanel.h>
#import "SecondViewCtrl.h"
#import "TestViewController.h"



@interface ViewController ()
{
    Mixpanel *mixpanel;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor yellowColor];
    mixpanel = [Mixpanel sharedInstance];
    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [testButton addTarget:self action:@selector(testClick) forControlEvents:UIControlEventTouchUpInside];
    testButton.frame = CGRectMake(100, 100, 100, 50);
    [testButton setTitle:@"click" forState:UIControlStateNormal];
    [self.view addSubview:testButton];
    NSString *sysName = [[UIDevice currentDevice] systemName];
    NSString *sysVer = [[UIDevice currentDevice] systemVersion];
    NSString *model = [[UIDevice currentDevice] model];
    NSString *name = [[UIDevice currentDevice] name];
    NSString *weizhi = [[UIDevice currentDevice] localizedModel];
    UIDeviceOrientation *orientation = [[UIDevice currentDevice] orientation];
    NSString *uuid = [[UIDevice currentDevice] identifierForVendor];
    float batterylevel = [[UIDevice currentDevice] batteryLevel];
    NSMutableArray *array = [NSMutableArray array];
        
    UIButton *nextViewClick = [UIButton buttonWithType:UIButtonTypeCustom];
    nextViewClick.frame = CGRectMake(0, 100, 100, 50);
    nextViewClick.backgroundColor = [UIColor greenColor];
    [nextViewClick addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextViewClick];
    
    UIButton *nextViewClick1 = [UIButton buttonWithType:UIButtonTypeCustom];
    nextViewClick1.frame = CGRectMake(0, 250, 100, 50);
    nextViewClick1.backgroundColor = [UIColor greenColor];
    [nextViewClick1 addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextViewClick1];
    
    UIButton *nextViewClick12 = [UIButton buttonWithType:UIButtonTypeCustom];
    [nextViewClick12 setTitle:@"turn" forState:UIControlStateNormal];
    [nextViewClick12 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    nextViewClick12.frame = CGRectMake(0, 400, 100, 50);
    nextViewClick12.backgroundColor = [UIColor greenColor];
    [nextViewClick12 addTarget:self action:@selector(turnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextViewClick12];
    
    UIButton *nextViewClick123 = [UIButton buttonWithType:UIButtonTypeCustom];
    nextViewClick123.frame = CGRectMake(0, 550, 100, 50);
    nextViewClick123.backgroundColor = [UIColor greenColor];
    [nextViewClick123 addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextViewClick123];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(200, 100, 100, 30)];
    label.text = @"test";
    [self.view addSubview:label];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)turnAction{
    
    TestViewController *nextVC = [TestViewController new];
    
    [self presentViewController:nextVC animated:YES completion:nil];
    NSLog(@"12");
}

-(void)next{
    SecondViewCtrl *secondVC = [SecondViewCtrl new];
//    [self.navigationController pushViewController:secondVC animated:YES];
    [self presentViewController:secondVC animated:YES completion:nil];
    NSLog(@"!!!!!");
}

-(void)testClick{
    NSLog(@"1");
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [mixpanel track:@"testtest"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
