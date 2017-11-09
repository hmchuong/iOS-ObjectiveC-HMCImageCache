//
//  UIButton+HMCImageCacheExtension.m
//  HMCImageCache
//
//  Created by Huỳnh Minh Chương on 11/4/17.
//

#import "UIButton+HMCImageCacheExtension.h"
#import "HMCImageCache.h"
#import <objc/runtime.h>

@implementation UIButton(HMCImageCache)

- (void)HMCSetImageFromURL:(NSURL *)url
                  forState:(UIControlState)state {
    
    if (self.frame.size.height == 0 && self.frame.size.width == 0) {
        return;
    }
    // Choosing target size
    CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    NSDictionary* imageHeader = (__bridge NSDictionary*) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    CGFloat height = [[imageHeader objectForKey:@"PixelHeight"] floatValue];
    CGFloat width = [[imageHeader objectForKey:@"PixelWidth"] floatValue];
    CGSize targetSize = self.frame.size;
    
    if (targetSize.height * targetSize.width > height * width) {
        targetSize.height = height;
        targetSize.width = width;
    }
    [HMCImageCache.sharedInstance imageFromURL:url
                                withTargetSize:self.frame.size
                                    completion:^(UIImage *image, NSString *key) {
                                        [self setImage:image
                                              forState:state];
                                        objc_setAssociatedObject(self, @"_caching_image_key", key, OBJC_ASSOCIATION_RETAIN);
                                    } callbackQueue:dispatch_get_main_queue()];
}

@end
