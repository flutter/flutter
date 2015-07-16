/*
 * xmllint.c : a small tester program for XML input.
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 */

#include "libxml.h"

#include <string.h>
#include <stdarg.h>
#include <assert.h>

#if defined (_WIN32) && !defined(__CYGWIN__)
#if defined (_MSC_VER) || defined(__BORLANDC__)
#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")
#define gettimeofday(p1,p2)
#endif /* _MSC_VER */
#endif /* _WIN32 */

#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#ifdef HAVE_TIME_H
#include <time.h>
#endif

#ifdef __MINGW32__
#define _WINSOCKAPI_
#include <wsockcompat.h>
#include <winsock2.h>
#undef XML_SOCKLEN_T
#define XML_SOCKLEN_T unsigned int
#endif

#ifdef HAVE_SYS_TIMEB_H
#include <sys/timeb.h>
#endif

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_SYS_MMAN_H
#include <sys/mman.h>
/* seems needed for Solaris */
#ifndef MAP_FAILED
#define MAP_FAILED ((void *) -1)
#endif
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_LIBREADLINE
#include <readline/readline.h>
#ifdef HAVE_LIBHISTORY
#include <readline/history.h>
#endif
#endif

#include <libxml/xmlmemory.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/HTMLparser.h>
#include <libxml/HTMLtree.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/debugXML.h>
#include <libxml/xmlerror.h>
#ifdef LIBXML_XINCLUDE_ENABLED
#include <libxml/xinclude.h>
#endif
#ifdef LIBXML_CATALOG_ENABLED
#include <libxml/catalog.h>
#endif
#include <libxml/globals.h>
#include <libxml/xmlreader.h>
#ifdef LIBXML_SCHEMATRON_ENABLED
#include <libxml/schematron.h>
#endif
#ifdef LIBXML_SCHEMAS_ENABLED
#include <libxml/relaxng.h>
#include <libxml/xmlschemas.h>
#endif
#ifdef LIBXML_PATTERN_ENABLED
#include <libxml/pattern.h>
#endif
#ifdef LIBXML_C14N_ENABLED
#include <libxml/c14n.h>
#endif
#ifdef LIBXML_OUTPUT_ENABLED
#include <libxml/xmlsave.h>
#endif

#ifndef XML_XML_DEFAULT_CATALOG
#define XML_XML_DEFAULT_CATALOG "file:///etc/xml/catalog"
#endif

typedef enum {
    XMLLINT_RETURN_OK = 0,	/* No error */
    XMLLINT_ERR_UNCLASS = 1,	/* Unclassified */
    XMLLINT_ERR_DTD = 2,	/* Error in DTD */
    XMLLINT_ERR_VALID = 3,	/* Validation error */
    XMLLINT_ERR_RDFILE = 4,	/* CtxtReadFile error */
    XMLLINT_ERR_SCHEMACOMP = 5,	/* Schema compilation */
    XMLLINT_ERR_OUT = 6,	/* Error writing output */
    XMLLINT_ERR_SCHEMAPAT = 7,	/* Error in schema pattern */
    XMLLINT_ERR_RDREGIS = 8,	/* Error in Reader registration */
    XMLLINT_ERR_MEM = 9,	/* Out of memory error */
    XMLLINT_ERR_XPATH = 10	/* XPath evaluation error */
} xmllintReturnCode;
#ifdef LIBXML_DEBUG_ENABLED
static int shell = 0;
static int debugent = 0;
#endif
static int debug = 0;
static int maxmem = 0;
#ifdef LIBXML_TREE_ENABLED
static int copy = 0;
#endif /* LIBXML_TREE_ENABLED */
static int recovery = 0;
static int noent = 0;
static int noblanks = 0;
static int noout = 0;
static int nowrap = 0;
#ifdef LIBXML_OUTPUT_ENABLED
static int format = 0;
static const char *output = NULL;
static int compress = 0;
static int oldout = 0;
#endif /* LIBXML_OUTPUT_ENABLED */
#ifdef LIBXML_VALID_ENABLED
static int valid = 0;
static int postvalid = 0;
static char * dtdvalid = NULL;
static char * dtdvalidfpi = NULL;
#endif
#ifdef LIBXML_SCHEMAS_ENABLED
static char * relaxng = NULL;
static xmlRelaxNGPtr relaxngschemas = NULL;
static char * schema = NULL;
static xmlSchemaPtr wxschemas = NULL;
#endif
#ifdef LIBXML_SCHEMATRON_ENABLED
static char * schematron = NULL;
static xmlSchematronPtr wxschematron = NULL;
#endif
static int repeat = 0;
static int insert = 0;
#if defined(LIBXML_HTML_ENABLED) || defined(LIBXML_VALID_ENABLED)
static int html = 0;
static int xmlout = 0;
#endif
static int htmlout = 0;
#ifdef LIBXML_PUSH_ENABLED
static int push = 0;
#endif /* LIBXML_PUSH_ENABLED */
#ifdef HAVE_SYS_MMAN_H
static int memory = 0;
#endif
static int testIO = 0;
static char *encoding = NULL;
#ifdef LIBXML_XINCLUDE_ENABLED
static int xinclude = 0;
#endif
static int dtdattrs = 0;
static int loaddtd = 0;
static xmllintReturnCode progresult = XMLLINT_RETURN_OK;
static int timing = 0;
static int generate = 0;
static int dropdtd = 0;
#ifdef LIBXML_CATALOG_ENABLED
static int catalogs = 0;
static int nocatalogs = 0;
#endif
#ifdef LIBXML_C14N_ENABLED
static int canonical = 0;
static int canonical_11 = 0;
static int exc_canonical = 0;
#endif
#ifdef LIBXML_READER_ENABLED
static int stream = 0;
static int walker = 0;
#endif /* LIBXML_READER_ENABLED */
static int chkregister = 0;
static int nbregister = 0;
#ifdef LIBXML_SAX1_ENABLED
static int sax1 = 0;
#endif /* LIBXML_SAX1_ENABLED */
#ifdef LIBXML_PATTERN_ENABLED
static const char *pattern = NULL;
static xmlPatternPtr patternc = NULL;
static xmlStreamCtxtPtr patstream = NULL;
#endif
#ifdef LIBXML_XPATH_ENABLED
static const char *xpathquery = NULL;
#endif
static int options = XML_PARSE_COMPACT;
static int sax = 0;
static int oldxml10 = 0;

/************************************************************************
 *									*
 *		 Entity loading control and customization.		*
 *									*
 ************************************************************************/
#define MAX_PATHS 64
#ifdef _WIN32
# define PATH_SEPARATOR ';'
#else
# define PATH_SEPARATOR ':'
#endif
static xmlChar *paths[MAX_PATHS + 1];
static int nbpaths = 0;
static int load_trace = 0;

static
void parsePath(const xmlChar *path) {
    const xmlChar *cur;

    if (path == NULL)
	return;
    while (*path != 0) {
	if (nbpaths >= MAX_PATHS) {
	    fprintf(stderr, "MAX_PATHS reached: too many paths\n");
	    return;
	}
	cur = path;
	while ((*cur == ' ') || (*cur == PATH_SEPARATOR))
	    cur++;
	path = cur;
	while ((*cur != 0) && (*cur != ' ') && (*cur != PATH_SEPARATOR))
	    cur++;
	if (cur != path) {
	    paths[nbpaths] = xmlStrndup(path, cur - path);
	    if (paths[nbpaths] != NULL)
		nbpaths++;
	    path = cur;
	}
    }
}

static xmlExternalEntityLoader defaultEntityLoader = NULL;

static xmlParserInputPtr
xmllintExternalEntityLoader(const char *URL, const char *ID,
			     xmlParserCtxtPtr ctxt) {
    xmlParserInputPtr ret;
    warningSAXFunc warning = NULL;
    errorSAXFunc err = NULL;

    int i;
    const char *lastsegment = URL;
    const char *iter = URL;

    if ((nbpaths > 0) && (iter != NULL)) {
	while (*iter != 0) {
	    if (*iter == '/')
		lastsegment = iter + 1;
	    iter++;
	}
    }

    if ((ctxt != NULL) && (ctxt->sax != NULL)) {
	warning = ctxt->sax->warning;
	err = ctxt->sax->error;
	ctxt->sax->warning = NULL;
	ctxt->sax->error = NULL;
    }

    if (defaultEntityLoader != NULL) {
	ret = defaultEntityLoader(URL, ID, ctxt);
	if (ret != NULL) {
	    if (warning != NULL)
		ctxt->sax->warning = warning;
	    if (err != NULL)
		ctxt->sax->error = err;
	    if (load_trace) {
		fprintf \
			(stderr,
			 "Loaded URL=\"%s\" ID=\"%s\"\n",
			 URL ? URL : "(null)",
			 ID ? ID : "(null)");
	    }
	    return(ret);
	}
    }
    for (i = 0;i < nbpaths;i++) {
	xmlChar *newURL;

	newURL = xmlStrdup((const xmlChar *) paths[i]);
	newURL = xmlStrcat(newURL, (const xmlChar *) "/");
	newURL = xmlStrcat(newURL, (const xmlChar *) lastsegment);
	if (newURL != NULL) {
	    ret = defaultEntityLoader((const char *)newURL, ID, ctxt);
	    if (ret != NULL) {
		if (warning != NULL)
		    ctxt->sax->warning = warning;
		if (err != NULL)
		    ctxt->sax->error = err;
		if (load_trace) {
		    fprintf \
			(stderr,
			 "Loaded URL=\"%s\" ID=\"%s\"\n",
			 newURL,
			 ID ? ID : "(null)");
		}
		xmlFree(newURL);
		return(ret);
	    }
	    xmlFree(newURL);
	}
    }
    if (err != NULL)
        ctxt->sax->error = err;
    if (warning != NULL) {
	ctxt->sax->warning = warning;
	if (URL != NULL)
	    warning(ctxt, "failed to load external entity \"%s\"\n", URL);
	else if (ID != NULL)
	    warning(ctxt, "failed to load external entity \"%s\"\n", ID);
    }
    return(NULL);
}
/************************************************************************
 *									*
 * Memory allocation consumption debugging				*
 *									*
 ************************************************************************/

static void
OOM(void)
{
    fprintf(stderr, "Ran out of memory needs > %d bytes\n", maxmem);
    progresult = XMLLINT_ERR_MEM;
}

static void
myFreeFunc(void *mem)
{
    xmlMemFree(mem);
}
static void *
myMallocFunc(size_t size)
{
    void *ret;

    ret = xmlMemMalloc(size);
    if (ret != NULL) {
        if (xmlMemUsed() > maxmem) {
            OOM();
            xmlMemFree(ret);
            return (NULL);
        }
    }
    return (ret);
}
static void *
myReallocFunc(void *mem, size_t size)
{
    void *ret;

    ret = xmlMemRealloc(mem, size);
    if (ret != NULL) {
        if (xmlMemUsed() > maxmem) {
            OOM();
            xmlMemFree(ret);
            return (NULL);
        }
    }
    return (ret);
}
static char *
myStrdupFunc(const char *str)
{
    char *ret;

    ret = xmlMemoryStrdup(str);
    if (ret != NULL) {
        if (xmlMemUsed() > maxmem) {
            OOM();
            xmlFree(ret);
            return (NULL);
        }
    }
    return (ret);
}
/************************************************************************
 *									*
 * Internal timing routines to remove the necessity to have		*
 * unix-specific function calls.					*
 *									*
 ************************************************************************/

#ifndef HAVE_GETTIMEOFDAY
#ifdef HAVE_SYS_TIMEB_H
#ifdef HAVE_SYS_TIME_H
#ifdef HAVE_FTIME

static int
my_gettimeofday(struct timeval *tvp, void *tzp)
{
	struct timeb timebuffer;

	ftime(&timebuffer);
	if (tvp) {
		tvp->tv_sec = timebuffer.time;
		tvp->tv_usec = timebuffer.millitm * 1000L;
	}
	return (0);
}
#define HAVE_GETTIMEOFDAY 1
#define gettimeofday my_gettimeofday

#endif /* HAVE_FTIME */
#endif /* HAVE_SYS_TIME_H */
#endif /* HAVE_SYS_TIMEB_H */
#endif /* !HAVE_GETTIMEOFDAY */

#if defined(HAVE_GETTIMEOFDAY)
static struct timeval begin, end;

/*
 * startTimer: call where you want to start timing
 */
static void
startTimer(void)
{
    gettimeofday(&begin, NULL);
}

/*
 * endTimer: call where you want to stop timing and to print out a
 *           message about the timing performed; format is a printf
 *           type argument
 */
static void XMLCDECL
endTimer(const char *fmt, ...)
{
    long msec;
    va_list ap;

    gettimeofday(&end, NULL);
    msec = end.tv_sec - begin.tv_sec;
    msec *= 1000;
    msec += (end.tv_usec - begin.tv_usec) / 1000;

#ifndef HAVE_STDARG_H
#error "endTimer required stdarg functions"
#endif
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);

    fprintf(stderr, " took %ld ms\n", msec);
}
#elif defined(HAVE_TIME_H)
/*
 * No gettimeofday function, so we have to make do with calling clock.
 * This is obviously less accurate, but there's little we can do about
 * that.
 */
#ifndef CLOCKS_PER_SEC
#define CLOCKS_PER_SEC 100
#endif

static clock_t begin, end;
static void
startTimer(void)
{
    begin = clock();
}
static void XMLCDECL
endTimer(const char *fmt, ...)
{
    long msec;
    va_list ap;

    end = clock();
    msec = ((end - begin) * 1000) / CLOCKS_PER_SEC;

#ifndef HAVE_STDARG_H
#error "endTimer required stdarg functions"
#endif
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fprintf(stderr, " took %ld ms\n", msec);
}
#else

/*
 * We don't have a gettimeofday or time.h, so we just don't do timing
 */
static void
startTimer(void)
{
    /*
     * Do nothing
     */
}
static void XMLCDECL
endTimer(char *format, ...)
{
    /*
     * We cannot do anything because we don't have a timing function
     */
#ifdef HAVE_STDARG_H
    va_start(ap, format);
    vfprintf(stderr, format, ap);
    va_end(ap);
    fprintf(stderr, " was not timed\n", msec);
#else
    /* We don't have gettimeofday, time or stdarg.h, what crazy world is
     * this ?!
     */
#endif
}
#endif
/************************************************************************
 *									*
 *			HTML ouput					*
 *									*
 ************************************************************************/
static char buffer[50000];

static void
xmlHTMLEncodeSend(void) {
    char *result;

    result = (char *) xmlEncodeEntitiesReentrant(NULL, BAD_CAST buffer);
    if (result) {
	xmlGenericError(xmlGenericErrorContext, "%s", result);
	xmlFree(result);
    }
    buffer[0] = 0;
}

/**
 * xmlHTMLPrintFileInfo:
 * @input:  an xmlParserInputPtr input
 *
 * Displays the associated file and line informations for the current input
 */

static void
xmlHTMLPrintFileInfo(xmlParserInputPtr input) {
    int len;
    xmlGenericError(xmlGenericErrorContext, "<p>");

    len = strlen(buffer);
    if (input != NULL) {
	if (input->filename) {
	    snprintf(&buffer[len], sizeof(buffer) - len, "%s:%d: ", input->filename,
		    input->line);
	} else {
	    snprintf(&buffer[len], sizeof(buffer) - len, "Entity: line %d: ", input->line);
	}
    }
    xmlHTMLEncodeSend();
}

/**
 * xmlHTMLPrintFileContext:
 * @input:  an xmlParserInputPtr input
 *
 * Displays current context within the input content for error tracking
 */

static void
xmlHTMLPrintFileContext(xmlParserInputPtr input) {
    const xmlChar *cur, *base;
    int len;
    int n;

    if (input == NULL) return;
    xmlGenericError(xmlGenericErrorContext, "<pre>\n");
    cur = input->cur;
    base = input->base;
    while ((cur > base) && ((*cur == '\n') || (*cur == '\r'))) {
	cur--;
    }
    n = 0;
    while ((n++ < 80) && (cur > base) && (*cur != '\n') && (*cur != '\r'))
        cur--;
    if ((*cur == '\n') || (*cur == '\r')) cur++;
    base = cur;
    n = 0;
    while ((*cur != 0) && (*cur != '\n') && (*cur != '\r') && (n < 79)) {
	len = strlen(buffer);
        snprintf(&buffer[len], sizeof(buffer) - len, "%c",
		    (unsigned char) *cur++);
	n++;
    }
    len = strlen(buffer);
    snprintf(&buffer[len], sizeof(buffer) - len, "\n");
    cur = input->cur;
    while ((*cur == '\n') || (*cur == '\r'))
	cur--;
    n = 0;
    while ((cur != base) && (n++ < 80)) {
	len = strlen(buffer);
        snprintf(&buffer[len], sizeof(buffer) - len, " ");
        base++;
    }
    len = strlen(buffer);
    snprintf(&buffer[len], sizeof(buffer) - len, "^\n");
    xmlHTMLEncodeSend();
    xmlGenericError(xmlGenericErrorContext, "</pre>");
}

/**
 * xmlHTMLError:
 * @ctx:  an XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format an error messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
xmlHTMLError(void *ctx, const char *msg, ...)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlParserInputPtr input;
    va_list args;
    int len;

    buffer[0] = 0;
    input = ctxt->input;
    if ((input != NULL) && (input->filename == NULL) && (ctxt->inputNr > 1)) {
        input = ctxt->inputTab[ctxt->inputNr - 2];
    }

    xmlHTMLPrintFileInfo(input);

    xmlGenericError(xmlGenericErrorContext, "<b>error</b>: ");
    va_start(args, msg);
    len = strlen(buffer);
    vsnprintf(&buffer[len],  sizeof(buffer) - len, msg, args);
    va_end(args);
    xmlHTMLEncodeSend();
    xmlGenericError(xmlGenericErrorContext, "</p>\n");

    xmlHTMLPrintFileContext(input);
    xmlHTMLEncodeSend();
}

/**
 * xmlHTMLWarning:
 * @ctx:  an XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a warning messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
xmlHTMLWarning(void *ctx, const char *msg, ...)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlParserInputPtr input;
    va_list args;
    int len;

    buffer[0] = 0;
    input = ctxt->input;
    if ((input != NULL) && (input->filename == NULL) && (ctxt->inputNr > 1)) {
        input = ctxt->inputTab[ctxt->inputNr - 2];
    }


    xmlHTMLPrintFileInfo(input);

    xmlGenericError(xmlGenericErrorContext, "<b>warning</b>: ");
    va_start(args, msg);
    len = strlen(buffer);
    vsnprintf(&buffer[len],  sizeof(buffer) - len, msg, args);
    va_end(args);
    xmlHTMLEncodeSend();
    xmlGenericError(xmlGenericErrorContext, "</p>\n");

    xmlHTMLPrintFileContext(input);
    xmlHTMLEncodeSend();
}

/**
 * xmlHTMLValidityError:
 * @ctx:  an XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format an validity error messages, gives file,
 * line, position and extra parameters.
 */
static void XMLCDECL
xmlHTMLValidityError(void *ctx, const char *msg, ...)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlParserInputPtr input;
    va_list args;
    int len;

    buffer[0] = 0;
    input = ctxt->input;
    if ((input->filename == NULL) && (ctxt->inputNr > 1))
        input = ctxt->inputTab[ctxt->inputNr - 2];

    xmlHTMLPrintFileInfo(input);

    xmlGenericError(xmlGenericErrorContext, "<b>validity error</b>: ");
    len = strlen(buffer);
    va_start(args, msg);
    vsnprintf(&buffer[len],  sizeof(buffer) - len, msg, args);
    va_end(args);
    xmlHTMLEncodeSend();
    xmlGenericError(xmlGenericErrorContext, "</p>\n");

    xmlHTMLPrintFileContext(input);
    xmlHTMLEncodeSend();
    progresult = XMLLINT_ERR_VALID;
}

/**
 * xmlHTMLValidityWarning:
 * @ctx:  an XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a validity warning messages, gives file, line,
 * position and extra parameters.
 */
static void XMLCDECL
xmlHTMLValidityWarning(void *ctx, const char *msg, ...)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlParserInputPtr input;
    va_list args;
    int len;

    buffer[0] = 0;
    input = ctxt->input;
    if ((input->filename == NULL) && (ctxt->inputNr > 1))
        input = ctxt->inputTab[ctxt->inputNr - 2];

    xmlHTMLPrintFileInfo(input);

    xmlGenericError(xmlGenericErrorContext, "<b>validity warning</b>: ");
    va_start(args, msg);
    len = strlen(buffer);
    vsnprintf(&buffer[len],  sizeof(buffer) - len, msg, args);
    va_end(args);
    xmlHTMLEncodeSend();
    xmlGenericError(xmlGenericErrorContext, "</p>\n");

    xmlHTMLPrintFileContext(input);
    xmlHTMLEncodeSend();
}

/************************************************************************
 *									*
 *			Shell Interface					*
 *									*
 ************************************************************************/
#ifdef LIBXML_DEBUG_ENABLED
#ifdef LIBXML_XPATH_ENABLED
/**
 * xmlShellReadline:
 * @prompt:  the prompt value
 *
 * Read a string
 *
 * Returns a pointer to it or NULL on EOF the caller is expected to
 *     free the returned string.
 */
static char *
xmlShellReadline(char *prompt) {
#ifdef HAVE_LIBREADLINE
    char *line_read;

    /* Get a line from the user. */
    line_read = readline (prompt);

    /* If the line has any text in it, save it on the history. */
    if (line_read && *line_read)
	add_history (line_read);

    return (line_read);
#else
    char line_read[501];
    char *ret;
    int len;

    if (prompt != NULL)
	fprintf(stdout, "%s", prompt);
    if (!fgets(line_read, 500, stdin))
        return(NULL);
    line_read[500] = 0;
    len = strlen(line_read);
    ret = (char *) malloc(len + 1);
    if (ret != NULL) {
	memcpy (ret, line_read, len + 1);
    }
    return(ret);
#endif
}
#endif /* LIBXML_XPATH_ENABLED */
#endif /* LIBXML_DEBUG_ENABLED */

/************************************************************************
 *									*
 *			I/O Interfaces					*
 *									*
 ************************************************************************/

static int myRead(FILE *f, char * buf, int len) {
    return(fread(buf, 1, len, f));
}
static void myClose(FILE *f) {
  if (f != stdin) {
    fclose(f);
  }
}

/************************************************************************
 *									*
 *			SAX based tests					*
 *									*
 ************************************************************************/

/*
 * empty SAX block
 */
static xmlSAXHandler emptySAXHandlerStruct = {
    NULL, /* internalSubset */
    NULL, /* isStandalone */
    NULL, /* hasInternalSubset */
    NULL, /* hasExternalSubset */
    NULL, /* resolveEntity */
    NULL, /* getEntity */
    NULL, /* entityDecl */
    NULL, /* notationDecl */
    NULL, /* attributeDecl */
    NULL, /* elementDecl */
    NULL, /* unparsedEntityDecl */
    NULL, /* setDocumentLocator */
    NULL, /* startDocument */
    NULL, /* endDocument */
    NULL, /* startElement */
    NULL, /* endElement */
    NULL, /* reference */
    NULL, /* characters */
    NULL, /* ignorableWhitespace */
    NULL, /* processingInstruction */
    NULL, /* comment */
    NULL, /* xmlParserWarning */
    NULL, /* xmlParserError */
    NULL, /* xmlParserError */
    NULL, /* getParameterEntity */
    NULL, /* cdataBlock; */
    NULL, /* externalSubset; */
    XML_SAX2_MAGIC,
    NULL,
    NULL, /* startElementNs */
    NULL, /* endElementNs */
    NULL  /* xmlStructuredErrorFunc */
};

static xmlSAXHandlerPtr emptySAXHandler = &emptySAXHandlerStruct;
extern xmlSAXHandlerPtr debugSAXHandler;
static int callbacks;

/**
 * isStandaloneDebug:
 * @ctxt:  An XML parser context
 *
 * Is this document tagged standalone ?
 *
 * Returns 1 if true
 */
static int
isStandaloneDebug(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (noout)
	return(0);
    fprintf(stdout, "SAX.isStandalone()\n");
    return(0);
}

/**
 * hasInternalSubsetDebug:
 * @ctxt:  An XML parser context
 *
 * Does this document has an internal subset
 *
 * Returns 1 if true
 */
static int
hasInternalSubsetDebug(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (noout)
	return(0);
    fprintf(stdout, "SAX.hasInternalSubset()\n");
    return(0);
}

/**
 * hasExternalSubsetDebug:
 * @ctxt:  An XML parser context
 *
 * Does this document has an external subset
 *
 * Returns 1 if true
 */
static int
hasExternalSubsetDebug(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (noout)
	return(0);
    fprintf(stdout, "SAX.hasExternalSubset()\n");
    return(0);
}

/**
 * internalSubsetDebug:
 * @ctxt:  An XML parser context
 *
 * Does this document has an internal subset
 */
static void
internalSubsetDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name,
	       const xmlChar *ExternalID, const xmlChar *SystemID)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.internalSubset(%s,", name);
    if (ExternalID == NULL)
	fprintf(stdout, " ,");
    else
	fprintf(stdout, " %s,", ExternalID);
    if (SystemID == NULL)
	fprintf(stdout, " )\n");
    else
	fprintf(stdout, " %s)\n", SystemID);
}

/**
 * externalSubsetDebug:
 * @ctxt:  An XML parser context
 *
 * Does this document has an external subset
 */
static void
externalSubsetDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name,
	       const xmlChar *ExternalID, const xmlChar *SystemID)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.externalSubset(%s,", name);
    if (ExternalID == NULL)
	fprintf(stdout, " ,");
    else
	fprintf(stdout, " %s,", ExternalID);
    if (SystemID == NULL)
	fprintf(stdout, " )\n");
    else
	fprintf(stdout, " %s)\n", SystemID);
}

/**
 * resolveEntityDebug:
 * @ctxt:  An XML parser context
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 *
 * Special entity resolver, better left to the parser, it has
 * more context than the application layer.
 * The default behaviour is to NOT resolve the entities, in that case
 * the ENTITY_REF nodes are built in the structure (and the parameter
 * values).
 *
 * Returns the xmlParserInputPtr if inlined or NULL for DOM behaviour.
 */
static xmlParserInputPtr
resolveEntityDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *publicId, const xmlChar *systemId)
{
    callbacks++;
    if (noout)
	return(NULL);
    /* xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx; */


    fprintf(stdout, "SAX.resolveEntity(");
    if (publicId != NULL)
	fprintf(stdout, "%s", (char *)publicId);
    else
	fprintf(stdout, " ");
    if (systemId != NULL)
	fprintf(stdout, ", %s)\n", (char *)systemId);
    else
	fprintf(stdout, ", )\n");
    return(NULL);
}

/**
 * getEntityDebug:
 * @ctxt:  An XML parser context
 * @name: The entity name
 *
 * Get an entity by name
 *
 * Returns the xmlParserInputPtr if inlined or NULL for DOM behaviour.
 */
static xmlEntityPtr
getEntityDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name)
{
    callbacks++;
    if (noout)
	return(NULL);
    fprintf(stdout, "SAX.getEntity(%s)\n", name);
    return(NULL);
}

/**
 * getParameterEntityDebug:
 * @ctxt:  An XML parser context
 * @name: The entity name
 *
 * Get a parameter entity by name
 *
 * Returns the xmlParserInputPtr
 */
static xmlEntityPtr
getParameterEntityDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name)
{
    callbacks++;
    if (noout)
	return(NULL);
    fprintf(stdout, "SAX.getParameterEntity(%s)\n", name);
    return(NULL);
}


/**
 * entityDeclDebug:
 * @ctxt:  An XML parser context
 * @name:  the entity name
 * @type:  the entity type
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 * @content: the entity value (without processing).
 *
 * An entity definition has been parsed
 */
static void
entityDeclDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name, int type,
          const xmlChar *publicId, const xmlChar *systemId, xmlChar *content)
{
const xmlChar *nullstr = BAD_CAST "(null)";
    /* not all libraries handle printing null pointers nicely */
    if (publicId == NULL)
        publicId = nullstr;
    if (systemId == NULL)
        systemId = nullstr;
    if (content == NULL)
        content = (xmlChar *)nullstr;
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.entityDecl(%s, %d, %s, %s, %s)\n",
            name, type, publicId, systemId, content);
}

/**
 * attributeDeclDebug:
 * @ctxt:  An XML parser context
 * @name:  the attribute name
 * @type:  the attribute type
 *
 * An attribute definition has been parsed
 */
static void
attributeDeclDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar * elem,
                   const xmlChar * name, int type, int def,
                   const xmlChar * defaultValue, xmlEnumerationPtr tree)
{
    callbacks++;
    if (noout)
        return;
    if (defaultValue == NULL)
        fprintf(stdout, "SAX.attributeDecl(%s, %s, %d, %d, NULL, ...)\n",
                elem, name, type, def);
    else
        fprintf(stdout, "SAX.attributeDecl(%s, %s, %d, %d, %s, ...)\n",
                elem, name, type, def, defaultValue);
    xmlFreeEnumeration(tree);
}

/**
 * elementDeclDebug:
 * @ctxt:  An XML parser context
 * @name:  the element name
 * @type:  the element type
 * @content: the element value (without processing).
 *
 * An element definition has been parsed
 */
static void
elementDeclDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name, int type,
	    xmlElementContentPtr content ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.elementDecl(%s, %d, ...)\n",
            name, type);
}

/**
 * notationDeclDebug:
 * @ctxt:  An XML parser context
 * @name: The name of the notation
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 *
 * What to do when a notation declaration has been parsed.
 */
static void
notationDeclDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name,
	     const xmlChar *publicId, const xmlChar *systemId)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.notationDecl(%s, %s, %s)\n",
            (char *) name, (char *) publicId, (char *) systemId);
}

/**
 * unparsedEntityDeclDebug:
 * @ctxt:  An XML parser context
 * @name: The name of the entity
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 * @notationName: the name of the notation
 *
 * What to do when an unparsed entity declaration is parsed
 */
static void
unparsedEntityDeclDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name,
		   const xmlChar *publicId, const xmlChar *systemId,
		   const xmlChar *notationName)
{
const xmlChar *nullstr = BAD_CAST "(null)";

    if (publicId == NULL)
        publicId = nullstr;
    if (systemId == NULL)
        systemId = nullstr;
    if (notationName == NULL)
        notationName = nullstr;
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.unparsedEntityDecl(%s, %s, %s, %s)\n",
            (char *) name, (char *) publicId, (char *) systemId,
	    (char *) notationName);
}

/**
 * setDocumentLocatorDebug:
 * @ctxt:  An XML parser context
 * @loc: A SAX Locator
 *
 * Receive the document locator at startup, actually xmlDefaultSAXLocator
 * Everything is available on the context, so this is useless in our case.
 */
static void
setDocumentLocatorDebug(void *ctx ATTRIBUTE_UNUSED, xmlSAXLocatorPtr loc ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.setDocumentLocator()\n");
}

/**
 * startDocumentDebug:
 * @ctxt:  An XML parser context
 *
 * called when the document start being processed.
 */
static void
startDocumentDebug(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.startDocument()\n");
}

/**
 * endDocumentDebug:
 * @ctxt:  An XML parser context
 *
 * called when the document end has been detected.
 */
static void
endDocumentDebug(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.endDocument()\n");
}

/**
 * startElementDebug:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when an opening tag has been processed.
 */
static void
startElementDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name, const xmlChar **atts)
{
    int i;

    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.startElement(%s", (char *) name);
    if (atts != NULL) {
        for (i = 0;(atts[i] != NULL);i++) {
	    fprintf(stdout, ", %s='", atts[i++]);
	    if (atts[i] != NULL)
	        fprintf(stdout, "%s'", atts[i]);
	}
    }
    fprintf(stdout, ")\n");
}

/**
 * endElementDebug:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when the end of an element has been detected.
 */
static void
endElementDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.endElement(%s)\n", (char *) name);
}

/**
 * charactersDebug:
 * @ctxt:  An XML parser context
 * @ch:  a xmlChar string
 * @len: the number of xmlChar
 *
 * receiving some chars from the parser.
 * Question: how much at a time ???
 */
static void
charactersDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *ch, int len)
{
    char out[40];
    int i;

    callbacks++;
    if (noout)
	return;
    for (i = 0;(i<len) && (i < 30);i++)
	out[i] = ch[i];
    out[i] = 0;

    fprintf(stdout, "SAX.characters(%s, %d)\n", out, len);
}

/**
 * referenceDebug:
 * @ctxt:  An XML parser context
 * @name:  The entity name
 *
 * called when an entity reference is detected.
 */
static void
referenceDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.reference(%s)\n", name);
}

/**
 * ignorableWhitespaceDebug:
 * @ctxt:  An XML parser context
 * @ch:  a xmlChar string
 * @start: the first char in the string
 * @len: the number of xmlChar
 *
 * receiving some ignorable whitespaces from the parser.
 * Question: how much at a time ???
 */
static void
ignorableWhitespaceDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *ch, int len)
{
    char out[40];
    int i;

    callbacks++;
    if (noout)
	return;
    for (i = 0;(i<len) && (i < 30);i++)
	out[i] = ch[i];
    out[i] = 0;
    fprintf(stdout, "SAX.ignorableWhitespace(%s, %d)\n", out, len);
}

/**
 * processingInstructionDebug:
 * @ctxt:  An XML parser context
 * @target:  the target name
 * @data: the PI data's
 * @len: the number of xmlChar
 *
 * A processing instruction has been parsed.
 */
static void
processingInstructionDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *target,
                      const xmlChar *data)
{
    callbacks++;
    if (noout)
	return;
    if (data != NULL)
	fprintf(stdout, "SAX.processingInstruction(%s, %s)\n",
		(char *) target, (char *) data);
    else
	fprintf(stdout, "SAX.processingInstruction(%s, NULL)\n",
		(char *) target);
}

/**
 * cdataBlockDebug:
 * @ctx: the user data (XML parser context)
 * @value:  The pcdata content
 * @len:  the block length
 *
 * called when a pcdata block has been parsed
 */
static void
cdataBlockDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *value, int len)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.pcdata(%.20s, %d)\n",
	    (char *) value, len);
}

/**
 * commentDebug:
 * @ctxt:  An XML parser context
 * @value:  the comment content
 *
 * A comment has been parsed.
 */
static void
commentDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *value)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.comment(%s)\n", value);
}

/**
 * warningDebug:
 * @ctxt:  An XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a warning messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
warningDebug(void *ctx ATTRIBUTE_UNUSED, const char *msg, ...)
{
    va_list args;

    callbacks++;
    if (noout)
	return;
    va_start(args, msg);
    fprintf(stdout, "SAX.warning: ");
    vfprintf(stdout, msg, args);
    va_end(args);
}

/**
 * errorDebug:
 * @ctxt:  An XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a error messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
errorDebug(void *ctx ATTRIBUTE_UNUSED, const char *msg, ...)
{
    va_list args;

    callbacks++;
    if (noout)
	return;
    va_start(args, msg);
    fprintf(stdout, "SAX.error: ");
    vfprintf(stdout, msg, args);
    va_end(args);
}

/**
 * fatalErrorDebug:
 * @ctxt:  An XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a fatalError messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
fatalErrorDebug(void *ctx ATTRIBUTE_UNUSED, const char *msg, ...)
{
    va_list args;

    callbacks++;
    if (noout)
	return;
    va_start(args, msg);
    fprintf(stdout, "SAX.fatalError: ");
    vfprintf(stdout, msg, args);
    va_end(args);
}

static xmlSAXHandler debugSAXHandlerStruct = {
    internalSubsetDebug,
    isStandaloneDebug,
    hasInternalSubsetDebug,
    hasExternalSubsetDebug,
    resolveEntityDebug,
    getEntityDebug,
    entityDeclDebug,
    notationDeclDebug,
    attributeDeclDebug,
    elementDeclDebug,
    unparsedEntityDeclDebug,
    setDocumentLocatorDebug,
    startDocumentDebug,
    endDocumentDebug,
    startElementDebug,
    endElementDebug,
    referenceDebug,
    charactersDebug,
    ignorableWhitespaceDebug,
    processingInstructionDebug,
    commentDebug,
    warningDebug,
    errorDebug,
    fatalErrorDebug,
    getParameterEntityDebug,
    cdataBlockDebug,
    externalSubsetDebug,
    1,
    NULL,
    NULL,
    NULL,
    NULL
};

xmlSAXHandlerPtr debugSAXHandler = &debugSAXHandlerStruct;

/*
 * SAX2 specific callbacks
 */
/**
 * startElementNsDebug:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when an opening tag has been processed.
 */
static void
startElementNsDebug(void *ctx ATTRIBUTE_UNUSED,
                    const xmlChar *localname,
                    const xmlChar *prefix,
                    const xmlChar *URI,
		    int nb_namespaces,
		    const xmlChar **namespaces,
		    int nb_attributes,
		    int nb_defaulted,
		    const xmlChar **attributes)
{
    int i;

    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.startElementNs(%s", (char *) localname);
    if (prefix == NULL)
	fprintf(stdout, ", NULL");
    else
	fprintf(stdout, ", %s", (char *) prefix);
    if (URI == NULL)
	fprintf(stdout, ", NULL");
    else
	fprintf(stdout, ", '%s'", (char *) URI);
    fprintf(stdout, ", %d", nb_namespaces);

    if (namespaces != NULL) {
        for (i = 0;i < nb_namespaces * 2;i++) {
	    fprintf(stdout, ", xmlns");
	    if (namespaces[i] != NULL)
	        fprintf(stdout, ":%s", namespaces[i]);
	    i++;
	    fprintf(stdout, "='%s'", namespaces[i]);
	}
    }
    fprintf(stdout, ", %d, %d", nb_attributes, nb_defaulted);
    if (attributes != NULL) {
        for (i = 0;i < nb_attributes * 5;i += 5) {
	    if (attributes[i + 1] != NULL)
		fprintf(stdout, ", %s:%s='", attributes[i + 1], attributes[i]);
	    else
		fprintf(stdout, ", %s='", attributes[i]);
	    fprintf(stdout, "%.4s...', %d", attributes[i + 3],
		    (int)(attributes[i + 4] - attributes[i + 3]));
	}
    }
    fprintf(stdout, ")\n");
}

/**
 * endElementDebug:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when the end of an element has been detected.
 */
static void
endElementNsDebug(void *ctx ATTRIBUTE_UNUSED,
                  const xmlChar *localname,
                  const xmlChar *prefix,
                  const xmlChar *URI)
{
    callbacks++;
    if (noout)
	return;
    fprintf(stdout, "SAX.endElementNs(%s", (char *) localname);
    if (prefix == NULL)
	fprintf(stdout, ", NULL");
    else
	fprintf(stdout, ", %s", (char *) prefix);
    if (URI == NULL)
	fprintf(stdout, ", NULL)\n");
    else
	fprintf(stdout, ", '%s')\n", (char *) URI);
}

static xmlSAXHandler debugSAX2HandlerStruct = {
    internalSubsetDebug,
    isStandaloneDebug,
    hasInternalSubsetDebug,
    hasExternalSubsetDebug,
    resolveEntityDebug,
    getEntityDebug,
    entityDeclDebug,
    notationDeclDebug,
    attributeDeclDebug,
    elementDeclDebug,
    unparsedEntityDeclDebug,
    setDocumentLocatorDebug,
    startDocumentDebug,
    endDocumentDebug,
    NULL,
    NULL,
    referenceDebug,
    charactersDebug,
    ignorableWhitespaceDebug,
    processingInstructionDebug,
    commentDebug,
    warningDebug,
    errorDebug,
    fatalErrorDebug,
    getParameterEntityDebug,
    cdataBlockDebug,
    externalSubsetDebug,
    XML_SAX2_MAGIC,
    NULL,
    startElementNsDebug,
    endElementNsDebug,
    NULL
};

static xmlSAXHandlerPtr debugSAX2Handler = &debugSAX2HandlerStruct;

static void
testSAX(const char *filename) {
    xmlSAXHandlerPtr handler;
    const char *user_data = "user_data"; /* mostly for debugging */
    xmlParserInputBufferPtr buf = NULL;
    xmlParserInputPtr inputStream;
    xmlParserCtxtPtr ctxt = NULL;
    xmlSAXHandlerPtr old_sax = NULL;

    callbacks = 0;

    if (noout) {
        handler = emptySAXHandler;
#ifdef LIBXML_SAX1_ENABLED
    } else if (sax1) {
        handler = debugSAXHandler;
#endif
    } else {
        handler = debugSAX2Handler;
    }

    /*
     * it's not the simplest code but the most generic in term of I/O
     */
    buf = xmlParserInputBufferCreateFilename(filename, XML_CHAR_ENCODING_NONE);
    if (buf == NULL) {
        goto error;
    }

#ifdef LIBXML_SCHEMAS_ENABLED
    if (wxschemas != NULL) {
        int ret;
	xmlSchemaValidCtxtPtr vctxt;

	vctxt = xmlSchemaNewValidCtxt(wxschemas);
	xmlSchemaSetValidErrors(vctxt,
		(xmlSchemaValidityErrorFunc) fprintf,
		(xmlSchemaValidityWarningFunc) fprintf,
		stderr);

	ret = xmlSchemaValidateStream(vctxt, buf, 0, handler,
	                              (void *)user_data);
	if (repeat == 0) {
	    if (ret == 0) {
		fprintf(stderr, "%s validates\n", filename);
	    } else if (ret > 0) {
		fprintf(stderr, "%s fails to validate\n", filename);
		progresult = XMLLINT_ERR_VALID;
	    } else {
		fprintf(stderr, "%s validation generated an internal error\n",
		       filename);
		progresult = XMLLINT_ERR_VALID;
	    }
	}
	xmlSchemaFreeValidCtxt(vctxt);
    } else
#endif
    {
	/*
	 * Create the parser context amd hook the input
	 */
	ctxt = xmlNewParserCtxt();
	if (ctxt == NULL) {
	    xmlFreeParserInputBuffer(buf);
	    goto error;
	}
	old_sax = ctxt->sax;
	ctxt->sax = handler;
	ctxt->userData = (void *) user_data;
	inputStream = xmlNewIOInputStream(ctxt, buf, XML_CHAR_ENCODING_NONE);
	if (inputStream == NULL) {
	    xmlFreeParserInputBuffer(buf);
	    goto error;
	}
	inputPush(ctxt, inputStream);

	/* do the parsing */
	xmlParseDocument(ctxt);

	if (ctxt->myDoc != NULL) {
	    fprintf(stderr, "SAX generated a doc !\n");
	    xmlFreeDoc(ctxt->myDoc);
	    ctxt->myDoc = NULL;
	}
    }

error:
    if (ctxt != NULL) {
        ctxt->sax = old_sax;
        xmlFreeParserCtxt(ctxt);
    }
}

/************************************************************************
 *									*
 *			Stream Test processing				*
 *									*
 ************************************************************************/
#ifdef LIBXML_READER_ENABLED
static void processNode(xmlTextReaderPtr reader) {
    const xmlChar *name, *value;
    int type, empty;

    type = xmlTextReaderNodeType(reader);
    empty = xmlTextReaderIsEmptyElement(reader);

    if (debug) {
	name = xmlTextReaderConstName(reader);
	if (name == NULL)
	    name = BAD_CAST "--";

	value = xmlTextReaderConstValue(reader);


	printf("%d %d %s %d %d",
		xmlTextReaderDepth(reader),
		type,
		name,
		empty,
		xmlTextReaderHasValue(reader));
	if (value == NULL)
	    printf("\n");
	else {
	    printf(" %s\n", value);
	}
    }
#ifdef LIBXML_PATTERN_ENABLED
    if (patternc) {
        xmlChar *path = NULL;
        int match = -1;

	if (type == XML_READER_TYPE_ELEMENT) {
	    /* do the check only on element start */
	    match = xmlPatternMatch(patternc, xmlTextReaderCurrentNode(reader));

	    if (match) {
#if defined(LIBXML_TREE_ENABLED) || defined(LIBXML_DEBUG_ENABLED)
		path = xmlGetNodePath(xmlTextReaderCurrentNode(reader));
		printf("Node %s matches pattern %s\n", path, pattern);
#else
                printf("Node %s matches pattern %s\n",
                       xmlTextReaderConstName(reader), pattern);
#endif
	    }
	}
	if (patstream != NULL) {
	    int ret;

	    if (type == XML_READER_TYPE_ELEMENT) {
		ret = xmlStreamPush(patstream,
		                    xmlTextReaderConstLocalName(reader),
				    xmlTextReaderConstNamespaceUri(reader));
		if (ret < 0) {
		    fprintf(stderr, "xmlStreamPush() failure\n");
                    xmlFreeStreamCtxt(patstream);
		    patstream = NULL;
		} else if (ret != match) {
#if defined(LIBXML_TREE_ENABLED) || defined(LIBXML_DEBUG_ENABLED)
		    if (path == NULL) {
		        path = xmlGetNodePath(
		                       xmlTextReaderCurrentNode(reader));
		    }
#endif
		    fprintf(stderr,
		            "xmlPatternMatch and xmlStreamPush disagree\n");
                    if (path != NULL)
                        fprintf(stderr, "  pattern %s node %s\n",
                                pattern, path);
                    else
		        fprintf(stderr, "  pattern %s node %s\n",
			    pattern, xmlTextReaderConstName(reader));
		}

	    }
	    if ((type == XML_READER_TYPE_END_ELEMENT) ||
	        ((type == XML_READER_TYPE_ELEMENT) && (empty))) {
	        ret = xmlStreamPop(patstream);
		if (ret < 0) {
		    fprintf(stderr, "xmlStreamPop() failure\n");
                    xmlFreeStreamCtxt(patstream);
		    patstream = NULL;
		}
	    }
	}
	if (path != NULL)
	    xmlFree(path);
    }
#endif
}

static void streamFile(char *filename) {
    xmlTextReaderPtr reader;
    int ret;
#ifdef HAVE_SYS_MMAN_H
    int fd = -1;
    struct stat info;
    const char *base = NULL;
    xmlParserInputBufferPtr input = NULL;

    if (memory) {
	if (stat(filename, &info) < 0)
	    return;
	if ((fd = open(filename, O_RDONLY)) < 0)
	    return;
	base = mmap(NULL, info.st_size, PROT_READ, MAP_SHARED, fd, 0) ;
	if (base == (void *) MAP_FAILED)
	    return;

	reader = xmlReaderForMemory(base, info.st_size, filename,
	                            NULL, options);
    } else
#endif
	reader = xmlReaderForFile(filename, NULL, options);
#ifdef LIBXML_PATTERN_ENABLED
    if (pattern != NULL) {
        patternc = xmlPatterncompile((const xmlChar *) pattern, NULL, 0, NULL);
	if (patternc == NULL) {
	    xmlGenericError(xmlGenericErrorContext,
		    "Pattern %s failed to compile\n", pattern);
            progresult = XMLLINT_ERR_SCHEMAPAT;
	    pattern = NULL;
	}
    }
    if (patternc != NULL) {
        patstream = xmlPatternGetStreamCtxt(patternc);
	if (patstream != NULL) {
	    ret = xmlStreamPush(patstream, NULL, NULL);
	    if (ret < 0) {
		fprintf(stderr, "xmlStreamPush() failure\n");
		xmlFreeStreamCtxt(patstream);
		patstream = NULL;
            }
	}
    }
#endif


    if (reader != NULL) {
#ifdef LIBXML_VALID_ENABLED
	if (valid)
	    xmlTextReaderSetParserProp(reader, XML_PARSER_VALIDATE, 1);
	else
#endif /* LIBXML_VALID_ENABLED */
	    xmlTextReaderSetParserProp(reader, XML_PARSER_LOADDTD, 1);
#ifdef LIBXML_SCHEMAS_ENABLED
	if (relaxng != NULL) {
	    if ((timing) && (!repeat)) {
		startTimer();
	    }
	    ret = xmlTextReaderRelaxNGValidate(reader, relaxng);
	    if (ret < 0) {
		xmlGenericError(xmlGenericErrorContext,
			"Relax-NG schema %s failed to compile\n", relaxng);
		progresult = XMLLINT_ERR_SCHEMACOMP;
		relaxng = NULL;
	    }
	    if ((timing) && (!repeat)) {
		endTimer("Compiling the schemas");
	    }
	}
	if (schema != NULL) {
	    if ((timing) && (!repeat)) {
		startTimer();
	    }
	    ret = xmlTextReaderSchemaValidate(reader, schema);
	    if (ret < 0) {
		xmlGenericError(xmlGenericErrorContext,
			"XSD schema %s failed to compile\n", schema);
		progresult = XMLLINT_ERR_SCHEMACOMP;
		schema = NULL;
	    }
	    if ((timing) && (!repeat)) {
		endTimer("Compiling the schemas");
	    }
	}
#endif

	/*
	 * Process all nodes in sequence
	 */
	if ((timing) && (!repeat)) {
	    startTimer();
	}
	ret = xmlTextReaderRead(reader);
	while (ret == 1) {
	    if ((debug)
#ifdef LIBXML_PATTERN_ENABLED
	        || (patternc)
#endif
	       )
		processNode(reader);
	    ret = xmlTextReaderRead(reader);
	}
	if ((timing) && (!repeat)) {
#ifdef LIBXML_SCHEMAS_ENABLED
	    if (relaxng != NULL)
		endTimer("Parsing and validating");
	    else
#endif
#ifdef LIBXML_VALID_ENABLED
	    if (valid)
		endTimer("Parsing and validating");
	    else
#endif
	    endTimer("Parsing");
	}

#ifdef LIBXML_VALID_ENABLED
	if (valid) {
	    if (xmlTextReaderIsValid(reader) != 1) {
		xmlGenericError(xmlGenericErrorContext,
			"Document %s does not validate\n", filename);
		progresult = XMLLINT_ERR_VALID;
	    }
	}
#endif /* LIBXML_VALID_ENABLED */
#ifdef LIBXML_SCHEMAS_ENABLED
	if ((relaxng != NULL) || (schema != NULL)) {
	    if (xmlTextReaderIsValid(reader) != 1) {
		fprintf(stderr, "%s fails to validate\n", filename);
		progresult = XMLLINT_ERR_VALID;
	    } else {
		fprintf(stderr, "%s validates\n", filename);
	    }
	}
#endif
	/*
	 * Done, cleanup and status
	 */
	xmlFreeTextReader(reader);
	if (ret != 0) {
	    fprintf(stderr, "%s : failed to parse\n", filename);
	    progresult = XMLLINT_ERR_UNCLASS;
	}
    } else {
	fprintf(stderr, "Unable to open %s\n", filename);
	progresult = XMLLINT_ERR_UNCLASS;
    }
#ifdef LIBXML_PATTERN_ENABLED
    if (patstream != NULL) {
	xmlFreeStreamCtxt(patstream);
	patstream = NULL;
    }
#endif
#ifdef HAVE_SYS_MMAN_H
    if (memory) {
        xmlFreeParserInputBuffer(input);
	munmap((char *) base, info.st_size);
	close(fd);
    }
#endif
}

static void walkDoc(xmlDocPtr doc) {
    xmlTextReaderPtr reader;
    int ret;

#ifdef LIBXML_PATTERN_ENABLED
    xmlNodePtr root;
    const xmlChar *namespaces[22];
    int i;
    xmlNsPtr ns;

    root = xmlDocGetRootElement(doc);
    for (ns = root->nsDef, i = 0;ns != NULL && i < 20;ns=ns->next) {
        namespaces[i++] = ns->href;
        namespaces[i++] = ns->prefix;
    }
    namespaces[i++] = NULL;
    namespaces[i] = NULL;

    if (pattern != NULL) {
        patternc = xmlPatterncompile((const xmlChar *) pattern, doc->dict,
	                             0, &namespaces[0]);
	if (patternc == NULL) {
	    xmlGenericError(xmlGenericErrorContext,
		    "Pattern %s failed to compile\n", pattern);
            progresult = XMLLINT_ERR_SCHEMAPAT;
	    pattern = NULL;
	}
    }
    if (patternc != NULL) {
        patstream = xmlPatternGetStreamCtxt(patternc);
	if (patstream != NULL) {
	    ret = xmlStreamPush(patstream, NULL, NULL);
	    if (ret < 0) {
		fprintf(stderr, "xmlStreamPush() failure\n");
		xmlFreeStreamCtxt(patstream);
		patstream = NULL;
            }
	}
    }
#endif /* LIBXML_PATTERN_ENABLED */
    reader = xmlReaderWalker(doc);
    if (reader != NULL) {
	if ((timing) && (!repeat)) {
	    startTimer();
	}
	ret = xmlTextReaderRead(reader);
	while (ret == 1) {
	    if ((debug)
#ifdef LIBXML_PATTERN_ENABLED
	        || (patternc)
#endif
	       )
		processNode(reader);
	    ret = xmlTextReaderRead(reader);
	}
	if ((timing) && (!repeat)) {
	    endTimer("walking through the doc");
	}
	xmlFreeTextReader(reader);
	if (ret != 0) {
	    fprintf(stderr, "failed to walk through the doc\n");
	    progresult = XMLLINT_ERR_UNCLASS;
	}
    } else {
	fprintf(stderr, "Failed to crate a reader from the document\n");
	progresult = XMLLINT_ERR_UNCLASS;
    }
#ifdef LIBXML_PATTERN_ENABLED
    if (patstream != NULL) {
	xmlFreeStreamCtxt(patstream);
	patstream = NULL;
    }
#endif
}
#endif /* LIBXML_READER_ENABLED */

#ifdef LIBXML_XPATH_ENABLED
/************************************************************************
 *									*
 *			XPath Query                                     *
 *									*
 ************************************************************************/

static void doXPathDump(xmlXPathObjectPtr cur) {
    switch(cur->type) {
        case XPATH_NODESET: {
            int i;
            xmlNodePtr node;
#ifdef LIBXML_OUTPUT_ENABLED
            xmlSaveCtxtPtr ctxt;

            if (cur->nodesetval->nodeNr <= 0) {
                fprintf(stderr, "XPath set is empty\n");
                progresult = XMLLINT_ERR_XPATH;
                break;
            }
            ctxt = xmlSaveToFd(1, NULL, 0);
            if (ctxt == NULL) {
                fprintf(stderr, "Out of memory for XPath\n");
                progresult = XMLLINT_ERR_MEM;
                return;
            }
            for (i = 0;i < cur->nodesetval->nodeNr;i++) {
                node = cur->nodesetval->nodeTab[i];
                xmlSaveTree(ctxt, node);
            }
            xmlSaveClose(ctxt);
#else
            printf("xpath returned %d nodes\n", cur->nodesetval->nodeNr);
#endif
	    break;
        }
        case XPATH_BOOLEAN:
	    if (cur->boolval) printf("true");
	    else printf("false");
	    break;
        case XPATH_NUMBER:
	    switch (xmlXPathIsInf(cur->floatval)) {
	    case 1:
		printf("Infinity");
		break;
	    case -1:
		printf("-Infinity");
		break;
	    default:
		if (xmlXPathIsNaN(cur->floatval)) {
		    printf("NaN");
		} else {
		    printf("%0g", cur->floatval);
		}
	    }
	    break;
        case XPATH_STRING:
	    printf("%s", (const char *) cur->stringval);
	    break;
        case XPATH_UNDEFINED:
	    fprintf(stderr, "XPath Object is uninitialized\n");
            progresult = XMLLINT_ERR_XPATH;
	    break;
	default:
	    fprintf(stderr, "XPath object of unexpected type\n");
            progresult = XMLLINT_ERR_XPATH;
	    break;
    }
}

static void doXPathQuery(xmlDocPtr doc, const char *query) {
    xmlXPathContextPtr ctxt;
    xmlXPathObjectPtr res;

    ctxt = xmlXPathNewContext(doc);
    if (ctxt == NULL) {
        fprintf(stderr, "Out of memory for XPath\n");
        progresult = XMLLINT_ERR_MEM;
        return;
    }
    ctxt->node = xmlDocGetRootElement(doc);
    res = xmlXPathEval(BAD_CAST query, ctxt);
    xmlXPathFreeContext(ctxt);

    if (res == NULL) {
        fprintf(stderr, "XPath evaluation failure\n");
        progresult = XMLLINT_ERR_XPATH;
        return;
    }
    doXPathDump(res);
    xmlXPathFreeObject(res);
}
#endif /* LIBXML_XPATH_ENABLED */

/************************************************************************
 *									*
 *			Tree Test processing				*
 *									*
 ************************************************************************/
static void parseAndPrintFile(char *filename, xmlParserCtxtPtr rectxt) {
    xmlDocPtr doc = NULL;
#ifdef LIBXML_TREE_ENABLED
    xmlDocPtr tmp;
#endif /* LIBXML_TREE_ENABLED */

    if ((timing) && (!repeat))
	startTimer();


#ifdef LIBXML_TREE_ENABLED
    if (filename == NULL) {
	if (generate) {
	    xmlNodePtr n;

	    doc = xmlNewDoc(BAD_CAST "1.0");
	    n = xmlNewDocNode(doc, NULL, BAD_CAST "info", NULL);
	    xmlNodeSetContent(n, BAD_CAST "abc");
	    xmlDocSetRootElement(doc, n);
	}
    }
#endif /* LIBXML_TREE_ENABLED */
#ifdef LIBXML_HTML_ENABLED
#ifdef LIBXML_PUSH_ENABLED
    else if ((html) && (push)) {
        FILE *f;

#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
	f = fopen(filename, "rb");
#else
	f = fopen(filename, "r");
#endif
        if (f != NULL) {
            int res, size = 3;
            char chars[4096];
            htmlParserCtxtPtr ctxt;

            /* if (repeat) */
                size = 4096;
            res = fread(chars, 1, 4, f);
            if (res > 0) {
                ctxt = htmlCreatePushParserCtxt(NULL, NULL,
                            chars, res, filename, XML_CHAR_ENCODING_NONE);
                while ((res = fread(chars, 1, size, f)) > 0) {
                    htmlParseChunk(ctxt, chars, res, 0);
                }
                htmlParseChunk(ctxt, chars, 0, 1);
                doc = ctxt->myDoc;
                htmlFreeParserCtxt(ctxt);
            }
            fclose(f);
        }
    }
#endif /* LIBXML_PUSH_ENABLED */
#ifdef HAVE_SYS_MMAN_H
    else if ((html) && (memory)) {
	int fd;
	struct stat info;
	const char *base;
	if (stat(filename, &info) < 0)
	    return;
	if ((fd = open(filename, O_RDONLY)) < 0)
	    return;
	base = mmap(NULL, info.st_size, PROT_READ, MAP_SHARED, fd, 0) ;
	if (base == (void *) MAP_FAILED)
	    return;

	doc = htmlReadMemory((char *) base, info.st_size, filename,
	                     NULL, options);

	munmap((char *) base, info.st_size);
	close(fd);
    }
#endif
    else if (html) {
	doc = htmlReadFile(filename, NULL, options);
    }
#endif /* LIBXML_HTML_ENABLED */
    else {
#ifdef LIBXML_PUSH_ENABLED
	/*
	 * build an XML tree from a string;
	 */
	if (push) {
	    FILE *f;

	    /* '-' Usually means stdin -<sven@zen.org> */
	    if ((filename[0] == '-') && (filename[1] == 0)) {
	      f = stdin;
	    } else {
#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
		f = fopen(filename, "rb");
#else
		f = fopen(filename, "r");
#endif
	    }
	    if (f != NULL) {
		int ret;
	        int res, size = 1024;
	        char chars[1024];
                xmlParserCtxtPtr ctxt;

		/* if (repeat) size = 1024; */
		res = fread(chars, 1, 4, f);
		if (res > 0) {
		    ctxt = xmlCreatePushParserCtxt(NULL, NULL,
		                chars, res, filename);
		    xmlCtxtUseOptions(ctxt, options);
		    while ((res = fread(chars, 1, size, f)) > 0) {
			xmlParseChunk(ctxt, chars, res, 0);
		    }
		    xmlParseChunk(ctxt, chars, 0, 1);
		    doc = ctxt->myDoc;
		    ret = ctxt->wellFormed;
		    xmlFreeParserCtxt(ctxt);
		    if (!ret) {
			xmlFreeDoc(doc);
			doc = NULL;
		    }
	        }
                if (f != stdin)
                    fclose(f);
	    }
	} else
#endif /* LIBXML_PUSH_ENABLED */
        if (testIO) {
	    if ((filename[0] == '-') && (filename[1] == 0)) {
	        doc = xmlReadFd(0, NULL, NULL, options);
	    } else {
	        FILE *f;

#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
		f = fopen(filename, "rb");
#else
		f = fopen(filename, "r");
#endif
		if (f != NULL) {
		    if (rectxt == NULL)
			doc = xmlReadIO((xmlInputReadCallback) myRead,
					(xmlInputCloseCallback) myClose, f,
					filename, NULL, options);
		    else
			doc = xmlCtxtReadIO(rectxt,
			                (xmlInputReadCallback) myRead,
					(xmlInputCloseCallback) myClose, f,
					filename, NULL, options);
		} else
		    doc = NULL;
	    }
	} else if (htmlout) {
	    xmlParserCtxtPtr ctxt;

	    if (rectxt == NULL)
		ctxt = xmlNewParserCtxt();
	    else
	        ctxt = rectxt;
	    if (ctxt == NULL) {
	        doc = NULL;
	    } else {
	        ctxt->sax->error = xmlHTMLError;
	        ctxt->sax->warning = xmlHTMLWarning;
	        ctxt->vctxt.error = xmlHTMLValidityError;
	        ctxt->vctxt.warning = xmlHTMLValidityWarning;

		doc = xmlCtxtReadFile(ctxt, filename, NULL, options);

		if (rectxt == NULL)
		    xmlFreeParserCtxt(ctxt);
	    }
#ifdef HAVE_SYS_MMAN_H
	} else if (memory) {
	    int fd;
	    struct stat info;
	    const char *base;
	    if (stat(filename, &info) < 0)
		return;
	    if ((fd = open(filename, O_RDONLY)) < 0)
		return;
	    base = mmap(NULL, info.st_size, PROT_READ, MAP_SHARED, fd, 0) ;
	    if (base == (void *) MAP_FAILED)
	        return;

	    if (rectxt == NULL)
		doc = xmlReadMemory((char *) base, info.st_size,
		                    filename, NULL, options);
	    else
		doc = xmlCtxtReadMemory(rectxt, (char *) base, info.st_size,
			                filename, NULL, options);

	    munmap((char *) base, info.st_size);
	    close(fd);
#endif
#ifdef LIBXML_VALID_ENABLED
	} else if (valid) {
	    xmlParserCtxtPtr ctxt = NULL;

	    if (rectxt == NULL)
		ctxt = xmlNewParserCtxt();
	    else
	        ctxt = rectxt;
	    if (ctxt == NULL) {
	        doc = NULL;
	    } else {
		doc = xmlCtxtReadFile(ctxt, filename, NULL, options);

		if (ctxt->valid == 0)
		    progresult = XMLLINT_ERR_RDFILE;
		if (rectxt == NULL)
		    xmlFreeParserCtxt(ctxt);
	    }
#endif /* LIBXML_VALID_ENABLED */
	} else {
	    if (rectxt != NULL)
	        doc = xmlCtxtReadFile(rectxt, filename, NULL, options);
	    else {
#ifdef LIBXML_SAX1_ENABLED
                if (sax1)
		    doc = xmlParseFile(filename);
		else
#endif /* LIBXML_SAX1_ENABLED */
		doc = xmlReadFile(filename, NULL, options);
	    }
	}
    }

    /*
     * If we don't have a document we might as well give up.  Do we
     * want an error message here?  <sven@zen.org> */
    if (doc == NULL) {
	progresult = XMLLINT_ERR_UNCLASS;
	return;
    }

    if ((timing) && (!repeat)) {
	endTimer("Parsing");
    }

    /*
     * Remove DOCTYPE nodes
     */
    if (dropdtd) {
	xmlDtdPtr dtd;

	dtd = xmlGetIntSubset(doc);
	if (dtd != NULL) {
	    xmlUnlinkNode((xmlNodePtr)dtd);
	    xmlFreeDtd(dtd);
	}
    }

#ifdef LIBXML_XINCLUDE_ENABLED
    if (xinclude) {
	if ((timing) && (!repeat)) {
	    startTimer();
	}
	if (xmlXIncludeProcessFlags(doc, options) < 0)
	    progresult = XMLLINT_ERR_UNCLASS;
	if ((timing) && (!repeat)) {
	    endTimer("Xinclude processing");
	}
    }
#endif

#ifdef LIBXML_XPATH_ENABLED
    if (xpathquery != NULL) {
        doXPathQuery(doc, xpathquery);
    }
#endif

#ifdef LIBXML_DEBUG_ENABLED
#ifdef LIBXML_XPATH_ENABLED
    /*
     * shell interaction
     */
    if (shell) {
        xmlXPathOrderDocElems(doc);
        xmlShell(doc, filename, xmlShellReadline, stdout);
    }
#endif
#endif

#ifdef LIBXML_TREE_ENABLED
    /*
     * test intermediate copy if needed.
     */
    if (copy) {
        tmp = doc;
	if (timing) {
	    startTimer();
	}
	doc = xmlCopyDoc(doc, 1);
	if (timing) {
	    endTimer("Copying");
	}
	if (timing) {
	    startTimer();
	}
	xmlFreeDoc(tmp);
	if (timing) {
	    endTimer("Freeing original");
	}
    }
#endif /* LIBXML_TREE_ENABLED */

#ifdef LIBXML_VALID_ENABLED
    if ((insert) && (!html)) {
        const xmlChar* list[256];
	int nb, i;
	xmlNodePtr node;

	if (doc->children != NULL) {
	    node = doc->children;
	    while ((node != NULL) && (node->last == NULL)) node = node->next;
	    if (node != NULL) {
		nb = xmlValidGetValidElements(node->last, NULL, list, 256);
		if (nb < 0) {
		    fprintf(stderr, "could not get valid list of elements\n");
		} else if (nb == 0) {
		    fprintf(stderr, "No element can be inserted under root\n");
		} else {
		    fprintf(stderr, "%d element types can be inserted under root:\n",
		           nb);
		    for (i = 0;i < nb;i++) {
			 fprintf(stderr, "%s\n", (char *) list[i]);
		    }
		}
	    }
	}
    }else
#endif /* LIBXML_VALID_ENABLED */
#ifdef LIBXML_READER_ENABLED
    if (walker) {
        walkDoc(doc);
    }
#endif /* LIBXML_READER_ENABLED */
#ifdef LIBXML_OUTPUT_ENABLED
    if (noout == 0) {
        int ret;

	/*
	 * print it.
	 */
#ifdef LIBXML_DEBUG_ENABLED
	if (!debug) {
#endif
	    if ((timing) && (!repeat)) {
		startTimer();
	    }
#ifdef LIBXML_HTML_ENABLED
            if ((html) && (!xmlout)) {
		if (compress) {
		    htmlSaveFile(output ? output : "-", doc);
		}
		else if (encoding != NULL) {
		    if ( format ) {
			htmlSaveFileFormat(output ? output : "-", doc, encoding, 1);
		    }
		    else {
			htmlSaveFileFormat(output ? output : "-", doc, encoding, 0);
		    }
		}
		else if (format) {
		    htmlSaveFileFormat(output ? output : "-", doc, NULL, 1);
		}
		else {
		    FILE *out;
		    if (output == NULL)
			out = stdout;
		    else {
			out = fopen(output,"wb");
		    }
		    if (out != NULL) {
			if (htmlDocDump(out, doc) < 0)
			    progresult = XMLLINT_ERR_OUT;

			if (output != NULL)
			    fclose(out);
		    } else {
			fprintf(stderr, "failed to open %s\n", output);
			progresult = XMLLINT_ERR_OUT;
		    }
		}
		if ((timing) && (!repeat)) {
		    endTimer("Saving");
		}
	    } else
#endif
#ifdef LIBXML_C14N_ENABLED
            if (canonical) {
	        xmlChar *result = NULL;
		int size;

		size = xmlC14NDocDumpMemory(doc, NULL, XML_C14N_1_0, NULL, 1, &result);
		if (size >= 0) {
		    write(1, result, size);
		    xmlFree(result);
		} else {
		    fprintf(stderr, "Failed to canonicalize\n");
		    progresult = XMLLINT_ERR_OUT;
		}
	    } else if (canonical) {
	        xmlChar *result = NULL;
		int size;

		size = xmlC14NDocDumpMemory(doc, NULL, XML_C14N_1_1, NULL, 1, &result);
		if (size >= 0) {
		    write(1, result, size);
		    xmlFree(result);
		} else {
		    fprintf(stderr, "Failed to canonicalize\n");
		    progresult = XMLLINT_ERR_OUT;
		}
	    } else
            if (exc_canonical) {
	        xmlChar *result = NULL;
		int size;

		size = xmlC14NDocDumpMemory(doc, NULL, XML_C14N_EXCLUSIVE_1_0, NULL, 1, &result);
		if (size >= 0) {
		    write(1, result, size);
		    xmlFree(result);
		} else {
		    fprintf(stderr, "Failed to canonicalize\n");
		    progresult = XMLLINT_ERR_OUT;
		}
	    } else
#endif
#ifdef HAVE_SYS_MMAN_H
	    if (memory) {
		xmlChar *result;
		int len;

		if (encoding != NULL) {
		    if ( format ) {
		        xmlDocDumpFormatMemoryEnc(doc, &result, &len, encoding, 1);
		    } else {
			xmlDocDumpMemoryEnc(doc, &result, &len, encoding);
		    }
		} else {
		    if (format)
			xmlDocDumpFormatMemory(doc, &result, &len, 1);
		    else
			xmlDocDumpMemory(doc, &result, &len);
		}
		if (result == NULL) {
		    fprintf(stderr, "Failed to save\n");
		    progresult = XMLLINT_ERR_OUT;
		} else {
		    write(1, result, len);
		    xmlFree(result);
		}

	    } else
#endif /* HAVE_SYS_MMAN_H */
	    if (compress) {
		xmlSaveFile(output ? output : "-", doc);
	    } else if (oldout) {
	        if (encoding != NULL) {
		    if ( format ) {
			ret = xmlSaveFormatFileEnc(output ? output : "-", doc,
						   encoding, 1);
		    }
		    else {
			ret = xmlSaveFileEnc(output ? output : "-", doc,
			                     encoding);
		    }
		    if (ret < 0) {
			fprintf(stderr, "failed save to %s\n",
				output ? output : "-");
			progresult = XMLLINT_ERR_OUT;
		    }
		} else if (format) {
		    ret = xmlSaveFormatFile(output ? output : "-", doc, 1);
		    if (ret < 0) {
			fprintf(stderr, "failed save to %s\n",
				output ? output : "-");
			progresult = XMLLINT_ERR_OUT;
		    }
		} else {
		    FILE *out;
		    if (output == NULL)
			out = stdout;
		    else {
			out = fopen(output,"wb");
		    }
		    if (out != NULL) {
			if (xmlDocDump(out, doc) < 0)
			    progresult = XMLLINT_ERR_OUT;

			if (output != NULL)
			    fclose(out);
		    } else {
			fprintf(stderr, "failed to open %s\n", output);
			progresult = XMLLINT_ERR_OUT;
		    }
		}
	    } else {
	        xmlSaveCtxtPtr ctxt;
		int saveOpts = 0;

                if (format)
		    saveOpts |= XML_SAVE_FORMAT;

#if defined(LIBXML_HTML_ENABLED) || defined(LIBXML_VALID_ENABLED)
                if (xmlout)
                    saveOpts |= XML_SAVE_AS_XML;
#endif

		if (output == NULL)
		    ctxt = xmlSaveToFd(1, encoding, saveOpts);
		else
		    ctxt = xmlSaveToFilename(output, encoding, saveOpts);

		if (ctxt != NULL) {
		    if (xmlSaveDoc(ctxt, doc) < 0) {
			fprintf(stderr, "failed save to %s\n",
				output ? output : "-");
			progresult = XMLLINT_ERR_OUT;
		    }
		    xmlSaveClose(ctxt);
		} else {
		    progresult = XMLLINT_ERR_OUT;
		}
	    }
	    if ((timing) && (!repeat)) {
		endTimer("Saving");
	    }
#ifdef LIBXML_DEBUG_ENABLED
	} else {
	    FILE *out;
	    if (output == NULL)
	        out = stdout;
	    else {
		out = fopen(output,"wb");
	    }
	    if (out != NULL) {
		xmlDebugDumpDocument(out, doc);

		if (output != NULL)
		    fclose(out);
	    } else {
		fprintf(stderr, "failed to open %s\n", output);
		progresult = XMLLINT_ERR_OUT;
	    }
	}
#endif
    }
#endif /* LIBXML_OUTPUT_ENABLED */

#ifdef LIBXML_VALID_ENABLED
    /*
     * A posteriori validation test
     */
    if ((dtdvalid != NULL) || (dtdvalidfpi != NULL)) {
	xmlDtdPtr dtd;

	if ((timing) && (!repeat)) {
	    startTimer();
	}
	if (dtdvalid != NULL)
	    dtd = xmlParseDTD(NULL, (const xmlChar *)dtdvalid);
	else
	    dtd = xmlParseDTD((const xmlChar *)dtdvalidfpi, NULL);
	if ((timing) && (!repeat)) {
	    endTimer("Parsing DTD");
	}
	if (dtd == NULL) {
	    if (dtdvalid != NULL)
		xmlGenericError(xmlGenericErrorContext,
			"Could not parse DTD %s\n", dtdvalid);
	    else
		xmlGenericError(xmlGenericErrorContext,
			"Could not parse DTD %s\n", dtdvalidfpi);
	    progresult = XMLLINT_ERR_DTD;
	} else {
	    xmlValidCtxtPtr cvp;

	    if ((cvp = xmlNewValidCtxt()) == NULL) {
		xmlGenericError(xmlGenericErrorContext,
			"Couldn't allocate validation context\n");
		exit(-1);
	    }
	    cvp->userData = (void *) stderr;
	    cvp->error    = (xmlValidityErrorFunc) fprintf;
	    cvp->warning  = (xmlValidityWarningFunc) fprintf;

	    if ((timing) && (!repeat)) {
		startTimer();
	    }
	    if (!xmlValidateDtd(cvp, doc, dtd)) {
		if (dtdvalid != NULL)
		    xmlGenericError(xmlGenericErrorContext,
			    "Document %s does not validate against %s\n",
			    filename, dtdvalid);
		else
		    xmlGenericError(xmlGenericErrorContext,
			    "Document %s does not validate against %s\n",
			    filename, dtdvalidfpi);
		progresult = XMLLINT_ERR_VALID;
	    }
	    if ((timing) && (!repeat)) {
		endTimer("Validating against DTD");
	    }
	    xmlFreeValidCtxt(cvp);
	    xmlFreeDtd(dtd);
	}
    } else if (postvalid) {
	xmlValidCtxtPtr cvp;

	if ((cvp = xmlNewValidCtxt()) == NULL) {
	    xmlGenericError(xmlGenericErrorContext,
		    "Couldn't allocate validation context\n");
	    exit(-1);
	}

	if ((timing) && (!repeat)) {
	    startTimer();
	}
	cvp->userData = (void *) stderr;
	cvp->error    = (xmlValidityErrorFunc) fprintf;
	cvp->warning  = (xmlValidityWarningFunc) fprintf;
	if (!xmlValidateDocument(cvp, doc)) {
	    xmlGenericError(xmlGenericErrorContext,
		    "Document %s does not validate\n", filename);
	    progresult = XMLLINT_ERR_VALID;
	}
	if ((timing) && (!repeat)) {
	    endTimer("Validating");
	}
	xmlFreeValidCtxt(cvp);
    }
#endif /* LIBXML_VALID_ENABLED */
#ifdef LIBXML_SCHEMATRON_ENABLED
    if (wxschematron != NULL) {
	xmlSchematronValidCtxtPtr ctxt;
	int ret;
	int flag;

	if ((timing) && (!repeat)) {
	    startTimer();
	}

	if (debug)
	    flag = XML_SCHEMATRON_OUT_XML;
	else
	    flag = XML_SCHEMATRON_OUT_TEXT;
	if (noout)
	    flag |= XML_SCHEMATRON_OUT_QUIET;
	ctxt = xmlSchematronNewValidCtxt(wxschematron, flag);
#if 0
	xmlSchematronSetValidErrors(ctxt,
		(xmlSchematronValidityErrorFunc) fprintf,
		(xmlSchematronValidityWarningFunc) fprintf,
		stderr);
#endif
	ret = xmlSchematronValidateDoc(ctxt, doc);
	if (ret == 0) {
	    fprintf(stderr, "%s validates\n", filename);
	} else if (ret > 0) {
	    fprintf(stderr, "%s fails to validate\n", filename);
	    progresult = XMLLINT_ERR_VALID;
	} else {
	    fprintf(stderr, "%s validation generated an internal error\n",
		   filename);
	    progresult = XMLLINT_ERR_VALID;
	}
	xmlSchematronFreeValidCtxt(ctxt);
	if ((timing) && (!repeat)) {
	    endTimer("Validating");
	}
    }
#endif
#ifdef LIBXML_SCHEMAS_ENABLED
    if (relaxngschemas != NULL) {
	xmlRelaxNGValidCtxtPtr ctxt;
	int ret;

	if ((timing) && (!repeat)) {
	    startTimer();
	}

	ctxt = xmlRelaxNGNewValidCtxt(relaxngschemas);
	xmlRelaxNGSetValidErrors(ctxt,
		(xmlRelaxNGValidityErrorFunc) fprintf,
		(xmlRelaxNGValidityWarningFunc) fprintf,
		stderr);
	ret = xmlRelaxNGValidateDoc(ctxt, doc);
	if (ret == 0) {
	    fprintf(stderr, "%s validates\n", filename);
	} else if (ret > 0) {
	    fprintf(stderr, "%s fails to validate\n", filename);
	    progresult = XMLLINT_ERR_VALID;
	} else {
	    fprintf(stderr, "%s validation generated an internal error\n",
		   filename);
	    progresult = XMLLINT_ERR_VALID;
	}
	xmlRelaxNGFreeValidCtxt(ctxt);
	if ((timing) && (!repeat)) {
	    endTimer("Validating");
	}
    } else if (wxschemas != NULL) {
	xmlSchemaValidCtxtPtr ctxt;
	int ret;

	if ((timing) && (!repeat)) {
	    startTimer();
	}

	ctxt = xmlSchemaNewValidCtxt(wxschemas);
	xmlSchemaSetValidErrors(ctxt,
		(xmlSchemaValidityErrorFunc) fprintf,
		(xmlSchemaValidityWarningFunc) fprintf,
		stderr);
	ret = xmlSchemaValidateDoc(ctxt, doc);
	if (ret == 0) {
	    fprintf(stderr, "%s validates\n", filename);
	} else if (ret > 0) {
	    fprintf(stderr, "%s fails to validate\n", filename);
	    progresult = XMLLINT_ERR_VALID;
	} else {
	    fprintf(stderr, "%s validation generated an internal error\n",
		   filename);
	    progresult = XMLLINT_ERR_VALID;
	}
	xmlSchemaFreeValidCtxt(ctxt);
	if ((timing) && (!repeat)) {
	    endTimer("Validating");
	}
    }
#endif

#ifdef LIBXML_DEBUG_ENABLED
#if defined(LIBXML_HTML_ENABLED) || defined(LIBXML_VALID_ENABLED)
    if ((debugent) && (!html))
	xmlDebugDumpEntities(stderr, doc);
#endif
#endif

    /*
     * free it.
     */
    if ((timing) && (!repeat)) {
	startTimer();
    }
    xmlFreeDoc(doc);
    if ((timing) && (!repeat)) {
	endTimer("Freeing");
    }
}

/************************************************************************
 *									*
 *			Usage and Main					*
 *									*
 ************************************************************************/

static void showVersion(const char *name) {
    fprintf(stderr, "%s: using libxml version %s\n", name, xmlParserVersion);
    fprintf(stderr, "   compiled with: ");
    if (xmlHasFeature(XML_WITH_THREAD)) fprintf(stderr, "Threads ");
    if (xmlHasFeature(XML_WITH_TREE)) fprintf(stderr, "Tree ");
    if (xmlHasFeature(XML_WITH_OUTPUT)) fprintf(stderr, "Output ");
    if (xmlHasFeature(XML_WITH_PUSH)) fprintf(stderr, "Push ");
    if (xmlHasFeature(XML_WITH_READER)) fprintf(stderr, "Reader ");
    if (xmlHasFeature(XML_WITH_PATTERN)) fprintf(stderr, "Patterns ");
    if (xmlHasFeature(XML_WITH_WRITER)) fprintf(stderr, "Writer ");
    if (xmlHasFeature(XML_WITH_SAX1)) fprintf(stderr, "SAXv1 ");
    if (xmlHasFeature(XML_WITH_FTP)) fprintf(stderr, "FTP ");
    if (xmlHasFeature(XML_WITH_HTTP)) fprintf(stderr, "HTTP ");
    if (xmlHasFeature(XML_WITH_VALID)) fprintf(stderr, "DTDValid ");
    if (xmlHasFeature(XML_WITH_HTML)) fprintf(stderr, "HTML ");
    if (xmlHasFeature(XML_WITH_LEGACY)) fprintf(stderr, "Legacy ");
    if (xmlHasFeature(XML_WITH_C14N)) fprintf(stderr, "C14N ");
    if (xmlHasFeature(XML_WITH_CATALOG)) fprintf(stderr, "Catalog ");
    if (xmlHasFeature(XML_WITH_XPATH)) fprintf(stderr, "XPath ");
    if (xmlHasFeature(XML_WITH_XPTR)) fprintf(stderr, "XPointer ");
    if (xmlHasFeature(XML_WITH_XINCLUDE)) fprintf(stderr, "XInclude ");
    if (xmlHasFeature(XML_WITH_ICONV)) fprintf(stderr, "Iconv ");
    if (xmlHasFeature(XML_WITH_ISO8859X)) fprintf(stderr, "ISO8859X ");
    if (xmlHasFeature(XML_WITH_UNICODE)) fprintf(stderr, "Unicode ");
    if (xmlHasFeature(XML_WITH_REGEXP)) fprintf(stderr, "Regexps ");
    if (xmlHasFeature(XML_WITH_AUTOMATA)) fprintf(stderr, "Automata ");
    if (xmlHasFeature(XML_WITH_EXPR)) fprintf(stderr, "Expr ");
    if (xmlHasFeature(XML_WITH_SCHEMAS)) fprintf(stderr, "Schemas ");
    if (xmlHasFeature(XML_WITH_SCHEMATRON)) fprintf(stderr, "Schematron ");
    if (xmlHasFeature(XML_WITH_MODULES)) fprintf(stderr, "Modules ");
    if (xmlHasFeature(XML_WITH_DEBUG)) fprintf(stderr, "Debug ");
    if (xmlHasFeature(XML_WITH_DEBUG_MEM)) fprintf(stderr, "MemDebug ");
    if (xmlHasFeature(XML_WITH_DEBUG_RUN)) fprintf(stderr, "RunDebug ");
    if (xmlHasFeature(XML_WITH_ZLIB)) fprintf(stderr, "Zlib ");
    fprintf(stderr, "\n");
}

static void usage(const char *name) {
    printf("Usage : %s [options] XMLfiles ...\n", name);
#ifdef LIBXML_OUTPUT_ENABLED
    printf("\tParse the XML files and output the result of the parsing\n");
#else
    printf("\tParse the XML files\n");
#endif /* LIBXML_OUTPUT_ENABLED */
    printf("\t--version : display the version of the XML library used\n");
#ifdef LIBXML_DEBUG_ENABLED
    printf("\t--debug : dump a debug tree of the in-memory document\n");
    printf("\t--shell : run a navigating shell\n");
    printf("\t--debugent : debug the entities defined in the document\n");
#else
#ifdef LIBXML_READER_ENABLED
    printf("\t--debug : dump the nodes content when using --stream\n");
#endif /* LIBXML_READER_ENABLED */
#endif
#ifdef LIBXML_TREE_ENABLED
    printf("\t--copy : used to test the internal copy implementation\n");
#endif /* LIBXML_TREE_ENABLED */
    printf("\t--recover : output what was parsable on broken XML documents\n");
    printf("\t--huge : remove any internal arbitrary parser limits\n");
    printf("\t--noent : substitute entity references by their value\n");
    printf("\t--noout : don't output the result tree\n");
    printf("\t--path 'paths': provide a set of paths for resources\n");
    printf("\t--load-trace : print trace of all external entites loaded\n");
    printf("\t--nonet : refuse to fetch DTDs or entities over network\n");
    printf("\t--nocompact : do not generate compact text nodes\n");
    printf("\t--htmlout : output results as HTML\n");
    printf("\t--nowrap : do not put HTML doc wrapper\n");
#ifdef LIBXML_VALID_ENABLED
    printf("\t--valid : validate the document in addition to std well-formed check\n");
    printf("\t--postvalid : do a posteriori validation, i.e after parsing\n");
    printf("\t--dtdvalid URL : do a posteriori validation against a given DTD\n");
    printf("\t--dtdvalidfpi FPI : same but name the DTD with a Public Identifier\n");
#endif /* LIBXML_VALID_ENABLED */
    printf("\t--timing : print some timings\n");
    printf("\t--output file or -o file: save to a given file\n");
    printf("\t--repeat : repeat 100 times, for timing or profiling\n");
    printf("\t--insert : ad-hoc test for valid insertions\n");
#ifdef LIBXML_OUTPUT_ENABLED
#ifdef HAVE_ZLIB_H
    printf("\t--compress : turn on gzip compression of output\n");
#endif
#endif /* LIBXML_OUTPUT_ENABLED */
#ifdef LIBXML_HTML_ENABLED
    printf("\t--html : use the HTML parser\n");
    printf("\t--xmlout : force to use the XML serializer when using --html\n");
#endif
#ifdef LIBXML_PUSH_ENABLED
    printf("\t--push : use the push mode of the parser\n");
#endif /* LIBXML_PUSH_ENABLED */
#ifdef HAVE_SYS_MMAN_H
    printf("\t--memory : parse from memory\n");
#endif
    printf("\t--maxmem nbbytes : limits memory allocation to nbbytes bytes\n");
    printf("\t--nowarning : do not emit warnings from parser/validator\n");
    printf("\t--noblanks : drop (ignorable?) blanks spaces\n");
    printf("\t--nocdata : replace cdata section with text nodes\n");
#ifdef LIBXML_OUTPUT_ENABLED
    printf("\t--format : reformat/reindent the input\n");
    printf("\t--encode encoding : output in the given encoding\n");
    printf("\t--dropdtd : remove the DOCTYPE of the input docs\n");
#endif /* LIBXML_OUTPUT_ENABLED */
    printf("\t--c14n : save in W3C canonical format v1.0 (with comments)\n");
    printf("\t--c14n11 : save in W3C canonical format v1.1 (with comments)\n");
    printf("\t--exc-c14n : save in W3C exclusive canonical format (with comments)\n");
#ifdef LIBXML_C14N_ENABLED
#endif /* LIBXML_C14N_ENABLED */
    printf("\t--nsclean : remove redundant namespace declarations\n");
    printf("\t--testIO : test user I/O support\n");
#ifdef LIBXML_CATALOG_ENABLED
    printf("\t--catalogs : use SGML catalogs from $SGML_CATALOG_FILES\n");
    printf("\t             otherwise XML Catalogs starting from \n");
    printf("\t         %s are activated by default\n", XML_XML_DEFAULT_CATALOG);
    printf("\t--nocatalogs: deactivate all catalogs\n");
#endif
    printf("\t--auto : generate a small doc on the fly\n");
#ifdef LIBXML_XINCLUDE_ENABLED
    printf("\t--xinclude : do XInclude processing\n");
    printf("\t--noxincludenode : same but do not generate XInclude nodes\n");
    printf("\t--nofixup-base-uris : do not fixup xml:base uris\n");
#endif
    printf("\t--loaddtd : fetch external DTD\n");
    printf("\t--dtdattr : loaddtd + populate the tree with inherited attributes \n");
#ifdef LIBXML_READER_ENABLED
    printf("\t--stream : use the streaming interface to process very large files\n");
    printf("\t--walker : create a reader and walk though the resulting doc\n");
#endif /* LIBXML_READER_ENABLED */
#ifdef LIBXML_PATTERN_ENABLED
    printf("\t--pattern pattern_value : test the pattern support\n");
#endif
    printf("\t--chkregister : verify the node registration code\n");
#ifdef LIBXML_SCHEMAS_ENABLED
    printf("\t--relaxng schema : do RelaxNG validation against the schema\n");
    printf("\t--schema schema : do validation against the WXS schema\n");
#endif
#ifdef LIBXML_SCHEMATRON_ENABLED
    printf("\t--schematron schema : do validation against a schematron\n");
#endif
#ifdef LIBXML_SAX1_ENABLED
    printf("\t--sax1: use the old SAX1 interfaces for processing\n");
#endif
    printf("\t--sax: do not build a tree but work just at the SAX level\n");
    printf("\t--oldxml10: use XML-1.0 parsing rules before the 5th edition\n");
#ifdef LIBXML_XPATH_ENABLED
    printf("\t--xpath expr: evaluate the XPath expression, inply --noout\n");
#endif

    printf("\nLibxml project home page: http://xmlsoft.org/\n");
    printf("To report bugs or get some help check: http://xmlsoft.org/bugs.html\n");
}

static void registerNode(xmlNodePtr node)
{
    node->_private = malloc(sizeof(long));
    *(long*)node->_private = (long) 0x81726354;
    nbregister++;
}

static void deregisterNode(xmlNodePtr node)
{
    assert(node->_private != NULL);
    assert(*(long*)node->_private == (long) 0x81726354);
    free(node->_private);
    nbregister--;
}

int
main(int argc, char **argv) {
    int i, acount;
    int files = 0;
    int version = 0;
    const char* indent;

    if (argc <= 1) {
	usage(argv[0]);
	return(1);
    }
    LIBXML_TEST_VERSION
    for (i = 1; i < argc ; i++) {
	if (!strcmp(argv[i], "-"))
	    break;

	if (argv[i][0] != '-')
	    continue;
	if ((!strcmp(argv[i], "-debug")) || (!strcmp(argv[i], "--debug")))
	    debug++;
	else
#ifdef LIBXML_DEBUG_ENABLED
	if ((!strcmp(argv[i], "-shell")) ||
	         (!strcmp(argv[i], "--shell"))) {
	    shell++;
            noout = 1;
        } else
#endif
#ifdef LIBXML_TREE_ENABLED
	if ((!strcmp(argv[i], "-copy")) || (!strcmp(argv[i], "--copy")))
	    copy++;
	else
#endif /* LIBXML_TREE_ENABLED */
	if ((!strcmp(argv[i], "-recover")) ||
	         (!strcmp(argv[i], "--recover"))) {
	    recovery++;
	    options |= XML_PARSE_RECOVER;
	} else if ((!strcmp(argv[i], "-huge")) ||
	         (!strcmp(argv[i], "--huge"))) {
	    options |= XML_PARSE_HUGE;
	} else if ((!strcmp(argv[i], "-noent")) ||
	         (!strcmp(argv[i], "--noent"))) {
	    noent++;
	    options |= XML_PARSE_NOENT;
	} else if ((!strcmp(argv[i], "-nsclean")) ||
	         (!strcmp(argv[i], "--nsclean"))) {
	    options |= XML_PARSE_NSCLEAN;
	} else if ((!strcmp(argv[i], "-nocdata")) ||
	         (!strcmp(argv[i], "--nocdata"))) {
	    options |= XML_PARSE_NOCDATA;
	} else if ((!strcmp(argv[i], "-nodict")) ||
	         (!strcmp(argv[i], "--nodict"))) {
	    options |= XML_PARSE_NODICT;
	} else if ((!strcmp(argv[i], "-version")) ||
	         (!strcmp(argv[i], "--version"))) {
	    showVersion(argv[0]);
	    version = 1;
	} else if ((!strcmp(argv[i], "-noout")) ||
	         (!strcmp(argv[i], "--noout")))
	    noout++;
#ifdef LIBXML_OUTPUT_ENABLED
	else if ((!strcmp(argv[i], "-o")) ||
	         (!strcmp(argv[i], "-output")) ||
	         (!strcmp(argv[i], "--output"))) {
	    i++;
	    output = argv[i];
	}
#endif /* LIBXML_OUTPUT_ENABLED */
	else if ((!strcmp(argv[i], "-htmlout")) ||
	         (!strcmp(argv[i], "--htmlout")))
	    htmlout++;
	else if ((!strcmp(argv[i], "-nowrap")) ||
	         (!strcmp(argv[i], "--nowrap")))
	    nowrap++;
#ifdef LIBXML_HTML_ENABLED
	else if ((!strcmp(argv[i], "-html")) ||
	         (!strcmp(argv[i], "--html"))) {
	    html++;
        }
	else if ((!strcmp(argv[i], "-xmlout")) ||
	         (!strcmp(argv[i], "--xmlout"))) {
	    xmlout++;
        }
#endif /* LIBXML_HTML_ENABLED */
	else if ((!strcmp(argv[i], "-loaddtd")) ||
	         (!strcmp(argv[i], "--loaddtd"))) {
	    loaddtd++;
	    options |= XML_PARSE_DTDLOAD;
	} else if ((!strcmp(argv[i], "-dtdattr")) ||
	         (!strcmp(argv[i], "--dtdattr"))) {
	    loaddtd++;
	    dtdattrs++;
	    options |= XML_PARSE_DTDATTR;
	}
#ifdef LIBXML_VALID_ENABLED
	else if ((!strcmp(argv[i], "-valid")) ||
	         (!strcmp(argv[i], "--valid"))) {
	    valid++;
	    options |= XML_PARSE_DTDVALID;
	} else if ((!strcmp(argv[i], "-postvalid")) ||
	         (!strcmp(argv[i], "--postvalid"))) {
	    postvalid++;
	    loaddtd++;
	    options |= XML_PARSE_DTDLOAD;
	} else if ((!strcmp(argv[i], "-dtdvalid")) ||
	         (!strcmp(argv[i], "--dtdvalid"))) {
	    i++;
	    dtdvalid = argv[i];
	    loaddtd++;
	    options |= XML_PARSE_DTDLOAD;
	} else if ((!strcmp(argv[i], "-dtdvalidfpi")) ||
	         (!strcmp(argv[i], "--dtdvalidfpi"))) {
	    i++;
	    dtdvalidfpi = argv[i];
	    loaddtd++;
	    options |= XML_PARSE_DTDLOAD;
        }
#endif /* LIBXML_VALID_ENABLED */
	else if ((!strcmp(argv[i], "-dropdtd")) ||
	         (!strcmp(argv[i], "--dropdtd")))
	    dropdtd++;
	else if ((!strcmp(argv[i], "-insert")) ||
	         (!strcmp(argv[i], "--insert")))
	    insert++;
	else if ((!strcmp(argv[i], "-timing")) ||
	         (!strcmp(argv[i], "--timing")))
	    timing++;
	else if ((!strcmp(argv[i], "-auto")) ||
	         (!strcmp(argv[i], "--auto")))
	    generate++;
	else if ((!strcmp(argv[i], "-repeat")) ||
	         (!strcmp(argv[i], "--repeat"))) {
	    if (repeat)
	        repeat *= 10;
	    else
	        repeat = 100;
	}
#ifdef LIBXML_PUSH_ENABLED
	else if ((!strcmp(argv[i], "-push")) ||
	         (!strcmp(argv[i], "--push")))
	    push++;
#endif /* LIBXML_PUSH_ENABLED */
#ifdef HAVE_SYS_MMAN_H
	else if ((!strcmp(argv[i], "-memory")) ||
	         (!strcmp(argv[i], "--memory")))
	    memory++;
#endif
	else if ((!strcmp(argv[i], "-testIO")) ||
	         (!strcmp(argv[i], "--testIO")))
	    testIO++;
#ifdef LIBXML_XINCLUDE_ENABLED
	else if ((!strcmp(argv[i], "-xinclude")) ||
	         (!strcmp(argv[i], "--xinclude"))) {
	    xinclude++;
	    options |= XML_PARSE_XINCLUDE;
	}
	else if ((!strcmp(argv[i], "-noxincludenode")) ||
	         (!strcmp(argv[i], "--noxincludenode"))) {
	    xinclude++;
	    options |= XML_PARSE_XINCLUDE;
	    options |= XML_PARSE_NOXINCNODE;
	}
	else if ((!strcmp(argv[i], "-nofixup-base-uris")) ||
	         (!strcmp(argv[i], "--nofixup-base-uris"))) {
	    xinclude++;
	    options |= XML_PARSE_XINCLUDE;
	    options |= XML_PARSE_NOBASEFIX;
	}
#endif
#ifdef LIBXML_OUTPUT_ENABLED
#ifdef HAVE_ZLIB_H
	else if ((!strcmp(argv[i], "-compress")) ||
	         (!strcmp(argv[i], "--compress"))) {
	    compress++;
	    xmlSetCompressMode(9);
        }
#endif
#endif /* LIBXML_OUTPUT_ENABLED */
	else if ((!strcmp(argv[i], "-nowarning")) ||
	         (!strcmp(argv[i], "--nowarning"))) {
	    xmlGetWarningsDefaultValue = 0;
	    xmlPedanticParserDefault(0);
	    options |= XML_PARSE_NOWARNING;
        }
	else if ((!strcmp(argv[i], "-pedantic")) ||
	         (!strcmp(argv[i], "--pedantic"))) {
	    xmlGetWarningsDefaultValue = 1;
	    xmlPedanticParserDefault(1);
	    options |= XML_PARSE_PEDANTIC;
        }
#ifdef LIBXML_DEBUG_ENABLED
	else if ((!strcmp(argv[i], "-debugent")) ||
		 (!strcmp(argv[i], "--debugent"))) {
	    debugent++;
	    xmlParserDebugEntities = 1;
	}
#endif
#ifdef LIBXML_C14N_ENABLED
	else if ((!strcmp(argv[i], "-c14n")) ||
		 (!strcmp(argv[i], "--c14n"))) {
	    canonical++;
	    options |= XML_PARSE_NOENT | XML_PARSE_DTDATTR | XML_PARSE_DTDLOAD;
	}
	else if ((!strcmp(argv[i], "-c14n11")) ||
		 (!strcmp(argv[i], "--c14n11"))) {
	    canonical_11++;
	    options |= XML_PARSE_NOENT | XML_PARSE_DTDATTR | XML_PARSE_DTDLOAD;
	}
	else if ((!strcmp(argv[i], "-exc-c14n")) ||
		 (!strcmp(argv[i], "--exc-c14n"))) {
	    exc_canonical++;
	    options |= XML_PARSE_NOENT | XML_PARSE_DTDATTR | XML_PARSE_DTDLOAD;
	}
#endif
#ifdef LIBXML_CATALOG_ENABLED
	else if ((!strcmp(argv[i], "-catalogs")) ||
		 (!strcmp(argv[i], "--catalogs"))) {
	    catalogs++;
	} else if ((!strcmp(argv[i], "-nocatalogs")) ||
		 (!strcmp(argv[i], "--nocatalogs"))) {
	    nocatalogs++;
	}
#endif
	else if ((!strcmp(argv[i], "-encode")) ||
	         (!strcmp(argv[i], "--encode"))) {
	    i++;
	    encoding = argv[i];
	    /*
	     * OK it's for testing purposes
	     */
	    xmlAddEncodingAlias("UTF-8", "DVEnc");
        }
	else if ((!strcmp(argv[i], "-noblanks")) ||
	         (!strcmp(argv[i], "--noblanks"))) {
	     noblanks++;
	     xmlKeepBlanksDefault(0);
        }
	else if ((!strcmp(argv[i], "-maxmem")) ||
	         (!strcmp(argv[i], "--maxmem"))) {
	     i++;
	     if (sscanf(argv[i], "%d", &maxmem) == 1) {
	         xmlMemSetup(myFreeFunc, myMallocFunc, myReallocFunc,
		             myStrdupFunc);
	     } else {
	         maxmem = 0;
	     }
        }
	else if ((!strcmp(argv[i], "-format")) ||
	         (!strcmp(argv[i], "--format"))) {
	     noblanks++;
#ifdef LIBXML_OUTPUT_ENABLED
	     format++;
#endif /* LIBXML_OUTPUT_ENABLED */
	     xmlKeepBlanksDefault(0);
	}
#ifdef LIBXML_READER_ENABLED
	else if ((!strcmp(argv[i], "-stream")) ||
	         (!strcmp(argv[i], "--stream"))) {
	     stream++;
	}
	else if ((!strcmp(argv[i], "-walker")) ||
	         (!strcmp(argv[i], "--walker"))) {
	     walker++;
             noout++;
	}
#endif /* LIBXML_READER_ENABLED */
#ifdef LIBXML_SAX1_ENABLED
	else if ((!strcmp(argv[i], "-sax1")) ||
	         (!strcmp(argv[i], "--sax1"))) {
	    sax1++;
	    options |= XML_PARSE_SAX1;
	}
#endif /* LIBXML_SAX1_ENABLED */
	else if ((!strcmp(argv[i], "-sax")) ||
	         (!strcmp(argv[i], "--sax"))) {
	    sax++;
	}
	else if ((!strcmp(argv[i], "-chkregister")) ||
	         (!strcmp(argv[i], "--chkregister"))) {
	    chkregister++;
#ifdef LIBXML_SCHEMAS_ENABLED
	} else if ((!strcmp(argv[i], "-relaxng")) ||
	         (!strcmp(argv[i], "--relaxng"))) {
	    i++;
	    relaxng = argv[i];
	    noent++;
	    options |= XML_PARSE_NOENT;
	} else if ((!strcmp(argv[i], "-schema")) ||
	         (!strcmp(argv[i], "--schema"))) {
	    i++;
	    schema = argv[i];
	    noent++;
#endif
#ifdef LIBXML_SCHEMATRON_ENABLED
	} else if ((!strcmp(argv[i], "-schematron")) ||
	         (!strcmp(argv[i], "--schematron"))) {
	    i++;
	    schematron = argv[i];
	    noent++;
#endif
        } else if ((!strcmp(argv[i], "-nonet")) ||
                   (!strcmp(argv[i], "--nonet"))) {
	    options |= XML_PARSE_NONET;
	    xmlSetExternalEntityLoader(xmlNoNetExternalEntityLoader);
        } else if ((!strcmp(argv[i], "-nocompact")) ||
                   (!strcmp(argv[i], "--nocompact"))) {
	    options &= ~XML_PARSE_COMPACT;
	} else if ((!strcmp(argv[i], "-load-trace")) ||
	           (!strcmp(argv[i], "--load-trace"))) {
	    load_trace++;
        } else if ((!strcmp(argv[i], "-path")) ||
                   (!strcmp(argv[i], "--path"))) {
	    i++;
	    parsePath(BAD_CAST argv[i]);
#ifdef LIBXML_PATTERN_ENABLED
        } else if ((!strcmp(argv[i], "-pattern")) ||
                   (!strcmp(argv[i], "--pattern"))) {
	    i++;
	    pattern = argv[i];
#endif
#ifdef LIBXML_XPATH_ENABLED
        } else if ((!strcmp(argv[i], "-xpath")) ||
                   (!strcmp(argv[i], "--xpath"))) {
	    i++;
	    noout++;
	    xpathquery = argv[i];
#endif
	} else if ((!strcmp(argv[i], "-oldxml10")) ||
	           (!strcmp(argv[i], "--oldxml10"))) {
	    oldxml10++;
	    options |= XML_PARSE_OLD10;
	} else {
	    fprintf(stderr, "Unknown option %s\n", argv[i]);
	    usage(argv[0]);
	    return(1);
	}
    }

#ifdef LIBXML_CATALOG_ENABLED
    if (nocatalogs == 0) {
	if (catalogs) {
	    const char *catal;

	    catal = getenv("SGML_CATALOG_FILES");
	    if (catal != NULL) {
		xmlLoadCatalogs(catal);
	    } else {
		fprintf(stderr, "Variable $SGML_CATALOG_FILES not set\n");
	    }
	}
    }
#endif

#ifdef LIBXML_SAX1_ENABLED
    if (sax1)
        xmlSAXDefaultVersion(1);
    else
        xmlSAXDefaultVersion(2);
#endif /* LIBXML_SAX1_ENABLED */

    if (chkregister) {
	xmlRegisterNodeDefault(registerNode);
	xmlDeregisterNodeDefault(deregisterNode);
    }

    indent = getenv("XMLLINT_INDENT");
    if(indent != NULL) {
	xmlTreeIndentString = indent;
    }


    defaultEntityLoader = xmlGetExternalEntityLoader();
    xmlSetExternalEntityLoader(xmllintExternalEntityLoader);

    xmlLineNumbersDefault(1);
    if (loaddtd != 0)
	xmlLoadExtDtdDefaultValue |= XML_DETECT_IDS;
    if (dtdattrs)
	xmlLoadExtDtdDefaultValue |= XML_COMPLETE_ATTRS;
    if (noent != 0) xmlSubstituteEntitiesDefault(1);
#ifdef LIBXML_VALID_ENABLED
    if (valid != 0) xmlDoValidityCheckingDefaultValue = 1;
#endif /* LIBXML_VALID_ENABLED */
    if ((htmlout) && (!nowrap)) {
	xmlGenericError(xmlGenericErrorContext,
         "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\"\n");
	xmlGenericError(xmlGenericErrorContext,
		"\t\"http://www.w3.org/TR/REC-html40/loose.dtd\">\n");
	xmlGenericError(xmlGenericErrorContext,
	 "<html><head><title>%s output</title></head>\n",
		argv[0]);
	xmlGenericError(xmlGenericErrorContext,
	 "<body bgcolor=\"#ffffff\"><h1 align=\"center\">%s output</h1>\n",
		argv[0]);
    }

#ifdef LIBXML_SCHEMATRON_ENABLED
    if ((schematron != NULL) && (sax == 0)
#ifdef LIBXML_READER_ENABLED
        && (stream == 0)
#endif /* LIBXML_READER_ENABLED */
	) {
	xmlSchematronParserCtxtPtr ctxt;

        /* forces loading the DTDs */
        xmlLoadExtDtdDefaultValue |= 1;
	options |= XML_PARSE_DTDLOAD;
	if (timing) {
	    startTimer();
	}
	ctxt = xmlSchematronNewParserCtxt(schematron);
#if 0
	xmlSchematronSetParserErrors(ctxt,
		(xmlSchematronValidityErrorFunc) fprintf,
		(xmlSchematronValidityWarningFunc) fprintf,
		stderr);
#endif
	wxschematron = xmlSchematronParse(ctxt);
	if (wxschematron == NULL) {
	    xmlGenericError(xmlGenericErrorContext,
		    "Schematron schema %s failed to compile\n", schematron);
            progresult = XMLLINT_ERR_SCHEMACOMP;
	    schematron = NULL;
	}
	xmlSchematronFreeParserCtxt(ctxt);
	if (timing) {
	    endTimer("Compiling the schemas");
	}
    }
#endif
#ifdef LIBXML_SCHEMAS_ENABLED
    if ((relaxng != NULL) && (sax == 0)
#ifdef LIBXML_READER_ENABLED
        && (stream == 0)
#endif /* LIBXML_READER_ENABLED */
	) {
	xmlRelaxNGParserCtxtPtr ctxt;

        /* forces loading the DTDs */
        xmlLoadExtDtdDefaultValue |= 1;
	options |= XML_PARSE_DTDLOAD;
	if (timing) {
	    startTimer();
	}
	ctxt = xmlRelaxNGNewParserCtxt(relaxng);
	xmlRelaxNGSetParserErrors(ctxt,
		(xmlRelaxNGValidityErrorFunc) fprintf,
		(xmlRelaxNGValidityWarningFunc) fprintf,
		stderr);
	relaxngschemas = xmlRelaxNGParse(ctxt);
	if (relaxngschemas == NULL) {
	    xmlGenericError(xmlGenericErrorContext,
		    "Relax-NG schema %s failed to compile\n", relaxng);
            progresult = XMLLINT_ERR_SCHEMACOMP;
	    relaxng = NULL;
	}
	xmlRelaxNGFreeParserCtxt(ctxt);
	if (timing) {
	    endTimer("Compiling the schemas");
	}
    } else if ((schema != NULL)
#ifdef LIBXML_READER_ENABLED
		&& (stream == 0)
#endif
	) {
	xmlSchemaParserCtxtPtr ctxt;

	if (timing) {
	    startTimer();
	}
	ctxt = xmlSchemaNewParserCtxt(schema);
	xmlSchemaSetParserErrors(ctxt,
		(xmlSchemaValidityErrorFunc) fprintf,
		(xmlSchemaValidityWarningFunc) fprintf,
		stderr);
	wxschemas = xmlSchemaParse(ctxt);
	if (wxschemas == NULL) {
	    xmlGenericError(xmlGenericErrorContext,
		    "WXS schema %s failed to compile\n", schema);
            progresult = XMLLINT_ERR_SCHEMACOMP;
	    schema = NULL;
	}
	xmlSchemaFreeParserCtxt(ctxt);
	if (timing) {
	    endTimer("Compiling the schemas");
	}
    }
#endif /* LIBXML_SCHEMAS_ENABLED */
#ifdef LIBXML_PATTERN_ENABLED
    if ((pattern != NULL)
#ifdef LIBXML_READER_ENABLED
        && (walker == 0)
#endif
	) {
        patternc = xmlPatterncompile((const xmlChar *) pattern, NULL, 0, NULL);
	if (patternc == NULL) {
	    xmlGenericError(xmlGenericErrorContext,
		    "Pattern %s failed to compile\n", pattern);
            progresult = XMLLINT_ERR_SCHEMAPAT;
	    pattern = NULL;
	}
    }
#endif /* LIBXML_PATTERN_ENABLED */
    for (i = 1; i < argc ; i++) {
	if ((!strcmp(argv[i], "-encode")) ||
	         (!strcmp(argv[i], "--encode"))) {
	    i++;
	    continue;
        } else if ((!strcmp(argv[i], "-o")) ||
                   (!strcmp(argv[i], "-output")) ||
                   (!strcmp(argv[i], "--output"))) {
            i++;
	    continue;
        }
#ifdef LIBXML_VALID_ENABLED
	if ((!strcmp(argv[i], "-dtdvalid")) ||
	         (!strcmp(argv[i], "--dtdvalid"))) {
	    i++;
	    continue;
        }
	if ((!strcmp(argv[i], "-path")) ||
                   (!strcmp(argv[i], "--path"))) {
            i++;
	    continue;
        }
	if ((!strcmp(argv[i], "-dtdvalidfpi")) ||
	         (!strcmp(argv[i], "--dtdvalidfpi"))) {
	    i++;
	    continue;
        }
#endif /* LIBXML_VALID_ENABLED */
	if ((!strcmp(argv[i], "-relaxng")) ||
	         (!strcmp(argv[i], "--relaxng"))) {
	    i++;
	    continue;
        }
	if ((!strcmp(argv[i], "-maxmem")) ||
	         (!strcmp(argv[i], "--maxmem"))) {
	    i++;
	    continue;
        }
	if ((!strcmp(argv[i], "-schema")) ||
	         (!strcmp(argv[i], "--schema"))) {
	    i++;
	    continue;
        }
	if ((!strcmp(argv[i], "-schematron")) ||
	         (!strcmp(argv[i], "--schematron"))) {
	    i++;
	    continue;
        }
#ifdef LIBXML_PATTERN_ENABLED
        if ((!strcmp(argv[i], "-pattern")) ||
	    (!strcmp(argv[i], "--pattern"))) {
	    i++;
	    continue;
	}
#endif
#ifdef LIBXML_XPATH_ENABLED
        if ((!strcmp(argv[i], "-xpath")) ||
	    (!strcmp(argv[i], "--xpath"))) {
	    i++;
	    continue;
	}
#endif
	if ((timing) && (repeat))
	    startTimer();
	/* Remember file names.  "-" means stdin.  <sven@zen.org> */
	if ((argv[i][0] != '-') || (strcmp(argv[i], "-") == 0)) {
	    if (repeat) {
		xmlParserCtxtPtr ctxt = NULL;

		for (acount = 0;acount < repeat;acount++) {
#ifdef LIBXML_READER_ENABLED
		    if (stream != 0) {
			streamFile(argv[i]);
		    } else {
#endif /* LIBXML_READER_ENABLED */
                        if (sax) {
			    testSAX(argv[i]);
			} else {
			    if (ctxt == NULL)
				ctxt = xmlNewParserCtxt();
			    parseAndPrintFile(argv[i], ctxt);
			}
#ifdef LIBXML_READER_ENABLED
		    }
#endif /* LIBXML_READER_ENABLED */
		}
		if (ctxt != NULL)
		    xmlFreeParserCtxt(ctxt);
	    } else {
		nbregister = 0;

#ifdef LIBXML_READER_ENABLED
		if (stream != 0)
		    streamFile(argv[i]);
		else
#endif /* LIBXML_READER_ENABLED */
                if (sax) {
		    testSAX(argv[i]);
		} else {
		    parseAndPrintFile(argv[i], NULL);
		}

                if ((chkregister) && (nbregister != 0)) {
		    fprintf(stderr, "Registration count off: %d\n", nbregister);
		    progresult = XMLLINT_ERR_RDREGIS;
		}
	    }
	    files ++;
	    if ((timing) && (repeat)) {
		endTimer("%d iterations", repeat);
	    }
	}
    }
    if (generate)
	parseAndPrintFile(NULL, NULL);
    if ((htmlout) && (!nowrap)) {
	xmlGenericError(xmlGenericErrorContext, "</body></html>\n");
    }
    if ((files == 0) && (!generate) && (version == 0)) {
	usage(argv[0]);
    }
#ifdef LIBXML_SCHEMATRON_ENABLED
    if (wxschematron != NULL)
	xmlSchematronFree(wxschematron);
#endif
#ifdef LIBXML_SCHEMAS_ENABLED
    if (relaxngschemas != NULL)
	xmlRelaxNGFree(relaxngschemas);
    if (wxschemas != NULL)
	xmlSchemaFree(wxschemas);
    xmlRelaxNGCleanupTypes();
#endif
#ifdef LIBXML_PATTERN_ENABLED
    if (patternc != NULL)
        xmlFreePattern(patternc);
#endif
    xmlCleanupParser();
    xmlMemoryDump();

    return(progresult);
}

