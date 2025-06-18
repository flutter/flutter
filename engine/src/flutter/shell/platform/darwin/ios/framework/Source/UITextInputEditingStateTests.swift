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

// MARK: UITextInputImplementationTests Helper

extension UITextInputImplementationTests {
  fileprivate func performTest<T: Equatable>(
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
  fileprivate func performTest(initialState: EditingState, actions: (UITextInputTestable) -> Void) {
    inputClient.editingState = initialState
    textView.editingState = initialState

    actions(inputClient)
    actions(textView)
    XCTAssertEqual(
      inputClient.editingState, textView.editingState, "failed with input \(initialState)")
  }
}

// MARK: Test Strings
let zwj = "\u{200d}"
// Indic script with virama, no ZWJs
let hebrewWithCGJ = "הֽ͏ַ"
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

let allTestStrings = [
  zwj, hebrewWithCGJ, indic, precomposedHangul, decomposedHangul, jamos, emojiZWJ, latinGrave,
  surrogatePair, thai, arabic,
]

// MARK: Test Body

class UITextInputImplementationTests: XCTestCase {
  var inputClient: UITextInputTestable!
  var textView: UITextView!
  override func setUp() {
    inputClient = FlutterTextInputView(
      owner: FlutterTextInputPlugin(delegate: fakeTextInputDelegate))
    textView = UITextView()
  }

  // First and foremost, make sure the UITextInput's interpretation of "position"
  // is in-line with UITextView.
  func testPositions() {
    let initialState = EditingState(
      string:
        zwj + emojiZWJ + jamos + decomposedHangul + thai + surrogatePair)

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
        "The prefix text at offset \(offset) should be the same. The full string was: \(initialState.string)"
      )
      XCTAssertEqual(
        inputClient.textAfter(position: p1), textView.textAfter(position: p2),
        "The suffix text at offset \(offset) should be the same. The full string was: \(initialState.string)"
      )
    }
  }

  // Verifies that the custom UITextInput's interpretation of "range" is in-line
  // with UITextView.
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

  // This test intentionally does not cover the cases where the delete operation
  // results in a malformed string (i.e., the selection includes unpaired
  // surrogates).
  //
  // This is because UITextVeiw doesn't seem to try to sanitize the selection
  // range such that it doesn't leave unpaired surrogates in the string, and
  // it sometimes throws out-of-bounds exceptions when the current selection
  // has unpaired surrogates.
  func testDeleteBackward() {
    // This test string set is arbitrary.
    //
    // To test more combinations of the shorter strings, try the folllowing:
    // this takes a long time to complete and is usually an overkill.
    //
    //    let s = ["", "a"] + Array(allTestStrings)
    //    let strings = s.flatMap { head in
    //      s.map { tail in head + tail  }
    //    }
    let strings = [
      "",
      "a",
      hebrewWithCGJ,
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
    _ = self.performTest(initialState: EditingState(string: String(repeating: "a", count: 100))) {
      input in
      let range = input.rangeFrom(0..<100)
      input.editingState = newEditingState
      return input.text(in: range)
    }
  }

  // Tests the UITextInput.offset(from:to:) implementation
  func testRangeToOffset() {
    inputClient.editingState = EditingState(
      string:
        zwj + emojiZWJ + jamos + decomposedHangul + surrogatePair)

    for position in inputClient.allPositions {
      let offset = inputClient.offset(from: inputClient.beginningOfDocument, to: position)
      XCTAssertEqual(
        position, inputClient.position(from: inputClient.beginningOfDocument, offset: offset))
      XCTAssertEqual(inputClient.offset(from: position, to: position), 0)
    }
  }

  // Tests the UITextInput.compare(_ position:,to other:) implementation
  func testPositionComparison() {
    inputClient.editingState = EditingState(
      string:
        zwj + emojiZWJ + jamos + decomposedHangul + surrogatePair)

    let positions = inputClient.allPositions
    for (index, position) in positions.enumerated() {
      XCTAssertEqual(inputClient.compare(position, to: position), .orderedSame)

      let predecessors = positions[..<index]
      let successors = index < positions.count ? positions[(index + 1)...] : []

      for pred in predecessors {
        XCTAssertEqual(inputClient.compare(pred, to: position), .orderedAscending)
        XCTAssertEqual(inputClient.compare(position, to: pred), .orderedDescending)
      }
      for succ in successors {
        XCTAssertEqual(inputClient.compare(position, to: succ), .orderedAscending)
        XCTAssertEqual(inputClient.compare(succ, to: position), .orderedDescending)
      }
    }
  }
  
  func testPositionComparisonIsAffinityAgnostic() {
    inputClient.editingState = EditingState(string: "")
    XCTAssertEqual(inputClient.beginningOfDocument, inputClient.endOfDocument)
    XCTAssertEqual(inputClient.compare(inputClient.beginningOfDocument, to: inputClient.endOfDocument), .orderedSame)
  }
}
