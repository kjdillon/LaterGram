//
//  ILViewController.m
//  InstaLater
//
//  Created by Kyle Dillon on 7/16/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "ILViewController.h"
#import "InstaPost.h"
#import "InstaPostCell.h"
#import "ILPostViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>


#define CORNER_RADIUS 5.0f
#define ACCENT_COLOR [UIColor colorWithRed:23.0/255.0 green:234.0/255.0 blue:166.0/255.0 alpha:0.9]

#define HEADER_VIEW_EXPANDED_HEIGHT 333
#define HEADER_VIEW_CONTRACTED_HEIGHT 69
#define HEADER_VIEW_CONTRACTED_ALPHA 0.9

@interface ILViewController () {
    QBImagePickerController *imagePickerController;
    UINavigationController *navigationController;
}

@end

@implementation ILViewController

bool headerViewExpanded = NO;
NSArray *timeArray;
int timeArrayIdx;
NSTimeInterval oneHour = 60 * 60 * 1;
NSTimeInterval sixHours = 60 * 60 * 6;
NSTimeInterval twelveHours = 60 * 60 * 12;
NSTimeInterval oneDay = 60 * 60 * 24;
NSTimeInterval oneWeek = 60 * 60 * 24 * 7;
NSDate *nextPost;

NSIndexPath *openIndex;

NSThread* thread;
bool threadRunning = NO;
bool restartThread = NO;

UIDocumentInteractionController *docFile;

- (void)viewDidLoad
{
    [super viewDidLoad];
    timeArray = [NSArray arrayWithObjects: @"6 Hours", @"12 Hours", @"Morning", @"Evening", @"Weekend", nil];
    
    self.queue = [[NSMutableArray alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/posts"];
    if([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        NSURL *rootURL = [NSURL URLWithString:dataPath];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:rootURL includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
        for (NSURL *url in dirEnumerator) {
            NSString *path = [url path];
            [self.queue addObject:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
        }
    }
    // Unpack posts
    self.library = [[ALAssetsLibrary alloc] init];
    for (InstaPost *instaPost in self.queue) {
        NSURL *url;
        if(instaPost.videoURL) {
            url = instaPost.videoURL;
        } else {
            url = instaPost.imageURL;
        }
        instaPost.asset = [self assetForURL:url];
        if(instaPost.image == nil) {
            ALAssetRepresentation* representation = [instaPost.asset defaultRepresentation];
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber* orientationValue = [instaPost.asset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil) {
                orientation = [orientationValue intValue];
            }
            CGFloat scale  = 1;
            instaPost.originalImage = [UIImage imageWithCGImage:[representation fullResolutionImage] scale:scale orientation:orientation];
            instaPost.image = [UIImage imageWithCGImage:[representation fullScreenImage]];
        }
    }
    
    [self.tableView.layer setCornerRadius:CORNER_RADIUS];
    [self.headerView.layer setCornerRadius:CORNER_RADIUS];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    [self.collectionView reloadData];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger idx = [defaults integerForKey:@"postTimeIndex"];
    timeArrayIdx = idx;
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];




    //temp
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    if(localNotification != nil) {
        InstaPost *nextPost = [self.queue objectAtIndex:0];
        NSURL *url;
        if(nextPost.videoURL != nil) {
            url = nextPost.videoURL;
        } else {
            url = nextPost.imageURL;
        }
        NSDate *currentDate = [NSDate date];
        NSDate *datePlusOneMinute = currentDate;
        NSDictionary *data = [NSDictionary dictionaryWithObject:[url absoluteString] forKey:@"postURLString"];
        [localNotification setUserInfo:data];
        [localNotification setFireDate:datePlusOneMinute];
        [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
        [localNotification setAlertBody:@"It's time to post!"];
        [localNotification setAlertAction:@"Okay"];
        [localNotification setHasAction:YES];
        [localNotification setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] + 1];
        [localNotification setSoundName:UILocalNotificationDefaultSoundName];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
    

}

- (void)appDidBecomeActive:(NSNotification *)notification {
    NSLog(@"did become active notification");
    
    [self updatePostDates];
    [self.collectionView reloadData];
    
    if(self.backPressed == YES) {
        self.backPressed = NO;
        return;
    }
    
    if(self.queue.count > 0) {
        InstaPost *zeroPost = [self.queue objectAtIndex:0];
        if([zeroPost.postDate compare:[[NSDate alloc] init]] == NSOrderedAscending || [zeroPost.postDate compare:[[NSDate alloc] init]] == NSOrderedSame) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ILPostViewController *postVC = [storyboard instantiateViewControllerWithIdentifier:@"postVC"];
            NSURL *url;
            if(zeroPost.videoURL != nil) {
                url = zeroPost.videoURL;
            } else {
                url = zeroPost.imageURL;
            }
            postVC.urlString = [url absoluteString];
            postVC.modalPresentationStyle = UIModalPresentationFullScreen;
            postVC.mainVC = self;
            [self presentModalViewController:postVC animated:YES];
        }
    }
    
    UIApplication *app = [UIApplication sharedApplication];
    app.applicationIconBadgeNumber = 0;
}

- (void)appDidEnterForeground:(NSNotification *)notification {
    NSLog(@"did enter foreground notification");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self archiveData];
}

-(void)archiveData {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/posts"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:dataPath error:nil];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:nil];
    int i = 0;
    for(InstaPost *post in self.queue) {
        NSString *appFile = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"post%d",i]];
        [NSKeyedArchiver archiveRootObject:post toFile:appFile];
        i++;
    }
}

-(void)animateHeaderView {
    [UIView transitionWithView:self.arrowButton.imageView duration:0.25f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        if(headerViewExpanded) {
            [self.arrowButton setImage:[UIImage imageNamed:@"downarrow"] forState:UIControlStateNormal];
        } else {
            [self.arrowButton setImage:[UIImage imageNamed:@"uparrow"] forState:UIControlStateNormal];
        }
    } completion:NULL];
    
    [UIView animateWithDuration:0.25 animations:^{
        if(headerViewExpanded) {
            // Contract the header view
            self.headerView.alpha = HEADER_VIEW_CONTRACTED_ALPHA;
            self.headerView.frame = CGRectMake(self.headerView.frame.origin.x, self.headerView.frame.origin.y, self.headerView.frame.size.width, HEADER_VIEW_CONTRACTED_HEIGHT);
        } else {
            // Expand the header view
            self.headerView.alpha = 1.0;
            self.headerView.frame = CGRectMake(self.headerView.frame.origin.x, self.headerView.frame.origin.y, self.headerView.frame.size.width, HEADER_VIEW_EXPANDED_HEIGHT);
        }
    } completion:^(BOOL finished) {
        headerViewExpanded = !headerViewExpanded;
    }];
}

-(void) removeZeroPost {
    
}

#pragma mark - UITableViewDataSource methods

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"cell%ld", (long)indexPath.item]];
    return cell;
}

#pragma mark - UITableViewDelegateSource methods

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    timeArrayIdx = indexPath.row;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:timeArrayIdx forKey:@"postTimeIndex"];
    [defaults synchronize];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy HH:mm:ss"];
    NSDate *todayDate = [[NSDate alloc] init];
    NSString *todayString = [dateFormatter stringFromDate:todayDate];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit) fromDate:todayDate];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    NSInteger second = [components second];
    
    NSTimeInterval timeUntil;
    
    NSUInteger weekdayToday = [components weekday];
    NSInteger daysToSaturday = (14 - weekdayToday) % 7;
    
    switch(timeArrayIdx) {
        case 0: // 6 hours
            nextPost = [NSDate dateWithTimeIntervalSinceNow:sixHours];
            break;
        case 1: // 12 hours
            nextPost = [NSDate dateWithTimeIntervalSinceNow:twelveHours];
            break;
        case 2: // Morning
            if(hour >= 9) {
                timeUntil = oneDay - ((hour - 9)*oneHour) - (minute*60) - second;
            } else {
                timeUntil = ((9 - hour)*oneHour) - (minute*60) - second;
            }
            nextPost = [NSDate dateWithTimeIntervalSinceNow:timeUntil];
            break;
        case 3: // Evening
            if(hour >= 18) {
                timeUntil = oneDay - ((hour - 18)*oneHour) - (minute*60) - second;
            } else {
                timeUntil = ((18 - hour)*oneHour) - (minute*60) - second;
            }
            nextPost = [NSDate dateWithTimeIntervalSinceNow:timeUntil];
            break;
        case 4:
            if(hour >= 12) {
                nextPost = [todayDate dateByAddingTimeInterval:(60*60*24*daysToSaturday) - ((hour - 12)*oneHour) - (minute*60) - second];
            }
            else {
                nextPost = [todayDate dateByAddingTimeInterval:(60*60*24*daysToSaturday) + ((12 - hour)*oneHour) - (minute*60) - second];
            }

            break;
        default: break;
    }
    
    /*
    
    int i = 0;
    for(InstaPost *instaPost in self.queue) {
        switch(timeArrayIdx) {
            case 0:
                instaPost.postDate = [nextPost dateByAddingTimeInterval:sixHours*i];
                break;
            case 1:
                instaPost.postDate = [nextPost dateByAddingTimeInterval:twelveHours*i];
                break;
            case 2:
                instaPost.postDate = [nextPost dateByAddingTimeInterval:oneDay*i];
                break;
            case 3:
                instaPost.postDate = [nextPost dateByAddingTimeInterval:oneDay*i];
                break;
            case 4:
                instaPost.postDate = [nextPost dateByAddingTimeInterval:oneWeek*i];
                break;
            default: break;
        }
        i++;
    }
     */
    
    InstaPost *zeroPost = [self.queue objectAtIndex:0];
    zeroPost.postDate = nextPost;
    
    [self updatePostDates];
    
    [self animateHeaderView];
    [self.collectionView reloadData];
    [self archiveData];
}

#pragma mark - UICollectionViewDelegate methods
#define BLUR_VIEW_RECT CGRectMake(0, 0, 279, 22)
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    InstaPostCell *instaPostCell = (InstaPostCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if(CGRectEqualToRect(instaPostCell.blurViewCaption.frame, instaPostCell.imageView.frame)){
        // Removing buttons
        openIndex = nil;
        [UIView animateWithDuration:0.25 animations:^{
            instaPostCell.blurViewCaption.alpha = 0.5;
            instaPostCell.blurViewCaption.backgroundColor = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1.0];
            instaPostCell.tintColor = [UIColor clearColor];
            instaPostCell.blurViewCaption.frame = BLUR_VIEW_RECT;
        } completion:^(BOOL finished) {
            [instaPostCell.blurViewCaption setBlurEnabled:NO];
        }];
    } else {
        // Showing buttons
        openIndex = indexPath;
        [instaPostCell.blurViewCaption setBlurEnabled:YES];
        [instaPostCell.blurViewCaption setDynamic:YES];
        [UIView animateWithDuration:0.25 animations:^{
            instaPostCell.blurViewCaption.alpha = 1.0;
            instaPostCell.blurViewCaption.backgroundColor = [UIColor clearColor];
            instaPostCell.blurViewCaption.frame = instaPostCell.imageView.frame;
        } completion:^(BOOL finished) {
                [instaPostCell.blurViewCaption setDynamic:NO];
        }];
    }
}


#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)theCollectionView numberOfItemsInSection:(NSInteger)theSectionIndex {
    return self.queue.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    InstaPostCell *instaPostCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
    InstaPost *instaPost = [self.queue objectAtIndex:indexPath.item];
    
    if (instaPost.videoURL != nil) {
        // video
        instaPostCell.playButton.hidden = NO;
    } else {
        instaPostCell.playButton.hidden = YES;
    }
    
    [instaPostCell.imageView setImage:instaPost.image];
    
    //Setup button
    instaPostCell.postButton.tag = indexPath.item;
    instaPostCell.removeButton.tag = indexPath.item;
    instaPostCell.playButton.tag = indexPath.item;
    [instaPostCell.postButton addTarget:self action:@selector(postButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [instaPostCell.removeButton addTarget:self action:@selector(removeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [instaPostCell.playButton addTarget:self action:@selector(playButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    [instaPostCell.blurViewCaption setTintColor:[UIColor clearColor]];
    [instaPostCell.blurViewCaption.layer setCornerRadius:CORNER_RADIUS];
    if(openIndex != nil && indexPath.item == openIndex.item) {
        instaPostCell.blurViewCaption.frame = instaPostCell.imageView.frame;
        instaPostCell.blurViewCaption.alpha = 1.0;
        instaPostCell.blurViewCaption.backgroundColor = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1.0];
        [instaPostCell.blurViewCaption setBlurEnabled:YES];
        instaPostCell.blurViewCaption.dynamic = YES;
    } else {
        instaPostCell.blurViewCaption.alpha = 0.5;
        instaPostCell.blurViewCaption.backgroundColor = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1.0];
        instaPostCell.blurViewCaption.frame = BLUR_VIEW_RECT;
        [instaPostCell.blurViewCaption setBlurEnabled:NO];
        instaPostCell.blurViewCaption.dynamic = NO;
    }
    [instaPostCell.imageView.layer setCornerRadius:CORNER_RADIUS];
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:instaPostCell.bounds];
    instaPostCell.layer.masksToBounds = NO;
    instaPostCell.layer.shadowColor = [UIColor blackColor].CGColor;
    instaPostCell.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    instaPostCell.layer.shadowOpacity = 0.5f;
    instaPostCell.layer.shadowPath = shadowPath.CGPath;
    
    /*
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd-yyyy HH:mm:ss"];
    NSString *stringFromDate = [formatter stringFromDate:instaPost.postDate];
     */
    
    // Schedule notification
    NSDate *curDate = [[NSDate alloc] init];
    
    if(indexPath.item == 0 && [instaPost.postDate compare:curDate] == NSOrderedDescending) {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        if(localNotification != nil) {
            NSDate *dateToFire = instaPost.postDate;
            [localNotification setFireDate:dateToFire];
            [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
            NSURL *url;
            if(instaPost.videoURL != nil) {
                url = instaPost.videoURL;
            } else {
                url = instaPost.imageURL;
            }
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
    
    NSString *caption;
    NSTimeInterval timeUntil = [instaPost.postDate timeIntervalSinceDate:curDate];
    if(timeUntil <= 0) {
        caption = @"Post it now!";
    } else {
        int mins = timeUntil/60.0;
        int hours = timeUntil/60.0/60.0;
        int days = timeUntil/60.0/60.0/24.0;

        if(days != 0) {
            NSString *daysString = (days != 1) ? @"days" : @"day";
            NSString *hoursString = ((hours%24) != 1) ? @"hours" : @"hour";
            caption = [NSString stringWithFormat:@"Posting in %d %@, %d %@", days, daysString, hours%24, hoursString];
        } else if(hours != 0) {
            NSString *minsString = ((mins%60) != 1) ? @"mins" : @"min";
            NSString *hoursString = (hours != 1) ? @"hours" : @"hour";
            caption = [NSString stringWithFormat:@"Posting in %d %@, %d %@", hours, hoursString, mins%60, minsString];
        } else {
            NSString *minsString = ((mins) != 1) ? @"mins" : @"min";
            caption = [NSString stringWithFormat:@"Posting in %d %@", mins, minsString];
        }
    }
    instaPostCell.caption.text = caption;
    
    instaPost.caption = @"#PostedWithLaterGram #LaterGram";
    
    instaPostCell.instaPost = instaPost;

    return instaPostCell;
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

-(void) deleteNotificationWithURLString:(NSString *)urlString {
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *eventArray = [app scheduledLocalNotifications];
    for (int i=0; i<[eventArray count]; i++)
    {
        UILocalNotification* oneEvent = [eventArray objectAtIndex:i];
        NSDictionary *userInfoCurrent = oneEvent.userInfo;
        NSString *uniqueString=[NSString stringWithFormat:@"%@",[userInfoCurrent valueForKey:@"postURLString"]];
        if ([uniqueString isEqualToString:urlString])
        {
            //Cancelling local notification
            [app cancelLocalNotification:oneEvent];
            break;
        }
    }
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

-(void)postButtonClicked:(UIButton*)sender
{
    // Post to instagram
    InstaPost *instaPost = [self.queue objectAtIndex:sender.tag];

    if ([[instaPost.asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
        NSString *videopath = [self savedVideoPathForAsset:instaPost.asset];
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
        
        if([instaPost.postDate compare:[[NSDate alloc] init]] == NSOrderedAscending || [instaPost.postDate compare:[[NSDate alloc] init]] == NSOrderedSame) {
            [self removePostAndDontUpdate:0];
        } else {
            [self removeButtonClicked:sender];
        }
    } else {
        NSURL *instagramURL = [NSURL URLWithString:@"instagram://"];
        if ([[UIApplication sharedApplication] canOpenURL:instagramURL])
        {
            UIImage* tempPhotoImage = instaPost.originalImage;
            UIImage* photoImage = [self unrotateImage:tempPhotoImage];
            NSData* imageData = UIImageJPEGRepresentation(photoImage, 1);
            NSString* captionString = instaPost.caption;
            NSString* imagePath = [NSString stringWithFormat:@"%@/instagramShare.igo", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
            [imageData writeToFile:imagePath atomically:NO];
            NSURL* fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"file://%@",imagePath]];
            
            docFile=[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:imagePath]];
            docFile.delegate = self;
            docFile.annotation = [NSDictionary dictionaryWithObject:captionString forKey:@"InstagramCaption"];
            docFile.UTI = @"com.instagram.exclusivegram";
            [docFile presentOpenInMenuFromRect: self.view.frame inView:self.view animated:YES];
            
            if([instaPost.postDate compare:[[NSDate alloc] init]] == NSOrderedAscending || [instaPost.postDate compare:[[NSDate alloc] init]] == NSOrderedSame) {
                [self removePostAndDontUpdate:0];
            } else {
                [self removeButtonClicked:sender];
            }
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
    
    [self collectionView: self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
}

// Helper method to fix orientation issues when exporting to Instagram
- (UIImage *)normalizedImage:(UIImage*)image {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}
- (UIImage*)unrotateImage:(UIImage*)image {
    CGSize size = image.size;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0,size.width ,size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)fixrotation:(UIImage *)image{
    if (image.imageOrientation == UIImageOrientationUp) return image;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformIdentity;
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
    
}

-(void)removeButtonClicked:(UIButton*)sender
{
    // Animate removal from list
    InstaPostCell *instaPostCell = (InstaPostCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    
    NSURL *url;
    InstaPost *instaPost = instaPostCell.instaPost;
    if(instaPost.videoURL != nil) {
        url = instaPost.videoURL;
    } else {
        url = instaPost.imageURL;
    }
    [self deleteNotificationWithURLString:[url absoluteString]];
    
    openIndex = nil;
    
    NSDate *prevDate = instaPost.postDate;
    for(int i = sender.tag + 1; i < self.queue.count; i++) {
        InstaPost *insta = [self.queue objectAtIndex:i];
        NSDate *tempDate = insta.postDate;
        insta.postDate = prevDate;
        prevDate = tempDate;
    }
    
    [self.queue removeObjectAtIndex:sender.tag];
    [self.collectionView reloadData];
    [self archiveData];
}

-(void)removePostAndDontUpdate:(int)index
{
    [self.queue removeObjectAtIndex:index];
    [self.collectionView reloadData];
}

MPMoviePlayerViewController *movieController;
-(void)playButtonClicked:(UIButton*)sender
{
    // Animate removal from list
    InstaPostCell *instaPostCell = (InstaPostCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:instaPostCell.instaPost.videoURL];
    [self presentMoviePlayerViewControllerAnimated:movieController];
    [movieController.moviePlayer play];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 123) {
        NSURL *instagramURL = [NSURL URLWithString:@"instagram://camera"];
        if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
            [[UIApplication sharedApplication] openURL:instagramURL];
        }
    }
}

#pragma mark - LXReorderableCollectionViewDataSource methods

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    InstaPost *zeroPost = [self.queue objectAtIndex:0];
    NSDate *zeroDate = zeroPost.postDate;
    
    InstaPost *instaPost = [self.queue objectAtIndex:fromIndexPath.item];
    
    [self.queue removeObjectAtIndex:fromIndexPath.item];
    [self.queue insertObject:instaPost atIndex:toIndexPath.item];
    
    // Make sure zero date stays accurate.
    zeroPost = [self.queue objectAtIndex:0];
    zeroPost.postDate = zeroDate;
}

-(void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    [self updatePostDates];
    [self.collectionView reloadData];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    return YES;
}

#pragma mark - LXReorderableCollectionViewDelegateFlowLayout methods

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"will begin drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did begin drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"will end drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did end drag");
}

#pragma mark - Button pressed methods

- (IBAction)arrowButtonPressed:(id)sender {
    [self animateHeaderView];
}

- (IBAction)plusButtonPressed:(id)sender {
    if (![QBImagePickerController isAccessible]) {
        NSLog(@"Error: Source is not accessible.");
        return;
    }
    
    imagePickerController = [[QBImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.navigationController.delegate = self;
    imagePickerController.allowsMultipleSelection = YES;
    
    navigationController = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
    navigationController.navigationBar.barTintColor = ACCENT_COLOR;
    navigationController.navigationBar.tintColor = [UIColor whiteColor];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"GillSans-Light" size:24],NSFontAttributeName, [UIColor whiteColor], NSForegroundColorAttributeName, nil];
    [navigationController.navigationBar setTitleTextAttributes:attributes];
    [self presentViewController:navigationController animated:YES completion:NULL];
}

#pragma mark - QBImagePickerControllerDelegate

- (void)dismissImagePickerController
{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [self.navigationController popToViewController:self animated:YES];
    }
}

- (void)imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets
{
    NSLog(@"*** imagePickerController:didSelectAssets:");
    NSLog(@"%@", assets);
    
    for (id asset in assets) {
        InstaPost *instaPost = [[InstaPost alloc] init];
        instaPost.asset = asset;
        if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            ALAssetRepresentation* representation = [asset defaultRepresentation];
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil) {
                orientation = [orientationValue intValue];
            }
            CGFloat scale  = 1;
            instaPost.originalImage = [UIImage imageWithCGImage:[representation fullResolutionImage] scale:scale orientation:orientation];
            instaPost.image = [UIImage imageWithCGImage:[representation fullScreenImage]];
            instaPost.videoURL = [[asset defaultRepresentation] url];
            instaPost.imageURL = nil;
        } else {
            ALAssetRepresentation* representation = [asset defaultRepresentation];
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil) {
                orientation = [orientationValue intValue];
            }
            CGFloat scale  = 1;
            instaPost.originalImage = [UIImage imageWithCGImage:[representation fullResolutionImage] scale:scale orientation:orientation];
            instaPost.image = [UIImage imageWithCGImage:[representation fullScreenImage]];
            instaPost.videoURL = nil;
            instaPost.imageURL = [[asset defaultRepresentation] url];
        }
        
        [self.queue addObject:instaPost];
    }
    
    [self updatePostDates];
    
    [self.collectionView reloadData];
    
    [self dismissImagePickerController];
}

-(void) updatePostDates {
    NSDate *latestDate;
    // Init latest date based on timeArrayIdx
    switch(timeArrayIdx) {
        case 0:
            latestDate = [[[NSDate alloc] init] dateByAddingTimeInterval:sixHours];
            break;
        case 1:
            latestDate = [[[NSDate alloc] init] dateByAddingTimeInterval:twelveHours];
            break;
        case 2:
            latestDate = [[[NSDate alloc] init] dateByAddingTimeInterval:oneDay];
            break;
        case 3:
            latestDate = [[[NSDate alloc] init] dateByAddingTimeInterval:oneDay];
            break;
        case 4:
            latestDate = [[[NSDate alloc] init] dateByAddingTimeInterval:oneWeek];
            break;
        default: break;
    }
    
    int i = 0;
    for(InstaPost *instaPost in self.queue) {
        NSDate *curDate = [[NSDate alloc] init];
        if(i == 0) {
            if(instaPost.postDate == nil) {
                instaPost.postDate = latestDate;
            }
            else if([instaPost.postDate compare:curDate] == NSOrderedAscending) {
                instaPost.postDate = curDate;
            }
            latestDate = instaPost.postDate;
            i++;
            continue;
        }
        
        // Otherwise
        switch(timeArrayIdx) {
            case 0:
                instaPost.postDate = [latestDate dateByAddingTimeInterval:sixHours*i];
                break;
            case 1:
                instaPost.postDate = [latestDate dateByAddingTimeInterval:twelveHours*i];
                break;
            case 2:
                instaPost.postDate = [latestDate dateByAddingTimeInterval:oneDay*i];
                break;
            case 3:
                instaPost.postDate = [latestDate dateByAddingTimeInterval:oneDay*i];
                break;
            case 4:
                instaPost.postDate = [latestDate dateByAddingTimeInterval:oneWeek*i];
                break;
            default: break;
        }
        i++;
    }

}

- (void)imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    NSLog(@"*** imagePickerControllerDidCancel:");
    [self dismissImagePickerController];
}

#pragma mark - UIScrollViewControllerDelegate

/* Implement later
InstaPostCell *prevMiddleCell;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    InstaPostCell *middleCell = nil;
    int minDiff = 1000; // big
    for(InstaPostCell *instaPostCell in self.collectionView.visibleCells) {
        if(instaPostCell.player == nil) continue;
        int diff = ABS(instaPostCell.center.y - self.view.center.y);
        if(diff < minDiff) {
            minDiff = diff;
            middleCell = instaPostCell;
        }
    }
    if(middleCell != nil && middleCell.instaPost.videoURL != prevMiddleCell.instaPost.videoURL) {
        [self.collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:[self.collectionView indexPathForCell:middleCell]]];
        prevMiddleCell = middleCell;
    }
}
 */

@end
