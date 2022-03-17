/* { dg-options "-fopenmp -fdump-tree-optimized -O2" } */
/* { dg-options "-fopenmp -fdump-tree-optimized -O2 -march=armv8.2-a+sve" { target aarch64*-*-* } } */

/* Test that if there is no *inbranch clauses, that both the masked and
   the unmasked version are created.  */

#pragma omp declare simd
int addit(int a, int b, int c)
{
  return a + b;
}

/* { dg-final { scan-tree-dump "_ZGVbN4vvv_addit" "optimized" { target i?86-*-* x86_64-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVbM4vvv_addit" "optimized" { target i?86-*-* x86_64-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVcN4vvv_addit" "optimized" { target i?86-*-* x86_64-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVcM4vvv_addit" "optimized" { target i?86-*-* x86_64-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVdN8vvv_addit" "optimized" { target i?86-*-* x86_64-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVdM8vvv_addit" "optimized" { target i?86-*-* x86_64-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVeN16vvv_addit" "optimized" { target i?86-*-* x86_64-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVeM16vvv_addit" "optimized" { target i?86-*-* x86_64-*-* } } } */

/* { dg-final { scan-tree-dump "_ZGVnN2vvv_addit" "optimized" { target aarch64*-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVnM2vvv_addit" "optimized" { target aarch64*-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVnN4vvv_addit" "optimized" { target aarch64*-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVnM4vvv_addit" "optimized" { target aarch64*-*-* } } } */
/* { dg-final { scan-tree-dump "_ZGVsMxvvv_addit" "optimized" { target aarch64*-*-* } } } */
