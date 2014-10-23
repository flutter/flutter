/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef WebTextInputType_h
#define WebTextInputType_h

namespace blink {

enum WebTextInputType {
    // Input caret is not in an editable node, no input method shall be used.
    WebTextInputTypeNone,

    // Input caret is in a normal editable node, any input method can be used.
    WebTextInputTypeText,

    // Input caret is in a specific input field, and input method may be used
    // only if it's suitable for the specific input field.
    WebTextInputTypePassword,
    WebTextInputTypeSearch,
    WebTextInputTypeEmail,
    WebTextInputTypeNumber,
    WebTextInputTypeTelephone,
    WebTextInputTypeURL,

    // FIXME: Remove these types once Date like types are not
    // seen as Text. For now they also exist in WebTextInputType
    WebTextInputTypeDate,
    WebTextInputTypeDateTime,
    WebTextInputTypeDateTimeLocal,
    WebTextInputTypeMonth,
    WebTextInputTypeTime,
    WebTextInputTypeWeek,
    WebTextInputTypeTextArea,

    // Input caret is in a contenteditable node (not an INPUT field).
    WebTextInputTypeContentEditable,

    // The focused node is date time field. The date time field does not have
    // input caret but it is necessary to distinguish from WebTextInputTypeNone
    // for on-screen keyboard.
    WebTextInputTypeDateTimeField,
};

// Separate on/off flags are defined so that the input mechanism can choose
// an appropriate default based on other things (like InputType and direct
// knowledge of the actual input system) if there are no overrides.
enum WebTextInputFlags {
    WebTextInputFlagNone = 0,
    WebTextInputFlagAutocompleteOn = 1 << 0,
    WebTextInputFlagAutocompleteOff = 1 << 1,
    WebTextInputFlagAutocorrectOn = 1 << 2,
    WebTextInputFlagAutocorrectOff = 1 << 3,
    WebTextInputFlagSpellcheckOn = 1 << 4,
    WebTextInputFlagSpellcheckOff = 1 << 5
};

} // namespace blink

#endif
