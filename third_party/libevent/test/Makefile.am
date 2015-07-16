AUTOMAKE_OPTIONS = foreign no-dependencies

AM_CFLAGS = -I$(top_srcdir) -I$(top_srcdir)/compat

EXTRA_DIST = regress.rpc regress.gen.h regress.gen.c

noinst_PROGRAMS = test-init test-eof test-weof test-time regress bench

BUILT_SOURCES = regress.gen.c regress.gen.h
test_init_SOURCES = test-init.c
test_init_LDADD = ../libevent_core.la
test_eof_SOURCES = test-eof.c
test_eof_LDADD = ../libevent_core.la
test_weof_SOURCES = test-weof.c
test_weof_LDADD = ../libevent_core.la
test_time_SOURCES = test-time.c
test_time_LDADD = ../libevent_core.la
regress_SOURCES = regress.c regress.h regress_http.c regress_dns.c \
	regress_rpc.c \
	regress.gen.c regress.gen.h
regress_LDADD = ../libevent.la
bench_SOURCES = bench.c
bench_LDADD = ../libevent.la

regress.gen.c regress.gen.h: regress.rpc $(top_srcdir)/event_rpcgen.py
	$(top_srcdir)/event_rpcgen.py $(srcdir)/regress.rpc || echo "No Python installed"

DISTCLEANFILES = *~

test: test-init test-eof test-weof test-time regress

verify: test
	@$(srcdir)/test.sh

bench test-init test-eof test-weof test-time: ../libevent.la
