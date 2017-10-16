//
//  HMCSystemHelper.h
//  HMCImageCache
//
//  Created by chuonghuynh on 8/14/17.
//  Copyright © 2017 Chương M. Huỳnh. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Utilities for reading system information
 */
@interface HMCSystemHelper : NSObject

/**
 Get free RAM memory at current time

 @return free memory in bytes
 */
+ (unsigned long)getFreeMemory;

@end
