/*
 * Copyright (C) 2006, 2007 Apple, Inc.  All rights reserved.
 * Copyright (C) 2012 Google, Inc.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/editing/EditingBehavior.h"

#include "gen/sky/core/EventTypeNames.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/platform/KeyboardCodes.h"

namespace blink {

//
// The below code was adapted from the WebKit file webview.cpp
//

static const unsigned CtrlKey = 1 << 0;
static const unsigned AltKey = 1 << 1;
static const unsigned ShiftKey = 1 << 2;
static const unsigned MetaKey = 1 << 3;
#if OS(MACOSX)
// Aliases for the generic key defintions to make kbd shortcuts definitions more
// readable on OS X.
static const unsigned OptionKey  = AltKey;

// Do not use this constant for anything but cursor movement commands. Keys
// with cmd set have their |isSystemKey| bit set, so chances are the shortcut
// will not be executed. Another, less important, reason is that shortcuts
// defined in the renderer do not blink the menu item that they triggered. See
// http://crbug.com/25856 and the bugs linked from there for details.
static const unsigned CommandKey = MetaKey;
#endif

// Keys with special meaning. These will be delegated to the editor using
// the execCommand() method
struct KeyDownEntry {
    unsigned virtualKey;
    unsigned modifiers;
    const char* name;
};

struct KeyPressEntry {
    unsigned charCode;
    unsigned modifiers;
    const char* name;
};

static const KeyDownEntry keyDownEntries[] = {
    { VKEY_LEFT,   0,                  "MoveLeft"                             },
    { VKEY_LEFT,   ShiftKey,           "MoveLeftAndModifySelection"           },
    { VKEY_LEFT,   CtrlKey,            "MoveWordLeft"                         },
    { VKEY_LEFT,   CtrlKey | ShiftKey,
        "MoveWordLeftAndModifySelection"                                      },
    { VKEY_RIGHT,  0,                  "MoveRight"                            },
    { VKEY_RIGHT,  ShiftKey,           "MoveRightAndModifySelection"          },
    { VKEY_RIGHT,  CtrlKey,            "MoveWordRight"                        },
    { VKEY_RIGHT,  CtrlKey | ShiftKey, "MoveWordRightAndModifySelection"      },
    { VKEY_UP,     0,                  "MoveUp"                               },
    { VKEY_UP,     ShiftKey,           "MoveUpAndModifySelection"             },
    { VKEY_PRIOR,  ShiftKey,           "MovePageUpAndModifySelection"         },
    { VKEY_DOWN,   0,                  "MoveDown"                             },
    { VKEY_DOWN,   ShiftKey,           "MoveDownAndModifySelection"           },
    { VKEY_NEXT,   ShiftKey,           "MovePageDownAndModifySelection"       },
    { VKEY_UP,     CtrlKey,            "MoveParagraphBackward"                },
    { VKEY_UP,     CtrlKey | ShiftKey, "MoveParagraphBackwardAndModifySelection" },
    { VKEY_DOWN,   CtrlKey,            "MoveParagraphForward"                },
    { VKEY_DOWN,   CtrlKey | ShiftKey, "MoveParagraphForwardAndModifySelection" },
    { VKEY_PRIOR,  0,                  "MovePageUp"                           },
    { VKEY_NEXT,   0,                  "MovePageDown"                         },
    { VKEY_HOME,   0,                  "MoveToBeginningOfLine"                },
    { VKEY_HOME,   ShiftKey,
        "MoveToBeginningOfLineAndModifySelection"                             },
    { VKEY_HOME,   CtrlKey,            "MoveToBeginningOfDocument"            },
    { VKEY_HOME,   CtrlKey | ShiftKey,
        "MoveToBeginningOfDocumentAndModifySelection"                         },
    { VKEY_END,    0,                  "MoveToEndOfLine"                      },
    { VKEY_END,    ShiftKey,           "MoveToEndOfLineAndModifySelection"    },
    { VKEY_END,    CtrlKey,            "MoveToEndOfDocument"                  },
    { VKEY_END,    CtrlKey | ShiftKey,
        "MoveToEndOfDocumentAndModifySelection"                               },
    { VKEY_BACK,   0,                  "DeleteBackward"                       },
    { VKEY_DELETE, 0,                  "DeleteForward"                        },
    { VKEY_BACK,   CtrlKey,            "DeleteWordBackward"                   },
    { VKEY_DELETE, CtrlKey,            "DeleteWordForward"                    },
    { VKEY_RETURN, 0,                  "InsertNewline"                        },
    { 'C',         CtrlKey,            "Copy"                                 },
    { 'V',         CtrlKey,            "Paste"                                },
    { 'V',         CtrlKey | ShiftKey, "PasteAndMatchStyle"                   },
    { 'X',         CtrlKey,            "Cut"                                  },
    { 'A',         CtrlKey,            "SelectAll"                            },
    { VKEY_INSERT, 0,                  "OverWrite"                            },
};

static const KeyPressEntry keyPressEntries[] = {
    { '\r',   0,                  "InsertNewline"                             },
};

const char* EditingBehavior::interpretKeyEvent(const KeyboardEvent& event) const
{
    static HashMap<int, const char*>* keyDownCommandsMap = 0;
    static HashMap<int, const char*>* keyPressCommandsMap = 0;

    if (!keyDownCommandsMap) {
        keyDownCommandsMap = new HashMap<int, const char*>;
        keyPressCommandsMap = new HashMap<int, const char*>;

        for (unsigned i = 0; i < arraysize(keyDownEntries); i++) {
            keyDownCommandsMap->set(keyDownEntries[i].modifiers << 16 | keyDownEntries[i].virtualKey, keyDownEntries[i].name);
        }

        for (unsigned i = 0; i < arraysize(keyPressEntries); i++) {
            keyPressCommandsMap->set(keyPressEntries[i].modifiers << 16 | keyPressEntries[i].charCode, keyPressEntries[i].name);
        }
    }

    unsigned modifiers = 0;
    if (event.shiftKey())
        modifiers |= ShiftKey;
    if (event.altKey())
        modifiers |= AltKey;
    if (event.ctrlKey())
        modifiers |= CtrlKey;
    if (event.metaKey())
        modifiers |= MetaKey;

    if (event.type() == EventTypeNames::keydown) {
        int mapKey = modifiers << 16 | event.key();
        return mapKey ? keyDownCommandsMap->get(mapKey) : 0;
    }

    int mapKey = modifiers << 16 | event.charCode();
    return mapKey ? keyPressCommandsMap->get(mapKey) : 0;
}

bool EditingBehavior::shouldInsertCharacter(const KeyboardEvent& event) const
{
    // On Gtk/Linux, it emits key events with ASCII text and ctrl on for ctrl-<x>.
    // In Webkit, EditorClient::handleKeyboardEvent in
    // WebKit/gtk/WebCoreSupport/EditorClientGtk.cpp drop such events.
    // On Mac, it emits key events with ASCII text and meta on for Command-<x>.
    // These key events should not emit text insert event.
    // Alt key would be used to insert alternative character, so we should let
    // through. Also note that Ctrl-Alt combination equals to AltGr key which is
    // also used to insert alternative character.
    // http://code.google.com/p/chromium/issues/detail?id=10846
    // Windows sets both alt and meta are on when "Alt" key pressed.
    // http://code.google.com/p/chromium/issues/detail?id=2215
    // Also, we should not rely on an assumption that keyboards don't
    // send ASCII characters when pressing a control key on Windows,
    // which may be configured to do it so by user.
    // See also http://en.wikipedia.org/wiki/Keyboard_Layout
    // FIXME(ukai): investigate more detail for various keyboard layout.
    UChar ch = event.charCode();

    // Don't insert null or control characters as they can result in
    // unexpected behaviour
    if (ch < ' ')
        return false;
#if !OS(WIN)
    // Don't insert ASCII character if ctrl w/o alt or meta is on.
    // On Mac, we should ignore events when meta is on (Command-<x>).
    if (ch < 0x80) {
        if (event.ctrlKey() && !event.altKey())
            return false;
#if OS(MACOSX)
        if (event.metaKey())
            return false;
#endif
    }
#endif

    return true;
}
} // namespace blink

