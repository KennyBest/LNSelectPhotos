//
//  LNAssetCollectionViewController.h
//  
//
//  Created by llj on 16/10/18.
//  Copyright © 2016年 llj. All rights reserved.
//
@import Photos;

#import <UIKit/UIKit.h>

@interface LNAssetCollectionViewController : UICollectionViewController

@property (nonatomic, strong) PHFetchResult<PHAsset *> *fetchResult;

/// confirm button click callback
@property (nonatomic, copy) void(^confirmSelectedImagesBlock)(NSArray *images);

@end
