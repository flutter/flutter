/*
 * runtest.c: C program to run libxml2 regression tests without
 *            requiring make or Python, and reducing platform dependancies
 *            to a strict minimum.
 *
 * To compile on Unixes:
 * cc -o runtest `xml2-config --cflags` runtest.c `xml2-config --libs` -lpthread
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
#include <libxml/tree.h>
#include <libxml/uri.h>

#ifdef LIBXML_OUTPUT_ENABLED
#ifdef LIBXML_READER_ENABLED
#include <libxml/xmlreader.h>
#endif

#ifdef LIBXML_XINCLUDE_ENABLED
#include <libxml/xinclude.h>
#endif

#ifdef LIBXML_XPATH_ENABLED
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#ifdef LIBXML_XPTR_ENABLED
#include <libxml/xpointer.h>
#endif
#endif

#ifdef LIBXML_SCHEMAS_ENABLED
#include <libxml/relaxng.h>
#include <libxml/xmlschemas.h>
#include <libxml/xmlschemastypes.h>
#endif

#ifdef LIBXML_PATTERN_ENABLED
#include <libxml/pattern.h>
#endif

#ifdef LIBXML_C14N_ENABLED
#include <libxml/c14n.h>
#endif

#ifdef LIBXML_HTML_ENABLED
#include <libxml/HTMLparser.h>
#include <libxml/HTMLtree.h>

/*
 * pseudo flag for the unification of HTML and XML tests
 */
#define XML_PARSE_HTML 1 << 24
#endif

#if defined(LIBXML_THREAD_ENABLED) && defined(LIBXML_CATALOG_ENABLED)
#include <libxml/globals.h>
#include <libxml/threads.h>
#include <libxml/parser.h>
#include <libxml/catalog.h>
#include <string.h>
#endif

/*
 * O_BINARY is just for Windows compatibility - if it isn't defined
 * on this system, avoid any compilation error
 */
#ifdef	O_BINARY
#define RD_FLAGS	O_RDONLY | O_BINARY
#else
#define	RD_FLAGS	O_RDONLY
#endif

typedef int (*functest) (const char *filename, const char *result,
                         const char *error, int options);

typedef struct testDesc testDesc;
typedef testDesc *testDescPtr;
struct testDesc {
    const char *desc; /* descripton of the test */
    functest    func; /* function implementing the test */
    const char *in;   /* glob to path for input files */
    const char *out;  /* output directory */
    const char *suffix;/* suffix for output files */
    const char *err;  /* suffix for error output files */
    int     options;  /* parser options for the test */
};

static int checkTestFile(const char *filename);

#if defined(_WIN32) && !defined(__CYGWIN__)

#include <windows.h>
#include <io.h>

typedef struct
{
      size_t gl_pathc;    /* Count of paths matched so far  */
      char **gl_pathv;    /* List of matched pathnames.  */
      size_t gl_offs;     /* Slots to reserve in 'gl_pathv'.  */
} glob_t;

#define GLOB_DOOFFS 0
static int glob(const char *pattern, int flags,
                int errfunc(const char *epath, int eerrno),
                glob_t *pglob) {
    glob_t *ret;
    WIN32_FIND_DATA FindFileData;
    HANDLE hFind;
    unsigned int nb_paths = 0;
    char directory[500];
    int len;

    if ((pattern == NULL) || (pglob == NULL)) return(-1);

    strncpy(directory, pattern, 499);
    for (len = strlen(directory);len >= 0;len--) {
        if (directory[len] == '/') {
	    len++;
	    directory[len] = 0;
	    break;
	}
    }
    if (len <= 0)
        len = 0;


    ret = pglob;
    memset(ret, 0, sizeof(glob_t));

    hFind = FindFirstFileA(pattern, &FindFileData);
    if (hFind == INVALID_HANDLE_VALUE)
        return(0);
    nb_paths = 20;
    ret->gl_pathv = (char **) malloc(nb_paths * sizeof(char *));
    if (ret->gl_pathv == NULL) {
	FindClose(hFind);
        return(-1);
    }
    strncpy(directory + len, FindFileData.cFileName, 499 - len);
    ret->gl_pathv[ret->gl_pathc] = strdup(directory);
    if (ret->gl_pathv[ret->gl_pathc] == NULL)
        goto done;
    ret->gl_pathc++;
    while(FindNextFileA(hFind, &FindFileData)) {
        if (FindFileData.cFileName[0] == '.')
	    continue;
        if (ret->gl_pathc + 2 > nb_paths) {
            char **tmp = realloc(ret->gl_pathv, nb_paths * 2 * sizeof(char *));
            if (tmp == NULL)
                break;
            ret->gl_pathv = tmp;
            nb_paths *= 2;
	}
	strncpy(directory + len, FindFileData.cFileName, 499 - len);
	ret->gl_pathv[ret->gl_pathc] = strdup(directory);
        if (ret->gl_pathv[ret->gl_pathc] == NULL)
            break;
        ret->gl_pathc++;
    }
    ret->gl_pathv[ret->gl_pathc] = NULL;

done:
    FindClose(hFind);
    return(0);
}



static void globfree(glob_t *pglob) {
    unsigned int i;
    if (pglob == NULL)
        return;

    for (i = 0;i < pglob->gl_pathc;i++) {
         if (pglob->gl_pathv[i] != NULL)
             free(pglob->gl_pathv[i]);
    }
}

#else
#include <glob.h>
#endif

/************************************************************************
 *									*
 *		Libxml2 specific routines				*
 *									*
 ************************************************************************/

static int nb_tests = 0;
static int nb_errors = 0;
static int nb_leaks = 0;
static int extraMemoryFromResolver = 0;

static int
fatalError(void) {
    fprintf(stderr, "Exitting tests on fatal error\n");
    exit(1);
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

    if (checkTestFile(URL)) {
	ret = xmlNoNetExternalEntityLoader(URL, ID, ctxt);
    } else {
	int memused = xmlMemUsed();
	ret = xmlNoNetExternalEntityLoader(URL, ID, ctxt);
	extraMemoryFromResolver += xmlMemUsed() - memused;
    }

    return(ret);
}

/*
 * Trapping the error messages at the generic level to grab the equivalent of
 * stderr messages on CLI tools.
 */
static char testErrors[32769];
static int testErrorsSize = 0;

static void XMLCDECL
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
#ifdef LIBXML_SCHEMAS_ENABLED
    xmlSchemaInitTypes();
    xmlRelaxNGInitTypes();
#endif
}


/************************************************************************
 *									*
 *		File name and path utilities				*
 *									*
 ************************************************************************/

static const char *baseFilename(const char *filename) {
    const char *cur;
    if (filename == NULL)
        return(NULL);
    cur = &filename[strlen(filename)];
    while ((cur > filename) && (*cur != '/'))
        cur--;
    if (*cur == '/')
        return(cur + 1);
    return(cur);
}

static char *resultFilename(const char *filename, const char *out,
                            const char *suffix) {
    const char *base;
    char res[500];
    char suffixbuff[500];

/*************
    if ((filename[0] == 't') && (filename[1] == 'e') &&
        (filename[2] == 's') && (filename[3] == 't') &&
	(filename[4] == '/'))
	filename = &filename[5];
 *************/

    base = baseFilename(filename);
    if (suffix == NULL)
        suffix = ".tmp";
    if (out == NULL)
        out = "";

    strncpy(suffixbuff,suffix,499);
#ifdef VMS
    if(strstr(base,".") && suffixbuff[0]=='.')
      suffixbuff[0]='_';
#endif

    snprintf(res, 499, "%s%s%s", out, base, suffixbuff);
    res[499] = 0;
    return(strdup(res));
}

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

static int compareFiles(const char *r1, const char *r2) {
    int res1, res2;
    int fd1, fd2;
    char bytes1[4096];
    char bytes2[4096];

    fd1 = open(r1, RD_FLAGS);
    if (fd1 < 0)
        return(-1);
    fd2 = open(r2, RD_FLAGS);
    if (fd2 < 0) {
        close(fd1);
        return(-1);
    }
    while (1) {
        res1 = read(fd1, bytes1, 4096);
        res2 = read(fd2, bytes2, 4096);
	if ((res1 != res2) || (res1 < 0)) {
	    close(fd1);
	    close(fd2);
	    return(1);
	}
	if (res1 == 0)
	    break;
	if (memcmp(bytes1, bytes2, res1) != 0) {
	    close(fd1);
	    close(fd2);
	    return(1);
	}
    }
    close(fd1);
    close(fd2);
    return(0);
}

static int compareFileMem(const char *filename, const char *mem, int size) {
    int res;
    int fd;
    char bytes[4096];
    int idx = 0;
    struct stat info;

    if (stat(filename, &info) < 0)
	return(-1);
    if (info.st_size != size)
        return(-1);
    fd = open(filename, RD_FLAGS);
    if (fd < 0)
        return(-1);
    while (idx < size) {
        res = read(fd, bytes, 4096);
	if (res <= 0)
	    break;
	if (res + idx > size)
	    break;
	if (memcmp(bytes, &mem[idx], res) != 0) {
	    int ix;
	    for (ix=0; ix<res; ix++)
		if (bytes[ix] != mem[idx+ix])
			break;
	    fprintf(stderr,"Compare error at position %d\n", idx+ix);
	    close(fd);
	    return(1);
	}
	idx += res;
    }
    close(fd);
    return(idx != size);
}

static int loadMem(const char *filename, const char **mem, int *size) {
    int fd, res;
    struct stat info;
    char *base;
    int siz = 0;
    if (stat(filename, &info) < 0)
	return(-1);
    base = malloc(info.st_size + 1);
    if (base == NULL)
	return(-1);
    if ((fd = open(filename, RD_FLAGS)) < 0) {
        free(base);
	return(-1);
    }
    while ((res = read(fd, &base[siz], info.st_size - siz)) > 0) {
        siz += res;
    }
    close(fd);
#if !defined(_WIN32)
    if (siz != info.st_size) {
        free(base);
	return(-1);
    }
#endif
    base[siz] = 0;
    *mem = base;
    *size = siz;
    return(0);
}

static int unloadMem(const char *mem) {
    free((char *)mem);
    return(0);
}

/************************************************************************
 *									*
 *		Tests implementations					*
 *									*
 ************************************************************************/

/************************************************************************
 *									*
 *		Parse to SAX based tests				*
 *									*
 ************************************************************************/

static FILE *SAXdebug = NULL;

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
    1,
    NULL,
    NULL, /* startElementNs */
    NULL, /* endElementNs */
    NULL  /* xmlStructuredErrorFunc */
};

static xmlSAXHandlerPtr emptySAXHandler = &emptySAXHandlerStruct;
static int callbacks = 0;
static int quiet = 0;

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
    if (quiet)
	return(0);
    fprintf(SAXdebug, "SAX.isStandalone()\n");
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
    if (quiet)
	return(0);
    fprintf(SAXdebug, "SAX.hasInternalSubset()\n");
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
    if (quiet)
	return(0);
    fprintf(SAXdebug, "SAX.hasExternalSubset()\n");
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.internalSubset(%s,", name);
    if (ExternalID == NULL)
	fprintf(SAXdebug, " ,");
    else
	fprintf(SAXdebug, " %s,", ExternalID);
    if (SystemID == NULL)
	fprintf(SAXdebug, " )\n");
    else
	fprintf(SAXdebug, " %s)\n", SystemID);
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.externalSubset(%s,", name);
    if (ExternalID == NULL)
	fprintf(SAXdebug, " ,");
    else
	fprintf(SAXdebug, " %s,", ExternalID);
    if (SystemID == NULL)
	fprintf(SAXdebug, " )\n");
    else
	fprintf(SAXdebug, " %s)\n", SystemID);
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
    if (quiet)
	return(NULL);
    /* xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx; */


    fprintf(SAXdebug, "SAX.resolveEntity(");
    if (publicId != NULL)
	fprintf(SAXdebug, "%s", (char *)publicId);
    else
	fprintf(SAXdebug, " ");
    if (systemId != NULL)
	fprintf(SAXdebug, ", %s)\n", (char *)systemId);
    else
	fprintf(SAXdebug, ", )\n");
/*********
    if (systemId != NULL) {
        return(xmlNewInputFromFile(ctxt, (char *) systemId));
    }
 *********/
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
    if (quiet)
	return(NULL);
    fprintf(SAXdebug, "SAX.getEntity(%s)\n", name);
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
    if (quiet)
	return(NULL);
    fprintf(SAXdebug, "SAX.getParameterEntity(%s)\n", name);
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.entityDecl(%s, %d, %s, %s, %s)\n",
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
    if (quiet)
        return;
    if (defaultValue == NULL)
        fprintf(SAXdebug, "SAX.attributeDecl(%s, %s, %d, %d, NULL, ...)\n",
                elem, name, type, def);
    else
        fprintf(SAXdebug, "SAX.attributeDecl(%s, %s, %d, %d, %s, ...)\n",
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.elementDecl(%s, %d, ...)\n",
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.notationDecl(%s, %s, %s)\n",
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.unparsedEntityDecl(%s, %s, %s, %s)\n",
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.setDocumentLocator()\n");
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.startDocument()\n");
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.endDocument()\n");
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.startElement(%s", (char *) name);
    if (atts != NULL) {
        for (i = 0;(atts[i] != NULL);i++) {
	    fprintf(SAXdebug, ", %s='", atts[i++]);
	    if (atts[i] != NULL)
	        fprintf(SAXdebug, "%s'", atts[i]);
	}
    }
    fprintf(SAXdebug, ")\n");
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.endElement(%s)\n", (char *) name);
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
    char output[40];
    int i;

    callbacks++;
    if (quiet)
	return;
    for (i = 0;(i<len) && (i < 30);i++)
	output[i] = ch[i];
    output[i] = 0;

    fprintf(SAXdebug, "SAX.characters(%s, %d)\n", output, len);
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.reference(%s)\n", name);
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
    char output[40];
    int i;

    callbacks++;
    if (quiet)
	return;
    for (i = 0;(i<len) && (i < 30);i++)
	output[i] = ch[i];
    output[i] = 0;
    fprintf(SAXdebug, "SAX.ignorableWhitespace(%s, %d)\n", output, len);
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
    if (quiet)
	return;
    if (data != NULL)
	fprintf(SAXdebug, "SAX.processingInstruction(%s, %s)\n",
		(char *) target, (char *) data);
    else
	fprintf(SAXdebug, "SAX.processingInstruction(%s, NULL)\n",
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.pcdata(%.20s, %d)\n",
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.comment(%s)\n", value);
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
    if (quiet)
	return;
    va_start(args, msg);
    fprintf(SAXdebug, "SAX.warning: ");
    vfprintf(SAXdebug, msg, args);
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
    if (quiet)
	return;
    va_start(args, msg);
    fprintf(SAXdebug, "SAX.error: ");
    vfprintf(SAXdebug, msg, args);
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
    if (quiet)
	return;
    va_start(args, msg);
    fprintf(SAXdebug, "SAX.fatalError: ");
    vfprintf(SAXdebug, msg, args);
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

static xmlSAXHandlerPtr debugSAXHandler = &debugSAXHandlerStruct;

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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.startElementNs(%s", (char *) localname);
    if (prefix == NULL)
	fprintf(SAXdebug, ", NULL");
    else
	fprintf(SAXdebug, ", %s", (char *) prefix);
    if (URI == NULL)
	fprintf(SAXdebug, ", NULL");
    else
	fprintf(SAXdebug, ", '%s'", (char *) URI);
    fprintf(SAXdebug, ", %d", nb_namespaces);

    if (namespaces != NULL) {
        for (i = 0;i < nb_namespaces * 2;i++) {
	    fprintf(SAXdebug, ", xmlns");
	    if (namespaces[i] != NULL)
	        fprintf(SAXdebug, ":%s", namespaces[i]);
	    i++;
	    fprintf(SAXdebug, "='%s'", namespaces[i]);
	}
    }
    fprintf(SAXdebug, ", %d, %d", nb_attributes, nb_defaulted);
    if (attributes != NULL) {
        for (i = 0;i < nb_attributes * 5;i += 5) {
	    if (attributes[i + 1] != NULL)
		fprintf(SAXdebug, ", %s:%s='", attributes[i + 1], attributes[i]);
	    else
		fprintf(SAXdebug, ", %s='", attributes[i]);
	    fprintf(SAXdebug, "%.4s...', %d", attributes[i + 3],
		    (int)(attributes[i + 4] - attributes[i + 3]));
	}
    }
    fprintf(SAXdebug, ")\n");
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
    if (quiet)
	return;
    fprintf(SAXdebug, "SAX.endElementNs(%s", (char *) localname);
    if (prefix == NULL)
	fprintf(SAXdebug, ", NULL");
    else
	fprintf(SAXdebug, ", %s", (char *) prefix);
    if (URI == NULL)
	fprintf(SAXdebug, ", NULL)\n");
    else
	fprintf(SAXdebug, ", '%s')\n", (char *) URI);
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

#ifdef LIBXML_HTML_ENABLED
/**
 * htmlstartElementDebug:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when an opening tag has been processed.
 */
static void
htmlstartElementDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name, const xmlChar **atts)
{
    int i;

    fprintf(SAXdebug, "SAX.startElement(%s", (char *) name);
    if (atts != NULL) {
        for (i = 0;(atts[i] != NULL);i++) {
	    fprintf(SAXdebug, ", %s", atts[i++]);
	    if (atts[i] != NULL) {
		unsigned char output[40];
		const unsigned char *att = atts[i];
		int outlen, attlen;
	        fprintf(SAXdebug, "='");
		while ((attlen = strlen((char*)att)) > 0) {
		    outlen = sizeof output - 1;
		    htmlEncodeEntities(output, &outlen, att, &attlen, '\'');
		    output[outlen] = 0;
		    fprintf(SAXdebug, "%s", (char *) output);
		    att += attlen;
		}
		fprintf(SAXdebug, "'");
	    }
	}
    }
    fprintf(SAXdebug, ")\n");
}

/**
 * htmlcharactersDebug:
 * @ctxt:  An XML parser context
 * @ch:  a xmlChar string
 * @len: the number of xmlChar
 *
 * receiving some chars from the parser.
 * Question: how much at a time ???
 */
static void
htmlcharactersDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *ch, int len)
{
    unsigned char output[40];
    int inlen = len, outlen = 30;

    htmlEncodeEntities(output, &outlen, ch, &inlen, 0);
    output[outlen] = 0;

    fprintf(SAXdebug, "SAX.characters(%s, %d)\n", output, len);
}

/**
 * htmlcdataDebug:
 * @ctxt:  An XML parser context
 * @ch:  a xmlChar string
 * @len: the number of xmlChar
 *
 * receiving some cdata chars from the parser.
 * Question: how much at a time ???
 */
static void
htmlcdataDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *ch, int len)
{
    unsigned char output[40];
    int inlen = len, outlen = 30;

    htmlEncodeEntities(output, &outlen, ch, &inlen, 0);
    output[outlen] = 0;

    fprintf(SAXdebug, "SAX.cdata(%s, %d)\n", output, len);
}

static xmlSAXHandler debugHTMLSAXHandlerStruct = {
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
    htmlstartElementDebug,
    endElementDebug,
    referenceDebug,
    htmlcharactersDebug,
    ignorableWhitespaceDebug,
    processingInstructionDebug,
    commentDebug,
    warningDebug,
    errorDebug,
    fatalErrorDebug,
    getParameterEntityDebug,
    htmlcdataDebug,
    externalSubsetDebug,
    1,
    NULL,
    NULL,
    NULL,
    NULL
};

static xmlSAXHandlerPtr debugHTMLSAXHandler = &debugHTMLSAXHandlerStruct;
#endif /* LIBXML_HTML_ENABLED */

#ifdef LIBXML_SAX1_ENABLED
/**
 * saxParseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file using the SAX API and check for errors.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
saxParseTest(const char *filename, const char *result,
             const char *err ATTRIBUTE_UNUSED,
             int options) {
    int ret;
    char *temp;

    nb_tests++;
    temp = resultFilename(filename, "", ".res");
    if (temp == NULL) {
        fprintf(stderr, "out of memory\n");
        fatalError();
    }
    SAXdebug = fopen(temp, "wb");
    if (SAXdebug == NULL) {
        fprintf(stderr, "Failed to write to %s\n", temp);
	free(temp);
	return(-1);
    }

    /* for SAX we really want the callbacks though the context handlers */
    xmlSetStructuredErrorFunc(NULL, NULL);
    xmlSetGenericErrorFunc(NULL, testErrorHandler);

#ifdef LIBXML_HTML_ENABLED
    if (options & XML_PARSE_HTML) {
	htmlSAXParseFile(filename, NULL, emptySAXHandler, NULL);
	ret = 0;
    } else
#endif
    ret = xmlSAXUserParseFile(emptySAXHandler, NULL, filename);
    if (ret == XML_WAR_UNDECLARED_ENTITY) {
        fprintf(SAXdebug, "xmlSAXUserParseFile returned error %d\n", ret);
        ret = 0;
    }
    if (ret != 0) {
        fprintf(stderr, "Failed to parse %s\n", filename);
	ret = 1;
	goto done;
    }
#ifdef LIBXML_HTML_ENABLED
    if (options & XML_PARSE_HTML) {
	htmlSAXParseFile(filename, NULL, debugHTMLSAXHandler, NULL);
	ret = 0;
    } else
#endif
    if (options & XML_PARSE_SAX1) {
	ret = xmlSAXUserParseFile(debugSAXHandler, NULL, filename);
    } else {
	ret = xmlSAXUserParseFile(debugSAX2Handler, NULL, filename);
    }
    if (ret == XML_WAR_UNDECLARED_ENTITY) {
        fprintf(SAXdebug, "xmlSAXUserParseFile returned error %d\n", ret);
        ret = 0;
    }
    fclose(SAXdebug);
    if (compareFiles(temp, result)) {
        fprintf(stderr, "Got a difference for %s\n", filename);
        ret = 1;
    }

done:
    if (temp != NULL) {
        unlink(temp);
        free(temp);
    }

    /* switch back to structured error handling */
    xmlSetGenericErrorFunc(NULL, NULL);
    xmlSetStructuredErrorFunc(NULL, testStructuredErrorHandler);

    return(ret);
}
#endif

/************************************************************************
 *									*
 *		Parse to tree based tests				*
 *									*
 ************************************************************************/
/**
 * oldParseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages: unused
 *
 * Parse a file using the old xmlParseFile API, then serialize back
 * reparse the result and serialize again, then check for deviation
 * in serialization.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
oldParseTest(const char *filename, const char *result,
             const char *err ATTRIBUTE_UNUSED,
	     int options ATTRIBUTE_UNUSED) {
    xmlDocPtr doc;
    char *temp;
    int res = 0;

    nb_tests++;
    /*
     * base of the test, parse with the old API
     */
#ifdef LIBXML_SAX1_ENABLED
    doc = xmlParseFile(filename);
#else
    doc = xmlReadFile(filename, NULL, 0);
#endif
    if (doc == NULL)
        return(1);
    temp = resultFilename(filename, "", ".res");
    if (temp == NULL) {
        fprintf(stderr, "out of memory\n");
        fatalError();
    }
    xmlSaveFile(temp, doc);
    if (compareFiles(temp, result)) {
        res = 1;
    }
    xmlFreeDoc(doc);

    /*
     * Parse the saved result to make sure the round trip is okay
     */
#ifdef LIBXML_SAX1_ENABLED
    doc = xmlParseFile(temp);
#else
    doc = xmlReadFile(temp, NULL, 0);
#endif
    if (doc == NULL)
        return(1);
    xmlSaveFile(temp, doc);
    if (compareFiles(temp, result)) {
        res = 1;
    }
    xmlFreeDoc(doc);

    if (temp != NULL) {
        unlink(temp);
        free(temp);
    }
    return(res);
}

#ifdef LIBXML_PUSH_ENABLED
/**
 * pushParseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages: unused
 *
 * Parse a file using the Push API, then serialize back
 * to check for content.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
pushParseTest(const char *filename, const char *result,
             const char *err ATTRIBUTE_UNUSED,
	     int options) {
    xmlParserCtxtPtr ctxt;
    xmlDocPtr doc;
    const char *base;
    int size, res;
    int cur = 0;

    nb_tests++;
    /*
     * load the document in memory and work from there.
     */
    if (loadMem(filename, &base, &size) != 0) {
        fprintf(stderr, "Failed to load %s\n", filename);
	return(-1);
    }

#ifdef LIBXML_HTML_ENABLED
    if (options & XML_PARSE_HTML)
	ctxt = htmlCreatePushParserCtxt(NULL, NULL, base + cur, 4, filename,
	                                XML_CHAR_ENCODING_NONE);
    else
#endif
    ctxt = xmlCreatePushParserCtxt(NULL, NULL, base + cur, 4, filename);
    xmlCtxtUseOptions(ctxt, options);
    cur += 4;
    while (cur < size) {
        if (cur + 1024 >= size) {
#ifdef LIBXML_HTML_ENABLED
	    if (options & XML_PARSE_HTML)
		htmlParseChunk(ctxt, base + cur, size - cur, 1);
	    else
#endif
	    xmlParseChunk(ctxt, base + cur, size - cur, 1);
	    break;
	} else {
#ifdef LIBXML_HTML_ENABLED
	    if (options & XML_PARSE_HTML)
		htmlParseChunk(ctxt, base + cur, 1024, 0);
	    else
#endif
	    xmlParseChunk(ctxt, base + cur, 1024, 0);
	    cur += 1024;
	}
    }
    doc = ctxt->myDoc;
#ifdef LIBXML_HTML_ENABLED
    if (options & XML_PARSE_HTML)
        res = 1;
    else
#endif
    res = ctxt->wellFormed;
    xmlFreeParserCtxt(ctxt);
    free((char *)base);
    if (!res) {
	xmlFreeDoc(doc);
	fprintf(stderr, "Failed to parse %s\n", filename);
	return(-1);
    }
#ifdef LIBXML_HTML_ENABLED
    if (options & XML_PARSE_HTML)
	htmlDocDumpMemory(doc, (xmlChar **) &base, &size);
    else
#endif
    xmlDocDumpMemory(doc, (xmlChar **) &base, &size);
    xmlFreeDoc(doc);
    res = compareFileMem(result, base, size);
    if ((base == NULL) || (res != 0)) {
	if (base != NULL)
	    xmlFree((char *)base);
        fprintf(stderr, "Result for %s failed\n", filename);
	return(-1);
    }
    xmlFree((char *)base);
    if (err != NULL) {
	res = compareFileMem(err, testErrors, testErrorsSize);
	if (res != 0) {
	    fprintf(stderr, "Error for %s failed\n", filename);
	    return(-1);
	}
    }
    return(0);
}
#endif

/**
 * memParseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages: unused
 *
 * Parse a file using the old xmlReadMemory API, then serialize back
 * reparse the result and serialize again, then check for deviation
 * in serialization.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
memParseTest(const char *filename, const char *result,
             const char *err ATTRIBUTE_UNUSED,
	     int options ATTRIBUTE_UNUSED) {
    xmlDocPtr doc;
    const char *base;
    int size, res;

    nb_tests++;
    /*
     * load and parse the memory
     */
    if (loadMem(filename, &base, &size) != 0) {
        fprintf(stderr, "Failed to load %s\n", filename);
	return(-1);
    }

    doc = xmlReadMemory(base, size, filename, NULL, 0);
    unloadMem(base);
    if (doc == NULL) {
        return(1);
    }
    xmlDocDumpMemory(doc, (xmlChar **) &base, &size);
    xmlFreeDoc(doc);
    res = compareFileMem(result, base, size);
    if ((base == NULL) || (res != 0)) {
	if (base != NULL)
	    xmlFree((char *)base);
        fprintf(stderr, "Result for %s failed\n", filename);
	return(-1);
    }
    xmlFree((char *)base);
    return(0);
}

/**
 * noentParseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages: unused
 *
 * Parse a file with entity resolution, then serialize back
 * reparse the result and serialize again, then check for deviation
 * in serialization.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
noentParseTest(const char *filename, const char *result,
               const char *err  ATTRIBUTE_UNUSED,
	       int options) {
    xmlDocPtr doc;
    char *temp;
    int res = 0;

    nb_tests++;
    /*
     * base of the test, parse with the old API
     */
    doc = xmlReadFile(filename, NULL, options);
    if (doc == NULL)
        return(1);
    temp = resultFilename(filename, "", ".res");
    if (temp == NULL) {
        fprintf(stderr, "Out of memory\n");
        fatalError();
    }
    xmlSaveFile(temp, doc);
    if (compareFiles(temp, result)) {
        res = 1;
    }
    xmlFreeDoc(doc);

    /*
     * Parse the saved result to make sure the round trip is okay
     */
    doc = xmlReadFile(filename, NULL, options);
    if (doc == NULL)
        return(1);
    xmlSaveFile(temp, doc);
    if (compareFiles(temp, result)) {
        res = 1;
    }
    xmlFreeDoc(doc);

    if (temp != NULL) {
        unlink(temp);
        free(temp);
    }
    return(res);
}

/**
 * errParseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file using the xmlReadFile API and check for errors.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
errParseTest(const char *filename, const char *result, const char *err,
             int options) {
    xmlDocPtr doc;
    const char *base = NULL;
    int size, res = 0;

    nb_tests++;
#ifdef LIBXML_HTML_ENABLED
    if (options & XML_PARSE_HTML) {
        doc = htmlReadFile(filename, NULL, options);
    } else
#endif
#ifdef LIBXML_XINCLUDE_ENABLED
    if (options & XML_PARSE_XINCLUDE) {
	doc = xmlReadFile(filename, NULL, options);
	xmlXIncludeProcessFlags(doc, options);
    } else
#endif
    {
	xmlGetWarningsDefaultValue = 1;
	doc = xmlReadFile(filename, NULL, options);
    }
    xmlGetWarningsDefaultValue = 0;
    if (result) {
	if (doc == NULL) {
	    base = "";
	    size = 0;
	} else {
#ifdef LIBXML_HTML_ENABLED
	    if (options & XML_PARSE_HTML) {
		htmlDocDumpMemory(doc, (xmlChar **) &base, &size);
	    } else
#endif
	    xmlDocDumpMemory(doc, (xmlChar **) &base, &size);
	}
	res = compareFileMem(result, base, size);
    }
    if (doc != NULL) {
	if (base != NULL)
	    xmlFree((char *)base);
	xmlFreeDoc(doc);
    }
    if (res != 0) {
        fprintf(stderr, "Result for %s failed\n", filename);
	return(-1);
    }
    if (err != NULL) {
	res = compareFileMem(err, testErrors, testErrorsSize);
	if (res != 0) {
	    fprintf(stderr, "Error for %s failed\n", filename);
	    return(-1);
	}
    } else if (options & XML_PARSE_DTDVALID) {
        if (testErrorsSize != 0)
	    fprintf(stderr, "Validation for %s failed\n", filename);
    }

    return(0);
}

#ifdef LIBXML_READER_ENABLED
/************************************************************************
 *									*
 *		Reader based tests					*
 *									*
 ************************************************************************/

static void processNode(FILE *out, xmlTextReaderPtr reader) {
    const xmlChar *name, *value;
    int type, empty;

    type = xmlTextReaderNodeType(reader);
    empty = xmlTextReaderIsEmptyElement(reader);

    name = xmlTextReaderConstName(reader);
    if (name == NULL)
	name = BAD_CAST "--";

    value = xmlTextReaderConstValue(reader);


    fprintf(out, "%d %d %s %d %d",
	    xmlTextReaderDepth(reader),
	    type,
	    name,
	    empty,
	    xmlTextReaderHasValue(reader));
    if (value == NULL)
	fprintf(out, "\n");
    else {
	fprintf(out, " %s\n", value);
    }
}
static int
streamProcessTest(const char *filename, const char *result, const char *err,
                  xmlTextReaderPtr reader, const char *rng, int options) {
    int ret;
    char *temp = NULL;
    FILE *t = NULL;

    if (reader == NULL)
        return(-1);

    nb_tests++;
    if (result != NULL) {
	temp = resultFilename(filename, "", ".res");
	if (temp == NULL) {
	    fprintf(stderr, "Out of memory\n");
	    fatalError();
	}
	t = fopen(temp, "wb");
	if (t == NULL) {
	    fprintf(stderr, "Can't open temp file %s\n", temp);
	    free(temp);
	    return(-1);
	}
    }
#ifdef LIBXML_SCHEMAS_ENABLED
    if (rng != NULL) {
	ret = xmlTextReaderRelaxNGValidate(reader, rng);
	if (ret < 0) {
	    testErrorHandler(NULL, "Relax-NG schema %s failed to compile\n",
	                     rng);
	    fclose(t);
            if (temp != NULL) {
                unlink(temp);
                free(temp);
            }
	    return(0);
	}
    }
#endif
    xmlGetWarningsDefaultValue = 1;
    ret = xmlTextReaderRead(reader);
    while (ret == 1) {
	if ((t != NULL) && (rng == NULL))
	    processNode(t, reader);
        ret = xmlTextReaderRead(reader);
    }
    if (ret != 0) {
        testErrorHandler(NULL, "%s : failed to parse\n", filename);
    }
    if (rng != NULL) {
        if (xmlTextReaderIsValid(reader) != 1) {
	    testErrorHandler(NULL, "%s fails to validate\n", filename);
	} else {
	    testErrorHandler(NULL, "%s validates\n", filename);
	}
    }
    xmlGetWarningsDefaultValue = 0;
    if (t != NULL) {
        fclose(t);
	ret = compareFiles(temp, result);
        if (temp != NULL) {
            unlink(temp);
            free(temp);
        }
	if (ret) {
	    fprintf(stderr, "Result for %s failed\n", filename);
	    return(-1);
	}
    }
    if (err != NULL) {
	ret = compareFileMem(err, testErrors, testErrorsSize);
	if (ret != 0) {
	    fprintf(stderr, "Error for %s failed\n", filename);
	    printf("%s", testErrors);
	    return(-1);
	}
    }

    return(0);
}

/**
 * streamParseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file using the reader API and check for errors.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
streamParseTest(const char *filename, const char *result, const char *err,
                int options) {
    xmlTextReaderPtr reader;
    int ret;

    reader = xmlReaderForFile(filename, NULL, options);
    ret = streamProcessTest(filename, result, err, reader, NULL, options);
    xmlFreeTextReader(reader);
    return(ret);
}

/**
 * walkerParseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file using the walker, i.e. a reader built from a atree.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
walkerParseTest(const char *filename, const char *result, const char *err,
                int options) {
    xmlDocPtr doc;
    xmlTextReaderPtr reader;
    int ret;

    doc = xmlReadFile(filename, NULL, options);
    if (doc == NULL) {
        fprintf(stderr, "Failed to parse %s\n", filename);
	return(-1);
    }
    reader = xmlReaderWalker(doc);
    ret = streamProcessTest(filename, result, err, reader, NULL, options);
    xmlFreeTextReader(reader);
    xmlFreeDoc(doc);
    return(ret);
}

/**
 * streamMemParseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file using the reader API from memory and check for errors.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
streamMemParseTest(const char *filename, const char *result, const char *err,
                   int options) {
    xmlTextReaderPtr reader;
    int ret;
    const char *base;
    int size;

    /*
     * load and parse the memory
     */
    if (loadMem(filename, &base, &size) != 0) {
        fprintf(stderr, "Failed to load %s\n", filename);
	return(-1);
    }
    reader = xmlReaderForMemory(base, size, filename, NULL, options);
    ret = streamProcessTest(filename, result, err, reader, NULL, options);
    free((char *)base);
    xmlFreeTextReader(reader);
    return(ret);
}
#endif

#ifdef LIBXML_XPATH_ENABLED
#ifdef LIBXML_DEBUG_ENABLED
/************************************************************************
 *									*
 *		XPath and XPointer based tests				*
 *									*
 ************************************************************************/

static FILE *xpathOutput;
static xmlDocPtr xpathDocument;

static void
testXPath(const char *str, int xptr, int expr) {
    xmlXPathObjectPtr res;
    xmlXPathContextPtr ctxt;

    nb_tests++;
#if defined(LIBXML_XPTR_ENABLED)
    if (xptr) {
	ctxt = xmlXPtrNewContext(xpathDocument, NULL, NULL);
	res = xmlXPtrEval(BAD_CAST str, ctxt);
    } else {
#endif
	ctxt = xmlXPathNewContext(xpathDocument);
	ctxt->node = xmlDocGetRootElement(xpathDocument);
	if (expr)
	    res = xmlXPathEvalExpression(BAD_CAST str, ctxt);
	else {
	    /* res = xmlXPathEval(BAD_CAST str, ctxt); */
	    xmlXPathCompExprPtr comp;

	    comp = xmlXPathCompile(BAD_CAST str);
	    if (comp != NULL) {
		res = xmlXPathCompiledEval(comp, ctxt);
		xmlXPathFreeCompExpr(comp);
	    } else
		res = NULL;
	}
#if defined(LIBXML_XPTR_ENABLED)
    }
#endif
    xmlXPathDebugDumpObject(xpathOutput, res, 0);
    xmlXPathFreeObject(res);
    xmlXPathFreeContext(ctxt);
}

/**
 * xpathExprTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file containing XPath standalone expressions and evaluate them
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
xpathCommonTest(const char *filename, const char *result,
                int xptr, int expr) {
    FILE *input;
    char expression[5000];
    int len, ret = 0;
    char *temp;

    temp = resultFilename(filename, "", ".res");
    if (temp == NULL) {
        fprintf(stderr, "Out of memory\n");
        fatalError();
    }
    xpathOutput = fopen(temp, "wb");
    if (xpathOutput == NULL) {
	fprintf(stderr, "failed to open output file %s\n", temp);
        free(temp);
	return(-1);
    }

    input = fopen(filename, "rb");
    if (input == NULL) {
        xmlGenericError(xmlGenericErrorContext,
		"Cannot open %s for reading\n", filename);
        free(temp);
	return(-1);
    }
    while (fgets(expression, 4500, input) != NULL) {
	len = strlen(expression);
	len--;
	while ((len >= 0) &&
	       ((expression[len] == '\n') || (expression[len] == '\t') ||
		(expression[len] == '\r') || (expression[len] == ' '))) len--;
	expression[len + 1] = 0;
	if (len >= 0) {
	    fprintf(xpathOutput,
	            "\n========================\nExpression: %s\n",
		    expression) ;
	    testXPath(expression, xptr, expr);
	}
    }

    fclose(input);
    fclose(xpathOutput);
    if (result != NULL) {
	ret = compareFiles(temp, result);
	if (ret) {
	    fprintf(stderr, "Result for %s failed\n", filename);
	}
    }

    if (temp != NULL) {
        unlink(temp);
        free(temp);
    }
    return(ret);
}

/**
 * xpathExprTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file containing XPath standalone expressions and evaluate them
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
xpathExprTest(const char *filename, const char *result,
              const char *err ATTRIBUTE_UNUSED,
              int options ATTRIBUTE_UNUSED) {
    return(xpathCommonTest(filename, result, 0, 1));
}

/**
 * xpathDocTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file containing XPath expressions and evaluate them against
 * a set of corresponding documents.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
xpathDocTest(const char *filename,
             const char *resul ATTRIBUTE_UNUSED,
             const char *err ATTRIBUTE_UNUSED,
             int options) {

    char pattern[500];
    char result[500];
    glob_t globbuf;
    size_t i;
    int ret = 0, res;

    xpathDocument = xmlReadFile(filename, NULL,
                                options | XML_PARSE_DTDATTR | XML_PARSE_NOENT);
    if (xpathDocument == NULL) {
        fprintf(stderr, "Failed to load %s\n", filename);
	return(-1);
    }

    snprintf(pattern, 499, "./test/XPath/tests/%s*", baseFilename(filename));
    pattern[499] = 0;
    globbuf.gl_offs = 0;
    glob(pattern, GLOB_DOOFFS, NULL, &globbuf);
    for (i = 0;i < globbuf.gl_pathc;i++) {
        snprintf(result, 499, "result/XPath/tests/%s",
	         baseFilename(globbuf.gl_pathv[i]));
	res = xpathCommonTest(globbuf.gl_pathv[i], &result[0], 0, 0);
	if (res != 0)
	    ret = res;
    }
    globfree(&globbuf);

    xmlFreeDoc(xpathDocument);
    return(ret);
}

#ifdef LIBXML_XPTR_ENABLED
/**
 * xptrDocTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file containing XPath expressions and evaluate them against
 * a set of corresponding documents.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
xptrDocTest(const char *filename,
            const char *resul ATTRIBUTE_UNUSED,
            const char *err ATTRIBUTE_UNUSED,
            int options) {

    char pattern[500];
    char result[500];
    glob_t globbuf;
    size_t i;
    int ret = 0, res;

    xpathDocument = xmlReadFile(filename, NULL,
                                options | XML_PARSE_DTDATTR | XML_PARSE_NOENT);
    if (xpathDocument == NULL) {
        fprintf(stderr, "Failed to load %s\n", filename);
	return(-1);
    }

    snprintf(pattern, 499, "./test/XPath/xptr/%s*", baseFilename(filename));
    pattern[499] = 0;
    globbuf.gl_offs = 0;
    glob(pattern, GLOB_DOOFFS, NULL, &globbuf);
    for (i = 0;i < globbuf.gl_pathc;i++) {
        snprintf(result, 499, "result/XPath/xptr/%s",
	         baseFilename(globbuf.gl_pathv[i]));
	res = xpathCommonTest(globbuf.gl_pathv[i], &result[0], 1, 0);
	if (res != 0)
	    ret = res;
    }
    globfree(&globbuf);

    xmlFreeDoc(xpathDocument);
    return(ret);
}
#endif /* LIBXML_XPTR_ENABLED */

/**
 * xmlidDocTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file containing xml:id and check for errors and verify
 * that XPath queries will work on them as expected.
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
xmlidDocTest(const char *filename,
             const char *result,
             const char *err,
             int options) {

    int res = 0;
    int ret = 0;
    char *temp;

    xpathDocument = xmlReadFile(filename, NULL,
                                options | XML_PARSE_DTDATTR | XML_PARSE_NOENT);
    if (xpathDocument == NULL) {
        fprintf(stderr, "Failed to load %s\n", filename);
	return(-1);
    }

    temp = resultFilename(filename, "", ".res");
    if (temp == NULL) {
        fprintf(stderr, "Out of memory\n");
        fatalError();
    }
    xpathOutput = fopen(temp, "wb");
    if (xpathOutput == NULL) {
	fprintf(stderr, "failed to open output file %s\n", temp);
        xmlFreeDoc(xpathDocument);
        free(temp);
	return(-1);
    }

    testXPath("id('bar')", 0, 0);

    fclose(xpathOutput);
    if (result != NULL) {
	ret = compareFiles(temp, result);
	if (ret) {
	    fprintf(stderr, "Result for %s failed\n", filename);
	    res = 1;
	}
    }

    if (temp != NULL) {
        unlink(temp);
        free(temp);
    }
    xmlFreeDoc(xpathDocument);

    if (err != NULL) {
	ret = compareFileMem(err, testErrors, testErrorsSize);
	if (ret != 0) {
	    fprintf(stderr, "Error for %s failed\n", filename);
	    res = 1;
	}
    }
    return(res);
}

#endif /* LIBXML_DEBUG_ENABLED */
#endif /* XPATH */
/************************************************************************
 *									*
 *			URI based tests					*
 *									*
 ************************************************************************/

static void
handleURI(const char *str, const char *base, FILE *o) {
    int ret;
    xmlURIPtr uri;
    xmlChar *res = NULL;

    uri = xmlCreateURI();

    if (base == NULL) {
	ret = xmlParseURIReference(uri, str);
	if (ret != 0)
	    fprintf(o, "%s : error %d\n", str, ret);
	else {
	    xmlNormalizeURIPath(uri->path);
	    xmlPrintURI(o, uri);
	    fprintf(o, "\n");
	}
    } else {
	res = xmlBuildURI((xmlChar *)str, (xmlChar *) base);
	if (res != NULL) {
	    fprintf(o, "%s\n", (char *) res);
	}
	else
	    fprintf(o, "::ERROR::\n");
    }
    if (res != NULL)
	xmlFree(res);
    xmlFreeURI(uri);
}

/**
 * uriCommonTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file containing URI and check for errors
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
uriCommonTest(const char *filename,
             const char *result,
             const char *err,
             const char *base) {
    char *temp;
    FILE *o, *f;
    char str[1024];
    int res = 0, i, ret;

    temp = resultFilename(filename, "", ".res");
    if (temp == NULL) {
        fprintf(stderr, "Out of memory\n");
        fatalError();
    }
    o = fopen(temp, "wb");
    if (o == NULL) {
	fprintf(stderr, "failed to open output file %s\n", temp);
        free(temp);
	return(-1);
    }
    f = fopen(filename, "rb");
    if (f == NULL) {
	fprintf(stderr, "failed to open input file %s\n", filename);
	fclose(o);
        if (temp != NULL) {
            unlink(temp);
            free(temp);
        }
	return(-1);
    }

    while (1) {
	/*
	 * read one line in string buffer.
	 */
	if (fgets (&str[0], sizeof (str) - 1, f) == NULL)
	   break;

	/*
	 * remove the ending spaces
	 */
	i = strlen(str);
	while ((i > 0) &&
	       ((str[i - 1] == '\n') || (str[i - 1] == '\r') ||
		(str[i - 1] == ' ') || (str[i - 1] == '\t'))) {
	    i--;
	    str[i] = 0;
	}
	nb_tests++;
	handleURI(str, base, o);
    }

    fclose(f);
    fclose(o);

    if (result != NULL) {
	ret = compareFiles(temp, result);
	if (ret) {
	    fprintf(stderr, "Result for %s failed\n", filename);
	    res = 1;
	}
    }
    if (err != NULL) {
	ret = compareFileMem(err, testErrors, testErrorsSize);
	if (ret != 0) {
	    fprintf(stderr, "Error for %s failed\n", filename);
	    res = 1;
	}
    }

    if (temp != NULL) {
        unlink(temp);
        free(temp);
    }
    return(res);
}

/**
 * uriParseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file containing URI and check for errors
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
uriParseTest(const char *filename,
             const char *result,
             const char *err,
             int options ATTRIBUTE_UNUSED) {
    return(uriCommonTest(filename, result, err, NULL));
}

/**
 * uriBaseTest:
 * @filename: the file to parse
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file containing URI, compose them against a fixed base and
 * check for errors
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
uriBaseTest(const char *filename,
             const char *result,
             const char *err,
             int options ATTRIBUTE_UNUSED) {
    return(uriCommonTest(filename, result, err,
                         "http://foo.com/path/to/index.html?orig#help"));
}

static int urip_success = 1;
static int urip_current = 0;
static const char *urip_testURLs[] = {
    "urip://example.com/a b.html",
    "urip://example.com/a%20b.html",
    "file:///path/to/a b.html",
    "file:///path/to/a%20b.html",
    "/path/to/a b.html",
    "/path/to/a%20b.html",
    "urip://example.com/r" "\xe9" "sum" "\xe9" ".html",
    "urip://example.com/test?a=1&b=2%263&c=4#foo",
    NULL
};
static const char *urip_rcvsURLs[] = {
    /* it is an URI the strings must be escaped */
    "urip://example.com/a%20b.html",
    /* check that % escaping is not broken */
    "urip://example.com/a%20b.html",
    /* it's an URI path the strings must be escaped */
    "file:///path/to/a%20b.html",
    /* check that % escaping is not broken */
    "file:///path/to/a%20b.html",
    /* this is not an URI, this is a path, so this should not be escaped */
    "/path/to/a b.html",
    /* check that paths with % are not broken */
    "/path/to/a%20b.html",
    /* out of context the encoding can't be guessed byte by byte conversion */
    "urip://example.com/r%E9sum%E9.html",
    /* verify we don't destroy URIs especially the query part */
    "urip://example.com/test?a=1&b=2%263&c=4#foo",
    NULL
};
static const char *urip_res = "<list/>";
static const char *urip_cur = NULL;
static int urip_rlen;

/**
 * uripMatch:
 * @URI: an URI to test
 *
 * Check for an urip: query
 *
 * Returns 1 if yes and 0 if another Input module should be used
 */
static int
uripMatch(const char * URI) {
    if ((URI == NULL) || (!strcmp(URI, "file:///etc/xml/catalog")))
        return(0);
    /* Verify we received the escaped URL */
    if (strcmp(urip_rcvsURLs[urip_current], URI))
	urip_success = 0;
    return(1);
}

/**
 * uripOpen:
 * @URI: an URI to test
 *
 * Return a pointer to the urip: query handler, in this example simply
 * the urip_current pointer...
 *
 * Returns an Input context or NULL in case or error
 */
static void *
uripOpen(const char * URI) {
    if ((URI == NULL) || (!strcmp(URI, "file:///etc/xml/catalog")))
        return(NULL);
    /* Verify we received the escaped URL */
    if (strcmp(urip_rcvsURLs[urip_current], URI))
	urip_success = 0;
    urip_cur = urip_res;
    urip_rlen = strlen(urip_res);
    return((void *) urip_cur);
}

/**
 * uripClose:
 * @context: the read context
 *
 * Close the urip: query handler
 *
 * Returns 0 or -1 in case of error
 */
static int
uripClose(void * context) {
    if (context == NULL) return(-1);
    urip_cur = NULL;
    urip_rlen = 0;
    return(0);
}

/**
 * uripRead:
 * @context: the read context
 * @buffer: where to store data
 * @len: number of bytes to read
 *
 * Implement an urip: query read.
 *
 * Returns the number of bytes read or -1 in case of error
 */
static int
uripRead(void * context, char * buffer, int len) {
   const char *ptr = (const char *) context;

   if ((context == NULL) || (buffer == NULL) || (len < 0))
       return(-1);

   if (len > urip_rlen) len = urip_rlen;
   memcpy(buffer, ptr, len);
   urip_rlen -= len;
   return(len);
}

static int
urip_checkURL(const char *URL) {
    xmlDocPtr doc;

    doc = xmlReadFile(URL, NULL, 0);
    if (doc == NULL)
        return(-1);
    xmlFreeDoc(doc);
    return(1);
}

/**
 * uriPathTest:
 * @filename: ignored
 * @result: ignored
 * @err: ignored
 *
 * Run a set of tests to check how Path and URI are handled before
 * being passed to the I/O layer
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
uriPathTest(const char *filename ATTRIBUTE_UNUSED,
             const char *result ATTRIBUTE_UNUSED,
             const char *err ATTRIBUTE_UNUSED,
             int options ATTRIBUTE_UNUSED) {
    int parsed;
    int failures = 0;

    /*
     * register the new I/O handlers
     */
    if (xmlRegisterInputCallbacks(uripMatch, uripOpen, uripRead, uripClose) < 0)
    {
        fprintf(stderr, "failed to register HTTP handler\n");
	return(-1);
    }

    for (urip_current = 0;urip_testURLs[urip_current] != NULL;urip_current++) {
        urip_success = 1;
        parsed = urip_checkURL(urip_testURLs[urip_current]);
	if (urip_success != 1) {
	    fprintf(stderr, "failed the URL passing test for %s",
	            urip_testURLs[urip_current]);
	    failures++;
	} else if (parsed != 1) {
	    fprintf(stderr, "failed the parsing test for %s",
	            urip_testURLs[urip_current]);
	    failures++;
	}
	nb_tests++;
    }

    xmlPopInputCallbacks();
    return(failures);
}

#ifdef LIBXML_SCHEMAS_ENABLED
/************************************************************************
 *									*
 *			Schemas tests					*
 *									*
 ************************************************************************/
static int
schemasOneTest(const char *sch,
               const char *filename,
               const char *result,
	       const char *err,
	       int options,
	       xmlSchemaPtr schemas) {
    xmlDocPtr doc;
    xmlSchemaValidCtxtPtr ctxt;
    int ret = 0;
    int validResult = 0;
    char *temp;
    FILE *schemasOutput;

    doc = xmlReadFile(filename, NULL, options);
    if (doc == NULL) {
        fprintf(stderr, "failed to parse instance %s for %s\n", filename, sch);
	return(-1);
    }

    temp = resultFilename(result, "", ".res");
    if (temp == NULL) {
        fprintf(stderr, "Out of memory\n");
        fatalError();
    }
    schemasOutput = fopen(temp, "wb");
    if (schemasOutput == NULL) {
	fprintf(stderr, "failed to open output file %s\n", temp);
	xmlFreeDoc(doc);
        free(temp);
	return(-1);
    }

    ctxt = xmlSchemaNewValidCtxt(schemas);
    xmlSchemaSetValidErrors(ctxt,
         (xmlSchemaValidityErrorFunc) testErrorHandler,
         (xmlSchemaValidityWarningFunc) testErrorHandler,
	 ctxt);
    validResult = xmlSchemaValidateDoc(ctxt, doc);
    if (validResult == 0) {
	fprintf(schemasOutput, "%s validates\n", filename);
    } else if (validResult > 0) {
	fprintf(schemasOutput, "%s fails to validate\n", filename);
    } else {
	fprintf(schemasOutput, "%s validation generated an internal error\n",
	       filename);
    }
    fclose(schemasOutput);
    if (result) {
	if (compareFiles(temp, result)) {
	    fprintf(stderr, "Result for %s on %s failed\n", filename, sch);
	    ret = 1;
	}
    }
    if (temp != NULL) {
        unlink(temp);
        free(temp);
    }

    if ((validResult != 0) && (err != NULL)) {
	if (compareFileMem(err, testErrors, testErrorsSize)) {
	    fprintf(stderr, "Error for %s on %s failed\n", filename, sch);
	    ret = 1;
	}
    }

    xmlSchemaFreeValidCtxt(ctxt);
    xmlFreeDoc(doc);
    return(ret);
}
/**
 * schemasTest:
 * @filename: the schemas file
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a file containing URI, compose them against a fixed base and
 * check for errors
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
schemasTest(const char *filename,
            const char *resul ATTRIBUTE_UNUSED,
            const char *errr ATTRIBUTE_UNUSED,
            int options) {
    const char *base = baseFilename(filename);
    const char *base2;
    const char *instance;
    xmlSchemaParserCtxtPtr ctxt;
    xmlSchemaPtr schemas;
    int res = 0, len, ret;
    char pattern[500];
    char prefix[500];
    char result[500];
    char err[500];
    glob_t globbuf;
    size_t i;
    char count = 0;

    /* first compile the schemas if possible */
    ctxt = xmlSchemaNewParserCtxt(filename);
    xmlSchemaSetParserErrors(ctxt,
         (xmlSchemaValidityErrorFunc) testErrorHandler,
         (xmlSchemaValidityWarningFunc) testErrorHandler,
	 ctxt);
    schemas = xmlSchemaParse(ctxt);
    xmlSchemaFreeParserCtxt(ctxt);

    /*
     * most of the mess is about the output filenames generated by the Makefile
     */
    len = strlen(base);
    if ((len > 499) || (len < 5)) {
        xmlSchemaFree(schemas);
	return(-1);
    }
    len -= 4; /* remove trailing .xsd */
    if (base[len - 2] == '_') {
        len -= 2; /* remove subtest number */
    }
    if (base[len - 2] == '_') {
        len -= 2; /* remove subtest number */
    }
    memcpy(prefix, base, len);
    prefix[len] = 0;

    snprintf(pattern, 499, "./test/schemas/%s_?.xml", prefix);
    pattern[499] = 0;

    if (base[len] == '_') {
        len += 2;
	memcpy(prefix, base, len);
	prefix[len] = 0;
    }

    globbuf.gl_offs = 0;
    glob(pattern, GLOB_DOOFFS, NULL, &globbuf);
    for (i = 0;i < globbuf.gl_pathc;i++) {
        testErrorsSize = 0;
	testErrors[0] = 0;
        instance = globbuf.gl_pathv[i];
	base2 = baseFilename(instance);
	len = strlen(base2);
	if ((len > 6) && (base2[len - 6] == '_')) {
	    count = base2[len - 5];
	    snprintf(result, 499, "result/schemas/%s_%c",
		     prefix, count);
	    result[499] = 0;
	    snprintf(err, 499, "result/schemas/%s_%c.err",
		     prefix, count);
	    err[499] = 0;
	} else {
	    fprintf(stderr, "don't know how to process %s\n", instance);
	    continue;
	}
	if (schemas == NULL) {
	} else {
	    nb_tests++;
	    ret = schemasOneTest(filename, instance, result, err,
	                         options, schemas);
	    if (ret != 0)
		res = ret;
	}
    }
    globfree(&globbuf);
    xmlSchemaFree(schemas);

    return(res);
}

/************************************************************************
 *									*
 *			Schemas tests					*
 *									*
 ************************************************************************/
static int
rngOneTest(const char *sch,
               const char *filename,
               const char *result,
	       const char *err,
	       int options,
	       xmlRelaxNGPtr schemas) {
    xmlDocPtr doc;
    xmlRelaxNGValidCtxtPtr ctxt;
    int ret = 0;
    char *temp;
    FILE *schemasOutput;

    doc = xmlReadFile(filename, NULL, options);
    if (doc == NULL) {
        fprintf(stderr, "failed to parse instance %s for %s\n", filename, sch);
	return(-1);
    }

    temp = resultFilename(result, "", ".res");
    if (temp == NULL) {
        fprintf(stderr, "Out of memory\n");
        fatalError();
    }
    schemasOutput = fopen(temp, "wb");
    if (schemasOutput == NULL) {
	fprintf(stderr, "failed to open output file %s\n", temp);
	xmlFreeDoc(doc);
        free(temp);
	return(-1);
    }

    ctxt = xmlRelaxNGNewValidCtxt(schemas);
    xmlRelaxNGSetValidErrors(ctxt,
         (xmlRelaxNGValidityErrorFunc) testErrorHandler,
         (xmlRelaxNGValidityWarningFunc) testErrorHandler,
	 ctxt);
    ret = xmlRelaxNGValidateDoc(ctxt, doc);
    if (ret == 0) {
	testErrorHandler(NULL, "%s validates\n", filename);
    } else if (ret > 0) {
	testErrorHandler(NULL, "%s fails to validate\n", filename);
    } else {
	testErrorHandler(NULL, "%s validation generated an internal error\n",
	       filename);
    }
    fclose(schemasOutput);
    ret = 0;
    if (result) {
	if (compareFiles(temp, result)) {
	    fprintf(stderr, "Result for %s on %s failed\n", filename, sch);
	    ret = 1;
	}
    }
    if (temp != NULL) {
        unlink(temp);
        free(temp);
    }

    if (err != NULL) {
	if (compareFileMem(err, testErrors, testErrorsSize)) {
	    fprintf(stderr, "Error for %s on %s failed\n", filename, sch);
	    ret = 1;
	    printf("%s", testErrors);
	}
    }


    xmlRelaxNGFreeValidCtxt(ctxt);
    xmlFreeDoc(doc);
    return(ret);
}
/**
 * rngTest:
 * @filename: the schemas file
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse an RNG schemas and then apply it to the related .xml
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
rngTest(const char *filename,
            const char *resul ATTRIBUTE_UNUSED,
            const char *errr ATTRIBUTE_UNUSED,
            int options) {
    const char *base = baseFilename(filename);
    const char *base2;
    const char *instance;
    xmlRelaxNGParserCtxtPtr ctxt;
    xmlRelaxNGPtr schemas;
    int res = 0, len, ret = 0;
    char pattern[500];
    char prefix[500];
    char result[500];
    char err[500];
    glob_t globbuf;
    size_t i;
    char count = 0;

    /* first compile the schemas if possible */
    ctxt = xmlRelaxNGNewParserCtxt(filename);
    xmlRelaxNGSetParserErrors(ctxt,
         (xmlRelaxNGValidityErrorFunc) testErrorHandler,
         (xmlRelaxNGValidityWarningFunc) testErrorHandler,
	 ctxt);
    schemas = xmlRelaxNGParse(ctxt);
    xmlRelaxNGFreeParserCtxt(ctxt);

    /*
     * most of the mess is about the output filenames generated by the Makefile
     */
    len = strlen(base);
    if ((len > 499) || (len < 5)) {
        xmlRelaxNGFree(schemas);
	return(-1);
    }
    len -= 4; /* remove trailing .rng */
    memcpy(prefix, base, len);
    prefix[len] = 0;

    snprintf(pattern, 499, "./test/relaxng/%s_?.xml", prefix);
    pattern[499] = 0;

    globbuf.gl_offs = 0;
    glob(pattern, GLOB_DOOFFS, NULL, &globbuf);
    for (i = 0;i < globbuf.gl_pathc;i++) {
        testErrorsSize = 0;
	testErrors[0] = 0;
        instance = globbuf.gl_pathv[i];
	base2 = baseFilename(instance);
	len = strlen(base2);
	if ((len > 6) && (base2[len - 6] == '_')) {
	    count = base2[len - 5];
	    snprintf(result, 499, "result/relaxng/%s_%c",
		     prefix, count);
	    result[499] = 0;
	    snprintf(err, 499, "result/relaxng/%s_%c.err",
		     prefix, count);
	    err[499] = 0;
	} else {
	    fprintf(stderr, "don't know how to process %s\n", instance);
	    continue;
	}
	if (schemas == NULL) {
	} else {
	    nb_tests++;
	    ret = rngOneTest(filename, instance, result, err,
	                         options, schemas);
	    if (res != 0)
		ret = res;
	}
    }
    globfree(&globbuf);
    xmlRelaxNGFree(schemas);

    return(ret);
}

#ifdef LIBXML_READER_ENABLED
/**
 * rngStreamTest:
 * @filename: the schemas file
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a set of files with streaming, applying an RNG schemas
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
rngStreamTest(const char *filename,
            const char *resul ATTRIBUTE_UNUSED,
            const char *errr ATTRIBUTE_UNUSED,
            int options) {
    const char *base = baseFilename(filename);
    const char *base2;
    const char *instance;
    int res = 0, len, ret;
    char pattern[500];
    char prefix[500];
    char result[500];
    char err[500];
    glob_t globbuf;
    size_t i;
    char count = 0;
    xmlTextReaderPtr reader;
    int disable_err = 0;

    /*
     * most of the mess is about the output filenames generated by the Makefile
     */
    len = strlen(base);
    if ((len > 499) || (len < 5)) {
	fprintf(stderr, "len(base) == %d !\n", len);
	return(-1);
    }
    len -= 4; /* remove trailing .rng */
    memcpy(prefix, base, len);
    prefix[len] = 0;

    /*
     * strictly unifying the error messages is nearly impossible this
     * hack is also done in the Makefile
     */
    if ((!strcmp(prefix, "tutor10_1")) || (!strcmp(prefix, "tutor10_2")) ||
        (!strcmp(prefix, "tutor3_2")) || (!strcmp(prefix, "307377")) ||
        (!strcmp(prefix, "tutor8_2")))
	disable_err = 1;

    snprintf(pattern, 499, "./test/relaxng/%s_?.xml", prefix);
    pattern[499] = 0;

    globbuf.gl_offs = 0;
    glob(pattern, GLOB_DOOFFS, NULL, &globbuf);
    for (i = 0;i < globbuf.gl_pathc;i++) {
        testErrorsSize = 0;
	testErrors[0] = 0;
        instance = globbuf.gl_pathv[i];
	base2 = baseFilename(instance);
	len = strlen(base2);
	if ((len > 6) && (base2[len - 6] == '_')) {
	    count = base2[len - 5];
	    snprintf(result, 499, "result/relaxng/%s_%c",
		     prefix, count);
	    result[499] = 0;
	    snprintf(err, 499, "result/relaxng/%s_%c.err",
		     prefix, count);
	    err[499] = 0;
	} else {
	    fprintf(stderr, "don't know how to process %s\n", instance);
	    continue;
	}
	reader = xmlReaderForFile(instance, NULL, options);
	if (reader == NULL) {
	    fprintf(stderr, "Failed to build reder for %s\n", instance);
	}
	if (disable_err == 1)
	    ret = streamProcessTest(instance, result, NULL, reader, filename,
	                            options);
	else
	    ret = streamProcessTest(instance, result, err, reader, filename,
	                            options);
	xmlFreeTextReader(reader);
	if (ret != 0) {
	    fprintf(stderr, "instance %s failed\n", instance);
	    res = ret;
	}
    }
    globfree(&globbuf);

    return(res);
}
#endif /* READER */

#endif

#ifdef LIBXML_PATTERN_ENABLED
#ifdef LIBXML_READER_ENABLED
/************************************************************************
 *									*
 *			Patterns tests					*
 *									*
 ************************************************************************/
static void patternNode(FILE *out, xmlTextReaderPtr reader,
                        const char *pattern, xmlPatternPtr patternc,
			xmlStreamCtxtPtr patstream) {
    xmlChar *path = NULL;
    int match = -1;
    int type, empty;

    type = xmlTextReaderNodeType(reader);
    empty = xmlTextReaderIsEmptyElement(reader);

    if (type == XML_READER_TYPE_ELEMENT) {
	/* do the check only on element start */
	match = xmlPatternMatch(patternc, xmlTextReaderCurrentNode(reader));

	if (match) {
	    path = xmlGetNodePath(xmlTextReaderCurrentNode(reader));
	    fprintf(out, "Node %s matches pattern %s\n", path, pattern);
	}
    }
    if (patstream != NULL) {
	int ret;

	if (type == XML_READER_TYPE_ELEMENT) {
	    ret = xmlStreamPush(patstream,
				xmlTextReaderConstLocalName(reader),
				xmlTextReaderConstNamespaceUri(reader));
	    if (ret < 0) {
		fprintf(out, "xmlStreamPush() failure\n");
		xmlFreeStreamCtxt(patstream);
		patstream = NULL;
	    } else if (ret != match) {
		if (path == NULL) {
		    path = xmlGetNodePath(
				   xmlTextReaderCurrentNode(reader));
		}
		fprintf(out,
			"xmlPatternMatch and xmlStreamPush disagree\n");
		fprintf(out,
			"  pattern %s node %s\n",
			pattern, path);
	    }


	}
	if ((type == XML_READER_TYPE_END_ELEMENT) ||
	    ((type == XML_READER_TYPE_ELEMENT) && (empty))) {
	    ret = xmlStreamPop(patstream);
	    if (ret < 0) {
		fprintf(out, "xmlStreamPop() failure\n");
		xmlFreeStreamCtxt(patstream);
		patstream = NULL;
	    }
	}
    }
    if (path != NULL)
	xmlFree(path);
}

/**
 * patternTest:
 * @filename: the schemas file
 * @result: the file with expected result
 * @err: the file with error messages
 *
 * Parse a set of files with streaming, applying an RNG schemas
 *
 * Returns 0 in case of success, an error code otherwise
 */
static int
patternTest(const char *filename,
            const char *resul ATTRIBUTE_UNUSED,
            const char *err ATTRIBUTE_UNUSED,
            int options) {
    xmlPatternPtr patternc = NULL;
    xmlStreamCtxtPtr patstream = NULL;
    FILE *o, *f;
    char str[1024];
    char xml[500];
    char result[500];
    int len, i;
    int ret = 0, res;
    char *temp;
    xmlTextReaderPtr reader;
    xmlDocPtr doc;

    len = strlen(filename);
    len -= 4;
    memcpy(xml, filename, len);
    xml[len] = 0;
    snprintf(result, 499, "result/pattern/%s", baseFilename(xml));
    result[499] = 0;
    memcpy(xml + len, ".xml", 5);

    if (!checkTestFile(xml)) {
	fprintf(stderr, "Missing xml file %s\n", xml);
	return(-1);
    }
    if (!checkTestFile(result)) {
	fprintf(stderr, "Missing result file %s\n", result);
	return(-1);
    }
    f = fopen(filename, "rb");
    if (f == NULL) {
        fprintf(stderr, "Failed to open %s\n", filename);
	return(-1);
    }
    temp = resultFilename(filename, "", ".res");
    if (temp == NULL) {
        fprintf(stderr, "Out of memory\n");
        fatalError();
    }
    o = fopen(temp, "wb");
    if (o == NULL) {
	fprintf(stderr, "failed to open output file %s\n", temp);
	fclose(f);
        free(temp);
	return(-1);
    }
    while (1) {
	/*
	 * read one line in string buffer.
	 */
	if (fgets (&str[0], sizeof (str) - 1, f) == NULL)
	   break;

	/*
	 * remove the ending spaces
	 */
	i = strlen(str);
	while ((i > 0) &&
	       ((str[i - 1] == '\n') || (str[i - 1] == '\r') ||
		(str[i - 1] == ' ') || (str[i - 1] == '\t'))) {
	    i--;
	    str[i] = 0;
	}
	doc = xmlReadFile(xml, NULL, options);
	if (doc == NULL) {
	    fprintf(stderr, "Failed to parse %s\n", xml);
	    ret = 1;
	} else {
	    xmlNodePtr root;
	    const xmlChar *namespaces[22];
	    int j;
	    xmlNsPtr ns;

	    root = xmlDocGetRootElement(doc);
	    for (ns = root->nsDef, j = 0;ns != NULL && j < 20;ns=ns->next) {
		namespaces[j++] = ns->href;
		namespaces[j++] = ns->prefix;
	    }
	    namespaces[j++] = NULL;
	    namespaces[j] = NULL;

	    patternc = xmlPatterncompile((const xmlChar *) str, doc->dict,
					 0, &namespaces[0]);
	    if (patternc == NULL) {
		testErrorHandler(NULL,
			"Pattern %s failed to compile\n", str);
		xmlFreeDoc(doc);
		ret = 1;
		continue;
	    }
	    patstream = xmlPatternGetStreamCtxt(patternc);
	    if (patstream != NULL) {
		ret = xmlStreamPush(patstream, NULL, NULL);
		if (ret < 0) {
		    fprintf(stderr, "xmlStreamPush() failure\n");
		    xmlFreeStreamCtxt(patstream);
		    patstream = NULL;
		}
	    }
	    nb_tests++;

	    reader = xmlReaderWalker(doc);
	    res = xmlTextReaderRead(reader);
	    while (res == 1) {
		patternNode(o, reader, str, patternc, patstream);
		res = xmlTextReaderRead(reader);
	    }
	    if (res != 0) {
		fprintf(o, "%s : failed to parse\n", filename);
	    }
	    xmlFreeTextReader(reader);
	    xmlFreeDoc(doc);
	    xmlFreeStreamCtxt(patstream);
	    patstream = NULL;
	    xmlFreePattern(patternc);

	}
    }

    fclose(f);
    fclose(o);

    ret = compareFiles(temp, result);
    if (ret) {
	fprintf(stderr, "Result for %s failed\n", filename);
	ret = 1;
    }
    if (temp != NULL) {
        unlink(temp);
        free(temp);
    }
    return(ret);
}
#endif /* READER */
#endif /* PATTERN */
#ifdef LIBXML_C14N_ENABLED
/************************************************************************
 *									*
 *			Canonicalization tests				*
 *									*
 ************************************************************************/
static xmlXPathObjectPtr
load_xpath_expr (xmlDocPtr parent_doc, const char* filename) {
    xmlXPathObjectPtr xpath;
    xmlDocPtr doc;
    xmlChar *expr;
    xmlXPathContextPtr ctx;
    xmlNodePtr node;
    xmlNsPtr ns;

    /*
     * load XPath expr as a file
     */
    xmlLoadExtDtdDefaultValue = XML_DETECT_IDS | XML_COMPLETE_ATTRS;
    xmlSubstituteEntitiesDefault(1);

    doc = xmlReadFile(filename, NULL, XML_PARSE_DTDATTR | XML_PARSE_NOENT);
    if (doc == NULL) {
	fprintf(stderr, "Error: unable to parse file \"%s\"\n", filename);
	return(NULL);
    }

    /*
     * Check the document is of the right kind
     */
    if(xmlDocGetRootElement(doc) == NULL) {
        fprintf(stderr,"Error: empty document for file \"%s\"\n", filename);
	xmlFreeDoc(doc);
	return(NULL);
    }

    node = doc->children;
    while(node != NULL && !xmlStrEqual(node->name, (const xmlChar *)"XPath")) {
	node = node->next;
    }

    if(node == NULL) {
        fprintf(stderr,"Error: XPath element expected in the file  \"%s\"\n", filename);
	xmlFreeDoc(doc);
	return(NULL);
    }

    expr = xmlNodeGetContent(node);
    if(expr == NULL) {
        fprintf(stderr,"Error: XPath content element is NULL \"%s\"\n", filename);
	xmlFreeDoc(doc);
	return(NULL);
    }

    ctx = xmlXPathNewContext(parent_doc);
    if(ctx == NULL) {
        fprintf(stderr,"Error: unable to create new context\n");
        xmlFree(expr);
        xmlFreeDoc(doc);
        return(NULL);
    }

    /*
     * Register namespaces
     */
    ns = node->nsDef;
    while(ns != NULL) {
	if(xmlXPathRegisterNs(ctx, ns->prefix, ns->href) != 0) {
	    fprintf(stderr,"Error: unable to register NS with prefix=\"%s\" and href=\"%s\"\n", ns->prefix, ns->href);
    xmlFree(expr);
	    xmlXPathFreeContext(ctx);
	    xmlFreeDoc(doc);
	    return(NULL);
	}
	ns = ns->next;
    }

    /*
     * Evaluate xpath
     */
    xpath = xmlXPathEvalExpression(expr, ctx);
    if(xpath == NULL) {
        fprintf(stderr,"Error: unable to evaluate xpath expression\n");
xmlFree(expr);
        xmlXPathFreeContext(ctx);
        xmlFreeDoc(doc);
        return(NULL);
    }

    /* print_xpath_nodes(xpath->nodesetval); */

    xmlFree(expr);
    xmlXPathFreeContext(ctx);
    xmlFreeDoc(doc);
    return(xpath);
}

/*
 * Macro used to grow the current buffer.
 */
#define xxx_growBufferReentrant() {						\
    buffer_size *= 2;							\
    buffer = (xmlChar **)						\
	xmlRealloc(buffer, buffer_size * sizeof(xmlChar*));	\
    if (buffer == NULL) {						\
	perror("realloc failed");					\
	return(NULL);							\
    }									\
}

static xmlChar **
parse_list(xmlChar *str) {
    xmlChar **buffer;
    xmlChar **out = NULL;
    int buffer_size = 0;
    int len;

    if(str == NULL) {
	return(NULL);
    }

    len = xmlStrlen(str);
    if((str[0] == '\'') && (str[len - 1] == '\'')) {
	str[len - 1] = '\0';
	str++;
    }
    /*
     * allocate an translation buffer.
     */
    buffer_size = 1000;
    buffer = (xmlChar **) xmlMalloc(buffer_size * sizeof(xmlChar*));
    if (buffer == NULL) {
	perror("malloc failed");
	return(NULL);
    }
    out = buffer;

    while(*str != '\0') {
	if (out - buffer > buffer_size - 10) {
	    int indx = out - buffer;

	    xxx_growBufferReentrant();
	    out = &buffer[indx];
	}
	(*out++) = str;
	while(*str != ',' && *str != '\0') ++str;
	if(*str == ',') *(str++) = '\0';
    }
    (*out) = NULL;
    return buffer;
}

static int
c14nRunTest(const char* xml_filename, int with_comments, int mode,
	    const char* xpath_filename, const char *ns_filename,
	    const char* result_file) {
    xmlDocPtr doc;
    xmlXPathObjectPtr xpath = NULL;
    xmlChar *result = NULL;
    int ret;
    xmlChar **inclusive_namespaces = NULL;
    const char *nslist = NULL;
    int nssize;


    /*
     * build an XML tree from a the file; we need to add default
     * attributes and resolve all character and entities references
     */
    xmlLoadExtDtdDefaultValue = XML_DETECT_IDS | XML_COMPLETE_ATTRS;
    xmlSubstituteEntitiesDefault(1);

    doc = xmlReadFile(xml_filename, NULL, XML_PARSE_DTDATTR | XML_PARSE_NOENT);
    if (doc == NULL) {
	fprintf(stderr, "Error: unable to parse file \"%s\"\n", xml_filename);
	return(-1);
    }

    /*
     * Check the document is of the right kind
     */
    if(xmlDocGetRootElement(doc) == NULL) {
        fprintf(stderr,"Error: empty document for file \"%s\"\n", xml_filename);
	xmlFreeDoc(doc);
	return(-1);
    }

    /*
     * load xpath file if specified
     */
    if(xpath_filename) {
	xpath = load_xpath_expr(doc, xpath_filename);
	if(xpath == NULL) {
	    fprintf(stderr,"Error: unable to evaluate xpath expression\n");
	    xmlFreeDoc(doc);
	    return(-1);
	}
    }

    if (ns_filename != NULL) {
        if (loadMem(ns_filename, &nslist, &nssize)) {
	    fprintf(stderr,"Error: unable to evaluate xpath expression\n");
	    if(xpath != NULL) xmlXPathFreeObject(xpath);
	    xmlFreeDoc(doc);
	    return(-1);
	}
        inclusive_namespaces = parse_list((xmlChar *) nslist);
    }

    /*
     * Canonical form
     */
    /* fprintf(stderr,"File \"%s\" loaded: start canonization\n", xml_filename); */
    ret = xmlC14NDocDumpMemory(doc,
	    (xpath) ? xpath->nodesetval : NULL,
	    mode, inclusive_namespaces,
	    with_comments, &result);
    if (ret >= 0) {
	if(result != NULL) {
	    if (compareFileMem(result_file, (const char *) result, ret)) {
		fprintf(stderr, "Result mismatch for %s\n", xml_filename);
		fprintf(stderr, "RESULT:\n%s\n", (const char*)result);
	        ret = -1;
	    }
	}
    } else {
	fprintf(stderr,"Error: failed to canonicalize XML file \"%s\" (ret=%d)\n", xml_filename, ret);
	ret = -1;
    }

    /*
     * Cleanup
     */
    if (result != NULL) xmlFree(result);
    if(xpath != NULL) xmlXPathFreeObject(xpath);
    if (inclusive_namespaces != NULL) xmlFree(inclusive_namespaces);
    if (nslist != NULL) free((char *) nslist);
    xmlFreeDoc(doc);

    return(ret);
}

static int
c14nCommonTest(const char *filename, int with_comments, int mode,
               const char *subdir) {
    char buf[500];
    char prefix[500];
    const char *base;
    int len;
    char *result = NULL;
    char *xpath = NULL;
    char *ns = NULL;
    int ret = 0;

    base = baseFilename(filename);
    len = strlen(base);
    len -= 4;
    memcpy(prefix, base, len);
    prefix[len] = 0;

    snprintf(buf, 499, "result/c14n/%s/%s", subdir,prefix);
    if (!checkTestFile(buf)) {
        fprintf(stderr, "Missing result file %s", buf);
	return(-1);
    }
    result = strdup(buf);
    snprintf(buf, 499, "test/c14n/%s/%s.xpath", subdir,prefix);
    if (checkTestFile(buf)) {
	xpath = strdup(buf);
    }
    snprintf(buf, 499, "test/c14n/%s/%s.ns", subdir,prefix);
    if (checkTestFile(buf)) {
	ns = strdup(buf);
    }

    nb_tests++;
    if (c14nRunTest(filename, with_comments, mode,
                    xpath, ns, result) < 0)
        ret = 1;

    if (result != NULL) free(result);
    if (xpath != NULL) free(xpath);
    if (ns != NULL) free(ns);
    return(ret);
}

static int
c14nWithCommentTest(const char *filename,
                    const char *resul ATTRIBUTE_UNUSED,
		    const char *err ATTRIBUTE_UNUSED,
		    int options ATTRIBUTE_UNUSED) {
    return(c14nCommonTest(filename, 1, XML_C14N_1_0, "with-comments"));
}
static int
c14nWithoutCommentTest(const char *filename,
                    const char *resul ATTRIBUTE_UNUSED,
		    const char *err ATTRIBUTE_UNUSED,
		    int options ATTRIBUTE_UNUSED) {
    return(c14nCommonTest(filename, 0, XML_C14N_1_0, "without-comments"));
}
static int
c14nExcWithoutCommentTest(const char *filename,
                    const char *resul ATTRIBUTE_UNUSED,
		    const char *err ATTRIBUTE_UNUSED,
		    int options ATTRIBUTE_UNUSED) {
    return(c14nCommonTest(filename, 0, XML_C14N_EXCLUSIVE_1_0, "exc-without-comments"));
}
static int
c14n11WithoutCommentTest(const char *filename,
                    const char *resul ATTRIBUTE_UNUSED,
		    const char *err ATTRIBUTE_UNUSED,
		    int options ATTRIBUTE_UNUSED) {
    return(c14nCommonTest(filename, 0, XML_C14N_1_1, "1-1-without-comments"));
}
#endif
#if defined(LIBXML_THREAD_ENABLED) && defined(LIBXML_CATALOG_ENABLED) && defined (LIBXML_SAX1_ENABLED)
/************************************************************************
 *									*
 *			Catalog and threads test			*
 *									*
 ************************************************************************/

/*
 * mostly a cut and paste from testThreads.c
 */
#define	MAX_ARGC	20

static const char *catalog = "test/threads/complex.xml";
static const char *testfiles[] = {
    "test/threads/abc.xml",
    "test/threads/acb.xml",
    "test/threads/bac.xml",
    "test/threads/bca.xml",
    "test/threads/cab.xml",
    "test/threads/cba.xml",
    "test/threads/invalid.xml",
};

static const char *Okay = "OK";
static const char *Failed = "Failed";

#ifndef xmlDoValidityCheckingDefaultValue
#error xmlDoValidityCheckingDefaultValue is not a macro
#endif
#ifndef xmlGenericErrorContext
#error xmlGenericErrorContext is not a macro
#endif

static void *
thread_specific_data(void *private_data)
{
    xmlDocPtr myDoc;
    const char *filename = (const char *) private_data;
    int okay = 1;

    if (!strcmp(filename, "test/threads/invalid.xml")) {
        xmlDoValidityCheckingDefaultValue = 0;
        xmlGenericErrorContext = stdout;
    } else {
        xmlDoValidityCheckingDefaultValue = 1;
        xmlGenericErrorContext = stderr;
    }
    myDoc = xmlParseFile(filename);
    if (myDoc) {
        xmlFreeDoc(myDoc);
    } else {
        printf("parse failed\n");
        okay = 0;
    }
    if (!strcmp(filename, "test/threads/invalid.xml")) {
        if (xmlDoValidityCheckingDefaultValue != 0) {
            printf("ValidityCheckingDefaultValue override failed\n");
            okay = 0;
        }
        if (xmlGenericErrorContext != stdout) {
            printf("xmlGenericErrorContext override failed\n");
            okay = 0;
        }
    } else {
        if (xmlDoValidityCheckingDefaultValue != 1) {
            printf("ValidityCheckingDefaultValue override failed\n");
            okay = 0;
        }
        if (xmlGenericErrorContext != stderr) {
            printf("xmlGenericErrorContext override failed\n");
            okay = 0;
        }
    }
    if (okay == 0)
        return ((void *) Failed);
    return ((void *) Okay);
}

#if defined WIN32
#include <windows.h>
#include <string.h>

#define TEST_REPEAT_COUNT 500

static HANDLE tid[MAX_ARGC];

static DWORD WINAPI
win32_thread_specific_data(void *private_data)
{
    return((DWORD) thread_specific_data(private_data));
}

static int
testThread(void)
{
    unsigned int i, repeat;
    unsigned int num_threads = sizeof(testfiles) / sizeof(testfiles[0]);
    DWORD results[MAX_ARGC];
    BOOL ret;
    int res = 0;

    xmlInitParser();
    for (repeat = 0; repeat < TEST_REPEAT_COUNT; repeat++) {
        xmlLoadCatalog(catalog);
        nb_tests++;

        for (i = 0; i < num_threads; i++) {
            results[i] = 0;
            tid[i] = (HANDLE) - 1;
        }

        for (i = 0; i < num_threads; i++) {
            DWORD useless;

            tid[i] = CreateThread(NULL, 0,
                                  win32_thread_specific_data,
				  (void *) testfiles[i], 0,
                                  &useless);
            if (tid[i] == NULL) {
                fprintf(stderr, "CreateThread failed\n");
                return(1);
            }
        }

        if (WaitForMultipleObjects(num_threads, tid, TRUE, INFINITE) ==
            WAIT_FAILED) {
            fprintf(stderr, "WaitForMultipleObjects failed\n");
	    return(1);
	}

        for (i = 0; i < num_threads; i++) {
            ret = GetExitCodeThread(tid[i], &results[i]);
            if (ret == 0) {
                fprintf(stderr, "GetExitCodeThread failed\n");
                return(1);
            }
            CloseHandle(tid[i]);
        }

        xmlCatalogCleanup();
        for (i = 0; i < num_threads; i++) {
            if (results[i] != (DWORD) Okay) {
                fprintf(stderr, "Thread %d handling %s failed\n",
		        i, testfiles[i]);
	        res = 1;
	    }
        }
    }

    return (res);
}

#elif defined __BEOS__
#include <OS.h>

static thread_id tid[MAX_ARGC];

static int
testThread(void)
{
    unsigned int i, repeat;
    unsigned int num_threads = sizeof(testfiles) / sizeof(testfiles[0]);
    void *results[MAX_ARGC];
    status_t ret;
    int res = 0;

    xmlInitParser();
    for (repeat = 0; repeat < 500; repeat++) {
        xmlLoadCatalog(catalog);
        for (i = 0; i < num_threads; i++) {
            results[i] = NULL;
            tid[i] = (thread_id) - 1;
        }
        for (i = 0; i < num_threads; i++) {
            tid[i] =
                spawn_thread(thread_specific_data, "xmlTestThread",
                             B_NORMAL_PRIORITY, (void *) testfiles[i]);
            if (tid[i] < B_OK) {
                fprintf(stderr, "beos_thread_create failed\n");
                return (1);
            }
            printf("beos_thread_create %d -> %d\n", i, tid[i]);
        }
        for (i = 0; i < num_threads; i++) {
            ret = wait_for_thread(tid[i], &results[i]);
            printf("beos_thread_wait %d -> %d\n", i, ret);
            if (ret != B_OK) {
                fprintf(stderr, "beos_thread_wait failed\n");
                return (1);
            }
        }

        xmlCatalogCleanup();
        ret = B_OK;
        for (i = 0; i < num_threads; i++)
            if (results[i] != (void *) Okay) {
                printf("Thread %d handling %s failed\n", i, testfiles[i]);
                ret = B_ERROR;
            }
    }
    if (ret != B_OK)
        return(1);
    return (0);
}

#elif defined HAVE_PTHREAD_H
#include <pthread.h>

static pthread_t tid[MAX_ARGC];

static int
testThread(void)
{
    unsigned int i, repeat;
    unsigned int num_threads = sizeof(testfiles) / sizeof(testfiles[0]);
    void *results[MAX_ARGC];
    int ret;
    int res = 0;

    xmlInitParser();

    for (repeat = 0; repeat < 500; repeat++) {
        xmlLoadCatalog(catalog);
        nb_tests++;

        for (i = 0; i < num_threads; i++) {
            results[i] = NULL;
            tid[i] = (pthread_t) - 1;
        }

        for (i = 0; i < num_threads; i++) {
            ret = pthread_create(&tid[i], 0, thread_specific_data,
                                 (void *) testfiles[i]);
            if (ret != 0) {
                fprintf(stderr, "pthread_create failed\n");
                return (1);
            }
        }
        for (i = 0; i < num_threads; i++) {
            ret = pthread_join(tid[i], &results[i]);
            if (ret != 0) {
                fprintf(stderr, "pthread_join failed\n");
                return (1);
            }
        }

        xmlCatalogCleanup();
        for (i = 0; i < num_threads; i++)
            if (results[i] != (void *) Okay) {
                fprintf(stderr, "Thread %d handling %s failed\n",
                        i, testfiles[i]);
                res = 1;
            }
    }
    return (res);
}

#else
static int
testThread(void)
{
    fprintf(stderr,
            "Specific platform thread support not detected\n");
    return (-1);
}
#endif
static int
threadsTest(const char *filename ATTRIBUTE_UNUSED,
	    const char *resul ATTRIBUTE_UNUSED,
	    const char *err ATTRIBUTE_UNUSED,
	    int options ATTRIBUTE_UNUSED) {
    return(testThread());
}
#endif
/************************************************************************
 *									*
 *			Tests Descriptions				*
 *									*
 ************************************************************************/

static
testDesc testDescriptions[] = {
    { "XML regression tests" ,
      oldParseTest, "./test/*", "result/", "", NULL,
      0 },
    { "XML regression tests on memory" ,
      memParseTest, "./test/*", "result/", "", NULL,
      0 },
    { "XML entity subst regression tests" ,
      noentParseTest, "./test/*", "result/noent/", "", NULL,
      XML_PARSE_NOENT },
    { "XML Namespaces regression tests",
      errParseTest, "./test/namespaces/*", "result/namespaces/", "", ".err",
      0 },
    { "Error cases regression tests",
      errParseTest, "./test/errors/*.xml", "result/errors/", "", ".err",
      0 },
#ifdef LIBXML_READER_ENABLED
    { "Error cases stream regression tests",
      streamParseTest, "./test/errors/*.xml", "result/errors/", NULL, ".str",
      0 },
    { "Reader regression tests",
      streamParseTest, "./test/*", "result/", ".rdr", NULL,
      0 },
    { "Reader entities substitution regression tests",
      streamParseTest, "./test/*", "result/", ".rde", NULL,
      XML_PARSE_NOENT },
    { "Reader on memory regression tests",
      streamMemParseTest, "./test/*", "result/", ".rdr", NULL,
      0 },
    { "Walker regression tests",
      walkerParseTest, "./test/*", "result/", ".rdr", NULL,
      0 },
#endif
#ifdef LIBXML_SAX1_ENABLED
    { "SAX1 callbacks regression tests" ,
      saxParseTest, "./test/*", "result/", ".sax", NULL,
      XML_PARSE_SAX1 },
    { "SAX2 callbacks regression tests" ,
      saxParseTest, "./test/*", "result/", ".sax2", NULL,
      0 },
#endif
#ifdef LIBXML_PUSH_ENABLED
    { "XML push regression tests" ,
      pushParseTest, "./test/*", "result/", "", NULL,
      0 },
#endif
#ifdef LIBXML_HTML_ENABLED
    { "HTML regression tests" ,
      errParseTest, "./test/HTML/*", "result/HTML/", "", ".err",
      XML_PARSE_HTML },
#ifdef LIBXML_PUSH_ENABLED
    { "Push HTML regression tests" ,
      pushParseTest, "./test/HTML/*", "result/HTML/", "", ".err",
      XML_PARSE_HTML },
#endif
#ifdef LIBXML_SAX1_ENABLED
    { "HTML SAX regression tests" ,
      saxParseTest, "./test/HTML/*", "result/HTML/", ".sax", NULL,
      XML_PARSE_HTML },
#endif
#endif
#ifdef LIBXML_VALID_ENABLED
    { "Valid documents regression tests" ,
      errParseTest, "./test/VCM/*", NULL, NULL, NULL,
      XML_PARSE_DTDVALID },
    { "Validity checking regression tests" ,
      errParseTest, "./test/VC/*", "result/VC/", NULL, "",
      XML_PARSE_DTDVALID },
#ifdef LIBXML_READER_ENABLED
    { "Streaming validity checking regression tests" ,
      streamParseTest, "./test/valid/*.xml", "result/valid/", NULL, ".err.rdr",
      XML_PARSE_DTDVALID },
    { "Streaming validity error checking regression tests" ,
      streamParseTest, "./test/VC/*", "result/VC/", NULL, ".rdr",
      XML_PARSE_DTDVALID },
#endif
    { "General documents valid regression tests" ,
      errParseTest, "./test/valid/*", "result/valid/", "", ".err",
      XML_PARSE_DTDVALID },
#endif
#ifdef LIBXML_XINCLUDE_ENABLED
    { "XInclude regression tests" ,
      errParseTest, "./test/XInclude/docs/*", "result/XInclude/", "", NULL,
      /* Ignore errors at this point ".err", */
      XML_PARSE_XINCLUDE },
#ifdef LIBXML_READER_ENABLED
    { "XInclude xmlReader regression tests",
      streamParseTest, "./test/XInclude/docs/*", "result/XInclude/", ".rdr",
      /* Ignore errors at this point ".err", */
      NULL, XML_PARSE_XINCLUDE },
#endif
    { "XInclude regression tests stripping include nodes" ,
      errParseTest, "./test/XInclude/docs/*", "result/XInclude/", "", NULL,
      /* Ignore errors at this point ".err", */
      XML_PARSE_XINCLUDE | XML_PARSE_NOXINCNODE },
#ifdef LIBXML_READER_ENABLED
    { "XInclude xmlReader regression tests stripping include nodes",
      streamParseTest, "./test/XInclude/docs/*", "result/XInclude/", ".rdr",
      /* Ignore errors at this point ".err", */
      NULL, XML_PARSE_XINCLUDE | XML_PARSE_NOXINCNODE },
#endif
#endif
#ifdef LIBXML_XPATH_ENABLED
#ifdef LIBXML_DEBUG_ENABLED
    { "XPath expressions regression tests" ,
      xpathExprTest, "./test/XPath/expr/*", "result/XPath/expr/", "", NULL,
      0 },
    { "XPath document queries regression tests" ,
      xpathDocTest, "./test/XPath/docs/*", NULL, NULL, NULL,
      0 },
#ifdef LIBXML_XPTR_ENABLED
    { "XPointer document queries regression tests" ,
      xptrDocTest, "./test/XPath/docs/*", NULL, NULL, NULL,
      0 },
#endif
    { "xml:id regression tests" ,
      xmlidDocTest, "./test/xmlid/*", "result/xmlid/", "", ".err",
      0 },
#endif
#endif
    { "URI parsing tests" ,
      uriParseTest, "./test/URI/*.uri", "result/URI/", "", NULL,
      0 },
    { "URI base composition tests" ,
      uriBaseTest, "./test/URI/*.data", "result/URI/", "", NULL,
      0 },
    { "Path URI conversion tests" ,
      uriPathTest, NULL, NULL, NULL, NULL,
      0 },
#ifdef LIBXML_SCHEMAS_ENABLED
    { "Schemas regression tests" ,
      schemasTest, "./test/schemas/*_*.xsd", NULL, NULL, NULL,
      0 },
    { "Relax-NG regression tests" ,
      rngTest, "./test/relaxng/*.rng", NULL, NULL, NULL,
      XML_PARSE_DTDATTR | XML_PARSE_NOENT },
#ifdef LIBXML_READER_ENABLED
    { "Relax-NG streaming regression tests" ,
      rngStreamTest, "./test/relaxng/*.rng", NULL, NULL, NULL,
      XML_PARSE_DTDATTR | XML_PARSE_NOENT },
#endif
#endif
#ifdef LIBXML_PATTERN_ENABLED
#ifdef LIBXML_READER_ENABLED
    { "Pattern regression tests" ,
      patternTest, "./test/pattern/*.pat", "result/pattern/", NULL, NULL,
      0 },
#endif
#endif
#ifdef LIBXML_C14N_ENABLED
    { "C14N with comments regression tests" ,
      c14nWithCommentTest, "./test/c14n/with-comments/*.xml", NULL, NULL, NULL,
      0 },
    { "C14N without comments regression tests" ,
      c14nWithoutCommentTest, "./test/c14n/without-comments/*.xml", NULL, NULL, NULL,
      0 },
    { "C14N exclusive without comments regression tests" ,
      c14nExcWithoutCommentTest, "./test/c14n/exc-without-comments/*.xml", NULL, NULL, NULL,
      0 },
    { "C14N 1.1 without comments regression tests" ,
      c14n11WithoutCommentTest, "./test/c14n/1-1-without-comments/*.xml", NULL, NULL, NULL,
      0 },
#endif
#if defined(LIBXML_THREAD_ENABLED) && defined(LIBXML_CATALOG_ENABLED) && defined(LIBXML_SAX1_ENABLED)
    { "Catalog and Threads regression tests" ,
      threadsTest, NULL, NULL, NULL, NULL,
      0 },
#endif
    {NULL, NULL, NULL, NULL, NULL, NULL, 0}
};

/************************************************************************
 *									*
 *		The main code driving the tests				*
 *									*
 ************************************************************************/

static int
launchTests(testDescPtr tst) {
    int res = 0, err = 0;
    size_t i;
    char *result;
    char *error;
    int mem;

    if (tst == NULL) return(-1);
    if (tst->in != NULL) {
	glob_t globbuf;

	globbuf.gl_offs = 0;
	glob(tst->in, GLOB_DOOFFS, NULL, &globbuf);
	for (i = 0;i < globbuf.gl_pathc;i++) {
	    if (!checkTestFile(globbuf.gl_pathv[i]))
	        continue;
	    if (tst->suffix != NULL) {
		result = resultFilename(globbuf.gl_pathv[i], tst->out,
					tst->suffix);
		if (result == NULL) {
		    fprintf(stderr, "Out of memory !\n");
		    fatalError();
		}
	    } else {
	        result = NULL;
	    }
	    if (tst->err != NULL) {
		error = resultFilename(globbuf.gl_pathv[i], tst->out,
		                        tst->err);
		if (error == NULL) {
		    fprintf(stderr, "Out of memory !\n");
		    fatalError();
		}
	    } else {
	        error = NULL;
	    }
	    if ((result) &&(!checkTestFile(result))) {
	        fprintf(stderr, "Missing result file %s\n", result);
	    } else if ((error) &&(!checkTestFile(error))) {
	        fprintf(stderr, "Missing error file %s\n", error);
	    } else {
		mem = xmlMemUsed();
		extraMemoryFromResolver = 0;
		testErrorsSize = 0;
		testErrors[0] = 0;
		res = tst->func(globbuf.gl_pathv[i], result, error,
		                tst->options | XML_PARSE_COMPACT);
		xmlResetLastError();
		if (res != 0) {
		    fprintf(stderr, "File %s generated an error\n",
		            globbuf.gl_pathv[i]);
		    nb_errors++;
		    err++;
		}
		else if (xmlMemUsed() != mem) {
		    if ((xmlMemUsed() != mem) &&
		        (extraMemoryFromResolver == 0)) {
			fprintf(stderr, "File %s leaked %d bytes\n",
				globbuf.gl_pathv[i], xmlMemUsed() - mem);
			nb_leaks++;
			err++;
		    }
		}
		testErrorsSize = 0;
	    }
	    if (result)
		free(result);
	    if (error)
		free(error);
	}
	globfree(&globbuf);
    } else {
        testErrorsSize = 0;
	testErrors[0] = 0;
	extraMemoryFromResolver = 0;
        res = tst->func(NULL, NULL, NULL, tst->options);
	if (res != 0) {
	    nb_errors++;
	    err++;
	}
    }
    return(err);
}

static int verbose = 0;
static int tests_quiet = 0;

static int
runtest(int i) {
    int ret = 0, res;
    int old_errors, old_tests, old_leaks;

    old_errors = nb_errors;
    old_tests = nb_tests;
    old_leaks = nb_leaks;
    if ((tests_quiet == 0) && (testDescriptions[i].desc != NULL))
	printf("## %s\n", testDescriptions[i].desc);
    res = launchTests(&testDescriptions[i]);
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

int
main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    int i, a, ret = 0;
    int subset = 0;

    initializeLibxml2();

    for (a = 1; a < argc;a++) {
        if (!strcmp(argv[a], "-v"))
	    verbose = 1;
        else if (!strcmp(argv[a], "-quiet"))
	    tests_quiet = 1;
	else {
	    for (i = 0; testDescriptions[i].func != NULL; i++) {
	        if (strstr(testDescriptions[i].desc, argv[a])) {
		    ret += runtest(i);
		    subset++;
		}
	    }
	}
    }
    if (subset == 0) {
	for (i = 0; testDescriptions[i].func != NULL; i++) {
	    ret += runtest(i);
	}
    }
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

#else /* ! LIBXML_OUTPUT_ENABLED */
int
main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    fprintf(stderr, "runtest requires output to be enabled in libxml2\n");
    return(1);
}
#endif
