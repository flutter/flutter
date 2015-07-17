#include "libxml.h"

#include <stdlib.h>
#include <stdio.h>

#if defined(LIBXML_THREAD_ENABLED) && defined(LIBXML_CATALOG_ENABLED) && defined(LIBXML_SAX1_ENABLED)
#include <libxml/globals.h>
#include <libxml/threads.h>
#include <libxml/parser.h>
#include <libxml/catalog.h>
#ifdef HAVE_PTHREAD_H
#include <pthread.h>
#elif defined HAVE_BEOS_THREADS
#include <OS.h>
#endif
#include <string.h>
#if !defined(_MSC_VER)
#include <unistd.h>
#endif
#include <assert.h>

#define	MAX_ARGC	20
#ifdef HAVE_PTHREAD_H
static pthread_t tid[MAX_ARGC];
#elif defined HAVE_BEOS_THREADS
static thread_id tid[MAX_ARGC];
#endif

static const char *catalog = "test/threads/complex.xml";
static const char *testfiles[] = {
    "test/threads/abc.xml",
    "test/threads/acb.xml",
    "test/threads/bac.xml",
    "test/threads/bca.xml",
    "test/threads/cab.xml",
    "test/threads/cba.xml",
    "test/threads/invalid.xml",
};

static const char *Okay = "OK";
static const char *Failed = "Failed";

#ifndef xmlDoValidityCheckingDefaultValue
#error xmlDoValidityCheckingDefaultValue is not a macro
#endif
#ifndef xmlGenericErrorContext
#error xmlGenericErrorContext is not a macro
#endif

static void *
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
	return((void *) Failed);
    return ((void *) Okay);
}

#ifdef HAVE_PTHREAD_H
int
main(void)
{
    unsigned int i, repeat;
    unsigned int num_threads = sizeof(testfiles) / sizeof(testfiles[0]);
    void *results[MAX_ARGC];
    int ret;

    xmlInitParser();
    for (repeat = 0;repeat < 500;repeat++) {
	xmlLoadCatalog(catalog);

        memset(results, 0, sizeof(*results)*num_threads);
        memset(tid, 0xff, sizeof(*tid)*num_threads);

	for (i = 0; i < num_threads; i++) {
	    ret = pthread_create(&tid[i], NULL, thread_specific_data,
				 (void *) testfiles[i]);
	    if (ret != 0) {
		perror("pthread_create");
		exit(1);
	    }
	}
	for (i = 0; i < num_threads; i++) {
	    ret = pthread_join(tid[i], &results[i]);
	    if (ret != 0) {
		perror("pthread_join");
		exit(1);
	    }
	}

	xmlCatalogCleanup();
	for (i = 0; i < num_threads; i++)
	    if (results[i] != (void *) Okay)
		printf("Thread %d handling %s failed\n", i, testfiles[i]);
    }
    xmlCleanupParser();
    xmlMemoryDump();
    return (0);
}
#elif defined HAVE_BEOS_THREADS
int
main(void)
{
    unsigned int i, repeat;
    unsigned int num_threads = sizeof(testfiles) / sizeof(testfiles[0]);
    void *results[MAX_ARGC];
    status_t ret;

    xmlInitParser();
    printf("Parser initialized\n");
    for (repeat = 0;repeat < 500;repeat++) {
    printf("repeat: %d\n",repeat);
	xmlLoadCatalog(catalog);
	printf("loaded catalog: %s\n", catalog);
	for (i = 0; i < num_threads; i++) {
	    results[i] = NULL;
	    tid[i] = (thread_id) -1;
	}
	printf("cleaned threads\n");
	for (i = 0; i < num_threads; i++) {
		tid[i] = spawn_thread(thread_specific_data, "xmlTestThread", B_NORMAL_PRIORITY, (void *) testfiles[i]);
		if (tid[i] < B_OK) {
			perror("beos_thread_create");
			exit(1);
		}
		printf("beos_thread_create %d -> %d\n", i, tid[i]);
	}
	for (i = 0; i < num_threads; i++) {
	    ret = wait_for_thread(tid[i], &results[i]);
	    printf("beos_thread_wait %d -> %d\n", i, ret);
	    if (ret != B_OK) {
			perror("beos_thread_wait");
			exit(1);
	    }
	}

	xmlCatalogCleanup();
	ret = B_OK;
	for (i = 0; i < num_threads; i++)
	    if (results[i] != (void *) Okay) {
			printf("Thread %d handling %s failed\n", i, testfiles[i]);
			ret = B_ERROR;
		}
    }
    xmlCleanupParser();
    xmlMemoryDump();

	if (ret == B_OK)
		printf("testThread : BeOS : SUCCESS!\n");
	else
		printf("testThread : BeOS : FAILED!\n");

    return (0);
}
#endif /* pthreads or BeOS threads */

#else /* !LIBXML_THREADS_ENABLED */
int
main(void)
{
    fprintf(stderr, "libxml was not compiled with thread or catalog support\n");
    return (0);
}
#endif
