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

FROM silkeh/clang:19-bookworm

RUN apt-get update && apt-get install -y python3 jq git clang-tools && apt-get clean

RUN apt-get update && apt-get install -y libgtest-dev && apt-get clean

ADD scan_build_all_the_things.sh /

RUN chmod a+rx /scan_build_all_the_things.sh

CMD ["echo 'Run with tools/distrib/scan_build_code.sh'"]
