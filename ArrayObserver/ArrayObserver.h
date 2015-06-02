//
//  ArrayObserver.h
//  Test
//
//  Created by Brent Gulanowski on 2015-05-28.
//  Copyright (c) 2015 Lichen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ArrayObserving <NSObject>

// keyPath is the property keyPath of a related object in the observed array
- (void)observeValueForArrayKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
//  property the array property of the object being observed
- (void)observeValueForArrayProperty:(NSString *)property ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end

@interface NSObject (ArrayObservation)

- (void)addObserver:(id<ArrayObserving>)observer forArrayKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
- (void)removeObserver:(id<ArrayObserving>)observer forArrayKeyPath:(NSString *)keyPath;

@end
