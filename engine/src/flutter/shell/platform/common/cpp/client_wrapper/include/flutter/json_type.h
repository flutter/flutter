// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_JSON_TYPE_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_JSON_TYPE_H_

// By default, the Json codecs use jsoncpp, but a version using RapidJSON is
// implemented as well. To use the latter, set USE_RAPID_JSON.
//
// When writing code using the JSON codec classes, do not use JsonValueType;
// instead use the underlying type for the library you have selected directly.

#ifdef USE_RAPID_JSON
#include <rapidjson/document.h>

// The APIs often pass owning references, which in RapidJSON must include the
// allocator, so the value type for the APIs is Document rather than Value.
using JsonValueType = rapidjson::Document;
#else
#include <json/json.h>

using JsonValueType = Json::Value;
#endif

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_JSON_TYPE_H_
