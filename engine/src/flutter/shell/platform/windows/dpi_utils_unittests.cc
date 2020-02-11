#include <windows.h>

#include "flutter/shell/platform/windows/dpi_utils.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(DpiUtilsTest, NonZero) {
  ASSERT_GT(GetDpiForHWND(nullptr), 0);
  ASSERT_GT(GetDpiForMonitor(nullptr), 0);
};

TEST(DpiUtilsTest, NullHwndUsesPrimaryMonitor) {
  const POINT target_point = {0, 0};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTOPRIMARY);
  ASSERT_EQ(GetDpiForHWND(nullptr), GetDpiForMonitor(monitor));
};

}  // namespace testing
}  // namespace flutter
