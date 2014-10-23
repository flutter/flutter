{######################################}
{% macro install_constants() %}
{% if has_constant_configuration %}
{# Normal constants #}
static const V8DOMConfiguration::ConstantConfiguration {{v8_class}}Constants[] = {
    {% for constant in constants if not constant.runtime_enabled_function %}
    {% if constant.idl_type in ('Double', 'Float') %}
        {% set value = '0, %s, 0' % constant.value %}
    {% elif constant.idl_type == 'String' %}
        {% set value = '0, 0, %s' % constant.value %}
    {% else %}
        {# 'Short', 'Long' etc. #}
        {% set value = '%s, 0, 0' % constant.value %}
    {% endif %}
    {"{{constant.name}}", {{value}}, V8DOMConfiguration::ConstantType{{constant.idl_type}}},
    {% endfor %}
};
V8DOMConfiguration::installConstants(functionTemplate, prototypeTemplate, {{v8_class}}Constants, WTF_ARRAY_LENGTH({{v8_class}}Constants), isolate);
{% endif %}
{# Runtime-enabled constants #}
{% for constant in constants if constant.runtime_enabled_function %}
if ({{constant.runtime_enabled_function}}()) {
    {% if constant.idl_type in ('Double', 'Float') %}
        {% set value = '0, %s, 0' % constant.value %}
    {% elif constant.idl_type == 'String' %}
        {% set value = '0, 0, %s' % constant.value %}
    {% else %}
        {# 'Short', 'Long' etc. #}
        {% set value = '%s, 0, 0' % constant.value %}
    {% endif %}
    static const V8DOMConfiguration::ConstantConfiguration constantConfiguration = {"{{constant.name}}", {{value}}, V8DOMConfiguration::ConstantType{{constant.idl_type}}};
    V8DOMConfiguration::installConstants(functionTemplate, prototypeTemplate, &constantConfiguration, 1, isolate);
}
{% endfor %}
{# Check constants #}
{% if not do_not_check_constants %}
{% for constant in constants %}
{% if constant.idl_type not in ('Double', 'Float', 'String') %}
{% set constant_cpp_class = constant.cpp_class or cpp_class %}
COMPILE_ASSERT({{constant.value}} == {{constant_cpp_class}}::{{constant.reflected_name}}, TheValueOf{{cpp_class}}_{{constant.reflected_name}}DoesntMatchWithImplementation);
{% endif %}
{% endfor %}
{% endif %}
{% endmacro %}
