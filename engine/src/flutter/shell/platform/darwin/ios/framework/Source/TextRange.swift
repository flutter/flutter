// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

/// A UITextPosition subclass that represents a location in the text, in
/// a Flutter text field.
@objc(FlutterTextPosition)
final class TextPosition: UITextPosition, NSCopying {
  // UITextInput implementations should access the offset via the `index`
  // computed property instead.
  fileprivate let offset: UInt
  @objc let affinity: UITextStorageDirection

  init(index: UInt, affinity: UITextStorageDirection = .forward) {
    self.offset = index
    self.affinity = affinity
  }

  func copy(with zone: NSZone? = nil) -> Any {
    return TextPosition(index: offset, affinity: affinity)
  }

  override var description: String {
    "TextPosition(\(index))"
  }
}

/// A UITextRange subclass that represents a text range within the text, in
/// a Flutter text field.
///
/// Similar to the dart:ui TextRange class, this class represents a right open
/// interval of two `TextPosition`s.
@objc(FlutterTextRange)
final class TextRange: UITextRange, NSCopying {
  // nsRange is exposed as `range` in an extension on UITextPosition.
  fileprivate let nsRange: NSRange

  init(NSRange range: NSRange) {
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
  /// The UTF16 range this TextRange represents.
  ///
  /// This computed property throws if the receiver is not a TextRange.
  /// This is a left closed right open interval.
  var range: NSRange {
    assert(self is TextRange, "Unexpected UITextRange type: \(type(of: self))")
    (self as! TextRange).nsRange
  }
}

@objc extension UITextPosition {
  /// The offset from the start of the document to this TextPosition, in UTF16 code units.
  ///
  /// This computed property throws if the receiver is not a TextPosition.
  var index: UInt {
    assert(self is TextPosition, "Unexpected UITextPosition type: \(type(of: self))")
    (self as! TextPosition).offset
  }
}
