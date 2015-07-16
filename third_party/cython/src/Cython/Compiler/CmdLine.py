#
#   Cython - Command Line Parsing
#

import os
import sys
import Options

usage = """\
Cython (http://cython.org) is a compiler for code written in the
Cython language.  Cython is based on Pyrex by Greg Ewing.

Usage: cython [options] sourcefile.{pyx,py} ...

Options:
  -V, --version                  Display version number of cython compiler
  -l, --create-listing           Write error messages to a listing file
  -I, --include-dir <directory>  Search for include files in named directory
                                 (multiple include directories are allowed).
  -o, --output-file <filename>   Specify name of generated C file
  -t, --timestamps               Only compile newer source files
  -f, --force                    Compile all source files (overrides implied -t)
  -v, --verbose                  Be verbose, print file names on multiple compilation
  -p, --embed-positions          If specified, the positions in Cython files of each
                                 function definition is embedded in its docstring.
  --cleanup <level>              Release interned objects on python exit, for memory debugging.
                                 Level indicates aggressiveness, default 0 releases nothing.
  -w, --working <directory>      Sets the working directory for Cython (the directory modules
                                 are searched from)
  --gdb                          Output debug information for cygdb
  --gdb-outdir <directory>       Specify gdb debug information output directory. Implies --gdb.

  -D, --no-docstrings            Strip docstrings from the compiled module.
  -a, --annotate                 Produce a colorized HTML version of the source.
  --line-directives              Produce #line directives pointing to the .pyx source
  --cplus                        Output a C++ rather than C file.
  --embed[=<method_name>]        Generate a main() function that embeds the Python interpreter.
  -2                             Compile based on Python-2 syntax and code semantics.
  -3                             Compile based on Python-3 syntax and code semantics.
  --lenient                      Change some compile time errors to runtime errors to
                                 improve Python compatibility
  --capi-reexport-cincludes      Add cincluded headers to any auto-generated header files.
  --fast-fail                    Abort the compilation on the first error
  --warning-errors, -Werror      Make all warnings into errors
  --warning-extra, -Wextra       Enable extra warnings
  -X, --directive <name>=<value>[,<name=value,...] Overrides a compiler directive
"""

#The following experimental options are supported only on MacOSX:
#  -C, --compile    Compile generated .c file to .o file
#  --link           Link .o file to produce extension module (implies -C)
#  -+, --cplus      Use C++ compiler for compiling and linking
#  Additional .o files to link may be supplied when using -X."""

def bad_usage():
    sys.stderr.write(usage)
    sys.exit(1)

def parse_command_line(args):

    from Cython.Compiler.Main import \
        CompilationOptions, default_options

    def pop_arg():
        if args:
            return args.pop(0)
        else:
            bad_usage()

    def get_param(option):
        tail = option[2:]
        if tail:
            return tail
        else:
            return pop_arg()

    options = CompilationOptions(default_options)
    sources = []
    while args:
        if args[0].startswith("-"):
            option = pop_arg()
            if option in ("-V", "--version"):
                options.show_version = 1
            elif option in ("-l", "--create-listing"):
                options.use_listing_file = 1
            elif option in ("-+", "--cplus"):
                options.cplus = 1
            elif option == "--embed":
                Options.embed = "main"
            elif option.startswith("--embed="):
                Options.embed = option[8:]
            elif option.startswith("-I"):
                options.include_path.append(get_param(option))
            elif option == "--include-dir":
                options.include_path.append(pop_arg())
            elif option in ("-w", "--working"):
                options.working_path = pop_arg()
            elif option in ("-o", "--output-file"):
                options.output_file = pop_arg()
            elif option in ("-t", "--timestamps"):
                options.timestamps = 1
            elif option in ("-f", "--force"):
                options.timestamps = 0
            elif option in ("-v", "--verbose"):
                options.verbose += 1
            elif option in ("-p", "--embed-positions"):
                Options.embed_pos_in_docstring = 1
            elif option in ("-z", "--pre-import"):
                Options.pre_import = pop_arg()
            elif option == "--cleanup":
                Options.generate_cleanup_code = int(pop_arg())
            elif option in ("-D", "--no-docstrings"):
                Options.docstrings = False
            elif option in ("-a", "--annotate"):
                Options.annotate = True
            elif option == "--convert-range":
                Options.convert_range = True
            elif option == "--line-directives":
                options.emit_linenums = True
            elif option == "--no-c-in-traceback":
                options.c_line_in_traceback = False
            elif option == "--gdb":
                options.gdb_debug = True
                options.output_dir = os.curdir
            elif option == "--gdb-outdir":
                options.gdb_debug = True
                options.output_dir = pop_arg()
            elif option == "--lenient":
                Options.error_on_unknown_names = False
                Options.error_on_uninitialized = False
            elif option == '-2':
                options.language_level = 2
            elif option == '-3':
                options.language_level = 3
            elif option == "--capi-reexport-cincludes":
                options.capi_reexport_cincludes = True
            elif option == "--fast-fail":
                Options.fast_fail = True
            elif option in ('-Werror', '--warning-errors'):
                Options.warning_errors = True
            elif option in ('-Wextra', '--warning-extra'):
                options.compiler_directives.update(Options.extra_warnings)
            elif option == "--old-style-globals":
                Options.old_style_globals = True
            elif option == "--directive" or option.startswith('-X'):
                if option.startswith('-X') and option[2:].strip():
                    x_args = option[2:]
                else:
                    x_args = pop_arg()
                try:
                    options.compiler_directives = Options.parse_directive_list(
                        x_args, relaxed_bool=True,
                        current_settings=options.compiler_directives)
                except ValueError, e:
                    sys.stderr.write("Error in compiler directive: %s\n" % e.args[0])
                    sys.exit(1)
            elif option.startswith('--debug'):
                option = option[2:].replace('-', '_')
                import DebugFlags
                if option in dir(DebugFlags):
                    setattr(DebugFlags, option, True)
                else:
                    sys.stderr.write("Unknown debug flag: %s\n" % option)
                    bad_usage()
            elif option in ('-h', '--help'):
                sys.stdout.write(usage)
                sys.exit(0)
            else:
                sys.stderr.write("Unknown compiler flag: %s\n" % option)
                sys.exit(1)
        else:
            sources.append(pop_arg())
    if options.use_listing_file and len(sources) > 1:
        sys.stderr.write(
            "cython: Only one source file allowed when using -o\n")
        sys.exit(1)
    if len(sources) == 0 and not options.show_version:
        bad_usage()
    if Options.embed and len(sources) > 1:
        sys.stderr.write(
            "cython: Only one source file allowed when using -embed\n")
        sys.exit(1)
    return options, sources

