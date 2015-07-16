#! /usr/bin/python
#
# See README for usage instructions.
import sys
import os
import subprocess

# We must use setuptools, not distutils, because we need to use the
# namespace_packages option for the "google" package.
try:
  from setuptools import setup, Extension
except ImportError:
  try:
    from ez_setup import use_setuptools
    use_setuptools()
    from setuptools import setup, Extension
  except ImportError:
    sys.stderr.write(
        "Could not import setuptools; make sure you have setuptools or "
        "ez_setup installed.\n")
    raise
from distutils.command.clean import clean as _clean
from distutils.command.build_py import build_py as _build_py
from distutils.spawn import find_executable

maintainer_email = "protobuf@googlegroups.com"

# Find the Protocol Compiler.
if 'PROTOC' in os.environ and os.path.exists(os.environ['PROTOC']):
  protoc = os.environ['PROTOC']
elif os.path.exists("../src/protoc"):
  protoc = "../src/protoc"
elif os.path.exists("../src/protoc.exe"):
  protoc = "../src/protoc.exe"
elif os.path.exists("../vsprojects/Debug/protoc.exe"):
  protoc = "../vsprojects/Debug/protoc.exe"
elif os.path.exists("../vsprojects/Release/protoc.exe"):
  protoc = "../vsprojects/Release/protoc.exe"
else:
  protoc = find_executable("protoc")

def generate_proto(source):
  """Invokes the Protocol Compiler to generate a _pb2.py from the given
  .proto file.  Does nothing if the output already exists and is newer than
  the input."""

  output = source.replace(".proto", "_pb2.py").replace("../src/", "")

  if (not os.path.exists(output) or
      (os.path.exists(source) and
       os.path.getmtime(source) > os.path.getmtime(output))):
    print "Generating %s..." % output

    if not os.path.exists(source):
      sys.stderr.write("Can't find required file: %s\n" % source)
      sys.exit(-1)

    if protoc == None:
      sys.stderr.write(
          "protoc is not installed nor found in ../src.  Please compile it "
          "or install the binary package.\n")
      sys.exit(-1)

    protoc_command = [ protoc, "-I../src", "-I.", "--python_out=.", source ]
    if subprocess.call(protoc_command) != 0:
      sys.exit(-1)

def GenerateUnittestProtos():
  generate_proto("../src/google/protobuf/unittest.proto")
  generate_proto("../src/google/protobuf/unittest_custom_options.proto")
  generate_proto("../src/google/protobuf/unittest_import.proto")
  generate_proto("../src/google/protobuf/unittest_import_public.proto")
  generate_proto("../src/google/protobuf/unittest_mset.proto")
  generate_proto("../src/google/protobuf/unittest_no_generic_services.proto")
  generate_proto("google/protobuf/internal/test_bad_identifiers.proto")
  generate_proto("google/protobuf/internal/more_extensions.proto")
  generate_proto("google/protobuf/internal/more_extensions_dynamic.proto")
  generate_proto("google/protobuf/internal/more_messages.proto")
  generate_proto("google/protobuf/internal/factory_test1.proto")
  generate_proto("google/protobuf/internal/factory_test2.proto")

def MakeTestSuite():
  # This is apparently needed on some systems to make sure that the tests
  # work even if a previous version is already installed.
  if 'google' in sys.modules:
    del sys.modules['google']
  GenerateUnittestProtos()

  import unittest
  import google.protobuf.internal.generator_test     as generator_test
  import google.protobuf.internal.descriptor_test    as descriptor_test
  import google.protobuf.internal.reflection_test    as reflection_test
  import google.protobuf.internal.service_reflection_test \
    as service_reflection_test
  import google.protobuf.internal.text_format_test   as text_format_test
  import google.protobuf.internal.wire_format_test   as wire_format_test
  import google.protobuf.internal.unknown_fields_test as unknown_fields_test
  import google.protobuf.internal.descriptor_database_test \
      as descriptor_database_test
  import google.protobuf.internal.descriptor_pool_test as descriptor_pool_test
  import google.protobuf.internal.message_factory_test as message_factory_test
  import google.protobuf.internal.message_cpp_test as message_cpp_test
  import google.protobuf.internal.reflection_cpp_generated_test \
      as reflection_cpp_generated_test

  loader = unittest.defaultTestLoader
  suite = unittest.TestSuite()
  for test in [ generator_test,
                descriptor_test,
                reflection_test,
                service_reflection_test,
                text_format_test,
                wire_format_test ]:
    suite.addTest(loader.loadTestsFromModule(test))

  return suite


class clean(_clean):
  def run(self):
    # Delete generated files in the code tree.
    for (dirpath, dirnames, filenames) in os.walk("."):
      for filename in filenames:
        filepath = os.path.join(dirpath, filename)
        if filepath.endswith("_pb2.py") or filepath.endswith(".pyc") or \
          filepath.endswith(".so") or filepath.endswith(".o") or \
          filepath.endswith('google/protobuf/compiler/__init__.py'):
          os.remove(filepath)
    # _clean is an old-style class, so super() doesn't work.
    _clean.run(self)

class build_py(_build_py):
  def run(self):
    # Generate necessary .proto file if it doesn't exist.
    generate_proto("../src/google/protobuf/descriptor.proto")
    generate_proto("../src/google/protobuf/compiler/plugin.proto")

    GenerateUnittestProtos()
    # Make sure google.protobuf.compiler is a valid package.
    open('google/protobuf/compiler/__init__.py', 'a').close()
    # _build_py is an old-style class, so super() doesn't work.
    _build_py.run(self)

if __name__ == '__main__':
  ext_module_list = []

  # C++ implementation extension
  if os.getenv("PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION", "python") == "cpp":
    print "Using EXPERIMENTAL C++ Implmenetation."
    ext_module_list.append(Extension(
        "google.protobuf.internal._net_proto2___python",
        [ "google/protobuf/pyext/python_descriptor.cc",
          "google/protobuf/pyext/python_protobuf.cc",
          "google/protobuf/pyext/python-proto2.cc" ],
        include_dirs = [ "." ],
        libraries = [ "protobuf" ]))

  setup(name = 'protobuf',
        version = '2.5.0-pre',
        packages = [ 'google' ],
        namespace_packages = [ 'google' ],
        test_suite = 'setup.MakeTestSuite',
        # Must list modules explicitly so that we don't install tests.
        py_modules = [
          'google.protobuf.internal.api_implementation',
          'google.protobuf.internal.containers',
          'google.protobuf.internal.cpp_message',
          'google.protobuf.internal.decoder',
          'google.protobuf.internal.encoder',
          'google.protobuf.internal.enum_type_wrapper',
          'google.protobuf.internal.message_listener',
          'google.protobuf.internal.python_message',
          'google.protobuf.internal.type_checkers',
          'google.protobuf.internal.wire_format',
          'google.protobuf.descriptor',
          'google.protobuf.descriptor_pb2',
          'google.protobuf.compiler.plugin_pb2',
          'google.protobuf.message',
          'google.protobuf.descriptor_database',
          'google.protobuf.descriptor_pool',
          'google.protobuf.message_factory',
          'google.protobuf.reflection',
          'google.protobuf.service',
          'google.protobuf.service_reflection',
          'google.protobuf.text_format' ],
        cmdclass = { 'clean': clean, 'build_py': build_py },
        install_requires = ['setuptools'],
        ext_modules = ext_module_list,
        url = 'http://code.google.com/p/protobuf/',
        maintainer = maintainer_email,
        maintainer_email = 'protobuf@googlegroups.com',
        license = 'New BSD License',
        description = 'Protocol Buffers',
        long_description =
          "Protocol Buffers are Google's data interchange format.",
        )
