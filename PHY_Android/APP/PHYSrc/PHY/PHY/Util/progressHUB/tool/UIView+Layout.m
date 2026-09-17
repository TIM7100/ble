//
//  UIView+Layout.m
//  CultureShanghai
//
//  Created by ct on 16/3/10.
//  Copyright © 2016年 CT. All rights reserved.
//

#import "UIView+Layout.h"

@implementation UIView (Layout)

//setting Methods
- (void)setOriginalX:(CGFloat)originalX
{
    CGRect frame = self.frame;
    frame.origin.x = originalX;
    self.frame = frame;
}

- (void)setOriginalY:(CGFloat)originalY
{
    CGRect frame = self.frame;
    frame.origin.y = originalY;
    self.frame = frame;
}


- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}


- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}


- (void)setViewSize:(CGSize)viewSize
{
    CGRect frame = self.frame;
    frame.size = viewSize;
    self.frame = frame;
}

- (void)setCenterPointX:(CGFloat)centerPointX
{
    self.center = CGPointMake(centerPointX, self.center.y);
}

- (void)setCenterPointY:(CGFloat)centerPointY
{
    self.center = CGPointMake(self.center.x, centerPointY);
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (cornerRadius > 0) {
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        self.layer.cornerRadius = cornerRadius;
        self.layer.masksToBounds = YES;
    }else{
        self.layer.cornerRadius = 0;
    }
}

//getting Methods

- (CGFloat)originalX
{
    return self.frame.origin.x;
}

- (CGFloat)originalY
{
    return self.frame.origin.y;
}

- (CGFloat)maxX
{
    return CGRectGetMaxX(self.frame);
}

- (CGFloat)maxY
{
    return CGRectGetMaxY(self.frame);
}

- (CGFloat)width
{
    return self.frame.size.width;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

- (CGSize)viewSize
{
    return self.bounds.size;
}

- (CGFloat)centerPointX
{
    return self.center.x;
}

- (CGFloat)centerPointY
{
    return self.center.y;
}


- (CGFloat)cornerRadius
{
    return self.layer.cornerRadius;
}


@end
