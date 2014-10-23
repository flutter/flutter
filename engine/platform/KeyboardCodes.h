/*
 * Copyright (c) 2008, 2009, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef KeyboardCodes_h
#define KeyboardCodes_h

#include "platform/WindowsKeyboardCodes.h"

namespace blink {

enum {
    // VKEY_LBUTTON (01) Left mouse button
    // VKEY_RBUTTON (02) Right mouse button
    // VKEY_CANCEL (03) Control-break processing
    // VKEY_MBUTTON (04) Middle mouse button (three-button mouse)
    // VKEY_XBUTTON1 (05)
    // VKEY_XBUTTON2 (06)

    // VKEY_BACK (08) BACKSPACE key
    VKEY_BACK = VK_BACK,

    // VKEY_TAB (09) TAB key
    VKEY_TAB = VK_TAB,

    // VKEY_CLEAR (0C) CLEAR key
    VKEY_CLEAR = VK_CLEAR,

    // VKEY_RETURN (0D)
    VKEY_RETURN = VK_RETURN,

    // VKEY_SHIFT (10) SHIFT key
    VKEY_SHIFT = VK_SHIFT,

    // VKEY_CONTROL (11) CTRL key
    VKEY_CONTROL = VK_CONTROL,

    // VKEY_MENU (12) ALT key
    VKEY_MENU = VK_MENU,

    // VKEY_PAUSE (13) PAUSE key
    VKEY_PAUSE = VK_PAUSE,

    // VKEY_CAPITAL (14) CAPS LOCK key
    VKEY_CAPITAL = VK_CAPITAL,

    // VKEY_KANA (15) Input Method Editor (IME) Kana mode
    VKEY_KANA = VK_KANA,

    // VKEY_HANGUEL (15) IME Hanguel mode (maintained for compatibility, use VKEY_HANGUL)
    // VKEY_HANGUL (15) IME Hangul mode
    VKEY_HANGUL = VK_HANGUL,

    // VKEY_JUNJA (17) IME Junja mode
    VKEY_JUNJA = VK_JUNJA,

    // VKEY_FINAL (18) IME final mode
    VKEY_FINAL = VK_FINAL,

    // VKEY_HANJA (19) IME Hanja mode
    VKEY_HANJA = VK_HANJA,

    // VKEY_KANJI (19) IME Kanji mode
    VKEY_KANJI = VK_KANJI,

    // VKEY_ESCAPE (1B) ESC key
    VKEY_ESCAPE = VK_ESCAPE,

    // VKEY_CONVERT (1C) IME convert
    VKEY_CONVERT = VK_CONVERT,

    // VKEY_NONCONVERT (1D) IME nonconvert
    VKEY_NONCONVERT = VK_NONCONVERT,

    // VKEY_ACCEPT (1E) IME accept
    VKEY_ACCEPT = VK_ACCEPT,

    // VKEY_MODECHANGE (1F) IME mode change request
    VKEY_MODECHANGE = VK_MODECHANGE,

    // VKEY_SPACE (20) SPACEBAR
    VKEY_SPACE = VK_SPACE,

    // VKEY_PRIOR (21) PAGE UP key
    VKEY_PRIOR = VK_PRIOR,

    // VKEY_NEXT (22) PAGE DOWN key
    VKEY_NEXT = VK_NEXT,

    // VKEY_END (23) END key
    VKEY_END = VK_END,

    // VKEY_HOME (24) HOME key
    VKEY_HOME = VK_HOME,

    // VKEY_LEFT (25) LEFT ARROW key
    VKEY_LEFT = VK_LEFT,

    // VKEY_UP (26) UP ARROW key
    VKEY_UP = VK_UP,

    // VKEY_RIGHT (27) RIGHT ARROW key
    VKEY_RIGHT = VK_RIGHT,

    // VKEY_DOWN (28) DOWN ARROW key
    VKEY_DOWN = VK_DOWN,

    // VKEY_SELECT (29) SELECT key
    VKEY_SELECT = VK_SELECT,

    // VKEY_PRINT (2A) PRINT key
    VKEY_PRINT = VK_PRINT,

    // VKEY_EXECUTE (2B) EXECUTE key
    VKEY_EXECUTE = VK_EXECUTE,

    // VKEY_SNAPSHOT (2C) PRINT SCREEN key
    VKEY_SNAPSHOT = VK_SNAPSHOT,

    // VKEY_INSERT (2D) INS key
    VKEY_INSERT = VK_INSERT,

    // VKEY_DELETE (2E) DEL key
    VKEY_DELETE = VK_DELETE,

    // VKEY_HELP (2F) HELP key
    VKEY_HELP = VK_HELP,

    // (30) 0 key
    VKEY_0 = '0',

    // (31) 1 key
    VKEY_1 = '1',

    // (32) 2 key
    VKEY_2 = '2',

    // (33) 3 key
    VKEY_3 = '3',

    // (34) 4 key
    VKEY_4 = '4',

    // (35) 5 key,

    VKEY_5 = '5',

    // (36) 6 key
    VKEY_6 = '6',

    // (37) 7 key
    VKEY_7 = '7',

    // (38) 8 key
    VKEY_8 = '8',

    // (39) 9 key
    VKEY_9 = '9',

    // (41) A key
    VKEY_A = 'A',

    // (42) B key
    VKEY_B = 'B',

    // (43) C key
    VKEY_C = 'C',

    // (44) D key
    VKEY_D = 'D',

    // (45) E key
    VKEY_E = 'E',

    // (46) F key
    VKEY_F = 'F',

    // (47) G key
    VKEY_G = 'G',

    // (48) H key
    VKEY_H = 'H',

    // (49) I key
    VKEY_I = 'I',

    // (4A) J key
    VKEY_J = 'J',

    // (4B) K key
    VKEY_K = 'K',

    // (4C) L key
    VKEY_L = 'L',

    // (4D) M key
    VKEY_M = 'M',

    // (4E) N key
    VKEY_N = 'N',

    // (4F) O key
    VKEY_O = 'O',

    // (50) P key
    VKEY_P = 'P',

    // (51) Q key
    VKEY_Q = 'Q',

    // (52) R key
    VKEY_R = 'R',

    // (53) S key
    VKEY_S = 'S',

    // (54) T key
    VKEY_T = 'T',

    // (55) U key
    VKEY_U = 'U',

    // (56) V key
    VKEY_V = 'V',

    // (57) W key
    VKEY_W = 'W',

    // (58) X key
    VKEY_X = 'X',

    // (59) Y key
    VKEY_Y = 'Y',

    // (5A) Z key
    VKEY_Z = 'Z',

    // VKEY_LWIN (5B) Left Windows key (Microsoft Natural keyboard)
    VKEY_LWIN = VK_LWIN,

    // VKEY_RWIN (5C) Right Windows key (Natural keyboard)
    VKEY_RWIN = VK_RWIN,

    // VKEY_APPS (5D) Applications key (Natural keyboard)
    VKEY_APPS = VK_APPS,

    // VKEY_SLEEP (5F) Computer Sleep key
    VKEY_SLEEP = VK_SLEEP,

    // VKEY_NUMPAD0 (60) Numeric keypad 0 key
    VKEY_NUMPAD0 = VK_NUMPAD0,

    // VKEY_NUMPAD1 (61) Numeric keypad 1 key
    VKEY_NUMPAD1 = VK_NUMPAD1,

    // VKEY_NUMPAD2 (62) Numeric keypad 2 key
    VKEY_NUMPAD2 = VK_NUMPAD2,

    // VKEY_NUMPAD3 (63) Numeric keypad 3 key
    VKEY_NUMPAD3 = VK_NUMPAD3,

    // VKEY_NUMPAD4 (64) Numeric keypad 4 key
    VKEY_NUMPAD4 = VK_NUMPAD4,

    // VKEY_NUMPAD5 (65) Numeric keypad 5 key
    VKEY_NUMPAD5 = VK_NUMPAD5,

    // VKEY_NUMPAD6 (66) Numeric keypad 6 key
    VKEY_NUMPAD6 = VK_NUMPAD6,

    // VKEY_NUMPAD7 (67) Numeric keypad 7 key
    VKEY_NUMPAD7 = VK_NUMPAD7,

    // VKEY_NUMPAD8 (68) Numeric keypad 8 key
    VKEY_NUMPAD8 = VK_NUMPAD8,

    // VKEY_NUMPAD9 (69) Numeric keypad 9 key
    VKEY_NUMPAD9 = VK_NUMPAD9,

    // VKEY_MULTIPLY (6A) Multiply key
    VKEY_MULTIPLY = VK_MULTIPLY,

    // VKEY_ADD (6B) Add key
    VKEY_ADD = VK_ADD,

    // VKEY_SEPARATOR (6C) Separator key
    VKEY_SEPARATOR = VK_SEPARATOR,

    // VKEY_SUBTRACT (6D) Subtract key
    VKEY_SUBTRACT = VK_SUBTRACT,

    // VKEY_DECIMAL (6E) Decimal key
    VKEY_DECIMAL = VK_DECIMAL,

    // VKEY_DIVIDE (6F) Divide key
    VKEY_DIVIDE = VK_DIVIDE,

    // VKEY_F1 (70) F1 key
    VKEY_F1 = VK_F1,

    // VKEY_F2 (71) F2 key
    VKEY_F2 = VK_F2,

    // VKEY_F3 (72) F3 key
    VKEY_F3 = VK_F3,

    // VKEY_F4 (73) F4 key
    VKEY_F4 = VK_F4,

    // VKEY_F5 (74) F5 key
    VKEY_F5 = VK_F5,

    // VKEY_F6 (75) F6 key
    VKEY_F6 = VK_F6,

    // VKEY_F7 (76) F7 key
    VKEY_F7 = VK_F7,

    // VKEY_F8 (77) F8 key
    VKEY_F8 = VK_F8,

    // VKEY_F9 (78) F9 key
    VKEY_F9 = VK_F9,

    // VKEY_F10 (79) F10 key
    VKEY_F10 = VK_F10,

    // VKEY_F11 (7A) F11 key
    VKEY_F11 = VK_F11,

    // VKEY_F12 (7B) F12 key
    VKEY_F12 = VK_F12,

    // VKEY_F13 (7C) F13 key
    VKEY_F13 = VK_F13,

    // VKEY_F14 (7D) F14 key
    VKEY_F14 = VK_F14,

    // VKEY_F15 (7E) F15 key
    VKEY_F15 = VK_F15,

    // VKEY_F16 (7F) F16 key
    VKEY_F16 = VK_F16,

    // VKEY_F17 (80H) F17 key
    VKEY_F17 = VK_F17,

    // VKEY_F18 (81H) F18 key
    VKEY_F18 = VK_F18,

    // VKEY_F19 (82H) F19 key
    VKEY_F19 = VK_F19,

    // VKEY_F20 (83H) F20 key
    VKEY_F20 = VK_F20,

    // VKEY_F21 (84H) F21 key
    VKEY_F21 = VK_F21,

    // VKEY_F22 (85H) F22 key
    VKEY_F22 = VK_F22,

    // VKEY_F23 (86H) F23 key
    VKEY_F23 = VK_F23,

    // VKEY_F24 (87H) F24 key
    VKEY_F24 = VK_F24,

    // VKEY_NUMLOCK (90) NUM LOCK key
    VKEY_NUMLOCK = VK_NUMLOCK,

    // VKEY_SCROLL (91) SCROLL LOCK key
    VKEY_SCROLL = VK_SCROLL,

    // VKEY_LSHIFT (A0) Left SHIFT key
    VKEY_LSHIFT = VK_LSHIFT,

    // VKEY_RSHIFT (A1) Right SHIFT key
    VKEY_RSHIFT = VK_RSHIFT,

    // VKEY_LCONTROL (A2) Left CONTROL key
    VKEY_LCONTROL = VK_LCONTROL,

    // VKEY_RCONTROL (A3) Right CONTROL key
    VKEY_RCONTROL = VK_RCONTROL,

    // VKEY_LMENU (A4) Left MENU key
    VKEY_LMENU = VK_LMENU,

    // VKEY_RMENU (A5) Right MENU key
    VKEY_RMENU = VK_RMENU,

    // VKEY_BROWSER_BACK (A6) Windows 2000/XP: Browser Back key
    VKEY_BROWSER_BACK = VK_BROWSER_BACK,

    // VKEY_BROWSER_FORWARD (A7) Windows 2000/XP: Browser Forward key
    VKEY_BROWSER_FORWARD = VK_BROWSER_FORWARD,

    // VKEY_BROWSER_REFRESH (A8) Windows 2000/XP: Browser Refresh key
    VKEY_BROWSER_REFRESH = VK_BROWSER_REFRESH,

    // VKEY_BROWSER_STOP (A9) Windows 2000/XP: Browser Stop key
    VKEY_BROWSER_STOP = VK_BROWSER_STOP,

    // VKEY_BROWSER_SEARCH (AA) Windows 2000/XP: Browser Search key
    VKEY_BROWSER_SEARCH = VK_BROWSER_SEARCH,

    // VKEY_BROWSER_FAVORITES (AB) Windows 2000/XP: Browser Favorites key
    VKEY_BROWSER_FAVORITES = VK_BROWSER_FAVORITES,

    // VKEY_BROWSER_HOME (AC) Windows 2000/XP: Browser Start and Home key
    VKEY_BROWSER_HOME = VK_BROWSER_HOME,

    // VKEY_VOLUME_MUTE (AD) Windows 2000/XP: Volume Mute key
    VKEY_VOLUME_MUTE = VK_VOLUME_MUTE,

    // VKEY_VOLUME_DOWN (AE) Windows 2000/XP: Volume Down key
    VKEY_VOLUME_DOWN = VK_VOLUME_DOWN,

    // VKEY_VOLUME_UP (AF) Windows 2000/XP: Volume Up key
    VKEY_VOLUME_UP = VK_VOLUME_UP,

    // VKEY_MEDIA_NEXT_TRACK (B0) Windows 2000/XP: Next Track key
    VKEY_MEDIA_NEXT_TRACK = VK_MEDIA_NEXT_TRACK,

    // VKEY_MEDIA_PREV_TRACK (B1) Windows 2000/XP: Previous Track key
    VKEY_MEDIA_PREV_TRACK = VK_MEDIA_PREV_TRACK,

    // VKEY_MEDIA_STOP (B2) Windows 2000/XP: Stop Media key
    VKEY_MEDIA_STOP = VK_MEDIA_STOP,

    // VKEY_MEDIA_PLAY_PAUSE (B3) Windows 2000/XP: Play/Pause Media key
    VKEY_MEDIA_PLAY_PAUSE = VK_MEDIA_PLAY_PAUSE,

    // VKEY_LAUNCH_MAIL (B4) Windows 2000/XP: Start Mail key
    VKEY_MEDIA_LAUNCH_MAIL = 0xB4,

    // VKEY_LAUNCH_MEDIA_SELECT (B5) Windows 2000/XP: Select Media key
    VKEY_MEDIA_LAUNCH_MEDIA_SELECT = 0xB5,

    // VKEY_LAUNCH_APP1 (B6) Windows 2000/XP: Start Application 1 key
    VKEY_MEDIA_LAUNCH_APP1 = 0xB6,

    // VKEY_LAUNCH_APP2 (B7) Windows 2000/XP: Start Application 2 key
    VKEY_MEDIA_LAUNCH_APP2 = 0xB7,

    // VKEY_OEM_1 (BA) Used for miscellaneous characters, it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the ',:' key
    VKEY_OEM_1 = VK_OEM_1,

    // VKEY_OEM_PLUS (BB) Windows 2000/XP: For any country/region, the '+' key
    VKEY_OEM_PLUS = VK_OEM_PLUS,

    // VKEY_OEM_COMMA (BC) Windows 2000/XP: For any country/region, the ',' key
    VKEY_OEM_COMMA = VK_OEM_COMMA,

    // VKEY_OEM_MINUS (BD) Windows 2000/XP: For any country/region, the '-' key
    VKEY_OEM_MINUS = VK_OEM_MINUS,

    // VKEY_OEM_PERIOD (BE) Windows 2000/XP: For any country/region, the '.' key
    VKEY_OEM_PERIOD = VK_OEM_PERIOD,

    // VKEY_OEM_2 (BF) Used for miscellaneous characters, it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '/?' key
    VKEY_OEM_2 = VK_OEM_2,

    // VKEY_OEM_3 (C0) Used for miscellaneous characters, it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '`~' key
    VKEY_OEM_3 = VK_OEM_3,

    // VKEY_OEM_4 (DB) Used for miscellaneous characters, it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '[{' key
    VKEY_OEM_4 = VK_OEM_4,

    // VKEY_OEM_5 (DC) Used for miscellaneous characters, it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '\|' key
    VKEY_OEM_5 = VK_OEM_5,

    // VKEY_OEM_6 (DD) Used for miscellaneous characters, it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the ']}' key
    VKEY_OEM_6 = VK_OEM_6,

    // VKEY_OEM_7 (DE) Used for miscellaneous characters, it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the 'single-quote/double-quote' key
    VKEY_OEM_7 = VK_OEM_7,

    // VKEY_OEM_8 (DF) Used for miscellaneous characters, it can vary by keyboard.
    VKEY_OEM_8 = VK_OEM_8,

    // VKEY_OEM_102 (E2) Windows 2000/XP: Either the angle bracket key or the backslash key on the RT 102-key keyboard
    VKEY_OEM_102 = VK_OEM_102,

    // VKEY_OEM_103 (E3) GTV KEYCODE_MEDIA_REWIND
    VKEY_OEM_103 = 0xE3,

    // VKEY_OEM_104 (E4) GTV KEYCODE_MEDIA_FAST_FORWARD
    VKEY_OEM_104 = 0xE4,

    // VKEY_PROCESSKEY (E5) Windows 95/98/Me, Windows NT 4.0, Windows 2000/XP: IME PROCESS key
    VKEY_PROCESSKEY = VK_PROCESSKEY,

    // VKEY_PACKET (E7) Windows 2000/XP: Used to pass Unicode characters as if they were keystrokes. The VKEY_PACKET key is the low word of a 32-bit Virtual Key value used for non-keyboard input methods. For more information, see Remark in KEYBDINPUT,SendInput, WM_KEYDOWN, and WM_KEYUP
    VKEY_PACKET = VK_PACKET,

    // VKEY_ATTN (F6) Attn key
    VKEY_ATTN = VK_ATTN,

    // VKEY_CRSEL (F7) CrSel key
    VKEY_CRSEL = VK_CRSEL,

    // VKEY_EXSEL (F8) ExSel key
    VKEY_EXSEL = VK_EXSEL,

    // VKEY_EREOF (F9) Erase EOF key
    VKEY_EREOF = VK_EREOF,

    // VKEY_PLAY (FA) Play key
    VKEY_PLAY = VK_PLAY,

    // VKEY_ZOOM (FB) Zoom key
    VKEY_ZOOM = VK_ZOOM,

    // VKEY_NONAME (FC) Reserved for future use
    VKEY_NONAME = VK_NONAME,

    // VKEY_PA1 (FD) PA1 key
    VKEY_PA1 = VK_PA1,

    // VKEY_OEM_CLEAR (FE) Clear key
    VKEY_OEM_CLEAR = VK_OEM_CLEAR,

    VKEY_UNKNOWN = 0
};

} // namespace blink

#endif
