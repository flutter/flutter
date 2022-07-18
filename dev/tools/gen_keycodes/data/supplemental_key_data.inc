  // This file contains supplemental key data to be added to those that
  // Chromium defines.

  // ============================================================
  // Printable keys (Unicode plane)
  // ============================================================

  //          Key                       Enum                Unicode code point
  DOM_KEY_UNI("Space",                  SPACE,                  ' '),
  DOM_KEY_UNI("Exclamation",            EXCLAMATION,            '!'),
  DOM_KEY_UNI("NumberSign",             NUMBER_SIGN,            '#'),
  DOM_KEY_UNI("Dollar",                 DOLLAR,                 '$'),
  DOM_KEY_UNI("Percent",                PERCENT,                '%'),
  DOM_KEY_UNI("Ampersand",              AMPERSAND,              '&'),
  DOM_KEY_UNI("QuoteSingle",            QUOTE_SINGLE,           0x0027),
  DOM_KEY_UNI("Quote",                  QUOTE,                  '"')",
  DOM_KEY_UNI("ParenthesisLeft",        PARENTHESIS_LEFT,       '('),
  DOM_KEY_UNI("ParenthesisRight",       PARENTHESIS_RIGHT,      ')'),
  DOM_KEY_UNI("Asterisk",               ASTERISK,               '*'),
  DOM_KEY_UNI("Add",                    ADD,                    '+'),
  DOM_KEY_UNI("Comma",                  COMMA,                  ','),
  DOM_KEY_UNI("Minus",                  MINUS,                  '-'),
  DOM_KEY_UNI("Period",                 PERIOD,                 '.'),
  DOM_KEY_UNI("Slash",                  SLASH,                  '/'),
  DOM_KEY_UNI("Digit0",                 DIGIT0,                 '0'),
  DOM_KEY_UNI("Digit1",                 DIGIT1,                 '1'),
  DOM_KEY_UNI("Digit2",                 DIGIT2,                 '2'),
  DOM_KEY_UNI("Digit3",                 DIGIT3,                 '3'),
  DOM_KEY_UNI("Digit4",                 DIGIT4,                 '4'),
  DOM_KEY_UNI("Digit5",                 DIGIT5,                 '5'),
  DOM_KEY_UNI("Digit6",                 DIGIT6,                 '6'),
  DOM_KEY_UNI("Digit7",                 DIGIT7,                 '7'),
  DOM_KEY_UNI("Digit8",                 DIGIT8,                 '8'),
  DOM_KEY_UNI("Digit9",                 DIGIT9,                 '9'),
  DOM_KEY_UNI("Colon",                  COLON,                  ':'),
  DOM_KEY_UNI("Semicolon",              SEMICOLON,              ';'),
  DOM_KEY_UNI("Less",                   LESS,                   '<'),
  DOM_KEY_UNI("Equal",                  EQUAL,                  '='),
  DOM_KEY_UNI("Greater",                GREATER,                '>'),
  DOM_KEY_UNI("Question",               QUESTION,               '?'),
  DOM_KEY_UNI("At",                     AT,                     '@'),
  DOM_KEY_UNI("BracketLeft",            BRACKET_LEFT,           '['),
  DOM_KEY_UNI("Backslash",              BACKSLASH,              0x005c),
  DOM_KEY_UNI("BracketRight",           BRACKET_RIGHT,          ']'),
  DOM_KEY_UNI("Caret",                  CARET,                  '^'),
  DOM_KEY_UNI("Backquote",              BACKQUOTE,              '`'),
  DOM_KEY_UNI("Underscore",             UNDERSCORE,             '_'),
  DOM_KEY_UNI("KeyA",                   KEY_A,                  'a'),
  DOM_KEY_UNI("KeyB",                   KEY_B,                  'b'),
  DOM_KEY_UNI("KeyC",                   KEY_C,                  'c'),
  DOM_KEY_UNI("KeyD",                   KEY_D,                  'd'),
  DOM_KEY_UNI("KeyE",                   KEY_E,                  'e'),
  DOM_KEY_UNI("KeyF",                   KEY_F,                  'f'),
  DOM_KEY_UNI("KeyG",                   KEY_G,                  'g'),
  DOM_KEY_UNI("KeyH",                   KEY_H,                  'h'),
  DOM_KEY_UNI("KeyI",                   KEY_I,                  'i'),
  DOM_KEY_UNI("KeyJ",                   KEY_J,                  'j'),
  DOM_KEY_UNI("KeyK",                   KEY_K,                  'k'),
  DOM_KEY_UNI("KeyL",                   KEY_L,                  'l'),
  DOM_KEY_UNI("KeyM",                   KEY_M,                  'm'),
  DOM_KEY_UNI("KeyN",                   KEY_N,                  'n'),
  DOM_KEY_UNI("KeyO",                   KEY_O,                  'o'),
  DOM_KEY_UNI("KeyP",                   KEY_P,                  'p'),
  DOM_KEY_UNI("KeyQ",                   KEY_Q,                  'q'),
  DOM_KEY_UNI("KeyR",                   KEY_R,                  'r'),
  DOM_KEY_UNI("KeyS",                   KEY_S,                  's'),
  DOM_KEY_UNI("KeyT",                   KEY_T,                  't'),
  DOM_KEY_UNI("KeyU",                   KEY_U,                  'u'),
  DOM_KEY_UNI("KeyV",                   KEY_V,                  'v'),
  DOM_KEY_UNI("KeyW",                   KEY_W,                  'w'),
  DOM_KEY_UNI("KeyX",                   KEY_X,                  'x'),
  DOM_KEY_UNI("KeyY",                   KEY_Y,                  'y'),
  DOM_KEY_UNI("KeyZ",                   KEY_Z,                  'z'),
  DOM_KEY_UNI("BraceLeft",              BRACE_LEFT,             '{'),
  DOM_KEY_UNI("BraceRight",             BRACE_RIGHT,            '}'),
  DOM_KEY_UNI("Tilde",                  TILDE,                  '~'),
  DOM_KEY_UNI("Bar",                    BAR,                    '|'),

  // ============================================================
  // Unprintable keys (Unicode plane)
  // ============================================================

  //          Key                       Enum                    Value
  // Sometimes the Escape key produces "Esc" instead of "Escape". This includes
  // older IE and Firefox browsers, and the current Cobalt browser.
  // See: https://github.com/flutter/flutter/issues/106062
  DOM_KEY_MAP("Esc",                    ESC,                    0x1B),

  // The following keys reside in the Flutter plane (0x0100000000).

  // ============================================================
  // Miscellaneous (0x000__)
  // ============================================================

  //              Key                       Enum                    Value
  FLUTTER_KEY_MAP("Suspend",                SUSPEND,                0x00000),
  FLUTTER_KEY_MAP("Resume",                 RESUME,                 0x00001),
  FLUTTER_KEY_MAP("Sleep",                  SLEEP,                  0x00002),
  FLUTTER_KEY_MAP("Abort",                  ABORT,                  0x00003),
  FLUTTER_KEY_MAP("Lang1",                  LANG1,                  0x00010),
  FLUTTER_KEY_MAP("Lang2",                  LANG2,                  0x00011),
  FLUTTER_KEY_MAP("Lang3",                  LANG3,                  0x00012),
  FLUTTER_KEY_MAP("Lang4",                  LANG4,                  0x00013),
  FLUTTER_KEY_MAP("Lang5",                  LANG5,                  0x00014),
  FLUTTER_KEY_MAP("IntlBackslash",          INTL_BACKSLASH,         0x00020),
  FLUTTER_KEY_MAP("IntlRo",                 INTL_RO,                0x00021),
  FLUTTER_KEY_MAP("IntlYen",                INTL_YEN,               0x00022),

  // ============================================================
  // Modifiers (0x001__)
  // ============================================================
  //              Key                       Enum                    Value
  FLUTTER_KEY_MAP("ControlLeft",            CONTROL_LEFT,           0x00100),
  FLUTTER_KEY_MAP("ControlRight",           CONTROL_RIGHT,          0x00101),
  FLUTTER_KEY_MAP("ShiftLeft",              SHIFT_LEFT,             0x00102),
  FLUTTER_KEY_MAP("ShiftRight",             SHIFT_RIGHT,            0x00103),
  FLUTTER_KEY_MAP("AltLeft",                ALT_LEFT,               0x00104),
  FLUTTER_KEY_MAP("AltRight",               ALT_RIGHT,              0x00105),
  FLUTTER_KEY_MAP("MetaLeft",               META_LEFT,              0x00106),
  FLUTTER_KEY_MAP("MetaRight",              META_RIGHT,             0x00107),
  // Synonym keys are added for compatibility and will be removed in the future.
  FLUTTER_KEY_MAP("Control",                CONTROL,                0x001F0),
  FLUTTER_KEY_MAP("Shift",                  SHIFT,                  0x001F2),
  FLUTTER_KEY_MAP("Alt",                    ALT,                    0x001F4),
  FLUTTER_KEY_MAP("Meta",                   META,                   0x001F6),

  // ============================================================
  // Number pad (0x002__)
  // ============================================================
  // The value for number pad buttons are derived from their unicode code
  // points.
  FLUTTER_KEY_MAP("NumpadEnter",            NUMPAD_ENTER,           0x0020D),
  FLUTTER_KEY_MAP("NumpadParenLeft",        NUMPAD_PAREN_LEFT,      0x00228),
  FLUTTER_KEY_MAP("NumpadParenRight",       NUMPAD_PAREN_RIGHT,     0x00229),
  FLUTTER_KEY_MAP("NumpadMultiply",         NUMPAD_MULTIPLY,        0x0022A),
  FLUTTER_KEY_MAP("NumpadAdd",              NUMPAD_ADD,             0x0022B),
  FLUTTER_KEY_MAP("NumpadComma",            NUMPAD_COMMA,           0x0022C),
  FLUTTER_KEY_MAP("NumpadSubtract",         NUMPAD_SUBTRACT,        0x0022D),
  FLUTTER_KEY_MAP("NumpadDecimal",          NUMPAD_DECIMAL,         0x0022E),
  FLUTTER_KEY_MAP("NumpadDivide",           NUMPAD_DIVIDE,          0x0022F),
  FLUTTER_KEY_MAP("Numpad0",                NUMPAD_0,               0x00230),
  FLUTTER_KEY_MAP("Numpad1",                NUMPAD_1,               0x00231),
  FLUTTER_KEY_MAP("Numpad2",                NUMPAD_2,               0x00232),
  FLUTTER_KEY_MAP("Numpad3",                NUMPAD_3,               0x00233),
  FLUTTER_KEY_MAP("Numpad4",                NUMPAD_4,               0x00234),
  FLUTTER_KEY_MAP("Numpad5",                NUMPAD_5,               0x00235),
  FLUTTER_KEY_MAP("Numpad6",                NUMPAD_6,               0x00236),
  FLUTTER_KEY_MAP("Numpad7",                NUMPAD_7,               0x00237),
  FLUTTER_KEY_MAP("Numpad8",                NUMPAD_8,               0x00238),
  FLUTTER_KEY_MAP("Numpad9",                NUMPAD_9,               0x00239),
  FLUTTER_KEY_MAP("NumpadEqual",            NUMPAD_EQUAL,           0x0023D),

  // ============================================================
  // Game controller buttons (0x003__)
  // ============================================================

  // The value for game controller buttons are derived from the last 8 bit
  // of its USB HID usage.
  //              Key                       Enum                    Value
  FLUTTER_KEY_MAP("GameButton1",            GAME_BUTTON_1,          0x00301),
  FLUTTER_KEY_MAP("GameButton2",            GAME_BUTTON_2,          0x00302),
  FLUTTER_KEY_MAP("GameButton3",            GAME_BUTTON_3,          0x00303),
  FLUTTER_KEY_MAP("GameButton4",            GAME_BUTTON_4,          0x00304),
  FLUTTER_KEY_MAP("GameButton5",            GAME_BUTTON_5,          0x00305),
  FLUTTER_KEY_MAP("GameButton6",            GAME_BUTTON_6,          0x00306),
  FLUTTER_KEY_MAP("GameButton7",            GAME_BUTTON_7,          0x00307),
  FLUTTER_KEY_MAP("GameButton8",            GAME_BUTTON_8,          0x00308),
  FLUTTER_KEY_MAP("GameButton9",            GAME_BUTTON_9,          0x00309),
  FLUTTER_KEY_MAP("GameButton10",           GAME_BUTTON_10,         0x0030a),
  FLUTTER_KEY_MAP("GameButton11",           GAME_BUTTON_11,         0x0030b),
  FLUTTER_KEY_MAP("GameButton12",           GAME_BUTTON_12,         0x0030c),
  FLUTTER_KEY_MAP("GameButton13",           GAME_BUTTON_13,         0x0030d),
  FLUTTER_KEY_MAP("GameButton14",           GAME_BUTTON_14,         0x0030e),
  FLUTTER_KEY_MAP("GameButton15",           GAME_BUTTON_15,         0x0030f),
  FLUTTER_KEY_MAP("GameButton16",           GAME_BUTTON_16,         0x00310),
  FLUTTER_KEY_MAP("GameButtonA",            GAME_BUTTON_A,          0x00311),
  FLUTTER_KEY_MAP("GameButtonB",            GAME_BUTTON_B,          0x00312),
  FLUTTER_KEY_MAP("GameButtonC",            GAME_BUTTON_C,          0x00313),
  FLUTTER_KEY_MAP("GameButtonLeft1",        GAME_BUTTON_L1,         0x00314),
  FLUTTER_KEY_MAP("GameButtonLeft2",        GAME_BUTTON_L2,         0x00315),
  FLUTTER_KEY_MAP("GameButtonMode",         GAME_BUTTON_MODE,       0x00316),
  FLUTTER_KEY_MAP("GameButtonRight1",       GAME_BUTTON_R1,         0x00317),
  FLUTTER_KEY_MAP("GameButtonRight2",       GAME_BUTTON_R2,         0x00318),
  FLUTTER_KEY_MAP("GameButtonSelect",       GAME_BUTTON_SELECT,     0x00319),
  FLUTTER_KEY_MAP("GameButtonStart",        GAME_BUTTON_START,      0x0031a),
  FLUTTER_KEY_MAP("GameButtonThumbLeft",    GAME_BUTTON_THUMBL,     0x0031b),
  FLUTTER_KEY_MAP("GameButtonThumbRight",   GAME_BUTTON_THUMBR,     0x0031c),
  FLUTTER_KEY_MAP("GameButtonX",            GAME_BUTTON_X,          0x0031d),
  FLUTTER_KEY_MAP("GameButtonY",            GAME_BUTTON_Y,          0x0031e),
  FLUTTER_KEY_MAP("GameButtonZ",            GAME_BUTTON_Z,          0x0031f),
