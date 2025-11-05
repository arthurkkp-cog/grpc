#!/bin/sh
# Copyright 2015 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

OUTPUT_DIR=${SCAN_BUILD_OUTPUT:-/tmp/grpc-scan-build-reports}

cd ${SCAN_BUILD_ROOT}

mkdir -p ${OUTPUT_DIR}

CLANG_ANALYZER=$(which clang)

echo "Running Clang Static Analyzer using compilation database..."
echo "Output directory: ${OUTPUT_DIR}"
echo "Using analyzer: ${CLANG_ANALYZER}"

cat compile_commands.json | jq -r '.[].file' \
  | grep -E "(^include/|^src/core/|^src/cpp/|^test/core/|^test/cpp/)" \
  | grep -v -E "src/core/telemetry/stats_data" \
  | grep -v -E "/upb-gen/|/upbdefs-gen/" \
  | grep -v -E "(ports_undef.inc|ports_def.inc)" \
  | sort \
  | uniq > /tmp/files_to_analyze.txt

TOTAL_FILES=$(wc -l < /tmp/files_to_analyze.txt)
echo "Found ${TOTAL_FILES} files to analyze"

echo "#!/bin/bash" > /tmp/build_script.sh
echo "set -e" >> /tmp/build_script.sh

while IFS= read -r file; do
  COMMAND=$(jq -r ".[] | select(.file==\"${file}\") | .command" compile_commands.json | head -1)
  if [ ! -z "$COMMAND" ]; then
    echo "$COMMAND || true" >> /tmp/build_script.sh
  fi
done < /tmp/files_to_analyze.txt

chmod +x /tmp/build_script.sh

echo "Analyzing ${TOTAL_FILES} files with scan-build..."

scan-build \
  --use-analyzer=${CLANG_ANALYZER} \
  -plist-html \
  -sarif \
  -o ${OUTPUT_DIR} \
  --keep-cc \
  --force-analyze-debug-code \
  bash /tmp/build_script.sh

echo ""
echo "========================================" 
echo "Scan-build analysis complete!"
echo "========================================" 
echo "Reports saved to: ${OUTPUT_DIR}"
echo ""
if [ -d "${OUTPUT_DIR}" ] && [ "$(ls -A ${OUTPUT_DIR} 2>/dev/null)" ]; then
  REPORT_DIRS=$(find ${OUTPUT_DIR} -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
  HTML_COUNT=$(find ${OUTPUT_DIR} -name "*.html" 2>/dev/null | wc -l)
  SARIF_COUNT=$(find ${OUTPUT_DIR} -name "*.sarif" 2>/dev/null | wc -l)
  
  echo "Generated reports:"
  echo "  - HTML files: ${HTML_COUNT}"
  echo "  - SARIF files: ${SARIF_COUNT}"
  echo ""
  
  if [ ! -z "$REPORT_DIRS" ]; then
    echo "Report directories:"
    echo "$REPORT_DIRS" | while read dir; do
      echo "  - $dir"
    done
    echo ""
    echo "To view HTML reports, run:"
    echo "  scan-view <report-directory>"
    echo ""
    echo "SARIF reports can be uploaded to GitHub Code Scanning or imported into compatible tools"
  fi
else
  echo "No issues found (or no reports generated)"
fi
