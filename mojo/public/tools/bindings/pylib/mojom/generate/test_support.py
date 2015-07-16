# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys
import traceback

import module as mojom

# Support for writing mojom test cases.
# RunTest(fn) will execute fn, catching any exceptions. fn should return
# the number of errors that are encountered.
#
# EXPECT_EQ(a, b) and EXPECT_TRUE(b) will print error information if the
# expectations are not true and return a non zero value. This allows test cases
# to be written like this
#
# def Foo():
#   errors = 0
#   errors += EXPECT_EQ('test', test())
#   ...
#   return errors
#
# RunTest(foo)

def FieldsAreEqual(field1, field2):
  if field1 == field2:
    return True
  return field1.name == field2.name and \
      KindsAreEqual(field1.kind, field2.kind) and \
      field1.ordinal == field2.ordinal and \
      field1.default == field2.default


def KindsAreEqual(kind1, kind2):
  if kind1 == kind2:
    return True
  if kind1.__class__ != kind2.__class__ or kind1.spec != kind2.spec:
    return False
  if kind1.__class__ == mojom.Kind:
    return kind1.spec == kind2.spec
  if kind1.__class__ == mojom.Struct:
    if kind1.name != kind2.name or \
        kind1.spec != kind2.spec or \
        len(kind1.fields) != len(kind2.fields):
      return False
    for i in range(len(kind1.fields)):
      if not FieldsAreEqual(kind1.fields[i], kind2.fields[i]):
        return False
    return True
  if kind1.__class__ == mojom.Array:
    return KindsAreEqual(kind1.kind, kind2.kind)
  print 'Unknown Kind class: ', kind1.__class__.__name__
  return False


def ParametersAreEqual(parameter1, parameter2):
  if parameter1 == parameter2:
    return True
  return parameter1.name == parameter2.name and \
     parameter1.ordinal == parameter2.ordinal and \
     parameter1.default == parameter2.default and \
     KindsAreEqual(parameter1.kind, parameter2.kind)


def MethodsAreEqual(method1, method2):
  if method1 == method2:
    return True
  if method1.name != method2.name or \
      method1.ordinal != method2.ordinal or \
      len(method1.parameters) != len(method2.parameters):
    return False
  for i in range(len(method1.parameters)):
    if not ParametersAreEqual(method1.parameters[i], method2.parameters[i]):
      return False
  return True


def InterfacesAreEqual(interface1, interface2):
  if interface1 == interface2:
    return True
  if interface1.name != interface2.name or \
      len(interface1.methods) != len(interface2.methods):
    return False
  for i in range(len(interface1.methods)):
    if not MethodsAreEqual(interface1.methods[i], interface2.methods[i]):
      return False
  return True


def ModulesAreEqual(module1, module2):
  if module1 == module2:
    return True
  if module1.name != module2.name or \
      module1.namespace != module2.namespace or \
      len(module1.structs) != len(module2.structs) or \
      len(module1.interfaces) != len(module2.interfaces):
    return False
  for i in range(len(module1.structs)):
    if not KindsAreEqual(module1.structs[i], module2.structs[i]):
      return False
  for i in range(len(module1.interfaces)):
    if not InterfacesAreEqual(module1.interfaces[i], module2.interfaces[i]):
      return False
  return True


# Builds and returns a Module suitable for testing/
def BuildTestModule():
  module = mojom.Module('test', 'testspace')
  struct = module.AddStruct('teststruct')
  struct.AddField('testfield1', mojom.INT32)
  struct.AddField('testfield2', mojom.Array(mojom.INT32), 42)

  interface = module.AddInterface('Server')
  method = interface.AddMethod('Foo', 42)
  method.AddParameter('foo', mojom.INT32)
  method.AddParameter('bar', mojom.Array(struct))

  return module


# Tests if |module| is as built by BuildTestModule(). Returns the number of
# errors
def TestTestModule(module):
  errors = 0

  errors += EXPECT_EQ('test', module.name)
  errors += EXPECT_EQ('testspace', module.namespace)
  errors += EXPECT_EQ(1, len(module.structs))
  errors += EXPECT_EQ('teststruct', module.structs[0].name)
  errors += EXPECT_EQ(2, len(module.structs[0].fields))
  errors += EXPECT_EQ('testfield1', module.structs[0].fields[0].name)
  errors += EXPECT_EQ(mojom.INT32, module.structs[0].fields[0].kind)
  errors += EXPECT_EQ('testfield2', module.structs[0].fields[1].name)
  errors += EXPECT_EQ(mojom.Array, module.structs[0].fields[1].kind.__class__)
  errors += EXPECT_EQ(mojom.INT32, module.structs[0].fields[1].kind.kind)

  errors += EXPECT_EQ(1, len(module.interfaces))
  errors += EXPECT_EQ('Server', module.interfaces[0].name)
  errors += EXPECT_EQ(1, len(module.interfaces[0].methods))
  errors += EXPECT_EQ('Foo', module.interfaces[0].methods[0].name)
  errors += EXPECT_EQ(2, len(module.interfaces[0].methods[0].parameters))
  errors += EXPECT_EQ('foo', module.interfaces[0].methods[0].parameters[0].name)
  errors += EXPECT_EQ(mojom.INT32,
                      module.interfaces[0].methods[0].parameters[0].kind)
  errors += EXPECT_EQ('bar', module.interfaces[0].methods[0].parameters[1].name)
  errors += EXPECT_EQ(
    mojom.Array,
    module.interfaces[0].methods[0].parameters[1].kind.__class__)
  errors += EXPECT_EQ(
    module.structs[0],
    module.interfaces[0].methods[0].parameters[1].kind.kind)
  return errors


def PrintFailure(string):
  stack = traceback.extract_stack()
  frame = stack[len(stack)-3]
  sys.stderr.write("ERROR at %s:%d, %s\n" % (frame[0], frame[1], string))
  print "Traceback:"
  for line in traceback.format_list(stack[:len(stack)-2]):
    sys.stderr.write(line)


def EXPECT_EQ(a, b):
  if a != b:
    PrintFailure("%s != %s" % (a, b))
    return 1
  return 0


def EXPECT_TRUE(a):
  if not a:
    PrintFailure('Expecting True')
    return 1
  return 0


def RunTest(fn):
  sys.stdout.write('Running %s...' % fn.__name__)
  try:
    errors = fn()
  except:
    traceback.print_exc(sys.stderr)
    errors = 1
  if errors == 0:
    sys.stdout.write('OK\n')
  elif errors == 1:
    sys.stdout.write('1 ERROR\n')
  else:
    sys.stdout.write('%d ERRORS\n' % errors)
  return errors
