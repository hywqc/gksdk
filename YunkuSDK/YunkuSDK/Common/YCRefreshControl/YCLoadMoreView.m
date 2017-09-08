//
//  YCLoadMoreView.m
//  mydemo
//
//  Created by wqc on 16/7/11.
//  Copyright © 2016年 gokuai. All rights reserved.
//

#import "YCLoadMoreView.h"

@interface YCLoadMoreView ()

@property(nonatomic,strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation YCLoadMoreView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.loadMoreButton];
        [self addSubview:self.activityIndicatorView];
        [self endLoading];
    }
    return self;
}

#pragma mark - Interface
-(void)startLoading {
    self.hidden = NO;
    [self.loadMoreButton setTitle:NSLocalizedString(@"正在载入", nil) forState:UIControlStateNormal];
    [self.activityIndicatorView startAnimating];
}

-(void)endLoading {
    self.hidden = YES;
    [self.loadMoreButton setTitle:NSLocalizedString(@"显示下20条", nil) forState:UIControlStateNormal];
    [self.activityIndicatorView stopAnimating];
}

-(void)setupManualState {
    self.hidden = NO;
    [self.loadMoreButton setTitle:NSLocalizedString(@"显示下20条", nil) forState:UIControlStateNormal];
}

#pragma mark - getter
-(UIButton*)loadMoreButton {
    if (!_loadMoreButton) {
        _loadMoreButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 5, CGRectGetWidth(self.bounds)-20, CGRectGetHeight(self.bounds)-10)];
        _loadMoreButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_loadMoreButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_loadMoreButton setBackgroundColor:[UIColor colorWithWhite:0.922 alpha:1.000]];
    }
    return _loadMoreButton;
}

-(UIActivityIndicatorView*)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicatorView.hidesWhenStopped = YES;
        _activityIndicatorView.center = CGPointMake(CGRectGetWidth(self.bounds)/3, CGRectGetHeight(self.bounds)/2);
    }
    return _activityIndicatorView;
}

@end
