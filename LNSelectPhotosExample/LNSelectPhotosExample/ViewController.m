//
//  ViewController.m
//  LNSelectPhotosExample
//
//  Created by llj on 16/10/26.
//  Copyright © 2016年 llj. All rights reserved.
//

#import "ViewController.h"
#import "LNAlbumTableViewController.h"
#import "LNAssetCollectionViewCell.h"

@interface ViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LNAlbumTableViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray *imagesArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.imagesArray = [NSMutableArray array];
    [self.collectionView registerNib:[UINib nibWithNibName:@"LNAssetCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"LNAssetCollectionViewCell"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectPhotos:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Select Photos" message:@"choose type" preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"From Camera" style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"From Photo Libary" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //        [alertController dismissViewControllerAnimated:YES completion:nil];
        LNAlbumTableViewController *vc = [[LNAlbumTableViewController alloc] init];
        vc.delegate = self;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark --

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imagesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LNAssetCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LNAssetCollectionViewCell" forIndexPath: indexPath];
    cell.selectedBtn.hidden = YES;
    
    if (self.imagesArray.count > indexPath.row) {
        cell.thumbnailImage = self.imagesArray[indexPath.row];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((self.view.frame.size.width - 2) / 3, (self.view.frame.size.width - 2) / 3);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 1;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1;
}


#pragma mark --  LNAlbumTableViewControllerDelegate

///获取到所选的照片
- (void)selectedImages:(NSArray *)images viewController:(LNAlbumTableViewController *)controller {
    [self.imagesArray addObjectsFromArray:images];
    [self.collectionView reloadData];
}

@end
