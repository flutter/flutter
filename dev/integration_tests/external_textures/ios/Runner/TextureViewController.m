// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "TextureViewController.h"
#import "AppDelegate.h"

@interface TextureViewController () <FlutterTexture>
@property (nonatomic, assign) uint64_t textureId;
@property (nonatomic, assign) int framesProduced;
@property (nonatomic, assign) int framesConsumed;
@property (nonatomic, assign) int lastFrameConsumed;
@property (nonatomic, assign) double startTime;
@property (nonatomic, assign) double endTime;
@property (nonatomic, assign) double frameRate;
@property (nonatomic, assign) double frameStartTime;
@property (nonatomic, strong) NSTimer* timer;
- (void)tick:(NSTimer*)timer;
@end

@implementation TextureViewController

- (void)awakeFromNib {
  [super awakeFromNib];

  FlutterMethodChannel* channel =
      [FlutterMethodChannel methodChannelWithName:@"texture"
                                  binaryMessenger:self.binaryMessenger];
  [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      if ([@"start" isEqualToString:call.method]) {
        _framesProduced = 0;
        _framesConsumed = 0;
        _frameRate = 1.0 / [(NSNumber*) call.arguments intValue];
        _timer = [NSTimer scheduledTimerWithTimeInterval:_frameRate
                                                  target:self
                                                selector:@selector(tick:)
                                                userInfo:nil
                                                 repeats:YES];
        _startTime = [[NSDate date] timeIntervalSince1970];
        result(nil);
      } else if ([@"stop" isEqualToString:call.method]) {
        [_timer invalidate];
        _endTime = [[NSDate date] timeIntervalSince1970];
        result(nil);
      } else if ([@"getProducedFrameRate" isEqualToString:call.method]) {
        result(@(_framesProduced / (_endTime - _startTime)));
      } else if ([@"getConsumedFrameRate" isEqualToString:call.method]) {
        result(@(_framesConsumed / (_endTime - _startTime)));
      } else {
        result(FlutterMethodNotImplemented);
      }
  }];

  _textureId = [self registerTexture:self];
}

- (void)tick:(NSTimer*)timer {
  [self textureFrameAvailable:_textureId];
  _frameStartTime = [[NSDate date] timeIntervalSince1970];
  // We just pretend to be producing a frame.
  _framesProduced++;
}

- (CVPixelBufferRef)copyPixelBuffer {
  double now = [[NSDate date] timeIntervalSince1970];
  if (now < _frameStartTime
      || _frameStartTime + _frameRate < now
      || _framesProduced == _lastFrameConsumed) return nil;
  _framesConsumed++;
  _lastFrameConsumed = _framesProduced;
  // We just pretend to be handing over the produced frame to the consumer.
  return nil;
}

@end
