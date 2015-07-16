AUTOMAKE_OPTIONS = foreign no-dependencies

LDADD = ../libevent.la
AM_CFLAGS = -I$(top_srcdir) -I$(top_srcdir)/compat

noinst_PROGRAMS = event-test time-test signal-test

event_test_sources = event-test.c
time_test_sources = time-test.c
signal_test_sources = signal-test.c

verify:

DISTCLEANFILES = *~
