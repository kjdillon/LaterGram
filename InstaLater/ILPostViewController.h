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
#import "ILViewController.h"

@interface ILPostViewController : UIViewController <UIDocumentInteractionControllerDelegate>

@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) ALAsset *asset;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)postItPressed:(id)sender;
- (IBAction)backPressed:(id)sender;

@property (strong, nonatomic) ALAssetsLibrary *library;
@property (strong, nonatomic) ILViewController *mainVC;
@property (weak, nonatomic) IBOutlet FXBlurView *blurView;

@end
