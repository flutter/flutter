# Performing Analysis

This document explains how to use the analyzer package to analyze Dart code.

## Conceptual Model

The analysis of Dart code depends on a set of metadata (data outside the code
being analyzed). An _analysis context_ is a representation of a set of code that
should be analyzed using the same sources of metadata (same package_spec.json
file, same analysis options file, etc.). That set of code typically corresponds
to a package.

Despite the fact that the analyzer APIs do not support its use in an incremental
system, it is used that way by the analysis server, and that fact has influenced
the design of those APIs.

Specifically, in an incremental system the metadata can change over time.
Analysis results obtained with one state of the metadata won't necessarily be
consistent with results obtained with a different state of the metadata. Clients
that need to work in an incremental environment need to know whether the results
are consistent. (Clients that aren't running in an incremental environment can
typically ignore this complication.)

An _analysis session_ provides a way for clients to know when newly requested
results would be inconsistent with previously requested results. Each analysis
session is associated with a single analysis context and represents a specific
state of the metadata for that context. An instance of
`InconsistentAnalysisException` is thrown by a session if the state of the
metadata has changed since the session was created. This prevents clients from
getting results that would be inconsistent.

## Configuring the Contexts

If you want to use the analyzer package to analyze one or more files, then you
need to start by configuring the analysis context(s) in which analysis is to be
performed. An analysis context tells the analyzer how to perform analysis, and
includes such information as

- how to resolve `package:` URIs,

- which defined variables are defined, if any, and what their value is, and

- any configuration information included in an analysis options file.

Fortunately, the analyzer package can do most of the work for you. All you need
to do is create an instance of `AnalysisContextCollection`, giving it the paths
to all of the files, or directories containing files, that you want to be able
to analyze.

```dart
void main() {
  List<String> includedPaths = <String>[/* ... */];
  AnalysisContextCollection collection =
      new AnalysisContextCollection(includedPaths: includedPaths);
  analyzeSomeFiles(collection, includedPaths);
}

void analyzeSomeFiles(
    AnalysisContextCollection collection, List<String> includedPaths) {
  // See below.
}
```

The collection will create one or more analysis contexts that can be used to
correctly analyze all of the files and directories that were specified.

## Analyzing Individual Files

You might already know the paths to the files that you want to analyze. This
would be the case, for example, if you're analyzing a single file (and hence
created a list of length 1 when you created the collection). If that's the case,
then you can ask the collection for the context associated with each of those
files. If you have more than one file to analyze, don't assume that all of the
files will be analyzed by the same context.

For example, if you have defined the collection as above, you could perform
analysis with the following:

```dart
void analyzeSomeFiles(
    AnalysisContextCollection collection, List<String> includedPaths) {
  for (String path in includedPaths) {
    AnalysisContext context = collection.contextFor(path);
    analyzeSingleFile(context, path);
  }
}

void analyzeSingleFile(AnalysisContext context, String path) {
  // See below.
}
```

## Analyzing Multiple Files

If you don't know all of the files that need to be analyzed, you can analyze
all of the files in the included files and directories by using a slightly
different API:

```dart
void analyzeAllFiles(AnalysisContextCollection collection) {
  for (AnalysisContext context in collection.contexts) {
    for (String path in context.contextRoot.analyzedFiles()) {
      analyzeSingleFile(context, path);
    }
  }
}

void analyzeSingleFile(AnalysisContext context, String path) {
  // See below.
}
```

The files returned this way will include _all_ of the files in all of the
directories, including those that are not '.dart' files, except for those files
that have explicitly been excluded or that are in directories that have been
explicitly excluded. If you're only interested in analyzing `.dart` files, then
you would need to manually filter out other files.

## Accessing Analysis Results

Analysis contexts do not provide direct access to analysis results. Instead, you
need to ask the context for an analysis session and then ask the session to
perform the analysis.

```dart
void analyzeSingleFile(AnalysisContext context, String path) {
  AnalysisSession session = context.currentSession;
  // ...
}
```

The session either provides the requested results or throws an exception if the
results that would have been returned would have been inconsistent with other
results returned by the same session.

While this might seem odd, the API was designed this way to provide safety when
performing analysis in an environment in which the state of the files being
analyzed can change over time.

If you are analyzing multiple files and no exception is thrown, then you know
that the results are all consistent with each other. If an exception is thrown,
and consistency is important, then you can request the new current session from
the context and re-request all of the needed analyses.

Several of the methods on `AnalysisSession` are discussed in the sections that
describe the results that those methods are used to access, including the
tutorials on [ASTs][ast] and [elements][element].

[ast]: ast.md
[element]: element.md
