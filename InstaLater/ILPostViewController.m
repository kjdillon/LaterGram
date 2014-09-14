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

bool dontPostNotification;

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
    
     if ([[self.asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
         self.playButton.hidden = NO;
     } else {
         self.playButton.hidden = YES;
     }
    
    if(self.asset == nil) {
        dontPostNotification = YES;
        [self backPressed:nil];
    } else {
        dontPostNotification = NO;
    }
    
}

- (ALAsset *)assetForURL:(NSURL *)url {
    __block ALAsset *result = nil;
    __block NSError *assetError = nil;
    __block BOOL resultComplete = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    [self.library assetForURL:url resultBlock:^(ALAsset *asset) {
        result = asset;
        resultComplete = YES;
        dispatch_semaphore_signal(sema);
    } failureBlock:^(NSError *error) {
        assetError = error;
        dispatch_semaphore_signal(sema);
    }];
    
    
    if ([NSThread isMainThread]) {
        while (!resultComplete && !assetError) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
    else {
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    
    return result;
}

- (void) video: (NSString *) videoPath didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo {
    NSLog(@"Video saved with error: %@", error);
}

-(NSString*)savedVideoPathForAsset:(ALAsset*)asset {
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    Byte *buffer = (Byte*)malloc(rep.size);
    NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
    NSData *videoData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
    NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.mov"];
    BOOL success = [videoData writeToFile:videoPath atomically:NO];
    if(success == YES) {
        return videoPath;
    } else {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Video Data Is Corrupted"
                                                          message:@"Please try a different video."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        return nil;
    }
}

UIDocumentInteractionController *docFile;
- (IBAction)postItPressed:(id)sender {
    if ([[self.asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
        NSString *videopath = [self savedVideoPathForAsset:self.asset];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videopath)) {
            UISaveVideoAtPathToSavedPhotosAlbum(videopath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Video Saved"
                                                          message:@"You'll now to transfered to Instagram, simply choose the most recently saved video."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        message.delegate = self;
        message.tag = 123;
        [message show];

    } else {
        NSURL *instagramURL = [NSURL URLWithString:@"instagram://"];
        if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
            UIImage* photoImage = [UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullScreenImage]];
            photoImage = [self normalizedImage:photoImage];
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
            [self.mainVC removePostAndDontUpdate:0];
        } else {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Instagram Not Installed"
                                                              message:@"Please install Instagram."
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            [message show];
        }
        
        dontPostNotification = YES;
        [self backPressed:nil];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 123) {
        NSURL *instagramURL = [NSURL URLWithString:@"instagram://camera"];
        if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
            [[UIApplication sharedApplication] openURL:instagramURL];
        }
        
        [self.mainVC removePostAndDontUpdate:0];
        
        dontPostNotification = YES;
        [self backPressed:nil];
    }
}

// Helper method to fix orientation issues when exporting to Instagram
- (UIImage *)normalizedImage:(UIImage*)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (IBAction)backPressed:(id)sender {
    /*
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *mainVC = [storyboard instantiateViewControllerWithIdentifier:@"mainVC"];
    [self.navigationController presentViewController:mainVC animated:YES completion:nil];
     */
    self.mainVC.backPressed = YES;
    
    if(dontPostNotification == NO) {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        if(localNotification != nil) {
            NSDate *curDate = [[NSDate alloc] init];
            NSDate *dateToFire = [curDate dateByAddingTimeInterval:6*60*60];
            [localNotification setFireDate:dateToFire];
            [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
            NSURL *url = [NSURL URLWithString:self.urlString];
            //[self deleteNotificationWithURLString:[url absoluteString]];
            [self deletePreviousNotifications];
            NSArray *objs = [NSArray arrayWithObjects:@"LATERGRAM_NOTIF",@"postURLString", nil];
            NSArray *keys = [NSArray arrayWithObjects:@"LATERGRAM_NOTIF",[url absoluteString], nil];
            NSDictionary *data = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
            [localNotification setUserInfo:data];
            [localNotification setAlertBody:@"It's time to post!"];
            [localNotification setAlertAction:@"Okay"];
            [localNotification setHasAction:YES];
            [localNotification setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] + 1];
            [localNotification setSoundName:UILocalNotificationDefaultSoundName];
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        }
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) deletePreviousNotifications {
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *eventArray = [app scheduledLocalNotifications];
    for (int i=0; i<[eventArray count]; i++)
    {
        UILocalNotification* oneEvent = [eventArray objectAtIndex:i];
        NSDictionary *userInfoCurrent = oneEvent.userInfo;
        NSString *uniqueString=[NSString stringWithFormat:@"%@",[userInfoCurrent valueForKey:@"LATERGRAM_NOTIF"]];
        if ([uniqueString isEqualToString:@"LATERGRAM_NOTIF"])
        {
            //Cancelling local notification
            [app cancelLocalNotification:oneEvent];
        }
    }
}

MPMoviePlayerViewController *movieController;
- (IBAction)playButtonPressed:(id)sender {
    // Animate removal from list
    movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:self.asset.defaultRepresentation.url];
    [self presentMoviePlayerViewControllerAnimated:movieController];
    [movieController.moviePlayer play];
}
@end
