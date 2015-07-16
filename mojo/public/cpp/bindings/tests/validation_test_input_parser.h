// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_TESTS_VALIDATION_TEST_INPUT_PARSER_H_
#define MOJO_PUBLIC_CPP_BINDINGS_TESTS_VALIDATION_TEST_INPUT_PARSER_H_

#include <stdint.h>

#include <string>
#include <vector>

namespace mojo {
namespace test {

// Input Format of Mojo Message Validation Tests.
//
// Data items are separated by whitespaces:
//   - ' ' (0x20) space;
//   - '\t' (0x09) horizontal tab;
//   - '\n' (0x0a) newline;
//   - '\r' (0x0d) carriage return.
// A comment starts with //, extending to the end of the line.
// Each data item is of the format [<type>]<value>. The types defined and the
// corresponding value formats are described below.
//
// Type: u1 / u2 / u4 / u8
// Description: Little-endian 1/2/4/8-byte unsigned integer.
// Value Format:
//   - Decimal integer: 0|[1-9][0-9]*
//   - Hexadecimal integer: 0[xX][0-9a-fA-F]+
//   - The type prefix (including the square brackets) of 1-byte unsigned
//   integer is optional.
//
// Type: s1 / s2 / s4 / s8
// Description: Little-endian 1/2/4/8-byte signed integer.
// Value Format:
//   - Decimal integer: [-+]?(0|[1-9][0-9]*)
//   - Hexadecimal integer: [-+]?0[xX][0-9a-fA-F]+
//
// Type: b
// Description: Binary sequence of 1 byte.
// Value Format: [01]{8}
//
// Type: f / d
// Description: Little-endian IEEE-754 format of float (4 bytes) and double (8
// bytes).
// Value Format: [-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?
//
// Type: dist4 / dist8
// Description: Little-endian 4/8-byte unsigned integer. The actual value is set
// to the byte distance from the location of this integer to the location of the
// anchr item with the same ID. A dist8 and anchr pair can be used to easily
// represent an encoded pointer. A dist4 and anchr pair can be used to easily
// calculate struct/array size.
// Value Format: The value is an ID: [0-9a-zA-Z_]+
//
// Type: anchr
// Description: Mark an anchor location. It doesn’t translate into any actual
// data.
// Value Format: The value is an ID of the same format as that of dist4/8.
//
// Type: handles
// Description: The number of handles that are associated with the message. This
// special item is not part of the message data. If specified, it should be the
// first item.
// Value Format: The same format as u1/2/4/8.
//
// EXAMPLE:
//
// Suppose you have the following Mojo types defined:
//   struct Bar {
//     int32 a;
//     bool b;
//     bool c;
//   };
//   struct Foo {
//     Bar x;
//     uint32 y;
//   };
//
// The following describes a valid message whose payload is a Foo struct:
//   // message header
//   [dist4]message_header   // num_bytes
//   [u4]3                   // version
//   [u4]0                   // type
//   [u4]1                   // flags
//   [u8]1234                // request_id
//   [anchr]message_header
//
//   // payload
//   [dist4]foo      // num_bytes
//   [u4]2           // version
//   [dist8]bar_ptr  // x
//   [u4]0xABCD      // y
//   [u4]0           // padding
//   [anchr]foo
//
//   [anchr]bar_ptr
//   [dist4]bar   // num_bytes
//   [u4]3        // version
//   [s4]-1       // a
//   [b]00000010  // b and c
//   0 0 0        // padding
//   [anchr]bar

// Parses validation test input.
// On success, |data| and |num_handles| store the parsing result,
// |error_message| is cleared; on failure, |error_message| is set to a message
// describing the error, |data| is cleared and |num_handles| set to 0.
// Note: For now, this method only works on little-endian platforms.
bool ParseValidationTestInput(const std::string& input,
                              std::vector<uint8_t>* data,
                              size_t* num_handles,
                              std::string* error_message);

}  // namespace test
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_TESTS_VALIDATION_TEST_INPUT_PARSER_H_
