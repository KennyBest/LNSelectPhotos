//
//  LNAlbumTableViewController.m
//  
//
//  Created by llj on 16/10/18.
//  Copyright © 2016年 llj. All rights reserved.
//

@import Photos;

@interface LNCollection : NSObject
@property (copy, nonatomic) NSString *title;
@property (strong, nonatomic) UIImage *shownImage;
@property (strong, nonatomic) PHFetchResult<PHAsset *> *fetchResult;
@end

@implementation LNCollection

@end

#import "LNAlbumTableViewController.h"
#import "LNAssetCollectionViewController.h"

@interface LNAlbumTableViewController ()

/// 用户自定义相册
@property (nonatomic, strong) PHFetchResult<PHCollection *> *usersAlbums;
///所有照片
@property (nonatomic, strong) PHFetchResult<PHAsset *> *allPhotos;
///照片流
@property (nonatomic, strong) PHAssetCollection *cameraRollCollectionPhotos;

@property (nonatomic, strong) NSMutableArray *collectionArray;
@property (nonatomic) CGSize targetSize;

@property (nonatomic, strong) LNAssetCollectionViewController *assetVC;
@end

static NSString *const reuseIdentifier = @"assetCell";

@implementation LNAlbumTableViewController

- (NSMutableArray *)collectionArray {
    if (!_collectionArray) {
        _collectionArray = [NSMutableArray array];
    }
    return _collectionArray;
}

- (CGSize)targetSize {
    if (CGSizeEqualToSize(CGSizeZero, _targetSize)) {
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGSize targetSize = CGSizeMake(80 * scale, 80 * scale);
        _targetSize = targetSize;
    }
    return _targetSize;
}

- (LNAssetCollectionViewController *)assetVC {
    if (!_assetVC) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake((self.view.frame.size.width - 2) / 3, (self.view.frame.size.width - 2) / 3);
        flowLayout.minimumLineSpacing = 1;
        flowLayout.minimumInteritemSpacing = 1;
        LNAssetCollectionViewController *assetVC = [[LNAssetCollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
        _assetVC = assetVC;
    }
    return _assetVC;
}

#pragma mark --  Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    ///初始时默认全部照片
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake((self.view.frame.size.width - 2) / 3, (self.view.frame.size.width - 2) / 3);
    flowLayout.minimumLineSpacing = 1;
    flowLayout.minimumInteritemSpacing = 1;
    LNAssetCollectionViewController *assetVC = [[LNAssetCollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
    assetVC.confirmSelectedImagesBlock = ^(NSArray *images){
        if ([self.delegate respondsToSelector:@selector(selectedImages:viewController:)]) {
            [self.delegate performSelector:@selector(selectedImages:viewController:) withObject:images withObject:self];
        }
    };
    assetVC.fetchResult = self.allPhotos;
    [self.navigationController pushViewController:assetVC animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
   
    [self configurePhotos];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {

}

#pragma mark --  Private Method

- (void)setupUI {
    //cell分割线至左
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    //导航关闭按钮
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeSelectPhotosModule:)];
    self.navigationItem.rightBarButtonItem = closeItem;
}

//获取资源
- (void)configurePhotos {
    self.usersAlbums = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    self.allPhotos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    PHFetchResult<PHAssetCollection *> *smartCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    self.cameraRollCollectionPhotos = [smartCollections objectAtIndex:0];
    
    //用户自己建的相册
    for (PHCollection *collection in self.usersAlbums) {
        [self genertateCollectionDictionaryWithCollection:collection];
    }
    //照片流
    [self genertateCollectionDictionaryWithCollection:self.cameraRollCollectionPhotos];
    //全部照片
    [[PHImageManager defaultManager] requestImageForAsset:[self.allPhotos lastObject] targetSize:self.targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        LNCollection *tmpCollection = [[LNCollection alloc] init];
        tmpCollection.title = @"相机胶卷";
        tmpCollection.shownImage = result;
        tmpCollection.fetchResult = self.allPhotos;
        [self.collectionArray addObject:tmpCollection];
    }];
}

- (void)genertateCollectionDictionaryWithCollection:(PHCollection *)collection{
    //PHCollection 转化为 PHAssetCollection
    PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    //获取最后一张
    PHAsset *asset = [fetchResult lastObject];
    //Photos框架 不能直接从PHAsset获取图片 通过PHImageManager以请求的方式拉取
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:self.targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        NSString *title = assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary ? @"我的照片流" : collection.localizedTitle;
        LNCollection *tmpCollection = [[LNCollection alloc] init];
        tmpCollection.title = title;
        tmpCollection.shownImage = result;
        tmpCollection.fetchResult = fetchResult;
        [self.collectionArray addObject:tmpCollection];
    }];
}

- (void)closeSelectPhotosModule:(UIBarButtonItem *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.collectionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    LNCollection *obj = self.collectionArray[indexPath.row];
    cell.textLabel.text = obj.title;
    cell.imageView.image = obj.shownImage;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LNCollection *obj = self.collectionArray[indexPath.row];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake((self.view.frame.size.width - 2) / 3, (self.view.frame.size.width - 2) / 3);
    flowLayout.minimumLineSpacing = 1;
    flowLayout.minimumInteritemSpacing = 1;
    LNAssetCollectionViewController *assetVC = [[LNAssetCollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
    assetVC.fetchResult = obj.fetchResult;
    [self.navigationController pushViewController:assetVC animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
}

@end
