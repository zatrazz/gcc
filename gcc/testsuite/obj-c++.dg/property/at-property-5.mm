/* Contributed by Nicola Pero <nicola.pero@meta-innovation.com>, October 2010.  */
/* { dg-do compile } */

#include <objc/objc.h>

@interface MyRootClass
{
  Class isa;
  id property_a;
  int property_b;
  int property_c;
  int property_d;
  id property_e;
  id property_f;
  id property_g;
  id property_h;
}

/* Test various error messages.  */
/* FIXME - there is a problem with the testuite in running the following test.  The compiler
   generates the messages, but the testsuite still complains.  */
/*@property id property_a;*/      /*  dg-warning "object property .property.a. has no .assign., .retain. or .copy. attribute"  */
			      /*  dg-message ".assign. can be unsafe for Objective-C objects" "" { target *-*-* } 20  */
@property int property_b = 4; /* { dg-error "expected" } */
@property (retain) int property_c; /* { dg-error ".retain. attribute is only valid for Objective-C objects" } */
@property (copy) int property_d; /* { dg-error ".copy. attribute is only valid for Objective-C objects" } */

@property (retain) id property_e;
@property (retain) id property_f;
@property (retain) id property_g;
@property (retain) id property_h;
/* FIXME - there is a problem with the testuite in running the following test.  The compiler
   generates the messages, but the testsuite still complains.  */
/*@property (retain) id property_e;*/ /*  dg-error "redeclaration of property .property_e."  */
   			          /*  dg-message "originally specified here" "" { target *-*-* } 26  */
@end

@property id test; /* { dg-error "misplaced .@property. Objective-C.. construct" } */
