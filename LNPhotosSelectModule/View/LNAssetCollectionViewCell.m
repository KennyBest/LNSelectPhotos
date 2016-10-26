//
//  LNAssetCollectionViewCell.m
//  UsePhotosDemo
//
//  Created by llj on 16/10/18.
//  Copyright © 2016年 llj. All rights reserved.
//

#import "LNAssetCollectionViewCell.h"

@interface LNAssetCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation LNAssetCollectionViewCell

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    self.imageView.image = thumbnailImage;
}

- (IBAction)selectBtnClicked:(UIButton *)sender {
    
}

- (void)updateSelectedButtonImage:(BOOL)selected {
    NSString *imageName = selected ? @"icon_image_yes" : @"icon_image_no";
    [self.selectedBtn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}
@end
