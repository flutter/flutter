// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define([
    "console",
    "file",
    "gin/test/expect",
    "mojo/public/interfaces/bindings/tests/validation_test_interfaces.mojom",
    "mojo/public/js/buffer",
    "mojo/public/js/codec",
    "mojo/public/js/connection",
    "mojo/public/js/connector",
    "mojo/public/js/core",
    "mojo/public/js/test/validation_test_input_parser",
    "mojo/public/js/router",
    "mojo/public/js/validator",
], function(console,
            file,
            expect,
            testInterface,
            buffer,
            codec,
            connection,
            connector,
            core,
            parser,
            router,
            validator) {

  var noError = validator.validationError.NONE;

  function checkTestMessageParser() {
    function TestMessageParserFailure(message, input) {
      this.message = message;
      this.input = input;
    }

    TestMessageParserFailure.prototype.toString = function() {
      return 'Error: ' + this.message + ' for "' + this.input + '"';
    }

    function checkData(data, expectedData, input) {
      if (data.byteLength != expectedData.byteLength) {
        var s = "message length (" + data.byteLength + ") doesn't match " +
            "expected length: " + expectedData.byteLength;
        throw new TestMessageParserFailure(s, input);
      }

      for (var i = 0; i < data.byteLength; i++) {
        if (data.getUint8(i) != expectedData.getUint8(i)) {
          var s = 'message data mismatch at byte offset ' + i;
          throw new TestMessageParserFailure(s, input);
        }
      }
    }

    function testFloatItems() {
      var input = '[f]+.3e9 [d]-10.03';
      var msg = parser.parseTestMessage(input);
      var expectedData = new buffer.Buffer(12);
      expectedData.setFloat32(0, +.3e9);
      expectedData.setFloat64(4, -10.03);
      checkData(msg.buffer, expectedData, input);
    }

    function testUnsignedIntegerItems() {
      var input = '[u1]0x10// hello world !! \n\r  \t [u2]65535 \n' +
          '[u4]65536 [u8]0xFFFFFFFFFFFFF 0 0Xff';
      var msg = parser.parseTestMessage(input);
      var expectedData = new buffer.Buffer(17);
      expectedData.setUint8(0, 0x10);
      expectedData.setUint16(1, 65535);
      expectedData.setUint32(3, 65536);
      expectedData.setUint64(7, 0xFFFFFFFFFFFFF);
      expectedData.setUint8(15, 0);
      expectedData.setUint8(16, 0xff);
      checkData(msg.buffer, expectedData, input);
    }

    function testSignedIntegerItems() {
      var input = '[s8]-0x800 [s1]-128\t[s2]+0 [s4]-40';
      var msg = parser.parseTestMessage(input);
      var expectedData = new buffer.Buffer(15);
      expectedData.setInt64(0, -0x800);
      expectedData.setInt8(8, -128);
      expectedData.setInt16(9, 0);
      expectedData.setInt32(11, -40);
      checkData(msg.buffer, expectedData, input);
    }

    function testByteItems() {
      var input = '[b]00001011 [b]10000000  // hello world\n [b]00000000';
      var msg = parser.parseTestMessage(input);
      var expectedData = new buffer.Buffer(3);
      expectedData.setUint8(0, 11);
      expectedData.setUint8(1, 128);
      expectedData.setUint8(2, 0);
      checkData(msg.buffer, expectedData, input);
    }

    function testAnchors() {
      var input = '[dist4]foo 0 [dist8]bar 0 [anchr]foo [anchr]bar';
      var msg = parser.parseTestMessage(input);
      var expectedData = new buffer.Buffer(14);
      expectedData.setUint32(0, 14);
      expectedData.setUint8(4, 0);
      expectedData.setUint64(5, 9);
      expectedData.setUint8(13, 0);
      checkData(msg.buffer, expectedData, input);
    }

    function testHandles() {
      var input = '// This message has handles! \n[handles]50 [u8]2';
      var msg = parser.parseTestMessage(input);
      var expectedData = new buffer.Buffer(8);
      expectedData.setUint64(0, 2);

      if (msg.handleCount != 50) {
        var s = 'wrong handle count (' + msg.handleCount + ')';
        throw new TestMessageParserFailure(s, input);
      }
      checkData(msg.buffer, expectedData, input);
    }

    function testEmptyInput() {
      var msg = parser.parseTestMessage('');
      if (msg.buffer.byteLength != 0)
        throw new TestMessageParserFailure('expected empty message', '');
    }

    function testBlankInput() {
      var input = '    \t  // hello world \n\r \t// the answer is 42   ';
      var msg = parser.parseTestMessage(input);
      if (msg.buffer.byteLength != 0)
        throw new TestMessageParserFailure('expected empty message', input);
    }

    function testInvalidInput() {
      function parserShouldFail(input) {
        try {
          parser.parseTestMessage(input);
        } catch (e) {
          if (e instanceof parser.InputError)
            return;
          throw new TestMessageParserFailure(
            'unexpected exception ' + e.toString(), input);
        }
        throw new TestMessageParserFailure("didn't detect invalid input", file);
      }

      ['/ hello world',
       '[u1]x',
       '[u2]-1000',
       '[u1]0x100',
       '[s2]-0x8001',
       '[b]1',
       '[b]1111111k',
       '[dist4]unmatched',
       '[anchr]hello [dist8]hello',
       '[dist4]a [dist4]a [anchr]a',
       // '[dist4]a [anchr]a [dist4]a [anchr]a',
       '0 [handles]50'
      ].forEach(parserShouldFail);
    }

    try {
      testFloatItems();
      testUnsignedIntegerItems();
      testSignedIntegerItems();
      testByteItems();
      testInvalidInput();
      testEmptyInput();
      testBlankInput();
      testHandles();
      testAnchors();
    } catch (e) {
      return e.toString();
    }
    return null;
  }

  function getMessageTestFiles(key) {
    var sourceRoot = file.getSourceRootDirectory();
    expect(sourceRoot).not.toBeNull();

    var testDir = sourceRoot +
      "/mojo/public/interfaces/bindings/tests/data/validation/";
    var testFiles = file.getFilesInDirectory(testDir);
    expect(testFiles).not.toBeNull();
    expect(testFiles.length).toBeGreaterThan(0);

    // The matching ".data" pathnames with the extension removed.
    return testFiles.filter(function(s) {
      return s.substr(-5) == ".data";
    }).map(function(s) {
      return testDir + s.slice(0, -5);
    }).filter(function(s) {
      return s.indexOf(key) != -1;
    });
  }

  function readTestMessage(filename) {
    var contents = file.readFileToString(filename + ".data");
    expect(contents).not.toBeNull();
    return parser.parseTestMessage(contents);
  }

  function readTestExpected(filename) {
    var contents = file.readFileToString(filename + ".expected");
    expect(contents).not.toBeNull();
    return contents.trim();
  }

  function checkValidationResult(testFile, err) {
    var actualResult = (err === noError) ? "PASS" : err;
    var expectedResult = readTestExpected(testFile);
    if (actualResult != expectedResult)
      console.log("[Test message validation failed: " + testFile + " ]");
    expect(actualResult).toEqual(expectedResult);
  }

  function testMessageValidation(key, filters) {
    var testFiles = getMessageTestFiles(key);
    expect(testFiles.length).toBeGreaterThan(0);

    for (var i = 0; i < testFiles.length; i++) {
      // TODO(hansmuller) Temporarily skipping array pointer overflow tests
      // because JS numbers are limited to 53 bits.
      // TODO(yzshen) Skipping struct versioning tests (tests with "mthd11"
      // in the name) because the feature is not supported in JS yet.
      // TODO(rudominer): Temporarily skipping 'no-such-method',
      // 'invalid_request_flags', and 'invalid_response_flags' until additional
      // logic in *RequestValidator and *ResponseValidator is ported from
      // cpp to js.
      if (testFiles[i].indexOf("overflow") != -1 ||
          testFiles[i].indexOf("mthd11") != -1 ||
          testFiles[i].indexOf("no_such_method") != -1 ||
          testFiles[i].indexOf("invalid_request_flags") != -1 ||
          testFiles[i].indexOf("invalid_response_flags") != -1) {
        console.log("[Skipping " + testFiles[i] + "]");
        continue;
      }

      var testMessage = readTestMessage(testFiles[i]);
      var handles = new Array(testMessage.handleCount);
      var message = new codec.Message(testMessage.buffer, handles);
      var messageValidator = new validator.Validator(message);

      var err = messageValidator.validateMessageHeader();
      for (var j = 0; err === noError && j < filters.length; ++j)
        err = filters[j](messageValidator);

      checkValidationResult(testFiles[i], err);
    }
  }

  function testConformanceMessageValidation() {
    testMessageValidation("conformance_", [
        testInterface.ConformanceTestInterface.validateRequest]);
  }

  function testIntegratedMessageValidation(testFilesPattern) {
    var testFiles = getMessageTestFiles(testFilesPattern);
    expect(testFiles.length).toBeGreaterThan(0);

    for (var i = 0; i < testFiles.length; i++) {
      var testMessage = readTestMessage(testFiles[i]);
      var handles = new Array(testMessage.handleCount);
      var testMessagePipe = new core.createMessagePipe();
      expect(testMessagePipe.result).toBe(core.RESULT_OK);

      var writeMessageValue = core.writeMessage(
          testMessagePipe.handle0,
          new Uint8Array(testMessage.buffer.arrayBuffer),
          new Array(testMessage.handleCount),
          core.WRITE_MESSAGE_FLAG_NONE);
      expect(writeMessageValue).toBe(core.RESULT_OK);

      var testConnection = new connection.TestConnection(
          testMessagePipe.handle1,
          testInterface.IntegrationTestInterface.stubClass,
          testInterface.IntegrationTestInterface.proxyClass);

      var validationError = noError;
      testConnection.router_.validationErrorHandler = function(err) {
        validationError = err;
      }

      testConnection.router_.connector_.deliverMessage();
      checkValidationResult(testFiles[i], validationError);

      testConnection.close();
      expect(core.close(testMessagePipe.handle0)).toBe(core.RESULT_OK);
    }
  }

  function testIntegratedMessageHeaderValidation() {
    testIntegratedMessageValidation("integration_msghdr");
  }

  function testIntegratedRequestMessageValidation() {
    testIntegratedMessageValidation("integration_intf_rqst");
  }

  function testIntegratedResponseMessageValidation() {
    testIntegratedMessageValidation("integration_intf_resp");
  }

  expect(checkTestMessageParser()).toBeNull();
  testConformanceMessageValidation();
  testIntegratedMessageHeaderValidation();
  testIntegratedResponseMessageValidation();
  testIntegratedRequestMessageValidation();
  this.result = "PASS";
});
