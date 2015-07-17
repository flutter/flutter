/*
 * relaxng.c : implementation of the Relax-NG handling and validity checking
 *
 * See Copyright for the status of this software.
 *
 * Daniel Veillard <veillard@redhat.com>
 */

/**
 * TODO:
 * - add support for DTD compatibility spec
 *   http://www.oasis-open.org/committees/relax-ng/compatibility-20011203.html
 * - report better mem allocations pbms at runtime and abort immediately.
 */

#define IN_LIBXML
#include "libxml.h"

#ifdef LIBXML_SCHEMAS_ENABLED

#include <string.h>
#include <stdio.h>
#include <libxml/xmlmemory.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/hash.h>
#include <libxml/uri.h>

#include <libxml/relaxng.h>

#include <libxml/xmlschemastypes.h>
#include <libxml/xmlautomata.h>
#include <libxml/xmlregexp.h>
#include <libxml/xmlschemastypes.h>

/*
 * The Relax-NG namespace
 */
static const xmlChar *xmlRelaxNGNs = (const xmlChar *)
    "http://relaxng.org/ns/structure/1.0";

#define IS_RELAXNG(node, typ)						\
   ((node != NULL) && (node->ns != NULL) &&				\
    (node->type == XML_ELEMENT_NODE) &&					\
    (xmlStrEqual(node->name, (const xmlChar *) typ)) &&		\
    (xmlStrEqual(node->ns->href, xmlRelaxNGNs)))


#if 0
#define DEBUG 1

#define DEBUG_GRAMMAR 1

#define DEBUG_CONTENT 1

#define DEBUG_TYPE 1

#define DEBUG_VALID 1

#define DEBUG_INTERLEAVE 1

#define DEBUG_LIST 1

#define DEBUG_INCLUDE 1

#define DEBUG_ERROR 1

#define DEBUG_COMPILE 1

#define DEBUG_PROGRESSIVE 1
#endif

#define MAX_ERROR 5

#define TODO								\
    xmlGenericError(xmlGenericErrorContext,				\
	    "Unimplemented block at %s:%d\n",				\
            __FILE__, __LINE__);

typedef struct _xmlRelaxNGSchema xmlRelaxNGSchema;
typedef xmlRelaxNGSchema *xmlRelaxNGSchemaPtr;

typedef struct _xmlRelaxNGDefine xmlRelaxNGDefine;
typedef xmlRelaxNGDefine *xmlRelaxNGDefinePtr;

typedef struct _xmlRelaxNGDocument xmlRelaxNGDocument;
typedef xmlRelaxNGDocument *xmlRelaxNGDocumentPtr;

typedef struct _xmlRelaxNGInclude xmlRelaxNGInclude;
typedef xmlRelaxNGInclude *xmlRelaxNGIncludePtr;

typedef enum {
    XML_RELAXNG_COMBINE_UNDEFINED = 0,  /* undefined */
    XML_RELAXNG_COMBINE_CHOICE, /* choice */
    XML_RELAXNG_COMBINE_INTERLEAVE      /* interleave */
} xmlRelaxNGCombine;

typedef enum {
    XML_RELAXNG_CONTENT_ERROR = -1,
    XML_RELAXNG_CONTENT_EMPTY = 0,
    XML_RELAXNG_CONTENT_SIMPLE,
    XML_RELAXNG_CONTENT_COMPLEX
} xmlRelaxNGContentType;

typedef struct _xmlRelaxNGGrammar xmlRelaxNGGrammar;
typedef xmlRelaxNGGrammar *xmlRelaxNGGrammarPtr;

struct _xmlRelaxNGGrammar {
    xmlRelaxNGGrammarPtr parent;        /* the parent grammar if any */
    xmlRelaxNGGrammarPtr children;      /* the children grammar if any */
    xmlRelaxNGGrammarPtr next;  /* the next grammar if any */
    xmlRelaxNGDefinePtr start;  /* <start> content */
    xmlRelaxNGCombine combine;  /* the default combine value */
    xmlRelaxNGDefinePtr startList;      /* list of <start> definitions */
    xmlHashTablePtr defs;       /* define* */
    xmlHashTablePtr refs;       /* references */
};


typedef enum {
    XML_RELAXNG_NOOP = -1,      /* a no operation from simplification  */
    XML_RELAXNG_EMPTY = 0,      /* an empty pattern */
    XML_RELAXNG_NOT_ALLOWED,    /* not allowed top */
    XML_RELAXNG_EXCEPT,         /* except present in nameclass defs */
    XML_RELAXNG_TEXT,           /* textual content */
    XML_RELAXNG_ELEMENT,        /* an element */
    XML_RELAXNG_DATATYPE,       /* extenal data type definition */
    XML_RELAXNG_PARAM,          /* extenal data type parameter */
    XML_RELAXNG_VALUE,          /* value from an extenal data type definition */
    XML_RELAXNG_LIST,           /* a list of patterns */
    XML_RELAXNG_ATTRIBUTE,      /* an attrbute following a pattern */
    XML_RELAXNG_DEF,            /* a definition */
    XML_RELAXNG_REF,            /* reference to a definition */
    XML_RELAXNG_EXTERNALREF,    /* reference to an external def */
    XML_RELAXNG_PARENTREF,      /* reference to a def in the parent grammar */
    XML_RELAXNG_OPTIONAL,       /* optional patterns */
    XML_RELAXNG_ZEROORMORE,     /* zero or more non empty patterns */
    XML_RELAXNG_ONEORMORE,      /* one or more non empty patterns */
    XML_RELAXNG_CHOICE,         /* a choice between non empty patterns */
    XML_RELAXNG_GROUP,          /* a pair/group of non empty patterns */
    XML_RELAXNG_INTERLEAVE,     /* interleaving choice of non-empty patterns */
    XML_RELAXNG_START           /* Used to keep track of starts on grammars */
} xmlRelaxNGType;

#define IS_NULLABLE		(1 << 0)
#define IS_NOT_NULLABLE		(1 << 1)
#define IS_INDETERMINIST	(1 << 2)
#define IS_MIXED		(1 << 3)
#define IS_TRIABLE		(1 << 4)
#define IS_PROCESSED		(1 << 5)
#define IS_COMPILABLE		(1 << 6)
#define IS_NOT_COMPILABLE	(1 << 7)
#define IS_EXTERNAL_REF	        (1 << 8)

struct _xmlRelaxNGDefine {
    xmlRelaxNGType type;        /* the type of definition */
    xmlNodePtr node;            /* the node in the source */
    xmlChar *name;              /* the element local name if present */
    xmlChar *ns;                /* the namespace local name if present */
    xmlChar *value;             /* value when available */
    void *data;                 /* data lib or specific pointer */
    xmlRelaxNGDefinePtr content;        /* the expected content */
    xmlRelaxNGDefinePtr parent; /* the parent definition, if any */
    xmlRelaxNGDefinePtr next;   /* list within grouping sequences */
    xmlRelaxNGDefinePtr attrs;  /* list of attributes for elements */
    xmlRelaxNGDefinePtr nameClass;      /* the nameClass definition if any */
    xmlRelaxNGDefinePtr nextHash;       /* next define in defs/refs hash tables */
    short depth;                /* used for the cycle detection */
    short dflags;               /* define related flags */
    xmlRegexpPtr contModel;     /* a compiled content model if available */
};

/**
 * _xmlRelaxNG:
 *
 * A RelaxNGs definition
 */
struct _xmlRelaxNG {
    void *_private;             /* unused by the library for users or bindings */
    xmlRelaxNGGrammarPtr topgrammar;
    xmlDocPtr doc;

    int idref;                  /* requires idref checking */

    xmlHashTablePtr defs;       /* define */
    xmlHashTablePtr refs;       /* references */
    xmlRelaxNGDocumentPtr documents;    /* all the documents loaded */
    xmlRelaxNGIncludePtr includes;      /* all the includes loaded */
    int defNr;                  /* number of defines used */
    xmlRelaxNGDefinePtr *defTab;        /* pointer to the allocated definitions */

};

#define XML_RELAXNG_IN_ATTRIBUTE	(1 << 0)
#define XML_RELAXNG_IN_ONEORMORE	(1 << 1)
#define XML_RELAXNG_IN_LIST		(1 << 2)
#define XML_RELAXNG_IN_DATAEXCEPT	(1 << 3)
#define XML_RELAXNG_IN_START		(1 << 4)
#define XML_RELAXNG_IN_OOMGROUP		(1 << 5)
#define XML_RELAXNG_IN_OOMINTERLEAVE	(1 << 6)
#define XML_RELAXNG_IN_EXTERNALREF	(1 << 7)
#define XML_RELAXNG_IN_ANYEXCEPT	(1 << 8)
#define XML_RELAXNG_IN_NSEXCEPT		(1 << 9)

struct _xmlRelaxNGParserCtxt {
    void *userData;             /* user specific data block */
    xmlRelaxNGValidityErrorFunc error;  /* the callback in case of errors */
    xmlRelaxNGValidityWarningFunc warning;      /* the callback in case of warning */
    xmlStructuredErrorFunc serror;
    xmlRelaxNGValidErr err;

    xmlRelaxNGPtr schema;       /* The schema in use */
    xmlRelaxNGGrammarPtr grammar;       /* the current grammar */
    xmlRelaxNGGrammarPtr parentgrammar; /* the parent grammar */
    int flags;                  /* parser flags */
    int nbErrors;               /* number of errors at parse time */
    int nbWarnings;             /* number of warnings at parse time */
    const xmlChar *define;      /* the current define scope */
    xmlRelaxNGDefinePtr def;    /* the current define */

    int nbInterleaves;
    xmlHashTablePtr interleaves;        /* keep track of all the interleaves */

    xmlRelaxNGDocumentPtr documents;    /* all the documents loaded */
    xmlRelaxNGIncludePtr includes;      /* all the includes loaded */
    xmlChar *URL;
    xmlDocPtr document;

    int defNr;                  /* number of defines used */
    int defMax;                 /* number of defines aloocated */
    xmlRelaxNGDefinePtr *defTab;        /* pointer to the allocated definitions */

    const char *buffer;
    int size;

    /* the document stack */
    xmlRelaxNGDocumentPtr doc;  /* Current parsed external ref */
    int docNr;                  /* Depth of the parsing stack */
    int docMax;                 /* Max depth of the parsing stack */
    xmlRelaxNGDocumentPtr *docTab;      /* array of docs */

    /* the include stack */
    xmlRelaxNGIncludePtr inc;   /* Current parsed include */
    int incNr;                  /* Depth of the include parsing stack */
    int incMax;                 /* Max depth of the parsing stack */
    xmlRelaxNGIncludePtr *incTab;       /* array of incs */

    int idref;                  /* requires idref checking */

    /* used to compile content models */
    xmlAutomataPtr am;          /* the automata */
    xmlAutomataStatePtr state;  /* used to build the automata */

    int crng;			/* compact syntax and other flags */
    int freedoc;		/* need to free the document */
};

#define FLAGS_IGNORABLE		1
#define FLAGS_NEGATIVE		2
#define FLAGS_MIXED_CONTENT	4
#define FLAGS_NOERROR		8

/**
 * xmlRelaxNGInterleaveGroup:
 *
 * A RelaxNGs partition set associated to lists of definitions
 */
typedef struct _xmlRelaxNGInterleaveGroup xmlRelaxNGInterleaveGroup;
typedef xmlRelaxNGInterleaveGroup *xmlRelaxNGInterleaveGroupPtr;
struct _xmlRelaxNGInterleaveGroup {
    xmlRelaxNGDefinePtr rule;   /* the rule to satisfy */
    xmlRelaxNGDefinePtr *defs;  /* the array of element definitions */
    xmlRelaxNGDefinePtr *attrs; /* the array of attributes definitions */
};

#define IS_DETERMINIST		1
#define IS_NEEDCHECK		2

/**
 * xmlRelaxNGPartitions:
 *
 * A RelaxNGs partition associated to an interleave group
 */
typedef struct _xmlRelaxNGPartition xmlRelaxNGPartition;
typedef xmlRelaxNGPartition *xmlRelaxNGPartitionPtr;
struct _xmlRelaxNGPartition {
    int nbgroups;               /* number of groups in the partitions */
    xmlHashTablePtr triage;     /* hash table used to direct nodes to the
                                 * right group when possible */
    int flags;                  /* determinist ? */
    xmlRelaxNGInterleaveGroupPtr *groups;
};

/**
 * xmlRelaxNGValidState:
 *
 * A RelaxNGs validation state
 */
#define MAX_ATTR 20
typedef struct _xmlRelaxNGValidState xmlRelaxNGValidState;
typedef xmlRelaxNGValidState *xmlRelaxNGValidStatePtr;
struct _xmlRelaxNGValidState {
    xmlNodePtr node;            /* the current node */
    xmlNodePtr seq;             /* the sequence of children left to validate */
    int nbAttrs;                /* the number of attributes */
    int maxAttrs;               /* the size of attrs */
    int nbAttrLeft;             /* the number of attributes left to validate */
    xmlChar *value;             /* the value when operating on string */
    xmlChar *endvalue;          /* the end value when operating on string */
    xmlAttrPtr *attrs;          /* the array of attributes */
};

/**
 * xmlRelaxNGStates:
 *
 * A RelaxNGs container for validation state
 */
typedef struct _xmlRelaxNGStates xmlRelaxNGStates;
typedef xmlRelaxNGStates *xmlRelaxNGStatesPtr;
struct _xmlRelaxNGStates {
    int nbState;                /* the number of states */
    int maxState;               /* the size of the array */
    xmlRelaxNGValidStatePtr *tabState;
};

#define ERROR_IS_DUP	1

/**
 * xmlRelaxNGValidError:
 *
 * A RelaxNGs validation error
 */
typedef struct _xmlRelaxNGValidError xmlRelaxNGValidError;
typedef xmlRelaxNGValidError *xmlRelaxNGValidErrorPtr;
struct _xmlRelaxNGValidError {
    xmlRelaxNGValidErr err;     /* the error number */
    int flags;                  /* flags */
    xmlNodePtr node;            /* the current node */
    xmlNodePtr seq;             /* the current child */
    const xmlChar *arg1;        /* first arg */
    const xmlChar *arg2;        /* second arg */
};

/**
 * xmlRelaxNGValidCtxt:
 *
 * A RelaxNGs validation context
 */

struct _xmlRelaxNGValidCtxt {
    void *userData;             /* user specific data block */
    xmlRelaxNGValidityErrorFunc error;  /* the callback in case of errors */
    xmlRelaxNGValidityWarningFunc warning;      /* the callback in case of warning */
    xmlStructuredErrorFunc serror;
    int nbErrors;               /* number of errors in validation */

    xmlRelaxNGPtr schema;       /* The schema in use */
    xmlDocPtr doc;              /* the document being validated */
    int flags;                  /* validation flags */
    int depth;                  /* validation depth */
    int idref;                  /* requires idref checking */
    int errNo;                  /* the first error found */

    /*
     * Errors accumulated in branches may have to be stacked to be
     * provided back when it's sure they affect validation.
     */
    xmlRelaxNGValidErrorPtr err;        /* Last error */
    int errNr;                  /* Depth of the error stack */
    int errMax;                 /* Max depth of the error stack */
    xmlRelaxNGValidErrorPtr errTab;     /* stack of errors */

    xmlRelaxNGValidStatePtr state;      /* the current validation state */
    xmlRelaxNGStatesPtr states; /* the accumulated state list */

    xmlRelaxNGStatesPtr freeState;      /* the pool of free valid states */
    int freeStatesNr;
    int freeStatesMax;
    xmlRelaxNGStatesPtr *freeStates;    /* the pool of free state groups */

    /*
     * This is used for "progressive" validation
     */
    xmlRegExecCtxtPtr elem;     /* the current element regexp */
    int elemNr;                 /* the number of element validated */
    int elemMax;                /* the max depth of elements */
    xmlRegExecCtxtPtr *elemTab; /* the stack of regexp runtime */
    int pstate;                 /* progressive state */
    xmlNodePtr pnode;           /* the current node */
    xmlRelaxNGDefinePtr pdef;   /* the non-streamable definition */
    int perr;                   /* signal error in content model
                                 * outside the regexp */
};

/**
 * xmlRelaxNGInclude:
 *
 * Structure associated to a RelaxNGs document element
 */
struct _xmlRelaxNGInclude {
    xmlRelaxNGIncludePtr next;  /* keep a chain of includes */
    xmlChar *href;              /* the normalized href value */
    xmlDocPtr doc;              /* the associated XML document */
    xmlRelaxNGDefinePtr content;        /* the definitions */
    xmlRelaxNGPtr schema;       /* the schema */
};

/**
 * xmlRelaxNGDocument:
 *
 * Structure associated to a RelaxNGs document element
 */
struct _xmlRelaxNGDocument {
    xmlRelaxNGDocumentPtr next; /* keep a chain of documents */
    xmlChar *href;              /* the normalized href value */
    xmlDocPtr doc;              /* the associated XML document */
    xmlRelaxNGDefinePtr content;        /* the definitions */
    xmlRelaxNGPtr schema;       /* the schema */
    int externalRef;            /* 1 if an external ref */
};


/************************************************************************
 *									*
 *		Some factorized error routines				*
 *									*
 ************************************************************************/

/**
 * xmlRngPErrMemory:
 * @ctxt:  an Relax-NG parser context
 * @extra:  extra informations
 *
 * Handle a redefinition of attribute error
 */
static void
xmlRngPErrMemory(xmlRelaxNGParserCtxtPtr ctxt, const char *extra)
{
    xmlStructuredErrorFunc schannel = NULL;
    xmlGenericErrorFunc channel = NULL;
    void *data = NULL;

    if (ctxt != NULL) {
        if (ctxt->serror != NULL)
	    schannel = ctxt->serror;
	else
	    channel = ctxt->error;
        data = ctxt->userData;
        ctxt->nbErrors++;
    }
    if (extra)
        __xmlRaiseError(schannel, channel, data,
                        NULL, NULL, XML_FROM_RELAXNGP,
                        XML_ERR_NO_MEMORY, XML_ERR_FATAL, NULL, 0, extra,
                        NULL, NULL, 0, 0,
                        "Memory allocation failed : %s\n", extra);
    else
        __xmlRaiseError(schannel, channel, data,
                        NULL, NULL, XML_FROM_RELAXNGP,
                        XML_ERR_NO_MEMORY, XML_ERR_FATAL, NULL, 0, NULL,
                        NULL, NULL, 0, 0, "Memory allocation failed\n");
}

/**
 * xmlRngVErrMemory:
 * @ctxt:  a Relax-NG validation context
 * @extra:  extra informations
 *
 * Handle a redefinition of attribute error
 */
static void
xmlRngVErrMemory(xmlRelaxNGValidCtxtPtr ctxt, const char *extra)
{
    xmlStructuredErrorFunc schannel = NULL;
    xmlGenericErrorFunc channel = NULL;
    void *data = NULL;

    if (ctxt != NULL) {
        if (ctxt->serror != NULL)
	    schannel = ctxt->serror;
	else
	    channel = ctxt->error;
        data = ctxt->userData;
        ctxt->nbErrors++;
    }
    if (extra)
        __xmlRaiseError(schannel, channel, data,
                        NULL, NULL, XML_FROM_RELAXNGV,
                        XML_ERR_NO_MEMORY, XML_ERR_FATAL, NULL, 0, extra,
                        NULL, NULL, 0, 0,
                        "Memory allocation failed : %s\n", extra);
    else
        __xmlRaiseError(schannel, channel, data,
                        NULL, NULL, XML_FROM_RELAXNGV,
                        XML_ERR_NO_MEMORY, XML_ERR_FATAL, NULL, 0, NULL,
                        NULL, NULL, 0, 0, "Memory allocation failed\n");
}

/**
 * xmlRngPErr:
 * @ctxt:  a Relax-NG parser context
 * @node:  the node raising the error
 * @error:  the error code
 * @msg:  message
 * @str1:  extra info
 * @str2:  extra info
 *
 * Handle a Relax NG Parsing error
 */
static void
xmlRngPErr(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node, int error,
           const char *msg, const xmlChar * str1, const xmlChar * str2)
{
    xmlStructuredErrorFunc schannel = NULL;
    xmlGenericErrorFunc channel = NULL;
    void *data = NULL;

    if (ctxt != NULL) {
        if (ctxt->serror != NULL)
	    schannel = ctxt->serror;
	else
	    channel = ctxt->error;
        data = ctxt->userData;
        ctxt->nbErrors++;
    }
    __xmlRaiseError(schannel, channel, data,
                    NULL, node, XML_FROM_RELAXNGP,
                    error, XML_ERR_ERROR, NULL, 0,
                    (const char *) str1, (const char *) str2, NULL, 0, 0,
                    msg, str1, str2);
}

/**
 * xmlRngVErr:
 * @ctxt:  a Relax-NG validation context
 * @node:  the node raising the error
 * @error:  the error code
 * @msg:  message
 * @str1:  extra info
 * @str2:  extra info
 *
 * Handle a Relax NG Validation error
 */
static void
xmlRngVErr(xmlRelaxNGValidCtxtPtr ctxt, xmlNodePtr node, int error,
           const char *msg, const xmlChar * str1, const xmlChar * str2)
{
    xmlStructuredErrorFunc schannel = NULL;
    xmlGenericErrorFunc channel = NULL;
    void *data = NULL;

    if (ctxt != NULL) {
        if (ctxt->serror != NULL)
	    schannel = ctxt->serror;
	else
	    channel = ctxt->error;
        data = ctxt->userData;
        ctxt->nbErrors++;
    }
    __xmlRaiseError(schannel, channel, data,
                    NULL, node, XML_FROM_RELAXNGV,
                    error, XML_ERR_ERROR, NULL, 0,
                    (const char *) str1, (const char *) str2, NULL, 0, 0,
                    msg, str1, str2);
}

/************************************************************************
 *									*
 *		Preliminary type checking interfaces			*
 *									*
 ************************************************************************/

/**
 * xmlRelaxNGTypeHave:
 * @data:  data needed for the library
 * @type:  the type name
 * @value:  the value to check
 *
 * Function provided by a type library to check if a type is exported
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
typedef int (*xmlRelaxNGTypeHave) (void *data, const xmlChar * type);

/**
 * xmlRelaxNGTypeCheck:
 * @data:  data needed for the library
 * @type:  the type name
 * @value:  the value to check
 * @result:  place to store the result if needed
 *
 * Function provided by a type library to check if a value match a type
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
typedef int (*xmlRelaxNGTypeCheck) (void *data, const xmlChar * type,
                                    const xmlChar * value, void **result,
                                    xmlNodePtr node);

/**
 * xmlRelaxNGFacetCheck:
 * @data:  data needed for the library
 * @type:  the type name
 * @facet:  the facet name
 * @val:  the facet value
 * @strval:  the string value
 * @value:  the value to check
 *
 * Function provided by a type library to check a value facet
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
typedef int (*xmlRelaxNGFacetCheck) (void *data, const xmlChar * type,
                                     const xmlChar * facet,
                                     const xmlChar * val,
                                     const xmlChar * strval, void *value);

/**
 * xmlRelaxNGTypeFree:
 * @data:  data needed for the library
 * @result:  the value to free
 *
 * Function provided by a type library to free a returned result
 */
typedef void (*xmlRelaxNGTypeFree) (void *data, void *result);

/**
 * xmlRelaxNGTypeCompare:
 * @data:  data needed for the library
 * @type:  the type name
 * @value1:  the first value
 * @value2:  the second value
 *
 * Function provided by a type library to compare two values accordingly
 * to a type.
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
typedef int (*xmlRelaxNGTypeCompare) (void *data, const xmlChar * type,
                                      const xmlChar * value1,
                                      xmlNodePtr ctxt1,
                                      void *comp1,
                                      const xmlChar * value2,
                                      xmlNodePtr ctxt2);
typedef struct _xmlRelaxNGTypeLibrary xmlRelaxNGTypeLibrary;
typedef xmlRelaxNGTypeLibrary *xmlRelaxNGTypeLibraryPtr;
struct _xmlRelaxNGTypeLibrary {
    const xmlChar *namespace;   /* the datatypeLibrary value */
    void *data;                 /* data needed for the library */
    xmlRelaxNGTypeHave have;    /* the export function */
    xmlRelaxNGTypeCheck check;  /* the checking function */
    xmlRelaxNGTypeCompare comp; /* the compare function */
    xmlRelaxNGFacetCheck facet; /* the facet check function */
    xmlRelaxNGTypeFree freef;   /* the freeing function */
};

/************************************************************************
 *									*
 *			Allocation functions				*
 *									*
 ************************************************************************/
static void xmlRelaxNGFreeGrammar(xmlRelaxNGGrammarPtr grammar);
static void xmlRelaxNGFreeDefine(xmlRelaxNGDefinePtr define);
static void xmlRelaxNGNormExtSpace(xmlChar * value);
static void xmlRelaxNGFreeInnerSchema(xmlRelaxNGPtr schema);
static int xmlRelaxNGEqualValidState(xmlRelaxNGValidCtxtPtr ctxt
                                     ATTRIBUTE_UNUSED,
                                     xmlRelaxNGValidStatePtr state1,
                                     xmlRelaxNGValidStatePtr state2);
static void xmlRelaxNGFreeValidState(xmlRelaxNGValidCtxtPtr ctxt,
                                     xmlRelaxNGValidStatePtr state);

/**
 * xmlRelaxNGFreeDocument:
 * @docu:  a document structure
 *
 * Deallocate a RelaxNG document structure.
 */
static void
xmlRelaxNGFreeDocument(xmlRelaxNGDocumentPtr docu)
{
    if (docu == NULL)
        return;

    if (docu->href != NULL)
        xmlFree(docu->href);
    if (docu->doc != NULL)
        xmlFreeDoc(docu->doc);
    if (docu->schema != NULL)
        xmlRelaxNGFreeInnerSchema(docu->schema);
    xmlFree(docu);
}

/**
 * xmlRelaxNGFreeDocumentList:
 * @docu:  a list of  document structure
 *
 * Deallocate a RelaxNG document structures.
 */
static void
xmlRelaxNGFreeDocumentList(xmlRelaxNGDocumentPtr docu)
{
    xmlRelaxNGDocumentPtr next;

    while (docu != NULL) {
        next = docu->next;
        xmlRelaxNGFreeDocument(docu);
        docu = next;
    }
}

/**
 * xmlRelaxNGFreeInclude:
 * @incl:  a include structure
 *
 * Deallocate a RelaxNG include structure.
 */
static void
xmlRelaxNGFreeInclude(xmlRelaxNGIncludePtr incl)
{
    if (incl == NULL)
        return;

    if (incl->href != NULL)
        xmlFree(incl->href);
    if (incl->doc != NULL)
        xmlFreeDoc(incl->doc);
    if (incl->schema != NULL)
        xmlRelaxNGFree(incl->schema);
    xmlFree(incl);
}

/**
 * xmlRelaxNGFreeIncludeList:
 * @incl:  a include structure list
 *
 * Deallocate a RelaxNG include structure.
 */
static void
xmlRelaxNGFreeIncludeList(xmlRelaxNGIncludePtr incl)
{
    xmlRelaxNGIncludePtr next;

    while (incl != NULL) {
        next = incl->next;
        xmlRelaxNGFreeInclude(incl);
        incl = next;
    }
}

/**
 * xmlRelaxNGNewRelaxNG:
 * @ctxt:  a Relax-NG validation context (optional)
 *
 * Allocate a new RelaxNG structure.
 *
 * Returns the newly allocated structure or NULL in case or error
 */
static xmlRelaxNGPtr
xmlRelaxNGNewRelaxNG(xmlRelaxNGParserCtxtPtr ctxt)
{
    xmlRelaxNGPtr ret;

    ret = (xmlRelaxNGPtr) xmlMalloc(sizeof(xmlRelaxNG));
    if (ret == NULL) {
        xmlRngPErrMemory(ctxt, NULL);
        return (NULL);
    }
    memset(ret, 0, sizeof(xmlRelaxNG));

    return (ret);
}

/**
 * xmlRelaxNGFreeInnerSchema:
 * @schema:  a schema structure
 *
 * Deallocate a RelaxNG schema structure.
 */
static void
xmlRelaxNGFreeInnerSchema(xmlRelaxNGPtr schema)
{
    if (schema == NULL)
        return;

    if (schema->doc != NULL)
        xmlFreeDoc(schema->doc);
    if (schema->defTab != NULL) {
        int i;

        for (i = 0; i < schema->defNr; i++)
            xmlRelaxNGFreeDefine(schema->defTab[i]);
        xmlFree(schema->defTab);
    }

    xmlFree(schema);
}

/**
 * xmlRelaxNGFree:
 * @schema:  a schema structure
 *
 * Deallocate a RelaxNG structure.
 */
void
xmlRelaxNGFree(xmlRelaxNGPtr schema)
{
    if (schema == NULL)
        return;

    if (schema->topgrammar != NULL)
        xmlRelaxNGFreeGrammar(schema->topgrammar);
    if (schema->doc != NULL)
        xmlFreeDoc(schema->doc);
    if (schema->documents != NULL)
        xmlRelaxNGFreeDocumentList(schema->documents);
    if (schema->includes != NULL)
        xmlRelaxNGFreeIncludeList(schema->includes);
    if (schema->defTab != NULL) {
        int i;

        for (i = 0; i < schema->defNr; i++)
            xmlRelaxNGFreeDefine(schema->defTab[i]);
        xmlFree(schema->defTab);
    }

    xmlFree(schema);
}

/**
 * xmlRelaxNGNewGrammar:
 * @ctxt:  a Relax-NG validation context (optional)
 *
 * Allocate a new RelaxNG grammar.
 *
 * Returns the newly allocated structure or NULL in case or error
 */
static xmlRelaxNGGrammarPtr
xmlRelaxNGNewGrammar(xmlRelaxNGParserCtxtPtr ctxt)
{
    xmlRelaxNGGrammarPtr ret;

    ret = (xmlRelaxNGGrammarPtr) xmlMalloc(sizeof(xmlRelaxNGGrammar));
    if (ret == NULL) {
        xmlRngPErrMemory(ctxt, NULL);
        return (NULL);
    }
    memset(ret, 0, sizeof(xmlRelaxNGGrammar));

    return (ret);
}

/**
 * xmlRelaxNGFreeGrammar:
 * @grammar:  a grammar structure
 *
 * Deallocate a RelaxNG grammar structure.
 */
static void
xmlRelaxNGFreeGrammar(xmlRelaxNGGrammarPtr grammar)
{
    if (grammar == NULL)
        return;

    if (grammar->children != NULL) {
        xmlRelaxNGFreeGrammar(grammar->children);
    }
    if (grammar->next != NULL) {
        xmlRelaxNGFreeGrammar(grammar->next);
    }
    if (grammar->refs != NULL) {
        xmlHashFree(grammar->refs, NULL);
    }
    if (grammar->defs != NULL) {
        xmlHashFree(grammar->defs, NULL);
    }

    xmlFree(grammar);
}

/**
 * xmlRelaxNGNewDefine:
 * @ctxt:  a Relax-NG validation context
 * @node:  the node in the input document.
 *
 * Allocate a new RelaxNG define.
 *
 * Returns the newly allocated structure or NULL in case or error
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGNewDefine(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGDefinePtr ret;

    if (ctxt->defMax == 0) {
        ctxt->defMax = 16;
        ctxt->defNr = 0;
        ctxt->defTab = (xmlRelaxNGDefinePtr *)
            xmlMalloc(ctxt->defMax * sizeof(xmlRelaxNGDefinePtr));
        if (ctxt->defTab == NULL) {
            xmlRngPErrMemory(ctxt, "allocating define\n");
            return (NULL);
        }
    } else if (ctxt->defMax <= ctxt->defNr) {
        xmlRelaxNGDefinePtr *tmp;

        ctxt->defMax *= 2;
        tmp = (xmlRelaxNGDefinePtr *) xmlRealloc(ctxt->defTab,
                                                 ctxt->defMax *
                                                 sizeof
                                                 (xmlRelaxNGDefinePtr));
        if (tmp == NULL) {
            xmlRngPErrMemory(ctxt, "allocating define\n");
            return (NULL);
        }
        ctxt->defTab = tmp;
    }
    ret = (xmlRelaxNGDefinePtr) xmlMalloc(sizeof(xmlRelaxNGDefine));
    if (ret == NULL) {
        xmlRngPErrMemory(ctxt, "allocating define\n");
        return (NULL);
    }
    memset(ret, 0, sizeof(xmlRelaxNGDefine));
    ctxt->defTab[ctxt->defNr++] = ret;
    ret->node = node;
    ret->depth = -1;
    return (ret);
}

/**
 * xmlRelaxNGFreePartition:
 * @partitions:  a partition set structure
 *
 * Deallocate RelaxNG partition set structures.
 */
static void
xmlRelaxNGFreePartition(xmlRelaxNGPartitionPtr partitions)
{
    xmlRelaxNGInterleaveGroupPtr group;
    int j;

    if (partitions != NULL) {
        if (partitions->groups != NULL) {
            for (j = 0; j < partitions->nbgroups; j++) {
                group = partitions->groups[j];
                if (group != NULL) {
                    if (group->defs != NULL)
                        xmlFree(group->defs);
                    if (group->attrs != NULL)
                        xmlFree(group->attrs);
                    xmlFree(group);
                }
            }
            xmlFree(partitions->groups);
        }
        if (partitions->triage != NULL) {
            xmlHashFree(partitions->triage, NULL);
        }
        xmlFree(partitions);
    }
}

/**
 * xmlRelaxNGFreeDefine:
 * @define:  a define structure
 *
 * Deallocate a RelaxNG define structure.
 */
static void
xmlRelaxNGFreeDefine(xmlRelaxNGDefinePtr define)
{
    if (define == NULL)
        return;

    if ((define->type == XML_RELAXNG_VALUE) && (define->attrs != NULL)) {
        xmlRelaxNGTypeLibraryPtr lib;

        lib = (xmlRelaxNGTypeLibraryPtr) define->data;
        if ((lib != NULL) && (lib->freef != NULL))
            lib->freef(lib->data, (void *) define->attrs);
    }
    if ((define->data != NULL) && (define->type == XML_RELAXNG_INTERLEAVE))
        xmlRelaxNGFreePartition((xmlRelaxNGPartitionPtr) define->data);
    if ((define->data != NULL) && (define->type == XML_RELAXNG_CHOICE))
        xmlHashFree((xmlHashTablePtr) define->data, NULL);
    if (define->name != NULL)
        xmlFree(define->name);
    if (define->ns != NULL)
        xmlFree(define->ns);
    if (define->value != NULL)
        xmlFree(define->value);
    if (define->contModel != NULL)
        xmlRegFreeRegexp(define->contModel);
    xmlFree(define);
}

/**
 * xmlRelaxNGNewStates:
 * @ctxt:  a Relax-NG validation context
 * @size:  the default size for the container
 *
 * Allocate a new RelaxNG validation state container
 *
 * Returns the newly allocated structure or NULL in case or error
 */
static xmlRelaxNGStatesPtr
xmlRelaxNGNewStates(xmlRelaxNGValidCtxtPtr ctxt, int size)
{
    xmlRelaxNGStatesPtr ret;

    if ((ctxt != NULL) &&
        (ctxt->freeStates != NULL) && (ctxt->freeStatesNr > 0)) {
        ctxt->freeStatesNr--;
        ret = ctxt->freeStates[ctxt->freeStatesNr];
        ret->nbState = 0;
        return (ret);
    }
    if (size < 16)
        size = 16;

    ret = (xmlRelaxNGStatesPtr) xmlMalloc(sizeof(xmlRelaxNGStates) +
                                          (size -
                                           1) *
                                          sizeof(xmlRelaxNGValidStatePtr));
    if (ret == NULL) {
        xmlRngVErrMemory(ctxt, "allocating states\n");
        return (NULL);
    }
    ret->nbState = 0;
    ret->maxState = size;
    ret->tabState = (xmlRelaxNGValidStatePtr *) xmlMalloc((size) *
                                                          sizeof
                                                          (xmlRelaxNGValidStatePtr));
    if (ret->tabState == NULL) {
        xmlRngVErrMemory(ctxt, "allocating states\n");
        xmlFree(ret);
        return (NULL);
    }
    return (ret);
}

/**
 * xmlRelaxNGAddStateUniq:
 * @ctxt:  a Relax-NG validation context
 * @states:  the states container
 * @state:  the validation state
 *
 * Add a RelaxNG validation state to the container without checking
 * for unicity.
 *
 * Return 1 in case of success and 0 if this is a duplicate and -1 on error
 */
static int
xmlRelaxNGAddStatesUniq(xmlRelaxNGValidCtxtPtr ctxt,
                        xmlRelaxNGStatesPtr states,
                        xmlRelaxNGValidStatePtr state)
{
    if (state == NULL) {
        return (-1);
    }
    if (states->nbState >= states->maxState) {
        xmlRelaxNGValidStatePtr *tmp;
        int size;

        size = states->maxState * 2;
        tmp = (xmlRelaxNGValidStatePtr *) xmlRealloc(states->tabState,
                                                     (size) *
                                                     sizeof
                                                     (xmlRelaxNGValidStatePtr));
        if (tmp == NULL) {
            xmlRngVErrMemory(ctxt, "adding states\n");
            return (-1);
        }
        states->tabState = tmp;
        states->maxState = size;
    }
    states->tabState[states->nbState++] = state;
    return (1);
}

/**
 * xmlRelaxNGAddState:
 * @ctxt:  a Relax-NG validation context
 * @states:  the states container
 * @state:  the validation state
 *
 * Add a RelaxNG validation state to the container
 *
 * Return 1 in case of success and 0 if this is a duplicate and -1 on error
 */
static int
xmlRelaxNGAddStates(xmlRelaxNGValidCtxtPtr ctxt,
                    xmlRelaxNGStatesPtr states,
                    xmlRelaxNGValidStatePtr state)
{
    int i;

    if (state == NULL || states == NULL) {
        return (-1);
    }
    if (states->nbState >= states->maxState) {
        xmlRelaxNGValidStatePtr *tmp;
        int size;

        size = states->maxState * 2;
        tmp = (xmlRelaxNGValidStatePtr *) xmlRealloc(states->tabState,
                                                     (size) *
                                                     sizeof
                                                     (xmlRelaxNGValidStatePtr));
        if (tmp == NULL) {
            xmlRngVErrMemory(ctxt, "adding states\n");
            return (-1);
        }
        states->tabState = tmp;
        states->maxState = size;
    }
    for (i = 0; i < states->nbState; i++) {
        if (xmlRelaxNGEqualValidState(ctxt, state, states->tabState[i])) {
            xmlRelaxNGFreeValidState(ctxt, state);
            return (0);
        }
    }
    states->tabState[states->nbState++] = state;
    return (1);
}

/**
 * xmlRelaxNGFreeStates:
 * @ctxt:  a Relax-NG validation context
 * @states:  teh container
 *
 * Free a RelaxNG validation state container
 */
static void
xmlRelaxNGFreeStates(xmlRelaxNGValidCtxtPtr ctxt,
                     xmlRelaxNGStatesPtr states)
{
    if (states == NULL)
        return;
    if ((ctxt != NULL) && (ctxt->freeStates == NULL)) {
        ctxt->freeStatesMax = 40;
        ctxt->freeStatesNr = 0;
        ctxt->freeStates = (xmlRelaxNGStatesPtr *)
            xmlMalloc(ctxt->freeStatesMax * sizeof(xmlRelaxNGStatesPtr));
        if (ctxt->freeStates == NULL) {
            xmlRngVErrMemory(ctxt, "storing states\n");
        }
    } else if ((ctxt != NULL)
               && (ctxt->freeStatesNr >= ctxt->freeStatesMax)) {
        xmlRelaxNGStatesPtr *tmp;

        tmp = (xmlRelaxNGStatesPtr *) xmlRealloc(ctxt->freeStates,
                                                 2 * ctxt->freeStatesMax *
                                                 sizeof
                                                 (xmlRelaxNGStatesPtr));
        if (tmp == NULL) {
            xmlRngVErrMemory(ctxt, "storing states\n");
            xmlFree(states->tabState);
            xmlFree(states);
            return;
        }
        ctxt->freeStates = tmp;
        ctxt->freeStatesMax *= 2;
    }
    if ((ctxt == NULL) || (ctxt->freeStates == NULL)) {
        xmlFree(states->tabState);
        xmlFree(states);
    } else {
        ctxt->freeStates[ctxt->freeStatesNr++] = states;
    }
}

/**
 * xmlRelaxNGNewValidState:
 * @ctxt:  a Relax-NG validation context
 * @node:  the current node or NULL for the document
 *
 * Allocate a new RelaxNG validation state
 *
 * Returns the newly allocated structure or NULL in case or error
 */
static xmlRelaxNGValidStatePtr
xmlRelaxNGNewValidState(xmlRelaxNGValidCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGValidStatePtr ret;
    xmlAttrPtr attr;
    xmlAttrPtr attrs[MAX_ATTR];
    int nbAttrs = 0;
    xmlNodePtr root = NULL;

    if (node == NULL) {
        root = xmlDocGetRootElement(ctxt->doc);
        if (root == NULL)
            return (NULL);
    } else {
        attr = node->properties;
        while (attr != NULL) {
            if (nbAttrs < MAX_ATTR)
                attrs[nbAttrs++] = attr;
            else
                nbAttrs++;
            attr = attr->next;
        }
    }
    if ((ctxt->freeState != NULL) && (ctxt->freeState->nbState > 0)) {
        ctxt->freeState->nbState--;
        ret = ctxt->freeState->tabState[ctxt->freeState->nbState];
    } else {
        ret =
            (xmlRelaxNGValidStatePtr)
            xmlMalloc(sizeof(xmlRelaxNGValidState));
        if (ret == NULL) {
            xmlRngVErrMemory(ctxt, "allocating states\n");
            return (NULL);
        }
        memset(ret, 0, sizeof(xmlRelaxNGValidState));
    }
    ret->value = NULL;
    ret->endvalue = NULL;
    if (node == NULL) {
        ret->node = (xmlNodePtr) ctxt->doc;
        ret->seq = root;
    } else {
        ret->node = node;
        ret->seq = node->children;
    }
    ret->nbAttrs = 0;
    if (nbAttrs > 0) {
        if (ret->attrs == NULL) {
            if (nbAttrs < 4)
                ret->maxAttrs = 4;
            else
                ret->maxAttrs = nbAttrs;
            ret->attrs = (xmlAttrPtr *) xmlMalloc(ret->maxAttrs *
                                                  sizeof(xmlAttrPtr));
            if (ret->attrs == NULL) {
                xmlRngVErrMemory(ctxt, "allocating states\n");
                return (ret);
            }
        } else if (ret->maxAttrs < nbAttrs) {
            xmlAttrPtr *tmp;

            tmp = (xmlAttrPtr *) xmlRealloc(ret->attrs, nbAttrs *
                                            sizeof(xmlAttrPtr));
            if (tmp == NULL) {
                xmlRngVErrMemory(ctxt, "allocating states\n");
                return (ret);
            }
            ret->attrs = tmp;
            ret->maxAttrs = nbAttrs;
        }
        ret->nbAttrs = nbAttrs;
        if (nbAttrs < MAX_ATTR) {
            memcpy(ret->attrs, attrs, sizeof(xmlAttrPtr) * nbAttrs);
        } else {
            attr = node->properties;
            nbAttrs = 0;
            while (attr != NULL) {
                ret->attrs[nbAttrs++] = attr;
                attr = attr->next;
            }
        }
    }
    ret->nbAttrLeft = ret->nbAttrs;
    return (ret);
}

/**
 * xmlRelaxNGCopyValidState:
 * @ctxt:  a Relax-NG validation context
 * @state:  a validation state
 *
 * Copy the validation state
 *
 * Returns the newly allocated structure or NULL in case or error
 */
static xmlRelaxNGValidStatePtr
xmlRelaxNGCopyValidState(xmlRelaxNGValidCtxtPtr ctxt,
                         xmlRelaxNGValidStatePtr state)
{
    xmlRelaxNGValidStatePtr ret;
    unsigned int maxAttrs;
    xmlAttrPtr *attrs;

    if (state == NULL)
        return (NULL);
    if ((ctxt->freeState != NULL) && (ctxt->freeState->nbState > 0)) {
        ctxt->freeState->nbState--;
        ret = ctxt->freeState->tabState[ctxt->freeState->nbState];
    } else {
        ret =
            (xmlRelaxNGValidStatePtr)
            xmlMalloc(sizeof(xmlRelaxNGValidState));
        if (ret == NULL) {
            xmlRngVErrMemory(ctxt, "allocating states\n");
            return (NULL);
        }
        memset(ret, 0, sizeof(xmlRelaxNGValidState));
    }
    attrs = ret->attrs;
    maxAttrs = ret->maxAttrs;
    memcpy(ret, state, sizeof(xmlRelaxNGValidState));
    ret->attrs = attrs;
    ret->maxAttrs = maxAttrs;
    if (state->nbAttrs > 0) {
        if (ret->attrs == NULL) {
            ret->maxAttrs = state->maxAttrs;
            ret->attrs = (xmlAttrPtr *) xmlMalloc(ret->maxAttrs *
                                                  sizeof(xmlAttrPtr));
            if (ret->attrs == NULL) {
                xmlRngVErrMemory(ctxt, "allocating states\n");
                ret->nbAttrs = 0;
                return (ret);
            }
        } else if (ret->maxAttrs < state->nbAttrs) {
            xmlAttrPtr *tmp;

            tmp = (xmlAttrPtr *) xmlRealloc(ret->attrs, state->maxAttrs *
                                            sizeof(xmlAttrPtr));
            if (tmp == NULL) {
                xmlRngVErrMemory(ctxt, "allocating states\n");
                ret->nbAttrs = 0;
                return (ret);
            }
            ret->maxAttrs = state->maxAttrs;
            ret->attrs = tmp;
        }
        memcpy(ret->attrs, state->attrs,
               state->nbAttrs * sizeof(xmlAttrPtr));
    }
    return (ret);
}

/**
 * xmlRelaxNGEqualValidState:
 * @ctxt:  a Relax-NG validation context
 * @state1:  a validation state
 * @state2:  a validation state
 *
 * Compare the validation states for equality
 *
 * Returns 1 if equald, 0 otherwise
 */
static int
xmlRelaxNGEqualValidState(xmlRelaxNGValidCtxtPtr ctxt ATTRIBUTE_UNUSED,
                          xmlRelaxNGValidStatePtr state1,
                          xmlRelaxNGValidStatePtr state2)
{
    int i;

    if ((state1 == NULL) || (state2 == NULL))
        return (0);
    if (state1 == state2)
        return (1);
    if (state1->node != state2->node)
        return (0);
    if (state1->seq != state2->seq)
        return (0);
    if (state1->nbAttrLeft != state2->nbAttrLeft)
        return (0);
    if (state1->nbAttrs != state2->nbAttrs)
        return (0);
    if (state1->endvalue != state2->endvalue)
        return (0);
    if ((state1->value != state2->value) &&
        (!xmlStrEqual(state1->value, state2->value)))
        return (0);
    for (i = 0; i < state1->nbAttrs; i++) {
        if (state1->attrs[i] != state2->attrs[i])
            return (0);
    }
    return (1);
}

/**
 * xmlRelaxNGFreeValidState:
 * @state:  a validation state structure
 *
 * Deallocate a RelaxNG validation state structure.
 */
static void
xmlRelaxNGFreeValidState(xmlRelaxNGValidCtxtPtr ctxt,
                         xmlRelaxNGValidStatePtr state)
{
    if (state == NULL)
        return;

    if ((ctxt != NULL) && (ctxt->freeState == NULL)) {
        ctxt->freeState = xmlRelaxNGNewStates(ctxt, 40);
    }
    if ((ctxt == NULL) || (ctxt->freeState == NULL)) {
        if (state->attrs != NULL)
            xmlFree(state->attrs);
        xmlFree(state);
    } else {
        xmlRelaxNGAddStatesUniq(ctxt, ctxt->freeState, state);
    }
}

/************************************************************************
 *									*
 *			Semi internal functions				*
 *									*
 ************************************************************************/

/**
 * xmlRelaxParserSetFlag:
 * @ctxt: a RelaxNG parser context
 * @flags: a set of flags values
 *
 * Semi private function used to pass informations to a parser context
 * which are a combination of xmlRelaxNGParserFlag .
 *
 * Returns 0 if success and -1 in case of error
 */
int
xmlRelaxParserSetFlag(xmlRelaxNGParserCtxtPtr ctxt, int flags)
{
    if (ctxt == NULL) return(-1);
    if (flags & XML_RELAXNGP_FREE_DOC) {
        ctxt->crng |= XML_RELAXNGP_FREE_DOC;
	flags -= XML_RELAXNGP_FREE_DOC;
    }
    if (flags & XML_RELAXNGP_CRNG) {
        ctxt->crng |= XML_RELAXNGP_CRNG;
	flags -= XML_RELAXNGP_CRNG;
    }
    if (flags != 0) return(-1);
    return(0);
}

/************************************************************************
 *									*
 *			Document functions				*
 *									*
 ************************************************************************/
static xmlDocPtr xmlRelaxNGCleanupDoc(xmlRelaxNGParserCtxtPtr ctxt,
                                      xmlDocPtr doc);

/**
 * xmlRelaxNGIncludePush:
 * @ctxt:  the parser context
 * @value:  the element doc
 *
 * Pushes a new include on top of the include stack
 *
 * Returns 0 in case of error, the index in the stack otherwise
 */
static int
xmlRelaxNGIncludePush(xmlRelaxNGParserCtxtPtr ctxt,
                      xmlRelaxNGIncludePtr value)
{
    if (ctxt->incTab == NULL) {
        ctxt->incMax = 4;
        ctxt->incNr = 0;
        ctxt->incTab =
            (xmlRelaxNGIncludePtr *) xmlMalloc(ctxt->incMax *
                                               sizeof(ctxt->incTab[0]));
        if (ctxt->incTab == NULL) {
            xmlRngPErrMemory(ctxt, "allocating include\n");
            return (0);
        }
    }
    if (ctxt->incNr >= ctxt->incMax) {
        ctxt->incMax *= 2;
        ctxt->incTab =
            (xmlRelaxNGIncludePtr *) xmlRealloc(ctxt->incTab,
                                                ctxt->incMax *
                                                sizeof(ctxt->incTab[0]));
        if (ctxt->incTab == NULL) {
            xmlRngPErrMemory(ctxt, "allocating include\n");
            return (0);
        }
    }
    ctxt->incTab[ctxt->incNr] = value;
    ctxt->inc = value;
    return (ctxt->incNr++);
}

/**
 * xmlRelaxNGIncludePop:
 * @ctxt: the parser context
 *
 * Pops the top include from the include stack
 *
 * Returns the include just removed
 */
static xmlRelaxNGIncludePtr
xmlRelaxNGIncludePop(xmlRelaxNGParserCtxtPtr ctxt)
{
    xmlRelaxNGIncludePtr ret;

    if (ctxt->incNr <= 0)
        return (NULL);
    ctxt->incNr--;
    if (ctxt->incNr > 0)
        ctxt->inc = ctxt->incTab[ctxt->incNr - 1];
    else
        ctxt->inc = NULL;
    ret = ctxt->incTab[ctxt->incNr];
    ctxt->incTab[ctxt->incNr] = NULL;
    return (ret);
}

/**
 * xmlRelaxNGRemoveRedefine:
 * @ctxt: the parser context
 * @URL:  the normalized URL
 * @target:  the included target
 * @name:  the define name to eliminate
 *
 * Applies the elimination algorithm of 4.7
 *
 * Returns 0 in case of error, 1 in case of success.
 */
static int
xmlRelaxNGRemoveRedefine(xmlRelaxNGParserCtxtPtr ctxt,
                         const xmlChar * URL ATTRIBUTE_UNUSED,
                         xmlNodePtr target, const xmlChar * name)
{
    int found = 0;
    xmlNodePtr tmp, tmp2;
    xmlChar *name2;

#ifdef DEBUG_INCLUDE
    if (name == NULL)
        xmlGenericError(xmlGenericErrorContext,
                        "Elimination of <include> start from %s\n", URL);
    else
        xmlGenericError(xmlGenericErrorContext,
                        "Elimination of <include> define %s from %s\n",
                        name, URL);
#endif
    tmp = target;
    while (tmp != NULL) {
        tmp2 = tmp->next;
        if ((name == NULL) && (IS_RELAXNG(tmp, "start"))) {
            found = 1;
            xmlUnlinkNode(tmp);
            xmlFreeNode(tmp);
        } else if ((name != NULL) && (IS_RELAXNG(tmp, "define"))) {
            name2 = xmlGetProp(tmp, BAD_CAST "name");
            xmlRelaxNGNormExtSpace(name2);
            if (name2 != NULL) {
                if (xmlStrEqual(name, name2)) {
                    found = 1;
                    xmlUnlinkNode(tmp);
                    xmlFreeNode(tmp);
                }
                xmlFree(name2);
            }
        } else if (IS_RELAXNG(tmp, "include")) {
            xmlChar *href = NULL;
            xmlRelaxNGDocumentPtr inc = tmp->psvi;

            if ((inc != NULL) && (inc->doc != NULL) &&
                (inc->doc->children != NULL)) {

                if (xmlStrEqual
                    (inc->doc->children->name, BAD_CAST "grammar")) {
#ifdef DEBUG_INCLUDE
                    href = xmlGetProp(tmp, BAD_CAST "href");
#endif
                    if (xmlRelaxNGRemoveRedefine(ctxt, href,
                                                 xmlDocGetRootElement(inc->doc)->children,
                                                 name) == 1) {
                        found = 1;
                    }
#ifdef DEBUG_INCLUDE
                    if (href != NULL)
                        xmlFree(href);
#endif
                }
            }
        }
        tmp = tmp2;
    }
    return (found);
}

/**
 * xmlRelaxNGLoadInclude:
 * @ctxt: the parser context
 * @URL:  the normalized URL
 * @node: the include node.
 * @ns:  the namespace passed from the context.
 *
 * First lookup if the document is already loaded into the parser context,
 * check against recursion. If not found the resource is loaded and
 * the content is preprocessed before being returned back to the caller.
 *
 * Returns the xmlRelaxNGIncludePtr or NULL in case of error
 */
static xmlRelaxNGIncludePtr
xmlRelaxNGLoadInclude(xmlRelaxNGParserCtxtPtr ctxt, const xmlChar * URL,
                      xmlNodePtr node, const xmlChar * ns)
{
    xmlRelaxNGIncludePtr ret = NULL;
    xmlDocPtr doc;
    int i;
    xmlNodePtr root, cur;

#ifdef DEBUG_INCLUDE
    xmlGenericError(xmlGenericErrorContext,
                    "xmlRelaxNGLoadInclude(%s)\n", URL);
#endif

    /*
     * check against recursion in the stack
     */
    for (i = 0; i < ctxt->incNr; i++) {
        if (xmlStrEqual(ctxt->incTab[i]->href, URL)) {
            xmlRngPErr(ctxt, NULL, XML_RNGP_INCLUDE_RECURSE,
                       "Detected an Include recursion for %s\n", URL,
                       NULL);
            return (NULL);
        }
    }

    /*
     * load the document
     */
    doc = xmlReadFile((const char *) URL,NULL,0);
    if (doc == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_PARSE_ERROR,
                   "xmlRelaxNG: could not load %s\n", URL, NULL);
        return (NULL);
    }
#ifdef DEBUG_INCLUDE
    xmlGenericError(xmlGenericErrorContext, "Parsed %s Okay\n", URL);
#endif

    /*
     * Allocate the document structures and register it first.
     */
    ret = (xmlRelaxNGIncludePtr) xmlMalloc(sizeof(xmlRelaxNGInclude));
    if (ret == NULL) {
        xmlRngPErrMemory(ctxt, "allocating include\n");
        xmlFreeDoc(doc);
        return (NULL);
    }
    memset(ret, 0, sizeof(xmlRelaxNGInclude));
    ret->doc = doc;
    ret->href = xmlStrdup(URL);
    ret->next = ctxt->includes;
    ctxt->includes = ret;

    /*
     * transmit the ns if needed
     */
    if (ns != NULL) {
        root = xmlDocGetRootElement(doc);
        if (root != NULL) {
            if (xmlHasProp(root, BAD_CAST "ns") == NULL) {
                xmlSetProp(root, BAD_CAST "ns", ns);
            }
        }
    }

    /*
     * push it on the stack
     */
    xmlRelaxNGIncludePush(ctxt, ret);

    /*
     * Some preprocessing of the document content, this include recursing
     * in the include stack.
     */
#ifdef DEBUG_INCLUDE
    xmlGenericError(xmlGenericErrorContext, "cleanup of %s\n", URL);
#endif

    doc = xmlRelaxNGCleanupDoc(ctxt, doc);
    if (doc == NULL) {
        ctxt->inc = NULL;
        return (NULL);
    }

    /*
     * Pop up the include from the stack
     */
    xmlRelaxNGIncludePop(ctxt);

#ifdef DEBUG_INCLUDE
    xmlGenericError(xmlGenericErrorContext, "Checking of %s\n", URL);
#endif
    /*
     * Check that the top element is a grammar
     */
    root = xmlDocGetRootElement(doc);
    if (root == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_EMPTY,
                   "xmlRelaxNG: included document is empty %s\n", URL,
                   NULL);
        return (NULL);
    }
    if (!IS_RELAXNG(root, "grammar")) {
        xmlRngPErr(ctxt, node, XML_RNGP_GRAMMAR_MISSING,
                   "xmlRelaxNG: included document %s root is not a grammar\n",
                   URL, NULL);
        return (NULL);
    }

    /*
     * Elimination of redefined rules in the include.
     */
    cur = node->children;
    while (cur != NULL) {
        if (IS_RELAXNG(cur, "start")) {
            int found = 0;

            found =
                xmlRelaxNGRemoveRedefine(ctxt, URL, root->children, NULL);
            if (!found) {
                xmlRngPErr(ctxt, node, XML_RNGP_START_MISSING,
                           "xmlRelaxNG: include %s has a start but not the included grammar\n",
                           URL, NULL);
            }
        } else if (IS_RELAXNG(cur, "define")) {
            xmlChar *name;

            name = xmlGetProp(cur, BAD_CAST "name");
            if (name == NULL) {
                xmlRngPErr(ctxt, node, XML_RNGP_NAME_MISSING,
                           "xmlRelaxNG: include %s has define without name\n",
                           URL, NULL);
            } else {
                int found;

                xmlRelaxNGNormExtSpace(name);
                found = xmlRelaxNGRemoveRedefine(ctxt, URL,
                                                 root->children, name);
                if (!found) {
                    xmlRngPErr(ctxt, node, XML_RNGP_DEFINE_MISSING,
                               "xmlRelaxNG: include %s has a define %s but not the included grammar\n",
                               URL, name);
                }
                xmlFree(name);
            }
        }
        cur = cur->next;
    }


    return (ret);
}

/**
 * xmlRelaxNGValidErrorPush:
 * @ctxt:  the validation context
 * @err:  the error code
 * @arg1:  the first string argument
 * @arg2:  the second string argument
 * @dup:  arg need to be duplicated
 *
 * Pushes a new error on top of the error stack
 *
 * Returns 0 in case of error, the index in the stack otherwise
 */
static int
xmlRelaxNGValidErrorPush(xmlRelaxNGValidCtxtPtr ctxt,
                         xmlRelaxNGValidErr err, const xmlChar * arg1,
                         const xmlChar * arg2, int dup)
{
    xmlRelaxNGValidErrorPtr cur;

#ifdef DEBUG_ERROR
    xmlGenericError(xmlGenericErrorContext,
                    "Pushing error %d at %d on stack\n", err, ctxt->errNr);
#endif
    if (ctxt->errTab == NULL) {
        ctxt->errMax = 8;
        ctxt->errNr = 0;
        ctxt->errTab =
            (xmlRelaxNGValidErrorPtr) xmlMalloc(ctxt->errMax *
                                                sizeof
                                                (xmlRelaxNGValidError));
        if (ctxt->errTab == NULL) {
            xmlRngVErrMemory(ctxt, "pushing error\n");
            return (0);
        }
        ctxt->err = NULL;
    }
    if (ctxt->errNr >= ctxt->errMax) {
        ctxt->errMax *= 2;
        ctxt->errTab =
            (xmlRelaxNGValidErrorPtr) xmlRealloc(ctxt->errTab,
                                                 ctxt->errMax *
                                                 sizeof
                                                 (xmlRelaxNGValidError));
        if (ctxt->errTab == NULL) {
            xmlRngVErrMemory(ctxt, "pushing error\n");
            return (0);
        }
        ctxt->err = &ctxt->errTab[ctxt->errNr - 1];
    }
    if ((ctxt->err != NULL) && (ctxt->state != NULL) &&
        (ctxt->err->node == ctxt->state->node) && (ctxt->err->err == err))
        return (ctxt->errNr);
    cur = &ctxt->errTab[ctxt->errNr];
    cur->err = err;
    if (dup) {
        cur->arg1 = xmlStrdup(arg1);
        cur->arg2 = xmlStrdup(arg2);
        cur->flags = ERROR_IS_DUP;
    } else {
        cur->arg1 = arg1;
        cur->arg2 = arg2;
        cur->flags = 0;
    }
    if (ctxt->state != NULL) {
        cur->node = ctxt->state->node;
        cur->seq = ctxt->state->seq;
    } else {
        cur->node = NULL;
        cur->seq = NULL;
    }
    ctxt->err = cur;
    return (ctxt->errNr++);
}

/**
 * xmlRelaxNGValidErrorPop:
 * @ctxt: the validation context
 *
 * Pops the top error from the error stack
 */
static void
xmlRelaxNGValidErrorPop(xmlRelaxNGValidCtxtPtr ctxt)
{
    xmlRelaxNGValidErrorPtr cur;

    if (ctxt->errNr <= 0) {
        ctxt->err = NULL;
        return;
    }
    ctxt->errNr--;
    if (ctxt->errNr > 0)
        ctxt->err = &ctxt->errTab[ctxt->errNr - 1];
    else
        ctxt->err = NULL;
    cur = &ctxt->errTab[ctxt->errNr];
    if (cur->flags & ERROR_IS_DUP) {
        if (cur->arg1 != NULL)
            xmlFree((xmlChar *) cur->arg1);
        cur->arg1 = NULL;
        if (cur->arg2 != NULL)
            xmlFree((xmlChar *) cur->arg2);
        cur->arg2 = NULL;
        cur->flags = 0;
    }
}

/**
 * xmlRelaxNGDocumentPush:
 * @ctxt:  the parser context
 * @value:  the element doc
 *
 * Pushes a new doc on top of the doc stack
 *
 * Returns 0 in case of error, the index in the stack otherwise
 */
static int
xmlRelaxNGDocumentPush(xmlRelaxNGParserCtxtPtr ctxt,
                       xmlRelaxNGDocumentPtr value)
{
    if (ctxt->docTab == NULL) {
        ctxt->docMax = 4;
        ctxt->docNr = 0;
        ctxt->docTab =
            (xmlRelaxNGDocumentPtr *) xmlMalloc(ctxt->docMax *
                                                sizeof(ctxt->docTab[0]));
        if (ctxt->docTab == NULL) {
            xmlRngPErrMemory(ctxt, "adding document\n");
            return (0);
        }
    }
    if (ctxt->docNr >= ctxt->docMax) {
        ctxt->docMax *= 2;
        ctxt->docTab =
            (xmlRelaxNGDocumentPtr *) xmlRealloc(ctxt->docTab,
                                                 ctxt->docMax *
                                                 sizeof(ctxt->docTab[0]));
        if (ctxt->docTab == NULL) {
            xmlRngPErrMemory(ctxt, "adding document\n");
            return (0);
        }
    }
    ctxt->docTab[ctxt->docNr] = value;
    ctxt->doc = value;
    return (ctxt->docNr++);
}

/**
 * xmlRelaxNGDocumentPop:
 * @ctxt: the parser context
 *
 * Pops the top doc from the doc stack
 *
 * Returns the doc just removed
 */
static xmlRelaxNGDocumentPtr
xmlRelaxNGDocumentPop(xmlRelaxNGParserCtxtPtr ctxt)
{
    xmlRelaxNGDocumentPtr ret;

    if (ctxt->docNr <= 0)
        return (NULL);
    ctxt->docNr--;
    if (ctxt->docNr > 0)
        ctxt->doc = ctxt->docTab[ctxt->docNr - 1];
    else
        ctxt->doc = NULL;
    ret = ctxt->docTab[ctxt->docNr];
    ctxt->docTab[ctxt->docNr] = NULL;
    return (ret);
}

/**
 * xmlRelaxNGLoadExternalRef:
 * @ctxt: the parser context
 * @URL:  the normalized URL
 * @ns:  the inherited ns if any
 *
 * First lookup if the document is already loaded into the parser context,
 * check against recursion. If not found the resource is loaded and
 * the content is preprocessed before being returned back to the caller.
 *
 * Returns the xmlRelaxNGDocumentPtr or NULL in case of error
 */
static xmlRelaxNGDocumentPtr
xmlRelaxNGLoadExternalRef(xmlRelaxNGParserCtxtPtr ctxt,
                          const xmlChar * URL, const xmlChar * ns)
{
    xmlRelaxNGDocumentPtr ret = NULL;
    xmlDocPtr doc;
    xmlNodePtr root;
    int i;

    /*
     * check against recursion in the stack
     */
    for (i = 0; i < ctxt->docNr; i++) {
        if (xmlStrEqual(ctxt->docTab[i]->href, URL)) {
            xmlRngPErr(ctxt, NULL, XML_RNGP_EXTERNALREF_RECURSE,
                       "Detected an externalRef recursion for %s\n", URL,
                       NULL);
            return (NULL);
        }
    }

    /*
     * load the document
     */
    doc = xmlReadFile((const char *) URL,NULL,0);
    if (doc == NULL) {
        xmlRngPErr(ctxt, NULL, XML_RNGP_PARSE_ERROR,
                   "xmlRelaxNG: could not load %s\n", URL, NULL);
        return (NULL);
    }

    /*
     * Allocate the document structures and register it first.
     */
    ret = (xmlRelaxNGDocumentPtr) xmlMalloc(sizeof(xmlRelaxNGDocument));
    if (ret == NULL) {
        xmlRngPErr(ctxt, (xmlNodePtr) doc, XML_ERR_NO_MEMORY,
                   "xmlRelaxNG: allocate memory for doc %s\n", URL, NULL);
        xmlFreeDoc(doc);
        return (NULL);
    }
    memset(ret, 0, sizeof(xmlRelaxNGDocument));
    ret->doc = doc;
    ret->href = xmlStrdup(URL);
    ret->next = ctxt->documents;
    ret->externalRef = 1;
    ctxt->documents = ret;

    /*
     * transmit the ns if needed
     */
    if (ns != NULL) {
        root = xmlDocGetRootElement(doc);
        if (root != NULL) {
            if (xmlHasProp(root, BAD_CAST "ns") == NULL) {
                xmlSetProp(root, BAD_CAST "ns", ns);
            }
        }
    }

    /*
     * push it on the stack and register it in the hash table
     */
    xmlRelaxNGDocumentPush(ctxt, ret);

    /*
     * Some preprocessing of the document content
     */
    doc = xmlRelaxNGCleanupDoc(ctxt, doc);
    if (doc == NULL) {
        ctxt->doc = NULL;
        return (NULL);
    }

    xmlRelaxNGDocumentPop(ctxt);

    return (ret);
}

/************************************************************************
 *									*
 *			Error functions					*
 *									*
 ************************************************************************/

#define VALID_ERR(a) xmlRelaxNGAddValidError(ctxt, a, NULL, NULL, 0);
#define VALID_ERR2(a, b) xmlRelaxNGAddValidError(ctxt, a, b, NULL, 0);
#define VALID_ERR3(a, b, c) xmlRelaxNGAddValidError(ctxt, a, b, c, 0);
#define VALID_ERR2P(a, b) xmlRelaxNGAddValidError(ctxt, a, b, NULL, 1);
#define VALID_ERR3P(a, b, c) xmlRelaxNGAddValidError(ctxt, a, b, c, 1);

static const char *
xmlRelaxNGDefName(xmlRelaxNGDefinePtr def)
{
    if (def == NULL)
        return ("none");
    switch (def->type) {
        case XML_RELAXNG_EMPTY:
            return ("empty");
        case XML_RELAXNG_NOT_ALLOWED:
            return ("notAllowed");
        case XML_RELAXNG_EXCEPT:
            return ("except");
        case XML_RELAXNG_TEXT:
            return ("text");
        case XML_RELAXNG_ELEMENT:
            return ("element");
        case XML_RELAXNG_DATATYPE:
            return ("datatype");
        case XML_RELAXNG_VALUE:
            return ("value");
        case XML_RELAXNG_LIST:
            return ("list");
        case XML_RELAXNG_ATTRIBUTE:
            return ("attribute");
        case XML_RELAXNG_DEF:
            return ("def");
        case XML_RELAXNG_REF:
            return ("ref");
        case XML_RELAXNG_EXTERNALREF:
            return ("externalRef");
        case XML_RELAXNG_PARENTREF:
            return ("parentRef");
        case XML_RELAXNG_OPTIONAL:
            return ("optional");
        case XML_RELAXNG_ZEROORMORE:
            return ("zeroOrMore");
        case XML_RELAXNG_ONEORMORE:
            return ("oneOrMore");
        case XML_RELAXNG_CHOICE:
            return ("choice");
        case XML_RELAXNG_GROUP:
            return ("group");
        case XML_RELAXNG_INTERLEAVE:
            return ("interleave");
        case XML_RELAXNG_START:
            return ("start");
        case XML_RELAXNG_NOOP:
            return ("noop");
        case XML_RELAXNG_PARAM:
            return ("param");
    }
    return ("unknown");
}

/**
 * xmlRelaxNGGetErrorString:
 * @err:  the error code
 * @arg1:  the first string argument
 * @arg2:  the second string argument
 *
 * computes a formatted error string for the given error code and args
 *
 * Returns the error string, it must be deallocated by the caller
 */
static xmlChar *
xmlRelaxNGGetErrorString(xmlRelaxNGValidErr err, const xmlChar * arg1,
                         const xmlChar * arg2)
{
    char msg[1000];

    if (arg1 == NULL)
        arg1 = BAD_CAST "";
    if (arg2 == NULL)
        arg2 = BAD_CAST "";

    msg[0] = 0;
    switch (err) {
        case XML_RELAXNG_OK:
            return (NULL);
        case XML_RELAXNG_ERR_MEMORY:
            return (xmlCharStrdup("out of memory\n"));
        case XML_RELAXNG_ERR_TYPE:
            snprintf(msg, 1000, "failed to validate type %s\n", arg1);
            break;
        case XML_RELAXNG_ERR_TYPEVAL:
            snprintf(msg, 1000, "Type %s doesn't allow value '%s'\n", arg1,
                     arg2);
            break;
        case XML_RELAXNG_ERR_DUPID:
            snprintf(msg, 1000, "ID %s redefined\n", arg1);
            break;
        case XML_RELAXNG_ERR_TYPECMP:
            snprintf(msg, 1000, "failed to compare type %s\n", arg1);
            break;
        case XML_RELAXNG_ERR_NOSTATE:
            return (xmlCharStrdup("Internal error: no state\n"));
        case XML_RELAXNG_ERR_NODEFINE:
            return (xmlCharStrdup("Internal error: no define\n"));
        case XML_RELAXNG_ERR_INTERNAL:
            snprintf(msg, 1000, "Internal error: %s\n", arg1);
            break;
        case XML_RELAXNG_ERR_LISTEXTRA:
            snprintf(msg, 1000, "Extra data in list: %s\n", arg1);
            break;
        case XML_RELAXNG_ERR_INTERNODATA:
            return (xmlCharStrdup
                    ("Internal: interleave block has no data\n"));
        case XML_RELAXNG_ERR_INTERSEQ:
            return (xmlCharStrdup("Invalid sequence in interleave\n"));
        case XML_RELAXNG_ERR_INTEREXTRA:
            snprintf(msg, 1000, "Extra element %s in interleave\n", arg1);
            break;
        case XML_RELAXNG_ERR_ELEMNAME:
            snprintf(msg, 1000, "Expecting element %s, got %s\n", arg1,
                     arg2);
            break;
        case XML_RELAXNG_ERR_ELEMNONS:
            snprintf(msg, 1000, "Expecting a namespace for element %s\n",
                     arg1);
            break;
        case XML_RELAXNG_ERR_ELEMWRONGNS:
            snprintf(msg, 1000,
                     "Element %s has wrong namespace: expecting %s\n", arg1,
                     arg2);
            break;
        case XML_RELAXNG_ERR_ELEMWRONG:
            snprintf(msg, 1000, "Did not expect element %s there\n", arg1);
            break;
        case XML_RELAXNG_ERR_TEXTWRONG:
            snprintf(msg, 1000,
                     "Did not expect text in element %s content\n", arg1);
            break;
        case XML_RELAXNG_ERR_ELEMEXTRANS:
            snprintf(msg, 1000, "Expecting no namespace for element %s\n",
                     arg1);
            break;
        case XML_RELAXNG_ERR_ELEMNOTEMPTY:
            snprintf(msg, 1000, "Expecting element %s to be empty\n", arg1);
            break;
        case XML_RELAXNG_ERR_NOELEM:
            snprintf(msg, 1000, "Expecting an element %s, got nothing\n",
                     arg1);
            break;
        case XML_RELAXNG_ERR_NOTELEM:
            return (xmlCharStrdup("Expecting an element got text\n"));
        case XML_RELAXNG_ERR_ATTRVALID:
            snprintf(msg, 1000, "Element %s failed to validate attributes\n",
                     arg1);
            break;
        case XML_RELAXNG_ERR_CONTENTVALID:
            snprintf(msg, 1000, "Element %s failed to validate content\n",
                     arg1);
            break;
        case XML_RELAXNG_ERR_EXTRACONTENT:
            snprintf(msg, 1000, "Element %s has extra content: %s\n",
                     arg1, arg2);
            break;
        case XML_RELAXNG_ERR_INVALIDATTR:
            snprintf(msg, 1000, "Invalid attribute %s for element %s\n",
                     arg1, arg2);
            break;
        case XML_RELAXNG_ERR_LACKDATA:
            snprintf(msg, 1000, "Datatype element %s contains no data\n",
                     arg1);
            break;
        case XML_RELAXNG_ERR_DATAELEM:
            snprintf(msg, 1000, "Datatype element %s has child elements\n",
                     arg1);
            break;
        case XML_RELAXNG_ERR_VALELEM:
            snprintf(msg, 1000, "Value element %s has child elements\n",
                     arg1);
            break;
        case XML_RELAXNG_ERR_LISTELEM:
            snprintf(msg, 1000, "List element %s has child elements\n",
                     arg1);
            break;
        case XML_RELAXNG_ERR_DATATYPE:
            snprintf(msg, 1000, "Error validating datatype %s\n", arg1);
            break;
        case XML_RELAXNG_ERR_VALUE:
            snprintf(msg, 1000, "Error validating value %s\n", arg1);
            break;
        case XML_RELAXNG_ERR_LIST:
            return (xmlCharStrdup("Error validating list\n"));
        case XML_RELAXNG_ERR_NOGRAMMAR:
            return (xmlCharStrdup("No top grammar defined\n"));
        case XML_RELAXNG_ERR_EXTRADATA:
            return (xmlCharStrdup("Extra data in the document\n"));
        default:
            return (xmlCharStrdup("Unknown error !\n"));
    }
    if (msg[0] == 0) {
        snprintf(msg, 1000, "Unknown error code %d\n", err);
    }
    msg[1000 - 1] = 0;
    return (xmlStrdup((xmlChar *) msg));
}

/**
 * xmlRelaxNGShowValidError:
 * @ctxt:  the validation context
 * @err:  the error number
 * @node:  the node
 * @child:  the node child generating the problem.
 * @arg1:  the first argument
 * @arg2:  the second argument
 *
 * Show a validation error.
 */
static void
xmlRelaxNGShowValidError(xmlRelaxNGValidCtxtPtr ctxt,
                         xmlRelaxNGValidErr err, xmlNodePtr node,
                         xmlNodePtr child, const xmlChar * arg1,
                         const xmlChar * arg2)
{
    xmlChar *msg;

    if (ctxt->flags & FLAGS_NOERROR)
        return;

#ifdef DEBUG_ERROR
    xmlGenericError(xmlGenericErrorContext, "Show error %d\n", err);
#endif
    msg = xmlRelaxNGGetErrorString(err, arg1, arg2);
    if (msg == NULL)
        return;

    if (ctxt->errNo == XML_RELAXNG_OK)
        ctxt->errNo = err;
    xmlRngVErr(ctxt, (child == NULL ? node : child), err,
               (const char *) msg, arg1, arg2);
    xmlFree(msg);
}

/**
 * xmlRelaxNGPopErrors:
 * @ctxt:  the validation context
 * @level:  the error level in the stack
 *
 * pop and discard all errors until the given level is reached
 */
static void
xmlRelaxNGPopErrors(xmlRelaxNGValidCtxtPtr ctxt, int level)
{
    int i;
    xmlRelaxNGValidErrorPtr err;

#ifdef DEBUG_ERROR
    xmlGenericError(xmlGenericErrorContext,
                    "Pop errors till level %d\n", level);
#endif
    for (i = level; i < ctxt->errNr; i++) {
        err = &ctxt->errTab[i];
        if (err->flags & ERROR_IS_DUP) {
            if (err->arg1 != NULL)
                xmlFree((xmlChar *) err->arg1);
            err->arg1 = NULL;
            if (err->arg2 != NULL)
                xmlFree((xmlChar *) err->arg2);
            err->arg2 = NULL;
            err->flags = 0;
        }
    }
    ctxt->errNr = level;
    if (ctxt->errNr <= 0)
        ctxt->err = NULL;
}

/**
 * xmlRelaxNGDumpValidError:
 * @ctxt:  the validation context
 *
 * Show all validation error over a given index.
 */
static void
xmlRelaxNGDumpValidError(xmlRelaxNGValidCtxtPtr ctxt)
{
    int i, j, k;
    xmlRelaxNGValidErrorPtr err, dup;

#ifdef DEBUG_ERROR
    xmlGenericError(xmlGenericErrorContext,
                    "Dumping error stack %d errors\n", ctxt->errNr);
#endif
    for (i = 0, k = 0; i < ctxt->errNr; i++) {
        err = &ctxt->errTab[i];
        if (k < MAX_ERROR) {
            for (j = 0; j < i; j++) {
                dup = &ctxt->errTab[j];
                if ((err->err == dup->err) && (err->node == dup->node) &&
                    (xmlStrEqual(err->arg1, dup->arg1)) &&
                    (xmlStrEqual(err->arg2, dup->arg2))) {
                    goto skip;
                }
            }
            xmlRelaxNGShowValidError(ctxt, err->err, err->node, err->seq,
                                     err->arg1, err->arg2);
            k++;
        }
      skip:
        if (err->flags & ERROR_IS_DUP) {
            if (err->arg1 != NULL)
                xmlFree((xmlChar *) err->arg1);
            err->arg1 = NULL;
            if (err->arg2 != NULL)
                xmlFree((xmlChar *) err->arg2);
            err->arg2 = NULL;
            err->flags = 0;
        }
    }
    ctxt->errNr = 0;
}

/**
 * xmlRelaxNGAddValidError:
 * @ctxt:  the validation context
 * @err:  the error number
 * @arg1:  the first argument
 * @arg2:  the second argument
 * @dup:  need to dup the args
 *
 * Register a validation error, either generating it if it's sure
 * or stacking it for later handling if unsure.
 */
static void
xmlRelaxNGAddValidError(xmlRelaxNGValidCtxtPtr ctxt,
                        xmlRelaxNGValidErr err, const xmlChar * arg1,
                        const xmlChar * arg2, int dup)
{
    if (ctxt == NULL)
        return;
    if (ctxt->flags & FLAGS_NOERROR)
        return;

#ifdef DEBUG_ERROR
    xmlGenericError(xmlGenericErrorContext, "Adding error %d\n", err);
#endif
    /*
     * generate the error directly
     */
    if (((ctxt->flags & FLAGS_IGNORABLE) == 0) ||
	 (ctxt->flags & FLAGS_NEGATIVE)) {
        xmlNodePtr node, seq;

        /*
         * Flush first any stacked error which might be the
         * real cause of the problem.
         */
        if (ctxt->errNr != 0)
            xmlRelaxNGDumpValidError(ctxt);
        if (ctxt->state != NULL) {
            node = ctxt->state->node;
            seq = ctxt->state->seq;
        } else {
            node = seq = NULL;
        }
        if ((node == NULL) && (seq == NULL)) {
            node = ctxt->pnode;
        }
        xmlRelaxNGShowValidError(ctxt, err, node, seq, arg1, arg2);
    }
    /*
     * Stack the error for later processing if needed
     */
    else {
        xmlRelaxNGValidErrorPush(ctxt, err, arg1, arg2, dup);
    }
}


/************************************************************************
 *									*
 *			Type library hooks				*
 *									*
 ************************************************************************/
static xmlChar *xmlRelaxNGNormalize(xmlRelaxNGValidCtxtPtr ctxt,
                                    const xmlChar * str);

/**
 * xmlRelaxNGSchemaTypeHave:
 * @data:  data needed for the library
 * @type:  the type name
 *
 * Check if the given type is provided by
 * the W3C XMLSchema Datatype library.
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
static int
xmlRelaxNGSchemaTypeHave(void *data ATTRIBUTE_UNUSED, const xmlChar * type)
{
    xmlSchemaTypePtr typ;

    if (type == NULL)
        return (-1);
    typ = xmlSchemaGetPredefinedType(type,
                                     BAD_CAST
                                     "http://www.w3.org/2001/XMLSchema");
    if (typ == NULL)
        return (0);
    return (1);
}

/**
 * xmlRelaxNGSchemaTypeCheck:
 * @data:  data needed for the library
 * @type:  the type name
 * @value:  the value to check
 * @node:  the node
 *
 * Check if the given type and value are validated by
 * the W3C XMLSchema Datatype library.
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
static int
xmlRelaxNGSchemaTypeCheck(void *data ATTRIBUTE_UNUSED,
                          const xmlChar * type,
                          const xmlChar * value,
                          void **result, xmlNodePtr node)
{
    xmlSchemaTypePtr typ;
    int ret;

    if ((type == NULL) || (value == NULL))
        return (-1);
    typ = xmlSchemaGetPredefinedType(type,
                                     BAD_CAST
                                     "http://www.w3.org/2001/XMLSchema");
    if (typ == NULL)
        return (-1);
    ret = xmlSchemaValPredefTypeNode(typ, value,
                                     (xmlSchemaValPtr *) result, node);
    if (ret == 2)               /* special ID error code */
        return (2);
    if (ret == 0)
        return (1);
    if (ret > 0)
        return (0);
    return (-1);
}

/**
 * xmlRelaxNGSchemaFacetCheck:
 * @data:  data needed for the library
 * @type:  the type name
 * @facet:  the facet name
 * @val:  the facet value
 * @strval:  the string value
 * @value:  the value to check
 *
 * Function provided by a type library to check a value facet
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
static int
xmlRelaxNGSchemaFacetCheck(void *data ATTRIBUTE_UNUSED,
                           const xmlChar * type, const xmlChar * facetname,
                           const xmlChar * val, const xmlChar * strval,
                           void *value)
{
    xmlSchemaFacetPtr facet;
    xmlSchemaTypePtr typ;
    int ret;

    if ((type == NULL) || (strval == NULL))
        return (-1);
    typ = xmlSchemaGetPredefinedType(type,
                                     BAD_CAST
                                     "http://www.w3.org/2001/XMLSchema");
    if (typ == NULL)
        return (-1);

    facet = xmlSchemaNewFacet();
    if (facet == NULL)
        return (-1);

    if (xmlStrEqual(facetname, BAD_CAST "minInclusive")) {
        facet->type = XML_SCHEMA_FACET_MININCLUSIVE;
    } else if (xmlStrEqual(facetname, BAD_CAST "minExclusive")) {
        facet->type = XML_SCHEMA_FACET_MINEXCLUSIVE;
    } else if (xmlStrEqual(facetname, BAD_CAST "maxInclusive")) {
        facet->type = XML_SCHEMA_FACET_MAXINCLUSIVE;
    } else if (xmlStrEqual(facetname, BAD_CAST "maxExclusive")) {
        facet->type = XML_SCHEMA_FACET_MAXEXCLUSIVE;
    } else if (xmlStrEqual(facetname, BAD_CAST "totalDigits")) {
        facet->type = XML_SCHEMA_FACET_TOTALDIGITS;
    } else if (xmlStrEqual(facetname, BAD_CAST "fractionDigits")) {
        facet->type = XML_SCHEMA_FACET_FRACTIONDIGITS;
    } else if (xmlStrEqual(facetname, BAD_CAST "pattern")) {
        facet->type = XML_SCHEMA_FACET_PATTERN;
    } else if (xmlStrEqual(facetname, BAD_CAST "enumeration")) {
        facet->type = XML_SCHEMA_FACET_ENUMERATION;
    } else if (xmlStrEqual(facetname, BAD_CAST "whiteSpace")) {
        facet->type = XML_SCHEMA_FACET_WHITESPACE;
    } else if (xmlStrEqual(facetname, BAD_CAST "length")) {
        facet->type = XML_SCHEMA_FACET_LENGTH;
    } else if (xmlStrEqual(facetname, BAD_CAST "maxLength")) {
        facet->type = XML_SCHEMA_FACET_MAXLENGTH;
    } else if (xmlStrEqual(facetname, BAD_CAST "minLength")) {
        facet->type = XML_SCHEMA_FACET_MINLENGTH;
    } else {
        xmlSchemaFreeFacet(facet);
        return (-1);
    }
    facet->value = val;
    ret = xmlSchemaCheckFacet(facet, typ, NULL, type);
    if (ret != 0) {
        xmlSchemaFreeFacet(facet);
        return (-1);
    }
    ret = xmlSchemaValidateFacet(typ, facet, strval, value);
    xmlSchemaFreeFacet(facet);
    if (ret != 0)
        return (-1);
    return (0);
}

/**
 * xmlRelaxNGSchemaFreeValue:
 * @data:  data needed for the library
 * @value:  the value to free
 *
 * Function provided by a type library to free a Schemas value
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
static void
xmlRelaxNGSchemaFreeValue(void *data ATTRIBUTE_UNUSED, void *value)
{
    xmlSchemaFreeValue(value);
}

/**
 * xmlRelaxNGSchemaTypeCompare:
 * @data:  data needed for the library
 * @type:  the type name
 * @value1:  the first value
 * @value2:  the second value
 *
 * Compare two values for equality accordingly a type from the W3C XMLSchema
 * Datatype library.
 *
 * Returns 1 if equal, 0 if no and -1 in case of error.
 */
static int
xmlRelaxNGSchemaTypeCompare(void *data ATTRIBUTE_UNUSED,
                            const xmlChar * type,
                            const xmlChar * value1,
                            xmlNodePtr ctxt1,
                            void *comp1,
                            const xmlChar * value2, xmlNodePtr ctxt2)
{
    int ret;
    xmlSchemaTypePtr typ;
    xmlSchemaValPtr res1 = NULL, res2 = NULL;

    if ((type == NULL) || (value1 == NULL) || (value2 == NULL))
        return (-1);
    typ = xmlSchemaGetPredefinedType(type,
                                     BAD_CAST
                                     "http://www.w3.org/2001/XMLSchema");
    if (typ == NULL)
        return (-1);
    if (comp1 == NULL) {
        ret = xmlSchemaValPredefTypeNode(typ, value1, &res1, ctxt1);
        if (ret != 0)
            return (-1);
        if (res1 == NULL)
            return (-1);
    } else {
        res1 = (xmlSchemaValPtr) comp1;
    }
    ret = xmlSchemaValPredefTypeNode(typ, value2, &res2, ctxt2);
    if (ret != 0) {
	if (res1 != (xmlSchemaValPtr) comp1)
	    xmlSchemaFreeValue(res1);
        return (-1);
    }
    ret = xmlSchemaCompareValues(res1, res2);
    if (res1 != (xmlSchemaValPtr) comp1)
        xmlSchemaFreeValue(res1);
    xmlSchemaFreeValue(res2);
    if (ret == -2)
        return (-1);
    if (ret == 0)
        return (1);
    return (0);
}

/**
 * xmlRelaxNGDefaultTypeHave:
 * @data:  data needed for the library
 * @type:  the type name
 *
 * Check if the given type is provided by
 * the default datatype library.
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
static int
xmlRelaxNGDefaultTypeHave(void *data ATTRIBUTE_UNUSED,
                          const xmlChar * type)
{
    if (type == NULL)
        return (-1);
    if (xmlStrEqual(type, BAD_CAST "string"))
        return (1);
    if (xmlStrEqual(type, BAD_CAST "token"))
        return (1);
    return (0);
}

/**
 * xmlRelaxNGDefaultTypeCheck:
 * @data:  data needed for the library
 * @type:  the type name
 * @value:  the value to check
 * @node:  the node
 *
 * Check if the given type and value are validated by
 * the default datatype library.
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
static int
xmlRelaxNGDefaultTypeCheck(void *data ATTRIBUTE_UNUSED,
                           const xmlChar * type ATTRIBUTE_UNUSED,
                           const xmlChar * value ATTRIBUTE_UNUSED,
                           void **result ATTRIBUTE_UNUSED,
                           xmlNodePtr node ATTRIBUTE_UNUSED)
{
    if (value == NULL)
        return (-1);
    if (xmlStrEqual(type, BAD_CAST "string"))
        return (1);
    if (xmlStrEqual(type, BAD_CAST "token")) {
        return (1);
    }

    return (0);
}

/**
 * xmlRelaxNGDefaultTypeCompare:
 * @data:  data needed for the library
 * @type:  the type name
 * @value1:  the first value
 * @value2:  the second value
 *
 * Compare two values accordingly a type from the default
 * datatype library.
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
static int
xmlRelaxNGDefaultTypeCompare(void *data ATTRIBUTE_UNUSED,
                             const xmlChar * type,
                             const xmlChar * value1,
                             xmlNodePtr ctxt1 ATTRIBUTE_UNUSED,
                             void *comp1 ATTRIBUTE_UNUSED,
                             const xmlChar * value2,
                             xmlNodePtr ctxt2 ATTRIBUTE_UNUSED)
{
    int ret = -1;

    if (xmlStrEqual(type, BAD_CAST "string")) {
        ret = xmlStrEqual(value1, value2);
    } else if (xmlStrEqual(type, BAD_CAST "token")) {
        if (!xmlStrEqual(value1, value2)) {
            xmlChar *nval, *nvalue;

            /*
             * TODO: trivial optimizations are possible by
             * computing at compile-time
             */
            nval = xmlRelaxNGNormalize(NULL, value1);
            nvalue = xmlRelaxNGNormalize(NULL, value2);

            if ((nval == NULL) || (nvalue == NULL))
                ret = -1;
            else if (xmlStrEqual(nval, nvalue))
                ret = 1;
            else
                ret = 0;
            if (nval != NULL)
                xmlFree(nval);
            if (nvalue != NULL)
                xmlFree(nvalue);
        } else
            ret = 1;
    }
    return (ret);
}

static int xmlRelaxNGTypeInitialized = 0;
static xmlHashTablePtr xmlRelaxNGRegisteredTypes = NULL;

/**
 * xmlRelaxNGFreeTypeLibrary:
 * @lib:  the type library structure
 * @namespace:  the URI bound to the library
 *
 * Free the structure associated to the type library
 */
static void
xmlRelaxNGFreeTypeLibrary(xmlRelaxNGTypeLibraryPtr lib,
                          const xmlChar * namespace ATTRIBUTE_UNUSED)
{
    if (lib == NULL)
        return;
    if (lib->namespace != NULL)
        xmlFree((xmlChar *) lib->namespace);
    xmlFree(lib);
}

/**
 * xmlRelaxNGRegisterTypeLibrary:
 * @namespace:  the URI bound to the library
 * @data:  data associated to the library
 * @have:  the provide function
 * @check:  the checking function
 * @comp:  the comparison function
 *
 * Register a new type library
 *
 * Returns 0 in case of success and -1 in case of error.
 */
static int
xmlRelaxNGRegisterTypeLibrary(const xmlChar * namespace, void *data,
                              xmlRelaxNGTypeHave have,
                              xmlRelaxNGTypeCheck check,
                              xmlRelaxNGTypeCompare comp,
                              xmlRelaxNGFacetCheck facet,
                              xmlRelaxNGTypeFree freef)
{
    xmlRelaxNGTypeLibraryPtr lib;
    int ret;

    if ((xmlRelaxNGRegisteredTypes == NULL) || (namespace == NULL) ||
        (check == NULL) || (comp == NULL))
        return (-1);
    if (xmlHashLookup(xmlRelaxNGRegisteredTypes, namespace) != NULL) {
        xmlGenericError(xmlGenericErrorContext,
                        "Relax-NG types library '%s' already registered\n",
                        namespace);
        return (-1);
    }
    lib =
        (xmlRelaxNGTypeLibraryPtr)
        xmlMalloc(sizeof(xmlRelaxNGTypeLibrary));
    if (lib == NULL) {
        xmlRngVErrMemory(NULL, "adding types library\n");
        return (-1);
    }
    memset(lib, 0, sizeof(xmlRelaxNGTypeLibrary));
    lib->namespace = xmlStrdup(namespace);
    lib->data = data;
    lib->have = have;
    lib->comp = comp;
    lib->check = check;
    lib->facet = facet;
    lib->freef = freef;
    ret = xmlHashAddEntry(xmlRelaxNGRegisteredTypes, namespace, lib);
    if (ret < 0) {
        xmlGenericError(xmlGenericErrorContext,
                        "Relax-NG types library failed to register '%s'\n",
                        namespace);
        xmlRelaxNGFreeTypeLibrary(lib, namespace);
        return (-1);
    }
    return (0);
}

/**
 * xmlRelaxNGInitTypes:
 *
 * Initilize the default type libraries.
 *
 * Returns 0 in case of success and -1 in case of error.
 */
int
xmlRelaxNGInitTypes(void)
{
    if (xmlRelaxNGTypeInitialized != 0)
        return (0);
    xmlRelaxNGRegisteredTypes = xmlHashCreate(10);
    if (xmlRelaxNGRegisteredTypes == NULL) {
        xmlGenericError(xmlGenericErrorContext,
                        "Failed to allocate sh table for Relax-NG types\n");
        return (-1);
    }
    xmlRelaxNGRegisterTypeLibrary(BAD_CAST
                                  "http://www.w3.org/2001/XMLSchema-datatypes",
                                  NULL, xmlRelaxNGSchemaTypeHave,
                                  xmlRelaxNGSchemaTypeCheck,
                                  xmlRelaxNGSchemaTypeCompare,
                                  xmlRelaxNGSchemaFacetCheck,
                                  xmlRelaxNGSchemaFreeValue);
    xmlRelaxNGRegisterTypeLibrary(xmlRelaxNGNs, NULL,
                                  xmlRelaxNGDefaultTypeHave,
                                  xmlRelaxNGDefaultTypeCheck,
                                  xmlRelaxNGDefaultTypeCompare, NULL,
                                  NULL);
    xmlRelaxNGTypeInitialized = 1;
    return (0);
}

/**
 * xmlRelaxNGCleanupTypes:
 *
 * Cleanup the default Schemas type library associated to RelaxNG
 */
void
xmlRelaxNGCleanupTypes(void)
{
    xmlSchemaCleanupTypes();
    if (xmlRelaxNGTypeInitialized == 0)
        return;
    xmlHashFree(xmlRelaxNGRegisteredTypes, (xmlHashDeallocator)
                xmlRelaxNGFreeTypeLibrary);
    xmlRelaxNGTypeInitialized = 0;
}

/************************************************************************
 *									*
 *		Compiling element content into regexp			*
 *									*
 * Sometime the element content can be compiled into a pure regexp,	*
 * This allows a faster execution and streamability at that level	*
 *									*
 ************************************************************************/

/* from automata.c but not exported */
void xmlAutomataSetFlags(xmlAutomataPtr am, int flags);


static int xmlRelaxNGTryCompile(xmlRelaxNGParserCtxtPtr ctxt,
                                xmlRelaxNGDefinePtr def);

/**
 * xmlRelaxNGIsCompileable:
 * @define:  the definition to check
 *
 * Check if a definition is nullable.
 *
 * Returns 1 if yes, 0 if no and -1 in case of error
 */
static int
xmlRelaxNGIsCompileable(xmlRelaxNGDefinePtr def)
{
    int ret = -1;

    if (def == NULL) {
        return (-1);
    }
    if ((def->type != XML_RELAXNG_ELEMENT) &&
        (def->dflags & IS_COMPILABLE))
        return (1);
    if ((def->type != XML_RELAXNG_ELEMENT) &&
        (def->dflags & IS_NOT_COMPILABLE))
        return (0);
    switch (def->type) {
        case XML_RELAXNG_NOOP:
            ret = xmlRelaxNGIsCompileable(def->content);
            break;
        case XML_RELAXNG_TEXT:
        case XML_RELAXNG_EMPTY:
            ret = 1;
            break;
        case XML_RELAXNG_ELEMENT:
            /*
             * Check if the element content is compileable
             */
            if (((def->dflags & IS_NOT_COMPILABLE) == 0) &&
                ((def->dflags & IS_COMPILABLE) == 0)) {
                xmlRelaxNGDefinePtr list;

                list = def->content;
                while (list != NULL) {
                    ret = xmlRelaxNGIsCompileable(list);
                    if (ret != 1)
                        break;
                    list = list->next;
                }
		/*
		 * Because the routine is recursive, we must guard against
		 * discovering both COMPILABLE and NOT_COMPILABLE
		 */
                if (ret == 0) {
		    def->dflags &= ~IS_COMPILABLE;
                    def->dflags |= IS_NOT_COMPILABLE;
		}
                if ((ret == 1) && !(def->dflags &= IS_NOT_COMPILABLE))
                    def->dflags |= IS_COMPILABLE;
#ifdef DEBUG_COMPILE
                if (ret == 1) {
                    xmlGenericError(xmlGenericErrorContext,
                                    "element content for %s is compilable\n",
                                    def->name);
                } else if (ret == 0) {
                    xmlGenericError(xmlGenericErrorContext,
                                    "element content for %s is not compilable\n",
                                    def->name);
                } else {
                    xmlGenericError(xmlGenericErrorContext,
                                    "Problem in RelaxNGIsCompileable for element %s\n",
                                    def->name);
                }
#endif
            }
            /*
             * All elements return a compileable status unless they
             * are generic like anyName
             */
            if ((def->nameClass != NULL) || (def->name == NULL))
                ret = 0;
            else
                ret = 1;
            return (ret);
        case XML_RELAXNG_REF:
        case XML_RELAXNG_EXTERNALREF:
        case XML_RELAXNG_PARENTREF:
            if (def->depth == -20) {
                return (1);
            } else {
                xmlRelaxNGDefinePtr list;

                def->depth = -20;
                list = def->content;
                while (list != NULL) {
                    ret = xmlRelaxNGIsCompileable(list);
                    if (ret != 1)
                        break;
                    list = list->next;
                }
            }
            break;
        case XML_RELAXNG_START:
        case XML_RELAXNG_OPTIONAL:
        case XML_RELAXNG_ZEROORMORE:
        case XML_RELAXNG_ONEORMORE:
        case XML_RELAXNG_CHOICE:
        case XML_RELAXNG_GROUP:
        case XML_RELAXNG_DEF:{
                xmlRelaxNGDefinePtr list;

                list = def->content;
                while (list != NULL) {
                    ret = xmlRelaxNGIsCompileable(list);
                    if (ret != 1)
                        break;
                    list = list->next;
                }
                break;
            }
        case XML_RELAXNG_EXCEPT:
        case XML_RELAXNG_ATTRIBUTE:
        case XML_RELAXNG_INTERLEAVE:
        case XML_RELAXNG_DATATYPE:
        case XML_RELAXNG_LIST:
        case XML_RELAXNG_PARAM:
        case XML_RELAXNG_VALUE:
        case XML_RELAXNG_NOT_ALLOWED:
            ret = 0;
            break;
    }
    if (ret == 0)
        def->dflags |= IS_NOT_COMPILABLE;
    if (ret == 1)
        def->dflags |= IS_COMPILABLE;
#ifdef DEBUG_COMPILE
    if (ret == 1) {
        xmlGenericError(xmlGenericErrorContext,
                        "RelaxNGIsCompileable %s : true\n",
                        xmlRelaxNGDefName(def));
    } else if (ret == 0) {
        xmlGenericError(xmlGenericErrorContext,
                        "RelaxNGIsCompileable %s : false\n",
                        xmlRelaxNGDefName(def));
    } else {
        xmlGenericError(xmlGenericErrorContext,
                        "Problem in RelaxNGIsCompileable %s\n",
                        xmlRelaxNGDefName(def));
    }
#endif
    return (ret);
}

/**
 * xmlRelaxNGCompile:
 * ctxt:  the RelaxNG parser context
 * @define:  the definition tree to compile
 *
 * Compile the set of definitions, it works recursively, till the
 * element boundaries, where it tries to compile the content if possible
 *
 * Returns 0 if success and -1 in case of error
 */
static int
xmlRelaxNGCompile(xmlRelaxNGParserCtxtPtr ctxt, xmlRelaxNGDefinePtr def)
{
    int ret = 0;
    xmlRelaxNGDefinePtr list;

    if ((ctxt == NULL) || (def == NULL))
        return (-1);

    switch (def->type) {
        case XML_RELAXNG_START:
            if ((xmlRelaxNGIsCompileable(def) == 1) && (def->depth != -25)) {
                xmlAutomataPtr oldam = ctxt->am;
                xmlAutomataStatePtr oldstate = ctxt->state;

                def->depth = -25;

                list = def->content;
                ctxt->am = xmlNewAutomata();
                if (ctxt->am == NULL)
                    return (-1);

                /*
                 * assume identical strings but not same pointer are different
                 * atoms, needed for non-determinism detection
                 * That way if 2 elements with the same name are in a choice
                 * branch the automata is found non-deterministic and
                 * we fallback to the normal validation which does the right
                 * thing of exploring both choices.
                 */
                xmlAutomataSetFlags(ctxt->am, 1);

                ctxt->state = xmlAutomataGetInitState(ctxt->am);
                while (list != NULL) {
                    xmlRelaxNGCompile(ctxt, list);
                    list = list->next;
                }
                xmlAutomataSetFinalState(ctxt->am, ctxt->state);
                if (xmlAutomataIsDeterminist(ctxt->am))
                    def->contModel = xmlAutomataCompile(ctxt->am);

                xmlFreeAutomata(ctxt->am);
                ctxt->state = oldstate;
                ctxt->am = oldam;
            }
            break;
        case XML_RELAXNG_ELEMENT:
            if ((ctxt->am != NULL) && (def->name != NULL)) {
                ctxt->state = xmlAutomataNewTransition2(ctxt->am,
                                                        ctxt->state, NULL,
                                                        def->name, def->ns,
                                                        def);
            }
            if ((def->dflags & IS_COMPILABLE) && (def->depth != -25)) {
                xmlAutomataPtr oldam = ctxt->am;
                xmlAutomataStatePtr oldstate = ctxt->state;

                def->depth = -25;

                list = def->content;
                ctxt->am = xmlNewAutomata();
                if (ctxt->am == NULL)
                    return (-1);
                xmlAutomataSetFlags(ctxt->am, 1);
                ctxt->state = xmlAutomataGetInitState(ctxt->am);
                while (list != NULL) {
                    xmlRelaxNGCompile(ctxt, list);
                    list = list->next;
                }
                xmlAutomataSetFinalState(ctxt->am, ctxt->state);
                def->contModel = xmlAutomataCompile(ctxt->am);
                if (!xmlRegexpIsDeterminist(def->contModel)) {
#ifdef DEBUG_COMPILE
                    xmlGenericError(xmlGenericErrorContext,
                        "Content model not determinist %s\n",
                                    def->name);
#endif
                    /*
                     * we can only use the automata if it is determinist
                     */
                    xmlRegFreeRegexp(def->contModel);
                    def->contModel = NULL;
                }
                xmlFreeAutomata(ctxt->am);
                ctxt->state = oldstate;
                ctxt->am = oldam;
            } else {
                xmlAutomataPtr oldam = ctxt->am;

                /*
                 * we can't build the content model for this element content
                 * but it still might be possible to build it for some of its
                 * children, recurse.
                 */
                ret = xmlRelaxNGTryCompile(ctxt, def);
                ctxt->am = oldam;
            }
            break;
        case XML_RELAXNG_NOOP:
            ret = xmlRelaxNGCompile(ctxt, def->content);
            break;
        case XML_RELAXNG_OPTIONAL:{
                xmlAutomataStatePtr oldstate = ctxt->state;

                list = def->content;
                while (list != NULL) {
                    xmlRelaxNGCompile(ctxt, list);
                    list = list->next;
                }
                xmlAutomataNewEpsilon(ctxt->am, oldstate, ctxt->state);
                break;
            }
        case XML_RELAXNG_ZEROORMORE:{
                xmlAutomataStatePtr oldstate;

                ctxt->state =
                    xmlAutomataNewEpsilon(ctxt->am, ctxt->state, NULL);
                oldstate = ctxt->state;
                list = def->content;
                while (list != NULL) {
                    xmlRelaxNGCompile(ctxt, list);
                    list = list->next;
                }
                xmlAutomataNewEpsilon(ctxt->am, ctxt->state, oldstate);
                ctxt->state =
                    xmlAutomataNewEpsilon(ctxt->am, oldstate, NULL);
                break;
            }
        case XML_RELAXNG_ONEORMORE:{
                xmlAutomataStatePtr oldstate;

                list = def->content;
                while (list != NULL) {
                    xmlRelaxNGCompile(ctxt, list);
                    list = list->next;
                }
                oldstate = ctxt->state;
                list = def->content;
                while (list != NULL) {
                    xmlRelaxNGCompile(ctxt, list);
                    list = list->next;
                }
                xmlAutomataNewEpsilon(ctxt->am, ctxt->state, oldstate);
                ctxt->state =
                    xmlAutomataNewEpsilon(ctxt->am, oldstate, NULL);
                break;
            }
        case XML_RELAXNG_CHOICE:{
                xmlAutomataStatePtr target = NULL;
                xmlAutomataStatePtr oldstate = ctxt->state;

                list = def->content;
                while (list != NULL) {
                    ctxt->state = oldstate;
                    ret = xmlRelaxNGCompile(ctxt, list);
                    if (ret != 0)
                        break;
                    if (target == NULL)
                        target = ctxt->state;
                    else {
                        xmlAutomataNewEpsilon(ctxt->am, ctxt->state,
                                              target);
                    }
                    list = list->next;
                }
                ctxt->state = target;

                break;
            }
        case XML_RELAXNG_REF:
        case XML_RELAXNG_EXTERNALREF:
        case XML_RELAXNG_PARENTREF:
        case XML_RELAXNG_GROUP:
        case XML_RELAXNG_DEF:
            list = def->content;
            while (list != NULL) {
                ret = xmlRelaxNGCompile(ctxt, list);
                if (ret != 0)
                    break;
                list = list->next;
            }
            break;
        case XML_RELAXNG_TEXT:{
                xmlAutomataStatePtr oldstate;

                ctxt->state =
                    xmlAutomataNewEpsilon(ctxt->am, ctxt->state, NULL);
                oldstate = ctxt->state;
                xmlRelaxNGCompile(ctxt, def->content);
                xmlAutomataNewTransition(ctxt->am, ctxt->state,
                                         ctxt->state, BAD_CAST "#text",
                                         NULL);
                ctxt->state =
                    xmlAutomataNewEpsilon(ctxt->am, oldstate, NULL);
                break;
            }
        case XML_RELAXNG_EMPTY:
            ctxt->state =
                xmlAutomataNewEpsilon(ctxt->am, ctxt->state, NULL);
            break;
        case XML_RELAXNG_EXCEPT:
        case XML_RELAXNG_ATTRIBUTE:
        case XML_RELAXNG_INTERLEAVE:
        case XML_RELAXNG_NOT_ALLOWED:
        case XML_RELAXNG_DATATYPE:
        case XML_RELAXNG_LIST:
        case XML_RELAXNG_PARAM:
        case XML_RELAXNG_VALUE:
            /* This should not happen and generate an internal error */
            fprintf(stderr, "RNG internal error trying to compile %s\n",
                    xmlRelaxNGDefName(def));
            break;
    }
    return (ret);
}

/**
 * xmlRelaxNGTryCompile:
 * ctxt:  the RelaxNG parser context
 * @define:  the definition tree to compile
 *
 * Try to compile the set of definitions, it works recursively,
 * possibly ignoring parts which cannot be compiled.
 *
 * Returns 0 if success and -1 in case of error
 */
static int
xmlRelaxNGTryCompile(xmlRelaxNGParserCtxtPtr ctxt, xmlRelaxNGDefinePtr def)
{
    int ret = 0;
    xmlRelaxNGDefinePtr list;

    if ((ctxt == NULL) || (def == NULL))
        return (-1);

    if ((def->type == XML_RELAXNG_START) ||
        (def->type == XML_RELAXNG_ELEMENT)) {
        ret = xmlRelaxNGIsCompileable(def);
        if ((def->dflags & IS_COMPILABLE) && (def->depth != -25)) {
            ctxt->am = NULL;
            ret = xmlRelaxNGCompile(ctxt, def);
#ifdef DEBUG_PROGRESSIVE
            if (ret == 0) {
                if (def->type == XML_RELAXNG_START)
                    xmlGenericError(xmlGenericErrorContext,
                                    "compiled the start\n");
                else
                    xmlGenericError(xmlGenericErrorContext,
                                    "compiled element %s\n", def->name);
            } else {
                if (def->type == XML_RELAXNG_START)
                    xmlGenericError(xmlGenericErrorContext,
                                    "failed to compile the start\n");
                else
                    xmlGenericError(xmlGenericErrorContext,
                                    "failed to compile element %s\n",
                                    def->name);
            }
#endif
            return (ret);
        }
    }
    switch (def->type) {
        case XML_RELAXNG_NOOP:
            ret = xmlRelaxNGTryCompile(ctxt, def->content);
            break;
        case XML_RELAXNG_TEXT:
        case XML_RELAXNG_DATATYPE:
        case XML_RELAXNG_LIST:
        case XML_RELAXNG_PARAM:
        case XML_RELAXNG_VALUE:
        case XML_RELAXNG_EMPTY:
        case XML_RELAXNG_ELEMENT:
            ret = 0;
            break;
        case XML_RELAXNG_OPTIONAL:
        case XML_RELAXNG_ZEROORMORE:
        case XML_RELAXNG_ONEORMORE:
        case XML_RELAXNG_CHOICE:
        case XML_RELAXNG_GROUP:
        case XML_RELAXNG_DEF:
        case XML_RELAXNG_START:
        case XML_RELAXNG_REF:
        case XML_RELAXNG_EXTERNALREF:
        case XML_RELAXNG_PARENTREF:
            list = def->content;
            while (list != NULL) {
                ret = xmlRelaxNGTryCompile(ctxt, list);
                if (ret != 0)
                    break;
                list = list->next;
            }
            break;
        case XML_RELAXNG_EXCEPT:
        case XML_RELAXNG_ATTRIBUTE:
        case XML_RELAXNG_INTERLEAVE:
        case XML_RELAXNG_NOT_ALLOWED:
            ret = 0;
            break;
    }
    return (ret);
}

/************************************************************************
 *									*
 *			Parsing functions				*
 *									*
 ************************************************************************/

static xmlRelaxNGDefinePtr xmlRelaxNGParseAttribute(xmlRelaxNGParserCtxtPtr
                                                    ctxt, xmlNodePtr node);
static xmlRelaxNGDefinePtr xmlRelaxNGParseElement(xmlRelaxNGParserCtxtPtr
                                                  ctxt, xmlNodePtr node);
static xmlRelaxNGDefinePtr xmlRelaxNGParsePatterns(xmlRelaxNGParserCtxtPtr
                                                   ctxt, xmlNodePtr nodes,
                                                   int group);
static xmlRelaxNGDefinePtr xmlRelaxNGParsePattern(xmlRelaxNGParserCtxtPtr
                                                  ctxt, xmlNodePtr node);
static xmlRelaxNGPtr xmlRelaxNGParseDocument(xmlRelaxNGParserCtxtPtr ctxt,
                                             xmlNodePtr node);
static int xmlRelaxNGParseGrammarContent(xmlRelaxNGParserCtxtPtr ctxt,
                                         xmlNodePtr nodes);
static xmlRelaxNGDefinePtr xmlRelaxNGParseNameClass(xmlRelaxNGParserCtxtPtr
                                                    ctxt, xmlNodePtr node,
                                                    xmlRelaxNGDefinePtr
                                                    def);
static xmlRelaxNGGrammarPtr xmlRelaxNGParseGrammar(xmlRelaxNGParserCtxtPtr
                                                   ctxt, xmlNodePtr nodes);
static int xmlRelaxNGElementMatch(xmlRelaxNGValidCtxtPtr ctxt,
                                  xmlRelaxNGDefinePtr define,
                                  xmlNodePtr elem);


#define IS_BLANK_NODE(n) (xmlRelaxNGIsBlank((n)->content))

/**
 * xmlRelaxNGIsNullable:
 * @define:  the definition to verify
 *
 * Check if a definition is nullable.
 *
 * Returns 1 if yes, 0 if no and -1 in case of error
 */
static int
xmlRelaxNGIsNullable(xmlRelaxNGDefinePtr define)
{
    int ret;

    if (define == NULL)
        return (-1);

    if (define->dflags & IS_NULLABLE)
        return (1);
    if (define->dflags & IS_NOT_NULLABLE)
        return (0);
    switch (define->type) {
        case XML_RELAXNG_EMPTY:
        case XML_RELAXNG_TEXT:
            ret = 1;
            break;
        case XML_RELAXNG_NOOP:
        case XML_RELAXNG_DEF:
        case XML_RELAXNG_REF:
        case XML_RELAXNG_EXTERNALREF:
        case XML_RELAXNG_PARENTREF:
        case XML_RELAXNG_ONEORMORE:
            ret = xmlRelaxNGIsNullable(define->content);
            break;
        case XML_RELAXNG_EXCEPT:
        case XML_RELAXNG_NOT_ALLOWED:
        case XML_RELAXNG_ELEMENT:
        case XML_RELAXNG_DATATYPE:
        case XML_RELAXNG_PARAM:
        case XML_RELAXNG_VALUE:
        case XML_RELAXNG_LIST:
        case XML_RELAXNG_ATTRIBUTE:
            ret = 0;
            break;
        case XML_RELAXNG_CHOICE:{
                xmlRelaxNGDefinePtr list = define->content;

                while (list != NULL) {
                    ret = xmlRelaxNGIsNullable(list);
                    if (ret != 0)
                        goto done;
                    list = list->next;
                }
                ret = 0;
                break;
            }
        case XML_RELAXNG_START:
        case XML_RELAXNG_INTERLEAVE:
        case XML_RELAXNG_GROUP:{
                xmlRelaxNGDefinePtr list = define->content;

                while (list != NULL) {
                    ret = xmlRelaxNGIsNullable(list);
                    if (ret != 1)
                        goto done;
                    list = list->next;
                }
                return (1);
            }
        default:
            return (-1);
    }
  done:
    if (ret == 0)
        define->dflags |= IS_NOT_NULLABLE;
    if (ret == 1)
        define->dflags |= IS_NULLABLE;
    return (ret);
}

/**
 * xmlRelaxNGIsBlank:
 * @str:  a string
 *
 * Check if a string is ignorable c.f. 4.2. Whitespace
 *
 * Returns 1 if the string is NULL or made of blanks chars, 0 otherwise
 */
static int
xmlRelaxNGIsBlank(xmlChar * str)
{
    if (str == NULL)
        return (1);
    while (*str != 0) {
        if (!(IS_BLANK_CH(*str)))
            return (0);
        str++;
    }
    return (1);
}

/**
 * xmlRelaxNGGetDataTypeLibrary:
 * @ctxt:  a Relax-NG parser context
 * @node:  the current data or value element
 *
 * Applies algorithm from 4.3. datatypeLibrary attribute
 *
 * Returns the datatypeLibary value or NULL if not found
 */
static xmlChar *
xmlRelaxNGGetDataTypeLibrary(xmlRelaxNGParserCtxtPtr ctxt ATTRIBUTE_UNUSED,
                             xmlNodePtr node)
{
    xmlChar *ret, *escape;

    if (node == NULL)
        return(NULL);

    if ((IS_RELAXNG(node, "data")) || (IS_RELAXNG(node, "value"))) {
        ret = xmlGetProp(node, BAD_CAST "datatypeLibrary");
        if (ret != NULL) {
            if (ret[0] == 0) {
                xmlFree(ret);
                return (NULL);
            }
            escape = xmlURIEscapeStr(ret, BAD_CAST ":/#?");
            if (escape == NULL) {
                return (ret);
            }
            xmlFree(ret);
            return (escape);
        }
    }
    node = node->parent;
    while ((node != NULL) && (node->type == XML_ELEMENT_NODE)) {
        ret = xmlGetProp(node, BAD_CAST "datatypeLibrary");
        if (ret != NULL) {
            if (ret[0] == 0) {
                xmlFree(ret);
                return (NULL);
            }
            escape = xmlURIEscapeStr(ret, BAD_CAST ":/#?");
            if (escape == NULL) {
                return (ret);
            }
            xmlFree(ret);
            return (escape);
        }
        node = node->parent;
    }
    return (NULL);
}

/**
 * xmlRelaxNGParseValue:
 * @ctxt:  a Relax-NG parser context
 * @node:  the data node.
 *
 * parse the content of a RelaxNG value node.
 *
 * Returns the definition pointer or NULL in case of error
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGParseValue(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGDefinePtr def = NULL;
    xmlRelaxNGTypeLibraryPtr lib = NULL;
    xmlChar *type;
    xmlChar *library;
    int success = 0;

    def = xmlRelaxNGNewDefine(ctxt, node);
    if (def == NULL)
        return (NULL);
    def->type = XML_RELAXNG_VALUE;

    type = xmlGetProp(node, BAD_CAST "type");
    if (type != NULL) {
        xmlRelaxNGNormExtSpace(type);
        if (xmlValidateNCName(type, 0)) {
            xmlRngPErr(ctxt, node, XML_RNGP_TYPE_VALUE,
                       "value type '%s' is not an NCName\n", type, NULL);
        }
        library = xmlRelaxNGGetDataTypeLibrary(ctxt, node);
        if (library == NULL)
            library =
                xmlStrdup(BAD_CAST "http://relaxng.org/ns/structure/1.0");

        def->name = type;
        def->ns = library;

        lib = (xmlRelaxNGTypeLibraryPtr)
            xmlHashLookup(xmlRelaxNGRegisteredTypes, library);
        if (lib == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_UNKNOWN_TYPE_LIB,
                       "Use of unregistered type library '%s'\n", library,
                       NULL);
            def->data = NULL;
        } else {
            def->data = lib;
            if (lib->have == NULL) {
                xmlRngPErr(ctxt, node, XML_RNGP_ERROR_TYPE_LIB,
                           "Internal error with type library '%s': no 'have'\n",
                           library, NULL);
            } else {
                success = lib->have(lib->data, def->name);
                if (success != 1) {
                    xmlRngPErr(ctxt, node, XML_RNGP_TYPE_NOT_FOUND,
                               "Error type '%s' is not exported by type library '%s'\n",
                               def->name, library);
                }
            }
        }
    }
    if (node->children == NULL) {
        def->value = xmlStrdup(BAD_CAST "");
    } else if (((node->children->type != XML_TEXT_NODE) &&
                (node->children->type != XML_CDATA_SECTION_NODE)) ||
               (node->children->next != NULL)) {
        xmlRngPErr(ctxt, node, XML_RNGP_TEXT_EXPECTED,
                   "Expecting a single text value for <value>content\n",
                   NULL, NULL);
    } else if (def != NULL) {
        def->value = xmlNodeGetContent(node);
        if (def->value == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_VALUE_NO_CONTENT,
                       "Element <value> has no content\n", NULL, NULL);
        } else if ((lib != NULL) && (lib->check != NULL) && (success == 1)) {
            void *val = NULL;

            success =
                lib->check(lib->data, def->name, def->value, &val, node);
            if (success != 1) {
                xmlRngPErr(ctxt, node, XML_RNGP_INVALID_VALUE,
                           "Value '%s' is not acceptable for type '%s'\n",
                           def->value, def->name);
            } else {
                if (val != NULL)
                    def->attrs = val;
            }
        }
    }
    return (def);
}

/**
 * xmlRelaxNGParseData:
 * @ctxt:  a Relax-NG parser context
 * @node:  the data node.
 *
 * parse the content of a RelaxNG data node.
 *
 * Returns the definition pointer or NULL in case of error
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGParseData(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGDefinePtr def = NULL, except;
    xmlRelaxNGDefinePtr param, lastparam = NULL;
    xmlRelaxNGTypeLibraryPtr lib;
    xmlChar *type;
    xmlChar *library;
    xmlNodePtr content;
    int tmp;

    type = xmlGetProp(node, BAD_CAST "type");
    if (type == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_TYPE_MISSING, "data has no type\n", NULL,
                   NULL);
        return (NULL);
    }
    xmlRelaxNGNormExtSpace(type);
    if (xmlValidateNCName(type, 0)) {
        xmlRngPErr(ctxt, node, XML_RNGP_TYPE_VALUE,
                   "data type '%s' is not an NCName\n", type, NULL);
    }
    library = xmlRelaxNGGetDataTypeLibrary(ctxt, node);
    if (library == NULL)
        library =
            xmlStrdup(BAD_CAST "http://relaxng.org/ns/structure/1.0");

    def = xmlRelaxNGNewDefine(ctxt, node);
    if (def == NULL) {
        xmlFree(type);
        return (NULL);
    }
    def->type = XML_RELAXNG_DATATYPE;
    def->name = type;
    def->ns = library;

    lib = (xmlRelaxNGTypeLibraryPtr)
        xmlHashLookup(xmlRelaxNGRegisteredTypes, library);
    if (lib == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_UNKNOWN_TYPE_LIB,
                   "Use of unregistered type library '%s'\n", library,
                   NULL);
        def->data = NULL;
    } else {
        def->data = lib;
        if (lib->have == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_ERROR_TYPE_LIB,
                       "Internal error with type library '%s': no 'have'\n",
                       library, NULL);
        } else {
            tmp = lib->have(lib->data, def->name);
            if (tmp != 1) {
                xmlRngPErr(ctxt, node, XML_RNGP_TYPE_NOT_FOUND,
                           "Error type '%s' is not exported by type library '%s'\n",
                           def->name, library);
            } else
                if ((xmlStrEqual
                     (library,
                      BAD_CAST
                      "http://www.w3.org/2001/XMLSchema-datatypes"))
                    && ((xmlStrEqual(def->name, BAD_CAST "IDREF"))
                        || (xmlStrEqual(def->name, BAD_CAST "IDREFS")))) {
                ctxt->idref = 1;
            }
        }
    }
    content = node->children;

    /*
     * Handle optional params
     */
    while (content != NULL) {
        if (!xmlStrEqual(content->name, BAD_CAST "param"))
            break;
        if (xmlStrEqual(library,
                        BAD_CAST "http://relaxng.org/ns/structure/1.0")) {
            xmlRngPErr(ctxt, node, XML_RNGP_PARAM_FORBIDDEN,
                       "Type library '%s' does not allow type parameters\n",
                       library, NULL);
            content = content->next;
            while ((content != NULL) &&
                   (xmlStrEqual(content->name, BAD_CAST "param")))
                content = content->next;
        } else {
            param = xmlRelaxNGNewDefine(ctxt, node);
            if (param != NULL) {
                param->type = XML_RELAXNG_PARAM;
                param->name = xmlGetProp(content, BAD_CAST "name");
                if (param->name == NULL) {
                    xmlRngPErr(ctxt, node, XML_RNGP_PARAM_NAME_MISSING,
                               "param has no name\n", NULL, NULL);
                }
                param->value = xmlNodeGetContent(content);
                if (lastparam == NULL) {
                    def->attrs = lastparam = param;
                } else {
                    lastparam->next = param;
                    lastparam = param;
                }
                if (lib != NULL) {
                }
            }
            content = content->next;
        }
    }
    /*
     * Handle optional except
     */
    if ((content != NULL)
        && (xmlStrEqual(content->name, BAD_CAST "except"))) {
        xmlNodePtr child;
        xmlRelaxNGDefinePtr tmp2, last = NULL;

        except = xmlRelaxNGNewDefine(ctxt, node);
        if (except == NULL) {
            return (def);
        }
        except->type = XML_RELAXNG_EXCEPT;
        child = content->children;
	def->content = except;
        if (child == NULL) {
            xmlRngPErr(ctxt, content, XML_RNGP_EXCEPT_NO_CONTENT,
                       "except has no content\n", NULL, NULL);
        }
        while (child != NULL) {
            tmp2 = xmlRelaxNGParsePattern(ctxt, child);
            if (tmp2 != NULL) {
                if (last == NULL) {
                    except->content = last = tmp2;
                } else {
                    last->next = tmp2;
                    last = tmp2;
                }
            }
            child = child->next;
        }
        content = content->next;
    }
    /*
     * Check there is no unhandled data
     */
    if (content != NULL) {
        xmlRngPErr(ctxt, content, XML_RNGP_DATA_CONTENT,
                   "Element data has unexpected content %s\n",
                   content->name, NULL);
    }

    return (def);
}

static const xmlChar *invalidName = BAD_CAST "\1";

/**
 * xmlRelaxNGCompareNameClasses:
 * @defs1:  the first element/attribute defs
 * @defs2:  the second element/attribute defs
 * @name:  the restriction on the name
 * @ns:  the restriction on the namespace
 *
 * Compare the 2 lists of element definitions. The comparison is
 * that if both lists do not accept the same QNames, it returns 1
 * If the 2 lists can accept the same QName the comparison returns 0
 *
 * Returns 1 disttinct, 0 if equal
 */
static int
xmlRelaxNGCompareNameClasses(xmlRelaxNGDefinePtr def1,
                             xmlRelaxNGDefinePtr def2)
{
    int ret = 1;
    xmlNode node;
    xmlNs ns;
    xmlRelaxNGValidCtxt ctxt;

    memset(&ctxt, 0, sizeof(xmlRelaxNGValidCtxt));

    ctxt.flags = FLAGS_IGNORABLE | FLAGS_NOERROR;

    if ((def1->type == XML_RELAXNG_ELEMENT) ||
        (def1->type == XML_RELAXNG_ATTRIBUTE)) {
        if (def2->type == XML_RELAXNG_TEXT)
            return (1);
        if (def1->name != NULL) {
            node.name = def1->name;
        } else {
            node.name = invalidName;
        }
        if (def1->ns != NULL) {
            if (def1->ns[0] == 0) {
                node.ns = NULL;
            } else {
	        node.ns = &ns;
                ns.href = def1->ns;
            }
        } else {
            node.ns = NULL;
        }
        if (xmlRelaxNGElementMatch(&ctxt, def2, &node)) {
            if (def1->nameClass != NULL) {
                ret = xmlRelaxNGCompareNameClasses(def1->nameClass, def2);
            } else {
                ret = 0;
            }
        } else {
            ret = 1;
        }
    } else if (def1->type == XML_RELAXNG_TEXT) {
        if (def2->type == XML_RELAXNG_TEXT)
            return (0);
        return (1);
    } else if (def1->type == XML_RELAXNG_EXCEPT) {
        TODO ret = 0;
    } else {
        TODO ret = 0;
    }
    if (ret == 0)
        return (ret);
    if ((def2->type == XML_RELAXNG_ELEMENT) ||
        (def2->type == XML_RELAXNG_ATTRIBUTE)) {
        if (def2->name != NULL) {
            node.name = def2->name;
        } else {
            node.name = invalidName;
        }
        node.ns = &ns;
        if (def2->ns != NULL) {
            if (def2->ns[0] == 0) {
                node.ns = NULL;
            } else {
                ns.href = def2->ns;
            }
        } else {
            ns.href = invalidName;
        }
        if (xmlRelaxNGElementMatch(&ctxt, def1, &node)) {
            if (def2->nameClass != NULL) {
                ret = xmlRelaxNGCompareNameClasses(def2->nameClass, def1);
            } else {
                ret = 0;
            }
        } else {
            ret = 1;
        }
    } else {
        TODO ret = 0;
    }

    return (ret);
}

/**
 * xmlRelaxNGCompareElemDefLists:
 * @ctxt:  a Relax-NG parser context
 * @defs1:  the first list of element/attribute defs
 * @defs2:  the second list of element/attribute defs
 *
 * Compare the 2 lists of element or attribute definitions. The comparison
 * is that if both lists do not accept the same QNames, it returns 1
 * If the 2 lists can accept the same QName the comparison returns 0
 *
 * Returns 1 disttinct, 0 if equal
 */
static int
xmlRelaxNGCompareElemDefLists(xmlRelaxNGParserCtxtPtr ctxt
                              ATTRIBUTE_UNUSED, xmlRelaxNGDefinePtr * def1,
                              xmlRelaxNGDefinePtr * def2)
{
    xmlRelaxNGDefinePtr *basedef2 = def2;

    if ((def1 == NULL) || (def2 == NULL))
        return (1);
    if ((*def1 == NULL) || (*def2 == NULL))
        return (1);
    while (*def1 != NULL) {
        while ((*def2) != NULL) {
            if (xmlRelaxNGCompareNameClasses(*def1, *def2) == 0)
                return (0);
            def2++;
        }
        def2 = basedef2;
        def1++;
    }
    return (1);
}

/**
 * xmlRelaxNGGenerateAttributes:
 * @ctxt:  a Relax-NG parser context
 * @def:  the definition definition
 *
 * Check if the definition can only generate attributes
 *
 * Returns 1 if yes, 0 if no and -1 in case of error.
 */
static int
xmlRelaxNGGenerateAttributes(xmlRelaxNGParserCtxtPtr ctxt,
                             xmlRelaxNGDefinePtr def)
{
    xmlRelaxNGDefinePtr parent, cur, tmp;

    /*
     * Don't run that check in case of error. Infinite recursion
     * becomes possible.
     */
    if (ctxt->nbErrors != 0)
        return (-1);

    parent = NULL;
    cur = def;
    while (cur != NULL) {
        if ((cur->type == XML_RELAXNG_ELEMENT) ||
            (cur->type == XML_RELAXNG_TEXT) ||
            (cur->type == XML_RELAXNG_DATATYPE) ||
            (cur->type == XML_RELAXNG_PARAM) ||
            (cur->type == XML_RELAXNG_LIST) ||
            (cur->type == XML_RELAXNG_VALUE) ||
            (cur->type == XML_RELAXNG_EMPTY))
            return (0);
        if ((cur->type == XML_RELAXNG_CHOICE) ||
            (cur->type == XML_RELAXNG_INTERLEAVE) ||
            (cur->type == XML_RELAXNG_GROUP) ||
            (cur->type == XML_RELAXNG_ONEORMORE) ||
            (cur->type == XML_RELAXNG_ZEROORMORE) ||
            (cur->type == XML_RELAXNG_OPTIONAL) ||
            (cur->type == XML_RELAXNG_PARENTREF) ||
            (cur->type == XML_RELAXNG_EXTERNALREF) ||
            (cur->type == XML_RELAXNG_REF) ||
            (cur->type == XML_RELAXNG_DEF)) {
            if (cur->content != NULL) {
                parent = cur;
                cur = cur->content;
                tmp = cur;
                while (tmp != NULL) {
                    tmp->parent = parent;
                    tmp = tmp->next;
                }
                continue;
            }
        }
        if (cur == def)
            break;
        if (cur->next != NULL) {
            cur = cur->next;
            continue;
        }
        do {
            cur = cur->parent;
            if (cur == NULL)
                break;
            if (cur == def)
                return (1);
            if (cur->next != NULL) {
                cur = cur->next;
                break;
            }
        } while (cur != NULL);
    }
    return (1);
}

/**
 * xmlRelaxNGGetElements:
 * @ctxt:  a Relax-NG parser context
 * @def:  the definition definition
 * @eora:  gather elements (0) or attributes (1)
 *
 * Compute the list of top elements a definition can generate
 *
 * Returns a list of elements or NULL if none was found.
 */
static xmlRelaxNGDefinePtr *
xmlRelaxNGGetElements(xmlRelaxNGParserCtxtPtr ctxt,
                      xmlRelaxNGDefinePtr def, int eora)
{
    xmlRelaxNGDefinePtr *ret = NULL, parent, cur, tmp;
    int len = 0;
    int max = 0;

    /*
     * Don't run that check in case of error. Infinite recursion
     * becomes possible.
     */
    if (ctxt->nbErrors != 0)
        return (NULL);

    parent = NULL;
    cur = def;
    while (cur != NULL) {
        if (((eora == 0) && ((cur->type == XML_RELAXNG_ELEMENT) ||
                             (cur->type == XML_RELAXNG_TEXT))) ||
            ((eora == 1) && (cur->type == XML_RELAXNG_ATTRIBUTE))) {
            if (ret == NULL) {
                max = 10;
                ret = (xmlRelaxNGDefinePtr *)
                    xmlMalloc((max + 1) * sizeof(xmlRelaxNGDefinePtr));
                if (ret == NULL) {
                    xmlRngPErrMemory(ctxt, "getting element list\n");
                    return (NULL);
                }
            } else if (max <= len) {
	        xmlRelaxNGDefinePtr *temp;

                max *= 2;
                temp = xmlRealloc(ret,
                               (max + 1) * sizeof(xmlRelaxNGDefinePtr));
                if (temp == NULL) {
                    xmlRngPErrMemory(ctxt, "getting element list\n");
		    xmlFree(ret);
                    return (NULL);
                }
		ret = temp;
            }
            ret[len++] = cur;
            ret[len] = NULL;
        } else if ((cur->type == XML_RELAXNG_CHOICE) ||
                   (cur->type == XML_RELAXNG_INTERLEAVE) ||
                   (cur->type == XML_RELAXNG_GROUP) ||
                   (cur->type == XML_RELAXNG_ONEORMORE) ||
                   (cur->type == XML_RELAXNG_ZEROORMORE) ||
                   (cur->type == XML_RELAXNG_OPTIONAL) ||
                   (cur->type == XML_RELAXNG_PARENTREF) ||
                   (cur->type == XML_RELAXNG_REF) ||
                   (cur->type == XML_RELAXNG_DEF) ||
		   (cur->type == XML_RELAXNG_EXTERNALREF)) {
            /*
             * Don't go within elements or attributes or string values.
             * Just gather the element top list
             */
            if (cur->content != NULL) {
                parent = cur;
                cur = cur->content;
                tmp = cur;
                while (tmp != NULL) {
                    tmp->parent = parent;
                    tmp = tmp->next;
                }
                continue;
            }
        }
        if (cur == def)
            break;
        if (cur->next != NULL) {
            cur = cur->next;
            continue;
        }
        do {
            cur = cur->parent;
            if (cur == NULL)
                break;
            if (cur == def)
                return (ret);
            if (cur->next != NULL) {
                cur = cur->next;
                break;
            }
        } while (cur != NULL);
    }
    return (ret);
}

/**
 * xmlRelaxNGCheckChoiceDeterminism:
 * @ctxt:  a Relax-NG parser context
 * @def:  the choice definition
 *
 * Also used to find indeterministic pattern in choice
 */
static void
xmlRelaxNGCheckChoiceDeterminism(xmlRelaxNGParserCtxtPtr ctxt,
                                 xmlRelaxNGDefinePtr def)
{
    xmlRelaxNGDefinePtr **list;
    xmlRelaxNGDefinePtr cur;
    int nbchild = 0, i, j, ret;
    int is_nullable = 0;
    int is_indeterminist = 0;
    xmlHashTablePtr triage = NULL;
    int is_triable = 1;

    if ((def == NULL) || (def->type != XML_RELAXNG_CHOICE))
        return;

    if (def->dflags & IS_PROCESSED)
        return;

    /*
     * Don't run that check in case of error. Infinite recursion
     * becomes possible.
     */
    if (ctxt->nbErrors != 0)
        return;

    is_nullable = xmlRelaxNGIsNullable(def);

    cur = def->content;
    while (cur != NULL) {
        nbchild++;
        cur = cur->next;
    }

    list = (xmlRelaxNGDefinePtr **) xmlMalloc(nbchild *
                                              sizeof(xmlRelaxNGDefinePtr
                                                     *));
    if (list == NULL) {
        xmlRngPErrMemory(ctxt, "building choice\n");
        return;
    }
    i = 0;
    /*
     * a bit strong but safe
     */
    if (is_nullable == 0) {
        triage = xmlHashCreate(10);
    } else {
        is_triable = 0;
    }
    cur = def->content;
    while (cur != NULL) {
        list[i] = xmlRelaxNGGetElements(ctxt, cur, 0);
        if ((list[i] == NULL) || (list[i][0] == NULL)) {
            is_triable = 0;
        } else if (is_triable == 1) {
            xmlRelaxNGDefinePtr *tmp;
            int res;

            tmp = list[i];
            while ((*tmp != NULL) && (is_triable == 1)) {
                if ((*tmp)->type == XML_RELAXNG_TEXT) {
                    res = xmlHashAddEntry2(triage,
                                           BAD_CAST "#text", NULL,
                                           (void *) cur);
                    if (res != 0)
                        is_triable = -1;
                } else if (((*tmp)->type == XML_RELAXNG_ELEMENT) &&
                           ((*tmp)->name != NULL)) {
                    if (((*tmp)->ns == NULL) || ((*tmp)->ns[0] == 0))
                        res = xmlHashAddEntry2(triage,
                                               (*tmp)->name, NULL,
                                               (void *) cur);
                    else
                        res = xmlHashAddEntry2(triage,
                                               (*tmp)->name, (*tmp)->ns,
                                               (void *) cur);
                    if (res != 0)
                        is_triable = -1;
                } else if ((*tmp)->type == XML_RELAXNG_ELEMENT) {
                    if (((*tmp)->ns == NULL) || ((*tmp)->ns[0] == 0))
                        res = xmlHashAddEntry2(triage,
                                               BAD_CAST "#any", NULL,
                                               (void *) cur);
                    else
                        res = xmlHashAddEntry2(triage,
                                               BAD_CAST "#any", (*tmp)->ns,
                                               (void *) cur);
                    if (res != 0)
                        is_triable = -1;
                } else {
                    is_triable = -1;
                }
                tmp++;
            }
        }
        i++;
        cur = cur->next;
    }

    for (i = 0; i < nbchild; i++) {
        if (list[i] == NULL)
            continue;
        for (j = 0; j < i; j++) {
            if (list[j] == NULL)
                continue;
            ret = xmlRelaxNGCompareElemDefLists(ctxt, list[i], list[j]);
            if (ret == 0) {
                is_indeterminist = 1;
            }
        }
    }
    for (i = 0; i < nbchild; i++) {
        if (list[i] != NULL)
            xmlFree(list[i]);
    }

    xmlFree(list);
    if (is_indeterminist) {
        def->dflags |= IS_INDETERMINIST;
    }
    if (is_triable == 1) {
        def->dflags |= IS_TRIABLE;
        def->data = triage;
    } else if (triage != NULL) {
        xmlHashFree(triage, NULL);
    }
    def->dflags |= IS_PROCESSED;
}

/**
 * xmlRelaxNGCheckGroupAttrs:
 * @ctxt:  a Relax-NG parser context
 * @def:  the group definition
 *
 * Detects violations of rule 7.3
 */
static void
xmlRelaxNGCheckGroupAttrs(xmlRelaxNGParserCtxtPtr ctxt,
                          xmlRelaxNGDefinePtr def)
{
    xmlRelaxNGDefinePtr **list;
    xmlRelaxNGDefinePtr cur;
    int nbchild = 0, i, j, ret;

    if ((def == NULL) ||
        ((def->type != XML_RELAXNG_GROUP) &&
         (def->type != XML_RELAXNG_ELEMENT)))
        return;

    if (def->dflags & IS_PROCESSED)
        return;

    /*
     * Don't run that check in case of error. Infinite recursion
     * becomes possible.
     */
    if (ctxt->nbErrors != 0)
        return;

    cur = def->attrs;
    while (cur != NULL) {
        nbchild++;
        cur = cur->next;
    }
    cur = def->content;
    while (cur != NULL) {
        nbchild++;
        cur = cur->next;
    }

    list = (xmlRelaxNGDefinePtr **) xmlMalloc(nbchild *
                                              sizeof(xmlRelaxNGDefinePtr
                                                     *));
    if (list == NULL) {
        xmlRngPErrMemory(ctxt, "building group\n");
        return;
    }
    i = 0;
    cur = def->attrs;
    while (cur != NULL) {
        list[i] = xmlRelaxNGGetElements(ctxt, cur, 1);
        i++;
        cur = cur->next;
    }
    cur = def->content;
    while (cur != NULL) {
        list[i] = xmlRelaxNGGetElements(ctxt, cur, 1);
        i++;
        cur = cur->next;
    }

    for (i = 0; i < nbchild; i++) {
        if (list[i] == NULL)
            continue;
        for (j = 0; j < i; j++) {
            if (list[j] == NULL)
                continue;
            ret = xmlRelaxNGCompareElemDefLists(ctxt, list[i], list[j]);
            if (ret == 0) {
                xmlRngPErr(ctxt, def->node, XML_RNGP_GROUP_ATTR_CONFLICT,
                           "Attributes conflicts in group\n", NULL, NULL);
            }
        }
    }
    for (i = 0; i < nbchild; i++) {
        if (list[i] != NULL)
            xmlFree(list[i]);
    }

    xmlFree(list);
    def->dflags |= IS_PROCESSED;
}

/**
 * xmlRelaxNGComputeInterleaves:
 * @def:  the interleave definition
 * @ctxt:  a Relax-NG parser context
 * @name:  the definition name
 *
 * A lot of work for preprocessing interleave definitions
 * is potentially needed to get a decent execution speed at runtime
 *   - trying to get a total order on the element nodes generated
 *     by the interleaves, order the list of interleave definitions
 *     following that order.
 *   - if <text/> is used to handle mixed content, it is better to
 *     flag this in the define and simplify the runtime checking
 *     algorithm
 */
static void
xmlRelaxNGComputeInterleaves(xmlRelaxNGDefinePtr def,
                             xmlRelaxNGParserCtxtPtr ctxt,
                             xmlChar * name ATTRIBUTE_UNUSED)
{
    xmlRelaxNGDefinePtr cur, *tmp;

    xmlRelaxNGPartitionPtr partitions = NULL;
    xmlRelaxNGInterleaveGroupPtr *groups = NULL;
    xmlRelaxNGInterleaveGroupPtr group;
    int i, j, ret, res;
    int nbgroups = 0;
    int nbchild = 0;
    int is_mixed = 0;
    int is_determinist = 1;

    /*
     * Don't run that check in case of error. Infinite recursion
     * becomes possible.
     */
    if (ctxt->nbErrors != 0)
        return;

#ifdef DEBUG_INTERLEAVE
    xmlGenericError(xmlGenericErrorContext,
                    "xmlRelaxNGComputeInterleaves(%s)\n", name);
#endif
    cur = def->content;
    while (cur != NULL) {
        nbchild++;
        cur = cur->next;
    }

#ifdef DEBUG_INTERLEAVE
    xmlGenericError(xmlGenericErrorContext, "  %d child\n", nbchild);
#endif
    groups = (xmlRelaxNGInterleaveGroupPtr *)
        xmlMalloc(nbchild * sizeof(xmlRelaxNGInterleaveGroupPtr));
    if (groups == NULL)
        goto error;
    cur = def->content;
    while (cur != NULL) {
        groups[nbgroups] = (xmlRelaxNGInterleaveGroupPtr)
            xmlMalloc(sizeof(xmlRelaxNGInterleaveGroup));
        if (groups[nbgroups] == NULL)
            goto error;
        if (cur->type == XML_RELAXNG_TEXT)
            is_mixed++;
        groups[nbgroups]->rule = cur;
        groups[nbgroups]->defs = xmlRelaxNGGetElements(ctxt, cur, 0);
        groups[nbgroups]->attrs = xmlRelaxNGGetElements(ctxt, cur, 1);
        nbgroups++;
        cur = cur->next;
    }
#ifdef DEBUG_INTERLEAVE
    xmlGenericError(xmlGenericErrorContext, "  %d groups\n", nbgroups);
#endif

    /*
     * Let's check that all rules makes a partitions according to 7.4
     */
    partitions = (xmlRelaxNGPartitionPtr)
        xmlMalloc(sizeof(xmlRelaxNGPartition));
    if (partitions == NULL)
        goto error;
    memset(partitions, 0, sizeof(xmlRelaxNGPartition));
    partitions->nbgroups = nbgroups;
    partitions->triage = xmlHashCreate(nbgroups);
    for (i = 0; i < nbgroups; i++) {
        group = groups[i];
        for (j = i + 1; j < nbgroups; j++) {
            if (groups[j] == NULL)
                continue;

            ret = xmlRelaxNGCompareElemDefLists(ctxt, group->defs,
                                                groups[j]->defs);
            if (ret == 0) {
                xmlRngPErr(ctxt, def->node, XML_RNGP_ELEM_TEXT_CONFLICT,
                           "Element or text conflicts in interleave\n",
                           NULL, NULL);
            }
            ret = xmlRelaxNGCompareElemDefLists(ctxt, group->attrs,
                                                groups[j]->attrs);
            if (ret == 0) {
                xmlRngPErr(ctxt, def->node, XML_RNGP_ATTR_CONFLICT,
                           "Attributes conflicts in interleave\n", NULL,
                           NULL);
            }
        }
        tmp = group->defs;
        if ((tmp != NULL) && (*tmp != NULL)) {
            while (*tmp != NULL) {
                if ((*tmp)->type == XML_RELAXNG_TEXT) {
                    res = xmlHashAddEntry2(partitions->triage,
                                           BAD_CAST "#text", NULL,
                                           (void *) (long) (i + 1));
                    if (res != 0)
                        is_determinist = -1;
                } else if (((*tmp)->type == XML_RELAXNG_ELEMENT) &&
                           ((*tmp)->name != NULL)) {
                    if (((*tmp)->ns == NULL) || ((*tmp)->ns[0] == 0))
                        res = xmlHashAddEntry2(partitions->triage,
                                               (*tmp)->name, NULL,
                                               (void *) (long) (i + 1));
                    else
                        res = xmlHashAddEntry2(partitions->triage,
                                               (*tmp)->name, (*tmp)->ns,
                                               (void *) (long) (i + 1));
                    if (res != 0)
                        is_determinist = -1;
                } else if ((*tmp)->type == XML_RELAXNG_ELEMENT) {
                    if (((*tmp)->ns == NULL) || ((*tmp)->ns[0] == 0))
                        res = xmlHashAddEntry2(partitions->triage,
                                               BAD_CAST "#any", NULL,
                                               (void *) (long) (i + 1));
                    else
                        res = xmlHashAddEntry2(partitions->triage,
                                               BAD_CAST "#any", (*tmp)->ns,
                                               (void *) (long) (i + 1));
                    if ((*tmp)->nameClass != NULL)
                        is_determinist = 2;
                    if (res != 0)
                        is_determinist = -1;
                } else {
                    is_determinist = -1;
                }
                tmp++;
            }
        } else {
            is_determinist = 0;
        }
    }
    partitions->groups = groups;

    /*
     * and save the partition list back in the def
     */
    def->data = partitions;
    if (is_mixed != 0)
        def->dflags |= IS_MIXED;
    if (is_determinist == 1)
        partitions->flags = IS_DETERMINIST;
    if (is_determinist == 2)
        partitions->flags = IS_DETERMINIST | IS_NEEDCHECK;
    return;

  error:
    xmlRngPErrMemory(ctxt, "in interleave computation\n");
    if (groups != NULL) {
        for (i = 0; i < nbgroups; i++)
            if (groups[i] != NULL) {
                if (groups[i]->defs != NULL)
                    xmlFree(groups[i]->defs);
                xmlFree(groups[i]);
            }
        xmlFree(groups);
    }
    xmlRelaxNGFreePartition(partitions);
}

/**
 * xmlRelaxNGParseInterleave:
 * @ctxt:  a Relax-NG parser context
 * @node:  the data node.
 *
 * parse the content of a RelaxNG interleave node.
 *
 * Returns the definition pointer or NULL in case of error
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGParseInterleave(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGDefinePtr def = NULL;
    xmlRelaxNGDefinePtr last = NULL, cur;
    xmlNodePtr child;

    def = xmlRelaxNGNewDefine(ctxt, node);
    if (def == NULL) {
        return (NULL);
    }
    def->type = XML_RELAXNG_INTERLEAVE;

    if (ctxt->interleaves == NULL)
        ctxt->interleaves = xmlHashCreate(10);
    if (ctxt->interleaves == NULL) {
        xmlRngPErrMemory(ctxt, "create interleaves\n");
    } else {
        char name[32];

        snprintf(name, 32, "interleave%d", ctxt->nbInterleaves++);
        if (xmlHashAddEntry(ctxt->interleaves, BAD_CAST name, def) < 0) {
            xmlRngPErr(ctxt, node, XML_RNGP_INTERLEAVE_ADD,
                       "Failed to add %s to hash table\n",
		       (const xmlChar *) name, NULL);
        }
    }
    child = node->children;
    if (child == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_INTERLEAVE_NO_CONTENT,
                   "Element interleave is empty\n", NULL, NULL);
    }
    while (child != NULL) {
        if (IS_RELAXNG(child, "element")) {
            cur = xmlRelaxNGParseElement(ctxt, child);
        } else {
            cur = xmlRelaxNGParsePattern(ctxt, child);
        }
        if (cur != NULL) {
            cur->parent = def;
            if (last == NULL) {
                def->content = last = cur;
            } else {
                last->next = cur;
                last = cur;
            }
        }
        child = child->next;
    }

    return (def);
}

/**
 * xmlRelaxNGParseInclude:
 * @ctxt:  a Relax-NG parser context
 * @node:  the include node
 *
 * Integrate the content of an include node in the current grammar
 *
 * Returns 0 in case of success or -1 in case of error
 */
static int
xmlRelaxNGParseInclude(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGIncludePtr incl;
    xmlNodePtr root;
    int ret = 0, tmp;

    incl = node->psvi;
    if (incl == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_INCLUDE_EMPTY,
                   "Include node has no data\n", NULL, NULL);
        return (-1);
    }
    root = xmlDocGetRootElement(incl->doc);
    if (root == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_EMPTY, "Include document is empty\n",
                   NULL, NULL);
        return (-1);
    }
    if (!xmlStrEqual(root->name, BAD_CAST "grammar")) {
        xmlRngPErr(ctxt, node, XML_RNGP_GRAMMAR_MISSING,
                   "Include document root is not a grammar\n", NULL, NULL);
        return (-1);
    }

    /*
     * Merge the definition from both the include and the internal list
     */
    if (root->children != NULL) {
        tmp = xmlRelaxNGParseGrammarContent(ctxt, root->children);
        if (tmp != 0)
            ret = -1;
    }
    if (node->children != NULL) {
        tmp = xmlRelaxNGParseGrammarContent(ctxt, node->children);
        if (tmp != 0)
            ret = -1;
    }
    return (ret);
}

/**
 * xmlRelaxNGParseDefine:
 * @ctxt:  a Relax-NG parser context
 * @node:  the define node
 *
 * parse the content of a RelaxNG define element node.
 *
 * Returns 0 in case of success or -1 in case of error
 */
static int
xmlRelaxNGParseDefine(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlChar *name;
    int ret = 0, tmp;
    xmlRelaxNGDefinePtr def;
    const xmlChar *olddefine;

    name = xmlGetProp(node, BAD_CAST "name");
    if (name == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_DEFINE_NAME_MISSING,
                   "define has no name\n", NULL, NULL);
    } else {
        xmlRelaxNGNormExtSpace(name);
        if (xmlValidateNCName(name, 0)) {
            xmlRngPErr(ctxt, node, XML_RNGP_INVALID_DEFINE_NAME,
                       "define name '%s' is not an NCName\n", name, NULL);
        }
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL) {
            xmlFree(name);
            return (-1);
        }
        def->type = XML_RELAXNG_DEF;
        def->name = name;
        if (node->children == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_DEFINE_EMPTY,
                       "define has no children\n", NULL, NULL);
        } else {
            olddefine = ctxt->define;
            ctxt->define = name;
            def->content =
                xmlRelaxNGParsePatterns(ctxt, node->children, 0);
            ctxt->define = olddefine;
        }
        if (ctxt->grammar->defs == NULL)
            ctxt->grammar->defs = xmlHashCreate(10);
        if (ctxt->grammar->defs == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_DEFINE_CREATE_FAILED,
                       "Could not create definition hash\n", NULL, NULL);
            ret = -1;
        } else {
            tmp = xmlHashAddEntry(ctxt->grammar->defs, name, def);
            if (tmp < 0) {
                xmlRelaxNGDefinePtr prev;

                prev = xmlHashLookup(ctxt->grammar->defs, name);
                if (prev == NULL) {
                    xmlRngPErr(ctxt, node, XML_RNGP_DEFINE_CREATE_FAILED,
                               "Internal error on define aggregation of %s\n",
                               name, NULL);
                    ret = -1;
                } else {
                    while (prev->nextHash != NULL)
                        prev = prev->nextHash;
                    prev->nextHash = def;
                }
            }
        }
    }
    return (ret);
}

/**
 * xmlRelaxNGParseImportRef:
 * @payload: the parser context
 * @data: the current grammar
 * @name: the reference name
 *
 * Import import one references into the current grammar
 */
static void
xmlRelaxNGParseImportRef(void *payload, void *data, xmlChar *name) {
    xmlRelaxNGParserCtxtPtr ctxt = (xmlRelaxNGParserCtxtPtr) data;
    xmlRelaxNGDefinePtr def = (xmlRelaxNGDefinePtr) payload;
    int tmp;

    def->dflags |= IS_EXTERNAL_REF;

    tmp = xmlHashAddEntry(ctxt->grammar->refs, name, def);
    if (tmp < 0) {
        xmlRelaxNGDefinePtr prev;

        prev = (xmlRelaxNGDefinePtr)
            xmlHashLookup(ctxt->grammar->refs, def->name);
        if (prev == NULL) {
            if (def->name != NULL) {
                xmlRngPErr(ctxt, NULL, XML_RNGP_REF_CREATE_FAILED,
                           "Error refs definitions '%s'\n",
                           def->name, NULL);
            } else {
                xmlRngPErr(ctxt, NULL, XML_RNGP_REF_CREATE_FAILED,
                           "Error refs definitions\n",
                           NULL, NULL);
            }
        } else {
            def->nextHash = prev->nextHash;
            prev->nextHash = def;
        }
    }
}

/**
 * xmlRelaxNGParseImportRefs:
 * @ctxt: the parser context
 * @grammar: the sub grammar
 *
 * Import references from the subgrammar into the current grammar
 *
 * Returns 0 in case of success, -1 in case of failure
 */
static int
xmlRelaxNGParseImportRefs(xmlRelaxNGParserCtxtPtr ctxt,
                          xmlRelaxNGGrammarPtr grammar) {
    if ((ctxt == NULL) || (grammar == NULL) || (ctxt->grammar == NULL))
        return(-1);
    if (grammar->refs == NULL)
        return(0);
    if (ctxt->grammar->refs == NULL)
        ctxt->grammar->refs = xmlHashCreate(10);
    if (ctxt->grammar->refs == NULL) {
        xmlRngPErr(ctxt, NULL, XML_RNGP_REF_CREATE_FAILED,
                   "Could not create references hash\n", NULL, NULL);
        return(-1);
    }
    xmlHashScan(grammar->refs, xmlRelaxNGParseImportRef, ctxt);
    return(0);
}

/**
 * xmlRelaxNGProcessExternalRef:
 * @ctxt: the parser context
 * @node:  the externlRef node
 *
 * Process and compile an externlRef node
 *
 * Returns the xmlRelaxNGDefinePtr or NULL in case of error
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGProcessExternalRef(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGDocumentPtr docu;
    xmlNodePtr root, tmp;
    xmlChar *ns;
    int newNs = 0, oldflags;
    xmlRelaxNGDefinePtr def;

    docu = node->psvi;
    if (docu != NULL) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_EXTERNALREF;

        if (docu->content == NULL) {
            /*
             * Then do the parsing for good
             */
            root = xmlDocGetRootElement(docu->doc);
            if (root == NULL) {
                xmlRngPErr(ctxt, node, XML_RNGP_EXTERNALREF_EMTPY,
                           "xmlRelaxNGParse: %s is empty\n", ctxt->URL,
                           NULL);
                return (NULL);
            }
            /*
             * ns transmission rules
             */
            ns = xmlGetProp(root, BAD_CAST "ns");
            if (ns == NULL) {
                tmp = node;
                while ((tmp != NULL) && (tmp->type == XML_ELEMENT_NODE)) {
                    ns = xmlGetProp(tmp, BAD_CAST "ns");
                    if (ns != NULL) {
                        break;
                    }
                    tmp = tmp->parent;
                }
                if (ns != NULL) {
                    xmlSetProp(root, BAD_CAST "ns", ns);
                    newNs = 1;
                    xmlFree(ns);
                }
            } else {
                xmlFree(ns);
            }

            /*
             * Parsing to get a precompiled schemas.
             */
            oldflags = ctxt->flags;
            ctxt->flags |= XML_RELAXNG_IN_EXTERNALREF;
            docu->schema = xmlRelaxNGParseDocument(ctxt, root);
            ctxt->flags = oldflags;
            if ((docu->schema != NULL) &&
                (docu->schema->topgrammar != NULL)) {
                docu->content = docu->schema->topgrammar->start;
                if (docu->schema->topgrammar->refs)
                    xmlRelaxNGParseImportRefs(ctxt, docu->schema->topgrammar);
            }

            /*
             * the externalRef may be reused in a different ns context
             */
            if (newNs == 1) {
                xmlUnsetProp(root, BAD_CAST "ns");
            }
        }
        def->content = docu->content;
    } else {
        def = NULL;
    }
    return (def);
}

/**
 * xmlRelaxNGParsePattern:
 * @ctxt:  a Relax-NG parser context
 * @node:  the pattern node.
 *
 * parse the content of a RelaxNG pattern node.
 *
 * Returns the definition pointer or NULL in case of error or if no
 *     pattern is generated.
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGParsePattern(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGDefinePtr def = NULL;

    if (node == NULL) {
        return (NULL);
    }
    if (IS_RELAXNG(node, "element")) {
        def = xmlRelaxNGParseElement(ctxt, node);
    } else if (IS_RELAXNG(node, "attribute")) {
        def = xmlRelaxNGParseAttribute(ctxt, node);
    } else if (IS_RELAXNG(node, "empty")) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_EMPTY;
        if (node->children != NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_EMPTY_NOT_EMPTY,
                       "empty: had a child node\n", NULL, NULL);
        }
    } else if (IS_RELAXNG(node, "text")) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_TEXT;
        if (node->children != NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_TEXT_HAS_CHILD,
                       "text: had a child node\n", NULL, NULL);
        }
    } else if (IS_RELAXNG(node, "zeroOrMore")) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_ZEROORMORE;
        if (node->children == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_EMPTY_CONSTRUCT,
                       "Element %s is empty\n", node->name, NULL);
        } else {
            def->content =
                xmlRelaxNGParsePatterns(ctxt, node->children, 1);
        }
    } else if (IS_RELAXNG(node, "oneOrMore")) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_ONEORMORE;
        if (node->children == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_EMPTY_CONSTRUCT,
                       "Element %s is empty\n", node->name, NULL);
        } else {
            def->content =
                xmlRelaxNGParsePatterns(ctxt, node->children, 1);
        }
    } else if (IS_RELAXNG(node, "optional")) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_OPTIONAL;
        if (node->children == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_EMPTY_CONSTRUCT,
                       "Element %s is empty\n", node->name, NULL);
        } else {
            def->content =
                xmlRelaxNGParsePatterns(ctxt, node->children, 1);
        }
    } else if (IS_RELAXNG(node, "choice")) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_CHOICE;
        if (node->children == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_EMPTY_CONSTRUCT,
                       "Element %s is empty\n", node->name, NULL);
        } else {
            def->content =
                xmlRelaxNGParsePatterns(ctxt, node->children, 0);
        }
    } else if (IS_RELAXNG(node, "group")) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_GROUP;
        if (node->children == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_EMPTY_CONSTRUCT,
                       "Element %s is empty\n", node->name, NULL);
        } else {
            def->content =
                xmlRelaxNGParsePatterns(ctxt, node->children, 0);
        }
    } else if (IS_RELAXNG(node, "ref")) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_REF;
        def->name = xmlGetProp(node, BAD_CAST "name");
        if (def->name == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_REF_NO_NAME, "ref has no name\n",
                       NULL, NULL);
        } else {
            xmlRelaxNGNormExtSpace(def->name);
            if (xmlValidateNCName(def->name, 0)) {
                xmlRngPErr(ctxt, node, XML_RNGP_REF_NAME_INVALID,
                           "ref name '%s' is not an NCName\n", def->name,
                           NULL);
            }
        }
        if (node->children != NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_REF_NOT_EMPTY, "ref is not empty\n",
                       NULL, NULL);
        }
        if (ctxt->grammar->refs == NULL)
            ctxt->grammar->refs = xmlHashCreate(10);
        if (ctxt->grammar->refs == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_REF_CREATE_FAILED,
                       "Could not create references hash\n", NULL, NULL);
            def = NULL;
        } else {
            int tmp;

            tmp = xmlHashAddEntry(ctxt->grammar->refs, def->name, def);
            if (tmp < 0) {
                xmlRelaxNGDefinePtr prev;

                prev = (xmlRelaxNGDefinePtr)
                    xmlHashLookup(ctxt->grammar->refs, def->name);
                if (prev == NULL) {
                    if (def->name != NULL) {
		        xmlRngPErr(ctxt, node, XML_RNGP_REF_CREATE_FAILED,
				   "Error refs definitions '%s'\n",
				   def->name, NULL);
                    } else {
		        xmlRngPErr(ctxt, node, XML_RNGP_REF_CREATE_FAILED,
				   "Error refs definitions\n",
				   NULL, NULL);
                    }
                    def = NULL;
                } else {
                    def->nextHash = prev->nextHash;
                    prev->nextHash = def;
                }
            }
        }
    } else if (IS_RELAXNG(node, "data")) {
        def = xmlRelaxNGParseData(ctxt, node);
    } else if (IS_RELAXNG(node, "value")) {
        def = xmlRelaxNGParseValue(ctxt, node);
    } else if (IS_RELAXNG(node, "list")) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_LIST;
        if (node->children == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_EMPTY_CONSTRUCT,
                       "Element %s is empty\n", node->name, NULL);
        } else {
            def->content =
                xmlRelaxNGParsePatterns(ctxt, node->children, 0);
        }
    } else if (IS_RELAXNG(node, "interleave")) {
        def = xmlRelaxNGParseInterleave(ctxt, node);
    } else if (IS_RELAXNG(node, "externalRef")) {
        def = xmlRelaxNGProcessExternalRef(ctxt, node);
    } else if (IS_RELAXNG(node, "notAllowed")) {
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_NOT_ALLOWED;
        if (node->children != NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_NOTALLOWED_NOT_EMPTY,
                       "xmlRelaxNGParse: notAllowed element is not empty\n",
                       NULL, NULL);
        }
    } else if (IS_RELAXNG(node, "grammar")) {
        xmlRelaxNGGrammarPtr grammar, old;
        xmlRelaxNGGrammarPtr oldparent;

#ifdef DEBUG_GRAMMAR
        xmlGenericError(xmlGenericErrorContext,
                        "Found <grammar> pattern\n");
#endif

        oldparent = ctxt->parentgrammar;
        old = ctxt->grammar;
        ctxt->parentgrammar = old;
        grammar = xmlRelaxNGParseGrammar(ctxt, node->children);
        if (old != NULL) {
            ctxt->grammar = old;
            ctxt->parentgrammar = oldparent;
#if 0
            if (grammar != NULL) {
                grammar->next = old->next;
                old->next = grammar;
            }
#endif
        }
        if (grammar != NULL)
            def = grammar->start;
        else
            def = NULL;
    } else if (IS_RELAXNG(node, "parentRef")) {
        if (ctxt->parentgrammar == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_PARENTREF_NO_PARENT,
                       "Use of parentRef without a parent grammar\n", NULL,
                       NULL);
            return (NULL);
        }
        def = xmlRelaxNGNewDefine(ctxt, node);
        if (def == NULL)
            return (NULL);
        def->type = XML_RELAXNG_PARENTREF;
        def->name = xmlGetProp(node, BAD_CAST "name");
        if (def->name == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_PARENTREF_NO_NAME,
                       "parentRef has no name\n", NULL, NULL);
        } else {
            xmlRelaxNGNormExtSpace(def->name);
            if (xmlValidateNCName(def->name, 0)) {
                xmlRngPErr(ctxt, node, XML_RNGP_PARENTREF_NAME_INVALID,
                           "parentRef name '%s' is not an NCName\n",
                           def->name, NULL);
            }
        }
        if (node->children != NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_PARENTREF_NOT_EMPTY,
                       "parentRef is not empty\n", NULL, NULL);
        }
        if (ctxt->parentgrammar->refs == NULL)
            ctxt->parentgrammar->refs = xmlHashCreate(10);
        if (ctxt->parentgrammar->refs == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_PARENTREF_CREATE_FAILED,
                       "Could not create references hash\n", NULL, NULL);
            def = NULL;
        } else if (def->name != NULL) {
            int tmp;

            tmp =
                xmlHashAddEntry(ctxt->parentgrammar->refs, def->name, def);
            if (tmp < 0) {
                xmlRelaxNGDefinePtr prev;

                prev = (xmlRelaxNGDefinePtr)
                    xmlHashLookup(ctxt->parentgrammar->refs, def->name);
                if (prev == NULL) {
                    xmlRngPErr(ctxt, node, XML_RNGP_PARENTREF_CREATE_FAILED,
                               "Internal error parentRef definitions '%s'\n",
                               def->name, NULL);
                    def = NULL;
                } else {
                    def->nextHash = prev->nextHash;
                    prev->nextHash = def;
                }
            }
        }
    } else if (IS_RELAXNG(node, "mixed")) {
        if (node->children == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_EMPTY_CONSTRUCT, "Mixed is empty\n",
                       NULL, NULL);
            def = NULL;
        } else {
            def = xmlRelaxNGParseInterleave(ctxt, node);
            if (def != NULL) {
                xmlRelaxNGDefinePtr tmp;

                if ((def->content != NULL) && (def->content->next != NULL)) {
                    tmp = xmlRelaxNGNewDefine(ctxt, node);
                    if (tmp != NULL) {
                        tmp->type = XML_RELAXNG_GROUP;
                        tmp->content = def->content;
                        def->content = tmp;
                    }
                }

                tmp = xmlRelaxNGNewDefine(ctxt, node);
                if (tmp == NULL)
                    return (def);
                tmp->type = XML_RELAXNG_TEXT;
                tmp->next = def->content;
                def->content = tmp;
            }
        }
    } else {
        xmlRngPErr(ctxt, node, XML_RNGP_UNKNOWN_CONSTRUCT,
                   "Unexpected node %s is not a pattern\n", node->name,
                   NULL);
        def = NULL;
    }
    return (def);
}

/**
 * xmlRelaxNGParseAttribute:
 * @ctxt:  a Relax-NG parser context
 * @node:  the element node
 *
 * parse the content of a RelaxNG attribute node.
 *
 * Returns the definition pointer or NULL in case of error.
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGParseAttribute(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGDefinePtr ret, cur;
    xmlNodePtr child;
    int old_flags;

    ret = xmlRelaxNGNewDefine(ctxt, node);
    if (ret == NULL)
        return (NULL);
    ret->type = XML_RELAXNG_ATTRIBUTE;
    ret->parent = ctxt->def;
    child = node->children;
    if (child == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_ATTRIBUTE_EMPTY,
                   "xmlRelaxNGParseattribute: attribute has no children\n",
                   NULL, NULL);
        return (ret);
    }
    old_flags = ctxt->flags;
    ctxt->flags |= XML_RELAXNG_IN_ATTRIBUTE;
    cur = xmlRelaxNGParseNameClass(ctxt, child, ret);
    if (cur != NULL)
        child = child->next;

    if (child != NULL) {
        cur = xmlRelaxNGParsePattern(ctxt, child);
        if (cur != NULL) {
            switch (cur->type) {
                case XML_RELAXNG_EMPTY:
                case XML_RELAXNG_NOT_ALLOWED:
                case XML_RELAXNG_TEXT:
                case XML_RELAXNG_ELEMENT:
                case XML_RELAXNG_DATATYPE:
                case XML_RELAXNG_VALUE:
                case XML_RELAXNG_LIST:
                case XML_RELAXNG_REF:
                case XML_RELAXNG_PARENTREF:
                case XML_RELAXNG_EXTERNALREF:
                case XML_RELAXNG_DEF:
                case XML_RELAXNG_ONEORMORE:
                case XML_RELAXNG_ZEROORMORE:
                case XML_RELAXNG_OPTIONAL:
                case XML_RELAXNG_CHOICE:
                case XML_RELAXNG_GROUP:
                case XML_RELAXNG_INTERLEAVE:
                case XML_RELAXNG_ATTRIBUTE:
                    ret->content = cur;
                    cur->parent = ret;
                    break;
                case XML_RELAXNG_START:
                case XML_RELAXNG_PARAM:
                case XML_RELAXNG_EXCEPT:
                    xmlRngPErr(ctxt, node, XML_RNGP_ATTRIBUTE_CONTENT,
                               "attribute has invalid content\n", NULL,
                               NULL);
                    break;
                case XML_RELAXNG_NOOP:
                    xmlRngPErr(ctxt, node, XML_RNGP_ATTRIBUTE_NOOP,
                               "RNG Internal error, noop found in attribute\n",
                               NULL, NULL);
                    break;
            }
        }
        child = child->next;
    }
    if (child != NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_ATTRIBUTE_CHILDREN,
                   "attribute has multiple children\n", NULL, NULL);
    }
    ctxt->flags = old_flags;
    return (ret);
}

/**
 * xmlRelaxNGParseExceptNameClass:
 * @ctxt:  a Relax-NG parser context
 * @node:  the except node
 * @attr:  1 if within an attribute, 0 if within an element
 *
 * parse the content of a RelaxNG nameClass node.
 *
 * Returns the definition pointer or NULL in case of error.
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGParseExceptNameClass(xmlRelaxNGParserCtxtPtr ctxt,
                               xmlNodePtr node, int attr)
{
    xmlRelaxNGDefinePtr ret, cur, last = NULL;
    xmlNodePtr child;

    if (!IS_RELAXNG(node, "except")) {
        xmlRngPErr(ctxt, node, XML_RNGP_EXCEPT_MISSING,
                   "Expecting an except node\n", NULL, NULL);
        return (NULL);
    }
    if (node->next != NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_EXCEPT_MULTIPLE,
                   "exceptNameClass allows only a single except node\n",
                   NULL, NULL);
    }
    if (node->children == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_EXCEPT_EMPTY, "except has no content\n",
                   NULL, NULL);
        return (NULL);
    }

    ret = xmlRelaxNGNewDefine(ctxt, node);
    if (ret == NULL)
        return (NULL);
    ret->type = XML_RELAXNG_EXCEPT;
    child = node->children;
    while (child != NULL) {
        cur = xmlRelaxNGNewDefine(ctxt, child);
        if (cur == NULL)
            break;
        if (attr)
            cur->type = XML_RELAXNG_ATTRIBUTE;
        else
            cur->type = XML_RELAXNG_ELEMENT;

        if (xmlRelaxNGParseNameClass(ctxt, child, cur) != NULL) {
            if (last == NULL) {
                ret->content = cur;
            } else {
                last->next = cur;
            }
            last = cur;
        }
        child = child->next;
    }

    return (ret);
}

/**
 * xmlRelaxNGParseNameClass:
 * @ctxt:  a Relax-NG parser context
 * @node:  the nameClass node
 * @def:  the current definition
 *
 * parse the content of a RelaxNG nameClass node.
 *
 * Returns the definition pointer or NULL in case of error.
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGParseNameClass(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node,
                         xmlRelaxNGDefinePtr def)
{
    xmlRelaxNGDefinePtr ret, tmp;
    xmlChar *val;

    ret = def;
    if ((IS_RELAXNG(node, "name")) || (IS_RELAXNG(node, "anyName")) ||
        (IS_RELAXNG(node, "nsName"))) {
        if ((def->type != XML_RELAXNG_ELEMENT) &&
            (def->type != XML_RELAXNG_ATTRIBUTE)) {
            ret = xmlRelaxNGNewDefine(ctxt, node);
            if (ret == NULL)
                return (NULL);
            ret->parent = def;
            if (ctxt->flags & XML_RELAXNG_IN_ATTRIBUTE)
                ret->type = XML_RELAXNG_ATTRIBUTE;
            else
                ret->type = XML_RELAXNG_ELEMENT;
        }
    }
    if (IS_RELAXNG(node, "name")) {
        val = xmlNodeGetContent(node);
        xmlRelaxNGNormExtSpace(val);
        if (xmlValidateNCName(val, 0)) {
	    if (node->parent != NULL)
		xmlRngPErr(ctxt, node, XML_RNGP_ELEMENT_NAME,
			   "Element %s name '%s' is not an NCName\n",
			   node->parent->name, val);
	    else
		xmlRngPErr(ctxt, node, XML_RNGP_ELEMENT_NAME,
			   "name '%s' is not an NCName\n",
			   val, NULL);
        }
        ret->name = val;
        val = xmlGetProp(node, BAD_CAST "ns");
        ret->ns = val;
        if ((ctxt->flags & XML_RELAXNG_IN_ATTRIBUTE) &&
            (val != NULL) &&
            (xmlStrEqual(val, BAD_CAST "http://www.w3.org/2000/xmlns"))) {
	    xmlRngPErr(ctxt, node, XML_RNGP_XML_NS,
                        "Attribute with namespace '%s' is not allowed\n",
                        val, NULL);
        }
        if ((ctxt->flags & XML_RELAXNG_IN_ATTRIBUTE) &&
            (val != NULL) &&
            (val[0] == 0) && (xmlStrEqual(ret->name, BAD_CAST "xmlns"))) {
	    xmlRngPErr(ctxt, node, XML_RNGP_XMLNS_NAME,
                       "Attribute with QName 'xmlns' is not allowed\n",
                       val, NULL);
        }
    } else if (IS_RELAXNG(node, "anyName")) {
        ret->name = NULL;
        ret->ns = NULL;
        if (node->children != NULL) {
            ret->nameClass =
                xmlRelaxNGParseExceptNameClass(ctxt, node->children,
                                               (def->type ==
                                                XML_RELAXNG_ATTRIBUTE));
        }
    } else if (IS_RELAXNG(node, "nsName")) {
        ret->name = NULL;
        ret->ns = xmlGetProp(node, BAD_CAST "ns");
        if (ret->ns == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_NSNAME_NO_NS,
                       "nsName has no ns attribute\n", NULL, NULL);
        }
        if ((ctxt->flags & XML_RELAXNG_IN_ATTRIBUTE) &&
            (ret->ns != NULL) &&
            (xmlStrEqual
             (ret->ns, BAD_CAST "http://www.w3.org/2000/xmlns"))) {
            xmlRngPErr(ctxt, node, XML_RNGP_XML_NS,
                       "Attribute with namespace '%s' is not allowed\n",
                       ret->ns, NULL);
        }
        if (node->children != NULL) {
            ret->nameClass =
                xmlRelaxNGParseExceptNameClass(ctxt, node->children,
                                               (def->type ==
                                                XML_RELAXNG_ATTRIBUTE));
        }
    } else if (IS_RELAXNG(node, "choice")) {
        xmlNodePtr child;
        xmlRelaxNGDefinePtr last = NULL;

        ret = xmlRelaxNGNewDefine(ctxt, node);
        if (ret == NULL)
            return (NULL);
        ret->parent = def;
        ret->type = XML_RELAXNG_CHOICE;

        if (node->children == NULL) {
            xmlRngPErr(ctxt, node, XML_RNGP_CHOICE_EMPTY,
                       "Element choice is empty\n", NULL, NULL);
        } else {

            child = node->children;
            while (child != NULL) {
                tmp = xmlRelaxNGParseNameClass(ctxt, child, ret);
                if (tmp != NULL) {
                    if (last == NULL) {
                        last = ret->nameClass = tmp;
                    } else {
                        last->next = tmp;
                        last = tmp;
                    }
                }
                child = child->next;
            }
        }
    } else {
        xmlRngPErr(ctxt, node, XML_RNGP_CHOICE_CONTENT,
                   "expecting name, anyName, nsName or choice : got %s\n",
                   (node == NULL ? (const xmlChar *) "nothing" : node->name),
		   NULL);
        return (NULL);
    }
    if (ret != def) {
        if (def->nameClass == NULL) {
            def->nameClass = ret;
        } else {
            tmp = def->nameClass;
            while (tmp->next != NULL) {
                tmp = tmp->next;
            }
            tmp->next = ret;
        }
    }
    return (ret);
}

/**
 * xmlRelaxNGParseElement:
 * @ctxt:  a Relax-NG parser context
 * @node:  the element node
 *
 * parse the content of a RelaxNG element node.
 *
 * Returns the definition pointer or NULL in case of error.
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGParseElement(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGDefinePtr ret, cur, last;
    xmlNodePtr child;
    const xmlChar *olddefine;

    ret = xmlRelaxNGNewDefine(ctxt, node);
    if (ret == NULL)
        return (NULL);
    ret->type = XML_RELAXNG_ELEMENT;
    ret->parent = ctxt->def;
    child = node->children;
    if (child == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_ELEMENT_EMPTY,
                   "xmlRelaxNGParseElement: element has no children\n",
                   NULL, NULL);
        return (ret);
    }
    cur = xmlRelaxNGParseNameClass(ctxt, child, ret);
    if (cur != NULL)
        child = child->next;

    if (child == NULL) {
        xmlRngPErr(ctxt, node, XML_RNGP_ELEMENT_NO_CONTENT,
                   "xmlRelaxNGParseElement: element has no content\n",
                   NULL, NULL);
        return (ret);
    }
    olddefine = ctxt->define;
    ctxt->define = NULL;
    last = NULL;
    while (child != NULL) {
        cur = xmlRelaxNGParsePattern(ctxt, child);
        if (cur != NULL) {
            cur->parent = ret;
            switch (cur->type) {
                case XML_RELAXNG_EMPTY:
                case XML_RELAXNG_NOT_ALLOWED:
                case XML_RELAXNG_TEXT:
                case XML_RELAXNG_ELEMENT:
                case XML_RELAXNG_DATATYPE:
                case XML_RELAXNG_VALUE:
                case XML_RELAXNG_LIST:
                case XML_RELAXNG_REF:
                case XML_RELAXNG_PARENTREF:
                case XML_RELAXNG_EXTERNALREF:
                case XML_RELAXNG_DEF:
                case XML_RELAXNG_ZEROORMORE:
                case XML_RELAXNG_ONEORMORE:
                case XML_RELAXNG_OPTIONAL:
                case XML_RELAXNG_CHOICE:
                case XML_RELAXNG_GROUP:
                case XML_RELAXNG_INTERLEAVE:
                    if (last == NULL) {
                        ret->content = last = cur;
                    } else {
                        if ((last->type == XML_RELAXNG_ELEMENT) &&
                            (ret->content == last)) {
                            ret->content = xmlRelaxNGNewDefine(ctxt, node);
                            if (ret->content != NULL) {
                                ret->content->type = XML_RELAXNG_GROUP;
                                ret->content->content = last;
                            } else {
                                ret->content = last;
                            }
                        }
                        last->next = cur;
                        last = cur;
                    }
                    break;
                case XML_RELAXNG_ATTRIBUTE:
                    cur->next = ret->attrs;
                    ret->attrs = cur;
                    break;
                case XML_RELAXNG_START:
                    xmlRngPErr(ctxt, node, XML_RNGP_ELEMENT_CONTENT,
                               "RNG Internal error, start found in element\n",
                               NULL, NULL);
                    break;
                case XML_RELAXNG_PARAM:
                    xmlRngPErr(ctxt, node, XML_RNGP_ELEMENT_CONTENT,
                               "RNG Internal error, param found in element\n",
                               NULL, NULL);
                    break;
                case XML_RELAXNG_EXCEPT:
                    xmlRngPErr(ctxt, node, XML_RNGP_ELEMENT_CONTENT,
                               "RNG Internal error, except found in element\n",
                               NULL, NULL);
                    break;
                case XML_RELAXNG_NOOP:
                    xmlRngPErr(ctxt, node, XML_RNGP_ELEMENT_CONTENT,
                               "RNG Internal error, noop found in element\n",
                               NULL, NULL);
                    break;
            }
        }
        child = child->next;
    }
    ctxt->define = olddefine;
    return (ret);
}

/**
 * xmlRelaxNGParsePatterns:
 * @ctxt:  a Relax-NG parser context
 * @nodes:  list of nodes
 * @group:  use an implicit <group> for elements
 *
 * parse the content of a RelaxNG start node.
 *
 * Returns the definition pointer or NULL in case of error.
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGParsePatterns(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr nodes,
                        int group)
{
    xmlRelaxNGDefinePtr def = NULL, last = NULL, cur, parent;

    parent = ctxt->def;
    while (nodes != NULL) {
        if (IS_RELAXNG(nodes, "element")) {
            cur = xmlRelaxNGParseElement(ctxt, nodes);
            if (def == NULL) {
                def = last = cur;
            } else {
                if ((group == 1) && (def->type == XML_RELAXNG_ELEMENT) &&
                    (def == last)) {
                    def = xmlRelaxNGNewDefine(ctxt, nodes);
                    def->type = XML_RELAXNG_GROUP;
                    def->content = last;
                }
                last->next = cur;
                last = cur;
            }
            cur->parent = parent;
        } else {
            cur = xmlRelaxNGParsePattern(ctxt, nodes);
            if (cur != NULL) {
                if (def == NULL) {
                    def = last = cur;
                } else {
                    last->next = cur;
                    last = cur;
                }
            }
        }
        nodes = nodes->next;
    }
    return (def);
}

/**
 * xmlRelaxNGParseStart:
 * @ctxt:  a Relax-NG parser context
 * @nodes:  start children nodes
 *
 * parse the content of a RelaxNG start node.
 *
 * Returns 0 in case of success, -1 in case of error
 */
static int
xmlRelaxNGParseStart(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr nodes)
{
    int ret = 0;
    xmlRelaxNGDefinePtr def = NULL, last;

    if (nodes == NULL) {
        xmlRngPErr(ctxt, nodes, XML_RNGP_START_EMPTY, "start has no children\n",
                   NULL, NULL);
        return (-1);
    }
    if (IS_RELAXNG(nodes, "empty")) {
        def = xmlRelaxNGNewDefine(ctxt, nodes);
        if (def == NULL)
            return (-1);
        def->type = XML_RELAXNG_EMPTY;
        if (nodes->children != NULL) {
            xmlRngPErr(ctxt, nodes, XML_RNGP_EMPTY_CONTENT,
                       "element empty is not empty\n", NULL, NULL);
        }
    } else if (IS_RELAXNG(nodes, "notAllowed")) {
        def = xmlRelaxNGNewDefine(ctxt, nodes);
        if (def == NULL)
            return (-1);
        def->type = XML_RELAXNG_NOT_ALLOWED;
        if (nodes->children != NULL) {
            xmlRngPErr(ctxt, nodes, XML_RNGP_NOTALLOWED_NOT_EMPTY,
                       "element notAllowed is not empty\n", NULL, NULL);
        }
    } else {
        def = xmlRelaxNGParsePatterns(ctxt, nodes, 1);
    }
    if (ctxt->grammar->start != NULL) {
        last = ctxt->grammar->start;
        while (last->next != NULL)
            last = last->next;
        last->next = def;
    } else {
        ctxt->grammar->start = def;
    }
    nodes = nodes->next;
    if (nodes != NULL) {
        xmlRngPErr(ctxt, nodes, XML_RNGP_START_CONTENT,
                   "start more than one children\n", NULL, NULL);
        return (-1);
    }
    return (ret);
}

/**
 * xmlRelaxNGParseGrammarContent:
 * @ctxt:  a Relax-NG parser context
 * @nodes:  grammar children nodes
 *
 * parse the content of a RelaxNG grammar node.
 *
 * Returns 0 in case of success, -1 in case of error
 */
static int
xmlRelaxNGParseGrammarContent(xmlRelaxNGParserCtxtPtr ctxt,
                              xmlNodePtr nodes)
{
    int ret = 0, tmp;

    if (nodes == NULL) {
        xmlRngPErr(ctxt, nodes, XML_RNGP_GRAMMAR_EMPTY,
                   "grammar has no children\n", NULL, NULL);
        return (-1);
    }
    while (nodes != NULL) {
        if (IS_RELAXNG(nodes, "start")) {
            if (nodes->children == NULL) {
                xmlRngPErr(ctxt, nodes, XML_RNGP_START_EMPTY,
                           "start has no children\n", NULL, NULL);
            } else {
                tmp = xmlRelaxNGParseStart(ctxt, nodes->children);
                if (tmp != 0)
                    ret = -1;
            }
        } else if (IS_RELAXNG(nodes, "define")) {
            tmp = xmlRelaxNGParseDefine(ctxt, nodes);
            if (tmp != 0)
                ret = -1;
        } else if (IS_RELAXNG(nodes, "include")) {
            tmp = xmlRelaxNGParseInclude(ctxt, nodes);
            if (tmp != 0)
                ret = -1;
        } else {
            xmlRngPErr(ctxt, nodes, XML_RNGP_GRAMMAR_CONTENT,
                       "grammar has unexpected child %s\n", nodes->name,
                       NULL);
            ret = -1;
        }
        nodes = nodes->next;
    }
    return (ret);
}

/**
 * xmlRelaxNGCheckReference:
 * @ref:  the ref
 * @ctxt:  a Relax-NG parser context
 * @name:  the name associated to the defines
 *
 * Applies the 4.17. combine attribute rule for all the define
 * element of a given grammar using the same name.
 */
static void
xmlRelaxNGCheckReference(xmlRelaxNGDefinePtr ref,
                         xmlRelaxNGParserCtxtPtr ctxt,
                         const xmlChar * name)
{
    xmlRelaxNGGrammarPtr grammar;
    xmlRelaxNGDefinePtr def, cur;

    /*
     * Those rules don't apply to imported ref from xmlRelaxNGParseImportRef
     */
    if (ref->dflags & IS_EXTERNAL_REF)
        return;

    grammar = ctxt->grammar;
    if (grammar == NULL) {
        xmlRngPErr(ctxt, ref->node, XML_ERR_INTERNAL_ERROR,
                   "Internal error: no grammar in CheckReference %s\n",
                   name, NULL);
        return;
    }
    if (ref->content != NULL) {
        xmlRngPErr(ctxt, ref->node, XML_ERR_INTERNAL_ERROR,
                   "Internal error: reference has content in CheckReference %s\n",
                   name, NULL);
        return;
    }
    if (grammar->defs != NULL) {
        def = xmlHashLookup(grammar->defs, name);
        if (def != NULL) {
            cur = ref;
            while (cur != NULL) {
                cur->content = def;
                cur = cur->nextHash;
            }
        } else {
            xmlRngPErr(ctxt, ref->node, XML_RNGP_REF_NO_DEF,
                       "Reference %s has no matching definition\n", name,
                       NULL);
        }
    } else {
        xmlRngPErr(ctxt, ref->node, XML_RNGP_REF_NO_DEF,
                   "Reference %s has no matching definition\n", name,
                   NULL);
    }
}

/**
 * xmlRelaxNGCheckCombine:
 * @define:  the define(s) list
 * @ctxt:  a Relax-NG parser context
 * @name:  the name associated to the defines
 *
 * Applies the 4.17. combine attribute rule for all the define
 * element of a given grammar using the same name.
 */
static void
xmlRelaxNGCheckCombine(xmlRelaxNGDefinePtr define,
                       xmlRelaxNGParserCtxtPtr ctxt, const xmlChar * name)
{
    xmlChar *combine;
    int choiceOrInterleave = -1;
    int missing = 0;
    xmlRelaxNGDefinePtr cur, last, tmp, tmp2;

    if (define->nextHash == NULL)
        return;
    cur = define;
    while (cur != NULL) {
        combine = xmlGetProp(cur->node, BAD_CAST "combine");
        if (combine != NULL) {
            if (xmlStrEqual(combine, BAD_CAST "choice")) {
                if (choiceOrInterleave == -1)
                    choiceOrInterleave = 1;
                else if (choiceOrInterleave == 0) {
                    xmlRngPErr(ctxt, define->node, XML_RNGP_DEF_CHOICE_AND_INTERLEAVE,
                               "Defines for %s use both 'choice' and 'interleave'\n",
                               name, NULL);
                }
            } else if (xmlStrEqual(combine, BAD_CAST "interleave")) {
                if (choiceOrInterleave == -1)
                    choiceOrInterleave = 0;
                else if (choiceOrInterleave == 1) {
                    xmlRngPErr(ctxt, define->node, XML_RNGP_DEF_CHOICE_AND_INTERLEAVE,
                               "Defines for %s use both 'choice' and 'interleave'\n",
                               name, NULL);
                }
            } else {
                xmlRngPErr(ctxt, define->node, XML_RNGP_UNKNOWN_COMBINE,
                           "Defines for %s use unknown combine value '%s''\n",
                           name, combine);
            }
            xmlFree(combine);
        } else {
            if (missing == 0)
                missing = 1;
            else {
                xmlRngPErr(ctxt, define->node, XML_RNGP_NEED_COMBINE,
                           "Some defines for %s needs the combine attribute\n",
                           name, NULL);
            }
        }

        cur = cur->nextHash;
    }
#ifdef DEBUG
    xmlGenericError(xmlGenericErrorContext,
                    "xmlRelaxNGCheckCombine(): merging %s defines: %d\n",
                    name, choiceOrInterleave);
#endif
    if (choiceOrInterleave == -1)
        choiceOrInterleave = 0;
    cur = xmlRelaxNGNewDefine(ctxt, define->node);
    if (cur == NULL)
        return;
    if (choiceOrInterleave == 0)
        cur->type = XML_RELAXNG_INTERLEAVE;
    else
        cur->type = XML_RELAXNG_CHOICE;
    tmp = define;
    last = NULL;
    while (tmp != NULL) {
        if (tmp->content != NULL) {
            if (tmp->content->next != NULL) {
                /*
                 * we need first to create a wrapper.
                 */
                tmp2 = xmlRelaxNGNewDefine(ctxt, tmp->content->node);
                if (tmp2 == NULL)
                    break;
                tmp2->type = XML_RELAXNG_GROUP;
                tmp2->content = tmp->content;
            } else {
                tmp2 = tmp->content;
            }
            if (last == NULL) {
                cur->content = tmp2;
            } else {
                last->next = tmp2;
            }
            last = tmp2;
        }
        tmp->content = cur;
        tmp = tmp->nextHash;
    }
    define->content = cur;
    if (choiceOrInterleave == 0) {
        if (ctxt->interleaves == NULL)
            ctxt->interleaves = xmlHashCreate(10);
        if (ctxt->interleaves == NULL) {
            xmlRngPErr(ctxt, define->node, XML_RNGP_INTERLEAVE_CREATE_FAILED,
                       "Failed to create interleaves hash table\n", NULL,
                       NULL);
        } else {
            char tmpname[32];

            snprintf(tmpname, 32, "interleave%d", ctxt->nbInterleaves++);
            if (xmlHashAddEntry(ctxt->interleaves, BAD_CAST tmpname, cur) <
                0) {
                xmlRngPErr(ctxt, define->node, XML_RNGP_INTERLEAVE_CREATE_FAILED,
                           "Failed to add %s to hash table\n",
			   (const xmlChar *) tmpname, NULL);
            }
        }
    }
}

/**
 * xmlRelaxNGCombineStart:
 * @ctxt:  a Relax-NG parser context
 * @grammar:  the grammar
 *
 * Applies the 4.17. combine rule for all the start
 * element of a given grammar.
 */
static void
xmlRelaxNGCombineStart(xmlRelaxNGParserCtxtPtr ctxt,
                       xmlRelaxNGGrammarPtr grammar)
{
    xmlRelaxNGDefinePtr starts;
    xmlChar *combine;
    int choiceOrInterleave = -1;
    int missing = 0;
    xmlRelaxNGDefinePtr cur;

    starts = grammar->start;
    if ((starts == NULL) || (starts->next == NULL))
        return;
    cur = starts;
    while (cur != NULL) {
        if ((cur->node == NULL) || (cur->node->parent == NULL) ||
            (!xmlStrEqual(cur->node->parent->name, BAD_CAST "start"))) {
            combine = NULL;
            xmlRngPErr(ctxt, cur->node, XML_RNGP_START_MISSING,
                       "Internal error: start element not found\n", NULL,
                       NULL);
        } else {
            combine = xmlGetProp(cur->node->parent, BAD_CAST "combine");
        }

        if (combine != NULL) {
            if (xmlStrEqual(combine, BAD_CAST "choice")) {
                if (choiceOrInterleave == -1)
                    choiceOrInterleave = 1;
                else if (choiceOrInterleave == 0) {
                    xmlRngPErr(ctxt, cur->node, XML_RNGP_START_CHOICE_AND_INTERLEAVE,
                               "<start> use both 'choice' and 'interleave'\n",
                               NULL, NULL);
                }
            } else if (xmlStrEqual(combine, BAD_CAST "interleave")) {
                if (choiceOrInterleave == -1)
                    choiceOrInterleave = 0;
                else if (choiceOrInterleave == 1) {
                    xmlRngPErr(ctxt, cur->node, XML_RNGP_START_CHOICE_AND_INTERLEAVE,
                               "<start> use both 'choice' and 'interleave'\n",
                               NULL, NULL);
                }
            } else {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_UNKNOWN_COMBINE,
                           "<start> uses unknown combine value '%s''\n",
                           combine, NULL);
            }
            xmlFree(combine);
        } else {
            if (missing == 0)
                missing = 1;
            else {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_NEED_COMBINE,
                           "Some <start> element miss the combine attribute\n",
                           NULL, NULL);
            }
        }

        cur = cur->next;
    }
#ifdef DEBUG
    xmlGenericError(xmlGenericErrorContext,
                    "xmlRelaxNGCombineStart(): merging <start>: %d\n",
                    choiceOrInterleave);
#endif
    if (choiceOrInterleave == -1)
        choiceOrInterleave = 0;
    cur = xmlRelaxNGNewDefine(ctxt, starts->node);
    if (cur == NULL)
        return;
    if (choiceOrInterleave == 0)
        cur->type = XML_RELAXNG_INTERLEAVE;
    else
        cur->type = XML_RELAXNG_CHOICE;
    cur->content = grammar->start;
    grammar->start = cur;
    if (choiceOrInterleave == 0) {
        if (ctxt->interleaves == NULL)
            ctxt->interleaves = xmlHashCreate(10);
        if (ctxt->interleaves == NULL) {
            xmlRngPErr(ctxt, cur->node, XML_RNGP_INTERLEAVE_CREATE_FAILED,
                       "Failed to create interleaves hash table\n", NULL,
                       NULL);
        } else {
            char tmpname[32];

            snprintf(tmpname, 32, "interleave%d", ctxt->nbInterleaves++);
            if (xmlHashAddEntry(ctxt->interleaves, BAD_CAST tmpname, cur) <
                0) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_INTERLEAVE_CREATE_FAILED,
                           "Failed to add %s to hash table\n",
			   (const xmlChar *) tmpname, NULL);
            }
        }
    }
}

/**
 * xmlRelaxNGCheckCycles:
 * @ctxt:  a Relax-NG parser context
 * @nodes:  grammar children nodes
 * @depth:  the counter
 *
 * Check for cycles.
 *
 * Returns 0 if check passed, and -1 in case of error
 */
static int
xmlRelaxNGCheckCycles(xmlRelaxNGParserCtxtPtr ctxt,
                      xmlRelaxNGDefinePtr cur, int depth)
{
    int ret = 0;

    while ((ret == 0) && (cur != NULL)) {
        if ((cur->type == XML_RELAXNG_REF) ||
            (cur->type == XML_RELAXNG_PARENTREF)) {
            if (cur->depth == -1) {
                cur->depth = depth;
                ret = xmlRelaxNGCheckCycles(ctxt, cur->content, depth);
                cur->depth = -2;
            } else if (depth == cur->depth) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_REF_CYCLE,
                           "Detected a cycle in %s references\n",
                           cur->name, NULL);
                return (-1);
            }
        } else if (cur->type == XML_RELAXNG_ELEMENT) {
            ret = xmlRelaxNGCheckCycles(ctxt, cur->content, depth + 1);
        } else {
            ret = xmlRelaxNGCheckCycles(ctxt, cur->content, depth);
        }
        cur = cur->next;
    }
    return (ret);
}

/**
 * xmlRelaxNGTryUnlink:
 * @ctxt:  a Relax-NG parser context
 * @cur:  the definition to unlink
 * @parent:  the parent definition
 * @prev:  the previous sibling definition
 *
 * Try to unlink a definition. If not possble make it a NOOP
 *
 * Returns the new prev definition
 */
static xmlRelaxNGDefinePtr
xmlRelaxNGTryUnlink(xmlRelaxNGParserCtxtPtr ctxt ATTRIBUTE_UNUSED,
                    xmlRelaxNGDefinePtr cur,
                    xmlRelaxNGDefinePtr parent, xmlRelaxNGDefinePtr prev)
{
    if (prev != NULL) {
        prev->next = cur->next;
    } else {
        if (parent != NULL) {
            if (parent->content == cur)
                parent->content = cur->next;
            else if (parent->attrs == cur)
                parent->attrs = cur->next;
            else if (parent->nameClass == cur)
                parent->nameClass = cur->next;
        } else {
            cur->type = XML_RELAXNG_NOOP;
            prev = cur;
        }
    }
    return (prev);
}

/**
 * xmlRelaxNGSimplify:
 * @ctxt:  a Relax-NG parser context
 * @nodes:  grammar children nodes
 *
 * Check for simplification of empty and notAllowed
 */
static void
xmlRelaxNGSimplify(xmlRelaxNGParserCtxtPtr ctxt,
                   xmlRelaxNGDefinePtr cur, xmlRelaxNGDefinePtr parent)
{
    xmlRelaxNGDefinePtr prev = NULL;

    while (cur != NULL) {
        if ((cur->type == XML_RELAXNG_REF) ||
            (cur->type == XML_RELAXNG_PARENTREF)) {
            if (cur->depth != -3) {
                cur->depth = -3;
                xmlRelaxNGSimplify(ctxt, cur->content, cur);
            }
        } else if (cur->type == XML_RELAXNG_NOT_ALLOWED) {
            cur->parent = parent;
            if ((parent != NULL) &&
                ((parent->type == XML_RELAXNG_ATTRIBUTE) ||
                 (parent->type == XML_RELAXNG_LIST) ||
                 (parent->type == XML_RELAXNG_GROUP) ||
                 (parent->type == XML_RELAXNG_INTERLEAVE) ||
                 (parent->type == XML_RELAXNG_ONEORMORE) ||
                 (parent->type == XML_RELAXNG_ZEROORMORE))) {
                parent->type = XML_RELAXNG_NOT_ALLOWED;
                break;
            }
            if ((parent != NULL) && (parent->type == XML_RELAXNG_CHOICE)) {
                prev = xmlRelaxNGTryUnlink(ctxt, cur, parent, prev);
            } else
                prev = cur;
        } else if (cur->type == XML_RELAXNG_EMPTY) {
            cur->parent = parent;
            if ((parent != NULL) &&
                ((parent->type == XML_RELAXNG_ONEORMORE) ||
                 (parent->type == XML_RELAXNG_ZEROORMORE))) {
                parent->type = XML_RELAXNG_EMPTY;
                break;
            }
            if ((parent != NULL) &&
                ((parent->type == XML_RELAXNG_GROUP) ||
                 (parent->type == XML_RELAXNG_INTERLEAVE))) {
                prev = xmlRelaxNGTryUnlink(ctxt, cur, parent, prev);
            } else
                prev = cur;
        } else {
            cur->parent = parent;
            if (cur->content != NULL)
                xmlRelaxNGSimplify(ctxt, cur->content, cur);
            if ((cur->type != XML_RELAXNG_VALUE) && (cur->attrs != NULL))
                xmlRelaxNGSimplify(ctxt, cur->attrs, cur);
            if (cur->nameClass != NULL)
                xmlRelaxNGSimplify(ctxt, cur->nameClass, cur);
            /*
             * On Elements, try to move attribute only generating rules on
             * the attrs rules.
             */
            if (cur->type == XML_RELAXNG_ELEMENT) {
                int attronly;
                xmlRelaxNGDefinePtr tmp, pre;

                while (cur->content != NULL) {
                    attronly =
                        xmlRelaxNGGenerateAttributes(ctxt, cur->content);
                    if (attronly == 1) {
                        /*
                         * migrate cur->content to attrs
                         */
                        tmp = cur->content;
                        cur->content = tmp->next;
                        tmp->next = cur->attrs;
                        cur->attrs = tmp;
                    } else {
                        /*
                         * cur->content can generate elements or text
                         */
                        break;
                    }
                }
                pre = cur->content;
                while ((pre != NULL) && (pre->next != NULL)) {
                    tmp = pre->next;
                    attronly = xmlRelaxNGGenerateAttributes(ctxt, tmp);
                    if (attronly == 1) {
                        /*
                         * migrate tmp to attrs
                         */
                        pre->next = tmp->next;
                        tmp->next = cur->attrs;
                        cur->attrs = tmp;
                    } else {
                        pre = tmp;
                    }
                }
            }
            /*
             * This may result in a simplification
             */
            if ((cur->type == XML_RELAXNG_GROUP) ||
                (cur->type == XML_RELAXNG_INTERLEAVE)) {
                if (cur->content == NULL)
                    cur->type = XML_RELAXNG_EMPTY;
                else if (cur->content->next == NULL) {
                    if ((parent == NULL) && (prev == NULL)) {
                        cur->type = XML_RELAXNG_NOOP;
                    } else if (prev == NULL) {
                        parent->content = cur->content;
                        cur->content->next = cur->next;
                        cur = cur->content;
                    } else {
                        cur->content->next = cur->next;
                        prev->next = cur->content;
                        cur = cur->content;
                    }
                }
            }
            /*
             * the current node may have been transformed back
             */
            if ((cur->type == XML_RELAXNG_EXCEPT) &&
                (cur->content != NULL) &&
                (cur->content->type == XML_RELAXNG_NOT_ALLOWED)) {
                prev = xmlRelaxNGTryUnlink(ctxt, cur, parent, prev);
            } else if (cur->type == XML_RELAXNG_NOT_ALLOWED) {
                if ((parent != NULL) &&
                    ((parent->type == XML_RELAXNG_ATTRIBUTE) ||
                     (parent->type == XML_RELAXNG_LIST) ||
                     (parent->type == XML_RELAXNG_GROUP) ||
                     (parent->type == XML_RELAXNG_INTERLEAVE) ||
                     (parent->type == XML_RELAXNG_ONEORMORE) ||
                     (parent->type == XML_RELAXNG_ZEROORMORE))) {
                    parent->type = XML_RELAXNG_NOT_ALLOWED;
                    break;
                }
                if ((parent != NULL) &&
                    (parent->type == XML_RELAXNG_CHOICE)) {
                    prev = xmlRelaxNGTryUnlink(ctxt, cur, parent, prev);
                } else
                    prev = cur;
            } else if (cur->type == XML_RELAXNG_EMPTY) {
                if ((parent != NULL) &&
                    ((parent->type == XML_RELAXNG_ONEORMORE) ||
                     (parent->type == XML_RELAXNG_ZEROORMORE))) {
                    parent->type = XML_RELAXNG_EMPTY;
                    break;
                }
                if ((parent != NULL) &&
                    ((parent->type == XML_RELAXNG_GROUP) ||
                     (parent->type == XML_RELAXNG_INTERLEAVE) ||
                     (parent->type == XML_RELAXNG_CHOICE))) {
                    prev = xmlRelaxNGTryUnlink(ctxt, cur, parent, prev);
                } else
                    prev = cur;
            } else {
                prev = cur;
            }
        }
        cur = cur->next;
    }
}

/**
 * xmlRelaxNGGroupContentType:
 * @ct1:  the first content type
 * @ct2:  the second content type
 *
 * Try to group 2 content types
 *
 * Returns the content type
 */
static xmlRelaxNGContentType
xmlRelaxNGGroupContentType(xmlRelaxNGContentType ct1,
                           xmlRelaxNGContentType ct2)
{
    if ((ct1 == XML_RELAXNG_CONTENT_ERROR) ||
        (ct2 == XML_RELAXNG_CONTENT_ERROR))
        return (XML_RELAXNG_CONTENT_ERROR);
    if (ct1 == XML_RELAXNG_CONTENT_EMPTY)
        return (ct2);
    if (ct2 == XML_RELAXNG_CONTENT_EMPTY)
        return (ct1);
    if ((ct1 == XML_RELAXNG_CONTENT_COMPLEX) &&
        (ct2 == XML_RELAXNG_CONTENT_COMPLEX))
        return (XML_RELAXNG_CONTENT_COMPLEX);
    return (XML_RELAXNG_CONTENT_ERROR);
}

/**
 * xmlRelaxNGMaxContentType:
 * @ct1:  the first content type
 * @ct2:  the second content type
 *
 * Compute the max content-type
 *
 * Returns the content type
 */
static xmlRelaxNGContentType
xmlRelaxNGMaxContentType(xmlRelaxNGContentType ct1,
                         xmlRelaxNGContentType ct2)
{
    if ((ct1 == XML_RELAXNG_CONTENT_ERROR) ||
        (ct2 == XML_RELAXNG_CONTENT_ERROR))
        return (XML_RELAXNG_CONTENT_ERROR);
    if ((ct1 == XML_RELAXNG_CONTENT_SIMPLE) ||
        (ct2 == XML_RELAXNG_CONTENT_SIMPLE))
        return (XML_RELAXNG_CONTENT_SIMPLE);
    if ((ct1 == XML_RELAXNG_CONTENT_COMPLEX) ||
        (ct2 == XML_RELAXNG_CONTENT_COMPLEX))
        return (XML_RELAXNG_CONTENT_COMPLEX);
    return (XML_RELAXNG_CONTENT_EMPTY);
}

/**
 * xmlRelaxNGCheckRules:
 * @ctxt:  a Relax-NG parser context
 * @cur:  the current definition
 * @flags:  some accumulated flags
 * @ptype:  the parent type
 *
 * Check for rules in section 7.1 and 7.2
 *
 * Returns the content type of @cur
 */
static xmlRelaxNGContentType
xmlRelaxNGCheckRules(xmlRelaxNGParserCtxtPtr ctxt,
                     xmlRelaxNGDefinePtr cur, int flags,
                     xmlRelaxNGType ptype)
{
    int nflags;
    xmlRelaxNGContentType ret, tmp, val = XML_RELAXNG_CONTENT_EMPTY;

    while (cur != NULL) {
        ret = XML_RELAXNG_CONTENT_EMPTY;
        if ((cur->type == XML_RELAXNG_REF) ||
            (cur->type == XML_RELAXNG_PARENTREF)) {
           /*
            * This should actually be caught by list//element(ref) at the
            * element boundaries, c.f. Bug #159968 local refs are dropped
            * in step 4.19.
            */
#if 0
            if (flags & XML_RELAXNG_IN_LIST) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_LIST_REF,
                           "Found forbidden pattern list//ref\n", NULL,
                           NULL);
            }
#endif
            if (flags & XML_RELAXNG_IN_DATAEXCEPT) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_DATA_EXCEPT_REF,
                           "Found forbidden pattern data/except//ref\n",
                           NULL, NULL);
            }
            if (cur->content == NULL) {
                if (cur->type == XML_RELAXNG_PARENTREF)
                    xmlRngPErr(ctxt, cur->node, XML_RNGP_REF_NO_DEF,
                               "Internal found no define for parent refs\n",
                               NULL, NULL);
                else
                    xmlRngPErr(ctxt, cur->node, XML_RNGP_REF_NO_DEF,
                               "Internal found no define for ref %s\n",
                               (cur->name ? cur->name: BAD_CAST "null"), NULL);
            }
            if (cur->depth > -4) {
                cur->depth = -4;
                ret = xmlRelaxNGCheckRules(ctxt, cur->content,
                                           flags, cur->type);
                cur->depth = ret - 15;
            } else if (cur->depth == -4) {
                ret = XML_RELAXNG_CONTENT_COMPLEX;
            } else {
                ret = (xmlRelaxNGContentType) (cur->depth + 15);
            }
        } else if (cur->type == XML_RELAXNG_ELEMENT) {
            /*
             * The 7.3 Attribute derivation rule for groups is plugged there
             */
            xmlRelaxNGCheckGroupAttrs(ctxt, cur);
            if (flags & XML_RELAXNG_IN_DATAEXCEPT) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_DATA_EXCEPT_ELEM,
                           "Found forbidden pattern data/except//element(ref)\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_LIST) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_LIST_ELEM,
                           "Found forbidden pattern list//element(ref)\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_ATTRIBUTE) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_ATTR_ELEM,
                           "Found forbidden pattern attribute//element(ref)\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_ATTRIBUTE) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_ATTR_ELEM,
                           "Found forbidden pattern attribute//element(ref)\n",
                           NULL, NULL);
            }
            /*
             * reset since in the simple form elements are only child
             * of grammar/define
             */
            nflags = 0;
            ret =
                xmlRelaxNGCheckRules(ctxt, cur->attrs, nflags, cur->type);
            if (ret != XML_RELAXNG_CONTENT_EMPTY) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_ELEM_CONTENT_EMPTY,
                           "Element %s attributes have a content type error\n",
                           cur->name, NULL);
            }
            ret =
                xmlRelaxNGCheckRules(ctxt, cur->content, nflags,
                                     cur->type);
            if (ret == XML_RELAXNG_CONTENT_ERROR) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_ELEM_CONTENT_ERROR,
                           "Element %s has a content type error\n",
                           cur->name, NULL);
            } else {
                ret = XML_RELAXNG_CONTENT_COMPLEX;
            }
        } else if (cur->type == XML_RELAXNG_ATTRIBUTE) {
            if (flags & XML_RELAXNG_IN_ATTRIBUTE) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_ATTR_ATTR,
                           "Found forbidden pattern attribute//attribute\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_LIST) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_LIST_ATTR,
                           "Found forbidden pattern list//attribute\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_OOMGROUP) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_ONEMORE_GROUP_ATTR,
                           "Found forbidden pattern oneOrMore//group//attribute\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_OOMINTERLEAVE) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_ONEMORE_INTERLEAVE_ATTR,
                           "Found forbidden pattern oneOrMore//interleave//attribute\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_DATAEXCEPT) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_DATA_EXCEPT_ATTR,
                           "Found forbidden pattern data/except//attribute\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_START) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_START_ATTR,
                           "Found forbidden pattern start//attribute\n",
                           NULL, NULL);
            }
            if ((!(flags & XML_RELAXNG_IN_ONEORMORE))
                && (cur->name == NULL)) {
                if (cur->ns == NULL) {
                    xmlRngPErr(ctxt, cur->node, XML_RNGP_ANYNAME_ATTR_ANCESTOR,
                               "Found anyName attribute without oneOrMore ancestor\n",
                               NULL, NULL);
                } else {
                    xmlRngPErr(ctxt, cur->node, XML_RNGP_NSNAME_ATTR_ANCESTOR,
                               "Found nsName attribute without oneOrMore ancestor\n",
                               NULL, NULL);
                }
            }
            nflags = flags | XML_RELAXNG_IN_ATTRIBUTE;
            xmlRelaxNGCheckRules(ctxt, cur->content, nflags, cur->type);
            ret = XML_RELAXNG_CONTENT_EMPTY;
        } else if ((cur->type == XML_RELAXNG_ONEORMORE) ||
                   (cur->type == XML_RELAXNG_ZEROORMORE)) {
            if (flags & XML_RELAXNG_IN_DATAEXCEPT) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_DATA_EXCEPT_ONEMORE,
                           "Found forbidden pattern data/except//oneOrMore\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_START) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_START_ONEMORE,
                           "Found forbidden pattern start//oneOrMore\n",
                           NULL, NULL);
            }
            nflags = flags | XML_RELAXNG_IN_ONEORMORE;
            ret =
                xmlRelaxNGCheckRules(ctxt, cur->content, nflags,
                                     cur->type);
            ret = xmlRelaxNGGroupContentType(ret, ret);
        } else if (cur->type == XML_RELAXNG_LIST) {
            if (flags & XML_RELAXNG_IN_LIST) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_LIST_LIST,
                           "Found forbidden pattern list//list\n", NULL,
                           NULL);
            }
            if (flags & XML_RELAXNG_IN_DATAEXCEPT) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_DATA_EXCEPT_LIST,
                           "Found forbidden pattern data/except//list\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_START) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_START_LIST,
                           "Found forbidden pattern start//list\n", NULL,
                           NULL);
            }
            nflags = flags | XML_RELAXNG_IN_LIST;
            ret =
                xmlRelaxNGCheckRules(ctxt, cur->content, nflags,
                                     cur->type);
        } else if (cur->type == XML_RELAXNG_GROUP) {
            if (flags & XML_RELAXNG_IN_DATAEXCEPT) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_DATA_EXCEPT_GROUP,
                           "Found forbidden pattern data/except//group\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_START) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_START_GROUP,
                           "Found forbidden pattern start//group\n", NULL,
                           NULL);
            }
            if (flags & XML_RELAXNG_IN_ONEORMORE)
                nflags = flags | XML_RELAXNG_IN_OOMGROUP;
            else
                nflags = flags;
            ret =
                xmlRelaxNGCheckRules(ctxt, cur->content, nflags,
                                     cur->type);
            /*
             * The 7.3 Attribute derivation rule for groups is plugged there
             */
            xmlRelaxNGCheckGroupAttrs(ctxt, cur);
        } else if (cur->type == XML_RELAXNG_INTERLEAVE) {
            if (flags & XML_RELAXNG_IN_LIST) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_LIST_INTERLEAVE,
                           "Found forbidden pattern list//interleave\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_DATAEXCEPT) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_DATA_EXCEPT_INTERLEAVE,
                           "Found forbidden pattern data/except//interleave\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_START) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_DATA_EXCEPT_INTERLEAVE,
                           "Found forbidden pattern start//interleave\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_ONEORMORE)
                nflags = flags | XML_RELAXNG_IN_OOMINTERLEAVE;
            else
                nflags = flags;
            ret =
                xmlRelaxNGCheckRules(ctxt, cur->content, nflags,
                                     cur->type);
        } else if (cur->type == XML_RELAXNG_EXCEPT) {
            if ((cur->parent != NULL) &&
                (cur->parent->type == XML_RELAXNG_DATATYPE))
                nflags = flags | XML_RELAXNG_IN_DATAEXCEPT;
            else
                nflags = flags;
            ret =
                xmlRelaxNGCheckRules(ctxt, cur->content, nflags,
                                     cur->type);
        } else if (cur->type == XML_RELAXNG_DATATYPE) {
            if (flags & XML_RELAXNG_IN_START) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_START_DATA,
                           "Found forbidden pattern start//data\n", NULL,
                           NULL);
            }
            xmlRelaxNGCheckRules(ctxt, cur->content, flags, cur->type);
            ret = XML_RELAXNG_CONTENT_SIMPLE;
        } else if (cur->type == XML_RELAXNG_VALUE) {
            if (flags & XML_RELAXNG_IN_START) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_START_VALUE,
                           "Found forbidden pattern start//value\n", NULL,
                           NULL);
            }
            xmlRelaxNGCheckRules(ctxt, cur->content, flags, cur->type);
            ret = XML_RELAXNG_CONTENT_SIMPLE;
        } else if (cur->type == XML_RELAXNG_TEXT) {
            if (flags & XML_RELAXNG_IN_LIST) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_LIST_TEXT,
                           "Found forbidden pattern list//text\n", NULL,
                           NULL);
            }
            if (flags & XML_RELAXNG_IN_DATAEXCEPT) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_DATA_EXCEPT_TEXT,
                           "Found forbidden pattern data/except//text\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_START) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_START_TEXT,
                           "Found forbidden pattern start//text\n", NULL,
                           NULL);
            }
            ret = XML_RELAXNG_CONTENT_COMPLEX;
        } else if (cur->type == XML_RELAXNG_EMPTY) {
            if (flags & XML_RELAXNG_IN_DATAEXCEPT) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_DATA_EXCEPT_EMPTY,
                           "Found forbidden pattern data/except//empty\n",
                           NULL, NULL);
            }
            if (flags & XML_RELAXNG_IN_START) {
                xmlRngPErr(ctxt, cur->node, XML_RNGP_PAT_START_EMPTY,
                           "Found forbidden pattern start//empty\n", NULL,
                           NULL);
            }
            ret = XML_RELAXNG_CONTENT_EMPTY;
        } else if (cur->type == XML_RELAXNG_CHOICE) {
            xmlRelaxNGCheckChoiceDeterminism(ctxt, cur);
            ret =
                xmlRelaxNGCheckRules(ctxt, cur->content, flags, cur->type);
        } else {
            ret =
                xmlRelaxNGCheckRules(ctxt, cur->content, flags, cur->type);
        }
        cur = cur->next;
        if (ptype == XML_RELAXNG_GROUP) {
            val = xmlRelaxNGGroupContentType(val, ret);
        } else if (ptype == XML_RELAXNG_INTERLEAVE) {
            /*
             * TODO: scan complain that tmp is never used, seems on purpose
             *       need double-checking
             */
            tmp = xmlRelaxNGGroupContentType(val, ret);
            if (tmp != XML_RELAXNG_CONTENT_ERROR)
                tmp = xmlRelaxNGMaxContentType(val, ret);
        } else if (ptype == XML_RELAXNG_CHOICE) {
            val = xmlRelaxNGMaxContentType(val, ret);
        } else if (ptype == XML_RELAXNG_LIST) {
            val = XML_RELAXNG_CONTENT_SIMPLE;
        } else if (ptype == XML_RELAXNG_EXCEPT) {
            if (ret == XML_RELAXNG_CONTENT_ERROR)
                val = XML_RELAXNG_CONTENT_ERROR;
            else
                val = XML_RELAXNG_CONTENT_SIMPLE;
        } else {
            val = xmlRelaxNGGroupContentType(val, ret);
        }

    }
    return (val);
}

/**
 * xmlRelaxNGParseGrammar:
 * @ctxt:  a Relax-NG parser context
 * @nodes:  grammar children nodes
 *
 * parse a Relax-NG <grammar> node
 *
 * Returns the internal xmlRelaxNGGrammarPtr built or
 *         NULL in case of error
 */
static xmlRelaxNGGrammarPtr
xmlRelaxNGParseGrammar(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr nodes)
{
    xmlRelaxNGGrammarPtr ret, tmp, old;

#ifdef DEBUG_GRAMMAR
    xmlGenericError(xmlGenericErrorContext, "Parsing a new grammar\n");
#endif

    ret = xmlRelaxNGNewGrammar(ctxt);
    if (ret == NULL)
        return (NULL);

    /*
     * Link the new grammar in the tree
     */
    ret->parent = ctxt->grammar;
    if (ctxt->grammar != NULL) {
        tmp = ctxt->grammar->children;
        if (tmp == NULL) {
            ctxt->grammar->children = ret;
        } else {
            while (tmp->next != NULL)
                tmp = tmp->next;
            tmp->next = ret;
        }
    }

    old = ctxt->grammar;
    ctxt->grammar = ret;
    xmlRelaxNGParseGrammarContent(ctxt, nodes);
    ctxt->grammar = ret;
    if (ctxt->grammar == NULL) {
        xmlRngPErr(ctxt, nodes, XML_RNGP_GRAMMAR_CONTENT,
                   "Failed to parse <grammar> content\n", NULL, NULL);
    } else if (ctxt->grammar->start == NULL) {
        xmlRngPErr(ctxt, nodes, XML_RNGP_GRAMMAR_NO_START,
                   "Element <grammar> has no <start>\n", NULL, NULL);
    }

    /*
     * Apply 4.17 merging rules to defines and starts
     */
    xmlRelaxNGCombineStart(ctxt, ret);
    if (ret->defs != NULL) {
        xmlHashScan(ret->defs, (xmlHashScanner) xmlRelaxNGCheckCombine,
                    ctxt);
    }

    /*
     * link together defines and refs in this grammar
     */
    if (ret->refs != NULL) {
        xmlHashScan(ret->refs, (xmlHashScanner) xmlRelaxNGCheckReference,
                    ctxt);
    }


    /* @@@@ */

    ctxt->grammar = old;
    return (ret);
}

/**
 * xmlRelaxNGParseDocument:
 * @ctxt:  a Relax-NG parser context
 * @node:  the root node of the RelaxNG schema
 *
 * parse a Relax-NG definition resource and build an internal
 * xmlRelaxNG struture which can be used to validate instances.
 *
 * Returns the internal XML RelaxNG structure built or
 *         NULL in case of error
 */
static xmlRelaxNGPtr
xmlRelaxNGParseDocument(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlRelaxNGPtr schema = NULL;
    const xmlChar *olddefine;
    xmlRelaxNGGrammarPtr old;

    if ((ctxt == NULL) || (node == NULL))
        return (NULL);

    schema = xmlRelaxNGNewRelaxNG(ctxt);
    if (schema == NULL)
        return (NULL);

    olddefine = ctxt->define;
    ctxt->define = NULL;
    if (IS_RELAXNG(node, "grammar")) {
        schema->topgrammar = xmlRelaxNGParseGrammar(ctxt, node->children);
        if (schema->topgrammar == NULL) {
            xmlRelaxNGFree(schema);
            return (NULL);
        }
    } else {
        xmlRelaxNGGrammarPtr tmp, ret;

        schema->topgrammar = ret = xmlRelaxNGNewGrammar(ctxt);
        if (schema->topgrammar == NULL) {
            xmlRelaxNGFree(schema);
            return (NULL);
        }
        /*
         * Link the new grammar in the tree
         */
        ret->parent = ctxt->grammar;
        if (ctxt->grammar != NULL) {
            tmp = ctxt->grammar->children;
            if (tmp == NULL) {
                ctxt->grammar->children = ret;
            } else {
                while (tmp->next != NULL)
                    tmp = tmp->next;
                tmp->next = ret;
            }
        }
        old = ctxt->grammar;
        ctxt->grammar = ret;
        xmlRelaxNGParseStart(ctxt, node);
        if (old != NULL)
            ctxt->grammar = old;
    }
    ctxt->define = olddefine;
    if (schema->topgrammar->start != NULL) {
        xmlRelaxNGCheckCycles(ctxt, schema->topgrammar->start, 0);
        if ((ctxt->flags & XML_RELAXNG_IN_EXTERNALREF) == 0) {
            xmlRelaxNGSimplify(ctxt, schema->topgrammar->start, NULL);
            while ((schema->topgrammar->start != NULL) &&
                   (schema->topgrammar->start->type == XML_RELAXNG_NOOP) &&
                   (schema->topgrammar->start->next != NULL))
                schema->topgrammar->start =
                    schema->topgrammar->start->content;
            xmlRelaxNGCheckRules(ctxt, schema->topgrammar->start,
                                 XML_RELAXNG_IN_START, XML_RELAXNG_NOOP);
        }
    }
#ifdef DEBUG
    if (schema == NULL)
        xmlGenericError(xmlGenericErrorContext,
                        "xmlRelaxNGParseDocument() failed\n");
#endif

    return (schema);
}

/************************************************************************
 *									*
 *			Reading RelaxNGs				*
 *									*
 ************************************************************************/

/**
 * xmlRelaxNGNewParserCtxt:
 * @URL:  the location of the schema
 *
 * Create an XML RelaxNGs parse context for that file/resource expected
 * to contain an XML RelaxNGs file.
 *
 * Returns the parser context or NULL in case of error
 */
xmlRelaxNGParserCtxtPtr
xmlRelaxNGNewParserCtxt(const char *URL)
{
    xmlRelaxNGParserCtxtPtr ret;

    if (URL == NULL)
        return (NULL);

    ret =
        (xmlRelaxNGParserCtxtPtr) xmlMalloc(sizeof(xmlRelaxNGParserCtxt));
    if (ret == NULL) {
        xmlRngPErrMemory(NULL, "building parser\n");
        return (NULL);
    }
    memset(ret, 0, sizeof(xmlRelaxNGParserCtxt));
    ret->URL = xmlStrdup((const xmlChar *) URL);
    ret->error = xmlGenericError;
    ret->userData = xmlGenericErrorContext;
    return (ret);
}

/**
 * xmlRelaxNGNewMemParserCtxt:
 * @buffer:  a pointer to a char array containing the schemas
 * @size:  the size of the array
 *
 * Create an XML RelaxNGs parse context for that memory buffer expected
 * to contain an XML RelaxNGs file.
 *
 * Returns the parser context or NULL in case of error
 */
xmlRelaxNGParserCtxtPtr
xmlRelaxNGNewMemParserCtxt(const char *buffer, int size)
{
    xmlRelaxNGParserCtxtPtr ret;

    if ((buffer == NULL) || (size <= 0))
        return (NULL);

    ret =
        (xmlRelaxNGParserCtxtPtr) xmlMalloc(sizeof(xmlRelaxNGParserCtxt));
    if (ret == NULL) {
        xmlRngPErrMemory(NULL, "building parser\n");
        return (NULL);
    }
    memset(ret, 0, sizeof(xmlRelaxNGParserCtxt));
    ret->buffer = buffer;
    ret->size = size;
    ret->error = xmlGenericError;
    ret->userData = xmlGenericErrorContext;
    return (ret);
}

/**
 * xmlRelaxNGNewDocParserCtxt:
 * @doc:  a preparsed document tree
 *
 * Create an XML RelaxNGs parser context for that document.
 * Note: since the process of compiling a RelaxNG schemas modifies the
 *       document, the @doc parameter is duplicated internally.
 *
 * Returns the parser context or NULL in case of error
 */
xmlRelaxNGParserCtxtPtr
xmlRelaxNGNewDocParserCtxt(xmlDocPtr doc)
{
    xmlRelaxNGParserCtxtPtr ret;
    xmlDocPtr copy;

    if (doc == NULL)
        return (NULL);
    copy = xmlCopyDoc(doc, 1);
    if (copy == NULL)
        return (NULL);

    ret =
        (xmlRelaxNGParserCtxtPtr) xmlMalloc(sizeof(xmlRelaxNGParserCtxt));
    if (ret == NULL) {
        xmlRngPErrMemory(NULL, "building parser\n");
        return (NULL);
    }
    memset(ret, 0, sizeof(xmlRelaxNGParserCtxt));
    ret->document = copy;
    ret->freedoc = 1;
    ret->userData = xmlGenericErrorContext;
    return (ret);
}

/**
 * xmlRelaxNGFreeParserCtxt:
 * @ctxt:  the schema parser context
 *
 * Free the resources associated to the schema parser context
 */
void
xmlRelaxNGFreeParserCtxt(xmlRelaxNGParserCtxtPtr ctxt)
{
    if (ctxt == NULL)
        return;
    if (ctxt->URL != NULL)
        xmlFree(ctxt->URL);
    if (ctxt->doc != NULL)
        xmlRelaxNGFreeDocument(ctxt->doc);
    if (ctxt->interleaves != NULL)
        xmlHashFree(ctxt->interleaves, NULL);
    if (ctxt->documents != NULL)
        xmlRelaxNGFreeDocumentList(ctxt->documents);
    if (ctxt->includes != NULL)
        xmlRelaxNGFreeIncludeList(ctxt->includes);
    if (ctxt->docTab != NULL)
        xmlFree(ctxt->docTab);
    if (ctxt->incTab != NULL)
        xmlFree(ctxt->incTab);
    if (ctxt->defTab != NULL) {
        int i;

        for (i = 0; i < ctxt->defNr; i++)
            xmlRelaxNGFreeDefine(ctxt->defTab[i]);
        xmlFree(ctxt->defTab);
    }
    if ((ctxt->document != NULL) && (ctxt->freedoc))
        xmlFreeDoc(ctxt->document);
    xmlFree(ctxt);
}

/**
 * xmlRelaxNGNormExtSpace:
 * @value:  a value
 *
 * Removes the leading and ending spaces of the value
 * The string is modified "in situ"
 */
static void
xmlRelaxNGNormExtSpace(xmlChar * value)
{
    xmlChar *start = value;
    xmlChar *cur = value;

    if (value == NULL)
        return;

    while (IS_BLANK_CH(*cur))
        cur++;
    if (cur == start) {
        do {
            while ((*cur != 0) && (!IS_BLANK_CH(*cur)))
                cur++;
            if (*cur == 0)
                return;
            start = cur;
            while (IS_BLANK_CH(*cur))
                cur++;
            if (*cur == 0) {
                *start = 0;
                return;
            }
        } while (1);
    } else {
        do {
            while ((*cur != 0) && (!IS_BLANK_CH(*cur)))
                *start++ = *cur++;
            if (*cur == 0) {
                *start = 0;
                return;
            }
            /* don't try to normalize the inner spaces */
            while (IS_BLANK_CH(*cur))
                cur++;
            if (*cur == 0) {
                *start = 0;
                return;
            }
            *start++ = *cur++;
        } while (1);
    }
}

/**
 * xmlRelaxNGCleanupAttributes:
 * @ctxt:  a Relax-NG parser context
 * @node:  a Relax-NG node
 *
 * Check all the attributes on the given node
 */
static void
xmlRelaxNGCleanupAttributes(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr node)
{
    xmlAttrPtr cur, next;

    cur = node->properties;
    while (cur != NULL) {
        next = cur->next;
        if ((cur->ns == NULL) ||
            (xmlStrEqual(cur->ns->href, xmlRelaxNGNs))) {
            if (xmlStrEqual(cur->name, BAD_CAST "name")) {
                if ((!xmlStrEqual(node->name, BAD_CAST "element")) &&
                    (!xmlStrEqual(node->name, BAD_CAST "attribute")) &&
                    (!xmlStrEqual(node->name, BAD_CAST "ref")) &&
                    (!xmlStrEqual(node->name, BAD_CAST "parentRef")) &&
                    (!xmlStrEqual(node->name, BAD_CAST "param")) &&
                    (!xmlStrEqual(node->name, BAD_CAST "define"))) {
                    xmlRngPErr(ctxt, node, XML_RNGP_FORBIDDEN_ATTRIBUTE,
                               "Attribute %s is not allowed on %s\n",
                               cur->name, node->name);
                }
            } else if (xmlStrEqual(cur->name, BAD_CAST "type")) {
                if ((!xmlStrEqual(node->name, BAD_CAST "value")) &&
                    (!xmlStrEqual(node->name, BAD_CAST "data"))) {
                    xmlRngPErr(ctxt, node, XML_RNGP_FORBIDDEN_ATTRIBUTE,
                               "Attribute %s is not allowed on %s\n",
                               cur->name, node->name);
                }
            } else if (xmlStrEqual(cur->name, BAD_CAST "href")) {
                if ((!xmlStrEqual(node->name, BAD_CAST "externalRef")) &&
                    (!xmlStrEqual(node->name, BAD_CAST "include"))) {
                    xmlRngPErr(ctxt, node, XML_RNGP_FORBIDDEN_ATTRIBUTE,
                               "Attribute %s is not allowed on %s\n",
                               cur->name, node->name);
                }
            } else if (xmlStrEqual(cur->name, BAD_CAST "combine")) {
                if ((!xmlStrEqual(node->name, BAD_CAST "start")) &&
                    (!xmlStrEqual(node->name, BAD_CAST "define"))) {
                    xmlRngPErr(ctxt, node, XML_RNGP_FORBIDDEN_ATTRIBUTE,
                               "Attribute %s is not allowed on %s\n",
                               cur->name, node->name);
                }
            } else if (xmlStrEqual(cur->name, BAD_CAST "datatypeLibrary")) {
                xmlChar *val;
                xmlURIPtr uri;

                val = xmlNodeListGetString(node->doc, cur->children, 1);
                if (val != NULL) {
                    if (val[0] != 0) {
                        uri = xmlParseURI((const char *) val);
                        if (uri == NULL) {
                            xmlRngPErr(ctxt, node, XML_RNGP_INVALID_URI,
                                       "Attribute %s contains invalid URI %s\n",
                                       cur->name, val);
                        } else {
                            if (uri->scheme == NULL) {
                                xmlRngPErr(ctxt, node, XML_RNGP_URI_NOT_ABSOLUTE,
                                           "Attribute %s URI %s is not absolute\n",
                                           cur->name, val);
                            }
                            if (uri->fragment != NULL) {
                                xmlRngPErr(ctxt, node, XML_RNGP_URI_FRAGMENT,
                                           "Attribute %s URI %s has a fragment ID\n",
                                           cur->name, val);
                            }
                            xmlFreeURI(uri);
                        }
                    }
                    xmlFree(val);
                }
            } else if (!xmlStrEqual(cur->name, BAD_CAST "ns")) {
                xmlRngPErr(ctxt, node, XML_RNGP_UNKNOWN_ATTRIBUTE,
                           "Unknown attribute %s on %s\n", cur->name,
                           node->name);
            }
        }
        cur = next;
    }
}

/**
 * xmlRelaxNGCleanupTree:
 * @ctxt:  a Relax-NG parser context
 * @root:  an xmlNodePtr subtree
 *
 * Cleanup the subtree from unwanted nodes for parsing, resolve
 * Include and externalRef lookups.
 */
static void
xmlRelaxNGCleanupTree(xmlRelaxNGParserCtxtPtr ctxt, xmlNodePtr root)
{
    xmlNodePtr cur, delete;

    delete = NULL;
    cur = root;
    while (cur != NULL) {
        if (delete != NULL) {
            xmlUnlinkNode(delete);
            xmlFreeNode(delete);
            delete = NULL;
        }
        if (cur->type == XML_ELEMENT_NODE) {
            /*
             * Simplification 4.1. Annotations
             */
            if ((cur->ns == NULL) ||
                (!xmlStrEqual(cur->ns->href, xmlRelaxNGNs))) {
                if ((cur->parent != NULL) &&
                    (cur->parent->type == XML_ELEMENT_NODE) &&
                    ((xmlStrEqual(cur->parent->name, BAD_CAST "name")) ||
                     (xmlStrEqual(cur->parent->name, BAD_CAST "value")) ||
                     (xmlStrEqual(cur->parent->name, BAD_CAST "param")))) {
                    xmlRngPErr(ctxt, cur, XML_RNGP_FOREIGN_ELEMENT,
                               "element %s doesn't allow foreign elements\n",
                               cur->parent->name, NULL);
                }
                delete = cur;
                goto skip_children;
            } else {
                xmlRelaxNGCleanupAttributes(ctxt, cur);
                if (xmlStrEqual(cur->name, BAD_CAST "externalRef")) {
                    xmlChar *href, *ns, *base, *URL;
                    xmlRelaxNGDocumentPtr docu;
                    xmlNodePtr tmp;
		    xmlURIPtr uri;

                    ns = xmlGetProp(cur, BAD_CAST "ns");
                    if (ns == NULL) {
                        tmp = cur->parent;
                        while ((tmp != NULL) &&
                               (tmp->type == XML_ELEMENT_NODE)) {
                            ns = xmlGetProp(tmp, BAD_CAST "ns");
                            if (ns != NULL)
                                break;
                            tmp = tmp->parent;
                        }
                    }
                    href = xmlGetProp(cur, BAD_CAST "href");
                    if (href == NULL) {
                        xmlRngPErr(ctxt, cur, XML_RNGP_MISSING_HREF,
                                   "xmlRelaxNGParse: externalRef has no href attribute\n",
                                   NULL, NULL);
                        if (ns != NULL)
                            xmlFree(ns);
                        delete = cur;
                        goto skip_children;
                    }
		    uri = xmlParseURI((const char *) href);
		    if (uri == NULL) {
                        xmlRngPErr(ctxt, cur, XML_RNGP_HREF_ERROR,
                                   "Incorrect URI for externalRef %s\n",
                                   href, NULL);
                        if (ns != NULL)
                            xmlFree(ns);
                        if (href != NULL)
                            xmlFree(href);
                        delete = cur;
                        goto skip_children;
		    }
		    if (uri->fragment != NULL) {
                        xmlRngPErr(ctxt, cur, XML_RNGP_HREF_ERROR,
			       "Fragment forbidden in URI for externalRef %s\n",
                                   href, NULL);
                        if (ns != NULL)
                            xmlFree(ns);
		        xmlFreeURI(uri);
                        if (href != NULL)
                            xmlFree(href);
                        delete = cur;
                        goto skip_children;
		    }
		    xmlFreeURI(uri);
                    base = xmlNodeGetBase(cur->doc, cur);
                    URL = xmlBuildURI(href, base);
                    if (URL == NULL) {
                        xmlRngPErr(ctxt, cur, XML_RNGP_HREF_ERROR,
                                   "Failed to compute URL for externalRef %s\n",
                                   href, NULL);
                        if (ns != NULL)
                            xmlFree(ns);
                        if (href != NULL)
                            xmlFree(href);
                        if (base != NULL)
                            xmlFree(base);
                        delete = cur;
                        goto skip_children;
                    }
                    if (href != NULL)
                        xmlFree(href);
                    if (base != NULL)
                        xmlFree(base);
                    docu = xmlRelaxNGLoadExternalRef(ctxt, URL, ns);
                    if (docu == NULL) {
                        xmlRngPErr(ctxt, cur, XML_RNGP_EXTERNAL_REF_FAILURE,
                                   "Failed to load externalRef %s\n", URL,
                                   NULL);
                        if (ns != NULL)
                            xmlFree(ns);
                        xmlFree(URL);
                        delete = cur;
                        goto skip_children;
                    }
                    if (ns != NULL)
                        xmlFree(ns);
                    xmlFree(URL);
                    cur->psvi = docu;
                } else if (xmlStrEqual(cur->name, BAD_CAST "include")) {
                    xmlChar *href, *ns, *base, *URL;
                    xmlRelaxNGIncludePtr incl;
                    xmlNodePtr tmp;

                    href = xmlGetProp(cur, BAD_CAST "href");
                    if (href == NULL) {
                        xmlRngPErr(ctxt, cur, XML_RNGP_MISSING_HREF,
                                   "xmlRelaxNGParse: include has no href attribute\n",
                                   NULL, NULL);
                        delete = cur;
                        goto skip_children;
                    }
                    base = xmlNodeGetBase(cur->doc, cur);
                    URL = xmlBuildURI(href, base);
                    if (URL == NULL) {
                        xmlRngPErr(ctxt, cur, XML_RNGP_HREF_ERROR,
                                   "Failed to compute URL for include %s\n",
                                   href, NULL);
                        if (href != NULL)
                            xmlFree(href);
                        if (base != NULL)
                            xmlFree(base);
                        delete = cur;
                        goto skip_children;
                    }
                    if (href != NULL)
                        xmlFree(href);
                    if (base != NULL)
                        xmlFree(base);
                    ns = xmlGetProp(cur, BAD_CAST "ns");
                    if (ns == NULL) {
                        tmp = cur->parent;
                        while ((tmp != NULL) &&
                               (tmp->type == XML_ELEMENT_NODE)) {
                            ns = xmlGetProp(tmp, BAD_CAST "ns");
                            if (ns != NULL)
                                break;
                            tmp = tmp->parent;
                        }
                    }
                    incl = xmlRelaxNGLoadInclude(ctxt, URL, cur, ns);
                    if (ns != NULL)
                        xmlFree(ns);
                    if (incl == NULL) {
                        xmlRngPErr(ctxt, cur, XML_RNGP_INCLUDE_FAILURE,
                                   "Failed to load include %s\n", URL,
                                   NULL);
                        xmlFree(URL);
                        delete = cur;
                        goto skip_children;
                    }
                    xmlFree(URL);
                    cur->psvi = incl;
                } else if ((xmlStrEqual(cur->name, BAD_CAST "element")) ||
                           (xmlStrEqual(cur->name, BAD_CAST "attribute")))
                {
                    xmlChar *name, *ns;
                    xmlNodePtr text = NULL;

                    /*
                     * Simplification 4.8. name attribute of element
                     * and attribute elements
                     */
                    name = xmlGetProp(cur, BAD_CAST "name");
                    if (name != NULL) {
                        if (cur->children == NULL) {
                            text =
                                xmlNewChild(cur, cur->ns, BAD_CAST "name",
                                            name);
                        } else {
                            xmlNodePtr node;

                            node = xmlNewDocNode(cur->doc, cur->ns,
			                         BAD_CAST "name", NULL);
                            if (node != NULL) {
                                xmlAddPrevSibling(cur->children, node);
                                text = xmlNewText(name);
                                xmlAddChild(node, text);
                                text = node;
                            }
                        }
                        if (text == NULL) {
                            xmlRngPErr(ctxt, cur, XML_RNGP_CREATE_FAILURE,
                                       "Failed to create a name %s element\n",
                                       name, NULL);
                        }
                        xmlUnsetProp(cur, BAD_CAST "name");
                        xmlFree(name);
                        ns = xmlGetProp(cur, BAD_CAST "ns");
                        if (ns != NULL) {
                            if (text != NULL) {
                                xmlSetProp(text, BAD_CAST "ns", ns);
                                /* xmlUnsetProp(cur, BAD_CAST "ns"); */
                            }
                            xmlFree(ns);
                        } else if (xmlStrEqual(cur->name,
                                               BAD_CAST "attribute")) {
                            xmlSetProp(text, BAD_CAST "ns", BAD_CAST "");
                        }
                    }
                } else if ((xmlStrEqual(cur->name, BAD_CAST "name")) ||
                           (xmlStrEqual(cur->name, BAD_CAST "nsName")) ||
                           (xmlStrEqual(cur->name, BAD_CAST "value"))) {
                    /*
                     * Simplification 4.8. name attribute of element
                     * and attribute elements
                     */
                    if (xmlHasProp(cur, BAD_CAST "ns") == NULL) {
                        xmlNodePtr node;
                        xmlChar *ns = NULL;

                        node = cur->parent;
                        while ((node != NULL) &&
                               (node->type == XML_ELEMENT_NODE)) {
                            ns = xmlGetProp(node, BAD_CAST "ns");
                            if (ns != NULL) {
                                break;
                            }
                            node = node->parent;
                        }
                        if (ns == NULL) {
                            xmlSetProp(cur, BAD_CAST "ns", BAD_CAST "");
                        } else {
                            xmlSetProp(cur, BAD_CAST "ns", ns);
                            xmlFree(ns);
                        }
                    }
                    if (xmlStrEqual(cur->name, BAD_CAST "name")) {
                        xmlChar *name, *local, *prefix;

                        /*
                         * Simplification: 4.10. QNames
                         */
                        name = xmlNodeGetContent(cur);
                        if (name != NULL) {
                            local = xmlSplitQName2(name, &prefix);
                            if (local != NULL) {
                                xmlNsPtr ns;

                                ns = xmlSearchNs(cur->doc, cur, prefix);
                                if (ns == NULL) {
                                    xmlRngPErr(ctxt, cur,
                                               XML_RNGP_PREFIX_UNDEFINED,
                                               "xmlRelaxNGParse: no namespace for prefix %s\n",
                                               prefix, NULL);
                                } else {
                                    xmlSetProp(cur, BAD_CAST "ns",
                                               ns->href);
                                    xmlNodeSetContent(cur, local);
                                }
                                xmlFree(local);
                                xmlFree(prefix);
                            }
                            xmlFree(name);
                        }
                    }
                    /*
                     * 4.16
                     */
                    if (xmlStrEqual(cur->name, BAD_CAST "nsName")) {
                        if (ctxt->flags & XML_RELAXNG_IN_NSEXCEPT) {
                            xmlRngPErr(ctxt, cur,
                                       XML_RNGP_PAT_NSNAME_EXCEPT_NSNAME,
                                       "Found nsName/except//nsName forbidden construct\n",
                                       NULL, NULL);
                        }
                    }
                } else if ((xmlStrEqual(cur->name, BAD_CAST "except")) &&
                           (cur != root)) {
                    int oldflags = ctxt->flags;

                    /*
                     * 4.16
                     */
                    if ((cur->parent != NULL) &&
                        (xmlStrEqual
                         (cur->parent->name, BAD_CAST "anyName"))) {
                        ctxt->flags |= XML_RELAXNG_IN_ANYEXCEPT;
                        xmlRelaxNGCleanupTree(ctxt, cur);
                        ctxt->flags = oldflags;
                        goto skip_children;
                    } else if ((cur->parent != NULL) &&
                               (xmlStrEqual
                                (cur->parent->name, BAD_CAST "nsName"))) {
                        ctxt->flags |= XML_RELAXNG_IN_NSEXCEPT;
                        xmlRelaxNGCleanupTree(ctxt, cur);
                        ctxt->flags = oldflags;
                        goto skip_children;
                    }
                } else if (xmlStrEqual(cur->name, BAD_CAST "anyName")) {
                    /*
                     * 4.16
                     */
                    if (ctxt->flags & XML_RELAXNG_IN_ANYEXCEPT) {
                        xmlRngPErr(ctxt, cur,
                                   XML_RNGP_PAT_ANYNAME_EXCEPT_ANYNAME,
                                   "Found anyName/except//anyName forbidden construct\n",
                                   NULL, NULL);
                    } else if (ctxt->flags & XML_RELAXNG_IN_NSEXCEPT) {
                        xmlRngPErr(ctxt, cur,
                                   XML_RNGP_PAT_NSNAME_EXCEPT_ANYNAME,
                                   "Found nsName/except//anyName forbidden construct\n",
                                   NULL, NULL);
                    }
                }
                /*
                 * This is not an else since "include" is transformed
                 * into a div
                 */
                if (xmlStrEqual(cur->name, BAD_CAST "div")) {
                    xmlChar *ns;
                    xmlNodePtr child, ins, tmp;

                    /*
                     * implements rule 4.11
                     */

                    ns = xmlGetProp(cur, BAD_CAST "ns");

                    child = cur->children;
                    ins = cur;
                    while (child != NULL) {
                        if (ns != NULL) {
                            if (!xmlHasProp(child, BAD_CAST "ns")) {
                                xmlSetProp(child, BAD_CAST "ns", ns);
                            }
                        }
                        tmp = child->next;
                        xmlUnlinkNode(child);
                        ins = xmlAddNextSibling(ins, child);
                        child = tmp;
                    }
                    if (ns != NULL)
                        xmlFree(ns);
		    /*
		     * Since we are about to delete cur, if its nsDef is non-NULL we
		     * need to preserve it (it contains the ns definitions for the
		     * children we just moved).  We'll just stick it on to the end
		     * of cur->parent's list, since it's never going to be re-serialized
		     * (bug 143738).
		     */
		    if ((cur->nsDef != NULL) && (cur->parent != NULL)) {
			xmlNsPtr parDef = (xmlNsPtr)&cur->parent->nsDef;
			while (parDef->next != NULL)
			    parDef = parDef->next;
			parDef->next = cur->nsDef;
			cur->nsDef = NULL;
		    }
                    delete = cur;
                    goto skip_children;
                }
            }
        }
        /*
         * Simplification 4.2 whitespaces
         */
        else if ((cur->type == XML_TEXT_NODE) ||
                 (cur->type == XML_CDATA_SECTION_NODE)) {
            if (IS_BLANK_NODE(cur)) {
                if ((cur->parent != NULL) &&
		    (cur->parent->type == XML_ELEMENT_NODE)) {
                    if ((!xmlStrEqual(cur->parent->name, BAD_CAST "value"))
                        &&
                        (!xmlStrEqual
                         (cur->parent->name, BAD_CAST "param")))
                        delete = cur;
                } else {
                    delete = cur;
                    goto skip_children;
                }
            }
        } else {
            delete = cur;
            goto skip_children;
        }

        /*
         * Skip to next node
         */
        if (cur->children != NULL) {
            if ((cur->children->type != XML_ENTITY_DECL) &&
                (cur->children->type != XML_ENTITY_REF_NODE) &&
                (cur->children->type != XML_ENTITY_NODE)) {
                cur = cur->children;
                continue;
            }
        }
      skip_children:
        if (cur->next != NULL) {
            cur = cur->next;
            continue;
        }

        do {
            cur = cur->parent;
            if (cur == NULL)
                break;
            if (cur == root) {
                cur = NULL;
                break;
            }
            if (cur->next != NULL) {
                cur = cur->next;
                break;
            }
        } while (cur != NULL);
    }
    if (delete != NULL) {
        xmlUnlinkNode(delete);
        xmlFreeNode(delete);
        delete = NULL;
    }
}

/**
 * xmlRelaxNGCleanupDoc:
 * @ctxt:  a Relax-NG parser context
 * @doc:  an xmldocPtr document pointer
 *
 * Cleanup the document from unwanted nodes for parsing, resolve
 * Include and externalRef lookups.
 *
 * Returns the cleaned up document or NULL in case of error
 */
static xmlDocPtr
xmlRelaxNGCleanupDoc(xmlRelaxNGParserCtxtPtr ctxt, xmlDocPtr doc)
{
    xmlNodePtr root;

    /*
     * Extract the root
     */
    root = xmlDocGetRootElement(doc);
    if (root == NULL) {
        xmlRngPErr(ctxt, (xmlNodePtr) doc, XML_RNGP_EMPTY, "xmlRelaxNGParse: %s is empty\n",
                   ctxt->URL, NULL);
        return (NULL);
    }
    xmlRelaxNGCleanupTree(ctxt, root);
    return (doc);
}

/**
 * xmlRelaxNGParse:
 * @ctxt:  a Relax-NG parser context
 *
 * parse a schema definition resource and build an internal
 * XML Shema struture which can be used to validate instances.
 *
 * Returns the internal XML RelaxNG structure built from the resource or
 *         NULL in case of error
 */
xmlRelaxNGPtr
xmlRelaxNGParse(xmlRelaxNGParserCtxtPtr ctxt)
{
    xmlRelaxNGPtr ret = NULL;
    xmlDocPtr doc;
    xmlNodePtr root;

    xmlRelaxNGInitTypes();

    if (ctxt == NULL)
        return (NULL);

    /*
     * First step is to parse the input document into an DOM/Infoset
     */
    if (ctxt->URL != NULL) {
        doc = xmlReadFile((const char *) ctxt->URL,NULL,0);
        if (doc == NULL) {
            xmlRngPErr(ctxt, NULL, XML_RNGP_PARSE_ERROR,
                       "xmlRelaxNGParse: could not load %s\n", ctxt->URL,
                       NULL);
            return (NULL);
        }
    } else if (ctxt->buffer != NULL) {
        doc = xmlReadMemory(ctxt->buffer, ctxt->size,NULL,NULL,0);
        if (doc == NULL) {
            xmlRngPErr(ctxt, NULL, XML_RNGP_PARSE_ERROR,
                       "xmlRelaxNGParse: could not parse schemas\n", NULL,
                       NULL);
            return (NULL);
        }
        doc->URL = xmlStrdup(BAD_CAST "in_memory_buffer");
        ctxt->URL = xmlStrdup(BAD_CAST "in_memory_buffer");
    } else if (ctxt->document != NULL) {
        doc = ctxt->document;
    } else {
        xmlRngPErr(ctxt, NULL, XML_RNGP_EMPTY,
                   "xmlRelaxNGParse: nothing to parse\n", NULL, NULL);
        return (NULL);
    }
    ctxt->document = doc;

    /*
     * Some preprocessing of the document content
     */
    doc = xmlRelaxNGCleanupDoc(ctxt, doc);
    if (doc == NULL) {
        xmlFreeDoc(ctxt->document);
        ctxt->document = NULL;
        return (NULL);
    }

    /*
     * Then do the parsing for good
     */
    root = xmlDocGetRootElement(doc);
    if (root == NULL) {
        xmlRngPErr(ctxt, (xmlNodePtr) doc,
	           XML_RNGP_EMPTY, "xmlRelaxNGParse: %s is empty\n",
                   (ctxt->URL ? ctxt->URL : BAD_CAST "schemas"), NULL);

        xmlFreeDoc(ctxt->document);
        ctxt->document = NULL;
        return (NULL);
    }
    ret = xmlRelaxNGParseDocument(ctxt, root);
    if (ret == NULL) {
        xmlFreeDoc(ctxt->document);
        ctxt->document = NULL;
        return (NULL);
    }

    /*
     * Check the ref/defines links
     */
    /*
     * try to preprocess interleaves
     */
    if (ctxt->interleaves != NULL) {
        xmlHashScan(ctxt->interleaves,
                    (xmlHashScanner) xmlRelaxNGComputeInterleaves, ctxt);
    }

    /*
     * if there was a parsing error return NULL
     */
    if (ctxt->nbErrors > 0) {
        xmlRelaxNGFree(ret);
        ctxt->document = NULL;
        xmlFreeDoc(doc);
        return (NULL);
    }

    /*
     * try to compile (parts of) the schemas
     */
    if ((ret->topgrammar != NULL) && (ret->topgrammar->start != NULL)) {
        if (ret->topgrammar->start->type != XML_RELAXNG_START) {
            xmlRelaxNGDefinePtr def;

            def = xmlRelaxNGNewDefine(ctxt, NULL);
            if (def != NULL) {
                def->type = XML_RELAXNG_START;
                def->content = ret->topgrammar->start;
                ret->topgrammar->start = def;
            }
        }
        xmlRelaxNGTryCompile(ctxt, ret->topgrammar->start);
    }

    /*
     * Transfer the pointer for cleanup at the schema level.
     */
    ret->doc = doc;
    ctxt->document = NULL;
    ret->documents = ctxt->documents;
    ctxt->documents = NULL;

    ret->includes = ctxt->includes;
    ctxt->includes = NULL;
    ret->defNr = ctxt->defNr;
    ret->defTab = ctxt->defTab;
    ctxt->defTab = NULL;
    if (ctxt->idref == 1)
        ret->idref = 1;

    return (ret);
}

/**
 * xmlRelaxNGSetParserErrors:
 * @ctxt:  a Relax-NG validation context
 * @err:  the error callback
 * @warn:  the warning callback
 * @ctx:  contextual data for the callbacks
 *
 * Set the callback functions used to handle errors for a validation context
 */
void
xmlRelaxNGSetParserErrors(xmlRelaxNGParserCtxtPtr ctxt,
                          xmlRelaxNGValidityErrorFunc err,
                          xmlRelaxNGValidityWarningFunc warn, void *ctx)
{
    if (ctxt == NULL)
        return;
    ctxt->error = err;
    ctxt->warning = warn;
    ctxt->serror = NULL;
    ctxt->userData = ctx;
}

/**
 * xmlRelaxNGGetParserErrors:
 * @ctxt:  a Relax-NG validation context
 * @err:  the error callback result
 * @warn:  the warning callback result
 * @ctx:  contextual data for the callbacks result
 *
 * Get the callback information used to handle errors for a validation context
 *
 * Returns -1 in case of failure, 0 otherwise.
 */
int
xmlRelaxNGGetParserErrors(xmlRelaxNGParserCtxtPtr ctxt,
                          xmlRelaxNGValidityErrorFunc * err,
                          xmlRelaxNGValidityWarningFunc * warn, void **ctx)
{
    if (ctxt == NULL)
        return (-1);
    if (err != NULL)
        *err = ctxt->error;
    if (warn != NULL)
        *warn = ctxt->warning;
    if (ctx != NULL)
        *ctx = ctxt->userData;
    return (0);
}

/**
 * xmlRelaxNGSetParserStructuredErrors:
 * @ctxt:  a Relax-NG parser context
 * @serror:  the error callback
 * @ctx:  contextual data for the callbacks
 *
 * Set the callback functions used to handle errors for a parsing context
 */
void
xmlRelaxNGSetParserStructuredErrors(xmlRelaxNGParserCtxtPtr ctxt,
				    xmlStructuredErrorFunc serror,
				    void *ctx)
{
    if (ctxt == NULL)
        return;
    ctxt->serror = serror;
    ctxt->error = NULL;
    ctxt->warning = NULL;
    ctxt->userData = ctx;
}

#ifdef LIBXML_OUTPUT_ENABLED

/************************************************************************
 *									*
 *			Dump back a compiled form			*
 *									*
 ************************************************************************/
static void xmlRelaxNGDumpDefine(FILE * output,
                                 xmlRelaxNGDefinePtr define);

/**
 * xmlRelaxNGDumpDefines:
 * @output:  the file output
 * @defines:  a list of define structures
 *
 * Dump a RelaxNG structure back
 */
static void
xmlRelaxNGDumpDefines(FILE * output, xmlRelaxNGDefinePtr defines)
{
    while (defines != NULL) {
        xmlRelaxNGDumpDefine(output, defines);
        defines = defines->next;
    }
}

/**
 * xmlRelaxNGDumpDefine:
 * @output:  the file output
 * @define:  a define structure
 *
 * Dump a RelaxNG structure back
 */
static void
xmlRelaxNGDumpDefine(FILE * output, xmlRelaxNGDefinePtr define)
{
    if (define == NULL)
        return;
    switch (define->type) {
        case XML_RELAXNG_EMPTY:
            fprintf(output, "<empty/>\n");
            break;
        case XML_RELAXNG_NOT_ALLOWED:
            fprintf(output, "<notAllowed/>\n");
            break;
        case XML_RELAXNG_TEXT:
            fprintf(output, "<text/>\n");
            break;
        case XML_RELAXNG_ELEMENT:
            fprintf(output, "<element>\n");
            if (define->name != NULL) {
                fprintf(output, "<name");
                if (define->ns != NULL)
                    fprintf(output, " ns=\"%s\"", define->ns);
                fprintf(output, ">%s</name>\n", define->name);
            }
            xmlRelaxNGDumpDefines(output, define->attrs);
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</element>\n");
            break;
        case XML_RELAXNG_LIST:
            fprintf(output, "<list>\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</list>\n");
            break;
        case XML_RELAXNG_ONEORMORE:
            fprintf(output, "<oneOrMore>\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</oneOrMore>\n");
            break;
        case XML_RELAXNG_ZEROORMORE:
            fprintf(output, "<zeroOrMore>\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</zeroOrMore>\n");
            break;
        case XML_RELAXNG_CHOICE:
            fprintf(output, "<choice>\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</choice>\n");
            break;
        case XML_RELAXNG_GROUP:
            fprintf(output, "<group>\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</group>\n");
            break;
        case XML_RELAXNG_INTERLEAVE:
            fprintf(output, "<interleave>\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</interleave>\n");
            break;
        case XML_RELAXNG_OPTIONAL:
            fprintf(output, "<optional>\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</optional>\n");
            break;
        case XML_RELAXNG_ATTRIBUTE:
            fprintf(output, "<attribute>\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</attribute>\n");
            break;
        case XML_RELAXNG_DEF:
            fprintf(output, "<define");
            if (define->name != NULL)
                fprintf(output, " name=\"%s\"", define->name);
            fprintf(output, ">\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</define>\n");
            break;
        case XML_RELAXNG_REF:
            fprintf(output, "<ref");
            if (define->name != NULL)
                fprintf(output, " name=\"%s\"", define->name);
            fprintf(output, ">\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</ref>\n");
            break;
        case XML_RELAXNG_PARENTREF:
            fprintf(output, "<parentRef");
            if (define->name != NULL)
                fprintf(output, " name=\"%s\"", define->name);
            fprintf(output, ">\n");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</parentRef>\n");
            break;
        case XML_RELAXNG_EXTERNALREF:
            fprintf(output, "<externalRef>");
            xmlRelaxNGDumpDefines(output, define->content);
            fprintf(output, "</externalRef>\n");
            break;
        case XML_RELAXNG_DATATYPE:
        case XML_RELAXNG_VALUE:
            TODO break;
        case XML_RELAXNG_START:
        case XML_RELAXNG_EXCEPT:
        case XML_RELAXNG_PARAM:
            TODO break;
        case XML_RELAXNG_NOOP:
            xmlRelaxNGDumpDefines(output, define->content);
            break;
    }
}

/**
 * xmlRelaxNGDumpGrammar:
 * @output:  the file output
 * @grammar:  a grammar structure
 * @top:  is this a top grammar
 *
 * Dump a RelaxNG structure back
 */
static void
xmlRelaxNGDumpGrammar(FILE * output, xmlRelaxNGGrammarPtr grammar, int top)
{
    if (grammar == NULL)
        return;

    fprintf(output, "<grammar");
    if (top)
        fprintf(output, " xmlns=\"http://relaxng.org/ns/structure/1.0\"");
    switch (grammar->combine) {
        case XML_RELAXNG_COMBINE_UNDEFINED:
            break;
        case XML_RELAXNG_COMBINE_CHOICE:
            fprintf(output, " combine=\"choice\"");
            break;
        case XML_RELAXNG_COMBINE_INTERLEAVE:
            fprintf(output, " combine=\"interleave\"");
            break;
        default:
            fprintf(output, " <!-- invalid combine value -->");
    }
    fprintf(output, ">\n");
    if (grammar->start == NULL) {
        fprintf(output, " <!-- grammar had no start -->");
    } else {
        fprintf(output, "<start>\n");
        xmlRelaxNGDumpDefine(output, grammar->start);
        fprintf(output, "</start>\n");
    }
    /* TODO ? Dump the defines ? */
    fprintf(output, "</grammar>\n");
}

/**
 * xmlRelaxNGDump:
 * @output:  the file output
 * @schema:  a schema structure
 *
 * Dump a RelaxNG structure back
 */
void
xmlRelaxNGDump(FILE * output, xmlRelaxNGPtr schema)
{
    if (output == NULL)
        return;
    if (schema == NULL) {
        fprintf(output, "RelaxNG empty or failed to compile\n");
        return;
    }
    fprintf(output, "RelaxNG: ");
    if (schema->doc == NULL) {
        fprintf(output, "no document\n");
    } else if (schema->doc->URL != NULL) {
        fprintf(output, "%s\n", schema->doc->URL);
    } else {
        fprintf(output, "\n");
    }
    if (schema->topgrammar == NULL) {
        fprintf(output, "RelaxNG has no top grammar\n");
        return;
    }
    xmlRelaxNGDumpGrammar(output, schema->topgrammar, 1);
}

/**
 * xmlRelaxNGDumpTree:
 * @output:  the file output
 * @schema:  a schema structure
 *
 * Dump the transformed RelaxNG tree.
 */
void
xmlRelaxNGDumpTree(FILE * output, xmlRelaxNGPtr schema)
{
    if (output == NULL)
        return;
    if (schema == NULL) {
        fprintf(output, "RelaxNG empty or failed to compile\n");
        return;
    }
    if (schema->doc == NULL) {
        fprintf(output, "no document\n");
    } else {
        xmlDocDump(output, schema->doc);
    }
}
#endif /* LIBXML_OUTPUT_ENABLED */

/************************************************************************
 *									*
 *		Validation of compiled content				*
 *									*
 ************************************************************************/
static int xmlRelaxNGValidateDefinition(xmlRelaxNGValidCtxtPtr ctxt,
                                        xmlRelaxNGDefinePtr define);

/**
 * xmlRelaxNGValidateCompiledCallback:
 * @exec:  the regular expression instance
 * @token:  the token which matched
 * @transdata:  callback data, the define for the subelement if available
 @ @inputdata:  callback data, the Relax NG validation context
 *
 * Handle the callback and if needed validate the element children.
 */
static void
xmlRelaxNGValidateCompiledCallback(xmlRegExecCtxtPtr exec ATTRIBUTE_UNUSED,
                                   const xmlChar * token,
                                   void *transdata, void *inputdata)
{
    xmlRelaxNGValidCtxtPtr ctxt = (xmlRelaxNGValidCtxtPtr) inputdata;
    xmlRelaxNGDefinePtr define = (xmlRelaxNGDefinePtr) transdata;
    int ret;

#ifdef DEBUG_COMPILE
    xmlGenericError(xmlGenericErrorContext,
                    "Compiled callback for: '%s'\n", token);
#endif
    if (ctxt == NULL) {
        fprintf(stderr, "callback on %s missing context\n", token);
        return;
    }
    if (define == NULL) {
        if (token[0] == '#')
            return;
        fprintf(stderr, "callback on %s missing define\n", token);
        if ((ctxt != NULL) && (ctxt->errNo == XML_RELAXNG_OK))
            ctxt->errNo = XML_RELAXNG_ERR_INTERNAL;
        return;
    }
    if ((ctxt == NULL) || (define == NULL)) {
        fprintf(stderr, "callback on %s missing info\n", token);
        if ((ctxt != NULL) && (ctxt->errNo == XML_RELAXNG_OK))
            ctxt->errNo = XML_RELAXNG_ERR_INTERNAL;
        return;
    } else if (define->type != XML_RELAXNG_ELEMENT) {
        fprintf(stderr, "callback on %s define is not element\n", token);
        if (ctxt->errNo == XML_RELAXNG_OK)
            ctxt->errNo = XML_RELAXNG_ERR_INTERNAL;
        return;
    }
    ret = xmlRelaxNGValidateDefinition(ctxt, define);
    if (ret != 0)
        ctxt->perr = ret;
}

/**
 * xmlRelaxNGValidateCompiledContent:
 * @ctxt:  the RelaxNG validation context
 * @regexp:  the regular expression as compiled
 * @content:  list of children to test against the regexp
 *
 * Validate the content model of an element or start using the regexp
 *
 * Returns 0 in case of success, -1 in case of error.
 */
static int
xmlRelaxNGValidateCompiledContent(xmlRelaxNGValidCtxtPtr ctxt,
                                  xmlRegexpPtr regexp, xmlNodePtr content)
{
    xmlRegExecCtxtPtr exec;
    xmlNodePtr cur;
    int ret = 0;
    int oldperr;

    if ((ctxt == NULL) || (regexp == NULL))
        return (-1);
    oldperr = ctxt->perr;
    exec = xmlRegNewExecCtxt(regexp,
                             xmlRelaxNGValidateCompiledCallback, ctxt);
    ctxt->perr = 0;
    cur = content;
    while (cur != NULL) {
        ctxt->state->seq = cur;
        switch (cur->type) {
            case XML_TEXT_NODE:
            case XML_CDATA_SECTION_NODE:
                if (xmlIsBlankNode(cur))
                    break;
                ret = xmlRegExecPushString(exec, BAD_CAST "#text", ctxt);
                if (ret < 0) {
                    VALID_ERR2(XML_RELAXNG_ERR_TEXTWRONG,
                               cur->parent->name);
                }
                break;
            case XML_ELEMENT_NODE:
                if (cur->ns != NULL) {
                    ret = xmlRegExecPushString2(exec, cur->name,
                                                cur->ns->href, ctxt);
                } else {
                    ret = xmlRegExecPushString(exec, cur->name, ctxt);
                }
                if (ret < 0) {
                    VALID_ERR2(XML_RELAXNG_ERR_ELEMWRONG, cur->name);
                }
                break;
            default:
                break;
        }
        if (ret < 0)
            break;
        /*
         * Switch to next element
         */
        cur = cur->next;
    }
    ret = xmlRegExecPushString(exec, NULL, NULL);
    if (ret == 1) {
        ret = 0;
        ctxt->state->seq = NULL;
    } else if (ret == 0) {
        /*
         * TODO: get some of the names needed to exit the current state of exec
         */
        VALID_ERR2(XML_RELAXNG_ERR_NOELEM, BAD_CAST "");
        ret = -1;
        if ((ctxt->flags & FLAGS_IGNORABLE) == 0)
            xmlRelaxNGDumpValidError(ctxt);
    } else {
        ret = -1;
    }
    xmlRegFreeExecCtxt(exec);
    /*
     * There might be content model errors outside of the pure
     * regexp validation, e.g. for attribute values.
     */
    if ((ret == 0) && (ctxt->perr != 0)) {
        ret = ctxt->perr;
    }
    ctxt->perr = oldperr;
    return (ret);
}

/************************************************************************
 *									*
 *		Progressive validation of when possible			*
 *									*
 ************************************************************************/
static int xmlRelaxNGValidateAttributeList(xmlRelaxNGValidCtxtPtr ctxt,
                                           xmlRelaxNGDefinePtr defines);
static int xmlRelaxNGValidateElementEnd(xmlRelaxNGValidCtxtPtr ctxt,
                                        int dolog);
static void xmlRelaxNGLogBestError(xmlRelaxNGValidCtxtPtr ctxt);

/**
 * xmlRelaxNGElemPush:
 * @ctxt:  the validation context
 * @exec:  the regexp runtime for the new content model
 *
 * Push a new regexp for the current node content model on the stack
 *
 * Returns 0 in case of success and -1 in case of error.
 */
static int
xmlRelaxNGElemPush(xmlRelaxNGValidCtxtPtr ctxt, xmlRegExecCtxtPtr exec)
{
    if (ctxt->elemTab == NULL) {
        ctxt->elemMax = 10;
        ctxt->elemTab = (xmlRegExecCtxtPtr *) xmlMalloc(ctxt->elemMax *
                                                        sizeof
                                                        (xmlRegExecCtxtPtr));
        if (ctxt->elemTab == NULL) {
            xmlRngVErrMemory(ctxt, "validating\n");
            return (-1);
        }
    }
    if (ctxt->elemNr >= ctxt->elemMax) {
        ctxt->elemMax *= 2;
        ctxt->elemTab = (xmlRegExecCtxtPtr *) xmlRealloc(ctxt->elemTab,
                                                         ctxt->elemMax *
                                                         sizeof
                                                         (xmlRegExecCtxtPtr));
        if (ctxt->elemTab == NULL) {
            xmlRngVErrMemory(ctxt, "validating\n");
            return (-1);
        }
    }
    ctxt->elemTab[ctxt->elemNr++] = exec;
    ctxt->elem = exec;
    return (0);
}

/**
 * xmlRelaxNGElemPop:
 * @ctxt:  the validation context
 *
 * Pop the regexp of the current node content model from the stack
 *
 * Returns the exec or NULL if empty
 */
static xmlRegExecCtxtPtr
xmlRelaxNGElemPop(xmlRelaxNGValidCtxtPtr ctxt)
{
    xmlRegExecCtxtPtr ret;

    if (ctxt->elemNr <= 0)
        return (NULL);
    ctxt->elemNr--;
    ret = ctxt->elemTab[ctxt->elemNr];
    ctxt->elemTab[ctxt->elemNr] = NULL;
    if (ctxt->elemNr > 0)
        ctxt->elem = ctxt->elemTab[ctxt->elemNr - 1];
    else
        ctxt->elem = NULL;
    return (ret);
}

/**
 * xmlRelaxNGValidateProgressiveCallback:
 * @exec:  the regular expression instance
 * @token:  the token which matched
 * @transdata:  callback data, the define for the subelement if available
 @ @inputdata:  callback data, the Relax NG validation context
 *
 * Handle the callback and if needed validate the element children.
 * some of the in/out informations are passed via the context in @inputdata.
 */
static void
xmlRelaxNGValidateProgressiveCallback(xmlRegExecCtxtPtr exec
                                      ATTRIBUTE_UNUSED,
                                      const xmlChar * token,
                                      void *transdata, void *inputdata)
{
    xmlRelaxNGValidCtxtPtr ctxt = (xmlRelaxNGValidCtxtPtr) inputdata;
    xmlRelaxNGDefinePtr define = (xmlRelaxNGDefinePtr) transdata;
    xmlRelaxNGValidStatePtr state, oldstate;
    xmlNodePtr node;
    int ret = 0, oldflags;

#ifdef DEBUG_PROGRESSIVE
    xmlGenericError(xmlGenericErrorContext,
                    "Progressive callback for: '%s'\n", token);
#endif
    if (ctxt == NULL) {
        fprintf(stderr, "callback on %s missing context\n", token);
        return;
    }
    node = ctxt->pnode;
    ctxt->pstate = 1;
    if (define == NULL) {
        if (token[0] == '#')
            return;
        fprintf(stderr, "callback on %s missing define\n", token);
        if ((ctxt != NULL) && (ctxt->errNo == XML_RELAXNG_OK))
            ctxt->errNo = XML_RELAXNG_ERR_INTERNAL;
        ctxt->pstate = -1;
        return;
    }
    if ((ctxt == NULL) || (define == NULL)) {
        fprintf(stderr, "callback on %s missing info\n", token);
        if ((ctxt != NULL) && (ctxt->errNo == XML_RELAXNG_OK))
            ctxt->errNo = XML_RELAXNG_ERR_INTERNAL;
        ctxt->pstate = -1;
        return;
    } else if (define->type != XML_RELAXNG_ELEMENT) {
        fprintf(stderr, "callback on %s define is not element\n", token);
        if (ctxt->errNo == XML_RELAXNG_OK)
            ctxt->errNo = XML_RELAXNG_ERR_INTERNAL;
        ctxt->pstate = -1;
        return;
    }
    if (node->type != XML_ELEMENT_NODE) {
        VALID_ERR(XML_RELAXNG_ERR_NOTELEM);
        if ((ctxt->flags & FLAGS_IGNORABLE) == 0)
            xmlRelaxNGDumpValidError(ctxt);
        ctxt->pstate = -1;
        return;
    }
    if (define->contModel == NULL) {
        /*
         * this node cannot be validated in a streamable fashion
         */
#ifdef DEBUG_PROGRESSIVE
        xmlGenericError(xmlGenericErrorContext,
                        "Element '%s' validation is not streamable\n",
                        token);
#endif
        ctxt->pstate = 0;
        ctxt->pdef = define;
        return;
    }
    exec = xmlRegNewExecCtxt(define->contModel,
                             xmlRelaxNGValidateProgressiveCallback, ctxt);
    if (exec == NULL) {
        ctxt->pstate = -1;
        return;
    }
    xmlRelaxNGElemPush(ctxt, exec);

    /*
     * Validate the attributes part of the content.
     */
    state = xmlRelaxNGNewValidState(ctxt, node);
    if (state == NULL) {
        ctxt->pstate = -1;
        return;
    }
    oldstate = ctxt->state;
    ctxt->state = state;
    if (define->attrs != NULL) {
        ret = xmlRelaxNGValidateAttributeList(ctxt, define->attrs);
        if (ret != 0) {
            ctxt->pstate = -1;
            VALID_ERR2(XML_RELAXNG_ERR_ATTRVALID, node->name);
        }
    }
    if (ctxt->state != NULL) {
        ctxt->state->seq = NULL;
        ret = xmlRelaxNGValidateElementEnd(ctxt, 1);
        if (ret != 0) {
            ctxt->pstate = -1;
        }
        xmlRelaxNGFreeValidState(ctxt, ctxt->state);
    } else if (ctxt->states != NULL) {
        int tmp = -1, i;

        oldflags = ctxt->flags;

        for (i = 0; i < ctxt->states->nbState; i++) {
            state = ctxt->states->tabState[i];
            ctxt->state = state;
            ctxt->state->seq = NULL;

            if (xmlRelaxNGValidateElementEnd(ctxt, 0) == 0) {
                tmp = 0;
                break;
            }
        }
        if (tmp != 0) {
            /*
             * validation error, log the message for the "best" one
             */
            ctxt->flags |= FLAGS_IGNORABLE;
            xmlRelaxNGLogBestError(ctxt);
        }
        for (i = 0; i < ctxt->states->nbState; i++) {
            xmlRelaxNGFreeValidState(ctxt, ctxt->states->tabState[i]);
        }
        xmlRelaxNGFreeStates(ctxt, ctxt->states);
        ctxt->states = NULL;
        if ((ret == 0) && (tmp == -1))
            ctxt->pstate = -1;
        ctxt->flags = oldflags;
    }
    if (ctxt->pstate == -1) {
        if ((ctxt->flags & FLAGS_IGNORABLE) == 0) {
            xmlRelaxNGDumpValidError(ctxt);
        }
    }
    ctxt->state = oldstate;
}

/**
 * xmlRelaxNGValidatePushElement:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element instance
 *
 * Push a new element start on the RelaxNG validation stack.
 *
 * returns 1 if no validation problem was found or 0 if validating the
 *         element requires a full node, and -1 in case of error.
 */
int
xmlRelaxNGValidatePushElement(xmlRelaxNGValidCtxtPtr ctxt,
                              xmlDocPtr doc ATTRIBUTE_UNUSED,
                              xmlNodePtr elem)
{
    int ret = 1;

    if ((ctxt == NULL) || (elem == NULL))
        return (-1);

#ifdef DEBUG_PROGRESSIVE
    xmlGenericError(xmlGenericErrorContext, "PushElem %s\n", elem->name);
#endif
    if (ctxt->elem == 0) {
        xmlRelaxNGPtr schema;
        xmlRelaxNGGrammarPtr grammar;
        xmlRegExecCtxtPtr exec;
        xmlRelaxNGDefinePtr define;

        schema = ctxt->schema;
        if (schema == NULL) {
            VALID_ERR(XML_RELAXNG_ERR_NOGRAMMAR);
            return (-1);
        }
        grammar = schema->topgrammar;
        if ((grammar == NULL) || (grammar->start == NULL)) {
            VALID_ERR(XML_RELAXNG_ERR_NOGRAMMAR);
            return (-1);
        }
        define = grammar->start;
        if (define->contModel == NULL) {
            ctxt->pdef = define;
            return (0);
        }
        exec = xmlRegNewExecCtxt(define->contModel,
                                 xmlRelaxNGValidateProgressiveCallback,
                                 ctxt);
        if (exec == NULL) {
            return (-1);
        }
        xmlRelaxNGElemPush(ctxt, exec);
    }
    ctxt->pnode = elem;
    ctxt->pstate = 0;
    if (elem->ns != NULL) {
        ret =
            xmlRegExecPushString2(ctxt->elem, elem->name, elem->ns->href,
                                  ctxt);
    } else {
        ret = xmlRegExecPushString(ctxt->elem, elem->name, ctxt);
    }
    if (ret < 0) {
        VALID_ERR2(XML_RELAXNG_ERR_ELEMWRONG, elem->name);
    } else {
        if (ctxt->pstate == 0)
            ret = 0;
        else if (ctxt->pstate < 0)
            ret = -1;
        else
            ret = 1;
    }
#ifdef DEBUG_PROGRESSIVE
    if (ret < 0)
        xmlGenericError(xmlGenericErrorContext, "PushElem %s failed\n",
                        elem->name);
#endif
    return (ret);
}

/**
 * xmlRelaxNGValidatePushCData:
 * @ctxt:  the RelaxNG validation context
 * @data:  some character data read
 * @len:  the length of the data
 *
 * check the CData parsed for validation in the current stack
 *
 * returns 1 if no validation problem was found or -1 otherwise
 */
int
xmlRelaxNGValidatePushCData(xmlRelaxNGValidCtxtPtr ctxt,
                            const xmlChar * data, int len ATTRIBUTE_UNUSED)
{
    int ret = 1;

    if ((ctxt == NULL) || (ctxt->elem == NULL) || (data == NULL))
        return (-1);

#ifdef DEBUG_PROGRESSIVE
    xmlGenericError(xmlGenericErrorContext, "CDATA %s %d\n", data, len);
#endif

    while (*data != 0) {
        if (!IS_BLANK_CH(*data))
            break;
        data++;
    }
    if (*data == 0)
        return (1);

    ret = xmlRegExecPushString(ctxt->elem, BAD_CAST "#text", ctxt);
    if (ret < 0) {
        VALID_ERR2(XML_RELAXNG_ERR_TEXTWRONG, BAD_CAST " TODO ");
#ifdef DEBUG_PROGRESSIVE
        xmlGenericError(xmlGenericErrorContext, "CDATA failed\n");
#endif

        return (-1);
    }
    return (1);
}

/**
 * xmlRelaxNGValidatePopElement:
 * @ctxt:  the RelaxNG validation context
 * @doc:  a document instance
 * @elem:  an element instance
 *
 * Pop the element end from the RelaxNG validation stack.
 *
 * returns 1 if no validation problem was found or 0 otherwise
 */
int
xmlRelaxNGValidatePopElement(xmlRelaxNGValidCtxtPtr ctxt,
                             xmlDocPtr doc ATTRIBUTE_UNUSED,
                             xmlNodePtr elem)
{
    int ret;
    xmlRegExecCtxtPtr exec;

    if ((ctxt == NULL) || (ctxt->elem == NULL) || (elem == NULL))
        return (-1);
#ifdef DEBUG_PROGRESSIVE
    xmlGenericError(xmlGenericErrorContext, "PopElem %s\n", elem->name);
#endif
    /*
     * verify that we reached a terminal state of the content model.
     */
    exec = xmlRelaxNGElemPop(ctxt);
    ret = xmlRegExecPushString(exec, NULL, NULL);
    if (ret == 0) {
        /*
         * TODO: get some of the names needed to exit the current state of exec
         */
        VALID_ERR2(XML_RELAXNG_ERR_NOELEM, BAD_CAST "");
        ret = -1;
    } else if (ret < 0) {
        ret = -1;
    } else {
        ret = 1;
    }
    xmlRegFreeExecCtxt(exec);
#ifdef DEBUG_PROGRESSIVE
    if (ret < 0)
        xmlGenericError(xmlGenericErrorContext, "PopElem %s failed\n",
                        elem->name);
#endif
    return (ret);
}

/**
 * xmlRelaxNGValidateFullElement:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element instance
 *
 * Validate a full subtree when xmlRelaxNGValidatePushElement() returned
 * 0 and the content of the node has been expanded.
 *
 * returns 1 if no validation problem was found or -1 in case of error.
 */
int
xmlRelaxNGValidateFullElement(xmlRelaxNGValidCtxtPtr ctxt,
                              xmlDocPtr doc ATTRIBUTE_UNUSED,
                              xmlNodePtr elem)
{
    int ret;
    xmlRelaxNGValidStatePtr state;

    if ((ctxt == NULL) || (ctxt->pdef == NULL) || (elem == NULL))
        return (-1);
#ifdef DEBUG_PROGRESSIVE
    xmlGenericError(xmlGenericErrorContext, "FullElem %s\n", elem->name);
#endif
    state = xmlRelaxNGNewValidState(ctxt, elem->parent);
    if (state == NULL) {
        return (-1);
    }
    state->seq = elem;
    ctxt->state = state;
    ctxt->errNo = XML_RELAXNG_OK;
    ret = xmlRelaxNGValidateDefinition(ctxt, ctxt->pdef);
    if ((ret != 0) || (ctxt->errNo != XML_RELAXNG_OK))
        ret = -1;
    else
        ret = 1;
    xmlRelaxNGFreeValidState(ctxt, ctxt->state);
    ctxt->state = NULL;
#ifdef DEBUG_PROGRESSIVE
    if (ret < 0)
        xmlGenericError(xmlGenericErrorContext, "FullElem %s failed\n",
                        elem->name);
#endif
    return (ret);
}

/************************************************************************
 *									*
 *		Generic interpreted validation implementation		*
 *									*
 ************************************************************************/
static int xmlRelaxNGValidateValue(xmlRelaxNGValidCtxtPtr ctxt,
                                   xmlRelaxNGDefinePtr define);

/**
 * xmlRelaxNGSkipIgnored:
 * @ctxt:  a schema validation context
 * @node:  the top node.
 *
 * Skip ignorable nodes in that context
 *
 * Returns the new sibling or NULL in case of error.
 */
static xmlNodePtr
xmlRelaxNGSkipIgnored(xmlRelaxNGValidCtxtPtr ctxt ATTRIBUTE_UNUSED,
                      xmlNodePtr node)
{
    /*
     * TODO complete and handle entities
     */
    while ((node != NULL) &&
           ((node->type == XML_COMMENT_NODE) ||
            (node->type == XML_PI_NODE) ||
	    (node->type == XML_XINCLUDE_START) ||
	    (node->type == XML_XINCLUDE_END) ||
            (((node->type == XML_TEXT_NODE) ||
              (node->type == XML_CDATA_SECTION_NODE)) &&
             ((ctxt->flags & FLAGS_MIXED_CONTENT) ||
              (IS_BLANK_NODE(node)))))) {
        node = node->next;
    }
    return (node);
}

/**
 * xmlRelaxNGNormalize:
 * @ctxt:  a schema validation context
 * @str:  the string to normalize
 *
 * Implements the  normalizeWhiteSpace( s ) function from
 * section 6.2.9 of the spec
 *
 * Returns the new string or NULL in case of error.
 */
static xmlChar *
xmlRelaxNGNormalize(xmlRelaxNGValidCtxtPtr ctxt, const xmlChar * str)
{
    xmlChar *ret, *p;
    const xmlChar *tmp;
    int len;

    if (str == NULL)
        return (NULL);
    tmp = str;
    while (*tmp != 0)
        tmp++;
    len = tmp - str;

    ret = (xmlChar *) xmlMallocAtomic((len + 1) * sizeof(xmlChar));
    if (ret == NULL) {
        xmlRngVErrMemory(ctxt, "validating\n");
        return (NULL);
    }
    p = ret;
    while (IS_BLANK_CH(*str))
        str++;
    while (*str != 0) {
        if (IS_BLANK_CH(*str)) {
            while (IS_BLANK_CH(*str))
                str++;
            if (*str == 0)
                break;
            *p++ = ' ';
        } else
            *p++ = *str++;
    }
    *p = 0;
    return (ret);
}

/**
 * xmlRelaxNGValidateDatatype:
 * @ctxt:  a Relax-NG validation context
 * @value:  the string value
 * @type:  the datatype definition
 * @node:  the node
 *
 * Validate the given value against the dataype
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateDatatype(xmlRelaxNGValidCtxtPtr ctxt,
                           const xmlChar * value,
                           xmlRelaxNGDefinePtr define, xmlNodePtr node)
{
    int ret, tmp;
    xmlRelaxNGTypeLibraryPtr lib;
    void *result = NULL;
    xmlRelaxNGDefinePtr cur;

    if ((define == NULL) || (define->data == NULL)) {
        return (-1);
    }
    lib = (xmlRelaxNGTypeLibraryPtr) define->data;
    if (lib->check != NULL) {
        if ((define->attrs != NULL) &&
            (define->attrs->type == XML_RELAXNG_PARAM)) {
            ret =
                lib->check(lib->data, define->name, value, &result, node);
        } else {
            ret = lib->check(lib->data, define->name, value, NULL, node);
        }
    } else
        ret = -1;
    if (ret < 0) {
        VALID_ERR2(XML_RELAXNG_ERR_TYPE, define->name);
        if ((result != NULL) && (lib != NULL) && (lib->freef != NULL))
            lib->freef(lib->data, result);
        return (-1);
    } else if (ret == 1) {
        ret = 0;
    } else if (ret == 2) {
        VALID_ERR2P(XML_RELAXNG_ERR_DUPID, value);
    } else {
        VALID_ERR3P(XML_RELAXNG_ERR_TYPEVAL, define->name, value);
        ret = -1;
    }
    cur = define->attrs;
    while ((ret == 0) && (cur != NULL) && (cur->type == XML_RELAXNG_PARAM)) {
        if (lib->facet != NULL) {
            tmp = lib->facet(lib->data, define->name, cur->name,
                             cur->value, value, result);
            if (tmp != 0)
                ret = -1;
        }
        cur = cur->next;
    }
    if ((ret == 0) && (define->content != NULL)) {
        const xmlChar *oldvalue, *oldendvalue;

        oldvalue = ctxt->state->value;
        oldendvalue = ctxt->state->endvalue;
        ctxt->state->value = (xmlChar *) value;
        ctxt->state->endvalue = NULL;
        ret = xmlRelaxNGValidateValue(ctxt, define->content);
        ctxt->state->value = (xmlChar *) oldvalue;
        ctxt->state->endvalue = (xmlChar *) oldendvalue;
    }
    if ((result != NULL) && (lib != NULL) && (lib->freef != NULL))
        lib->freef(lib->data, result);
    return (ret);
}

/**
 * xmlRelaxNGNextValue:
 * @ctxt:  a Relax-NG validation context
 *
 * Skip to the next value when validating within a list
 *
 * Returns 0 if the operation succeeded or an error code.
 */
static int
xmlRelaxNGNextValue(xmlRelaxNGValidCtxtPtr ctxt)
{
    xmlChar *cur;

    cur = ctxt->state->value;
    if ((cur == NULL) || (ctxt->state->endvalue == NULL)) {
        ctxt->state->value = NULL;
        ctxt->state->endvalue = NULL;
        return (0);
    }
    while (*cur != 0)
        cur++;
    while ((cur != ctxt->state->endvalue) && (*cur == 0))
        cur++;
    if (cur == ctxt->state->endvalue)
        ctxt->state->value = NULL;
    else
        ctxt->state->value = cur;
    return (0);
}

/**
 * xmlRelaxNGValidateValueList:
 * @ctxt:  a Relax-NG validation context
 * @defines:  the list of definitions to verify
 *
 * Validate the given set of definitions for the current value
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateValueList(xmlRelaxNGValidCtxtPtr ctxt,
                            xmlRelaxNGDefinePtr defines)
{
    int ret = 0;

    while (defines != NULL) {
        ret = xmlRelaxNGValidateValue(ctxt, defines);
        if (ret != 0)
            break;
        defines = defines->next;
    }
    return (ret);
}

/**
 * xmlRelaxNGValidateValue:
 * @ctxt:  a Relax-NG validation context
 * @define:  the definition to verify
 *
 * Validate the given definition for the current value
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateValue(xmlRelaxNGValidCtxtPtr ctxt,
                        xmlRelaxNGDefinePtr define)
{
    int ret = 0, oldflags;
    xmlChar *value;

    value = ctxt->state->value;
    switch (define->type) {
        case XML_RELAXNG_EMPTY:{
                if ((value != NULL) && (value[0] != 0)) {
                    int idx = 0;

                    while (IS_BLANK_CH(value[idx]))
                        idx++;
                    if (value[idx] != 0)
                        ret = -1;
                }
                break;
            }
        case XML_RELAXNG_TEXT:
            break;
        case XML_RELAXNG_VALUE:{
                if (!xmlStrEqual(value, define->value)) {
                    if (define->name != NULL) {
                        xmlRelaxNGTypeLibraryPtr lib;

                        lib = (xmlRelaxNGTypeLibraryPtr) define->data;
                        if ((lib != NULL) && (lib->comp != NULL)) {
                            ret = lib->comp(lib->data, define->name,
                                            define->value, define->node,
                                            (void *) define->attrs,
                                            value, ctxt->state->node);
                        } else
                            ret = -1;
                        if (ret < 0) {
                            VALID_ERR2(XML_RELAXNG_ERR_TYPECMP,
                                       define->name);
                            return (-1);
                        } else if (ret == 1) {
                            ret = 0;
                        } else {
                            ret = -1;
                        }
                    } else {
                        xmlChar *nval, *nvalue;

                        /*
                         * TODO: trivial optimizations are possible by
                         * computing at compile-time
                         */
                        nval = xmlRelaxNGNormalize(ctxt, define->value);
                        nvalue = xmlRelaxNGNormalize(ctxt, value);

                        if ((nval == NULL) || (nvalue == NULL) ||
                            (!xmlStrEqual(nval, nvalue)))
                            ret = -1;
                        if (nval != NULL)
                            xmlFree(nval);
                        if (nvalue != NULL)
                            xmlFree(nvalue);
                    }
                }
                if (ret == 0)
                    xmlRelaxNGNextValue(ctxt);
                break;
            }
        case XML_RELAXNG_DATATYPE:{
                ret = xmlRelaxNGValidateDatatype(ctxt, value, define,
                                                 ctxt->state->seq);
                if (ret == 0)
                    xmlRelaxNGNextValue(ctxt);

                break;
            }
        case XML_RELAXNG_CHOICE:{
                xmlRelaxNGDefinePtr list = define->content;
                xmlChar *oldvalue;

                oldflags = ctxt->flags;
                ctxt->flags |= FLAGS_IGNORABLE;

                oldvalue = ctxt->state->value;
                while (list != NULL) {
                    ret = xmlRelaxNGValidateValue(ctxt, list);
                    if (ret == 0) {
                        break;
                    }
                    ctxt->state->value = oldvalue;
                    list = list->next;
                }
                ctxt->flags = oldflags;
                if (ret != 0) {
                    if ((ctxt->flags & FLAGS_IGNORABLE) == 0)
                        xmlRelaxNGDumpValidError(ctxt);
                } else {
                    if (ctxt->errNr > 0)
                        xmlRelaxNGPopErrors(ctxt, 0);
                }
                break;
            }
        case XML_RELAXNG_LIST:{
                xmlRelaxNGDefinePtr list = define->content;
                xmlChar *oldvalue, *oldend, *val, *cur;

#ifdef DEBUG_LIST
                int nb_values = 0;
#endif

                oldvalue = ctxt->state->value;
                oldend = ctxt->state->endvalue;

                val = xmlStrdup(oldvalue);
                if (val == NULL) {
                    val = xmlStrdup(BAD_CAST "");
                }
                if (val == NULL) {
                    VALID_ERR(XML_RELAXNG_ERR_NOSTATE);
                    return (-1);
                }
                cur = val;
                while (*cur != 0) {
                    if (IS_BLANK_CH(*cur)) {
                        *cur = 0;
                        cur++;
#ifdef DEBUG_LIST
                        nb_values++;
#endif
                        while (IS_BLANK_CH(*cur))
                            *cur++ = 0;
                    } else
                        cur++;
                }
#ifdef DEBUG_LIST
                xmlGenericError(xmlGenericErrorContext,
                                "list value: '%s' found %d items\n",
                                oldvalue, nb_values);
                nb_values = 0;
#endif
                ctxt->state->endvalue = cur;
                cur = val;
                while ((*cur == 0) && (cur != ctxt->state->endvalue))
                    cur++;

                ctxt->state->value = cur;

                while (list != NULL) {
                    if (ctxt->state->value == ctxt->state->endvalue)
                        ctxt->state->value = NULL;
                    ret = xmlRelaxNGValidateValue(ctxt, list);
                    if (ret != 0) {
#ifdef DEBUG_LIST
                        xmlGenericError(xmlGenericErrorContext,
                                        "Failed to validate value: '%s' with %d rule\n",
                                        ctxt->state->value, nb_values);
#endif
                        break;
                    }
#ifdef DEBUG_LIST
                    nb_values++;
#endif
                    list = list->next;
                }

                if ((ret == 0) && (ctxt->state->value != NULL) &&
                    (ctxt->state->value != ctxt->state->endvalue)) {
                    VALID_ERR2(XML_RELAXNG_ERR_LISTEXTRA,
                               ctxt->state->value);
                    ret = -1;
                }
                xmlFree(val);
                ctxt->state->value = oldvalue;
                ctxt->state->endvalue = oldend;
                break;
            }
        case XML_RELAXNG_ONEORMORE:
            ret = xmlRelaxNGValidateValueList(ctxt, define->content);
            if (ret != 0) {
                break;
            }
            /* no break on purpose */
        case XML_RELAXNG_ZEROORMORE:{
                xmlChar *cur, *temp;

                if ((ctxt->state->value == NULL) ||
                    (*ctxt->state->value == 0)) {
                    ret = 0;
                    break;
                }
                oldflags = ctxt->flags;
                ctxt->flags |= FLAGS_IGNORABLE;
                cur = ctxt->state->value;
                temp = NULL;
                while ((cur != NULL) && (cur != ctxt->state->endvalue) &&
                       (temp != cur)) {
                    temp = cur;
                    ret =
                        xmlRelaxNGValidateValueList(ctxt, define->content);
                    if (ret != 0) {
                        ctxt->state->value = temp;
                        ret = 0;
                        break;
                    }
                    cur = ctxt->state->value;
                }
                ctxt->flags = oldflags;
		if (ctxt->errNr > 0)
		    xmlRelaxNGPopErrors(ctxt, 0);
                break;
            }
        case XML_RELAXNG_OPTIONAL:{
                xmlChar *temp;

                if ((ctxt->state->value == NULL) ||
                    (*ctxt->state->value == 0)) {
                    ret = 0;
                    break;
                }
                oldflags = ctxt->flags;
                ctxt->flags |= FLAGS_IGNORABLE;
                temp = ctxt->state->value;
                ret = xmlRelaxNGValidateValue(ctxt, define->content);
                ctxt->flags = oldflags;
                if (ret != 0) {
                    ctxt->state->value = temp;
                    if (ctxt->errNr > 0)
                        xmlRelaxNGPopErrors(ctxt, 0);
                    ret = 0;
                    break;
                }
		if (ctxt->errNr > 0)
		    xmlRelaxNGPopErrors(ctxt, 0);
                break;
            }
        case XML_RELAXNG_EXCEPT:{
                xmlRelaxNGDefinePtr list;

                list = define->content;
                while (list != NULL) {
                    ret = xmlRelaxNGValidateValue(ctxt, list);
                    if (ret == 0) {
                        ret = -1;
                        break;
                    } else
                        ret = 0;
                    list = list->next;
                }
                break;
            }
        case XML_RELAXNG_DEF:
        case XML_RELAXNG_GROUP:{
                xmlRelaxNGDefinePtr list;

                list = define->content;
                while (list != NULL) {
                    ret = xmlRelaxNGValidateValue(ctxt, list);
                    if (ret != 0) {
                        ret = -1;
                        break;
                    } else
                        ret = 0;
                    list = list->next;
                }
                break;
            }
        case XML_RELAXNG_REF:
        case XML_RELAXNG_PARENTREF:
	    if (define->content == NULL) {
                VALID_ERR(XML_RELAXNG_ERR_NODEFINE);
                ret = -1;
	    } else {
                ret = xmlRelaxNGValidateValue(ctxt, define->content);
            }
            break;
        default:
            TODO ret = -1;
    }
    return (ret);
}

/**
 * xmlRelaxNGValidateValueContent:
 * @ctxt:  a Relax-NG validation context
 * @defines:  the list of definitions to verify
 *
 * Validate the given definitions for the current value
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateValueContent(xmlRelaxNGValidCtxtPtr ctxt,
                               xmlRelaxNGDefinePtr defines)
{
    int ret = 0;

    while (defines != NULL) {
        ret = xmlRelaxNGValidateValue(ctxt, defines);
        if (ret != 0)
            break;
        defines = defines->next;
    }
    return (ret);
}

/**
 * xmlRelaxNGAttributeMatch:
 * @ctxt:  a Relax-NG validation context
 * @define:  the definition to check
 * @prop:  the attribute
 *
 * Check if the attribute matches the definition nameClass
 *
 * Returns 1 if the attribute matches, 0 if no, or -1 in case of error
 */
static int
xmlRelaxNGAttributeMatch(xmlRelaxNGValidCtxtPtr ctxt,
                         xmlRelaxNGDefinePtr define, xmlAttrPtr prop)
{
    int ret;

    if (define->name != NULL) {
        if (!xmlStrEqual(define->name, prop->name))
            return (0);
    }
    if (define->ns != NULL) {
        if (define->ns[0] == 0) {
            if (prop->ns != NULL)
                return (0);
        } else {
            if ((prop->ns == NULL) ||
                (!xmlStrEqual(define->ns, prop->ns->href)))
                return (0);
        }
    }
    if (define->nameClass == NULL)
        return (1);
    define = define->nameClass;
    if (define->type == XML_RELAXNG_EXCEPT) {
        xmlRelaxNGDefinePtr list;

        list = define->content;
        while (list != NULL) {
            ret = xmlRelaxNGAttributeMatch(ctxt, list, prop);
            if (ret == 1)
                return (0);
            if (ret < 0)
                return (ret);
            list = list->next;
        }
    } else if (define->type == XML_RELAXNG_CHOICE) {
        xmlRelaxNGDefinePtr list;

        list = define->nameClass;
        while (list != NULL) {
            ret = xmlRelaxNGAttributeMatch(ctxt, list, prop);
            if (ret == 1)
                return (1);
            if (ret < 0)
                return (ret);
            list = list->next;
        }
        return (0);
    } else {
    TODO}
    return (1);
}

/**
 * xmlRelaxNGValidateAttribute:
 * @ctxt:  a Relax-NG validation context
 * @define:  the definition to verify
 *
 * Validate the given attribute definition for that node
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateAttribute(xmlRelaxNGValidCtxtPtr ctxt,
                            xmlRelaxNGDefinePtr define)
{
    int ret = 0, i;
    xmlChar *value, *oldvalue;
    xmlAttrPtr prop = NULL, tmp;
    xmlNodePtr oldseq;

    if (ctxt->state->nbAttrLeft <= 0)
        return (-1);
    if (define->name != NULL) {
        for (i = 0; i < ctxt->state->nbAttrs; i++) {
            tmp = ctxt->state->attrs[i];
            if ((tmp != NULL) && (xmlStrEqual(define->name, tmp->name))) {
                if ((((define->ns == NULL) || (define->ns[0] == 0)) &&
                     (tmp->ns == NULL)) ||
                    ((tmp->ns != NULL) &&
                     (xmlStrEqual(define->ns, tmp->ns->href)))) {
                    prop = tmp;
                    break;
                }
            }
        }
        if (prop != NULL) {
            value = xmlNodeListGetString(prop->doc, prop->children, 1);
            oldvalue = ctxt->state->value;
            oldseq = ctxt->state->seq;
            ctxt->state->seq = (xmlNodePtr) prop;
            ctxt->state->value = value;
            ctxt->state->endvalue = NULL;
            ret = xmlRelaxNGValidateValueContent(ctxt, define->content);
            if (ctxt->state->value != NULL)
                value = ctxt->state->value;
            if (value != NULL)
                xmlFree(value);
            ctxt->state->value = oldvalue;
            ctxt->state->seq = oldseq;
            if (ret == 0) {
                /*
                 * flag the attribute as processed
                 */
                ctxt->state->attrs[i] = NULL;
                ctxt->state->nbAttrLeft--;
            }
        } else {
            ret = -1;
        }
#ifdef DEBUG
        xmlGenericError(xmlGenericErrorContext,
                        "xmlRelaxNGValidateAttribute(%s): %d\n",
                        define->name, ret);
#endif
    } else {
        for (i = 0; i < ctxt->state->nbAttrs; i++) {
            tmp = ctxt->state->attrs[i];
            if ((tmp != NULL) &&
                (xmlRelaxNGAttributeMatch(ctxt, define, tmp) == 1)) {
                prop = tmp;
                break;
            }
        }
        if (prop != NULL) {
            value = xmlNodeListGetString(prop->doc, prop->children, 1);
            oldvalue = ctxt->state->value;
            oldseq = ctxt->state->seq;
            ctxt->state->seq = (xmlNodePtr) prop;
            ctxt->state->value = value;
            ret = xmlRelaxNGValidateValueContent(ctxt, define->content);
            if (ctxt->state->value != NULL)
                value = ctxt->state->value;
            if (value != NULL)
                xmlFree(value);
            ctxt->state->value = oldvalue;
            ctxt->state->seq = oldseq;
            if (ret == 0) {
                /*
                 * flag the attribute as processed
                 */
                ctxt->state->attrs[i] = NULL;
                ctxt->state->nbAttrLeft--;
            }
        } else {
            ret = -1;
        }
#ifdef DEBUG
        if (define->ns != NULL) {
            xmlGenericError(xmlGenericErrorContext,
                            "xmlRelaxNGValidateAttribute(nsName ns = %s): %d\n",
                            define->ns, ret);
        } else {
            xmlGenericError(xmlGenericErrorContext,
                            "xmlRelaxNGValidateAttribute(anyName): %d\n",
                            ret);
        }
#endif
    }

    return (ret);
}

/**
 * xmlRelaxNGValidateAttributeList:
 * @ctxt:  a Relax-NG validation context
 * @define:  the list of definition to verify
 *
 * Validate the given node against the list of attribute definitions
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateAttributeList(xmlRelaxNGValidCtxtPtr ctxt,
                                xmlRelaxNGDefinePtr defines)
{
    int ret = 0, res;
    int needmore = 0;
    xmlRelaxNGDefinePtr cur;

    cur = defines;
    while (cur != NULL) {
        if (cur->type == XML_RELAXNG_ATTRIBUTE) {
            if (xmlRelaxNGValidateAttribute(ctxt, cur) != 0)
                ret = -1;
        } else
            needmore = 1;
        cur = cur->next;
    }
    if (!needmore)
        return (ret);
    cur = defines;
    while (cur != NULL) {
        if (cur->type != XML_RELAXNG_ATTRIBUTE) {
            if ((ctxt->state != NULL) || (ctxt->states != NULL)) {
                res = xmlRelaxNGValidateDefinition(ctxt, cur);
                if (res < 0)
                    ret = -1;
            } else {
                VALID_ERR(XML_RELAXNG_ERR_NOSTATE);
                return (-1);
            }
            if (res == -1)      /* continues on -2 */
                break;
        }
        cur = cur->next;
    }

    return (ret);
}

/**
 * xmlRelaxNGNodeMatchesList:
 * @node:  the node
 * @list:  a NULL terminated array of definitions
 *
 * Check if a node can be matched by one of the definitions
 *
 * Returns 1 if matches 0 otherwise
 */
static int
xmlRelaxNGNodeMatchesList(xmlNodePtr node, xmlRelaxNGDefinePtr * list)
{
    xmlRelaxNGDefinePtr cur;
    int i = 0, tmp;

    if ((node == NULL) || (list == NULL))
        return (0);

    cur = list[i++];
    while (cur != NULL) {
        if ((node->type == XML_ELEMENT_NODE) &&
            (cur->type == XML_RELAXNG_ELEMENT)) {
            tmp = xmlRelaxNGElementMatch(NULL, cur, node);
            if (tmp == 1)
                return (1);
        } else if (((node->type == XML_TEXT_NODE) ||
                    (node->type == XML_CDATA_SECTION_NODE)) &&
                   (cur->type == XML_RELAXNG_TEXT)) {
            return (1);
        }
        cur = list[i++];
    }
    return (0);
}

/**
 * xmlRelaxNGValidateInterleave:
 * @ctxt:  a Relax-NG validation context
 * @define:  the definition to verify
 *
 * Validate an interleave definition for a node.
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateInterleave(xmlRelaxNGValidCtxtPtr ctxt,
                             xmlRelaxNGDefinePtr define)
{
    int ret = 0, i, nbgroups;
    int errNr = ctxt->errNr;
    int oldflags;

    xmlRelaxNGValidStatePtr oldstate;
    xmlRelaxNGPartitionPtr partitions;
    xmlRelaxNGInterleaveGroupPtr group = NULL;
    xmlNodePtr cur, start, last = NULL, lastchg = NULL, lastelem;
    xmlNodePtr *list = NULL, *lasts = NULL;

    if (define->data != NULL) {
        partitions = (xmlRelaxNGPartitionPtr) define->data;
        nbgroups = partitions->nbgroups;
    } else {
        VALID_ERR(XML_RELAXNG_ERR_INTERNODATA);
        return (-1);
    }
    /*
     * Optimizations for MIXED
     */
    oldflags = ctxt->flags;
    if (define->dflags & IS_MIXED) {
        ctxt->flags |= FLAGS_MIXED_CONTENT;
        if (nbgroups == 2) {
            /*
             * this is a pure <mixed> case
             */
            if (ctxt->state != NULL)
                ctxt->state->seq = xmlRelaxNGSkipIgnored(ctxt,
                                                         ctxt->state->seq);
            if (partitions->groups[0]->rule->type == XML_RELAXNG_TEXT)
                ret = xmlRelaxNGValidateDefinition(ctxt,
                                                   partitions->groups[1]->
                                                   rule);
            else
                ret = xmlRelaxNGValidateDefinition(ctxt,
                                                   partitions->groups[0]->
                                                   rule);
            if (ret == 0) {
                if (ctxt->state != NULL)
                    ctxt->state->seq = xmlRelaxNGSkipIgnored(ctxt,
                                                             ctxt->state->
                                                             seq);
            }
            ctxt->flags = oldflags;
            return (ret);
        }
    }

    /*
     * Build arrays to store the first and last node of the chain
     * pertaining to each group
     */
    list = (xmlNodePtr *) xmlMalloc(nbgroups * sizeof(xmlNodePtr));
    if (list == NULL) {
        xmlRngVErrMemory(ctxt, "validating\n");
        return (-1);
    }
    memset(list, 0, nbgroups * sizeof(xmlNodePtr));
    lasts = (xmlNodePtr *) xmlMalloc(nbgroups * sizeof(xmlNodePtr));
    if (lasts == NULL) {
        xmlRngVErrMemory(ctxt, "validating\n");
        return (-1);
    }
    memset(lasts, 0, nbgroups * sizeof(xmlNodePtr));

    /*
     * Walk the sequence of children finding the right group and
     * sorting them in sequences.
     */
    cur = ctxt->state->seq;
    cur = xmlRelaxNGSkipIgnored(ctxt, cur);
    start = cur;
    while (cur != NULL) {
        ctxt->state->seq = cur;
        if ((partitions->triage != NULL) &&
            (partitions->flags & IS_DETERMINIST)) {
            void *tmp = NULL;

            if ((cur->type == XML_TEXT_NODE) ||
                (cur->type == XML_CDATA_SECTION_NODE)) {
                tmp = xmlHashLookup2(partitions->triage, BAD_CAST "#text",
                                     NULL);
            } else if (cur->type == XML_ELEMENT_NODE) {
                if (cur->ns != NULL) {
                    tmp = xmlHashLookup2(partitions->triage, cur->name,
                                         cur->ns->href);
                    if (tmp == NULL)
                        tmp = xmlHashLookup2(partitions->triage,
                                             BAD_CAST "#any",
                                             cur->ns->href);
                } else
                    tmp =
                        xmlHashLookup2(partitions->triage, cur->name,
                                       NULL);
                if (tmp == NULL)
                    tmp =
                        xmlHashLookup2(partitions->triage, BAD_CAST "#any",
                                       NULL);
            }

            if (tmp == NULL) {
                i = nbgroups;
            } else {
                i = ((long) tmp) - 1;
                if (partitions->flags & IS_NEEDCHECK) {
                    group = partitions->groups[i];
                    if (!xmlRelaxNGNodeMatchesList(cur, group->defs))
                        i = nbgroups;
                }
            }
        } else {
            for (i = 0; i < nbgroups; i++) {
                group = partitions->groups[i];
                if (group == NULL)
                    continue;
                if (xmlRelaxNGNodeMatchesList(cur, group->defs))
                    break;
            }
        }
        /*
         * We break as soon as an element not matched is found
         */
        if (i >= nbgroups) {
            break;
        }
        if (lasts[i] != NULL) {
            lasts[i]->next = cur;
            lasts[i] = cur;
        } else {
            list[i] = cur;
            lasts[i] = cur;
        }
        if (cur->next != NULL)
            lastchg = cur->next;
        else
            lastchg = cur;
        cur = xmlRelaxNGSkipIgnored(ctxt, cur->next);
    }
    if (ret != 0) {
        VALID_ERR(XML_RELAXNG_ERR_INTERSEQ);
        ret = -1;
        goto done;
    }
    lastelem = cur;
    oldstate = ctxt->state;
    for (i = 0; i < nbgroups; i++) {
        ctxt->state = xmlRelaxNGCopyValidState(ctxt, oldstate);
	if (ctxt->state == NULL) {
	    ret = -1;
	    break;
	}
        group = partitions->groups[i];
        if (lasts[i] != NULL) {
            last = lasts[i]->next;
            lasts[i]->next = NULL;
        }
        ctxt->state->seq = list[i];
        ret = xmlRelaxNGValidateDefinition(ctxt, group->rule);
        if (ret != 0)
            break;
        if (ctxt->state != NULL) {
            cur = ctxt->state->seq;
            cur = xmlRelaxNGSkipIgnored(ctxt, cur);
            xmlRelaxNGFreeValidState(ctxt, oldstate);
            oldstate = ctxt->state;
            ctxt->state = NULL;
            if (cur != NULL) {
                VALID_ERR2(XML_RELAXNG_ERR_INTEREXTRA, cur->name);
                ret = -1;
                ctxt->state = oldstate;
                goto done;
            }
        } else if (ctxt->states != NULL) {
            int j;
            int found = 0;
	    int best = -1;
	    int lowattr = -1;

	    /*
	     * PBM: what happen if there is attributes checks in the interleaves
	     */

            for (j = 0; j < ctxt->states->nbState; j++) {
                cur = ctxt->states->tabState[j]->seq;
                cur = xmlRelaxNGSkipIgnored(ctxt, cur);
                if (cur == NULL) {
		    if (found == 0) {
		        lowattr = ctxt->states->tabState[j]->nbAttrLeft;
			best = j;
		    }
                    found = 1;
		    if (ctxt->states->tabState[j]->nbAttrLeft <= lowattr) {
		        /* try  to keep the latest one to mach old heuristic */
		        lowattr = ctxt->states->tabState[j]->nbAttrLeft;
			best = j;
		    }
                    if (lowattr == 0)
		        break;
                } else if (found == 0) {
                    if (lowattr == -1) {
		        lowattr = ctxt->states->tabState[j]->nbAttrLeft;
			best = j;
		    } else
		    if (ctxt->states->tabState[j]->nbAttrLeft <= lowattr)  {
		        /* try  to keep the latest one to mach old heuristic */
		        lowattr = ctxt->states->tabState[j]->nbAttrLeft;
			best = j;
		    }
		}
            }
	    /*
	     * BIG PBM: here we pick only one restarting point :-(
	     */
            if (ctxt->states->nbState > 0) {
                xmlRelaxNGFreeValidState(ctxt, oldstate);
		if (best != -1) {
		    oldstate = ctxt->states->tabState[best];
		    ctxt->states->tabState[best] = NULL;
		} else {
		    oldstate =
			ctxt->states->tabState[ctxt->states->nbState - 1];
                    ctxt->states->tabState[ctxt->states->nbState - 1] = NULL;
                    ctxt->states->nbState--;
		}
            }
            for (j = 0; j < ctxt->states->nbState ; j++) {
                xmlRelaxNGFreeValidState(ctxt, ctxt->states->tabState[j]);
            }
            xmlRelaxNGFreeStates(ctxt, ctxt->states);
            ctxt->states = NULL;
            if (found == 0) {
                if (cur == NULL) {
		    VALID_ERR2(XML_RELAXNG_ERR_INTEREXTRA,
			       (const xmlChar *) "noname");
                } else {
                    VALID_ERR2(XML_RELAXNG_ERR_INTEREXTRA, cur->name);
                }
                ret = -1;
                ctxt->state = oldstate;
                goto done;
            }
        } else {
            ret = -1;
            break;
        }
        if (lasts[i] != NULL) {
            lasts[i]->next = last;
        }
    }
    if (ctxt->state != NULL)
        xmlRelaxNGFreeValidState(ctxt, ctxt->state);
    ctxt->state = oldstate;
    ctxt->state->seq = lastelem;
    if (ret != 0) {
        VALID_ERR(XML_RELAXNG_ERR_INTERSEQ);
        ret = -1;
        goto done;
    }

  done:
    ctxt->flags = oldflags;
    /*
     * builds the next links chain from the prev one
     */
    cur = lastchg;
    while (cur != NULL) {
        if ((cur == start) || (cur->prev == NULL))
            break;
        cur->prev->next = cur;
        cur = cur->prev;
    }
    if (ret == 0) {
        if (ctxt->errNr > errNr)
            xmlRelaxNGPopErrors(ctxt, errNr);
    }

    xmlFree(list);
    xmlFree(lasts);
    return (ret);
}

/**
 * xmlRelaxNGValidateDefinitionList:
 * @ctxt:  a Relax-NG validation context
 * @define:  the list of definition to verify
 *
 * Validate the given node content against the (list) of definitions
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateDefinitionList(xmlRelaxNGValidCtxtPtr ctxt,
                                 xmlRelaxNGDefinePtr defines)
{
    int ret = 0, res;


    if (defines == NULL) {
        VALID_ERR2(XML_RELAXNG_ERR_INTERNAL,
                   BAD_CAST "NULL definition list");
        return (-1);
    }
    while (defines != NULL) {
        if ((ctxt->state != NULL) || (ctxt->states != NULL)) {
            res = xmlRelaxNGValidateDefinition(ctxt, defines);
            if (res < 0)
                ret = -1;
        } else {
            VALID_ERR(XML_RELAXNG_ERR_NOSTATE);
            return (-1);
        }
        if (res == -1)          /* continues on -2 */
            break;
        defines = defines->next;
    }

    return (ret);
}

/**
 * xmlRelaxNGElementMatch:
 * @ctxt:  a Relax-NG validation context
 * @define:  the definition to check
 * @elem:  the element
 *
 * Check if the element matches the definition nameClass
 *
 * Returns 1 if the element matches, 0 if no, or -1 in case of error
 */
static int
xmlRelaxNGElementMatch(xmlRelaxNGValidCtxtPtr ctxt,
                       xmlRelaxNGDefinePtr define, xmlNodePtr elem)
{
    int ret = 0, oldflags = 0;

    if (define->name != NULL) {
        if (!xmlStrEqual(elem->name, define->name)) {
            VALID_ERR3(XML_RELAXNG_ERR_ELEMNAME, define->name, elem->name);
            return (0);
        }
    }
    if ((define->ns != NULL) && (define->ns[0] != 0)) {
        if (elem->ns == NULL) {
            VALID_ERR2(XML_RELAXNG_ERR_ELEMNONS, elem->name);
            return (0);
        } else if (!xmlStrEqual(elem->ns->href, define->ns)) {
            VALID_ERR3(XML_RELAXNG_ERR_ELEMWRONGNS,
                       elem->name, define->ns);
            return (0);
        }
    } else if ((elem->ns != NULL) && (define->ns != NULL) &&
               (define->name == NULL)) {
        VALID_ERR2(XML_RELAXNG_ERR_ELEMEXTRANS, elem->name);
        return (0);
    } else if ((elem->ns != NULL) && (define->name != NULL)) {
        VALID_ERR2(XML_RELAXNG_ERR_ELEMEXTRANS, define->name);
        return (0);
    }

    if (define->nameClass == NULL)
        return (1);

    define = define->nameClass;
    if (define->type == XML_RELAXNG_EXCEPT) {
        xmlRelaxNGDefinePtr list;

        if (ctxt != NULL) {
            oldflags = ctxt->flags;
            ctxt->flags |= FLAGS_IGNORABLE;
        }

        list = define->content;
        while (list != NULL) {
            ret = xmlRelaxNGElementMatch(ctxt, list, elem);
            if (ret == 1) {
                if (ctxt != NULL)
                    ctxt->flags = oldflags;
                return (0);
            }
            if (ret < 0) {
                if (ctxt != NULL)
                    ctxt->flags = oldflags;
                return (ret);
            }
            list = list->next;
        }
        ret = 1;
        if (ctxt != NULL) {
            ctxt->flags = oldflags;
        }
    } else if (define->type == XML_RELAXNG_CHOICE) {
        xmlRelaxNGDefinePtr list;

        if (ctxt != NULL) {
            oldflags = ctxt->flags;
            ctxt->flags |= FLAGS_IGNORABLE;
        }

        list = define->nameClass;
        while (list != NULL) {
            ret = xmlRelaxNGElementMatch(ctxt, list, elem);
            if (ret == 1) {
                if (ctxt != NULL)
                    ctxt->flags = oldflags;
                return (1);
            }
            if (ret < 0) {
                if (ctxt != NULL)
                    ctxt->flags = oldflags;
                return (ret);
            }
            list = list->next;
        }
        if (ctxt != NULL) {
            if (ret != 0) {
                if ((ctxt->flags & FLAGS_IGNORABLE) == 0)
                    xmlRelaxNGDumpValidError(ctxt);
            } else {
                if (ctxt->errNr > 0)
                    xmlRelaxNGPopErrors(ctxt, 0);
            }
        }
        ret = 0;
        if (ctxt != NULL) {
            ctxt->flags = oldflags;
        }
    } else {
        TODO ret = -1;
    }
    return (ret);
}

/**
 * xmlRelaxNGBestState:
 * @ctxt:  a Relax-NG validation context
 *
 * Find the "best" state in the ctxt->states list of states to report
 * errors about. I.e. a state with no element left in the child list
 * or the one with the less attributes left.
 * This is called only if a falidation error was detected
 *
 * Returns the index of the "best" state or -1 in case of error
 */
static int
xmlRelaxNGBestState(xmlRelaxNGValidCtxtPtr ctxt)
{
    xmlRelaxNGValidStatePtr state;
    int i, tmp;
    int best = -1;
    int value = 1000000;

    if ((ctxt == NULL) || (ctxt->states == NULL) ||
        (ctxt->states->nbState <= 0))
        return (-1);

    for (i = 0; i < ctxt->states->nbState; i++) {
        state = ctxt->states->tabState[i];
        if (state == NULL)
            continue;
        if (state->seq != NULL) {
            if ((best == -1) || (value > 100000)) {
                value = 100000;
                best = i;
            }
        } else {
            tmp = state->nbAttrLeft;
            if ((best == -1) || (value > tmp)) {
                value = tmp;
                best = i;
            }
        }
    }
    return (best);
}

/**
 * xmlRelaxNGLogBestError:
 * @ctxt:  a Relax-NG validation context
 *
 * Find the "best" state in the ctxt->states list of states to report
 * errors about and log it.
 */
static void
xmlRelaxNGLogBestError(xmlRelaxNGValidCtxtPtr ctxt)
{
    int best;

    if ((ctxt == NULL) || (ctxt->states == NULL) ||
        (ctxt->states->nbState <= 0))
        return;

    best = xmlRelaxNGBestState(ctxt);
    if ((best >= 0) && (best < ctxt->states->nbState)) {
        ctxt->state = ctxt->states->tabState[best];

        xmlRelaxNGValidateElementEnd(ctxt, 1);
    }
}

/**
 * xmlRelaxNGValidateElementEnd:
 * @ctxt:  a Relax-NG validation context
 * @dolog:  indicate that error logging should be done
 *
 * Validate the end of the element, implements check that
 * there is nothing left not consumed in the element content
 * or in the attribute list.
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateElementEnd(xmlRelaxNGValidCtxtPtr ctxt, int dolog)
{
    int i;
    xmlRelaxNGValidStatePtr state;

    state = ctxt->state;
    if (state->seq != NULL) {
        state->seq = xmlRelaxNGSkipIgnored(ctxt, state->seq);
        if (state->seq != NULL) {
            if (dolog) {
                VALID_ERR3(XML_RELAXNG_ERR_EXTRACONTENT,
                           state->node->name, state->seq->name);
            }
            return (-1);
        }
    }
    for (i = 0; i < state->nbAttrs; i++) {
        if (state->attrs[i] != NULL) {
            if (dolog) {
                VALID_ERR3(XML_RELAXNG_ERR_INVALIDATTR,
                           state->attrs[i]->name, state->node->name);
            }
            return (-1 - i);
        }
    }
    return (0);
}

/**
 * xmlRelaxNGValidateState:
 * @ctxt:  a Relax-NG validation context
 * @define:  the definition to verify
 *
 * Validate the current state against the definition
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateState(xmlRelaxNGValidCtxtPtr ctxt,
                        xmlRelaxNGDefinePtr define)
{
    xmlNodePtr node;
    int ret = 0, i, tmp, oldflags, errNr;
    xmlRelaxNGValidStatePtr oldstate = NULL, state;

    if (define == NULL) {
        VALID_ERR(XML_RELAXNG_ERR_NODEFINE);
        return (-1);
    }

    if (ctxt->state != NULL) {
        node = ctxt->state->seq;
    } else {
        node = NULL;
    }
#ifdef DEBUG
    for (i = 0; i < ctxt->depth; i++)
        xmlGenericError(xmlGenericErrorContext, " ");
    xmlGenericError(xmlGenericErrorContext,
                    "Start validating %s ", xmlRelaxNGDefName(define));
    if (define->name != NULL)
        xmlGenericError(xmlGenericErrorContext, "%s ", define->name);
    if ((node != NULL) && (node->name != NULL))
        xmlGenericError(xmlGenericErrorContext, "on %s\n", node->name);
    else
        xmlGenericError(xmlGenericErrorContext, "\n");
#endif
    ctxt->depth++;
    switch (define->type) {
        case XML_RELAXNG_EMPTY:
            node = xmlRelaxNGSkipIgnored(ctxt, node);
            ret = 0;
            break;
        case XML_RELAXNG_NOT_ALLOWED:
            ret = -1;
            break;
        case XML_RELAXNG_TEXT:
            while ((node != NULL) &&
                   ((node->type == XML_TEXT_NODE) ||
                    (node->type == XML_COMMENT_NODE) ||
                    (node->type == XML_PI_NODE) ||
                    (node->type == XML_CDATA_SECTION_NODE)))
                node = node->next;
            ctxt->state->seq = node;
            break;
        case XML_RELAXNG_ELEMENT:
            errNr = ctxt->errNr;
            node = xmlRelaxNGSkipIgnored(ctxt, node);
            if (node == NULL) {
                VALID_ERR2(XML_RELAXNG_ERR_NOELEM, define->name);
                ret = -1;
                if ((ctxt->flags & FLAGS_IGNORABLE) == 0)
                    xmlRelaxNGDumpValidError(ctxt);
                break;
            }
            if (node->type != XML_ELEMENT_NODE) {
                VALID_ERR(XML_RELAXNG_ERR_NOTELEM);
                ret = -1;
                if ((ctxt->flags & FLAGS_IGNORABLE) == 0)
                    xmlRelaxNGDumpValidError(ctxt);
                break;
            }
            /*
             * This node was already validated successfully against
             * this definition.
             */
            if (node->psvi == define) {
                ctxt->state->seq = xmlRelaxNGSkipIgnored(ctxt, node->next);
                if (ctxt->errNr > errNr)
                    xmlRelaxNGPopErrors(ctxt, errNr);
                if (ctxt->errNr != 0) {
                    while ((ctxt->err != NULL) &&
                           (((ctxt->err->err == XML_RELAXNG_ERR_ELEMNAME)
                             && (xmlStrEqual(ctxt->err->arg2, node->name)))
                            ||
                            ((ctxt->err->err ==
                              XML_RELAXNG_ERR_ELEMEXTRANS)
                             && (xmlStrEqual(ctxt->err->arg1, node->name)))
                            || (ctxt->err->err == XML_RELAXNG_ERR_NOELEM)
                            || (ctxt->err->err ==
                                XML_RELAXNG_ERR_NOTELEM)))
                        xmlRelaxNGValidErrorPop(ctxt);
                }
                break;
            }

            ret = xmlRelaxNGElementMatch(ctxt, define, node);
            if (ret <= 0) {
                ret = -1;
                if ((ctxt->flags & FLAGS_IGNORABLE) == 0)
                    xmlRelaxNGDumpValidError(ctxt);
                break;
            }
            ret = 0;
            if (ctxt->errNr != 0) {
                if (ctxt->errNr > errNr)
                    xmlRelaxNGPopErrors(ctxt, errNr);
                while ((ctxt->err != NULL) &&
                       (((ctxt->err->err == XML_RELAXNG_ERR_ELEMNAME) &&
                         (xmlStrEqual(ctxt->err->arg2, node->name))) ||
                        ((ctxt->err->err == XML_RELAXNG_ERR_ELEMEXTRANS) &&
                         (xmlStrEqual(ctxt->err->arg1, node->name))) ||
                        (ctxt->err->err == XML_RELAXNG_ERR_NOELEM) ||
                        (ctxt->err->err == XML_RELAXNG_ERR_NOTELEM)))
                    xmlRelaxNGValidErrorPop(ctxt);
            }
            errNr = ctxt->errNr;

            oldflags = ctxt->flags;
            if (ctxt->flags & FLAGS_MIXED_CONTENT) {
                ctxt->flags -= FLAGS_MIXED_CONTENT;
            }
            state = xmlRelaxNGNewValidState(ctxt, node);
            if (state == NULL) {
                ret = -1;
                if ((ctxt->flags & FLAGS_IGNORABLE) == 0)
                    xmlRelaxNGDumpValidError(ctxt);
                break;
            }

            oldstate = ctxt->state;
            ctxt->state = state;
            if (define->attrs != NULL) {
                tmp = xmlRelaxNGValidateAttributeList(ctxt, define->attrs);
                if (tmp != 0) {
                    ret = -1;
                    VALID_ERR2(XML_RELAXNG_ERR_ATTRVALID, node->name);
                }
            }
            if (define->contModel != NULL) {
                xmlRelaxNGValidStatePtr nstate, tmpstate = ctxt->state;
                xmlRelaxNGStatesPtr tmpstates = ctxt->states;
                xmlNodePtr nseq;

                nstate = xmlRelaxNGNewValidState(ctxt, node);
                ctxt->state = nstate;
                ctxt->states = NULL;

                tmp = xmlRelaxNGValidateCompiledContent(ctxt,
                                                        define->contModel,
                                                        ctxt->state->seq);
                nseq = ctxt->state->seq;
                ctxt->state = tmpstate;
                ctxt->states = tmpstates;
                xmlRelaxNGFreeValidState(ctxt, nstate);

#ifdef DEBUG_COMPILE
                xmlGenericError(xmlGenericErrorContext,
                                "Validating content of '%s' : %d\n",
                                define->name, tmp);
#endif
                if (tmp != 0)
                    ret = -1;

                if (ctxt->states != NULL) {
                    tmp = -1;

                    for (i = 0; i < ctxt->states->nbState; i++) {
                        state = ctxt->states->tabState[i];
                        ctxt->state = state;
                        ctxt->state->seq = nseq;

                        if (xmlRelaxNGValidateElementEnd(ctxt, 0) == 0) {
                            tmp = 0;
                            break;
                        }
                    }
                    if (tmp != 0) {
                        /*
                         * validation error, log the message for the "best" one
                         */
                        ctxt->flags |= FLAGS_IGNORABLE;
                        xmlRelaxNGLogBestError(ctxt);
                    }
                    for (i = 0; i < ctxt->states->nbState; i++) {
                        xmlRelaxNGFreeValidState(ctxt,
                                                 ctxt->states->
                                                 tabState[i]);
                    }
                    xmlRelaxNGFreeStates(ctxt, ctxt->states);
                    ctxt->flags = oldflags;
                    ctxt->states = NULL;
                    if ((ret == 0) && (tmp == -1))
                        ret = -1;
                } else {
                    state = ctxt->state;
		    if (ctxt->state != NULL)
			ctxt->state->seq = nseq;
                    if (ret == 0)
                        ret = xmlRelaxNGValidateElementEnd(ctxt, 1);
                    xmlRelaxNGFreeValidState(ctxt, state);
                }
            } else {
                if (define->content != NULL) {
                    tmp = xmlRelaxNGValidateDefinitionList(ctxt,
                                                           define->
                                                           content);
                    if (tmp != 0) {
                        ret = -1;
                        if (ctxt->state == NULL) {
                            ctxt->state = oldstate;
                            VALID_ERR2(XML_RELAXNG_ERR_CONTENTVALID,
                                       node->name);
                            ctxt->state = NULL;
                        } else {
                            VALID_ERR2(XML_RELAXNG_ERR_CONTENTVALID,
                                       node->name);
                        }

                    }
                }
                if (ctxt->states != NULL) {
                    tmp = -1;

                    for (i = 0; i < ctxt->states->nbState; i++) {
                        state = ctxt->states->tabState[i];
                        ctxt->state = state;

                        if (xmlRelaxNGValidateElementEnd(ctxt, 0) == 0) {
                            tmp = 0;
                            break;
                        }
                    }
                    if (tmp != 0) {
                        /*
                         * validation error, log the message for the "best" one
                         */
                        ctxt->flags |= FLAGS_IGNORABLE;
                        xmlRelaxNGLogBestError(ctxt);
                    }
                    for (i = 0; i < ctxt->states->nbState; i++) {
                        xmlRelaxNGFreeValidState(ctxt,
                                                 ctxt->states->tabState[i]);
                        ctxt->states->tabState[i] = NULL;
                    }
                    xmlRelaxNGFreeStates(ctxt, ctxt->states);
                    ctxt->flags = oldflags;
                    ctxt->states = NULL;
                    if ((ret == 0) && (tmp == -1))
                        ret = -1;
                } else {
                    state = ctxt->state;
                    if (ret == 0)
                        ret = xmlRelaxNGValidateElementEnd(ctxt, 1);
                    xmlRelaxNGFreeValidState(ctxt, state);
                }
            }
            if (ret == 0) {
                node->psvi = define;
            }
            ctxt->flags = oldflags;
            ctxt->state = oldstate;
            if (oldstate != NULL)
                oldstate->seq = xmlRelaxNGSkipIgnored(ctxt, node->next);
            if (ret != 0) {
                if ((ctxt->flags & FLAGS_IGNORABLE) == 0) {
                    xmlRelaxNGDumpValidError(ctxt);
                    ret = 0;
#if 0
                } else {
                    ret = -2;
#endif
                }
            } else {
                if (ctxt->errNr > errNr)
                    xmlRelaxNGPopErrors(ctxt, errNr);
            }

#ifdef DEBUG
            xmlGenericError(xmlGenericErrorContext,
                            "xmlRelaxNGValidateDefinition(): validated %s : %d",
                            node->name, ret);
            if (oldstate == NULL)
                xmlGenericError(xmlGenericErrorContext, ": no state\n");
            else if (oldstate->seq == NULL)
                xmlGenericError(xmlGenericErrorContext, ": done\n");
            else if (oldstate->seq->type == XML_ELEMENT_NODE)
                xmlGenericError(xmlGenericErrorContext, ": next elem %s\n",
                                oldstate->seq->name);
            else
                xmlGenericError(xmlGenericErrorContext, ": next %s %d\n",
                                oldstate->seq->name, oldstate->seq->type);
#endif
            break;
        case XML_RELAXNG_OPTIONAL:{
                errNr = ctxt->errNr;
                oldflags = ctxt->flags;
                ctxt->flags |= FLAGS_IGNORABLE;
                oldstate = xmlRelaxNGCopyValidState(ctxt, ctxt->state);
                ret =
                    xmlRelaxNGValidateDefinitionList(ctxt,
                                                     define->content);
                if (ret != 0) {
                    if (ctxt->state != NULL)
                        xmlRelaxNGFreeValidState(ctxt, ctxt->state);
                    ctxt->state = oldstate;
                    ctxt->flags = oldflags;
                    ret = 0;
                    if (ctxt->errNr > errNr)
                        xmlRelaxNGPopErrors(ctxt, errNr);
                    break;
                }
                if (ctxt->states != NULL) {
                    xmlRelaxNGAddStates(ctxt, ctxt->states, oldstate);
                } else {
                    ctxt->states = xmlRelaxNGNewStates(ctxt, 1);
                    if (ctxt->states == NULL) {
                        xmlRelaxNGFreeValidState(ctxt, oldstate);
                        ctxt->flags = oldflags;
                        ret = -1;
                        if (ctxt->errNr > errNr)
                            xmlRelaxNGPopErrors(ctxt, errNr);
                        break;
                    }
                    xmlRelaxNGAddStates(ctxt, ctxt->states, oldstate);
                    xmlRelaxNGAddStates(ctxt, ctxt->states, ctxt->state);
                    ctxt->state = NULL;
                }
                ctxt->flags = oldflags;
                ret = 0;
                if (ctxt->errNr > errNr)
                    xmlRelaxNGPopErrors(ctxt, errNr);
                break;
            }
        case XML_RELAXNG_ONEORMORE:
            errNr = ctxt->errNr;
            ret = xmlRelaxNGValidateDefinitionList(ctxt, define->content);
            if (ret != 0) {
                break;
            }
            if (ctxt->errNr > errNr)
                xmlRelaxNGPopErrors(ctxt, errNr);
            /* no break on purpose */
        case XML_RELAXNG_ZEROORMORE:{
                int progress;
                xmlRelaxNGStatesPtr states = NULL, res = NULL;
                int base, j;

                errNr = ctxt->errNr;
                res = xmlRelaxNGNewStates(ctxt, 1);
                if (res == NULL) {
                    ret = -1;
                    break;
                }
                /*
                 * All the input states are also exit states
                 */
                if (ctxt->state != NULL) {
                    xmlRelaxNGAddStates(ctxt, res,
                                        xmlRelaxNGCopyValidState(ctxt,
                                                                 ctxt->
                                                                 state));
                } else {
                    for (j = 0; j < ctxt->states->nbState; j++) {
                        xmlRelaxNGAddStates(ctxt, res,
                            xmlRelaxNGCopyValidState(ctxt,
                                            ctxt->states->tabState[j]));
                    }
                }
                oldflags = ctxt->flags;
                ctxt->flags |= FLAGS_IGNORABLE;
                do {
                    progress = 0;
                    base = res->nbState;

                    if (ctxt->states != NULL) {
                        states = ctxt->states;
                        for (i = 0; i < states->nbState; i++) {
                            ctxt->state = states->tabState[i];
                            ctxt->states = NULL;
                            ret = xmlRelaxNGValidateDefinitionList(ctxt,
                                                                   define->
                                                                   content);
                            if (ret == 0) {
                                if (ctxt->state != NULL) {
                                    tmp = xmlRelaxNGAddStates(ctxt, res,
                                                              ctxt->state);
                                    ctxt->state = NULL;
                                    if (tmp == 1)
                                        progress = 1;
                                } else if (ctxt->states != NULL) {
                                    for (j = 0; j < ctxt->states->nbState;
                                         j++) {
                                        tmp =
                                            xmlRelaxNGAddStates(ctxt, res,
                                                   ctxt->states->tabState[j]);
                                        if (tmp == 1)
                                            progress = 1;
                                    }
                                    xmlRelaxNGFreeStates(ctxt,
                                                         ctxt->states);
                                    ctxt->states = NULL;
                                }
                            } else {
                                if (ctxt->state != NULL) {
                                    xmlRelaxNGFreeValidState(ctxt,
                                                             ctxt->state);
                                    ctxt->state = NULL;
                                }
                            }
                        }
                    } else {
                        ret = xmlRelaxNGValidateDefinitionList(ctxt,
                                                               define->
                                                               content);
                        if (ret != 0) {
                            xmlRelaxNGFreeValidState(ctxt, ctxt->state);
                            ctxt->state = NULL;
                        } else {
                            base = res->nbState;
                            if (ctxt->state != NULL) {
                                tmp = xmlRelaxNGAddStates(ctxt, res,
                                                          ctxt->state);
                                ctxt->state = NULL;
                                if (tmp == 1)
                                    progress = 1;
                            } else if (ctxt->states != NULL) {
                                for (j = 0; j < ctxt->states->nbState; j++) {
                                    tmp = xmlRelaxNGAddStates(ctxt, res,
                                               ctxt->states->tabState[j]);
                                    if (tmp == 1)
                                        progress = 1;
                                }
                                if (states == NULL) {
                                    states = ctxt->states;
                                } else {
                                    xmlRelaxNGFreeStates(ctxt,
                                                         ctxt->states);
                                }
                                ctxt->states = NULL;
                            }
                        }
                    }
                    if (progress) {
                        /*
                         * Collect all the new nodes added at that step
                         * and make them the new node set
                         */
                        if (res->nbState - base == 1) {
                            ctxt->state = xmlRelaxNGCopyValidState(ctxt,
                                                                   res->
                                                                   tabState
                                                                   [base]);
                        } else {
                            if (states == NULL) {
                                xmlRelaxNGNewStates(ctxt,
                                                    res->nbState - base);
			        states = ctxt->states;
				if (states == NULL) {
				    progress = 0;
				    break;
				}
                            }
                            states->nbState = 0;
                            for (i = base; i < res->nbState; i++)
                                xmlRelaxNGAddStates(ctxt, states,
                                                    xmlRelaxNGCopyValidState
                                                    (ctxt, res->tabState[i]));
                            ctxt->states = states;
                        }
                    }
                } while (progress == 1);
                if (states != NULL) {
                    xmlRelaxNGFreeStates(ctxt, states);
                }
                ctxt->states = res;
                ctxt->flags = oldflags;
#if 0
                /*
                 * errors may have to be propagated back...
                 */
                if (ctxt->errNr > errNr)
                    xmlRelaxNGPopErrors(ctxt, errNr);
#endif
                ret = 0;
                break;
            }
        case XML_RELAXNG_CHOICE:{
                xmlRelaxNGDefinePtr list = NULL;
                xmlRelaxNGStatesPtr states = NULL;

                node = xmlRelaxNGSkipIgnored(ctxt, node);

                errNr = ctxt->errNr;
                if ((define->dflags & IS_TRIABLE) && (define->data != NULL) &&
		    (node != NULL)) {
		    /*
		     * node == NULL can't be optimized since IS_TRIABLE
		     * doesn't account for choice which may lead to
		     * only attributes.
		     */
                    xmlHashTablePtr triage =
                        (xmlHashTablePtr) define->data;

                    /*
                     * Something we can optimize cleanly there is only one
                     * possble branch out !
                     */
                    if ((node->type == XML_TEXT_NODE) ||
                        (node->type == XML_CDATA_SECTION_NODE)) {
                        list =
                            xmlHashLookup2(triage, BAD_CAST "#text", NULL);
                    } else if (node->type == XML_ELEMENT_NODE) {
                        if (node->ns != NULL) {
                            list = xmlHashLookup2(triage, node->name,
                                                  node->ns->href);
                            if (list == NULL)
                                list =
                                    xmlHashLookup2(triage, BAD_CAST "#any",
                                                   node->ns->href);
                        } else
                            list =
                                xmlHashLookup2(triage, node->name, NULL);
                        if (list == NULL)
                            list =
                                xmlHashLookup2(triage, BAD_CAST "#any",
                                               NULL);
                    }
                    if (list == NULL) {
                        ret = -1;
			VALID_ERR2(XML_RELAXNG_ERR_ELEMWRONG, node->name);
                        break;
                    }
                    ret = xmlRelaxNGValidateDefinition(ctxt, list);
                    if (ret == 0) {
                    }
                    break;
                }

                list = define->content;
                oldflags = ctxt->flags;
                ctxt->flags |= FLAGS_IGNORABLE;

                while (list != NULL) {
                    oldstate = xmlRelaxNGCopyValidState(ctxt, ctxt->state);
                    ret = xmlRelaxNGValidateDefinition(ctxt, list);
                    if (ret == 0) {
                        if (states == NULL) {
                            states = xmlRelaxNGNewStates(ctxt, 1);
                        }
                        if (ctxt->state != NULL) {
                            xmlRelaxNGAddStates(ctxt, states, ctxt->state);
                        } else if (ctxt->states != NULL) {
                            for (i = 0; i < ctxt->states->nbState; i++) {
                                xmlRelaxNGAddStates(ctxt, states,
                                                    ctxt->states->
                                                    tabState[i]);
                            }
                            xmlRelaxNGFreeStates(ctxt, ctxt->states);
                            ctxt->states = NULL;
                        }
                    } else {
                        xmlRelaxNGFreeValidState(ctxt, ctxt->state);
                    }
                    ctxt->state = oldstate;
                    list = list->next;
                }
                if (states != NULL) {
                    xmlRelaxNGFreeValidState(ctxt, oldstate);
                    ctxt->states = states;
                    ctxt->state = NULL;
                    ret = 0;
                } else {
                    ctxt->states = NULL;
                }
                ctxt->flags = oldflags;
                if (ret != 0) {
                    if ((ctxt->flags & FLAGS_IGNORABLE) == 0) {
                        xmlRelaxNGDumpValidError(ctxt);
                    }
                } else {
                    if (ctxt->errNr > errNr)
                        xmlRelaxNGPopErrors(ctxt, errNr);
                }
                break;
            }
        case XML_RELAXNG_DEF:
        case XML_RELAXNG_GROUP:
            ret = xmlRelaxNGValidateDefinitionList(ctxt, define->content);
            break;
        case XML_RELAXNG_INTERLEAVE:
            ret = xmlRelaxNGValidateInterleave(ctxt, define);
            break;
        case XML_RELAXNG_ATTRIBUTE:
            ret = xmlRelaxNGValidateAttribute(ctxt, define);
            break;
        case XML_RELAXNG_START:
        case XML_RELAXNG_NOOP:
        case XML_RELAXNG_REF:
        case XML_RELAXNG_EXTERNALREF:
        case XML_RELAXNG_PARENTREF:
            ret = xmlRelaxNGValidateDefinition(ctxt, define->content);
            break;
        case XML_RELAXNG_DATATYPE:{
                xmlNodePtr child;
                xmlChar *content = NULL;

                child = node;
                while (child != NULL) {
                    if (child->type == XML_ELEMENT_NODE) {
                        VALID_ERR2(XML_RELAXNG_ERR_DATAELEM,
                                   node->parent->name);
                        ret = -1;
                        break;
                    } else if ((child->type == XML_TEXT_NODE) ||
                               (child->type == XML_CDATA_SECTION_NODE)) {
                        content = xmlStrcat(content, child->content);
                    }
                    /* TODO: handle entities ... */
                    child = child->next;
                }
                if (ret == -1) {
                    if (content != NULL)
                        xmlFree(content);
                    break;
                }
                if (content == NULL) {
                    content = xmlStrdup(BAD_CAST "");
                    if (content == NULL) {
                        xmlRngVErrMemory(ctxt, "validating\n");
                        ret = -1;
                        break;
                    }
                }
                ret = xmlRelaxNGValidateDatatype(ctxt, content, define,
                                                 ctxt->state->seq);
                if (ret == -1) {
                    VALID_ERR2(XML_RELAXNG_ERR_DATATYPE, define->name);
                } else if (ret == 0) {
                    ctxt->state->seq = NULL;
                }
                if (content != NULL)
                    xmlFree(content);
                break;
            }
        case XML_RELAXNG_VALUE:{
                xmlChar *content = NULL;
                xmlChar *oldvalue;
                xmlNodePtr child;

                child = node;
                while (child != NULL) {
                    if (child->type == XML_ELEMENT_NODE) {
                        VALID_ERR2(XML_RELAXNG_ERR_VALELEM,
                                   node->parent->name);
                        ret = -1;
                        break;
                    } else if ((child->type == XML_TEXT_NODE) ||
                               (child->type == XML_CDATA_SECTION_NODE)) {
                        content = xmlStrcat(content, child->content);
                    }
                    /* TODO: handle entities ... */
                    child = child->next;
                }
                if (ret == -1) {
                    if (content != NULL)
                        xmlFree(content);
                    break;
                }
                if (content == NULL) {
                    content = xmlStrdup(BAD_CAST "");
                    if (content == NULL) {
                        xmlRngVErrMemory(ctxt, "validating\n");
                        ret = -1;
                        break;
                    }
                }
                oldvalue = ctxt->state->value;
                ctxt->state->value = content;
                ret = xmlRelaxNGValidateValue(ctxt, define);
                ctxt->state->value = oldvalue;
                if (ret == -1) {
                    VALID_ERR2(XML_RELAXNG_ERR_VALUE, define->name);
                } else if (ret == 0) {
                    ctxt->state->seq = NULL;
                }
                if (content != NULL)
                    xmlFree(content);
                break;
            }
        case XML_RELAXNG_LIST:{
                xmlChar *content;
                xmlNodePtr child;
                xmlChar *oldvalue, *oldendvalue;
                int len;

                /*
                 * Make sure it's only text nodes
                 */

                content = NULL;
                child = node;
                while (child != NULL) {
                    if (child->type == XML_ELEMENT_NODE) {
                        VALID_ERR2(XML_RELAXNG_ERR_LISTELEM,
                                   node->parent->name);
                        ret = -1;
                        break;
                    } else if ((child->type == XML_TEXT_NODE) ||
                               (child->type == XML_CDATA_SECTION_NODE)) {
                        content = xmlStrcat(content, child->content);
                    }
                    /* TODO: handle entities ... */
                    child = child->next;
                }
                if (ret == -1) {
                    if (content != NULL)
                        xmlFree(content);
                    break;
                }
                if (content == NULL) {
                    content = xmlStrdup(BAD_CAST "");
                    if (content == NULL) {
                        xmlRngVErrMemory(ctxt, "validating\n");
                        ret = -1;
                        break;
                    }
                }
                len = xmlStrlen(content);
                oldvalue = ctxt->state->value;
                oldendvalue = ctxt->state->endvalue;
                ctxt->state->value = content;
                ctxt->state->endvalue = content + len;
                ret = xmlRelaxNGValidateValue(ctxt, define);
                ctxt->state->value = oldvalue;
                ctxt->state->endvalue = oldendvalue;
                if (ret == -1) {
                    VALID_ERR(XML_RELAXNG_ERR_LIST);
                } else if ((ret == 0) && (node != NULL)) {
                    ctxt->state->seq = node->next;
                }
                if (content != NULL)
                    xmlFree(content);
                break;
            }
        case XML_RELAXNG_EXCEPT:
        case XML_RELAXNG_PARAM:
            TODO ret = -1;
            break;
    }
    ctxt->depth--;
#ifdef DEBUG
    for (i = 0; i < ctxt->depth; i++)
        xmlGenericError(xmlGenericErrorContext, " ");
    xmlGenericError(xmlGenericErrorContext,
                    "Validating %s ", xmlRelaxNGDefName(define));
    if (define->name != NULL)
        xmlGenericError(xmlGenericErrorContext, "%s ", define->name);
    if (ret == 0)
        xmlGenericError(xmlGenericErrorContext, "suceeded\n");
    else
        xmlGenericError(xmlGenericErrorContext, "failed\n");
#endif
    return (ret);
}

/**
 * xmlRelaxNGValidateDefinition:
 * @ctxt:  a Relax-NG validation context
 * @define:  the definition to verify
 *
 * Validate the current node lists against the definition
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateDefinition(xmlRelaxNGValidCtxtPtr ctxt,
                             xmlRelaxNGDefinePtr define)
{
    xmlRelaxNGStatesPtr states, res;
    int i, j, k, ret, oldflags;

    /*
     * We should NOT have both ctxt->state and ctxt->states
     */
    if ((ctxt->state != NULL) && (ctxt->states != NULL)) {
        TODO xmlRelaxNGFreeValidState(ctxt, ctxt->state);
        ctxt->state = NULL;
    }

    if ((ctxt->states == NULL) || (ctxt->states->nbState == 1)) {
        if (ctxt->states != NULL) {
            ctxt->state = ctxt->states->tabState[0];
            xmlRelaxNGFreeStates(ctxt, ctxt->states);
            ctxt->states = NULL;
        }
        ret = xmlRelaxNGValidateState(ctxt, define);
        if ((ctxt->state != NULL) && (ctxt->states != NULL)) {
            TODO xmlRelaxNGFreeValidState(ctxt, ctxt->state);
            ctxt->state = NULL;
        }
        if ((ctxt->states != NULL) && (ctxt->states->nbState == 1)) {
            ctxt->state = ctxt->states->tabState[0];
            xmlRelaxNGFreeStates(ctxt, ctxt->states);
            ctxt->states = NULL;
        }
        return (ret);
    }

    states = ctxt->states;
    ctxt->states = NULL;
    res = NULL;
    j = 0;
    oldflags = ctxt->flags;
    ctxt->flags |= FLAGS_IGNORABLE;
    for (i = 0; i < states->nbState; i++) {
        ctxt->state = states->tabState[i];
        ctxt->states = NULL;
        ret = xmlRelaxNGValidateState(ctxt, define);
        /*
         * We should NOT have both ctxt->state and ctxt->states
         */
        if ((ctxt->state != NULL) && (ctxt->states != NULL)) {
            TODO xmlRelaxNGFreeValidState(ctxt, ctxt->state);
            ctxt->state = NULL;
        }
        if (ret == 0) {
            if (ctxt->states == NULL) {
                if (res != NULL) {
                    /* add the state to the container */
                    xmlRelaxNGAddStates(ctxt, res, ctxt->state);
                    ctxt->state = NULL;
                } else {
                    /* add the state directly in states */
                    states->tabState[j++] = ctxt->state;
                    ctxt->state = NULL;
                }
            } else {
                if (res == NULL) {
                    /* make it the new container and copy other results */
                    res = ctxt->states;
                    ctxt->states = NULL;
                    for (k = 0; k < j; k++)
                        xmlRelaxNGAddStates(ctxt, res,
                                            states->tabState[k]);
                } else {
                    /* add all the new results to res and reff the container */
                    for (k = 0; k < ctxt->states->nbState; k++)
                        xmlRelaxNGAddStates(ctxt, res,
                                            ctxt->states->tabState[k]);
                    xmlRelaxNGFreeStates(ctxt, ctxt->states);
                    ctxt->states = NULL;
                }
            }
        } else {
            if (ctxt->state != NULL) {
                xmlRelaxNGFreeValidState(ctxt, ctxt->state);
                ctxt->state = NULL;
            } else if (ctxt->states != NULL) {
                for (k = 0; k < ctxt->states->nbState; k++)
                    xmlRelaxNGFreeValidState(ctxt,
                                             ctxt->states->tabState[k]);
                xmlRelaxNGFreeStates(ctxt, ctxt->states);
                ctxt->states = NULL;
            }
        }
    }
    ctxt->flags = oldflags;
    if (res != NULL) {
        xmlRelaxNGFreeStates(ctxt, states);
        ctxt->states = res;
        ret = 0;
    } else if (j > 1) {
        states->nbState = j;
        ctxt->states = states;
        ret = 0;
    } else if (j == 1) {
        ctxt->state = states->tabState[0];
        xmlRelaxNGFreeStates(ctxt, states);
        ret = 0;
    } else {
        ret = -1;
        xmlRelaxNGFreeStates(ctxt, states);
        if (ctxt->states != NULL) {
            xmlRelaxNGFreeStates(ctxt, ctxt->states);
            ctxt->states = NULL;
        }
    }
    if ((ctxt->state != NULL) && (ctxt->states != NULL)) {
        TODO xmlRelaxNGFreeValidState(ctxt, ctxt->state);
        ctxt->state = NULL;
    }
    return (ret);
}

/**
 * xmlRelaxNGValidateDocument:
 * @ctxt:  a Relax-NG validation context
 * @doc:  the document
 *
 * Validate the given document
 *
 * Returns 0 if the validation succeeded or an error code.
 */
static int
xmlRelaxNGValidateDocument(xmlRelaxNGValidCtxtPtr ctxt, xmlDocPtr doc)
{
    int ret;
    xmlRelaxNGPtr schema;
    xmlRelaxNGGrammarPtr grammar;
    xmlRelaxNGValidStatePtr state;
    xmlNodePtr node;

    if ((ctxt == NULL) || (ctxt->schema == NULL) || (doc == NULL))
        return (-1);

    ctxt->errNo = XML_RELAXNG_OK;
    schema = ctxt->schema;
    grammar = schema->topgrammar;
    if (grammar == NULL) {
        VALID_ERR(XML_RELAXNG_ERR_NOGRAMMAR);
        return (-1);
    }
    state = xmlRelaxNGNewValidState(ctxt, NULL);
    ctxt->state = state;
    ret = xmlRelaxNGValidateDefinition(ctxt, grammar->start);
    if ((ctxt->state != NULL) && (state->seq != NULL)) {
        state = ctxt->state;
        node = state->seq;
        node = xmlRelaxNGSkipIgnored(ctxt, node);
        if (node != NULL) {
            if (ret != -1) {
                VALID_ERR(XML_RELAXNG_ERR_EXTRADATA);
                ret = -1;
            }
        }
    } else if (ctxt->states != NULL) {
        int i;
        int tmp = -1;

        for (i = 0; i < ctxt->states->nbState; i++) {
            state = ctxt->states->tabState[i];
            node = state->seq;
            node = xmlRelaxNGSkipIgnored(ctxt, node);
            if (node == NULL)
                tmp = 0;
            xmlRelaxNGFreeValidState(ctxt, state);
        }
        if (tmp == -1) {
            if (ret != -1) {
                VALID_ERR(XML_RELAXNG_ERR_EXTRADATA);
                ret = -1;
            }
        }
    }
    if (ctxt->state != NULL) {
        xmlRelaxNGFreeValidState(ctxt, ctxt->state);
        ctxt->state = NULL;
    }
    if (ret != 0)
        xmlRelaxNGDumpValidError(ctxt);
#ifdef DEBUG
    else if (ctxt->errNr != 0) {
        ctxt->error(ctxt->userData,
                    "%d Extra error messages left on stack !\n",
                    ctxt->errNr);
        xmlRelaxNGDumpValidError(ctxt);
    }
#endif
#ifdef LIBXML_VALID_ENABLED
    if (ctxt->idref == 1) {
        xmlValidCtxt vctxt;

        memset(&vctxt, 0, sizeof(xmlValidCtxt));
        vctxt.valid = 1;
        vctxt.error = ctxt->error;
        vctxt.warning = ctxt->warning;
        vctxt.userData = ctxt->userData;

        if (xmlValidateDocumentFinal(&vctxt, doc) != 1)
            ret = -1;
    }
#endif /* LIBXML_VALID_ENABLED */
    if ((ret == 0) && (ctxt->errNo != XML_RELAXNG_OK))
        ret = -1;

    return (ret);
}

/**
 * xmlRelaxNGCleanPSVI:
 * @node:  an input element or document
 *
 * Call this routine to speed up XPath computation on static documents.
 * This stamps all the element nodes with the document order
 * Like for line information, the order is kept in the element->content
 * field, the value stored is actually - the node number (starting at -1)
 * to be able to differentiate from line numbers.
 *
 * Returns the number of elements found in the document or -1 in case
 *    of error.
 */
static void
xmlRelaxNGCleanPSVI(xmlNodePtr node) {
    xmlNodePtr cur;

    if ((node == NULL) ||
        ((node->type != XML_ELEMENT_NODE) &&
         (node->type != XML_DOCUMENT_NODE) &&
         (node->type != XML_HTML_DOCUMENT_NODE)))
	return;
    if (node->type == XML_ELEMENT_NODE)
        node->psvi = NULL;

    cur = node->children;
    while (cur != NULL) {
	if (cur->type == XML_ELEMENT_NODE) {
	    cur->psvi = NULL;
	    if (cur->children != NULL) {
		cur = cur->children;
		continue;
	    }
	}
	if (cur->next != NULL) {
	    cur = cur->next;
	    continue;
	}
	do {
	    cur = cur->parent;
	    if (cur == NULL)
		break;
	    if (cur == node) {
		cur = NULL;
		break;
	    }
	    if (cur->next != NULL) {
		cur = cur->next;
		break;
	    }
	} while (cur != NULL);
    }
    return;
}
/************************************************************************
 *									*
 *			Validation interfaces				*
 *									*
 ************************************************************************/

/**
 * xmlRelaxNGNewValidCtxt:
 * @schema:  a precompiled XML RelaxNGs
 *
 * Create an XML RelaxNGs validation context based on the given schema
 *
 * Returns the validation context or NULL in case of error
 */
xmlRelaxNGValidCtxtPtr
xmlRelaxNGNewValidCtxt(xmlRelaxNGPtr schema)
{
    xmlRelaxNGValidCtxtPtr ret;

    ret = (xmlRelaxNGValidCtxtPtr) xmlMalloc(sizeof(xmlRelaxNGValidCtxt));
    if (ret == NULL) {
        xmlRngVErrMemory(NULL, "building context\n");
        return (NULL);
    }
    memset(ret, 0, sizeof(xmlRelaxNGValidCtxt));
    ret->schema = schema;
    ret->error = xmlGenericError;
    ret->userData = xmlGenericErrorContext;
    ret->errNr = 0;
    ret->errMax = 0;
    ret->err = NULL;
    ret->errTab = NULL;
    if (schema != NULL)
	ret->idref = schema->idref;
    ret->states = NULL;
    ret->freeState = NULL;
    ret->freeStates = NULL;
    ret->errNo = XML_RELAXNG_OK;
    return (ret);
}

/**
 * xmlRelaxNGFreeValidCtxt:
 * @ctxt:  the schema validation context
 *
 * Free the resources associated to the schema validation context
 */
void
xmlRelaxNGFreeValidCtxt(xmlRelaxNGValidCtxtPtr ctxt)
{
    int k;

    if (ctxt == NULL)
        return;
    if (ctxt->states != NULL)
        xmlRelaxNGFreeStates(NULL, ctxt->states);
    if (ctxt->freeState != NULL) {
        for (k = 0; k < ctxt->freeState->nbState; k++) {
            xmlRelaxNGFreeValidState(NULL, ctxt->freeState->tabState[k]);
        }
        xmlRelaxNGFreeStates(NULL, ctxt->freeState);
    }
    if (ctxt->freeStates != NULL) {
        for (k = 0; k < ctxt->freeStatesNr; k++) {
            xmlRelaxNGFreeStates(NULL, ctxt->freeStates[k]);
        }
        xmlFree(ctxt->freeStates);
    }
    if (ctxt->errTab != NULL)
        xmlFree(ctxt->errTab);
    if (ctxt->elemTab != NULL) {
        xmlRegExecCtxtPtr exec;

        exec = xmlRelaxNGElemPop(ctxt);
        while (exec != NULL) {
            xmlRegFreeExecCtxt(exec);
            exec = xmlRelaxNGElemPop(ctxt);
        }
        xmlFree(ctxt->elemTab);
    }
    xmlFree(ctxt);
}

/**
 * xmlRelaxNGSetValidErrors:
 * @ctxt:  a Relax-NG validation context
 * @err:  the error function
 * @warn: the warning function
 * @ctx: the functions context
 *
 * Set the error and warning callback informations
 */
void
xmlRelaxNGSetValidErrors(xmlRelaxNGValidCtxtPtr ctxt,
                         xmlRelaxNGValidityErrorFunc err,
                         xmlRelaxNGValidityWarningFunc warn, void *ctx)
{
    if (ctxt == NULL)
        return;
    ctxt->error = err;
    ctxt->warning = warn;
    ctxt->userData = ctx;
    ctxt->serror = NULL;
}

/**
 * xmlRelaxNGSetValidStructuredErrors:
 * @ctxt:  a Relax-NG validation context
 * @serror:  the structured error function
 * @ctx: the functions context
 *
 * Set the structured error callback
 */
void
xmlRelaxNGSetValidStructuredErrors(xmlRelaxNGValidCtxtPtr ctxt,
                                   xmlStructuredErrorFunc serror, void *ctx)
{
    if (ctxt == NULL)
        return;
    ctxt->serror = serror;
    ctxt->error = NULL;
    ctxt->warning = NULL;
    ctxt->userData = ctx;
}

/**
 * xmlRelaxNGGetValidErrors:
 * @ctxt:  a Relax-NG validation context
 * @err:  the error function result
 * @warn: the warning function result
 * @ctx: the functions context result
 *
 * Get the error and warning callback informations
 *
 * Returns -1 in case of error and 0 otherwise
 */
int
xmlRelaxNGGetValidErrors(xmlRelaxNGValidCtxtPtr ctxt,
                         xmlRelaxNGValidityErrorFunc * err,
                         xmlRelaxNGValidityWarningFunc * warn, void **ctx)
{
    if (ctxt == NULL)
        return (-1);
    if (err != NULL)
        *err = ctxt->error;
    if (warn != NULL)
        *warn = ctxt->warning;
    if (ctx != NULL)
        *ctx = ctxt->userData;
    return (0);
}

/**
 * xmlRelaxNGValidateDoc:
 * @ctxt:  a Relax-NG validation context
 * @doc:  a parsed document tree
 *
 * Validate a document tree in memory.
 *
 * Returns 0 if the document is valid, a positive error code
 *     number otherwise and -1 in case of internal or API error.
 */
int
xmlRelaxNGValidateDoc(xmlRelaxNGValidCtxtPtr ctxt, xmlDocPtr doc)
{
    int ret;

    if ((ctxt == NULL) || (doc == NULL))
        return (-1);

    ctxt->doc = doc;

    ret = xmlRelaxNGValidateDocument(ctxt, doc);
    /*
     * Remove all left PSVI
     */
    xmlRelaxNGCleanPSVI((xmlNodePtr) doc);

    /*
     * TODO: build error codes
     */
    if (ret == -1)
        return (1);
    return (ret);
}

#define bottom_relaxng
#include "elfgcchack.h"
#endif /* LIBXML_SCHEMAS_ENABLED */
