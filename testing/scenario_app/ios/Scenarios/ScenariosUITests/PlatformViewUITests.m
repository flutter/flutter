// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/flutter.h>
#import <XCTest/XCTest.h>
#include <sys/sysctl.h>

#import "../Scenarios/TextPlatformView.h"

@interface PlatformViewUITests : XCTestCase
@property(nonatomic, strong) XCUIApplication* application;
@end

@implementation PlatformViewUITests

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;

  self.application = [[XCUIApplication alloc] init];
  self.application.launchArguments = @[ @"--platform-view" ];
  [self.application launch];
}

- (void)testPlatformView {
  NSBundle* bundle = [NSBundle bundleForClass:[self class]];
  NSString* goldenName =
      [NSString stringWithFormat:@"golden_platform_view_%@", [self platformName]];
  NSString* path = [bundle pathForResource:goldenName ofType:@"png"];
  UIImage* golden = [[UIImage alloc] initWithContentsOfFile:path];

  XCUIScreenshot* screenshot = [[XCUIScreen mainScreen] screenshot];
  XCTAttachment* attachment = [XCTAttachment attachmentWithScreenshot:screenshot];
  attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
  [self addAttachment:attachment];

  if (golden) {
    XCTAttachment* goldenAttachment = [XCTAttachment attachmentWithImage:golden];
    goldenAttachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:goldenAttachment];
  } else {
    XCTFail(@"This test will fail - no golden named %@ found. Follow the steps in the "
            @"README to add a new golden.",
            goldenName);
  }

  XCTAssertTrue([self compareImage:golden toOther:screenshot.image]);
}

- (NSString*)platformName {
  NSString* simulatorName =
      [[NSProcessInfo processInfo].environment objectForKey:@"SIMULATOR_DEVICE_NAME"];
  if (simulatorName) {
    return [NSString stringWithFormat:@"%@_simulator", simulatorName];
  }

  size_t size;
  sysctlbyname("hw.model", NULL, &size, NULL, 0);
  char* answer = malloc(size);
  sysctlbyname("hw.model", answer, &size, NULL, 0);

  NSString* results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
  free(answer);
  return results;
}

- (BOOL)compareImage:(UIImage*)a toOther:(UIImage*)b {
  CGImageRef imageRefA = [a CGImage];
  CGImageRef imageRefB = [b CGImage];

  NSUInteger widthA = CGImageGetWidth(imageRefA);
  NSUInteger heightA = CGImageGetHeight(imageRefA);
  NSUInteger widthB = CGImageGetWidth(imageRefB);
  NSUInteger heightB = CGImageGetHeight(imageRefB);

  if (widthA != widthB || heightA != heightB) {
    return NO;
  }
  NSUInteger bytesPerPixel = 4;
  NSUInteger size = widthA * heightA * bytesPerPixel;
  NSMutableData* rawA = [NSMutableData dataWithLength:size];
  NSMutableData* rawB = [NSMutableData dataWithLength:size];

  if (!rawA || !rawB) {
    return NO;
  }

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

  NSUInteger bytesPerRow = bytesPerPixel * widthA;
  NSUInteger bitsPerComponent = 8;
  CGContextRef contextA =
      CGBitmapContextCreate(rawA.mutableBytes, widthA, heightA, bitsPerComponent, bytesPerRow,
                            colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

  CGContextDrawImage(contextA, CGRectMake(0, 0, widthA, heightA), imageRefA);
  CGContextRelease(contextA);

  CGContextRef contextB =
      CGBitmapContextCreate(rawB.mutableBytes, widthA, heightA, bitsPerComponent, bytesPerRow,
                            colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(colorSpace);

  CGContextDrawImage(contextB, CGRectMake(0, 0, widthA, heightA), imageRefB);
  CGContextRelease(contextB);

  if (memcmp(rawA.mutableBytes, rawB.mutableBytes, size)) {
    return NO;
  }

  return YES;
}

@end
