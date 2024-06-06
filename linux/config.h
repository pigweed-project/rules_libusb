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

#define DEFAULT_VISIBILITY __attribute__ ((visibility ("default")))
#define ENABLE_LOGGING 1
#define HAVE_ASM_TYPES_H 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_DECL_EFD_CLOEXEC 1
#define HAVE_DECL_EFD_NONBLOCK 1
#define HAVE_DECL_TFD_CLOEXEC 1
#define HAVE_DECL_TFD_NONBLOCK 1
#define HAVE_DLFCN_H 1
#define HAVE_EVENTFD 1
#define HAVE_INTTYPES_H 1
#define HAVE_NFDS_T 1
#define HAVE_PIPE2 1
#define HAVE_PTHREAD_CONDATTR_SETCLOCK 1
#define HAVE_PTHREAD_SETNAME_NP 1
#define HAVE_STDINT_H 1
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_TIMERFD 1
#define HAVE_UNISTD_H 1

#define PLATFORM_POSIX 1

/* Required for libusb < 1.0.24. */
#define THREADS_POSIX 1
#define POLL_NFDS_TYPE nfds_t
#define USBI_TIMERFD_AVAILABLE 1
#define OS_LINUX 1
#define HAVE_LINUX_FILTER_H 1
#define HAVE_LINUX_NETLINK_H 1
#define HAVE_POLL_H 1
#define HAVE_SYSLOG_FUNC 1
#define HAVE_SYSLOG_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_GETTIMEOFDAY 1

#define PRINTF_FORMAT(a, b) __attribute__ ((__format__ (__printf__, a, b)))
#define STDC_HEADERS 1

#define _GNU_SOURCE 1

// Explicitly define HAVE_LIBUDEV to prevent auto-detection.
#ifndef HAVE_LIBUDEV
#if __has_include(<libudev.h>)
#define HAVE_LIBUDEV 1
#define USE_UDEV 1
#endif  // __has_include(<libudev.h>)
#endif  // HAVE_LIBUDEV
