@REM Start cython from windows commandline as "cython", not "cython.py".
@REM This is especially useful for windows power shell, as no extra window
@REM is used.

@echo OFF
python -c "from Cython.Compiler.Main import main; main(command_line = 1)" %*
