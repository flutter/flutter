/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef FontFace_h
#define FontFace_h

#include "bindings/core/v8/ScriptPromise.h"
#include "bindings/core/v8/ScriptPromiseProperty.h"
#include "bindings/core/v8/ScriptWrappable.h"
#include "core/CSSPropertyNames.h"
#include "core/css/CSSValue.h"
#include "core/dom/DOMException.h"
#include "platform/fonts/FontTraits.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/text/WTFString.h"

namespace blink {

class CSSFontFace;
class CSSValueList;
class Dictionary;
class Document;
class ExceptionState;
class FontFaceReadyPromiseResolver;
class StylePropertySet;
class StyleRuleFontFace;

class FontFace : public RefCountedWillBeGarbageCollectedFinalized<FontFace>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    enum LoadStatus { Unloaded, Loading, Loaded, Error };

    static PassRefPtrWillBeRawPtr<FontFace> create(ExecutionContext*, const AtomicString& family, PassRefPtr<ArrayBuffer> source, const Dictionary&);
    static PassRefPtrWillBeRawPtr<FontFace> create(ExecutionContext*, const AtomicString& family, PassRefPtr<ArrayBufferView>, const Dictionary&);
    static PassRefPtrWillBeRawPtr<FontFace> create(ExecutionContext*, const AtomicString& family, const String& source, const Dictionary&);
    static PassRefPtrWillBeRawPtr<FontFace> create(Document*, const StyleRuleFontFace*);

    ~FontFace();

    const AtomicString& family() const { return m_family; }
    String style() const;
    String weight() const;
    String stretch() const;
    String unicodeRange() const;
    String variant() const;
    String featureSettings() const;

    // FIXME: Changing these attributes should affect font matching.
    void setFamily(ExecutionContext*, const AtomicString& s, ExceptionState&) { m_family = s; }
    void setStyle(ExecutionContext*, const String&, ExceptionState&);
    void setWeight(ExecutionContext*, const String&, ExceptionState&);
    void setStretch(ExecutionContext*, const String&, ExceptionState&);
    void setUnicodeRange(ExecutionContext*, const String&, ExceptionState&);
    void setVariant(ExecutionContext*, const String&, ExceptionState&);
    void setFeatureSettings(ExecutionContext*, const String&, ExceptionState&);

    String status() const;
    ScriptPromise loaded(ScriptState* scriptState) { return fontStatusPromise(scriptState); }

    ScriptPromise load(ScriptState*);

    LoadStatus loadStatus() const { return m_status; }
    void setLoadStatus(LoadStatus);
    void setError(PassRefPtrWillBeRawPtr<DOMException> = nullptr);
    DOMException* error() const { return m_error.get(); }
    FontTraits traits() const;
    CSSFontFace* cssFontFace() { return m_cssFontFace.get(); }

    void trace(Visitor*);

    bool hadBlankText() const;

    class LoadFontCallback : public RefCountedWillBeGarbageCollectedFinalized<LoadFontCallback> {
    public:
        virtual ~LoadFontCallback() { }
        virtual void notifyLoaded(FontFace*) = 0;
        virtual void notifyError(FontFace*) = 0;
        virtual void trace(Visitor*) { }
    };
    void loadWithCallback(PassRefPtrWillBeRawPtr<LoadFontCallback>, ExecutionContext*);

private:
    FontFace();
    FontFace(ExecutionContext*, const AtomicString& family, const Dictionary& descriptors);

    void initCSSFontFace(Document*, PassRefPtrWillBeRawPtr<CSSValue> src);
    void initCSSFontFace(const unsigned char* data, unsigned size);
    void setPropertyFromString(const Document*, const String&, CSSPropertyID, ExceptionState* = 0);
    bool setPropertyFromStyle(const StylePropertySet&, CSSPropertyID);
    bool setPropertyValue(PassRefPtrWillBeRawPtr<CSSValue>, CSSPropertyID);
    bool setFamilyValue(CSSValueList*);
    void loadInternal(ExecutionContext*);
    ScriptPromise fontStatusPromise(ScriptState*);

    typedef ScriptPromiseProperty<RawPtrWillBeMember<FontFace>, RawPtrWillBeMember<FontFace>, RefPtrWillBeMember<DOMException> > LoadedProperty;

    AtomicString m_family;
    RefPtrWillBeMember<CSSValue> m_src;
    RefPtrWillBeMember<CSSValue> m_style;
    RefPtrWillBeMember<CSSValue> m_weight;
    RefPtrWillBeMember<CSSValue> m_stretch;
    RefPtrWillBeMember<CSSValue> m_unicodeRange;
    RefPtrWillBeMember<CSSValue> m_variant;
    RefPtrWillBeMember<CSSValue> m_featureSettings;
    LoadStatus m_status;
    RefPtrWillBeMember<DOMException> m_error;

    PersistentWillBeMember<LoadedProperty> m_loadedProperty;
    OwnPtrWillBeMember<CSSFontFace> m_cssFontFace;
    WillBeHeapVector<RefPtrWillBeMember<LoadFontCallback> > m_callbacks;
};

typedef WillBeHeapVector<RefPtrWillBeMember<FontFace> > FontFaceArray;

} // namespace blink

#endif // FontFace_h
