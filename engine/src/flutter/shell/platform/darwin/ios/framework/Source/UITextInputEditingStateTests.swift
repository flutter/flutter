// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import UIKit
import XCTest

enum Either<L, R> {
  case left(L)
  case right(R)
}

/// Tests in this file verify that our custom UITextInput implementations
/// matches the behavior of UITextViews when receive the same input from the
/// IME.

// Swift tuples can't conform to Equtable (yet).
struct TextSelection: Equatable {
  init(base: UInt, extent: UInt, markedRange: Range<UInt>?) {
    self.base = base
    self.extent = extent
    assert(
      markedRange.map { $0.lowerBound <= min(base, extent) && max(base, extent) <= $0.upperBound }
        ?? true)
    assert(!(markedRange?.isEmpty ?? false))
    self.markedRange = markedRange
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

struct EditingState: Equatable, ExpressibleByStringLiteral {
  init(string: String, selectedTextRange: TextSelection?) {
    self.string = string
    self.selectedTextRange = selectedTextRange
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

  private static func parseComposingRegion(string: String) -> Either<
    (String, String, String), String
  > {
    // "|" is the token that represents composing regions
    let components = string.components(separatedBy: "|")
    if components.count == 1 {
      return .right(string)
    } else {
      assert(components.count == 3)
      assert(!components[1].isEmpty)
      return .left((components[0], components[1], components[2]))
    }
  }

  private static func parseSelection(string: String) -> (String, UInt, UInt) {
    assert(string.count(where: { $0 == "<" }) <= 1)
    assert(string.count(where: { $0 == ">" }) == string.count(where: { $0 == "<" }))
    let baseIndex = string.prefix(while: { $0 != "<" }).utf16.count
    let extentIndex = string.prefix(while: { $0 != ">" }).utf16.count
    if extentIndex == baseIndex {
      let caret = UInt(string.utf16.count)
      return (string, caret, caret)
    }
    let text = string.filter { c in c != "<" || c != ">" }
    return baseIndex < extentIndex
      ? (text, UInt(baseIndex), UInt(extentIndex - 1))
      : (text, UInt(baseIndex - 1), UInt(extentIndex - 1))
  }

  init(stringLiteral: StaticString) {
    let selection: TextSelection
    let string: String

    switch EditingState.parseComposingRegion(string: stringLiteral.description) {
    case let .left((p1, p2, p3)):
      let (text, start, end) = EditingState.parseSelection(string: p2)
      let markedRange = UInt(p1.utf16.count)..<UInt(p1.utf16.count + p2.utf16.count)
      selection = TextSelection(
        base: markedRange.lowerBound + start, extent: markedRange.lowerBound + end,
        markedRange: markedRange)
      string = p1 + text + p3
    case let .right(s):
      let (text, start, end) = EditingState.parseSelection(string: s)
      selection = TextSelection(base: start, extent: end, markedRange: nil)
      string = text
    }

    self.init(string: string, selectedTextRange: selection)
  }

  let string: String

  let selectedTextRange: TextSelection?
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
      if let selectedTextRange = editingState.selectedTextRange,
        let markedTextRange = selectedTextRange.markedRange
      {
        let markedCharacterRange: Range<String.Index> =
          String.Index(
            utf16Offset: Int(markedTextRange.lowerBound), in: newValue.string)..<String.Index(
            utf16Offset: Int(markedTextRange.upperBound), in: newValue.string)
        let markedText = newValue.string[markedCharacterRange]
        setMarkedText(String(markedText), selectedRange: NSRange(selectedTextRange.relativeRange))
      } else if let selectedRange = editingState.selectedTextRange {
        selectedTextRange = self.textRange(
          from: position(from: beginningOfDocument, offset: Int(selectedRange.base))!,
          to: position(from: beginningOfDocument, offset: Int(selectedRange.extent))!)
      } else {
        selectedTextRange = nil
      }
    }
  }

  // Returns all unique UITextPositions in the EditingState's text.
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

extension UITextView: UITextInputTestable {}
extension FlutterTextInputView: UITextInputTestable {}

let fakeTextInputDelegate = FakeTextInputDelegate()

//func allTestables() -> [any UITextInputTestable] {
//  [FlutterTextInputView(owner: FlutterTextInputPlugin(delegate: fakeTextInputDelegate))]
//}
//
//@Suite
//struct UITextInputTestableTests {
//  //@Test(arguments: [EditingState.empty])
//  //func huh(implementation: any UITextInputTestable, initialState: EditingState) {
//    //#expect(Bool(false), "test")
//  //}
//  @Test
//  func test() {
//    #expect(1 == 1)
//  }
//}

class UITextInputImplementationTests: XCTestCase {
  var inputClient: UITextInputTestable!
  var textView: UITextView!
  override func setUp() {
    inputClient = FlutterTextInputView(
      owner: FlutterTextInputPlugin(delegate: fakeTextInputDelegate))
    textView = UITextView()
  }

  private func performTest<T: Equatable>(
    initialState: EditingState, actions: (UITextInputTestable) -> T
  ) -> T {
    inputClient.editingState = initialState
    textView.editingState = initialState

    let returnValue1 = actions(inputClient)
    let returnValue2 = actions(textView)

    XCTAssert(inputClient.editingState == textView.editingState)
    XCTAssert(returnValue1 == returnValue2)
    print("test: \(returnValue1), textView: \(returnValue2)")
    return returnValue1
  }

  // This is the same performTest method as before but for T == Void.
  private func performTest(initialState: EditingState, actions: (UITextInputTestable) -> Void) {
    inputClient.editingState = initialState
    textView.editingState = initialState

    actions(inputClient)
    actions(textView)
    XCTAssertEqual(
      inputClient.editingState, textView.editingState, "failed with input \(initialState)")
  }

  // First and foremost, make sure the UITextInput's interpretation of position
  // is in-line with UITextView.
  func testPositions() {
    let initialStates: [EditingState] = [
      "",
      "text",
      "क्षि",  // Indic script
      "퓛",  // pre-composed Hangul syllable block
      "퓛",   // 3 decomposed Hangul syllables
      "🧑‍🤝‍🧑",  // Emoji ZWJ sequence
      "😀",  // surrogate pair
    ]

    initialStates.forEach { initialState in
      inputClient.editingState = initialState
      textView.editingState = initialState

      XCTAssertEqual(
        inputClient.position(from: inputClient.beginningOfDocument, offset: -1),
        textView.position(from: textView.beginningOfDocument, offset: -1),
        initialState.string
      )  // Regardless of the position type, this method is supposed to return nil
      XCTAssertEqual(
        inputClient.position(from: inputClient.endOfDocument, offset: 1),
        textView.position(from: textView.endOfDocument, offset: 1),
        initialState.string
      )  // Regardless of the position type, this method is supposed to return nil

      // Verify that inputClient has the same unique TextPositions as a
      // UITextView if the text is the same.

      XCTAssertEqual(
        inputClient.allPositions.count, textView.allPositions.count, initialState.string)
      for (offset, (p1, p2)) in zip(inputClient.allPositions, textView.allPositions).enumerated() {
        XCTAssertEqual(
          inputClient.textBefore(position: p1), textView.textBefore(position: p2),
          "\(initialState.string) @ \(offset)")
        XCTAssertEqual(
          inputClient.textAfter(position: p1), textView.textAfter(position: p2),
          "\(initialState.string) @ \(offset)")
      }
    }
  }

  func testRanges() {

  }

  // MARK: deleteBackward
  func testDeleteBackward() {
    let initialStates: [EditingState] = [
      "",
      "String",         // collapsed selection
      "123 n<ihao>",    // has selection
      "123 n|<iha>o|",  // with marked text and selection
      "क्षि",             // Indic script
      "퓛",             // pre-composed Hangul syllable block
      "퓛",             // 3 decomposed Hangul syllables
      "🧑‍🤝‍🧑",            // Emoji ZWJ sequence
      "😀",            // surrogate pair
    ]

    initialStates.forEach {
      self.performTest(initialState: $0) { input in input.deleteBackward() }
    }
  }
  // MARK: insertText

}

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
