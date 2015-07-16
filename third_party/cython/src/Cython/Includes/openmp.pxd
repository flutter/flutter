cdef extern from "omp.h":
    ctypedef struct omp_lock_t:
        pass
    ctypedef struct omp_nest_lock_t:
        pass

    ctypedef enum omp_sched_t:
        omp_sched_static = 1,
        omp_sched_dynamic = 2,
        omp_sched_guided = 3,
        omp_sched_auto = 4

    extern void omp_set_num_threads(int) nogil
    extern int omp_get_num_threads() nogil
    extern int omp_get_max_threads() nogil
    extern int omp_get_thread_num() nogil
    extern int omp_get_num_procs() nogil

    extern int omp_in_parallel() nogil

    extern void omp_set_dynamic(int) nogil
    extern int omp_get_dynamic() nogil

    extern void omp_set_nested(int) nogil
    extern int omp_get_nested() nogil

    extern void omp_init_lock(omp_lock_t *) nogil
    extern void omp_destroy_lock(omp_lock_t *) nogil
    extern void omp_set_lock(omp_lock_t *) nogil
    extern void omp_unset_lock(omp_lock_t *) nogil
    extern int omp_test_lock(omp_lock_t *) nogil

    extern void omp_init_nest_lock(omp_nest_lock_t *) nogil
    extern void omp_destroy_nest_lock(omp_nest_lock_t *) nogil
    extern void omp_set_nest_lock(omp_nest_lock_t *) nogil
    extern void omp_unset_nest_lock(omp_nest_lock_t *) nogil
    extern int omp_test_nest_lock(omp_nest_lock_t *) nogil

    extern double omp_get_wtime() nogil
    extern double omp_get_wtick() nogil

    void omp_set_schedule(omp_sched_t, int) nogil
    void omp_get_schedule(omp_sched_t *, int *) nogil
    int omp_get_thread_limit() nogil
    void omp_set_max_active_levels(int) nogil
    int omp_get_max_active_levels() nogil
    int omp_get_level() nogil
    int omp_get_ancestor_thread_num(int) nogil
    int omp_get_team_size(int) nogil
    int omp_get_active_level() nogil

