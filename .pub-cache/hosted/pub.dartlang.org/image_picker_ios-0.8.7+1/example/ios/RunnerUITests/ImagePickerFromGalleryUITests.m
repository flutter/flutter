// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>
#import <os/log.h>

const int kElementWaitingTime = 30;

@interface ImagePickerFromGalleryUITests : XCTestCase

@property(nonatomic, strong) XCUIApplication *app;

@end

@implementation ImagePickerFromGalleryUITests

- (void)setUp {
  [super setUp];
  // Delete the app if already exists, to test permission popups

  self.continueAfterFailure = NO;
  self.app = [[XCUIApplication alloc] init];
  [self.app launch];
  __weak typeof(self) weakSelf = self;
  [self addUIInterruptionMonitorWithDescription:@"Permission popups"
                                        handler:^BOOL(XCUIElement *_Nonnull interruptingElement) {
                                          if (@available(iOS 14, *)) {
                                            XCUIElement *allPhotoPermission =
                                                interruptingElement
                                                    .buttons[@"Allow Access to All Photos"];
                                            if (![allPhotoPermission waitForExistenceWithTimeout:
                                                                         kElementWaitingTime]) {
                                              os_log_error(OS_LOG_DEFAULT, "%@",
                                                           weakSelf.app.debugDescription);
                                              XCTFail(@"Failed due to not able to find "
                                                      @"allPhotoPermission button with %@ seconds",
                                                      @(kElementWaitingTime));
                                            }
                                            [allPhotoPermission tap];
                                          } else {
                                            XCUIElement *ok = interruptingElement.buttons[@"OK"];
                                            if (![ok waitForExistenceWithTimeout:
                                                         kElementWaitingTime]) {
                                              os_log_error(OS_LOG_DEFAULT, "%@",
                                                           weakSelf.app.debugDescription);
                                              XCTFail(@"Failed due to not able to find ok button "
                                                      @"with %@ seconds",
                                                      @(kElementWaitingTime));
                                            }
                                            [ok tap];
                                          }
                                          return YES;
                                        }];
}

- (void)tearDown {
  [super tearDown];
  [self.app terminate];
}

- (void)testCancel {
  // Find and tap on the pick from gallery button.
  XCUIElement *imageFromGalleryButton =
      self.app.otherElements[@"image_picker_example_from_gallery"].firstMatch;
  if (![imageFromGalleryButton waitForExistenceWithTimeout:kElementWaitingTime]) {
    os_log_error(OS_LOG_DEFAULT, "%@", self.app.debugDescription);
    XCTFail(@"Failed due to not able to find image from gallery button with %@ seconds",
            @(kElementWaitingTime));
  }

  [imageFromGalleryButton tap];

  // Find and tap on the `pick` button.
  XCUIElement *pickButton = self.app.buttons[@"PICK"].firstMatch;
  if (![pickButton waitForExistenceWithTimeout:kElementWaitingTime]) {
    os_log_error(OS_LOG_DEFAULT, "%@", self.app.debugDescription);
    XCTFail(@"Failed due to not able to find pick button with %@ seconds", @(kElementWaitingTime));
  }

  [pickButton tap];

  // There is a known bug where the permission popups interruption won't get fired until a tap
  // happened in the app. We expect a permission popup so we do a tap here.
  [self.app tap];

  // Find and tap on the `Cancel` button.
  XCUIElement *cancelButton = self.app.buttons[@"Cancel"].firstMatch;
  if (![cancelButton waitForExistenceWithTimeout:kElementWaitingTime]) {
    os_log_error(OS_LOG_DEFAULT, "%@", self.app.debugDescription);
    XCTFail(@"Failed due to not able to find Cancel button with %@ seconds",
            @(kElementWaitingTime));
  }

  [cancelButton tap];

  // Find the "not picked image text".
  XCUIElement *imageNotPickedText =
      self.app.staticTexts[@"You have not yet picked an image."].firstMatch;
  if (![imageNotPickedText waitForExistenceWithTimeout:kElementWaitingTime]) {
    os_log_error(OS_LOG_DEFAULT, "%@", self.app.debugDescription);
    XCTFail(@"Failed due to not able to find imageNotPickedText with %@ seconds",
            @(kElementWaitingTime));
  }
}

- (void)testPickingFromGallery {
  [self launchPickerAndPickWithMaxWidth:nil maxHeight:nil quality:nil];
}

- (void)testPickingWithContraintsFromGallery {
  [self launchPickerAndPickWithMaxWidth:@200 maxHeight:@100 quality:@50];
}

- (void)launchPickerAndPickWithMaxWidth:(NSNumber *)maxWidth
                              maxHeight:(NSNumber *)maxHeight
                                quality:(NSNumber *)quality {
  // Find and tap on the pick from gallery button.
  XCUIElement *imageFromGalleryButton =
      self.app.otherElements[@"image_picker_example_from_gallery"].firstMatch;
  if (![imageFromGalleryButton waitForExistenceWithTimeout:kElementWaitingTime]) {
    os_log_error(OS_LOG_DEFAULT, "%@", self.app.debugDescription);
    XCTFail(@"Failed due to not able to find image from gallery button with %@ seconds",
            @(kElementWaitingTime));
  }
  [imageFromGalleryButton tap];

  if (maxWidth != nil) {
    XCUIElement *field = self.app.textFields[@"Enter maxWidth if desired"].firstMatch;
    [field tap];
    [field typeText:maxWidth.stringValue];
  }

  if (maxHeight != nil) {
    XCUIElement *field = self.app.textFields[@"Enter maxHeight if desired"].firstMatch;
    [field tap];
    [field typeText:maxHeight.stringValue];
  }

  if (quality != nil) {
    XCUIElement *field = self.app.textFields[@"Enter quality if desired"].firstMatch;
    [field tap];
    [field typeText:quality.stringValue];
  }

  // Find and tap on the `pick` button.
  XCUIElement *pickButton = self.app.buttons[@"PICK"].firstMatch;
  if (![pickButton waitForExistenceWithTimeout:kElementWaitingTime]) {
    os_log_error(OS_LOG_DEFAULT, "%@", self.app.debugDescription);
    XCTFail(@"Failed due to not able to find pick button with %@ seconds", @(kElementWaitingTime));
  }
  [pickButton tap];

  // There is a known bug where the permission popups interruption won't get fired until a tap
  // happened in the app. We expect a permission popup so we do a tap here.
  [self.app tap];

  // Find an image and tap on it. (IOS 14 UI, images are showing directly)
  XCUIElement *aImage;
  if (@available(iOS 14, *)) {
    aImage = [self.app.scrollViews.firstMatch.images elementBoundByIndex:1];
  } else {
    XCUIElement *allPhotosCell = self.app.cells[@"All Photos"].firstMatch;
    if (![allPhotosCell waitForExistenceWithTimeout:kElementWaitingTime]) {
      os_log_error(OS_LOG_DEFAULT, "%@", self.app.debugDescription);
      XCTFail(@"Failed due to not able to find \"All Photos\" cell with %@ seconds",
              @(kElementWaitingTime));
    }
    [allPhotosCell tap];
    aImage = [self.app.collectionViews elementMatchingType:XCUIElementTypeCollectionView
                                                identifier:@"PhotosGridView"]
                 .cells.firstMatch;
  }
  os_log_error(OS_LOG_DEFAULT, "description before picking image %@", self.app.debugDescription);
  if (![aImage waitForExistenceWithTimeout:kElementWaitingTime]) {
    os_log_error(OS_LOG_DEFAULT, "%@", self.app.debugDescription);
    XCTFail(@"Failed due to not able to find an image with %@ seconds", @(kElementWaitingTime));
  }
  [aImage tap];

  // Find the picked image.
  XCUIElement *pickedImage = self.app.images[@"image_picker_example_picked_image"].firstMatch;
  if (![pickedImage waitForExistenceWithTimeout:kElementWaitingTime]) {
    os_log_error(OS_LOG_DEFAULT, "%@", self.app.debugDescription);
    XCTFail(@"Failed due to not able to find pickedImage with %@ seconds", @(kElementWaitingTime));
  }
}

@end
