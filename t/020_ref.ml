#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;
open PoCaml.Scalar;;
open PoCaml.Ref;;
open PoCaml.Env;;

plan 14;;

is (reftype (ref_of_sv (sv_undef ())))             SVt_NULL "... reftype \\undef passed";;
is (reftype (ref_of_sv (sv_of_int 1)))             SVt_IV   "... reftype \\1 passed";;
is (reftype (ref_of_sv (sv_of_float 1.)))          SVt_NV   "... reftype \\1.0 passed";;
is (reftype (ref_of_sv (sv_of_string "foo")))      SVt_PV   "... reftype \\'foo' passed";;
is (reftype (ref_of_sv (ref_of_sv (sv_undef ())))) SVt_RV   "... reftype \\(\\undef) passed";;

is (reftype (ref_of_av (PoCaml.Array.create_empty ()))) SVt_PVAV "... reftype \\@foo passed";;
is (reftype (ref_of_hv (PoCaml.Hash.create_empty ())))  SVt_PVHV "... reftype \\%foo passed";;

(*
I am not sure how to handle these sv types
    SVt_PVCV
    SVt_PVGV
    SVt_PVMG
It seems like (from my slim understanding of C
and perl guts) that they cannot be dereferenced
using the pocaml_deref function. And quite 
possibly they would need special handling.
*)

is (sv_type (sv_of_ref (ref_of_sv (sv_undef ()))))             SVt_NULL "... sv_of_ref \\undef passed";;
is (sv_type (sv_of_ref (ref_of_sv (sv_of_int 1))))             SVt_IV   "... sv_of_ref \\1 passed";;
is (sv_type (sv_of_ref (ref_of_sv (sv_of_float 1.))))          SVt_NV   "... sv_of_ref \\1.0 passed";;
is (sv_type (sv_of_ref (ref_of_sv (sv_of_string "foo"))))      SVt_PV   "... sv_of_ref \\'foo' passed";;
is (sv_type (sv_of_ref (ref_of_sv (ref_of_sv (sv_undef ()))))) SVt_RV   "... sv_of_ref \\(\\undef) passed";;

is (PoCaml.Array.to_list (av_of_ref (ref_of_av (PoCaml.Array.create_empty ())))) [] "... av_of_ref \\@foo passed";;
is (PoCaml.Hash.keys (hv_of_ref (ref_of_hv (PoCaml.Hash.create_empty ()))))      [] "... hv_of_ref \\%foo passed";;

(* Check for memory errors. *)
Gc.full_major ()