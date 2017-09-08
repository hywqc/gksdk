//
//  YCRefreshControl.m
//  mydemo
//
//  Created by wqc on 16/7/11.
//  Copyright © 2016年 gokuai. All rights reserved.
//

#import "YCRefreshControl.h"
#import "YCRefreshView.h"
#import "YCLoadMoreView.h"


static const NSInteger kYCDefaultRefreshHeight = 60;
static const NSInteger kYCDefaultLoadMoreHeight = 50;

typedef NS_ENUM(NSInteger, YCRefreshState) {
    YCRefreshState_Pulling = 0,
    YCRefreshState_Normal,
    YCRefreshState_Loading,
    YCRefreshState_Stopped
};

@interface YCRefreshControl ()

@property(nonatomic,strong) UIScrollView* scrollView;
@property(nonatomic,weak) id<YCRefreshControlDelegate> delegate;

@property(nonatomic,assign) YCRefreshState refreshSate;



@property(nonatomic,assign) BOOL enablePullDownRefresh;
@property(nonatomic,assign) BOOL enableLoadMoreRefresh;
@property(nonatomic,assign) NSInteger autoLoadMoreThreshold;
@property(nonatomic,assign) YCRefreshViewLayerType refreshViewLayerType;

@property(nonatomic,strong) YCRefreshView* refreshView;
@property(nonatomic,strong) YCLoadMoreView* loadMoreView;


@property(nonatomic,assign) BOOL pullDownRefreshing;
@property(nonatomic,assign) BOOL loadMoreRefreshing;

@property(nonatomic,assign) NSInteger loadMoreRefreshedCount;

@end

@implementation YCRefreshControl

-(instancetype) initWithScrollView:(UIScrollView*)scrollView delegate:(id<YCRefreshControlDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.scrollView = scrollView;
        [self setup];
    }
    return self;
}

-(void)setup {
    
    _originalTopInset = _scrollView.contentInset.top;
    
    self.refreshSate = YCRefreshState_Normal;
    
    [self configObserverWithScrollView:_scrollView];
    
    if (self.refreshViewLayerType == YCRefreshViewLayerTypeOnScrollViews) {
        if (self.enablePullDownRefresh) {
            [_scrollView addSubview:self.refreshView];
        }
    } else {
        _scrollView.backgroundColor = [UIColor clearColor];
        UIView *superView = [_scrollView superview];
        if (self.enablePullDownRefresh) {
            [superView insertSubview:self.refreshView belowSubview:_scrollView];
        }
    }
    
    if (self.enableLoadMoreRefresh) {
        [_scrollView addSubview:self.loadMoreView];
    }
}

-(void)dealloc {
    self.delegate = nil;
    [self removeObserverWithScrollView:self.scrollView];
    self.scrollView = nil;
    
    self.refreshView = nil;
    
    self.loadMoreView = nil;
}

-(void)configObserverWithScrollView:(UIScrollView*)scrollView {
    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    //[scrollView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:nil];
    [scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserverWithScrollView:(UIScrollView *)scrollView {
    [scrollView removeObserver:self forKeyPath:@"contentOffset" context:nil];
    //[scrollView removeObserver:self forKeyPath:@"contentInset" context:nil];
    [scrollView removeObserver:self forKeyPath:@"contentSize" context:nil];
}

-(void)setRefreshSate:(YCRefreshState)refreshSate {
    
    switch (refreshSate) {
        case YCRefreshState_Normal:
        case YCRefreshState_Stopped:
            self.refreshView.stateLabel.text = NSLocalizedString(@"下拉刷新",nil);
            break;
        case YCRefreshState_Loading:
            if (self.pullDownRefreshing) {
                self.refreshView.stateLabel.text = NSLocalizedString(@"正在加载",nil);
                [self setScrollViewContentInsetForPullDown];
                
                if (self.refreshSate == YCRefreshState_Pulling) {
                    [self animationRefreshCircleView];
                }
            }
            break;
        case YCRefreshState_Pulling:
            self.refreshView.stateLabel.text = NSLocalizedString(@"释放立即刷新",nil);
            break;
        default:
            break;
    }
    _refreshSate = refreshSate;
}


-(void)resetScrollViewContentInset {
    UIEdgeInsets inset = _scrollView.contentInset;
    inset.top = _originalTopInset;
    
    [UIView animateWithDuration:0.3 animations:^{
        _scrollView.contentInset = inset;
    } completion:^(BOOL finished) {
        self.refreshSate = YCRefreshState_Normal;
        
        self.refreshView.refreshCircleView.offsetY = 0;
        [self.refreshView.refreshCircleView setNeedsDisplay];
        
        if (self.refreshView.refreshCircleView) {
            [self.refreshView.refreshCircleView.layer removeAllAnimations];
        }
    }];
}


-(void)setScrollViewContentInset:(UIEdgeInsets)inset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = inset;
                     }
                     completion:^(BOOL finished) {
                         if (self.refreshSate == YCRefreshState_Stopped) {
                             self.refreshSate = YCRefreshState_Normal;
                             
                             if (self.refreshView.refreshCircleView) {
                                 [self.refreshView.refreshCircleView.layer removeAllAnimations];
                             }
                         }
                     }];
}

-(void)setScrollViewContentInsetForPullDown {
    UIEdgeInsets inset = self.scrollView.contentInset;
    inset.top = kYCDefaultRefreshHeight+[self getAdaptorTop];
    [self setScrollViewContentInset:inset];
}

-(void)setScrollViewContentInsetForLoadMore {
    if(_pullDownRefreshing) return;
    UIEdgeInsets inset = self.scrollView.contentInset;
    inset.bottom = kYCDefaultLoadMoreHeight+[self getAdaptorBottom];
    [self setScrollViewContentInset:inset];
}

-(void)startLoadMoreRefreshing {
    if (self.enableLoadMoreRefresh) {
        NSInteger count = self.autoLoadMoreThreshold;
        if (count == 0 || self.loadMoreRefreshedCount > count) {
            [self.loadMoreView setupManualState];
        } else {
            [self callBeginLoadMoreRefreshing];
        }
    }
    
}

-(void)callBeginLoadMoreRefreshing {
    if(_loadMoreRefreshing) return;
    self.loadMoreRefreshing = YES;
    self.loadMoreRefreshedCount ++;
    self.refreshSate = YCRefreshState_Loading;
    [self.loadMoreView startLoading];
    [self.delegate beginLoadMoreRefreshing];
}

-(void)callBeginPullDownRefreshing {
    self.loadMoreRefreshedCount = 0;
    [self.delegate beginPullDownRefreshing];
}


-(void)endLoadMoreRefreshing {
    if (self.enableLoadMoreRefresh) {
        self.loadMoreRefreshing = NO;
        self.refreshSate = YCRefreshState_Normal;
        [self.loadMoreView endLoading];
    }
}

-(void)endPullDownRefreshing {
    if (self.enablePullDownRefresh) {
        self.pullDownRefreshing = NO;
        self.refreshSate = YCRefreshState_Stopped;
        [self resetScrollViewContentInset];
    }
}

-(CGFloat)getAdaptorTop {
    BOOL b = YES;
    if ([_delegate respondsToSelector:@selector(extendForTopEdge)]) {
        b = [_delegate extendForTopEdge];
    }
    return (b?64:0);
}

-(CGFloat)getAdaptorBottom {
    CGFloat h = 0;
    if ([_delegate respondsToSelector:@selector(extendBottomHeight)]) {
        h = [_delegate extendBottomHeight];
    }
    return h;
}

- (void)animationRefreshCircleView {
    if (self.refreshView.refreshCircleView.offsetY != kYCDefaultRefreshHeight - kXHRefreshCircleViewHeight) {
        self.refreshView.refreshCircleView.offsetY = kYCDefaultRefreshHeight - kXHRefreshCircleViewHeight;
        [self.refreshView.refreshCircleView setNeedsDisplay];
    }
    [self.refreshView.refreshCircleView.layer removeAllAnimations];
    [self.refreshView.refreshCircleView.layer addAnimation:[YCRefreshCircleView repeatRotateAnimation] forKey:@"rotateAnimation"];
    
    [self callBeginPullDownRefreshing];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"contentSize"]) {
        if (self.enableLoadMoreRefresh) {
            CGSize size = [[change valueForKey:NSKeyValueChangeNewKey] CGSizeValue];
            if (size.height>CGRectGetHeight(self.scrollView.bounds)) {
                CGRect frame = self.loadMoreView.frame;
                frame.origin.y = size.height;
                self.loadMoreView.frame = frame;
                [self setScrollViewContentInsetForLoadMore];
            }
        }
    } else if ([keyPath isEqualToString:@"contentOffset"]) {
        CGPoint contentOffset = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
        if (self.enableLoadMoreRefresh) {
            CGFloat pos = self.scrollView.contentOffset.y;
            
            CGFloat scrollViewHeight = self.scrollView.bounds.size.height;
            
            CGSize contentSize = self.scrollView.contentSize;
            
            CGFloat inset = self.scrollView.contentInset.bottom;
            
            if ((contentSize.height-inset - (pos + scrollViewHeight) < kYCDefaultLoadMoreHeight) &&
                _refreshSate!=YCRefreshState_Loading &&
                !_loadMoreRefreshing) {
                [self startLoadMoreRefreshing];
            }
        }
        
        if (self.enablePullDownRefresh) {
            if (!self.loadMoreRefreshing) {
                if (self.refreshSate!=YCRefreshState_Loading) {
                    
                    if (ABS(self.scrollView.contentOffset.y + [self getAdaptorTop]) >= kXHRefreshCircleViewHeight) {
                        self.refreshView.refreshCircleView.offsetY = MIN(ABS(self.scrollView.contentOffset.y + [self getAdaptorTop]), kYCDefaultRefreshHeight) - kXHRefreshCircleViewHeight;
                        [self.refreshView.refreshCircleView setNeedsDisplay];
                    }
                    
                    CGFloat offsetThreshold = -(kYCDefaultRefreshHeight+self.scrollView.contentInset.top);
                    
                    if (self.refreshSate == YCRefreshState_Pulling && !self.scrollView.isDragging) {
                        self.pullDownRefreshing = YES;
                        self.refreshSate = YCRefreshState_Loading;
                    } else if (contentOffset.y<offsetThreshold && self.scrollView.isDragging && self.refreshSate == YCRefreshState_Stopped) {
                        self.refreshSate = YCRefreshState_Pulling;
                    } else if (contentOffset.y>=offsetThreshold && self.refreshSate!=YCRefreshState_Stopped) {
                        self.refreshSate = YCRefreshState_Stopped;
                    }
                }
            }
        }
        
    }
}

-(void)onLoadMoreButtonClicked:(id)sender {
    [self callBeginLoadMoreRefreshing];
}

#pragma mark - getter
-(YCRefreshViewLayerType)refreshViewLayerType {
    YCRefreshViewLayerType curType = YCRefreshViewLayerTypeOnScrollViews;
    if ([_delegate respondsToSelector:@selector(refreshViewLayerType)]) {
        curType = [_delegate refreshViewLayerType];
    }
    return curType;
}

-(YCRefreshView*)refreshView {
    if (!_refreshView) {
        _refreshView = [[YCRefreshView alloc] initWithFrame:CGRectMake(0, (self.refreshViewLayerType == YCRefreshViewLayerTypeOnSuperView?self.scrollView.contentInset.top:-kYCDefaultRefreshHeight), CGRectGetWidth([UIScreen mainScreen].bounds), kYCDefaultRefreshHeight)];
        _refreshView.backgroundColor = [UIColor whiteColor];
        _refreshView.refreshCircleView.heightBeginToRefresh = kYCDefaultRefreshHeight - kXHRefreshCircleViewHeight;
        _refreshView.refreshCircleView.offsetY = 0;
        _refreshView.refreshCircleView.isRefreshViewOnTableView = self.refreshViewLayerType;
    }
    return _refreshView;
}

-(YCLoadMoreView*)loadMoreView {
    if (!_loadMoreView) {
        _loadMoreView = [[YCLoadMoreView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), kYCDefaultLoadMoreHeight)];
        [_loadMoreView.loadMoreButton addTarget:self action:@selector(onLoadMoreButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _loadMoreView;
}

-(BOOL)enablePullDownRefresh {
    BOOL enable = YES;
    if ([_delegate respondsToSelector:@selector(enablePullDownRefresh)]) {
        enable = [_delegate enablePullDownRefresh];
    }
    return enable;
}

-(BOOL)enableLoadMoreRefresh {
    BOOL enable = YES;
    if ([_delegate respondsToSelector:@selector(enableLoadMoreRefresh)]) {
        enable = [_delegate enableLoadMoreRefresh];
    }
    return enable;
}

-(NSInteger)autoLoadMoreThreshold {
    NSInteger count = 2;
    if ([_delegate respondsToSelector:@selector(autoLoadMoreThreshold)]) {
        count = [_delegate autoLoadMoreThreshold];
    }
    return count;
}

@end
