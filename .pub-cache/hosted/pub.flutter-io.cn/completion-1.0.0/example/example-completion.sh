#
# Installation:
#
# Via shell config file  ~/.bashrc  (or ~/.zshrc)
#
#   Append the contents to config file
#   'source' the file in the config file
#
# You may also have a directory on your system that is configured
#    for completion files, such as:
#
#    /usr/local/etc/bash_completion.d/

###-begin-example.dart-completion-###

if type complete &>/dev/null; then
  __example_dart_completion() {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           example.dart completion -- "${COMP_WORDS[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -F __example_dart_completion example.dart
elif type compdef &>/dev/null; then
  __example_dart_completion() {
    si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 example.dart completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef __example_dart_completion example.dart
elif type compctl &>/dev/null; then
  __example_dart_completion() {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       example.dart completion -- "${words[@]}" \
                       2>/dev/null)) || return $?
    IFS="$si"
  }
  compctl -K __example_dart_completion example.dart
fi

###-end-example.dart-completion-###

## Generated 2018-12-06 13:41:53.261614Z
## By /Users/kevmoo/source/github/completion.dart/bin/shell_completion_generator.dart
