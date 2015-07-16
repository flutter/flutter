/*
 * xpath.c: XML Path Language implementation
 *          XPath is a language for addressing parts of an XML document,
 *          designed to be used by both XSLT and XPointer
 *f
 * Reference: W3C Recommendation 16 November 1999
 *     http://www.w3.org/TR/1999/REC-xpath-19991116
 * Public reference:
 *     http://www.w3.org/TR/xpath
 *
 * See Copyright for the status of this software
 *
 * Author: daniel@veillard.com
 *
 */

#define IN_LIBXML
#include "libxml.h"

#include <string.h>

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_MATH_H
#include <math.h>
#endif
#ifdef HAVE_FLOAT_H
#include <float.h>
#endif
#ifdef HAVE_CTYPE_H
#include <ctype.h>
#endif
#ifdef HAVE_SIGNAL_H
#include <signal.h>
#endif

#include <libxml/xmlmemory.h>
#include <libxml/tree.h>
#include <libxml/valid.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxml/parserInternals.h>
#include <libxml/hash.h>
#ifdef LIBXML_XPTR_ENABLED
#include <libxml/xpointer.h>
#endif
#ifdef LIBXML_DEBUG_ENABLED
#include <libxml/debugXML.h>
#endif
#include <libxml/xmlerror.h>
#include <libxml/threads.h>
#include <libxml/globals.h>
#ifdef LIBXML_PATTERN_ENABLED
#include <libxml/pattern.h>
#endif

#ifdef LIBXML_PATTERN_ENABLED
#define XPATH_STREAMING
#endif

#define TODO								\
    xmlGenericError(xmlGenericErrorContext,				\
	    "Unimplemented block at %s:%d\n",				\
            __FILE__, __LINE__);

/*
* XP_OPTIMIZED_NON_ELEM_COMPARISON:
* If defined, this will use xmlXPathCmpNodesExt() instead of
* xmlXPathCmpNodes(). The new function is optimized comparison of
* non-element nodes; actually it will speed up comparison only if
* xmlXPathOrderDocElems() was called in order to index the elements of
* a tree in document order; Libxslt does such an indexing, thus it will
* benefit from this optimization.
*/
#define XP_OPTIMIZED_NON_ELEM_COMPARISON

/*
* XP_OPTIMIZED_FILTER_FIRST:
* If defined, this will optimize expressions like "key('foo', 'val')[b][1]"
* in a way, that it stop evaluation at the first node.
*/
#define XP_OPTIMIZED_FILTER_FIRST

/*
* XP_DEBUG_OBJ_USAGE:
* Internal flag to enable tracking of how much XPath objects have been
* created.
*/
/* #define XP_DEBUG_OBJ_USAGE */

/*
 * TODO:
 * There are a few spots where some tests are done which depend upon ascii
 * data.  These should be enhanced for full UTF8 support (see particularly
 * any use of the macros IS_ASCII_CHARACTER and IS_ASCII_DIGIT)
 */

#if defined(LIBXML_XPATH_ENABLED) || defined(LIBXML_SCHEMAS_ENABLED)

/************************************************************************
 *									*
 *			Floating point stuff				*
 *									*
 ************************************************************************/

#ifndef TRIO_REPLACE_STDIO
#define TRIO_PUBLIC static
#endif
#include "trionan.c"

/*
 * The lack of portability of this section of the libc is annoying !
 */
double xmlXPathNAN = 0;
double xmlXPathPINF = 1;
double xmlXPathNINF = -1;
static double xmlXPathNZERO = 0; /* not exported from headers */
static int xmlXPathInitialized = 0;

/**
 * xmlXPathInit:
 *
 * Initialize the XPath environment
 */
void
xmlXPathInit(void) {
    if (xmlXPathInitialized) return;

    xmlXPathPINF = trio_pinf();
    xmlXPathNINF = trio_ninf();
    xmlXPathNAN = trio_nan();
    xmlXPathNZERO = trio_nzero();

    xmlXPathInitialized = 1;
}

/**
 * xmlXPathIsNaN:
 * @val:  a double value
 *
 * Provides a portable isnan() function to detect whether a double
 * is a NotaNumber. Based on trio code
 * http://sourceforge.net/projects/ctrio/
 *
 * Returns 1 if the value is a NaN, 0 otherwise
 */
int
xmlXPathIsNaN(double val) {
    return(trio_isnan(val));
}

/**
 * xmlXPathIsInf:
 * @val:  a double value
 *
 * Provides a portable isinf() function to detect whether a double
 * is a +Infinite or -Infinite. Based on trio code
 * http://sourceforge.net/projects/ctrio/
 *
 * Returns 1 vi the value is +Infinite, -1 if -Infinite, 0 otherwise
 */
int
xmlXPathIsInf(double val) {
    return(trio_isinf(val));
}

#endif /* SCHEMAS or XPATH */
#ifdef LIBXML_XPATH_ENABLED
/**
 * xmlXPathGetSign:
 * @val:  a double value
 *
 * Provides a portable function to detect the sign of a double
 * Modified from trio code
 * http://sourceforge.net/projects/ctrio/
 *
 * Returns 1 if the value is Negative, 0 if positive
 */
static int
xmlXPathGetSign(double val) {
    return(trio_signbit(val));
}


/*
 * TODO: when compatibility allows remove all "fake node libxslt" strings
 *       the test should just be name[0] = ' '
 */
#ifdef DEBUG_XPATH_EXPRESSION
#define DEBUG_STEP
#define DEBUG_EXPR
#define DEBUG_EVAL_COUNTS
#endif

static xmlNs xmlXPathXMLNamespaceStruct = {
    NULL,
    XML_NAMESPACE_DECL,
    XML_XML_NAMESPACE,
    BAD_CAST "xml",
    NULL,
    NULL
};
static xmlNsPtr xmlXPathXMLNamespace = &xmlXPathXMLNamespaceStruct;
#ifndef LIBXML_THREAD_ENABLED
/*
 * Optimizer is disabled only when threaded apps are detected while
 * the library ain't compiled for thread safety.
 */
static int xmlXPathDisableOptimizer = 0;
#endif

/************************************************************************
 *									*
 *			Error handling routines				*
 *									*
 ************************************************************************/

/**
 * XP_ERRORNULL:
 * @X:  the error code
 *
 * Macro to raise an XPath error and return NULL.
 */
#define XP_ERRORNULL(X)							\
    { xmlXPathErr(ctxt, X); return(NULL); }

/*
 * The array xmlXPathErrorMessages corresponds to the enum xmlXPathError
 */
static const char *xmlXPathErrorMessages[] = {
    "Ok\n",
    "Number encoding\n",
    "Unfinished literal\n",
    "Start of literal\n",
    "Expected $ for variable reference\n",
    "Undefined variable\n",
    "Invalid predicate\n",
    "Invalid expression\n",
    "Missing closing curly brace\n",
    "Unregistered function\n",
    "Invalid operand\n",
    "Invalid type\n",
    "Invalid number of arguments\n",
    "Invalid context size\n",
    "Invalid context position\n",
    "Memory allocation error\n",
    "Syntax error\n",
    "Resource error\n",
    "Sub resource error\n",
    "Undefined namespace prefix\n",
    "Encoding error\n",
    "Char out of XML range\n",
    "Invalid or incomplete context\n",
    "?? Unknown error ??\n"	/* Must be last in the list! */
};
#define MAXERRNO ((int)(sizeof(xmlXPathErrorMessages) /	\
		   sizeof(xmlXPathErrorMessages[0])) - 1)
/**
 * xmlXPathErrMemory:
 * @ctxt:  an XPath context
 * @extra:  extra informations
 *
 * Handle a redefinition of attribute error
 */
static void
xmlXPathErrMemory(xmlXPathContextPtr ctxt, const char *extra)
{
    if (ctxt != NULL) {
        if (extra) {
            xmlChar buf[200];

            xmlStrPrintf(buf, 200,
                         BAD_CAST "Memory allocation failed : %s\n",
                         extra);
            ctxt->lastError.message = (char *) xmlStrdup(buf);
        } else {
            ctxt->lastError.message = (char *)
	       xmlStrdup(BAD_CAST "Memory allocation failed\n");
        }
        ctxt->lastError.domain = XML_FROM_XPATH;
        ctxt->lastError.code = XML_ERR_NO_MEMORY;
	if (ctxt->error != NULL)
	    ctxt->error(ctxt->userData, &ctxt->lastError);
    } else {
        if (extra)
            __xmlRaiseError(NULL, NULL, NULL,
                            NULL, NULL, XML_FROM_XPATH,
                            XML_ERR_NO_MEMORY, XML_ERR_FATAL, NULL, 0,
                            extra, NULL, NULL, 0, 0,
                            "Memory allocation failed : %s\n", extra);
        else
            __xmlRaiseError(NULL, NULL, NULL,
                            NULL, NULL, XML_FROM_XPATH,
                            XML_ERR_NO_MEMORY, XML_ERR_FATAL, NULL, 0,
                            NULL, NULL, NULL, 0, 0,
                            "Memory allocation failed\n");
    }
}

/**
 * xmlXPathPErrMemory:
 * @ctxt:  an XPath parser context
 * @extra:  extra informations
 *
 * Handle a redefinition of attribute error
 */
static void
xmlXPathPErrMemory(xmlXPathParserContextPtr ctxt, const char *extra)
{
    if (ctxt == NULL)
	xmlXPathErrMemory(NULL, extra);
    else {
	ctxt->error = XPATH_MEMORY_ERROR;
	xmlXPathErrMemory(ctxt->context, extra);
    }
}

/**
 * xmlXPathErr:
 * @ctxt:  a XPath parser context
 * @error:  the error code
 *
 * Handle an XPath error
 */
void
xmlXPathErr(xmlXPathParserContextPtr ctxt, int error)
{
    if ((error < 0) || (error > MAXERRNO))
	error = MAXERRNO;
    if (ctxt == NULL) {
	__xmlRaiseError(NULL, NULL, NULL,
			NULL, NULL, XML_FROM_XPATH,
			error + XML_XPATH_EXPRESSION_OK - XPATH_EXPRESSION_OK,
			XML_ERR_ERROR, NULL, 0,
			NULL, NULL, NULL, 0, 0,
			"%s", xmlXPathErrorMessages[error]);
	return;
    }
    ctxt->error = error;
    if (ctxt->context == NULL) {
	__xmlRaiseError(NULL, NULL, NULL,
			NULL, NULL, XML_FROM_XPATH,
			error + XML_XPATH_EXPRESSION_OK - XPATH_EXPRESSION_OK,
			XML_ERR_ERROR, NULL, 0,
			(const char *) ctxt->base, NULL, NULL,
			ctxt->cur - ctxt->base, 0,
			"%s", xmlXPathErrorMessages[error]);
	return;
    }

    /* cleanup current last error */
    xmlResetError(&ctxt->context->lastError);

    ctxt->context->lastError.domain = XML_FROM_XPATH;
    ctxt->context->lastError.code = error + XML_XPATH_EXPRESSION_OK -
                           XPATH_EXPRESSION_OK;
    ctxt->context->lastError.level = XML_ERR_ERROR;
    ctxt->context->lastError.str1 = (char *) xmlStrdup(ctxt->base);
    ctxt->context->lastError.int1 = ctxt->cur - ctxt->base;
    ctxt->context->lastError.node = ctxt->context->debugNode;
    if (ctxt->context->error != NULL) {
	ctxt->context->error(ctxt->context->userData,
	                     &ctxt->context->lastError);
    } else {
	__xmlRaiseError(NULL, NULL, NULL,
			NULL, ctxt->context->debugNode, XML_FROM_XPATH,
			error + XML_XPATH_EXPRESSION_OK - XPATH_EXPRESSION_OK,
			XML_ERR_ERROR, NULL, 0,
			(const char *) ctxt->base, NULL, NULL,
			ctxt->cur - ctxt->base, 0,
			"%s", xmlXPathErrorMessages[error]);
    }

}

/**
 * xmlXPatherror:
 * @ctxt:  the XPath Parser context
 * @file:  the file name
 * @line:  the line number
 * @no:  the error number
 *
 * Formats an error message.
 */
void
xmlXPatherror(xmlXPathParserContextPtr ctxt, const char *file ATTRIBUTE_UNUSED,
              int line ATTRIBUTE_UNUSED, int no) {
    xmlXPathErr(ctxt, no);
}

/************************************************************************
 *									*
 *			Utilities					*
 *									*
 ************************************************************************/

/**
 * xsltPointerList:
 *
 * Pointer-list for various purposes.
 */
typedef struct _xmlPointerList xmlPointerList;
typedef xmlPointerList *xmlPointerListPtr;
struct _xmlPointerList {
    void **items;
    int number;
    int size;
};
/*
* TODO: Since such a list-handling is used in xmlschemas.c and libxslt
* and here, we should make the functions public.
*/
static int
xmlPointerListAddSize(xmlPointerListPtr list,
		       void *item,
		       int initialSize)
{
    if (list->items == NULL) {
	if (initialSize <= 0)
	    initialSize = 1;
	list->items = (void **) xmlMalloc(
	    initialSize * sizeof(void *));
	if (list->items == NULL) {
	    xmlXPathErrMemory(NULL,
		"xmlPointerListCreate: allocating item\n");
	    return(-1);
	}
	list->number = 0;
	list->size = initialSize;
    } else if (list->size <= list->number) {
	list->size *= 2;
	list->items = (void **) xmlRealloc(list->items,
	    list->size * sizeof(void *));
	if (list->items == NULL) {
	    xmlXPathErrMemory(NULL,
		"xmlPointerListCreate: re-allocating item\n");
	    list->size = 0;
	    return(-1);
	}
    }
    list->items[list->number++] = item;
    return(0);
}

/**
 * xsltPointerListCreate:
 *
 * Creates an xsltPointerList structure.
 *
 * Returns a xsltPointerList structure or NULL in case of an error.
 */
static xmlPointerListPtr
xmlPointerListCreate(int initialSize)
{
    xmlPointerListPtr ret;

    ret = xmlMalloc(sizeof(xmlPointerList));
    if (ret == NULL) {
	xmlXPathErrMemory(NULL,
	    "xmlPointerListCreate: allocating item\n");
	return (NULL);
    }
    memset(ret, 0, sizeof(xmlPointerList));
    if (initialSize > 0) {
	xmlPointerListAddSize(ret, NULL, initialSize);
	ret->number = 0;
    }
    return (ret);
}

/**
 * xsltPointerListFree:
 *
 * Frees the xsltPointerList structure. This does not free
 * the content of the list.
 */
static void
xmlPointerListFree(xmlPointerListPtr list)
{
    if (list == NULL)
	return;
    if (list->items != NULL)
	xmlFree(list->items);
    xmlFree(list);
}

/************************************************************************
 *									*
 *			Parser Types					*
 *									*
 ************************************************************************/

/*
 * Types are private:
 */

typedef enum {
    XPATH_OP_END=0,
    XPATH_OP_AND,
    XPATH_OP_OR,
    XPATH_OP_EQUAL,
    XPATH_OP_CMP,
    XPATH_OP_PLUS,
    XPATH_OP_MULT,
    XPATH_OP_UNION,
    XPATH_OP_ROOT,
    XPATH_OP_NODE,
    XPATH_OP_RESET, /* 10 */
    XPATH_OP_COLLECT,
    XPATH_OP_VALUE, /* 12 */
    XPATH_OP_VARIABLE,
    XPATH_OP_FUNCTION,
    XPATH_OP_ARG,
    XPATH_OP_PREDICATE,
    XPATH_OP_FILTER, /* 17 */
    XPATH_OP_SORT /* 18 */
#ifdef LIBXML_XPTR_ENABLED
    ,XPATH_OP_RANGETO
#endif
} xmlXPathOp;

typedef enum {
    AXIS_ANCESTOR = 1,
    AXIS_ANCESTOR_OR_SELF,
    AXIS_ATTRIBUTE,
    AXIS_CHILD,
    AXIS_DESCENDANT,
    AXIS_DESCENDANT_OR_SELF,
    AXIS_FOLLOWING,
    AXIS_FOLLOWING_SIBLING,
    AXIS_NAMESPACE,
    AXIS_PARENT,
    AXIS_PRECEDING,
    AXIS_PRECEDING_SIBLING,
    AXIS_SELF
} xmlXPathAxisVal;

typedef enum {
    NODE_TEST_NONE = 0,
    NODE_TEST_TYPE = 1,
    NODE_TEST_PI = 2,
    NODE_TEST_ALL = 3,
    NODE_TEST_NS = 4,
    NODE_TEST_NAME = 5
} xmlXPathTestVal;

typedef enum {
    NODE_TYPE_NODE = 0,
    NODE_TYPE_COMMENT = XML_COMMENT_NODE,
    NODE_TYPE_TEXT = XML_TEXT_NODE,
    NODE_TYPE_PI = XML_PI_NODE
} xmlXPathTypeVal;

#define XP_REWRITE_DOS_CHILD_ELEM 1

typedef struct _xmlXPathStepOp xmlXPathStepOp;
typedef xmlXPathStepOp *xmlXPathStepOpPtr;
struct _xmlXPathStepOp {
    xmlXPathOp op;		/* The identifier of the operation */
    int ch1;			/* First child */
    int ch2;			/* Second child */
    int value;
    int value2;
    int value3;
    void *value4;
    void *value5;
    void *cache;
    void *cacheURI;
    int rewriteType;
};

struct _xmlXPathCompExpr {
    int nbStep;			/* Number of steps in this expression */
    int maxStep;		/* Maximum number of steps allocated */
    xmlXPathStepOp *steps;	/* ops for computation of this expression */
    int last;			/* index of last step in expression */
    xmlChar *expr;		/* the expression being computed */
    xmlDictPtr dict;		/* the dictionnary to use if any */
#ifdef DEBUG_EVAL_COUNTS
    int nb;
    xmlChar *string;
#endif
#ifdef XPATH_STREAMING
    xmlPatternPtr stream;
#endif
};

/************************************************************************
 *									*
 *			Forward declarations				*
 *									*
 ************************************************************************/
static void
xmlXPathFreeValueTree(xmlNodeSetPtr obj);
static void
xmlXPathReleaseObject(xmlXPathContextPtr ctxt, xmlXPathObjectPtr obj);
static int
xmlXPathCompOpEvalFirst(xmlXPathParserContextPtr ctxt,
                        xmlXPathStepOpPtr op, xmlNodePtr *first);
static int
xmlXPathCompOpEvalToBoolean(xmlXPathParserContextPtr ctxt,
			    xmlXPathStepOpPtr op,
			    int isPredicate);

/************************************************************************
 *									*
 *			Parser Type functions				*
 *									*
 ************************************************************************/

/**
 * xmlXPathNewCompExpr:
 *
 * Create a new Xpath component
 *
 * Returns the newly allocated xmlXPathCompExprPtr or NULL in case of error
 */
static xmlXPathCompExprPtr
xmlXPathNewCompExpr(void) {
    xmlXPathCompExprPtr cur;

    cur = (xmlXPathCompExprPtr) xmlMalloc(sizeof(xmlXPathCompExpr));
    if (cur == NULL) {
        xmlXPathErrMemory(NULL, "allocating component\n");
	return(NULL);
    }
    memset(cur, 0, sizeof(xmlXPathCompExpr));
    cur->maxStep = 10;
    cur->nbStep = 0;
    cur->steps = (xmlXPathStepOp *) xmlMalloc(cur->maxStep *
	                                   sizeof(xmlXPathStepOp));
    if (cur->steps == NULL) {
        xmlXPathErrMemory(NULL, "allocating steps\n");
	xmlFree(cur);
	return(NULL);
    }
    memset(cur->steps, 0, cur->maxStep * sizeof(xmlXPathStepOp));
    cur->last = -1;
#ifdef DEBUG_EVAL_COUNTS
    cur->nb = 0;
#endif
    return(cur);
}

/**
 * xmlXPathFreeCompExpr:
 * @comp:  an XPATH comp
 *
 * Free up the memory allocated by @comp
 */
void
xmlXPathFreeCompExpr(xmlXPathCompExprPtr comp)
{
    xmlXPathStepOpPtr op;
    int i;

    if (comp == NULL)
        return;
    if (comp->dict == NULL) {
	for (i = 0; i < comp->nbStep; i++) {
	    op = &comp->steps[i];
	    if (op->value4 != NULL) {
		if (op->op == XPATH_OP_VALUE)
		    xmlXPathFreeObject(op->value4);
		else
		    xmlFree(op->value4);
	    }
	    if (op->value5 != NULL)
		xmlFree(op->value5);
	}
    } else {
	for (i = 0; i < comp->nbStep; i++) {
	    op = &comp->steps[i];
	    if (op->value4 != NULL) {
		if (op->op == XPATH_OP_VALUE)
		    xmlXPathFreeObject(op->value4);
	    }
	}
        xmlDictFree(comp->dict);
    }
    if (comp->steps != NULL) {
        xmlFree(comp->steps);
    }
#ifdef DEBUG_EVAL_COUNTS
    if (comp->string != NULL) {
        xmlFree(comp->string);
    }
#endif
#ifdef XPATH_STREAMING
    if (comp->stream != NULL) {
        xmlFreePatternList(comp->stream);
    }
#endif
    if (comp->expr != NULL) {
        xmlFree(comp->expr);
    }

    xmlFree(comp);
}

/**
 * xmlXPathCompExprAdd:
 * @comp:  the compiled expression
 * @ch1: first child index
 * @ch2: second child index
 * @op:  an op
 * @value:  the first int value
 * @value2:  the second int value
 * @value3:  the third int value
 * @value4:  the first string value
 * @value5:  the second string value
 *
 * Add a step to an XPath Compiled Expression
 *
 * Returns -1 in case of failure, the index otherwise
 */
static int
xmlXPathCompExprAdd(xmlXPathCompExprPtr comp, int ch1, int ch2,
   xmlXPathOp op, int value,
   int value2, int value3, void *value4, void *value5) {
    if (comp->nbStep >= comp->maxStep) {
	xmlXPathStepOp *real;

	comp->maxStep *= 2;
	real = (xmlXPathStepOp *) xmlRealloc(comp->steps,
		                      comp->maxStep * sizeof(xmlXPathStepOp));
	if (real == NULL) {
	    comp->maxStep /= 2;
	    xmlXPathErrMemory(NULL, "adding step\n");
	    return(-1);
	}
	comp->steps = real;
    }
    comp->last = comp->nbStep;
    comp->steps[comp->nbStep].rewriteType = 0;
    comp->steps[comp->nbStep].ch1 = ch1;
    comp->steps[comp->nbStep].ch2 = ch2;
    comp->steps[comp->nbStep].op = op;
    comp->steps[comp->nbStep].value = value;
    comp->steps[comp->nbStep].value2 = value2;
    comp->steps[comp->nbStep].value3 = value3;
    if ((comp->dict != NULL) &&
        ((op == XPATH_OP_FUNCTION) || (op == XPATH_OP_VARIABLE) ||
	 (op == XPATH_OP_COLLECT))) {
        if (value4 != NULL) {
	    comp->steps[comp->nbStep].value4 = (xmlChar *)
	        (void *)xmlDictLookup(comp->dict, value4, -1);
	    xmlFree(value4);
	} else
	    comp->steps[comp->nbStep].value4 = NULL;
        if (value5 != NULL) {
	    comp->steps[comp->nbStep].value5 = (xmlChar *)
	        (void *)xmlDictLookup(comp->dict, value5, -1);
	    xmlFree(value5);
	} else
	    comp->steps[comp->nbStep].value5 = NULL;
    } else {
	comp->steps[comp->nbStep].value4 = value4;
	comp->steps[comp->nbStep].value5 = value5;
    }
    comp->steps[comp->nbStep].cache = NULL;
    return(comp->nbStep++);
}

/**
 * xmlXPathCompSwap:
 * @comp:  the compiled expression
 * @op: operation index
 *
 * Swaps 2 operations in the compiled expression
 */
static void
xmlXPathCompSwap(xmlXPathStepOpPtr op) {
    int tmp;

#ifndef LIBXML_THREAD_ENABLED
    /*
     * Since this manipulates possibly shared variables, this is
     * disabled if one detects that the library is used in a multithreaded
     * application
     */
    if (xmlXPathDisableOptimizer)
	return;
#endif

    tmp = op->ch1;
    op->ch1 = op->ch2;
    op->ch2 = tmp;
}

#define PUSH_FULL_EXPR(op, op1, op2, val, val2, val3, val4, val5)	\
    xmlXPathCompExprAdd(ctxt->comp, (op1), (op2),			\
	                (op), (val), (val2), (val3), (val4), (val5))
#define PUSH_LONG_EXPR(op, val, val2, val3, val4, val5)			\
    xmlXPathCompExprAdd(ctxt->comp, ctxt->comp->last, -1,		\
	                (op), (val), (val2), (val3), (val4), (val5))

#define PUSH_LEAVE_EXPR(op, val, val2)					\
xmlXPathCompExprAdd(ctxt->comp, -1, -1, (op), (val), (val2), 0 ,NULL ,NULL)

#define PUSH_UNARY_EXPR(op, ch, val, val2)				\
xmlXPathCompExprAdd(ctxt->comp, (ch), -1, (op), (val), (val2), 0 ,NULL ,NULL)

#define PUSH_BINARY_EXPR(op, ch1, ch2, val, val2)			\
xmlXPathCompExprAdd(ctxt->comp, (ch1), (ch2), (op),			\
			(val), (val2), 0 ,NULL ,NULL)

/************************************************************************
 *									*
 *		XPath object cache structures				*
 *									*
 ************************************************************************/

/* #define XP_DEFAULT_CACHE_ON */

#define XP_HAS_CACHE(c) ((c != NULL) && ((c)->cache != NULL))

typedef struct _xmlXPathContextCache xmlXPathContextCache;
typedef xmlXPathContextCache *xmlXPathContextCachePtr;
struct _xmlXPathContextCache {
    xmlPointerListPtr nodesetObjs;  /* contains xmlXPathObjectPtr */
    xmlPointerListPtr stringObjs;   /* contains xmlXPathObjectPtr */
    xmlPointerListPtr booleanObjs;  /* contains xmlXPathObjectPtr */
    xmlPointerListPtr numberObjs;   /* contains xmlXPathObjectPtr */
    xmlPointerListPtr miscObjs;     /* contains xmlXPathObjectPtr */
    int maxNodeset;
    int maxString;
    int maxBoolean;
    int maxNumber;
    int maxMisc;
#ifdef XP_DEBUG_OBJ_USAGE
    int dbgCachedAll;
    int dbgCachedNodeset;
    int dbgCachedString;
    int dbgCachedBool;
    int dbgCachedNumber;
    int dbgCachedPoint;
    int dbgCachedRange;
    int dbgCachedLocset;
    int dbgCachedUsers;
    int dbgCachedXSLTTree;
    int dbgCachedUndefined;


    int dbgReusedAll;
    int dbgReusedNodeset;
    int dbgReusedString;
    int dbgReusedBool;
    int dbgReusedNumber;
    int dbgReusedPoint;
    int dbgReusedRange;
    int dbgReusedLocset;
    int dbgReusedUsers;
    int dbgReusedXSLTTree;
    int dbgReusedUndefined;

#endif
};

/************************************************************************
 *									*
 *		Debugging related functions				*
 *									*
 ************************************************************************/

#define STRANGE							\
    xmlGenericError(xmlGenericErrorContext,				\
	    "Internal error at %s:%d\n",				\
            __FILE__, __LINE__);

#ifdef LIBXML_DEBUG_ENABLED
static void
xmlXPathDebugDumpNode(FILE *output, xmlNodePtr cur, int depth) {
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;
    if (cur == NULL) {
	fprintf(output, "%s", shift);
	fprintf(output, "Node is NULL !\n");
	return;

    }

    if ((cur->type == XML_DOCUMENT_NODE) ||
	     (cur->type == XML_HTML_DOCUMENT_NODE)) {
	fprintf(output, "%s", shift);
	fprintf(output, " /\n");
    } else if (cur->type == XML_ATTRIBUTE_NODE)
	xmlDebugDumpAttr(output, (xmlAttrPtr)cur, depth);
    else
	xmlDebugDumpOneNode(output, cur, depth);
}
static void
xmlXPathDebugDumpNodeList(FILE *output, xmlNodePtr cur, int depth) {
    xmlNodePtr tmp;
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;
    if (cur == NULL) {
	fprintf(output, "%s", shift);
	fprintf(output, "Node is NULL !\n");
	return;

    }

    while (cur != NULL) {
	tmp = cur;
	cur = cur->next;
	xmlDebugDumpOneNode(output, tmp, depth);
    }
}

static void
xmlXPathDebugDumpNodeSet(FILE *output, xmlNodeSetPtr cur, int depth) {
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;

    if (cur == NULL) {
	fprintf(output, "%s", shift);
	fprintf(output, "NodeSet is NULL !\n");
	return;

    }

    if (cur != NULL) {
	fprintf(output, "Set contains %d nodes:\n", cur->nodeNr);
	for (i = 0;i < cur->nodeNr;i++) {
	    fprintf(output, "%s", shift);
	    fprintf(output, "%d", i + 1);
	    xmlXPathDebugDumpNode(output, cur->nodeTab[i], depth + 1);
	}
    }
}

static void
xmlXPathDebugDumpValueTree(FILE *output, xmlNodeSetPtr cur, int depth) {
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;

    if ((cur == NULL) || (cur->nodeNr == 0) || (cur->nodeTab[0] == NULL)) {
	fprintf(output, "%s", shift);
	fprintf(output, "Value Tree is NULL !\n");
	return;

    }

    fprintf(output, "%s", shift);
    fprintf(output, "%d", i + 1);
    xmlXPathDebugDumpNodeList(output, cur->nodeTab[0]->children, depth + 1);
}
#if defined(LIBXML_XPTR_ENABLED)
static void
xmlXPathDebugDumpLocationSet(FILE *output, xmlLocationSetPtr cur, int depth) {
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;

    if (cur == NULL) {
	fprintf(output, "%s", shift);
	fprintf(output, "LocationSet is NULL !\n");
	return;

    }

    for (i = 0;i < cur->locNr;i++) {
	fprintf(output, "%s", shift);
        fprintf(output, "%d : ", i + 1);
	xmlXPathDebugDumpObject(output, cur->locTab[i], depth + 1);
    }
}
#endif /* LIBXML_XPTR_ENABLED */

/**
 * xmlXPathDebugDumpObject:
 * @output:  the FILE * to dump the output
 * @cur:  the object to inspect
 * @depth:  indentation level
 *
 * Dump the content of the object for debugging purposes
 */
void
xmlXPathDebugDumpObject(FILE *output, xmlXPathObjectPtr cur, int depth) {
    int i;
    char shift[100];

    if (output == NULL) return;

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;


    fprintf(output, "%s", shift);

    if (cur == NULL) {
        fprintf(output, "Object is empty (NULL)\n");
	return;
    }
    switch(cur->type) {
        case XPATH_UNDEFINED:
	    fprintf(output, "Object is uninitialized\n");
	    break;
        case XPATH_NODESET:
	    fprintf(output, "Object is a Node Set :\n");
	    xmlXPathDebugDumpNodeSet(output, cur->nodesetval, depth);
	    break;
	case XPATH_XSLT_TREE:
	    fprintf(output, "Object is an XSLT value tree :\n");
	    xmlXPathDebugDumpValueTree(output, cur->nodesetval, depth);
	    break;
        case XPATH_BOOLEAN:
	    fprintf(output, "Object is a Boolean : ");
	    if (cur->boolval) fprintf(output, "true\n");
	    else fprintf(output, "false\n");
	    break;
        case XPATH_NUMBER:
	    switch (xmlXPathIsInf(cur->floatval)) {
	    case 1:
		fprintf(output, "Object is a number : Infinity\n");
		break;
	    case -1:
		fprintf(output, "Object is a number : -Infinity\n");
		break;
	    default:
		if (xmlXPathIsNaN(cur->floatval)) {
		    fprintf(output, "Object is a number : NaN\n");
		} else if (cur->floatval == 0 && xmlXPathGetSign(cur->floatval) != 0) {
		    fprintf(output, "Object is a number : 0\n");
		} else {
		    fprintf(output, "Object is a number : %0g\n", cur->floatval);
		}
	    }
	    break;
        case XPATH_STRING:
	    fprintf(output, "Object is a string : ");
	    xmlDebugDumpString(output, cur->stringval);
	    fprintf(output, "\n");
	    break;
	case XPATH_POINT:
	    fprintf(output, "Object is a point : index %d in node", cur->index);
	    xmlXPathDebugDumpNode(output, (xmlNodePtr) cur->user, depth + 1);
	    fprintf(output, "\n");
	    break;
	case XPATH_RANGE:
	    if ((cur->user2 == NULL) ||
		((cur->user2 == cur->user) && (cur->index == cur->index2))) {
		fprintf(output, "Object is a collapsed range :\n");
		fprintf(output, "%s", shift);
		if (cur->index >= 0)
		    fprintf(output, "index %d in ", cur->index);
		fprintf(output, "node\n");
		xmlXPathDebugDumpNode(output, (xmlNodePtr) cur->user,
			              depth + 1);
	    } else  {
		fprintf(output, "Object is a range :\n");
		fprintf(output, "%s", shift);
		fprintf(output, "From ");
		if (cur->index >= 0)
		    fprintf(output, "index %d in ", cur->index);
		fprintf(output, "node\n");
		xmlXPathDebugDumpNode(output, (xmlNodePtr) cur->user,
			              depth + 1);
		fprintf(output, "%s", shift);
		fprintf(output, "To ");
		if (cur->index2 >= 0)
		    fprintf(output, "index %d in ", cur->index2);
		fprintf(output, "node\n");
		xmlXPathDebugDumpNode(output, (xmlNodePtr) cur->user2,
			              depth + 1);
		fprintf(output, "\n");
	    }
	    break;
	case XPATH_LOCATIONSET:
#if defined(LIBXML_XPTR_ENABLED)
	    fprintf(output, "Object is a Location Set:\n");
	    xmlXPathDebugDumpLocationSet(output,
		    (xmlLocationSetPtr) cur->user, depth);
#endif
	    break;
	case XPATH_USERS:
	    fprintf(output, "Object is user defined\n");
	    break;
    }
}

static void
xmlXPathDebugDumpStepOp(FILE *output, xmlXPathCompExprPtr comp,
	                     xmlXPathStepOpPtr op, int depth) {
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;

    fprintf(output, "%s", shift);
    if (op == NULL) {
	fprintf(output, "Step is NULL\n");
	return;
    }
    switch (op->op) {
        case XPATH_OP_END:
	    fprintf(output, "END"); break;
        case XPATH_OP_AND:
	    fprintf(output, "AND"); break;
        case XPATH_OP_OR:
	    fprintf(output, "OR"); break;
        case XPATH_OP_EQUAL:
	     if (op->value)
		 fprintf(output, "EQUAL =");
	     else
		 fprintf(output, "EQUAL !=");
	     break;
        case XPATH_OP_CMP:
	     if (op->value)
		 fprintf(output, "CMP <");
	     else
		 fprintf(output, "CMP >");
	     if (!op->value2)
		 fprintf(output, "=");
	     break;
        case XPATH_OP_PLUS:
	     if (op->value == 0)
		 fprintf(output, "PLUS -");
	     else if (op->value == 1)
		 fprintf(output, "PLUS +");
	     else if (op->value == 2)
		 fprintf(output, "PLUS unary -");
	     else if (op->value == 3)
		 fprintf(output, "PLUS unary - -");
	     break;
        case XPATH_OP_MULT:
	     if (op->value == 0)
		 fprintf(output, "MULT *");
	     else if (op->value == 1)
		 fprintf(output, "MULT div");
	     else
		 fprintf(output, "MULT mod");
	     break;
        case XPATH_OP_UNION:
	     fprintf(output, "UNION"); break;
        case XPATH_OP_ROOT:
	     fprintf(output, "ROOT"); break;
        case XPATH_OP_NODE:
	     fprintf(output, "NODE"); break;
        case XPATH_OP_RESET:
	     fprintf(output, "RESET"); break;
        case XPATH_OP_SORT:
	     fprintf(output, "SORT"); break;
        case XPATH_OP_COLLECT: {
	    xmlXPathAxisVal axis = (xmlXPathAxisVal)op->value;
	    xmlXPathTestVal test = (xmlXPathTestVal)op->value2;
	    xmlXPathTypeVal type = (xmlXPathTypeVal)op->value3;
	    const xmlChar *prefix = op->value4;
	    const xmlChar *name = op->value5;

	    fprintf(output, "COLLECT ");
	    switch (axis) {
		case AXIS_ANCESTOR:
		    fprintf(output, " 'ancestors' "); break;
		case AXIS_ANCESTOR_OR_SELF:
		    fprintf(output, " 'ancestors-or-self' "); break;
		case AXIS_ATTRIBUTE:
		    fprintf(output, " 'attributes' "); break;
		case AXIS_CHILD:
		    fprintf(output, " 'child' "); break;
		case AXIS_DESCENDANT:
		    fprintf(output, " 'descendant' "); break;
		case AXIS_DESCENDANT_OR_SELF:
		    fprintf(output, " 'descendant-or-self' "); break;
		case AXIS_FOLLOWING:
		    fprintf(output, " 'following' "); break;
		case AXIS_FOLLOWING_SIBLING:
		    fprintf(output, " 'following-siblings' "); break;
		case AXIS_NAMESPACE:
		    fprintf(output, " 'namespace' "); break;
		case AXIS_PARENT:
		    fprintf(output, " 'parent' "); break;
		case AXIS_PRECEDING:
		    fprintf(output, " 'preceding' "); break;
		case AXIS_PRECEDING_SIBLING:
		    fprintf(output, " 'preceding-sibling' "); break;
		case AXIS_SELF:
		    fprintf(output, " 'self' "); break;
	    }
	    switch (test) {
                case NODE_TEST_NONE:
		    fprintf(output, "'none' "); break;
                case NODE_TEST_TYPE:
		    fprintf(output, "'type' "); break;
                case NODE_TEST_PI:
		    fprintf(output, "'PI' "); break;
                case NODE_TEST_ALL:
		    fprintf(output, "'all' "); break;
                case NODE_TEST_NS:
		    fprintf(output, "'namespace' "); break;
                case NODE_TEST_NAME:
		    fprintf(output, "'name' "); break;
	    }
	    switch (type) {
                case NODE_TYPE_NODE:
		    fprintf(output, "'node' "); break;
                case NODE_TYPE_COMMENT:
		    fprintf(output, "'comment' "); break;
                case NODE_TYPE_TEXT:
		    fprintf(output, "'text' "); break;
                case NODE_TYPE_PI:
		    fprintf(output, "'PI' "); break;
	    }
	    if (prefix != NULL)
		fprintf(output, "%s:", prefix);
	    if (name != NULL)
		fprintf(output, "%s", (const char *) name);
	    break;

        }
	case XPATH_OP_VALUE: {
	    xmlXPathObjectPtr object = (xmlXPathObjectPtr) op->value4;

	    fprintf(output, "ELEM ");
	    xmlXPathDebugDumpObject(output, object, 0);
	    goto finish;
	}
	case XPATH_OP_VARIABLE: {
	    const xmlChar *prefix = op->value5;
	    const xmlChar *name = op->value4;

	    if (prefix != NULL)
		fprintf(output, "VARIABLE %s:%s", prefix, name);
	    else
		fprintf(output, "VARIABLE %s", name);
	    break;
	}
	case XPATH_OP_FUNCTION: {
	    int nbargs = op->value;
	    const xmlChar *prefix = op->value5;
	    const xmlChar *name = op->value4;

	    if (prefix != NULL)
		fprintf(output, "FUNCTION %s:%s(%d args)",
			prefix, name, nbargs);
	    else
		fprintf(output, "FUNCTION %s(%d args)", name, nbargs);
	    break;
	}
        case XPATH_OP_ARG: fprintf(output, "ARG"); break;
        case XPATH_OP_PREDICATE: fprintf(output, "PREDICATE"); break;
        case XPATH_OP_FILTER: fprintf(output, "FILTER"); break;
#ifdef LIBXML_XPTR_ENABLED
        case XPATH_OP_RANGETO: fprintf(output, "RANGETO"); break;
#endif
	default:
        fprintf(output, "UNKNOWN %d\n", op->op); return;
    }
    fprintf(output, "\n");
finish:
    if (op->ch1 >= 0)
	xmlXPathDebugDumpStepOp(output, comp, &comp->steps[op->ch1], depth + 1);
    if (op->ch2 >= 0)
	xmlXPathDebugDumpStepOp(output, comp, &comp->steps[op->ch2], depth + 1);
}

/**
 * xmlXPathDebugDumpCompExpr:
 * @output:  the FILE * for the output
 * @comp:  the precompiled XPath expression
 * @depth:  the indentation level.
 *
 * Dumps the tree of the compiled XPath expression.
 */
void
xmlXPathDebugDumpCompExpr(FILE *output, xmlXPathCompExprPtr comp,
	                  int depth) {
    int i;
    char shift[100];

    if ((output == NULL) || (comp == NULL)) return;

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;

    fprintf(output, "%s", shift);

    fprintf(output, "Compiled Expression : %d elements\n",
	    comp->nbStep);
    i = comp->last;
    xmlXPathDebugDumpStepOp(output, comp, &comp->steps[i], depth + 1);
}

#ifdef XP_DEBUG_OBJ_USAGE

/*
* XPath object usage related debugging variables.
*/
static int xmlXPathDebugObjCounterUndefined = 0;
static int xmlXPathDebugObjCounterNodeset = 0;
static int xmlXPathDebugObjCounterBool = 0;
static int xmlXPathDebugObjCounterNumber = 0;
static int xmlXPathDebugObjCounterString = 0;
static int xmlXPathDebugObjCounterPoint = 0;
static int xmlXPathDebugObjCounterRange = 0;
static int xmlXPathDebugObjCounterLocset = 0;
static int xmlXPathDebugObjCounterUsers = 0;
static int xmlXPathDebugObjCounterXSLTTree = 0;
static int xmlXPathDebugObjCounterAll = 0;

static int xmlXPathDebugObjTotalUndefined = 0;
static int xmlXPathDebugObjTotalNodeset = 0;
static int xmlXPathDebugObjTotalBool = 0;
static int xmlXPathDebugObjTotalNumber = 0;
static int xmlXPathDebugObjTotalString = 0;
static int xmlXPathDebugObjTotalPoint = 0;
static int xmlXPathDebugObjTotalRange = 0;
static int xmlXPathDebugObjTotalLocset = 0;
static int xmlXPathDebugObjTotalUsers = 0;
static int xmlXPathDebugObjTotalXSLTTree = 0;
static int xmlXPathDebugObjTotalAll = 0;

static int xmlXPathDebugObjMaxUndefined = 0;
static int xmlXPathDebugObjMaxNodeset = 0;
static int xmlXPathDebugObjMaxBool = 0;
static int xmlXPathDebugObjMaxNumber = 0;
static int xmlXPathDebugObjMaxString = 0;
static int xmlXPathDebugObjMaxPoint = 0;
static int xmlXPathDebugObjMaxRange = 0;
static int xmlXPathDebugObjMaxLocset = 0;
static int xmlXPathDebugObjMaxUsers = 0;
static int xmlXPathDebugObjMaxXSLTTree = 0;
static int xmlXPathDebugObjMaxAll = 0;

/* REVISIT TODO: Make this static when committing */
static void
xmlXPathDebugObjUsageReset(xmlXPathContextPtr ctxt)
{
    if (ctxt != NULL) {
	if (ctxt->cache != NULL) {
	    xmlXPathContextCachePtr cache =
		(xmlXPathContextCachePtr) ctxt->cache;

	    cache->dbgCachedAll = 0;
	    cache->dbgCachedNodeset = 0;
	    cache->dbgCachedString = 0;
	    cache->dbgCachedBool = 0;
	    cache->dbgCachedNumber = 0;
	    cache->dbgCachedPoint = 0;
	    cache->dbgCachedRange = 0;
	    cache->dbgCachedLocset = 0;
	    cache->dbgCachedUsers = 0;
	    cache->dbgCachedXSLTTree = 0;
	    cache->dbgCachedUndefined = 0;

	    cache->dbgReusedAll = 0;
	    cache->dbgReusedNodeset = 0;
	    cache->dbgReusedString = 0;
	    cache->dbgReusedBool = 0;
	    cache->dbgReusedNumber = 0;
	    cache->dbgReusedPoint = 0;
	    cache->dbgReusedRange = 0;
	    cache->dbgReusedLocset = 0;
	    cache->dbgReusedUsers = 0;
	    cache->dbgReusedXSLTTree = 0;
	    cache->dbgReusedUndefined = 0;
	}
    }

    xmlXPathDebugObjCounterUndefined = 0;
    xmlXPathDebugObjCounterNodeset = 0;
    xmlXPathDebugObjCounterBool = 0;
    xmlXPathDebugObjCounterNumber = 0;
    xmlXPathDebugObjCounterString = 0;
    xmlXPathDebugObjCounterPoint = 0;
    xmlXPathDebugObjCounterRange = 0;
    xmlXPathDebugObjCounterLocset = 0;
    xmlXPathDebugObjCounterUsers = 0;
    xmlXPathDebugObjCounterXSLTTree = 0;
    xmlXPathDebugObjCounterAll = 0;

    xmlXPathDebugObjTotalUndefined = 0;
    xmlXPathDebugObjTotalNodeset = 0;
    xmlXPathDebugObjTotalBool = 0;
    xmlXPathDebugObjTotalNumber = 0;
    xmlXPathDebugObjTotalString = 0;
    xmlXPathDebugObjTotalPoint = 0;
    xmlXPathDebugObjTotalRange = 0;
    xmlXPathDebugObjTotalLocset = 0;
    xmlXPathDebugObjTotalUsers = 0;
    xmlXPathDebugObjTotalXSLTTree = 0;
    xmlXPathDebugObjTotalAll = 0;

    xmlXPathDebugObjMaxUndefined = 0;
    xmlXPathDebugObjMaxNodeset = 0;
    xmlXPathDebugObjMaxBool = 0;
    xmlXPathDebugObjMaxNumber = 0;
    xmlXPathDebugObjMaxString = 0;
    xmlXPathDebugObjMaxPoint = 0;
    xmlXPathDebugObjMaxRange = 0;
    xmlXPathDebugObjMaxLocset = 0;
    xmlXPathDebugObjMaxUsers = 0;
    xmlXPathDebugObjMaxXSLTTree = 0;
    xmlXPathDebugObjMaxAll = 0;

}

static void
xmlXPathDebugObjUsageRequested(xmlXPathContextPtr ctxt,
			      xmlXPathObjectType objType)
{
    int isCached = 0;

    if (ctxt != NULL) {
	if (ctxt->cache != NULL) {
	    xmlXPathContextCachePtr cache =
		(xmlXPathContextCachePtr) ctxt->cache;

	    isCached = 1;

	    cache->dbgReusedAll++;
	    switch (objType) {
		case XPATH_UNDEFINED:
		    cache->dbgReusedUndefined++;
		    break;
		case XPATH_NODESET:
		    cache->dbgReusedNodeset++;
		    break;
		case XPATH_BOOLEAN:
		    cache->dbgReusedBool++;
		    break;
		case XPATH_NUMBER:
		    cache->dbgReusedNumber++;
		    break;
		case XPATH_STRING:
		    cache->dbgReusedString++;
		    break;
		case XPATH_POINT:
		    cache->dbgReusedPoint++;
		    break;
		case XPATH_RANGE:
		    cache->dbgReusedRange++;
		    break;
		case XPATH_LOCATIONSET:
		    cache->dbgReusedLocset++;
		    break;
		case XPATH_USERS:
		    cache->dbgReusedUsers++;
		    break;
		case XPATH_XSLT_TREE:
		    cache->dbgReusedXSLTTree++;
		    break;
		default:
		    break;
	    }
	}
    }

    switch (objType) {
	case XPATH_UNDEFINED:
	    if (! isCached)
		xmlXPathDebugObjTotalUndefined++;
	    xmlXPathDebugObjCounterUndefined++;
	    if (xmlXPathDebugObjCounterUndefined >
		xmlXPathDebugObjMaxUndefined)
		xmlXPathDebugObjMaxUndefined =
		    xmlXPathDebugObjCounterUndefined;
	    break;
	case XPATH_NODESET:
	    if (! isCached)
		xmlXPathDebugObjTotalNodeset++;
	    xmlXPathDebugObjCounterNodeset++;
	    if (xmlXPathDebugObjCounterNodeset >
		xmlXPathDebugObjMaxNodeset)
		xmlXPathDebugObjMaxNodeset =
		    xmlXPathDebugObjCounterNodeset;
	    break;
	case XPATH_BOOLEAN:
	    if (! isCached)
		xmlXPathDebugObjTotalBool++;
	    xmlXPathDebugObjCounterBool++;
	    if (xmlXPathDebugObjCounterBool >
		xmlXPathDebugObjMaxBool)
		xmlXPathDebugObjMaxBool =
		    xmlXPathDebugObjCounterBool;
	    break;
	case XPATH_NUMBER:
	    if (! isCached)
		xmlXPathDebugObjTotalNumber++;
	    xmlXPathDebugObjCounterNumber++;
	    if (xmlXPathDebugObjCounterNumber >
		xmlXPathDebugObjMaxNumber)
		xmlXPathDebugObjMaxNumber =
		    xmlXPathDebugObjCounterNumber;
	    break;
	case XPATH_STRING:
	    if (! isCached)
		xmlXPathDebugObjTotalString++;
	    xmlXPathDebugObjCounterString++;
	    if (xmlXPathDebugObjCounterString >
		xmlXPathDebugObjMaxString)
		xmlXPathDebugObjMaxString =
		    xmlXPathDebugObjCounterString;
	    break;
	case XPATH_POINT:
	    if (! isCached)
		xmlXPathDebugObjTotalPoint++;
	    xmlXPathDebugObjCounterPoint++;
	    if (xmlXPathDebugObjCounterPoint >
		xmlXPathDebugObjMaxPoint)
		xmlXPathDebugObjMaxPoint =
		    xmlXPathDebugObjCounterPoint;
	    break;
	case XPATH_RANGE:
	    if (! isCached)
		xmlXPathDebugObjTotalRange++;
	    xmlXPathDebugObjCounterRange++;
	    if (xmlXPathDebugObjCounterRange >
		xmlXPathDebugObjMaxRange)
		xmlXPathDebugObjMaxRange =
		    xmlXPathDebugObjCounterRange;
	    break;
	case XPATH_LOCATIONSET:
	    if (! isCached)
		xmlXPathDebugObjTotalLocset++;
	    xmlXPathDebugObjCounterLocset++;
	    if (xmlXPathDebugObjCounterLocset >
		xmlXPathDebugObjMaxLocset)
		xmlXPathDebugObjMaxLocset =
		    xmlXPathDebugObjCounterLocset;
	    break;
	case XPATH_USERS:
	    if (! isCached)
		xmlXPathDebugObjTotalUsers++;
	    xmlXPathDebugObjCounterUsers++;
	    if (xmlXPathDebugObjCounterUsers >
		xmlXPathDebugObjMaxUsers)
		xmlXPathDebugObjMaxUsers =
		    xmlXPathDebugObjCounterUsers;
	    break;
	case XPATH_XSLT_TREE:
	    if (! isCached)
		xmlXPathDebugObjTotalXSLTTree++;
	    xmlXPathDebugObjCounterXSLTTree++;
	    if (xmlXPathDebugObjCounterXSLTTree >
		xmlXPathDebugObjMaxXSLTTree)
		xmlXPathDebugObjMaxXSLTTree =
		    xmlXPathDebugObjCounterXSLTTree;
	    break;
	default:
	    break;
    }
    if (! isCached)
	xmlXPathDebugObjTotalAll++;
    xmlXPathDebugObjCounterAll++;
    if (xmlXPathDebugObjCounterAll >
	xmlXPathDebugObjMaxAll)
	xmlXPathDebugObjMaxAll =
	    xmlXPathDebugObjCounterAll;
}

static void
xmlXPathDebugObjUsageReleased(xmlXPathContextPtr ctxt,
			      xmlXPathObjectType objType)
{
    int isCached = 0;

    if (ctxt != NULL) {
	if (ctxt->cache != NULL) {
	    xmlXPathContextCachePtr cache =
		(xmlXPathContextCachePtr) ctxt->cache;

	    isCached = 1;

	    cache->dbgCachedAll++;
	    switch (objType) {
		case XPATH_UNDEFINED:
		    cache->dbgCachedUndefined++;
		    break;
		case XPATH_NODESET:
		    cache->dbgCachedNodeset++;
		    break;
		case XPATH_BOOLEAN:
		    cache->dbgCachedBool++;
		    break;
		case XPATH_NUMBER:
		    cache->dbgCachedNumber++;
		    break;
		case XPATH_STRING:
		    cache->dbgCachedString++;
		    break;
		case XPATH_POINT:
		    cache->dbgCachedPoint++;
		    break;
		case XPATH_RANGE:
		    cache->dbgCachedRange++;
		    break;
		case XPATH_LOCATIONSET:
		    cache->dbgCachedLocset++;
		    break;
		case XPATH_USERS:
		    cache->dbgCachedUsers++;
		    break;
		case XPATH_XSLT_TREE:
		    cache->dbgCachedXSLTTree++;
		    break;
		default:
		    break;
	    }

	}
    }
    switch (objType) {
	case XPATH_UNDEFINED:
	    xmlXPathDebugObjCounterUndefined--;
	    break;
	case XPATH_NODESET:
	    xmlXPathDebugObjCounterNodeset--;
	    break;
	case XPATH_BOOLEAN:
	    xmlXPathDebugObjCounterBool--;
	    break;
	case XPATH_NUMBER:
	    xmlXPathDebugObjCounterNumber--;
	    break;
	case XPATH_STRING:
	    xmlXPathDebugObjCounterString--;
	    break;
	case XPATH_POINT:
	    xmlXPathDebugObjCounterPoint--;
	    break;
	case XPATH_RANGE:
	    xmlXPathDebugObjCounterRange--;
	    break;
	case XPATH_LOCATIONSET:
	    xmlXPathDebugObjCounterLocset--;
	    break;
	case XPATH_USERS:
	    xmlXPathDebugObjCounterUsers--;
	    break;
	case XPATH_XSLT_TREE:
	    xmlXPathDebugObjCounterXSLTTree--;
	    break;
	default:
	    break;
    }
    xmlXPathDebugObjCounterAll--;
}

/* REVISIT TODO: Make this static when committing */
static void
xmlXPathDebugObjUsageDisplay(xmlXPathContextPtr ctxt)
{
    int reqAll, reqNodeset, reqString, reqBool, reqNumber,
	reqXSLTTree, reqUndefined;
    int caAll = 0, caNodeset = 0, caString = 0, caBool = 0,
	caNumber = 0, caXSLTTree = 0, caUndefined = 0;
    int reAll = 0, reNodeset = 0, reString = 0, reBool = 0,
	reNumber = 0, reXSLTTree = 0, reUndefined = 0;
    int leftObjs = xmlXPathDebugObjCounterAll;

    reqAll = xmlXPathDebugObjTotalAll;
    reqNodeset = xmlXPathDebugObjTotalNodeset;
    reqString = xmlXPathDebugObjTotalString;
    reqBool = xmlXPathDebugObjTotalBool;
    reqNumber = xmlXPathDebugObjTotalNumber;
    reqXSLTTree = xmlXPathDebugObjTotalXSLTTree;
    reqUndefined = xmlXPathDebugObjTotalUndefined;

    printf("# XPath object usage:\n");

    if (ctxt != NULL) {
	if (ctxt->cache != NULL) {
	    xmlXPathContextCachePtr cache =
		(xmlXPathContextCachePtr) ctxt->cache;

	    reAll = cache->dbgReusedAll;
	    reqAll += reAll;
	    reNodeset = cache->dbgReusedNodeset;
	    reqNodeset += reNodeset;
	    reString = cache->dbgReusedString;
	    reqString += reString;
	    reBool = cache->dbgReusedBool;
	    reqBool += reBool;
	    reNumber = cache->dbgReusedNumber;
	    reqNumber += reNumber;
	    reXSLTTree = cache->dbgReusedXSLTTree;
	    reqXSLTTree += reXSLTTree;
	    reUndefined = cache->dbgReusedUndefined;
	    reqUndefined += reUndefined;

	    caAll = cache->dbgCachedAll;
	    caBool = cache->dbgCachedBool;
	    caNodeset = cache->dbgCachedNodeset;
	    caString = cache->dbgCachedString;
	    caNumber = cache->dbgCachedNumber;
	    caXSLTTree = cache->dbgCachedXSLTTree;
	    caUndefined = cache->dbgCachedUndefined;

	    if (cache->nodesetObjs)
		leftObjs -= cache->nodesetObjs->number;
	    if (cache->stringObjs)
		leftObjs -= cache->stringObjs->number;
	    if (cache->booleanObjs)
		leftObjs -= cache->booleanObjs->number;
	    if (cache->numberObjs)
		leftObjs -= cache->numberObjs->number;
	    if (cache->miscObjs)
		leftObjs -= cache->miscObjs->number;
	}
    }

    printf("# all\n");
    printf("#   total  : %d\n", reqAll);
    printf("#   left  : %d\n", leftObjs);
    printf("#   created: %d\n", xmlXPathDebugObjTotalAll);
    printf("#   reused : %d\n", reAll);
    printf("#   max    : %d\n", xmlXPathDebugObjMaxAll);

    printf("# node-sets\n");
    printf("#   total  : %d\n", reqNodeset);
    printf("#   created: %d\n", xmlXPathDebugObjTotalNodeset);
    printf("#   reused : %d\n", reNodeset);
    printf("#   max    : %d\n", xmlXPathDebugObjMaxNodeset);

    printf("# strings\n");
    printf("#   total  : %d\n", reqString);
    printf("#   created: %d\n", xmlXPathDebugObjTotalString);
    printf("#   reused : %d\n", reString);
    printf("#   max    : %d\n", xmlXPathDebugObjMaxString);

    printf("# booleans\n");
    printf("#   total  : %d\n", reqBool);
    printf("#   created: %d\n", xmlXPathDebugObjTotalBool);
    printf("#   reused : %d\n", reBool);
    printf("#   max    : %d\n", xmlXPathDebugObjMaxBool);

    printf("# numbers\n");
    printf("#   total  : %d\n", reqNumber);
    printf("#   created: %d\n", xmlXPathDebugObjTotalNumber);
    printf("#   reused : %d\n", reNumber);
    printf("#   max    : %d\n", xmlXPathDebugObjMaxNumber);

    printf("# XSLT result tree fragments\n");
    printf("#   total  : %d\n", reqXSLTTree);
    printf("#   created: %d\n", xmlXPathDebugObjTotalXSLTTree);
    printf("#   reused : %d\n", reXSLTTree);
    printf("#   max    : %d\n", xmlXPathDebugObjMaxXSLTTree);

    printf("# undefined\n");
    printf("#   total  : %d\n", reqUndefined);
    printf("#   created: %d\n", xmlXPathDebugObjTotalUndefined);
    printf("#   reused : %d\n", reUndefined);
    printf("#   max    : %d\n", xmlXPathDebugObjMaxUndefined);

}

#endif /* XP_DEBUG_OBJ_USAGE */

#endif /* LIBXML_DEBUG_ENABLED */

/************************************************************************
 *									*
 *			XPath object caching				*
 *									*
 ************************************************************************/

/**
 * xmlXPathNewCache:
 *
 * Create a new object cache
 *
 * Returns the xmlXPathCache just allocated.
 */
static xmlXPathContextCachePtr
xmlXPathNewCache(void)
{
    xmlXPathContextCachePtr ret;

    ret = (xmlXPathContextCachePtr) xmlMalloc(sizeof(xmlXPathContextCache));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating object cache\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathContextCache));
    ret->maxNodeset = 100;
    ret->maxString = 100;
    ret->maxBoolean = 100;
    ret->maxNumber = 100;
    ret->maxMisc = 100;
    return(ret);
}

static void
xmlXPathCacheFreeObjectList(xmlPointerListPtr list)
{
    int i;
    xmlXPathObjectPtr obj;

    if (list == NULL)
	return;

    for (i = 0; i < list->number; i++) {
	obj = list->items[i];
	/*
	* Note that it is already assured that we don't need to
	* look out for namespace nodes in the node-set.
	*/
	if (obj->nodesetval != NULL) {
	    if (obj->nodesetval->nodeTab != NULL)
		xmlFree(obj->nodesetval->nodeTab);
	    xmlFree(obj->nodesetval);
	}
	xmlFree(obj);
#ifdef XP_DEBUG_OBJ_USAGE
	xmlXPathDebugObjCounterAll--;
#endif
    }
    xmlPointerListFree(list);
}

static void
xmlXPathFreeCache(xmlXPathContextCachePtr cache)
{
    if (cache == NULL)
	return;
    if (cache->nodesetObjs)
	xmlXPathCacheFreeObjectList(cache->nodesetObjs);
    if (cache->stringObjs)
	xmlXPathCacheFreeObjectList(cache->stringObjs);
    if (cache->booleanObjs)
	xmlXPathCacheFreeObjectList(cache->booleanObjs);
    if (cache->numberObjs)
	xmlXPathCacheFreeObjectList(cache->numberObjs);
    if (cache->miscObjs)
	xmlXPathCacheFreeObjectList(cache->miscObjs);
    xmlFree(cache);
}

/**
 * xmlXPathContextSetCache:
 *
 * @ctxt:  the XPath context
 * @active: enables/disables (creates/frees) the cache
 * @value: a value with semantics dependant on @options
 * @options: options (currently only the value 0 is used)
 *
 * Creates/frees an object cache on the XPath context.
 * If activates XPath objects (xmlXPathObject) will be cached internally
 * to be reused.
 * @options:
 *   0: This will set the XPath object caching:
 *      @value:
 *        This will set the maximum number of XPath objects
 *        to be cached per slot
 *        There are 5 slots for: node-set, string, number, boolean, and
 *        misc objects. Use <0 for the default number (100).
 *   Other values for @options have currently no effect.
 *
 * Returns 0 if the setting succeeded, and -1 on API or internal errors.
 */
int
xmlXPathContextSetCache(xmlXPathContextPtr ctxt,
			int active,
			int value,
			int options)
{
    if (ctxt == NULL)
	return(-1);
    if (active) {
	xmlXPathContextCachePtr cache;

	if (ctxt->cache == NULL) {
	    ctxt->cache = xmlXPathNewCache();
	    if (ctxt->cache == NULL)
		return(-1);
	}
	cache = (xmlXPathContextCachePtr) ctxt->cache;
	if (options == 0) {
	    if (value < 0)
		value = 100;
	    cache->maxNodeset = value;
	    cache->maxString = value;
	    cache->maxNumber = value;
	    cache->maxBoolean = value;
	    cache->maxMisc = value;
	}
    } else if (ctxt->cache != NULL) {
	xmlXPathFreeCache((xmlXPathContextCachePtr) ctxt->cache);
	ctxt->cache = NULL;
    }
    return(0);
}

/**
 * xmlXPathCacheWrapNodeSet:
 * @ctxt: the XPath context
 * @val:  the NodePtr value
 *
 * This is the cached version of xmlXPathWrapNodeSet().
 * Wrap the Nodeset @val in a new xmlXPathObjectPtr
 *
 * Returns the created or reused object.
 */
static xmlXPathObjectPtr
xmlXPathCacheWrapNodeSet(xmlXPathContextPtr ctxt, xmlNodeSetPtr val)
{
    if ((ctxt != NULL) && (ctxt->cache != NULL)) {
	xmlXPathContextCachePtr cache =
	    (xmlXPathContextCachePtr) ctxt->cache;

	if ((cache->miscObjs != NULL) &&
	    (cache->miscObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;

	    ret = (xmlXPathObjectPtr)
		cache->miscObjs->items[--cache->miscObjs->number];
	    ret->type = XPATH_NODESET;
	    ret->nodesetval = val;
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_NODESET);
#endif
	    return(ret);
	}
    }

    return(xmlXPathWrapNodeSet(val));

}

/**
 * xmlXPathCacheWrapString:
 * @ctxt: the XPath context
 * @val:  the xmlChar * value
 *
 * This is the cached version of xmlXPathWrapString().
 * Wraps the @val string into an XPath object.
 *
 * Returns the created or reused object.
 */
static xmlXPathObjectPtr
xmlXPathCacheWrapString(xmlXPathContextPtr ctxt, xmlChar *val)
{
    if ((ctxt != NULL) && (ctxt->cache != NULL)) {
	xmlXPathContextCachePtr cache = (xmlXPathContextCachePtr) ctxt->cache;

	if ((cache->stringObjs != NULL) &&
	    (cache->stringObjs->number != 0))
	{

	    xmlXPathObjectPtr ret;

	    ret = (xmlXPathObjectPtr)
		cache->stringObjs->items[--cache->stringObjs->number];
	    ret->type = XPATH_STRING;
	    ret->stringval = val;
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_STRING);
#endif
	    return(ret);
	} else if ((cache->miscObjs != NULL) &&
	    (cache->miscObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;
	    /*
	    * Fallback to misc-cache.
	    */
	    ret = (xmlXPathObjectPtr)
		cache->miscObjs->items[--cache->miscObjs->number];

	    ret->type = XPATH_STRING;
	    ret->stringval = val;
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_STRING);
#endif
	    return(ret);
	}
    }
    return(xmlXPathWrapString(val));
}

/**
 * xmlXPathCacheNewNodeSet:
 * @ctxt: the XPath context
 * @val:  the NodePtr value
 *
 * This is the cached version of xmlXPathNewNodeSet().
 * Acquire an xmlXPathObjectPtr of type NodeSet and initialize
 * it with the single Node @val
 *
 * Returns the created or reused object.
 */
static xmlXPathObjectPtr
xmlXPathCacheNewNodeSet(xmlXPathContextPtr ctxt, xmlNodePtr val)
{
    if ((ctxt != NULL) && (ctxt->cache)) {
	xmlXPathContextCachePtr cache = (xmlXPathContextCachePtr) ctxt->cache;

	if ((cache->nodesetObjs != NULL) &&
	    (cache->nodesetObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;
	    /*
	    * Use the nodset-cache.
	    */
	    ret = (xmlXPathObjectPtr)
		cache->nodesetObjs->items[--cache->nodesetObjs->number];
	    ret->type = XPATH_NODESET;
	    ret->boolval = 0;
	    if (val) {
		if ((ret->nodesetval->nodeMax == 0) ||
		    (val->type == XML_NAMESPACE_DECL))
		{
		    xmlXPathNodeSetAddUnique(ret->nodesetval, val);
		} else {
		    ret->nodesetval->nodeTab[0] = val;
		    ret->nodesetval->nodeNr = 1;
		}
	    }
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_NODESET);
#endif
	    return(ret);
	} else if ((cache->miscObjs != NULL) &&
	    (cache->miscObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;
	    /*
	    * Fallback to misc-cache.
	    */

	    ret = (xmlXPathObjectPtr)
		cache->miscObjs->items[--cache->miscObjs->number];

	    ret->type = XPATH_NODESET;
	    ret->boolval = 0;
	    ret->nodesetval = xmlXPathNodeSetCreate(val);
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_NODESET);
#endif
	    return(ret);
	}
    }
    return(xmlXPathNewNodeSet(val));
}

/**
 * xmlXPathCacheNewCString:
 * @ctxt: the XPath context
 * @val:  the char * value
 *
 * This is the cached version of xmlXPathNewCString().
 * Acquire an xmlXPathObjectPtr of type string and of value @val
 *
 * Returns the created or reused object.
 */
static xmlXPathObjectPtr
xmlXPathCacheNewCString(xmlXPathContextPtr ctxt, const char *val)
{
    if ((ctxt != NULL) && (ctxt->cache)) {
	xmlXPathContextCachePtr cache = (xmlXPathContextCachePtr) ctxt->cache;

	if ((cache->stringObjs != NULL) &&
	    (cache->stringObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;

	    ret = (xmlXPathObjectPtr)
		cache->stringObjs->items[--cache->stringObjs->number];

	    ret->type = XPATH_STRING;
	    ret->stringval = xmlStrdup(BAD_CAST val);
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_STRING);
#endif
	    return(ret);
	} else if ((cache->miscObjs != NULL) &&
	    (cache->miscObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;

	    ret = (xmlXPathObjectPtr)
		cache->miscObjs->items[--cache->miscObjs->number];

	    ret->type = XPATH_STRING;
	    ret->stringval = xmlStrdup(BAD_CAST val);
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_STRING);
#endif
	    return(ret);
	}
    }
    return(xmlXPathNewCString(val));
}

/**
 * xmlXPathCacheNewString:
 * @ctxt: the XPath context
 * @val:  the xmlChar * value
 *
 * This is the cached version of xmlXPathNewString().
 * Acquire an xmlXPathObjectPtr of type string and of value @val
 *
 * Returns the created or reused object.
 */
static xmlXPathObjectPtr
xmlXPathCacheNewString(xmlXPathContextPtr ctxt, const xmlChar *val)
{
    if ((ctxt != NULL) && (ctxt->cache)) {
	xmlXPathContextCachePtr cache = (xmlXPathContextCachePtr) ctxt->cache;

	if ((cache->stringObjs != NULL) &&
	    (cache->stringObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;

	    ret = (xmlXPathObjectPtr)
		cache->stringObjs->items[--cache->stringObjs->number];
	    ret->type = XPATH_STRING;
	    if (val != NULL)
		ret->stringval = xmlStrdup(val);
	    else
		ret->stringval = xmlStrdup((const xmlChar *)"");
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_STRING);
#endif
	    return(ret);
	} else if ((cache->miscObjs != NULL) &&
	    (cache->miscObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;

	    ret = (xmlXPathObjectPtr)
		cache->miscObjs->items[--cache->miscObjs->number];

	    ret->type = XPATH_STRING;
	    if (val != NULL)
		ret->stringval = xmlStrdup(val);
	    else
		ret->stringval = xmlStrdup((const xmlChar *)"");
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_STRING);
#endif
	    return(ret);
	}
    }
    return(xmlXPathNewString(val));
}

/**
 * xmlXPathCacheNewBoolean:
 * @ctxt: the XPath context
 * @val:  the boolean value
 *
 * This is the cached version of xmlXPathNewBoolean().
 * Acquires an xmlXPathObjectPtr of type boolean and of value @val
 *
 * Returns the created or reused object.
 */
static xmlXPathObjectPtr
xmlXPathCacheNewBoolean(xmlXPathContextPtr ctxt, int val)
{
    if ((ctxt != NULL) && (ctxt->cache)) {
	xmlXPathContextCachePtr cache = (xmlXPathContextCachePtr) ctxt->cache;

	if ((cache->booleanObjs != NULL) &&
	    (cache->booleanObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;

	    ret = (xmlXPathObjectPtr)
		cache->booleanObjs->items[--cache->booleanObjs->number];
	    ret->type = XPATH_BOOLEAN;
	    ret->boolval = (val != 0);
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_BOOLEAN);
#endif
	    return(ret);
	} else if ((cache->miscObjs != NULL) &&
	    (cache->miscObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;

	    ret = (xmlXPathObjectPtr)
		cache->miscObjs->items[--cache->miscObjs->number];

	    ret->type = XPATH_BOOLEAN;
	    ret->boolval = (val != 0);
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_BOOLEAN);
#endif
	    return(ret);
	}
    }
    return(xmlXPathNewBoolean(val));
}

/**
 * xmlXPathCacheNewFloat:
 * @ctxt: the XPath context
 * @val:  the double value
 *
 * This is the cached version of xmlXPathNewFloat().
 * Acquires an xmlXPathObjectPtr of type double and of value @val
 *
 * Returns the created or reused object.
 */
static xmlXPathObjectPtr
xmlXPathCacheNewFloat(xmlXPathContextPtr ctxt, double val)
{
     if ((ctxt != NULL) && (ctxt->cache)) {
	xmlXPathContextCachePtr cache = (xmlXPathContextCachePtr) ctxt->cache;

	if ((cache->numberObjs != NULL) &&
	    (cache->numberObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;

	    ret = (xmlXPathObjectPtr)
		cache->numberObjs->items[--cache->numberObjs->number];
	    ret->type = XPATH_NUMBER;
	    ret->floatval = val;
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_NUMBER);
#endif
	    return(ret);
	} else if ((cache->miscObjs != NULL) &&
	    (cache->miscObjs->number != 0))
	{
	    xmlXPathObjectPtr ret;

	    ret = (xmlXPathObjectPtr)
		cache->miscObjs->items[--cache->miscObjs->number];

	    ret->type = XPATH_NUMBER;
	    ret->floatval = val;
#ifdef XP_DEBUG_OBJ_USAGE
	    xmlXPathDebugObjUsageRequested(ctxt, XPATH_NUMBER);
#endif
	    return(ret);
	}
    }
    return(xmlXPathNewFloat(val));
}

/**
 * xmlXPathCacheConvertString:
 * @ctxt: the XPath context
 * @val:  an XPath object
 *
 * This is the cached version of xmlXPathConvertString().
 * Converts an existing object to its string() equivalent
 *
 * Returns a created or reused object, the old one is freed (cached)
 *         (or the operation is done directly on @val)
 */

static xmlXPathObjectPtr
xmlXPathCacheConvertString(xmlXPathContextPtr ctxt, xmlXPathObjectPtr val) {
    xmlChar *res = NULL;

    if (val == NULL)
	return(xmlXPathCacheNewCString(ctxt, ""));

    switch (val->type) {
    case XPATH_UNDEFINED:
#ifdef DEBUG_EXPR
	xmlGenericError(xmlGenericErrorContext, "STRING: undefined\n");
#endif
	break;
    case XPATH_NODESET:
    case XPATH_XSLT_TREE:
	res = xmlXPathCastNodeSetToString(val->nodesetval);
	break;
    case XPATH_STRING:
	return(val);
    case XPATH_BOOLEAN:
	res = xmlXPathCastBooleanToString(val->boolval);
	break;
    case XPATH_NUMBER:
	res = xmlXPathCastNumberToString(val->floatval);
	break;
    case XPATH_USERS:
    case XPATH_POINT:
    case XPATH_RANGE:
    case XPATH_LOCATIONSET:
	TODO;
	break;
    }
    xmlXPathReleaseObject(ctxt, val);
    if (res == NULL)
	return(xmlXPathCacheNewCString(ctxt, ""));
    return(xmlXPathCacheWrapString(ctxt, res));
}

/**
 * xmlXPathCacheObjectCopy:
 * @ctxt: the XPath context
 * @val:  the original object
 *
 * This is the cached version of xmlXPathObjectCopy().
 * Acquire a copy of a given object
 *
 * Returns a created or reused created object.
 */
static xmlXPathObjectPtr
xmlXPathCacheObjectCopy(xmlXPathContextPtr ctxt, xmlXPathObjectPtr val)
{
    if (val == NULL)
	return(NULL);

    if (XP_HAS_CACHE(ctxt)) {
	switch (val->type) {
	    case XPATH_NODESET:
		return(xmlXPathCacheWrapNodeSet(ctxt,
		    xmlXPathNodeSetMerge(NULL, val->nodesetval)));
	    case XPATH_STRING:
		return(xmlXPathCacheNewString(ctxt, val->stringval));
	    case XPATH_BOOLEAN:
		return(xmlXPathCacheNewBoolean(ctxt, val->boolval));
	    case XPATH_NUMBER:
		return(xmlXPathCacheNewFloat(ctxt, val->floatval));
	    default:
		break;
	}
    }
    return(xmlXPathObjectCopy(val));
}

/**
 * xmlXPathCacheConvertBoolean:
 * @ctxt: the XPath context
 * @val:  an XPath object
 *
 * This is the cached version of xmlXPathConvertBoolean().
 * Converts an existing object to its boolean() equivalent
 *
 * Returns a created or reused object, the old one is freed (or the operation
 *         is done directly on @val)
 */
static xmlXPathObjectPtr
xmlXPathCacheConvertBoolean(xmlXPathContextPtr ctxt, xmlXPathObjectPtr val) {
    xmlXPathObjectPtr ret;

    if (val == NULL)
	return(xmlXPathCacheNewBoolean(ctxt, 0));
    if (val->type == XPATH_BOOLEAN)
	return(val);
    ret = xmlXPathCacheNewBoolean(ctxt, xmlXPathCastToBoolean(val));
    xmlXPathReleaseObject(ctxt, val);
    return(ret);
}

/**
 * xmlXPathCacheConvertNumber:
 * @ctxt: the XPath context
 * @val:  an XPath object
 *
 * This is the cached version of xmlXPathConvertNumber().
 * Converts an existing object to its number() equivalent
 *
 * Returns a created or reused object, the old one is freed (or the operation
 *         is done directly on @val)
 */
static xmlXPathObjectPtr
xmlXPathCacheConvertNumber(xmlXPathContextPtr ctxt, xmlXPathObjectPtr val) {
    xmlXPathObjectPtr ret;

    if (val == NULL)
	return(xmlXPathCacheNewFloat(ctxt, 0.0));
    if (val->type == XPATH_NUMBER)
	return(val);
    ret = xmlXPathCacheNewFloat(ctxt, xmlXPathCastToNumber(val));
    xmlXPathReleaseObject(ctxt, val);
    return(ret);
}

/************************************************************************
 *									*
 *		Parser stacks related functions and macros		*
 *									*
 ************************************************************************/

/**
 * valuePop:
 * @ctxt: an XPath evaluation context
 *
 * Pops the top XPath object from the value stack
 *
 * Returns the XPath object just removed
 */
xmlXPathObjectPtr
valuePop(xmlXPathParserContextPtr ctxt)
{
    xmlXPathObjectPtr ret;

    if ((ctxt == NULL) || (ctxt->valueNr <= 0))
        return (NULL);
    ctxt->valueNr--;
    if (ctxt->valueNr > 0)
        ctxt->value = ctxt->valueTab[ctxt->valueNr - 1];
    else
        ctxt->value = NULL;
    ret = ctxt->valueTab[ctxt->valueNr];
    ctxt->valueTab[ctxt->valueNr] = NULL;
    return (ret);
}
/**
 * valuePush:
 * @ctxt:  an XPath evaluation context
 * @value:  the XPath object
 *
 * Pushes a new XPath object on top of the value stack
 *
 * returns the number of items on the value stack
 */
int
valuePush(xmlXPathParserContextPtr ctxt, xmlXPathObjectPtr value)
{
    if ((ctxt == NULL) || (value == NULL)) return(-1);
    if (ctxt->valueNr >= ctxt->valueMax) {
        xmlXPathObjectPtr *tmp;

        tmp = (xmlXPathObjectPtr *) xmlRealloc(ctxt->valueTab,
                                             2 * ctxt->valueMax *
                                             sizeof(ctxt->valueTab[0]));
        if (tmp == NULL) {
            xmlGenericError(xmlGenericErrorContext, "realloc failed !\n");
            return (0);
        }
        ctxt->valueMax *= 2;
	ctxt->valueTab = tmp;
    }
    ctxt->valueTab[ctxt->valueNr] = value;
    ctxt->value = value;
    return (ctxt->valueNr++);
}

/**
 * xmlXPathPopBoolean:
 * @ctxt:  an XPath parser context
 *
 * Pops a boolean from the stack, handling conversion if needed.
 * Check error with #xmlXPathCheckError.
 *
 * Returns the boolean
 */
int
xmlXPathPopBoolean (xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr obj;
    int ret;

    obj = valuePop(ctxt);
    if (obj == NULL) {
	xmlXPathSetError(ctxt, XPATH_INVALID_OPERAND);
	return(0);
    }
    if (obj->type != XPATH_BOOLEAN)
	ret = xmlXPathCastToBoolean(obj);
    else
        ret = obj->boolval;
    xmlXPathReleaseObject(ctxt->context, obj);
    return(ret);
}

/**
 * xmlXPathPopNumber:
 * @ctxt:  an XPath parser context
 *
 * Pops a number from the stack, handling conversion if needed.
 * Check error with #xmlXPathCheckError.
 *
 * Returns the number
 */
double
xmlXPathPopNumber (xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr obj;
    double ret;

    obj = valuePop(ctxt);
    if (obj == NULL) {
	xmlXPathSetError(ctxt, XPATH_INVALID_OPERAND);
	return(0);
    }
    if (obj->type != XPATH_NUMBER)
	ret = xmlXPathCastToNumber(obj);
    else
        ret = obj->floatval;
    xmlXPathReleaseObject(ctxt->context, obj);
    return(ret);
}

/**
 * xmlXPathPopString:
 * @ctxt:  an XPath parser context
 *
 * Pops a string from the stack, handling conversion if needed.
 * Check error with #xmlXPathCheckError.
 *
 * Returns the string
 */
xmlChar *
xmlXPathPopString (xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr obj;
    xmlChar * ret;

    obj = valuePop(ctxt);
    if (obj == NULL) {
	xmlXPathSetError(ctxt, XPATH_INVALID_OPERAND);
	return(NULL);
    }
    ret = xmlXPathCastToString(obj);	/* this does required strdup */
    /* TODO: needs refactoring somewhere else */
    if (obj->stringval == ret)
	obj->stringval = NULL;
    xmlXPathReleaseObject(ctxt->context, obj);
    return(ret);
}

/**
 * xmlXPathPopNodeSet:
 * @ctxt:  an XPath parser context
 *
 * Pops a node-set from the stack, handling conversion if needed.
 * Check error with #xmlXPathCheckError.
 *
 * Returns the node-set
 */
xmlNodeSetPtr
xmlXPathPopNodeSet (xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr obj;
    xmlNodeSetPtr ret;

    if (ctxt == NULL) return(NULL);
    if (ctxt->value == NULL) {
	xmlXPathSetError(ctxt, XPATH_INVALID_OPERAND);
	return(NULL);
    }
    if (!xmlXPathStackIsNodeSet(ctxt)) {
	xmlXPathSetTypeError(ctxt);
	return(NULL);
    }
    obj = valuePop(ctxt);
    ret = obj->nodesetval;
#if 0
    /* to fix memory leak of not clearing obj->user */
    if (obj->boolval && obj->user != NULL)
        xmlFreeNodeList((xmlNodePtr) obj->user);
#endif
    obj->nodesetval = NULL;
    xmlXPathReleaseObject(ctxt->context, obj);
    return(ret);
}

/**
 * xmlXPathPopExternal:
 * @ctxt:  an XPath parser context
 *
 * Pops an external object from the stack, handling conversion if needed.
 * Check error with #xmlXPathCheckError.
 *
 * Returns the object
 */
void *
xmlXPathPopExternal (xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr obj;
    void * ret;

    if ((ctxt == NULL) || (ctxt->value == NULL)) {
	xmlXPathSetError(ctxt, XPATH_INVALID_OPERAND);
	return(NULL);
    }
    if (ctxt->value->type != XPATH_USERS) {
	xmlXPathSetTypeError(ctxt);
	return(NULL);
    }
    obj = valuePop(ctxt);
    ret = obj->user;
    obj->user = NULL;
    xmlXPathReleaseObject(ctxt->context, obj);
    return(ret);
}

/*
 * Macros for accessing the content. Those should be used only by the parser,
 * and not exported.
 *
 * Dirty macros, i.e. one need to make assumption on the context to use them
 *
 *   CUR_PTR return the current pointer to the xmlChar to be parsed.
 *   CUR     returns the current xmlChar value, i.e. a 8 bit value
 *           in ISO-Latin or UTF-8.
 *           This should be used internally by the parser
 *           only to compare to ASCII values otherwise it would break when
 *           running with UTF-8 encoding.
 *   NXT(n)  returns the n'th next xmlChar. Same as CUR is should be used only
 *           to compare on ASCII based substring.
 *   SKIP(n) Skip n xmlChar, and must also be used only to skip ASCII defined
 *           strings within the parser.
 *   CURRENT Returns the current char value, with the full decoding of
 *           UTF-8 if we are using this mode. It returns an int.
 *   NEXT    Skip to the next character, this does the proper decoding
 *           in UTF-8 mode. It also pop-up unfinished entities on the fly.
 *           It returns the pointer to the current xmlChar.
 */

#define CUR (*ctxt->cur)
#define SKIP(val) ctxt->cur += (val)
#define NXT(val) ctxt->cur[(val)]
#define CUR_PTR ctxt->cur
#define CUR_CHAR(l) xmlXPathCurrentChar(ctxt, &l)

#define COPY_BUF(l,b,i,v)                                              \
    if (l == 1) b[i++] = (xmlChar) v;                                  \
    else i += xmlCopyChar(l,&b[i],v)

#define NEXTL(l)  ctxt->cur += l

#define SKIP_BLANKS							\
    while (IS_BLANK_CH(*(ctxt->cur))) NEXT

#define CURRENT (*ctxt->cur)
#define NEXT ((*ctxt->cur) ?  ctxt->cur++: ctxt->cur)


#ifndef DBL_DIG
#define DBL_DIG 16
#endif
#ifndef DBL_EPSILON
#define DBL_EPSILON 1E-9
#endif

#define UPPER_DOUBLE 1E9
#define LOWER_DOUBLE 1E-5
#define	LOWER_DOUBLE_EXP 5

#define INTEGER_DIGITS DBL_DIG
#define FRACTION_DIGITS (DBL_DIG + 1 + (LOWER_DOUBLE_EXP))
#define EXPONENT_DIGITS (3 + 2)

/**
 * xmlXPathFormatNumber:
 * @number:     number to format
 * @buffer:     output buffer
 * @buffersize: size of output buffer
 *
 * Convert the number into a string representation.
 */
static void
xmlXPathFormatNumber(double number, char buffer[], int buffersize)
{
    switch (xmlXPathIsInf(number)) {
    case 1:
	if (buffersize > (int)sizeof("Infinity"))
	    snprintf(buffer, buffersize, "Infinity");
	break;
    case -1:
	if (buffersize > (int)sizeof("-Infinity"))
	    snprintf(buffer, buffersize, "-Infinity");
	break;
    default:
	if (xmlXPathIsNaN(number)) {
	    if (buffersize > (int)sizeof("NaN"))
		snprintf(buffer, buffersize, "NaN");
	} else if (number == 0 && xmlXPathGetSign(number) != 0) {
	    snprintf(buffer, buffersize, "0");
	} else if (number == ((int) number)) {
	    char work[30];
	    char *ptr, *cur;
	    int value = (int) number;

            ptr = &buffer[0];
	    if (value == 0) {
		*ptr++ = '0';
	    } else {
		snprintf(work, 29, "%d", value);
		cur = &work[0];
		while ((*cur) && (ptr - buffer < buffersize)) {
		    *ptr++ = *cur++;
		}
	    }
	    if (ptr - buffer < buffersize) {
		*ptr = 0;
	    } else if (buffersize > 0) {
		ptr--;
		*ptr = 0;
	    }
	} else {
	    /*
	      For the dimension of work,
	          DBL_DIG is number of significant digits
		  EXPONENT is only needed for "scientific notation"
	          3 is sign, decimal point, and terminating zero
		  LOWER_DOUBLE_EXP is max number of leading zeroes in fraction
	      Note that this dimension is slightly (a few characters)
	      larger than actually necessary.
	    */
	    char work[DBL_DIG + EXPONENT_DIGITS + 3 + LOWER_DOUBLE_EXP];
	    int integer_place, fraction_place;
	    char *ptr;
	    char *after_fraction;
	    double absolute_value;
	    int size;

	    absolute_value = fabs(number);

	    /*
	     * First choose format - scientific or regular floating point.
	     * In either case, result is in work, and after_fraction points
	     * just past the fractional part.
	    */
	    if ( ((absolute_value > UPPER_DOUBLE) ||
		  (absolute_value < LOWER_DOUBLE)) &&
		 (absolute_value != 0.0) ) {
		/* Use scientific notation */
		integer_place = DBL_DIG + EXPONENT_DIGITS + 1;
		fraction_place = DBL_DIG - 1;
		size = snprintf(work, sizeof(work),"%*.*e",
			 integer_place, fraction_place, number);
		while ((size > 0) && (work[size] != 'e')) size--;

	    }
	    else {
		/* Use regular notation */
		if (absolute_value > 0.0) {
		    integer_place = (int)log10(absolute_value);
		    if (integer_place > 0)
		        fraction_place = DBL_DIG - integer_place - 1;
		    else
		        fraction_place = DBL_DIG - integer_place;
		} else {
		    fraction_place = 1;
		}
		size = snprintf(work, sizeof(work), "%0.*f",
				fraction_place, number);
	    }

	    /* Remove fractional trailing zeroes */
	    after_fraction = work + size;
	    ptr = after_fraction;
	    while (*(--ptr) == '0')
		;
	    if (*ptr != '.')
	        ptr++;
	    while ((*ptr++ = *after_fraction++) != 0);

	    /* Finally copy result back to caller */
	    size = strlen(work) + 1;
	    if (size > buffersize) {
		work[buffersize - 1] = 0;
		size = buffersize;
	    }
	    memmove(buffer, work, size);
	}
	break;
    }
}


/************************************************************************
 *									*
 *			Routines to handle NodeSets			*
 *									*
 ************************************************************************/

/**
 * xmlXPathOrderDocElems:
 * @doc:  an input document
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
long
xmlXPathOrderDocElems(xmlDocPtr doc) {
    long count = 0;
    xmlNodePtr cur;

    if (doc == NULL)
	return(-1);
    cur = doc->children;
    while (cur != NULL) {
	if (cur->type == XML_ELEMENT_NODE) {
	    cur->content = (void *) (-(++count));
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
	    if (cur == (xmlNodePtr) doc) {
		cur = NULL;
		break;
	    }
	    if (cur->next != NULL) {
		cur = cur->next;
		break;
	    }
	} while (cur != NULL);
    }
    return(count);
}

/**
 * xmlXPathCmpNodes:
 * @node1:  the first node
 * @node2:  the second node
 *
 * Compare two nodes w.r.t document order
 *
 * Returns -2 in case of error 1 if first point < second point, 0 if
 *         it's the same node, -1 otherwise
 */
int
xmlXPathCmpNodes(xmlNodePtr node1, xmlNodePtr node2) {
    int depth1, depth2;
    int attr1 = 0, attr2 = 0;
    xmlNodePtr attrNode1 = NULL, attrNode2 = NULL;
    xmlNodePtr cur, root;

    if ((node1 == NULL) || (node2 == NULL))
	return(-2);
    /*
     * a couple of optimizations which will avoid computations in most cases
     */
    if (node1 == node2)		/* trivial case */
	return(0);
    if (node1->type == XML_ATTRIBUTE_NODE) {
	attr1 = 1;
	attrNode1 = node1;
	node1 = node1->parent;
    }
    if (node2->type == XML_ATTRIBUTE_NODE) {
	attr2 = 1;
	attrNode2 = node2;
	node2 = node2->parent;
    }
    if (node1 == node2) {
	if (attr1 == attr2) {
	    /* not required, but we keep attributes in order */
	    if (attr1 != 0) {
	        cur = attrNode2->prev;
		while (cur != NULL) {
		    if (cur == attrNode1)
		        return (1);
		    cur = cur->prev;
		}
		return (-1);
	    }
	    return(0);
	}
	if (attr2 == 1)
	    return(1);
	return(-1);
    }
    if ((node1->type == XML_NAMESPACE_DECL) ||
        (node2->type == XML_NAMESPACE_DECL))
	return(1);
    if (node1 == node2->prev)
	return(1);
    if (node1 == node2->next)
	return(-1);

    /*
     * Speedup using document order if availble.
     */
    if ((node1->type == XML_ELEMENT_NODE) &&
	(node2->type == XML_ELEMENT_NODE) &&
	(0 > (long) node1->content) &&
	(0 > (long) node2->content) &&
	(node1->doc == node2->doc)) {
	long l1, l2;

	l1 = -((long) node1->content);
	l2 = -((long) node2->content);
	if (l1 < l2)
	    return(1);
	if (l1 > l2)
	    return(-1);
    }

    /*
     * compute depth to root
     */
    for (depth2 = 0, cur = node2;cur->parent != NULL;cur = cur->parent) {
	if (cur == node1)
	    return(1);
	depth2++;
    }
    root = cur;
    for (depth1 = 0, cur = node1;cur->parent != NULL;cur = cur->parent) {
	if (cur == node2)
	    return(-1);
	depth1++;
    }
    /*
     * Distinct document (or distinct entities :-( ) case.
     */
    if (root != cur) {
	return(-2);
    }
    /*
     * get the nearest common ancestor.
     */
    while (depth1 > depth2) {
	depth1--;
	node1 = node1->parent;
    }
    while (depth2 > depth1) {
	depth2--;
	node2 = node2->parent;
    }
    while (node1->parent != node2->parent) {
	node1 = node1->parent;
	node2 = node2->parent;
	/* should not happen but just in case ... */
	if ((node1 == NULL) || (node2 == NULL))
	    return(-2);
    }
    /*
     * Find who's first.
     */
    if (node1 == node2->prev)
	return(1);
    if (node1 == node2->next)
	return(-1);
    /*
     * Speedup using document order if availble.
     */
    if ((node1->type == XML_ELEMENT_NODE) &&
	(node2->type == XML_ELEMENT_NODE) &&
	(0 > (long) node1->content) &&
	(0 > (long) node2->content) &&
	(node1->doc == node2->doc)) {
	long l1, l2;

	l1 = -((long) node1->content);
	l2 = -((long) node2->content);
	if (l1 < l2)
	    return(1);
	if (l1 > l2)
	    return(-1);
    }

    for (cur = node1->next;cur != NULL;cur = cur->next)
	if (cur == node2)
	    return(1);
    return(-1); /* assume there is no sibling list corruption */
}

#ifdef XP_OPTIMIZED_NON_ELEM_COMPARISON
/**
 * xmlXPathCmpNodesExt:
 * @node1:  the first node
 * @node2:  the second node
 *
 * Compare two nodes w.r.t document order.
 * This one is optimized for handling of non-element nodes.
 *
 * Returns -2 in case of error 1 if first point < second point, 0 if
 *         it's the same node, -1 otherwise
 */
static int
xmlXPathCmpNodesExt(xmlNodePtr node1, xmlNodePtr node2) {
    int depth1, depth2;
    int misc = 0, precedence1 = 0, precedence2 = 0;
    xmlNodePtr miscNode1 = NULL, miscNode2 = NULL;
    xmlNodePtr cur, root;
    long l1, l2;

    if ((node1 == NULL) || (node2 == NULL))
	return(-2);

    if (node1 == node2)
	return(0);

    /*
     * a couple of optimizations which will avoid computations in most cases
     */
    switch (node1->type) {
	case XML_ELEMENT_NODE:
	    if (node2->type == XML_ELEMENT_NODE) {
		if ((0 > (long) node1->content) && /* TODO: Would a != 0 suffice here? */
		    (0 > (long) node2->content) &&
		    (node1->doc == node2->doc))
		{
		    l1 = -((long) node1->content);
		    l2 = -((long) node2->content);
		    if (l1 < l2)
			return(1);
		    if (l1 > l2)
			return(-1);
		} else
		    goto turtle_comparison;
	    }
	    break;
	case XML_ATTRIBUTE_NODE:
	    precedence1 = 1; /* element is owner */
	    miscNode1 = node1;
	    node1 = node1->parent;
	    misc = 1;
	    break;
	case XML_TEXT_NODE:
	case XML_CDATA_SECTION_NODE:
	case XML_COMMENT_NODE:
	case XML_PI_NODE: {
	    miscNode1 = node1;
	    /*
	    * Find nearest element node.
	    */
	    if (node1->prev != NULL) {
		do {
		    node1 = node1->prev;
		    if (node1->type == XML_ELEMENT_NODE) {
			precedence1 = 3; /* element in prev-sibl axis */
			break;
		    }
		    if (node1->prev == NULL) {
			precedence1 = 2; /* element is parent */
			/*
			* URGENT TODO: Are there any cases, where the
			* parent of such a node is not an element node?
			*/
			node1 = node1->parent;
			break;
		    }
		} while (1);
	    } else {
		precedence1 = 2; /* element is parent */
		node1 = node1->parent;
	    }
	    if ((node1 == NULL) || (node1->type != XML_ELEMENT_NODE) ||
		(0 <= (long) node1->content)) {
		/*
		* Fallback for whatever case.
		*/
		node1 = miscNode1;
		precedence1 = 0;
	    } else
		misc = 1;
	}
	    break;
	case XML_NAMESPACE_DECL:
	    /*
	    * TODO: why do we return 1 for namespace nodes?
	    */
	    return(1);
	default:
	    break;
    }
    switch (node2->type) {
	case XML_ELEMENT_NODE:
	    break;
	case XML_ATTRIBUTE_NODE:
	    precedence2 = 1; /* element is owner */
	    miscNode2 = node2;
	    node2 = node2->parent;
	    misc = 1;
	    break;
	case XML_TEXT_NODE:
	case XML_CDATA_SECTION_NODE:
	case XML_COMMENT_NODE:
	case XML_PI_NODE: {
	    miscNode2 = node2;
	    if (node2->prev != NULL) {
		do {
		    node2 = node2->prev;
		    if (node2->type == XML_ELEMENT_NODE) {
			precedence2 = 3; /* element in prev-sibl axis */
			break;
		    }
		    if (node2->prev == NULL) {
			precedence2 = 2; /* element is parent */
			node2 = node2->parent;
			break;
		    }
		} while (1);
	    } else {
		precedence2 = 2; /* element is parent */
		node2 = node2->parent;
	    }
	    if ((node2 == NULL) || (node2->type != XML_ELEMENT_NODE) ||
		(0 <= (long) node1->content))
	    {
		node2 = miscNode2;
		precedence2 = 0;
	    } else
		misc = 1;
	}
	    break;
	case XML_NAMESPACE_DECL:
	    return(1);
	default:
	    break;
    }
    if (misc) {
	if (node1 == node2) {
	    if (precedence1 == precedence2) {
		/*
		* The ugly case; but normally there aren't many
		* adjacent non-element nodes around.
		*/
		cur = miscNode2->prev;
		while (cur != NULL) {
		    if (cur == miscNode1)
			return(1);
		    if (cur->type == XML_ELEMENT_NODE)
			return(-1);
		    cur = cur->prev;
		}
		return (-1);
	    } else {
		/*
		* Evaluate based on higher precedence wrt to the element.
		* TODO: This assumes attributes are sorted before content.
		*   Is this 100% correct?
		*/
		if (precedence1 < precedence2)
		    return(1);
		else
		    return(-1);
	    }
	}
	/*
	* Special case: One of the helper-elements is contained by the other.
	* <foo>
	*   <node2>
	*     <node1>Text-1(precedence1 == 2)</node1>
	*   </node2>
	*   Text-6(precedence2 == 3)
	* </foo>
	*/
	if ((precedence2 == 3) && (precedence1 > 1)) {
	    cur = node1->parent;
	    while (cur) {
		if (cur == node2)
		    return(1);
		cur = cur->parent;
	    }
	}
	if ((precedence1 == 3) && (precedence2 > 1)) {
	    cur = node2->parent;
	    while (cur) {
		if (cur == node1)
		    return(-1);
		cur = cur->parent;
	    }
	}
    }

    /*
     * Speedup using document order if availble.
     */
    if ((node1->type == XML_ELEMENT_NODE) &&
	(node2->type == XML_ELEMENT_NODE) &&
	(0 > (long) node1->content) &&
	(0 > (long) node2->content) &&
	(node1->doc == node2->doc)) {

	l1 = -((long) node1->content);
	l2 = -((long) node2->content);
	if (l1 < l2)
	    return(1);
	if (l1 > l2)
	    return(-1);
    }

turtle_comparison:

    if (node1 == node2->prev)
	return(1);
    if (node1 == node2->next)
	return(-1);
    /*
     * compute depth to root
     */
    for (depth2 = 0, cur = node2;cur->parent != NULL;cur = cur->parent) {
	if (cur == node1)
	    return(1);
	depth2++;
    }
    root = cur;
    for (depth1 = 0, cur = node1;cur->parent != NULL;cur = cur->parent) {
	if (cur == node2)
	    return(-1);
	depth1++;
    }
    /*
     * Distinct document (or distinct entities :-( ) case.
     */
    if (root != cur) {
	return(-2);
    }
    /*
     * get the nearest common ancestor.
     */
    while (depth1 > depth2) {
	depth1--;
	node1 = node1->parent;
    }
    while (depth2 > depth1) {
	depth2--;
	node2 = node2->parent;
    }
    while (node1->parent != node2->parent) {
	node1 = node1->parent;
	node2 = node2->parent;
	/* should not happen but just in case ... */
	if ((node1 == NULL) || (node2 == NULL))
	    return(-2);
    }
    /*
     * Find who's first.
     */
    if (node1 == node2->prev)
	return(1);
    if (node1 == node2->next)
	return(-1);
    /*
     * Speedup using document order if availble.
     */
    if ((node1->type == XML_ELEMENT_NODE) &&
	(node2->type == XML_ELEMENT_NODE) &&
	(0 > (long) node1->content) &&
	(0 > (long) node2->content) &&
	(node1->doc == node2->doc)) {

	l1 = -((long) node1->content);
	l2 = -((long) node2->content);
	if (l1 < l2)
	    return(1);
	if (l1 > l2)
	    return(-1);
    }

    for (cur = node1->next;cur != NULL;cur = cur->next)
	if (cur == node2)
	    return(1);
    return(-1); /* assume there is no sibling list corruption */
}
#endif /* XP_OPTIMIZED_NON_ELEM_COMPARISON */

/**
 * xmlXPathNodeSetSort:
 * @set:  the node set
 *
 * Sort the node set in document order
 */
void
xmlXPathNodeSetSort(xmlNodeSetPtr set) {
    int i, j, incr, len;
    xmlNodePtr tmp;

    if (set == NULL)
	return;

    /* Use Shell's sort to sort the node-set */
    len = set->nodeNr;
    for (incr = len / 2; incr > 0; incr /= 2) {
	for (i = incr; i < len; i++) {
	    j = i - incr;
	    while (j >= 0) {
#ifdef XP_OPTIMIZED_NON_ELEM_COMPARISON
		if (xmlXPathCmpNodesExt(set->nodeTab[j],
			set->nodeTab[j + incr]) == -1)
#else
		if (xmlXPathCmpNodes(set->nodeTab[j],
			set->nodeTab[j + incr]) == -1)
#endif
		{
		    tmp = set->nodeTab[j];
		    set->nodeTab[j] = set->nodeTab[j + incr];
		    set->nodeTab[j + incr] = tmp;
		    j -= incr;
		} else
		    break;
	    }
	}
    }
}

#define XML_NODESET_DEFAULT	10
/**
 * xmlXPathNodeSetDupNs:
 * @node:  the parent node of the namespace XPath node
 * @ns:  the libxml namespace declaration node.
 *
 * Namespace node in libxml don't match the XPath semantic. In a node set
 * the namespace nodes are duplicated and the next pointer is set to the
 * parent node in the XPath semantic.
 *
 * Returns the newly created object.
 */
static xmlNodePtr
xmlXPathNodeSetDupNs(xmlNodePtr node, xmlNsPtr ns) {
    xmlNsPtr cur;

    if ((ns == NULL) || (ns->type != XML_NAMESPACE_DECL))
	return(NULL);
    if ((node == NULL) || (node->type == XML_NAMESPACE_DECL))
	return((xmlNodePtr) ns);

    /*
     * Allocate a new Namespace and fill the fields.
     */
    cur = (xmlNsPtr) xmlMalloc(sizeof(xmlNs));
    if (cur == NULL) {
        xmlXPathErrMemory(NULL, "duplicating namespace\n");
	return(NULL);
    }
    memset(cur, 0, sizeof(xmlNs));
    cur->type = XML_NAMESPACE_DECL;
    if (ns->href != NULL)
	cur->href = xmlStrdup(ns->href);
    if (ns->prefix != NULL)
	cur->prefix = xmlStrdup(ns->prefix);
    cur->next = (xmlNsPtr) node;
    return((xmlNodePtr) cur);
}

/**
 * xmlXPathNodeSetFreeNs:
 * @ns:  the XPath namespace node found in a nodeset.
 *
 * Namespace nodes in libxml don't match the XPath semantic. In a node set
 * the namespace nodes are duplicated and the next pointer is set to the
 * parent node in the XPath semantic. Check if such a node needs to be freed
 */
void
xmlXPathNodeSetFreeNs(xmlNsPtr ns) {
    if ((ns == NULL) || (ns->type != XML_NAMESPACE_DECL))
	return;

    if ((ns->next != NULL) && (ns->next->type != XML_NAMESPACE_DECL)) {
	if (ns->href != NULL)
	    xmlFree((xmlChar *)ns->href);
	if (ns->prefix != NULL)
	    xmlFree((xmlChar *)ns->prefix);
	xmlFree(ns);
    }
}

/**
 * xmlXPathNodeSetCreate:
 * @val:  an initial xmlNodePtr, or NULL
 *
 * Create a new xmlNodeSetPtr of type double and of value @val
 *
 * Returns the newly created object.
 */
xmlNodeSetPtr
xmlXPathNodeSetCreate(xmlNodePtr val) {
    xmlNodeSetPtr ret;

    ret = (xmlNodeSetPtr) xmlMalloc(sizeof(xmlNodeSet));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating nodeset\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlNodeSet));
    if (val != NULL) {
        ret->nodeTab = (xmlNodePtr *) xmlMalloc(XML_NODESET_DEFAULT *
					     sizeof(xmlNodePtr));
	if (ret->nodeTab == NULL) {
	    xmlXPathErrMemory(NULL, "creating nodeset\n");
	    xmlFree(ret);
	    return(NULL);
	}
	memset(ret->nodeTab, 0 ,
	       XML_NODESET_DEFAULT * (size_t) sizeof(xmlNodePtr));
        ret->nodeMax = XML_NODESET_DEFAULT;
	if (val->type == XML_NAMESPACE_DECL) {
	    xmlNsPtr ns = (xmlNsPtr) val;

	    ret->nodeTab[ret->nodeNr++] =
		xmlXPathNodeSetDupNs((xmlNodePtr) ns->next, ns);
	} else
	    ret->nodeTab[ret->nodeNr++] = val;
    }
    return(ret);
}

/**
 * xmlXPathNodeSetCreateSize:
 * @size:  the initial size of the set
 *
 * Create a new xmlNodeSetPtr of type double and of value @val
 *
 * Returns the newly created object.
 */
static xmlNodeSetPtr
xmlXPathNodeSetCreateSize(int size) {
    xmlNodeSetPtr ret;

    ret = (xmlNodeSetPtr) xmlMalloc(sizeof(xmlNodeSet));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating nodeset\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlNodeSet));
    if (size < XML_NODESET_DEFAULT)
	size = XML_NODESET_DEFAULT;
    ret->nodeTab = (xmlNodePtr *) xmlMalloc(size * sizeof(xmlNodePtr));
    if (ret->nodeTab == NULL) {
	xmlXPathErrMemory(NULL, "creating nodeset\n");
	xmlFree(ret);
	return(NULL);
    }
    memset(ret->nodeTab, 0 , size * (size_t) sizeof(xmlNodePtr));
    ret->nodeMax = size;
    return(ret);
}

/**
 * xmlXPathNodeSetContains:
 * @cur:  the node-set
 * @val:  the node
 *
 * checks whether @cur contains @val
 *
 * Returns true (1) if @cur contains @val, false (0) otherwise
 */
int
xmlXPathNodeSetContains (xmlNodeSetPtr cur, xmlNodePtr val) {
    int i;

    if ((cur == NULL) || (val == NULL)) return(0);
    if (val->type == XML_NAMESPACE_DECL) {
	for (i = 0; i < cur->nodeNr; i++) {
	    if (cur->nodeTab[i]->type == XML_NAMESPACE_DECL) {
		xmlNsPtr ns1, ns2;

		ns1 = (xmlNsPtr) val;
		ns2 = (xmlNsPtr) cur->nodeTab[i];
		if (ns1 == ns2)
		    return(1);
		if ((ns1->next != NULL) && (ns2->next == ns1->next) &&
	            (xmlStrEqual(ns1->prefix, ns2->prefix)))
		    return(1);
	    }
	}
    } else {
	for (i = 0; i < cur->nodeNr; i++) {
	    if (cur->nodeTab[i] == val)
		return(1);
	}
    }
    return(0);
}

/**
 * xmlXPathNodeSetAddNs:
 * @cur:  the initial node set
 * @node:  the hosting node
 * @ns:  a the namespace node
 *
 * add a new namespace node to an existing NodeSet
 */
void
xmlXPathNodeSetAddNs(xmlNodeSetPtr cur, xmlNodePtr node, xmlNsPtr ns) {
    int i;


    if ((cur == NULL) || (ns == NULL) || (node == NULL) ||
        (ns->type != XML_NAMESPACE_DECL) ||
	(node->type != XML_ELEMENT_NODE))
	return;

    /* @@ with_ns to check whether namespace nodes should be looked at @@ */
    /*
     * prevent duplicates
     */
    for (i = 0;i < cur->nodeNr;i++) {
        if ((cur->nodeTab[i] != NULL) &&
	    (cur->nodeTab[i]->type == XML_NAMESPACE_DECL) &&
	    (((xmlNsPtr)cur->nodeTab[i])->next == (xmlNsPtr) node) &&
	    (xmlStrEqual(ns->prefix, ((xmlNsPtr)cur->nodeTab[i])->prefix)))
	    return;
    }

    /*
     * grow the nodeTab if needed
     */
    if (cur->nodeMax == 0) {
        cur->nodeTab = (xmlNodePtr *) xmlMalloc(XML_NODESET_DEFAULT *
					     sizeof(xmlNodePtr));
	if (cur->nodeTab == NULL) {
	    xmlXPathErrMemory(NULL, "growing nodeset\n");
	    return;
	}
	memset(cur->nodeTab, 0 ,
	       XML_NODESET_DEFAULT * (size_t) sizeof(xmlNodePtr));
        cur->nodeMax = XML_NODESET_DEFAULT;
    } else if (cur->nodeNr == cur->nodeMax) {
        xmlNodePtr *temp;

        cur->nodeMax *= 2;
	temp = (xmlNodePtr *) xmlRealloc(cur->nodeTab, cur->nodeMax *
				      sizeof(xmlNodePtr));
	if (temp == NULL) {
	    xmlXPathErrMemory(NULL, "growing nodeset\n");
	    return;
	}
	cur->nodeTab = temp;
    }
    cur->nodeTab[cur->nodeNr++] = xmlXPathNodeSetDupNs(node, ns);
}

/**
 * xmlXPathNodeSetAdd:
 * @cur:  the initial node set
 * @val:  a new xmlNodePtr
 *
 * add a new xmlNodePtr to an existing NodeSet
 */
void
xmlXPathNodeSetAdd(xmlNodeSetPtr cur, xmlNodePtr val) {
    int i;

    if ((cur == NULL) || (val == NULL)) return;

#if 0
    if ((val->type == XML_ELEMENT_NODE) && (val->name[0] == ' '))
	return;	/* an XSLT fake node */
#endif

    /* @@ with_ns to check whether namespace nodes should be looked at @@ */
    /*
     * prevent duplcates
     */
    for (i = 0;i < cur->nodeNr;i++)
        if (cur->nodeTab[i] == val) return;

    /*
     * grow the nodeTab if needed
     */
    if (cur->nodeMax == 0) {
        cur->nodeTab = (xmlNodePtr *) xmlMalloc(XML_NODESET_DEFAULT *
					     sizeof(xmlNodePtr));
	if (cur->nodeTab == NULL) {
	    xmlXPathErrMemory(NULL, "growing nodeset\n");
	    return;
	}
	memset(cur->nodeTab, 0 ,
	       XML_NODESET_DEFAULT * (size_t) sizeof(xmlNodePtr));
        cur->nodeMax = XML_NODESET_DEFAULT;
    } else if (cur->nodeNr == cur->nodeMax) {
        xmlNodePtr *temp;

        cur->nodeMax *= 2;
	temp = (xmlNodePtr *) xmlRealloc(cur->nodeTab, cur->nodeMax *
				      sizeof(xmlNodePtr));
	if (temp == NULL) {
	    xmlXPathErrMemory(NULL, "growing nodeset\n");
	    return;
	}
	cur->nodeTab = temp;
    }
    if (val->type == XML_NAMESPACE_DECL) {
	xmlNsPtr ns = (xmlNsPtr) val;

	cur->nodeTab[cur->nodeNr++] =
	    xmlXPathNodeSetDupNs((xmlNodePtr) ns->next, ns);
    } else
	cur->nodeTab[cur->nodeNr++] = val;
}

/**
 * xmlXPathNodeSetAddUnique:
 * @cur:  the initial node set
 * @val:  a new xmlNodePtr
 *
 * add a new xmlNodePtr to an existing NodeSet, optimized version
 * when we are sure the node is not already in the set.
 */
void
xmlXPathNodeSetAddUnique(xmlNodeSetPtr cur, xmlNodePtr val) {
    if ((cur == NULL) || (val == NULL)) return;

#if 0
    if ((val->type == XML_ELEMENT_NODE) && (val->name[0] == ' '))
	return;	/* an XSLT fake node */
#endif

    /* @@ with_ns to check whether namespace nodes should be looked at @@ */
    /*
     * grow the nodeTab if needed
     */
    if (cur->nodeMax == 0) {
        cur->nodeTab = (xmlNodePtr *) xmlMalloc(XML_NODESET_DEFAULT *
					     sizeof(xmlNodePtr));
	if (cur->nodeTab == NULL) {
	    xmlXPathErrMemory(NULL, "growing nodeset\n");
	    return;
	}
	memset(cur->nodeTab, 0 ,
	       XML_NODESET_DEFAULT * (size_t) sizeof(xmlNodePtr));
        cur->nodeMax = XML_NODESET_DEFAULT;
    } else if (cur->nodeNr == cur->nodeMax) {
        xmlNodePtr *temp;

        cur->nodeMax *= 2;
	temp = (xmlNodePtr *) xmlRealloc(cur->nodeTab, cur->nodeMax *
				      sizeof(xmlNodePtr));
	if (temp == NULL) {
	    xmlXPathErrMemory(NULL, "growing nodeset\n");
	    return;
	}
	cur->nodeTab = temp;
    }
    if (val->type == XML_NAMESPACE_DECL) {
	xmlNsPtr ns = (xmlNsPtr) val;

	cur->nodeTab[cur->nodeNr++] =
	    xmlXPathNodeSetDupNs((xmlNodePtr) ns->next, ns);
    } else
	cur->nodeTab[cur->nodeNr++] = val;
}

/**
 * xmlXPathNodeSetMerge:
 * @val1:  the first NodeSet or NULL
 * @val2:  the second NodeSet
 *
 * Merges two nodesets, all nodes from @val2 are added to @val1
 * if @val1 is NULL, a new set is created and copied from @val2
 *
 * Returns @val1 once extended or NULL in case of error.
 */
xmlNodeSetPtr
xmlXPathNodeSetMerge(xmlNodeSetPtr val1, xmlNodeSetPtr val2) {
    int i, j, initNr, skip;
    xmlNodePtr n1, n2;

    if (val2 == NULL) return(val1);
    if (val1 == NULL) {
	val1 = xmlXPathNodeSetCreate(NULL);
    if (val1 == NULL)
        return (NULL);
#if 0
	/*
	* TODO: The optimization won't work in every case, since
	*  those nasty namespace nodes need to be added with
	*  xmlXPathNodeSetDupNs() to the set; thus a pure
	*  memcpy is not possible.
	*  If there was a flag on the nodesetval, indicating that
	*  some temporary nodes are in, that would be helpfull.
	*/
	/*
	* Optimization: Create an equally sized node-set
	* and memcpy the content.
	*/
	val1 = xmlXPathNodeSetCreateSize(val2->nodeNr);
	if (val1 == NULL)
	    return(NULL);
	if (val2->nodeNr != 0) {
	    if (val2->nodeNr == 1)
		*(val1->nodeTab) = *(val2->nodeTab);
	    else {
		memcpy(val1->nodeTab, val2->nodeTab,
		    val2->nodeNr * sizeof(xmlNodePtr));
	    }
	    val1->nodeNr = val2->nodeNr;
	}
	return(val1);
#endif
    }

    /* @@ with_ns to check whether namespace nodes should be looked at @@ */
    initNr = val1->nodeNr;

    for (i = 0;i < val2->nodeNr;i++) {
	n2 = val2->nodeTab[i];
	/*
	 * check against duplicates
	 */
	skip = 0;
	for (j = 0; j < initNr; j++) {
	    n1 = val1->nodeTab[j];
	    if (n1 == n2) {
		skip = 1;
		break;
	    } else if ((n1->type == XML_NAMESPACE_DECL) &&
		       (n2->type == XML_NAMESPACE_DECL)) {
		if ((((xmlNsPtr) n1)->next == ((xmlNsPtr) n2)->next) &&
		    (xmlStrEqual(((xmlNsPtr) n1)->prefix,
			((xmlNsPtr) n2)->prefix)))
		{
		    skip = 1;
		    break;
		}
	    }
	}
	if (skip)
	    continue;

	/*
	 * grow the nodeTab if needed
	 */
	if (val1->nodeMax == 0) {
	    val1->nodeTab = (xmlNodePtr *) xmlMalloc(XML_NODESET_DEFAULT *
						    sizeof(xmlNodePtr));
	    if (val1->nodeTab == NULL) {
	        xmlXPathErrMemory(NULL, "merging nodeset\n");
		return(NULL);
	    }
	    memset(val1->nodeTab, 0 ,
		   XML_NODESET_DEFAULT * (size_t) sizeof(xmlNodePtr));
	    val1->nodeMax = XML_NODESET_DEFAULT;
	} else if (val1->nodeNr == val1->nodeMax) {
	    xmlNodePtr *temp;

	    val1->nodeMax *= 2;
	    temp = (xmlNodePtr *) xmlRealloc(val1->nodeTab, val1->nodeMax *
					     sizeof(xmlNodePtr));
	    if (temp == NULL) {
	        xmlXPathErrMemory(NULL, "merging nodeset\n");
		return(NULL);
	    }
	    val1->nodeTab = temp;
	}
	if (n2->type == XML_NAMESPACE_DECL) {
	    xmlNsPtr ns = (xmlNsPtr) n2;

	    val1->nodeTab[val1->nodeNr++] =
		xmlXPathNodeSetDupNs((xmlNodePtr) ns->next, ns);
	} else
	    val1->nodeTab[val1->nodeNr++] = n2;
    }

    return(val1);
}

#if 0 /* xmlXPathNodeSetMergeUnique() is currently not used anymore */
/**
 * xmlXPathNodeSetMergeUnique:
 * @val1:  the first NodeSet or NULL
 * @val2:  the second NodeSet
 *
 * Merges two nodesets, all nodes from @val2 are added to @val1
 * if @val1 is NULL, a new set is created and copied from @val2
 *
 * Returns @val1 once extended or NULL in case of error.
 */
static xmlNodeSetPtr
xmlXPathNodeSetMergeUnique(xmlNodeSetPtr val1, xmlNodeSetPtr val2) {
    int i;

    if (val2 == NULL) return(val1);
    if (val1 == NULL) {
	val1 = xmlXPathNodeSetCreate(NULL);
    }
    if (val1 == NULL)
        return (NULL);

    /* @@ with_ns to check whether namespace nodes should be looked at @@ */

    for (i = 0;i < val2->nodeNr;i++) {
	/*
	 * grow the nodeTab if needed
	 */
	if (val1->nodeMax == 0) {
	    val1->nodeTab = (xmlNodePtr *) xmlMalloc(XML_NODESET_DEFAULT *
						    sizeof(xmlNodePtr));
	    if (val1->nodeTab == NULL) {
	        xmlXPathErrMemory(NULL, "merging nodeset\n");
		return(NULL);
	    }
	    memset(val1->nodeTab, 0 ,
		   XML_NODESET_DEFAULT * (size_t) sizeof(xmlNodePtr));
	    val1->nodeMax = XML_NODESET_DEFAULT;
	} else if (val1->nodeNr == val1->nodeMax) {
	    xmlNodePtr *temp;

	    val1->nodeMax *= 2;
	    temp = (xmlNodePtr *) xmlRealloc(val1->nodeTab, val1->nodeMax *
					     sizeof(xmlNodePtr));
	    if (temp == NULL) {
	        xmlXPathErrMemory(NULL, "merging nodeset\n");
		return(NULL);
	    }
	    val1->nodeTab = temp;
	}
	if (val2->nodeTab[i]->type == XML_NAMESPACE_DECL) {
	    xmlNsPtr ns = (xmlNsPtr) val2->nodeTab[i];

	    val1->nodeTab[val1->nodeNr++] =
		xmlXPathNodeSetDupNs((xmlNodePtr) ns->next, ns);
	} else
	    val1->nodeTab[val1->nodeNr++] = val2->nodeTab[i];
    }

    return(val1);
}
#endif /* xmlXPathNodeSetMergeUnique() is currently not used anymore */

/**
 * xmlXPathNodeSetMergeAndClear:
 * @set1:  the first NodeSet or NULL
 * @set2:  the second NodeSet
 * @hasSet2NsNodes: 1 if set2 contains namespaces nodes
 *
 * Merges two nodesets, all nodes from @set2 are added to @set1
 * if @set1 is NULL, a new set is created and copied from @set2.
 * Checks for duplicate nodes. Clears set2.
 *
 * Returns @set1 once extended or NULL in case of error.
 */
static xmlNodeSetPtr
xmlXPathNodeSetMergeAndClear(xmlNodeSetPtr set1, xmlNodeSetPtr set2,
			     int hasNullEntries)
{
    if ((set1 == NULL) && (hasNullEntries == 0)) {
	/*
	* Note that doing a memcpy of the list, namespace nodes are
	* just assigned to set1, since set2 is cleared anyway.
	*/
	set1 = xmlXPathNodeSetCreateSize(set2->nodeNr);
	if (set1 == NULL)
	    return(NULL);
	if (set2->nodeNr != 0) {
	    memcpy(set1->nodeTab, set2->nodeTab,
		set2->nodeNr * sizeof(xmlNodePtr));
	    set1->nodeNr = set2->nodeNr;
	}
    } else {
	int i, j, initNbSet1;
	xmlNodePtr n1, n2;

	if (set1 == NULL)
            set1 = xmlXPathNodeSetCreate(NULL);
        if (set1 == NULL)
            return (NULL);

	initNbSet1 = set1->nodeNr;
	for (i = 0;i < set2->nodeNr;i++) {
	    n2 = set2->nodeTab[i];
	    /*
	    * Skip NULLed entries.
	    */
	    if (n2 == NULL)
		continue;
	    /*
	    * Skip duplicates.
	    */
	    for (j = 0; j < initNbSet1; j++) {
		n1 = set1->nodeTab[j];
		if (n1 == n2) {
		    goto skip_node;
		} else if ((n1->type == XML_NAMESPACE_DECL) &&
		    (n2->type == XML_NAMESPACE_DECL))
		{
		    if ((((xmlNsPtr) n1)->next == ((xmlNsPtr) n2)->next) &&
			(xmlStrEqual(((xmlNsPtr) n1)->prefix,
			((xmlNsPtr) n2)->prefix)))
		    {
			/*
			* Free the namespace node.
			*/
			set2->nodeTab[i] = NULL;
			xmlXPathNodeSetFreeNs((xmlNsPtr) n2);
			goto skip_node;
		    }
		}
	    }
	    /*
	    * grow the nodeTab if needed
	    */
	    if (set1->nodeMax == 0) {
		set1->nodeTab = (xmlNodePtr *) xmlMalloc(
		    XML_NODESET_DEFAULT * sizeof(xmlNodePtr));
		if (set1->nodeTab == NULL) {
		    xmlXPathErrMemory(NULL, "merging nodeset\n");
		    return(NULL);
		}
		memset(set1->nodeTab, 0,
		    XML_NODESET_DEFAULT * (size_t) sizeof(xmlNodePtr));
		set1->nodeMax = XML_NODESET_DEFAULT;
	    } else if (set1->nodeNr >= set1->nodeMax) {
		xmlNodePtr *temp;

		set1->nodeMax *= 2;
		temp = (xmlNodePtr *) xmlRealloc(
		    set1->nodeTab, set1->nodeMax * sizeof(xmlNodePtr));
		if (temp == NULL) {
		    xmlXPathErrMemory(NULL, "merging nodeset\n");
		    return(NULL);
		}
		set1->nodeTab = temp;
	    }
	    if (n2->type == XML_NAMESPACE_DECL) {
		xmlNsPtr ns = (xmlNsPtr) n2;

		set1->nodeTab[set1->nodeNr++] =
		    xmlXPathNodeSetDupNs((xmlNodePtr) ns->next, ns);
	    } else
		set1->nodeTab[set1->nodeNr++] = n2;
skip_node:
	    {}
	}
    }
    set2->nodeNr = 0;
    return(set1);
}

/**
 * xmlXPathNodeSetMergeAndClearNoDupls:
 * @set1:  the first NodeSet or NULL
 * @set2:  the second NodeSet
 * @hasSet2NsNodes: 1 if set2 contains namespaces nodes
 *
 * Merges two nodesets, all nodes from @set2 are added to @set1
 * if @set1 is NULL, a new set is created and copied from @set2.
 * Doesn't chack for duplicate nodes. Clears set2.
 *
 * Returns @set1 once extended or NULL in case of error.
 */
static xmlNodeSetPtr
xmlXPathNodeSetMergeAndClearNoDupls(xmlNodeSetPtr set1, xmlNodeSetPtr set2,
				    int hasNullEntries)
{
    if (set2 == NULL)
	return(set1);
    if ((set1 == NULL) && (hasNullEntries == 0)) {
	/*
	* Note that doing a memcpy of the list, namespace nodes are
	* just assigned to set1, since set2 is cleared anyway.
	*/
	set1 = xmlXPathNodeSetCreateSize(set2->nodeNr);
	if (set1 == NULL)
	    return(NULL);
	if (set2->nodeNr != 0) {
	    memcpy(set1->nodeTab, set2->nodeTab,
		set2->nodeNr * sizeof(xmlNodePtr));
	    set1->nodeNr = set2->nodeNr;
	}
    } else {
	int i;
	xmlNodePtr n2;

	if (set1 == NULL)
	    set1 = xmlXPathNodeSetCreate(NULL);
        if (set1 == NULL)
            return (NULL);

	for (i = 0;i < set2->nodeNr;i++) {
	    n2 = set2->nodeTab[i];
	    /*
	    * Skip NULLed entries.
	    */
	    if (n2 == NULL)
		continue;
	    if (set1->nodeMax == 0) {
		set1->nodeTab = (xmlNodePtr *) xmlMalloc(
		    XML_NODESET_DEFAULT * sizeof(xmlNodePtr));
		if (set1->nodeTab == NULL) {
		    xmlXPathErrMemory(NULL, "merging nodeset\n");
		    return(NULL);
		}
		memset(set1->nodeTab, 0,
		    XML_NODESET_DEFAULT * (size_t) sizeof(xmlNodePtr));
		set1->nodeMax = XML_NODESET_DEFAULT;
	    } else if (set1->nodeNr >= set1->nodeMax) {
		xmlNodePtr *temp;

		set1->nodeMax *= 2;
		temp = (xmlNodePtr *) xmlRealloc(
		    set1->nodeTab, set1->nodeMax * sizeof(xmlNodePtr));
		if (temp == NULL) {
		    xmlXPathErrMemory(NULL, "merging nodeset\n");
		    return(NULL);
		}
		set1->nodeTab = temp;
	    }
	    set1->nodeTab[set1->nodeNr++] = n2;
	}
    }
    set2->nodeNr = 0;
    return(set1);
}

/**
 * xmlXPathNodeSetDel:
 * @cur:  the initial node set
 * @val:  an xmlNodePtr
 *
 * Removes an xmlNodePtr from an existing NodeSet
 */
void
xmlXPathNodeSetDel(xmlNodeSetPtr cur, xmlNodePtr val) {
    int i;

    if (cur == NULL) return;
    if (val == NULL) return;

    /*
     * find node in nodeTab
     */
    for (i = 0;i < cur->nodeNr;i++)
        if (cur->nodeTab[i] == val) break;

    if (i >= cur->nodeNr) {	/* not found */
#ifdef DEBUG
        xmlGenericError(xmlGenericErrorContext,
	        "xmlXPathNodeSetDel: Node %s wasn't found in NodeList\n",
		val->name);
#endif
        return;
    }
    if ((cur->nodeTab[i] != NULL) &&
	(cur->nodeTab[i]->type == XML_NAMESPACE_DECL))
	xmlXPathNodeSetFreeNs((xmlNsPtr) cur->nodeTab[i]);
    cur->nodeNr--;
    for (;i < cur->nodeNr;i++)
        cur->nodeTab[i] = cur->nodeTab[i + 1];
    cur->nodeTab[cur->nodeNr] = NULL;
}

/**
 * xmlXPathNodeSetRemove:
 * @cur:  the initial node set
 * @val:  the index to remove
 *
 * Removes an entry from an existing NodeSet list.
 */
void
xmlXPathNodeSetRemove(xmlNodeSetPtr cur, int val) {
    if (cur == NULL) return;
    if (val >= cur->nodeNr) return;
    if ((cur->nodeTab[val] != NULL) &&
	(cur->nodeTab[val]->type == XML_NAMESPACE_DECL))
	xmlXPathNodeSetFreeNs((xmlNsPtr) cur->nodeTab[val]);
    cur->nodeNr--;
    for (;val < cur->nodeNr;val++)
        cur->nodeTab[val] = cur->nodeTab[val + 1];
    cur->nodeTab[cur->nodeNr] = NULL;
}

/**
 * xmlXPathFreeNodeSet:
 * @obj:  the xmlNodeSetPtr to free
 *
 * Free the NodeSet compound (not the actual nodes !).
 */
void
xmlXPathFreeNodeSet(xmlNodeSetPtr obj) {
    if (obj == NULL) return;
    if (obj->nodeTab != NULL) {
	int i;

	/* @@ with_ns to check whether namespace nodes should be looked at @@ */
	for (i = 0;i < obj->nodeNr;i++)
	    if ((obj->nodeTab[i] != NULL) &&
		(obj->nodeTab[i]->type == XML_NAMESPACE_DECL))
		xmlXPathNodeSetFreeNs((xmlNsPtr) obj->nodeTab[i]);
	xmlFree(obj->nodeTab);
    }
    xmlFree(obj);
}

/**
 * xmlXPathNodeSetClear:
 * @set:  the node set to clear
 *
 * Clears the list from all temporary XPath objects (e.g. namespace nodes
 * are feed), but does *not* free the list itself. Sets the length of the
 * list to 0.
 */
static void
xmlXPathNodeSetClear(xmlNodeSetPtr set, int hasNsNodes)
{
    if ((set == NULL) || (set->nodeNr <= 0))
	return;
    else if (hasNsNodes) {
	int i;
	xmlNodePtr node;

	for (i = 0; i < set->nodeNr; i++) {
	    node = set->nodeTab[i];
	    if ((node != NULL) &&
		(node->type == XML_NAMESPACE_DECL))
		xmlXPathNodeSetFreeNs((xmlNsPtr) node);
	}
    }
    set->nodeNr = 0;
}

/**
 * xmlXPathNodeSetClearFromPos:
 * @set: the node set to be cleared
 * @pos: the start position to clear from
 *
 * Clears the list from temporary XPath objects (e.g. namespace nodes
 * are feed) starting with the entry at @pos, but does *not* free the list
 * itself. Sets the length of the list to @pos.
 */
static void
xmlXPathNodeSetClearFromPos(xmlNodeSetPtr set, int pos, int hasNsNodes)
{
    if ((set == NULL) || (set->nodeNr <= 0) || (pos >= set->nodeNr))
	return;
    else if ((hasNsNodes)) {
	int i;
	xmlNodePtr node;

	for (i = pos; i < set->nodeNr; i++) {
	    node = set->nodeTab[i];
	    if ((node != NULL) &&
		(node->type == XML_NAMESPACE_DECL))
		xmlXPathNodeSetFreeNs((xmlNsPtr) node);
	}
    }
    set->nodeNr = pos;
}

/**
 * xmlXPathFreeValueTree:
 * @obj:  the xmlNodeSetPtr to free
 *
 * Free the NodeSet compound and the actual tree, this is different
 * from xmlXPathFreeNodeSet()
 */
static void
xmlXPathFreeValueTree(xmlNodeSetPtr obj) {
    int i;

    if (obj == NULL) return;

    if (obj->nodeTab != NULL) {
	for (i = 0;i < obj->nodeNr;i++) {
	    if (obj->nodeTab[i] != NULL) {
		if (obj->nodeTab[i]->type == XML_NAMESPACE_DECL) {
		    xmlXPathNodeSetFreeNs((xmlNsPtr) obj->nodeTab[i]);
		} else {
		    xmlFreeNodeList(obj->nodeTab[i]);
		}
	    }
	}
	xmlFree(obj->nodeTab);
    }
    xmlFree(obj);
}

#if defined(DEBUG) || defined(DEBUG_STEP)
/**
 * xmlGenericErrorContextNodeSet:
 * @output:  a FILE * for the output
 * @obj:  the xmlNodeSetPtr to display
 *
 * Quick display of a NodeSet
 */
void
xmlGenericErrorContextNodeSet(FILE *output, xmlNodeSetPtr obj) {
    int i;

    if (output == NULL) output = xmlGenericErrorContext;
    if (obj == NULL)  {
        fprintf(output, "NodeSet == NULL !\n");
	return;
    }
    if (obj->nodeNr == 0) {
        fprintf(output, "NodeSet is empty\n");
	return;
    }
    if (obj->nodeTab == NULL) {
	fprintf(output, " nodeTab == NULL !\n");
	return;
    }
    for (i = 0; i < obj->nodeNr; i++) {
        if (obj->nodeTab[i] == NULL) {
	    fprintf(output, " NULL !\n");
	    return;
        }
	if ((obj->nodeTab[i]->type == XML_DOCUMENT_NODE) ||
	    (obj->nodeTab[i]->type == XML_HTML_DOCUMENT_NODE))
	    fprintf(output, " /");
	else if (obj->nodeTab[i]->name == NULL)
	    fprintf(output, " noname!");
	else fprintf(output, " %s", obj->nodeTab[i]->name);
    }
    fprintf(output, "\n");
}
#endif

/**
 * xmlXPathNewNodeSet:
 * @val:  the NodePtr value
 *
 * Create a new xmlXPathObjectPtr of type NodeSet and initialize
 * it with the single Node @val
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathNewNodeSet(xmlNodePtr val) {
    xmlXPathObjectPtr ret;

    ret = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating nodeset\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathObject));
    ret->type = XPATH_NODESET;
    ret->boolval = 0;
    ret->nodesetval = xmlXPathNodeSetCreate(val);
    /* @@ with_ns to check whether namespace nodes should be looked at @@ */
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageRequested(NULL, XPATH_NODESET);
#endif
    return(ret);
}

/**
 * xmlXPathNewValueTree:
 * @val:  the NodePtr value
 *
 * Create a new xmlXPathObjectPtr of type Value Tree (XSLT) and initialize
 * it with the tree root @val
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathNewValueTree(xmlNodePtr val) {
    xmlXPathObjectPtr ret;

    ret = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating result value tree\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathObject));
    ret->type = XPATH_XSLT_TREE;
    ret->boolval = 1;
    ret->user = (void *) val;
    ret->nodesetval = xmlXPathNodeSetCreate(val);
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageRequested(NULL, XPATH_XSLT_TREE);
#endif
    return(ret);
}

/**
 * xmlXPathNewNodeSetList:
 * @val:  an existing NodeSet
 *
 * Create a new xmlXPathObjectPtr of type NodeSet and initialize
 * it with the Nodeset @val
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathNewNodeSetList(xmlNodeSetPtr val)
{
    xmlXPathObjectPtr ret;
    int i;

    if (val == NULL)
        ret = NULL;
    else if (val->nodeTab == NULL)
        ret = xmlXPathNewNodeSet(NULL);
    else {
        ret = xmlXPathNewNodeSet(val->nodeTab[0]);
        if (ret)
            for (i = 1; i < val->nodeNr; ++i)
                xmlXPathNodeSetAddUnique(ret->nodesetval, val->nodeTab[i]);
    }

    return (ret);
}

/**
 * xmlXPathWrapNodeSet:
 * @val:  the NodePtr value
 *
 * Wrap the Nodeset @val in a new xmlXPathObjectPtr
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathWrapNodeSet(xmlNodeSetPtr val) {
    xmlXPathObjectPtr ret;

    ret = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating node set object\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathObject));
    ret->type = XPATH_NODESET;
    ret->nodesetval = val;
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageRequested(NULL, XPATH_NODESET);
#endif
    return(ret);
}

/**
 * xmlXPathFreeNodeSetList:
 * @obj:  an existing NodeSetList object
 *
 * Free up the xmlXPathObjectPtr @obj but don't deallocate the objects in
 * the list contrary to xmlXPathFreeObject().
 */
void
xmlXPathFreeNodeSetList(xmlXPathObjectPtr obj) {
    if (obj == NULL) return;
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageReleased(NULL, obj->type);
#endif
    xmlFree(obj);
}

/**
 * xmlXPathDifference:
 * @nodes1:  a node-set
 * @nodes2:  a node-set
 *
 * Implements the EXSLT - Sets difference() function:
 *    node-set set:difference (node-set, node-set)
 *
 * Returns the difference between the two node sets, or nodes1 if
 *         nodes2 is empty
 */
xmlNodeSetPtr
xmlXPathDifference (xmlNodeSetPtr nodes1, xmlNodeSetPtr nodes2) {
    xmlNodeSetPtr ret;
    int i, l1;
    xmlNodePtr cur;

    if (xmlXPathNodeSetIsEmpty(nodes2))
	return(nodes1);

    ret = xmlXPathNodeSetCreate(NULL);
    if (xmlXPathNodeSetIsEmpty(nodes1))
	return(ret);

    l1 = xmlXPathNodeSetGetLength(nodes1);

    for (i = 0; i < l1; i++) {
	cur = xmlXPathNodeSetItem(nodes1, i);
	if (!xmlXPathNodeSetContains(nodes2, cur))
	    xmlXPathNodeSetAddUnique(ret, cur);
    }
    return(ret);
}

/**
 * xmlXPathIntersection:
 * @nodes1:  a node-set
 * @nodes2:  a node-set
 *
 * Implements the EXSLT - Sets intersection() function:
 *    node-set set:intersection (node-set, node-set)
 *
 * Returns a node set comprising the nodes that are within both the
 *         node sets passed as arguments
 */
xmlNodeSetPtr
xmlXPathIntersection (xmlNodeSetPtr nodes1, xmlNodeSetPtr nodes2) {
    xmlNodeSetPtr ret = xmlXPathNodeSetCreate(NULL);
    int i, l1;
    xmlNodePtr cur;

    if (ret == NULL)
        return(ret);
    if (xmlXPathNodeSetIsEmpty(nodes1))
	return(ret);
    if (xmlXPathNodeSetIsEmpty(nodes2))
	return(ret);

    l1 = xmlXPathNodeSetGetLength(nodes1);

    for (i = 0; i < l1; i++) {
	cur = xmlXPathNodeSetItem(nodes1, i);
	if (xmlXPathNodeSetContains(nodes2, cur))
	    xmlXPathNodeSetAddUnique(ret, cur);
    }
    return(ret);
}

/**
 * xmlXPathDistinctSorted:
 * @nodes:  a node-set, sorted by document order
 *
 * Implements the EXSLT - Sets distinct() function:
 *    node-set set:distinct (node-set)
 *
 * Returns a subset of the nodes contained in @nodes, or @nodes if
 *         it is empty
 */
xmlNodeSetPtr
xmlXPathDistinctSorted (xmlNodeSetPtr nodes) {
    xmlNodeSetPtr ret;
    xmlHashTablePtr hash;
    int i, l;
    xmlChar * strval;
    xmlNodePtr cur;

    if (xmlXPathNodeSetIsEmpty(nodes))
	return(nodes);

    ret = xmlXPathNodeSetCreate(NULL);
    if (ret == NULL)
        return(ret);
    l = xmlXPathNodeSetGetLength(nodes);
    hash = xmlHashCreate (l);
    for (i = 0; i < l; i++) {
	cur = xmlXPathNodeSetItem(nodes, i);
	strval = xmlXPathCastNodeToString(cur);
	if (xmlHashLookup(hash, strval) == NULL) {
	    xmlHashAddEntry(hash, strval, strval);
	    xmlXPathNodeSetAddUnique(ret, cur);
	} else {
	    xmlFree(strval);
	}
    }
    xmlHashFree(hash, (xmlHashDeallocator) xmlFree);
    return(ret);
}

/**
 * xmlXPathDistinct:
 * @nodes:  a node-set
 *
 * Implements the EXSLT - Sets distinct() function:
 *    node-set set:distinct (node-set)
 * @nodes is sorted by document order, then #exslSetsDistinctSorted
 * is called with the sorted node-set
 *
 * Returns a subset of the nodes contained in @nodes, or @nodes if
 *         it is empty
 */
xmlNodeSetPtr
xmlXPathDistinct (xmlNodeSetPtr nodes) {
    if (xmlXPathNodeSetIsEmpty(nodes))
	return(nodes);

    xmlXPathNodeSetSort(nodes);
    return(xmlXPathDistinctSorted(nodes));
}

/**
 * xmlXPathHasSameNodes:
 * @nodes1:  a node-set
 * @nodes2:  a node-set
 *
 * Implements the EXSLT - Sets has-same-nodes function:
 *    boolean set:has-same-node(node-set, node-set)
 *
 * Returns true (1) if @nodes1 shares any node with @nodes2, false (0)
 *         otherwise
 */
int
xmlXPathHasSameNodes (xmlNodeSetPtr nodes1, xmlNodeSetPtr nodes2) {
    int i, l;
    xmlNodePtr cur;

    if (xmlXPathNodeSetIsEmpty(nodes1) ||
	xmlXPathNodeSetIsEmpty(nodes2))
	return(0);

    l = xmlXPathNodeSetGetLength(nodes1);
    for (i = 0; i < l; i++) {
	cur = xmlXPathNodeSetItem(nodes1, i);
	if (xmlXPathNodeSetContains(nodes2, cur))
	    return(1);
    }
    return(0);
}

/**
 * xmlXPathNodeLeadingSorted:
 * @nodes: a node-set, sorted by document order
 * @node: a node
 *
 * Implements the EXSLT - Sets leading() function:
 *    node-set set:leading (node-set, node-set)
 *
 * Returns the nodes in @nodes that precede @node in document order,
 *         @nodes if @node is NULL or an empty node-set if @nodes
 *         doesn't contain @node
 */
xmlNodeSetPtr
xmlXPathNodeLeadingSorted (xmlNodeSetPtr nodes, xmlNodePtr node) {
    int i, l;
    xmlNodePtr cur;
    xmlNodeSetPtr ret;

    if (node == NULL)
	return(nodes);

    ret = xmlXPathNodeSetCreate(NULL);
    if (ret == NULL)
        return(ret);
    if (xmlXPathNodeSetIsEmpty(nodes) ||
	(!xmlXPathNodeSetContains(nodes, node)))
	return(ret);

    l = xmlXPathNodeSetGetLength(nodes);
    for (i = 0; i < l; i++) {
	cur = xmlXPathNodeSetItem(nodes, i);
	if (cur == node)
	    break;
	xmlXPathNodeSetAddUnique(ret, cur);
    }
    return(ret);
}

/**
 * xmlXPathNodeLeading:
 * @nodes:  a node-set
 * @node:  a node
 *
 * Implements the EXSLT - Sets leading() function:
 *    node-set set:leading (node-set, node-set)
 * @nodes is sorted by document order, then #exslSetsNodeLeadingSorted
 * is called.
 *
 * Returns the nodes in @nodes that precede @node in document order,
 *         @nodes if @node is NULL or an empty node-set if @nodes
 *         doesn't contain @node
 */
xmlNodeSetPtr
xmlXPathNodeLeading (xmlNodeSetPtr nodes, xmlNodePtr node) {
    xmlXPathNodeSetSort(nodes);
    return(xmlXPathNodeLeadingSorted(nodes, node));
}

/**
 * xmlXPathLeadingSorted:
 * @nodes1:  a node-set, sorted by document order
 * @nodes2:  a node-set, sorted by document order
 *
 * Implements the EXSLT - Sets leading() function:
 *    node-set set:leading (node-set, node-set)
 *
 * Returns the nodes in @nodes1 that precede the first node in @nodes2
 *         in document order, @nodes1 if @nodes2 is NULL or empty or
 *         an empty node-set if @nodes1 doesn't contain @nodes2
 */
xmlNodeSetPtr
xmlXPathLeadingSorted (xmlNodeSetPtr nodes1, xmlNodeSetPtr nodes2) {
    if (xmlXPathNodeSetIsEmpty(nodes2))
	return(nodes1);
    return(xmlXPathNodeLeadingSorted(nodes1,
				     xmlXPathNodeSetItem(nodes2, 1)));
}

/**
 * xmlXPathLeading:
 * @nodes1:  a node-set
 * @nodes2:  a node-set
 *
 * Implements the EXSLT - Sets leading() function:
 *    node-set set:leading (node-set, node-set)
 * @nodes1 and @nodes2 are sorted by document order, then
 * #exslSetsLeadingSorted is called.
 *
 * Returns the nodes in @nodes1 that precede the first node in @nodes2
 *         in document order, @nodes1 if @nodes2 is NULL or empty or
 *         an empty node-set if @nodes1 doesn't contain @nodes2
 */
xmlNodeSetPtr
xmlXPathLeading (xmlNodeSetPtr nodes1, xmlNodeSetPtr nodes2) {
    if (xmlXPathNodeSetIsEmpty(nodes2))
	return(nodes1);
    if (xmlXPathNodeSetIsEmpty(nodes1))
	return(xmlXPathNodeSetCreate(NULL));
    xmlXPathNodeSetSort(nodes1);
    xmlXPathNodeSetSort(nodes2);
    return(xmlXPathNodeLeadingSorted(nodes1,
				     xmlXPathNodeSetItem(nodes2, 1)));
}

/**
 * xmlXPathNodeTrailingSorted:
 * @nodes: a node-set, sorted by document order
 * @node: a node
 *
 * Implements the EXSLT - Sets trailing() function:
 *    node-set set:trailing (node-set, node-set)
 *
 * Returns the nodes in @nodes that follow @node in document order,
 *         @nodes if @node is NULL or an empty node-set if @nodes
 *         doesn't contain @node
 */
xmlNodeSetPtr
xmlXPathNodeTrailingSorted (xmlNodeSetPtr nodes, xmlNodePtr node) {
    int i, l;
    xmlNodePtr cur;
    xmlNodeSetPtr ret;

    if (node == NULL)
	return(nodes);

    ret = xmlXPathNodeSetCreate(NULL);
    if (ret == NULL)
        return(ret);
    if (xmlXPathNodeSetIsEmpty(nodes) ||
	(!xmlXPathNodeSetContains(nodes, node)))
	return(ret);

    l = xmlXPathNodeSetGetLength(nodes);
    for (i = l - 1; i >= 0; i--) {
	cur = xmlXPathNodeSetItem(nodes, i);
	if (cur == node)
	    break;
	xmlXPathNodeSetAddUnique(ret, cur);
    }
    xmlXPathNodeSetSort(ret);	/* bug 413451 */
    return(ret);
}

/**
 * xmlXPathNodeTrailing:
 * @nodes:  a node-set
 * @node:  a node
 *
 * Implements the EXSLT - Sets trailing() function:
 *    node-set set:trailing (node-set, node-set)
 * @nodes is sorted by document order, then #xmlXPathNodeTrailingSorted
 * is called.
 *
 * Returns the nodes in @nodes that follow @node in document order,
 *         @nodes if @node is NULL or an empty node-set if @nodes
 *         doesn't contain @node
 */
xmlNodeSetPtr
xmlXPathNodeTrailing (xmlNodeSetPtr nodes, xmlNodePtr node) {
    xmlXPathNodeSetSort(nodes);
    return(xmlXPathNodeTrailingSorted(nodes, node));
}

/**
 * xmlXPathTrailingSorted:
 * @nodes1:  a node-set, sorted by document order
 * @nodes2:  a node-set, sorted by document order
 *
 * Implements the EXSLT - Sets trailing() function:
 *    node-set set:trailing (node-set, node-set)
 *
 * Returns the nodes in @nodes1 that follow the first node in @nodes2
 *         in document order, @nodes1 if @nodes2 is NULL or empty or
 *         an empty node-set if @nodes1 doesn't contain @nodes2
 */
xmlNodeSetPtr
xmlXPathTrailingSorted (xmlNodeSetPtr nodes1, xmlNodeSetPtr nodes2) {
    if (xmlXPathNodeSetIsEmpty(nodes2))
	return(nodes1);
    return(xmlXPathNodeTrailingSorted(nodes1,
				      xmlXPathNodeSetItem(nodes2, 0)));
}

/**
 * xmlXPathTrailing:
 * @nodes1:  a node-set
 * @nodes2:  a node-set
 *
 * Implements the EXSLT - Sets trailing() function:
 *    node-set set:trailing (node-set, node-set)
 * @nodes1 and @nodes2 are sorted by document order, then
 * #xmlXPathTrailingSorted is called.
 *
 * Returns the nodes in @nodes1 that follow the first node in @nodes2
 *         in document order, @nodes1 if @nodes2 is NULL or empty or
 *         an empty node-set if @nodes1 doesn't contain @nodes2
 */
xmlNodeSetPtr
xmlXPathTrailing (xmlNodeSetPtr nodes1, xmlNodeSetPtr nodes2) {
    if (xmlXPathNodeSetIsEmpty(nodes2))
	return(nodes1);
    if (xmlXPathNodeSetIsEmpty(nodes1))
	return(xmlXPathNodeSetCreate(NULL));
    xmlXPathNodeSetSort(nodes1);
    xmlXPathNodeSetSort(nodes2);
    return(xmlXPathNodeTrailingSorted(nodes1,
				      xmlXPathNodeSetItem(nodes2, 0)));
}

/************************************************************************
 *									*
 *		Routines to handle extra functions			*
 *									*
 ************************************************************************/

/**
 * xmlXPathRegisterFunc:
 * @ctxt:  the XPath context
 * @name:  the function name
 * @f:  the function implementation or NULL
 *
 * Register a new function. If @f is NULL it unregisters the function
 *
 * Returns 0 in case of success, -1 in case of error
 */
int
xmlXPathRegisterFunc(xmlXPathContextPtr ctxt, const xmlChar *name,
		     xmlXPathFunction f) {
    return(xmlXPathRegisterFuncNS(ctxt, name, NULL, f));
}

/**
 * xmlXPathRegisterFuncNS:
 * @ctxt:  the XPath context
 * @name:  the function name
 * @ns_uri:  the function namespace URI
 * @f:  the function implementation or NULL
 *
 * Register a new function. If @f is NULL it unregisters the function
 *
 * Returns 0 in case of success, -1 in case of error
 */
int
xmlXPathRegisterFuncNS(xmlXPathContextPtr ctxt, const xmlChar *name,
		       const xmlChar *ns_uri, xmlXPathFunction f) {
    if (ctxt == NULL)
	return(-1);
    if (name == NULL)
	return(-1);

    if (ctxt->funcHash == NULL)
	ctxt->funcHash = xmlHashCreate(0);
    if (ctxt->funcHash == NULL)
	return(-1);
    if (f == NULL)
        return(xmlHashRemoveEntry2(ctxt->funcHash, name, ns_uri, NULL));
    return(xmlHashAddEntry2(ctxt->funcHash, name, ns_uri, XML_CAST_FPTR(f)));
}

/**
 * xmlXPathRegisterFuncLookup:
 * @ctxt:  the XPath context
 * @f:  the lookup function
 * @funcCtxt:  the lookup data
 *
 * Registers an external mechanism to do function lookup.
 */
void
xmlXPathRegisterFuncLookup (xmlXPathContextPtr ctxt,
			    xmlXPathFuncLookupFunc f,
			    void *funcCtxt) {
    if (ctxt == NULL)
	return;
    ctxt->funcLookupFunc = f;
    ctxt->funcLookupData = funcCtxt;
}

/**
 * xmlXPathFunctionLookup:
 * @ctxt:  the XPath context
 * @name:  the function name
 *
 * Search in the Function array of the context for the given
 * function.
 *
 * Returns the xmlXPathFunction or NULL if not found
 */
xmlXPathFunction
xmlXPathFunctionLookup(xmlXPathContextPtr ctxt, const xmlChar *name) {
    if (ctxt == NULL)
	return (NULL);

    if (ctxt->funcLookupFunc != NULL) {
	xmlXPathFunction ret;
	xmlXPathFuncLookupFunc f;

	f = ctxt->funcLookupFunc;
	ret = f(ctxt->funcLookupData, name, NULL);
	if (ret != NULL)
	    return(ret);
    }
    return(xmlXPathFunctionLookupNS(ctxt, name, NULL));
}

/**
 * xmlXPathFunctionLookupNS:
 * @ctxt:  the XPath context
 * @name:  the function name
 * @ns_uri:  the function namespace URI
 *
 * Search in the Function array of the context for the given
 * function.
 *
 * Returns the xmlXPathFunction or NULL if not found
 */
xmlXPathFunction
xmlXPathFunctionLookupNS(xmlXPathContextPtr ctxt, const xmlChar *name,
			 const xmlChar *ns_uri) {
    xmlXPathFunction ret;

    if (ctxt == NULL)
	return(NULL);
    if (name == NULL)
	return(NULL);

    if (ctxt->funcLookupFunc != NULL) {
	xmlXPathFuncLookupFunc f;

	f = ctxt->funcLookupFunc;
	ret = f(ctxt->funcLookupData, name, ns_uri);
	if (ret != NULL)
	    return(ret);
    }

    if (ctxt->funcHash == NULL)
	return(NULL);

    XML_CAST_FPTR(ret) = xmlHashLookup2(ctxt->funcHash, name, ns_uri);
    return(ret);
}

/**
 * xmlXPathRegisteredFuncsCleanup:
 * @ctxt:  the XPath context
 *
 * Cleanup the XPath context data associated to registered functions
 */
void
xmlXPathRegisteredFuncsCleanup(xmlXPathContextPtr ctxt) {
    if (ctxt == NULL)
	return;

    xmlHashFree(ctxt->funcHash, NULL);
    ctxt->funcHash = NULL;
}

/************************************************************************
 *									*
 *			Routines to handle Variables			*
 *									*
 ************************************************************************/

/**
 * xmlXPathRegisterVariable:
 * @ctxt:  the XPath context
 * @name:  the variable name
 * @value:  the variable value or NULL
 *
 * Register a new variable value. If @value is NULL it unregisters
 * the variable
 *
 * Returns 0 in case of success, -1 in case of error
 */
int
xmlXPathRegisterVariable(xmlXPathContextPtr ctxt, const xmlChar *name,
			 xmlXPathObjectPtr value) {
    return(xmlXPathRegisterVariableNS(ctxt, name, NULL, value));
}

/**
 * xmlXPathRegisterVariableNS:
 * @ctxt:  the XPath context
 * @name:  the variable name
 * @ns_uri:  the variable namespace URI
 * @value:  the variable value or NULL
 *
 * Register a new variable value. If @value is NULL it unregisters
 * the variable
 *
 * Returns 0 in case of success, -1 in case of error
 */
int
xmlXPathRegisterVariableNS(xmlXPathContextPtr ctxt, const xmlChar *name,
			   const xmlChar *ns_uri,
			   xmlXPathObjectPtr value) {
    if (ctxt == NULL)
	return(-1);
    if (name == NULL)
	return(-1);

    if (ctxt->varHash == NULL)
	ctxt->varHash = xmlHashCreate(0);
    if (ctxt->varHash == NULL)
	return(-1);
    if (value == NULL)
        return(xmlHashRemoveEntry2(ctxt->varHash, name, ns_uri,
	                           (xmlHashDeallocator)xmlXPathFreeObject));
    return(xmlHashUpdateEntry2(ctxt->varHash, name, ns_uri,
			       (void *) value,
			       (xmlHashDeallocator)xmlXPathFreeObject));
}

/**
 * xmlXPathRegisterVariableLookup:
 * @ctxt:  the XPath context
 * @f:  the lookup function
 * @data:  the lookup data
 *
 * register an external mechanism to do variable lookup
 */
void
xmlXPathRegisterVariableLookup(xmlXPathContextPtr ctxt,
	 xmlXPathVariableLookupFunc f, void *data) {
    if (ctxt == NULL)
	return;
    ctxt->varLookupFunc = f;
    ctxt->varLookupData = data;
}

/**
 * xmlXPathVariableLookup:
 * @ctxt:  the XPath context
 * @name:  the variable name
 *
 * Search in the Variable array of the context for the given
 * variable value.
 *
 * Returns a copy of the value or NULL if not found
 */
xmlXPathObjectPtr
xmlXPathVariableLookup(xmlXPathContextPtr ctxt, const xmlChar *name) {
    if (ctxt == NULL)
	return(NULL);

    if (ctxt->varLookupFunc != NULL) {
	xmlXPathObjectPtr ret;

	ret = ((xmlXPathVariableLookupFunc)ctxt->varLookupFunc)
	        (ctxt->varLookupData, name, NULL);
	return(ret);
    }
    return(xmlXPathVariableLookupNS(ctxt, name, NULL));
}

/**
 * xmlXPathVariableLookupNS:
 * @ctxt:  the XPath context
 * @name:  the variable name
 * @ns_uri:  the variable namespace URI
 *
 * Search in the Variable array of the context for the given
 * variable value.
 *
 * Returns the a copy of the value or NULL if not found
 */
xmlXPathObjectPtr
xmlXPathVariableLookupNS(xmlXPathContextPtr ctxt, const xmlChar *name,
			 const xmlChar *ns_uri) {
    if (ctxt == NULL)
	return(NULL);

    if (ctxt->varLookupFunc != NULL) {
	xmlXPathObjectPtr ret;

	ret = ((xmlXPathVariableLookupFunc)ctxt->varLookupFunc)
	        (ctxt->varLookupData, name, ns_uri);
	if (ret != NULL) return(ret);
    }

    if (ctxt->varHash == NULL)
	return(NULL);
    if (name == NULL)
	return(NULL);

    return(xmlXPathCacheObjectCopy(ctxt, (xmlXPathObjectPtr)
		xmlHashLookup2(ctxt->varHash, name, ns_uri)));
}

/**
 * xmlXPathRegisteredVariablesCleanup:
 * @ctxt:  the XPath context
 *
 * Cleanup the XPath context data associated to registered variables
 */
void
xmlXPathRegisteredVariablesCleanup(xmlXPathContextPtr ctxt) {
    if (ctxt == NULL)
	return;

    xmlHashFree(ctxt->varHash, (xmlHashDeallocator)xmlXPathFreeObject);
    ctxt->varHash = NULL;
}

/**
 * xmlXPathRegisterNs:
 * @ctxt:  the XPath context
 * @prefix:  the namespace prefix cannot be NULL or empty string
 * @ns_uri:  the namespace name
 *
 * Register a new namespace. If @ns_uri is NULL it unregisters
 * the namespace
 *
 * Returns 0 in case of success, -1 in case of error
 */
int
xmlXPathRegisterNs(xmlXPathContextPtr ctxt, const xmlChar *prefix,
			   const xmlChar *ns_uri) {
    if (ctxt == NULL)
	return(-1);
    if (prefix == NULL)
	return(-1);
    if (prefix[0] == 0)
	return(-1);

    if (ctxt->nsHash == NULL)
	ctxt->nsHash = xmlHashCreate(10);
    if (ctxt->nsHash == NULL)
	return(-1);
    if (ns_uri == NULL)
        return(xmlHashRemoveEntry(ctxt->nsHash, prefix,
	                          (xmlHashDeallocator)xmlFree));
    return(xmlHashUpdateEntry(ctxt->nsHash, prefix, (void *) xmlStrdup(ns_uri),
			      (xmlHashDeallocator)xmlFree));
}

/**
 * xmlXPathNsLookup:
 * @ctxt:  the XPath context
 * @prefix:  the namespace prefix value
 *
 * Search in the namespace declaration array of the context for the given
 * namespace name associated to the given prefix
 *
 * Returns the value or NULL if not found
 */
const xmlChar *
xmlXPathNsLookup(xmlXPathContextPtr ctxt, const xmlChar *prefix) {
    if (ctxt == NULL)
	return(NULL);
    if (prefix == NULL)
	return(NULL);

#ifdef XML_XML_NAMESPACE
    if (xmlStrEqual(prefix, (const xmlChar *) "xml"))
	return(XML_XML_NAMESPACE);
#endif

    if (ctxt->namespaces != NULL) {
	int i;

	for (i = 0;i < ctxt->nsNr;i++) {
	    if ((ctxt->namespaces[i] != NULL) &&
		(xmlStrEqual(ctxt->namespaces[i]->prefix, prefix)))
		return(ctxt->namespaces[i]->href);
	}
    }

    return((const xmlChar *) xmlHashLookup(ctxt->nsHash, prefix));
}

/**
 * xmlXPathRegisteredNsCleanup:
 * @ctxt:  the XPath context
 *
 * Cleanup the XPath context data associated to registered variables
 */
void
xmlXPathRegisteredNsCleanup(xmlXPathContextPtr ctxt) {
    if (ctxt == NULL)
	return;

    xmlHashFree(ctxt->nsHash, (xmlHashDeallocator)xmlFree);
    ctxt->nsHash = NULL;
}

/************************************************************************
 *									*
 *			Routines to handle Values			*
 *									*
 ************************************************************************/

/* Allocations are terrible, one needs to optimize all this !!! */

/**
 * xmlXPathNewFloat:
 * @val:  the double value
 *
 * Create a new xmlXPathObjectPtr of type double and of value @val
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathNewFloat(double val) {
    xmlXPathObjectPtr ret;

    ret = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating float object\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathObject));
    ret->type = XPATH_NUMBER;
    ret->floatval = val;
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageRequested(NULL, XPATH_NUMBER);
#endif
    return(ret);
}

/**
 * xmlXPathNewBoolean:
 * @val:  the boolean value
 *
 * Create a new xmlXPathObjectPtr of type boolean and of value @val
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathNewBoolean(int val) {
    xmlXPathObjectPtr ret;

    ret = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating boolean object\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathObject));
    ret->type = XPATH_BOOLEAN;
    ret->boolval = (val != 0);
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageRequested(NULL, XPATH_BOOLEAN);
#endif
    return(ret);
}

/**
 * xmlXPathNewString:
 * @val:  the xmlChar * value
 *
 * Create a new xmlXPathObjectPtr of type string and of value @val
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathNewString(const xmlChar *val) {
    xmlXPathObjectPtr ret;

    ret = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating string object\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathObject));
    ret->type = XPATH_STRING;
    if (val != NULL)
	ret->stringval = xmlStrdup(val);
    else
	ret->stringval = xmlStrdup((const xmlChar *)"");
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageRequested(NULL, XPATH_STRING);
#endif
    return(ret);
}

/**
 * xmlXPathWrapString:
 * @val:  the xmlChar * value
 *
 * Wraps the @val string into an XPath object.
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathWrapString (xmlChar *val) {
    xmlXPathObjectPtr ret;

    ret = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating string object\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathObject));
    ret->type = XPATH_STRING;
    ret->stringval = val;
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageRequested(NULL, XPATH_STRING);
#endif
    return(ret);
}

/**
 * xmlXPathNewCString:
 * @val:  the char * value
 *
 * Create a new xmlXPathObjectPtr of type string and of value @val
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathNewCString(const char *val) {
    xmlXPathObjectPtr ret;

    ret = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating string object\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathObject));
    ret->type = XPATH_STRING;
    ret->stringval = xmlStrdup(BAD_CAST val);
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageRequested(NULL, XPATH_STRING);
#endif
    return(ret);
}

/**
 * xmlXPathWrapCString:
 * @val:  the char * value
 *
 * Wraps a string into an XPath object.
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathWrapCString (char * val) {
    return(xmlXPathWrapString((xmlChar *)(val)));
}

/**
 * xmlXPathWrapExternal:
 * @val:  the user data
 *
 * Wraps the @val data into an XPath object.
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathWrapExternal (void *val) {
    xmlXPathObjectPtr ret;

    ret = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating user object\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathObject));
    ret->type = XPATH_USERS;
    ret->user = val;
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageRequested(NULL, XPATH_USERS);
#endif
    return(ret);
}

/**
 * xmlXPathObjectCopy:
 * @val:  the original object
 *
 * allocate a new copy of a given object
 *
 * Returns the newly created object.
 */
xmlXPathObjectPtr
xmlXPathObjectCopy(xmlXPathObjectPtr val) {
    xmlXPathObjectPtr ret;

    if (val == NULL)
	return(NULL);

    ret = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "copying object\n");
	return(NULL);
    }
    memcpy(ret, val , (size_t) sizeof(xmlXPathObject));
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageRequested(NULL, val->type);
#endif
    switch (val->type) {
	case XPATH_BOOLEAN:
	case XPATH_NUMBER:
	case XPATH_POINT:
	case XPATH_RANGE:
	    break;
	case XPATH_STRING:
	    ret->stringval = xmlStrdup(val->stringval);
	    break;
	case XPATH_XSLT_TREE:
#if 0
/*
  Removed 11 July 2004 - the current handling of xslt tmpRVT nodes means that
  this previous handling is no longer correct, and can cause some serious
  problems (ref. bug 145547)
*/
	    if ((val->nodesetval != NULL) &&
		(val->nodesetval->nodeTab != NULL)) {
		xmlNodePtr cur, tmp;
		xmlDocPtr top;

		ret->boolval = 1;
		top =  xmlNewDoc(NULL);
		top->name = (char *)
		    xmlStrdup(val->nodesetval->nodeTab[0]->name);
		ret->user = top;
		if (top != NULL) {
		    top->doc = top;
		    cur = val->nodesetval->nodeTab[0]->children;
		    while (cur != NULL) {
			tmp = xmlDocCopyNode(cur, top, 1);
			xmlAddChild((xmlNodePtr) top, tmp);
			cur = cur->next;
		    }
		}

		ret->nodesetval = xmlXPathNodeSetCreate((xmlNodePtr) top);
	    } else
		ret->nodesetval = xmlXPathNodeSetCreate(NULL);
	    /* Deallocate the copied tree value */
	    break;
#endif
	case XPATH_NODESET:
	    ret->nodesetval = xmlXPathNodeSetMerge(NULL, val->nodesetval);
	    /* Do not deallocate the copied tree value */
	    ret->boolval = 0;
	    break;
	case XPATH_LOCATIONSET:
#ifdef LIBXML_XPTR_ENABLED
	{
	    xmlLocationSetPtr loc = val->user;
	    ret->user = (void *) xmlXPtrLocationSetMerge(NULL, loc);
	    break;
	}
#endif
        case XPATH_USERS:
	    ret->user = val->user;
	    break;
        case XPATH_UNDEFINED:
	    xmlGenericError(xmlGenericErrorContext,
		    "xmlXPathObjectCopy: unsupported type %d\n",
		    val->type);
	    break;
    }
    return(ret);
}

/**
 * xmlXPathFreeObject:
 * @obj:  the object to free
 *
 * Free up an xmlXPathObjectPtr object.
 */
void
xmlXPathFreeObject(xmlXPathObjectPtr obj) {
    if (obj == NULL) return;
    if ((obj->type == XPATH_NODESET) || (obj->type == XPATH_XSLT_TREE)) {
	if (obj->boolval) {
#if 0
	    if (obj->user != NULL) {
                xmlXPathFreeNodeSet(obj->nodesetval);
		xmlFreeNodeList((xmlNodePtr) obj->user);
	    } else
#endif
	    obj->type = XPATH_XSLT_TREE; /* TODO: Just for debugging. */
	    if (obj->nodesetval != NULL)
		xmlXPathFreeValueTree(obj->nodesetval);
	} else {
	    if (obj->nodesetval != NULL)
		xmlXPathFreeNodeSet(obj->nodesetval);
	}
#ifdef LIBXML_XPTR_ENABLED
    } else if (obj->type == XPATH_LOCATIONSET) {
	if (obj->user != NULL)
	    xmlXPtrFreeLocationSet(obj->user);
#endif
    } else if (obj->type == XPATH_STRING) {
	if (obj->stringval != NULL)
	    xmlFree(obj->stringval);
    }
#ifdef XP_DEBUG_OBJ_USAGE
    xmlXPathDebugObjUsageReleased(NULL, obj->type);
#endif
    xmlFree(obj);
}

/**
 * xmlXPathReleaseObject:
 * @obj:  the xmlXPathObjectPtr to free or to cache
 *
 * Depending on the state of the cache this frees the given
 * XPath object or stores it in the cache.
 */
static void
xmlXPathReleaseObject(xmlXPathContextPtr ctxt, xmlXPathObjectPtr obj)
{
#define XP_CACHE_ADD(sl, o) if (sl == NULL) { \
	sl = xmlPointerListCreate(10); if (sl == NULL) goto free_obj; } \
    if (xmlPointerListAddSize(sl, obj, 0) == -1) goto free_obj;

#define XP_CACHE_WANTS(sl, n) ((sl == NULL) || ((sl)->number < n))

    if (obj == NULL)
	return;
    if ((ctxt == NULL) || (ctxt->cache == NULL)) {
	 xmlXPathFreeObject(obj);
    } else {
	xmlXPathContextCachePtr cache =
	    (xmlXPathContextCachePtr) ctxt->cache;

	switch (obj->type) {
	    case XPATH_NODESET:
	    case XPATH_XSLT_TREE:
		if (obj->nodesetval != NULL) {
		    if (obj->boolval) {
			/*
			* It looks like the @boolval is used for
			* evaluation if this an XSLT Result Tree Fragment.
			* TODO: Check if this assumption is correct.
			*/
			obj->type = XPATH_XSLT_TREE; /* just for debugging */
			xmlXPathFreeValueTree(obj->nodesetval);
			obj->nodesetval = NULL;
		    } else if ((obj->nodesetval->nodeMax <= 40) &&
			(XP_CACHE_WANTS(cache->nodesetObjs,
					cache->maxNodeset)))
		    {
			XP_CACHE_ADD(cache->nodesetObjs, obj);
			goto obj_cached;
		    } else {
			xmlXPathFreeNodeSet(obj->nodesetval);
			obj->nodesetval = NULL;
		    }
		}
		break;
	    case XPATH_STRING:
		if (obj->stringval != NULL)
		    xmlFree(obj->stringval);

		if (XP_CACHE_WANTS(cache->stringObjs, cache->maxString)) {
		    XP_CACHE_ADD(cache->stringObjs, obj);
		    goto obj_cached;
		}
		break;
	    case XPATH_BOOLEAN:
		if (XP_CACHE_WANTS(cache->booleanObjs, cache->maxBoolean)) {
		    XP_CACHE_ADD(cache->booleanObjs, obj);
		    goto obj_cached;
		}
		break;
	    case XPATH_NUMBER:
		if (XP_CACHE_WANTS(cache->numberObjs, cache->maxNumber)) {
		    XP_CACHE_ADD(cache->numberObjs, obj);
		    goto obj_cached;
		}
		break;
#ifdef LIBXML_XPTR_ENABLED
	    case XPATH_LOCATIONSET:
		if (obj->user != NULL) {
		    xmlXPtrFreeLocationSet(obj->user);
		}
		goto free_obj;
#endif
	    default:
		goto free_obj;
	}

	/*
	* Fallback to adding to the misc-objects slot.
	*/
	if (XP_CACHE_WANTS(cache->miscObjs, cache->maxMisc)) {
	    XP_CACHE_ADD(cache->miscObjs, obj);
	} else
	    goto free_obj;

obj_cached:

#ifdef XP_DEBUG_OBJ_USAGE
	xmlXPathDebugObjUsageReleased(ctxt, obj->type);
#endif

	if (obj->nodesetval != NULL) {
	    xmlNodeSetPtr tmpset = obj->nodesetval;

	    /*
	    * TODO: Due to those nasty ns-nodes, we need to traverse
	    *  the list and free the ns-nodes.
	    * URGENT TODO: Check if it's actually slowing things down.
	    *  Maybe we shouldn't try to preserve the list.
	    */
	    if (tmpset->nodeNr > 1) {
		int i;
		xmlNodePtr node;

		for (i = 0; i < tmpset->nodeNr; i++) {
		    node = tmpset->nodeTab[i];
		    if ((node != NULL) &&
			(node->type == XML_NAMESPACE_DECL))
		    {
			xmlXPathNodeSetFreeNs((xmlNsPtr) node);
		    }
		}
	    } else if (tmpset->nodeNr == 1) {
		if ((tmpset->nodeTab[0] != NULL) &&
		    (tmpset->nodeTab[0]->type == XML_NAMESPACE_DECL))
		    xmlXPathNodeSetFreeNs((xmlNsPtr) tmpset->nodeTab[0]);
	    }
	    tmpset->nodeNr = 0;
	    memset(obj, 0, sizeof(xmlXPathObject));
	    obj->nodesetval = tmpset;
	} else
	    memset(obj, 0, sizeof(xmlXPathObject));

	return;

free_obj:
	/*
	* Cache is full; free the object.
	*/
	if (obj->nodesetval != NULL)
	    xmlXPathFreeNodeSet(obj->nodesetval);
#ifdef XP_DEBUG_OBJ_USAGE
	xmlXPathDebugObjUsageReleased(NULL, obj->type);
#endif
	xmlFree(obj);
    }
    return;
}


/************************************************************************
 *									*
 *			Type Casting Routines				*
 *									*
 ************************************************************************/

/**
 * xmlXPathCastBooleanToString:
 * @val:  a boolean
 *
 * Converts a boolean to its string value.
 *
 * Returns a newly allocated string.
 */
xmlChar *
xmlXPathCastBooleanToString (int val) {
    xmlChar *ret;
    if (val)
	ret = xmlStrdup((const xmlChar *) "true");
    else
	ret = xmlStrdup((const xmlChar *) "false");
    return(ret);
}

/**
 * xmlXPathCastNumberToString:
 * @val:  a number
 *
 * Converts a number to its string value.
 *
 * Returns a newly allocated string.
 */
xmlChar *
xmlXPathCastNumberToString (double val) {
    xmlChar *ret;
    switch (xmlXPathIsInf(val)) {
    case 1:
	ret = xmlStrdup((const xmlChar *) "Infinity");
	break;
    case -1:
	ret = xmlStrdup((const xmlChar *) "-Infinity");
	break;
    default:
	if (xmlXPathIsNaN(val)) {
	    ret = xmlStrdup((const xmlChar *) "NaN");
	} else if (val == 0 && xmlXPathGetSign(val) != 0) {
	    ret = xmlStrdup((const xmlChar *) "0");
	} else {
	    /* could be improved */
	    char buf[100];
	    xmlXPathFormatNumber(val, buf, 99);
	    buf[99] = 0;
	    ret = xmlStrdup((const xmlChar *) buf);
	}
    }
    return(ret);
}

/**
 * xmlXPathCastNodeToString:
 * @node:  a node
 *
 * Converts a node to its string value.
 *
 * Returns a newly allocated string.
 */
xmlChar *
xmlXPathCastNodeToString (xmlNodePtr node) {
xmlChar *ret;
    if ((ret = xmlNodeGetContent(node)) == NULL)
	ret = xmlStrdup((const xmlChar *) "");
    return(ret);
}

/**
 * xmlXPathCastNodeSetToString:
 * @ns:  a node-set
 *
 * Converts a node-set to its string value.
 *
 * Returns a newly allocated string.
 */
xmlChar *
xmlXPathCastNodeSetToString (xmlNodeSetPtr ns) {
    if ((ns == NULL) || (ns->nodeNr == 0) || (ns->nodeTab == NULL))
	return(xmlStrdup((const xmlChar *) ""));

    if (ns->nodeNr > 1)
	xmlXPathNodeSetSort(ns);
    return(xmlXPathCastNodeToString(ns->nodeTab[0]));
}

/**
 * xmlXPathCastToString:
 * @val:  an XPath object
 *
 * Converts an existing object to its string() equivalent
 *
 * Returns the allocated string value of the object, NULL in case of error.
 *         It's up to the caller to free the string memory with xmlFree().
 */
xmlChar *
xmlXPathCastToString(xmlXPathObjectPtr val) {
    xmlChar *ret = NULL;

    if (val == NULL)
	return(xmlStrdup((const xmlChar *) ""));
    switch (val->type) {
	case XPATH_UNDEFINED:
#ifdef DEBUG_EXPR
	    xmlGenericError(xmlGenericErrorContext, "String: undefined\n");
#endif
	    ret = xmlStrdup((const xmlChar *) "");
	    break;
        case XPATH_NODESET:
        case XPATH_XSLT_TREE:
	    ret = xmlXPathCastNodeSetToString(val->nodesetval);
	    break;
	case XPATH_STRING:
	    return(xmlStrdup(val->stringval));
        case XPATH_BOOLEAN:
	    ret = xmlXPathCastBooleanToString(val->boolval);
	    break;
	case XPATH_NUMBER: {
	    ret = xmlXPathCastNumberToString(val->floatval);
	    break;
	}
	case XPATH_USERS:
	case XPATH_POINT:
	case XPATH_RANGE:
	case XPATH_LOCATIONSET:
	    TODO
	    ret = xmlStrdup((const xmlChar *) "");
	    break;
    }
    return(ret);
}

/**
 * xmlXPathConvertString:
 * @val:  an XPath object
 *
 * Converts an existing object to its string() equivalent
 *
 * Returns the new object, the old one is freed (or the operation
 *         is done directly on @val)
 */
xmlXPathObjectPtr
xmlXPathConvertString(xmlXPathObjectPtr val) {
    xmlChar *res = NULL;

    if (val == NULL)
	return(xmlXPathNewCString(""));

    switch (val->type) {
    case XPATH_UNDEFINED:
#ifdef DEBUG_EXPR
	xmlGenericError(xmlGenericErrorContext, "STRING: undefined\n");
#endif
	break;
    case XPATH_NODESET:
    case XPATH_XSLT_TREE:
	res = xmlXPathCastNodeSetToString(val->nodesetval);
	break;
    case XPATH_STRING:
	return(val);
    case XPATH_BOOLEAN:
	res = xmlXPathCastBooleanToString(val->boolval);
	break;
    case XPATH_NUMBER:
	res = xmlXPathCastNumberToString(val->floatval);
	break;
    case XPATH_USERS:
    case XPATH_POINT:
    case XPATH_RANGE:
    case XPATH_LOCATIONSET:
	TODO;
	break;
    }
    xmlXPathFreeObject(val);
    if (res == NULL)
	return(xmlXPathNewCString(""));
    return(xmlXPathWrapString(res));
}

/**
 * xmlXPathCastBooleanToNumber:
 * @val:  a boolean
 *
 * Converts a boolean to its number value
 *
 * Returns the number value
 */
double
xmlXPathCastBooleanToNumber(int val) {
    if (val)
	return(1.0);
    return(0.0);
}

/**
 * xmlXPathCastStringToNumber:
 * @val:  a string
 *
 * Converts a string to its number value
 *
 * Returns the number value
 */
double
xmlXPathCastStringToNumber(const xmlChar * val) {
    return(xmlXPathStringEvalNumber(val));
}

/**
 * xmlXPathCastNodeToNumber:
 * @node:  a node
 *
 * Converts a node to its number value
 *
 * Returns the number value
 */
double
xmlXPathCastNodeToNumber (xmlNodePtr node) {
    xmlChar *strval;
    double ret;

    if (node == NULL)
	return(xmlXPathNAN);
    strval = xmlXPathCastNodeToString(node);
    if (strval == NULL)
	return(xmlXPathNAN);
    ret = xmlXPathCastStringToNumber(strval);
    xmlFree(strval);

    return(ret);
}

/**
 * xmlXPathCastNodeSetToNumber:
 * @ns:  a node-set
 *
 * Converts a node-set to its number value
 *
 * Returns the number value
 */
double
xmlXPathCastNodeSetToNumber (xmlNodeSetPtr ns) {
    xmlChar *str;
    double ret;

    if (ns == NULL)
	return(xmlXPathNAN);
    str = xmlXPathCastNodeSetToString(ns);
    ret = xmlXPathCastStringToNumber(str);
    xmlFree(str);
    return(ret);
}

/**
 * xmlXPathCastToNumber:
 * @val:  an XPath object
 *
 * Converts an XPath object to its number value
 *
 * Returns the number value
 */
double
xmlXPathCastToNumber(xmlXPathObjectPtr val) {
    double ret = 0.0;

    if (val == NULL)
	return(xmlXPathNAN);
    switch (val->type) {
    case XPATH_UNDEFINED:
#ifdef DEGUB_EXPR
	xmlGenericError(xmlGenericErrorContext, "NUMBER: undefined\n");
#endif
	ret = xmlXPathNAN;
	break;
    case XPATH_NODESET:
    case XPATH_XSLT_TREE:
	ret = xmlXPathCastNodeSetToNumber(val->nodesetval);
	break;
    case XPATH_STRING:
	ret = xmlXPathCastStringToNumber(val->stringval);
	break;
    case XPATH_NUMBER:
	ret = val->floatval;
	break;
    case XPATH_BOOLEAN:
	ret = xmlXPathCastBooleanToNumber(val->boolval);
	break;
    case XPATH_USERS:
    case XPATH_POINT:
    case XPATH_RANGE:
    case XPATH_LOCATIONSET:
	TODO;
	ret = xmlXPathNAN;
	break;
    }
    return(ret);
}

/**
 * xmlXPathConvertNumber:
 * @val:  an XPath object
 *
 * Converts an existing object to its number() equivalent
 *
 * Returns the new object, the old one is freed (or the operation
 *         is done directly on @val)
 */
xmlXPathObjectPtr
xmlXPathConvertNumber(xmlXPathObjectPtr val) {
    xmlXPathObjectPtr ret;

    if (val == NULL)
	return(xmlXPathNewFloat(0.0));
    if (val->type == XPATH_NUMBER)
	return(val);
    ret = xmlXPathNewFloat(xmlXPathCastToNumber(val));
    xmlXPathFreeObject(val);
    return(ret);
}

/**
 * xmlXPathCastNumberToBoolean:
 * @val:  a number
 *
 * Converts a number to its boolean value
 *
 * Returns the boolean value
 */
int
xmlXPathCastNumberToBoolean (double val) {
     if (xmlXPathIsNaN(val) || (val == 0.0))
	 return(0);
     return(1);
}

/**
 * xmlXPathCastStringToBoolean:
 * @val:  a string
 *
 * Converts a string to its boolean value
 *
 * Returns the boolean value
 */
int
xmlXPathCastStringToBoolean (const xmlChar *val) {
    if ((val == NULL) || (xmlStrlen(val) == 0))
	return(0);
    return(1);
}

/**
 * xmlXPathCastNodeSetToBoolean:
 * @ns:  a node-set
 *
 * Converts a node-set to its boolean value
 *
 * Returns the boolean value
 */
int
xmlXPathCastNodeSetToBoolean (xmlNodeSetPtr ns) {
    if ((ns == NULL) || (ns->nodeNr == 0))
	return(0);
    return(1);
}

/**
 * xmlXPathCastToBoolean:
 * @val:  an XPath object
 *
 * Converts an XPath object to its boolean value
 *
 * Returns the boolean value
 */
int
xmlXPathCastToBoolean (xmlXPathObjectPtr val) {
    int ret = 0;

    if (val == NULL)
	return(0);
    switch (val->type) {
    case XPATH_UNDEFINED:
#ifdef DEBUG_EXPR
	xmlGenericError(xmlGenericErrorContext, "BOOLEAN: undefined\n");
#endif
	ret = 0;
	break;
    case XPATH_NODESET:
    case XPATH_XSLT_TREE:
	ret = xmlXPathCastNodeSetToBoolean(val->nodesetval);
	break;
    case XPATH_STRING:
	ret = xmlXPathCastStringToBoolean(val->stringval);
	break;
    case XPATH_NUMBER:
	ret = xmlXPathCastNumberToBoolean(val->floatval);
	break;
    case XPATH_BOOLEAN:
	ret = val->boolval;
	break;
    case XPATH_USERS:
    case XPATH_POINT:
    case XPATH_RANGE:
    case XPATH_LOCATIONSET:
	TODO;
	ret = 0;
	break;
    }
    return(ret);
}


/**
 * xmlXPathConvertBoolean:
 * @val:  an XPath object
 *
 * Converts an existing object to its boolean() equivalent
 *
 * Returns the new object, the old one is freed (or the operation
 *         is done directly on @val)
 */
xmlXPathObjectPtr
xmlXPathConvertBoolean(xmlXPathObjectPtr val) {
    xmlXPathObjectPtr ret;

    if (val == NULL)
	return(xmlXPathNewBoolean(0));
    if (val->type == XPATH_BOOLEAN)
	return(val);
    ret = xmlXPathNewBoolean(xmlXPathCastToBoolean(val));
    xmlXPathFreeObject(val);
    return(ret);
}

/************************************************************************
 *									*
 *		Routines to handle XPath contexts			*
 *									*
 ************************************************************************/

/**
 * xmlXPathNewContext:
 * @doc:  the XML document
 *
 * Create a new xmlXPathContext
 *
 * Returns the xmlXPathContext just allocated. The caller will need to free it.
 */
xmlXPathContextPtr
xmlXPathNewContext(xmlDocPtr doc) {
    xmlXPathContextPtr ret;

    ret = (xmlXPathContextPtr) xmlMalloc(sizeof(xmlXPathContext));
    if (ret == NULL) {
        xmlXPathErrMemory(NULL, "creating context\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathContext));
    ret->doc = doc;
    ret->node = NULL;

    ret->varHash = NULL;

    ret->nb_types = 0;
    ret->max_types = 0;
    ret->types = NULL;

    ret->funcHash = xmlHashCreate(0);

    ret->nb_axis = 0;
    ret->max_axis = 0;
    ret->axis = NULL;

    ret->nsHash = NULL;
    ret->user = NULL;

    ret->contextSize = -1;
    ret->proximityPosition = -1;

#ifdef XP_DEFAULT_CACHE_ON
    if (xmlXPathContextSetCache(ret, 1, -1, 0) == -1) {
	xmlXPathFreeContext(ret);
	return(NULL);
    }
#endif

    xmlXPathRegisterAllFunctions(ret);

    return(ret);
}

/**
 * xmlXPathFreeContext:
 * @ctxt:  the context to free
 *
 * Free up an xmlXPathContext
 */
void
xmlXPathFreeContext(xmlXPathContextPtr ctxt) {
    if (ctxt == NULL) return;

    if (ctxt->cache != NULL)
	xmlXPathFreeCache((xmlXPathContextCachePtr) ctxt->cache);
    xmlXPathRegisteredNsCleanup(ctxt);
    xmlXPathRegisteredFuncsCleanup(ctxt);
    xmlXPathRegisteredVariablesCleanup(ctxt);
    xmlResetError(&ctxt->lastError);
    xmlFree(ctxt);
}

/************************************************************************
 *									*
 *		Routines to handle XPath parser contexts		*
 *									*
 ************************************************************************/

#define CHECK_CTXT(ctxt)						\
    if (ctxt == NULL) {						\
	__xmlRaiseError(NULL, NULL, NULL,				\
		NULL, NULL, XML_FROM_XPATH,				\
		XML_ERR_INTERNAL_ERROR, XML_ERR_FATAL,			\
		__FILE__, __LINE__,					\
		NULL, NULL, NULL, 0, 0,					\
		"NULL context pointer\n");				\
	return(NULL);							\
    }									\

#define CHECK_CTXT_NEG(ctxt)						\
    if (ctxt == NULL) {						\
	__xmlRaiseError(NULL, NULL, NULL,				\
		NULL, NULL, XML_FROM_XPATH,				\
		XML_ERR_INTERNAL_ERROR, XML_ERR_FATAL,			\
		__FILE__, __LINE__,					\
		NULL, NULL, NULL, 0, 0,					\
		"NULL context pointer\n");				\
	return(-1);							\
    }									\


#define CHECK_CONTEXT(ctxt)						\
    if ((ctxt == NULL) || (ctxt->doc == NULL) ||			\
        (ctxt->doc->children == NULL)) {				\
	xmlXPatherror(ctxt, __FILE__, __LINE__, XPATH_INVALID_CTXT);	\
	return(NULL);							\
    }


/**
 * xmlXPathNewParserContext:
 * @str:  the XPath expression
 * @ctxt:  the XPath context
 *
 * Create a new xmlXPathParserContext
 *
 * Returns the xmlXPathParserContext just allocated.
 */
xmlXPathParserContextPtr
xmlXPathNewParserContext(const xmlChar *str, xmlXPathContextPtr ctxt) {
    xmlXPathParserContextPtr ret;

    ret = (xmlXPathParserContextPtr) xmlMalloc(sizeof(xmlXPathParserContext));
    if (ret == NULL) {
        xmlXPathErrMemory(ctxt, "creating parser context\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathParserContext));
    ret->cur = ret->base = str;
    ret->context = ctxt;

    ret->comp = xmlXPathNewCompExpr();
    if (ret->comp == NULL) {
	xmlFree(ret->valueTab);
	xmlFree(ret);
	return(NULL);
    }
    if ((ctxt != NULL) && (ctxt->dict != NULL)) {
        ret->comp->dict = ctxt->dict;
	xmlDictReference(ret->comp->dict);
    }

    return(ret);
}

/**
 * xmlXPathCompParserContext:
 * @comp:  the XPath compiled expression
 * @ctxt:  the XPath context
 *
 * Create a new xmlXPathParserContext when processing a compiled expression
 *
 * Returns the xmlXPathParserContext just allocated.
 */
static xmlXPathParserContextPtr
xmlXPathCompParserContext(xmlXPathCompExprPtr comp, xmlXPathContextPtr ctxt) {
    xmlXPathParserContextPtr ret;

    ret = (xmlXPathParserContextPtr) xmlMalloc(sizeof(xmlXPathParserContext));
    if (ret == NULL) {
        xmlXPathErrMemory(ctxt, "creating evaluation context\n");
	return(NULL);
    }
    memset(ret, 0 , (size_t) sizeof(xmlXPathParserContext));

    /* Allocate the value stack */
    ret->valueTab = (xmlXPathObjectPtr *)
                     xmlMalloc(10 * sizeof(xmlXPathObjectPtr));
    if (ret->valueTab == NULL) {
	xmlFree(ret);
	xmlXPathErrMemory(ctxt, "creating evaluation context\n");
	return(NULL);
    }
    ret->valueNr = 0;
    ret->valueMax = 10;
    ret->value = NULL;

    ret->context = ctxt;
    ret->comp = comp;

    return(ret);
}

/**
 * xmlXPathFreeParserContext:
 * @ctxt:  the context to free
 *
 * Free up an xmlXPathParserContext
 */
void
xmlXPathFreeParserContext(xmlXPathParserContextPtr ctxt) {
    if (ctxt->valueTab != NULL) {
        xmlFree(ctxt->valueTab);
    }
    if (ctxt->comp != NULL) {
#ifdef XPATH_STREAMING
	if (ctxt->comp->stream != NULL) {
	    xmlFreePatternList(ctxt->comp->stream);
	    ctxt->comp->stream = NULL;
	}
#endif
	xmlXPathFreeCompExpr(ctxt->comp);
    }
    xmlFree(ctxt);
}

/************************************************************************
 *									*
 *		The implicit core function library			*
 *									*
 ************************************************************************/

/**
 * xmlXPathNodeValHash:
 * @node:  a node pointer
 *
 * Function computing the beginning of the string value of the node,
 * used to speed up comparisons
 *
 * Returns an int usable as a hash
 */
static unsigned int
xmlXPathNodeValHash(xmlNodePtr node) {
    int len = 2;
    const xmlChar * string = NULL;
    xmlNodePtr tmp = NULL;
    unsigned int ret = 0;

    if (node == NULL)
	return(0);

    if (node->type == XML_DOCUMENT_NODE) {
	tmp = xmlDocGetRootElement((xmlDocPtr) node);
	if (tmp == NULL)
	    node = node->children;
	else
	    node = tmp;

	if (node == NULL)
	    return(0);
    }

    switch (node->type) {
	case XML_COMMENT_NODE:
	case XML_PI_NODE:
	case XML_CDATA_SECTION_NODE:
	case XML_TEXT_NODE:
	    string = node->content;
	    if (string == NULL)
		return(0);
	    if (string[0] == 0)
		return(0);
	    return(((unsigned int) string[0]) +
		   (((unsigned int) string[1]) << 8));
	case XML_NAMESPACE_DECL:
	    string = ((xmlNsPtr)node)->href;
	    if (string == NULL)
		return(0);
	    if (string[0] == 0)
		return(0);
	    return(((unsigned int) string[0]) +
		   (((unsigned int) string[1]) << 8));
	case XML_ATTRIBUTE_NODE:
	    tmp = ((xmlAttrPtr) node)->children;
	    break;
	case XML_ELEMENT_NODE:
	    tmp = node->children;
	    break;
	default:
	    return(0);
    }
    while (tmp != NULL) {
	switch (tmp->type) {
	    case XML_COMMENT_NODE:
	    case XML_PI_NODE:
	    case XML_CDATA_SECTION_NODE:
	    case XML_TEXT_NODE:
		string = tmp->content;
		break;
	    case XML_NAMESPACE_DECL:
		string = ((xmlNsPtr)tmp)->href;
		break;
	    default:
		break;
	}
	if ((string != NULL) && (string[0] != 0)) {
	    if (len == 1) {
		return(ret + (((unsigned int) string[0]) << 8));
	    }
	    if (string[1] == 0) {
		len = 1;
		ret = (unsigned int) string[0];
	    } else {
		return(((unsigned int) string[0]) +
		       (((unsigned int) string[1]) << 8));
	    }
	}
	/*
	 * Skip to next node
	 */
	if ((tmp->children != NULL) && (tmp->type != XML_DTD_NODE)) {
	    if (tmp->children->type != XML_ENTITY_DECL) {
		tmp = tmp->children;
		continue;
	    }
	}
	if (tmp == node)
	    break;

	if (tmp->next != NULL) {
	    tmp = tmp->next;
	    continue;
	}

	do {
	    tmp = tmp->parent;
	    if (tmp == NULL)
		break;
	    if (tmp == node) {
		tmp = NULL;
		break;
	    }
	    if (tmp->next != NULL) {
		tmp = tmp->next;
		break;
	    }
	} while (tmp != NULL);
    }
    return(ret);
}

/**
 * xmlXPathStringHash:
 * @string:  a string
 *
 * Function computing the beginning of the string value of the node,
 * used to speed up comparisons
 *
 * Returns an int usable as a hash
 */
static unsigned int
xmlXPathStringHash(const xmlChar * string) {
    if (string == NULL)
	return((unsigned int) 0);
    if (string[0] == 0)
	return(0);
    return(((unsigned int) string[0]) +
	   (((unsigned int) string[1]) << 8));
}

/**
 * xmlXPathCompareNodeSetFloat:
 * @ctxt:  the XPath Parser context
 * @inf:  less than (1) or greater than (0)
 * @strict:  is the comparison strict
 * @arg:  the node set
 * @f:  the value
 *
 * Implement the compare operation between a nodeset and a number
 *     @ns < @val    (1, 1, ...
 *     @ns <= @val   (1, 0, ...
 *     @ns > @val    (0, 1, ...
 *     @ns >= @val   (0, 0, ...
 *
 * If one object to be compared is a node-set and the other is a number,
 * then the comparison will be true if and only if there is a node in the
 * node-set such that the result of performing the comparison on the number
 * to be compared and on the result of converting the string-value of that
 * node to a number using the number function is true.
 *
 * Returns 0 or 1 depending on the results of the test.
 */
static int
xmlXPathCompareNodeSetFloat(xmlXPathParserContextPtr ctxt, int inf, int strict,
	                    xmlXPathObjectPtr arg, xmlXPathObjectPtr f) {
    int i, ret = 0;
    xmlNodeSetPtr ns;
    xmlChar *str2;

    if ((f == NULL) || (arg == NULL) ||
	((arg->type != XPATH_NODESET) && (arg->type != XPATH_XSLT_TREE))) {
	xmlXPathReleaseObject(ctxt->context, arg);
	xmlXPathReleaseObject(ctxt->context, f);
        return(0);
    }
    ns = arg->nodesetval;
    if (ns != NULL) {
	for (i = 0;i < ns->nodeNr;i++) {
	     str2 = xmlXPathCastNodeToString(ns->nodeTab[i]);
	     if (str2 != NULL) {
		 valuePush(ctxt,
			   xmlXPathCacheNewString(ctxt->context, str2));
		 xmlFree(str2);
		 xmlXPathNumberFunction(ctxt, 1);
		 valuePush(ctxt, xmlXPathCacheObjectCopy(ctxt->context, f));
		 ret = xmlXPathCompareValues(ctxt, inf, strict);
		 if (ret)
		     break;
	     }
	}
    }
    xmlXPathReleaseObject(ctxt->context, arg);
    xmlXPathReleaseObject(ctxt->context, f);
    return(ret);
}

/**
 * xmlXPathCompareNodeSetString:
 * @ctxt:  the XPath Parser context
 * @inf:  less than (1) or greater than (0)
 * @strict:  is the comparison strict
 * @arg:  the node set
 * @s:  the value
 *
 * Implement the compare operation between a nodeset and a string
 *     @ns < @val    (1, 1, ...
 *     @ns <= @val   (1, 0, ...
 *     @ns > @val    (0, 1, ...
 *     @ns >= @val   (0, 0, ...
 *
 * If one object to be compared is a node-set and the other is a string,
 * then the comparison will be true if and only if there is a node in
 * the node-set such that the result of performing the comparison on the
 * string-value of the node and the other string is true.
 *
 * Returns 0 or 1 depending on the results of the test.
 */
static int
xmlXPathCompareNodeSetString(xmlXPathParserContextPtr ctxt, int inf, int strict,
	                    xmlXPathObjectPtr arg, xmlXPathObjectPtr s) {
    int i, ret = 0;
    xmlNodeSetPtr ns;
    xmlChar *str2;

    if ((s == NULL) || (arg == NULL) ||
	((arg->type != XPATH_NODESET) && (arg->type != XPATH_XSLT_TREE))) {
	xmlXPathReleaseObject(ctxt->context, arg);
	xmlXPathReleaseObject(ctxt->context, s);
        return(0);
    }
    ns = arg->nodesetval;
    if (ns != NULL) {
	for (i = 0;i < ns->nodeNr;i++) {
	     str2 = xmlXPathCastNodeToString(ns->nodeTab[i]);
	     if (str2 != NULL) {
		 valuePush(ctxt,
			   xmlXPathCacheNewString(ctxt->context, str2));
		 xmlFree(str2);
		 valuePush(ctxt, xmlXPathCacheObjectCopy(ctxt->context, s));
		 ret = xmlXPathCompareValues(ctxt, inf, strict);
		 if (ret)
		     break;
	     }
	}
    }
    xmlXPathReleaseObject(ctxt->context, arg);
    xmlXPathReleaseObject(ctxt->context, s);
    return(ret);
}

/**
 * xmlXPathCompareNodeSets:
 * @inf:  less than (1) or greater than (0)
 * @strict:  is the comparison strict
 * @arg1:  the first node set object
 * @arg2:  the second node set object
 *
 * Implement the compare operation on nodesets:
 *
 * If both objects to be compared are node-sets, then the comparison
 * will be true if and only if there is a node in the first node-set
 * and a node in the second node-set such that the result of performing
 * the comparison on the string-values of the two nodes is true.
 * ....
 * When neither object to be compared is a node-set and the operator
 * is <=, <, >= or >, then the objects are compared by converting both
 * objects to numbers and comparing the numbers according to IEEE 754.
 * ....
 * The number function converts its argument to a number as follows:
 *  - a string that consists of optional whitespace followed by an
 *    optional minus sign followed by a Number followed by whitespace
 *    is converted to the IEEE 754 number that is nearest (according
 *    to the IEEE 754 round-to-nearest rule) to the mathematical value
 *    represented by the string; any other string is converted to NaN
 *
 * Conclusion all nodes need to be converted first to their string value
 * and then the comparison must be done when possible
 */
static int
xmlXPathCompareNodeSets(int inf, int strict,
	                xmlXPathObjectPtr arg1, xmlXPathObjectPtr arg2) {
    int i, j, init = 0;
    double val1;
    double *values2;
    int ret = 0;
    xmlNodeSetPtr ns1;
    xmlNodeSetPtr ns2;

    if ((arg1 == NULL) ||
	((arg1->type != XPATH_NODESET) && (arg1->type != XPATH_XSLT_TREE))) {
	xmlXPathFreeObject(arg2);
        return(0);
    }
    if ((arg2 == NULL) ||
	((arg2->type != XPATH_NODESET) && (arg2->type != XPATH_XSLT_TREE))) {
	xmlXPathFreeObject(arg1);
	xmlXPathFreeObject(arg2);
        return(0);
    }

    ns1 = arg1->nodesetval;
    ns2 = arg2->nodesetval;

    if ((ns1 == NULL) || (ns1->nodeNr <= 0)) {
	xmlXPathFreeObject(arg1);
	xmlXPathFreeObject(arg2);
	return(0);
    }
    if ((ns2 == NULL) || (ns2->nodeNr <= 0)) {
	xmlXPathFreeObject(arg1);
	xmlXPathFreeObject(arg2);
	return(0);
    }

    values2 = (double *) xmlMalloc(ns2->nodeNr * sizeof(double));
    if (values2 == NULL) {
        xmlXPathErrMemory(NULL, "comparing nodesets\n");
	xmlXPathFreeObject(arg1);
	xmlXPathFreeObject(arg2);
	return(0);
    }
    for (i = 0;i < ns1->nodeNr;i++) {
	val1 = xmlXPathCastNodeToNumber(ns1->nodeTab[i]);
	if (xmlXPathIsNaN(val1))
	    continue;
	for (j = 0;j < ns2->nodeNr;j++) {
	    if (init == 0) {
		values2[j] = xmlXPathCastNodeToNumber(ns2->nodeTab[j]);
	    }
	    if (xmlXPathIsNaN(values2[j]))
		continue;
	    if (inf && strict)
		ret = (val1 < values2[j]);
	    else if (inf && !strict)
		ret = (val1 <= values2[j]);
	    else if (!inf && strict)
		ret = (val1 > values2[j]);
	    else if (!inf && !strict)
		ret = (val1 >= values2[j]);
	    if (ret)
		break;
	}
	if (ret)
	    break;
	init = 1;
    }
    xmlFree(values2);
    xmlXPathFreeObject(arg1);
    xmlXPathFreeObject(arg2);
    return(ret);
}

/**
 * xmlXPathCompareNodeSetValue:
 * @ctxt:  the XPath Parser context
 * @inf:  less than (1) or greater than (0)
 * @strict:  is the comparison strict
 * @arg:  the node set
 * @val:  the value
 *
 * Implement the compare operation between a nodeset and a value
 *     @ns < @val    (1, 1, ...
 *     @ns <= @val   (1, 0, ...
 *     @ns > @val    (0, 1, ...
 *     @ns >= @val   (0, 0, ...
 *
 * If one object to be compared is a node-set and the other is a boolean,
 * then the comparison will be true if and only if the result of performing
 * the comparison on the boolean and on the result of converting
 * the node-set to a boolean using the boolean function is true.
 *
 * Returns 0 or 1 depending on the results of the test.
 */
static int
xmlXPathCompareNodeSetValue(xmlXPathParserContextPtr ctxt, int inf, int strict,
	                    xmlXPathObjectPtr arg, xmlXPathObjectPtr val) {
    if ((val == NULL) || (arg == NULL) ||
	((arg->type != XPATH_NODESET) && (arg->type != XPATH_XSLT_TREE)))
        return(0);

    switch(val->type) {
        case XPATH_NUMBER:
	    return(xmlXPathCompareNodeSetFloat(ctxt, inf, strict, arg, val));
        case XPATH_NODESET:
        case XPATH_XSLT_TREE:
	    return(xmlXPathCompareNodeSets(inf, strict, arg, val));
        case XPATH_STRING:
	    return(xmlXPathCompareNodeSetString(ctxt, inf, strict, arg, val));
        case XPATH_BOOLEAN:
	    valuePush(ctxt, arg);
	    xmlXPathBooleanFunction(ctxt, 1);
	    valuePush(ctxt, val);
	    return(xmlXPathCompareValues(ctxt, inf, strict));
	default:
	    TODO
    }
    return(0);
}

/**
 * xmlXPathEqualNodeSetString:
 * @arg:  the nodeset object argument
 * @str:  the string to compare to.
 * @neq:  flag to show whether for '=' (0) or '!=' (1)
 *
 * Implement the equal operation on XPath objects content: @arg1 == @arg2
 * If one object to be compared is a node-set and the other is a string,
 * then the comparison will be true if and only if there is a node in
 * the node-set such that the result of performing the comparison on the
 * string-value of the node and the other string is true.
 *
 * Returns 0 or 1 depending on the results of the test.
 */
static int
xmlXPathEqualNodeSetString(xmlXPathObjectPtr arg, const xmlChar * str, int neq)
{
    int i;
    xmlNodeSetPtr ns;
    xmlChar *str2;
    unsigned int hash;

    if ((str == NULL) || (arg == NULL) ||
        ((arg->type != XPATH_NODESET) && (arg->type != XPATH_XSLT_TREE)))
        return (0);
    ns = arg->nodesetval;
    /*
     * A NULL nodeset compared with a string is always false
     * (since there is no node equal, and no node not equal)
     */
    if ((ns == NULL) || (ns->nodeNr <= 0) )
        return (0);
    hash = xmlXPathStringHash(str);
    for (i = 0; i < ns->nodeNr; i++) {
        if (xmlXPathNodeValHash(ns->nodeTab[i]) == hash) {
            str2 = xmlNodeGetContent(ns->nodeTab[i]);
            if ((str2 != NULL) && (xmlStrEqual(str, str2))) {
                xmlFree(str2);
		if (neq)
		    continue;
                return (1);
	    } else if ((str2 == NULL) && (xmlStrEqual(str, BAD_CAST ""))) {
		if (neq)
		    continue;
                return (1);
            } else if (neq) {
		if (str2 != NULL)
		    xmlFree(str2);
		return (1);
	    }
            if (str2 != NULL)
                xmlFree(str2);
        } else if (neq)
	    return (1);
    }
    return (0);
}

/**
 * xmlXPathEqualNodeSetFloat:
 * @arg:  the nodeset object argument
 * @f:  the float to compare to
 * @neq:  flag to show whether to compare '=' (0) or '!=' (1)
 *
 * Implement the equal operation on XPath objects content: @arg1 == @arg2
 * If one object to be compared is a node-set and the other is a number,
 * then the comparison will be true if and only if there is a node in
 * the node-set such that the result of performing the comparison on the
 * number to be compared and on the result of converting the string-value
 * of that node to a number using the number function is true.
 *
 * Returns 0 or 1 depending on the results of the test.
 */
static int
xmlXPathEqualNodeSetFloat(xmlXPathParserContextPtr ctxt,
    xmlXPathObjectPtr arg, double f, int neq) {
  int i, ret=0;
  xmlNodeSetPtr ns;
  xmlChar *str2;
  xmlXPathObjectPtr val;
  double v;

    if ((arg == NULL) ||
	((arg->type != XPATH_NODESET) && (arg->type != XPATH_XSLT_TREE)))
        return(0);

    ns = arg->nodesetval;
    if (ns != NULL) {
	for (i=0;i<ns->nodeNr;i++) {
	    str2 = xmlXPathCastNodeToString(ns->nodeTab[i]);
	    if (str2 != NULL) {
		valuePush(ctxt, xmlXPathCacheNewString(ctxt->context, str2));
		xmlFree(str2);
		xmlXPathNumberFunction(ctxt, 1);
		val = valuePop(ctxt);
		v = val->floatval;
		xmlXPathReleaseObject(ctxt->context, val);
		if (!xmlXPathIsNaN(v)) {
		    if ((!neq) && (v==f)) {
			ret = 1;
			break;
		    } else if ((neq) && (v!=f)) {
			ret = 1;
			break;
		    }
		} else {	/* NaN is unequal to any value */
		    if (neq)
			ret = 1;
		}
	    }
	}
    }

    return(ret);
}


/**
 * xmlXPathEqualNodeSets:
 * @arg1:  first nodeset object argument
 * @arg2:  second nodeset object argument
 * @neq:   flag to show whether to test '=' (0) or '!=' (1)
 *
 * Implement the equal / not equal operation on XPath nodesets:
 * @arg1 == @arg2  or  @arg1 != @arg2
 * If both objects to be compared are node-sets, then the comparison
 * will be true if and only if there is a node in the first node-set and
 * a node in the second node-set such that the result of performing the
 * comparison on the string-values of the two nodes is true.
 *
 * (needless to say, this is a costly operation)
 *
 * Returns 0 or 1 depending on the results of the test.
 */
static int
xmlXPathEqualNodeSets(xmlXPathObjectPtr arg1, xmlXPathObjectPtr arg2, int neq) {
    int i, j;
    unsigned int *hashs1;
    unsigned int *hashs2;
    xmlChar **values1;
    xmlChar **values2;
    int ret = 0;
    xmlNodeSetPtr ns1;
    xmlNodeSetPtr ns2;

    if ((arg1 == NULL) ||
	((arg1->type != XPATH_NODESET) && (arg1->type != XPATH_XSLT_TREE)))
        return(0);
    if ((arg2 == NULL) ||
	((arg2->type != XPATH_NODESET) && (arg2->type != XPATH_XSLT_TREE)))
        return(0);

    ns1 = arg1->nodesetval;
    ns2 = arg2->nodesetval;

    if ((ns1 == NULL) || (ns1->nodeNr <= 0))
	return(0);
    if ((ns2 == NULL) || (ns2->nodeNr <= 0))
	return(0);

    /*
     * for equal, check if there is a node pertaining to both sets
     */
    if (neq == 0)
	for (i = 0;i < ns1->nodeNr;i++)
	    for (j = 0;j < ns2->nodeNr;j++)
		if (ns1->nodeTab[i] == ns2->nodeTab[j])
		    return(1);

    values1 = (xmlChar **) xmlMalloc(ns1->nodeNr * sizeof(xmlChar *));
    if (values1 == NULL) {
        xmlXPathErrMemory(NULL, "comparing nodesets\n");
	return(0);
    }
    hashs1 = (unsigned int *) xmlMalloc(ns1->nodeNr * sizeof(unsigned int));
    if (hashs1 == NULL) {
        xmlXPathErrMemory(NULL, "comparing nodesets\n");
	xmlFree(values1);
	return(0);
    }
    memset(values1, 0, ns1->nodeNr * sizeof(xmlChar *));
    values2 = (xmlChar **) xmlMalloc(ns2->nodeNr * sizeof(xmlChar *));
    if (values2 == NULL) {
        xmlXPathErrMemory(NULL, "comparing nodesets\n");
	xmlFree(hashs1);
	xmlFree(values1);
	return(0);
    }
    hashs2 = (unsigned int *) xmlMalloc(ns2->nodeNr * sizeof(unsigned int));
    if (hashs2 == NULL) {
        xmlXPathErrMemory(NULL, "comparing nodesets\n");
	xmlFree(hashs1);
	xmlFree(values1);
	xmlFree(values2);
	return(0);
    }
    memset(values2, 0, ns2->nodeNr * sizeof(xmlChar *));
    for (i = 0;i < ns1->nodeNr;i++) {
	hashs1[i] = xmlXPathNodeValHash(ns1->nodeTab[i]);
	for (j = 0;j < ns2->nodeNr;j++) {
	    if (i == 0)
		hashs2[j] = xmlXPathNodeValHash(ns2->nodeTab[j]);
	    if (hashs1[i] != hashs2[j]) {
		if (neq) {
		    ret = 1;
		    break;
		}
	    }
	    else {
		if (values1[i] == NULL)
		    values1[i] = xmlNodeGetContent(ns1->nodeTab[i]);
		if (values2[j] == NULL)
		    values2[j] = xmlNodeGetContent(ns2->nodeTab[j]);
		ret = xmlStrEqual(values1[i], values2[j]) ^ neq;
		if (ret)
		    break;
	    }
	}
	if (ret)
	    break;
    }
    for (i = 0;i < ns1->nodeNr;i++)
	if (values1[i] != NULL)
	    xmlFree(values1[i]);
    for (j = 0;j < ns2->nodeNr;j++)
	if (values2[j] != NULL)
	    xmlFree(values2[j]);
    xmlFree(values1);
    xmlFree(values2);
    xmlFree(hashs1);
    xmlFree(hashs2);
    return(ret);
}

static int
xmlXPathEqualValuesCommon(xmlXPathParserContextPtr ctxt,
  xmlXPathObjectPtr arg1, xmlXPathObjectPtr arg2) {
    int ret = 0;
    /*
     *At this point we are assured neither arg1 nor arg2
     *is a nodeset, so we can just pick the appropriate routine.
     */
    switch (arg1->type) {
        case XPATH_UNDEFINED:
#ifdef DEBUG_EXPR
	    xmlGenericError(xmlGenericErrorContext,
		    "Equal: undefined\n");
#endif
	    break;
        case XPATH_BOOLEAN:
	    switch (arg2->type) {
	        case XPATH_UNDEFINED:
#ifdef DEBUG_EXPR
		    xmlGenericError(xmlGenericErrorContext,
			    "Equal: undefined\n");
#endif
		    break;
		case XPATH_BOOLEAN:
#ifdef DEBUG_EXPR
		    xmlGenericError(xmlGenericErrorContext,
			    "Equal: %d boolean %d \n",
			    arg1->boolval, arg2->boolval);
#endif
		    ret = (arg1->boolval == arg2->boolval);
		    break;
		case XPATH_NUMBER:
		    ret = (arg1->boolval ==
			   xmlXPathCastNumberToBoolean(arg2->floatval));
		    break;
		case XPATH_STRING:
		    if ((arg2->stringval == NULL) ||
			(arg2->stringval[0] == 0)) ret = 0;
		    else
			ret = 1;
		    ret = (arg1->boolval == ret);
		    break;
		case XPATH_USERS:
		case XPATH_POINT:
		case XPATH_RANGE:
		case XPATH_LOCATIONSET:
		    TODO
		    break;
		case XPATH_NODESET:
		case XPATH_XSLT_TREE:
		    break;
	    }
	    break;
        case XPATH_NUMBER:
	    switch (arg2->type) {
	        case XPATH_UNDEFINED:
#ifdef DEBUG_EXPR
		    xmlGenericError(xmlGenericErrorContext,
			    "Equal: undefined\n");
#endif
		    break;
		case XPATH_BOOLEAN:
		    ret = (arg2->boolval==
			   xmlXPathCastNumberToBoolean(arg1->floatval));
		    break;
		case XPATH_STRING:
		    valuePush(ctxt, arg2);
		    xmlXPathNumberFunction(ctxt, 1);
		    arg2 = valuePop(ctxt);
		    /* no break on purpose */
		case XPATH_NUMBER:
		    /* Hand check NaN and Infinity equalities */
		    if (xmlXPathIsNaN(arg1->floatval) ||
			    xmlXPathIsNaN(arg2->floatval)) {
		        ret = 0;
		    } else if (xmlXPathIsInf(arg1->floatval) == 1) {
		        if (xmlXPathIsInf(arg2->floatval) == 1)
			    ret = 1;
			else
			    ret = 0;
		    } else if (xmlXPathIsInf(arg1->floatval) == -1) {
			if (xmlXPathIsInf(arg2->floatval) == -1)
			    ret = 1;
			else
			    ret = 0;
		    } else if (xmlXPathIsInf(arg2->floatval) == 1) {
			if (xmlXPathIsInf(arg1->floatval) == 1)
			    ret = 1;
			else
			    ret = 0;
		    } else if (xmlXPathIsInf(arg2->floatval) == -1) {
			if (xmlXPathIsInf(arg1->floatval) == -1)
			    ret = 1;
			else
			    ret = 0;
		    } else {
		        ret = (arg1->floatval == arg2->floatval);
		    }
		    break;
		case XPATH_USERS:
		case XPATH_POINT:
		case XPATH_RANGE:
		case XPATH_LOCATIONSET:
		    TODO
		    break;
		case XPATH_NODESET:
		case XPATH_XSLT_TREE:
		    break;
	    }
	    break;
        case XPATH_STRING:
	    switch (arg2->type) {
	        case XPATH_UNDEFINED:
#ifdef DEBUG_EXPR
		    xmlGenericError(xmlGenericErrorContext,
			    "Equal: undefined\n");
#endif
		    break;
		case XPATH_BOOLEAN:
		    if ((arg1->stringval == NULL) ||
			(arg1->stringval[0] == 0)) ret = 0;
		    else
			ret = 1;
		    ret = (arg2->boolval == ret);
		    break;
		case XPATH_STRING:
		    ret = xmlStrEqual(arg1->stringval, arg2->stringval);
		    break;
		case XPATH_NUMBER:
		    valuePush(ctxt, arg1);
		    xmlXPathNumberFunction(ctxt, 1);
		    arg1 = valuePop(ctxt);
		    /* Hand check NaN and Infinity equalities */
		    if (xmlXPathIsNaN(arg1->floatval) ||
			    xmlXPathIsNaN(arg2->floatval)) {
		        ret = 0;
		    } else if (xmlXPathIsInf(arg1->floatval) == 1) {
			if (xmlXPathIsInf(arg2->floatval) == 1)
			    ret = 1;
			else
			    ret = 0;
		    } else if (xmlXPathIsInf(arg1->floatval) == -1) {
			if (xmlXPathIsInf(arg2->floatval) == -1)
			    ret = 1;
			else
			    ret = 0;
		    } else if (xmlXPathIsInf(arg2->floatval) == 1) {
			if (xmlXPathIsInf(arg1->floatval) == 1)
			    ret = 1;
			else
			    ret = 0;
		    } else if (xmlXPathIsInf(arg2->floatval) == -1) {
			if (xmlXPathIsInf(arg1->floatval) == -1)
			    ret = 1;
			else
			    ret = 0;
		    } else {
		        ret = (arg1->floatval == arg2->floatval);
		    }
		    break;
		case XPATH_USERS:
		case XPATH_POINT:
		case XPATH_RANGE:
		case XPATH_LOCATIONSET:
		    TODO
		    break;
		case XPATH_NODESET:
		case XPATH_XSLT_TREE:
		    break;
	    }
	    break;
        case XPATH_USERS:
	case XPATH_POINT:
	case XPATH_RANGE:
	case XPATH_LOCATIONSET:
	    TODO
	    break;
	case XPATH_NODESET:
	case XPATH_XSLT_TREE:
	    break;
    }
    xmlXPathReleaseObject(ctxt->context, arg1);
    xmlXPathReleaseObject(ctxt->context, arg2);
    return(ret);
}

/**
 * xmlXPathEqualValues:
 * @ctxt:  the XPath Parser context
 *
 * Implement the equal operation on XPath objects content: @arg1 == @arg2
 *
 * Returns 0 or 1 depending on the results of the test.
 */
int
xmlXPathEqualValues(xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr arg1, arg2, argtmp;
    int ret = 0;

    if ((ctxt == NULL) || (ctxt->context == NULL)) return(0);
    arg2 = valuePop(ctxt);
    arg1 = valuePop(ctxt);
    if ((arg1 == NULL) || (arg2 == NULL)) {
	if (arg1 != NULL)
	    xmlXPathReleaseObject(ctxt->context, arg1);
	else
	    xmlXPathReleaseObject(ctxt->context, arg2);
	XP_ERROR0(XPATH_INVALID_OPERAND);
    }

    if (arg1 == arg2) {
#ifdef DEBUG_EXPR
        xmlGenericError(xmlGenericErrorContext,
		"Equal: by pointer\n");
#endif
	xmlXPathFreeObject(arg1);
        return(1);
    }

    /*
     *If either argument is a nodeset, it's a 'special case'
     */
    if ((arg2->type == XPATH_NODESET) || (arg2->type == XPATH_XSLT_TREE) ||
      (arg1->type == XPATH_NODESET) || (arg1->type == XPATH_XSLT_TREE)) {
	/*
	 *Hack it to assure arg1 is the nodeset
	 */
	if ((arg1->type != XPATH_NODESET) && (arg1->type != XPATH_XSLT_TREE)) {
		argtmp = arg2;
		arg2 = arg1;
		arg1 = argtmp;
	}
	switch (arg2->type) {
	    case XPATH_UNDEFINED:
#ifdef DEBUG_EXPR
		xmlGenericError(xmlGenericErrorContext,
			"Equal: undefined\n");
#endif
		break;
	    case XPATH_NODESET:
	    case XPATH_XSLT_TREE:
		ret = xmlXPathEqualNodeSets(arg1, arg2, 0);
		break;
	    case XPATH_BOOLEAN:
		if ((arg1->nodesetval == NULL) ||
		  (arg1->nodesetval->nodeNr == 0)) ret = 0;
		else
		    ret = 1;
		ret = (ret == arg2->boolval);
		break;
	    case XPATH_NUMBER:
		ret = xmlXPathEqualNodeSetFloat(ctxt, arg1, arg2->floatval, 0);
		break;
	    case XPATH_STRING:
		ret = xmlXPathEqualNodeSetString(arg1, arg2->stringval, 0);
		break;
	    case XPATH_USERS:
	    case XPATH_POINT:
	    case XPATH_RANGE:
	    case XPATH_LOCATIONSET:
		TODO
		break;
	}
	xmlXPathReleaseObject(ctxt->context, arg1);
	xmlXPathReleaseObject(ctxt->context, arg2);
	return(ret);
    }

    return (xmlXPathEqualValuesCommon(ctxt, arg1, arg2));
}

/**
 * xmlXPathNotEqualValues:
 * @ctxt:  the XPath Parser context
 *
 * Implement the equal operation on XPath objects content: @arg1 == @arg2
 *
 * Returns 0 or 1 depending on the results of the test.
 */
int
xmlXPathNotEqualValues(xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr arg1, arg2, argtmp;
    int ret = 0;

    if ((ctxt == NULL) || (ctxt->context == NULL)) return(0);
    arg2 = valuePop(ctxt);
    arg1 = valuePop(ctxt);
    if ((arg1 == NULL) || (arg2 == NULL)) {
	if (arg1 != NULL)
	    xmlXPathReleaseObject(ctxt->context, arg1);
	else
	    xmlXPathReleaseObject(ctxt->context, arg2);
	XP_ERROR0(XPATH_INVALID_OPERAND);
    }

    if (arg1 == arg2) {
#ifdef DEBUG_EXPR
        xmlGenericError(xmlGenericErrorContext,
		"NotEqual: by pointer\n");
#endif
	xmlXPathReleaseObject(ctxt->context, arg1);
        return(0);
    }

    /*
     *If either argument is a nodeset, it's a 'special case'
     */
    if ((arg2->type == XPATH_NODESET) || (arg2->type == XPATH_XSLT_TREE) ||
      (arg1->type == XPATH_NODESET) || (arg1->type == XPATH_XSLT_TREE)) {
	/*
	 *Hack it to assure arg1 is the nodeset
	 */
	if ((arg1->type != XPATH_NODESET) && (arg1->type != XPATH_XSLT_TREE)) {
		argtmp = arg2;
		arg2 = arg1;
		arg1 = argtmp;
	}
	switch (arg2->type) {
	    case XPATH_UNDEFINED:
#ifdef DEBUG_EXPR
		xmlGenericError(xmlGenericErrorContext,
			"NotEqual: undefined\n");
#endif
		break;
	    case XPATH_NODESET:
	    case XPATH_XSLT_TREE:
		ret = xmlXPathEqualNodeSets(arg1, arg2, 1);
		break;
	    case XPATH_BOOLEAN:
		if ((arg1->nodesetval == NULL) ||
		  (arg1->nodesetval->nodeNr == 0)) ret = 0;
		else
		    ret = 1;
		ret = (ret != arg2->boolval);
		break;
	    case XPATH_NUMBER:
		ret = xmlXPathEqualNodeSetFloat(ctxt, arg1, arg2->floatval, 1);
		break;
	    case XPATH_STRING:
		ret = xmlXPathEqualNodeSetString(arg1, arg2->stringval,1);
		break;
	    case XPATH_USERS:
	    case XPATH_POINT:
	    case XPATH_RANGE:
	    case XPATH_LOCATIONSET:
		TODO
		break;
	}
	xmlXPathReleaseObject(ctxt->context, arg1);
	xmlXPathReleaseObject(ctxt->context, arg2);
	return(ret);
    }

    return (!xmlXPathEqualValuesCommon(ctxt, arg1, arg2));
}

/**
 * xmlXPathCompareValues:
 * @ctxt:  the XPath Parser context
 * @inf:  less than (1) or greater than (0)
 * @strict:  is the comparison strict
 *
 * Implement the compare operation on XPath objects:
 *     @arg1 < @arg2    (1, 1, ...
 *     @arg1 <= @arg2   (1, 0, ...
 *     @arg1 > @arg2    (0, 1, ...
 *     @arg1 >= @arg2   (0, 0, ...
 *
 * When neither object to be compared is a node-set and the operator is
 * <=, <, >=, >, then the objects are compared by converted both objects
 * to numbers and comparing the numbers according to IEEE 754. The <
 * comparison will be true if and only if the first number is less than the
 * second number. The <= comparison will be true if and only if the first
 * number is less than or equal to the second number. The > comparison
 * will be true if and only if the first number is greater than the second
 * number. The >= comparison will be true if and only if the first number
 * is greater than or equal to the second number.
 *
 * Returns 1 if the comparison succeeded, 0 if it failed
 */
int
xmlXPathCompareValues(xmlXPathParserContextPtr ctxt, int inf, int strict) {
    int ret = 0, arg1i = 0, arg2i = 0;
    xmlXPathObjectPtr arg1, arg2;

    if ((ctxt == NULL) || (ctxt->context == NULL)) return(0);
    arg2 = valuePop(ctxt);
    arg1 = valuePop(ctxt);
    if ((arg1 == NULL) || (arg2 == NULL)) {
	if (arg1 != NULL)
	    xmlXPathReleaseObject(ctxt->context, arg1);
	else
	    xmlXPathReleaseObject(ctxt->context, arg2);
	XP_ERROR0(XPATH_INVALID_OPERAND);
    }

    if ((arg2->type == XPATH_NODESET) || (arg2->type == XPATH_XSLT_TREE) ||
      (arg1->type == XPATH_NODESET) || (arg1->type == XPATH_XSLT_TREE)) {
	/*
	 * If either argument is a XPATH_NODESET or XPATH_XSLT_TREE the two arguments
	 * are not freed from within this routine; they will be freed from the
	 * called routine, e.g. xmlXPathCompareNodeSets or xmlXPathCompareNodeSetValue
	 */
	if (((arg2->type == XPATH_NODESET) || (arg2->type == XPATH_XSLT_TREE)) &&
	  ((arg1->type == XPATH_NODESET) || (arg1->type == XPATH_XSLT_TREE))){
	    ret = xmlXPathCompareNodeSets(inf, strict, arg1, arg2);
	} else {
	    if ((arg1->type == XPATH_NODESET) || (arg1->type == XPATH_XSLT_TREE)) {
		ret = xmlXPathCompareNodeSetValue(ctxt, inf, strict,
			                          arg1, arg2);
	    } else {
		ret = xmlXPathCompareNodeSetValue(ctxt, !inf, strict,
			                          arg2, arg1);
	    }
	}
	return(ret);
    }

    if (arg1->type != XPATH_NUMBER) {
	valuePush(ctxt, arg1);
	xmlXPathNumberFunction(ctxt, 1);
	arg1 = valuePop(ctxt);
    }
    if (arg1->type != XPATH_NUMBER) {
	xmlXPathFreeObject(arg1);
	xmlXPathFreeObject(arg2);
	XP_ERROR0(XPATH_INVALID_OPERAND);
    }
    if (arg2->type != XPATH_NUMBER) {
	valuePush(ctxt, arg2);
	xmlXPathNumberFunction(ctxt, 1);
	arg2 = valuePop(ctxt);
    }
    if (arg2->type != XPATH_NUMBER) {
	xmlXPathReleaseObject(ctxt->context, arg1);
	xmlXPathReleaseObject(ctxt->context, arg2);
	XP_ERROR0(XPATH_INVALID_OPERAND);
    }
    /*
     * Add tests for infinity and nan
     * => feedback on 3.4 for Inf and NaN
     */
    /* Hand check NaN and Infinity comparisons */
    if (xmlXPathIsNaN(arg1->floatval) || xmlXPathIsNaN(arg2->floatval)) {
	ret=0;
    } else {
	arg1i=xmlXPathIsInf(arg1->floatval);
	arg2i=xmlXPathIsInf(arg2->floatval);
	if (inf && strict) {
	    if ((arg1i == -1 && arg2i != -1) ||
		(arg2i == 1 && arg1i != 1)) {
		ret = 1;
	    } else if (arg1i == 0 && arg2i == 0) {
		ret = (arg1->floatval < arg2->floatval);
	    } else {
		ret = 0;
	    }
	}
	else if (inf && !strict) {
	    if (arg1i == -1 || arg2i == 1) {
		ret = 1;
	    } else if (arg1i == 0 && arg2i == 0) {
		ret = (arg1->floatval <= arg2->floatval);
	    } else {
		ret = 0;
	    }
	}
	else if (!inf && strict) {
	    if ((arg1i == 1 && arg2i != 1) ||
		(arg2i == -1 && arg1i != -1)) {
		ret = 1;
	    } else if (arg1i == 0 && arg2i == 0) {
		ret = (arg1->floatval > arg2->floatval);
	    } else {
		ret = 0;
	    }
	}
	else if (!inf && !strict) {
	    if (arg1i == 1 || arg2i == -1) {
		ret = 1;
	    } else if (arg1i == 0 && arg2i == 0) {
		ret = (arg1->floatval >= arg2->floatval);
	    } else {
		ret = 0;
	    }
	}
    }
    xmlXPathReleaseObject(ctxt->context, arg1);
    xmlXPathReleaseObject(ctxt->context, arg2);
    return(ret);
}

/**
 * xmlXPathValueFlipSign:
 * @ctxt:  the XPath Parser context
 *
 * Implement the unary - operation on an XPath object
 * The numeric operators convert their operands to numbers as if
 * by calling the number function.
 */
void
xmlXPathValueFlipSign(xmlXPathParserContextPtr ctxt) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return;
    CAST_TO_NUMBER;
    CHECK_TYPE(XPATH_NUMBER);
    if (xmlXPathIsNaN(ctxt->value->floatval))
        ctxt->value->floatval=xmlXPathNAN;
    else if (xmlXPathIsInf(ctxt->value->floatval) == 1)
        ctxt->value->floatval=xmlXPathNINF;
    else if (xmlXPathIsInf(ctxt->value->floatval) == -1)
        ctxt->value->floatval=xmlXPathPINF;
    else if (ctxt->value->floatval == 0) {
        if (xmlXPathGetSign(ctxt->value->floatval) == 0)
	    ctxt->value->floatval = xmlXPathNZERO;
	else
	    ctxt->value->floatval = 0;
    }
    else
        ctxt->value->floatval = - ctxt->value->floatval;
}

/**
 * xmlXPathAddValues:
 * @ctxt:  the XPath Parser context
 *
 * Implement the add operation on XPath objects:
 * The numeric operators convert their operands to numbers as if
 * by calling the number function.
 */
void
xmlXPathAddValues(xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr arg;
    double val;

    arg = valuePop(ctxt);
    if (arg == NULL)
	XP_ERROR(XPATH_INVALID_OPERAND);
    val = xmlXPathCastToNumber(arg);
    xmlXPathReleaseObject(ctxt->context, arg);
    CAST_TO_NUMBER;
    CHECK_TYPE(XPATH_NUMBER);
    ctxt->value->floatval += val;
}

/**
 * xmlXPathSubValues:
 * @ctxt:  the XPath Parser context
 *
 * Implement the subtraction operation on XPath objects:
 * The numeric operators convert their operands to numbers as if
 * by calling the number function.
 */
void
xmlXPathSubValues(xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr arg;
    double val;

    arg = valuePop(ctxt);
    if (arg == NULL)
	XP_ERROR(XPATH_INVALID_OPERAND);
    val = xmlXPathCastToNumber(arg);
    xmlXPathReleaseObject(ctxt->context, arg);
    CAST_TO_NUMBER;
    CHECK_TYPE(XPATH_NUMBER);
    ctxt->value->floatval -= val;
}

/**
 * xmlXPathMultValues:
 * @ctxt:  the XPath Parser context
 *
 * Implement the multiply operation on XPath objects:
 * The numeric operators convert their operands to numbers as if
 * by calling the number function.
 */
void
xmlXPathMultValues(xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr arg;
    double val;

    arg = valuePop(ctxt);
    if (arg == NULL)
	XP_ERROR(XPATH_INVALID_OPERAND);
    val = xmlXPathCastToNumber(arg);
    xmlXPathReleaseObject(ctxt->context, arg);
    CAST_TO_NUMBER;
    CHECK_TYPE(XPATH_NUMBER);
    ctxt->value->floatval *= val;
}

/**
 * xmlXPathDivValues:
 * @ctxt:  the XPath Parser context
 *
 * Implement the div operation on XPath objects @arg1 / @arg2:
 * The numeric operators convert their operands to numbers as if
 * by calling the number function.
 */
void
xmlXPathDivValues(xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr arg;
    double val;

    arg = valuePop(ctxt);
    if (arg == NULL)
	XP_ERROR(XPATH_INVALID_OPERAND);
    val = xmlXPathCastToNumber(arg);
    xmlXPathReleaseObject(ctxt->context, arg);
    CAST_TO_NUMBER;
    CHECK_TYPE(XPATH_NUMBER);
    if (xmlXPathIsNaN(val) || xmlXPathIsNaN(ctxt->value->floatval))
	ctxt->value->floatval = xmlXPathNAN;
    else if (val == 0 && xmlXPathGetSign(val) != 0) {
	if (ctxt->value->floatval == 0)
	    ctxt->value->floatval = xmlXPathNAN;
	else if (ctxt->value->floatval > 0)
	    ctxt->value->floatval = xmlXPathNINF;
	else if (ctxt->value->floatval < 0)
	    ctxt->value->floatval = xmlXPathPINF;
    }
    else if (val == 0) {
	if (ctxt->value->floatval == 0)
	    ctxt->value->floatval = xmlXPathNAN;
	else if (ctxt->value->floatval > 0)
	    ctxt->value->floatval = xmlXPathPINF;
	else if (ctxt->value->floatval < 0)
	    ctxt->value->floatval = xmlXPathNINF;
    } else
	ctxt->value->floatval /= val;
}

/**
 * xmlXPathModValues:
 * @ctxt:  the XPath Parser context
 *
 * Implement the mod operation on XPath objects: @arg1 / @arg2
 * The numeric operators convert their operands to numbers as if
 * by calling the number function.
 */
void
xmlXPathModValues(xmlXPathParserContextPtr ctxt) {
    xmlXPathObjectPtr arg;
    double arg1, arg2;

    arg = valuePop(ctxt);
    if (arg == NULL)
	XP_ERROR(XPATH_INVALID_OPERAND);
    arg2 = xmlXPathCastToNumber(arg);
    xmlXPathReleaseObject(ctxt->context, arg);
    CAST_TO_NUMBER;
    CHECK_TYPE(XPATH_NUMBER);
    arg1 = ctxt->value->floatval;
    if (arg2 == 0)
	ctxt->value->floatval = xmlXPathNAN;
    else {
	ctxt->value->floatval = fmod(arg1, arg2);
    }
}

/************************************************************************
 *									*
 *		The traversal functions					*
 *									*
 ************************************************************************/

/*
 * A traversal function enumerates nodes along an axis.
 * Initially it must be called with NULL, and it indicates
 * termination on the axis by returning NULL.
 */
typedef xmlNodePtr (*xmlXPathTraversalFunction)
                    (xmlXPathParserContextPtr ctxt, xmlNodePtr cur);

/*
 * xmlXPathTraversalFunctionExt:
 * A traversal function enumerates nodes along an axis.
 * Initially it must be called with NULL, and it indicates
 * termination on the axis by returning NULL.
 * The context node of the traversal is specified via @contextNode.
 */
typedef xmlNodePtr (*xmlXPathTraversalFunctionExt)
                    (xmlNodePtr cur, xmlNodePtr contextNode);

/*
 * xmlXPathNodeSetMergeFunction:
 * Used for merging node sets in xmlXPathCollectAndTest().
 */
typedef xmlNodeSetPtr (*xmlXPathNodeSetMergeFunction)
		    (xmlNodeSetPtr, xmlNodeSetPtr, int);


/**
 * xmlXPathNextSelf:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "self" direction
 * The self axis contains just the context node itself
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextSelf(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if (cur == NULL)
        return(ctxt->context->node);
    return(NULL);
}

/**
 * xmlXPathNextChild:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "child" direction
 * The child axis contains the children of the context node in document order.
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextChild(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if (cur == NULL) {
	if (ctxt->context->node == NULL) return(NULL);
	switch (ctxt->context->node->type) {
            case XML_ELEMENT_NODE:
            case XML_TEXT_NODE:
            case XML_CDATA_SECTION_NODE:
            case XML_ENTITY_REF_NODE:
            case XML_ENTITY_NODE:
            case XML_PI_NODE:
            case XML_COMMENT_NODE:
            case XML_NOTATION_NODE:
            case XML_DTD_NODE:
		return(ctxt->context->node->children);
            case XML_DOCUMENT_NODE:
            case XML_DOCUMENT_TYPE_NODE:
            case XML_DOCUMENT_FRAG_NODE:
            case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
	    case XML_DOCB_DOCUMENT_NODE:
#endif
		return(((xmlDocPtr) ctxt->context->node)->children);
	    case XML_ELEMENT_DECL:
	    case XML_ATTRIBUTE_DECL:
	    case XML_ENTITY_DECL:
            case XML_ATTRIBUTE_NODE:
	    case XML_NAMESPACE_DECL:
	    case XML_XINCLUDE_START:
	    case XML_XINCLUDE_END:
		return(NULL);
	}
	return(NULL);
    }
    if ((cur->type == XML_DOCUMENT_NODE) ||
        (cur->type == XML_HTML_DOCUMENT_NODE))
	return(NULL);
    return(cur->next);
}

/**
 * xmlXPathNextChildElement:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "child" direction and nodes of type element.
 * The child axis contains the children of the context node in document order.
 *
 * Returns the next element following that axis
 */
static xmlNodePtr
xmlXPathNextChildElement(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if (cur == NULL) {
	cur = ctxt->context->node;
	if (cur == NULL) return(NULL);
	/*
	* Get the first element child.
	*/
	switch (cur->type) {
            case XML_ELEMENT_NODE:
	    case XML_DOCUMENT_FRAG_NODE:
	    case XML_ENTITY_REF_NODE: /* URGENT TODO: entify-refs as well? */
            case XML_ENTITY_NODE:
		cur = cur->children;
		if (cur != NULL) {
		    if (cur->type == XML_ELEMENT_NODE)
			return(cur);
		    do {
			cur = cur->next;
		    } while ((cur != NULL) &&
			(cur->type != XML_ELEMENT_NODE));
		    return(cur);
		}
		return(NULL);
            case XML_DOCUMENT_NODE:
            case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
	    case XML_DOCB_DOCUMENT_NODE:
#endif
		return(xmlDocGetRootElement((xmlDocPtr) cur));
	    default:
		return(NULL);
	}
	return(NULL);
    }
    /*
    * Get the next sibling element node.
    */
    switch (cur->type) {
	case XML_ELEMENT_NODE:
	case XML_TEXT_NODE:
	case XML_ENTITY_REF_NODE:
	case XML_ENTITY_NODE:
	case XML_CDATA_SECTION_NODE:
	case XML_PI_NODE:
	case XML_COMMENT_NODE:
	case XML_XINCLUDE_END:
	    break;
	/* case XML_DTD_NODE: */ /* URGENT TODO: DTD-node as well? */
	default:
	    return(NULL);
    }
    if (cur->next != NULL) {
	if (cur->next->type == XML_ELEMENT_NODE)
	    return(cur->next);
	cur = cur->next;
	do {
	    cur = cur->next;
	} while ((cur != NULL) && (cur->type != XML_ELEMENT_NODE));
	return(cur);
    }
    return(NULL);
}

/**
 * xmlXPathNextDescendantOrSelfElemParent:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "descendant-or-self" axis.
 * Additionally it returns only nodes which can be parents of
 * element nodes.
 *
 *
 * Returns the next element following that axis
 */
static xmlNodePtr
xmlXPathNextDescendantOrSelfElemParent(xmlNodePtr cur,
				       xmlNodePtr contextNode)
{
    if (cur == NULL) {
	if (contextNode == NULL)
	    return(NULL);
	switch (contextNode->type) {
	    case XML_ELEMENT_NODE:
	    case XML_XINCLUDE_START:
	    case XML_DOCUMENT_FRAG_NODE:
	    case XML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
	    case XML_DOCB_DOCUMENT_NODE:
#endif
	    case XML_HTML_DOCUMENT_NODE:	    
		return(contextNode);
	    default:
		return(NULL);
	}
	return(NULL);
    } else {
	xmlNodePtr start = cur;

	while (cur != NULL) {
	    switch (cur->type) {
		case XML_ELEMENT_NODE:
		/* TODO: OK to have XInclude here? */
		case XML_XINCLUDE_START:
		case XML_DOCUMENT_FRAG_NODE:
		    if (cur != start)
			return(cur);
		    if (cur->children != NULL) {
			cur = cur->children;
			continue;
		    }
		    break;
		/* Not sure if we need those here. */
		case XML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
		case XML_DOCB_DOCUMENT_NODE:
#endif
		case XML_HTML_DOCUMENT_NODE:
		    if (cur != start)
			return(cur);
		    return(xmlDocGetRootElement((xmlDocPtr) cur));
		default:
		    break;
	    }

next_sibling:
	    if ((cur == NULL) || (cur == contextNode))
		return(NULL);
	    if (cur->next != NULL) {
		cur = cur->next;
	    } else {
		cur = cur->parent;
		goto next_sibling;
	    }
	}
    }
    return(NULL);
}

/**
 * xmlXPathNextDescendant:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "descendant" direction
 * the descendant axis contains the descendants of the context node in document
 * order; a descendant is a child or a child of a child and so on.
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextDescendant(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if (cur == NULL) {
	if (ctxt->context->node == NULL)
	    return(NULL);
	if ((ctxt->context->node->type == XML_ATTRIBUTE_NODE) ||
	    (ctxt->context->node->type == XML_NAMESPACE_DECL))
	    return(NULL);

        if (ctxt->context->node == (xmlNodePtr) ctxt->context->doc)
	    return(ctxt->context->doc->children);
        return(ctxt->context->node->children);
    }

    if (cur->children != NULL) {
	/*
	 * Do not descend on entities declarations
	 */
	if (cur->children->type != XML_ENTITY_DECL) {
	    cur = cur->children;
	    /*
	     * Skip DTDs
	     */
	    if (cur->type != XML_DTD_NODE)
		return(cur);
	}
    }

    if (cur == ctxt->context->node) return(NULL);

    while (cur->next != NULL) {
	cur = cur->next;
	if ((cur->type != XML_ENTITY_DECL) &&
	    (cur->type != XML_DTD_NODE))
	    return(cur);
    }

    do {
        cur = cur->parent;
	if (cur == NULL) break;
	if (cur == ctxt->context->node) return(NULL);
	if (cur->next != NULL) {
	    cur = cur->next;
	    return(cur);
	}
    } while (cur != NULL);
    return(cur);
}

/**
 * xmlXPathNextDescendantOrSelf:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "descendant-or-self" direction
 * the descendant-or-self axis contains the context node and the descendants
 * of the context node in document order; thus the context node is the first
 * node on the axis, and the first child of the context node is the second node
 * on the axis
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextDescendantOrSelf(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if (cur == NULL) {
	if (ctxt->context->node == NULL)
	    return(NULL);
	if ((ctxt->context->node->type == XML_ATTRIBUTE_NODE) ||
	    (ctxt->context->node->type == XML_NAMESPACE_DECL))
	    return(NULL);
        return(ctxt->context->node);
    }

    return(xmlXPathNextDescendant(ctxt, cur));
}

/**
 * xmlXPathNextParent:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "parent" direction
 * The parent axis contains the parent of the context node, if there is one.
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextParent(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    /*
     * the parent of an attribute or namespace node is the element
     * to which the attribute or namespace node is attached
     * Namespace handling !!!
     */
    if (cur == NULL) {
	if (ctxt->context->node == NULL) return(NULL);
	switch (ctxt->context->node->type) {
            case XML_ELEMENT_NODE:
            case XML_TEXT_NODE:
            case XML_CDATA_SECTION_NODE:
            case XML_ENTITY_REF_NODE:
            case XML_ENTITY_NODE:
            case XML_PI_NODE:
            case XML_COMMENT_NODE:
            case XML_NOTATION_NODE:
            case XML_DTD_NODE:
	    case XML_ELEMENT_DECL:
	    case XML_ATTRIBUTE_DECL:
	    case XML_XINCLUDE_START:
	    case XML_XINCLUDE_END:
	    case XML_ENTITY_DECL:
		if (ctxt->context->node->parent == NULL)
		    return((xmlNodePtr) ctxt->context->doc);
		if ((ctxt->context->node->parent->type == XML_ELEMENT_NODE) &&
		    ((ctxt->context->node->parent->name[0] == ' ') ||
		     (xmlStrEqual(ctxt->context->node->parent->name,
				 BAD_CAST "fake node libxslt"))))
		    return(NULL);
		return(ctxt->context->node->parent);
            case XML_ATTRIBUTE_NODE: {
		xmlAttrPtr att = (xmlAttrPtr) ctxt->context->node;

		return(att->parent);
	    }
            case XML_DOCUMENT_NODE:
            case XML_DOCUMENT_TYPE_NODE:
            case XML_DOCUMENT_FRAG_NODE:
            case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
	    case XML_DOCB_DOCUMENT_NODE:
#endif
                return(NULL);
	    case XML_NAMESPACE_DECL: {
		xmlNsPtr ns = (xmlNsPtr) ctxt->context->node;

		if ((ns->next != NULL) &&
		    (ns->next->type != XML_NAMESPACE_DECL))
		    return((xmlNodePtr) ns->next);
                return(NULL);
	    }
	}
    }
    return(NULL);
}

/**
 * xmlXPathNextAncestor:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "ancestor" direction
 * the ancestor axis contains the ancestors of the context node; the ancestors
 * of the context node consist of the parent of context node and the parent's
 * parent and so on; the nodes are ordered in reverse document order; thus the
 * parent is the first node on the axis, and the parent's parent is the second
 * node on the axis
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextAncestor(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    /*
     * the parent of an attribute or namespace node is the element
     * to which the attribute or namespace node is attached
     * !!!!!!!!!!!!!
     */
    if (cur == NULL) {
	if (ctxt->context->node == NULL) return(NULL);
	switch (ctxt->context->node->type) {
            case XML_ELEMENT_NODE:
            case XML_TEXT_NODE:
            case XML_CDATA_SECTION_NODE:
            case XML_ENTITY_REF_NODE:
            case XML_ENTITY_NODE:
            case XML_PI_NODE:
            case XML_COMMENT_NODE:
	    case XML_DTD_NODE:
	    case XML_ELEMENT_DECL:
	    case XML_ATTRIBUTE_DECL:
	    case XML_ENTITY_DECL:
            case XML_NOTATION_NODE:
	    case XML_XINCLUDE_START:
	    case XML_XINCLUDE_END:
		if (ctxt->context->node->parent == NULL)
		    return((xmlNodePtr) ctxt->context->doc);
		if ((ctxt->context->node->parent->type == XML_ELEMENT_NODE) &&
		    ((ctxt->context->node->parent->name[0] == ' ') ||
		     (xmlStrEqual(ctxt->context->node->parent->name,
				 BAD_CAST "fake node libxslt"))))
		    return(NULL);
		return(ctxt->context->node->parent);
            case XML_ATTRIBUTE_NODE: {
		xmlAttrPtr tmp = (xmlAttrPtr) ctxt->context->node;

		return(tmp->parent);
	    }
            case XML_DOCUMENT_NODE:
            case XML_DOCUMENT_TYPE_NODE:
            case XML_DOCUMENT_FRAG_NODE:
            case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
	    case XML_DOCB_DOCUMENT_NODE:
#endif
                return(NULL);
	    case XML_NAMESPACE_DECL: {
		xmlNsPtr ns = (xmlNsPtr) ctxt->context->node;

		if ((ns->next != NULL) &&
		    (ns->next->type != XML_NAMESPACE_DECL))
		    return((xmlNodePtr) ns->next);
		/* Bad, how did that namespace end up here ? */
                return(NULL);
	    }
	}
	return(NULL);
    }
    if (cur == ctxt->context->doc->children)
	return((xmlNodePtr) ctxt->context->doc);
    if (cur == (xmlNodePtr) ctxt->context->doc)
	return(NULL);
    switch (cur->type) {
	case XML_ELEMENT_NODE:
	case XML_TEXT_NODE:
	case XML_CDATA_SECTION_NODE:
	case XML_ENTITY_REF_NODE:
	case XML_ENTITY_NODE:
	case XML_PI_NODE:
	case XML_COMMENT_NODE:
	case XML_NOTATION_NODE:
	case XML_DTD_NODE:
        case XML_ELEMENT_DECL:
        case XML_ATTRIBUTE_DECL:
        case XML_ENTITY_DECL:
	case XML_XINCLUDE_START:
	case XML_XINCLUDE_END:
	    if (cur->parent == NULL)
		return(NULL);
	    if ((cur->parent->type == XML_ELEMENT_NODE) &&
		((cur->parent->name[0] == ' ') ||
		 (xmlStrEqual(cur->parent->name,
			      BAD_CAST "fake node libxslt"))))
		return(NULL);
	    return(cur->parent);
	case XML_ATTRIBUTE_NODE: {
	    xmlAttrPtr att = (xmlAttrPtr) ctxt->context->node;

	    return(att->parent);
	}
	case XML_NAMESPACE_DECL: {
	    xmlNsPtr ns = (xmlNsPtr) ctxt->context->node;

	    if ((ns->next != NULL) &&
	        (ns->next->type != XML_NAMESPACE_DECL))
	        return((xmlNodePtr) ns->next);
	    /* Bad, how did that namespace end up here ? */
            return(NULL);
	}
	case XML_DOCUMENT_NODE:
	case XML_DOCUMENT_TYPE_NODE:
	case XML_DOCUMENT_FRAG_NODE:
	case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
	case XML_DOCB_DOCUMENT_NODE:
#endif
	    return(NULL);
    }
    return(NULL);
}

/**
 * xmlXPathNextAncestorOrSelf:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "ancestor-or-self" direction
 * he ancestor-or-self axis contains the context node and ancestors of
 * the context node in reverse document order; thus the context node is
 * the first node on the axis, and the context node's parent the second;
 * parent here is defined the same as with the parent axis.
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextAncestorOrSelf(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if (cur == NULL)
        return(ctxt->context->node);
    return(xmlXPathNextAncestor(ctxt, cur));
}

/**
 * xmlXPathNextFollowingSibling:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "following-sibling" direction
 * The following-sibling axis contains the following siblings of the context
 * node in document order.
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextFollowingSibling(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if ((ctxt->context->node->type == XML_ATTRIBUTE_NODE) ||
	(ctxt->context->node->type == XML_NAMESPACE_DECL))
	return(NULL);
    if (cur == (xmlNodePtr) ctxt->context->doc)
        return(NULL);
    if (cur == NULL)
        return(ctxt->context->node->next);
    return(cur->next);
}

/**
 * xmlXPathNextPrecedingSibling:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "preceding-sibling" direction
 * The preceding-sibling axis contains the preceding siblings of the context
 * node in reverse document order; the first preceding sibling is first on the
 * axis; the sibling preceding that node is the second on the axis and so on.
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextPrecedingSibling(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if ((ctxt->context->node->type == XML_ATTRIBUTE_NODE) ||
	(ctxt->context->node->type == XML_NAMESPACE_DECL))
	return(NULL);
    if (cur == (xmlNodePtr) ctxt->context->doc)
        return(NULL);
    if (cur == NULL)
        return(ctxt->context->node->prev);
    if ((cur->prev != NULL) && (cur->prev->type == XML_DTD_NODE)) {
	cur = cur->prev;
	if (cur == NULL)
	    return(ctxt->context->node->prev);
    }
    return(cur->prev);
}

/**
 * xmlXPathNextFollowing:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "following" direction
 * The following axis contains all nodes in the same document as the context
 * node that are after the context node in document order, excluding any
 * descendants and excluding attribute nodes and namespace nodes; the nodes
 * are ordered in document order
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextFollowing(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if ((cur != NULL) && (cur->type  != XML_ATTRIBUTE_NODE) &&
        (cur->type != XML_NAMESPACE_DECL) && (cur->children != NULL))
        return(cur->children);

    if (cur == NULL) {
        cur = ctxt->context->node;
        if (cur->type == XML_NAMESPACE_DECL)
            return(NULL);
        if (cur->type == XML_ATTRIBUTE_NODE)
            cur = cur->parent;
    }
    if (cur == NULL) return(NULL) ; /* ERROR */
    if (cur->next != NULL) return(cur->next) ;
    do {
        cur = cur->parent;
        if (cur == NULL) break;
        if (cur == (xmlNodePtr) ctxt->context->doc) return(NULL);
        if (cur->next != NULL) return(cur->next);
    } while (cur != NULL);
    return(cur);
}

/*
 * xmlXPathIsAncestor:
 * @ancestor:  the ancestor node
 * @node:  the current node
 *
 * Check that @ancestor is a @node's ancestor
 *
 * returns 1 if @ancestor is a @node's ancestor, 0 otherwise.
 */
static int
xmlXPathIsAncestor(xmlNodePtr ancestor, xmlNodePtr node) {
    if ((ancestor == NULL) || (node == NULL)) return(0);
    /* nodes need to be in the same document */
    if (ancestor->doc != node->doc) return(0);
    /* avoid searching if ancestor or node is the root node */
    if (ancestor == (xmlNodePtr) node->doc) return(1);
    if (node == (xmlNodePtr) ancestor->doc) return(0);
    while (node->parent != NULL) {
        if (node->parent == ancestor)
            return(1);
	node = node->parent;
    }
    return(0);
}

/**
 * xmlXPathNextPreceding:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "preceding" direction
 * the preceding axis contains all nodes in the same document as the context
 * node that are before the context node in document order, excluding any
 * ancestors and excluding attribute nodes and namespace nodes; the nodes are
 * ordered in reverse document order
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextPreceding(xmlXPathParserContextPtr ctxt, xmlNodePtr cur)
{
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if (cur == NULL) {
        cur = ctxt->context->node;
        if (cur->type == XML_NAMESPACE_DECL)
            return(NULL);
        if (cur->type == XML_ATTRIBUTE_NODE)
            return(cur->parent);
    }
    if (cur == NULL)
	return (NULL);
    if ((cur->prev != NULL) && (cur->prev->type == XML_DTD_NODE))
	cur = cur->prev;
    do {
        if (cur->prev != NULL) {
            for (cur = cur->prev; cur->last != NULL; cur = cur->last) ;
            return (cur);
        }

        cur = cur->parent;
        if (cur == NULL)
            return (NULL);
        if (cur == ctxt->context->doc->children)
            return (NULL);
    } while (xmlXPathIsAncestor(cur, ctxt->context->node));
    return (cur);
}

/**
 * xmlXPathNextPrecedingInternal:
 * @ctxt:  the XPath Parser context
 * @cur:  the current node in the traversal
 *
 * Traversal function for the "preceding" direction
 * the preceding axis contains all nodes in the same document as the context
 * node that are before the context node in document order, excluding any
 * ancestors and excluding attribute nodes and namespace nodes; the nodes are
 * ordered in reverse document order
 * This is a faster implementation but internal only since it requires a
 * state kept in the parser context: ctxt->ancestor.
 *
 * Returns the next element following that axis
 */
static xmlNodePtr
xmlXPathNextPrecedingInternal(xmlXPathParserContextPtr ctxt,
                              xmlNodePtr cur)
{
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if (cur == NULL) {
        cur = ctxt->context->node;
        if (cur == NULL)
            return (NULL);
        if (cur->type == XML_NAMESPACE_DECL)
            return (NULL);
        ctxt->ancestor = cur->parent;
    }
    if ((cur->prev != NULL) && (cur->prev->type == XML_DTD_NODE))
	cur = cur->prev;
    while (cur->prev == NULL) {
        cur = cur->parent;
        if (cur == NULL)
            return (NULL);
        if (cur == ctxt->context->doc->children)
            return (NULL);
        if (cur != ctxt->ancestor)
            return (cur);
        ctxt->ancestor = cur->parent;
    }
    cur = cur->prev;
    while (cur->last != NULL)
        cur = cur->last;
    return (cur);
}

/**
 * xmlXPathNextNamespace:
 * @ctxt:  the XPath Parser context
 * @cur:  the current attribute in the traversal
 *
 * Traversal function for the "namespace" direction
 * the namespace axis contains the namespace nodes of the context node;
 * the order of nodes on this axis is implementation-defined; the axis will
 * be empty unless the context node is an element
 *
 * We keep the XML namespace node at the end of the list.
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextNamespace(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if (ctxt->context->node->type != XML_ELEMENT_NODE) return(NULL);
    if (ctxt->context->tmpNsList == NULL && cur != (xmlNodePtr) xmlXPathXMLNamespace) {
        if (ctxt->context->tmpNsList != NULL)
	    xmlFree(ctxt->context->tmpNsList);
	ctxt->context->tmpNsList =
	    xmlGetNsList(ctxt->context->doc, ctxt->context->node);
	ctxt->context->tmpNsNr = 0;
	if (ctxt->context->tmpNsList != NULL) {
	    while (ctxt->context->tmpNsList[ctxt->context->tmpNsNr] != NULL) {
		ctxt->context->tmpNsNr++;
	    }
	}
	return((xmlNodePtr) xmlXPathXMLNamespace);
    }
    if (ctxt->context->tmpNsNr > 0) {
	return (xmlNodePtr)ctxt->context->tmpNsList[--ctxt->context->tmpNsNr];
    } else {
	if (ctxt->context->tmpNsList != NULL)
	    xmlFree(ctxt->context->tmpNsList);
	ctxt->context->tmpNsList = NULL;
	return(NULL);
    }
}

/**
 * xmlXPathNextAttribute:
 * @ctxt:  the XPath Parser context
 * @cur:  the current attribute in the traversal
 *
 * Traversal function for the "attribute" direction
 * TODO: support DTD inherited default attributes
 *
 * Returns the next element following that axis
 */
xmlNodePtr
xmlXPathNextAttribute(xmlXPathParserContextPtr ctxt, xmlNodePtr cur) {
    if ((ctxt == NULL) || (ctxt->context == NULL)) return(NULL);
    if (ctxt->context->node == NULL)
	return(NULL);
    if (ctxt->context->node->type != XML_ELEMENT_NODE)
	return(NULL);
    if (cur == NULL) {
        if (ctxt->context->node == (xmlNodePtr) ctxt->context->doc)
	    return(NULL);
        return((xmlNodePtr)ctxt->context->node->properties);
    }
    return((xmlNodePtr)cur->next);
}

/************************************************************************
 *									*
 *		NodeTest Functions					*
 *									*
 ************************************************************************/

#define IS_FUNCTION			200


/************************************************************************
 *									*
 *		Implicit tree core function library			*
 *									*
 ************************************************************************/

/**
 * xmlXPathRoot:
 * @ctxt:  the XPath Parser context
 *
 * Initialize the context to the root of the document
 */
void
xmlXPathRoot(xmlXPathParserContextPtr ctxt) {
    if ((ctxt == NULL) || (ctxt->context == NULL))
	return;
    ctxt->context->node = (xmlNodePtr) ctxt->context->doc;
    valuePush(ctxt, xmlXPathCacheNewNodeSet(ctxt->context,
	ctxt->context->node));
}

/************************************************************************
 *									*
 *		The explicit core function library			*
 *http://www.w3.org/Style/XSL/Group/1999/07/xpath-19990705.html#corelib	*
 *									*
 ************************************************************************/


/**
 * xmlXPathLastFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the last() XPath function
 *    number last()
 * The last function returns the number of nodes in the context node list.
 */
void
xmlXPathLastFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    CHECK_ARITY(0);
    if (ctxt->context->contextSize >= 0) {
	valuePush(ctxt,
	    xmlXPathCacheNewFloat(ctxt->context,
		(double) ctxt->context->contextSize));
#ifdef DEBUG_EXPR
	xmlGenericError(xmlGenericErrorContext,
		"last() : %d\n", ctxt->context->contextSize);
#endif
    } else {
	XP_ERROR(XPATH_INVALID_CTXT_SIZE);
    }
}

/**
 * xmlXPathPositionFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the position() XPath function
 *    number position()
 * The position function returns the position of the context node in the
 * context node list. The first position is 1, and so the last position
 * will be equal to last().
 */
void
xmlXPathPositionFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    CHECK_ARITY(0);
    if (ctxt->context->proximityPosition >= 0) {
	valuePush(ctxt,
	      xmlXPathCacheNewFloat(ctxt->context,
		(double) ctxt->context->proximityPosition));
#ifdef DEBUG_EXPR
	xmlGenericError(xmlGenericErrorContext, "position() : %d\n",
		ctxt->context->proximityPosition);
#endif
    } else {
	XP_ERROR(XPATH_INVALID_CTXT_POSITION);
    }
}

/**
 * xmlXPathCountFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the count() XPath function
 *    number count(node-set)
 */
void
xmlXPathCountFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr cur;

    CHECK_ARITY(1);
    if ((ctxt->value == NULL) ||
	((ctxt->value->type != XPATH_NODESET) &&
	 (ctxt->value->type != XPATH_XSLT_TREE)))
	XP_ERROR(XPATH_INVALID_TYPE);
    cur = valuePop(ctxt);

    if ((cur == NULL) || (cur->nodesetval == NULL))
	valuePush(ctxt, xmlXPathCacheNewFloat(ctxt->context, (double) 0));
    else if ((cur->type == XPATH_NODESET) || (cur->type == XPATH_XSLT_TREE)) {
	valuePush(ctxt, xmlXPathCacheNewFloat(ctxt->context,
	    (double) cur->nodesetval->nodeNr));
    } else {
	if ((cur->nodesetval->nodeNr != 1) ||
	    (cur->nodesetval->nodeTab == NULL)) {
	    valuePush(ctxt, xmlXPathCacheNewFloat(ctxt->context, (double) 0));
	} else {
	    xmlNodePtr tmp;
	    int i = 0;

	    tmp = cur->nodesetval->nodeTab[0];
	    if (tmp != NULL) {
		tmp = tmp->children;
		while (tmp != NULL) {
		    tmp = tmp->next;
		    i++;
		}
	    }
	    valuePush(ctxt, xmlXPathCacheNewFloat(ctxt->context, (double) i));
	}
    }
    xmlXPathReleaseObject(ctxt->context, cur);
}

/**
 * xmlXPathGetElementsByIds:
 * @doc:  the document
 * @ids:  a whitespace separated list of IDs
 *
 * Selects elements by their unique ID.
 *
 * Returns a node-set of selected elements.
 */
static xmlNodeSetPtr
xmlXPathGetElementsByIds (xmlDocPtr doc, const xmlChar *ids) {
    xmlNodeSetPtr ret;
    const xmlChar *cur = ids;
    xmlChar *ID;
    xmlAttrPtr attr;
    xmlNodePtr elem = NULL;

    if (ids == NULL) return(NULL);

    ret = xmlXPathNodeSetCreate(NULL);
    if (ret == NULL)
        return(ret);

    while (IS_BLANK_CH(*cur)) cur++;
    while (*cur != 0) {
	while ((!IS_BLANK_CH(*cur)) && (*cur != 0))
	    cur++;

        ID = xmlStrndup(ids, cur - ids);
	if (ID != NULL) {
	    /*
	     * We used to check the fact that the value passed
	     * was an NCName, but this generated much troubles for
	     * me and Aleksey Sanin, people blatantly violated that
	     * constaint, like Visa3D spec.
	     * if (xmlValidateNCName(ID, 1) == 0)
	     */
	    attr = xmlGetID(doc, ID);
	    if (attr != NULL) {
		if (attr->type == XML_ATTRIBUTE_NODE)
		    elem = attr->parent;
		else if (attr->type == XML_ELEMENT_NODE)
		    elem = (xmlNodePtr) attr;
		else
		    elem = NULL;
		if (elem != NULL)
		    xmlXPathNodeSetAdd(ret, elem);
	    }
	    xmlFree(ID);
	}

	while (IS_BLANK_CH(*cur)) cur++;
	ids = cur;
    }
    return(ret);
}

/**
 * xmlXPathIdFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the id() XPath function
 *    node-set id(object)
 * The id function selects elements by their unique ID
 * (see [5.2.1 Unique IDs]). When the argument to id is of type node-set,
 * then the result is the union of the result of applying id to the
 * string value of each of the nodes in the argument node-set. When the
 * argument to id is of any other type, the argument is converted to a
 * string as if by a call to the string function; the string is split
 * into a whitespace-separated list of tokens (whitespace is any sequence
 * of characters matching the production S); the result is a node-set
 * containing the elements in the same document as the context node that
 * have a unique ID equal to any of the tokens in the list.
 */
void
xmlXPathIdFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlChar *tokens;
    xmlNodeSetPtr ret;
    xmlXPathObjectPtr obj;

    CHECK_ARITY(1);
    obj = valuePop(ctxt);
    if (obj == NULL) XP_ERROR(XPATH_INVALID_OPERAND);
    if ((obj->type == XPATH_NODESET) || (obj->type == XPATH_XSLT_TREE)) {
	xmlNodeSetPtr ns;
	int i;

	ret = xmlXPathNodeSetCreate(NULL);
        /*
         * FIXME -- in an out-of-memory condition this will behave badly.
         * The solution is not clear -- we already popped an item from
         * ctxt, so the object is in a corrupt state.
         */

	if (obj->nodesetval != NULL) {
	    for (i = 0; i < obj->nodesetval->nodeNr; i++) {
		tokens =
		    xmlXPathCastNodeToString(obj->nodesetval->nodeTab[i]);
		ns = xmlXPathGetElementsByIds(ctxt->context->doc, tokens);
		ret = xmlXPathNodeSetMerge(ret, ns);
		xmlXPathFreeNodeSet(ns);
		if (tokens != NULL)
		    xmlFree(tokens);
	    }
	}
	xmlXPathReleaseObject(ctxt->context, obj);
	valuePush(ctxt, xmlXPathCacheWrapNodeSet(ctxt->context, ret));
	return;
    }
    obj = xmlXPathCacheConvertString(ctxt->context, obj);
    ret = xmlXPathGetElementsByIds(ctxt->context->doc, obj->stringval);
    valuePush(ctxt, xmlXPathCacheWrapNodeSet(ctxt->context, ret));
    xmlXPathReleaseObject(ctxt->context, obj);
    return;
}

/**
 * xmlXPathLocalNameFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the local-name() XPath function
 *    string local-name(node-set?)
 * The local-name function returns a string containing the local part
 * of the name of the node in the argument node-set that is first in
 * document order. If the node-set is empty or the first node has no
 * name, an empty string is returned. If the argument is omitted it
 * defaults to the context node.
 */
void
xmlXPathLocalNameFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr cur;

    if (ctxt == NULL) return;

    if (nargs == 0) {
	valuePush(ctxt, xmlXPathCacheNewNodeSet(ctxt->context,
	    ctxt->context->node));
	nargs = 1;
    }

    CHECK_ARITY(1);
    if ((ctxt->value == NULL) ||
	((ctxt->value->type != XPATH_NODESET) &&
	 (ctxt->value->type != XPATH_XSLT_TREE)))
	XP_ERROR(XPATH_INVALID_TYPE);
    cur = valuePop(ctxt);

    if ((cur->nodesetval == NULL) || (cur->nodesetval->nodeNr == 0)) {
	valuePush(ctxt, xmlXPathCacheNewCString(ctxt->context, ""));
    } else {
	int i = 0; /* Should be first in document order !!!!! */
	switch (cur->nodesetval->nodeTab[i]->type) {
	case XML_ELEMENT_NODE:
	case XML_ATTRIBUTE_NODE:
	case XML_PI_NODE:
	    if (cur->nodesetval->nodeTab[i]->name[0] == ' ')
		valuePush(ctxt, xmlXPathCacheNewCString(ctxt->context, ""));
	    else
		valuePush(ctxt,
		      xmlXPathCacheNewString(ctxt->context,
			cur->nodesetval->nodeTab[i]->name));
	    break;
	case XML_NAMESPACE_DECL:
	    valuePush(ctxt, xmlXPathCacheNewString(ctxt->context,
			((xmlNsPtr)cur->nodesetval->nodeTab[i])->prefix));
	    break;
	default:
	    valuePush(ctxt, xmlXPathCacheNewCString(ctxt->context, ""));
	}
    }
    xmlXPathReleaseObject(ctxt->context, cur);
}

/**
 * xmlXPathNamespaceURIFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the namespace-uri() XPath function
 *    string namespace-uri(node-set?)
 * The namespace-uri function returns a string containing the
 * namespace URI of the expanded name of the node in the argument
 * node-set that is first in document order. If the node-set is empty,
 * the first node has no name, or the expanded name has no namespace
 * URI, an empty string is returned. If the argument is omitted it
 * defaults to the context node.
 */
void
xmlXPathNamespaceURIFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr cur;

    if (ctxt == NULL) return;

    if (nargs == 0) {
	valuePush(ctxt, xmlXPathCacheNewNodeSet(ctxt->context,
	    ctxt->context->node));
	nargs = 1;
    }
    CHECK_ARITY(1);
    if ((ctxt->value == NULL) ||
	((ctxt->value->type != XPATH_NODESET) &&
	 (ctxt->value->type != XPATH_XSLT_TREE)))
	XP_ERROR(XPATH_INVALID_TYPE);
    cur = valuePop(ctxt);

    if ((cur->nodesetval == NULL) || (cur->nodesetval->nodeNr == 0)) {
	valuePush(ctxt, xmlXPathCacheNewCString(ctxt->context, ""));
    } else {
	int i = 0; /* Should be first in document order !!!!! */
	switch (cur->nodesetval->nodeTab[i]->type) {
	case XML_ELEMENT_NODE:
	case XML_ATTRIBUTE_NODE:
	    if (cur->nodesetval->nodeTab[i]->ns == NULL)
		valuePush(ctxt, xmlXPathCacheNewCString(ctxt->context, ""));
	    else
		valuePush(ctxt, xmlXPathCacheNewString(ctxt->context,
			  cur->nodesetval->nodeTab[i]->ns->href));
	    break;
	default:
	    valuePush(ctxt, xmlXPathCacheNewCString(ctxt->context, ""));
	}
    }
    xmlXPathReleaseObject(ctxt->context, cur);
}

/**
 * xmlXPathNameFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the name() XPath function
 *    string name(node-set?)
 * The name function returns a string containing a QName representing
 * the name of the node in the argument node-set that is first in document
 * order. The QName must represent the name with respect to the namespace
 * declarations in effect on the node whose name is being represented.
 * Typically, this will be the form in which the name occurred in the XML
 * source. This need not be the case if there are namespace declarations
 * in effect on the node that associate multiple prefixes with the same
 * namespace. However, an implementation may include information about
 * the original prefix in its representation of nodes; in this case, an
 * implementation can ensure that the returned string is always the same
 * as the QName used in the XML source. If the argument it omitted it
 * defaults to the context node.
 * Libxml keep the original prefix so the "real qualified name" used is
 * returned.
 */
static void
xmlXPathNameFunction(xmlXPathParserContextPtr ctxt, int nargs)
{
    xmlXPathObjectPtr cur;

    if (nargs == 0) {
	valuePush(ctxt, xmlXPathCacheNewNodeSet(ctxt->context,
	    ctxt->context->node));
        nargs = 1;
    }

    CHECK_ARITY(1);
    if ((ctxt->value == NULL) ||
        ((ctxt->value->type != XPATH_NODESET) &&
         (ctxt->value->type != XPATH_XSLT_TREE)))
        XP_ERROR(XPATH_INVALID_TYPE);
    cur = valuePop(ctxt);

    if ((cur->nodesetval == NULL) || (cur->nodesetval->nodeNr == 0)) {
        valuePush(ctxt, xmlXPathCacheNewCString(ctxt->context, ""));
    } else {
        int i = 0;              /* Should be first in document order !!!!! */

        switch (cur->nodesetval->nodeTab[i]->type) {
            case XML_ELEMENT_NODE:
            case XML_ATTRIBUTE_NODE:
		if (cur->nodesetval->nodeTab[i]->name[0] == ' ')
		    valuePush(ctxt,
			xmlXPathCacheNewCString(ctxt->context, ""));
		else if ((cur->nodesetval->nodeTab[i]->ns == NULL) ||
                         (cur->nodesetval->nodeTab[i]->ns->prefix == NULL)) {
		    valuePush(ctxt,
		        xmlXPathCacheNewString(ctxt->context,
			    cur->nodesetval->nodeTab[i]->name));
		} else {
		    xmlChar *fullname;

		    fullname = xmlBuildQName(cur->nodesetval->nodeTab[i]->name,
				     cur->nodesetval->nodeTab[i]->ns->prefix,
				     NULL, 0);
		    if (fullname == cur->nodesetval->nodeTab[i]->name)
			fullname = xmlStrdup(cur->nodesetval->nodeTab[i]->name);
		    if (fullname == NULL) {
			XP_ERROR(XPATH_MEMORY_ERROR);
		    }
		    valuePush(ctxt, xmlXPathCacheWrapString(
			ctxt->context, fullname));
                }
                break;
            default:
		valuePush(ctxt, xmlXPathCacheNewNodeSet(ctxt->context,
		    cur->nodesetval->nodeTab[i]));
                xmlXPathLocalNameFunction(ctxt, 1);
        }
    }
    xmlXPathReleaseObject(ctxt->context, cur);
}


/**
 * xmlXPathStringFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the string() XPath function
 *    string string(object?)
 * The string function converts an object to a string as follows:
 *    - A node-set is converted to a string by returning the value of
 *      the node in the node-set that is first in document order.
 *      If the node-set is empty, an empty string is returned.
 *    - A number is converted to a string as follows
 *      + NaN is converted to the string NaN
 *      + positive zero is converted to the string 0
 *      + negative zero is converted to the string 0
 *      + positive infinity is converted to the string Infinity
 *      + negative infinity is converted to the string -Infinity
 *      + if the number is an integer, the number is represented in
 *        decimal form as a Number with no decimal point and no leading
 *        zeros, preceded by a minus sign (-) if the number is negative
 *      + otherwise, the number is represented in decimal form as a
 *        Number including a decimal point with at least one digit
 *        before the decimal point and at least one digit after the
 *        decimal point, preceded by a minus sign (-) if the number
 *        is negative; there must be no leading zeros before the decimal
 *        point apart possibly from the one required digit immediately
 *        before the decimal point; beyond the one required digit
 *        after the decimal point there must be as many, but only as
 *        many, more digits as are needed to uniquely distinguish the
 *        number from all other IEEE 754 numeric values.
 *    - The boolean false value is converted to the string false.
 *      The boolean true value is converted to the string true.
 *
 * If the argument is omitted, it defaults to a node-set with the
 * context node as its only member.
 */
void
xmlXPathStringFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr cur;

    if (ctxt == NULL) return;
    if (nargs == 0) {
    valuePush(ctxt,
	xmlXPathCacheWrapString(ctxt->context,
	    xmlXPathCastNodeToString(ctxt->context->node)));
	return;
    }

    CHECK_ARITY(1);
    cur = valuePop(ctxt);
    if (cur == NULL) XP_ERROR(XPATH_INVALID_OPERAND);
    valuePush(ctxt, xmlXPathCacheConvertString(ctxt->context, cur));
}

/**
 * xmlXPathStringLengthFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the string-length() XPath function
 *    number string-length(string?)
 * The string-length returns the number of characters in the string
 * (see [3.6 Strings]). If the argument is omitted, it defaults to
 * the context node converted to a string, in other words the value
 * of the context node.
 */
void
xmlXPathStringLengthFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr cur;

    if (nargs == 0) {
        if ((ctxt == NULL) || (ctxt->context == NULL))
	    return;
	if (ctxt->context->node == NULL) {
	    valuePush(ctxt, xmlXPathCacheNewFloat(ctxt->context, 0));
	} else {
	    xmlChar *content;

	    content = xmlXPathCastNodeToString(ctxt->context->node);
	    valuePush(ctxt, xmlXPathCacheNewFloat(ctxt->context,
		xmlUTF8Strlen(content)));
	    xmlFree(content);
	}
	return;
    }
    CHECK_ARITY(1);
    CAST_TO_STRING;
    CHECK_TYPE(XPATH_STRING);
    cur = valuePop(ctxt);
    valuePush(ctxt, xmlXPathCacheNewFloat(ctxt->context,
	xmlUTF8Strlen(cur->stringval)));
    xmlXPathReleaseObject(ctxt->context, cur);
}

/**
 * xmlXPathConcatFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the concat() XPath function
 *    string concat(string, string, string*)
 * The concat function returns the concatenation of its arguments.
 */
void
xmlXPathConcatFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr cur, newobj;
    xmlChar *tmp;

    if (ctxt == NULL) return;
    if (nargs < 2) {
	CHECK_ARITY(2);
    }

    CAST_TO_STRING;
    cur = valuePop(ctxt);
    if ((cur == NULL) || (cur->type != XPATH_STRING)) {
	xmlXPathReleaseObject(ctxt->context, cur);
	return;
    }
    nargs--;

    while (nargs > 0) {
	CAST_TO_STRING;
	newobj = valuePop(ctxt);
	if ((newobj == NULL) || (newobj->type != XPATH_STRING)) {
	    xmlXPathReleaseObject(ctxt->context, newobj);
	    xmlXPathReleaseObject(ctxt->context, cur);
	    XP_ERROR(XPATH_INVALID_TYPE);
	}
	tmp = xmlStrcat(newobj->stringval, cur->stringval);
	newobj->stringval = cur->stringval;
	cur->stringval = tmp;
	xmlXPathReleaseObject(ctxt->context, newobj);
	nargs--;
    }
    valuePush(ctxt, cur);
}

/**
 * xmlXPathContainsFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the contains() XPath function
 *    boolean contains(string, string)
 * The contains function returns true if the first argument string
 * contains the second argument string, and otherwise returns false.
 */
void
xmlXPathContainsFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr hay, needle;

    CHECK_ARITY(2);
    CAST_TO_STRING;
    CHECK_TYPE(XPATH_STRING);
    needle = valuePop(ctxt);
    CAST_TO_STRING;
    hay = valuePop(ctxt);

    if ((hay == NULL) || (hay->type != XPATH_STRING)) {
	xmlXPathReleaseObject(ctxt->context, hay);
	xmlXPathReleaseObject(ctxt->context, needle);
	XP_ERROR(XPATH_INVALID_TYPE);
    }
    if (xmlStrstr(hay->stringval, needle->stringval))
	valuePush(ctxt, xmlXPathCacheNewBoolean(ctxt->context, 1));
    else
	valuePush(ctxt, xmlXPathCacheNewBoolean(ctxt->context, 0));
    xmlXPathReleaseObject(ctxt->context, hay);
    xmlXPathReleaseObject(ctxt->context, needle);
}

/**
 * xmlXPathStartsWithFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the starts-with() XPath function
 *    boolean starts-with(string, string)
 * The starts-with function returns true if the first argument string
 * starts with the second argument string, and otherwise returns false.
 */
void
xmlXPathStartsWithFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr hay, needle;
    int n;

    CHECK_ARITY(2);
    CAST_TO_STRING;
    CHECK_TYPE(XPATH_STRING);
    needle = valuePop(ctxt);
    CAST_TO_STRING;
    hay = valuePop(ctxt);

    if ((hay == NULL) || (hay->type != XPATH_STRING)) {
	xmlXPathReleaseObject(ctxt->context, hay);
	xmlXPathReleaseObject(ctxt->context, needle);
	XP_ERROR(XPATH_INVALID_TYPE);
    }
    n = xmlStrlen(needle->stringval);
    if (xmlStrncmp(hay->stringval, needle->stringval, n))
        valuePush(ctxt, xmlXPathCacheNewBoolean(ctxt->context, 0));
    else
        valuePush(ctxt, xmlXPathCacheNewBoolean(ctxt->context, 1));
    xmlXPathReleaseObject(ctxt->context, hay);
    xmlXPathReleaseObject(ctxt->context, needle);
}

/**
 * xmlXPathSubstringFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the substring() XPath function
 *    string substring(string, number, number?)
 * The substring function returns the substring of the first argument
 * starting at the position specified in the second argument with
 * length specified in the third argument. For example,
 * substring("12345",2,3) returns "234". If the third argument is not
 * specified, it returns the substring starting at the position specified
 * in the second argument and continuing to the end of the string. For
 * example, substring("12345",2) returns "2345".  More precisely, each
 * character in the string (see [3.6 Strings]) is considered to have a
 * numeric position: the position of the first character is 1, the position
 * of the second character is 2 and so on. The returned substring contains
 * those characters for which the position of the character is greater than
 * or equal to the second argument and, if the third argument is specified,
 * less than the sum of the second and third arguments; the comparisons
 * and addition used for the above follow the standard IEEE 754 rules. Thus:
 *  - substring("12345", 1.5, 2.6) returns "234"
 *  - substring("12345", 0, 3) returns "12"
 *  - substring("12345", 0 div 0, 3) returns ""
 *  - substring("12345", 1, 0 div 0) returns ""
 *  - substring("12345", -42, 1 div 0) returns "12345"
 *  - substring("12345", -1 div 0, 1 div 0) returns ""
 */
void
xmlXPathSubstringFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr str, start, len;
    double le=0, in;
    int i, l, m;
    xmlChar *ret;

    if (nargs < 2) {
	CHECK_ARITY(2);
    }
    if (nargs > 3) {
	CHECK_ARITY(3);
    }
    /*
     * take care of possible last (position) argument
    */
    if (nargs == 3) {
	CAST_TO_NUMBER;
	CHECK_TYPE(XPATH_NUMBER);
	len = valuePop(ctxt);
	le = len->floatval;
	xmlXPathReleaseObject(ctxt->context, len);
    }

    CAST_TO_NUMBER;
    CHECK_TYPE(XPATH_NUMBER);
    start = valuePop(ctxt);
    in = start->floatval;
    xmlXPathReleaseObject(ctxt->context, start);
    CAST_TO_STRING;
    CHECK_TYPE(XPATH_STRING);
    str = valuePop(ctxt);
    m = xmlUTF8Strlen((const unsigned char *)str->stringval);

    /*
     * If last pos not present, calculate last position
    */
    if (nargs != 3) {
	le = (double)m;
	if (in < 1.0)
	    in = 1.0;
    }

    /* Need to check for the special cases where either
     * the index is NaN, the length is NaN, or both
     * arguments are infinity (relying on Inf + -Inf = NaN)
     */
    if (!xmlXPathIsInf(in) && !xmlXPathIsNaN(in + le)) {
        /*
         * To meet the requirements of the spec, the arguments
	 * must be converted to integer format before
	 * initial index calculations are done
         *
         * First we go to integer form, rounding up
	 * and checking for special cases
         */
        i = (int) in;
        if (((double)i)+0.5 <= in) i++;

	if (xmlXPathIsInf(le) == 1) {
	    l = m;
	    if (i < 1)
		i = 1;
	}
	else if (xmlXPathIsInf(le) == -1 || le < 0.0)
	    l = 0;
	else {
	    l = (int) le;
	    if (((double)l)+0.5 <= le) l++;
	}

	/* Now we normalize inidices */
        i -= 1;
        l += i;
        if (i < 0)
            i = 0;
        if (l > m)
            l = m;

        /* number of chars to copy */
        l -= i;

        ret = xmlUTF8Strsub(str->stringval, i, l);
    }
    else {
        ret = NULL;
    }
    if (ret == NULL)
	valuePush(ctxt, xmlXPathCacheNewCString(ctxt->context, ""));
    else {
	valuePush(ctxt, xmlXPathCacheNewString(ctxt->context, ret));
	xmlFree(ret);
    }
    xmlXPathReleaseObject(ctxt->context, str);
}

/**
 * xmlXPathSubstringBeforeFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the substring-before() XPath function
 *    string substring-before(string, string)
 * The substring-before function returns the substring of the first
 * argument string that precedes the first occurrence of the second
 * argument string in the first argument string, or the empty string
 * if the first argument string does not contain the second argument
 * string. For example, substring-before("1999/04/01","/") returns 1999.
 */
void
xmlXPathSubstringBeforeFunction(xmlXPathParserContextPtr ctxt, int nargs) {
  xmlXPathObjectPtr str;
  xmlXPathObjectPtr find;
  xmlBufferPtr target;
  const xmlChar *point;
  int offset;

  CHECK_ARITY(2);
  CAST_TO_STRING;
  find = valuePop(ctxt);
  CAST_TO_STRING;
  str = valuePop(ctxt);

  target = xmlBufferCreate();
  if (target) {
    point = xmlStrstr(str->stringval, find->stringval);
    if (point) {
      offset = (int)(point - str->stringval);
      xmlBufferAdd(target, str->stringval, offset);
    }
    valuePush(ctxt, xmlXPathCacheNewString(ctxt->context,
	xmlBufferContent(target)));
    xmlBufferFree(target);
  }
  xmlXPathReleaseObject(ctxt->context, str);
  xmlXPathReleaseObject(ctxt->context, find);
}

/**
 * xmlXPathSubstringAfterFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the substring-after() XPath function
 *    string substring-after(string, string)
 * The substring-after function returns the substring of the first
 * argument string that follows the first occurrence of the second
 * argument string in the first argument string, or the empty stringi
 * if the first argument string does not contain the second argument
 * string. For example, substring-after("1999/04/01","/") returns 04/01,
 * and substring-after("1999/04/01","19") returns 99/04/01.
 */
void
xmlXPathSubstringAfterFunction(xmlXPathParserContextPtr ctxt, int nargs) {
  xmlXPathObjectPtr str;
  xmlXPathObjectPtr find;
  xmlBufferPtr target;
  const xmlChar *point;
  int offset;

  CHECK_ARITY(2);
  CAST_TO_STRING;
  find = valuePop(ctxt);
  CAST_TO_STRING;
  str = valuePop(ctxt);

  target = xmlBufferCreate();
  if (target) {
    point = xmlStrstr(str->stringval, find->stringval);
    if (point) {
      offset = (int)(point - str->stringval) + xmlStrlen(find->stringval);
      xmlBufferAdd(target, &str->stringval[offset],
		   xmlStrlen(str->stringval) - offset);
    }
    valuePush(ctxt, xmlXPathCacheNewString(ctxt->context,
	xmlBufferContent(target)));
    xmlBufferFree(target);
  }
  xmlXPathReleaseObject(ctxt->context, str);
  xmlXPathReleaseObject(ctxt->context, find);
}

/**
 * xmlXPathNormalizeFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the normalize-space() XPath function
 *    string normalize-space(string?)
 * The normalize-space function returns the argument string with white
 * space normalized by stripping leading and trailing whitespace
 * and replacing sequences of whitespace characters by a single
 * space. Whitespace characters are the same allowed by the S production
 * in XML. If the argument is omitted, it defaults to the context
 * node converted to a string, in other words the value of the context node.
 */
void
xmlXPathNormalizeFunction(xmlXPathParserContextPtr ctxt, int nargs) {
  xmlXPathObjectPtr obj = NULL;
  xmlChar *source = NULL;
  xmlBufferPtr target;
  xmlChar blank;

  if (ctxt == NULL) return;
  if (nargs == 0) {
    /* Use current context node */
      valuePush(ctxt,
	  xmlXPathCacheWrapString(ctxt->context,
	    xmlXPathCastNodeToString(ctxt->context->node)));
    nargs = 1;
  }

  CHECK_ARITY(1);
  CAST_TO_STRING;
  CHECK_TYPE(XPATH_STRING);
  obj = valuePop(ctxt);
  source = obj->stringval;

  target = xmlBufferCreate();
  if (target && source) {

    /* Skip leading whitespaces */
    while (IS_BLANK_CH(*source))
      source++;

    /* Collapse intermediate whitespaces, and skip trailing whitespaces */
    blank = 0;
    while (*source) {
      if (IS_BLANK_CH(*source)) {
	blank = 0x20;
      } else {
	if (blank) {
	  xmlBufferAdd(target, &blank, 1);
	  blank = 0;
	}
	xmlBufferAdd(target, source, 1);
      }
      source++;
    }
    valuePush(ctxt, xmlXPathCacheNewString(ctxt->context,
	xmlBufferContent(target)));
    xmlBufferFree(target);
  }
  xmlXPathReleaseObject(ctxt->context, obj);
}

/**
 * xmlXPathTranslateFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the translate() XPath function
 *    string translate(string, string, string)
 * The translate function returns the first argument string with
 * occurrences of characters in the second argument string replaced
 * by the character at the corresponding position in the third argument
 * string. For example, translate("bar","abc","ABC") returns the string
 * BAr. If there is a character in the second argument string with no
 * character at a corresponding position in the third argument string
 * (because the second argument string is longer than the third argument
 * string), then occurrences of that character in the first argument
 * string are removed. For example, translate("--aaa--","abc-","ABC")
 * returns "AAA". If a character occurs more than once in second
 * argument string, then the first occurrence determines the replacement
 * character. If the third argument string is longer than the second
 * argument string, then excess characters are ignored.
 */
void
xmlXPathTranslateFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr str;
    xmlXPathObjectPtr from;
    xmlXPathObjectPtr to;
    xmlBufferPtr target;
    int offset, max;
    xmlChar ch;
    const xmlChar *point;
    xmlChar *cptr;

    CHECK_ARITY(3);

    CAST_TO_STRING;
    to = valuePop(ctxt);
    CAST_TO_STRING;
    from = valuePop(ctxt);
    CAST_TO_STRING;
    str = valuePop(ctxt);

    target = xmlBufferCreate();
    if (target) {
	max = xmlUTF8Strlen(to->stringval);
	for (cptr = str->stringval; (ch=*cptr); ) {
	    offset = xmlUTF8Strloc(from->stringval, cptr);
	    if (offset >= 0) {
		if (offset < max) {
		    point = xmlUTF8Strpos(to->stringval, offset);
		    if (point)
			xmlBufferAdd(target, point, xmlUTF8Strsize(point, 1));
		}
	    } else
		xmlBufferAdd(target, cptr, xmlUTF8Strsize(cptr, 1));

	    /* Step to next character in input */
	    cptr++;
	    if ( ch & 0x80 ) {
		/* if not simple ascii, verify proper format */
		if ( (ch & 0xc0) != 0xc0 ) {
		    xmlGenericError(xmlGenericErrorContext,
			"xmlXPathTranslateFunction: Invalid UTF8 string\n");
		    break;
		}
		/* then skip over remaining bytes for this char */
		while ( (ch <<= 1) & 0x80 )
		    if ( (*cptr++ & 0xc0) != 0x80 ) {
			xmlGenericError(xmlGenericErrorContext,
			    "xmlXPathTranslateFunction: Invalid UTF8 string\n");
			break;
		    }
		if (ch & 0x80) /* must have had error encountered */
		    break;
	    }
	}
    }
    valuePush(ctxt, xmlXPathCacheNewString(ctxt->context,
	xmlBufferContent(target)));
    xmlBufferFree(target);
    xmlXPathReleaseObject(ctxt->context, str);
    xmlXPathReleaseObject(ctxt->context, from);
    xmlXPathReleaseObject(ctxt->context, to);
}

/**
 * xmlXPathBooleanFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the boolean() XPath function
 *    boolean boolean(object)
 * The boolean function converts its argument to a boolean as follows:
 *    - a number is true if and only if it is neither positive or
 *      negative zero nor NaN
 *    - a node-set is true if and only if it is non-empty
 *    - a string is true if and only if its length is non-zero
 */
void
xmlXPathBooleanFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr cur;

    CHECK_ARITY(1);
    cur = valuePop(ctxt);
    if (cur == NULL) XP_ERROR(XPATH_INVALID_OPERAND);
    cur = xmlXPathCacheConvertBoolean(ctxt->context, cur);
    valuePush(ctxt, cur);
}

/**
 * xmlXPathNotFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the not() XPath function
 *    boolean not(boolean)
 * The not function returns true if its argument is false,
 * and false otherwise.
 */
void
xmlXPathNotFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    CHECK_ARITY(1);
    CAST_TO_BOOLEAN;
    CHECK_TYPE(XPATH_BOOLEAN);
    ctxt->value->boolval = ! ctxt->value->boolval;
}

/**
 * xmlXPathTrueFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the true() XPath function
 *    boolean true()
 */
void
xmlXPathTrueFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    CHECK_ARITY(0);
    valuePush(ctxt, xmlXPathCacheNewBoolean(ctxt->context, 1));
}

/**
 * xmlXPathFalseFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the false() XPath function
 *    boolean false()
 */
void
xmlXPathFalseFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    CHECK_ARITY(0);
    valuePush(ctxt, xmlXPathCacheNewBoolean(ctxt->context, 0));
}

/**
 * xmlXPathLangFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the lang() XPath function
 *    boolean lang(string)
 * The lang function returns true or false depending on whether the
 * language of the context node as specified by xml:lang attributes
 * is the same as or is a sublanguage of the language specified by
 * the argument string. The language of the context node is determined
 * by the value of the xml:lang attribute on the context node, or, if
 * the context node has no xml:lang attribute, by the value of the
 * xml:lang attribute on the nearest ancestor of the context node that
 * has an xml:lang attribute. If there is no such attribute, then lang
 * returns false. If there is such an attribute, then lang returns
 * true if the attribute value is equal to the argument ignoring case,
 * or if there is some suffix starting with - such that the attribute
 * value is equal to the argument ignoring that suffix of the attribute
 * value and ignoring case.
 */
void
xmlXPathLangFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr val = NULL;
    const xmlChar *theLang = NULL;
    const xmlChar *lang;
    int ret = 0;
    int i;

    CHECK_ARITY(1);
    CAST_TO_STRING;
    CHECK_TYPE(XPATH_STRING);
    val = valuePop(ctxt);
    lang = val->stringval;
    theLang = xmlNodeGetLang(ctxt->context->node);
    if ((theLang != NULL) && (lang != NULL)) {
        for (i = 0;lang[i] != 0;i++)
	    if (toupper(lang[i]) != toupper(theLang[i]))
	        goto not_equal;
	if ((theLang[i] == 0) || (theLang[i] == '-'))
	    ret = 1;
    }
not_equal:
    if (theLang != NULL)
	xmlFree((void *)theLang);

    xmlXPathReleaseObject(ctxt->context, val);
    valuePush(ctxt, xmlXPathCacheNewBoolean(ctxt->context, ret));
}

/**
 * xmlXPathNumberFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the number() XPath function
 *    number number(object?)
 */
void
xmlXPathNumberFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr cur;
    double res;

    if (ctxt == NULL) return;
    if (nargs == 0) {
	if (ctxt->context->node == NULL) {
	    valuePush(ctxt, xmlXPathCacheNewFloat(ctxt->context, 0.0));
	} else {
	    xmlChar* content = xmlNodeGetContent(ctxt->context->node);

	    res = xmlXPathStringEvalNumber(content);
	    valuePush(ctxt, xmlXPathCacheNewFloat(ctxt->context, res));
	    xmlFree(content);
	}
	return;
    }

    CHECK_ARITY(1);
    cur = valuePop(ctxt);
    valuePush(ctxt, xmlXPathCacheConvertNumber(ctxt->context, cur));
}

/**
 * xmlXPathSumFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the sum() XPath function
 *    number sum(node-set)
 * The sum function returns the sum of the values of the nodes in
 * the argument node-set.
 */
void
xmlXPathSumFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr cur;
    int i;
    double res = 0.0;

    CHECK_ARITY(1);
    if ((ctxt->value == NULL) ||
	((ctxt->value->type != XPATH_NODESET) &&
	 (ctxt->value->type != XPATH_XSLT_TREE)))
	XP_ERROR(XPATH_INVALID_TYPE);
    cur = valuePop(ctxt);

    if ((cur->nodesetval != NULL) && (cur->nodesetval->nodeNr != 0)) {
	for (i = 0; i < cur->nodesetval->nodeNr; i++) {
	    res += xmlXPathCastNodeToNumber(cur->nodesetval->nodeTab[i]);
	}
    }
    valuePush(ctxt, xmlXPathCacheNewFloat(ctxt->context, res));
    xmlXPathReleaseObject(ctxt->context, cur);
}

/*
 * To assure working code on multiple platforms, we want to only depend
 * upon the characteristic truncation of converting a floating point value
 * to an integer.  Unfortunately, because of the different storage sizes
 * of our internal floating point value (double) and integer (int), we
 * can't directly convert (see bug 301162).  This macro is a messy
 * 'workaround'
 */
#define XTRUNC(f, v)            \
    f = fmod((v), INT_MAX);     \
    f = (v) - (f) + (double)((int)(f));

/**
 * xmlXPathFloorFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the floor() XPath function
 *    number floor(number)
 * The floor function returns the largest (closest to positive infinity)
 * number that is not greater than the argument and that is an integer.
 */
void
xmlXPathFloorFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    double f;

    CHECK_ARITY(1);
    CAST_TO_NUMBER;
    CHECK_TYPE(XPATH_NUMBER);

    XTRUNC(f, ctxt->value->floatval);
    if (f != ctxt->value->floatval) {
	if (ctxt->value->floatval > 0)
	    ctxt->value->floatval = f;
	else
	    ctxt->value->floatval = f - 1;
    }
}

/**
 * xmlXPathCeilingFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the ceiling() XPath function
 *    number ceiling(number)
 * The ceiling function returns the smallest (closest to negative infinity)
 * number that is not less than the argument and that is an integer.
 */
void
xmlXPathCeilingFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    double f;

    CHECK_ARITY(1);
    CAST_TO_NUMBER;
    CHECK_TYPE(XPATH_NUMBER);

#if 0
    ctxt->value->floatval = ceil(ctxt->value->floatval);
#else
    XTRUNC(f, ctxt->value->floatval);
    if (f != ctxt->value->floatval) {
	if (ctxt->value->floatval > 0)
	    ctxt->value->floatval = f + 1;
	else {
	    if (ctxt->value->floatval < 0 && f == 0)
	        ctxt->value->floatval = xmlXPathNZERO;
	    else
	        ctxt->value->floatval = f;
	}

    }
#endif
}

/**
 * xmlXPathRoundFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the round() XPath function
 *    number round(number)
 * The round function returns the number that is closest to the
 * argument and that is an integer. If there are two such numbers,
 * then the one that is even is returned.
 */
void
xmlXPathRoundFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    double f;

    CHECK_ARITY(1);
    CAST_TO_NUMBER;
    CHECK_TYPE(XPATH_NUMBER);

    if ((xmlXPathIsNaN(ctxt->value->floatval)) ||
	(xmlXPathIsInf(ctxt->value->floatval) == 1) ||
	(xmlXPathIsInf(ctxt->value->floatval) == -1) ||
	(ctxt->value->floatval == 0.0))
	return;

    XTRUNC(f, ctxt->value->floatval);
    if (ctxt->value->floatval < 0) {
	if (ctxt->value->floatval < f - 0.5)
	    ctxt->value->floatval = f - 1;
	else
	    ctxt->value->floatval = f;
	if (ctxt->value->floatval == 0)
	    ctxt->value->floatval = xmlXPathNZERO;
    } else {
	if (ctxt->value->floatval < f + 0.5)
	    ctxt->value->floatval = f;
	else
	    ctxt->value->floatval = f + 1;
    }
}

/************************************************************************
 *									*
 *			The Parser					*
 *									*
 ************************************************************************/

/*
 * a few forward declarations since we use a recursive call based
 * implementation.
 */
static void xmlXPathCompileExpr(xmlXPathParserContextPtr ctxt, int sort);
static void xmlXPathCompPredicate(xmlXPathParserContextPtr ctxt, int filter);
static void xmlXPathCompLocationPath(xmlXPathParserContextPtr ctxt);
static void xmlXPathCompRelativeLocationPath(xmlXPathParserContextPtr ctxt);
static xmlChar * xmlXPathParseNameComplex(xmlXPathParserContextPtr ctxt,
	                                  int qualified);

/**
 * xmlXPathCurrentChar:
 * @ctxt:  the XPath parser context
 * @cur:  pointer to the beginning of the char
 * @len:  pointer to the length of the char read
 *
 * The current char value, if using UTF-8 this may actually span multiple
 * bytes in the input buffer.
 *
 * Returns the current char value and its length
 */

static int
xmlXPathCurrentChar(xmlXPathParserContextPtr ctxt, int *len) {
    unsigned char c;
    unsigned int val;
    const xmlChar *cur;

    if (ctxt == NULL)
	return(0);
    cur = ctxt->cur;

    /*
     * We are supposed to handle UTF8, check it's valid
     * From rfc2044: encoding of the Unicode values on UTF-8:
     *
     * UCS-4 range (hex.)           UTF-8 octet sequence (binary)
     * 0000 0000-0000 007F   0xxxxxxx
     * 0000 0080-0000 07FF   110xxxxx 10xxxxxx
     * 0000 0800-0000 FFFF   1110xxxx 10xxxxxx 10xxxxxx
     *
     * Check for the 0x110000 limit too
     */
    c = *cur;
    if (c & 0x80) {
	if ((cur[1] & 0xc0) != 0x80)
	    goto encoding_error;
	if ((c & 0xe0) == 0xe0) {

	    if ((cur[2] & 0xc0) != 0x80)
		goto encoding_error;
	    if ((c & 0xf0) == 0xf0) {
		if (((c & 0xf8) != 0xf0) ||
		    ((cur[3] & 0xc0) != 0x80))
		    goto encoding_error;
		/* 4-byte code */
		*len = 4;
		val = (cur[0] & 0x7) << 18;
		val |= (cur[1] & 0x3f) << 12;
		val |= (cur[2] & 0x3f) << 6;
		val |= cur[3] & 0x3f;
	    } else {
	      /* 3-byte code */
		*len = 3;
		val = (cur[0] & 0xf) << 12;
		val |= (cur[1] & 0x3f) << 6;
		val |= cur[2] & 0x3f;
	    }
	} else {
	  /* 2-byte code */
	    *len = 2;
	    val = (cur[0] & 0x1f) << 6;
	    val |= cur[1] & 0x3f;
	}
	if (!IS_CHAR(val)) {
	    XP_ERROR0(XPATH_INVALID_CHAR_ERROR);
	}
	return(val);
    } else {
	/* 1-byte code */
	*len = 1;
	return((int) *cur);
    }
encoding_error:
    /*
     * If we detect an UTF8 error that probably means that the
     * input encoding didn't get properly advertised in the
     * declaration header. Report the error and switch the encoding
     * to ISO-Latin-1 (if you don't like this policy, just declare the
     * encoding !)
     */
    *len = 0;
    XP_ERROR0(XPATH_ENCODING_ERROR);
}

/**
 * xmlXPathParseNCName:
 * @ctxt:  the XPath Parser context
 *
 * parse an XML namespace non qualified name.
 *
 * [NS 3] NCName ::= (Letter | '_') (NCNameChar)*
 *
 * [NS 4] NCNameChar ::= Letter | Digit | '.' | '-' | '_' |
 *                       CombiningChar | Extender
 *
 * Returns the namespace name or NULL
 */

xmlChar *
xmlXPathParseNCName(xmlXPathParserContextPtr ctxt) {
    const xmlChar *in;
    xmlChar *ret;
    int count = 0;

    if ((ctxt == NULL) || (ctxt->cur == NULL)) return(NULL);
    /*
     * Accelerator for simple ASCII names
     */
    in = ctxt->cur;
    if (((*in >= 0x61) && (*in <= 0x7A)) ||
	((*in >= 0x41) && (*in <= 0x5A)) ||
	(*in == '_')) {
	in++;
	while (((*in >= 0x61) && (*in <= 0x7A)) ||
	       ((*in >= 0x41) && (*in <= 0x5A)) ||
	       ((*in >= 0x30) && (*in <= 0x39)) ||
	       (*in == '_') || (*in == '.') ||
	       (*in == '-'))
	    in++;
	if ((*in == ' ') || (*in == '>') || (*in == '/') ||
            (*in == '[') || (*in == ']') || (*in == ':') ||
            (*in == '@') || (*in == '*')) {
	    count = in - ctxt->cur;
	    if (count == 0)
		return(NULL);
	    ret = xmlStrndup(ctxt->cur, count);
	    ctxt->cur = in;
	    return(ret);
	}
    }
    return(xmlXPathParseNameComplex(ctxt, 0));
}


/**
 * xmlXPathParseQName:
 * @ctxt:  the XPath Parser context
 * @prefix:  a xmlChar **
 *
 * parse an XML qualified name
 *
 * [NS 5] QName ::= (Prefix ':')? LocalPart
 *
 * [NS 6] Prefix ::= NCName
 *
 * [NS 7] LocalPart ::= NCName
 *
 * Returns the function returns the local part, and prefix is updated
 *   to get the Prefix if any.
 */

static xmlChar *
xmlXPathParseQName(xmlXPathParserContextPtr ctxt, xmlChar **prefix) {
    xmlChar *ret = NULL;

    *prefix = NULL;
    ret = xmlXPathParseNCName(ctxt);
    if (ret && CUR == ':') {
        *prefix = ret;
	NEXT;
	ret = xmlXPathParseNCName(ctxt);
    }
    return(ret);
}

/**
 * xmlXPathParseName:
 * @ctxt:  the XPath Parser context
 *
 * parse an XML name
 *
 * [4] NameChar ::= Letter | Digit | '.' | '-' | '_' | ':' |
 *                  CombiningChar | Extender
 *
 * [5] Name ::= (Letter | '_' | ':') (NameChar)*
 *
 * Returns the namespace name or NULL
 */

xmlChar *
xmlXPathParseName(xmlXPathParserContextPtr ctxt) {
    const xmlChar *in;
    xmlChar *ret;
    int count = 0;

    if ((ctxt == NULL) || (ctxt->cur == NULL)) return(NULL);
    /*
     * Accelerator for simple ASCII names
     */
    in = ctxt->cur;
    if (((*in >= 0x61) && (*in <= 0x7A)) ||
	((*in >= 0x41) && (*in <= 0x5A)) ||
	(*in == '_') || (*in == ':')) {
	in++;
	while (((*in >= 0x61) && (*in <= 0x7A)) ||
	       ((*in >= 0x41) && (*in <= 0x5A)) ||
	       ((*in >= 0x30) && (*in <= 0x39)) ||
	       (*in == '_') || (*in == '-') ||
	       (*in == ':') || (*in == '.'))
	    in++;
	if ((*in > 0) && (*in < 0x80)) {
	    count = in - ctxt->cur;
	    ret = xmlStrndup(ctxt->cur, count);
	    ctxt->cur = in;
	    return(ret);
	}
    }
    return(xmlXPathParseNameComplex(ctxt, 1));
}

static xmlChar *
xmlXPathParseNameComplex(xmlXPathParserContextPtr ctxt, int qualified) {
    xmlChar buf[XML_MAX_NAMELEN + 5];
    int len = 0, l;
    int c;

    /*
     * Handler for more complex cases
     */
    c = CUR_CHAR(l);
    if ((c == ' ') || (c == '>') || (c == '/') || /* accelerators */
        (c == '[') || (c == ']') || (c == '@') || /* accelerators */
        (c == '*') || /* accelerators */
	(!IS_LETTER(c) && (c != '_') &&
         ((qualified) && (c != ':')))) {
	return(NULL);
    }

    while ((c != ' ') && (c != '>') && (c != '/') && /* test bigname.xml */
	   ((IS_LETTER(c)) || (IS_DIGIT(c)) ||
            (c == '.') || (c == '-') ||
	    (c == '_') || ((qualified) && (c == ':')) ||
	    (IS_COMBINING(c)) ||
	    (IS_EXTENDER(c)))) {
	COPY_BUF(l,buf,len,c);
	NEXTL(l);
	c = CUR_CHAR(l);
	if (len >= XML_MAX_NAMELEN) {
	    /*
	     * Okay someone managed to make a huge name, so he's ready to pay
	     * for the processing speed.
	     */
	    xmlChar *buffer;
	    int max = len * 2;

	    buffer = (xmlChar *) xmlMallocAtomic(max * sizeof(xmlChar));
	    if (buffer == NULL) {
		XP_ERRORNULL(XPATH_MEMORY_ERROR);
	    }
	    memcpy(buffer, buf, len);
	    while ((IS_LETTER(c)) || (IS_DIGIT(c)) || /* test bigname.xml */
		   (c == '.') || (c == '-') ||
		   (c == '_') || ((qualified) && (c == ':')) ||
		   (IS_COMBINING(c)) ||
		   (IS_EXTENDER(c))) {
		if (len + 10 > max) {
		    max *= 2;
		    buffer = (xmlChar *) xmlRealloc(buffer,
			                            max * sizeof(xmlChar));
		    if (buffer == NULL) {
			XP_ERRORNULL(XPATH_MEMORY_ERROR);
		    }
		}
		COPY_BUF(l,buffer,len,c);
		NEXTL(l);
		c = CUR_CHAR(l);
	    }
	    buffer[len] = 0;
	    return(buffer);
	}
    }
    if (len == 0)
	return(NULL);
    return(xmlStrndup(buf, len));
}

#define MAX_FRAC 20

/*
 * These are used as divisors for the fractional part of a number.
 * Since the table includes 1.0 (representing '0' fractional digits),
 * it must be dimensioned at MAX_FRAC+1 (bug 133921)
 */
static double my_pow10[MAX_FRAC+1] = {
    1.0, 10.0, 100.0, 1000.0, 10000.0,
    100000.0, 1000000.0, 10000000.0, 100000000.0, 1000000000.0,
    10000000000.0, 100000000000.0, 1000000000000.0, 10000000000000.0,
    100000000000000.0,
    1000000000000000.0, 10000000000000000.0, 100000000000000000.0,
    1000000000000000000.0, 10000000000000000000.0, 100000000000000000000.0
};

/**
 * xmlXPathStringEvalNumber:
 * @str:  A string to scan
 *
 *  [30a]  Float  ::= Number ('e' Digits?)?
 *
 *  [30]   Number ::=   Digits ('.' Digits?)?
 *                    | '.' Digits
 *  [31]   Digits ::=   [0-9]+
 *
 * Compile a Number in the string
 * In complement of the Number expression, this function also handles
 * negative values : '-' Number.
 *
 * Returns the double value.
 */
double
xmlXPathStringEvalNumber(const xmlChar *str) {
    const xmlChar *cur = str;
    double ret;
    int ok = 0;
    int isneg = 0;
    int exponent = 0;
    int is_exponent_negative = 0;
#ifdef __GNUC__
    unsigned long tmp = 0;
    double temp;
#endif
    if (cur == NULL) return(0);
    while (IS_BLANK_CH(*cur)) cur++;
    if ((*cur != '.') && ((*cur < '0') || (*cur > '9')) && (*cur != '-')) {
        return(xmlXPathNAN);
    }
    if (*cur == '-') {
	isneg = 1;
	cur++;
    }

#ifdef __GNUC__
    /*
     * tmp/temp is a workaround against a gcc compiler bug
     * http://veillard.com/gcc.bug
     */
    ret = 0;
    while ((*cur >= '0') && (*cur <= '9')) {
	ret = ret * 10;
	tmp = (*cur - '0');
	ok = 1;
	cur++;
	temp = (double) tmp;
	ret = ret + temp;
    }
#else
    ret = 0;
    while ((*cur >= '0') && (*cur <= '9')) {
	ret = ret * 10 + (*cur - '0');
	ok = 1;
	cur++;
    }
#endif

    if (*cur == '.') {
	int v, frac = 0;
	double fraction = 0;

        cur++;
	if (((*cur < '0') || (*cur > '9')) && (!ok)) {
	    return(xmlXPathNAN);
	}
	while (((*cur >= '0') && (*cur <= '9')) && (frac < MAX_FRAC)) {
	    v = (*cur - '0');
	    fraction = fraction * 10 + v;
	    frac = frac + 1;
	    cur++;
	}
	fraction /= my_pow10[frac];
	ret = ret + fraction;
	while ((*cur >= '0') && (*cur <= '9'))
	    cur++;
    }
    if ((*cur == 'e') || (*cur == 'E')) {
      cur++;
      if (*cur == '-') {
	is_exponent_negative = 1;
	cur++;
      } else if (*cur == '+') {
        cur++;
      }
      while ((*cur >= '0') && (*cur <= '9')) {
	exponent = exponent * 10 + (*cur - '0');
	cur++;
      }
    }
    while (IS_BLANK_CH(*cur)) cur++;
    if (*cur != 0) return(xmlXPathNAN);
    if (isneg) ret = -ret;
    if (is_exponent_negative) exponent = -exponent;
    ret *= pow(10.0, (double)exponent);
    return(ret);
}

/**
 * xmlXPathCompNumber:
 * @ctxt:  the XPath Parser context
 *
 *  [30]   Number ::=   Digits ('.' Digits?)?
 *                    | '.' Digits
 *  [31]   Digits ::=   [0-9]+
 *
 * Compile a Number, then push it on the stack
 *
 */
static void
xmlXPathCompNumber(xmlXPathParserContextPtr ctxt)
{
    double ret = 0.0;
    double mult = 1;
    int ok = 0;
    int exponent = 0;
    int is_exponent_negative = 0;
#ifdef __GNUC__
    unsigned long tmp = 0;
    double temp;
#endif

    CHECK_ERROR;
    if ((CUR != '.') && ((CUR < '0') || (CUR > '9'))) {
        XP_ERROR(XPATH_NUMBER_ERROR);
    }
#ifdef __GNUC__
    /*
     * tmp/temp is a workaround against a gcc compiler bug
     * http://veillard.com/gcc.bug
     */
    ret = 0;
    while ((CUR >= '0') && (CUR <= '9')) {
	ret = ret * 10;
	tmp = (CUR - '0');
        ok = 1;
        NEXT;
	temp = (double) tmp;
	ret = ret + temp;
    }
#else
    ret = 0;
    while ((CUR >= '0') && (CUR <= '9')) {
	ret = ret * 10 + (CUR - '0');
	ok = 1;
	NEXT;
    }
#endif
    if (CUR == '.') {
        NEXT;
        if (((CUR < '0') || (CUR > '9')) && (!ok)) {
            XP_ERROR(XPATH_NUMBER_ERROR);
        }
        while ((CUR >= '0') && (CUR <= '9')) {
            mult /= 10;
            ret = ret + (CUR - '0') * mult;
            NEXT;
        }
    }
    if ((CUR == 'e') || (CUR == 'E')) {
        NEXT;
        if (CUR == '-') {
            is_exponent_negative = 1;
            NEXT;
        } else if (CUR == '+') {
	    NEXT;
	}
        while ((CUR >= '0') && (CUR <= '9')) {
            exponent = exponent * 10 + (CUR - '0');
            NEXT;
        }
        if (is_exponent_negative)
            exponent = -exponent;
        ret *= pow(10.0, (double) exponent);
    }
    PUSH_LONG_EXPR(XPATH_OP_VALUE, XPATH_NUMBER, 0, 0,
                   xmlXPathCacheNewFloat(ctxt->context, ret), NULL);
}

/**
 * xmlXPathParseLiteral:
 * @ctxt:  the XPath Parser context
 *
 * Parse a Literal
 *
 *  [29]   Literal ::=   '"' [^"]* '"'
 *                    | "'" [^']* "'"
 *
 * Returns the value found or NULL in case of error
 */
static xmlChar *
xmlXPathParseLiteral(xmlXPathParserContextPtr ctxt) {
    const xmlChar *q;
    xmlChar *ret = NULL;

    if (CUR == '"') {
        NEXT;
	q = CUR_PTR;
	while ((IS_CHAR_CH(CUR)) && (CUR != '"'))
	    NEXT;
	if (!IS_CHAR_CH(CUR)) {
	    XP_ERRORNULL(XPATH_UNFINISHED_LITERAL_ERROR);
	} else {
	    ret = xmlStrndup(q, CUR_PTR - q);
	    NEXT;
        }
    } else if (CUR == '\'') {
        NEXT;
	q = CUR_PTR;
	while ((IS_CHAR_CH(CUR)) && (CUR != '\''))
	    NEXT;
	if (!IS_CHAR_CH(CUR)) {
	    XP_ERRORNULL(XPATH_UNFINISHED_LITERAL_ERROR);
	} else {
	    ret = xmlStrndup(q, CUR_PTR - q);
	    NEXT;
        }
    } else {
	XP_ERRORNULL(XPATH_START_LITERAL_ERROR);
    }
    return(ret);
}

/**
 * xmlXPathCompLiteral:
 * @ctxt:  the XPath Parser context
 *
 * Parse a Literal and push it on the stack.
 *
 *  [29]   Literal ::=   '"' [^"]* '"'
 *                    | "'" [^']* "'"
 *
 * TODO: xmlXPathCompLiteral memory allocation could be improved.
 */
static void
xmlXPathCompLiteral(xmlXPathParserContextPtr ctxt) {
    const xmlChar *q;
    xmlChar *ret = NULL;

    if (CUR == '"') {
        NEXT;
	q = CUR_PTR;
	while ((IS_CHAR_CH(CUR)) && (CUR != '"'))
	    NEXT;
	if (!IS_CHAR_CH(CUR)) {
	    XP_ERROR(XPATH_UNFINISHED_LITERAL_ERROR);
	} else {
	    ret = xmlStrndup(q, CUR_PTR - q);
	    NEXT;
        }
    } else if (CUR == '\'') {
        NEXT;
	q = CUR_PTR;
	while ((IS_CHAR_CH(CUR)) && (CUR != '\''))
	    NEXT;
	if (!IS_CHAR_CH(CUR)) {
	    XP_ERROR(XPATH_UNFINISHED_LITERAL_ERROR);
	} else {
	    ret = xmlStrndup(q, CUR_PTR - q);
	    NEXT;
        }
    } else {
	XP_ERROR(XPATH_START_LITERAL_ERROR);
    }
    if (ret == NULL) return;
    PUSH_LONG_EXPR(XPATH_OP_VALUE, XPATH_STRING, 0, 0,
	           xmlXPathCacheNewString(ctxt->context, ret), NULL);
    xmlFree(ret);
}

/**
 * xmlXPathCompVariableReference:
 * @ctxt:  the XPath Parser context
 *
 * Parse a VariableReference, evaluate it and push it on the stack.
 *
 * The variable bindings consist of a mapping from variable names
 * to variable values. The value of a variable is an object, which can be
 * of any of the types that are possible for the value of an expression,
 * and may also be of additional types not specified here.
 *
 * Early evaluation is possible since:
 * The variable bindings [...] used to evaluate a subexpression are
 * always the same as those used to evaluate the containing expression.
 *
 *  [36]   VariableReference ::=   '$' QName
 */
static void
xmlXPathCompVariableReference(xmlXPathParserContextPtr ctxt) {
    xmlChar *name;
    xmlChar *prefix;

    SKIP_BLANKS;
    if (CUR != '$') {
	XP_ERROR(XPATH_VARIABLE_REF_ERROR);
    }
    NEXT;
    name = xmlXPathParseQName(ctxt, &prefix);
    if (name == NULL) {
	XP_ERROR(XPATH_VARIABLE_REF_ERROR);
    }
    ctxt->comp->last = -1;
    PUSH_LONG_EXPR(XPATH_OP_VARIABLE, 0, 0, 0,
	           name, prefix);
    SKIP_BLANKS;
    if ((ctxt->context != NULL) && (ctxt->context->flags & XML_XPATH_NOVAR)) {
	XP_ERROR(XPATH_UNDEF_VARIABLE_ERROR);
    }
}

/**
 * xmlXPathIsNodeType:
 * @name:  a name string
 *
 * Is the name given a NodeType one.
 *
 *  [38]   NodeType ::=   'comment'
 *                    | 'text'
 *                    | 'processing-instruction'
 *                    | 'node'
 *
 * Returns 1 if true 0 otherwise
 */
int
xmlXPathIsNodeType(const xmlChar *name) {
    if (name == NULL)
	return(0);

    if (xmlStrEqual(name, BAD_CAST "node"))
	return(1);
    if (xmlStrEqual(name, BAD_CAST "text"))
	return(1);
    if (xmlStrEqual(name, BAD_CAST "comment"))
	return(1);
    if (xmlStrEqual(name, BAD_CAST "processing-instruction"))
	return(1);
    return(0);
}

/**
 * xmlXPathCompFunctionCall:
 * @ctxt:  the XPath Parser context
 *
 *  [16]   FunctionCall ::=   FunctionName '(' ( Argument ( ',' Argument)*)? ')'
 *  [17]   Argument ::=   Expr
 *
 * Compile a function call, the evaluation of all arguments are
 * pushed on the stack
 */
static void
xmlXPathCompFunctionCall(xmlXPathParserContextPtr ctxt) {
    xmlChar *name;
    xmlChar *prefix;
    int nbargs = 0;
    int sort = 1;

    name = xmlXPathParseQName(ctxt, &prefix);
    if (name == NULL) {
	xmlFree(prefix);
	XP_ERROR(XPATH_EXPR_ERROR);
    }
    SKIP_BLANKS;
#ifdef DEBUG_EXPR
    if (prefix == NULL)
	xmlGenericError(xmlGenericErrorContext, "Calling function %s\n",
			name);
    else
	xmlGenericError(xmlGenericErrorContext, "Calling function %s:%s\n",
			prefix, name);
#endif

    if (CUR != '(') {
	XP_ERROR(XPATH_EXPR_ERROR);
    }
    NEXT;
    SKIP_BLANKS;

    /*
    * Optimization for count(): we don't need the node-set to be sorted.
    */
    if ((prefix == NULL) && (name[0] == 'c') &&
	xmlStrEqual(name, BAD_CAST "count"))
    {
	sort = 0;
    }
    ctxt->comp->last = -1;
    if (CUR != ')') {
	while (CUR != 0) {
	    int op1 = ctxt->comp->last;
	    ctxt->comp->last = -1;
	    xmlXPathCompileExpr(ctxt, sort);
	    if (ctxt->error != XPATH_EXPRESSION_OK) {
		xmlFree(name);
		xmlFree(prefix);
		return;
	    }
	    PUSH_BINARY_EXPR(XPATH_OP_ARG, op1, ctxt->comp->last, 0, 0);
	    nbargs++;
	    if (CUR == ')') break;
	    if (CUR != ',') {
		XP_ERROR(XPATH_EXPR_ERROR);
	    }
	    NEXT;
	    SKIP_BLANKS;
	}
    }
    PUSH_LONG_EXPR(XPATH_OP_FUNCTION, nbargs, 0, 0,
	           name, prefix);
    NEXT;
    SKIP_BLANKS;
}

/**
 * xmlXPathCompPrimaryExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [15]   PrimaryExpr ::=   VariableReference
 *                | '(' Expr ')'
 *                | Literal
 *                | Number
 *                | FunctionCall
 *
 * Compile a primary expression.
 */
static void
xmlXPathCompPrimaryExpr(xmlXPathParserContextPtr ctxt) {
    SKIP_BLANKS;
    if (CUR == '$') xmlXPathCompVariableReference(ctxt);
    else if (CUR == '(') {
	NEXT;
	SKIP_BLANKS;
	xmlXPathCompileExpr(ctxt, 1);
	CHECK_ERROR;
	if (CUR != ')') {
	    XP_ERROR(XPATH_EXPR_ERROR);
	}
	NEXT;
	SKIP_BLANKS;
    } else if (IS_ASCII_DIGIT(CUR) || (CUR == '.' && IS_ASCII_DIGIT(NXT(1)))) {
	xmlXPathCompNumber(ctxt);
    } else if ((CUR == '\'') || (CUR == '"')) {
	xmlXPathCompLiteral(ctxt);
    } else {
	xmlXPathCompFunctionCall(ctxt);
    }
    SKIP_BLANKS;
}

/**
 * xmlXPathCompFilterExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [20]   FilterExpr ::=   PrimaryExpr
 *               | FilterExpr Predicate
 *
 * Compile a filter expression.
 * Square brackets are used to filter expressions in the same way that
 * they are used in location paths. It is an error if the expression to
 * be filtered does not evaluate to a node-set. The context node list
 * used for evaluating the expression in square brackets is the node-set
 * to be filtered listed in document order.
 */

static void
xmlXPathCompFilterExpr(xmlXPathParserContextPtr ctxt) {
    xmlXPathCompPrimaryExpr(ctxt);
    CHECK_ERROR;
    SKIP_BLANKS;

    while (CUR == '[') {
	xmlXPathCompPredicate(ctxt, 1);
	SKIP_BLANKS;
    }


}

/**
 * xmlXPathScanName:
 * @ctxt:  the XPath Parser context
 *
 * Trickery: parse an XML name but without consuming the input flow
 * Needed to avoid insanity in the parser state.
 *
 * [4] NameChar ::= Letter | Digit | '.' | '-' | '_' | ':' |
 *                  CombiningChar | Extender
 *
 * [5] Name ::= (Letter | '_' | ':') (NameChar)*
 *
 * [6] Names ::= Name (S Name)*
 *
 * Returns the Name parsed or NULL
 */

static xmlChar *
xmlXPathScanName(xmlXPathParserContextPtr ctxt) {
    int len = 0, l;
    int c;
    const xmlChar *cur;
    xmlChar *ret;

    cur = ctxt->cur;

    c = CUR_CHAR(l);
    if ((c == ' ') || (c == '>') || (c == '/') || /* accelerators */
	(!IS_LETTER(c) && (c != '_') &&
         (c != ':'))) {
	return(NULL);
    }

    while ((c != ' ') && (c != '>') && (c != '/') && /* test bigname.xml */
	   ((IS_LETTER(c)) || (IS_DIGIT(c)) ||
            (c == '.') || (c == '-') ||
	    (c == '_') || (c == ':') ||
	    (IS_COMBINING(c)) ||
	    (IS_EXTENDER(c)))) {
	len += l;
	NEXTL(l);
	c = CUR_CHAR(l);
    }
    ret = xmlStrndup(cur, ctxt->cur - cur);
    ctxt->cur = cur;
    return(ret);
}

/**
 * xmlXPathCompPathExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [19]   PathExpr ::=   LocationPath
 *               | FilterExpr
 *               | FilterExpr '/' RelativeLocationPath
 *               | FilterExpr '//' RelativeLocationPath
 *
 * Compile a path expression.
 * The / operator and // operators combine an arbitrary expression
 * and a relative location path. It is an error if the expression
 * does not evaluate to a node-set.
 * The / operator does composition in the same way as when / is
 * used in a location path. As in location paths, // is short for
 * /descendant-or-self::node()/.
 */

static void
xmlXPathCompPathExpr(xmlXPathParserContextPtr ctxt) {
    int lc = 1;           /* Should we branch to LocationPath ?         */
    xmlChar *name = NULL; /* we may have to preparse a name to find out */

    SKIP_BLANKS;
    if ((CUR == '$') || (CUR == '(') ||
	(IS_ASCII_DIGIT(CUR)) ||
        (CUR == '\'') || (CUR == '"') ||
	(CUR == '.' && IS_ASCII_DIGIT(NXT(1)))) {
	lc = 0;
    } else if (CUR == '*') {
	/* relative or absolute location path */
	lc = 1;
    } else if (CUR == '/') {
	/* relative or absolute location path */
	lc = 1;
    } else if (CUR == '@') {
	/* relative abbreviated attribute location path */
	lc = 1;
    } else if (CUR == '.') {
	/* relative abbreviated attribute location path */
	lc = 1;
    } else {
	/*
	 * Problem is finding if we have a name here whether it's:
	 *   - a nodetype
	 *   - a function call in which case it's followed by '('
	 *   - an axis in which case it's followed by ':'
	 *   - a element name
	 * We do an a priori analysis here rather than having to
	 * maintain parsed token content through the recursive function
	 * calls. This looks uglier but makes the code easier to
	 * read/write/debug.
	 */
	SKIP_BLANKS;
	name = xmlXPathScanName(ctxt);
	if ((name != NULL) && (xmlStrstr(name, (xmlChar *) "::") != NULL)) {
#ifdef DEBUG_STEP
	    xmlGenericError(xmlGenericErrorContext,
		    "PathExpr: Axis\n");
#endif
	    lc = 1;
	    xmlFree(name);
	} else if (name != NULL) {
	    int len =xmlStrlen(name);


	    while (NXT(len) != 0) {
		if (NXT(len) == '/') {
		    /* element name */
#ifdef DEBUG_STEP
		    xmlGenericError(xmlGenericErrorContext,
			    "PathExpr: AbbrRelLocation\n");
#endif
		    lc = 1;
		    break;
		} else if (IS_BLANK_CH(NXT(len))) {
		    /* ignore blanks */
		    ;
		} else if (NXT(len) == ':') {
#ifdef DEBUG_STEP
		    xmlGenericError(xmlGenericErrorContext,
			    "PathExpr: AbbrRelLocation\n");
#endif
		    lc = 1;
		    break;
		} else if ((NXT(len) == '(')) {
		    /* Note Type or Function */
		    if (xmlXPathIsNodeType(name)) {
#ifdef DEBUG_STEP
		        xmlGenericError(xmlGenericErrorContext,
				"PathExpr: Type search\n");
#endif
			lc = 1;
		    } else {
#ifdef DEBUG_STEP
		        xmlGenericError(xmlGenericErrorContext,
				"PathExpr: function call\n");
#endif
			lc = 0;
		    }
                    break;
		} else if ((NXT(len) == '[')) {
		    /* element name */
#ifdef DEBUG_STEP
		    xmlGenericError(xmlGenericErrorContext,
			    "PathExpr: AbbrRelLocation\n");
#endif
		    lc = 1;
		    break;
		} else if ((NXT(len) == '<') || (NXT(len) == '>') ||
			   (NXT(len) == '=')) {
		    lc = 1;
		    break;
		} else {
		    lc = 1;
		    break;
		}
		len++;
	    }
	    if (NXT(len) == 0) {
#ifdef DEBUG_STEP
		xmlGenericError(xmlGenericErrorContext,
			"PathExpr: AbbrRelLocation\n");
#endif
		/* element name */
		lc = 1;
	    }
	    xmlFree(name);
	} else {
	    /* make sure all cases are covered explicitly */
	    XP_ERROR(XPATH_EXPR_ERROR);
	}
    }

    if (lc) {
	if (CUR == '/') {
	    PUSH_LEAVE_EXPR(XPATH_OP_ROOT, 0, 0);
	} else {
	    PUSH_LEAVE_EXPR(XPATH_OP_NODE, 0, 0);
	}
	xmlXPathCompLocationPath(ctxt);
    } else {
	xmlXPathCompFilterExpr(ctxt);
	CHECK_ERROR;
	if ((CUR == '/') && (NXT(1) == '/')) {
	    SKIP(2);
	    SKIP_BLANKS;

	    PUSH_LONG_EXPR(XPATH_OP_COLLECT, AXIS_DESCENDANT_OR_SELF,
		    NODE_TEST_TYPE, NODE_TYPE_NODE, NULL, NULL);
	    PUSH_UNARY_EXPR(XPATH_OP_RESET, ctxt->comp->last, 1, 0);

	    xmlXPathCompRelativeLocationPath(ctxt);
	} else if (CUR == '/') {
	    xmlXPathCompRelativeLocationPath(ctxt);
	}
    }
    SKIP_BLANKS;
}

/**
 * xmlXPathCompUnionExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [18]   UnionExpr ::=   PathExpr
 *               | UnionExpr '|' PathExpr
 *
 * Compile an union expression.
 */

static void
xmlXPathCompUnionExpr(xmlXPathParserContextPtr ctxt) {
    xmlXPathCompPathExpr(ctxt);
    CHECK_ERROR;
    SKIP_BLANKS;
    while (CUR == '|') {
	int op1 = ctxt->comp->last;
	PUSH_LEAVE_EXPR(XPATH_OP_NODE, 0, 0);

	NEXT;
	SKIP_BLANKS;
	xmlXPathCompPathExpr(ctxt);

	PUSH_BINARY_EXPR(XPATH_OP_UNION, op1, ctxt->comp->last, 0, 0);

	SKIP_BLANKS;
    }
}

/**
 * xmlXPathCompUnaryExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [27]   UnaryExpr ::=   UnionExpr
 *                   | '-' UnaryExpr
 *
 * Compile an unary expression.
 */

static void
xmlXPathCompUnaryExpr(xmlXPathParserContextPtr ctxt) {
    int minus = 0;
    int found = 0;

    SKIP_BLANKS;
    while (CUR == '-') {
        minus = 1 - minus;
	found = 1;
	NEXT;
	SKIP_BLANKS;
    }

    xmlXPathCompUnionExpr(ctxt);
    CHECK_ERROR;
    if (found) {
	if (minus)
	    PUSH_UNARY_EXPR(XPATH_OP_PLUS, ctxt->comp->last, 2, 0);
	else
	    PUSH_UNARY_EXPR(XPATH_OP_PLUS, ctxt->comp->last, 3, 0);
    }
}

/**
 * xmlXPathCompMultiplicativeExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [26]   MultiplicativeExpr ::=   UnaryExpr
 *                   | MultiplicativeExpr MultiplyOperator UnaryExpr
 *                   | MultiplicativeExpr 'div' UnaryExpr
 *                   | MultiplicativeExpr 'mod' UnaryExpr
 *  [34]   MultiplyOperator ::=   '*'
 *
 * Compile an Additive expression.
 */

static void
xmlXPathCompMultiplicativeExpr(xmlXPathParserContextPtr ctxt) {
    xmlXPathCompUnaryExpr(ctxt);
    CHECK_ERROR;
    SKIP_BLANKS;
    while ((CUR == '*') ||
           ((CUR == 'd') && (NXT(1) == 'i') && (NXT(2) == 'v')) ||
           ((CUR == 'm') && (NXT(1) == 'o') && (NXT(2) == 'd'))) {
	int op = -1;
	int op1 = ctxt->comp->last;

        if (CUR == '*') {
	    op = 0;
	    NEXT;
	} else if (CUR == 'd') {
	    op = 1;
	    SKIP(3);
	} else if (CUR == 'm') {
	    op = 2;
	    SKIP(3);
	}
	SKIP_BLANKS;
        xmlXPathCompUnaryExpr(ctxt);
	CHECK_ERROR;
	PUSH_BINARY_EXPR(XPATH_OP_MULT, op1, ctxt->comp->last, op, 0);
	SKIP_BLANKS;
    }
}

/**
 * xmlXPathCompAdditiveExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [25]   AdditiveExpr ::=   MultiplicativeExpr
 *                   | AdditiveExpr '+' MultiplicativeExpr
 *                   | AdditiveExpr '-' MultiplicativeExpr
 *
 * Compile an Additive expression.
 */

static void
xmlXPathCompAdditiveExpr(xmlXPathParserContextPtr ctxt) {

    xmlXPathCompMultiplicativeExpr(ctxt);
    CHECK_ERROR;
    SKIP_BLANKS;
    while ((CUR == '+') || (CUR == '-')) {
	int plus;
	int op1 = ctxt->comp->last;

        if (CUR == '+') plus = 1;
	else plus = 0;
	NEXT;
	SKIP_BLANKS;
        xmlXPathCompMultiplicativeExpr(ctxt);
	CHECK_ERROR;
	PUSH_BINARY_EXPR(XPATH_OP_PLUS, op1, ctxt->comp->last, plus, 0);
	SKIP_BLANKS;
    }
}

/**
 * xmlXPathCompRelationalExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [24]   RelationalExpr ::=   AdditiveExpr
 *                 | RelationalExpr '<' AdditiveExpr
 *                 | RelationalExpr '>' AdditiveExpr
 *                 | RelationalExpr '<=' AdditiveExpr
 *                 | RelationalExpr '>=' AdditiveExpr
 *
 *  A <= B > C is allowed ? Answer from James, yes with
 *  (AdditiveExpr <= AdditiveExpr) > AdditiveExpr
 *  which is basically what got implemented.
 *
 * Compile a Relational expression, then push the result
 * on the stack
 */

static void
xmlXPathCompRelationalExpr(xmlXPathParserContextPtr ctxt) {
    xmlXPathCompAdditiveExpr(ctxt);
    CHECK_ERROR;
    SKIP_BLANKS;
    while ((CUR == '<') ||
           (CUR == '>') ||
           ((CUR == '<') && (NXT(1) == '=')) ||
           ((CUR == '>') && (NXT(1) == '='))) {
	int inf, strict;
	int op1 = ctxt->comp->last;

        if (CUR == '<') inf = 1;
	else inf = 0;
	if (NXT(1) == '=') strict = 0;
	else strict = 1;
	NEXT;
	if (!strict) NEXT;
	SKIP_BLANKS;
        xmlXPathCompAdditiveExpr(ctxt);
	CHECK_ERROR;
	PUSH_BINARY_EXPR(XPATH_OP_CMP, op1, ctxt->comp->last, inf, strict);
	SKIP_BLANKS;
    }
}

/**
 * xmlXPathCompEqualityExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [23]   EqualityExpr ::=   RelationalExpr
 *                 | EqualityExpr '=' RelationalExpr
 *                 | EqualityExpr '!=' RelationalExpr
 *
 *  A != B != C is allowed ? Answer from James, yes with
 *  (RelationalExpr = RelationalExpr) = RelationalExpr
 *  (RelationalExpr != RelationalExpr) != RelationalExpr
 *  which is basically what got implemented.
 *
 * Compile an Equality expression.
 *
 */
static void
xmlXPathCompEqualityExpr(xmlXPathParserContextPtr ctxt) {
    xmlXPathCompRelationalExpr(ctxt);
    CHECK_ERROR;
    SKIP_BLANKS;
    while ((CUR == '=') || ((CUR == '!') && (NXT(1) == '='))) {
	int eq;
	int op1 = ctxt->comp->last;

        if (CUR == '=') eq = 1;
	else eq = 0;
	NEXT;
	if (!eq) NEXT;
	SKIP_BLANKS;
        xmlXPathCompRelationalExpr(ctxt);
	CHECK_ERROR;
	PUSH_BINARY_EXPR(XPATH_OP_EQUAL, op1, ctxt->comp->last, eq, 0);
	SKIP_BLANKS;
    }
}

/**
 * xmlXPathCompAndExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [22]   AndExpr ::=   EqualityExpr
 *                 | AndExpr 'and' EqualityExpr
 *
 * Compile an AND expression.
 *
 */
static void
xmlXPathCompAndExpr(xmlXPathParserContextPtr ctxt) {
    xmlXPathCompEqualityExpr(ctxt);
    CHECK_ERROR;
    SKIP_BLANKS;
    while ((CUR == 'a') && (NXT(1) == 'n') && (NXT(2) == 'd')) {
	int op1 = ctxt->comp->last;
        SKIP(3);
	SKIP_BLANKS;
        xmlXPathCompEqualityExpr(ctxt);
	CHECK_ERROR;
	PUSH_BINARY_EXPR(XPATH_OP_AND, op1, ctxt->comp->last, 0, 0);
	SKIP_BLANKS;
    }
}

/**
 * xmlXPathCompileExpr:
 * @ctxt:  the XPath Parser context
 *
 *  [14]   Expr ::=   OrExpr
 *  [21]   OrExpr ::=   AndExpr
 *                 | OrExpr 'or' AndExpr
 *
 * Parse and compile an expression
 */
static void
xmlXPathCompileExpr(xmlXPathParserContextPtr ctxt, int sort) {
    xmlXPathCompAndExpr(ctxt);
    CHECK_ERROR;
    SKIP_BLANKS;
    while ((CUR == 'o') && (NXT(1) == 'r')) {
	int op1 = ctxt->comp->last;
        SKIP(2);
	SKIP_BLANKS;
        xmlXPathCompAndExpr(ctxt);
	CHECK_ERROR;
	PUSH_BINARY_EXPR(XPATH_OP_OR, op1, ctxt->comp->last, 0, 0);
	SKIP_BLANKS;
    }
    if ((sort) && (ctxt->comp->steps[ctxt->comp->last].op != XPATH_OP_VALUE)) {
	/* more ops could be optimized too */
	/*
	* This is the main place to eliminate sorting for
	* operations which don't require a sorted node-set.
	* E.g. count().
	*/
	PUSH_UNARY_EXPR(XPATH_OP_SORT, ctxt->comp->last , 0, 0);
    }
}

/**
 * xmlXPathCompPredicate:
 * @ctxt:  the XPath Parser context
 * @filter:  act as a filter
 *
 *  [8]   Predicate ::=   '[' PredicateExpr ']'
 *  [9]   PredicateExpr ::=   Expr
 *
 * Compile a predicate expression
 */
static void
xmlXPathCompPredicate(xmlXPathParserContextPtr ctxt, int filter) {
    int op1 = ctxt->comp->last;

    SKIP_BLANKS;
    if (CUR != '[') {
	XP_ERROR(XPATH_INVALID_PREDICATE_ERROR);
    }
    NEXT;
    SKIP_BLANKS;

    ctxt->comp->last = -1;
    /*
    * This call to xmlXPathCompileExpr() will deactivate sorting
    * of the predicate result.
    * TODO: Sorting is still activated for filters, since I'm not
    *  sure if needed. Normally sorting should not be needed, since
    *  a filter can only diminish the number of items in a sequence,
    *  but won't change its order; so if the initial sequence is sorted,
    *  subsequent sorting is not needed.
    */
    if (! filter)
	xmlXPathCompileExpr(ctxt, 0);
    else
	xmlXPathCompileExpr(ctxt, 1);
    CHECK_ERROR;

    if (CUR != ']') {
	XP_ERROR(XPATH_INVALID_PREDICATE_ERROR);
    }

    if (filter)
	PUSH_BINARY_EXPR(XPATH_OP_FILTER, op1, ctxt->comp->last, 0, 0);
    else
	PUSH_BINARY_EXPR(XPATH_OP_PREDICATE, op1, ctxt->comp->last, 0, 0);

    NEXT;
    SKIP_BLANKS;
}

/**
 * xmlXPathCompNodeTest:
 * @ctxt:  the XPath Parser context
 * @test:  pointer to a xmlXPathTestVal
 * @type:  pointer to a xmlXPathTypeVal
 * @prefix:  placeholder for a possible name prefix
 *
 * [7] NodeTest ::=   NameTest
 *		    | NodeType '(' ')'
 *		    | 'processing-instruction' '(' Literal ')'
 *
 * [37] NameTest ::=  '*'
 *		    | NCName ':' '*'
 *		    | QName
 * [38] NodeType ::= 'comment'
 *		   | 'text'
 *		   | 'processing-instruction'
 *		   | 'node'
 *
 * Returns the name found and updates @test, @type and @prefix appropriately
 */
static xmlChar *
xmlXPathCompNodeTest(xmlXPathParserContextPtr ctxt, xmlXPathTestVal *test,
	             xmlXPathTypeVal *type, const xmlChar **prefix,
		     xmlChar *name) {
    int blanks;

    if ((test == NULL) || (type == NULL) || (prefix == NULL)) {
	STRANGE;
	return(NULL);
    }
    *type = (xmlXPathTypeVal) 0;
    *test = (xmlXPathTestVal) 0;
    *prefix = NULL;
    SKIP_BLANKS;

    if ((name == NULL) && (CUR == '*')) {
	/*
	 * All elements
	 */
	NEXT;
	*test = NODE_TEST_ALL;
	return(NULL);
    }

    if (name == NULL)
	name = xmlXPathParseNCName(ctxt);
    if (name == NULL) {
	XP_ERRORNULL(XPATH_EXPR_ERROR);
    }

    blanks = IS_BLANK_CH(CUR);
    SKIP_BLANKS;
    if (CUR == '(') {
	NEXT;
	/*
	 * NodeType or PI search
	 */
	if (xmlStrEqual(name, BAD_CAST "comment"))
	    *type = NODE_TYPE_COMMENT;
	else if (xmlStrEqual(name, BAD_CAST "node"))
	    *type = NODE_TYPE_NODE;
	else if (xmlStrEqual(name, BAD_CAST "processing-instruction"))
	    *type = NODE_TYPE_PI;
	else if (xmlStrEqual(name, BAD_CAST "text"))
	    *type = NODE_TYPE_TEXT;
	else {
	    if (name != NULL)
		xmlFree(name);
	    XP_ERRORNULL(XPATH_EXPR_ERROR);
	}

	*test = NODE_TEST_TYPE;

	SKIP_BLANKS;
	if (*type == NODE_TYPE_PI) {
	    /*
	     * Specific case: search a PI by name.
	     */
	    if (name != NULL)
		xmlFree(name);
	    name = NULL;
	    if (CUR != ')') {
		name = xmlXPathParseLiteral(ctxt);
		CHECK_ERROR NULL;
		*test = NODE_TEST_PI;
		SKIP_BLANKS;
	    }
	}
	if (CUR != ')') {
	    if (name != NULL)
		xmlFree(name);
	    XP_ERRORNULL(XPATH_UNCLOSED_ERROR);
	}
	NEXT;
	return(name);
    }
    *test = NODE_TEST_NAME;
    if ((!blanks) && (CUR == ':')) {
	NEXT;

	/*
	 * Since currently the parser context don't have a
	 * namespace list associated:
	 * The namespace name for this prefix can be computed
	 * only at evaluation time. The compilation is done
	 * outside of any context.
	 */
#if 0
	*prefix = xmlXPathNsLookup(ctxt->context, name);
	if (name != NULL)
	    xmlFree(name);
	if (*prefix == NULL) {
	    XP_ERROR0(XPATH_UNDEF_PREFIX_ERROR);
	}
#else
	*prefix = name;
#endif

	if (CUR == '*') {
	    /*
	     * All elements
	     */
	    NEXT;
	    *test = NODE_TEST_ALL;
	    return(NULL);
	}

	name = xmlXPathParseNCName(ctxt);
	if (name == NULL) {
	    XP_ERRORNULL(XPATH_EXPR_ERROR);
	}
    }
    return(name);
}

/**
 * xmlXPathIsAxisName:
 * @name:  a preparsed name token
 *
 * [6] AxisName ::=   'ancestor'
 *                  | 'ancestor-or-self'
 *                  | 'attribute'
 *                  | 'child'
 *                  | 'descendant'
 *                  | 'descendant-or-self'
 *                  | 'following'
 *                  | 'following-sibling'
 *                  | 'namespace'
 *                  | 'parent'
 *                  | 'preceding'
 *                  | 'preceding-sibling'
 *                  | 'self'
 *
 * Returns the axis or 0
 */
static xmlXPathAxisVal
xmlXPathIsAxisName(const xmlChar *name) {
    xmlXPathAxisVal ret = (xmlXPathAxisVal) 0;
    switch (name[0]) {
	case 'a':
	    if (xmlStrEqual(name, BAD_CAST "ancestor"))
		ret = AXIS_ANCESTOR;
	    if (xmlStrEqual(name, BAD_CAST "ancestor-or-self"))
		ret = AXIS_ANCESTOR_OR_SELF;
	    if (xmlStrEqual(name, BAD_CAST "attribute"))
		ret = AXIS_ATTRIBUTE;
	    break;
	case 'c':
	    if (xmlStrEqual(name, BAD_CAST "child"))
		ret = AXIS_CHILD;
	    break;
	case 'd':
	    if (xmlStrEqual(name, BAD_CAST "descendant"))
		ret = AXIS_DESCENDANT;
	    if (xmlStrEqual(name, BAD_CAST "descendant-or-self"))
		ret = AXIS_DESCENDANT_OR_SELF;
	    break;
	case 'f':
	    if (xmlStrEqual(name, BAD_CAST "following"))
		ret = AXIS_FOLLOWING;
	    if (xmlStrEqual(name, BAD_CAST "following-sibling"))
		ret = AXIS_FOLLOWING_SIBLING;
	    break;
	case 'n':
	    if (xmlStrEqual(name, BAD_CAST "namespace"))
		ret = AXIS_NAMESPACE;
	    break;
	case 'p':
	    if (xmlStrEqual(name, BAD_CAST "parent"))
		ret = AXIS_PARENT;
	    if (xmlStrEqual(name, BAD_CAST "preceding"))
		ret = AXIS_PRECEDING;
	    if (xmlStrEqual(name, BAD_CAST "preceding-sibling"))
		ret = AXIS_PRECEDING_SIBLING;
	    break;
	case 's':
	    if (xmlStrEqual(name, BAD_CAST "self"))
		ret = AXIS_SELF;
	    break;
    }
    return(ret);
}

/**
 * xmlXPathCompStep:
 * @ctxt:  the XPath Parser context
 *
 * [4] Step ::=   AxisSpecifier NodeTest Predicate*
 *                  | AbbreviatedStep
 *
 * [12] AbbreviatedStep ::=   '.' | '..'
 *
 * [5] AxisSpecifier ::= AxisName '::'
 *                  | AbbreviatedAxisSpecifier
 *
 * [13] AbbreviatedAxisSpecifier ::= '@'?
 *
 * Modified for XPtr range support as:
 *
 *  [4xptr] Step ::= AxisSpecifier NodeTest Predicate*
 *                     | AbbreviatedStep
 *                     | 'range-to' '(' Expr ')' Predicate*
 *
 * Compile one step in a Location Path
 * A location step of . is short for self::node(). This is
 * particularly useful in conjunction with //. For example, the
 * location path .//para is short for
 * self::node()/descendant-or-self::node()/child::para
 * and so will select all para descendant elements of the context
 * node.
 * Similarly, a location step of .. is short for parent::node().
 * For example, ../title is short for parent::node()/child::title
 * and so will select the title children of the parent of the context
 * node.
 */
static void
xmlXPathCompStep(xmlXPathParserContextPtr ctxt) {
#ifdef LIBXML_XPTR_ENABLED
    int rangeto = 0;
    int op2 = -1;
#endif

    SKIP_BLANKS;
    if ((CUR == '.') && (NXT(1) == '.')) {
	SKIP(2);
	SKIP_BLANKS;
	PUSH_LONG_EXPR(XPATH_OP_COLLECT, AXIS_PARENT,
		    NODE_TEST_TYPE, NODE_TYPE_NODE, NULL, NULL);
    } else if (CUR == '.') {
	NEXT;
	SKIP_BLANKS;
    } else {
	xmlChar *name = NULL;
	const xmlChar *prefix = NULL;
	xmlXPathTestVal test = (xmlXPathTestVal) 0;
	xmlXPathAxisVal axis = (xmlXPathAxisVal) 0;
	xmlXPathTypeVal type = (xmlXPathTypeVal) 0;
	int op1;

	/*
	 * The modification needed for XPointer change to the production
	 */
#ifdef LIBXML_XPTR_ENABLED
	if (ctxt->xptr) {
	    name = xmlXPathParseNCName(ctxt);
	    if ((name != NULL) && (xmlStrEqual(name, BAD_CAST "range-to"))) {
                op2 = ctxt->comp->last;
		xmlFree(name);
		SKIP_BLANKS;
		if (CUR != '(') {
		    XP_ERROR(XPATH_EXPR_ERROR);
		}
		NEXT;
		SKIP_BLANKS;

		xmlXPathCompileExpr(ctxt, 1);
		/* PUSH_BINARY_EXPR(XPATH_OP_RANGETO, op2, ctxt->comp->last, 0, 0); */
		CHECK_ERROR;

		SKIP_BLANKS;
		if (CUR != ')') {
		    XP_ERROR(XPATH_EXPR_ERROR);
		}
		NEXT;
		rangeto = 1;
		goto eval_predicates;
	    }
	}
#endif
	if (CUR == '*') {
	    axis = AXIS_CHILD;
	} else {
	    if (name == NULL)
		name = xmlXPathParseNCName(ctxt);
	    if (name != NULL) {
		axis = xmlXPathIsAxisName(name);
		if (axis != 0) {
		    SKIP_BLANKS;
		    if ((CUR == ':') && (NXT(1) == ':')) {
			SKIP(2);
			xmlFree(name);
			name = NULL;
		    } else {
			/* an element name can conflict with an axis one :-\ */
			axis = AXIS_CHILD;
		    }
		} else {
		    axis = AXIS_CHILD;
		}
	    } else if (CUR == '@') {
		NEXT;
		axis = AXIS_ATTRIBUTE;
	    } else {
		axis = AXIS_CHILD;
	    }
	}

	CHECK_ERROR;

	name = xmlXPathCompNodeTest(ctxt, &test, &type, &prefix, name);
	if (test == 0)
	    return;

        if ((prefix != NULL) && (ctxt->context != NULL) &&
	    (ctxt->context->flags & XML_XPATH_CHECKNS)) {
	    if (xmlXPathNsLookup(ctxt->context, prefix) == NULL) {
		xmlXPathErr(ctxt, XPATH_UNDEF_PREFIX_ERROR);
	    }
	}
#ifdef DEBUG_STEP
	xmlGenericError(xmlGenericErrorContext,
		"Basis : computing new set\n");
#endif

#ifdef DEBUG_STEP
	xmlGenericError(xmlGenericErrorContext, "Basis : ");
	if (ctxt->value == NULL)
	    xmlGenericError(xmlGenericErrorContext, "no value\n");
	else if (ctxt->value->nodesetval == NULL)
	    xmlGenericError(xmlGenericErrorContext, "Empty\n");
	else
	    xmlGenericErrorContextNodeSet(stdout, ctxt->value->nodesetval);
#endif

#ifdef LIBXML_XPTR_ENABLED
eval_predicates:
#endif
	op1 = ctxt->comp->last;
	ctxt->comp->last = -1;

	SKIP_BLANKS;
	while (CUR == '[') {
	    xmlXPathCompPredicate(ctxt, 0);
	}

#ifdef LIBXML_XPTR_ENABLED
	if (rangeto) {
	    PUSH_BINARY_EXPR(XPATH_OP_RANGETO, op2, op1, 0, 0);
	} else
#endif
	    PUSH_FULL_EXPR(XPATH_OP_COLLECT, op1, ctxt->comp->last, axis,
			   test, type, (void *)prefix, (void *)name);

    }
#ifdef DEBUG_STEP
    xmlGenericError(xmlGenericErrorContext, "Step : ");
    if (ctxt->value == NULL)
	xmlGenericError(xmlGenericErrorContext, "no value\n");
    else if (ctxt->value->nodesetval == NULL)
	xmlGenericError(xmlGenericErrorContext, "Empty\n");
    else
	xmlGenericErrorContextNodeSet(xmlGenericErrorContext,
		ctxt->value->nodesetval);
#endif
}

/**
 * xmlXPathCompRelativeLocationPath:
 * @ctxt:  the XPath Parser context
 *
 *  [3]   RelativeLocationPath ::=   Step
 *                     | RelativeLocationPath '/' Step
 *                     | AbbreviatedRelativeLocationPath
 *  [11]  AbbreviatedRelativeLocationPath ::=   RelativeLocationPath '//' Step
 *
 * Compile a relative location path.
 */
static void
xmlXPathCompRelativeLocationPath
(xmlXPathParserContextPtr ctxt) {
    SKIP_BLANKS;
    if ((CUR == '/') && (NXT(1) == '/')) {
	SKIP(2);
	SKIP_BLANKS;
	PUSH_LONG_EXPR(XPATH_OP_COLLECT, AXIS_DESCENDANT_OR_SELF,
		         NODE_TEST_TYPE, NODE_TYPE_NODE, NULL, NULL);
    } else if (CUR == '/') {
	    NEXT;
	SKIP_BLANKS;
    }
    xmlXPathCompStep(ctxt);
    CHECK_ERROR;
    SKIP_BLANKS;
    while (CUR == '/') {
	if ((CUR == '/') && (NXT(1) == '/')) {
	    SKIP(2);
	    SKIP_BLANKS;
	    PUSH_LONG_EXPR(XPATH_OP_COLLECT, AXIS_DESCENDANT_OR_SELF,
			     NODE_TEST_TYPE, NODE_TYPE_NODE, NULL, NULL);
	    xmlXPathCompStep(ctxt);
	} else if (CUR == '/') {
	    NEXT;
	    SKIP_BLANKS;
	    xmlXPathCompStep(ctxt);
	}
	SKIP_BLANKS;
    }
}

/**
 * xmlXPathCompLocationPath:
 * @ctxt:  the XPath Parser context
 *
 *  [1]   LocationPath ::=   RelativeLocationPath
 *                     | AbsoluteLocationPath
 *  [2]   AbsoluteLocationPath ::=   '/' RelativeLocationPath?
 *                     | AbbreviatedAbsoluteLocationPath
 *  [10]   AbbreviatedAbsoluteLocationPath ::=
 *                           '//' RelativeLocationPath
 *
 * Compile a location path
 *
 * // is short for /descendant-or-self::node()/. For example,
 * //para is short for /descendant-or-self::node()/child::para and
 * so will select any para element in the document (even a para element
 * that is a document element will be selected by //para since the
 * document element node is a child of the root node); div//para is
 * short for div/descendant-or-self::node()/child::para and so will
 * select all para descendants of div children.
 */
static void
xmlXPathCompLocationPath(xmlXPathParserContextPtr ctxt) {
    SKIP_BLANKS;
    if (CUR != '/') {
        xmlXPathCompRelativeLocationPath(ctxt);
    } else {
	while (CUR == '/') {
	    if ((CUR == '/') && (NXT(1) == '/')) {
		SKIP(2);
		SKIP_BLANKS;
		PUSH_LONG_EXPR(XPATH_OP_COLLECT, AXIS_DESCENDANT_OR_SELF,
			     NODE_TEST_TYPE, NODE_TYPE_NODE, NULL, NULL);
		xmlXPathCompRelativeLocationPath(ctxt);
	    } else if (CUR == '/') {
		NEXT;
		SKIP_BLANKS;
		if ((CUR != 0 ) &&
		    ((IS_ASCII_LETTER(CUR)) || (CUR == '_') || (CUR == '.') ||
		     (CUR == '@') || (CUR == '*')))
		    xmlXPathCompRelativeLocationPath(ctxt);
	    }
	    CHECK_ERROR;
	}
    }
}

/************************************************************************
 *									*
 *		XPath precompiled expression evaluation			*
 *									*
 ************************************************************************/

static int
xmlXPathCompOpEval(xmlXPathParserContextPtr ctxt, xmlXPathStepOpPtr op);

#ifdef DEBUG_STEP
static void
xmlXPathDebugDumpStepAxis(xmlXPathStepOpPtr op,
			  int nbNodes)
{
    xmlGenericError(xmlGenericErrorContext, "new step : ");
    switch (op->value) {
        case AXIS_ANCESTOR:
            xmlGenericError(xmlGenericErrorContext, "axis 'ancestors' ");
            break;
        case AXIS_ANCESTOR_OR_SELF:
            xmlGenericError(xmlGenericErrorContext,
                            "axis 'ancestors-or-self' ");
            break;
        case AXIS_ATTRIBUTE:
            xmlGenericError(xmlGenericErrorContext, "axis 'attributes' ");
            break;
        case AXIS_CHILD:
            xmlGenericError(xmlGenericErrorContext, "axis 'child' ");
            break;
        case AXIS_DESCENDANT:
            xmlGenericError(xmlGenericErrorContext, "axis 'descendant' ");
            break;
        case AXIS_DESCENDANT_OR_SELF:
            xmlGenericError(xmlGenericErrorContext,
                            "axis 'descendant-or-self' ");
            break;
        case AXIS_FOLLOWING:
            xmlGenericError(xmlGenericErrorContext, "axis 'following' ");
            break;
        case AXIS_FOLLOWING_SIBLING:
            xmlGenericError(xmlGenericErrorContext,
                            "axis 'following-siblings' ");
            break;
        case AXIS_NAMESPACE:
            xmlGenericError(xmlGenericErrorContext, "axis 'namespace' ");
            break;
        case AXIS_PARENT:
            xmlGenericError(xmlGenericErrorContext, "axis 'parent' ");
            break;
        case AXIS_PRECEDING:
            xmlGenericError(xmlGenericErrorContext, "axis 'preceding' ");
            break;
        case AXIS_PRECEDING_SIBLING:
            xmlGenericError(xmlGenericErrorContext,
                            "axis 'preceding-sibling' ");
            break;
        case AXIS_SELF:
            xmlGenericError(xmlGenericErrorContext, "axis 'self' ");
            break;
    }
    xmlGenericError(xmlGenericErrorContext,
	" context contains %d nodes\n", nbNodes);
    switch (op->value2) {
        case NODE_TEST_NONE:
            xmlGenericError(xmlGenericErrorContext,
                            "           searching for none !!!\n");
            break;
        case NODE_TEST_TYPE:
            xmlGenericError(xmlGenericErrorContext,
                            "           searching for type %d\n", op->value3);
            break;
        case NODE_TEST_PI:
            xmlGenericError(xmlGenericErrorContext,
                            "           searching for PI !!!\n");
            break;
        case NODE_TEST_ALL:
            xmlGenericError(xmlGenericErrorContext,
                            "           searching for *\n");
            break;
        case NODE_TEST_NS:
            xmlGenericError(xmlGenericErrorContext,
                            "           searching for namespace %s\n",
                            op->value5);
            break;
        case NODE_TEST_NAME:
            xmlGenericError(xmlGenericErrorContext,
                            "           searching for name %s\n", op->value5);
            if (op->value4)
                xmlGenericError(xmlGenericErrorContext,
                                "           with namespace %s\n", op->value4);
            break;
    }
    xmlGenericError(xmlGenericErrorContext, "Testing : ");
}
#endif /* DEBUG_STEP */

static int
xmlXPathCompOpEvalPredicate(xmlXPathParserContextPtr ctxt,
			    xmlXPathStepOpPtr op,
			    xmlNodeSetPtr set,
			    int contextSize,
			    int hasNsNodes)
{
    if (op->ch1 != -1) {
	xmlXPathCompExprPtr comp = ctxt->comp;
	/*
	* Process inner predicates first.
	*/
	if (comp->steps[op->ch1].op != XPATH_OP_PREDICATE) {
	    /*
	    * TODO: raise an internal error.
	    */
	}
	contextSize = xmlXPathCompOpEvalPredicate(ctxt,
	    &comp->steps[op->ch1], set, contextSize, hasNsNodes);
	CHECK_ERROR0;
	if (contextSize <= 0)
	    return(0);
    }
    if (op->ch2 != -1) {
	xmlXPathContextPtr xpctxt = ctxt->context;
	xmlNodePtr contextNode, oldContextNode;
	xmlDocPtr oldContextDoc;
	int i, res, contextPos = 0, newContextSize;
	xmlXPathStepOpPtr exprOp;
	xmlXPathObjectPtr contextObj = NULL, exprRes = NULL;

#ifdef LIBXML_XPTR_ENABLED
	/*
	* URGENT TODO: Check the following:
	*  We don't expect location sets if evaluating prediates, right?
	*  Only filters should expect location sets, right?
	*/
#endif
	/*
	* SPEC XPath 1.0:
	*  "For each node in the node-set to be filtered, the
	*  PredicateExpr is evaluated with that node as the
	*  context node, with the number of nodes in the
	*  node-set as the context size, and with the proximity
	*  position of the node in the node-set with respect to
	*  the axis as the context position;"
	* @oldset is the node-set" to be filtered.
	*
	* SPEC XPath 1.0:
	*  "only predicates change the context position and
	*  context size (see [2.4 Predicates])."
	* Example:
	*   node-set  context pos
	*    nA         1
	*    nB         2
	*    nC         3
	*   After applying predicate [position() > 1] :
	*   node-set  context pos
	*    nB         1
	*    nC         2
	*/
	oldContextNode = xpctxt->node;
	oldContextDoc = xpctxt->doc;
	/*
	* Get the expression of this predicate.
	*/
	exprOp = &ctxt->comp->steps[op->ch2];
	newContextSize = 0;
	for (i = 0; i < set->nodeNr; i++) {
	    if (set->nodeTab[i] == NULL)
		continue;

	    contextNode = set->nodeTab[i];
	    xpctxt->node = contextNode;
	    xpctxt->contextSize = contextSize;
	    xpctxt->proximityPosition = ++contextPos;

	    /*
	    * Also set the xpath document in case things like
	    * key() are evaluated in the predicate.
	    */
	    if ((contextNode->type != XML_NAMESPACE_DECL) &&
		(contextNode->doc != NULL))
		xpctxt->doc = contextNode->doc;
	    /*
	    * Evaluate the predicate expression with 1 context node
	    * at a time; this node is packaged into a node set; this
	    * node set is handed over to the evaluation mechanism.
	    */
	    if (contextObj == NULL)
		contextObj = xmlXPathCacheNewNodeSet(xpctxt, contextNode);
	    else
		xmlXPathNodeSetAddUnique(contextObj->nodesetval,
		    contextNode);

	    valuePush(ctxt, contextObj);

	    res = xmlXPathCompOpEvalToBoolean(ctxt, exprOp, 1);

	    if ((ctxt->error != XPATH_EXPRESSION_OK) || (res == -1)) {
		xmlXPathNodeSetClear(set, hasNsNodes);
		newContextSize = 0;
		goto evaluation_exit;
	    }

	    if (res != 0) {
		newContextSize++;
	    } else {
		/*
		* Remove the entry from the initial node set.
		*/
		set->nodeTab[i] = NULL;
		if (contextNode->type == XML_NAMESPACE_DECL)
		    xmlXPathNodeSetFreeNs((xmlNsPtr) contextNode);
	    }
	    if (ctxt->value == contextObj) {
		/*
		* Don't free the temporary XPath object holding the
		* context node, in order to avoid massive recreation
		* inside this loop.
		*/
		valuePop(ctxt);
		xmlXPathNodeSetClear(contextObj->nodesetval, hasNsNodes);
	    } else {
		/*
		* TODO: The object was lost in the evaluation machinery.
		*  Can this happen? Maybe in internal-error cases.
		*/
		contextObj = NULL;
	    }
	}

	if (contextObj != NULL) {
	    if (ctxt->value == contextObj)
		valuePop(ctxt);
	    xmlXPathReleaseObject(xpctxt, contextObj);
	}
evaluation_exit:
	if (exprRes != NULL)
	    xmlXPathReleaseObject(ctxt->context, exprRes);
	/*
	* Reset/invalidate the context.
	*/
	xpctxt->node = oldContextNode;
	xpctxt->doc = oldContextDoc;
	xpctxt->contextSize = -1;
	xpctxt->proximityPosition = -1;
	return(newContextSize);
    }
    return(contextSize);
}

static int
xmlXPathCompOpEvalPositionalPredicate(xmlXPathParserContextPtr ctxt,
				      xmlXPathStepOpPtr op,
				      xmlNodeSetPtr set,
				      int contextSize,
				      int minPos,
				      int maxPos,
				      int hasNsNodes)
{
    if (op->ch1 != -1) {
	xmlXPathCompExprPtr comp = ctxt->comp;
	if (comp->steps[op->ch1].op != XPATH_OP_PREDICATE) {
	    /*
	    * TODO: raise an internal error.
	    */
	}
	contextSize = xmlXPathCompOpEvalPredicate(ctxt,
	    &comp->steps[op->ch1], set, contextSize, hasNsNodes);
	CHECK_ERROR0;
	if (contextSize <= 0)
	    return(0);
    }
    /*
    * Check if the node set contains a sufficient number of nodes for
    * the requested range.
    */
    if (contextSize < minPos) {
	xmlXPathNodeSetClear(set, hasNsNodes);
	return(0);
    }
    if (op->ch2 == -1) {
	/*
	* TODO: Can this ever happen?
	*/
	return (contextSize);
    } else {
	xmlDocPtr oldContextDoc;
	int i, pos = 0, newContextSize = 0, contextPos = 0, res;
	xmlXPathStepOpPtr exprOp;
	xmlXPathObjectPtr contextObj = NULL, exprRes = NULL;
	xmlNodePtr oldContextNode, contextNode = NULL;
	xmlXPathContextPtr xpctxt = ctxt->context;

#ifdef LIBXML_XPTR_ENABLED
	    /*
	    * URGENT TODO: Check the following:
	    *  We don't expect location sets if evaluating prediates, right?
	    *  Only filters should expect location sets, right?
	*/
#endif /* LIBXML_XPTR_ENABLED */

	/*
	* Save old context.
	*/
	oldContextNode = xpctxt->node;
	oldContextDoc = xpctxt->doc;
	/*
	* Get the expression of this predicate.
	*/
	exprOp = &ctxt->comp->steps[op->ch2];
	for (i = 0; i < set->nodeNr; i++) {
	    if (set->nodeTab[i] == NULL)
		continue;

	    contextNode = set->nodeTab[i];
	    xpctxt->node = contextNode;
	    xpctxt->contextSize = contextSize;
	    xpctxt->proximityPosition = ++contextPos;

	    /*
	    * Initialize the new set.
	    * Also set the xpath document in case things like
	    * key() evaluation are attempted on the predicate
	    */
	    if ((contextNode->type != XML_NAMESPACE_DECL) &&
		(contextNode->doc != NULL))
		xpctxt->doc = contextNode->doc;
	    /*
	    * Evaluate the predicate expression with 1 context node
	    * at a time; this node is packaged into a node set; this
	    * node set is handed over to the evaluation mechanism.
	    */
	    if (contextObj == NULL)
		contextObj = xmlXPathCacheNewNodeSet(xpctxt, contextNode);
	    else
		xmlXPathNodeSetAddUnique(contextObj->nodesetval,
		    contextNode);

	    valuePush(ctxt, contextObj);
	    res = xmlXPathCompOpEvalToBoolean(ctxt, exprOp, 1);

	    if ((ctxt->error != XPATH_EXPRESSION_OK) || (res == -1)) {
	        xmlXPathObjectPtr tmp;
		/* pop the result if any */
		tmp = valuePop(ctxt);
                while (tmp != contextObj) {
                    /*
                     * Free up the result
                     * then pop off contextObj, which will be freed later
                     */
                    xmlXPathReleaseObject(xpctxt, tmp);
                    tmp = valuePop(ctxt);
                }
		goto evaluation_error;
	    }

	    if (res)
		pos++;

	    if (res && (pos >= minPos) && (pos <= maxPos)) {
		/*
		* Fits in the requested range.
		*/
		newContextSize++;
		if (minPos == maxPos) {
		    /*
		    * Only 1 node was requested.
		    */
		    if (contextNode->type == XML_NAMESPACE_DECL) {
			/*
			* As always: take care of those nasty
			* namespace nodes.
			*/
			set->nodeTab[i] = NULL;
		    }
		    xmlXPathNodeSetClear(set, hasNsNodes);
		    set->nodeNr = 1;
		    set->nodeTab[0] = contextNode;
		    goto evaluation_exit;
		}
		if (pos == maxPos) {
		    /*
		    * We are done.
		    */
		    xmlXPathNodeSetClearFromPos(set, i +1, hasNsNodes);
		    goto evaluation_exit;
		}
	    } else {
		/*
		* Remove the entry from the initial node set.
		*/
		set->nodeTab[i] = NULL;
		if (contextNode->type == XML_NAMESPACE_DECL)
		    xmlXPathNodeSetFreeNs((xmlNsPtr) contextNode);
	    }
	    if (exprRes != NULL) {
		xmlXPathReleaseObject(ctxt->context, exprRes);
		exprRes = NULL;
	    }
	    if (ctxt->value == contextObj) {
		/*
		* Don't free the temporary XPath object holding the
		* context node, in order to avoid massive recreation
		* inside this loop.
		*/
		valuePop(ctxt);
		xmlXPathNodeSetClear(contextObj->nodesetval, hasNsNodes);
	    } else {
		/*
		* The object was lost in the evaluation machinery.
		* Can this happen? Maybe in case of internal-errors.
		*/
		contextObj = NULL;
	    }
	}
	goto evaluation_exit;

evaluation_error:
	xmlXPathNodeSetClear(set, hasNsNodes);
	newContextSize = 0;

evaluation_exit:
	if (contextObj != NULL) {
	    if (ctxt->value == contextObj)
		valuePop(ctxt);
	    xmlXPathReleaseObject(xpctxt, contextObj);
	}
	if (exprRes != NULL)
	    xmlXPathReleaseObject(ctxt->context, exprRes);
	/*
	* Reset/invalidate the context.
	*/
	xpctxt->node = oldContextNode;
	xpctxt->doc = oldContextDoc;
	xpctxt->contextSize = -1;
	xpctxt->proximityPosition = -1;
	return(newContextSize);
    }
    return(contextSize);
}

static int
xmlXPathIsPositionalPredicate(xmlXPathParserContextPtr ctxt,
			    xmlXPathStepOpPtr op,
			    int *maxPos)
{

    xmlXPathStepOpPtr exprOp;

    /*
    * BIG NOTE: This is not intended for XPATH_OP_FILTER yet!
    */

    /*
    * If not -1, then ch1 will point to:
    * 1) For predicates (XPATH_OP_PREDICATE):
    *    - an inner predicate operator
    * 2) For filters (XPATH_OP_FILTER):
    *    - an inner filter operater OR
    *    - an expression selecting the node set.
    *      E.g. "key('a', 'b')" or "(//foo | //bar)".
    */
    if ((op->op != XPATH_OP_PREDICATE) && (op->op != XPATH_OP_FILTER))
	return(0);

    if (op->ch2 != -1) {
	exprOp = &ctxt->comp->steps[op->ch2];
    } else
	return(0);

    if ((exprOp != NULL) &&
	(exprOp->op == XPATH_OP_VALUE) &&
	(exprOp->value4 != NULL) &&
	(((xmlXPathObjectPtr) exprOp->value4)->type == XPATH_NUMBER))
    {
	/*
	* We have a "[n]" predicate here.
	* TODO: Unfortunately this simplistic test here is not
	* able to detect a position() predicate in compound
	* expressions like "[@attr = 'a" and position() = 1],
	* and even not the usage of position() in
	* "[position() = 1]"; thus - obviously - a position-range,
	* like it "[position() < 5]", is also not detected.
	* Maybe we could rewrite the AST to ease the optimization.
	*/
	*maxPos = (int) ((xmlXPathObjectPtr) exprOp->value4)->floatval;

	if (((xmlXPathObjectPtr) exprOp->value4)->floatval ==
	    (float) *maxPos)
	{
	    return(1);
	}
    }
    return(0);
}

static int
xmlXPathNodeCollectAndTest(xmlXPathParserContextPtr ctxt,
                           xmlXPathStepOpPtr op,
			   xmlNodePtr * first, xmlNodePtr * last,
			   int toBool)
{

#define XP_TEST_HIT \
    if (hasAxisRange != 0) { \
	if (++pos == maxPos) { \
	    addNode(seq, cur); \
	goto axis_range_end; } \
    } else { \
	addNode(seq, cur); \
	if (breakOnFirstHit) goto first_hit; }

#define XP_TEST_HIT_NS \
    if (hasAxisRange != 0) { \
	if (++pos == maxPos) { \
	    hasNsNodes = 1; \
	    xmlXPathNodeSetAddNs(seq, xpctxt->node, (xmlNsPtr) cur); \
	goto axis_range_end; } \
    } else { \
	hasNsNodes = 1; \
	xmlXPathNodeSetAddNs(seq, \
	xpctxt->node, (xmlNsPtr) cur); \
	if (breakOnFirstHit) goto first_hit; }

    xmlXPathAxisVal axis = (xmlXPathAxisVal) op->value;
    xmlXPathTestVal test = (xmlXPathTestVal) op->value2;
    xmlXPathTypeVal type = (xmlXPathTypeVal) op->value3;
    const xmlChar *prefix = op->value4;
    const xmlChar *name = op->value5;
    const xmlChar *URI = NULL;

#ifdef DEBUG_STEP
    int nbMatches = 0, prevMatches = 0;
#endif
    int total = 0, hasNsNodes = 0;
    /* The popped object holding the context nodes */
    xmlXPathObjectPtr obj;
    /* The set of context nodes for the node tests */
    xmlNodeSetPtr contextSeq;
    int contextIdx;
    xmlNodePtr contextNode;
    /* The context node for a compound traversal */
    xmlNodePtr outerContextNode;
    /* The final resulting node set wrt to all context nodes */
    xmlNodeSetPtr outSeq;
    /*
    * The temporary resulting node set wrt 1 context node.
    * Used to feed predicate evaluation.
    */
    xmlNodeSetPtr seq;
    xmlNodePtr cur;
    /* First predicate operator */
    xmlXPathStepOpPtr predOp;
    int maxPos; /* The requested position() (when a "[n]" predicate) */
    int hasPredicateRange, hasAxisRange, pos, size, newSize;
    int breakOnFirstHit;

    xmlXPathTraversalFunction next = NULL;
    /* compound axis traversal */
    xmlXPathTraversalFunctionExt outerNext = NULL;
    void (*addNode) (xmlNodeSetPtr, xmlNodePtr);
    xmlXPathNodeSetMergeFunction mergeAndClear;
    xmlNodePtr oldContextNode;
    xmlXPathContextPtr xpctxt = ctxt->context;


    CHECK_TYPE0(XPATH_NODESET);
    obj = valuePop(ctxt);
    /*
    * Setup namespaces.
    */
    if (prefix != NULL) {
        URI = xmlXPathNsLookup(xpctxt, prefix);
        if (URI == NULL) {
	    xmlXPathReleaseObject(xpctxt, obj);
            XP_ERROR0(XPATH_UNDEF_PREFIX_ERROR);
	}
    }
    /*
    * Setup axis.
    *
    * MAYBE FUTURE TODO: merging optimizations:
    * - If the nodes to be traversed wrt to the initial nodes and
    *   the current axis cannot overlap, then we could avoid searching
    *   for duplicates during the merge.
    *   But the question is how/when to evaluate if they cannot overlap.
    *   Example: if we know that for two initial nodes, the one is
    *   not in the ancestor-or-self axis of the other, then we could safely
    *   avoid a duplicate-aware merge, if the axis to be traversed is e.g.
    *   the descendant-or-self axis.
    */
    mergeAndClear = xmlXPathNodeSetMergeAndClear;
    switch (axis) {
        case AXIS_ANCESTOR:
            first = NULL;
            next = xmlXPathNextAncestor;
            break;
        case AXIS_ANCESTOR_OR_SELF:
            first = NULL;
            next = xmlXPathNextAncestorOrSelf;
            break;
        case AXIS_ATTRIBUTE:
            first = NULL;
	    last = NULL;
            next = xmlXPathNextAttribute;
	    mergeAndClear = xmlXPathNodeSetMergeAndClearNoDupls;
            break;
        case AXIS_CHILD:
	    last = NULL;
	    if (op->rewriteType == XP_REWRITE_DOS_CHILD_ELEM) {
		/*
		* This iterator will give us only nodes which can
		* hold element nodes.
		*/
		outerNext = xmlXPathNextDescendantOrSelfElemParent;
	    }
	    if (((test == NODE_TEST_NAME) || (test == NODE_TEST_ALL)) &&
		(type == NODE_TYPE_NODE))
	    {
		/*
		* Optimization if an element node type is 'element'.
		*/
		next = xmlXPathNextChildElement;
	    } else
		next = xmlXPathNextChild;
	    mergeAndClear = xmlXPathNodeSetMergeAndClearNoDupls;
            break;
        case AXIS_DESCENDANT:
	    last = NULL;
            next = xmlXPathNextDescendant;
            break;
        case AXIS_DESCENDANT_OR_SELF:
	    last = NULL;
            next = xmlXPathNextDescendantOrSelf;
            break;
        case AXIS_FOLLOWING:
	    last = NULL;
            next = xmlXPathNextFollowing;
            break;
        case AXIS_FOLLOWING_SIBLING:
	    last = NULL;
            next = xmlXPathNextFollowingSibling;
            break;
        case AXIS_NAMESPACE:
            first = NULL;
	    last = NULL;
            next = (xmlXPathTraversalFunction) xmlXPathNextNamespace;
	    mergeAndClear = xmlXPathNodeSetMergeAndClearNoDupls;
            break;
        case AXIS_PARENT:
            first = NULL;
            next = xmlXPathNextParent;
            break;
        case AXIS_PRECEDING:
            first = NULL;
            next = xmlXPathNextPrecedingInternal;
            break;
        case AXIS_PRECEDING_SIBLING:
            first = NULL;
            next = xmlXPathNextPrecedingSibling;
            break;
        case AXIS_SELF:
            first = NULL;
	    last = NULL;
            next = xmlXPathNextSelf;
	    mergeAndClear = xmlXPathNodeSetMergeAndClearNoDupls;
            break;
    }

#ifdef DEBUG_STEP
    xmlXPathDebugDumpStepAxis(op,
	(obj->nodesetval != NULL) ? obj->nodesetval->nodeNr : 0);
#endif

    if (next == NULL) {
	xmlXPathReleaseObject(xpctxt, obj);
        return(0);
    }
    contextSeq = obj->nodesetval;
    if ((contextSeq == NULL) || (contextSeq->nodeNr <= 0)) {
	xmlXPathReleaseObject(xpctxt, obj);
        valuePush(ctxt, xmlXPathCacheWrapNodeSet(xpctxt, NULL));
        return(0);
    }
    /*
    * Predicate optimization ---------------------------------------------
    * If this step has a last predicate, which contains a position(),
    * then we'll optimize (although not exactly "position()", but only
    * the  short-hand form, i.e., "[n]".
    *
    * Example - expression "/foo[parent::bar][1]":
    *
    * COLLECT 'child' 'name' 'node' foo    -- op (we are here)
    *   ROOT                               -- op->ch1
    *   PREDICATE                          -- op->ch2 (predOp)
    *     PREDICATE                          -- predOp->ch1 = [parent::bar]
    *       SORT
    *         COLLECT  'parent' 'name' 'node' bar
    *           NODE
    *     ELEM Object is a number : 1        -- predOp->ch2 = [1]
    *
    */
    maxPos = 0;
    predOp = NULL;
    hasPredicateRange = 0;
    hasAxisRange = 0;
    if (op->ch2 != -1) {
	/*
	* There's at least one predicate. 16 == XPATH_OP_PREDICATE
	*/
	predOp = &ctxt->comp->steps[op->ch2];
	if (xmlXPathIsPositionalPredicate(ctxt, predOp, &maxPos)) {
	    if (predOp->ch1 != -1) {
		/*
		* Use the next inner predicate operator.
		*/
		predOp = &ctxt->comp->steps[predOp->ch1];
		hasPredicateRange = 1;
	    } else {
		/*
		* There's no other predicate than the [n] predicate.
		*/
		predOp = NULL;
		hasAxisRange = 1;
	    }
	}
    }
    breakOnFirstHit = ((toBool) && (predOp == NULL)) ? 1 : 0;
    /*
    * Axis traversal -----------------------------------------------------
    */
    /*
     * 2.3 Node Tests
     *  - For the attribute axis, the principal node type is attribute.
     *  - For the namespace axis, the principal node type is namespace.
     *  - For other axes, the principal node type is element.
     *
     * A node test * is true for any node of the
     * principal node type. For example, child::* will
     * select all element children of the context node
     */
    oldContextNode = xpctxt->node;
    addNode = xmlXPathNodeSetAddUnique;
    outSeq = NULL;
    seq = NULL;
    outerContextNode = NULL;
    contextNode = NULL;
    contextIdx = 0;


    while ((contextIdx < contextSeq->nodeNr) || (contextNode != NULL)) {
	if (outerNext != NULL) {
	    /*
	    * This is a compound traversal.
	    */
	    if (contextNode == NULL) {
		/*
		* Set the context for the outer traversal.
		*/
		outerContextNode = contextSeq->nodeTab[contextIdx++];
		contextNode = outerNext(NULL, outerContextNode);
	    } else
		contextNode = outerNext(contextNode, outerContextNode);
	    if (contextNode == NULL)
		continue;
	    /*
	    * Set the context for the main traversal.
	    */
	    xpctxt->node = contextNode;
	} else
	    xpctxt->node = contextSeq->nodeTab[contextIdx++];

	if (seq == NULL) {
	    seq = xmlXPathNodeSetCreate(NULL);
	    if (seq == NULL) {
		total = 0;
		goto error;
	    }
	}
	/*
	* Traverse the axis and test the nodes.
	*/
	pos = 0;
	cur = NULL;
	hasNsNodes = 0;
        do {
            cur = next(ctxt, cur);
            if (cur == NULL)
                break;

	    /*
	    * QUESTION TODO: What does the "first" and "last" stuff do?
	    */
            if ((first != NULL) && (*first != NULL)) {
		if (*first == cur)
		    break;
		if (((total % 256) == 0) &&
#ifdef XP_OPTIMIZED_NON_ELEM_COMPARISON
		    (xmlXPathCmpNodesExt(*first, cur) >= 0))
#else
		    (xmlXPathCmpNodes(*first, cur) >= 0))
#endif
		{
		    break;
		}
	    }
	    if ((last != NULL) && (*last != NULL)) {
		if (*last == cur)
		    break;
		if (((total % 256) == 0) &&
#ifdef XP_OPTIMIZED_NON_ELEM_COMPARISON
		    (xmlXPathCmpNodesExt(cur, *last) >= 0))
#else
		    (xmlXPathCmpNodes(cur, *last) >= 0))
#endif
		{
		    break;
		}
	    }

            total++;

#ifdef DEBUG_STEP
            xmlGenericError(xmlGenericErrorContext, " %s", cur->name);
#endif

	    switch (test) {
                case NODE_TEST_NONE:
		    total = 0;
                    STRANGE
		    goto error;
                case NODE_TEST_TYPE:
		    /*
		    * TODO: Don't we need to use
		    *  xmlXPathNodeSetAddNs() for namespace nodes here?
		    *  Surprisingly, some c14n tests fail, if we do this.
		    */
		    if (type == NODE_TYPE_NODE) {
			switch (cur->type) {
			    case XML_DOCUMENT_NODE:
			    case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
			    case XML_DOCB_DOCUMENT_NODE:
#endif
			    case XML_ELEMENT_NODE:
			    case XML_ATTRIBUTE_NODE:
			    case XML_PI_NODE:
			    case XML_COMMENT_NODE:
			    case XML_CDATA_SECTION_NODE:
			    case XML_TEXT_NODE:
			    case XML_NAMESPACE_DECL:
				XP_TEST_HIT
				break;
			    default:
				break;
			}
		    } else if (cur->type == type) {
			if (cur->type == XML_NAMESPACE_DECL)
			    XP_TEST_HIT_NS
			else
			    XP_TEST_HIT
		    } else if ((type == NODE_TYPE_TEXT) &&
			 (cur->type == XML_CDATA_SECTION_NODE))
		    {
			XP_TEST_HIT
		    }
		    break;
                case NODE_TEST_PI:
                    if ((cur->type == XML_PI_NODE) &&
                        ((name == NULL) || xmlStrEqual(name, cur->name)))
		    {
			XP_TEST_HIT
                    }
                    break;
                case NODE_TEST_ALL:
                    if (axis == AXIS_ATTRIBUTE) {
                        if (cur->type == XML_ATTRIBUTE_NODE)
			{
			    XP_TEST_HIT
                        }
                    } else if (axis == AXIS_NAMESPACE) {
                        if (cur->type == XML_NAMESPACE_DECL)
			{
			    XP_TEST_HIT_NS
                        }
                    } else {
                        if (cur->type == XML_ELEMENT_NODE) {
                            if (prefix == NULL)
			    {
				XP_TEST_HIT

                            } else if ((cur->ns != NULL) &&
				(xmlStrEqual(URI, cur->ns->href)))
			    {
				XP_TEST_HIT
                            }
                        }
                    }
                    break;
                case NODE_TEST_NS:{
                        TODO;
                        break;
                    }
                case NODE_TEST_NAME:
                    if (axis == AXIS_ATTRIBUTE) {
                        if (cur->type != XML_ATTRIBUTE_NODE)
			    break;
		    } else if (axis == AXIS_NAMESPACE) {
                        if (cur->type != XML_NAMESPACE_DECL)
			    break;
		    } else {
		        if (cur->type != XML_ELEMENT_NODE)
			    break;
		    }
                    switch (cur->type) {
                        case XML_ELEMENT_NODE:
                            if (xmlStrEqual(name, cur->name)) {
                                if (prefix == NULL) {
                                    if (cur->ns == NULL)
				    {
					XP_TEST_HIT
                                    }
                                } else {
                                    if ((cur->ns != NULL) &&
                                        (xmlStrEqual(URI, cur->ns->href)))
				    {
					XP_TEST_HIT
                                    }
                                }
                            }
                            break;
                        case XML_ATTRIBUTE_NODE:{
                                xmlAttrPtr attr = (xmlAttrPtr) cur;

                                if (xmlStrEqual(name, attr->name)) {
                                    if (prefix == NULL) {
                                        if ((attr->ns == NULL) ||
                                            (attr->ns->prefix == NULL))
					{
					    XP_TEST_HIT
                                        }
                                    } else {
                                        if ((attr->ns != NULL) &&
                                            (xmlStrEqual(URI,
					      attr->ns->href)))
					{
					    XP_TEST_HIT
                                        }
                                    }
                                }
                                break;
                            }
                        case XML_NAMESPACE_DECL:
                            if (cur->type == XML_NAMESPACE_DECL) {
                                xmlNsPtr ns = (xmlNsPtr) cur;

                                if ((ns->prefix != NULL) && (name != NULL)
                                    && (xmlStrEqual(ns->prefix, name)))
				{
				    XP_TEST_HIT_NS
                                }
                            }
                            break;
                        default:
                            break;
                    }
                    break;
	    } /* switch(test) */
        } while (cur != NULL);

	goto apply_predicates;

axis_range_end: /* ----------------------------------------------------- */
	/*
	* We have a "/foo[n]", and position() = n was reached.
	* Note that we can have as well "/foo/::parent::foo[1]", so
	* a duplicate-aware merge is still needed.
	* Merge with the result.
	*/
	if (outSeq == NULL) {
	    outSeq = seq;
	    seq = NULL;
	} else
	    outSeq = mergeAndClear(outSeq, seq, 0);
	/*
	* Break if only a true/false result was requested.
	*/
	if (toBool)
	    break;
	continue;

first_hit: /* ---------------------------------------------------------- */
	/*
	* Break if only a true/false result was requested and
	* no predicates existed and a node test succeeded.
	*/
	if (outSeq == NULL) {
	    outSeq = seq;
	    seq = NULL;
	} else
	    outSeq = mergeAndClear(outSeq, seq, 0);
	break;

#ifdef DEBUG_STEP
	if (seq != NULL)
	    nbMatches += seq->nodeNr;
#endif

apply_predicates: /* --------------------------------------------------- */
        /*
	* Apply predicates.
	*/
        if ((predOp != NULL) && (seq->nodeNr > 0)) {
	    /*
	    * E.g. when we have a "/foo[some expression][n]".
	    */	    
	    /*
	    * QUESTION TODO: The old predicate evaluation took into
	    *  account location-sets.
	    *  (E.g. ctxt->value->type == XPATH_LOCATIONSET)
	    *  Do we expect such a set here?
	    *  All what I learned now from the evaluation semantics
	    *  does not indicate that a location-set will be processed
	    *  here, so this looks OK.
	    */	    
	    /*
	    * Iterate over all predicates, starting with the outermost
	    * predicate.
	    * TODO: Problem: we cannot execute the inner predicates first
	    *  since we cannot go back *up* the operator tree!
	    *  Options we have:
	    *  1) Use of recursive functions (like is it currently done
	    *     via xmlXPathCompOpEval())
	    *  2) Add a predicate evaluation information stack to the
	    *     context struct
	    *  3) Change the way the operators are linked; we need a
	    *     "parent" field on xmlXPathStepOp
	    *
	    * For the moment, I'll try to solve this with a recursive
	    * function: xmlXPathCompOpEvalPredicate().
	    */
	    size = seq->nodeNr;
	    if (hasPredicateRange != 0)
		newSize = xmlXPathCompOpEvalPositionalPredicate(ctxt,
		    predOp, seq, size, maxPos, maxPos, hasNsNodes);
	    else
		newSize = xmlXPathCompOpEvalPredicate(ctxt,
		    predOp, seq, size, hasNsNodes);

	    if (ctxt->error != XPATH_EXPRESSION_OK) {
		total = 0;
		goto error;
	    }
	    /*
	    * Add the filtered set of nodes to the result node set.
	    */
	    if (newSize == 0) {
		/*
		* The predicates filtered all nodes out.
		*/
		xmlXPathNodeSetClear(seq, hasNsNodes);
	    } else if (seq->nodeNr > 0) {
		/*
		* Add to result set.
		*/
		if (outSeq == NULL) {
		    if (size != newSize) {
			/*
			* We need to merge and clear here, since
			* the sequence will contained NULLed entries.
			*/
			outSeq = mergeAndClear(NULL, seq, 1);
		    } else {
			outSeq = seq;
			seq = NULL;
		    }
		} else
		    outSeq = mergeAndClear(outSeq, seq,
			(size != newSize) ? 1: 0);
		/*
		* Break if only a true/false result was requested.
		*/
		if (toBool)
		    break;
	    }
        } else if (seq->nodeNr > 0) {
	    /*
	    * Add to result set.
	    */
	    if (outSeq == NULL) {
		outSeq = seq;
		seq = NULL;
	    } else {
		outSeq = mergeAndClear(outSeq, seq, 0);
	    }
	}
    }

error:
    if ((obj->boolval) && (obj->user != NULL)) {
	/*
	* QUESTION TODO: What does this do and why?
	* TODO: Do we have to do this also for the "error"
	* cleanup further down?
	*/
	ctxt->value->boolval = 1;
	ctxt->value->user = obj->user;
	obj->user = NULL;
	obj->boolval = 0;
    }
    xmlXPathReleaseObject(xpctxt, obj);

    /*
    * Ensure we return at least an emtpy set.
    */
    if (outSeq == NULL) {
	if ((seq != NULL) && (seq->nodeNr == 0))
	    outSeq = seq;
	else
	    outSeq = xmlXPathNodeSetCreate(NULL);
        /* XXX what if xmlXPathNodeSetCreate returned NULL here? */
    }
    if ((seq != NULL) && (seq != outSeq)) {
	 xmlXPathFreeNodeSet(seq);
    }
    /*
    * Hand over the result. Better to push the set also in
    * case of errors.
    */
    valuePush(ctxt, xmlXPathCacheWrapNodeSet(xpctxt, outSeq));
    /*
    * Reset the context node.
    */
    xpctxt->node = oldContextNode;

#ifdef DEBUG_STEP
    xmlGenericError(xmlGenericErrorContext,
	"\nExamined %d nodes, found %d nodes at that step\n",
	total, nbMatches);
#endif

    return(total);
}

static int
xmlXPathCompOpEvalFilterFirst(xmlXPathParserContextPtr ctxt,
			      xmlXPathStepOpPtr op, xmlNodePtr * first);

/**
 * xmlXPathCompOpEvalFirst:
 * @ctxt:  the XPath parser context with the compiled expression
 * @op:  an XPath compiled operation
 * @first:  the first elem found so far
 *
 * Evaluate the Precompiled XPath operation searching only the first
 * element in document order
 *
 * Returns the number of examined objects.
 */
static int
xmlXPathCompOpEvalFirst(xmlXPathParserContextPtr ctxt,
                        xmlXPathStepOpPtr op, xmlNodePtr * first)
{
    int total = 0, cur;
    xmlXPathCompExprPtr comp;
    xmlXPathObjectPtr arg1, arg2;

    CHECK_ERROR0;
    comp = ctxt->comp;
    switch (op->op) {
        case XPATH_OP_END:
            return (0);
        case XPATH_OP_UNION:
            total =
                xmlXPathCompOpEvalFirst(ctxt, &comp->steps[op->ch1],
                                        first);
	    CHECK_ERROR0;
            if ((ctxt->value != NULL)
                && (ctxt->value->type == XPATH_NODESET)
                && (ctxt->value->nodesetval != NULL)
                && (ctxt->value->nodesetval->nodeNr >= 1)) {
                /*
                 * limit tree traversing to first node in the result
                 */
		/*
		* OPTIMIZE TODO: This implicitely sorts
		*  the result, even if not needed. E.g. if the argument
		*  of the count() function, no sorting is needed.
		* OPTIMIZE TODO: How do we know if the node-list wasn't
		*  aready sorted?
		*/
		if (ctxt->value->nodesetval->nodeNr > 1)
		    xmlXPathNodeSetSort(ctxt->value->nodesetval);
                *first = ctxt->value->nodesetval->nodeTab[0];
            }
            cur =
                xmlXPathCompOpEvalFirst(ctxt, &comp->steps[op->ch2],
                                        first);
	    CHECK_ERROR0;
            CHECK_TYPE0(XPATH_NODESET);
            arg2 = valuePop(ctxt);

            CHECK_TYPE0(XPATH_NODESET);
            arg1 = valuePop(ctxt);

            arg1->nodesetval = xmlXPathNodeSetMerge(arg1->nodesetval,
                                                    arg2->nodesetval);
            valuePush(ctxt, arg1);
	    xmlXPathReleaseObject(ctxt->context, arg2);
            /* optimizer */
	    if (total > cur)
		xmlXPathCompSwap(op);
            return (total + cur);
        case XPATH_OP_ROOT:
            xmlXPathRoot(ctxt);
            return (0);
        case XPATH_OP_NODE:
            if (op->ch1 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
            if (op->ch2 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    CHECK_ERROR0;
	    valuePush(ctxt, xmlXPathCacheNewNodeSet(ctxt->context,
		ctxt->context->node));
            return (total);
        case XPATH_OP_RESET:
            if (op->ch1 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
            if (op->ch2 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    CHECK_ERROR0;
            ctxt->context->node = NULL;
            return (total);
        case XPATH_OP_COLLECT:{
                if (op->ch1 == -1)
                    return (total);

                total = xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
		CHECK_ERROR0;

                total += xmlXPathNodeCollectAndTest(ctxt, op, first, NULL, 0);
                return (total);
            }
        case XPATH_OP_VALUE:
            valuePush(ctxt,
                      xmlXPathCacheObjectCopy(ctxt->context,
			(xmlXPathObjectPtr) op->value4));
            return (0);
        case XPATH_OP_SORT:
            if (op->ch1 != -1)
                total +=
                    xmlXPathCompOpEvalFirst(ctxt, &comp->steps[op->ch1],
                                            first);
	    CHECK_ERROR0;
            if ((ctxt->value != NULL)
                && (ctxt->value->type == XPATH_NODESET)
                && (ctxt->value->nodesetval != NULL)
		&& (ctxt->value->nodesetval->nodeNr > 1))
                xmlXPathNodeSetSort(ctxt->value->nodesetval);
            return (total);
#ifdef XP_OPTIMIZED_FILTER_FIRST
	case XPATH_OP_FILTER:
                total += xmlXPathCompOpEvalFilterFirst(ctxt, op, first);
            return (total);
#endif
        default:
            return (xmlXPathCompOpEval(ctxt, op));
    }
}

/**
 * xmlXPathCompOpEvalLast:
 * @ctxt:  the XPath parser context with the compiled expression
 * @op:  an XPath compiled operation
 * @last:  the last elem found so far
 *
 * Evaluate the Precompiled XPath operation searching only the last
 * element in document order
 *
 * Returns the number of nodes traversed
 */
static int
xmlXPathCompOpEvalLast(xmlXPathParserContextPtr ctxt, xmlXPathStepOpPtr op,
                       xmlNodePtr * last)
{
    int total = 0, cur;
    xmlXPathCompExprPtr comp;
    xmlXPathObjectPtr arg1, arg2;
    xmlNodePtr bak;
    xmlDocPtr bakd;
    int pp;
    int cs;

    CHECK_ERROR0;
    comp = ctxt->comp;
    switch (op->op) {
        case XPATH_OP_END:
            return (0);
        case XPATH_OP_UNION:
	    bakd = ctxt->context->doc;
	    bak = ctxt->context->node;
	    pp = ctxt->context->proximityPosition;
	    cs = ctxt->context->contextSize;
            total =
                xmlXPathCompOpEvalLast(ctxt, &comp->steps[op->ch1], last);
	    CHECK_ERROR0;
            if ((ctxt->value != NULL)
                && (ctxt->value->type == XPATH_NODESET)
                && (ctxt->value->nodesetval != NULL)
                && (ctxt->value->nodesetval->nodeNr >= 1)) {
                /*
                 * limit tree traversing to first node in the result
                 */
		if (ctxt->value->nodesetval->nodeNr > 1)
		    xmlXPathNodeSetSort(ctxt->value->nodesetval);
                *last =
                    ctxt->value->nodesetval->nodeTab[ctxt->value->
                                                     nodesetval->nodeNr -
                                                     1];
            }
	    ctxt->context->doc = bakd;
	    ctxt->context->node = bak;
	    ctxt->context->proximityPosition = pp;
	    ctxt->context->contextSize = cs;
            cur =
                xmlXPathCompOpEvalLast(ctxt, &comp->steps[op->ch2], last);
	    CHECK_ERROR0;
            if ((ctxt->value != NULL)
                && (ctxt->value->type == XPATH_NODESET)
                && (ctxt->value->nodesetval != NULL)
                && (ctxt->value->nodesetval->nodeNr >= 1)) { /* TODO: NOP ? */
            }
            CHECK_TYPE0(XPATH_NODESET);
            arg2 = valuePop(ctxt);

            CHECK_TYPE0(XPATH_NODESET);
            arg1 = valuePop(ctxt);

            arg1->nodesetval = xmlXPathNodeSetMerge(arg1->nodesetval,
                                                    arg2->nodesetval);
            valuePush(ctxt, arg1);
	    xmlXPathReleaseObject(ctxt->context, arg2);
            /* optimizer */
	    if (total > cur)
		xmlXPathCompSwap(op);
            return (total + cur);
        case XPATH_OP_ROOT:
            xmlXPathRoot(ctxt);
            return (0);
        case XPATH_OP_NODE:
            if (op->ch1 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
            if (op->ch2 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    CHECK_ERROR0;
	    valuePush(ctxt, xmlXPathCacheNewNodeSet(ctxt->context,
		ctxt->context->node));
            return (total);
        case XPATH_OP_RESET:
            if (op->ch1 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
            if (op->ch2 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    CHECK_ERROR0;
            ctxt->context->node = NULL;
            return (total);
        case XPATH_OP_COLLECT:{
                if (op->ch1 == -1)
                    return (0);

                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
		CHECK_ERROR0;

                total += xmlXPathNodeCollectAndTest(ctxt, op, NULL, last, 0);
                return (total);
            }
        case XPATH_OP_VALUE:
            valuePush(ctxt,
                      xmlXPathCacheObjectCopy(ctxt->context,
			(xmlXPathObjectPtr) op->value4));
            return (0);
        case XPATH_OP_SORT:
            if (op->ch1 != -1)
                total +=
                    xmlXPathCompOpEvalLast(ctxt, &comp->steps[op->ch1],
                                           last);
	    CHECK_ERROR0;
            if ((ctxt->value != NULL)
                && (ctxt->value->type == XPATH_NODESET)
                && (ctxt->value->nodesetval != NULL)
		&& (ctxt->value->nodesetval->nodeNr > 1))
                xmlXPathNodeSetSort(ctxt->value->nodesetval);
            return (total);
        default:
            return (xmlXPathCompOpEval(ctxt, op));
    }
}

#ifdef XP_OPTIMIZED_FILTER_FIRST
static int
xmlXPathCompOpEvalFilterFirst(xmlXPathParserContextPtr ctxt,
			      xmlXPathStepOpPtr op, xmlNodePtr * first)
{
    int total = 0;
    xmlXPathCompExprPtr comp;
    xmlXPathObjectPtr res;
    xmlXPathObjectPtr obj;
    xmlNodeSetPtr oldset;
    xmlNodePtr oldnode;
    xmlDocPtr oldDoc;
    int i;

    CHECK_ERROR0;
    comp = ctxt->comp;
    /*
    * Optimization for ()[last()] selection i.e. the last elem
    */
    if ((op->ch1 != -1) && (op->ch2 != -1) &&
	(comp->steps[op->ch1].op == XPATH_OP_SORT) &&
	(comp->steps[op->ch2].op == XPATH_OP_SORT)) {
	int f = comp->steps[op->ch2].ch1;

	if ((f != -1) &&
	    (comp->steps[f].op == XPATH_OP_FUNCTION) &&
	    (comp->steps[f].value5 == NULL) &&
	    (comp->steps[f].value == 0) &&
	    (comp->steps[f].value4 != NULL) &&
	    (xmlStrEqual
	    (comp->steps[f].value4, BAD_CAST "last"))) {
	    xmlNodePtr last = NULL;

	    total +=
		xmlXPathCompOpEvalLast(ctxt,
		    &comp->steps[op->ch1],
		    &last);
	    CHECK_ERROR0;
	    /*
	    * The nodeset should be in document order,
	    * Keep only the last value
	    */
	    if ((ctxt->value != NULL) &&
		(ctxt->value->type == XPATH_NODESET) &&
		(ctxt->value->nodesetval != NULL) &&
		(ctxt->value->nodesetval->nodeTab != NULL) &&
		(ctxt->value->nodesetval->nodeNr > 1)) {
		ctxt->value->nodesetval->nodeTab[0] =
		    ctxt->value->nodesetval->nodeTab[ctxt->
		    value->
		    nodesetval->
		    nodeNr -
		    1];
		ctxt->value->nodesetval->nodeNr = 1;
		*first = *(ctxt->value->nodesetval->nodeTab);
	    }
	    return (total);
	}
    }

    if (op->ch1 != -1)
	total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
    CHECK_ERROR0;
    if (op->ch2 == -1)
	return (total);
    if (ctxt->value == NULL)
	return (total);

#ifdef LIBXML_XPTR_ENABLED
    oldnode = ctxt->context->node;
    /*
    * Hum are we filtering the result of an XPointer expression
    */
    if (ctxt->value->type == XPATH_LOCATIONSET) {
	xmlXPathObjectPtr tmp = NULL;
	xmlLocationSetPtr newlocset = NULL;
	xmlLocationSetPtr oldlocset;

	/*
	* Extract the old locset, and then evaluate the result of the
	* expression for all the element in the locset. use it to grow
	* up a new locset.
	*/
	CHECK_TYPE0(XPATH_LOCATIONSET);
	obj = valuePop(ctxt);
	oldlocset = obj->user;
	ctxt->context->node = NULL;

	if ((oldlocset == NULL) || (oldlocset->locNr == 0)) {
	    ctxt->context->contextSize = 0;
	    ctxt->context->proximityPosition = 0;
	    if (op->ch2 != -1)
		total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    res = valuePop(ctxt);
	    if (res != NULL) {
		xmlXPathReleaseObject(ctxt->context, res);
	    }
	    valuePush(ctxt, obj);
	    CHECK_ERROR0;
	    return (total);
	}
	newlocset = xmlXPtrLocationSetCreate(NULL);

	for (i = 0; i < oldlocset->locNr; i++) {
	    /*
	    * Run the evaluation with a node list made of a
	    * single item in the nodelocset.
	    */
	    ctxt->context->node = oldlocset->locTab[i]->user;
	    ctxt->context->contextSize = oldlocset->locNr;
	    ctxt->context->proximityPosition = i + 1;
	    if (tmp == NULL) {
		tmp = xmlXPathCacheNewNodeSet(ctxt->context,
		    ctxt->context->node);
	    } else {
		xmlXPathNodeSetAddUnique(tmp->nodesetval,
		    ctxt->context->node);
	    }
	    valuePush(ctxt, tmp);
	    if (op->ch2 != -1)
		total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    if (ctxt->error != XPATH_EXPRESSION_OK) {
		xmlXPathFreeObject(obj);
		return(0);
	    }
	    /*
	    * The result of the evaluation need to be tested to
	    * decided whether the filter succeeded or not
	    */
	    res = valuePop(ctxt);
	    if (xmlXPathEvaluatePredicateResult(ctxt, res)) {
		xmlXPtrLocationSetAdd(newlocset,
		    xmlXPathCacheObjectCopy(ctxt->context,
			oldlocset->locTab[i]));
	    }
	    /*
	    * Cleanup
	    */
	    if (res != NULL) {
		xmlXPathReleaseObject(ctxt->context, res);
	    }
	    if (ctxt->value == tmp) {
		valuePop(ctxt);
		xmlXPathNodeSetClear(tmp->nodesetval, 1);
		/*
		* REVISIT TODO: Don't create a temporary nodeset
		* for everly iteration.
		*/
		/* OLD: xmlXPathFreeObject(res); */
	    } else
		tmp = NULL;
	    ctxt->context->node = NULL;
	    /*
	    * Only put the first node in the result, then leave.
	    */
	    if (newlocset->locNr > 0) {
		*first = (xmlNodePtr) oldlocset->locTab[i]->user;
		break;
	    }
	}
	if (tmp != NULL) {
	    xmlXPathReleaseObject(ctxt->context, tmp);
	}
	/*
	* The result is used as the new evaluation locset.
	*/
	xmlXPathReleaseObject(ctxt->context, obj);
	ctxt->context->node = NULL;
	ctxt->context->contextSize = -1;
	ctxt->context->proximityPosition = -1;
	valuePush(ctxt, xmlXPtrWrapLocationSet(newlocset));
	ctxt->context->node = oldnode;
	return (total);
    }
#endif /* LIBXML_XPTR_ENABLED */

    /*
    * Extract the old set, and then evaluate the result of the
    * expression for all the element in the set. use it to grow
    * up a new set.
    */
    CHECK_TYPE0(XPATH_NODESET);
    obj = valuePop(ctxt);
    oldset = obj->nodesetval;

    oldnode = ctxt->context->node;
    oldDoc = ctxt->context->doc;
    ctxt->context->node = NULL;

    if ((oldset == NULL) || (oldset->nodeNr == 0)) {
	ctxt->context->contextSize = 0;
	ctxt->context->proximityPosition = 0;
	/* QUESTION TODO: Why was this code commented out?
	    if (op->ch2 != -1)
		total +=
		    xmlXPathCompOpEval(ctxt,
			&comp->steps[op->ch2]);
	    CHECK_ERROR0;
	    res = valuePop(ctxt);
	    if (res != NULL)
		xmlXPathFreeObject(res);
	*/
	valuePush(ctxt, obj);
	ctxt->context->node = oldnode;
	CHECK_ERROR0;
    } else {
	xmlNodeSetPtr newset;
	xmlXPathObjectPtr tmp = NULL;
	/*
	* Initialize the new set.
	* Also set the xpath document in case things like
	* key() evaluation are attempted on the predicate
	*/
	newset = xmlXPathNodeSetCreate(NULL);
        /* XXX what if xmlXPathNodeSetCreate returned NULL? */

	for (i = 0; i < oldset->nodeNr; i++) {
	    /*
	    * Run the evaluation with a node list made of
	    * a single item in the nodeset.
	    */
	    ctxt->context->node = oldset->nodeTab[i];
	    if ((oldset->nodeTab[i]->type != XML_NAMESPACE_DECL) &&
		(oldset->nodeTab[i]->doc != NULL))
		ctxt->context->doc = oldset->nodeTab[i]->doc;
	    if (tmp == NULL) {
		tmp = xmlXPathCacheNewNodeSet(ctxt->context,
		    ctxt->context->node);
	    } else {
		xmlXPathNodeSetAddUnique(tmp->nodesetval,
		    ctxt->context->node);
	    }
	    valuePush(ctxt, tmp);
	    ctxt->context->contextSize = oldset->nodeNr;
	    ctxt->context->proximityPosition = i + 1;
	    if (op->ch2 != -1)
		total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    if (ctxt->error != XPATH_EXPRESSION_OK) {
		xmlXPathFreeNodeSet(newset);
		xmlXPathFreeObject(obj);
		return(0);
	    }
	    /*
	    * The result of the evaluation needs to be tested to
	    * decide whether the filter succeeded or not
	    */
	    res = valuePop(ctxt);
	    if (xmlXPathEvaluatePredicateResult(ctxt, res)) {
		xmlXPathNodeSetAdd(newset, oldset->nodeTab[i]);
	    }
	    /*
	    * Cleanup
	    */
	    if (res != NULL) {
		xmlXPathReleaseObject(ctxt->context, res);
	    }
	    if (ctxt->value == tmp) {
		valuePop(ctxt);
		/*
		* Don't free the temporary nodeset
		* in order to avoid massive recreation inside this
		* loop.
		*/
		xmlXPathNodeSetClear(tmp->nodesetval, 1);
	    } else
		tmp = NULL;
	    ctxt->context->node = NULL;
	    /*
	    * Only put the first node in the result, then leave.
	    */
	    if (newset->nodeNr > 0) {
		*first = *(newset->nodeTab);
		break;
	    }
	}
	if (tmp != NULL) {
	    xmlXPathReleaseObject(ctxt->context, tmp);
	}
	/*
	* The result is used as the new evaluation set.
	*/
	xmlXPathReleaseObject(ctxt->context, obj);
	ctxt->context->node = NULL;
	ctxt->context->contextSize = -1;
	ctxt->context->proximityPosition = -1;
	/* may want to move this past the '}' later */
	ctxt->context->doc = oldDoc;
	valuePush(ctxt, xmlXPathCacheWrapNodeSet(ctxt->context, newset));
    }
    ctxt->context->node = oldnode;
    return(total);
}
#endif /* XP_OPTIMIZED_FILTER_FIRST */

/**
 * xmlXPathCompOpEval:
 * @ctxt:  the XPath parser context with the compiled expression
 * @op:  an XPath compiled operation
 *
 * Evaluate the Precompiled XPath operation
 * Returns the number of nodes traversed
 */
static int
xmlXPathCompOpEval(xmlXPathParserContextPtr ctxt, xmlXPathStepOpPtr op)
{
    int total = 0;
    int equal, ret;
    xmlXPathCompExprPtr comp;
    xmlXPathObjectPtr arg1, arg2;
    xmlNodePtr bak;
    xmlDocPtr bakd;
    int pp;
    int cs;

    CHECK_ERROR0;
    comp = ctxt->comp;
    switch (op->op) {
        case XPATH_OP_END:
            return (0);
        case XPATH_OP_AND:
	    bakd = ctxt->context->doc;
	    bak = ctxt->context->node;
	    pp = ctxt->context->proximityPosition;
	    cs = ctxt->context->contextSize;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
            xmlXPathBooleanFunction(ctxt, 1);
            if ((ctxt->value == NULL) || (ctxt->value->boolval == 0))
                return (total);
            arg2 = valuePop(ctxt);
	    ctxt->context->doc = bakd;
	    ctxt->context->node = bak;
	    ctxt->context->proximityPosition = pp;
	    ctxt->context->contextSize = cs;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    if (ctxt->error) {
		xmlXPathFreeObject(arg2);
		return(0);
	    }
            xmlXPathBooleanFunction(ctxt, 1);
            arg1 = valuePop(ctxt);
            arg1->boolval &= arg2->boolval;
            valuePush(ctxt, arg1);
	    xmlXPathReleaseObject(ctxt->context, arg2);
            return (total);
        case XPATH_OP_OR:
	    bakd = ctxt->context->doc;
	    bak = ctxt->context->node;
	    pp = ctxt->context->proximityPosition;
	    cs = ctxt->context->contextSize;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
            xmlXPathBooleanFunction(ctxt, 1);
            if ((ctxt->value == NULL) || (ctxt->value->boolval == 1))
                return (total);
            arg2 = valuePop(ctxt);
	    ctxt->context->doc = bakd;
	    ctxt->context->node = bak;
	    ctxt->context->proximityPosition = pp;
	    ctxt->context->contextSize = cs;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    if (ctxt->error) {
		xmlXPathFreeObject(arg2);
		return(0);
	    }
            xmlXPathBooleanFunction(ctxt, 1);
            arg1 = valuePop(ctxt);
            arg1->boolval |= arg2->boolval;
            valuePush(ctxt, arg1);
	    xmlXPathReleaseObject(ctxt->context, arg2);
            return (total);
        case XPATH_OP_EQUAL:
	    bakd = ctxt->context->doc;
	    bak = ctxt->context->node;
	    pp = ctxt->context->proximityPosition;
	    cs = ctxt->context->contextSize;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
	    ctxt->context->doc = bakd;
	    ctxt->context->node = bak;
	    ctxt->context->proximityPosition = pp;
	    ctxt->context->contextSize = cs;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    CHECK_ERROR0;
	    if (op->value)
		equal = xmlXPathEqualValues(ctxt);
	    else
		equal = xmlXPathNotEqualValues(ctxt);
	    valuePush(ctxt, xmlXPathCacheNewBoolean(ctxt->context, equal));
            return (total);
        case XPATH_OP_CMP:
	    bakd = ctxt->context->doc;
	    bak = ctxt->context->node;
	    pp = ctxt->context->proximityPosition;
	    cs = ctxt->context->contextSize;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
	    ctxt->context->doc = bakd;
	    ctxt->context->node = bak;
	    ctxt->context->proximityPosition = pp;
	    ctxt->context->contextSize = cs;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    CHECK_ERROR0;
            ret = xmlXPathCompareValues(ctxt, op->value, op->value2);
	    valuePush(ctxt, xmlXPathCacheNewBoolean(ctxt->context, ret));
            return (total);
        case XPATH_OP_PLUS:
	    bakd = ctxt->context->doc;
	    bak = ctxt->context->node;
	    pp = ctxt->context->proximityPosition;
	    cs = ctxt->context->contextSize;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
            if (op->ch2 != -1) {
		ctxt->context->doc = bakd;
		ctxt->context->node = bak;
		ctxt->context->proximityPosition = pp;
		ctxt->context->contextSize = cs;
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    }
	    CHECK_ERROR0;
            if (op->value == 0)
                xmlXPathSubValues(ctxt);
            else if (op->value == 1)
                xmlXPathAddValues(ctxt);
            else if (op->value == 2)
                xmlXPathValueFlipSign(ctxt);
            else if (op->value == 3) {
                CAST_TO_NUMBER;
                CHECK_TYPE0(XPATH_NUMBER);
            }
            return (total);
        case XPATH_OP_MULT:
	    bakd = ctxt->context->doc;
	    bak = ctxt->context->node;
	    pp = ctxt->context->proximityPosition;
	    cs = ctxt->context->contextSize;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
	    ctxt->context->doc = bakd;
	    ctxt->context->node = bak;
	    ctxt->context->proximityPosition = pp;
	    ctxt->context->contextSize = cs;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    CHECK_ERROR0;
            if (op->value == 0)
                xmlXPathMultValues(ctxt);
            else if (op->value == 1)
                xmlXPathDivValues(ctxt);
            else if (op->value == 2)
                xmlXPathModValues(ctxt);
            return (total);
        case XPATH_OP_UNION:
	    bakd = ctxt->context->doc;
	    bak = ctxt->context->node;
	    pp = ctxt->context->proximityPosition;
	    cs = ctxt->context->contextSize;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
	    ctxt->context->doc = bakd;
	    ctxt->context->node = bak;
	    ctxt->context->proximityPosition = pp;
	    ctxt->context->contextSize = cs;
            total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    CHECK_ERROR0;
            CHECK_TYPE0(XPATH_NODESET);
            arg2 = valuePop(ctxt);

            CHECK_TYPE0(XPATH_NODESET);
            arg1 = valuePop(ctxt);

	    if ((arg1->nodesetval == NULL) ||
		((arg2->nodesetval != NULL) &&
		 (arg2->nodesetval->nodeNr != 0)))
	    {
		arg1->nodesetval = xmlXPathNodeSetMerge(arg1->nodesetval,
							arg2->nodesetval);
	    }

            valuePush(ctxt, arg1);
	    xmlXPathReleaseObject(ctxt->context, arg2);
            return (total);
        case XPATH_OP_ROOT:
            xmlXPathRoot(ctxt);
            return (total);
        case XPATH_OP_NODE:
            if (op->ch1 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
            if (op->ch2 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    CHECK_ERROR0;
	    valuePush(ctxt, xmlXPathCacheNewNodeSet(ctxt->context,
		ctxt->context->node));
            return (total);
        case XPATH_OP_RESET:
            if (op->ch1 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
            if (op->ch2 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	    CHECK_ERROR0;
            ctxt->context->node = NULL;
            return (total);
        case XPATH_OP_COLLECT:{
                if (op->ch1 == -1)
                    return (total);

                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
		CHECK_ERROR0;

                total += xmlXPathNodeCollectAndTest(ctxt, op, NULL, NULL, 0);
                return (total);
            }
        case XPATH_OP_VALUE:
            valuePush(ctxt,
                      xmlXPathCacheObjectCopy(ctxt->context,
			(xmlXPathObjectPtr) op->value4));
            return (total);
        case XPATH_OP_VARIABLE:{
		xmlXPathObjectPtr val;

                if (op->ch1 != -1)
                    total +=
                        xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
                if (op->value5 == NULL) {
		    val = xmlXPathVariableLookup(ctxt->context, op->value4);
		    if (val == NULL) {
			ctxt->error = XPATH_UNDEF_VARIABLE_ERROR;
			return(0);
		    }
                    valuePush(ctxt, val);
		} else {
                    const xmlChar *URI;

                    URI = xmlXPathNsLookup(ctxt->context, op->value5);
                    if (URI == NULL) {
                        xmlGenericError(xmlGenericErrorContext,
            "xmlXPathCompOpEval: variable %s bound to undefined prefix %s\n",
                                    (char *) op->value4, (char *)op->value5);
                        ctxt->error = XPATH_UNDEF_PREFIX_ERROR;
                        return (total);
                    }
		    val = xmlXPathVariableLookupNS(ctxt->context,
                                                       op->value4, URI);
		    if (val == NULL) {
			ctxt->error = XPATH_UNDEF_VARIABLE_ERROR;
			return(0);
		    }
                    valuePush(ctxt, val);
                }
                return (total);
            }
        case XPATH_OP_FUNCTION:{
                xmlXPathFunction func;
                const xmlChar *oldFunc, *oldFuncURI;
		int i;

                if (op->ch1 != -1)
                    total +=
                        xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
		if (ctxt->valueNr < op->value) {
		    xmlGenericError(xmlGenericErrorContext,
			    "xmlXPathCompOpEval: parameter error\n");
		    ctxt->error = XPATH_INVALID_OPERAND;
		    return (total);
		}
		for (i = 0; i < op->value; i++)
		    if (ctxt->valueTab[(ctxt->valueNr - 1) - i] == NULL) {
			xmlGenericError(xmlGenericErrorContext,
				"xmlXPathCompOpEval: parameter error\n");
			ctxt->error = XPATH_INVALID_OPERAND;
			return (total);
		    }
                if (op->cache != NULL)
                    XML_CAST_FPTR(func) = op->cache;
                else {
                    const xmlChar *URI = NULL;

                    if (op->value5 == NULL)
                        func =
                            xmlXPathFunctionLookup(ctxt->context,
                                                   op->value4);
                    else {
                        URI = xmlXPathNsLookup(ctxt->context, op->value5);
                        if (URI == NULL) {
                            xmlGenericError(xmlGenericErrorContext,
            "xmlXPathCompOpEval: function %s bound to undefined prefix %s\n",
                                    (char *)op->value4, (char *)op->value5);
                            ctxt->error = XPATH_UNDEF_PREFIX_ERROR;
                            return (total);
                        }
                        func = xmlXPathFunctionLookupNS(ctxt->context,
                                                        op->value4, URI);
                    }
                    if (func == NULL) {
                        xmlGenericError(xmlGenericErrorContext,
                                "xmlXPathCompOpEval: function %s not found\n",
                                        (char *)op->value4);
                        XP_ERROR0(XPATH_UNKNOWN_FUNC_ERROR);
                    }
                    op->cache = XML_CAST_FPTR(func);
                    op->cacheURI = (void *) URI;
                }
                oldFunc = ctxt->context->function;
                oldFuncURI = ctxt->context->functionURI;
                ctxt->context->function = op->value4;
                ctxt->context->functionURI = op->cacheURI;
                func(ctxt, op->value);
                ctxt->context->function = oldFunc;
                ctxt->context->functionURI = oldFuncURI;
                return (total);
            }
        case XPATH_OP_ARG:
	    bakd = ctxt->context->doc;
	    bak = ctxt->context->node;
	    pp = ctxt->context->proximityPosition;
	    cs = ctxt->context->contextSize;
            if (op->ch1 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    ctxt->context->contextSize = cs;
	    ctxt->context->proximityPosition = pp;
	    ctxt->context->node = bak;
	    ctxt->context->doc = bakd;
	    CHECK_ERROR0;
            if (op->ch2 != -1) {
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch2]);
	        ctxt->context->doc = bakd;
	        ctxt->context->node = bak;
	        CHECK_ERROR0;
	    }
            return (total);
        case XPATH_OP_PREDICATE:
        case XPATH_OP_FILTER:{
                xmlXPathObjectPtr res;
                xmlXPathObjectPtr obj, tmp;
                xmlNodeSetPtr newset = NULL;
                xmlNodeSetPtr oldset;
                xmlNodePtr oldnode;
		xmlDocPtr oldDoc;
                int i;

                /*
                 * Optimization for ()[1] selection i.e. the first elem
                 */
                if ((op->ch1 != -1) && (op->ch2 != -1) &&
#ifdef XP_OPTIMIZED_FILTER_FIRST
		    /*
		    * FILTER TODO: Can we assume that the inner processing
		    *  will result in an ordered list if we have an
		    *  XPATH_OP_FILTER?
		    *  What about an additional field or flag on
		    *  xmlXPathObject like @sorted ? This way we wouln'd need
		    *  to assume anything, so it would be more robust and
		    *  easier to optimize.
		    */
                    ((comp->steps[op->ch1].op == XPATH_OP_SORT) || /* 18 */
		     (comp->steps[op->ch1].op == XPATH_OP_FILTER)) && /* 17 */
#else
		    (comp->steps[op->ch1].op == XPATH_OP_SORT) &&
#endif
                    (comp->steps[op->ch2].op == XPATH_OP_VALUE)) { /* 12 */
                    xmlXPathObjectPtr val;

                    val = comp->steps[op->ch2].value4;
                    if ((val != NULL) && (val->type == XPATH_NUMBER) &&
                        (val->floatval == 1.0)) {
                        xmlNodePtr first = NULL;

                        total +=
                            xmlXPathCompOpEvalFirst(ctxt,
                                                    &comp->steps[op->ch1],
                                                    &first);
			CHECK_ERROR0;
                        /*
                         * The nodeset should be in document order,
                         * Keep only the first value
                         */
                        if ((ctxt->value != NULL) &&
                            (ctxt->value->type == XPATH_NODESET) &&
                            (ctxt->value->nodesetval != NULL) &&
                            (ctxt->value->nodesetval->nodeNr > 1))
                            ctxt->value->nodesetval->nodeNr = 1;
                        return (total);
                    }
                }
                /*
                 * Optimization for ()[last()] selection i.e. the last elem
                 */
                if ((op->ch1 != -1) && (op->ch2 != -1) &&
                    (comp->steps[op->ch1].op == XPATH_OP_SORT) &&
                    (comp->steps[op->ch2].op == XPATH_OP_SORT)) {
                    int f = comp->steps[op->ch2].ch1;

                    if ((f != -1) &&
                        (comp->steps[f].op == XPATH_OP_FUNCTION) &&
                        (comp->steps[f].value5 == NULL) &&
                        (comp->steps[f].value == 0) &&
                        (comp->steps[f].value4 != NULL) &&
                        (xmlStrEqual
                         (comp->steps[f].value4, BAD_CAST "last"))) {
                        xmlNodePtr last = NULL;

                        total +=
                            xmlXPathCompOpEvalLast(ctxt,
                                                   &comp->steps[op->ch1],
                                                   &last);
			CHECK_ERROR0;
                        /*
                         * The nodeset should be in document order,
                         * Keep only the last value
                         */
                        if ((ctxt->value != NULL) &&
                            (ctxt->value->type == XPATH_NODESET) &&
                            (ctxt->value->nodesetval != NULL) &&
                            (ctxt->value->nodesetval->nodeTab != NULL) &&
                            (ctxt->value->nodesetval->nodeNr > 1)) {
                            ctxt->value->nodesetval->nodeTab[0] =
                                ctxt->value->nodesetval->nodeTab[ctxt->
                                                                 value->
                                                                 nodesetval->
                                                                 nodeNr -
                                                                 1];
                            ctxt->value->nodesetval->nodeNr = 1;
                        }
                        return (total);
                    }
                }
		/*
		* Process inner predicates first.
		* Example "index[parent::book][1]":
		* ...
		*   PREDICATE   <-- we are here "[1]"
		*     PREDICATE <-- process "[parent::book]" first
		*       SORT
		*         COLLECT  'parent' 'name' 'node' book
		*           NODE
		*     ELEM Object is a number : 1
		*/
                if (op->ch1 != -1)
                    total +=
                        xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
		CHECK_ERROR0;
                if (op->ch2 == -1)
                    return (total);
                if (ctxt->value == NULL)
                    return (total);

                oldnode = ctxt->context->node;

#ifdef LIBXML_XPTR_ENABLED
                /*
                 * Hum are we filtering the result of an XPointer expression
                 */
                if (ctxt->value->type == XPATH_LOCATIONSET) {
                    xmlLocationSetPtr newlocset = NULL;
                    xmlLocationSetPtr oldlocset;

                    /*
                     * Extract the old locset, and then evaluate the result of the
                     * expression for all the element in the locset. use it to grow
                     * up a new locset.
                     */
                    CHECK_TYPE0(XPATH_LOCATIONSET);
                    obj = valuePop(ctxt);
                    oldlocset = obj->user;
                    ctxt->context->node = NULL;

                    if ((oldlocset == NULL) || (oldlocset->locNr == 0)) {
                        ctxt->context->contextSize = 0;
                        ctxt->context->proximityPosition = 0;
                        if (op->ch2 != -1)
                            total +=
                                xmlXPathCompOpEval(ctxt,
                                                   &comp->steps[op->ch2]);
                        res = valuePop(ctxt);
                        if (res != NULL) {
			    xmlXPathReleaseObject(ctxt->context, res);
			}
                        valuePush(ctxt, obj);
                        CHECK_ERROR0;
                        return (total);
                    }
                    newlocset = xmlXPtrLocationSetCreate(NULL);

                    for (i = 0; i < oldlocset->locNr; i++) {
                        /*
                         * Run the evaluation with a node list made of a
                         * single item in the nodelocset.
                         */
                        ctxt->context->node = oldlocset->locTab[i]->user;
                        ctxt->context->contextSize = oldlocset->locNr;
                        ctxt->context->proximityPosition = i + 1;
			tmp = xmlXPathCacheNewNodeSet(ctxt->context,
			    ctxt->context->node);
                        valuePush(ctxt, tmp);

                        if (op->ch2 != -1)
                            total +=
                                xmlXPathCompOpEval(ctxt,
                                                   &comp->steps[op->ch2]);
			if (ctxt->error != XPATH_EXPRESSION_OK) {
			    xmlXPathFreeObject(obj);
			    return(0);
			}

                        /*
                         * The result of the evaluation need to be tested to
                         * decided whether the filter succeeded or not
                         */
                        res = valuePop(ctxt);
                        if (xmlXPathEvaluatePredicateResult(ctxt, res)) {
                            xmlXPtrLocationSetAdd(newlocset,
                                                  xmlXPathObjectCopy
                                                  (oldlocset->locTab[i]));
                        }

                        /*
                         * Cleanup
                         */
                        if (res != NULL) {
			    xmlXPathReleaseObject(ctxt->context, res);
			}
                        if (ctxt->value == tmp) {
                            res = valuePop(ctxt);
			    xmlXPathReleaseObject(ctxt->context, res);
                        }

                        ctxt->context->node = NULL;
                    }

                    /*
                     * The result is used as the new evaluation locset.
                     */
		    xmlXPathReleaseObject(ctxt->context, obj);
                    ctxt->context->node = NULL;
                    ctxt->context->contextSize = -1;
                    ctxt->context->proximityPosition = -1;
                    valuePush(ctxt, xmlXPtrWrapLocationSet(newlocset));
                    ctxt->context->node = oldnode;
                    return (total);
                }
#endif /* LIBXML_XPTR_ENABLED */

                /*
                 * Extract the old set, and then evaluate the result of the
                 * expression for all the element in the set. use it to grow
                 * up a new set.
                 */
                CHECK_TYPE0(XPATH_NODESET);
                obj = valuePop(ctxt);
                oldset = obj->nodesetval;

                oldnode = ctxt->context->node;
		oldDoc = ctxt->context->doc;
                ctxt->context->node = NULL;

                if ((oldset == NULL) || (oldset->nodeNr == 0)) {
                    ctxt->context->contextSize = 0;
                    ctxt->context->proximityPosition = 0;
/*
                    if (op->ch2 != -1)
                        total +=
                            xmlXPathCompOpEval(ctxt,
                                               &comp->steps[op->ch2]);
		    CHECK_ERROR0;
                    res = valuePop(ctxt);
                    if (res != NULL)
                        xmlXPathFreeObject(res);
*/
                    valuePush(ctxt, obj);
                    ctxt->context->node = oldnode;
                    CHECK_ERROR0;
                } else {
		    tmp = NULL;
                    /*
                     * Initialize the new set.
		     * Also set the xpath document in case things like
		     * key() evaluation are attempted on the predicate
                     */
                    newset = xmlXPathNodeSetCreate(NULL);
		    /*
		    * SPEC XPath 1.0:
		    *  "For each node in the node-set to be filtered, the
		    *  PredicateExpr is evaluated with that node as the
		    *  context node, with the number of nodes in the
		    *  node-set as the context size, and with the proximity
		    *  position of the node in the node-set with respect to
		    *  the axis as the context position;"
		    * @oldset is the node-set" to be filtered.
		    *
		    * SPEC XPath 1.0:
		    *  "only predicates change the context position and
		    *  context size (see [2.4 Predicates])."
		    * Example:
		    *   node-set  context pos
		    *    nA         1
		    *    nB         2
		    *    nC         3
		    *   After applying predicate [position() > 1] :
		    *   node-set  context pos
		    *    nB         1
		    *    nC         2
		    *
		    * removed the first node in the node-set, then
		    * the context position of the
		    */
                    for (i = 0; i < oldset->nodeNr; i++) {
                        /*
                         * Run the evaluation with a node list made of
                         * a single item in the nodeset.
                         */
                        ctxt->context->node = oldset->nodeTab[i];
			if ((oldset->nodeTab[i]->type != XML_NAMESPACE_DECL) &&
			    (oldset->nodeTab[i]->doc != NULL))
		            ctxt->context->doc = oldset->nodeTab[i]->doc;
			if (tmp == NULL) {
			    tmp = xmlXPathCacheNewNodeSet(ctxt->context,
				ctxt->context->node);
			} else {
			    xmlXPathNodeSetAddUnique(tmp->nodesetval,
				ctxt->context->node);
			}
                        valuePush(ctxt, tmp);
                        ctxt->context->contextSize = oldset->nodeNr;
                        ctxt->context->proximityPosition = i + 1;
			/*
			* Evaluate the predicate against the context node.
			* Can/should we optimize position() predicates
			* here (e.g. "[1]")?
			*/
                        if (op->ch2 != -1)
                            total +=
                                xmlXPathCompOpEval(ctxt,
                                                   &comp->steps[op->ch2]);
			if (ctxt->error != XPATH_EXPRESSION_OK) {
			    xmlXPathFreeNodeSet(newset);
			    xmlXPathFreeObject(obj);
			    return(0);
			}

                        /*
                         * The result of the evaluation needs to be tested to
                         * decide whether the filter succeeded or not
                         */
			/*
			* OPTIMIZE TODO: Can we use
			* xmlXPathNodeSetAdd*Unique()* instead?
			*/
                        res = valuePop(ctxt);
                        if (xmlXPathEvaluatePredicateResult(ctxt, res)) {
                            xmlXPathNodeSetAdd(newset, oldset->nodeTab[i]);
                        }

                        /*
                         * Cleanup
                         */
                        if (res != NULL) {
			    xmlXPathReleaseObject(ctxt->context, res);
			}
                        if (ctxt->value == tmp) {
                            valuePop(ctxt);
			    xmlXPathNodeSetClear(tmp->nodesetval, 1);
			    /*
			    * Don't free the temporary nodeset
			    * in order to avoid massive recreation inside this
			    * loop.
			    */
                        } else
			    tmp = NULL;
                        ctxt->context->node = NULL;
                    }
		    if (tmp != NULL)
			xmlXPathReleaseObject(ctxt->context, tmp);
                    /*
                     * The result is used as the new evaluation set.
                     */
		    xmlXPathReleaseObject(ctxt->context, obj);
                    ctxt->context->node = NULL;
                    ctxt->context->contextSize = -1;
                    ctxt->context->proximityPosition = -1;
		    /* may want to move this past the '}' later */
		    ctxt->context->doc = oldDoc;
		    valuePush(ctxt,
			xmlXPathCacheWrapNodeSet(ctxt->context, newset));
                }
                ctxt->context->node = oldnode;
                return (total);
            }
        case XPATH_OP_SORT:
            if (op->ch1 != -1)
                total += xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
	    CHECK_ERROR0;
            if ((ctxt->value != NULL) &&
                (ctxt->value->type == XPATH_NODESET) &&
                (ctxt->value->nodesetval != NULL) &&
		(ctxt->value->nodesetval->nodeNr > 1))
	    {
                xmlXPathNodeSetSort(ctxt->value->nodesetval);
	    }
            return (total);
#ifdef LIBXML_XPTR_ENABLED
        case XPATH_OP_RANGETO:{
                xmlXPathObjectPtr range;
                xmlXPathObjectPtr res, obj;
                xmlXPathObjectPtr tmp;
                xmlLocationSetPtr newlocset = NULL;
		    xmlLocationSetPtr oldlocset;
                xmlNodeSetPtr oldset;
                int i, j;

                if (op->ch1 != -1)
                    total +=
                        xmlXPathCompOpEval(ctxt, &comp->steps[op->ch1]);
                if (op->ch2 == -1)
                    return (total);

                if (ctxt->value->type == XPATH_LOCATIONSET) {
                    /*
                     * Extract the old locset, and then evaluate the result of the
                     * expression for all the element in the locset. use it to grow
                     * up a new locset.
                     */
                    CHECK_TYPE0(XPATH_LOCATIONSET);
                    obj = valuePop(ctxt);
                    oldlocset = obj->user;

                    if ((oldlocset == NULL) || (oldlocset->locNr == 0)) {
		        ctxt->context->node = NULL;
                        ctxt->context->contextSize = 0;
                        ctxt->context->proximityPosition = 0;
                        total += xmlXPathCompOpEval(ctxt,&comp->steps[op->ch2]);
                        res = valuePop(ctxt);
                        if (res != NULL) {
			    xmlXPathReleaseObject(ctxt->context, res);
			}
                        valuePush(ctxt, obj);
                        CHECK_ERROR0;
                        return (total);
                    }
                    newlocset = xmlXPtrLocationSetCreate(NULL);

                    for (i = 0; i < oldlocset->locNr; i++) {
                        /*
                         * Run the evaluation with a node list made of a
                         * single item in the nodelocset.
                         */
                        ctxt->context->node = oldlocset->locTab[i]->user;
                        ctxt->context->contextSize = oldlocset->locNr;
                        ctxt->context->proximityPosition = i + 1;
			tmp = xmlXPathCacheNewNodeSet(ctxt->context,
			    ctxt->context->node);
                        valuePush(ctxt, tmp);

                        if (op->ch2 != -1)
                            total +=
                                xmlXPathCompOpEval(ctxt,
                                                   &comp->steps[op->ch2]);
			if (ctxt->error != XPATH_EXPRESSION_OK) {
			    xmlXPathFreeObject(obj);
			    return(0);
			}

                        res = valuePop(ctxt);
			if (res->type == XPATH_LOCATIONSET) {
			    xmlLocationSetPtr rloc =
			        (xmlLocationSetPtr)res->user;
			    for (j=0; j<rloc->locNr; j++) {
			        range = xmlXPtrNewRange(
				  oldlocset->locTab[i]->user,
				  oldlocset->locTab[i]->index,
				  rloc->locTab[j]->user2,
				  rloc->locTab[j]->index2);
				if (range != NULL) {
				    xmlXPtrLocationSetAdd(newlocset, range);
				}
			    }
			} else {
			    range = xmlXPtrNewRangeNodeObject(
				(xmlNodePtr)oldlocset->locTab[i]->user, res);
                            if (range != NULL) {
                                xmlXPtrLocationSetAdd(newlocset,range);
			    }
                        }

                        /*
                         * Cleanup
                         */
                        if (res != NULL) {
			    xmlXPathReleaseObject(ctxt->context, res);
			}
                        if (ctxt->value == tmp) {
                            res = valuePop(ctxt);
			    xmlXPathReleaseObject(ctxt->context, res);
                        }

                        ctxt->context->node = NULL;
                    }
		} else {	/* Not a location set */
                    CHECK_TYPE0(XPATH_NODESET);
                    obj = valuePop(ctxt);
                    oldset = obj->nodesetval;
                    ctxt->context->node = NULL;

                    newlocset = xmlXPtrLocationSetCreate(NULL);

                    if (oldset != NULL) {
                        for (i = 0; i < oldset->nodeNr; i++) {
                            /*
                             * Run the evaluation with a node list made of a single item
                             * in the nodeset.
                             */
                            ctxt->context->node = oldset->nodeTab[i];
			    /*
			    * OPTIMIZE TODO: Avoid recreation for every iteration.
			    */
			    tmp = xmlXPathCacheNewNodeSet(ctxt->context,
				ctxt->context->node);
                            valuePush(ctxt, tmp);

                            if (op->ch2 != -1)
                                total +=
                                    xmlXPathCompOpEval(ctxt,
                                                   &comp->steps[op->ch2]);
			    if (ctxt->error != XPATH_EXPRESSION_OK) {
				xmlXPathFreeObject(obj);
				return(0);
			    }

                            res = valuePop(ctxt);
                            range =
                                xmlXPtrNewRangeNodeObject(oldset->nodeTab[i],
                                                      res);
                            if (range != NULL) {
                                xmlXPtrLocationSetAdd(newlocset, range);
                            }

                            /*
                             * Cleanup
                             */
                            if (res != NULL) {
				xmlXPathReleaseObject(ctxt->context, res);
			    }
                            if (ctxt->value == tmp) {
                                res = valuePop(ctxt);
				xmlXPathReleaseObject(ctxt->context, res);
                            }

                            ctxt->context->node = NULL;
                        }
                    }
                }

                /*
                 * The result is used as the new evaluation set.
                 */
		xmlXPathReleaseObject(ctxt->context, obj);
                ctxt->context->node = NULL;
                ctxt->context->contextSize = -1;
                ctxt->context->proximityPosition = -1;
                valuePush(ctxt, xmlXPtrWrapLocationSet(newlocset));
                return (total);
            }
#endif /* LIBXML_XPTR_ENABLED */
    }
    xmlGenericError(xmlGenericErrorContext,
                    "XPath: unknown precompiled operation %d\n", op->op);
    return (total);
}

/**
 * xmlXPathCompOpEvalToBoolean:
 * @ctxt:  the XPath parser context
 *
 * Evaluates if the expression evaluates to true.
 *
 * Returns 1 if true, 0 if false and -1 on API or internal errors.
 */
static int
xmlXPathCompOpEvalToBoolean(xmlXPathParserContextPtr ctxt,
			    xmlXPathStepOpPtr op,
			    int isPredicate)
{
    xmlXPathObjectPtr resObj = NULL;

start:
    /* comp = ctxt->comp; */
    switch (op->op) {
        case XPATH_OP_END:
            return (0);
	case XPATH_OP_VALUE:
	    resObj = (xmlXPathObjectPtr) op->value4;
	    if (isPredicate)
		return(xmlXPathEvaluatePredicateResult(ctxt, resObj));
	    return(xmlXPathCastToBoolean(resObj));
	case XPATH_OP_SORT:
	    /*
	    * We don't need sorting for boolean results. Skip this one.
	    */
            if (op->ch1 != -1) {
		op = &ctxt->comp->steps[op->ch1];
		goto start;
	    }
	    return(0);
	case XPATH_OP_COLLECT:
	    if (op->ch1 == -1)
		return(0);

            xmlXPathCompOpEval(ctxt, &ctxt->comp->steps[op->ch1]);
	    if (ctxt->error != XPATH_EXPRESSION_OK)
		return(-1);

            xmlXPathNodeCollectAndTest(ctxt, op, NULL, NULL, 1);
	    if (ctxt->error != XPATH_EXPRESSION_OK)
		return(-1);

	    resObj = valuePop(ctxt);
	    if (resObj == NULL)
		return(-1);
	    break;
	default:
	    /*
	    * Fallback to call xmlXPathCompOpEval().
	    */
	    xmlXPathCompOpEval(ctxt, op);
	    if (ctxt->error != XPATH_EXPRESSION_OK)
		return(-1);

	    resObj = valuePop(ctxt);
	    if (resObj == NULL)
		return(-1);
	    break;
    }

    if (resObj) {
	int res;

	if (resObj->type == XPATH_BOOLEAN) {
	    res = resObj->boolval;
	} else if (isPredicate) {
	    /*
	    * For predicates a result of type "number" is handled
	    * differently:
	    * SPEC XPath 1.0:
	    * "If the result is a number, the result will be converted
	    *  to true if the number is equal to the context position
	    *  and will be converted to false otherwise;"
	    */
	    res = xmlXPathEvaluatePredicateResult(ctxt, resObj);
	} else {
	    res = xmlXPathCastToBoolean(resObj);
	}
	xmlXPathReleaseObject(ctxt->context, resObj);
	return(res);
    }

    return(0);
}

#ifdef XPATH_STREAMING
/**
 * xmlXPathRunStreamEval:
 * @ctxt:  the XPath parser context with the compiled expression
 *
 * Evaluate the Precompiled Streamable XPath expression in the given context.
 */
static int
xmlXPathRunStreamEval(xmlXPathContextPtr ctxt, xmlPatternPtr comp,
		      xmlXPathObjectPtr *resultSeq, int toBool)
{
    int max_depth, min_depth;
    int from_root;
    int ret, depth;
    int eval_all_nodes;
    xmlNodePtr cur = NULL, limit = NULL;
    xmlStreamCtxtPtr patstream = NULL;

    int nb_nodes = 0;

    if ((ctxt == NULL) || (comp == NULL))
        return(-1);
    max_depth = xmlPatternMaxDepth(comp);
    if (max_depth == -1)
        return(-1);
    if (max_depth == -2)
        max_depth = 10000;
    min_depth = xmlPatternMinDepth(comp);
    if (min_depth == -1)
        return(-1);
    from_root = xmlPatternFromRoot(comp);
    if (from_root < 0)
        return(-1);
#if 0
    printf("stream eval: depth %d from root %d\n", max_depth, from_root);
#endif

    if (! toBool) {
	if (resultSeq == NULL)
	    return(-1);
	*resultSeq = xmlXPathCacheNewNodeSet(ctxt, NULL);
	if (*resultSeq == NULL)
	    return(-1);
    }

    /*
     * handle the special cases of "/" amd "." being matched
     */
    if (min_depth == 0) {
	if (from_root) {
	    /* Select "/" */
	    if (toBool)
		return(1);
	    xmlXPathNodeSetAddUnique((*resultSeq)->nodesetval,
		(xmlNodePtr) ctxt->doc);
	} else {
	    /* Select "self::node()" */
	    if (toBool)
		return(1);
	    xmlXPathNodeSetAddUnique((*resultSeq)->nodesetval, ctxt->node);
	}
    }
    if (max_depth == 0) {
	return(0);
    }

    if (from_root) {
        cur = (xmlNodePtr)ctxt->doc;
    } else if (ctxt->node != NULL) {
        switch (ctxt->node->type) {
            case XML_ELEMENT_NODE:
            case XML_DOCUMENT_NODE:
            case XML_DOCUMENT_FRAG_NODE:
            case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
            case XML_DOCB_DOCUMENT_NODE:
#endif
	        cur = ctxt->node;
		break;
            case XML_ATTRIBUTE_NODE:
            case XML_TEXT_NODE:
            case XML_CDATA_SECTION_NODE:
            case XML_ENTITY_REF_NODE:
            case XML_ENTITY_NODE:
            case XML_PI_NODE:
            case XML_COMMENT_NODE:
            case XML_NOTATION_NODE:
            case XML_DTD_NODE:
            case XML_DOCUMENT_TYPE_NODE:
            case XML_ELEMENT_DECL:
            case XML_ATTRIBUTE_DECL:
            case XML_ENTITY_DECL:
            case XML_NAMESPACE_DECL:
            case XML_XINCLUDE_START:
            case XML_XINCLUDE_END:
		break;
	}
	limit = cur;
    }
    if (cur == NULL) {
        return(0);
    }

    patstream = xmlPatternGetStreamCtxt(comp);
    if (patstream == NULL) {
	/*
	* QUESTION TODO: Is this an error?
	*/
	return(0);
    }

    eval_all_nodes = xmlStreamWantsAnyNode(patstream);

    if (from_root) {
	ret = xmlStreamPush(patstream, NULL, NULL);
	if (ret < 0) {
	} else if (ret == 1) {
	    if (toBool)
		goto return_1;
	    xmlXPathNodeSetAddUnique((*resultSeq)->nodesetval, cur);
	}
    }
    depth = 0;
    goto scan_children;
next_node:
    do {
        nb_nodes++;

	switch (cur->type) {
	    case XML_ELEMENT_NODE:
	    case XML_TEXT_NODE:
	    case XML_CDATA_SECTION_NODE:
	    case XML_COMMENT_NODE:
	    case XML_PI_NODE:
		if (cur->type == XML_ELEMENT_NODE) {
		    ret = xmlStreamPush(patstream, cur->name,
				(cur->ns ? cur->ns->href : NULL));
		} else if (eval_all_nodes)
		    ret = xmlStreamPushNode(patstream, NULL, NULL, cur->type);
		else
		    break;

		if (ret < 0) {
		    /* NOP. */
		} else if (ret == 1) {
		    if (toBool)
			goto return_1;
		    xmlXPathNodeSetAddUnique((*resultSeq)->nodesetval, cur);
		}
		if ((cur->children == NULL) || (depth >= max_depth)) {
		    ret = xmlStreamPop(patstream);
		    while (cur->next != NULL) {
			cur = cur->next;
			if ((cur->type != XML_ENTITY_DECL) &&
			    (cur->type != XML_DTD_NODE))
			    goto next_node;
		    }
		}
	    default:
		break;
	}

scan_children:
	if ((cur->children != NULL) && (depth < max_depth)) {
	    /*
	     * Do not descend on entities declarations
	     */
	    if (cur->children->type != XML_ENTITY_DECL) {
		cur = cur->children;
		depth++;
		/*
		 * Skip DTDs
		 */
		if (cur->type != XML_DTD_NODE)
		    continue;
	    }
	}

	if (cur == limit)
	    break;

	while (cur->next != NULL) {
	    cur = cur->next;
	    if ((cur->type != XML_ENTITY_DECL) &&
		(cur->type != XML_DTD_NODE))
		goto next_node;
	}

	do {
	    cur = cur->parent;
	    depth--;
	    if ((cur == NULL) || (cur == limit))
	        goto done;
	    if (cur->type == XML_ELEMENT_NODE) {
		ret = xmlStreamPop(patstream);
	    } else if ((eval_all_nodes) &&
		((cur->type == XML_TEXT_NODE) ||
		 (cur->type == XML_CDATA_SECTION_NODE) ||
		 (cur->type == XML_COMMENT_NODE) ||
		 (cur->type == XML_PI_NODE)))
	    {
		ret = xmlStreamPop(patstream);
	    }
	    if (cur->next != NULL) {
		cur = cur->next;
		break;
	    }
	} while (cur != NULL);

    } while ((cur != NULL) && (depth >= 0));

done:

#if 0
    printf("stream eval: checked %d nodes selected %d\n",
           nb_nodes, retObj->nodesetval->nodeNr);
#endif

    if (patstream)
	xmlFreeStreamCtxt(patstream);
    return(0);

return_1:
    if (patstream)
	xmlFreeStreamCtxt(patstream);
    return(1);
}
#endif /* XPATH_STREAMING */

/**
 * xmlXPathRunEval:
 * @ctxt:  the XPath parser context with the compiled expression
 * @toBool:  evaluate to a boolean result
 *
 * Evaluate the Precompiled XPath expression in the given context.
 */
static int
xmlXPathRunEval(xmlXPathParserContextPtr ctxt, int toBool)
{
    xmlXPathCompExprPtr comp;

    if ((ctxt == NULL) || (ctxt->comp == NULL))
	return(-1);

    if (ctxt->valueTab == NULL) {
	/* Allocate the value stack */
	ctxt->valueTab = (xmlXPathObjectPtr *)
			 xmlMalloc(10 * sizeof(xmlXPathObjectPtr));
	if (ctxt->valueTab == NULL) {
	    xmlXPathPErrMemory(ctxt, "creating evaluation context\n");
	    xmlFree(ctxt);
	}
	ctxt->valueNr = 0;
	ctxt->valueMax = 10;
	ctxt->value = NULL;
    }
#ifdef XPATH_STREAMING
    if (ctxt->comp->stream) {
	int res;

	if (toBool) {
	    /*
	    * Evaluation to boolean result.
	    */
	    res = xmlXPathRunStreamEval(ctxt->context,
		ctxt->comp->stream, NULL, 1);
	    if (res != -1)
		return(res);
	} else {
	    xmlXPathObjectPtr resObj = NULL;

	    /*
	    * Evaluation to a sequence.
	    */
	    res = xmlXPathRunStreamEval(ctxt->context,
		ctxt->comp->stream, &resObj, 0);

	    if ((res != -1) && (resObj != NULL)) {
		valuePush(ctxt, resObj);
		return(0);
	    }
	    if (resObj != NULL)
		xmlXPathReleaseObject(ctxt->context, resObj);
	}
	/*
	* QUESTION TODO: This falls back to normal XPath evaluation
	* if res == -1. Is this intended?
	*/
    }
#endif
    comp = ctxt->comp;
    if (comp->last < 0) {
	xmlGenericError(xmlGenericErrorContext,
	    "xmlXPathRunEval: last is less than zero\n");
	return(-1);
    }
    if (toBool)
	return(xmlXPathCompOpEvalToBoolean(ctxt,
	    &comp->steps[comp->last], 0));
    else
	xmlXPathCompOpEval(ctxt, &comp->steps[comp->last]);

    return(0);
}

/************************************************************************
 *									*
 *			Public interfaces				*
 *									*
 ************************************************************************/

/**
 * xmlXPathEvalPredicate:
 * @ctxt:  the XPath context
 * @res:  the Predicate Expression evaluation result
 *
 * Evaluate a predicate result for the current node.
 * A PredicateExpr is evaluated by evaluating the Expr and converting
 * the result to a boolean. If the result is a number, the result will
 * be converted to true if the number is equal to the position of the
 * context node in the context node list (as returned by the position
 * function) and will be converted to false otherwise; if the result
 * is not a number, then the result will be converted as if by a call
 * to the boolean function.
 *
 * Returns 1 if predicate is true, 0 otherwise
 */
int
xmlXPathEvalPredicate(xmlXPathContextPtr ctxt, xmlXPathObjectPtr res) {
    if ((ctxt == NULL) || (res == NULL)) return(0);
    switch (res->type) {
        case XPATH_BOOLEAN:
	    return(res->boolval);
        case XPATH_NUMBER:
	    return(res->floatval == ctxt->proximityPosition);
        case XPATH_NODESET:
        case XPATH_XSLT_TREE:
	    if (res->nodesetval == NULL)
		return(0);
	    return(res->nodesetval->nodeNr != 0);
        case XPATH_STRING:
	    return((res->stringval != NULL) &&
	           (xmlStrlen(res->stringval) != 0));
        default:
	    STRANGE
    }
    return(0);
}

/**
 * xmlXPathEvaluatePredicateResult:
 * @ctxt:  the XPath Parser context
 * @res:  the Predicate Expression evaluation result
 *
 * Evaluate a predicate result for the current node.
 * A PredicateExpr is evaluated by evaluating the Expr and converting
 * the result to a boolean. If the result is a number, the result will
 * be converted to true if the number is equal to the position of the
 * context node in the context node list (as returned by the position
 * function) and will be converted to false otherwise; if the result
 * is not a number, then the result will be converted as if by a call
 * to the boolean function.
 *
 * Returns 1 if predicate is true, 0 otherwise
 */
int
xmlXPathEvaluatePredicateResult(xmlXPathParserContextPtr ctxt,
                                xmlXPathObjectPtr res) {
    if ((ctxt == NULL) || (res == NULL)) return(0);
    switch (res->type) {
        case XPATH_BOOLEAN:
	    return(res->boolval);
        case XPATH_NUMBER:
#if defined(__BORLANDC__) || (defined(_MSC_VER) && (_MSC_VER == 1200))
	    return((res->floatval == ctxt->context->proximityPosition) &&
	           (!xmlXPathIsNaN(res->floatval))); /* MSC pbm Mark Vakoc !*/
#else
	    return(res->floatval == ctxt->context->proximityPosition);
#endif
        case XPATH_NODESET:
        case XPATH_XSLT_TREE:
	    if (res->nodesetval == NULL)
		return(0);
	    return(res->nodesetval->nodeNr != 0);
        case XPATH_STRING:
	    return((res->stringval != NULL) && (res->stringval[0] != 0));
#ifdef LIBXML_XPTR_ENABLED
	case XPATH_LOCATIONSET:{
	    xmlLocationSetPtr ptr = res->user;
	    if (ptr == NULL)
	        return(0);
	    return (ptr->locNr != 0);
	    }
#endif
        default:
	    STRANGE
    }
    return(0);
}

#ifdef XPATH_STREAMING
/**
 * xmlXPathTryStreamCompile:
 * @ctxt: an XPath context
 * @str:  the XPath expression
 *
 * Try to compile the XPath expression as a streamable subset.
 *
 * Returns the compiled expression or NULL if failed to compile.
 */
static xmlXPathCompExprPtr
xmlXPathTryStreamCompile(xmlXPathContextPtr ctxt, const xmlChar *str) {
    /*
     * Optimization: use streaming patterns when the XPath expression can
     * be compiled to a stream lookup
     */
    xmlPatternPtr stream;
    xmlXPathCompExprPtr comp;
    xmlDictPtr dict = NULL;
    const xmlChar **namespaces = NULL;
    xmlNsPtr ns;
    int i, j;

    if ((!xmlStrchr(str, '[')) && (!xmlStrchr(str, '(')) &&
        (!xmlStrchr(str, '@'))) {
	const xmlChar *tmp;

	/*
	 * We don't try to handle expressions using the verbose axis
	 * specifiers ("::"), just the simplied form at this point.
	 * Additionally, if there is no list of namespaces available and
	 *  there's a ":" in the expression, indicating a prefixed QName,
	 *  then we won't try to compile either. xmlPatterncompile() needs
	 *  to have a list of namespaces at compilation time in order to
	 *  compile prefixed name tests.
	 */
	tmp = xmlStrchr(str, ':');
	if ((tmp != NULL) &&
	    ((ctxt == NULL) || (ctxt->nsNr == 0) || (tmp[1] == ':')))
	    return(NULL);

	if (ctxt != NULL) {
	    dict = ctxt->dict;
	    if (ctxt->nsNr > 0) {
		namespaces = xmlMalloc(2 * (ctxt->nsNr + 1) * sizeof(xmlChar*));
		if (namespaces == NULL) {
		    xmlXPathErrMemory(ctxt, "allocating namespaces array\n");
		    return(NULL);
		}
		for (i = 0, j = 0; (j < ctxt->nsNr); j++) {
		    ns = ctxt->namespaces[j];
		    namespaces[i++] = ns->href;
		    namespaces[i++] = ns->prefix;
		}
		namespaces[i++] = NULL;
		namespaces[i] = NULL;
	    }
	}

	stream = xmlPatterncompile(str, dict, XML_PATTERN_XPATH,
			&namespaces[0]);
	if (namespaces != NULL) {
	    xmlFree((xmlChar **)namespaces);
	}
	if ((stream != NULL) && (xmlPatternStreamable(stream) == 1)) {
	    comp = xmlXPathNewCompExpr();
	    if (comp == NULL) {
		xmlXPathErrMemory(ctxt, "allocating streamable expression\n");
		return(NULL);
	    }
	    comp->stream = stream;
	    comp->dict = dict;
	    if (comp->dict)
		xmlDictReference(comp->dict);
	    return(comp);
	}
	xmlFreePattern(stream);
    }
    return(NULL);
}
#endif /* XPATH_STREAMING */

static int
xmlXPathCanRewriteDosExpression(xmlChar *expr)
{
    if (expr == NULL)
	return(0);
    do {
        if ((*expr == '/') && (*(++expr) == '/'))
	    return(1);
    } while (*expr++);
    return(0);
}
static void
xmlXPathRewriteDOSExpression(xmlXPathCompExprPtr comp, xmlXPathStepOpPtr op)
{
    /*
    * Try to rewrite "descendant-or-self::node()/foo" to an optimized
    * internal representation.
    */
    if (op->ch1 != -1) {
	if ((op->op == XPATH_OP_COLLECT /* 11 */) &&
	    ((xmlXPathAxisVal) op->value == AXIS_CHILD /* 4 */) &&
	    ((xmlXPathTestVal) op->value2 == NODE_TEST_NAME /* 5 */) &&
	    ((xmlXPathTypeVal) op->value3 == NODE_TYPE_NODE /* 0 */))
	{
	    /*
	    * This is a "child::foo"
	    */
	    xmlXPathStepOpPtr prevop = &comp->steps[op->ch1];

	    if ((prevop->op == XPATH_OP_COLLECT /* 11 */) &&
		(prevop->ch1 != -1) &&
		((xmlXPathAxisVal) prevop->value ==
		    AXIS_DESCENDANT_OR_SELF) &&
		(prevop->ch2 == -1) &&
		((xmlXPathTestVal) prevop->value2 == NODE_TEST_TYPE) &&
		((xmlXPathTypeVal) prevop->value3 == NODE_TYPE_NODE) &&
		(comp->steps[prevop->ch1].op == XPATH_OP_ROOT))
	    {
		/*
		* This is a "/descendant-or-self::node()" without predicates.
		* Eliminate it.
		*/
		op->ch1 = prevop->ch1;
		op->rewriteType = XP_REWRITE_DOS_CHILD_ELEM;
	    }
	}
	if (op->ch1 != -1)
	    xmlXPathRewriteDOSExpression(comp, &comp->steps[op->ch1]);
    }
    if (op->ch2 != -1)
	xmlXPathRewriteDOSExpression(comp, &comp->steps[op->ch2]);
}

/**
 * xmlXPathCtxtCompile:
 * @ctxt: an XPath context
 * @str:  the XPath expression
 *
 * Compile an XPath expression
 *
 * Returns the xmlXPathCompExprPtr resulting from the compilation or NULL.
 *         the caller has to free the object.
 */
xmlXPathCompExprPtr
xmlXPathCtxtCompile(xmlXPathContextPtr ctxt, const xmlChar *str) {
    xmlXPathParserContextPtr pctxt;
    xmlXPathCompExprPtr comp;

#ifdef XPATH_STREAMING
    comp = xmlXPathTryStreamCompile(ctxt, str);
    if (comp != NULL)
        return(comp);
#endif

    xmlXPathInit();

    pctxt = xmlXPathNewParserContext(str, ctxt);
    if (pctxt == NULL)
        return NULL;
    xmlXPathCompileExpr(pctxt, 1);

    if( pctxt->error != XPATH_EXPRESSION_OK )
    {
        xmlXPathFreeParserContext(pctxt);
        return(NULL);
    }

    if (*pctxt->cur != 0) {
	/*
	 * aleksey: in some cases this line prints *second* error message
	 * (see bug #78858) and probably this should be fixed.
	 * However, we are not sure that all error messages are printed
	 * out in other places. It's not critical so we leave it as-is for now
	 */
	xmlXPatherror(pctxt, __FILE__, __LINE__, XPATH_EXPR_ERROR);
	comp = NULL;
    } else {
	comp = pctxt->comp;
	pctxt->comp = NULL;
    }
    xmlXPathFreeParserContext(pctxt);

    if (comp != NULL) {
	comp->expr = xmlStrdup(str);
#ifdef DEBUG_EVAL_COUNTS
	comp->string = xmlStrdup(str);
	comp->nb = 0;
#endif
	if ((comp->expr != NULL) &&
	    (comp->nbStep > 2) &&
	    (comp->last >= 0) &&
	    (xmlXPathCanRewriteDosExpression(comp->expr) == 1))
	{
	    xmlXPathRewriteDOSExpression(comp, &comp->steps[comp->last]);
	}
    }
    return(comp);
}

/**
 * xmlXPathCompile:
 * @str:  the XPath expression
 *
 * Compile an XPath expression
 *
 * Returns the xmlXPathCompExprPtr resulting from the compilation or NULL.
 *         the caller has to free the object.
 */
xmlXPathCompExprPtr
xmlXPathCompile(const xmlChar *str) {
    return(xmlXPathCtxtCompile(NULL, str));
}

/**
 * xmlXPathCompiledEvalInternal:
 * @comp:  the compiled XPath expression
 * @ctxt:  the XPath context
 * @resObj: the resulting XPath object or NULL
 * @toBool: 1 if only a boolean result is requested
 *
 * Evaluate the Precompiled XPath expression in the given context.
 * The caller has to free @resObj.
 *
 * Returns the xmlXPathObjectPtr resulting from the evaluation or NULL.
 *         the caller has to free the object.
 */
static int
xmlXPathCompiledEvalInternal(xmlXPathCompExprPtr comp,
			     xmlXPathContextPtr ctxt,
			     xmlXPathObjectPtr *resObj,
			     int toBool)
{
    xmlXPathParserContextPtr pctxt;
#ifndef LIBXML_THREAD_ENABLED
    static int reentance = 0;
#endif
    int res;

    CHECK_CTXT_NEG(ctxt)

    if (comp == NULL)
	return(-1);
    xmlXPathInit();

#ifndef LIBXML_THREAD_ENABLED
    reentance++;
    if (reentance > 1)
	xmlXPathDisableOptimizer = 1;
#endif

#ifdef DEBUG_EVAL_COUNTS
    comp->nb++;
    if ((comp->string != NULL) && (comp->nb > 100)) {
	fprintf(stderr, "100 x %s\n", comp->string);
	comp->nb = 0;
    }
#endif
    pctxt = xmlXPathCompParserContext(comp, ctxt);
    res = xmlXPathRunEval(pctxt, toBool);

    if (resObj) {
	if (pctxt->value == NULL) {
	    xmlGenericError(xmlGenericErrorContext,
		"xmlXPathCompiledEval: evaluation failed\n");
	    *resObj = NULL;
	} else {
	    *resObj = valuePop(pctxt);
	}
    }

    /*
    * Pop all remaining objects from the stack.
    */
    if (pctxt->valueNr > 0) {
	xmlXPathObjectPtr tmp;
	int stack = 0;

	do {
	    tmp = valuePop(pctxt);
	    if (tmp != NULL) {
		stack++;
		xmlXPathReleaseObject(ctxt, tmp);
	    }
	} while (tmp != NULL);
	if ((stack != 0) &&
	    ((toBool) || ((resObj) && (*resObj))))
	{
	    xmlGenericError(xmlGenericErrorContext,
		"xmlXPathCompiledEval: %d objects left on the stack.\n",
		stack);
	}
    }

    if ((pctxt->error != XPATH_EXPRESSION_OK) && (resObj) && (*resObj)) {
	xmlXPathFreeObject(*resObj);
	*resObj = NULL;
    }
    pctxt->comp = NULL;
    xmlXPathFreeParserContext(pctxt);
#ifndef LIBXML_THREAD_ENABLED
    reentance--;
#endif

    return(res);
}

/**
 * xmlXPathCompiledEval:
 * @comp:  the compiled XPath expression
 * @ctx:  the XPath context
 *
 * Evaluate the Precompiled XPath expression in the given context.
 *
 * Returns the xmlXPathObjectPtr resulting from the evaluation or NULL.
 *         the caller has to free the object.
 */
xmlXPathObjectPtr
xmlXPathCompiledEval(xmlXPathCompExprPtr comp, xmlXPathContextPtr ctx)
{
    xmlXPathObjectPtr res = NULL;

    xmlXPathCompiledEvalInternal(comp, ctx, &res, 0);
    return(res);
}

/**
 * xmlXPathCompiledEvalToBoolean:
 * @comp:  the compiled XPath expression
 * @ctxt:  the XPath context
 *
 * Applies the XPath boolean() function on the result of the given
 * compiled expression.
 *
 * Returns 1 if the expression evaluated to true, 0 if to false and
 *         -1 in API and internal errors.
 */
int
xmlXPathCompiledEvalToBoolean(xmlXPathCompExprPtr comp,
			      xmlXPathContextPtr ctxt)
{
    return(xmlXPathCompiledEvalInternal(comp, ctxt, NULL, 1));
}

/**
 * xmlXPathEvalExpr:
 * @ctxt:  the XPath Parser context
 *
 * Parse and evaluate an XPath expression in the given context,
 * then push the result on the context stack
 */
void
xmlXPathEvalExpr(xmlXPathParserContextPtr ctxt) {
#ifdef XPATH_STREAMING
    xmlXPathCompExprPtr comp;
#endif

    if (ctxt == NULL) return;

#ifdef XPATH_STREAMING
    comp = xmlXPathTryStreamCompile(ctxt->context, ctxt->base);
    if (comp != NULL) {
        if (ctxt->comp != NULL)
	    xmlXPathFreeCompExpr(ctxt->comp);
        ctxt->comp = comp;
	if (ctxt->cur != NULL)
	    while (*ctxt->cur != 0) ctxt->cur++;
    } else
#endif
    {
	xmlXPathCompileExpr(ctxt, 1);
	/*
	* In this scenario the expression string will sit in ctxt->base.
	*/
	if ((ctxt->error == XPATH_EXPRESSION_OK) &&
	    (ctxt->comp != NULL) &&
	    (ctxt->base != NULL) &&
	    (ctxt->comp->nbStep > 2) &&
	    (ctxt->comp->last >= 0) &&
	    (xmlXPathCanRewriteDosExpression((xmlChar *) ctxt->base) == 1))
	{
	    xmlXPathRewriteDOSExpression(ctxt->comp,
		&ctxt->comp->steps[ctxt->comp->last]);
	}
    }
    CHECK_ERROR;
    xmlXPathRunEval(ctxt, 0);
}

/**
 * xmlXPathEval:
 * @str:  the XPath expression
 * @ctx:  the XPath context
 *
 * Evaluate the XPath Location Path in the given context.
 *
 * Returns the xmlXPathObjectPtr resulting from the evaluation or NULL.
 *         the caller has to free the object.
 */
xmlXPathObjectPtr
xmlXPathEval(const xmlChar *str, xmlXPathContextPtr ctx) {
    xmlXPathParserContextPtr ctxt;
    xmlXPathObjectPtr res, tmp, init = NULL;
    int stack = 0;

    CHECK_CTXT(ctx)

    xmlXPathInit();

    ctxt = xmlXPathNewParserContext(str, ctx);
    if (ctxt == NULL)
        return NULL;
    xmlXPathEvalExpr(ctxt);

    if (ctxt->value == NULL) {
	xmlGenericError(xmlGenericErrorContext,
		"xmlXPathEval: evaluation failed\n");
	res = NULL;
    } else if ((*ctxt->cur != 0) && (ctxt->comp != NULL)
#ifdef XPATH_STREAMING
            && (ctxt->comp->stream == NULL)
#endif
	      ) {
	xmlXPatherror(ctxt, __FILE__, __LINE__, XPATH_EXPR_ERROR);
	res = NULL;
    } else {
	res = valuePop(ctxt);
    }

    do {
        tmp = valuePop(ctxt);
	if (tmp != NULL) {
	    if (tmp != init)
		stack++;
	    xmlXPathReleaseObject(ctx, tmp);
        }
    } while (tmp != NULL);
    if ((stack != 0) && (res != NULL)) {
	xmlGenericError(xmlGenericErrorContext,
		"xmlXPathEval: %d object left on the stack\n",
	        stack);
    }
    if (ctxt->error != XPATH_EXPRESSION_OK) {
	xmlXPathFreeObject(res);
	res = NULL;
    }

    xmlXPathFreeParserContext(ctxt);
    return(res);
}

/**
 * xmlXPathEvalExpression:
 * @str:  the XPath expression
 * @ctxt:  the XPath context
 *
 * Evaluate the XPath expression in the given context.
 *
 * Returns the xmlXPathObjectPtr resulting from the evaluation or NULL.
 *         the caller has to free the object.
 */
xmlXPathObjectPtr
xmlXPathEvalExpression(const xmlChar *str, xmlXPathContextPtr ctxt) {
    xmlXPathParserContextPtr pctxt;
    xmlXPathObjectPtr res, tmp;
    int stack = 0;

    CHECK_CTXT(ctxt)

    xmlXPathInit();

    pctxt = xmlXPathNewParserContext(str, ctxt);
    if (pctxt == NULL)
        return NULL;
    xmlXPathEvalExpr(pctxt);

    if ((*pctxt->cur != 0) || (pctxt->error != XPATH_EXPRESSION_OK)) {
	xmlXPatherror(pctxt, __FILE__, __LINE__, XPATH_EXPR_ERROR);
	res = NULL;
    } else {
	res = valuePop(pctxt);
    }
    do {
        tmp = valuePop(pctxt);
	if (tmp != NULL) {
	    xmlXPathReleaseObject(ctxt, tmp);
	    stack++;
	}
    } while (tmp != NULL);
    if ((stack != 0) && (res != NULL)) {
	xmlGenericError(xmlGenericErrorContext,
		"xmlXPathEvalExpression: %d object left on the stack\n",
	        stack);
    }
    xmlXPathFreeParserContext(pctxt);
    return(res);
}

/************************************************************************
 *									*
 *	Extra functions not pertaining to the XPath spec		*
 *									*
 ************************************************************************/
/**
 * xmlXPathEscapeUriFunction:
 * @ctxt:  the XPath Parser context
 * @nargs:  the number of arguments
 *
 * Implement the escape-uri() XPath function
 *    string escape-uri(string $str, bool $escape-reserved)
 *
 * This function applies the URI escaping rules defined in section 2 of [RFC
 * 2396] to the string supplied as $uri-part, which typically represents all
 * or part of a URI. The effect of the function is to replace any special
 * character in the string by an escape sequence of the form %xx%yy...,
 * where xxyy... is the hexadecimal representation of the octets used to
 * represent the character in UTF-8.
 *
 * The set of characters that are escaped depends on the setting of the
 * boolean argument $escape-reserved.
 *
 * If $escape-reserved is true, all characters are escaped other than lower
 * case letters a-z, upper case letters A-Z, digits 0-9, and the characters
 * referred to in [RFC 2396] as "marks": specifically, "-" | "_" | "." | "!"
 * | "~" | "*" | "'" | "(" | ")". The "%" character itself is escaped only
 * if it is not followed by two hexadecimal digits (that is, 0-9, a-f, and
 * A-F).
 *
 * If $escape-reserved is false, the behavior differs in that characters
 * referred to in [RFC 2396] as reserved characters are not escaped. These
 * characters are ";" | "/" | "?" | ":" | "@" | "&" | "=" | "+" | "$" | ",".
 *
 * [RFC 2396] does not define whether escaped URIs should use lower case or
 * upper case for hexadecimal digits. To ensure that escaped URIs can be
 * compared using string comparison functions, this function must always use
 * the upper-case letters A-F.
 *
 * Generally, $escape-reserved should be set to true when escaping a string
 * that is to form a single part of a URI, and to false when escaping an
 * entire URI or URI reference.
 *
 * In the case of non-ascii characters, the string is encoded according to
 * utf-8 and then converted according to RFC 2396.
 *
 * Examples
 *  xf:escape-uri ("gopher://spinaltap.micro.umn.edu/00/Weather/California/Los%20Angeles#ocean"), true())
 *  returns "gopher%3A%2F%2Fspinaltap.micro.umn.edu%2F00%2FWeather%2FCalifornia%2FLos%20Angeles%23ocean"
 *  xf:escape-uri ("gopher://spinaltap.micro.umn.edu/00/Weather/California/Los%20Angeles#ocean"), false())
 *  returns "gopher://spinaltap.micro.umn.edu/00/Weather/California/Los%20Angeles%23ocean"
 *
 */
static void
xmlXPathEscapeUriFunction(xmlXPathParserContextPtr ctxt, int nargs) {
    xmlXPathObjectPtr str;
    int escape_reserved;
    xmlBufferPtr target;
    xmlChar *cptr;
    xmlChar escape[4];

    CHECK_ARITY(2);

    escape_reserved = xmlXPathPopBoolean(ctxt);

    CAST_TO_STRING;
    str = valuePop(ctxt);

    target = xmlBufferCreate();

    escape[0] = '%';
    escape[3] = 0;

    if (target) {
	for (cptr = str->stringval; *cptr; cptr++) {
	    if ((*cptr >= 'A' && *cptr <= 'Z') ||
		(*cptr >= 'a' && *cptr <= 'z') ||
		(*cptr >= '0' && *cptr <= '9') ||
		*cptr == '-' || *cptr == '_' || *cptr == '.' ||
		*cptr == '!' || *cptr == '~' || *cptr == '*' ||
		*cptr == '\''|| *cptr == '(' || *cptr == ')' ||
		(*cptr == '%' &&
		 ((cptr[1] >= 'A' && cptr[1] <= 'F') ||
		  (cptr[1] >= 'a' && cptr[1] <= 'f') ||
		  (cptr[1] >= '0' && cptr[1] <= '9')) &&
		 ((cptr[2] >= 'A' && cptr[2] <= 'F') ||
		  (cptr[2] >= 'a' && cptr[2] <= 'f') ||
		  (cptr[2] >= '0' && cptr[2] <= '9'))) ||
		(!escape_reserved &&
		 (*cptr == ';' || *cptr == '/' || *cptr == '?' ||
		  *cptr == ':' || *cptr == '@' || *cptr == '&' ||
		  *cptr == '=' || *cptr == '+' || *cptr == '$' ||
		  *cptr == ','))) {
		xmlBufferAdd(target, cptr, 1);
	    } else {
		if ((*cptr >> 4) < 10)
		    escape[1] = '0' + (*cptr >> 4);
		else
		    escape[1] = 'A' - 10 + (*cptr >> 4);
		if ((*cptr & 0xF) < 10)
		    escape[2] = '0' + (*cptr & 0xF);
		else
		    escape[2] = 'A' - 10 + (*cptr & 0xF);

		xmlBufferAdd(target, &escape[0], 3);
	    }
	}
    }
    valuePush(ctxt, xmlXPathCacheNewString(ctxt->context,
	xmlBufferContent(target)));
    xmlBufferFree(target);
    xmlXPathReleaseObject(ctxt->context, str);
}

/**
 * xmlXPathRegisterAllFunctions:
 * @ctxt:  the XPath context
 *
 * Registers all default XPath functions in this context
 */
void
xmlXPathRegisterAllFunctions(xmlXPathContextPtr ctxt)
{
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"boolean",
                         xmlXPathBooleanFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"ceiling",
                         xmlXPathCeilingFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"count",
                         xmlXPathCountFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"concat",
                         xmlXPathConcatFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"contains",
                         xmlXPathContainsFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"id",
                         xmlXPathIdFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"false",
                         xmlXPathFalseFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"floor",
                         xmlXPathFloorFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"last",
                         xmlXPathLastFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"lang",
                         xmlXPathLangFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"local-name",
                         xmlXPathLocalNameFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"not",
                         xmlXPathNotFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"name",
                         xmlXPathNameFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"namespace-uri",
                         xmlXPathNamespaceURIFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"normalize-space",
                         xmlXPathNormalizeFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"number",
                         xmlXPathNumberFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"position",
                         xmlXPathPositionFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"round",
                         xmlXPathRoundFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"string",
                         xmlXPathStringFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"string-length",
                         xmlXPathStringLengthFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"starts-with",
                         xmlXPathStartsWithFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"substring",
                         xmlXPathSubstringFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"substring-before",
                         xmlXPathSubstringBeforeFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"substring-after",
                         xmlXPathSubstringAfterFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"sum",
                         xmlXPathSumFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"true",
                         xmlXPathTrueFunction);
    xmlXPathRegisterFunc(ctxt, (const xmlChar *)"translate",
                         xmlXPathTranslateFunction);

    xmlXPathRegisterFuncNS(ctxt, (const xmlChar *)"escape-uri",
	 (const xmlChar *)"http://www.w3.org/2002/08/xquery-functions",
                         xmlXPathEscapeUriFunction);
}

#endif /* LIBXML_XPATH_ENABLED */
#define bottom_xpath
#include "elfgcchack.h"
