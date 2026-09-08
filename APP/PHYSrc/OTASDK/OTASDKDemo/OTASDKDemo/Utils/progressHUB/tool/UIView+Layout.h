//
//  UIView+Layout.h
//  CultureShanghai
//
//  Created by ct on 16/3/10.
//  Copyright © 2016年 CT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Layout)


@property (nonatomic, assign) CGFloat originalX;//视图左上角的X值
@property (nonatomic, assign) CGFloat originalY;//视图左上角的Y值
@property (nonatomic, assign, readonly) CGFloat maxX;//视图的右下角的X值
@property (nonatomic, assign, readonly) CGFloat maxY;//视图的右下角的Y值
@property (nonatomic, assign) CGFloat width;//视图的宽
@property (nonatomic, assign) CGFloat height;//视图的高
@property (nonatomic, assign) CGSize viewSize;//视图的宽和高
@property (nonatomic, assign) CGFloat centerPointX;//中心位置的X坐标
@property (nonatomic, assign) CGFloat centerPointY;//中心位置的Y坐标

@property (nonatomic, assign) CGFloat cornerRadius;


@end
