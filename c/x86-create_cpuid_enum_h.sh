#!/bin/sh
# Create x86-cpuid_enum.h by parsing cpufeature.h from Linux
# (/usr/src/linux/arch/x86/include/asm/cpufeature.h)

CPU_FEATURE_FILE="x86-linux-cpufeature.h.tmp"
CPU_SCATTERED_FILE="x86-linux-cpu-scattered.c.tmp"

if ! [ -r "$CPU_FEATURE_FILE" -a -r "$CPU_SCATTERED_FILE" ]
then
    echo >&2 "Unable to read $CPU_FEATURE_FILE or $CPU_SCATTERED_FILE"
    echo >&2 "Use 'make update_cpuid' to update x86-cpuid_enum.h"
    exit 1
fi

# Header
cat << EOF
/**
 * This file is automatically generated.
 * DO NOT EDIT THIS FILE DIRECTLY.
 *
 * NB: designated initializers are a C99 feature so use __extension__ to be
 *   able to compile with -pendantic.
 */

#ifndef CPUID_ENUM_H
#define CPUID_ENUM_H

#include <assert.h>
EOF

# CPUID fields from /usr/src/linux/arch/x86/include/asm/cpufeature.h
extract_cpuid_features() {
    cat << EOF

/**
 * $3
 */
__extension__ static const char* $2[32] = {
EOF
    sed -n 's/^#define X86_FEATURE_\(\S\+\)\s\+(\s*'$1'\*32+\s*\([0-9]\+\)\s*).*/    [\2] = "\1",/p' < "$CPU_FEATURE_FILE" | tr '[A-Z]' '[a-z]'
    echo '};'
}
extract_cpuid_features 0 cpuidstr_1_edx 'cpuid 0x00000001, edx register' | sed 's/"ds"/"dts"/;s/"xmm/"sse/'
extract_cpuid_features 4 cpuidstr_1_ecx 'cpuid 0x00000001, ecx register' | sed 's/"xmm/"sse/'
extract_cpuid_features 9 cpuidstr_7_ebx 'cpuid 0x00000007:0, ebx register'
extract_cpuid_features 1 cpuidstr_ext1_edx 'cpuid 0x80000001, edx register'
extract_cpuid_features 6 cpuidstr_ext1_ecx 'cpuid 0x80000001, ecx register'

# CPUID fields from /usr/src/linux/arch/x86/kernel/cpu/scattered.c
extract_cpuid_scat_features() {
    local CPUIDNUM
    CPUIDNUM=$(echo "$1" | sed 's/0x8000000/ext/;s/0x0000000//')
    REG_NAME_UP=$(echo "$2" | tr '[a-z]' '[A-Z]')
    cat << EOF

/**
 * cpuid $1, $2 register
 */
__extension__ static const char* cpuidstr_${CPUIDNUM}_$2[32] = {
EOF
    sed -n 's/^\t*{ X86_FEATURE_\(\S\+\),\s*CR_'"$REG_NAME_UP"',\s*\([0-9]\+\),\s*'"$1"',.*/    [\2] = "\1",/p' < "$CPU_SCATTERED_FILE" | tr '[A-Z]' '[a-z]'
    echo '};'
}
extract_cpuid_scat_features 0x00000006 eax
extract_cpuid_scat_features 0x00000006 ecx
extract_cpuid_scat_features 0x80000007 edx

# Fix things up
cat << EOF

static void add_manual_cpuid_str(void)
{
    /* https://en.wikipedia.org/wiki/CPUID */
    assert(cpuidstr_1_ecx[11] == NULL);
    cpuidstr_1_ecx[11] = "sdbg";

    assert(cpuidstr_7_ebx[17] == NULL);
    cpuidstr_7_ebx[17] = "avx512dq";
    assert(cpuidstr_7_ebx[21] == NULL);
    cpuidstr_7_ebx[21] = "avx512ifma";
    assert(cpuidstr_7_ebx[29] == NULL);
    cpuidstr_7_ebx[29] = "sha";
    assert(cpuidstr_7_ebx[30] == NULL);
    cpuidstr_7_ebx[30] = "avx512bw";
    assert(cpuidstr_7_ebx[31] == NULL);
    cpuidstr_7_ebx[31] = "avx512vl";

    /* documented in /usr/src/linux/arch/x86/kernel/cpu/{amd.c,intel.c}
     * and also /usr/src/linux/tools/power/x86/turbostat/turbostat.c
     */
    assert(cpuidstr_ext7_edx[8] == NULL);
    cpuidstr_ext7_edx[8] = "constant_tsc";
}
EOF

# Footer
cat << EOF

#endif
EOF
