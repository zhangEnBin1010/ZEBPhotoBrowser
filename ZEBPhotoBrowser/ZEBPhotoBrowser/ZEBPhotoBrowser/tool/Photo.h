//
//  Photo.h
//  ZEBPhotoBrowser Demo
//
//  Created by zeb－Apple on 17/1/5.
//  Copyright © 2017年 zeb. All rights reserved.
//  图片model

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Photo : NSObject

@property (nonatomic, copy) NSString *originalUrl;  // 原图url
@property (nonatomic, copy) NSString *thumbnailUrl; // 缩略图url

@property (nonatomic, assign) BOOL isLoading;  // 是否在下载
@property (nonatomic, assign) NSInteger progress; // 下载进度

@property (nonatomic, assign) BOOL original; // 是否有原图

@property (nonatomic, copy) NSString *size; // 原图图片大小

@property (nonatomic, assign) BOOL isDownload; // 原图是否被下载

@property (nonatomic, weak) UIImage *image; // 图片

@end
