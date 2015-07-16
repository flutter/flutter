# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Resolves the values used for constants and enums."""

from itertools import ifilter
import mojom.generate.module as mojom

def ResolveConstants(module, expression_to_text):
  in_progress = set()
  computed = set()

  def GetResolvedValue(named_value):
    assert isinstance(named_value, (mojom.EnumValue, mojom.ConstantValue))
    if isinstance(named_value, mojom.EnumValue):
      field = next(ifilter(lambda field: field.name == named_value.name,
                           named_value.enum.fields), None)
      if not field:
        raise RuntimeError(
            'Unable to get computed value for field %s of enum %s' %
            (named_value.name, named_value.enum.name))
      if field not in computed:
        ResolveEnum(named_value.enum)
      return field.resolved_value
    else:
      ResolveConstant(named_value.constant)
      named_value.resolved_value = named_value.constant.resolved_value
      return named_value.resolved_value

  def ResolveConstant(constant):
    if constant in computed:
      return
    if constant in in_progress:
      raise RuntimeError('Circular dependency for constant: %s' % constant.name)
    in_progress.add(constant)
    if isinstance(constant.value, (mojom.EnumValue, mojom.ConstantValue)):
      resolved_value = GetResolvedValue(constant.value)
    else:
      resolved_value = expression_to_text(constant.value)
    constant.resolved_value = resolved_value
    in_progress.remove(constant)
    computed.add(constant)

  def ResolveEnum(enum):
    def ResolveEnumField(enum, field, default_value):
      if field in computed:
        return
      if field in in_progress:
        raise RuntimeError('Circular dependency for enum: %s' % enum.name)
      in_progress.add(field)
      if field.value:
        if isinstance(field.value, mojom.EnumValue):
          resolved_value = GetResolvedValue(field.value)
        elif isinstance(field.value, str):
          resolved_value = int(field.value, 0)
        else:
          raise RuntimeError('Unexpected value: %s' % field.value)
      else:
        resolved_value = default_value
      field.resolved_value = resolved_value
      in_progress.remove(field)
      computed.add(field)

    current_value = 0
    for field in enum.fields:
      ResolveEnumField(enum, field, current_value)
      current_value = field.resolved_value + 1

  for constant in module.constants:
    ResolveConstant(constant)

  for enum in module.enums:
    ResolveEnum(enum)

  for struct in module.structs:
    for constant in struct.constants:
      ResolveConstant(constant)
    for enum in struct.enums:
      ResolveEnum(enum)
    for field in struct.fields:
      if isinstance(field.default, (mojom.ConstantValue, mojom.EnumValue)):
        field.default.resolved_value = GetResolvedValue(field.default)

  for interface in module.interfaces:
    for constant in interface.constants:
      ResolveConstant(constant)
    for enum in interface.enums:
      ResolveEnum(enum)

  return module
