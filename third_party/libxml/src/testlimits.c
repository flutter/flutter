/*
 * testlimits.c: C program to run libxml2 regression tests checking various
 *       limits in document size. Will consume a lot of RAM and CPU cycles
 *
 * To compile on Unixes:
 * cc -o testlimits `xml2-config --cflags` testlimits.c `xml2-config --libs` -lpthread
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
#include <time.h>

#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/tree.h>
#include <libxml/uri.h>
#ifdef LIBXML_READER_ENABLED
#include <libxml/xmlreader.h>
#endif

static int verbose = 0;
static int tests_quiet = 0;

/************************************************************************
 *									*
 *		time handling                                           *
 *									*
 ************************************************************************/

/* maximum time for one parsing before declaring a timeout */
#define MAX_TIME 2 /* seconds */

static clock_t t0;
int timeout = 0;

static void reset_timout(void) {
    timeout = 0;
    t0 = clock();
}

static int check_time(void) {
    clock_t tnow = clock();
    if (((tnow - t0) / CLOCKS_PER_SEC) > MAX_TIME) {
        timeout = 1;
        return(0);
    }
    return(1);
}

/************************************************************************
 *									*
 *		Huge document generator					*
 *									*
 ************************************************************************/

#include <libxml/xmlIO.h>

/*
 * Huge documents are built using fixed start and end chunks
 * and filling between the two an unconventional amount of char data
 */
typedef struct hugeTest hugeTest;
typedef hugeTest *hugeTestPtr;
struct hugeTest {
    const char *description;
    const char *name;
    const char *start;
    const char *end;
};

static struct hugeTest hugeTests[] = {
    { "Huge text node", "huge:textNode", "<foo>", "</foo>" },
    { "Huge attribute node", "huge:attrNode", "<foo bar='", "'/>" },
    { "Huge comment node", "huge:commentNode", "<foo><!--", "--></foo>" },
    { "Huge PI node", "huge:piNode", "<foo><?bar ", "?></foo>" },
};

static const char *current;
static int rlen;
static unsigned int currentTest = 0;
static int instate = 0;

/**
 * hugeMatch:
 * @URI: an URI to test
 *
 * Check for an huge: query
 *
 * Returns 1 if yes and 0 if another Input module should be used
 */
static int
hugeMatch(const char * URI) {
    if ((URI != NULL) && (!strncmp(URI, "huge:", 5)))
        return(1);
    return(0);
}

/**
 * hugeOpen:
 * @URI: an URI to test
 *
 * Return a pointer to the huge: query handler, in this example simply
 * the current pointer...
 *
 * Returns an Input context or NULL in case or error
 */
static void *
hugeOpen(const char * URI) {
    if ((URI == NULL) || (strncmp(URI, "huge:", 5)))
        return(NULL);

    for (currentTest = 0;currentTest < sizeof(hugeTests)/sizeof(hugeTests[0]);
         currentTest++)
         if (!strcmp(hugeTests[currentTest].name, URI))
             goto found;

    return(NULL);

found:
    rlen = strlen(hugeTests[currentTest].start);
    current = hugeTests[currentTest].start;
    instate = 0;
    return((void *) current);
}

/**
 * hugeClose:
 * @context: the read context
 *
 * Close the huge: query handler
 *
 * Returns 0 or -1 in case of error
 */
static int
hugeClose(void * context) {
    if (context == NULL) return(-1);
    fprintf(stderr, "\n");
    return(0);
}

#define CHUNK 4096

char filling[CHUNK + 1];

static void fillFilling(void) {
    int i;

    for (i = 0;i < CHUNK;i++) {
        filling[i] = 'a';
    }
    filling[CHUNK] = 0;
}

size_t maxlen = 64 * 1024 * 1024;
size_t curlen = 0;
size_t dotlen;

/**
 * hugeRead:
 * @context: the read context
 * @buffer: where to store data
 * @len: number of bytes to read
 *
 * Implement an huge: query read.
 *
 * Returns the number of bytes read or -1 in case of error
 */
static int
hugeRead(void *context, char *buffer, int len)
{
    if ((context == NULL) || (buffer == NULL) || (len < 0))
        return (-1);

    if (instate == 0) {
        if (len >= rlen) {
            len = rlen;
            rlen = 0;
            memcpy(buffer, current, len);
            instate = 1;
            curlen = 0;
            dotlen = maxlen / 10;
        } else {
            memcpy(buffer, current, len);
            rlen -= len;
            current += len;
        }
    } else if (instate == 2) {
        if (len >= rlen) {
            len = rlen;
            rlen = 0;
            memcpy(buffer, current, len);
            instate = 3;
            curlen = 0;
        } else {
            memcpy(buffer, current, len);
            rlen -= len;
            current += len;
        }
    } else if (instate == 1) {
        if (len > CHUNK) len = CHUNK;
        memcpy(buffer, &filling[0], len);
        curlen += len;
        if (curlen >= maxlen) {
            rlen = strlen(hugeTests[currentTest].end);
            current = hugeTests[currentTest].end;
            instate = 2;
	} else {
            if (curlen > dotlen) {
                fprintf(stderr, ".");
                dotlen += maxlen / 10;
            }
        }
    } else
      len = 0;
    return (len);
}

/************************************************************************
 *									*
 *		Crazy document generator				*
 *									*
 ************************************************************************/

unsigned int crazy_indx = 0;

const char *crazy = "<?xml version='1.0' encoding='UTF-8'?>\
<?tst ?>\
<!-- tst -->\
<!DOCTYPE foo [\
<?tst ?>\
<!-- tst -->\
<!ELEMENT foo (#PCDATA)>\
<!ELEMENT p (#PCDATA|emph)* >\
]>\
<?tst ?>\
<!-- tst -->\
<foo bar='foo'>\
<?tst ?>\
<!-- tst -->\
foo\
<![CDATA[ ]]>\
</foo>\
<?tst ?>\
<!-- tst -->";

/**
 * crazyMatch:
 * @URI: an URI to test
 *
 * Check for a crazy: query
 *
 * Returns 1 if yes and 0 if another Input module should be used
 */
static int
crazyMatch(const char * URI) {
    if ((URI != NULL) && (!strncmp(URI, "crazy:", 6)))
        return(1);
    return(0);
}

/**
 * crazyOpen:
 * @URI: an URI to test
 *
 * Return a pointer to the crazy: query handler, in this example simply
 * the current pointer...
 *
 * Returns an Input context or NULL in case or error
 */
static void *
crazyOpen(const char * URI) {
    if ((URI == NULL) || (strncmp(URI, "crazy:", 6)))
        return(NULL);

    if (crazy_indx > strlen(crazy))
        return(NULL);
    reset_timout();
    rlen = crazy_indx;
    current = &crazy[0];
    instate = 0;
    return((void *) current);
}

/**
 * crazyClose:
 * @context: the read context
 *
 * Close the crazy: query handler
 *
 * Returns 0 or -1 in case of error
 */
static int
crazyClose(void * context) {
    if (context == NULL) return(-1);
    return(0);
}


/**
 * crazyRead:
 * @context: the read context
 * @buffer: where to store data
 * @len: number of bytes to read
 *
 * Implement an crazy: query read.
 *
 * Returns the number of bytes read or -1 in case of error
 */
static int
crazyRead(void *context, char *buffer, int len)
{
    if ((context == NULL) || (buffer == NULL) || (len < 0))
        return (-1);

    if ((check_time() <= 0) && (instate == 1)) {
        fprintf(stderr, "\ntimeout in crazy(%d)\n", crazy_indx);
        rlen = strlen(crazy) - crazy_indx;
        current = &crazy[crazy_indx];
        instate = 2;
    }
    if (instate == 0) {
        if (len >= rlen) {
            len = rlen;
            rlen = 0;
            memcpy(buffer, current, len);
            instate = 1;
            curlen = 0;
        } else {
            memcpy(buffer, current, len);
            rlen -= len;
            current += len;
        }
    } else if (instate == 2) {
        if (len >= rlen) {
            len = rlen;
            rlen = 0;
            memcpy(buffer, current, len);
            instate = 3;
            curlen = 0;
        } else {
            memcpy(buffer, current, len);
            rlen -= len;
            current += len;
        }
    } else if (instate == 1) {
        if (len > CHUNK) len = CHUNK;
        memcpy(buffer, &filling[0], len);
        curlen += len;
        if (curlen >= maxlen) {
            rlen = strlen(crazy) - crazy_indx;
            current = &crazy[crazy_indx];
            instate = 2;
        }
    } else
      len = 0;
    return (len);
}
/************************************************************************
 *									*
 *		Libxml2 specific routines				*
 *									*
 ************************************************************************/

static int nb_tests = 0;
static int nb_errors = 0;
static int nb_leaks = 0;
static int extraMemoryFromResolver = 0;

/*
 * We need to trap calls to the resolver to not account memory for the catalog
 * which is shared to the current running test. We also don't want to have
 * network downloads modifying tests.
 */
static xmlParserInputPtr
testExternalEntityLoader(const char *URL, const char *ID,
			 xmlParserCtxtPtr ctxt) {
    xmlParserInputPtr ret;
    int memused = xmlMemUsed();

    ret = xmlNoNetExternalEntityLoader(URL, ID, ctxt);
    extraMemoryFromResolver += xmlMemUsed() - memused;

    return(ret);
}

/*
 * Trapping the error messages at the generic level to grab the equivalent of
 * stderr messages on CLI tools.
 */
static char testErrors[32769];
static int testErrorsSize = 0;

static void XMLCDECL
channel(void *ctx  ATTRIBUTE_UNUSED, const char *msg, ...) {
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

/**
 * xmlParserPrintFileContext:
 * @input:  an xmlParserInputPtr input
 *
 * Displays current context within the input content for error tracking
 */

static void
xmlParserPrintFileContextInternal(xmlParserInputPtr input ,
		xmlGenericErrorFunc chanl, void *data ) {
    const xmlChar *cur, *base;
    unsigned int n, col;	/* GCC warns if signed, because compared with sizeof() */
    xmlChar  content[81]; /* space for 80 chars + line terminator */
    xmlChar *ctnt;

    if (input == NULL) return;
    cur = input->cur;
    base = input->base;
    /* skip backwards over any end-of-lines */
    while ((cur > base) && ((*(cur) == '\n') || (*(cur) == '\r'))) {
	cur--;
    }
    n = 0;
    /* search backwards for beginning-of-line (to max buff size) */
    while ((n++ < (sizeof(content)-1)) && (cur > base) &&
   (*(cur) != '\n') && (*(cur) != '\r'))
        cur--;
    if ((*(cur) == '\n') || (*(cur) == '\r')) cur++;
    /* calculate the error position in terms of the current position */
    col = input->cur - cur;
    /* search forward for end-of-line (to max buff size) */
    n = 0;
    ctnt = content;
    /* copy selected text to our buffer */
    while ((*cur != 0) && (*(cur) != '\n') &&
   (*(cur) != '\r') && (n < sizeof(content)-1)) {
		*ctnt++ = *cur++;
	n++;
    }
    *ctnt = 0;
    /* print out the selected text */
    chanl(data ,"%s\n", content);
    /* create blank line with problem pointer */
    n = 0;
    ctnt = content;
    /* (leave buffer space for pointer + line terminator) */
    while ((n<col) && (n++ < sizeof(content)-2) && (*ctnt != 0)) {
	if (*(ctnt) != '\t')
	    *(ctnt) = ' ';
	ctnt++;
    }
    *ctnt++ = '^';
    *ctnt = 0;
    chanl(data ,"%s\n", content);
}

static void
testStructuredErrorHandler(void *ctx  ATTRIBUTE_UNUSED, xmlErrorPtr err) {
    char *file = NULL;
    int line = 0;
    int code = -1;
    int domain;
    void *data = NULL;
    const char *str;
    const xmlChar *name = NULL;
    xmlNodePtr node;
    xmlErrorLevel level;
    xmlParserInputPtr input = NULL;
    xmlParserInputPtr cur = NULL;
    xmlParserCtxtPtr ctxt = NULL;

    if (err == NULL)
        return;

    file = err->file;
    line = err->line;
    code = err->code;
    domain = err->domain;
    level = err->level;
    node = err->node;
    if ((domain == XML_FROM_PARSER) || (domain == XML_FROM_HTML) ||
        (domain == XML_FROM_DTD) || (domain == XML_FROM_NAMESPACE) ||
	(domain == XML_FROM_IO) || (domain == XML_FROM_VALID)) {
	ctxt = err->ctxt;
    }
    str = err->message;

    if (code == XML_ERR_OK)
        return;

    if ((node != NULL) && (node->type == XML_ELEMENT_NODE))
        name = node->name;

    /*
     * Maintain the compatibility with the legacy error handling
     */
    if (ctxt != NULL) {
        input = ctxt->input;
        if ((input != NULL) && (input->filename == NULL) &&
            (ctxt->inputNr > 1)) {
            cur = input;
            input = ctxt->inputTab[ctxt->inputNr - 2];
        }
        if (input != NULL) {
            if (input->filename)
                channel(data, "%s:%d: ", input->filename, input->line);
            else if ((line != 0) && (domain == XML_FROM_PARSER))
                channel(data, "Entity: line %d: ", input->line);
        }
    } else {
        if (file != NULL)
            channel(data, "%s:%d: ", file, line);
        else if ((line != 0) && (domain == XML_FROM_PARSER))
            channel(data, "Entity: line %d: ", line);
    }
    if (name != NULL) {
        channel(data, "element %s: ", name);
    }
    if (code == XML_ERR_OK)
        return;
    switch (domain) {
        case XML_FROM_PARSER:
            channel(data, "parser ");
            break;
        case XML_FROM_NAMESPACE:
            channel(data, "namespace ");
            break;
        case XML_FROM_DTD:
        case XML_FROM_VALID:
            channel(data, "validity ");
            break;
        case XML_FROM_HTML:
            channel(data, "HTML parser ");
            break;
        case XML_FROM_MEMORY:
            channel(data, "memory ");
            break;
        case XML_FROM_OUTPUT:
            channel(data, "output ");
            break;
        case XML_FROM_IO:
            channel(data, "I/O ");
            break;
        case XML_FROM_XINCLUDE:
            channel(data, "XInclude ");
            break;
        case XML_FROM_XPATH:
            channel(data, "XPath ");
            break;
        case XML_FROM_XPOINTER:
            channel(data, "parser ");
            break;
        case XML_FROM_REGEXP:
            channel(data, "regexp ");
            break;
        case XML_FROM_MODULE:
            channel(data, "module ");
            break;
        case XML_FROM_SCHEMASV:
            channel(data, "Schemas validity ");
            break;
        case XML_FROM_SCHEMASP:
            channel(data, "Schemas parser ");
            break;
        case XML_FROM_RELAXNGP:
            channel(data, "Relax-NG parser ");
            break;
        case XML_FROM_RELAXNGV:
            channel(data, "Relax-NG validity ");
            break;
        case XML_FROM_CATALOG:
            channel(data, "Catalog ");
            break;
        case XML_FROM_C14N:
            channel(data, "C14N ");
            break;
        case XML_FROM_XSLT:
            channel(data, "XSLT ");
            break;
        default:
            break;
    }
    if (code == XML_ERR_OK)
        return;
    switch (level) {
        case XML_ERR_NONE:
            channel(data, ": ");
            break;
        case XML_ERR_WARNING:
            channel(data, "warning : ");
            break;
        case XML_ERR_ERROR:
            channel(data, "error : ");
            break;
        case XML_ERR_FATAL:
            channel(data, "error : ");
            break;
    }
    if (code == XML_ERR_OK)
        return;
    if (str != NULL) {
        int len;
	len = xmlStrlen((const xmlChar *)str);
	if ((len > 0) && (str[len - 1] != '\n'))
	    channel(data, "%s\n", str);
	else
	    channel(data, "%s", str);
    } else {
        channel(data, "%s\n", "out of memory error");
    }
    if (code == XML_ERR_OK)
        return;

    if (ctxt != NULL) {
        xmlParserPrintFileContextInternal(input, channel, data);
        if (cur != NULL) {
            if (cur->filename)
                channel(data, "%s:%d: \n", cur->filename, cur->line);
            else if ((line != 0) && (domain == XML_FROM_PARSER))
                channel(data, "Entity: line %d: \n", cur->line);
            xmlParserPrintFileContextInternal(cur, channel, data);
        }
    }
    if ((domain == XML_FROM_XPATH) && (err->str1 != NULL) &&
        (err->int1 < 100) &&
	(err->int1 < xmlStrlen((const xmlChar *)err->str1))) {
	xmlChar buf[150];
	int i;

	channel(data, "%s\n", err->str1);
	for (i=0;i < err->int1;i++)
	     buf[i] = ' ';
	buf[i++] = '^';
	buf[i] = 0;
	channel(data, "%s\n", buf);
    }
}

static void
initializeLibxml2(void) {
    xmlGetWarningsDefaultValue = 0;
    xmlPedanticParserDefault(0);

    xmlMemSetup(xmlMemFree, xmlMemMalloc, xmlMemRealloc, xmlMemoryStrdup);
    xmlInitParser();
    xmlSetExternalEntityLoader(testExternalEntityLoader);
    xmlSetStructuredErrorFunc(NULL, testStructuredErrorHandler);
    /*
     * register the new I/O handlers
     */
    if (xmlRegisterInputCallbacks(hugeMatch, hugeOpen,
                                  hugeRead, hugeClose) < 0) {
        fprintf(stderr, "failed to register Huge handlers\n");
	exit(1);
    }
    if (xmlRegisterInputCallbacks(crazyMatch, crazyOpen,
                                  crazyRead, crazyClose) < 0) {
        fprintf(stderr, "failed to register Crazy handlers\n");
	exit(1);
    }
}

/************************************************************************
 *									*
 *		SAX empty callbacks                                     *
 *									*
 ************************************************************************/

unsigned long callbacks = 0;

/**
 * isStandaloneCallback:
 * @ctxt:  An XML parser context
 *
 * Is this document tagged standalone ?
 *
 * Returns 1 if true
 */
static int
isStandaloneCallback(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    return (0);
}

/**
 * hasInternalSubsetCallback:
 * @ctxt:  An XML parser context
 *
 * Does this document has an internal subset
 *
 * Returns 1 if true
 */
static int
hasInternalSubsetCallback(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    return (0);
}

/**
 * hasExternalSubsetCallback:
 * @ctxt:  An XML parser context
 *
 * Does this document has an external subset
 *
 * Returns 1 if true
 */
static int
hasExternalSubsetCallback(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    return (0);
}

/**
 * internalSubsetCallback:
 * @ctxt:  An XML parser context
 *
 * Does this document has an internal subset
 */
static void
internalSubsetCallback(void *ctx ATTRIBUTE_UNUSED,
                       const xmlChar * name ATTRIBUTE_UNUSED,
                       const xmlChar * ExternalID ATTRIBUTE_UNUSED,
                       const xmlChar * SystemID ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * externalSubsetCallback:
 * @ctxt:  An XML parser context
 *
 * Does this document has an external subset
 */
static void
externalSubsetCallback(void *ctx ATTRIBUTE_UNUSED,
                       const xmlChar * name ATTRIBUTE_UNUSED,
                       const xmlChar * ExternalID ATTRIBUTE_UNUSED,
                       const xmlChar * SystemID ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * resolveEntityCallback:
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
resolveEntityCallback(void *ctx ATTRIBUTE_UNUSED,
                      const xmlChar * publicId ATTRIBUTE_UNUSED,
                      const xmlChar * systemId ATTRIBUTE_UNUSED)
{
    callbacks++;
    return (NULL);
}

/**
 * getEntityCallback:
 * @ctxt:  An XML parser context
 * @name: The entity name
 *
 * Get an entity by name
 *
 * Returns the xmlParserInputPtr if inlined or NULL for DOM behaviour.
 */
static xmlEntityPtr
getEntityCallback(void *ctx ATTRIBUTE_UNUSED,
                  const xmlChar * name ATTRIBUTE_UNUSED)
{
    callbacks++;
    return (NULL);
}

/**
 * getParameterEntityCallback:
 * @ctxt:  An XML parser context
 * @name: The entity name
 *
 * Get a parameter entity by name
 *
 * Returns the xmlParserInputPtr
 */
static xmlEntityPtr
getParameterEntityCallback(void *ctx ATTRIBUTE_UNUSED,
                           const xmlChar * name ATTRIBUTE_UNUSED)
{
    callbacks++;
    return (NULL);
}


/**
 * entityDeclCallback:
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
entityDeclCallback(void *ctx ATTRIBUTE_UNUSED,
                   const xmlChar * name ATTRIBUTE_UNUSED,
                   int type ATTRIBUTE_UNUSED,
                   const xmlChar * publicId ATTRIBUTE_UNUSED,
                   const xmlChar * systemId ATTRIBUTE_UNUSED,
                   xmlChar * content ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * attributeDeclCallback:
 * @ctxt:  An XML parser context
 * @name:  the attribute name
 * @type:  the attribute type
 *
 * An attribute definition has been parsed
 */
static void
attributeDeclCallback(void *ctx ATTRIBUTE_UNUSED,
                      const xmlChar * elem ATTRIBUTE_UNUSED,
                      const xmlChar * name ATTRIBUTE_UNUSED,
                      int type ATTRIBUTE_UNUSED, int def ATTRIBUTE_UNUSED,
                      const xmlChar * defaultValue ATTRIBUTE_UNUSED,
                      xmlEnumerationPtr tree ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * elementDeclCallback:
 * @ctxt:  An XML parser context
 * @name:  the element name
 * @type:  the element type
 * @content: the element value (without processing).
 *
 * An element definition has been parsed
 */
static void
elementDeclCallback(void *ctx ATTRIBUTE_UNUSED,
                    const xmlChar * name ATTRIBUTE_UNUSED,
                    int type ATTRIBUTE_UNUSED,
                    xmlElementContentPtr content ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * notationDeclCallback:
 * @ctxt:  An XML parser context
 * @name: The name of the notation
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 *
 * What to do when a notation declaration has been parsed.
 */
static void
notationDeclCallback(void *ctx ATTRIBUTE_UNUSED,
                     const xmlChar * name ATTRIBUTE_UNUSED,
                     const xmlChar * publicId ATTRIBUTE_UNUSED,
                     const xmlChar * systemId ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * unparsedEntityDeclCallback:
 * @ctxt:  An XML parser context
 * @name: The name of the entity
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 * @notationName: the name of the notation
 *
 * What to do when an unparsed entity declaration is parsed
 */
static void
unparsedEntityDeclCallback(void *ctx ATTRIBUTE_UNUSED,
                           const xmlChar * name ATTRIBUTE_UNUSED,
                           const xmlChar * publicId ATTRIBUTE_UNUSED,
                           const xmlChar * systemId ATTRIBUTE_UNUSED,
                           const xmlChar * notationName ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * setDocumentLocatorCallback:
 * @ctxt:  An XML parser context
 * @loc: A SAX Locator
 *
 * Receive the document locator at startup, actually xmlDefaultSAXLocator
 * Everything is available on the context, so this is useless in our case.
 */
static void
setDocumentLocatorCallback(void *ctx ATTRIBUTE_UNUSED,
                           xmlSAXLocatorPtr loc ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * startDocumentCallback:
 * @ctxt:  An XML parser context
 *
 * called when the document start being processed.
 */
static void
startDocumentCallback(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * endDocumentCallback:
 * @ctxt:  An XML parser context
 *
 * called when the document end has been detected.
 */
static void
endDocumentCallback(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

#if 0
/**
 * startElementCallback:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when an opening tag has been processed.
 */
static void
startElementCallback(void *ctx ATTRIBUTE_UNUSED,
                     const xmlChar * name ATTRIBUTE_UNUSED,
                     const xmlChar ** atts ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * endElementCallback:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when the end of an element has been detected.
 */
static void
endElementCallback(void *ctx ATTRIBUTE_UNUSED,
                   const xmlChar * name ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}
#endif

/**
 * charactersCallback:
 * @ctxt:  An XML parser context
 * @ch:  a xmlChar string
 * @len: the number of xmlChar
 *
 * receiving some chars from the parser.
 * Question: how much at a time ???
 */
static void
charactersCallback(void *ctx ATTRIBUTE_UNUSED,
                   const xmlChar * ch ATTRIBUTE_UNUSED,
                   int len ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * referenceCallback:
 * @ctxt:  An XML parser context
 * @name:  The entity name
 *
 * called when an entity reference is detected.
 */
static void
referenceCallback(void *ctx ATTRIBUTE_UNUSED,
                  const xmlChar * name ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * ignorableWhitespaceCallback:
 * @ctxt:  An XML parser context
 * @ch:  a xmlChar string
 * @start: the first char in the string
 * @len: the number of xmlChar
 *
 * receiving some ignorable whitespaces from the parser.
 * Question: how much at a time ???
 */
static void
ignorableWhitespaceCallback(void *ctx ATTRIBUTE_UNUSED,
                            const xmlChar * ch ATTRIBUTE_UNUSED,
                            int len ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * processingInstructionCallback:
 * @ctxt:  An XML parser context
 * @target:  the target name
 * @data: the PI data's
 * @len: the number of xmlChar
 *
 * A processing instruction has been parsed.
 */
static void
processingInstructionCallback(void *ctx ATTRIBUTE_UNUSED,
                              const xmlChar * target ATTRIBUTE_UNUSED,
                              const xmlChar * data ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * cdataBlockCallback:
 * @ctx: the user data (XML parser context)
 * @value:  The pcdata content
 * @len:  the block length
 *
 * called when a pcdata block has been parsed
 */
static void
cdataBlockCallback(void *ctx ATTRIBUTE_UNUSED,
                   const xmlChar * value ATTRIBUTE_UNUSED,
                   int len ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * commentCallback:
 * @ctxt:  An XML parser context
 * @value:  the comment content
 *
 * A comment has been parsed.
 */
static void
commentCallback(void *ctx ATTRIBUTE_UNUSED,
                const xmlChar * value ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * warningCallback:
 * @ctxt:  An XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a warning messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
warningCallback(void *ctx ATTRIBUTE_UNUSED,
                const char *msg ATTRIBUTE_UNUSED, ...)
{
    callbacks++;
    return;
}

/**
 * errorCallback:
 * @ctxt:  An XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a error messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
errorCallback(void *ctx ATTRIBUTE_UNUSED, const char *msg ATTRIBUTE_UNUSED,
              ...)
{
    callbacks++;
    return;
}

/**
 * fatalErrorCallback:
 * @ctxt:  An XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a fatalError messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
fatalErrorCallback(void *ctx ATTRIBUTE_UNUSED,
                   const char *msg ATTRIBUTE_UNUSED, ...)
{
    return;
}


/*
 * SAX2 specific callbacks
 */

/**
 * startElementNsCallback:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when an opening tag has been processed.
 */
static void
startElementNsCallback(void *ctx ATTRIBUTE_UNUSED,
                       const xmlChar * localname ATTRIBUTE_UNUSED,
                       const xmlChar * prefix ATTRIBUTE_UNUSED,
                       const xmlChar * URI ATTRIBUTE_UNUSED,
                       int nb_namespaces ATTRIBUTE_UNUSED,
                       const xmlChar ** namespaces ATTRIBUTE_UNUSED,
                       int nb_attributes ATTRIBUTE_UNUSED,
                       int nb_defaulted ATTRIBUTE_UNUSED,
                       const xmlChar ** attributes ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

/**
 * endElementCallback:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when the end of an element has been detected.
 */
static void
endElementNsCallback(void *ctx ATTRIBUTE_UNUSED,
                     const xmlChar * localname ATTRIBUTE_UNUSED,
                     const xmlChar * prefix ATTRIBUTE_UNUSED,
                     const xmlChar * URI ATTRIBUTE_UNUSED)
{
    callbacks++;
    return;
}

static xmlSAXHandler callbackSAX2HandlerStruct = {
    internalSubsetCallback,
    isStandaloneCallback,
    hasInternalSubsetCallback,
    hasExternalSubsetCallback,
    resolveEntityCallback,
    getEntityCallback,
    entityDeclCallback,
    notationDeclCallback,
    attributeDeclCallback,
    elementDeclCallback,
    unparsedEntityDeclCallback,
    setDocumentLocatorCallback,
    startDocumentCallback,
    endDocumentCallback,
    NULL,
    NULL,
    referenceCallback,
    charactersCallback,
    ignorableWhitespaceCallback,
    processingInstructionCallback,
    commentCallback,
    warningCallback,
    errorCallback,
    fatalErrorCallback,
    getParameterEntityCallback,
    cdataBlockCallback,
    externalSubsetCallback,
    XML_SAX2_MAGIC,
    NULL,
    startElementNsCallback,
    endElementNsCallback,
    NULL
};

static xmlSAXHandlerPtr callbackSAX2Handler = &callbackSAX2HandlerStruct;

/************************************************************************
 *									*
 *		The tests front-ends                                     *
 *									*
 ************************************************************************/

/**
 * readerTest:
 * @filename: the file to parse
 * @max_size: size of the limit to test
 * @options: parsing options
 * @fail: should a failure be reported
 *
 * Parse a memory generated file using SAX
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
saxTest(const char *filename, size_t limit, int options, int fail) {
    int res = 0;
    xmlParserCtxtPtr ctxt;
    xmlDocPtr doc;
    xmlSAXHandlerPtr old_sax;

    nb_tests++;

    maxlen = limit;
    ctxt = xmlNewParserCtxt();
    if (ctxt == NULL) {
        fprintf(stderr, "Failed to create parser context\n");
	return(1);
    }
    old_sax = ctxt->sax;
    ctxt->sax = callbackSAX2Handler;
    ctxt->userData = NULL;
    doc = xmlCtxtReadFile(ctxt, filename, NULL, options);

    if (doc != NULL) {
        fprintf(stderr, "SAX parsing generated a document !\n");
        xmlFreeDoc(doc);
        res = 0;
    } else if (ctxt->wellFormed == 0) {
        if (fail)
            res = 0;
        else {
            fprintf(stderr, "Failed to parse '%s' %lu\n", filename, limit);
            res = 1;
        }
    } else {
        if (fail) {
            fprintf(stderr, "Failed to get failure for '%s' %lu\n",
                    filename, limit);
            res = 1;
        } else
            res = 0;
    }
    ctxt->sax = old_sax;
    xmlFreeParserCtxt(ctxt);

    return(res);
}
#ifdef LIBXML_READER_ENABLED
/**
 * readerTest:
 * @filename: the file to parse
 * @max_size: size of the limit to test
 * @options: parsing options
 * @fail: should a failure be reported
 *
 * Parse a memory generated file using the xmlReader
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
readerTest(const char *filename, size_t limit, int options, int fail) {
    xmlTextReaderPtr reader;
    int res = 0;
    int ret;

    nb_tests++;

    maxlen = limit;
    reader = xmlReaderForFile(filename , NULL, options);
    if (reader == NULL) {
        fprintf(stderr, "Failed to open '%s' test\n", filename);
	return(1);
    }
    ret = xmlTextReaderRead(reader);
    while (ret == 1) {
        ret = xmlTextReaderRead(reader);
    }
    if (ret != 0) {
        if (fail)
            res = 0;
        else {
            if (strncmp(filename, "crazy:", 6) == 0)
                fprintf(stderr, "Failed to parse '%s' %u\n",
                        filename, crazy_indx);
            else
                fprintf(stderr, "Failed to parse '%s' %lu\n",
                        filename, limit);
            res = 1;
        }
    } else {
        if (fail) {
            if (strncmp(filename, "crazy:", 6) == 0)
                fprintf(stderr, "Failed to get failure for '%s' %u\n",
                        filename, crazy_indx);
            else
                fprintf(stderr, "Failed to get failure for '%s' %lu\n",
                        filename, limit);
            res = 1;
        } else
            res = 0;
    }
    if (timeout)
        res = 1;
    xmlFreeTextReader(reader);

    return(res);
}
#endif

/************************************************************************
 *									*
 *			Tests descriptions				*
 *									*
 ************************************************************************/

typedef int (*functest) (const char *filename, size_t limit, int options,
                         int fail);

typedef struct limitDesc limitDesc;
typedef limitDesc *limitDescPtr;
struct limitDesc {
    const char *name; /* the huge generator name */
    size_t limit;     /* the limit to test */
    int options;      /* extra parser options */
    int fail;         /* whether the test should fail */
};

static limitDesc limitDescriptions[] = {
    /* max length of a text node in content */
    {"huge:textNode", XML_MAX_TEXT_LENGTH - CHUNK, 0, 0},
    {"huge:textNode", XML_MAX_TEXT_LENGTH + CHUNK, 0, 1},
    {"huge:textNode", XML_MAX_TEXT_LENGTH + CHUNK, XML_PARSE_HUGE, 0},
    /* max length of a text node in content */
    {"huge:attrNode", XML_MAX_TEXT_LENGTH - CHUNK, 0, 0},
    {"huge:attrNode", XML_MAX_TEXT_LENGTH + CHUNK, 0, 1},
    {"huge:attrNode", XML_MAX_TEXT_LENGTH + CHUNK, XML_PARSE_HUGE, 0},
    /* max length of a comment node */
    {"huge:commentNode", XML_MAX_TEXT_LENGTH - CHUNK, 0, 0},
    {"huge:commentNode", XML_MAX_TEXT_LENGTH + CHUNK, 0, 1},
    {"huge:commentNode", XML_MAX_TEXT_LENGTH + CHUNK, XML_PARSE_HUGE, 0},
    /* max length of a PI node */
    {"huge:piNode", XML_MAX_TEXT_LENGTH - CHUNK, 0, 0},
    {"huge:piNode", XML_MAX_TEXT_LENGTH + CHUNK, 0, 1},
    {"huge:piNode", XML_MAX_TEXT_LENGTH + CHUNK, XML_PARSE_HUGE, 0},
};

typedef struct testDesc testDesc;
typedef testDesc *testDescPtr;
struct testDesc {
    const char *desc; /* descripton of the test */
    functest    func; /* function implementing the test */
};

static
testDesc testDescriptions[] = {
    { "Parsing of huge files with the sax parser", saxTest},
/*    { "Parsing of huge files with the tree parser", treeTest}, */
#ifdef LIBXML_READER_ENABLED
    { "Parsing of huge files with the reader", readerTest},
#endif
    {NULL, NULL}
};

typedef struct testException testException;
typedef testException *testExceptionPtr;
struct testException {
    unsigned int test;  /* the parser test number */
    unsigned int limit; /* the limit test number */
    int fail;           /* new fail value or -1*/
    size_t size;        /* new limit value or 0 */
};

static
testException testExceptions[] = {
    /* the SAX parser doesn't hit a limit of XML_MAX_TEXT_LENGTH text nodes */
    { 0, 1, 0, 0},
};

static int
launchTests(testDescPtr tst, unsigned int test) {
    int res = 0, err = 0;
    unsigned int i, j;
    size_t limit;
    int fail;

    if (tst == NULL) return(-1);

    for (i = 0;i < sizeof(limitDescriptions)/sizeof(limitDescriptions[0]);i++) {
        limit = limitDescriptions[i].limit;
        fail = limitDescriptions[i].fail;
        /*
         * Handle exceptions if any
         */
        for (j = 0;j < sizeof(testExceptions)/sizeof(testExceptions[0]);j++) {
            if ((testExceptions[j].test == test) &&
                (testExceptions[j].limit == i)) {
                if (testExceptions[j].fail != -1)
                    fail = testExceptions[j].fail;
                if (testExceptions[j].size != 0)
                    limit = testExceptions[j].size;
                break;
            }
        }
        res = tst->func(limitDescriptions[i].name, limit,
                        limitDescriptions[i].options, fail);
        if (res != 0) {
            nb_errors++;
            err++;
        }
    }
    return(err);
}


static int
runtest(unsigned int i) {
    int ret = 0, res;
    int old_errors, old_tests, old_leaks;

    old_errors = nb_errors;
    old_tests = nb_tests;
    old_leaks = nb_leaks;
    if ((tests_quiet == 0) && (testDescriptions[i].desc != NULL))
	printf("## %s\n", testDescriptions[i].desc);
    res = launchTests(&testDescriptions[i], i);
    if (res != 0)
	ret++;
    if (verbose) {
	if ((nb_errors == old_errors) && (nb_leaks == old_leaks))
	    printf("Ran %d tests, no errors\n", nb_tests - old_tests);
	else
	    printf("Ran %d tests, %d errors, %d leaks\n",
		   nb_tests - old_tests,
		   nb_errors - old_errors,
		   nb_leaks - old_leaks);
    }
    return(ret);
}

static int
launchCrazySAX(unsigned int test, int fail) {
    int res = 0, err = 0;

    crazy_indx = test;

    res = saxTest("crazy::test", XML_MAX_LOOKUP_LIMIT - CHUNK, 0, fail);
    if (res != 0) {
        nb_errors++;
        err++;
    }
    if (tests_quiet == 0)
        fprintf(stderr, "%c", crazy[test]);

    return(err);
}

#ifdef LIBXML_READER_ENABLED
static int
launchCrazy(unsigned int test, int fail) {
    int res = 0, err = 0;

    crazy_indx = test;

    res = readerTest("crazy::test", XML_MAX_LOOKUP_LIMIT - CHUNK, 0, fail);
    if (res != 0) {
        nb_errors++;
        err++;
    }
    if (tests_quiet == 0)
        fprintf(stderr, "%c", crazy[test]);

    return(err);
}
#endif

static int get_crazy_fail(int test) {
    /*
     * adding 1000000 of character 'a' leads to parser failure mostly
     * everywhere except in those special spots. Need to be updated
     * each time crazy is updated
     */
    int fail = 1;
    if ((test == 44) || /* PI in Misc */
        ((test >= 50) && (test <= 55)) || /* Comment in Misc */
        (test == 79) || /* PI in DTD */
        ((test >= 85) && (test <= 90)) || /* Comment in DTD */
        (test == 154) || /* PI in Misc */
        ((test >= 160) && (test <= 165)) || /* Comment in Misc */
        ((test >= 178) && (test <= 181)) || /* attribute value */
        (test == 183) || /* Text */
        (test == 189) || /* PI in Content */
        (test == 191) || /* Text */
        ((test >= 195) && (test <= 200)) || /* Comment in Content */
        ((test >= 203) && (test <= 206)) || /* Text */
        (test == 215) || (test == 216) || /* in CDATA */
        (test == 219) || /* Text */
        (test == 231) || /* PI in Misc */
        ((test >= 237) && (test <= 242))) /* Comment in Misc */
        fail = 0;
    return(fail);
}

static int
runcrazy(void) {
    int ret = 0, res = 0;
    int old_errors, old_tests, old_leaks;
    unsigned int i;

    old_errors = nb_errors;
    old_tests = nb_tests;
    old_leaks = nb_leaks;

#ifdef LIBXML_READER_ENABLED
    if (tests_quiet == 0) {
	printf("## Crazy tests on reader\n");
    }
    for (i = 0;i < strlen(crazy);i++) {
        res += launchCrazy(i, get_crazy_fail(i));
        if (res != 0)
            ret++;
    }
#endif

    if (tests_quiet == 0) {
	printf("\n## Crazy tests on SAX\n");
    }
    for (i = 0;i < strlen(crazy);i++) {
        res += launchCrazySAX(i, get_crazy_fail(i));
        if (res != 0)
            ret++;
    }
    if (tests_quiet == 0)
        fprintf(stderr, "\n");
    if (verbose) {
	if ((nb_errors == old_errors) && (nb_leaks == old_leaks))
	    printf("Ran %d tests, no errors\n", nb_tests - old_tests);
	else
	    printf("Ran %d tests, %d errors, %d leaks\n",
		   nb_tests - old_tests,
		   nb_errors - old_errors,
		   nb_leaks - old_leaks);
    }
    return(ret);
}


int
main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    int i, a, ret = 0;
    int subset = 0;

    fillFilling();
    initializeLibxml2();

    for (a = 1; a < argc;a++) {
        if (!strcmp(argv[a], "-v"))
	    verbose = 1;
        else if (!strcmp(argv[a], "-quiet"))
	    tests_quiet = 1;
        else if (!strcmp(argv[a], "-crazy"))
	    subset = 1;
    }
    if (subset == 0) {
	for (i = 0; testDescriptions[i].func != NULL; i++) {
	    ret += runtest(i);
	}
    }
    ret += runcrazy();
    if ((nb_errors == 0) && (nb_leaks == 0)) {
        ret = 0;
	printf("Total %d tests, no errors\n",
	       nb_tests);
    } else {
        ret = 1;
	printf("Total %d tests, %d errors, %d leaks\n",
	       nb_tests, nb_errors, nb_leaks);
    }
    xmlCleanupParser();
    xmlMemoryDump();

    return(ret);
}
