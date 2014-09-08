//
//  ILOnboardViewController6.m
//  InstaLater
//
//  Created by Kyle Dillon on 9/1/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "ILOnboardViewController6.h"

@interface ILOnboardViewController6 ()

@end

@implementation ILOnboardViewController6

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.button.layer.cornerRadius = 5.0;
    [self applyDropShadowToView:self.button withWidth:5.0];
    // Do any additional setup after loading the view.
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
