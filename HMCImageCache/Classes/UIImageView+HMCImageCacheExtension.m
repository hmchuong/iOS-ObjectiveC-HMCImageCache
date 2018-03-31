//
//  UIImageView+HMCImageCacheExtension.m
//  HMCImageCache
//
//  Created by Huỳnh Minh Chương on 11/4/17.
//

#import "UIImageView+HMCImageCacheExtension.h"
#import "HMCImageCache.h"
#import <objc/runtime.h>
#import "HMCDownloadManager.h"

@implementation UIImageView(HMCImageCache)

static NSString *normalKey = @"_caching_normal_image_key";
static NSString *highlightedKey = @"_caching_highlighted_image_key";
static NSString *sizeOfUrlKey = @"_caching_image_size";
static NSString *urlNormalKey = @"_caching_image_url";
static NSString *urlHighlightedKey = @"_caching_highlighted_url";

- (NSString *)getNormalCachedImageKey {
    return objc_getAssociatedObject(self, &normalKey);
}

- (NSString *)getHighlightedCachedImageKey {
    return objc_getAssociatedObject(self, &highlightedKey);
}

- (NSURL *)getCurrentNormalImageUrl {
    return objc_getAssociatedObject(self, &urlNormalKey);
}

- (void)setCurrentNormalImageUrl:(NSURL *)url {
    objc_setAssociatedObject(self, &urlNormalKey, url, OBJC_ASSOCIATION_RETAIN);
}

- (NSURL *)getCurrentHighlightedImageUrl {
    return objc_getAssociatedObject(self, &urlHighlightedKey);
}

- (void)setCurrentHighlightedImageUrl:(NSURL *)url {
    objc_setAssociatedObject(self, &urlHighlightedKey, url, OBJC_ASSOCIATION_RETAIN);
}

/**
 Get size of image from url

 @param url url to get size
 @return size of image from url
 */
- (CGSize)getSizeOfUrl:(NSURL *)url {
    
    NSMutableDictionary *sizes = objc_getAssociatedObject(self, &sizeOfUrlKey);
    if (sizes == nil || sizes[url.absoluteString] == nil) {
        CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
        if (source == nil) {
            return CGSizeMake(-1, -1);
        }
        NSDictionary* imageHeader = (__bridge NSDictionary*) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
        CGFloat height = [[imageHeader objectForKey:@"PixelHeight"] floatValue];
        CGFloat width = [[imageHeader objectForKey:@"PixelWidth"] floatValue];
        CGSize size = CGSizeMake(width, height);
        [self setSize:size ofUrl:url];
        return size;
    }
    NSArray *size = sizes[url.absoluteString];
    return CGSizeMake([(NSNumber *)size[0] floatValue], [(NSNumber *)size[1] floatValue]);
}

/**
 store size of image with url

 @param size size to store
 @param url url of size
 */
- (void)setSize:(CGSize)size ofUrl:(NSURL *)url {
    
    NSMutableDictionary *sizes = objc_getAssociatedObject(self, &sizeOfUrlKey);
    if (sizes == nil) {
        sizes = [[NSMutableDictionary alloc] init];
    }
    [sizes setValue:[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:size.width], [NSNumber numberWithFloat:size.height], nil] forKey:url.absoluteString];
    objc_setAssociatedObject(self, &sizeOfUrlKey, sizes, OBJC_ASSOCIATION_RETAIN);
}

- (void)HMCSetImageFromURL:(NSURL *)url
                  forState:(UIControlState)state{
    
    if (state == UIControlStateNormal) {
        NSURL *currentUrl = [self getCurrentNormalImageUrl];
        if (currentUrl != NULL && currentUrl.absoluteString == url.absoluteString) {
            [HMCDownloadManager.sharedBackgroundManager pauseDownload:currentUrl];
        }
        [self setCurrentNormalImageUrl:url];
    } else {
        NSURL *currentUrl = [self getCurrentHighlightedImageUrl];
        if (currentUrl != NULL && currentUrl.absoluteString == url.absoluteString) {
            [HMCDownloadManager.sharedBackgroundManager pauseDownload:currentUrl];
        }
        [self setCurrentHighlightedImageUrl:url];
    }
    
    NSString *key = [HMCImageCache.sharedInstance sanitizeFileNameString:url.absoluteString];
    if (state == UIControlStateNormal) {
        
        objc_setAssociatedObject(self, &normalKey, key, OBJC_ASSOCIATION_RETAIN);
    } else {
        
        objc_setAssociatedObject(self, &highlightedKey, key, OBJC_ASSOCIATION_RETAIN);
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [HMCImageCache.sharedInstance imageFromURL:url
                                    withTargetSize:^CGSize{
                                        CGSize __block size;
                                        if (![NSThread isMainThread]) {
                                            dispatch_sync(dispatch_get_main_queue(), ^{
                                                size = self.frame.size;
                                            });
                                        } else {
                                            size = self.frame.size;
                                        }
                                        return size;
                                    } completion:^(UIImage *image, NSString *key) {
                                        if (state == UIControlStateNormal) {
                                            NSString *currentKey = [self getNormalCachedImageKey];
                                            if ([key containsString:currentKey]) {
                                                objc_setAssociatedObject(self, &normalKey, key, OBJC_ASSOCIATION_RETAIN);
                                                [self setImage:image];
                                            } else {
                                                NSLog(key);
                                            }
                                                
                                        } else {
                                            NSString *currentKey = [self getHighlightedCachedImageKey];
                                            if ([key containsString:currentKey]) {
                                                objc_setAssociatedObject(self, &highlightedKey, key, OBJC_ASSOCIATION_RETAIN);
                                                [self setHighlightedImage:image];
                                            } else {
                                                NSLog(key);
                                            }
                                        }
                                    } callbackQueue:dispatch_get_main_queue()];
    });
    
}

@end
