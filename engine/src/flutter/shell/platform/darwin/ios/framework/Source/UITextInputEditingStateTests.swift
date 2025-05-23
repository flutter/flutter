// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import Testing
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
  
  
  private func parseComposingRegion(string: String) -> Either<(String, String, String), String> {
    // "|" is the token that represents composing regions
    let components = string.components(separatedBy: "|")
    if (components.count == 1) {
      return .right(string)
    } else {
      assert(components.count == 3)
      assert(!components[1].isEmpty)
      return .left((components[0], components[1], components[2]))
    }
  }
  
  private func parseSelection(string: String) -> (String, UInt, UInt) {
    assert(string[string.utf16.indices(of: "<")].count <= 1)
    assert(string[string.utf16.indices(of: ">")].count <= 1)
    guard let baseIndex = string.utf16.first("<"), let extentIndex = string.utf16.first(">") else {
      assert(!string.contains(">"))
      return (string, string.utf16.count, string.utf16.count)
    }
    return (string.removeAll { c in c = "<" || c = ">" }, baseIndex, extentIndex - 1)
  }

  init(stringLiteral: StaticString) {
    let selection: TextSelection
    
    switch parseComposingRegion(string: stringLiteral.description) {
    case let .left((p1, p2, p3)):
      
      TextSelection(base: p1.utf16.count + , extent: <#T##UInt#>, markedRange: <#T##Range<UInt>?#>)
    }
    
    self.init(string: stringLiteral.description)
  }

  let string: String

  let selectedTextRange: TextSelection?
}

// MARK: DSL for describing text selection
private struct EditingStateExpectingRightBracket {
  let string: String
  let leftBracketLocation: UInt

}

//postfix operator |>
//fileprivate postfix func |> (lhs: EditingStateExpectingRightBracket) -> EditingState {
//  EditingState(string: lhs.string, selectedTextRange: TextSelection(base: lhs.leftBracketLocation, extent: UInt(lhs.string.utf16.count), markedRange: nil))
//}
infix operator > : MultiplicationPrecedence
fileprivate func > (lhs: EditingStateExpectingRightBracket, rhs: String) -> EditingState {
  EditingState(string: lhs.string + rhs, selectedTextRange: TextSelection(base: lhs.leftBracketLocation, extent: UInt(lhs.string.utf16.count), markedRange: nil))
}
fileprivate func > (lhs: String, rhs: String) -> EditingStateExpectingLeftBracket {
  EditingStateExpectingLeftBracket(string: lhs + rhs, rightBracketLocation: UInt(lhs.utf16.count))
}


private struct EditingStateExpectingLeftBracket {
  let string: String
  let rightBracketLocation: UInt

}

//postfix operator <|
//fileprivate postfix func <| (lhs: EditingStateExpectingLeftBracket) -> EditingState {
//  EditingState(string: lhs.string, selectedTextRange: TextSelection(base: UInt(lhs.string.utf16.count), extent: lhs.rightBracketLocation, markedRange: nil))
//}
infix operator < : MultiplicationPrecedence
fileprivate func < (lhs: EditingStateExpectingLeftBracket, rhs: String) -> EditingState {
  EditingState(string: lhs.string + rhs, selectedTextRange: TextSelection(base: UInt(lhs.string.utf16.count), extent: lhs.rightBracketLocation, markedRange: nil))
}
fileprivate func < (lhs: String, rhs: String) -> EditingStateExpectingRightBracket {
  EditingStateExpectingRightBracket(string: lhs + rhs, leftBracketLocation: UInt(lhs.utf16.count))
}



extension String {
  func with(selection: TextSelection?) -> EditingState {
    EditingState(string: self, selectedTextRange: selection)
  }

  func with(selection: Range<UInt>) -> EditingState {
    with(
      selection: TextSelection(
        base: selection.lowerBound, extent: selection.upperBound, markedRange: nil))
  }

  func with(markedTextRange: Range<UInt>) -> EditingState {
    with(
      selection: TextSelection(
        base: markedTextRange.upperBound, extent: markedTextRange.upperBound,
        markedRange: markedTextRange))
  }

  func with(selection: Range<UInt>, andMarkedTextRange markedRange: Range<UInt>) -> EditingState {
    with(
      selection: TextSelection(
        base: selection.lowerBound, extent: selection.upperBound,
        markedRange: markedRange))
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
    //print("test: \(inputClient.editingState), textView: \(textView.editingState)")
    XCTAssertEqual(inputClient.editingState, textView.editingState)
  }

  // MARK: deleteBackward
  func testDeleteBackward() {
    let initialStates: [EditingState] = [
      "",  // empty
      "String",  // no selection
      "123 n<ihao>",
      "123 nihao".with(markedTextRange: 5..<10),  // with marked text
      //"123 nihao".with(selection: 5..<9, andMarkedTextRange: 5..<10),  // with marked text and selection
      "123 n|<iha>o|",  // with marked text and selection
      "123 n<ihao>"
      "क्षि",  // Indic script
      "🧑‍🤝‍🧑",  // Emoji ZWJ sequence
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
