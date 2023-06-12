# `xdg_directories`

A Dart package for reading XDG directory configuration information on Linux.

## Getting Started

On Linux, `xdg` is a system developed by [freedesktop.org](freedesktop.org), a
project to work on interoperability and shared base technology for free software
desktop environments for Linux.

This Dart package can be used to determine the directory configuration
information defined by `xdg`, such as where the Documents or Desktop directories
are. These are called "user directories" and are defined in configuration file
in the user's home directory.

See [this wiki](https://wiki.archlinux.org/index.php/XDG_Base_Directory) for
more details of the XDG Base Directory implementation.

To use this package, the basic XDG values for the following are available via a Dart API:

 - `dataHome` - The single base directory relative to which user-specific data
   files should be written. (Corresponds to `$XDG_DATA_HOME`).

 - `configHome` - The a single base directory relative to which user-specific
   configuration files should be written. (Corresponds to `$XDG_CONFIG_HOME`).

 - `dataDirs` - The list of preference-ordered base directories relative to
   which data files should be searched. (Corresponds to `$XDG_DATA_DIRS`).

 - `configDirs` - The list of preference-ordered base directories relative to
   which configuration files should be searched. (Corresponds to
   `$XDG_CONFIG_DIRS`).

 - `cacheHome` - The base directory relative to which user-specific
   non-essential (cached) data should be written. (Corresponds to
   `$XDG_CACHE_HOME`).

 - `runtimeDir` - The base directory relative to which user-specific runtime
   files and other file objects should be placed. (Corresponds to
   `$XDG_RUNTIME_DIR`).

 - `getUserDirectoryNames()` - Returns a set of the names of user directories
   defined in the `xdg` configuration files.

 - `getUserDirectory(String dirName)` - Gets the value of the user dir with the
   given name. Requesting a user dir that doesn't exist returns `null`. The
   `dirName` argument is case-insensitive. See [this
   wiki](https://wiki.archlinux.org/index.php/XDG_user_directories) for more
   details and what values of `dirName` might be available.

