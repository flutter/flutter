/*
 * runsuite.c: C program to run libxml2 againts published testsuites
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 */

#include "libxml.h"
#include <stdio.h>

#ifdef LIBXML_XPATH_ENABLED

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
#include <libxml/xmlreader.h>

#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>

#define LOGFILE "runxmlconf.log"
static FILE *logfile = NULL;
static int verbose = 0;

#define NB_EXPECTED_ERRORS 15


const char *skipped_tests[] = {
/* http://lists.w3.org/Archives/Public/public-xml-testsuite/2008Jul/0000.html */
    "rmt-ns10-035",
    NULL
};

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

static int nb_skipped = 0;
static int nb_tests = 0;
static int nb_errors = 0;
static int nb_leaks = 0;

/*
 * We need to trap calls to the resolver to not account memory for the catalog
 * and not rely on any external resources.
 */
static xmlParserInputPtr
testExternalEntityLoader(const char *URL, const char *ID ATTRIBUTE_UNUSED,
			 xmlParserCtxtPtr ctxt) {
    xmlParserInputPtr ret;

    ret = xmlNewInputFromFile(ctxt, (const char *) URL);

    return(ret);
}

/*
 * Trapping the error messages at the generic level to grab the equivalent of
 * stderr messages on CLI tools.
 */
static char testErrors[32769];
static int testErrorsSize = 0;
static int nbError = 0;
static int nbFatal = 0;

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
testErrorHandler(void *userData ATTRIBUTE_UNUSED, xmlErrorPtr error) {
    int res;

    if (testErrorsSize >= 32768)
        return;
    res = snprintf(&testErrors[testErrorsSize],
                    32768 - testErrorsSize,
		   "%s:%d: %s\n", (error->file ? error->file : "entity"),
		   error->line, error->message);
    if (error->level == XML_ERR_FATAL)
        nbFatal++;
    else if (error->level == XML_ERR_ERROR)
        nbError++;
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
    xmlSetStructuredErrorFunc(NULL, testErrorHandler);
}

/************************************************************************
 *									*
 *		Run the xmlconf test if found				*
 *									*
 ************************************************************************/

static int
xmlconfTestInvalid(const char *id, const char *filename, int options) {
    xmlDocPtr doc;
    xmlParserCtxtPtr ctxt;
    int ret = 1;

    ctxt = xmlNewParserCtxt();
    if (ctxt == NULL) {
        test_log("test %s : %s out of memory\n",
	         id, filename);
        return(0);
    }
    doc = xmlCtxtReadFile(ctxt, filename, NULL, options);
    if (doc == NULL) {
        test_log("test %s : %s invalid document turned not well-formed too\n",
	         id, filename);
    } else {
    /* invalidity should be reported both in the context and in the document */
        if ((ctxt->valid != 0) || (doc->properties & XML_DOC_DTDVALID)) {
	    test_log("test %s : %s failed to detect invalid document\n",
		     id, filename);
	    nb_errors++;
	    ret = 0;
	}
	xmlFreeDoc(doc);
    }
    xmlFreeParserCtxt(ctxt);
    return(ret);
}

static int
xmlconfTestValid(const char *id, const char *filename, int options) {
    xmlDocPtr doc;
    xmlParserCtxtPtr ctxt;
    int ret = 1;

    ctxt = xmlNewParserCtxt();
    if (ctxt == NULL) {
        test_log("test %s : %s out of memory\n",
	         id, filename);
        return(0);
    }
    doc = xmlCtxtReadFile(ctxt, filename, NULL, options);
    if (doc == NULL) {
        test_log("test %s : %s failed to parse a valid document\n",
	         id, filename);
        nb_errors++;
	ret = 0;
    } else {
    /* validity should be reported both in the context and in the document */
        if ((ctxt->valid == 0) || ((doc->properties & XML_DOC_DTDVALID) == 0)) {
	    test_log("test %s : %s failed to validate a valid document\n",
		     id, filename);
	    nb_errors++;
	    ret = 0;
	}
	xmlFreeDoc(doc);
    }
    xmlFreeParserCtxt(ctxt);
    return(ret);
}

static int
xmlconfTestNotNSWF(const char *id, const char *filename, int options) {
    xmlDocPtr doc;
    int ret = 1;

    /*
     * In case of Namespace errors, libxml2 will still parse the document
     * but log a Namesapce error.
     */
    doc = xmlReadFile(filename, NULL, options);
    if (doc == NULL) {
        test_log("test %s : %s failed to parse the XML\n",
	         id, filename);
        nb_errors++;
	ret = 0;
    } else {
	if ((xmlLastError.code == XML_ERR_OK) ||
	    (xmlLastError.domain != XML_FROM_NAMESPACE)) {
	    test_log("test %s : %s failed to detect namespace error\n",
		     id, filename);
	    nb_errors++;
	    ret = 0;
	}
	xmlFreeDoc(doc);
    }
    return(ret);
}

static int
xmlconfTestNotWF(const char *id, const char *filename, int options) {
    xmlDocPtr doc;
    int ret = 1;

    doc = xmlReadFile(filename, NULL, options);
    if (doc != NULL) {
        test_log("test %s : %s failed to detect not well formedness\n",
	         id, filename);
        nb_errors++;
	xmlFreeDoc(doc);
	ret = 0;
    }
    return(ret);
}

static int
xmlconfTestItem(xmlDocPtr doc, xmlNodePtr cur) {
    int ret = -1;
    xmlChar *type = NULL;
    xmlChar *filename = NULL;
    xmlChar *uri = NULL;
    xmlChar *base = NULL;
    xmlChar *id = NULL;
    xmlChar *rec = NULL;
    xmlChar *version = NULL;
    xmlChar *entities = NULL;
    xmlChar *edition = NULL;
    int options = 0;
    int nstest = 0;
    int mem, final;
    int i;

    testErrorsSize = 0; testErrors[0] = 0;
    nbError = 0;
    nbFatal = 0;
    id = xmlGetProp(cur, BAD_CAST "ID");
    if (id == NULL) {
        test_log("test missing ID, line %ld\n", xmlGetLineNo(cur));
	goto error;
    }
    for (i = 0;skipped_tests[i] != NULL;i++) {
        if (!strcmp(skipped_tests[i], (char *) id)) {
	    test_log("Skipping test %s from skipped list\n", (char *) id);
	    ret = 0;
	    nb_skipped++;
	    goto error;
	}
    }
    type = xmlGetProp(cur, BAD_CAST "TYPE");
    if (type == NULL) {
        test_log("test %s missing TYPE\n", (char *) id);
	goto error;
    }
    uri = xmlGetProp(cur, BAD_CAST "URI");
    if (uri == NULL) {
        test_log("test %s missing URI\n", (char *) id);
	goto error;
    }
    base = xmlNodeGetBase(doc, cur);
    filename = composeDir(base, uri);
    if (!checkTestFile((char *) filename)) {
        test_log("test %s missing file %s \n", id,
	         (filename ? (char *)filename : "NULL"));
	goto error;
    }

    version = xmlGetProp(cur, BAD_CAST "VERSION");

    entities = xmlGetProp(cur, BAD_CAST "ENTITIES");
    if (!xmlStrEqual(entities, BAD_CAST "none")) {
        options |= XML_PARSE_DTDLOAD;
        options |= XML_PARSE_NOENT;
    }
    rec = xmlGetProp(cur, BAD_CAST "RECOMMENDATION");
    if ((rec == NULL) ||
        (xmlStrEqual(rec, BAD_CAST "XML1.0")) ||
	(xmlStrEqual(rec, BAD_CAST "XML1.0-errata2e")) ||
	(xmlStrEqual(rec, BAD_CAST "XML1.0-errata3e")) ||
	(xmlStrEqual(rec, BAD_CAST "XML1.0-errata4e"))) {
	if ((version != NULL) && (!xmlStrEqual(version, BAD_CAST "1.0"))) {
	    test_log("Skipping test %s for %s\n", (char *) id,
	             (char *) version);
	    ret = 0;
	    nb_skipped++;
	    goto error;
	}
	ret = 1;
    } else if ((xmlStrEqual(rec, BAD_CAST "NS1.0")) ||
	       (xmlStrEqual(rec, BAD_CAST "NS1.0-errata1e"))) {
	ret = 1;
	nstest = 1;
    } else {
        test_log("Skipping test %s for REC %s\n", (char *) id, (char *) rec);
	ret = 0;
	nb_skipped++;
	goto error;
    }
    edition = xmlGetProp(cur, BAD_CAST "EDITION");
    if ((edition != NULL) && (xmlStrchr(edition, '5') == NULL)) {
        /* test limited to all versions before 5th */
	options |= XML_PARSE_OLD10;
    }

    /*
     * Reset errors and check memory usage before the test
     */
    xmlResetLastError();
    testErrorsSize = 0; testErrors[0] = 0;
    mem = xmlMemUsed();

    if (xmlStrEqual(type, BAD_CAST "not-wf")) {
        if (nstest == 0)
	    xmlconfTestNotWF((char *) id, (char *) filename, options);
        else
	    xmlconfTestNotNSWF((char *) id, (char *) filename, options);
    } else if (xmlStrEqual(type, BAD_CAST "valid")) {
        options |= XML_PARSE_DTDVALID;
	xmlconfTestValid((char *) id, (char *) filename, options);
    } else if (xmlStrEqual(type, BAD_CAST "invalid")) {
        options |= XML_PARSE_DTDVALID;
	xmlconfTestInvalid((char *) id, (char *) filename, options);
    } else if (xmlStrEqual(type, BAD_CAST "error")) {
        test_log("Skipping error test %s \n", (char *) id);
	ret = 0;
	nb_skipped++;
	goto error;
    } else {
        test_log("test %s unknown TYPE value %s\n", (char *) id, (char *)type);
	ret = -1;
	goto error;
    }

    /*
     * Reset errors and check memory usage after the test
     */
    xmlResetLastError();
    final = xmlMemUsed();
    if (final > mem) {
        test_log("test %s : %s leaked %d bytes\n",
	         id, filename, final - mem);
        nb_leaks++;
	xmlMemDisplayLast(logfile, final - mem);
    }
    nb_tests++;

error:
    if (type != NULL)
        xmlFree(type);
    if (entities != NULL)
        xmlFree(entities);
    if (edition != NULL)
        xmlFree(edition);
    if (version != NULL)
        xmlFree(version);
    if (filename != NULL)
        xmlFree(filename);
    if (uri != NULL)
        xmlFree(uri);
    if (base != NULL)
        xmlFree(base);
    if (id != NULL)
        xmlFree(id);
    if (rec != NULL)
        xmlFree(rec);
    return(ret);
}

static int
xmlconfTestCases(xmlDocPtr doc, xmlNodePtr cur, int level) {
    xmlChar *profile;
    int ret = 0;
    int tests = 0;
    int output = 0;

    if (level == 1) {
	profile = xmlGetProp(cur, BAD_CAST "PROFILE");
	if (profile != NULL) {
	    output = 1;
	    level++;
	    printf("Test cases: %s\n", (char *) profile);
	    xmlFree(profile);
	}
    }
    cur = cur->children;
    while (cur != NULL) {
        /* look only at elements we ignore everything else */
        if (cur->type == XML_ELEMENT_NODE) {
	    if (xmlStrEqual(cur->name, BAD_CAST "TESTCASES")) {
	        ret += xmlconfTestCases(doc, cur, level);
	    } else if (xmlStrEqual(cur->name, BAD_CAST "TEST")) {
	        if (xmlconfTestItem(doc, cur) >= 0)
		    ret++;
		tests++;
	    } else {
	        fprintf(stderr, "Unhandled element %s\n", (char *)cur->name);
	    }
	}
        cur = cur->next;
    }
    if (output == 1) {
	if (tests > 0)
	    printf("Test cases: %d tests\n", tests);
    }
    return(ret);
}

static int
xmlconfTestSuite(xmlDocPtr doc, xmlNodePtr cur) {
    xmlChar *profile;
    int ret = 0;

    profile = xmlGetProp(cur, BAD_CAST "PROFILE");
    if (profile != NULL) {
        printf("Test suite: %s\n", (char *) profile);
	xmlFree(profile);
    } else
        printf("Test suite\n");
    cur = cur->children;
    while (cur != NULL) {
        /* look only at elements we ignore everything else */
        if (cur->type == XML_ELEMENT_NODE) {
	    if (xmlStrEqual(cur->name, BAD_CAST "TESTCASES")) {
	        ret += xmlconfTestCases(doc, cur, 1);
	    } else {
	        fprintf(stderr, "Unhandled element %s\n", (char *)cur->name);
	    }
	}
        cur = cur->next;
    }
    return(ret);
}

static void
xmlconfInfo(void) {
    fprintf(stderr, "  you need to fetch and extract the\n");
    fprintf(stderr, "  latest XML Conformance Test Suites\n");
    fprintf(stderr, "  http://www.w3.org/XML/Test/xmlts20080827.tar.gz\n");
    fprintf(stderr, "  see http://www.w3.org/XML/Test/ for informations\n");
}

static int
xmlconfTest(void) {
    const char *confxml = "xmlconf/xmlconf.xml";
    xmlDocPtr doc;
    xmlNodePtr cur;
    int ret = 0;

    if (!checkTestFile(confxml)) {
        fprintf(stderr, "%s is missing \n", confxml);
	xmlconfInfo();
	return(-1);
    }
    doc = xmlReadFile(confxml, NULL, XML_PARSE_NOENT);
    if (doc == NULL) {
        fprintf(stderr, "%s is corrupted \n", confxml);
	xmlconfInfo();
	return(-1);
    }

    cur = xmlDocGetRootElement(doc);
    if ((cur == NULL) || (!xmlStrEqual(cur->name, BAD_CAST "TESTSUITE"))) {
        fprintf(stderr, "Unexpected format %s\n", confxml);
	xmlconfInfo();
	ret = -1;
    } else {
        ret = xmlconfTestSuite(doc, cur);
    }
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
    xmlconfTest();
    if ((nb_errors == old_errors) && (nb_leaks == old_leaks))
	printf("Ran %d tests, no errors\n", nb_tests - old_tests);
    else
	printf("Ran %d tests, %d errors, %d leaks\n",
	       nb_tests - old_tests,
	       nb_errors - old_errors,
	       nb_leaks - old_leaks);
    if ((nb_errors == 0) && (nb_leaks == 0)) {
        ret = 0;
	printf("Total %d tests, no errors\n",
	       nb_tests);
    } else {
	ret = 1;
	printf("Total %d tests, %d errors, %d leaks\n",
	       nb_tests, nb_errors, nb_leaks);
	printf("See %s for detailed output\n", LOGFILE);
	if ((nb_leaks == 0) && (nb_errors == NB_EXPECTED_ERRORS)) {
	    printf("%d errors were expected\n", nb_errors);
	    ret = 0;
	}
    }
    xmlXPathFreeContext(ctxtXPath);
    xmlCleanupParser();
    xmlMemoryDump();

    if (logfile != NULL)
        fclose(logfile);
    return(ret);
}

#else /* ! LIBXML_XPATH_ENABLED */
#include <stdio.h>
int
main(int argc, char **argv) {
    fprintf(stderr, "%s need XPath support\n", argv[0]);
}
#endif
