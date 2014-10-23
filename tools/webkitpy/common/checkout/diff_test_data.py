# Copyright (C) 2011 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#  FIXME: Store this as a .patch file in some new fixtures directory or similar.
DIFF_TEST_DATA = '''diff --git a/WebCore/rendering/style/StyleFlexibleBoxData.h b/WebCore/rendering/style/StyleFlexibleBoxData.h
index f5d5e74..3b6aa92 100644
--- a/WebCore/rendering/style/StyleFlexibleBoxData.h
+++ b/WebCore/rendering/style/StyleFlexibleBoxData.h
@@ -47,7 +47,6 @@ public:
 
     unsigned align : 3; // EBoxAlignment
     unsigned pack: 3; // EBoxAlignment
-    unsigned orient: 1; // EBoxOrient
     unsigned lines : 1; // EBoxLines
 
 private:
diff --git a/WebCore/rendering/style/StyleRareInheritedData.cpp b/WebCore/rendering/style/StyleRareInheritedData.cpp
index ce21720..324929e 100644
--- a/WebCore/rendering/style/StyleRareInheritedData.cpp
+++ b/WebCore/rendering/style/StyleRareInheritedData.cpp
@@ -39,6 +39,7 @@ StyleRareInheritedData::StyleRareInheritedData()
     , textSizeAdjust(RenderStyle::initialTextSizeAdjust())
     , resize(RenderStyle::initialResize())
     , userSelect(RenderStyle::initialUserSelect())
+    , boxOrient(RenderStyle::initialBoxOrient())
 {
 }
 
@@ -58,6 +59,7 @@ StyleRareInheritedData::StyleRareInheritedData(const StyleRareInheritedData& o)
     , textSizeAdjust(o.textSizeAdjust)
     , resize(o.resize)
     , userSelect(o.userSelect)
+    , boxOrient(o.boxOrient)
 {
 }
 
@@ -81,7 +83,8 @@ bool StyleRareInheritedData::operator==(const StyleRareInheritedData& o) const
         && khtmlLineBreak == o.khtmlLineBreak
         && textSizeAdjust == o.textSizeAdjust
         && resize == o.resize
-        && userSelect == o.userSelect;
+        && userSelect == o.userSelect
+        && boxOrient == o.boxOrient;
 }
 
 bool StyleRareInheritedData::shadowDataEquivalent(const StyleRareInheritedData& o) const
diff --git a/tests/platform/mac/fast/flexbox/box-orient-button-expected.checksum b/tests/platform/mac/fast/flexbox/box-orient-button-expected.checksum
new file mode 100644
index 0000000..6db26bd
--- /dev/null
+++ b/tests/platform/mac/fast/flexbox/box-orient-button-expected.checksum
@@ -0,0 +1 @@
+61a373ee739673a9dcd7bac62b9f182e
\ No newline at end of file
'''
