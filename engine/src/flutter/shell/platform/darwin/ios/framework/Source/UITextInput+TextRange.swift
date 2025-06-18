// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

@objc(FlutterTextPosition)
public final class TextPosition: UITextPosition, NSCopying {
  let offset: UInt
  @objc let affinity: UITextStorageDirection

  @objc init(index: UInt, affinity: UITextStorageDirection = .forward) {
    self.offset = index
    self.affinity = affinity
  }

  override public func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? TextPosition else {
      return false
    }
    // Affinity is only visual.
    return offset == other.offset
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    return TextPosition(index: offset, affinity: affinity)
  }

  override public var description: String {
    "TextPosition(\(index))"
  }
}

@objc(FlutterTextRange)
public final class TextRange: UITextRange, NSCopying {
  internal let nsRange: NSRange

  @objc init(NSRange range: NSRange) {
    precondition(range.location != NSNotFound)
    self.nsRange = range
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    TextRange(NSRange: nsRange)
  }

  override public var start: TextPosition {
    TextPosition(index: UInt(nsRange.lowerBound))
  }

  override public var end: TextPosition {
    TextPosition(index: UInt(nsRange.upperBound))
  }

  override public var isEmpty: Bool { range.length == 0 }

  override public func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? TextRange else {
      return false
    }
    return range == other.nsRange
  }

  /// Returns the smallest TextRange that contains this TextRange and doesn't contain unpaired surrogates.
  ///
  /// This method assumes the receiver is a valid range with in the given document, and the text of the
  /// document is a well-formed string.
  ///
  /// On iOS 13, the default standard Korean keyboard incorrectly may delete the low surrogate and
  /// leaves the high surrogate in the string, resulting in a malformed string and subsequently a crash during
  /// UTF8 encoding. See: https://github.com/flutter/flutter/issues/111494.
  @objc public func safeRange(in document: UITextInput) -> TextRange {
    let fullText = document.fullText
    let start = self.start.index
    let end = self.end.index
    let startsWithTrailingSurrogate =
      start > 0 && Unicode.UTF16.isTrailSurrogate(fullText.utf16[start])
    let endsWithLeadingSurrogate =
      isEmpty
      ? startsWithTrailingSurrogate
      : Unicode.UTF16.isLeadSurrogate(fullText.utf16[end - 1])

    let newStart = startsWithTrailingSurrogate ? start - 1 : start
    let newEnd = endsWithLeadingSurrogate ? end + 1 : end
    return TextRange(
      NSRange: NSRange(location: Int(newStart), length: newStart.distance(to: newEnd)))
  }

  override public var description: String {
    "TextRange(\(range))"
  }
}

// MARK: Class methods for initializing in Objective-C

@objc extension TextPosition {
  public class func position(withIndex index: UInt, affinity: UITextStorageDirection)
    -> TextPosition
  {
    TextPosition(index: index, affinity: affinity)
  }

  public class func position(withIndex index: UInt) -> TextPosition {
    TextPosition(index: index)
  }
}

@objc extension TextRange {
  public class func range(withNSRange range: NSRange) -> TextRange {
    TextRange(NSRange: range)
  }
}

// MARK: Convenience extensions on UITextRange and UITextPosition

@objc extension UITextRange {
  /// The UTF16 range this FlutterTextRange represents.
  ///
  /// This computed property throws if the receiver is not a FlutterTextRange.
  /// This is a left closed right open interval.
  public var range: NSRange { (self as! TextRange).nsRange }
}

@objc extension UITextPosition {
  /// The offset from the start of the document to this FlutterTextPosition, in UTF16 code units.
  ///
  /// This computed property throws if the receiver is not a FlutterTextRange.
  public var index: UInt { (self as! TextPosition).offset }

  public func compare(to other: UITextPosition) -> ComparisonResult {
    let otherIndex = other.index
    let index = self.index
    if otherIndex == index {
      return .orderedSame
    } else if otherIndex > index {
      return .orderedAscending
    }
    return .orderedDescending
  }

  public func offset(by offset: Int, inDocument document: UITextInput)
    -> TextPosition?
  {
    let newOffset = offset + Int(index)
    if newOffset < 0 || newOffset > (document.fullText as NSString).length {
      return nil
    }
    return TextPosition(
      index: UInt(newOffset), affinity: document.selectionAffinity ?? .forward)
  }
}

// MARK: Convenience extensions

extension String.UTF16View {
  public subscript(index: UInt) -> Unicode.UTF16.CodeUnit {
    self[self.index(startIndex, offsetBy: Int(index))]
  }
}

@objc extension NSString {
  // Get the UTF16 range for backspace deletion, when the caret is placed at
  // `utf16Offset`.
  //
  // The implementation tries to match the behavior of this Core Foundation function:
  // https://github.com/opensource-apple/CF/blob/3cc41a76b1491f50813e28a4ec09954ffa359e6f/CFString.c#L3658-L3833
  @objc public func getBackspaceDeleteRange(forCaretLocation utf16Offset: UInt) -> NSRange {
    guard utf16Offset != 0 else {
      return NSRange(location: 0, length: 0)
    }
    precondition(utf16Offset <= length)
    let index = utf16Offset - 1
    // Under the hood, rangeOfComposedCharacterSequencet calls
    // CFStringGetRangeOfCharacterClusterAtIndex with type = kCFStringComposedCharacterCluster
    let graphemeClusterRange = rangeOfComposedCharacterSequence(at: Int(index)).range

    // Codepoints from the [Armenian, Limbu] blocks are deleted codepoint by codepoint.
    // All these codepoints are in BMP.
    let breakCodepoints: Range<Unicode.UTF16.CodeUnit> = 0x0530..<0x1950
    // ... except for jamos. The jamos block is not continous (for instance
    // 0x11FA ... 0x11FF are not assigned in Unicode so they're for private use).
    // The core foundation implementation doesn't consider
    let jamoCodepoints: Range<Unicode.UTF16.CodeUnit> = 0x1100..<0x1200

    func shouldBreak(_ offset: UInt) -> Bool {
      let character = character(at: Int(offset))
      return breakCodepoints.contains(character) && !jamoCodepoints.contains(character)
    }

    precondition(graphemeClusterRange.contains(index))

    let startIndex =
      (graphemeClusterRange.lowerBound..<index).last(where: shouldBreak).map { $0 + 1 }
      ?? graphemeClusterRange.lowerBound

    let endIndex =
      ((index + 1)..<graphemeClusterRange.upperBound).first(where: shouldBreak)
      ?? graphemeClusterRange.upperBound
    return NSRange(location: Int(startIndex), length: startIndex.distance(to: endIndex))
  }
}

extension Range<UInt> {
  var nsRange: NSRange {
    NSRange(location: Int(lowerBound), length: lowerBound.distance(to: upperBound))
  }
}

extension NSRange {
  var range: Range<UInt> {
    precondition(location != NSNotFound)
    return UInt(location)..<UInt(location + length)
  }
}

extension UITextInput {
  var fullText: String {
    text(in: textRange(from: beginningOfDocument, to: endOfDocument)!) ?? ""
  }
}
