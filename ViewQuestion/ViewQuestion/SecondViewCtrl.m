//
//  SecondViewCtrl.m
//  ViewQuestion
//
//  Created by 杨 on 15/12/28.
//  Copyright © 2015年 杨. All rights reserved.
//

#import "SecondViewCtrl.h"
#import <Mixpanel/MPTweakInline.h>

@interface SecondViewCtrl ()

@end

@implementation SecondViewCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *str = MPTweakValue(@"change name",@"hehe");
    [testButton setTitle:str forState:UIControlStateNormal];
    testButton.frame = CGRectMake(100, 100, 100, 50);
    [self.view addSubview:testButton];
    // Do any additional setup after loading the view.
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

@end
