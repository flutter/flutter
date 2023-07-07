// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Corresponds to constants defined in Androids `android.os.Environment` class.
///
/// https://developer.android.com/reference/android/os/Environment.html#fields_1
enum StorageDirectory {
  /// Contains audio files that should be treated as music.
  ///
  /// See https://developer.android.com/reference/android/os/Environment.html#DIRECTORY_MUSIC.
  music,

  /// Contains audio files that should be treated as podcasts.
  ///
  /// See https://developer.android.com/reference/android/os/Environment.html#DIRECTORY_PODCASTS.
  podcasts,

  /// Contains audio files that should be treated as ringtones.
  ///
  /// See https://developer.android.com/reference/android/os/Environment.html#DIRECTORY_RINGTONES.
  ringtones,

  /// Contains audio files that should be treated as alarm sounds.
  ///
  /// See https://developer.android.com/reference/android/os/Environment.html#DIRECTORY_ALARMS.
  alarms,

  /// Contains audio files that should be treated as notification sounds.
  ///
  /// See https://developer.android.com/reference/android/os/Environment.html#DIRECTORY_NOTIFICATIONS.
  notifications,

  /// Contains images. See https://developer.android.com/reference/android/os/Environment.html#DIRECTORY_PICTURES.
  pictures,

  /// Contains movies. See https://developer.android.com/reference/android/os/Environment.html#DIRECTORY_MOVIES.
  movies,

  /// Contains files of any type that have been downloaded by the user.
  ///
  /// See https://developer.android.com/reference/android/os/Environment.html#DIRECTORY_DOWNLOADS.
  downloads,

  /// Used to hold both pictures and videos when the device filesystem is
  /// treated like a camera's.
  ///
  /// See https://developer.android.com/reference/android/os/Environment.html#DIRECTORY_DCIM.
  dcim,

  /// Holds user-created documents. See https://developer.android.com/reference/android/os/Environment.html#DIRECTORY_DOCUMENTS.
  documents,
}
