set(LLVM_LINK_COMPONENTS
  BitReader
  MCParser
  Option
  X86AsmParser
  )

add_llvm_executable(rewrite_scoped_refptr
  RewriteScopedRefptr.cpp
  )

target_link_libraries(rewrite_scoped_refptr
  clangAST
  clangASTMatchers
  clangAnalysis
  clangBasic
  clangDriver
  clangEdit
  clangFrontend
  clangLex
  clangParse
  clangSema
  clangSerialization
  clangTooling
  )

cr_install(TARGETS rewrite_scoped_refptr RUNTIME DESTINATION bin)
