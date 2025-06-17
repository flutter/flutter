// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import XCTest

/// Tests in this file verify that our custom UITextInput implementations
/// matches the behavior of UITextViews when receive the same input from the
/// IME.

extension UITextView: UITextInputTestable {}
extension FlutterTextInputView: UITextInputTestable {}

class UITextInputImplementationTests: XCTestCase {
  var inputClient: UITextInputTestable!
  var textView: UITextView!
  override func setUp() {
    inputClient = FlutterTextInputView(
      owner: FlutterTextInputPlugin(delegate: fakeTextInputDelegate))
    textView = UITextView()
  }

  let zwj = "\u{200d}"
  // Indic script with virama, no ZWJs
  let indic = "क्षि"
  // pre-composed Hangul syllable block, single code unit 0xD4DB
  let precomposedHangul = "퓛"
  // 3 decomposed Hangul syllables, 3 code units
  let decomposedHangul = "퓛"
  // Jamos that don't actually combine
  let jamos = String(repeating: "ᄌ", count: 3)
  // Emoji ZWJ sequence
  let emojiZWJ = "🧑‍🤝‍🧑"
  // À but decomposed
  let latinGrave = "A\u{0300}"
  let surrogatePair = "😀"
  // Thai cluster with diacritic marks
  let thai = "ห้"
  // Arabic with diacritic marks
  let arabic = "كُتِبَ"

  private func performTest<T: Equatable>(
    initialState: EditingState, actions: (UITextInputTestable) -> T
  ) -> T {
    inputClient.editingState = initialState
    textView.editingState = initialState

    let returnValue1 = actions(inputClient)
    let returnValue2 = actions(textView)

    XCTAssert(inputClient.editingState == textView.editingState)
    XCTAssert(returnValue1 == returnValue2)
    return returnValue1
  }

  // This is the same performTest method as the one above, but for T == Void.
  private func performTest(initialState: EditingState, actions: (UITextInputTestable) -> Void) {
    inputClient.editingState = initialState
    textView.editingState = initialState

    actions(inputClient)
    actions(textView)
    XCTAssertEqual(
      inputClient.editingState, textView.editingState, "failed with input \(initialState)")
  }

  // First and foremost, make sure the UITextInput's interpretation of "position"
  // is in-line with UITextView.
  func testPositions() {
    let editingStateTextCases = EditingState.allVariations(
      zwj + emojiZWJ + jamos + precomposedHangul + decomposedHangul + thai)

    editingStateTextCases.forEach { initialState in
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
    let text = zwj + emojiZWJ + jamos + precomposedHangul + decomposedHangul + thai
    let utf16Length = UInt(text.utf16.count)
    let allRanges: [Range<UInt>] =
      (0..<utf16Length)
      .flatMap { start in ((start + 1)...utf16Length).map { start..<$0 } }

    allRanges.forEach { range in
      let initialState = EditingState(string: text)
      inputClient.editingState = initialState
      textView.editingState = initialState

      XCTAssertEqual(
        inputClient.text(in: inputClient.rangeFrom(range)),
        textView.text(in: textView.rangeFrom(range)))
    }
  }

  // MARK: UIKeyInput tests

  func testDeleteBackward() {
    // This test string set is arbitrary.
    //
    // Ideally, this should test all combinations of the shorter strings.
    // Unfortunately that creates too many test cases and slows down tests
    // significantly.
    let strings: [String] = [
      "",
      "a",
      "הֽ͏ַ",  // test CGJ
      arabic,
      precomposedHangul + zwj + surrogatePair,
      decomposedHangul + zwj + surrogatePair,
      indic + zwj + indic,
      jamos + precomposedHangul,
      jamos + decomposedHangul,
      latinGrave + zwj + emojiZWJ,
      surrogatePair + zwj + jamos,
      surrogatePair + zwj + thai,
    ]
    let editingStates = strings.flatMap(EditingState.allVariations).filter {
      !$0.selectionBreaksCodepoint
    }
    editingStates.forEach {
      self.performTest(initialState: $0) { input in input.deleteBackward() }
    }
  }

  func testInsertText() {
    let editingStateTextCases = EditingState.allVariations(
      zwj + emojiZWJ + jamos + thai)
    editingStateTextCases.filter { !$0.selectionBreaksCodepoint }.forEach {
      self.performTest(initialState: $0) { input in input.insertText("i") }
      self.performTest(initialState: $0) { input in input.insertText("") }
    }
  }

  // MARK: UITextInput tests

  // Makes sure the textInRange implementation handles OOB ranges gracefully.
  func testTextInRangeWithInvalidRanges() {
    let newEditingState = EditingState(string: String(repeating: "a", count: 3))

    self.performTest(initialState: EditingState(string: String(repeating: "a", count: 100))) {
      input in
      let range = input.rangeFrom(0..<100)
      input.editingState = newEditingState
      print(input.text(in: range))
      return input.text(in: range)
    }
  }
}
