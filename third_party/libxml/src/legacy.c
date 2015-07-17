/*
 * legacy.c: set of deprecated routines, not to be used anymore but
 *           kept purely for ABI compatibility
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 */

#define IN_LIBXML
#include "libxml.h"

#ifdef LIBXML_LEGACY_ENABLED
#include <string.h>

#include <libxml/tree.h>
#include <libxml/entities.h>
#include <libxml/SAX.h>
#include <libxml/parserInternals.h>
#include <libxml/HTMLparser.h>

void xmlUpgradeOldNs(xmlDocPtr doc);

/************************************************************************
 *									*
 *		Deprecated functions kept for compatibility		*
 *									*
 ************************************************************************/

#ifdef LIBXML_HTML_ENABLED
xmlChar *htmlDecodeEntities(htmlParserCtxtPtr ctxt, int len, xmlChar end,
                            xmlChar end2, xmlChar end3);

/**
 * htmlDecodeEntities:
 * @ctxt:  the parser context
 * @len:  the len to decode (in bytes !), -1 for no size limit
 * @end:  an end marker xmlChar, 0 if none
 * @end2:  an end marker xmlChar, 0 if none
 * @end3:  an end marker xmlChar, 0 if none
 *
 * Substitute the HTML entities by their value
 *
 * DEPRECATED !!!!
 *
 * Returns A newly allocated string with the substitution done. The caller
 *      must deallocate it !
 */
xmlChar *
htmlDecodeEntities(htmlParserCtxtPtr ctxt ATTRIBUTE_UNUSED,
                   int len ATTRIBUTE_UNUSED, xmlChar end ATTRIBUTE_UNUSED,
                   xmlChar end2 ATTRIBUTE_UNUSED,
                   xmlChar end3 ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "htmlDecodeEntities() deprecated function reached\n");
        deprecated = 1;
    }
    return (NULL);
}
#endif

/**
 * xmlInitializePredefinedEntities:
 *
 * Set up the predefined entities.
 * Deprecated call
 */
void
xmlInitializePredefinedEntities(void)
{
}

/**
 * xmlCleanupPredefinedEntities:
 *
 * Cleanup up the predefined entities table.
 * Deprecated call
 */
void
xmlCleanupPredefinedEntities(void)
{
}

static const char *xmlFeaturesList[] = {
    "validate",
    "load subset",
    "keep blanks",
    "disable SAX",
    "fetch external entities",
    "substitute entities",
    "gather line info",
    "user data",
    "is html",
    "is standalone",
    "stop parser",
    "document",
    "is well formed",
    "is valid",
    "SAX block",
    "SAX function internalSubset",
    "SAX function isStandalone",
    "SAX function hasInternalSubset",
    "SAX function hasExternalSubset",
    "SAX function resolveEntity",
    "SAX function getEntity",
    "SAX function entityDecl",
    "SAX function notationDecl",
    "SAX function attributeDecl",
    "SAX function elementDecl",
    "SAX function unparsedEntityDecl",
    "SAX function setDocumentLocator",
    "SAX function startDocument",
    "SAX function endDocument",
    "SAX function startElement",
    "SAX function endElement",
    "SAX function reference",
    "SAX function characters",
    "SAX function ignorableWhitespace",
    "SAX function processingInstruction",
    "SAX function comment",
    "SAX function warning",
    "SAX function error",
    "SAX function fatalError",
    "SAX function getParameterEntity",
    "SAX function cdataBlock",
    "SAX function externalSubset",
};

/**
 * xmlGetFeaturesList:
 * @len:  the length of the features name array (input/output)
 * @result:  an array of string to be filled with the features name.
 *
 * Copy at most *@len feature names into the @result array
 *
 * Returns -1 in case or error, or the total number of features,
 *            len is updated with the number of strings copied,
 *            strings must not be deallocated
 */
int
xmlGetFeaturesList(int *len, const char **result)
{
    int ret, i;

    ret = sizeof(xmlFeaturesList) / sizeof(xmlFeaturesList[0]);
    if ((len == NULL) || (result == NULL))
        return (ret);
    if ((*len < 0) || (*len >= 1000))
        return (-1);
    if (*len > ret)
        *len = ret;
    for (i = 0; i < *len; i++)
        result[i] = xmlFeaturesList[i];
    return (ret);
}

/**
 * xmlGetFeature:
 * @ctxt:  an XML/HTML parser context
 * @name:  the feature name
 * @result:  location to store the result
 *
 * Read the current value of one feature of this parser instance
 *
 * Returns -1 in case or error, 0 otherwise
 */
int
xmlGetFeature(xmlParserCtxtPtr ctxt, const char *name, void *result)
{
    if ((ctxt == NULL) || (name == NULL) || (result == NULL))
        return (-1);

    if (!strcmp(name, "validate")) {
        *((int *) result) = ctxt->validate;
    } else if (!strcmp(name, "keep blanks")) {
        *((int *) result) = ctxt->keepBlanks;
    } else if (!strcmp(name, "disable SAX")) {
        *((int *) result) = ctxt->disableSAX;
    } else if (!strcmp(name, "fetch external entities")) {
        *((int *) result) = ctxt->loadsubset;
    } else if (!strcmp(name, "substitute entities")) {
        *((int *) result) = ctxt->replaceEntities;
    } else if (!strcmp(name, "gather line info")) {
        *((int *) result) = ctxt->record_info;
    } else if (!strcmp(name, "user data")) {
        *((void **) result) = ctxt->userData;
    } else if (!strcmp(name, "is html")) {
        *((int *) result) = ctxt->html;
    } else if (!strcmp(name, "is standalone")) {
        *((int *) result) = ctxt->standalone;
    } else if (!strcmp(name, "document")) {
        *((xmlDocPtr *) result) = ctxt->myDoc;
    } else if (!strcmp(name, "is well formed")) {
        *((int *) result) = ctxt->wellFormed;
    } else if (!strcmp(name, "is valid")) {
        *((int *) result) = ctxt->valid;
    } else if (!strcmp(name, "SAX block")) {
        *((xmlSAXHandlerPtr *) result) = ctxt->sax;
    } else if (!strcmp(name, "SAX function internalSubset")) {
        *((internalSubsetSAXFunc *) result) = ctxt->sax->internalSubset;
    } else if (!strcmp(name, "SAX function isStandalone")) {
        *((isStandaloneSAXFunc *) result) = ctxt->sax->isStandalone;
    } else if (!strcmp(name, "SAX function hasInternalSubset")) {
        *((hasInternalSubsetSAXFunc *) result) =
            ctxt->sax->hasInternalSubset;
    } else if (!strcmp(name, "SAX function hasExternalSubset")) {
        *((hasExternalSubsetSAXFunc *) result) =
            ctxt->sax->hasExternalSubset;
    } else if (!strcmp(name, "SAX function resolveEntity")) {
        *((resolveEntitySAXFunc *) result) = ctxt->sax->resolveEntity;
    } else if (!strcmp(name, "SAX function getEntity")) {
        *((getEntitySAXFunc *) result) = ctxt->sax->getEntity;
    } else if (!strcmp(name, "SAX function entityDecl")) {
        *((entityDeclSAXFunc *) result) = ctxt->sax->entityDecl;
    } else if (!strcmp(name, "SAX function notationDecl")) {
        *((notationDeclSAXFunc *) result) = ctxt->sax->notationDecl;
    } else if (!strcmp(name, "SAX function attributeDecl")) {
        *((attributeDeclSAXFunc *) result) = ctxt->sax->attributeDecl;
    } else if (!strcmp(name, "SAX function elementDecl")) {
        *((elementDeclSAXFunc *) result) = ctxt->sax->elementDecl;
    } else if (!strcmp(name, "SAX function unparsedEntityDecl")) {
        *((unparsedEntityDeclSAXFunc *) result) =
            ctxt->sax->unparsedEntityDecl;
    } else if (!strcmp(name, "SAX function setDocumentLocator")) {
        *((setDocumentLocatorSAXFunc *) result) =
            ctxt->sax->setDocumentLocator;
    } else if (!strcmp(name, "SAX function startDocument")) {
        *((startDocumentSAXFunc *) result) = ctxt->sax->startDocument;
    } else if (!strcmp(name, "SAX function endDocument")) {
        *((endDocumentSAXFunc *) result) = ctxt->sax->endDocument;
    } else if (!strcmp(name, "SAX function startElement")) {
        *((startElementSAXFunc *) result) = ctxt->sax->startElement;
    } else if (!strcmp(name, "SAX function endElement")) {
        *((endElementSAXFunc *) result) = ctxt->sax->endElement;
    } else if (!strcmp(name, "SAX function reference")) {
        *((referenceSAXFunc *) result) = ctxt->sax->reference;
    } else if (!strcmp(name, "SAX function characters")) {
        *((charactersSAXFunc *) result) = ctxt->sax->characters;
    } else if (!strcmp(name, "SAX function ignorableWhitespace")) {
        *((ignorableWhitespaceSAXFunc *) result) =
            ctxt->sax->ignorableWhitespace;
    } else if (!strcmp(name, "SAX function processingInstruction")) {
        *((processingInstructionSAXFunc *) result) =
            ctxt->sax->processingInstruction;
    } else if (!strcmp(name, "SAX function comment")) {
        *((commentSAXFunc *) result) = ctxt->sax->comment;
    } else if (!strcmp(name, "SAX function warning")) {
        *((warningSAXFunc *) result) = ctxt->sax->warning;
    } else if (!strcmp(name, "SAX function error")) {
        *((errorSAXFunc *) result) = ctxt->sax->error;
    } else if (!strcmp(name, "SAX function fatalError")) {
        *((fatalErrorSAXFunc *) result) = ctxt->sax->fatalError;
    } else if (!strcmp(name, "SAX function getParameterEntity")) {
        *((getParameterEntitySAXFunc *) result) =
            ctxt->sax->getParameterEntity;
    } else if (!strcmp(name, "SAX function cdataBlock")) {
        *((cdataBlockSAXFunc *) result) = ctxt->sax->cdataBlock;
    } else if (!strcmp(name, "SAX function externalSubset")) {
        *((externalSubsetSAXFunc *) result) = ctxt->sax->externalSubset;
    } else {
        return (-1);
    }
    return (0);
}

/**
 * xmlSetFeature:
 * @ctxt:  an XML/HTML parser context
 * @name:  the feature name
 * @value:  pointer to the location of the new value
 *
 * Change the current value of one feature of this parser instance
 *
 * Returns -1 in case or error, 0 otherwise
 */
int
xmlSetFeature(xmlParserCtxtPtr ctxt, const char *name, void *value)
{
    if ((ctxt == NULL) || (name == NULL) || (value == NULL))
        return (-1);

    if (!strcmp(name, "validate")) {
        int newvalidate = *((int *) value);

        if ((!ctxt->validate) && (newvalidate != 0)) {
            if (ctxt->vctxt.warning == NULL)
                ctxt->vctxt.warning = xmlParserValidityWarning;
            if (ctxt->vctxt.error == NULL)
                ctxt->vctxt.error = xmlParserValidityError;
            ctxt->vctxt.nodeMax = 0;
        }
        ctxt->validate = newvalidate;
    } else if (!strcmp(name, "keep blanks")) {
        ctxt->keepBlanks = *((int *) value);
    } else if (!strcmp(name, "disable SAX")) {
        ctxt->disableSAX = *((int *) value);
    } else if (!strcmp(name, "fetch external entities")) {
        ctxt->loadsubset = *((int *) value);
    } else if (!strcmp(name, "substitute entities")) {
        ctxt->replaceEntities = *((int *) value);
    } else if (!strcmp(name, "gather line info")) {
        ctxt->record_info = *((int *) value);
    } else if (!strcmp(name, "user data")) {
        ctxt->userData = *((void **) value);
    } else if (!strcmp(name, "is html")) {
        ctxt->html = *((int *) value);
    } else if (!strcmp(name, "is standalone")) {
        ctxt->standalone = *((int *) value);
    } else if (!strcmp(name, "document")) {
        ctxt->myDoc = *((xmlDocPtr *) value);
    } else if (!strcmp(name, "is well formed")) {
        ctxt->wellFormed = *((int *) value);
    } else if (!strcmp(name, "is valid")) {
        ctxt->valid = *((int *) value);
    } else if (!strcmp(name, "SAX block")) {
        ctxt->sax = *((xmlSAXHandlerPtr *) value);
    } else if (!strcmp(name, "SAX function internalSubset")) {
        ctxt->sax->internalSubset = *((internalSubsetSAXFunc *) value);
    } else if (!strcmp(name, "SAX function isStandalone")) {
        ctxt->sax->isStandalone = *((isStandaloneSAXFunc *) value);
    } else if (!strcmp(name, "SAX function hasInternalSubset")) {
        ctxt->sax->hasInternalSubset =
            *((hasInternalSubsetSAXFunc *) value);
    } else if (!strcmp(name, "SAX function hasExternalSubset")) {
        ctxt->sax->hasExternalSubset =
            *((hasExternalSubsetSAXFunc *) value);
    } else if (!strcmp(name, "SAX function resolveEntity")) {
        ctxt->sax->resolveEntity = *((resolveEntitySAXFunc *) value);
    } else if (!strcmp(name, "SAX function getEntity")) {
        ctxt->sax->getEntity = *((getEntitySAXFunc *) value);
    } else if (!strcmp(name, "SAX function entityDecl")) {
        ctxt->sax->entityDecl = *((entityDeclSAXFunc *) value);
    } else if (!strcmp(name, "SAX function notationDecl")) {
        ctxt->sax->notationDecl = *((notationDeclSAXFunc *) value);
    } else if (!strcmp(name, "SAX function attributeDecl")) {
        ctxt->sax->attributeDecl = *((attributeDeclSAXFunc *) value);
    } else if (!strcmp(name, "SAX function elementDecl")) {
        ctxt->sax->elementDecl = *((elementDeclSAXFunc *) value);
    } else if (!strcmp(name, "SAX function unparsedEntityDecl")) {
        ctxt->sax->unparsedEntityDecl =
            *((unparsedEntityDeclSAXFunc *) value);
    } else if (!strcmp(name, "SAX function setDocumentLocator")) {
        ctxt->sax->setDocumentLocator =
            *((setDocumentLocatorSAXFunc *) value);
    } else if (!strcmp(name, "SAX function startDocument")) {
        ctxt->sax->startDocument = *((startDocumentSAXFunc *) value);
    } else if (!strcmp(name, "SAX function endDocument")) {
        ctxt->sax->endDocument = *((endDocumentSAXFunc *) value);
    } else if (!strcmp(name, "SAX function startElement")) {
        ctxt->sax->startElement = *((startElementSAXFunc *) value);
    } else if (!strcmp(name, "SAX function endElement")) {
        ctxt->sax->endElement = *((endElementSAXFunc *) value);
    } else if (!strcmp(name, "SAX function reference")) {
        ctxt->sax->reference = *((referenceSAXFunc *) value);
    } else if (!strcmp(name, "SAX function characters")) {
        ctxt->sax->characters = *((charactersSAXFunc *) value);
    } else if (!strcmp(name, "SAX function ignorableWhitespace")) {
        ctxt->sax->ignorableWhitespace =
            *((ignorableWhitespaceSAXFunc *) value);
    } else if (!strcmp(name, "SAX function processingInstruction")) {
        ctxt->sax->processingInstruction =
            *((processingInstructionSAXFunc *) value);
    } else if (!strcmp(name, "SAX function comment")) {
        ctxt->sax->comment = *((commentSAXFunc *) value);
    } else if (!strcmp(name, "SAX function warning")) {
        ctxt->sax->warning = *((warningSAXFunc *) value);
    } else if (!strcmp(name, "SAX function error")) {
        ctxt->sax->error = *((errorSAXFunc *) value);
    } else if (!strcmp(name, "SAX function fatalError")) {
        ctxt->sax->fatalError = *((fatalErrorSAXFunc *) value);
    } else if (!strcmp(name, "SAX function getParameterEntity")) {
        ctxt->sax->getParameterEntity =
            *((getParameterEntitySAXFunc *) value);
    } else if (!strcmp(name, "SAX function cdataBlock")) {
        ctxt->sax->cdataBlock = *((cdataBlockSAXFunc *) value);
    } else if (!strcmp(name, "SAX function externalSubset")) {
        ctxt->sax->externalSubset = *((externalSubsetSAXFunc *) value);
    } else {
        return (-1);
    }
    return (0);
}

/**
 * xmlDecodeEntities:
 * @ctxt:  the parser context
 * @len:  the len to decode (in bytes !), -1 for no size limit
 * @what:  combination of XML_SUBSTITUTE_REF and XML_SUBSTITUTE_PEREF
 * @end:  an end marker xmlChar, 0 if none
 * @end2:  an end marker xmlChar, 0 if none
 * @end3:  an end marker xmlChar, 0 if none
 *
 * This function is deprecated, we now always process entities content
 * through xmlStringDecodeEntities
 *
 * TODO: remove it in next major release.
 *
 * [67] Reference ::= EntityRef | CharRef
 *
 * [69] PEReference ::= '%' Name ';'
 *
 * Returns A newly allocated string with the substitution done. The caller
 *      must deallocate it !
 */
xmlChar *
xmlDecodeEntities(xmlParserCtxtPtr ctxt ATTRIBUTE_UNUSED,
                  int len ATTRIBUTE_UNUSED, int what ATTRIBUTE_UNUSED,
                  xmlChar end ATTRIBUTE_UNUSED,
                  xmlChar end2 ATTRIBUTE_UNUSED,
                  xmlChar end3 ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlDecodeEntities() deprecated function reached\n");
        deprecated = 1;
    }
    return (NULL);
}

/**
 * xmlNamespaceParseNCName:
 * @ctxt:  an XML parser context
 *
 * parse an XML namespace name.
 *
 * TODO: this seems not in use anymore, the namespace handling is done on
 *       top of the SAX interfaces, i.e. not on raw input.
 *
 * [NS 3] NCName ::= (Letter | '_') (NCNameChar)*
 *
 * [NS 4] NCNameChar ::= Letter | Digit | '.' | '-' | '_' |
 *                       CombiningChar | Extender
 *
 * Returns the namespace name or NULL
 */

xmlChar *
xmlNamespaceParseNCName(xmlParserCtxtPtr ctxt ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlNamespaceParseNCName() deprecated function reached\n");
        deprecated = 1;
    }
    return (NULL);
}

/**
 * xmlNamespaceParseQName:
 * @ctxt:  an XML parser context
 * @prefix:  a xmlChar **
 *
 * TODO: this seems not in use anymore, the namespace handling is done on
 *       top of the SAX interfaces, i.e. not on raw input.
 *
 * parse an XML qualified name
 *
 * [NS 5] QName ::= (Prefix ':')? LocalPart
 *
 * [NS 6] Prefix ::= NCName
 *
 * [NS 7] LocalPart ::= NCName
 *
 * Returns the local part, and prefix is updated
 *   to get the Prefix if any.
 */

xmlChar *
xmlNamespaceParseQName(xmlParserCtxtPtr ctxt ATTRIBUTE_UNUSED,
                       xmlChar ** prefix ATTRIBUTE_UNUSED)
{

    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlNamespaceParseQName() deprecated function reached\n");
        deprecated = 1;
    }
    return (NULL);
}

/**
 * xmlNamespaceParseNSDef:
 * @ctxt:  an XML parser context
 *
 * parse a namespace prefix declaration
 *
 * TODO: this seems not in use anymore, the namespace handling is done on
 *       top of the SAX interfaces, i.e. not on raw input.
 *
 * [NS 1] NSDef ::= PrefixDef Eq SystemLiteral
 *
 * [NS 2] PrefixDef ::= 'xmlns' (':' NCName)?
 *
 * Returns the namespace name
 */

xmlChar *
xmlNamespaceParseNSDef(xmlParserCtxtPtr ctxt ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlNamespaceParseNSDef() deprecated function reached\n");
        deprecated = 1;
    }
    return (NULL);
}

/**
 * xmlParseQuotedString:
 * @ctxt:  an XML parser context
 *
 * Parse and return a string between quotes or doublequotes
 *
 * TODO: Deprecated, to  be removed at next drop of binary compatibility
 *
 * Returns the string parser or NULL.
 */
xmlChar *
xmlParseQuotedString(xmlParserCtxtPtr ctxt ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlParseQuotedString() deprecated function reached\n");
        deprecated = 1;
    }
    return (NULL);
}

/**
 * xmlParseNamespace:
 * @ctxt:  an XML parser context
 *
 * xmlParseNamespace: parse specific PI '<?namespace ...' constructs.
 *
 * This is what the older xml-name Working Draft specified, a bunch of
 * other stuff may still rely on it, so support is still here as
 * if it was declared on the root of the Tree:-(
 *
 * TODO: remove from library
 *
 * To be removed at next drop of binary compatibility
 */

void
xmlParseNamespace(xmlParserCtxtPtr ctxt ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlParseNamespace() deprecated function reached\n");
        deprecated = 1;
    }
}

/**
 * xmlScanName:
 * @ctxt:  an XML parser context
 *
 * Trickery: parse an XML name but without consuming the input flow
 * Needed for rollback cases. Used only when parsing entities references.
 *
 * TODO: seems deprecated now, only used in the default part of
 *       xmlParserHandleReference
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

xmlChar *
xmlScanName(xmlParserCtxtPtr ctxt ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlScanName() deprecated function reached\n");
        deprecated = 1;
    }
    return (NULL);
}

/**
 * xmlParserHandleReference:
 * @ctxt:  the parser context
 *
 * TODO: Remove, now deprecated ... the test is done directly in the
 *       content parsing
 * routines.
 *
 * [67] Reference ::= EntityRef | CharRef
 *
 * [68] EntityRef ::= '&' Name ';'
 *
 * [ WFC: Entity Declared ]
 * the Name given in the entity reference must match that in an entity
 * declaration, except that well-formed documents need not declare any
 * of the following entities: amp, lt, gt, apos, quot.
 *
 * [ WFC: Parsed Entity ]
 * An entity reference must not contain the name of an unparsed entity
 *
 * [66] CharRef ::= '&#' [0-9]+ ';' |
 *                  '&#x' [0-9a-fA-F]+ ';'
 *
 * A PEReference may have been detected in the current input stream
 * the handling is done accordingly to
 *      http://www.w3.org/TR/REC-xml#entproc
 */
void
xmlParserHandleReference(xmlParserCtxtPtr ctxt ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlParserHandleReference() deprecated function reached\n");
        deprecated = 1;
    }

    return;
}

/**
 * xmlHandleEntity:
 * @ctxt:  an XML parser context
 * @entity:  an XML entity pointer.
 *
 * Default handling of defined entities, when should we define a new input
 * stream ? When do we just handle that as a set of chars ?
 *
 * OBSOLETE: to be removed at some point.
 */

void
xmlHandleEntity(xmlParserCtxtPtr ctxt ATTRIBUTE_UNUSED,
                xmlEntityPtr entity ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlHandleEntity() deprecated function reached\n");
        deprecated = 1;
    }
}

/**
 * xmlNewGlobalNs:
 * @doc:  the document carrying the namespace
 * @href:  the URI associated
 * @prefix:  the prefix for the namespace
 *
 * Creation of a Namespace, the old way using PI and without scoping
 *   DEPRECATED !!!
 * Returns NULL this functionality had been removed
 */
xmlNsPtr
xmlNewGlobalNs(xmlDocPtr doc ATTRIBUTE_UNUSED,
               const xmlChar * href ATTRIBUTE_UNUSED,
               const xmlChar * prefix ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlNewGlobalNs() deprecated function reached\n");
        deprecated = 1;
    }
    return (NULL);
}

/**
 * xmlUpgradeOldNs:
 * @doc:  a document pointer
 *
 * Upgrade old style Namespaces (PI) and move them to the root of the document.
 * DEPRECATED
 */
void
xmlUpgradeOldNs(xmlDocPtr doc ATTRIBUTE_UNUSED)
{
    static int deprecated = 0;

    if (!deprecated) {
        xmlGenericError(xmlGenericErrorContext,
                        "xmlUpgradeOldNs() deprecated function reached\n");
        deprecated = 1;
    }
}

/**
 * xmlEncodeEntities:
 * @doc:  the document containing the string
 * @input:  A string to convert to XML.
 *
 * TODO: remove xmlEncodeEntities, once we are not afraid of breaking binary
 *       compatibility
 *
 * People must migrate their code to xmlEncodeEntitiesReentrant !
 * This routine will issue a warning when encountered.
 *
 * Returns NULL
 */
const xmlChar *
xmlEncodeEntities(xmlDocPtr doc ATTRIBUTE_UNUSED,
                  const xmlChar * input ATTRIBUTE_UNUSED)
{
    static int warning = 1;

    if (warning) {
        xmlGenericError(xmlGenericErrorContext,
                        "Deprecated API xmlEncodeEntities() used\n");
        xmlGenericError(xmlGenericErrorContext,
                        "   change code to use xmlEncodeEntitiesReentrant()\n");
        warning = 0;
    }
    return (NULL);
}

/************************************************************************
 *									*
 *		Old set of SAXv1 functions				*
 *									*
 ************************************************************************/
static int deprecated_v1_msg = 0;

#define DEPRECATED(n)						\
    if (deprecated_v1_msg == 0)					\
	xmlGenericError(xmlGenericErrorContext,			\
	  "Use of deprecated SAXv1 function %s\n", n);		\
    deprecated_v1_msg++;

/**
 * getPublicId:
 * @ctx: the user data (XML parser context)
 *
 * Provides the public ID e.g. "-//SGMLSOURCE//DTD DEMO//EN"
 * DEPRECATED: use xmlSAX2GetPublicId()
 *
 * Returns a xmlChar *
 */
const xmlChar *
getPublicId(void *ctx)
{
    DEPRECATED("getPublicId")
        return (xmlSAX2GetPublicId(ctx));
}

/**
 * getSystemId:
 * @ctx: the user data (XML parser context)
 *
 * Provides the system ID, basically URL or filename e.g.
 * http://www.sgmlsource.com/dtds/memo.dtd
 * DEPRECATED: use xmlSAX2GetSystemId()
 *
 * Returns a xmlChar *
 */
const xmlChar *
getSystemId(void *ctx)
{
    DEPRECATED("getSystemId")
        return (xmlSAX2GetSystemId(ctx));
}

/**
 * getLineNumber:
 * @ctx: the user data (XML parser context)
 *
 * Provide the line number of the current parsing point.
 * DEPRECATED: use xmlSAX2GetLineNumber()
 *
 * Returns an int
 */
int
getLineNumber(void *ctx)
{
    DEPRECATED("getLineNumber")
        return (xmlSAX2GetLineNumber(ctx));
}

/**
 * getColumnNumber:
 * @ctx: the user data (XML parser context)
 *
 * Provide the column number of the current parsing point.
 * DEPRECATED: use xmlSAX2GetColumnNumber()
 *
 * Returns an int
 */
int
getColumnNumber(void *ctx)
{
    DEPRECATED("getColumnNumber")
        return (xmlSAX2GetColumnNumber(ctx));
}

/**
 * isStandalone:
 * @ctx: the user data (XML parser context)
 *
 * Is this document tagged standalone ?
 * DEPRECATED: use xmlSAX2IsStandalone()
 *
 * Returns 1 if true
 */
int
isStandalone(void *ctx)
{
    DEPRECATED("isStandalone")
        return (xmlSAX2IsStandalone(ctx));
}

/**
 * hasInternalSubset:
 * @ctx: the user data (XML parser context)
 *
 * Does this document has an internal subset
 * DEPRECATED: use xmlSAX2HasInternalSubset()
 *
 * Returns 1 if true
 */
int
hasInternalSubset(void *ctx)
{
    DEPRECATED("hasInternalSubset")
        return (xmlSAX2HasInternalSubset(ctx));
}

/**
 * hasExternalSubset:
 * @ctx: the user data (XML parser context)
 *
 * Does this document has an external subset
 * DEPRECATED: use xmlSAX2HasExternalSubset()
 *
 * Returns 1 if true
 */
int
hasExternalSubset(void *ctx)
{
    DEPRECATED("hasExternalSubset")
        return (xmlSAX2HasExternalSubset(ctx));
}

/**
 * internalSubset:
 * @ctx:  the user data (XML parser context)
 * @name:  the root element name
 * @ExternalID:  the external ID
 * @SystemID:  the SYSTEM ID (e.g. filename or URL)
 *
 * Callback on internal subset declaration.
 * DEPRECATED: use xmlSAX2InternalSubset()
 */
void
internalSubset(void *ctx, const xmlChar * name,
               const xmlChar * ExternalID, const xmlChar * SystemID)
{
    DEPRECATED("internalSubset")
        xmlSAX2InternalSubset(ctx, name, ExternalID, SystemID);
}

/**
 * externalSubset:
 * @ctx: the user data (XML parser context)
 * @name:  the root element name
 * @ExternalID:  the external ID
 * @SystemID:  the SYSTEM ID (e.g. filename or URL)
 *
 * Callback on external subset declaration.
 * DEPRECATED: use xmlSAX2ExternalSubset()
 */
void
externalSubset(void *ctx, const xmlChar * name,
               const xmlChar * ExternalID, const xmlChar * SystemID)
{
    DEPRECATED("externalSubset")
        xmlSAX2ExternalSubset(ctx, name, ExternalID, SystemID);
}

/**
 * resolveEntity:
 * @ctx: the user data (XML parser context)
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 *
 * The entity loader, to control the loading of external entities,
 * the application can either:
 *    - override this resolveEntity() callback in the SAX block
 *    - or better use the xmlSetExternalEntityLoader() function to
 *      set up it's own entity resolution routine
 * DEPRECATED: use xmlSAX2ResolveEntity()
 *
 * Returns the xmlParserInputPtr if inlined or NULL for DOM behaviour.
 */
xmlParserInputPtr
resolveEntity(void *ctx, const xmlChar * publicId,
              const xmlChar * systemId)
{
    DEPRECATED("resolveEntity")
        return (xmlSAX2ResolveEntity(ctx, publicId, systemId));
}

/**
 * getEntity:
 * @ctx: the user data (XML parser context)
 * @name: The entity name
 *
 * Get an entity by name
 * DEPRECATED: use xmlSAX2GetEntity()
 *
 * Returns the xmlEntityPtr if found.
 */
xmlEntityPtr
getEntity(void *ctx, const xmlChar * name)
{
    DEPRECATED("getEntity")
        return (xmlSAX2GetEntity(ctx, name));
}

/**
 * getParameterEntity:
 * @ctx: the user data (XML parser context)
 * @name: The entity name
 *
 * Get a parameter entity by name
 * DEPRECATED: use xmlSAX2GetParameterEntity()
 *
 * Returns the xmlEntityPtr if found.
 */
xmlEntityPtr
getParameterEntity(void *ctx, const xmlChar * name)
{
    DEPRECATED("getParameterEntity")
        return (xmlSAX2GetParameterEntity(ctx, name));
}


/**
 * entityDecl:
 * @ctx: the user data (XML parser context)
 * @name:  the entity name
 * @type:  the entity type
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 * @content: the entity value (without processing).
 *
 * An entity definition has been parsed
 * DEPRECATED: use xmlSAX2EntityDecl()
 */
void
entityDecl(void *ctx, const xmlChar * name, int type,
           const xmlChar * publicId, const xmlChar * systemId,
           xmlChar * content)
{
    DEPRECATED("entityDecl")
        xmlSAX2EntityDecl(ctx, name, type, publicId, systemId, content);
}

/**
 * attributeDecl:
 * @ctx: the user data (XML parser context)
 * @elem:  the name of the element
 * @fullname:  the attribute name
 * @type:  the attribute type
 * @def:  the type of default value
 * @defaultValue: the attribute default value
 * @tree:  the tree of enumerated value set
 *
 * An attribute definition has been parsed
 * DEPRECATED: use xmlSAX2AttributeDecl()
 */
void
attributeDecl(void *ctx, const xmlChar * elem, const xmlChar * fullname,
              int type, int def, const xmlChar * defaultValue,
              xmlEnumerationPtr tree)
{
    DEPRECATED("attributeDecl")
        xmlSAX2AttributeDecl(ctx, elem, fullname, type, def, defaultValue,
                             tree);
}

/**
 * elementDecl:
 * @ctx: the user data (XML parser context)
 * @name:  the element name
 * @type:  the element type
 * @content: the element value tree
 *
 * An element definition has been parsed
 * DEPRECATED: use xmlSAX2ElementDecl()
 */
void
elementDecl(void *ctx, const xmlChar * name, int type,
            xmlElementContentPtr content)
{
    DEPRECATED("elementDecl")
        xmlSAX2ElementDecl(ctx, name, type, content);
}

/**
 * notationDecl:
 * @ctx: the user data (XML parser context)
 * @name: The name of the notation
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 *
 * What to do when a notation declaration has been parsed.
 * DEPRECATED: use xmlSAX2NotationDecl()
 */
void
notationDecl(void *ctx, const xmlChar * name,
             const xmlChar * publicId, const xmlChar * systemId)
{
    DEPRECATED("notationDecl")
        xmlSAX2NotationDecl(ctx, name, publicId, systemId);
}

/**
 * unparsedEntityDecl:
 * @ctx: the user data (XML parser context)
 * @name: The name of the entity
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 * @notationName: the name of the notation
 *
 * What to do when an unparsed entity declaration is parsed
 * DEPRECATED: use xmlSAX2UnparsedEntityDecl()
 */
void
unparsedEntityDecl(void *ctx, const xmlChar * name,
                   const xmlChar * publicId, const xmlChar * systemId,
                   const xmlChar * notationName)
{
    DEPRECATED("unparsedEntityDecl")
        xmlSAX2UnparsedEntityDecl(ctx, name, publicId, systemId,
                                  notationName);
}

/**
 * setDocumentLocator:
 * @ctx: the user data (XML parser context)
 * @loc: A SAX Locator
 *
 * Receive the document locator at startup, actually xmlDefaultSAXLocator
 * Everything is available on the context, so this is useless in our case.
 * DEPRECATED
 */
void
setDocumentLocator(void *ctx ATTRIBUTE_UNUSED,
                   xmlSAXLocatorPtr loc ATTRIBUTE_UNUSED)
{
    DEPRECATED("setDocumentLocator")
}

/**
 * startDocument:
 * @ctx: the user data (XML parser context)
 *
 * called when the document start being processed.
 * DEPRECATED: use xmlSAX2StartDocument()
 */
void
startDocument(void *ctx)
{
   /* don't be too painful for glade users */
   /*  DEPRECATED("startDocument") */
        xmlSAX2StartDocument(ctx);
}

/**
 * endDocument:
 * @ctx: the user data (XML parser context)
 *
 * called when the document end has been detected.
 * DEPRECATED: use xmlSAX2EndDocument()
 */
void
endDocument(void *ctx)
{
    DEPRECATED("endDocument")
        xmlSAX2EndDocument(ctx);
}

/**
 * attribute:
 * @ctx: the user data (XML parser context)
 * @fullname:  The attribute name, including namespace prefix
 * @value:  The attribute value
 *
 * Handle an attribute that has been read by the parser.
 * The default handling is to convert the attribute into an
 * DOM subtree and past it in a new xmlAttr element added to
 * the element.
 * DEPRECATED: use xmlSAX2Attribute()
 */
void
attribute(void *ctx ATTRIBUTE_UNUSED,
          const xmlChar * fullname ATTRIBUTE_UNUSED,
          const xmlChar * value ATTRIBUTE_UNUSED)
{
    DEPRECATED("attribute")
}

/**
 * startElement:
 * @ctx: the user data (XML parser context)
 * @fullname:  The element name, including namespace prefix
 * @atts:  An array of name/value attributes pairs, NULL terminated
 *
 * called when an opening tag has been processed.
 * DEPRECATED: use xmlSAX2StartElement()
 */
void
startElement(void *ctx, const xmlChar * fullname, const xmlChar ** atts)
{
    xmlSAX2StartElement(ctx, fullname, atts);
}

/**
 * endElement:
 * @ctx: the user data (XML parser context)
 * @name:  The element name
 *
 * called when the end of an element has been detected.
 * DEPRECATED: use xmlSAX2EndElement()
 */
void
endElement(void *ctx, const xmlChar * name ATTRIBUTE_UNUSED)
{
    DEPRECATED("endElement")
    xmlSAX2EndElement(ctx, name);
}

/**
 * reference:
 * @ctx: the user data (XML parser context)
 * @name:  The entity name
 *
 * called when an entity reference is detected.
 * DEPRECATED: use xmlSAX2Reference()
 */
void
reference(void *ctx, const xmlChar * name)
{
    DEPRECATED("reference")
        xmlSAX2Reference(ctx, name);
}

/**
 * characters:
 * @ctx: the user data (XML parser context)
 * @ch:  a xmlChar string
 * @len: the number of xmlChar
 *
 * receiving some chars from the parser.
 * DEPRECATED: use xmlSAX2Characters()
 */
void
characters(void *ctx, const xmlChar * ch, int len)
{
    DEPRECATED("characters")
        xmlSAX2Characters(ctx, ch, len);
}

/**
 * ignorableWhitespace:
 * @ctx: the user data (XML parser context)
 * @ch:  a xmlChar string
 * @len: the number of xmlChar
 *
 * receiving some ignorable whitespaces from the parser.
 * UNUSED: by default the DOM building will use characters
 * DEPRECATED: use xmlSAX2IgnorableWhitespace()
 */
void
ignorableWhitespace(void *ctx ATTRIBUTE_UNUSED,
                    const xmlChar * ch ATTRIBUTE_UNUSED,
                    int len ATTRIBUTE_UNUSED)
{
    DEPRECATED("ignorableWhitespace")
}

/**
 * processingInstruction:
 * @ctx: the user data (XML parser context)
 * @target:  the target name
 * @data: the PI data's
 *
 * A processing instruction has been parsed.
 * DEPRECATED: use xmlSAX2ProcessingInstruction()
 */
void
processingInstruction(void *ctx, const xmlChar * target,
                      const xmlChar * data)
{
    DEPRECATED("processingInstruction")
        xmlSAX2ProcessingInstruction(ctx, target, data);
}

/**
 * globalNamespace:
 * @ctx: the user data (XML parser context)
 * @href:  the namespace associated URN
 * @prefix: the namespace prefix
 *
 * An old global namespace has been parsed.
 * DEPRECATED
 */
void
globalNamespace(void *ctx ATTRIBUTE_UNUSED,
                const xmlChar * href ATTRIBUTE_UNUSED,
                const xmlChar * prefix ATTRIBUTE_UNUSED)
{
    DEPRECATED("globalNamespace")
}

/**
 * setNamespace:
 * @ctx: the user data (XML parser context)
 * @name:  the namespace prefix
 *
 * Set the current element namespace.
 * DEPRECATED
 */

void
setNamespace(void *ctx ATTRIBUTE_UNUSED,
             const xmlChar * name ATTRIBUTE_UNUSED)
{
    DEPRECATED("setNamespace")
}

/**
 * getNamespace:
 * @ctx: the user data (XML parser context)
 *
 * Get the current element namespace.
 * DEPRECATED
 *
 * Returns the xmlNsPtr or NULL if none
 */

xmlNsPtr
getNamespace(void *ctx ATTRIBUTE_UNUSED)
{
    DEPRECATED("getNamespace")
        return (NULL);
}

/**
 * checkNamespace:
 * @ctx: the user data (XML parser context)
 * @namespace: the namespace to check against
 *
 * Check that the current element namespace is the same as the
 * one read upon parsing.
 * DEPRECATED
 *
 * Returns 1 if true 0 otherwise
 */

int
checkNamespace(void *ctx ATTRIBUTE_UNUSED,
               xmlChar * namespace ATTRIBUTE_UNUSED)
{
    DEPRECATED("checkNamespace")
        return (0);
}

/**
 * namespaceDecl:
 * @ctx: the user data (XML parser context)
 * @href:  the namespace associated URN
 * @prefix: the namespace prefix
 *
 * A namespace has been parsed.
 * DEPRECATED
 */
void
namespaceDecl(void *ctx ATTRIBUTE_UNUSED,
              const xmlChar * href ATTRIBUTE_UNUSED,
              const xmlChar * prefix ATTRIBUTE_UNUSED)
{
    DEPRECATED("namespaceDecl")
}

/**
 * comment:
 * @ctx: the user data (XML parser context)
 * @value:  the comment content
 *
 * A comment has been parsed.
 * DEPRECATED: use xmlSAX2Comment()
 */
void
comment(void *ctx, const xmlChar * value)
{
    DEPRECATED("comment")
        xmlSAX2Comment(ctx, value);
}

/**
 * cdataBlock:
 * @ctx: the user data (XML parser context)
 * @value:  The pcdata content
 * @len:  the block length
 *
 * called when a pcdata block has been parsed
 * DEPRECATED: use xmlSAX2CDataBlock()
 */
void
cdataBlock(void *ctx, const xmlChar * value, int len)
{
    DEPRECATED("cdataBlock")
        xmlSAX2CDataBlock(ctx, value, len);
}
#define bottom_legacy
#include "elfgcchack.h"
#endif /* LIBXML_LEGACY_ENABLED */

