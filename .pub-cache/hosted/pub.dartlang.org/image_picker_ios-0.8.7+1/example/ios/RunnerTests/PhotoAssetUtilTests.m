// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ImagePickerTestImages.h"

@import image_picker_ios;
@import image_picker_ios.Test;
@import XCTest;

@interface PhotoAssetUtilTests : XCTestCase
@end

@implementation PhotoAssetUtilTests

- (void)getAssetFromImagePickerInfoShouldReturnNilIfNotAvailable {
  NSDictionary *mockData = @{};
  XCTAssertNil([FLTImagePickerPhotoAssetUtil getAssetFromImagePickerInfo:mockData]);
}

- (void)testGetAssetFromPHPickerResultShouldReturnNilIfNotAvailable API_AVAILABLE(ios(14)) {
  if (@available(iOS 14, *)) {
    PHPickerResult *mockData;
    [mockData.itemProvider
        loadObjectOfClass:[UIImage class]
        completionHandler:^(__kindof id<NSItemProviderReading> _Nullable image,
                            NSError *_Nullable error) {
          XCTAssertNil([FLTImagePickerPhotoAssetUtil getAssetFromPHPickerResult:mockData]);
        }];
  }
}

- (void)testSaveImageWithOriginalImageData_ShouldSaveWithTheCorrectExtentionAndMetaData {
  // test jpg
  NSData *dataJPG = ImagePickerTestImages.JPGTestData;
  UIImage *imageJPG = [UIImage imageWithData:dataJPG];
  NSString *savedPathJPG = [FLTImagePickerPhotoAssetUtil saveImageWithOriginalImageData:dataJPG
                                                                                  image:imageJPG
                                                                               maxWidth:nil
                                                                              maxHeight:nil
                                                                           imageQuality:nil];
  XCTAssertEqualObjects([NSURL URLWithString:savedPathJPG].pathExtension, @"jpg");

  NSDictionary *originalMetaDataJPG = [FLTImagePickerMetaDataUtil getMetaDataFromImageData:dataJPG];
  NSData *newDataJPG = [NSData dataWithContentsOfFile:savedPathJPG];
  NSDictionary *newMetaDataJPG = [FLTImagePickerMetaDataUtil getMetaDataFromImageData:newDataJPG];
  XCTAssertEqualObjects(originalMetaDataJPG[@"ProfileName"], newMetaDataJPG[@"ProfileName"]);

  // test png
  NSData *dataPNG = ImagePickerTestImages.PNGTestData;
  UIImage *imagePNG = [UIImage imageWithData:dataPNG];
  NSString *savedPathPNG = [FLTImagePickerPhotoAssetUtil saveImageWithOriginalImageData:dataPNG
                                                                                  image:imagePNG
                                                                               maxWidth:nil
                                                                              maxHeight:nil
                                                                           imageQuality:nil];
  XCTAssertEqualObjects([NSURL URLWithString:savedPathPNG].pathExtension, @"png");

  NSDictionary *originalMetaDataPNG = [FLTImagePickerMetaDataUtil getMetaDataFromImageData:dataPNG];
  NSData *newDataPNG = [NSData dataWithContentsOfFile:savedPathPNG];
  NSDictionary *newMetaDataPNG = [FLTImagePickerMetaDataUtil getMetaDataFromImageData:newDataPNG];
  XCTAssertEqualObjects(originalMetaDataPNG[@"ProfileName"], newMetaDataPNG[@"ProfileName"]);
}

- (void)testSaveImageWithPickerInfo_ShouldSaveWithDefaultExtention {
  UIImage *imageJPG = [UIImage imageWithData:ImagePickerTestImages.JPGTestData];
  NSString *savedPathJPG = [FLTImagePickerPhotoAssetUtil saveImageWithPickerInfo:nil
                                                                           image:imageJPG
                                                                    imageQuality:nil];
  // should be saved as
  XCTAssertEqualObjects([savedPathJPG substringFromIndex:savedPathJPG.length - 4],
                        kFLTImagePickerDefaultSuffix);
}

- (void)testSaveImageWithPickerInfo_ShouldSaveWithTheCorrectExtentionAndMetaData {
  NSDictionary *dummyInfo = @{
    UIImagePickerControllerMediaMetadata : @{
      (__bridge NSString *)kCGImagePropertyExifDictionary :
          @{(__bridge NSString *)kCGImagePropertyExifMakerNote : @"aNote"}
    }
  };
  UIImage *imageJPG = [UIImage imageWithData:ImagePickerTestImages.JPGTestData];
  NSString *savedPathJPG = [FLTImagePickerPhotoAssetUtil saveImageWithPickerInfo:dummyInfo
                                                                           image:imageJPG
                                                                    imageQuality:nil];
  NSData *data = [NSData dataWithContentsOfFile:savedPathJPG];
  NSDictionary *meta = [FLTImagePickerMetaDataUtil getMetaDataFromImageData:data];
  XCTAssertEqualObjects(meta[(__bridge NSString *)kCGImagePropertyExifDictionary]
                            [(__bridge NSString *)kCGImagePropertyExifMakerNote],
                        @"aNote");
}

- (void)testSaveImageWithOriginalImageData_ShouldSaveAsGifAnimation {
  // test gif
  NSData *dataGIF = ImagePickerTestImages.GIFTestData;
  UIImage *imageGIF = [UIImage imageWithData:dataGIF];
  CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)dataGIF, nil);

  size_t numberOfFrames = CGImageSourceGetCount(imageSource);

  NSString *savedPathGIF = [FLTImagePickerPhotoAssetUtil saveImageWithOriginalImageData:dataGIF
                                                                                  image:imageGIF
                                                                               maxWidth:nil
                                                                              maxHeight:nil
                                                                           imageQuality:nil];
  XCTAssertEqualObjects([NSURL URLWithString:savedPathGIF].pathExtension, @"gif");

  NSData *newDataGIF = [NSData dataWithContentsOfFile:savedPathGIF];

  CGImageSourceRef newImageSource =
      CGImageSourceCreateWithData((__bridge CFDataRef)newDataGIF, nil);

  size_t newNumberOfFrames = CGImageSourceGetCount(newImageSource);

  XCTAssertEqual(numberOfFrames, newNumberOfFrames);
}

- (void)testSaveImageWithOriginalImageData_ShouldSaveAsScalledGifAnimation {
  // test gif
  NSData *dataGIF = ImagePickerTestImages.GIFTestData;
  UIImage *imageGIF = [UIImage imageWithData:dataGIF];

  CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)dataGIF, nil);

  size_t numberOfFrames = CGImageSourceGetCount(imageSource);

  NSString *savedPathGIF = [FLTImagePickerPhotoAssetUtil saveImageWithOriginalImageData:dataGIF
                                                                                  image:imageGIF
                                                                               maxWidth:@3
                                                                              maxHeight:@2
                                                                           imageQuality:nil];
  NSData *newDataGIF = [NSData dataWithContentsOfFile:savedPathGIF];
  UIImage *newImage = [[UIImage alloc] initWithData:newDataGIF];

  XCTAssertEqual(newImage.size.width, 3);
  XCTAssertEqual(newImage.size.height, 2);

  CGImageSourceRef newImageSource =
      CGImageSourceCreateWithData((__bridge CFDataRef)newDataGIF, nil);

  size_t newNumberOfFrames = CGImageSourceGetCount(newImageSource);

  XCTAssertEqual(numberOfFrames, newNumberOfFrames);
}

@end
