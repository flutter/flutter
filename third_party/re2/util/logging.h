// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Simplified version of Google's logging.

#ifndef RE2_UTIL_LOGGING_H__
#define RE2_UTIL_LOGGING_H__

#ifndef WIN32
#include <unistd.h>  /* for write */
#endif
#include <sstream>
#ifdef WIN32
#include <io.h>
#endif

// Debug-only checking.
#define DCHECK(condition) assert(condition)
#define DCHECK_EQ(val1, val2) assert((val1) == (val2))
#define DCHECK_NE(val1, val2) assert((val1) != (val2))
#define DCHECK_LE(val1, val2) assert((val1) <= (val2))
#define DCHECK_LT(val1, val2) assert((val1) < (val2))
#define DCHECK_GE(val1, val2) assert((val1) >= (val2))
#define DCHECK_GT(val1, val2) assert((val1) > (val2))

// Always-on checking
#define CHECK(x)	if(x){}else LogMessageFatal(__FILE__, __LINE__).stream() << "Check failed: " #x
#define CHECK_LT(x, y)	CHECK((x) < (y))
#define CHECK_GT(x, y)	CHECK((x) > (y))
#define CHECK_LE(x, y)	CHECK((x) <= (y))
#define CHECK_GE(x, y)	CHECK((x) >= (y))
#define CHECK_EQ(x, y)	CHECK((x) == (y))
#define CHECK_NE(x, y)	CHECK((x) != (y))

#define LOG_INFO LogMessage(__FILE__, __LINE__)
#define LOG_ERROR LOG_INFO
#define LOG_WARNING LOG_INFO
#define LOG_FATAL LogMessageFatal(__FILE__, __LINE__)
#define LOG_QFATAL LOG_FATAL

#define VLOG(x) if((x)>0){}else LOG_INFO.stream()

#ifdef NDEBUG
#define DEBUG_MODE 0
#define LOG_DFATAL LOG_ERROR
#else
#define DEBUG_MODE 1
#define LOG_DFATAL LOG_FATAL
#endif

#define LOG(severity) LOG_ ## severity.stream()

class LogMessage {
 public:
  LogMessage(const char* file, int line) : flushed_(false) {
    stream() << file << ":" << line << ": ";
  }
  void Flush() {
    stream() << "\n";
    string s = str_.str();
    int n = (int)s.size(); // shut up msvc
    if(write(2, s.data(), n) < 0) {}  // shut up gcc
    flushed_ = true;
  }
  ~LogMessage() {
    if (!flushed_) {
      Flush();
    }
  }
  ostream& stream() { return str_; }
 
 private:
  bool flushed_;
  std::ostringstream str_;
  DISALLOW_EVIL_CONSTRUCTORS(LogMessage);
};

class LogMessageFatal : public LogMessage {
 public:
  LogMessageFatal(const char* file, int line)
    : LogMessage(file, line) { }
  ~LogMessageFatal() {
    Flush();
    abort();
  }
 private:
  DISALLOW_EVIL_CONSTRUCTORS(LogMessageFatal);
};

#endif  // RE2_UTIL_LOGGING_H__
