#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Extracts native methods from a Java file and generates the JNI bindings.
If you change this, please run and update the tests."""

import collections
import errno
import optparse
import os
import re
import string
from string import Template
import subprocess
import sys
import textwrap
import zipfile

CHROMIUM_SRC = os.path.join(
    os.path.dirname(__file__), os.pardir, os.pardir, os.pardir)
BUILD_ANDROID_GYP = os.path.join(
    CHROMIUM_SRC, 'build', 'android', 'gyp')

sys.path.append(BUILD_ANDROID_GYP)

from util import build_utils


class ParseError(Exception):
  """Exception thrown when we can't parse the input file."""

  def __init__(self, description, *context_lines):
    Exception.__init__(self)
    self.description = description
    self.context_lines = context_lines

  def __str__(self):
    context = '\n'.join(self.context_lines)
    return '***\nERROR: %s\n\n%s\n***' % (self.description, context)


class Param(object):
  """Describes a param for a method, either java or native."""

  def __init__(self, **kwargs):
    self.datatype = kwargs['datatype']
    self.name = kwargs['name']


class NativeMethod(object):
  """Describes a C/C++ method that is called by Java code"""

  def __init__(self, **kwargs):
    self.static = kwargs['static']
    self.java_class_name = kwargs['java_class_name']
    self.return_type = kwargs['return_type']
    self.name = kwargs['name']
    self.params = kwargs['params']
    if self.params:
      assert type(self.params) is list
      assert type(self.params[0]) is Param
    if (self.params and
        self.params[0].datatype == kwargs.get('ptr_type', 'int') and
        self.params[0].name.startswith('native')):
      self.type = 'method'
      self.p0_type = self.params[0].name[len('native'):]
      if kwargs.get('native_class_name'):
        self.p0_type = kwargs['native_class_name']
    else:
      self.type = 'function'
    self.method_id_var_name = kwargs.get('method_id_var_name', None)


class CalledByNative(object):
  """Describes a java method exported to c/c++"""

  def __init__(self, **kwargs):
    self.system_class = kwargs['system_class']
    self.unchecked = kwargs['unchecked']
    self.static = kwargs['static']
    self.java_class_name = kwargs['java_class_name']
    self.return_type = kwargs['return_type']
    self.name = kwargs['name']
    self.params = kwargs['params']
    self.method_id_var_name = kwargs.get('method_id_var_name', None)
    self.signature = kwargs.get('signature')
    self.is_constructor = kwargs.get('is_constructor', False)
    self.env_call = GetEnvCall(self.is_constructor, self.static,
                               self.return_type)
    self.static_cast = GetStaticCastForReturnType(self.return_type)


class ConstantField(object):
  def __init__(self, **kwargs):
    self.name = kwargs['name']
    self.value = kwargs['value']


def JavaDataTypeToC(java_type):
  """Returns a C datatype for the given java type."""
  java_pod_type_map = {
      'int': 'jint',
      'byte': 'jbyte',
      'char': 'jchar',
      'short': 'jshort',
      'boolean': 'jboolean',
      'long': 'jlong',
      'double': 'jdouble',
      'float': 'jfloat',
  }
  java_type_map = {
      'void': 'void',
      'String': 'jstring',
      'java/lang/String': 'jstring',
      'java/lang/Class': 'jclass',
  }

  if java_type in java_pod_type_map:
    return java_pod_type_map[java_type]
  elif java_type in java_type_map:
    return java_type_map[java_type]
  elif java_type.endswith('[]'):
    if java_type[:-2] in java_pod_type_map:
      return java_pod_type_map[java_type[:-2]] + 'Array'
    return 'jobjectArray'
  elif java_type.startswith('Class'):
    # Checking just the start of the name, rather than a direct comparison,
    # in order to handle generics.
    return 'jclass'
  else:
    return 'jobject'


def JavaDataTypeToCForCalledByNativeParam(java_type):
  """Returns a C datatype to be when calling from native."""
  if java_type == 'int':
    return 'JniIntWrapper'
  else:
    return JavaDataTypeToC(java_type)


def JavaReturnValueToC(java_type):
  """Returns a valid C return value for the given java type."""
  java_pod_type_map = {
      'int': '0',
      'byte': '0',
      'char': '0',
      'short': '0',
      'boolean': 'false',
      'long': '0',
      'double': '0',
      'float': '0',
      'void': ''
  }
  return java_pod_type_map.get(java_type, 'NULL')


class JniParams(object):
  _imports = []
  _fully_qualified_class = ''
  _package = ''
  _inner_classes = []
  _remappings = []
  _implicit_imports = []

  @staticmethod
  def SetFullyQualifiedClass(fully_qualified_class):
    JniParams._fully_qualified_class = 'L' + fully_qualified_class
    JniParams._package = '/'.join(fully_qualified_class.split('/')[:-1])

  @staticmethod
  def AddAdditionalImport(class_name):
    assert class_name.endswith('.class')
    raw_class_name = class_name[:-len('.class')]
    if '.' in raw_class_name:
      raise SyntaxError('%s cannot be used in @JNIAdditionalImport. '
                        'Only import unqualified outer classes.' % class_name)
    new_import = 'L%s/%s' % (JniParams._package, raw_class_name)
    if new_import in JniParams._imports:
      raise SyntaxError('Do not use JNIAdditionalImport on an already '
                        'imported class: %s' % (new_import.replace('/', '.')))
    JniParams._imports += [new_import]

  @staticmethod
  def ExtractImportsAndInnerClasses(contents):
    if not JniParams._package:
      raise RuntimeError('SetFullyQualifiedClass must be called before '
                         'ExtractImportsAndInnerClasses')
    contents = contents.replace('\n', '')
    re_import = re.compile(r'import.*?(?P<class>\S*?);')
    for match in re.finditer(re_import, contents):
      JniParams._imports += ['L' + match.group('class').replace('.', '/')]

    re_inner = re.compile(r'(class|interface)\s+?(?P<name>\w+?)\W')
    for match in re.finditer(re_inner, contents):
      inner = match.group('name')
      if not JniParams._fully_qualified_class.endswith(inner):
        JniParams._inner_classes += [JniParams._fully_qualified_class + '$' +
                                     inner]

    re_additional_imports = re.compile(
        r'@JNIAdditionalImport\(\s*{?(?P<class_names>.*?)}?\s*\)')
    for match in re.finditer(re_additional_imports, contents):
      for class_name in match.group('class_names').split(','):
        JniParams.AddAdditionalImport(class_name.strip())

  @staticmethod
  def ParseJavaPSignature(signature_line):
    prefix = 'Signature: '
    index = signature_line.find(prefix)
    if index == -1:
      prefix = 'descriptor: '
      index = signature_line.index(prefix)
    return '"%s"' % signature_line[index + len(prefix):]

  @staticmethod
  def JavaToJni(param):
    """Converts a java param into a JNI signature type."""
    pod_param_map = {
        'int': 'I',
        'boolean': 'Z',
        'char': 'C',
        'short': 'S',
        'long': 'J',
        'double': 'D',
        'float': 'F',
        'byte': 'B',
        'void': 'V',
    }
    object_param_list = [
        'Ljava/lang/Boolean',
        'Ljava/lang/Integer',
        'Ljava/lang/Long',
        'Ljava/lang/Object',
        'Ljava/lang/String',
        'Ljava/lang/Class',
        'Ljava/lang/CharSequence',
        'Ljava/lang/Runnable',
        'Ljava/lang/Throwable',
    ]

    prefix = ''
    # Array?
    while param[-2:] == '[]':
      prefix += '['
      param = param[:-2]
    # Generic?
    if '<' in param:
      param = param[:param.index('<')]
    if param in pod_param_map:
      return prefix + pod_param_map[param]
    if '/' in param:
      # Coming from javap, use the fully qualified param directly.
      return prefix + 'L' + JniParams.RemapClassName(param) + ';'

    for qualified_name in (object_param_list +
                           [JniParams._fully_qualified_class] +
                           JniParams._inner_classes):
      if (qualified_name.endswith('/' + param) or
          qualified_name.endswith('$' + param.replace('.', '$')) or
          qualified_name == 'L' + param):
        return prefix + JniParams.RemapClassName(qualified_name) + ';'

    # Is it from an import? (e.g. referecing Class from import pkg.Class;
    # note that referencing an inner class Inner from import pkg.Class.Inner
    # is not supported).
    for qualified_name in JniParams._imports:
      if qualified_name.endswith('/' + param):
        # Ensure it's not an inner class.
        components = qualified_name.split('/')
        if len(components) > 2 and components[-2][0].isupper():
          raise SyntaxError('Inner class (%s) can not be imported '
                            'and used by JNI (%s). Please import the outer '
                            'class and use Outer.Inner instead.' %
                            (qualified_name, param))
        return prefix + JniParams.RemapClassName(qualified_name) + ';'

    # Is it an inner class from an outer class import? (e.g. referencing
    # Class.Inner from import pkg.Class).
    if '.' in param:
      components = param.split('.')
      outer = '/'.join(components[:-1])
      inner = components[-1]
      for qualified_name in JniParams._imports:
        if qualified_name.endswith('/' + outer):
          return (prefix + JniParams.RemapClassName(qualified_name) +
                  '$' + inner + ';')
      raise SyntaxError('Inner class (%s) can not be '
                        'used directly by JNI. Please import the outer '
                        'class, probably:\n'
                        'import %s.%s;' %
                        (param, JniParams._package.replace('/', '.'),
                         outer.replace('/', '.')))

    JniParams._CheckImplicitImports(param)

    # Type not found, falling back to same package as this class.
    return (prefix + 'L' +
            JniParams.RemapClassName(JniParams._package + '/' + param) + ';')

  @staticmethod
  def _CheckImplicitImports(param):
    # Ensure implicit imports, such as java.lang.*, are not being treated
    # as being in the same package.
    if not JniParams._implicit_imports:
      # This file was generated from android.jar and lists
      # all classes that are implicitly imported.
      with file(os.path.join(os.path.dirname(sys.argv[0]),
                             'android_jar.classes'), 'r') as f:
        JniParams._implicit_imports = f.readlines()
    for implicit_import in JniParams._implicit_imports:
      implicit_import = implicit_import.strip().replace('.class', '')
      implicit_import = implicit_import.replace('/', '.')
      if implicit_import.endswith('.' + param):
        raise SyntaxError('Ambiguous class (%s) can not be used directly '
                          'by JNI.\nPlease import it, probably:\n\n'
                          'import %s;' %
                          (param, implicit_import))


  @staticmethod
  def Signature(params, returns, wrap):
    """Returns the JNI signature for the given datatypes."""
    items = ['(']
    items += [JniParams.JavaToJni(param.datatype) for param in params]
    items += [')']
    items += [JniParams.JavaToJni(returns)]
    if wrap:
      return '\n' + '\n'.join(['"' + item + '"' for item in items])
    else:
      return '"' + ''.join(items) + '"'

  @staticmethod
  def Parse(params):
    """Parses the params into a list of Param objects."""
    if not params:
      return []
    ret = []
    for p in [p.strip() for p in params.split(',')]:
      items = p.split(' ')
      if 'final' in items:
        items.remove('final')
      param = Param(
          datatype=items[0],
          name=(items[1] if len(items) > 1 else 'p%s' % len(ret)),
      )
      ret += [param]
    return ret

  @staticmethod
  def RemapClassName(class_name):
    """Remaps class names using the jarjar mapping table."""
    for old, new in JniParams._remappings:
      if old.endswith('**') and old[:-2] in class_name:
        return class_name.replace(old[:-2], new, 1)
      if '*' not in old and class_name.endswith(old):
        return class_name.replace(old, new, 1)

    return class_name

  @staticmethod
  def SetJarJarMappings(mappings):
    """Parse jarjar mappings from a string."""
    JniParams._remappings = []
    for line in mappings.splitlines():
      rule = line.split()
      if rule[0] != 'rule':
        continue
      _, src, dest = rule
      src = src.replace('.', '/')
      dest = dest.replace('.', '/')
      if src.endswith('**'):
        src_real_name = src[:-2]
      else:
        assert not '*' in src
        src_real_name = src

      if dest.endswith('@0'):
        JniParams._remappings.append((src, dest[:-2] + src_real_name))
      elif dest.endswith('@1'):
        assert '**' in src
        JniParams._remappings.append((src, dest[:-2]))
      else:
        assert not '@' in dest
        JniParams._remappings.append((src, dest))


def ExtractJNINamespace(contents):
  re_jni_namespace = re.compile('.*?@JNINamespace\("(.*?)"\)')
  m = re.findall(re_jni_namespace, contents)
  if not m:
    return ''
  return m[0]


def ExtractFullyQualifiedJavaClassName(java_file_name, contents):
  re_package = re.compile('.*?package (.*?);')
  matches = re.findall(re_package, contents)
  if not matches:
    raise SyntaxError('Unable to find "package" line in %s' % java_file_name)
  return (matches[0].replace('.', '/') + '/' +
          os.path.splitext(os.path.basename(java_file_name))[0])


def ExtractNatives(contents, ptr_type):
  """Returns a list of dict containing information about a native method."""
  contents = contents.replace('\n', '')
  natives = []
  re_native = re.compile(r'(@NativeClassQualifiedName'
                         '\(\"(?P<native_class_name>.*?)\"\)\s+)?'
                         '(@NativeCall(\(\"(?P<java_class_name>.*?)\"\))\s+)?'
                         '(?P<qualifiers>\w+\s\w+|\w+|\s+)\s*native '
                         '(?P<return_type>\S*) '
                         '(?P<name>native\w+)\((?P<params>.*?)\);')
  for match in re.finditer(re_native, contents):
    native = NativeMethod(
        static='static' in match.group('qualifiers'),
        java_class_name=match.group('java_class_name'),
        native_class_name=match.group('native_class_name'),
        return_type=match.group('return_type'),
        name=match.group('name').replace('native', ''),
        params=JniParams.Parse(match.group('params')),
        ptr_type=ptr_type)
    natives += [native]
  return natives


def GetStaticCastForReturnType(return_type):
  type_map = { 'String' : 'jstring',
               'java/lang/String' : 'jstring',
               'boolean[]': 'jbooleanArray',
               'byte[]': 'jbyteArray',
               'char[]': 'jcharArray',
               'short[]': 'jshortArray',
               'int[]': 'jintArray',
               'long[]': 'jlongArray',
               'float[]': 'jfloatArray',
               'double[]': 'jdoubleArray' }
  ret = type_map.get(return_type, None)
  if ret:
    return ret
  if return_type.endswith('[]'):
    return 'jobjectArray'
  return None


def GetEnvCall(is_constructor, is_static, return_type):
  """Maps the types availabe via env->Call__Method."""
  if is_constructor:
    return 'NewObject'
  env_call_map = {'boolean': 'Boolean',
                  'byte': 'Byte',
                  'char': 'Char',
                  'short': 'Short',
                  'int': 'Int',
                  'long': 'Long',
                  'float': 'Float',
                  'void': 'Void',
                  'double': 'Double',
                  'Object': 'Object',
                 }
  call = env_call_map.get(return_type, 'Object')
  if is_static:
    call = 'Static' + call
  return 'Call' + call + 'Method'


def GetMangledParam(datatype):
  """Returns a mangled identifier for the datatype."""
  if len(datatype) <= 2:
    return datatype.replace('[', 'A')
  ret = ''
  for i in range(1, len(datatype)):
    c = datatype[i]
    if c == '[':
      ret += 'A'
    elif c.isupper() or datatype[i - 1] in ['/', 'L']:
      ret += c.upper()
  return ret


def GetMangledMethodName(name, params, return_type):
  """Returns a mangled method name for the given signature.

     The returned name can be used as a C identifier and will be unique for all
     valid overloads of the same method.

  Args:
     name: string.
     params: list of Param.
     return_type: string.

  Returns:
      A mangled name.
  """
  mangled_items = []
  for datatype in [return_type] + [x.datatype for x in params]:
    mangled_items += [GetMangledParam(JniParams.JavaToJni(datatype))]
  mangled_name = name + '_'.join(mangled_items)
  assert re.match(r'[0-9a-zA-Z_]+', mangled_name)
  return mangled_name


def MangleCalledByNatives(called_by_natives):
  """Mangles all the overloads from the call_by_natives list."""
  method_counts = collections.defaultdict(
      lambda: collections.defaultdict(lambda: 0))
  for called_by_native in called_by_natives:
    java_class_name = called_by_native.java_class_name
    name = called_by_native.name
    method_counts[java_class_name][name] += 1
  for called_by_native in called_by_natives:
    java_class_name = called_by_native.java_class_name
    method_name = called_by_native.name
    method_id_var_name = method_name
    if method_counts[java_class_name][method_name] > 1:
      method_id_var_name = GetMangledMethodName(method_name,
                                                called_by_native.params,
                                                called_by_native.return_type)
    called_by_native.method_id_var_name = method_id_var_name
  return called_by_natives


# Regex to match the JNI return types that should be included in a
# ScopedJavaLocalRef.
RE_SCOPED_JNI_RETURN_TYPES = re.compile('jobject|jclass|jstring|.*Array')

# Regex to match a string like "@CalledByNative public void foo(int bar)".
RE_CALLED_BY_NATIVE = re.compile(
    '@CalledByNative(?P<Unchecked>(Unchecked)*?)(?:\("(?P<annotation>.*)"\))?'
    '\s+(?P<prefix>[\w ]*?)'
    '\s*(?P<return_type>\S+?)'
    '\s+(?P<name>\w+)'
    '\s*\((?P<params>[^\)]*)\)')


def ExtractCalledByNatives(contents):
  """Parses all methods annotated with @CalledByNative.

  Args:
    contents: the contents of the java file.

  Returns:
    A list of dict with information about the annotated methods.
    TODO(bulach): return a CalledByNative object.

  Raises:
    ParseError: if unable to parse.
  """
  called_by_natives = []
  for match in re.finditer(RE_CALLED_BY_NATIVE, contents):
    called_by_natives += [CalledByNative(
        system_class=False,
        unchecked='Unchecked' in match.group('Unchecked'),
        static='static' in match.group('prefix'),
        java_class_name=match.group('annotation') or '',
        return_type=match.group('return_type'),
        name=match.group('name'),
        params=JniParams.Parse(match.group('params')))]
  # Check for any @CalledByNative occurrences that weren't matched.
  unmatched_lines = re.sub(RE_CALLED_BY_NATIVE, '', contents).split('\n')
  for line1, line2 in zip(unmatched_lines, unmatched_lines[1:]):
    if '@CalledByNative' in line1:
      raise ParseError('could not parse @CalledByNative method signature',
                       line1, line2)
  return MangleCalledByNatives(called_by_natives)


class JNIFromJavaP(object):
  """Uses 'javap' to parse a .class file and generate the JNI header file."""

  def __init__(self, contents, options):
    self.contents = contents
    self.namespace = options.namespace
    for line in contents:
      class_name = re.match(
          '.*?(public).*?(class|interface) (?P<class_name>\S+?)( |\Z)',
          line)
      if class_name:
        self.fully_qualified_class = class_name.group('class_name')
        break
    self.fully_qualified_class = self.fully_qualified_class.replace('.', '/')
    # Java 7's javap includes type parameters in output, like HashSet<T>. Strip
    # away the <...> and use the raw class name that Java 6 would've given us.
    self.fully_qualified_class = self.fully_qualified_class.split('<', 1)[0]
    JniParams.SetFullyQualifiedClass(self.fully_qualified_class)
    self.java_class_name = self.fully_qualified_class.split('/')[-1]
    if not self.namespace:
      self.namespace = 'JNI_' + self.java_class_name
    re_method = re.compile('(?P<prefix>.*?)(?P<return_type>\S+?) (?P<name>\w+?)'
                           '\((?P<params>.*?)\)')
    self.called_by_natives = []
    for lineno, content in enumerate(contents[2:], 2):
      match = re.match(re_method, content)
      if not match:
        continue
      self.called_by_natives += [CalledByNative(
          system_class=True,
          unchecked=False,
          static='static' in match.group('prefix'),
          java_class_name='',
          return_type=match.group('return_type').replace('.', '/'),
          name=match.group('name'),
          params=JniParams.Parse(match.group('params').replace('.', '/')),
          signature=JniParams.ParseJavaPSignature(contents[lineno + 1]))]
    re_constructor = re.compile('(.*?)public ' +
                                self.fully_qualified_class.replace('/', '.') +
                                '\((?P<params>.*?)\)')
    for lineno, content in enumerate(contents[2:], 2):
      match = re.match(re_constructor, content)
      if not match:
        continue
      self.called_by_natives += [CalledByNative(
          system_class=True,
          unchecked=False,
          static=False,
          java_class_name='',
          return_type=self.fully_qualified_class,
          name='Constructor',
          params=JniParams.Parse(match.group('params').replace('.', '/')),
          signature=JniParams.ParseJavaPSignature(contents[lineno + 1]),
          is_constructor=True)]
    self.called_by_natives = MangleCalledByNatives(self.called_by_natives)

    self.constant_fields = []
    re_constant_field = re.compile('.*?public static final int (?P<name>.*?);')
    re_constant_field_value = re.compile(
        '.*?Constant(Value| value): int (?P<value>(-*[0-9]+)?)')
    for lineno, content in enumerate(contents[2:], 2):
      match = re.match(re_constant_field, content)
      if not match:
        continue
      value = re.match(re_constant_field_value, contents[lineno + 2])
      if not value:
        value = re.match(re_constant_field_value, contents[lineno + 3])
      if value:
        self.constant_fields.append(
            ConstantField(name=match.group('name'),
                          value=value.group('value')))

    self.inl_header_file_generator = InlHeaderFileGenerator(
        self.namespace, self.fully_qualified_class, [],
        self.called_by_natives, self.constant_fields, options)

  def GetContent(self):
    return self.inl_header_file_generator.GetContent()

  @staticmethod
  def CreateFromClass(class_file, options):
    class_name = os.path.splitext(os.path.basename(class_file))[0]
    p = subprocess.Popen(args=[options.javap, '-c', '-verbose',
                               '-s', class_name],
                         cwd=os.path.dirname(class_file),
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    stdout, _ = p.communicate()
    jni_from_javap = JNIFromJavaP(stdout.split('\n'), options)
    return jni_from_javap


class JNIFromJavaSource(object):
  """Uses the given java source file to generate the JNI header file."""

  # Match single line comments, multiline comments, character literals, and
  # double-quoted strings.
  _comment_remover_regex = re.compile(
      r'//.*?$|/\*.*?\*/|\'(?:\\.|[^\\\'])*\'|"(?:\\.|[^\\"])*"',
      re.DOTALL | re.MULTILINE)

  def __init__(self, contents, fully_qualified_class, options):
    contents = self._RemoveComments(contents)
    JniParams.SetFullyQualifiedClass(fully_qualified_class)
    JniParams.ExtractImportsAndInnerClasses(contents)
    jni_namespace = ExtractJNINamespace(contents) or options.namespace
    natives = ExtractNatives(contents, options.ptr_type)
    called_by_natives = ExtractCalledByNatives(contents)
    if len(natives) == 0 and len(called_by_natives) == 0:
      raise SyntaxError('Unable to find any JNI methods for %s.' %
                        fully_qualified_class)
    inl_header_file_generator = InlHeaderFileGenerator(
        jni_namespace, fully_qualified_class, natives, called_by_natives,
        [], options)
    self.content = inl_header_file_generator.GetContent()

  @classmethod
  def _RemoveComments(cls, contents):
    # We need to support both inline and block comments, and we need to handle
    # strings that contain '//' or '/*'.
    # TODO(bulach): This is a bit hacky. It would be cleaner to use a real Java
    # parser. Maybe we could ditch JNIFromJavaSource and just always use
    # JNIFromJavaP; or maybe we could rewrite this script in Java and use APT.
    # http://code.google.com/p/chromium/issues/detail?id=138941
    def replacer(match):
      # Replace matches that are comments with nothing; return literals/strings
      # unchanged.
      s = match.group(0)
      if s.startswith('/'):
        return ''
      else:
        return s
    return cls._comment_remover_regex.sub(replacer, contents)

  def GetContent(self):
    return self.content

  @staticmethod
  def CreateFromFile(java_file_name, options):
    contents = file(java_file_name).read()
    fully_qualified_class = ExtractFullyQualifiedJavaClassName(java_file_name,
                                                               contents)
    return JNIFromJavaSource(contents, fully_qualified_class, options)


class InlHeaderFileGenerator(object):
  """Generates an inline header file for JNI integration."""

  def __init__(self, namespace, fully_qualified_class, natives,
               called_by_natives, constant_fields, options):
    self.namespace = namespace
    self.fully_qualified_class = fully_qualified_class
    self.class_name = self.fully_qualified_class.split('/')[-1]
    self.natives = natives
    self.called_by_natives = called_by_natives
    self.header_guard = fully_qualified_class.replace('/', '_') + '_JNI'
    self.constant_fields = constant_fields
    self.options = options
    self.init_native = self.ExtractInitNative(options)

  def ExtractInitNative(self, options):
    for native in self.natives:
      if options.jni_init_native_name == 'native' + native.name:
        self.natives.remove(native)
        return native
    return None

  def GetContent(self):
    """Returns the content of the JNI binding file."""
    template = Template("""\
// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


// This file is autogenerated by
//     ${SCRIPT_NAME}
// For
//     ${FULLY_QUALIFIED_CLASS}

#ifndef ${HEADER_GUARD}
#define ${HEADER_GUARD}

#include <jni.h>

${INCLUDES}

#include "base/android/jni_int_wrapper.h"

// Step 1: forward declarations.
namespace {
$CLASS_PATH_DEFINITIONS
$METHOD_ID_DEFINITIONS
}  // namespace

$OPEN_NAMESPACE
$FORWARD_DECLARATIONS

$CONSTANT_FIELDS

// Step 2: method stubs.
$METHOD_STUBS

// Step 3: RegisterNatives.
$JNI_NATIVE_METHODS
$REGISTER_NATIVES
$CLOSE_NAMESPACE
$JNI_REGISTER_NATIVES
#endif  // ${HEADER_GUARD}
""")
    values = {
        'SCRIPT_NAME': self.options.script_name,
        'FULLY_QUALIFIED_CLASS': self.fully_qualified_class,
        'CLASS_PATH_DEFINITIONS': self.GetClassPathDefinitionsString(),
        'METHOD_ID_DEFINITIONS': self.GetMethodIDDefinitionsString(),
        'FORWARD_DECLARATIONS': self.GetForwardDeclarationsString(),
        'CONSTANT_FIELDS': self.GetConstantFieldsString(),
        'METHOD_STUBS': self.GetMethodStubsString(),
        'OPEN_NAMESPACE': self.GetOpenNamespaceString(),
        'JNI_NATIVE_METHODS': self.GetJNINativeMethodsString(),
        'REGISTER_NATIVES': self.GetRegisterNativesString(),
        'CLOSE_NAMESPACE': self.GetCloseNamespaceString(),
        'HEADER_GUARD': self.header_guard,
        'INCLUDES': self.GetIncludesString(),
        'JNI_REGISTER_NATIVES': self.GetJNIRegisterNativesString()
    }
    return WrapOutput(template.substitute(values))

  def GetClassPathDefinitionsString(self):
    ret = []
    ret += [self.GetClassPathDefinitions()]
    return '\n'.join(ret)

  def GetMethodIDDefinitionsString(self):
    """Returns the definition of method ids for the called by native methods."""
    if not self.options.eager_called_by_natives:
      return ''
    template = Template("""\
jmethodID g_${JAVA_CLASS}_${METHOD_ID_VAR_NAME} = NULL;""")
    ret = []
    for called_by_native in self.called_by_natives:
      values = {
          'JAVA_CLASS': called_by_native.java_class_name or self.class_name,
          'METHOD_ID_VAR_NAME': called_by_native.method_id_var_name,
      }
      ret += [template.substitute(values)]
    return '\n'.join(ret)

  def GetForwardDeclarationsString(self):
    ret = []
    for native in self.natives:
      if native.type != 'method':
        ret += [self.GetForwardDeclaration(native)]
    if self.options.native_exports and ret:
      return '\nextern "C" {\n' + "\n".join(ret) + '\n};  // extern "C"'
    return '\n'.join(ret)

  def GetConstantFieldsString(self):
    if not self.constant_fields:
      return ''
    ret = ['enum Java_%s_constant_fields {' % self.class_name]
    for c in self.constant_fields:
      ret += ['  %s = %s,' % (c.name, c.value)]
    ret += ['};']
    return '\n'.join(ret)

  def GetMethodStubsString(self):
    """Returns the code corresponding to method stubs."""
    ret = []
    for native in self.natives:
      if native.type == 'method':
        ret += [self.GetNativeMethodStubString(native)]
    if self.options.eager_called_by_natives:
      ret += self.GetEagerCalledByNativeMethodStubs()
    else:
      ret += self.GetLazyCalledByNativeMethodStubs()

    if self.options.native_exports and ret:
      return '\nextern "C" {\n' + "\n".join(ret) + '\n};  // extern "C"'
    return '\n'.join(ret)

  def GetLazyCalledByNativeMethodStubs(self):
    return [self.GetLazyCalledByNativeMethodStub(called_by_native)
            for called_by_native in self.called_by_natives]

  def GetEagerCalledByNativeMethodStubs(self):
    ret = []
    if self.called_by_natives:
      ret += ['namespace {']
      for called_by_native in self.called_by_natives:
        ret += [self.GetEagerCalledByNativeMethodStub(called_by_native)]
      ret += ['}  // namespace']
    return ret

  def GetIncludesString(self):
    if not self.options.includes:
      return ''
    includes = self.options.includes.split(',')
    return '\n'.join('#include "%s"' % x for x in includes)

  def GetKMethodsString(self, clazz):
    ret = []
    for native in self.natives:
      if (native.java_class_name == clazz or
          (not native.java_class_name and clazz == self.class_name)):
        ret += [self.GetKMethodArrayEntry(native)]
    return '\n'.join(ret)

  def SubstituteNativeMethods(self, template):
    """Substitutes JAVA_CLASS and KMETHODS in the provided template."""
    ret = []
    all_classes = self.GetUniqueClasses(self.natives)
    all_classes[self.class_name] = self.fully_qualified_class
    for clazz in all_classes:
      kmethods = self.GetKMethodsString(clazz)
      if kmethods:
        values = {'JAVA_CLASS': clazz,
                  'KMETHODS': kmethods}
        ret += [template.substitute(values)]
    if not ret: return ''
    return '\n' + '\n'.join(ret)

  def GetJNINativeMethodsString(self):
    """Returns the implementation of the array of native methods."""
    if self.options.native_exports and not self.options.native_exports_optional:
      return ''
    template = Template("""\
static const JNINativeMethod kMethods${JAVA_CLASS}[] = {
${KMETHODS}
};
""")
    return self.SubstituteNativeMethods(template)

  def GetRegisterCalledByNativesImplString(self):
    """Returns the code for registering the called by native methods."""
    if not self.options.eager_called_by_natives:
      return ''
    template = Template("""\
  g_${JAVA_CLASS}_${METHOD_ID_VAR_NAME} = ${GET_METHOD_ID_IMPL}
  if (g_${JAVA_CLASS}_${METHOD_ID_VAR_NAME} == NULL) {
    return false;
  }
    """)
    ret = []
    for called_by_native in self.called_by_natives:
      values = {
          'JAVA_CLASS': called_by_native.java_class_name or self.class_name,
          'METHOD_ID_VAR_NAME': called_by_native.method_id_var_name,
          'GET_METHOD_ID_IMPL': self.GetMethodIDImpl(called_by_native),
      }
      ret += [template.substitute(values)]
    return '\n'.join(ret)

  def GetRegisterNativesString(self):
    """Returns the code for RegisterNatives."""
    template = Template("""\
${REGISTER_NATIVES_SIGNATURE} {
${EARLY_EXIT}
${CLASSES}
${NATIVES}
${CALLED_BY_NATIVES}
  return true;
}
""")
    signature = 'static bool RegisterNativesImpl(JNIEnv* env'
    if self.init_native:
      signature += ', jclass clazz)'
    else:
      signature += ')'

    early_exit = ''
    if self.options.native_exports_optional:
      early_exit = """\
  if (base::android::IsManualJniRegistrationDisabled()) return true;
"""

    natives = self.GetRegisterNativesImplString()
    called_by_natives = self.GetRegisterCalledByNativesImplString()
    values = {'REGISTER_NATIVES_SIGNATURE': signature,
              'EARLY_EXIT': early_exit,
              'CLASSES': self.GetFindClasses(),
              'NATIVES': natives,
              'CALLED_BY_NATIVES': called_by_natives,
             }
    return template.substitute(values)

  def GetRegisterNativesImplString(self):
    """Returns the shared implementation for RegisterNatives."""
    if self.options.native_exports and not self.options.native_exports_optional:
      return ''

    template = Template("""\
  const int kMethods${JAVA_CLASS}Size = arraysize(kMethods${JAVA_CLASS});

  if (env->RegisterNatives(${JAVA_CLASS}_clazz(env),
                           kMethods${JAVA_CLASS},
                           kMethods${JAVA_CLASS}Size) < 0) {
    jni_generator::HandleRegistrationError(
        env, ${JAVA_CLASS}_clazz(env), __FILE__);
    return false;
  }
""")
    return self.SubstituteNativeMethods(template)

  def GetJNIRegisterNativesString(self):
    """Returns the implementation for the JNI registration of native methods."""
    if not self.init_native:
      return ''

    template = Template("""\
extern "C" JNIEXPORT bool JNICALL
Java_${FULLY_QUALIFIED_CLASS}_${INIT_NATIVE_NAME}(JNIEnv* env, jclass clazz) {
  return ${NAMESPACE}RegisterNativesImpl(env, clazz);
}
""")

    if self.options.native_exports:
      java_name = JniParams.RemapClassName(self.fully_qualified_class)
      java_name = java_name.replace('_', '_1').replace('/', '_')
    else:
      java_name = self.fully_qualified_class.replace('/', '_')

    namespace = ''
    if self.namespace:
      namespace = self.namespace + '::'
    values = {'FULLY_QUALIFIED_CLASS': java_name,
              'INIT_NATIVE_NAME': 'native' + self.init_native.name,
              'NAMESPACE': namespace,
              'REGISTER_NATIVES_IMPL': self.GetRegisterNativesImplString()
             }
    return template.substitute(values)

  def GetOpenNamespaceString(self):
    if self.namespace:
      all_namespaces = ['namespace %s {' % ns
                        for ns in self.namespace.split('::')]
      return '\n'.join(all_namespaces)
    return ''

  def GetCloseNamespaceString(self):
    if self.namespace:
      all_namespaces = ['}  // namespace %s' % ns
                        for ns in self.namespace.split('::')]
      all_namespaces.reverse()
      return '\n'.join(all_namespaces) + '\n'
    return ''

  def GetJNIFirstParam(self, native):
    ret = []
    if native.type == 'method':
      ret = ['jobject jcaller']
    elif native.type == 'function':
      if native.static:
        ret = ['jclass jcaller']
      else:
        ret = ['jobject jcaller']
    return ret

  def GetParamsInDeclaration(self, native):
    """Returns the params for the stub declaration.

    Args:
      native: the native dictionary describing the method.

    Returns:
      A string containing the params.
    """
    return ',\n    '.join(self.GetJNIFirstParam(native) +
                          [JavaDataTypeToC(param.datatype) + ' ' +
                           param.name
                           for param in native.params])

  def GetCalledByNativeParamsInDeclaration(self, called_by_native):
    return ',\n    '.join([
        JavaDataTypeToCForCalledByNativeParam(param.datatype) + ' ' +
        param.name
        for param in called_by_native.params])

  def GetStubName(self, native):
    """Return the name of the stub function for this native method.

    Args:
      native: the native dictionary describing the method.

    Returns:
      A string with the stub function name. For native exports mode this is the
      Java_* symbol name required by the JVM; otherwise it is just the name of
      the native method itself.
    """
    if self.options.native_exports:
      template = Template("Java_${JAVA_NAME}_native${NAME}")

      java_name = JniParams.RemapClassName(self.fully_qualified_class)
      java_name = java_name.replace('_', '_1').replace('/', '_')
      if native.java_class_name:
        java_name += '_00024' + native.java_class_name

      values = {'NAME': native.name,
                'JAVA_NAME': java_name}
      return template.substitute(values)
    else:
      return native.name

  def GetForwardDeclaration(self, native):
    template_str = """
static ${RETURN} ${NAME}(JNIEnv* env, ${PARAMS});
"""
    if self.options.native_exports:
      template_str += """
__attribute__((visibility("default")))
${RETURN} ${STUB_NAME}(JNIEnv* env, ${PARAMS}) {
  return ${NAME}(${PARAMS_IN_CALL});
}
"""
    template = Template(template_str)
    params_in_call = []
    if not self.options.pure_native_methods:
      params_in_call = ['env', 'jcaller']
    params_in_call = ', '.join(params_in_call + [p.name for p in native.params])

    values = {'RETURN': JavaDataTypeToC(native.return_type),
              'NAME': native.name,
              'PARAMS': self.GetParamsInDeclaration(native),
              'PARAMS_IN_CALL': params_in_call,
              'STUB_NAME': self.GetStubName(native)}
    return template.substitute(values)

  def GetNativeMethodStubString(self, native):
    """Returns stubs for native methods."""
    if self.options.native_exports:
      template_str = """\
__attribute__((visibility("default")))
${RETURN} ${STUB_NAME}(JNIEnv* env,
    ${PARAMS_IN_DECLARATION}) {"""
    else:
      template_str = """\
static ${RETURN} ${STUB_NAME}(JNIEnv* env, ${PARAMS_IN_DECLARATION}) {"""
    template_str += """
  ${P0_TYPE}* native = reinterpret_cast<${P0_TYPE}*>(${PARAM0_NAME});
  CHECK_NATIVE_PTR(env, jcaller, native, "${NAME}"${OPTIONAL_ERROR_RETURN});
  return native->${NAME}(${PARAMS_IN_CALL})${POST_CALL};
}
"""

    template = Template(template_str)
    params = []
    if not self.options.pure_native_methods:
      params = ['env', 'jcaller']
    params_in_call = ', '.join(params + [p.name for p in native.params[1:]])

    return_type = JavaDataTypeToC(native.return_type)
    optional_error_return = JavaReturnValueToC(native.return_type)
    if optional_error_return:
      optional_error_return = ', ' + optional_error_return
    post_call = ''
    if re.match(RE_SCOPED_JNI_RETURN_TYPES, return_type):
      post_call = '.Release()'

    values = {
        'RETURN': return_type,
        'OPTIONAL_ERROR_RETURN': optional_error_return,
        'NAME': native.name,
        'PARAMS_IN_DECLARATION': self.GetParamsInDeclaration(native),
        'PARAM0_NAME': native.params[0].name,
        'P0_TYPE': native.p0_type,
        'PARAMS_IN_CALL': params_in_call,
        'POST_CALL': post_call,
        'STUB_NAME': self.GetStubName(native),
    }
    return template.substitute(values)

  def GetArgument(self, param):
    return ('as_jint(' + param.name + ')'
            if param.datatype == 'int' else param.name)

  def GetArgumentsInCall(self, params):
    """Return a string of arguments to call from native into Java"""
    return [self.GetArgument(p) for p in params]

  def GetCalledByNativeValues(self, called_by_native):
    """Fills in necessary values for the CalledByNative methods."""
    java_class = called_by_native.java_class_name or self.class_name
    if called_by_native.static or called_by_native.is_constructor:
      first_param_in_declaration = ''
      first_param_in_call = ('%s_clazz(env)' % java_class)
    else:
      first_param_in_declaration = ', jobject obj'
      first_param_in_call = 'obj'
    params_in_declaration = self.GetCalledByNativeParamsInDeclaration(
        called_by_native)
    if params_in_declaration:
      params_in_declaration = ', ' + params_in_declaration
    params_in_call = ', '.join(self.GetArgumentsInCall(called_by_native.params))
    if params_in_call:
      params_in_call = ', ' + params_in_call
    pre_call = ''
    post_call = ''
    if called_by_native.static_cast:
      pre_call = 'static_cast<%s>(' % called_by_native.static_cast
      post_call = ')'
    check_exception = ''
    if not called_by_native.unchecked:
      check_exception = 'jni_generator::CheckException(env);'
    return_type = JavaDataTypeToC(called_by_native.return_type)
    optional_error_return = JavaReturnValueToC(called_by_native.return_type)
    if optional_error_return:
      optional_error_return = ', ' + optional_error_return
    return_declaration = ''
    return_clause = ''
    if return_type != 'void':
      pre_call = ' ' + pre_call
      return_declaration = return_type + ' ret ='
      if re.match(RE_SCOPED_JNI_RETURN_TYPES, return_type):
        return_type = 'base::android::ScopedJavaLocalRef<' + return_type + '>'
        return_clause = 'return ' + return_type + '(env, ret);'
      else:
        return_clause = 'return ret;'
    return {
        'JAVA_CLASS': java_class,
        'RETURN_TYPE': return_type,
        'OPTIONAL_ERROR_RETURN': optional_error_return,
        'RETURN_DECLARATION': return_declaration,
        'RETURN_CLAUSE': return_clause,
        'FIRST_PARAM_IN_DECLARATION': first_param_in_declaration,
        'PARAMS_IN_DECLARATION': params_in_declaration,
        'PRE_CALL': pre_call,
        'POST_CALL': post_call,
        'ENV_CALL': called_by_native.env_call,
        'FIRST_PARAM_IN_CALL': first_param_in_call,
        'PARAMS_IN_CALL': params_in_call,
        'METHOD_ID_VAR_NAME': called_by_native.method_id_var_name,
        'CHECK_EXCEPTION': check_exception,
        'GET_METHOD_ID_IMPL': self.GetMethodIDImpl(called_by_native)
    }

  def GetEagerCalledByNativeMethodStub(self, called_by_native):
    """Returns the implementation of the called by native method."""
    template = Template("""
static ${RETURN_TYPE} ${METHOD_ID_VAR_NAME}(\
JNIEnv* env${FIRST_PARAM_IN_DECLARATION}${PARAMS_IN_DECLARATION}) {
  ${RETURN_DECLARATION}${PRE_CALL}env->${ENV_CALL}(${FIRST_PARAM_IN_CALL},
      g_${JAVA_CLASS}_${METHOD_ID_VAR_NAME}${PARAMS_IN_CALL})${POST_CALL};
  ${RETURN_CLAUSE}
}""")
    values = self.GetCalledByNativeValues(called_by_native)
    return template.substitute(values)

  def GetLazyCalledByNativeMethodStub(self, called_by_native):
    """Returns a string."""
    function_signature_template = Template("""\
static ${RETURN_TYPE} Java_${JAVA_CLASS}_${METHOD_ID_VAR_NAME}(\
JNIEnv* env${FIRST_PARAM_IN_DECLARATION}${PARAMS_IN_DECLARATION})""")
    function_header_template = Template("""\
${FUNCTION_SIGNATURE} {""")
    function_header_with_unused_template = Template("""\
${FUNCTION_SIGNATURE} __attribute__ ((unused));
${FUNCTION_SIGNATURE} {""")
    template = Template("""
static base::subtle::AtomicWord g_${JAVA_CLASS}_${METHOD_ID_VAR_NAME} = 0;
${FUNCTION_HEADER}
  /* Must call RegisterNativesImpl()  */
  CHECK_CLAZZ(env, ${FIRST_PARAM_IN_CALL},
      ${JAVA_CLASS}_clazz(env)${OPTIONAL_ERROR_RETURN});
  jmethodID method_id =
    ${GET_METHOD_ID_IMPL}
  ${RETURN_DECLARATION}
     ${PRE_CALL}env->${ENV_CALL}(${FIRST_PARAM_IN_CALL},
          method_id${PARAMS_IN_CALL})${POST_CALL};
  ${CHECK_EXCEPTION}
  ${RETURN_CLAUSE}
}""")
    values = self.GetCalledByNativeValues(called_by_native)
    values['FUNCTION_SIGNATURE'] = (
        function_signature_template.substitute(values))
    if called_by_native.system_class:
      values['FUNCTION_HEADER'] = (
          function_header_with_unused_template.substitute(values))
    else:
      values['FUNCTION_HEADER'] = function_header_template.substitute(values)
    return template.substitute(values)

  def GetKMethodArrayEntry(self, native):
    template = Template('    { "native${NAME}", ${JNI_SIGNATURE}, ' +
                        'reinterpret_cast<void*>(${STUB_NAME}) },')
    values = {'NAME': native.name,
              'JNI_SIGNATURE': JniParams.Signature(native.params,
                                                   native.return_type,
                                                   True),
              'STUB_NAME': self.GetStubName(native)}
    return template.substitute(values)

  def GetUniqueClasses(self, origin):
    ret = {self.class_name: self.fully_qualified_class}
    for entry in origin:
      class_name = self.class_name
      jni_class_path = self.fully_qualified_class
      if entry.java_class_name:
        class_name = entry.java_class_name
        jni_class_path = self.fully_qualified_class + '$' + class_name
      ret[class_name] = jni_class_path
    return ret

  def GetClassPathDefinitions(self):
    """Returns the ClassPath constants."""
    ret = []
    template = Template("""\
const char k${JAVA_CLASS}ClassPath[] = "${JNI_CLASS_PATH}";""")
    native_classes = self.GetUniqueClasses(self.natives)
    called_by_native_classes = self.GetUniqueClasses(self.called_by_natives)
    if self.options.native_exports:
      all_classes = called_by_native_classes
    else:
      all_classes = native_classes
      all_classes.update(called_by_native_classes)

    for clazz in all_classes:
      values = {
          'JAVA_CLASS': clazz,
          'JNI_CLASS_PATH': JniParams.RemapClassName(all_classes[clazz]),
      }
      ret += [template.substitute(values)]
    ret += ''

    class_getter_methods = []
    if self.options.native_exports:
      template = Template("""\
// Leaking this jclass as we cannot use LazyInstance from some threads.
base::subtle::AtomicWord g_${JAVA_CLASS}_clazz __attribute__((unused)) = 0;
#define ${JAVA_CLASS}_clazz(env) \
base::android::LazyGetClass(env, k${JAVA_CLASS}ClassPath, \
&g_${JAVA_CLASS}_clazz)""")
    else:
      template = Template("""\
// Leaking this jclass as we cannot use LazyInstance from some threads.
jclass g_${JAVA_CLASS}_clazz = NULL;
#define ${JAVA_CLASS}_clazz(env) g_${JAVA_CLASS}_clazz""")

    for clazz in called_by_native_classes:
      values = {
          'JAVA_CLASS': clazz,
      }
      ret += [template.substitute(values)]

    return '\n'.join(ret)

  def GetFindClasses(self):
    """Returns the imlementation of FindClass for all known classes."""
    if self.init_native:
      if self.options.native_exports:
        template = Template("""\
  base::subtle::Release_Store(&g_${JAVA_CLASS}_clazz,
      static_cast<base::subtle::AtomicWord>(env->NewWeakGlobalRef(clazz));""")
      else:
        template = Template("""\
  g_${JAVA_CLASS}_clazz = static_cast<jclass>(env->NewWeakGlobalRef(clazz));""")
    else:
      if self.options.native_exports:
        return '\n'
      template = Template("""\
  g_${JAVA_CLASS}_clazz = reinterpret_cast<jclass>(env->NewGlobalRef(
      base::android::GetClass(env, k${JAVA_CLASS}ClassPath).obj()));""")
    ret = []
    for clazz in self.GetUniqueClasses(self.called_by_natives):
      values = {'JAVA_CLASS': clazz}
      ret += [template.substitute(values)]
    return '\n'.join(ret)

  def GetMethodIDImpl(self, called_by_native):
    """Returns the implementation of GetMethodID."""
    if self.options.eager_called_by_natives:
      template = Template("""\
env->Get${STATIC_METHOD_PART}MethodID(
      ${JAVA_CLASS}_clazz(env),
      "${JNI_NAME}", ${JNI_SIGNATURE});""")
    else:
      template = Template("""\
  base::android::MethodID::LazyGet<
      base::android::MethodID::TYPE_${STATIC}>(
      env, ${JAVA_CLASS}_clazz(env),
      "${JNI_NAME}",
      ${JNI_SIGNATURE},
      &g_${JAVA_CLASS}_${METHOD_ID_VAR_NAME});
""")
    jni_name = called_by_native.name
    jni_return_type = called_by_native.return_type
    if called_by_native.is_constructor:
      jni_name = '<init>'
      jni_return_type = 'void'
    if called_by_native.signature:
      signature = called_by_native.signature
    else:
      signature = JniParams.Signature(called_by_native.params,
                                      jni_return_type,
                                      True)
    values = {
        'JAVA_CLASS': called_by_native.java_class_name or self.class_name,
        'JNI_NAME': jni_name,
        'METHOD_ID_VAR_NAME': called_by_native.method_id_var_name,
        'STATIC': 'STATIC' if called_by_native.static else 'INSTANCE',
        'STATIC_METHOD_PART': 'Static' if called_by_native.static else '',
        'JNI_SIGNATURE': signature,
    }
    return template.substitute(values)


def WrapOutput(output):
  ret = []
  for line in output.splitlines():
    # Do not wrap lines under 80 characters or preprocessor directives.
    if len(line) < 80 or line.lstrip()[:1] == '#':
      stripped = line.rstrip()
      if len(ret) == 0 or len(ret[-1]) or len(stripped):
        ret.append(stripped)
    else:
      first_line_indent = ' ' * (len(line) - len(line.lstrip()))
      subsequent_indent =  first_line_indent + ' ' * 4
      if line.startswith('//'):
        subsequent_indent = '//' + subsequent_indent
      wrapper = textwrap.TextWrapper(width=80,
                                     subsequent_indent=subsequent_indent,
                                     break_long_words=False)
      ret += [wrapped.rstrip() for wrapped in wrapper.wrap(line)]
  ret += ['']
  return '\n'.join(ret)


def ExtractJarInputFile(jar_file, input_file, out_dir):
  """Extracts input file from jar and returns the filename.

  The input file is extracted to the same directory that the generated jni
  headers will be placed in.  This is passed as an argument to script.

  Args:
    jar_file: the jar file containing the input files to extract.
    input_files: the list of files to extract from the jar file.
    out_dir: the name of the directories to extract to.

  Returns:
    the name of extracted input file.
  """
  jar_file = zipfile.ZipFile(jar_file)

  out_dir = os.path.join(out_dir, os.path.dirname(input_file))
  try:
    os.makedirs(out_dir)
  except OSError as e:
    if e.errno != errno.EEXIST:
      raise
  extracted_file_name = os.path.join(out_dir, os.path.basename(input_file))
  with open(extracted_file_name, 'w') as outfile:
    outfile.write(jar_file.read(input_file))

  return extracted_file_name


def GenerateJNIHeader(input_file, output_file, options):
  try:
    if os.path.splitext(input_file)[1] == '.class':
      jni_from_javap = JNIFromJavaP.CreateFromClass(input_file, options)
      content = jni_from_javap.GetContent()
    else:
      jni_from_java_source = JNIFromJavaSource.CreateFromFile(
          input_file, options)
      content = jni_from_java_source.GetContent()
  except ParseError, e:
    print e
    sys.exit(1)
  if output_file:
    if not os.path.exists(os.path.dirname(os.path.abspath(output_file))):
      os.makedirs(os.path.dirname(os.path.abspath(output_file)))
    if options.optimize_generation and os.path.exists(output_file):
      with file(output_file, 'r') as f:
        existing_content = f.read()
        if existing_content == content:
          return
    with file(output_file, 'w') as f:
      f.write(content)
  else:
    print content


def GetScriptName():
  script_components = os.path.abspath(sys.argv[0]).split(os.path.sep)
  base_index = 0
  for idx, value in enumerate(script_components):
    if value == 'base' or value == 'third_party':
      base_index = idx
      break
  return os.sep.join(script_components[base_index:])


def main(argv):
  usage = """usage: %prog [OPTIONS]
This script will parse the given java source code extracting the native
declarations and print the header file to stdout (or a file).
See SampleForTests.java for more details.
  """
  option_parser = optparse.OptionParser(usage=usage)
  build_utils.AddDepfileOption(option_parser)

  option_parser.add_option('-j', '--jar_file', dest='jar_file',
                           help='Extract the list of input files from'
                           ' a specified jar file.'
                           ' Uses javap to extract the methods from a'
                           ' pre-compiled class. --input should point'
                           ' to pre-compiled Java .class files.')
  option_parser.add_option('-n', dest='namespace',
                           help='Uses as a namespace in the generated header '
                           'instead of the javap class name, or when there is '
                           'no JNINamespace annotation in the java source.')
  option_parser.add_option('--input_file',
                           help='Single input file name. The output file name '
                           'will be derived from it. Must be used with '
                           '--output_dir.')
  option_parser.add_option('--output_dir',
                           help='The output directory. Must be used with '
                           '--input')
  option_parser.add_option('--optimize_generation', type="int",
                           default=0, help='Whether we should optimize JNI '
                           'generation by not regenerating files if they have '
                           'not changed.')
  option_parser.add_option('--jarjar',
                           help='Path to optional jarjar rules file.')
  option_parser.add_option('--script_name', default=GetScriptName(),
                           help='The name of this script in the generated '
                           'header.')
  option_parser.add_option('--includes',
                           help='The comma-separated list of header files to '
                           'include in the generated header.')
  option_parser.add_option('--pure_native_methods',
                           action='store_true', dest='pure_native_methods',
                           help='When true, the native methods will be called '
                           'without any JNI-specific arguments.')
  option_parser.add_option('--ptr_type', default='int',
                           type='choice', choices=['int', 'long'],
                           help='The type used to represent native pointers in '
                           'Java code. For 32-bit, use int; '
                           'for 64-bit, use long.')
  option_parser.add_option('--jni_init_native_name', default='',
                           help='The name of the JNI registration method that '
                           'is used to initialize all native methods. If a '
                           'method with this name is not present in the Java '
                           'source file, setting this option is a no-op. When '
                           'a method with this name is found however, the '
                           'naming convention Java_<packageName>_<className> '
                           'will limit the initialization to only the '
                           'top-level class.')
  option_parser.add_option('--eager_called_by_natives',
                           action='store_true', dest='eager_called_by_natives',
                           help='When true, the called-by-native methods will '
                           'be initialized in a non-atomic way.')
  option_parser.add_option('--cpp', default='cpp',
                           help='The path to cpp command.')
  option_parser.add_option('--javap', default='javap',
                           help='The path to javap command.')
  option_parser.add_option('--native_exports', action='store_true',
                           help='Native method registration through .so '
                           'exports.')
  option_parser.add_option('--native_exports_optional', action='store_true',
                           help='Support both explicit and native method'
                           'registration.')
  options, args = option_parser.parse_args(argv)
  if options.native_exports_optional:
    options.native_exports = True
  if options.jar_file:
    input_file = ExtractJarInputFile(options.jar_file, options.input_file,
                                     options.output_dir)
  elif options.input_file:
    input_file = options.input_file
  else:
    option_parser.print_help()
    print '\nError: Must specify --jar_file or --input_file.'
    return 1
  output_file = None
  if options.output_dir:
    root_name = os.path.splitext(os.path.basename(input_file))[0]
    output_file = os.path.join(options.output_dir, root_name) + '_jni.h'
  if options.jarjar:
    with open(options.jarjar) as f:
      JniParams.SetJarJarMappings(f.read())
  GenerateJNIHeader(input_file, output_file, options)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        build_utils.GetPythonDependencies())


if __name__ == '__main__':
  sys.exit(main(sys.argv))
