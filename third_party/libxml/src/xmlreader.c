/*
 * xmlreader.c: implements the xmlTextReader streaming node API
 *
 * NOTE:
 *   XmlTextReader.Normalization Property won't be supported, since
 *     it makes the parser non compliant to the XML recommendation
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 */

/*
 * TODOs:
 *   - XML Schemas validation
 */
#define IN_LIBXML
#include "libxml.h"

#ifdef LIBXML_READER_ENABLED
#include <string.h> /* for memset() only ! */
#include <stdarg.h>

#ifdef HAVE_CTYPE_H
#include <ctype.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#include <libxml/xmlmemory.h>
#include <libxml/xmlIO.h>
#include <libxml/xmlreader.h>
#include <libxml/parserInternals.h>
#ifdef LIBXML_SCHEMAS_ENABLED
#include <libxml/relaxng.h>
#include <libxml/xmlschemas.h>
#endif
#include <libxml/uri.h>
#ifdef LIBXML_XINCLUDE_ENABLED
#include <libxml/xinclude.h>
#endif
#ifdef LIBXML_PATTERN_ENABLED
#include <libxml/pattern.h>
#endif

#define MAX_ERR_MSG_SIZE 64000

/*
 * The following VA_COPY was coded following an example in
 * the Samba project.  It may not be sufficient for some
 * esoteric implementations of va_list (i.e. it may need
 * something involving a memcpy) but (hopefully) will be
 * sufficient for libxml2.
 */
#ifndef VA_COPY
  #ifdef HAVE_VA_COPY
    #define VA_COPY(dest, src) va_copy(dest, src)
  #else
    #ifdef HAVE___VA_COPY
      #define VA_COPY(dest,src) __va_copy(dest, src)
    #else
      #define VA_COPY(dest,src) (dest) = (src)
    #endif
  #endif
#endif

/* #define DEBUG_CALLBACKS */
/* #define DEBUG_READER */

/**
 * TODO:
 *
 * macro to flag unimplemented blocks
 */
#define TODO								\
    xmlGenericError(xmlGenericErrorContext,				\
	    "Unimplemented block at %s:%d\n",				\
            __FILE__, __LINE__);

#ifdef DEBUG_READER
#define DUMP_READER xmlTextReaderDebug(reader);
#else
#define DUMP_READER
#endif

#define CHUNK_SIZE 512
/************************************************************************
 *									*
 *	The parser: maps the Text Reader API on top of the existing	*
 *		parsing routines building a tree			*
 *									*
 ************************************************************************/

#define XML_TEXTREADER_INPUT	1
#define XML_TEXTREADER_CTXT	2

typedef enum {
    XML_TEXTREADER_NONE = -1,
    XML_TEXTREADER_START= 0,
    XML_TEXTREADER_ELEMENT= 1,
    XML_TEXTREADER_END= 2,
    XML_TEXTREADER_EMPTY= 3,
    XML_TEXTREADER_BACKTRACK= 4,
    XML_TEXTREADER_DONE= 5,
    XML_TEXTREADER_ERROR= 6
} xmlTextReaderState;

typedef enum {
    XML_TEXTREADER_NOT_VALIDATE = 0,
    XML_TEXTREADER_VALIDATE_DTD = 1,
    XML_TEXTREADER_VALIDATE_RNG = 2,
    XML_TEXTREADER_VALIDATE_XSD = 4
} xmlTextReaderValidate;

struct _xmlTextReader {
    int				mode;	/* the parsing mode */
    xmlDocPtr			doc;    /* when walking an existing doc */
    xmlTextReaderValidate       validate;/* is there any validation */
    int				allocs;	/* what structure were deallocated */
    xmlTextReaderState		state;
    xmlParserCtxtPtr		ctxt;	/* the parser context */
    xmlSAXHandlerPtr		sax;	/* the parser SAX callbacks */
    xmlParserInputBufferPtr	input;	/* the input */
    startElementSAXFunc		startElement;/* initial SAX callbacks */
    endElementSAXFunc		endElement;  /* idem */
    startElementNsSAX2Func	startElementNs;/* idem */
    endElementNsSAX2Func	endElementNs;  /* idem */
    charactersSAXFunc		characters;
    cdataBlockSAXFunc		cdataBlock;
    unsigned int		base;	/* base of the segment in the input */
    unsigned int		cur;	/* current position in the input */
    xmlNodePtr			node;	/* current node */
    xmlNodePtr			curnode;/* current attribute node */
    int				depth;  /* depth of the current node */
    xmlNodePtr			faketext;/* fake xmlNs chld */
    int				preserve;/* preserve the resulting document */
    xmlBufferPtr		buffer; /* used to return const xmlChar * */
    xmlDictPtr			dict;	/* the context dictionnary */

    /* entity stack when traversing entities content */
    xmlNodePtr         ent;          /* Current Entity Ref Node */
    int                entNr;        /* Depth of the entities stack */
    int                entMax;       /* Max depth of the entities stack */
    xmlNodePtr        *entTab;       /* array of entities */

    /* error handling */
    xmlTextReaderErrorFunc errorFunc;    /* callback function */
    void                  *errorFuncArg; /* callback function user argument */

#ifdef LIBXML_SCHEMAS_ENABLED
    /* Handling of RelaxNG validation */
    xmlRelaxNGPtr          rngSchemas;	/* The Relax NG schemas */
    xmlRelaxNGValidCtxtPtr rngValidCtxt;/* The Relax NG validation context */
    int                    rngValidErrors;/* The number of errors detected */
    xmlNodePtr             rngFullNode;	/* the node if RNG not progressive */
    /* Handling of Schemas validation */
    xmlSchemaPtr          xsdSchemas;	/* The Schemas schemas */
    xmlSchemaValidCtxtPtr xsdValidCtxt;/* The Schemas validation context */
    int                   xsdPreserveCtxt; /* 1 if the context was provided by the user */
    int                   xsdValidErrors;/* The number of errors detected */
    xmlSchemaSAXPlugPtr   xsdPlug;	/* the schemas plug in SAX pipeline */
#endif
#ifdef LIBXML_XINCLUDE_ENABLED
    /* Handling of XInclude processing */
    int                xinclude;	/* is xinclude asked for */
    const xmlChar *    xinclude_name;	/* the xinclude name from dict */
    xmlXIncludeCtxtPtr xincctxt;	/* the xinclude context */
    int                in_xinclude;	/* counts for xinclude */
#endif
#ifdef LIBXML_PATTERN_ENABLED
    int                patternNr;       /* number of preserve patterns */
    int                patternMax;      /* max preserve patterns */
    xmlPatternPtr     *patternTab;      /* array of preserve patterns */
#endif
    int                preserves;	/* level of preserves */
    int                parserFlags;	/* the set of options set */
    /* Structured error handling */
    xmlStructuredErrorFunc sErrorFunc;  /* callback function */
};

#define NODE_IS_EMPTY		0x1
#define NODE_IS_PRESERVED	0x2
#define NODE_IS_SPRESERVED	0x4

/**
 * CONSTSTR:
 *
 * Macro used to return an interned string
 */
#define CONSTSTR(str) xmlDictLookup(reader->dict, (str), -1)
#define CONSTQSTR(p, str) xmlDictQLookup(reader->dict, (p), (str))

static int xmlTextReaderReadTree(xmlTextReaderPtr reader);
static int xmlTextReaderNextTree(xmlTextReaderPtr reader);

/************************************************************************
 *									*
 *	Our own version of the freeing routines as we recycle nodes	*
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

static void xmlTextReaderFreeNode(xmlTextReaderPtr reader, xmlNodePtr cur);
static void xmlTextReaderFreeNodeList(xmlTextReaderPtr reader, xmlNodePtr cur);

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
    xmlFree(id);
}

/**
 * xmlTextReaderRemoveID:
 * @doc:  the document
 * @attr:  the attribute
 *
 * Remove the given attribute from the ID table maintained internally.
 *
 * Returns -1 if the lookup failed and 0 otherwise
 */
static int
xmlTextReaderRemoveID(xmlDocPtr doc, xmlAttrPtr attr) {
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
    xmlFree(ID);
    if (id == NULL || id->attr != attr) {
	return(-1);
    }
    id->name = attr->name;
    id->attr = NULL;
    return(0);
}

/**
 * xmlTextReaderFreeProp:
 * @reader:  the xmlTextReaderPtr used
 * @cur:  the node
 *
 * Free a node.
 */
static void
xmlTextReaderFreeProp(xmlTextReaderPtr reader, xmlAttrPtr cur) {
    xmlDictPtr dict;

    dict = reader->ctxt->dict;
    if (cur == NULL) return;

    if ((__xmlRegisterCallbacks) && (xmlDeregisterNodeDefaultValue))
	xmlDeregisterNodeDefaultValue((xmlNodePtr) cur);

    /* Check for ID removal -> leading to invalid references ! */
    if ((cur->parent != NULL) && (cur->parent->doc != NULL) &&
	((cur->parent->doc->intSubset != NULL) ||
	 (cur->parent->doc->extSubset != NULL))) {
        if (xmlIsID(cur->parent->doc, cur->parent, cur))
	    xmlTextReaderRemoveID(cur->parent->doc, cur);
    }
    if (cur->children != NULL)
        xmlTextReaderFreeNodeList(reader, cur->children);

    DICT_FREE(cur->name);
    if ((reader != NULL) && (reader->ctxt != NULL) &&
        (reader->ctxt->freeAttrsNr < 100)) {
        cur->next = reader->ctxt->freeAttrs;
	reader->ctxt->freeAttrs = cur;
	reader->ctxt->freeAttrsNr++;
    } else {
	xmlFree(cur);
    }
}

/**
 * xmlTextReaderFreePropList:
 * @reader:  the xmlTextReaderPtr used
 * @cur:  the first property in the list
 *
 * Free a property and all its siblings, all the children are freed too.
 */
static void
xmlTextReaderFreePropList(xmlTextReaderPtr reader, xmlAttrPtr cur) {
    xmlAttrPtr next;
    if (cur == NULL) return;
    while (cur != NULL) {
        next = cur->next;
        xmlTextReaderFreeProp(reader, cur);
	cur = next;
    }
}

/**
 * xmlTextReaderFreeNodeList:
 * @reader:  the xmlTextReaderPtr used
 * @cur:  the first node in the list
 *
 * Free a node and all its siblings, this is a recursive behaviour, all
 * the children are freed too.
 */
static void
xmlTextReaderFreeNodeList(xmlTextReaderPtr reader, xmlNodePtr cur) {
    xmlNodePtr next;
    xmlDictPtr dict;

    dict = reader->ctxt->dict;
    if (cur == NULL) return;
    if (cur->type == XML_NAMESPACE_DECL) {
	xmlFreeNsList((xmlNsPtr) cur);
	return;
    }
    if ((cur->type == XML_DOCUMENT_NODE) ||
	(cur->type == XML_HTML_DOCUMENT_NODE)) {
	xmlFreeDoc((xmlDocPtr) cur);
	return;
    }
    while (cur != NULL) {
        next = cur->next;
	/* unroll to speed up freeing the document */
	if (cur->type != XML_DTD_NODE) {

	    if ((cur->children != NULL) &&
		(cur->type != XML_ENTITY_REF_NODE)) {
		if (cur->children->parent == cur)
		    xmlTextReaderFreeNodeList(reader, cur->children);
		cur->children = NULL;
	    }

	    if ((__xmlRegisterCallbacks) && (xmlDeregisterNodeDefaultValue))
		xmlDeregisterNodeDefaultValue(cur);

	    if (((cur->type == XML_ELEMENT_NODE) ||
		 (cur->type == XML_XINCLUDE_START) ||
		 (cur->type == XML_XINCLUDE_END)) &&
		(cur->properties != NULL))
		xmlTextReaderFreePropList(reader, cur->properties);
	    if ((cur->content != (xmlChar *) &(cur->properties)) &&
	        (cur->type != XML_ELEMENT_NODE) &&
		(cur->type != XML_XINCLUDE_START) &&
		(cur->type != XML_XINCLUDE_END) &&
		(cur->type != XML_ENTITY_REF_NODE)) {
		DICT_FREE(cur->content);
	    }
	    if (((cur->type == XML_ELEMENT_NODE) ||
	         (cur->type == XML_XINCLUDE_START) ||
		 (cur->type == XML_XINCLUDE_END)) &&
		(cur->nsDef != NULL))
		xmlFreeNsList(cur->nsDef);

	    /*
	     * we don't free element names here they are interned now
	     */
	    if ((cur->type != XML_TEXT_NODE) &&
		(cur->type != XML_COMMENT_NODE))
		DICT_FREE(cur->name);
	    if (((cur->type == XML_ELEMENT_NODE) ||
		 (cur->type == XML_TEXT_NODE)) &&
	        (reader != NULL) && (reader->ctxt != NULL) &&
		(reader->ctxt->freeElemsNr < 100)) {
	        cur->next = reader->ctxt->freeElems;
		reader->ctxt->freeElems = cur;
		reader->ctxt->freeElemsNr++;
	    } else {
		xmlFree(cur);
	    }
	}
	cur = next;
    }
}

/**
 * xmlTextReaderFreeNode:
 * @reader:  the xmlTextReaderPtr used
 * @cur:  the node
 *
 * Free a node, this is a recursive behaviour, all the children are freed too.
 * This doesn't unlink the child from the list, use xmlUnlinkNode() first.
 */
static void
xmlTextReaderFreeNode(xmlTextReaderPtr reader, xmlNodePtr cur) {
    xmlDictPtr dict;

    dict = reader->ctxt->dict;
    if (cur->type == XML_DTD_NODE) {
	xmlFreeDtd((xmlDtdPtr) cur);
	return;
    }
    if (cur->type == XML_NAMESPACE_DECL) {
	xmlFreeNs((xmlNsPtr) cur);
        return;
    }
    if (cur->type == XML_ATTRIBUTE_NODE) {
	xmlTextReaderFreeProp(reader, (xmlAttrPtr) cur);
	return;
    }

    if ((cur->children != NULL) &&
	(cur->type != XML_ENTITY_REF_NODE)) {
	if (cur->children->parent == cur)
	    xmlTextReaderFreeNodeList(reader, cur->children);
	cur->children = NULL;
    }

    if ((__xmlRegisterCallbacks) && (xmlDeregisterNodeDefaultValue))
	xmlDeregisterNodeDefaultValue(cur);

    if (((cur->type == XML_ELEMENT_NODE) ||
	 (cur->type == XML_XINCLUDE_START) ||
	 (cur->type == XML_XINCLUDE_END)) &&
	(cur->properties != NULL))
	xmlTextReaderFreePropList(reader, cur->properties);
    if ((cur->content != (xmlChar *) &(cur->properties)) &&
        (cur->type != XML_ELEMENT_NODE) &&
	(cur->type != XML_XINCLUDE_START) &&
	(cur->type != XML_XINCLUDE_END) &&
	(cur->type != XML_ENTITY_REF_NODE)) {
	DICT_FREE(cur->content);
    }
    if (((cur->type == XML_ELEMENT_NODE) ||
	 (cur->type == XML_XINCLUDE_START) ||
	 (cur->type == XML_XINCLUDE_END)) &&
	(cur->nsDef != NULL))
	xmlFreeNsList(cur->nsDef);

    /*
     * we don't free names here they are interned now
     */
    if ((cur->type != XML_TEXT_NODE) &&
        (cur->type != XML_COMMENT_NODE))
	DICT_FREE(cur->name);

    if (((cur->type == XML_ELEMENT_NODE) ||
	 (cur->type == XML_TEXT_NODE)) &&
	(reader != NULL) && (reader->ctxt != NULL) &&
	(reader->ctxt->freeElemsNr < 100)) {
	cur->next = reader->ctxt->freeElems;
	reader->ctxt->freeElems = cur;
	reader->ctxt->freeElemsNr++;
    } else {
	xmlFree(cur);
    }
}

/**
 * xmlTextReaderFreeIDTable:
 * @table:  An id table
 *
 * Deallocate the memory used by an ID hash table.
 */
static void
xmlTextReaderFreeIDTable(xmlIDTablePtr table) {
    xmlHashFree(table, (xmlHashDeallocator) xmlFreeID);
}

/**
 * xmlTextReaderFreeDoc:
 * @reader:  the xmlTextReaderPtr used
 * @cur:  pointer to the document
 *
 * Free up all the structures used by a document, tree included.
 */
static void
xmlTextReaderFreeDoc(xmlTextReaderPtr reader, xmlDocPtr cur) {
    xmlDtdPtr extSubset, intSubset;

    if (cur == NULL) return;

    if ((__xmlRegisterCallbacks) && (xmlDeregisterNodeDefaultValue))
	xmlDeregisterNodeDefaultValue((xmlNodePtr) cur);

    /*
     * Do this before freeing the children list to avoid ID lookups
     */
    if (cur->ids != NULL) xmlTextReaderFreeIDTable((xmlIDTablePtr) cur->ids);
    cur->ids = NULL;
    if (cur->refs != NULL) xmlFreeRefTable((xmlRefTablePtr) cur->refs);
    cur->refs = NULL;
    extSubset = cur->extSubset;
    intSubset = cur->intSubset;
    if (intSubset == extSubset)
	extSubset = NULL;
    if (extSubset != NULL) {
	xmlUnlinkNode((xmlNodePtr) cur->extSubset);
	cur->extSubset = NULL;
	xmlFreeDtd(extSubset);
    }
    if (intSubset != NULL) {
	xmlUnlinkNode((xmlNodePtr) cur->intSubset);
	cur->intSubset = NULL;
	xmlFreeDtd(intSubset);
    }

    if (cur->children != NULL) xmlTextReaderFreeNodeList(reader, cur->children);

    if (cur->version != NULL) xmlFree((char *) cur->version);
    if (cur->name != NULL) xmlFree((char *) cur->name);
    if (cur->encoding != NULL) xmlFree((char *) cur->encoding);
    if (cur->oldNs != NULL) xmlFreeNsList(cur->oldNs);
    if (cur->URL != NULL) xmlFree((char *) cur->URL);
    if (cur->dict != NULL) xmlDictFree(cur->dict);

    xmlFree(cur);
}

/************************************************************************
 *									*
 *			The reader core parser				*
 *									*
 ************************************************************************/
#ifdef DEBUG_READER
static void
xmlTextReaderDebug(xmlTextReaderPtr reader) {
    if ((reader == NULL) || (reader->ctxt == NULL)) {
	fprintf(stderr, "xmlTextReader NULL\n");
	return;
    }
    fprintf(stderr, "xmlTextReader: state %d depth %d ",
	    reader->state, reader->depth);
    if (reader->node == NULL) {
	fprintf(stderr, "node = NULL\n");
    } else {
	fprintf(stderr, "node %s\n", reader->node->name);
    }
    fprintf(stderr, "  input: base %d, cur %d, depth %d: ",
	    reader->base, reader->cur, reader->ctxt->nodeNr);
    if (reader->input->buffer == NULL) {
	fprintf(stderr, "buffer is NULL\n");
    } else {
#ifdef LIBXML_DEBUG_ENABLED
	xmlDebugDumpString(stderr,
		&reader->input->buffer->content[reader->cur]);
#endif
	fprintf(stderr, "\n");
    }
}
#endif

/**
 * xmlTextReaderEntPush:
 * @reader:  the xmlTextReaderPtr used
 * @value:  the entity reference node
 *
 * Pushes a new entity reference node on top of the entities stack
 *
 * Returns 0 in case of error, the index in the stack otherwise
 */
static int
xmlTextReaderEntPush(xmlTextReaderPtr reader, xmlNodePtr value)
{
    if (reader->entMax <= 0) {
	reader->entMax = 10;
	reader->entTab = (xmlNodePtr *) xmlMalloc(reader->entMax *
		                                  sizeof(reader->entTab[0]));
        if (reader->entTab == NULL) {
            xmlGenericError(xmlGenericErrorContext, "xmlMalloc failed !\n");
            return (0);
        }
    }
    if (reader->entNr >= reader->entMax) {
        reader->entMax *= 2;
        reader->entTab =
            (xmlNodePtr *) xmlRealloc(reader->entTab,
                                      reader->entMax *
                                      sizeof(reader->entTab[0]));
        if (reader->entTab == NULL) {
            xmlGenericError(xmlGenericErrorContext, "xmlRealloc failed !\n");
            return (0);
        }
    }
    reader->entTab[reader->entNr] = value;
    reader->ent = value;
    return (reader->entNr++);
}

/**
 * xmlTextReaderEntPop:
 * @reader:  the xmlTextReaderPtr used
 *
 * Pops the top element entity from the entities stack
 *
 * Returns the entity just removed
 */
static xmlNodePtr
xmlTextReaderEntPop(xmlTextReaderPtr reader)
{
    xmlNodePtr ret;

    if (reader->entNr <= 0)
        return (NULL);
    reader->entNr--;
    if (reader->entNr > 0)
        reader->ent = reader->entTab[reader->entNr - 1];
    else
        reader->ent = NULL;
    ret = reader->entTab[reader->entNr];
    reader->entTab[reader->entNr] = NULL;
    return (ret);
}

/**
 * xmlTextReaderStartElement:
 * @ctx: the user data (XML parser context)
 * @fullname:  The element name, including namespace prefix
 * @atts:  An array of name/value attributes pairs, NULL terminated
 *
 * called when an opening tag has been processed.
 */
static void
xmlTextReaderStartElement(void *ctx, const xmlChar *fullname,
	                  const xmlChar **atts) {
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlTextReaderPtr reader = ctxt->_private;

#ifdef DEBUG_CALLBACKS
    printf("xmlTextReaderStartElement(%s)\n", fullname);
#endif
    if ((reader != NULL) && (reader->startElement != NULL)) {
	reader->startElement(ctx, fullname, atts);
	if ((ctxt->node != NULL) && (ctxt->input != NULL) &&
	    (ctxt->input->cur != NULL) && (ctxt->input->cur[0] == '/') &&
	    (ctxt->input->cur[1] == '>'))
	    ctxt->node->extra = NODE_IS_EMPTY;
    }
    if (reader != NULL)
	reader->state = XML_TEXTREADER_ELEMENT;
}

/**
 * xmlTextReaderEndElement:
 * @ctx: the user data (XML parser context)
 * @fullname:  The element name, including namespace prefix
 *
 * called when an ending tag has been processed.
 */
static void
xmlTextReaderEndElement(void *ctx, const xmlChar *fullname) {
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlTextReaderPtr reader = ctxt->_private;

#ifdef DEBUG_CALLBACKS
    printf("xmlTextReaderEndElement(%s)\n", fullname);
#endif
    if ((reader != NULL) && (reader->endElement != NULL)) {
	reader->endElement(ctx, fullname);
    }
}

/**
 * xmlTextReaderStartElementNs:
 * @ctx: the user data (XML parser context)
 * @localname:  the local name of the element
 * @prefix:  the element namespace prefix if available
 * @URI:  the element namespace name if available
 * @nb_namespaces:  number of namespace definitions on that node
 * @namespaces:  pointer to the array of prefix/URI pairs namespace definitions
 * @nb_attributes:  the number of attributes on that node
 * nb_defaulted:  the number of defaulted attributes.
 * @attributes:  pointer to the array of (localname/prefix/URI/value/end)
 *               attribute values.
 *
 * called when an opening tag has been processed.
 */
static void
xmlTextReaderStartElementNs(void *ctx,
                      const xmlChar *localname,
		      const xmlChar *prefix,
		      const xmlChar *URI,
		      int nb_namespaces,
		      const xmlChar **namespaces,
		      int nb_attributes,
		      int nb_defaulted,
		      const xmlChar **attributes)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlTextReaderPtr reader = ctxt->_private;

#ifdef DEBUG_CALLBACKS
    printf("xmlTextReaderStartElementNs(%s)\n", localname);
#endif
    if ((reader != NULL) && (reader->startElementNs != NULL)) {
	reader->startElementNs(ctx, localname, prefix, URI, nb_namespaces,
	                       namespaces, nb_attributes, nb_defaulted,
			       attributes);
	if ((ctxt->node != NULL) && (ctxt->input != NULL) &&
	    (ctxt->input->cur != NULL) && (ctxt->input->cur[0] == '/') &&
	    (ctxt->input->cur[1] == '>'))
	    ctxt->node->extra = NODE_IS_EMPTY;
    }
    if (reader != NULL)
	reader->state = XML_TEXTREADER_ELEMENT;
}

/**
 * xmlTextReaderEndElementNs:
 * @ctx: the user data (XML parser context)
 * @localname:  the local name of the element
 * @prefix:  the element namespace prefix if available
 * @URI:  the element namespace name if available
 *
 * called when an ending tag has been processed.
 */
static void
xmlTextReaderEndElementNs(void *ctx,
                          const xmlChar * localname,
                          const xmlChar * prefix,
		          const xmlChar * URI)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlTextReaderPtr reader = ctxt->_private;

#ifdef DEBUG_CALLBACKS
    printf("xmlTextReaderEndElementNs(%s)\n", localname);
#endif
    if ((reader != NULL) && (reader->endElementNs != NULL)) {
	reader->endElementNs(ctx, localname, prefix, URI);
    }
}


/**
 * xmlTextReaderCharacters:
 * @ctx: the user data (XML parser context)
 * @ch:  a xmlChar string
 * @len: the number of xmlChar
 *
 * receiving some chars from the parser.
 */
static void
xmlTextReaderCharacters(void *ctx, const xmlChar *ch, int len)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlTextReaderPtr reader = ctxt->_private;

#ifdef DEBUG_CALLBACKS
    printf("xmlTextReaderCharacters()\n");
#endif
    if ((reader != NULL) && (reader->characters != NULL)) {
	reader->characters(ctx, ch, len);
    }
}

/**
 * xmlTextReaderCDataBlock:
 * @ctx: the user data (XML parser context)
 * @value:  The pcdata content
 * @len:  the block length
 *
 * called when a pcdata block has been parsed
 */
static void
xmlTextReaderCDataBlock(void *ctx, const xmlChar *ch, int len)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlTextReaderPtr reader = ctxt->_private;

#ifdef DEBUG_CALLBACKS
    printf("xmlTextReaderCDataBlock()\n");
#endif
    if ((reader != NULL) && (reader->cdataBlock != NULL)) {
	reader->cdataBlock(ctx, ch, len);
    }
}

/**
 * xmlTextReaderPushData:
 * @reader:  the xmlTextReaderPtr used
 *
 * Push data down the progressive parser until a significant callback
 * got raised.
 *
 * Returns -1 in case of failure, 0 otherwise
 */
static int
xmlTextReaderPushData(xmlTextReaderPtr reader) {
    xmlBufferPtr inbuf;
    int val, s;
    xmlTextReaderState oldstate;

    if ((reader->input == NULL) || (reader->input->buffer == NULL))
	return(-1);

    oldstate = reader->state;
    reader->state = XML_TEXTREADER_NONE;
    inbuf = reader->input->buffer;

    while (reader->state == XML_TEXTREADER_NONE) {
	if (inbuf->use < reader->cur + CHUNK_SIZE) {
	    /*
	     * Refill the buffer unless we are at the end of the stream
	     */
	    if (reader->mode != XML_TEXTREADER_MODE_EOF) {
		val = xmlParserInputBufferRead(reader->input, 4096);
		if ((val == 0) &&
		    (inbuf->alloc == XML_BUFFER_ALLOC_IMMUTABLE)) {
		    if (inbuf->use == reader->cur) {
			reader->mode = XML_TEXTREADER_MODE_EOF;
			reader->state = oldstate;
		    }
		} else if (val < 0) {
		    reader->mode = XML_TEXTREADER_MODE_EOF;
		    reader->state = oldstate;
		    if ((oldstate != XML_TEXTREADER_START) ||
			(reader->ctxt->myDoc != NULL))
			return(val);
		} else if (val == 0) {
		    /* mark the end of the stream and process the remains */
		    reader->mode = XML_TEXTREADER_MODE_EOF;
		    break;
		}

	    } else
		break;
	}
	/*
	 * parse by block of CHUNK_SIZE bytes, various tests show that
	 * it's the best tradeoff at least on a 1.2GH Duron
	 */
	if (inbuf->use >= reader->cur + CHUNK_SIZE) {
	    val = xmlParseChunk(reader->ctxt,
		          (const char *) &inbuf->content[reader->cur],
			  CHUNK_SIZE, 0);
	    reader->cur += CHUNK_SIZE;
	    if ((val != 0) || (reader->ctxt->wellFormed == 0))
		return(-1);
	} else {
	    s = inbuf->use - reader->cur;
	    val = xmlParseChunk(reader->ctxt,
		          (const char *) &inbuf->content[reader->cur],
			  s, 0);
	    reader->cur += s;
	    if ((val != 0) || (reader->ctxt->wellFormed == 0))
		return(-1);
	    break;
	}
    }

    /*
     * Discard the consumed input when needed and possible
     */
    if (reader->mode == XML_TEXTREADER_MODE_INTERACTIVE) {
        if (inbuf->alloc != XML_BUFFER_ALLOC_IMMUTABLE) {
	    if ((reader->cur >= 4096) &&
		(inbuf->use - reader->cur <= CHUNK_SIZE)) {
		val = xmlBufferShrink(inbuf, reader->cur);
		if (val >= 0) {
		    reader->cur -= val;
		}
	    }
	}
    }

    /*
     * At the end of the stream signal that the work is done to the Push
     * parser.
     */
    else if (reader->mode == XML_TEXTREADER_MODE_EOF) {
	if (reader->state != XML_TEXTREADER_DONE) {
	    s = inbuf->use - reader->cur;
	    val = xmlParseChunk(reader->ctxt,
		    (const char *) &inbuf->content[reader->cur],
		    s, 1);
	    reader->cur = inbuf->use;
	    reader->state  = XML_TEXTREADER_DONE;
	    if ((val != 0) || (reader->ctxt->wellFormed == 0))
	        return(-1);
	}
    }
    reader->state = oldstate;
    return(0);
}

#ifdef LIBXML_REGEXP_ENABLED
/**
 * xmlTextReaderValidatePush:
 * @reader:  the xmlTextReaderPtr used
 *
 * Push the current node for validation
 */
static void
xmlTextReaderValidatePush(xmlTextReaderPtr reader ATTRIBUTE_UNUSED) {
    xmlNodePtr node = reader->node;

#ifdef LIBXML_VALID_ENABLED
    if ((reader->validate == XML_TEXTREADER_VALIDATE_DTD) &&
        (reader->ctxt != NULL) && (reader->ctxt->validate == 1)) {
	if ((node->ns == NULL) || (node->ns->prefix == NULL)) {
	    reader->ctxt->valid &= xmlValidatePushElement(&reader->ctxt->vctxt,
				    reader->ctxt->myDoc, node, node->name);
	} else {
	    /* TODO use the BuildQName interface */
	    xmlChar *qname;

	    qname = xmlStrdup(node->ns->prefix);
	    qname = xmlStrcat(qname, BAD_CAST ":");
	    qname = xmlStrcat(qname, node->name);
	    reader->ctxt->valid &= xmlValidatePushElement(&reader->ctxt->vctxt,
				    reader->ctxt->myDoc, node, qname);
	    if (qname != NULL)
		xmlFree(qname);
	}
    }
#endif /* LIBXML_VALID_ENABLED */
#ifdef LIBXML_SCHEMAS_ENABLED
    if ((reader->validate == XML_TEXTREADER_VALIDATE_RNG) &&
               (reader->rngValidCtxt != NULL)) {
	int ret;

	if (reader->rngFullNode != NULL) return;
	ret = xmlRelaxNGValidatePushElement(reader->rngValidCtxt,
	                                    reader->ctxt->myDoc,
					    node);
	if (ret == 0) {
	    /*
	     * this element requires a full tree
	     */
	    node = xmlTextReaderExpand(reader);
	    if (node == NULL) {
printf("Expand failed !\n");
	        ret = -1;
	    } else {
		ret = xmlRelaxNGValidateFullElement(reader->rngValidCtxt,
						    reader->ctxt->myDoc,
						    node);
		reader->rngFullNode = node;
	    }
	}
	if (ret != 1)
	    reader->rngValidErrors++;
    }
#endif
}

/**
 * xmlTextReaderValidateCData:
 * @reader:  the xmlTextReaderPtr used
 * @data:  pointer to the CData
 * @len:  lenght of the CData block in bytes.
 *
 * Push some CData for validation
 */
static void
xmlTextReaderValidateCData(xmlTextReaderPtr reader,
                           const xmlChar *data, int len) {
#ifdef LIBXML_VALID_ENABLED
    if ((reader->validate == XML_TEXTREADER_VALIDATE_DTD) &&
        (reader->ctxt != NULL) && (reader->ctxt->validate == 1)) {
	reader->ctxt->valid &= xmlValidatePushCData(&reader->ctxt->vctxt,
	                                            data, len);
    }
#endif /* LIBXML_VALID_ENABLED */
#ifdef LIBXML_SCHEMAS_ENABLED
    if ((reader->validate == XML_TEXTREADER_VALIDATE_RNG) &&
               (reader->rngValidCtxt != NULL)) {
	int ret;

	if (reader->rngFullNode != NULL) return;
	ret = xmlRelaxNGValidatePushCData(reader->rngValidCtxt, data, len);
	if (ret != 1)
	    reader->rngValidErrors++;
    }
#endif
}

/**
 * xmlTextReaderValidatePop:
 * @reader:  the xmlTextReaderPtr used
 *
 * Pop the current node from validation
 */
static void
xmlTextReaderValidatePop(xmlTextReaderPtr reader) {
    xmlNodePtr node = reader->node;

#ifdef LIBXML_VALID_ENABLED
    if ((reader->validate == XML_TEXTREADER_VALIDATE_DTD) &&
        (reader->ctxt != NULL) && (reader->ctxt->validate == 1)) {
	if ((node->ns == NULL) || (node->ns->prefix == NULL)) {
	    reader->ctxt->valid &= xmlValidatePopElement(&reader->ctxt->vctxt,
				    reader->ctxt->myDoc, node, node->name);
	} else {
	    /* TODO use the BuildQName interface */
	    xmlChar *qname;

	    qname = xmlStrdup(node->ns->prefix);
	    qname = xmlStrcat(qname, BAD_CAST ":");
	    qname = xmlStrcat(qname, node->name);
	    reader->ctxt->valid &= xmlValidatePopElement(&reader->ctxt->vctxt,
				    reader->ctxt->myDoc, node, qname);
	    if (qname != NULL)
		xmlFree(qname);
	}
    }
#endif /* LIBXML_VALID_ENABLED */
#ifdef LIBXML_SCHEMAS_ENABLED
    if ((reader->validate == XML_TEXTREADER_VALIDATE_RNG) &&
               (reader->rngValidCtxt != NULL)) {
	int ret;

	if (reader->rngFullNode != NULL) {
	    if (node == reader->rngFullNode)
	        reader->rngFullNode = NULL;
	    return;
	}
	ret = xmlRelaxNGValidatePopElement(reader->rngValidCtxt,
	                                   reader->ctxt->myDoc,
					   node);
	if (ret != 1)
	    reader->rngValidErrors++;
    }
#endif
}

/**
 * xmlTextReaderValidateEntity:
 * @reader:  the xmlTextReaderPtr used
 *
 * Handle the validation when an entity reference is encountered and
 * entity substitution is not activated. As a result the parser interface
 * must walk through the entity and do the validation calls
 */
static void
xmlTextReaderValidateEntity(xmlTextReaderPtr reader) {
    xmlNodePtr oldnode = reader->node;
    xmlNodePtr node = reader->node;
    xmlParserCtxtPtr ctxt = reader->ctxt;

    do {
	if (node->type == XML_ENTITY_REF_NODE) {
	    /*
	     * Case where the underlying tree is not availble, lookup the entity
	     * and walk it.
	     */
	    if ((node->children == NULL) && (ctxt->sax != NULL) &&
		(ctxt->sax->getEntity != NULL)) {
		node->children = (xmlNodePtr)
		    ctxt->sax->getEntity(ctxt, node->name);
	    }

	    if ((node->children != NULL) &&
		(node->children->type == XML_ENTITY_DECL) &&
		(node->children->children != NULL)) {
		xmlTextReaderEntPush(reader, node);
		node = node->children->children;
		continue;
	    } else {
		/*
		 * The error has probably be raised already.
		 */
		if (node == oldnode)
		    break;
		node = node->next;
	    }
#ifdef LIBXML_REGEXP_ENABLED
	} else if (node->type == XML_ELEMENT_NODE) {
	    reader->node = node;
	    xmlTextReaderValidatePush(reader);
	} else if ((node->type == XML_TEXT_NODE) ||
		   (node->type == XML_CDATA_SECTION_NODE)) {
            xmlTextReaderValidateCData(reader, node->content,
	                               xmlStrlen(node->content));
#endif
	}

	/*
	 * go to next node
	 */
	if (node->children != NULL) {
	    node = node->children;
	    continue;
	} else if (node->type == XML_ELEMENT_NODE) {
	    xmlTextReaderValidatePop(reader);
	}
	if (node->next != NULL) {
	    node = node->next;
	    continue;
	}
	do {
	    node = node->parent;
	    if (node->type == XML_ELEMENT_NODE) {
	        xmlNodePtr tmp;
		if (reader->entNr == 0) {
		    while ((tmp = node->last) != NULL) {
			if ((tmp->extra & NODE_IS_PRESERVED) == 0) {
			    xmlUnlinkNode(tmp);
			    xmlTextReaderFreeNode(reader, tmp);
			} else
			    break;
		    }
		}
		reader->node = node;
		xmlTextReaderValidatePop(reader);
	    }
	    if ((node->type == XML_ENTITY_DECL) &&
		(reader->ent != NULL) && (reader->ent->children == node)) {
		node = xmlTextReaderEntPop(reader);
	    }
	    if (node == oldnode)
		break;
	    if (node->next != NULL) {
		node = node->next;
		break;
	    }
	} while ((node != NULL) && (node != oldnode));
    } while ((node != NULL) && (node != oldnode));
    reader->node = oldnode;
}
#endif /* LIBXML_REGEXP_ENABLED */


/**
 * xmlTextReaderGetSuccessor:
 * @cur:  the current node
 *
 * Get the successor of a node if available.
 *
 * Returns the successor node or NULL
 */
static xmlNodePtr
xmlTextReaderGetSuccessor(xmlNodePtr cur) {
    if (cur == NULL) return(NULL) ; /* ERROR */
    if (cur->next != NULL) return(cur->next) ;
    do {
        cur = cur->parent;
        if (cur == NULL) break;
        if (cur->next != NULL) return(cur->next);
    } while (cur != NULL);
    return(cur);
}

/**
 * xmlTextReaderDoExpand:
 * @reader:  the xmlTextReaderPtr used
 *
 * Makes sure that the current node is fully read as well as all its
 * descendant. It means the full DOM subtree must be available at the
 * end of the call.
 *
 * Returns 1 if the node was expanded successfully, 0 if there is no more
 *          nodes to read, or -1 in case of error
 */
static int
xmlTextReaderDoExpand(xmlTextReaderPtr reader) {
    int val;

    if ((reader == NULL) || (reader->node == NULL) || (reader->ctxt == NULL))
        return(-1);
    do {
	if (reader->ctxt->instate == XML_PARSER_EOF) return(1);

        if (xmlTextReaderGetSuccessor(reader->node) != NULL)
	    return(1);
	if (reader->ctxt->nodeNr < reader->depth)
	    return(1);
	if (reader->mode == XML_TEXTREADER_MODE_EOF)
	    return(1);
	val = xmlTextReaderPushData(reader);
	if (val < 0){
	    reader->mode = XML_TEXTREADER_MODE_ERROR;
	    return(-1);
	}
    } while(reader->mode != XML_TEXTREADER_MODE_EOF);
    return(1);
}

/**
 * xmlTextReaderCollectSiblings:
 * @node:    the first child
 *
 *  Traverse depth-first through all sibling nodes and their children
 *  nodes and concatenate their content. This is an auxiliary function
 *  to xmlTextReaderReadString.
 *
 *  Returns a string containing the content, or NULL in case of error.
 */
static xmlChar *
xmlTextReaderCollectSiblings(xmlNodePtr node)
{
    xmlBufferPtr buffer;
    xmlChar *ret;

    buffer = xmlBufferCreate();
    if (buffer == NULL)
       return NULL;

    for ( ; node != NULL; node = node->next) {
       switch (node->type) {
       case XML_TEXT_NODE:
       case XML_CDATA_SECTION_NODE:
           xmlBufferCat(buffer, node->content);
           break;
       case XML_ELEMENT_NODE: {
           xmlChar *tmp;

	   tmp = xmlTextReaderCollectSiblings(node->children);
           xmlBufferCat(buffer, tmp);
	   xmlFree(tmp);
	   break;
       }
       default:
           break;
       }
    }
    ret = buffer->content;
    buffer->content = NULL;
    xmlBufferFree(buffer);
    return(ret);
}

/**
 * xmlTextReaderRead:
 * @reader:  the xmlTextReaderPtr used
 *
 *  Moves the position of the current instance to the next node in
 *  the stream, exposing its properties.
 *
 *  Returns 1 if the node was read successfully, 0 if there is no more
 *          nodes to read, or -1 in case of error
 */
int
xmlTextReaderRead(xmlTextReaderPtr reader) {
    int val, olddepth = 0;
    xmlTextReaderState oldstate = XML_TEXTREADER_START;
    xmlNodePtr oldnode = NULL;


    if (reader == NULL)
	return(-1);
    reader->curnode = NULL;
    if (reader->doc != NULL)
        return(xmlTextReaderReadTree(reader));
    if (reader->ctxt == NULL)
	return(-1);
    if (reader->ctxt->wellFormed != 1)
	return(-1);

#ifdef DEBUG_READER
    fprintf(stderr, "\nREAD ");
    DUMP_READER
#endif
    if (reader->mode == XML_TEXTREADER_MODE_INITIAL) {
	reader->mode = XML_TEXTREADER_MODE_INTERACTIVE;
	/*
	 * Initial state
	 */
	do {
	    val = xmlTextReaderPushData(reader);
		if (val < 0){
			reader->mode = XML_TEXTREADER_MODE_ERROR;
			reader->state = XML_TEXTREADER_ERROR;
		return(-1);
		}
	} while ((reader->ctxt->node == NULL) &&
		 ((reader->mode != XML_TEXTREADER_MODE_EOF) &&
		  (reader->state != XML_TEXTREADER_DONE)));
	if (reader->ctxt->node == NULL) {
	    if (reader->ctxt->myDoc != NULL) {
		reader->node = reader->ctxt->myDoc->children;
	    }
	    if (reader->node == NULL){
			reader->mode = XML_TEXTREADER_MODE_ERROR;
			reader->state = XML_TEXTREADER_ERROR;
		return(-1);
		}
	    reader->state = XML_TEXTREADER_ELEMENT;
	} else {
	    if (reader->ctxt->myDoc != NULL) {
		reader->node = reader->ctxt->myDoc->children;
	    }
	    if (reader->node == NULL)
		reader->node = reader->ctxt->nodeTab[0];
	    reader->state = XML_TEXTREADER_ELEMENT;
	}
	reader->depth = 0;
	reader->ctxt->parseMode = XML_PARSE_READER;
	goto node_found;
    }
    oldstate = reader->state;
    olddepth = reader->ctxt->nodeNr;
    oldnode = reader->node;

get_next_node:
    if (reader->node == NULL) {
	if (reader->mode == XML_TEXTREADER_MODE_EOF)
	    return(0);
	else
	    return(-1);
    }

    /*
     * If we are not backtracking on ancestors or examined nodes,
     * that the parser didn't finished or that we arent at the end
     * of stream, continue processing.
     */
    while ((reader->node != NULL) && (reader->node->next == NULL) &&
	   (reader->ctxt->nodeNr == olddepth) &&
           ((oldstate == XML_TEXTREADER_BACKTRACK) ||
            (reader->node->children == NULL) ||
	    (reader->node->type == XML_ENTITY_REF_NODE) ||
	    ((reader->node->children != NULL) &&
	     (reader->node->children->type == XML_TEXT_NODE) &&
	     (reader->node->children->next == NULL)) ||
	    (reader->node->type == XML_DTD_NODE) ||
	    (reader->node->type == XML_DOCUMENT_NODE) ||
	    (reader->node->type == XML_HTML_DOCUMENT_NODE)) &&
	   ((reader->ctxt->node == NULL) ||
	    (reader->ctxt->node == reader->node) ||
	    (reader->ctxt->node == reader->node->parent)) &&
	   (reader->ctxt->instate != XML_PARSER_EOF)) {
	val = xmlTextReaderPushData(reader);
	if (val < 0){
		reader->mode = XML_TEXTREADER_MODE_ERROR;
		reader->state = XML_TEXTREADER_ERROR;
	    return(-1);
	}
	if (reader->node == NULL)
	    goto node_end;
    }
    if (oldstate != XML_TEXTREADER_BACKTRACK) {
	if ((reader->node->children != NULL) &&
	    (reader->node->type != XML_ENTITY_REF_NODE) &&
	    (reader->node->type != XML_XINCLUDE_START) &&
	    (reader->node->type != XML_DTD_NODE)) {
	    reader->node = reader->node->children;
	    reader->depth++;
	    reader->state = XML_TEXTREADER_ELEMENT;
	    goto node_found;
	}
    }
    if (reader->node->next != NULL) {
	if ((oldstate == XML_TEXTREADER_ELEMENT) &&
            (reader->node->type == XML_ELEMENT_NODE) &&
	    (reader->node->children == NULL) &&
	    ((reader->node->extra & NODE_IS_EMPTY) == 0)
#ifdef LIBXML_XINCLUDE_ENABLED
	    && (reader->in_xinclude <= 0)
#endif
	    ) {
	    reader->state = XML_TEXTREADER_END;
	    goto node_found;
	}
#ifdef LIBXML_REGEXP_ENABLED
	if ((reader->validate) &&
	    (reader->node->type == XML_ELEMENT_NODE))
	    xmlTextReaderValidatePop(reader);
#endif /* LIBXML_REGEXP_ENABLED */
        if ((reader->preserves > 0) &&
	    (reader->node->extra & NODE_IS_SPRESERVED))
	    reader->preserves--;
	reader->node = reader->node->next;
	reader->state = XML_TEXTREADER_ELEMENT;

	/*
	 * Cleanup of the old node
	 */
	if ((reader->preserves == 0) &&
#ifdef LIBXML_XINCLUDE_ENABLED
	    (reader->in_xinclude == 0) &&
#endif
	    (reader->entNr == 0) &&
	    (reader->node->prev != NULL) &&
	    (reader->node->prev->type != XML_DTD_NODE)) {
	    xmlNodePtr tmp = reader->node->prev;
	    if ((tmp->extra & NODE_IS_PRESERVED) == 0) {
		xmlUnlinkNode(tmp);
		xmlTextReaderFreeNode(reader, tmp);
	    }
	}

	goto node_found;
    }
    if ((oldstate == XML_TEXTREADER_ELEMENT) &&
	(reader->node->type == XML_ELEMENT_NODE) &&
	(reader->node->children == NULL) &&
	((reader->node->extra & NODE_IS_EMPTY) == 0)) {;
	reader->state = XML_TEXTREADER_END;
	goto node_found;
    }
#ifdef LIBXML_REGEXP_ENABLED
    if ((reader->validate) && (reader->node->type == XML_ELEMENT_NODE))
	xmlTextReaderValidatePop(reader);
#endif /* LIBXML_REGEXP_ENABLED */
    if ((reader->preserves > 0) &&
	(reader->node->extra & NODE_IS_SPRESERVED))
	reader->preserves--;
    reader->node = reader->node->parent;
    if ((reader->node == NULL) ||
	(reader->node->type == XML_DOCUMENT_NODE) ||
#ifdef LIBXML_DOCB_ENABLED
	(reader->node->type == XML_DOCB_DOCUMENT_NODE) ||
#endif
	(reader->node->type == XML_HTML_DOCUMENT_NODE)) {
	if (reader->mode != XML_TEXTREADER_MODE_EOF) {
	    val = xmlParseChunk(reader->ctxt, "", 0, 1);
	    reader->state = XML_TEXTREADER_DONE;
	    if (val != 0)
	        return(-1);
	}
	reader->node = NULL;
	reader->depth = -1;

	/*
	 * Cleanup of the old node
	 */
	if ((oldnode != NULL) && (reader->preserves == 0) &&
#ifdef LIBXML_XINCLUDE_ENABLED
	    (reader->in_xinclude == 0) &&
#endif
	    (reader->entNr == 0) &&
	    (oldnode->type != XML_DTD_NODE) &&
	    ((oldnode->extra & NODE_IS_PRESERVED) == 0)) {
	    xmlUnlinkNode(oldnode);
	    xmlTextReaderFreeNode(reader, oldnode);
	}

	goto node_end;
    }
    if ((reader->preserves == 0) &&
#ifdef LIBXML_XINCLUDE_ENABLED
        (reader->in_xinclude == 0) &&
#endif
	(reader->entNr == 0) &&
        (reader->node->last != NULL) &&
        ((reader->node->last->extra & NODE_IS_PRESERVED) == 0)) {
	xmlNodePtr tmp = reader->node->last;
	xmlUnlinkNode(tmp);
	xmlTextReaderFreeNode(reader, tmp);
    }
    reader->depth--;
    reader->state = XML_TEXTREADER_BACKTRACK;

node_found:
    DUMP_READER

    /*
     * If we are in the middle of a piece of CDATA make sure it's finished
     */
    if ((reader->node != NULL) &&
        (reader->node->next == NULL) &&
        ((reader->node->type == XML_TEXT_NODE) ||
	 (reader->node->type == XML_CDATA_SECTION_NODE))) {
            if (xmlTextReaderExpand(reader) == NULL)
	        return -1;
    }

#ifdef LIBXML_XINCLUDE_ENABLED
    /*
     * Handle XInclude if asked for
     */
    if ((reader->xinclude) && (reader->node != NULL) &&
	(reader->node->type == XML_ELEMENT_NODE) &&
	(reader->node->ns != NULL) &&
	((xmlStrEqual(reader->node->ns->href, XINCLUDE_NS)) ||
	 (xmlStrEqual(reader->node->ns->href, XINCLUDE_OLD_NS)))) {
	if (reader->xincctxt == NULL) {
	    reader->xincctxt = xmlXIncludeNewContext(reader->ctxt->myDoc);
	    xmlXIncludeSetFlags(reader->xincctxt,
	                        reader->parserFlags & (~XML_PARSE_NOXINCNODE));
	}
	/*
	 * expand that node and process it
	 */
	if (xmlTextReaderExpand(reader) == NULL)
	    return -1;
	xmlXIncludeProcessNode(reader->xincctxt, reader->node);
    }
    if ((reader->node != NULL) && (reader->node->type == XML_XINCLUDE_START)) {
        reader->in_xinclude++;
	goto get_next_node;
    }
    if ((reader->node != NULL) && (reader->node->type == XML_XINCLUDE_END)) {
        reader->in_xinclude--;
	goto get_next_node;
    }
#endif
    /*
     * Handle entities enter and exit when in entity replacement mode
     */
    if ((reader->node != NULL) &&
	(reader->node->type == XML_ENTITY_REF_NODE) &&
	(reader->ctxt != NULL) && (reader->ctxt->replaceEntities == 1)) {
	/*
	 * Case where the underlying tree is not availble, lookup the entity
	 * and walk it.
	 */
	if ((reader->node->children == NULL) && (reader->ctxt->sax != NULL) &&
	    (reader->ctxt->sax->getEntity != NULL)) {
	    reader->node->children = (xmlNodePtr)
		reader->ctxt->sax->getEntity(reader->ctxt, reader->node->name);
	}

	if ((reader->node->children != NULL) &&
	    (reader->node->children->type == XML_ENTITY_DECL) &&
	    (reader->node->children->children != NULL)) {
	    xmlTextReaderEntPush(reader, reader->node);
	    reader->node = reader->node->children->children;
	}
#ifdef LIBXML_REGEXP_ENABLED
    } else if ((reader->node != NULL) &&
	       (reader->node->type == XML_ENTITY_REF_NODE) &&
	       (reader->ctxt != NULL) && (reader->validate)) {
	xmlTextReaderValidateEntity(reader);
#endif /* LIBXML_REGEXP_ENABLED */
    }
    if ((reader->node != NULL) &&
	(reader->node->type == XML_ENTITY_DECL) &&
	(reader->ent != NULL) && (reader->ent->children == reader->node)) {
	reader->node = xmlTextReaderEntPop(reader);
	reader->depth++;
        goto get_next_node;
    }
#ifdef LIBXML_REGEXP_ENABLED
    if ((reader->validate) && (reader->node != NULL)) {
	xmlNodePtr node = reader->node;

	if ((node->type == XML_ELEMENT_NODE) &&
            ((reader->state != XML_TEXTREADER_END) &&
	     (reader->state != XML_TEXTREADER_BACKTRACK))) {
	    xmlTextReaderValidatePush(reader);
	} else if ((node->type == XML_TEXT_NODE) ||
		   (node->type == XML_CDATA_SECTION_NODE)) {
            xmlTextReaderValidateCData(reader, node->content,
	                               xmlStrlen(node->content));
	}
    }
#endif /* LIBXML_REGEXP_ENABLED */
#ifdef LIBXML_PATTERN_ENABLED
    if ((reader->patternNr > 0) && (reader->state != XML_TEXTREADER_END) &&
        (reader->state != XML_TEXTREADER_BACKTRACK)) {
        int i;
	for (i = 0;i < reader->patternNr;i++) {
	     if (xmlPatternMatch(reader->patternTab[i], reader->node) == 1) {
	         xmlTextReaderPreserve(reader);
		 break;
             }
	}
    }
#endif /* LIBXML_PATTERN_ENABLED */
#ifdef LIBXML_SCHEMAS_ENABLED
    if ((reader->validate == XML_TEXTREADER_VALIDATE_XSD) &&
        (reader->xsdValidErrors == 0) &&
	(reader->xsdValidCtxt != NULL)) {
	reader->xsdValidErrors = !xmlSchemaIsValid(reader->xsdValidCtxt);
    }
#endif /* LIBXML_PATTERN_ENABLED */
    return(1);
node_end:
    reader->state = XML_TEXTREADER_DONE;
    return(0);
}

/**
 * xmlTextReaderReadState:
 * @reader:  the xmlTextReaderPtr used
 *
 * Gets the read state of the reader.
 *
 * Returns the state value, or -1 in case of error
 */
int
xmlTextReaderReadState(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(-1);
    return(reader->mode);
}

/**
 * xmlTextReaderExpand:
 * @reader:  the xmlTextReaderPtr used
 *
 * Reads the contents of the current node and the full subtree. It then makes
 * the subtree available until the next xmlTextReaderRead() call
 *
 * Returns a node pointer valid until the next xmlTextReaderRead() call
 *         or NULL in case of error.
 */
xmlNodePtr
xmlTextReaderExpand(xmlTextReaderPtr reader) {
    if ((reader == NULL) || (reader->node == NULL))
        return(NULL);
    if (reader->doc != NULL)
        return(reader->node);
    if (reader->ctxt == NULL)
        return(NULL);
    if (xmlTextReaderDoExpand(reader) < 0)
        return(NULL);
    return(reader->node);
}

/**
 * xmlTextReaderNext:
 * @reader:  the xmlTextReaderPtr used
 *
 * Skip to the node following the current one in document order while
 * avoiding the subtree if any.
 *
 * Returns 1 if the node was read successfully, 0 if there is no more
 *          nodes to read, or -1 in case of error
 */
int
xmlTextReaderNext(xmlTextReaderPtr reader) {
    int ret;
    xmlNodePtr cur;

    if (reader == NULL)
	return(-1);
    if (reader->doc != NULL)
        return(xmlTextReaderNextTree(reader));
    cur = reader->node;
    if ((cur == NULL) || (cur->type != XML_ELEMENT_NODE))
        return(xmlTextReaderRead(reader));
    if (reader->state == XML_TEXTREADER_END || reader->state == XML_TEXTREADER_BACKTRACK)
        return(xmlTextReaderRead(reader));
    if (cur->extra & NODE_IS_EMPTY)
        return(xmlTextReaderRead(reader));
    do {
        ret = xmlTextReaderRead(reader);
	if (ret != 1)
	    return(ret);
    } while (reader->node != cur);
    return(xmlTextReaderRead(reader));
}

#ifdef LIBXML_WRITER_ENABLED
/**
 * xmlTextReaderReadInnerXml:
 * @reader:  the xmlTextReaderPtr used
 *
 * Reads the contents of the current node, including child nodes and markup.
 *
 * Returns a string containing the XML content, or NULL if the current node
 *         is neither an element nor attribute, or has no child nodes. The
 *         string must be deallocated by the caller.
 */
xmlChar *
xmlTextReaderReadInnerXml(xmlTextReaderPtr reader ATTRIBUTE_UNUSED)
{
    xmlChar *resbuf;
    xmlNodePtr node, cur_node;
    xmlBufferPtr buff, buff2;
    xmlDocPtr doc;

    if (xmlTextReaderExpand(reader) == NULL) {
        return NULL;
    }
    doc = reader->doc;
    buff = xmlBufferCreate();
    for (cur_node = reader->node->children; cur_node != NULL;
         cur_node = cur_node->next) {
        node = xmlDocCopyNode(cur_node, doc, 1);
        buff2 = xmlBufferCreate();
        if (xmlNodeDump(buff2, doc, node, 0, 0) == -1) {
            xmlFreeNode(node);
            xmlBufferFree(buff2);
            xmlBufferFree(buff);
            return NULL;
        }
        xmlBufferCat(buff, buff2->content);
        xmlFreeNode(node);
        xmlBufferFree(buff2);
    }
    resbuf = buff->content;
    buff->content = NULL;

    xmlBufferFree(buff);
    return resbuf;
}
#endif

#ifdef LIBXML_WRITER_ENABLED
/**
 * xmlTextReaderReadOuterXml:
 * @reader:  the xmlTextReaderPtr used
 *
 * Reads the contents of the current node, including child nodes and markup.
 *
 * Returns a string containing the XML content, or NULL if the current node
 *         is neither an element nor attribute, or has no child nodes. The
 *         string must be deallocated by the caller.
 */
xmlChar *
xmlTextReaderReadOuterXml(xmlTextReaderPtr reader ATTRIBUTE_UNUSED)
{
    xmlChar *resbuf;
    xmlNodePtr node;
    xmlBufferPtr buff;
    xmlDocPtr doc;

    node = reader->node;
    doc = reader->doc;
    if (xmlTextReaderExpand(reader) == NULL) {
        return NULL;
    }
    node = xmlDocCopyNode(node, doc, 1);
    buff = xmlBufferCreate();
    if (xmlNodeDump(buff, doc, node, 0, 0) == -1) {
        xmlFreeNode(node);
        xmlBufferFree(buff);
        return NULL;
    }

    resbuf = buff->content;
    buff->content = NULL;

    xmlFreeNode(node);
    xmlBufferFree(buff);
    return resbuf;
}
#endif

/**
 * xmlTextReaderReadString:
 * @reader:  the xmlTextReaderPtr used
 *
 * Reads the contents of an element or a text node as a string.
 *
 * Returns a string containing the contents of the Element or Text node,
 *         or NULL if the reader is positioned on any other type of node.
 *         The string must be deallocated by the caller.
 */
xmlChar *
xmlTextReaderReadString(xmlTextReaderPtr reader)
{
    xmlNodePtr node;

    if ((reader == NULL) || (reader->node == NULL))
       return(NULL);

    node = (reader->curnode != NULL) ? reader->curnode : reader->node;
    switch (node->type) {
    case XML_TEXT_NODE:
       if (node->content != NULL)
           return(xmlStrdup(node->content));
       break;
    case XML_ELEMENT_NODE:
	if (xmlTextReaderDoExpand(reader) != -1) {
	    return xmlTextReaderCollectSiblings(node->children);
	}
    case XML_ATTRIBUTE_NODE:
	TODO
	break;
    default:
       break;
    }
    return(NULL);
}

#if 0
/**
 * xmlTextReaderReadBase64:
 * @reader:  the xmlTextReaderPtr used
 * @array:  a byte array to store the content.
 * @offset:  the zero-based index into array where the method should
 *           begin to write.
 * @len:  the number of bytes to write.
 *
 * Reads and decodes the Base64 encoded contents of an element and
 * stores the result in a byte buffer.
 *
 * Returns the number of bytes written to array, or zero if the current
 *         instance is not positioned on an element or -1 in case of error.
 */
int
xmlTextReaderReadBase64(xmlTextReaderPtr reader,
                        unsigned char *array ATTRIBUTE_UNUSED,
	                int offset ATTRIBUTE_UNUSED,
			int len ATTRIBUTE_UNUSED) {
    if ((reader == NULL) || (reader->ctxt == NULL))
	return(-1);
    if (reader->ctxt->wellFormed != 1)
	return(-1);

    if ((reader->node == NULL) || (reader->node->type == XML_ELEMENT_NODE))
	return(0);
    TODO
    return(0);
}

/**
 * xmlTextReaderReadBinHex:
 * @reader:  the xmlTextReaderPtr used
 * @array:  a byte array to store the content.
 * @offset:  the zero-based index into array where the method should
 *           begin to write.
 * @len:  the number of bytes to write.
 *
 * Reads and decodes the BinHex encoded contents of an element and
 * stores the result in a byte buffer.
 *
 * Returns the number of bytes written to array, or zero if the current
 *         instance is not positioned on an element or -1 in case of error.
 */
int
xmlTextReaderReadBinHex(xmlTextReaderPtr reader,
                        unsigned char *array ATTRIBUTE_UNUSED,
	                int offset ATTRIBUTE_UNUSED,
			int len ATTRIBUTE_UNUSED) {
    if ((reader == NULL) || (reader->ctxt == NULL))
	return(-1);
    if (reader->ctxt->wellFormed != 1)
	return(-1);

    if ((reader->node == NULL) || (reader->node->type == XML_ELEMENT_NODE))
	return(0);
    TODO
    return(0);
}
#endif

/************************************************************************
 *									*
 *			Operating on a preparsed tree			*
 *									*
 ************************************************************************/
static int
xmlTextReaderNextTree(xmlTextReaderPtr reader)
{
    if (reader == NULL)
        return(-1);

    if (reader->state == XML_TEXTREADER_END)
        return(0);

    if (reader->node == NULL) {
        if (reader->doc->children == NULL) {
            reader->state = XML_TEXTREADER_END;
            return(0);
        }

        reader->node = reader->doc->children;
        reader->state = XML_TEXTREADER_START;
        return(1);
    }

    if (reader->state != XML_TEXTREADER_BACKTRACK) {
	/* Here removed traversal to child, because we want to skip the subtree,
	replace with traversal to sibling to skip subtree */
        if (reader->node->next != 0) {
	    /* Move to sibling if present,skipping sub-tree */
            reader->node = reader->node->next;
            reader->state = XML_TEXTREADER_START;
            return(1);
        }

	/* if reader->node->next is NULL mean no subtree for current node,
	so need to move to sibling of parent node if present */
        if ((reader->node->type == XML_ELEMENT_NODE) ||
            (reader->node->type == XML_ATTRIBUTE_NODE)) {
            reader->state = XML_TEXTREADER_BACKTRACK;
	    /* This will move to parent if present */
            xmlTextReaderRead(reader);
        }
    }

    if (reader->node->next != 0) {
        reader->node = reader->node->next;
        reader->state = XML_TEXTREADER_START;
        return(1);
    }

    if (reader->node->parent != 0) {
        if (reader->node->parent->type == XML_DOCUMENT_NODE) {
            reader->state = XML_TEXTREADER_END;
            return(0);
        }

        reader->node = reader->node->parent;
        reader->depth--;
        reader->state = XML_TEXTREADER_BACKTRACK;
	/* Repeat process to move to sibling of parent node if present */
        xmlTextReaderNextTree(reader);
    }

    reader->state = XML_TEXTREADER_END;

    return(1);
}

/**
 * xmlTextReaderReadTree:
 * @reader:  the xmlTextReaderPtr used
 *
 *  Moves the position of the current instance to the next node in
 *  the stream, exposing its properties.
 *
 *  Returns 1 if the node was read successfully, 0 if there is no more
 *          nodes to read, or -1 in case of error
 */
static int
xmlTextReaderReadTree(xmlTextReaderPtr reader) {
    if (reader->state == XML_TEXTREADER_END)
        return(0);

next_node:
    if (reader->node == NULL) {
        if (reader->doc->children == NULL) {
            reader->state = XML_TEXTREADER_END;
            return(0);
        }

        reader->node = reader->doc->children;
        reader->state = XML_TEXTREADER_START;
        goto found_node;
    }

    if ((reader->state != XML_TEXTREADER_BACKTRACK) &&
        (reader->node->type != XML_DTD_NODE) &&
        (reader->node->type != XML_XINCLUDE_START) &&
	(reader->node->type != XML_ENTITY_REF_NODE)) {
        if (reader->node->children != NULL) {
            reader->node = reader->node->children;
            reader->depth++;
            reader->state = XML_TEXTREADER_START;
            goto found_node;
        }

        if (reader->node->type == XML_ATTRIBUTE_NODE) {
            reader->state = XML_TEXTREADER_BACKTRACK;
            goto found_node;
        }
    }

    if (reader->node->next != NULL) {
        reader->node = reader->node->next;
        reader->state = XML_TEXTREADER_START;
        goto found_node;
    }

    if (reader->node->parent != NULL) {
        if ((reader->node->parent->type == XML_DOCUMENT_NODE) ||
	    (reader->node->parent->type == XML_HTML_DOCUMENT_NODE)) {
            reader->state = XML_TEXTREADER_END;
            return(0);
        }

        reader->node = reader->node->parent;
        reader->depth--;
        reader->state = XML_TEXTREADER_BACKTRACK;
        goto found_node;
    }

    reader->state = XML_TEXTREADER_END;

found_node:
    if ((reader->node->type == XML_XINCLUDE_START) ||
        (reader->node->type == XML_XINCLUDE_END))
	goto next_node;

    return(1);
}

/**
 * xmlTextReaderNextSibling:
 * @reader:  the xmlTextReaderPtr used
 *
 * Skip to the node following the current one in document order while
 * avoiding the subtree if any.
 * Currently implemented only for Readers built on a document
 *
 * Returns 1 if the node was read successfully, 0 if there is no more
 *          nodes to read, or -1 in case of error
 */
int
xmlTextReaderNextSibling(xmlTextReaderPtr reader) {
    if (reader == NULL)
        return(-1);
    if (reader->doc == NULL) {
        /* TODO */
	return(-1);
    }

    if (reader->state == XML_TEXTREADER_END)
        return(0);

    if (reader->node == NULL)
        return(xmlTextReaderNextTree(reader));

    if (reader->node->next != NULL) {
        reader->node = reader->node->next;
        reader->state = XML_TEXTREADER_START;
        return(1);
    }

    return(0);
}

/************************************************************************
 *									*
 *			Constructor and destructors			*
 *									*
 ************************************************************************/
/**
 * xmlNewTextReader:
 * @input: the xmlParserInputBufferPtr used to read data
 * @URI: the URI information for the source if available
 *
 * Create an xmlTextReader structure fed with @input
 *
 * Returns the new xmlTextReaderPtr or NULL in case of error
 */
xmlTextReaderPtr
xmlNewTextReader(xmlParserInputBufferPtr input, const char *URI) {
    xmlTextReaderPtr ret;

    if (input == NULL)
	return(NULL);
    ret = xmlMalloc(sizeof(xmlTextReader));
    if (ret == NULL) {
        xmlGenericError(xmlGenericErrorContext,
		"xmlNewTextReader : malloc failed\n");
	return(NULL);
    }
    memset(ret, 0, sizeof(xmlTextReader));
    ret->doc = NULL;
    ret->entTab = NULL;
    ret->entMax = 0;
    ret->entNr = 0;
    ret->input = input;
    ret->buffer = xmlBufferCreateSize(100);
    if (ret->buffer == NULL) {
        xmlFree(ret);
        xmlGenericError(xmlGenericErrorContext,
		"xmlNewTextReader : malloc failed\n");
	return(NULL);
    }
    ret->sax = (xmlSAXHandler *) xmlMalloc(sizeof(xmlSAXHandler));
    if (ret->sax == NULL) {
	xmlBufferFree(ret->buffer);
	xmlFree(ret);
        xmlGenericError(xmlGenericErrorContext,
		"xmlNewTextReader : malloc failed\n");
	return(NULL);
    }
    xmlSAXVersion(ret->sax, 2);
    ret->startElement = ret->sax->startElement;
    ret->sax->startElement = xmlTextReaderStartElement;
    ret->endElement = ret->sax->endElement;
    ret->sax->endElement = xmlTextReaderEndElement;
#ifdef LIBXML_SAX1_ENABLED
    if (ret->sax->initialized == XML_SAX2_MAGIC) {
#endif /* LIBXML_SAX1_ENABLED */
	ret->startElementNs = ret->sax->startElementNs;
	ret->sax->startElementNs = xmlTextReaderStartElementNs;
	ret->endElementNs = ret->sax->endElementNs;
	ret->sax->endElementNs = xmlTextReaderEndElementNs;
#ifdef LIBXML_SAX1_ENABLED
    } else {
	ret->startElementNs = NULL;
	ret->endElementNs = NULL;
    }
#endif /* LIBXML_SAX1_ENABLED */
    ret->characters = ret->sax->characters;
    ret->sax->characters = xmlTextReaderCharacters;
    ret->sax->ignorableWhitespace = xmlTextReaderCharacters;
    ret->cdataBlock = ret->sax->cdataBlock;
    ret->sax->cdataBlock = xmlTextReaderCDataBlock;

    ret->mode = XML_TEXTREADER_MODE_INITIAL;
    ret->node = NULL;
    ret->curnode = NULL;
    if (ret->input->buffer->use < 4) {
	xmlParserInputBufferRead(input, 4);
    }
    if (ret->input->buffer->use >= 4) {
	ret->ctxt = xmlCreatePushParserCtxt(ret->sax, NULL,
			(const char *) ret->input->buffer->content, 4, URI);
	ret->base = 0;
	ret->cur = 4;
    } else {
	ret->ctxt = xmlCreatePushParserCtxt(ret->sax, NULL, NULL, 0, URI);
	ret->base = 0;
	ret->cur = 0;
    }

    if (ret->ctxt == NULL) {
        xmlGenericError(xmlGenericErrorContext,
		"xmlNewTextReader : malloc failed\n");
	xmlBufferFree(ret->buffer);
	xmlFree(ret->sax);
	xmlFree(ret);
	return(NULL);
    }
    ret->ctxt->parseMode = XML_PARSE_READER;
    ret->ctxt->_private = ret;
    ret->ctxt->linenumbers = 1;
    ret->ctxt->dictNames = 1;
    ret->allocs = XML_TEXTREADER_CTXT;
    /*
     * use the parser dictionnary to allocate all elements and attributes names
     */
    ret->ctxt->docdict = 1;
    ret->dict = ret->ctxt->dict;
#ifdef LIBXML_XINCLUDE_ENABLED
    ret->xinclude = 0;
#endif
#ifdef LIBXML_PATTERN_ENABLED
    ret->patternMax = 0;
    ret->patternTab = NULL;
#endif
    return(ret);
}

/**
 * xmlNewTextReaderFilename:
 * @URI: the URI of the resource to process
 *
 * Create an xmlTextReader structure fed with the resource at @URI
 *
 * Returns the new xmlTextReaderPtr or NULL in case of error
 */
xmlTextReaderPtr
xmlNewTextReaderFilename(const char *URI) {
    xmlParserInputBufferPtr input;
    xmlTextReaderPtr ret;
    char *directory = NULL;

    input = xmlParserInputBufferCreateFilename(URI, XML_CHAR_ENCODING_NONE);
    if (input == NULL)
	return(NULL);
    ret = xmlNewTextReader(input, URI);
    if (ret == NULL) {
	xmlFreeParserInputBuffer(input);
	return(NULL);
    }
    ret->allocs |= XML_TEXTREADER_INPUT;
    if (ret->ctxt->directory == NULL)
        directory = xmlParserGetDirectory(URI);
    if ((ret->ctxt->directory == NULL) && (directory != NULL))
        ret->ctxt->directory = (char *) xmlStrdup((xmlChar *) directory);
    if (directory != NULL)
	xmlFree(directory);
    return(ret);
}

/**
 * xmlFreeTextReader:
 * @reader:  the xmlTextReaderPtr
 *
 * Deallocate all the resources associated to the reader
 */
void
xmlFreeTextReader(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return;
#ifdef LIBXML_SCHEMAS_ENABLED
    if (reader->rngSchemas != NULL) {
	xmlRelaxNGFree(reader->rngSchemas);
	reader->rngSchemas = NULL;
    }
    if (reader->rngValidCtxt != NULL) {
	xmlRelaxNGFreeValidCtxt(reader->rngValidCtxt);
	reader->rngValidCtxt = NULL;
    }
    if (reader->xsdPlug != NULL) {
	xmlSchemaSAXUnplug(reader->xsdPlug);
	reader->xsdPlug = NULL;
    }
    if (reader->xsdValidCtxt != NULL) {
	if (! reader->xsdPreserveCtxt)
	    xmlSchemaFreeValidCtxt(reader->xsdValidCtxt);
	reader->xsdValidCtxt = NULL;
    }
    if (reader->xsdSchemas != NULL) {
	xmlSchemaFree(reader->xsdSchemas);
	reader->xsdSchemas = NULL;
    }
#endif
#ifdef LIBXML_XINCLUDE_ENABLED
    if (reader->xincctxt != NULL)
	xmlXIncludeFreeContext(reader->xincctxt);
#endif
#ifdef LIBXML_PATTERN_ENABLED
    if (reader->patternTab != NULL) {
        int i;
	for (i = 0;i < reader->patternNr;i++) {
	    if (reader->patternTab[i] != NULL)
	        xmlFreePattern(reader->patternTab[i]);
	}
	xmlFree(reader->patternTab);
    }
#endif
    if (reader->faketext != NULL) {
	xmlFreeNode(reader->faketext);
    }
    if (reader->ctxt != NULL) {
        if (reader->dict == reader->ctxt->dict)
	    reader->dict = NULL;
	if (reader->ctxt->myDoc != NULL) {
	    if (reader->preserve == 0)
		xmlTextReaderFreeDoc(reader, reader->ctxt->myDoc);
	    reader->ctxt->myDoc = NULL;
	}
	if ((reader->ctxt->vctxt.vstateTab != NULL) &&
	    (reader->ctxt->vctxt.vstateMax > 0)){
	    xmlFree(reader->ctxt->vctxt.vstateTab);
	    reader->ctxt->vctxt.vstateTab = NULL;
	    reader->ctxt->vctxt.vstateMax = 0;
	}
	if (reader->allocs & XML_TEXTREADER_CTXT)
	    xmlFreeParserCtxt(reader->ctxt);
    }
    if (reader->sax != NULL)
	xmlFree(reader->sax);
    if ((reader->input != NULL)  && (reader->allocs & XML_TEXTREADER_INPUT))
	xmlFreeParserInputBuffer(reader->input);
    if (reader->buffer != NULL)
        xmlBufferFree(reader->buffer);
    if (reader->entTab != NULL)
	xmlFree(reader->entTab);
    if (reader->dict != NULL)
        xmlDictFree(reader->dict);
    xmlFree(reader);
}

/************************************************************************
 *									*
 *			Methods for XmlTextReader			*
 *									*
 ************************************************************************/
/**
 * xmlTextReaderClose:
 * @reader:  the xmlTextReaderPtr used
 *
 * This method releases any resources allocated by the current instance
 * changes the state to Closed and close any underlying input.
 *
 * Returns 0 or -1 in case of error
 */
int
xmlTextReaderClose(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(-1);
    reader->node = NULL;
    reader->curnode = NULL;
    reader->mode = XML_TEXTREADER_MODE_CLOSED;
    if (reader->ctxt != NULL) {
	xmlStopParser(reader->ctxt);
	if (reader->ctxt->myDoc != NULL) {
	    if (reader->preserve == 0)
		xmlTextReaderFreeDoc(reader, reader->ctxt->myDoc);
	    reader->ctxt->myDoc = NULL;
	}
    }
    if ((reader->input != NULL)  && (reader->allocs & XML_TEXTREADER_INPUT)) {
	xmlFreeParserInputBuffer(reader->input);
	reader->allocs -= XML_TEXTREADER_INPUT;
    }
    return(0);
}

/**
 * xmlTextReaderGetAttributeNo:
 * @reader:  the xmlTextReaderPtr used
 * @no: the zero-based index of the attribute relative to the containing element
 *
 * Provides the value of the attribute with the specified index relative
 * to the containing element.
 *
 * Returns a string containing the value of the specified attribute, or NULL
 *    in case of error. The string must be deallocated by the caller.
 */
xmlChar *
xmlTextReaderGetAttributeNo(xmlTextReaderPtr reader, int no) {
    xmlChar *ret;
    int i;
    xmlAttrPtr cur;
    xmlNsPtr ns;

    if (reader == NULL)
	return(NULL);
    if (reader->node == NULL)
	return(NULL);
    if (reader->curnode != NULL)
	return(NULL);
    /* TODO: handle the xmlDecl */
    if (reader->node->type != XML_ELEMENT_NODE)
	return(NULL);

    ns = reader->node->nsDef;
    for (i = 0;(i < no) && (ns != NULL);i++) {
	ns = ns->next;
    }
    if (ns != NULL)
	return(xmlStrdup(ns->href));

    cur = reader->node->properties;
    if (cur == NULL)
	return(NULL);
    for (;i < no;i++) {
	cur = cur->next;
	if (cur == NULL)
	    return(NULL);
    }
    /* TODO walk the DTD if present */

    ret = xmlNodeListGetString(reader->node->doc, cur->children, 1);
    if (ret == NULL) return(xmlStrdup((xmlChar *)""));
    return(ret);
}

/**
 * xmlTextReaderGetAttribute:
 * @reader:  the xmlTextReaderPtr used
 * @name: the qualified name of the attribute.
 *
 * Provides the value of the attribute with the specified qualified name.
 *
 * Returns a string containing the value of the specified attribute, or NULL
 *    in case of error. The string must be deallocated by the caller.
 */
xmlChar *
xmlTextReaderGetAttribute(xmlTextReaderPtr reader, const xmlChar *name) {
    xmlChar *prefix = NULL;
    xmlChar *localname;
    xmlNsPtr ns;
    xmlChar *ret = NULL;

    if ((reader == NULL) || (name == NULL))
	return(NULL);
    if (reader->node == NULL)
	return(NULL);
    if (reader->curnode != NULL)
	return(NULL);

    /* TODO: handle the xmlDecl */
    if (reader->node->type != XML_ELEMENT_NODE)
	return(NULL);

    localname = xmlSplitQName2(name, &prefix);
    if (localname == NULL) {
		/*
		 * Namespace default decl
		 */
		if (xmlStrEqual(name, BAD_CAST "xmlns")) {
			ns = reader->node->nsDef;
			while (ns != NULL) {
				if (ns->prefix == NULL) {
					return(xmlStrdup(ns->href));
				}
				ns = ns->next;
			}
			return NULL;
		}
		return(xmlGetNoNsProp(reader->node, name));
	}

    /*
     * Namespace default decl
     */
    if (xmlStrEqual(prefix, BAD_CAST "xmlns")) {
		ns = reader->node->nsDef;
		while (ns != NULL) {
			if ((ns->prefix != NULL) && (xmlStrEqual(ns->prefix, localname))) {
				ret = xmlStrdup(ns->href);
				break;
			}
			ns = ns->next;
		}
    } else {
		ns = xmlSearchNs(reader->node->doc, reader->node, prefix);
		if (ns != NULL)
			ret = xmlGetNsProp(reader->node, localname, ns->href);
	}

    xmlFree(localname);
    if (prefix != NULL)
        xmlFree(prefix);
    return(ret);
}


/**
 * xmlTextReaderGetAttributeNs:
 * @reader:  the xmlTextReaderPtr used
 * @localName: the local name of the attribute.
 * @namespaceURI: the namespace URI of the attribute.
 *
 * Provides the value of the specified attribute
 *
 * Returns a string containing the value of the specified attribute, or NULL
 *    in case of error. The string must be deallocated by the caller.
 */
xmlChar *
xmlTextReaderGetAttributeNs(xmlTextReaderPtr reader, const xmlChar *localName,
			    const xmlChar *namespaceURI) {
    xmlChar *prefix = NULL;
    xmlNsPtr ns;

    if ((reader == NULL) || (localName == NULL))
	return(NULL);
    if (reader->node == NULL)
	return(NULL);
    if (reader->curnode != NULL)
	return(NULL);

    /* TODO: handle the xmlDecl */
    if (reader->node->type != XML_ELEMENT_NODE)
	return(NULL);

    if (xmlStrEqual(namespaceURI, BAD_CAST "http://www.w3.org/2000/xmlns/")) {
		if (! xmlStrEqual(localName, BAD_CAST "xmlns")) {
			prefix = BAD_CAST localName;
		}
		ns = reader->node->nsDef;
		while (ns != NULL) {
			if ((prefix == NULL && ns->prefix == NULL) ||
				((ns->prefix != NULL) && (xmlStrEqual(ns->prefix, localName)))) {
				return xmlStrdup(ns->href);
			}
			ns = ns->next;
		}
		return NULL;
    }

    return(xmlGetNsProp(reader->node, localName, namespaceURI));
}

/**
 * xmlTextReaderGetRemainder:
 * @reader:  the xmlTextReaderPtr used
 *
 * Method to get the remainder of the buffered XML. this method stops the
 * parser, set its state to End Of File and return the input stream with
 * what is left that the parser did not use.
 *
 * The implementation is not good, the parser certainly procgressed past
 * what's left in reader->input, and there is an allocation problem. Best
 * would be to rewrite it differently.
 *
 * Returns the xmlParserInputBufferPtr attached to the XML or NULL
 *    in case of error.
 */
xmlParserInputBufferPtr
xmlTextReaderGetRemainder(xmlTextReaderPtr reader) {
    xmlParserInputBufferPtr ret = NULL;

    if (reader == NULL)
	return(NULL);
    if (reader->node == NULL)
	return(NULL);

    reader->node = NULL;
    reader->curnode = NULL;
    reader->mode = XML_TEXTREADER_MODE_EOF;
    if (reader->ctxt != NULL) {
	xmlStopParser(reader->ctxt);
	if (reader->ctxt->myDoc != NULL) {
	    if (reader->preserve == 0)
		xmlTextReaderFreeDoc(reader, reader->ctxt->myDoc);
	    reader->ctxt->myDoc = NULL;
	}
    }
    if (reader->allocs & XML_TEXTREADER_INPUT) {
	ret = reader->input;
	reader->input = NULL;
	reader->allocs -= XML_TEXTREADER_INPUT;
    } else {
	/*
	 * Hum, one may need to duplicate the data structure because
	 * without reference counting the input may be freed twice:
	 *   - by the layer which allocated it.
	 *   - by the layer to which would have been returned to.
	 */
	TODO
	return(NULL);
    }
    return(ret);
}

/**
 * xmlTextReaderLookupNamespace:
 * @reader:  the xmlTextReaderPtr used
 * @prefix: the prefix whose namespace URI is to be resolved. To return
 *          the default namespace, specify NULL
 *
 * Resolves a namespace prefix in the scope of the current element.
 *
 * Returns a string containing the namespace URI to which the prefix maps
 *    or NULL in case of error. The string must be deallocated by the caller.
 */
xmlChar *
xmlTextReaderLookupNamespace(xmlTextReaderPtr reader, const xmlChar *prefix) {
    xmlNsPtr ns;

    if (reader == NULL)
	return(NULL);
    if (reader->node == NULL)
	return(NULL);

    ns = xmlSearchNs(reader->node->doc, reader->node, prefix);
    if (ns == NULL)
	return(NULL);
    return(xmlStrdup(ns->href));
}

/**
 * xmlTextReaderMoveToAttributeNo:
 * @reader:  the xmlTextReaderPtr used
 * @no: the zero-based index of the attribute relative to the containing
 *      element.
 *
 * Moves the position of the current instance to the attribute with
 * the specified index relative to the containing element.
 *
 * Returns 1 in case of success, -1 in case of error, 0 if not found
 */
int
xmlTextReaderMoveToAttributeNo(xmlTextReaderPtr reader, int no) {
    int i;
    xmlAttrPtr cur;
    xmlNsPtr ns;

    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(-1);
    /* TODO: handle the xmlDecl */
    if (reader->node->type != XML_ELEMENT_NODE)
	return(-1);

    reader->curnode = NULL;

    ns = reader->node->nsDef;
    for (i = 0;(i < no) && (ns != NULL);i++) {
	ns = ns->next;
    }
    if (ns != NULL) {
	reader->curnode = (xmlNodePtr) ns;
	return(1);
    }

    cur = reader->node->properties;
    if (cur == NULL)
	return(0);
    for (;i < no;i++) {
	cur = cur->next;
	if (cur == NULL)
	    return(0);
    }
    /* TODO walk the DTD if present */

    reader->curnode = (xmlNodePtr) cur;
    return(1);
}

/**
 * xmlTextReaderMoveToAttribute:
 * @reader:  the xmlTextReaderPtr used
 * @name: the qualified name of the attribute.
 *
 * Moves the position of the current instance to the attribute with
 * the specified qualified name.
 *
 * Returns 1 in case of success, -1 in case of error, 0 if not found
 */
int
xmlTextReaderMoveToAttribute(xmlTextReaderPtr reader, const xmlChar *name) {
    xmlChar *prefix = NULL;
    xmlChar *localname;
    xmlNsPtr ns;
    xmlAttrPtr prop;

    if ((reader == NULL) || (name == NULL))
	return(-1);
    if (reader->node == NULL)
	return(-1);

    /* TODO: handle the xmlDecl */
    if (reader->node->type != XML_ELEMENT_NODE)
	return(0);

    localname = xmlSplitQName2(name, &prefix);
    if (localname == NULL) {
	/*
	 * Namespace default decl
	 */
	if (xmlStrEqual(name, BAD_CAST "xmlns")) {
	    ns = reader->node->nsDef;
	    while (ns != NULL) {
		if (ns->prefix == NULL) {
		    reader->curnode = (xmlNodePtr) ns;
		    return(1);
		}
		ns = ns->next;
	    }
	    return(0);
	}

	prop = reader->node->properties;
	while (prop != NULL) {
	    /*
	     * One need to have
	     *   - same attribute names
	     *   - and the attribute carrying that namespace
	     */
	    if ((xmlStrEqual(prop->name, name)) &&
		((prop->ns == NULL) || (prop->ns->prefix == NULL))) {
		reader->curnode = (xmlNodePtr) prop;
		return(1);
	    }
	    prop = prop->next;
	}
	return(0);
    }

    /*
     * Namespace default decl
     */
    if (xmlStrEqual(prefix, BAD_CAST "xmlns")) {
	ns = reader->node->nsDef;
	while (ns != NULL) {
	    if ((ns->prefix != NULL) && (xmlStrEqual(ns->prefix, localname))) {
		reader->curnode = (xmlNodePtr) ns;
		goto found;
	    }
	    ns = ns->next;
	}
	goto not_found;
    }
    prop = reader->node->properties;
    while (prop != NULL) {
	/*
	 * One need to have
	 *   - same attribute names
	 *   - and the attribute carrying that namespace
	 */
	if ((xmlStrEqual(prop->name, localname)) &&
	    (prop->ns != NULL) && (xmlStrEqual(prop->ns->prefix, prefix))) {
	    reader->curnode = (xmlNodePtr) prop;
	    goto found;
	}
	prop = prop->next;
    }
not_found:
    if (localname != NULL)
        xmlFree(localname);
    if (prefix != NULL)
        xmlFree(prefix);
    return(0);

found:
    if (localname != NULL)
        xmlFree(localname);
    if (prefix != NULL)
        xmlFree(prefix);
    return(1);
}

/**
 * xmlTextReaderMoveToAttributeNs:
 * @reader:  the xmlTextReaderPtr used
 * @localName:  the local name of the attribute.
 * @namespaceURI:  the namespace URI of the attribute.
 *
 * Moves the position of the current instance to the attribute with the
 * specified local name and namespace URI.
 *
 * Returns 1 in case of success, -1 in case of error, 0 if not found
 */
int
xmlTextReaderMoveToAttributeNs(xmlTextReaderPtr reader,
	const xmlChar *localName, const xmlChar *namespaceURI) {
    xmlAttrPtr prop;
    xmlNodePtr node;
    xmlNsPtr ns;
    xmlChar *prefix = NULL;

    if ((reader == NULL) || (localName == NULL) || (namespaceURI == NULL))
	return(-1);
    if (reader->node == NULL)
	return(-1);
    if (reader->node->type != XML_ELEMENT_NODE)
	return(0);
    node = reader->node;

    if (xmlStrEqual(namespaceURI, BAD_CAST "http://www.w3.org/2000/xmlns/")) {
		if (! xmlStrEqual(localName, BAD_CAST "xmlns")) {
			prefix = BAD_CAST localName;
		}
		ns = reader->node->nsDef;
		while (ns != NULL) {
			if ((prefix == NULL && ns->prefix == NULL) ||
				((ns->prefix != NULL) && (xmlStrEqual(ns->prefix, localName)))) {
				reader->curnode = (xmlNodePtr) ns;
				return(1);
			}
			ns = ns->next;
		}
		return(0);
    }

    prop = node->properties;
    while (prop != NULL) {
	/*
	 * One need to have
	 *   - same attribute names
	 *   - and the attribute carrying that namespace
	 */
        if (xmlStrEqual(prop->name, localName) &&
	    ((prop->ns != NULL) &&
	     (xmlStrEqual(prop->ns->href, namespaceURI)))) {
	    reader->curnode = (xmlNodePtr) prop;
	    return(1);
        }
	prop = prop->next;
    }
    return(0);
}

/**
 * xmlTextReaderMoveToFirstAttribute:
 * @reader:  the xmlTextReaderPtr used
 *
 * Moves the position of the current instance to the first attribute
 * associated with the current node.
 *
 * Returns 1 in case of success, -1 in case of error, 0 if not found
 */
int
xmlTextReaderMoveToFirstAttribute(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(-1);
    if (reader->node->type != XML_ELEMENT_NODE)
	return(0);

    if (reader->node->nsDef != NULL) {
	reader->curnode = (xmlNodePtr) reader->node->nsDef;
	return(1);
    }
    if (reader->node->properties != NULL) {
	reader->curnode = (xmlNodePtr) reader->node->properties;
	return(1);
    }
    return(0);
}

/**
 * xmlTextReaderMoveToNextAttribute:
 * @reader:  the xmlTextReaderPtr used
 *
 * Moves the position of the current instance to the next attribute
 * associated with the current node.
 *
 * Returns 1 in case of success, -1 in case of error, 0 if not found
 */
int
xmlTextReaderMoveToNextAttribute(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(-1);
    if (reader->node->type != XML_ELEMENT_NODE)
	return(0);
    if (reader->curnode == NULL)
	return(xmlTextReaderMoveToFirstAttribute(reader));

    if (reader->curnode->type == XML_NAMESPACE_DECL) {
	xmlNsPtr ns = (xmlNsPtr) reader->curnode;
	if (ns->next != NULL) {
	    reader->curnode = (xmlNodePtr) ns->next;
	    return(1);
	}
	if (reader->node->properties != NULL) {
	    reader->curnode = (xmlNodePtr) reader->node->properties;
	    return(1);
	}
	return(0);
    } else if ((reader->curnode->type == XML_ATTRIBUTE_NODE) &&
	       (reader->curnode->next != NULL)) {
	reader->curnode = reader->curnode->next;
	return(1);
    }
    return(0);
}

/**
 * xmlTextReaderMoveToElement:
 * @reader:  the xmlTextReaderPtr used
 *
 * Moves the position of the current instance to the node that
 * contains the current Attribute  node.
 *
 * Returns 1 in case of success, -1 in case of error, 0 if not moved
 */
int
xmlTextReaderMoveToElement(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(-1);
    if (reader->node->type != XML_ELEMENT_NODE)
	return(0);
    if (reader->curnode != NULL) {
	reader->curnode = NULL;
	return(1);
    }
    return(0);
}

/**
 * xmlTextReaderReadAttributeValue:
 * @reader:  the xmlTextReaderPtr used
 *
 * Parses an attribute value into one or more Text and EntityReference nodes.
 *
 * Returns 1 in case of success, 0 if the reader was not positionned on an
 *         ttribute node or all the attribute values have been read, or -1
 *         in case of error.
 */
int
xmlTextReaderReadAttributeValue(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(-1);
    if (reader->curnode == NULL)
	return(0);
    if (reader->curnode->type == XML_ATTRIBUTE_NODE) {
	if (reader->curnode->children == NULL)
	    return(0);
	reader->curnode = reader->curnode->children;
    } else if (reader->curnode->type == XML_NAMESPACE_DECL) {
	xmlNsPtr ns = (xmlNsPtr) reader->curnode;

	if (reader->faketext == NULL) {
	    reader->faketext = xmlNewDocText(reader->node->doc,
		                             ns->href);
	} else {
            if ((reader->faketext->content != NULL) &&
	        (reader->faketext->content !=
		 (xmlChar *) &(reader->faketext->properties)))
		xmlFree(reader->faketext->content);
	    reader->faketext->content = xmlStrdup(ns->href);
	}
	reader->curnode = reader->faketext;
    } else {
	if (reader->curnode->next == NULL)
	    return(0);
	reader->curnode = reader->curnode->next;
    }
    return(1);
}

/**
 * xmlTextReaderConstEncoding:
 * @reader:  the xmlTextReaderPtr used
 *
 * Determine the encoding of the document being read.
 *
 * Returns a string containing the encoding of the document or NULL in
 * case of error.  The string is deallocated with the reader.
 */
const xmlChar *
xmlTextReaderConstEncoding(xmlTextReaderPtr reader) {
    xmlDocPtr doc = NULL;
    if (reader == NULL)
	return(NULL);
    if (reader->doc != NULL)
        doc = reader->doc;
    else if (reader->ctxt != NULL)
	doc = reader->ctxt->myDoc;
    if (doc == NULL)
	return(NULL);

    if (doc->encoding == NULL)
	return(NULL);
    else
      return(CONSTSTR(doc->encoding));
}


/************************************************************************
 *									*
 *			Acces API to the current node			*
 *									*
 ************************************************************************/
/**
 * xmlTextReaderAttributeCount:
 * @reader:  the xmlTextReaderPtr used
 *
 * Provides the number of attributes of the current node
 *
 * Returns 0 i no attributes, -1 in case of error or the attribute count
 */
int
xmlTextReaderAttributeCount(xmlTextReaderPtr reader) {
    int ret;
    xmlAttrPtr attr;
    xmlNsPtr ns;
    xmlNodePtr node;

    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(0);

    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;

    if (node->type != XML_ELEMENT_NODE)
	return(0);
    if ((reader->state == XML_TEXTREADER_END) ||
	(reader->state == XML_TEXTREADER_BACKTRACK))
	return(0);
    ret = 0;
    attr = node->properties;
    while (attr != NULL) {
	ret++;
	attr = attr->next;
    }
    ns = node->nsDef;
    while (ns != NULL) {
	ret++;
	ns = ns->next;
    }
    return(ret);
}

/**
 * xmlTextReaderNodeType:
 * @reader:  the xmlTextReaderPtr used
 *
 * Get the node type of the current node
 * Reference:
 * http://www.gnu.org/software/dotgnu/pnetlib-doc/System/Xml/XmlNodeType.html
 *
 * Returns the xmlNodeType of the current node or -1 in case of error
 */
int
xmlTextReaderNodeType(xmlTextReaderPtr reader) {
    xmlNodePtr node;

    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(XML_READER_TYPE_NONE);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;
    switch (node->type) {
        case XML_ELEMENT_NODE:
	    if ((reader->state == XML_TEXTREADER_END) ||
		(reader->state == XML_TEXTREADER_BACKTRACK))
		return(XML_READER_TYPE_END_ELEMENT);
	    return(XML_READER_TYPE_ELEMENT);
        case XML_NAMESPACE_DECL:
        case XML_ATTRIBUTE_NODE:
	    return(XML_READER_TYPE_ATTRIBUTE);
        case XML_TEXT_NODE:
	    if (xmlIsBlankNode(reader->node)) {
		if (xmlNodeGetSpacePreserve(reader->node))
		    return(XML_READER_TYPE_SIGNIFICANT_WHITESPACE);
		else
		    return(XML_READER_TYPE_WHITESPACE);
	    } else {
		return(XML_READER_TYPE_TEXT);
	    }
        case XML_CDATA_SECTION_NODE:
	    return(XML_READER_TYPE_CDATA);
        case XML_ENTITY_REF_NODE:
	    return(XML_READER_TYPE_ENTITY_REFERENCE);
        case XML_ENTITY_NODE:
	    return(XML_READER_TYPE_ENTITY);
        case XML_PI_NODE:
	    return(XML_READER_TYPE_PROCESSING_INSTRUCTION);
        case XML_COMMENT_NODE:
	    return(XML_READER_TYPE_COMMENT);
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
        case XML_DOCB_DOCUMENT_NODE:
#endif
	    return(XML_READER_TYPE_DOCUMENT);
        case XML_DOCUMENT_FRAG_NODE:
	    return(XML_READER_TYPE_DOCUMENT_FRAGMENT);
        case XML_NOTATION_NODE:
	    return(XML_READER_TYPE_NOTATION);
        case XML_DOCUMENT_TYPE_NODE:
        case XML_DTD_NODE:
	    return(XML_READER_TYPE_DOCUMENT_TYPE);

        case XML_ELEMENT_DECL:
        case XML_ATTRIBUTE_DECL:
        case XML_ENTITY_DECL:
        case XML_XINCLUDE_START:
        case XML_XINCLUDE_END:
	    return(XML_READER_TYPE_NONE);
    }
    return(-1);
}

/**
 * xmlTextReaderIsEmptyElement:
 * @reader:  the xmlTextReaderPtr used
 *
 * Check if the current node is empty
 *
 * Returns 1 if empty, 0 if not and -1 in case of error
 */
int
xmlTextReaderIsEmptyElement(xmlTextReaderPtr reader) {
    if ((reader == NULL) || (reader->node == NULL))
	return(-1);
    if (reader->node->type != XML_ELEMENT_NODE)
	return(0);
    if (reader->curnode != NULL)
	return(0);
    if (reader->node->children != NULL)
	return(0);
    if (reader->state == XML_TEXTREADER_END)
	return(0);
    if (reader->doc != NULL)
        return(1);
#ifdef LIBXML_XINCLUDE_ENABLED
    if (reader->in_xinclude > 0)
        return(1);
#endif
    return((reader->node->extra & NODE_IS_EMPTY) != 0);
}

/**
 * xmlTextReaderLocalName:
 * @reader:  the xmlTextReaderPtr used
 *
 * The local name of the node.
 *
 * Returns the local name or NULL if not available,
 *   if non NULL it need to be freed by the caller.
 */
xmlChar *
xmlTextReaderLocalName(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if ((reader == NULL) || (reader->node == NULL))
	return(NULL);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;
    if (node->type == XML_NAMESPACE_DECL) {
	xmlNsPtr ns = (xmlNsPtr) node;
	if (ns->prefix == NULL)
	    return(xmlStrdup(BAD_CAST "xmlns"));
	else
	    return(xmlStrdup(ns->prefix));
    }
    if ((node->type != XML_ELEMENT_NODE) &&
	(node->type != XML_ATTRIBUTE_NODE))
	return(xmlTextReaderName(reader));
    return(xmlStrdup(node->name));
}

/**
 * xmlTextReaderConstLocalName:
 * @reader:  the xmlTextReaderPtr used
 *
 * The local name of the node.
 *
 * Returns the local name or NULL if not available, the
 *         string will be deallocated with the reader.
 */
const xmlChar *
xmlTextReaderConstLocalName(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if ((reader == NULL) || (reader->node == NULL))
	return(NULL);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;
    if (node->type == XML_NAMESPACE_DECL) {
	xmlNsPtr ns = (xmlNsPtr) node;
	if (ns->prefix == NULL)
	    return(CONSTSTR(BAD_CAST "xmlns"));
	else
	    return(ns->prefix);
    }
    if ((node->type != XML_ELEMENT_NODE) &&
	(node->type != XML_ATTRIBUTE_NODE))
	return(xmlTextReaderConstName(reader));
    return(node->name);
}

/**
 * xmlTextReaderName:
 * @reader:  the xmlTextReaderPtr used
 *
 * The qualified name of the node, equal to Prefix :LocalName.
 *
 * Returns the local name or NULL if not available,
 *   if non NULL it need to be freed by the caller.
 */
xmlChar *
xmlTextReaderName(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    xmlChar *ret;

    if ((reader == NULL) || (reader->node == NULL))
	return(NULL);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;
    switch (node->type) {
        case XML_ELEMENT_NODE:
        case XML_ATTRIBUTE_NODE:
	    if ((node->ns == NULL) ||
		(node->ns->prefix == NULL))
		return(xmlStrdup(node->name));

	    ret = xmlStrdup(node->ns->prefix);
	    ret = xmlStrcat(ret, BAD_CAST ":");
	    ret = xmlStrcat(ret, node->name);
	    return(ret);
        case XML_TEXT_NODE:
	    return(xmlStrdup(BAD_CAST "#text"));
        case XML_CDATA_SECTION_NODE:
	    return(xmlStrdup(BAD_CAST "#cdata-section"));
        case XML_ENTITY_NODE:
        case XML_ENTITY_REF_NODE:
	    return(xmlStrdup(node->name));
        case XML_PI_NODE:
	    return(xmlStrdup(node->name));
        case XML_COMMENT_NODE:
	    return(xmlStrdup(BAD_CAST "#comment"));
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
        case XML_DOCB_DOCUMENT_NODE:
#endif
	    return(xmlStrdup(BAD_CAST "#document"));
        case XML_DOCUMENT_FRAG_NODE:
	    return(xmlStrdup(BAD_CAST "#document-fragment"));
        case XML_NOTATION_NODE:
	    return(xmlStrdup(node->name));
        case XML_DOCUMENT_TYPE_NODE:
        case XML_DTD_NODE:
	    return(xmlStrdup(node->name));
        case XML_NAMESPACE_DECL: {
	    xmlNsPtr ns = (xmlNsPtr) node;

	    ret = xmlStrdup(BAD_CAST "xmlns");
	    if (ns->prefix == NULL)
		return(ret);
	    ret = xmlStrcat(ret, BAD_CAST ":");
	    ret = xmlStrcat(ret, ns->prefix);
	    return(ret);
	}

        case XML_ELEMENT_DECL:
        case XML_ATTRIBUTE_DECL:
        case XML_ENTITY_DECL:
        case XML_XINCLUDE_START:
        case XML_XINCLUDE_END:
	    return(NULL);
    }
    return(NULL);
}

/**
 * xmlTextReaderConstName:
 * @reader:  the xmlTextReaderPtr used
 *
 * The qualified name of the node, equal to Prefix :LocalName.
 *
 * Returns the local name or NULL if not available, the string is
 *         deallocated with the reader.
 */
const xmlChar *
xmlTextReaderConstName(xmlTextReaderPtr reader) {
    xmlNodePtr node;

    if ((reader == NULL) || (reader->node == NULL))
	return(NULL);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;
    switch (node->type) {
        case XML_ELEMENT_NODE:
        case XML_ATTRIBUTE_NODE:
	    if ((node->ns == NULL) ||
		(node->ns->prefix == NULL))
		return(node->name);
	    return(CONSTQSTR(node->ns->prefix, node->name));
        case XML_TEXT_NODE:
	    return(CONSTSTR(BAD_CAST "#text"));
        case XML_CDATA_SECTION_NODE:
	    return(CONSTSTR(BAD_CAST "#cdata-section"));
        case XML_ENTITY_NODE:
        case XML_ENTITY_REF_NODE:
	    return(CONSTSTR(node->name));
        case XML_PI_NODE:
	    return(CONSTSTR(node->name));
        case XML_COMMENT_NODE:
	    return(CONSTSTR(BAD_CAST "#comment"));
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
        case XML_DOCB_DOCUMENT_NODE:
#endif
	    return(CONSTSTR(BAD_CAST "#document"));
        case XML_DOCUMENT_FRAG_NODE:
	    return(CONSTSTR(BAD_CAST "#document-fragment"));
        case XML_NOTATION_NODE:
	    return(CONSTSTR(node->name));
        case XML_DOCUMENT_TYPE_NODE:
        case XML_DTD_NODE:
	    return(CONSTSTR(node->name));
        case XML_NAMESPACE_DECL: {
	    xmlNsPtr ns = (xmlNsPtr) node;

	    if (ns->prefix == NULL)
		return(CONSTSTR(BAD_CAST "xmlns"));
	    return(CONSTQSTR(BAD_CAST "xmlns", ns->prefix));
	}

        case XML_ELEMENT_DECL:
        case XML_ATTRIBUTE_DECL:
        case XML_ENTITY_DECL:
        case XML_XINCLUDE_START:
        case XML_XINCLUDE_END:
	    return(NULL);
    }
    return(NULL);
}

/**
 * xmlTextReaderPrefix:
 * @reader:  the xmlTextReaderPtr used
 *
 * A shorthand reference to the namespace associated with the node.
 *
 * Returns the prefix or NULL if not available,
 *    if non NULL it need to be freed by the caller.
 */
xmlChar *
xmlTextReaderPrefix(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if ((reader == NULL) || (reader->node == NULL))
	return(NULL);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;
    if (node->type == XML_NAMESPACE_DECL) {
	xmlNsPtr ns = (xmlNsPtr) node;
	if (ns->prefix == NULL)
	    return(NULL);
	return(xmlStrdup(BAD_CAST "xmlns"));
    }
    if ((node->type != XML_ELEMENT_NODE) &&
	(node->type != XML_ATTRIBUTE_NODE))
	return(NULL);
    if ((node->ns != NULL) && (node->ns->prefix != NULL))
	return(xmlStrdup(node->ns->prefix));
    return(NULL);
}

/**
 * xmlTextReaderConstPrefix:
 * @reader:  the xmlTextReaderPtr used
 *
 * A shorthand reference to the namespace associated with the node.
 *
 * Returns the prefix or NULL if not available, the string is deallocated
 *         with the reader.
 */
const xmlChar *
xmlTextReaderConstPrefix(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if ((reader == NULL) || (reader->node == NULL))
	return(NULL);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;
    if (node->type == XML_NAMESPACE_DECL) {
	xmlNsPtr ns = (xmlNsPtr) node;
	if (ns->prefix == NULL)
	    return(NULL);
	return(CONSTSTR(BAD_CAST "xmlns"));
    }
    if ((node->type != XML_ELEMENT_NODE) &&
	(node->type != XML_ATTRIBUTE_NODE))
	return(NULL);
    if ((node->ns != NULL) && (node->ns->prefix != NULL))
	return(CONSTSTR(node->ns->prefix));
    return(NULL);
}

/**
 * xmlTextReaderNamespaceUri:
 * @reader:  the xmlTextReaderPtr used
 *
 * The URI defining the namespace associated with the node.
 *
 * Returns the namespace URI or NULL if not available,
 *    if non NULL it need to be freed by the caller.
 */
xmlChar *
xmlTextReaderNamespaceUri(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if ((reader == NULL) || (reader->node == NULL))
	return(NULL);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;
    if (node->type == XML_NAMESPACE_DECL)
	return(xmlStrdup(BAD_CAST "http://www.w3.org/2000/xmlns/"));
    if ((node->type != XML_ELEMENT_NODE) &&
	(node->type != XML_ATTRIBUTE_NODE))
	return(NULL);
    if (node->ns != NULL)
	return(xmlStrdup(node->ns->href));
    return(NULL);
}

/**
 * xmlTextReaderConstNamespaceUri:
 * @reader:  the xmlTextReaderPtr used
 *
 * The URI defining the namespace associated with the node.
 *
 * Returns the namespace URI or NULL if not available, the string
 *         will be deallocated with the reader
 */
const xmlChar *
xmlTextReaderConstNamespaceUri(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if ((reader == NULL) || (reader->node == NULL))
	return(NULL);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;
    if (node->type == XML_NAMESPACE_DECL)
	return(CONSTSTR(BAD_CAST "http://www.w3.org/2000/xmlns/"));
    if ((node->type != XML_ELEMENT_NODE) &&
	(node->type != XML_ATTRIBUTE_NODE))
	return(NULL);
    if (node->ns != NULL)
	return(CONSTSTR(node->ns->href));
    return(NULL);
}

/**
 * xmlTextReaderBaseUri:
 * @reader:  the xmlTextReaderPtr used
 *
 * The base URI of the node.
 *
 * Returns the base URI or NULL if not available,
 *    if non NULL it need to be freed by the caller.
 */
xmlChar *
xmlTextReaderBaseUri(xmlTextReaderPtr reader) {
    if ((reader == NULL) || (reader->node == NULL))
	return(NULL);
    return(xmlNodeGetBase(NULL, reader->node));
}

/**
 * xmlTextReaderConstBaseUri:
 * @reader:  the xmlTextReaderPtr used
 *
 * The base URI of the node.
 *
 * Returns the base URI or NULL if not available, the string
 *         will be deallocated with the reader
 */
const xmlChar *
xmlTextReaderConstBaseUri(xmlTextReaderPtr reader) {
    xmlChar *tmp;
    const xmlChar *ret;

    if ((reader == NULL) || (reader->node == NULL))
	return(NULL);
    tmp = xmlNodeGetBase(NULL, reader->node);
    if (tmp == NULL)
        return(NULL);
    ret = CONSTSTR(tmp);
    xmlFree(tmp);
    return(ret);
}

/**
 * xmlTextReaderDepth:
 * @reader:  the xmlTextReaderPtr used
 *
 * The depth of the node in the tree.
 *
 * Returns the depth or -1 in case of error
 */
int
xmlTextReaderDepth(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(0);

    if (reader->curnode != NULL) {
	if ((reader->curnode->type == XML_ATTRIBUTE_NODE) ||
	    (reader->curnode->type == XML_NAMESPACE_DECL))
	    return(reader->depth + 1);
	return(reader->depth + 2);
    }
    return(reader->depth);
}

/**
 * xmlTextReaderHasAttributes:
 * @reader:  the xmlTextReaderPtr used
 *
 * Whether the node has attributes.
 *
 * Returns 1 if true, 0 if false, and -1 in case or error
 */
int
xmlTextReaderHasAttributes(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(0);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;

    if ((node->type == XML_ELEMENT_NODE) &&
	((node->properties != NULL) || (node->nsDef != NULL)))
	return(1);
    /* TODO: handle the xmlDecl */
    return(0);
}

/**
 * xmlTextReaderHasValue:
 * @reader:  the xmlTextReaderPtr used
 *
 * Whether the node can have a text value.
 *
 * Returns 1 if true, 0 if false, and -1 in case or error
 */
int
xmlTextReaderHasValue(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(0);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;

    switch (node->type) {
        case XML_ATTRIBUTE_NODE:
        case XML_TEXT_NODE:
        case XML_CDATA_SECTION_NODE:
        case XML_PI_NODE:
        case XML_COMMENT_NODE:
        case XML_NAMESPACE_DECL:
	    return(1);
	default:
	    break;
    }
    return(0);
}

/**
 * xmlTextReaderValue:
 * @reader:  the xmlTextReaderPtr used
 *
 * Provides the text value of the node if present
 *
 * Returns the string or NULL if not available. The result must be deallocated
 *     with xmlFree()
 */
xmlChar *
xmlTextReaderValue(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if (reader == NULL)
	return(NULL);
    if (reader->node == NULL)
	return(NULL);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;

    switch (node->type) {
        case XML_NAMESPACE_DECL:
	    return(xmlStrdup(((xmlNsPtr) node)->href));
        case XML_ATTRIBUTE_NODE:{
	    xmlAttrPtr attr = (xmlAttrPtr) node;

	    if (attr->parent != NULL)
		return (xmlNodeListGetString
			(attr->parent->doc, attr->children, 1));
	    else
		return (xmlNodeListGetString(NULL, attr->children, 1));
	    break;
	}
        case XML_TEXT_NODE:
        case XML_CDATA_SECTION_NODE:
        case XML_PI_NODE:
        case XML_COMMENT_NODE:
            if (node->content != NULL)
                return (xmlStrdup(node->content));
	default:
	    break;
    }
    return(NULL);
}

/**
 * xmlTextReaderConstValue:
 * @reader:  the xmlTextReaderPtr used
 *
 * Provides the text value of the node if present
 *
 * Returns the string or NULL if not available. The result will be
 *     deallocated on the next Read() operation.
 */
const xmlChar *
xmlTextReaderConstValue(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if (reader == NULL)
	return(NULL);
    if (reader->node == NULL)
	return(NULL);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;

    switch (node->type) {
        case XML_NAMESPACE_DECL:
	    return(((xmlNsPtr) node)->href);
        case XML_ATTRIBUTE_NODE:{
	    xmlAttrPtr attr = (xmlAttrPtr) node;

	    if ((attr->children != NULL) &&
	        (attr->children->type == XML_TEXT_NODE) &&
		(attr->children->next == NULL))
		return(attr->children->content);
	    else {
		if (reader->buffer == NULL)
		    reader->buffer = xmlBufferCreateSize(100);
		if (reader->buffer == NULL) {
		    xmlGenericError(xmlGenericErrorContext,
				    "xmlTextReaderSetup : malloc failed\n");
		    return (NULL);
		}
	        reader->buffer->use = 0;
	        xmlNodeBufGetContent(reader->buffer, node);
		return(reader->buffer->content);
	    }
	    break;
	}
        case XML_TEXT_NODE:
        case XML_CDATA_SECTION_NODE:
        case XML_PI_NODE:
        case XML_COMMENT_NODE:
	    return(node->content);
	default:
	    break;
    }
    return(NULL);
}

/**
 * xmlTextReaderIsDefault:
 * @reader:  the xmlTextReaderPtr used
 *
 * Whether an Attribute  node was generated from the default value
 * defined in the DTD or schema.
 *
 * Returns 0 if not defaulted, 1 if defaulted, and -1 in case of error
 */
int
xmlTextReaderIsDefault(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(-1);
    return(0);
}

/**
 * xmlTextReaderQuoteChar:
 * @reader:  the xmlTextReaderPtr used
 *
 * The quotation mark character used to enclose the value of an attribute.
 *
 * Returns " or ' and -1 in case of error
 */
int
xmlTextReaderQuoteChar(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(-1);
    /* TODO maybe lookup the attribute value for " first */
    return((int) '"');
}

/**
 * xmlTextReaderXmlLang:
 * @reader:  the xmlTextReaderPtr used
 *
 * The xml:lang scope within which the node resides.
 *
 * Returns the xml:lang value or NULL if none exists.,
 *    if non NULL it need to be freed by the caller.
 */
xmlChar *
xmlTextReaderXmlLang(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(NULL);
    if (reader->node == NULL)
	return(NULL);
    return(xmlNodeGetLang(reader->node));
}

/**
 * xmlTextReaderConstXmlLang:
 * @reader:  the xmlTextReaderPtr used
 *
 * The xml:lang scope within which the node resides.
 *
 * Returns the xml:lang value or NULL if none exists.
 */
const xmlChar *
xmlTextReaderConstXmlLang(xmlTextReaderPtr reader) {
    xmlChar *tmp;
    const xmlChar *ret;

    if (reader == NULL)
	return(NULL);
    if (reader->node == NULL)
	return(NULL);
    tmp = xmlNodeGetLang(reader->node);
    if (tmp == NULL)
        return(NULL);
    ret = CONSTSTR(tmp);
    xmlFree(tmp);
    return(ret);
}

/**
 * xmlTextReaderConstString:
 * @reader:  the xmlTextReaderPtr used
 * @str:  the string to intern.
 *
 * Get an interned string from the reader, allows for example to
 * speedup string name comparisons
 *
 * Returns an interned copy of the string or NULL in case of error. The
 *         string will be deallocated with the reader.
 */
const xmlChar *
xmlTextReaderConstString(xmlTextReaderPtr reader, const xmlChar *str) {
    if (reader == NULL)
	return(NULL);
    return(CONSTSTR(str));
}

/**
 * xmlTextReaderNormalization:
 * @reader:  the xmlTextReaderPtr used
 *
 * The value indicating whether to normalize white space and attribute values.
 * Since attribute value and end of line normalizations are a MUST in the XML
 * specification only the value true is accepted. The broken bahaviour of
 * accepting out of range character entities like &#0; is of course not
 * supported either.
 *
 * Returns 1 or -1 in case of error.
 */
int
xmlTextReaderNormalization(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(-1);
    return(1);
}

/************************************************************************
 *									*
 *			Extensions to the base APIs			*
 *									*
 ************************************************************************/

/**
 * xmlTextReaderSetParserProp:
 * @reader:  the xmlTextReaderPtr used
 * @prop:  the xmlParserProperties to set
 * @value:  usually 0 or 1 to (de)activate it
 *
 * Change the parser processing behaviour by changing some of its internal
 * properties. Note that some properties can only be changed before any
 * read has been done.
 *
 * Returns 0 if the call was successful, or -1 in case of error
 */
int
xmlTextReaderSetParserProp(xmlTextReaderPtr reader, int prop, int value) {
    xmlParserProperties p = (xmlParserProperties) prop;
    xmlParserCtxtPtr ctxt;

    if ((reader == NULL) || (reader->ctxt == NULL))
	return(-1);
    ctxt = reader->ctxt;

    switch (p) {
        case XML_PARSER_LOADDTD:
	    if (value != 0) {
		if (ctxt->loadsubset == 0) {
		    if (reader->mode != XML_TEXTREADER_MODE_INITIAL)
			return(-1);
		    ctxt->loadsubset = XML_DETECT_IDS;
		}
	    } else {
		ctxt->loadsubset = 0;
	    }
	    return(0);
        case XML_PARSER_DEFAULTATTRS:
	    if (value != 0) {
		ctxt->loadsubset |= XML_COMPLETE_ATTRS;
	    } else {
		if (ctxt->loadsubset & XML_COMPLETE_ATTRS)
		    ctxt->loadsubset -= XML_COMPLETE_ATTRS;
	    }
	    return(0);
        case XML_PARSER_VALIDATE:
	    if (value != 0) {
		ctxt->validate = 1;
		reader->validate = XML_TEXTREADER_VALIDATE_DTD;
	    } else {
		ctxt->validate = 0;
	    }
	    return(0);
        case XML_PARSER_SUBST_ENTITIES:
	    if (value != 0) {
		ctxt->replaceEntities = 1;
	    } else {
		ctxt->replaceEntities = 0;
	    }
	    return(0);
    }
    return(-1);
}

/**
 * xmlTextReaderGetParserProp:
 * @reader:  the xmlTextReaderPtr used
 * @prop:  the xmlParserProperties to get
 *
 * Read the parser internal property.
 *
 * Returns the value, usually 0 or 1, or -1 in case of error.
 */
int
xmlTextReaderGetParserProp(xmlTextReaderPtr reader, int prop) {
    xmlParserProperties p = (xmlParserProperties) prop;
    xmlParserCtxtPtr ctxt;

    if ((reader == NULL) || (reader->ctxt == NULL))
	return(-1);
    ctxt = reader->ctxt;

    switch (p) {
        case XML_PARSER_LOADDTD:
	    if ((ctxt->loadsubset != 0) || (ctxt->validate != 0))
		return(1);
	    return(0);
        case XML_PARSER_DEFAULTATTRS:
	    if (ctxt->loadsubset & XML_COMPLETE_ATTRS)
		return(1);
	    return(0);
        case XML_PARSER_VALIDATE:
	    return(reader->validate);
	case XML_PARSER_SUBST_ENTITIES:
	    return(ctxt->replaceEntities);
    }
    return(-1);
}


/**
 * xmlTextReaderGetParserLineNumber:
 * @reader: the user data (XML reader context)
 *
 * Provide the line number of the current parsing point.
 *
 * Returns an int or 0 if not available
 */
int
xmlTextReaderGetParserLineNumber(xmlTextReaderPtr reader)
{
    if ((reader == NULL) || (reader->ctxt == NULL) ||
        (reader->ctxt->input == NULL)) {
        return (0);
    }
    return (reader->ctxt->input->line);
}

/**
 * xmlTextReaderGetParserColumnNumber:
 * @reader: the user data (XML reader context)
 *
 * Provide the column number of the current parsing point.
 *
 * Returns an int or 0 if not available
 */
int
xmlTextReaderGetParserColumnNumber(xmlTextReaderPtr reader)
{
    if ((reader == NULL) || (reader->ctxt == NULL) ||
        (reader->ctxt->input == NULL)) {
        return (0);
    }
    return (reader->ctxt->input->col);
}

/**
 * xmlTextReaderCurrentNode:
 * @reader:  the xmlTextReaderPtr used
 *
 * Hacking interface allowing to get the xmlNodePtr correponding to the
 * current node being accessed by the xmlTextReader. This is dangerous
 * because the underlying node may be destroyed on the next Reads.
 *
 * Returns the xmlNodePtr or NULL in case of error.
 */
xmlNodePtr
xmlTextReaderCurrentNode(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(NULL);

    if (reader->curnode != NULL)
	return(reader->curnode);
    return(reader->node);
}

/**
 * xmlTextReaderPreserve:
 * @reader:  the xmlTextReaderPtr used
 *
 * This tells the XML Reader to preserve the current node.
 * The caller must also use xmlTextReaderCurrentDoc() to
 * keep an handle on the resulting document once parsing has finished
 *
 * Returns the xmlNodePtr or NULL in case of error.
 */
xmlNodePtr
xmlTextReaderPreserve(xmlTextReaderPtr reader) {
    xmlNodePtr cur, parent;

    if (reader == NULL)
	return(NULL);

    if (reader->curnode != NULL)
        cur = reader->curnode;
    else
        cur = reader->node;
    if (cur == NULL)
        return(NULL);

    if ((cur->type != XML_DOCUMENT_NODE) && (cur->type != XML_DTD_NODE)) {
	cur->extra |= NODE_IS_PRESERVED;
	cur->extra |= NODE_IS_SPRESERVED;
    }
    reader->preserves++;

    parent = cur->parent;;
    while (parent != NULL) {
        if (parent->type == XML_ELEMENT_NODE)
	    parent->extra |= NODE_IS_PRESERVED;
	parent = parent->parent;
    }
    return(cur);
}

#ifdef LIBXML_PATTERN_ENABLED
/**
 * xmlTextReaderPreservePattern:
 * @reader:  the xmlTextReaderPtr used
 * @pattern:  an XPath subset pattern
 * @namespaces: the prefix definitions, array of [URI, prefix] or NULL
 *
 * This tells the XML Reader to preserve all nodes matched by the
 * pattern. The caller must also use xmlTextReaderCurrentDoc() to
 * keep an handle on the resulting document once parsing has finished
 *
 * Returns a positive number in case of success and -1 in case of error
 */
int
xmlTextReaderPreservePattern(xmlTextReaderPtr reader, const xmlChar *pattern,
                             const xmlChar **namespaces)
{
    xmlPatternPtr comp;

    if ((reader == NULL) || (pattern == NULL))
	return(-1);

    comp = xmlPatterncompile(pattern, reader->dict, 0, namespaces);
    if (comp == NULL)
        return(-1);

    if (reader->patternMax <= 0) {
	reader->patternMax = 4;
	reader->patternTab = (xmlPatternPtr *) xmlMalloc(reader->patternMax *
					      sizeof(reader->patternTab[0]));
        if (reader->patternTab == NULL) {
            xmlGenericError(xmlGenericErrorContext, "xmlMalloc failed !\n");
            return (-1);
        }
    }
    if (reader->patternNr >= reader->patternMax) {
        xmlPatternPtr *tmp;
        reader->patternMax *= 2;
	tmp = (xmlPatternPtr *) xmlRealloc(reader->patternTab,
                                      reader->patternMax *
                                      sizeof(reader->patternTab[0]));
        if (tmp == NULL) {
            xmlGenericError(xmlGenericErrorContext, "xmlRealloc failed !\n");
	    reader->patternMax /= 2;
            return (-1);
        }
	reader->patternTab = tmp;
    }
    reader->patternTab[reader->patternNr] = comp;
    return(reader->patternNr++);
}
#endif

/**
 * xmlTextReaderCurrentDoc:
 * @reader:  the xmlTextReaderPtr used
 *
 * Hacking interface allowing to get the xmlDocPtr correponding to the
 * current document being accessed by the xmlTextReader.
 * NOTE: as a result of this call, the reader will not destroy the
 *       associated XML document and calling xmlFreeDoc() on the result
 *       is needed once the reader parsing has finished.
 *
 * Returns the xmlDocPtr or NULL in case of error.
 */
xmlDocPtr
xmlTextReaderCurrentDoc(xmlTextReaderPtr reader) {
    if (reader == NULL)
	return(NULL);
    if (reader->doc != NULL)
        return(reader->doc);
    if ((reader->ctxt == NULL) || (reader->ctxt->myDoc == NULL))
	return(NULL);

    reader->preserve = 1;
    return(reader->ctxt->myDoc);
}

#ifdef LIBXML_SCHEMAS_ENABLED
static char *xmlTextReaderBuildMessage(const char *msg, va_list ap);

static void XMLCDECL
xmlTextReaderValidityError(void *ctxt, const char *msg, ...);

static void XMLCDECL
xmlTextReaderValidityWarning(void *ctxt, const char *msg, ...);

static void XMLCDECL
xmlTextReaderValidityErrorRelay(void *ctx, const char *msg, ...)
{
    xmlTextReaderPtr reader = (xmlTextReaderPtr) ctx;

    char *str;

    va_list ap;

    va_start(ap, msg);
    str = xmlTextReaderBuildMessage(msg, ap);
    if (!reader->errorFunc) {
        xmlTextReaderValidityError(ctx, "%s", str);
    } else {
        reader->errorFunc(reader->errorFuncArg, str,
                          XML_PARSER_SEVERITY_VALIDITY_ERROR,
                          NULL /* locator */ );
    }
    if (str != NULL)
        xmlFree(str);
    va_end(ap);
}

static void XMLCDECL
xmlTextReaderValidityWarningRelay(void *ctx, const char *msg, ...)
{
    xmlTextReaderPtr reader = (xmlTextReaderPtr) ctx;

    char *str;

    va_list ap;

    va_start(ap, msg);
    str = xmlTextReaderBuildMessage(msg, ap);
    if (!reader->errorFunc) {
        xmlTextReaderValidityWarning(ctx, "%s", str);
    } else {
        reader->errorFunc(reader->errorFuncArg, str,
                          XML_PARSER_SEVERITY_VALIDITY_WARNING,
                          NULL /* locator */ );
    }
    if (str != NULL)
        xmlFree(str);
    va_end(ap);
}

static void
  xmlTextReaderStructuredError(void *ctxt, xmlErrorPtr error);

static void
xmlTextReaderValidityStructuredRelay(void *userData, xmlErrorPtr error)
{
    xmlTextReaderPtr reader = (xmlTextReaderPtr) userData;

    if (reader->sErrorFunc) {
        reader->sErrorFunc(reader->errorFuncArg, error);
    } else {
        xmlTextReaderStructuredError(reader, error);
    }
}
/**
 * xmlTextReaderRelaxNGSetSchema:
 * @reader:  the xmlTextReaderPtr used
 * @schema:  a precompiled RelaxNG schema
 *
 * Use RelaxNG to validate the document as it is processed.
 * Activation is only possible before the first Read().
 * if @schema is NULL, then RelaxNG validation is desactivated.
 @ The @schema should not be freed until the reader is deallocated
 * or its use has been deactivated.
 *
 * Returns 0 in case the RelaxNG validation could be (des)activated and
 *         -1 in case of error.
 */
int
xmlTextReaderRelaxNGSetSchema(xmlTextReaderPtr reader, xmlRelaxNGPtr schema) {
    if (reader == NULL)
        return(-1);
    if (schema == NULL) {
        if (reader->rngSchemas != NULL) {
	    xmlRelaxNGFree(reader->rngSchemas);
	    reader->rngSchemas = NULL;
	}
        if (reader->rngValidCtxt != NULL) {
	    xmlRelaxNGFreeValidCtxt(reader->rngValidCtxt);
	    reader->rngValidCtxt = NULL;
        }
	return(0);
    }
    if (reader->mode != XML_TEXTREADER_MODE_INITIAL)
	return(-1);
    if (reader->rngSchemas != NULL) {
	xmlRelaxNGFree(reader->rngSchemas);
	reader->rngSchemas = NULL;
    }
    if (reader->rngValidCtxt != NULL) {
	xmlRelaxNGFreeValidCtxt(reader->rngValidCtxt);
	reader->rngValidCtxt = NULL;
    }
    reader->rngValidCtxt = xmlRelaxNGNewValidCtxt(schema);
    if (reader->rngValidCtxt == NULL)
        return(-1);
    if (reader->errorFunc != NULL) {
	xmlRelaxNGSetValidErrors(reader->rngValidCtxt,
			xmlTextReaderValidityErrorRelay,
			xmlTextReaderValidityWarningRelay,
			reader);
    }
	if (reader->sErrorFunc != NULL) {
		xmlRelaxNGSetValidStructuredErrors(reader->rngValidCtxt,
			xmlTextReaderValidityStructuredRelay,
			reader);
    }
    reader->rngValidErrors = 0;
    reader->rngFullNode = NULL;
    reader->validate = XML_TEXTREADER_VALIDATE_RNG;
    return(0);
}

/**
 * xmlTextReaderSetSchema:
 * @reader:  the xmlTextReaderPtr used
 * @schema:  a precompiled Schema schema
 *
 * Use XSD Schema to validate the document as it is processed.
 * Activation is only possible before the first Read().
 * if @schema is NULL, then Schema validation is desactivated.
 @ The @schema should not be freed until the reader is deallocated
 * or its use has been deactivated.
 *
 * Returns 0 in case the Schema validation could be (des)activated and
 *         -1 in case of error.
 */
int
xmlTextReaderSetSchema(xmlTextReaderPtr reader, xmlSchemaPtr schema) {
    if (reader == NULL)
        return(-1);
    if (schema == NULL) {
	if (reader->xsdPlug != NULL) {
	    xmlSchemaSAXUnplug(reader->xsdPlug);
	    reader->xsdPlug = NULL;
	}
        if (reader->xsdValidCtxt != NULL) {
	    if (! reader->xsdPreserveCtxt)
		xmlSchemaFreeValidCtxt(reader->xsdValidCtxt);
	    reader->xsdValidCtxt = NULL;
        }
	reader->xsdPreserveCtxt = 0;
        if (reader->xsdSchemas != NULL) {
	    xmlSchemaFree(reader->xsdSchemas);
	    reader->xsdSchemas = NULL;
	}
	return(0);
    }
    if (reader->mode != XML_TEXTREADER_MODE_INITIAL)
	return(-1);
    if (reader->xsdPlug != NULL) {
	xmlSchemaSAXUnplug(reader->xsdPlug);
	reader->xsdPlug = NULL;
    }
    if (reader->xsdValidCtxt != NULL) {
	if (! reader->xsdPreserveCtxt)
	    xmlSchemaFreeValidCtxt(reader->xsdValidCtxt);
	reader->xsdValidCtxt = NULL;
    }
    reader->xsdPreserveCtxt = 0;
    if (reader->xsdSchemas != NULL) {
	xmlSchemaFree(reader->xsdSchemas);
	reader->xsdSchemas = NULL;
    }
    reader->xsdValidCtxt = xmlSchemaNewValidCtxt(schema);
    if (reader->xsdValidCtxt == NULL) {
	xmlSchemaFree(reader->xsdSchemas);
	reader->xsdSchemas = NULL;
        return(-1);
    }
    reader->xsdPlug = xmlSchemaSAXPlug(reader->xsdValidCtxt,
                                       &(reader->ctxt->sax),
				       &(reader->ctxt->userData));
    if (reader->xsdPlug == NULL) {
	xmlSchemaFree(reader->xsdSchemas);
	reader->xsdSchemas = NULL;
	xmlSchemaFreeValidCtxt(reader->xsdValidCtxt);
	reader->xsdValidCtxt = NULL;
	return(-1);
    }
    if (reader->errorFunc != NULL) {
	xmlSchemaSetValidErrors(reader->xsdValidCtxt,
			xmlTextReaderValidityErrorRelay,
			xmlTextReaderValidityWarningRelay,
			reader);
    }
	if (reader->sErrorFunc != NULL) {
		xmlSchemaSetValidStructuredErrors(reader->xsdValidCtxt,
			xmlTextReaderValidityStructuredRelay,
			reader);
    }
    reader->xsdValidErrors = 0;
    reader->validate = XML_TEXTREADER_VALIDATE_XSD;
    return(0);
}

/**
 * xmlTextReaderRelaxNGValidate:
 * @reader:  the xmlTextReaderPtr used
 * @rng:  the path to a RelaxNG schema or NULL
 *
 * Use RelaxNG to validate the document as it is processed.
 * Activation is only possible before the first Read().
 * if @rng is NULL, then RelaxNG validation is deactivated.
 *
 * Returns 0 in case the RelaxNG validation could be (de)activated and
 *         -1 in case of error.
 */
int
xmlTextReaderRelaxNGValidate(xmlTextReaderPtr reader, const char *rng) {
    xmlRelaxNGParserCtxtPtr ctxt;

    if (reader == NULL)
        return(-1);

    if (rng == NULL) {
        if (reader->rngValidCtxt != NULL) {
	    xmlRelaxNGFreeValidCtxt(reader->rngValidCtxt);
	    reader->rngValidCtxt = NULL;
        }
        if (reader->rngSchemas != NULL) {
	    xmlRelaxNGFree(reader->rngSchemas);
	    reader->rngSchemas = NULL;
	}
	return(0);
    }
    if (reader->mode != XML_TEXTREADER_MODE_INITIAL)
	return(-1);
    if (reader->rngSchemas != NULL) {
	xmlRelaxNGFree(reader->rngSchemas);
	reader->rngSchemas = NULL;
    }
    if (reader->rngValidCtxt != NULL) {
	xmlRelaxNGFreeValidCtxt(reader->rngValidCtxt);
	reader->rngValidCtxt = NULL;
    }
    ctxt = xmlRelaxNGNewParserCtxt(rng);
    if (reader->errorFunc != NULL) {
	xmlRelaxNGSetParserErrors(ctxt,
			 xmlTextReaderValidityErrorRelay,
			 xmlTextReaderValidityWarningRelay,
			 reader);
    }
    if (reader->sErrorFunc != NULL) {
	xmlRelaxNGSetValidStructuredErrors(reader->rngValidCtxt,
			xmlTextReaderValidityStructuredRelay,
			reader);
    }
    reader->rngSchemas = xmlRelaxNGParse(ctxt);
    xmlRelaxNGFreeParserCtxt(ctxt);
    if (reader->rngSchemas == NULL)
        return(-1);
    reader->rngValidCtxt = xmlRelaxNGNewValidCtxt(reader->rngSchemas);
    if (reader->rngValidCtxt == NULL) {
	xmlRelaxNGFree(reader->rngSchemas);
	reader->rngSchemas = NULL;
        return(-1);
    }
    if (reader->errorFunc != NULL) {
	xmlRelaxNGSetValidErrors(reader->rngValidCtxt,
			 xmlTextReaderValidityErrorRelay,
			 xmlTextReaderValidityWarningRelay,
			 reader);
    }
	if (reader->sErrorFunc != NULL) {
		xmlRelaxNGSetValidStructuredErrors(reader->rngValidCtxt,
			xmlTextReaderValidityStructuredRelay,
			reader);
    }
    reader->rngValidErrors = 0;
    reader->rngFullNode = NULL;
    reader->validate = XML_TEXTREADER_VALIDATE_RNG;
    return(0);
}

/**
 * xmlTextReaderSchemaValidateInternal:
 * @reader:  the xmlTextReaderPtr used
 * @xsd:  the path to a W3C XSD schema or NULL
 * @ctxt: the XML Schema validation context or NULL
 * @options: options (not used yet)
 *
 * Validate the document as it is processed using XML Schema.
 * Activation is only possible before the first Read().
 * If both @xsd and @ctxt are NULL then XML Schema validation is deactivated.
 *
 * Returns 0 in case the schemas validation could be (de)activated and
 *         -1 in case of error.
 */
static int
xmlTextReaderSchemaValidateInternal(xmlTextReaderPtr reader,
				    const char *xsd,
				    xmlSchemaValidCtxtPtr ctxt,
				    int options ATTRIBUTE_UNUSED)
{
    if (reader == NULL)
        return(-1);

    if ((xsd != NULL) && (ctxt != NULL))
	return(-1);

    if (((xsd != NULL) || (ctxt != NULL)) &&
	((reader->mode != XML_TEXTREADER_MODE_INITIAL) ||
        (reader->ctxt == NULL)))
	return(-1);

    /* Cleanup previous validation stuff. */
    if (reader->xsdPlug != NULL) {
	xmlSchemaSAXUnplug(reader->xsdPlug);
	reader->xsdPlug = NULL;
    }
    if (reader->xsdValidCtxt != NULL) {
	if (! reader->xsdPreserveCtxt)
	    xmlSchemaFreeValidCtxt(reader->xsdValidCtxt);
	reader->xsdValidCtxt = NULL;
    }
    reader->xsdPreserveCtxt = 0;
    if (reader->xsdSchemas != NULL) {
	xmlSchemaFree(reader->xsdSchemas);
	reader->xsdSchemas = NULL;
    }

    if ((xsd == NULL) && (ctxt == NULL)) {
	/* We just want to deactivate the validation, so get out. */
	return(0);
    }

    if (xsd != NULL) {
	xmlSchemaParserCtxtPtr pctxt;
	/* Parse the schema and create validation environment. */
	pctxt = xmlSchemaNewParserCtxt(xsd);
	if (reader->errorFunc != NULL) {
	    xmlSchemaSetParserErrors(pctxt,
		xmlTextReaderValidityErrorRelay,
		xmlTextReaderValidityWarningRelay,
		reader);
	}
	reader->xsdSchemas = xmlSchemaParse(pctxt);
	xmlSchemaFreeParserCtxt(pctxt);
	if (reader->xsdSchemas == NULL)
	    return(-1);
	reader->xsdValidCtxt = xmlSchemaNewValidCtxt(reader->xsdSchemas);
	if (reader->xsdValidCtxt == NULL) {
	    xmlSchemaFree(reader->xsdSchemas);
	    reader->xsdSchemas = NULL;
	    return(-1);
	}
	reader->xsdPlug = xmlSchemaSAXPlug(reader->xsdValidCtxt,
	    &(reader->ctxt->sax),
	    &(reader->ctxt->userData));
	if (reader->xsdPlug == NULL) {
	    xmlSchemaFree(reader->xsdSchemas);
	    reader->xsdSchemas = NULL;
	    xmlSchemaFreeValidCtxt(reader->xsdValidCtxt);
	    reader->xsdValidCtxt = NULL;
	    return(-1);
	}
    } else {
	/* Use the given validation context. */
	reader->xsdValidCtxt = ctxt;
	reader->xsdPreserveCtxt = 1;
	reader->xsdPlug = xmlSchemaSAXPlug(reader->xsdValidCtxt,
	    &(reader->ctxt->sax),
	    &(reader->ctxt->userData));
	if (reader->xsdPlug == NULL) {
	    reader->xsdValidCtxt = NULL;
	    reader->xsdPreserveCtxt = 0;
	    return(-1);
	}
    }
    /*
    * Redirect the validation context's error channels to use
    * the reader channels.
    * TODO: In case the user provides the validation context we
    *   could make this redirection optional.
    */
    if (reader->errorFunc != NULL) {
	xmlSchemaSetValidErrors(reader->xsdValidCtxt,
			 xmlTextReaderValidityErrorRelay,
			 xmlTextReaderValidityWarningRelay,
			 reader);
    }
	if (reader->sErrorFunc != NULL) {
		xmlSchemaSetValidStructuredErrors(reader->xsdValidCtxt,
			xmlTextReaderValidityStructuredRelay,
			reader);
    }
    reader->xsdValidErrors = 0;
    reader->validate = XML_TEXTREADER_VALIDATE_XSD;
    return(0);
}

/**
 * xmlTextReaderSchemaValidateCtxt:
 * @reader:  the xmlTextReaderPtr used
 * @ctxt: the XML Schema validation context or NULL
 * @options: options (not used yet)
 *
 * Use W3C XSD schema context to validate the document as it is processed.
 * Activation is only possible before the first Read().
 * If @ctxt is NULL, then XML Schema validation is deactivated.
 *
 * Returns 0 in case the schemas validation could be (de)activated and
 *         -1 in case of error.
 */
int
xmlTextReaderSchemaValidateCtxt(xmlTextReaderPtr reader,
				    xmlSchemaValidCtxtPtr ctxt,
				    int options)
{
    return(xmlTextReaderSchemaValidateInternal(reader, NULL, ctxt, options));
}

/**
 * xmlTextReaderSchemaValidate:
 * @reader:  the xmlTextReaderPtr used
 * @xsd:  the path to a W3C XSD schema or NULL
 *
 * Use W3C XSD schema to validate the document as it is processed.
 * Activation is only possible before the first Read().
 * If @xsd is NULL, then XML Schema validation is deactivated.
 *
 * Returns 0 in case the schemas validation could be (de)activated and
 *         -1 in case of error.
 */
int
xmlTextReaderSchemaValidate(xmlTextReaderPtr reader, const char *xsd)
{
    return(xmlTextReaderSchemaValidateInternal(reader, xsd, NULL, 0));
}
#endif

/**
 * xmlTextReaderIsNamespaceDecl:
 * @reader: the xmlTextReaderPtr used
 *
 * Determine whether the current node is a namespace declaration
 * rather than a regular attribute.
 *
 * Returns 1 if the current node is a namespace declaration, 0 if it
 * is a regular attribute or other type of node, or -1 in case of
 * error.
 */
int
xmlTextReaderIsNamespaceDecl(xmlTextReaderPtr reader) {
    xmlNodePtr node;
    if (reader == NULL)
	return(-1);
    if (reader->node == NULL)
	return(-1);
    if (reader->curnode != NULL)
	node = reader->curnode;
    else
	node = reader->node;

    if (XML_NAMESPACE_DECL == node->type)
	return(1);
    else
	return(0);
}

/**
 * xmlTextReaderConstXmlVersion:
 * @reader:  the xmlTextReaderPtr used
 *
 * Determine the XML version of the document being read.
 *
 * Returns a string containing the XML version of the document or NULL
 * in case of error.  The string is deallocated with the reader.
 */
const xmlChar *
xmlTextReaderConstXmlVersion(xmlTextReaderPtr reader) {
    xmlDocPtr doc = NULL;
    if (reader == NULL)
	return(NULL);
    if (reader->doc != NULL)
        doc = reader->doc;
    else if (reader->ctxt != NULL)
	doc = reader->ctxt->myDoc;
    if (doc == NULL)
	return(NULL);

    if (doc->version == NULL)
	return(NULL);
    else
      return(CONSTSTR(doc->version));
}

/**
 * xmlTextReaderStandalone:
 * @reader:  the xmlTextReaderPtr used
 *
 * Determine the standalone status of the document being read.
 *
 * Returns 1 if the document was declared to be standalone, 0 if it
 * was declared to be not standalone, or -1 if the document did not
 * specify its standalone status or in case of error.
 */
int
xmlTextReaderStandalone(xmlTextReaderPtr reader) {
    xmlDocPtr doc = NULL;
    if (reader == NULL)
	return(-1);
    if (reader->doc != NULL)
        doc = reader->doc;
    else if (reader->ctxt != NULL)
	doc = reader->ctxt->myDoc;
    if (doc == NULL)
	return(-1);

    return(doc->standalone);
}

/************************************************************************
 *									*
 *			Error Handling Extensions                       *
 *									*
 ************************************************************************/

/* helper to build a xmlMalloc'ed string from a format and va_list */
static char *
xmlTextReaderBuildMessage(const char *msg, va_list ap) {
    int size = 0;
    int chars;
    char *larger;
    char *str = NULL;
    va_list aq;

    while (1) {
        VA_COPY(aq, ap);
        chars = vsnprintf(str, size, msg, aq);
        va_end(aq);
        if (chars < 0) {
	    xmlGenericError(xmlGenericErrorContext, "vsnprintf failed !\n");
	    if (str)
		xmlFree(str);
	    return NULL;
	}
	if ((chars < size) || (size == MAX_ERR_MSG_SIZE))
            break;
        if (chars < MAX_ERR_MSG_SIZE)
	size = chars + 1;
	else
		size = MAX_ERR_MSG_SIZE;
        if ((larger = (char *) xmlRealloc(str, size)) == NULL) {
	    xmlGenericError(xmlGenericErrorContext, "xmlRealloc failed !\n");
	    if (str)
                xmlFree(str);
            return NULL;
        }
        str = larger;
    }

    return str;
}

/**
 * xmlTextReaderLocatorLineNumber:
 * @locator: the xmlTextReaderLocatorPtr used
 *
 * Obtain the line number for the given locator.
 *
 * Returns the line number or -1 in case of error.
 */
int
xmlTextReaderLocatorLineNumber(xmlTextReaderLocatorPtr locator) {
    /* we know that locator is a xmlParserCtxtPtr */
    xmlParserCtxtPtr ctx = (xmlParserCtxtPtr)locator;
    int ret = -1;

    if (locator == NULL)
        return(-1);
    if (ctx->node != NULL) {
	ret = xmlGetLineNo(ctx->node);
    }
    else {
	/* inspired from error.c */
	xmlParserInputPtr input;
	input = ctx->input;
	if ((input->filename == NULL) && (ctx->inputNr > 1))
	    input = ctx->inputTab[ctx->inputNr - 2];
	if (input != NULL) {
	    ret = input->line;
	}
	else {
	    ret = -1;
	}
    }

    return ret;
}

/**
 * xmlTextReaderLocatorBaseURI:
 * @locator: the xmlTextReaderLocatorPtr used
 *
 * Obtain the base URI for the given locator.
 *
 * Returns the base URI or NULL in case of error,
 *    if non NULL it need to be freed by the caller.
 */
xmlChar *
xmlTextReaderLocatorBaseURI(xmlTextReaderLocatorPtr locator) {
    /* we know that locator is a xmlParserCtxtPtr */
    xmlParserCtxtPtr ctx = (xmlParserCtxtPtr)locator;
    xmlChar *ret = NULL;

    if (locator == NULL)
        return(NULL);
    if (ctx->node != NULL) {
	ret = xmlNodeGetBase(NULL,ctx->node);
    }
    else {
	/* inspired from error.c */
	xmlParserInputPtr input;
	input = ctx->input;
	if ((input->filename == NULL) && (ctx->inputNr > 1))
	    input = ctx->inputTab[ctx->inputNr - 2];
	if (input != NULL) {
	    ret = xmlStrdup(BAD_CAST input->filename);
	}
	else {
	    ret = NULL;
	}
    }

    return ret;
}

static void
xmlTextReaderGenericError(void *ctxt, xmlParserSeverities severity,
                          char *str)
{
    xmlParserCtxtPtr ctx = (xmlParserCtxtPtr) ctxt;

    xmlTextReaderPtr reader = (xmlTextReaderPtr) ctx->_private;

    if (str != NULL) {
        if (reader->errorFunc)
            reader->errorFunc(reader->errorFuncArg, str, severity,
                              (xmlTextReaderLocatorPtr) ctx);
        xmlFree(str);
    }
}

static void
xmlTextReaderStructuredError(void *ctxt, xmlErrorPtr error)
{
    xmlParserCtxtPtr ctx = (xmlParserCtxtPtr) ctxt;

    xmlTextReaderPtr reader = (xmlTextReaderPtr) ctx->_private;

    if (error && reader->sErrorFunc) {
        reader->sErrorFunc(reader->errorFuncArg, (xmlErrorPtr) error);
    }
}

static void XMLCDECL
xmlTextReaderError(void *ctxt, const char *msg, ...)
{
    va_list ap;

    va_start(ap, msg);
    xmlTextReaderGenericError(ctxt,
                              XML_PARSER_SEVERITY_ERROR,
                              xmlTextReaderBuildMessage(msg, ap));
    va_end(ap);

}

static void XMLCDECL
xmlTextReaderWarning(void *ctxt, const char *msg, ...)
{
    va_list ap;

    va_start(ap, msg);
    xmlTextReaderGenericError(ctxt,
                              XML_PARSER_SEVERITY_WARNING,
                              xmlTextReaderBuildMessage(msg, ap));
    va_end(ap);
}

static void XMLCDECL
xmlTextReaderValidityError(void *ctxt, const char *msg, ...)
{
    va_list ap;

    int len = xmlStrlen((const xmlChar *) msg);

    if ((len > 1) && (msg[len - 2] != ':')) {
        /*
         * some callbacks only report locator information:
         * skip them (mimicking behaviour in error.c)
         */
        va_start(ap, msg);
        xmlTextReaderGenericError(ctxt,
                                  XML_PARSER_SEVERITY_VALIDITY_ERROR,
                                  xmlTextReaderBuildMessage(msg, ap));
        va_end(ap);
    }
}

static void XMLCDECL
xmlTextReaderValidityWarning(void *ctxt, const char *msg, ...)
{
    va_list ap;

    int len = xmlStrlen((const xmlChar *) msg);

    if ((len != 0) && (msg[len - 1] != ':')) {
        /*
         * some callbacks only report locator information:
         * skip them (mimicking behaviour in error.c)
         */
        va_start(ap, msg);
        xmlTextReaderGenericError(ctxt,
                                  XML_PARSER_SEVERITY_VALIDITY_WARNING,
                                  xmlTextReaderBuildMessage(msg, ap));
        va_end(ap);
    }
}

/**
 * xmlTextReaderSetErrorHandler:
 * @reader:  the xmlTextReaderPtr used
 * @f:	the callback function to call on error and warnings
 * @arg:    a user argument to pass to the callback function
 *
 * Register a callback function that will be called on error and warnings.
 *
 * If @f is NULL, the default error and warning handlers are restored.
 */
void
xmlTextReaderSetErrorHandler(xmlTextReaderPtr reader,
                             xmlTextReaderErrorFunc f, void *arg)
{
    if (f != NULL) {
        reader->ctxt->sax->error = xmlTextReaderError;
        reader->ctxt->sax->serror = NULL;
        reader->ctxt->vctxt.error = xmlTextReaderValidityError;
        reader->ctxt->sax->warning = xmlTextReaderWarning;
        reader->ctxt->vctxt.warning = xmlTextReaderValidityWarning;
        reader->errorFunc = f;
        reader->sErrorFunc = NULL;
        reader->errorFuncArg = arg;
#ifdef LIBXML_SCHEMAS_ENABLED
        if (reader->rngValidCtxt) {
            xmlRelaxNGSetValidErrors(reader->rngValidCtxt,
                                     xmlTextReaderValidityErrorRelay,
                                     xmlTextReaderValidityWarningRelay,
                                     reader);
            xmlRelaxNGSetValidStructuredErrors(reader->rngValidCtxt, NULL,
                                               reader);
        }
        if (reader->xsdValidCtxt) {
            xmlSchemaSetValidErrors(reader->xsdValidCtxt,
                                    xmlTextReaderValidityErrorRelay,
                                    xmlTextReaderValidityWarningRelay,
                                    reader);
            xmlSchemaSetValidStructuredErrors(reader->xsdValidCtxt, NULL,
                                              reader);
        }
#endif
    } else {
        /* restore defaults */
        reader->ctxt->sax->error = xmlParserError;
        reader->ctxt->vctxt.error = xmlParserValidityError;
        reader->ctxt->sax->warning = xmlParserWarning;
        reader->ctxt->vctxt.warning = xmlParserValidityWarning;
        reader->errorFunc = NULL;
        reader->sErrorFunc = NULL;
        reader->errorFuncArg = NULL;
#ifdef LIBXML_SCHEMAS_ENABLED
        if (reader->rngValidCtxt) {
            xmlRelaxNGSetValidErrors(reader->rngValidCtxt, NULL, NULL,
                                     reader);
            xmlRelaxNGSetValidStructuredErrors(reader->rngValidCtxt, NULL,
                                               reader);
        }
        if (reader->xsdValidCtxt) {
            xmlSchemaSetValidErrors(reader->xsdValidCtxt, NULL, NULL,
                                    reader);
            xmlSchemaSetValidStructuredErrors(reader->xsdValidCtxt, NULL,
                                              reader);
        }
#endif
    }
}

/**
* xmlTextReaderSetStructuredErrorHandler:
 * @reader:  the xmlTextReaderPtr used
 * @f:	the callback function to call on error and warnings
 * @arg:    a user argument to pass to the callback function
 *
 * Register a callback function that will be called on error and warnings.
 *
 * If @f is NULL, the default error and warning handlers are restored.
 */
void
xmlTextReaderSetStructuredErrorHandler(xmlTextReaderPtr reader,
                                       xmlStructuredErrorFunc f, void *arg)
{
    if (f != NULL) {
        reader->ctxt->sax->error = NULL;
        reader->ctxt->sax->serror = xmlTextReaderStructuredError;
        reader->ctxt->vctxt.error = xmlTextReaderValidityError;
        reader->ctxt->sax->warning = xmlTextReaderWarning;
        reader->ctxt->vctxt.warning = xmlTextReaderValidityWarning;
        reader->sErrorFunc = f;
        reader->errorFunc = NULL;
        reader->errorFuncArg = arg;
#ifdef LIBXML_SCHEMAS_ENABLED
        if (reader->rngValidCtxt) {
            xmlRelaxNGSetValidErrors(reader->rngValidCtxt, NULL, NULL,
                                     reader);
            xmlRelaxNGSetValidStructuredErrors(reader->rngValidCtxt,
                                        xmlTextReaderValidityStructuredRelay,
                                               reader);
        }
        if (reader->xsdValidCtxt) {
            xmlSchemaSetValidErrors(reader->xsdValidCtxt, NULL, NULL,
                                    reader);
            xmlSchemaSetValidStructuredErrors(reader->xsdValidCtxt,
                                       xmlTextReaderValidityStructuredRelay,
                                              reader);
        }
#endif
    } else {
        /* restore defaults */
        reader->ctxt->sax->error = xmlParserError;
        reader->ctxt->sax->serror = NULL;
        reader->ctxt->vctxt.error = xmlParserValidityError;
        reader->ctxt->sax->warning = xmlParserWarning;
        reader->ctxt->vctxt.warning = xmlParserValidityWarning;
        reader->errorFunc = NULL;
        reader->sErrorFunc = NULL;
        reader->errorFuncArg = NULL;
#ifdef LIBXML_SCHEMAS_ENABLED
        if (reader->rngValidCtxt) {
            xmlRelaxNGSetValidErrors(reader->rngValidCtxt, NULL, NULL,
                                     reader);
            xmlRelaxNGSetValidStructuredErrors(reader->rngValidCtxt, NULL,
                                               reader);
        }
        if (reader->xsdValidCtxt) {
            xmlSchemaSetValidErrors(reader->xsdValidCtxt, NULL, NULL,
                                    reader);
            xmlSchemaSetValidStructuredErrors(reader->xsdValidCtxt, NULL,
                                              reader);
        }
#endif
    }
}

/**
 * xmlTextReaderIsValid:
 * @reader:  the xmlTextReaderPtr used
 *
 * Retrieve the validity status from the parser context
 *
 * Returns the flag value 1 if valid, 0 if no, and -1 in case of error
 */
int
xmlTextReaderIsValid(xmlTextReaderPtr reader)
{
    if (reader == NULL)
        return (-1);
#ifdef LIBXML_SCHEMAS_ENABLED
    if (reader->validate == XML_TEXTREADER_VALIDATE_RNG)
        return (reader->rngValidErrors == 0);
    if (reader->validate == XML_TEXTREADER_VALIDATE_XSD)
        return (reader->xsdValidErrors == 0);
#endif
    if ((reader->ctxt != NULL) && (reader->ctxt->validate == 1))
        return (reader->ctxt->valid);
    return (0);
}

/**
 * xmlTextReaderGetErrorHandler:
 * @reader:  the xmlTextReaderPtr used
 * @f:	the callback function or NULL is no callback has been registered
 * @arg:    a user argument
 *
 * Retrieve the error callback function and user argument.
 */
void
xmlTextReaderGetErrorHandler(xmlTextReaderPtr reader,
                             xmlTextReaderErrorFunc * f, void **arg)
{
    if (f != NULL)
        *f = reader->errorFunc;
    if (arg != NULL)
        *arg = reader->errorFuncArg;
}
/************************************************************************
 *									*
 *	New set (2.6.0) of simpler and more flexible APIs		*
 *									*
 ************************************************************************/

/**
 * xmlTextReaderSetup:
 * @reader:  an XML reader
 * @input: xmlParserInputBufferPtr used to feed the reader, will
 *         be destroyed with it.
 * @URL:  the base URL to use for the document
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * Setup an XML reader with new options
 *
 * Returns 0 in case of success and -1 in case of error.
 */
int
xmlTextReaderSetup(xmlTextReaderPtr reader,
                   xmlParserInputBufferPtr input, const char *URL,
                   const char *encoding, int options)
{
    if (reader == NULL) {
        if (input != NULL)
	    xmlFreeParserInputBuffer(input);
        return (-1);
    }

    /*
     * we force the generation of compact text nodes on the reader
     * since usr applications should never modify the tree
     */
    options |= XML_PARSE_COMPACT;

    reader->doc = NULL;
    reader->entNr = 0;
    reader->parserFlags = options;
    reader->validate = XML_TEXTREADER_NOT_VALIDATE;
    if ((input != NULL) && (reader->input != NULL) &&
        (reader->allocs & XML_TEXTREADER_INPUT)) {
	xmlFreeParserInputBuffer(reader->input);
	reader->input = NULL;
	reader->allocs -= XML_TEXTREADER_INPUT;
    }
    if (input != NULL) {
	reader->input = input;
	reader->allocs |= XML_TEXTREADER_INPUT;
    }
    if (reader->buffer == NULL)
        reader->buffer = xmlBufferCreateSize(100);
    if (reader->buffer == NULL) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlTextReaderSetup : malloc failed\n");
        return (-1);
    }
    if (reader->sax == NULL)
	reader->sax = (xmlSAXHandler *) xmlMalloc(sizeof(xmlSAXHandler));
    if (reader->sax == NULL) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlTextReaderSetup : malloc failed\n");
        return (-1);
    }
    xmlSAXVersion(reader->sax, 2);
    reader->startElement = reader->sax->startElement;
    reader->sax->startElement = xmlTextReaderStartElement;
    reader->endElement = reader->sax->endElement;
    reader->sax->endElement = xmlTextReaderEndElement;
#ifdef LIBXML_SAX1_ENABLED
    if (reader->sax->initialized == XML_SAX2_MAGIC) {
#endif /* LIBXML_SAX1_ENABLED */
        reader->startElementNs = reader->sax->startElementNs;
        reader->sax->startElementNs = xmlTextReaderStartElementNs;
        reader->endElementNs = reader->sax->endElementNs;
        reader->sax->endElementNs = xmlTextReaderEndElementNs;
#ifdef LIBXML_SAX1_ENABLED
    } else {
        reader->startElementNs = NULL;
        reader->endElementNs = NULL;
    }
#endif /* LIBXML_SAX1_ENABLED */
    reader->characters = reader->sax->characters;
    reader->sax->characters = xmlTextReaderCharacters;
    reader->sax->ignorableWhitespace = xmlTextReaderCharacters;
    reader->cdataBlock = reader->sax->cdataBlock;
    reader->sax->cdataBlock = xmlTextReaderCDataBlock;

    reader->mode = XML_TEXTREADER_MODE_INITIAL;
    reader->node = NULL;
    reader->curnode = NULL;
    if (input != NULL) {
        if (reader->input->buffer->use < 4) {
            xmlParserInputBufferRead(input, 4);
        }
        if (reader->ctxt == NULL) {
            if (reader->input->buffer->use >= 4) {
                reader->ctxt = xmlCreatePushParserCtxt(reader->sax, NULL,
		       (const char *) reader->input->buffer->content, 4, URL);
                reader->base = 0;
                reader->cur = 4;
            } else {
                reader->ctxt =
                    xmlCreatePushParserCtxt(reader->sax, NULL, NULL, 0, URL);
                reader->base = 0;
                reader->cur = 0;
            }
        } else {
	    xmlParserInputPtr inputStream;
	    xmlParserInputBufferPtr buf;
	    xmlCharEncoding enc = XML_CHAR_ENCODING_NONE;

	    xmlCtxtReset(reader->ctxt);
	    buf = xmlAllocParserInputBuffer(enc);
	    if (buf == NULL) return(-1);
	    inputStream = xmlNewInputStream(reader->ctxt);
	    if (inputStream == NULL) {
		xmlFreeParserInputBuffer(buf);
		return(-1);
	    }

	    if (URL == NULL)
		inputStream->filename = NULL;
	    else
		inputStream->filename = (char *)
		    xmlCanonicPath((const xmlChar *) URL);
	    inputStream->buf = buf;
	    inputStream->base = inputStream->buf->buffer->content;
	    inputStream->cur = inputStream->buf->buffer->content;
	    inputStream->end =
            &inputStream->buf->buffer->content[inputStream->buf->buffer->use];

	    inputPush(reader->ctxt, inputStream);
	    reader->cur = 0;
	}
        if (reader->ctxt == NULL) {
            xmlGenericError(xmlGenericErrorContext,
                            "xmlTextReaderSetup : malloc failed\n");
            return (-1);
        }
    }
    if (reader->dict != NULL) {
        if (reader->ctxt->dict != NULL) {
	    if (reader->dict != reader->ctxt->dict) {
		xmlDictFree(reader->dict);
		reader->dict = reader->ctxt->dict;
	    }
	} else {
	    reader->ctxt->dict = reader->dict;
	}
    } else {
	if (reader->ctxt->dict == NULL)
	    reader->ctxt->dict = xmlDictCreate();
        reader->dict = reader->ctxt->dict;
    }
    reader->ctxt->_private = reader;
    reader->ctxt->linenumbers = 1;
    reader->ctxt->dictNames = 1;
    /*
     * use the parser dictionnary to allocate all elements and attributes names
     */
    reader->ctxt->docdict = 1;
    reader->ctxt->parseMode = XML_PARSE_READER;

#ifdef LIBXML_XINCLUDE_ENABLED
    if (reader->xincctxt != NULL) {
	xmlXIncludeFreeContext(reader->xincctxt);
	reader->xincctxt = NULL;
    }
    if (options & XML_PARSE_XINCLUDE) {
        reader->xinclude = 1;
	reader->xinclude_name = xmlDictLookup(reader->dict, XINCLUDE_NODE, -1);
	options -= XML_PARSE_XINCLUDE;
    } else
        reader->xinclude = 0;
    reader->in_xinclude = 0;
#endif
#ifdef LIBXML_PATTERN_ENABLED
    if (reader->patternTab == NULL) {
        reader->patternNr = 0;
	reader->patternMax = 0;
    }
    while (reader->patternNr > 0) {
        reader->patternNr--;
	if (reader->patternTab[reader->patternNr] != NULL) {
	    xmlFreePattern(reader->patternTab[reader->patternNr]);
            reader->patternTab[reader->patternNr] = NULL;
	}
    }
#endif

    if (options & XML_PARSE_DTDVALID)
        reader->validate = XML_TEXTREADER_VALIDATE_DTD;

    xmlCtxtUseOptions(reader->ctxt, options);
    if (encoding != NULL) {
        xmlCharEncodingHandlerPtr hdlr;

        hdlr = xmlFindCharEncodingHandler(encoding);
        if (hdlr != NULL)
            xmlSwitchToEncoding(reader->ctxt, hdlr);
    }
    if ((URL != NULL) && (reader->ctxt->input != NULL) &&
        (reader->ctxt->input->filename == NULL))
        reader->ctxt->input->filename = (char *)
            xmlStrdup((const xmlChar *) URL);

    reader->doc = NULL;

    return (0);
}

/**
 * xmlTextReaderByteConsumed:
 * @reader: an XML reader
 *
 * This function provides the current index of the parser used
 * by the reader, relative to the start of the current entity.
 * This function actually just wraps a call to xmlBytesConsumed()
 * for the parser context associated with the reader.
 * See xmlBytesConsumed() for more information.
 *
 * Returns the index in bytes from the beginning of the entity or -1
 *         in case the index could not be computed.
 */
long
xmlTextReaderByteConsumed(xmlTextReaderPtr reader) {
    if ((reader == NULL) || (reader->ctxt == NULL))
        return(-1);
    return(xmlByteConsumed(reader->ctxt));
}


/**
 * xmlReaderWalker:
 * @doc:  a preparsed document
 *
 * Create an xmltextReader for a preparsed document.
 *
 * Returns the new reader or NULL in case of error.
 */
xmlTextReaderPtr
xmlReaderWalker(xmlDocPtr doc)
{
    xmlTextReaderPtr ret;

    if (doc == NULL)
        return(NULL);

    ret = xmlMalloc(sizeof(xmlTextReader));
    if (ret == NULL) {
        xmlGenericError(xmlGenericErrorContext,
		"xmlNewTextReader : malloc failed\n");
	return(NULL);
    }
    memset(ret, 0, sizeof(xmlTextReader));
    ret->entNr = 0;
    ret->input = NULL;
    ret->mode = XML_TEXTREADER_MODE_INITIAL;
    ret->node = NULL;
    ret->curnode = NULL;
    ret->base = 0;
    ret->cur = 0;
    ret->allocs = XML_TEXTREADER_CTXT;
    ret->doc = doc;
    ret->state = XML_TEXTREADER_START;
    ret->dict = xmlDictCreate();
    return(ret);
}

/**
 * xmlReaderForDoc:
 * @cur:  a pointer to a zero terminated string
 * @URL:  the base URL to use for the document
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * Create an xmltextReader for an XML in-memory document.
 * The parsing flags @options are a combination of xmlParserOption.
 *
 * Returns the new reader or NULL in case of error.
 */
xmlTextReaderPtr
xmlReaderForDoc(const xmlChar * cur, const char *URL, const char *encoding,
                int options)
{
    int len;

    if (cur == NULL)
        return (NULL);
    len = xmlStrlen(cur);

    return (xmlReaderForMemory
            ((const char *) cur, len, URL, encoding, options));
}

/**
 * xmlReaderForFile:
 * @filename:  a file or URL
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * parse an XML file from the filesystem or the network.
 * The parsing flags @options are a combination of xmlParserOption.
 *
 * Returns the new reader or NULL in case of error.
 */
xmlTextReaderPtr
xmlReaderForFile(const char *filename, const char *encoding, int options)
{
    xmlTextReaderPtr reader;

    reader = xmlNewTextReaderFilename(filename);
    if (reader == NULL)
        return (NULL);
    xmlTextReaderSetup(reader, NULL, NULL, encoding, options);
    return (reader);
}

/**
 * xmlReaderForMemory:
 * @buffer:  a pointer to a char array
 * @size:  the size of the array
 * @URL:  the base URL to use for the document
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * Create an xmltextReader for an XML in-memory document.
 * The parsing flags @options are a combination of xmlParserOption.
 *
 * Returns the new reader or NULL in case of error.
 */
xmlTextReaderPtr
xmlReaderForMemory(const char *buffer, int size, const char *URL,
                   const char *encoding, int options)
{
    xmlTextReaderPtr reader;
    xmlParserInputBufferPtr buf;

    buf = xmlParserInputBufferCreateStatic(buffer, size,
                                      XML_CHAR_ENCODING_NONE);
    if (buf == NULL) {
        return (NULL);
    }
    reader = xmlNewTextReader(buf, URL);
    if (reader == NULL) {
        xmlFreeParserInputBuffer(buf);
        return (NULL);
    }
    reader->allocs |= XML_TEXTREADER_INPUT;
    xmlTextReaderSetup(reader, NULL, URL, encoding, options);
    return (reader);
}

/**
 * xmlReaderForFd:
 * @fd:  an open file descriptor
 * @URL:  the base URL to use for the document
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * Create an xmltextReader for an XML from a file descriptor.
 * The parsing flags @options are a combination of xmlParserOption.
 * NOTE that the file descriptor will not be closed when the
 *      reader is closed or reset.
 *
 * Returns the new reader or NULL in case of error.
 */
xmlTextReaderPtr
xmlReaderForFd(int fd, const char *URL, const char *encoding, int options)
{
    xmlTextReaderPtr reader;
    xmlParserInputBufferPtr input;

    if (fd < 0)
        return (NULL);

    input = xmlParserInputBufferCreateFd(fd, XML_CHAR_ENCODING_NONE);
    if (input == NULL)
        return (NULL);
    input->closecallback = NULL;
    reader = xmlNewTextReader(input, URL);
    if (reader == NULL) {
        xmlFreeParserInputBuffer(input);
        return (NULL);
    }
    reader->allocs |= XML_TEXTREADER_INPUT;
    xmlTextReaderSetup(reader, NULL, URL, encoding, options);
    return (reader);
}

/**
 * xmlReaderForIO:
 * @ioread:  an I/O read function
 * @ioclose:  an I/O close function
 * @ioctx:  an I/O handler
 * @URL:  the base URL to use for the document
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * Create an xmltextReader for an XML document from I/O functions and source.
 * The parsing flags @options are a combination of xmlParserOption.
 *
 * Returns the new reader or NULL in case of error.
 */
xmlTextReaderPtr
xmlReaderForIO(xmlInputReadCallback ioread, xmlInputCloseCallback ioclose,
               void *ioctx, const char *URL, const char *encoding,
               int options)
{
    xmlTextReaderPtr reader;
    xmlParserInputBufferPtr input;

    if (ioread == NULL)
        return (NULL);

    input = xmlParserInputBufferCreateIO(ioread, ioclose, ioctx,
                                         XML_CHAR_ENCODING_NONE);
    if (input == NULL)
        return (NULL);
    reader = xmlNewTextReader(input, URL);
    if (reader == NULL) {
        xmlFreeParserInputBuffer(input);
        return (NULL);
    }
    reader->allocs |= XML_TEXTREADER_INPUT;
    xmlTextReaderSetup(reader, NULL, URL, encoding, options);
    return (reader);
}

/**
 * xmlReaderNewWalker:
 * @reader:  an XML reader
 * @doc:  a preparsed document
 *
 * Setup an xmltextReader to parse a preparsed XML document.
 * This reuses the existing @reader xmlTextReader.
 *
 * Returns 0 in case of success and -1 in case of error
 */
int
xmlReaderNewWalker(xmlTextReaderPtr reader, xmlDocPtr doc)
{
    if (doc == NULL)
        return (-1);
    if (reader == NULL)
        return (-1);

    if (reader->input != NULL) {
        xmlFreeParserInputBuffer(reader->input);
    }
    if (reader->ctxt != NULL) {
	xmlCtxtReset(reader->ctxt);
    }

    reader->entNr = 0;
    reader->input = NULL;
    reader->mode = XML_TEXTREADER_MODE_INITIAL;
    reader->node = NULL;
    reader->curnode = NULL;
    reader->base = 0;
    reader->cur = 0;
    reader->allocs = XML_TEXTREADER_CTXT;
    reader->doc = doc;
    reader->state = XML_TEXTREADER_START;
    if (reader->dict == NULL) {
        if ((reader->ctxt != NULL) && (reader->ctxt->dict != NULL))
	    reader->dict = reader->ctxt->dict;
	else
	    reader->dict = xmlDictCreate();
    }
    return(0);
}

/**
 * xmlReaderNewDoc:
 * @reader:  an XML reader
 * @cur:  a pointer to a zero terminated string
 * @URL:  the base URL to use for the document
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * Setup an xmltextReader to parse an XML in-memory document.
 * The parsing flags @options are a combination of xmlParserOption.
 * This reuses the existing @reader xmlTextReader.
 *
 * Returns 0 in case of success and -1 in case of error
 */
int
xmlReaderNewDoc(xmlTextReaderPtr reader, const xmlChar * cur,
                const char *URL, const char *encoding, int options)
{

    int len;

    if (cur == NULL)
        return (-1);
    if (reader == NULL)
        return (-1);

    len = xmlStrlen(cur);
    return (xmlReaderNewMemory(reader, (const char *)cur, len,
                               URL, encoding, options));
}

/**
 * xmlReaderNewFile:
 * @reader:  an XML reader
 * @filename:  a file or URL
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * parse an XML file from the filesystem or the network.
 * The parsing flags @options are a combination of xmlParserOption.
 * This reuses the existing @reader xmlTextReader.
 *
 * Returns 0 in case of success and -1 in case of error
 */
int
xmlReaderNewFile(xmlTextReaderPtr reader, const char *filename,
                 const char *encoding, int options)
{
    xmlParserInputBufferPtr input;

    if (filename == NULL)
        return (-1);
    if (reader == NULL)
        return (-1);

    input =
        xmlParserInputBufferCreateFilename(filename,
                                           XML_CHAR_ENCODING_NONE);
    if (input == NULL)
        return (-1);
    return (xmlTextReaderSetup(reader, input, filename, encoding, options));
}

/**
 * xmlReaderNewMemory:
 * @reader:  an XML reader
 * @buffer:  a pointer to a char array
 * @size:  the size of the array
 * @URL:  the base URL to use for the document
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * Setup an xmltextReader to parse an XML in-memory document.
 * The parsing flags @options are a combination of xmlParserOption.
 * This reuses the existing @reader xmlTextReader.
 *
 * Returns 0 in case of success and -1 in case of error
 */
int
xmlReaderNewMemory(xmlTextReaderPtr reader, const char *buffer, int size,
                   const char *URL, const char *encoding, int options)
{
    xmlParserInputBufferPtr input;

    if (reader == NULL)
        return (-1);
    if (buffer == NULL)
        return (-1);

    input = xmlParserInputBufferCreateStatic(buffer, size,
                                      XML_CHAR_ENCODING_NONE);
    if (input == NULL) {
        return (-1);
    }
    return (xmlTextReaderSetup(reader, input, URL, encoding, options));
}

/**
 * xmlReaderNewFd:
 * @reader:  an XML reader
 * @fd:  an open file descriptor
 * @URL:  the base URL to use for the document
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * Setup an xmltextReader to parse an XML from a file descriptor.
 * NOTE that the file descriptor will not be closed when the
 *      reader is closed or reset.
 * The parsing flags @options are a combination of xmlParserOption.
 * This reuses the existing @reader xmlTextReader.
 *
 * Returns 0 in case of success and -1 in case of error
 */
int
xmlReaderNewFd(xmlTextReaderPtr reader, int fd,
               const char *URL, const char *encoding, int options)
{
    xmlParserInputBufferPtr input;

    if (fd < 0)
        return (-1);
    if (reader == NULL)
        return (-1);

    input = xmlParserInputBufferCreateFd(fd, XML_CHAR_ENCODING_NONE);
    if (input == NULL)
        return (-1);
    input->closecallback = NULL;
    return (xmlTextReaderSetup(reader, input, URL, encoding, options));
}

/**
 * xmlReaderNewIO:
 * @reader:  an XML reader
 * @ioread:  an I/O read function
 * @ioclose:  an I/O close function
 * @ioctx:  an I/O handler
 * @URL:  the base URL to use for the document
 * @encoding:  the document encoding, or NULL
 * @options:  a combination of xmlParserOption
 *
 * Setup an xmltextReader to parse an XML document from I/O functions
 * and source.
 * The parsing flags @options are a combination of xmlParserOption.
 * This reuses the existing @reader xmlTextReader.
 *
 * Returns 0 in case of success and -1 in case of error
 */
int
xmlReaderNewIO(xmlTextReaderPtr reader, xmlInputReadCallback ioread,
               xmlInputCloseCallback ioclose, void *ioctx,
               const char *URL, const char *encoding, int options)
{
    xmlParserInputBufferPtr input;

    if (ioread == NULL)
        return (-1);
    if (reader == NULL)
        return (-1);

    input = xmlParserInputBufferCreateIO(ioread, ioclose, ioctx,
                                         XML_CHAR_ENCODING_NONE);
    if (input == NULL)
        return (-1);
    return (xmlTextReaderSetup(reader, input, URL, encoding, options));
}
/************************************************************************
 *									*
 *			Utilities					*
 *									*
 ************************************************************************/
#ifdef NOT_USED_YET

/**
 * xmlBase64Decode:
 * @in:  the input buffer
 * @inlen:  the size of the input (in), the size read from it (out)
 * @to:  the output buffer
 * @tolen:  the size of the output (in), the size written to (out)
 *
 * Base64 decoder, reads from @in and save in @to
 * TODO: tell jody when this is actually exported
 *
 * Returns 0 if all the input was consumer, 1 if the Base64 end was reached,
 *         2 if there wasn't enough space on the output or -1 in case of error.
 */
static int
xmlBase64Decode(const unsigned char *in, unsigned long *inlen,
                unsigned char *to, unsigned long *tolen)
{
    unsigned long incur;        /* current index in in[] */

    unsigned long inblk;        /* last block index in in[] */

    unsigned long outcur;       /* current index in out[] */

    unsigned long inmax;        /* size of in[] */

    unsigned long outmax;       /* size of out[] */

    unsigned char cur;          /* the current value read from in[] */

    unsigned char intmp[4], outtmp[4];  /* temporary buffers for the convert */

    int nbintmp;                /* number of byte in intmp[] */

    int is_ignore;              /* cur should be ignored */

    int is_end = 0;             /* the end of the base64 was found */

    int retval = 1;

    int i;

    if ((in == NULL) || (inlen == NULL) || (to == NULL) || (tolen == NULL))
        return (-1);

    incur = 0;
    inblk = 0;
    outcur = 0;
    inmax = *inlen;
    outmax = *tolen;
    nbintmp = 0;

    while (1) {
        if (incur >= inmax)
            break;
        cur = in[incur++];
        is_ignore = 0;
        if ((cur >= 'A') && (cur <= 'Z'))
            cur = cur - 'A';
        else if ((cur >= 'a') && (cur <= 'z'))
            cur = cur - 'a' + 26;
        else if ((cur >= '0') && (cur <= '9'))
            cur = cur - '0' + 52;
        else if (cur == '+')
            cur = 62;
        else if (cur == '/')
            cur = 63;
        else if (cur == '.')
            cur = 0;
        else if (cur == '=')    /*no op , end of the base64 stream */
            is_end = 1;
        else {
            is_ignore = 1;
            if (nbintmp == 0)
                inblk = incur;
        }

        if (!is_ignore) {
            int nbouttmp = 3;

            int is_break = 0;

            if (is_end) {
                if (nbintmp == 0)
                    break;
                if ((nbintmp == 1) || (nbintmp == 2))
                    nbouttmp = 1;
                else
                    nbouttmp = 2;
                nbintmp = 3;
                is_break = 1;
            }
            intmp[nbintmp++] = cur;
            /*
             * if intmp is full, push the 4byte sequence as a 3 byte
             * sequence out
             */
            if (nbintmp == 4) {
                nbintmp = 0;
                outtmp[0] = (intmp[0] << 2) | ((intmp[1] & 0x30) >> 4);
                outtmp[1] =
                    ((intmp[1] & 0x0F) << 4) | ((intmp[2] & 0x3C) >> 2);
                outtmp[2] = ((intmp[2] & 0x03) << 6) | (intmp[3] & 0x3F);
                if (outcur + 3 >= outmax) {
                    retval = 2;
                    break;
                }

                for (i = 0; i < nbouttmp; i++)
                    to[outcur++] = outtmp[i];
                inblk = incur;
            }

            if (is_break) {
                retval = 0;
                break;
            }
        }
    }

    *tolen = outcur;
    *inlen = inblk;
    return (retval);
}

/*
 * Test routine for the xmlBase64Decode function
 */
#if 0
int
main(int argc, char **argv)
{
    char *input = "  VW4 gcGV0        \n      aXQgdGVzdCAuCg== ";

    char output[100];

    char output2[100];

    char output3[100];

    unsigned long inlen = strlen(input);

    unsigned long outlen = 100;

    int ret;

    unsigned long cons, tmp, tmp2, prod;

    /*
     * Direct
     */
    ret = xmlBase64Decode(input, &inlen, output, &outlen);

    output[outlen] = 0;
    printf("ret: %d, inlen: %ld , outlen: %ld, output: '%s'\n", ret, inlen,
           outlen, output)indent: Standard input:179: Error:Unmatched #endif
;

    /*
     * output chunking
     */
    cons = 0;
    prod = 0;
    while (cons < inlen) {
        tmp = 5;
        tmp2 = inlen - cons;

        printf("%ld %ld\n", cons, prod);
        ret = xmlBase64Decode(&input[cons], &tmp2, &output2[prod], &tmp);
        cons += tmp2;
        prod += tmp;
        printf("%ld %ld\n", cons, prod);
    }
    output2[outlen] = 0;
    printf("ret: %d, cons: %ld , prod: %ld, output: '%s'\n", ret, cons,
           prod, output2);

    /*
     * input chunking
     */
    cons = 0;
    prod = 0;
    while (cons < inlen) {
        tmp = 100 - prod;
        tmp2 = inlen - cons;
        if (tmp2 > 5)
            tmp2 = 5;

        printf("%ld %ld\n", cons, prod);
        ret = xmlBase64Decode(&input[cons], &tmp2, &output3[prod], &tmp);
        cons += tmp2;
        prod += tmp;
        printf("%ld %ld\n", cons, prod);
    }
    output3[outlen] = 0;
    printf("ret: %d, cons: %ld , prod: %ld, output: '%s'\n", ret, cons,
           prod, output3);
    return (0);

}
#endif
#endif /* NOT_USED_YET */
#define bottom_xmlreader
#include "elfgcchack.h"
#endif /* LIBXML_READER_ENABLED */
