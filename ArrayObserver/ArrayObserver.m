//
//  ArrayObserver.m
//  Test
//
//  Created by Brent Gulanowski on 2015-05-28.
//  Copyright (c) 2015 Lichen Labs. All rights reserved.
//

#import "ArrayObserver.h"

#import <objc/runtime.h>

static void * ArrayContext = &ArrayContext;
static void * MemberContext = &MemberContext;

@interface ArrayObserver : NSObject
@property (nonatomic, weak) id observer;
@property (nonatomic, weak) id object;
@property (nonatomic) NSString *keyPath;
@property (nonatomic) void *context;
@end

@implementation ArrayObserver {
    NSString *_property;
    NSString *_relatedPath;
}

- (void)beginObservingObject {
    if (![_object respondsToSelector:NSSelectorFromString(_property)]) {
        [NSException raise:NSInternalInconsistencyException format:@"unsupported property %@ for object", _property];
    }
    [_object addObserver:self forKeyPath:_property options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:ArrayContext];
}

- (void)stopObservingObject {
    [_object removeObserver:self forKeyPath:_property context:ArrayContext];
}

- (void)beginObservingRelatedObjects:(NSArray *)objects {
    for (id object in objects) {
        [object addObserver:self forKeyPath:_relatedPath options:0 context:MemberContext];
    }
}

- (void)stopObservingRelatedObjects:(NSArray *)objects {
    for (id object in objects) {
        [object removeObserver:self forKeyPath:_relatedPath context:MemberContext];
    }
}

- (void)updateObservationForRelatedObjectsOld:(NSArray *)old new:(NSArray *)new indexes:(NSIndexSet *)indexes {
    
    [self stopObservingRelatedObjects:old];
    [self beginObservingRelatedObjects:new];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ArrayContext) {
        
        BOOL inserts = NO;
        BOOL removals = NO;
        
        switch ((NSKeyValueChange)[change[NSKeyValueChangeKindKey] integerValue]) {
            case NSKeyValueChangeSetting:
            case NSKeyValueChangeInsertion:
                inserts = YES;
                break;
                
            case NSKeyValueChangeRemoval:
                removals = YES;
                break;
                
            case NSKeyValueChangeReplacement:
                inserts = removals = YES;
                break;
        }
        
        NSArray *old = removals ? change[NSKeyValueChangeOldKey] : nil;
        NSArray *new = inserts ? change[NSKeyValueChangeNewKey] : nil;
        
        [self updateObservationForRelatedObjectsOld:old new:new indexes:change[NSKeyValueChangeIndexesKey]];
        [_observer observeValueForArrayProperty:_property ofObject:object change:change context:_context];
    }
    else if(context == MemberContext) {
        [_observer observeValueForArrayKeyPath:_relatedPath ofObject:object change:nil context:_context];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)extractPathInfo {
    NSArray *keys = [_keyPath componentsSeparatedByString:@"."];
    _property = [keys firstObject];
    _relatedPath = [[keys subarrayWithRange:NSMakeRange(1, keys.count-1)] componentsJoinedByString:@"."];
}

- (instancetype)initWithObserver:(id)observer object:(id)object keyPath:(NSString *)keyPath context:(void *)context {
    if ((self = [super init])) {
        _observer = observer;
        _object = object;
        _keyPath = keyPath;
        _context = context;
        [self extractPathInfo];
        [self beginObservingObject];
    }
    return self;
}

- (void)dealloc {
    [self stopObservingObject];
}

+ (instancetype)arrayObserverForObserver:(id)observer object:(id)object keyPath:(NSString *)keypath context:(void *)context {
    return [[self alloc] initWithObserver:observer object:object keyPath:keypath context:context];
}

@end

#pragma mark -

@implementation NSObject (ArrayObservation)

static NSString * const key = @"arrayObservers";

- (NSMutableDictionary *)arrayObservers
{
    NSMutableDictionary *arrayObservers = objc_getAssociatedObject(self, (__bridge const void *)(key));
    if (nil == arrayObservers) {
        arrayObservers = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, (__bridge const void *)(key), arrayObservers, OBJC_ASSOCIATION_RETAIN);
    }
    return arrayObservers;
}

- (void)cleanUpObserversForKeyPath:(NSString *)keyPath
{
    NSMutableDictionary *arrayObservers = [self arrayObservers];
    NSMutableSet *pathObservers = arrayObservers[keyPath];

    if ([pathObservers count] == 0) {
        arrayObservers[keyPath] = nil;
        if ([arrayObservers count] == 0) {
            objc_setAssociatedObject(self, (__bridge const void *)(key), nil, OBJC_ASSOCIATION_RETAIN);
        }
    }

}

- (void)addObserver:(id<ArrayObserving>)observer forArrayKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    NSMutableDictionary *arrayObservers = [self arrayObservers];
    ArrayObserver *ao = [ArrayObserver arrayObserverForObserver:observer object:self keyPath:keyPath context:context];
    
    NSMutableSet *pathObservers = arrayObservers[keyPath];
    if (pathObservers == nil) {
        pathObservers = [NSMutableSet setWithObject:ao];
        arrayObservers[keyPath] = pathObservers;
    }
    else {
        [pathObservers addObject:ao];
    }
}

- (void)removeObserver:(id<ArrayObserving>)observer forArrayKeyPath:(NSString *)keyPath
{
    NSMutableDictionary *arrayObservers = [self arrayObservers];
    NSMutableSet *pathObservers = arrayObservers[keyPath];
    for (ArrayObserver *ao in [pathObservers copy]) {
        if (ao.observer == observer) {
            [pathObservers removeObject:ao];
            break;
        }
    }
    [self cleanUpObserversForKeyPath:keyPath];
}

@end
