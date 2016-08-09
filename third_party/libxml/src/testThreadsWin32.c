#include "libxml.h"
#include <stdlib.h>
#include <stdio.h>

#if defined(LIBXML_THREAD_ENABLED) && defined(LIBXML_CATALOG_ENABLED)
#include <libxml/globals.h>
#include <libxml/threads.h>
#include <libxml/parser.h>
#include <libxml/catalog.h>
#include <windows.h>
#include <string.h>
#include <assert.h>

#define	MAX_ARGC	20
#define TEST_REPEAT_COUNT 500

static HANDLE tid[MAX_ARGC];

static const char *catalog = "test/threads/complex.xml";
static char *testfiles[] = {
    "test/threads/abc.xml",
    "test/threads/acb.xml",
    "test/threads/bac.xml",
    "test/threads/bca.xml",
    "test/threads/cab.xml",
    "test/threads/cba.xml",
    "test/threads/invalid.xml",
};

const char *Okay = "OK";
const char *Failed = "Failed";

#ifndef xmlDoValidityCheckingDefaultValue
#error xmlDoValidityCheckingDefaultValue is not a macro
#endif
#ifndef xmlGenericErrorContext
#error xmlGenericErrorContext is not a macro
#endif

static DWORD WINAPI
thread_specific_data(void *private_data)
{
    xmlDocPtr myDoc;
    const char *filename = (const char *) private_data;
    int okay = 1;

    if (!strcmp(filename, "test/threads/invalid.xml")) {
        xmlDoValidityCheckingDefaultValue = 0;
        xmlGenericErrorContext = stdout;
    } else {
        xmlDoValidityCheckingDefaultValue = 1;
        xmlGenericErrorContext = stderr;
    }
    myDoc = xmlParseFile(filename);
    if (myDoc) {
        xmlFreeDoc(myDoc);
    } else {
        printf("parse failed\n");
	okay = 0;
    }
    if (!strcmp(filename, "test/threads/invalid.xml")) {
        if (xmlDoValidityCheckingDefaultValue != 0) {
	    printf("ValidityCheckingDefaultValue override failed\n");
	    okay = 0;
	}
        if (xmlGenericErrorContext != stdout) {
	    printf("xmlGenericErrorContext override failed\n");
	    okay = 0;
	}
    } else {
        if (xmlDoValidityCheckingDefaultValue != 1) {
	    printf("ValidityCheckingDefaultValue override failed\n");
	    okay = 0;
	}
        if (xmlGenericErrorContext != stderr) {
	    printf("xmlGenericErrorContext override failed\n");
	    okay = 0;
	}
    }
    if (okay == 0)
	return ((DWORD) Failed);
    return ((DWORD) Okay);
}

int
main()
{
	unsigned int i, repeat;
	unsigned int num_threads = sizeof(testfiles) / sizeof(testfiles[0]);
	DWORD results[MAX_ARGC];
	BOOL ret;

	xmlInitParser();
	for (repeat = 0;repeat < TEST_REPEAT_COUNT;repeat++)
	{
		xmlLoadCatalog(catalog);

		for (i = 0; i < num_threads; i++)
		{
			results[i] = 0;
			tid[i] = (HANDLE) -1;
		}

		for (i = 0; i < num_threads; i++)
		{
			DWORD useless;
			tid[i] = CreateThread(NULL, 0, 
				thread_specific_data, testfiles[i], 0, &useless);
			if (tid[i] == NULL)
			{
				perror("CreateThread");
				exit(1);
			}
		}

		if (WaitForMultipleObjects (num_threads, tid, TRUE, INFINITE) == WAIT_FAILED) 
			perror ("WaitForMultipleObjects failed");

		for (i = 0; i < num_threads; i++)
		{
			ret = GetExitCodeThread (tid[i], &results[i]);
			if (ret == 0)
			{
				perror("GetExitCodeThread");
				exit(1);
			}
			CloseHandle (tid[i]);
		}

		xmlCatalogCleanup();
		for (i = 0; i < num_threads; i++) {
		    if (results[i] != (DWORD) Okay) 
			printf("Thread %d handling %s failed\n", i, testfiles[i]);
		}
	}

	xmlCleanupParser();
	xmlMemoryDump();

	return (0);
}

#else /* !LIBXML_THREADS_ENABLED */
int
main()
{
    fprintf(stderr, "libxml was not compiled with thread or catalog support\n");
    return (0);
}
#endif
