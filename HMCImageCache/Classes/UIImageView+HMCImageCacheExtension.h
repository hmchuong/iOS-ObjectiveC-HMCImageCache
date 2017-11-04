//
//  UIImageView+HMCImageCacheExtension.h
//  HMCImageCache
//
//  Created by Huỳnh Minh Chương on 11/4/17.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIImageView(HMCImageCache)

/**
 Download, cache and set image to UIImageView
 
 @param url url to download image
 */
- (void)HMCSetImageFromURL:(NSURL *) url;

@end
