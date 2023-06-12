// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unicode Grapheme Breaking Algorithm Character Categories.
/// (Order is irrelevent to correctness, so it is chosen
/// to minimize the size of the generated table strings
/// by avoiding many bytes that need escapes).
const int categoryCR = 0;
const int categoryZWJ = 1;
const int categoryControl = 2;
const int categoryOther = 3; // Any character not in any other category.
const int categoryExtend = 4;
const int categorySpacingMark = 5;
const int categoryRegionalIndicator = 6;
const int categoryPictographic = 7;
const int categoryLF = 8;
const int categoryPrepend = 9;
const int categoryL = 10;
const int categoryV = 11;
const int categoryT = 12;
const int categoryLV = 13;
const int categoryLVT = 14;
const int categoryEoT = 15; // End of Text (synthetic input)

// Automaton states for forwards automaton.

const int stateSoT = 0; // Start of text (or grapheme).
const int stateBreak = 0x10; // Always break before next.
const int stateCR = 0x20; // Break unless next is LF.
const int stateOther = 0x30; // Break unless next is Extend, ZWJ, SpacingMark.
const int statePrepend = 0x40; // Only break if next is Control/CR/LF/eot.
const int stateL = 0x50; // As Other unless next is L, V, LV, LVT.
const int stateV = 0x60; // As Other unless next is V, T.
const int stateT = 0x70; // As Other unless next is T.
const int statePictographic = 0x80; // As Other unless followed by Ext* ZWJ Pic.
const int statePictographicZWJ = 0x90; // As Other unless followed by Pic.
const int stateRegionalSingle = 0xA0; // As Other unless followed by RI
const int stateSoTNoBreak = 0xB0; // As SoT but never cause break before next.

/// Bit flag or'ed to the automaton output if there should not be a break
/// before the most recent input character.
const int stateNoBreak = 1;

// Backwards Automaton extra/alternative states and categories.

const int categorySoT = 15; // Start of Text (synthetic input)

const int stateEoT = 0; // Start of text (or grapheme).
const int stateLF = 0x20; // Break unless prev is CR.
const int stateExtend = 0x40; // Only break if prev is Control/CR/LF/sot.
const int stateZWJPictographic = 0x90; // Preceeded by Pic Ext*.
const int stateEoTNoBreak = 0xB0; // As EoT but never cause break before.
const int stateRegionalEven = 0xC0; // There is an even number of RIs before.
const int stateRegionalOdd =
    stateZWJPictographic; // There is an odd (non-zero!) number of RIs before.

/// Minimum state requesting a look-ahead.
const int stateLookaheadMin = stateRegionalLookahead;

/// State requesting a look-ahead for an even or odd number of RIs.
const int stateRegionalLookahead = 0xD0;

/// State requesting a look-ahead for Pic Ext*.
const int stateZWJPictographicLookahead = 0xE0;
