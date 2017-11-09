//
//  UIImageView+HMCImageCacheExtension.m
//  HMCImageCache
//
//  Created by Huỳnh Minh Chương on 11/4/17.
//

#import "UIImageView+HMCImageCacheExtension.h"
#import "HMCImageCache.h"
#import <objc/runtime.h>

@implementation UIImageView(HMCImageCache)

static NSString *normalKey = @"_caching_normal_image_key";
static NSString *highlightedKey = @"_caching_highlighted_image_key";
static NSString *sizeOfUrlKey = @"_caching_image_size";

- (NSString *)getNormalCachedImageKey {
    return objc_getAssociatedObject(self, &normalKey);
}

- (NSString *)getHighlightedCachedImageKey {
    return objc_getAssociatedObject(self, &highlightedKey);
}

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
    
    if (self.frame.size.height == 0 && self.frame.size.width == 0) {
        return;
    }
    
    // Choosing target size
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        CGSize targetSize = self.frame.size;
        CGSize originSize = [self getSizeOfUrl:url];
        if (targetSize.height * targetSize.width > originSize.height * originSize.width && originSize.height > 0 && originSize.width > 0) {
            targetSize.height = originSize.height;
            targetSize.width = originSize.width;
        }
        
        [HMCImageCache.sharedInstance imageFromURL:url
                                    withTargetSize:targetSize
                                        completion:^(UIImage *image, NSString *key) {
                                            if (state == UIControlStateNormal) {
                                                
                                                objc_setAssociatedObject(self, &normalKey, key, OBJC_ASSOCIATION_RETAIN);
                                                [self setImage:image];
                                            } else {
                                                
                                                objc_setAssociatedObject(self, &highlightedKey, key, OBJC_ASSOCIATION_RETAIN);
                                                [self setHighlightedImage:image];
                                            }
                                        } callbackQueue:dispatch_get_main_queue()];
    });
    
}

@end
