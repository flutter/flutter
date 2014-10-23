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

#include "config.h"

#include "core/html/canvas/Canvas2DContextAttributes.h"

#include "wtf/text/WTFString.h"

namespace blink {

Canvas2DContextAttributes::Canvas2DContextAttributes()
    : m_alpha(true)
    , m_storage(PersistentStorage)
{
    ScriptWrappable::init(this);
}

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(Canvas2DContextAttributes);

PassRefPtrWillBeRawPtr<Canvas2DContextAttributes> Canvas2DContextAttributes::create()
{
    return adoptRefWillBeNoop(new Canvas2DContextAttributes());
}

bool Canvas2DContextAttributes::alpha() const
{
    return m_alpha;
}

void Canvas2DContextAttributes::setAlpha(bool alpha)
{
    m_alpha = alpha;
}

String Canvas2DContextAttributes::storage() const
{
    return m_storage == PersistentStorage ? "persistent" : "discardable";
}

void Canvas2DContextAttributes::setStorage(const String& storage)
{
    if (storage == "persistent")
        m_storage = PersistentStorage;
    else if (storage == "discardable")
        m_storage = DiscardableStorage;
}

Canvas2DContextStorage Canvas2DContextAttributes::parsedStorage() const
{
    return m_storage;
}

} // namespace blink
