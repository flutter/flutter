// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTImagePickerMetaDataUtil.h"
#import <Photos/Photos.h>

static const uint8_t kFirstByteJPEG = 0xFF;
static const uint8_t kFirstBytePNG = 0x89;
static const uint8_t kFirstByteGIF = 0x47;

NSString *const kFLTImagePickerDefaultSuffix = @".jpg";
const FLTImagePickerMIMEType kFLTImagePickerMIMETypeDefault = FLTImagePickerMIMETypeJPEG;

@implementation FLTImagePickerMetaDataUtil

+ (FLTImagePickerMIMEType)getImageMIMETypeFromImageData:(NSData *)imageData {
  uint8_t firstByte;
  [imageData getBytes:&firstByte length:1];
  switch (firstByte) {
    case kFirstByteJPEG:
      return FLTImagePickerMIMETypeJPEG;
    case kFirstBytePNG:
      return FLTImagePickerMIMETypePNG;
    case kFirstByteGIF:
      return FLTImagePickerMIMETypeGIF;
  }
  return FLTImagePickerMIMETypeOther;
}

+ (NSString *)imageTypeSuffixFromType:(FLTImagePickerMIMEType)type {
  switch (type) {
    case FLTImagePickerMIMETypeJPEG:
      return @".jpg";
    case FLTImagePickerMIMETypePNG:
      return @".png";
    case FLTImagePickerMIMETypeGIF:
      return @".gif";
    default:
      return nil;
  }
}

+ (NSDictionary *)getMetaDataFromImageData:(NSData *)imageData {
  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
  NSDictionary *metadata =
      (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
  CFRelease(source);
  return metadata;
}

+ (NSData *)imageFromImage:(NSData *)imageData withMetaData:(NSDictionary *)metadata {
  NSMutableData *targetData = [NSMutableData data];
  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
  if (source == NULL) {
    return nil;
  }
  CGImageDestinationRef destination = NULL;
  CFStringRef sourceType = CGImageSourceGetType(source);
  if (sourceType != NULL) {
    destination =
        CGImageDestinationCreateWithData((__bridge CFMutableDataRef)targetData, sourceType, 1, nil);
  }
  if (destination == NULL) {
    CFRelease(source);
    return nil;
  }
  CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)metadata);
  CGImageDestinationFinalize(destination);
  CFRelease(source);
  CFRelease(destination);
  return targetData;
}

+ (NSData *)convertImage:(UIImage *)image
               usingType:(FLTImagePickerMIMEType)type
                 quality:(nullable NSNumber *)quality {
  if (quality && type != FLTImagePickerMIMETypeJPEG) {
    NSLog(@"image_picker: compressing is not supported for type %@. Returning the image with "
          @"original quality",
          [FLTImagePickerMetaDataUtil imageTypeSuffixFromType:type]);
  }

  switch (type) {
    case FLTImagePickerMIMETypeJPEG: {
      CGFloat qualityFloat = (quality != nil) ? quality.floatValue : 1;
      return UIImageJPEGRepresentation(image, qualityFloat);
    }
    case FLTImagePickerMIMETypePNG:
      return UIImagePNGRepresentation(image);
    default: {
      // converts to JPEG by default.
      CGFloat qualityFloat = (quality != nil) ? quality.floatValue : 1;
      return UIImageJPEGRepresentation(image, qualityFloat);
    }
  }
}

@end
