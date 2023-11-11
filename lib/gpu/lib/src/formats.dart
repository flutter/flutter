// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_gpu;

/// Specifies where an allocation resides and how it may be used.
enum StorageMode {
  /// Allocations can be mapped onto the hosts address space and also be used by
  /// the device.
  hostVisible,

  /// Allocations can only be used by the device. This location is optimal for
  /// use by the device. If the host needs to access these allocations, the
  /// data must first be copied into a host visible allocation.
  devicePrivate,

  /// Used by the device for temporary render targets. These allocations cannot
  /// be copied to or from other allocations. This storage mode is only valid
  /// for Textures.
  ///
  /// These allocations reside in tile memory which has higher bandwidth, lower
  /// latency and lower power consumption. The total device memory usage is
  /// also lower as a separate allocation does not need to be created in
  /// device memory. Prefer using these allocations for intermediates like depth
  /// and stencil buffers.
  deviceTransient,
}
