// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// <stdio.h>-lookalike-ish. Note that this is a C header, so that crappy (and
// non-crappy) C programs can use it.
//
// In general, functions/types/macros are given "mojio_"/"MOJIO_"/etc. prefixes.
// There are a handful of exceptions (noted below).
//
// One should be able to have a drop-in <stdio.h> replacement using just (C99)
// inline functions, typedefs, and macro definitions. (For "native" apps, doing
// so in C is somewhat problematic, due to conflicts with the "native" C
// library.)
//
// TODO(vtl): The lack of |restrict|s in certain functions is slightly
// mysterious to me, but it's consistent with glibc. I don't know what the
// standard specifies.

#ifndef MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_STDIO_H_
#define MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_STDIO_H_

// Includes --------------------------------------------------------------------

// We need |va_list|.
#include <stdarg.h>

// <stdio.h> is required to define |NULL| (as a macro) and |size_t|. We don't
// define our own (with prefixes), and just use the standard ones from
// <stddef.h>.
#include <stddef.h>

#include "files/public/c/mojio_config.h"

// Macros ----------------------------------------------------------------------

// Default buffer size.
#define MOJIO_BUFSIZ MOJIO_CONFIG_BUFSIZ

// |EOF|: -1 in the known universe. Probably nothing would work if different.
#define MOJIO_EOF (-1)

// Recommended size for arrays meant to hold a filename.
#define MOJIO_FILENAME_MAX MOJIO_CONFIG_FILENAME_MAX

// Supposed maximum number of files opened simultaneously. May be a total lie.
#define MOJIO_FOPEN_MAX MOJIO_CONFIG_FOPEN_MAX

// Minimum size needed for |mojio_tmpnam()| (includes terminating null).
#define MOJIO_L_tmpnam 20

// Minimum number of unique names guaranteed possible from |mojio_tmpnam()|.
// (Note: This is (2*26+10)^3, in case you're wondering.)
#define MOJIO_TMP_MAX 238328

// "Whence". These are duplicated (verbatim) in mojio_unistd.h.
#define MOJIO_SEEK_SET 0
#define MOJIO_SEEK_CUR 1
#define MOJIO_SEEK_END 2

// For |mojio_setvbuf()| (excuse the extra underscores).
#define MOJIO__IOFBF
#define MOJIO__IOLBF
#define MOJIO__IONBF

// |stdin|/|stdout|/|stderr| are actually required to be macros. Haha. (We
// actually define globals further below.) It's actually somewhat reasonable:
// it'd allow one to make a <stdio.h> from this by defining |stdin| to be
// |mojio_stdin|, etc.
#define mojio_stdin mojio_stdin
#define mojio_stdout mojio_stdout
#define mojio_stderr mojio_stderr

// Types -----------------------------------------------------------------------

// <stdio.h> is required to define two types in addition to |size_t|:

// |FILE| is fully opaque (but must be a typedef) -- only |FILE*|s are ever
// used.
typedef struct MojioFileImpl MOJIO_FILE;

// |fpos_t| is supposedly opaque (e.g., could theoretically be a struct), but
// callers must be able to declare instances.
typedef mojio_config_int64 mojio_fpos_t;

// Functions -------------------------------------------------------------------

#ifdef __cplusplus
extern "C" {
#endif

// TODO(vtl): None of the things below are implemented yet.

// Operations on files:
int mojio_remove(const char* filename);
int mojio_rename(const char* oldname, const char* newname);
MOJIO_FILE* mojio_tmpfile(void);
char* mojio_tmpnam(char* s);

// File access:
int mojio_fclose(MOJIO_FILE* stream);
int mojio_fflush(MOJIO_FILE* stream);
MOJIO_FILE* mojio_fopen(const char* MOJIO_CONFIG_RESTRICT filename,
                        const char* MOJIO_CONFIG_RESTRICT mode);
MOJIO_FILE* mojio_freopen(const char* MOJIO_CONFIG_RESTRICT filename,
                          const char* MOJIO_CONFIG_RESTRICT mode,
                          MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream);
void mojio_setbuf(MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream,
                  char* MOJIO_CONFIG_RESTRICT buffer);
int mojio_setvbuf(MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream,
                  char* MOJIO_CONFIG_RESTRICT buffer,
                  int mode,
                  size_t size);

// Formatted input/output:
int mojio_fprintf(MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream,
                  const char* MOJIO_CONFIG_RESTRICT format,
                  ...);
int mojio_fscanf(MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream,
                 const char* MOJIO_CONFIG_RESTRICT format,
                 ...);
int mojio_printf(const char* MOJIO_CONFIG_RESTRICT format, ...);
int mojio_scanf(const char* MOJIO_CONFIG_RESTRICT format, ...);
int mojio_snprintf(char* MOJIO_CONFIG_RESTRICT s,
                   size_t n,
                   const char* MOJIO_CONFIG_RESTRICT format,
                   ...);
int mojio_sprintf(char* MOJIO_CONFIG_RESTRICT s,
                  const char* MOJIO_CONFIG_RESTRICT format,
                  ...);
int mojio_sscanf(const char* MOJIO_CONFIG_RESTRICT s,
                 const char* MOJIO_CONFIG_RESTRICT format,
                 ...);
int mojio_vfprintf(MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream,
                   const char* MOJIO_CONFIG_RESTRICT format,
                   va_list arg);
int mojio_vfscanf(MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream,
                  const char* MOJIO_CONFIG_RESTRICT format,
                  va_list arg);
int mojio_vprintf(const char* MOJIO_CONFIG_RESTRICT format, va_list arg);
int mojio_vscanf(const char* MOJIO_CONFIG_RESTRICT format, va_list arg);
int mojio_vsnprintf(char* MOJIO_CONFIG_RESTRICT s,
                    size_t n,
                    const char* MOJIO_CONFIG_RESTRICT format,
                    va_list arg);
int mojio_vsprintf(char* MOJIO_CONFIG_RESTRICT s,
                   const char* MOJIO_CONFIG_RESTRICT format,
                   va_list arg);
int mojio_vsscanf(const char* MOJIO_CONFIG_RESTRICT s,
                  const char* MOJIO_CONFIG_RESTRICT format,
                  va_list arg);

// Character input/output:
int mojio_fgetc(MOJIO_FILE* stream);
char* mojio_fgets(char* MOJIO_CONFIG_RESTRICT s,
                  int n,
                  MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream);
int mojio_fputc(int c, MOJIO_FILE* stream);
int mojio_fputs(const char* MOJIO_CONFIG_RESTRICT s,
                MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream);
int mojio_getc(MOJIO_FILE* stream);
int mojio_getchar(void);
char* mojio_gets(char* s);
int mojio_putc(int c, MOJIO_FILE* stream);
int mojio_putchar(int c);
int mojio_puts(const char* s);
int mojio_ungetc(int c, MOJIO_FILE* stream);

// Direct input/output:
size_t mojio_fread(void* MOJIO_CONFIG_RESTRICT ptr,
                   size_t size,
                   size_t nmemb,
                   MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream);
size_t mojio_fwrite(const void* MOJIO_CONFIG_RESTRICT ptr,
                    size_t size,
                    size_t nmemb,
                    MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream);

// File positioning:
int mojio_fgetpos(MOJIO_FILE* MOJIO_CONFIG_RESTRICT stream,
                  fpos_t* MOJIO_CONFIG_RESTRICT pos);
int mojio_fseek(MOJIO_FILE* stream, long offset, int whence);
int mojio_fsetpos(MOJIO_FILE* stream, const fpos_t* pos);
long mojio_ftell(MOJIO_FILE* stream);
void mojio_rewind(MOJIO_FILE* stream);

// Error-handling:
void mojio_clearerr(MOJIO_FILE* stream);
int mojio_feof(MOJIO_FILE* stream);
int mojio_ferror(MOJIO_FILE* stream);
void mojio_perror(const char* s);

// Globals ---------------------------------------------------------------------

extern MOJIO_FILE* mojio_stdin;
extern MOJIO_FILE* mojio_stdout;
extern MOJIO_FILE* mojio_stderr;

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_STDIO_H_
