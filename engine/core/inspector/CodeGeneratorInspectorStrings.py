# Copyright (c) 2013 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# THis file contains string resources for CodeGeneratorInspector.
# Its syntax is a Python syntax subset, suitable for manual parsing.

frontend_domain_class = (
"""    class $domainClassName {
    public:
        $domainClassName(InspectorFrontendChannel* inspectorFrontendChannel) : m_inspectorFrontendChannel(inspectorFrontendChannel) { }
${frontendDomainMethodDeclarations}
        void flush() { m_inspectorFrontendChannel->flush(); }
    private:
        InspectorFrontendChannel* m_inspectorFrontendChannel;
    };

    $domainClassName* $domainFieldName() { return &m_$domainFieldName; }

""")

backend_method = (
"""void InspectorBackendDispatcherImpl::${domainName}_$methodName(long callId, JSONObject*$requestMessageObject, JSONArray* protocolErrors)
{
    if (!$agentField)
        protocolErrors->pushString("${domainName} handler is not available.");
$methodCode
    if (protocolErrors->length()) {
        reportProtocolError(&callId, InvalidParams, String::format(InvalidParamsFormatString, commandName($commandNameIndex)), protocolErrors);
        return;
    }
$agentCallParamsDeclaration
    $agentField->$methodName($agentCallParams);
$responseCook
    sendResponse(callId, $sendResponseCallParams);
}
""")

frontend_method = ("""void InspectorFrontend::$domainName::$eventName($parameters)
{
    RefPtr<JSONObject> jsonMessage = JSONObject::create();
    jsonMessage->setString("method", "$domainName.$eventName");
$code    if (m_inspectorFrontendChannel)
        m_inspectorFrontendChannel->sendMessageToFrontend(jsonMessage.release());
}
""")

callback_main_methods = (
"""InspectorBackendDispatcher::$agentName::$callbackName::$callbackName(PassRefPtr<InspectorBackendDispatcherImpl> backendImpl, int id) : CallbackBase(backendImpl, id) {}

void InspectorBackendDispatcher::$agentName::$callbackName::sendSuccess($parameters)
{
    RefPtr<JSONObject> jsonMessage = JSONObject::create();
$code    sendIfActive(jsonMessage, ErrorString(), PassRefPtr<JSONValue>());
}
""")

callback_failure_method = (
"""void InspectorBackendDispatcher::$agentName::$callbackName::sendFailure(const ErrorString& error, $parameter)
{
    ASSERT(error.length());
    RefPtr<JSONValue> errorDataValue;
    if (error) {
        errorDataValue = $argument;
    }
    sendIfActive(nullptr, error, errorDataValue.release());
}
""")


frontend_h = (
"""#ifndef InspectorFrontend_h
#define InspectorFrontend_h

#include "InspectorTypeBuilder.h"
#include "core/inspector/InspectorFrontendChannel.h"
#include "platform/JSONValues.h"
#include "wtf/PassRefPtr.h"
#include "wtf/text/WTFString.h"

namespace blink {

typedef String ErrorString;

class InspectorFrontend {
public:
    InspectorFrontend(InspectorFrontendChannel*);
    InspectorFrontendChannel* channel() { return m_inspectorFrontendChannel; }

$domainClassList
private:
    InspectorFrontendChannel* m_inspectorFrontendChannel;
${fieldDeclarations}};

} // namespace blink
#endif // !defined(InspectorFrontend_h)
""")

backend_h = (
"""#ifndef InspectorBackendDispatcher_h
#define InspectorBackendDispatcher_h

#include "InspectorTypeBuilder.h"

#include "platform/heap/Handle.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/text/WTFString.h"

namespace blink {

class JSONObject;
class JSONArray;
class InspectorFrontendChannel;

typedef String ErrorString;

class InspectorBackendDispatcherImpl;

class InspectorBackendDispatcher: public RefCounted<InspectorBackendDispatcher> {
public:
    static PassRefPtr<InspectorBackendDispatcher> create(InspectorFrontendChannel* inspectorFrontendChannel);
    virtual ~InspectorBackendDispatcher() { }

    class CallbackBase: public RefCounted<CallbackBase> {
    public:
        CallbackBase(PassRefPtr<InspectorBackendDispatcherImpl> backendImpl, int id);
        virtual ~CallbackBase();
        void sendFailure(const ErrorString&);
        bool isActive();

    protected:
        void sendIfActive(PassRefPtr<JSONObject> partialMessage, const ErrorString& invocationError, PassRefPtr<JSONValue> errorData);

    private:
        void disable() { m_alreadySent = true; }

        RefPtr<InspectorBackendDispatcherImpl> m_backendImpl;
        int m_id;
        bool m_alreadySent;

        friend class InspectorBackendDispatcherImpl;
    };

$agentInterfaces
$virtualSetters

    virtual void clearFrontend() = 0;

    enum CommonErrorCode {
        ParseError = 0,
        InvalidRequest,
        MethodNotFound,
        InvalidParams,
        InternalError,
        ServerError,
        LastEntry,
    };

    void reportProtocolError(const long* const callId, CommonErrorCode, const String& errorMessage) const;
    virtual void reportProtocolError(const long* const callId, CommonErrorCode, const String& errorMessage, PassRefPtr<JSONValue> data) const = 0;
    virtual void dispatch(const String& message) = 0;
    static bool getCommandName(const String& message, String* result);

    enum MethodNames {
$methodNamesEnumContent

        kMethodNamesEnumSize
    };

    static const char* commandName(MethodNames);

private:
    static const char commandNames[];
    static const size_t commandNamesIndex[];
};

} // namespace blink
#endif // !defined(InspectorBackendDispatcher_h)


""")

backend_cpp = (
"""

#include "config.h"
#include "InspectorBackendDispatcher.h"

#include "core/inspector/InspectorFrontendChannel.h"
#include "core/inspector/JSONParser.h"
#include "platform/JSONValues.h"
#include "wtf/text/CString.h"
#include "wtf/text/WTFString.h"

namespace blink {

const char InspectorBackendDispatcher::commandNames[] = {
$methodNameDeclarations
};

const size_t InspectorBackendDispatcher::commandNamesIndex[] = {
$methodNameDeclarationsIndex
};

const char* InspectorBackendDispatcher::commandName(MethodNames index) {
    COMPILE_ASSERT(static_cast<int>(kMethodNamesEnumSize) == WTF_ARRAY_LENGTH(commandNamesIndex), command_name_array_problem);
    return commandNames + commandNamesIndex[index];
}

class InspectorBackendDispatcherImpl : public InspectorBackendDispatcher {
public:
    InspectorBackendDispatcherImpl(InspectorFrontendChannel* inspectorFrontendChannel)
        : m_inspectorFrontendChannel(inspectorFrontendChannel)
$constructorInit
    { }

    virtual void clearFrontend() { m_inspectorFrontendChannel = 0; }
    virtual void dispatch(const String& message);
    virtual void reportProtocolError(const long* const callId, CommonErrorCode, const String& errorMessage, PassRefPtr<JSONValue> data) const;
    using InspectorBackendDispatcher::reportProtocolError;

    void sendResponse(long callId, const ErrorString& invocationError, PassRefPtr<JSONValue> errorData, PassRefPtr<JSONObject> result);
    bool isActive() { return m_inspectorFrontendChannel; }

$setters
private:
$methodDeclarations

    InspectorFrontendChannel* m_inspectorFrontendChannel;
$fieldDeclarations

    template<typename R, typename V, typename V0>
    static R getPropertyValueImpl(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors, V0 initial_value, bool (*as_method)(JSONValue*, V*), const char* type_name);

    static int getInt(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors);
    static double getDouble(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors);
    static String getString(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors);
    static bool getBoolean(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors);
    static PassRefPtr<JSONObject> getObject(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors);
    static PassRefPtr<JSONArray> getArray(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors);

    void sendResponse(long callId, ErrorString invocationError, PassRefPtr<JSONObject> result)
    {
        sendResponse(callId, invocationError, RefPtr<JSONValue>(), result);
    }
    void sendResponse(long callId, ErrorString invocationError)
    {
        sendResponse(callId, invocationError, RefPtr<JSONValue>(), JSONObject::create());
    }
    static const char InvalidParamsFormatString[];
};

const char InspectorBackendDispatcherImpl::InvalidParamsFormatString[] = "Some arguments of method '%s' can't be processed";

$methods

PassRefPtr<InspectorBackendDispatcher> InspectorBackendDispatcher::create(InspectorFrontendChannel* inspectorFrontendChannel)
{
    return adoptRef(new InspectorBackendDispatcherImpl(inspectorFrontendChannel));
}


void InspectorBackendDispatcherImpl::dispatch(const String& message)
{
    RefPtr<InspectorBackendDispatcher> protect(this);
    typedef void (InspectorBackendDispatcherImpl::*CallHandler)(long callId, JSONObject* messageObject, JSONArray* protocolErrors);
    typedef HashMap<String, CallHandler> DispatchMap;
    DEFINE_STATIC_LOCAL(DispatchMap, dispatchMap, );
    long callId = 0;

    if (dispatchMap.isEmpty()) {
        static const CallHandler handlers[] = {
$messageHandlers
        };
        for (size_t i = 0; i < kMethodNamesEnumSize; ++i)
            dispatchMap.add(commandName(static_cast<MethodNames>(i)), handlers[i]);
    }

    RefPtr<JSONValue> parsedMessage = parseJSON(message);
    if (!parsedMessage) {
        reportProtocolError(0, ParseError, "Message must be in JSON format");
        return;
    }

    RefPtr<JSONObject> messageObject = parsedMessage->asObject();
    if (!messageObject) {
        reportProtocolError(0, InvalidRequest, "Message must be a JSONified object");
        return;
    }

    RefPtr<JSONValue> callIdValue = messageObject->get("id");
    if (!callIdValue) {
        reportProtocolError(0, InvalidRequest, "'id' property was not found");
        return;
    }

    if (!callIdValue->asNumber(&callId)) {
        reportProtocolError(0, InvalidRequest, "The type of 'id' property must be number");
        return;
    }

    RefPtr<JSONValue> methodValue = messageObject->get("method");
    if (!methodValue) {
        reportProtocolError(&callId, InvalidRequest, "'method' property wasn't found");
        return;
    }

    String method;
    if (!methodValue->asString(&method)) {
        reportProtocolError(&callId, InvalidRequest, "The type of 'method' property must be string");
        return;
    }

    HashMap<String, CallHandler>::iterator it = dispatchMap.find(method);
    if (it == dispatchMap.end()) {
        reportProtocolError(&callId, MethodNotFound, "'" + method + "' wasn't found");
        return;
    }

    RefPtr<JSONArray> protocolErrors = JSONArray::create();
    ((*this).*it->value)(callId, messageObject.get(), protocolErrors.get());
}

void InspectorBackendDispatcherImpl::sendResponse(long callId, const ErrorString& invocationError, PassRefPtr<JSONValue> errorData, PassRefPtr<JSONObject> result)
{
    if (invocationError.length()) {
        reportProtocolError(&callId, ServerError, invocationError, errorData);
        return;
    }

    RefPtr<JSONObject> responseMessage = JSONObject::create();
    responseMessage->setNumber("id", callId);
    responseMessage->setObject("result", result);
    if (m_inspectorFrontendChannel)
        m_inspectorFrontendChannel->sendMessageToFrontend(responseMessage.release());
}

void InspectorBackendDispatcher::reportProtocolError(const long* const callId, CommonErrorCode code, const String& errorMessage) const
{
    reportProtocolError(callId, code, errorMessage, PassRefPtr<JSONValue>());
}

void InspectorBackendDispatcherImpl::reportProtocolError(const long* const callId, CommonErrorCode code, const String& errorMessage, PassRefPtr<JSONValue> data) const
{
    DEFINE_STATIC_LOCAL(Vector<int>,s_commonErrors,);
    if (!s_commonErrors.size()) {
        s_commonErrors.insert(ParseError, -32700);
        s_commonErrors.insert(InvalidRequest, -32600);
        s_commonErrors.insert(MethodNotFound, -32601);
        s_commonErrors.insert(InvalidParams, -32602);
        s_commonErrors.insert(InternalError, -32603);
        s_commonErrors.insert(ServerError, -32000);
    }
    ASSERT(code >=0);
    ASSERT((unsigned)code < s_commonErrors.size());
    ASSERT(s_commonErrors[code]);
    RefPtr<JSONObject> error = JSONObject::create();
    error->setNumber("code", s_commonErrors[code]);
    error->setString("message", errorMessage);
    ASSERT(error);
    if (data)
        error->setValue("data", data);
    RefPtr<JSONObject> message = JSONObject::create();
    message->setObject("error", error);
    if (callId)
        message->setNumber("id", *callId);
    else
        message->setValue("id", JSONValue::null());
    if (m_inspectorFrontendChannel)
        m_inspectorFrontendChannel->sendMessageToFrontend(message.release());
}

template<typename R, typename V, typename V0>
R InspectorBackendDispatcherImpl::getPropertyValueImpl(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors, V0 initial_value, bool (*as_method)(JSONValue*, V*), const char* type_name)
{
    ASSERT(protocolErrors);

    if (valueFound)
        *valueFound = false;

    V value = initial_value;

    if (!object) {
        if (!valueFound) {
            // Required parameter in missing params container.
            protocolErrors->pushString(String::format("'params' object must contain required parameter '%s' with type '%s'.", name, type_name));
        }
        return value;
    }

    JSONObject::const_iterator end = object->end();
    JSONObject::const_iterator valueIterator = object->find(name);

    if (valueIterator == end) {
        if (!valueFound)
            protocolErrors->pushString(String::format("Parameter '%s' with type '%s' was not found.", name, type_name));
        return value;
    }

    if (!as_method(valueIterator->value.get(), &value))
        protocolErrors->pushString(String::format("Parameter '%s' has wrong type. It must be '%s'.", name, type_name));
    else
        if (valueFound)
            *valueFound = true;
    return value;
}

struct AsMethodBridges {
    static bool asInt(JSONValue* value, int* output) { return value->asNumber(output); }
    static bool asDouble(JSONValue* value, double* output) { return value->asNumber(output); }
    static bool asString(JSONValue* value, String* output) { return value->asString(output); }
    static bool asBoolean(JSONValue* value, bool* output) { return value->asBoolean(output); }
    static bool asObject(JSONValue* value, RefPtr<JSONObject>* output) { return value->asObject(output); }
    static bool asArray(JSONValue* value, RefPtr<JSONArray>* output) { return value->asArray(output); }
};

int InspectorBackendDispatcherImpl::getInt(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors)
{
    return getPropertyValueImpl<int, int, int>(object, name, valueFound, protocolErrors, 0, AsMethodBridges::asInt, "Number");
}

double InspectorBackendDispatcherImpl::getDouble(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors)
{
    return getPropertyValueImpl<double, double, double>(object, name, valueFound, protocolErrors, 0, AsMethodBridges::asDouble, "Number");
}

String InspectorBackendDispatcherImpl::getString(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors)
{
    return getPropertyValueImpl<String, String, String>(object, name, valueFound, protocolErrors, "", AsMethodBridges::asString, "String");
}

bool InspectorBackendDispatcherImpl::getBoolean(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors)
{
    return getPropertyValueImpl<bool, bool, bool>(object, name, valueFound, protocolErrors, false, AsMethodBridges::asBoolean, "Boolean");
}

PassRefPtr<JSONObject> InspectorBackendDispatcherImpl::getObject(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors)
{
    return getPropertyValueImpl<PassRefPtr<JSONObject>, RefPtr<JSONObject>, JSONObject*>(object, name, valueFound, protocolErrors, 0, AsMethodBridges::asObject, "Object");
}

PassRefPtr<JSONArray> InspectorBackendDispatcherImpl::getArray(JSONObject* object, const char* name, bool* valueFound, JSONArray* protocolErrors)
{
    return getPropertyValueImpl<PassRefPtr<JSONArray>, RefPtr<JSONArray>, JSONArray*>(object, name, valueFound, protocolErrors, 0, AsMethodBridges::asArray, "Array");
}

bool InspectorBackendDispatcher::getCommandName(const String& message, String* result)
{
    RefPtr<JSONValue> value = parseJSON(message);
    if (!value)
        return false;

    RefPtr<JSONObject> object = value->asObject();
    if (!object)
        return false;

    if (!object->getString("method", result))
        return false;

    return true;
}

InspectorBackendDispatcher::CallbackBase::CallbackBase(PassRefPtr<InspectorBackendDispatcherImpl> backendImpl, int id)
    : m_backendImpl(backendImpl), m_id(id), m_alreadySent(false) {}

InspectorBackendDispatcher::CallbackBase::~CallbackBase() {}

void InspectorBackendDispatcher::CallbackBase::sendFailure(const ErrorString& error)
{
    ASSERT(error.length());
    sendIfActive(nullptr, error, PassRefPtr<JSONValue>());
}

bool InspectorBackendDispatcher::CallbackBase::isActive()
{
    return !m_alreadySent && m_backendImpl->isActive();
}

void InspectorBackendDispatcher::CallbackBase::sendIfActive(PassRefPtr<JSONObject> partialMessage, const ErrorString& invocationError, PassRefPtr<JSONValue> errorData)
{
    if (m_alreadySent)
        return;
    m_backendImpl->sendResponse(m_id, invocationError, errorData, partialMessage);
    m_alreadySent = true;
}

} // namespace blink

""")

frontend_cpp = (
"""

#include "config.h"
#include "InspectorFrontend.h"

#include "core/inspector/InspectorFrontendChannel.h"
#include "platform/JSONValues.h"
#include "wtf/text/CString.h"
#include "wtf/text/WTFString.h"

namespace blink {

InspectorFrontend::InspectorFrontend(InspectorFrontendChannel* inspectorFrontendChannel)
    : m_inspectorFrontendChannel(inspectorFrontendChannel)
    , $constructorInit
{
}

$methods

} // namespace blink

""")

typebuilder_h = (
"""
#ifndef InspectorTypeBuilder_h
#define InspectorTypeBuilder_h

#include "platform/JSONValues.h"
#include "wtf/Assertions.h"
#include "wtf/PassRefPtr.h"

namespace blink {

namespace TypeBuilder {

template<typename T>
class OptOutput {
public:
    OptOutput() : m_assigned(false) { }

    void operator=(T value)
    {
        m_value = value;
        m_assigned = true;
    }

    bool isAssigned() { return m_assigned; }

    T getValue()
    {
        ASSERT(isAssigned());
        return m_value;
    }

private:
    T m_value;
    bool m_assigned;

    WTF_MAKE_NONCOPYABLE(OptOutput);
};


// A small transient wrapper around int type, that can be used as a funciton parameter type
// cleverly disallowing C++ implicit casts from float or double.
class ExactlyInt {
public:
    template<typename T>
    ExactlyInt(T t) : m_value(cast_to_int<T>(t)) {}

    ExactlyInt() {}

    operator int() { return m_value; }
private:
    int m_value;

    template<typename T>
    static int cast_to_int(T) { return T::default_case_cast_is_not_supported(); }
};

template<>
inline int ExactlyInt::cast_to_int<int>(int i) { return i; }

template<>
inline int ExactlyInt::cast_to_int<unsigned int>(unsigned int i) { return i; }

class RuntimeCastHelper {
public:
#if $validatorIfdefName
    template<JSONValue::Type TYPE>
    static void assertType(JSONValue* value)
    {
        ASSERT(value->type() == TYPE);
    }
    static void assertAny(JSONValue*);
    static void assertInt(JSONValue* value);
#endif
};


// This class provides "Traits" type for the input type T. It is programmed using C++ template specialization
// technique. By default it simply takes "ItemTraits" type from T, but it doesn't work with the base types.
template<typename T>
struct ArrayItemHelper {
    typedef typename T::ItemTraits Traits;
};

template<typename T>
class Array : public JSONArrayBase {
private:
    Array() { }

    JSONArray* openAccessors() {
        COMPILE_ASSERT(sizeof(JSONArray) == sizeof(Array<T>), cannot_cast);
        return static_cast<JSONArray*>(static_cast<JSONArrayBase*>(this));
    }

public:
    void addItem(PassRefPtr<T> value)
    {
        ArrayItemHelper<T>::Traits::pushRefPtr(this->openAccessors(), value);
    }

    void addItem(T value)
    {
        ArrayItemHelper<T>::Traits::pushRaw(this->openAccessors(), value);
    }

    static PassRefPtr<Array<T> > create()
    {
        return adoptRef(new Array<T>());
    }

    static PassRefPtr<Array<T> > runtimeCast(PassRefPtr<JSONValue> value)
    {
        RefPtr<JSONArray> array;
        bool castRes = value->asArray(&array);
        ASSERT_UNUSED(castRes, castRes);
#if $validatorIfdefName
        assertCorrectValue(array.get());
#endif  // $validatorIfdefName
        COMPILE_ASSERT(sizeof(Array<T>) == sizeof(JSONArray), type_cast_problem);
        return static_cast<Array<T>*>(static_cast<JSONArrayBase*>(array.get()));
    }

    void concat(PassRefPtr<Array<T> > array)
    {
        return ArrayItemHelper<T>::Traits::concat(this->openAccessors(), array->openAccessors());
    }

#if $validatorIfdefName
    static void assertCorrectValue(JSONValue* value)
    {
        RefPtr<JSONArray> array;
        bool castRes = value->asArray(&array);
        ASSERT_UNUSED(castRes, castRes);
        for (unsigned i = 0; i < array->length(); i++)
            ArrayItemHelper<T>::Traits::template assertCorrectValue<T>(array->get(i).get());
    }

#endif // $validatorIfdefName
};

struct StructItemTraits {
    static void pushRefPtr(JSONArray* array, PassRefPtr<JSONValue> value)
    {
        array->pushValue(value);
    }

    static void concat(JSONArray* array, JSONArray* anotherArray)
    {
        for (JSONArray::iterator it = anotherArray->begin(); it != anotherArray->end(); ++it)
            array->pushValue(*it);
    }

#if $validatorIfdefName
    template<typename T>
    static void assertCorrectValue(JSONValue* value) {
        T::assertCorrectValue(value);
    }
#endif  // $validatorIfdefName
};

template<>
struct ArrayItemHelper<String> {
    struct Traits {
        static void pushRaw(JSONArray* array, const String& value)
        {
            array->pushString(value);
        }

#if $validatorIfdefName
        template<typename T>
        static void assertCorrectValue(JSONValue* value) {
            RuntimeCastHelper::assertType<JSONValue::TypeString>(value);
        }
#endif  // $validatorIfdefName
    };
};

template<>
struct ArrayItemHelper<int> {
    struct Traits {
        static void pushRaw(JSONArray* array, int value)
        {
            array->pushInt(value);
        }

#if $validatorIfdefName
        template<typename T>
        static void assertCorrectValue(JSONValue* value) {
            RuntimeCastHelper::assertInt(value);
        }
#endif  // $validatorIfdefName
    };
};

template<>
struct ArrayItemHelper<double> {
    struct Traits {
        static void pushRaw(JSONArray* array, double value)
        {
            array->pushNumber(value);
        }

#if $validatorIfdefName
        template<typename T>
        static void assertCorrectValue(JSONValue* value) {
            RuntimeCastHelper::assertType<JSONValue::TypeNumber>(value);
        }
#endif  // $validatorIfdefName
    };
};

template<>
struct ArrayItemHelper<bool> {
    struct Traits {
        static void pushRaw(JSONArray* array, bool value)
        {
            array->pushBoolean(value);
        }

#if $validatorIfdefName
        template<typename T>
        static void assertCorrectValue(JSONValue* value) {
            RuntimeCastHelper::assertType<JSONValue::TypeBoolean>(value);
        }
#endif  // $validatorIfdefName
    };
};

template<>
struct ArrayItemHelper<JSONValue> {
    struct Traits {
        static void pushRefPtr(JSONArray* array, PassRefPtr<JSONValue> value)
        {
            array->pushValue(value);
        }

#if $validatorIfdefName
        template<typename T>
        static void assertCorrectValue(JSONValue* value) {
            RuntimeCastHelper::assertAny(value);
        }
#endif  // $validatorIfdefName
    };
};

template<>
struct ArrayItemHelper<JSONObject> {
    struct Traits {
        static void pushRefPtr(JSONArray* array, PassRefPtr<JSONValue> value)
        {
            array->pushValue(value);
        }

#if $validatorIfdefName
        template<typename T>
        static void assertCorrectValue(JSONValue* value) {
            RuntimeCastHelper::assertType<JSONValue::TypeObject>(value);
        }
#endif  // $validatorIfdefName
    };
};

template<>
struct ArrayItemHelper<JSONArray> {
    struct Traits {
        static void pushRefPtr(JSONArray* array, PassRefPtr<JSONArray> value)
        {
            array->pushArray(value);
        }

#if $validatorIfdefName
        template<typename T>
        static void assertCorrectValue(JSONValue* value) {
            RuntimeCastHelper::assertType<JSONValue::TypeArray>(value);
        }
#endif  // $validatorIfdefName
    };
};

template<typename T>
struct ArrayItemHelper<TypeBuilder::Array<T> > {
    struct Traits {
        static void pushRefPtr(JSONArray* array, PassRefPtr<TypeBuilder::Array<T> > value)
        {
            array->pushValue(value);
        }

#if $validatorIfdefName
        template<typename S>
        static void assertCorrectValue(JSONValue* value) {
            S::assertCorrectValue(value);
        }
#endif  // $validatorIfdefName
    };
};

${forwards}

String getEnumConstantValue(int code);

${typeBuilders}
} // namespace TypeBuilder


} // namespace blink

#endif // !defined(InspectorTypeBuilder_h)

""")

typebuilder_cpp = (
"""

#include "config.h"

#include "InspectorTypeBuilder.h"
#include "wtf/text/CString.h"

namespace blink {

namespace TypeBuilder {

const char* const enum_constant_values[] = {
$enumConstantValues};

String getEnumConstantValue(int code) {
    return enum_constant_values[code];
}

} // namespace TypeBuilder

$implCode

#if $validatorIfdefName

void TypeBuilder::RuntimeCastHelper::assertAny(JSONValue*)
{
    // No-op.
}


void TypeBuilder::RuntimeCastHelper::assertInt(JSONValue* value)
{
    double v;
    bool castRes = value->asNumber(&v);
    ASSERT_UNUSED(castRes, castRes);
    ASSERT(static_cast<double>(static_cast<int>(v)) == v);
}

$validatorCode

#endif // $validatorIfdefName

} // namespace blink

""")

param_container_access_code = """
    RefPtr<JSONObject> paramsContainer = requestMessageObject->getObject("params");
    JSONObject* paramsContainerPtr = paramsContainer.get();
"""

class_binding_builder_part_1 = (
"""        AllFieldsSet = %s
    };

    template<int STATE>
    class Builder {
    private:
        RefPtr<JSONObject> m_result;

        template<int STEP> Builder<STATE | STEP>& castState()
        {
            return *reinterpret_cast<Builder<STATE | STEP>*>(this);
        }

        Builder(PassRefPtr</*%s*/JSONObject> ptr)
        {
            COMPILE_ASSERT(STATE == NoFieldsSet, builder_created_in_non_init_state);
            m_result = ptr;
        }
        friend class %s;
    public:
""")

class_binding_builder_part_2 = ("""
        Builder<STATE | %s>& set%s(%s value)
        {
            COMPILE_ASSERT(!(STATE & %s), property_%s_already_set);
            m_result->set%s("%s", %s);
            return castState<%s>();
        }
""")

class_binding_builder_part_3 = ("""
        operator RefPtr<%s>& ()
        {
            COMPILE_ASSERT(STATE == AllFieldsSet, result_is_not_ready);
            COMPILE_ASSERT(sizeof(%s) == sizeof(JSONObject), cannot_cast);
            return *reinterpret_cast<RefPtr<%s>*>(&m_result);
        }

        PassRefPtr<%s> release()
        {
            return RefPtr<%s>(*this).release();
        }
    };

""")

class_binding_builder_part_4 = (
"""    static Builder<NoFieldsSet> create()
    {
        return Builder<NoFieldsSet>(JSONObject::create());
    }
""")
