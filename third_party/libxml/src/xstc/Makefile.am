#
# Definition for the tests from W3C
#
PYSCRIPTS=nist-test.py ms-test.py sun-test.py
TESTDIR=Tests
TESTDIRS=$(TESTDIR)/msxsdtest $(TESTDIR)/suntest $(TESTDIR)/Datatypes
TARBALL=xsts-2002-01-16.tar.gz
TARBALL_2=xsts-2004-01-14.tar.gz
TSNAME=xmlschema2002-01-16
TSNAME_2=xmlschema2004-01-14
TARBALLURL=http://www.w3.org/XML/2004/xml-schema-test-suite/$(TSNAME)/$(TARBALL)
TARBALLURL_2=http://www.w3.org/XML/2004/xml-schema-test-suite/$(TSNAME_2)/$(TARBALL_2)
MSTESTDEF=MSXMLSchema1-0-20020116.testSet
SUNTESTDEF=SunXMLSchema1-0-20020116.testSet
NISTTESTDEF=NISTXMLSchema1-0-20020116.testSet
NISTTESTDEF_2=NISTXMLSchemaDatatypes.testSet

#
# The local data and scripts
#
EXTRA_DIST=xstc.py xstc-to-python.xsl
#
# Nothing is done by make, only make tests and
# only if Python and Schemas are enabled.
#
all:

#
# Rule to load the test description and extract the informations
#
$(TESTDIRS) Tests/Metadata/$(NISTTESTDEF_2) Tests/Metadata/$(MSTTESTDEF) Tests/Metadata/$(SUNTESTDEF):
	-@(if [ ! -d Tests ] ; then \
	   mkdir Tests ; \
	   fi)
	-@(if [ ! -f $(TARBALL_2) ] ; then \
	   if [ -f $(srcdir)/$(TARBALL_2) ] ; then \
	   $(LN_S) $(srcdir)/$(TARBALL_2) $(TARBALL_2) ; else \
	   echo "Missing the test suite description (2004-01-14), trying to fetch it" ;\
	   if [ -x "$(WGET)" ] ; then \
	   $(WGET) $(TARBALLURL_2) ; \
	   else echo "Dont' know how to fetch $(TARBALLURL_2)" ; fi ; fi ; fi)
	-@(if [ -f $(TARBALL_2) ] ; then \
	   echo -n "extracting test data (NIST)..." ; \
	   $(TAR) -xzf $(TARBALL_2) --wildcards '*/Datatypes' '*/Metadata/$(NISTTESTDEF_2)' ; \
	   echo "done" ; \
	   fi)
	-@(if [ ! -f $(TARBALL) ] ; then \
	   if [ -f $(srcdir)/$(TARBALL) ] ; then \
	   $(LN_S) $(srcdir)/$(TARBALL) $(TARBALL) ; else \
	   echo "Missing the test suite description (2002-01-16), trying to fetch it" ;\
	   if [ -x "$(WGET)" ] ; then \
	   $(WGET) $(TARBALLURL) ; \
	   else echo "Dont' know how to fetch $(TARBALLURL)" ; fi ; fi ; fi)
	-@(if [ -f $(TARBALL) ] ; then \
	   echo -n "extracting test data (Sun, Microsoft)..." ; \
	   $(TAR) -C Tests -xzf $(TARBALL) --wildcards '*/suntest' '*/msxsdtest' '*/$(MSTESTDEF)' '*/$(SUNTESTDEF)' ; \
	   if [ -d Tests/suntest ] ; then rm -r Tests/suntest ; fi ; \
	   if [ -d Tests/msxsdtest ] ; then rm -r Tests/msxsdtest ; fi ; \
	   mv Tests/xmlschema2002-01-16/* Tests ; \
	   mv Tests/*.testSet Tests/Metadata ; \
	   rm -r Tests/xmlschema2002-01-16 ; \
	   echo "done" ; \
	   fi)

#
# The python tests are generated via XSLT
#
nist-test.py: Tests/Metadata/$(NISTTESTDEF_2) xstc-to-python.xsl
	-@(if [ -x $(XSLTPROC) ] ; then \
	  echo "Rebuilding script (NIST)" $@ ; \
	  $(XSLTPROC) --nonet --stringparam vendor NIST-2 \
	                     $(srcdir)/xstc-to-python.xsl \
	                     $(srcdir)/Tests/Metadata/$(NISTTESTDEF_2) > $@ ; \
	  chmod +x $@ ; fi )

ms-test.py: Tests/Metadata/$(MSTTESTDEF) xstc-to-python.xsl
	-@(if [ -x $(XSLTPROC) ] ; then \
	  echo "Rebuilding script (Microsoft)" $@ ; \
	  $(XSLTPROC) --nonet --stringparam vendor MS \
	                     $(srcdir)/xstc-to-python.xsl \
	                     $(srcdir)/Tests/Metadata/$(MSTESTDEF) > $@ ; \
	  chmod +x $@ ; fi )

sun-test.py: Tests/Metadata/$(SUNTESTDEF) xstc-to-python.xsl
	-@(if [ -x $(XSLTPROC) ] ; then \
	  echo "Rebuilding script (Sun)" $@ ; \
	  $(XSLTPROC) --nonet --stringparam vendor SUN \
	                     $(srcdir)/xstc-to-python.xsl \
	                     $(srcdir)/Tests/Metadata/$(SUNTESTDEF) > $@ ; \
	  chmod +x $@ ; fi )

#
# The actual test run if present. PYTHONPATH is updated to make sure
# we run the version from the loacl build and not preinstalled bindings
#
pytests: $(PYSCRIPTS) $(TESTDIRS)
	-@(if [ -x nist-test.py -a -d $(TESTDIR)/Datatypes ] ; then 		\
	   echo "## Running XML Schema tests (NIST)";			\
	   PYTHONPATH="../python:../python/.libs:..:../.libs:$$PYTHONPATH" ;\
	   export PYTHONPATH;						\
	   LD_LIBRARY_PATH="$(top_builddir)/.libs:$$LD_LIBRARY_PATH" ;	\
	   export LD_LIBRARY_PATH;					\
	   $(CHECKER) $(PYTHON) nist-test.py -s -b $(srcdir) ; fi)
	-@(if [ -x sun-test.py -a -d $(TESTDIR)/suntest ] ; then 			\
	   echo "## Running Schema tests (Sun)";				\
	   PYTHONPATH="../python:../python/.libs:..:../.libs:$$PYTHONPATH" ;\
	   export PYTHONPATH;						\
	   LD_LIBRARY_PATH="$(top_builddir)/.libs:$$LD_LIBRARY_PATH" ;	\
	   export LD_LIBRARY_PATH;					\
	   $(CHECKER) $(PYTHON) sun-test.py -s -b $(srcdir) ; fi)
	-@(if [ -x ms-test.py -a -d $(TESTDIR)/msxsdtest ] ; then 			\
	   echo "## Running Schema tests (Microsoft)";			\
	   PYTHONPATH="../python:../python/.libs:..:../.libs:$$PYTHONPATH" ;\
	   export PYTHONPATH;						\
	   LD_LIBRARY_PATH="$(top_builddir)/.libs:$$LD_LIBRARY_PATH" ;	\
	   export LD_LIBRARY_PATH;					\
	   $(CHECKER) $(PYTHON) ms-test.py -s -b $(srcdir) ; fi)

tests:
	-@(if [ -x $(PYTHON) ] ; then 					\
	   $(MAKE) pytests ; fi);

#
# Heavy, works well only on RHEL3
#
valgrind:
	-@(if [ -x $(PYTHON) ] ; then 					\
	   echo '## Running the regression tests under Valgrind' ;	\
	   $(MAKE) CHECKER='valgrind -q' pytests ; fi);

CLEANFILES=$(PYSCRIPTS) test.log

