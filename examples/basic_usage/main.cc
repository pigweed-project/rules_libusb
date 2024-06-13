// Copyright 2024 The Pigweed Authors
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy of
// the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations under
// the License.

#include <cstdio>

#include "libusb.h"

int main() {
    libusb_device** devs;
    if (libusb_init(nullptr) < 0) {
        printf("Error: Failed to initialize libusb\n");
        return 1;
    }

    ssize_t device_count = libusb_get_device_list(nullptr, &devs);
    if (device_count < 0) {
        printf("Error: Failed to enumerate devices\n");
        return 1;
    }
    printf("%d devices attached\n", static_cast<int>(device_count));

    libusb_free_device_list(devs, 1);
    libusb_exit(nullptr);
    return 0;
}
