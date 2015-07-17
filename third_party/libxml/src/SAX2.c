/*
 * SAX2.c : Default SAX2 handler to build a tree.
 *
 * See Copyright for the status of this software.
 *
 * Daniel Veillard <daniel@veillard.com>
 */


#define IN_LIBXML
#include "libxml.h"
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <libxml/xmlmemory.h>
#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/valid.h>
#include <libxml/entities.h>
#include <libxml/xmlerror.h>
#include <libxml/debugXML.h>
#include <libxml/xmlIO.h>
#include <libxml/SAX.h>
#include <libxml/uri.h>
#include <libxml/valid.h>
#include <libxml/HTMLtree.h>
#include <libxml/globals.h>

/* Define SIZE_T_MAX unless defined through <limits.h>. */
#ifndef SIZE_T_MAX
# define SIZE_T_MAX     ((size_t)-1)
#endif /* !SIZE_T_MAX */

/* #define DEBUG_SAX2 */
/* #define DEBUG_SAX2_TREE */

/**
 * TODO:
 *
 * macro to flag unimplemented blocks
 * XML_CATALOG_PREFER user env to select between system/public prefered
 * option. C.f. Richard Tobin <richard@cogsci.ed.ac.uk>
 *> Just FYI, I am using an environment variable XML_CATALOG_PREFER with
 *> values "system" and "public".  I have made the default be "system" to
 *> match yours.
 */
#define TODO								\
    xmlGenericError(xmlGenericErrorContext,				\
	    "Unimplemented block at %s:%d\n",				\
            __FILE__, __LINE__);

/*
 * xmlSAX2ErrMemory:
 * @ctxt:  an XML validation parser context
 * @msg:   a string to accompany the error message
 */
static void
xmlSAX2ErrMemory(xmlParserCtxtPtr ctxt, const char *msg) {
    xmlStructuredErrorFunc schannel = NULL;
    const char *str1 = "out of memory\n";

    if (ctxt != NULL) {
	ctxt->errNo = XML_ERR_NO_MEMORY;
	if ((ctxt->sax != NULL) && (ctxt->sax->initialized == XML_SAX2_MAGIC))
	    schannel = ctxt->sax->serror;
	__xmlRaiseError(schannel,
			ctxt->vctxt.error, ctxt->vctxt.userData,
			ctxt, NULL, XML_FROM_PARSER, XML_ERR_NO_MEMORY,
			XML_ERR_ERROR, NULL, 0, (const char *) str1,
			NULL, NULL, 0, 0,
			msg, (const char *) str1, NULL);
	ctxt->errNo = XML_ERR_NO_MEMORY;
	ctxt->instate = XML_PARSER_EOF;
	ctxt->disableSAX = 1;
    } else {
	__xmlRaiseError(schannel,
			NULL, NULL,
			ctxt, NULL, XML_FROM_PARSER, XML_ERR_NO_MEMORY,
			XML_ERR_ERROR, NULL, 0, (const char *) str1,
			NULL, NULL, 0, 0,
			msg, (const char *) str1, NULL);
    }
}

/**
 * xmlValidError:
 * @ctxt:  an XML validation parser context
 * @error:  the error number
 * @msg:  the error message
 * @str1:  extra data
 * @str2:  extra data
 *
 * Handle a validation error
 */
static void
xmlErrValid(xmlParserCtxtPtr ctxt, xmlParserErrors error,
            const char *msg, const char *str1, const char *str2)
{
    xmlStructuredErrorFunc schannel = NULL;

    if ((ctxt != NULL) && (ctxt->disableSAX != 0) &&
        (ctxt->instate == XML_PARSER_EOF))
	return;
    if (ctxt != NULL) {
	ctxt->errNo = error;
	if ((ctxt->sax != NULL) && (ctxt->sax->initialized == XML_SAX2_MAGIC))
	    schannel = ctxt->sax->serror;
	__xmlRaiseError(schannel,
			ctxt->vctxt.error, ctxt->vctxt.userData,
			ctxt, NULL, XML_FROM_DTD, error,
			XML_ERR_ERROR, NULL, 0, (const char *) str1,
			(const char *) str2, NULL, 0, 0,
			msg, (const char *) str1, (const char *) str2);
	ctxt->valid = 0;
    } else {
	__xmlRaiseError(schannel,
			NULL, NULL,
			ctxt, NULL, XML_FROM_DTD, error,
			XML_ERR_ERROR, NULL, 0, (const char *) str1,
			(const char *) str2, NULL, 0, 0,
			msg, (const char *) str1, (const char *) str2);
    }
}

/**
 * xmlFatalErrMsg:
 * @ctxt:  an XML parser context
 * @error:  the error number
 * @msg:  the error message
 * @str1:  an error string
 * @str2:  an error string
 *
 * Handle a fatal parser error, i.e. violating Well-Formedness constraints
 */
static void
xmlFatalErrMsg(xmlParserCtxtPtr ctxt, xmlParserErrors error,
               const char *msg, const xmlChar *str1, const xmlChar *str2)
{
    if ((ctxt != NULL) && (ctxt->disableSAX != 0) &&
        (ctxt->instate == XML_PARSER_EOF))
	return;
    if (ctxt != NULL)
	ctxt->errNo = error;
    __xmlRaiseError(NULL, NULL, NULL, ctxt, NULL, XML_FROM_PARSER, error,
                    XML_ERR_FATAL, NULL, 0,
		    (const char *) str1, (const char *) str2,
		    NULL, 0, 0, msg, str1, str2);
    if (ctxt != NULL) {
	ctxt->wellFormed = 0;
	ctxt->valid = 0;
	if (ctxt->recovery == 0)
	    ctxt->disableSAX = 1;
    }
}

/**
 * xmlWarnMsg:
 * @ctxt:  an XML parser context
 * @error:  the error number
 * @msg:  the error message
 * @str1:  an error string
 * @str2:  an error string
 *
 * Handle a parser warning
 */
static void
xmlWarnMsg(xmlParserCtxtPtr ctxt, xmlParserErrors error,
               const char *msg, const xmlChar *str1)
{
    if ((ctxt != NULL) && (ctxt->disableSAX != 0) &&
        (ctxt->instate == XML_PARSER_EOF))
	return;
    if (ctxt != NULL)
	ctxt->errNo = error;
    __xmlRaiseError(NULL, NULL, NULL, ctxt, NULL, XML_FROM_PARSER, error,
                    XML_ERR_WARNING, NULL, 0,
		    (const char *) str1, NULL,
		    NULL, 0, 0, msg, str1);
}

/**
 * xmlNsErrMsg:
 * @ctxt:  an XML parser context
 * @error:  the error number
 * @msg:  the error message
 * @str1:  an error string
 * @str2:  an error string
 *
 * Handle a namespace error
 */
static void
xmlNsErrMsg(xmlParserCtxtPtr ctxt, xmlParserErrors error,
            const char *msg, const xmlChar *str1, const xmlChar *str2)
{
    if ((ctxt != NULL) && (ctxt->disableSAX != 0) &&
        (ctxt->instate == XML_PARSER_EOF))
	return;
    if (ctxt != NULL)
	ctxt->errNo = error;
    __xmlRaiseError(NULL, NULL, NULL, ctxt, NULL, XML_FROM_NAMESPACE, error,
                    XML_ERR_ERROR, NULL, 0,
		    (const char *) str1, (const char *) str2,
		    NULL, 0, 0, msg, str1, str2);
}

/**
 * xmlNsWarnMsg:
 * @ctxt:  an XML parser context
 * @error:  the error number
 * @msg:  the error message
 * @str1:  an error string
 *
 * Handle a namespace warning
 */
static void
xmlNsWarnMsg(xmlParserCtxtPtr ctxt, xmlParserErrors error,
             const char *msg, const xmlChar *str1, const xmlChar *str2)
{
    if ((ctxt != NULL) && (ctxt->disableSAX != 0) &&
        (ctxt->instate == XML_PARSER_EOF))
	return;
    if (ctxt != NULL)
	ctxt->errNo = error;
    __xmlRaiseError(NULL, NULL, NULL, ctxt, NULL, XML_FROM_NAMESPACE, error,
                    XML_ERR_WARNING, NULL, 0,
		    (const char *) str1, (const char *) str2,
		    NULL, 0, 0, msg, str1, str2);
}

/**
 * xmlSAX2GetPublicId:
 * @ctx: the user data (XML parser context)
 *
 * Provides the public ID e.g. "-//SGMLSOURCE//DTD DEMO//EN"
 *
 * Returns a xmlChar *
 */
const xmlChar *
xmlSAX2GetPublicId(void *ctx ATTRIBUTE_UNUSED)
{
    /* xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx; */
    return(NULL);
}

/**
 * xmlSAX2GetSystemId:
 * @ctx: the user data (XML parser context)
 *
 * Provides the system ID, basically URL or filename e.g.
 * http://www.sgmlsource.com/dtds/memo.dtd
 *
 * Returns a xmlChar *
 */
const xmlChar *
xmlSAX2GetSystemId(void *ctx)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    if ((ctx == NULL) || (ctxt->input == NULL)) return(NULL);
    return((const xmlChar *) ctxt->input->filename);
}

/**
 * xmlSAX2GetLineNumber:
 * @ctx: the user data (XML parser context)
 *
 * Provide the line number of the current parsing point.
 *
 * Returns an int
 */
int
xmlSAX2GetLineNumber(void *ctx)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    if ((ctx == NULL) || (ctxt->input == NULL)) return(0);
    return(ctxt->input->line);
}

/**
 * xmlSAX2GetColumnNumber:
 * @ctx: the user data (XML parser context)
 *
 * Provide the column number of the current parsing point.
 *
 * Returns an int
 */
int
xmlSAX2GetColumnNumber(void *ctx)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    if ((ctx == NULL) || (ctxt->input == NULL)) return(0);
    return(ctxt->input->col);
}

/**
 * xmlSAX2IsStandalone:
 * @ctx: the user data (XML parser context)
 *
 * Is this document tagged standalone ?
 *
 * Returns 1 if true
 */
int
xmlSAX2IsStandalone(void *ctx)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    if ((ctx == NULL) || (ctxt->myDoc == NULL)) return(0);
    return(ctxt->myDoc->standalone == 1);
}

/**
 * xmlSAX2HasInternalSubset:
 * @ctx: the user data (XML parser context)
 *
 * Does this document has an internal subset
 *
 * Returns 1 if true
 */
int
xmlSAX2HasInternalSubset(void *ctx)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    if ((ctxt == NULL) || (ctxt->myDoc == NULL)) return(0);
    return(ctxt->myDoc->intSubset != NULL);
}

/**
 * xmlSAX2HasExternalSubset:
 * @ctx: the user data (XML parser context)
 *
 * Does this document has an external subset
 *
 * Returns 1 if true
 */
int
xmlSAX2HasExternalSubset(void *ctx)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    if ((ctxt == NULL) || (ctxt->myDoc == NULL)) return(0);
    return(ctxt->myDoc->extSubset != NULL);
}

/**
 * xmlSAX2InternalSubset:
 * @ctx:  the user data (XML parser context)
 * @name:  the root element name
 * @ExternalID:  the external ID
 * @SystemID:  the SYSTEM ID (e.g. filename or URL)
 *
 * Callback on internal subset declaration.
 */
void
xmlSAX2InternalSubset(void *ctx, const xmlChar *name,
	       const xmlChar *ExternalID, const xmlChar *SystemID)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlDtdPtr dtd;
    if (ctx == NULL) return;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2InternalSubset(%s, %s, %s)\n",
            name, ExternalID, SystemID);
#endif

    if (ctxt->myDoc == NULL)
	return;
    dtd = xmlGetIntSubset(ctxt->myDoc);
    if (dtd != NULL) {
	if (ctxt->html)
	    return;
	xmlUnlinkNode((xmlNodePtr) dtd);
	xmlFreeDtd(dtd);
	ctxt->myDoc->intSubset = NULL;
    }
    ctxt->myDoc->intSubset =
	xmlCreateIntSubset(ctxt->myDoc, name, ExternalID, SystemID);
    if (ctxt->myDoc->intSubset == NULL)
        xmlSAX2ErrMemory(ctxt, "xmlSAX2InternalSubset");
}

/**
 * xmlSAX2ExternalSubset:
 * @ctx: the user data (XML parser context)
 * @name:  the root element name
 * @ExternalID:  the external ID
 * @SystemID:  the SYSTEM ID (e.g. filename or URL)
 *
 * Callback on external subset declaration.
 */
void
xmlSAX2ExternalSubset(void *ctx, const xmlChar *name,
	       const xmlChar *ExternalID, const xmlChar *SystemID)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    if (ctx == NULL) return;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2ExternalSubset(%s, %s, %s)\n",
            name, ExternalID, SystemID);
#endif
    if (((ExternalID != NULL) || (SystemID != NULL)) &&
        (((ctxt->validate) || (ctxt->loadsubset != 0)) &&
	 (ctxt->wellFormed && ctxt->myDoc))) {
	/*
	 * Try to fetch and parse the external subset.
	 */
	xmlParserInputPtr oldinput;
	int oldinputNr;
	int oldinputMax;
	xmlParserInputPtr *oldinputTab;
	xmlParserInputPtr input = NULL;
	xmlCharEncoding enc;
	int oldcharset;
	const xmlChar *oldencoding;

	/*
	 * Ask the Entity resolver to load the damn thing
	 */
	if ((ctxt->sax != NULL) && (ctxt->sax->resolveEntity != NULL))
	    input = ctxt->sax->resolveEntity(ctxt->userData, ExternalID,
	                                        SystemID);
	if (input == NULL) {
	    return;
	}

	xmlNewDtd(ctxt->myDoc, name, ExternalID, SystemID);

	/*
	 * make sure we won't destroy the main document context
	 */
	oldinput = ctxt->input;
	oldinputNr = ctxt->inputNr;
	oldinputMax = ctxt->inputMax;
	oldinputTab = ctxt->inputTab;
	oldcharset = ctxt->charset;
	oldencoding = ctxt->encoding;
	ctxt->encoding = NULL;

	ctxt->inputTab = (xmlParserInputPtr *)
	                 xmlMalloc(5 * sizeof(xmlParserInputPtr));
	if (ctxt->inputTab == NULL) {
	    xmlSAX2ErrMemory(ctxt, "xmlSAX2ExternalSubset");
	    ctxt->input = oldinput;
	    ctxt->inputNr = oldinputNr;
	    ctxt->inputMax = oldinputMax;
	    ctxt->inputTab = oldinputTab;
	    ctxt->charset = oldcharset;
	    ctxt->encoding = oldencoding;
	    return;
	}
	ctxt->inputNr = 0;
	ctxt->inputMax = 5;
	ctxt->input = NULL;
	xmlPushInput(ctxt, input);

	/*
	 * On the fly encoding conversion if needed
	 */
	if (ctxt->input->length >= 4) {
	    enc = xmlDetectCharEncoding(ctxt->input->cur, 4);
	    xmlSwitchEncoding(ctxt, enc);
	}

	if (input->filename == NULL)
	    input->filename = (char *) xmlCanonicPath(SystemID);
	input->line = 1;
	input->col = 1;
	input->base = ctxt->input->cur;
	input->cur = ctxt->input->cur;
	input->free = NULL;

	/*
	 * let's parse that entity knowing it's an external subset.
	 */
	xmlParseExternalSubset(ctxt, ExternalID, SystemID);

        /*
	 * Free up the external entities
	 */

	while (ctxt->inputNr > 1)
	    xmlPopInput(ctxt);
	xmlFreeInputStream(ctxt->input);
        xmlFree(ctxt->inputTab);

	/*
	 * Restore the parsing context of the main entity
	 */
	ctxt->input = oldinput;
	ctxt->inputNr = oldinputNr;
	ctxt->inputMax = oldinputMax;
	ctxt->inputTab = oldinputTab;
	ctxt->charset = oldcharset;
	if ((ctxt->encoding != NULL) &&
	    ((ctxt->dict == NULL) ||
	     (!xmlDictOwns(ctxt->dict, ctxt->encoding))))
	    xmlFree((xmlChar *) ctxt->encoding);
	ctxt->encoding = oldencoding;
	/* ctxt->wellFormed = oldwellFormed; */
    }
}

/**
 * xmlSAX2ResolveEntity:
 * @ctx: the user data (XML parser context)
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 *
 * The entity loader, to control the loading of external entities,
 * the application can either:
 *    - override this xmlSAX2ResolveEntity() callback in the SAX block
 *    - or better use the xmlSetExternalEntityLoader() function to
 *      set up it's own entity resolution routine
 *
 * Returns the xmlParserInputPtr if inlined or NULL for DOM behaviour.
 */
xmlParserInputPtr
xmlSAX2ResolveEntity(void *ctx, const xmlChar *publicId, const xmlChar *systemId)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlParserInputPtr ret;
    xmlChar *URI;
    const char *base = NULL;

    if (ctx == NULL) return(NULL);
    if (ctxt->input != NULL)
	base = ctxt->input->filename;
    if (base == NULL)
	base = ctxt->directory;

    URI = xmlBuildURI(systemId, (const xmlChar *) base);

#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2ResolveEntity(%s, %s)\n", publicId, systemId);
#endif

    ret = xmlLoadExternalEntity((const char *) URI,
				(const char *) publicId, ctxt);
    if (URI != NULL)
	xmlFree(URI);
    return(ret);
}

/**
 * xmlSAX2GetEntity:
 * @ctx: the user data (XML parser context)
 * @name: The entity name
 *
 * Get an entity by name
 *
 * Returns the xmlEntityPtr if found.
 */
xmlEntityPtr
xmlSAX2GetEntity(void *ctx, const xmlChar *name)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlEntityPtr ret = NULL;

    if (ctx == NULL) return(NULL);
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2GetEntity(%s)\n", name);
#endif

    if (ctxt->inSubset == 0) {
	ret = xmlGetPredefinedEntity(name);
	if (ret != NULL)
	    return(ret);
    }
    if ((ctxt->myDoc != NULL) && (ctxt->myDoc->standalone == 1)) {
	if (ctxt->inSubset == 2) {
	    ctxt->myDoc->standalone = 0;
	    ret = xmlGetDocEntity(ctxt->myDoc, name);
	    ctxt->myDoc->standalone = 1;
	} else {
	    ret = xmlGetDocEntity(ctxt->myDoc, name);
	    if (ret == NULL) {
		ctxt->myDoc->standalone = 0;
		ret = xmlGetDocEntity(ctxt->myDoc, name);
		if (ret != NULL) {
		    xmlFatalErrMsg(ctxt, XML_ERR_NOT_STANDALONE,
	 "Entity(%s) document marked standalone but requires external subset\n",
				   name, NULL);
		}
		ctxt->myDoc->standalone = 1;
	    }
	}
    } else {
	ret = xmlGetDocEntity(ctxt->myDoc, name);
    }
    if ((ret != NULL) &&
	((ctxt->validate) || (ctxt->replaceEntities)) &&
	(ret->children == NULL) &&
	(ret->etype == XML_EXTERNAL_GENERAL_PARSED_ENTITY)) {
	int val;

	/*
	 * for validation purposes we really need to fetch and
	 * parse the external entity
	 */
	xmlNodePtr children;
	unsigned long oldnbent = ctxt->nbentities;

        val = xmlParseCtxtExternalEntity(ctxt, ret->URI,
		                         ret->ExternalID, &children);
	if (val == 0) {
	    xmlAddChildList((xmlNodePtr) ret, children);
	} else {
	    xmlFatalErrMsg(ctxt, XML_ERR_ENTITY_PROCESSING,
		           "Failure to process entity %s\n", name, NULL);
	    ctxt->validate = 0;
	    return(NULL);
	}
	ret->owner = 1;
	if (ret->checked == 0) {
	    ret->checked = (ctxt->nbentities - oldnbent + 1) * 2;
	    if ((ret->content != NULL) && (xmlStrchr(ret->content, '<')))
	        ret->checked |= 1;
	}
    }
    return(ret);
}

/**
 * xmlSAX2GetParameterEntity:
 * @ctx: the user data (XML parser context)
 * @name: The entity name
 *
 * Get a parameter entity by name
 *
 * Returns the xmlEntityPtr if found.
 */
xmlEntityPtr
xmlSAX2GetParameterEntity(void *ctx, const xmlChar *name)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlEntityPtr ret;

    if (ctx == NULL) return(NULL);
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2GetParameterEntity(%s)\n", name);
#endif

    ret = xmlGetParameterEntity(ctxt->myDoc, name);
    return(ret);
}


/**
 * xmlSAX2EntityDecl:
 * @ctx: the user data (XML parser context)
 * @name:  the entity name
 * @type:  the entity type
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 * @content: the entity value (without processing).
 *
 * An entity definition has been parsed
 */
void
xmlSAX2EntityDecl(void *ctx, const xmlChar *name, int type,
          const xmlChar *publicId, const xmlChar *systemId, xmlChar *content)
{
    xmlEntityPtr ent;
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;

    if (ctx == NULL) return;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2EntityDecl(%s, %d, %s, %s, %s)\n",
            name, type, publicId, systemId, content);
#endif
    if (ctxt->inSubset == 1) {
	ent = xmlAddDocEntity(ctxt->myDoc, name, type, publicId,
		              systemId, content);
	if ((ent == NULL) && (ctxt->pedantic))
	    xmlWarnMsg(ctxt, XML_WAR_ENTITY_REDEFINED,
	     "Entity(%s) already defined in the internal subset\n",
	               name);
	if ((ent != NULL) && (ent->URI == NULL) && (systemId != NULL)) {
	    xmlChar *URI;
	    const char *base = NULL;

	    if (ctxt->input != NULL)
		base = ctxt->input->filename;
	    if (base == NULL)
		base = ctxt->directory;

	    URI = xmlBuildURI(systemId, (const xmlChar *) base);
	    ent->URI = URI;
	}
    } else if (ctxt->inSubset == 2) {
	ent = xmlAddDtdEntity(ctxt->myDoc, name, type, publicId,
		              systemId, content);
	if ((ent == NULL) && (ctxt->pedantic) &&
	    (ctxt->sax != NULL) && (ctxt->sax->warning != NULL))
	    ctxt->sax->warning(ctxt->userData,
	     "Entity(%s) already defined in the external subset\n", name);
	if ((ent != NULL) && (ent->URI == NULL) && (systemId != NULL)) {
	    xmlChar *URI;
	    const char *base = NULL;

	    if (ctxt->input != NULL)
		base = ctxt->input->filename;
	    if (base == NULL)
		base = ctxt->directory;

	    URI = xmlBuildURI(systemId, (const xmlChar *) base);
	    ent->URI = URI;
	}
    } else {
	xmlFatalErrMsg(ctxt, XML_ERR_ENTITY_PROCESSING,
	               "SAX.xmlSAX2EntityDecl(%s) called while not in subset\n",
		       name, NULL);
    }
}

/**
 * xmlSAX2AttributeDecl:
 * @ctx: the user data (XML parser context)
 * @elem:  the name of the element
 * @fullname:  the attribute name
 * @type:  the attribute type
 * @def:  the type of default value
 * @defaultValue: the attribute default value
 * @tree:  the tree of enumerated value set
 *
 * An attribute definition has been parsed
 */
void
xmlSAX2AttributeDecl(void *ctx, const xmlChar *elem, const xmlChar *fullname,
              int type, int def, const xmlChar *defaultValue,
	      xmlEnumerationPtr tree)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlAttributePtr attr;
    xmlChar *name = NULL, *prefix = NULL;

    if ((ctxt == NULL) || (ctxt->myDoc == NULL))
        return;

#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2AttributeDecl(%s, %s, %d, %d, %s, ...)\n",
            elem, fullname, type, def, defaultValue);
#endif
    if ((xmlStrEqual(fullname, BAD_CAST "xml:id")) &&
        (type != XML_ATTRIBUTE_ID)) {
	/*
	 * Raise the error but keep the validity flag
	 */
	int tmp = ctxt->valid;
	xmlErrValid(ctxt, XML_DTD_XMLID_TYPE,
	      "xml:id : attribute type should be ID\n", NULL, NULL);
	ctxt->valid = tmp;
    }
    /* TODO: optimize name/prefix allocation */
    name = xmlSplitQName(ctxt, fullname, &prefix);
    ctxt->vctxt.valid = 1;
    if (ctxt->inSubset == 1)
	attr = xmlAddAttributeDecl(&ctxt->vctxt, ctxt->myDoc->intSubset, elem,
	       name, prefix, (xmlAttributeType) type,
	       (xmlAttributeDefault) def, defaultValue, tree);
    else if (ctxt->inSubset == 2)
	attr = xmlAddAttributeDecl(&ctxt->vctxt, ctxt->myDoc->extSubset, elem,
	   name, prefix, (xmlAttributeType) type,
	   (xmlAttributeDefault) def, defaultValue, tree);
    else {
        xmlFatalErrMsg(ctxt, XML_ERR_INTERNAL_ERROR,
	     "SAX.xmlSAX2AttributeDecl(%s) called while not in subset\n",
	               name, NULL);
	xmlFreeEnumeration(tree);
	return;
    }
#ifdef LIBXML_VALID_ENABLED
    if (ctxt->vctxt.valid == 0)
	ctxt->valid = 0;
    if ((attr != NULL) && (ctxt->validate) && (ctxt->wellFormed) &&
        (ctxt->myDoc->intSubset != NULL))
	ctxt->valid &= xmlValidateAttributeDecl(&ctxt->vctxt, ctxt->myDoc,
	                                        attr);
#endif /* LIBXML_VALID_ENABLED */
    if (prefix != NULL)
	xmlFree(prefix);
    if (name != NULL)
	xmlFree(name);
}

/**
 * xmlSAX2ElementDecl:
 * @ctx: the user data (XML parser context)
 * @name:  the element name
 * @type:  the element type
 * @content: the element value tree
 *
 * An element definition has been parsed
 */
void
xmlSAX2ElementDecl(void *ctx, const xmlChar * name, int type,
            xmlElementContentPtr content)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlElementPtr elem = NULL;

    if ((ctxt == NULL) || (ctxt->myDoc == NULL))
        return;

#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
                    "SAX.xmlSAX2ElementDecl(%s, %d, ...)\n", name, type);
#endif

    if (ctxt->inSubset == 1)
        elem = xmlAddElementDecl(&ctxt->vctxt, ctxt->myDoc->intSubset,
                                 name, (xmlElementTypeVal) type, content);
    else if (ctxt->inSubset == 2)
        elem = xmlAddElementDecl(&ctxt->vctxt, ctxt->myDoc->extSubset,
                                 name, (xmlElementTypeVal) type, content);
    else {
        xmlFatalErrMsg(ctxt, XML_ERR_INTERNAL_ERROR,
	     "SAX.xmlSAX2ElementDecl(%s) called while not in subset\n",
	               name, NULL);
        return;
    }
#ifdef LIBXML_VALID_ENABLED
    if (elem == NULL)
        ctxt->valid = 0;
    if (ctxt->validate && ctxt->wellFormed &&
        ctxt->myDoc && ctxt->myDoc->intSubset)
        ctxt->valid &=
            xmlValidateElementDecl(&ctxt->vctxt, ctxt->myDoc, elem);
#endif /* LIBXML_VALID_ENABLED */
}

/**
 * xmlSAX2NotationDecl:
 * @ctx: the user data (XML parser context)
 * @name: The name of the notation
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 *
 * What to do when a notation declaration has been parsed.
 */
void
xmlSAX2NotationDecl(void *ctx, const xmlChar *name,
	     const xmlChar *publicId, const xmlChar *systemId)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlNotationPtr nota = NULL;

    if ((ctxt == NULL) || (ctxt->myDoc == NULL))
        return;

#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2NotationDecl(%s, %s, %s)\n", name, publicId, systemId);
#endif

    if ((publicId == NULL) && (systemId == NULL)) {
	xmlFatalErrMsg(ctxt, XML_ERR_NOTATION_PROCESSING,
	     "SAX.xmlSAX2NotationDecl(%s) externalID or PublicID missing\n",
	               name, NULL);
	return;
    } else if (ctxt->inSubset == 1)
	nota = xmlAddNotationDecl(&ctxt->vctxt, ctxt->myDoc->intSubset, name,
                              publicId, systemId);
    else if (ctxt->inSubset == 2)
	nota = xmlAddNotationDecl(&ctxt->vctxt, ctxt->myDoc->extSubset, name,
                              publicId, systemId);
    else {
	xmlFatalErrMsg(ctxt, XML_ERR_NOTATION_PROCESSING,
	     "SAX.xmlSAX2NotationDecl(%s) called while not in subset\n",
	               name, NULL);
	return;
    }
#ifdef LIBXML_VALID_ENABLED
    if (nota == NULL) ctxt->valid = 0;
    if ((ctxt->validate) && (ctxt->wellFormed) &&
        (ctxt->myDoc->intSubset != NULL))
	ctxt->valid &= xmlValidateNotationDecl(&ctxt->vctxt, ctxt->myDoc,
	                                       nota);
#endif /* LIBXML_VALID_ENABLED */
}

/**
 * xmlSAX2UnparsedEntityDecl:
 * @ctx: the user data (XML parser context)
 * @name: The name of the entity
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 * @notationName: the name of the notation
 *
 * What to do when an unparsed entity declaration is parsed
 */
void
xmlSAX2UnparsedEntityDecl(void *ctx, const xmlChar *name,
		   const xmlChar *publicId, const xmlChar *systemId,
		   const xmlChar *notationName)
{
    xmlEntityPtr ent;
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    if (ctx == NULL) return;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2UnparsedEntityDecl(%s, %s, %s, %s)\n",
            name, publicId, systemId, notationName);
#endif
    if (ctxt->inSubset == 1) {
	ent = xmlAddDocEntity(ctxt->myDoc, name,
			XML_EXTERNAL_GENERAL_UNPARSED_ENTITY,
			publicId, systemId, notationName);
	if ((ent == NULL) && (ctxt->pedantic) &&
	    (ctxt->sax != NULL) && (ctxt->sax->warning != NULL))
	    ctxt->sax->warning(ctxt->userData,
	     "Entity(%s) already defined in the internal subset\n", name);
	if ((ent != NULL) && (ent->URI == NULL) && (systemId != NULL)) {
	    xmlChar *URI;
	    const char *base = NULL;

	    if (ctxt->input != NULL)
		base = ctxt->input->filename;
	    if (base == NULL)
		base = ctxt->directory;

	    URI = xmlBuildURI(systemId, (const xmlChar *) base);
	    ent->URI = URI;
	}
    } else if (ctxt->inSubset == 2) {
	ent = xmlAddDtdEntity(ctxt->myDoc, name,
			XML_EXTERNAL_GENERAL_UNPARSED_ENTITY,
			publicId, systemId, notationName);
	if ((ent == NULL) && (ctxt->pedantic) &&
	    (ctxt->sax != NULL) && (ctxt->sax->warning != NULL))
	    ctxt->sax->warning(ctxt->userData,
	     "Entity(%s) already defined in the external subset\n", name);
	if ((ent != NULL) && (ent->URI == NULL) && (systemId != NULL)) {
	    xmlChar *URI;
	    const char *base = NULL;

	    if (ctxt->input != NULL)
		base = ctxt->input->filename;
	    if (base == NULL)
		base = ctxt->directory;

	    URI = xmlBuildURI(systemId, (const xmlChar *) base);
	    ent->URI = URI;
	}
    } else {
        xmlFatalErrMsg(ctxt, XML_ERR_INTERNAL_ERROR,
	     "SAX.xmlSAX2UnparsedEntityDecl(%s) called while not in subset\n",
	               name, NULL);
    }
}

/**
 * xmlSAX2SetDocumentLocator:
 * @ctx: the user data (XML parser context)
 * @loc: A SAX Locator
 *
 * Receive the document locator at startup, actually xmlDefaultSAXLocator
 * Everything is available on the context, so this is useless in our case.
 */
void
xmlSAX2SetDocumentLocator(void *ctx ATTRIBUTE_UNUSED, xmlSAXLocatorPtr loc ATTRIBUTE_UNUSED)
{
    /* xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx; */
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2SetDocumentLocator()\n");
#endif
}

/**
 * xmlSAX2StartDocument:
 * @ctx: the user data (XML parser context)
 *
 * called when the document start being processed.
 */
void
xmlSAX2StartDocument(void *ctx)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlDocPtr doc;

    if (ctx == NULL) return;

#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2StartDocument()\n");
#endif
    if (ctxt->html) {
#ifdef LIBXML_HTML_ENABLED
	if (ctxt->myDoc == NULL)
	    ctxt->myDoc = htmlNewDocNoDtD(NULL, NULL);
	if (ctxt->myDoc == NULL) {
	    xmlSAX2ErrMemory(ctxt, "xmlSAX2StartDocument");
	    return;
	}
	ctxt->myDoc->properties = XML_DOC_HTML;
	ctxt->myDoc->parseFlags = ctxt->options;
#else
        xmlGenericError(xmlGenericErrorContext,
		"libxml2 built without HTML support\n");
	ctxt->errNo = XML_ERR_INTERNAL_ERROR;
	ctxt->instate = XML_PARSER_EOF;
	ctxt->disableSAX = 1;
	return;
#endif
    } else {
	doc = ctxt->myDoc = xmlNewDoc(ctxt->version);
	if (doc != NULL) {
	    doc->properties = 0;
	    if (ctxt->options & XML_PARSE_OLD10)
	        doc->properties |= XML_DOC_OLD10;
	    doc->parseFlags = ctxt->options;
	    if (ctxt->encoding != NULL)
		doc->encoding = xmlStrdup(ctxt->encoding);
	    else
		doc->encoding = NULL;
	    doc->standalone = ctxt->standalone;
	} else {
	    xmlSAX2ErrMemory(ctxt, "xmlSAX2StartDocument");
	    return;
	}
	if ((ctxt->dictNames) && (doc != NULL)) {
	    doc->dict = ctxt->dict;
	    xmlDictReference(doc->dict);
	}
    }
    if ((ctxt->myDoc != NULL) && (ctxt->myDoc->URL == NULL) &&
	(ctxt->input != NULL) && (ctxt->input->filename != NULL)) {
	ctxt->myDoc->URL = xmlPathToURI((const xmlChar *)ctxt->input->filename);
	if (ctxt->myDoc->URL == NULL)
	    xmlSAX2ErrMemory(ctxt, "xmlSAX2StartDocument");
    }
}

/**
 * xmlSAX2EndDocument:
 * @ctx: the user data (XML parser context)
 *
 * called when the document end has been detected.
 */
void
xmlSAX2EndDocument(void *ctx)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2EndDocument()\n");
#endif
    if (ctx == NULL) return;
#ifdef LIBXML_VALID_ENABLED
    if (ctxt->validate && ctxt->wellFormed &&
        ctxt->myDoc && ctxt->myDoc->intSubset)
	ctxt->valid &= xmlValidateDocumentFinal(&ctxt->vctxt, ctxt->myDoc);
#endif /* LIBXML_VALID_ENABLED */

    /*
     * Grab the encoding if it was added on-the-fly
     */
    if ((ctxt->encoding != NULL) && (ctxt->myDoc != NULL) &&
	(ctxt->myDoc->encoding == NULL)) {
	ctxt->myDoc->encoding = ctxt->encoding;
	ctxt->encoding = NULL;
    }
    if ((ctxt->inputTab != NULL) &&
        (ctxt->inputNr > 0) && (ctxt->inputTab[0] != NULL) &&
        (ctxt->inputTab[0]->encoding != NULL) && (ctxt->myDoc != NULL) &&
	(ctxt->myDoc->encoding == NULL)) {
	ctxt->myDoc->encoding = xmlStrdup(ctxt->inputTab[0]->encoding);
    }
    if ((ctxt->charset != XML_CHAR_ENCODING_NONE) && (ctxt->myDoc != NULL) &&
	(ctxt->myDoc->charset == XML_CHAR_ENCODING_NONE)) {
	ctxt->myDoc->charset = ctxt->charset;
    }
}

#if defined(LIBXML_SAX1_ENABLED) || defined(LIBXML_HTML_ENABLED) || defined(LIBXML_WRITER_ENABLED) || defined(LIBXML_DOCB_ENABLED) || defined(LIBXML_LEGACY_ENABLED)
/**
 * xmlSAX2AttributeInternal:
 * @ctx: the user data (XML parser context)
 * @fullname:  The attribute name, including namespace prefix
 * @value:  The attribute value
 * @prefix: the prefix on the element node
 *
 * Handle an attribute that has been read by the parser.
 * The default handling is to convert the attribute into an
 * DOM subtree and past it in a new xmlAttr element added to
 * the element.
 */
static void
xmlSAX2AttributeInternal(void *ctx, const xmlChar *fullname,
             const xmlChar *value, const xmlChar *prefix ATTRIBUTE_UNUSED)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlAttrPtr ret;
    xmlChar *name;
    xmlChar *ns;
    xmlChar *nval;
    xmlNsPtr namespace;

    if (ctxt->html) {
	name = xmlStrdup(fullname);
	ns = NULL;
	namespace = NULL;
    } else {
	/*
	 * Split the full name into a namespace prefix and the tag name
	 */
	name = xmlSplitQName(ctxt, fullname, &ns);
	if ((name != NULL) && (name[0] == 0)) {
	    if (xmlStrEqual(ns, BAD_CAST "xmlns")) {
		xmlNsErrMsg(ctxt, XML_ERR_NS_DECL_ERROR,
			    "invalid namespace declaration '%s'\n",
			    fullname, NULL);
	    } else {
		xmlNsWarnMsg(ctxt, XML_WAR_NS_COLUMN,
			     "Avoid attribute ending with ':' like '%s'\n",
			     fullname, NULL);
	    }
	    if (ns != NULL)
		xmlFree(ns);
	    ns = NULL;
	    xmlFree(name);
	    name = xmlStrdup(fullname);
	}
    }
    if (name == NULL) {
        xmlSAX2ErrMemory(ctxt, "xmlSAX2StartElement");
	if (ns != NULL)
	    xmlFree(ns);
	return;
    }

#ifdef LIBXML_HTML_ENABLED
    if ((ctxt->html) &&
        (value == NULL) && (htmlIsBooleanAttr(fullname))) {
            nval = xmlStrdup(fullname);
            value = (const xmlChar *) nval;
    } else
#endif
    {
#ifdef LIBXML_VALID_ENABLED
        /*
         * Do the last stage of the attribute normalization
         * Needed for HTML too:
         *   http://www.w3.org/TR/html4/types.html#h-6.2
         */
        ctxt->vctxt.valid = 1;
        nval = xmlValidCtxtNormalizeAttributeValue(&ctxt->vctxt,
                                               ctxt->myDoc, ctxt->node,
                                               fullname, value);
        if (ctxt->vctxt.valid != 1) {
            ctxt->valid = 0;
        }
        if (nval != NULL)
            value = nval;
#else
        nval = NULL;
#endif /* LIBXML_VALID_ENABLED */
    }

    /*
     * Check whether it's a namespace definition
     */
    if ((!ctxt->html) && (ns == NULL) &&
        (name[0] == 'x') && (name[1] == 'm') && (name[2] == 'l') &&
        (name[3] == 'n') && (name[4] == 's') && (name[5] == 0)) {
	xmlNsPtr nsret;
	xmlChar *val;

        if (!ctxt->replaceEntities) {
	    ctxt->depth++;
	    val = xmlStringDecodeEntities(ctxt, value, XML_SUBSTITUTE_REF,
		                          0,0,0);
	    ctxt->depth--;
	    if (val == NULL) {
	        xmlSAX2ErrMemory(ctxt, "xmlSAX2StartElement");
		if (name != NULL)
		    xmlFree(name);
		return;
	    }
	} else {
	    val = (xmlChar *) value;
	}

	if (val[0] != 0) {
	    xmlURIPtr uri;

	    uri = xmlParseURI((const char *)val);
	    if (uri == NULL) {
		if ((ctxt->sax != NULL) && (ctxt->sax->warning != NULL))
		    ctxt->sax->warning(ctxt->userData,
			 "xmlns: %s not a valid URI\n", val);
	    } else {
		if (uri->scheme == NULL) {
		    if ((ctxt->sax != NULL) && (ctxt->sax->warning != NULL))
			ctxt->sax->warning(ctxt->userData,
			     "xmlns: URI %s is not absolute\n", val);
		}
		xmlFreeURI(uri);
	    }
	}

	/* a default namespace definition */
	nsret = xmlNewNs(ctxt->node, val, NULL);

#ifdef LIBXML_VALID_ENABLED
	/*
	 * Validate also for namespace decls, they are attributes from
	 * an XML-1.0 perspective
	 */
        if (nsret != NULL && ctxt->validate && ctxt->wellFormed &&
	    ctxt->myDoc && ctxt->myDoc->intSubset)
	    ctxt->valid &= xmlValidateOneNamespace(&ctxt->vctxt, ctxt->myDoc,
					   ctxt->node, prefix, nsret, val);
#endif /* LIBXML_VALID_ENABLED */
	if (name != NULL)
	    xmlFree(name);
	if (nval != NULL)
	    xmlFree(nval);
	if (val != value)
	    xmlFree(val);
	return;
    }
    if ((!ctxt->html) &&
	(ns != NULL) && (ns[0] == 'x') && (ns[1] == 'm') && (ns[2] == 'l') &&
        (ns[3] == 'n') && (ns[4] == 's') && (ns[5] == 0)) {
	xmlNsPtr nsret;
	xmlChar *val;

        if (!ctxt->replaceEntities) {
	    ctxt->depth++;
	    val = xmlStringDecodeEntities(ctxt, value, XML_SUBSTITUTE_REF,
		                          0,0,0);
	    ctxt->depth--;
	    if (val == NULL) {
	        xmlSAX2ErrMemory(ctxt, "xmlSAX2StartElement");
	        xmlFree(ns);
		if (name != NULL)
		    xmlFree(name);
		return;
	    }
	} else {
	    val = (xmlChar *) value;
	}

	if (val[0] == 0) {
	    xmlNsErrMsg(ctxt, XML_NS_ERR_EMPTY,
		        "Empty namespace name for prefix %s\n", name, NULL);
	}
	if ((ctxt->pedantic != 0) && (val[0] != 0)) {
	    xmlURIPtr uri;

	    uri = xmlParseURI((const char *)val);
	    if (uri == NULL) {
	        xmlNsWarnMsg(ctxt, XML_WAR_NS_URI,
			 "xmlns:%s: %s not a valid URI\n", name, value);
	    } else {
		if (uri->scheme == NULL) {
		    xmlNsWarnMsg(ctxt, XML_WAR_NS_URI_RELATIVE,
			   "xmlns:%s: URI %s is not absolute\n", name, value);
		}
		xmlFreeURI(uri);
	    }
	}

	/* a standard namespace definition */
	nsret = xmlNewNs(ctxt->node, val, name);
	xmlFree(ns);
#ifdef LIBXML_VALID_ENABLED
	/*
	 * Validate also for namespace decls, they are attributes from
	 * an XML-1.0 perspective
	 */
        if (nsret != NULL && ctxt->validate && ctxt->wellFormed &&
	    ctxt->myDoc && ctxt->myDoc->intSubset)
	    ctxt->valid &= xmlValidateOneNamespace(&ctxt->vctxt, ctxt->myDoc,
					   ctxt->node, prefix, nsret, value);
#endif /* LIBXML_VALID_ENABLED */
	if (name != NULL)
	    xmlFree(name);
	if (nval != NULL)
	    xmlFree(nval);
	if (val != value)
	    xmlFree(val);
	return;
    }

    if (ns != NULL) {
	namespace = xmlSearchNs(ctxt->myDoc, ctxt->node, ns);

	if (namespace == NULL) {
	    xmlNsErrMsg(ctxt, XML_NS_ERR_UNDEFINED_NAMESPACE,
		    "Namespace prefix %s of attribute %s is not defined\n",
		             ns, name);
	} else {
            xmlAttrPtr prop;

            prop = ctxt->node->properties;
            while (prop != NULL) {
                if (prop->ns != NULL) {
                    if ((xmlStrEqual(name, prop->name)) &&
                        ((namespace == prop->ns) ||
                         (xmlStrEqual(namespace->href, prop->ns->href)))) {
                            xmlNsErrMsg(ctxt, XML_ERR_ATTRIBUTE_REDEFINED,
                                    "Attribute %s in %s redefined\n",
                                             name, namespace->href);
                        ctxt->wellFormed = 0;
                        if (ctxt->recovery == 0) ctxt->disableSAX = 1;
                        goto error;
                    }
                }
                prop = prop->next;
            }
        }
    } else {
	namespace = NULL;
    }

    /* !!!!!! <a toto:arg="" xmlns:toto="http://toto.com"> */
    ret = xmlNewNsPropEatName(ctxt->node, namespace, name, NULL);

    if (ret != NULL) {
        if ((ctxt->replaceEntities == 0) && (!ctxt->html)) {
	    xmlNodePtr tmp;

	    ret->children = xmlStringGetNodeList(ctxt->myDoc, value);
	    tmp = ret->children;
	    while (tmp != NULL) {
		tmp->parent = (xmlNodePtr) ret;
		if (tmp->next == NULL)
		    ret->last = tmp;
		tmp = tmp->next;
	    }
	} else if (value != NULL) {
	    ret->children = xmlNewDocText(ctxt->myDoc, value);
	    ret->last = ret->children;
	    if (ret->children != NULL)
		ret->children->parent = (xmlNodePtr) ret;
	}
    }

#ifdef LIBXML_VALID_ENABLED
    if ((!ctxt->html) && ctxt->validate && ctxt->wellFormed &&
        ctxt->myDoc && ctxt->myDoc->intSubset) {

	/*
	 * If we don't substitute entities, the validation should be
	 * done on a value with replaced entities anyway.
	 */
        if (!ctxt->replaceEntities) {
	    xmlChar *val;

	    ctxt->depth++;
	    val = xmlStringDecodeEntities(ctxt, value, XML_SUBSTITUTE_REF,
		                          0,0,0);
	    ctxt->depth--;

	    if (val == NULL)
		ctxt->valid &= xmlValidateOneAttribute(&ctxt->vctxt,
				ctxt->myDoc, ctxt->node, ret, value);
	    else {
		xmlChar *nvalnorm;

		/*
		 * Do the last stage of the attribute normalization
		 * It need to be done twice ... it's an extra burden related
		 * to the ability to keep xmlSAX2References in attributes
		 */
		nvalnorm = xmlValidNormalizeAttributeValue(ctxt->myDoc,
					    ctxt->node, fullname, val);
		if (nvalnorm != NULL) {
		    xmlFree(val);
		    val = nvalnorm;
		}

		ctxt->valid &= xmlValidateOneAttribute(&ctxt->vctxt,
			        ctxt->myDoc, ctxt->node, ret, val);
                xmlFree(val);
	    }
	} else {
	    ctxt->valid &= xmlValidateOneAttribute(&ctxt->vctxt, ctxt->myDoc,
					       ctxt->node, ret, value);
	}
    } else
#endif /* LIBXML_VALID_ENABLED */
           if (((ctxt->loadsubset & XML_SKIP_IDS) == 0) &&
	       (((ctxt->replaceEntities == 0) && (ctxt->external != 2)) ||
	        ((ctxt->replaceEntities != 0) && (ctxt->inSubset == 0)))) {
        /*
	 * when validating, the ID registration is done at the attribute
	 * validation level. Otherwise we have to do specific handling here.
	 */
	if (xmlStrEqual(fullname, BAD_CAST "xml:id")) {
	    /*
	     * Add the xml:id value
	     *
	     * Open issue: normalization of the value.
	     */
	    if (xmlValidateNCName(value, 1) != 0) {
	        xmlErrValid(ctxt, XML_DTD_XMLID_VALUE,
		      "xml:id : attribute value %s is not an NCName\n",
			    (const char *) value, NULL);
	    }
	    xmlAddID(&ctxt->vctxt, ctxt->myDoc, value, ret);
	} else if (xmlIsID(ctxt->myDoc, ctxt->node, ret))
	    xmlAddID(&ctxt->vctxt, ctxt->myDoc, value, ret);
	else if (xmlIsRef(ctxt->myDoc, ctxt->node, ret))
	    xmlAddRef(&ctxt->vctxt, ctxt->myDoc, value, ret);
    }

error:
    if (nval != NULL)
	xmlFree(nval);
    if (ns != NULL)
	xmlFree(ns);
}

/*
 * xmlCheckDefaultedAttributes:
 *
 * Check defaulted attributes from the DTD
 */
static void
xmlCheckDefaultedAttributes(xmlParserCtxtPtr ctxt, const xmlChar *name,
	const xmlChar *prefix, const xmlChar **atts) {
    xmlElementPtr elemDecl;
    const xmlChar *att;
    int internal = 1;
    int i;

    elemDecl = xmlGetDtdQElementDesc(ctxt->myDoc->intSubset, name, prefix);
    if (elemDecl == NULL) {
	elemDecl = xmlGetDtdQElementDesc(ctxt->myDoc->extSubset, name, prefix);
	internal = 0;
    }

process_external_subset:

    if (elemDecl != NULL) {
	xmlAttributePtr attr = elemDecl->attributes;
	/*
	 * Check against defaulted attributes from the external subset
	 * if the document is stamped as standalone
	 */
	if ((ctxt->myDoc->standalone == 1) &&
	    (ctxt->myDoc->extSubset != NULL) &&
	    (ctxt->validate)) {
	    while (attr != NULL) {
		if ((attr->defaultValue != NULL) &&
		    (xmlGetDtdQAttrDesc(ctxt->myDoc->extSubset,
					attr->elem, attr->name,
					attr->prefix) == attr) &&
		    (xmlGetDtdQAttrDesc(ctxt->myDoc->intSubset,
					attr->elem, attr->name,
					attr->prefix) == NULL)) {
		    xmlChar *fulln;

		    if (attr->prefix != NULL) {
			fulln = xmlStrdup(attr->prefix);
			fulln = xmlStrcat(fulln, BAD_CAST ":");
			fulln = xmlStrcat(fulln, attr->name);
		    } else {
			fulln = xmlStrdup(attr->name);
		    }
                    if (fulln == NULL) {
                        xmlSAX2ErrMemory(ctxt, "xmlSAX2StartElement");
                        break;
                    }

		    /*
		     * Check that the attribute is not declared in the
		     * serialization
		     */
		    att = NULL;
		    if (atts != NULL) {
			i = 0;
			att = atts[i];
			while (att != NULL) {
			    if (xmlStrEqual(att, fulln))
				break;
			    i += 2;
			    att = atts[i];
			}
		    }
		    if (att == NULL) {
		        xmlErrValid(ctxt, XML_DTD_STANDALONE_DEFAULTED,
      "standalone: attribute %s on %s defaulted from external subset\n",
				    (const char *)fulln,
				    (const char *)attr->elem);
		    }
                    xmlFree(fulln);
		}
		attr = attr->nexth;
	    }
	}

	/*
	 * Actually insert defaulted values when needed
	 */
	attr = elemDecl->attributes;
	while (attr != NULL) {
	    /*
	     * Make sure that attributes redefinition occuring in the
	     * internal subset are not overriden by definitions in the
	     * external subset.
	     */
	    if (attr->defaultValue != NULL) {
		/*
		 * the element should be instantiated in the tree if:
		 *  - this is a namespace prefix
		 *  - the user required for completion in the tree
		 *    like XSLT
		 *  - there isn't already an attribute definition
		 *    in the internal subset overriding it.
		 */
		if (((attr->prefix != NULL) &&
		     (xmlStrEqual(attr->prefix, BAD_CAST "xmlns"))) ||
		    ((attr->prefix == NULL) &&
		     (xmlStrEqual(attr->name, BAD_CAST "xmlns"))) ||
		    (ctxt->loadsubset & XML_COMPLETE_ATTRS)) {
		    xmlAttributePtr tst;

		    tst = xmlGetDtdQAttrDesc(ctxt->myDoc->intSubset,
					     attr->elem, attr->name,
					     attr->prefix);
		    if ((tst == attr) || (tst == NULL)) {
		        xmlChar fn[50];
			xmlChar *fulln;

                        fulln = xmlBuildQName(attr->name, attr->prefix, fn, 50);
			if (fulln == NULL) {
			    xmlSAX2ErrMemory(ctxt, "xmlSAX2StartElement");
			    return;
			}

			/*
			 * Check that the attribute is not declared in the
			 * serialization
			 */
			att = NULL;
			if (atts != NULL) {
			    i = 0;
			    att = atts[i];
			    while (att != NULL) {
				if (xmlStrEqual(att, fulln))
				    break;
				i += 2;
				att = atts[i];
			    }
			}
			if (att == NULL) {
			    xmlSAX2AttributeInternal(ctxt, fulln,
						 attr->defaultValue, prefix);
			}
			if ((fulln != fn) && (fulln != attr->name))
			    xmlFree(fulln);
		    }
		}
	    }
	    attr = attr->nexth;
	}
	if (internal == 1) {
	    elemDecl = xmlGetDtdQElementDesc(ctxt->myDoc->extSubset,
		                             name, prefix);
	    internal = 0;
	    goto process_external_subset;
	}
    }
}

/**
 * xmlSAX2StartElement:
 * @ctx: the user data (XML parser context)
 * @fullname:  The element name, including namespace prefix
 * @atts:  An array of name/value attributes pairs, NULL terminated
 *
 * called when an opening tag has been processed.
 */
void
xmlSAX2StartElement(void *ctx, const xmlChar *fullname, const xmlChar **atts)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlNodePtr ret;
    xmlNodePtr parent;
    xmlNsPtr ns;
    xmlChar *name;
    xmlChar *prefix;
    const xmlChar *att;
    const xmlChar *value;
    int i;

    if ((ctx == NULL) || (fullname == NULL) || (ctxt->myDoc == NULL)) return;
    parent = ctxt->node;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2StartElement(%s)\n", fullname);
#endif

    /*
     * First check on validity:
     */
    if (ctxt->validate && (ctxt->myDoc->extSubset == NULL) &&
        ((ctxt->myDoc->intSubset == NULL) ||
	 ((ctxt->myDoc->intSubset->notations == NULL) &&
	  (ctxt->myDoc->intSubset->elements == NULL) &&
	  (ctxt->myDoc->intSubset->attributes == NULL) &&
	  (ctxt->myDoc->intSubset->entities == NULL)))) {
	xmlErrValid(ctxt, XML_ERR_NO_DTD,
	  "Validation failed: no DTD found !", NULL, NULL);
	ctxt->validate = 0;
    }


    /*
     * Split the full name into a namespace prefix and the tag name
     */
    name = xmlSplitQName(ctxt, fullname, &prefix);


    /*
     * Note : the namespace resolution is deferred until the end of the
     *        attributes parsing, since local namespace can be defined as
     *        an attribute at this level.
     */
    ret = xmlNewDocNodeEatName(ctxt->myDoc, NULL, name, NULL);
    if (ret == NULL) {
        if (prefix != NULL)
	    xmlFree(prefix);
	xmlSAX2ErrMemory(ctxt, "xmlSAX2StartElement");
        return;
    }
    if (ctxt->myDoc->children == NULL) {
#ifdef DEBUG_SAX_TREE
	xmlGenericError(xmlGenericErrorContext, "Setting %s as root\n", name);
#endif
        xmlAddChild((xmlNodePtr) ctxt->myDoc, (xmlNodePtr) ret);
    } else if (parent == NULL) {
        parent = ctxt->myDoc->children;
    }
    ctxt->nodemem = -1;
    if (ctxt->linenumbers) {
	if (ctxt->input != NULL) {
	    if (ctxt->input->line < 65535)
		ret->line = (short) ctxt->input->line;
	    else
	        ret->line = 65535;
	}
    }

    /*
     * We are parsing a new node.
     */
#ifdef DEBUG_SAX_TREE
    xmlGenericError(xmlGenericErrorContext, "pushing(%s)\n", name);
#endif
    nodePush(ctxt, ret);

    /*
     * Link the child element
     */
    if (parent != NULL) {
        if (parent->type == XML_ELEMENT_NODE) {
#ifdef DEBUG_SAX_TREE
	    xmlGenericError(xmlGenericErrorContext,
		    "adding child %s to %s\n", name, parent->name);
#endif
	    xmlAddChild(parent, ret);
	} else {
#ifdef DEBUG_SAX_TREE
	    xmlGenericError(xmlGenericErrorContext,
		    "adding sibling %s to ", name);
	    xmlDebugDumpOneNode(stderr, parent, 0);
#endif
	    xmlAddSibling(parent, ret);
	}
    }

    /*
     * Insert all the defaulted attributes from the DTD especially namespaces
     */
    if ((!ctxt->html) &&
	((ctxt->myDoc->intSubset != NULL) ||
	 (ctxt->myDoc->extSubset != NULL))) {
	xmlCheckDefaultedAttributes(ctxt, name, prefix, atts);
    }

    /*
     * process all the attributes whose name start with "xmlns"
     */
    if (atts != NULL) {
        i = 0;
	att = atts[i++];
	value = atts[i++];
	if (!ctxt->html) {
	    while ((att != NULL) && (value != NULL)) {
		if ((att[0] == 'x') && (att[1] == 'm') && (att[2] == 'l') &&
		    (att[3] == 'n') && (att[4] == 's'))
		    xmlSAX2AttributeInternal(ctxt, att, value, prefix);

		att = atts[i++];
		value = atts[i++];
	    }
	}
    }

    /*
     * Search the namespace, note that since the attributes have been
     * processed, the local namespaces are available.
     */
    ns = xmlSearchNs(ctxt->myDoc, ret, prefix);
    if ((ns == NULL) && (parent != NULL))
	ns = xmlSearchNs(ctxt->myDoc, parent, prefix);
    if ((prefix != NULL) && (ns == NULL)) {
	ns = xmlNewNs(ret, NULL, prefix);
	xmlNsWarnMsg(ctxt, XML_NS_ERR_UNDEFINED_NAMESPACE,
		     "Namespace prefix %s is not defined\n",
		     prefix, NULL);
    }

    /*
     * set the namespace node, making sure that if the default namspace
     * is unbound on a parent we simply kee it NULL
     */
    if ((ns != NULL) && (ns->href != NULL) &&
	((ns->href[0] != 0) || (ns->prefix != NULL)))
	xmlSetNs(ret, ns);

    /*
     * process all the other attributes
     */
    if (atts != NULL) {
        i = 0;
	att = atts[i++];
	value = atts[i++];
	if (ctxt->html) {
	    while (att != NULL) {
		xmlSAX2AttributeInternal(ctxt, att, value, NULL);
		att = atts[i++];
		value = atts[i++];
	    }
	} else {
	    while ((att != NULL) && (value != NULL)) {
		if ((att[0] != 'x') || (att[1] != 'm') || (att[2] != 'l') ||
		    (att[3] != 'n') || (att[4] != 's'))
		    xmlSAX2AttributeInternal(ctxt, att, value, NULL);

		/*
		 * Next ones
		 */
		att = atts[i++];
		value = atts[i++];
	    }
	}
    }

#ifdef LIBXML_VALID_ENABLED
    /*
     * If it's the Document root, finish the DTD validation and
     * check the document root element for validity
     */
    if ((ctxt->validate) && (ctxt->vctxt.finishDtd == XML_CTXT_FINISH_DTD_0)) {
	int chk;

	chk = xmlValidateDtdFinal(&ctxt->vctxt, ctxt->myDoc);
	if (chk <= 0)
	    ctxt->valid = 0;
	if (chk < 0)
	    ctxt->wellFormed = 0;
	ctxt->valid &= xmlValidateRoot(&ctxt->vctxt, ctxt->myDoc);
	ctxt->vctxt.finishDtd = XML_CTXT_FINISH_DTD_1;
    }
#endif /* LIBXML_VALID_ENABLED */

    if (prefix != NULL)
	xmlFree(prefix);

}

/**
 * xmlSAX2EndElement:
 * @ctx: the user data (XML parser context)
 * @name:  The element name
 *
 * called when the end of an element has been detected.
 */
void
xmlSAX2EndElement(void *ctx, const xmlChar *name ATTRIBUTE_UNUSED)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlNodePtr cur;

    if (ctx == NULL) return;
    cur = ctxt->node;
#ifdef DEBUG_SAX
    if (name == NULL)
        xmlGenericError(xmlGenericErrorContext, "SAX.xmlSAX2EndElement(NULL)\n");
    else
	xmlGenericError(xmlGenericErrorContext, "SAX.xmlSAX2EndElement(%s)\n", name);
#endif

    /* Capture end position and add node */
    if (cur != NULL && ctxt->record_info) {
      ctxt->nodeInfo->end_pos = ctxt->input->cur - ctxt->input->base;
      ctxt->nodeInfo->end_line = ctxt->input->line;
      ctxt->nodeInfo->node = cur;
      xmlParserAddNodeInfo(ctxt, ctxt->nodeInfo);
    }
    ctxt->nodemem = -1;

#ifdef LIBXML_VALID_ENABLED
    if (ctxt->validate && ctxt->wellFormed &&
        ctxt->myDoc && ctxt->myDoc->intSubset)
        ctxt->valid &= xmlValidateOneElement(&ctxt->vctxt, ctxt->myDoc,
					     cur);
#endif /* LIBXML_VALID_ENABLED */


    /*
     * end of parsing of this node.
     */
#ifdef DEBUG_SAX_TREE
    xmlGenericError(xmlGenericErrorContext, "popping(%s)\n", cur->name);
#endif
    nodePop(ctxt);
}
#endif /* LIBXML_SAX1_ENABLED || LIBXML_HTML_ENABLED || LIBXML_LEGACY_ENABLED */

/*
 * xmlSAX2TextNode:
 * @ctxt:  the parser context
 * @str:  the input string
 * @len: the string length
 *
 * Callback for a text node
 *
 * Returns the newly allocated string or NULL if not needed or error
 */
static xmlNodePtr
xmlSAX2TextNode(xmlParserCtxtPtr ctxt, const xmlChar *str, int len) {
    xmlNodePtr ret;
    const xmlChar *intern = NULL;

    /*
     * Allocate
     */
    if (ctxt->freeElems != NULL) {
	ret = ctxt->freeElems;
	ctxt->freeElems = ret->next;
	ctxt->freeElemsNr--;
    } else {
	ret = (xmlNodePtr) xmlMalloc(sizeof(xmlNode));
    }
    if (ret == NULL) {
        xmlErrMemory(ctxt, "xmlSAX2Characters");
	return(NULL);
    }
    memset(ret, 0, sizeof(xmlNode));
    /*
     * intern the formatting blanks found between tags, or the
     * very short strings
     */
    if (ctxt->dictNames) {
        xmlChar cur = str[len];

	if ((len < (int) (2 * sizeof(void *))) &&
	    (ctxt->options & XML_PARSE_COMPACT)) {
	    /* store the string in the node overriding properties and nsDef */
	    xmlChar *tmp = (xmlChar *) &(ret->properties);
	    memcpy(tmp, str, len);
	    tmp[len] = 0;
	    intern = tmp;
	} else if ((len <= 3) && ((cur == '"') || (cur == '\'') ||
	    ((cur == '<') && (str[len + 1] != '!')))) {
	    intern = xmlDictLookup(ctxt->dict, str, len);
	} else if (IS_BLANK_CH(*str) && (len < 60) && (cur == '<') &&
	           (str[len + 1] != '!')) {
	    int i;

	    for (i = 1;i < len;i++) {
		if (!IS_BLANK_CH(str[i])) goto skip;
	    }
	    intern = xmlDictLookup(ctxt->dict, str, len);
	}
    }
skip:
    ret->type = XML_TEXT_NODE;

    ret->name = xmlStringText;
    if (intern == NULL) {
	ret->content = xmlStrndup(str, len);
	if (ret->content == NULL) {
	    xmlSAX2ErrMemory(ctxt, "xmlSAX2TextNode");
	    xmlFree(ret);
	    return(NULL);
	}
    } else
	ret->content = (xmlChar *) intern;

    if (ctxt->linenumbers) {
	if (ctxt->input != NULL) {
	    if (ctxt->input->line < 65535)
		ret->line = (short) ctxt->input->line;
	    else {
	        ret->line = 65535;
		if (ctxt->options & XML_PARSE_BIG_LINES)
		    ret->psvi = (void *) (long) ctxt->input->line;
	    }
	}
    }

    if ((__xmlRegisterCallbacks) && (xmlRegisterNodeDefaultValue))
	xmlRegisterNodeDefaultValue(ret);
    return(ret);
}

#ifdef LIBXML_VALID_ENABLED
/*
 * xmlSAX2DecodeAttrEntities:
 * @ctxt:  the parser context
 * @str:  the input string
 * @len: the string length
 *
 * Remove the entities from an attribute value
 *
 * Returns the newly allocated string or NULL if not needed or error
 */
static xmlChar *
xmlSAX2DecodeAttrEntities(xmlParserCtxtPtr ctxt, const xmlChar *str,
                          const xmlChar *end) {
    const xmlChar *in;
    xmlChar *ret;

    in = str;
    while (in < end)
        if (*in++ == '&')
	    goto decode;
    return(NULL);
decode:
    ctxt->depth++;
    ret = xmlStringLenDecodeEntities(ctxt, str, end - str,
				     XML_SUBSTITUTE_REF, 0,0,0);
    ctxt->depth--;
    return(ret);
}
#endif /* LIBXML_VALID_ENABLED */

/**
 * xmlSAX2AttributeNs:
 * @ctx: the user data (XML parser context)
 * @localname:  the local name of the attribute
 * @prefix:  the attribute namespace prefix if available
 * @URI:  the attribute namespace name if available
 * @value:  Start of the attribute value
 * @valueend: end of the attribute value
 *
 * Handle an attribute that has been read by the parser.
 * The default handling is to convert the attribute into an
 * DOM subtree and past it in a new xmlAttr element added to
 * the element.
 */
static void
xmlSAX2AttributeNs(xmlParserCtxtPtr ctxt,
                   const xmlChar * localname,
                   const xmlChar * prefix,
		   const xmlChar * value,
		   const xmlChar * valueend)
{
    xmlAttrPtr ret;
    xmlNsPtr namespace = NULL;
    xmlChar *dup = NULL;

    /*
     * Note: if prefix == NULL, the attribute is not in the default namespace
     */
    if (prefix != NULL)
	namespace = xmlSearchNs(ctxt->myDoc, ctxt->node, prefix);

    /*
     * allocate the node
     */
    if (ctxt->freeAttrs != NULL) {
        ret = ctxt->freeAttrs;
	ctxt->freeAttrs = ret->next;
	ctxt->freeAttrsNr--;
	memset(ret, 0, sizeof(xmlAttr));
	ret->type = XML_ATTRIBUTE_NODE;

	ret->parent = ctxt->node;
	ret->doc = ctxt->myDoc;
	ret->ns = namespace;

	if (ctxt->dictNames)
	    ret->name = localname;
	else
	    ret->name = xmlStrdup(localname);

        /* link at the end to preserv order, TODO speed up with a last */
	if (ctxt->node->properties == NULL) {
	    ctxt->node->properties = ret;
	} else {
	    xmlAttrPtr prev = ctxt->node->properties;

	    while (prev->next != NULL) prev = prev->next;
	    prev->next = ret;
	    ret->prev = prev;
	}

	if ((__xmlRegisterCallbacks) && (xmlRegisterNodeDefaultValue))
	    xmlRegisterNodeDefaultValue((xmlNodePtr)ret);
    } else {
	if (ctxt->dictNames)
	    ret = xmlNewNsPropEatName(ctxt->node, namespace,
	                              (xmlChar *) localname, NULL);
	else
	    ret = xmlNewNsProp(ctxt->node, namespace, localname, NULL);
	if (ret == NULL) {
	    xmlErrMemory(ctxt, "xmlSAX2AttributeNs");
	    return;
	}
    }

    if ((ctxt->replaceEntities == 0) && (!ctxt->html)) {
	xmlNodePtr tmp;

	/*
	 * We know that if there is an entity reference, then
	 * the string has been dup'ed and terminates with 0
	 * otherwise with ' or "
	 */
	if (*valueend != 0) {
	    tmp = xmlSAX2TextNode(ctxt, value, valueend - value);
	    ret->children = tmp;
	    ret->last = tmp;
	    if (tmp != NULL) {
		tmp->doc = ret->doc;
		tmp->parent = (xmlNodePtr) ret;
	    }
	} else {
	    ret->children = xmlStringLenGetNodeList(ctxt->myDoc, value,
						    valueend - value);
	    tmp = ret->children;
	    while (tmp != NULL) {
	        tmp->doc = ret->doc;
		tmp->parent = (xmlNodePtr) ret;
		if (tmp->next == NULL)
		    ret->last = tmp;
		tmp = tmp->next;
	    }
	}
    } else if (value != NULL) {
	xmlNodePtr tmp;

	tmp = xmlSAX2TextNode(ctxt, value, valueend - value);
	ret->children = tmp;
	ret->last = tmp;
	if (tmp != NULL) {
	    tmp->doc = ret->doc;
	    tmp->parent = (xmlNodePtr) ret;
	}
    }

#ifdef LIBXML_VALID_ENABLED
    if ((!ctxt->html) && ctxt->validate && ctxt->wellFormed &&
        ctxt->myDoc && ctxt->myDoc->intSubset) {
	/*
	 * If we don't substitute entities, the validation should be
	 * done on a value with replaced entities anyway.
	 */
        if (!ctxt->replaceEntities) {
	    dup = xmlSAX2DecodeAttrEntities(ctxt, value, valueend);
	    if (dup == NULL) {
	        if (*valueend == 0) {
		    ctxt->valid &= xmlValidateOneAttribute(&ctxt->vctxt,
				    ctxt->myDoc, ctxt->node, ret, value);
		} else {
		    /*
		     * That should already be normalized.
		     * cheaper to finally allocate here than duplicate
		     * entry points in the full validation code
		     */
		    dup = xmlStrndup(value, valueend - value);

		    ctxt->valid &= xmlValidateOneAttribute(&ctxt->vctxt,
				    ctxt->myDoc, ctxt->node, ret, dup);
		}
	    } else {
	        /*
		 * dup now contains a string of the flattened attribute
		 * content with entities substitued. Check if we need to
		 * apply an extra layer of normalization.
		 * It need to be done twice ... it's an extra burden related
		 * to the ability to keep references in attributes
		 */
		if (ctxt->attsSpecial != NULL) {
		    xmlChar *nvalnorm;
		    xmlChar fn[50];
		    xmlChar *fullname;

		    fullname = xmlBuildQName(localname, prefix, fn, 50);
		    if (fullname != NULL) {
			ctxt->vctxt.valid = 1;
		        nvalnorm = xmlValidCtxtNormalizeAttributeValue(
			                 &ctxt->vctxt, ctxt->myDoc,
					 ctxt->node, fullname, dup);
			if (ctxt->vctxt.valid != 1)
			    ctxt->valid = 0;

			if ((fullname != fn) && (fullname != localname))
			    xmlFree(fullname);
			if (nvalnorm != NULL) {
			    xmlFree(dup);
			    dup = nvalnorm;
			}
		    }
		}

		ctxt->valid &= xmlValidateOneAttribute(&ctxt->vctxt,
			        ctxt->myDoc, ctxt->node, ret, dup);
	    }
	} else {
	    /*
	     * if entities already have been substitued, then
	     * the attribute as passed is already normalized
	     */
	    dup = xmlStrndup(value, valueend - value);

	    ctxt->valid &= xmlValidateOneAttribute(&ctxt->vctxt,
	                             ctxt->myDoc, ctxt->node, ret, dup);
	}
    } else
#endif /* LIBXML_VALID_ENABLED */
           if (((ctxt->loadsubset & XML_SKIP_IDS) == 0) &&
	       (((ctxt->replaceEntities == 0) && (ctxt->external != 2)) ||
	        ((ctxt->replaceEntities != 0) && (ctxt->inSubset == 0)))) {
        /*
	 * when validating, the ID registration is done at the attribute
	 * validation level. Otherwise we have to do specific handling here.
	 */
        if ((prefix == ctxt->str_xml) &&
	           (localname[0] == 'i') && (localname[1] == 'd') &&
		   (localname[2] == 0)) {
	    /*
	     * Add the xml:id value
	     *
	     * Open issue: normalization of the value.
	     */
	    if (dup == NULL)
	        dup = xmlStrndup(value, valueend - value);
#if defined(LIBXML_SAX1_ENABLED) || defined(LIBXML_HTML_ENABLED) || defined(LIBXML_WRITER_ENABLED) || defined(LIBXML_DOCB_ENABLED) || defined(LIBXML_LEGACY_ENABLED)
#ifdef LIBXML_VALID_ENABLED
	    if (xmlValidateNCName(dup, 1) != 0) {
	        xmlErrValid(ctxt, XML_DTD_XMLID_VALUE,
		      "xml:id : attribute value %s is not an NCName\n",
			    (const char *) dup, NULL);
	    }
#endif
#endif
	    xmlAddID(&ctxt->vctxt, ctxt->myDoc, dup, ret);
	} else if (xmlIsID(ctxt->myDoc, ctxt->node, ret)) {
	    /* might be worth duplicate entry points and not copy */
	    if (dup == NULL)
	        dup = xmlStrndup(value, valueend - value);
	    xmlAddID(&ctxt->vctxt, ctxt->myDoc, dup, ret);
	} else if (xmlIsRef(ctxt->myDoc, ctxt->node, ret)) {
	    if (dup == NULL)
	        dup = xmlStrndup(value, valueend - value);
	    xmlAddRef(&ctxt->vctxt, ctxt->myDoc, dup, ret);
	}
    }
    if (dup != NULL)
	xmlFree(dup);
}

/**
 * xmlSAX2StartElementNs:
 * @ctx:  the user data (XML parser context)
 * @localname:  the local name of the element
 * @prefix:  the element namespace prefix if available
 * @URI:  the element namespace name if available
 * @nb_namespaces:  number of namespace definitions on that node
 * @namespaces:  pointer to the array of prefix/URI pairs namespace definitions
 * @nb_attributes:  the number of attributes on that node
 * @nb_defaulted:  the number of defaulted attributes.
 * @attributes:  pointer to the array of (localname/prefix/URI/value/end)
 *               attribute values.
 *
 * SAX2 callback when an element start has been detected by the parser.
 * It provides the namespace informations for the element, as well as
 * the new namespace declarations on the element.
 */
void
xmlSAX2StartElementNs(void *ctx,
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
    xmlNodePtr ret;
    xmlNodePtr parent;
    xmlNsPtr last = NULL, ns;
    const xmlChar *uri, *pref;
    xmlChar *lname = NULL;
    int i, j;

    if (ctx == NULL) return;
    parent = ctxt->node;
    /*
     * First check on validity:
     */
    if (ctxt->validate && (ctxt->myDoc->extSubset == NULL) &&
        ((ctxt->myDoc->intSubset == NULL) ||
	 ((ctxt->myDoc->intSubset->notations == NULL) &&
	  (ctxt->myDoc->intSubset->elements == NULL) &&
	  (ctxt->myDoc->intSubset->attributes == NULL) &&
	  (ctxt->myDoc->intSubset->entities == NULL)))) {
	xmlErrValid(ctxt, XML_DTD_NO_DTD,
	  "Validation failed: no DTD found !", NULL, NULL);
	ctxt->validate = 0;
    }

    /*
     * Take care of the rare case of an undefined namespace prefix
     */
    if ((prefix != NULL) && (URI == NULL)) {
        if (ctxt->dictNames) {
	    const xmlChar *fullname;

	    fullname = xmlDictQLookup(ctxt->dict, prefix, localname);
	    if (fullname != NULL)
	        localname = fullname;
	} else {
	    lname = xmlBuildQName(localname, prefix, NULL, 0);
	}
    }
    /*
     * allocate the node
     */
    if (ctxt->freeElems != NULL) {
        ret = ctxt->freeElems;
	ctxt->freeElems = ret->next;
	ctxt->freeElemsNr--;
	memset(ret, 0, sizeof(xmlNode));
	ret->type = XML_ELEMENT_NODE;

	if (ctxt->dictNames)
	    ret->name = localname;
	else {
	    if (lname == NULL)
		ret->name = xmlStrdup(localname);
	    else
	        ret->name = lname;
	    if (ret->name == NULL) {
	        xmlSAX2ErrMemory(ctxt, "xmlSAX2StartElementNs");
		return;
	    }
	}
	if ((__xmlRegisterCallbacks) && (xmlRegisterNodeDefaultValue))
	    xmlRegisterNodeDefaultValue(ret);
    } else {
	if (ctxt->dictNames)
	    ret = xmlNewDocNodeEatName(ctxt->myDoc, NULL,
	                               (xmlChar *) localname, NULL);
	else if (lname == NULL)
	    ret = xmlNewDocNode(ctxt->myDoc, NULL, localname, NULL);
	else
	    ret = xmlNewDocNodeEatName(ctxt->myDoc, NULL,
	                               (xmlChar *) lname, NULL);
	if (ret == NULL) {
	    xmlSAX2ErrMemory(ctxt, "xmlSAX2StartElementNs");
	    return;
	}
    }
    if (ctxt->linenumbers) {
	if (ctxt->input != NULL) {
	    if (ctxt->input->line < 65535)
		ret->line = (short) ctxt->input->line;
	    else
	        ret->line = 65535;
	}
    }

    if (parent == NULL) {
        xmlAddChild((xmlNodePtr) ctxt->myDoc, (xmlNodePtr) ret);
    }
    /*
     * Build the namespace list
     */
    for (i = 0,j = 0;j < nb_namespaces;j++) {
        pref = namespaces[i++];
	uri = namespaces[i++];
	ns = xmlNewNs(NULL, uri, pref);
	if (ns != NULL) {
	    if (last == NULL) {
	        ret->nsDef = last = ns;
	    } else {
	        last->next = ns;
		last = ns;
	    }
	    if ((URI != NULL) && (prefix == pref))
		ret->ns = ns;
	} else {
            /*
             * any out of memory error would already have been raised
             * but we can't be garanteed it's the actual error due to the
             * API, best is to skip in this case
             */
	    continue;
	}
#ifdef LIBXML_VALID_ENABLED
	if ((!ctxt->html) && ctxt->validate && ctxt->wellFormed &&
	    ctxt->myDoc && ctxt->myDoc->intSubset) {
	    ctxt->valid &= xmlValidateOneNamespace(&ctxt->vctxt, ctxt->myDoc,
	                                           ret, prefix, ns, uri);
	}
#endif /* LIBXML_VALID_ENABLED */
    }
    ctxt->nodemem = -1;

    /*
     * We are parsing a new node.
     */
    nodePush(ctxt, ret);

    /*
     * Link the child element
     */
    if (parent != NULL) {
        if (parent->type == XML_ELEMENT_NODE) {
	    xmlAddChild(parent, ret);
	} else {
	    xmlAddSibling(parent, ret);
	}
    }

    /*
     * Insert the defaulted attributes from the DTD only if requested:
     */
    if ((nb_defaulted != 0) &&
        ((ctxt->loadsubset & XML_COMPLETE_ATTRS) == 0))
	nb_attributes -= nb_defaulted;

    /*
     * Search the namespace if it wasn't already found
     * Note that, if prefix is NULL, this searches for the default Ns
     */
    if ((URI != NULL) && (ret->ns == NULL)) {
        ret->ns = xmlSearchNs(ctxt->myDoc, parent, prefix);
	if ((ret->ns == NULL) && (xmlStrEqual(prefix, BAD_CAST "xml"))) {
	    ret->ns = xmlSearchNs(ctxt->myDoc, ret, prefix);
	}
	if (ret->ns == NULL) {
	    ns = xmlNewNs(ret, NULL, prefix);
	    if (ns == NULL) {

	        xmlSAX2ErrMemory(ctxt, "xmlSAX2StartElementNs");
		return;
	    }
            if (prefix != NULL)
                xmlNsWarnMsg(ctxt, XML_NS_ERR_UNDEFINED_NAMESPACE,
                             "Namespace prefix %s was not found\n",
                             prefix, NULL);
            else
                xmlNsWarnMsg(ctxt, XML_NS_ERR_UNDEFINED_NAMESPACE,
                             "Namespace default prefix was not found\n",
                             NULL, NULL);
	}
    }

    /*
     * process all the other attributes
     */
    if (nb_attributes > 0) {
        for (j = 0,i = 0;i < nb_attributes;i++,j+=5) {
	    /*
	     * Handle the rare case of an undefined atribute prefix
	     */
	    if ((attributes[j+1] != NULL) && (attributes[j+2] == NULL)) {
		if (ctxt->dictNames) {
		    const xmlChar *fullname;

		    fullname = xmlDictQLookup(ctxt->dict, attributes[j+1],
		                              attributes[j]);
		    if (fullname != NULL) {
			xmlSAX2AttributeNs(ctxt, fullname, NULL,
			                   attributes[j+3], attributes[j+4]);
		        continue;
		    }
		} else {
		    lname = xmlBuildQName(attributes[j], attributes[j+1],
		                          NULL, 0);
		    if (lname != NULL) {
			xmlSAX2AttributeNs(ctxt, lname, NULL,
			                   attributes[j+3], attributes[j+4]);
			xmlFree(lname);
		        continue;
		    }
		}
	    }
	    xmlSAX2AttributeNs(ctxt, attributes[j], attributes[j+1],
			       attributes[j+3], attributes[j+4]);
	}
    }

#ifdef LIBXML_VALID_ENABLED
    /*
     * If it's the Document root, finish the DTD validation and
     * check the document root element for validity
     */
    if ((ctxt->validate) && (ctxt->vctxt.finishDtd == XML_CTXT_FINISH_DTD_0)) {
	int chk;

	chk = xmlValidateDtdFinal(&ctxt->vctxt, ctxt->myDoc);
	if (chk <= 0)
	    ctxt->valid = 0;
	if (chk < 0)
	    ctxt->wellFormed = 0;
	ctxt->valid &= xmlValidateRoot(&ctxt->vctxt, ctxt->myDoc);
	ctxt->vctxt.finishDtd = XML_CTXT_FINISH_DTD_1;
    }
#endif /* LIBXML_VALID_ENABLED */
}

/**
 * xmlSAX2EndElementNs:
 * @ctx:  the user data (XML parser context)
 * @localname:  the local name of the element
 * @prefix:  the element namespace prefix if available
 * @URI:  the element namespace name if available
 *
 * SAX2 callback when an element end has been detected by the parser.
 * It provides the namespace informations for the element.
 */
void
xmlSAX2EndElementNs(void *ctx,
                    const xmlChar * localname ATTRIBUTE_UNUSED,
                    const xmlChar * prefix ATTRIBUTE_UNUSED,
		    const xmlChar * URI ATTRIBUTE_UNUSED)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlParserNodeInfo node_info;
    xmlNodePtr cur;

    if (ctx == NULL) return;
    cur = ctxt->node;
    /* Capture end position and add node */
    if ((ctxt->record_info) && (cur != NULL)) {
        node_info.end_pos = ctxt->input->cur - ctxt->input->base;
        node_info.end_line = ctxt->input->line;
        node_info.node = cur;
        xmlParserAddNodeInfo(ctxt, &node_info);
    }
    ctxt->nodemem = -1;

#ifdef LIBXML_VALID_ENABLED
    if (ctxt->validate && ctxt->wellFormed &&
        ctxt->myDoc && ctxt->myDoc->intSubset)
        ctxt->valid &= xmlValidateOneElement(&ctxt->vctxt, ctxt->myDoc, cur);
#endif /* LIBXML_VALID_ENABLED */

    /*
     * end of parsing of this node.
     */
    nodePop(ctxt);
}

/**
 * xmlSAX2Reference:
 * @ctx: the user data (XML parser context)
 * @name:  The entity name
 *
 * called when an entity xmlSAX2Reference is detected.
 */
void
xmlSAX2Reference(void *ctx, const xmlChar *name)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlNodePtr ret;

    if (ctx == NULL) return;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2Reference(%s)\n", name);
#endif
    if (name[0] == '#')
	ret = xmlNewCharRef(ctxt->myDoc, name);
    else
	ret = xmlNewReference(ctxt->myDoc, name);
#ifdef DEBUG_SAX_TREE
    xmlGenericError(xmlGenericErrorContext,
	    "add xmlSAX2Reference %s to %s \n", name, ctxt->node->name);
#endif
    if (xmlAddChild(ctxt->node, ret) == NULL) {
        xmlFreeNode(ret);
    }
}

/**
 * xmlSAX2Characters:
 * @ctx: the user data (XML parser context)
 * @ch:  a xmlChar string
 * @len: the number of xmlChar
 *
 * receiving some chars from the parser.
 */
void
xmlSAX2Characters(void *ctx, const xmlChar *ch, int len)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlNodePtr lastChild;

    if (ctx == NULL) return;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2Characters(%.30s, %d)\n", ch, len);
#endif
    /*
     * Handle the data if any. If there is no child
     * add it as content, otherwise if the last child is text,
     * concatenate it, else create a new node of type text.
     */

    if (ctxt->node == NULL) {
#ifdef DEBUG_SAX_TREE
	xmlGenericError(xmlGenericErrorContext,
		"add chars: ctxt->node == NULL !\n");
#endif
        return;
    }
    lastChild = ctxt->node->last;
#ifdef DEBUG_SAX_TREE
    xmlGenericError(xmlGenericErrorContext,
	    "add chars to %s \n", ctxt->node->name);
#endif

    /*
     * Here we needed an accelerator mechanism in case of very large
     * elements. Use an attribute in the structure !!!
     */
    if (lastChild == NULL) {
        lastChild = xmlSAX2TextNode(ctxt, ch, len);
	if (lastChild != NULL) {
	    ctxt->node->children = lastChild;
	    ctxt->node->last = lastChild;
	    lastChild->parent = ctxt->node;
	    lastChild->doc = ctxt->node->doc;
	    ctxt->nodelen = len;
	    ctxt->nodemem = len + 1;
	} else {
	    xmlSAX2ErrMemory(ctxt, "xmlSAX2Characters");
	    return;
	}
    } else {
	int coalesceText = (lastChild != NULL) &&
	    (lastChild->type == XML_TEXT_NODE) &&
	    (lastChild->name == xmlStringText);
	if ((coalesceText) && (ctxt->nodemem != 0)) {
	    /*
	     * The whole point of maintaining nodelen and nodemem,
	     * xmlTextConcat is too costly, i.e. compute length,
	     * reallocate a new buffer, move data, append ch. Here
	     * We try to minimaze realloc() uses and avoid copying
	     * and recomputing length over and over.
	     */
	    if (lastChild->content == (xmlChar *)&(lastChild->properties)) {
		lastChild->content = xmlStrdup(lastChild->content);
		lastChild->properties = NULL;
	    } else if ((ctxt->nodemem == ctxt->nodelen + 1) &&
	               (xmlDictOwns(ctxt->dict, lastChild->content))) {
		lastChild->content = xmlStrdup(lastChild->content);
	    }
	    if (lastChild->content == NULL) {
		xmlSAX2ErrMemory(ctxt, "xmlSAX2Characters: xmlStrdup returned NULL");
		return;
 	    }
            if (((size_t)ctxt->nodelen + (size_t)len > XML_MAX_TEXT_LENGTH) &&
                ((ctxt->options & XML_PARSE_HUGE) == 0)) {
                xmlSAX2ErrMemory(ctxt, "xmlSAX2Characters: huge text node");
                return;
            }
	    if ((size_t)ctxt->nodelen > SIZE_T_MAX - (size_t)len ||
	        (size_t)ctxt->nodemem + (size_t)len > SIZE_T_MAX / 2) {
                xmlSAX2ErrMemory(ctxt, "xmlSAX2Characters overflow prevented");
                return;
	    }
	    if (ctxt->nodelen + len >= ctxt->nodemem) {
		xmlChar *newbuf;
		size_t size;

		size = ctxt->nodemem + len;
		size *= 2;
                newbuf = (xmlChar *) xmlRealloc(lastChild->content,size);
		if (newbuf == NULL) {
		    xmlSAX2ErrMemory(ctxt, "xmlSAX2Characters");
		    return;
		}
		ctxt->nodemem = size;
		lastChild->content = newbuf;
	    }
	    memcpy(&lastChild->content[ctxt->nodelen], ch, len);
	    ctxt->nodelen += len;
	    lastChild->content[ctxt->nodelen] = 0;
	} else if (coalesceText) {
	    if (xmlTextConcat(lastChild, ch, len)) {
		xmlSAX2ErrMemory(ctxt, "xmlSAX2Characters");
	    }
	    if (ctxt->node->children != NULL) {
		ctxt->nodelen = xmlStrlen(lastChild->content);
		ctxt->nodemem = ctxt->nodelen + 1;
	    }
	} else {
	    /* Mixed content, first time */
	    lastChild = xmlSAX2TextNode(ctxt, ch, len);
	    if (lastChild != NULL) {
		xmlAddChild(ctxt->node, lastChild);
		if (ctxt->node->children != NULL) {
		    ctxt->nodelen = len;
		    ctxt->nodemem = len + 1;
		}
	    }
	}
    }
}

/**
 * xmlSAX2IgnorableWhitespace:
 * @ctx: the user data (XML parser context)
 * @ch:  a xmlChar string
 * @len: the number of xmlChar
 *
 * receiving some ignorable whitespaces from the parser.
 * UNUSED: by default the DOM building will use xmlSAX2Characters
 */
void
xmlSAX2IgnorableWhitespace(void *ctx ATTRIBUTE_UNUSED, const xmlChar *ch ATTRIBUTE_UNUSED, int len ATTRIBUTE_UNUSED)
{
    /* xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx; */
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2IgnorableWhitespace(%.30s, %d)\n", ch, len);
#endif
}

/**
 * xmlSAX2ProcessingInstruction:
 * @ctx: the user data (XML parser context)
 * @target:  the target name
 * @data: the PI data's
 *
 * A processing instruction has been parsed.
 */
void
xmlSAX2ProcessingInstruction(void *ctx, const xmlChar *target,
                      const xmlChar *data)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlNodePtr ret;
    xmlNodePtr parent;

    if (ctx == NULL) return;
    parent = ctxt->node;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.xmlSAX2ProcessingInstruction(%s, %s)\n", target, data);
#endif

    ret = xmlNewDocPI(ctxt->myDoc, target, data);
    if (ret == NULL) return;

    if (ctxt->linenumbers) {
	if (ctxt->input != NULL) {
	    if (ctxt->input->line < 65535)
		ret->line = (short) ctxt->input->line;
	    else
	        ret->line = 65535;
	}
    }
    if (ctxt->inSubset == 1) {
	xmlAddChild((xmlNodePtr) ctxt->myDoc->intSubset, ret);
	return;
    } else if (ctxt->inSubset == 2) {
	xmlAddChild((xmlNodePtr) ctxt->myDoc->extSubset, ret);
	return;
    }
    if (parent == NULL) {
#ifdef DEBUG_SAX_TREE
	    xmlGenericError(xmlGenericErrorContext,
		    "Setting PI %s as root\n", target);
#endif
        xmlAddChild((xmlNodePtr) ctxt->myDoc, (xmlNodePtr) ret);
	return;
    }
    if (parent->type == XML_ELEMENT_NODE) {
#ifdef DEBUG_SAX_TREE
	xmlGenericError(xmlGenericErrorContext,
		"adding PI %s child to %s\n", target, parent->name);
#endif
	xmlAddChild(parent, ret);
    } else {
#ifdef DEBUG_SAX_TREE
	xmlGenericError(xmlGenericErrorContext,
		"adding PI %s sibling to ", target);
	xmlDebugDumpOneNode(stderr, parent, 0);
#endif
	xmlAddSibling(parent, ret);
    }
}

/**
 * xmlSAX2Comment:
 * @ctx: the user data (XML parser context)
 * @value:  the xmlSAX2Comment content
 *
 * A xmlSAX2Comment has been parsed.
 */
void
xmlSAX2Comment(void *ctx, const xmlChar *value)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlNodePtr ret;
    xmlNodePtr parent;

    if (ctx == NULL) return;
    parent = ctxt->node;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext, "SAX.xmlSAX2Comment(%s)\n", value);
#endif
    ret = xmlNewDocComment(ctxt->myDoc, value);
    if (ret == NULL) return;
    if (ctxt->linenumbers) {
	if (ctxt->input != NULL) {
	    if (ctxt->input->line < 65535)
		ret->line = (short) ctxt->input->line;
	    else
	        ret->line = 65535;
	}
    }

    if (ctxt->inSubset == 1) {
	xmlAddChild((xmlNodePtr) ctxt->myDoc->intSubset, ret);
	return;
    } else if (ctxt->inSubset == 2) {
	xmlAddChild((xmlNodePtr) ctxt->myDoc->extSubset, ret);
	return;
    }
    if (parent == NULL) {
#ifdef DEBUG_SAX_TREE
	    xmlGenericError(xmlGenericErrorContext,
		    "Setting xmlSAX2Comment as root\n");
#endif
        xmlAddChild((xmlNodePtr) ctxt->myDoc, (xmlNodePtr) ret);
	return;
    }
    if (parent->type == XML_ELEMENT_NODE) {
#ifdef DEBUG_SAX_TREE
	xmlGenericError(xmlGenericErrorContext,
		"adding xmlSAX2Comment child to %s\n", parent->name);
#endif
	xmlAddChild(parent, ret);
    } else {
#ifdef DEBUG_SAX_TREE
	xmlGenericError(xmlGenericErrorContext,
		"adding xmlSAX2Comment sibling to ");
	xmlDebugDumpOneNode(stderr, parent, 0);
#endif
	xmlAddSibling(parent, ret);
    }
}

/**
 * xmlSAX2CDataBlock:
 * @ctx: the user data (XML parser context)
 * @value:  The pcdata content
 * @len:  the block length
 *
 * called when a pcdata block has been parsed
 */
void
xmlSAX2CDataBlock(void *ctx, const xmlChar *value, int len)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlNodePtr ret, lastChild;

    if (ctx == NULL) return;
#ifdef DEBUG_SAX
    xmlGenericError(xmlGenericErrorContext,
	    "SAX.pcdata(%.10s, %d)\n", value, len);
#endif
    lastChild = xmlGetLastChild(ctxt->node);
#ifdef DEBUG_SAX_TREE
    xmlGenericError(xmlGenericErrorContext,
	    "add chars to %s \n", ctxt->node->name);
#endif
    if ((lastChild != NULL) &&
        (lastChild->type == XML_CDATA_SECTION_NODE)) {
	xmlTextConcat(lastChild, value, len);
    } else {
	ret = xmlNewCDataBlock(ctxt->myDoc, value, len);
	xmlAddChild(ctxt->node, ret);
    }
}

static int xmlSAX2DefaultVersionValue = 2;

#ifdef LIBXML_SAX1_ENABLED
/**
 * xmlSAXDefaultVersion:
 * @version:  the version, 1 or 2
 *
 * Set the default version of SAX used globally by the library.
 * By default, during initialization the default is set to 2.
 * Note that it is generally a better coding style to use
 * xmlSAXVersion() to set up the version explicitly for a given
 * parsing context.
 *
 * Returns the previous value in case of success and -1 in case of error.
 */
int
xmlSAXDefaultVersion(int version)
{
    int ret = xmlSAX2DefaultVersionValue;

    if ((version != 1) && (version != 2))
        return(-1);
    xmlSAX2DefaultVersionValue = version;
    return(ret);
}
#endif /* LIBXML_SAX1_ENABLED */

/**
 * xmlSAXVersion:
 * @hdlr:  the SAX handler
 * @version:  the version, 1 or 2
 *
 * Initialize the default XML SAX handler according to the version
 *
 * Returns 0 in case of success and -1 in case of error.
 */
int
xmlSAXVersion(xmlSAXHandler *hdlr, int version)
{
    if (hdlr == NULL) return(-1);
    if (version == 2) {
	hdlr->startElement = NULL;
	hdlr->endElement = NULL;
	hdlr->startElementNs = xmlSAX2StartElementNs;
	hdlr->endElementNs = xmlSAX2EndElementNs;
	hdlr->serror = NULL;
	hdlr->initialized = XML_SAX2_MAGIC;
#ifdef LIBXML_SAX1_ENABLED
    } else if (version == 1) {
	hdlr->startElement = xmlSAX2StartElement;
	hdlr->endElement = xmlSAX2EndElement;
	hdlr->initialized = 1;
#endif /* LIBXML_SAX1_ENABLED */
    } else
        return(-1);
    hdlr->internalSubset = xmlSAX2InternalSubset;
    hdlr->externalSubset = xmlSAX2ExternalSubset;
    hdlr->isStandalone = xmlSAX2IsStandalone;
    hdlr->hasInternalSubset = xmlSAX2HasInternalSubset;
    hdlr->hasExternalSubset = xmlSAX2HasExternalSubset;
    hdlr->resolveEntity = xmlSAX2ResolveEntity;
    hdlr->getEntity = xmlSAX2GetEntity;
    hdlr->getParameterEntity = xmlSAX2GetParameterEntity;
    hdlr->entityDecl = xmlSAX2EntityDecl;
    hdlr->attributeDecl = xmlSAX2AttributeDecl;
    hdlr->elementDecl = xmlSAX2ElementDecl;
    hdlr->notationDecl = xmlSAX2NotationDecl;
    hdlr->unparsedEntityDecl = xmlSAX2UnparsedEntityDecl;
    hdlr->setDocumentLocator = xmlSAX2SetDocumentLocator;
    hdlr->startDocument = xmlSAX2StartDocument;
    hdlr->endDocument = xmlSAX2EndDocument;
    hdlr->reference = xmlSAX2Reference;
    hdlr->characters = xmlSAX2Characters;
    hdlr->cdataBlock = xmlSAX2CDataBlock;
    hdlr->ignorableWhitespace = xmlSAX2Characters;
    hdlr->processingInstruction = xmlSAX2ProcessingInstruction;
    hdlr->comment = xmlSAX2Comment;
    hdlr->warning = xmlParserWarning;
    hdlr->error = xmlParserError;
    hdlr->fatalError = xmlParserError;

    return(0);
}

/**
 * xmlSAX2InitDefaultSAXHandler:
 * @hdlr:  the SAX handler
 * @warning:  flag if non-zero sets the handler warning procedure
 *
 * Initialize the default XML SAX2 handler
 */
void
xmlSAX2InitDefaultSAXHandler(xmlSAXHandler *hdlr, int warning)
{
    if ((hdlr == NULL) || (hdlr->initialized != 0))
	return;

    xmlSAXVersion(hdlr, xmlSAX2DefaultVersionValue);
    if (warning == 0)
	hdlr->warning = NULL;
    else
	hdlr->warning = xmlParserWarning;
}

/**
 * xmlDefaultSAXHandlerInit:
 *
 * Initialize the default SAX2 handler
 */
void
xmlDefaultSAXHandlerInit(void)
{
#ifdef LIBXML_SAX1_ENABLED
    xmlSAXVersion((xmlSAXHandlerPtr) &xmlDefaultSAXHandler, 1);
#endif /* LIBXML_SAX1_ENABLED */
}

#ifdef LIBXML_HTML_ENABLED

/**
 * xmlSAX2InitHtmlDefaultSAXHandler:
 * @hdlr:  the SAX handler
 *
 * Initialize the default HTML SAX2 handler
 */
void
xmlSAX2InitHtmlDefaultSAXHandler(xmlSAXHandler *hdlr)
{
    if ((hdlr == NULL) || (hdlr->initialized != 0))
	return;

    hdlr->internalSubset = xmlSAX2InternalSubset;
    hdlr->externalSubset = NULL;
    hdlr->isStandalone = NULL;
    hdlr->hasInternalSubset = NULL;
    hdlr->hasExternalSubset = NULL;
    hdlr->resolveEntity = NULL;
    hdlr->getEntity = xmlSAX2GetEntity;
    hdlr->getParameterEntity = NULL;
    hdlr->entityDecl = NULL;
    hdlr->attributeDecl = NULL;
    hdlr->elementDecl = NULL;
    hdlr->notationDecl = NULL;
    hdlr->unparsedEntityDecl = NULL;
    hdlr->setDocumentLocator = xmlSAX2SetDocumentLocator;
    hdlr->startDocument = xmlSAX2StartDocument;
    hdlr->endDocument = xmlSAX2EndDocument;
    hdlr->startElement = xmlSAX2StartElement;
    hdlr->endElement = xmlSAX2EndElement;
    hdlr->reference = NULL;
    hdlr->characters = xmlSAX2Characters;
    hdlr->cdataBlock = xmlSAX2CDataBlock;
    hdlr->ignorableWhitespace = xmlSAX2IgnorableWhitespace;
    hdlr->processingInstruction = xmlSAX2ProcessingInstruction;
    hdlr->comment = xmlSAX2Comment;
    hdlr->warning = xmlParserWarning;
    hdlr->error = xmlParserError;
    hdlr->fatalError = xmlParserError;

    hdlr->initialized = 1;
}

/**
 * htmlDefaultSAXHandlerInit:
 *
 * Initialize the default SAX handler
 */
void
htmlDefaultSAXHandlerInit(void)
{
    xmlSAX2InitHtmlDefaultSAXHandler((xmlSAXHandlerPtr) &htmlDefaultSAXHandler);
}

#endif /* LIBXML_HTML_ENABLED */

#ifdef LIBXML_DOCB_ENABLED

/**
 * xmlSAX2InitDocbDefaultSAXHandler:
 * @hdlr:  the SAX handler
 *
 * Initialize the default DocBook SAX2 handler
 */
void
xmlSAX2InitDocbDefaultSAXHandler(xmlSAXHandler *hdlr)
{
    if ((hdlr == NULL) || (hdlr->initialized != 0))
	return;

    hdlr->internalSubset = xmlSAX2InternalSubset;
    hdlr->externalSubset = NULL;
    hdlr->isStandalone = xmlSAX2IsStandalone;
    hdlr->hasInternalSubset = xmlSAX2HasInternalSubset;
    hdlr->hasExternalSubset = xmlSAX2HasExternalSubset;
    hdlr->resolveEntity = xmlSAX2ResolveEntity;
    hdlr->getEntity = xmlSAX2GetEntity;
    hdlr->getParameterEntity = NULL;
    hdlr->entityDecl = xmlSAX2EntityDecl;
    hdlr->attributeDecl = NULL;
    hdlr->elementDecl = NULL;
    hdlr->notationDecl = NULL;
    hdlr->unparsedEntityDecl = NULL;
    hdlr->setDocumentLocator = xmlSAX2SetDocumentLocator;
    hdlr->startDocument = xmlSAX2StartDocument;
    hdlr->endDocument = xmlSAX2EndDocument;
    hdlr->startElement = xmlSAX2StartElement;
    hdlr->endElement = xmlSAX2EndElement;
    hdlr->reference = xmlSAX2Reference;
    hdlr->characters = xmlSAX2Characters;
    hdlr->cdataBlock = NULL;
    hdlr->ignorableWhitespace = xmlSAX2IgnorableWhitespace;
    hdlr->processingInstruction = NULL;
    hdlr->comment = xmlSAX2Comment;
    hdlr->warning = xmlParserWarning;
    hdlr->error = xmlParserError;
    hdlr->fatalError = xmlParserError;

    hdlr->initialized = 1;
}

/**
 * docbDefaultSAXHandlerInit:
 *
 * Initialize the default SAX handler
 */
void
docbDefaultSAXHandlerInit(void)
{
    xmlSAX2InitDocbDefaultSAXHandler((xmlSAXHandlerPtr) &docbDefaultSAXHandler);
}

#endif /* LIBXML_DOCB_ENABLED */
#define bottom_SAX2
#include "elfgcchack.h"
