eval "$(echo "static const int Moo = 88;" | xcrun clang -x c \
    -arch x86_64 \
    -dynamiclib \
    -Xlinker -rpath -Xlinker '@executable_path/Frameworks' \
    -Xlinker -rpath -Xlinker '@loader_path/Frameworks' \
    -install_name '@rpath/App.framework/App' \
    -o "macos/Flutter/ephemeral/App.framework/App" -)"