/* gzwrite.c -- zlib functions for writing gzip files
 * Copyright (C) 2004, 2005, 2010 Mark Adler
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

#include "gzguts.h"

/* Local functions */
local int gz_init OF((gz_statep));
local int gz_comp OF((gz_statep, int));
local int gz_zero OF((gz_statep, z_off64_t));

/* Initialize state for writing a gzip file.  Mark initialization by setting
   state->size to non-zero.  Return -1 on failure or 0 on success. */
local int gz_init(state)
    gz_statep state;
{
    int ret;
    z_streamp strm = &(state->strm);

    /* allocate input and output buffers */
    state->in = malloc(state->want);
    state->out = malloc(state->want);
    if (state->in == NULL || state->out == NULL) {
        if (state->out != NULL)
            free(state->out);
        if (state->in != NULL)
            free(state->in);
        gz_error(state, Z_MEM_ERROR, "out of memory");
        return -1;
    }

    /* allocate deflate memory, set up for gzip compression */
    strm->zalloc = Z_NULL;
    strm->zfree = Z_NULL;
    strm->opaque = Z_NULL;
    ret = deflateInit2(strm, state->level, Z_DEFLATED,
                       15 + 16, 8, state->strategy);
    if (ret != Z_OK) {
        free(state->in);
        gz_error(state, Z_MEM_ERROR, "out of memory");
        return -1;
    }

    /* mark state as initialized */
    state->size = state->want;

    /* initialize write buffer */
    strm->avail_out = state->size;
    strm->next_out = state->out;
    state->next = strm->next_out;
    return 0;
}

/* Compress whatever is at avail_in and next_in and write to the output file.
   Return -1 if there is an error writing to the output file, otherwise 0.
   flush is assumed to be a valid deflate() flush value.  If flush is Z_FINISH,
   then the deflate() state is reset to start a new gzip stream. */
local int gz_comp(state, flush)
    gz_statep state;
    int flush;
{
    int ret, got;
    unsigned have;
    z_streamp strm = &(state->strm);

    /* allocate memory if this is the first time through */
    if (state->size == 0 && gz_init(state) == -1)
        return -1;

    /* run deflate() on provided input until it produces no more output */
    ret = Z_OK;
    do {
        /* write out current buffer contents if full, or if flushing, but if
           doing Z_FINISH then don't write until we get to Z_STREAM_END */
        if (strm->avail_out == 0 || (flush != Z_NO_FLUSH &&
            (flush != Z_FINISH || ret == Z_STREAM_END))) {
            have = (unsigned)(strm->next_out - state->next);
            if (have && ((got = write(state->fd, state->next, have)) < 0 ||
                         (unsigned)got != have)) {
                gz_error(state, Z_ERRNO, zstrerror());
                return -1;
            }
            if (strm->avail_out == 0) {
                strm->avail_out = state->size;
                strm->next_out = state->out;
            }
            state->next = strm->next_out;
        }

        /* compress */
        have = strm->avail_out;
        ret = deflate(strm, flush);
        if (ret == Z_STREAM_ERROR) {
            gz_error(state, Z_STREAM_ERROR,
                      "internal error: deflate stream corrupt");
            return -1;
        }
        have -= strm->avail_out;
    } while (have);

    /* if that completed a deflate stream, allow another to start */
    if (flush == Z_FINISH)
        deflateReset(strm);

    /* all done, no errors */
    return 0;
}

/* Compress len zeros to output.  Return -1 on error, 0 on success. */
local int gz_zero(state, len)
    gz_statep state;
    z_off64_t len;
{
    int first;
    unsigned n;
    z_streamp strm = &(state->strm);

    /* consume whatever's left in the input buffer */
    if (strm->avail_in && gz_comp(state, Z_NO_FLUSH) == -1)
        return -1;

    /* compress len zeros (len guaranteed > 0) */
    first = 1;
    while (len) {
        n = GT_OFF(state->size) || (z_off64_t)state->size > len ?
            (unsigned)len : state->size;
        if (first) {
            memset(state->in, 0, n);
            first = 0;
        }
        strm->avail_in = n;
        strm->next_in = state->in;
        state->pos += n;
        if (gz_comp(state, Z_NO_FLUSH) == -1)
            return -1;
        len -= n;
    }
    return 0;
}

/* -- see zlib.h -- */
int ZEXPORT gzwrite(file, buf, len)
    gzFile file;
    voidpc buf;
    unsigned len;
{
    unsigned put = len;
    unsigned n;
    gz_statep state;
    z_streamp strm;

    /* get internal structure */
    if (file == NULL)
        return 0;
    state = (gz_statep)file;
    strm = &(state->strm);

    /* check that we're writing and that there's no error */
    if (state->mode != GZ_WRITE || state->err != Z_OK)
        return 0;

    /* since an int is returned, make sure len fits in one, otherwise return
       with an error (this avoids the flaw in the interface) */
    if ((int)len < 0) {
        gz_error(state, Z_BUF_ERROR, "requested length does not fit in int");
        return 0;
    }

    /* if len is zero, avoid unnecessary operations */
    if (len == 0)
        return 0;

    /* allocate memory if this is the first time through */
    if (state->size == 0 && gz_init(state) == -1)
        return 0;

    /* check for seek request */
    if (state->seek) {
        state->seek = 0;
        if (gz_zero(state, state->skip) == -1)
            return 0;
    }

    /* for small len, copy to input buffer, otherwise compress directly */
    if (len < state->size) {
        /* copy to input buffer, compress when full */
        do {
            if (strm->avail_in == 0)
                strm->next_in = state->in;
            n = state->size - strm->avail_in;
            if (n > len)
                n = len;
            memcpy(strm->next_in + strm->avail_in, buf, n);
            strm->avail_in += n;
            state->pos += n;
            buf = (char *)buf + n;
            len -= n;
            if (len && gz_comp(state, Z_NO_FLUSH) == -1)
                return 0;
        } while (len);
    }
    else {
        /* consume whatever's left in the input buffer */
        if (strm->avail_in && gz_comp(state, Z_NO_FLUSH) == -1)
            return 0;

        /* directly compress user buffer to file */
        strm->avail_in = len;
        strm->next_in = (voidp)buf;
        state->pos += len;
        if (gz_comp(state, Z_NO_FLUSH) == -1)
            return 0;
    }

    /* input was all buffered or compressed (put will fit in int) */
    return (int)put;
}

/* -- see zlib.h -- */
int ZEXPORT gzputc(file, c)
    gzFile file;
    int c;
{
    unsigned char buf[1];
    gz_statep state;
    z_streamp strm;

    /* get internal structure */
    if (file == NULL)
        return -1;
    state = (gz_statep)file;
    strm = &(state->strm);

    /* check that we're writing and that there's no error */
    if (state->mode != GZ_WRITE || state->err != Z_OK)
        return -1;

    /* check for seek request */
    if (state->seek) {
        state->seek = 0;
        if (gz_zero(state, state->skip) == -1)
            return -1;
    }

    /* try writing to input buffer for speed (state->size == 0 if buffer not
       initialized) */
    if (strm->avail_in < state->size) {
        if (strm->avail_in == 0)
            strm->next_in = state->in;
        strm->next_in[strm->avail_in++] = c;
        state->pos++;
        return c;
    }

    /* no room in buffer or not initialized, use gz_write() */
    buf[0] = c;
    if (gzwrite(file, buf, 1) != 1)
        return -1;
    return c;
}

/* -- see zlib.h -- */
int ZEXPORT gzputs(file, str)
    gzFile file;
    const char *str;
{
    int ret;
    unsigned len;

    /* write string */
    len = (unsigned)strlen(str);
    ret = gzwrite(file, str, len);
    return ret == 0 && len != 0 ? -1 : ret;
}

#ifdef STDC
#include <stdarg.h>

/* -- see zlib.h -- */
int ZEXPORTVA gzprintf (gzFile file, const char *format, ...)
{
    int size, len;
    gz_statep state;
    z_streamp strm;
    va_list va;

    /* get internal structure */
    if (file == NULL)
        return -1;
    state = (gz_statep)file;
    strm = &(state->strm);

    /* check that we're writing and that there's no error */
    if (state->mode != GZ_WRITE || state->err != Z_OK)
        return 0;

    /* make sure we have some buffer space */
    if (state->size == 0 && gz_init(state) == -1)
        return 0;

    /* check for seek request */
    if (state->seek) {
        state->seek = 0;
        if (gz_zero(state, state->skip) == -1)
            return 0;
    }

    /* consume whatever's left in the input buffer */
    if (strm->avail_in && gz_comp(state, Z_NO_FLUSH) == -1)
        return 0;

    /* do the printf() into the input buffer, put length in len */
    size = (int)(state->size);
    state->in[size - 1] = 0;
    va_start(va, format);
#ifdef NO_vsnprintf
#  ifdef HAS_vsprintf_void
    (void)vsprintf(state->in, format, va);
    va_end(va);
    for (len = 0; len < size; len++)
        if (state->in[len] == 0) break;
#  else
    len = vsprintf(state->in, format, va);
    va_end(va);
#  endif
#else
#  ifdef HAS_vsnprintf_void
    (void)vsnprintf(state->in, size, format, va);
    va_end(va);
    len = strlen(state->in);
#  else
    len = vsnprintf((char *)(state->in), size, format, va);
    va_end(va);
#  endif
#endif

    /* check that printf() results fit in buffer */
    if (len <= 0 || len >= (int)size || state->in[size - 1] != 0)
        return 0;

    /* update buffer and position, defer compression until needed */
    strm->avail_in = (unsigned)len;
    strm->next_in = state->in;
    state->pos += len;
    return len;
}

#else /* !STDC */

/* -- see zlib.h -- */
int ZEXPORTVA gzprintf (file, format, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
                       a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
    gzFile file;
    const char *format;
    int a1, a2, a3, a4, a5, a6, a7, a8, a9, a10,
        a11, a12, a13, a14, a15, a16, a17, a18, a19, a20;
{
    int size, len;
    gz_statep state;
    z_streamp strm;

    /* get internal structure */
    if (file == NULL)
        return -1;
    state = (gz_statep)file;
    strm = &(state->strm);

    /* check that we're writing and that there's no error */
    if (state->mode != GZ_WRITE || state->err != Z_OK)
        return 0;

    /* make sure we have some buffer space */
    if (state->size == 0 && gz_init(state) == -1)
        return 0;

    /* check for seek request */
    if (state->seek) {
        state->seek = 0;
        if (gz_zero(state, state->skip) == -1)
            return 0;
    }

    /* consume whatever's left in the input buffer */
    if (strm->avail_in && gz_comp(state, Z_NO_FLUSH) == -1)
        return 0;

    /* do the printf() into the input buffer, put length in len */
    size = (int)(state->size);
    state->in[size - 1] = 0;
#ifdef NO_snprintf
#  ifdef HAS_sprintf_void
    sprintf(state->in, format, a1, a2, a3, a4, a5, a6, a7, a8,
            a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20);
    for (len = 0; len < size; len++)
        if (state->in[len] == 0) break;
#  else
    len = sprintf(state->in, format, a1, a2, a3, a4, a5, a6, a7, a8,
                a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20);
#  endif
#else
#  ifdef HAS_snprintf_void
    snprintf(state->in, size, format, a1, a2, a3, a4, a5, a6, a7, a8,
             a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20);
    len = strlen(state->in);
#  else
    len = snprintf(state->in, size, format, a1, a2, a3, a4, a5, a6, a7, a8,
                 a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20);
#  endif
#endif

    /* check that printf() results fit in buffer */
    if (len <= 0 || len >= (int)size || state->in[size - 1] != 0)
        return 0;

    /* update buffer and position, defer compression until needed */
    strm->avail_in = (unsigned)len;
    strm->next_in = state->in;
    state->pos += len;
    return len;
}

#endif

/* -- see zlib.h -- */
int ZEXPORT gzflush(file, flush)
    gzFile file;
    int flush;
{
    gz_statep state;

    /* get internal structure */
    if (file == NULL)
        return -1;
    state = (gz_statep)file;

    /* check that we're writing and that there's no error */
    if (state->mode != GZ_WRITE || state->err != Z_OK)
        return Z_STREAM_ERROR;

    /* check flush parameter */
    if (flush < 0 || flush > Z_FINISH)
        return Z_STREAM_ERROR;

    /* check for seek request */
    if (state->seek) {
        state->seek = 0;
        if (gz_zero(state, state->skip) == -1)
            return -1;
    }

    /* compress remaining data with requested flush */
    gz_comp(state, flush);
    return state->err;
}

/* -- see zlib.h -- */
int ZEXPORT gzsetparams(file, level, strategy)
    gzFile file;
    int level;
    int strategy;
{
    gz_statep state;
    z_streamp strm;

    /* get internal structure */
    if (file == NULL)
        return Z_STREAM_ERROR;
    state = (gz_statep)file;
    strm = &(state->strm);

    /* check that we're writing and that there's no error */
    if (state->mode != GZ_WRITE || state->err != Z_OK)
        return Z_STREAM_ERROR;

    /* if no change is requested, then do nothing */
    if (level == state->level && strategy == state->strategy)
        return Z_OK;

    /* check for seek request */
    if (state->seek) {
        state->seek = 0;
        if (gz_zero(state, state->skip) == -1)
            return -1;
    }

    /* change compression parameters for subsequent input */
    if (state->size) {
        /* flush previous input with previous parameters before changing */
        if (strm->avail_in && gz_comp(state, Z_PARTIAL_FLUSH) == -1)
            return state->err;
        deflateParams(strm, level, strategy);
    }
    state->level = level;
    state->strategy = strategy;
    return Z_OK;
}

/* -- see zlib.h -- */
int ZEXPORT gzclose_w(file)
    gzFile file;
{
    int ret = 0;
    gz_statep state;

    /* get internal structure */
    if (file == NULL)
        return Z_STREAM_ERROR;
    state = (gz_statep)file;

    /* check that we're writing */
    if (state->mode != GZ_WRITE)
        return Z_STREAM_ERROR;

    /* check for seek request */
    if (state->seek) {
        state->seek = 0;
        ret += gz_zero(state, state->skip);
    }

    /* flush, free memory, and close file */
    ret += gz_comp(state, Z_FINISH);
    (void)deflateEnd(&(state->strm));
    free(state->out);
    free(state->in);
    gz_error(state, Z_OK, NULL);
    free(state->path);
    ret += close(state->fd);
    free(state);
    return ret ? Z_ERRNO : Z_OK;
}
