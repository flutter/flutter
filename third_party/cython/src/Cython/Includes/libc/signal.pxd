# 7.14 Signal handling <signal.h>

ctypedef void (*sighandler_t)(int SIGNUM) nogil

cdef extern from "signal.h" nogil:

    ctypedef int sig_atomic_t

    enum: SIGABRT
    enum: SIGFPE
    enum: SIGILL
    enum: SIGINT
    enum: SIGSEGV
    enum: SIGTERM

    sighandler_t SIG_DFL
    sighandler_t SIG_IGN
    sighandler_t SIG_ERR

    sighandler_t signal        (int signum, sighandler_t action)
    int          raise_"raise" (int signum)


cdef extern from "signal.h" nogil:

    # Program Error
    enum: SIGFPE
    enum: SIGILL
    enum: SIGSEGV
    enum: SIGBUS
    enum: SIGABRT
    enum: SIGIOT
    enum: SIGTRAP
    enum: SIGEMT
    enum: SIGSYS
    # Termination
    enum: SIGTERM
    enum: SIGINT
    enum: SIGQUIT
    enum: SIGKILL
    enum: SIGHUP
    # Alarm
    enum: SIGALRM
    enum: SIGVTALRM
    enum: SIGPROF
    # Asynchronous I/O
    enum: SIGIO
    enum: SIGURG
    enum: SIGPOLL
    # Job Control
    enum: SIGCHLD
    enum: SIGCLD
    enum: SIGCONT
    enum: SIGSTOP
    enum: SIGTSTP
    enum: SIGTTIN
    enum: SIGTTOU
    # Operation Error
    enum: SIGPIPE
    enum: SIGLOST
    enum: SIGXCPU
    enum: SIGXFSZ
    # Miscellaneous
    enum: SIGUSR1
    enum: SIGUSR2
    enum: SIGWINCH
    enum: SIGINFO

