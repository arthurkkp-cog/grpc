#!/bin/bash
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

echo "========================================" 
echo "Clang Static Analyzer (scan-build)"
echo "========================================" 
echo "This will analyze the codebase for potential bugs"
echo "Reports will be generated in HTML and SARIF formats"
echo ""

set -ex

cd $(dirname $0)/../..
REPO_ROOT=$(pwd)

export MANUAL_TARGETS=$(bazel query 'attr("tags", "manual", tests(//test/cpp/...))' | grep -v _on_ios)

tools/distrib/gen_compilation_database.py \
  --include_headers \
  --ignore_system_headers \
  --dedup_targets \
  "//:*" \
  "//src/core/..." \
  "//src/compiler/..." \
  "//test/core/..." \
  "//test/cpp/..." \
  $MANUAL_TARGETS

export SCAN_BUILD_OUTPUT=${SCAN_BUILD_OUTPUT:-${REPO_ROOT}/scan-build-reports}

if [ "$SCAN_BUILD_SKIP_DOCKER" == "" ]
then
  docker build -t grpc_scan_build tools/dockerfile/grpc_scan_build

  docker run \
    -e SCAN_BUILD_ROOT="/local-code" \
    -e SCAN_BUILD_OUTPUT="/local-code/scan-build-reports" \
    --rm=true \
    -v "${REPO_ROOT}":/local-code \
    -v "${HOME/.cache/bazel}":"${HOME/.cache/bazel}" \
    --user "$(id -u):$(id -g)" \
    -t grpc_scan_build /scan_build_all_the_things.sh "$@"
  
  echo ""
  echo "========================================" 
  echo "Analysis Complete!"
  echo "========================================" 
  echo "Reports location: ${SCAN_BUILD_OUTPUT}"
  echo ""
  echo "The reports are available in:"
  echo "  - HTML format (for human viewing)"
  echo "  - SARIF format (for tool integration)"
  echo ""
else
  SCAN_BUILD_ROOT="${REPO_ROOT}" tools/dockerfile/grpc_scan_build/scan_build_all_the_things.sh "$@"
fi
