#!/bin/sh
# Copyright 2017 gRPC authors.
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

ANALYZE_BUILD=${ANALYZE_BUILD:-analyze-build}

cd ${SCAN_BUILD_ROOT}

OUTPUT_DIR="${SCAN_BUILD_OUTPUT:-${SCAN_BUILD_ROOT}/scan-build-reports}"
mkdir -p "${OUTPUT_DIR}"

echo "Filtering compilation database to include only relevant files..."

jq '[.[] | select(.file | test("^(include/|src/core/|src/cpp/|test/core/|test/cpp/)")) | select(.file | test("(upb-gen|upbdefs-gen|telemetry/stats_data|ports_undef\\.inc|ports_def\\.inc)") | not)]' \
  compile_commands.json > compile_commands_filtered.json

echo "Running scan-build analysis using compilation database..."
echo "Reports will be saved to: ${OUTPUT_DIR}"
echo ""

${ANALYZE_BUILD} \
  --cdb compile_commands_filtered.json \
  -o "${OUTPUT_DIR}" \
  --status-bugs \
  --sarif-html \
  -enable-checker alpha.core.BoolAssignment \
  -enable-checker alpha.core.CastSize \
  -enable-checker alpha.core.CastToStruct \
  -enable-checker alpha.core.FixedAddr \
  -enable-checker alpha.core.PointerArithm \
  -enable-checker alpha.core.PointerSub \
  -enable-checker alpha.core.SizeofPtr \
  -enable-checker alpha.security.ArrayBoundV2 \
  -enable-checker alpha.security.MallocOverflow \
  -enable-checker alpha.security.ReturnPtrRange \
  -enable-checker alpha.unix.cstring.BufferOverlap \
  -enable-checker alpha.unix.cstring.NotNullTerminated \
  -enable-checker alpha.unix.cstring.OutOfBounds \
  -enable-checker security.insecureAPI.UncheckedReturn \
  -enable-checker security.insecureAPI.getpw \
  -enable-checker security.insecureAPI.gets \
  -enable-checker security.insecureAPI.mkstemp \
  -enable-checker security.insecureAPI.mktemp \
  -maxloop 4

echo ""
echo "Scan-build analysis complete!"
echo "Reports saved to: ${OUTPUT_DIR}"
echo ""
echo "To view the reports:"
echo "  Find the timestamped directory in ${OUTPUT_DIR}"
echo "  Open the index.html file in your browser"
