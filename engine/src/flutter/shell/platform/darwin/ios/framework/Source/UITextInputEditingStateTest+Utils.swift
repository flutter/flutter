// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extension String.UTF16View {
  subscript(index: UInt) -> Unicode.UTF16.CodeUnit {
    self[self.index(startIndex, offsetBy: Int(index))]
  }
}

struct TextSelection: Equatable {
  init(base: UInt, extent: UInt, markedRange: Range<UInt>?) {
    self.base = base
    self.extent = extent
    precondition(
      markedRange.map { $0.lowerBound <= min(base, extent) && max(base, extent) <= $0.upperBound }
        ?? true)
    precondition(!(markedRange?.isEmpty ?? false))
    self.markedRange = markedRange
  }

  static func allVariations(_ utf16Length: UInt) -> [TextSelection] {
    if utf16Length == 0 {
      return [TextSelection(base: 0, extent: 0, markedRange: nil)]
    }
    let allMarkedRanges: [Range<UInt>?] =
      [nil]
      + (0..<utf16Length)
      .flatMap { start in ((start + 1)...utf16Length).map { start..<$0 } }
    return allMarkedRanges.flatMap { markedRange in
      let allowedRange = markedRange ?? 0..<utf16Length
      let selectionRange = (allowedRange.lowerBound...allowedRange.upperBound)

      return selectionRange.flatMap { base in
        selectionRange.map { TextSelection(base: base, extent: $0, markedRange: markedRange) }
      }
    }
  }

  let base: UInt
  let extent: UInt
  let markedRange: Range<UInt>?

  var range: Range<UInt> {
    min(base, extent)..<max(base, extent)
  }
  var relativeRange: Range<UInt> {
    let range = self.range
    let baseOffset = markedRange?.lowerBound ?? 0
    return (range.lowerBound - baseOffset)..<(range.upperBound - baseOffset)
  }
}

// This is a UITextInput implementation-agnostic data type that represents
// the current editing state in a UITextInput.
// It is used in tests to compare the text editing states of different
// UITextInput implementations
struct EditingState: Equatable {
  init(string: String, selectedTextRange: TextSelection?) {
    self.string = string
    self.selectedTextRange = selectedTextRange
    precondition(selectedTextRange.map { $0.range.upperBound <= string.utf16.count } ?? true)
    precondition(selectedTextRange?.markedRange.map { $0.upperBound <= string.utf16.count } ?? true)
  }

  init(string: String) {
    let caret = UInt(string.utf16.count)
    self.init(
      string: string, selectedTextRange: TextSelection(base: caret, extent: caret, markedRange: nil)
    )
  }

  init(string: String, markedTextRange: Range<UInt>) {
    self.init(
      string: string,
      selectedTextRange: TextSelection(
        base: markedTextRange.upperBound, extent: markedTextRange.upperBound,
        markedRange: markedTextRange))
  }

  /// Returns all unique EditingStates with different marked text range and selection
  /// range, given the text.
  static func allVariations(_ text: String) -> [EditingState] {
    TextSelection.allVariations(UInt(text.utf16.count)).map {
      EditingState(string: text, selectedTextRange: $0)
    } + [EditingState(string: text, selectedTextRange: nil)]
  }

  let string: String

  let selectedTextRange: TextSelection?

  // Whether the EditingState's selection or marked range breaks codepoint
  // (i.e., cuts a surrogate pair in half). UITextView may throw out-of-bounds
  // exceptions when performing backspace deletion if this flag is true.
  var selectionBreaksCodepoint: Bool {
    guard let selectedTextRange = self.selectedTextRange else {
      return true
    }
    func rangeBreaksCodepoint(_ range: Range<UInt>) -> Bool {
      guard range.lowerBound < string.utf16.count else {
        return false
      }
      return Unicode.UTF16.isTrailSurrogate(string.utf16[range.lowerBound])
        || (!range.isEmpty && Unicode.UTF16.isLeadSurrogate(string.utf16[range.upperBound - 1]))
    }
    return rangeBreaksCodepoint(selectedTextRange.range)
      || (selectedTextRange.markedRange.map(rangeBreaksCodepoint) ?? true)
  }
}

protocol UITextInputTestable: UITextInput {
  var editingState: EditingState { get set }
}

extension UITextInput {
  fileprivate func offsetOf(_ position: UITextPosition) -> UInt {
    UInt(offset(from: self.beginningOfDocument, to: position))
  }
  fileprivate func rangeOf(_ range: UITextRange) -> Range<UInt> {
    offsetOf(range.start)..<offsetOf(range.end)
  }
  func rangeFrom(_ range: Range<UInt>) -> UITextRange {
    textRange(
      from: position(from: beginningOfDocument, offset: Int(range.lowerBound))!,
      to: position(from: beginningOfDocument, offset: Int(range.upperBound))!)!
  }
}

extension UITextInputTestable {
  var editingState: EditingState {
    get {
      let selection = selectedTextRange.map { range in
        TextSelection(
          base: offsetOf(range.start), extent: offsetOf(range.end),
          markedRange: markedTextRange.map(rangeOf))
      }
      return EditingState(
        string: text(in: textRange(from: beginningOfDocument, to: endOfDocument)!)!,
        selectedTextRange: selection)
    }
    set {
      unmarkText()
      selectedTextRange = textRange(from: beginningOfDocument, to: endOfDocument)
      insertText(newValue.string)
      if let selectedTextRange = newValue.selectedTextRange,
        let markedTextRange = selectedTextRange.markedRange
      {
        let markedCharacterRange: Range<String.Index> =
          String.Index(
            utf16Offset: Int(markedTextRange.lowerBound), in: newValue.string)..<String.Index(
            utf16Offset: Int(markedTextRange.upperBound), in: newValue.string)
        let markedText = newValue.string[markedCharacterRange]
        setMarkedText(String(markedText), selectedRange: NSRange(selectedTextRange.relativeRange))
      } else if let selectedRange = newValue.selectedTextRange {
        let newSelectedTextRange = textRange(
          from: position(from: beginningOfDocument, offset: Int(selectedRange.base))!,
          to: position(from: beginningOfDocument, offset: Int(selectedRange.extent))!)
        selectedTextRange = newSelectedTextRange
      } else {
        selectedTextRange = nil
      }
    }
  }

  // Returns all unique UITextPositions in the EditingState's text, including
  // the ones that break surrogate pairs.
  var allPositions: [UITextPosition] {
    var position: UITextPosition? = beginningOfDocument
    var positions: [UITextPosition] = []
    while let p = position {
      positions.append(p)
      position = self.position(from: p, offset: 1)
    }
    return positions
  }

  func textBefore(position: UITextPosition) -> String? {
    text(in: textRange(from: beginningOfDocument, to: position)!)
  }

  func textAfter(position: UITextPosition) -> String? {
    text(in: textRange(from: position, to: endOfDocument)!)
  }
}

// MARK: Test Object with FlutterTextInputDelegate Conformance
let fakeTextInputDelegate = FakeTextInputDelegate()
@objc class FakeTextInputDelegate: NSObject, FlutterTextInputDelegate {
  func flutterTextInputView(
    _ textInputView: FlutterTextInputView, updateEditingClient client: Int32,
    withState state: [AnyHashable: Any]
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView, updateEditingClient client: Int32,
    withState state: [AnyHashable: Any], withTag tag: String
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView, updateEditingClient client: Int32,
    withDelta state: [AnyHashable: Any]
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView, perform action: FlutterTextInputAction,
    withClient client: Int32
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView,
    updateFloatingCursor state: FlutterFloatingCursorDragState, withClient client: Int32,
    withPosition point: [AnyHashable: Any]
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView, showAutocorrectionPromptRectForStart start: UInt,
    end: UInt, withClient client: Int32
  ) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, showToolbar client: Int32) {
  }

  func flutterTextInputViewScribbleInteractionBegan(_ textInputView: FlutterTextInputView) {
  }

  func flutterTextInputViewScribbleInteractionFinished(_ textInputView: FlutterTextInputView) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView, insertTextPlaceholderWith size: CGSize,
    withClient client: Int32
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView, removeTextPlaceholder client: Int32
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView,
    didResignFirstResponderWithTextInputClient textInputClient: Int32
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView,
    willDismissEditMenuWithTextInputClient textInputClient: Int32
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView, shareSelectedText selectedText: String
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView, searchWebWithSelectedText selectedText: String
  ) {
  }

  func flutterTextInputView(
    _ textInputView: FlutterTextInputView, lookUpSelectedText selectedText: String
  ) {
  }
}
