/* { dg-do compile { target i?86-*-* x86_64-*-* aarch64*-*-* } } */
/* { dg-options "-fopenmp" } */
/* { dg-options "-fopenmp -march=armv8.2-a+sve" { target aarch64*-*-* } } */

#pragma omp declare simd simdlen(4) notinbranch
int f2 (int a, int b)
{
  if (a > 5)
    return a + b;
  else
    return a - b;
}
