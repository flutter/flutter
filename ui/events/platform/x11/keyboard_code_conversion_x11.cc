// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/platform/x11/keyboard_code_conversion_x11.h"

#include <algorithm>

#define XK_3270  // for XK_3270_BackTab
#include <X11/extensions/XInput2.h>
#include <X11/keysym.h>
#include <X11/XF86keysym.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/strings/stringprintf.h"
#include "base/strings/sys_string_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include "ui/events/keycodes/dom4/keycode_converter.h"
#include "ui/events/platform/x11/keysym_to_unicode.h"

#define VKEY_UNSUPPORTED VKEY_UNKNOWN

namespace ui {

namespace {

// MAP0 - MAP3:
// These are the generated VKEY code maps for all possible Latin keyboard
// layouts in Windows. And the maps are only for special letter keys excluding
// [a-z] & [0-9].
//
// ch0: the keysym without modifier states.
// ch1: the keysym with shift state.
// ch2: the keysym with altgr state.
// sc: the hardware keycode (in Windows, it's called scan code).
// vk: the VKEY code.
//
// MAP0: maps from ch0 to vk.
// MAP1: maps from ch0+sc to vk.
// MAP2: maps from ch0+ch1+sc to vk.
// MAP3: maps from ch0+ch1+ch2+sc to vk.
// MAP0 - MAP3 are all sorted, so that finding VK can be binary search.
//
// Reason for creating these maps is because a hard-coded mapping in
// KeyboardCodeFromXKeysym() doesn't support non-US keyboard layouts.
// e.g. in UK keyboard, the key between Quote and Enter keys has the VKEY code
// VKEY_OEM_5 instead of VKEY_3.
//
// The key symbols which are not [a-zA-Z0-9] and functional/extend keys (e.g.
// TAB, ENTER, BS, Arrow keys, modifier keys, F1-F12, media/app keys, etc.)
// should go through these maps for correct VKEY codes.
//
// Please refer to crbug.com/386066.
//
const struct MAP0 {
  KeySym ch0;
  uint8 vk;
  bool operator()(const MAP0& m1, const MAP0& m2) const {
    return m1.ch0 < m2.ch0;
  }
} map0[] = {
    {0x0025, 0x35},  // XK_percent: VKEY_5
    {0x0026, 0x31},  // XK_ampersand: VKEY_1
    {0x003C, 0xDC},  // XK_less: VKEY_OEM_5
    {0x007B, 0xDE},  // XK_braceleft: VKEY_OEM_7
    {0x007C, 0xDC},  // XK_bar: VKEY_OEM_5
    {0x007D, 0xBF},  // XK_braceright: VKEY_OEM_2
    {0x007E, 0xDC},  // XK_asciitilde: VKEY_OEM_5
    {0x00A1, 0xDD},  // XK_exclamdown: VKEY_OEM_6
    {0x00AD, 0xC0},  // XK_hyphen: VKEY_OEM_3
    {0x00B2, 0xDE},  // XK_twosuperior: VKEY_OEM_7
    {0x00B5, 0xDC},  // XK_mu: VKEY_OEM_5
    {0x00BB, 0x39},  // XK_guillemotright: VKEY_9
    {0x00BD, 0xDC},  // XK_onehalf: VKEY_OEM_5
    {0x00BF, 0xDD},  // XK_questiondown: VKEY_OEM_6
    {0x00DF, 0xDB},  // XK_ssharp: VKEY_OEM_4
    {0x00E5, 0xDD},  // XK_aring: VKEY_OEM_6
    {0x00EA, 0x33},  // XK_ecircumflex: VKEY_3
    {0x00EB, 0xBA},  // XK_ediaeresis: VKEY_OEM_1
    {0x00EC, 0xDD},  // XK_igrave: VKEY_OEM_6
    {0x00EE, 0xDD},  // XK_icircumflex: VKEY_OEM_6
    {0x00F1, 0xC0},  // XK_ntilde: VKEY_OEM_3
    {0x00F2, 0xC0},  // XK_ograve: VKEY_OEM_3
    {0x00F5, 0xDB},  // XK_otilde: VKEY_OEM_4
    {0x00F7, 0xDD},  // XK_division: VKEY_OEM_6
    {0x00FD, 0x37},  // XK_yacute: VKEY_7
    {0x00FE, 0xBD},  // XK_thorn: VKEY_OEM_MINUS
    {0x01A1, 0xDD},  // XK_ohorn: VKEY_OEM_6
    {0x01B0, 0xDB},  // XK_uhorn: VKEY_OEM_4
    {0x01B5, 0x32},  // XK_lcaron: VKEY_2
    {0x01B6, 0xDD},  // XK_zstroke: VKEY_OEM_6
    {0x01BB, 0x35},  // XK_tcaron: VKEY_5
    {0x01E6, 0xDE},  // XK_cacute: VKEY_OEM_7
    {0x01EC, 0x32},  // XK_ecaron: VKEY_2
    {0x01F2, 0xDC},  // XK_ncaron: VKEY_OEM_5
    {0x01F5, 0xDB},  // XK_odoubleacute: VKEY_OEM_4
    {0x01F8, 0x35},  // XK_rcaron: VKEY_5
    {0x01F9, 0xBA},  // XK_uring: VKEY_OEM_1
    {0x01FB, 0xDC},  // XK_udoubleacute: VKEY_OEM_5
    {0x01FE, 0xDE},  // XK_tcedilla: VKEY_OEM_7
    {0x0259, 0xC0},  // XK_schwa: VKEY_OEM_3
    {0x02B1, 0xDD},  // XK_hstroke: VKEY_OEM_6
    {0x02B9, 0xBA},  // XK_idotless: VKEY_OEM_1
    {0x02BB, 0xDD},  // XK_gbreve: VKEY_OEM_6
    {0x02E5, 0xC0},  // XK_cabovedot: VKEY_OEM_3
    {0x02F5, 0xDB},  // XK_gabovedot: VKEY_OEM_4
    {0x03B6, 0xBF},  // XK_lcedilla: VKEY_OEM_2
    {0x03BA, 0x57},  // XK_emacron: VKEY_W
    {0x03E0, 0xDF},  // XK_amacron: VKEY_OEM_8
    {0x03EF, 0xDD},  // XK_imacron: VKEY_OEM_6
    {0x03F1, 0xDB},  // XK_ncedilla: VKEY_OEM_4
    {0x03F3, 0xDC},  // XK_kcedilla: VKEY_OEM_5
};

const struct MAP1 {
  KeySym ch0;
  unsigned sc;
  uint8 vk;
  bool operator()(const MAP1& m1, const MAP1& m2) const {
    if (m1.ch0 == m2.ch0)
      return m1.sc < m2.sc;
    return m1.ch0 < m2.ch0;
  }
} map1[] = {
    {0x0021, 0x0A, 0x31},  // XK_exclam+AE01: VKEY_1
    {0x0021, 0x11, 0x38},  // XK_exclam+AE08: VKEY_8
    {0x0021, 0x3D, 0xDF},  // XK_exclam+AB10: VKEY_OEM_8
    {0x0022, 0x0B, 0x32},  // XK_quotedbl+AE02: VKEY_2
    {0x0022, 0x0C, 0x33},  // XK_quotedbl+AE03: VKEY_3
    {0x0023, 0x31, 0xDE},  // XK_numbersign+TLDE: VKEY_OEM_7
    {0x0024, 0x23, 0xBA},  // XK_dollar+AD12: VKEY_OEM_1
    {0x0024, 0x33, 0xDF},  // XK_dollar+BKSL: VKEY_OEM_8
    {0x0027, 0x0D, 0x34},  // XK_quoteright+AE04: VKEY_4
    {0x0027, 0x18, 0xDE},  // XK_quoteright+AD01: VKEY_OEM_7
    {0x0027, 0x23, 0xBA},  // XK_quoteright+AD12: VKEY_OEM_1
    {0x0027, 0x3D, 0xDE},  // XK_quoteright+AB10: VKEY_OEM_7
    {0x0028, 0x0E, 0x35},  // XK_parenleft+AE05: VKEY_5
    {0x0028, 0x12, 0x39},  // XK_parenleft+AE09: VKEY_9
    {0x0028, 0x33, 0xDC},  // XK_parenleft+BKSL: VKEY_OEM_5
    {0x0029, 0x13, 0x30},  // XK_parenright+AE10: VKEY_0
    {0x0029, 0x14, 0xDB},  // XK_parenright+AE11: VKEY_OEM_4
    {0x0029, 0x23, 0xDD},  // XK_parenright+AD12: VKEY_OEM_6
    {0x002A, 0x23, 0xBA},  // XK_asterisk+AD12: VKEY_OEM_1
    {0x002A, 0x33, 0xDC},  // XK_asterisk+BKSL: VKEY_OEM_5
    {0x002B, 0x0A, 0x31},  // XK_plus+AE01: VKEY_1
    {0x002B, 0x15, 0xBB},  // XK_plus+AE12: VKEY_OEM_PLUS
    {0x002B, 0x22, 0xBB},  // XK_plus+AD11: VKEY_OEM_PLUS
    {0x002B, 0x23, 0xBB},  // XK_plus+AD12: VKEY_OEM_PLUS
    {0x002B, 0x2F, 0xBB},  // XK_plus+AC10: VKEY_OEM_PLUS
    {0x002B, 0x33, 0xBF},  // XK_plus+BKSL: VKEY_OEM_2
    {0x002C, 0x0C, 0x33},  // XK_comma+AE03: VKEY_3
    {0x002C, 0x0E, 0x35},  // XK_comma+AE05: VKEY_5
    {0x002C, 0x0F, 0x36},  // XK_comma+AE06: VKEY_6
    {0x002C, 0x12, 0x39},  // XK_comma+AE09: VKEY_9
    {0x002C, 0x19, 0xBC},  // XK_comma+AD02: VKEY_OEM_COMMA
    {0x002C, 0x37, 0xBC},  // XK_comma+AB04: VKEY_OEM_COMMA
    {0x002C, 0x3A, 0xBC},  // XK_comma+AB07: VKEY_OEM_COMMA
    {0x002C, 0x3B, 0xBC},  // XK_comma+AB08: VKEY_OEM_COMMA
    {0x002D, 0x0B, 0x32},  // XK_minus+AE02: VKEY_2
    {0x002D, 0x0F, 0x36},  // XK_minus+AE06: VKEY_6
    {0x002D, 0x14, 0xBD},  // XK_minus+AE11: VKEY_OEM_MINUS
    {0x002D, 0x26, 0xBD},  // XK_minus+AC01: VKEY_OEM_MINUS
    {0x002D, 0x30, 0xBD},  // XK_minus+AC11: VKEY_OEM_MINUS
    {0x002E, 0x10, 0x37},  // XK_period+AE07: VKEY_7
    {0x002E, 0x11, 0x38},  // XK_period+AE08: VKEY_8
    {0x002E, 0x1A, 0xBE},  // XK_period+AD03: VKEY_OEM_PERIOD
    {0x002E, 0x1B, 0xBE},  // XK_period+AD04: VKEY_OEM_PERIOD
    {0x002E, 0x20, 0xBE},  // XK_period+AD09: VKEY_OEM_PERIOD
    {0x002E, 0x30, 0xDE},  // XK_period+AC11: VKEY_OEM_7
    {0x002E, 0x3C, 0xBE},  // XK_period+AB09: VKEY_OEM_PERIOD
    {0x002E, 0x3D, 0xBF},  // XK_period+AB10: VKEY_OEM_2
    {0x002F, 0x14, 0xDB},  // XK_slash+AE11: VKEY_OEM_4
    {0x002F, 0x22, 0xBF},  // XK_slash+AD11: VKEY_OEM_2
    {0x002F, 0x31, 0xDE},  // XK_slash+TLDE: VKEY_OEM_7
    {0x002F, 0x33, 0xDC},  // XK_slash+BKSL: VKEY_OEM_5
    {0x002F, 0x3D, 0xBF},  // XK_slash+AB10: VKEY_OEM_2
    {0x003A, 0x0A, 0x31},  // XK_colon+AE01: VKEY_1
    {0x003A, 0x0E, 0x35},  // XK_colon+AE05: VKEY_5
    {0x003A, 0x0F, 0x36},  // XK_colon+AE06: VKEY_6
    {0x003A, 0x3C, 0xBF},  // XK_colon+AB09: VKEY_OEM_2
    {0x003B, 0x0D, 0x34},  // XK_semicolon+AE04: VKEY_4
    {0x003B, 0x11, 0x38},  // XK_semicolon+AE08: VKEY_8
    {0x003B, 0x18, 0xBA},  // XK_semicolon+AD01: VKEY_OEM_1
    {0x003B, 0x22, 0xBA},  // XK_semicolon+AD11: VKEY_OEM_1
    {0x003B, 0x23, 0xDD},  // XK_semicolon+AD12: VKEY_OEM_6
    {0x003B, 0x2F, 0xBA},  // XK_semicolon+AC10: VKEY_OEM_1
    {0x003B, 0x31, 0xC0},  // XK_semicolon+TLDE: VKEY_OEM_3
    {0x003B, 0x34, 0xBA},  // XK_semicolon+AB01: VKEY_OEM_1
    {0x003B, 0x3B, 0xBE},  // XK_semicolon+AB08: VKEY_OEM_PERIOD
    {0x003B, 0x3D, 0xBF},  // XK_semicolon+AB10: VKEY_OEM_2
    {0x003D, 0x11, 0x38},  // XK_equal+AE08: VKEY_8
    {0x003D, 0x15, 0xBB},  // XK_equal+AE12: VKEY_OEM_PLUS
    {0x003D, 0x23, 0xBB},  // XK_equal+AD12: VKEY_OEM_PLUS
    {0x003F, 0x0B, 0x32},  // XK_question+AE02: VKEY_2
    {0x003F, 0x10, 0x37},  // XK_question+AE07: VKEY_7
    {0x003F, 0x11, 0x38},  // XK_question+AE08: VKEY_8
    {0x003F, 0x14, 0xBB},  // XK_question+AE11: VKEY_OEM_PLUS
    {0x0040, 0x23, 0xDD},  // XK_at+AD12: VKEY_OEM_6
    {0x0040, 0x31, 0xDE},  // XK_at+TLDE: VKEY_OEM_7
    {0x005B, 0x0A, 0xDB},  // XK_bracketleft+AE01: VKEY_OEM_4
    {0x005B, 0x14, 0xDB},  // XK_bracketleft+AE11: VKEY_OEM_4
    {0x005B, 0x22, 0xDB},  // XK_bracketleft+AD11: VKEY_OEM_4
    {0x005B, 0x23, 0xDD},  // XK_bracketleft+AD12: VKEY_OEM_6
    {0x005B, 0x30, 0xDE},  // XK_bracketleft+AC11: VKEY_OEM_7
    {0x005C, 0x15, 0xDB},  // XK_backslash+AE12: VKEY_OEM_4
    {0x005D, 0x0B, 0xDD},  // XK_bracketright+AE02: VKEY_OEM_6
    {0x005D, 0x15, 0xDD},  // XK_bracketright+AE12: VKEY_OEM_6
    {0x005D, 0x23, 0xDD},  // XK_bracketright+AD12: VKEY_OEM_6
    {0x005D, 0x31, 0xC0},  // XK_bracketright+TLDE: VKEY_OEM_3
    {0x005D, 0x33, 0xDC},  // XK_bracketright+BKSL: VKEY_OEM_5
    {0x005F, 0x11, 0x38},  // XK_underscore+AE08: VKEY_8
    {0x005F, 0x14, 0xBD},  // XK_underscore+AE11: VKEY_OEM_MINUS
    {0x00A7, 0x0D, 0x34},  // XK_section+AE04: VKEY_4
    {0x00A7, 0x0F, 0x36},  // XK_section+AE06: VKEY_6
    {0x00A7, 0x30, 0xDE},  // XK_section+AC11: VKEY_OEM_7
    {0x00AB, 0x11, 0x38},  // XK_guillemotleft+AE08: VKEY_8
    {0x00AB, 0x15, 0xDD},  // XK_guillemotleft+AE12: VKEY_OEM_6
    {0x00B0, 0x15, 0xBF},  // XK_degree+AE12: VKEY_OEM_2
    {0x00B0, 0x31, 0xDE},  // XK_degree+TLDE: VKEY_OEM_7
    {0x00BA, 0x30, 0xDE},  // XK_masculine+AC11: VKEY_OEM_7
    {0x00BA, 0x31, 0xDC},  // XK_masculine+TLDE: VKEY_OEM_5
    {0x00E0, 0x13, 0x30},  // XK_agrave+AE10: VKEY_0
    {0x00E0, 0x33, 0xDC},  // XK_agrave+BKSL: VKEY_OEM_5
    {0x00E1, 0x11, 0x38},  // XK_aacute+AE08: VKEY_8
    {0x00E1, 0x30, 0xDE},  // XK_aacute+AC11: VKEY_OEM_7
    {0x00E2, 0x0B, 0x32},  // XK_acircumflex+AE02: VKEY_2
    {0x00E2, 0x33, 0xDC},  // XK_acircumflex+BKSL: VKEY_OEM_5
    {0x00E4, 0x23, 0xDD},  // XK_adiaeresis+AD12: VKEY_OEM_6
    {0x00E6, 0x2F, 0xC0},  // XK_ae+AC10: VKEY_OEM_3
    {0x00E6, 0x30, 0xDE},  // XK_ae+AC11: VKEY_OEM_7
    {0x00E7, 0x12, 0x39},  // XK_ccedilla+AE09: VKEY_9
    {0x00E7, 0x22, 0xDB},  // XK_ccedilla+AD11: VKEY_OEM_4
    {0x00E7, 0x23, 0xDD},  // XK_ccedilla+AD12: VKEY_OEM_6
    {0x00E7, 0x30, 0xDE},  // XK_ccedilla+AC11: VKEY_OEM_7
    {0x00E7, 0x33, 0xBF},  // XK_ccedilla+BKSL: VKEY_OEM_2
    {0x00E7, 0x3B, 0xBC},  // XK_ccedilla+AB08: VKEY_OEM_COMMA
    {0x00E8, 0x10, 0x37},  // XK_egrave+AE07: VKEY_7
    {0x00E8, 0x22, 0xBA},  // XK_egrave+AD11: VKEY_OEM_1
    {0x00E8, 0x30, 0xC0},  // XK_egrave+AC11: VKEY_OEM_3
    {0x00E9, 0x0B, 0x32},  // XK_eacute+AE02: VKEY_2
    {0x00E9, 0x13, 0x30},  // XK_eacute+AE10: VKEY_0
    {0x00E9, 0x3D, 0xBF},  // XK_eacute+AB10: VKEY_OEM_2
    {0x00ED, 0x12, 0x39},  // XK_iacute+AE09: VKEY_9
    {0x00ED, 0x31, 0x30},  // XK_iacute+TLDE: VKEY_0
    {0x00F0, 0x22, 0xDD},  // XK_eth+AD11: VKEY_OEM_6
    {0x00F0, 0x23, 0xBA},  // XK_eth+AD12: VKEY_OEM_1
    {0x00F3, 0x15, 0xBB},  // XK_oacute+AE12: VKEY_OEM_PLUS
    {0x00F3, 0x33, 0xDC},  // XK_oacute+BKSL: VKEY_OEM_5
    {0x00F4, 0x0D, 0x34},  // XK_ocircumflex+AE04: VKEY_4
    {0x00F4, 0x2F, 0xBA},  // XK_ocircumflex+AC10: VKEY_OEM_1
    {0x00F6, 0x13, 0xC0},  // XK_odiaeresis+AE10: VKEY_OEM_3
    {0x00F6, 0x14, 0xBB},  // XK_odiaeresis+AE11: VKEY_OEM_PLUS
    {0x00F6, 0x22, 0xDB},  // XK_odiaeresis+AD11: VKEY_OEM_4
    {0x00F8, 0x2F, 0xC0},  // XK_oslash+AC10: VKEY_OEM_3
    {0x00F8, 0x30, 0xDE},  // XK_oslash+AC11: VKEY_OEM_7
    {0x00F9, 0x30, 0xC0},  // XK_ugrave+AC11: VKEY_OEM_3
    {0x00F9, 0x33, 0xBF},  // XK_ugrave+BKSL: VKEY_OEM_2
    {0x00FA, 0x22, 0xDB},  // XK_uacute+AD11: VKEY_OEM_4
    {0x00FA, 0x23, 0xDD},  // XK_uacute+AD12: VKEY_OEM_6
    {0x00FC, 0x19, 0x57},  // XK_udiaeresis+AD02: VKEY_W
    {0x01B1, 0x0A, 0x31},  // XK_aogonek+AE01: VKEY_1
    {0x01B1, 0x18, 0x51},  // XK_aogonek+AD01: VKEY_Q
    {0x01B1, 0x30, 0xDE},  // XK_aogonek+AC11: VKEY_OEM_7
    {0x01B3, 0x2F, 0xBA},  // XK_lstroke+AC10: VKEY_OEM_1
    {0x01B3, 0x33, 0xBF},  // XK_lstroke+BKSL: VKEY_OEM_2
    {0x01B9, 0x0C, 0x33},  // XK_scaron+AE03: VKEY_3
    {0x01B9, 0x0F, 0x36},  // XK_scaron+AE06: VKEY_6
    {0x01B9, 0x22, 0xDB},  // XK_scaron+AD11: VKEY_OEM_4
    {0x01B9, 0x26, 0xBA},  // XK_scaron+AC01: VKEY_OEM_1
    {0x01B9, 0x29, 0x46},  // XK_scaron+AC04: VKEY_F
    {0x01B9, 0x3C, 0xBE},  // XK_scaron+AB09: VKEY_OEM_PERIOD
    {0x01BA, 0x2F, 0xBA},  // XK_scedilla+AC10: VKEY_OEM_1
    {0x01BA, 0x3C, 0xBE},  // XK_scedilla+AB09: VKEY_OEM_PERIOD
    {0x01BE, 0x0F, 0x36},  // XK_zcaron+AE06: VKEY_6
    {0x01BE, 0x15, 0xBB},  // XK_zcaron+AE12: VKEY_OEM_PLUS
    {0x01BE, 0x19, 0x57},  // XK_zcaron+AD02: VKEY_W
    {0x01BE, 0x22, 0x59},  // XK_zcaron+AD11: VKEY_Y
    {0x01BE, 0x33, 0xDC},  // XK_zcaron+BKSL: VKEY_OEM_5
    {0x01BF, 0x22, 0xDB},  // XK_zabovedot+AD11: VKEY_OEM_4
    {0x01BF, 0x33, 0xDC},  // XK_zabovedot+BKSL: VKEY_OEM_5
    {0x01E3, 0x0A, 0x31},  // XK_abreve+AE01: VKEY_1
    {0x01E3, 0x22, 0xDB},  // XK_abreve+AD11: VKEY_OEM_4
    {0x01E8, 0x0B, 0x32},  // XK_ccaron+AE02: VKEY_2
    {0x01E8, 0x0D, 0x34},  // XK_ccaron+AE04: VKEY_4
    {0x01E8, 0x21, 0x58},  // XK_ccaron+AD10: VKEY_X
    {0x01E8, 0x2F, 0xBA},  // XK_ccaron+AC10: VKEY_OEM_1
    {0x01E8, 0x3B, 0xBC},  // XK_ccaron+AB08: VKEY_OEM_COMMA
    {0x01EA, 0x0C, 0x33},  // XK_eogonek+AE03: VKEY_3
    {0x01F0, 0x13, 0x30},  // XK_dstroke+AE10: VKEY_0
    {0x01F0, 0x23, 0xDD},  // XK_dstroke+AD12: VKEY_OEM_6
    {0x03E7, 0x0E, 0x35},  // XK_iogonek+AE05: VKEY_5
    {0x03EC, 0x0D, 0x34},  // XK_eabovedot+AE04: VKEY_4
    {0x03EC, 0x30, 0xDE},  // XK_eabovedot+AC11: VKEY_OEM_7
    {0x03F9, 0x10, 0x37},  // XK_uogonek+AE07: VKEY_7
    {0x03FE, 0x11, 0x38},  // XK_umacron+AE08: VKEY_8
    {0x03FE, 0x18, 0x51},  // XK_umacron+AD01: VKEY_Q
    {0x03FE, 0x35, 0x58},  // XK_umacron+AB02: VKEY_X
};

const struct MAP2 {
  KeySym ch0;
  unsigned sc;
  KeySym ch1;
  uint8 vk;
  bool operator()(const MAP2& m1, const MAP2& m2) const {
    if (m1.ch0 == m2.ch0 && m1.sc == m2.sc)
      return m1.ch1 < m2.ch1;
    if (m1.ch0 == m2.ch0)
      return m1.sc < m2.sc;
    return m1.ch0 < m2.ch0;
  }
} map2[] = {
    {0x0023,
     0x33,
     0x0027,
     0xBF},  // XK_numbersign+BKSL+XK_quoteright: VKEY_OEM_2
    {0x0027, 0x30, 0x0022, 0xDE},  // XK_quoteright+AC11+XK_quotedbl: VKEY_OEM_7
    {0x0027, 0x31, 0x0022, 0xC0},  // XK_quoteright+TLDE+XK_quotedbl: VKEY_OEM_3
    {0x0027,
     0x31,
     0x00B7,
     0xDC},  // XK_quoteright+TLDE+XK_periodcentered: VKEY_OEM_5
    {0x0027, 0x33, 0x0000, 0xDC},  // XK_quoteright+BKSL+NoSymbol: VKEY_OEM_5
    {0x002D, 0x3D, 0x003D, 0xBD},  // XK_minus+AB10+XK_equal: VKEY_OEM_MINUS
    {0x002F, 0x0C, 0x0033, 0x33},  // XK_slash+AE03+XK_3: VKEY_3
    {0x002F, 0x0C, 0x003F, 0xBF},  // XK_slash+AE03+XK_question: VKEY_OEM_2
    {0x002F, 0x13, 0x0030, 0x30},  // XK_slash+AE10+XK_0: VKEY_0
    {0x002F, 0x13, 0x003F, 0xBF},  // XK_slash+AE10+XK_question: VKEY_OEM_2
    {0x003D, 0x3D, 0x0025, 0xDF},  // XK_equal+AB10+XK_percent: VKEY_OEM_8
    {0x003D, 0x3D, 0x002B, 0xBB},  // XK_equal+AB10+XK_plus: VKEY_OEM_PLUS
    {0x005C, 0x33, 0x002F, 0xDE},  // XK_backslash+BKSL+XK_slash: VKEY_OEM_7
    {0x005C, 0x33, 0x007C, 0xDC},  // XK_backslash+BKSL+XK_bar: VKEY_OEM_5
    {0x0060, 0x31, 0x0000, 0xC0},  // XK_quoteleft+TLDE+NoSymbol: VKEY_OEM_3
    {0x0060, 0x31, 0x00AC, 0xDF},  // XK_quoteleft+TLDE+XK_notsign: VKEY_OEM_8
    {0x00A7, 0x31, 0x00B0, 0xBF},  // XK_section+TLDE+XK_degree: VKEY_OEM_2
    {0x00A7, 0x31, 0x00BD, 0xDC},  // XK_section+TLDE+XK_onehalf: VKEY_OEM_5
    {0x00E0, 0x30, 0x00B0, 0xDE},  // XK_agrave+AC11+XK_degree: VKEY_OEM_7
    {0x00E0, 0x30, 0x00E4, 0xDC},  // XK_agrave+AC11+XK_adiaeresis: VKEY_OEM_5
    {0x00E4, 0x30, 0x00E0, 0xDC},  // XK_adiaeresis+AC11+XK_agrave: VKEY_OEM_5
    {0x00E9, 0x2F, 0x00C9, 0xBA},  // XK_eacute+AC10+XK_Eacute: VKEY_OEM_1
    {0x00E9, 0x2F, 0x00F6, 0xDE},  // XK_eacute+AC10+XK_odiaeresis: VKEY_OEM_7
    {0x00F6, 0x2F, 0x00E9, 0xDE},  // XK_odiaeresis+AC10+XK_eacute: VKEY_OEM_7
    {0x00FC, 0x22, 0x00E8, 0xBA},  // XK_udiaeresis+AD11+XK_egrave: VKEY_OEM_1
};

const struct MAP3 {
  KeySym ch0;
  unsigned sc;
  KeySym ch1;
  KeySym ch2;
  uint8 vk;
  bool operator()(const MAP3& m1, const MAP3& m2) const {
    if (m1.ch0 == m2.ch0 && m1.sc == m2.sc && m1.ch1 == m2.ch1)
      return m1.ch2 < m2.ch2;
    if (m1.ch0 == m2.ch0 && m1.sc == m2.sc)
      return m1.ch1 < m2.ch1;
    if (m1.ch0 == m2.ch0)
      return m1.sc < m2.sc;
    return m1.ch0 < m2.ch0;
  }
} map3[] = {
    {0x0023,
     0x33,
     0x007E,
     0x0000,
     0xDE},  // XK_numbersign+BKSL+XK_asciitilde+NoSymbol: VKEY_OEM_7
    {0x0027,
     0x14,
     0x003F,
     0x0000,
     0xDB},  // XK_quoteright+AE11+XK_question+NoSymbol: VKEY_OEM_4
    {0x0027,
     0x14,
     0x003F,
     0x00DD,
     0xDB},  // XK_quoteright+AE11+XK_question+XK_Yacute: VKEY_OEM_4
    {0x0027,
     0x15,
     0x002A,
     0x0000,
     0xBB},  // XK_quoteright+AE12+XK_asterisk+NoSymbol: VKEY_OEM_PLUS
    {0x0027,
     0x30,
     0x0040,
     0x0000,
     0xC0},  // XK_quoteright+AC11+XK_at+NoSymbol: VKEY_OEM_3
    {0x0027,
     0x33,
     0x002A,
     0x0000,
     0xBF},  // XK_quoteright+BKSL+XK_asterisk+NoSymbol: VKEY_OEM_2
    {0x0027,
     0x33,
     0x002A,
     0x00BD,
     0xDC},  // XK_quoteright+BKSL+XK_asterisk+XK_onehalf: VKEY_OEM_5
    {0x0027,
     0x33,
     0x002A,
     0x01A3,
     0xBF},  // XK_quoteright+BKSL+XK_asterisk+XK_Lstroke: VKEY_OEM_2
    {0x0027,
     0x34,
     0x0022,
     0x0000,
     0x5A},  // XK_quoteright+AB01+XK_quotedbl+NoSymbol: VKEY_Z
    {0x0027,
     0x34,
     0x0022,
     0x01D8,
     0xDE},  // XK_quoteright+AB01+XK_quotedbl+XK_Rcaron: VKEY_OEM_7
    {0x002B,
     0x14,
     0x003F,
     0x0000,
     0xBB},  // XK_plus+AE11+XK_question+NoSymbol: VKEY_OEM_PLUS
    {0x002B,
     0x14,
     0x003F,
     0x005C,
     0xBD},  // XK_plus+AE11+XK_question+XK_backslash: VKEY_OEM_MINUS
    {0x002B,
     0x14,
     0x003F,
     0x01F5,
     0xBB},  // XK_plus+AE11+XK_question+XK_odoubleacute: VKEY_OEM_PLUS
    {0x002D,
     0x15,
     0x005F,
     0x0000,
     0xBD},  // XK_minus+AE12+XK_underscore+NoSymbol: VKEY_OEM_MINUS
    {0x002D,
     0x15,
     0x005F,
     0x03B3,
     0xDB},  // XK_minus+AE12+XK_underscore+XK_rcedilla: VKEY_OEM_4
    {0x002D,
     0x3D,
     0x005F,
     0x0000,
     0xBD},  // XK_minus+AB10+XK_underscore+NoSymbol: VKEY_OEM_MINUS
    {0x002D,
     0x3D,
     0x005F,
     0x002A,
     0xBD},  // XK_minus+AB10+XK_underscore+XK_asterisk: VKEY_OEM_MINUS
    {0x002D,
     0x3D,
     0x005F,
     0x002F,
     0xBF},  // XK_minus+AB10+XK_underscore+XK_slash: VKEY_OEM_2
    {0x002D,
     0x3D,
     0x005F,
     0x006E,
     0xBD},  // XK_minus+AB10+XK_underscore+XK_n: VKEY_OEM_MINUS
    {0x003D,
     0x14,
     0x0025,
     0x0000,
     0xBB},  // XK_equal+AE11+XK_percent+NoSymbol: VKEY_OEM_PLUS
    {0x003D,
     0x14,
     0x0025,
     0x002D,
     0xBD},  // XK_equal+AE11+XK_percent+XK_minus: VKEY_OEM_MINUS
    {0x005C,
     0x31,
     0x007C,
     0x0031,
     0xDC},  // XK_backslash+TLDE+XK_bar+XK_1: VKEY_OEM_5
    {0x005C,
     0x31,
     0x007C,
     0x03D1,
     0xC0},  // XK_backslash+TLDE+XK_bar+XK_Ncedilla: VKEY_OEM_3
    {0x0060,
     0x31,
     0x007E,
     0x0000,
     0xC0},  // XK_quoteleft+TLDE+XK_asciitilde+NoSymbol: VKEY_OEM_3
    {0x0060,
     0x31,
     0x007E,
     0x0031,
     0xC0},  // XK_quoteleft+TLDE+XK_asciitilde+XK_1: VKEY_OEM_3
    {0x0060,
     0x31,
     0x007E,
     0x003B,
     0xC0},  // XK_quoteleft+TLDE+XK_asciitilde+XK_semicolon: VKEY_OEM_3
    {0x0060,
     0x31,
     0x007E,
     0x0060,
     0xC0},  // XK_quoteleft+TLDE+XK_asciitilde+XK_quoteleft: VKEY_OEM_3
    {0x0060,
     0x31,
     0x007E,
     0x00BF,
     0xC0},  // XK_quoteleft+TLDE+XK_asciitilde+XK_questiondown: VKEY_OEM_3
    {0x0060,
     0x31,
     0x007E,
     0x01F5,
     0xC0},  // XK_quoteleft+TLDE+XK_asciitilde+XK_odoubleacute: VKEY_OEM_3
    {0x00E4,
     0x30,
     0x00C4,
     0x0000,
     0xDE},  // XK_adiaeresis+AC11+XK_Adiaeresis+NoSymbol: VKEY_OEM_7
    {0x00E4,
     0x30,
     0x00C4,
     0x01A6,
     0xDE},  // XK_adiaeresis+AC11+XK_Adiaeresis+XK_Sacute: VKEY_OEM_7
    {0x00E4,
     0x30,
     0x00C4,
     0x01F8,
     0xDE},  // XK_adiaeresis+AC11+XK_Adiaeresis+XK_rcaron: VKEY_OEM_7
    {0x00E7,
     0x2F,
     0x00C7,
     0x0000,
     0xBA},  // XK_ccedilla+AC10+XK_Ccedilla+NoSymbol: VKEY_OEM_1
    {0x00E7,
     0x2F,
     0x00C7,
     0x00DE,
     0xC0},  // XK_ccedilla+AC10+XK_Ccedilla+XK_Thorn: VKEY_OEM_3
    {0x00F6,
     0x2F,
     0x00D6,
     0x0000,
     0xC0},  // XK_odiaeresis+AC10+XK_Odiaeresis+NoSymbol: VKEY_OEM_3
    {0x00F6,
     0x2F,
     0x00D6,
     0x01DE,
     0xC0},  // XK_odiaeresis+AC10+XK_Odiaeresis+XK_Tcedilla: VKEY_OEM_3
    {0x00FC,
     0x14,
     0x00DC,
     0x0000,
     0xBF},  // XK_udiaeresis+AE11+XK_Udiaeresis+NoSymbol: VKEY_OEM_2
    {0x00FC,
     0x22,
     0x00DC,
     0x0000,
     0xBA},  // XK_udiaeresis+AD11+XK_Udiaeresis+NoSymbol: VKEY_OEM_1
    {0x00FC,
     0x22,
     0x00DC,
     0x01A3,
     0xC0},  // XK_udiaeresis+AD11+XK_Udiaeresis+XK_Lstroke: VKEY_OEM_3
    {0x01EA,
     0x3D,
     0x01CA,
     0x0000,
     0xBD},  // XK_eogonek+AB10+XK_Eogonek+NoSymbol: VKEY_OEM_MINUS
    {0x01EA,
     0x3D,
     0x01CA,
     0x006E,
     0xBF},  // XK_eogonek+AB10+XK_Eogonek+XK_n: VKEY_OEM_2
    {0x03E7,
     0x22,
     0x03C7,
     0x0000,
     0xDB},  // XK_iogonek+AD11+XK_Iogonek+NoSymbol: VKEY_OEM_4
    {0x03F9,
     0x2F,
     0x03D9,
     0x0000,
     0xC0},  // XK_uogonek+AC10+XK_Uogonek+NoSymbol: VKEY_OEM_3
    {0x03F9,
     0x2F,
     0x03D9,
     0x01DE,
     0xBA},  // XK_uogonek+AC10+XK_Uogonek+XK_Tcedilla: VKEY_OEM_1
};

template <class T_MAP>
KeyboardCode FindVK(const T_MAP& key, const T_MAP* map, size_t size) {
  T_MAP comp = {0};
  const T_MAP* p = std::lower_bound(map, map + size, key, comp);
  if (p != map + size && !comp(*p, key) && !comp(key, *p))
    return static_cast<KeyboardCode>(p->vk);
  return VKEY_UNKNOWN;
}

}  // namespace

// Get an ui::KeyboardCode from an X keyevent
KeyboardCode KeyboardCodeFromXKeyEvent(const XEvent* xev) {
  // Gets correct VKEY code from XEvent is performed as the following steps:
  // 1. Gets the keysym without modifier states.
  // 2. For [a-z] & [0-9] cases, returns the VKEY code accordingly.
  // 3. Find keysym in map0.
  // 4. If not found, fallback to find keysym + hardware_code in map1.
  // 5. If not found, fallback to find keysym + keysym_shift + hardware_code
  //    in map2.
  // 6. If not found, fallback to find keysym + keysym_shift + keysym_altgr +
  //    hardware_code in map3.
  // 7. If not found, fallback to find in KeyboardCodeFromXKeysym(), which
  //    mainly for non-letter keys.
  // 8. If not found, fallback to find with the hardware code in US layout.

  KeySym keysym = NoSymbol;
  XEvent xkeyevent = {0};
  if (xev->type == GenericEvent) {
    // Convert the XI2 key event into a core key event so that we can
    // continue to use XLookupString() until crbug.com/367732 is complete.
    InitXKeyEventFromXIDeviceEvent(*xev, &xkeyevent);
  } else {
    xkeyevent.xkey = xev->xkey;
  }
  KeyboardCode keycode = VKEY_UNKNOWN;
  XKeyEvent* xkey = &xkeyevent.xkey;
  // XLookupKeysym does not take into consideration the state of the lock/shift
  // etc. keys. So it is necessary to use XLookupString instead.
  XLookupString(xkey, NULL, 0, &keysym, NULL);
  if (IsKeypadKey(keysym) || IsPrivateKeypadKey(keysym) ||
      IsCursorKey(keysym) || IsPFKey(keysym) || IsFunctionKey(keysym) ||
      IsModifierKey(keysym)) {
    return KeyboardCodeFromXKeysym(keysym);
  }

  // If |xkey| has modifiers set, other than NumLock, then determine the
  // un-modified KeySym and use that to map, so that e.g. Ctrl+D correctly
  // generates VKEY_D.
  if (xkey->state & 0xFF & ~Mod2Mask) {
    xkey->state &= (~0xFF | Mod2Mask);
    XLookupString(xkey, NULL, 0, &keysym, NULL);
  }

  // [a-z] cases.
  if (keysym >= XK_a && keysym <= XK_z)
    return static_cast<KeyboardCode>(VKEY_A + keysym - XK_a);

  // [0-9] cases.
  if (keysym >= XK_0 && keysym <= XK_9)
    return static_cast<KeyboardCode>(VKEY_0 + keysym - XK_0);

  if (!IsKeypadKey(keysym) && !IsPrivateKeypadKey(keysym) &&
      !IsCursorKey(keysym) && !IsPFKey(keysym) && !IsFunctionKey(keysym) &&
      !IsModifierKey(keysym)) {
    MAP0 key0 = {keysym & 0xFFFF, 0};
    keycode = FindVK(key0, map0, arraysize(map0));
    if (keycode != VKEY_UNKNOWN)
      return keycode;

    MAP1 key1 = {keysym & 0xFFFF, xkey->keycode, 0};
    keycode = FindVK(key1, map1, arraysize(map1));
    if (keycode != VKEY_UNKNOWN)
      return keycode;

    KeySym keysym_shift = NoSymbol;
    xkey->state |= ShiftMask;
    XLookupString(xkey, NULL, 0, &keysym_shift, NULL);
    MAP2 key2 = {keysym & 0xFFFF, xkey->keycode, keysym_shift & 0xFFFF, 0};
    keycode = FindVK(key2, map2, arraysize(map2));
    if (keycode != VKEY_UNKNOWN)
      return keycode;

    KeySym keysym_altgr = NoSymbol;
    xkey->state &= ~ShiftMask;
    xkey->state |= Mod1Mask;
    XLookupString(xkey, NULL, 0, &keysym_altgr, NULL);
    MAP3 key3 = {keysym & 0xFFFF,
                 xkey->keycode,
                 keysym_shift & 0xFFFF,
                 keysym_altgr & 0xFFFF,
                 0};
    keycode = FindVK(key3, map3, arraysize(map3));
    if (keycode != VKEY_UNKNOWN)
      return keycode;

    // On Linux some keys has AltGr char but not on Windows.
    // So if cannot find VKEY with (ch0+sc+ch1+ch2) in map3, tries to fallback
    // to just find VKEY with (ch0+sc+ch1). This is the best we could do.
    MAP3 key4 = {keysym & 0xFFFF, xkey->keycode, keysym_shift & 0xFFFF, 0, 0};
    const MAP3* p =
        std::lower_bound(map3, map3 + arraysize(map3), key4, MAP3());
    if (p != map3 + arraysize(map3) && p->ch0 == key4.ch0 && p->sc == key4.sc &&
        p->ch1 == key4.ch1)
      return static_cast<KeyboardCode>(p->vk);
  }

  keycode = KeyboardCodeFromXKeysym(keysym);
  if (keycode == VKEY_UNKNOWN && !IsModifierKey(keysym)) {
    // Modifier keys should not fall back to the hardware-keycode-based US
    // layout.  See crbug.com/402320
    keycode = DefaultKeyboardCodeFromHardwareKeycode(xkey->keycode);
  }

  return keycode;
}

KeyboardCode KeyboardCodeFromXKeysym(unsigned int keysym) {
  // TODO(sad): Have |keysym| go through the X map list?

  switch (keysym) {
    case XK_BackSpace:
      return VKEY_BACK;
    case XK_Delete:
    case XK_KP_Delete:
      return VKEY_DELETE;
    case XK_Tab:
    case XK_KP_Tab:
    case XK_ISO_Left_Tab:
    case XK_3270_BackTab:
      return VKEY_TAB;
    case XK_Linefeed:
    case XK_Return:
    case XK_KP_Enter:
    case XK_ISO_Enter:
      return VKEY_RETURN;
    case XK_Clear:
    case XK_KP_Begin:  // NumPad 5 without Num Lock, for crosbug.com/29169.
      return VKEY_CLEAR;
    case XK_KP_Space:
    case XK_space:
      return VKEY_SPACE;
    case XK_Home:
    case XK_KP_Home:
      return VKEY_HOME;
    case XK_End:
    case XK_KP_End:
      return VKEY_END;
    case XK_Page_Up:
    case XK_KP_Page_Up:  // aka XK_KP_Prior
      return VKEY_PRIOR;
    case XK_Page_Down:
    case XK_KP_Page_Down:  // aka XK_KP_Next
      return VKEY_NEXT;
    case XK_Left:
    case XK_KP_Left:
      return VKEY_LEFT;
    case XK_Right:
    case XK_KP_Right:
      return VKEY_RIGHT;
    case XK_Down:
    case XK_KP_Down:
      return VKEY_DOWN;
    case XK_Up:
    case XK_KP_Up:
      return VKEY_UP;
    case XK_Escape:
      return VKEY_ESCAPE;
    case XK_Kana_Lock:
    case XK_Kana_Shift:
      return VKEY_KANA;
    case XK_Hangul:
      return VKEY_HANGUL;
    case XK_Hangul_Hanja:
      return VKEY_HANJA;
    case XK_Kanji:
      return VKEY_KANJI;
    case XK_Henkan:
      return VKEY_CONVERT;
    case XK_Muhenkan:
      return VKEY_NONCONVERT;
    case XK_Zenkaku_Hankaku:
      return VKEY_DBE_DBCSCHAR;

    case XK_KP_0:
    case XK_KP_1:
    case XK_KP_2:
    case XK_KP_3:
    case XK_KP_4:
    case XK_KP_5:
    case XK_KP_6:
    case XK_KP_7:
    case XK_KP_8:
    case XK_KP_9:
      return static_cast<KeyboardCode>(VKEY_NUMPAD0 + (keysym - XK_KP_0));

    case XK_multiply:
    case XK_KP_Multiply:
      return VKEY_MULTIPLY;
    case XK_KP_Add:
      return VKEY_ADD;
    case XK_KP_Separator:
      return VKEY_SEPARATOR;
    case XK_KP_Subtract:
      return VKEY_SUBTRACT;
    case XK_KP_Decimal:
      return VKEY_DECIMAL;
    case XK_KP_Divide:
      return VKEY_DIVIDE;
    case XK_KP_Equal:
    case XK_equal:
    case XK_plus:
      return VKEY_OEM_PLUS;
    case XK_comma:
    case XK_less:
      return VKEY_OEM_COMMA;
    case XK_minus:
    case XK_underscore:
      return VKEY_OEM_MINUS;
    case XK_greater:
    case XK_period:
      return VKEY_OEM_PERIOD;
    case XK_colon:
    case XK_semicolon:
      return VKEY_OEM_1;
    case XK_question:
    case XK_slash:
      return VKEY_OEM_2;
    case XK_asciitilde:
    case XK_quoteleft:
      return VKEY_OEM_3;
    case XK_bracketleft:
    case XK_braceleft:
      return VKEY_OEM_4;
    case XK_backslash:
    case XK_bar:
      return VKEY_OEM_5;
    case XK_bracketright:
    case XK_braceright:
      return VKEY_OEM_6;
    case XK_quoteright:
    case XK_quotedbl:
      return VKEY_OEM_7;
    case XK_ISO_Level5_Shift:
      return VKEY_OEM_8;
    case XK_Shift_L:
    case XK_Shift_R:
      return VKEY_SHIFT;
    case XK_Control_L:
    case XK_Control_R:
      return VKEY_CONTROL;
    case XK_Meta_L:
    case XK_Meta_R:
    case XK_Alt_L:
    case XK_Alt_R:
      return VKEY_MENU;
    case XK_ISO_Level3_Shift:
    case XK_Mode_switch:
      return VKEY_ALTGR;
    case XK_Multi_key:
      return VKEY_COMPOSE;
    case XK_Pause:
      return VKEY_PAUSE;
    case XK_Caps_Lock:
      return VKEY_CAPITAL;
    case XK_Num_Lock:
      return VKEY_NUMLOCK;
    case XK_Scroll_Lock:
      return VKEY_SCROLL;
    case XK_Select:
      return VKEY_SELECT;
    case XK_Print:
      return VKEY_PRINT;
    case XK_Execute:
      return VKEY_EXECUTE;
    case XK_Insert:
    case XK_KP_Insert:
      return VKEY_INSERT;
    case XK_Help:
      return VKEY_HELP;
    case XK_Super_L:
      return VKEY_LWIN;
    case XK_Super_R:
      return VKEY_RWIN;
    case XK_Menu:
      return VKEY_APPS;
    case XK_F1:
    case XK_F2:
    case XK_F3:
    case XK_F4:
    case XK_F5:
    case XK_F6:
    case XK_F7:
    case XK_F8:
    case XK_F9:
    case XK_F10:
    case XK_F11:
    case XK_F12:
    case XK_F13:
    case XK_F14:
    case XK_F15:
    case XK_F16:
    case XK_F17:
    case XK_F18:
    case XK_F19:
    case XK_F20:
    case XK_F21:
    case XK_F22:
    case XK_F23:
    case XK_F24:
      return static_cast<KeyboardCode>(VKEY_F1 + (keysym - XK_F1));
    case XK_KP_F1:
    case XK_KP_F2:
    case XK_KP_F3:
    case XK_KP_F4:
      return static_cast<KeyboardCode>(VKEY_F1 + (keysym - XK_KP_F1));

    case XK_guillemotleft:
    case XK_guillemotright:
    case XK_degree:
    // In the case of canadian multilingual keyboard layout, VKEY_OEM_102 is
    // assigned to ugrave key.
    case XK_ugrave:
    case XK_Ugrave:
    case XK_brokenbar:
      return VKEY_OEM_102;  // international backslash key in 102 keyboard.

    // When evdev is in use, /usr/share/X11/xkb/symbols/inet maps F13-18 keys
    // to the special XF86XK symbols to support Microsoft Ergonomic keyboards:
    // https://bugs.freedesktop.org/show_bug.cgi?id=5783
    // In Chrome, we map these X key symbols back to F13-18 since we don't have
    // VKEYs for these XF86XK symbols.
    case XF86XK_Tools:
      return VKEY_F13;
    case XF86XK_Launch5:
      return VKEY_F14;
    case XF86XK_Launch6:
      return VKEY_F15;
    case XF86XK_Launch7:
      return VKEY_F16;
    case XF86XK_Launch8:
      return VKEY_F17;
    case XF86XK_Launch9:
      return VKEY_F18;

    // For supporting multimedia buttons on a USB keyboard.
    case XF86XK_Back:
      return VKEY_BROWSER_BACK;
    case XF86XK_Forward:
      return VKEY_BROWSER_FORWARD;
    case XF86XK_Reload:
      return VKEY_BROWSER_REFRESH;
    case XF86XK_Stop:
      return VKEY_BROWSER_STOP;
    case XF86XK_Search:
      return VKEY_BROWSER_SEARCH;
    case XF86XK_Favorites:
      return VKEY_BROWSER_FAVORITES;
    case XF86XK_HomePage:
      return VKEY_BROWSER_HOME;
    case XF86XK_AudioMute:
      return VKEY_VOLUME_MUTE;
    case XF86XK_AudioLowerVolume:
      return VKEY_VOLUME_DOWN;
    case XF86XK_AudioRaiseVolume:
      return VKEY_VOLUME_UP;
    case XF86XK_AudioNext:
      return VKEY_MEDIA_NEXT_TRACK;
    case XF86XK_AudioPrev:
      return VKEY_MEDIA_PREV_TRACK;
    case XF86XK_AudioStop:
      return VKEY_MEDIA_STOP;
    case XF86XK_AudioPlay:
      return VKEY_MEDIA_PLAY_PAUSE;
    case XF86XK_Mail:
      return VKEY_MEDIA_LAUNCH_MAIL;
    case XF86XK_LaunchA:  // F3 on an Apple keyboard.
      return VKEY_MEDIA_LAUNCH_APP1;
    case XF86XK_LaunchB:  // F4 on an Apple keyboard.
    case XF86XK_Calculator:
      return VKEY_MEDIA_LAUNCH_APP2;
    case XF86XK_WLAN:
      return VKEY_WLAN;
    case XF86XK_PowerOff:
      return VKEY_POWER;
    case XF86XK_Sleep:
      return VKEY_SLEEP;
    case XF86XK_MonBrightnessDown:
      return VKEY_BRIGHTNESS_DOWN;
    case XF86XK_MonBrightnessUp:
      return VKEY_BRIGHTNESS_UP;
    case XF86XK_KbdBrightnessDown:
      return VKEY_KBD_BRIGHTNESS_DOWN;
    case XF86XK_KbdBrightnessUp:
      return VKEY_KBD_BRIGHTNESS_UP;

      // TODO(sad): some keycodes are still missing.
  }
  DVLOG(1) << "Unknown keysym: " << base::StringPrintf("0x%x", keysym);
  return VKEY_UNKNOWN;
}

const char* CodeFromXEvent(const XEvent* xev) {
  int keycode = (xev->type == GenericEvent)
                    ? static_cast<XIDeviceEvent*>(xev->xcookie.data)->detail
                    : xev->xkey.keycode;
  return ui::KeycodeConverter::NativeKeycodeToCode(keycode);
}

uint16 GetCharacterFromXEvent(const XEvent* xev) {
  XEvent xkeyevent = {0};
  const XKeyEvent* xkey = NULL;
  if (xev->type == GenericEvent) {
    // Convert the XI2 key event into a core key event so that we can
    // continue to use XLookupString() until crbug.com/367732 is complete.
    InitXKeyEventFromXIDeviceEvent(*xev, &xkeyevent);
    xkey = &xkeyevent.xkey;
  } else {
    xkey = &xev->xkey;
  }
  KeySym keysym = XK_VoidSymbol;
  XLookupString(const_cast<XKeyEvent*>(xkey), NULL, 0, &keysym, NULL);
  return GetUnicodeCharacterFromXKeySym(keysym);
}

KeyboardCode DefaultKeyboardCodeFromHardwareKeycode(
    unsigned int hardware_code) {
  // This function assumes that X11 is using evdev-based keycodes.
  static const KeyboardCode kHardwareKeycodeMap[] = {
      // Please refer to below links for the table content:
      // http://www.w3.org/TR/DOM-Level-3-Events-code/#keyboard-101
      // https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent.keyCode
      // http://download.microsoft.com/download/1/6/1/161ba512-40e2-4cc9-843a-923143f3456c/translate.pdf
      VKEY_UNKNOWN,       // 0x00:
      VKEY_UNKNOWN,       // 0x01:
      VKEY_UNKNOWN,       // 0x02:
      VKEY_UNKNOWN,       // 0x03:
      VKEY_UNKNOWN,       // 0x04:
      VKEY_UNKNOWN,       // 0x05:
      VKEY_UNKNOWN,       // 0x06:
      VKEY_UNKNOWN,       // XKB   evdev (XKB - 8)      X KeySym
      VKEY_UNKNOWN,       // ===   ===============      ======
      VKEY_ESCAPE,        // 0x09: KEY_ESC              Escape
      VKEY_1,             // 0x0A: KEY_1                1
      VKEY_2,             // 0x0B: KEY_2                2
      VKEY_3,             // 0x0C: KEY_3                3
      VKEY_4,             // 0x0D: KEY_4                4
      VKEY_5,             // 0x0E: KEY_5                5
      VKEY_6,             // 0x0F: KEY_6                6
      VKEY_7,             // 0x10: KEY_7                7
      VKEY_8,             // 0x11: KEY_8                8
      VKEY_9,             // 0x12: KEY_9                9
      VKEY_0,             // 0x13: KEY_0                0
      VKEY_OEM_MINUS,     // 0x14: KEY_MINUS            minus
      VKEY_OEM_PLUS,      // 0x15: KEY_EQUAL            equal
      VKEY_BACK,          // 0x16: KEY_BACKSPACE        BackSpace
      VKEY_TAB,           // 0x17: KEY_TAB              Tab
      VKEY_Q,             // 0x18: KEY_Q                q
      VKEY_W,             // 0x19: KEY_W                w
      VKEY_E,             // 0x1A: KEY_E                e
      VKEY_R,             // 0x1B: KEY_R                r
      VKEY_T,             // 0x1C: KEY_T                t
      VKEY_Y,             // 0x1D: KEY_Y                y
      VKEY_U,             // 0x1E: KEY_U                u
      VKEY_I,             // 0x1F: KEY_I                i
      VKEY_O,             // 0x20: KEY_O                o
      VKEY_P,             // 0x21: KEY_P                p
      VKEY_OEM_4,         // 0x22: KEY_LEFTBRACE        bracketleft
      VKEY_OEM_6,         // 0x23: KEY_RIGHTBRACE       bracketright
      VKEY_RETURN,        // 0x24: KEY_ENTER            Return
      VKEY_LCONTROL,      // 0x25: KEY_LEFTCTRL         Control_L
      VKEY_A,             // 0x26: KEY_A                a
      VKEY_S,             // 0x27: KEY_S                s
      VKEY_D,             // 0x28: KEY_D                d
      VKEY_F,             // 0x29: KEY_F                f
      VKEY_G,             // 0x2A: KEY_G                g
      VKEY_H,             // 0x2B: KEY_H                h
      VKEY_J,             // 0x2C: KEY_J                j
      VKEY_K,             // 0x2D: KEY_K                k
      VKEY_L,             // 0x2E: KEY_L                l
      VKEY_OEM_1,         // 0x2F: KEY_SEMICOLON        semicolon
      VKEY_OEM_7,         // 0x30: KEY_APOSTROPHE       apostrophe
      VKEY_OEM_3,         // 0x31: KEY_GRAVE            grave
      VKEY_LSHIFT,        // 0x32: KEY_LEFTSHIFT        Shift_L
      VKEY_OEM_5,         // 0x33: KEY_BACKSLASH        backslash
      VKEY_Z,             // 0x34: KEY_Z                z
      VKEY_X,             // 0x35: KEY_X                x
      VKEY_C,             // 0x36: KEY_C                c
      VKEY_V,             // 0x37: KEY_V                v
      VKEY_B,             // 0x38: KEY_B                b
      VKEY_N,             // 0x39: KEY_N                n
      VKEY_M,             // 0x3A: KEY_M                m
      VKEY_OEM_COMMA,     // 0x3B: KEY_COMMA            comma
      VKEY_OEM_PERIOD,    // 0x3C: KEY_DOT              period
      VKEY_OEM_2,         // 0x3D: KEY_SLASH            slash
      VKEY_RSHIFT,        // 0x3E: KEY_RIGHTSHIFT       Shift_R
      VKEY_MULTIPLY,      // 0x3F: KEY_KPASTERISK       KP_Multiply
      VKEY_LMENU,         // 0x40: KEY_LEFTALT          Alt_L
      VKEY_SPACE,         // 0x41: KEY_SPACE            space
      VKEY_CAPITAL,       // 0x42: KEY_CAPSLOCK         Caps_Lock
      VKEY_F1,            // 0x43: KEY_F1               F1
      VKEY_F2,            // 0x44: KEY_F2               F2
      VKEY_F3,            // 0x45: KEY_F3               F3
      VKEY_F4,            // 0x46: KEY_F4               F4
      VKEY_F5,            // 0x47: KEY_F5               F5
      VKEY_F6,            // 0x48: KEY_F6               F6
      VKEY_F7,            // 0x49: KEY_F7               F7
      VKEY_F8,            // 0x4A: KEY_F8               F8
      VKEY_F9,            // 0x4B: KEY_F9               F9
      VKEY_F10,           // 0x4C: KEY_F10              F10
      VKEY_NUMLOCK,       // 0x4D: KEY_NUMLOCK          Num_Lock
      VKEY_SCROLL,        // 0x4E: KEY_SCROLLLOCK       Scroll_Lock
      VKEY_NUMPAD7,       // 0x4F: KEY_KP7              KP_7
      VKEY_NUMPAD8,       // 0x50: KEY_KP8              KP_8
      VKEY_NUMPAD9,       // 0x51: KEY_KP9              KP_9
      VKEY_SUBTRACT,      // 0x52: KEY_KPMINUS          KP_Subtract
      VKEY_NUMPAD4,       // 0x53: KEY_KP4              KP_4
      VKEY_NUMPAD5,       // 0x54: KEY_KP5              KP_5
      VKEY_NUMPAD6,       // 0x55: KEY_KP6              KP_6
      VKEY_ADD,           // 0x56: KEY_KPPLUS           KP_Add
      VKEY_NUMPAD1,       // 0x57: KEY_KP1              KP_1
      VKEY_NUMPAD2,       // 0x58: KEY_KP2              KP_2
      VKEY_NUMPAD3,       // 0x59: KEY_KP3              KP_3
      VKEY_NUMPAD0,       // 0x5A: KEY_KP0              KP_0
      VKEY_DECIMAL,       // 0x5B: KEY_KPDOT            KP_Decimal
      VKEY_UNKNOWN,       // 0x5C:
      VKEY_DBE_DBCSCHAR,  // 0x5D: KEY_ZENKAKUHANKAKU   Zenkaku_Hankaku
      VKEY_OEM_5,         // 0x5E: KEY_102ND            backslash
      VKEY_F11,           // 0x5F: KEY_F11              F11
      VKEY_F12,           // 0x60: KEY_F12              F12
      VKEY_OEM_102,       // 0x61: KEY_RO               Romaji
      VKEY_UNSUPPORTED,   // 0x62: KEY_KATAKANA         Katakana
      VKEY_UNSUPPORTED,   // 0x63: KEY_HIRAGANA         Hiragana
      VKEY_CONVERT,       // 0x64: KEY_HENKAN           Henkan
      VKEY_UNSUPPORTED,   // 0x65: KEY_KATAKANAHIRAGANA Hiragana_Katakana
      VKEY_NONCONVERT,    // 0x66: KEY_MUHENKAN         Muhenkan
      VKEY_SEPARATOR,     // 0x67: KEY_KPJPCOMMA        KP_Separator
      VKEY_RETURN,        // 0x68: KEY_KPENTER          KP_Enter
      VKEY_RCONTROL,      // 0x69: KEY_RIGHTCTRL        Control_R
      VKEY_DIVIDE,        // 0x6A: KEY_KPSLASH          KP_Divide
      VKEY_PRINT,         // 0x6B: KEY_SYSRQ            Print
      VKEY_RMENU,         // 0x6C: KEY_RIGHTALT         Alt_R
      VKEY_RETURN,        // 0x6D: KEY_LINEFEED         Linefeed
      VKEY_HOME,          // 0x6E: KEY_HOME             Home
      VKEY_UP,            // 0x6F: KEY_UP               Up
      VKEY_PRIOR,         // 0x70: KEY_PAGEUP           Page_Up
      VKEY_LEFT,          // 0x71: KEY_LEFT             Left
      VKEY_RIGHT,         // 0x72: KEY_RIGHT            Right
      VKEY_END,           // 0x73: KEY_END              End
      VKEY_DOWN,          // 0x74: KEY_DOWN             Down
      VKEY_NEXT,          // 0x75: KEY_PAGEDOWN         Page_Down
      VKEY_INSERT,        // 0x76: KEY_INSERT           Insert
      VKEY_DELETE,        // 0x77: KEY_DELETE           Delete
      VKEY_UNSUPPORTED,   // 0x78: KEY_MACRO
      VKEY_VOLUME_MUTE,   // 0x79: KEY_MUTE             XF86AudioMute
      VKEY_VOLUME_DOWN,   // 0x7A: KEY_VOLUMEDOWN       XF86AudioLowerVolume
      VKEY_VOLUME_UP,     // 0x7B: KEY_VOLUMEUP         XF86AudioRaiseVolume
      VKEY_POWER,         // 0x7C: KEY_POWER            XF86PowerOff
      VKEY_OEM_PLUS,      // 0x7D: KEY_KPEQUAL          KP_Equal
      VKEY_UNSUPPORTED,   // 0x7E: KEY_KPPLUSMINUS      plusminus
      VKEY_PAUSE,         // 0x7F: KEY_PAUSE            Pause
      VKEY_MEDIA_LAUNCH_APP1,  // 0x80: KEY_SCALE            XF86LaunchA
      VKEY_DECIMAL,            // 0x81: KEY_KPCOMMA          KP_Decimal
      VKEY_HANGUL,             // 0x82: KEY_HANGUEL          Hangul
      VKEY_HANJA,              // 0x83: KEY_HANJA            Hangul_Hanja
      VKEY_OEM_5,              // 0x84: KEY_YEN              yen
      VKEY_LWIN,               // 0x85: KEY_LEFTMETA         Super_L
      VKEY_RWIN,               // 0x86: KEY_RIGHTMETA        Super_R
      VKEY_COMPOSE,            // 0x87: KEY_COMPOSE          Menu
  };

  if (hardware_code >= arraysize(kHardwareKeycodeMap)) {
    // Additional keycodes used by the Chrome OS top row special function keys.
    switch (hardware_code) {
      case 0xA6:  // KEY_BACK
        return VKEY_BACK;
      case 0xA7:  // KEY_FORWARD
        return VKEY_BROWSER_FORWARD;
      case 0xB5:  // KEY_REFRESH
        return VKEY_BROWSER_REFRESH;
      case 0xD4:  // KEY_DASHBOARD
        return VKEY_MEDIA_LAUNCH_APP2;
      case 0xE8:  // KEY_BRIGHTNESSDOWN
        return VKEY_BRIGHTNESS_DOWN;
      case 0xE9:  // KEY_BRIGHTNESSUP
        return VKEY_BRIGHTNESS_UP;
    }
    return VKEY_UNKNOWN;
  }
  return kHardwareKeycodeMap[hardware_code];
}

// TODO(jcampan): this method might be incomplete.
int XKeysymForWindowsKeyCode(KeyboardCode keycode, bool shift) {
  switch (keycode) {
    case VKEY_NUMPAD0:
      return XK_KP_0;
    case VKEY_NUMPAD1:
      return XK_KP_1;
    case VKEY_NUMPAD2:
      return XK_KP_2;
    case VKEY_NUMPAD3:
      return XK_KP_3;
    case VKEY_NUMPAD4:
      return XK_KP_4;
    case VKEY_NUMPAD5:
      return XK_KP_5;
    case VKEY_NUMPAD6:
      return XK_KP_6;
    case VKEY_NUMPAD7:
      return XK_KP_7;
    case VKEY_NUMPAD8:
      return XK_KP_8;
    case VKEY_NUMPAD9:
      return XK_KP_9;
    case VKEY_MULTIPLY:
      return XK_KP_Multiply;
    case VKEY_ADD:
      return XK_KP_Add;
    case VKEY_SUBTRACT:
      return XK_KP_Subtract;
    case VKEY_DECIMAL:
      return XK_KP_Decimal;
    case VKEY_DIVIDE:
      return XK_KP_Divide;

    case VKEY_BACK:
      return XK_BackSpace;
    case VKEY_TAB:
      return shift ? XK_ISO_Left_Tab : XK_Tab;
    case VKEY_CLEAR:
      return XK_Clear;
    case VKEY_RETURN:
      return XK_Return;
    case VKEY_SHIFT:
      return XK_Shift_L;
    case VKEY_CONTROL:
      return XK_Control_L;
    case VKEY_MENU:
      return XK_Alt_L;
    case VKEY_APPS:
      return XK_Menu;
    case VKEY_ALTGR:
      return XK_ISO_Level3_Shift;
    case VKEY_COMPOSE:
      return XK_Multi_key;

    case VKEY_PAUSE:
      return XK_Pause;
    case VKEY_CAPITAL:
      return XK_Caps_Lock;
    case VKEY_KANA:
      return XK_Kana_Lock;
    case VKEY_HANJA:
      return XK_Hangul_Hanja;
    case VKEY_CONVERT:
      return XK_Henkan;
    case VKEY_NONCONVERT:
      return XK_Muhenkan;
    case VKEY_DBE_SBCSCHAR:
      return XK_Zenkaku_Hankaku;
    case VKEY_DBE_DBCSCHAR:
      return XK_Zenkaku_Hankaku;
    case VKEY_ESCAPE:
      return XK_Escape;
    case VKEY_SPACE:
      return XK_space;
    case VKEY_PRIOR:
      return XK_Page_Up;
    case VKEY_NEXT:
      return XK_Page_Down;
    case VKEY_END:
      return XK_End;
    case VKEY_HOME:
      return XK_Home;
    case VKEY_LEFT:
      return XK_Left;
    case VKEY_UP:
      return XK_Up;
    case VKEY_RIGHT:
      return XK_Right;
    case VKEY_DOWN:
      return XK_Down;
    case VKEY_SELECT:
      return XK_Select;
    case VKEY_PRINT:
      return XK_Print;
    case VKEY_EXECUTE:
      return XK_Execute;
    case VKEY_INSERT:
      return XK_Insert;
    case VKEY_DELETE:
      return XK_Delete;
    case VKEY_HELP:
      return XK_Help;
    case VKEY_0:
      return shift ? XK_parenright : XK_0;
    case VKEY_1:
      return shift ? XK_exclam : XK_1;
    case VKEY_2:
      return shift ? XK_at : XK_2;
    case VKEY_3:
      return shift ? XK_numbersign : XK_3;
    case VKEY_4:
      return shift ? XK_dollar : XK_4;
    case VKEY_5:
      return shift ? XK_percent : XK_5;
    case VKEY_6:
      return shift ? XK_asciicircum : XK_6;
    case VKEY_7:
      return shift ? XK_ampersand : XK_7;
    case VKEY_8:
      return shift ? XK_asterisk : XK_8;
    case VKEY_9:
      return shift ? XK_parenleft : XK_9;

    case VKEY_A:
    case VKEY_B:
    case VKEY_C:
    case VKEY_D:
    case VKEY_E:
    case VKEY_F:
    case VKEY_G:
    case VKEY_H:
    case VKEY_I:
    case VKEY_J:
    case VKEY_K:
    case VKEY_L:
    case VKEY_M:
    case VKEY_N:
    case VKEY_O:
    case VKEY_P:
    case VKEY_Q:
    case VKEY_R:
    case VKEY_S:
    case VKEY_T:
    case VKEY_U:
    case VKEY_V:
    case VKEY_W:
    case VKEY_X:
    case VKEY_Y:
    case VKEY_Z:
      return (shift ? XK_A : XK_a) + (keycode - VKEY_A);

    case VKEY_LWIN:
      return XK_Super_L;
    case VKEY_RWIN:
      return XK_Super_R;

    case VKEY_NUMLOCK:
      return XK_Num_Lock;

    case VKEY_SCROLL:
      return XK_Scroll_Lock;

    case VKEY_OEM_1:
      return shift ? XK_colon : XK_semicolon;
    case VKEY_OEM_PLUS:
      return shift ? XK_plus : XK_equal;
    case VKEY_OEM_COMMA:
      return shift ? XK_less : XK_comma;
    case VKEY_OEM_MINUS:
      return shift ? XK_underscore : XK_minus;
    case VKEY_OEM_PERIOD:
      return shift ? XK_greater : XK_period;
    case VKEY_OEM_2:
      return shift ? XK_question : XK_slash;
    case VKEY_OEM_3:
      return shift ? XK_asciitilde : XK_quoteleft;
    case VKEY_OEM_4:
      return shift ? XK_braceleft : XK_bracketleft;
    case VKEY_OEM_5:
      return shift ? XK_bar : XK_backslash;
    case VKEY_OEM_6:
      return shift ? XK_braceright : XK_bracketright;
    case VKEY_OEM_7:
      return shift ? XK_quotedbl : XK_quoteright;
    case VKEY_OEM_8:
      return XK_ISO_Level5_Shift;
    case VKEY_OEM_102:
      return shift ? XK_guillemotleft : XK_guillemotright;

    case VKEY_F1:
    case VKEY_F2:
    case VKEY_F3:
    case VKEY_F4:
    case VKEY_F5:
    case VKEY_F6:
    case VKEY_F7:
    case VKEY_F8:
    case VKEY_F9:
    case VKEY_F10:
    case VKEY_F11:
    case VKEY_F12:
    case VKEY_F13:
    case VKEY_F14:
    case VKEY_F15:
    case VKEY_F16:
    case VKEY_F17:
    case VKEY_F18:
    case VKEY_F19:
    case VKEY_F20:
    case VKEY_F21:
    case VKEY_F22:
    case VKEY_F23:
    case VKEY_F24:
      return XK_F1 + (keycode - VKEY_F1);

    case VKEY_BROWSER_BACK:
      return XF86XK_Back;
    case VKEY_BROWSER_FORWARD:
      return XF86XK_Forward;
    case VKEY_BROWSER_REFRESH:
      return XF86XK_Reload;
    case VKEY_BROWSER_STOP:
      return XF86XK_Stop;
    case VKEY_BROWSER_SEARCH:
      return XF86XK_Search;
    case VKEY_BROWSER_FAVORITES:
      return XF86XK_Favorites;
    case VKEY_BROWSER_HOME:
      return XF86XK_HomePage;
    case VKEY_VOLUME_MUTE:
      return XF86XK_AudioMute;
    case VKEY_VOLUME_DOWN:
      return XF86XK_AudioLowerVolume;
    case VKEY_VOLUME_UP:
      return XF86XK_AudioRaiseVolume;
    case VKEY_MEDIA_NEXT_TRACK:
      return XF86XK_AudioNext;
    case VKEY_MEDIA_PREV_TRACK:
      return XF86XK_AudioPrev;
    case VKEY_MEDIA_STOP:
      return XF86XK_AudioStop;
    case VKEY_MEDIA_PLAY_PAUSE:
      return XF86XK_AudioPlay;
    case VKEY_MEDIA_LAUNCH_MAIL:
      return XF86XK_Mail;
    case VKEY_MEDIA_LAUNCH_APP1:
      return XF86XK_LaunchA;
    case VKEY_MEDIA_LAUNCH_APP2:
      return XF86XK_LaunchB;
    case VKEY_WLAN:
      return XF86XK_WLAN;
    case VKEY_POWER:
      return XF86XK_PowerOff;
    case VKEY_BRIGHTNESS_DOWN:
      return XF86XK_MonBrightnessDown;
    case VKEY_BRIGHTNESS_UP:
      return XF86XK_MonBrightnessUp;
    case VKEY_KBD_BRIGHTNESS_DOWN:
      return XF86XK_KbdBrightnessDown;
    case VKEY_KBD_BRIGHTNESS_UP:
      return XF86XK_KbdBrightnessUp;

    default:
      LOG(WARNING) << "Unknown keycode:" << keycode;
      return 0;
  }
}

void InitXKeyEventFromXIDeviceEvent(const XEvent& src, XEvent* xkeyevent) {
  DCHECK(src.type == GenericEvent);
  XIDeviceEvent* xievent = static_cast<XIDeviceEvent*>(src.xcookie.data);
  switch (xievent->evtype) {
    case XI_KeyPress:
      xkeyevent->type = KeyPress;
      break;
    case XI_KeyRelease:
      xkeyevent->type = KeyRelease;
      break;
    default:
      NOTREACHED();
  }
  xkeyevent->xkey.serial = xievent->serial;
  xkeyevent->xkey.send_event = xievent->send_event;
  xkeyevent->xkey.display = xievent->display;
  xkeyevent->xkey.window = xievent->event;
  xkeyevent->xkey.root = xievent->root;
  xkeyevent->xkey.subwindow = xievent->child;
  xkeyevent->xkey.time = xievent->time;
  xkeyevent->xkey.x = xievent->event_x;
  xkeyevent->xkey.y = xievent->event_y;
  xkeyevent->xkey.x_root = xievent->root_x;
  xkeyevent->xkey.y_root = xievent->root_y;
  xkeyevent->xkey.state = xievent->mods.effective;
  xkeyevent->xkey.keycode = xievent->detail;
  xkeyevent->xkey.same_screen = 1;
}

unsigned int XKeyCodeForWindowsKeyCode(ui::KeyboardCode key_code,
                                       int flags,
                                       XDisplay* display) {
  // SHIFT state is ignored in the call to XKeysymForWindowsKeyCode() here
  // because we map the XKeysym back to a keycode, i.e. a physical key position.
  // Using a SHIFT-modified XKeysym would sometimes yield X keycodes that,
  // while technically valid, may be surprising in that they do not match
  // the keycode of the original press, and conflict with assumptions in
  // other code.
  //
  // For example, in a US layout, Shift-9 has the interpretation XK_parenleft,
  // but the keycode KEY_9 alone does not map to XK_parenleft; instead,
  // XKeysymToKeycode() returns KEY_KPLEFTPAREN (keypad left parenthesis)
  // which does map to XK_parenleft -- notwithstanding that keyboards with
  // dedicated number pad parenthesis keys are currently uncommon.
  //
  // Similarly, Shift-Comma has the interpretation XK_less, but KEY_COMMA
  // alone does not map to XK_less; XKeysymToKeycode() returns KEY_102ND
  // (the '<>' key between Shift and Z on 105-key keyboards) which does.
  //
  // crbug.com/386066 and crbug.com/390263 are examples of problems
  // associated with this.
  //
  return XKeysymToKeycode(display, XKeysymForWindowsKeyCode(key_code, false));
}

}  // namespace ui
