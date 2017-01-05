//
//  ZEBPhotoBrowser.h
//  ZEBPhotoBrowser
//
//  Created by zeb－Apple on 17/1/5.
//  Copyright © 2017年 zeb. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ __nullable DismissBlock)(UIImage * __nullable image, NSInteger index);

@interface ZEBPhotoBrowser : UIView

/*
 * @param imageView    点击的imageView
 * @param URLStrings   加载的网络图片的urlString 
 [{originalUrl:@"",thumbnailUrl:@"",size:@""},{originalUrl:@"",thumbnailUrl:@"",size:@""}]
 * @param index        点击的图片在所有要展示图片中的位置
 */

+ (nonnull instancetype)showFromImageView:(nullable UIImageView *)imageView withURLStrings:(nullable NSArray *)dataArray atIndex:(NSInteger)index;

/*
 * @param imageView    点击的imageView
 * @param withImages   加载的本地图片
 * @param index        点击的图片在所有要展示图片中的位置
 */

+ (nonnull instancetype)showFromImageView:(nullable UIImageView *)imageView withImages:(nullable NSArray *)images atIndex:(NSInteger)index;

/*
 * @param imageView    点击的imageView
 * @param URLStrings   加载的网络图片的urlString
 [{originalUrl:@"",thumbnailUrl:@"",size:@""},{originalUrl:@"",thumbnailUrl:@"",size:@""}]
 * @param image        占位图片
 * @param index        点击的图片在所有要展示图片中的位置
 * @param dismiss      photoBrowser消失的回调
 */
+ (nonnull instancetype)showFromImageView:(nullable UIImageView *)imageView withURLStrings:(nullable NSArray *)dataArray placeholderImage:(nullable UIImage *)image atIndex:(NSInteger)index dismiss:(DismissBlock)block;

/*
 * @param imageView    点击的imageView
 * @param withImages   加载的本地图片
 * @param image        占位图片
 * @param index        点击的图片在所有要展示图片中的位置
 * @param dismiss      photoBrowser消失的回调
 */
+ (nonnull instancetype)showFromImageView:(nullable UIImageView *)imageView withImages:(nullable NSArray *)images atIndex:(NSInteger)index dismiss:(DismissBlock)block;

@property (nonatomic, strong, nullable) UIImage *placeholderImage;

@end
