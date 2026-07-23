// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import InternalFlutterSwiftCommon
import Testing

@Suite struct FlutterJSONCodecTest {
  let codec = FlutterJSONMessageCodec.sharedInstance()

  @Test func sanitizeUnpairedSurrogates() throws {
    let malformedString = NSString(
      data: Data([0xDF, 0xFF]),
      encoding: NSUTF16StringEncoding
    )!
    let rawJSON = "\"\(malformedString)\""
    try #require(malformedString.character(at: 0) == 0xDFFF)
    try #require(
      !rawJSON.contains("u{FFFD}"),
      "String literal initializer shouldn't sanitize the malformed string."
    )
    let decoded = codec.decode(rawJSON.data(using: .utf16)) as? String
    #expect("\u{FFFD}" == decoded)
  }

  @Test func decodeZeroLength() {
    #expect(codec.decode(Data()) == nil)
  }

  // Exit tests are only available on Swift 6.2 and later.
  // These two tests currently do not run on CI.
  #if compiler(>=6.2)
    @available(macOS 13.0, *)
    @Test func encodingAssertsOnInvalidInput() async {
      let result = await #expect(
        processExitsWith: .signal(SIGABRT),
        observing: [\.standardErrorContent]
      ) {
        let malformedString = NSString(
          data: Data([0xDF, 0xFF]),
          encoding: NSUTF16StringEncoding
        )!
        FlutterJSONMessageCodec.sharedInstance().encode(malformedString)
      }
      if let result {
        #expect(
          result.standardErrorContent.contains("failed to convert to UTF8".utf8)
        )
      }
    }

    @available(macOS 13.0, *)
    @Test func decodingAssertsOnInvalidInput() async {
      let result = await #expect(
        processExitsWith: .signal(SIGABRT),
        observing: [\.standardErrorContent]
      ) {
        FlutterJSONMessageCodec.sharedInstance().decode(
          "{{{".data(using: .utf8)
        )
      }
      if let result {
        #expect(
          result.standardErrorContent.contains(
            "No string key for value in object around line 1".utf8
          )
        )
      }
    }
  #endif  // compiler(>=6.2)

  @Test(arguments: [
    NSArray(
      objects: NSNull(),
      "hello",
      3.14,
      47,
      NSDictionary(dictionaryLiteral: ("a", "nested"))
    ),
    NSDictionary(
      dictionaryLiteral: ("a", 3.14),
      ("b", 47),
      ("c", NSNull()),
      ("d", ["nested"])
    ),
    "top-level element" as NSString,
    nil,
  ])
  func basicTest(_ data: AnyObject?) {
    let result = codec.decode(codec.encode(data))
    if let data {
      #expect(data.isEqual(result))
    } else {
      #expect(result == nil)
    }
  }
}

@Suite struct FlutterStringCodecTest {
  let codec = FlutterStringCodec.sharedInstance()

  @Test(arguments: [
    "",
    "hello world",
    "hello u{263A} world",
    "hello u{1F602} world",
    nil,
  ])
  func basicTest(_ data: String?) {
    let result = codec.decode(codec.encode(data)) as! String?
    #expect(data == result)
  }
}
