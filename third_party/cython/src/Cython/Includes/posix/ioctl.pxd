cdef extern from "sys/ioctl.h" nogil:
    enum: FIONBIO

    int ioctl(int fd, int request, ...)
