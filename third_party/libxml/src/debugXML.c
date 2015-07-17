/*
 * debugXML.c : This is a set of routines used for debugging the tree
 *              produced by the XML parser.
 *
 * See Copyright for the status of this software.
 *
 * Daniel Veillard <daniel@veillard.com>
 */

#define IN_LIBXML
#include "libxml.h"
#ifdef LIBXML_DEBUG_ENABLED

#include <string.h>
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_STRING_H
#include <string.h>
#endif
#include <libxml/xmlmemory.h>
#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/valid.h>
#include <libxml/debugXML.h>
#include <libxml/HTMLtree.h>
#include <libxml/HTMLparser.h>
#include <libxml/xmlerror.h>
#include <libxml/globals.h>
#include <libxml/xpathInternals.h>
#include <libxml/uri.h>
#ifdef LIBXML_SCHEMAS_ENABLED
#include <libxml/relaxng.h>
#endif

#define DUMP_TEXT_TYPE 1

typedef struct _xmlDebugCtxt xmlDebugCtxt;
typedef xmlDebugCtxt *xmlDebugCtxtPtr;
struct _xmlDebugCtxt {
    FILE *output;               /* the output file */
    char shift[101];            /* used for indenting */
    int depth;                  /* current depth */
    xmlDocPtr doc;              /* current document */
    xmlNodePtr node;		/* current node */
    xmlDictPtr dict;		/* the doc dictionnary */
    int check;                  /* do just checkings */
    int errors;                 /* number of errors found */
    int nodict;			/* if the document has no dictionnary */
    int options;		/* options */
};

static void xmlCtxtDumpNodeList(xmlDebugCtxtPtr ctxt, xmlNodePtr node);

static void
xmlCtxtDumpInitCtxt(xmlDebugCtxtPtr ctxt)
{
    int i;

    ctxt->depth = 0;
    ctxt->check = 0;
    ctxt->errors = 0;
    ctxt->output = stdout;
    ctxt->doc = NULL;
    ctxt->node = NULL;
    ctxt->dict = NULL;
    ctxt->nodict = 0;
    ctxt->options = 0;
    for (i = 0; i < 100; i++)
        ctxt->shift[i] = ' ';
    ctxt->shift[100] = 0;
}

static void
xmlCtxtDumpCleanCtxt(xmlDebugCtxtPtr ctxt ATTRIBUTE_UNUSED)
{
 /* remove the ATTRIBUTE_UNUSED when this is added */
}

/**
 * xmlNsCheckScope:
 * @node: the node
 * @ns: the namespace node
 *
 * Check that a given namespace is in scope on a node.
 *
 * Returns 1 if in scope, -1 in case of argument error,
 *         -2 if the namespace is not in scope, and -3 if not on
 *         an ancestor node.
 */
static int
xmlNsCheckScope(xmlNodePtr node, xmlNsPtr ns)
{
    xmlNsPtr cur;

    if ((node == NULL) || (ns == NULL))
        return(-1);

    if ((node->type != XML_ELEMENT_NODE) &&
	(node->type != XML_ATTRIBUTE_NODE) &&
	(node->type != XML_DOCUMENT_NODE) &&
	(node->type != XML_TEXT_NODE) &&
	(node->type != XML_HTML_DOCUMENT_NODE) &&
	(node->type != XML_XINCLUDE_START))
	return(-2);

    while ((node != NULL) &&
           ((node->type == XML_ELEMENT_NODE) ||
            (node->type == XML_ATTRIBUTE_NODE) ||
            (node->type == XML_TEXT_NODE) ||
	    (node->type == XML_XINCLUDE_START))) {
	if ((node->type == XML_ELEMENT_NODE) ||
	    (node->type == XML_XINCLUDE_START)) {
	    cur = node->nsDef;
	    while (cur != NULL) {
	        if (cur == ns)
		    return(1);
		if (xmlStrEqual(cur->prefix, ns->prefix))
		    return(-2);
		cur = cur->next;
	    }
	}
	node = node->parent;
    }
    /* the xml namespace may be declared on the document node */
    if ((node != NULL) &&
        ((node->type == XML_DOCUMENT_NODE) ||
	 (node->type == XML_HTML_DOCUMENT_NODE))) {
	 xmlNsPtr oldNs = ((xmlDocPtr) node)->oldNs;
	 if (oldNs == ns)
	     return(1);
    }
    return(-3);
}

static void
xmlCtxtDumpSpaces(xmlDebugCtxtPtr ctxt)
{
    if (ctxt->check)
        return;
    if ((ctxt->output != NULL) && (ctxt->depth > 0)) {
        if (ctxt->depth < 50)
            fprintf(ctxt->output, "%s", &ctxt->shift[100 - 2 * ctxt->depth]);
        else
            fprintf(ctxt->output, "%s", ctxt->shift);
    }
}

/**
 * xmlDebugErr:
 * @ctxt:  a debug context
 * @error:  the error code
 *
 * Handle a debug error.
 */
static void
xmlDebugErr(xmlDebugCtxtPtr ctxt, int error, const char *msg)
{
    ctxt->errors++;
    __xmlRaiseError(NULL, NULL, NULL,
		    NULL, ctxt->node, XML_FROM_CHECK,
		    error, XML_ERR_ERROR, NULL, 0,
		    NULL, NULL, NULL, 0, 0,
		    "%s", msg);
}
static void
xmlDebugErr2(xmlDebugCtxtPtr ctxt, int error, const char *msg, int extra)
{
    ctxt->errors++;
    __xmlRaiseError(NULL, NULL, NULL,
		    NULL, ctxt->node, XML_FROM_CHECK,
		    error, XML_ERR_ERROR, NULL, 0,
		    NULL, NULL, NULL, 0, 0,
		    msg, extra);
}
static void
xmlDebugErr3(xmlDebugCtxtPtr ctxt, int error, const char *msg, const char *extra)
{
    ctxt->errors++;
    __xmlRaiseError(NULL, NULL, NULL,
		    NULL, ctxt->node, XML_FROM_CHECK,
		    error, XML_ERR_ERROR, NULL, 0,
		    NULL, NULL, NULL, 0, 0,
		    msg, extra);
}

/**
 * xmlCtxtNsCheckScope:
 * @ctxt: the debugging context
 * @node: the node
 * @ns: the namespace node
 *
 * Report if a given namespace is is not in scope.
 */
static void
xmlCtxtNsCheckScope(xmlDebugCtxtPtr ctxt, xmlNodePtr node, xmlNsPtr ns)
{
    int ret;

    ret = xmlNsCheckScope(node, ns);
    if (ret == -2) {
        if (ns->prefix == NULL)
	    xmlDebugErr(ctxt, XML_CHECK_NS_SCOPE,
			"Reference to default namespace not in scope\n");
	else
	    xmlDebugErr3(ctxt, XML_CHECK_NS_SCOPE,
			 "Reference to namespace '%s' not in scope\n",
			 (char *) ns->prefix);
    }
    if (ret == -3) {
        if (ns->prefix == NULL)
	    xmlDebugErr(ctxt, XML_CHECK_NS_ANCESTOR,
			"Reference to default namespace not on ancestor\n");
	else
	    xmlDebugErr3(ctxt, XML_CHECK_NS_ANCESTOR,
			 "Reference to namespace '%s' not on ancestor\n",
			 (char *) ns->prefix);
    }
}

/**
 * xmlCtxtCheckString:
 * @ctxt: the debug context
 * @str: the string
 *
 * Do debugging on the string, currently it just checks the UTF-8 content
 */
static void
xmlCtxtCheckString(xmlDebugCtxtPtr ctxt, const xmlChar * str)
{
    if (str == NULL) return;
    if (ctxt->check) {
        if (!xmlCheckUTF8(str)) {
	    xmlDebugErr3(ctxt, XML_CHECK_NOT_UTF8,
			 "String is not UTF-8 %s", (const char *) str);
	}
    }
}

/**
 * xmlCtxtCheckName:
 * @ctxt: the debug context
 * @name: the name
 *
 * Do debugging on the name, for example the dictionnary status and
 * conformance to the Name production.
 */
static void
xmlCtxtCheckName(xmlDebugCtxtPtr ctxt, const xmlChar * name)
{
    if (ctxt->check) {
	if (name == NULL) {
	    xmlDebugErr(ctxt, XML_CHECK_NO_NAME, "Name is NULL");
	    return;
	}
#if defined(LIBXML_TREE_ENABLED) || defined(LIBXML_SCHEMAS_ENABLED)
        if (xmlValidateName(name, 0)) {
	    xmlDebugErr3(ctxt, XML_CHECK_NOT_NCNAME,
			 "Name is not an NCName '%s'", (const char *) name);
	}
#endif
	if ((ctxt->dict != NULL) &&
	    (!xmlDictOwns(ctxt->dict, name)) &&
            ((ctxt->doc == NULL) ||
             ((ctxt->doc->parseFlags & (XML_PARSE_SAX1 | XML_PARSE_NODICT)) == 0))) {
	    xmlDebugErr3(ctxt, XML_CHECK_OUTSIDE_DICT,
			 "Name is not from the document dictionnary '%s'",
			 (const char *) name);
	}
    }
}

static void
xmlCtxtGenericNodeCheck(xmlDebugCtxtPtr ctxt, xmlNodePtr node) {
    xmlDocPtr doc;
    xmlDictPtr dict;

    doc = node->doc;

    if (node->parent == NULL)
        xmlDebugErr(ctxt, XML_CHECK_NO_PARENT,
	            "Node has no parent\n");
    if (node->doc == NULL) {
        xmlDebugErr(ctxt, XML_CHECK_NO_DOC,
	            "Node has no doc\n");
        dict = NULL;
    } else {
	dict = doc->dict;
	if ((dict == NULL) && (ctxt->nodict == 0)) {
#if 0
            /* desactivated right now as it raises too many errors */
	    if (doc->type == XML_DOCUMENT_NODE)
		xmlDebugErr(ctxt, XML_CHECK_NO_DICT,
			    "Document has no dictionnary\n");
#endif
	    ctxt->nodict = 1;
	}
	if (ctxt->doc == NULL)
	    ctxt->doc = doc;

	if (ctxt->dict == NULL) {
	    ctxt->dict = dict;
	}
    }
    if ((node->parent != NULL) && (node->doc != node->parent->doc) &&
        (!xmlStrEqual(node->name, BAD_CAST "pseudoroot")))
        xmlDebugErr(ctxt, XML_CHECK_WRONG_DOC,
	            "Node doc differs from parent's one\n");
    if (node->prev == NULL) {
        if (node->type == XML_ATTRIBUTE_NODE) {
	    if ((node->parent != NULL) &&
	        (node != (xmlNodePtr) node->parent->properties))
		xmlDebugErr(ctxt, XML_CHECK_NO_PREV,
                    "Attr has no prev and not first of attr list\n");

        } else if ((node->parent != NULL) && (node->parent->children != node))
	    xmlDebugErr(ctxt, XML_CHECK_NO_PREV,
                    "Node has no prev and not first of parent list\n");
    } else {
        if (node->prev->next != node)
	    xmlDebugErr(ctxt, XML_CHECK_WRONG_PREV,
                        "Node prev->next : back link wrong\n");
    }
    if (node->next == NULL) {
	if ((node->parent != NULL) && (node->type != XML_ATTRIBUTE_NODE) &&
	    (node->parent->last != node) &&
	    (node->parent->type == XML_ELEMENT_NODE))
	    xmlDebugErr(ctxt, XML_CHECK_NO_NEXT,
                    "Node has no next and not last of parent list\n");
    } else {
        if (node->next->prev != node)
	    xmlDebugErr(ctxt, XML_CHECK_WRONG_NEXT,
                    "Node next->prev : forward link wrong\n");
        if (node->next->parent != node->parent)
	    xmlDebugErr(ctxt, XML_CHECK_WRONG_PARENT,
                    "Node next->prev : forward link wrong\n");
    }
    if (node->type == XML_ELEMENT_NODE) {
        xmlNsPtr ns;

	ns = node->nsDef;
	while (ns != NULL) {
	    xmlCtxtNsCheckScope(ctxt, node, ns);
	    ns = ns->next;
	}
	if (node->ns != NULL)
	    xmlCtxtNsCheckScope(ctxt, node, node->ns);
    } else if (node->type == XML_ATTRIBUTE_NODE) {
	if (node->ns != NULL)
	    xmlCtxtNsCheckScope(ctxt, node, node->ns);
    }

    if ((node->type != XML_ELEMENT_NODE) &&
	(node->type != XML_ATTRIBUTE_NODE) &&
	(node->type != XML_ELEMENT_DECL) &&
	(node->type != XML_ATTRIBUTE_DECL) &&
	(node->type != XML_DTD_NODE) &&
	(node->type != XML_HTML_DOCUMENT_NODE) &&
	(node->type != XML_DOCUMENT_NODE)) {
	if (node->content != NULL)
	    xmlCtxtCheckString(ctxt, (const xmlChar *) node->content);
    }
    switch (node->type) {
        case XML_ELEMENT_NODE:
        case XML_ATTRIBUTE_NODE:
	    xmlCtxtCheckName(ctxt, node->name);
	    break;
        case XML_TEXT_NODE:
	    if ((node->name == xmlStringText) ||
	        (node->name == xmlStringTextNoenc))
		break;
	    /* some case of entity substitution can lead to this */
	    if ((ctxt->dict != NULL) &&
	        (node->name == xmlDictLookup(ctxt->dict, BAD_CAST "nbktext",
		                             7)))
		break;

	    xmlDebugErr3(ctxt, XML_CHECK_WRONG_NAME,
			 "Text node has wrong name '%s'",
			 (const char *) node->name);
	    break;
        case XML_COMMENT_NODE:
	    if (node->name == xmlStringComment)
		break;
	    xmlDebugErr3(ctxt, XML_CHECK_WRONG_NAME,
			 "Comment node has wrong name '%s'",
			 (const char *) node->name);
	    break;
        case XML_PI_NODE:
	    xmlCtxtCheckName(ctxt, node->name);
	    break;
        case XML_CDATA_SECTION_NODE:
	    if (node->name == NULL)
		break;
	    xmlDebugErr3(ctxt, XML_CHECK_NAME_NOT_NULL,
			 "CData section has non NULL name '%s'",
			 (const char *) node->name);
	    break;
        case XML_ENTITY_REF_NODE:
        case XML_ENTITY_NODE:
        case XML_DOCUMENT_TYPE_NODE:
        case XML_DOCUMENT_FRAG_NODE:
        case XML_NOTATION_NODE:
        case XML_DTD_NODE:
        case XML_ELEMENT_DECL:
        case XML_ATTRIBUTE_DECL:
        case XML_ENTITY_DECL:
        case XML_NAMESPACE_DECL:
        case XML_XINCLUDE_START:
        case XML_XINCLUDE_END:
#ifdef LIBXML_DOCB_ENABLED
        case XML_DOCB_DOCUMENT_NODE:
#endif
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
	    break;
    }
}

static void
xmlCtxtDumpString(xmlDebugCtxtPtr ctxt, const xmlChar * str)
{
    int i;

    if (ctxt->check) {
        return;
    }
    /* TODO: check UTF8 content of the string */
    if (str == NULL) {
        fprintf(ctxt->output, "(NULL)");
        return;
    }
    for (i = 0; i < 40; i++)
        if (str[i] == 0)
            return;
        else if (IS_BLANK_CH(str[i]))
            fputc(' ', ctxt->output);
        else if (str[i] >= 0x80)
            fprintf(ctxt->output, "#%X", str[i]);
        else
            fputc(str[i], ctxt->output);
    fprintf(ctxt->output, "...");
}

static void
xmlCtxtDumpDtdNode(xmlDebugCtxtPtr ctxt, xmlDtdPtr dtd)
{
    xmlCtxtDumpSpaces(ctxt);

    if (dtd == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "DTD node is NULL\n");
        return;
    }

    if (dtd->type != XML_DTD_NODE) {
	xmlDebugErr(ctxt, XML_CHECK_NOT_DTD,
	            "Node is not a DTD");
        return;
    }
    if (!ctxt->check) {
        if (dtd->name != NULL)
            fprintf(ctxt->output, "DTD(%s)", (char *) dtd->name);
        else
            fprintf(ctxt->output, "DTD");
        if (dtd->ExternalID != NULL)
            fprintf(ctxt->output, ", PUBLIC %s", (char *) dtd->ExternalID);
        if (dtd->SystemID != NULL)
            fprintf(ctxt->output, ", SYSTEM %s", (char *) dtd->SystemID);
        fprintf(ctxt->output, "\n");
    }
    /*
     * Do a bit of checking
     */
    xmlCtxtGenericNodeCheck(ctxt, (xmlNodePtr) dtd);
}

static void
xmlCtxtDumpAttrDecl(xmlDebugCtxtPtr ctxt, xmlAttributePtr attr)
{
    xmlCtxtDumpSpaces(ctxt);

    if (attr == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "Attribute declaration is NULL\n");
        return;
    }
    if (attr->type != XML_ATTRIBUTE_DECL) {
	xmlDebugErr(ctxt, XML_CHECK_NOT_ATTR_DECL,
	            "Node is not an attribute declaration");
        return;
    }
    if (attr->name != NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "ATTRDECL(%s)", (char *) attr->name);
    } else
	xmlDebugErr(ctxt, XML_CHECK_NO_NAME,
	            "Node attribute declaration has no name");
    if (attr->elem != NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, " for %s", (char *) attr->elem);
    } else
	xmlDebugErr(ctxt, XML_CHECK_NO_ELEM,
	            "Node attribute declaration has no element name");
    if (!ctxt->check) {
        switch (attr->atype) {
            case XML_ATTRIBUTE_CDATA:
                fprintf(ctxt->output, " CDATA");
                break;
            case XML_ATTRIBUTE_ID:
                fprintf(ctxt->output, " ID");
                break;
            case XML_ATTRIBUTE_IDREF:
                fprintf(ctxt->output, " IDREF");
                break;
            case XML_ATTRIBUTE_IDREFS:
                fprintf(ctxt->output, " IDREFS");
                break;
            case XML_ATTRIBUTE_ENTITY:
                fprintf(ctxt->output, " ENTITY");
                break;
            case XML_ATTRIBUTE_ENTITIES:
                fprintf(ctxt->output, " ENTITIES");
                break;
            case XML_ATTRIBUTE_NMTOKEN:
                fprintf(ctxt->output, " NMTOKEN");
                break;
            case XML_ATTRIBUTE_NMTOKENS:
                fprintf(ctxt->output, " NMTOKENS");
                break;
            case XML_ATTRIBUTE_ENUMERATION:
                fprintf(ctxt->output, " ENUMERATION");
                break;
            case XML_ATTRIBUTE_NOTATION:
                fprintf(ctxt->output, " NOTATION ");
                break;
        }
        if (attr->tree != NULL) {
            int indx;
            xmlEnumerationPtr cur = attr->tree;

            for (indx = 0; indx < 5; indx++) {
                if (indx != 0)
                    fprintf(ctxt->output, "|%s", (char *) cur->name);
                else
                    fprintf(ctxt->output, " (%s", (char *) cur->name);
                cur = cur->next;
                if (cur == NULL)
                    break;
            }
            if (cur == NULL)
                fprintf(ctxt->output, ")");
            else
                fprintf(ctxt->output, "...)");
        }
        switch (attr->def) {
            case XML_ATTRIBUTE_NONE:
                break;
            case XML_ATTRIBUTE_REQUIRED:
                fprintf(ctxt->output, " REQUIRED");
                break;
            case XML_ATTRIBUTE_IMPLIED:
                fprintf(ctxt->output, " IMPLIED");
                break;
            case XML_ATTRIBUTE_FIXED:
                fprintf(ctxt->output, " FIXED");
                break;
        }
        if (attr->defaultValue != NULL) {
            fprintf(ctxt->output, "\"");
            xmlCtxtDumpString(ctxt, attr->defaultValue);
            fprintf(ctxt->output, "\"");
        }
        fprintf(ctxt->output, "\n");
    }

    /*
     * Do a bit of checking
     */
    xmlCtxtGenericNodeCheck(ctxt, (xmlNodePtr) attr);
}

static void
xmlCtxtDumpElemDecl(xmlDebugCtxtPtr ctxt, xmlElementPtr elem)
{
    xmlCtxtDumpSpaces(ctxt);

    if (elem == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "Element declaration is NULL\n");
        return;
    }
    if (elem->type != XML_ELEMENT_DECL) {
	xmlDebugErr(ctxt, XML_CHECK_NOT_ELEM_DECL,
	            "Node is not an element declaration");
        return;
    }
    if (elem->name != NULL) {
        if (!ctxt->check) {
            fprintf(ctxt->output, "ELEMDECL(");
            xmlCtxtDumpString(ctxt, elem->name);
            fprintf(ctxt->output, ")");
        }
    } else
	xmlDebugErr(ctxt, XML_CHECK_NO_NAME,
	            "Element declaration has no name");
    if (!ctxt->check) {
        switch (elem->etype) {
            case XML_ELEMENT_TYPE_UNDEFINED:
                fprintf(ctxt->output, ", UNDEFINED");
                break;
            case XML_ELEMENT_TYPE_EMPTY:
                fprintf(ctxt->output, ", EMPTY");
                break;
            case XML_ELEMENT_TYPE_ANY:
                fprintf(ctxt->output, ", ANY");
                break;
            case XML_ELEMENT_TYPE_MIXED:
                fprintf(ctxt->output, ", MIXED ");
                break;
            case XML_ELEMENT_TYPE_ELEMENT:
                fprintf(ctxt->output, ", MIXED ");
                break;
        }
        if ((elem->type != XML_ELEMENT_NODE) && (elem->content != NULL)) {
            char buf[5001];

            buf[0] = 0;
            xmlSnprintfElementContent(buf, 5000, elem->content, 1);
            buf[5000] = 0;
            fprintf(ctxt->output, "%s", buf);
        }
        fprintf(ctxt->output, "\n");
    }

    /*
     * Do a bit of checking
     */
    xmlCtxtGenericNodeCheck(ctxt, (xmlNodePtr) elem);
}

static void
xmlCtxtDumpEntityDecl(xmlDebugCtxtPtr ctxt, xmlEntityPtr ent)
{
    xmlCtxtDumpSpaces(ctxt);

    if (ent == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "Entity declaration is NULL\n");
        return;
    }
    if (ent->type != XML_ENTITY_DECL) {
	xmlDebugErr(ctxt, XML_CHECK_NOT_ENTITY_DECL,
	            "Node is not an entity declaration");
        return;
    }
    if (ent->name != NULL) {
        if (!ctxt->check) {
            fprintf(ctxt->output, "ENTITYDECL(");
            xmlCtxtDumpString(ctxt, ent->name);
            fprintf(ctxt->output, ")");
        }
    } else
	xmlDebugErr(ctxt, XML_CHECK_NO_NAME,
	            "Entity declaration has no name");
    if (!ctxt->check) {
        switch (ent->etype) {
            case XML_INTERNAL_GENERAL_ENTITY:
                fprintf(ctxt->output, ", internal\n");
                break;
            case XML_EXTERNAL_GENERAL_PARSED_ENTITY:
                fprintf(ctxt->output, ", external parsed\n");
                break;
            case XML_EXTERNAL_GENERAL_UNPARSED_ENTITY:
                fprintf(ctxt->output, ", unparsed\n");
                break;
            case XML_INTERNAL_PARAMETER_ENTITY:
                fprintf(ctxt->output, ", parameter\n");
                break;
            case XML_EXTERNAL_PARAMETER_ENTITY:
                fprintf(ctxt->output, ", external parameter\n");
                break;
            case XML_INTERNAL_PREDEFINED_ENTITY:
                fprintf(ctxt->output, ", predefined\n");
                break;
        }
        if (ent->ExternalID) {
            xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, " ExternalID=%s\n",
                    (char *) ent->ExternalID);
        }
        if (ent->SystemID) {
            xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, " SystemID=%s\n",
                    (char *) ent->SystemID);
        }
        if (ent->URI != NULL) {
            xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, " URI=%s\n", (char *) ent->URI);
        }
        if (ent->content) {
            xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, " content=");
            xmlCtxtDumpString(ctxt, ent->content);
            fprintf(ctxt->output, "\n");
        }
    }

    /*
     * Do a bit of checking
     */
    xmlCtxtGenericNodeCheck(ctxt, (xmlNodePtr) ent);
}

static void
xmlCtxtDumpNamespace(xmlDebugCtxtPtr ctxt, xmlNsPtr ns)
{
    xmlCtxtDumpSpaces(ctxt);

    if (ns == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "namespace node is NULL\n");
        return;
    }
    if (ns->type != XML_NAMESPACE_DECL) {
	xmlDebugErr(ctxt, XML_CHECK_NOT_NS_DECL,
	            "Node is not a namespace declaration");
        return;
    }
    if (ns->href == NULL) {
        if (ns->prefix != NULL)
	    xmlDebugErr3(ctxt, XML_CHECK_NO_HREF,
                    "Incomplete namespace %s href=NULL\n",
                    (char *) ns->prefix);
        else
	    xmlDebugErr(ctxt, XML_CHECK_NO_HREF,
                    "Incomplete default namespace href=NULL\n");
    } else {
        if (!ctxt->check) {
            if (ns->prefix != NULL)
                fprintf(ctxt->output, "namespace %s href=",
                        (char *) ns->prefix);
            else
                fprintf(ctxt->output, "default namespace href=");

            xmlCtxtDumpString(ctxt, ns->href);
            fprintf(ctxt->output, "\n");
        }
    }
}

static void
xmlCtxtDumpNamespaceList(xmlDebugCtxtPtr ctxt, xmlNsPtr ns)
{
    while (ns != NULL) {
        xmlCtxtDumpNamespace(ctxt, ns);
        ns = ns->next;
    }
}

static void
xmlCtxtDumpEntity(xmlDebugCtxtPtr ctxt, xmlEntityPtr ent)
{
    xmlCtxtDumpSpaces(ctxt);

    if (ent == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "Entity is NULL\n");
        return;
    }
    if (!ctxt->check) {
        switch (ent->etype) {
            case XML_INTERNAL_GENERAL_ENTITY:
                fprintf(ctxt->output, "INTERNAL_GENERAL_ENTITY ");
                break;
            case XML_EXTERNAL_GENERAL_PARSED_ENTITY:
                fprintf(ctxt->output, "EXTERNAL_GENERAL_PARSED_ENTITY ");
                break;
            case XML_EXTERNAL_GENERAL_UNPARSED_ENTITY:
                fprintf(ctxt->output, "EXTERNAL_GENERAL_UNPARSED_ENTITY ");
                break;
            case XML_INTERNAL_PARAMETER_ENTITY:
                fprintf(ctxt->output, "INTERNAL_PARAMETER_ENTITY ");
                break;
            case XML_EXTERNAL_PARAMETER_ENTITY:
                fprintf(ctxt->output, "EXTERNAL_PARAMETER_ENTITY ");
                break;
            default:
                fprintf(ctxt->output, "ENTITY_%d ! ", (int) ent->etype);
        }
        fprintf(ctxt->output, "%s\n", ent->name);
        if (ent->ExternalID) {
            xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, "ExternalID=%s\n",
                    (char *) ent->ExternalID);
        }
        if (ent->SystemID) {
            xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, "SystemID=%s\n", (char *) ent->SystemID);
        }
        if (ent->URI) {
            xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, "URI=%s\n", (char *) ent->URI);
        }
        if (ent->content) {
            xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, "content=");
            xmlCtxtDumpString(ctxt, ent->content);
            fprintf(ctxt->output, "\n");
        }
    }
}

/**
 * xmlCtxtDumpAttr:
 * @output:  the FILE * for the output
 * @attr:  the attribute
 * @depth:  the indentation level.
 *
 * Dumps debug information for the attribute
 */
static void
xmlCtxtDumpAttr(xmlDebugCtxtPtr ctxt, xmlAttrPtr attr)
{
    xmlCtxtDumpSpaces(ctxt);

    if (attr == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "Attr is NULL");
        return;
    }
    if (!ctxt->check) {
        fprintf(ctxt->output, "ATTRIBUTE ");
	xmlCtxtDumpString(ctxt, attr->name);
        fprintf(ctxt->output, "\n");
        if (attr->children != NULL) {
            ctxt->depth++;
            xmlCtxtDumpNodeList(ctxt, attr->children);
            ctxt->depth--;
        }
    }
    if (attr->name == NULL)
	xmlDebugErr(ctxt, XML_CHECK_NO_NAME,
	            "Attribute has no name");

    /*
     * Do a bit of checking
     */
    xmlCtxtGenericNodeCheck(ctxt, (xmlNodePtr) attr);
}

/**
 * xmlCtxtDumpAttrList:
 * @output:  the FILE * for the output
 * @attr:  the attribute list
 * @depth:  the indentation level.
 *
 * Dumps debug information for the attribute list
 */
static void
xmlCtxtDumpAttrList(xmlDebugCtxtPtr ctxt, xmlAttrPtr attr)
{
    while (attr != NULL) {
        xmlCtxtDumpAttr(ctxt, attr);
        attr = attr->next;
    }
}

/**
 * xmlCtxtDumpOneNode:
 * @output:  the FILE * for the output
 * @node:  the node
 * @depth:  the indentation level.
 *
 * Dumps debug information for the element node, it is not recursive
 */
static void
xmlCtxtDumpOneNode(xmlDebugCtxtPtr ctxt, xmlNodePtr node)
{
    if (node == NULL) {
        if (!ctxt->check) {
            xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, "node is NULL\n");
        }
        return;
    }
    ctxt->node = node;

    switch (node->type) {
        case XML_ELEMENT_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "ELEMENT ");
                if ((node->ns != NULL) && (node->ns->prefix != NULL)) {
                    xmlCtxtDumpString(ctxt, node->ns->prefix);
                    fprintf(ctxt->output, ":");
                }
                xmlCtxtDumpString(ctxt, node->name);
                fprintf(ctxt->output, "\n");
            }
            break;
        case XML_ATTRIBUTE_NODE:
            if (!ctxt->check)
                xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, "Error, ATTRIBUTE found here\n");
            xmlCtxtGenericNodeCheck(ctxt, node);
            return;
        case XML_TEXT_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                if (node->name == (const xmlChar *) xmlStringTextNoenc)
                    fprintf(ctxt->output, "TEXT no enc");
                else
                    fprintf(ctxt->output, "TEXT");
		if (ctxt->options & DUMP_TEXT_TYPE) {
		    if (node->content == (xmlChar *) &(node->properties))
			fprintf(ctxt->output, " compact\n");
		    else if (xmlDictOwns(ctxt->dict, node->content) == 1)
			fprintf(ctxt->output, " interned\n");
		    else
			fprintf(ctxt->output, "\n");
		} else
		    fprintf(ctxt->output, "\n");
            }
            break;
        case XML_CDATA_SECTION_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "CDATA_SECTION\n");
            }
            break;
        case XML_ENTITY_REF_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "ENTITY_REF(%s)\n",
                        (char *) node->name);
            }
            break;
        case XML_ENTITY_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "ENTITY\n");
            }
            break;
        case XML_PI_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "PI %s\n", (char *) node->name);
            }
            break;
        case XML_COMMENT_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "COMMENT\n");
            }
            break;
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
            }
            fprintf(ctxt->output, "Error, DOCUMENT found here\n");
            xmlCtxtGenericNodeCheck(ctxt, node);
            return;
        case XML_DOCUMENT_TYPE_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "DOCUMENT_TYPE\n");
            }
            break;
        case XML_DOCUMENT_FRAG_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "DOCUMENT_FRAG\n");
            }
            break;
        case XML_NOTATION_NODE:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "NOTATION\n");
            }
            break;
        case XML_DTD_NODE:
            xmlCtxtDumpDtdNode(ctxt, (xmlDtdPtr) node);
            return;
        case XML_ELEMENT_DECL:
            xmlCtxtDumpElemDecl(ctxt, (xmlElementPtr) node);
            return;
        case XML_ATTRIBUTE_DECL:
            xmlCtxtDumpAttrDecl(ctxt, (xmlAttributePtr) node);
            return;
        case XML_ENTITY_DECL:
            xmlCtxtDumpEntityDecl(ctxt, (xmlEntityPtr) node);
            return;
        case XML_NAMESPACE_DECL:
            xmlCtxtDumpNamespace(ctxt, (xmlNsPtr) node);
            return;
        case XML_XINCLUDE_START:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "INCLUDE START\n");
            }
            return;
        case XML_XINCLUDE_END:
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "INCLUDE END\n");
            }
            return;
        default:
            if (!ctxt->check)
                xmlCtxtDumpSpaces(ctxt);
	    xmlDebugErr2(ctxt, XML_CHECK_UNKNOWN_NODE,
	                "Unknown node type %d\n", node->type);
            return;
    }
    if (node->doc == NULL) {
        if (!ctxt->check) {
            xmlCtxtDumpSpaces(ctxt);
        }
        fprintf(ctxt->output, "PBM: doc == NULL !!!\n");
    }
    ctxt->depth++;
    if ((node->type == XML_ELEMENT_NODE) && (node->nsDef != NULL))
        xmlCtxtDumpNamespaceList(ctxt, node->nsDef);
    if ((node->type == XML_ELEMENT_NODE) && (node->properties != NULL))
        xmlCtxtDumpAttrList(ctxt, node->properties);
    if (node->type != XML_ENTITY_REF_NODE) {
        if ((node->type != XML_ELEMENT_NODE) && (node->content != NULL)) {
            if (!ctxt->check) {
                xmlCtxtDumpSpaces(ctxt);
                fprintf(ctxt->output, "content=");
                xmlCtxtDumpString(ctxt, node->content);
                fprintf(ctxt->output, "\n");
            }
        }
    } else {
        xmlEntityPtr ent;

        ent = xmlGetDocEntity(node->doc, node->name);
        if (ent != NULL)
            xmlCtxtDumpEntity(ctxt, ent);
    }
    ctxt->depth--;

    /*
     * Do a bit of checking
     */
    xmlCtxtGenericNodeCheck(ctxt, node);
}

/**
 * xmlCtxtDumpNode:
 * @output:  the FILE * for the output
 * @node:  the node
 * @depth:  the indentation level.
 *
 * Dumps debug information for the element node, it is recursive
 */
static void
xmlCtxtDumpNode(xmlDebugCtxtPtr ctxt, xmlNodePtr node)
{
    if (node == NULL) {
        if (!ctxt->check) {
            xmlCtxtDumpSpaces(ctxt);
            fprintf(ctxt->output, "node is NULL\n");
        }
        return;
    }
    xmlCtxtDumpOneNode(ctxt, node);
    if ((node->type != XML_NAMESPACE_DECL) &&
        (node->children != NULL) && (node->type != XML_ENTITY_REF_NODE)) {
        ctxt->depth++;
        xmlCtxtDumpNodeList(ctxt, node->children);
        ctxt->depth--;
    }
}

/**
 * xmlCtxtDumpNodeList:
 * @output:  the FILE * for the output
 * @node:  the node list
 * @depth:  the indentation level.
 *
 * Dumps debug information for the list of element node, it is recursive
 */
static void
xmlCtxtDumpNodeList(xmlDebugCtxtPtr ctxt, xmlNodePtr node)
{
    while (node != NULL) {
        xmlCtxtDumpNode(ctxt, node);
        node = node->next;
    }
}

static void
xmlCtxtDumpDocHead(xmlDebugCtxtPtr ctxt, xmlDocPtr doc)
{
    if (doc == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "DOCUMENT == NULL !\n");
        return;
    }
    ctxt->node = (xmlNodePtr) doc;

    switch (doc->type) {
        case XML_ELEMENT_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_ELEMENT,
	                "Misplaced ELEMENT node\n");
            break;
        case XML_ATTRIBUTE_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_ATTRIBUTE,
	                "Misplaced ATTRIBUTE node\n");
            break;
        case XML_TEXT_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_TEXT,
	                "Misplaced TEXT node\n");
            break;
        case XML_CDATA_SECTION_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_CDATA,
	                "Misplaced CDATA node\n");
            break;
        case XML_ENTITY_REF_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_ENTITYREF,
	                "Misplaced ENTITYREF node\n");
            break;
        case XML_ENTITY_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_ENTITY,
	                "Misplaced ENTITY node\n");
            break;
        case XML_PI_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_PI,
	                "Misplaced PI node\n");
            break;
        case XML_COMMENT_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_COMMENT,
	                "Misplaced COMMENT node\n");
            break;
        case XML_DOCUMENT_NODE:
	    if (!ctxt->check)
		fprintf(ctxt->output, "DOCUMENT\n");
            break;
        case XML_HTML_DOCUMENT_NODE:
	    if (!ctxt->check)
		fprintf(ctxt->output, "HTML DOCUMENT\n");
            break;
        case XML_DOCUMENT_TYPE_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_DOCTYPE,
	                "Misplaced DOCTYPE node\n");
            break;
        case XML_DOCUMENT_FRAG_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_FRAGMENT,
	                "Misplaced FRAGMENT node\n");
            break;
        case XML_NOTATION_NODE:
	    xmlDebugErr(ctxt, XML_CHECK_FOUND_NOTATION,
	                "Misplaced NOTATION node\n");
            break;
        default:
	    xmlDebugErr2(ctxt, XML_CHECK_UNKNOWN_NODE,
	                "Unknown node type %d\n", doc->type);
    }
}

/**
 * xmlCtxtDumpDocumentHead:
 * @output:  the FILE * for the output
 * @doc:  the document
 *
 * Dumps debug information cncerning the document, not recursive
 */
static void
xmlCtxtDumpDocumentHead(xmlDebugCtxtPtr ctxt, xmlDocPtr doc)
{
    if (doc == NULL) return;
    xmlCtxtDumpDocHead(ctxt, doc);
    if (!ctxt->check) {
        if (doc->name != NULL) {
            fprintf(ctxt->output, "name=");
            xmlCtxtDumpString(ctxt, BAD_CAST doc->name);
            fprintf(ctxt->output, "\n");
        }
        if (doc->version != NULL) {
            fprintf(ctxt->output, "version=");
            xmlCtxtDumpString(ctxt, doc->version);
            fprintf(ctxt->output, "\n");
        }
        if (doc->encoding != NULL) {
            fprintf(ctxt->output, "encoding=");
            xmlCtxtDumpString(ctxt, doc->encoding);
            fprintf(ctxt->output, "\n");
        }
        if (doc->URL != NULL) {
            fprintf(ctxt->output, "URL=");
            xmlCtxtDumpString(ctxt, doc->URL);
            fprintf(ctxt->output, "\n");
        }
        if (doc->standalone)
            fprintf(ctxt->output, "standalone=true\n");
    }
    if (doc->oldNs != NULL)
        xmlCtxtDumpNamespaceList(ctxt, doc->oldNs);
}

/**
 * xmlCtxtDumpDocument:
 * @output:  the FILE * for the output
 * @doc:  the document
 *
 * Dumps debug information for the document, it's recursive
 */
static void
xmlCtxtDumpDocument(xmlDebugCtxtPtr ctxt, xmlDocPtr doc)
{
    if (doc == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "DOCUMENT == NULL !\n");
        return;
    }
    xmlCtxtDumpDocumentHead(ctxt, doc);
    if (((doc->type == XML_DOCUMENT_NODE) ||
         (doc->type == XML_HTML_DOCUMENT_NODE))
        && (doc->children != NULL)) {
        ctxt->depth++;
        xmlCtxtDumpNodeList(ctxt, doc->children);
        ctxt->depth--;
    }
}

static void
xmlCtxtDumpEntityCallback(xmlEntityPtr cur, xmlDebugCtxtPtr ctxt)
{
    if (cur == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "Entity is NULL");
        return;
    }
    if (!ctxt->check) {
        fprintf(ctxt->output, "%s : ", (char *) cur->name);
        switch (cur->etype) {
            case XML_INTERNAL_GENERAL_ENTITY:
                fprintf(ctxt->output, "INTERNAL GENERAL, ");
                break;
            case XML_EXTERNAL_GENERAL_PARSED_ENTITY:
                fprintf(ctxt->output, "EXTERNAL PARSED, ");
                break;
            case XML_EXTERNAL_GENERAL_UNPARSED_ENTITY:
                fprintf(ctxt->output, "EXTERNAL UNPARSED, ");
                break;
            case XML_INTERNAL_PARAMETER_ENTITY:
                fprintf(ctxt->output, "INTERNAL PARAMETER, ");
                break;
            case XML_EXTERNAL_PARAMETER_ENTITY:
                fprintf(ctxt->output, "EXTERNAL PARAMETER, ");
                break;
            default:
		xmlDebugErr2(ctxt, XML_CHECK_ENTITY_TYPE,
			     "Unknown entity type %d\n", cur->etype);
        }
        if (cur->ExternalID != NULL)
            fprintf(ctxt->output, "ID \"%s\"", (char *) cur->ExternalID);
        if (cur->SystemID != NULL)
            fprintf(ctxt->output, "SYSTEM \"%s\"", (char *) cur->SystemID);
        if (cur->orig != NULL)
            fprintf(ctxt->output, "\n orig \"%s\"", (char *) cur->orig);
        if ((cur->type != XML_ELEMENT_NODE) && (cur->content != NULL))
            fprintf(ctxt->output, "\n content \"%s\"",
                    (char *) cur->content);
        fprintf(ctxt->output, "\n");
    }
}

/**
 * xmlCtxtDumpEntities:
 * @output:  the FILE * for the output
 * @doc:  the document
 *
 * Dumps debug information for all the entities in use by the document
 */
static void
xmlCtxtDumpEntities(xmlDebugCtxtPtr ctxt, xmlDocPtr doc)
{
    if (doc == NULL) return;
    xmlCtxtDumpDocHead(ctxt, doc);
    if ((doc->intSubset != NULL) && (doc->intSubset->entities != NULL)) {
        xmlEntitiesTablePtr table = (xmlEntitiesTablePtr)
            doc->intSubset->entities;

        if (!ctxt->check)
            fprintf(ctxt->output, "Entities in internal subset\n");
        xmlHashScan(table, (xmlHashScanner) xmlCtxtDumpEntityCallback,
                    ctxt);
    } else
        fprintf(ctxt->output, "No entities in internal subset\n");
    if ((doc->extSubset != NULL) && (doc->extSubset->entities != NULL)) {
        xmlEntitiesTablePtr table = (xmlEntitiesTablePtr)
            doc->extSubset->entities;

        if (!ctxt->check)
            fprintf(ctxt->output, "Entities in external subset\n");
        xmlHashScan(table, (xmlHashScanner) xmlCtxtDumpEntityCallback,
                    ctxt);
    } else if (!ctxt->check)
        fprintf(ctxt->output, "No entities in external subset\n");
}

/**
 * xmlCtxtDumpDTD:
 * @output:  the FILE * for the output
 * @dtd:  the DTD
 *
 * Dumps debug information for the DTD
 */
static void
xmlCtxtDumpDTD(xmlDebugCtxtPtr ctxt, xmlDtdPtr dtd)
{
    if (dtd == NULL) {
        if (!ctxt->check)
            fprintf(ctxt->output, "DTD is NULL\n");
        return;
    }
    xmlCtxtDumpDtdNode(ctxt, dtd);
    if (dtd->children == NULL)
        fprintf(ctxt->output, "    DTD is empty\n");
    else {
        ctxt->depth++;
        xmlCtxtDumpNodeList(ctxt, dtd->children);
        ctxt->depth--;
    }
}

/************************************************************************
 *									*
 *			Public entry points for dump			*
 *									*
 ************************************************************************/

/**
 * xmlDebugDumpString:
 * @output:  the FILE * for the output
 * @str:  the string
 *
 * Dumps informations about the string, shorten it if necessary
 */
void
xmlDebugDumpString(FILE * output, const xmlChar * str)
{
    int i;

    if (output == NULL)
	output = stdout;
    if (str == NULL) {
        fprintf(output, "(NULL)");
        return;
    }
    for (i = 0; i < 40; i++)
        if (str[i] == 0)
            return;
        else if (IS_BLANK_CH(str[i]))
            fputc(' ', output);
        else if (str[i] >= 0x80)
            fprintf(output, "#%X", str[i]);
        else
            fputc(str[i], output);
    fprintf(output, "...");
}

/**
 * xmlDebugDumpAttr:
 * @output:  the FILE * for the output
 * @attr:  the attribute
 * @depth:  the indentation level.
 *
 * Dumps debug information for the attribute
 */
void
xmlDebugDumpAttr(FILE *output, xmlAttrPtr attr, int depth) {
    xmlDebugCtxt ctxt;

    if (output == NULL) return;
    xmlCtxtDumpInitCtxt(&ctxt);
    ctxt.output = output;
    ctxt.depth = depth;
    xmlCtxtDumpAttr(&ctxt, attr);
    xmlCtxtDumpCleanCtxt(&ctxt);
}


/**
 * xmlDebugDumpEntities:
 * @output:  the FILE * for the output
 * @doc:  the document
 *
 * Dumps debug information for all the entities in use by the document
 */
void
xmlDebugDumpEntities(FILE * output, xmlDocPtr doc)
{
    xmlDebugCtxt ctxt;

    if (output == NULL) return;
    xmlCtxtDumpInitCtxt(&ctxt);
    ctxt.output = output;
    xmlCtxtDumpEntities(&ctxt, doc);
    xmlCtxtDumpCleanCtxt(&ctxt);
}

/**
 * xmlDebugDumpAttrList:
 * @output:  the FILE * for the output
 * @attr:  the attribute list
 * @depth:  the indentation level.
 *
 * Dumps debug information for the attribute list
 */
void
xmlDebugDumpAttrList(FILE * output, xmlAttrPtr attr, int depth)
{
    xmlDebugCtxt ctxt;

    if (output == NULL) return;
    xmlCtxtDumpInitCtxt(&ctxt);
    ctxt.output = output;
    ctxt.depth = depth;
    xmlCtxtDumpAttrList(&ctxt, attr);
    xmlCtxtDumpCleanCtxt(&ctxt);
}

/**
 * xmlDebugDumpOneNode:
 * @output:  the FILE * for the output
 * @node:  the node
 * @depth:  the indentation level.
 *
 * Dumps debug information for the element node, it is not recursive
 */
void
xmlDebugDumpOneNode(FILE * output, xmlNodePtr node, int depth)
{
    xmlDebugCtxt ctxt;

    if (output == NULL) return;
    xmlCtxtDumpInitCtxt(&ctxt);
    ctxt.output = output;
    ctxt.depth = depth;
    xmlCtxtDumpOneNode(&ctxt, node);
    xmlCtxtDumpCleanCtxt(&ctxt);
}

/**
 * xmlDebugDumpNode:
 * @output:  the FILE * for the output
 * @node:  the node
 * @depth:  the indentation level.
 *
 * Dumps debug information for the element node, it is recursive
 */
void
xmlDebugDumpNode(FILE * output, xmlNodePtr node, int depth)
{
    xmlDebugCtxt ctxt;

    if (output == NULL)
	output = stdout;
    xmlCtxtDumpInitCtxt(&ctxt);
    ctxt.output = output;
    ctxt.depth = depth;
    xmlCtxtDumpNode(&ctxt, node);
    xmlCtxtDumpCleanCtxt(&ctxt);
}

/**
 * xmlDebugDumpNodeList:
 * @output:  the FILE * for the output
 * @node:  the node list
 * @depth:  the indentation level.
 *
 * Dumps debug information for the list of element node, it is recursive
 */
void
xmlDebugDumpNodeList(FILE * output, xmlNodePtr node, int depth)
{
    xmlDebugCtxt ctxt;

    if (output == NULL)
	output = stdout;
    xmlCtxtDumpInitCtxt(&ctxt);
    ctxt.output = output;
    ctxt.depth = depth;
    xmlCtxtDumpNodeList(&ctxt, node);
    xmlCtxtDumpCleanCtxt(&ctxt);
}

/**
 * xmlDebugDumpDocumentHead:
 * @output:  the FILE * for the output
 * @doc:  the document
 *
 * Dumps debug information cncerning the document, not recursive
 */
void
xmlDebugDumpDocumentHead(FILE * output, xmlDocPtr doc)
{
    xmlDebugCtxt ctxt;

    if (output == NULL)
	output = stdout;
    xmlCtxtDumpInitCtxt(&ctxt);
    ctxt.options |= DUMP_TEXT_TYPE;
    ctxt.output = output;
    xmlCtxtDumpDocumentHead(&ctxt, doc);
    xmlCtxtDumpCleanCtxt(&ctxt);
}

/**
 * xmlDebugDumpDocument:
 * @output:  the FILE * for the output
 * @doc:  the document
 *
 * Dumps debug information for the document, it's recursive
 */
void
xmlDebugDumpDocument(FILE * output, xmlDocPtr doc)
{
    xmlDebugCtxt ctxt;

    if (output == NULL)
	output = stdout;
    xmlCtxtDumpInitCtxt(&ctxt);
    ctxt.options |= DUMP_TEXT_TYPE;
    ctxt.output = output;
    xmlCtxtDumpDocument(&ctxt, doc);
    xmlCtxtDumpCleanCtxt(&ctxt);
}

/**
 * xmlDebugDumpDTD:
 * @output:  the FILE * for the output
 * @dtd:  the DTD
 *
 * Dumps debug information for the DTD
 */
void
xmlDebugDumpDTD(FILE * output, xmlDtdPtr dtd)
{
    xmlDebugCtxt ctxt;

    if (output == NULL)
	output = stdout;
    xmlCtxtDumpInitCtxt(&ctxt);
    ctxt.options |= DUMP_TEXT_TYPE;
    ctxt.output = output;
    xmlCtxtDumpDTD(&ctxt, dtd);
    xmlCtxtDumpCleanCtxt(&ctxt);
}

/************************************************************************
 *									*
 *			Public entry points for checkings		*
 *									*
 ************************************************************************/

/**
 * xmlDebugCheckDocument:
 * @output:  the FILE * for the output
 * @doc:  the document
 *
 * Check the document for potential content problems, and output
 * the errors to @output
 *
 * Returns the number of errors found
 */
int
xmlDebugCheckDocument(FILE * output, xmlDocPtr doc)
{
    xmlDebugCtxt ctxt;

    if (output == NULL)
	output = stdout;
    xmlCtxtDumpInitCtxt(&ctxt);
    ctxt.output = output;
    ctxt.check = 1;
    xmlCtxtDumpDocument(&ctxt, doc);
    xmlCtxtDumpCleanCtxt(&ctxt);
    return(ctxt.errors);
}

/************************************************************************
 *									*
 *			Helpers for Shell				*
 *									*
 ************************************************************************/

/**
 * xmlLsCountNode:
 * @node:  the node to count
 *
 * Count the children of @node.
 *
 * Returns the number of children of @node.
 */
int
xmlLsCountNode(xmlNodePtr node) {
    int ret = 0;
    xmlNodePtr list = NULL;

    if (node == NULL)
	return(0);

    switch (node->type) {
	case XML_ELEMENT_NODE:
	    list = node->children;
	    break;
	case XML_DOCUMENT_NODE:
	case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
	case XML_DOCB_DOCUMENT_NODE:
#endif
	    list = ((xmlDocPtr) node)->children;
	    break;
	case XML_ATTRIBUTE_NODE:
	    list = ((xmlAttrPtr) node)->children;
	    break;
	case XML_TEXT_NODE:
	case XML_CDATA_SECTION_NODE:
	case XML_PI_NODE:
	case XML_COMMENT_NODE:
	    if (node->content != NULL) {
		ret = xmlStrlen(node->content);
            }
	    break;
	case XML_ENTITY_REF_NODE:
	case XML_DOCUMENT_TYPE_NODE:
	case XML_ENTITY_NODE:
	case XML_DOCUMENT_FRAG_NODE:
	case XML_NOTATION_NODE:
	case XML_DTD_NODE:
        case XML_ELEMENT_DECL:
        case XML_ATTRIBUTE_DECL:
        case XML_ENTITY_DECL:
	case XML_NAMESPACE_DECL:
	case XML_XINCLUDE_START:
	case XML_XINCLUDE_END:
	    ret = 1;
	    break;
    }
    for (;list != NULL;ret++)
        list = list->next;
    return(ret);
}

/**
 * xmlLsOneNode:
 * @output:  the FILE * for the output
 * @node:  the node to dump
 *
 * Dump to @output the type and name of @node.
 */
void
xmlLsOneNode(FILE *output, xmlNodePtr node) {
    if (output == NULL) return;
    if (node == NULL) {
	fprintf(output, "NULL\n");
	return;
    }
    switch (node->type) {
	case XML_ELEMENT_NODE:
	    fprintf(output, "-");
	    break;
	case XML_ATTRIBUTE_NODE:
	    fprintf(output, "a");
	    break;
	case XML_TEXT_NODE:
	    fprintf(output, "t");
	    break;
	case XML_CDATA_SECTION_NODE:
	    fprintf(output, "C");
	    break;
	case XML_ENTITY_REF_NODE:
	    fprintf(output, "e");
	    break;
	case XML_ENTITY_NODE:
	    fprintf(output, "E");
	    break;
	case XML_PI_NODE:
	    fprintf(output, "p");
	    break;
	case XML_COMMENT_NODE:
	    fprintf(output, "c");
	    break;
	case XML_DOCUMENT_NODE:
	    fprintf(output, "d");
	    break;
	case XML_HTML_DOCUMENT_NODE:
	    fprintf(output, "h");
	    break;
	case XML_DOCUMENT_TYPE_NODE:
	    fprintf(output, "T");
	    break;
	case XML_DOCUMENT_FRAG_NODE:
	    fprintf(output, "F");
	    break;
	case XML_NOTATION_NODE:
	    fprintf(output, "N");
	    break;
	case XML_NAMESPACE_DECL:
	    fprintf(output, "n");
	    break;
	default:
	    fprintf(output, "?");
    }
    if (node->type != XML_NAMESPACE_DECL) {
	if (node->properties != NULL)
	    fprintf(output, "a");
	else
	    fprintf(output, "-");
	if (node->nsDef != NULL)
	    fprintf(output, "n");
	else
	    fprintf(output, "-");
    }

    fprintf(output, " %8d ", xmlLsCountNode(node));

    switch (node->type) {
	case XML_ELEMENT_NODE:
	    if (node->name != NULL) {
                if ((node->ns != NULL) && (node->ns->prefix != NULL))
                    fprintf(output, "%s:", node->ns->prefix);
		fprintf(output, "%s", (const char *) node->name);
            }
	    break;
	case XML_ATTRIBUTE_NODE:
	    if (node->name != NULL)
		fprintf(output, "%s", (const char *) node->name);
	    break;
	case XML_TEXT_NODE:
	    if (node->content != NULL) {
		xmlDebugDumpString(output, node->content);
            }
	    break;
	case XML_CDATA_SECTION_NODE:
	    break;
	case XML_ENTITY_REF_NODE:
	    if (node->name != NULL)
		fprintf(output, "%s", (const char *) node->name);
	    break;
	case XML_ENTITY_NODE:
	    if (node->name != NULL)
		fprintf(output, "%s", (const char *) node->name);
	    break;
	case XML_PI_NODE:
	    if (node->name != NULL)
		fprintf(output, "%s", (const char *) node->name);
	    break;
	case XML_COMMENT_NODE:
	    break;
	case XML_DOCUMENT_NODE:
	    break;
	case XML_HTML_DOCUMENT_NODE:
	    break;
	case XML_DOCUMENT_TYPE_NODE:
	    break;
	case XML_DOCUMENT_FRAG_NODE:
	    break;
	case XML_NOTATION_NODE:
	    break;
	case XML_NAMESPACE_DECL: {
	    xmlNsPtr ns = (xmlNsPtr) node;

	    if (ns->prefix == NULL)
		fprintf(output, "default -> %s", (char *)ns->href);
	    else
		fprintf(output, "%s -> %s", (char *)ns->prefix,
			(char *)ns->href);
	    break;
	}
	default:
	    if (node->name != NULL)
		fprintf(output, "%s", (const char *) node->name);
    }
    fprintf(output, "\n");
}

/**
 * xmlBoolToText:
 * @boolval: a bool to turn into text
 *
 * Convenient way to turn bool into text
 *
 * Returns a pointer to either "True" or "False"
 */
const char *
xmlBoolToText(int boolval)
{
    if (boolval)
        return("True");
    else
        return("False");
}

#ifdef LIBXML_XPATH_ENABLED
/****************************************************************
 *								*
 *		The XML shell related functions			*
 *								*
 ****************************************************************/



/*
 * TODO: Improvement/cleanups for the XML shell
 *     - allow to shell out an editor on a subpart
 *     - cleanup function registrations (with help) and calling
 *     - provide registration routines
 */

/**
 * xmlShellPrintXPathError:
 * @errorType: valid xpath error id
 * @arg: the argument that cause xpath to fail
 *
 * Print the xpath error to libxml default error channel
 */
void
xmlShellPrintXPathError(int errorType, const char *arg)
{
    const char *default_arg = "Result";

    if (!arg)
        arg = default_arg;

    switch (errorType) {
        case XPATH_UNDEFINED:
            xmlGenericError(xmlGenericErrorContext,
                            "%s: no such node\n", arg);
            break;

        case XPATH_BOOLEAN:
            xmlGenericError(xmlGenericErrorContext,
                            "%s is a Boolean\n", arg);
            break;
        case XPATH_NUMBER:
            xmlGenericError(xmlGenericErrorContext,
                            "%s is a number\n", arg);
            break;
        case XPATH_STRING:
            xmlGenericError(xmlGenericErrorContext,
                            "%s is a string\n", arg);
            break;
        case XPATH_POINT:
            xmlGenericError(xmlGenericErrorContext,
                            "%s is a point\n", arg);
            break;
        case XPATH_RANGE:
            xmlGenericError(xmlGenericErrorContext,
                            "%s is a range\n", arg);
            break;
        case XPATH_LOCATIONSET:
            xmlGenericError(xmlGenericErrorContext,
                            "%s is a range\n", arg);
            break;
        case XPATH_USERS:
            xmlGenericError(xmlGenericErrorContext,
                            "%s is user-defined\n", arg);
            break;
        case XPATH_XSLT_TREE:
            xmlGenericError(xmlGenericErrorContext,
                            "%s is an XSLT value tree\n", arg);
            break;
    }
#if 0
    xmlGenericError(xmlGenericErrorContext,
                    "Try casting the result string function (xpath builtin)\n",
                    arg);
#endif
}


#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlShellPrintNodeCtxt:
 * @ctxt : a non-null shell context
 * @node : a non-null node to print to the output FILE
 *
 * Print node to the output FILE
 */
static void
xmlShellPrintNodeCtxt(xmlShellCtxtPtr ctxt,xmlNodePtr node)
{
    FILE *fp;

    if (!node)
        return;
    if (ctxt == NULL)
	fp = stdout;
    else
	fp = ctxt->output;

    if (node->type == XML_DOCUMENT_NODE)
        xmlDocDump(fp, (xmlDocPtr) node);
    else if (node->type == XML_ATTRIBUTE_NODE)
        xmlDebugDumpAttrList(fp, (xmlAttrPtr) node, 0);
    else
        xmlElemDump(fp, node->doc, node);

    fprintf(fp, "\n");
}

/**
 * xmlShellPrintNode:
 * @node : a non-null node to print to the output FILE
 *
 * Print node to the output FILE
 */
void
xmlShellPrintNode(xmlNodePtr node)
{
    xmlShellPrintNodeCtxt(NULL, node);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlShellPrintXPathResultCtxt:
 * @ctxt: a valid shell context
 * @list: a valid result generated by an xpath evaluation
 *
 * Prints result to the output FILE
 */
static void
xmlShellPrintXPathResultCtxt(xmlShellCtxtPtr ctxt,xmlXPathObjectPtr list)
{
    if (!ctxt)
       return;

    if (list != NULL) {
        switch (list->type) {
            case XPATH_NODESET:{
#ifdef LIBXML_OUTPUT_ENABLED
                    int indx;

                    if (list->nodesetval) {
                        for (indx = 0; indx < list->nodesetval->nodeNr;
                             indx++) {
                            xmlShellPrintNodeCtxt(ctxt,
				    list->nodesetval->nodeTab[indx]);
                        }
                    } else {
                        xmlGenericError(xmlGenericErrorContext,
                                        "Empty node set\n");
                    }
                    break;
#else
		    xmlGenericError(xmlGenericErrorContext,
				    "Node set\n");
#endif /* LIBXML_OUTPUT_ENABLED */
                }
            case XPATH_BOOLEAN:
                xmlGenericError(xmlGenericErrorContext,
                                "Is a Boolean:%s\n",
                                xmlBoolToText(list->boolval));
                break;
            case XPATH_NUMBER:
                xmlGenericError(xmlGenericErrorContext,
                                "Is a number:%0g\n", list->floatval);
                break;
            case XPATH_STRING:
                xmlGenericError(xmlGenericErrorContext,
                                "Is a string:%s\n", list->stringval);
                break;

            default:
                xmlShellPrintXPathError(list->type, NULL);
        }
    }
}

/**
 * xmlShellPrintXPathResult:
 * @list: a valid result generated by an xpath evaluation
 *
 * Prints result to the output FILE
 */
void
xmlShellPrintXPathResult(xmlXPathObjectPtr list)
{
    xmlShellPrintXPathResultCtxt(NULL, list);
}

/**
 * xmlShellList:
 * @ctxt:  the shell context
 * @arg:  unused
 * @node:  a node
 * @node2:  unused
 *
 * Implements the XML shell function "ls"
 * Does an Unix like listing of the given node (like a directory)
 *
 * Returns 0
 */
int
xmlShellList(xmlShellCtxtPtr ctxt,
             char *arg ATTRIBUTE_UNUSED, xmlNodePtr node,
             xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlNodePtr cur;
    if (!ctxt)
        return (0);
    if (node == NULL) {
	fprintf(ctxt->output, "NULL\n");
	return (0);
    }
    if ((node->type == XML_DOCUMENT_NODE) ||
        (node->type == XML_HTML_DOCUMENT_NODE)) {
        cur = ((xmlDocPtr) node)->children;
    } else if (node->type == XML_NAMESPACE_DECL) {
        xmlLsOneNode(ctxt->output, node);
        return (0);
    } else if (node->children != NULL) {
        cur = node->children;
    } else {
        xmlLsOneNode(ctxt->output, node);
        return (0);
    }
    while (cur != NULL) {
        xmlLsOneNode(ctxt->output, cur);
        cur = cur->next;
    }
    return (0);
}

/**
 * xmlShellBase:
 * @ctxt:  the shell context
 * @arg:  unused
 * @node:  a node
 * @node2:  unused
 *
 * Implements the XML shell function "base"
 * dumps the current XML base of the node
 *
 * Returns 0
 */
int
xmlShellBase(xmlShellCtxtPtr ctxt,
             char *arg ATTRIBUTE_UNUSED, xmlNodePtr node,
             xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlChar *base;
    if (!ctxt)
        return 0;
    if (node == NULL) {
	fprintf(ctxt->output, "NULL\n");
	return (0);
    }

    base = xmlNodeGetBase(node->doc, node);

    if (base == NULL) {
        fprintf(ctxt->output, " No base found !!!\n");
    } else {
        fprintf(ctxt->output, "%s\n", base);
        xmlFree(base);
    }
    return (0);
}

#ifdef LIBXML_TREE_ENABLED
/**
 * xmlShellSetBase:
 * @ctxt:  the shell context
 * @arg:  the new base
 * @node:  a node
 * @node2:  unused
 *
 * Implements the XML shell function "setbase"
 * change the current XML base of the node
 *
 * Returns 0
 */
static int
xmlShellSetBase(xmlShellCtxtPtr ctxt ATTRIBUTE_UNUSED,
             char *arg ATTRIBUTE_UNUSED, xmlNodePtr node,
             xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlNodeSetBase(node, (xmlChar*) arg);
    return (0);
}
#endif

#ifdef LIBXML_XPATH_ENABLED
/**
 * xmlShellRegisterNamespace:
 * @ctxt:  the shell context
 * @arg:  a string in prefix=nsuri format
 * @node:  unused
 * @node2:  unused
 *
 * Implements the XML shell function "setns"
 * register/unregister a prefix=namespace pair
 * on the XPath context
 *
 * Returns 0 on success and a negative value otherwise.
 */
static int
xmlShellRegisterNamespace(xmlShellCtxtPtr ctxt, char *arg,
      xmlNodePtr node ATTRIBUTE_UNUSED, xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlChar* nsListDup;
    xmlChar* prefix;
    xmlChar* href;
    xmlChar* next;

    nsListDup = xmlStrdup((xmlChar *) arg);
    next = nsListDup;
    while(next != NULL) {
	/* skip spaces */
	/*while((*next) == ' ') next++;*/
	if((*next) == '\0') break;

	/* find prefix */
	prefix = next;
	next = (xmlChar*)xmlStrchr(next, '=');
	if(next == NULL) {
	    fprintf(ctxt->output, "setns: prefix=[nsuri] required\n");
	    xmlFree(nsListDup);
	    return(-1);
	}
	*(next++) = '\0';

	/* find href */
	href = next;
	next = (xmlChar*)xmlStrchr(next, ' ');
	if(next != NULL) {
	    *(next++) = '\0';
	}

	/* do register namespace */
	if(xmlXPathRegisterNs(ctxt->pctxt, prefix, href) != 0) {
	    fprintf(ctxt->output,"Error: unable to register NS with prefix=\"%s\" and href=\"%s\"\n", prefix, href);
	    xmlFree(nsListDup);
	    return(-1);
	}
    }

    xmlFree(nsListDup);
    return(0);
}
/**
 * xmlShellRegisterRootNamespaces:
 * @ctxt:  the shell context
 * @arg:  unused
 * @node:  the root element
 * @node2:  unused
 *
 * Implements the XML shell function "setrootns"
 * which registers all namespaces declarations found on the root element.
 *
 * Returns 0 on success and a negative value otherwise.
 */
static int
xmlShellRegisterRootNamespaces(xmlShellCtxtPtr ctxt, char *arg ATTRIBUTE_UNUSED,
      xmlNodePtr root, xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlNsPtr ns;

    if ((root == NULL) || (root->type != XML_ELEMENT_NODE) ||
        (root->nsDef == NULL) || (ctxt == NULL) || (ctxt->pctxt == NULL))
	return(-1);
    ns = root->nsDef;
    while (ns != NULL) {
        if (ns->prefix == NULL)
	    xmlXPathRegisterNs(ctxt->pctxt, BAD_CAST "defaultns", ns->href);
	else
	    xmlXPathRegisterNs(ctxt->pctxt, ns->prefix, ns->href);
        ns = ns->next;
    }
    return(0);
}
#endif

/**
 * xmlShellGrep:
 * @ctxt:  the shell context
 * @arg:  the string or regular expression to find
 * @node:  a node
 * @node2:  unused
 *
 * Implements the XML shell function "grep"
 * dumps informations about the node (namespace, attributes, content).
 *
 * Returns 0
 */
static int
xmlShellGrep(xmlShellCtxtPtr ctxt ATTRIBUTE_UNUSED,
            char *arg, xmlNodePtr node, xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    if (!ctxt)
        return (0);
    if (node == NULL)
	return (0);
    if (arg == NULL)
	return (0);
#ifdef LIBXML_REGEXP_ENABLED
    if ((xmlStrchr((xmlChar *) arg, '?')) ||
	(xmlStrchr((xmlChar *) arg, '*')) ||
	(xmlStrchr((xmlChar *) arg, '.')) ||
	(xmlStrchr((xmlChar *) arg, '['))) {
    }
#endif
    while (node != NULL) {
        if (node->type == XML_COMMENT_NODE) {
	    if (xmlStrstr(node->content, (xmlChar *) arg)) {

		fprintf(ctxt->output, "%s : ", xmlGetNodePath(node));
                xmlShellList(ctxt, NULL, node, NULL);
	    }
        } else if (node->type == XML_TEXT_NODE) {
	    if (xmlStrstr(node->content, (xmlChar *) arg)) {

		fprintf(ctxt->output, "%s : ", xmlGetNodePath(node->parent));
                xmlShellList(ctxt, NULL, node->parent, NULL);
	    }
        }

        /*
         * Browse the full subtree, deep first
         */

        if ((node->type == XML_DOCUMENT_NODE) ||
            (node->type == XML_HTML_DOCUMENT_NODE)) {
            node = ((xmlDocPtr) node)->children;
        } else if ((node->children != NULL)
                   && (node->type != XML_ENTITY_REF_NODE)) {
            /* deep first */
            node = node->children;
        } else if (node->next != NULL) {
            /* then siblings */
            node = node->next;
        } else {
            /* go up to parents->next if needed */
            while (node != NULL) {
                if (node->parent != NULL) {
                    node = node->parent;
                }
                if (node->next != NULL) {
                    node = node->next;
                    break;
                }
                if (node->parent == NULL) {
                    node = NULL;
                    break;
                }
            }
	}
    }
    return (0);
}

/**
 * xmlShellDir:
 * @ctxt:  the shell context
 * @arg:  unused
 * @node:  a node
 * @node2:  unused
 *
 * Implements the XML shell function "dir"
 * dumps informations about the node (namespace, attributes, content).
 *
 * Returns 0
 */
int
xmlShellDir(xmlShellCtxtPtr ctxt ATTRIBUTE_UNUSED,
            char *arg ATTRIBUTE_UNUSED, xmlNodePtr node,
            xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    if (!ctxt)
        return (0);
    if (node == NULL) {
	fprintf(ctxt->output, "NULL\n");
	return (0);
    }
    if ((node->type == XML_DOCUMENT_NODE) ||
        (node->type == XML_HTML_DOCUMENT_NODE)) {
        xmlDebugDumpDocumentHead(ctxt->output, (xmlDocPtr) node);
    } else if (node->type == XML_ATTRIBUTE_NODE) {
        xmlDebugDumpAttr(ctxt->output, (xmlAttrPtr) node, 0);
    } else {
        xmlDebugDumpOneNode(ctxt->output, node, 0);
    }
    return (0);
}

/**
 * xmlShellSetContent:
 * @ctxt:  the shell context
 * @value:  the content as a string
 * @node:  a node
 * @node2:  unused
 *
 * Implements the XML shell function "dir"
 * dumps informations about the node (namespace, attributes, content).
 *
 * Returns 0
 */
static int
xmlShellSetContent(xmlShellCtxtPtr ctxt ATTRIBUTE_UNUSED,
            char *value, xmlNodePtr node,
            xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlNodePtr results;
    xmlParserErrors ret;

    if (!ctxt)
        return (0);
    if (node == NULL) {
	fprintf(ctxt->output, "NULL\n");
	return (0);
    }
    if (value == NULL) {
        fprintf(ctxt->output, "NULL\n");
	return (0);
    }

    ret = xmlParseInNodeContext(node, value, strlen(value), 0, &results);
    if (ret == XML_ERR_OK) {
	if (node->children != NULL) {
	    xmlFreeNodeList(node->children);
	    node->children = NULL;
	    node->last = NULL;
	}
	xmlAddChildList(node, results);
    } else {
        fprintf(ctxt->output, "failed to parse content\n");
    }
    return (0);
}

#ifdef LIBXML_SCHEMAS_ENABLED
/**
 * xmlShellRNGValidate:
 * @ctxt:  the shell context
 * @schemas:  the path to the Relax-NG schemas
 * @node:  a node
 * @node2:  unused
 *
 * Implements the XML shell function "relaxng"
 * validating the instance against a Relax-NG schemas
 *
 * Returns 0
 */
static int
xmlShellRNGValidate(xmlShellCtxtPtr sctxt, char *schemas,
            xmlNodePtr node ATTRIBUTE_UNUSED,
	    xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlRelaxNGPtr relaxngschemas;
    xmlRelaxNGParserCtxtPtr ctxt;
    xmlRelaxNGValidCtxtPtr vctxt;
    int ret;

    ctxt = xmlRelaxNGNewParserCtxt(schemas);
    xmlRelaxNGSetParserErrors(ctxt,
	    (xmlRelaxNGValidityErrorFunc) fprintf,
	    (xmlRelaxNGValidityWarningFunc) fprintf,
	    stderr);
    relaxngschemas = xmlRelaxNGParse(ctxt);
    xmlRelaxNGFreeParserCtxt(ctxt);
    if (relaxngschemas == NULL) {
	xmlGenericError(xmlGenericErrorContext,
		"Relax-NG schema %s failed to compile\n", schemas);
	return(-1);
    }
    vctxt = xmlRelaxNGNewValidCtxt(relaxngschemas);
    xmlRelaxNGSetValidErrors(vctxt,
	    (xmlRelaxNGValidityErrorFunc) fprintf,
	    (xmlRelaxNGValidityWarningFunc) fprintf,
	    stderr);
    ret = xmlRelaxNGValidateDoc(vctxt, sctxt->doc);
    if (ret == 0) {
	fprintf(stderr, "%s validates\n", sctxt->filename);
    } else if (ret > 0) {
	fprintf(stderr, "%s fails to validate\n", sctxt->filename);
    } else {
	fprintf(stderr, "%s validation generated an internal error\n",
	       sctxt->filename);
    }
    xmlRelaxNGFreeValidCtxt(vctxt);
    if (relaxngschemas != NULL)
	xmlRelaxNGFree(relaxngschemas);
    return(0);
}
#endif

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlShellCat:
 * @ctxt:  the shell context
 * @arg:  unused
 * @node:  a node
 * @node2:  unused
 *
 * Implements the XML shell function "cat"
 * dumps the serialization node content (XML or HTML).
 *
 * Returns 0
 */
int
xmlShellCat(xmlShellCtxtPtr ctxt, char *arg ATTRIBUTE_UNUSED,
            xmlNodePtr node, xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    if (!ctxt)
        return (0);
    if (node == NULL) {
	fprintf(ctxt->output, "NULL\n");
	return (0);
    }
    if (ctxt->doc->type == XML_HTML_DOCUMENT_NODE) {
#ifdef LIBXML_HTML_ENABLED
        if (node->type == XML_HTML_DOCUMENT_NODE)
            htmlDocDump(ctxt->output, (htmlDocPtr) node);
        else
            htmlNodeDumpFile(ctxt->output, ctxt->doc, node);
#else
        if (node->type == XML_DOCUMENT_NODE)
            xmlDocDump(ctxt->output, (xmlDocPtr) node);
        else
            xmlElemDump(ctxt->output, ctxt->doc, node);
#endif /* LIBXML_HTML_ENABLED */
    } else {
        if (node->type == XML_DOCUMENT_NODE)
            xmlDocDump(ctxt->output, (xmlDocPtr) node);
        else
            xmlElemDump(ctxt->output, ctxt->doc, node);
    }
    fprintf(ctxt->output, "\n");
    return (0);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlShellLoad:
 * @ctxt:  the shell context
 * @filename:  the file name
 * @node:  unused
 * @node2:  unused
 *
 * Implements the XML shell function "load"
 * loads a new document specified by the filename
 *
 * Returns 0 or -1 if loading failed
 */
int
xmlShellLoad(xmlShellCtxtPtr ctxt, char *filename,
             xmlNodePtr node ATTRIBUTE_UNUSED,
             xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlDocPtr doc;
    int html = 0;

    if ((ctxt == NULL) || (filename == NULL)) return(-1);
    if (ctxt->doc != NULL)
        html = (ctxt->doc->type == XML_HTML_DOCUMENT_NODE);

    if (html) {
#ifdef LIBXML_HTML_ENABLED
        doc = htmlParseFile(filename, NULL);
#else
        fprintf(ctxt->output, "HTML support not compiled in\n");
        doc = NULL;
#endif /* LIBXML_HTML_ENABLED */
    } else {
        doc = xmlReadFile(filename,NULL,0);
    }
    if (doc != NULL) {
        if (ctxt->loaded == 1) {
            xmlFreeDoc(ctxt->doc);
        }
        ctxt->loaded = 1;
#ifdef LIBXML_XPATH_ENABLED
        xmlXPathFreeContext(ctxt->pctxt);
#endif /* LIBXML_XPATH_ENABLED */
        xmlFree(ctxt->filename);
        ctxt->doc = doc;
        ctxt->node = (xmlNodePtr) doc;
#ifdef LIBXML_XPATH_ENABLED
        ctxt->pctxt = xmlXPathNewContext(doc);
#endif /* LIBXML_XPATH_ENABLED */
        ctxt->filename = (char *) xmlCanonicPath((xmlChar *) filename);
    } else
        return (-1);
    return (0);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlShellWrite:
 * @ctxt:  the shell context
 * @filename:  the file name
 * @node:  a node in the tree
 * @node2:  unused
 *
 * Implements the XML shell function "write"
 * Write the current node to the filename, it saves the serialization
 * of the subtree under the @node specified
 *
 * Returns 0 or -1 in case of error
 */
int
xmlShellWrite(xmlShellCtxtPtr ctxt, char *filename, xmlNodePtr node,
              xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    if (node == NULL)
        return (-1);
    if ((filename == NULL) || (filename[0] == 0)) {
        return (-1);
    }
#ifdef W_OK
    if (access((char *) filename, W_OK)) {
        xmlGenericError(xmlGenericErrorContext,
                        "Cannot write to %s\n", filename);
        return (-1);
    }
#endif
    switch (node->type) {
        case XML_DOCUMENT_NODE:
            if (xmlSaveFile((char *) filename, ctxt->doc) < -1) {
                xmlGenericError(xmlGenericErrorContext,
                                "Failed to write to %s\n", filename);
                return (-1);
            }
            break;
        case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_HTML_ENABLED
            if (htmlSaveFile((char *) filename, ctxt->doc) < 0) {
                xmlGenericError(xmlGenericErrorContext,
                                "Failed to write to %s\n", filename);
                return (-1);
            }
#else
            if (xmlSaveFile((char *) filename, ctxt->doc) < -1) {
                xmlGenericError(xmlGenericErrorContext,
                                "Failed to write to %s\n", filename);
                return (-1);
            }
#endif /* LIBXML_HTML_ENABLED */
            break;
        default:{
                FILE *f;

                f = fopen((char *) filename, "w");
                if (f == NULL) {
                    xmlGenericError(xmlGenericErrorContext,
                                    "Failed to write to %s\n", filename);
                    return (-1);
                }
                xmlElemDump(f, ctxt->doc, node);
                fclose(f);
            }
    }
    return (0);
}

/**
 * xmlShellSave:
 * @ctxt:  the shell context
 * @filename:  the file name (optional)
 * @node:  unused
 * @node2:  unused
 *
 * Implements the XML shell function "save"
 * Write the current document to the filename, or it's original name
 *
 * Returns 0 or -1 in case of error
 */
int
xmlShellSave(xmlShellCtxtPtr ctxt, char *filename,
             xmlNodePtr node ATTRIBUTE_UNUSED,
             xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    if ((ctxt == NULL) || (ctxt->doc == NULL))
        return (-1);
    if ((filename == NULL) || (filename[0] == 0))
        filename = ctxt->filename;
    if (filename == NULL)
        return (-1);
#ifdef W_OK
    if (access((char *) filename, W_OK)) {
        xmlGenericError(xmlGenericErrorContext,
                        "Cannot save to %s\n", filename);
        return (-1);
    }
#endif
    switch (ctxt->doc->type) {
        case XML_DOCUMENT_NODE:
            if (xmlSaveFile((char *) filename, ctxt->doc) < 0) {
                xmlGenericError(xmlGenericErrorContext,
                                "Failed to save to %s\n", filename);
            }
            break;
        case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_HTML_ENABLED
            if (htmlSaveFile((char *) filename, ctxt->doc) < 0) {
                xmlGenericError(xmlGenericErrorContext,
                                "Failed to save to %s\n", filename);
            }
#else
            if (xmlSaveFile((char *) filename, ctxt->doc) < 0) {
                xmlGenericError(xmlGenericErrorContext,
                                "Failed to save to %s\n", filename);
            }
#endif /* LIBXML_HTML_ENABLED */
            break;
        default:
            xmlGenericError(xmlGenericErrorContext,
	    "To save to subparts of a document use the 'write' command\n");
            return (-1);

    }
    return (0);
}
#endif /* LIBXML_OUTPUT_ENABLED */

#ifdef LIBXML_VALID_ENABLED
/**
 * xmlShellValidate:
 * @ctxt:  the shell context
 * @dtd:  the DTD URI (optional)
 * @node:  unused
 * @node2:  unused
 *
 * Implements the XML shell function "validate"
 * Validate the document, if a DTD path is provided, then the validation
 * is done against the given DTD.
 *
 * Returns 0 or -1 in case of error
 */
int
xmlShellValidate(xmlShellCtxtPtr ctxt, char *dtd,
                 xmlNodePtr node ATTRIBUTE_UNUSED,
                 xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlValidCtxt vctxt;
    int res = -1;

    if ((ctxt == NULL) || (ctxt->doc == NULL)) return(-1);
    vctxt.userData = stderr;
    vctxt.error = (xmlValidityErrorFunc) fprintf;
    vctxt.warning = (xmlValidityWarningFunc) fprintf;

    if ((dtd == NULL) || (dtd[0] == 0)) {
        res = xmlValidateDocument(&vctxt, ctxt->doc);
    } else {
        xmlDtdPtr subset;

        subset = xmlParseDTD(NULL, (xmlChar *) dtd);
        if (subset != NULL) {
            res = xmlValidateDtd(&vctxt, ctxt->doc, subset);

            xmlFreeDtd(subset);
        }
    }
    return (res);
}
#endif /* LIBXML_VALID_ENABLED */

/**
 * xmlShellDu:
 * @ctxt:  the shell context
 * @arg:  unused
 * @tree:  a node defining a subtree
 * @node2:  unused
 *
 * Implements the XML shell function "du"
 * show the structure of the subtree under node @tree
 * If @tree is null, the command works on the current node.
 *
 * Returns 0 or -1 in case of error
 */
int
xmlShellDu(xmlShellCtxtPtr ctxt,
           char *arg ATTRIBUTE_UNUSED, xmlNodePtr tree,
           xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlNodePtr node;
    int indent = 0, i;

    if (!ctxt)
	return (-1);

    if (tree == NULL)
        return (-1);
    node = tree;
    while (node != NULL) {
        if ((node->type == XML_DOCUMENT_NODE) ||
            (node->type == XML_HTML_DOCUMENT_NODE)) {
            fprintf(ctxt->output, "/\n");
        } else if (node->type == XML_ELEMENT_NODE) {
            for (i = 0; i < indent; i++)
                fprintf(ctxt->output, "  ");
            if ((node->ns) && (node->ns->prefix))
                fprintf(ctxt->output, "%s:", node->ns->prefix);
            fprintf(ctxt->output, "%s\n", node->name);
        } else {
        }

        /*
         * Browse the full subtree, deep first
         */

        if ((node->type == XML_DOCUMENT_NODE) ||
            (node->type == XML_HTML_DOCUMENT_NODE)) {
            node = ((xmlDocPtr) node)->children;
        } else if ((node->children != NULL)
                   && (node->type != XML_ENTITY_REF_NODE)) {
            /* deep first */
            node = node->children;
            indent++;
        } else if ((node != tree) && (node->next != NULL)) {
            /* then siblings */
            node = node->next;
        } else if (node != tree) {
            /* go up to parents->next if needed */
            while (node != tree) {
                if (node->parent != NULL) {
                    node = node->parent;
                    indent--;
                }
                if ((node != tree) && (node->next != NULL)) {
                    node = node->next;
                    break;
                }
                if (node->parent == NULL) {
                    node = NULL;
                    break;
                }
                if (node == tree) {
                    node = NULL;
                    break;
                }
            }
            /* exit condition */
            if (node == tree)
                node = NULL;
        } else
            node = NULL;
    }
    return (0);
}

/**
 * xmlShellPwd:
 * @ctxt:  the shell context
 * @buffer:  the output buffer
 * @node:  a node
 * @node2:  unused
 *
 * Implements the XML shell function "pwd"
 * Show the full path from the root to the node, if needed building
 * thumblers when similar elements exists at a given ancestor level.
 * The output is compatible with XPath commands.
 *
 * Returns 0 or -1 in case of error
 */
int
xmlShellPwd(xmlShellCtxtPtr ctxt ATTRIBUTE_UNUSED, char *buffer,
            xmlNodePtr node, xmlNodePtr node2 ATTRIBUTE_UNUSED)
{
    xmlChar *path;

    if ((node == NULL) || (buffer == NULL))
        return (-1);

    path = xmlGetNodePath(node);
    if (path == NULL)
	return (-1);

    /*
     * This test prevents buffer overflow, because this routine
     * is only called by xmlShell, in which the second argument is
     * 500 chars long.
     * It is a dirty hack before a cleaner solution is found.
     * Documentation should mention that the second argument must
     * be at least 500 chars long, and could be stripped if too long.
     */
    snprintf(buffer, 499, "%s", path);
    buffer[499] = '0';
    xmlFree(path);

    return (0);
}

/**
 * xmlShell:
 * @doc:  the initial document
 * @filename:  the output buffer
 * @input:  the line reading function
 * @output:  the output FILE*, defaults to stdout if NULL
 *
 * Implements the XML shell
 * This allow to load, validate, view, modify and save a document
 * using a environment similar to a UNIX commandline.
 */
void
xmlShell(xmlDocPtr doc, char *filename, xmlShellReadlineFunc input,
         FILE * output)
{
    char prompt[500] = "/ > ";
    char *cmdline = NULL, *cur;
    char command[100];
    char arg[400];
    int i;
    xmlShellCtxtPtr ctxt;
    xmlXPathObjectPtr list;

    if (doc == NULL)
        return;
    if (filename == NULL)
        return;
    if (input == NULL)
        return;
    if (output == NULL)
        output = stdout;
    ctxt = (xmlShellCtxtPtr) xmlMalloc(sizeof(xmlShellCtxt));
    if (ctxt == NULL)
        return;
    ctxt->loaded = 0;
    ctxt->doc = doc;
    ctxt->input = input;
    ctxt->output = output;
    ctxt->filename = (char *) xmlStrdup((xmlChar *) filename);
    ctxt->node = (xmlNodePtr) ctxt->doc;

#ifdef LIBXML_XPATH_ENABLED
    ctxt->pctxt = xmlXPathNewContext(ctxt->doc);
    if (ctxt->pctxt == NULL) {
        xmlFree(ctxt);
        return;
    }
#endif /* LIBXML_XPATH_ENABLED */
    while (1) {
        if (ctxt->node == (xmlNodePtr) ctxt->doc)
            snprintf(prompt, sizeof(prompt), "%s > ", "/");
        else if ((ctxt->node != NULL) && (ctxt->node->name) &&
                 (ctxt->node->ns) && (ctxt->node->ns->prefix))
            snprintf(prompt, sizeof(prompt), "%s:%s > ",
                     (ctxt->node->ns->prefix), ctxt->node->name);
        else if ((ctxt->node != NULL) && (ctxt->node->name))
            snprintf(prompt, sizeof(prompt), "%s > ", ctxt->node->name);
        else
            snprintf(prompt, sizeof(prompt), "? > ");
        prompt[sizeof(prompt) - 1] = 0;

        /*
         * Get a new command line
         */
        cmdline = ctxt->input(prompt);
        if (cmdline == NULL)
            break;

        /*
         * Parse the command itself
         */
        cur = cmdline;
        while ((*cur == ' ') || (*cur == '\t'))
            cur++;
        i = 0;
        while ((*cur != ' ') && (*cur != '\t') &&
               (*cur != '\n') && (*cur != '\r')) {
            if (*cur == 0)
                break;
            command[i++] = *cur++;
        }
        command[i] = 0;
        if (i == 0)
            continue;

        /*
         * Parse the argument
         */
        while ((*cur == ' ') || (*cur == '\t'))
            cur++;
        i = 0;
        while ((*cur != '\n') && (*cur != '\r') && (*cur != 0)) {
            if (*cur == 0)
                break;
            arg[i++] = *cur++;
        }
        arg[i] = 0;

        /*
         * start interpreting the command
         */
        if (!strcmp(command, "exit"))
            break;
        if (!strcmp(command, "quit"))
            break;
        if (!strcmp(command, "bye"))
            break;
		if (!strcmp(command, "help")) {
		  fprintf(ctxt->output, "\tbase         display XML base of the node\n");
		  fprintf(ctxt->output, "\tsetbase URI  change the XML base of the node\n");
		  fprintf(ctxt->output, "\tbye          leave shell\n");
		  fprintf(ctxt->output, "\tcat [node]   display node or current node\n");
		  fprintf(ctxt->output, "\tcd [path]    change directory to path or to root\n");
		  fprintf(ctxt->output, "\tdir [path]   dumps informations about the node (namespace, attributes, content)\n");
		  fprintf(ctxt->output, "\tdu [path]    show the structure of the subtree under path or the current node\n");
		  fprintf(ctxt->output, "\texit         leave shell\n");
		  fprintf(ctxt->output, "\thelp         display this help\n");
		  fprintf(ctxt->output, "\tfree         display memory usage\n");
		  fprintf(ctxt->output, "\tload [name]  load a new document with name\n");
		  fprintf(ctxt->output, "\tls [path]    list contents of path or the current directory\n");
		  fprintf(ctxt->output, "\tset xml_fragment replace the current node content with the fragment parsed in context\n");
#ifdef LIBXML_XPATH_ENABLED
		  fprintf(ctxt->output, "\txpath expr   evaluate the XPath expression in that context and print the result\n");
		  fprintf(ctxt->output, "\tsetns nsreg  register a namespace to a prefix in the XPath evaluation context\n");
		  fprintf(ctxt->output, "\t             format for nsreg is: prefix=[nsuri] (i.e. prefix= unsets a prefix)\n");
		  fprintf(ctxt->output, "\tsetrootns    register all namespace found on the root element\n");
		  fprintf(ctxt->output, "\t             the default namespace if any uses 'defaultns' prefix\n");
#endif /* LIBXML_XPATH_ENABLED */
		  fprintf(ctxt->output, "\tpwd          display current working directory\n");
		  fprintf(ctxt->output, "\twhereis      display absolute path of [path] or current working directory\n");
		  fprintf(ctxt->output, "\tquit         leave shell\n");
#ifdef LIBXML_OUTPUT_ENABLED
		  fprintf(ctxt->output, "\tsave [name]  save this document to name or the original name\n");
		  fprintf(ctxt->output, "\twrite [name] write the current node to the filename\n");
#endif /* LIBXML_OUTPUT_ENABLED */
#ifdef LIBXML_VALID_ENABLED
		  fprintf(ctxt->output, "\tvalidate     check the document for errors\n");
#endif /* LIBXML_VALID_ENABLED */
#ifdef LIBXML_SCHEMAS_ENABLED
		  fprintf(ctxt->output, "\trelaxng rng  validate the document agaisnt the Relax-NG schemas\n");
#endif
		  fprintf(ctxt->output, "\tgrep string  search for a string in the subtree\n");
#ifdef LIBXML_VALID_ENABLED
        } else if (!strcmp(command, "validate")) {
            xmlShellValidate(ctxt, arg, NULL, NULL);
#endif /* LIBXML_VALID_ENABLED */
        } else if (!strcmp(command, "load")) {
            xmlShellLoad(ctxt, arg, NULL, NULL);
#ifdef LIBXML_SCHEMAS_ENABLED
        } else if (!strcmp(command, "relaxng")) {
            xmlShellRNGValidate(ctxt, arg, NULL, NULL);
#endif
#ifdef LIBXML_OUTPUT_ENABLED
        } else if (!strcmp(command, "save")) {
            xmlShellSave(ctxt, arg, NULL, NULL);
        } else if (!strcmp(command, "write")) {
	    if (arg[0] == 0)
		xmlGenericError(xmlGenericErrorContext,
                        "Write command requires a filename argument\n");
	    else
		xmlShellWrite(ctxt, arg, ctxt->node, NULL);
#endif /* LIBXML_OUTPUT_ENABLED */
        } else if (!strcmp(command, "grep")) {
            xmlShellGrep(ctxt, arg, ctxt->node, NULL);
        } else if (!strcmp(command, "free")) {
            if (arg[0] == 0) {
                xmlMemShow(ctxt->output, 0);
            } else {
                int len = 0;

                sscanf(arg, "%d", &len);
                xmlMemShow(ctxt->output, len);
            }
        } else if (!strcmp(command, "pwd")) {
            char dir[500];

            if (!xmlShellPwd(ctxt, dir, ctxt->node, NULL))
                fprintf(ctxt->output, "%s\n", dir);
        } else if (!strcmp(command, "du")) {
            if (arg[0] == 0) {
                xmlShellDu(ctxt, NULL, ctxt->node, NULL);
            } else {
                ctxt->pctxt->node = ctxt->node;
#ifdef LIBXML_XPATH_ENABLED
                ctxt->pctxt->node = ctxt->node;
                list = xmlXPathEval((xmlChar *) arg, ctxt->pctxt);
#else
                list = NULL;
#endif /* LIBXML_XPATH_ENABLED */
                if (list != NULL) {
                    switch (list->type) {
                        case XPATH_UNDEFINED:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s: no such node\n", arg);
                            break;
                        case XPATH_NODESET:{
                            int indx;

                            if (list->nodesetval == NULL)
                                break;

                            for (indx = 0;
                                 indx < list->nodesetval->nodeNr;
                                 indx++)
                                xmlShellDu(ctxt, NULL,
                                           list->nodesetval->
                                           nodeTab[indx], NULL);
                            break;
                        }
                        case XPATH_BOOLEAN:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a Boolean\n", arg);
                            break;
                        case XPATH_NUMBER:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a number\n", arg);
                            break;
                        case XPATH_STRING:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a string\n", arg);
                            break;
                        case XPATH_POINT:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a point\n", arg);
                            break;
                        case XPATH_RANGE:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a range\n", arg);
                            break;
                        case XPATH_LOCATIONSET:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a range\n", arg);
                            break;
                        case XPATH_USERS:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is user-defined\n", arg);
                            break;
                        case XPATH_XSLT_TREE:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is an XSLT value tree\n",
                                            arg);
                            break;
                    }
#ifdef LIBXML_XPATH_ENABLED
                    xmlXPathFreeObject(list);
#endif
                } else {
                    xmlGenericError(xmlGenericErrorContext,
                                    "%s: no such node\n", arg);
                }
                ctxt->pctxt->node = NULL;
            }
        } else if (!strcmp(command, "base")) {
            xmlShellBase(ctxt, NULL, ctxt->node, NULL);
        } else if (!strcmp(command, "set")) {
	    xmlShellSetContent(ctxt, arg, ctxt->node, NULL);
#ifdef LIBXML_XPATH_ENABLED
        } else if (!strcmp(command, "setns")) {
            if (arg[0] == 0) {
		xmlGenericError(xmlGenericErrorContext,
				"setns: prefix=[nsuri] required\n");
            } else {
                xmlShellRegisterNamespace(ctxt, arg, NULL, NULL);
            }
        } else if (!strcmp(command, "setrootns")) {
	    xmlNodePtr root;

	    root = xmlDocGetRootElement(ctxt->doc);
	    xmlShellRegisterRootNamespaces(ctxt, NULL, root, NULL);
        } else if (!strcmp(command, "xpath")) {
            if (arg[0] == 0) {
		xmlGenericError(xmlGenericErrorContext,
				"xpath: expression required\n");
	    } else {
                ctxt->pctxt->node = ctxt->node;
                list = xmlXPathEval((xmlChar *) arg, ctxt->pctxt);
		xmlXPathDebugDumpObject(ctxt->output, list, 0);
		xmlXPathFreeObject(list);
	    }
#endif /* LIBXML_XPATH_ENABLED */
#ifdef LIBXML_TREE_ENABLED
        } else if (!strcmp(command, "setbase")) {
            xmlShellSetBase(ctxt, arg, ctxt->node, NULL);
#endif
        } else if ((!strcmp(command, "ls")) || (!strcmp(command, "dir"))) {
            int dir = (!strcmp(command, "dir"));

            if (arg[0] == 0) {
                if (dir)
                    xmlShellDir(ctxt, NULL, ctxt->node, NULL);
                else
                    xmlShellList(ctxt, NULL, ctxt->node, NULL);
            } else {
                ctxt->pctxt->node = ctxt->node;
#ifdef LIBXML_XPATH_ENABLED
                ctxt->pctxt->node = ctxt->node;
                list = xmlXPathEval((xmlChar *) arg, ctxt->pctxt);
#else
                list = NULL;
#endif /* LIBXML_XPATH_ENABLED */
                if (list != NULL) {
                    switch (list->type) {
                        case XPATH_UNDEFINED:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s: no such node\n", arg);
                            break;
                        case XPATH_NODESET:{
                                int indx;

				if (list->nodesetval == NULL)
				    break;

                                for (indx = 0;
                                     indx < list->nodesetval->nodeNr;
                                     indx++) {
                                    if (dir)
                                        xmlShellDir(ctxt, NULL,
                                                    list->nodesetval->
                                                    nodeTab[indx], NULL);
                                    else
                                        xmlShellList(ctxt, NULL,
                                                     list->nodesetval->
                                                     nodeTab[indx], NULL);
                                }
                                break;
                            }
                        case XPATH_BOOLEAN:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a Boolean\n", arg);
                            break;
                        case XPATH_NUMBER:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a number\n", arg);
                            break;
                        case XPATH_STRING:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a string\n", arg);
                            break;
                        case XPATH_POINT:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a point\n", arg);
                            break;
                        case XPATH_RANGE:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a range\n", arg);
                            break;
                        case XPATH_LOCATIONSET:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a range\n", arg);
                            break;
                        case XPATH_USERS:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is user-defined\n", arg);
                            break;
                        case XPATH_XSLT_TREE:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is an XSLT value tree\n",
                                            arg);
                            break;
                    }
#ifdef LIBXML_XPATH_ENABLED
                    xmlXPathFreeObject(list);
#endif
                } else {
                    xmlGenericError(xmlGenericErrorContext,
                                    "%s: no such node\n", arg);
                }
                ctxt->pctxt->node = NULL;
            }
        } else if (!strcmp(command, "whereis")) {
            char dir[500];

            if (arg[0] == 0) {
                if (!xmlShellPwd(ctxt, dir, ctxt->node, NULL))
                    fprintf(ctxt->output, "%s\n", dir);
            } else {
                ctxt->pctxt->node = ctxt->node;
#ifdef LIBXML_XPATH_ENABLED
                list = xmlXPathEval((xmlChar *) arg, ctxt->pctxt);
#else
                list = NULL;
#endif /* LIBXML_XPATH_ENABLED */
                if (list != NULL) {
                    switch (list->type) {
                        case XPATH_UNDEFINED:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s: no such node\n", arg);
                            break;
                        case XPATH_NODESET:{
                                int indx;

				if (list->nodesetval == NULL)
				    break;

                                for (indx = 0;
                                     indx < list->nodesetval->nodeNr;
                                     indx++) {
                                    if (!xmlShellPwd(ctxt, dir, list->nodesetval->
                                                     nodeTab[indx], NULL))
                                        fprintf(ctxt->output, "%s\n", dir);
                                }
                                break;
                            }
                        case XPATH_BOOLEAN:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a Boolean\n", arg);
                            break;
                        case XPATH_NUMBER:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a number\n", arg);
                            break;
                        case XPATH_STRING:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a string\n", arg);
                            break;
                        case XPATH_POINT:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a point\n", arg);
                            break;
                        case XPATH_RANGE:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a range\n", arg);
                            break;
                        case XPATH_LOCATIONSET:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a range\n", arg);
                            break;
                        case XPATH_USERS:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is user-defined\n", arg);
                            break;
                        case XPATH_XSLT_TREE:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is an XSLT value tree\n",
                                            arg);
                            break;
                    }
#ifdef LIBXML_XPATH_ENABLED
                    xmlXPathFreeObject(list);
#endif
                } else {
                    xmlGenericError(xmlGenericErrorContext,
                                    "%s: no such node\n", arg);
                }
                ctxt->pctxt->node = NULL;
            }
        } else if (!strcmp(command, "cd")) {
            if (arg[0] == 0) {
                ctxt->node = (xmlNodePtr) ctxt->doc;
            } else {
#ifdef LIBXML_XPATH_ENABLED
                int l;

                ctxt->pctxt->node = ctxt->node;
		l = strlen(arg);
		if ((l >= 2) && (arg[l - 1] == '/'))
		    arg[l - 1] = 0;
                list = xmlXPathEval((xmlChar *) arg, ctxt->pctxt);
#else
                list = NULL;
#endif /* LIBXML_XPATH_ENABLED */
                if (list != NULL) {
                    switch (list->type) {
                        case XPATH_UNDEFINED:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s: no such node\n", arg);
                            break;
                        case XPATH_NODESET:
                            if (list->nodesetval != NULL) {
				if (list->nodesetval->nodeNr == 1) {
				    ctxt->node = list->nodesetval->nodeTab[0];
				    if ((ctxt->node != NULL) &&
				        (ctxt->node->type ==
					 XML_NAMESPACE_DECL)) {
					xmlGenericError(xmlGenericErrorContext,
						    "cannot cd to namespace\n");
					ctxt->node = NULL;
				    }
				} else
				    xmlGenericError(xmlGenericErrorContext,
						    "%s is a %d Node Set\n",
						    arg,
						    list->nodesetval->nodeNr);
                            } else
                                xmlGenericError(xmlGenericErrorContext,
                                                "%s is an empty Node Set\n",
                                                arg);
                            break;
                        case XPATH_BOOLEAN:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a Boolean\n", arg);
                            break;
                        case XPATH_NUMBER:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a number\n", arg);
                            break;
                        case XPATH_STRING:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a string\n", arg);
                            break;
                        case XPATH_POINT:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a point\n", arg);
                            break;
                        case XPATH_RANGE:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a range\n", arg);
                            break;
                        case XPATH_LOCATIONSET:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a range\n", arg);
                            break;
                        case XPATH_USERS:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is user-defined\n", arg);
                            break;
                        case XPATH_XSLT_TREE:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is an XSLT value tree\n",
                                            arg);
                            break;
                    }
#ifdef LIBXML_XPATH_ENABLED
                    xmlXPathFreeObject(list);
#endif
                } else {
                    xmlGenericError(xmlGenericErrorContext,
                                    "%s: no such node\n", arg);
                }
                ctxt->pctxt->node = NULL;
            }
#ifdef LIBXML_OUTPUT_ENABLED
        } else if (!strcmp(command, "cat")) {
            if (arg[0] == 0) {
                xmlShellCat(ctxt, NULL, ctxt->node, NULL);
            } else {
                ctxt->pctxt->node = ctxt->node;
#ifdef LIBXML_XPATH_ENABLED
                ctxt->pctxt->node = ctxt->node;
                list = xmlXPathEval((xmlChar *) arg, ctxt->pctxt);
#else
                list = NULL;
#endif /* LIBXML_XPATH_ENABLED */
                if (list != NULL) {
                    switch (list->type) {
                        case XPATH_UNDEFINED:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s: no such node\n", arg);
                            break;
                        case XPATH_NODESET:{
                                int indx;

				if (list->nodesetval == NULL)
				    break;

                                for (indx = 0;
                                     indx < list->nodesetval->nodeNr;
                                     indx++) {
                                    if (i > 0)
                                        fprintf(ctxt->output, " -------\n");
                                    xmlShellCat(ctxt, NULL,
                                                list->nodesetval->
                                                nodeTab[indx], NULL);
                                }
                                break;
                            }
                        case XPATH_BOOLEAN:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a Boolean\n", arg);
                            break;
                        case XPATH_NUMBER:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a number\n", arg);
                            break;
                        case XPATH_STRING:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a string\n", arg);
                            break;
                        case XPATH_POINT:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a point\n", arg);
                            break;
                        case XPATH_RANGE:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a range\n", arg);
                            break;
                        case XPATH_LOCATIONSET:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is a range\n", arg);
                            break;
                        case XPATH_USERS:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is user-defined\n", arg);
                            break;
                        case XPATH_XSLT_TREE:
                            xmlGenericError(xmlGenericErrorContext,
                                            "%s is an XSLT value tree\n",
                                            arg);
                            break;
                    }
#ifdef LIBXML_XPATH_ENABLED
                    xmlXPathFreeObject(list);
#endif
                } else {
                    xmlGenericError(xmlGenericErrorContext,
                                    "%s: no such node\n", arg);
                }
                ctxt->pctxt->node = NULL;
            }
#endif /* LIBXML_OUTPUT_ENABLED */
        } else {
            xmlGenericError(xmlGenericErrorContext,
                            "Unknown command %s\n", command);
        }
        free(cmdline);          /* not xmlFree here ! */
	cmdline = NULL;
    }
#ifdef LIBXML_XPATH_ENABLED
    xmlXPathFreeContext(ctxt->pctxt);
#endif /* LIBXML_XPATH_ENABLED */
    if (ctxt->loaded) {
        xmlFreeDoc(ctxt->doc);
    }
    if (ctxt->filename != NULL)
        xmlFree(ctxt->filename);
    xmlFree(ctxt);
    if (cmdline != NULL)
        free(cmdline);          /* not xmlFree here ! */
}

#endif /* LIBXML_XPATH_ENABLED */
#define bottom_debugXML
#include "elfgcchack.h"
#endif /* LIBXML_DEBUG_ENABLED */
