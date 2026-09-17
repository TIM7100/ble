//
//  CustomLoadingView.m
//  progressHUD
//
//  Created by 刘燕鲁 on 16/12/29.
//  Copyright © 2016年 刘燕鲁. All rights reserved.
//

#import "CustomLoadingView.h"
#import "MyMaskView.h"
#import "UIView+Frame.h"
#import "UIImage+GIF.h"
#import "UIView+Layout.h"


// rgb颜色转换（16进制->10进制）
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define TXT_SIZE_15 [UIFont systemFontOfSize:13]

@interface CustomLoadingView()


@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSArray *titleArray;
@property (nonatomic, assign) NSInteger number;

@end

@implementation CustomLoadingView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        MyMaskView *maskView = [[MyMaskView alloc] initWithFrame:CGRectMake(0, 0, 150, 150) bgColor:[UIColor clearColor] cornerRadius:15.0f];
        [self addSubview:maskView];
        
        maskView.center = CGPointMake(self.width * 0.5, self.height * 0.5);
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -10, 150, 150)];
//        imageView.backgroundColor = [UIColor whiteColor];
        static UIImage *gifImg;
        if (!gifImg) {
            NSData *gifData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"jiazai" ofType:@"gif"]];
            gifImg = [UIImage sd_animatedGIFWithData:gifData];
        }
        imageView.image = gifImg;
        [maskView addSubview:imageView];
        imageView.centerX = maskView.width * 0.5;
        
        self.titleArray = @[@"加载中 .",@"加载中 ..",@"加载中 ..."];
        
        //标题
        CGFloat labelWidth = [self textWidth:self.titleArray[2] font:TXT_SIZE_15];
        self.loadLabel = [[UILabel alloc] initWithFrame:CGRectMake((maskView.width-labelWidth)*0.5, 0, maskView.width, [self fontHeight:TXT_SIZE_15])];
        self.loadLabel.font = TXT_SIZE_15;
        self.loadLabel.textColor = [UIColor redColor];
        self.loadLabel.textAlignment = NSTextAlignmentLeft;
//        [maskView addSubview:self.loadLabel];
        self.loadLabel.originalY = maskView.height -self.loadLabel.height - 15;
        
        [self beginAnimation];
    }
    return self;
}
- (CGFloat)fontHeight:(UIFont *)font
{
    
    if (font != nil){
        return font.lineHeight;
    }else{
        return 0;
    }
}
- (CGFloat)textWidth:(NSString *)text font:(UIFont *)font
{
    if ([text isKindOfClass:[NSString class]] && font != nil)
    {
        if (text.length)
        {
            CGSize size = [text sizeWithAttributes:@{NSFontAttributeName:font}];
            return ceilf(size.width);
        }
    }
    return 0;
}

+ (id)sharedLoadingView:(BOOL)isInteractive
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    CustomLoadingView *shareView = [window viewWithTag:19345];
    if (!shareView) {
        if (isInteractive) {
            shareView = [[CustomLoadingView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        }else{
            shareView = [[CustomLoadingView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        }
        shareView.tag = 19345;
        [window addSubview:shareView];
        shareView.center = CGPointMake(SCREEN_WIDTH * 0.5, SCREEN_HEIGHT * 0.5 - 25);
    }
    return shareView;
}

- (void)beginAnimation{
    
    [self endAnimation];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateLoadingLabelText) userInfo:nil repeats:YES];
    [_timer fire];
}
- (void)endAnimation{
    
    if (self.timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)updateLoadingLabelText{

    self.loadLabel.text = _titleArray[_number];
    _number ++;
    if (_number == 3) {
        _number = 0;
    }
}

@end
