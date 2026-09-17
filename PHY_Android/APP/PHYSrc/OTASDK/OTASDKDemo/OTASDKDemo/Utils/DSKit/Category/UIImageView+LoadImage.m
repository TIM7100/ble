//
//  UIImageView+LoadImage.m
//  XianjinXia
//
//  Created by sword on 10/02/2017.
//  Copyright © 2017 lxw. All rights reserved.
//

#import "UIImageView+LoadImage.h"
#import "BaseDefinition.h"
#import "UIImageView+WebCache.h"

@implementation UIImageView (LoadImage)

- (void)loadImageWithImagePath:(NSString *)imagePath {
    
    [self loadImageWithImagePath:imagePath placeholderImage:ImageNamed(@"ascending_icon_normal")];
}

- (void)loadImageWithImagePath:(NSString *)imagePath placeholderImage:(UIImage *)image {
    
    [self sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:image];
}

@end
