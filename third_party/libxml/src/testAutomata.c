/*
 * testRegexp.c: simple module for testing regular expressions
 *
 * See Copyright for the status of this software.
 *
 * Daniel Veillard <veillard@redhat.com>
 */

#include "libxml.h"
#ifdef LIBXML_AUTOMATA_ENABLED
#include <string.h>

#include <libxml/tree.h>
#include <libxml/xmlautomata.h>

static int scanNumber(char **ptr) {
    int ret = 0;
    char *cur;

    cur = *ptr;
    while ((*cur >= '0') && (*cur <= '9')) {
	ret = ret * 10 + (*cur - '0');
	cur++;
    }
    *ptr = cur;
    return(ret);
}

static void
testRegexpFile(const char *filename) {
    FILE *input;
    char expr[5000];
    int len;
    int ret;
    int i;
    xmlAutomataPtr am;
    xmlAutomataStatePtr states[1000];
    xmlRegexpPtr regexp = NULL;
    xmlRegExecCtxtPtr exec = NULL;

    for (i = 0;i<1000;i++)
	states[i] = NULL;

    input = fopen(filename, "r");
    if (input == NULL) {
        xmlGenericError(xmlGenericErrorContext,
		"Cannot open %s for reading\n", filename);
	return;
    }

    am = xmlNewAutomata();
    if (am == NULL) {
        xmlGenericError(xmlGenericErrorContext,
		"Cannot create automata\n");
	fclose(input);
	return;
    }
    states[0] = xmlAutomataGetInitState(am);
    if (states[0] == NULL) {
        xmlGenericError(xmlGenericErrorContext,
		"Cannot get start state\n");
	xmlFreeAutomata(am);
	fclose(input);
	return;
    }
    ret = 0;

    while (fgets(expr, 4500, input) != NULL) {
	if (expr[0] == '#')
	    continue;
	len = strlen(expr);
	len--;
	while ((len >= 0) && 
	       ((expr[len] == '\n') || (expr[len] == '\t') ||
		(expr[len] == '\r') || (expr[len] == ' '))) len--;
	expr[len + 1] = 0;      
	if (len >= 0) {
	    if ((am != NULL) && (expr[0] == 't') && (expr[1] == ' ')) {
		char *ptr = &expr[2];
		int from, to;

		from = scanNumber(&ptr);
		if (*ptr != ' ') {
		    xmlGenericError(xmlGenericErrorContext,
			    "Bad line %s\n", expr);
		    break;
		}
		if (states[from] == NULL)
		    states[from] = xmlAutomataNewState(am);
		ptr++;
		to = scanNumber(&ptr);
		if (*ptr != ' ') {
		    xmlGenericError(xmlGenericErrorContext,
			    "Bad line %s\n", expr);
		    break;
		}
		if (states[to] == NULL)
		    states[to] = xmlAutomataNewState(am);
		ptr++;
		xmlAutomataNewTransition(am, states[from], states[to],
			                 BAD_CAST ptr, NULL);
	    } else if ((am != NULL) && (expr[0] == 'e') && (expr[1] == ' ')) {
		char *ptr = &expr[2];
		int from, to;

		from = scanNumber(&ptr);
		if (*ptr != ' ') {
		    xmlGenericError(xmlGenericErrorContext,
			    "Bad line %s\n", expr);
		    break;
		}
		if (states[from] == NULL)
		    states[from] = xmlAutomataNewState(am);
		ptr++;
		to = scanNumber(&ptr);
		if (states[to] == NULL)
		    states[to] = xmlAutomataNewState(am);
		xmlAutomataNewEpsilon(am, states[from], states[to]);
	    } else if ((am != NULL) && (expr[0] == 'f') && (expr[1] == ' ')) {
		char *ptr = &expr[2];
		int state;

		state = scanNumber(&ptr);
		if (states[state] == NULL) {
		    xmlGenericError(xmlGenericErrorContext,
			    "Bad state %d : %s\n", state, expr);
		    break;
		}
		xmlAutomataSetFinalState(am, states[state]);
	    } else if ((am != NULL) && (expr[0] == 'c') && (expr[1] == ' ')) {
		char *ptr = &expr[2];
		int from, to;
		int min, max;

		from = scanNumber(&ptr);
		if (*ptr != ' ') {
		    xmlGenericError(xmlGenericErrorContext,
			    "Bad line %s\n", expr);
		    break;
		}
		if (states[from] == NULL)
		    states[from] = xmlAutomataNewState(am);
		ptr++;
		to = scanNumber(&ptr);
		if (*ptr != ' ') {
		    xmlGenericError(xmlGenericErrorContext,
			    "Bad line %s\n", expr);
		    break;
		}
		if (states[to] == NULL)
		    states[to] = xmlAutomataNewState(am);
		ptr++;
		min = scanNumber(&ptr);
		if (*ptr != ' ') {
		    xmlGenericError(xmlGenericErrorContext,
			    "Bad line %s\n", expr);
		    break;
		}
		ptr++;
		max = scanNumber(&ptr);
		if (*ptr != ' ') {
		    xmlGenericError(xmlGenericErrorContext,
			    "Bad line %s\n", expr);
		    break;
		}
		ptr++;
		xmlAutomataNewCountTrans(am, states[from], states[to],
			                 BAD_CAST ptr, min, max, NULL);
	    } else if ((am != NULL) && (expr[0] == '-') && (expr[1] == '-')) {
		/* end of the automata */
		regexp = xmlAutomataCompile(am);
		xmlFreeAutomata(am);
		am = NULL;
		if (regexp == NULL) {
		    xmlGenericError(xmlGenericErrorContext,
			    "Failed to compile the automata");
		    break;
		}
	    } else if ((expr[0] == '=') && (expr[1] == '>')) {
		if (regexp == NULL) {
		    printf("=> failed not compiled\n");
		} else {
		    if (exec == NULL)
			exec = xmlRegNewExecCtxt(regexp, NULL, NULL);
		    if (ret == 0) {
			ret = xmlRegExecPushString(exec, NULL, NULL);
		    }
		    if (ret == 1)
			printf("=> Passed\n");
		    else if ((ret == 0) || (ret == -1))
			printf("=> Failed\n");
		    else if (ret < 0)
			printf("=> Error\n");
		    xmlRegFreeExecCtxt(exec);
		    exec = NULL;
		}
		ret = 0;
	    } else if (regexp != NULL) {
		if (exec == NULL)
		    exec = xmlRegNewExecCtxt(regexp, NULL, NULL);
		ret = xmlRegExecPushString(exec, BAD_CAST expr, NULL);
	    } else {
		xmlGenericError(xmlGenericErrorContext,
			"Unexpected line %s\n", expr);
	    }
	}
    }
    fclose(input);
    if (regexp != NULL)
	xmlRegFreeRegexp(regexp);
    if (exec != NULL)
	xmlRegFreeExecCtxt(exec);
    if (am != NULL)
	xmlFreeAutomata(am);
}

int main(int argc, char **argv) {

    xmlInitMemory();

    if (argc == 1) {
	int ret;
	xmlAutomataPtr am;
	xmlAutomataStatePtr start, cur;
	xmlRegexpPtr regexp;
	xmlRegExecCtxtPtr exec;

	am = xmlNewAutomata();
	start = xmlAutomataGetInitState(am);

	/* generate a[ba]*a */
	cur = xmlAutomataNewTransition(am, start, NULL, BAD_CAST"a", NULL);
	xmlAutomataNewTransition(am, cur, cur, BAD_CAST"b", NULL);
	xmlAutomataNewTransition(am, cur, cur, BAD_CAST"a", NULL);
	cur = xmlAutomataNewCountTrans(am, cur, NULL, BAD_CAST"a", 2, 3, NULL);
	xmlAutomataSetFinalState(am, cur);

	/* compile it in a regexp and free the automata */
	regexp = xmlAutomataCompile(am);
	xmlFreeAutomata(am);

	/* test the regexp */
	xmlRegexpPrint(stdout, regexp);
	exec = xmlRegNewExecCtxt(regexp, NULL, NULL);
	ret = xmlRegExecPushString(exec, BAD_CAST"a", NULL);
	if (ret == 1)
	    printf("final\n");
	else if (ret < 0)
	    printf("error\n");
	ret =xmlRegExecPushString(exec, BAD_CAST"a", NULL);
	if (ret == 1)
	    printf("final\n");
	else if (ret < 0)
	    printf("error\n");
	ret =xmlRegExecPushString(exec, BAD_CAST"b", NULL);
	if (ret == 1)
	    printf("final\n");
	else if (ret < 0)
	    printf("error\n");
	ret =xmlRegExecPushString(exec, BAD_CAST"a", NULL);
	if (ret == 1)
	    printf("final\n");
	else if (ret < 0)
	    printf("error\n");
	ret =xmlRegExecPushString(exec, BAD_CAST"a", NULL);
	if (ret == 1)
	    printf("final\n");
	else if (ret < 0)
	    printf("error\n");
	ret =xmlRegExecPushString(exec, BAD_CAST"a", NULL);
	if (ret == 1)
	    printf("final\n");
	else if (ret < 0)
	    printf("error\n");
	ret =xmlRegExecPushString(exec, BAD_CAST"a", NULL);
	if (ret == 1)
	    printf("final\n");
	else if (ret < 0)
	    printf("error\n");
	if (ret == 0) {
	    ret = xmlRegExecPushString(exec, NULL, NULL);
	    if (ret == 1)
		printf("final\n");
	    else if (ret < 0)
		printf("error\n");
	}
	xmlRegFreeExecCtxt(exec);

	/* free the regexp */
	xmlRegFreeRegexp(regexp);
    } else {
	int i;

	for (i = 1;i < argc;i++)
	    testRegexpFile(argv[i]);
    }

    xmlCleanupParser();
    xmlMemoryDump();
    return(0);
}

#else
#include <stdio.h>
int main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    printf("%s : Automata support not compiled in\n", argv[0]);
    return(0);
}
#endif /* LIBXML_AUTOMATA_ENABLED */
