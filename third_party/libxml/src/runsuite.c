/*
 * runsuite.c: C program to run libxml2 againts published testsuites
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 */

#include "libxml.h"
#include <stdio.h>

#if !defined(_WIN32) || defined(__CYGWIN__)
#include <unistd.h>
#endif
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/tree.h>
#include <libxml/uri.h>
#if defined(LIBXML_SCHEMAS_ENABLED) && defined(LIBXML_XPATH_ENABLED)
#include <libxml/xmlreader.h>

#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>

#include <libxml/relaxng.h>
#include <libxml/xmlschemas.h>
#include <libxml/xmlschemastypes.h>

#define LOGFILE "runsuite.log"
static FILE *logfile = NULL;
static int verbose = 0;


/************************************************************************
 *									*
 *		File name and path utilities				*
 *									*
 ************************************************************************/

static int checkTestFile(const char *filename) {
    struct stat buf;

    if (stat(filename, &buf) == -1)
        return(0);

#if defined(_WIN32) && !defined(__CYGWIN__)
    if (!(buf.st_mode & _S_IFREG))
        return(0);
#else
    if (!S_ISREG(buf.st_mode))
        return(0);
#endif

    return(1);
}

static xmlChar *composeDir(const xmlChar *dir, const xmlChar *path) {
    char buf[500];

    if (dir == NULL) return(xmlStrdup(path));
    if (path == NULL) return(NULL);

    snprintf(buf, 500, "%s/%s", (const char *) dir, (const char *) path);
    return(xmlStrdup((const xmlChar *) buf));
}

/************************************************************************
 *									*
 *		Libxml2 specific routines				*
 *									*
 ************************************************************************/

static int nb_tests = 0;
static int nb_errors = 0;
static int nb_internals = 0;
static int nb_schematas = 0;
static int nb_unimplemented = 0;
static int nb_leaks = 0;
static int extraMemoryFromResolver = 0;

static int
fatalError(void) {
    fprintf(stderr, "Exitting tests on fatal error\n");
    exit(1);
}

/*
 * that's needed to implement <resource>
 */
#define MAX_ENTITIES 20
static char *testEntitiesName[MAX_ENTITIES];
static char *testEntitiesValue[MAX_ENTITIES];
static int nb_entities = 0;
static void resetEntities(void) {
    int i;

    for (i = 0;i < nb_entities;i++) {
        if (testEntitiesName[i] != NULL)
	    xmlFree(testEntitiesName[i]);
        if (testEntitiesValue[i] != NULL)
	    xmlFree(testEntitiesValue[i]);
    }
    nb_entities = 0;
}
static int addEntity(char *name, char *content) {
    if (nb_entities >= MAX_ENTITIES) {
	fprintf(stderr, "Too many entities defined\n");
	return(-1);
    }
    testEntitiesName[nb_entities] = name;
    testEntitiesValue[nb_entities] = content;
    nb_entities++;
    return(0);
}

/*
 * We need to trap calls to the resolver to not account memory for the catalog
 * which is shared to the current running test. We also don't want to have
 * network downloads modifying tests.
 */
static xmlParserInputPtr
testExternalEntityLoader(const char *URL, const char *ID,
			 xmlParserCtxtPtr ctxt) {
    xmlParserInputPtr ret;
    int i;

    for (i = 0;i < nb_entities;i++) {
        if (!strcmp(testEntitiesName[i], URL)) {
	    ret = xmlNewStringInputStream(ctxt,
	                (const xmlChar *) testEntitiesValue[i]);
	    if (ret != NULL) {
	        ret->filename = (const char *)
		                xmlStrdup((xmlChar *)testEntitiesName[i]);
	    }
	    return(ret);
	}
    }
    if (checkTestFile(URL)) {
	ret = xmlNoNetExternalEntityLoader(URL, ID, ctxt);
    } else {
	int memused = xmlMemUsed();
	ret = xmlNoNetExternalEntityLoader(URL, ID, ctxt);
	extraMemoryFromResolver += xmlMemUsed() - memused;
    }
#if 0
    if (ret == NULL) {
        fprintf(stderr, "Failed to find resource %s\n", URL);
    }
#endif

    return(ret);
}

/*
 * Trapping the error messages at the generic level to grab the equivalent of
 * stderr messages on CLI tools.
 */
static char testErrors[32769];
static int testErrorsSize = 0;

static void test_log(const char *msg, ...) {
    va_list args;
    if (logfile != NULL) {
        fprintf(logfile, "\n------------\n");
	va_start(args, msg);
	vfprintf(logfile, msg, args);
	va_end(args);
	fprintf(logfile, "%s", testErrors);
	testErrorsSize = 0; testErrors[0] = 0;
    }
    if (verbose) {
	va_start(args, msg);
	vfprintf(stderr, msg, args);
	va_end(args);
    }
}

static void
testErrorHandler(void *ctx  ATTRIBUTE_UNUSED, const char *msg, ...) {
    va_list args;
    int res;

    if (testErrorsSize >= 32768)
        return;
    va_start(args, msg);
    res = vsnprintf(&testErrors[testErrorsSize],
                    32768 - testErrorsSize,
		    msg, args);
    va_end(args);
    if (testErrorsSize + res >= 32768) {
        /* buffer is full */
	testErrorsSize = 32768;
	testErrors[testErrorsSize] = 0;
    } else {
        testErrorsSize += res;
    }
    testErrors[testErrorsSize] = 0;
}

static xmlXPathContextPtr ctxtXPath;

static void
initializeLibxml2(void) {
    xmlGetWarningsDefaultValue = 0;
    xmlPedanticParserDefault(0);

    xmlMemSetup(xmlMemFree, xmlMemMalloc, xmlMemRealloc, xmlMemoryStrdup);
    xmlInitParser();
    xmlSetExternalEntityLoader(testExternalEntityLoader);
    ctxtXPath = xmlXPathNewContext(NULL);
    /*
    * Deactivate the cache if created; otherwise we have to create/free it
    * for every test, since it will confuse the memory leak detection.
    * Note that normally this need not be done, since the cache is not
    * created until set explicitely with xmlXPathContextSetCache();
    * but for test purposes it is sometimes usefull to activate the
    * cache by default for the whole library.
    */
    if (ctxtXPath->cache != NULL)
	xmlXPathContextSetCache(ctxtXPath, 0, -1, 0);
    /* used as default nanemspace in xstc tests */
    xmlXPathRegisterNs(ctxtXPath, BAD_CAST "ts", BAD_CAST "TestSuite");
    xmlXPathRegisterNs(ctxtXPath, BAD_CAST "xlink",
                       BAD_CAST "http://www.w3.org/1999/xlink");
    xmlSetGenericErrorFunc(NULL, testErrorHandler);
#ifdef LIBXML_SCHEMAS_ENABLED
    xmlSchemaInitTypes();
    xmlRelaxNGInitTypes();
#endif
}

static xmlNodePtr
getNext(xmlNodePtr cur, const char *xpath) {
    xmlNodePtr ret = NULL;
    xmlXPathObjectPtr res;
    xmlXPathCompExprPtr comp;

    if ((cur == NULL)  || (cur->doc == NULL) || (xpath == NULL))
        return(NULL);
    ctxtXPath->doc = cur->doc;
    ctxtXPath->node = cur;
    comp = xmlXPathCompile(BAD_CAST xpath);
    if (comp == NULL) {
        fprintf(stderr, "Failed to compile %s\n", xpath);
	return(NULL);
    }
    res = xmlXPathCompiledEval(comp, ctxtXPath);
    xmlXPathFreeCompExpr(comp);
    if (res == NULL)
        return(NULL);
    if ((res->type == XPATH_NODESET) &&
        (res->nodesetval != NULL) &&
	(res->nodesetval->nodeNr > 0) &&
	(res->nodesetval->nodeTab != NULL))
	ret = res->nodesetval->nodeTab[0];
    xmlXPathFreeObject(res);
    return(ret);
}

static xmlChar *
getString(xmlNodePtr cur, const char *xpath) {
    xmlChar *ret = NULL;
    xmlXPathObjectPtr res;
    xmlXPathCompExprPtr comp;

    if ((cur == NULL)  || (cur->doc == NULL) || (xpath == NULL))
        return(NULL);
    ctxtXPath->doc = cur->doc;
    ctxtXPath->node = cur;
    comp = xmlXPathCompile(BAD_CAST xpath);
    if (comp == NULL) {
        fprintf(stderr, "Failed to compile %s\n", xpath);
	return(NULL);
    }
    res = xmlXPathCompiledEval(comp, ctxtXPath);
    xmlXPathFreeCompExpr(comp);
    if (res == NULL)
        return(NULL);
    if (res->type == XPATH_STRING) {
        ret = res->stringval;
	res->stringval = NULL;
    }
    xmlXPathFreeObject(res);
    return(ret);
}

/************************************************************************
 *									*
 *		Test test/xsdtest/xsdtestsuite.xml			*
 *									*
 ************************************************************************/

static int
xsdIncorectTestCase(xmlNodePtr cur) {
    xmlNodePtr test;
    xmlBufferPtr buf;
    xmlRelaxNGParserCtxtPtr pctxt;
    xmlRelaxNGPtr rng = NULL;
    int ret = 0, memt;

    cur = getNext(cur, "./incorrect[1]");
    if (cur == NULL) {
        return(0);
    }

    test = getNext(cur, "./*");
    if (test == NULL) {
        test_log("Failed to find test in correct line %ld\n",
	        xmlGetLineNo(cur));
        return(1);
    }

    memt = xmlMemUsed();
    extraMemoryFromResolver = 0;
    /*
     * dump the schemas to a buffer, then reparse it and compile the schemas
     */
    buf = xmlBufferCreate();
    if (buf == NULL) {
        fprintf(stderr, "out of memory !\n");
	fatalError();
    }
    xmlNodeDump(buf, test->doc, test, 0, 0);
    pctxt = xmlRelaxNGNewMemParserCtxt((const char *)buf->content, buf->use);
    xmlRelaxNGSetParserErrors(pctxt,
         (xmlRelaxNGValidityErrorFunc) testErrorHandler,
         (xmlRelaxNGValidityWarningFunc) testErrorHandler,
	 pctxt);
    rng = xmlRelaxNGParse(pctxt);
    xmlRelaxNGFreeParserCtxt(pctxt);
    if (rng != NULL) {
	test_log("Failed to detect incorect RNG line %ld\n",
		    xmlGetLineNo(test));
        ret = 1;
	goto done;
    }

done:
    if (buf != NULL)
	xmlBufferFree(buf);
    if (rng != NULL)
        xmlRelaxNGFree(rng);
    xmlResetLastError();
    if ((memt < xmlMemUsed()) && (extraMemoryFromResolver == 0)) {
	test_log("Validation of tests starting line %ld leaked %d\n",
		xmlGetLineNo(cur), xmlMemUsed() - memt);
	nb_leaks++;
    }
    return(ret);
}

static void
installResources(xmlNodePtr tst, const xmlChar *base) {
    xmlNodePtr test;
    xmlBufferPtr buf;
    xmlChar *name, *content, *res;

    buf = xmlBufferCreate();
    if (buf == NULL) {
        fprintf(stderr, "out of memory !\n");
	fatalError();
    }
    xmlNodeDump(buf, tst->doc, tst, 0, 0);

    while (tst != NULL) {
	test = getNext(tst, "./*");
	if (test != NULL) {
	    xmlBufferEmpty(buf);
	    xmlNodeDump(buf, test->doc, test, 0, 0);
	    name = getString(tst, "string(@name)");
	    content = xmlStrdup(buf->content);
	    if ((name != NULL) && (content != NULL)) {
	        res = composeDir(base, name);
		xmlFree(name);
	        addEntity((char *) res, (char *) content);
	    } else {
	        if (name != NULL) xmlFree(name);
	        if (content != NULL) xmlFree(content);
	    }
	}
	tst = getNext(tst, "following-sibling::resource[1]");
    }
    if (buf != NULL)
	xmlBufferFree(buf);
}

static void
installDirs(xmlNodePtr tst, const xmlChar *base) {
    xmlNodePtr test;
    xmlChar *name, *res;

    name = getString(tst, "string(@name)");
    if (name == NULL)
        return;
    res = composeDir(base, name);
    xmlFree(name);
    if (res == NULL) {
	return;
    }
    /* Now process resources and subdir recursively */
    test = getNext(tst, "./resource[1]");
    if (test != NULL) {
        installResources(test, res);
    }
    test = getNext(tst, "./dir[1]");
    while (test != NULL) {
        installDirs(test, res);
	test = getNext(test, "following-sibling::dir[1]");
    }
    xmlFree(res);
}

static int
xsdTestCase(xmlNodePtr tst) {
    xmlNodePtr test, tmp, cur;
    xmlBufferPtr buf;
    xmlDocPtr doc = NULL;
    xmlRelaxNGParserCtxtPtr pctxt;
    xmlRelaxNGValidCtxtPtr ctxt;
    xmlRelaxNGPtr rng = NULL;
    int ret = 0, mem, memt;
    xmlChar *dtd;

    resetEntities();
    testErrorsSize = 0; testErrors[0] = 0;

    tmp = getNext(tst, "./dir[1]");
    if (tmp != NULL) {
        installDirs(tmp, NULL);
    }
    tmp = getNext(tst, "./resource[1]");
    if (tmp != NULL) {
        installResources(tmp, NULL);
    }

    cur = getNext(tst, "./correct[1]");
    if (cur == NULL) {
        return(xsdIncorectTestCase(tst));
    }

    test = getNext(cur, "./*");
    if (test == NULL) {
        fprintf(stderr, "Failed to find test in correct line %ld\n",
	        xmlGetLineNo(cur));
        return(1);
    }

    memt = xmlMemUsed();
    extraMemoryFromResolver = 0;
    /*
     * dump the schemas to a buffer, then reparse it and compile the schemas
     */
    buf = xmlBufferCreate();
    if (buf == NULL) {
        fprintf(stderr, "out of memory !\n");
	fatalError();
    }
    xmlNodeDump(buf, test->doc, test, 0, 0);
    pctxt = xmlRelaxNGNewMemParserCtxt((const char *)buf->content, buf->use);
    xmlRelaxNGSetParserErrors(pctxt,
         (xmlRelaxNGValidityErrorFunc) testErrorHandler,
         (xmlRelaxNGValidityWarningFunc) testErrorHandler,
	 pctxt);
    rng = xmlRelaxNGParse(pctxt);
    xmlRelaxNGFreeParserCtxt(pctxt);
    if (extraMemoryFromResolver)
        memt = 0;

    if (rng == NULL) {
        test_log("Failed to parse RNGtest line %ld\n",
	        xmlGetLineNo(test));
	nb_errors++;
        ret = 1;
	goto done;
    }
    /*
     * now scan all the siblings of correct to process the <valid> tests
     */
    tmp = getNext(cur, "following-sibling::valid[1]");
    while (tmp != NULL) {
	dtd = xmlGetProp(tmp, BAD_CAST "dtd");
	test = getNext(tmp, "./*");
	if (test == NULL) {
	    fprintf(stderr, "Failed to find test in <valid> line %ld\n",
		    xmlGetLineNo(tmp));

	} else {
	    xmlBufferEmpty(buf);
	    if (dtd != NULL)
		xmlBufferAdd(buf, dtd, -1);
	    xmlNodeDump(buf, test->doc, test, 0, 0);

	    /*
	     * We are ready to run the test
	     */
	    mem = xmlMemUsed();
	    extraMemoryFromResolver = 0;
            doc = xmlReadMemory((const char *)buf->content, buf->use,
	                        "test", NULL, 0);
	    if (doc == NULL) {
		test_log("Failed to parse valid instance line %ld\n",
			xmlGetLineNo(tmp));
		nb_errors++;
	    } else {
		nb_tests++;
	        ctxt = xmlRelaxNGNewValidCtxt(rng);
		xmlRelaxNGSetValidErrors(ctxt,
		     (xmlRelaxNGValidityErrorFunc) testErrorHandler,
		     (xmlRelaxNGValidityWarningFunc) testErrorHandler,
		     ctxt);
		ret = xmlRelaxNGValidateDoc(ctxt, doc);
		xmlRelaxNGFreeValidCtxt(ctxt);
		if (ret > 0) {
		    test_log("Failed to validate valid instance line %ld\n",
				xmlGetLineNo(tmp));
		    nb_errors++;
		} else if (ret < 0) {
		    test_log("Internal error validating instance line %ld\n",
			    xmlGetLineNo(tmp));
		    nb_errors++;
		}
		xmlFreeDoc(doc);
	    }
	    xmlResetLastError();
	    if ((mem != xmlMemUsed()) && (extraMemoryFromResolver == 0)) {
	        test_log("Validation of instance line %ld leaked %d\n",
		        xmlGetLineNo(tmp), xmlMemUsed() - mem);
		xmlMemoryDump();
	        nb_leaks++;
	    }
	}
	if (dtd != NULL)
	    xmlFree(dtd);
	tmp = getNext(tmp, "following-sibling::valid[1]");
    }
    /*
     * now scan all the siblings of correct to process the <invalid> tests
     */
    tmp = getNext(cur, "following-sibling::invalid[1]");
    while (tmp != NULL) {
	test = getNext(tmp, "./*");
	if (test == NULL) {
	    fprintf(stderr, "Failed to find test in <invalid> line %ld\n",
		    xmlGetLineNo(tmp));

	} else {
	    xmlBufferEmpty(buf);
	    xmlNodeDump(buf, test->doc, test, 0, 0);

	    /*
	     * We are ready to run the test
	     */
	    mem = xmlMemUsed();
	    extraMemoryFromResolver = 0;
            doc = xmlReadMemory((const char *)buf->content, buf->use,
	                        "test", NULL, 0);
	    if (doc == NULL) {
		test_log("Failed to parse valid instance line %ld\n",
			xmlGetLineNo(tmp));
		nb_errors++;
	    } else {
		nb_tests++;
	        ctxt = xmlRelaxNGNewValidCtxt(rng);
		xmlRelaxNGSetValidErrors(ctxt,
		     (xmlRelaxNGValidityErrorFunc) testErrorHandler,
		     (xmlRelaxNGValidityWarningFunc) testErrorHandler,
		     ctxt);
		ret = xmlRelaxNGValidateDoc(ctxt, doc);
		xmlRelaxNGFreeValidCtxt(ctxt);
		if (ret == 0) {
		    test_log("Failed to detect invalid instance line %ld\n",
				xmlGetLineNo(tmp));
		    nb_errors++;
		} else if (ret < 0) {
		    test_log("Internal error validating instance line %ld\n",
			    xmlGetLineNo(tmp));
		    nb_errors++;
		}
		xmlFreeDoc(doc);
	    }
	    xmlResetLastError();
	    if ((mem != xmlMemUsed()) && (extraMemoryFromResolver == 0)) {
	        test_log("Validation of instance line %ld leaked %d\n",
		        xmlGetLineNo(tmp), xmlMemUsed() - mem);
		xmlMemoryDump();
	        nb_leaks++;
	    }
	}
	tmp = getNext(tmp, "following-sibling::invalid[1]");
    }

done:
    if (buf != NULL)
	xmlBufferFree(buf);
    if (rng != NULL)
        xmlRelaxNGFree(rng);
    xmlResetLastError();
    if ((memt != xmlMemUsed()) && (memt != 0)) {
	test_log("Validation of tests starting line %ld leaked %d\n",
		xmlGetLineNo(cur), xmlMemUsed() - memt);
	nb_leaks++;
    }
    return(ret);
}

static int
xsdTestSuite(xmlNodePtr cur) {
    if (verbose) {
	xmlChar *doc = getString(cur, "string(documentation)");

	if (doc != NULL) {
	    printf("Suite %s\n", doc);
	    xmlFree(doc);
	}
    }
    cur = getNext(cur, "./testCase[1]");
    while (cur != NULL) {
        xsdTestCase(cur);
	cur = getNext(cur, "following-sibling::testCase[1]");
    }

    return(0);
}

static int
xsdTest(void) {
    xmlDocPtr doc;
    xmlNodePtr cur;
    const char *filename = "test/xsdtest/xsdtestsuite.xml";
    int ret = 0;

    doc = xmlReadFile(filename, NULL, XML_PARSE_NOENT);
    if (doc == NULL) {
        fprintf(stderr, "Failed to parse %s\n", filename);
	return(-1);
    }
    printf("## XML Schemas datatypes test suite from James Clark\n");

    cur = xmlDocGetRootElement(doc);
    if ((cur == NULL) || (!xmlStrEqual(cur->name, BAD_CAST "testSuite"))) {
        fprintf(stderr, "Unexpected format %s\n", filename);
	ret = -1;
	goto done;
    }

    cur = getNext(cur, "./testSuite[1]");
    if ((cur == NULL) || (!xmlStrEqual(cur->name, BAD_CAST "testSuite"))) {
        fprintf(stderr, "Unexpected format %s\n", filename);
	ret = -1;
	goto done;
    }
    while (cur != NULL) {
        xsdTestSuite(cur);
	cur = getNext(cur, "following-sibling::testSuite[1]");
    }

done:
    if (doc != NULL)
	xmlFreeDoc(doc);
    return(ret);
}

static int
rngTestSuite(xmlNodePtr cur) {
    if (verbose) {
	xmlChar *doc = getString(cur, "string(documentation)");

	if (doc != NULL) {
	    printf("Suite %s\n", doc);
	    xmlFree(doc);
	} else {
	    doc = getString(cur, "string(section)");
	    if (doc != NULL) {
		printf("Section %s\n", doc);
		xmlFree(doc);
	    }
	}
    }
    cur = getNext(cur, "./testSuite[1]");
    while (cur != NULL) {
        xsdTestSuite(cur);
	cur = getNext(cur, "following-sibling::testSuite[1]");
    }

    return(0);
}

static int
rngTest1(void) {
    xmlDocPtr doc;
    xmlNodePtr cur;
    const char *filename = "test/relaxng/OASIS/spectest.xml";
    int ret = 0;

    doc = xmlReadFile(filename, NULL, XML_PARSE_NOENT);
    if (doc == NULL) {
        fprintf(stderr, "Failed to parse %s\n", filename);
	return(-1);
    }
    printf("## Relax NG test suite from James Clark\n");

    cur = xmlDocGetRootElement(doc);
    if ((cur == NULL) || (!xmlStrEqual(cur->name, BAD_CAST "testSuite"))) {
        fprintf(stderr, "Unexpected format %s\n", filename);
	ret = -1;
	goto done;
    }

    cur = getNext(cur, "./testSuite[1]");
    if ((cur == NULL) || (!xmlStrEqual(cur->name, BAD_CAST "testSuite"))) {
        fprintf(stderr, "Unexpected format %s\n", filename);
	ret = -1;
	goto done;
    }
    while (cur != NULL) {
        rngTestSuite(cur);
	cur = getNext(cur, "following-sibling::testSuite[1]");
    }

done:
    if (doc != NULL)
	xmlFreeDoc(doc);
    return(ret);
}

static int
rngTest2(void) {
    xmlDocPtr doc;
    xmlNodePtr cur;
    const char *filename = "test/relaxng/testsuite.xml";
    int ret = 0;

    doc = xmlReadFile(filename, NULL, XML_PARSE_NOENT);
    if (doc == NULL) {
        fprintf(stderr, "Failed to parse %s\n", filename);
	return(-1);
    }
    printf("## Relax NG test suite for libxml2\n");

    cur = xmlDocGetRootElement(doc);
    if ((cur == NULL) || (!xmlStrEqual(cur->name, BAD_CAST "testSuite"))) {
        fprintf(stderr, "Unexpected format %s\n", filename);
	ret = -1;
	goto done;
    }

    cur = getNext(cur, "./testSuite[1]");
    if ((cur == NULL) || (!xmlStrEqual(cur->name, BAD_CAST "testSuite"))) {
        fprintf(stderr, "Unexpected format %s\n", filename);
	ret = -1;
	goto done;
    }
    while (cur != NULL) {
        xsdTestSuite(cur);
	cur = getNext(cur, "following-sibling::testSuite[1]");
    }

done:
    if (doc != NULL)
	xmlFreeDoc(doc);
    return(ret);
}

/************************************************************************
 *									*
 *		Schemas test suites from W3C/NIST/MS/Sun		*
 *									*
 ************************************************************************/

static int
xstcTestInstance(xmlNodePtr cur, xmlSchemaPtr schemas,
                 const xmlChar *spath, const char *base) {
    xmlChar *href = NULL;
    xmlChar *path = NULL;
    xmlChar *validity = NULL;
    xmlSchemaValidCtxtPtr ctxt = NULL;
    xmlDocPtr doc = NULL;
    int ret = 0, mem;

    xmlResetLastError();
    testErrorsSize = 0; testErrors[0] = 0;
    mem = xmlMemUsed();
    href = getString(cur,
                     "string(ts:instanceDocument/@xlink:href)");
    if ((href == NULL) || (href[0] == 0)) {
	test_log("testGroup line %ld misses href for schemaDocument\n",
		    xmlGetLineNo(cur));
	ret = -1;
	goto done;
    }
    path = xmlBuildURI(href, BAD_CAST base);
    if (path == NULL) {
	fprintf(stderr,
	        "Failed to build path to schemas testGroup line %ld : %s\n",
		xmlGetLineNo(cur), href);
	ret = -1;
	goto done;
    }
    if (checkTestFile((const char *) path) <= 0) {
	test_log("schemas for testGroup line %ld is missing: %s\n",
		xmlGetLineNo(cur), path);
	ret = -1;
	goto done;
    }
    validity = getString(cur,
                         "string(ts:expected/@validity)");
    if (validity == NULL) {
        fprintf(stderr, "instanceDocument line %ld misses expected validity\n",
	        xmlGetLineNo(cur));
	ret = -1;
	goto done;
    }
    nb_tests++;
    doc = xmlReadFile((const char *) path, NULL, XML_PARSE_NOENT);
    if (doc == NULL) {
        fprintf(stderr, "instance %s fails to parse\n", path);
	ret = -1;
	nb_errors++;
	goto done;
    }

    ctxt = xmlSchemaNewValidCtxt(schemas);
    xmlSchemaSetValidErrors(ctxt,
         (xmlSchemaValidityErrorFunc) testErrorHandler,
         (xmlSchemaValidityWarningFunc) testErrorHandler,
	 ctxt);
    ret = xmlSchemaValidateDoc(ctxt, doc);

    if (xmlStrEqual(validity, BAD_CAST "valid")) {
	if (ret > 0) {
	    test_log("valid instance %s failed to validate against %s\n",
			path, spath);
	    nb_errors++;
	} else if (ret < 0) {
	    test_log("valid instance %s got internal error validating %s\n",
			path, spath);
	    nb_internals++;
	    nb_errors++;
	}
    } else if (xmlStrEqual(validity, BAD_CAST "invalid")) {
	if (ret == 0) {
	    test_log("Failed to detect invalid instance %s against %s\n",
			path, spath);
	    nb_errors++;
	}
    } else {
        test_log("instanceDocument line %ld has unexpected validity value%s\n",
	        xmlGetLineNo(cur), validity);
	ret = -1;
	goto done;
    }

done:
    if (href != NULL) xmlFree(href);
    if (path != NULL) xmlFree(path);
    if (validity != NULL) xmlFree(validity);
    if (ctxt != NULL) xmlSchemaFreeValidCtxt(ctxt);
    if (doc != NULL) xmlFreeDoc(doc);
    xmlResetLastError();
    if (mem != xmlMemUsed()) {
	test_log("Validation of tests starting line %ld leaked %d\n",
		xmlGetLineNo(cur), xmlMemUsed() - mem);
	nb_leaks++;
    }
    return(ret);
}

static int
xstcTestGroup(xmlNodePtr cur, const char *base) {
    xmlChar *href = NULL;
    xmlChar *path = NULL;
    xmlChar *validity = NULL;
    xmlSchemaPtr schemas = NULL;
    xmlSchemaParserCtxtPtr ctxt;
    xmlNodePtr instance;
    int ret = 0, mem;

    xmlResetLastError();
    testErrorsSize = 0; testErrors[0] = 0;
    mem = xmlMemUsed();
    href = getString(cur,
                     "string(ts:schemaTest/ts:schemaDocument/@xlink:href)");
    if ((href == NULL) || (href[0] == 0)) {
        test_log("testGroup line %ld misses href for schemaDocument\n",
		    xmlGetLineNo(cur));
	ret = -1;
	goto done;
    }
    path = xmlBuildURI(href, BAD_CAST base);
    if (path == NULL) {
	test_log("Failed to build path to schemas testGroup line %ld : %s\n",
		xmlGetLineNo(cur), href);
	ret = -1;
	goto done;
    }
    if (checkTestFile((const char *) path) <= 0) {
	test_log("schemas for testGroup line %ld is missing: %s\n",
		xmlGetLineNo(cur), path);
	ret = -1;
	goto done;
    }
    validity = getString(cur,
                         "string(ts:schemaTest/ts:expected/@validity)");
    if (validity == NULL) {
        test_log("testGroup line %ld misses expected validity\n",
	        xmlGetLineNo(cur));
	ret = -1;
	goto done;
    }
    nb_tests++;
    if (xmlStrEqual(validity, BAD_CAST "valid")) {
        nb_schematas++;
	ctxt = xmlSchemaNewParserCtxt((const char *) path);
	xmlSchemaSetParserErrors(ctxt,
	     (xmlSchemaValidityErrorFunc) testErrorHandler,
	     (xmlSchemaValidityWarningFunc) testErrorHandler,
	     ctxt);
	schemas = xmlSchemaParse(ctxt);
	xmlSchemaFreeParserCtxt(ctxt);
	if (schemas == NULL) {
	    test_log("valid schemas %s failed to parse\n",
			path);
	    ret = 1;
	    nb_errors++;
	}
	if ((ret == 0) && (strstr(testErrors, "nimplemented") != NULL)) {
	    test_log("valid schemas %s hit an unimplemented block\n",
			path);
	    ret = 1;
	    nb_unimplemented++;
	    nb_errors++;
	}
	instance = getNext(cur, "./ts:instanceTest[1]");
	while (instance != NULL) {
	    if (schemas != NULL) {
		xstcTestInstance(instance, schemas, path, base);
	    } else {
		/*
		* We'll automatically mark the instances as failed
		* if the schema was broken.
		*/
		nb_errors++;
	    }
	    instance = getNext(instance,
		"following-sibling::ts:instanceTest[1]");
	}
    } else if (xmlStrEqual(validity, BAD_CAST "invalid")) {
        nb_schematas++;
	ctxt = xmlSchemaNewParserCtxt((const char *) path);
	xmlSchemaSetParserErrors(ctxt,
	     (xmlSchemaValidityErrorFunc) testErrorHandler,
	     (xmlSchemaValidityWarningFunc) testErrorHandler,
	     ctxt);
	schemas = xmlSchemaParse(ctxt);
	xmlSchemaFreeParserCtxt(ctxt);
	if (schemas != NULL) {
	    test_log("Failed to detect error in schemas %s\n",
			path);
	    nb_errors++;
	    ret = 1;
	}
	if ((ret == 0) && (strstr(testErrors, "nimplemented") != NULL)) {
	    nb_unimplemented++;
	    test_log("invalid schemas %s hit an unimplemented block\n",
			path);
	    ret = 1;
	    nb_errors++;
	}
    } else {
        test_log("testGroup line %ld misses unexpected validity value%s\n",
	        xmlGetLineNo(cur), validity);
	ret = -1;
	goto done;
    }

done:
    if (href != NULL) xmlFree(href);
    if (path != NULL) xmlFree(path);
    if (validity != NULL) xmlFree(validity);
    if (schemas != NULL) xmlSchemaFree(schemas);
    xmlResetLastError();
    if ((mem != xmlMemUsed()) && (extraMemoryFromResolver == 0)) {
	test_log("Processing test line %ld %s leaked %d\n",
		xmlGetLineNo(cur), path, xmlMemUsed() - mem);
	nb_leaks++;
    }
    return(ret);
}

static int
xstcMetadata(const char *metadata, const char *base) {
    xmlDocPtr doc;
    xmlNodePtr cur;
    xmlChar *contributor;
    xmlChar *name;
    int ret = 0;

    doc = xmlReadFile(metadata, NULL, XML_PARSE_NOENT);
    if (doc == NULL) {
        fprintf(stderr, "Failed to parse %s\n", metadata);
	return(-1);
    }

    cur = xmlDocGetRootElement(doc);
    if ((cur == NULL) || (!xmlStrEqual(cur->name, BAD_CAST "testSet"))) {
        fprintf(stderr, "Unexpected format %s\n", metadata);
	return(-1);
    }
    contributor = xmlGetProp(cur, BAD_CAST "contributor");
    if (contributor == NULL) {
        contributor = xmlStrdup(BAD_CAST "Unknown");
    }
    name = xmlGetProp(cur, BAD_CAST "name");
    if (name == NULL) {
        name = xmlStrdup(BAD_CAST "Unknown");
    }
    printf("## %s test suite for Schemas version %s\n", contributor, name);
    xmlFree(contributor);
    xmlFree(name);

    cur = getNext(cur, "./ts:testGroup[1]");
    if ((cur == NULL) || (!xmlStrEqual(cur->name, BAD_CAST "testGroup"))) {
        fprintf(stderr, "Unexpected format %s\n", metadata);
	ret = -1;
	goto done;
    }
    while (cur != NULL) {
        xstcTestGroup(cur, base);
	cur = getNext(cur, "following-sibling::ts:testGroup[1]");
    }

done:
    xmlFreeDoc(doc);
    return(ret);
}

/************************************************************************
 *									*
 *		The driver for the tests				*
 *									*
 ************************************************************************/

int
main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    int ret = 0;
    int old_errors, old_tests, old_leaks;

    logfile = fopen(LOGFILE, "w");
    if (logfile == NULL) {
        fprintf(stderr,
	        "Could not open the log file, running in verbose mode\n");
	verbose = 1;
    }
    initializeLibxml2();

    if ((argc >= 2) && (!strcmp(argv[1], "-v")))
        verbose = 1;


    old_errors = nb_errors;
    old_tests = nb_tests;
    old_leaks = nb_leaks;
    xsdTest();
    if ((nb_errors == old_errors) && (nb_leaks == old_leaks))
	printf("Ran %d tests, no errors\n", nb_tests - old_tests);
    else
	printf("Ran %d tests, %d errors, %d leaks\n",
	       nb_tests - old_tests,
	       nb_errors - old_errors,
	       nb_leaks - old_leaks);
    old_errors = nb_errors;
    old_tests = nb_tests;
    old_leaks = nb_leaks;
    rngTest1();
    if ((nb_errors == old_errors) && (nb_leaks == old_leaks))
	printf("Ran %d tests, no errors\n", nb_tests - old_tests);
    else
	printf("Ran %d tests, %d errors, %d leaks\n",
	       nb_tests - old_tests,
	       nb_errors - old_errors,
	       nb_leaks - old_leaks);
    old_errors = nb_errors;
    old_tests = nb_tests;
    old_leaks = nb_leaks;
    rngTest2();
    if ((nb_errors == old_errors) && (nb_leaks == old_leaks))
	printf("Ran %d tests, no errors\n", nb_tests - old_tests);
    else
	printf("Ran %d tests, %d errors, %d leaks\n",
	       nb_tests - old_tests,
	       nb_errors - old_errors,
	       nb_leaks - old_leaks);
    old_errors = nb_errors;
    old_tests = nb_tests;
    old_leaks = nb_leaks;
    nb_internals = 0;
    nb_schematas = 0;
    xstcMetadata("xstc/Tests/Metadata/NISTXMLSchemaDatatypes.testSet",
		 "xstc/Tests/Metadata/");
    if ((nb_errors == old_errors) && (nb_leaks == old_leaks))
	printf("Ran %d tests (%d schemata), no errors\n",
	       nb_tests - old_tests, nb_schematas);
    else
	printf("Ran %d tests (%d schemata), %d errors (%d internals), %d leaks\n",
	       nb_tests - old_tests,
	       nb_schematas,
	       nb_errors - old_errors,
	       nb_internals,
	       nb_leaks - old_leaks);
    old_errors = nb_errors;
    old_tests = nb_tests;
    old_leaks = nb_leaks;
    nb_internals = 0;
    nb_schematas = 0;
    xstcMetadata("xstc/Tests/Metadata/SunXMLSchema1-0-20020116.testSet",
		 "xstc/Tests/");
    if ((nb_errors == old_errors) && (nb_leaks == old_leaks))
	printf("Ran %d tests (%d schemata), no errors\n",
	       nb_tests - old_tests, nb_schematas);
    else
	printf("Ran %d tests (%d schemata), %d errors (%d internals), %d leaks\n",
	       nb_tests - old_tests,
	       nb_schematas,
	       nb_errors - old_errors,
	       nb_internals,
	       nb_leaks - old_leaks);
    old_errors = nb_errors;
    old_tests = nb_tests;
    old_leaks = nb_leaks;
    nb_internals = 0;
    nb_schematas = 0;
    xstcMetadata("xstc/Tests/Metadata/MSXMLSchema1-0-20020116.testSet",
		 "xstc/Tests/");
    if ((nb_errors == old_errors) && (nb_leaks == old_leaks))
	printf("Ran %d tests (%d schemata), no errors\n",
	       nb_tests - old_tests, nb_schematas);
    else
	printf("Ran %d tests (%d schemata), %d errors (%d internals), %d leaks\n",
	       nb_tests - old_tests,
	       nb_schematas,
	       nb_errors - old_errors,
	       nb_internals,
	       nb_leaks - old_leaks);

    if ((nb_errors == 0) && (nb_leaks == 0)) {
        ret = 0;
	printf("Total %d tests, no errors\n",
	       nb_tests);
    } else {
        ret = 1;
	printf("Total %d tests, %d errors, %d leaks\n",
	       nb_tests, nb_errors, nb_leaks);
    }
    xmlXPathFreeContext(ctxtXPath);
    xmlCleanupParser();
    xmlMemoryDump();

    if (logfile != NULL)
        fclose(logfile);
    return(ret);
}
#else /* !SCHEMAS */
int
main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    fprintf(stderr, "runsuite requires support for schemas and xpath in libxml2\n");
}
#endif
