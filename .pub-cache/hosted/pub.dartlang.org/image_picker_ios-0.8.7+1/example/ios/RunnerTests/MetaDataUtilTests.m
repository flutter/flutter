// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ImagePickerTestImages.h"

@import image_picker_ios;
@import image_picker_ios.Test;
@import XCTest;

@interface MetaDataUtilTests : XCTestCase
@end

@implementation MetaDataUtilTests

- (void)testGetImageMIMETypeFromImageData {
  // test jpeg
  XCTAssertEqual(
      [FLTImagePickerMetaDataUtil getImageMIMETypeFromImageData:ImagePickerTestImages.JPGTestData],
      FLTImagePickerMIMETypeJPEG);

  // test png
  XCTAssertEqual(
      [FLTImagePickerMetaDataUtil getImageMIMETypeFromImageData:ImagePickerTestImages.PNGTestData],
      FLTImagePickerMIMETypePNG);

  // test gif
  XCTAssertEqual(
      [FLTImagePickerMetaDataUtil getImageMIMETypeFromImageData:ImagePickerTestImages.GIFTestData],
      FLTImagePickerMIMETypeGIF);
}

- (void)testSuffixFromType {
  // test jpeg
  XCTAssertEqualObjects(
      [FLTImagePickerMetaDataUtil imageTypeSuffixFromType:FLTImagePickerMIMETypeJPEG], @".jpg");

  // test png
  XCTAssertEqualObjects(
      [FLTImagePickerMetaDataUtil imageTypeSuffixFromType:FLTImagePickerMIMETypePNG], @".png");

  // test gif
  XCTAssertEqualObjects(
      [FLTImagePickerMetaDataUtil imageTypeSuffixFromType:FLTImagePickerMIMETypeGIF], @".gif");

  // test other
  XCTAssertNil([FLTImagePickerMetaDataUtil imageTypeSuffixFromType:FLTImagePickerMIMETypeOther]);
}

- (void)testGetMetaData {
  NSDictionary *metaData =
      [FLTImagePickerMetaDataUtil getMetaDataFromImageData:ImagePickerTestImages.JPGTestData];
  NSDictionary *exif = [metaData objectForKey:(__bridge NSString *)kCGImagePropertyExifDictionary];
  XCTAssertEqual([exif[(__bridge NSString *)kCGImagePropertyExifPixelXDimension] integerValue], 12);
}

- (void)testWriteMetaData {
  NSData *dataJPG = ImagePickerTestImages.JPGTestData;

  NSDictionary *metaData = [FLTImagePickerMetaDataUtil getMetaDataFromImageData:dataJPG];
  NSString *tmpFile = [NSString stringWithFormat:@"image_picker_test.jpg"];
  NSString *tmpDirectory = NSTemporaryDirectory();
  NSString *tmpPath = [tmpDirectory stringByAppendingPathComponent:tmpFile];
  NSData *newData = [FLTImagePickerMetaDataUtil imageFromImage:dataJPG withMetaData:metaData];
  if ([[NSFileManager defaultManager] createFileAtPath:tmpPath contents:newData attributes:nil]) {
    NSData *savedTmpImageData = [NSData dataWithContentsOfFile:tmpPath];
    NSDictionary *tmpMetaData =
        [FLTImagePickerMetaDataUtil getMetaDataFromImageData:savedTmpImageData];
    XCTAssert([tmpMetaData isEqualToDictionary:metaData]);
  } else {
    XCTAssert(NO);
  }
}

- (void)testUpdateMetaDataBadData {
  NSData *imageData = [NSData data];

  NSDictionary *metaData = [FLTImagePickerMetaDataUtil getMetaDataFromImageData:imageData];
  NSData *newData = [FLTImagePickerMetaDataUtil imageFromImage:imageData withMetaData:metaData];
  XCTAssertNil(newData);
}

- (void)testConvertImageToData {
  UIImage *imageJPG = [UIImage imageWithData:ImagePickerTestImages.JPGTestData];
  NSData *convertedDataJPG = [FLTImagePickerMetaDataUtil convertImage:imageJPG
                                                            usingType:FLTImagePickerMIMETypeJPEG
                                                              quality:@(0.5)];
  XCTAssertEqual([FLTImagePickerMetaDataUtil getImageMIMETypeFromImageData:convertedDataJPG],
                 FLTImagePickerMIMETypeJPEG);

  NSData *convertedDataPNG = [FLTImagePickerMetaDataUtil convertImage:imageJPG
                                                            usingType:FLTImagePickerMIMETypePNG
                                                              quality:nil];
  XCTAssertEqual([FLTImagePickerMetaDataUtil getImageMIMETypeFromImageData:convertedDataPNG],
                 FLTImagePickerMIMETypePNG);
}

@end
