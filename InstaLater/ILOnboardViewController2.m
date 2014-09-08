//
//  ILOnboardViewController2.m
//  InstaLater
//
//  Created by Kyle Dillon on 9/1/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "ILOnboardViewController2.h"

@interface ILOnboardViewController2 ()

@end

@implementation ILOnboardViewController2

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.button.layer.cornerRadius = 5.0;
    [self applyDropShadowToView:self.button withWidth:5.0];
}

-(void)applyDropShadowToView:(UIView*)view withWidth:(float)width {
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:view.bounds];
    view.layer.masksToBounds = NO;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0.0f, width);
    view.layer.shadowOpacity = 0.5f;
    view.layer.shadowPath = shadowPath.CGPath;
}

@end
