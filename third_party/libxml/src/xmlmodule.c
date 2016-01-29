/*
 * xmlmodule.c : basic API for dynamic module loading added 2.6.17
 *
 * See Copyright for the status of this software.
 *
 * joelwreed@comcast.net
 *
 * http://www.fortran-2000.com/ArnaudRecipes/sharedlib.html
 */

#define IN_LIBXML
#include "libxml.h"

#include <string.h>
#include <libxml/xmlmemory.h>
#include <libxml/xmlerror.h>
#include <libxml/xmlmodule.h>
#include <libxml/globals.h>

#ifdef LIBXML_MODULES_ENABLED

struct _xmlModule {
    unsigned char *name;
    void *handle;
};

static void *xmlModulePlatformOpen(const char *name);
static int xmlModulePlatformClose(void *handle);
static int xmlModulePlatformSymbol(void *handle, const char *name, void **result);

/************************************************************************
 *									*
 * 		module memory error handler				*
 *									*
 ************************************************************************/

/**
 * xmlModuleErrMemory:
 * @extra:  extra information
 *
 * Handle an out of memory condition
 */
static void
xmlModuleErrMemory(xmlModulePtr module, const char *extra)
{
    const char *name = NULL;

    if (module != NULL) {
        name = (const char *) module->name;
    }

    __xmlRaiseError(NULL, NULL, NULL, NULL, NULL, XML_FROM_MODULE,
                    XML_ERR_NO_MEMORY, XML_ERR_FATAL, NULL, 0, extra,
                    name, NULL, 0, 0,
                    "Memory allocation failed : %s\n", extra);
}

/**
 * xmlModuleOpen:
 * @name: the module name
 * @options: a set of xmlModuleOption
 *
 * Opens a module/shared library given its name or path
 * TODO: options are not yet implemented.
 *
 * Returns a handle for the module or NULL in case of error
 */
xmlModulePtr
xmlModuleOpen(const char *name, int options ATTRIBUTE_UNUSED)
{
    xmlModulePtr module;

    module = (xmlModulePtr) xmlMalloc(sizeof(xmlModule));
    if (module == NULL) {
        xmlModuleErrMemory(NULL, "creating module");
        return (NULL);
    }

    memset(module, 0, sizeof(xmlModule));

    module->handle = xmlModulePlatformOpen(name);

    if (module->handle == NULL) {
        xmlFree(module);
        __xmlRaiseError(NULL, NULL, NULL, NULL, NULL, XML_FROM_MODULE,
                        XML_MODULE_OPEN, XML_ERR_FATAL, NULL, 0, 0,
                        name, NULL, 0, 0, "failed to open %s\n", name);
        return(NULL);
    }

    module->name = xmlStrdup((const xmlChar *) name);
    return (module);
}

/**
 * xmlModuleSymbol:
 * @module: the module
 * @name: the name of the symbol
 * @symbol: the resulting symbol address
 *
 * Lookup for a symbol address in the given module
 *
 * Returns 0 if the symbol was found, or -1 in case of error
 */
int
xmlModuleSymbol(xmlModulePtr module, const char *name, void **symbol)
{
    int rc = -1;
	
    if ((NULL == module) || (symbol == NULL)) {
        __xmlRaiseError(NULL, NULL, NULL, NULL, NULL, XML_FROM_MODULE,
                        XML_MODULE_OPEN, XML_ERR_FATAL, NULL, 0, 0,
                        NULL, NULL, 0, 0, "null parameter\n");
        return rc;
    }

    rc = xmlModulePlatformSymbol(module->handle, name, symbol);

    if (rc == -1) {
        __xmlRaiseError(NULL, NULL, NULL, NULL, NULL, XML_FROM_MODULE,
                        XML_MODULE_OPEN, XML_ERR_FATAL, NULL, 0, 0,
                        name, NULL, 0, 0,
                        "failed to find symbol: %s\n",
			(name == NULL ? "NULL" : name));
        return rc;
    }

    return rc;
}

/**
 * xmlModuleClose:
 * @module: the module handle
 *
 * The close operations unload the associated module and free the
 * data associated to the module.
 *
 * Returns 0 in case of success, -1 in case of argument error and -2
 *         if the module could not be closed/unloaded.
 */
int
xmlModuleClose(xmlModulePtr module)
{
    int rc;

    if (NULL == module) {
        __xmlRaiseError(NULL, NULL, NULL, NULL, NULL, XML_FROM_MODULE,
                        XML_MODULE_CLOSE, XML_ERR_FATAL, NULL, 0, 0,
                        NULL, NULL, 0, 0, "null module pointer\n");
        return -1;
    }

    rc = xmlModulePlatformClose(module->handle);

    if (rc != 0) {
        __xmlRaiseError(NULL, NULL, NULL, NULL, NULL, XML_FROM_MODULE,
                        XML_MODULE_CLOSE, XML_ERR_FATAL, NULL, 0, 0,
                        (const char *) module->name, NULL, 0, 0,
                        "failed to close: %s\n", module->name);
        return -2;
    }

    rc = xmlModuleFree(module);
    return (rc);
}

/**
 * xmlModuleFree:
 * @module: the module handle
 *
 * The free operations free the data associated to the module
 * but does not unload the associated shared library which may still
 * be in use.
 *
 * Returns 0 in case of success, -1 in case of argument error
 */
int
xmlModuleFree(xmlModulePtr module)
{
    if (NULL == module) {
        __xmlRaiseError(NULL, NULL, NULL, NULL, NULL, XML_FROM_MODULE,
                        XML_MODULE_CLOSE, XML_ERR_FATAL, NULL, 0, NULL,
                        NULL, NULL, 0, 0, "null module pointer\n");
        return -1;
    }

    xmlFree(module->name);
    xmlFree(module);

    return (0);
}

#if defined(HAVE_DLOPEN) && !defined(_WIN32)
#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#endif

#ifndef RTLD_GLOBAL            /* For Tru64 UNIX 4.0 */
#define RTLD_GLOBAL 0
#endif

/**
 * xmlModulePlatformOpen:
 * @name: path to the module
 *
 * returns a handle on success, and zero on error.
 */

static void *
xmlModulePlatformOpen(const char *name)
{
    return dlopen(name, RTLD_GLOBAL | RTLD_NOW);
}

/*
 * xmlModulePlatformClose:
 * @handle: handle to the module
 *
 * returns 0 on success, and non-zero on error.
 */

static int
xmlModulePlatformClose(void *handle)
{
    return dlclose(handle);
}

/*
 * xmlModulePlatformSymbol:
 * http://www.opengroup.org/onlinepubs/009695399/functions/dlsym.html
 * returns 0 on success and the loaded symbol in result, and -1 on error.
 */

static int
xmlModulePlatformSymbol(void *handle, const char *name, void **symbol)
{
    *symbol = dlsym(handle, name);
    if (dlerror() != NULL) {
	return -1;
    }
    return 0;
}

#else /* ! HAVE_DLOPEN */

#ifdef HAVE_SHLLOAD             /* HAVE_SHLLOAD */
#ifdef HAVE_DL_H
#include <dl.h>
#endif
/*
 * xmlModulePlatformOpen:
 * returns a handle on success, and zero on error.
 */

static void *
xmlModulePlatformOpen(const char *name)
{
    return shl_load(name, BIND_IMMEDIATE, 0L);
}

/*
 * xmlModulePlatformClose:
 * returns 0 on success, and non-zero on error.
 */

static int
xmlModulePlatformClose(void *handle)
{
    return shl_unload(handle);
}

/*
 * xmlModulePlatformSymbol:
 * http://docs.hp.com/en/B2355-90683/shl_load.3X.html
 * returns 0 on success and the loaded symbol in result, and -1 on error.
 */

static int
xmlModulePlatformSymbol(void *handle, const char *name, void **symbol)
{
    int rc;

    errno = 0;
    rc = shl_findsym(&handle, name, TYPE_UNDEFINED, symbol);
    return rc;
}

#endif /* HAVE_SHLLOAD */
#endif /* ! HAVE_DLOPEN */

#ifdef _WIN32

#include <windows.h>

/*
 * xmlModulePlatformOpen:
 * returns a handle on success, and zero on error.
 */

static void *
xmlModulePlatformOpen(const char *name)
{
    return LoadLibraryA(name);
}

/*
 * xmlModulePlatformClose:
 * returns 0 on success, and non-zero on error.
 */

static int
xmlModulePlatformClose(void *handle)
{
    int rc;

    rc = FreeLibrary(handle);
    return (0 == rc);
}

/*
 * xmlModulePlatformSymbol:
 * http://msdn.microsoft.com/library/default.asp?url=/library/en-us/dllproc/base/getprocaddress.asp
 * returns 0 on success and the loaded symbol in result, and -1 on error.
 */

static int
xmlModulePlatformSymbol(void *handle, const char *name, void **symbol)
{
    *symbol = GetProcAddress(handle, name);
    return (NULL == *symbol) ? -1 : 0;
}

#endif /* _WIN32 */

#ifdef HAVE_BEOS

#include <kernel/image.h>

/*
 * xmlModulePlatformOpen:
 * beos api info: http://www.beunited.org/bebook/The%20Kernel%20Kit/Images.html
 * returns a handle on success, and zero on error.
 */

static void *
xmlModulePlatformOpen(const char *name)
{
    return (void *) load_add_on(name);
}

/*
 * xmlModulePlatformClose:
 * beos api info: http://www.beunited.org/bebook/The%20Kernel%20Kit/Images.html
 * returns 0 on success, and non-zero on error.
 */

static int
xmlModulePlatformClose(void *handle)
{
    status_t rc;

    rc = unload_add_on((image_id) handle);

    if (rc == B_OK)
        return 0;
    else
        return -1;
}

/*
 * xmlModulePlatformSymbol:
 * beos api info: http://www.beunited.org/bebook/The%20Kernel%20Kit/Images.html
 * returns 0 on success and the loaded symbol in result, and -1 on error.
 */

static int
xmlModulePlatformSymbol(void *handle, const char *name, void **symbol)
{
    status_t rc;

    rc = get_image_symbol((image_id) handle, name, B_SYMBOL_TYPE_ANY, symbol);

    return (rc == B_OK) ? 0 : -1;
}

#endif /* HAVE_BEOS */

#ifdef HAVE_OS2

#include <os2.h>

/*
 * xmlModulePlatformOpen:
 * os2 api info: http://www.edm2.com/os2api/Dos/DosLoadModule.html
 * returns a handle on success, and zero on error.
 */

static void *
xmlModulePlatformOpen(const char *name)
{
    char errbuf[256];
    void *handle;
    int rc;

    rc = DosLoadModule(errbuf, sizeof(errbuf) - 1, name, &handle);

    if (rc)
        return 0;
    else
        return (handle);
}

/*
 * xmlModulePlatformClose:
 * os2 api info: http://www.edm2.com/os2api/Dos/DosFreeModule.html
 * returns 0 on success, and non-zero on error.
 */

static int
xmlModulePlatformClose(void *handle)
{
    return DosFreeModule(handle);
}

/*
 * xmlModulePlatformSymbol:
 * os2 api info: http://www.edm2.com/os2api/Dos/DosQueryProcAddr.html
 * returns 0 on success and the loaded symbol in result, and -1 on error.
 */

static int
xmlModulePlatformSymbol(void *handle, const char *name, void **symbol)
{
    int rc;

    rc = DosQueryProcAddr(handle, 0, name, symbol);

    return (rc == NO_ERROR) ? 0 : -1;
}

#endif /* HAVE_OS2 */

#define bottom_xmlmodule
#include "elfgcchack.h"
#endif /* LIBXML_MODULES_ENABLED */
