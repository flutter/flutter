# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates JavaScript source files from a mojom.Module."""

import mojom.generate.generator as generator
import mojom.generate.module as mojom
import mojom.generate.pack as pack
from mojom.generate.template_expander import UseJinja

_kind_to_javascript_default_value = {
  mojom.BOOL:                  "false",
  mojom.INT8:                  "0",
  mojom.UINT8:                 "0",
  mojom.INT16:                 "0",
  mojom.UINT16:                "0",
  mojom.INT32:                 "0",
  mojom.UINT32:                "0",
  mojom.FLOAT:                 "0",
  mojom.HANDLE:                "null",
  mojom.DCPIPE:                "null",
  mojom.DPPIPE:                "null",
  mojom.MSGPIPE:               "null",
  mojom.SHAREDBUFFER:          "null",
  mojom.NULLABLE_HANDLE:       "null",
  mojom.NULLABLE_DCPIPE:       "null",
  mojom.NULLABLE_DPPIPE:       "null",
  mojom.NULLABLE_MSGPIPE:      "null",
  mojom.NULLABLE_SHAREDBUFFER: "null",
  mojom.INT64:                 "0",
  mojom.UINT64:                "0",
  mojom.DOUBLE:                "0",
  mojom.STRING:                "null",
  mojom.NULLABLE_STRING:       "null"
}


def JavaScriptType(kind):
  if kind.imported_from:
    return kind.imported_from["unique_name"] + "." + kind.name
  return kind.name


def JavaScriptDefaultValue(field):
  if field.default:
    if mojom.IsStructKind(field.kind):
      assert field.default == "default"
      return "new %s()" % JavaScriptType(field.kind)
    return ExpressionToText(field.default)
  if field.kind in mojom.PRIMITIVES:
    return _kind_to_javascript_default_value[field.kind]
  if mojom.IsStructKind(field.kind):
    return "null"
  if mojom.IsUnionKind(field.kind):
    return "null"
  if mojom.IsArrayKind(field.kind):
    return "null"
  if mojom.IsMapKind(field.kind):
    return "null"
  if mojom.IsInterfaceKind(field.kind) or \
     mojom.IsInterfaceRequestKind(field.kind):
    return _kind_to_javascript_default_value[mojom.MSGPIPE]
  if mojom.IsEnumKind(field.kind):
    return "0"
  raise Exception("No valid default: %s" % field)


def JavaScriptPayloadSize(packed):
  packed_fields = packed.packed_fields
  if not packed_fields:
    return 0
  last_field = packed_fields[-1]
  offset = last_field.offset + last_field.size
  pad = pack.GetPad(offset, 8)
  return offset + pad


_kind_to_codec_type = {
  mojom.BOOL:                  "codec.Uint8",
  mojom.INT8:                  "codec.Int8",
  mojom.UINT8:                 "codec.Uint8",
  mojom.INT16:                 "codec.Int16",
  mojom.UINT16:                "codec.Uint16",
  mojom.INT32:                 "codec.Int32",
  mojom.UINT32:                "codec.Uint32",
  mojom.FLOAT:                 "codec.Float",
  mojom.HANDLE:                "codec.Handle",
  mojom.DCPIPE:                "codec.Handle",
  mojom.DPPIPE:                "codec.Handle",
  mojom.MSGPIPE:               "codec.Handle",
  mojom.SHAREDBUFFER:          "codec.Handle",
  mojom.NULLABLE_HANDLE:       "codec.NullableHandle",
  mojom.NULLABLE_DCPIPE:       "codec.NullableHandle",
  mojom.NULLABLE_DPPIPE:       "codec.NullableHandle",
  mojom.NULLABLE_MSGPIPE:      "codec.NullableHandle",
  mojom.NULLABLE_SHAREDBUFFER: "codec.NullableHandle",
  mojom.INT64:                 "codec.Int64",
  mojom.UINT64:                "codec.Uint64",
  mojom.DOUBLE:                "codec.Double",
  mojom.STRING:                "codec.String",
  mojom.NULLABLE_STRING:       "codec.NullableString",
}


def CodecType(kind):
  if kind in mojom.PRIMITIVES:
    return _kind_to_codec_type[kind]
  if mojom.IsStructKind(kind):
    pointer_type = "NullablePointerTo" if mojom.IsNullableKind(kind) \
        else "PointerTo"
    return "new codec.%s(%s)" % (pointer_type, JavaScriptType(kind))
  if mojom.IsUnionKind(kind):
    return JavaScriptType(kind)
  if mojom.IsArrayKind(kind):
    array_type = "NullableArrayOf" if mojom.IsNullableKind(kind) else "ArrayOf"
    array_length = "" if kind.length is None else ", %d" % kind.length
    element_type = ElementCodecType(kind.kind)
    return "new codec.%s(%s%s)" % (array_type, element_type, array_length)
  if mojom.IsInterfaceKind(kind):
    return "codec.%s" % ("NullableInterface" if mojom.IsNullableKind(kind)
        else "Interface")
  if mojom.IsInterfaceRequestKind(kind):
    return CodecType(mojom.MSGPIPE)
  if mojom.IsEnumKind(kind):
    return _kind_to_codec_type[mojom.INT32]
  if mojom.IsMapKind(kind):
    map_type = "NullableMapOf" if mojom.IsNullableKind(kind) else "MapOf"
    key_type = ElementCodecType(kind.key_kind)
    value_type = ElementCodecType(kind.value_kind)
    return "new codec.%s(%s, %s)" % (map_type, key_type, value_type)
  raise Exception("No codec type for %s" % kind)


def ElementCodecType(kind):
  return "codec.PackedBool" if mojom.IsBoolKind(kind) else CodecType(kind)

def JavaScriptDecodeSnippet(kind):
  if kind in mojom.PRIMITIVES or mojom.IsUnionKind(kind):
    return "decodeStruct(%s)" % CodecType(kind)
  if mojom.IsStructKind(kind):
    return "decodeStructPointer(%s)" % JavaScriptType(kind)
  if mojom.IsMapKind(kind):
    return "decodeMapPointer(%s, %s)" % \
        (ElementCodecType(kind.key_kind), ElementCodecType(kind.value_kind))
  if mojom.IsArrayKind(kind) and mojom.IsBoolKind(kind.kind):
    return "decodeArrayPointer(codec.PackedBool)"
  if mojom.IsArrayKind(kind):
    return "decodeArrayPointer(%s)" % CodecType(kind.kind)
  if mojom.IsInterfaceKind(kind):
    return "decodeStruct(%s)" % CodecType(kind)
  if mojom.IsUnionKind(kind):
    return "decodeUnion(%s)" % CodecType(kind)
  if mojom.IsInterfaceRequestKind(kind):
    return JavaScriptDecodeSnippet(mojom.MSGPIPE)
  if mojom.IsEnumKind(kind):
    return JavaScriptDecodeSnippet(mojom.INT32)
  raise Exception("No decode snippet for %s" % kind)


def JavaScriptEncodeSnippet(kind):
  if kind in mojom.PRIMITIVES or mojom.IsUnionKind(kind):
    return "encodeStruct(%s, " % CodecType(kind)
  if mojom.IsUnionKind(kind):
    return "encodeStruct(%s, " % JavaScriptType(kind)
  if mojom.IsStructKind(kind):
    return "encodeStructPointer(%s, " % JavaScriptType(kind)
  if mojom.IsMapKind(kind):
    return "encodeMapPointer(%s, %s, " % \
        (ElementCodecType(kind.key_kind), ElementCodecType(kind.value_kind))
  if mojom.IsArrayKind(kind) and mojom.IsBoolKind(kind.kind):
    return "encodeArrayPointer(codec.PackedBool, ";
  if mojom.IsArrayKind(kind):
    return "encodeArrayPointer(%s, " % CodecType(kind.kind)
  if mojom.IsInterfaceKind(kind):
    return "encodeStruct(%s, " % CodecType(kind)
  if mojom.IsInterfaceRequestKind(kind):
    return JavaScriptEncodeSnippet(mojom.MSGPIPE)
  if mojom.IsEnumKind(kind):
    return JavaScriptEncodeSnippet(mojom.INT32)
  raise Exception("No encode snippet for %s" % kind)


def JavaScriptUnionDecodeSnippet(kind):
  if mojom.IsUnionKind(kind):
    return "decodeStructPointer(%s)" % JavaScriptType(kind)
  return JavaScriptDecodeSnippet(kind)


def JavaScriptUnionEncodeSnippet(kind):
  if mojom.IsUnionKind(kind):
    return "encodeStructPointer(%s, " % JavaScriptType(kind)
  return JavaScriptEncodeSnippet(kind)


def JavaScriptFieldOffset(packed_field):
  return "offset + codec.kStructHeaderSize + %s" % packed_field.offset


def JavaScriptNullableParam(field):
  return "true" if mojom.IsNullableKind(field.kind) else "false"


def GetArrayExpectedDimensionSizes(kind):
  expected_dimension_sizes = []
  while mojom.IsArrayKind(kind):
    expected_dimension_sizes.append(generator.ExpectedArraySize(kind) or 0)
    kind = kind.kind
  # Strings are serialized as variable-length arrays.
  if (mojom.IsStringKind(kind)):
    expected_dimension_sizes.append(0)
  return expected_dimension_sizes


def JavaScriptValidateArrayParams(field):
  nullable = JavaScriptNullableParam(field)
  element_kind = field.kind.kind
  element_size = pack.PackedField.GetSizeForKind(element_kind)
  expected_dimension_sizes = GetArrayExpectedDimensionSizes(
      field.kind)
  element_type = ElementCodecType(element_kind)
  return "%s, %s, %s, %s, 0" % \
      (element_size, element_type, nullable,
       expected_dimension_sizes)


def JavaScriptValidateStructParams(field):
  nullable = JavaScriptNullableParam(field)
  struct_type = JavaScriptType(field.kind)
  return "%s, %s" % (struct_type, nullable)

def JavaScriptValidateUnionParams(field):
  nullable = JavaScriptNullableParam(field)
  union_type = JavaScriptType(field.kind)
  return "%s, %s" % (union_type, nullable)

def JavaScriptValidateMapParams(field):
  nullable = JavaScriptNullableParam(field)
  keys_type = ElementCodecType(field.kind.key_kind)
  values_kind = field.kind.value_kind;
  values_type = ElementCodecType(values_kind)
  values_nullable = "true" if mojom.IsNullableKind(values_kind) else "false"
  return "%s, %s, %s, %s" % \
      (nullable, keys_type, values_type, values_nullable)


def JavaScriptValidateStringParams(field):
  nullable = JavaScriptNullableParam(field)
  return "%s" % (nullable)


def JavaScriptValidateHandleParams(field):
  nullable = JavaScriptNullableParam(field)
  return "%s" % (nullable)

def JavaScriptValidateInterfaceParams(field):
  return JavaScriptValidateHandleParams(field)

def JavaScriptProxyMethodParameterValue(parameter):
  name = parameter.name;
  if (mojom.IsInterfaceKind(parameter.kind)):
   type = JavaScriptType(parameter.kind)
   return "core.isHandle(%s) ? %s : connection.bindImpl" \
       "(%s, %s)" % (name, name, name, type)
  if (mojom.IsInterfaceRequestKind(parameter.kind)):
   type = JavaScriptType(parameter.kind.kind)
   return "core.isHandle(%s) ? %s : connection.bindProxy" \
       "(%s, %s)" % (name, name, name, type)
  return name;


def JavaScriptStubMethodParameterValue(parameter):
  name = parameter.name;
  if (mojom.IsInterfaceKind(parameter.kind)):
   type = JavaScriptType(parameter.kind)
   return "connection.bindHandleToProxy(%s, %s)" % (name, type)
  if (mojom.IsInterfaceRequestKind(parameter.kind)):
   type = JavaScriptType(parameter.kind.kind)
   return "connection.bindHandleToStub(%s, %s)" % (name, type)
  return name;


def TranslateConstants(token):
  if isinstance(token, (mojom.EnumValue, mojom.NamedValue)):
    # Both variable and enum constants are constructed like:
    # NamespaceUid.Struct[.Enum].CONSTANT_NAME
    name = []
    if token.imported_from:
      name.append(token.imported_from["unique_name"])
    if token.parent_kind:
      name.append(token.parent_kind.name)
    if isinstance(token, mojom.EnumValue):
      name.append(token.enum.name)
    name.append(token.name)
    return ".".join(name)

  if isinstance(token, mojom.BuiltinValue):
    if token.value == "double.INFINITY" or token.value == "float.INFINITY":
      return "Infinity";
    if token.value == "double.NEGATIVE_INFINITY" or \
       token.value == "float.NEGATIVE_INFINITY":
      return "-Infinity";
    if token.value == "double.NAN" or token.value == "float.NAN":
      return "NaN";

  return token


def ExpressionToText(value):
  return TranslateConstants(value)

def IsArrayPointerField(field):
  return mojom.IsArrayKind(field.kind)

def IsStringPointerField(field):
  return mojom.IsStringKind(field.kind)

def IsStructPointerField(field):
  return mojom.IsStructKind(field.kind)

def IsMapPointerField(field):
  return mojom.IsMapKind(field.kind)

def IsHandleField(field):
  return mojom.IsAnyHandleKind(field.kind)

def IsInterfaceField(field):
  return mojom.IsInterfaceKind(field.kind)

def IsUnionField(field):
  return mojom.IsUnionKind(field.kind)


class Generator(generator.Generator):

  js_filters = {
    "default_value": JavaScriptDefaultValue,
    "payload_size": JavaScriptPayloadSize,
    "decode_snippet": JavaScriptDecodeSnippet,
    "encode_snippet": JavaScriptEncodeSnippet,
    "union_decode_snippet": JavaScriptUnionDecodeSnippet,
    "union_encode_snippet": JavaScriptUnionEncodeSnippet,
    "expression_to_text": ExpressionToText,
    "field_offset": JavaScriptFieldOffset,
    "has_callbacks": mojom.HasCallbacks,
    "is_array_pointer_field": IsArrayPointerField,
    "is_map_pointer_field": IsMapPointerField,
    "is_struct_pointer_field": IsStructPointerField,
    "is_string_pointer_field": IsStringPointerField,
    "is_union_field": IsUnionField,
    "is_handle_field": IsHandleField,
    "is_interface_field": IsInterfaceField,
    "js_type": JavaScriptType,
    "js_proxy_method_parameter_value": JavaScriptProxyMethodParameterValue,
    "js_stub_method_parameter_value": JavaScriptStubMethodParameterValue,
    "stylize_method": generator.StudlyCapsToCamel,
    "validate_array_params": JavaScriptValidateArrayParams,
    "validate_handle_params": JavaScriptValidateHandleParams,
    "validate_interface_params": JavaScriptValidateInterfaceParams,
    "validate_map_params": JavaScriptValidateMapParams,
    "validate_string_params": JavaScriptValidateStringParams,
    "validate_struct_params": JavaScriptValidateStructParams,
    "validate_union_params": JavaScriptValidateUnionParams,
  }

  def GetParameters(self):
    return {
      "namespace": self.module.namespace,
      "imports": self.GetImports(),
      "kinds": self.module.kinds,
      "enums": self.module.enums,
      "module": self.module,
      "structs": self.GetStructs() + self.GetStructsFromMethods(),
      "unions": self.GetUnions(),
      "interfaces": self.GetInterfaces(),
      "imported_interfaces": self.GetImportedInterfaces(),
    }

  @UseJinja("js_templates/module.amd.tmpl", filters=js_filters)
  def GenerateAMDModule(self):
    return self.GetParameters()

  def GenerateFiles(self, args):
    self.Write(self.GenerateAMDModule(),
        self.MatchMojomFilePath("%s.js" % self.module.name))

  def GetImports(self):
    used_names = set()
    for each_import in self.module.imports:
      simple_name = each_import["module_name"].split(".")[0]

      # Since each import is assigned a variable in JS, they need to have unique
      # names.
      unique_name = simple_name
      counter = 0
      while unique_name in used_names:
        counter += 1
        unique_name = simple_name + str(counter)

      used_names.add(unique_name)
      each_import["unique_name"] = unique_name + "$"
      counter += 1
    return self.module.imports

  def GetImportedInterfaces(self):
    interface_to_import = {};
    for each_import in self.module.imports:
      for each_interface in each_import["module"].interfaces:
        name = each_interface.name
        interface_to_import[name] = each_import["unique_name"] + "." + name
    return interface_to_import;

