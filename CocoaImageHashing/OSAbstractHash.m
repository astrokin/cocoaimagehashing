//
//  OSAbstractHash.m
//  CocoaImageHashing
//
//  Created by Andreas Meingast on 16/10/15.
//  Copyright © 2015 Andreas Meingast. All rights reserved.
//

#import "OSAbstractHash.h"
#import "OSCategories.h"
#import "OSImageHashing.h"
#import "OSTypes+Internal.h"

@implementation OSAbstractHash

#pragma mark - OSImageHashing Protocol

- (OSHashType)hashImage:(OSImageType *)image
{
    NSData *data = nil;
    
    NSAssert(image, @"Image must not be null");
    data = [image dataRepresentation];
    if (!data) {
        return OSHashTypeError;
    }
    return [self hashImageData:data];
}

- (BOOL)compareImageData:(NSData *)leftHandImageData
                      to:(NSData *)rightHandImageData
{
    NSAssert(leftHandImageData, @"Left hand image data must not be null");
    NSAssert(rightHandImageData, @"Right hand image data must not be null");
    return [self compareImageData:leftHandImageData
                                      to:rightHandImageData
                   withDistanceThreshold:[self hashDistanceSimilarityThreshold]];
}

- (OSHashDistanceType)hashDistance:(OSHashType)leftHand
                                to:(OSHashType)rightHand
{
    NSAssert(leftHand != OSHashTypeError, @"Left hand hash must not be OSHashTypeError");
    NSAssert(rightHand != OSHashTypeError, @"Right hand hash must not be OSHashTypeError");
    return OSHammingDistance(leftHand, rightHand);
}

- (BOOL)compareImageData:(NSData *)leftHandImageData
                      to:(NSData *)rightHandImageData
   withDistanceThreshold:(OSHashDistanceType)distanceThreshold
{
    OSHashType leftHandImageDataHash;
    OSHashType rightHandImageDataHash;
    OSHashDistanceType distance;
    NSAssert(leftHandImageData, @"Left hand image data must not be null");
    NSAssert(rightHandImageData, @"Right hand image data must not be null");
    leftHandImageDataHash = [self hashImageData:leftHandImageData];
    rightHandImageDataHash = [self hashImageData:rightHandImageData];
    if (leftHandImageDataHash == OSHashTypeError || rightHandImageDataHash == OSHashTypeError) {
        return NO;
    }
    distance = [self hashDistance:leftHandImageDataHash to:rightHandImageDataHash];
    return distance < distanceThreshold;
}

- (NSComparisonResult)imageSimilarityComparatorForImageForBaseImageData:(NSData *)baseImageData
                                                   forLeftHandImageData:(NSData *)leftHandImageData
                                                  forRightHandImageData:(NSData *)rightHandImageData
{
    OSHashType leftHandImageHash;
    OSHashType rightHandImageHash;
    OSHashType baseImageHash;
    OSHashDistanceType distanceToLeftImageData;
    OSHashDistanceType distanceToRightImageData;
    NSAssert(baseImageData, @"Base image data must not be null");
    NSAssert(rightHandImageData, @"Right hand image data must not be null");
    NSAssert(leftHandImageData, @"Left hand image data must not be null");
    NSAssert(rightHandImageData, @"Right hand image data must not be null");
    leftHandImageHash = [self hashImageData:leftHandImageData];
    rightHandImageHash = [self hashImageData:rightHandImageData];
    baseImageHash = [self hashImageData:baseImageData];
    if (baseImageHash == OSHashTypeError) {
        return NSOrderedSame;
    } else if (leftHandImageHash == OSHashTypeError) {
        return NSOrderedDescending;
    } else if (rightHandImageHash == OSHashTypeError) {
        return NSOrderedAscending;
    }
    distanceToLeftImageData = [self hashDistance:leftHandImageHash to:baseImageHash];
    distanceToRightImageData = [self hashDistance:rightHandImageHash to:baseImageHash];
    if (distanceToLeftImageData < distanceToRightImageData) {
        return NSOrderedAscending;
    } else if (distanceToLeftImageData > distanceToRightImageData) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

#pragma mark - Abstract methods

+ (instancetype)sharedInstance
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Abstract method called."
                                 userInfo:nil];
}

- (OSHashDistanceType)hashDistanceSimilarityThreshold
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Abstract method called."
                                 userInfo:nil];
}

- (OSHashType)hashImageData:(NSData * OS_UNUSED)imageData
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Abstract method called."
                                 userInfo:nil];
}

@end
