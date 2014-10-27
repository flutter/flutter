{% extends 'interface_base.cpp' %}


{##############################################################################}
{% block constructor_getter %}
{% if has_constructor_attributes %}
static void {{cpp_class}}ConstructorGetter(v8::Local<v8::String>, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    v8::Handle<v8::Value> data = info.Data();
    ASSERT(data->IsExternal());
    V8PerContextData* perContextData = V8PerContextData::from(info.Holder()->CreationContext());
    if (!perContextData)
        return;
    v8SetReturnValue(info, perContextData->constructorForType(WrapperTypeInfo::unwrap(data)));
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block replaceable_attribute_setter_and_callback %}
{% if has_replaceable_attributes or has_constructor_attributes %}
static void {{cpp_class}}ForceSetAttributeOnThis(v8::Local<v8::String> name, v8::Local<v8::Value> v8Value, const v8::PropertyCallbackInfo<void>& info)
{
    {% if is_check_security %}
    {{cpp_class}}* impl = {{v8_class}}::toNative(info.Holder());
    v8::String::Utf8Value attributeName(name);
    ExceptionState exceptionState(ExceptionState::SetterContext, *attributeName, "{{interface_name}}", info.Holder(), info.GetIsolate());
    if (!BindingSecurity::shouldAllowAccessToFrame(info.GetIsolate(), impl->frame(), exceptionState)) {
        exceptionState.throwIfNeeded();
        return;
    }
    {% endif %}
    if (info.This()->IsObject())
        v8::Handle<v8::Object>::Cast(info.This())->ForceSet(name, v8Value);
}

static void {{cpp_class}}ForceSetAttributeOnThisCallback(v8::Local<v8::String> name, v8::Local<v8::Value> v8Value, const v8::PropertyCallbackInfo<void>& info)
{
    {{cpp_class}}V8Internal::{{cpp_class}}ForceSetAttributeOnThis(name, v8Value, info);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block security_check_functions %}
{% if has_access_check_callbacks %}
bool indexedSecurityCheck(v8::Local<v8::Object> host, uint32_t index, v8::AccessType type, v8::Local<v8::Value>)
{
    {{cpp_class}}* impl = {{v8_class}}::toNative(host);
    return BindingSecurity::shouldAllowAccessToFrame(v8::Isolate::GetCurrent(), impl->frame(), DoNotReportSecurityError);
}

bool namedSecurityCheck(v8::Local<v8::Object> host, v8::Local<v8::Value> key, v8::AccessType type, v8::Local<v8::Value>)
{
    {{cpp_class}}* impl = {{v8_class}}::toNative(host);
    return BindingSecurity::shouldAllowAccessToFrame(v8::Isolate::GetCurrent(), impl->frame(), DoNotReportSecurityError);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block indexed_property_getter %}
{% if indexed_property_getter and not indexed_property_getter.is_custom %}
{% set getter = indexed_property_getter %}
static void indexedPropertyGetter(uint32_t index, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    {{cpp_class}}* impl = {{v8_class}}::toNative(info.Holder());
    {% if getter.is_raises_exception %}
    ExceptionState exceptionState(ExceptionState::IndexedGetterContext, "{{interface_name}}", info.Holder(), info.GetIsolate());
    {% endif %}
    {% set getter_name = getter.name or 'anonymousIndexedGetter' %}
    {% set getter_arguments = ['index', 'exceptionState']
           if getter.is_raises_exception else ['index'] %}
    {{getter.cpp_type}} result = impl->{{getter_name}}({{getter_arguments | join(', ')}});
    {% if getter.is_raises_exception %}
    if (exceptionState.throwIfNeeded())
        return;
    {% endif %}
    if ({{getter.is_null_expression}})
        return;
    {{getter.v8_set_return_value}};
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block indexed_property_getter_callback %}
{% if indexed_property_getter %}
{% set getter = indexed_property_getter %}
static void indexedPropertyGetterCallback(uint32_t index, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    TRACE_EVENT_SET_SAMPLING_STATE("blink", "DOMIndexedProperty");
    {% if getter.is_custom %}
    {{v8_class}}::indexedPropertyGetterCustom(index, info);
    {% else %}
    {{cpp_class}}V8Internal::indexedPropertyGetter(index, info);
    {% endif %}
    TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8Execution");
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block indexed_property_setter %}
{% if indexed_property_setter and not indexed_property_setter.is_custom %}
{% set setter = indexed_property_setter %}
static void indexedPropertySetter(uint32_t index, v8::Local<v8::Value> v8Value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    {{cpp_class}}* impl = {{v8_class}}::toNative(info.Holder());
    {{setter.v8_value_to_local_cpp_value}};
    {% if setter.has_exception_state %}
    ExceptionState exceptionState(ExceptionState::IndexedSetterContext, "{{interface_name}}", info.Holder(), info.GetIsolate());
    {% endif %}
    {% if setter.has_type_checking_interface %}
    {# Type checking for interface types (if interface not implemented, throw
       TypeError), per http://www.w3.org/TR/WebIDL/#es-interface #}
    if (!isUndefinedOrNull(v8Value) && !V8{{setter.idl_type}}::hasInstance(v8Value, info.GetIsolate())) {
        exceptionState.throwTypeError("The provided value is not of type '{{setter.idl_type}}'.");
        exceptionState.throwIfNeeded();
        return;
    }
    {% endif %}
    {% set setter_name = setter.name or 'anonymousIndexedSetter' %}
    {% set setter_arguments = ['index', 'propertyValue', 'exceptionState']
           if setter.is_raises_exception else ['index', 'propertyValue'] %}
    bool result = impl->{{setter_name}}({{setter_arguments | join(', ')}});
    {% if setter.is_raises_exception %}
    if (exceptionState.throwIfNeeded())
        return;
    {% endif %}
    if (!result)
        return;
    v8SetReturnValue(info, v8Value);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block indexed_property_setter_callback %}
{% if indexed_property_setter %}
{% set setter = indexed_property_setter %}
static void indexedPropertySetterCallback(uint32_t index, v8::Local<v8::Value> v8Value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    TRACE_EVENT_SET_SAMPLING_STATE("blink", "DOMIndexedProperty");
    {% if setter.is_custom %}
    {{v8_class}}::indexedPropertySetterCustom(index, v8Value, info);
    {% else %}
    {{cpp_class}}V8Internal::indexedPropertySetter(index, v8Value, info);
    {% endif %}
    TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8Execution");
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block indexed_property_deleter %}
{% if indexed_property_deleter and not indexed_property_deleter.is_custom %}
{% set deleter = indexed_property_deleter %}
static void indexedPropertyDeleter(uint32_t index, const v8::PropertyCallbackInfo<v8::Boolean>& info)
{
    {{cpp_class}}* impl = {{v8_class}}::toNative(info.Holder());
    {% if deleter.is_raises_exception %}
    ExceptionState exceptionState(ExceptionState::IndexedDeletionContext, "{{interface_name}}", info.Holder(), info.GetIsolate());
    {% endif %}
    {% set deleter_name = deleter.name or 'anonymousIndexedDeleter' %}
    {% set deleter_arguments = ['index', 'exceptionState']
           if deleter.is_raises_exception else ['index'] %}
    DeleteResult result = impl->{{deleter_name}}({{deleter_arguments | join(', ')}});
    {% if deleter.is_raises_exception %}
    if (exceptionState.throwIfNeeded())
        return;
    {% endif %}
    if (result != DeleteUnknownProperty)
        return v8SetReturnValueBool(info, result == DeleteSuccess);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block indexed_property_deleter_callback %}
{% if indexed_property_deleter %}
{% set deleter = indexed_property_deleter %}
static void indexedPropertyDeleterCallback(uint32_t index, const v8::PropertyCallbackInfo<v8::Boolean>& info)
{
    TRACE_EVENT_SET_SAMPLING_STATE("blink", "DOMIndexedProperty");
    {% if deleter.is_custom %}
    {{v8_class}}::indexedPropertyDeleterCustom(index, info);
    {% else %}
    {{cpp_class}}V8Internal::indexedPropertyDeleter(index, info);
    {% endif %}
    TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8Execution");
}

{% endif %}
{% endblock %}


{##############################################################################}
{% from 'methods.cpp' import union_type_method_call_and_set_return_value %}
{% block named_property_getter %}
{% if named_property_getter and not named_property_getter.is_custom %}
{% set getter = named_property_getter %}
static void namedPropertyGetter(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    {% if not is_override_builtins %}
    if (info.Holder()->HasRealNamedProperty(name))
        return;
    if (!info.Holder()->GetRealNamedPropertyInPrototypeChain(name).IsEmpty())
        return;

    {% endif %}
    {{cpp_class}}* impl = {{v8_class}}::toNative(info.Holder());
    AtomicString propertyName = toCoreAtomicString(name);
    {% if getter.is_raises_exception %}
    v8::String::Utf8Value namedProperty(name);
    ExceptionState exceptionState(ExceptionState::GetterContext, *namedProperty, "{{interface_name}}", info.Holder(), info.GetIsolate());
    {% endif %}
    {% if getter.union_arguments %}
    {{union_type_method_call_and_set_return_value(getter) | indent}}
    {% else %}
    {{getter.cpp_type}} result = {{getter.cpp_value}};
    {% if getter.is_raises_exception %}
    if (exceptionState.throwIfNeeded())
        return;
    {% endif %}
    if ({{getter.is_null_expression}})
        return;
    {{getter.v8_set_return_value}};
    {% endif %}
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block named_property_getter_callback %}
{% if named_property_getter %}
{% set getter = named_property_getter %}
static void namedPropertyGetterCallback(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    TRACE_EVENT_SET_SAMPLING_STATE("blink", "DOMNamedProperty");
    {% if getter.is_custom %}
    {{v8_class}}::namedPropertyGetterCustom(name, info);
    {% else %}
    {{cpp_class}}V8Internal::namedPropertyGetter(name, info);
    {% endif %}
    TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8Execution");
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block named_property_setter %}
{% if named_property_setter and not named_property_setter.is_custom %}
{% set setter = named_property_setter %}
static void namedPropertySetter(v8::Local<v8::String> name, v8::Local<v8::Value> v8Value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    {% if not is_override_builtins %}
    if (info.Holder()->HasRealNamedProperty(name))
        return;
    if (!info.Holder()->GetRealNamedPropertyInPrototypeChain(name).IsEmpty())
        return;

    {% endif %}
    {{cpp_class}}* impl = {{v8_class}}::toNative(info.Holder());
    {# v8_value_to_local_cpp_value('DOMString', 'name', 'propertyName') #}
    TOSTRING_VOID(V8StringResource<>, propertyName, name);
    {{setter.v8_value_to_local_cpp_value}};
    {% if setter.has_exception_state %}
    v8::String::Utf8Value namedProperty(name);
    ExceptionState exceptionState(ExceptionState::SetterContext, *namedProperty, "{{interface_name}}", info.Holder(), info.GetIsolate());
    {% endif %}
    {% set setter_name = setter.name or 'anonymousNamedSetter' %}
    {% set setter_arguments =
           ['propertyName', 'propertyValue', 'exceptionState']
           if setter.is_raises_exception else
           ['propertyName', 'propertyValue'] %}
    bool result = impl->{{setter_name}}({{setter_arguments | join(', ')}});
    {% if setter.is_raises_exception %}
    if (exceptionState.throwIfNeeded())
        return;
    {% endif %}
    if (!result)
        return;
    v8SetReturnValue(info, v8Value);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block named_property_setter_callback %}
{% if named_property_setter %}
{% set setter = named_property_setter %}
static void namedPropertySetterCallback(v8::Local<v8::String> name, v8::Local<v8::Value> v8Value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    TRACE_EVENT_SET_SAMPLING_STATE("blink", "DOMNamedProperty");
    {% if setter.is_custom %}
    {{v8_class}}::namedPropertySetterCustom(name, v8Value, info);
    {% else %}
    {{cpp_class}}V8Internal::namedPropertySetter(name, v8Value, info);
    {% endif %}
    TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8Execution");
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block named_property_query %}
{% if named_property_getter and named_property_getter.is_enumerable and
      not named_property_getter.is_custom_property_query %}
{# If there is an enumerator, there MUST be a query method to properly
   communicate property attributes. #}
static void namedPropertyQuery(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Integer>& info)
{
    {{cpp_class}}* impl = {{v8_class}}::toNative(info.Holder());
    AtomicString propertyName = toCoreAtomicString(name);
    v8::String::Utf8Value namedProperty(name);
    ExceptionState exceptionState(ExceptionState::GetterContext, *namedProperty, "{{interface_name}}", info.Holder(), info.GetIsolate());
    bool result = impl->namedPropertyQuery(propertyName, exceptionState);
    if (exceptionState.throwIfNeeded())
        return;
    if (!result)
        return;
    v8SetReturnValueInt(info, v8::None);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block named_property_query_callback %}
{% if named_property_getter and named_property_getter.is_enumerable %}
{% set getter = named_property_getter %}
static void namedPropertyQueryCallback(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Integer>& info)
{
    TRACE_EVENT_SET_SAMPLING_STATE("blink", "DOMNamedProperty");
    {% if getter.is_custom_property_query %}
    {{v8_class}}::namedPropertyQueryCustom(name, info);
    {% else %}
    {{cpp_class}}V8Internal::namedPropertyQuery(name, info);
    {% endif %}
    TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8Execution");
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block named_property_deleter %}
{% if named_property_deleter and not named_property_deleter.is_custom %}
{% set deleter = named_property_deleter %}
static void namedPropertyDeleter(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Boolean>& info)
{
    {{cpp_class}}* impl = {{v8_class}}::toNative(info.Holder());
    AtomicString propertyName = toCoreAtomicString(name);
    {% if deleter.is_raises_exception %}
    v8::String::Utf8Value namedProperty(name);
    ExceptionState exceptionState(ExceptionState::DeletionContext, *namedProperty, "{{interface_name}}", info.Holder(), info.GetIsolate());
    {% endif %}
    {% set deleter_name = deleter.name or 'anonymousNamedDeleter' %}
    {% set deleter_arguments = ['propertyName', 'exceptionState']
           if deleter.is_raises_exception else ['propertyName'] %}
    DeleteResult result = impl->{{deleter_name}}({{deleter_arguments | join(', ')}});
    {% if deleter.is_raises_exception %}
    if (exceptionState.throwIfNeeded())
        return;
    {% endif %}
    if (result != DeleteUnknownProperty)
        return v8SetReturnValueBool(info, result == DeleteSuccess);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block named_property_deleter_callback %}
{% if named_property_deleter %}
{% set deleter = named_property_deleter %}
static void namedPropertyDeleterCallback(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Boolean>& info)
{
    TRACE_EVENT_SET_SAMPLING_STATE("blink", "DOMNamedProperty");
    {% if deleter.is_custom %}
    {{v8_class}}::namedPropertyDeleterCustom(name, info);
    {% else %}
    {{cpp_class}}V8Internal::namedPropertyDeleter(name, info);
    {% endif %}
    TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8Execution");
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block named_property_enumerator %}
{% if named_property_getter and named_property_getter.is_enumerable and
      not named_property_getter.is_custom_property_enumerator %}
static void namedPropertyEnumerator(const v8::PropertyCallbackInfo<v8::Array>& info)
{
    {{cpp_class}}* impl = {{v8_class}}::toNative(info.Holder());
    Vector<String> names;
    ExceptionState exceptionState(ExceptionState::EnumerationContext, "{{interface_name}}", info.Holder(), info.GetIsolate());
    impl->namedPropertyEnumerator(names, exceptionState);
    if (exceptionState.throwIfNeeded())
        return;
    v8::Handle<v8::Array> v8names = v8::Array::New(info.GetIsolate(), names.size());
    for (size_t i = 0; i < names.size(); ++i)
        v8names->Set(v8::Integer::New(info.GetIsolate(), i), v8String(info.GetIsolate(), names[i]));
    v8SetReturnValue(info, v8names);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block named_property_enumerator_callback %}
{% if named_property_getter and named_property_getter.is_enumerable %}
{% set getter = named_property_getter %}
static void namedPropertyEnumeratorCallback(const v8::PropertyCallbackInfo<v8::Array>& info)
{
    TRACE_EVENT_SET_SAMPLING_STATE("blink", "DOMNamedProperty");
    {% if getter.is_custom_property_enumerator %}
    {{v8_class}}::namedPropertyEnumeratorCustom(info);
    {% else %}
    {{cpp_class}}V8Internal::namedPropertyEnumerator(info);
    {% endif %}
    TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8Execution");
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block origin_safe_method_setter %}
{% if has_origin_safe_method_setter %}
static void {{cpp_class}}OriginSafeMethodSetter(v8::Local<v8::String> name, v8::Local<v8::Value> v8Value, const v8::PropertyCallbackInfo<void>& info)
{
    v8::Handle<v8::Object> holder = {{v8_class}}::findInstanceInPrototypeChain(info.This(), info.GetIsolate());
    if (holder.IsEmpty())
        return;
    {{cpp_class}}* impl = {{v8_class}}::toNative(holder);
    v8::String::Utf8Value attributeName(name);
    ExceptionState exceptionState(ExceptionState::SetterContext, *attributeName, "{{interface_name}}", info.Holder(), info.GetIsolate());
    if (!BindingSecurity::shouldAllowAccessToFrame(info.GetIsolate(), impl->frame(), exceptionState)) {
        exceptionState.throwIfNeeded();
        return;
    }

    {# The findInstanceInPrototypeChain() call above only returns a non-empty handle if info.This() is an Object. #}
    V8HiddenValue::setHiddenValue(info.GetIsolate(), v8::Handle<v8::Object>::Cast(info.This()), name, v8Value);
}

static void {{cpp_class}}OriginSafeMethodSetterCallback(v8::Local<v8::String> name, v8::Local<v8::Value> v8Value, const v8::PropertyCallbackInfo<void>& info)
{
    TRACE_EVENT_SET_SAMPLING_STATE("blink", "DOMSetter");
    {{cpp_class}}V8Internal::{{cpp_class}}OriginSafeMethodSetter(name, v8Value, info);
    TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8Execution");
}

{% endif %}
{% endblock %}


{##############################################################################}
{% from 'methods.cpp' import generate_constructor with context %}
{% block named_constructor %}
{% if named_constructor %}
{% set to_active_dom_object = '%s::toActiveDOMObject' % v8_class
                              if is_active_dom_object else '0' %}
{% set to_event_target = '%s::toEventTarget' % v8_class
                         if is_event_target else '0' %}
const WrapperTypeInfo {{v8_class}}Constructor::wrapperTypeInfo = { gin::kEmbedderBlink, {{v8_class}}Constructor::domTemplate, {{v8_class}}::refObject, {{v8_class}}::derefObject, {{to_active_dom_object}}, {{to_event_target}}, 0, {{v8_class}}::installConditionallyEnabledMethods, {{v8_class}}::installConditionallyEnabledProperties, 0, WrapperTypeInfo::WrapperTypeObjectPrototype, WrapperTypeInfo::{{wrapper_class_id}}, WrapperTypeInfo::{{lifetime}} };

{{generate_constructor(named_constructor)}}
v8::Handle<v8::FunctionTemplate> {{v8_class}}Constructor::domTemplate(v8::Isolate* isolate)
{
    static int domTemplateKey; // This address is used for a key to look up the dom template.
    V8PerIsolateData* data = V8PerIsolateData::from(isolate);
    v8::Local<v8::FunctionTemplate> result = data->existingDOMTemplate(&domTemplateKey);
    if (!result.IsEmpty())
        return result;

    TRACE_EVENT_SCOPED_SAMPLING_STATE("blink", "BuildDOMTemplate");
    result = v8::FunctionTemplate::New(isolate, {{v8_class}}ConstructorCallback);
    v8::Local<v8::ObjectTemplate> instanceTemplate = result->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount({{v8_class}}::internalFieldCount);
    result->SetClassName(v8AtomicString(isolate, "{{cpp_class}}"));
    result->Inherit({{v8_class}}::domTemplate(isolate));
    data->setDOMTemplate(&domTemplateKey, result);
    return result;
}

{% endif %}
{% endblock %}

{##############################################################################}
{% block overloaded_constructor %}
{% if constructor_overloads %}
static void constructor(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ConstructionContext, "{{interface_name}}", info.Holder(), info.GetIsolate());
    {# 2. Initialize argcount to be min(maxarg, n). #}
    switch (std::min({{constructor_overloads.maxarg}}, info.Length())) {
    {# 3. Remove from S all entries whose type list is not of length argcount. #}
    {% for length, tests_constructors in constructor_overloads.length_tests_methods %}
    case {{length}}:
        {# Then resolve by testing argument #}
        {% for test, constructor in tests_constructors %}
        {# 10. If i = d, then: #}
        if ({{test}}) {
            {{cpp_class}}V8Internal::constructor{{constructor.overload_index}}(info);
            return;
        }
        {% endfor %}
        break;
    {% endfor %}
    default:
        {# Invalid arity, throw error #}
        {# Report full list of valid arities if gaps and above minimum #}
        {% if constructor_overloads.valid_arities %}
        if (info.Length() >= {{constructor_overloads.minarg}}) {
            throwArityTypeError(exceptionState, "{{constructor_overloads.valid_arities}}", info.Length());
            return;
        }
        {% endif %}
        {# Otherwise just report "not enough arguments" #}
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments({{constructor_overloads.minarg}}, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }
    {# No match, throw error #}
    exceptionState.throwTypeError("No matching constructor signature.");
    exceptionState.throwIfNeeded();
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block event_constructor %}
{% if has_event_constructor %}
static void constructor(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ConstructionContext, "{{interface_name}}", info.Holder(), info.GetIsolate());
    if (info.Length() < 1) {
        exceptionState.throwTypeError("An event name must be provided.");
        exceptionState.throwIfNeeded();
        return;
    }

    TOSTRING_VOID(V8StringResource<>, type, info[0]);
    {% for attribute in any_type_attributes %}
    v8::Local<v8::Value> {{attribute.name}};
    {% endfor %}
    {{cpp_class}}Init eventInit;
    if (info.Length() >= 2) {
        TONATIVE_VOID(Dictionary, options, Dictionary(info[1], info.GetIsolate()));
        if (!initialize{{cpp_class}}(eventInit, options, exceptionState, info)) {
            exceptionState.throwIfNeeded();
            return;
        }
        {# Store attributes of type |any| on the wrapper to avoid leaking them
           between isolated worlds. #}
        {% for attribute in any_type_attributes %}
        options.get("{{attribute.name}}", {{attribute.name}});
        if (!{{attribute.name}}.IsEmpty())
            V8HiddenValue::setHiddenValue(info.GetIsolate(), info.Holder(), v8AtomicString(info.GetIsolate(), "{{attribute.name}}"), {{attribute.name}});
        {% endfor %}
    }
    {% if is_constructor_raises_exception %}
    RefPtrWillBeRawPtr<{{cpp_class}}> event = {{cpp_class}}::create(type, eventInit, exceptionState);
    if (exceptionState.throwIfNeeded())
        return;
    {% else %}
    RefPtrWillBeRawPtr<{{cpp_class}}> event = {{cpp_class}}::create(type, eventInit);
    {% endif %}
    {% if any_type_attributes and not interface_name == 'ErrorEvent' %}
    {# If we're in an isolated world, create a SerializedScriptValue and store
       it in the event for later cloning if the property is accessed from
       another world. The main world case is handled lazily (in custom code).

       We do not clone Error objects (exceptions), for 2 reasons:
       1) Errors carry a reference to the isolated world's global object, and
          thus passing it around would cause leakage.
       2) Errors cannot be cloned (or serialized):
       http://www.whatwg.org/specs/web-apps/current-work/multipage/common-dom-interfaces.html#safe-passing-of-structured-data #}
    if (DOMWrapperWorld::current(info.GetIsolate()).isIsolatedWorld()) {
        {% for attribute in any_type_attributes %}
        if (!{{attribute.name}}.IsEmpty())
            event->setSerialized{{attribute.name | blink_capitalize}}(SerializedScriptValue::createAndSwallowExceptions({{attribute.name}}, info.GetIsolate()));
        {% endfor %}
    }

    {% endif %}
    v8::Handle<v8::Object> wrapper = info.Holder();
    V8DOMWrapper::associateObjectWithWrapper<{{v8_class}}>(event.release(), &{{v8_class}}::wrapperTypeInfo, wrapper, info.GetIsolate());
    v8SetReturnValue(info, wrapper);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block visit_dom_wrapper %}
{% if reachable_node_function or set_wrapper_reference_to_list %}
void {{v8_class}}::visitDOMWrapper(ScriptWrappableBase* internalPointer, const v8::Persistent<v8::Object>& wrapper, v8::Isolate* isolate)
{
    {{cpp_class}}* impl = fromInternalPointer(internalPointer);
    {% if set_wrapper_reference_to_list %}
    v8::Local<v8::Object> creationContext = v8::Local<v8::Object>::New(isolate, wrapper);
    V8WrapperInstantiationScope scope(creationContext, isolate);
    {% for set_wrapper_reference_to in set_wrapper_reference_to_list %}
    {{set_wrapper_reference_to.cpp_type}} {{set_wrapper_reference_to.name}} = impl->{{set_wrapper_reference_to.name}}();
    if ({{set_wrapper_reference_to.name}}) {
        if (!DOMDataStore::containsWrapper<{{set_wrapper_reference_to.v8_type}}>({{set_wrapper_reference_to.name}}, isolate))
            wrap({{set_wrapper_reference_to.name}}, creationContext, isolate);
        DOMDataStore::setWrapperReference<{{set_wrapper_reference_to.v8_type}}>(wrapper, {{set_wrapper_reference_to.name}}, isolate);
    }
    {% endfor %}
    {% endif %}
    {% if reachable_node_function %}
    // The {{reachable_node_function}}() method may return a reference or a pointer.
    if (Node* owner = WTF::getPtr(impl->{{reachable_node_function}}())) {
        Node* root = V8GCController::opaqueRootForGC(owner, isolate);
        isolate->SetReferenceFromGroup(v8::UniqueId(reinterpret_cast<intptr_t>(root)), wrapper);
        return;
    }
    {% endif %}
    setObjectGroup(internalPointer, wrapper, isolate);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% from 'attributes.cpp' import attribute_configuration with context %}
{% block shadow_attributes %}
{% if interface_name == 'Window' %}
static const V8DOMConfiguration::AttributeConfiguration shadowAttributes[] = {
    {% for attribute in attributes if attribute.is_unforgeable and attribute.should_be_exposed_to_script %}
    {{attribute_configuration(attribute)}},
    {% endfor %}
};

{% endif %}
{% endblock %}


{##############################################################################}
{% block install_attributes %}
{% if has_attribute_configuration %}
static const V8DOMConfiguration::AttributeConfiguration {{v8_class}}Attributes[] = {
    {% for attribute in attributes
       if not (attribute.is_expose_js_accessors or
               attribute.is_static or
               attribute.runtime_enabled_function or
               attribute.exposed_test or
               (interface_name == 'Window' and attribute.is_unforgeable))
           and attribute.should_be_exposed_to_script %}
    {% filter conditional(attribute.conditional_string) %}
    {{attribute_configuration(attribute)}},
    {% endfilter %}
    {% endfor %}
};

{% endif %}
{% endblock %}


{##############################################################################}
{% block install_accessors %}
{% if has_accessors %}
static const V8DOMConfiguration::AccessorConfiguration {{v8_class}}Accessors[] = {
    {% for attribute in attributes if attribute.is_expose_js_accessors and attribute.should_be_exposed_to_script %}
    {{attribute_configuration(attribute)}},
    {% endfor %}
};

{% endif %}
{% endblock %}


{##############################################################################}
{% from 'methods.cpp' import method_configuration with context %}
{% block install_methods %}
{% if method_configuration_methods %}
static const V8DOMConfiguration::MethodConfiguration {{v8_class}}Methods[] = {
    {% for method in method_configuration_methods %}
    {% filter conditional(method.conditional_string) %}
    {{method_configuration(method)}},
    {% endfilter %}
    {% endfor %}
};

{% endif %}
{% endblock %}


{##############################################################################}
{% block initialize_event %}
{% if has_event_constructor %}
bool initialize{{cpp_class}}({{cpp_class}}Init& eventInit, const Dictionary& options, ExceptionState& exceptionState, const v8::FunctionCallbackInfo<v8::Value>& info, const String& forEventName)
{
    Dictionary::ConversionContext conversionContext(forEventName.isEmpty() ? String("{{interface_name}}") : forEventName, "", exceptionState);
    {% if parent_interface %}{# any Event interface except Event itself #}
    if (!initialize{{parent_interface}}(eventInit, options, exceptionState, info, forEventName.isEmpty() ? String("{{interface_name}}") : forEventName))
        return false;

    {% endif %}
    {% for attribute in attributes
           if (attribute.is_initialized_by_event_constructor and
               not attribute.idl_type == 'any')%}
    {% set is_nullable = 'true' if attribute.is_nullable else 'false' %}
    {% if attribute.deprecate_as %}
    if (DictionaryHelper::convert(options, conversionContext.setConversionType("{{attribute.idl_type}}", {{is_nullable}}), "{{attribute.name}}", eventInit.{{attribute.cpp_name}})) {
        if (options.hasProperty("{{attribute.name}}"))
            UseCounter::countDeprecation(callingExecutionContext(info.GetIsolate()), UseCounter::{{attribute.deprecate_as}});
    } else {
        return false;
    }
    {% else %}
    if (!DictionaryHelper::convert(options, conversionContext.setConversionType("{{attribute.idl_type}}", {{is_nullable}}), "{{attribute.name}}", eventInit.{{attribute.cpp_name}}))
        return false;
    {% endif %}
    {% endfor %}
    return true;
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block constructor_callback %}
{% if constructors or has_custom_constructor or has_event_constructor %}
void {{v8_class}}::constructorCallback(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    TRACE_EVENT_SCOPED_SAMPLING_STATE("blink", "DOMConstructor");
    {% if measure_as %}
    UseCounter::count(callingExecutionContext(info.GetIsolate()), UseCounter::{{measure_as}});
    {% endif %}
    if (!info.IsConstructCall()) {
        V8ThrowException::throwTypeError(ExceptionMessages::constructorNotCallableAsFunction("{{interface_name}}"), info.GetIsolate());
        return;
    }

    if (ConstructorMode::current(info.GetIsolate()) == ConstructorMode::WrapExistingObject) {
        v8SetReturnValue(info, info.Holder());
        return;
    }

    {% if has_custom_constructor %}
    {{v8_class}}::constructorCustom(info);
    {% else %}
    {{cpp_class}}V8Internal::constructor(info);
    {% endif %}
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block configure_shadow_object_template %}
{% if interface_name == 'Window' %}
static void configureShadowObjectTemplate(v8::Handle<v8::ObjectTemplate> templ, v8::Isolate* isolate)
{
    V8DOMConfiguration::installAttributes(templ, v8::Handle<v8::ObjectTemplate>(), shadowAttributes, WTF_ARRAY_LENGTH(shadowAttributes), isolate);

    // Install a security handler with V8.
    templ->SetAccessCheckCallbacks(V8Window::namedSecurityCheckCustom, V8Window::indexedSecurityCheckCustom, v8::External::New(isolate, const_cast<WrapperTypeInfo*>(&V8Window::wrapperTypeInfo)));
    templ->SetInternalFieldCount(V8Window::internalFieldCount);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% from 'methods.cpp' import install_custom_signature with context %}
{% from 'constants.cpp' import install_constants with context %}
{% block install_dom_template %}
static void install{{v8_class}}Template(v8::Handle<v8::FunctionTemplate> functionTemplate, v8::Isolate* isolate)
{
    functionTemplate->ReadOnlyPrototype();

    v8::Local<v8::Signature> defaultSignature;
    {% set parent_template =
           'V8%s::domTemplate(isolate)' % parent_interface
           if parent_interface else 'v8::Local<v8::FunctionTemplate>()' %}
    {% if runtime_enabled_function %}
    if (!{{runtime_enabled_function}}())
        defaultSignature = V8DOMConfiguration::installDOMClassTemplate(functionTemplate, "", {{parent_template}}, {{v8_class}}::internalFieldCount, 0, 0, 0, 0, 0, 0, isolate);
    else
    {% endif %}
    {% set runtime_enabled_indent = 4 if runtime_enabled_function else 0 %}
    {% filter indent(runtime_enabled_indent, true) %}
    defaultSignature = V8DOMConfiguration::installDOMClassTemplate(functionTemplate, "{{interface_name}}", {{parent_template}}, {{v8_class}}::internalFieldCount,
        {# Test needed as size 0 arrays definitions are not allowed per standard
           (so objects have distinct addresses), which is enforced by MSVC.
           8.5.1 Aggregates [dcl.init.aggr]
           An array of unknown size initialized with a brace-enclosed
           initializer-list containing n initializer-clauses, where n shall be
           greater than zero, is defined as having n elements (8.3.4). #}
        {% set attributes_name, attributes_length =
               ('%sAttributes' % v8_class,
                'WTF_ARRAY_LENGTH(%sAttributes)' % v8_class)
           if has_attribute_configuration else (0, 0) %}
        {% set accessors_name, accessors_length =
               ('%sAccessors' % v8_class,
                'WTF_ARRAY_LENGTH(%sAccessors)' % v8_class)
           if has_accessors else (0, 0) %}
        {% set methods_name, methods_length =
               ('%sMethods' % v8_class,
                'WTF_ARRAY_LENGTH(%sMethods)' % v8_class)
           if method_configuration_methods else (0, 0) %}
        {{attributes_name}}, {{attributes_length}},
        {{accessors_name}}, {{accessors_length}},
        {{methods_name}}, {{methods_length}},
        isolate);
    {% endfilter %}

    {% if constructors or has_custom_constructor or has_event_constructor %}
    functionTemplate->SetCallHandler({{v8_class}}::constructorCallback);
    functionTemplate->SetLength({{interface_length}});
    {% endif %}
    v8::Local<v8::ObjectTemplate> instanceTemplate ALLOW_UNUSED = functionTemplate->InstanceTemplate();
    v8::Local<v8::ObjectTemplate> prototypeTemplate ALLOW_UNUSED = functionTemplate->PrototypeTemplate();
    {% if has_access_check_callbacks %}
    instanceTemplate->SetAccessCheckCallbacks({{cpp_class}}V8Internal::namedSecurityCheck, {{cpp_class}}V8Internal::indexedSecurityCheck, v8::External::New(isolate, const_cast<WrapperTypeInfo*>(&{{v8_class}}::wrapperTypeInfo)));
    {% endif %}
    {% for attribute in attributes
       if attribute.runtime_enabled_function and
          not attribute.exposed_test and
          not attribute.is_static %}
    {% filter conditional(attribute.conditional_string) %}
    if ({{attribute.runtime_enabled_function}}()) {
        static const V8DOMConfiguration::AttributeConfiguration attributeConfiguration =\
        {{attribute_configuration(attribute)}};
        V8DOMConfiguration::installAttribute(instanceTemplate, prototypeTemplate, attributeConfiguration, isolate);
    }
    {% endfilter %}
    {% endfor %}
    {% if constants %}
    {{install_constants() | indent}}
    {% endif %}
    {# Special operations #}
    {# V8 has access-check callback API and it's used on Window instead of
       deleters or enumerators; see ObjectTemplate::SetAccessCheckCallbacks.
       In addition, the getter should be set on the prototype template, to get
       the implementation straight out of the Window prototype, regardless of
       what prototype is actually set on the object. #}
    {% set set_on_template = 'PrototypeTemplate' if interface_name == 'Window'
                        else 'InstanceTemplate' %}
    {% if indexed_property_getter %}
    {# if have indexed properties, MUST have an indexed property getter #}
    {% set indexed_property_getter_callback =
           '%sV8Internal::indexedPropertyGetterCallback' % cpp_class %}
    {% set indexed_property_setter_callback =
           '%sV8Internal::indexedPropertySetterCallback' % cpp_class
           if indexed_property_setter else '0' %}
    {% set indexed_property_query_callback = '0' %}{# Unused #}
    {% set indexed_property_deleter_callback =
           '%sV8Internal::indexedPropertyDeleterCallback' % cpp_class
           if indexed_property_deleter else '0' %}
    {% set indexed_property_enumerator_callback =
           'indexedPropertyEnumerator<%s>' % cpp_class
           if indexed_property_getter.is_enumerable else '0' %}
    functionTemplate->{{set_on_template}}()->SetIndexedPropertyHandler({{indexed_property_getter_callback}}, {{indexed_property_setter_callback}}, {{indexed_property_query_callback}}, {{indexed_property_deleter_callback}}, {{indexed_property_enumerator_callback}});
    {% endif %}
    {% if named_property_getter %}
    {# if have named properties, MUST have a named property getter #}
    {% set named_property_getter_callback =
           '%sV8Internal::namedPropertyGetterCallback' % cpp_class %}
    {% set named_property_setter_callback =
           '%sV8Internal::namedPropertySetterCallback' % cpp_class
           if named_property_setter else '0' %}
    {% set named_property_query_callback =
           '%sV8Internal::namedPropertyQueryCallback' % cpp_class
           if named_property_getter.is_enumerable else '0' %}
    {% set named_property_deleter_callback =
           '%sV8Internal::namedPropertyDeleterCallback' % cpp_class
           if named_property_deleter else '0' %}
    {% set named_property_enumerator_callback =
           '%sV8Internal::namedPropertyEnumeratorCallback' % cpp_class
           if named_property_getter.is_enumerable else '0' %}
    functionTemplate->{{set_on_template}}()->SetNamedPropertyHandler({{named_property_getter_callback}}, {{named_property_setter_callback}}, {{named_property_query_callback}}, {{named_property_deleter_callback}}, {{named_property_enumerator_callback}});
    {% endif %}
    {% if iterator_method %}
    static const V8DOMConfiguration::SymbolKeyedMethodConfiguration symbolKeyedIteratorConfiguration = { v8::Symbol::GetIterator, {{cpp_class}}V8Internal::iteratorMethodCallback, 0, V8DOMConfiguration::ExposedToAllScripts };
    V8DOMConfiguration::installMethod(prototypeTemplate, defaultSignature, v8::DontDelete, symbolKeyedIteratorConfiguration, isolate);
    {% endif %}
    {# End special operations #}
    {% if has_custom_legacy_call_as_function %}
    functionTemplate->InstanceTemplate()->SetCallAsFunctionHandler({{v8_class}}::legacyCallCustom);
    {% endif %}
    {% for method in custom_registration_methods %}
    {# install_custom_signature #}
    {% filter conditional(method.conditional_string) %}
    {% filter runtime_enabled(method.overloads.runtime_enabled_function_all
                              if method.overloads else
                              method.runtime_enabled_function) %}
    {% if method.is_do_not_check_security %}
    {{install_do_not_check_security_signature(method) | indent}}
    {% else %}{# is_do_not_check_security #}
    {{install_custom_signature(method) | indent}}
    {% endif %}{# is_do_not_check_security #}
    {% endfilter %}{# runtime_enabled() #}
    {% endfilter %}{# conditional() #}
    {% endfor %}
    {% for attribute in attributes if attribute.is_static %}
    {% set getter_callback = '%sV8Internal::%sAttributeGetterCallback' %
           (cpp_class, attribute.name) %}
    {% filter conditional(attribute.conditional_string) %}
    functionTemplate->SetNativeDataProperty(v8AtomicString(isolate, "{{attribute.name}}"), {{getter_callback}}, {{attribute.setter_callback}}, v8::External::New(isolate, 0), static_cast<v8::PropertyAttribute>(v8::None), v8::Handle<v8::AccessorSignature>(), static_cast<v8::AccessControl>(v8::DEFAULT));
    {% endfilter %}
    {% endfor %}
    {# Special interfaces #}
    {% if interface_name == 'Window' %}

    prototypeTemplate->SetInternalFieldCount(V8Window::internalFieldCount);
    functionTemplate->SetHiddenPrototype(true);
    instanceTemplate->SetInternalFieldCount(V8Window::internalFieldCount);
    // Set access check callbacks, but turned off initially.
    // When a context is detached from a frame, turn on the access check.
    // Turning on checks also invalidates inline caches of the object.
    instanceTemplate->SetAccessCheckCallbacks(V8Window::namedSecurityCheckCustom, V8Window::indexedSecurityCheckCustom, v8::External::New(isolate, const_cast<WrapperTypeInfo*>(&V8Window::wrapperTypeInfo)), false);
    {% elif interface_name in ['HTMLDocument'] %}
    functionTemplate->SetHiddenPrototype(true);
    {% endif %}

    // Custom toString template
    functionTemplate->Set(v8AtomicString(isolate, "toString"), V8PerIsolateData::from(isolate)->toStringTemplate());
}

{% endblock %}


{######################################}
{% macro install_do_not_check_security_signature(method, world_suffix) %}
{# Methods that are [DoNotCheckSecurity] are always readable, but if they are
   changed and then accessed from a different origin, we do not return the
   underlying value, but instead return a new copy of the original function.
   This is achieved by storing the changed value as a hidden property. #}
{% set getter_callback =
       '%sV8Internal::%sOriginSafeMethodGetterCallback%s' %
       (cpp_class, method.name, world_suffix) %}
{% set setter_callback =
    '{0}V8Internal::{0}OriginSafeMethodSetterCallback'.format(cpp_class)
    if not method.is_read_only else '0' %}
{% if method.is_per_world_bindings %}
{% set getter_callback_for_main_world = '%sForMainWorld' % getter_callback %}
{% set setter_callback_for_main_world = '%sForMainWorld' % setter_callback
   if not method.is_read_only else '0' %}
{% else %}
{% set getter_callback_for_main_world = '0' %}
{% set setter_callback_for_main_world = '0' %}
{% endif %}
{% set property_attribute =
    'static_cast<v8::PropertyAttribute>(%s)' %
    ' | '.join(method.property_attributes or ['v8::DontDelete']) %}
{% set only_exposed_to_private_script = 'V8DOMConfiguration::OnlyExposedToPrivateScript' if method.only_exposed_to_private_script else 'V8DOMConfiguration::ExposedToAllScripts' %}
static const V8DOMConfiguration::AttributeConfiguration {{method.name}}OriginSafeAttributeConfiguration = {
    "{{method.name}}", {{getter_callback}}, {{setter_callback}}, {{getter_callback_for_main_world}}, {{setter_callback_for_main_world}}, &{{v8_class}}::wrapperTypeInfo, v8::ALL_CAN_READ, {{property_attribute}}, {{only_exposed_to_private_script}}, V8DOMConfiguration::OnInstance,
};
V8DOMConfiguration::installAttribute({{method.function_template}}, v8::Handle<v8::ObjectTemplate>(), {{method.name}}OriginSafeAttributeConfiguration, isolate);
{%- endmacro %}


{##############################################################################}
{% block get_dom_template %}
v8::Handle<v8::FunctionTemplate> {{v8_class}}::domTemplate(v8::Isolate* isolate)
{
    return V8DOMConfiguration::domClassTemplate(isolate, const_cast<WrapperTypeInfo*>(&wrapperTypeInfo), install{{v8_class}}Template);
}

{% endblock %}


{##############################################################################}
{% block has_instance %}
bool {{v8_class}}::hasInstance(v8::Handle<v8::Value> v8Value, v8::Isolate* isolate)
{
    return V8PerIsolateData::from(isolate)->hasInstance(&wrapperTypeInfo, v8Value);
}

v8::Handle<v8::Object> {{v8_class}}::findInstanceInPrototypeChain(v8::Handle<v8::Value> v8Value, v8::Isolate* isolate)
{
    return V8PerIsolateData::from(isolate)->findInstanceInPrototypeChain(&wrapperTypeInfo, v8Value);
}

{% endblock %}


{##############################################################################}
{% block to_native_with_type_check %}
{{cpp_class}}* {{v8_class}}::toNativeWithTypeCheck(v8::Isolate* isolate, v8::Handle<v8::Value> value)
{
    return hasInstance(value, isolate) ? fromInternalPointer(blink::toScriptWrappableBase(v8::Handle<v8::Object>::Cast(value))) : 0;
}

{% endblock %}


{##############################################################################}
{% block install_conditional_attributes %}
{% if has_conditional_attributes %}
void {{v8_class}}::installConditionallyEnabledProperties(v8::Handle<v8::Object> instanceObject, v8::Isolate* isolate)
{
    v8::Local<v8::Object> prototypeObject = v8::Local<v8::Object>::Cast(instanceObject->GetPrototype());
    ExecutionContext* context = toExecutionContext(prototypeObject->CreationContext());

    {% for attribute in attributes if attribute.exposed_test %}
    {% filter exposed(attribute.exposed_test) %}
    static const V8DOMConfiguration::AttributeConfiguration attributeConfiguration =\
    {{attribute_configuration(attribute)}};
    V8DOMConfiguration::installAttribute(instanceObject, prototypeObject, attributeConfiguration, isolate);
    {% endfilter %}
    {% endfor %}
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block install_conditional_methods %}
{% if conditionally_enabled_methods %}
void {{v8_class}}::installConditionallyEnabledMethods(v8::Handle<v8::Object> prototypeObject, v8::Isolate* isolate)
{
    {# Define per-context enabled operations #}
    v8::Local<v8::Signature> defaultSignature = v8::Signature::New(isolate, domTemplate(isolate));
    ExecutionContext* context = toExecutionContext(prototypeObject->CreationContext());
    ASSERT(context);

    {% for method in conditionally_enabled_methods %}
    {% filter exposed(method.exposed_test) %}
    prototypeObject->Set(v8AtomicString(isolate, "{{method.name}}"), v8::FunctionTemplate::New(isolate, {{cpp_class}}V8Internal::{{method.name}}MethodCallback, v8Undefined(), defaultSignature, {{method.number_of_required_arguments}})->GetFunction());
    {% endfilter %}
    {% endfor %}
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block to_active_dom_object %}
{% if is_active_dom_object %}
ActiveDOMObject* {{v8_class}}::toActiveDOMObject(v8::Handle<v8::Object> wrapper)
{
    return toNative(wrapper);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block to_event_target %}
{% if is_event_target %}
EventTarget* {{v8_class}}::toEventTarget(v8::Handle<v8::Object> object)
{
    return toNative(object);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block get_shadow_object_template %}
{% if interface_name == 'Window' %}
v8::Handle<v8::ObjectTemplate> V8Window::getShadowObjectTemplate(v8::Isolate* isolate)
{
    if (DOMWrapperWorld::current(isolate).isMainWorld()) {
        DEFINE_STATIC_LOCAL(v8::Persistent<v8::ObjectTemplate>, V8WindowShadowObjectCacheForMainWorld, ());
        if (V8WindowShadowObjectCacheForMainWorld.IsEmpty()) {
            TRACE_EVENT_SCOPED_SAMPLING_STATE("blink", "BuildDOMTemplate");
            v8::Handle<v8::ObjectTemplate> templ = v8::ObjectTemplate::New(isolate);
            configureShadowObjectTemplate(templ, isolate);
            V8WindowShadowObjectCacheForMainWorld.Reset(isolate, templ);
            return templ;
        }
        return v8::Local<v8::ObjectTemplate>::New(isolate, V8WindowShadowObjectCacheForMainWorld);
    } else {
        DEFINE_STATIC_LOCAL(v8::Persistent<v8::ObjectTemplate>, V8WindowShadowObjectCacheForNonMainWorld, ());
        if (V8WindowShadowObjectCacheForNonMainWorld.IsEmpty()) {
            TRACE_EVENT_SCOPED_SAMPLING_STATE("blink", "BuildDOMTemplate");
            v8::Handle<v8::ObjectTemplate> templ = v8::ObjectTemplate::New(isolate);
            configureShadowObjectTemplate(templ, isolate);
            V8WindowShadowObjectCacheForNonMainWorld.Reset(isolate, templ);
            return templ;
        }
        return v8::Local<v8::ObjectTemplate>::New(isolate, V8WindowShadowObjectCacheForNonMainWorld);
    }
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block wrap %}
{% if special_wrap_for or is_document %}
v8::Handle<v8::Object> wrap({{cpp_class}}* impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(impl);
    {% for special_wrap_interface in special_wrap_for %}
    if (impl->is{{special_wrap_interface}}())
        return wrap(to{{special_wrap_interface}}(impl), creationContext, isolate);
    {% endfor %}
    v8::Handle<v8::Object> wrapper = {{v8_class}}::createWrapper(impl, creationContext, isolate);
    {% if is_document %}
    if (wrapper.IsEmpty())
        return wrapper;
    DOMWrapperWorld& world = DOMWrapperWorld::current(isolate);
    if (world.isMainWorld()) {
        if (LocalFrame* frame = impl->frame())
            frame->script().windowProxy(world)->updateDocumentWrapper(wrapper);
    }
    {% endif %}
    return wrapper;
}

{% elif not has_custom_to_v8 and not has_custom_wrap %}
v8::Handle<v8::Object> wrap({{cpp_class}}* impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(impl);
    ASSERT(!DOMDataStore::containsWrapper<{{v8_class}}>(impl, isolate));
    return {{v8_class}}::createWrapper(impl, creationContext, isolate);
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block create_wrapper %}
{% if not has_custom_to_v8 %}
v8::Handle<v8::Object> {{v8_class}}::createWrapper({{pass_cpp_type}} impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(impl);
    ASSERT(!DOMDataStore::containsWrapper<{{v8_class}}>(impl.get(), isolate));
    {% if is_script_wrappable %}
    const WrapperTypeInfo* actualInfo = impl->wrapperTypeInfo();
    // Might be a XXXConstructor::wrapperTypeInfo instead of an XXX::wrapperTypeInfo. These will both have
    // the same object de-ref functions, though, so use that as the basis of the check.
    RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(actualInfo->derefObjectFunction == wrapperTypeInfo.derefObjectFunction);
    {% endif %}

    {% if is_document %}
    if (LocalFrame* frame = impl->frame()) {
        if (frame->script().initializeMainWorld()) {
            // initializeMainWorld may have created a wrapper for the object, retry from the start.
            v8::Handle<v8::Object> wrapper = DOMDataStore::getWrapper<{{v8_class}}>(impl.get(), isolate);
            if (!wrapper.IsEmpty())
                return wrapper;
        }
    }
    {% endif %}
    v8::Handle<v8::Object> wrapper = V8DOMWrapper::createWrapper(creationContext, &wrapperTypeInfo, toScriptWrappableBase(impl.get()), isolate);
    if (UNLIKELY(wrapper.IsEmpty()))
        return wrapper;

    installConditionallyEnabledProperties(wrapper, isolate);
    V8DOMWrapper::associateObjectWithWrapper<{{v8_class}}>(impl, &wrapperTypeInfo, wrapper, isolate);
    return wrapper;
}

{% endif %}
{% endblock %}


{##############################################################################}
{% block deref_object_and_to_v8_no_inline %}

void {{v8_class}}::refObject(ScriptWrappableBase* internalPointer)
{
    fromInternalPointer(internalPointer)->ref();
}

void {{v8_class}}::derefObject(ScriptWrappableBase* internalPointer)
{
    fromInternalPointer(internalPointer)->deref();
}

template<>
v8::Handle<v8::Value> toV8NoInline({{cpp_class}}* impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    return toV8(impl, creationContext, isolate);
}

{% endblock %}
