Terminal
========

This is a prototype "terminal" application that can connect to any Mojo
application (providing the |terminal.TerminalClient| interface) and provide
interactive terminal facilities via an implementation of |mojo.files.File|.
I.e., once connected, the application can write to/read from the terminal by
performing the corresponding operations on a "file" (thus replicating
decades-old technology, poorly).
