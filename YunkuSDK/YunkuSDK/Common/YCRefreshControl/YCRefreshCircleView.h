//
//  YCRefreshCircleView.h
//  mydemo
//
//  Created by wqc on 16/7/12.
//  Copyright © 2016年 gokuai. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kXHRefreshCircleViewHeight 20

@interface YCRefreshCircleView : UIView

@property (nonatomic, assign) CGFloat heightBeginToRefresh;
@property (nonatomic, assign) CGFloat offsetY;


@property (nonatomic, assign) BOOL isRefreshViewOnTableView;

+ (CABasicAnimation*)repeatRotateAnimation;

@end
