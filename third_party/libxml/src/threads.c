/**
 * threads.c: set of generic threading related routines
 *
 * See Copyright for the status of this software.
 *
 * Gary Pennington <Gary.Pennington@uk.sun.com>
 * daniel@veillard.com
 */

#define IN_LIBXML
#include "libxml.h"

#include <string.h>

#include <libxml/threads.h>
#include <libxml/globals.h>

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_PTHREAD_H
#include <pthread.h>
#elif defined HAVE_WIN32_THREADS
#include <windows.h>
#ifndef HAVE_COMPILER_TLS
#include <process.h>
#endif
#endif

#ifdef HAVE_BEOS_THREADS
#include <OS.h>
#include <TLS.h>
#endif

#if defined(SOLARIS)
#include <note.h>
#endif

/* #define DEBUG_THREADS */

#ifdef HAVE_PTHREAD_H

static int libxml_is_threaded = -1;
#ifdef __GNUC__
#ifdef linux
#if (__GNUC__ == 3 && __GNUC_MINOR__ >= 3) || (__GNUC__ > 3)
extern int pthread_once (pthread_once_t *__once_control,
                         void (*__init_routine) (void))
	   __attribute((weak));
extern void *pthread_getspecific (pthread_key_t __key)
	   __attribute((weak));
extern int pthread_setspecific (pthread_key_t __key,
                                __const void *__pointer)
	   __attribute((weak));
extern int pthread_key_create (pthread_key_t *__key,
                               void (*__destr_function) (void *))
	   __attribute((weak));
extern int pthread_key_delete (pthread_key_t __key)
	   __attribute((weak));
extern int pthread_mutex_init ()
	   __attribute((weak));
extern int pthread_mutex_destroy ()
	   __attribute((weak));
extern int pthread_mutex_lock ()
	   __attribute((weak));
extern int pthread_mutex_unlock ()
	   __attribute((weak));
extern int pthread_cond_init ()
	   __attribute((weak));
extern int pthread_cond_destroy ()
	   __attribute((weak));
extern int pthread_cond_wait ()
	   __attribute((weak));
extern int pthread_equal ()
	   __attribute((weak));
extern pthread_t pthread_self ()
	   __attribute((weak));
extern int pthread_key_create ()
	   __attribute((weak));
extern int pthread_key_delete ()
	   __attribute((weak));
extern int pthread_cond_signal ()
	   __attribute((weak));
#endif
#endif /* linux */
#endif /* __GNUC__ */
#endif /* HAVE_PTHREAD_H */

/*
 * TODO: this module still uses malloc/free and not xmlMalloc/xmlFree
 *       to avoid some crazyness since xmlMalloc/xmlFree may actually
 *       be hosted on allocated blocks needing them for the allocation ...
 */

/*
 * xmlMutex are a simple mutual exception locks
 */
struct _xmlMutex {
#ifdef HAVE_PTHREAD_H
    pthread_mutex_t lock;
#elif defined HAVE_WIN32_THREADS
    HANDLE mutex;
#elif defined HAVE_BEOS_THREADS
    sem_id sem;
    thread_id tid;
#else
    int empty;
#endif
};

/*
 * xmlRMutex are reentrant mutual exception locks
 */
struct _xmlRMutex {
#ifdef HAVE_PTHREAD_H
    pthread_mutex_t lock;
    unsigned int held;
    unsigned int waiters;
    pthread_t tid;
    pthread_cond_t cv;
#elif defined HAVE_WIN32_THREADS
    CRITICAL_SECTION cs;
    unsigned int count;
#elif defined HAVE_BEOS_THREADS
    xmlMutexPtr lock;
    thread_id tid;
    int32 count;
#else
    int empty;
#endif
};

/*
 * This module still has some internal static data.
 *   - xmlLibraryLock a global lock
 *   - globalkey used for per-thread data
 */

#ifdef HAVE_PTHREAD_H
static pthread_key_t globalkey;
static pthread_t mainthread;
static pthread_once_t once_control = PTHREAD_ONCE_INIT;
static pthread_mutex_t global_init_lock = PTHREAD_MUTEX_INITIALIZER;
#elif defined HAVE_WIN32_THREADS
#if defined(HAVE_COMPILER_TLS)
static __declspec(thread) xmlGlobalState tlstate;
static __declspec(thread) int tlstate_inited = 0;
#else /* HAVE_COMPILER_TLS */
static DWORD globalkey = TLS_OUT_OF_INDEXES;
#endif /* HAVE_COMPILER_TLS */
static DWORD mainthread;
static struct {
    DWORD done;
    DWORD control;
} run_once = { 0, 0};
static volatile LPCRITICAL_SECTION global_init_lock = NULL;

/* endif HAVE_WIN32_THREADS */
#elif defined HAVE_BEOS_THREADS
int32 globalkey = 0;
thread_id mainthread = 0;
int32 run_once_init = 0;
static int32 global_init_lock = -1;
static vint32 global_init_count = 0;
#endif

static xmlRMutexPtr xmlLibraryLock = NULL;

#ifdef LIBXML_THREAD_ENABLED
static void xmlOnceInit(void);
#endif

/**
 * xmlNewMutex:
 *
 * xmlNewMutex() is used to allocate a libxml2 token struct for use in
 * synchronizing access to data.
 *
 * Returns a new simple mutex pointer or NULL in case of error
 */
xmlMutexPtr
xmlNewMutex(void)
{
    xmlMutexPtr tok;

    if ((tok = malloc(sizeof(xmlMutex))) == NULL)
        return (NULL);
#ifdef HAVE_PTHREAD_H
    if (libxml_is_threaded != 0)
        pthread_mutex_init(&tok->lock, NULL);
#elif defined HAVE_WIN32_THREADS
    tok->mutex = CreateMutex(NULL, FALSE, NULL);
#elif defined HAVE_BEOS_THREADS
    if ((tok->sem = create_sem(1, "xmlMutex")) < B_OK) {
        free(tok);
        return NULL;
    }
    tok->tid = -1;
#endif
    return (tok);
}

/**
 * xmlFreeMutex:
 * @tok:  the simple mutex
 *
 * xmlFreeMutex() is used to reclaim resources associated with a libxml2 token
 * struct.
 */
void
xmlFreeMutex(xmlMutexPtr tok)
{
    if (tok == NULL)
        return;

#ifdef HAVE_PTHREAD_H
    if (libxml_is_threaded != 0)
        pthread_mutex_destroy(&tok->lock);
#elif defined HAVE_WIN32_THREADS
    CloseHandle(tok->mutex);
#elif defined HAVE_BEOS_THREADS
    delete_sem(tok->sem);
#endif
    free(tok);
}

/**
 * xmlMutexLock:
 * @tok:  the simple mutex
 *
 * xmlMutexLock() is used to lock a libxml2 token.
 */
void
xmlMutexLock(xmlMutexPtr tok)
{
    if (tok == NULL)
        return;
#ifdef HAVE_PTHREAD_H
    if (libxml_is_threaded != 0)
        pthread_mutex_lock(&tok->lock);
#elif defined HAVE_WIN32_THREADS
    WaitForSingleObject(tok->mutex, INFINITE);
#elif defined HAVE_BEOS_THREADS
    if (acquire_sem(tok->sem) != B_NO_ERROR) {
#ifdef DEBUG_THREADS
        xmlGenericError(xmlGenericErrorContext,
                        "xmlMutexLock():BeOS:Couldn't aquire semaphore\n");
        exit();
#endif
    }
    tok->tid = find_thread(NULL);
#endif

}

/**
 * xmlMutexUnlock:
 * @tok:  the simple mutex
 *
 * xmlMutexUnlock() is used to unlock a libxml2 token.
 */
void
xmlMutexUnlock(xmlMutexPtr tok)
{
    if (tok == NULL)
        return;
#ifdef HAVE_PTHREAD_H
    if (libxml_is_threaded != 0)
        pthread_mutex_unlock(&tok->lock);
#elif defined HAVE_WIN32_THREADS
    ReleaseMutex(tok->mutex);
#elif defined HAVE_BEOS_THREADS
    if (tok->tid == find_thread(NULL)) {
        tok->tid = -1;
        release_sem(tok->sem);
    }
#endif
}

/**
 * xmlNewRMutex:
 *
 * xmlRNewMutex() is used to allocate a reentrant mutex for use in
 * synchronizing access to data. token_r is a re-entrant lock and thus useful
 * for synchronizing access to data structures that may be manipulated in a
 * recursive fashion.
 *
 * Returns the new reentrant mutex pointer or NULL in case of error
 */
xmlRMutexPtr
xmlNewRMutex(void)
{
    xmlRMutexPtr tok;

    if ((tok = malloc(sizeof(xmlRMutex))) == NULL)
        return (NULL);
#ifdef HAVE_PTHREAD_H
    if (libxml_is_threaded != 0) {
        pthread_mutex_init(&tok->lock, NULL);
        tok->held = 0;
        tok->waiters = 0;
        pthread_cond_init(&tok->cv, NULL);
    }
#elif defined HAVE_WIN32_THREADS
    InitializeCriticalSection(&tok->cs);
    tok->count = 0;
#elif defined HAVE_BEOS_THREADS
    if ((tok->lock = xmlNewMutex()) == NULL) {
        free(tok);
        return NULL;
    }
    tok->count = 0;
#endif
    return (tok);
}

/**
 * xmlFreeRMutex:
 * @tok:  the reentrant mutex
 *
 * xmlRFreeMutex() is used to reclaim resources associated with a
 * reentrant mutex.
 */
void
xmlFreeRMutex(xmlRMutexPtr tok ATTRIBUTE_UNUSED)
{
    if (tok == NULL)
        return;
#ifdef HAVE_PTHREAD_H
    if (libxml_is_threaded != 0) {
        pthread_mutex_destroy(&tok->lock);
        pthread_cond_destroy(&tok->cv);
    }
#elif defined HAVE_WIN32_THREADS
    DeleteCriticalSection(&tok->cs);
#elif defined HAVE_BEOS_THREADS
    xmlFreeMutex(tok->lock);
#endif
    free(tok);
}

/**
 * xmlRMutexLock:
 * @tok:  the reentrant mutex
 *
 * xmlRMutexLock() is used to lock a libxml2 token_r.
 */
void
xmlRMutexLock(xmlRMutexPtr tok)
{
    if (tok == NULL)
        return;
#ifdef HAVE_PTHREAD_H
    if (libxml_is_threaded == 0)
        return;

    pthread_mutex_lock(&tok->lock);
    if (tok->held) {
        if (pthread_equal(tok->tid, pthread_self())) {
            tok->held++;
            pthread_mutex_unlock(&tok->lock);
            return;
        } else {
            tok->waiters++;
            while (tok->held)
                pthread_cond_wait(&tok->cv, &tok->lock);
            tok->waiters--;
        }
    }
    tok->tid = pthread_self();
    tok->held = 1;
    pthread_mutex_unlock(&tok->lock);
#elif defined HAVE_WIN32_THREADS
    EnterCriticalSection(&tok->cs);
    ++tok->count;
#elif defined HAVE_BEOS_THREADS
    if (tok->lock->tid == find_thread(NULL)) {
        tok->count++;
        return;
    } else {
        xmlMutexLock(tok->lock);
        tok->count = 1;
    }
#endif
}

/**
 * xmlRMutexUnlock:
 * @tok:  the reentrant mutex
 *
 * xmlRMutexUnlock() is used to unlock a libxml2 token_r.
 */
void
xmlRMutexUnlock(xmlRMutexPtr tok ATTRIBUTE_UNUSED)
{
    if (tok == NULL)
        return;
#ifdef HAVE_PTHREAD_H
    if (libxml_is_threaded == 0)
        return;

    pthread_mutex_lock(&tok->lock);
    tok->held--;
    if (tok->held == 0) {
        if (tok->waiters)
            pthread_cond_signal(&tok->cv);
        memset(&tok->tid, 0, sizeof(tok->tid));
    }
    pthread_mutex_unlock(&tok->lock);
#elif defined HAVE_WIN32_THREADS
    if (!--tok->count)
        LeaveCriticalSection(&tok->cs);
#elif defined HAVE_BEOS_THREADS
    if (tok->lock->tid == find_thread(NULL)) {
        tok->count--;
        if (tok->count == 0) {
            xmlMutexUnlock(tok->lock);
        }
        return;
    }
#endif
}

/**
 * xmlGlobalInitMutexLock
 *
 * Makes sure that the global initialization mutex is initialized and
 * locks it.
 */
void
__xmlGlobalInitMutexLock(void)
{
    /* Make sure the global init lock is initialized and then lock it. */
#ifdef HAVE_PTHREAD_H
    /* The mutex is statically initialized, so we just lock it. */
    pthread_mutex_lock(&global_init_lock);
#elif defined HAVE_WIN32_THREADS
    LPCRITICAL_SECTION cs;

    /* Create a new critical section */
    if (global_init_lock == NULL) {
        cs = malloc(sizeof(CRITICAL_SECTION));
        if (cs == NULL) {
            xmlGenericError(xmlGenericErrorContext,
                            "xmlGlobalInitMutexLock: out of memory\n");
            return;
        }
        InitializeCriticalSection(cs);

        /* Swap it into the global_init_lock */
#ifdef InterlockedCompareExchangePointer
        InterlockedCompareExchangePointer(&global_init_lock, cs, NULL);
#else /* Use older void* version */
        InterlockedCompareExchange((void **) &global_init_lock,
                                   (void *) cs, NULL);
#endif /* InterlockedCompareExchangePointer */

        /* If another thread successfully recorded its critical
         * section in the global_init_lock then discard the one
         * allocated by this thread. */
        if (global_init_lock != cs) {
            DeleteCriticalSection(cs);
            free(cs);
        }
    }

    /* Lock the chosen critical section */
    EnterCriticalSection(global_init_lock);
#elif defined HAVE_BEOS_THREADS
    int32 sem;

    /* Allocate a new semaphore */
    sem = create_sem(1, "xmlGlobalinitMutex");

    while (global_init_lock == -1) {
        if (atomic_add(&global_init_count, 1) == 0) {
            global_init_lock = sem;
        } else {
            snooze(1);
            atomic_add(&global_init_count, -1);
        }
    }

    /* If another thread successfully recorded its critical
     * section in the global_init_lock then discard the one
     * allocated by this thread. */
    if (global_init_lock != sem)
        delete_sem(sem);

    /* Acquire the chosen semaphore */
    if (acquire_sem(global_init_lock) != B_NO_ERROR) {
#ifdef DEBUG_THREADS
        xmlGenericError(xmlGenericErrorContext,
                        "xmlGlobalInitMutexLock():BeOS:Couldn't acquire semaphore\n");
        exit();
#endif
    }
#endif
}

void
__xmlGlobalInitMutexUnlock(void)
{
#ifdef HAVE_PTHREAD_H
    pthread_mutex_unlock(&global_init_lock);
#elif defined HAVE_WIN32_THREADS
    if (global_init_lock != NULL) {
	LeaveCriticalSection(global_init_lock);
    }
#elif defined HAVE_BEOS_THREADS
    release_sem(global_init_lock);
#endif
}

/**
 * xmlGlobalInitMutexDestroy
 *
 * Makes sure that the global initialization mutex is destroyed before
 * application termination.
 */
void
__xmlGlobalInitMutexDestroy(void)
{
#ifdef HAVE_PTHREAD_H
#elif defined HAVE_WIN32_THREADS
    if (global_init_lock != NULL) {
        DeleteCriticalSection(global_init_lock);
        free(global_init_lock);
        global_init_lock = NULL;
    }
#endif
}

/************************************************************************
 *									*
 *			Per thread global state handling		*
 *									*
 ************************************************************************/

#ifdef LIBXML_THREAD_ENABLED
#ifdef xmlLastError
#undef xmlLastError
#endif

/**
 * xmlFreeGlobalState:
 * @state:  a thread global state
 *
 * xmlFreeGlobalState() is called when a thread terminates with a non-NULL
 * global state. It is is used here to reclaim memory resources.
 */
static void
xmlFreeGlobalState(void *state)
{
    xmlGlobalState *gs = (xmlGlobalState *) state;

    /* free any memory allocated in the thread's xmlLastError */
    xmlResetError(&(gs->xmlLastError));
    free(state);
}

/**
 * xmlNewGlobalState:
 *
 * xmlNewGlobalState() allocates a global state. This structure is used to
 * hold all data for use by a thread when supporting backwards compatibility
 * of libxml2 to pre-thread-safe behaviour.
 *
 * Returns the newly allocated xmlGlobalStatePtr or NULL in case of error
 */
static xmlGlobalStatePtr
xmlNewGlobalState(void)
{
    xmlGlobalState *gs;

    gs = malloc(sizeof(xmlGlobalState));
    if (gs == NULL) {
	xmlGenericError(xmlGenericErrorContext,
			"xmlGetGlobalState: out of memory\n");
        return (NULL);
    }

    memset(gs, 0, sizeof(xmlGlobalState));
    xmlInitializeGlobalState(gs);
    return (gs);
}
#endif /* LIBXML_THREAD_ENABLED */

#ifdef HAVE_PTHREAD_H
#elif defined HAVE_WIN32_THREADS
#if !defined(HAVE_COMPILER_TLS)
#if defined(LIBXML_STATIC) && !defined(LIBXML_STATIC_FOR_DLL)
typedef struct _xmlGlobalStateCleanupHelperParams {
    HANDLE thread;
    void *memory;
} xmlGlobalStateCleanupHelperParams;

static void XMLCDECL
xmlGlobalStateCleanupHelper(void *p)
{
    xmlGlobalStateCleanupHelperParams *params =
        (xmlGlobalStateCleanupHelperParams *) p;
    WaitForSingleObject(params->thread, INFINITE);
    CloseHandle(params->thread);
    xmlFreeGlobalState(params->memory);
    free(params);
    _endthread();
}
#else /* LIBXML_STATIC && !LIBXML_STATIC_FOR_DLL */

typedef struct _xmlGlobalStateCleanupHelperParams {
    void *memory;
    struct _xmlGlobalStateCleanupHelperParams *prev;
    struct _xmlGlobalStateCleanupHelperParams *next;
} xmlGlobalStateCleanupHelperParams;

static xmlGlobalStateCleanupHelperParams *cleanup_helpers_head = NULL;
static CRITICAL_SECTION cleanup_helpers_cs;

#endif /* LIBXMLSTATIC && !LIBXML_STATIC_FOR_DLL */
#endif /* HAVE_COMPILER_TLS */
#endif /* HAVE_WIN32_THREADS */

#if defined HAVE_BEOS_THREADS

/**
 * xmlGlobalStateCleanup:
 * @data: unused parameter
 *
 * Used for Beos only
 */
void
xmlGlobalStateCleanup(void *data)
{
    void *globalval = tls_get(globalkey);

    if (globalval != NULL)
        xmlFreeGlobalState(globalval);
}
#endif

/**
 * xmlGetGlobalState:
 *
 * xmlGetGlobalState() is called to retrieve the global state for a thread.
 *
 * Returns the thread global state or NULL in case of error
 */
xmlGlobalStatePtr
xmlGetGlobalState(void)
{
#ifdef HAVE_PTHREAD_H
    xmlGlobalState *globalval;

    if (libxml_is_threaded == 0)
        return (NULL);

    pthread_once(&once_control, xmlOnceInit);

    if ((globalval = (xmlGlobalState *)
         pthread_getspecific(globalkey)) == NULL) {
        xmlGlobalState *tsd = xmlNewGlobalState();
	if (tsd == NULL)
	    return(NULL);

        pthread_setspecific(globalkey, tsd);
        return (tsd);
    }
    return (globalval);
#elif defined HAVE_WIN32_THREADS
#if defined(HAVE_COMPILER_TLS)
    if (!tlstate_inited) {
        tlstate_inited = 1;
        xmlInitializeGlobalState(&tlstate);
    }
    return &tlstate;
#else /* HAVE_COMPILER_TLS */
    xmlGlobalState *globalval;
    xmlGlobalStateCleanupHelperParams *p;

    xmlOnceInit();
#if defined(LIBXML_STATIC) && !defined(LIBXML_STATIC_FOR_DLL)
    globalval = (xmlGlobalState *) TlsGetValue(globalkey);
#else
    p = (xmlGlobalStateCleanupHelperParams *) TlsGetValue(globalkey);
    globalval = (xmlGlobalState *) (p ? p->memory : NULL);
#endif
    if (globalval == NULL) {
        xmlGlobalState *tsd = xmlNewGlobalState();

        if (tsd == NULL)
	    return(NULL);
        p = (xmlGlobalStateCleanupHelperParams *)
            malloc(sizeof(xmlGlobalStateCleanupHelperParams));
	if (p == NULL) {
            xmlGenericError(xmlGenericErrorContext,
                            "xmlGetGlobalState: out of memory\n");
            xmlFreeGlobalState(tsd);
	    return(NULL);
	}
        p->memory = tsd;
#if defined(LIBXML_STATIC) && !defined(LIBXML_STATIC_FOR_DLL)
        DuplicateHandle(GetCurrentProcess(), GetCurrentThread(),
                        GetCurrentProcess(), &p->thread, 0, TRUE,
                        DUPLICATE_SAME_ACCESS);
        TlsSetValue(globalkey, tsd);
        _beginthread(xmlGlobalStateCleanupHelper, 0, p);
#else
        EnterCriticalSection(&cleanup_helpers_cs);
        if (cleanup_helpers_head != NULL) {
            cleanup_helpers_head->prev = p;
        }
        p->next = cleanup_helpers_head;
        p->prev = NULL;
        cleanup_helpers_head = p;
        TlsSetValue(globalkey, p);
        LeaveCriticalSection(&cleanup_helpers_cs);
#endif

        return (tsd);
    }
    return (globalval);
#endif /* HAVE_COMPILER_TLS */
#elif defined HAVE_BEOS_THREADS
    xmlGlobalState *globalval;

    xmlOnceInit();

    if ((globalval = (xmlGlobalState *) tls_get(globalkey)) == NULL) {
        xmlGlobalState *tsd = xmlNewGlobalState();
	if (tsd == NULL)
	    return (NULL);

        tls_set(globalkey, tsd);
        on_exit_thread(xmlGlobalStateCleanup, NULL);
        return (tsd);
    }
    return (globalval);
#else
    return (NULL);
#endif
}

/************************************************************************
 *									*
 *			Library wide thread interfaces			*
 *									*
 ************************************************************************/

/**
 * xmlGetThreadId:
 *
 * xmlGetThreadId() find the current thread ID number
 * Note that this is likely to be broken on some platforms using pthreads
 * as the specification doesn't mandate pthread_t to be an integer type
 *
 * Returns the current thread ID number
 */
int
xmlGetThreadId(void)
{
#ifdef HAVE_PTHREAD_H
    pthread_t id;
    int ret;

    if (libxml_is_threaded == 0)
        return (0);
    id = pthread_self();
    /* horrible but preserves compat, see warning above */
    memcpy(&ret, &id, sizeof(ret));
    return (ret);
#elif defined HAVE_WIN32_THREADS
    return GetCurrentThreadId();
#elif defined HAVE_BEOS_THREADS
    return find_thread(NULL);
#else
    return ((int) 0);
#endif
}

/**
 * xmlIsMainThread:
 *
 * xmlIsMainThread() check whether the current thread is the main thread.
 *
 * Returns 1 if the current thread is the main thread, 0 otherwise
 */
int
xmlIsMainThread(void)
{
#ifdef HAVE_PTHREAD_H
    if (libxml_is_threaded == -1)
        xmlInitThreads();
    if (libxml_is_threaded == 0)
        return (1);
    pthread_once(&once_control, xmlOnceInit);
#elif defined HAVE_WIN32_THREADS
    xmlOnceInit();
#elif defined HAVE_BEOS_THREADS
    xmlOnceInit();
#endif

#ifdef DEBUG_THREADS
    xmlGenericError(xmlGenericErrorContext, "xmlIsMainThread()\n");
#endif
#ifdef HAVE_PTHREAD_H
    return (pthread_equal(mainthread,pthread_self()));
#elif defined HAVE_WIN32_THREADS
    return (mainthread == GetCurrentThreadId());
#elif defined HAVE_BEOS_THREADS
    return (mainthread == find_thread(NULL));
#else
    return (1);
#endif
}

/**
 * xmlLockLibrary:
 *
 * xmlLockLibrary() is used to take out a re-entrant lock on the libxml2
 * library.
 */
void
xmlLockLibrary(void)
{
#ifdef DEBUG_THREADS
    xmlGenericError(xmlGenericErrorContext, "xmlLockLibrary()\n");
#endif
    xmlRMutexLock(xmlLibraryLock);
}

/**
 * xmlUnlockLibrary:
 *
 * xmlUnlockLibrary() is used to release a re-entrant lock on the libxml2
 * library.
 */
void
xmlUnlockLibrary(void)
{
#ifdef DEBUG_THREADS
    xmlGenericError(xmlGenericErrorContext, "xmlUnlockLibrary()\n");
#endif
    xmlRMutexUnlock(xmlLibraryLock);
}

/**
 * xmlInitThreads:
 *
 * xmlInitThreads() is used to to initialize all the thread related
 * data of the libxml2 library.
 */
void
xmlInitThreads(void)
{
#ifdef HAVE_PTHREAD_H
    if (libxml_is_threaded == -1) {
        if ((pthread_once != NULL) &&
            (pthread_getspecific != NULL) &&
            (pthread_setspecific != NULL) &&
            (pthread_key_create != NULL) &&
            (pthread_key_delete != NULL) &&
            (pthread_mutex_init != NULL) &&
            (pthread_mutex_destroy != NULL) &&
            (pthread_mutex_lock != NULL) &&
            (pthread_mutex_unlock != NULL) &&
            (pthread_cond_init != NULL) &&
            (pthread_cond_destroy != NULL) &&
            (pthread_cond_wait != NULL) &&
            (pthread_equal != NULL) &&
            (pthread_self != NULL) &&
            (pthread_cond_signal != NULL)) {
            libxml_is_threaded = 1;

/* fprintf(stderr, "Running multithreaded\n"); */
        } else {

/* fprintf(stderr, "Running without multithread\n"); */
            libxml_is_threaded = 0;
        }
    }
#elif defined(HAVE_WIN32_THREADS) && !defined(HAVE_COMPILER_TLS) && (!defined(LIBXML_STATIC) || defined(LIBXML_STATIC_FOR_DLL))
    InitializeCriticalSection(&cleanup_helpers_cs);
#endif
}

/**
 * xmlCleanupThreads:
 *
 * xmlCleanupThreads() is used to to cleanup all the thread related
 * data of the libxml2 library once processing has ended.
 *
 * WARNING: if your application is multithreaded or has plugin support
 *          calling this may crash the application if another thread or
 *          a plugin is still using libxml2. It's sometimes very hard to
 *          guess if libxml2 is in use in the application, some libraries
 *          or plugins may use it without notice. In case of doubt abstain
 *          from calling this function or do it just before calling exit()
 *          to avoid leak reports from valgrind !
 */
void
xmlCleanupThreads(void)
{
#ifdef DEBUG_THREADS
    xmlGenericError(xmlGenericErrorContext, "xmlCleanupThreads()\n");
#endif
#ifdef HAVE_PTHREAD_H
    if ((libxml_is_threaded)  && (pthread_key_delete != NULL))
        pthread_key_delete(globalkey);
#elif defined(HAVE_WIN32_THREADS) && !defined(HAVE_COMPILER_TLS) && (!defined(LIBXML_STATIC) || defined(LIBXML_STATIC_FOR_DLL))
    if (globalkey != TLS_OUT_OF_INDEXES) {
        xmlGlobalStateCleanupHelperParams *p;

        EnterCriticalSection(&cleanup_helpers_cs);
        p = cleanup_helpers_head;
        while (p != NULL) {
            xmlGlobalStateCleanupHelperParams *temp = p;

            p = p->next;
            xmlFreeGlobalState(temp->memory);
            free(temp);
        }
        cleanup_helpers_head = 0;
        LeaveCriticalSection(&cleanup_helpers_cs);
        TlsFree(globalkey);
        globalkey = TLS_OUT_OF_INDEXES;
    }
    DeleteCriticalSection(&cleanup_helpers_cs);
#endif
}

#ifdef LIBXML_THREAD_ENABLED

/**
 * xmlOnceInit
 *
 * xmlOnceInit() is used to initialize the value of mainthread for use
 * in other routines. This function should only be called using
 * pthread_once() in association with the once_control variable to ensure
 * that the function is only called once. See man pthread_once for more
 * details.
 */
static void
xmlOnceInit(void)
{
#ifdef HAVE_PTHREAD_H
    (void) pthread_key_create(&globalkey, xmlFreeGlobalState);
    mainthread = pthread_self();
#elif defined(HAVE_WIN32_THREADS)
    if (!run_once.done) {
        if (InterlockedIncrement(&run_once.control) == 1) {
#if !defined(HAVE_COMPILER_TLS)
            globalkey = TlsAlloc();
#endif
            mainthread = GetCurrentThreadId();
            run_once.done = 1;
        } else {
            /* Another thread is working; give up our slice and
             * wait until they're done. */
            while (!run_once.done)
                Sleep(0);
        }
    }
#elif defined HAVE_BEOS_THREADS
    if (atomic_add(&run_once_init, 1) == 0) {
        globalkey = tls_allocate();
        tls_set(globalkey, NULL);
        mainthread = find_thread(NULL);
    } else
        atomic_add(&run_once_init, -1);
#endif
}
#endif

/**
 * DllMain:
 * @hinstDLL: handle to DLL instance
 * @fdwReason: Reason code for entry
 * @lpvReserved: generic pointer (depends upon reason code)
 *
 * Entry point for Windows library. It is being used to free thread-specific
 * storage.
 *
 * Returns TRUE always
 */
#ifdef HAVE_PTHREAD_H
#elif defined(HAVE_WIN32_THREADS) && !defined(HAVE_COMPILER_TLS) && (!defined(LIBXML_STATIC) || defined(LIBXML_STATIC_FOR_DLL))
#if defined(LIBXML_STATIC_FOR_DLL)
BOOL XMLCALL
xmlDllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
#else
BOOL WINAPI
DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
#endif
{
    switch (fdwReason) {
        case DLL_THREAD_DETACH:
            if (globalkey != TLS_OUT_OF_INDEXES) {
                xmlGlobalState *globalval = NULL;
                xmlGlobalStateCleanupHelperParams *p =
                    (xmlGlobalStateCleanupHelperParams *)
                    TlsGetValue(globalkey);
                globalval = (xmlGlobalState *) (p ? p->memory : NULL);
                if (globalval) {
                    xmlFreeGlobalState(globalval);
                    TlsSetValue(globalkey, NULL);
                }
                if (p) {
                    EnterCriticalSection(&cleanup_helpers_cs);
                    if (p == cleanup_helpers_head)
                        cleanup_helpers_head = p->next;
                    else
                        p->prev->next = p->next;
                    if (p->next != NULL)
                        p->next->prev = p->prev;
                    LeaveCriticalSection(&cleanup_helpers_cs);
                    free(p);
                }
            }
            break;
    }
    return TRUE;
}
#endif
#define bottom_threads
#include "elfgcchack.h"
