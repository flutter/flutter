/*
 * valid.c : part of the code use to do the DTD handling and the validity
 *           checking
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 */

#define IN_LIBXML
#include "libxml.h"

#include <string.h>

#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#include <libxml/xmlmemory.h>
#include <libxml/hash.h>
#include <libxml/uri.h>
#include <libxml/valid.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/xmlerror.h>
#include <libxml/list.h>
#include <libxml/globals.h>

static xmlElementPtr xmlGetDtdElementDesc2(xmlDtdPtr dtd, const xmlChar *name,
	                           int create);
/* #define DEBUG_VALID_ALGO */
/* #define DEBUG_REGEXP_ALGO */

#define TODO								\
    xmlGenericError(xmlGenericErrorContext,				\
	    "Unimplemented block at %s:%d\n",				\
            __FILE__, __LINE__);

#ifdef LIBXML_VALID_ENABLED
static int
xmlValidateAttributeValueInternal(xmlDocPtr doc, xmlAttributeType type,
                                  const xmlChar *value);
#endif
/************************************************************************
 *									*
 *			Error handling routines				*
 *									*
 ************************************************************************/

/**
 * xmlVErrMemory:
 * @ctxt:  an XML validation parser context
 * @extra:  extra informations
 *
 * Handle an out of memory error
 */
static void
xmlVErrMemory(xmlValidCtxtPtr ctxt, const char *extra)
{
    xmlGenericErrorFunc channel = NULL;
    xmlParserCtxtPtr pctxt = NULL;
    void *data = NULL;

    if (ctxt != NULL) {
        channel = ctxt->error;
        data = ctxt->userData;
	/* Use the special values to detect if it is part of a parsing
	   context */
	if ((ctxt->finishDtd == XML_CTXT_FINISH_DTD_0) ||
	    (ctxt->finishDtd == XML_CTXT_FINISH_DTD_1)) {
	    long delta = (char *) ctxt - (char *) ctxt->userData;
	    if ((delta > 0) && (delta < 250))
		pctxt = ctxt->userData;
	}
    }
    if (extra)
        __xmlRaiseError(NULL, channel, data,
                        pctxt, NULL, XML_FROM_VALID, XML_ERR_NO_MEMORY,
                        XML_ERR_FATAL, NULL, 0, extra, NULL, NULL, 0, 0,
                        "Memory allocation failed : %s\n", extra);
    else
        __xmlRaiseError(NULL, channel, data,
                        pctxt, NULL, XML_FROM_VALID, XML_ERR_NO_MEMORY,
                        XML_ERR_FATAL, NULL, 0, NULL, NULL, NULL, 0, 0,
                        "Memory allocation failed\n");
}

/**
 * xmlErrValid:
 * @ctxt:  an XML validation parser context
 * @error:  the error number
 * @extra:  extra informations
 *
 * Handle a validation error
 */
static void
xmlErrValid(xmlValidCtxtPtr ctxt, xmlParserErrors error,
            const char *msg, const char *extra)
{
    xmlGenericErrorFunc channel = NULL;
    xmlParserCtxtPtr pctxt = NULL;
    void *data = NULL;

    if (ctxt != NULL) {
        channel = ctxt->error;
        data = ctxt->userData;
	/* Use the special values to detect if it is part of a parsing
	   context */
	if ((ctxt->finishDtd == XML_CTXT_FINISH_DTD_0) ||
	    (ctxt->finishDtd == XML_CTXT_FINISH_DTD_1)) {
	    long delta = (char *) ctxt - (char *) ctxt->userData;
	    if ((delta > 0) && (delta < 250))
		pctxt = ctxt->userData;
	}
    }
    if (extra)
        __xmlRaiseError(NULL, channel, data,
                        pctxt, NULL, XML_FROM_VALID, error,
                        XML_ERR_ERROR, NULL, 0, extra, NULL, NULL, 0, 0,
                        msg, extra);
    else
        __xmlRaiseError(NULL, channel, data,
                        pctxt, NULL, XML_FROM_VALID, error,
                        XML_ERR_ERROR, NULL, 0, NULL, NULL, NULL, 0, 0,
                        "%s", msg);
}

#if defined(LIBXML_VALID_ENABLED) || defined(LIBXML_SCHEMAS_ENABLED)
/**
 * xmlErrValidNode:
 * @ctxt:  an XML validation parser context
 * @node:  the node raising the error
 * @error:  the error number
 * @str1:  extra informations
 * @str2:  extra informations
 * @str3:  extra informations
 *
 * Handle a validation error, provide contextual informations
 */
static void
xmlErrValidNode(xmlValidCtxtPtr ctxt,
                xmlNodePtr node, xmlParserErrors error,
                const char *msg, const xmlChar * str1,
                const xmlChar * str2, const xmlChar * str3)
{
    xmlStructuredErrorFunc schannel = NULL;
    xmlGenericErrorFunc channel = NULL;
    xmlParserCtxtPtr pctxt = NULL;
    void *data = NULL;

    if (ctxt != NULL) {
        channel = ctxt->error;
        data = ctxt->userData;
	/* Use the special values to detect if it is part of a parsing
	   context */
	if ((ctxt->finishDtd == XML_CTXT_FINISH_DTD_0) ||
	    (ctxt->finishDtd == XML_CTXT_FINISH_DTD_1)) {
	    long delta = (char *) ctxt - (char *) ctxt->userData;
	    if ((delta > 0) && (delta < 250))
		pctxt = ctxt->userData;
	}
    }
    __xmlRaiseError(schannel, channel, data, pctxt, node, XML_FROM_VALID, error,
                    XML_ERR_ERROR, NULL, 0,
                    (const char *) str1,
                    (const char *) str1,
                    (const char *) str3, 0, 0, msg, str1, str2, str3);
}
#endif /* LIBXML_VALID_ENABLED or LIBXML_SCHEMAS_ENABLED */

#ifdef LIBXML_VALID_ENABLED
/**
 * xmlErrValidNodeNr:
 * @ctxt:  an XML validation parser context
 * @node:  the node raising the error
 * @error:  the error number
 * @str1:  extra informations
 * @int2:  extra informations
 * @str3:  extra informations
 *
 * Handle a validation error, provide contextual informations
 */
static void
xmlErrValidNodeNr(xmlValidCtxtPtr ctxt,
                xmlNodePtr node, xmlParserErrors error,
                const char *msg, const xmlChar * str1,
                int int2, const xmlChar * str3)
{
    xmlStructuredErrorFunc schannel = NULL;
    xmlGenericErrorFunc channel = NULL;
    xmlParserCtxtPtr pctxt = NULL;
    void *data = NULL;

    if (ctxt != NULL) {
        channel = ctxt->error;
        data = ctxt->userData;
	/* Use the special values to detect if it is part of a parsing
	   context */
	if ((ctxt->finishDtd == XML_CTXT_FINISH_DTD_0) ||
	    (ctxt->finishDtd == XML_CTXT_FINISH_DTD_1)) {
	    long delta = (char *) ctxt - (char *) ctxt->userData;
	    if ((delta > 0) && (delta < 250))
		pctxt = ctxt->userData;
	}
    }
    __xmlRaiseError(schannel, channel, data, pctxt, node, XML_FROM_VALID, error,
                    XML_ERR_ERROR, NULL, 0,
                    (const char *) str1,
                    (const char *) str3,
                    NULL, int2, 0, msg, str1, int2, str3);
}

/**
 * xmlErrValidWarning:
 * @ctxt:  an XML validation parser context
 * @node:  the node raising the error
 * @error:  the error number
 * @str1:  extra information
 * @str2:  extra information
 * @str3:  extra information
 *
 * Handle a validation error, provide contextual information
 */
static void
xmlErrValidWarning(xmlValidCtxtPtr ctxt,
                xmlNodePtr node, xmlParserErrors error,
                const char *msg, const xmlChar * str1,
                const xmlChar * str2, const xmlChar * str3)
{
    xmlStructuredErrorFunc schannel = NULL;
    xmlGenericErrorFunc channel = NULL;
    xmlParserCtxtPtr pctxt = NULL;
    void *data = NULL;

    if (ctxt != NULL) {
        channel = ctxt->warning;
        data = ctxt->userData;
	/* Use the special values to detect if it is part of a parsing
	   context */
	if ((ctxt->finishDtd == XML_CTXT_FINISH_DTD_0) ||
	    (ctxt->finishDtd == XML_CTXT_FINISH_DTD_1)) {
	    long delta = (char *) ctxt - (char *) ctxt->userData;
	    if ((delta > 0) && (delta < 250))
		pctxt = ctxt->userData;
	}
    }
    __xmlRaiseError(schannel, channel, data, pctxt, node, XML_FROM_VALID, error,
                    XML_ERR_WARNING, NULL, 0,
                    (const char *) str1,
                    (const char *) str1,
                    (const char *) str3, 0, 0, msg, str1, str2, str3);
}



#ifdef LIBXML_REGEXP_ENABLED
/*
 * If regexp are enabled we can do continuous validation without the
 * need of a tree to validate the content model. this is done in each
 * callbacks.
 * Each xmlValidState represent the validation state associated to the
 * set of nodes currently open from the document root to the current element.
 */


typedef struct _xmlValidState {
    xmlElementPtr	 elemDecl;	/* pointer to the content model */
    xmlNodePtr           node;		/* pointer to the current node */
    xmlRegExecCtxtPtr    exec;		/* regexp runtime */
} _xmlValidState;


static int
vstateVPush(xmlValidCtxtPtr ctxt, xmlElementPtr elemDecl, xmlNodePtr node) {
    if ((ctxt->vstateMax == 0) || (ctxt->vstateTab == NULL)) {
	ctxt->vstateMax = 10;
	ctxt->vstateTab = (xmlValidState *) xmlMalloc(ctxt->vstateMax *
		              sizeof(ctxt->vstateTab[0]));
        if (ctxt->vstateTab == NULL) {
	    xmlVErrMemory(ctxt, "malloc failed");
	    return(-1);
	}
    }

    if (ctxt->vstateNr >= ctxt->vstateMax) {
        xmlValidState *tmp;

	tmp = (xmlValidState *) xmlRealloc(ctxt->vstateTab,
	             2 * ctxt->vstateMax * sizeof(ctxt->vstateTab[0]));
        if (tmp == NULL) {
	    xmlVErrMemory(ctxt, "realloc failed");
	    return(-1);
	}
	ctxt->vstateMax *= 2;
	ctxt->vstateTab = tmp;
    }
    ctxt->vstate = &ctxt->vstateTab[ctxt->vstateNr];
    ctxt->vstateTab[ctxt->vstateNr].elemDecl = elemDecl;
    ctxt->vstateTab[ctxt->vstateNr].node = node;
    if ((elemDecl != NULL) && (elemDecl->etype == XML_ELEMENT_TYPE_ELEMENT)) {
	if (elemDecl->contModel == NULL)
	    xmlValidBuildContentModel(ctxt, elemDecl);
	if (elemDecl->contModel != NULL) {
	    ctxt->vstateTab[ctxt->vstateNr].exec =
		xmlRegNewExecCtxt(elemDecl->contModel, NULL, NULL);
	} else {
	    ctxt->vstateTab[ctxt->vstateNr].exec = NULL;
	    xmlErrValidNode(ctxt, (xmlNodePtr) elemDecl,
	                    XML_ERR_INTERNAL_ERROR,
			    "Failed to build content model regexp for %s\n",
			    node->name, NULL, NULL);
	}
    }
    return(ctxt->vstateNr++);
}

static int
vstateVPop(xmlValidCtxtPtr ctxt) {
    xmlElementPtr elemDecl;

    if (ctxt->vstateNr < 1) return(-1);
    ctxt->vstateNr--;
    elemDecl = ctxt->vstateTab[ctxt->vstateNr].elemDecl;
    ctxt->vstateTab[ctxt->vstateNr].elemDecl = NULL;
    ctxt->vstateTab[ctxt->vstateNr].node = NULL;
    if ((elemDecl != NULL) && (elemDecl->etype == XML_ELEMENT_TYPE_ELEMENT)) {
	xmlRegFreeExecCtxt(ctxt->vstateTab[ctxt->vstateNr].exec);
    }
    ctxt->vstateTab[ctxt->vstateNr].exec = NULL;
    if (ctxt->vstateNr >= 1)
	ctxt->vstate = &ctxt->vstateTab[ctxt->vstateNr - 1];
    else
	ctxt->vstate = NULL;
    return(ctxt->vstateNr);
}

#else /* not LIBXML_REGEXP_ENABLED */
/*
 * If regexp are not enabled, it uses a home made algorithm less
 * complex and easier to
 * debug/maintain than a generic NFA -> DFA state based algo. The
 * only restriction is on the deepness of the tree limited by the
 * size of the occurs bitfield
 *
 * this is the content of a saved state for rollbacks
 */

#define ROLLBACK_OR	0
#define ROLLBACK_PARENT	1

typedef struct _xmlValidState {
    xmlElementContentPtr cont;	/* pointer to the content model subtree */
    xmlNodePtr           node;	/* pointer to the current node in the list */
    long                 occurs;/* bitfield for multiple occurrences */
    unsigned char        depth; /* current depth in the overall tree */
    unsigned char        state; /* ROLLBACK_XXX */
} _xmlValidState;

#define MAX_RECURSE 25000
#define MAX_DEPTH ((sizeof(_xmlValidState.occurs)) * 8)
#define CONT ctxt->vstate->cont
#define NODE ctxt->vstate->node
#define DEPTH ctxt->vstate->depth
#define OCCURS ctxt->vstate->occurs
#define STATE ctxt->vstate->state

#define OCCURRENCE (ctxt->vstate->occurs & (1 << DEPTH))
#define PARENT_OCCURRENCE (ctxt->vstate->occurs & ((1 << DEPTH) - 1))

#define SET_OCCURRENCE ctxt->vstate->occurs |= (1 << DEPTH)
#define RESET_OCCURRENCE ctxt->vstate->occurs &= ((1 << DEPTH) - 1)

static int
vstateVPush(xmlValidCtxtPtr ctxt, xmlElementContentPtr cont,
	    xmlNodePtr node, unsigned char depth, long occurs,
	    unsigned char state) {
    int i = ctxt->vstateNr - 1;

    if (ctxt->vstateNr > MAX_RECURSE) {
	return(-1);
    }
    if (ctxt->vstateTab == NULL) {
	ctxt->vstateMax = 8;
	ctxt->vstateTab = (xmlValidState *) xmlMalloc(
		     ctxt->vstateMax * sizeof(ctxt->vstateTab[0]));
	if (ctxt->vstateTab == NULL) {
	    xmlVErrMemory(ctxt, "malloc failed");
	    return(-1);
	}
    }
    if (ctxt->vstateNr >= ctxt->vstateMax) {
        xmlValidState *tmp;

        tmp = (xmlValidState *) xmlRealloc(ctxt->vstateTab,
	             2 * ctxt->vstateMax * sizeof(ctxt->vstateTab[0]));
        if (tmp == NULL) {
	    xmlVErrMemory(ctxt, "malloc failed");
	    return(-1);
	}
	ctxt->vstateMax *= 2;
	ctxt->vstateTab = tmp;
	ctxt->vstate = &ctxt->vstateTab[0];
    }
    /*
     * Don't push on the stack a state already here
     */
    if ((i >= 0) && (ctxt->vstateTab[i].cont == cont) &&
	(ctxt->vstateTab[i].node == node) &&
	(ctxt->vstateTab[i].depth == depth) &&
	(ctxt->vstateTab[i].occurs == occurs) &&
	(ctxt->vstateTab[i].state == state))
	return(ctxt->vstateNr);
    ctxt->vstateTab[ctxt->vstateNr].cont = cont;
    ctxt->vstateTab[ctxt->vstateNr].node = node;
    ctxt->vstateTab[ctxt->vstateNr].depth = depth;
    ctxt->vstateTab[ctxt->vstateNr].occurs = occurs;
    ctxt->vstateTab[ctxt->vstateNr].state = state;
    return(ctxt->vstateNr++);
}

static int
vstateVPop(xmlValidCtxtPtr ctxt) {
    if (ctxt->vstateNr <= 1) return(-1);
    ctxt->vstateNr--;
    ctxt->vstate = &ctxt->vstateTab[0];
    ctxt->vstate->cont =  ctxt->vstateTab[ctxt->vstateNr].cont;
    ctxt->vstate->node = ctxt->vstateTab[ctxt->vstateNr].node;
    ctxt->vstate->depth = ctxt->vstateTab[ctxt->vstateNr].depth;
    ctxt->vstate->occurs = ctxt->vstateTab[ctxt->vstateNr].occurs;
    ctxt->vstate->state = ctxt->vstateTab[ctxt->vstateNr].state;
    return(ctxt->vstateNr);
}

#endif /* LIBXML_REGEXP_ENABLED */

static int
nodeVPush(xmlValidCtxtPtr ctxt, xmlNodePtr value)
{
    if (ctxt->nodeMax <= 0) {
        ctxt->nodeMax = 4;
        ctxt->nodeTab =
            (xmlNodePtr *) xmlMalloc(ctxt->nodeMax *
                                     sizeof(ctxt->nodeTab[0]));
        if (ctxt->nodeTab == NULL) {
	    xmlVErrMemory(ctxt, "malloc failed");
            ctxt->nodeMax = 0;
            return (0);
        }
    }
    if (ctxt->nodeNr >= ctxt->nodeMax) {
        xmlNodePtr *tmp;
        tmp = (xmlNodePtr *) xmlRealloc(ctxt->nodeTab,
			      ctxt->nodeMax * 2 * sizeof(ctxt->nodeTab[0]));
        if (tmp == NULL) {
	    xmlVErrMemory(ctxt, "realloc failed");
            return (0);
        }
        ctxt->nodeMax *= 2;
	ctxt->nodeTab = tmp;
    }
    ctxt->nodeTab[ctxt->nodeNr] = value;
    ctxt->node = value;
    return (ctxt->nodeNr++);
}
static xmlNodePtr
nodeVPop(xmlValidCtxtPtr ctxt)
{
    xmlNodePtr ret;

    if (ctxt->nodeNr <= 0)
        return (NULL);
    ctxt->nodeNr--;
    if (ctxt->nodeNr > 0)
        ctxt->node = ctxt->nodeTab[ctxt->nodeNr - 1];
    else
        ctxt->node = NULL;
    ret = ctxt->nodeTab[ctxt->nodeNr];
    ctxt->nodeTab[ctxt->nodeNr] = NULL;
    return (ret);
}

#ifdef DEBUG_VALID_ALGO
static void
xmlValidPrintNode(xmlNodePtr cur) {
    if (cur == NULL) {
	xmlGenericError(xmlGenericErrorContext, "null");
	return;
    }
    switch (cur->type) {
	case XML_ELEMENT_NODE:
	    xmlGenericError(xmlGenericErrorContext, "%s ", cur->name);
	    break;
	case XML_TEXT_NODE:
	    xmlGenericError(xmlGenericErrorContext, "text ");
	    break;
	case XML_CDATA_SECTION_NODE:
	    xmlGenericError(xmlGenericErrorContext, "cdata ");
	    break;
	case XML_ENTITY_REF_NODE:
	    xmlGenericError(xmlGenericErrorContext, "&%s; ", cur->name);
	    break;
	case XML_PI_NODE:
	    xmlGenericError(xmlGenericErrorContext, "pi(%s) ", cur->name);
	    break;
	case XML_COMMENT_NODE:
	    xmlGenericError(xmlGenericErrorContext, "comment ");
	    break;
	case XML_ATTRIBUTE_NODE:
	    xmlGenericError(xmlGenericErrorContext, "?attr? ");
	    break;
	case XML_ENTITY_NODE:
	    xmlGenericError(xmlGenericErrorContext, "?ent? ");
	    break;
	case XML_DOCUMENT_NODE:
	    xmlGenericError(xmlGenericErrorContext, "?doc? ");
	    break;
	case XML_DOCUMENT_TYPE_NODE:
	    xmlGenericError(xmlGenericErrorContext, "?doctype? ");
	    break;
	case XML_DOCUMENT_FRAG_NODE:
	    xmlGenericError(xmlGenericErrorContext, "?frag? ");
	    break;
	case XML_NOTATION_NODE:
	    xmlGenericError(xmlGenericErrorContext, "?nota? ");
	    break;
	case XML_HTML_DOCUMENT_NODE:
	    xmlGenericError(xmlGenericErrorContext, "?html? ");
	    break;
#ifdef LIBXML_DOCB_ENABLED
	case XML_DOCB_DOCUMENT_NODE:
	    xmlGenericError(xmlGenericErrorContext, "?docb? ");
	    break;
#endif
	case XML_DTD_NODE:
	    xmlGenericError(xmlGenericErrorContext, "?dtd? ");
	    break;
	case XML_ELEMENT_DECL:
	    xmlGenericError(xmlGenericErrorContext, "?edecl? ");
	    break;
	case XML_ATTRIBUTE_DECL:
	    xmlGenericError(xmlGenericErrorContext, "?adecl? ");
	    break;
	case XML_ENTITY_DECL:
	    xmlGenericError(xmlGenericErrorContext, "?entdecl? ");
	    break;
	case XML_NAMESPACE_DECL:
	    xmlGenericError(xmlGenericErrorContext, "?nsdecl? ");
	    break;
	case XML_XINCLUDE_START:
	    xmlGenericError(xmlGenericErrorContext, "incstart ");
	    break;
	case XML_XINCLUDE_END:
	    xmlGenericError(xmlGenericErrorContext, "incend ");
	    break;
    }
}

static void
xmlValidPrintNodeList(xmlNodePtr cur) {
    if (cur == NULL)
	xmlGenericError(xmlGenericErrorContext, "null ");
    while (cur != NULL) {
	xmlValidPrintNode(cur);
	cur = cur->next;
    }
}

static void
xmlValidDebug(xmlNodePtr cur, xmlElementContentPtr cont) {
    char expr[5000];

    expr[0] = 0;
    xmlGenericError(xmlGenericErrorContext, "valid: ");
    xmlValidPrintNodeList(cur);
    xmlGenericError(xmlGenericErrorContext, "against ");
    xmlSnprintfElementContent(expr, 5000, cont, 1);
    xmlGenericError(xmlGenericErrorContext, "%s\n", expr);
}

static void
xmlValidDebugState(xmlValidStatePtr state) {
    xmlGenericError(xmlGenericErrorContext, "(");
    if (state->cont == NULL)
	xmlGenericError(xmlGenericErrorContext, "null,");
    else
	switch (state->cont->type) {
            case XML_ELEMENT_CONTENT_PCDATA:
		xmlGenericError(xmlGenericErrorContext, "pcdata,");
		break;
            case XML_ELEMENT_CONTENT_ELEMENT:
		xmlGenericError(xmlGenericErrorContext, "%s,",
			        state->cont->name);
		break;
            case XML_ELEMENT_CONTENT_SEQ:
		xmlGenericError(xmlGenericErrorContext, "seq,");
		break;
            case XML_ELEMENT_CONTENT_OR:
		xmlGenericError(xmlGenericErrorContext, "or,");
		break;
	}
    xmlValidPrintNode(state->node);
    xmlGenericError(xmlGenericErrorContext, ",%d,%X,%d)",
	    state->depth, state->occurs, state->state);
}

static void
xmlValidStateDebug(xmlValidCtxtPtr ctxt) {
    int i, j;

    xmlGenericError(xmlGenericErrorContext, "state: ");
    xmlValidDebugState(ctxt->vstate);
    xmlGenericError(xmlGenericErrorContext, " stack: %d ",
	    ctxt->vstateNr - 1);
    for (i = 0, j = ctxt->vstateNr - 1;(i < 3) && (j > 0);i++,j--)
	xmlValidDebugState(&ctxt->vstateTab[j]);
    xmlGenericError(xmlGenericErrorContext, "\n");
}

/*****
#define DEBUG_VALID_STATE(n,c) xmlValidDebug(n,c);
 *****/

#define DEBUG_VALID_STATE(n,c) xmlValidStateDebug(ctxt);
#define DEBUG_VALID_MSG(m)					\
    xmlGenericError(xmlGenericErrorContext, "%s\n", m);

#else
#define DEBUG_VALID_STATE(n,c)
#define DEBUG_VALID_MSG(m)
#endif

/* TODO: use hash table for accesses to elem and attribute definitions */


#define CHECK_DTD						\
   if (doc == NULL) return(0);					\
   else if ((doc->intSubset == NULL) &&				\
	    (doc->extSubset == NULL)) return(0)

#ifdef LIBXML_REGEXP_ENABLED

/************************************************************************
 *									*
 *		Content model validation based on the regexps		*
 *									*
 ************************************************************************/

/**
 * xmlValidBuildAContentModel:
 * @content:  the content model
 * @ctxt:  the schema parser context
 * @name:  the element name whose content is being built
 *
 * Generate the automata sequence needed for that type
 *
 * Returns 1 if successful or 0 in case of error.
 */
static int
xmlValidBuildAContentModel(xmlElementContentPtr content,
		           xmlValidCtxtPtr ctxt,
		           const xmlChar *name) {
    if (content == NULL) {
	xmlErrValidNode(ctxt, NULL, XML_ERR_INTERNAL_ERROR,
			"Found NULL content in content model of %s\n",
			name, NULL, NULL);
	return(0);
    }
    switch (content->type) {
	case XML_ELEMENT_CONTENT_PCDATA:
	    xmlErrValidNode(ctxt, NULL, XML_ERR_INTERNAL_ERROR,
			    "Found PCDATA in content model of %s\n",
		            name, NULL, NULL);
	    return(0);
	    break;
	case XML_ELEMENT_CONTENT_ELEMENT: {
	    xmlAutomataStatePtr oldstate = ctxt->state;
	    xmlChar fn[50];
	    xmlChar *fullname;

	    fullname = xmlBuildQName(content->name, content->prefix, fn, 50);
	    if (fullname == NULL) {
	        xmlVErrMemory(ctxt, "Building content model");
		return(0);
	    }

	    switch (content->ocur) {
		case XML_ELEMENT_CONTENT_ONCE:
		    ctxt->state = xmlAutomataNewTransition(ctxt->am,
			    ctxt->state, NULL, fullname, NULL);
		    break;
		case XML_ELEMENT_CONTENT_OPT:
		    ctxt->state = xmlAutomataNewTransition(ctxt->am,
			    ctxt->state, NULL, fullname, NULL);
		    xmlAutomataNewEpsilon(ctxt->am, oldstate, ctxt->state);
		    break;
		case XML_ELEMENT_CONTENT_PLUS:
		    ctxt->state = xmlAutomataNewTransition(ctxt->am,
			    ctxt->state, NULL, fullname, NULL);
		    xmlAutomataNewTransition(ctxt->am, ctxt->state,
			                     ctxt->state, fullname, NULL);
		    break;
		case XML_ELEMENT_CONTENT_MULT:
		    ctxt->state = xmlAutomataNewEpsilon(ctxt->am,
					    ctxt->state, NULL);
		    xmlAutomataNewTransition(ctxt->am,
			    ctxt->state, ctxt->state, fullname, NULL);
		    break;
	    }
	    if ((fullname != fn) && (fullname != content->name))
		xmlFree(fullname);
	    break;
	}
	case XML_ELEMENT_CONTENT_SEQ: {
	    xmlAutomataStatePtr oldstate, oldend;
	    xmlElementContentOccur ocur;

	    /*
	     * Simply iterate over the content
	     */
	    oldstate = ctxt->state;
	    ocur = content->ocur;
	    if (ocur != XML_ELEMENT_CONTENT_ONCE) {
		ctxt->state = xmlAutomataNewEpsilon(ctxt->am, oldstate, NULL);
		oldstate = ctxt->state;
	    }
	    do {
		xmlValidBuildAContentModel(content->c1, ctxt, name);
		content = content->c2;
	    } while ((content->type == XML_ELEMENT_CONTENT_SEQ) &&
		     (content->ocur == XML_ELEMENT_CONTENT_ONCE));
	    xmlValidBuildAContentModel(content, ctxt, name);
	    oldend = ctxt->state;
	    ctxt->state = xmlAutomataNewEpsilon(ctxt->am, oldend, NULL);
	    switch (ocur) {
		case XML_ELEMENT_CONTENT_ONCE:
		    break;
		case XML_ELEMENT_CONTENT_OPT:
		    xmlAutomataNewEpsilon(ctxt->am, oldstate, ctxt->state);
		    break;
		case XML_ELEMENT_CONTENT_MULT:
		    xmlAutomataNewEpsilon(ctxt->am, oldstate, ctxt->state);
		    xmlAutomataNewEpsilon(ctxt->am, oldend, oldstate);
		    break;
		case XML_ELEMENT_CONTENT_PLUS:
		    xmlAutomataNewEpsilon(ctxt->am, oldend, oldstate);
		    break;
	    }
	    break;
	}
	case XML_ELEMENT_CONTENT_OR: {
	    xmlAutomataStatePtr oldstate, oldend;
	    xmlElementContentOccur ocur;

	    ocur = content->ocur;
	    if ((ocur == XML_ELEMENT_CONTENT_PLUS) ||
		(ocur == XML_ELEMENT_CONTENT_MULT)) {
		ctxt->state = xmlAutomataNewEpsilon(ctxt->am,
			ctxt->state, NULL);
	    }
	    oldstate = ctxt->state;
	    oldend = xmlAutomataNewState(ctxt->am);

	    /*
	     * iterate over the subtypes and remerge the end with an
	     * epsilon transition
	     */
	    do {
		ctxt->state = oldstate;
		xmlValidBuildAContentModel(content->c1, ctxt, name);
		xmlAutomataNewEpsilon(ctxt->am, ctxt->state, oldend);
		content = content->c2;
	    } while ((content->type == XML_ELEMENT_CONTENT_OR) &&
		     (content->ocur == XML_ELEMENT_CONTENT_ONCE));
	    ctxt->state = oldstate;
	    xmlValidBuildAContentModel(content, ctxt, name);
	    xmlAutomataNewEpsilon(ctxt->am, ctxt->state, oldend);
	    ctxt->state = xmlAutomataNewEpsilon(ctxt->am, oldend, NULL);
	    switch (ocur) {
		case XML_ELEMENT_CONTENT_ONCE:
		    break;
		case XML_ELEMENT_CONTENT_OPT:
		    xmlAutomataNewEpsilon(ctxt->am, oldstate, ctxt->state);
		    break;
		case XML_ELEMENT_CONTENT_MULT:
		    xmlAutomataNewEpsilon(ctxt->am, oldstate, ctxt->state);
		    xmlAutomataNewEpsilon(ctxt->am, oldend, oldstate);
		    break;
		case XML_ELEMENT_CONTENT_PLUS:
		    xmlAutomataNewEpsilon(ctxt->am, oldend, oldstate);
		    break;
	    }
	    break;
	}
	default:
	    xmlErrValid(ctxt, XML_ERR_INTERNAL_ERROR,
	                "ContentModel broken for element %s\n",
			(const char *) name);
	    return(0);
    }
    return(1);
}
/**
 * xmlValidBuildContentModel:
 * @ctxt:  a validation context
 * @elem:  an element declaration node
 *
 * (Re)Build the automata associated to the content model of this
 * element
 *
 * Returns 1 in case of success, 0 in case of error
 */
int
xmlValidBuildContentModel(xmlValidCtxtPtr ctxt, xmlElementPtr elem) {

    if ((ctxt == NULL) || (elem == NULL))
	return(0);
    if (elem->type != XML_ELEMENT_DECL)
	return(0);
    if (elem->etype != XML_ELEMENT_TYPE_ELEMENT)
	return(1);
    /* TODO: should we rebuild in this case ? */
    if (elem->contModel != NULL) {
	if (!xmlRegexpIsDeterminist(elem->contModel)) {
	    ctxt->valid = 0;
	    return(0);
	}
	return(1);
    }

    ctxt->am = xmlNewAutomata();
    if (ctxt->am == NULL) {
	xmlErrValidNode(ctxt, (xmlNodePtr) elem,
	                XML_ERR_INTERNAL_ERROR,
	                "Cannot create automata for element %s\n",
		        elem->name, NULL, NULL);
	return(0);
    }
    ctxt->state = xmlAutomataGetInitState(ctxt->am);
    xmlValidBuildAContentModel(elem->content, ctxt, elem->name);
    xmlAutomataSetFinalState(ctxt->am, ctxt->state);
    elem->contModel = xmlAutomataCompile(ctxt->am);
    if (xmlRegexpIsDeterminist(elem->contModel) != 1) {
	char expr[5000];
	expr[0] = 0;
	xmlSnprintfElementContent(expr, 5000, elem->content, 1);
	xmlErrValidNode(ctxt, (xmlNodePtr) elem,
	                XML_DTD_CONTENT_NOT_DETERMINIST,
	       "Content model of %s is not determinist: %s\n",
	       elem->name, BAD_CAST expr, NULL);
#ifdef DEBUG_REGEXP_ALGO
        xmlRegexpPrint(stderr, elem->contModel);
#endif
        ctxt->valid = 0;
	ctxt->state = NULL;
	xmlFreeAutomata(ctxt->am);
	ctxt->am = NULL;
	return(0);
    }
    ctxt->state = NULL;
    xmlFreeAutomata(ctxt->am);
    ctxt->am = NULL;
    return(1);
}

#endif /* LIBXML_REGEXP_ENABLED */

/****************************************************************
 *								*
 *	Util functions for data allocation/deallocation		*
 *								*
 ****************************************************************/

/**
 * xmlNewValidCtxt:
 *
 * Allocate a validation context structure.
 *
 * Returns NULL if not, otherwise the new validation context structure
 */
xmlValidCtxtPtr xmlNewValidCtxt(void) {
    xmlValidCtxtPtr ret;

    if ((ret = xmlMalloc(sizeof (xmlValidCtxt))) == NULL) {
	xmlVErrMemory(NULL, "malloc failed");
	return (NULL);
    }

    (void) memset(ret, 0, sizeof (xmlValidCtxt));

    return (ret);
}

/**
 * xmlFreeValidCtxt:
 * @cur:  the validation context to free
 *
 * Free a validation context structure.
 */
void
xmlFreeValidCtxt(xmlValidCtxtPtr cur) {
    if (cur->vstateTab != NULL)
        xmlFree(cur->vstateTab);
    if (cur->nodeTab != NULL)
        xmlFree(cur->nodeTab);
    xmlFree(cur);
}

#endif /* LIBXML_VALID_ENABLED */

/**
 * xmlNewDocElementContent:
 * @doc:  the document
 * @name:  the subelement name or NULL
 * @type:  the type of element content decl
 *
 * Allocate an element content structure for the document.
 *
 * Returns NULL if not, otherwise the new element content structure
 */
xmlElementContentPtr
xmlNewDocElementContent(xmlDocPtr doc, const xmlChar *name,
                        xmlElementContentType type) {
    xmlElementContentPtr ret;
    xmlDictPtr dict = NULL;

    if (doc != NULL)
        dict = doc->dict;

    switch(type) {
	case XML_ELEMENT_CONTENT_ELEMENT:
	    if (name == NULL) {
	        xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
			"xmlNewElementContent : name == NULL !\n",
			NULL);
	    }
	    break;
        case XML_ELEMENT_CONTENT_PCDATA:
	case XML_ELEMENT_CONTENT_SEQ:
	case XML_ELEMENT_CONTENT_OR:
	    if (name != NULL) {
	        xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
			"xmlNewElementContent : name != NULL !\n",
			NULL);
	    }
	    break;
	default:
	    xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
		    "Internal: ELEMENT content corrupted invalid type\n",
		    NULL);
	    return(NULL);
    }
    ret = (xmlElementContentPtr) xmlMalloc(sizeof(xmlElementContent));
    if (ret == NULL) {
	xmlVErrMemory(NULL, "malloc failed");
	return(NULL);
    }
    memset(ret, 0, sizeof(xmlElementContent));
    ret->type = type;
    ret->ocur = XML_ELEMENT_CONTENT_ONCE;
    if (name != NULL) {
        int l;
	const xmlChar *tmp;

	tmp = xmlSplitQName3(name, &l);
	if (tmp == NULL) {
	    if (dict == NULL)
		ret->name = xmlStrdup(name);
	    else
	        ret->name = xmlDictLookup(dict, name, -1);
	} else {
	    if (dict == NULL) {
		ret->prefix = xmlStrndup(name, l);
		ret->name = xmlStrdup(tmp);
	    } else {
	        ret->prefix = xmlDictLookup(dict, name, l);
		ret->name = xmlDictLookup(dict, tmp, -1);
	    }
	}
    }
    return(ret);
}

/**
 * xmlNewElementContent:
 * @name:  the subelement name or NULL
 * @type:  the type of element content decl
 *
 * Allocate an element content structure.
 * Deprecated in favor of xmlNewDocElementContent
 *
 * Returns NULL if not, otherwise the new element content structure
 */
xmlElementContentPtr
xmlNewElementContent(const xmlChar *name, xmlElementContentType type) {
    return(xmlNewDocElementContent(NULL, name, type));
}

/**
 * xmlCopyDocElementContent:
 * @doc:  the document owning the element declaration
 * @cur:  An element content pointer.
 *
 * Build a copy of an element content description.
 *
 * Returns the new xmlElementContentPtr or NULL in case of error.
 */
xmlElementContentPtr
xmlCopyDocElementContent(xmlDocPtr doc, xmlElementContentPtr cur) {
    xmlElementContentPtr ret = NULL, prev = NULL, tmp;
    xmlDictPtr dict = NULL;

    if (cur == NULL) return(NULL);

    if (doc != NULL)
        dict = doc->dict;

    ret = (xmlElementContentPtr) xmlMalloc(sizeof(xmlElementContent));
    if (ret == NULL) {
	xmlVErrMemory(NULL, "malloc failed");
	return(NULL);
    }
    memset(ret, 0, sizeof(xmlElementContent));
    ret->type = cur->type;
    ret->ocur = cur->ocur;
    if (cur->name != NULL) {
	if (dict)
	    ret->name = xmlDictLookup(dict, cur->name, -1);
	else
	    ret->name = xmlStrdup(cur->name);
    }

    if (cur->prefix != NULL) {
	if (dict)
	    ret->prefix = xmlDictLookup(dict, cur->prefix, -1);
	else
	    ret->prefix = xmlStrdup(cur->prefix);
    }
    if (cur->c1 != NULL)
        ret->c1 = xmlCopyDocElementContent(doc, cur->c1);
    if (ret->c1 != NULL)
	ret->c1->parent = ret;
    if (cur->c2 != NULL) {
        prev = ret;
	cur = cur->c2;
	while (cur != NULL) {
	    tmp = (xmlElementContentPtr) xmlMalloc(sizeof(xmlElementContent));
	    if (tmp == NULL) {
		xmlVErrMemory(NULL, "malloc failed");
		return(ret);
	    }
	    memset(tmp, 0, sizeof(xmlElementContent));
	    tmp->type = cur->type;
	    tmp->ocur = cur->ocur;
	    prev->c2 = tmp;
	    if (cur->name != NULL) {
		if (dict)
		    tmp->name = xmlDictLookup(dict, cur->name, -1);
		else
		    tmp->name = xmlStrdup(cur->name);
	    }

	    if (cur->prefix != NULL) {
		if (dict)
		    tmp->prefix = xmlDictLookup(dict, cur->prefix, -1);
		else
		    tmp->prefix = xmlStrdup(cur->prefix);
	    }
	    if (cur->c1 != NULL)
	        tmp->c1 = xmlCopyDocElementContent(doc,cur->c1);
	    if (tmp->c1 != NULL)
		tmp->c1->parent = ret;
	    prev = tmp;
	    cur = cur->c2;
	}
    }
    return(ret);
}

/**
 * xmlCopyElementContent:
 * @cur:  An element content pointer.
 *
 * Build a copy of an element content description.
 * Deprecated, use xmlCopyDocElementContent instead
 *
 * Returns the new xmlElementContentPtr or NULL in case of error.
 */
xmlElementContentPtr
xmlCopyElementContent(xmlElementContentPtr cur) {
    return(xmlCopyDocElementContent(NULL, cur));
}

/**
 * xmlFreeDocElementContent:
 * @doc: the document owning the element declaration
 * @cur:  the element content tree to free
 *
 * Free an element content structure. The whole subtree is removed.
 */
void
xmlFreeDocElementContent(xmlDocPtr doc, xmlElementContentPtr cur) {
    xmlElementContentPtr next;
    xmlDictPtr dict = NULL;

    if (doc != NULL)
        dict = doc->dict;

    while (cur != NULL) {
        next = cur->c2;
	switch (cur->type) {
	    case XML_ELEMENT_CONTENT_PCDATA:
	    case XML_ELEMENT_CONTENT_ELEMENT:
	    case XML_ELEMENT_CONTENT_SEQ:
	    case XML_ELEMENT_CONTENT_OR:
		break;
	    default:
		xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
			"Internal: ELEMENT content corrupted invalid type\n",
			NULL);
		return;
	}
	if (cur->c1 != NULL) xmlFreeDocElementContent(doc, cur->c1);
	if (dict) {
	    if ((cur->name != NULL) && (!xmlDictOwns(dict, cur->name)))
	        xmlFree((xmlChar *) cur->name);
	    if ((cur->prefix != NULL) && (!xmlDictOwns(dict, cur->prefix)))
	        xmlFree((xmlChar *) cur->prefix);
	} else {
	    if (cur->name != NULL) xmlFree((xmlChar *) cur->name);
	    if (cur->prefix != NULL) xmlFree((xmlChar *) cur->prefix);
	}
	xmlFree(cur);
	cur = next;
    }
}

/**
 * xmlFreeElementContent:
 * @cur:  the element content tree to free
 *
 * Free an element content structure. The whole subtree is removed.
 * Deprecated, use xmlFreeDocElementContent instead
 */
void
xmlFreeElementContent(xmlElementContentPtr cur) {
    xmlFreeDocElementContent(NULL, cur);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlDumpElementContent:
 * @buf:  An XML buffer
 * @content:  An element table
 * @glob: 1 if one must print the englobing parenthesis, 0 otherwise
 *
 * This will dump the content of the element table as an XML DTD definition
 */
static void
xmlDumpElementContent(xmlBufferPtr buf, xmlElementContentPtr content, int glob) {
    if (content == NULL) return;

    if (glob) xmlBufferWriteChar(buf, "(");
    switch (content->type) {
        case XML_ELEMENT_CONTENT_PCDATA:
            xmlBufferWriteChar(buf, "#PCDATA");
	    break;
	case XML_ELEMENT_CONTENT_ELEMENT:
	    if (content->prefix != NULL) {
		xmlBufferWriteCHAR(buf, content->prefix);
		xmlBufferWriteChar(buf, ":");
	    }
	    xmlBufferWriteCHAR(buf, content->name);
	    break;
	case XML_ELEMENT_CONTENT_SEQ:
	    if ((content->c1->type == XML_ELEMENT_CONTENT_OR) ||
	        (content->c1->type == XML_ELEMENT_CONTENT_SEQ))
		xmlDumpElementContent(buf, content->c1, 1);
	    else
		xmlDumpElementContent(buf, content->c1, 0);
            xmlBufferWriteChar(buf, " , ");
	    if ((content->c2->type == XML_ELEMENT_CONTENT_OR) ||
	        ((content->c2->type == XML_ELEMENT_CONTENT_SEQ) &&
		 (content->c2->ocur != XML_ELEMENT_CONTENT_ONCE)))
		xmlDumpElementContent(buf, content->c2, 1);
	    else
		xmlDumpElementContent(buf, content->c2, 0);
	    break;
	case XML_ELEMENT_CONTENT_OR:
	    if ((content->c1->type == XML_ELEMENT_CONTENT_OR) ||
	        (content->c1->type == XML_ELEMENT_CONTENT_SEQ))
		xmlDumpElementContent(buf, content->c1, 1);
	    else
		xmlDumpElementContent(buf, content->c1, 0);
            xmlBufferWriteChar(buf, " | ");
	    if ((content->c2->type == XML_ELEMENT_CONTENT_SEQ) ||
	        ((content->c2->type == XML_ELEMENT_CONTENT_OR) &&
		 (content->c2->ocur != XML_ELEMENT_CONTENT_ONCE)))
		xmlDumpElementContent(buf, content->c2, 1);
	    else
		xmlDumpElementContent(buf, content->c2, 0);
	    break;
	default:
	    xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
		    "Internal: ELEMENT content corrupted invalid type\n",
		    NULL);
    }
    if (glob)
        xmlBufferWriteChar(buf, ")");
    switch (content->ocur) {
        case XML_ELEMENT_CONTENT_ONCE:
	    break;
        case XML_ELEMENT_CONTENT_OPT:
	    xmlBufferWriteChar(buf, "?");
	    break;
        case XML_ELEMENT_CONTENT_MULT:
	    xmlBufferWriteChar(buf, "*");
	    break;
        case XML_ELEMENT_CONTENT_PLUS:
	    xmlBufferWriteChar(buf, "+");
	    break;
    }
}

/**
 * xmlSprintfElementContent:
 * @buf:  an output buffer
 * @content:  An element table
 * @englob: 1 if one must print the englobing parenthesis, 0 otherwise
 *
 * Deprecated, unsafe, use xmlSnprintfElementContent
 */
void
xmlSprintfElementContent(char *buf ATTRIBUTE_UNUSED,
	                 xmlElementContentPtr content ATTRIBUTE_UNUSED,
			 int englob ATTRIBUTE_UNUSED) {
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlSnprintfElementContent:
 * @buf:  an output buffer
 * @size:  the buffer size
 * @content:  An element table
 * @englob: 1 if one must print the englobing parenthesis, 0 otherwise
 *
 * This will dump the content of the element content definition
 * Intended just for the debug routine
 */
void
xmlSnprintfElementContent(char *buf, int size, xmlElementContentPtr content, int englob) {
    int len;

    if (content == NULL) return;
    len = strlen(buf);
    if (size - len < 50) {
	if ((size - len > 4) && (buf[len - 1] != '.'))
	    strcat(buf, " ...");
	return;
    }
    if (englob) strcat(buf, "(");
    switch (content->type) {
        case XML_ELEMENT_CONTENT_PCDATA:
            strcat(buf, "#PCDATA");
	    break;
	case XML_ELEMENT_CONTENT_ELEMENT:
	    if (content->prefix != NULL) {
		if (size - len < xmlStrlen(content->prefix) + 10) {
		    strcat(buf, " ...");
		    return;
		}
		strcat(buf, (char *) content->prefix);
		strcat(buf, ":");
	    }
	    if (size - len < xmlStrlen(content->name) + 10) {
		strcat(buf, " ...");
		return;
	    }
	    if (content->name != NULL)
		strcat(buf, (char *) content->name);
	    break;
	case XML_ELEMENT_CONTENT_SEQ:
	    if ((content->c1->type == XML_ELEMENT_CONTENT_OR) ||
	        (content->c1->type == XML_ELEMENT_CONTENT_SEQ))
		xmlSnprintfElementContent(buf, size, content->c1, 1);
	    else
		xmlSnprintfElementContent(buf, size, content->c1, 0);
	    len = strlen(buf);
	    if (size - len < 50) {
		if ((size - len > 4) && (buf[len - 1] != '.'))
		    strcat(buf, " ...");
		return;
	    }
            strcat(buf, " , ");
	    if (((content->c2->type == XML_ELEMENT_CONTENT_OR) ||
		 (content->c2->ocur != XML_ELEMENT_CONTENT_ONCE)) &&
		(content->c2->type != XML_ELEMENT_CONTENT_ELEMENT))
		xmlSnprintfElementContent(buf, size, content->c2, 1);
	    else
		xmlSnprintfElementContent(buf, size, content->c2, 0);
	    break;
	case XML_ELEMENT_CONTENT_OR:
	    if ((content->c1->type == XML_ELEMENT_CONTENT_OR) ||
	        (content->c1->type == XML_ELEMENT_CONTENT_SEQ))
		xmlSnprintfElementContent(buf, size, content->c1, 1);
	    else
		xmlSnprintfElementContent(buf, size, content->c1, 0);
	    len = strlen(buf);
	    if (size - len < 50) {
		if ((size - len > 4) && (buf[len - 1] != '.'))
		    strcat(buf, " ...");
		return;
	    }
            strcat(buf, " | ");
	    if (((content->c2->type == XML_ELEMENT_CONTENT_SEQ) ||
		 (content->c2->ocur != XML_ELEMENT_CONTENT_ONCE)) &&
		(content->c2->type != XML_ELEMENT_CONTENT_ELEMENT))
		xmlSnprintfElementContent(buf, size, content->c2, 1);
	    else
		xmlSnprintfElementContent(buf, size, content->c2, 0);
	    break;
    }
    if (englob)
        strcat(buf, ")");
    switch (content->ocur) {
        case XML_ELEMENT_CONTENT_ONCE:
	    break;
        case XML_ELEMENT_CONTENT_OPT:
	    strcat(buf, "?");
	    break;
        case XML_ELEMENT_CONTENT_MULT:
	    strcat(buf, "*");
	    break;
        case XML_ELEMENT_CONTENT_PLUS:
	    strcat(buf, "+");
	    break;
    }
}

/****************************************************************
 *								*
 *	Registration of DTD declarations			*
 *								*
 ****************************************************************/

/**
 * xmlFreeElement:
 * @elem:  An element
 *
 * Deallocate the memory used by an element definition
 */
static void
xmlFreeElement(xmlElementPtr elem) {
    if (elem == NULL) return;
    xmlUnlinkNode((xmlNodePtr) elem);
    xmlFreeDocElementContent(elem->doc, elem->content);
    if (elem->name != NULL)
	xmlFree((xmlChar *) elem->name);
    if (elem->prefix != NULL)
	xmlFree((xmlChar *) elem->prefix);
#ifdef LIBXML_REGEXP_ENABLED
    if (elem->contModel != NULL)
	xmlRegFreeRegexp(elem->contModel);
#endif
    xmlFree(elem);
}


/**
 * xmlAddElementDecl:
 * @ctxt:  the validation context
 * @dtd:  pointer to the DTD
 * @name:  the entity name
 * @type:  the element type
 * @content:  the element content tree or NULL
 *
 * Register a new element declaration
 *
 * Returns NULL if not, otherwise the entity
 */
xmlElementPtr
xmlAddElementDecl(xmlValidCtxtPtr ctxt,
                  xmlDtdPtr dtd, const xmlChar *name,
                  xmlElementTypeVal type,
		  xmlElementContentPtr content) {
    xmlElementPtr ret;
    xmlElementTablePtr table;
    xmlAttributePtr oldAttributes = NULL;
    xmlChar *ns, *uqname;

    if (dtd == NULL) {
	return(NULL);
    }
    if (name == NULL) {
	return(NULL);
    }

    switch (type) {
        case XML_ELEMENT_TYPE_EMPTY:
	    if (content != NULL) {
		xmlErrValid(ctxt, XML_ERR_INTERNAL_ERROR,
		        "xmlAddElementDecl: content != NULL for EMPTY\n",
			NULL);
		return(NULL);
	    }
	    break;
	case XML_ELEMENT_TYPE_ANY:
	    if (content != NULL) {
		xmlErrValid(ctxt, XML_ERR_INTERNAL_ERROR,
		        "xmlAddElementDecl: content != NULL for ANY\n",
			NULL);
		return(NULL);
	    }
	    break;
	case XML_ELEMENT_TYPE_MIXED:
	    if (content == NULL) {
		xmlErrValid(ctxt, XML_ERR_INTERNAL_ERROR,
		        "xmlAddElementDecl: content == NULL for MIXED\n",
			NULL);
		return(NULL);
	    }
	    break;
	case XML_ELEMENT_TYPE_ELEMENT:
	    if (content == NULL) {
		xmlErrValid(ctxt, XML_ERR_INTERNAL_ERROR,
		        "xmlAddElementDecl: content == NULL for ELEMENT\n",
			NULL);
		return(NULL);
	    }
	    break;
	default:
	    xmlErrValid(ctxt, XML_ERR_INTERNAL_ERROR,
		    "Internal: ELEMENT decl corrupted invalid type\n",
		    NULL);
	    return(NULL);
    }

    /*
     * check if name is a QName
     */
    uqname = xmlSplitQName2(name, &ns);
    if (uqname != NULL)
	name = uqname;

    /*
     * Create the Element table if needed.
     */
    table = (xmlElementTablePtr) dtd->elements;
    if (table == NULL) {
	xmlDictPtr dict = NULL;

	if (dtd->doc != NULL)
	    dict = dtd->doc->dict;
        table = xmlHashCreateDict(0, dict);
	dtd->elements = (void *) table;
    }
    if (table == NULL) {
	xmlVErrMemory(ctxt,
            "xmlAddElementDecl: Table creation failed!\n");
	if (uqname != NULL)
	    xmlFree(uqname);
	if (ns != NULL)
	    xmlFree(ns);
        return(NULL);
    }

    /*
     * lookup old attributes inserted on an undefined element in the
     * internal subset.
     */
    if ((dtd->doc != NULL) && (dtd->doc->intSubset != NULL)) {
	ret = xmlHashLookup2(dtd->doc->intSubset->elements, name, ns);
	if ((ret != NULL) && (ret->etype == XML_ELEMENT_TYPE_UNDEFINED)) {
	    oldAttributes = ret->attributes;
	    ret->attributes = NULL;
	    xmlHashRemoveEntry2(dtd->doc->intSubset->elements, name, ns, NULL);
	    xmlFreeElement(ret);
	}
    }

    /*
     * The element may already be present if one of its attribute
     * was registered first
     */
    ret = xmlHashLookup2(table, name, ns);
    if (ret != NULL) {
	if (ret->etype != XML_ELEMENT_TYPE_UNDEFINED) {
#ifdef LIBXML_VALID_ENABLED
	    /*
	     * The element is already defined in this DTD.
	     */
	    xmlErrValidNode(ctxt, (xmlNodePtr) dtd, XML_DTD_ELEM_REDEFINED,
	                    "Redefinition of element %s\n",
			    name, NULL, NULL);
#endif /* LIBXML_VALID_ENABLED */
	    if (uqname != NULL)
		xmlFree(uqname);
            if (ns != NULL)
	        xmlFree(ns);
	    return(NULL);
	}
	if (ns != NULL) {
	    xmlFree(ns);
	    ns = NULL;
	}
    } else {
	ret = (xmlElementPtr) xmlMalloc(sizeof(xmlElement));
	if (ret == NULL) {
	    xmlVErrMemory(ctxt, "malloc failed");
	    if (uqname != NULL)
		xmlFree(uqname);
            if (ns != NULL)
	        xmlFree(ns);
	    return(NULL);
	}
	memset(ret, 0, sizeof(xmlElement));
	ret->type = XML_ELEMENT_DECL;

	/*
	 * fill the structure.
	 */
	ret->name = xmlStrdup(name);
	if (ret->name == NULL) {
	    xmlVErrMemory(ctxt, "malloc failed");
	    if (uqname != NULL)
		xmlFree(uqname);
            if (ns != NULL)
	        xmlFree(ns);
	    xmlFree(ret);
	    return(NULL);
	}
	ret->prefix = ns;

	/*
	 * Validity Check:
	 * Insertion must not fail
	 */
	if (xmlHashAddEntry2(table, name, ns, ret)) {
#ifdef LIBXML_VALID_ENABLED
	    /*
	     * The element is already defined in this DTD.
	     */
	    xmlErrValidNode(ctxt, (xmlNodePtr) dtd, XML_DTD_ELEM_REDEFINED,
	                    "Redefinition of element %s\n",
			    name, NULL, NULL);
#endif /* LIBXML_VALID_ENABLED */
	    xmlFreeElement(ret);
	    if (uqname != NULL)
		xmlFree(uqname);
	    return(NULL);
	}
	/*
	 * For new element, may have attributes from earlier
	 * definition in internal subset
	 */
	ret->attributes = oldAttributes;
    }

    /*
     * Finish to fill the structure.
     */
    ret->etype = type;
    /*
     * Avoid a stupid copy when called by the parser
     * and flag it by setting a special parent value
     * so the parser doesn't unallocate it.
     */
    if ((ctxt != NULL) &&
        ((ctxt->finishDtd == XML_CTXT_FINISH_DTD_0) ||
         (ctxt->finishDtd == XML_CTXT_FINISH_DTD_1))) {
	ret->content = content;
	if (content != NULL)
	    content->parent = (xmlElementContentPtr) 1;
    } else {
	ret->content = xmlCopyDocElementContent(dtd->doc, content);
    }

    /*
     * Link it to the DTD
     */
    ret->parent = dtd;
    ret->doc = dtd->doc;
    if (dtd->last == NULL) {
	dtd->children = dtd->last = (xmlNodePtr) ret;
    } else {
        dtd->last->next = (xmlNodePtr) ret;
	ret->prev = dtd->last;
	dtd->last = (xmlNodePtr) ret;
    }
    if (uqname != NULL)
	xmlFree(uqname);
    return(ret);
}

/**
 * xmlFreeElementTable:
 * @table:  An element table
 *
 * Deallocate the memory used by an element hash table.
 */
void
xmlFreeElementTable(xmlElementTablePtr table) {
    xmlHashFree(table, (xmlHashDeallocator) xmlFreeElement);
}

#ifdef LIBXML_TREE_ENABLED
/**
 * xmlCopyElement:
 * @elem:  An element
 *
 * Build a copy of an element.
 *
 * Returns the new xmlElementPtr or NULL in case of error.
 */
static xmlElementPtr
xmlCopyElement(xmlElementPtr elem) {
    xmlElementPtr cur;

    cur = (xmlElementPtr) xmlMalloc(sizeof(xmlElement));
    if (cur == NULL) {
	xmlVErrMemory(NULL, "malloc failed");
	return(NULL);
    }
    memset(cur, 0, sizeof(xmlElement));
    cur->type = XML_ELEMENT_DECL;
    cur->etype = elem->etype;
    if (elem->name != NULL)
	cur->name = xmlStrdup(elem->name);
    else
	cur->name = NULL;
    if (elem->prefix != NULL)
	cur->prefix = xmlStrdup(elem->prefix);
    else
	cur->prefix = NULL;
    cur->content = xmlCopyElementContent(elem->content);
    /* TODO : rebuild the attribute list on the copy */
    cur->attributes = NULL;
    return(cur);
}

/**
 * xmlCopyElementTable:
 * @table:  An element table
 *
 * Build a copy of an element table.
 *
 * Returns the new xmlElementTablePtr or NULL in case of error.
 */
xmlElementTablePtr
xmlCopyElementTable(xmlElementTablePtr table) {
    return((xmlElementTablePtr) xmlHashCopy(table,
		                            (xmlHashCopier) xmlCopyElement));
}
#endif /* LIBXML_TREE_ENABLED */

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlDumpElementDecl:
 * @buf:  the XML buffer output
 * @elem:  An element table
 *
 * This will dump the content of the element declaration as an XML
 * DTD definition
 */
void
xmlDumpElementDecl(xmlBufferPtr buf, xmlElementPtr elem) {
    if ((buf == NULL) || (elem == NULL))
        return;
    switch (elem->etype) {
	case XML_ELEMENT_TYPE_EMPTY:
	    xmlBufferWriteChar(buf, "<!ELEMENT ");
	    if (elem->prefix != NULL) {
		xmlBufferWriteCHAR(buf, elem->prefix);
		xmlBufferWriteChar(buf, ":");
	    }
	    xmlBufferWriteCHAR(buf, elem->name);
	    xmlBufferWriteChar(buf, " EMPTY>\n");
	    break;
	case XML_ELEMENT_TYPE_ANY:
	    xmlBufferWriteChar(buf, "<!ELEMENT ");
	    if (elem->prefix != NULL) {
		xmlBufferWriteCHAR(buf, elem->prefix);
		xmlBufferWriteChar(buf, ":");
	    }
	    xmlBufferWriteCHAR(buf, elem->name);
	    xmlBufferWriteChar(buf, " ANY>\n");
	    break;
	case XML_ELEMENT_TYPE_MIXED:
	    xmlBufferWriteChar(buf, "<!ELEMENT ");
	    if (elem->prefix != NULL) {
		xmlBufferWriteCHAR(buf, elem->prefix);
		xmlBufferWriteChar(buf, ":");
	    }
	    xmlBufferWriteCHAR(buf, elem->name);
	    xmlBufferWriteChar(buf, " ");
	    xmlDumpElementContent(buf, elem->content, 1);
	    xmlBufferWriteChar(buf, ">\n");
	    break;
	case XML_ELEMENT_TYPE_ELEMENT:
	    xmlBufferWriteChar(buf, "<!ELEMENT ");
	    if (elem->prefix != NULL) {
		xmlBufferWriteCHAR(buf, elem->prefix);
		xmlBufferWriteChar(buf, ":");
	    }
	    xmlBufferWriteCHAR(buf, elem->name);
	    xmlBufferWriteChar(buf, " ");
	    xmlDumpElementContent(buf, elem->content, 1);
	    xmlBufferWriteChar(buf, ">\n");
	    break;
	default:
	    xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
		    "Internal: ELEMENT struct corrupted invalid type\n",
		    NULL);
    }
}

/**
 * xmlDumpElementDeclScan:
 * @elem:  An element table
 * @buf:  the XML buffer output
 *
 * This routine is used by the hash scan function.  It just reverses
 * the arguments.
 */
static void
xmlDumpElementDeclScan(xmlElementPtr elem, xmlBufferPtr buf) {
    xmlDumpElementDecl(buf, elem);
}

/**
 * xmlDumpElementTable:
 * @buf:  the XML buffer output
 * @table:  An element table
 *
 * This will dump the content of the element table as an XML DTD definition
 */
void
xmlDumpElementTable(xmlBufferPtr buf, xmlElementTablePtr table) {
    if ((buf == NULL) || (table == NULL))
        return;
    xmlHashScan(table, (xmlHashScanner) xmlDumpElementDeclScan, buf);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlCreateEnumeration:
 * @name:  the enumeration name or NULL
 *
 * create and initialize an enumeration attribute node.
 *
 * Returns the xmlEnumerationPtr just created or NULL in case
 *                of error.
 */
xmlEnumerationPtr
xmlCreateEnumeration(const xmlChar *name) {
    xmlEnumerationPtr ret;

    ret = (xmlEnumerationPtr) xmlMalloc(sizeof(xmlEnumeration));
    if (ret == NULL) {
	xmlVErrMemory(NULL, "malloc failed");
        return(NULL);
    }
    memset(ret, 0, sizeof(xmlEnumeration));

    if (name != NULL)
        ret->name = xmlStrdup(name);
    return(ret);
}

/**
 * xmlFreeEnumeration:
 * @cur:  the tree to free.
 *
 * free an enumeration attribute node (recursive).
 */
void
xmlFreeEnumeration(xmlEnumerationPtr cur) {
    if (cur == NULL) return;

    if (cur->next != NULL) xmlFreeEnumeration(cur->next);

    if (cur->name != NULL) xmlFree((xmlChar *) cur->name);
    xmlFree(cur);
}

#ifdef LIBXML_TREE_ENABLED
/**
 * xmlCopyEnumeration:
 * @cur:  the tree to copy.
 *
 * Copy an enumeration attribute node (recursive).
 *
 * Returns the xmlEnumerationPtr just created or NULL in case
 *                of error.
 */
xmlEnumerationPtr
xmlCopyEnumeration(xmlEnumerationPtr cur) {
    xmlEnumerationPtr ret;

    if (cur == NULL) return(NULL);
    ret = xmlCreateEnumeration((xmlChar *) cur->name);
    if (ret == NULL) return(NULL);

    if (cur->next != NULL) ret->next = xmlCopyEnumeration(cur->next);
    else ret->next = NULL;

    return(ret);
}
#endif /* LIBXML_TREE_ENABLED */

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlDumpEnumeration:
 * @buf:  the XML buffer output
 * @enum:  An enumeration
 *
 * This will dump the content of the enumeration
 */
static void
xmlDumpEnumeration(xmlBufferPtr buf, xmlEnumerationPtr cur) {
    if ((buf == NULL) || (cur == NULL))
        return;

    xmlBufferWriteCHAR(buf, cur->name);
    if (cur->next == NULL)
	xmlBufferWriteChar(buf, ")");
    else {
	xmlBufferWriteChar(buf, " | ");
	xmlDumpEnumeration(buf, cur->next);
    }
}
#endif /* LIBXML_OUTPUT_ENABLED */

#ifdef LIBXML_VALID_ENABLED
/**
 * xmlScanIDAttributeDecl:
 * @ctxt:  the validation context
 * @elem:  the element name
 * @err: whether to raise errors here
 *
 * Verify that the element don't have too many ID attributes
 * declared.
 *
 * Returns the number of ID attributes found.
 */
static int
xmlScanIDAttributeDecl(xmlValidCtxtPtr ctxt, xmlElementPtr elem, int err) {
    xmlAttributePtr cur;
    int ret = 0;

    if (elem == NULL) return(0);
    cur = elem->attributes;
    while (cur != NULL) {
        if (cur->atype == XML_ATTRIBUTE_ID) {
	    ret ++;
	    if ((ret > 1) && (err))
		xmlErrValidNode(ctxt, (xmlNodePtr) elem, XML_DTD_MULTIPLE_ID,
	       "Element %s has too many ID attributes defined : %s\n",
		       elem->name, cur->name, NULL);
	}
	cur = cur->nexth;
    }
    return(ret);
}
#endif /* LIBXML_VALID_ENABLED */

/**
 * xmlFreeAttribute:
 * @elem:  An attribute
 *
 * Deallocate the memory used by an attribute definition
 */
static void
xmlFreeAttribute(xmlAttributePtr attr) {
    xmlDictPtr dict;

    if (attr == NULL) return;
    if (attr->doc != NULL)
	dict = attr->doc->dict;
    else
	dict = NULL;
    xmlUnlinkNode((xmlNodePtr) attr);
    if (attr->tree != NULL)
        xmlFreeEnumeration(attr->tree);
    if (dict) {
        if ((attr->elem != NULL) && (!xmlDictOwns(dict, attr->elem)))
	    xmlFree((xmlChar *) attr->elem);
        if ((attr->name != NULL) && (!xmlDictOwns(dict, attr->name)))
	    xmlFree((xmlChar *) attr->name);
        if ((attr->prefix != NULL) && (!xmlDictOwns(dict, attr->prefix)))
	    xmlFree((xmlChar *) attr->prefix);
        if ((attr->defaultValue != NULL) &&
	    (!xmlDictOwns(dict, attr->defaultValue)))
	    xmlFree((xmlChar *) attr->defaultValue);
    } else {
	if (attr->elem != NULL)
	    xmlFree((xmlChar *) attr->elem);
	if (attr->name != NULL)
	    xmlFree((xmlChar *) attr->name);
	if (attr->defaultValue != NULL)
	    xmlFree((xmlChar *) attr->defaultValue);
	if (attr->prefix != NULL)
	    xmlFree((xmlChar *) attr->prefix);
    }
    xmlFree(attr);
}


/**
 * xmlAddAttributeDecl:
 * @ctxt:  the validation context
 * @dtd:  pointer to the DTD
 * @elem:  the element name
 * @name:  the attribute name
 * @ns:  the attribute namespace prefix
 * @type:  the attribute type
 * @def:  the attribute default type
 * @defaultValue:  the attribute default value
 * @tree:  if it's an enumeration, the associated list
 *
 * Register a new attribute declaration
 * Note that @tree becomes the ownership of the DTD
 *
 * Returns NULL if not new, otherwise the attribute decl
 */
xmlAttributePtr
xmlAddAttributeDecl(xmlValidCtxtPtr ctxt,
                    xmlDtdPtr dtd, const xmlChar *elem,
                    const xmlChar *name, const xmlChar *ns,
		    xmlAttributeType type, xmlAttributeDefault def,
		    const xmlChar *defaultValue, xmlEnumerationPtr tree) {
    xmlAttributePtr ret;
    xmlAttributeTablePtr table;
    xmlElementPtr elemDef;
    xmlDictPtr dict = NULL;

    if (dtd == NULL) {
	xmlFreeEnumeration(tree);
	return(NULL);
    }
    if (name == NULL) {
	xmlFreeEnumeration(tree);
	return(NULL);
    }
    if (elem == NULL) {
	xmlFreeEnumeration(tree);
	return(NULL);
    }
    if (dtd->doc != NULL)
	dict = dtd->doc->dict;

#ifdef LIBXML_VALID_ENABLED
    /*
     * Check the type and possibly the default value.
     */
    switch (type) {
        case XML_ATTRIBUTE_CDATA:
	    break;
        case XML_ATTRIBUTE_ID:
	    break;
        case XML_ATTRIBUTE_IDREF:
	    break;
        case XML_ATTRIBUTE_IDREFS:
	    break;
        case XML_ATTRIBUTE_ENTITY:
	    break;
        case XML_ATTRIBUTE_ENTITIES:
	    break;
        case XML_ATTRIBUTE_NMTOKEN:
	    break;
        case XML_ATTRIBUTE_NMTOKENS:
	    break;
        case XML_ATTRIBUTE_ENUMERATION:
	    break;
        case XML_ATTRIBUTE_NOTATION:
	    break;
	default:
	    xmlErrValid(ctxt, XML_ERR_INTERNAL_ERROR,
		    "Internal: ATTRIBUTE struct corrupted invalid type\n",
		    NULL);
	    xmlFreeEnumeration(tree);
	    return(NULL);
    }
    if ((defaultValue != NULL) &&
        (!xmlValidateAttributeValueInternal(dtd->doc, type, defaultValue))) {
	xmlErrValidNode(ctxt, (xmlNodePtr) dtd, XML_DTD_ATTRIBUTE_DEFAULT,
	                "Attribute %s of %s: invalid default value\n",
	                elem, name, defaultValue);
	defaultValue = NULL;
	if (ctxt != NULL)
	    ctxt->valid = 0;
    }
#endif /* LIBXML_VALID_ENABLED */

    /*
     * Check first that an attribute defined in the external subset wasn't
     * already defined in the internal subset
     */
    if ((dtd->doc != NULL) && (dtd->doc->extSubset == dtd) &&
	(dtd->doc->intSubset != NULL) &&
	(dtd->doc->intSubset->attributes != NULL)) {
        ret = xmlHashLookup3(dtd->doc->intSubset->attributes, name, ns, elem);
	if (ret != NULL) {
	    xmlFreeEnumeration(tree);
	    return(NULL);
	}
    }

    /*
     * Create the Attribute table if needed.
     */
    table = (xmlAttributeTablePtr) dtd->attributes;
    if (table == NULL) {
        table = xmlHashCreateDict(0, dict);
	dtd->attributes = (void *) table;
    }
    if (table == NULL) {
	xmlVErrMemory(ctxt,
            "xmlAddAttributeDecl: Table creation failed!\n");
	xmlFreeEnumeration(tree);
        return(NULL);
    }


    ret = (xmlAttributePtr) xmlMalloc(sizeof(xmlAttribute));
    if (ret == NULL) {
	xmlVErrMemory(ctxt, "malloc failed");
	xmlFreeEnumeration(tree);
	return(NULL);
    }
    memset(ret, 0, sizeof(xmlAttribute));
    ret->type = XML_ATTRIBUTE_DECL;

    /*
     * fill the structure.
     */
    ret->atype = type;
    /*
     * doc must be set before possible error causes call
     * to xmlFreeAttribute (because it's used to check on
     * dict use)
     */
    ret->doc = dtd->doc;
    if (dict) {
	ret->name = xmlDictLookup(dict, name, -1);
	ret->prefix = xmlDictLookup(dict, ns, -1);
	ret->elem = xmlDictLookup(dict, elem, -1);
    } else {
	ret->name = xmlStrdup(name);
	ret->prefix = xmlStrdup(ns);
	ret->elem = xmlStrdup(elem);
    }
    ret->def = def;
    ret->tree = tree;
    if (defaultValue != NULL) {
        if (dict)
	    ret->defaultValue = xmlDictLookup(dict, defaultValue, -1);
	else
	    ret->defaultValue = xmlStrdup(defaultValue);
    }

    /*
     * Validity Check:
     * Search the DTD for previous declarations of the ATTLIST
     */
    if (xmlHashAddEntry3(table, ret->name, ret->prefix, ret->elem, ret) < 0) {
#ifdef LIBXML_VALID_ENABLED
	/*
	 * The attribute is already defined in this DTD.
	 */
	xmlErrValidWarning(ctxt, (xmlNodePtr) dtd, XML_DTD_ATTRIBUTE_REDEFINED,
		 "Attribute %s of element %s: already defined\n",
		 name, elem, NULL);
#endif /* LIBXML_VALID_ENABLED */
	xmlFreeAttribute(ret);
	return(NULL);
    }

    /*
     * Validity Check:
     * Multiple ID per element
     */
    elemDef = xmlGetDtdElementDesc2(dtd, elem, 1);
    if (elemDef != NULL) {

#ifdef LIBXML_VALID_ENABLED
        if ((type == XML_ATTRIBUTE_ID) &&
	    (xmlScanIDAttributeDecl(NULL, elemDef, 1) != 0)) {
	    xmlErrValidNode(ctxt, (xmlNodePtr) dtd, XML_DTD_MULTIPLE_ID,
	   "Element %s has too may ID attributes defined : %s\n",
		   elem, name, NULL);
	    if (ctxt != NULL)
		ctxt->valid = 0;
	}
#endif /* LIBXML_VALID_ENABLED */

	/*
	 * Insert namespace default def first they need to be
	 * processed first.
	 */
	if ((xmlStrEqual(ret->name, BAD_CAST "xmlns")) ||
	    ((ret->prefix != NULL &&
	     (xmlStrEqual(ret->prefix, BAD_CAST "xmlns"))))) {
	    ret->nexth = elemDef->attributes;
	    elemDef->attributes = ret;
	} else {
	    xmlAttributePtr tmp = elemDef->attributes;

	    while ((tmp != NULL) &&
		   ((xmlStrEqual(tmp->name, BAD_CAST "xmlns")) ||
		    ((ret->prefix != NULL &&
		     (xmlStrEqual(ret->prefix, BAD_CAST "xmlns")))))) {
		if (tmp->nexth == NULL)
		    break;
		tmp = tmp->nexth;
	    }
	    if (tmp != NULL) {
		ret->nexth = tmp->nexth;
	        tmp->nexth = ret;
	    } else {
		ret->nexth = elemDef->attributes;
		elemDef->attributes = ret;
	    }
	}
    }

    /*
     * Link it to the DTD
     */
    ret->parent = dtd;
    if (dtd->last == NULL) {
	dtd->children = dtd->last = (xmlNodePtr) ret;
    } else {
        dtd->last->next = (xmlNodePtr) ret;
	ret->prev = dtd->last;
	dtd->last = (xmlNodePtr) ret;
    }
    return(ret);
}

/**
 * xmlFreeAttributeTable:
 * @table:  An attribute table
 *
 * Deallocate the memory used by an entities hash table.
 */
void
xmlFreeAttributeTable(xmlAttributeTablePtr table) {
    xmlHashFree(table, (xmlHashDeallocator) xmlFreeAttribute);
}

#ifdef LIBXML_TREE_ENABLED
/**
 * xmlCopyAttribute:
 * @attr:  An attribute
 *
 * Build a copy of an attribute.
 *
 * Returns the new xmlAttributePtr or NULL in case of error.
 */
static xmlAttributePtr
xmlCopyAttribute(xmlAttributePtr attr) {
    xmlAttributePtr cur;

    cur = (xmlAttributePtr) xmlMalloc(sizeof(xmlAttribute));
    if (cur == NULL) {
	xmlVErrMemory(NULL, "malloc failed");
	return(NULL);
    }
    memset(cur, 0, sizeof(xmlAttribute));
    cur->type = XML_ATTRIBUTE_DECL;
    cur->atype = attr->atype;
    cur->def = attr->def;
    cur->tree = xmlCopyEnumeration(attr->tree);
    if (attr->elem != NULL)
	cur->elem = xmlStrdup(attr->elem);
    if (attr->name != NULL)
	cur->name = xmlStrdup(attr->name);
    if (attr->prefix != NULL)
	cur->prefix = xmlStrdup(attr->prefix);
    if (attr->defaultValue != NULL)
	cur->defaultValue = xmlStrdup(attr->defaultValue);
    return(cur);
}

/**
 * xmlCopyAttributeTable:
 * @table:  An attribute table
 *
 * Build a copy of an attribute table.
 *
 * Returns the new xmlAttributeTablePtr or NULL in case of error.
 */
xmlAttributeTablePtr
xmlCopyAttributeTable(xmlAttributeTablePtr table) {
    return((xmlAttributeTablePtr) xmlHashCopy(table,
				    (xmlHashCopier) xmlCopyAttribute));
}
#endif /* LIBXML_TREE_ENABLED */

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlDumpAttributeDecl:
 * @buf:  the XML buffer output
 * @attr:  An attribute declaration
 *
 * This will dump the content of the attribute declaration as an XML
 * DTD definition
 */
void
xmlDumpAttributeDecl(xmlBufferPtr buf, xmlAttributePtr attr) {
    if ((buf == NULL) || (attr == NULL))
        return;
    xmlBufferWriteChar(buf, "<!ATTLIST ");
    xmlBufferWriteCHAR(buf, attr->elem);
    xmlBufferWriteChar(buf, " ");
    if (attr->prefix != NULL) {
	xmlBufferWriteCHAR(buf, attr->prefix);
	xmlBufferWriteChar(buf, ":");
    }
    xmlBufferWriteCHAR(buf, attr->name);
    switch (attr->atype) {
	case XML_ATTRIBUTE_CDATA:
	    xmlBufferWriteChar(buf, " CDATA");
	    break;
	case XML_ATTRIBUTE_ID:
	    xmlBufferWriteChar(buf, " ID");
	    break;
	case XML_ATTRIBUTE_IDREF:
	    xmlBufferWriteChar(buf, " IDREF");
	    break;
	case XML_ATTRIBUTE_IDREFS:
	    xmlBufferWriteChar(buf, " IDREFS");
	    break;
	case XML_ATTRIBUTE_ENTITY:
	    xmlBufferWriteChar(buf, " ENTITY");
	    break;
	case XML_ATTRIBUTE_ENTITIES:
	    xmlBufferWriteChar(buf, " ENTITIES");
	    break;
	case XML_ATTRIBUTE_NMTOKEN:
	    xmlBufferWriteChar(buf, " NMTOKEN");
	    break;
	case XML_ATTRIBUTE_NMTOKENS:
	    xmlBufferWriteChar(buf, " NMTOKENS");
	    break;
	case XML_ATTRIBUTE_ENUMERATION:
	    xmlBufferWriteChar(buf, " (");
	    xmlDumpEnumeration(buf, attr->tree);
	    break;
	case XML_ATTRIBUTE_NOTATION:
	    xmlBufferWriteChar(buf, " NOTATION (");
	    xmlDumpEnumeration(buf, attr->tree);
	    break;
	default:
	    xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
		    "Internal: ATTRIBUTE struct corrupted invalid type\n",
		    NULL);
    }
    switch (attr->def) {
	case XML_ATTRIBUTE_NONE:
	    break;
	case XML_ATTRIBUTE_REQUIRED:
	    xmlBufferWriteChar(buf, " #REQUIRED");
	    break;
	case XML_ATTRIBUTE_IMPLIED:
	    xmlBufferWriteChar(buf, " #IMPLIED");
	    break;
	case XML_ATTRIBUTE_FIXED:
	    xmlBufferWriteChar(buf, " #FIXED");
	    break;
	default:
	    xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
		    "Internal: ATTRIBUTE struct corrupted invalid def\n",
		    NULL);
    }
    if (attr->defaultValue != NULL) {
	xmlBufferWriteChar(buf, " ");
	xmlBufferWriteQuotedString(buf, attr->defaultValue);
    }
    xmlBufferWriteChar(buf, ">\n");
}

/**
 * xmlDumpAttributeDeclScan:
 * @attr:  An attribute declaration
 * @buf:  the XML buffer output
 *
 * This is used with the hash scan function - just reverses arguments
 */
static void
xmlDumpAttributeDeclScan(xmlAttributePtr attr, xmlBufferPtr buf) {
    xmlDumpAttributeDecl(buf, attr);
}

/**
 * xmlDumpAttributeTable:
 * @buf:  the XML buffer output
 * @table:  An attribute table
 *
 * This will dump the content of the attribute table as an XML DTD definition
 */
void
xmlDumpAttributeTable(xmlBufferPtr buf, xmlAttributeTablePtr table) {
    if ((buf == NULL) || (table == NULL))
        return;
    xmlHashScan(table, (xmlHashScanner) xmlDumpAttributeDeclScan, buf);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/************************************************************************
 *									*
 *				NOTATIONs				*
 *									*
 ************************************************************************/
/**
 * xmlFreeNotation:
 * @not:  A notation
 *
 * Deallocate the memory used by an notation definition
 */
static void
xmlFreeNotation(xmlNotationPtr nota) {
    if (nota == NULL) return;
    if (nota->name != NULL)
	xmlFree((xmlChar *) nota->name);
    if (nota->PublicID != NULL)
	xmlFree((xmlChar *) nota->PublicID);
    if (nota->SystemID != NULL)
	xmlFree((xmlChar *) nota->SystemID);
    xmlFree(nota);
}


/**
 * xmlAddNotationDecl:
 * @dtd:  pointer to the DTD
 * @ctxt:  the validation context
 * @name:  the entity name
 * @PublicID:  the public identifier or NULL
 * @SystemID:  the system identifier or NULL
 *
 * Register a new notation declaration
 *
 * Returns NULL if not, otherwise the entity
 */
xmlNotationPtr
xmlAddNotationDecl(xmlValidCtxtPtr ctxt, xmlDtdPtr dtd,
	           const xmlChar *name,
                   const xmlChar *PublicID, const xmlChar *SystemID) {
    xmlNotationPtr ret;
    xmlNotationTablePtr table;

    if (dtd == NULL) {
	return(NULL);
    }
    if (name == NULL) {
	return(NULL);
    }
    if ((PublicID == NULL) && (SystemID == NULL)) {
	return(NULL);
    }

    /*
     * Create the Notation table if needed.
     */
    table = (xmlNotationTablePtr) dtd->notations;
    if (table == NULL) {
	xmlDictPtr dict = NULL;
	if (dtd->doc != NULL)
	    dict = dtd->doc->dict;

        dtd->notations = table = xmlHashCreateDict(0, dict);
    }
    if (table == NULL) {
	xmlVErrMemory(ctxt,
		"xmlAddNotationDecl: Table creation failed!\n");
        return(NULL);
    }

    ret = (xmlNotationPtr) xmlMalloc(sizeof(xmlNotation));
    if (ret == NULL) {
	xmlVErrMemory(ctxt, "malloc failed");
	return(NULL);
    }
    memset(ret, 0, sizeof(xmlNotation));

    /*
     * fill the structure.
     */
    ret->name = xmlStrdup(name);
    if (SystemID != NULL)
        ret->SystemID = xmlStrdup(SystemID);
    if (PublicID != NULL)
        ret->PublicID = xmlStrdup(PublicID);

    /*
     * Validity Check:
     * Check the DTD for previous declarations of the ATTLIST
     */
    if (xmlHashAddEntry(table, name, ret)) {
#ifdef LIBXML_VALID_ENABLED
	xmlErrValid(NULL, XML_DTD_NOTATION_REDEFINED,
		    "xmlAddNotationDecl: %s already defined\n",
		    (const char *) name);
#endif /* LIBXML_VALID_ENABLED */
	xmlFreeNotation(ret);
	return(NULL);
    }
    return(ret);
}

/**
 * xmlFreeNotationTable:
 * @table:  An notation table
 *
 * Deallocate the memory used by an entities hash table.
 */
void
xmlFreeNotationTable(xmlNotationTablePtr table) {
    xmlHashFree(table, (xmlHashDeallocator) xmlFreeNotation);
}

#ifdef LIBXML_TREE_ENABLED
/**
 * xmlCopyNotation:
 * @nota:  A notation
 *
 * Build a copy of a notation.
 *
 * Returns the new xmlNotationPtr or NULL in case of error.
 */
static xmlNotationPtr
xmlCopyNotation(xmlNotationPtr nota) {
    xmlNotationPtr cur;

    cur = (xmlNotationPtr) xmlMalloc(sizeof(xmlNotation));
    if (cur == NULL) {
	xmlVErrMemory(NULL, "malloc failed");
	return(NULL);
    }
    if (nota->name != NULL)
	cur->name = xmlStrdup(nota->name);
    else
	cur->name = NULL;
    if (nota->PublicID != NULL)
	cur->PublicID = xmlStrdup(nota->PublicID);
    else
	cur->PublicID = NULL;
    if (nota->SystemID != NULL)
	cur->SystemID = xmlStrdup(nota->SystemID);
    else
	cur->SystemID = NULL;
    return(cur);
}

/**
 * xmlCopyNotationTable:
 * @table:  A notation table
 *
 * Build a copy of a notation table.
 *
 * Returns the new xmlNotationTablePtr or NULL in case of error.
 */
xmlNotationTablePtr
xmlCopyNotationTable(xmlNotationTablePtr table) {
    return((xmlNotationTablePtr) xmlHashCopy(table,
				    (xmlHashCopier) xmlCopyNotation));
}
#endif /* LIBXML_TREE_ENABLED */

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlDumpNotationDecl:
 * @buf:  the XML buffer output
 * @nota:  A notation declaration
 *
 * This will dump the content the notation declaration as an XML DTD definition
 */
void
xmlDumpNotationDecl(xmlBufferPtr buf, xmlNotationPtr nota) {
    if ((buf == NULL) || (nota == NULL))
        return;
    xmlBufferWriteChar(buf, "<!NOTATION ");
    xmlBufferWriteCHAR(buf, nota->name);
    if (nota->PublicID != NULL) {
	xmlBufferWriteChar(buf, " PUBLIC ");
	xmlBufferWriteQuotedString(buf, nota->PublicID);
	if (nota->SystemID != NULL) {
	    xmlBufferWriteChar(buf, " ");
	    xmlBufferWriteQuotedString(buf, nota->SystemID);
	}
    } else {
	xmlBufferWriteChar(buf, " SYSTEM ");
	xmlBufferWriteQuotedString(buf, nota->SystemID);
    }
    xmlBufferWriteChar(buf, " >\n");
}

/**
 * xmlDumpNotationDeclScan:
 * @nota:  A notation declaration
 * @buf:  the XML buffer output
 *
 * This is called with the hash scan function, and just reverses args
 */
static void
xmlDumpNotationDeclScan(xmlNotationPtr nota, xmlBufferPtr buf) {
    xmlDumpNotationDecl(buf, nota);
}

/**
 * xmlDumpNotationTable:
 * @buf:  the XML buffer output
 * @table:  A notation table
 *
 * This will dump the content of the notation table as an XML DTD definition
 */
void
xmlDumpNotationTable(xmlBufferPtr buf, xmlNotationTablePtr table) {
    if ((buf == NULL) || (table == NULL))
        return;
    xmlHashScan(table, (xmlHashScanner) xmlDumpNotationDeclScan, buf);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/************************************************************************
 *									*
 *				IDs					*
 *									*
 ************************************************************************/
/**
 * DICT_FREE:
 * @str:  a string
 *
 * Free a string if it is not owned by the "dict" dictionnary in the
 * current scope
 */
#define DICT_FREE(str)						\
	if ((str) && ((!dict) ||				\
	    (xmlDictOwns(dict, (const xmlChar *)(str)) == 0)))	\
	    xmlFree((char *)(str));

/**
 * xmlFreeID:
 * @not:  A id
 *
 * Deallocate the memory used by an id definition
 */
static void
xmlFreeID(xmlIDPtr id) {
    xmlDictPtr dict = NULL;

    if (id == NULL) return;

    if (id->doc != NULL)
        dict = id->doc->dict;

    if (id->value != NULL)
	DICT_FREE(id->value)
    if (id->name != NULL)
	DICT_FREE(id->name)
    xmlFree(id);
}


/**
 * xmlAddID:
 * @ctxt:  the validation context
 * @doc:  pointer to the document
 * @value:  the value name
 * @attr:  the attribute holding the ID
 *
 * Register a new id declaration
 *
 * Returns NULL if not, otherwise the new xmlIDPtr
 */
xmlIDPtr
xmlAddID(xmlValidCtxtPtr ctxt, xmlDocPtr doc, const xmlChar *value,
         xmlAttrPtr attr) {
    xmlIDPtr ret;
    xmlIDTablePtr table;

    if (doc == NULL) {
	return(NULL);
    }
    if (value == NULL) {
	return(NULL);
    }
    if (attr == NULL) {
	return(NULL);
    }

    /*
     * Create the ID table if needed.
     */
    table = (xmlIDTablePtr) doc->ids;
    if (table == NULL)  {
        doc->ids = table = xmlHashCreateDict(0, doc->dict);
    }
    if (table == NULL) {
	xmlVErrMemory(ctxt,
		"xmlAddID: Table creation failed!\n");
        return(NULL);
    }

    ret = (xmlIDPtr) xmlMalloc(sizeof(xmlID));
    if (ret == NULL) {
	xmlVErrMemory(ctxt, "malloc failed");
	return(NULL);
    }

    /*
     * fill the structure.
     */
    ret->value = xmlStrdup(value);
    ret->doc = doc;
    if ((ctxt != NULL) && (ctxt->vstateNr != 0)) {
	/*
	 * Operating in streaming mode, attr is gonna disapear
	 */
	if (doc->dict != NULL)
	    ret->name = xmlDictLookup(doc->dict, attr->name, -1);
	else
	    ret->name = xmlStrdup(attr->name);
	ret->attr = NULL;
    } else {
	ret->attr = attr;
	ret->name = NULL;
    }
    ret->lineno = xmlGetLineNo(attr->parent);

    if (xmlHashAddEntry(table, value, ret) < 0) {
#ifdef LIBXML_VALID_ENABLED
	/*
	 * The id is already defined in this DTD.
	 */
	xmlErrValidNode(ctxt, attr->parent, XML_DTD_ID_REDEFINED,
			"ID %s already defined\n", value, NULL, NULL);
#endif /* LIBXML_VALID_ENABLED */
	xmlFreeID(ret);
	return(NULL);
    }
    if (attr != NULL)
	attr->atype = XML_ATTRIBUTE_ID;
    return(ret);
}

/**
 * xmlFreeIDTable:
 * @table:  An id table
 *
 * Deallocate the memory used by an ID hash table.
 */
void
xmlFreeIDTable(xmlIDTablePtr table) {
    xmlHashFree(table, (xmlHashDeallocator) xmlFreeID);
}

/**
 * xmlIsID:
 * @doc:  the document
 * @elem:  the element carrying the attribute
 * @attr:  the attribute
 *
 * Determine whether an attribute is of type ID. In case we have DTD(s)
 * then this is done if DTD loading has been requested. In the case
 * of HTML documents parsed with the HTML parser, then ID detection is
 * done systematically.
 *
 * Returns 0 or 1 depending on the lookup result
 */
int
xmlIsID(xmlDocPtr doc, xmlNodePtr elem, xmlAttrPtr attr) {
    if ((attr == NULL) || (attr->name == NULL)) return(0);
    if ((attr->ns != NULL) && (attr->ns->prefix != NULL) &&
        (!strcmp((char *) attr->name, "id")) &&
        (!strcmp((char *) attr->ns->prefix, "xml")))
	return(1);
    if (doc == NULL) return(0);
    if ((doc->intSubset == NULL) && (doc->extSubset == NULL) &&
        (doc->type != XML_HTML_DOCUMENT_NODE)) {
	return(0);
    } else if (doc->type == XML_HTML_DOCUMENT_NODE) {
        if ((xmlStrEqual(BAD_CAST "id", attr->name)) ||
	    ((xmlStrEqual(BAD_CAST "name", attr->name)) &&
	    ((elem == NULL) || (xmlStrEqual(elem->name, BAD_CAST "a")))))
	    return(1);
	return(0);
    } else if (elem == NULL) {
	return(0);
    } else {
	xmlAttributePtr attrDecl = NULL;

	xmlChar felem[50], fattr[50];
	xmlChar *fullelemname, *fullattrname;

	fullelemname = (elem->ns != NULL && elem->ns->prefix != NULL) ?
	    xmlBuildQName(elem->name, elem->ns->prefix, felem, 50) :
	    (xmlChar *)elem->name;

	fullattrname = (attr->ns != NULL && attr->ns->prefix != NULL) ?
	    xmlBuildQName(attr->name, attr->ns->prefix, fattr, 50) :
	    (xmlChar *)attr->name;

	if (fullelemname != NULL && fullattrname != NULL) {
	    attrDecl = xmlGetDtdAttrDesc(doc->intSubset, fullelemname,
		                         fullattrname);
	    if ((attrDecl == NULL) && (doc->extSubset != NULL))
		attrDecl = xmlGetDtdAttrDesc(doc->extSubset, fullelemname,
					     fullattrname);
	}

	if ((fullattrname != fattr) && (fullattrname != attr->name))
	    xmlFree(fullattrname);
	if ((fullelemname != felem) && (fullelemname != elem->name))
	    xmlFree(fullelemname);

        if ((attrDecl != NULL) && (attrDecl->atype == XML_ATTRIBUTE_ID))
	    return(1);
    }
    return(0);
}

/**
 * xmlRemoveID:
 * @doc:  the document
 * @attr:  the attribute
 *
 * Remove the given attribute from the ID table maintained internally.
 *
 * Returns -1 if the lookup failed and 0 otherwise
 */
int
xmlRemoveID(xmlDocPtr doc, xmlAttrPtr attr) {
    xmlIDTablePtr table;
    xmlIDPtr id;
    xmlChar *ID;

    if (doc == NULL) return(-1);
    if (attr == NULL) return(-1);

    table = (xmlIDTablePtr) doc->ids;
    if (table == NULL)
        return(-1);

    ID = xmlNodeListGetString(doc, attr->children, 1);
    if (ID == NULL)
        return(-1);

    id = xmlHashLookup(table, ID);
    if (id == NULL || id->attr != attr) {
        xmlFree(ID);
        return(-1);
    }

    xmlHashRemoveEntry(table, ID, (xmlHashDeallocator) xmlFreeID);
    xmlFree(ID);
    attr->atype = 0;
    return(0);
}

/**
 * xmlGetID:
 * @doc:  pointer to the document
 * @ID:  the ID value
 *
 * Search the attribute declaring the given ID
 *
 * Returns NULL if not found, otherwise the xmlAttrPtr defining the ID
 */
xmlAttrPtr
xmlGetID(xmlDocPtr doc, const xmlChar *ID) {
    xmlIDTablePtr table;
    xmlIDPtr id;

    if (doc == NULL) {
	return(NULL);
    }

    if (ID == NULL) {
	return(NULL);
    }

    table = (xmlIDTablePtr) doc->ids;
    if (table == NULL)
        return(NULL);

    id = xmlHashLookup(table, ID);
    if (id == NULL)
	return(NULL);
    if (id->attr == NULL) {
	/*
	 * We are operating on a stream, return a well known reference
	 * since the attribute node doesn't exist anymore
	 */
	return((xmlAttrPtr) doc);
    }
    return(id->attr);
}

/************************************************************************
 *									*
 *				Refs					*
 *									*
 ************************************************************************/
typedef struct xmlRemoveMemo_t
{
	xmlListPtr l;
	xmlAttrPtr ap;
} xmlRemoveMemo;

typedef xmlRemoveMemo *xmlRemoveMemoPtr;

typedef struct xmlValidateMemo_t
{
    xmlValidCtxtPtr ctxt;
    const xmlChar *name;
} xmlValidateMemo;

typedef xmlValidateMemo *xmlValidateMemoPtr;

/**
 * xmlFreeRef:
 * @lk:  A list link
 *
 * Deallocate the memory used by a ref definition
 */
static void
xmlFreeRef(xmlLinkPtr lk) {
    xmlRefPtr ref = (xmlRefPtr)xmlLinkGetData(lk);
    if (ref == NULL) return;
    if (ref->value != NULL)
        xmlFree((xmlChar *)ref->value);
    if (ref->name != NULL)
        xmlFree((xmlChar *)ref->name);
    xmlFree(ref);
}

/**
 * xmlFreeRefList:
 * @list_ref:  A list of references.
 *
 * Deallocate the memory used by a list of references
 */
static void
xmlFreeRefList(xmlListPtr list_ref) {
    if (list_ref == NULL) return;
    xmlListDelete(list_ref);
}

/**
 * xmlWalkRemoveRef:
 * @data:  Contents of current link
 * @user:  Value supplied by the user
 *
 * Returns 0 to abort the walk or 1 to continue
 */
static int
xmlWalkRemoveRef(const void *data, const void *user)
{
    xmlAttrPtr attr0 = ((xmlRefPtr)data)->attr;
    xmlAttrPtr attr1 = ((xmlRemoveMemoPtr)user)->ap;
    xmlListPtr ref_list = ((xmlRemoveMemoPtr)user)->l;

    if (attr0 == attr1) { /* Matched: remove and terminate walk */
        xmlListRemoveFirst(ref_list, (void *)data);
        return 0;
    }
    return 1;
}

/**
 * xmlDummyCompare
 * @data0:  Value supplied by the user
 * @data1:  Value supplied by the user
 *
 * Do nothing, return 0. Used to create unordered lists.
 */
static int
xmlDummyCompare(const void *data0 ATTRIBUTE_UNUSED,
                const void *data1 ATTRIBUTE_UNUSED)
{
    return (0);
}

/**
 * xmlAddRef:
 * @ctxt:  the validation context
 * @doc:  pointer to the document
 * @value:  the value name
 * @attr:  the attribute holding the Ref
 *
 * Register a new ref declaration
 *
 * Returns NULL if not, otherwise the new xmlRefPtr
 */
xmlRefPtr
xmlAddRef(xmlValidCtxtPtr ctxt, xmlDocPtr doc, const xmlChar *value,
    xmlAttrPtr attr) {
    xmlRefPtr ret;
    xmlRefTablePtr table;
    xmlListPtr ref_list;

    if (doc == NULL) {
        return(NULL);
    }
    if (value == NULL) {
        return(NULL);
    }
    if (attr == NULL) {
        return(NULL);
    }

    /*
     * Create the Ref table if needed.
     */
    table = (xmlRefTablePtr) doc->refs;
    if (table == NULL) {
        doc->refs = table = xmlHashCreateDict(0, doc->dict);
    }
    if (table == NULL) {
	xmlVErrMemory(ctxt,
            "xmlAddRef: Table creation failed!\n");
        return(NULL);
    }

    ret = (xmlRefPtr) xmlMalloc(sizeof(xmlRef));
    if (ret == NULL) {
	xmlVErrMemory(ctxt, "malloc failed");
        return(NULL);
    }

    /*
     * fill the structure.
     */
    ret->value = xmlStrdup(value);
    if ((ctxt != NULL) && (ctxt->vstateNr != 0)) {
	/*
	 * Operating in streaming mode, attr is gonna disapear
	 */
	ret->name = xmlStrdup(attr->name);
	ret->attr = NULL;
    } else {
	ret->name = NULL;
	ret->attr = attr;
    }
    ret->lineno = xmlGetLineNo(attr->parent);

    /* To add a reference :-
     * References are maintained as a list of references,
     * Lookup the entry, if no entry create new nodelist
     * Add the owning node to the NodeList
     * Return the ref
     */

    if (NULL == (ref_list = xmlHashLookup(table, value))) {
        if (NULL == (ref_list = xmlListCreate(xmlFreeRef, xmlDummyCompare))) {
	    xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
		    "xmlAddRef: Reference list creation failed!\n",
		    NULL);
	    goto failed;
        }
        if (xmlHashAddEntry(table, value, ref_list) < 0) {
            xmlListDelete(ref_list);
	    xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
		    "xmlAddRef: Reference list insertion failed!\n",
		    NULL);
	    goto failed;
        }
    }
    if (xmlListAppend(ref_list, ret) != 0) {
	xmlErrValid(NULL, XML_ERR_INTERNAL_ERROR,
		    "xmlAddRef: Reference list insertion failed!\n",
		    NULL);
        goto failed;
    }
    return(ret);
failed:
    if (ret != NULL) {
        if (ret->value != NULL)
	    xmlFree((char *)ret->value);
        if (ret->name != NULL)
	    xmlFree((char *)ret->name);
        xmlFree(ret);
    }
    return(NULL);
}

/**
 * xmlFreeRefTable:
 * @table:  An ref table
 *
 * Deallocate the memory used by an Ref hash table.
 */
void
xmlFreeRefTable(xmlRefTablePtr table) {
    xmlHashFree(table, (xmlHashDeallocator) xmlFreeRefList);
}

/**
 * xmlIsRef:
 * @doc:  the document
 * @elem:  the element carrying the attribute
 * @attr:  the attribute
 *
 * Determine whether an attribute is of type Ref. In case we have DTD(s)
 * then this is simple, otherwise we use an heuristic: name Ref (upper
 * or lowercase).
 *
 * Returns 0 or 1 depending on the lookup result
 */
int
xmlIsRef(xmlDocPtr doc, xmlNodePtr elem, xmlAttrPtr attr) {
    if (attr == NULL)
        return(0);
    if (doc == NULL) {
        doc = attr->doc;
	if (doc == NULL) return(0);
    }

    if ((doc->intSubset == NULL) && (doc->extSubset == NULL)) {
        return(0);
    } else if (doc->type == XML_HTML_DOCUMENT_NODE) {
        /* TODO @@@ */
        return(0);
    } else {
        xmlAttributePtr attrDecl;

        if (elem == NULL) return(0);
        attrDecl = xmlGetDtdAttrDesc(doc->intSubset, elem->name, attr->name);
        if ((attrDecl == NULL) && (doc->extSubset != NULL))
            attrDecl = xmlGetDtdAttrDesc(doc->extSubset,
		                         elem->name, attr->name);

	if ((attrDecl != NULL) &&
	    (attrDecl->atype == XML_ATTRIBUTE_IDREF ||
	     attrDecl->atype == XML_ATTRIBUTE_IDREFS))
	return(1);
    }
    return(0);
}

/**
 * xmlRemoveRef:
 * @doc:  the document
 * @attr:  the attribute
 *
 * Remove the given attribute from the Ref table maintained internally.
 *
 * Returns -1 if the lookup failed and 0 otherwise
 */
int
xmlRemoveRef(xmlDocPtr doc, xmlAttrPtr attr) {
    xmlListPtr ref_list;
    xmlRefTablePtr table;
    xmlChar *ID;
    xmlRemoveMemo target;

    if (doc == NULL) return(-1);
    if (attr == NULL) return(-1);

    table = (xmlRefTablePtr) doc->refs;
    if (table == NULL)
        return(-1);

    ID = xmlNodeListGetString(doc, attr->children, 1);
    if (ID == NULL)
        return(-1);

    ref_list = xmlHashLookup(table, ID);
    if(ref_list == NULL) {
        xmlFree(ID);
        return (-1);
    }

    /* At this point, ref_list refers to a list of references which
     * have the same key as the supplied attr. Our list of references
     * is ordered by reference address and we don't have that information
     * here to use when removing. We'll have to walk the list and
     * check for a matching attribute, when we find one stop the walk
     * and remove the entry.
     * The list is ordered by reference, so that means we don't have the
     * key. Passing the list and the reference to the walker means we
     * will have enough data to be able to remove the entry.
     */
    target.l = ref_list;
    target.ap = attr;

    /* Remove the supplied attr from our list */
    xmlListWalk(ref_list, xmlWalkRemoveRef, &target);

    /*If the list is empty then remove the list entry in the hash */
    if (xmlListEmpty(ref_list))
        xmlHashUpdateEntry(table, ID, NULL, (xmlHashDeallocator)
        xmlFreeRefList);
    xmlFree(ID);
    return(0);
}

/**
 * xmlGetRefs:
 * @doc:  pointer to the document
 * @ID:  the ID value
 *
 * Find the set of references for the supplied ID.
 *
 * Returns NULL if not found, otherwise node set for the ID.
 */
xmlListPtr
xmlGetRefs(xmlDocPtr doc, const xmlChar *ID) {
    xmlRefTablePtr table;

    if (doc == NULL) {
        return(NULL);
    }

    if (ID == NULL) {
        return(NULL);
    }

    table = (xmlRefTablePtr) doc->refs;
    if (table == NULL)
        return(NULL);

    return (xmlHashLookup(table, ID));
}

/************************************************************************
 *									*
 *		Routines for validity checking				*
 *									*
 ************************************************************************/

/**
 * xmlGetDtdElementDesc:
 * @dtd:  a pointer to the DtD to search
 * @name:  the element name
 *
 * Search the DTD for the description of this element
 *
 * returns the xmlElementPtr if found or NULL
 */

xmlElementPtr
xmlGetDtdElementDesc(xmlDtdPtr dtd, const xmlChar *name) {
    xmlElementTablePtr table;
    xmlElementPtr cur;
    xmlChar *uqname = NULL, *prefix = NULL;

    if ((dtd == NULL) || (name == NULL)) return(NULL);
    if (dtd->elements == NULL)
	return(NULL);
    table = (xmlElementTablePtr) dtd->elements;

    uqname = xmlSplitQName2(name, &prefix);
    if (uqname != NULL)
        name = uqname;
    cur = xmlHashLookup2(table, name, prefix);
    if (prefix != NULL) xmlFree(prefix);
    if (uqname != NULL) xmlFree(uqname);
    return(cur);
}
/**
 * xmlGetDtdElementDesc2:
 * @dtd:  a pointer to the DtD to search
 * @name:  the element name
 * @create:  create an empty description if not found
 *
 * Search the DTD for the description of this element
 *
 * returns the xmlElementPtr if found or NULL
 */

static xmlElementPtr
xmlGetDtdElementDesc2(xmlDtdPtr dtd, const xmlChar *name, int create) {
    xmlElementTablePtr table;
    xmlElementPtr cur;
    xmlChar *uqname = NULL, *prefix = NULL;

    if (dtd == NULL) return(NULL);
    if (dtd->elements == NULL) {
	xmlDictPtr dict = NULL;

	if (dtd->doc != NULL)
	    dict = dtd->doc->dict;

	if (!create)
	    return(NULL);
	/*
	 * Create the Element table if needed.
	 */
	table = (xmlElementTablePtr) dtd->elements;
	if (table == NULL) {
	    table = xmlHashCreateDict(0, dict);
	    dtd->elements = (void *) table;
	}
	if (table == NULL) {
	    xmlVErrMemory(NULL, "element table allocation failed");
	    return(NULL);
	}
    }
    table = (xmlElementTablePtr) dtd->elements;

    uqname = xmlSplitQName2(name, &prefix);
    if (uqname != NULL)
        name = uqname;
    cur = xmlHashLookup2(table, name, prefix);
    if ((cur == NULL) && (create)) {
	cur = (xmlElementPtr) xmlMalloc(sizeof(xmlElement));
	if (cur == NULL) {
	    xmlVErrMemory(NULL, "malloc failed");
	    return(NULL);
	}
	memset(cur, 0, sizeof(xmlElement));
	cur->type = XML_ELEMENT_DECL;

	/*
	 * fill the structure.
	 */
	cur->name = xmlStrdup(name);
	cur->prefix = xmlStrdup(prefix);
	cur->etype = XML_ELEMENT_TYPE_UNDEFINED;

	xmlHashAddEntry2(table, name, prefix, cur);
    }
    if (prefix != NULL) xmlFree(prefix);
    if (uqname != NULL) xmlFree(uqname);
    return(cur);
}

/**
 * xmlGetDtdQElementDesc:
 * @dtd:  a pointer to the DtD to search
 * @name:  the element name
 * @prefix:  the element namespace prefix
 *
 * Search the DTD for the description of this element
 *
 * returns the xmlElementPtr if found or NULL
 */

xmlElementPtr
xmlGetDtdQElementDesc(xmlDtdPtr dtd, const xmlChar *name,
	              const xmlChar *prefix) {
    xmlElementTablePtr table;

    if (dtd == NULL) return(NULL);
    if (dtd->elements == NULL) return(NULL);
    table = (xmlElementTablePtr) dtd->elements;

    return(xmlHashLookup2(table, name, prefix));
}

/**
 * xmlGetDtdAttrDesc:
 * @dtd:  a pointer to the DtD to search
 * @elem:  the element name
 * @name:  the attribute name
 *
 * Search the DTD for the description of this attribute on
 * this element.
 *
 * returns the xmlAttributePtr if found or NULL
 */

xmlAttributePtr
xmlGetDtdAttrDesc(xmlDtdPtr dtd, const xmlChar *elem, const xmlChar *name) {
    xmlAttributeTablePtr table;
    xmlAttributePtr cur;
    xmlChar *uqname = NULL, *prefix = NULL;

    if (dtd == NULL) return(NULL);
    if (dtd->attributes == NULL) return(NULL);

    table = (xmlAttributeTablePtr) dtd->attributes;
    if (table == NULL)
	return(NULL);

    uqname = xmlSplitQName2(name, &prefix);

    if (uqname != NULL) {
	cur = xmlHashLookup3(table, uqname, prefix, elem);
	if (prefix != NULL) xmlFree(prefix);
	if (uqname != NULL) xmlFree(uqname);
    } else
	cur = xmlHashLookup3(table, name, NULL, elem);
    return(cur);
}

/**
 * xmlGetDtdQAttrDesc:
 * @dtd:  a pointer to the DtD to search
 * @elem:  the element name
 * @name:  the attribute name
 * @prefix:  the attribute namespace prefix
 *
 * Search the DTD for the description of this qualified attribute on
 * this element.
 *
 * returns the xmlAttributePtr if found or NULL
 */

xmlAttributePtr
xmlGetDtdQAttrDesc(xmlDtdPtr dtd, const xmlChar *elem, const xmlChar *name,
	          const xmlChar *prefix) {
    xmlAttributeTablePtr table;

    if (dtd == NULL) return(NULL);
    if (dtd->attributes == NULL) return(NULL);
    table = (xmlAttributeTablePtr) dtd->attributes;

    return(xmlHashLookup3(table, name, prefix, elem));
}

/**
 * xmlGetDtdNotationDesc:
 * @dtd:  a pointer to the DtD to search
 * @name:  the notation name
 *
 * Search the DTD for the description of this notation
 *
 * returns the xmlNotationPtr if found or NULL
 */

xmlNotationPtr
xmlGetDtdNotationDesc(xmlDtdPtr dtd, const xmlChar *name) {
    xmlNotationTablePtr table;

    if (dtd == NULL) return(NULL);
    if (dtd->notations == NULL) return(NULL);
    table = (xmlNotationTablePtr) dtd->notations;

    return(xmlHashLookup(table, name));
}

#if defined(LIBXML_VALID_ENABLED) || defined(LIBXML_SCHEMAS_ENABLED)
/**
 * xmlValidateNotationUse:
 * @ctxt:  the validation context
 * @doc:  the document
 * @notationName:  the notation name to check
 *
 * Validate that the given name match a notation declaration.
 * - [ VC: Notation Declared ]
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateNotationUse(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
                       const xmlChar *notationName) {
    xmlNotationPtr notaDecl;
    if ((doc == NULL) || (doc->intSubset == NULL) ||
        (notationName == NULL)) return(-1);

    notaDecl = xmlGetDtdNotationDesc(doc->intSubset, notationName);
    if ((notaDecl == NULL) && (doc->extSubset != NULL))
	notaDecl = xmlGetDtdNotationDesc(doc->extSubset, notationName);

    if ((notaDecl == NULL) && (ctxt != NULL)) {
	xmlErrValidNode(ctxt, (xmlNodePtr) doc, XML_DTD_UNKNOWN_NOTATION,
	                "NOTATION %s is not declared\n",
		        notationName, NULL, NULL);
	return(0);
    }
    return(1);
}
#endif /* LIBXML_VALID_ENABLED or LIBXML_SCHEMAS_ENABLED */

/**
 * xmlIsMixedElement:
 * @doc:  the document
 * @name:  the element name
 *
 * Search in the DtDs whether an element accept Mixed content (or ANY)
 * basically if it is supposed to accept text childs
 *
 * returns 0 if no, 1 if yes, and -1 if no element description is available
 */

int
xmlIsMixedElement(xmlDocPtr doc, const xmlChar *name) {
    xmlElementPtr elemDecl;

    if ((doc == NULL) || (doc->intSubset == NULL)) return(-1);

    elemDecl = xmlGetDtdElementDesc(doc->intSubset, name);
    if ((elemDecl == NULL) && (doc->extSubset != NULL))
	elemDecl = xmlGetDtdElementDesc(doc->extSubset, name);
    if (elemDecl == NULL) return(-1);
    switch (elemDecl->etype) {
	case XML_ELEMENT_TYPE_UNDEFINED:
	    return(-1);
	case XML_ELEMENT_TYPE_ELEMENT:
	    return(0);
        case XML_ELEMENT_TYPE_EMPTY:
	    /*
	     * return 1 for EMPTY since we want VC error to pop up
	     * on <empty>     </empty> for example
	     */
	case XML_ELEMENT_TYPE_ANY:
	case XML_ELEMENT_TYPE_MIXED:
	    return(1);
    }
    return(1);
}

#ifdef LIBXML_VALID_ENABLED

static int
xmlIsDocNameStartChar(xmlDocPtr doc, int c) {
    if ((doc == NULL) || (doc->properties & XML_DOC_OLD10) == 0) {
        /*
	 * Use the new checks of production [4] [4a] amd [5] of the
	 * Update 5 of XML-1.0
	 */
	if (((c >= 'a') && (c <= 'z')) ||
	    ((c >= 'A') && (c <= 'Z')) ||
	    (c == '_') || (c == ':') ||
	    ((c >= 0xC0) && (c <= 0xD6)) ||
	    ((c >= 0xD8) && (c <= 0xF6)) ||
	    ((c >= 0xF8) && (c <= 0x2FF)) ||
	    ((c >= 0x370) && (c <= 0x37D)) ||
	    ((c >= 0x37F) && (c <= 0x1FFF)) ||
	    ((c >= 0x200C) && (c <= 0x200D)) ||
	    ((c >= 0x2070) && (c <= 0x218F)) ||
	    ((c >= 0x2C00) && (c <= 0x2FEF)) ||
	    ((c >= 0x3001) && (c <= 0xD7FF)) ||
	    ((c >= 0xF900) && (c <= 0xFDCF)) ||
	    ((c >= 0xFDF0) && (c <= 0xFFFD)) ||
	    ((c >= 0x10000) && (c <= 0xEFFFF)))
	    return(1);
    } else {
        if (IS_LETTER(c) || (c == '_') || (c == ':'))
	    return(1);
    }
    return(0);
}

static int
xmlIsDocNameChar(xmlDocPtr doc, int c) {
    if ((doc == NULL) || (doc->properties & XML_DOC_OLD10) == 0) {
        /*
	 * Use the new checks of production [4] [4a] amd [5] of the
	 * Update 5 of XML-1.0
	 */
	if (((c >= 'a') && (c <= 'z')) ||
	    ((c >= 'A') && (c <= 'Z')) ||
	    ((c >= '0') && (c <= '9')) || /* !start */
	    (c == '_') || (c == ':') ||
	    (c == '-') || (c == '.') || (c == 0xB7) || /* !start */
	    ((c >= 0xC0) && (c <= 0xD6)) ||
	    ((c >= 0xD8) && (c <= 0xF6)) ||
	    ((c >= 0xF8) && (c <= 0x2FF)) ||
	    ((c >= 0x300) && (c <= 0x36F)) || /* !start */
	    ((c >= 0x370) && (c <= 0x37D)) ||
	    ((c >= 0x37F) && (c <= 0x1FFF)) ||
	    ((c >= 0x200C) && (c <= 0x200D)) ||
	    ((c >= 0x203F) && (c <= 0x2040)) || /* !start */
	    ((c >= 0x2070) && (c <= 0x218F)) ||
	    ((c >= 0x2C00) && (c <= 0x2FEF)) ||
	    ((c >= 0x3001) && (c <= 0xD7FF)) ||
	    ((c >= 0xF900) && (c <= 0xFDCF)) ||
	    ((c >= 0xFDF0) && (c <= 0xFFFD)) ||
	    ((c >= 0x10000) && (c <= 0xEFFFF)))
	     return(1);
    } else {
        if ((IS_LETTER(c)) || (IS_DIGIT(c)) ||
            (c == '.') || (c == '-') ||
	    (c == '_') || (c == ':') ||
	    (IS_COMBINING(c)) ||
	    (IS_EXTENDER(c)))
	    return(1);
    }
    return(0);
}

/**
 * xmlValidateNameValue:
 * @doc:  pointer to the document or NULL
 * @value:  an Name value
 *
 * Validate that the given value match Name production
 *
 * returns 1 if valid or 0 otherwise
 */

static int
xmlValidateNameValueInternal(xmlDocPtr doc, const xmlChar *value) {
    const xmlChar *cur;
    int val, len;

    if (value == NULL) return(0);
    cur = value;
    val = xmlStringCurrentChar(NULL, cur, &len);
    cur += len;
    if (!xmlIsDocNameStartChar(doc, val))
	return(0);

    val = xmlStringCurrentChar(NULL, cur, &len);
    cur += len;
    while (xmlIsDocNameChar(doc, val)) {
	val = xmlStringCurrentChar(NULL, cur, &len);
	cur += len;
    }

    if (val != 0) return(0);

    return(1);
}

/**
 * xmlValidateNameValue:
 * @value:  an Name value
 *
 * Validate that the given value match Name production
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateNameValue(const xmlChar *value) {
    return(xmlValidateNameValueInternal(NULL, value));
}

/**
 * xmlValidateNamesValueInternal:
 * @doc:  pointer to the document or NULL
 * @value:  an Names value
 *
 * Validate that the given value match Names production
 *
 * returns 1 if valid or 0 otherwise
 */

static int
xmlValidateNamesValueInternal(xmlDocPtr doc, const xmlChar *value) {
    const xmlChar *cur;
    int val, len;

    if (value == NULL) return(0);
    cur = value;
    val = xmlStringCurrentChar(NULL, cur, &len);
    cur += len;

    if (!xmlIsDocNameStartChar(doc, val))
	return(0);

    val = xmlStringCurrentChar(NULL, cur, &len);
    cur += len;
    while (xmlIsDocNameChar(doc, val)) {
	val = xmlStringCurrentChar(NULL, cur, &len);
	cur += len;
    }

    /* Should not test IS_BLANK(val) here -- see erratum E20*/
    while (val == 0x20) {
	while (val == 0x20) {
	    val = xmlStringCurrentChar(NULL, cur, &len);
	    cur += len;
	}

	if (!xmlIsDocNameStartChar(doc, val))
	    return(0);

	val = xmlStringCurrentChar(NULL, cur, &len);
	cur += len;

	while (xmlIsDocNameChar(doc, val)) {
	    val = xmlStringCurrentChar(NULL, cur, &len);
	    cur += len;
	}
    }

    if (val != 0) return(0);

    return(1);
}

/**
 * xmlValidateNamesValue:
 * @value:  an Names value
 *
 * Validate that the given value match Names production
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateNamesValue(const xmlChar *value) {
    return(xmlValidateNamesValueInternal(NULL, value));
}

/**
 * xmlValidateNmtokenValueInternal:
 * @doc:  pointer to the document or NULL
 * @value:  an Nmtoken value
 *
 * Validate that the given value match Nmtoken production
 *
 * [ VC: Name Token ]
 *
 * returns 1 if valid or 0 otherwise
 */

static int
xmlValidateNmtokenValueInternal(xmlDocPtr doc, const xmlChar *value) {
    const xmlChar *cur;
    int val, len;

    if (value == NULL) return(0);
    cur = value;
    val = xmlStringCurrentChar(NULL, cur, &len);
    cur += len;

    if (!xmlIsDocNameChar(doc, val))
	return(0);

    val = xmlStringCurrentChar(NULL, cur, &len);
    cur += len;
    while (xmlIsDocNameChar(doc, val)) {
	val = xmlStringCurrentChar(NULL, cur, &len);
	cur += len;
    }

    if (val != 0) return(0);

    return(1);
}

/**
 * xmlValidateNmtokenValue:
 * @value:  an Nmtoken value
 *
 * Validate that the given value match Nmtoken production
 *
 * [ VC: Name Token ]
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateNmtokenValue(const xmlChar *value) {
    return(xmlValidateNmtokenValueInternal(NULL, value));
}

/**
 * xmlValidateNmtokensValueInternal:
 * @doc:  pointer to the document or NULL
 * @value:  an Nmtokens value
 *
 * Validate that the given value match Nmtokens production
 *
 * [ VC: Name Token ]
 *
 * returns 1 if valid or 0 otherwise
 */

static int
xmlValidateNmtokensValueInternal(xmlDocPtr doc, const xmlChar *value) {
    const xmlChar *cur;
    int val, len;

    if (value == NULL) return(0);
    cur = value;
    val = xmlStringCurrentChar(NULL, cur, &len);
    cur += len;

    while (IS_BLANK(val)) {
	val = xmlStringCurrentChar(NULL, cur, &len);
	cur += len;
    }

    if (!xmlIsDocNameChar(doc, val))
	return(0);

    while (xmlIsDocNameChar(doc, val)) {
	val = xmlStringCurrentChar(NULL, cur, &len);
	cur += len;
    }

    /* Should not test IS_BLANK(val) here -- see erratum E20*/
    while (val == 0x20) {
	while (val == 0x20) {
	    val = xmlStringCurrentChar(NULL, cur, &len);
	    cur += len;
	}
	if (val == 0) return(1);

	if (!xmlIsDocNameChar(doc, val))
	    return(0);

	val = xmlStringCurrentChar(NULL, cur, &len);
	cur += len;

	while (xmlIsDocNameChar(doc, val)) {
	    val = xmlStringCurrentChar(NULL, cur, &len);
	    cur += len;
	}
    }

    if (val != 0) return(0);

    return(1);
}

/**
 * xmlValidateNmtokensValue:
 * @value:  an Nmtokens value
 *
 * Validate that the given value match Nmtokens production
 *
 * [ VC: Name Token ]
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateNmtokensValue(const xmlChar *value) {
    return(xmlValidateNmtokensValueInternal(NULL, value));
}

/**
 * xmlValidateNotationDecl:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @nota:  a notation definition
 *
 * Try to validate a single notation definition
 * basically it does the following checks as described by the
 * XML-1.0 recommendation:
 *  - it seems that no validity constraint exists on notation declarations
 * But this function get called anyway ...
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateNotationDecl(xmlValidCtxtPtr ctxt ATTRIBUTE_UNUSED, xmlDocPtr doc ATTRIBUTE_UNUSED,
                         xmlNotationPtr nota ATTRIBUTE_UNUSED) {
    int ret = 1;

    return(ret);
}

/**
 * xmlValidateAttributeValueInternal:
 * @doc: the document
 * @type:  an attribute type
 * @value:  an attribute value
 *
 * Validate that the given attribute value match  the proper production
 *
 * returns 1 if valid or 0 otherwise
 */

static int
xmlValidateAttributeValueInternal(xmlDocPtr doc, xmlAttributeType type,
                                  const xmlChar *value) {
    switch (type) {
	case XML_ATTRIBUTE_ENTITIES:
	case XML_ATTRIBUTE_IDREFS:
	    return(xmlValidateNamesValueInternal(doc, value));
	case XML_ATTRIBUTE_ENTITY:
	case XML_ATTRIBUTE_IDREF:
	case XML_ATTRIBUTE_ID:
	case XML_ATTRIBUTE_NOTATION:
	    return(xmlValidateNameValueInternal(doc, value));
	case XML_ATTRIBUTE_NMTOKENS:
	case XML_ATTRIBUTE_ENUMERATION:
	    return(xmlValidateNmtokensValueInternal(doc, value));
	case XML_ATTRIBUTE_NMTOKEN:
	    return(xmlValidateNmtokenValueInternal(doc, value));
        case XML_ATTRIBUTE_CDATA:
	    break;
    }
    return(1);
}

/**
 * xmlValidateAttributeValue:
 * @type:  an attribute type
 * @value:  an attribute value
 *
 * Validate that the given attribute value match  the proper production
 *
 * [ VC: ID ]
 * Values of type ID must match the Name production....
 *
 * [ VC: IDREF ]
 * Values of type IDREF must match the Name production, and values
 * of type IDREFS must match Names ...
 *
 * [ VC: Entity Name ]
 * Values of type ENTITY must match the Name production, values
 * of type ENTITIES must match Names ...
 *
 * [ VC: Name Token ]
 * Values of type NMTOKEN must match the Nmtoken production; values
 * of type NMTOKENS must match Nmtokens.
 *
 * returns 1 if valid or 0 otherwise
 */
int
xmlValidateAttributeValue(xmlAttributeType type, const xmlChar *value) {
    return(xmlValidateAttributeValueInternal(NULL, type, value));
}

/**
 * xmlValidateAttributeValue2:
 * @ctxt:  the validation context
 * @doc:  the document
 * @name:  the attribute name (used for error reporting only)
 * @type:  the attribute type
 * @value:  the attribute value
 *
 * Validate that the given attribute value match a given type.
 * This typically cannot be done before having finished parsing
 * the subsets.
 *
 * [ VC: IDREF ]
 * Values of type IDREF must match one of the declared IDs
 * Values of type IDREFS must match a sequence of the declared IDs
 * each Name must match the value of an ID attribute on some element
 * in the XML document; i.e. IDREF values must match the value of
 * some ID attribute
 *
 * [ VC: Entity Name ]
 * Values of type ENTITY must match one declared entity
 * Values of type ENTITIES must match a sequence of declared entities
 *
 * [ VC: Notation Attributes ]
 * all notation names in the declaration must be declared.
 *
 * returns 1 if valid or 0 otherwise
 */

static int
xmlValidateAttributeValue2(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
      const xmlChar *name, xmlAttributeType type, const xmlChar *value) {
    int ret = 1;
    switch (type) {
	case XML_ATTRIBUTE_IDREFS:
	case XML_ATTRIBUTE_IDREF:
	case XML_ATTRIBUTE_ID:
	case XML_ATTRIBUTE_NMTOKENS:
	case XML_ATTRIBUTE_ENUMERATION:
	case XML_ATTRIBUTE_NMTOKEN:
        case XML_ATTRIBUTE_CDATA:
	    break;
	case XML_ATTRIBUTE_ENTITY: {
	    xmlEntityPtr ent;

	    ent = xmlGetDocEntity(doc, value);
	    /* yeah it's a bit messy... */
	    if ((ent == NULL) && (doc->standalone == 1)) {
		doc->standalone = 0;
		ent = xmlGetDocEntity(doc, value);
	    }
	    if (ent == NULL) {
		xmlErrValidNode(ctxt, (xmlNodePtr) doc,
				XML_DTD_UNKNOWN_ENTITY,
   "ENTITY attribute %s reference an unknown entity \"%s\"\n",
		       name, value, NULL);
		ret = 0;
	    } else if (ent->etype != XML_EXTERNAL_GENERAL_UNPARSED_ENTITY) {
		xmlErrValidNode(ctxt, (xmlNodePtr) doc,
				XML_DTD_ENTITY_TYPE,
   "ENTITY attribute %s reference an entity \"%s\" of wrong type\n",
		       name, value, NULL);
		ret = 0;
	    }
	    break;
        }
	case XML_ATTRIBUTE_ENTITIES: {
	    xmlChar *dup, *nam = NULL, *cur, save;
	    xmlEntityPtr ent;

	    dup = xmlStrdup(value);
	    if (dup == NULL)
		return(0);
	    cur = dup;
	    while (*cur != 0) {
		nam = cur;
		while ((*cur != 0) && (!IS_BLANK_CH(*cur))) cur++;
		save = *cur;
		*cur = 0;
		ent = xmlGetDocEntity(doc, nam);
		if (ent == NULL) {
		    xmlErrValidNode(ctxt, (xmlNodePtr) doc,
				    XML_DTD_UNKNOWN_ENTITY,
       "ENTITIES attribute %s reference an unknown entity \"%s\"\n",
			   name, nam, NULL);
		    ret = 0;
		} else if (ent->etype != XML_EXTERNAL_GENERAL_UNPARSED_ENTITY) {
		    xmlErrValidNode(ctxt, (xmlNodePtr) doc,
				    XML_DTD_ENTITY_TYPE,
       "ENTITIES attribute %s reference an entity \"%s\" of wrong type\n",
			   name, nam, NULL);
		    ret = 0;
		}
		if (save == 0)
		    break;
		*cur = save;
		while (IS_BLANK_CH(*cur)) cur++;
	    }
	    xmlFree(dup);
	    break;
	}
	case XML_ATTRIBUTE_NOTATION: {
	    xmlNotationPtr nota;

	    nota = xmlGetDtdNotationDesc(doc->intSubset, value);
	    if ((nota == NULL) && (doc->extSubset != NULL))
		nota = xmlGetDtdNotationDesc(doc->extSubset, value);

	    if (nota == NULL) {
		xmlErrValidNode(ctxt, (xmlNodePtr) doc,
		                XML_DTD_UNKNOWN_NOTATION,
       "NOTATION attribute %s reference an unknown notation \"%s\"\n",
		       name, value, NULL);
		ret = 0;
	    }
	    break;
        }
    }
    return(ret);
}

/**
 * xmlValidCtxtNormalizeAttributeValue:
 * @ctxt: the validation context
 * @doc:  the document
 * @elem:  the parent
 * @name:  the attribute name
 * @value:  the attribute value
 * @ctxt:  the validation context or NULL
 *
 * Does the validation related extra step of the normalization of attribute
 * values:
 *
 * If the declared value is not CDATA, then the XML processor must further
 * process the normalized attribute value by discarding any leading and
 * trailing space (#x20) characters, and by replacing sequences of space
 * (#x20) characters by single space (#x20) character.
 *
 * Also  check VC: Standalone Document Declaration in P32, and update
 *  ctxt->valid accordingly
 *
 * returns a new normalized string if normalization is needed, NULL otherwise
 *      the caller must free the returned value.
 */

xmlChar *
xmlValidCtxtNormalizeAttributeValue(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
	     xmlNodePtr elem, const xmlChar *name, const xmlChar *value) {
    xmlChar *ret, *dst;
    const xmlChar *src;
    xmlAttributePtr attrDecl = NULL;
    int extsubset = 0;

    if (doc == NULL) return(NULL);
    if (elem == NULL) return(NULL);
    if (name == NULL) return(NULL);
    if (value == NULL) return(NULL);

    if ((elem->ns != NULL) && (elem->ns->prefix != NULL)) {
	xmlChar fn[50];
	xmlChar *fullname;

	fullname = xmlBuildQName(elem->name, elem->ns->prefix, fn, 50);
	if (fullname == NULL)
	    return(NULL);
	attrDecl = xmlGetDtdAttrDesc(doc->intSubset, fullname, name);
	if ((attrDecl == NULL) && (doc->extSubset != NULL)) {
	    attrDecl = xmlGetDtdAttrDesc(doc->extSubset, fullname, name);
	    if (attrDecl != NULL)
		extsubset = 1;
	}
	if ((fullname != fn) && (fullname != elem->name))
	    xmlFree(fullname);
    }
    if ((attrDecl == NULL) && (doc->intSubset != NULL))
	attrDecl = xmlGetDtdAttrDesc(doc->intSubset, elem->name, name);
    if ((attrDecl == NULL) && (doc->extSubset != NULL)) {
	attrDecl = xmlGetDtdAttrDesc(doc->extSubset, elem->name, name);
	if (attrDecl != NULL)
	    extsubset = 1;
    }

    if (attrDecl == NULL)
	return(NULL);
    if (attrDecl->atype == XML_ATTRIBUTE_CDATA)
	return(NULL);

    ret = xmlStrdup(value);
    if (ret == NULL)
	return(NULL);
    src = value;
    dst = ret;
    while (*src == 0x20) src++;
    while (*src != 0) {
	if (*src == 0x20) {
	    while (*src == 0x20) src++;
	    if (*src != 0)
		*dst++ = 0x20;
	} else {
	    *dst++ = *src++;
	}
    }
    *dst = 0;
    if ((doc->standalone) && (extsubset == 1) && (!xmlStrEqual(value, ret))) {
	xmlErrValidNode(ctxt, elem, XML_DTD_NOT_STANDALONE,
"standalone: %s on %s value had to be normalized based on external subset declaration\n",
	       name, elem->name, NULL);
	ctxt->valid = 0;
    }
    return(ret);
}

/**
 * xmlValidNormalizeAttributeValue:
 * @doc:  the document
 * @elem:  the parent
 * @name:  the attribute name
 * @value:  the attribute value
 *
 * Does the validation related extra step of the normalization of attribute
 * values:
 *
 * If the declared value is not CDATA, then the XML processor must further
 * process the normalized attribute value by discarding any leading and
 * trailing space (#x20) characters, and by replacing sequences of space
 * (#x20) characters by single space (#x20) character.
 *
 * Returns a new normalized string if normalization is needed, NULL otherwise
 *      the caller must free the returned value.
 */

xmlChar *
xmlValidNormalizeAttributeValue(xmlDocPtr doc, xmlNodePtr elem,
			        const xmlChar *name, const xmlChar *value) {
    xmlChar *ret, *dst;
    const xmlChar *src;
    xmlAttributePtr attrDecl = NULL;

    if (doc == NULL) return(NULL);
    if (elem == NULL) return(NULL);
    if (name == NULL) return(NULL);
    if (value == NULL) return(NULL);

    if ((elem->ns != NULL) && (elem->ns->prefix != NULL)) {
	xmlChar fn[50];
	xmlChar *fullname;

	fullname = xmlBuildQName(elem->name, elem->ns->prefix, fn, 50);
	if (fullname == NULL)
	    return(NULL);
	if ((fullname != fn) && (fullname != elem->name))
	    xmlFree(fullname);
    }
    attrDecl = xmlGetDtdAttrDesc(doc->intSubset, elem->name, name);
    if ((attrDecl == NULL) && (doc->extSubset != NULL))
	attrDecl = xmlGetDtdAttrDesc(doc->extSubset, elem->name, name);

    if (attrDecl == NULL)
	return(NULL);
    if (attrDecl->atype == XML_ATTRIBUTE_CDATA)
	return(NULL);

    ret = xmlStrdup(value);
    if (ret == NULL)
	return(NULL);
    src = value;
    dst = ret;
    while (*src == 0x20) src++;
    while (*src != 0) {
	if (*src == 0x20) {
	    while (*src == 0x20) src++;
	    if (*src != 0)
		*dst++ = 0x20;
	} else {
	    *dst++ = *src++;
	}
    }
    *dst = 0;
    return(ret);
}

static void
xmlValidateAttributeIdCallback(xmlAttributePtr attr, int *count,
	                       const xmlChar* name ATTRIBUTE_UNUSED) {
    if (attr->atype == XML_ATTRIBUTE_ID) (*count)++;
}

/**
 * xmlValidateAttributeDecl:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @attr:  an attribute definition
 *
 * Try to validate a single attribute definition
 * basically it does the following checks as described by the
 * XML-1.0 recommendation:
 *  - [ VC: Attribute Default Legal ]
 *  - [ VC: Enumeration ]
 *  - [ VC: ID Attribute Default ]
 *
 * The ID/IDREF uniqueness and matching are done separately
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateAttributeDecl(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
                         xmlAttributePtr attr) {
    int ret = 1;
    int val;
    CHECK_DTD;
    if(attr == NULL) return(1);

    /* Attribute Default Legal */
    /* Enumeration */
    if (attr->defaultValue != NULL) {
	val = xmlValidateAttributeValueInternal(doc, attr->atype,
	                                        attr->defaultValue);
	if (val == 0) {
	    xmlErrValidNode(ctxt, (xmlNodePtr) attr, XML_DTD_ATTRIBUTE_DEFAULT,
	       "Syntax of default value for attribute %s of %s is not valid\n",
	           attr->name, attr->elem, NULL);
	}
        ret &= val;
    }

    /* ID Attribute Default */
    if ((attr->atype == XML_ATTRIBUTE_ID)&&
        (attr->def != XML_ATTRIBUTE_IMPLIED) &&
	(attr->def != XML_ATTRIBUTE_REQUIRED)) {
	xmlErrValidNode(ctxt, (xmlNodePtr) attr, XML_DTD_ID_FIXED,
          "ID attribute %s of %s is not valid must be #IMPLIED or #REQUIRED\n",
	       attr->name, attr->elem, NULL);
	ret = 0;
    }

    /* One ID per Element Type */
    if (attr->atype == XML_ATTRIBUTE_ID) {
        int nbId;

	/* the trick is that we parse DtD as their own internal subset */
        xmlElementPtr elem = xmlGetDtdElementDesc(doc->intSubset,
	                                          attr->elem);
	if (elem != NULL) {
	    nbId = xmlScanIDAttributeDecl(NULL, elem, 0);
	} else {
	    xmlAttributeTablePtr table;

	    /*
	     * The attribute may be declared in the internal subset and the
	     * element in the external subset.
	     */
	    nbId = 0;
	    if (doc->intSubset != NULL) {
		table = (xmlAttributeTablePtr) doc->intSubset->attributes;
		xmlHashScan3(table, NULL, NULL, attr->elem, (xmlHashScanner)
			     xmlValidateAttributeIdCallback, &nbId);
	    }
	}
	if (nbId > 1) {

	    xmlErrValidNodeNr(ctxt, (xmlNodePtr) attr, XML_DTD_ID_SUBSET,
       "Element %s has %d ID attribute defined in the internal subset : %s\n",
		   attr->elem, nbId, attr->name);
	} else if (doc->extSubset != NULL) {
	    int extId = 0;
	    elem = xmlGetDtdElementDesc(doc->extSubset, attr->elem);
	    if (elem != NULL) {
		extId = xmlScanIDAttributeDecl(NULL, elem, 0);
	    }
	    if (extId > 1) {
		xmlErrValidNodeNr(ctxt, (xmlNodePtr) attr, XML_DTD_ID_SUBSET,
       "Element %s has %d ID attribute defined in the external subset : %s\n",
		       attr->elem, extId, attr->name);
	    } else if (extId + nbId > 1) {
		xmlErrValidNode(ctxt, (xmlNodePtr) attr, XML_DTD_ID_SUBSET,
"Element %s has ID attributes defined in the internal and external subset : %s\n",
		       attr->elem, attr->name, NULL);
	    }
	}
    }

    /* Validity Constraint: Enumeration */
    if ((attr->defaultValue != NULL) && (attr->tree != NULL)) {
        xmlEnumerationPtr tree = attr->tree;
	while (tree != NULL) {
	    if (xmlStrEqual(tree->name, attr->defaultValue)) break;
	    tree = tree->next;
	}
	if (tree == NULL) {
	    xmlErrValidNode(ctxt, (xmlNodePtr) attr, XML_DTD_ATTRIBUTE_VALUE,
"Default value \"%s\" for attribute %s of %s is not among the enumerated set\n",
		   attr->defaultValue, attr->name, attr->elem);
	    ret = 0;
	}
    }

    return(ret);
}

/**
 * xmlValidateElementDecl:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element definition
 *
 * Try to validate a single element definition
 * basically it does the following checks as described by the
 * XML-1.0 recommendation:
 *  - [ VC: One ID per Element Type ]
 *  - [ VC: No Duplicate Types ]
 *  - [ VC: Unique Element Type Declaration ]
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateElementDecl(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
                       xmlElementPtr elem) {
    int ret = 1;
    xmlElementPtr tst;

    CHECK_DTD;

    if (elem == NULL) return(1);

#if 0
#ifdef LIBXML_REGEXP_ENABLED
    /* Build the regexp associated to the content model */
    ret = xmlValidBuildContentModel(ctxt, elem);
#endif
#endif

    /* No Duplicate Types */
    if (elem->etype == XML_ELEMENT_TYPE_MIXED) {
	xmlElementContentPtr cur, next;
        const xmlChar *name;

	cur = elem->content;
	while (cur != NULL) {
	    if (cur->type != XML_ELEMENT_CONTENT_OR) break;
	    if (cur->c1 == NULL) break;
	    if (cur->c1->type == XML_ELEMENT_CONTENT_ELEMENT) {
		name = cur->c1->name;
		next = cur->c2;
		while (next != NULL) {
		    if (next->type == XML_ELEMENT_CONTENT_ELEMENT) {
		        if ((xmlStrEqual(next->name, name)) &&
			    (xmlStrEqual(next->prefix, cur->c1->prefix))) {
			    if (cur->c1->prefix == NULL) {
				xmlErrValidNode(ctxt, (xmlNodePtr) elem, XML_DTD_CONTENT_ERROR,
		   "Definition of %s has duplicate references of %s\n",
				       elem->name, name, NULL);
			    } else {
				xmlErrValidNode(ctxt, (xmlNodePtr) elem, XML_DTD_CONTENT_ERROR,
		   "Definition of %s has duplicate references of %s:%s\n",
				       elem->name, cur->c1->prefix, name);
			    }
			    ret = 0;
			}
			break;
		    }
		    if (next->c1 == NULL) break;
		    if (next->c1->type != XML_ELEMENT_CONTENT_ELEMENT) break;
		    if ((xmlStrEqual(next->c1->name, name)) &&
		        (xmlStrEqual(next->c1->prefix, cur->c1->prefix))) {
			if (cur->c1->prefix == NULL) {
			    xmlErrValidNode(ctxt, (xmlNodePtr) elem, XML_DTD_CONTENT_ERROR,
	       "Definition of %s has duplicate references to %s\n",
				   elem->name, name, NULL);
			} else {
			    xmlErrValidNode(ctxt, (xmlNodePtr) elem, XML_DTD_CONTENT_ERROR,
	       "Definition of %s has duplicate references to %s:%s\n",
				   elem->name, cur->c1->prefix, name);
			}
			ret = 0;
		    }
		    next = next->c2;
		}
	    }
	    cur = cur->c2;
	}
    }

    /* VC: Unique Element Type Declaration */
    tst = xmlGetDtdElementDesc(doc->intSubset, elem->name);
    if ((tst != NULL ) && (tst != elem) &&
	((tst->prefix == elem->prefix) ||
	 (xmlStrEqual(tst->prefix, elem->prefix))) &&
	(tst->etype != XML_ELEMENT_TYPE_UNDEFINED)) {
	xmlErrValidNode(ctxt, (xmlNodePtr) elem, XML_DTD_ELEM_REDEFINED,
	                "Redefinition of element %s\n",
		       elem->name, NULL, NULL);
	ret = 0;
    }
    tst = xmlGetDtdElementDesc(doc->extSubset, elem->name);
    if ((tst != NULL ) && (tst != elem) &&
	((tst->prefix == elem->prefix) ||
	 (xmlStrEqual(tst->prefix, elem->prefix))) &&
	(tst->etype != XML_ELEMENT_TYPE_UNDEFINED)) {
	xmlErrValidNode(ctxt, (xmlNodePtr) elem, XML_DTD_ELEM_REDEFINED,
	                "Redefinition of element %s\n",
		       elem->name, NULL, NULL);
	ret = 0;
    }
    /* One ID per Element Type
     * already done when registering the attribute
    if (xmlScanIDAttributeDecl(ctxt, elem) > 1) {
	ret = 0;
    } */
    return(ret);
}

/**
 * xmlValidateOneAttribute:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element instance
 * @attr:  an attribute instance
 * @value:  the attribute value (without entities processing)
 *
 * Try to validate a single attribute for an element
 * basically it does the following checks as described by the
 * XML-1.0 recommendation:
 *  - [ VC: Attribute Value Type ]
 *  - [ VC: Fixed Attribute Default ]
 *  - [ VC: Entity Name ]
 *  - [ VC: Name Token ]
 *  - [ VC: ID ]
 *  - [ VC: IDREF ]
 *  - [ VC: Entity Name ]
 *  - [ VC: Notation Attributes ]
 *
 * The ID/IDREF uniqueness and matching are done separately
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateOneAttribute(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
                        xmlNodePtr elem, xmlAttrPtr attr, const xmlChar *value)
{
    xmlAttributePtr attrDecl =  NULL;
    int val;
    int ret = 1;

    CHECK_DTD;
    if ((elem == NULL) || (elem->name == NULL)) return(0);
    if ((attr == NULL) || (attr->name == NULL)) return(0);

    if ((elem->ns != NULL) && (elem->ns->prefix != NULL)) {
	xmlChar fn[50];
	xmlChar *fullname;

	fullname = xmlBuildQName(elem->name, elem->ns->prefix, fn, 50);
	if (fullname == NULL)
	    return(0);
	if (attr->ns != NULL) {
	    attrDecl = xmlGetDtdQAttrDesc(doc->intSubset, fullname,
		                          attr->name, attr->ns->prefix);
	    if ((attrDecl == NULL) && (doc->extSubset != NULL))
		attrDecl = xmlGetDtdQAttrDesc(doc->extSubset, fullname,
					      attr->name, attr->ns->prefix);
	} else {
	    attrDecl = xmlGetDtdAttrDesc(doc->intSubset, fullname, attr->name);
	    if ((attrDecl == NULL) && (doc->extSubset != NULL))
		attrDecl = xmlGetDtdAttrDesc(doc->extSubset,
					     fullname, attr->name);
	}
	if ((fullname != fn) && (fullname != elem->name))
	    xmlFree(fullname);
    }
    if (attrDecl == NULL) {
	if (attr->ns != NULL) {
	    attrDecl = xmlGetDtdQAttrDesc(doc->intSubset, elem->name,
		                          attr->name, attr->ns->prefix);
	    if ((attrDecl == NULL) && (doc->extSubset != NULL))
		attrDecl = xmlGetDtdQAttrDesc(doc->extSubset, elem->name,
					      attr->name, attr->ns->prefix);
	} else {
	    attrDecl = xmlGetDtdAttrDesc(doc->intSubset,
		                         elem->name, attr->name);
	    if ((attrDecl == NULL) && (doc->extSubset != NULL))
		attrDecl = xmlGetDtdAttrDesc(doc->extSubset,
					     elem->name, attr->name);
	}
    }


    /* Validity Constraint: Attribute Value Type */
    if (attrDecl == NULL) {
	xmlErrValidNode(ctxt, elem, XML_DTD_UNKNOWN_ATTRIBUTE,
	       "No declaration for attribute %s of element %s\n",
	       attr->name, elem->name, NULL);
	return(0);
    }
    attr->atype = attrDecl->atype;

    val = xmlValidateAttributeValueInternal(doc, attrDecl->atype, value);
    if (val == 0) {
	    xmlErrValidNode(ctxt, elem, XML_DTD_ATTRIBUTE_VALUE,
	   "Syntax of value for attribute %s of %s is not valid\n",
	       attr->name, elem->name, NULL);
        ret = 0;
    }

    /* Validity constraint: Fixed Attribute Default */
    if (attrDecl->def == XML_ATTRIBUTE_FIXED) {
	if (!xmlStrEqual(value, attrDecl->defaultValue)) {
	    xmlErrValidNode(ctxt, elem, XML_DTD_ATTRIBUTE_DEFAULT,
	   "Value for attribute %s of %s is different from default \"%s\"\n",
		   attr->name, elem->name, attrDecl->defaultValue);
	    ret = 0;
	}
    }

    /* Validity Constraint: ID uniqueness */
    if (attrDecl->atype == XML_ATTRIBUTE_ID) {
        if (xmlAddID(ctxt, doc, value, attr) == NULL)
	    ret = 0;
    }

    if ((attrDecl->atype == XML_ATTRIBUTE_IDREF) ||
	(attrDecl->atype == XML_ATTRIBUTE_IDREFS)) {
        if (xmlAddRef(ctxt, doc, value, attr) == NULL)
	    ret = 0;
    }

    /* Validity Constraint: Notation Attributes */
    if (attrDecl->atype == XML_ATTRIBUTE_NOTATION) {
        xmlEnumerationPtr tree = attrDecl->tree;
        xmlNotationPtr nota;

        /* First check that the given NOTATION was declared */
	nota = xmlGetDtdNotationDesc(doc->intSubset, value);
	if (nota == NULL)
	    nota = xmlGetDtdNotationDesc(doc->extSubset, value);

	if (nota == NULL) {
	    xmlErrValidNode(ctxt, elem, XML_DTD_UNKNOWN_NOTATION,
       "Value \"%s\" for attribute %s of %s is not a declared Notation\n",
		   value, attr->name, elem->name);
	    ret = 0;
        }

	/* Second, verify that it's among the list */
	while (tree != NULL) {
	    if (xmlStrEqual(tree->name, value)) break;
	    tree = tree->next;
	}
	if (tree == NULL) {
	    xmlErrValidNode(ctxt, elem, XML_DTD_NOTATION_VALUE,
"Value \"%s\" for attribute %s of %s is not among the enumerated notations\n",
		   value, attr->name, elem->name);
	    ret = 0;
	}
    }

    /* Validity Constraint: Enumeration */
    if (attrDecl->atype == XML_ATTRIBUTE_ENUMERATION) {
        xmlEnumerationPtr tree = attrDecl->tree;
	while (tree != NULL) {
	    if (xmlStrEqual(tree->name, value)) break;
	    tree = tree->next;
	}
	if (tree == NULL) {
	    xmlErrValidNode(ctxt, elem, XML_DTD_ATTRIBUTE_VALUE,
       "Value \"%s\" for attribute %s of %s is not among the enumerated set\n",
		   value, attr->name, elem->name);
	    ret = 0;
	}
    }

    /* Fixed Attribute Default */
    if ((attrDecl->def == XML_ATTRIBUTE_FIXED) &&
        (!xmlStrEqual(attrDecl->defaultValue, value))) {
	xmlErrValidNode(ctxt, elem, XML_DTD_ATTRIBUTE_VALUE,
	   "Value for attribute %s of %s must be \"%s\"\n",
	       attr->name, elem->name, attrDecl->defaultValue);
        ret = 0;
    }

    /* Extra check for the attribute value */
    ret &= xmlValidateAttributeValue2(ctxt, doc, attr->name,
				      attrDecl->atype, value);

    return(ret);
}

/**
 * xmlValidateOneNamespace:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element instance
 * @prefix:  the namespace prefix
 * @ns:  an namespace declaration instance
 * @value:  the attribute value (without entities processing)
 *
 * Try to validate a single namespace declaration for an element
 * basically it does the following checks as described by the
 * XML-1.0 recommendation:
 *  - [ VC: Attribute Value Type ]
 *  - [ VC: Fixed Attribute Default ]
 *  - [ VC: Entity Name ]
 *  - [ VC: Name Token ]
 *  - [ VC: ID ]
 *  - [ VC: IDREF ]
 *  - [ VC: Entity Name ]
 *  - [ VC: Notation Attributes ]
 *
 * The ID/IDREF uniqueness and matching are done separately
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateOneNamespace(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
xmlNodePtr elem, const xmlChar *prefix, xmlNsPtr ns, const xmlChar *value) {
    /* xmlElementPtr elemDecl; */
    xmlAttributePtr attrDecl =  NULL;
    int val;
    int ret = 1;

    CHECK_DTD;
    if ((elem == NULL) || (elem->name == NULL)) return(0);
    if ((ns == NULL) || (ns->href == NULL)) return(0);

    if (prefix != NULL) {
	xmlChar fn[50];
	xmlChar *fullname;

	fullname = xmlBuildQName(elem->name, prefix, fn, 50);
	if (fullname == NULL) {
	    xmlVErrMemory(ctxt, "Validating namespace");
	    return(0);
	}
	if (ns->prefix != NULL) {
	    attrDecl = xmlGetDtdQAttrDesc(doc->intSubset, fullname,
		                          ns->prefix, BAD_CAST "xmlns");
	    if ((attrDecl == NULL) && (doc->extSubset != NULL))
		attrDecl = xmlGetDtdQAttrDesc(doc->extSubset, fullname,
					  ns->prefix, BAD_CAST "xmlns");
	} else {
	    attrDecl = xmlGetDtdAttrDesc(doc->intSubset, fullname,
		                         BAD_CAST "xmlns");
	    if ((attrDecl == NULL) && (doc->extSubset != NULL))
		attrDecl = xmlGetDtdAttrDesc(doc->extSubset, fullname,
			                 BAD_CAST "xmlns");
	}
	if ((fullname != fn) && (fullname != elem->name))
	    xmlFree(fullname);
    }
    if (attrDecl == NULL) {
	if (ns->prefix != NULL) {
	    attrDecl = xmlGetDtdQAttrDesc(doc->intSubset, elem->name,
		                          ns->prefix, BAD_CAST "xmlns");
	    if ((attrDecl == NULL) && (doc->extSubset != NULL))
		attrDecl = xmlGetDtdQAttrDesc(doc->extSubset, elem->name,
					      ns->prefix, BAD_CAST "xmlns");
	} else {
	    attrDecl = xmlGetDtdAttrDesc(doc->intSubset,
		                         elem->name, BAD_CAST "xmlns");
	    if ((attrDecl == NULL) && (doc->extSubset != NULL))
		attrDecl = xmlGetDtdAttrDesc(doc->extSubset,
					     elem->name, BAD_CAST "xmlns");
	}
    }


    /* Validity Constraint: Attribute Value Type */
    if (attrDecl == NULL) {
	if (ns->prefix != NULL) {
	    xmlErrValidNode(ctxt, elem, XML_DTD_UNKNOWN_ATTRIBUTE,
		   "No declaration for attribute xmlns:%s of element %s\n",
		   ns->prefix, elem->name, NULL);
	} else {
	    xmlErrValidNode(ctxt, elem, XML_DTD_UNKNOWN_ATTRIBUTE,
		   "No declaration for attribute xmlns of element %s\n",
		   elem->name, NULL, NULL);
	}
	return(0);
    }

    val = xmlValidateAttributeValueInternal(doc, attrDecl->atype, value);
    if (val == 0) {
	if (ns->prefix != NULL) {
	    xmlErrValidNode(ctxt, elem, XML_DTD_INVALID_DEFAULT,
	       "Syntax of value for attribute xmlns:%s of %s is not valid\n",
		   ns->prefix, elem->name, NULL);
	} else {
	    xmlErrValidNode(ctxt, elem, XML_DTD_INVALID_DEFAULT,
	       "Syntax of value for attribute xmlns of %s is not valid\n",
		   elem->name, NULL, NULL);
	}
        ret = 0;
    }

    /* Validity constraint: Fixed Attribute Default */
    if (attrDecl->def == XML_ATTRIBUTE_FIXED) {
	if (!xmlStrEqual(value, attrDecl->defaultValue)) {
	    if (ns->prefix != NULL) {
		xmlErrValidNode(ctxt, elem, XML_DTD_ATTRIBUTE_DEFAULT,
       "Value for attribute xmlns:%s of %s is different from default \"%s\"\n",
		       ns->prefix, elem->name, attrDecl->defaultValue);
	    } else {
		xmlErrValidNode(ctxt, elem, XML_DTD_ATTRIBUTE_DEFAULT,
       "Value for attribute xmlns of %s is different from default \"%s\"\n",
		       elem->name, attrDecl->defaultValue, NULL);
	    }
	    ret = 0;
	}
    }

    /* Validity Constraint: ID uniqueness */
    if (attrDecl->atype == XML_ATTRIBUTE_ID) {
        if (xmlAddID(ctxt, doc, value, (xmlAttrPtr) ns) == NULL)
	    ret = 0;
    }

    if ((attrDecl->atype == XML_ATTRIBUTE_IDREF) ||
	(attrDecl->atype == XML_ATTRIBUTE_IDREFS)) {
        if (xmlAddRef(ctxt, doc, value, (xmlAttrPtr) ns) == NULL)
	    ret = 0;
    }

    /* Validity Constraint: Notation Attributes */
    if (attrDecl->atype == XML_ATTRIBUTE_NOTATION) {
        xmlEnumerationPtr tree = attrDecl->tree;
        xmlNotationPtr nota;

        /* First check that the given NOTATION was declared */
	nota = xmlGetDtdNotationDesc(doc->intSubset, value);
	if (nota == NULL)
	    nota = xmlGetDtdNotationDesc(doc->extSubset, value);

	if (nota == NULL) {
	    if (ns->prefix != NULL) {
		xmlErrValidNode(ctxt, elem, XML_DTD_UNKNOWN_NOTATION,
       "Value \"%s\" for attribute xmlns:%s of %s is not a declared Notation\n",
		       value, ns->prefix, elem->name);
	    } else {
		xmlErrValidNode(ctxt, elem, XML_DTD_UNKNOWN_NOTATION,
       "Value \"%s\" for attribute xmlns of %s is not a declared Notation\n",
		       value, elem->name, NULL);
	    }
	    ret = 0;
        }

	/* Second, verify that it's among the list */
	while (tree != NULL) {
	    if (xmlStrEqual(tree->name, value)) break;
	    tree = tree->next;
	}
	if (tree == NULL) {
	    if (ns->prefix != NULL) {
		xmlErrValidNode(ctxt, elem, XML_DTD_NOTATION_VALUE,
"Value \"%s\" for attribute xmlns:%s of %s is not among the enumerated notations\n",
		       value, ns->prefix, elem->name);
	    } else {
		xmlErrValidNode(ctxt, elem, XML_DTD_NOTATION_VALUE,
"Value \"%s\" for attribute xmlns of %s is not among the enumerated notations\n",
		       value, elem->name, NULL);
	    }
	    ret = 0;
	}
    }

    /* Validity Constraint: Enumeration */
    if (attrDecl->atype == XML_ATTRIBUTE_ENUMERATION) {
        xmlEnumerationPtr tree = attrDecl->tree;
	while (tree != NULL) {
	    if (xmlStrEqual(tree->name, value)) break;
	    tree = tree->next;
	}
	if (tree == NULL) {
	    if (ns->prefix != NULL) {
		xmlErrValidNode(ctxt, elem, XML_DTD_ATTRIBUTE_VALUE,
"Value \"%s\" for attribute xmlns:%s of %s is not among the enumerated set\n",
		       value, ns->prefix, elem->name);
	    } else {
		xmlErrValidNode(ctxt, elem, XML_DTD_ATTRIBUTE_VALUE,
"Value \"%s\" for attribute xmlns of %s is not among the enumerated set\n",
		       value, elem->name, NULL);
	    }
	    ret = 0;
	}
    }

    /* Fixed Attribute Default */
    if ((attrDecl->def == XML_ATTRIBUTE_FIXED) &&
        (!xmlStrEqual(attrDecl->defaultValue, value))) {
	if (ns->prefix != NULL) {
	    xmlErrValidNode(ctxt, elem, XML_DTD_ELEM_NAMESPACE,
		   "Value for attribute xmlns:%s of %s must be \"%s\"\n",
		   ns->prefix, elem->name, attrDecl->defaultValue);
	} else {
	    xmlErrValidNode(ctxt, elem, XML_DTD_ELEM_NAMESPACE,
		   "Value for attribute xmlns of %s must be \"%s\"\n",
		   elem->name, attrDecl->defaultValue, NULL);
	}
        ret = 0;
    }

    /* Extra check for the attribute value */
    if (ns->prefix != NULL) {
	ret &= xmlValidateAttributeValue2(ctxt, doc, ns->prefix,
					  attrDecl->atype, value);
    } else {
	ret &= xmlValidateAttributeValue2(ctxt, doc, BAD_CAST "xmlns",
					  attrDecl->atype, value);
    }

    return(ret);
}

#ifndef  LIBXML_REGEXP_ENABLED
/**
 * xmlValidateSkipIgnorable:
 * @ctxt:  the validation context
 * @child:  the child list
 *
 * Skip ignorable elements w.r.t. the validation process
 *
 * returns the first element to consider for validation of the content model
 */

static xmlNodePtr
xmlValidateSkipIgnorable(xmlNodePtr child) {
    while (child != NULL) {
	switch (child->type) {
	    /* These things are ignored (skipped) during validation.  */
	    case XML_PI_NODE:
	    case XML_COMMENT_NODE:
	    case XML_XINCLUDE_START:
	    case XML_XINCLUDE_END:
		child = child->next;
		break;
	    case XML_TEXT_NODE:
		if (xmlIsBlankNode(child))
		    child = child->next;
		else
		    return(child);
		break;
	    /* keep current node */
	    default:
		return(child);
	}
    }
    return(child);
}

/**
 * xmlValidateElementType:
 * @ctxt:  the validation context
 *
 * Try to validate the content model of an element internal function
 *
 * returns 1 if valid or 0 ,-1 in case of error, -2 if an entity
 *           reference is found and -3 if the validation succeeded but
 *           the content model is not determinist.
 */

static int
xmlValidateElementType(xmlValidCtxtPtr ctxt) {
    int ret = -1;
    int determinist = 1;

    NODE = xmlValidateSkipIgnorable(NODE);
    if ((NODE == NULL) && (CONT == NULL))
	return(1);
    if ((NODE == NULL) &&
	((CONT->ocur == XML_ELEMENT_CONTENT_MULT) ||
	 (CONT->ocur == XML_ELEMENT_CONTENT_OPT))) {
	return(1);
    }
    if (CONT == NULL) return(-1);
    if ((NODE != NULL) && (NODE->type == XML_ENTITY_REF_NODE))
	return(-2);

    /*
     * We arrive here when more states need to be examined
     */
cont:

    /*
     * We just recovered from a rollback generated by a possible
     * epsilon transition, go directly to the analysis phase
     */
    if (STATE == ROLLBACK_PARENT) {
	DEBUG_VALID_MSG("restored parent branch");
	DEBUG_VALID_STATE(NODE, CONT)
	ret = 1;
	goto analyze;
    }

    DEBUG_VALID_STATE(NODE, CONT)
    /*
     * we may have to save a backup state here. This is the equivalent
     * of handling epsilon transition in NFAs.
     */
    if ((CONT != NULL) &&
	((CONT->parent == NULL) ||
	 (CONT->parent->type != XML_ELEMENT_CONTENT_OR)) &&
	((CONT->ocur == XML_ELEMENT_CONTENT_MULT) ||
	 (CONT->ocur == XML_ELEMENT_CONTENT_OPT) ||
	 ((CONT->ocur == XML_ELEMENT_CONTENT_PLUS) && (OCCURRENCE)))) {
	DEBUG_VALID_MSG("saving parent branch");
	if (vstateVPush(ctxt, CONT, NODE, DEPTH, OCCURS, ROLLBACK_PARENT) < 0)
	    return(0);
    }


    /*
     * Check first if the content matches
     */
    switch (CONT->type) {
	case XML_ELEMENT_CONTENT_PCDATA:
	    if (NODE == NULL) {
		DEBUG_VALID_MSG("pcdata failed no node");
		ret = 0;
		break;
	    }
	    if (NODE->type == XML_TEXT_NODE) {
		DEBUG_VALID_MSG("pcdata found, skip to next");
		/*
		 * go to next element in the content model
		 * skipping ignorable elems
		 */
		do {
		    NODE = NODE->next;
		    NODE = xmlValidateSkipIgnorable(NODE);
		    if ((NODE != NULL) &&
			(NODE->type == XML_ENTITY_REF_NODE))
			return(-2);
		} while ((NODE != NULL) &&
			 ((NODE->type != XML_ELEMENT_NODE) &&
			  (NODE->type != XML_TEXT_NODE) &&
			  (NODE->type != XML_CDATA_SECTION_NODE)));
                ret = 1;
		break;
	    } else {
		DEBUG_VALID_MSG("pcdata failed");
		ret = 0;
		break;
	    }
	    break;
	case XML_ELEMENT_CONTENT_ELEMENT:
	    if (NODE == NULL) {
		DEBUG_VALID_MSG("element failed no node");
		ret = 0;
		break;
	    }
	    ret = ((NODE->type == XML_ELEMENT_NODE) &&
		   (xmlStrEqual(NODE->name, CONT->name)));
	    if (ret == 1) {
		if ((NODE->ns == NULL) || (NODE->ns->prefix == NULL)) {
		    ret = (CONT->prefix == NULL);
		} else if (CONT->prefix == NULL) {
		    ret = 0;
		} else {
		    ret = xmlStrEqual(NODE->ns->prefix, CONT->prefix);
		}
	    }
	    if (ret == 1) {
		DEBUG_VALID_MSG("element found, skip to next");
		/*
		 * go to next element in the content model
		 * skipping ignorable elems
		 */
		do {
		    NODE = NODE->next;
		    NODE = xmlValidateSkipIgnorable(NODE);
		    if ((NODE != NULL) &&
			(NODE->type == XML_ENTITY_REF_NODE))
			return(-2);
		} while ((NODE != NULL) &&
			 ((NODE->type != XML_ELEMENT_NODE) &&
			  (NODE->type != XML_TEXT_NODE) &&
			  (NODE->type != XML_CDATA_SECTION_NODE)));
	    } else {
		DEBUG_VALID_MSG("element failed");
		ret = 0;
		break;
	    }
	    break;
	case XML_ELEMENT_CONTENT_OR:
	    /*
	     * Small optimization.
	     */
	    if (CONT->c1->type == XML_ELEMENT_CONTENT_ELEMENT) {
		if ((NODE == NULL) ||
		    (!xmlStrEqual(NODE->name, CONT->c1->name))) {
		    DEPTH++;
		    CONT = CONT->c2;
		    goto cont;
		}
		if ((NODE->ns == NULL) || (NODE->ns->prefix == NULL)) {
		    ret = (CONT->c1->prefix == NULL);
		} else if (CONT->c1->prefix == NULL) {
		    ret = 0;
		} else {
		    ret = xmlStrEqual(NODE->ns->prefix, CONT->c1->prefix);
		}
		if (ret == 0) {
		    DEPTH++;
		    CONT = CONT->c2;
		    goto cont;
		}
	    }

	    /*
	     * save the second branch 'or' branch
	     */
	    DEBUG_VALID_MSG("saving 'or' branch");
	    if (vstateVPush(ctxt, CONT->c2, NODE, (unsigned char)(DEPTH + 1),
			    OCCURS, ROLLBACK_OR) < 0)
		return(-1);
	    DEPTH++;
	    CONT = CONT->c1;
	    goto cont;
	case XML_ELEMENT_CONTENT_SEQ:
	    /*
	     * Small optimization.
	     */
	    if ((CONT->c1->type == XML_ELEMENT_CONTENT_ELEMENT) &&
		((CONT->c1->ocur == XML_ELEMENT_CONTENT_OPT) ||
		 (CONT->c1->ocur == XML_ELEMENT_CONTENT_MULT))) {
		if ((NODE == NULL) ||
		    (!xmlStrEqual(NODE->name, CONT->c1->name))) {
		    DEPTH++;
		    CONT = CONT->c2;
		    goto cont;
		}
		if ((NODE->ns == NULL) || (NODE->ns->prefix == NULL)) {
		    ret = (CONT->c1->prefix == NULL);
		} else if (CONT->c1->prefix == NULL) {
		    ret = 0;
		} else {
		    ret = xmlStrEqual(NODE->ns->prefix, CONT->c1->prefix);
		}
		if (ret == 0) {
		    DEPTH++;
		    CONT = CONT->c2;
		    goto cont;
		}
	    }
	    DEPTH++;
	    CONT = CONT->c1;
	    goto cont;
    }

    /*
     * At this point handle going up in the tree
     */
    if (ret == -1) {
	DEBUG_VALID_MSG("error found returning");
	return(ret);
    }
analyze:
    while (CONT != NULL) {
	/*
	 * First do the analysis depending on the occurrence model at
	 * this level.
	 */
	if (ret == 0) {
	    switch (CONT->ocur) {
		xmlNodePtr cur;

		case XML_ELEMENT_CONTENT_ONCE:
		    cur = ctxt->vstate->node;
		    DEBUG_VALID_MSG("Once branch failed, rollback");
		    if (vstateVPop(ctxt) < 0 ) {
			DEBUG_VALID_MSG("exhaustion, failed");
			return(0);
		    }
		    if (cur != ctxt->vstate->node)
			determinist = -3;
		    goto cont;
		case XML_ELEMENT_CONTENT_PLUS:
		    if (OCCURRENCE == 0) {
			cur = ctxt->vstate->node;
			DEBUG_VALID_MSG("Plus branch failed, rollback");
			if (vstateVPop(ctxt) < 0 ) {
			    DEBUG_VALID_MSG("exhaustion, failed");
			    return(0);
			}
			if (cur != ctxt->vstate->node)
			    determinist = -3;
			goto cont;
		    }
		    DEBUG_VALID_MSG("Plus branch found");
		    ret = 1;
		    break;
		case XML_ELEMENT_CONTENT_MULT:
#ifdef DEBUG_VALID_ALGO
		    if (OCCURRENCE == 0) {
			DEBUG_VALID_MSG("Mult branch failed");
		    } else {
			DEBUG_VALID_MSG("Mult branch found");
		    }
#endif
		    ret = 1;
		    break;
		case XML_ELEMENT_CONTENT_OPT:
		    DEBUG_VALID_MSG("Option branch failed");
		    ret = 1;
		    break;
	    }
	} else {
	    switch (CONT->ocur) {
		case XML_ELEMENT_CONTENT_OPT:
		    DEBUG_VALID_MSG("Option branch succeeded");
		    ret = 1;
		    break;
		case XML_ELEMENT_CONTENT_ONCE:
		    DEBUG_VALID_MSG("Once branch succeeded");
		    ret = 1;
		    break;
		case XML_ELEMENT_CONTENT_PLUS:
		    if (STATE == ROLLBACK_PARENT) {
			DEBUG_VALID_MSG("Plus branch rollback");
			ret = 1;
			break;
		    }
		    if (NODE == NULL) {
			DEBUG_VALID_MSG("Plus branch exhausted");
			ret = 1;
			break;
		    }
		    DEBUG_VALID_MSG("Plus branch succeeded, continuing");
		    SET_OCCURRENCE;
		    goto cont;
		case XML_ELEMENT_CONTENT_MULT:
		    if (STATE == ROLLBACK_PARENT) {
			DEBUG_VALID_MSG("Mult branch rollback");
			ret = 1;
			break;
		    }
		    if (NODE == NULL) {
			DEBUG_VALID_MSG("Mult branch exhausted");
			ret = 1;
			break;
		    }
		    DEBUG_VALID_MSG("Mult branch succeeded, continuing");
		    /* SET_OCCURRENCE; */
		    goto cont;
	    }
	}
	STATE = 0;

	/*
	 * Then act accordingly at the parent level
	 */
	RESET_OCCURRENCE;
	if (CONT->parent == NULL)
	    break;

	switch (CONT->parent->type) {
	    case XML_ELEMENT_CONTENT_PCDATA:
		DEBUG_VALID_MSG("Error: parent pcdata");
		return(-1);
	    case XML_ELEMENT_CONTENT_ELEMENT:
		DEBUG_VALID_MSG("Error: parent element");
		return(-1);
	    case XML_ELEMENT_CONTENT_OR:
		if (ret == 1) {
		    DEBUG_VALID_MSG("Or succeeded");
		    CONT = CONT->parent;
		    DEPTH--;
		} else {
		    DEBUG_VALID_MSG("Or failed");
		    CONT = CONT->parent;
		    DEPTH--;
		}
		break;
	    case XML_ELEMENT_CONTENT_SEQ:
		if (ret == 0) {
		    DEBUG_VALID_MSG("Sequence failed");
		    CONT = CONT->parent;
		    DEPTH--;
		} else if (CONT == CONT->parent->c1) {
		    DEBUG_VALID_MSG("Sequence testing 2nd branch");
		    CONT = CONT->parent->c2;
		    goto cont;
		} else {
		    DEBUG_VALID_MSG("Sequence succeeded");
		    CONT = CONT->parent;
		    DEPTH--;
		}
	}
    }
    if (NODE != NULL) {
	xmlNodePtr cur;

	cur = ctxt->vstate->node;
	DEBUG_VALID_MSG("Failed, remaining input, rollback");
	if (vstateVPop(ctxt) < 0 ) {
	    DEBUG_VALID_MSG("exhaustion, failed");
	    return(0);
	}
	if (cur != ctxt->vstate->node)
	    determinist = -3;
	goto cont;
    }
    if (ret == 0) {
	xmlNodePtr cur;

	cur = ctxt->vstate->node;
	DEBUG_VALID_MSG("Failure, rollback");
	if (vstateVPop(ctxt) < 0 ) {
	    DEBUG_VALID_MSG("exhaustion, failed");
	    return(0);
	}
	if (cur != ctxt->vstate->node)
	    determinist = -3;
	goto cont;
    }
    return(determinist);
}
#endif

/**
 * xmlSnprintfElements:
 * @buf:  an output buffer
 * @size:  the size of the buffer
 * @content:  An element
 * @glob: 1 if one must print the englobing parenthesis, 0 otherwise
 *
 * This will dump the list of elements to the buffer
 * Intended just for the debug routine
 */
static void
xmlSnprintfElements(char *buf, int size, xmlNodePtr node, int glob) {
    xmlNodePtr cur;
    int len;

    if (node == NULL) return;
    if (glob) strcat(buf, "(");
    cur = node;
    while (cur != NULL) {
	len = strlen(buf);
	if (size - len < 50) {
	    if ((size - len > 4) && (buf[len - 1] != '.'))
		strcat(buf, " ...");
	    return;
	}
        switch (cur->type) {
            case XML_ELEMENT_NODE:
		if ((cur->ns != NULL) && (cur->ns->prefix != NULL)) {
		    if (size - len < xmlStrlen(cur->ns->prefix) + 10) {
			if ((size - len > 4) && (buf[len - 1] != '.'))
			    strcat(buf, " ...");
			return;
		    }
		    strcat(buf, (char *) cur->ns->prefix);
		    strcat(buf, ":");
		}
                if (size - len < xmlStrlen(cur->name) + 10) {
		    if ((size - len > 4) && (buf[len - 1] != '.'))
			strcat(buf, " ...");
		    return;
		}
	        strcat(buf, (char *) cur->name);
		if (cur->next != NULL)
		    strcat(buf, " ");
		break;
            case XML_TEXT_NODE:
		if (xmlIsBlankNode(cur))
		    break;
            case XML_CDATA_SECTION_NODE:
            case XML_ENTITY_REF_NODE:
	        strcat(buf, "CDATA");
		if (cur->next != NULL)
		    strcat(buf, " ");
		break;
            case XML_ATTRIBUTE_NODE:
            case XML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
	    case XML_DOCB_DOCUMENT_NODE:
#endif
	    case XML_HTML_DOCUMENT_NODE:
            case XML_DOCUMENT_TYPE_NODE:
            case XML_DOCUMENT_FRAG_NODE:
            case XML_NOTATION_NODE:
	    case XML_NAMESPACE_DECL:
	        strcat(buf, "???");
		if (cur->next != NULL)
		    strcat(buf, " ");
		break;
            case XML_ENTITY_NODE:
            case XML_PI_NODE:
            case XML_DTD_NODE:
            case XML_COMMENT_NODE:
	    case XML_ELEMENT_DECL:
	    case XML_ATTRIBUTE_DECL:
	    case XML_ENTITY_DECL:
	    case XML_XINCLUDE_START:
	    case XML_XINCLUDE_END:
		break;
	}
	cur = cur->next;
    }
    if (glob) strcat(buf, ")");
}

/**
 * xmlValidateElementContent:
 * @ctxt:  the validation context
 * @child:  the child list
 * @elemDecl:  pointer to the element declaration
 * @warn:  emit the error message
 * @parent: the parent element (for error reporting)
 *
 * Try to validate the content model of an element
 *
 * returns 1 if valid or 0 if not and -1 in case of error
 */

static int
xmlValidateElementContent(xmlValidCtxtPtr ctxt, xmlNodePtr child,
       xmlElementPtr elemDecl, int warn, xmlNodePtr parent) {
    int ret = 1;
#ifndef  LIBXML_REGEXP_ENABLED
    xmlNodePtr repl = NULL, last = NULL, tmp;
#endif
    xmlNodePtr cur;
    xmlElementContentPtr cont;
    const xmlChar *name;

    if ((elemDecl == NULL) || (parent == NULL) || (ctxt == NULL))
	return(-1);
    cont = elemDecl->content;
    name = elemDecl->name;

#ifdef LIBXML_REGEXP_ENABLED
    /* Build the regexp associated to the content model */
    if (elemDecl->contModel == NULL)
	ret = xmlValidBuildContentModel(ctxt, elemDecl);
    if (elemDecl->contModel == NULL) {
	return(-1);
    } else {
	xmlRegExecCtxtPtr exec;

	if (!xmlRegexpIsDeterminist(elemDecl->contModel)) {
	    return(-1);
	}
	ctxt->nodeMax = 0;
	ctxt->nodeNr = 0;
	ctxt->nodeTab = NULL;
	exec = xmlRegNewExecCtxt(elemDecl->contModel, NULL, NULL);
	if (exec != NULL) {
	    cur = child;
	    while (cur != NULL) {
		switch (cur->type) {
		    case XML_ENTITY_REF_NODE:
			/*
			 * Push the current node to be able to roll back
			 * and process within the entity
			 */
			if ((cur->children != NULL) &&
			    (cur->children->children != NULL)) {
			    nodeVPush(ctxt, cur);
			    cur = cur->children->children;
			    continue;
			}
			break;
		    case XML_TEXT_NODE:
			if (xmlIsBlankNode(cur))
			    break;
			ret = 0;
			goto fail;
		    case XML_CDATA_SECTION_NODE:
			/* TODO */
			ret = 0;
			goto fail;
		    case XML_ELEMENT_NODE:
			if ((cur->ns != NULL) && (cur->ns->prefix != NULL)) {
			    xmlChar fn[50];
			    xmlChar *fullname;

			    fullname = xmlBuildQName(cur->name,
				                     cur->ns->prefix, fn, 50);
			    if (fullname == NULL) {
				ret = -1;
				goto fail;
			    }
                            ret = xmlRegExecPushString(exec, fullname, NULL);
			    if ((fullname != fn) && (fullname != cur->name))
				xmlFree(fullname);
			} else {
			    ret = xmlRegExecPushString(exec, cur->name, NULL);
			}
			break;
		    default:
			break;
		}
		/*
		 * Switch to next element
		 */
		cur = cur->next;
		while (cur == NULL) {
		    cur = nodeVPop(ctxt);
		    if (cur == NULL)
			break;
		    cur = cur->next;
		}
	    }
	    ret = xmlRegExecPushString(exec, NULL, NULL);
fail:
	    xmlRegFreeExecCtxt(exec);
	}
    }
#else  /* LIBXML_REGEXP_ENABLED */
    /*
     * Allocate the stack
     */
    ctxt->vstateMax = 8;
    ctxt->vstateTab = (xmlValidState *) xmlMalloc(
		 ctxt->vstateMax * sizeof(ctxt->vstateTab[0]));
    if (ctxt->vstateTab == NULL) {
	xmlVErrMemory(ctxt, "malloc failed");
	return(-1);
    }
    /*
     * The first entry in the stack is reserved to the current state
     */
    ctxt->nodeMax = 0;
    ctxt->nodeNr = 0;
    ctxt->nodeTab = NULL;
    ctxt->vstate = &ctxt->vstateTab[0];
    ctxt->vstateNr = 1;
    CONT = cont;
    NODE = child;
    DEPTH = 0;
    OCCURS = 0;
    STATE = 0;
    ret = xmlValidateElementType(ctxt);
    if ((ret == -3) && (warn)) {
	xmlErrValidWarning(ctxt, child, XML_DTD_CONTENT_NOT_DETERMINIST,
	       "Content model for Element %s is ambiguous\n",
	                   name, NULL, NULL);
    } else if (ret == -2) {
	/*
	 * An entities reference appeared at this level.
	 * Buid a minimal representation of this node content
	 * sufficient to run the validation process on it
	 */
	DEBUG_VALID_MSG("Found an entity reference, linearizing");
	cur = child;
	while (cur != NULL) {
	    switch (cur->type) {
		case XML_ENTITY_REF_NODE:
		    /*
		     * Push the current node to be able to roll back
		     * and process within the entity
		     */
		    if ((cur->children != NULL) &&
			(cur->children->children != NULL)) {
			nodeVPush(ctxt, cur);
			cur = cur->children->children;
			continue;
		    }
		    break;
		case XML_TEXT_NODE:
		    if (xmlIsBlankNode(cur))
			break;
		    /* no break on purpose */
		case XML_CDATA_SECTION_NODE:
		    /* no break on purpose */
		case XML_ELEMENT_NODE:
		    /*
		     * Allocate a new node and minimally fills in
		     * what's required
		     */
		    tmp = (xmlNodePtr) xmlMalloc(sizeof(xmlNode));
		    if (tmp == NULL) {
			xmlVErrMemory(ctxt, "malloc failed");
			xmlFreeNodeList(repl);
			ret = -1;
			goto done;
		    }
		    tmp->type = cur->type;
		    tmp->name = cur->name;
		    tmp->ns = cur->ns;
		    tmp->next = NULL;
		    tmp->content = NULL;
		    if (repl == NULL)
			repl = last = tmp;
		    else {
			last->next = tmp;
			last = tmp;
		    }
		    if (cur->type == XML_CDATA_SECTION_NODE) {
			/*
			 * E59 spaces in CDATA does not match the
			 * nonterminal S
			 */
			tmp->content = xmlStrdup(BAD_CAST "CDATA");
		    }
		    break;
		default:
		    break;
	    }
	    /*
	     * Switch to next element
	     */
	    cur = cur->next;
	    while (cur == NULL) {
		cur = nodeVPop(ctxt);
		if (cur == NULL)
		    break;
		cur = cur->next;
	    }
	}

	/*
	 * Relaunch the validation
	 */
	ctxt->vstate = &ctxt->vstateTab[0];
	ctxt->vstateNr = 1;
	CONT = cont;
	NODE = repl;
	DEPTH = 0;
	OCCURS = 0;
	STATE = 0;
	ret = xmlValidateElementType(ctxt);
    }
#endif /* LIBXML_REGEXP_ENABLED */
    if ((warn) && ((ret != 1) && (ret != -3))) {
	if (ctxt != NULL) {
	    char expr[5000];
	    char list[5000];

	    expr[0] = 0;
	    xmlSnprintfElementContent(&expr[0], 5000, cont, 1);
	    list[0] = 0;
#ifndef LIBXML_REGEXP_ENABLED
	    if (repl != NULL)
		xmlSnprintfElements(&list[0], 5000, repl, 1);
	    else
#endif /* LIBXML_REGEXP_ENABLED */
		xmlSnprintfElements(&list[0], 5000, child, 1);

	    if (name != NULL) {
		xmlErrValidNode(ctxt, parent, XML_DTD_CONTENT_MODEL,
	   "Element %s content does not follow the DTD, expecting %s, got %s\n",
		       name, BAD_CAST expr, BAD_CAST list);
	    } else {
		xmlErrValidNode(ctxt, parent, XML_DTD_CONTENT_MODEL,
	   "Element content does not follow the DTD, expecting %s, got %s\n",
		       BAD_CAST expr, BAD_CAST list, NULL);
	    }
	} else {
	    if (name != NULL) {
		xmlErrValidNode(ctxt, parent, XML_DTD_CONTENT_MODEL,
		       "Element %s content does not follow the DTD\n",
		       name, NULL, NULL);
	    } else {
		xmlErrValidNode(ctxt, parent, XML_DTD_CONTENT_MODEL,
		       "Element content does not follow the DTD\n",
		                NULL, NULL, NULL);
	    }
	}
	ret = 0;
    }
    if (ret == -3)
	ret = 1;

#ifndef  LIBXML_REGEXP_ENABLED
done:
    /*
     * Deallocate the copy if done, and free up the validation stack
     */
    while (repl != NULL) {
	tmp = repl->next;
	xmlFree(repl);
	repl = tmp;
    }
    ctxt->vstateMax = 0;
    if (ctxt->vstateTab != NULL) {
	xmlFree(ctxt->vstateTab);
	ctxt->vstateTab = NULL;
    }
#endif
    ctxt->nodeMax = 0;
    ctxt->nodeNr = 0;
    if (ctxt->nodeTab != NULL) {
	xmlFree(ctxt->nodeTab);
	ctxt->nodeTab = NULL;
    }
    return(ret);

}

/**
 * xmlValidateCdataElement:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element instance
 *
 * Check that an element follows #CDATA
 *
 * returns 1 if valid or 0 otherwise
 */
static int
xmlValidateOneCdataElement(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
                           xmlNodePtr elem) {
    int ret = 1;
    xmlNodePtr cur, child;

    if ((ctxt == NULL) || (doc == NULL) || (elem == NULL) ||
        (elem->type != XML_ELEMENT_NODE))
	return(0);

    child = elem->children;

    cur = child;
    while (cur != NULL) {
	switch (cur->type) {
	    case XML_ENTITY_REF_NODE:
		/*
		 * Push the current node to be able to roll back
		 * and process within the entity
		 */
		if ((cur->children != NULL) &&
		    (cur->children->children != NULL)) {
		    nodeVPush(ctxt, cur);
		    cur = cur->children->children;
		    continue;
		}
		break;
	    case XML_COMMENT_NODE:
	    case XML_PI_NODE:
	    case XML_TEXT_NODE:
	    case XML_CDATA_SECTION_NODE:
		break;
	    default:
		ret = 0;
		goto done;
	}
	/*
	 * Switch to next element
	 */
	cur = cur->next;
	while (cur == NULL) {
	    cur = nodeVPop(ctxt);
	    if (cur == NULL)
		break;
	    cur = cur->next;
	}
    }
done:
    ctxt->nodeMax = 0;
    ctxt->nodeNr = 0;
    if (ctxt->nodeTab != NULL) {
	xmlFree(ctxt->nodeTab);
	ctxt->nodeTab = NULL;
    }
    return(ret);
}

/**
 * xmlValidateCheckMixed:
 * @ctxt:  the validation context
 * @cont:  the mixed content model
 * @qname:  the qualified name as appearing in the serialization
 *
 * Check if the given node is part of the content model.
 *
 * Returns 1 if yes, 0 if no, -1 in case of error
 */
static int
xmlValidateCheckMixed(xmlValidCtxtPtr ctxt,
	              xmlElementContentPtr cont, const xmlChar *qname) {
    const xmlChar *name;
    int plen;
    name = xmlSplitQName3(qname, &plen);

    if (name == NULL) {
	while (cont != NULL) {
	    if (cont->type == XML_ELEMENT_CONTENT_ELEMENT) {
		if ((cont->prefix == NULL) && (xmlStrEqual(cont->name, qname)))
		    return(1);
	    } else if ((cont->type == XML_ELEMENT_CONTENT_OR) &&
	       (cont->c1 != NULL) &&
	       (cont->c1->type == XML_ELEMENT_CONTENT_ELEMENT)){
		if ((cont->c1->prefix == NULL) &&
		    (xmlStrEqual(cont->c1->name, qname)))
		    return(1);
	    } else if ((cont->type != XML_ELEMENT_CONTENT_OR) ||
		(cont->c1 == NULL) ||
		(cont->c1->type != XML_ELEMENT_CONTENT_PCDATA)){
		xmlErrValid(NULL, XML_DTD_MIXED_CORRUPT,
			"Internal: MIXED struct corrupted\n",
			NULL);
		break;
	    }
	    cont = cont->c2;
	}
    } else {
	while (cont != NULL) {
	    if (cont->type == XML_ELEMENT_CONTENT_ELEMENT) {
		if ((cont->prefix != NULL) &&
		    (xmlStrncmp(cont->prefix, qname, plen) == 0) &&
		    (xmlStrEqual(cont->name, name)))
		    return(1);
	    } else if ((cont->type == XML_ELEMENT_CONTENT_OR) &&
	       (cont->c1 != NULL) &&
	       (cont->c1->type == XML_ELEMENT_CONTENT_ELEMENT)){
		if ((cont->c1->prefix != NULL) &&
		    (xmlStrncmp(cont->c1->prefix, qname, plen) == 0) &&
		    (xmlStrEqual(cont->c1->name, name)))
		    return(1);
	    } else if ((cont->type != XML_ELEMENT_CONTENT_OR) ||
		(cont->c1 == NULL) ||
		(cont->c1->type != XML_ELEMENT_CONTENT_PCDATA)){
		xmlErrValid(ctxt, XML_DTD_MIXED_CORRUPT,
			"Internal: MIXED struct corrupted\n",
			NULL);
		break;
	    }
	    cont = cont->c2;
	}
    }
    return(0);
}

/**
 * xmlValidGetElemDecl:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element instance
 * @extsubset:  pointer, (out) indicate if the declaration was found
 *              in the external subset.
 *
 * Finds a declaration associated to an element in the document.
 *
 * returns the pointer to the declaration or NULL if not found.
 */
static xmlElementPtr
xmlValidGetElemDecl(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
	            xmlNodePtr elem, int *extsubset) {
    xmlElementPtr elemDecl = NULL;
    const xmlChar *prefix = NULL;

    if ((ctxt == NULL) || (doc == NULL) ||
        (elem == NULL) || (elem->name == NULL))
        return(NULL);
    if (extsubset != NULL)
	*extsubset = 0;

    /*
     * Fetch the declaration for the qualified name
     */
    if ((elem->ns != NULL) && (elem->ns->prefix != NULL))
	prefix = elem->ns->prefix;

    if (prefix != NULL) {
	elemDecl = xmlGetDtdQElementDesc(doc->intSubset,
		                         elem->name, prefix);
	if ((elemDecl == NULL) && (doc->extSubset != NULL)) {
	    elemDecl = xmlGetDtdQElementDesc(doc->extSubset,
		                             elem->name, prefix);
	    if ((elemDecl != NULL) && (extsubset != NULL))
		*extsubset = 1;
	}
    }

    /*
     * Fetch the declaration for the non qualified name
     * This is "non-strict" validation should be done on the
     * full QName but in that case being flexible makes sense.
     */
    if (elemDecl == NULL) {
	elemDecl = xmlGetDtdElementDesc(doc->intSubset, elem->name);
	if ((elemDecl == NULL) && (doc->extSubset != NULL)) {
	    elemDecl = xmlGetDtdElementDesc(doc->extSubset, elem->name);
	    if ((elemDecl != NULL) && (extsubset != NULL))
		*extsubset = 1;
	}
    }
    if (elemDecl == NULL) {
	xmlErrValidNode(ctxt, elem,
			XML_DTD_UNKNOWN_ELEM,
	       "No declaration for element %s\n",
	       elem->name, NULL, NULL);
    }
    return(elemDecl);
}

#ifdef LIBXML_REGEXP_ENABLED
/**
 * xmlValidatePushElement:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element instance
 * @qname:  the qualified name as appearing in the serialization
 *
 * Push a new element start on the validation stack.
 *
 * returns 1 if no validation problem was found or 0 otherwise
 */
int
xmlValidatePushElement(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
                       xmlNodePtr elem, const xmlChar *qname) {
    int ret = 1;
    xmlElementPtr eDecl;
    int extsubset = 0;

    if (ctxt == NULL)
        return(0);
/* printf("PushElem %s\n", qname); */
    if ((ctxt->vstateNr > 0) && (ctxt->vstate != NULL)) {
	xmlValidStatePtr state = ctxt->vstate;
	xmlElementPtr elemDecl;

	/*
	 * Check the new element agaisnt the content model of the new elem.
	 */
	if (state->elemDecl != NULL) {
	    elemDecl = state->elemDecl;

	    switch(elemDecl->etype) {
		case XML_ELEMENT_TYPE_UNDEFINED:
		    ret = 0;
		    break;
		case XML_ELEMENT_TYPE_EMPTY:
		    xmlErrValidNode(ctxt, state->node,
				    XML_DTD_NOT_EMPTY,
	       "Element %s was declared EMPTY this one has content\n",
			   state->node->name, NULL, NULL);
		    ret = 0;
		    break;
		case XML_ELEMENT_TYPE_ANY:
		    /* I don't think anything is required then */
		    break;
		case XML_ELEMENT_TYPE_MIXED:
		    /* simple case of declared as #PCDATA */
		    if ((elemDecl->content != NULL) &&
			(elemDecl->content->type ==
			 XML_ELEMENT_CONTENT_PCDATA)) {
			xmlErrValidNode(ctxt, state->node,
					XML_DTD_NOT_PCDATA,
	       "Element %s was declared #PCDATA but contains non text nodes\n",
				state->node->name, NULL, NULL);
			ret = 0;
		    } else {
			ret = xmlValidateCheckMixed(ctxt, elemDecl->content,
				                    qname);
			if (ret != 1) {
			    xmlErrValidNode(ctxt, state->node,
					    XML_DTD_INVALID_CHILD,
	       "Element %s is not declared in %s list of possible children\n",
				    qname, state->node->name, NULL);
			}
		    }
		    break;
		case XML_ELEMENT_TYPE_ELEMENT:
		    /*
		     * TODO:
		     * VC: Standalone Document Declaration
		     *     - element types with element content, if white space
		     *       occurs directly within any instance of those types.
		     */
		    if (state->exec != NULL) {
			ret = xmlRegExecPushString(state->exec, qname, NULL);
			if (ret < 0) {
			    xmlErrValidNode(ctxt, state->node,
					    XML_DTD_CONTENT_MODEL,
	       "Element %s content does not follow the DTD, Misplaced %s\n",
				   state->node->name, qname, NULL);
			    ret = 0;
			} else {
			    ret = 1;
			}
		    }
		    break;
	    }
	}
    }
    eDecl = xmlValidGetElemDecl(ctxt, doc, elem, &extsubset);
    vstateVPush(ctxt, eDecl, elem);
    return(ret);
}

/**
 * xmlValidatePushCData:
 * @ctxt:  the validation context
 * @data:  some character data read
 * @len:  the length of the data
 *
 * check the CData parsed for validation in the current stack
 *
 * returns 1 if no validation problem was found or 0 otherwise
 */
int
xmlValidatePushCData(xmlValidCtxtPtr ctxt, const xmlChar *data, int len) {
    int ret = 1;

/* printf("CDATA %s %d\n", data, len); */
    if (ctxt == NULL)
        return(0);
    if (len <= 0)
	return(ret);
    if ((ctxt->vstateNr > 0) && (ctxt->vstate != NULL)) {
	xmlValidStatePtr state = ctxt->vstate;
	xmlElementPtr elemDecl;

	/*
	 * Check the new element agaisnt the content model of the new elem.
	 */
	if (state->elemDecl != NULL) {
	    elemDecl = state->elemDecl;

	    switch(elemDecl->etype) {
		case XML_ELEMENT_TYPE_UNDEFINED:
		    ret = 0;
		    break;
		case XML_ELEMENT_TYPE_EMPTY:
		    xmlErrValidNode(ctxt, state->node,
				    XML_DTD_NOT_EMPTY,
	       "Element %s was declared EMPTY this one has content\n",
			   state->node->name, NULL, NULL);
		    ret = 0;
		    break;
		case XML_ELEMENT_TYPE_ANY:
		    break;
		case XML_ELEMENT_TYPE_MIXED:
		    break;
		case XML_ELEMENT_TYPE_ELEMENT:
		    if (len > 0) {
			int i;

			for (i = 0;i < len;i++) {
			    if (!IS_BLANK_CH(data[i])) {
				xmlErrValidNode(ctxt, state->node,
						XML_DTD_CONTENT_MODEL,
	   "Element %s content does not follow the DTD, Text not allowed\n",
				       state->node->name, NULL, NULL);
				ret = 0;
				goto done;
			    }
			}
			/*
			 * TODO:
			 * VC: Standalone Document Declaration
			 *  element types with element content, if white space
			 *  occurs directly within any instance of those types.
			 */
		    }
		    break;
	    }
	}
    }
done:
    return(ret);
}

/**
 * xmlValidatePopElement:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element instance
 * @qname:  the qualified name as appearing in the serialization
 *
 * Pop the element end from the validation stack.
 *
 * returns 1 if no validation problem was found or 0 otherwise
 */
int
xmlValidatePopElement(xmlValidCtxtPtr ctxt, xmlDocPtr doc ATTRIBUTE_UNUSED,
                      xmlNodePtr elem ATTRIBUTE_UNUSED,
		      const xmlChar *qname ATTRIBUTE_UNUSED) {
    int ret = 1;

    if (ctxt == NULL)
        return(0);
/* printf("PopElem %s\n", qname); */
    if ((ctxt->vstateNr > 0) && (ctxt->vstate != NULL)) {
	xmlValidStatePtr state = ctxt->vstate;
	xmlElementPtr elemDecl;

	/*
	 * Check the new element agaisnt the content model of the new elem.
	 */
	if (state->elemDecl != NULL) {
	    elemDecl = state->elemDecl;

	    if (elemDecl->etype == XML_ELEMENT_TYPE_ELEMENT) {
		if (state->exec != NULL) {
		    ret = xmlRegExecPushString(state->exec, NULL, NULL);
		    if (ret == 0) {
			xmlErrValidNode(ctxt, state->node,
			                XML_DTD_CONTENT_MODEL,
	   "Element %s content does not follow the DTD, Expecting more child\n",
			       state->node->name, NULL,NULL);
		    } else {
			/*
			 * previous validation errors should not generate
			 * a new one here
			 */
			ret = 1;
		    }
		}
	    }
	}
	vstateVPop(ctxt);
    }
    return(ret);
}
#endif /* LIBXML_REGEXP_ENABLED */

/**
 * xmlValidateOneElement:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element instance
 *
 * Try to validate a single element and it's attributes,
 * basically it does the following checks as described by the
 * XML-1.0 recommendation:
 *  - [ VC: Element Valid ]
 *  - [ VC: Required Attribute ]
 * Then call xmlValidateOneAttribute() for each attribute present.
 *
 * The ID/IDREF checkings are done separately
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateOneElement(xmlValidCtxtPtr ctxt, xmlDocPtr doc,
                      xmlNodePtr elem) {
    xmlElementPtr elemDecl = NULL;
    xmlElementContentPtr cont;
    xmlAttributePtr attr;
    xmlNodePtr child;
    int ret = 1, tmp;
    const xmlChar *name;
    int extsubset = 0;

    CHECK_DTD;

    if (elem == NULL) return(0);
    switch (elem->type) {
        case XML_ATTRIBUTE_NODE:
	    xmlErrValidNode(ctxt, elem, XML_ERR_INTERNAL_ERROR,
		   "Attribute element not expected\n", NULL, NULL ,NULL);
	    return(0);
        case XML_TEXT_NODE:
	    if (elem->children != NULL) {
		xmlErrValidNode(ctxt, elem, XML_ERR_INTERNAL_ERROR,
		                "Text element has children !\n",
				NULL,NULL,NULL);
		return(0);
	    }
	    if (elem->ns != NULL) {
		xmlErrValidNode(ctxt, elem, XML_ERR_INTERNAL_ERROR,
		                "Text element has namespace !\n",
				NULL,NULL,NULL);
		return(0);
	    }
	    if (elem->content == NULL) {
		xmlErrValidNode(ctxt, elem, XML_ERR_INTERNAL_ERROR,
		                "Text element has no content !\n",
				NULL,NULL,NULL);
		return(0);
	    }
	    return(1);
        case XML_XINCLUDE_START:
        case XML_XINCLUDE_END:
            return(1);
        case XML_CDATA_SECTION_NODE:
        case XML_ENTITY_REF_NODE:
        case XML_PI_NODE:
        case XML_COMMENT_NODE:
	    return(1);
        case XML_ENTITY_NODE:
	    xmlErrValidNode(ctxt, elem, XML_ERR_INTERNAL_ERROR,
		   "Entity element not expected\n", NULL, NULL ,NULL);
	    return(0);
        case XML_NOTATION_NODE:
	    xmlErrValidNode(ctxt, elem, XML_ERR_INTERNAL_ERROR,
		   "Notation element not expected\n", NULL, NULL ,NULL);
	    return(0);
        case XML_DOCUMENT_NODE:
        case XML_DOCUMENT_TYPE_NODE:
        case XML_DOCUMENT_FRAG_NODE:
	    xmlErrValidNode(ctxt, elem, XML_ERR_INTERNAL_ERROR,
		   "Document element not expected\n", NULL, NULL ,NULL);
	    return(0);
        case XML_HTML_DOCUMENT_NODE:
	    xmlErrValidNode(ctxt, elem, XML_ERR_INTERNAL_ERROR,
		   "HTML Document not expected\n", NULL, NULL ,NULL);
	    return(0);
        case XML_ELEMENT_NODE:
	    break;
	default:
	    xmlErrValidNode(ctxt, elem, XML_ERR_INTERNAL_ERROR,
		   "unknown element type\n", NULL, NULL ,NULL);
	    return(0);
    }

    /*
     * Fetch the declaration
     */
    elemDecl = xmlValidGetElemDecl(ctxt, doc, elem, &extsubset);
    if (elemDecl == NULL)
	return(0);

    /*
     * If vstateNr is not zero that means continuous validation is
     * activated, do not try to check the content model at that level.
     */
    if (ctxt->vstateNr == 0) {
    /* Check that the element content matches the definition */
    switch (elemDecl->etype) {
        case XML_ELEMENT_TYPE_UNDEFINED:
	    xmlErrValidNode(ctxt, elem, XML_DTD_UNKNOWN_ELEM,
	                    "No declaration for element %s\n",
		   elem->name, NULL, NULL);
	    return(0);
        case XML_ELEMENT_TYPE_EMPTY:
	    if (elem->children != NULL) {
		xmlErrValidNode(ctxt, elem, XML_DTD_NOT_EMPTY,
	       "Element %s was declared EMPTY this one has content\n",
	               elem->name, NULL, NULL);
		ret = 0;
	    }
	    break;
        case XML_ELEMENT_TYPE_ANY:
	    /* I don't think anything is required then */
	    break;
        case XML_ELEMENT_TYPE_MIXED:

	    /* simple case of declared as #PCDATA */
	    if ((elemDecl->content != NULL) &&
		(elemDecl->content->type == XML_ELEMENT_CONTENT_PCDATA)) {
		ret = xmlValidateOneCdataElement(ctxt, doc, elem);
		if (!ret) {
		    xmlErrValidNode(ctxt, elem, XML_DTD_NOT_PCDATA,
	       "Element %s was declared #PCDATA but contains non text nodes\n",
			   elem->name, NULL, NULL);
		}
		break;
	    }
	    child = elem->children;
	    /* Hum, this start to get messy */
	    while (child != NULL) {
	        if (child->type == XML_ELEMENT_NODE) {
		    name = child->name;
		    if ((child->ns != NULL) && (child->ns->prefix != NULL)) {
			xmlChar fn[50];
			xmlChar *fullname;

			fullname = xmlBuildQName(child->name, child->ns->prefix,
				                 fn, 50);
			if (fullname == NULL)
			    return(0);
			cont = elemDecl->content;
			while (cont != NULL) {
			    if (cont->type == XML_ELEMENT_CONTENT_ELEMENT) {
				if (xmlStrEqual(cont->name, fullname))
				    break;
			    } else if ((cont->type == XML_ELEMENT_CONTENT_OR) &&
			       (cont->c1 != NULL) &&
			       (cont->c1->type == XML_ELEMENT_CONTENT_ELEMENT)){
				if (xmlStrEqual(cont->c1->name, fullname))
				    break;
			    } else if ((cont->type != XML_ELEMENT_CONTENT_OR) ||
				(cont->c1 == NULL) ||
				(cont->c1->type != XML_ELEMENT_CONTENT_PCDATA)){
				xmlErrValid(NULL, XML_DTD_MIXED_CORRUPT,
					"Internal: MIXED struct corrupted\n",
					NULL);
				break;
			    }
			    cont = cont->c2;
			}
			if ((fullname != fn) && (fullname != child->name))
			    xmlFree(fullname);
			if (cont != NULL)
			    goto child_ok;
		    }
		    cont = elemDecl->content;
		    while (cont != NULL) {
		        if (cont->type == XML_ELEMENT_CONTENT_ELEMENT) {
			    if (xmlStrEqual(cont->name, name)) break;
			} else if ((cont->type == XML_ELEMENT_CONTENT_OR) &&
			   (cont->c1 != NULL) &&
			   (cont->c1->type == XML_ELEMENT_CONTENT_ELEMENT)) {
			    if (xmlStrEqual(cont->c1->name, name)) break;
			} else if ((cont->type != XML_ELEMENT_CONTENT_OR) ||
			    (cont->c1 == NULL) ||
			    (cont->c1->type != XML_ELEMENT_CONTENT_PCDATA)) {
			    xmlErrValid(ctxt, XML_DTD_MIXED_CORRUPT,
				    "Internal: MIXED struct corrupted\n",
				    NULL);
			    break;
			}
			cont = cont->c2;
		    }
		    if (cont == NULL) {
			xmlErrValidNode(ctxt, elem, XML_DTD_INVALID_CHILD,
	       "Element %s is not declared in %s list of possible children\n",
			       name, elem->name, NULL);
			ret = 0;
		    }
		}
child_ok:
	        child = child->next;
	    }
	    break;
        case XML_ELEMENT_TYPE_ELEMENT:
	    if ((doc->standalone == 1) && (extsubset == 1)) {
		/*
		 * VC: Standalone Document Declaration
		 *     - element types with element content, if white space
		 *       occurs directly within any instance of those types.
		 */
		child = elem->children;
		while (child != NULL) {
		    if (child->type == XML_TEXT_NODE) {
			const xmlChar *content = child->content;

			while (IS_BLANK_CH(*content))
			    content++;
			if (*content == 0) {
			    xmlErrValidNode(ctxt, elem,
			                    XML_DTD_STANDALONE_WHITE_SPACE,
"standalone: %s declared in the external subset contains white spaces nodes\n",
				   elem->name, NULL, NULL);
			    ret = 0;
			    break;
			}
		    }
		    child =child->next;
		}
	    }
	    child = elem->children;
	    cont = elemDecl->content;
	    tmp = xmlValidateElementContent(ctxt, child, elemDecl, 1, elem);
	    if (tmp <= 0)
		ret = tmp;
	    break;
    }
    } /* not continuous */

    /* [ VC: Required Attribute ] */
    attr = elemDecl->attributes;
    while (attr != NULL) {
	if (attr->def == XML_ATTRIBUTE_REQUIRED) {
	    int qualified = -1;

	    if ((attr->prefix == NULL) &&
		(xmlStrEqual(attr->name, BAD_CAST "xmlns"))) {
		xmlNsPtr ns;

		ns = elem->nsDef;
		while (ns != NULL) {
		    if (ns->prefix == NULL)
			goto found;
		    ns = ns->next;
		}
	    } else if (xmlStrEqual(attr->prefix, BAD_CAST "xmlns")) {
		xmlNsPtr ns;

		ns = elem->nsDef;
		while (ns != NULL) {
		    if (xmlStrEqual(attr->name, ns->prefix))
			goto found;
		    ns = ns->next;
		}
	    } else {
		xmlAttrPtr attrib;

		attrib = elem->properties;
		while (attrib != NULL) {
		    if (xmlStrEqual(attrib->name, attr->name)) {
			if (attr->prefix != NULL) {
			    xmlNsPtr nameSpace = attrib->ns;

			    if (nameSpace == NULL)
				nameSpace = elem->ns;
			    /*
			     * qualified names handling is problematic, having a
			     * different prefix should be possible but DTDs don't
			     * allow to define the URI instead of the prefix :-(
			     */
			    if (nameSpace == NULL) {
				if (qualified < 0)
				    qualified = 0;
			    } else if (!xmlStrEqual(nameSpace->prefix,
						    attr->prefix)) {
				if (qualified < 1)
				    qualified = 1;
			    } else
				goto found;
			} else {
			    /*
			     * We should allow applications to define namespaces
			     * for their application even if the DTD doesn't
			     * carry one, otherwise, basically we would always
			     * break.
			     */
			    goto found;
			}
		    }
		    attrib = attrib->next;
		}
	    }
	    if (qualified == -1) {
		if (attr->prefix == NULL) {
		    xmlErrValidNode(ctxt, elem, XML_DTD_MISSING_ATTRIBUTE,
		       "Element %s does not carry attribute %s\n",
			   elem->name, attr->name, NULL);
		    ret = 0;
	        } else {
		    xmlErrValidNode(ctxt, elem, XML_DTD_MISSING_ATTRIBUTE,
		       "Element %s does not carry attribute %s:%s\n",
			   elem->name, attr->prefix,attr->name);
		    ret = 0;
		}
	    } else if (qualified == 0) {
		xmlErrValidWarning(ctxt, elem, XML_DTD_NO_PREFIX,
		   "Element %s required attribute %s:%s has no prefix\n",
		       elem->name, attr->prefix, attr->name);
	    } else if (qualified == 1) {
		xmlErrValidWarning(ctxt, elem, XML_DTD_DIFFERENT_PREFIX,
		   "Element %s required attribute %s:%s has different prefix\n",
		       elem->name, attr->prefix, attr->name);
	    }
	} else if (attr->def == XML_ATTRIBUTE_FIXED) {
	    /*
	     * Special tests checking #FIXED namespace declarations
	     * have the right value since this is not done as an
	     * attribute checking
	     */
	    if ((attr->prefix == NULL) &&
		(xmlStrEqual(attr->name, BAD_CAST "xmlns"))) {
		xmlNsPtr ns;

		ns = elem->nsDef;
		while (ns != NULL) {
		    if (ns->prefix == NULL) {
			if (!xmlStrEqual(attr->defaultValue, ns->href)) {
			    xmlErrValidNode(ctxt, elem,
			           XML_DTD_ELEM_DEFAULT_NAMESPACE,
   "Element %s namespace name for default namespace does not match the DTD\n",
				   elem->name, NULL, NULL);
			    ret = 0;
			}
			goto found;
		    }
		    ns = ns->next;
		}
	    } else if (xmlStrEqual(attr->prefix, BAD_CAST "xmlns")) {
		xmlNsPtr ns;

		ns = elem->nsDef;
		while (ns != NULL) {
		    if (xmlStrEqual(attr->name, ns->prefix)) {
			if (!xmlStrEqual(attr->defaultValue, ns->href)) {
			    xmlErrValidNode(ctxt, elem, XML_DTD_ELEM_NAMESPACE,
		   "Element %s namespace name for %s does not match the DTD\n",
				   elem->name, ns->prefix, NULL);
			    ret = 0;
			}
			goto found;
		    }
		    ns = ns->next;
		}
	    }
	}
found:
        attr = attr->nexth;
    }
    return(ret);
}

/**
 * xmlValidateRoot:
 * @ctxt:  the validation context
 * @doc:  a document instance
 *
 * Try to validate a the root element
 * basically it does the following check as described by the
 * XML-1.0 recommendation:
 *  - [ VC: Root Element Type ]
 * it doesn't try to recurse or apply other check to the element
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateRoot(xmlValidCtxtPtr ctxt, xmlDocPtr doc) {
    xmlNodePtr root;
    int ret;

    if (doc == NULL) return(0);

    root = xmlDocGetRootElement(doc);
    if ((root == NULL) || (root->name == NULL)) {
	xmlErrValid(ctxt, XML_DTD_NO_ROOT,
	            "no root element\n", NULL);
        return(0);
    }

    /*
     * When doing post validation against a separate DTD, those may
     * no internal subset has been generated
     */
    if ((doc->intSubset != NULL) &&
	(doc->intSubset->name != NULL)) {
	/*
	 * Check first the document root against the NQName
	 */
	if (!xmlStrEqual(doc->intSubset->name, root->name)) {
	    if ((root->ns != NULL) && (root->ns->prefix != NULL)) {
		xmlChar fn[50];
		xmlChar *fullname;

		fullname = xmlBuildQName(root->name, root->ns->prefix, fn, 50);
		if (fullname == NULL) {
		    xmlVErrMemory(ctxt, NULL);
		    return(0);
		}
		ret = xmlStrEqual(doc->intSubset->name, fullname);
		if ((fullname != fn) && (fullname != root->name))
		    xmlFree(fullname);
		if (ret == 1)
		    goto name_ok;
	    }
	    if ((xmlStrEqual(doc->intSubset->name, BAD_CAST "HTML")) &&
		(xmlStrEqual(root->name, BAD_CAST "html")))
		goto name_ok;
	    xmlErrValidNode(ctxt, root, XML_DTD_ROOT_NAME,
		   "root and DTD name do not match '%s' and '%s'\n",
		   root->name, doc->intSubset->name, NULL);
	    return(0);
	}
    }
name_ok:
    return(1);
}


/**
 * xmlValidateElement:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @elem:  an element instance
 *
 * Try to validate the subtree under an element
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateElement(xmlValidCtxtPtr ctxt, xmlDocPtr doc, xmlNodePtr elem) {
    xmlNodePtr child;
    xmlAttrPtr attr;
    xmlNsPtr ns;
    const xmlChar *value;
    int ret = 1;

    if (elem == NULL) return(0);

    /*
     * XInclude elements were added after parsing in the infoset,
     * they don't really mean anything validation wise.
     */
    if ((elem->type == XML_XINCLUDE_START) ||
	(elem->type == XML_XINCLUDE_END) ||
	(elem->type == XML_NAMESPACE_DECL))
	return(1);

    CHECK_DTD;

    /*
     * Entities references have to be handled separately
     */
    if (elem->type == XML_ENTITY_REF_NODE) {
	return(1);
    }

    ret &= xmlValidateOneElement(ctxt, doc, elem);
    if (elem->type == XML_ELEMENT_NODE) {
	attr = elem->properties;
	while (attr != NULL) {
	    value = xmlNodeListGetString(doc, attr->children, 0);
	    ret &= xmlValidateOneAttribute(ctxt, doc, elem, attr, value);
	    if (value != NULL)
		xmlFree((char *)value);
	    attr= attr->next;
	}
	ns = elem->nsDef;
	while (ns != NULL) {
	    if (elem->ns == NULL)
		ret &= xmlValidateOneNamespace(ctxt, doc, elem, NULL,
					       ns, ns->href);
	    else
		ret &= xmlValidateOneNamespace(ctxt, doc, elem,
		                               elem->ns->prefix, ns, ns->href);
	    ns = ns->next;
	}
    }
    child = elem->children;
    while (child != NULL) {
        ret &= xmlValidateElement(ctxt, doc, child);
        child = child->next;
    }

    return(ret);
}

/**
 * xmlValidateRef:
 * @ref:   A reference to be validated
 * @ctxt:  Validation context
 * @name:  Name of ID we are searching for
 *
 */
static void
xmlValidateRef(xmlRefPtr ref, xmlValidCtxtPtr ctxt,
	                   const xmlChar *name) {
    xmlAttrPtr id;
    xmlAttrPtr attr;

    if (ref == NULL)
	return;
    if ((ref->attr == NULL) && (ref->name == NULL))
	return;
    attr = ref->attr;
    if (attr == NULL) {
	xmlChar *dup, *str = NULL, *cur, save;

	dup = xmlStrdup(name);
	if (dup == NULL) {
	    ctxt->valid = 0;
	    return;
	}
	cur = dup;
	while (*cur != 0) {
	    str = cur;
	    while ((*cur != 0) && (!IS_BLANK_CH(*cur))) cur++;
	    save = *cur;
	    *cur = 0;
	    id = xmlGetID(ctxt->doc, str);
	    if (id == NULL) {
		xmlErrValidNodeNr(ctxt, NULL, XML_DTD_UNKNOWN_ID,
	   "attribute %s line %d references an unknown ID \"%s\"\n",
		       ref->name, ref->lineno, str);
		ctxt->valid = 0;
	    }
	    if (save == 0)
		break;
	    *cur = save;
	    while (IS_BLANK_CH(*cur)) cur++;
	}
	xmlFree(dup);
    } else if (attr->atype == XML_ATTRIBUTE_IDREF) {
	id = xmlGetID(ctxt->doc, name);
	if (id == NULL) {
	    xmlErrValidNode(ctxt, attr->parent, XML_DTD_UNKNOWN_ID,
	   "IDREF attribute %s references an unknown ID \"%s\"\n",
		   attr->name, name, NULL);
	    ctxt->valid = 0;
	}
    } else if (attr->atype == XML_ATTRIBUTE_IDREFS) {
	xmlChar *dup, *str = NULL, *cur, save;

	dup = xmlStrdup(name);
	if (dup == NULL) {
	    xmlVErrMemory(ctxt, "IDREFS split");
	    ctxt->valid = 0;
	    return;
	}
	cur = dup;
	while (*cur != 0) {
	    str = cur;
	    while ((*cur != 0) && (!IS_BLANK_CH(*cur))) cur++;
	    save = *cur;
	    *cur = 0;
	    id = xmlGetID(ctxt->doc, str);
	    if (id == NULL) {
		xmlErrValidNode(ctxt, attr->parent, XML_DTD_UNKNOWN_ID,
	   "IDREFS attribute %s references an unknown ID \"%s\"\n",
			     attr->name, str, NULL);
		ctxt->valid = 0;
	    }
	    if (save == 0)
		break;
	    *cur = save;
	    while (IS_BLANK_CH(*cur)) cur++;
	}
	xmlFree(dup);
    }
}

/**
 * xmlWalkValidateList:
 * @data:  Contents of current link
 * @user:  Value supplied by the user
 *
 * Returns 0 to abort the walk or 1 to continue
 */
static int
xmlWalkValidateList(const void *data, const void *user)
{
	xmlValidateMemoPtr memo = (xmlValidateMemoPtr)user;
	xmlValidateRef((xmlRefPtr)data, memo->ctxt, memo->name);
	return 1;
}

/**
 * xmlValidateCheckRefCallback:
 * @ref_list:  List of references
 * @ctxt:  Validation context
 * @name:  Name of ID we are searching for
 *
 */
static void
xmlValidateCheckRefCallback(xmlListPtr ref_list, xmlValidCtxtPtr ctxt,
	                   const xmlChar *name) {
    xmlValidateMemo memo;

    if (ref_list == NULL)
	return;
    memo.ctxt = ctxt;
    memo.name = name;

    xmlListWalk(ref_list, xmlWalkValidateList, &memo);

}

/**
 * xmlValidateDocumentFinal:
 * @ctxt:  the validation context
 * @doc:  a document instance
 *
 * Does the final step for the document validation once all the
 * incremental validation steps have been completed
 *
 * basically it does the following checks described by the XML Rec
 *
 * Check all the IDREF/IDREFS attributes definition for validity
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateDocumentFinal(xmlValidCtxtPtr ctxt, xmlDocPtr doc) {
    xmlRefTablePtr table;
    unsigned int save;

    if (ctxt == NULL)
        return(0);
    if (doc == NULL) {
        xmlErrValid(ctxt, XML_DTD_NO_DOC,
		"xmlValidateDocumentFinal: doc == NULL\n", NULL);
	return(0);
    }

    /* trick to get correct line id report */
    save = ctxt->finishDtd;
    ctxt->finishDtd = 0;

    /*
     * Check all the NOTATION/NOTATIONS attributes
     */
    /*
     * Check all the ENTITY/ENTITIES attributes definition for validity
     */
    /*
     * Check all the IDREF/IDREFS attributes definition for validity
     */
    table = (xmlRefTablePtr) doc->refs;
    ctxt->doc = doc;
    ctxt->valid = 1;
    xmlHashScan(table, (xmlHashScanner) xmlValidateCheckRefCallback, ctxt);

    ctxt->finishDtd = save;
    return(ctxt->valid);
}

/**
 * xmlValidateDtd:
 * @ctxt:  the validation context
 * @doc:  a document instance
 * @dtd:  a dtd instance
 *
 * Try to validate the document against the dtd instance
 *
 * Basically it does check all the definitions in the DtD.
 * Note the the internal subset (if present) is de-coupled
 * (i.e. not used), which could give problems if ID or IDREF
 * is present.
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateDtd(xmlValidCtxtPtr ctxt, xmlDocPtr doc, xmlDtdPtr dtd) {
    int ret;
    xmlDtdPtr oldExt, oldInt;
    xmlNodePtr root;

    if (dtd == NULL) return(0);
    if (doc == NULL) return(0);
    oldExt = doc->extSubset;
    oldInt = doc->intSubset;
    doc->extSubset = dtd;
    doc->intSubset = NULL;
    ret = xmlValidateRoot(ctxt, doc);
    if (ret == 0) {
	doc->extSubset = oldExt;
	doc->intSubset = oldInt;
	return(ret);
    }
    if (doc->ids != NULL) {
          xmlFreeIDTable(doc->ids);
          doc->ids = NULL;
    }
    if (doc->refs != NULL) {
          xmlFreeRefTable(doc->refs);
          doc->refs = NULL;
    }
    root = xmlDocGetRootElement(doc);
    ret = xmlValidateElement(ctxt, doc, root);
    ret &= xmlValidateDocumentFinal(ctxt, doc);
    doc->extSubset = oldExt;
    doc->intSubset = oldInt;
    return(ret);
}

static void
xmlValidateNotationCallback(xmlEntityPtr cur, xmlValidCtxtPtr ctxt,
	                    const xmlChar *name ATTRIBUTE_UNUSED) {
    if (cur == NULL)
	return;
    if (cur->etype == XML_EXTERNAL_GENERAL_UNPARSED_ENTITY) {
	xmlChar *notation = cur->content;

	if (notation != NULL) {
	    int ret;

	    ret = xmlValidateNotationUse(ctxt, cur->doc, notation);
	    if (ret != 1) {
		ctxt->valid = 0;
	    }
	}
    }
}

static void
xmlValidateAttributeCallback(xmlAttributePtr cur, xmlValidCtxtPtr ctxt,
	                    const xmlChar *name ATTRIBUTE_UNUSED) {
    int ret;
    xmlDocPtr doc;
    xmlElementPtr elem = NULL;

    if (cur == NULL)
	return;
    switch (cur->atype) {
	case XML_ATTRIBUTE_CDATA:
	case XML_ATTRIBUTE_ID:
	case XML_ATTRIBUTE_IDREF	:
	case XML_ATTRIBUTE_IDREFS:
	case XML_ATTRIBUTE_NMTOKEN:
	case XML_ATTRIBUTE_NMTOKENS:
	case XML_ATTRIBUTE_ENUMERATION:
	    break;
	case XML_ATTRIBUTE_ENTITY:
	case XML_ATTRIBUTE_ENTITIES:
	case XML_ATTRIBUTE_NOTATION:
	    if (cur->defaultValue != NULL) {

		ret = xmlValidateAttributeValue2(ctxt, ctxt->doc, cur->name,
			                         cur->atype, cur->defaultValue);
		if ((ret == 0) && (ctxt->valid == 1))
		    ctxt->valid = 0;
	    }
	    if (cur->tree != NULL) {
		xmlEnumerationPtr tree = cur->tree;
		while (tree != NULL) {
		    ret = xmlValidateAttributeValue2(ctxt, ctxt->doc,
				    cur->name, cur->atype, tree->name);
		    if ((ret == 0) && (ctxt->valid == 1))
			ctxt->valid = 0;
		    tree = tree->next;
		}
	    }
    }
    if (cur->atype == XML_ATTRIBUTE_NOTATION) {
	doc = cur->doc;
	if (cur->elem == NULL) {
	    xmlErrValid(ctxt, XML_ERR_INTERNAL_ERROR,
		   "xmlValidateAttributeCallback(%s): internal error\n",
		   (const char *) cur->name);
	    return;
	}

	if (doc != NULL)
	    elem = xmlGetDtdElementDesc(doc->intSubset, cur->elem);
	if ((elem == NULL) && (doc != NULL))
	    elem = xmlGetDtdElementDesc(doc->extSubset, cur->elem);
	if ((elem == NULL) && (cur->parent != NULL) &&
	    (cur->parent->type == XML_DTD_NODE))
	    elem = xmlGetDtdElementDesc((xmlDtdPtr) cur->parent, cur->elem);
	if (elem == NULL) {
	    xmlErrValidNode(ctxt, NULL, XML_DTD_UNKNOWN_ELEM,
		   "attribute %s: could not find decl for element %s\n",
		   cur->name, cur->elem, NULL);
	    return;
	}
	if (elem->etype == XML_ELEMENT_TYPE_EMPTY) {
	    xmlErrValidNode(ctxt, NULL, XML_DTD_EMPTY_NOTATION,
		   "NOTATION attribute %s declared for EMPTY element %s\n",
		   cur->name, cur->elem, NULL);
	    ctxt->valid = 0;
	}
    }
}

/**
 * xmlValidateDtdFinal:
 * @ctxt:  the validation context
 * @doc:  a document instance
 *
 * Does the final step for the dtds validation once all the
 * subsets have been parsed
 *
 * basically it does the following checks described by the XML Rec
 * - check that ENTITY and ENTITIES type attributes default or
 *   possible values matches one of the defined entities.
 * - check that NOTATION type attributes default or
 *   possible values matches one of the defined notations.
 *
 * returns 1 if valid or 0 if invalid and -1 if not well-formed
 */

int
xmlValidateDtdFinal(xmlValidCtxtPtr ctxt, xmlDocPtr doc) {
    xmlDtdPtr dtd;
    xmlAttributeTablePtr table;
    xmlEntitiesTablePtr entities;

    if ((doc == NULL) || (ctxt == NULL)) return(0);
    if ((doc->intSubset == NULL) && (doc->extSubset == NULL))
	return(0);
    ctxt->doc = doc;
    ctxt->valid = 1;
    dtd = doc->intSubset;
    if ((dtd != NULL) && (dtd->attributes != NULL)) {
	table = (xmlAttributeTablePtr) dtd->attributes;
	xmlHashScan(table, (xmlHashScanner) xmlValidateAttributeCallback, ctxt);
    }
    if ((dtd != NULL) && (dtd->entities != NULL)) {
	entities = (xmlEntitiesTablePtr) dtd->entities;
	xmlHashScan(entities, (xmlHashScanner) xmlValidateNotationCallback,
		    ctxt);
    }
    dtd = doc->extSubset;
    if ((dtd != NULL) && (dtd->attributes != NULL)) {
	table = (xmlAttributeTablePtr) dtd->attributes;
	xmlHashScan(table, (xmlHashScanner) xmlValidateAttributeCallback, ctxt);
    }
    if ((dtd != NULL) && (dtd->entities != NULL)) {
	entities = (xmlEntitiesTablePtr) dtd->entities;
	xmlHashScan(entities, (xmlHashScanner) xmlValidateNotationCallback,
		    ctxt);
    }
    return(ctxt->valid);
}

/**
 * xmlValidateDocument:
 * @ctxt:  the validation context
 * @doc:  a document instance
 *
 * Try to validate the document instance
 *
 * basically it does the all the checks described by the XML Rec
 * i.e. validates the internal and external subset (if present)
 * and validate the document tree.
 *
 * returns 1 if valid or 0 otherwise
 */

int
xmlValidateDocument(xmlValidCtxtPtr ctxt, xmlDocPtr doc) {
    int ret;
    xmlNodePtr root;

    if (doc == NULL)
        return(0);
    if ((doc->intSubset == NULL) && (doc->extSubset == NULL)) {
        xmlErrValid(ctxt, XML_DTD_NO_DTD,
	            "no DTD found!\n", NULL);
	return(0);
    }
    if ((doc->intSubset != NULL) && ((doc->intSubset->SystemID != NULL) ||
	(doc->intSubset->ExternalID != NULL)) && (doc->extSubset == NULL)) {
	xmlChar *sysID;
	if (doc->intSubset->SystemID != NULL) {
	    sysID = xmlBuildURI(doc->intSubset->SystemID,
			doc->URL);
	    if (sysID == NULL) {
	        xmlErrValid(ctxt, XML_DTD_LOAD_ERROR,
			"Could not build URI for external subset \"%s\"\n",
			(const char *) doc->intSubset->SystemID);
		return 0;
	    }
	} else
	    sysID = NULL;
        doc->extSubset = xmlParseDTD(doc->intSubset->ExternalID,
			(const xmlChar *)sysID);
	if (sysID != NULL)
	    xmlFree(sysID);
        if (doc->extSubset == NULL) {
	    if (doc->intSubset->SystemID != NULL) {
		xmlErrValid(ctxt, XML_DTD_LOAD_ERROR,
		       "Could not load the external subset \"%s\"\n",
		       (const char *) doc->intSubset->SystemID);
	    } else {
		xmlErrValid(ctxt, XML_DTD_LOAD_ERROR,
		       "Could not load the external subset \"%s\"\n",
		       (const char *) doc->intSubset->ExternalID);
	    }
	    return(0);
	}
    }

    if (doc->ids != NULL) {
          xmlFreeIDTable(doc->ids);
          doc->ids = NULL;
    }
    if (doc->refs != NULL) {
          xmlFreeRefTable(doc->refs);
          doc->refs = NULL;
    }
    ret = xmlValidateDtdFinal(ctxt, doc);
    if (!xmlValidateRoot(ctxt, doc)) return(0);

    root = xmlDocGetRootElement(doc);
    ret &= xmlValidateElement(ctxt, doc, root);
    ret &= xmlValidateDocumentFinal(ctxt, doc);
    return(ret);
}

/************************************************************************
 *									*
 *		Routines for dynamic validation editing			*
 *									*
 ************************************************************************/

/**
 * xmlValidGetPotentialChildren:
 * @ctree:  an element content tree
 * @names:  an array to store the list of child names
 * @len:  a pointer to the number of element in the list
 * @max:  the size of the array
 *
 * Build/extend a list of  potential children allowed by the content tree
 *
 * returns the number of element in the list, or -1 in case of error.
 */

int
xmlValidGetPotentialChildren(xmlElementContent *ctree,
                             const xmlChar **names,
                             int *len, int max) {
    int i;

    if ((ctree == NULL) || (names == NULL) || (len == NULL))
        return(-1);
    if (*len >= max) return(*len);

    switch (ctree->type) {
	case XML_ELEMENT_CONTENT_PCDATA:
	    for (i = 0; i < *len;i++)
		if (xmlStrEqual(BAD_CAST "#PCDATA", names[i])) return(*len);
	    names[(*len)++] = BAD_CAST "#PCDATA";
	    break;
	case XML_ELEMENT_CONTENT_ELEMENT:
	    for (i = 0; i < *len;i++)
		if (xmlStrEqual(ctree->name, names[i])) return(*len);
	    names[(*len)++] = ctree->name;
	    break;
	case XML_ELEMENT_CONTENT_SEQ:
	    xmlValidGetPotentialChildren(ctree->c1, names, len, max);
	    xmlValidGetPotentialChildren(ctree->c2, names, len, max);
	    break;
	case XML_ELEMENT_CONTENT_OR:
	    xmlValidGetPotentialChildren(ctree->c1, names, len, max);
	    xmlValidGetPotentialChildren(ctree->c2, names, len, max);
	    break;
   }

   return(*len);
}

/*
 * Dummy function to suppress messages while we try out valid elements
 */
static void XMLCDECL xmlNoValidityErr(void *ctx ATTRIBUTE_UNUSED,
                                const char *msg ATTRIBUTE_UNUSED, ...) {
    return;
}

/**
 * xmlValidGetValidElements:
 * @prev:  an element to insert after
 * @next:  an element to insert next
 * @names:  an array to store the list of child names
 * @max:  the size of the array
 *
 * This function returns the list of authorized children to insert
 * within an existing tree while respecting the validity constraints
 * forced by the Dtd. The insertion point is defined using @prev and
 * @next in the following ways:
 *  to insert before 'node': xmlValidGetValidElements(node->prev, node, ...
 *  to insert next 'node': xmlValidGetValidElements(node, node->next, ...
 *  to replace 'node': xmlValidGetValidElements(node->prev, node->next, ...
 *  to prepend a child to 'node': xmlValidGetValidElements(NULL, node->childs,
 *  to append a child to 'node': xmlValidGetValidElements(node->last, NULL, ...
 *
 * pointers to the element names are inserted at the beginning of the array
 * and do not need to be freed.
 *
 * returns the number of element in the list, or -1 in case of error. If
 *    the function returns the value @max the caller is invited to grow the
 *    receiving array and retry.
 */

int
xmlValidGetValidElements(xmlNode *prev, xmlNode *next, const xmlChar **names,
                         int max) {
    xmlValidCtxt vctxt;
    int nb_valid_elements = 0;
    const xmlChar *elements[256]={0};
    int nb_elements = 0, i;
    const xmlChar *name;

    xmlNode *ref_node;
    xmlNode *parent;
    xmlNode *test_node;

    xmlNode *prev_next;
    xmlNode *next_prev;
    xmlNode *parent_childs;
    xmlNode *parent_last;

    xmlElement *element_desc;

    if (prev == NULL && next == NULL)
        return(-1);

    if (names == NULL) return(-1);
    if (max <= 0) return(-1);

    memset(&vctxt, 0, sizeof (xmlValidCtxt));
    vctxt.error = xmlNoValidityErr;	/* this suppresses err/warn output */

    nb_valid_elements = 0;
    ref_node = prev ? prev : next;
    parent = ref_node->parent;

    /*
     * Retrieves the parent element declaration
     */
    element_desc = xmlGetDtdElementDesc(parent->doc->intSubset,
                                         parent->name);
    if ((element_desc == NULL) && (parent->doc->extSubset != NULL))
        element_desc = xmlGetDtdElementDesc(parent->doc->extSubset,
                                             parent->name);
    if (element_desc == NULL) return(-1);

    /*
     * Do a backup of the current tree structure
     */
    prev_next = prev ? prev->next : NULL;
    next_prev = next ? next->prev : NULL;
    parent_childs = parent->children;
    parent_last = parent->last;

    /*
     * Creates a dummy node and insert it into the tree
     */
    test_node = xmlNewDocNode (ref_node->doc, NULL, BAD_CAST "<!dummy?>", NULL);
    if (test_node == NULL)
        return(-1);

    test_node->parent = parent;
    test_node->prev = prev;
    test_node->next = next;
    name = test_node->name;

    if (prev) prev->next = test_node;
    else parent->children = test_node;

    if (next) next->prev = test_node;
    else parent->last = test_node;

    /*
     * Insert each potential child node and check if the parent is
     * still valid
     */
    nb_elements = xmlValidGetPotentialChildren(element_desc->content,
		       elements, &nb_elements, 256);

    for (i = 0;i < nb_elements;i++) {
	test_node->name = elements[i];
	if (xmlValidateOneElement(&vctxt, parent->doc, parent)) {
	    int j;

	    for (j = 0; j < nb_valid_elements;j++)
		if (xmlStrEqual(elements[i], names[j])) break;
	    names[nb_valid_elements++] = elements[i];
	    if (nb_valid_elements >= max) break;
	}
    }

    /*
     * Restore the tree structure
     */
    if (prev) prev->next = prev_next;
    if (next) next->prev = next_prev;
    parent->children = parent_childs;
    parent->last = parent_last;

    /*
     * Free up the dummy node
     */
    test_node->name = name;
    xmlFreeNode(test_node);

    return(nb_valid_elements);
}
#endif /* LIBXML_VALID_ENABLED */

#define bottom_valid
#include "elfgcchack.h"
