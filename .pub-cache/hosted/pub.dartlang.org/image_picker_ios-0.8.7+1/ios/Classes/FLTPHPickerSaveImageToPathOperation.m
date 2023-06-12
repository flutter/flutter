// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "FLTPHPickerSaveImageToPathOperation.h"

#import <os/log.h>

API_AVAILABLE(ios(14))
@interface FLTPHPickerSaveImageToPathOperation ()

@property(strong, nonatomic) PHPickerResult *result;
@property(strong, nonatomic) NSNumber *maxHeight;
@property(strong, nonatomic) NSNumber *maxWidth;
@property(strong, nonatomic) NSNumber *desiredImageQuality;
@property(assign, nonatomic) BOOL requestFullMetadata;

@end

@implementation FLTPHPickerSaveImageToPathOperation {
  BOOL executing;
  BOOL finished;
  FLTGetSavedPath getSavedPath;
}

- (instancetype)initWithResult:(PHPickerResult *)result
                     maxHeight:(NSNumber *)maxHeight
                      maxWidth:(NSNumber *)maxWidth
           desiredImageQuality:(NSNumber *)desiredImageQuality
                  fullMetadata:(BOOL)fullMetadata
                savedPathBlock:(FLTGetSavedPath)savedPathBlock API_AVAILABLE(ios(14)) {
  if (self = [super init]) {
    if (result) {
      self.result = result;
      self.maxHeight = maxHeight;
      self.maxWidth = maxWidth;
      self.desiredImageQuality = desiredImageQuality;
      self.requestFullMetadata = fullMetadata;
      getSavedPath = savedPathBlock;
      executing = NO;
      finished = NO;
    } else {
      return nil;
    }
    return self;
  } else {
    return nil;
  }
}

- (BOOL)isConcurrent {
  return YES;
}

- (BOOL)isExecuting {
  return executing;
}

- (BOOL)isFinished {
  return finished;
}

- (void)setFinished:(BOOL)isFinished {
  [self willChangeValueForKey:@"isFinished"];
  self->finished = isFinished;
  [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)isExecuting {
  [self willChangeValueForKey:@"isExecuting"];
  self->executing = isExecuting;
  [self didChangeValueForKey:@"isExecuting"];
}

- (void)completeOperationWithPath:(NSString *)savedPath error:(FlutterError *)error {
  getSavedPath(savedPath, error);
  [self setExecuting:NO];
  [self setFinished:YES];
}

- (void)start {
  if ([self isCancelled]) {
    [self setFinished:YES];
    return;
  }
  if (@available(iOS 14, *)) {
    [self setExecuting:YES];

    // This supports uniform types that conform to UTTypeImage.
    // This includes UTTypeHEIC, UTTypeHEIF, UTTypeLivePhoto, UTTypeICO, UTTypeICNS, UTTypePNG
    // UTTypeGIF, UTTypeJPEG, UTTypeWebP, UTTypeTIFF, UTTypeBMP, UTTypeSVG, UTTypeRAWImage
    if ([self.result.itemProvider hasItemConformingToTypeIdentifier:UTTypeImage.identifier]) {
      [self.result.itemProvider
          loadDataRepresentationForTypeIdentifier:UTTypeImage.identifier
                                completionHandler:^(NSData *_Nullable data,
                                                    NSError *_Nullable error) {
                                  if (data != nil) {
                                    [self processImage:data];
                                  } else {
                                    FlutterError *flutterError =
                                        [FlutterError errorWithCode:@"invalid_image"
                                                            message:error.localizedDescription
                                                            details:error.domain];
                                    [self completeOperationWithPath:nil error:flutterError];
                                  }
                                }];
    } else {
      FlutterError *flutterError = [FlutterError errorWithCode:@"invalid_source"
                                                       message:@"Invalid image source."
                                                       details:nil];
      [self completeOperationWithPath:nil error:flutterError];
    }
  } else {
    [self setFinished:YES];
  }
}

/**
 * Processes the image.
 */
- (void)processImage:(NSData *)pickerImageData API_AVAILABLE(ios(14)) {
  UIImage *localImage = [[UIImage alloc] initWithData:pickerImageData];

  PHAsset *originalAsset;
  // Only if requested, fetch the full "PHAsset" metadata, which requires  "Photo Library Usage"
  // permissions.
  if (self.requestFullMetadata) {
    originalAsset = [FLTImagePickerPhotoAssetUtil getAssetFromPHPickerResult:self.result];
  }

  if (self.maxWidth != nil || self.maxHeight != nil) {
    localImage = [FLTImagePickerImageUtil scaledImage:localImage
                                             maxWidth:self.maxWidth
                                            maxHeight:self.maxHeight
                                  isMetadataAvailable:YES];
  }
  if (originalAsset) {
    void (^resultHandler)(NSData *imageData, NSString *dataUTI, NSDictionary *info) =
        ^(NSData *_Nullable imageData, NSString *_Nullable dataUTI, NSDictionary *_Nullable info) {
          // maxWidth and maxHeight are used only for GIF images.
          NSString *savedPath = [FLTImagePickerPhotoAssetUtil
              saveImageWithOriginalImageData:imageData
                                       image:localImage
                                    maxWidth:self.maxWidth
                                   maxHeight:self.maxHeight
                                imageQuality:self.desiredImageQuality];
          [self completeOperationWithPath:savedPath error:nil];
        };
    if (@available(iOS 13.0, *)) {
      [[PHImageManager defaultManager]
          requestImageDataAndOrientationForAsset:originalAsset
                                         options:nil
                                   resultHandler:^(NSData *_Nullable imageData,
                                                   NSString *_Nullable dataUTI,
                                                   CGImagePropertyOrientation orientation,
                                                   NSDictionary *_Nullable info) {
                                     resultHandler(imageData, dataUTI, info);
                                   }];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      [[PHImageManager defaultManager]
          requestImageDataForAsset:originalAsset
                           options:nil
                     resultHandler:^(NSData *_Nullable imageData, NSString *_Nullable dataUTI,
                                     UIImageOrientation orientation, NSDictionary *_Nullable info) {
                       resultHandler(imageData, dataUTI, info);
                     }];
#pragma clang diagnostic pop
    }
  } else {
    // Image picked without an original asset (e.g. User pick image without permission)
    // maxWidth and maxHeight are used only for GIF images.
    NSString *savedPath =
        [FLTImagePickerPhotoAssetUtil saveImageWithOriginalImageData:pickerImageData
                                                               image:localImage
                                                            maxWidth:self.maxWidth
                                                           maxHeight:self.maxHeight
                                                        imageQuality:self.desiredImageQuality];
    [self completeOperationWithPath:savedPath error:nil];
  }
}

@end
