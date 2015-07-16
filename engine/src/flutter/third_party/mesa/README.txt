Compilation has a few phases:

1. Generate the header and dispatch source files that have to match the GL api.
   These read in a description of the GL api in the form of XML files. In
   addition, generate the GLSL parser and lexer using flex and bison. These
   sources are needed for step 2
2. Compile everything in src/glsl into a library. This step uses the parser and
   lexer output.
3. Compile the compiler (executable) that can create the builtin functions'
   source file.  Note that this step uses builtin_stubs.cpp because we haven't
   generated the actual builtin functions' source file yet.
4. Invoke the compiler that we just built to create
   gen/mesa/builtin_function.cpp
5. Compile the rest of mesa, using the builtins that we created in step 4. In
   addition, link in all the files that we've previously compiled in step 2.
