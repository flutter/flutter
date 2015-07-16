/* pnggccrd.c was removed from libpng-1.2.20. */

/* This code snippet is for use by configure's compilation test. */

#if (!defined _MSC_VER) && \
    defined(PNG_ASSEMBLER_CODE_SUPPORTED) && \
    defined(PNG_MMX_CODE_SUPPORTED)

int PNGAPI png_dummy_mmx_support(void);

static int _mmx_supported = 2; // 0: no MMX; 1: MMX supported; 2: not tested

int PNGAPI
png_dummy_mmx_support(void) __attribute__((noinline));

int PNGAPI
png_dummy_mmx_support(void)
{
   int result;
#ifdef PNG_MMX_CODE_SUPPORTED  // superfluous, but what the heck
    __asm__ __volatile__ (
#ifdef __x86_64__
        "pushq %%rbx          \n\t"  // rbx gets clobbered by CPUID instruction
        "pushq %%rcx          \n\t"  // so does rcx...
        "pushq %%rdx          \n\t"  // ...and rdx (but rcx & rdx safe on Linux)
        "pushfq               \n\t"  // save Eflag to stack
        "popq %%rax           \n\t"  // get Eflag from stack into rax
        "movq %%rax, %%rcx    \n\t"  // make another copy of Eflag in rcx
        "xorl $0x200000, %%eax \n\t" // toggle ID bit in Eflag (i.e., bit 21)
        "pushq %%rax          \n\t"  // save modified Eflag back to stack
        "popfq                \n\t"  // restore modified value to Eflag reg
        "pushfq               \n\t"  // save Eflag to stack
        "popq %%rax           \n\t"  // get Eflag from stack
        "pushq %%rcx          \n\t"  // save original Eflag to stack
        "popfq                \n\t"  // restore original Eflag
#else
        "pushl %%ebx          \n\t"  // ebx gets clobbered by CPUID instruction
        "pushl %%ecx          \n\t"  // so does ecx...
        "pushl %%edx          \n\t"  // ...and edx (but ecx & edx safe on Linux)
        "pushfl               \n\t"  // save Eflag to stack
        "popl %%eax           \n\t"  // get Eflag from stack into eax
        "movl %%eax, %%ecx    \n\t"  // make another copy of Eflag in ecx
        "xorl $0x200000, %%eax \n\t" // toggle ID bit in Eflag (i.e., bit 21)
        "pushl %%eax          \n\t"  // save modified Eflag back to stack
        "popfl                \n\t"  // restore modified value to Eflag reg
        "pushfl               \n\t"  // save Eflag to stack
        "popl %%eax           \n\t"  // get Eflag from stack
        "pushl %%ecx          \n\t"  // save original Eflag to stack
        "popfl                \n\t"  // restore original Eflag
#endif
        "xorl %%ecx, %%eax    \n\t"  // compare new Eflag with original Eflag
        "jz 0f                \n\t"  // if same, CPUID instr. is not supported

        "xorl %%eax, %%eax    \n\t"  // set eax to zero
//      ".byte  0x0f, 0xa2    \n\t"  // CPUID instruction (two-byte opcode)
        "cpuid                \n\t"  // get the CPU identification info
        "cmpl $1, %%eax       \n\t"  // make sure eax return non-zero value
        "jl 0f                \n\t"  // if eax is zero, MMX is not supported

        "xorl %%eax, %%eax    \n\t"  // set eax to zero and...
        "incl %%eax           \n\t"  // ...increment eax to 1.  This pair is
                                     // faster than the instruction "mov eax, 1"
        "cpuid                \n\t"  // get the CPU identification info again
        "andl $0x800000, %%edx \n\t" // mask out all bits but MMX bit (23)
        "cmpl $0, %%edx       \n\t"  // 0 = MMX not supported
        "jz 0f                \n\t"  // non-zero = yes, MMX IS supported

        "movl $1, %%eax       \n\t"  // set return value to 1
        "jmp  1f              \n\t"  // DONE:  have MMX support

    "0:                       \n\t"  // .NOT_SUPPORTED: target label for jump instructions
        "movl $0, %%eax       \n\t"  // set return value to 0
    "1:                       \n\t"  // .RETURN: target label for jump instructions
#ifdef __x86_64__
        "popq %%rdx           \n\t"  // restore rdx
        "popq %%rcx           \n\t"  // restore rcx
        "popq %%rbx           \n\t"  // restore rbx
#else
        "popl %%edx           \n\t"  // restore edx
        "popl %%ecx           \n\t"  // restore ecx
        "popl %%ebx           \n\t"  // restore ebx
#endif

//      "ret                  \n\t"  // DONE:  no MMX support
                                     // (fall through to standard C "ret")

        : "=a" (result)              // output list

        :                            // any variables used on input (none)

                                     // no clobber list
//      , "%ebx", "%ecx", "%edx"     // GRR:  we handle these manually
//      , "memory"   // if write to a variable gcc thought was in a reg
//      , "cc"       // "condition codes" (flag bits)
    );
    _mmx_supported = result;
#else
    _mmx_supported = 0;
#endif /* PNG_MMX_CODE_SUPPORTED */

    return _mmx_supported;
}
#endif
