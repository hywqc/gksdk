//
//  YCLoadMoreView.h
//  mydemo
//
//  Created by wqc on 16/7/11.
//  Copyright © 2016年 gokuai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YCLoadMoreView : UIView

@property(nonatomic,strong) UIButton *loadMoreButton;

-(void)startLoading;
-(void)endLoading;
-(void)setupManualState;

@end
