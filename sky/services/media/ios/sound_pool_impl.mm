// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/media/ios/sound_pool_impl.h"

#include "base/bind.h"
#include "base/files/file_util.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "base/message_loop/message_loop.h"
#include "mojo/data_pipe_utils/data_pipe_utils.h"

#include <Foundation/Foundation.h>
#include <AVFoundation/AVFoundation.h>

@interface SoundPoolClient : NSObject

- (BOOL)loadPlayer:(NSURL*)url streamOut:(int32_t*)stream;

- (BOOL)play:(int32_t)stream;

- (BOOL)play:(int32_t)stream
      volume:(float)volume
        loop:(BOOL)loop
        rate:(float)rate;

- (BOOL)resume:(int32_t)stream;

- (void)stop:(int32_t)stream;

- (void)pause:(int32_t)stream;

- (void)setRate:(float)rate stream:(int32_t)stream;

- (void)setVolume:(float)volume stream:(int32_t)stream;

- (void)pauseAll;

- (void)resumeAll;

@end

@implementation SoundPoolClient {
  NSMutableDictionary* _players;  // keyed by stream ID
  int32_t _lastID;
}

- (instancetype)init {
  self = [super init];

  if (self) {
    _players = [[NSMutableDictionary alloc] init];
  }

  return self;
}

- (BOOL)loadPlayer:(NSURL*)url streamOut:(int32_t*)stream {
  if (stream == NULL) {
    return NO;
  }

  NSError* error = NULL;
  AVAudioPlayer* player =
      [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];

  if (error != NULL) {
    [player release];
    return NO;
  }

  if (![player prepareToPlay]) {
    [player release];
    return NO;
  }

  int32_t streamID = ++_lastID;
  _players[@(streamID)] = player;
  [player release];

  *stream = streamID;
  return YES;
}

- (AVAudioPlayer*)playerForID:(int32_t)stream {
  return _players[@(stream)];
}

- (BOOL)play:(int32_t)stream {
  AVAudioPlayer *player = [self playerForID:stream];
  player.currentTime = 0.0;
  return [player play];
}

- (BOOL)play:(int32_t)stream
      volume:(float)volume
        loop:(BOOL)loop
        rate:(float)rate {
  AVAudioPlayer* player = [self playerForID:stream];

  if (player == NULL) {
    return NO;
  }

  if (volume > 1.0) {
    volume = 1.0;
  }

  if (volume < 0.0) {
    volume = 0.0;
  }

  player.volume = volume;
  player.numberOfLoops = loop ? -1 : 0;
  player.rate = rate;
  player.currentTime = 0.0;
  return [player play];
}

- (BOOL)resume:(int32_t)stream {
  // Unlike a play (from beginning), we don't set the current time to 0
  return [[self playerForID:stream] play];
}

- (void)stop:(int32_t)stream {
  return [[self playerForID:stream] stop];
}

- (void)pause:(int32_t)stream {
  return [[self playerForID:stream] pause];
}

- (void)setRate:(float)rate stream:(int32_t)stream {
  [self playerForID:stream].rate = rate;
}

- (void)setVolume:(float)volume stream:(int32_t)stream {
  if (volume > 1.0) {
    volume = 1.0;
  }

  if (volume < 0.0) {
    volume = 0.0;
  }

  [self playerForID:stream].volume = volume;
}

- (void)pauseAll {
  for (AVAudioPlayer* player in [_players allValues]) {
    [player pause];
  }
}

- (void)resumeAll {
  for (AVAudioPlayer* player in [_players allValues]) {
    [player play];
  }
}

- (void)dealloc {
  [_players release];

  [super dealloc];
}

@end

namespace sky {
namespace services {
namespace media {

SoundPoolImpl::SoundPoolImpl(mojo::InterfaceRequest<::media::SoundPool> request)
    : binding_(this, request.Pass()),
      sound_pool_([[SoundPoolClient alloc] init]) {}

SoundPoolImpl::~SoundPoolImpl() {
  [sound_pool_ release];

  for (const auto& path : temp_files_) {
    base::DeleteFile(path, false);
  }
}

static base::FilePath TemporaryFilePath() {
  char temp[256] = {0};
  NSString* tempDirectory = NSTemporaryDirectory();
  snprintf(temp, sizeof(temp), "%spool.XXXXXX", tempDirectory.UTF8String);
  base::FilePath path(mktemp(temp));
  return path;
}

void SoundPoolImpl::Load(mojo::ScopedDataPipeConsumerHandle data_source,
                         const ::media::SoundPool::LoadCallback& callback) {
  base::mac::ScopedNSAutoreleasePool pool;

  // Copy the contents of the data source to a temporary file
  auto path = TemporaryFilePath();
  auto taskRunner = base::MessageLoop::current()->task_runner().get();
  auto copyCallback = base::Bind(&SoundPoolImpl::onCopyToTemp,
                                 base::Unretained(this), callback, path);

  mojo::common::CopyToFile(data_source.Pass(), path, taskRunner, copyCallback);
}

void SoundPoolImpl::onCopyToTemp(
    const ::media::SoundPool::LoadCallback& callback,
    base::FilePath path,
    bool success) {
  base::mac::ScopedNSAutoreleasePool pool;

  if (!success) {
    callback.Run(false, 0);
    return;
  }

  temp_files_.push_back(path);

  // After the copy, initialize the audio player instance in the pool
  NSString* filePath =
      [NSString stringWithUTF8String:path.AsUTF8Unsafe().c_str()];
  NSURL* fileURL = [NSURL URLWithString:filePath];

  int32_t streamID = 0;
  BOOL loadResult = [sound_pool_ loadPlayer:fileURL streamOut:&streamID];

  // Fire user callback
  callback.Run(loadResult, loadResult ? streamID : 0);
}

static float AverageVolume(mojo::Array<float>& channel_volumes) {
  // There is no provision to set individual channel volumes. Instead, we just
  // average out the volumes and pass that to the sound pool.
  size_t volumesCount = channel_volumes.size();

  if (volumesCount == 0) {
    return 1.0;
  }

  float sum = 0;
  for (const auto& volume : channel_volumes) {
    sum += volume;
  }

  return sum / volumesCount;
}

void SoundPoolImpl::Play(int32_t sound_id,
                         int32_t stream_id,
                         mojo::Array<float> channel_volumes,
                         bool loop,
                         float rate,
                         const ::media::SoundPool::PlayCallback& callback) {
  base::mac::ScopedNSAutoreleasePool pool;
  // To match Android semantics, during the load operation, we return the
  // ID used to key the audio player in the sound pool map as the stream ID.
  // The caller is returning that ID to us as the sound ID.
  BOOL playResult = [sound_pool_ play:sound_id
                               volume:AverageVolume(channel_volumes)
                                 loop:loop
                                 rate:rate];
  callback.Run(playResult);
}

void SoundPoolImpl::Stop(int32_t stream_id) {
  base::mac::ScopedNSAutoreleasePool pool;
  [sound_pool_ stop:stream_id];
}

void SoundPoolImpl::Pause(int32_t stream_id) {
  base::mac::ScopedNSAutoreleasePool pool;
  [sound_pool_ pause:stream_id];
}

void SoundPoolImpl::Resume(int32_t stream_id) {
  base::mac::ScopedNSAutoreleasePool pool;
  [sound_pool_ resume:stream_id];
}

void SoundPoolImpl::SetRate(int32_t stream_id, float rate) {
  base::mac::ScopedNSAutoreleasePool pool;
  [sound_pool_ setRate:rate stream:stream_id];
}

void SoundPoolImpl::SetVolume(int32_t stream_id,
                              mojo::Array<float> channel_volumes) {
  base::mac::ScopedNSAutoreleasePool pool;
  [sound_pool_ setVolume:AverageVolume(channel_volumes) stream:stream_id];
}

void SoundPoolImpl::PauseAll() {
  base::mac::ScopedNSAutoreleasePool pool;
  [sound_pool_ pauseAll];
}

void SoundPoolImpl::ResumeAll() {
  base::mac::ScopedNSAutoreleasePool pool;
  [sound_pool_ resumeAll];
}

}  // namespace media
}  // namespace services
}  // namespace sky
