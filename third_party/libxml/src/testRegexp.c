/*
 * testRegexp.c: simple module for testing regular expressions
 *
 * See Copyright for the status of this software.
 *
 * Daniel Veillard <veillard@redhat.com>
 */

#include "libxml.h"
#ifdef LIBXML_REGEXP_ENABLED
#include <string.h>

#include <libxml/tree.h>
#include <libxml/xmlregexp.h>

static int repeat = 0;
static int debug = 0;

static void testRegexp(xmlRegexpPtr comp, const char *value) {
    int ret;

    ret = xmlRegexpExec(comp, (const xmlChar *) value);
    if (ret == 1)
	printf("%s: Ok\n", value);
    else if (ret == 0)
	printf("%s: Fail\n", value);
    else
	printf("%s: Error: %d\n", value, ret);
    if (repeat) {
	int j;
	for (j = 0;j < 999999;j++)
	    xmlRegexpExec(comp, (const xmlChar *) value);
    }
}

static void
testRegexpFile(const char *filename) {
    xmlRegexpPtr comp = NULL;
    FILE *input;
    char expression[5000];
    int len;

    input = fopen(filename, "r");
    if (input == NULL) {
        xmlGenericError(xmlGenericErrorContext,
		"Cannot open %s for reading\n", filename);
	return;
    }
    while (fgets(expression, 4500, input) != NULL) {
	len = strlen(expression);
	len--;
	while ((len >= 0) && 
	       ((expression[len] == '\n') || (expression[len] == '\t') ||
		(expression[len] == '\r') || (expression[len] == ' '))) len--;
	expression[len + 1] = 0;      
	if (len >= 0) {
	    if (expression[0] == '#')
		continue;
	    if ((expression[0] == '=') && (expression[1] == '>')) {
		char *pattern = &expression[2];

		if (comp != NULL) {
		    xmlRegFreeRegexp(comp);
		    comp = NULL;
		}
		printf("Regexp: %s\n", pattern) ;
		comp = xmlRegexpCompile((const xmlChar *) pattern);
		if (comp == NULL) {
		    printf("   failed to compile\n");
		    break;
		}
	    } else if (comp == NULL) {
		printf("Regexp: %s\n", expression) ;
		comp = xmlRegexpCompile((const xmlChar *) expression);
		if (comp == NULL) {
		    printf("   failed to compile\n");
		    break;
		}
	    } else if (comp != NULL) {
		testRegexp(comp, expression);
	    }
	}
    }
    fclose(input);
    if (comp != NULL)
	xmlRegFreeRegexp(comp);
}

#ifdef LIBXML_EXPR_ENABLED
static void
runFileTest(xmlExpCtxtPtr ctxt, const char *filename) {
    xmlExpNodePtr expr = NULL, sub;
    FILE *input;
    char expression[5000];
    int len;

    input = fopen(filename, "r");
    if (input == NULL) {
        xmlGenericError(xmlGenericErrorContext,
		"Cannot open %s for reading\n", filename);
	return;
    }
    while (fgets(expression, 4500, input) != NULL) {
	len = strlen(expression);
	len--;
	while ((len >= 0) && 
	       ((expression[len] == '\n') || (expression[len] == '\t') ||
		(expression[len] == '\r') || (expression[len] == ' '))) len--;
	expression[len + 1] = 0;      
	if (len >= 0) {
	    if (expression[0] == '#')
		continue;
	    if ((expression[0] == '=') && (expression[1] == '>')) {
		char *str = &expression[2];

		if (expr != NULL) {
		    xmlExpFree(ctxt, expr);
		    if (xmlExpCtxtNbNodes(ctxt) != 0) 
		        printf(" Parse/free of Expression leaked %d\n",
			       xmlExpCtxtNbNodes(ctxt));
		    expr = NULL;
		}
		printf("Expression: %s\n", str) ;
		expr = xmlExpParse(ctxt, str);
		if (expr == NULL) {
		    printf("   parsing Failed\n");
		    break;
		}
	    } else if (expr != NULL) {
	        int expect = -1;
		int nodes1, nodes2;

		if (expression[0] == '0')
		    expect = 0;
		if (expression[0] == '1')
		    expect = 1;
		printf("Subexp: %s", expression + 2) ;
		nodes1 = xmlExpCtxtNbNodes(ctxt);
		sub = xmlExpParse(ctxt, expression + 2);
		if (sub == NULL) {
		    printf("   parsing Failed\n");
		    break;
		} else {
		    int ret;
		    
		    nodes2 = xmlExpCtxtNbNodes(ctxt);
		    ret = xmlExpSubsume(ctxt, expr, sub);

		    if ((expect == 1) && (ret == 1)) {
			printf(" => accept, Ok\n");
		    } else if ((expect == 0) && (ret == 0)) {
		        printf(" => reject, Ok\n");
		    } else if ((expect == 1) && (ret == 0)) {
			printf(" => reject, Failed\n");
		    } else if ((expect == 0) && (ret == 1)) {
			printf(" => accept, Failed\n");
		    } else {
		        printf(" => fail internally\n");
		    }
		    if (xmlExpCtxtNbNodes(ctxt) > nodes2) {
		        printf(" Subsume leaked %d\n",
			       xmlExpCtxtNbNodes(ctxt) - nodes2);
			nodes1 += xmlExpCtxtNbNodes(ctxt) - nodes2;
		    }
		    xmlExpFree(ctxt, sub);
		    if (xmlExpCtxtNbNodes(ctxt) > nodes1) {
		        printf(" Parse/free leaked %d\n",
			       xmlExpCtxtNbNodes(ctxt) - nodes1);
		    }
		}

	    }
	}
    }
    if (expr != NULL) {
	xmlExpFree(ctxt, expr);
	if (xmlExpCtxtNbNodes(ctxt) != 0) 
	    printf(" Parse/free of Expression leaked %d\n",
		   xmlExpCtxtNbNodes(ctxt));
    }
    fclose(input);
}

static void 
testReduce(xmlExpCtxtPtr ctxt, xmlExpNodePtr expr, const char *tst) {
    xmlBufferPtr xmlExpBuf;
    xmlExpNodePtr sub, deriv;
    xmlExpBuf = xmlBufferCreate();

    sub = xmlExpParse(ctxt, tst);
    if (sub == NULL) {
        printf("Subset %s failed to parse\n", tst);
	return;
    }
    xmlExpDump(xmlExpBuf, sub);
    printf("Subset parsed as: %s\n",
           (const char *) xmlBufferContent(xmlExpBuf));
    deriv = xmlExpExpDerive(ctxt, expr, sub);
    if (deriv == NULL) {
        printf("Derivation led to an internal error, report this !\n");
	return;
    } else {
        xmlBufferEmpty(xmlExpBuf);
	xmlExpDump(xmlExpBuf, deriv);
	if (xmlExpIsNillable(deriv))
	    printf("Resulting nillable derivation: %s\n",
	           (const char *) xmlBufferContent(xmlExpBuf));
	else
	    printf("Resulting derivation: %s\n",
	           (const char *) xmlBufferContent(xmlExpBuf));
	xmlExpFree(ctxt, deriv);
    }
    xmlExpFree(ctxt, sub);
}

static void 
exprDebug(xmlExpCtxtPtr ctxt, xmlExpNodePtr expr) {
    xmlBufferPtr xmlExpBuf;
    xmlExpNodePtr deriv;
    const char *list[40];
    int ret;

    xmlExpBuf = xmlBufferCreate();

    if (expr == NULL) {
        printf("Failed to parse\n");
	return;
    }
    xmlExpDump(xmlExpBuf, expr);
    printf("Parsed as: %s\n", (const char *) xmlBufferContent(xmlExpBuf));
    printf("Max token input = %d\n", xmlExpMaxToken(expr));
    if (xmlExpIsNillable(expr) == 1)
	printf("Is nillable\n");
    ret = xmlExpGetLanguage(ctxt, expr, (const xmlChar **) &list[0], 40);
    if (ret < 0)
	printf("Failed to get list: %d\n", ret);
    else {
	int i;

	printf("Language has %d strings, testing string derivations\n", ret);
	for (i = 0;i < ret;i++) {
	    deriv = xmlExpStringDerive(ctxt, expr, BAD_CAST list[i], -1);
	    if (deriv == NULL) {
		printf("  %s -> derivation failed\n", list[i]);
	    } else {
		xmlBufferEmpty(xmlExpBuf);
		xmlExpDump(xmlExpBuf, deriv);
		printf("  %s -> %s\n", list[i],
		       (const char *) xmlBufferContent(xmlExpBuf));
	    }
	    xmlExpFree(ctxt, deriv);
	}
    }
    xmlBufferFree(xmlExpBuf);
}
#endif

static void usage(const char *name) {
    fprintf(stderr, "Usage: %s [flags]\n", name);
    fprintf(stderr, "Testing tool for libxml2 string and pattern regexps\n");
    fprintf(stderr, "   --debug: switch on debugging\n");
    fprintf(stderr, "   --repeat: loop on the operation\n");
#ifdef LIBXML_EXPR_ENABLED
    fprintf(stderr, "   --expr: test xmlExp and not xmlRegexp\n");
#endif
    fprintf(stderr, "   --input filename: use the given filename for regexp\n");
    fprintf(stderr, "   --input filename: use the given filename for exp\n");
}

int main(int argc, char **argv) {
    xmlRegexpPtr comp = NULL;
#ifdef LIBXML_EXPR_ENABLED
    xmlExpNodePtr expr = NULL;
    int use_exp = 0;
    xmlExpCtxtPtr ctxt = NULL;
#endif
    const char *pattern = NULL;
    char *filename = NULL;
    int i;

    xmlInitMemory();

    if (argc <= 1) {
	usage(argv[0]);
	return(1);
    }
    for (i = 1; i < argc ; i++) {
	if (!strcmp(argv[i], "-"))
	    break;

	if (argv[i][0] != '-')
	    continue;
	if (!strcmp(argv[i], "--"))
	    break;

	if ((!strcmp(argv[i], "-debug")) || (!strcmp(argv[i], "--debug"))) {
	    debug++;
	} else if ((!strcmp(argv[i], "-repeat")) ||
	         (!strcmp(argv[i], "--repeat"))) {
	    repeat++;
#ifdef LIBXML_EXPR_ENABLED
	} else if ((!strcmp(argv[i], "-expr")) ||
	         (!strcmp(argv[i], "--expr"))) {
	    use_exp++;
#endif
	} else if ((!strcmp(argv[i], "-i")) || (!strcmp(argv[i], "-f")) ||
		   (!strcmp(argv[i], "--input")))
	    filename = argv[++i];
        else {
	    fprintf(stderr, "Unknown option %s\n", argv[i]);
	    usage(argv[0]);
	}
    }

#ifdef LIBXML_EXPR_ENABLED
    if (use_exp)
	ctxt = xmlExpNewCtxt(0, NULL);
#endif

    if (filename != NULL) {
#ifdef LIBXML_EXPR_ENABLED
        if (use_exp)
	    runFileTest(ctxt, filename);
	else
#endif
	    testRegexpFile(filename);
    } else {
        int  data = 0;
#ifdef LIBXML_EXPR_ENABLED

        if (use_exp) {
	    for (i = 1; i < argc ; i++) {
	        if (strcmp(argv[i], "--") == 0)
		    data = 1;
		else if ((argv[i][0] != '-') || (strcmp(argv[i], "-") == 0) ||
		    (data == 1)) {
		    if (pattern == NULL) {
			pattern = argv[i];
			printf("Testing expr %s:\n", pattern);
			expr = xmlExpParse(ctxt, pattern);
			if (expr == NULL) {
			    printf("   failed to compile\n");
			    break;
			}
			if (debug) {
			    exprDebug(ctxt, expr);
			}
		    } else {
			testReduce(ctxt, expr, argv[i]);
		    }
		}
	    }
	    if (expr != NULL) {
		xmlExpFree(ctxt, expr);
		expr = NULL;
	    }
	} else
#endif
        {
	    for (i = 1; i < argc ; i++) {
	        if (strcmp(argv[i], "--") == 0)
		    data = 1;
		else if ((argv[i][0] != '-') || (strcmp(argv[i], "-") == 0) ||
		         (data == 1)) {
		    if (pattern == NULL) {
			pattern = argv[i];
			printf("Testing %s:\n", pattern);
			comp = xmlRegexpCompile((const xmlChar *) pattern);
			if (comp == NULL) {
			    printf("   failed to compile\n");
			    break;
			}
			if (debug)
			    xmlRegexpPrint(stdout, comp);
		    } else {
			testRegexp(comp, argv[i]);
		    }
		}
	    }
	    if (comp != NULL)
		xmlRegFreeRegexp(comp);
        }
    }
#ifdef LIBXML_EXPR_ENABLED
    if (ctxt != NULL) {
	printf("Ops: %d nodes, %d cons\n",
	       xmlExpCtxtNbNodes(ctxt), xmlExpCtxtNbCons(ctxt));
	xmlExpFreeCtxt(ctxt);
    }
#endif
    xmlCleanupParser();
    xmlMemoryDump();
    return(0);
}

#else
#include <stdio.h>
int main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    printf("%s : Regexp support not compiled in\n", argv[0]);
    return(0);
}
#endif /* LIBXML_REGEXP_ENABLED */
