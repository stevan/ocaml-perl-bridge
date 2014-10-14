#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;
open PoCaml.Scalar;;

plan 3;;

(* undef (or unit types in Ocaml) *)
ok (sv_is_undef (sv_undef ())) "... sv_is_undef (sv_undef) = true";;
ok (not (sv_is_undef (sv_true ()))) "... sv_is_undef (sv_true) = false";;

is (sv_type (sv_undef ())) SVt_NULL "... sv_undef returns the right SV type";;

(* Check for memory errors. *)
Gc.full_major ()