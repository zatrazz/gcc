/* { dg-do compile { target i?86-*-* x86_64-*-* aarch64*-*-* } } */
/* { dg-options "-fopenmp -w" } */
/* { dg-options "-fopenmp -w -march=armv8.2-a+sve" { target aarch64*-*-* } } */

/* ?? The -w above is to inhibit the following warning for now:
   a.c:2:6: warning: AVX vector argument without AVX enabled changes
   the ABI.  */

#pragma omp declare simd notinbranch simdlen(4)
void foo (int *a)
{
  *a = 555;
}
