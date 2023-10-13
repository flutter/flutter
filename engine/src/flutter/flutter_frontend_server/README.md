# Frontend Server

Frontend server is simple wrapper around Dart Frontend. It is a Dart application
that compiles Dart source into Dart Kernel binary (.dill-file).
Documentation on Dart Kernel (semantic, binary format, etc) can be found here:
https://github.com/dart-lang/sdk/wiki/Kernel-Documentation.

Frontend server runs in two modes:
 - immediate mode, where Dart source file name is provided as command line
 argument;
 - interactive mode, where communication is happening over stdin/stdout.

## Interactive mode instructions

### Compile/Recompile
```
compile <input.dart>
```
 Compiles <input.dart> Dart source file with Dart Frontend. Replies with `result` response.

```
recompile <boundary-key>
<path/to/updated/file1.dart>
<path/to/updated/file2.dart>
...
<boundary-key>
```
 Incrementally recompiles Dart program previously compiled in current session, taking into account
 changes in the listed files. Replies with `result` response.

 Relative paths should be relative to current working directory for the shell that launched
 Frontend Server.

### Accept/Reject
```
accept
```
 Accepts results of incremental compilation, so that on next recompilation request Dart Frontend
 will not include these recompiled files.
```
reject
```
 Rejects results of incremental compilation, so that on next recompilation request Dart Frontend
 will include compilation results from previously rejected recompilation in addition to what it
 will recompile based on newly changed files.
 Small technical detail is that Dart Frontend will not recompile files from previously rejected
 recompilation attempts (unless they were changed since then), it will just include appropriate
 kernel binaries it kept around from those previously rejected compilation requests.

 One use of `accept` and `reject` instructions is in the context of Dart VM hot-reload. Dart VM can
 reject user-provided incremental change to what is currently running. It could happen for variety
 of Dart VM internal reasons. For example, if incremental update changes some `class` to `enum`,
 such update can not be hot-reloaded by VM at this point, will be rejected.

### Quit
```
quit
```
 Stops the server.

## Response from the server

```
result <boundary-key>
<compiler output>
<boundary-key> [<output.dill>]
```
Response from the Dart Frontend compiler is bracketed by `<boundary-key>` tags. If the compiler
was able to produce a Dart Kernel file, the name of this file `<output.dill>` is provided too.
If the compiler encountered unrecoverable errors, there will be no output file name provided.

