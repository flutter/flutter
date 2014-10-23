/*
 * Copyright (c) 2013, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
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

#ifndef Canvas2DContextAttributes_h
#define Canvas2DContextAttributes_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/html/canvas/CanvasContextAttributes.h"
#include "wtf/PassRefPtr.h"

namespace blink {

enum Canvas2DContextStorage {
    PersistentStorage,
    DiscardableStorage
};

class Canvas2DContextAttributes : public CanvasContextAttributes, public ScriptWrappable {
    DECLARE_EMPTY_VIRTUAL_DESTRUCTOR_WILL_BE_REMOVED(Canvas2DContextAttributes);
    DEFINE_WRAPPERTYPEINFO();
public:
    // Create a new attributes object
    static PassRefPtrWillBeRawPtr<Canvas2DContextAttributes> create();

    // Whether or not the drawing buffer has an alpha channel; default=true
    bool alpha() const;
    void setAlpha(bool);

    String storage() const;
    void setStorage(const String&);
    Canvas2DContextStorage parsedStorage() const;

protected:
    Canvas2DContextAttributes();

    bool m_alpha;
    Canvas2DContextStorage m_storage;
};

} // namespace blink

#endif // Canvas2DContextAttributes_h
