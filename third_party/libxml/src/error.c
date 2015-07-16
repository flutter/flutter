/*
 * error.c: module displaying/handling XML parser errors
 *
 * See Copyright for the status of this software.
 *
 * Daniel Veillard <daniel@veillard.com>
 */

#define IN_LIBXML
#include "libxml.h"

#include <string.h>
#include <stdarg.h>
#include <libxml/parser.h>
#include <libxml/xmlerror.h>
#include <libxml/xmlmemory.h>
#include <libxml/globals.h>

void XMLCDECL xmlGenericErrorDefaultFunc	(void *ctx ATTRIBUTE_UNUSED,
				 const char *msg,
				 ...);

#define XML_GET_VAR_STR(msg, str) {				\
    int       size, prev_size = -1;				\
    int       chars;						\
    char      *larger;						\
    va_list   ap;						\
								\
    str = (char *) xmlMalloc(150);				\
    if (str != NULL) {						\
								\
    size = 150;							\
								\
    while (size < 64000) {					\
	va_start(ap, msg);					\
  	chars = vsnprintf(str, size, msg, ap);			\
	va_end(ap);						\
	if ((chars > -1) && (chars < size)) {			\
	    if (prev_size == chars) {				\
		break;						\
	    } else {						\
		prev_size = chars;				\
	    }							\
	}							\
	if (chars > -1)						\
	    size += chars + 1;					\
	else							\
	    size += 100;					\
	if ((larger = (char *) xmlRealloc(str, size)) == NULL) {\
	    break;						\
	}							\
	str = larger;						\
    }}								\
}

/************************************************************************
 * 									*
 * 			Handling of out of context errors		*
 * 									*
 ************************************************************************/

/**
 * xmlGenericErrorDefaultFunc:
 * @ctx:  an error context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 * 
 * Default handler for out of context error messages.
 */
void XMLCDECL
xmlGenericErrorDefaultFunc(void *ctx ATTRIBUTE_UNUSED, const char *msg, ...) {
    va_list args;

    if (xmlGenericErrorContext == NULL)
	xmlGenericErrorContext = (void *) stderr;

    va_start(args, msg);
    vfprintf((FILE *)xmlGenericErrorContext, msg, args);
    va_end(args);
}

/**
 * initGenericErrorDefaultFunc:
 * @handler:  the handler
 * 
 * Set or reset (if NULL) the default handler for generic errors
 * to the builtin error function.
 */
void
initGenericErrorDefaultFunc(xmlGenericErrorFunc * handler)
{
    if (handler == NULL)
        xmlGenericError = xmlGenericErrorDefaultFunc;
    else
        xmlGenericError = (*handler);
}

/**
 * xmlSetGenericErrorFunc:
 * @ctx:  the new error handling context
 * @handler:  the new handler function
 *
 * Function to reset the handler and the error context for out of
 * context error messages.
 * This simply means that @handler will be called for subsequent
 * error messages while not parsing nor validating. And @ctx will
 * be passed as first argument to @handler
 * One can simply force messages to be emitted to another FILE * than
 * stderr by setting @ctx to this file handle and @handler to NULL.
 * For multi-threaded applications, this must be set separately for each thread.
 */
void
xmlSetGenericErrorFunc(void *ctx, xmlGenericErrorFunc handler) {
    xmlGenericErrorContext = ctx;
    if (handler != NULL)
	xmlGenericError = handler;
    else
	xmlGenericError = xmlGenericErrorDefaultFunc;
}

/**
 * xmlSetStructuredErrorFunc:
 * @ctx:  the new error handling context
 * @handler:  the new handler function
 *
 * Function to reset the handler and the error context for out of
 * context structured error messages.
 * This simply means that @handler will be called for subsequent
 * error messages while not parsing nor validating. And @ctx will
 * be passed as first argument to @handler
 * For multi-threaded applications, this must be set separately for each thread.
 */
void
xmlSetStructuredErrorFunc(void *ctx, xmlStructuredErrorFunc handler) {
    xmlStructuredErrorContext = ctx;
    xmlStructuredError = handler;
}

/************************************************************************
 * 									*
 * 			Handling of parsing errors			*
 * 									*
 ************************************************************************/

/**
 * xmlParserPrintFileInfo:
 * @input:  an xmlParserInputPtr input
 * 
 * Displays the associated file and line informations for the current input
 */

void
xmlParserPrintFileInfo(xmlParserInputPtr input) {
    if (input != NULL) {
	if (input->filename)
	    xmlGenericError(xmlGenericErrorContext,
		    "%s:%d: ", input->filename,
		    input->line);
	else
	    xmlGenericError(xmlGenericErrorContext,
		    "Entity: line %d: ", input->line);
    }
}

/**
 * xmlParserPrintFileContext:
 * @input:  an xmlParserInputPtr input
 * 
 * Displays current context within the input content for error tracking
 */

static void
xmlParserPrintFileContextInternal(xmlParserInputPtr input , 
		xmlGenericErrorFunc channel, void *data ) {
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
    channel(data ,"%s\n", content);
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
    channel(data ,"%s\n", content);
}

/**
 * xmlParserPrintFileContext:
 * @input:  an xmlParserInputPtr input
 * 
 * Displays current context within the input content for error tracking
 */
void
xmlParserPrintFileContext(xmlParserInputPtr input) {
   xmlParserPrintFileContextInternal(input, xmlGenericError,
                                     xmlGenericErrorContext);
}

/**
 * xmlReportError:
 * @err: the error
 * @ctx: the parser context or NULL
 * @str: the formatted error message
 *
 * Report an erro with its context, replace the 4 old error/warning
 * routines.
 */
static void
xmlReportError(xmlErrorPtr err, xmlParserCtxtPtr ctxt, const char *str,
               xmlGenericErrorFunc channel, void *data)
{
    char *file = NULL;
    int line = 0;
    int code = -1;
    int domain;
    const xmlChar *name = NULL;
    xmlNodePtr node;
    xmlErrorLevel level;
    xmlParserInputPtr input = NULL;
    xmlParserInputPtr cur = NULL;

    if (err == NULL)
        return;

    if (channel == NULL) {
	channel = xmlGenericError;
	data = xmlGenericErrorContext;
    }
    file = err->file;
    line = err->line;
    code = err->code;
    domain = err->domain;
    level = err->level;
    node = err->node;

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
        case XML_FROM_I18N:
            channel(data, "encoding ");
            break;
        default:
            break;
    }
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

/**
 * __xmlRaiseError:
 * @schannel: the structured callback channel
 * @channel: the old callback channel
 * @data: the callback data
 * @ctx: the parser context or NULL
 * @ctx: the parser context or NULL
 * @domain: the domain for the error
 * @code: the code for the error
 * @level: the xmlErrorLevel for the error
 * @file: the file source of the error (or NULL)
 * @line: the line of the error or 0 if N/A
 * @str1: extra string info
 * @str2: extra string info
 * @str3: extra string info
 * @int1: extra int info
 * @col: column number of the error or 0 if N/A 
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Update the appropriate global or contextual error structure,
 * then forward the error message down the parser or generic
 * error callback handler
 */
void XMLCDECL
__xmlRaiseError(xmlStructuredErrorFunc schannel,
              xmlGenericErrorFunc channel, void *data, void *ctx,
              void *nod, int domain, int code, xmlErrorLevel level,
              const char *file, int line, const char *str1,
              const char *str2, const char *str3, int int1, int col,
	      const char *msg, ...)
{
    xmlParserCtxtPtr ctxt = NULL;
    xmlNodePtr node = (xmlNodePtr) nod;
    char *str = NULL;
    xmlParserInputPtr input = NULL;
    xmlErrorPtr to = &xmlLastError;
    xmlNodePtr baseptr = NULL;

    if ((xmlGetWarningsDefaultValue == 0) && (level == XML_ERR_WARNING))
        return;
    if ((domain == XML_FROM_PARSER) || (domain == XML_FROM_HTML) ||
        (domain == XML_FROM_DTD) || (domain == XML_FROM_NAMESPACE) ||
	(domain == XML_FROM_IO) || (domain == XML_FROM_VALID)) {
	ctxt = (xmlParserCtxtPtr) ctx;
	if ((schannel == NULL) && (ctxt != NULL) && (ctxt->sax != NULL) &&
	    (ctxt->sax->initialized == XML_SAX2_MAGIC))
	    schannel = ctxt->sax->serror;
    }
    /*
     * Check if structured error handler set
     */
    if (schannel == NULL) {
	schannel = xmlStructuredError;
	/*
	 * if user has defined handler, change data ptr to user's choice
	 */
	if (schannel != NULL)
	    data = xmlStructuredErrorContext;
    }
    if ((domain == XML_FROM_VALID) &&
        ((channel == xmlParserValidityError) ||
	 (channel == xmlParserValidityWarning))) {
	ctxt = (xmlParserCtxtPtr) ctx;
	if ((schannel == NULL) && (ctxt != NULL) && (ctxt->sax != NULL) &&
	    (ctxt->sax->initialized == XML_SAX2_MAGIC))
	    schannel = ctxt->sax->serror;
    }
    if (code == XML_ERR_OK)
        return;
    /*
     * Formatting the message
     */
    if (msg == NULL) {
        str = (char *) xmlStrdup(BAD_CAST "No error message provided");
    } else {
        XML_GET_VAR_STR(msg, str);
    }

    /*
     * specific processing if a parser context is provided
     */
    if (ctxt != NULL) {
        if (file == NULL) {
            input = ctxt->input;
            if ((input != NULL) && (input->filename == NULL) &&
                (ctxt->inputNr > 1)) {
                input = ctxt->inputTab[ctxt->inputNr - 2];
            }
            if (input != NULL) {
                file = input->filename;
                line = input->line;
                col = input->col;
            }
        }
        to = &ctxt->lastError;
    } else if ((node != NULL) && (file == NULL)) {
	int i;

	if ((node->doc != NULL) && (node->doc->URL != NULL)) {
	    baseptr = node;
/*	    file = (const char *) node->doc->URL; */
	}
	for (i = 0;
	     ((i < 10) && (node != NULL) && (node->type != XML_ELEMENT_NODE));
	     i++)
	     node = node->parent;
        if ((baseptr == NULL) && (node != NULL) &&
	    (node->doc != NULL) && (node->doc->URL != NULL))
	    baseptr = node;

	if ((node != NULL) && (node->type == XML_ELEMENT_NODE))
	    line = node->line;
    }

    /*
     * Save the information about the error
     */
    xmlResetError(to);
    to->domain = domain;
    to->code = code;
    to->message = str;
    to->level = level;
    if (file != NULL)
        to->file = (char *) xmlStrdup((const xmlChar *) file);
    else if (baseptr != NULL) {
#ifdef LIBXML_XINCLUDE_ENABLED
	/*
	 * We check if the error is within an XInclude section and,
	 * if so, attempt to print out the href of the XInclude instead
	 * of the usual "base" (doc->URL) for the node (bug 152623).
	 */
        xmlNodePtr prev = baseptr;
	int inclcount = 0;
	while (prev != NULL) {
	    if (prev->prev == NULL)
	        prev = prev->parent;
	    else {
	        prev = prev->prev;
		if (prev->type == XML_XINCLUDE_START) {
		    if (--inclcount < 0)
		        break;
		} else if (prev->type == XML_XINCLUDE_END)
		    inclcount++;
	    }
	}
	if (prev != NULL) {
	    if (prev->type == XML_XINCLUDE_START) {
		prev->type = XML_ELEMENT_NODE;
		to->file = (char *) xmlGetProp(prev, BAD_CAST "href");
		prev->type = XML_XINCLUDE_START;
	    } else {
		to->file = (char *) xmlGetProp(prev, BAD_CAST "href");
	    }
	} else
#endif
	    to->file = (char *) xmlStrdup(baseptr->doc->URL);
	if ((to->file == NULL) && (node != NULL) && (node->doc != NULL)) {
	    to->file = (char *) xmlStrdup(node->doc->URL);
	}
    }
    to->line = line;
    if (str1 != NULL)
        to->str1 = (char *) xmlStrdup((const xmlChar *) str1);
    if (str2 != NULL)
        to->str2 = (char *) xmlStrdup((const xmlChar *) str2);
    if (str3 != NULL)
        to->str3 = (char *) xmlStrdup((const xmlChar *) str3);
    to->int1 = int1;
    to->int2 = col;
    to->node = node;
    to->ctxt = ctx;

    if (to != &xmlLastError)
        xmlCopyError(to,&xmlLastError);

    /*
     * Find the callback channel if channel param is NULL
     */
    if ((ctxt != NULL) && (channel == NULL) &&
        (xmlStructuredError == NULL) && (ctxt->sax != NULL)) {
        if (level == XML_ERR_WARNING)
	    channel = ctxt->sax->warning;
        else
	    channel = ctxt->sax->error;
	data = ctxt->userData;
    } else if (channel == NULL) {
        if ((schannel == NULL) && (xmlStructuredError != NULL)) {
	    schannel = xmlStructuredError;
	    data = xmlStructuredErrorContext;
	} else {
	    channel = xmlGenericError;
	    if (!data) {
		data = xmlGenericErrorContext;
	    }
	}
    }
    if (schannel != NULL) {
        schannel(data, to);
	return;
    }
    if (channel == NULL)
        return;

    if ((channel == xmlParserError) ||
        (channel == xmlParserWarning) ||
	(channel == xmlParserValidityError) ||
	(channel == xmlParserValidityWarning))
	xmlReportError(to, ctxt, str, NULL, NULL);
    else if ((channel == (xmlGenericErrorFunc) fprintf) ||
             (channel == xmlGenericErrorDefaultFunc))
	xmlReportError(to, ctxt, str, channel, data);
    else
	channel(data, "%s", str);
}

/**
 * __xmlSimpleError:
 * @domain: where the error comes from
 * @code: the error code
 * @node: the context node
 * @extra:  extra informations
 *
 * Handle an out of memory condition
 */
void
__xmlSimpleError(int domain, int code, xmlNodePtr node,
                 const char *msg, const char *extra)
{

    if (code == XML_ERR_NO_MEMORY) {
	if (extra)
	    __xmlRaiseError(NULL, NULL, NULL, NULL, node, domain,
			    XML_ERR_NO_MEMORY, XML_ERR_FATAL, NULL, 0, extra,
			    NULL, NULL, 0, 0,
			    "Memory allocation failed : %s\n", extra);
	else
	    __xmlRaiseError(NULL, NULL, NULL, NULL, node, domain,
			    XML_ERR_NO_MEMORY, XML_ERR_FATAL, NULL, 0, NULL,
			    NULL, NULL, 0, 0, "Memory allocation failed\n");
    } else {
	__xmlRaiseError(NULL, NULL, NULL, NULL, node, domain,
			code, XML_ERR_ERROR, NULL, 0, extra,
			NULL, NULL, 0, 0, msg, extra);
    }
}
/**
 * xmlParserError:
 * @ctx:  an XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 * 
 * Display and format an error messages, gives file, line, position and
 * extra parameters.
 */
void XMLCDECL
xmlParserError(void *ctx, const char *msg, ...)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlParserInputPtr input = NULL;
    xmlParserInputPtr cur = NULL;
    char * str;

    if (ctxt != NULL) {
	input = ctxt->input;
	if ((input != NULL) && (input->filename == NULL) &&
	    (ctxt->inputNr > 1)) {
	    cur = input;
	    input = ctxt->inputTab[ctxt->inputNr - 2];
	}
	xmlParserPrintFileInfo(input);
    }

    xmlGenericError(xmlGenericErrorContext, "error: ");
    XML_GET_VAR_STR(msg, str);
    xmlGenericError(xmlGenericErrorContext, "%s", str);
    if (str != NULL)
	xmlFree(str);

    if (ctxt != NULL) {
	xmlParserPrintFileContext(input);
	if (cur != NULL) {
	    xmlParserPrintFileInfo(cur);
	    xmlGenericError(xmlGenericErrorContext, "\n");
	    xmlParserPrintFileContext(cur);
	}
    }
}

/**
 * xmlParserWarning:
 * @ctx:  an XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 * 
 * Display and format a warning messages, gives file, line, position and
 * extra parameters.
 */
void XMLCDECL
xmlParserWarning(void *ctx, const char *msg, ...)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlParserInputPtr input = NULL;
    xmlParserInputPtr cur = NULL;
    char * str;

    if (ctxt != NULL) {
	input = ctxt->input;
	if ((input != NULL) && (input->filename == NULL) &&
	    (ctxt->inputNr > 1)) {
	    cur = input;
	    input = ctxt->inputTab[ctxt->inputNr - 2];
	}
	xmlParserPrintFileInfo(input);
    }
        
    xmlGenericError(xmlGenericErrorContext, "warning: ");
    XML_GET_VAR_STR(msg, str);
    xmlGenericError(xmlGenericErrorContext, "%s", str);
    if (str != NULL)
	xmlFree(str);

    if (ctxt != NULL) {
	xmlParserPrintFileContext(input);
	if (cur != NULL) {
	    xmlParserPrintFileInfo(cur);
	    xmlGenericError(xmlGenericErrorContext, "\n");
	    xmlParserPrintFileContext(cur);
	}
    }
}

/************************************************************************
 * 									*
 * 			Handling of validation errors			*
 * 									*
 ************************************************************************/

/**
 * xmlParserValidityError:
 * @ctx:  an XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 * 
 * Display and format an validity error messages, gives file,
 * line, position and extra parameters.
 */
void XMLCDECL
xmlParserValidityError(void *ctx, const char *msg, ...)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlParserInputPtr input = NULL;
    char * str;
    int len = xmlStrlen((const xmlChar *) msg);
    static int had_info = 0;

    if ((len > 1) && (msg[len - 2] != ':')) {
	if (ctxt != NULL) {
	    input = ctxt->input;
	    if ((input->filename == NULL) && (ctxt->inputNr > 1))
		input = ctxt->inputTab[ctxt->inputNr - 2];
		
	    if (had_info == 0) {
		xmlParserPrintFileInfo(input);
	    }
	}
	xmlGenericError(xmlGenericErrorContext, "validity error: ");
	had_info = 0;
    } else {
	had_info = 1;
    }

    XML_GET_VAR_STR(msg, str);
    xmlGenericError(xmlGenericErrorContext, "%s", str);
    if (str != NULL)
	xmlFree(str);

    if ((ctxt != NULL) && (input != NULL)) {
	xmlParserPrintFileContext(input);
    }
}

/**
 * xmlParserValidityWarning:
 * @ctx:  an XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 * 
 * Display and format a validity warning messages, gives file, line,
 * position and extra parameters.
 */
void XMLCDECL
xmlParserValidityWarning(void *ctx, const char *msg, ...)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlParserInputPtr input = NULL;
    char * str;
    int len = xmlStrlen((const xmlChar *) msg);

    if ((ctxt != NULL) && (len != 0) && (msg[len - 1] != ':')) {
	input = ctxt->input;
	if ((input->filename == NULL) && (ctxt->inputNr > 1))
	    input = ctxt->inputTab[ctxt->inputNr - 2];

	xmlParserPrintFileInfo(input);
    }
        
    xmlGenericError(xmlGenericErrorContext, "validity warning: ");
    XML_GET_VAR_STR(msg, str);
    xmlGenericError(xmlGenericErrorContext, "%s", str);
    if (str != NULL)
	xmlFree(str);

    if (ctxt != NULL) {
	xmlParserPrintFileContext(input);
    }
}


/************************************************************************
 *									*
 *			Extended Error Handling				*
 *									*
 ************************************************************************/

/**
 * xmlGetLastError:
 *
 * Get the last global error registered. This is per thread if compiled
 * with thread support.
 *
 * Returns NULL if no error occured or a pointer to the error
 */
xmlErrorPtr
xmlGetLastError(void)
{
    if (xmlLastError.code == XML_ERR_OK)
        return (NULL);
    return (&xmlLastError);
}

/**
 * xmlResetError:
 * @err: pointer to the error.
 *
 * Cleanup the error.
 */
void
xmlResetError(xmlErrorPtr err)
{
    if (err == NULL)
        return;
    if (err->code == XML_ERR_OK)
        return;
    if (err->message != NULL)
        xmlFree(err->message);
    if (err->file != NULL)
        xmlFree(err->file);
    if (err->str1 != NULL)
        xmlFree(err->str1);
    if (err->str2 != NULL)
        xmlFree(err->str2);
    if (err->str3 != NULL)
        xmlFree(err->str3);
    memset(err, 0, sizeof(xmlError));
    err->code = XML_ERR_OK;
}

/**
 * xmlResetLastError:
 *
 * Cleanup the last global error registered. For parsing error
 * this does not change the well-formedness result.
 */
void
xmlResetLastError(void)
{
    if (xmlLastError.code == XML_ERR_OK)
        return;
    xmlResetError(&xmlLastError);
}

/**
 * xmlCtxtGetLastError:
 * @ctx:  an XML parser context
 *
 * Get the last parsing error registered.
 *
 * Returns NULL if no error occured or a pointer to the error
 */
xmlErrorPtr
xmlCtxtGetLastError(void *ctx)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;

    if (ctxt == NULL)
        return (NULL);
    if (ctxt->lastError.code == XML_ERR_OK)
        return (NULL);
    return (&ctxt->lastError);
}

/**
 * xmlCtxtResetLastError:
 * @ctx:  an XML parser context
 *
 * Cleanup the last global error registered. For parsing error
 * this does not change the well-formedness result.
 */
void
xmlCtxtResetLastError(void *ctx)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;

    if (ctxt == NULL)
        return;
    ctxt->errNo = XML_ERR_OK;
    if (ctxt->lastError.code == XML_ERR_OK)
        return;
    xmlResetError(&ctxt->lastError);
}

/**
 * xmlCopyError:
 * @from:  a source error
 * @to:  a target error
 *
 * Save the original error to the new place.
 *
 * Returns 0 in case of success and -1 in case of error.
 */
int
xmlCopyError(xmlErrorPtr from, xmlErrorPtr to) {
    char *message, *file, *str1, *str2, *str3;

    if ((from == NULL) || (to == NULL))
        return(-1);

    message = (char *) xmlStrdup((xmlChar *) from->message);
    file = (char *) xmlStrdup ((xmlChar *) from->file);
    str1 = (char *) xmlStrdup ((xmlChar *) from->str1);
    str2 = (char *) xmlStrdup ((xmlChar *) from->str2);
    str3 = (char *) xmlStrdup ((xmlChar *) from->str3);

    if (to->message != NULL)
        xmlFree(to->message);
    if (to->file != NULL)
        xmlFree(to->file);
    if (to->str1 != NULL)
        xmlFree(to->str1);
    if (to->str2 != NULL)
        xmlFree(to->str2);
    if (to->str3 != NULL)
        xmlFree(to->str3);
    to->domain = from->domain;
    to->code = from->code;
    to->level = from->level;
    to->line = from->line;
    to->node = from->node;
    to->int1 = from->int1;
    to->int2 = from->int2;
    to->node = from->node;
    to->ctxt = from->ctxt;
    to->message = message;
    to->file = file;
    to->str1 = str1;
    to->str2 = str2;
    to->str3 = str3;

    return 0;
}

#define bottom_error
#include "elfgcchack.h"
