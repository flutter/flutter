// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_ASSERTIONS_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_ASSERTIONS_H_

#include <sstream>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/testing/assertions.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkSize.h"

//------------------------------------------------------------------------------
// Equality
//------------------------------------------------------------------------------
inline bool operator==(const FlutterPoint& a, const FlutterPoint& b) {
  return flutter::testing::NumberNear(a.x, b.x) &&
         flutter::testing::NumberNear(a.y, b.y);
}

inline bool operator==(const FlutterSize& a, const FlutterSize& b) {
  return flutter::testing::NumberNear(a.width, b.width) &&
         flutter::testing::NumberNear(a.height, b.height);
}

inline bool operator==(const FlutterOpenGLTexture& a,
                       const FlutterOpenGLTexture& b) {
  return a.target == b.target && a.name == b.name && a.format == b.format &&
         a.user_data == b.user_data &&
         a.destruction_callback == b.destruction_callback;
}

inline bool operator==(const FlutterOpenGLFramebuffer& a,
                       const FlutterOpenGLFramebuffer& b) {
  return a.target == b.target && a.name == b.name &&
         a.user_data == b.user_data &&
         a.destruction_callback == b.destruction_callback;
}

inline bool operator==(const FlutterOpenGLBackingStore& a,
                       const FlutterOpenGLBackingStore& b) {
  if (!(a.type == b.type)) {
    return false;
  }

  switch (a.type) {
    case kFlutterOpenGLTargetTypeTexture:
      return a.texture == b.texture;
    case kFlutterOpenGLTargetTypeFramebuffer:
      return a.framebuffer == b.framebuffer;
  }

  return false;
}

inline bool operator==(const FlutterSoftwareBackingStore& a,
                       const FlutterSoftwareBackingStore& b) {
  return a.allocation == b.allocation && a.row_bytes == b.row_bytes &&
         a.height == b.height && a.user_data == b.user_data &&
         a.destruction_callback == b.destruction_callback;
}

inline bool operator==(const FlutterBackingStore& a,
                       const FlutterBackingStore& b) {
  if (!(a.struct_size == b.struct_size && a.user_data == b.user_data &&
        a.type == b.type && a.did_update == b.did_update)) {
    return false;
  }

  switch (a.type) {
    case kFlutterBackingStoreTypeOpenGL:
      return a.open_gl == b.open_gl;
    case kFlutterBackingStoreTypeSoftware:
      return a.software == b.software;
  }

  return false;
}

inline bool operator==(const FlutterPlatformView& a,
                       const FlutterPlatformView& b) {
  return a.struct_size == b.struct_size && a.identifier == b.identifier;
}

inline bool operator==(const FlutterLayer& a, const FlutterLayer& b) {
  if (!(a.struct_size == b.struct_size && a.type == b.type &&
        a.offset == b.offset && a.size == b.size)) {
    return false;
  }

  switch (a.type) {
    case kFlutterLayerContentTypeBackingStore:
      return *a.backing_store == *b.backing_store;
    case kFlutterLayerContentTypePlatformView:
      return *a.platform_view == *b.platform_view;
  }

  return false;
}

//------------------------------------------------------------------------------
// Printing
//------------------------------------------------------------------------------

inline std::ostream& operator<<(std::ostream& out, const FlutterPoint& point) {
  return out << "(" << point.x << ", " << point.y << ")";
}

inline std::ostream& operator<<(std::ostream& out, const FlutterSize& size) {
  return out << "(" << size.width << ", " << size.height << ")";
}

inline std::string FlutterLayerContentTypeToString(
    FlutterLayerContentType type) {
  switch (type) {
    case kFlutterLayerContentTypeBackingStore:
      return "kFlutterLayerContentTypeBackingStore";
    case kFlutterLayerContentTypePlatformView:
      return "kFlutterLayerContentTypePlatformView";
  }
  return "Unknown";
}

inline std::string FlutterBackingStoreTypeToString(
    FlutterBackingStoreType type) {
  switch (type) {
    case kFlutterBackingStoreTypeOpenGL:
      return "kFlutterBackingStoreTypeOpenGL";
    case kFlutterBackingStoreTypeSoftware:
      return "kFlutterBackingStoreTypeSoftware";
  }
  return "Unknown";
}

inline std::ostream& operator<<(std::ostream& out,
                                const FlutterOpenGLTexture& item) {
  return out << "(FlutterOpenGLTexture) Target: 0x" << std::hex << item.target
             << std::dec << " Name: " << item.name << " Format: " << item.format
             << " User Data: " << item.user_data
             << " Destruction Callback: " << item.destruction_callback;
}

inline std::ostream& operator<<(std::ostream& out,
                                const FlutterOpenGLFramebuffer& item) {
  return out << "(FlutterOpenGLFramebuffer) Target: 0x" << std::hex
             << item.target << std::dec << " Name: " << item.name
             << " User Data: " << item.user_data
             << " Destruction Callback: " << item.destruction_callback;
}

inline std::ostream& operator<<(std::ostream& out,
                                const FlutterPlatformView& platform_view) {
  return out << "(FlutterPlatformView) Struct Size: "
             << platform_view.struct_size
             << " Identifier: " << platform_view.identifier;
}

inline std::string FlutterOpenGLTargetTypeToString(
    FlutterOpenGLTargetType type) {
  switch (type) {
    case kFlutterOpenGLTargetTypeTexture:
      return "kFlutterOpenGLTargetTypeTexture";
    case kFlutterOpenGLTargetTypeFramebuffer:
      return "kFlutterOpenGLTargetTypeFramebuffer";
  }
  return "Unknown";
}

inline std::ostream& operator<<(std::ostream& out,
                                const FlutterOpenGLBackingStore& item) {
  out << "(FlutterOpenGLBackingStore) Type: "
      << FlutterOpenGLTargetTypeToString(item.type) << " ";
  switch (item.type) {
    case kFlutterOpenGLTargetTypeTexture:
      out << item.texture;
      break;
    case kFlutterOpenGLTargetTypeFramebuffer:
      out << item.framebuffer;
      break;
  }
  return out;
}

inline std::ostream& operator<<(std::ostream& out,
                                const FlutterSoftwareBackingStore& item) {
  return out << "(FlutterSoftwareBackingStore) Allocation: " << item.allocation
             << " Row Bytes: " << item.row_bytes << " Height: " << item.height
             << " User Data: " << item.user_data
             << " Destruction Callback: " << item.destruction_callback;
}

inline std::ostream& operator<<(std::ostream& out,
                                const FlutterBackingStore& backing_store) {
  out << "(FlutterBackingStore) Struct size: " << backing_store.struct_size
      << " User Data: " << backing_store.user_data
      << " Type: " << FlutterBackingStoreTypeToString(backing_store.type)
      << " ";

  switch (backing_store.type) {
    case kFlutterBackingStoreTypeOpenGL:
      out << backing_store.open_gl;
      break;

    case kFlutterBackingStoreTypeSoftware:
      out << backing_store.software;
      break;
  }

  return out;
}

inline std::ostream& operator<<(std::ostream& out, const FlutterLayer& layer) {
  out << "(Flutter Layer) Struct size: " << layer.struct_size
      << " Type: " << FlutterLayerContentTypeToString(layer.type);

  switch (layer.type) {
    case kFlutterLayerContentTypeBackingStore:
      out << *layer.backing_store;
      break;
    case kFlutterLayerContentTypePlatformView:
      out << *layer.platform_view;
      break;
  }

  return out << " Offset: " << layer.offset << " Size: " << layer.size;
}

//------------------------------------------------------------------------------
// Factories and Casts
//------------------------------------------------------------------------------

inline FlutterPoint FlutterPointMake(double x, double y) {
  FlutterPoint point = {};
  point.x = x;
  point.y = y;
  return point;
}

inline FlutterSize FlutterSizeMake(double width, double height) {
  FlutterSize size = {};
  size.width = width;
  size.height = height;
  return size;
}

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_ASSERTIONS_H_
