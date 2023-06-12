// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>

@import image_picker_ios;
@import image_picker_ios.Test;
@import UniformTypeIdentifiers;
@import XCTest;

@interface PickerSaveImageToPathOperationTests : XCTestCase

@end

@implementation PickerSaveImageToPathOperationTests

- (void)testSaveWebPImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"webpImage"
                                                             withExtension:@"webp"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  [self verifySavingImageWithPickerResult:result fullMetadata:YES withExtension:@"jpg"];
}

- (void)testSavePNGImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"pngImage"
                                                             withExtension:@"png"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  [self verifySavingImageWithPickerResult:result fullMetadata:YES withExtension:@"png"];
}

- (void)testSaveJPGImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"jpgImage"
                                                             withExtension:@"jpg"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  [self verifySavingImageWithPickerResult:result fullMetadata:YES withExtension:@"jpg"];
}

- (void)testSaveGIFImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"gifImage"
                                                             withExtension:@"gif"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  NSData *dataGIF = [NSData dataWithContentsOfURL:imageURL];
  CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)dataGIF, nil);
  size_t numberOfFrames = CGImageSourceGetCount(imageSource);

  XCTestExpectation *pathExpectation = [self expectationWithDescription:@"Path was created"];
  XCTestExpectation *operationExpectation =
      [self expectationWithDescription:@"Operation completed"];

  FLTPHPickerSaveImageToPathOperation *operation = [[FLTPHPickerSaveImageToPathOperation alloc]
           initWithResult:result
                maxHeight:@100
                 maxWidth:@100
      desiredImageQuality:@100
             fullMetadata:NO
           savedPathBlock:^(NSString *savedPath, FlutterError *error) {
             XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:savedPath]);

             // Ensure gif is animated.
             XCTAssertEqualObjects([NSURL URLWithString:savedPath].pathExtension, @"gif");
             NSData *newDataGIF = [NSData dataWithContentsOfFile:savedPath];
             CGImageSourceRef newImageSource =
                 CGImageSourceCreateWithData((__bridge CFDataRef)newDataGIF, nil);
             size_t newNumberOfFrames = CGImageSourceGetCount(newImageSource);
             XCTAssertEqual(numberOfFrames, newNumberOfFrames);
             [pathExpectation fulfill];
           }];
  operation.completionBlock = ^{
    [operationExpectation fulfill];
  };

  [operation start];
  [self waitForExpectationsWithTimeout:30 handler:nil];
  XCTAssertTrue(operation.isFinished);
}

- (void)testSaveBMPImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"bmpImage"
                                                             withExtension:@"bmp"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  [self verifySavingImageWithPickerResult:result fullMetadata:YES withExtension:@"jpg"];
}

- (void)testSaveHEICImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"heicImage"
                                                             withExtension:@"heic"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  [self verifySavingImageWithPickerResult:result fullMetadata:YES withExtension:@"jpg"];
}

- (void)testSaveWithOrientation API_AVAILABLE(ios(14)) {
  NSURL *imageURL =
      [[NSBundle bundleForClass:[self class]] URLForResource:@"jpgImageWithRightOrientation"
                                               withExtension:@"jpg"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  XCTestExpectation *pathExpectation = [self expectationWithDescription:@"Path was created"];
  XCTestExpectation *operationExpectation =
      [self expectationWithDescription:@"Operation completed"];

  FLTPHPickerSaveImageToPathOperation *operation = [[FLTPHPickerSaveImageToPathOperation alloc]
           initWithResult:result
                maxHeight:@10
                 maxWidth:@10
      desiredImageQuality:@100
             fullMetadata:NO
           savedPathBlock:^(NSString *savedPath, FlutterError *error) {
             XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:savedPath]);

             // Ensure image retained it's orientation data.
             XCTAssertEqualObjects([NSURL URLWithString:savedPath].pathExtension, @"jpg");
             UIImage *image = [UIImage imageWithContentsOfFile:savedPath];
             XCTAssertEqual(image.imageOrientation, UIImageOrientationRight);
             XCTAssertEqual(image.size.width, 7);
             XCTAssertEqual(image.size.height, 10);
             [pathExpectation fulfill];
           }];
  operation.completionBlock = ^{
    [operationExpectation fulfill];
  };

  [operation start];
  [self waitForExpectationsWithTimeout:30 handler:nil];
  XCTAssertTrue(operation.isFinished);
}

- (void)testSaveICNSImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"icnsImage"
                                                             withExtension:@"icns"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  [self verifySavingImageWithPickerResult:result fullMetadata:YES withExtension:@"jpg"];
}

- (void)testSaveICOImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"icoImage"
                                                             withExtension:@"ico"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  [self verifySavingImageWithPickerResult:result fullMetadata:YES withExtension:@"jpg"];
}

- (void)testSaveProRAWImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"proRawImage"
                                                             withExtension:@"dng"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  [self verifySavingImageWithPickerResult:result fullMetadata:YES withExtension:@"jpg"];
}

- (void)testSaveSVGImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"svgImage"
                                                             withExtension:@"svg"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  [self verifySavingImageWithPickerResult:result fullMetadata:YES withExtension:@"jpg"];
}

- (void)testSaveTIFFImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"tiffImage"
                                                             withExtension:@"tiff"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];
  [self verifySavingImageWithPickerResult:result fullMetadata:YES withExtension:@"jpg"];
}

- (void)testNonexistentImage API_AVAILABLE(ios(14)) {
  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"bogus"
                                                             withExtension:@"png"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];

  XCTestExpectation *errorExpectation = [self expectationWithDescription:@"invalid source error"];
  FLTPHPickerSaveImageToPathOperation *operation = [[FLTPHPickerSaveImageToPathOperation alloc]
           initWithResult:result
                maxHeight:@100
                 maxWidth:@100
      desiredImageQuality:@100
             fullMetadata:YES
           savedPathBlock:^(NSString *savedPath, FlutterError *error) {
             XCTAssertEqualObjects(error.code, @"invalid_source");
             [errorExpectation fulfill];
           }];

  [operation start];
  [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testFailingImageLoad API_AVAILABLE(ios(14)) {
  NSError *loadDataError = [NSError errorWithDomain:@"PHPickerDomain" code:1234 userInfo:nil];

  id mockItemProvider = OCMClassMock([NSItemProvider class]);
  OCMStub([mockItemProvider hasItemConformingToTypeIdentifier:OCMOCK_ANY]).andReturn(YES);
  [[mockItemProvider stub]
      loadDataRepresentationForTypeIdentifier:OCMOCK_ANY
                            completionHandler:[OCMArg invokeBlockWithArgs:[NSNull null],
                                                                          loadDataError, nil]];

  id pickerResult = OCMClassMock([PHPickerResult class]);
  OCMStub([pickerResult itemProvider]).andReturn(mockItemProvider);

  XCTestExpectation *errorExpectation = [self expectationWithDescription:@"invalid image error"];

  FLTPHPickerSaveImageToPathOperation *operation = [[FLTPHPickerSaveImageToPathOperation alloc]
           initWithResult:pickerResult
                maxHeight:@100
                 maxWidth:@100
      desiredImageQuality:@100
             fullMetadata:YES
           savedPathBlock:^(NSString *savedPath, FlutterError *error) {
             XCTAssertEqualObjects(error.code, @"invalid_image");
             XCTAssertEqualObjects(error.message, loadDataError.localizedDescription);
             XCTAssertEqualObjects(error.details, @"PHPickerDomain");
             [errorExpectation fulfill];
           }];

  [operation start];
  [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testSavePNGImageWithoutFullMetadata API_AVAILABLE(ios(14)) {
  id photoAssetUtil = OCMClassMock([PHAsset class]);

  NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"pngImage"
                                                             withExtension:@"png"];
  NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithContentsOfURL:imageURL];
  PHPickerResult *result = [self createPickerResultWithProvider:itemProvider];
  OCMReject([photoAssetUtil fetchAssetsWithLocalIdentifiers:OCMOCK_ANY options:OCMOCK_ANY]);

  [self verifySavingImageWithPickerResult:result fullMetadata:NO withExtension:@"png"];
  OCMVerifyAll(photoAssetUtil);
}

/**
 * Creates a mock picker result using NSItemProvider.
 *
 * @param itemProvider an item provider that will be used as picker result
 */
- (PHPickerResult *)createPickerResultWithProvider:(NSItemProvider *)itemProvider
    API_AVAILABLE(ios(14)) {
  PHPickerResult *result = OCMClassMock([PHPickerResult class]);

  OCMStub([result itemProvider]).andReturn(itemProvider);
  OCMStub([result assetIdentifier]).andReturn(itemProvider.registeredTypeIdentifiers.firstObject);

  return result;
}

/**
 * Validates a saving process of FLTPHPickerSaveImageToPathOperation.
 *
 * FLTPHPickerSaveImageToPathOperation is responsible for saving a picked image to the disk for
 * later use. It is expected that the saving is always successful.
 *
 * @param result the picker result
 */
- (void)verifySavingImageWithPickerResult:(PHPickerResult *)result
                             fullMetadata:(BOOL)fullMetadata
                            withExtension:(NSString *)extension API_AVAILABLE(ios(14)) {
  XCTestExpectation *pathExpectation = [self expectationWithDescription:@"Path was created"];
  XCTestExpectation *operationExpectation =
      [self expectationWithDescription:@"Operation completed"];

  FLTPHPickerSaveImageToPathOperation *operation = [[FLTPHPickerSaveImageToPathOperation alloc]
           initWithResult:result
                maxHeight:@100
                 maxWidth:@100
      desiredImageQuality:@100
             fullMetadata:fullMetadata
           savedPathBlock:^(NSString *savedPath, FlutterError *error) {
             XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:savedPath]);
             XCTAssertEqualObjects([NSURL URLWithString:savedPath].pathExtension, extension);
             [pathExpectation fulfill];
           }];
  operation.completionBlock = ^{
    [operationExpectation fulfill];
  };

  [operation start];
  [self waitForExpectationsWithTimeout:30 handler:nil];
  XCTAssertTrue(operation.isFinished);
}

@end
