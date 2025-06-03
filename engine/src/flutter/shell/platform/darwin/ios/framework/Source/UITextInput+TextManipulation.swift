// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

/// This protocol provides

@objc public final class FlutterTextPosition: UITextPosition, NSCopying {
  let offset: UInt
  @objc let affinity: UITextStorageDirection

  @objc init(index: UInt, affinity: UITextStorageDirection = .forward) {
    self.offset = index
    self.affinity = affinity
  }

  @objc class func position(withIndex index: UInt, affinity: UITextStorageDirection)
    -> FlutterTextPosition
  {
    FlutterTextPosition(index: index, affinity: affinity)
  }

  @objc class func position(withIndex index: UInt) -> FlutterTextPosition {
    FlutterTextPosition(index: index)
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    return FlutterTextPosition(index: offset, affinity: affinity)
  }
}

@objc public final class FlutterTextRange: UITextRange, NSCopying {
  internal let nsRange: NSRange

  @objc init(NSRange range: NSRange) {
    self.nsRange = range
  }

  @objc class func range(withNSRange range: NSRange) -> FlutterTextRange {
    FlutterTextRange(NSRange: range)
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    FlutterTextRange(NSRange: nsRange)
  }

  override public var start: FlutterTextPosition {
    FlutterTextPosition(index: UInt(nsRange.lowerBound))
  }
  
  override public var end: FlutterTextPosition {
    FlutterTextPosition(index: UInt(nsRange.upperBound))
  }
  
  override public var isEmpty: Bool { range.length == 0 }
}

// MARK: Convenience extensions on UITextRange and UITextPosition
@objc extension UITextRange {
  public var range: NSRange { (self as! FlutterTextRange).nsRange }
}

@objc extension UITextPosition {
  /// The offset from the start of the document to this FlutterTextPosition, in UTF16 code units.
  public var index: UInt { (self as! FlutterTextPosition).offset }

  public func offset(by offset: Int, inDocument document: UITextInputDefaultImpl)
    -> FlutterTextPosition?
  {
    let newOffset = offset + Int(index)
    if newOffset < 0 || newOffset > (document.fullText as NSString).length {
      return nil
    }
    return FlutterTextPosition(
      index: UInt(newOffset), affinity: document.selectionAffinity ?? .forward)
  }
}

@objc public protocol UITextInputDefaultImpl: UITextInput, NSObjectProtocol {
  var fullText: String { get }
}

// MARK: Position & Range alrithmetics and equality
