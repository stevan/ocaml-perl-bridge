#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;
open PoCaml.Scalar;;
open PoCaml.Env;;

plan 26;;

is (sv_type (eval "undef"))    SVt_NULL "... sv_type passed";;
is (sv_type (eval "1"))        SVt_IV   "... sv_type passed";;
is (sv_type (eval "1.0"))      SVt_NV   "... sv_type passed";;
is (sv_type (eval "'foo'"))    SVt_PV   "... sv_type passed";;
is (sv_type (eval "\\($var)")) SVt_RV   "... sv_type passed";;
is (sv_type (eval "*STDIN"))   SVt_PVGV "... sv_type passed";;

(*
I am not sure how to get values which will show these:
    SVt_PVAV
    SVt_PVHV
    SVt_PVCV
    SVt_PVMG
as their SV types. At least not using the mechanisms I have 
available to me, which includes my limited knowledge of 
perl guts.
*)

is (string_of_sv_t SVt_NULL) "SVt_NULL" "... string_of_sv_t passed";;
is (string_of_sv_t SVt_IV  ) "SVt_IV"   "... string_of_sv_t passed";;
is (string_of_sv_t SVt_NV  ) "SVt_NV"   "... string_of_sv_t passed";;
is (string_of_sv_t SVt_PV  ) "SVt_PV"   "... string_of_sv_t passed";;
is (string_of_sv_t SVt_RV  ) "SVt_RV"   "... string_of_sv_t passed";;
is (string_of_sv_t SVt_PVAV) "SVt_PVAV" "... string_of_sv_t passed";;
is (string_of_sv_t SVt_PVHV) "SVt_PVHV" "... string_of_sv_t passed";;
is (string_of_sv_t SVt_PVCV) "SVt_PVCV" "... string_of_sv_t passed";;
is (string_of_sv_t SVt_PVGV) "SVt_PVGV" "... string_of_sv_t passed";;
is (string_of_sv_t SVt_PVMG) "SVt_PVMG" "... string_of_sv_t passed";;

is (name_of_sv_t SVt_NULL) "UNDEF"  "... name_of_sv_t passed";;
is (name_of_sv_t SVt_IV  ) "INT"    "... name_of_sv_t passed";;
is (name_of_sv_t SVt_NV  ) "FLOAT"  "... name_of_sv_t passed";;
is (name_of_sv_t SVt_PV  ) "STRING" "... name_of_sv_t passed";;
is (name_of_sv_t SVt_RV  ) "REF"    "... name_of_sv_t passed";;
is (name_of_sv_t SVt_PVAV) "ARRAY"  "... name_of_sv_t passed";;
is (name_of_sv_t SVt_PVHV) "HASH"   "... name_of_sv_t passed";;
is (name_of_sv_t SVt_PVCV) "CODE"   "... name_of_sv_t passed";;
is (name_of_sv_t SVt_PVGV) "GLOB"   "... name_of_sv_t passed";;
is (name_of_sv_t SVt_PVMG) "MAGIC"  "... name_of_sv_t passed";;

(* Check for memory errors. *)
Gc.full_major ()