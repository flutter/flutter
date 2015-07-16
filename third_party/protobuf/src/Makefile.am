## Process this file with automake to produce Makefile.in

if HAVE_ZLIB
GZCHECKPROGRAMS = zcgzip zcgunzip
GZHEADERS = google/protobuf/io/gzip_stream.h
GZTESTS = google/protobuf/io/gzip_stream_unittest.sh
else
GZCHECKPROGRAMS =
GZHEADERS =
GZTESTS =
endif

if GCC
# These are good warnings to turn on by default
NO_OPT_CXXFLAGS = $(PTHREAD_CFLAGS) -Wall -Wwrite-strings -Woverloaded-virtual -Wno-sign-compare
else
NO_OPT_CXXFLAGS = $(PTHREAD_CFLAGS)
endif

AM_CXXFLAGS = $(NO_OPT_CXXFLAGS) $(PROTOBUF_OPT_FLAG)

AM_LDFLAGS = $(PTHREAD_CFLAGS)

# If I say "dist_include_DATA", automake complains that $(includedir) is not
# a "legitimate" directory for DATA.  Screw you, automake.
protodir = $(includedir)
nobase_dist_proto_DATA = google/protobuf/descriptor.proto \
                         google/protobuf/compiler/plugin.proto

# Not sure why these don't get cleaned automatically.
clean-local:
	rm -f *.loT

CLEANFILES = $(protoc_outputs) unittest_proto_middleman \
             testzip.jar testzip.list testzip.proto testzip.zip

MAINTAINERCLEANFILES =   \
  Makefile.in

nobase_include_HEADERS =                                        \
  google/protobuf/stubs/atomicops.h                             \
  google/protobuf/stubs/atomicops_internals_arm_gcc.h           \
  google/protobuf/stubs/atomicops_internals_arm_qnx.h           \
  google/protobuf/stubs/atomicops_internals_atomicword_compat.h \
  google/protobuf/stubs/atomicops_internals_macosx.h            \
  google/protobuf/stubs/atomicops_internals_mips_gcc.h          \
  google/protobuf/stubs/atomicops_internals_pnacl.h             \
  google/protobuf/stubs/atomicops_internals_x86_gcc.h           \
  google/protobuf/stubs/atomicops_internals_x86_msvc.h          \
  google/protobuf/stubs/common.h                                \
  google/protobuf/stubs/platform_macros.h                       \
  google/protobuf/stubs/once.h                                  \
  google/protobuf/stubs/template_util.h                         \
  google/protobuf/stubs/type_traits.h                           \
  google/protobuf/descriptor.h                                  \
  google/protobuf/descriptor.pb.h                               \
  google/protobuf/descriptor_database.h                         \
  google/protobuf/dynamic_message.h                             \
  google/protobuf/extension_set.h                               \
  google/protobuf/generated_enum_reflection.h                   \
  google/protobuf/generated_message_util.h                      \
  google/protobuf/generated_message_reflection.h                \
  google/protobuf/message.h                                     \
  google/protobuf/message_lite.h                                \
  google/protobuf/reflection_ops.h                              \
  google/protobuf/repeated_field.h                              \
  google/protobuf/service.h                                     \
  google/protobuf/text_format.h                                 \
  google/protobuf/unknown_field_set.h                           \
  google/protobuf/wire_format.h                                 \
  google/protobuf/wire_format_lite.h                            \
  google/protobuf/wire_format_lite_inl.h                        \
  google/protobuf/io/coded_stream.h                             \
  $(GZHEADERS)                                                  \
  google/protobuf/io/printer.h                                  \
  google/protobuf/io/tokenizer.h                                \
  google/protobuf/io/zero_copy_stream.h                         \
  google/protobuf/io/zero_copy_stream_impl.h                    \
  google/protobuf/io/zero_copy_stream_impl_lite.h               \
  google/protobuf/compiler/code_generator.h                     \
  google/protobuf/compiler/command_line_interface.h             \
  google/protobuf/compiler/importer.h                           \
  google/protobuf/compiler/parser.h                             \
  google/protobuf/compiler/plugin.h                             \
  google/protobuf/compiler/plugin.pb.h                          \
  google/protobuf/compiler/cpp/cpp_generator.h                  \
  google/protobuf/compiler/java/java_generator.h                \
  google/protobuf/compiler/python/python_generator.h

lib_LTLIBRARIES = libprotobuf-lite.la libprotobuf.la libprotoc.la

libprotobuf_lite_la_LIBADD = $(PTHREAD_LIBS)
libprotobuf_lite_la_LDFLAGS = -version-info 8:0:0 -export-dynamic -no-undefined
libprotobuf_lite_la_SOURCES =                                  \
  google/protobuf/stubs/atomicops_internals_x86_gcc.cc         \
  google/protobuf/stubs/atomicops_internals_x86_msvc.cc        \
  google/protobuf/stubs/common.cc                              \
  google/protobuf/stubs/once.cc                                \
  google/protobuf/stubs/hash.h                                 \
  google/protobuf/stubs/map-util.h                             \
  google/protobuf/stubs/stl_util.h                             \
  google/protobuf/stubs/stringprintf.cc                        \
  google/protobuf/stubs/stringprintf.h                         \
  google/protobuf/extension_set.cc                             \
  google/protobuf/generated_message_util.cc                    \
  google/protobuf/message_lite.cc                              \
  google/protobuf/repeated_field.cc                            \
  google/protobuf/wire_format_lite.cc                          \
  google/protobuf/io/coded_stream.cc                           \
  google/protobuf/io/coded_stream_inl.h                        \
  google/protobuf/io/zero_copy_stream.cc                       \
  google/protobuf/io/zero_copy_stream_impl_lite.cc

libprotobuf_la_LIBADD = $(PTHREAD_LIBS)
libprotobuf_la_LDFLAGS = -version-info 8:0:0 -export-dynamic -no-undefined
libprotobuf_la_SOURCES =                                       \
  $(libprotobuf_lite_la_SOURCES)                               \
  google/protobuf/stubs/strutil.cc                             \
  google/protobuf/stubs/strutil.h                              \
  google/protobuf/stubs/substitute.cc                          \
  google/protobuf/stubs/substitute.h                           \
  google/protobuf/stubs/structurally_valid.cc                  \
  google/protobuf/descriptor.cc                                \
  google/protobuf/descriptor.pb.cc                             \
  google/protobuf/descriptor_database.cc                       \
  google/protobuf/dynamic_message.cc                           \
  google/protobuf/extension_set_heavy.cc                       \
  google/protobuf/generated_message_reflection.cc              \
  google/protobuf/message.cc                                   \
  google/protobuf/reflection_ops.cc                            \
  google/protobuf/service.cc                                   \
  google/protobuf/text_format.cc                               \
  google/protobuf/unknown_field_set.cc                         \
  google/protobuf/wire_format.cc                               \
  google/protobuf/io/gzip_stream.cc                            \
  google/protobuf/io/printer.cc                                \
  google/protobuf/io/tokenizer.cc                              \
  google/protobuf/io/zero_copy_stream_impl.cc                  \
  google/protobuf/compiler/importer.cc                         \
  google/protobuf/compiler/parser.cc

libprotoc_la_LIBADD = $(PTHREAD_LIBS) libprotobuf.la
libprotoc_la_LDFLAGS = -version-info 8:0:0 -export-dynamic -no-undefined
libprotoc_la_SOURCES =                                         \
  google/protobuf/compiler/code_generator.cc                   \
  google/protobuf/compiler/command_line_interface.cc           \
  google/protobuf/compiler/plugin.cc                           \
  google/protobuf/compiler/plugin.pb.cc                        \
  google/protobuf/compiler/subprocess.cc                       \
  google/protobuf/compiler/subprocess.h                        \
  google/protobuf/compiler/zip_writer.cc                       \
  google/protobuf/compiler/zip_writer.h                        \
  google/protobuf/compiler/cpp/cpp_enum.cc                     \
  google/protobuf/compiler/cpp/cpp_enum.h                      \
  google/protobuf/compiler/cpp/cpp_enum_field.cc               \
  google/protobuf/compiler/cpp/cpp_enum_field.h                \
  google/protobuf/compiler/cpp/cpp_extension.cc                \
  google/protobuf/compiler/cpp/cpp_extension.h                 \
  google/protobuf/compiler/cpp/cpp_field.cc                    \
  google/protobuf/compiler/cpp/cpp_field.h                     \
  google/protobuf/compiler/cpp/cpp_file.cc                     \
  google/protobuf/compiler/cpp/cpp_file.h                      \
  google/protobuf/compiler/cpp/cpp_generator.cc                \
  google/protobuf/compiler/cpp/cpp_helpers.cc                  \
  google/protobuf/compiler/cpp/cpp_helpers.h                   \
  google/protobuf/compiler/cpp/cpp_message.cc                  \
  google/protobuf/compiler/cpp/cpp_message.h                   \
  google/protobuf/compiler/cpp/cpp_message_field.cc            \
  google/protobuf/compiler/cpp/cpp_message_field.h             \
  google/protobuf/compiler/cpp/cpp_options.h                   \
  google/protobuf/compiler/cpp/cpp_primitive_field.cc          \
  google/protobuf/compiler/cpp/cpp_primitive_field.h           \
  google/protobuf/compiler/cpp/cpp_service.cc                  \
  google/protobuf/compiler/cpp/cpp_service.h                   \
  google/protobuf/compiler/cpp/cpp_string_field.cc             \
  google/protobuf/compiler/cpp/cpp_string_field.h              \
  google/protobuf/compiler/java/java_enum.cc                   \
  google/protobuf/compiler/java/java_enum.h                    \
  google/protobuf/compiler/java/java_enum_field.cc             \
  google/protobuf/compiler/java/java_enum_field.h              \
  google/protobuf/compiler/java/java_extension.cc              \
  google/protobuf/compiler/java/java_extension.h               \
  google/protobuf/compiler/java/java_field.cc                  \
  google/protobuf/compiler/java/java_field.h                   \
  google/protobuf/compiler/java/java_file.cc                   \
  google/protobuf/compiler/java/java_file.h                    \
  google/protobuf/compiler/java/java_generator.cc              \
  google/protobuf/compiler/java/java_helpers.cc                \
  google/protobuf/compiler/java/java_helpers.h                 \
  google/protobuf/compiler/java/java_message.cc                \
  google/protobuf/compiler/java/java_message.h                 \
  google/protobuf/compiler/java/java_message_field.cc          \
  google/protobuf/compiler/java/java_message_field.h           \
  google/protobuf/compiler/java/java_primitive_field.cc        \
  google/protobuf/compiler/java/java_primitive_field.h         \
  google/protobuf/compiler/java/java_service.cc                \
  google/protobuf/compiler/java/java_service.h                 \
  google/protobuf/compiler/java/java_string_field.cc           \
  google/protobuf/compiler/java/java_string_field.h            \
  google/protobuf/compiler/java/java_doc_comment.cc            \
  google/protobuf/compiler/java/java_doc_comment.h             \
  google/protobuf/compiler/python/python_generator.cc

bin_PROGRAMS = protoc
protoc_LDADD = $(PTHREAD_LIBS) libprotobuf.la libprotoc.la
protoc_SOURCES = google/protobuf/compiler/main.cc

# Tests ==============================================================

protoc_inputs =                                                \
  google/protobuf/unittest.proto                               \
  google/protobuf/unittest_empty.proto                         \
  google/protobuf/unittest_import.proto                        \
  google/protobuf/unittest_import_public.proto                 \
  google/protobuf/unittest_mset.proto                          \
  google/protobuf/unittest_optimize_for.proto                  \
  google/protobuf/unittest_embed_optimize_for.proto            \
  google/protobuf/unittest_custom_options.proto                \
  google/protobuf/unittest_lite.proto                          \
  google/protobuf/unittest_import_lite.proto                   \
  google/protobuf/unittest_import_public_lite.proto            \
  google/protobuf/unittest_lite_imports_nonlite.proto          \
  google/protobuf/unittest_no_generic_services.proto           \
  google/protobuf/compiler/cpp/cpp_test_bad_identifiers.proto

EXTRA_DIST =                                                   \
  $(protoc_inputs)                                             \
  solaris/libstdc++.la                                         \
  google/protobuf/io/gzip_stream.h                             \
  google/protobuf/io/gzip_stream_unittest.sh                   \
  google/protobuf/testdata/golden_message                      \
  google/protobuf/testdata/golden_packed_fields_message        \
  google/protobuf/testdata/text_format_unittest_data.txt       \
  google/protobuf/testdata/text_format_unittest_extensions_data.txt  \
  google/protobuf/package_info.h                               \
  google/protobuf/io/package_info.h                            \
  google/protobuf/compiler/package_info.h                      \
  google/protobuf/compiler/zip_output_unittest.sh              \
  google/protobuf/unittest_enormous_descriptor.proto

protoc_lite_outputs =                                          \
  google/protobuf/unittest_lite.pb.cc                          \
  google/protobuf/unittest_lite.pb.h                           \
  google/protobuf/unittest_import_lite.pb.cc                   \
  google/protobuf/unittest_import_lite.pb.h                    \
  google/protobuf/unittest_import_public_lite.pb.cc            \
  google/protobuf/unittest_import_public_lite.pb.h

protoc_outputs =                                               \
  $(protoc_lite_outputs)                                       \
  google/protobuf/unittest.pb.cc                               \
  google/protobuf/unittest.pb.h                                \
  google/protobuf/unittest_empty.pb.cc                         \
  google/protobuf/unittest_empty.pb.h                          \
  google/protobuf/unittest_import.pb.cc                        \
  google/protobuf/unittest_import.pb.h                         \
  google/protobuf/unittest_import_public.pb.cc                 \
  google/protobuf/unittest_import_public.pb.h                  \
  google/protobuf/unittest_mset.pb.cc                          \
  google/protobuf/unittest_mset.pb.h                           \
  google/protobuf/unittest_optimize_for.pb.cc                  \
  google/protobuf/unittest_optimize_for.pb.h                   \
  google/protobuf/unittest_embed_optimize_for.pb.cc            \
  google/protobuf/unittest_embed_optimize_for.pb.h             \
  google/protobuf/unittest_custom_options.pb.cc                \
  google/protobuf/unittest_custom_options.pb.h                 \
  google/protobuf/unittest_lite_imports_nonlite.pb.cc          \
  google/protobuf/unittest_lite_imports_nonlite.pb.h           \
  google/protobuf/unittest_no_generic_services.pb.cc           \
  google/protobuf/unittest_no_generic_services.pb.h            \
  google/protobuf/compiler/cpp/cpp_test_bad_identifiers.pb.cc  \
  google/protobuf/compiler/cpp/cpp_test_bad_identifiers.pb.h

BUILT_SOURCES = $(protoc_outputs)

if USE_EXTERNAL_PROTOC

unittest_proto_middleman: $(protoc_inputs)
	$(PROTOC) -I$(srcdir) --cpp_out=. $^
	touch unittest_proto_middleman

else

# We have to cd to $(srcdir) before executing protoc because $(protoc_inputs) is
# relative to srcdir, which may not be the same as the current directory when
# building out-of-tree.
unittest_proto_middleman: protoc$(EXEEXT) $(protoc_inputs)
	oldpwd=`pwd` && ( cd $(srcdir) && $$oldpwd/protoc$(EXEEXT) -I. --cpp_out=$$oldpwd $(protoc_inputs) )
	touch unittest_proto_middleman

endif

$(protoc_outputs): unittest_proto_middleman

COMMON_TEST_SOURCES =                                          \
  google/protobuf/test_util.cc                                 \
  google/protobuf/test_util.h                                  \
  google/protobuf/testing/googletest.cc                        \
  google/protobuf/testing/googletest.h                         \
  google/protobuf/testing/file.cc                              \
  google/protobuf/testing/file.h

check_PROGRAMS = protoc protobuf-test protobuf-lazy-descriptor-test \
                 protobuf-lite-test test_plugin $(GZCHECKPROGRAMS)
protobuf_test_LDADD = $(PTHREAD_LIBS) libprotobuf.la libprotoc.la \
                      $(top_builddir)/gtest/lib/libgtest.la       \
                      $(top_builddir)/gtest/lib/libgtest_main.la
protobuf_test_CPPFLAGS = -I$(top_srcdir)/gtest/include         \
                         -I$(top_builddir)/gtest/include
# Disable optimization for tests unless the user explicitly asked for it,
# since test_util.cc takes forever to compile with optimization (with GCC).
# See configure.ac for more info.
protobuf_test_CXXFLAGS = $(NO_OPT_CXXFLAGS)
protobuf_test_SOURCES =                                        \
  google/protobuf/stubs/common_unittest.cc                     \
  google/protobuf/stubs/once_unittest.cc                       \
  google/protobuf/stubs/strutil_unittest.cc                    \
  google/protobuf/stubs/structurally_valid_unittest.cc         \
  google/protobuf/stubs/stringprintf_unittest.cc               \
  google/protobuf/stubs/template_util_unittest.cc              \
  google/protobuf/stubs/type_traits_unittest.cc                \
  google/protobuf/descriptor_database_unittest.cc              \
  google/protobuf/descriptor_unittest.cc                       \
  google/protobuf/dynamic_message_unittest.cc                  \
  google/protobuf/extension_set_unittest.cc                    \
  google/protobuf/generated_message_reflection_unittest.cc     \
  google/protobuf/message_unittest.cc                          \
  google/protobuf/reflection_ops_unittest.cc                   \
  google/protobuf/repeated_field_unittest.cc                   \
  google/protobuf/repeated_field_reflection_unittest.cc        \
  google/protobuf/text_format_unittest.cc                      \
  google/protobuf/unknown_field_set_unittest.cc                \
  google/protobuf/wire_format_unittest.cc                      \
  google/protobuf/io/coded_stream_unittest.cc                  \
  google/protobuf/io/printer_unittest.cc                       \
  google/protobuf/io/tokenizer_unittest.cc                     \
  google/protobuf/io/zero_copy_stream_unittest.cc              \
  google/protobuf/compiler/command_line_interface_unittest.cc  \
  google/protobuf/compiler/importer_unittest.cc                \
  google/protobuf/compiler/mock_code_generator.cc              \
  google/protobuf/compiler/mock_code_generator.h               \
  google/protobuf/compiler/parser_unittest.cc                  \
  google/protobuf/compiler/cpp/cpp_bootstrap_unittest.cc       \
  google/protobuf/compiler/cpp/cpp_unittest.h                  \
  google/protobuf/compiler/cpp/cpp_unittest.cc                 \
  google/protobuf/compiler/cpp/cpp_plugin_unittest.cc          \
  google/protobuf/compiler/java/java_plugin_unittest.cc        \
  google/protobuf/compiler/java/java_doc_comment_unittest.cc   \
  google/protobuf/compiler/python/python_plugin_unittest.cc    \
  $(COMMON_TEST_SOURCES)
nodist_protobuf_test_SOURCES = $(protoc_outputs)

# Run cpp_unittest again with PROTOBUF_TEST_NO_DESCRIPTORS defined.
protobuf_lazy_descriptor_test_LDADD = $(PTHREAD_LIBS) libprotobuf.la \
                      $(top_builddir)/gtest/lib/libgtest.la       \
                      $(top_builddir)/gtest/lib/libgtest_main.la
protobuf_lazy_descriptor_test_CPPFLAGS = -I$(top_srcdir)/gtest/include    \
                                         -I$(top_builddir)/gtest/include  \
                                         -DPROTOBUF_TEST_NO_DESCRIPTORS
protobuf_lazy_descriptor_test_CXXFLAGS = $(NO_OPT_CXXFLAGS)
protobuf_lazy_descriptor_test_SOURCES =                        \
  google/protobuf/compiler/cpp/cpp_unittest.cc                 \
  $(COMMON_TEST_SOURCES)
nodist_protobuf_lazy_descriptor_test_SOURCES = $(protoc_outputs)

# Build lite_unittest separately, since it doesn't use gtest.
protobuf_lite_test_LDADD = $(PTHREAD_LIBS) libprotobuf-lite.la
protobuf_lite_test_CXXFLAGS = $(NO_OPT_CXXFLAGS)
protobuf_lite_test_SOURCES =                                           \
  google/protobuf/lite_unittest.cc                                     \
  google/protobuf/test_util_lite.cc                                    \
  google/protobuf/test_util_lite.h
nodist_protobuf_lite_test_SOURCES = $(protoc_lite_outputs)

# Test plugin binary.
test_plugin_LDADD = $(PTHREAD_LIBS) libprotobuf.la libprotoc.la \
                    $(top_builddir)/gtest/lib/libgtest.la
test_plugin_CPPFLAGS = -I$(top_srcdir)/gtest/include         \
                       -I$(top_builddir)/gtest/include
test_plugin_SOURCES =                                          \
  google/protobuf/compiler/mock_code_generator.cc              \
  google/protobuf/testing/file.cc                              \
  google/protobuf/testing/file.h                               \
  google/protobuf/compiler/test_plugin.cc

if HAVE_ZLIB
zcgzip_LDADD = $(PTHREAD_LIBS) libprotobuf.la
zcgzip_SOURCES = google/protobuf/testing/zcgzip.cc

zcgunzip_LDADD = $(PTHREAD_LIBS) libprotobuf.la
zcgunzip_SOURCES = google/protobuf/testing/zcgunzip.cc
endif

TESTS = protobuf-test protobuf-lazy-descriptor-test protobuf-lite-test \
        google/protobuf/compiler/zip_output_unittest.sh $(GZTESTS)
