//
//  ZEBPhotoBrowserCell.m
//  ZEBPhotoBrowserCell
//
//  Created by zeb－Apple on 17/1/5.
//  Copyright © 2017年 zeb. All rights reserved.
//

#import "ZEBPhotoBrowserCell.h"
#import "ZEB_const.h"
#import <UIImageView+WebCache.h>
#import "Photo.h"

@interface ZEBPhotoBrowserCell () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic,strong) UITapGestureRecognizer *doubleTap;
@property (nonatomic,strong) UITapGestureRecognizer *singleTap;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, weak) UIButton *OriginalPhotoButton;  // 查看原图
@property (nonatomic, strong) UIView *loadingView;  // 加载的图片
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicatorView;
@end

@implementation ZEBPhotoBrowserCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        [self setupView];
        [self addGestureRecognizer:self.singleTap];
        [self addGestureRecognizer:self.doubleTap];
        [self addGestureRecognizer:self.longPress];
    }
    return self;
}

- (void)setupView {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.maximumZoomScale = 2;
    _scrollView.minimumZoomScale = 0.5;
    _scrollView.delegate = self;

    [self addSubview:_scrollView];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.userInteractionEnabled = YES;
    [_scrollView addSubview:imageView];
    _imageView = imageView;
    
    CGFloat w = 110;
    CGFloat h = 20;
    
    UIButton *OriginalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    OriginalPhotoButton.frame = CGRectMake(CGRectGetWidth(self.frame)/2-w/2, CGRectGetHeight(self.frame)-h-10, w, h);
    [OriginalPhotoButton setTitle:@"查看原图" forState:UIControlStateNormal];
    [OriginalPhotoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    OriginalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:12];
    OriginalPhotoButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [OriginalPhotoButton addTarget:self action:@selector(OriginalPhotoBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:OriginalPhotoButton];
    
    
    self.OriginalPhotoButton = OriginalPhotoButton;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:OriginalPhotoButton.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(2.5, 2.5)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];
    //设置大小
    maskLayer.frame = OriginalPhotoButton.bounds;
    //设置图形样子
    maskLayer.path = maskPath.CGPath;
    OriginalPhotoButton.layer.mask = maskLayer;
    
    CAShapeLayer *borderLayer=[CAShapeLayer layer];
    borderLayer.path    =   maskPath.CGPath;
    borderLayer.fillColor  = [UIColor clearColor].CGColor;
    borderLayer.strokeColor    = [UIColor whiteColor].CGColor;
    borderLayer.lineWidth      = 0.5;
    [OriginalPhotoButton.layer addSublayer:borderLayer];
    OriginalPhotoButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    
    
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.loadingView.center = self.center;
    self.loadingView.userInteractionEnabled = NO;
    self.loadingView.backgroundColor = [UIColor blackColor];
    self.loadingView.hidden = YES;
    self.loadingView.alpha = 0.6;
    [self addSubview:self.loadingView];
    UIBezierPath *maskloadingPath = [UIBezierPath bezierPathWithRoundedRect:self.loadingView.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(5, 5)];
    CAShapeLayer *maskloadingLayer = [[CAShapeLayer alloc]init];
    //设置大小
    maskloadingLayer.frame = self.loadingView.bounds;
    //设置图形样子
    maskloadingLayer.path = maskloadingPath.CGPath;
    self.loadingView.layer.mask = maskloadingLayer;
    
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];//指定进度轮的大小
    aiv.center = CGPointMake(CGRectGetWidth(self.loadingView.frame)/2, CGRectGetHeight(self.loadingView.frame)/2-10);
    [aiv setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];//设置进度轮显示类型
    CGAffineTransform transform = CGAffineTransformMakeScale(.7f, .7f);
    aiv.transform = transform;
    [self.loadingView addSubview:aiv];
    self.activityIndicatorView = aiv;
    
    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(aiv.frame)+5, CGRectGetWidth(self.loadingView.frame)-20, 30)];
    loadingLabel.text = @"下载中...";
    loadingLabel.textColor = [UIColor whiteColor];
    loadingLabel.backgroundColor = [UIColor clearColor];
    loadingLabel.font = [UIFont systemFontOfSize:10];
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    [self.loadingView addSubview:loadingLabel];
   
    
}
- (void)setPhoto:(Photo *)photo {
    _photo = photo;
    [self reloadCell];
}
- (void)reloadCell {
    if (_photo.original) {
        if (_photo.isDownload) {
            self.OriginalPhotoButton.alpha = 0;
            self.btnShow = NO;
        }else{
            self.OriginalPhotoButton.alpha = 1;
            self.btnShow = YES;
        }
    }else {
        self.OriginalPhotoButton.alpha = 0;
        self.btnShow = NO;
    }
    if (_photo.isLoading) {
        [self.activityIndicatorView startAnimating];
        self.loadingView.hidden = NO;
    }else {
        [self.activityIndicatorView stopAnimating];
        self.loadingView.hidden = YES;
    }
    NSInteger photoSize = [_photo.size integerValue];
    NSString *title = [NSString stringWithFormat:@"查看原图 (%@)",[self transformDataLength:photoSize]];
    [self.OriginalPhotoButton setTitle:title forState:UIControlStateNormal];
}

- (NSString *)transformDataLength:(NSInteger)dataLength {
    NSString *bytes = @"";
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%.2fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%.1fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB",dataLength];
    }
    return bytes;
}
#pragma mark -
#pragma mark OriginalPhotoButton
- (void)hideOriginalPhotoButton {
    [UIView animateWithDuration:0.3 animations:^{
        self.OriginalPhotoButton.alpha = 0.0;
    } completion:^(BOOL finished) {
        
    }];
}
- (void)showOriginalPhotoButton {
    [UIView animateWithDuration:0.3 animations:^{
        self.OriginalPhotoButton.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)resetZoomingScale {
    
    if (self.scrollView.zoomScale !=1) {
         self.scrollView.zoomScale = 1;
    }
   
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _scrollView.frame = self.bounds;
    _imageView.frame = _scrollView.bounds;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    self.imageView.center = [self centerOfScrollViewContent:scrollView];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [[NSNotificationCenter defaultCenter] postNotificationName:kPhotoCellDidZommingNotification object:_indexPath];
}

#pragma mark - gesture handler

- (void)doubleTapGestrueHandle:(UITapGestureRecognizer *)sender {
    CGPoint p = [sender locationInView:self];
    if (self.scrollView.zoomScale <=1.0) {
        CGFloat scaleX = p.x + self.scrollView.contentOffset.x;
        CGFloat scaley = p.y + self.scrollView.contentOffset.y;
        [self.scrollView zoomToRect:CGRectMake(scaleX, scaley, 10, 10) animated:YES];
    }
    else {
        [self.scrollView setZoomScale:1.0 animated:YES];
    }
}

- (void)singleTapGestrueHandle:(UITapGestureRecognizer *)sender {
    if (self.tapActionBlock) {
        self.tapActionBlock(sender);
    }
    
}

#pragma mark - private

- (CGPoint)centerOfScrollViewContent:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    CGPoint actualCenter = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                       scrollView.contentSize.height * 0.5 + offsetY);
    return actualCenter;
}


#pragma mark - getter

- (UILongPressGestureRecognizer *)longPress {
    if (!_longPress) {
        _longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(LongPressToDO:)];
        _longPress.numberOfTouchesRequired=1;
        _longPress.minimumPressDuration=1.0;
    }
    return _longPress;
}
- (UITapGestureRecognizer *)doubleTap {
    if (!_doubleTap) {
        _doubleTap  =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestrueHandle:)];
        _doubleTap.numberOfTapsRequired = 2;
        _doubleTap.numberOfTouchesRequired = 1;
    }
    return _doubleTap;
}

- (UITapGestureRecognizer *)singleTap {
    if (!_singleTap) {
        _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestrueHandle:)];
        _singleTap.numberOfTapsRequired = 1;
        _singleTap.numberOfTouchesRequired = 1;
        [_singleTap requireGestureRecognizerToFail:self.doubleTap];
    }
    return _singleTap;
}
- (void)LongPressToDO:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state==UIGestureRecognizerStateBegan) {
        if (_delegate && [_delegate respondsToSelector:@selector(zebPhotoBrowserCellLongPress:photo:image:)]) {
            [_delegate zebPhotoBrowserCellLongPress:self photo:self.photo image:self.imageView.image];
        }
                
    }
}
- (void)OriginalPhotoBtn:(UIButton *)btn {
    [self.activityIndicatorView startAnimating];
    self.loadingView.hidden = NO;;
    if (_delegate && [_delegate respondsToSelector:@selector(zebPhotoBrowserCellOriginalImage:photo:)]) {
        [_delegate zebPhotoBrowserCellOriginalImage:self photo:self.photo];
    }
}
@end
