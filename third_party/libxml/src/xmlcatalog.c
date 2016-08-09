/*
 * xmlcatalog.c : a small utility program to handle XML catalogs
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 */

#include "libxml.h"

#include <string.h>
#include <stdio.h>
#include <stdarg.h>

#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

#ifdef HAVE_LIBREADLINE
#include <readline/readline.h>
#ifdef HAVE_LIBHISTORY
#include <readline/history.h>
#endif
#endif

#include <libxml/xmlmemory.h>
#include <libxml/uri.h>
#include <libxml/catalog.h>
#include <libxml/parser.h>
#include <libxml/globals.h>

#if defined(LIBXML_CATALOG_ENABLED) && defined(LIBXML_OUTPUT_ENABLED)
static int shell = 0;
static int sgml = 0;
static int noout = 0;
static int create = 0;
static int add = 0;
static int del = 0;
static int convert = 0;
static int no_super_update = 0;
static int verbose = 0;
static char *filename = NULL;


#ifndef XML_SGML_DEFAULT_CATALOG
#define XML_SGML_DEFAULT_CATALOG "/etc/sgml/catalog"
#endif

/************************************************************************
 * 									*
 * 			Shell Interface					*
 * 									*
 ************************************************************************/
/**
 * xmlShellReadline:
 * @prompt:  the prompt value
 *
 * Read a string
 * 
 * Returns a pointer to it or NULL on EOF the caller is expected to
 *     free the returned string.
 */
static char *
xmlShellReadline(const char *prompt) {
#ifdef HAVE_LIBREADLINE
    char *line_read;

    /* Get a line from the user. */
    line_read = readline (prompt);

    /* If the line has any text in it, save it on the history. */
    if (line_read && *line_read)
	add_history (line_read);

    return (line_read);
#else
    char line_read[501];
    char *ret;
    int len;

    if (prompt != NULL)
	fprintf(stdout, "%s", prompt);
    if (!fgets(line_read, 500, stdin))
        return(NULL);
    line_read[500] = 0;
    len = strlen(line_read);
    ret = (char *) malloc(len + 1);
    if (ret != NULL) {
	memcpy (ret, line_read, len + 1);
    }
    return(ret);
#endif
}

static void usershell(void) {
    char *cmdline = NULL, *cur;
    int nbargs;
    char command[100];
    char arg[400];
    char *argv[20];
    int i, ret;
    xmlChar *ans;

    while (1) {
	cmdline = xmlShellReadline("> ");
	if (cmdline == NULL)
	    return;

	/*
	 * Parse the command itself
	 */
	cur = cmdline;
	nbargs = 0;
	while ((*cur == ' ') || (*cur == '\t')) cur++;
	i = 0;
	while ((*cur != ' ') && (*cur != '\t') &&
	       (*cur != '\n') && (*cur != '\r')) {
	    if (*cur == 0)
		break;
	    command[i++] = *cur++;
	}
	command[i] = 0;
	if (i == 0) {
	    free(cmdline);
	    continue;
	}

	/*
	 * Parse the argument string
	 */
	memset(arg, 0, sizeof(arg));
	while ((*cur == ' ') || (*cur == '\t')) cur++;
	i = 0;
	while ((*cur != '\n') && (*cur != '\r') && (*cur != 0)) {
	    if (*cur == 0)
		break;
	    arg[i++] = *cur++;
	}
	arg[i] = 0;

	/*
	 * Parse the arguments
	 */
	i = 0;
	nbargs = 0;
	cur = arg;
	memset(argv, 0, sizeof(argv));
	while (*cur != 0) {
	    while ((*cur == ' ') || (*cur == '\t')) cur++;
	    if (*cur == '\'') {
		cur++;
		argv[i] = cur;
		while ((*cur != 0) && (*cur != '\'')) cur++;
		if (*cur == '\'') {
		    *cur = 0;
		    nbargs++;
		    i++;
		    cur++;
		}
	    } else if (*cur == '"') { 
		cur++;
		argv[i] = cur;
		while ((*cur != 0) && (*cur != '"')) cur++;
		if (*cur == '"') {
		    *cur = 0;
		    nbargs++;
		    i++;
		    cur++;
		}
	    } else {
		argv[i] = cur;
		while ((*cur != 0) && (*cur != ' ') && (*cur != '\t'))
		    cur++;
		*cur = 0;
		nbargs++;
		i++;
		cur++;
	    }
	}

	/*
	 * start interpreting the command
	 */
        if (!strcmp(command, "exit"))
	    break;
        if (!strcmp(command, "quit"))
	    break;
        if (!strcmp(command, "bye"))
	    break;
	if (!strcmp(command, "public")) {
	    if (nbargs != 1) {
		printf("public requires 1 arguments\n");
	    } else {
		ans = xmlCatalogResolvePublic((const xmlChar *) argv[0]);
		if (ans == NULL) {
		    printf("No entry for PUBLIC %s\n", argv[0]);
		} else {
		    printf("%s\n", (char *) ans);
		    xmlFree(ans);
		}
	    }
	} else if (!strcmp(command, "system")) {
	    if (nbargs != 1) {
		printf("system requires 1 arguments\n");
	    } else {
		ans = xmlCatalogResolveSystem((const xmlChar *) argv[0]);
		if (ans == NULL) {
		    printf("No entry for SYSTEM %s\n", argv[0]);
		} else {
		    printf("%s\n", (char *) ans);
		    xmlFree(ans);
		}
	    }
	} else if (!strcmp(command, "add")) {
	    if (sgml) {
		if ((nbargs != 3) && (nbargs != 2)) {
		    printf("add requires 2 or 3 arguments\n");
		} else {
		    if (argv[2] == NULL)
			ret = xmlCatalogAdd(BAD_CAST argv[0], NULL,
					    BAD_CAST argv[1]);
		    else
			ret = xmlCatalogAdd(BAD_CAST argv[0], BAD_CAST argv[1],
					    BAD_CAST argv[2]);
		    if (ret != 0)
			printf("add command failed\n");
		}
	    } else {
		if ((nbargs != 3) && (nbargs != 2)) {
		    printf("add requires 2 or 3 arguments\n");
		} else {
		    if (argv[2] == NULL)
			ret = xmlCatalogAdd(BAD_CAST argv[0], NULL,
					    BAD_CAST argv[1]);
		    else
			ret = xmlCatalogAdd(BAD_CAST argv[0], BAD_CAST argv[1],
					    BAD_CAST argv[2]);
		    if (ret != 0)
			printf("add command failed\n");
		}
	    }
	} else if (!strcmp(command, "del")) {
	    if (nbargs != 1) {
		printf("del requires 1\n");
	    } else {
		ret = xmlCatalogRemove(BAD_CAST argv[0]);
		if (ret <= 0)
		    printf("del command failed\n");

	    }
	} else if (!strcmp(command, "resolve")) {
	    if (nbargs != 2) {
		printf("resolve requires 2 arguments\n");
	    } else {
		ans = xmlCatalogResolve(BAD_CAST argv[0],
			                BAD_CAST argv[1]);
		if (ans == NULL) {
		    printf("Resolver failed to find an answer\n");
		} else {
		    printf("%s\n", (char *) ans);
		    xmlFree(ans);
		}
	    }
	} else if (!strcmp(command, "dump")) {
	    if (nbargs != 0) {
		printf("dump has no arguments\n");
	    } else {
		xmlCatalogDump(stdout);
	    }
	} else if (!strcmp(command, "debug")) {
	    if (nbargs != 0) {
		printf("debug has no arguments\n");
	    } else {
		verbose++;
		xmlCatalogSetDebug(verbose);
	    }
	} else if (!strcmp(command, "quiet")) {
	    if (nbargs != 0) {
		printf("quiet has no arguments\n");
	    } else {
		if (verbose > 0)
		    verbose--;
		xmlCatalogSetDebug(verbose);
	    }
	} else {
	    if (strcmp(command, "help")) {
		printf("Unrecognized command %s\n", command);
	    }
	    printf("Commands available:\n");
	    printf("\tpublic PublicID: make a PUBLIC identifier lookup\n");
	    printf("\tsystem SystemID: make a SYSTEM identifier lookup\n");
	    printf("\tresolve PublicID SystemID: do a full resolver lookup\n");
	    printf("\tadd 'type' 'orig' 'replace' : add an entry\n");
	    printf("\tdel 'values' : remove values\n");
	    printf("\tdump: print the current catalog state\n");
	    printf("\tdebug: increase the verbosity level\n");
	    printf("\tquiet: decrease the verbosity level\n");
	    printf("\texit:  quit the shell\n");
	} 
	free(cmdline); /* not xmlFree here ! */
    }
}

/************************************************************************
 * 									*
 * 			Main						*
 * 									*
 ************************************************************************/
static void usage(const char *name) {
    /* split into 2 printf's to avoid overly long string (gcc warning) */
    printf("\
Usage : %s [options] catalogfile entities...\n\
\tParse the catalog file and query it for the entities\n\
\t--sgml : handle SGML Super catalogs for --add and --del\n\
\t--shell : run a shell allowing interactive queries\n\
\t--create : create a new catalog\n\
\t--add 'type' 'orig' 'replace' : add an XML entry\n\
\t--add 'entry' : add an SGML entry\n", name);
    printf("\
\t--del 'values' : remove values\n\
\t--noout: avoid dumping the result on stdout\n\
\t         used with --add or --del, it saves the catalog changes\n\
\t         and with --sgml it automatically updates the super catalog\n\
\t--no-super-update: do not update the SGML super catalog\n\
\t-v --verbose : provide debug informations\n");
}
int main(int argc, char **argv) {
    int i;
    int ret;
    int exit_value = 0;


    if (argc <= 1) {
	usage(argv[0]);
	return(1);
    }

    LIBXML_TEST_VERSION
    for (i = 1; i < argc ; i++) {
	if (!strcmp(argv[i], "-"))
	    break;

	if (argv[i][0] != '-')
	    break;
	if ((!strcmp(argv[i], "-verbose")) ||
	    (!strcmp(argv[i], "-v")) ||
	    (!strcmp(argv[i], "--verbose"))) {
	    verbose++;
	    xmlCatalogSetDebug(verbose);
	} else if ((!strcmp(argv[i], "-noout")) ||
	    (!strcmp(argv[i], "--noout"))) {
            noout = 1;
	} else if ((!strcmp(argv[i], "-shell")) ||
	    (!strcmp(argv[i], "--shell"))) {
	    shell++;
            noout = 1;
	} else if ((!strcmp(argv[i], "-sgml")) ||
	    (!strcmp(argv[i], "--sgml"))) {
	    sgml++;
	} else if ((!strcmp(argv[i], "-create")) ||
	    (!strcmp(argv[i], "--create"))) {
	    create++;
	} else if ((!strcmp(argv[i], "-convert")) ||
	    (!strcmp(argv[i], "--convert"))) {
	    convert++;
	} else if ((!strcmp(argv[i], "-no-super-update")) ||
	    (!strcmp(argv[i], "--no-super-update"))) {
	    no_super_update++;
	} else if ((!strcmp(argv[i], "-add")) ||
	    (!strcmp(argv[i], "--add"))) {
	    if (sgml)
		i += 2;
	    else
		i += 3;
	    add++;
	} else if ((!strcmp(argv[i], "-del")) ||
	    (!strcmp(argv[i], "--del"))) {
	    i += 1;
	    del++;
	} else {
	    fprintf(stderr, "Unknown option %s\n", argv[i]);
	    usage(argv[0]);
	    return(1);
	}
    }

    for (i = 1; i < argc; i++) {
	if ((!strcmp(argv[i], "-add")) ||
	    (!strcmp(argv[i], "--add"))) {
	    if (sgml)
		i += 2;
	    else
		i += 3;
	    continue;
	} else if ((!strcmp(argv[i], "-del")) ||
	    (!strcmp(argv[i], "--del"))) {
	    i += 1;

	    /* No catalog entry specified */
	    if (i == argc || (sgml && i + 1 == argc)) {
		fprintf(stderr, "No catalog entry specified to remove from\n");
		usage (argv[0]);
		return(1);
	    }

	    continue;
	} else if (argv[i][0] == '-')
	    continue;
	filename = argv[i];
	    ret = xmlLoadCatalog(argv[i]);
	    if ((ret < 0) && (create)) {
		xmlCatalogAdd(BAD_CAST "catalog", BAD_CAST argv[i], NULL);
	    }
	break;
    }

    if (convert)
        ret = xmlCatalogConvert();

    if ((add) || (del)) {
	for (i = 1; i < argc ; i++) {
	    if (!strcmp(argv[i], "-"))
		break;

	    if (argv[i][0] != '-')
		continue;
	    if (strcmp(argv[i], "-add") && strcmp(argv[i], "--add") &&
		strcmp(argv[i], "-del") && strcmp(argv[i], "--del"))
		continue;

	    if (sgml) {
		/*
		 * Maintenance of SGML catalogs.
		 */
		xmlCatalogPtr catal = NULL;
		xmlCatalogPtr super = NULL;

		catal = xmlLoadSGMLSuperCatalog(argv[i + 1]);

		if ((!strcmp(argv[i], "-add")) ||
		    (!strcmp(argv[i], "--add"))) {
		    if (catal == NULL)
			catal = xmlNewCatalog(1);
		    xmlACatalogAdd(catal, BAD_CAST "CATALOG",
					 BAD_CAST argv[i + 2], NULL);

		    if (!no_super_update) {
			super = xmlLoadSGMLSuperCatalog(XML_SGML_DEFAULT_CATALOG);
			if (super == NULL)
			    super = xmlNewCatalog(1);

			xmlACatalogAdd(super, BAD_CAST "CATALOG",
					     BAD_CAST argv[i + 1], NULL);
		    }
		} else {
		    if (catal != NULL)
			ret = xmlACatalogRemove(catal, BAD_CAST argv[i + 2]);
		    else
			ret = -1;
		    if (ret < 0) {
			fprintf(stderr, "Failed to remove entry from %s\n",
				argv[i + 1]);
			exit_value = 1;
		    }
		    if ((!no_super_update) && (noout) && (catal != NULL) &&
			(xmlCatalogIsEmpty(catal))) {
			super = xmlLoadSGMLSuperCatalog(
				   XML_SGML_DEFAULT_CATALOG);
			if (super != NULL) {
			    ret = xmlACatalogRemove(super,
				    BAD_CAST argv[i + 1]);
			    if (ret < 0) {
				fprintf(stderr,
					"Failed to remove entry from %s\n",
					XML_SGML_DEFAULT_CATALOG);
				exit_value = 1;
			    }
			}
		    }
		}
		if (noout) {
		    FILE *out;

		    if (xmlCatalogIsEmpty(catal)) {
			remove(argv[i + 1]);
		    } else {
			out = fopen(argv[i + 1], "w");
			if (out == NULL) {
			    fprintf(stderr, "could not open %s for saving\n",
				    argv[i + 1]);
			    exit_value = 2;
			    noout = 0;
			} else {
			    xmlACatalogDump(catal, out);
			    fclose(out);
			}
		    }
		    if (!no_super_update && super != NULL) {
			if (xmlCatalogIsEmpty(super)) {
			    remove(XML_SGML_DEFAULT_CATALOG);
			} else {
			    out = fopen(XML_SGML_DEFAULT_CATALOG, "w");
			    if (out == NULL) {
				fprintf(stderr,
					"could not open %s for saving\n",
					XML_SGML_DEFAULT_CATALOG);
				exit_value = 2;
				noout = 0;
			    } else {
				
				xmlACatalogDump(super, out);
				fclose(out);
			    }
			}
		    }
		} else {
		    xmlACatalogDump(catal, stdout);
		}
		i += 2;
	    } else {
		if ((!strcmp(argv[i], "-add")) ||
		    (!strcmp(argv[i], "--add"))) {
			if ((argv[i + 3] == NULL) || (argv[i + 3][0] == 0))
			    ret = xmlCatalogAdd(BAD_CAST argv[i + 1], NULL,
						BAD_CAST argv[i + 2]);
			else
			    ret = xmlCatalogAdd(BAD_CAST argv[i + 1],
						BAD_CAST argv[i + 2],
						BAD_CAST argv[i + 3]);
			if (ret != 0) {
			    printf("add command failed\n");
			    exit_value = 3;
			}
			i += 3;
		} else if ((!strcmp(argv[i], "-del")) ||
		    (!strcmp(argv[i], "--del"))) {
		    ret = xmlCatalogRemove(BAD_CAST argv[i + 1]);
		    if (ret < 0) {
			fprintf(stderr, "Failed to remove entry %s\n",
				argv[i + 1]);
			exit_value = 1;
		    }
		    i += 1;
		}
	    }
	}
	
    } else if (shell) {
	usershell();
    } else {
	for (i++; i < argc; i++) {
	    xmlURIPtr uri;
	    xmlChar *ans;
	    
	    uri = xmlParseURI(argv[i]);
	    if (uri == NULL) {
		ans = xmlCatalogResolvePublic((const xmlChar *) argv[i]);
		if (ans == NULL) {
		    printf("No entry for PUBLIC %s\n", argv[i]);
		    exit_value = 4;
		} else {
		    printf("%s\n", (char *) ans);
		    xmlFree(ans);
		}
	    } else {
                xmlFreeURI(uri);
		ans = xmlCatalogResolveSystem((const xmlChar *) argv[i]);
		if (ans == NULL) {
		    printf("No entry for SYSTEM %s\n", argv[i]);
		    ans = xmlCatalogResolveURI ((const xmlChar *) argv[i]);
		    if (ans == NULL) {
			printf ("No entry for URI %s\n", argv[i]);
		        exit_value = 4;
		    } else {
		        printf("%s\n", (char *) ans);
			xmlFree (ans);
		    }
		} else {
		    printf("%s\n", (char *) ans);
		    xmlFree(ans);
		}
	    }
	}
    }
    if ((!sgml) && ((add) || (del) || (create) || (convert))) {
	if (noout && filename && *filename) {
	    FILE *out;

	    out = fopen(filename, "w");
	    if (out == NULL) {
		fprintf(stderr, "could not open %s for saving\n", filename);
		exit_value = 2;
		noout = 0;
	    } else {
		xmlCatalogDump(out);
	    }
	} else {
	    xmlCatalogDump(stdout);
	}
    }

    /*
     * Cleanup and check for memory leaks
     */
    xmlCleanupParser();
    xmlMemoryDump();
    return(exit_value);
}
#else
int main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    fprintf(stderr, "libxml was not compiled with catalog and output support\n");
    return(1);
}
#endif
