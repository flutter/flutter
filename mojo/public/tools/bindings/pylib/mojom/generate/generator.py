# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Code shared by the various language-specific code generators."""

from functools import partial
import os.path
import re

import module as mojom
import mojom.fileutil as fileutil
import pack

def ExpectedArraySize(kind):
  if mojom.IsArrayKind(kind):
    return kind.length
  return None

def StudlyCapsToCamel(studly):
  return studly[0].lower() + studly[1:]

def CamelCaseToAllCaps(camel_case):
  return '_'.join(
      word for word in re.split(r'([A-Z][^A-Z]+)', camel_case) if word).upper()

def UnderToCamel(under):
  """Converts underscore_separated strings to CamelCase strings."""
  return ''.join(word.capitalize() for word in under.split('_'))

def WriteFile(contents, full_path):
  # Make sure the containing directory exists.
  full_dir = os.path.dirname(full_path)
  fileutil.EnsureDirectoryExists(full_dir)

  # Dump the data to disk.
  with open(full_path, "w+") as f:
    f.write(contents)

class Generator(object):
  # Pass |output_dir| to emit files to disk. Omit |output_dir| to echo all
  # files to stdout.
  def __init__(self, module, output_dir=None):
    self.module = module
    self.output_dir = output_dir

  def GetStructsFromMethods(self):
    result = []
    for interface in self.module.interfaces:
      for method in interface.methods:
        result.append(self._GetStructFromMethod(method))
        if method.response_parameters != None:
          result.append(self._GetResponseStructFromMethod(method))
    return result

  def GetStructs(self):
    return map(partial(self._AddStructComputedData, True), self.module.structs)

  def GetUnions(self):
    return map(self._AddUnionComputedData, self.module.unions)

  def GetInterfaces(self):
    return map(self._AddInterfaceComputedData, self.module.interfaces)

  # Prepend the filename with a directory that matches the directory of the
  # original .mojom file, relative to the import root.
  def MatchMojomFilePath(self, filename):
    return os.path.join(os.path.dirname(self.module.path), filename)

  def Write(self, contents, filename):
    if self.output_dir is None:
      print contents
      return
    full_path = os.path.join(self.output_dir, filename)
    WriteFile(contents, full_path)

  def GenerateFiles(self, args):
    raise NotImplementedError("Subclasses must override/implement this method")

  def GetJinjaParameters(self):
    """Returns default constructor parameters for the jinja environment."""
    return {}

  def GetGlobals(self):
    """Returns global mappings for the template generation."""
    return {}

  def _AddStructComputedData(self, exported, struct):
    """Adds computed data to the given struct. The data is computed once and
    used repeatedly in the generation process."""
    struct.packed = pack.PackedStruct(struct)
    struct.bytes = pack.GetByteLayout(struct.packed)
    struct.versions = pack.GetVersionInfo(struct.packed)
    struct.exported = exported
    return struct

  def _AddUnionComputedData(self, union):
    """Adds computed data to the given union. The data is computed once and
    used repeatedly in the generation process."""
    ordinal = 0
    for field in union.fields:
      if field.ordinal is not None:
        ordinal = field.ordinal
      field.ordinal = ordinal
      ordinal += 1
    return union

  def _AddInterfaceComputedData(self, interface):
    """Adds computed data to the given interface. The data is computed once and
    used repeatedly in the generation process."""
    interface.version = 0
    for method in interface.methods:
      if method.min_version is not None:
        interface.version = max(interface.version, method.min_version)

      method.param_struct = self._GetStructFromMethod(method)
      interface.version = max(interface.version,
                              method.param_struct.versions[-1].version)

      if method.response_parameters is not None:
        method.response_param_struct = self._GetResponseStructFromMethod(method)
        interface.version = max(
            interface.version,
            method.response_param_struct.versions[-1].version)
      else:
        method.response_param_struct = None
    return interface

  def _GetStructFromMethod(self, method):
    """Converts a method's parameters into the fields of a struct."""
    params_class = "%s_%s_Params" % (method.interface.name, method.name)
    struct = mojom.Struct(params_class, module=method.interface.module)
    for param in method.parameters:
      struct.AddField(param.name, param.kind, param.ordinal,
                      attributes=param.attributes)
    return self._AddStructComputedData(False, struct)

  def _GetResponseStructFromMethod(self, method):
    """Converts a method's response_parameters into the fields of a struct."""
    params_class = "%s_%s_ResponseParams" % (method.interface.name, method.name)
    struct = mojom.Struct(params_class, module=method.interface.module)
    for param in method.response_parameters:
      struct.AddField(param.name, param.kind, param.ordinal,
                      attributes=param.attributes)
    return self._AddStructComputedData(False, struct)
