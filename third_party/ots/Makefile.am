NULL =

bin_PROGRAMS = \
  ot-sanitise \
  $(NULL)

noinst_PROGRAMS = \
  perf \
  $(NULL)

if HAVE_FREETYPE
noinst_PROGRAMS += \
  idempotent \
  validator-checker \
  side-by-side \
  $(NULL)
endif

lib_LIBRARIES = \
  libots.a \
  libbrotli.a \
  $(NULL)

TESTS = \
  cff_type2_charstring_test \
  layout_common_table_test \
  table_dependencies_test \
  tests/test_unmalicious_fonts.sh \
  $(NULL)

check_PROGRAMS = \
  cff_type2_charstring_test \
  layout_common_table_test \
  table_dependencies_test \
  $(NULL)

check_LIBRARIES = \
  libgtest.a \
  $(NULL)


libots_a_SOURCES = \
  src/cff.cc \
  src/cff.h \
  src/cff_type2_charstring.cc \
  src/cff_type2_charstring.h \
  src/cmap.cc \
  src/cmap.h \
  src/cvt.cc \
  src/cvt.h \
  src/fpgm.cc \
  src/fpgm.h \
  src/gasp.cc \
  src/gasp.h \
  src/gdef.cc \
  src/gdef.h \
  src/glyf.cc \
  src/glyf.h \
  src/gpos.cc \
  src/gpos.h \
  src/gsub.cc \
  src/gsub.h \
  src/hdmx.cc \
  src/hdmx.h \
  src/head.cc \
  src/head.h \
  src/hhea.cc \
  src/hhea.h \
  src/hmtx.cc \
  src/hmtx.h \
  src/kern.cc \
  src/kern.h \
  src/layout.cc \
  src/layout.h \
  src/loca.cc \
  src/loca.h \
  src/ltsh.cc \
  src/ltsh.h \
  src/maxp.cc \
  src/maxp.h \
  src/math.cc \
  src/math_.h \
  src/metrics.cc \
  src/metrics.h \
  src/name.cc \
  src/name.h \
  src/os2.cc \
  src/os2.h \
  src/ots.cc \
  src/ots.h \
  src/post.cc \
  src/post.h \
  src/prep.cc \
  src/prep.h \
  src/vdmx.cc \
  src/vdmx.h \
  src/vhea.cc \
  src/vhea.h \
  src/vmtx.cc \
  src/vmtx.h \
  src/vorg.cc \
  src/vorg.h \
  src/woff2.cc \
  src/woff2.h \
  $(NULL)


pkginclude_HEADERS = \
  include/ots-memory-stream.h \
  include/opentype-sanitiser.h \
  $(NULL)


libbrotli_a_SOURCES = \
  third_party/brotli/dec/bit_reader.c \
  third_party/brotli/dec/bit_reader.h \
  third_party/brotli/dec/context.h \
  third_party/brotli/dec/decode.c \
  third_party/brotli/dec/decode.h \
  third_party/brotli/dec/dictionary.h \
  third_party/brotli/dec/huffman.c \
  third_party/brotli/dec/huffman.h \
  third_party/brotli/dec/prefix.h \
  third_party/brotli/dec/safe_malloc.c \
  third_party/brotli/dec/safe_malloc.h \
  third_party/brotli/dec/streams.c \
  third_party/brotli/dec/streams.h \
  third_party/brotli/dec/transform.h \
  third_party/brotli/dec/types.h \
  $(NULL)


ot_sanitise_SOURCES = \
  util/ot-sanitise.cc \
  util/file-stream.h \
  $(NULL)


perf_SOURCES = \
  util/perf.cc \
  $(NULL)


idempotent_SOURCES = \
  util/idempotent.cc \
  $(NULL)


validator_checker_SOURCES = \
  util/validator-checker.cc \
  $(NULL)

side_by_side_SOURCES = \
  util/side-by-side.cc \
  $(NULL)


cff_type2_charstring_test_SOURCES = \
  tests/cff_type2_charstring_test.cc \
  $(NULL)

cff_type2_charstring_test_LDADD = \
  libgtest.a \
  $(LDADD) \
  $(NULL)


layout_common_table_test_SOURCES = \
  tests/layout_common_table_test.cc \
  $(NULL)

layout_common_table_test_LDADD = \
  libgtest.a \
  $(LDADD) \
  $(NULL)


table_dependencies_test_SOURCES = \
  tests/table_dependencies_test.cc \
  $(NULL)

table_dependencies_test_LDADD = \
  libgtest.a \
  $(LDADD) \
  $(NULL)


libgtest_a_SOURCES = \
  third_party/gtest/src/gtest-all.cc \
  third_party/gtest/src/gtest_main.cc \
  $(NULL)

libgtest_a_LIBADD = \
  $(PTHREAD_LIBS) \
  $(NULL)


AM_CPPFLAGS = \
  -I$(top_srcdir)/third_party/gtest/include \
  -I$(top_srcdir)/third_party/gtest/ \
  -I$(top_srcdir)/src \
  -I$(top_srcdir)/include \
  -I$(top_srcdir)/third_party/brotli/dec/ \
  $(GTEST_CPPFLAGS) \
  $(NULL)

AM_CXXFLAGS = \
  $(CORETEXT_CFLAGS) \
  $(FREETYPE_CFLAGS) \
  $(PTHREAD_CFLAGS) \
  $(NULL)

LDADD = \
  libots.a \
  libbrotli.a \
  -lz \
  $(CORETEXT_LIBS) \
  $(FREETYPE_LIBS) \
  $(NULL)


AM_TESTS_ENVIRONMENT = \
  EXEEXT="$(EXEEXT)"; \
  export EXEEXT; \
  top_srcdir="$(top_srcdir)"; \
  export top_srcdir; \
  top_builddir="$(top_builddir)"; \
  export top_builddir; \
  $(NULL)


MAINTAINERCLEANFILES = \
  $(GITIGNORE_MAINTAINERCLEANFILES_TOPLEVEL) \
  $(GITIGNORE_MAINTAINERCLEANFILES_M4_LIBTOOL) \
  $(GITIGNORE_MAINTAINERCLEANFILES_MAKEFILE_IN) \
  $(NULL)

-include $(top_srcdir)/git.mk
