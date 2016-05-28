// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "mojo/data_pipe_utils/data_pipe_utils.h"
#include "sky/services/media/ios/media_player_impl.h"

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioClient : NSObject

- (instancetype)initWithPath:(NSString*)path;

- (BOOL)play;
- (void)pause;
- (BOOL)seekTo:(NSTimeInterval)interval;
- (void)setVolume:(double)volume;
- (void)setLooping:(BOOL)loop;

+ (NSString*)temporaryFilePath;

@end

@implementation AudioClient {
  AVAudioPlayer* _player;
}

- (instancetype)initWithPath:(NSString*)path {
  self = [super init];

  if (self) {
    NSError* error = nil;
    _player =
        [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path]
                                               error:&error];

    if (error != nil) {
      NSLog(@"Could not initialize audio client: %@",
            error.localizedDescription);
      [self release];
      return nil;
    }
  }

  return self;
}

- (BOOL)play {
  return [_player play];
}

- (void)pause {
  [_player pause];
}

- (BOOL)seekTo:(NSTimeInterval)interval {
  return [_player playAtTime:_player.deviceCurrentTime + interval];
}

- (void)setVolume:(double)volume {
  if (volume > 1.0) {
    volume = 1.0;
  }

  if (volume < 0.0) {
    volume = 0.0;
  }

  _player.volume = volume;
}

- (void)setLooping:(BOOL)shouldLoop {
  _player.numberOfLoops = shouldLoop ? -1 : 0;
}

+ (NSString*)temporaryFilePath {
  char temp[256] = {0};

  snprintf(temp, sizeof(temp), "%smedia.XXXXXX", NSTemporaryDirectory().UTF8String);
  char *path = mktemp(temp);

  if (path == NULL) {
    return NULL;
  }

  return [NSString stringWithUTF8String:path];
}

- (void)dealloc {
  [_player release];

  [super dealloc];
}

@end

namespace sky {
namespace services {
namespace media {

MediaPlayerImpl::MediaPlayerImpl(
    mojo::InterfaceRequest<::media::MediaPlayer> request)
    : binding_(this, request.Pass()), audio_client_(nullptr) {}

MediaPlayerImpl::~MediaPlayerImpl() {
  reset();
}

void MediaPlayerImpl::Prepare(
    mojo::ScopedDataPipeConsumerHandle data_source,
    const ::media::MediaPlayer::PrepareCallback& callback) {
  reset();

  NSString* filePath = [AudioClient temporaryFilePath];
  base::FilePath path(filePath.UTF8String);

  auto taskRunner = base::MessageLoop::current()->task_runner().get();
  auto copyCallback = base::Bind(&MediaPlayerImpl::onCopyToTemp,
                                 base::Unretained(this), callback, path);
  mojo::common::CopyToFile(data_source.Pass(), path, taskRunner, copyCallback);
}

void MediaPlayerImpl::onCopyToTemp(
    const ::media::MediaPlayer::PrepareCallback& callback,
    base::FilePath path,
    bool success) {
  if (success) {
    NSString* filePath =
        [NSString stringWithUTF8String:path.AsUTF8Unsafe().c_str()];
    audio_client_ = [[AudioClient alloc] initWithPath:filePath];
  } else {
    reset();
  }
  callback.Run(success && audio_client_ != nullptr);
}

void MediaPlayerImpl::Start() {
  [audio_client_ play];
}

void MediaPlayerImpl::Pause() {
  [audio_client_ pause];
}

void MediaPlayerImpl::SeekTo(uint32_t msec) {
  [audio_client_ seekTo:msec * 1e-3];
}

void MediaPlayerImpl::reset() {
  [audio_client_ release];
  audio_client_ = nullptr;
}

void MediaPlayerImpl::SetVolume(float volume) {
  [audio_client_ setVolume:volume];
}

void MediaPlayerImpl::SetLooping(bool looping) {
  [audio_client_ setLooping:looping];
}

}  // namespace media
}  // namespace services
}  // namespace sky
