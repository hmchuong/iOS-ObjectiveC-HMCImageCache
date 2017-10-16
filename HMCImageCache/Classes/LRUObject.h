//
//  LRUObject.h
//  HMCImageCache
//
//  Created by chuonghuynh on 8/14/17.
//  Copyright © 2017 Chương M. Huỳnh. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Object stored in LRU cache
 */
@interface LRUObject : NSObject

@property (strong, nonatomic, readonly) NSString *key;      // key of object
@property (strong, nonatomic, readonly) id value;           // Value of object
@property NSUInteger cost;                                  // cost of object

- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithKey:(NSString *)key
                       value:(id)value
                        cost:(NSUInteger)cost;

@end
