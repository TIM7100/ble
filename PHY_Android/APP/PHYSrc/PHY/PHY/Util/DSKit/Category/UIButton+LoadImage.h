//
//  UIButton+LoadImage.h
//  KDFDApp
//
//  Created by sword on 2017/1/6.
//  Copyright © 2017年 cailiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (LoadImage)

- (void)loadBackgroundImageWithImagePath:(NSString *)imagePath;

- (void)loadBackgroundImageWithImagePath:(NSString *)imagePath placeholderImage:(UIImage *)image;

- (void)loadImageWithImagePath:(NSString *)imagePath;

- (void)loadImageWithImagePath:(NSString *)imagePath placeholderImage:(UIImage *)image;

@end
