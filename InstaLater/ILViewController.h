//
//  ILViewController.h
//  InstaLater
//
//  Created by Kyle Dillon on 7/16/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LXReorderableCollectionViewFlowLayout.h"
#import "FXBlurView.h"
#import "QBImagePickerController.h"

@interface ILViewController : UIViewController <UICollectionViewDelegate, LXReorderableCollectionViewDataSource,LXReorderableCollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, QBImagePickerControllerDelegate, UIScrollViewDelegate, UIDocumentInteractionControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *queue;
@property (strong, nonatomic) ALAssetsLibrary *library;

- (IBAction)arrowButtonPressed:(id)sender;
- (IBAction)plusButtonPressed:(id)sender;

@property (weak, nonatomic) IBOutlet FXBlurView *headerView;

@end
