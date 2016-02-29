//
//  BaseTabbarVC.m
//  WineApp
//
//  Created by 孙云 on 16/2/23.
//  Copyright © 2016年 haidai. All rights reserved.
//

#import "BaseTabbarVC.h"
#import "GoDrinkVC.h"
#import "SayDrinkVC.h"
@interface BaseTabbarVC ()

@end

@implementation BaseTabbarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    //加载控制器
    [self initVC];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/**
 *  加载控制器方法
 */
- (void)initVC{

    GoDrinkVC *goVC = [[GoDrinkVC alloc]init];
    goVC.title = @"去喝酒";
    UINavigationController *goNav = [[UINavigationController alloc]initWithRootViewController:goVC];
    
    SayDrinkVC *sayVC = [[SayDrinkVC alloc]init];
    sayVC.title = @"去聊酒";
    sayVC.view.backgroundColor = [UIColor blueColor];
    UINavigationController *sayNav = [[UINavigationController alloc]initWithRootViewController:sayVC];
    NSArray *vcArray = @[goNav,sayNav];
    self.viewControllers = vcArray;
}
@end
