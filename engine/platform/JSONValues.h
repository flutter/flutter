/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef JSONValues_h
#define JSONValues_h

#include "platform/PlatformExport.h"
#include "wtf/Forward.h"
#include "wtf/HashMap.h"
#include "wtf/RefCounted.h"
#include "wtf/Vector.h"
#include "wtf/text/StringHash.h"
#include "wtf/text/WTFString.h"

namespace blink {

class JSONArray;
class JSONObject;

class PLATFORM_EXPORT JSONValue : public RefCounted<JSONValue> {
public:
    static const int maxDepth = 1000;

    JSONValue() : m_type(TypeNull) { }
    virtual ~JSONValue() { }

    static PassRefPtr<JSONValue> null()
    {
        return adoptRef(new JSONValue());
    }

    typedef enum {
        TypeNull = 0,
        TypeBoolean,
        TypeNumber,
        TypeString,
        TypeObject,
        TypeArray
    } Type;

    Type type() const { return m_type; }

    bool isNull() const { return m_type == TypeNull; }

    virtual bool asBoolean(bool* output) const;
    virtual bool asNumber(double* output) const;
    virtual bool asNumber(long* output) const;
    virtual bool asNumber(int* output) const;
    virtual bool asNumber(unsigned long* output) const;
    virtual bool asNumber(unsigned* output) const;
    virtual bool asString(String* output) const;
    virtual bool asValue(RefPtr<JSONValue>* output);
    virtual bool asObject(RefPtr<JSONObject>* output);
    virtual bool asArray(RefPtr<JSONArray>* output);
    virtual PassRefPtr<JSONObject> asObject();
    virtual PassRefPtr<JSONArray> asArray();

    String toJSONString() const;
    String toPrettyJSONString() const;
    virtual void writeJSON(StringBuilder* output) const;
    virtual void prettyWriteJSON(StringBuilder* output) const;

protected:
    explicit JSONValue(Type type) : m_type(type) { }
    virtual void prettyWriteJSONInternal(StringBuilder* output, int depth) const;

private:
    friend class JSONObjectBase;
    friend class JSONArrayBase;

    Type m_type;
};

class PLATFORM_EXPORT JSONBasicValue : public JSONValue {
public:

    static PassRefPtr<JSONBasicValue> create(bool value)
    {
        return adoptRef(new JSONBasicValue(value));
    }

    static PassRefPtr<JSONBasicValue> create(int value)
    {
        return adoptRef(new JSONBasicValue(value));
    }

    static PassRefPtr<JSONBasicValue> create(double value)
    {
        return adoptRef(new JSONBasicValue(value));
    }

    virtual bool asBoolean(bool* output) const OVERRIDE;
    virtual bool asNumber(double* output) const OVERRIDE;
    virtual bool asNumber(long* output) const OVERRIDE;
    virtual bool asNumber(int* output) const OVERRIDE;
    virtual bool asNumber(unsigned long* output) const OVERRIDE;
    virtual bool asNumber(unsigned* output) const OVERRIDE;

    virtual void writeJSON(StringBuilder* output) const OVERRIDE;

private:
    explicit JSONBasicValue(bool value) : JSONValue(TypeBoolean), m_boolValue(value) { }
    explicit JSONBasicValue(int value) : JSONValue(TypeNumber), m_doubleValue((double)value) { }
    explicit JSONBasicValue(double value) : JSONValue(TypeNumber), m_doubleValue(value) { }

    union {
        bool m_boolValue;
        double m_doubleValue;
    };
};

class PLATFORM_EXPORT JSONString : public JSONValue {
public:
    static PassRefPtr<JSONString> create(const String& value)
    {
        return adoptRef(new JSONString(value));
    }

    static PassRefPtr<JSONString> create(const char* value)
    {
        return adoptRef(new JSONString(value));
    }

    virtual bool asString(String* output) const OVERRIDE;

    virtual void writeJSON(StringBuilder* output) const OVERRIDE;

private:
    explicit JSONString(const String& value) : JSONValue(TypeString), m_stringValue(value) { }
    explicit JSONString(const char* value) : JSONValue(TypeString), m_stringValue(value) { }

    String m_stringValue;
};

class PLATFORM_EXPORT JSONObjectBase : public JSONValue {
private:
    typedef HashMap<String, RefPtr<JSONValue> > Dictionary;

public:
    typedef Dictionary::iterator iterator;
    typedef Dictionary::const_iterator const_iterator;

    virtual PassRefPtr<JSONObject> asObject() OVERRIDE;
    JSONObject* openAccessors();

    virtual void writeJSON(StringBuilder* output) const OVERRIDE;

protected:
    virtual ~JSONObjectBase();

    virtual bool asObject(RefPtr<JSONObject>* output) OVERRIDE;

    void setBoolean(const String& name, bool);
    void setNumber(const String& name, double);
    void setString(const String& name, const String&);
    void setValue(const String& name, PassRefPtr<JSONValue>);
    void setObject(const String& name, PassRefPtr<JSONObject>);
    void setArray(const String& name, PassRefPtr<JSONArray>);

    iterator find(const String& name);
    const_iterator find(const String& name) const;
    bool getBoolean(const String& name, bool* output) const;
    template<class T> bool getNumber(const String& name, T* output) const
    {
        RefPtr<JSONValue> value = get(name);
        if (!value)
            return false;
        return value->asNumber(output);
    }
    bool getString(const String& name, String* output) const;
    PassRefPtr<JSONObject> getObject(const String& name) const;
    PassRefPtr<JSONArray> getArray(const String& name) const;
    PassRefPtr<JSONValue> get(const String& name) const;

    void remove(const String& name);

    virtual void prettyWriteJSONInternal(StringBuilder* output, int depth) const OVERRIDE;

    iterator begin() { return m_data.begin(); }
    iterator end() { return m_data.end(); }
    const_iterator begin() const { return m_data.begin(); }
    const_iterator end() const { return m_data.end(); }

    int size() const { return m_data.size(); }

protected:
    JSONObjectBase();

private:
    Dictionary m_data;
    Vector<String> m_order;
};

class PLATFORM_EXPORT JSONObject : public JSONObjectBase {
public:
    static PassRefPtr<JSONObject> create()
    {
        return adoptRef(new JSONObject());
    }

    using JSONObjectBase::asObject;

    using JSONObjectBase::setBoolean;
    using JSONObjectBase::setNumber;
    using JSONObjectBase::setString;
    using JSONObjectBase::setValue;
    using JSONObjectBase::setObject;
    using JSONObjectBase::setArray;

    using JSONObjectBase::find;
    using JSONObjectBase::getBoolean;
    using JSONObjectBase::getNumber;
    using JSONObjectBase::getString;
    using JSONObjectBase::getObject;
    using JSONObjectBase::getArray;
    using JSONObjectBase::get;

    using JSONObjectBase::remove;

    using JSONObjectBase::begin;
    using JSONObjectBase::end;

    using JSONObjectBase::size;
};


class PLATFORM_EXPORT JSONArrayBase : public JSONValue {
public:
    typedef Vector<RefPtr<JSONValue> >::iterator iterator;
    typedef Vector<RefPtr<JSONValue> >::const_iterator const_iterator;

    virtual PassRefPtr<JSONArray> asArray() OVERRIDE;

    unsigned length() const { return m_data.size(); }

    virtual void writeJSON(StringBuilder* output) const OVERRIDE;

protected:
    virtual ~JSONArrayBase();

    virtual bool asArray(RefPtr<JSONArray>* output) OVERRIDE;

    void pushBoolean(bool);
    void pushInt(int);
    void pushNumber(double);
    void pushString(const String&);
    void pushValue(PassRefPtr<JSONValue>);
    void pushObject(PassRefPtr<JSONObject>);
    void pushArray(PassRefPtr<JSONArray>);

    PassRefPtr<JSONValue> get(size_t index);

    virtual void prettyWriteJSONInternal(StringBuilder* output, int depth) const OVERRIDE;

    iterator begin() { return m_data.begin(); }
    iterator end() { return m_data.end(); }
    const_iterator begin() const { return m_data.begin(); }
    const_iterator end() const { return m_data.end(); }

protected:
    JSONArrayBase();

private:
    Vector<RefPtr<JSONValue> > m_data;
};

class PLATFORM_EXPORT JSONArray : public JSONArrayBase {
public:
    static PassRefPtr<JSONArray> create()
    {
        return adoptRef(new JSONArray());
    }

    using JSONArrayBase::asArray;

    using JSONArrayBase::pushBoolean;
    using JSONArrayBase::pushInt;
    using JSONArrayBase::pushNumber;
    using JSONArrayBase::pushString;
    using JSONArrayBase::pushValue;
    using JSONArrayBase::pushObject;
    using JSONArrayBase::pushArray;

    using JSONArrayBase::get;

    using JSONArrayBase::begin;
    using JSONArrayBase::end;
};

} // namespace blink

#endif // !defined(JSONValues_h)
