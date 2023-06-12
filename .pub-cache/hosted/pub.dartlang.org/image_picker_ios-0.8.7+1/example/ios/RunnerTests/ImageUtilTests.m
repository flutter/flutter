// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ImagePickerTestImages.h"

@import image_picker_ios;
@import image_picker_ios.Test;
@import XCTest;

@interface ImageUtilTests : XCTestCase
@end

@implementation ImageUtilTests

- (void)testScaledImage_ShouldBeScaled {
  UIImage *image = [UIImage imageWithData:ImagePickerTestImages.JPGTestData];
  UIImage *newImage = [FLTImagePickerImageUtil scaledImage:image
                                                  maxWidth:@3
                                                 maxHeight:@2
                                       isMetadataAvailable:YES];

  XCTAssertEqual(newImage.size.width, 3);
  XCTAssertEqual(newImage.size.height, 2);
}

- (void)testScaledImage_ShouldBeScaledWithNoMetadata {
  UIImage *image = [UIImage imageWithData:ImagePickerTestImages.JPGTestData];
  UIImage *newImage = [FLTImagePickerImageUtil scaledImage:image
                                                  maxWidth:@3
                                                 maxHeight:@2
                                       isMetadataAvailable:NO];

  XCTAssertEqual(newImage.size.width, 3);
  XCTAssertEqual(newImage.size.height, 2);
}

- (void)testScaledImage_ShouldBeCorrectRotation {
  NSURL *imageURL =
      [[NSBundle bundleForClass:[self class]] URLForResource:@"jpgImageWithRightOrientation"
                                               withExtension:@"jpg"];
  NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
  UIImage *image = [UIImage imageWithData:imageData];
  XCTAssertEqual(image.size.width, 130);
  XCTAssertEqual(image.size.height, 174);
  XCTAssertEqual(image.imageOrientation, UIImageOrientationRight);

  UIImage *newImage = [FLTImagePickerImageUtil scaledImage:image
                                                  maxWidth:@10
                                                 maxHeight:@10
                                       isMetadataAvailable:YES];
  XCTAssertEqual(newImage.size.width, 10);
  XCTAssertEqual(newImage.size.height, 7);
  XCTAssertEqual(newImage.imageOrientation, UIImageOrientationUp);
}

- (void)testScaledGIFImage_ShouldBeScaled {
  // gif image that frame size is 3 and the duration is 1 second.
  GIFInfo *info = [FLTImagePickerImageUtil scaledGIFImage:ImagePickerTestImages.GIFTestData
                                                 maxWidth:@3
                                                maxHeight:@2];

  NSArray<UIImage *> *images = info.images;
  NSTimeInterval duration = info.interval;

  XCTAssertEqual(images.count, 3);
  XCTAssertEqual(duration, 1);

  for (UIImage *newImage in images) {
    XCTAssertEqual(newImage.size.width, 3);
    XCTAssertEqual(newImage.size.height, 2);
  }
}

@end
