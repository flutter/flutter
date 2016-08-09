/*
 * Canonical XML implementation test program
 * (http://www.w3.org/TR/2001/REC-xml-c14n-20010315)
 *
 * See Copyright for the status of this software.
 * 
 * Author: Aleksey Sanin <aleksey@aleksey.com>
 */
#include "libxml.h"
#if defined(LIBXML_C14N_ENABLED) && defined(LIBXML_OUTPUT_ENABLED)

#include <stdio.h>
#include <string.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#include <libxml/xmlmemory.h>
#include <libxml/parser.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>

#include <libxml/c14n.h>


static void usage(const char *name) {
    fprintf(stderr,
	"Usage: %s <mode> <xml-file> [<xpath-expr>] [<inclusive-ns-list>]\n",
	    name);
    fprintf(stderr, "where <mode> is one of following:\n");
    fprintf(stderr,
	"--with-comments       \t XML file canonicalization v1.0 w comments \n");
    fprintf(stderr,
	"--without-comments    \t XML file canonicalization v1.0 w/o comments\n");
    fprintf(stderr,
	"--1-1-with-comments       \t XML file canonicalization v1.1 w comments\n");
    fprintf(stderr,
	"--1-1-without-comments    \t XML file canonicalization v1.1 w/o comments\n");
    fprintf(stderr,
    "--exc-with-comments   \t Exclusive XML file canonicalization v1.0 w comments\n");
    fprintf(stderr,
    "--exc-without-comments\t Exclusive XML file canonicalization v1.0 w/o comments\n");
}

static xmlXPathObjectPtr
load_xpath_expr (xmlDocPtr parent_doc, const char* filename);

static xmlChar **parse_list(xmlChar *str);

/* static void print_xpath_nodes(xmlNodeSetPtr nodes); */

static int 
test_c14n(const char* xml_filename, int with_comments, int mode,
	const char* xpath_filename, xmlChar **inclusive_namespaces) {
    xmlDocPtr doc;
    xmlXPathObjectPtr xpath = NULL; 
    xmlChar *result = NULL;
    int ret;

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

    /*
     * Canonical form
     */      
    /* fprintf(stderr,"File \"%s\" loaded: start canonization\n", xml_filename); */
    ret = xmlC14NDocDumpMemory(doc, 
	    (xpath) ? xpath->nodesetval : NULL, 
	    mode, inclusive_namespaces,
	    with_comments, &result);
    if(ret >= 0) {
	if(result != NULL) {
	    write(1, result, ret);
	    xmlFree(result);          
	}
    } else {
	fprintf(stderr,"Error: failed to canonicalize XML file \"%s\" (ret=%d)\n", xml_filename, ret);
	if(result != NULL) xmlFree(result);
	xmlFreeDoc(doc); 
	return(-1);
    }
        
    /*
     * Cleanup
     */ 
    if(xpath != NULL) xmlXPathFreeObject(xpath);
    xmlFreeDoc(doc);    

    return(ret);
}

int main(int argc, char **argv) {
    int ret = -1;
    
    /*
     * Init libxml
     */     
    xmlInitParser();
    LIBXML_TEST_VERSION

    /*
     * Parse command line and process file
     */
    if( argc < 3 ) {
	fprintf(stderr, "Error: wrong number of arguments.\n");
	usage(argv[0]);
    } else if(strcmp(argv[1], "--with-comments") == 0) {
	ret = test_c14n(argv[2], 1, XML_C14N_1_0, (argc > 3) ? argv[3] : NULL, NULL);
    } else if(strcmp(argv[1], "--without-comments") == 0) {
	ret = test_c14n(argv[2], 0, XML_C14N_1_0, (argc > 3) ? argv[3] : NULL, NULL);
    } else if(strcmp(argv[1], "--1-1-with-comments") == 0) {
	ret = test_c14n(argv[2], 1, XML_C14N_1_1, (argc > 3) ? argv[3] : NULL, NULL);
    } else if(strcmp(argv[1], "--1-1-without-comments") == 0) {
	ret = test_c14n(argv[2], 0, XML_C14N_1_1, (argc > 3) ? argv[3] : NULL, NULL);
    } else if(strcmp(argv[1], "--exc-with-comments") == 0) {
	xmlChar **list;
	
	/* load exclusive namespace from command line */
	list = (argc > 4) ? parse_list((xmlChar *)argv[4]) : NULL;
	ret = test_c14n(argv[2], 1, XML_C14N_EXCLUSIVE_1_0, (argc > 3) ? argv[3] : NULL, list);
	if(list != NULL) xmlFree(list);
    } else if(strcmp(argv[1], "--exc-without-comments") == 0) {
	xmlChar **list;
	
	/* load exclusive namespace from command line */
	list = (argc > 4) ? parse_list((xmlChar *)argv[4]) : NULL;
	ret = test_c14n(argv[2], 0, XML_C14N_EXCLUSIVE_1_0, (argc > 3) ? argv[3] : NULL, list);
	if(list != NULL) xmlFree(list);
    } else {
	fprintf(stderr, "Error: bad option.\n");
	usage(argv[0]);
    }

    /* 
     * Shutdown libxml
     */
    xmlCleanupParser();
    xmlMemoryDump();

    return((ret >= 0) ? 0 : 1);
}

/*
 * Macro used to grow the current buffer.
 */
#define growBufferReentrant() {						\
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

	    growBufferReentrant();
	    out = &buffer[indx];
	}
	(*out++) = str;
	while(*str != ',' && *str != '\0') ++str;
	if(*str == ',') *(str++) = '\0';
    }
    (*out) = NULL;
    return buffer;
}

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
static void
print_xpath_nodes(xmlNodeSetPtr nodes) {
    xmlNodePtr cur;
    int i;
    
    if(nodes == NULL ){ 
	fprintf(stderr, "Error: no nodes set defined\n");
	return;
    }
    
    fprintf(stderr, "Nodes Set:\n-----\n");
    for(i = 0; i < nodes->nodeNr; ++i) {
	if(nodes->nodeTab[i]->type == XML_NAMESPACE_DECL) {
	    xmlNsPtr ns;
	    
	    ns = (xmlNsPtr)nodes->nodeTab[i];
	    cur = (xmlNodePtr)ns->next;
	    fprintf(stderr, "namespace \"%s\"=\"%s\" for node %s:%s\n", 
		    ns->prefix, ns->href,
		    (cur->ns) ? cur->ns->prefix : BAD_CAST "", cur->name);
	} else if(nodes->nodeTab[i]->type == XML_ELEMENT_NODE) {
	    cur = nodes->nodeTab[i];    
	    fprintf(stderr, "element node \"%s:%s\"\n", 
		    (cur->ns) ? cur->ns->prefix : BAD_CAST "", cur->name);
	} else {
	    cur = nodes->nodeTab[i];    
	    fprintf(stderr, "node \"%s\": type %d\n", cur->name, cur->type);
	}
    }
}
*/

#else
#include <stdio.h>
int main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    printf("%s : XPath/Canonicalization and output support not compiled in\n", argv[0]);
    return(0);
}
#endif /* LIBXML_C14N_ENABLED */


