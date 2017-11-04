//
//  UIButton+HMCImageCacheExtension.h
//  HMCImageCache
//
//  Created by Huỳnh Minh Chương on 11/4/17.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIButton(HMCImageCache)

/**
 Download, cache and set image to UIButton
 
 @param url url to download image
 */
- (void)HMCSetImageFromURL:(NSURL *) url
                     forState:(UIControlState)state;

@end
