// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwift
import UIKit
import XCTest
import Testing

/// Tests in this file verify that our custom UITextInput implementations
/// matches the behavior of UITextViews when receive the same input from the
/// IME.

// Swift tuples can't conform to Equtable (yet).
struct TextSelection: Equatable {
  init(base: UInt, extent: UInt) {
    self.base = base
    self.extent = extent
  }
  init(collapsed: UInt) {
    self.init(base: collapsed, extent: collapsed)
  }
  let base: UInt
  let extent: UInt
  
  var range: Range<UInt> {
    min(base, extent) ..< max(base, extent)
  }
}

struct EditingState: Equatable, ExpressibleByStringLiteral {
  init(string: String, markedTextRange: Range<UInt>?, selectedTextRange: TextSelection?) {
    self.string = string
    self.markedTextRange = markedTextRange
    self.selectedTextRange = selectedTextRange
    assert(markedTextRange == nil || selectedTextRange != nil);
    assert(markedTextRange?.overlaps(selectedTextRange!.range) ?? true)
  }
  
  init(string: String) {
    self.init(string: string, markedTextRange: nil, selectedTextRange: TextSelection(collapsed: UInt(string.utf16.count)))
  }
  
  init(string: String, markedTextRange: Range<UInt>) {
    self.init(string: string, markedTextRange: markedTextRange, selectedTextRange: TextSelection(collapsed: markedTextRange.upperBound))
  }
  
  init(stringLiteral: StaticString) {
    self.init(string: stringLiteral.description)
  }
  
  let string: String
  
  let markedTextRange: Range<UInt>?
  let selectedTextRange: TextSelection?
//  
//  func replace(text: String, range: Range<UInt>) -> EditingState {
//    self
//  }
  
  // MARK: Special Values
  static let empty = ""
}

protocol UITextInputTestable: UITextInput {
  var editingState: EditingState { get set }
}

extension UITextInput {
  func offsetOf(_ position: UITextPosition) -> UInt {
    UInt(offset(from: self.beginningOfDocument, to: position))
  }
  func selectionOf(_ position: UITextRange) -> TextSelection {
    TextSelection(base: offsetOf(position.start), extent: offsetOf(position.end))
  }
}

extension UITextView: UITextInputTestable {

  
  var editingState: EditingState {
    get {
      EditingState(string: text, markedTextRange: markedTextRange.map(selectionOf)?.range, selectedTextRange: selectedTextRange.map(selectionOf))
    }
    set { fatalError() }
  }
}

extension FlutterTextInputView: UITextInputTestable {
  var editingState: EditingState {
    get { fatalError() }
    set { fatalError() }
  }
}
let fakeTextInputDelegate = FakeTextInputDelegate()

//func allTestables() -> [any UITextInputTestable] {
//  [FlutterTextInputView(owner: FlutterTextInputPlugin(delegate: fakeTextInputDelegate))]
//}

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
    inputClient = FlutterTextInputView(owner: FlutterTextInputPlugin(delegate: fakeTextInputDelegate))
    textView = UITextView()
  }
  
  private func performTest<T: Equatable>(initialState: EditingState, actions: (UITextInputTestable)->T) -> T {
    inputClient.editingState = initialState
    textView.editingState = initialState
    
    let returnValue1 = actions(inputClient)
    let returnValue2 = actions(textView)
    
    XCTAssert(inputClient.editingState == textView.editingState)
    XCTAssert(returnValue1 == returnValue2)
    return returnValue1
  }
  
  // This is the same performTest method as before but for T == Void.
  private func performTest(initialState: EditingState, actions: (UITextInputTestable)->Void) {
    inputClient.editingState = initialState
    textView.editingState = initialState
    
    actions(inputClient)
    actions(textView)
    XCTAssert(inputClient.editingState == textView.editingState)
  }
  
  func testBackspaceDeleteEmpty() {
    performTest(
      initialState: "") { input in
        input.deleteBackward()
      }
  }
  
  func testBackspaceDeleteNoSelection() {
    performTest(initialState: "String") { input in
      input.deleteBackward()
    }
  }
  
  func testBackspaceDeleteWithMarkedText() {
    let initialState = EditingState(string: "123 nihao", markedTextRange: 5..<10)
    performTest(initialState: initialState) { input in
      input.deleteBackward()
    }
  }
  
  func testBackspaceDeleteWithMarkedTextAndSelection() {
    let initialState = EditingState(string: "123 nihao", markedTextRange: 5..<10, selectedTextRange: TextSelection(base: 5, extent: 9))
    performTest(initialState: initialState) { input in
      input.deleteBackward()
    }
  }
}


@objc class FakeTextInputDelegate: NSObject, FlutterTextInputDelegate {
  func flutterTextInputView(_ textInputView: FlutterTextInputView, updateEditingClient client: Int32, withState state: [AnyHashable: Any]) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, updateEditingClient client: Int32, withState state: [AnyHashable: Any], withTag tag: String) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, updateEditingClient client: Int32, withDelta state: [AnyHashable: Any]) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, perform action: FlutterTextInputAction, withClient client: Int32) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, updateFloatingCursor state: FlutterFloatingCursorDragState, withClient client: Int32, withPosition point: [AnyHashable: Any]) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, showAutocorrectionPromptRectForStart start: UInt, end: UInt, withClient client: Int32) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, showToolbar client: Int32) {
  }

  func flutterTextInputViewScribbleInteractionBegan(_ textInputView: FlutterTextInputView) {
  }

  func flutterTextInputViewScribbleInteractionFinished(_ textInputView: FlutterTextInputView) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, insertTextPlaceholderWith size: CGSize, withClient client: Int32) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, removeTextPlaceholder client: Int32) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, didResignFirstResponderWithTextInputClient textInputClient: Int32) {
  }
  
  func flutterTextInputView(_ textInputView: FlutterTextInputView, willDismissEditMenuWithTextInputClient textInputClient: Int32) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, shareSelectedText selectedText: String) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, searchWebWithSelectedText selectedText: String) {
  }

  func flutterTextInputView(_ textInputView: FlutterTextInputView, lookUpSelectedText selectedText: String) {
  }
}
