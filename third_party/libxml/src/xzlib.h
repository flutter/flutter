/**
 * xzlib.h: header for the front end for the transparent suport of lzma
 *          compression at the I/O layer
 *
 * See Copyright for the status of this software.
 *
 * Anders F Bjorklund <afb@users.sourceforge.net>
 */

#ifndef LIBXML2_XZLIB_H
#define LIBXML2_XZLIB_H
typedef void *xzFile;           /* opaque lzma file descriptor */

xzFile __libxml2_xzopen(const char *path, const char *mode);
xzFile __libxml2_xzdopen(int fd, const char *mode);
int __libxml2_xzread(xzFile file, void *buf, unsigned len);
int __libxml2_xzclose(xzFile file);
int __libxml2_xzcompressed(xzFile f);
#endif /* LIBXML2_XZLIB_H */
