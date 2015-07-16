// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define([
    "gin/test/expect",
    "mojo/public/interfaces/bindings/tests/rect.mojom",
    "mojo/public/interfaces/bindings/tests/test_structs.mojom",
    "mojo/public/js/codec",
    "mojo/public/js/validator",
], function(expect,
            rect,
            testStructs,
            codec,
            validator) {

  function testConstructors() {
    var r = new rect.Rect();
    expect(r).toEqual(new rect.Rect({x:0, y:0, width:0, height:0}));
    expect(r).toEqual(new rect.Rect({foo:100, bar:200}));

    r.x = 10;
    r.y = 20;
    r.width = 30;
    r.height = 40;
    var rp = new testStructs.RectPair({first: r, second: r});
    expect(rp.first).toEqual(r);
    expect(rp.second).toEqual(r);

    expect(new testStructs.RectPair({second: r}).first).toBeNull();

    var nr = new testStructs.NamedRegion();
    expect(nr.name).toBeNull();
    expect(nr.rects).toBeNull();
    expect(nr).toEqual(new testStructs.NamedRegion({}));

    nr.name = "foo";
    nr.rects = [r, r, r];
    expect(nr).toEqual(new testStructs.NamedRegion({
      name: "foo",
      rects: [r, r, r],
    }));

    var e = new testStructs.EmptyStruct();
    expect(e).toEqual(new testStructs.EmptyStruct({foo:123}));
  }

  function testNoDefaultFieldValues() {
    var s = new testStructs.NoDefaultFieldValues();
    expect(s.f0).toEqual(false);

    // f1 - f10, number type fields
    for (var i = 1; i <= 10; i++)
      expect(s["f" + i]).toEqual(0);

    // f11,12 strings, f13-22 handles, f23-f26 arrays, f27,28 structs
    for (var i = 11; i <= 28; i++)
      expect(s["f" + i]).toBeNull();
  }

  function testDefaultFieldValues() {
    var s = new testStructs.DefaultFieldValues();
    expect(s.f0).toEqual(true);

    // f1 - f12, number type fields
    for (var i = 1; i <= 12; i++)
      expect(s["f" + i]).toEqual(100);

    // f13,14 "foo"
    for (var i = 13; i <= 14; i++)
      expect(s["f" + i]).toEqual("foo");

    // f15,16 a default instance of Rect
    var r = new rect.Rect();
    expect(s.f15).toEqual(r);
    expect(s.f16).toEqual(r);
  }

  function testScopedConstants() {
    expect(testStructs.ScopedConstants.TEN).toEqual(10);
    expect(testStructs.ScopedConstants.ALSO_TEN).toEqual(10);
    expect(testStructs.ScopedConstants.TEN_TOO).toEqual(10);

    expect(testStructs.ScopedConstants.EType.E0).toEqual(0);
    expect(testStructs.ScopedConstants.EType.E1).toEqual(1);
    expect(testStructs.ScopedConstants.EType.E2).toEqual(10);
    expect(testStructs.ScopedConstants.EType.E3).toEqual(10);
    expect(testStructs.ScopedConstants.EType.E4).toEqual(11);

    var s = new testStructs.ScopedConstants();
    expect(s.f0).toEqual(0);
    expect(s.f1).toEqual(1);
    expect(s.f2).toEqual(10);
    expect(s.f3).toEqual(10);
    expect(s.f4).toEqual(11);
    expect(s.f5).toEqual(10);
    expect(s.f6).toEqual(10);
  }

  function structEncodeDecode(struct) {
    var structClass = struct.constructor;
    var builder = new codec.MessageBuilder(1234, structClass.encodedSize);
    builder.encodeStruct(structClass, struct);
    var message = builder.finish();

    var messageValidator = new validator.Validator(message);
    var err = structClass.validate(messageValidator, codec.kMessageHeaderSize);
    expect(err).toEqual(validator.validationError.NONE);

    var reader = new codec.MessageReader(message);
    return reader.decodeStruct(structClass);
  }

  function testMapKeyTypes() {
    var mapFieldsStruct = new testStructs.MapKeyTypes({
      f0: new Map([[true, false], [false, true]]),  // map<bool, bool>
      f1: new Map([[0, 0], [1, 127], [-1, -128]]),  // map<int8, int8>
      f2: new Map([[0, 0], [1, 127], [2, 255]]),  // map<uint8, uint8>
      f3: new Map([[0, 0], [1, 32767], [2, -32768]]),  // map<int16, int16>
      f4: new Map([[0, 0], [1, 32768], [2, 0xFFFF]]),  // map<uint16, uint16>
      f5: new Map([[0, 0], [1, 32767], [2, -32768]]),  // map<int32, int32>
      f6: new Map([[0, 0], [1, 32768], [2, 0xFFFF]]),  // map<uint32, uint32>
      f7: new Map([[0, 0], [1, 32767], [2, -32768]]),  // map<int64, int64>
      f8: new Map([[0, 0], [1, 32768], [2, 0xFFFF]]),  // map<uint64, uint64>
      f9: new Map([[1000.5, -50000], [100.5, 5000]]),  // map<float, float>
      f10: new Map([[-100.5, -50000], [0, 50000000]]),  // map<double, double>
      f11: new Map([["one", "two"], ["free", "four"]]),  // map<string, string>
    });
    var decodedStruct = structEncodeDecode(mapFieldsStruct);
    expect(decodedStruct.f0).toEqual(mapFieldsStruct.f0);
    expect(decodedStruct.f1).toEqual(mapFieldsStruct.f1);
    expect(decodedStruct.f2).toEqual(mapFieldsStruct.f2);
    expect(decodedStruct.f3).toEqual(mapFieldsStruct.f3);
    expect(decodedStruct.f4).toEqual(mapFieldsStruct.f4);
    expect(decodedStruct.f5).toEqual(mapFieldsStruct.f5);
    expect(decodedStruct.f6).toEqual(mapFieldsStruct.f6);
    expect(decodedStruct.f7).toEqual(mapFieldsStruct.f7);
    expect(decodedStruct.f8).toEqual(mapFieldsStruct.f8);
    expect(decodedStruct.f9).toEqual(mapFieldsStruct.f9);
    expect(decodedStruct.f10).toEqual(mapFieldsStruct.f10);
    expect(decodedStruct.f11).toEqual(mapFieldsStruct.f11);
  }

  function testMapValueTypes() {
    var mapFieldsStruct = new testStructs.MapValueTypes({
      // map<string, array<string>>
      f0: new Map([["a", ["b", "c"]], ["d", ["e"]]]),
      // map<string, array<string>?>
      f1: new Map([["a", null], ["b", ["c", "d"]]]),
      // map<string, array<string?>>
      f2: new Map([["a", [null]], ["b", [null, "d"]]]),
      // map<string, array<string,2>>
      f3: new Map([["a", ["1", "2"]], ["b", ["1", "2"]]]),
      // map<string, array<array<string, 2>?>>
      f4: new Map([["a", [["1", "2"]]], ["b", [null]]]),
      // map<string, array<array<string, 2>, 1>>
      f5: new Map([["a", [["1", "2"]]]]),
      // map<string, Rect?>
      f6: new Map([["a", null]]),
      // map<string, map<string, string>>
      f7: new Map([["a", new Map([["b", "c"]])]]),
      // map<string, array<map<string, string>>>
      f8: new Map([["a", [new Map([["b", "c"]])]]]),
      // map<string, handle>
      f9: new Map([["a", 1234]]),
      // map<string, array<handle>>
      f10: new Map([["a", [1234, 5678]]]),
      // map<string, map<string, handle>>
      f11: new Map([["a", new Map([["b", 1234]])]]),
    });
    var decodedStruct = structEncodeDecode(mapFieldsStruct);
    expect(decodedStruct.f0).toEqual(mapFieldsStruct.f0);
    expect(decodedStruct.f1).toEqual(mapFieldsStruct.f1);
    expect(decodedStruct.f2).toEqual(mapFieldsStruct.f2);
    expect(decodedStruct.f3).toEqual(mapFieldsStruct.f3);
    expect(decodedStruct.f4).toEqual(mapFieldsStruct.f4);
    expect(decodedStruct.f5).toEqual(mapFieldsStruct.f5);
    expect(decodedStruct.f6).toEqual(mapFieldsStruct.f6);
    expect(decodedStruct.f7).toEqual(mapFieldsStruct.f7);
    expect(decodedStruct.f8).toEqual(mapFieldsStruct.f8);
    expect(decodedStruct.f9).toEqual(mapFieldsStruct.f9);
    expect(decodedStruct.f10).toEqual(mapFieldsStruct.f10);
    expect(decodedStruct.f11).toEqual(mapFieldsStruct.f11);
  }

  function testFloatNumberValues() {
    var decodedStruct = structEncodeDecode(new testStructs.FloatNumberValues);
    expect(decodedStruct.f0).toEqual(testStructs.FloatNumberValues.V0);
    expect(decodedStruct.f1).toEqual(testStructs.FloatNumberValues.V1);
    expect(decodedStruct.f2).toEqual(testStructs.FloatNumberValues.V2);
    expect(decodedStruct.f3).toEqual(testStructs.FloatNumberValues.V3);
    expect(decodedStruct.f4).toEqual(testStructs.FloatNumberValues.V4);
    expect(decodedStruct.f5).toEqual(testStructs.FloatNumberValues.V5);
    expect(decodedStruct.f6).toEqual(testStructs.FloatNumberValues.V6);
    expect(decodedStruct.f7).toEqual(testStructs.FloatNumberValues.V7);
    expect(decodedStruct.f8).toEqual(testStructs.FloatNumberValues.V8);
    expect(decodedStruct.f9).toEqual(testStructs.FloatNumberValues.V9);
  }

  function testIntegerNumberValues() {
    var decodedStruct = structEncodeDecode(new testStructs.IntegerNumberValues);
    expect(decodedStruct.f0).toEqual(testStructs.IntegerNumberValues.V0);
    expect(decodedStruct.f1).toEqual(testStructs.IntegerNumberValues.V1);
    expect(decodedStruct.f2).toEqual(testStructs.IntegerNumberValues.V2);
    expect(decodedStruct.f3).toEqual(testStructs.IntegerNumberValues.V3);
    expect(decodedStruct.f4).toEqual(testStructs.IntegerNumberValues.V4);
    expect(decodedStruct.f5).toEqual(testStructs.IntegerNumberValues.V5);
    expect(decodedStruct.f6).toEqual(testStructs.IntegerNumberValues.V6);
    expect(decodedStruct.f7).toEqual(testStructs.IntegerNumberValues.V7);
    expect(decodedStruct.f8).toEqual(testStructs.IntegerNumberValues.V8);
    expect(decodedStruct.f9).toEqual(testStructs.IntegerNumberValues.V9);
    expect(decodedStruct.f10).toEqual(testStructs.IntegerNumberValues.V10);
    expect(decodedStruct.f11).toEqual(testStructs.IntegerNumberValues.V11);
    expect(decodedStruct.f12).toEqual(testStructs.IntegerNumberValues.V12);
    expect(decodedStruct.f13).toEqual(testStructs.IntegerNumberValues.V13);
    expect(decodedStruct.f14).toEqual(testStructs.IntegerNumberValues.V14);
    expect(decodedStruct.f15).toEqual(testStructs.IntegerNumberValues.V15);
    expect(decodedStruct.f16).toEqual(testStructs.IntegerNumberValues.V16);
    expect(decodedStruct.f17).toEqual(testStructs.IntegerNumberValues.V17);
    expect(decodedStruct.f18).toEqual(testStructs.IntegerNumberValues.V18);
    expect(decodedStruct.f19).toEqual(testStructs.IntegerNumberValues.V19);
  }

  function testUnsignedNumberValues() {
    var decodedStruct =
        structEncodeDecode(new testStructs.UnsignedNumberValues);
    expect(decodedStruct.f0).toEqual(testStructs.UnsignedNumberValues.V0);
    expect(decodedStruct.f1).toEqual(testStructs.UnsignedNumberValues.V1);
    expect(decodedStruct.f2).toEqual(testStructs.UnsignedNumberValues.V2);
    expect(decodedStruct.f3).toEqual(testStructs.UnsignedNumberValues.V3);
    expect(decodedStruct.f4).toEqual(testStructs.UnsignedNumberValues.V4);
    expect(decodedStruct.f5).toEqual(testStructs.UnsignedNumberValues.V5);
    expect(decodedStruct.f6).toEqual(testStructs.UnsignedNumberValues.V6);
    expect(decodedStruct.f7).toEqual(testStructs.UnsignedNumberValues.V7);
    expect(decodedStruct.f8).toEqual(testStructs.UnsignedNumberValues.V8);
    expect(decodedStruct.f9).toEqual(testStructs.UnsignedNumberValues.V9);
    expect(decodedStruct.f10).toEqual(testStructs.UnsignedNumberValues.V10);
    expect(decodedStruct.f11).toEqual(testStructs.UnsignedNumberValues.V11);
  }


  function testBitArrayValues() {
    var bitArraysStruct = new testStructs.BitArrayValues({
      // array<bool, 1> f0;
      f0: [true],
      // array<bool, 7> f1;
      f1: [true, false, true, false, true, false, true],
      // array<bool, 9> f2;
      f2: [true, false, true, false, true, false, true, false, true],
      // array<bool> f3;
      f3: [true, false, true, false, true, false, true, false],
      // array<array<bool>> f4;
      f4: [[true], [false], [true, false], [true, false, true, false]],
      // array<array<bool>?> f5;
      f5: [[true], null, null, [true, false, true, false]],
      // array<array<bool, 2>?> f6;
      f6: [[true, false], [true, false], [true, false]],
    });
    var decodedStruct = structEncodeDecode(bitArraysStruct);
    expect(decodedStruct.f0).toEqual(bitArraysStruct.f0);
    expect(decodedStruct.f1).toEqual(bitArraysStruct.f1);
    expect(decodedStruct.f2).toEqual(bitArraysStruct.f2);
    expect(decodedStruct.f3).toEqual(bitArraysStruct.f3);
    expect(decodedStruct.f4).toEqual(bitArraysStruct.f4);
    expect(decodedStruct.f5).toEqual(bitArraysStruct.f5);
    expect(decodedStruct.f6).toEqual(bitArraysStruct.f6);
  }

  testConstructors();
  testNoDefaultFieldValues();
  testDefaultFieldValues();
  testScopedConstants();
  testMapKeyTypes();
  testMapValueTypes();
  testFloatNumberValues();
  testIntegerNumberValues();
  testUnsignedNumberValues();
  testBitArrayValues();
  this.result = "PASS";
});
