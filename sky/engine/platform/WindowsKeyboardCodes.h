/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef VK_UNKNOWN

#define VK_UNKNOWN 0

// Left mouse button
// Right mouse button
// Control-break processing
// Middle mouse button (three-button mouse)
// VK_XBUTTON1 (05)
// VK_XBUTTON2 (06)

#ifndef VK_BACK
#define VK_BACK 0x08
#endif
#ifndef VK_TAB
#define VK_TAB 0x09
#endif
#ifndef VK_CLEAR
#define VK_CLEAR 0x0C
#endif
#ifndef VK_RETURN
#define VK_RETURN 0x0D
#endif
#ifndef VK_SHIFT
#define VK_SHIFT 0x10
#endif
#ifndef VK_CONTROL
#define VK_CONTROL 0x11 // CTRL key
#endif
#ifndef VK_MENU
#define VK_MENU 0x12 // ALT key
#endif
#ifndef VK_PAUSE
#define VK_PAUSE 0x13 // PAUSE key
#endif
#ifndef VK_CAPITAL
#define VK_CAPITAL 0x14 // CAPS LOCK key
#endif
#ifndef VK_KANA
#define VK_KANA 0x15 // Input Method Editor (IME) Kana mode
#endif
#ifndef VK_HANGUL
#define VK_HANGUL 0x15 // IME Hangul mode
#endif
#ifndef VK_JUNJA
#define VK_JUNJA 0x17 // IME Junja mode
#endif
#ifndef VK_FINAL
#define VK_FINAL 0x18 // IME final mode
#endif
#ifndef VK_HANJA
#define VK_HANJA 0x19 // IME Hanja mode
#endif
#ifndef VK_KANJI
#define VK_KANJI 0x19 // IME Kanji mode
#endif
#ifndef VK_ESCAPE
#define VK_ESCAPE 0x1B // ESC key
#endif
#ifndef VK_CONVERT
#define VK_CONVERT 0x1C // IME convert
#endif
#ifndef VK_NONCONVERT
#define VK_NONCONVERT 0x1D // IME nonconvert
#endif
#ifndef VK_ACCEPT
#define VK_ACCEPT 0x1E // IME accept
#endif
#ifndef VK_MODECHANGE
#define VK_MODECHANGE 0x1F // IME mode change request
#endif
#ifndef VK_SPACE
#define VK_SPACE 0x20 // SPACE key
#endif
#ifndef VK_PRIOR
#define VK_PRIOR 0x21 // PAGE UP key
#endif
#ifndef VK_NEXT
#define VK_NEXT 0x22 // PAGE DOWN key
#endif
#ifndef VK_END
#define VK_END 0x23 // END key
#endif
#ifndef VK_HOME
#define VK_HOME 0x24 // HOME key
#endif
#ifndef VK_LEFT
#define VK_LEFT 0x25 // LEFT ARROW key
#endif
#ifndef VK_UP
#define VK_UP 0x26 // UP ARROW key
#endif
#ifndef VK_RIGHT
#define VK_RIGHT 0x27 // RIGHT ARROW key
#endif
#ifndef VK_DOWN
#define VK_DOWN 0x28 // DOWN ARROW key
#endif
#ifndef VK_SELECT
#define VK_SELECT 0x29 // SELECT key
#endif
#ifndef VK_PRINT
#define VK_PRINT 0x2A // PRINT key
#endif
#ifndef VK_EXECUTE
#define VK_EXECUTE 0x2B // EXECUTE key
#endif
#ifndef VK_SNAPSHOT
#define VK_SNAPSHOT 0x2C // PRINT SCREEN key
#endif
#ifndef VK_INSERT
#define VK_INSERT 0x2D // INS key
#endif
#ifndef VK_DELETE
#define VK_DELETE 0x2E // DEL key
#endif
#ifndef VK_HELP
#define VK_HELP 0x2F // HELP key
#endif

#define VK_0 0x30
#define VK_1 0x31
#define VK_2 0x32
#define VK_3 0x33
#define VK_4 0x34
#define VK_5 0x35
#define VK_6 0x36
#define VK_7 0x37
#define VK_8 0x38
#define VK_9 0x39
#define VK_A 0x41
#define VK_B 0x42
#define VK_C 0x43
#define VK_D 0x44
#define VK_E 0x45
#define VK_F 0x46
#define VK_G 0x47
#define VK_H 0x48
#define VK_I 0x49
#define VK_J 0x4A
#define VK_K 0x4B
#define VK_L 0x4C
#define VK_M 0x4D
#define VK_N 0x4E
#define VK_O 0x4F
#define VK_P 0x50
#define VK_Q 0x51
#define VK_R 0x52
#define VK_S 0x53
#define VK_T 0x54
#define VK_U 0x55
#define VK_V 0x56
#define VK_W 0x57
#define VK_X 0x58
#define VK_Y 0x59
#define VK_Z 0x5A

#define VK_LWIN 0x5B // Left Windows key (Microsoft Natural keyboard)

#define VK_RWIN 0x5C // Right Windows key (Natural keyboard)

#define VK_APPS 0x5D // Applications key (Natural keyboard)

#define VK_SLEEP 0x5F // Computer Sleep key

// Num pad keys
#define VK_NUMPAD0 0x60
#define VK_NUMPAD1 0x61
#define VK_NUMPAD2 0x62
#define VK_NUMPAD3 0x63
#define VK_NUMPAD4 0x64
#define VK_NUMPAD5 0x65
#define VK_NUMPAD6 0x66
#define VK_NUMPAD7 0x67
#define VK_NUMPAD8 0x68
#define VK_NUMPAD9 0x69
#define VK_MULTIPLY 0x6A
#define VK_ADD 0x6B
#define VK_SEPARATOR 0x6C
#define VK_SUBTRACT 0x6D
#define VK_DECIMAL 0x6E
#define VK_DIVIDE 0x6F

#define VK_F1 0x70
#define VK_F2 0x71
#define VK_F3 0x72
#define VK_F4 0x73
#define VK_F5 0x74
#define VK_F6 0x75
#define VK_F7 0x76
#define VK_F8 0x77
#define VK_F9 0x78
#define VK_F10 0x79
#define VK_F11 0x7A
#define VK_F12 0x7B
#define VK_F13 0x7C
#define VK_F14 0x7D
#define VK_F15 0x7E
#define VK_F16 0x7F
#define VK_F17 0x80
#define VK_F18 0x81
#define VK_F19 0x82
#define VK_F20 0x83
#define VK_F21 0x84
#define VK_F22 0x85
#define VK_F23 0x86
#define VK_F24 0x87

#define VK_NUMLOCK 0x90
#define VK_SCROLL 0x91
#define VK_LSHIFT 0xA0
#define VK_RSHIFT 0xA1
#define VK_LCONTROL 0xA2
#define VK_RCONTROL 0xA3
#define VK_LMENU 0xA4
#define VK_RMENU 0xA5

#define VK_BROWSER_BACK 0xA6 // Windows 2000/XP: Browser Back key
#define VK_BROWSER_FORWARD 0xA7 // Windows 2000/XP: Browser Forward key
#define VK_BROWSER_REFRESH 0xA8 // Windows 2000/XP: Browser Refresh key
#define VK_BROWSER_STOP 0xA9 // Windows 2000/XP: Browser Stop key
#define VK_BROWSER_SEARCH 0xAA // Windows 2000/XP: Browser Search key
#define VK_BROWSER_FAVORITES 0xAB // Windows 2000/XP: Browser Favorites key
#define VK_BROWSER_HOME 0xAC // Windows 2000/XP: Browser Start and Home key
#define VK_VOLUME_MUTE 0xAD // Windows 2000/XP: Volume Mute key
#define VK_VOLUME_DOWN 0xAE // Windows 2000/XP: Volume Down key
#define VK_VOLUME_UP 0xAF // Windows 2000/XP: Volume Up key
#define VK_MEDIA_NEXT_TRACK 0xB0 // Windows 2000/XP: Next Track key
#define VK_MEDIA_PREV_TRACK 0xB1 // Windows 2000/XP: Previous Track key
#define VK_MEDIA_STOP 0xB2 // Windows 2000/XP: Stop Media key
#define VK_MEDIA_PLAY_PAUSE 0xB3 // Windows 2000/XP: Play/Pause Media key
#define VK_MEDIA_LAUNCH_MAIL 0xB4 // Windows 2000/XP: Start Mail key
#define VK_MEDIA_LAUNCH_MEDIA_SELECT 0xB5 // Windows 2000/XP: Select Media key
#define VK_MEDIA_LAUNCH_APP1 0xB6 // VK_LAUNCH_APP1 (B6) Windows 2000/XP: Start Application 1 key
#define VK_MEDIA_LAUNCH_APP2 0xB7 // VK_LAUNCH_APP2 (B7) Windows 2000/XP: Start Application 2 key

// VK_OEM_1 (BA) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the ';:' key
#define VK_OEM_1 0xBA

// Windows 2000/XP: For any country/region, the '+' key
#define VK_OEM_PLUS 0xBB

// Windows 2000/XP: For any country/region, the ',' key
#define VK_OEM_COMMA 0xBC

// Windows 2000/XP: For any country/region, the '-' key
#define VK_OEM_MINUS 0xBD

// Windows 2000/XP: For any country/region, the '.' key
#define VK_OEM_PERIOD 0xBE

// VK_OEM_2 (BF) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '/?' key
#define VK_OEM_2 0xBF

// VK_OEM_3 (C0) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '`~' key
#define VK_OEM_3 0xC0

// VK_OEM_4 (DB) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '[{' key
#define VK_OEM_4 0xDB

// VK_OEM_5 (DC) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the '\|' key
#define VK_OEM_5 0xDC

// VK_OEM_6 (DD) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the ']}' key
#define VK_OEM_6 0xDD

// VK_OEM_7 (DE) Used for miscellaneous characters; it can vary by keyboard. Windows 2000/XP: For the US standard keyboard, the 'single-quote/double-quote' key
#define VK_OEM_7 0xDE

// VK_OEM_8 (DF) Used for miscellaneous characters; it can vary by keyboard.
#define VK_OEM_8 0xDF

// VK_OEM_102 (E2) Windows 2000/XP: Either the angle bracket key or the backslash key on the RT 102-key keyboard
#define VK_OEM_102 0xE2

// Windows 95/98/Me, Windows NT 4.0, Windows 2000/XP: IME PROCESS key
#define VK_PROCESSKEY 0xE5

// Windows 2000/XP: Used to pass Unicode characters as if they were keystrokes. The VK_PACKET key is the low word of a 32-bit Virtual Key value used for non-keyboard input methods. For more information, see Remark in KEYBDINPUT,SendInput, WM_KEYDOWN, and WM_KEYUP
#define VK_PACKET 0xE7

#define VK_ATTN 0xF6 // Attn key
#define VK_CRSEL 0xF7 // CrSel key
#define VK_EXSEL 0xF8 // ExSel key
#define VK_EREOF 0xF9 // Erase EOF key
#define VK_PLAY 0xFA // Play key
#define VK_ZOOM 0xFB // Zoom key

#define VK_NONAME 0xFC // Reserved for future use

#define VK_PA1 0xFD // VK_PA1 (FD) PA1 key

#define VK_OEM_CLEAR 0xFE // Clear key

#endif // VK_UNKNOWN
