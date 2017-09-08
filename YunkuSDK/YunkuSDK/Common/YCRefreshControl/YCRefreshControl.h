//
//  YCRefreshControl.h
//  mydemo
//
//  Created by wqc on 16/7/11.
//  Copyright © 2016年 gokuai. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, YCRefreshViewLayerType) {
    YCRefreshViewLayerTypeOnScrollViews = 0,
    YCRefreshViewLayerTypeOnSuperView = 1,
};

@protocol YCRefreshControlDelegate <NSObject>
/**
 *  tableview的内容是否可以穿透nav bar
 *
 *  @return
 */
-(BOOL)extendForTopEdge;


/**
 *  tableview的内容是否可以穿透底部的bar, 以及高度, 当tableview延伸到下面的bar时, 必须实现该方法
 *
 *  @return
 */
-(CGFloat)extendBottomHeight;

/**
 *  询问代理是否支持下拉刷新, 默认支持
 *
 *  @return
 */

@optional

/**
 *  是否支持下拉刷新, 默认支持
 *
 *  @return
 */
-(BOOL)enablePullDownRefresh;


/**
 *  询问代理是否支持底部分页刷新, 默认支持
 *
 *  @return
 */
-(BOOL)enableLoadMoreRefresh;


/**
 *  下拉刷新控件添加在哪里, 默认添加在scrollview上
 *
 *  @return
 */
-(YCRefreshViewLayerType)refreshViewLayerType;


/**
 *  分页自动刷新几次后 转手动刷新, 默认3次
 *
 *  @return 返回0 表示一直手动刷新
 */
-(NSInteger)autoLoadMoreThreshold;


/**
 *  将要开始上提加载更多, 如果支持分页刷新, 这个方法必须实现
 */
-(void)beginLoadMoreRefreshing;


/**
 *  将要下拉刷新更多, 如果支持下拉刷新, 这个方法必须实现
 */
-(void)beginPullDownRefreshing;

@end

@interface YCRefreshControl : NSObject

@property (nonatomic, readwrite) CGFloat originalTopInset;

-(instancetype) initWithScrollView:(UIScrollView*)scrollView delegate:(id<YCRefreshControlDelegate>)delegate;

-(void)endLoadMoreRefreshing;
-(void)endPullDownRefreshing;

@end
