#include "Logger.h"

using namespace std;

LogLevel Logger::logLevel = LogLevel::Error;

void Logger::Info(std::string message) {
    Log(LogLevel::Info, message);
}

void Logger::Error(std::string message) {
    Log(LogLevel::Error, message);
}

void Logger::Log(LogLevel level, std::string message) {
    if (level <= logLevel) {
        cout << "AudioPlayers: " << message << endl;
    }
}