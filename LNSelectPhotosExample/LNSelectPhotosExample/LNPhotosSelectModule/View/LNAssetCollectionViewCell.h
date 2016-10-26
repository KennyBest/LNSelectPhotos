//
//  LNAssetCollectionViewCell.h
//  UsePhotosDemo
//
//  Created by llj on 16/10/18.
//  Copyright © 2016年 llj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LNAssetCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImage *thumbnailImage;

@property (copy, nonatomic) NSString *represntAssetIdentifier;

@property (weak, nonatomic) IBOutlet UIButton *selectedBtn;

- (void)updateSelectedButtonImage:(BOOL)selected;

@end
