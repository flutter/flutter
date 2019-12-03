cmake_minimum_required(VERSION 3.4.1)  # for example

add_library( ffi_tests

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             ../../ios/Classes/ffi_test_dynamic_library.cpp
             ../../ios/Classes/ffi_test_functions.cpp )
