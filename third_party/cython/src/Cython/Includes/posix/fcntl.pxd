# http://www.opengroup.org/onlinepubs/009695399/basedefs/fcntl.h.html

cdef extern from "fcntl.h" nogil:

    enum: F_DUPFD
    enum: F_GETFD
    enum: F_SETFD
    enum: F_GETFL
    enum: F_SETFL
    enum: F_GETLK
    enum: F_SETLK
    enum: F_SETLKW
    enum: F_GETOWN
    enum: F_SETOWN

    enum: FD_CLOEXEC

    enum: F_RDLCK
    enum: F_UNLCK
    enum: F_WRLCK

    enum: SEEK_SET
    enum: SEEK_CUR
    enum: SEEK_END

    enum: O_CREAT
    enum: O_EXCL
    enum: O_NOCTTY
    enum: O_TRUNC

    enum: O_APPEND
    enum: O_DSYNC
    enum: O_NONBLOCK
    enum: O_RSYNC
    enum: O_SYNC

    enum: O_ACCMODE # O_RDONLY|O_WRONLY|O_RDWR

    enum: O_RDONLY
    enum: O_WRONLY
    enum: O_RDWR

    enum: S_IFMT
    enum: S_IFBLK
    enum: S_IFCHR
    enum: S_IFIFO
    enum: S_IFREG
    enum: S_IFDIR
    enum: S_IFLNK
    enum: S_IFSOCK

    ctypedef int    mode_t
    ctypedef signed pid_t
    ctypedef signed off_t

    struct flock:
        short l_type
        short l_whence
        off_t l_start
        off_t l_len
        pid_t l_pid

    int creat(char *, mode_t)
    int fcntl(int, int, ...)
    int open(char *, int, ...)
    #int open (char *, int, mode_t)

