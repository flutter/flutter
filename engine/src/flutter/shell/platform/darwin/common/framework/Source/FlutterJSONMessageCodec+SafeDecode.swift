// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

// The extension is implemented in Swift because `JSONSerialization.jsonObject`
// converts `data` to a `String` using [NSString initWithBytes:length:encoding:],
// before passing it to the JSON parser. In Swift the initializer replaces
// unpaired surrogates in the String with `U+FFFD`, but this doesn't happen in
// Objective-C.
//
// Seealso: https://github.com/flutter/flutter/issues/179727.
@objc extension FlutterJSONMessageCodec {
  func decodeMessage(_ data: Data) throws -> Any {
    return try JSONSerialization.jsonObject(
      with: data,
      options: [.fragmentsAllowed]
    )
  }
}
