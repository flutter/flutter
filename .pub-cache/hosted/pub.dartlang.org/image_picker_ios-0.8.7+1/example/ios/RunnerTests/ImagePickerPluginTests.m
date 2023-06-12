// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ImagePickerTestImages.h"

@import image_picker_ios;
@import image_picker_ios.Test;
@import UniformTypeIdentifiers;
@import XCTest;

#import <OCMock/OCMock.h>

@interface MockViewController : UIViewController
@property(nonatomic, retain) UIViewController *mockPresented;
@end

@implementation MockViewController
@synthesize mockPresented;

- (UIViewController *)presentedViewController {
  return mockPresented;
}

@end

@interface ImagePickerPluginTests : XCTestCase

@end

@implementation ImagePickerPluginTests

- (void)testPluginPickImageDeviceBack {
  id mockUIImagePicker = OCMClassMock([UIImagePickerController class]);
  id mockAVCaptureDevice = OCMClassMock([AVCaptureDevice class]);
  // UIImagePickerControllerSourceTypeCamera is supported
  OCMStub(ClassMethod(
              [mockUIImagePicker isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]))
      .andReturn(YES);

  // UIImagePickerControllerCameraDeviceRear is supported
  OCMStub(ClassMethod(
              [mockUIImagePicker isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]))
      .andReturn(YES);

  // AVAuthorizationStatusAuthorized is supported
  OCMStub([mockAVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
      .andReturn(AVAuthorizationStatusAuthorized);

  // Run test
  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  UIImagePickerController *controller = [[UIImagePickerController alloc] init];
  [plugin setImagePickerControllerOverrides:@[ controller ]];

  [plugin pickImageWithSource:[FLTSourceSpecification makeWithType:FLTSourceTypeCamera
                                                            camera:FLTSourceCameraRear]
                      maxSize:[[FLTMaxSize alloc] init]
                      quality:nil
                 fullMetadata:@YES
                   completion:^(NSString *_Nullable result, FlutterError *_Nullable error){
                   }];

  XCTAssertEqual(controller.cameraDevice, UIImagePickerControllerCameraDeviceRear);
}

- (void)testPluginPickImageDeviceFront {
  id mockUIImagePicker = OCMClassMock([UIImagePickerController class]);
  id mockAVCaptureDevice = OCMClassMock([AVCaptureDevice class]);
  // UIImagePickerControllerSourceTypeCamera is supported
  OCMStub(ClassMethod(
              [mockUIImagePicker isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]))
      .andReturn(YES);

  // UIImagePickerControllerCameraDeviceFront is supported
  OCMStub(ClassMethod(
              [mockUIImagePicker isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]))
      .andReturn(YES);

  // AVAuthorizationStatusAuthorized is supported
  OCMStub([mockAVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
      .andReturn(AVAuthorizationStatusAuthorized);

  // Run test
  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  UIImagePickerController *controller = [[UIImagePickerController alloc] init];
  [plugin setImagePickerControllerOverrides:@[ controller ]];

  [plugin pickImageWithSource:[FLTSourceSpecification makeWithType:FLTSourceTypeCamera
                                                            camera:FLTSourceCameraFront]
                      maxSize:[[FLTMaxSize alloc] init]
                      quality:nil
                 fullMetadata:@YES
                   completion:^(NSString *_Nullable result, FlutterError *_Nullable error){
                   }];

  XCTAssertEqual(controller.cameraDevice, UIImagePickerControllerCameraDeviceFront);
}

- (void)testPluginPickVideoDeviceBack {
  id mockUIImagePicker = OCMClassMock([UIImagePickerController class]);
  id mockAVCaptureDevice = OCMClassMock([AVCaptureDevice class]);
  // UIImagePickerControllerSourceTypeCamera is supported
  OCMStub(ClassMethod(
              [mockUIImagePicker isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]))
      .andReturn(YES);

  // UIImagePickerControllerCameraDeviceRear is supported
  OCMStub(ClassMethod(
              [mockUIImagePicker isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]))
      .andReturn(YES);

  // AVAuthorizationStatusAuthorized is supported
  OCMStub([mockAVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
      .andReturn(AVAuthorizationStatusAuthorized);

  // Run test
  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  UIImagePickerController *controller = [[UIImagePickerController alloc] init];
  [plugin setImagePickerControllerOverrides:@[ controller ]];

  [plugin pickVideoWithSource:[FLTSourceSpecification makeWithType:FLTSourceTypeCamera
                                                            camera:FLTSourceCameraRear]
                  maxDuration:nil
                   completion:^(NSString *_Nullable result, FlutterError *_Nullable error){
                   }];

  XCTAssertEqual(controller.cameraDevice, UIImagePickerControllerCameraDeviceRear);
}

- (void)testPluginPickVideoDeviceFront {
  id mockUIImagePicker = OCMClassMock([UIImagePickerController class]);
  id mockAVCaptureDevice = OCMClassMock([AVCaptureDevice class]);

  // UIImagePickerControllerSourceTypeCamera is supported
  OCMStub(ClassMethod(
              [mockUIImagePicker isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]))
      .andReturn(YES);

  // UIImagePickerControllerCameraDeviceFront is supported
  OCMStub(ClassMethod(
              [mockUIImagePicker isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]))
      .andReturn(YES);

  // AVAuthorizationStatusAuthorized is supported
  OCMStub([mockAVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
      .andReturn(AVAuthorizationStatusAuthorized);

  // Run test
  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  UIImagePickerController *controller = [[UIImagePickerController alloc] init];
  [plugin setImagePickerControllerOverrides:@[ controller ]];

  [plugin pickVideoWithSource:[FLTSourceSpecification makeWithType:FLTSourceTypeCamera
                                                            camera:FLTSourceCameraFront]
                  maxDuration:nil
                   completion:^(NSString *_Nullable result, FlutterError *_Nullable error){
                   }];

  XCTAssertEqual(controller.cameraDevice, UIImagePickerControllerCameraDeviceFront);
}

- (void)testPickMultiImageShouldUseUIImagePickerControllerOnPreiOS14 {
  if (@available(iOS 14, *)) {
    return;
  }

  id mockUIImagePicker = OCMClassMock([UIImagePickerController class]);
  id photoLibrary = OCMClassMock([PHPhotoLibrary class]);
  OCMStub(ClassMethod([photoLibrary authorizationStatus]))
      .andReturn(PHAuthorizationStatusAuthorized);

  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  [plugin setImagePickerControllerOverrides:@[ mockUIImagePicker ]];

  [plugin pickMultiImageWithMaxSize:[FLTMaxSize makeWithWidth:@(100) height:@(200)]
                            quality:@(50)
                       fullMetadata:@YES
                         completion:^(NSArray<NSString *> *_Nullable result,
                                      FlutterError *_Nullable error){
                         }];
  OCMVerify(times(1),
            [mockUIImagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary]);
}

- (void)testPickImageWithoutFullMetadata {
  id mockUIImagePicker = OCMClassMock([UIImagePickerController class]);
  id photoLibrary = OCMClassMock([PHPhotoLibrary class]);

  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  [plugin setImagePickerControllerOverrides:@[ mockUIImagePicker ]];

  [plugin pickImageWithSource:[FLTSourceSpecification makeWithType:FLTSourceTypeGallery
                                                            camera:FLTSourceCameraFront]
                      maxSize:[[FLTMaxSize alloc] init]
                      quality:nil
                 fullMetadata:@NO
                   completion:^(NSString *_Nullable result, FlutterError *_Nullable error){
                   }];

  OCMVerify(times(0), [photoLibrary authorizationStatus]);
}

- (void)testPickMultiImageWithoutFullMetadata {
  id mockUIImagePicker = OCMClassMock([UIImagePickerController class]);
  id photoLibrary = OCMClassMock([PHPhotoLibrary class]);

  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  [plugin setImagePickerControllerOverrides:@[ mockUIImagePicker ]];

  [plugin pickMultiImageWithMaxSize:[[FLTMaxSize alloc] init]
                            quality:nil
                       fullMetadata:@NO
                         completion:^(NSArray<NSString *> *_Nullable result,
                                      FlutterError *_Nullable error){
                         }];

  OCMVerify(times(0), [photoLibrary authorizationStatus]);
}

#pragma mark - Test camera devices, no op on simulators

- (void)testPluginPickImageDeviceCancelClickMultipleTimes {
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    return;
  }
  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  UIImagePickerController *controller = [[UIImagePickerController alloc] init];
  plugin.imagePickerControllerOverrides = @[ controller ];

  [plugin pickImageWithSource:[FLTSourceSpecification makeWithType:FLTSourceTypeCamera
                                                            camera:FLTSourceCameraRear]
                      maxSize:[[FLTMaxSize alloc] init]
                      quality:nil
                 fullMetadata:@YES
                   completion:^(NSString *_Nullable result, FlutterError *_Nullable error){
                   }];

  // To ensure the flow does not crash by multiple cancel call
  [plugin imagePickerControllerDidCancel:controller];
  [plugin imagePickerControllerDidCancel:controller];
}

#pragma mark - Test video duration

- (void)testPickingVideoWithDuration {
  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  UIImagePickerController *controller = [[UIImagePickerController alloc] init];
  [plugin setImagePickerControllerOverrides:@[ controller ]];

  [plugin pickVideoWithSource:[FLTSourceSpecification makeWithType:FLTSourceTypeCamera
                                                            camera:FLTSourceCameraRear]
                  maxDuration:@(95)
                   completion:^(NSString *_Nullable result, FlutterError *_Nullable error){
                   }];

  XCTAssertEqual(controller.videoMaximumDuration, 95);
}

- (void)testViewController {
  UIWindow *window = [UIWindow new];
  MockViewController *vc1 = [MockViewController new];
  window.rootViewController = vc1;

  UIViewController *vc2 = [UIViewController new];
  vc1.mockPresented = vc2;

  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  XCTAssertEqual([plugin viewControllerWithWindow:window], vc2);
}

- (void)testPluginMultiImagePathHasNullItem {
  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];

  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];
  plugin.callContext = [[FLTImagePickerMethodCallContext alloc]
      initWithResult:^(NSArray<NSString *> *_Nullable result, FlutterError *_Nullable error) {
        XCTAssertEqualObjects(error.code, @"create_error");
        [resultExpectation fulfill];
      }];
  [plugin sendCallResultWithSavedPathList:@[ [NSNull null] ]];

  [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testPluginMultiImagePathHasItem {
  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];
  NSArray *pathList = @[ @"test" ];

  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];

  plugin.callContext = [[FLTImagePickerMethodCallContext alloc]
      initWithResult:^(NSArray<NSString *> *_Nullable result, FlutterError *_Nullable error) {
        XCTAssertEqualObjects(result, pathList);
        [resultExpectation fulfill];
      }];
  [plugin sendCallResultWithSavedPathList:pathList];

  [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testSendsImageInvalidSourceError API_AVAILABLE(ios(14)) {
  id mockPickerViewController = OCMClassMock([PHPickerViewController class]);

  id mockItemProvider = OCMClassMock([NSItemProvider class]);
  // Does not conform to image, invalid source.
  OCMStub([mockItemProvider hasItemConformingToTypeIdentifier:OCMOCK_ANY]).andReturn(NO);

  PHPickerResult *failResult1 = OCMClassMock([PHPickerResult class]);
  OCMStub([failResult1 itemProvider]).andReturn(mockItemProvider);

  PHPickerResult *failResult2 = OCMClassMock([PHPickerResult class]);
  OCMStub([failResult2 itemProvider]).andReturn(mockItemProvider);

  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];

  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];

  plugin.callContext = [[FLTImagePickerMethodCallContext alloc]
      initWithResult:^(NSArray<NSString *> *result, FlutterError *error) {
        XCTAssertTrue(NSThread.isMainThread);
        XCTAssertNil(result);
        XCTAssertEqualObjects(error.code, @"invalid_source");
        [resultExpectation fulfill];
      }];

  [plugin picker:mockPickerViewController didFinishPicking:@[ failResult1, failResult2 ]];

  [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testSendsImageInvalidErrorWhenOneFails API_AVAILABLE(ios(14)) {
  id mockPickerViewController = OCMClassMock([PHPickerViewController class]);
  NSError *loadDataError = [NSError errorWithDomain:@"PHPickerDomain" code:1234 userInfo:nil];

  id mockFailItemProvider = OCMClassMock([NSItemProvider class]);
  OCMStub([mockFailItemProvider hasItemConformingToTypeIdentifier:OCMOCK_ANY]).andReturn(YES);
  [[mockFailItemProvider stub]
      loadDataRepresentationForTypeIdentifier:OCMOCK_ANY
                            completionHandler:[OCMArg invokeBlockWithArgs:[NSNull null],
                                                                          loadDataError, nil]];

  PHPickerResult *failResult = OCMClassMock([PHPickerResult class]);
  OCMStub([failResult itemProvider]).andReturn(mockFailItemProvider);

  NSURL *tiffURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"tiffImage"
                                                            withExtension:@"tiff"];
  NSItemProvider *tiffItemProvider = [[NSItemProvider alloc] initWithContentsOfURL:tiffURL];
  PHPickerResult *tiffResult = OCMClassMock([PHPickerResult class]);
  OCMStub([tiffResult itemProvider]).andReturn(tiffItemProvider);

  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];

  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];

  plugin.callContext = [[FLTImagePickerMethodCallContext alloc]
      initWithResult:^(NSArray<NSString *> *result, FlutterError *error) {
        XCTAssertTrue(NSThread.isMainThread);
        XCTAssertNil(result);
        XCTAssertEqualObjects(error.code, @"invalid_image");
        [resultExpectation fulfill];
      }];

  [plugin picker:mockPickerViewController didFinishPicking:@[ failResult, tiffResult ]];

  [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testSavesImages API_AVAILABLE(ios(14)) {
  id mockPickerViewController = OCMClassMock([PHPickerViewController class]);

  NSURL *tiffURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"tiffImage"
                                                            withExtension:@"tiff"];
  NSItemProvider *tiffItemProvider = [[NSItemProvider alloc] initWithContentsOfURL:tiffURL];
  PHPickerResult *tiffResult = OCMClassMock([PHPickerResult class]);
  OCMStub([tiffResult itemProvider]).andReturn(tiffItemProvider);

  NSURL *pngURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"pngImage"
                                                           withExtension:@"png"];
  NSItemProvider *pngItemProvider = [[NSItemProvider alloc] initWithContentsOfURL:pngURL];
  PHPickerResult *pngResult = OCMClassMock([PHPickerResult class]);
  OCMStub([pngResult itemProvider]).andReturn(pngItemProvider);

  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];

  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];

  plugin.callContext = [[FLTImagePickerMethodCallContext alloc]
      initWithResult:^(NSArray<NSString *> *result, FlutterError *error) {
        XCTAssertTrue(NSThread.isMainThread);
        XCTAssertEqual(result.count, 2);
        XCTAssertNil(error);
        [resultExpectation fulfill];
      }];

  [plugin picker:mockPickerViewController didFinishPicking:@[ tiffResult, pngResult ]];

  [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testPickImageRequestAuthorization API_AVAILABLE(ios(14)) {
  id mockPhotoLibrary = OCMClassMock([PHPhotoLibrary class]);
  OCMStub([mockPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite])
      .andReturn(PHAuthorizationStatusNotDetermined);
  OCMExpect([mockPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite
                                                         handler:OCMOCK_ANY]);

  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];

  [plugin pickImageWithSource:[FLTSourceSpecification makeWithType:FLTSourceTypeGallery
                                                            camera:FLTSourceCameraFront]
                      maxSize:[[FLTMaxSize alloc] init]
                      quality:nil
                 fullMetadata:@YES
                   completion:^(NSString *result, FlutterError *error){
                   }];
  OCMVerifyAll(mockPhotoLibrary);
}

- (void)testPickImageAuthorizationDenied API_AVAILABLE(ios(14)) {
  id mockPhotoLibrary = OCMClassMock([PHPhotoLibrary class]);
  OCMStub([mockPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite])
      .andReturn(PHAuthorizationStatusDenied);

  FLTImagePickerPlugin *plugin = [[FLTImagePickerPlugin alloc] init];

  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];

  [plugin pickImageWithSource:[FLTSourceSpecification makeWithType:FLTSourceTypeGallery
                                                            camera:FLTSourceCameraFront]
                      maxSize:[[FLTMaxSize alloc] init]
                      quality:nil
                 fullMetadata:@YES
                   completion:^(NSString *result, FlutterError *error) {
                     XCTAssertNil(result);
                     XCTAssertEqualObjects(error.code, @"photo_access_denied");
                     XCTAssertEqualObjects(error.message, @"The user did not allow photo access.");
                     [resultExpectation fulfill];
                   }];
  [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end
