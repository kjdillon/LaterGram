//
//  InstaPost.h
//  InstaLater
//
//  Created by Kyle Dillon on 7/16/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QBImagePickerController.h"

@interface InstaPost : NSObject <NSCoding>

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImage *originalImage;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) NSString *caption;
@property (strong, nonatomic) NSDate *postDate;
@property (strong, nonatomic) ALAsset *asset;

@end
