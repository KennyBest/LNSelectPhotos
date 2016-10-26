//
//  LNAlbumTableViewController.h
//  
//
//  Created by llj on 16/10/18.
//  Copyright © 2016年 llj. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LNAlbumTableViewController;

@protocol LNAlbumTableViewControllerDelegate <NSObject>

@required
- (void)selectedImages:(NSArray *)images viewController:(LNAlbumTableViewController *)controller;

@end

/// 相册列表
@interface LNAlbumTableViewController : UITableViewController

@property (nonatomic, weak) id<LNAlbumTableViewControllerDelegate> delegate;

@end
