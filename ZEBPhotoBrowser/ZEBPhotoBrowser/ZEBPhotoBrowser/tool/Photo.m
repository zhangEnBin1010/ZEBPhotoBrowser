//
//  Photo.m
//  ZEBPhotoBrowserCell Demo
//
//  Created by zeb－Apple on 17/1/5.
//  Copyright © 2017年 zeb. All rights reserved.
//

#import "Photo.h"
#import <UIImageView+WebCache.h>

@implementation Photo


- (void)setOriginalUrl:(NSString *)originalUrl {
    _originalUrl = originalUrl;
    if (![[self isNullToString:_originalUrl] isEqualToString:@""]) {
        _original = YES;
    }
    _isDownload = [self hasDownLoad];
}


- (BOOL)hasDownLoad {
    BOOL ret = NO;
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    if ([manager cachedImageExistsForURL:[NSURL URLWithString:[manager cacheKeyForURL:[NSURL URLWithString:self.originalUrl]]]]) {
        ret = YES;
    }
    return ret;
}
- (NSString *)isNullToString:(id)string
{
    if ([string isEqual:@"NULL"] || [string isKindOfClass:[NSNull class]] || [string isEqual:[NSNull null]] || [string isEqual:NULL] || [[string class] isSubclassOfClass:[NSNull class]] || string == nil || string == NULL || [string isKindOfClass:[NSNull class]] || [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]==0 || [string isEqualToString:@"<null>"] || [string isEqualToString:@"(null)"])
    {
        return @"";
        
    }else
    {
        
        return (NSString *)string;
    }
}

@end
