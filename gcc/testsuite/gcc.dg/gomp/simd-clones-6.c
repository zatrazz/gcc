/* { dg-do compile { target i?86-*-* x86_64-*-* aarch64*-*-* } } */
/* { dg-options "-fopenmp" } */
/* { dg-options "-fopenmp -march=armv8.2-a+sve" { target aarch64*-*-* } } */

/* Test that array subscripts are properly adjusted.  */

int array[1000];
#pragma omp declare simd notinbranch simdlen(4)
void foo (int i)
{
  array[i] = 555;
}
