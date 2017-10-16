//
//  LRUMemoryCache.m
//  HMCImageCache
//
//  Created by chuonghuynh on 8/14/17.
//  Copyright © 2017 Chương M. Huỳnh. All rights reserved.
//

#import "LRUMemoryCache.h"
#import "HMCThreadSafeMutableDictionary.h"
#import "LRUObject.h"
#import "HMCLinkedList.h"

@interface LRUMemoryCache()

/**
 Dictionary to store objects
 */
@property (strong, nonatomic) HMCThreadSafeMutableDictionary *storedObjects;
@property (strong, nonatomic) ZLMLinkedList *lruList;

@property NSUInteger currentTotalCost;               // Total cost of all stored object
@property NSUInteger totalCostThreshold;             // Threshold of total cost

@end

@implementation LRUMemoryCache

#pragma mark - Constructors

- (instancetype)init {
    
    self = [super init];
    
    _storedObjects = [[HMCThreadSafeMutableDictionary alloc] init];
    
    _totalCostThreshold = NSUIntegerMax;
    _currentTotalCost = 0;
    _lruList = [[ZLMLinkedList alloc] init];
    
    return self;
}

- (instancetype)initWithTotalCostLimit:(NSUInteger)totalCost {
    
    self = [self init];
    
    [self setTotalCostLimit:totalCost];
    
    return self;
}

#pragma mark - Set total cost limit

- (void)setTotalCostLimit:(NSUInteger)totalCost {
    
    _totalCostThreshold = totalCost;
    
    // Free memory cache if necessary
    while (_currentTotalCost > _totalCostThreshold) {
        [self removeLRUObject];
    }
}

#pragma mark - Get object

- (id)objectForKey:(NSString *)key {
    
    NSAssert(key!=nil && ![key isEqualToString:@""], @"Key must be non nil and non empty");
    
    LRUObject *lruObject = _storedObjects[key];
    
    if (lruObject != nil) {
        
        // Put object to head of LRU list
        [_lruList removeObjectEqualTo:lruObject];
        [_lruList pushFront:lruObject];
    }
    
    return lruObject.value;
}

#pragma mark - Set object

- (void)setObject:(id)object
           forKey:(NSString *)key
             cost:(NSUInteger)cost {
    
    NSAssert(object!=nil, @"Object must be non nil");
    NSAssert(key!=nil && ![key isEqualToString:@""], @"Key must be non nil and non empty");
    
    // if key exist --> Get old cost and calculate changed cost
    LRUObject *lruObject = _storedObjects[key];
    
    NSUInteger oldCost = 0;
    
    if (lruObject != nil) {
        
        oldCost = lruObject.cost;
        
        // remove old object in LRU List
        [_lruList removeObjectEqualTo:lruObject];
    }
    
    NSUInteger changedCost = cost - oldCost;
    
    // Change current total cost
    [self changeTotalCurrentCost:changedCost];
    
    // Store object
    LRUObject *newNode = [[LRUObject alloc] initWithKey:key
                                          value:object
                                           cost:cost];
    _storedObjects[key] = newNode;
    
    
    // Add object to head of LRU list
    [_lruList pushFront:newNode];
}

#pragma mark - Remove object

- (void)removeObjectForKey:(NSString *)key {
    
    LRUObject *lruObject = _storedObjects[key];
    
    if (lruObject == nil) {
        return;
    }
    
    _currentTotalCost -= lruObject.cost;
    
    [_storedObjects removeObjectForkey:key];
    [_lruList removeObjectEqualTo:lruObject];
}

- (void)removeAllObjects {
    
    _currentTotalCost = 0;
    [_storedObjects removeAllObjects];
    [_lruList removeAllObjects];
}

#pragma mark - LRU algorithm

/**
 Remove one least-recently-used object
 */
- (void)removeLRUObject {
    
    // Remove last object (Least-recently-used)
    if ([_lruList size] > 0) {
        LRUObject *lastObject = _lruList.lastObject;
        [self removeObjectForKey:lastObject.key];
    }
}

/**
 Change current total cost and remove objects if out of limit

 @param changedCost - changed cost
 */
- (void)changeTotalCurrentCost:(NSInteger)changedCost {
    
    _currentTotalCost += changedCost;
    
    while (_currentTotalCost > _totalCostThreshold) {
        [self removeLRUObject];
    }
}

@end
