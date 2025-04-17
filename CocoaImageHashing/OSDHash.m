//
//  OSDHash.m
//  CocoaImageHashing
//
//  Created by Andreas Meingast on 10/10/15.
//  Copyright © 2015 Andreas Meingast. All rights reserved.
//

#import "OSCategories.h"
#import "OSDHash.h"
#import "OSFastGraphics.h"

static const NSUInteger OSDHashImageWidthInPixels = 9;
static const NSUInteger OSDHashImageHeightInPixels = 9;
static const OSHashDistanceType OSDHashDistanceThreshold = 9;

@implementation OSDHash

#pragma mark - OSImageHashing Protocol

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (OSHashType)hashImageData:(NSData *)imageData
{
    NSData *pixels = nil;
    NSAssert(imageData, @"Image data must not be null");
    pixels = [imageData RGBABitmapDataForResizedImageWithWidth:OSDHashImageWidthInPixels andHeight:OSDHashImageHeightInPixels];
    if (!pixels) {
        return OSHashTypeError;
    }
    return dhash_rgba_9_9([pixels bytes]);
}

- (OSHashDistanceType)hashDistanceSimilarityThreshold
{
    return OSDHashDistanceThreshold;
}

@end
