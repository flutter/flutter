// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import video_player;
@import XCTest;

#import <OCMock/OCMock.h>

@interface VideoPlayerTests : XCTestCase
@end

@implementation VideoPlayerTests

- (void)testPlugin {
  FLTVideoPlayerPlugin *plugin = [[FLTVideoPlayerPlugin alloc] init];
  XCTAssertNotNil(plugin);
}

- (void)testSeekToInvokesTextureFrameAvailableOnTextureRegistry {
  NSObject<FlutterTextureRegistry> *mockTextureRegistry =
      OCMProtocolMock(@protocol(FlutterTextureRegistry));
  NSObject<FlutterPluginRegistry> *registry =
      (NSObject<FlutterPluginRegistry> *)[[UIApplication sharedApplication] delegate];
  NSObject<FlutterPluginRegistrar> *registrar =
      [registry registrarForPlugin:@"TEST_FLTVideoPlayerPlugin"];
  NSObject<FlutterPluginRegistrar> *partialRegistrar = OCMPartialMock(registrar);
  OCMStub([partialRegistrar textures]).andReturn(mockTextureRegistry);
  [FLTVideoPlayerPlugin registerWithRegistrar:partialRegistrar];
  FLTVideoPlayerPlugin<FLTVideoPlayerApi> *videoPlayerPlugin =
      (FLTVideoPlayerPlugin<FLTVideoPlayerApi> *)[[FLTVideoPlayerPlugin alloc]
          initWithRegistrar:partialRegistrar];
  FLTPositionMessage *message = [[FLTPositionMessage alloc] init];
  message.textureId = @101;
  message.position = @0;
  FlutterError *error;
  [videoPlayerPlugin seekTo:message error:&error];
  OCMVerify([mockTextureRegistry textureFrameAvailable:message.textureId.intValue]);
}

@end
