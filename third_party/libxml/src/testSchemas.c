/*
 * testSchemas.c : a small tester program for Schema validation
 *
 * See Copyright for the status of this software.
 *
 * Daniel.Veillard@w3.org
 */

#include "libxml.h"
#ifdef LIBXML_SCHEMAS_ENABLED

#include <libxml/xmlversion.h>
#include <libxml/parser.h>

#include <stdio.h>
#include <string.h>
#include <stdarg.h>


#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_SYS_MMAN_H
#include <sys/mman.h>
/* seems needed for Solaris */
#ifndef MAP_FAILED
#define MAP_FAILED ((void *) -1)
#endif
#endif

#include <libxml/xmlmemory.h>
#include <libxml/debugXML.h>
#include <libxml/xmlschemas.h>
#include <libxml/xmlschemastypes.h>

#ifdef LIBXML_DEBUG_ENABLED
static int debug = 0;
#endif
static int noout = 0;
#ifdef HAVE_MMAP
static int memory = 0;
#endif


int main(int argc, char **argv) {
    int i;
    int files = 0;
    xmlSchemaPtr schema = NULL;

    for (i = 1; i < argc ; i++) {
#ifdef LIBXML_DEBUG_ENABLED
	if ((!strcmp(argv[i], "-debug")) || (!strcmp(argv[i], "--debug")))
	    debug++;
	else
#endif
#ifdef HAVE_MMAP
	if ((!strcmp(argv[i], "-memory")) || (!strcmp(argv[i], "--memory"))) {
	    memory++;
        } else
#endif
	if ((!strcmp(argv[i], "-noout")) || (!strcmp(argv[i], "--noout"))) {
	    noout++;
        }
    }
    xmlLineNumbersDefault(1);
    for (i = 1; i < argc ; i++) {
	if (argv[i][0] != '-') {
	    if (schema == NULL) {
		xmlSchemaParserCtxtPtr ctxt;

#ifdef HAVE_MMAP
		if (memory) {
		    int fd;
		    struct stat info;
		    const char *base;
		    if (stat(argv[i], &info) < 0)
			break;
		    if ((fd = open(argv[i], O_RDONLY)) < 0)
			break;
		    base = mmap(NULL, info.st_size, PROT_READ,
			        MAP_SHARED, fd, 0) ;
		    if (base == (void *) MAP_FAILED)
			break;

		    ctxt = xmlSchemaNewMemParserCtxt((char *)base,info.st_size);

		    xmlSchemaSetParserErrors(ctxt,
			    (xmlSchemaValidityErrorFunc) fprintf,
			    (xmlSchemaValidityWarningFunc) fprintf,
			    stderr);
		    schema = xmlSchemaParse(ctxt);
		    xmlSchemaFreeParserCtxt(ctxt);
		    munmap((char *) base, info.st_size);
		} else
#endif
		{
		    ctxt = xmlSchemaNewParserCtxt(argv[i]);
		    xmlSchemaSetParserErrors(ctxt,
			    (xmlSchemaValidityErrorFunc) fprintf,
			    (xmlSchemaValidityWarningFunc) fprintf,
			    stderr);
		    schema = xmlSchemaParse(ctxt);
		    xmlSchemaFreeParserCtxt(ctxt);
		}
#ifdef LIBXML_OUTPUT_ENABLED
#ifdef LIBXML_DEBUG_ENABLED
		if (debug)
		    xmlSchemaDump(stdout, schema);
#endif
#endif /* LIBXML_OUTPUT_ENABLED */
		if (schema == NULL)
		    goto failed_schemas;
	    } else {
		xmlDocPtr doc;

		doc = xmlReadFile(argv[i],NULL,0);

		if (doc == NULL) {
		    fprintf(stderr, "Could not parse %s\n", argv[i]);
		} else {
		    xmlSchemaValidCtxtPtr ctxt;
		    int ret;

		    ctxt = xmlSchemaNewValidCtxt(schema);
		    xmlSchemaSetValidErrors(ctxt,
			    (xmlSchemaValidityErrorFunc) fprintf,
			    (xmlSchemaValidityWarningFunc) fprintf,
			    stderr);
		    ret = xmlSchemaValidateDoc(ctxt, doc);
		    if (ret == 0) {
			printf("%s validates\n", argv[i]);
		    } else if (ret > 0) {
			printf("%s fails to validate\n", argv[i]);
		    } else {
			printf("%s validation generated an internal error\n",
			       argv[i]);
		    }
		    xmlSchemaFreeValidCtxt(ctxt);
		    xmlFreeDoc(doc);
		}
	    }
	    files ++;
	}
    }
    if (schema != NULL)
	xmlSchemaFree(schema);
    if (files == 0) {
	printf("Usage : %s [--debug] [--noout] schemas XMLfiles ...\n",
	       argv[0]);
	printf("\tParse the HTML files and output the result of the parsing\n");
#ifdef LIBXML_DEBUG_ENABLED
	printf("\t--debug : dump a debug tree of the in-memory document\n");
#endif
	printf("\t--noout : do not print the result\n");
#ifdef HAVE_MMAP
	printf("\t--memory : test the schemas in memory parsing\n");
#endif
    }
failed_schemas:
    xmlSchemaCleanupTypes();
    xmlCleanupParser();
    xmlMemoryDump();

    return(0);
}

#else
#include <stdio.h>
int main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    printf("%s : Schemas support not compiled in\n", argv[0]);
    return(0);
}
#endif /* LIBXML_SCHEMAS_ENABLED */
