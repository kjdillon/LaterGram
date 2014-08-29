//
//  ILPostViewController.m
//  InstaLater
//
//  Created by Kyle Dillon on 8/7/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "ILPostViewController.h"

@interface ILPostViewController ()

@end

@implementation ILPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    NSURL *url = [NSURL URLWithString:self.urlString];
    ALAsset *asset = [self assetForURL:url];
    self.asset = asset;
    UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
    [self.imageView setImage:image];
    
    
    [self.blurView.layer setCornerRadius:20];
    //[self postItPressed:nil];
    
}

- (ALAsset *)assetForURL:(NSURL *)url {
    __block ALAsset *result = nil;
    __block NSError *assetError = nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    [self.library assetForURL:url resultBlock:^(ALAsset *asset) {
        result = asset;
        dispatch_semaphore_signal(sema);
    } failureBlock:^(NSError *error) {
        assetError = error;
        dispatch_semaphore_signal(sema);
    }];
    
    
    if ([NSThread isMainThread]) {
        while (!result && !assetError) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
    else {
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    
    return result;
}

UIDocumentInteractionController *docFile;
- (IBAction)postItPressed:(id)sender {
    NSURL *instagramURL = [NSURL URLWithString:@"instagram://"];
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
        UIImage* photoImage = [UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullScreenImage]];
        NSData* imageData = UIImagePNGRepresentation(photoImage);
        NSString* captionString = @"#LaterGram #MadeWithLaterGram";
        NSString* imagePath = [NSString stringWithFormat:@"%@/instagramShare.igo", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
        [imageData writeToFile:imagePath atomically:NO];
        NSURL* fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"file://%@",imagePath]];
        docFile=[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:imagePath]];
        docFile.delegate = self;
        docFile.annotation = [NSDictionary dictionaryWithObject:captionString forKey:@"InstagramCaption"];
        docFile.UTI = @"com.instagram.exclusivegram";
        [docFile presentOpenInMenuFromRect: self.view.frame inView:self.view animated:YES];
    }
    else {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Instagram Not Installed"
                                                          message:@"Please install Instagram."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }

}

- (IBAction)backPressed:(id)sender {
    /*
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *mainVC = [storyboard instantiateViewControllerWithIdentifier:@"mainVC"];
    [self.navigationController presentViewController:mainVC animated:YES completion:nil];
     */
    self.mainVC.backPressed = YES;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
