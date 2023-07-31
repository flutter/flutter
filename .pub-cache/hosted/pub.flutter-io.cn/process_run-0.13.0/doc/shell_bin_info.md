# Manipulate environment

Binary utility that allow changing from the command line the environment (var, path, alias) used in Shell.

### Setup

```shell
# Add ds utility
pub global activate process_run
```
### Example

```
# Version
ds --version

# Run using the shell environment (alias, path and var=
ds run echo Hello World

# Set a var
ds env var set MY_VAR my_value

# Set an alias
ds env alias set ll ls -l

# Add a path (prepend only)
ds env path prepend dummy/relative/folder

# Windows example to add flutter bin in the path
# The following command will work even if flutter is not globally in your PATH
# env variable (from your IDE for example)
# await run('flutter --version');
ds env path prepend -u C:\app\flutter\stable\flutter\bin
```
