//
//  LRUObject.m
//  HMCImageCache
//
//  Created by chuonghuynh on 8/14/17.
//  Copyright © 2017 Chương M. Huỳnh. All rights reserved.
//

#import "LRUObject.h"

@implementation LRUObject

- (instancetype)initWithKey:(NSString *)key
                      value:(id)value
                       cost:(NSUInteger)cost {
    self = [super init];
    
    _key = key;
    _value = value;
    _cost = cost;
    
    return self;
}

@end
