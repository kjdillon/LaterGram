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
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>

#define CORNER_RADIUS 5.0f
#define ACCENT_COLOR [UIColor colorWithRed:23.0/255.0 green:234.0/255.0 blue:166.0/255.0 alpha:0.9]

@interface ILViewController ()

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
    timeArrayIdx = 0;
    
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
    }
    
    [self.tableView.layer setCornerRadius:CORNER_RADIUS];
    [self.headerView.layer setCornerRadius:CORNER_RADIUS];
    
    [self.collectionView reloadData];
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
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
    timeArrayIdx = indexPath.item;
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
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDelegate methods
#define BLUR_VIEW_RECT CGRectMake(0, 0, 279, 22)
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    InstaPostCell *instaPostCell = (InstaPostCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if(CGRectEqualToRect(instaPostCell.blurViewCaption.frame, instaPostCell.imageView.frame)){
        openIndex = nil;
        [UIView animateWithDuration:0.25 animations:^{
            instaPostCell.blurViewCaption.alpha = 0.5;
            instaPostCell.blurViewCaption.backgroundColor = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1.0];
            instaPostCell.blurViewCaption.frame = BLUR_VIEW_RECT;
        } completion:^(BOOL finished) {
            [instaPostCell.blurViewCaption setBlurEnabled:NO];
            //[self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
        }];
    } else {
        openIndex = indexPath;
        [instaPostCell.blurViewCaption setBlurEnabled:YES];
        instaPostCell.blurViewCaption.dynamic = YES;
        [UIView animateWithDuration:0.25 animations:^{
            instaPostCell.blurViewCaption.alpha = 1.0;
            instaPostCell.blurViewCaption.backgroundColor = [UIColor clearColor];
            instaPostCell.blurViewCaption.frame = instaPostCell.imageView.frame;
        } completion:^(BOOL finished) {
            instaPostCell.blurViewCaption.dynamic = NO;
            //[self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
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
    
    if(instaPost.image == nil) {
        instaPost.image = [UIImage imageWithCGImage:[[instaPost.asset defaultRepresentation] fullScreenImage]];
        instaPost.originalImage = [UIImage imageWithCGImage:[[instaPost.asset defaultRepresentation] fullResolutionImage]];
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
    
    switch(timeArrayIdx) {
        case 0:
            instaPost.postDate = [nextPost dateByAddingTimeInterval:sixHours*(indexPath.item)];
            break;
        case 1:
            instaPost.postDate = [nextPost dateByAddingTimeInterval:twelveHours*(indexPath.item)];
            break;
        case 2:
            instaPost.postDate = [nextPost dateByAddingTimeInterval:oneDay*(indexPath.item)];
            break;
        case 3:
            instaPost.postDate = [nextPost dateByAddingTimeInterval:oneDay*(indexPath.item)];
            break;
        case 4:
            instaPost.postDate = [nextPost dateByAddingTimeInterval:oneWeek*(indexPath.item)];
            break;
        default: break;
    }
    /*
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd-yyyy HH:mm:ss"];
    NSString *stringFromDate = [formatter stringFromDate:instaPost.postDate];
     */
    
    // Schedule notification
    /*
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    if(localNotification != nil) {
        NSDate *date = [NSDate date];
        NSDate *dateToFire = [date dateByAddingTimeInterval:60];
        [localNotification setFireDate:dateToFire];
        [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
        NSDictionary *data = [NSDictionary dictionaryWithObject:instaPost forKey:@"post"];
        [localNotification setUserInfo:data];
        [localNotification setAlertBody:@"It's time to post!" ];
        [localNotification setAlertAction:@"Okay"];
        [localNotification setHasAction:YES];
        [localNotification setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] + 1];
        [localNotification setSoundName:UILocalNotificationDefaultSoundName];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
     */
    
    
    NSDate *curDate = [[NSDate alloc] init];
    NSTimeInterval timeUntil = [instaPost.postDate timeIntervalSinceDate:curDate];
    int mins = timeUntil/60.0;
    int hours = timeUntil/60.0/60.0;
    int days = timeUntil/60.0/60.0/24.0;
    NSString *caption;
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
        caption = [NSString stringWithFormat:@"Posting in %d minutes %@", mins, minsString];
    }
    instaPostCell.caption.text = caption;
    
    instaPost.caption = @"#PostedWithLaterGram #LaterGram";
    
    instaPostCell.instaPost = instaPost;

    return instaPostCell;
}

-(void)postButtonClicked:(UIButton*)sender
{
    // Post to instagram
    NSURL *instagramURL = [NSURL URLWithString:@"instagram://"];
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL])
    {
        InstaPost *instaPost = [self.queue objectAtIndex:sender.tag];
        UIImage* photoImage = instaPost.originalImage;
        NSData* imageData = UIImagePNGRepresentation(photoImage);
        NSString* captionString = instaPost.caption;
        NSString* imagePath = [NSString stringWithFormat:@"%@/instagramShare.igo", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
        [imageData writeToFile:imagePath atomically:NO];
        NSURL* fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"file://%@",imagePath]];
        
        docFile=[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:imagePath]];
        docFile.delegate = self;
        docFile.annotation = [NSDictionary dictionaryWithObject:captionString forKey:@"InstagramCaption"];
        docFile.UTI = @"com.instagram.exclusivegram";
        [docFile presentOpenInMenuFromRect: self.view.frame inView:self.view animated:YES];
    }
    else
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Instagram Not Installed"
                                                          message:@"Please install Instagram."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }
    
}

-(void)removeButtonClicked:(UIButton*)sender
{
    // Animate removal from list
    InstaPostCell *instaPostCell = (InstaPostCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:sender.tag inSection:0]];
    openIndex = nil;
    [self.queue removeObjectAtIndex:sender.tag];
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

#pragma mark - LXReorderableCollectionViewDataSource methods

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    InstaPost *instaPost = [self.queue objectAtIndex:fromIndexPath.item];
    
    [self.queue removeObjectAtIndex:fromIndexPath.item];
    [self.queue insertObject:instaPost atIndex:toIndexPath.item];
}

-(void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
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

#define HEADER_VIEW_EXPANDED_HEIGHT 333
#define HEADER_VIEW_CONTRACTED_HEIGHT 69
#define HEADER_VIEW_CONTRACTED_ALPHA 0.9
- (IBAction)arrowButtonPressed:(id)sender {
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

- (IBAction)plusButtonPressed:(id)sender {
    /*
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.navigationBar.barTintColor = ACCENT_COLOR;
        imagePicker.navigationBar.tintColor = [UIColor whiteColor];
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"GillSans-Light" size:24],NSFontAttributeName, [UIColor whiteColor], NSForegroundColorAttributeName, nil];
        [imagePicker.navigationBar setTitleTextAttributes:attributes];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = @[(NSString *) kUTTypeImage];
        imagePicker.allowsEditing = YES;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
     */
    
    if (![QBImagePickerController isAccessible]) {
        NSLog(@"Error: Source is not accessible.");
        return;
    }
    QBImagePickerController *imagePickerController = [[QBImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.navigationController.delegate = self;
    imagePickerController.allowsMultipleSelection = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
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
            instaPost.image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
            instaPost.originalImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]];
            instaPost.videoURL = [[asset defaultRepresentation] url];
            instaPost.imageURL = nil;
        } else {
            instaPost.image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
            instaPost.originalImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]];
            instaPost.videoURL = nil;
            instaPost.imageURL = [[asset defaultRepresentation] url];
        }
        [self.queue addObject:instaPost];
    }
    [self.collectionView reloadData];
    [self dismissImagePickerController];
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
