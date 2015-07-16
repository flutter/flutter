# 7.19 Input/output <stdio.h>


# deprecated cimports for backwards compatibility:
from libc.string cimport const_char, const_void


cdef extern from "stdio.h" nogil:

    ctypedef struct FILE
    cdef FILE *stdin
    cdef FILE *stdout
    cdef FILE *stderr

    enum: FOPEN_MAX
    enum: FILENAME_MAX
    FILE *fopen   (const char *filename, const char  *opentype)
    FILE *freopen (const char *filename, const char *opentype, FILE *stream)
    FILE *fdopen  (int fdescriptor, const char *opentype)
    int  fclose   (FILE *stream)
    int  remove   (const char *filename)
    int  rename   (const char *oldname, const char *newname)
    FILE *tmpfile ()

    int remove (const char *pathname)
    int rename (const char *oldpath, const char *newpath)

    enum: _IOFBF
    enum: _IOLBF
    enum: _IONBF
    int setvbuf (FILE *stream, char *buf, int mode, size_t size)
    enum: BUFSIZ
    void setbuf (FILE *stream, char *buf)

    size_t fread  (void *data, size_t size, size_t count, FILE *stream)
    size_t fwrite (const void *data, size_t size, size_t count, FILE *stream)
    int    fflush (FILE *stream)

    enum: EOF
    void clearerr (FILE *stream)
    int feof      (FILE *stream)
    int ferror    (FILE *stream)

    enum: SEEK_SET
    enum: SEEK_CUR
    enum: SEEK_END
    int      fseek  (FILE *stream, long int offset, int whence)
    void     rewind (FILE *stream)
    long int ftell  (FILE *stream)

    ctypedef struct fpos_t
    ctypedef const fpos_t const_fpos_t "const fpos_t"
    int fgetpos (FILE *stream, fpos_t *position)
    int fsetpos (FILE *stream, const fpos_t *position)

    int scanf    (const char *template, ...)
    int sscanf   (const char *s, const char *template, ...)
    int fscanf   (FILE *stream, const char *template, ...)

    int printf   (const char *template, ...)
    int sprintf  (char *s, const char *template, ...)
    int snprintf (char *s, size_t size, const char *template, ...)
    int fprintf  (FILE *stream, const char *template, ...)

    void perror  (const char *message)

    char *gets  (char *s)
    char *fgets (char *s, int count, FILE *stream)
    int getchar ()
    int fgetc   (FILE *stream)
    int getc    (FILE *stream)
    int ungetc  (int c, FILE *stream)

    int puts    (const char *s)
    int fputs   (const char *s, FILE *stream)
    int putchar (int c)
    int fputc   (int c, FILE *stream)
    int putc    (int c, FILE *stream)

    size_t getline(char **lineptr, size_t *n, FILE *stream)
