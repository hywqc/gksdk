//
//  YCRefreshView.m
//  mydemo
//
//  Created by wqc on 16/7/11.
//  Copyright © 2016年 gokuai. All rights reserved.
//

#import "YCRefreshView.h"

@implementation YCRefreshView

- (YCRefreshCircleView *)refreshCircleView {
    if (!_refreshCircleView) {
        _refreshCircleView = [[YCRefreshCircleView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.bounds) - kXHRefreshCircleViewHeight) / 2 - 40, (CGRectGetHeight(self.bounds) - kXHRefreshCircleViewHeight) / 2 - 5, kXHRefreshCircleViewHeight, kXHRefreshCircleViewHeight)];
    }
    return _refreshCircleView;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.refreshCircleView.frame) + 5, (CGRectGetMinY(_refreshCircleView.frame)+(kXHRefreshCircleViewHeight-15)/2), 160, 15)];
        _stateLabel.backgroundColor = [UIColor clearColor];
        _stateLabel.font = [UIFont systemFontOfSize:13.f];
        _stateLabel.textColor = [UIColor lightGrayColor];
    }
    return _stateLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        CGRect timeLabelFrame = self.stateLabel.frame;
        timeLabelFrame.origin.y += CGRectGetHeight(timeLabelFrame) + 6;
        _timeLabel = [[UILabel alloc] initWithFrame:timeLabelFrame];
        _timeLabel.backgroundColor = [UIColor clearColor];
        _timeLabel.font = [UIFont systemFontOfSize:11.f];
        _timeLabel.textColor = [UIColor colorWithWhite:0.659 alpha:1.000];
    }
    return _timeLabel;
}

#pragma mark - Life Cycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //self.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.refreshCircleView];
        [self addSubview:self.stateLabel];
        //[self addSubview:self.timeLabel];
    }
    return self;
}

@end
