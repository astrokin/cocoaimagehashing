//
//  OSSimilaritySearch.m
//  CocoaImageHashing
//
//  Created by Andreas Meingast on 16/10/15.
//  Copyright © 2015 Andreas Meingast. All rights reserved.
//

#import "OSCategories.h"
#import "OSImageHashing.h"
#import "OSSimilaritySearch.h"

@import Darwin.libkern.OSAtomic;

@implementation OSSimilaritySearch

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [self new];
    });
    return instance;
}

#pragma mark - Collection & Stream Based Similarity Search

- (void)similarImagesWithProvider:(OSImageHashingProviderId)imageHashingProviderId
        withHashDistanceThreshold:(OSHashDistanceType)hashDistanceThreshold
            forImageStreamHandler:(OSTuple<OSImageId *, NSData *> * (^)(void))imageStreamHandler
                 forResultHandler:(void (^)(OSImageId * __unsafe_unretained leftHandImageId, OSImageId * __unsafe_unretained rightHandImageId))resultHandler
{
    NSMutableArray<OSHashResultTuple<NSString *> *> __block *fingerPrintedTuples = [NSMutableArray new];
    NSUInteger cpuCount = [[NSProcessInfo processInfo] processorCount];
    dispatch_semaphore_t hashingSemaphore = dispatch_semaphore_create((long)cpuCount);
    dispatch_group_t hashingDispatchGroup = dispatch_group_create();
    id<OSImageHashingProvider> hashingProvider = nil;
    OSSpinLock volatile __block lock;
    NSData * __unsafe_unretained imageData;
    
    NSAssert(imageStreamHandler, @"Image stream handler must not be nil");
    NSAssert(resultHandler, @"Result handler must not be nil");
    
    hashingProvider = OSImageHashingProviderFromImageHashingProviderId(imageHashingProviderId);
    if (!hashingProvider) {
        return;
    }
    lock = OS_SPINLOCK_INIT;
    for (;;) {
        OSTuple<NSString *, NSData *> __block *inputTuple = imageStreamHandler();
        if (!inputTuple) {
            break;
        }
        imageData = inputTuple->_second;
        if (!imageData) {
            continue;
        }
        dispatch_semaphore_wait(hashingSemaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(hashingDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          OSHashType hashResult = [hashingProvider hashImageData:imageData];
          if (hashResult != OSHashTypeError) {
              OSHashResultTuple<NSString *> *resultTuple = [OSHashResultTuple new];
              resultTuple->_first = inputTuple->_first;
              resultTuple->_hashResult = hashResult;
              OSSpinLockLock(&lock);
              [fingerPrintedTuples addObject:resultTuple];
              OSSpinLockUnlock(&lock);
          }
          dispatch_semaphore_signal(hashingSemaphore);
        });
    }
    dispatch_group_wait(hashingDispatchGroup, DISPATCH_TIME_FOREVER);
    [fingerPrintedTuples enumeratePairCombinationsUsingBlock:^(OSHashResultTuple * __unsafe_unretained leftHandTuple, OSHashResultTuple * __unsafe_unretained rightHandTuple) {
        OSHashDistanceType hashDistance = OSHammingDistance(leftHandTuple->_hashResult, rightHandTuple->_hashResult);
        if (hashDistance <= hashDistanceThreshold && hashDistance != OSHashTypeError) {
            resultHandler(leftHandTuple->_first, rightHandTuple->_first);
        }
    }];
}

- (NSArray<OSTuple<OSImageId *, OSImageId *> *> *)similarImagesWithProvider:(OSImageHashingProviderId)imageHashingProviderId
                                                  withHashDistanceThreshold:(OSHashDistanceType)hashDistanceThreshold
                                                      forImageStreamHandler:(OSTuple<OSImageId *, NSData *> * (^)(void))imageStreamHandler
{
    NSMutableArray<OSTuple<NSString *, NSString *> *> *tuples = [NSMutableArray new];
    OSSpinLock volatile __block lock;
    
    NSAssert(imageStreamHandler, @"Image stream handler must not be nil");
    
    lock = OS_SPINLOCK_INIT;
    [self similarImagesWithProvider:imageHashingProviderId
          withHashDistanceThreshold:hashDistanceThreshold
              forImageStreamHandler:imageStreamHandler
                   forResultHandler:^(OSImageId * __unsafe_unretained leftHandImageId, OSImageId * __unsafe_unretained rightHandImageId) {
                     OSTuple<OSImageId *, OSImageId *> *tuple = [OSTuple tupleWithFirst:leftHandImageId
                                                                              andSecond:rightHandImageId];
                     OSSpinLockLock(&lock);
                     [tuples addObject:tuple];
                     OSSpinLockUnlock(&lock);
                   }];
    return tuples;
}

- (NSArray<OSTuple<OSImageId *, OSImageId *> *> *)similarImagesWithProvider:(OSImageHashingProviderId)imageHashingProviderId
                                                  withHashDistanceThreshold:(OSHashDistanceType)hashDistanceThreshold
                                                                  forImages:(NSArray<OSTuple<OSImageId *, NSData *> *> *)imageTuples
{
    NSUInteger __block i = 0;
    NSArray<OSTuple<OSImageId *, OSImageId *> *> *result;
    
    NSAssert(imageTuples, @"Image tuple array must not be nil");
    
    result = [self
        similarImagesWithProvider:imageHashingProviderId
        withHashDistanceThreshold:hashDistanceThreshold
            forImageStreamHandler:^OSTuple<OSImageId *, NSData *> * {
              if (i >= [imageTuples count]) {
                  return nil;
              }
              return [imageTuples objectAtIndex:i++];
            }];
    return result;
}

#pragma mark - Result Conversion

- (NSDictionary<OSImageId *, NSSet<OSImageId *> *> *)dictionaryFromSimilarImagesResult:(NSArray<OSTuple<OSImageId *, OSImageId *> *> *)similarImageTuples
{
    NSMutableDictionary<OSImageId *, OSImageId *> *representatives = [NSMutableDictionary new];
    NSMutableDictionary<OSImageId *, NSMutableSet<OSImageId *> *> *result = [NSMutableDictionary new];
    OSImageId * __unsafe_unretained secondRep;
    NSAssert(similarImageTuples, @"Similar image tuple array must not be nil");
    for (OSTuple<OSImageId *, OSImageId *> *tuple in similarImageTuples) {
        OSImageId * __unsafe_unretained first = tuple->_first;
        OSImageId * __unsafe_unretained second = tuple->_second;
        if (first && second) {
            OSImageId * __unsafe_unretained firstRep = representatives[first];
            if (!firstRep) {
                representatives[first] = firstRep = first;
                result[first] = [NSMutableSet set];
            }
            secondRep = representatives[second];
            if (!secondRep) {
                representatives[second] = firstRep;
            }
            [result[firstRep] addObject:second];
        }
    }
    return result;
}

@end
