/*
    SDL_windows_main.c, placed in the public domain by Sam Lantinga  4/13/98

    The WinMain function -- calls your program's main() function
*/
#include "SDL_config.h"

#ifdef __WIN32__

//#include "../../core/windows/SDL_windows.h"

/* Include this so we define UNICODE properly */
#if defined(__WIN32__)
#define WIN32_LEAN_AND_MEAN
#define STRICT
#ifndef UNICODE
#define UNICODE 1
#endif
#undef _WIN32_WINNT
#define _WIN32_WINNT  0x501   /* Need 0x410 for AlphaBlend() and 0x500 for EnumDisplayDevices(), 0x501 for raw input */
#endif

#include <windows.h>

/* Routines to convert from UTF8 to native Windows text */
#if UNICODE
#define WIN_StringToUTF8(S) SDL_iconv_string("UTF-8", "UTF-16LE", (char *)(S), (SDL_wcslen(S)+1)*sizeof(WCHAR))
#define WIN_UTF8ToString(S) (WCHAR *)SDL_iconv_string("UTF-16LE", "UTF-8", (char *)(S), SDL_strlen(S)+1)
#else
/* !!! FIXME: UTF8ToString() can just be a SDL_strdup() here. */
#define WIN_StringToUTF8(S) SDL_iconv_string("UTF-8", "ASCII", (char *)(S), (SDL_strlen(S)+1))
#define WIN_UTF8ToString(S) SDL_iconv_string("ASCII", "UTF-8", (char *)(S), SDL_strlen(S)+1)
#endif

/* Sets an error message based on a given HRESULT */
extern int WIN_SetErrorFromHRESULT(const char *prefix, HRESULT hr);

/* Sets an error message based on GetLastError(). Always return -1. */
extern int WIN_SetError(const char *prefix);

/* Wrap up the oddities of CoInitialize() into a common function. */
extern HRESULT WIN_CoInitialize(void);
extern void WIN_CoUninitialize(void);

/* Returns SDL_TRUE if we're running on Windows Vista and newer */
extern BOOL WIN_IsWindowsVistaOrGreater();

#include <stdio.h>
#include <stdlib.h>

/* Include the SDL main definition header */
#include "SDL.h"
#include "SDL_main.h"

#ifdef main
#  undef main
#endif /* main */

static void
UnEscapeQuotes(char *arg)
{
    char *last = NULL;

    while (*arg) {
        if (*arg == '"' && (last != NULL && *last == '\\')) {
            char *c_curr = arg;
            char *c_last = last;

            while (*c_curr) {
                *c_last = *c_curr;
                c_last = c_curr;
                c_curr++;
            }
            *c_last = '\0';
        }
        last = arg;
        arg++;
    }
}

/* Parse a command line buffer into arguments */
static int
ParseCommandLine(char *cmdline, char **argv)
{
    char *bufp;
    char *lastp = NULL;
    int argc, last_argc;

    argc = last_argc = 0;
    for (bufp = cmdline; *bufp;) {
        /* Skip leading whitespace */
        while (SDL_isspace(*bufp)) {
            ++bufp;
        }
        /* Skip over argument */
        if (*bufp == '"') {
            ++bufp;
            if (*bufp) {
                if (argv) {
                    argv[argc] = bufp;
                }
                ++argc;
            }
            /* Skip over word */
            lastp = bufp;
            while (*bufp && (*bufp != '"' || *lastp == '\\')) {
                lastp = bufp;
                ++bufp;
            }
        } else {
            if (*bufp) {
                if (argv) {
                    argv[argc] = bufp;
                }
                ++argc;
            }
            /* Skip over word */
            while (*bufp && !SDL_isspace(*bufp)) {
                ++bufp;
            }
        }
        if (*bufp) {
            if (argv) {
                *bufp = '\0';
            }
            ++bufp;
        }

        /* Strip out \ from \" sequences */
        if (argv && last_argc != argc) {
            UnEscapeQuotes(argv[last_argc]);
        }
        last_argc = argc;
    }
    if (argv) {
        argv[argc] = NULL;
    }
    return (argc);
}

/* Show an error message */
static void
ShowError(const char *title, const char *message)
{
/* If USE_MESSAGEBOX is defined, you need to link with user32.lib */
#ifdef USE_MESSAGEBOX
    MessageBox(NULL, message, title, MB_ICONEXCLAMATION | MB_OK);
#else
    fprintf(stderr, "%s: %s\n", title, message);
#endif
}

/* Pop up an out of memory message, returns to Windows */
static BOOL
OutOfMemory(void)
{
    ShowError("Fatal Error", "Out of memory - aborting");
    return FALSE;
}

#if defined(_MSC_VER)
/* The VC++ compiler needs main defined */
#define console_main main
#endif

/* This is where execution begins [console apps] */
int
console_main(int argc, char *argv[])
{
    int status;

    SDL_SetMainReady();

    /* Run the application main() code */
    status = SDL_main(argc, argv);

    /* Exit cleanly, calling atexit() functions */
    exit(status);

    /* Hush little compiler, don't you cry... */
    return 0;
}

/* This is where execution begins [windowed apps] */
int WINAPI
WinMain(HINSTANCE hInst, HINSTANCE hPrev, LPSTR szCmdLine, int sw)
{
    char **argv;
    int argc;
    char *cmdline;

    /* Grab the command line */
    TCHAR *text = GetCommandLine();
#if UNICODE
    cmdline = SDL_iconv_string("UTF-8", "UCS-2-INTERNAL", (char *)(text), (SDL_wcslen(text)+1)*sizeof(WCHAR));
#else
    cmdline = SDL_strdup(text);
#endif
    if (cmdline == NULL) {
        return OutOfMemory();
    }

    /* Parse it into argv and argc */
    argc = ParseCommandLine(cmdline, NULL);
    argv = SDL_stack_alloc(char *, argc + 1);
    if (argv == NULL) {
        return OutOfMemory();
    }
    ParseCommandLine(cmdline, argv);

    /* Run the main program */
    console_main(argc, argv);

    SDL_stack_free(argv);

    SDL_free(cmdline);

    /* Hush little compiler, don't you cry... */
    return 0;
}

#endif /* __WIN32__ */

/* vi: set ts=4 sw=4 expandtab: */
