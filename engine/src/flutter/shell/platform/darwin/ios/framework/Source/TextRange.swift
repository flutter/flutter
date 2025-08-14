// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

@objc(FlutterTextPosition)
final class TextPosition: UITextPosition, NSCopying {
  // offset is exposed as `range` in an extension on UITextPosition.
  fileprivate let offset: UInt
  @objc let affinity: UITextStorageDirection

  init(index: UInt, affinity: UITextStorageDirection = .forward) {
    self.offset = index
    self.affinity = affinity
  }

  override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? TextPosition else {
      return false
    }
    // Affinity is only visual.
    return offset == other.offset
  }

  func copy(with zone: NSZone? = nil) -> Any {
    return TextPosition(index: offset, affinity: affinity)
  }

  override var description: String {
    "TextPosition(\(index))"
  }
}

@objc(FlutterTextRange)
final class TextRange: UITextRange, NSCopying {
  // nsRange is exposed as `range` in an extension on UITextPosition.
  fileprivate let nsRange: NSRange

  init(NSRange range: NSRange) {
    assert(range.location != NSNotFound)
    self.nsRange = range
  }

  func copy(with zone: NSZone? = nil) -> Any {
    TextRange(NSRange: nsRange)
  }

  override var start: TextPosition {
    TextPosition(index: UInt(nsRange.lowerBound))
  }

  override var end: TextPosition {
    TextPosition(index: UInt(nsRange.upperBound))
  }

  override var isEmpty: Bool { range.length == 0 }

  override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? TextRange else {
      return false
    }
    return range == other.nsRange
  }

  override var description: String {
    "TextRange(\(range))"
  }
}

// MARK: Class methods for initializing in Objective-C

@available(swift, obsoleted: 1.0)
@objc extension TextPosition {
  class func position(withIndex index: UInt, affinity: UITextStorageDirection)
    -> TextPosition
  {
    TextPosition(index: index, affinity: affinity)
  }

  class func position(withIndex index: UInt) -> TextPosition {
    TextPosition(index: index)
  }
}

@objc extension TextRange {
  class func range(withNSRange range: NSRange) -> TextRange {
    TextRange(NSRange: range)
  }
}

// MARK: Convenience extensions on UITextRange and UITextPosition

@objc extension UITextRange {
  /// The UTF16 range this FlutterTextRange represents.
  ///
  /// This computed property throws if the receiver is not a FlutterTextRange.
  /// This is a left closed right open interval.
  var range: NSRange { (self as! TextRange).nsRange }
}

@objc extension UITextPosition {
  /// The offset from the start of the document to this FlutterTextPosition, in UTF16 code units.
  ///
  /// This computed property throws if the receiver is not a FlutterTextPosition.
  var index: UInt { (self as! TextPosition).offset }
}
