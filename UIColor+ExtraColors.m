//
//  UIColor+ExtraColors.m
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-17.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import "UIColor+ExtraColors.h"

@implementation UIColor (ExtraColors)

+ (UIColor *)previewButtonColor
{
    return [UIColor colorWithRed:51/255 green:0.90 blue:51/255 alpha:1.0];
}

+ (UIColor *)unsentTextColor
{
    return [UIColor colorWithRed:81.0/255.0 green:102.0/255.0 blue:145.0/255.0 alpha:1.0];
}

+ (UIColor *)sentTextColor
{
    return [UIColor colorWithRed:50/255 green:205/255 blue:50/255 alpha:1.0];
}

@end
