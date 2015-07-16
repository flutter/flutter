// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define([
    "gin/test/expect",
    "mojo/public/interfaces/bindings/tests/test_unions.mojom",
    "mojo/public/js/codec",
    "mojo/public/js/validator",
], function(expect,
            unions,
            codec,
            validator) {
  function testConstructors() {
    var u = new unions.PodUnion();
    expect(u.$data).toEqual(null);
    expect(u.$tag).toBeUndefined();

    u.f_uint32 = 32;

    expect(u.f_uint32).toEqual(32);
    expect(u.$tag).toEqual(unions.PodUnion.Tags.f_uint32);

    var u = new unions.PodUnion({f_uint64: 64});
    expect(u.f_uint64).toEqual(64);
    expect(u.$tag).toEqual(unions.PodUnion.Tags.f_uint64);
    expect(function() {var v = u.f_uint32;}).toThrow();

    expect(function() {
      var u = new unions.PodUnion({
        f_uint64: 64,
        f_uint32: 32,
      });
    }).toThrow();

    expect(function() {
      var u = new unions.PodUnion({ foo: 64 }); }).toThrow();

    expect(function() {
      var u = new unions.PodUnion([1,2,3,4]); }).toThrow();
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
    var view = reader.decoder.buffer.dataView;

    return reader.decodeStruct(structClass);
  }

  function testBasicEncoding() {
    var s = new unions.WrapperStruct({
      pod_union: new unions.PodUnion({
        f_uint64: 64})});

    var decoded = structEncodeDecode(s);
    expect(decoded).toEqual(s);

    var s = new unions.WrapperStruct({
      object_union: new unions.ObjectUnion({
        f_dummy: new unions.DummyStruct({
          f_int8: 8})})});

    var decoded = structEncodeDecode(s);
    expect(decoded).toEqual(s);

    var s = new unions.WrapperStruct({
      object_union: new unions.ObjectUnion({
        f_array_int8: [1, 2, 3]})});

    var decoded = structEncodeDecode(s);
    expect(decoded).toEqual(s);

    var s = new unions.WrapperStruct({
      object_union: new unions.ObjectUnion({
        f_map_int8: new Map([
          ["first", 1],
          ["second", 2],
        ])})});

    var decoded = structEncodeDecode(s);
    expect(decoded).toEqual(s);

    // Encoding a union with no member set is an error.
    var s = new unions.WrapperStruct({
      object_union: new unions.ObjectUnion()});
    expect(function() {
      structEncodeDecode(s); }).toThrow();
  }

  function testUnionsInArrayEncoding() {
    var s = new unions.SmallStruct({
      pod_union_array: [
        new unions.PodUnion({f_uint32: 32}),
        new unions.PodUnion({f_uint64: 64}),
      ]
    });

    var decoded = structEncodeDecode(s);
    expect(decoded).toEqual(s);
  }

  function testUnionsInMapEncoding() {
    var s = new unions.SmallStruct({
      pod_union_map: new Map([
        ["thirty-two", new unions.PodUnion({f_uint32: 32})],
        ["sixty-four", new unions.PodUnion({f_uint64: 64})],
      ])
    });

    var decoded = structEncodeDecode(s);
    expect(decoded).toEqual(s);
  }

  function testNestedUnionsEncoding() {
    var s = new unions.WrapperStruct({
      object_union: new unions.ObjectUnion({
        f_pod_union: new unions.PodUnion({f_uint32: 32})
      })});
    var decoded = structEncodeDecode(s);
    expect(decoded).toEqual(s);
  }

  function structValidate(struct) {
    var structClass = struct.constructor;
    var builder = new codec.MessageBuilder(1234, structClass.encodedSize);
    builder.encodeStruct(structClass, struct);

    var message = builder.finish();

    var messageValidator = new validator.Validator(message);
    return structClass.validate(messageValidator, codec.kMessageHeaderSize);
  }

  function testNullUnionMemberValidation() {
    var s = new unions.WrapperStruct({
      object_union: new unions.ObjectUnion({
        f_dummy: null})});

    var err = structValidate(s);
    expect(err).toEqual(validator.validationError.UNEXPECTED_NULL_POINTER);

    var s = new unions.WrapperStruct({
      object_union: new unions.ObjectUnion({
        f_nullable: null})});

    var err = structValidate(s);
    expect(err).toEqual(validator.validationError.NONE);
  }

  function testNullUnionValidation() {
    var s = new unions.SmallStructNonNullableUnion({
      pod_union: null});

    var err = structValidate(s);
    expect(err).toEqual(validator.validationError.UNEXPECTED_NULL_UNION);

    var s = new unions.WrapperStruct({
      object_union: new unions.ObjectUnion({
        f_pod_union: null})
      });

    var err = structValidate(s);
    expect(err).toEqual(validator.validationError.UNEXPECTED_NULL_UNION);
  }

  testConstructors();
  testBasicEncoding();
  testUnionsInArrayEncoding();
  testUnionsInMapEncoding();
  testNestedUnionsEncoding();
  testNullUnionMemberValidation();
  testNullUnionValidation();
  this.result = "PASS";
});
