//
//  InstaPost.m
//  InstaLater
//
//  Created by Kyle Dillon on 7/16/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "InstaPost.h"

@implementation InstaPost

-(void)encodeWithCoder:(NSCoder *)encoder{
    //[encoder encodeObject:self.image forKey:@"image"];
    //[encoder encodeObject:self.originalImage forKey:@"originalImage"];
    [encoder encodeObject:self.videoURL forKey:@"videoURL"];
    [encoder encodeObject:self.imageURL forKey:@"imageURL"];
    [encoder encodeObject:self.postDate forKey:@"postDate"];
    [encoder encodeObject:self.caption forKey:@"caption"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        //self.image = [decoder decodeObjectForKey:@"image"];
        //self.originalImage = [decoder decodeObjectForKey:@"originalImage"];
        self.videoURL = [decoder decodeObjectForKey:@"videoURL"];
        self.imageURL = [decoder decodeObjectForKey:@"imageURL"];
        self.postDate = [decoder decodeObjectForKey:@"postDate"];
        self.caption = [decoder decodeObjectForKey:@"caption"];
    }
    return self;
}

@end
