//
//  LRUMemoryCache.h
//  HMCImageCache
//
//  Created by chuonghuynh on 8/14/17.
//  Copyright © 2017 Chương M. Huỳnh. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Memory cache with LRU algorithm
 */
@interface LRUMemoryCache : NSObject

- (instancetype)init;

/**
 Init a memory cache with total cost limit

 @param totalCost - total cost limit for memory cache
 @return LRUMemoryCache
 */
- (instancetype)initWithTotalCostLimit:(NSUInteger)totalCost;

/**
 Set object with key and cost

 @param object - object to store
 @param key - key representing object
 @param cost - cost of object
 */
- (void)setObject:(id)object
           forKey:(NSString *)key
             cost:(NSUInteger)cost;

/**
 Get object with key

 @param key - key representing object
 @return - stored object if existed, nil otherwise
 */
- (id)objectForKey:(NSString *)key;

/**
 Remove object with key

 @param key - key representing object
 */
- (void)removeObjectForKey:(NSString *)key;

/**
 Remove all object in cache
 */
- (void)removeAllObjects;

/**
 Set total cost limit for cache

 @param totalCost - threshold cost of cache. Over the cost, some objects will be removed 
 */
- (void)setTotalCostLimit:(NSUInteger)totalCost;

@end
