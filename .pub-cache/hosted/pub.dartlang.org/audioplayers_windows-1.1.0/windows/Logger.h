#include <string>

#include <iostream>

enum class LogLevel
{
    None,
    Error,
    Info
};

class Logger {
private:
    static void Log(LogLevel level, std::string message);
public:
    static inline LogLevel logLevel = LogLevel::Error;

    static void Info(std::string message);

    static void Error(std::string message);
};