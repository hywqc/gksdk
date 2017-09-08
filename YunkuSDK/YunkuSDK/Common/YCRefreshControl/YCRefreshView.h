//
//  YCRefreshView.h
//  mydemo
//
//  Created by wqc on 16/7/11.
//  Copyright © 2016年 gokuai. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "YCRefreshCircleView.h"

@interface YCRefreshView : UIView

@property (nonatomic, strong) YCRefreshCircleView *refreshCircleView;

@property (nonatomic, strong) UILabel *stateLabel;

@property (nonatomic, strong) UILabel *timeLabel;

@end
