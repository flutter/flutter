// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// A Swift class the Objective-C++ test reaches through the module's
/// generated header (`MacosSwiftSmoke/MacosSwiftSmoke.h`), calling C from
/// the bridging header: what darwin/common's InternalFlutterSwiftCommon
/// does for the Flutter framework.
@objc public class FlutterBazelSwiftSmoke: NSObject {
  /// `text` reversed, through Swift's String.
  @objc public static func reversed(_ text: String) -> String {
    return String(text.reversed())
  }

  /// smoke_c_source.c's answer, through the bridging header.
  @objc public static func answerFromC() -> Int32 {
    return FlutterBazelSwiftSmokeCAnswer()
  }
}
