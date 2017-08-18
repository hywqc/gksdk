//
//  ViewController.m
//  testobjc
//
//  Created by wqc on 2017/7/24.
//  Copyright © 2017年 wqc. All rights reserved.
//

#import "ViewController.h"
@import gkutility;
@import gknet;

@interface ViewController ()

@property(nonatomic,assign) int64_t taskID;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString * path = [gkutility docPathWithDecorate:nil];
    NSLog(@"path: %@",path);
    
    NSString * url = @"http://sdjfh=dhj!?dfjhdj";
    NSLog(@"%@",url.gkUrlEncode);
    
    NSDictionary * dic = @{@"aa":@11};
    NSString * dicstr = [gkutility obj2strWithObj:dic];
    NSData * d = [gkutility str2dataWithStr:dicstr];
    NSDictionary * adic = d.gkDic;
    NSLog(@"%@",dic.gkStr);
    
    GKRequestRetToken * retToken = [[GKHttpEngine shareInstance] loginWithAccount:@"hywqc" password:[@"Wqc@19870206" gkMD5]];
    if (retToken.statuscode == 200) {
        NSLog(@"%@",retToken.accessToken);
    }
}

- (IBAction)onTest:(id)sender {
    
    self.taskID = [[GKHttpEngine shareInstance] fetchEntsWithReget:NO completion:^(GKRequestRetEnts * _Nonnull ret) {
        if (ret.statuscode == 200) {
            NSLog(@"ok");
        } else {
            NSLog(@"failed");
        }
    }];
    
}

- (IBAction)onCancel:(id)sender {
    [[GKHttpEngine shareInstance] cancelTask:self.taskID];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
