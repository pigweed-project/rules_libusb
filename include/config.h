// Copyright 2024 The Pigweed Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if defined(_WIN32) || defined(_WIN64)

#if defined(_MSC_VER)
#include "msvc/config.h"
#endif  // defined(_MSC_VER)

// TODO: MinGW-W64 and clang support.

#define _RULES_LIBUSB_OS_SUPPORTED 1

#elif defined(__linux__)

#include "linux/config.h"

#define _RULES_LIBUSB_OS_SUPPORTED 1

#elif defined(__APPLE__)

#include "Xcode/config.h"
#if __has_include(<IOKit/usb/IOUSBHostFamilyDefinitions.h>)
#define HAVE_IOKIT_USB_IOUSBHOSTFAMILYDEFINITIONS_H 1
#endif

#define _RULES_LIBUSB_OS_SUPPORTED 1

#endif  // defined(_WIN32) || defined(_WIN64)

#if !defined(_RULES_LIBUSB_OS_SUPPORTED) || !_RULES_LIBUSB_OS_SUPPORTED
#error Unsupported configuration, either contribute to rules_libusb, or build your own `config.h`.
#endif  // !defined(_RULES_LIBUSB_OS_SUPPORTED)
