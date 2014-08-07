//
//  InstaPostCell.h
//  InstaLater
//
//  Created by Kyle Dillon on 7/16/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InstaPost.h"
#import <MediaPlayer/MediaPlayer.h>
#import "FXBlurView.h"

@class InstaPost;

@interface InstaPostCell : UICollectionViewCell

@property (strong, nonatomic) InstaPost *instaPost;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *caption;
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (weak, nonatomic) IBOutlet FXBlurView *blurViewCaption;
@property (weak, nonatomic) IBOutlet UIButton *postButton;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end
