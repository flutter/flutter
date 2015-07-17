/*
 * HTMLtree.c : implementation of access function for an HTML tree.
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 */


#define IN_LIBXML
#include "libxml.h"
#ifdef LIBXML_HTML_ENABLED

#include <string.h> /* for memset() only ! */

#ifdef HAVE_CTYPE_H
#include <ctype.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#include <libxml/xmlmemory.h>
#include <libxml/HTMLparser.h>
#include <libxml/HTMLtree.h>
#include <libxml/entities.h>
#include <libxml/valid.h>
#include <libxml/xmlerror.h>
#include <libxml/parserInternals.h>
#include <libxml/globals.h>
#include <libxml/uri.h>

#include "buf.h"

/************************************************************************
 *									*
 *		Getting/Setting encoding meta tags			*
 *									*
 ************************************************************************/

/**
 * htmlGetMetaEncoding:
 * @doc:  the document
 *
 * Encoding definition lookup in the Meta tags
 *
 * Returns the current encoding as flagged in the HTML source
 */
const xmlChar *
htmlGetMetaEncoding(htmlDocPtr doc) {
    htmlNodePtr cur;
    const xmlChar *content;
    const xmlChar *encoding;

    if (doc == NULL)
	return(NULL);
    cur = doc->children;

    /*
     * Search the html
     */
    while (cur != NULL) {
	if ((cur->type == XML_ELEMENT_NODE) && (cur->name != NULL)) {
	    if (xmlStrEqual(cur->name, BAD_CAST"html"))
		break;
	    if (xmlStrEqual(cur->name, BAD_CAST"head"))
		goto found_head;
	    if (xmlStrEqual(cur->name, BAD_CAST"meta"))
		goto found_meta;
	}
	cur = cur->next;
    }
    if (cur == NULL)
	return(NULL);
    cur = cur->children;

    /*
     * Search the head
     */
    while (cur != NULL) {
	if ((cur->type == XML_ELEMENT_NODE) && (cur->name != NULL)) {
	    if (xmlStrEqual(cur->name, BAD_CAST"head"))
		break;
	    if (xmlStrEqual(cur->name, BAD_CAST"meta"))
		goto found_meta;
	}
	cur = cur->next;
    }
    if (cur == NULL)
	return(NULL);
found_head:
    cur = cur->children;

    /*
     * Search the meta elements
     */
found_meta:
    while (cur != NULL) {
	if ((cur->type == XML_ELEMENT_NODE) && (cur->name != NULL)) {
	    if (xmlStrEqual(cur->name, BAD_CAST"meta")) {
		xmlAttrPtr attr = cur->properties;
		int http;
		const xmlChar *value;

		content = NULL;
		http = 0;
		while (attr != NULL) {
		    if ((attr->children != NULL) &&
		        (attr->children->type == XML_TEXT_NODE) &&
		        (attr->children->next == NULL)) {
			value = attr->children->content;
			if ((!xmlStrcasecmp(attr->name, BAD_CAST"http-equiv"))
			 && (!xmlStrcasecmp(value, BAD_CAST"Content-Type")))
			    http = 1;
			else if ((value != NULL)
			 && (!xmlStrcasecmp(attr->name, BAD_CAST"content")))
			    content = value;
			if ((http != 0) && (content != NULL))
			    goto found_content;
		    }
		    attr = attr->next;
		}
	    }
	}
	cur = cur->next;
    }
    return(NULL);

found_content:
    encoding = xmlStrstr(content, BAD_CAST"charset=");
    if (encoding == NULL)
	encoding = xmlStrstr(content, BAD_CAST"Charset=");
    if (encoding == NULL)
	encoding = xmlStrstr(content, BAD_CAST"CHARSET=");
    if (encoding != NULL) {
	encoding += 8;
    } else {
	encoding = xmlStrstr(content, BAD_CAST"charset =");
	if (encoding == NULL)
	    encoding = xmlStrstr(content, BAD_CAST"Charset =");
	if (encoding == NULL)
	    encoding = xmlStrstr(content, BAD_CAST"CHARSET =");
	if (encoding != NULL)
	    encoding += 9;
    }
    if (encoding != NULL) {
	while ((*encoding == ' ') || (*encoding == '\t')) encoding++;
    }
    return(encoding);
}

/**
 * htmlSetMetaEncoding:
 * @doc:  the document
 * @encoding:  the encoding string
 *
 * Sets the current encoding in the Meta tags
 * NOTE: this will not change the document content encoding, just
 * the META flag associated.
 *
 * Returns 0 in case of success and -1 in case of error
 */
int
htmlSetMetaEncoding(htmlDocPtr doc, const xmlChar *encoding) {
    htmlNodePtr cur, meta = NULL, head = NULL;
    const xmlChar *content = NULL;
    char newcontent[100];

    newcontent[0] = 0;

    if (doc == NULL)
	return(-1);

    /* html isn't a real encoding it's just libxml2 way to get entities */
    if (!xmlStrcasecmp(encoding, BAD_CAST "html"))
        return(-1);

    if (encoding != NULL) {
	snprintf(newcontent, sizeof(newcontent), "text/html; charset=%s",
                (char *)encoding);
	newcontent[sizeof(newcontent) - 1] = 0;
    }

    cur = doc->children;

    /*
     * Search the html
     */
    while (cur != NULL) {
	if ((cur->type == XML_ELEMENT_NODE) && (cur->name != NULL)) {
	    if (xmlStrcasecmp(cur->name, BAD_CAST"html") == 0)
		break;
	    if (xmlStrcasecmp(cur->name, BAD_CAST"head") == 0)
		goto found_head;
	    if (xmlStrcasecmp(cur->name, BAD_CAST"meta") == 0)
		goto found_meta;
	}
	cur = cur->next;
    }
    if (cur == NULL)
	return(-1);
    cur = cur->children;

    /*
     * Search the head
     */
    while (cur != NULL) {
	if ((cur->type == XML_ELEMENT_NODE) && (cur->name != NULL)) {
	    if (xmlStrcasecmp(cur->name, BAD_CAST"head") == 0)
		break;
	    if (xmlStrcasecmp(cur->name, BAD_CAST"meta") == 0) {
                head = cur->parent;
		goto found_meta;
            }
	}
	cur = cur->next;
    }
    if (cur == NULL)
	return(-1);
found_head:
    head = cur;
    if (cur->children == NULL)
        goto create;
    cur = cur->children;

found_meta:
    /*
     * Search and update all the remaining the meta elements carrying
     * encoding informations
     */
    while (cur != NULL) {
	if ((cur->type == XML_ELEMENT_NODE) && (cur->name != NULL)) {
	    if (xmlStrcasecmp(cur->name, BAD_CAST"meta") == 0) {
		xmlAttrPtr attr = cur->properties;
		int http;
		const xmlChar *value;

		content = NULL;
		http = 0;
		while (attr != NULL) {
		    if ((attr->children != NULL) &&
		        (attr->children->type == XML_TEXT_NODE) &&
		        (attr->children->next == NULL)) {
			value = attr->children->content;
			if ((!xmlStrcasecmp(attr->name, BAD_CAST"http-equiv"))
			 && (!xmlStrcasecmp(value, BAD_CAST"Content-Type")))
			    http = 1;
			else
                        {
                           if ((value != NULL) &&
                               (!xmlStrcasecmp(attr->name, BAD_CAST"content")))
			       content = value;
                        }
		        if ((http != 0) && (content != NULL))
			    break;
		    }
		    attr = attr->next;
		}
		if ((http != 0) && (content != NULL)) {
		    meta = cur;
		    break;
		}

	    }
	}
	cur = cur->next;
    }
create:
    if (meta == NULL) {
        if ((encoding != NULL) && (head != NULL)) {
            /*
             * Create a new Meta element with the right attributes
             */

            meta = xmlNewDocNode(doc, NULL, BAD_CAST"meta", NULL);
            if (head->children == NULL)
                xmlAddChild(head, meta);
            else
                xmlAddPrevSibling(head->children, meta);
            xmlNewProp(meta, BAD_CAST"http-equiv", BAD_CAST"Content-Type");
            xmlNewProp(meta, BAD_CAST"content", BAD_CAST newcontent);
        }
    } else {
        /* remove the meta tag if NULL is passed */
        if (encoding == NULL) {
            xmlUnlinkNode(meta);
            xmlFreeNode(meta);
        }
        /* change the document only if there is a real encoding change */
        else if (xmlStrcasestr(content, encoding) == NULL) {
            xmlSetProp(meta, BAD_CAST"content", BAD_CAST newcontent);
        }
    }


    return(0);
}

/**
 * booleanHTMLAttrs:
 *
 * These are the HTML attributes which will be output
 * in minimized form, i.e. <option selected="selected"> will be
 * output as <option selected>, as per XSLT 1.0 16.2 "HTML Output Method"
 *
 */
static const char* htmlBooleanAttrs[] = {
  "checked", "compact", "declare", "defer", "disabled", "ismap",
  "multiple", "nohref", "noresize", "noshade", "nowrap", "readonly",
  "selected", NULL
};


/**
 * htmlIsBooleanAttr:
 * @name:  the name of the attribute to check
 *
 * Determine if a given attribute is a boolean attribute.
 *
 * returns: false if the attribute is not boolean, true otherwise.
 */
int
htmlIsBooleanAttr(const xmlChar *name)
{
    int i = 0;

    while (htmlBooleanAttrs[i] != NULL) {
        if (xmlStrcasecmp((const xmlChar *)htmlBooleanAttrs[i], name) == 0)
            return 1;
        i++;
    }
    return 0;
}

#ifdef LIBXML_OUTPUT_ENABLED
/*
 * private routine exported from xmlIO.c
 */
xmlOutputBufferPtr
xmlAllocOutputBufferInternal(xmlCharEncodingHandlerPtr encoder);
/************************************************************************
 *									*
 *			Output error handlers				*
 *									*
 ************************************************************************/
/**
 * htmlSaveErrMemory:
 * @extra:  extra informations
 *
 * Handle an out of memory condition
 */
static void
htmlSaveErrMemory(const char *extra)
{
    __xmlSimpleError(XML_FROM_OUTPUT, XML_ERR_NO_MEMORY, NULL, NULL, extra);
}

/**
 * htmlSaveErr:
 * @code:  the error number
 * @node:  the location of the error.
 * @extra:  extra informations
 *
 * Handle an out of memory condition
 */
static void
htmlSaveErr(int code, xmlNodePtr node, const char *extra)
{
    const char *msg = NULL;

    switch(code) {
        case XML_SAVE_NOT_UTF8:
	    msg = "string is not in UTF-8\n";
	    break;
	case XML_SAVE_CHAR_INVALID:
	    msg = "invalid character value\n";
	    break;
	case XML_SAVE_UNKNOWN_ENCODING:
	    msg = "unknown encoding %s\n";
	    break;
	case XML_SAVE_NO_DOCTYPE:
	    msg = "HTML has no DOCTYPE\n";
	    break;
	default:
	    msg = "unexpected error number\n";
    }
    __xmlSimpleError(XML_FROM_OUTPUT, code, node, msg, extra);
}

/************************************************************************
 *									*
 *		Dumping HTML tree content to a simple buffer		*
 *									*
 ************************************************************************/

/**
 * htmlBufNodeDumpFormat:
 * @buf:  the xmlBufPtr output
 * @doc:  the document
 * @cur:  the current node
 * @format:  should formatting spaces been added
 *
 * Dump an HTML node, recursive behaviour,children are printed too.
 *
 * Returns the number of byte written or -1 in case of error
 */
static size_t
htmlBufNodeDumpFormat(xmlBufPtr buf, xmlDocPtr doc, xmlNodePtr cur,
	           int format) {
    size_t use;
    int ret;
    xmlOutputBufferPtr outbuf;

    if (cur == NULL) {
	return (-1);
    }
    if (buf == NULL) {
	return (-1);
    }
    outbuf = (xmlOutputBufferPtr) xmlMalloc(sizeof(xmlOutputBuffer));
    if (outbuf == NULL) {
        htmlSaveErrMemory("allocating HTML output buffer");
	return (-1);
    }
    memset(outbuf, 0, (size_t) sizeof(xmlOutputBuffer));
    outbuf->buffer = buf;
    outbuf->encoder = NULL;
    outbuf->writecallback = NULL;
    outbuf->closecallback = NULL;
    outbuf->context = NULL;
    outbuf->written = 0;

    use = xmlBufUse(buf);
    htmlNodeDumpFormatOutput(outbuf, doc, cur, NULL, format);
    xmlFree(outbuf);
    ret = xmlBufUse(buf) - use;
    return (ret);
}

/**
 * htmlNodeDump:
 * @buf:  the HTML buffer output
 * @doc:  the document
 * @cur:  the current node
 *
 * Dump an HTML node, recursive behaviour,children are printed too,
 * and formatting returns are added.
 *
 * Returns the number of byte written or -1 in case of error
 */
int
htmlNodeDump(xmlBufferPtr buf, xmlDocPtr doc, xmlNodePtr cur) {
    xmlBufPtr buffer;
    size_t ret;

    if ((buf == NULL) || (cur == NULL))
        return(-1);

    xmlInitParser();
    buffer = xmlBufFromBuffer(buf);
    if (buffer == NULL)
        return(-1);

    ret = htmlBufNodeDumpFormat(buffer, doc, cur, 1);

    xmlBufBackToBuffer(buffer);

    if (ret > INT_MAX)
        return(-1);
    return((int) ret);
}

/**
 * htmlNodeDumpFileFormat:
 * @out:  the FILE pointer
 * @doc:  the document
 * @cur:  the current node
 * @encoding: the document encoding
 * @format:  should formatting spaces been added
 *
 * Dump an HTML node, recursive behaviour,children are printed too.
 *
 * TODO: if encoding == NULL try to save in the doc encoding
 *
 * returns: the number of byte written or -1 in case of failure.
 */
int
htmlNodeDumpFileFormat(FILE *out, xmlDocPtr doc,
	               xmlNodePtr cur, const char *encoding, int format) {
    xmlOutputBufferPtr buf;
    xmlCharEncodingHandlerPtr handler = NULL;
    int ret;

    xmlInitParser();

    if (encoding != NULL) {
	xmlCharEncoding enc;

	enc = xmlParseCharEncoding(encoding);
	if (enc != XML_CHAR_ENCODING_UTF8) {
	    handler = xmlFindCharEncodingHandler(encoding);
	    if (handler == NULL)
		htmlSaveErr(XML_SAVE_UNKNOWN_ENCODING, NULL, encoding);
	}
    }

    /*
     * Fallback to HTML or ASCII when the encoding is unspecified
     */
    if (handler == NULL)
	handler = xmlFindCharEncodingHandler("HTML");
    if (handler == NULL)
	handler = xmlFindCharEncodingHandler("ascii");

    /*
     * save the content to a temp buffer.
     */
    buf = xmlOutputBufferCreateFile(out, handler);
    if (buf == NULL) return(0);

    htmlNodeDumpFormatOutput(buf, doc, cur, encoding, format);

    ret = xmlOutputBufferClose(buf);
    return(ret);
}

/**
 * htmlNodeDumpFile:
 * @out:  the FILE pointer
 * @doc:  the document
 * @cur:  the current node
 *
 * Dump an HTML node, recursive behaviour,children are printed too,
 * and formatting returns are added.
 */
void
htmlNodeDumpFile(FILE *out, xmlDocPtr doc, xmlNodePtr cur) {
    htmlNodeDumpFileFormat(out, doc, cur, NULL, 1);
}

/**
 * htmlDocDumpMemoryFormat:
 * @cur:  the document
 * @mem:  OUT: the memory pointer
 * @size:  OUT: the memory length
 * @format:  should formatting spaces been added
 *
 * Dump an HTML document in memory and return the xmlChar * and it's size.
 * It's up to the caller to free the memory.
 */
void
htmlDocDumpMemoryFormat(xmlDocPtr cur, xmlChar**mem, int *size, int format) {
    xmlOutputBufferPtr buf;
    xmlCharEncodingHandlerPtr handler = NULL;
    const char *encoding;

    xmlInitParser();

    if ((mem == NULL) || (size == NULL))
        return;
    if (cur == NULL) {
	*mem = NULL;
	*size = 0;
	return;
    }

    encoding = (const char *) htmlGetMetaEncoding(cur);

    if (encoding != NULL) {
	xmlCharEncoding enc;

	enc = xmlParseCharEncoding(encoding);
	if (enc != cur->charset) {
	    if (cur->charset != XML_CHAR_ENCODING_UTF8) {
		/*
		 * Not supported yet
		 */
		*mem = NULL;
		*size = 0;
		return;
	    }

	    handler = xmlFindCharEncodingHandler(encoding);
	    if (handler == NULL)
                htmlSaveErr(XML_SAVE_UNKNOWN_ENCODING, NULL, encoding);

	} else {
	    handler = xmlFindCharEncodingHandler(encoding);
	}
    }

    /*
     * Fallback to HTML or ASCII when the encoding is unspecified
     */
    if (handler == NULL)
	handler = xmlFindCharEncodingHandler("HTML");
    if (handler == NULL)
	handler = xmlFindCharEncodingHandler("ascii");

    buf = xmlAllocOutputBufferInternal(handler);
    if (buf == NULL) {
	*mem = NULL;
	*size = 0;
	return;
    }

    htmlDocContentDumpFormatOutput(buf, cur, NULL, format);

    xmlOutputBufferFlush(buf);
    if (buf->conv != NULL) {
	*size = xmlBufUse(buf->conv);
	*mem = xmlStrndup(xmlBufContent(buf->conv), *size);
    } else {
	*size = xmlBufUse(buf->buffer);
	*mem = xmlStrndup(xmlBufContent(buf->buffer), *size);
    }
    (void)xmlOutputBufferClose(buf);
}

/**
 * htmlDocDumpMemory:
 * @cur:  the document
 * @mem:  OUT: the memory pointer
 * @size:  OUT: the memory length
 *
 * Dump an HTML document in memory and return the xmlChar * and it's size.
 * It's up to the caller to free the memory.
 */
void
htmlDocDumpMemory(xmlDocPtr cur, xmlChar**mem, int *size) {
	htmlDocDumpMemoryFormat(cur, mem, size, 1);
}


/************************************************************************
 *									*
 *		Dumping HTML tree content to an I/O output buffer	*
 *									*
 ************************************************************************/

void xmlNsListDumpOutput(xmlOutputBufferPtr buf, xmlNsPtr cur);

/**
 * htmlDtdDumpOutput:
 * @buf:  the HTML buffer output
 * @doc:  the document
 * @encoding:  the encoding string
 *
 * TODO: check whether encoding is needed
 *
 * Dump the HTML document DTD, if any.
 */
static void
htmlDtdDumpOutput(xmlOutputBufferPtr buf, xmlDocPtr doc,
	          const char *encoding ATTRIBUTE_UNUSED) {
    xmlDtdPtr cur = doc->intSubset;

    if (cur == NULL) {
	htmlSaveErr(XML_SAVE_NO_DOCTYPE, (xmlNodePtr) doc, NULL);
	return;
    }
    xmlOutputBufferWriteString(buf, "<!DOCTYPE ");
    xmlOutputBufferWriteString(buf, (const char *)cur->name);
    if (cur->ExternalID != NULL) {
	xmlOutputBufferWriteString(buf, " PUBLIC ");
	xmlBufWriteQuotedString(buf->buffer, cur->ExternalID);
	if (cur->SystemID != NULL) {
	    xmlOutputBufferWriteString(buf, " ");
	    xmlBufWriteQuotedString(buf->buffer, cur->SystemID);
	}
    }  else if (cur->SystemID != NULL) {
	xmlOutputBufferWriteString(buf, " SYSTEM ");
	xmlBufWriteQuotedString(buf->buffer, cur->SystemID);
    }
    xmlOutputBufferWriteString(buf, ">\n");
}

/**
 * htmlAttrDumpOutput:
 * @buf:  the HTML buffer output
 * @doc:  the document
 * @cur:  the attribute pointer
 * @encoding:  the encoding string
 *
 * Dump an HTML attribute
 */
static void
htmlAttrDumpOutput(xmlOutputBufferPtr buf, xmlDocPtr doc, xmlAttrPtr cur,
	           const char *encoding ATTRIBUTE_UNUSED) {
    xmlChar *value;

    /*
     * The html output method should not escape a & character
     * occurring in an attribute value immediately followed by
     * a { character (see Section B.7.1 of the HTML 4.0 Recommendation).
     * This is implemented in xmlEncodeEntitiesReentrant
     */

    if (cur == NULL) {
	return;
    }
    xmlOutputBufferWriteString(buf, " ");
    if ((cur->ns != NULL) && (cur->ns->prefix != NULL)) {
        xmlOutputBufferWriteString(buf, (const char *)cur->ns->prefix);
	xmlOutputBufferWriteString(buf, ":");
    }
    xmlOutputBufferWriteString(buf, (const char *)cur->name);
    if ((cur->children != NULL) && (!htmlIsBooleanAttr(cur->name))) {
	value = xmlNodeListGetString(doc, cur->children, 0);
	if (value) {
	    xmlOutputBufferWriteString(buf, "=");
	    if ((cur->ns == NULL) && (cur->parent != NULL) &&
		(cur->parent->ns == NULL) &&
		((!xmlStrcasecmp(cur->name, BAD_CAST "href")) ||
	         (!xmlStrcasecmp(cur->name, BAD_CAST "action")) ||
		 (!xmlStrcasecmp(cur->name, BAD_CAST "src")) ||
		 ((!xmlStrcasecmp(cur->name, BAD_CAST "name")) &&
		  (!xmlStrcasecmp(cur->parent->name, BAD_CAST "a"))))) {
		xmlChar *tmp = value;
		/* xmlURIEscapeStr() escapes '"' so it can be safely used. */
		xmlBufCCat(buf->buffer, "\"");

		while (IS_BLANK_CH(*tmp)) tmp++;

		/* URI Escape everything, except server side includes. */
		for ( ; ; ) {
		    xmlChar *escaped;
		    xmlChar endChar;
		    xmlChar *end = NULL;
		    xmlChar *start = (xmlChar *)xmlStrstr(tmp, BAD_CAST "<!--");
		    if (start != NULL) {
			end = (xmlChar *)xmlStrstr(tmp, BAD_CAST "-->");
			if (end != NULL) {
			    *start = '\0';
			}
		    }

		    /* Escape the whole string, or until start (set to '\0'). */
		    escaped = xmlURIEscapeStr(tmp, BAD_CAST"@/:=?;#%&,+");
		    if (escaped != NULL) {
		        xmlBufCat(buf->buffer, escaped);
		        xmlFree(escaped);
		    } else {
		        xmlBufCat(buf->buffer, tmp);
		    }

		    if (end == NULL) { /* Everything has been written. */
			break;
		    }

		    /* Do not escape anything within server side includes. */
		    *start = '<'; /* Restore the first character of "<!--". */
		    end += 3; /* strlen("-->") */
		    endChar = *end;
		    *end = '\0';
		    xmlBufCat(buf->buffer, start);
		    *end = endChar;
		    tmp = end;
		}

		xmlBufCCat(buf->buffer, "\"");
	    } else {
		xmlBufWriteQuotedString(buf->buffer, value);
	    }
	    xmlFree(value);
	} else  {
	    xmlOutputBufferWriteString(buf, "=\"\"");
	}
    }
}

/**
 * htmlAttrListDumpOutput:
 * @buf:  the HTML buffer output
 * @doc:  the document
 * @cur:  the first attribute pointer
 * @encoding:  the encoding string
 *
 * Dump a list of HTML attributes
 */
static void
htmlAttrListDumpOutput(xmlOutputBufferPtr buf, xmlDocPtr doc, xmlAttrPtr cur, const char *encoding) {
    if (cur == NULL) {
	return;
    }
    while (cur != NULL) {
        htmlAttrDumpOutput(buf, doc, cur, encoding);
	cur = cur->next;
    }
}



/**
 * htmlNodeListDumpOutput:
 * @buf:  the HTML buffer output
 * @doc:  the document
 * @cur:  the first node
 * @encoding:  the encoding string
 * @format:  should formatting spaces been added
 *
 * Dump an HTML node list, recursive behaviour,children are printed too.
 */
static void
htmlNodeListDumpOutput(xmlOutputBufferPtr buf, xmlDocPtr doc,
	               xmlNodePtr cur, const char *encoding, int format) {
    if (cur == NULL) {
	return;
    }
    while (cur != NULL) {
        htmlNodeDumpFormatOutput(buf, doc, cur, encoding, format);
	cur = cur->next;
    }
}

/**
 * htmlNodeDumpFormatOutput:
 * @buf:  the HTML buffer output
 * @doc:  the document
 * @cur:  the current node
 * @encoding:  the encoding string
 * @format:  should formatting spaces been added
 *
 * Dump an HTML node, recursive behaviour,children are printed too.
 */
void
htmlNodeDumpFormatOutput(xmlOutputBufferPtr buf, xmlDocPtr doc,
	                 xmlNodePtr cur, const char *encoding, int format) {
    const htmlElemDesc * info;

    xmlInitParser();

    if ((cur == NULL) || (buf == NULL)) {
	return;
    }
    /*
     * Special cases.
     */
    if (cur->type == XML_DTD_NODE)
	return;
    if ((cur->type == XML_HTML_DOCUMENT_NODE) ||
        (cur->type == XML_DOCUMENT_NODE)){
	htmlDocContentDumpOutput(buf, (xmlDocPtr) cur, encoding);
	return;
    }
    if (cur->type == XML_ATTRIBUTE_NODE) {
        htmlAttrDumpOutput(buf, doc, (xmlAttrPtr) cur, encoding);
	return;
    }
    if (cur->type == HTML_TEXT_NODE) {
	if (cur->content != NULL) {
	    if (((cur->name == (const xmlChar *)xmlStringText) ||
		 (cur->name != (const xmlChar *)xmlStringTextNoenc)) &&
		((cur->parent == NULL) ||
		 ((xmlStrcasecmp(cur->parent->name, BAD_CAST "script")) &&
		  (xmlStrcasecmp(cur->parent->name, BAD_CAST "style"))))) {
		xmlChar *buffer;

		buffer = xmlEncodeEntitiesReentrant(doc, cur->content);
		if (buffer != NULL) {
		    xmlOutputBufferWriteString(buf, (const char *)buffer);
		    xmlFree(buffer);
		}
	    } else {
		xmlOutputBufferWriteString(buf, (const char *)cur->content);
	    }
	}
	return;
    }
    if (cur->type == HTML_COMMENT_NODE) {
	if (cur->content != NULL) {
	    xmlOutputBufferWriteString(buf, "<!--");
	    xmlOutputBufferWriteString(buf, (const char *)cur->content);
	    xmlOutputBufferWriteString(buf, "-->");
	}
	return;
    }
    if (cur->type == HTML_PI_NODE) {
	if (cur->name == NULL)
	    return;
	xmlOutputBufferWriteString(buf, "<?");
	xmlOutputBufferWriteString(buf, (const char *)cur->name);
	if (cur->content != NULL) {
	    xmlOutputBufferWriteString(buf, " ");
	    xmlOutputBufferWriteString(buf, (const char *)cur->content);
	}
	xmlOutputBufferWriteString(buf, ">");
	return;
    }
    if (cur->type == HTML_ENTITY_REF_NODE) {
        xmlOutputBufferWriteString(buf, "&");
	xmlOutputBufferWriteString(buf, (const char *)cur->name);
        xmlOutputBufferWriteString(buf, ";");
	return;
    }
    if (cur->type == HTML_PRESERVE_NODE) {
	if (cur->content != NULL) {
	    xmlOutputBufferWriteString(buf, (const char *)cur->content);
	}
	return;
    }

    /*
     * Get specific HTML info for that node.
     */
    if (cur->ns == NULL)
	info = htmlTagLookup(cur->name);
    else
	info = NULL;

    xmlOutputBufferWriteString(buf, "<");
    if ((cur->ns != NULL) && (cur->ns->prefix != NULL)) {
        xmlOutputBufferWriteString(buf, (const char *)cur->ns->prefix);
	xmlOutputBufferWriteString(buf, ":");
    }
    xmlOutputBufferWriteString(buf, (const char *)cur->name);
    if (cur->nsDef)
	xmlNsListDumpOutput(buf, cur->nsDef);
    if (cur->properties != NULL)
        htmlAttrListDumpOutput(buf, doc, cur->properties, encoding);

    if ((info != NULL) && (info->empty)) {
        xmlOutputBufferWriteString(buf, ">");
	if ((format) && (!info->isinline) && (cur->next != NULL)) {
	    if ((cur->next->type != HTML_TEXT_NODE) &&
		(cur->next->type != HTML_ENTITY_REF_NODE) &&
		(cur->parent != NULL) &&
		(cur->parent->name != NULL) &&
		(cur->parent->name[0] != 'p')) /* p, pre, param */
		xmlOutputBufferWriteString(buf, "\n");
	}
	return;
    }
    if (((cur->type == XML_ELEMENT_NODE) || (cur->content == NULL)) &&
	(cur->children == NULL)) {
        if ((info != NULL) && (info->saveEndTag != 0) &&
	    (xmlStrcmp(BAD_CAST info->name, BAD_CAST "html")) &&
	    (xmlStrcmp(BAD_CAST info->name, BAD_CAST "body"))) {
	    xmlOutputBufferWriteString(buf, ">");
	} else {
	    xmlOutputBufferWriteString(buf, "></");
            if ((cur->ns != NULL) && (cur->ns->prefix != NULL)) {
                xmlOutputBufferWriteString(buf, (const char *)cur->ns->prefix);
                xmlOutputBufferWriteString(buf, ":");
            }
	    xmlOutputBufferWriteString(buf, (const char *)cur->name);
	    xmlOutputBufferWriteString(buf, ">");
	}
	if ((format) && (cur->next != NULL) &&
            (info != NULL) && (!info->isinline)) {
	    if ((cur->next->type != HTML_TEXT_NODE) &&
		(cur->next->type != HTML_ENTITY_REF_NODE) &&
		(cur->parent != NULL) &&
		(cur->parent->name != NULL) &&
		(cur->parent->name[0] != 'p')) /* p, pre, param */
		xmlOutputBufferWriteString(buf, "\n");
	}
	return;
    }
    xmlOutputBufferWriteString(buf, ">");
    if ((cur->type != XML_ELEMENT_NODE) &&
	(cur->content != NULL)) {
	    /*
	     * Uses the OutputBuffer property to automatically convert
	     * invalids to charrefs
	     */

            xmlOutputBufferWriteString(buf, (const char *) cur->content);
    }
    if (cur->children != NULL) {
        if ((format) && (info != NULL) && (!info->isinline) &&
	    (cur->children->type != HTML_TEXT_NODE) &&
	    (cur->children->type != HTML_ENTITY_REF_NODE) &&
	    (cur->children != cur->last) &&
	    (cur->name != NULL) &&
	    (cur->name[0] != 'p')) /* p, pre, param */
	    xmlOutputBufferWriteString(buf, "\n");
	htmlNodeListDumpOutput(buf, doc, cur->children, encoding, format);
        if ((format) && (info != NULL) && (!info->isinline) &&
	    (cur->last->type != HTML_TEXT_NODE) &&
	    (cur->last->type != HTML_ENTITY_REF_NODE) &&
	    (cur->children != cur->last) &&
	    (cur->name != NULL) &&
	    (cur->name[0] != 'p')) /* p, pre, param */
	    xmlOutputBufferWriteString(buf, "\n");
    }
    xmlOutputBufferWriteString(buf, "</");
    if ((cur->ns != NULL) && (cur->ns->prefix != NULL)) {
        xmlOutputBufferWriteString(buf, (const char *)cur->ns->prefix);
	xmlOutputBufferWriteString(buf, ":");
    }
    xmlOutputBufferWriteString(buf, (const char *)cur->name);
    xmlOutputBufferWriteString(buf, ">");
    if ((format) && (info != NULL) && (!info->isinline) &&
	(cur->next != NULL)) {
        if ((cur->next->type != HTML_TEXT_NODE) &&
	    (cur->next->type != HTML_ENTITY_REF_NODE) &&
	    (cur->parent != NULL) &&
	    (cur->parent->name != NULL) &&
	    (cur->parent->name[0] != 'p')) /* p, pre, param */
	    xmlOutputBufferWriteString(buf, "\n");
    }
}

/**
 * htmlNodeDumpOutput:
 * @buf:  the HTML buffer output
 * @doc:  the document
 * @cur:  the current node
 * @encoding:  the encoding string
 *
 * Dump an HTML node, recursive behaviour,children are printed too,
 * and formatting returns/spaces are added.
 */
void
htmlNodeDumpOutput(xmlOutputBufferPtr buf, xmlDocPtr doc,
	           xmlNodePtr cur, const char *encoding) {
    htmlNodeDumpFormatOutput(buf, doc, cur, encoding, 1);
}

/**
 * htmlDocContentDumpFormatOutput:
 * @buf:  the HTML buffer output
 * @cur:  the document
 * @encoding:  the encoding string
 * @format:  should formatting spaces been added
 *
 * Dump an HTML document.
 */
void
htmlDocContentDumpFormatOutput(xmlOutputBufferPtr buf, xmlDocPtr cur,
	                       const char *encoding, int format) {
    int type;

    xmlInitParser();

    if ((buf == NULL) || (cur == NULL))
        return;

    /*
     * force to output the stuff as HTML, especially for entities
     */
    type = cur->type;
    cur->type = XML_HTML_DOCUMENT_NODE;
    if (cur->intSubset != NULL) {
        htmlDtdDumpOutput(buf, cur, NULL);
    }
    if (cur->children != NULL) {
        htmlNodeListDumpOutput(buf, cur, cur->children, encoding, format);
    }
    xmlOutputBufferWriteString(buf, "\n");
    cur->type = (xmlElementType) type;
}

/**
 * htmlDocContentDumpOutput:
 * @buf:  the HTML buffer output
 * @cur:  the document
 * @encoding:  the encoding string
 *
 * Dump an HTML document. Formating return/spaces are added.
 */
void
htmlDocContentDumpOutput(xmlOutputBufferPtr buf, xmlDocPtr cur,
	                 const char *encoding) {
    htmlDocContentDumpFormatOutput(buf, cur, encoding, 1);
}

/************************************************************************
 *									*
 *		Saving functions front-ends				*
 *									*
 ************************************************************************/

/**
 * htmlDocDump:
 * @f:  the FILE*
 * @cur:  the document
 *
 * Dump an HTML document to an open FILE.
 *
 * returns: the number of byte written or -1 in case of failure.
 */
int
htmlDocDump(FILE *f, xmlDocPtr cur) {
    xmlOutputBufferPtr buf;
    xmlCharEncodingHandlerPtr handler = NULL;
    const char *encoding;
    int ret;

    xmlInitParser();

    if ((cur == NULL) || (f == NULL)) {
	return(-1);
    }

    encoding = (const char *) htmlGetMetaEncoding(cur);

    if (encoding != NULL) {
	xmlCharEncoding enc;

	enc = xmlParseCharEncoding(encoding);
	if (enc != cur->charset) {
	    if (cur->charset != XML_CHAR_ENCODING_UTF8) {
		/*
		 * Not supported yet
		 */
		return(-1);
	    }

	    handler = xmlFindCharEncodingHandler(encoding);
	    if (handler == NULL)
		htmlSaveErr(XML_SAVE_UNKNOWN_ENCODING, NULL, encoding);
	} else {
	    handler = xmlFindCharEncodingHandler(encoding);
	}
    }

    /*
     * Fallback to HTML or ASCII when the encoding is unspecified
     */
    if (handler == NULL)
	handler = xmlFindCharEncodingHandler("HTML");
    if (handler == NULL)
	handler = xmlFindCharEncodingHandler("ascii");

    buf = xmlOutputBufferCreateFile(f, handler);
    if (buf == NULL) return(-1);
    htmlDocContentDumpOutput(buf, cur, NULL);

    ret = xmlOutputBufferClose(buf);
    return(ret);
}

/**
 * htmlSaveFile:
 * @filename:  the filename (or URL)
 * @cur:  the document
 *
 * Dump an HTML document to a file. If @filename is "-" the stdout file is
 * used.
 * returns: the number of byte written or -1 in case of failure.
 */
int
htmlSaveFile(const char *filename, xmlDocPtr cur) {
    xmlOutputBufferPtr buf;
    xmlCharEncodingHandlerPtr handler = NULL;
    const char *encoding;
    int ret;

    if ((cur == NULL) || (filename == NULL))
        return(-1);

    xmlInitParser();

    encoding = (const char *) htmlGetMetaEncoding(cur);

    if (encoding != NULL) {
	xmlCharEncoding enc;

	enc = xmlParseCharEncoding(encoding);
	if (enc != cur->charset) {
	    if (cur->charset != XML_CHAR_ENCODING_UTF8) {
		/*
		 * Not supported yet
		 */
		return(-1);
	    }

	    handler = xmlFindCharEncodingHandler(encoding);
	    if (handler == NULL)
		htmlSaveErr(XML_SAVE_UNKNOWN_ENCODING, NULL, encoding);
	}
    }

    /*
     * Fallback to HTML or ASCII when the encoding is unspecified
     */
    if (handler == NULL)
	handler = xmlFindCharEncodingHandler("HTML");
    if (handler == NULL)
	handler = xmlFindCharEncodingHandler("ascii");

    /*
     * save the content to a temp buffer.
     */
    buf = xmlOutputBufferCreateFilename(filename, handler, cur->compression);
    if (buf == NULL) return(0);

    htmlDocContentDumpOutput(buf, cur, NULL);

    ret = xmlOutputBufferClose(buf);
    return(ret);
}

/**
 * htmlSaveFileFormat:
 * @filename:  the filename
 * @cur:  the document
 * @format:  should formatting spaces been added
 * @encoding: the document encoding
 *
 * Dump an HTML document to a file using a given encoding.
 *
 * returns: the number of byte written or -1 in case of failure.
 */
int
htmlSaveFileFormat(const char *filename, xmlDocPtr cur,
	           const char *encoding, int format) {
    xmlOutputBufferPtr buf;
    xmlCharEncodingHandlerPtr handler = NULL;
    int ret;

    if ((cur == NULL) || (filename == NULL))
        return(-1);

    xmlInitParser();

    if (encoding != NULL) {
	xmlCharEncoding enc;

	enc = xmlParseCharEncoding(encoding);
	if (enc != cur->charset) {
	    if (cur->charset != XML_CHAR_ENCODING_UTF8) {
		/*
		 * Not supported yet
		 */
		return(-1);
	    }

	    handler = xmlFindCharEncodingHandler(encoding);
	    if (handler == NULL)
		htmlSaveErr(XML_SAVE_UNKNOWN_ENCODING, NULL, encoding);
	}
        htmlSetMetaEncoding(cur, (const xmlChar *) encoding);
    } else {
	htmlSetMetaEncoding(cur, (const xmlChar *) "UTF-8");
    }

    /*
     * Fallback to HTML or ASCII when the encoding is unspecified
     */
    if (handler == NULL)
	handler = xmlFindCharEncodingHandler("HTML");
    if (handler == NULL)
	handler = xmlFindCharEncodingHandler("ascii");

    /*
     * save the content to a temp buffer.
     */
    buf = xmlOutputBufferCreateFilename(filename, handler, 0);
    if (buf == NULL) return(0);

    htmlDocContentDumpFormatOutput(buf, cur, encoding, format);

    ret = xmlOutputBufferClose(buf);
    return(ret);
}

/**
 * htmlSaveFileEnc:
 * @filename:  the filename
 * @cur:  the document
 * @encoding: the document encoding
 *
 * Dump an HTML document to a file using a given encoding
 * and formatting returns/spaces are added.
 *
 * returns: the number of byte written or -1 in case of failure.
 */
int
htmlSaveFileEnc(const char *filename, xmlDocPtr cur, const char *encoding) {
    return(htmlSaveFileFormat(filename, cur, encoding, 1));
}

#endif /* LIBXML_OUTPUT_ENABLED */

#define bottom_HTMLtree
#include "elfgcchack.h"
#endif /* LIBXML_HTML_ENABLED */
