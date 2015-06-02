//
//  UIImage+BackgroundImage.m
//  Test
//
//  Created by Brent Gulanowski on 2015-06-02.
//  Copyright (c) 2015 Lichen Labs. All rights reserved.
//

#import "UIImage+BackgroundImage.h"

@implementation UIImage (BackgroundImage)

+ (UIImage *)buttonBackgroundImageWithFill:(UIColor *)fill stroke:(UIColor *)stroke
{
    // add a point to diameter for stretchable area
    CGFloat diameter = 8 * 2.0f + 1.0f;
    
    CGRect rect = CGRectMake(0.0f, 0.0f, diameter, diameter);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 0.5, 0.5) cornerRadius:8];
    path.lineWidth = 1;
    
    CGRect contextRect = CGRectInset(rect, -0.5, -0.5);
    UIGraphicsBeginImageContextWithOptions(contextRect.size, NO, 0);
    
    if (fill) {
        [fill setFill];
        [path fill];
    }
    
    if (stroke) {
        [stroke setStroke];
        [path stroke];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIEdgeInsets capInsets = UIEdgeInsetsMake(8,8,8,8);
    image = [image resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
    
    return image;
}

@end
