//
//  UIButton+LoadImage.m
//  KDFDApp
//
//  Created by sword on 2017/1/6.
//  Copyright © 2017年 cailiang. All rights reserved.
//

#import "UIButton+LoadImage.h"

#import "UIButton+WebCache.h"

@implementation UIButton (LoadImage)

- (void)loadBackgroundImageWithImagePath:(NSString *)imagePath {
    
    [self loadBackgroundImageWithImagePath:imagePath placeholderImage:[UIImage imageNamed:@"default_image"]];
}
- (void)loadBackgroundImageWithImagePath:(NSString *)imagePath placeholderImage:(UIImage *)image {
    
    [self sd_setBackgroundImageWithURL:[NSURL URLWithString:imagePath] forState:UIControlStateNormal placeholderImage:image];
}

- (void)loadImageWithImagePath:(NSString *)imagePath {
    
    [self loadImageWithImagePath:imagePath placeholderImage:nil];
}
- (void)loadImageWithImagePath:(NSString *)imagePath placeholderImage:(UIImage *)image {
    
    [self sd_setImageWithURL:[NSURL URLWithString:imagePath] forState:UIControlStateNormal placeholderImage:image];
}
@end
