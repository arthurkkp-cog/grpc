# Copyright 2024 gRPC authors.
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

# Ensure /Zi for separate PDB files on older CMake versions
# CMAKE_MSVC_DEBUG_INFORMATION_FORMAT requires CMake 3.25+
# For older versions, manually ensure /Zi instead of /Z7
if(MSVC AND CMAKE_VERSION VERSION_LESS "3.25")
  # Replace any /Z7 with /Zi for separate PDB files
  string(REPLACE "/Z7" "/Zi" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
  string(REPLACE "/Z7" "/Zi" CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}")
  
  # Ensure /Zi is present if not already
  if(NOT CMAKE_CXX_FLAGS_DEBUG MATCHES "/Zi")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /Zi")
  endif()
  if(NOT CMAKE_C_FLAGS_DEBUG MATCHES "/Zi")
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /Zi")
  endif()
endif()
