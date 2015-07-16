Mojo Public API
===============

The Mojo Public API is a binary stable API to the Mojo system.

It consists of support for a number of programming languages (with a directory
for each support language), some "build" tools and build-time requirements, and
interface definitions for Mojo services (specified using an IDL).

Note that there are various subdirectories named tests/. These contain tests of
the code in the enclosing directory, and are not meant for use by Mojo
applications.

C/CPP/JS
--------

The c/, cpp/, js/ subdirectories define the API for C, C++, and JavaScript,
respectively.

The basic principle for these directories is that they consist of the source
files that one needs at build/deployment/run time (as appropriate for the
language), organized in a natural way for the particular language.

Interfaces
----------

The interfaces/ subdirectory contains Mojo IDL (a.k.a. .mojom) descriptions of
standard Mojo services.

Platform
--------

The platform/ subdirectory contains any build-time requirements (e.g., static
libraries) that may be needed to produce a Mojo application for certain
platforms, such as a native shared library or as a NaCl binary.

Tools
-----

The tools/ subdirectory contains tools that are useful/necessary at
build/deployment time. These tools may be needed (as a practical necessity) to
use the API in any given language, e.g., to generate bindings from Mojo IDL
files.
