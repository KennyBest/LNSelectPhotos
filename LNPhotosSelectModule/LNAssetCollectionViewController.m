//
//  LNAssetCollectionViewController.m
//  
//
//  Created by llj on 16/10/18.
//  Copyright © 2016年 llj. All rights reserved.
//

#import "LNAssetCollectionViewController.h"
#import "LNAssetCollectionViewCell.h"


@interface UICollectionView (Photos)
- (NSArray<NSIndexPath *>*)indexPathsForElements:(CGRect)rect;
@end

@implementation UICollectionView (Photos)
- (NSArray<NSIndexPath *> *)indexPathsForElements:(CGRect)rect {
    NSArray *layoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attribute in layoutAttributes) {
        [indexPaths addObject:attribute.indexPath];
    }
    return [indexPaths copy];
}
@end

@interface LNAssetCollectionViewController ()
@property (nonatomic) PHCachingImageManager *imageManager;
@property (nonatomic, assign) CGSize thumbnailSize;
@property (nonatomic, assign) CGRect previousPreheatRect;
@property (nonatomic, strong) NSMutableArray *selectedAssets;

///Bottom Opertaion Button Bar
@property (nonatomic, strong) UIToolbar *toolBar;
@end

@implementation LNAssetCollectionViewController {
    NSMutableArray *_addedRect, *_removedRect;
}

static NSString * const reuseIdentifier = @"LNAssetCollectionViewCell";

- (NSMutableArray *)selectedAssets {
    if (!_selectedAssets) {
        _selectedAssets = [NSMutableArray array];
    }
    return _selectedAssets;
}

- (UIToolbar *)toolBar {
    if (!_toolBar) {
        _toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 44, CGRectGetWidth(self.view.frame), 44)];
        //占位item
        UIBarButtonItem *fixedSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *confirmBtn = [[UIBarButtonItem alloc] initWithTitle:@"确认" style:UIBarButtonItemStylePlain target:self action:@selector(confirmSelectedImage:)];
        _toolBar.items = @[fixedSpaceItem, confirmBtn];
    }
    return _toolBar;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    self.collectionView.allowsMultipleSelection = YES;
    [self.collectionView registerNib:[UINib nibWithNibName:@"LNAssetCollectionViewCell" bundle:nil]forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    
    // add buttom toolBar
    [self.view addSubview:self.toolBar];
    
    // set dismiss right navigation item
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeSelectImageModule)];
    
    //change Photo collectionView frame
    self.collectionView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 44);
    
    self.imageManager = [[PHCachingImageManager alloc] init];
    [self resetCachedAssets];
    
    if (!self.fetchResult) {
        self.fetchResult = [PHAsset fetchAssetsWithOptions:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self resetCachedAssets];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize cellSize = [(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout itemSize];
    self.thumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateCachedAssets];
}


#pragma mark --  Private Method

- (void)resetCachedAssets {
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    //只在view加载出来后才更新
    if (!self.isViewLoaded || self.view.window == nil) {
        return;
    }
    
    //预热window（预加载图层）的高度是可见frame高度的两倍
    CGRect preheatRect = CGRectInset(self.view.bounds, 0, -0.5 * self.view.bounds.size.height);
    
    //只有当可见区域和上一次预加载区域不同时才更新
    CGFloat delta = fabs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta <= self.view.bounds.size.height / 3) {
        return;
    }
    
    //推测开始缓存和结束缓存时的assets
    [self differenceBetweenRectsWithOldRect:_previousPreheatRect newRect:preheatRect];
    NSMutableArray<PHAsset *> *addedAssets = @[].mutableCopy;
    NSMutableArray<PHAsset *> *removedAssets = @[].mutableCopy;
    [_addedRect enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect rect = CGRectFromString(obj);
        //根据rect获取indexPath
        NSArray *cellIndexPaths = [self.collectionView indexPathsForElements:rect];
        for (NSIndexPath *indexPath in cellIndexPaths) {
            [addedAssets addObject:[self.fetchResult objectAtIndex:indexPath.item]];
        }
    }];
    [_removedRect enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect rect = CGRectFromString(obj);
        //根据rect获取indexPath
        NSArray *cellIndexPaths = [self.collectionView indexPathsForElements:rect];
        for (NSIndexPath *indexPath in cellIndexPaths) {
            [removedAssets addObject:[self.fetchResult objectAtIndex:indexPath.item]];
        }
    }];
    
    //更新assets
    [self.imageManager startCachingImagesForAssets:addedAssets targetSize:self.thumbnailSize contentMode:PHImageContentModeAspectFill options:nil];
    [self.imageManager stopCachingImagesForAssets:removedAssets targetSize:self.thumbnailSize contentMode:PHImageContentModeAspectFill options:nil];
    
    //
    self.previousPreheatRect = preheatRect;

}

- (void)differenceBetweenRectsWithOldRect:(CGRect)oldRect newRect:(CGRect)newRect{
    //判断两者是否有交叉
    if (CGRectIntersectsRect(oldRect, newRect)) {
        _addedRect = [NSMutableArray array];
        if (CGRectGetMaxY(newRect) > CGRectGetMaxY(oldRect)) {
            CGRect rect = CGRectMake(newRect.origin.x, CGRectGetMaxY(oldRect), newRect.size.width, CGRectGetMaxY(newRect) - CGRectGetMaxY(oldRect));
            [_addedRect addObject:NSStringFromCGRect(rect)];
        }
        if (CGRectGetMinY(oldRect) > CGRectGetMinY(newRect)) {
            CGRect rect = CGRectMake(newRect.origin.x, CGRectGetMinY(newRect), newRect.size.width, CGRectGetMinY(oldRect) - CGRectGetMinY(newRect));
            [_addedRect addObject:NSStringFromCGRect(rect)];
        }
        
        _removedRect = [NSMutableArray array];
        if (CGRectGetMaxY(newRect) < CGRectGetMaxY(oldRect)) {
            CGRect rect = CGRectMake(newRect.origin.x, CGRectGetMaxY(newRect), newRect.size.width, CGRectGetMaxY(oldRect) - CGRectGetMaxY(newRect));
            [_removedRect addObject:NSStringFromCGRect(rect)];
        }
        if (CGRectGetMinY(oldRect) < CGRectGetMinY(newRect)) {
            CGRect rect = CGRectMake(newRect.origin.x, CGRectGetMinY(oldRect), newRect.size.width, CGRectGetMinY(newRect) - CGRectGetMinY(oldRect));
            [_removedRect addObject:NSStringFromCGRect(rect)];
        }
    } else {
        _addedRect = @[NSStringFromCGRect(newRect)].mutableCopy;
        _removedRect = @[NSStringFromCGRect(oldRect)].mutableCopy;
    }
}


#pragma mark --  确认选择的照片

- (void)confirmSelectedImage:(UIBarButtonItem *)sender {
    NSMutableArray *images = @[].mutableCopy;
    
    for (PHAsset *asset in self.selectedAssets) {
       [self.imageManager requestImageForAsset:asset targetSize:self.thumbnailSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            [images addObject:result];
        }];
    }
    
    if (self.confirmSelectedImagesBlock && images.count > 0) {
        self.confirmSelectedImagesBlock(images.copy);
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

///关闭选择照片组件
- (void)closeSelectImageModule {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.fetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LNAssetCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    PHAsset *asset = self.fetchResult[indexPath.row];
    cell.represntAssetIdentifier = asset.localIdentifier;
    [self.imageManager requestImageForAsset:asset
                                 targetSize:self.thumbnailSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                        if ([cell.represntAssetIdentifier isEqualToString:asset.localIdentifier]) {
                                             cell.thumbnailImage = result;
                                        }
                                    }];
    cell.selectedBtn.tag = indexPath.row;
    [cell.selectedBtn addTarget: self action:@selector(selectedBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self refreshSelectedAssetCellAtIndexPath:indexPath];
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

- (void)refreshSelectedAssetCellAtIndexPath:(NSIndexPath *)indexPath {
    LNAssetCollectionViewCell *cell = (LNAssetCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    
    BOOL isContain = [self.selectedAssets containsObject:self.fetchResult[indexPath.item]];
    if (isContain) {
        [self.selectedAssets removeObject:self.fetchResult[indexPath.item]];
    } else {
        [self.selectedAssets addObject:self.fetchResult[indexPath.item]];
    }
    
    [cell updateSelectedButtonImage:!isContain];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateCachedAssets];
}


#pragma mark --  选择按钮事件

- (void)selectedBtnClicked:(UIButton *)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
    [self refreshSelectedAssetCellAtIndexPath:indexPath];
}
@end
