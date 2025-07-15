# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
WORKSPACE=../../engine.code-workspace
# json5 "$WORKSPACE" -s 2 -o engine.code-workspace
# yq eval -P engine.code-workspace > engine-workspace.yaml
yq eval -o=json engine-workspace.yaml > "$WORKSPACE"
temp_file=$(mktemp)
{ echo "// Don't edit directly, see //tools/vscode_workspace for a script"; echo "// that can refresh this from yaml."; cat "$WORKSPACE"; } > "$temp_file" && mv "$temp_file" "$WORKSPACE"
