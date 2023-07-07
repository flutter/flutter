#!/bin/sh
#
# Show how these examples are different.

echo "----------------------------------------------------------------"
echo "===== DIFFERENCE BETWEEN import-demo-1 AND import-demo-2 ====="
diff import-demo-1.dart import-demo-2.dart

echo
echo "----------------------------------------------------------------"
echo "===== DIFFERENCE BETWEEN import-demo-2 AND import-demo-3 ====="
diff import-demo-2.dart import-demo-3.dart

echo
echo "----------------------------------------------------------------"
echo "===== DIFFERENCE BETWEEN import-demo-3 AND import-demo-4 ====="
diff import-demo-3.dart import-demo-4.dart
