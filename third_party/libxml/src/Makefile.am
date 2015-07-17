## Process this file with automake to produce Makefile.in

ACLOCAL_AMFLAGS = -I m4

SUBDIRS = include . doc example xstc $(PYTHON_SUBDIR)

DIST_SUBDIRS = include . doc example python xstc

AM_CPPFLAGS = -I$(top_builddir)/include -I$(srcdir)/include

AM_CFLAGS = $(THREAD_CFLAGS) $(Z_CFLAGS) $(LZMA_CFLAGS)

noinst_PROGRAMS=testSchemas testRelax testSAX testHTML testXPath testURI \
                testThreads testC14N testAutomata testRegexp \
                testReader testapi testModule runtest runsuite testchar \
		testdict runxmlconf testrecurse testlimits

bin_PROGRAMS = xmllint xmlcatalog

bin_SCRIPTS=xml2-config

lib_LTLIBRARIES = libxml2.la
libxml2_la_LIBADD = $(ICU_LIBS) $(THREAD_LIBS) $(Z_LIBS) $(LZMA_LIBS) $(ICONV_LIBS) $(M_LIBS) $(WIN32_EXTRA_LIBADD)

if USE_VERSION_SCRIPT
LIBXML2_VERSION_SCRIPT = $(VERSION_SCRIPT_FLAGS)$(srcdir)/libxml2.syms
else
LIBXML2_VERSION_SCRIPT =
endif

libxml2_la_LDFLAGS = $(CYGWIN_EXTRA_LDFLAGS) $(WIN32_EXTRA_LDFLAGS) \
		     $(LIBXML2_VERSION_SCRIPT) \
		     -version-info $(LIBXML_VERSION_INFO) \
		     $(MODULE_PLATFORM_LIBS)

if WITH_SAX1_SOURCES
docb_sources = DOCBparser.c
else
docb_sources =
endif

if WITH_TRIO_SOURCES
trio_sources = triostr.c trio.c
else
trio_sources =
endif

libxml2_la_SOURCES = SAX.c entities.c encoding.c error.c parserInternals.c  \
		parser.c tree.c hash.c list.c xmlIO.c xmlmemory.c uri.c  \
		valid.c xlink.c HTMLparser.c HTMLtree.c debugXML.c xpath.c  \
		xpointer.c xinclude.c nanohttp.c nanoftp.c \
		$(docb_sources) \
		catalog.c globals.c threads.c c14n.c xmlstring.c buf.c \
		xmlregexp.c xmlschemas.c xmlschemastypes.c xmlunicode.c \
		$(trio_sources) \
		xmlreader.c relaxng.c dict.c SAX2.c \
		xmlwriter.c legacy.c chvalid.c pattern.c xmlsave.c \
		xmlmodule.c schematron.c xzlib.c

DEPS = $(top_builddir)/libxml2.la
LDADDS = $(STATIC_BINARIES) $(top_builddir)/libxml2.la $(THREAD_LIBS) $(Z_LIBS) $(LZMA_LIBS) $(ICONV_LIBS) $(M_LIBS) $(WIN32_EXTRA_LIBADD)


man_MANS = xml2-config.1 libxml.3

m4datadir = $(datadir)/aclocal
m4data_DATA = libxml.m4

runtest_SOURCES=runtest.c
runtest_LDFLAGS = 
runtest_DEPENDENCIES = $(DEPS)
runtest_LDADD= $(BASE_THREAD_LIBS) $(RDL_LIBS) $(LDADDS)

testrecurse_SOURCES=testrecurse.c
testrecurse_LDFLAGS = 
testrecurse_DEPENDENCIES = $(DEPS)
testrecurse_LDADD= $(BASE_THREAD_LIBS) $(RDL_LIBS) $(LDADDS)

testlimits_SOURCES=testlimits.c
testlimits_LDFLAGS = 
testlimits_DEPENDENCIES = $(DEPS)
testlimits_LDADD= $(BASE_THREAD_LIBS) $(RDL_LIBS) $(LDADDS)

testchar_SOURCES=testchar.c
testchar_LDFLAGS = 
testchar_DEPENDENCIES = $(DEPS)
testchar_LDADD= $(RDL_LIBS) $(LDADDS)

testdict_SOURCES=testdict.c
testdict_LDFLAGS = 
testdict_DEPENDENCIES = $(DEPS)
testdict_LDADD= $(RDL_LIBS) $(LDADDS)

runsuite_SOURCES=runsuite.c
runsuite_LDFLAGS = 
runsuite_DEPENDENCIES = $(DEPS)
runsuite_LDADD= $(RDL_LIBS) $(LDADDS)

xmllint_SOURCES=xmllint.c
xmllint_LDFLAGS = 
xmllint_DEPENDENCIES = $(DEPS)
xmllint_LDADD=  $(RDL_LIBS) $(LDADDS)

testSAX_SOURCES=testSAX.c
testSAX_LDFLAGS = 
testSAX_DEPENDENCIES = $(DEPS)
testSAX_LDADD= $(LDADDS)

testHTML_SOURCES=testHTML.c
testHTML_LDFLAGS = 
testHTML_DEPENDENCIES = $(DEPS)
testHTML_LDADD= $(LDADDS)

xmlcatalog_SOURCES=xmlcatalog.c
xmlcatalog_LDFLAGS = 
xmlcatalog_DEPENDENCIES = $(DEPS)
xmlcatalog_LDADD = $(RDL_LIBS) $(LDADDS)

testXPath_SOURCES=testXPath.c
testXPath_LDFLAGS = 
testXPath_DEPENDENCIES = $(DEPS)
testXPath_LDADD= $(LDADDS)

testC14N_SOURCES=testC14N.c
testC14N_LDFLAGS = 
testC14N_DEPENDENCIES = $(DEPS)
testC14N_LDADD= $(LDADDS)

if THREADS_W32
testThreads_SOURCES = testThreadsWin32.c
else
testThreads_SOURCES = testThreads.c
endif
testThreads_LDFLAGS = 
testThreads_DEPENDENCIES = $(DEPS)
testThreads_LDADD= $(BASE_THREAD_LIBS) $(LDADDS)

testURI_SOURCES=testURI.c
testURI_LDFLAGS = 
testURI_DEPENDENCIES = $(DEPS)
testURI_LDADD= $(LDADDS)

testRegexp_SOURCES=testRegexp.c
testRegexp_LDFLAGS = 
testRegexp_DEPENDENCIES = $(DEPS)
testRegexp_LDADD= $(LDADDS)

testAutomata_SOURCES=testAutomata.c
testAutomata_LDFLAGS = 
testAutomata_DEPENDENCIES = $(DEPS)
testAutomata_LDADD= $(LDADDS)

testSchemas_SOURCES=testSchemas.c
testSchemas_LDFLAGS = 
testSchemas_DEPENDENCIES = $(DEPS)
testSchemas_LDADD= $(LDADDS)

testRelax_SOURCES=testRelax.c
testRelax_LDFLAGS = 
testRelax_DEPENDENCIES = $(DEPS)
testRelax_LDADD= $(LDADDS)

testReader_SOURCES=testReader.c
testReader_LDFLAGS = 
testReader_DEPENDENCIES = $(DEPS)
testReader_LDADD= $(LDADDS)

testModule_SOURCES=testModule.c
testModule_LDFLAGS = 
testModule_DEPENDENCIES = $(DEPS)
testModule_LDADD= $(LDADDS)

noinst_LTLIBRARIES = testdso.la
testdso_la_SOURCES = testdso.c
testdso_la_LDFLAGS = -module -no-undefined -avoid-version -rpath $(libdir)

# that one forces the rebuild when "make rebuild" is run on doc/
rebuild_testapi:
	-@(if [ "$(PYTHON)" != "" ] ; then \
	    $(PYTHON) $(srcdir)/gentest.py $(srcdir) ; fi )

# that one is just to make sure it is rebuilt if missing
# but adding the dependances generate mess
testapi.c: $(srcdir)/gentest.py
	-@(if [ "$(PYTHON)" != "" ] ; then \
	    $(PYTHON) $(srcdir)/gentest.py $(srcdir) ; fi )

BUILT_SOURCES = testapi.c

testapi_SOURCES=testapi.c
testapi_LDFLAGS = 
testapi_DEPENDENCIES = $(DEPS)
testapi_LDADD= $(LDADDS)

runxmlconf_SOURCES=runxmlconf.c
runxmlconf_LDFLAGS = 
runxmlconf_DEPENDENCIES = $(DEPS)
runxmlconf_LDADD= $(LDADDS)

#testOOM_SOURCES=testOOM.c testOOMlib.h testOOMlib.c
#testOOM_LDFLAGS = 
#testOOM_DEPENDENCIES = $(DEPS)
#testOOM_LDADD= $(LDADDS)

runtests:
	[ -d test   ] || $(LN_S) $(srcdir)/test   .
	[ -d result ] || $(LN_S) $(srcdir)/result .
	$(CHECKER) ./runtest$(EXEEXT) && $(CHECKER) ./testrecurse$(EXEEXT) &&$(CHECKER) ./testapi$(EXEEXT) && $(CHECKER) ./testchar$(EXEEXT)&& $(CHECKER) ./testdict$(EXEEXT) && $(CHECKER) ./runxmlconf$(EXEEXT)
	@(if [ "$(PYTHON_SUBDIR)" != "" ] ; then cd python ; \
	    $(MAKE) tests ; fi)

check: all runtests

check-valgrind valgrind: all
	@echo '## Running the regression tests under Valgrind'
	@echo '## Go get a cup of coffee it is gonna take a while ...'
	$(MAKE) CHECKER='valgrind -q' runtests

testall : tests SVGtests SAXtests

tests: XMLtests XMLenttests NStests IDtests Errtests APItests $(READER_TEST) $(TEST_SAX) $(TEST_PUSH) $(TEST_HTML) $(TEST_PHTML) $(TEST_VALID) URItests $(TEST_PATTERN) $(TEST_XPATH) $(TEST_XPTR) $(TEST_XINCLUDE) $(TEST_C14N) $(TEST_DEBUG) $(TEST_CATALOG) $(TEST_REGEXPS) $(TEST_SCHEMAS) $(TEST_SCHEMATRON) $(TEST_THREADS) Timingtests $(TEST_VTIME) $(PYTHON_TESTS) $(TEST_MODULES)
	@(if [ "$(PYTHON_SUBDIR)" != "" ] ; then cd python ; \
	    $(MAKE) tests ; fi)
	@(cd doc/examples ; $(MAKE) tests)

APItests: testapi$(EXEEXT)
	@echo "## Running the API regression tests this may take a little while"
	-@($(CHECKER) $(top_builddir)/testapi -q)

HTMLtests : testHTML$(EXEEXT)
	@(echo > .memdump)
	@echo "## HTML regression tests"
	-@(for i in $(srcdir)/test/HTML/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/HTML/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testHTML $$i > $(srcdir)/result/HTML/$$name 2>$(srcdir)/result/HTML/$$name.err ; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/testHTML $$i > result.$$name 2> error.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/HTML/$$name result.$$name ; \
	      diff -b $(srcdir)/result/HTML/$$name.err error.$$name ; \
	      $(CHECKER) $(top_builddir)/testHTML result.$$name > result2.$$name 2>error.$$name ; \
	      diff result.$$name result2.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name result2.$$name error.$$name ; \
	  fi ; fi ; done)

HTMLPushtests : testHTML$(EXEEXT)
	@echo "## Push HTML regression tests"
	-@(for i in $(srcdir)/test/HTML/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/HTML/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testHTML --push $$i > $(srcdir)/result/HTML/$$name 2>$(srcdir)/result/HTML/$$name.err ; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/testHTML --push $$i > result.$$name 2> error.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/HTML/$$name result.$$name ; \
	      cut -b 1-15 $(srcdir)/result/HTML/$$name.err > errorcut.$$name; \
	      cut -b 1-15 error.$$name > errorcut2.$$name; \
	      diff -b errorcut.$$name errorcut2.$$name ; \
	      $(CHECKER) $(top_builddir)/testHTML --push result.$$name > result2.$$name 2>error.$$name ; \
	      diff result.$$name result2.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name result2.$$name error.$$name errorcut.$$name errorcut2.$$name ; \
	  fi ; fi ; done)
	@echo "## HTML SAX regression tests"
	-@(for i in $(srcdir)/test/HTML/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/HTML/$$name.sax ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testHTML --sax $$i > $(srcdir)/result/HTML/$$name.sax ; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/testHTML --sax $$i > result.$$name.sax ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/HTML/$$name.sax result.$$name.sax` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name.sax ; \
	  fi ; fi ; done)
	@echo "## Push HTML SAX regression tests"
	-@(for i in $(srcdir)/test/HTML/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/HTML/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testHTML --push --sax $$i > $(srcdir)/result/HTML/$$name.sax ; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/testHTML --push --sax $$i 2>&1 > result.$$name.sax ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/HTML/$$name.sax result.$$name.sax` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name.sax ; \
	  fi ; fi ; done)

XMLtests : xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## XML regression tests"
	-@(for i in $(srcdir)/test/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint $$i > $(srcdir)/result/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	      diff $(srcdir)/result/$$name result.$$name ; \
	      $(CHECKER) $(top_builddir)/xmllint result.$$name 2>&1 > result2.$$name | grep -v 'failed to load external entity' ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	      diff result.$$name result2.$$name` ;\
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name result2.$$name ; \
	  fi ; fi ; done)
	@echo "## XML regression tests on memory"
	-@(for i in $(srcdir)/test/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --memory $$i > $(srcdir)/result/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --memory $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/$$name result.$$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --memory result.$$name 2>&1 > result2.$$name | grep -v 'failed to load external entity' ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"`; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      diff result.$$name result2.$$name ; \
	      rm result.$$name result2.$$name ; \
	  fi ; fi ; done)

XMLPushtests: xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## XML push regression tests"
	-@(for i in $(srcdir)/test/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --push $$i > $(srcdir)/result/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --push $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	      diff $(srcdir)/result/$$name result.$$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --push result.$$name 2>&1 > result2.$$name | grep -v 'failed to load external entity' ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	      diff result.$$name result2.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name result2.$$name ; \
	  fi ; fi ; done)

NStests : xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## XML Namespaces regression tests"
	-@(for i in $(srcdir)/test/namespaces/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/namespaces/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint $$i \
	         2> $(srcdir)/result/namespaces/$$name.err \
		 > $(srcdir)/result/namespaces/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint $$i 2> error.$$name > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	      diff $(srcdir)/result/namespaces/$$name result.$$name ; \
	      diff $(srcdir)/result/namespaces/$$name.err error.$$name`; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name error.$$name ; \
	  fi ; fi ; done)

IDtests : xmllint$(EXEEXT) testXPath$(EXEEXT)
	@(echo > .memdump)
	@echo "## xml:id regression tests"
	-@(for i in $(srcdir)/test/xmlid/id_*.xml ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/xmlid/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testXPath -i $$i "id('bar')" \
	         2> $(srcdir)/result/xmlid/$$name.err \
		 > $(srcdir)/result/xmlid/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/testXPath -i $$i "id('bar')" 2> error.$$name > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	      diff $(srcdir)/result/xmlid/$$name result.$$name ; \
	      diff $(srcdir)/result/xmlid/$$name.err error.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name error.$$name ; \
	  fi ; fi ; done)

Errtests : xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## Error cases regression tests"
	-@(for i in $(srcdir)/test/errors/*.xml ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/errors/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint $$i \
	         2> $(srcdir)/result/errors/$$name.err \
		 > $(srcdir)/result/errors/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint $$i 2> error.$$name > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	      diff $(srcdir)/result/errors/$$name result.$$name ; \
	      diff $(srcdir)/result/errors/$$name.err error.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name error.$$name ; \
	  fi ; fi ; done)
	@echo "## Error cases stream regression tests"
	-@(for i in $(srcdir)/test/errors/*.xml ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/errors/$$name.str ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --stream $$i \
	         2> $(srcdir)/result/errors/$$name.str \
		 > /dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --stream $$i 2> error.$$name > /dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	      diff $(srcdir)/result/errors/$$name.str error.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm error.$$name ; \
	  fi ; fi ; done)

Docbtests : xmllint$(EXEEXT)

XMLenttests : xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## XML entity subst regression tests"
	-@(for i in $(srcdir)/test/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/noent/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --noent $$i > $(srcdir)/result/noent/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --noent $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	      diff $(srcdir)/result/noent/$$name result.$$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --noent result.$$name 2>&1 > result2.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	      diff result.$$name result2.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name result2.$$name ; \
	  fi ; fi ; done)

URItests : testURI$(EXEEXT)
	@(echo > .memdump)
	@echo "## URI module regression tests"
	-@(for i in $(srcdir)/test/URI/*.data ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/URI/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testURI -base 'http://foo.com/path/to/index.html?orig#help' < $$i > $(srcdir)/result/URI/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/testURI -base 'http://foo.com/path/to/index.html?orig#help' < $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/URI/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)
	-@(for i in $(srcdir)/test/URI/*.uri ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/URI/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testURI < $$i > $(srcdir)/result/URI/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/testURI < $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/URI/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)

XPathtests : testXPath$(EXEEXT)
	@(echo > .memdump)
	@echo "## XPath regression tests"
	-@(if [ "`$(top_builddir)/testXPath | grep 'support not compiled in'`" != "" ] ; \
	  then echo Skipping debug not compiled in ; exit 0 ; fi ; \
	  for i in $(srcdir)/test/XPath/expr/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/XPath/expr/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testXPath -f --expr $$i > $(srcdir)/result/XPath/expr/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/testXPath -f --expr $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/XPath/expr/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done ; \
	  for i in $(srcdir)/test/XPath/docs/* ; do \
	  if [ ! -d $$i ] ; then \
	  doc=`basename $$i`; \
	  for j in $(srcdir)/test/XPath/tests/$$doc* ; do \
	  if [ ! -f $$j ] ; then continue ; fi ; \
	  name=`basename $$j`; \
	  if [ ! -d $$j ] ; then \
	  if [ ! -f $(srcdir)/result/XPath/tests/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testXPath -f -i $$i $$j > $(srcdir)/result/XPath/tests/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/testXPath -f -i $$i $$j 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/XPath/tests/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done ; fi ; done)

XPtrtests : testXPath$(EXEEXT)
	@(echo > .memdump)
	@echo "## XPointer regression tests"
	-@(if [ "`$(top_builddir)/testXPath | grep 'support not compiled in'`" != "" ] ; \
	  then echo Skipping debug not compiled in ; exit 0 ; fi ; \
	  for i in $(srcdir)/test/XPath/docs/* ; do \
	  if [ ! -d $$i ] ; then \
	  doc=`basename $$i`; \
	  for j in $(srcdir)/test/XPath/xptr/$$doc* ; do \
	  if [ ! -f $$j ] ; then continue ; fi ; \
	  name=`basename $$j`; \
	  if [ ! -d $$j ] ; then \
	  if [ ! -f $(srcdir)/result/XPath/xptr/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testXPath -xptr -f -i $$i $$j > $(srcdir)/result/XPath/xptr/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	  else \
	      log=`$(CHECKER) $(top_builddir)/testXPath -xptr -f -i $$i $$j 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/XPath/xptr/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done ; fi ; done)

XIncludetests : xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## XInclude regression tests"
	-@(for i in $(srcdir)/test/XInclude/docs/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/XInclude/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --nowarning --xinclude $$i > $(srcdir)/result/XInclude/$$name 2> $(srcdir)/result/XInclude/$$name.err ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --nowarning --xinclude $$i > result.$$name 2>error.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/XInclude/$$name result.$$name ; \
	      diff $(srcdir)/result/XInclude/$$name.err error.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name error.$$name ; \
	  fi ; fi ; done)
	-@(for i in $(srcdir)/test/XInclude/docs/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/XInclude/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --nowarning --noxincludenode $$i > $(srcdir)/result/XInclude/$$name 2> $(srcdir)/result/XInclude/$$name.err ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --nowarning --noxincludenode $$i > result.$$name 2>error.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/XInclude/$$name result.$$name ; \
	      diff $(srcdir)/result/XInclude/$$name.err error.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name error.$$name ; \
	  fi ; fi ; done)
	@(echo > .memdump)
	@echo "## XInclude xmlReader regression tests"
	-@(for i in $(srcdir)/test/XInclude/docs/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/XInclude/$$name.rdr ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --nowarning --xinclude --stream --debug $$i > $(srcdir)/result/XInclude/$$name.rdr ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --nowarning --xinclude --stream --debug $$i > result.$$name 2>error.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/XInclude/$$name.err error.$$name ; \
	      diff $(srcdir)/result/XInclude/$$name.rdr result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name error.$$name ; \
	  fi ; fi ; done)
	-@(for i in $(srcdir)/test/XInclude/docs/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/XInclude/$$name.rdr ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --nowarning --noxincludenode --stream --debug $$i > $(srcdir)/result/XInclude/$$name.rdr ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --nowarning --xinclude --stream --debug $$i > result.$$name 2>error.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/XInclude/$$name.err error.$$name ; \
	      diff $(srcdir)/result/XInclude/$$name.rdr result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name error.$$name ; \
	  fi ; fi ; done)

Scripttests : xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## Scripts regression tests"
	@echo "## Some of the base computations may be different if srcdir != ."
	-@(for i in $(srcdir)/test/scripts/*.script ; do \
	  name=`basename $$i .script`; \
	  xml=$(srcdir)/test/scripts/`basename $$i .script`.xml; \
	  if [ -f $$xml ] ; then \
	  if [ ! -f $(srcdir)/result/scripts/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --shell $$xml < $$i > $(srcdir)/result/scripts/$$name 2> $(srcdir)/result/scripts/$$name.err ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --shell $$xml < $$i > result.$$name 2> result.$$name.err ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/scripts/$$name result.$$name ; \
	      diff $(srcdir)/result/scripts/$$name.err result.$$name.err` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name result.$$name.err ; \
	  fi ; fi ; done)

Catatests : xmlcatalog$(EXEEXT)
	@(echo > .memdump)
	@echo "## Catalog regression tests"
	-@(for i in $(srcdir)/test/catalogs/*.script ; do \
	  name=`basename $$i .script`; \
	  xml=$(srcdir)/test/catalogs/`basename $$i .script`.xml; \
	  if [ -f $$xml ] ; then \
	  if [ ! -f $(srcdir)/result/catalogs/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmlcatalog --shell $$xml < $$i 2>&1 > $(srcdir)/result/catalogs/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmlcatalog --shell $$xml < $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/catalogs/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)
	-@(for i in $(srcdir)/test/catalogs/*.script ; do \
	  name=`basename $$i .script`; \
	  sgml=$(srcdir)/test/catalogs/`basename $$i .script`.sgml; \
	  if [ -f $$sgml ] ; then \
	  if [ ! -f $(srcdir)/result/catalogs/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmlcatalog --shell $$sgml < $$i > $(srcdir)/result/catalogs/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmlcatalog --shell $$sgml < $$i > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/catalogs/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)
	@echo "## Add and del operations on XML Catalogs"
	-@($(CHECKER) $(top_builddir)/xmlcatalog --create --noout $(srcdir)/result/catalogs/mycatalog; \
	grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	$(CHECKER) $(top_builddir)/xmlcatalog --noout --add public Pubid sysid $(srcdir)/result/catalogs/mycatalog; \
	grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	$(CHECKER) $(top_builddir)/xmlcatalog --noout --add public Pubid2 sysid2 $(srcdir)/result/catalogs/mycatalog; \
	grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	$(CHECKER) $(top_builddir)/xmlcatalog --noout --add public Pubid3 sysid3 $(srcdir)/result/catalogs/mycatalog; \
	grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	diff result/catalogs/mycatalog.full $(srcdir)/result/catalogs/mycatalog; \
	grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	$(CHECKER) $(top_builddir)/xmlcatalog --noout --del sysid $(srcdir)/result/catalogs/mycatalog; \
	grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	$(CHECKER) $(top_builddir)/xmlcatalog --noout --del sysid3 $(srcdir)/result/catalogs/mycatalog; \
	grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	$(CHECKER) $(top_builddir)/xmlcatalog --noout --del sysid2 $(srcdir)/result/catalogs/mycatalog; \
	grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	diff result/catalogs/mycatalog.empty $(srcdir)/result/catalogs/mycatalog; \
	grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	rm -f $(srcdir)/result/catalogs/mycatalog)

SVGtests : xmllint$(EXEEXT)
	@echo "## SVG parsing regression tests"
	-@(for i in $(srcdir)/test/SVG/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/SVG/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint $$i > $(srcdir)/result/SVG/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      echo Testing $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint $$i > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/SVG/$$name result.$$name ; \
	      $(CHECKER) $(top_builddir)/xmllint result.$$name > result2.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff result.$$name result2.$$name ; \
	      rm result.$$name result2.$$name ; \
	  fi ; fi ; done)

Threadtests : testThreads$(EXEEXT)
	@echo "## Threaded regression tests"
	-@($(CHECKER) $(top_builddir)/testThreads ; \
	   grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"; \
	   exit 0)

Readertests : xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## Reader regression tests"
	-@(for i in $(srcdir)/test/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/$$name.rdr ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --nonet --debug --stream $$i > $(srcdir)/result/$$name.rdr 2>/dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --nonet --debug --stream $$i > result.$$name 2>/dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/$$name.rdr result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)
	@echo "## Reader on memory regression tests"
	-@(for i in $(srcdir)/test/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/$$name.rdr ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --memory --nonet --debug --stream $$i > $(srcdir)/result/$$name.rdr 2>/dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --memory --nonet --debug --stream $$i > result.$$name 2>/dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/$$name.rdr result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)
	@(echo > .memdump)
	@echo "## Walker regression tests"
	-@(for i in $(srcdir)/test/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/$$name.rdr ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --nonet --debug --walker $$i > $(srcdir)/result/$$name.rdr 2>/dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --nonet --debug --walker $$i > result.$$name 2>/dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/$$name.rdr result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)
	@echo "## Reader entities substitution regression tests"
	-@(for i in $(srcdir)/test/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/$$name.rde ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --noent --nonet --debug --stream $$i > $(srcdir)/result/$$name.rde 2>/dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --noent --nonet --debug --stream $$i > result.$$name 2>/dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/$$name.rde result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)

SAXtests : testSAX$(EXEEXT)
	@(echo > .memdump)
	@echo "## SAX1 callbacks regression tests"
	-@(for i in $(srcdir)/test/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/$$name.sax ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testSAX $$i > $(srcdir)/result/$$name.sax 2> /dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/testSAX $$i > result.$$name 2> /dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/$$name.sax result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)
	@echo "## SAX2 callbacks regression tests"
	-@(for i in $(srcdir)/test/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/$$name.sax2 ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testSAX --sax2 $$i > $(srcdir)/result/$$name.sax2 2> /dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/testSAX --sax2 $$i > result.$$name 2> /dev/null ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/$$name.sax2 result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)

Validtests : xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## Valid documents regression tests"
	-@(for i in $(srcdir)/test/VCM/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	      log=`$(CHECKER) $(top_builddir)/xmllint --valid --noout --nowarning $$i ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0"`;\
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	  fi ; done ; exit 0)
	@echo "## Validity checking regression tests"
	-@(for i in $(srcdir)/test/VC/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/VC/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --noout --valid $$i 2> $(srcdir)/result/VC/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --noout --valid $$i 2> result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/VC/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)
	@echo "## General documents valid regression tests"
	-@(for i in $(srcdir)/test/valid/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/valid/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint --valid $$i > $(srcdir)/result/valid/$$name 2>$(srcdir)/result/valid/$$name.err ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint --valid $$i > result.$$name 2>error.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/valid/$$name result.$$name ; \
	      diff $(srcdir)/result/valid/$$name.err error.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name error.$$name ; \
	  fi ; fi ; done)

Regexptests: testRegexp$(EXEEXT)
	@(echo > .memdump)
	@echo "## Regexp regression tests"
	-@(for i in $(srcdir)/test/regexp/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/regexp/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testRegexp -i $$i > $(srcdir)/result/regexp/$$name; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/testRegexp -i $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/regexp/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)
	@echo "## Formal expresssions regression tests"
	-@(for i in $(srcdir)/test/expr/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/expr/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testRegexp --expr -i $$i > $(srcdir)/result/expr/$$name; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/testRegexp --expr -i $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/expr/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)

Automatatests: testAutomata$(EXEEXT)
	@(echo > .memdump)
	@echo "## Automata regression tests"
	-@(for i in $(srcdir)/test/automata/* ; do \
	  name=`basename $$i`; \
	  if [ ! -d $$i ] ; then \
	  if [ ! -f $(srcdir)/result/automata/$$name ] ; then \
	      echo New test file $$name ; \
	      $(CHECKER) $(top_builddir)/testAutomata $$i > $(srcdir)/result/automata/$$name; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/testAutomata $$i 2>&1 > result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/automata/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done)

dba100000.xml: dbgenattr.pl
	@echo "## generating dba100000.xml"
	@($(PERL) $(top_srcdir)/dbgenattr.pl 100000 > dba100000.xml)

Timingtests: xmllint$(EXEEXT) dba100000.xml
	@echo "## Timing tests to try to detect performance"
	@echo "## as well a memory usage breakage when streaming"
	@echo "## 1/ using the file interface"
	@echo "## 2/ using the memory interface"
	@echo "## 3/ repeated DOM parsing"
	@echo "## 4/ repeated DOM validation"
	-@($(top_builddir)/xmllint --stream --timing dba100000.xml; \
	   MEM=`cat .memdump | grep "MEMORY ALLOCATED" | awk '{ print $$7}'`;\
	   if [ "$$MEM" != "" ] ; then echo Using $$MEM bytes ; fi ; \
	   grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	   exit 0)
	-@($(top_builddir)/xmllint --stream --timing --memory dba100000.xml; \
	   MEM=`cat .memdump | grep "MEMORY ALLOCATED" | awk '{ print $$7}'`;\
	   if [ "$$MEM" != "" ] ; then echo Using $$MEM bytes ; fi ; \
	   grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	   exit 0)
	-@($(top_builddir)/xmllint --noout --timing --repeat $(srcdir)/test/valid/REC-xml-19980210.xml; \
	   MEM=`cat .memdump | grep "MEMORY ALLOCATED" | awk '{ print $$7}'`;\
	   if [ "$$MEM" != "" ] ; then echo Using $$MEM bytes ; fi ; \
	   grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	   exit 0)

VTimingtests: xmllint$(EXEEXT)
	-@($(top_builddir)/xmllint --noout --timing --valid --repeat $(srcdir)/test/valid/REC-xml-19980210.xml; \
	   MEM=`cat .memdump | grep "MEMORY ALLOCATED" | awk '{ print $$7}'`;\
	   if [ "$$MEM" != "" ] ; then echo Using $$MEM bytes ; fi ; \
	   grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	   exit 0)

C14Ntests : testC14N$(EXEEXT)
	@echo "## C14N and XPath regression tests"
	-@(for m in with-comments without-comments 1-1-without-comments exc-without-comments ; do \
	    for i in $(srcdir)/test/c14n/$$m/*.xml ; do  \
		if [ ! -d $$i ] ; then \
		    name=`basename $$i .xml`; \
		    cmdline="$(CHECKER) $(top_builddir)/testC14N --$$m $$i"; \
		    if [ -f $(srcdir)/test/c14n/$$m/$$name.xpath ] ; then \
			cmdline="$$cmdline $(srcdir)/test/c14n/$$m/$$name.xpath"; \
			if [ -f $(srcdir)/test/c14n/$$m/$$name.ns ] ; then \
			    cmdline="$$cmdline '`cat $(srcdir)/test/c14n/$$m/$$name.ns`'"; \
			fi; \
		    fi; \
		    $$cmdline > $(srcdir)/test/c14n/test.tmp; \
		    if [ $$? -eq 0 ]; then \
			diff  $(srcdir)/result/c14n/$$m/$$name $(srcdir)/test/c14n/test.tmp; \
			if [ $$? -ne 0 ]; then \
			    echo "Test $$m/$$name failed"; \
			    cat $(srcdir)/test/c14n/test.tmp; \
			fi; \
		    else \
			echo "C14N failed"; \
		    fi; \
		    grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
		fi; \
		rm -f $(srcdir)/test/c14n/test.tmp; \
	    done; \
	done)

Schemastests: testSchemas$(EXEEXT)
	@(echo > .memdump)
	@echo "## Schemas regression tests"
	-@(for i in $(srcdir)/test/schemas/*_*.xsd ; do \
	  name=`basename $$i | sed 's+_.*++'`; \
	  sno=`basename $$i | sed 's+.*_\(.*\).xsd+\1+'`; \
	  for j in $(srcdir)/test/schemas/"$$name"_*.xml ; do \
	      if [ -f $$j ] ; then \
	      xno=`basename $$j | sed 's+.*_\(.*\).xml+\1+'`; \
	      if [ ! -f $(srcdir)/result/schemas/"$$name"_"$$sno"_"$$xno" ]; \
	      then \
		  echo New test file "$$name"_"$$sno"_"$$xno" ; \
		  $(CHECKER) $(top_builddir)/testSchemas $$i $$j \
		    > $(srcdir)/result/schemas/"$$name"_"$$sno"_"$$xno" \
		    2> $(srcdir)/result/schemas/"$$name"_"$$sno"_"$$xno".err; \
	          grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      else \
	          log=`$(CHECKER) $(top_builddir)/testSchemas $$i $$j \
		    > res.$$name 2> err.$$name;\
	          grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	          diff $(srcdir)/result/schemas/"$$name"_"$$sno"_"$$xno" \
		       res.$$name;\
	          diff $(srcdir)/result/schemas/"$$name"_"$$sno"_"$$xno".err \
		       err.$$name;\
		  grep Unimplemented err.$$name`; \
	          if [ -n "$$log" ] ; then echo "$$name"_"$$sno"_"$$xno" result ; echo $$log ; fi ; \
	          rm res.$$name err.$$name ; \
	       fi ; fi ;\
	  done; done)

Relaxtests: xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## Relax-NG regression tests"
	-@(for i in $(srcdir)/test/relaxng/*.rng ; do \
	  name=`basename $$i | sed 's+\.rng++'`; \
	  if [ ! -f $(srcdir)/result/relaxng/"$$name"_valid ] ; then \
	      echo New schemas $$name ; \
	      $(CHECKER) $(top_builddir)/xmllint$(EXEEXT) --noout --relaxng $(srcdir)/test/relaxng/tutorA.rng $$i \
		      > $(srcdir)/result/relaxng/"$$name"_valid \
		      2> $(srcdir)/result/relaxng/"$$name"_err; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	  else \
	      log=`$(CHECKER) $(top_builddir)/xmllint$(EXEEXT) --noout --relaxng $(srcdir)/test/relaxng/tutorA.rng $$i \
	      > res.$$name 2> err.$$name;\
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      diff $(srcdir)/result/relaxng/"$$name"_valid \
		   res.$$name;\
	      diff $(srcdir)/result/relaxng/"$$name"_err \
		   err.$$name | grep -v "error detected at";\
	      grep Unimplemented err.$$name`; \
	      if [ -n "$$log" ] ; then echo schemas $$name result ; echo $$log ; fi ; \
	      rm res.$$name err.$$name ; \
	  fi; \
	  for j in $(srcdir)/test/relaxng/"$$name"_*.xml ; do \
	      if [ -f $$j ] ; then \
	      xno=`basename $$j | sed 's+.*_\(.*\).xml+\1+'`; \
	      if [ ! -f $(srcdir)/result/relaxng/"$$name"_"$$xno" ]; \
	      then \
		  echo New test file "$$name"_"$$xno" ; \
		  $(CHECKER) $(top_builddir)/xmllint$(EXEEXT) --noout --relaxng $$i $$j \
		    > $(srcdir)/result/relaxng/"$$name"_"$$xno" \
		    2> $(srcdir)/result/relaxng/"$$name"_"$$xno".err; \
	          grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      else \
	          log=`$(CHECKER) $(top_builddir)/xmllint$(EXEEXT) --noout --relaxng $$i $$j \
		    > res.$$name 2> err.$$name;\
	          grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	          diff $(srcdir)/result/relaxng/"$$name"_"$$xno" \
		       res.$$name;\
	          diff $(srcdir)/result/relaxng/"$$name"_"$$xno".err \
		       err.$$name | grep -v "error detected at";\
		  grep Unimplemented err.$$name`; \
		  if [ -n "$$log" ] ; then echo "$$name"_"$$xno" result ; echo $$log ; fi ; \
	          rm res.$$name err.$$name ; \
	       fi ; fi ; \
	  done; done)
	@echo "## Relax-NG streaming regression tests"
	-@(for i in $(srcdir)/test/relaxng/*.rng ; do \
	  name=`basename $$i | sed 's+\.rng++'`; \
	  for j in $(srcdir)/test/relaxng/"$$name"_*.xml ; do \
	      if [ -f $$j ] ; then \
	      xno=`basename $$j | sed 's+.*_\(.*\).xml+\1+'`; \
	      if [ ! -f $(srcdir)/result/relaxng/"$$name"_"$$xno" ]; \
	      then \
		  echo New test file "$$name"_"$$xno" ; \
		  $(CHECKER) $(top_builddir)/xmllint$(EXEEXT) --noout --relaxng $$i $$j \
		    > $(srcdir)/result/relaxng/"$$name"_"$$xno" \
		    2> $(srcdir)/result/relaxng/"$$name"_"$$xno".err; \
	          grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      else \
	          log=`$(CHECKER) $(top_builddir)/xmllint$(EXEEXT) --noout --stream --relaxng $$i $$j \
		    > res.$$name 2> err.$$name;\
	          grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	          diff $(srcdir)/result/relaxng/"$$name"_"$$xno" res.$$name;\
		  if [ "$$name" != "tutor10_1" -a "$$name" != "tutor10_2" -a "$$name" != "tutor3_2" -a "$$name" != "307377" -a "$$name" != "tutor8_2" ] ; then \
		      diff $(srcdir)/result/relaxng/"$$name"_"$$xno".err \
			   err.$$name | grep -v "error detected at";\
		  fi ; grep Unimplemented err.$$name`; \
	          if [ -n "$$log" ] ; then echo "$$name"_"$$xno" result ; echo $$log ; fi ; \
	          rm res.$$name err.$$name ; \
	       fi ; fi ; \
	  done; done)

Schematrontests: xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## Schematron regression tests"
	-@(for i in $(srcdir)/test/schematron/*.sct ; do \
	  name=`basename $$i | sed 's+\.sct++'`; \
	  for j in $(srcdir)/test/schematron/"$$name"_*.xml ; do \
	      if [ -f $$j ] ; then \
	      xno=`basename $$j | sed 's+.*_\(.*\).xml+\1+'`; \
	      if [ ! -f $(srcdir)/result/schematron/"$$name"_"$$xno" ]; \
	      then \
		  echo New test file "$$name"_"$$xno" ; \
		  $(CHECKER) $(top_builddir)/xmllint$(EXEEXT) --schematron $$i $$j \
		    > $(srcdir)/result/schematron/"$$name"_"$$xno" \
		    2> $(srcdir)/result/schematron/"$$name"_"$$xno".err; \
	          grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      else \
	          log=`$(CHECKER) $(top_builddir)/xmllint$(EXEEXT) --schematron $$i $$j \
		    > res.$$name 2> err.$$name;\
	          grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	          diff $(srcdir)/result/schematron/"$$name"_"$$xno" \
		       res.$$name;\
	          diff $(srcdir)/result/schematron/"$$name"_"$$xno".err \
		       err.$$name | grep -v "error detected at";\
		  grep Unimplemented err.$$name`; \
		  if [ -n "$$log" ] ; then echo "$$name"_"$$xno" result ; echo $$log ; fi ; \
	          rm res.$$name err.$$name ; \
	       fi ; fi ; \
	  done; done)

RelaxNGPythonTests:
	@(if [ -x $(PYTHON) ] ; then \
	    PYTHONPATH=$(top_builddir)/python:$(top_builddir)/python/.libs:$$PYTHONPATH ; \
	    export PYTHONPATH; \
	    LD_LIBRARY_PATH="$(top_builddir)/.libs:$$LD_LIBRARY_PATH" ; \
	    export LD_LIBRARY_PATH; \
	    echo "## Relax-NG Python based test suite 1" ; \
	    $(CHECKER) $(PYTHON) $(srcdir)/check-relaxng-test-suite.py ; \
	    echo "## Relax-NG Python based test suite 2" ; \
	    $(CHECKER) $(PYTHON) $(srcdir)/check-relaxng-test-suite2.py ; \
	  fi)

SchemasPythonTests:
	@(if [ -x $(PYTHON) ] ; then \
	    PYTHONPATH=$(top_builddir)/python:$(top_builddir)/python/.libs:$$PYTHONPATH; \
	    export PYTHONPATH; \
	    LD_LIBRARY_PATH="$(top_builddir)/.libs:$$LD_LIBRARY_PATH" ; \
	    export LD_LIBRARY_PATH; \
	    echo "## XML Schemas datatypes Python based test suite" ; \
	    echo "## It is normal to see 11 errors reported" ; \
	    $(CHECKER) $(PYTHON) $(srcdir)/check-xsddata-test-suite.py ; \
	  fi)
	@(if [ -x $(PYTHON) -a -d xstc ] ; then cd xstc ; $(MAKE) CHECKER="$(CHECKER)" pytests ; fi)

Patterntests: xmllint$(EXEEXT)
	@(echo > .memdump)
	@echo "## Pattern regression tests"
	-@(for i in $(srcdir)/test/pattern/*.pat ; do \
	  name=`basename $$i .pat`; \
	  if [ -f $(srcdir)/test/pattern/$$name.xml ] ; then \
	  if [ ! -f $(srcdir)/result/pattern/$$name ] ; then \
	      rm -f result.$$name ; \
	      echo New test file $$name ; \
	      for pat in `cat $$i` ; do \
	      $(CHECKER) $(top_builddir)/xmllint --walker --pattern $$pat $(srcdir)/test/pattern/$$name.xml >> $(srcdir)/result/pattern/$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      done ;\
	  else \
	      rm -f result.$$name ; \
	      lst=`cat $$i` ; \
	      log=`for pat in $$lst ; do $(CHECKER) $(top_builddir)/xmllint --walker --pattern $$pat $(srcdir)/test/pattern/$$name.xml 2>&1 >> result.$$name ; \
	      grep "MORY ALLO" .memdump  | grep -v "MEMORY ALLOCATED : 0";\
	      done ;\
	      diff $(srcdir)/result/pattern/$$name result.$$name` ; \
	      if [ -n "$$log" ] ; then echo $$name result ; echo $$log ; fi ; \
	      rm result.$$name ; \
	  fi ; fi ; done ;)

ModuleTests: testModule$(EXEEXT) testdso.la
	@echo "## Module tests"
	@(./testModule$(EXEEXT))

cleanup:
	-@(find . -name .\#\* -exec rm {} \;)
	-@(find . -name \*.gcda -o -name \*.gcno -exec rm -f {} \;)
	-@(find . -name \*.orig -o -name \*.rej -o -name \*.old -exec rm -f {} \;)

dist-hook: cleanup libxml2.spec
	-cp libxml2.spec $(distdir)
	(cd $(srcdir) ; tar -cf - --exclude CVS --exclude .svn --exclude .git win32 macos os400 vms VxWorks bakefile test result) | (cd $(distdir); tar xf -)

dist-source: distdir
	$(AMTAR) -chof - --exclude Tests --exclude test --exclude result $(distdir) | GZIP=$(GZIP_ENV) gzip -c >`echo "$(distdir)" | sed "s+libxml2+libxml2-sources+"`.tar.gz

dist-test: distdir
	(mkdir -p $(distdir))
	(cd $(srcdir) ; tar -cf - --exclude CVS --exclude .svn --exclude .git xstc/Tests) | (cd $(distdir); tar xf -)
	tar -cf - $(distdir)/test $(distdir)/result $(distdir)/xstc/Tests  $(distdir)/Makefile.tests $(distdir)/README $(distdir)/README.tests $(distdir)/AUTHORS $(distdir)/testapi.c $(distdir)/runtest.c $(distdir)/runsuite.c | GZIP=$(GZIP_ENV) gzip -c >`echo "$(distdir)" | sed "s+libxml2+libxml2-tests+"`.tar.gz
	@(rm -rf $(distdir)/xstc/Test)

cleantar:
	@(rm -f libxml*.tar.gz COPYING.LIB)

rpm: cleanup cleantar
	@(unset CDPATH ; $(MAKE) dist-source dist && rpmbuild -ta $(distdir).tar.gz)

## We create xml2Conf.sh here and not from configure because we want
## to get the paths expanded correctly.  Macros like srcdir are given
## the value NONE in configure if the user doesn't specify them (this
## is an autoconf feature, not a bug).

xml2Conf.sh: xml2Conf.sh.in Makefile
## Use sed and then mv to avoid problems if the user interrupts.
	sed -e 's?\@XML_LIBDIR\@?$(XML_LIBDIR)?g' \
	    -e 's?\@XML_INCLUDEDIR\@?$(XML_INCLUDEDIR)?g' \
	    -e 's?\@VERSION\@?$(VERSION)?g' \
	    -e 's?\@XML_LIBS\@?$(XML_LIBS)?g' \
	       < $(srcdir)/xml2Conf.sh.in > xml2Conf.tmp \
	&& mv xml2Conf.tmp xml2Conf.sh

CLEANFILES = runxmlconf.log test.out xml2Conf.sh *.gcda *.gcno *.res
DISTCLEANFILES = COPYING missing.lst

confexecdir=$(libdir)
confexec_DATA = xml2Conf.sh
CVS_EXTRA_DIST=
EXTRA_DIST = xml2-config.in xml2Conf.sh.in libxml.spec.in libxml2.spec \
             libxml.m4 Copyright check-xml-test-suite.py gentest.py \
	     check-relaxng-test-suite.py check-relaxng-test-suite2.py \
	     check-xsddata-test-suite.py check-xinclude-test-suite.py \
             example/Makefile.am example/gjobread.c example/gjobs.xml \
	     $(man_MANS) libxml-2.0.pc.in libxml-2.0-uninstalled.pc.in \
	     libxml2-config.cmake.in \
	     trionan.c trionan.h triostr.c triostr.h trio.c trio.h \
	     triop.h triodef.h libxml.h elfgcchack.h xzlib.h buf.h \
	     enc.h save.h testThreadsWin32.c genUnicode.py TODO_SCHEMAS \
	     dbgen.pl dbgenattr.pl regressions.py regressions.xml \
	     README.tests Makefile.tests libxml2.syms timsort.h \
	     $(CVS_EXTRA_DIST)


pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libxml-2.0.pc

cmakedir = $(libdir)/cmake/libxml2
cmake_DATA = libxml2-config.cmake

#
# Install the tests program sources as examples 
#
BASE_DIR=$(datadir)/doc
DOC_MODULE=libxml2-$(VERSION)
EXAMPLES_DIR=$(BASE_DIR)/$(DOC_MODULE)/examples

install-data-local: 
	$(MKDIR_P) $(DESTDIR)$(BASE_DIR)/$(DOC_MODULE)
	-$(INSTALL) -m 0644 $(srcdir)/Copyright $(DESTDIR)$(BASE_DIR)/$(DOC_MODULE)
	$(MKDIR_P) $(DESTDIR)$(EXAMPLES_DIR)
	-$(INSTALL) -m 0644 $(srcdir)/xmllint.c $(DESTDIR)$(EXAMPLES_DIR)
	-$(INSTALL) -m 0644 $(srcdir)/testSAX.c $(DESTDIR)$(EXAMPLES_DIR)
	-$(INSTALL) -m 0644 $(srcdir)/testHTML.c $(DESTDIR)$(EXAMPLES_DIR)
	-$(INSTALL) -m 0644 $(srcdir)/testXPath.c $(DESTDIR)$(EXAMPLES_DIR)

uninstall-local:
	rm -f $(DESTDIR)$(EXAMPLES_DIR)/testXPath.c
	rm -f $(DESTDIR)$(EXAMPLES_DIR)/testHTML.c
	rm -f $(DESTDIR)$(EXAMPLES_DIR)/testSAX.c
	rm -f $(DESTDIR)$(EXAMPLES_DIR)/xmllint.c
	rm -rf $(DESTDIR)$(EXAMPLES_DIR)
	rm -f $(DESTDIR)$(BASE_DIR)/$(DOC_MODULE)/Copyright
	rm -rf $(DESTDIR)$(BASE_DIR)/$(DOC_MODULE)

tst: tst.c
	$(CC) $(CFLAGS) -Iinclude -o tst tst.c .libs/libxml2.a -lpthread -lm -lz -llzma

sparse: clean
	$(MAKE) CC=cgcc

#
# Coverage support, largely borrowed from libvirt
# Both binaries comes from the lcov package in Fedora
#
LCOV = /usr/bin/lcov
GENHTML = /usr/bin/genhtml

cov: clean-cov
	if [ "`echo $(LDFLAGS) | grep coverage`" = "" ] ; then \
	    echo not configured with coverage; exit 1 ; fi
	if [ ! -x $(LCOV) -o ! -x $(GENHTML) ] ; then \
	    echo Need $(LCOV) and $(GENHTML) excecutables; exit 1 ; fi
	-@($(MAKE) check)
	-@(./runsuite$(EXEEXT))
	mkdir $(top_builddir)/coverage
	$(LCOV) -c -o $(top_builddir)/coverage/libxml2.info.tmp -d $(top_srcdir)
	$(LCOV) -r $(top_builddir)/coverage/libxml2.info.tmp -o $(top_builddir)/coverage/libxml2.info *usr*
	rm $(top_builddir)/coverage/libxml2.info.tmp
	$(GENHTML) -s -t "libxml2" -o $(top_builddir)/coverage --legend $(top_builddir)/coverage/libxml2.info
	echo "Coverage report is in $(top_builddir)/coverage/index.html"

clean-cov:
	rm -rf $(top_builddir)/coverage

