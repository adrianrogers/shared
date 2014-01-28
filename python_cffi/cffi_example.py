#!/usr/bin/env python
# -*- coding:UTF-8 -*-
"""Example of cffi library to interact with a C dynamic library

@author: Nicolas Iooss
"""
from cffi import FFI
import os.path


# Call functions from the standard lib C library
ffi = FFI()
ffi.cdef("""
    typedef unsigned int gid_t;
    typedef unsigned int uid_t;
    typedef int pid_t;

    gid_t getgid(void);
    uid_t getuid(void);
    pid_t getpid(void);
""")
libc = ffi.dlopen(None)
print("getuid() = {}".format(libc.getuid()))
print("getgid() = {}".format(libc.getgid()))
print("getpid() = {}".format(libc.getpid()))


# Use ffi.verify to compile code
ffi = FFI()
ffi.cdef('const size_t LONG_SIZE;')
libv = ffi.verify('const size_t LONG_SIZE = sizeof(long);')
print("sizeof(long) = {}".format(libv.LONG_SIZE))


# Add C definitions from header file, without any preprocessor macro
ffi = FFI()
current_dir = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(current_dir, 'cffi_example.h'), 'r') as fhead:
    cdefs = [line for line in fhead if not line.startswith('#')]
    ffi.cdef(''.join(cdefs))

_cffi_example = ffi.dlopen(os.path.join(current_dir, '_cffi_example.so'))

print(ffi.string(_cffi_example.helloworld).decode('utf-8'))
print("The answer is {}".format(_cffi_example.get_answer()))