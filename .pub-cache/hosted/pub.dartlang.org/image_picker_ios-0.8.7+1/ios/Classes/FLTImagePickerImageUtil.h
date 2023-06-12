// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GIFInfo : NSObject

@property(strong, nonatomic, readonly) NSArray<UIImage *> *images;
@property(assign, nonatomic, readonly) NSTimeInterval interval;

- (instancetype)initWithImages:(NSArray<UIImage *> *)images interval:(NSTimeInterval)interval;

@end

@interface FLTImagePickerImageUtil : NSObject

// Resizes the given image to fit within maxWidth (if non-nil) and maxHeight (if non-nil)
+ (UIImage *)scaledImage:(UIImage *)image
                maxWidth:(nullable NSNumber *)maxWidth
               maxHeight:(nullable NSNumber *)maxHeight
     isMetadataAvailable:(BOOL)isMetadataAvailable;

// Resize all gif animation frames.
+ (GIFInfo *)scaledGIFImage:(NSData *)data
                   maxWidth:(NSNumber *)maxWidth
                  maxHeight:(NSNumber *)maxHeight;

@end

NS_ASSUME_NONNULL_END
