# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates C++ source files from a mojom.Module."""

import mojom.generate.generator as generator
import mojom.generate.module as mojom
import mojom.generate.pack as pack
from mojom.generate.template_expander import UseJinja


_kind_to_cpp_type = {
  mojom.BOOL:                  "bool",
  mojom.INT8:                  "int8_t",
  mojom.UINT8:                 "uint8_t",
  mojom.INT16:                 "int16_t",
  mojom.UINT16:                "uint16_t",
  mojom.INT32:                 "int32_t",
  mojom.UINT32:                "uint32_t",
  mojom.FLOAT:                 "float",
  mojom.HANDLE:                "mojo::Handle",
  mojom.DCPIPE:                "mojo::DataPipeConsumerHandle",
  mojom.DPPIPE:                "mojo::DataPipeProducerHandle",
  mojom.MSGPIPE:               "mojo::MessagePipeHandle",
  mojom.SHAREDBUFFER:          "mojo::SharedBufferHandle",
  mojom.NULLABLE_HANDLE:       "mojo::Handle",
  mojom.NULLABLE_DCPIPE:       "mojo::DataPipeConsumerHandle",
  mojom.NULLABLE_DPPIPE:       "mojo::DataPipeProducerHandle",
  mojom.NULLABLE_MSGPIPE:      "mojo::MessagePipeHandle",
  mojom.NULLABLE_SHAREDBUFFER: "mojo::SharedBufferHandle",
  mojom.INT64:                 "int64_t",
  mojom.UINT64:                "uint64_t",
  mojom.DOUBLE:                "double",
}

_kind_to_cpp_literal_suffix = {
  mojom.UINT8:        "U",
  mojom.UINT16:       "U",
  mojom.UINT32:       "U",
  mojom.FLOAT:        "f",
  mojom.UINT64:       "ULL",
}

def ConstantValue(constant):
  return ExpressionToText(constant.value, kind=constant.kind)

def DefaultValue(field):
  if field.default:
    if mojom.IsStructKind(field.kind):
      assert field.default == "default"
      return "%s::New()" % GetNameForKind(field.kind)
    return ExpressionToText(field.default, kind=field.kind)
  return ""

def NamespaceToArray(namespace):
  return namespace.split(".") if namespace else []

def GetNameForKind(kind, internal = False):
  parts = []
  if kind.imported_from:
    parts.extend(NamespaceToArray(kind.imported_from["namespace"]))
  if internal:
    parts.append("internal")
  if kind.parent_kind:
    parts.append(kind.parent_kind.name)
  parts.append(kind.name)
  return "::".join(parts)

def GetCppType(kind):
  if mojom.IsArrayKind(kind):
    return "mojo::internal::Array_Data<%s>*" % GetCppType(kind.kind)
  if mojom.IsMapKind(kind):
    return "mojo::internal::Map_Data<%s, %s>*" % (
      GetCppType(kind.key_kind), GetCppType(kind.value_kind))
  if mojom.IsStructKind(kind):
    return "%s_Data*" % GetNameForKind(kind, internal=True)
  if mojom.IsUnionKind(kind):
    return "%s_Data" % GetNameForKind(kind, internal=True)
  if mojom.IsInterfaceKind(kind):
    return "mojo::internal::Interface_Data"
  if mojom.IsInterfaceRequestKind(kind):
    return "mojo::MessagePipeHandle"
  if mojom.IsEnumKind(kind):
    return "int32_t"
  if mojom.IsStringKind(kind):
    return "mojo::internal::String_Data*"
  return _kind_to_cpp_type[kind]

def GetCppPodType(kind):
  if mojom.IsStringKind(kind):
    return "char*"
  return _kind_to_cpp_type[kind]

def GetCppArrayArgWrapperType(kind):
  if mojom.IsEnumKind(kind):
    return GetNameForKind(kind)
  if mojom.IsStructKind(kind) or mojom.IsUnionKind(kind):
    return "%sPtr" % GetNameForKind(kind)
  if mojom.IsArrayKind(kind):
    return "mojo::Array<%s> " % GetCppArrayArgWrapperType(kind.kind)
  if mojom.IsMapKind(kind):
    return "mojo::Map<%s, %s> " % (GetCppArrayArgWrapperType(kind.key_kind),
                                   GetCppArrayArgWrapperType(kind.value_kind))
  if mojom.IsInterfaceKind(kind):
    raise Exception("Arrays of interfaces not yet supported!")
  if mojom.IsInterfaceRequestKind(kind):
    raise Exception("Arrays of interface requests not yet supported!")
  if mojom.IsStringKind(kind):
    return "mojo::String"
  if mojom.IsGenericHandleKind(kind):
    return "mojo::ScopedHandle"
  if mojom.IsDataPipeConsumerKind(kind):
    return "mojo::ScopedDataPipeConsumerHandle"
  if mojom.IsDataPipeProducerKind(kind):
    return "mojo::ScopedDataPipeProducerHandle"
  if mojom.IsMessagePipeKind(kind):
    return "mojo::ScopedMessagePipeHandle"
  if mojom.IsSharedBufferKind(kind):
    return "mojo::ScopedSharedBufferHandle"
  return _kind_to_cpp_type[kind]

def GetCppResultWrapperType(kind):
  if mojom.IsEnumKind(kind):
    return GetNameForKind(kind)
  if mojom.IsStructKind(kind) or mojom.IsUnionKind(kind):
    return "%sPtr" % GetNameForKind(kind)
  if mojom.IsArrayKind(kind):
    return "mojo::Array<%s>" % GetCppArrayArgWrapperType(kind.kind)
  if mojom.IsMapKind(kind):
    return "mojo::Map<%s, %s>" % (GetCppArrayArgWrapperType(kind.key_kind),
                                  GetCppArrayArgWrapperType(kind.value_kind))
  if mojom.IsInterfaceKind(kind):
    return "%sPtr" % GetNameForKind(kind)
  if mojom.IsInterfaceRequestKind(kind):
    return "mojo::InterfaceRequest<%s>" % GetNameForKind(kind.kind)
  if mojom.IsStringKind(kind):
    return "mojo::String"
  if mojom.IsGenericHandleKind(kind):
    return "mojo::ScopedHandle"
  if mojom.IsDataPipeConsumerKind(kind):
    return "mojo::ScopedDataPipeConsumerHandle"
  if mojom.IsDataPipeProducerKind(kind):
    return "mojo::ScopedDataPipeProducerHandle"
  if mojom.IsMessagePipeKind(kind):
    return "mojo::ScopedMessagePipeHandle"
  if mojom.IsSharedBufferKind(kind):
    return "mojo::ScopedSharedBufferHandle"
  return _kind_to_cpp_type[kind]

def GetCppWrapperType(kind):
  if mojom.IsEnumKind(kind):
    return GetNameForKind(kind)
  if mojom.IsStructKind(kind) or mojom.IsUnionKind(kind):
    return "%sPtr" % GetNameForKind(kind)
  if mojom.IsArrayKind(kind):
    return "mojo::Array<%s>" % GetCppArrayArgWrapperType(kind.kind)
  if mojom.IsMapKind(kind):
    return "mojo::Map<%s, %s>" % (GetCppArrayArgWrapperType(kind.key_kind),
                                  GetCppArrayArgWrapperType(kind.value_kind))
  if mojom.IsInterfaceKind(kind):
    return "%sPtr" % GetNameForKind(kind)
  if mojom.IsInterfaceRequestKind(kind):
    raise Exception("InterfaceRequest fields not supported!")
  if mojom.IsStringKind(kind):
    return "mojo::String"
  if mojom.IsGenericHandleKind(kind):
    return "mojo::ScopedHandle"
  if mojom.IsDataPipeConsumerKind(kind):
    return "mojo::ScopedDataPipeConsumerHandle"
  if mojom.IsDataPipeProducerKind(kind):
    return "mojo::ScopedDataPipeProducerHandle"
  if mojom.IsMessagePipeKind(kind):
    return "mojo::ScopedMessagePipeHandle"
  if mojom.IsSharedBufferKind(kind):
    return "mojo::ScopedSharedBufferHandle"
  return _kind_to_cpp_type[kind]

def GetCppConstWrapperType(kind):
  if mojom.IsStructKind(kind) or mojom.IsUnionKind(kind):
    return "%sPtr" % GetNameForKind(kind)
  if mojom.IsArrayKind(kind):
    return "mojo::Array<%s>" % GetCppArrayArgWrapperType(kind.kind)
  if mojom.IsMapKind(kind):
    return "mojo::Map<%s, %s>" % (GetCppArrayArgWrapperType(kind.key_kind),
                                  GetCppArrayArgWrapperType(kind.value_kind))
  if mojom.IsInterfaceKind(kind):
    return "%sPtr" % GetNameForKind(kind)
  if mojom.IsInterfaceRequestKind(kind):
    return "mojo::InterfaceRequest<%s>" % GetNameForKind(kind.kind)
  if mojom.IsEnumKind(kind):
    return GetNameForKind(kind)
  if mojom.IsStringKind(kind):
    return "const mojo::String&"
  if mojom.IsGenericHandleKind(kind):
    return "mojo::ScopedHandle"
  if mojom.IsDataPipeConsumerKind(kind):
    return "mojo::ScopedDataPipeConsumerHandle"
  if mojom.IsDataPipeProducerKind(kind):
    return "mojo::ScopedDataPipeProducerHandle"
  if mojom.IsMessagePipeKind(kind):
    return "mojo::ScopedMessagePipeHandle"
  if mojom.IsSharedBufferKind(kind):
    return "mojo::ScopedSharedBufferHandle"
  if not kind in _kind_to_cpp_type:
    print "missing:", kind.spec
  return _kind_to_cpp_type[kind]

def GetCppFieldType(kind):
  if mojom.IsStructKind(kind):
    return ("mojo::internal::StructPointer<%s_Data>" %
        GetNameForKind(kind, internal=True))
  if mojom.IsUnionKind(kind):
    return "%s_Data" % GetNameForKind(kind, internal=True)
  if mojom.IsArrayKind(kind):
    return "mojo::internal::ArrayPointer<%s>" % GetCppType(kind.kind)
  if mojom.IsMapKind(kind):
    return ("mojo::internal::StructPointer<mojo::internal::Map_Data<%s, %s>>" %
            (GetCppType(kind.key_kind), GetCppType(kind.value_kind)))
  if mojom.IsInterfaceKind(kind):
    return "mojo::internal::Interface_Data"
  if mojom.IsInterfaceRequestKind(kind):
    return "mojo::MessagePipeHandle"
  if mojom.IsEnumKind(kind):
    return GetNameForKind(kind)
  if mojom.IsStringKind(kind):
    return "mojo::internal::StringPointer"
  return _kind_to_cpp_type[kind]

def GetCppUnionFieldType(kind):
  if mojom.IsAnyHandleKind(kind):
    return "MojoHandle"
  if mojom.IsInterfaceKind(kind):
    return "uint64_t"
  if mojom.IsEnumKind(kind):
    return "int32_t"
  if mojom.IsUnionKind(kind):
    return ("mojo::internal::UnionPointer<%s_Data>" %
        GetNameForKind(kind, internal=True))
  return GetCppFieldType(kind)

def GetUnionGetterReturnType(kind):
  if (mojom.IsStructKind(kind) or mojom.IsUnionKind(kind) or
      mojom.IsArrayKind(kind) or mojom.IsMapKind(kind) or
      mojom.IsAnyHandleKind(kind) or mojom.IsInterfaceKind(kind)):
    return "%s&" % GetCppWrapperType(kind)
  return GetCppResultWrapperType(kind)

def TranslateConstants(token, kind):
  if isinstance(token, mojom.NamedValue):
    # Both variable and enum constants are constructed like:
    # Namespace::Struct::CONSTANT_NAME
    # For enums, CONSTANT_NAME is ENUM_NAME_ENUM_VALUE.
    name = []
    if token.imported_from:
      name.extend(NamespaceToArray(token.namespace))
    if token.parent_kind:
      name.append(token.parent_kind.name)
    if isinstance(token, mojom.EnumValue):
      name.append(
          "%s_%s" % (generator.CamelCaseToAllCaps(token.enum.name), token.name))
    else:
      name.append(token.name)
    return "::".join(name)

  if isinstance(token, mojom.BuiltinValue):
    if token.value == "double.INFINITY" or token.value == "float.INFINITY":
      return "INFINITY";
    if token.value == "double.NEGATIVE_INFINITY" or \
       token.value == "float.NEGATIVE_INFINITY":
      return "-INFINITY";
    if token.value == "double.NAN" or token.value == "float.NAN":
      return "NAN";

  if (kind is not None and mojom.IsFloatKind(kind)):
      return token if token.isdigit() else token + "f";

  # Per C++11, 2.14.2, the type of an integer literal is the first of the
  # corresponding list in Table 6 in which its value can be represented. In this
  # case, the list for decimal constants with no suffix is:
  #   int, long int, long long int
  # The standard considers a program ill-formed if it contains an integer
  # literal that cannot be represented by any of the allowed types.
  #
  # As it turns out, MSVC doesn't bother trying to fall back to long long int,
  # so the integral constant -2147483648 causes it grief: it decides to
  # represent 2147483648 as an unsigned integer, and then warns that the unary
  # minus operator doesn't make sense on unsigned types. Doh!
  if kind == mojom.INT32 and token == "-2147483648":
    return "(-%d - 1) /* %s */" % (
        2**31 - 1, "Workaround for MSVC bug; see https://crbug.com/445618")

  return "%s%s" % (token, _kind_to_cpp_literal_suffix.get(kind, ""))

def ExpressionToText(value, kind=None):
  return TranslateConstants(value, kind)

def ShouldInlineStruct(struct):
  # TODO(darin): Base this on the size of the wrapper class.
  if len(struct.fields) > 4:
    return False
  for field in struct.fields:
    if mojom.IsMoveOnlyKind(field.kind):
      return False
  return True

def ShouldInlineUnion(union):
  return not any(mojom.IsMoveOnlyKind(field.kind) for field in union.fields)

def GetArrayValidateParamsCtorArgs(kind):
  if mojom.IsStringKind(kind):
    expected_num_elements = 0
    element_is_nullable = False
    element_validate_params = "nullptr"
  elif mojom.IsMapKind(kind):
    expected_num_elements = 0
    element_is_nullable = mojom.IsNullableKind(kind.value_kind)
    element_validate_params = GetNewArrayValidateParams(kind.value_kind)
  else:
    expected_num_elements = generator.ExpectedArraySize(kind) or 0
    element_is_nullable = mojom.IsNullableKind(kind.kind)
    element_validate_params = GetNewArrayValidateParams(kind.kind)

  return "%d, %s, %s" % (expected_num_elements,
                         "true" if element_is_nullable else "false",
                         element_validate_params)

def GetNewArrayValidateParams(kind):
  if (not mojom.IsArrayKind(kind) and not mojom.IsMapKind(kind) and
      not mojom.IsStringKind(kind)):
    return "nullptr"

  return "new mojo::internal::ArrayValidateParams(%s)" % (
      GetArrayValidateParamsCtorArgs(kind))

def GetMapValidateParamsCtorArgs(value_kind):
  # Unlike GetArrayValidateParams, we are given the wrapped kind, instead of
  # the raw array kind. So we wrap the return value of GetArrayValidateParams.
  element_is_nullable = mojom.IsNullableKind(value_kind)
  return "0, %s, %s" % ("true" if element_is_nullable else "false",
                        GetNewArrayValidateParams(value_kind))

class Generator(generator.Generator):

  cpp_filters = {
    "constant_value": ConstantValue,
    "cpp_const_wrapper_type": GetCppConstWrapperType,
    "cpp_field_type": GetCppFieldType,
    "cpp_union_field_type": GetCppUnionFieldType,
    "cpp_pod_type": GetCppPodType,
    "cpp_result_type": GetCppResultWrapperType,
    "cpp_type": GetCppType,
    "cpp_union_getter_return_type": GetUnionGetterReturnType,
    "cpp_wrapper_type": GetCppWrapperType,
    "default_value": DefaultValue,
    "expression_to_text": ExpressionToText,
    "get_array_validate_params_ctor_args": GetArrayValidateParamsCtorArgs,
    "get_map_validate_params_ctor_args": GetMapValidateParamsCtorArgs,
    "get_name_for_kind": GetNameForKind,
    "get_pad": pack.GetPad,
    "has_callbacks": mojom.HasCallbacks,
    "should_inline": ShouldInlineStruct,
    "should_inline_union": ShouldInlineUnion,
    "is_array_kind": mojom.IsArrayKind,
    "is_cloneable_kind": mojom.IsCloneableKind,
    "is_enum_kind": mojom.IsEnumKind,
    "is_integral_kind": mojom.IsIntegralKind,
    "is_move_only_kind": mojom.IsMoveOnlyKind,
    "is_any_handle_kind": mojom.IsAnyHandleKind,
    "is_interface_kind": mojom.IsInterfaceKind,
    "is_interface_request_kind": mojom.IsInterfaceRequestKind,
    "is_map_kind": mojom.IsMapKind,
    "is_nullable_kind": mojom.IsNullableKind,
    "is_object_kind": mojom.IsObjectKind,
    "is_string_kind": mojom.IsStringKind,
    "is_struct_kind": mojom.IsStructKind,
    "is_union_kind": mojom.IsUnionKind,
    "struct_size": lambda ps: ps.GetTotalSize() + _HEADER_SIZE,
    "stylize_method": generator.StudlyCapsToCamel,
    "to_all_caps": generator.CamelCaseToAllCaps,
    "under_to_camel": generator.UnderToCamel,
  }

  def GetJinjaExports(self):
    return {
      "module": self.module,
      "namespace": self.module.namespace,
      "namespaces_as_array": NamespaceToArray(self.module.namespace),
      "imports": self.module.imports,
      "kinds": self.module.kinds,
      "enums": self.module.enums,
      "structs": self.GetStructs(),
      "unions": self.GetUnions(),
      "interfaces": self.GetInterfaces(),
    }

  @UseJinja("cpp_templates/module.h.tmpl", filters=cpp_filters)
  def GenerateModuleHeader(self):
    return self.GetJinjaExports()

  @UseJinja("cpp_templates/module-internal.h.tmpl", filters=cpp_filters)
  def GenerateModuleInternalHeader(self):
    return self.GetJinjaExports()

  @UseJinja("cpp_templates/module.cc.tmpl", filters=cpp_filters)
  def GenerateModuleSource(self):
    return self.GetJinjaExports()

  def GenerateFiles(self, args):
    self.Write(self.GenerateModuleHeader(),
        self.MatchMojomFilePath("%s.h" % self.module.name))
    self.Write(self.GenerateModuleInternalHeader(),
        self.MatchMojomFilePath("%s-internal.h" % self.module.name))
    self.Write(self.GenerateModuleSource(),
        self.MatchMojomFilePath("%s.cc" % self.module.name))
