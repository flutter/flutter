%define	RELEASE	1
%define rel     %{?CUSTOM_RELEASE} %{!?CUSTOM_RELEASE:%RELEASE}
%define	prefix	/usr

Name: %NAME
Summary: Performance tools for C++
Version: %VERSION
Release: %rel
Group: Development/Libraries
URL: http://code.google.com/p/gperftools/
License: BSD
Vendor: Google Inc. and others
Packager: Google Inc. and others <google-perftools@googlegroups.com>
Source: http://%{NAME}.googlecode.com/files/%{NAME}-%{VERSION}.tar.gz
Distribution: Redhat 7 and above.
Buildroot: %{_tmppath}/%{name}-root
Prefix: %prefix

%description
The %name packages contains some utilities to improve and analyze the
performance of C++ programs.  This includes an optimized thread-caching
malloc() and cpu and heap profiling utilities.

%package devel
Summary: Performance tools for C++
Group: Development/Libraries
Requires: %{NAME} = %{VERSION}

%description devel
The %name-devel package contains static and debug libraries and header
files for developing applications that use the %name package.

%changelog
	* Mon Apr 20 2009  <opensource@google.com>
	- Change build rule to use a configure line more like '%configure'
	- Change install to use DESTDIR instead of prefix for configure
	- Use wildcards for doc/ and lib/ directories

	* Fri Mar 11 2005  <opensource@google.com>
	- First draft

%prep
%setup

%build
# I can't use '% configure', because it defines -m32 which breaks some
# of the low-level atomicops files in this package.  But I do take
# as much from % configure (in /usr/lib/rpm/macros) as I can.
./configure --prefix=%{_prefix} --exec-prefix=%{_exec_prefix} --bindir=%{_bindir} --sbindir=%{_sbindir} --sysconfdir=%{_sysconfdir} --datadir=%{_datadir} --includedir=%{_includedir} --libdir=%{_libdir} --libexecdir=%{_libexecdir} --localstatedir=%{_localstatedir} --sharedstatedir=%{_sharedstatedir} --mandir=%{_mandir} --infodir=%{_infodir}
make

%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)

%docdir %{prefix}/share/doc/%{NAME}-%{VERSION}
%{prefix}/share/doc/%{NAME}-%{VERSION}/*

%{_libdir}/*.so.*
%{_bindir}/pprof
%{_mandir}/man1/pprof.1*

%files devel
%defattr(-,root,root)

%{_includedir}/google
%{_includedir}/gperftools
%{_libdir}/*.a
%{_libdir}/*.la
%{_libdir}/*.so
%{_libdir}/pkgconfig/*.pc
