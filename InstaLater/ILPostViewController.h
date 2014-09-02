//
//  ILPostViewController.h
//  InstaLater
//
//  Created by Kyle Dillon on 8/7/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QBImagePickerController.h"
#import "FXBlurView.h"
#import "InstaPostCell.h"
#import "InstaPost.h"
#import "ILViewController.h"

@interface ILPostViewController : UIViewController <UIDocumentInteractionControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) ALAsset *asset;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)postItPressed:(id)sender;
- (IBAction)backPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

- (IBAction)playButtonPressed:(id)sender;
@property (strong, nonatomic) ALAssetsLibrary *library;
@property (strong, nonatomic) ILViewController *mainVC;
@property (weak, nonatomic) IBOutlet FXBlurView *blurView;

@end
