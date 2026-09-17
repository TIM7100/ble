//
//  ValueSlider.h
//  PHY
//
//  Created by Han on 2018/10/9.
//  Copyright © 2018年 phy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ValueSlider : UISlider
/*! @brief slider的value文本 */
@property (nonatomic, copy) NSString *valueText;
/*! @brief slider的value字体 */
@property (nonatomic, strong) UIFont *valueFont;
/*! @brief slider的value文本颜色 */
@property (nonatomic, strong) UIColor *valueTextColor;
/*! @brief 按下slider时的回调block */
@property (nonatomic, copy) void(^touchDown)(ValueSlider *);
/*! @brief slider的value发生变化时的回调block */
@property (nonatomic, copy) void(^valueChanged)(ValueSlider *);
/*! @brief 松开slider时的回调block */
@property (nonatomic, copy) void(^touchUpInside)(ValueSlider *);
@end

NS_ASSUME_NONNULL_END
