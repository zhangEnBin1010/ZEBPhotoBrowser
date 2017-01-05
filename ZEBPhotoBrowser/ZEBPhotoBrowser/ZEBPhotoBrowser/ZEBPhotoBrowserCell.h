//
//  ZEBPhotoBrowserCell.h
//  ZEBPhotoBrowserCell
//
//  Created by zeb－Apple on 17/1/5.
//  Copyright © 2017年 zeb. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZEBPhotoBrowserCell,Photo;

#define kPhotoBrowserCellID @"ZEBPhotoBrowserCell"
static NSString * const kPhotoCellDidZommingNotification = @"kPhotoCellDidZommingNotification";
static NSString * const kPhotoCellDidImageLoadedNotification = @"kPhotoCellDidImageLoadedNotification";

@protocol ZEBPhotoBrowserCellDelegate <NSObject>

- (void)zebPhotoBrowserCellOriginalImage:(ZEBPhotoBrowserCell *)cell photo:(Photo *)photo;
- (void)zebPhotoBrowserCellLongPress:(ZEBPhotoBrowserCell *)cell photo:(Photo *)photo image:(UIImage *)image;

@end

@interface ZEBPhotoBrowserCell : UICollectionViewCell

@property (nonatomic, weak) id<ZEBPhotoBrowserCellDelegate> delegate;

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) Photo *photo;
@property (nonatomic, assign) BOOL btnShow; // 查看原图的状态

//@property (nonatomic, strong) UIImage *placeholderImage;

@property (nonatomic, strong) NSIndexPath *indexPath;


- (void)resetZoomingScale;

//- (void)configureCellWithURLStrings:(NSString *)URLStrings;

@property (nonatomic, copy) void(^tapActionBlock)(UITapGestureRecognizer *tapGesture);


- (void)hideOriginalPhotoButton;
- (void)showOriginalPhotoButton;
@end
