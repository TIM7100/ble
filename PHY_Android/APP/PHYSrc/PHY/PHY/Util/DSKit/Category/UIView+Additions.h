//
//  UIView+Additions.h
//  MLIPhone
//
//  Created by yakehuang on 5/10/14.
//
//

#import <UIKit/UIKit.h>

@interface UIView (XJXAdditions)

// 获得所属控制器
- (UIViewController*)viewController;
- (void)showLoading:(NSString *)word;
@end
