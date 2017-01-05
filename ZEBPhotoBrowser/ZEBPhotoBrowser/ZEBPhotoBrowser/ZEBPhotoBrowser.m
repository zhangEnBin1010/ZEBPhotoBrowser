//
//  ZEBPhotoBrowser.m
//  ZEBPhotoBrowser
//
//  Created by mac on 17/1/5.
//  Copyright (c) 2016年 zeb. All rights reserved.
//

#import "ZEBPhotoBrowser.h"
#import "ZEBPhotoBrowserCell.h"
#import "ZEB_const.h"
#import "ZEBToast.h"
#import <UIImageView+WebCache.h>
#import "Photo.h"

@interface ZEBPhotoBrowser () <UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,ZEBPhotoBrowserCellDelegate> {
    CGRect _endTempFrame;
    NSInteger _currentPage;
    NSIndexPath *_zoomingIndexPath;
    BOOL _imageDidLoaded;
    BOOL _animationCompleted;
}

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *tmpImageView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *toolBar;
@property (nonatomic, weak) UILabel *countLab;
@property (nonatomic, strong) NSMutableArray *URLStrings;
@property (nonatomic) NSInteger index;
@property (nonatomic) NSInteger imagesCount;
@property (nonatomic, copy) DismissBlock dismissDlock;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, weak) NSArray *dataArray;
@property (nonatomic, strong) SDWebImageManager *shareManager;
@end

@implementation ZEBPhotoBrowser

- (void)dealloc {
    self.collectionView.delegate = nil; 
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)showFromImageView:(UIImageView *)imageView withURLStrings:(NSArray *)dataArray placeholderImage:(UIImage *)image atIndex:(NSInteger)index dismiss:(DismissBlock)block {
    ZEBPhotoBrowser *browser = [[ZEBPhotoBrowser alloc] initWithFrame:kScreenRect];
    browser.imageView = imageView;
    browser.dataArray = dataArray;
    browser.imagesCount = dataArray.count;
    [browser resetCountLabWithIndex:index+1];
    [browser configureBrowser];
    [browser animateImageViewAtIndex:index];
    browser.placeholderImage = image;
    browser.dismissDlock = block;
    
    return browser;
}


+ (instancetype)showFromImageView:(UIImageView *)imageView withImages:(NSArray *)images atIndex:(NSInteger)index dismiss:(DismissBlock)block {
    ZEBPhotoBrowser *browser = [[ZEBPhotoBrowser alloc] initWithFrame:kScreenRect];
    browser.imageView = imageView;
    browser.images = images;
    browser.imagesCount = images.count;
    [browser resetCountLabWithIndex:index+1];
    [browser configureBrowser];
    [browser animateImageViewAtIndex:index];
    browser.dismissDlock = block;
    
    return browser;
}

+ (instancetype)showFromImageView:(UIImageView *)imageView withURLStrings:(NSArray *)dataArray atIndex:(NSInteger)index {

    return [self showFromImageView:imageView withURLStrings:dataArray placeholderImage:nil atIndex:index dismiss:nil];
}

+ (instancetype)showFromImageView:(UIImageView *)imageView withImages:(NSArray *)images atIndex:(NSInteger)index {
    return [self showFromImageView:imageView withImages:images atIndex:index dismiss:nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        [self addSubview:self.collectionView];
        
        [self setupToolBar];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadForScreenRotate) name:UIDeviceOrientationDidChangeNotification object:nil];
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoCellDidZooming:) name:kPhotoCellDidZommingNotification object:nil];
        
    }
    return self;
}
- (SDWebImageManager *)shareManager {
    if (!_shareManager) {
        _shareManager = [SDWebImageManager sharedManager];
    }
    return _shareManager;
}
- (NSMutableArray *)URLStrings {
    if (!_URLStrings) {
        _URLStrings = [NSMutableArray array];
    }
    return _URLStrings;
}
#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = 0;
    if (self.URLStrings.count > 0) {
        count = _URLStrings.count;
    }
    else if (self.images) {
        count = _images.count;
    }
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZEBPhotoBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoBrowserCellID forIndexPath:indexPath];
    cell.indexPath = indexPath;
    [cell resetZoomingScale];
    __weak __typeof(self) wself = self;
    cell.tapActionBlock = ^(UITapGestureRecognizer *sender) {
        [wself dismiss];
    };
    
    if (self.URLStrings.count > 0) {
        Photo *photo = self.URLStrings[indexPath.row];
        cell.photo = photo;
        cell.delegate = self;
        NSURL *url = nil;
        if (photo.original) {
            if (photo.isDownload) {
                url = [NSURL URLWithString:photo.originalUrl];
            }else {
                url = [NSURL URLWithString:photo.thumbnailUrl];
            }
        }else {
            url = [NSURL URLWithString:photo.thumbnailUrl];
        }
        if (indexPath.row != _index) {
            [cell.imageView sd_setImageWithURL:url placeholderImage:_placeholderImage];
        }
        else {
            UIImage *placeHolder = _tmpImageView.image;
            [cell.imageView sd_setImageWithURL:url placeholderImage:placeHolder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                
                if (!_imageDidLoaded) {
                    _imageDidLoaded = YES;
                    if (_animationCompleted) {
                        self.collectionView.hidden = NO;
                        [_tmpImageView removeFromSuperview];
                        _animationCompleted = NO;
                    }
                    
                }
                
            }];
        }
    }
    else if (self.images) {
        cell.imageView.image = self.images[indexPath.row];
    }

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return kScreenRect.size;
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _currentPage = scrollView.contentOffset.x/kScreenWidth + 0.5;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_currentPage inSection:0];
    ZEBPhotoBrowserCell *cell = (ZEBPhotoBrowserCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell.btnShow) {
        [cell hideOriginalPhotoButton];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _currentPage = scrollView.contentOffset.x/kScreenWidth + 0.5;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_currentPage inSection:0];
    ZEBPhotoBrowserCell *cell = (ZEBPhotoBrowserCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell.photo.original) {
        
    }
    if (cell.btnShow) {
      [cell showOriginalPhotoButton];
    }
    
    _countLab.text = [NSString stringWithFormat:@"%zd/%zd",_currentPage+1,_imagesCount];
    
    if (_zoomingIndexPath) {
       [self.collectionView reloadItemsAtIndexPaths:@[_zoomingIndexPath]];
        _zoomingIndexPath = nil;
    }
    
}

#pragma mark - notification handler

- (void)reloadForScreenRotate {
     _collectionView.frame = kScreenRect;
   
    [self.collectionView reloadData];
    self.collectionView.contentOffset = CGPointMake(kScreenWidth * _currentPage,0);
}

- (void)photoCellDidZooming:(NSNotification *)nofit {
    NSIndexPath *indexPath = nofit.object;
    _zoomingIndexPath = indexPath;
}

#pragma mark - getter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        
        _collectionView = [[UICollectionView alloc]initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.hidden = YES;
        _collectionView.pagingEnabled = YES;
        _collectionView.showsHorizontalScrollIndicator = NO;
        
    }
    return _collectionView;
}

#pragma mark - private 

- (void)configureBrowser {
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[ZEBPhotoBrowserCell class] forCellWithReuseIdentifier:kPhotoBrowserCellID];
    
    [[UIApplication sharedApplication].keyWindow addSubview:self];
}

- (void)setupToolBar {
//    _toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-38, self.frame.size.width, 30)];
//    _toolBar.backgroundColor = [UIColor clearColor];
  //  [self addSubview:_toolBar];
    
    UILabel *countLab = [[UILabel alloc] initWithFrame:CGRectMake(8, self.frame.size.height-38, 100, 30)];
    countLab.textColor = [UIColor whiteColor];
    countLab.layer.cornerRadius = 2;
    countLab.layer.masksToBounds = YES;
    countLab.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.4];
    countLab.font = [UIFont systemFontOfSize:13];
    countLab.textAlignment = NSTextAlignmentCenter;
    [self addSubview:countLab];
    _countLab = countLab;
    
//    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    saveBtn.frame = CGRectMake(_toolBar.frame.size.width-58, 1, 50, 28);
//    saveBtn.layer.cornerRadius = 2;
//    [saveBtn setBackgroundColor:[[UIColor blackColor]colorWithAlphaComponent:0.4]];
//    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
//    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    saveBtn.titleLabel.font = [UIFont systemFontOfSize:13];
//    [saveBtn addTarget:self action:@selector(saveImae) forControlEvents:UIControlEventToucZEBpInside];
//    [self addSubview:saveBtn];
    
}
- (void)animateImageViewAtIndex:(NSInteger)index {
    _index = index;
    CGRect startFrame = [self.imageView.superview convertRect:self.imageView.frame toView:[UIApplication sharedApplication].keyWindow];
    CGRect endFrame = kScreenRect;
    
    if (self.imageView.image) {
        UIImage *image = self.imageView.image;
        CGFloat ratio = image.size.width / image.size.height;
        
        if (ratio > kScreenRatio) {
            
            endFrame.size.width = kScreenWidth;
            endFrame.size.height = kScreenWidth / ratio;
            
        } else {
            endFrame.size.height = kScreenHeight;
            endFrame.size.width = kScreenHeight * ratio;
            
        }
        endFrame.origin.x = (kScreenWidth - endFrame.size.width) / 2;
        endFrame.origin.y = (kScreenHeight - endFrame.size.height) / 2;
        
    }
    
    _endTempFrame = endFrame;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
#endif
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:startFrame];
    tempImageView.image = self.imageView.image;
    tempImageView.contentMode = UIViewContentModeScaleAspectFit;
    [[UIApplication sharedApplication].keyWindow addSubview:tempImageView];
    _tmpImageView = tempImageView;
    
    if (self.URLStrings.count>0 && !self.images) {
        Photo *photo = self.URLStrings[_index];
        
        NSString *key = [self.shareManager cacheKeyForURL:[NSURL URLWithString:photo.thumbnailUrl]];
        UIImage *image = [[self.shareManager imageCache] imageFromMemoryCacheForKey:key];
        if (image) {
            image = [[self.shareManager imageCache] imageFromDiskCacheForKey:key];
        }
        _imageDidLoaded = image != nil;
    }
    [self.collectionView setContentOffset:CGPointMake(kScreenWidth * index,0) animated:NO];
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        tempImageView.frame = endFrame;
        
    } completion:^(BOOL finished) {
        _currentPage = index;
        _animationCompleted = YES;
        if (self.images || _imageDidLoaded || (self.URLStrings.count>0 && !_imageDidLoaded)) {
            self.collectionView.hidden = NO;
            [tempImageView removeFromSuperview];
            _animationCompleted = NO;
        }
        
    }];
    
    
}

- (void)dismiss {
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#endif
    
    if (self.dismissDlock) {
        ZEBPhotoBrowserCell *cell = (ZEBPhotoBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_currentPage inSection:0]];
        self.dismissDlock(cell.imageView.image, _currentPage);
    }
    
    if (_currentPage != _index) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            
            [self removeFromSuperview];
        }];
        return;
    }
    
    CGRect endFrame = [self.imageView.superview convertRect:self.imageView.frame toView:[UIApplication sharedApplication].keyWindow];
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:_endTempFrame];
    tempImageView.image = self.imageView.image;
    tempImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.collectionView.hidden = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:tempImageView];
    
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        tempImageView.frame = endFrame;
        self.alpha = 0;
    } completion:^(BOOL finished) {
        if (self.shareManager.isRunning) {
            [self.shareManager cancelAll];
        }
        [self removeFromSuperview];
        [tempImageView removeFromSuperview];
        
    }];
    
}

- (void)resetCountLabWithIndex:(NSInteger)index {
    
    NSString *text = [NSString stringWithFormat:@"%zd%zd",_imagesCount,_imagesCount];
    CGFloat width = [text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]}].width+8;
    _countLab.frame = CGRectMake(8, self.frame.size.height-38, MAX(50, width), 28);
    _countLab.text = [NSString stringWithFormat:@"%zd/%zd",index,_imagesCount];
}

- (void)saveImae {
    ZEBPhotoBrowserCell *cell = (ZEBPhotoBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_currentPage inSection:0]];
    UIImage *seavedImage = cell.imageView.image;
    if (seavedImage) {
         UIImageWriteToSavedPhotosAlbum(seavedImage, self, @selector(imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
    }
   
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
  
    NSString *msg = nil ;
    if(error != nil){
        msg = @"保存图片失败";
    }
    else{
        msg = @"保存图片成功";
    }
    [ZEBToast showToastWithMsg:msg];
}
#pragma mark -
#pragma mark ZEBPhotoBrowserCellDelegate
- (void)zebPhotoBrowserCellOriginalImage:(ZEBPhotoBrowserCell *)cell photo:(Photo *)photo {
    
    photo.isLoading = YES;
    [self.shareManager downloadImageWithURL:[NSURL URLWithString:photo.originalUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        photo.progress = receivedSize;
        NSLog(@"----------%ld--------%ld",receivedSize,expectedSize);
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        photo.isLoading = NO;
        if (image) {
          [self.shareManager saveImageToCache:image forURL:[NSURL URLWithString:photo.originalUrl]];
           photo.isDownload = YES;
           [cell hideOriginalPhotoButton];
          [self.collectionView reloadData];
        }
    }];
}
- (void)zebPhotoBrowserCellLongPress:(ZEBPhotoBrowserCell *)cell photo:(Photo *)photo image:(UIImage *)image {
    
}
#pragma mark -
#pragma mark  photomodel

- (void)setDataArray:(NSArray *)dataArray {
    _dataArray = dataArray;
    [self initTZEBmbnailModel];
}
- (void)initTZEBmbnailModel {
    [self.URLStrings removeAllObjects];
    for (id dict in self.dataArray) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            NSDictionary *parm = (NSDictionary *)dict;
            Photo *photo = [[Photo alloc] init];
            photo.thumbnailUrl = parm[@"thumbnailUrl"];
            photo.originalUrl = parm[@"originalUrl"];
            photo.size = parm[@"size"];
            [self.URLStrings addObject:photo];
        }else {
            NSLog(@"出错了，这里需要一个字典!");
        }
    }
    [self.collectionView reloadData];
}
@end
