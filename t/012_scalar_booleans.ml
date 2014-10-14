#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;
open PoCaml.Scalar;;

plan 8;;

(* booleans *)
ok (sv_is_true (sv_true ())) "... sv_is_true (sv_true)";;
ok (not (sv_is_true (sv_false ()))) "... not sv_is_true (sv_false)";;

is (bool_of_sv (sv_true ())) true "... bool_of_sv (sv_true) = true";;
is (bool_of_sv (sv_false ())) false "... bool_of_sv (sv_false) = false";;

ok (sv_is_true (sv_of_bool true)) "... sv_of_bool (true) = sv_true";;
ok (not (sv_is_true (sv_of_bool false))) "... sv_of_bool (false) = sv_false";;

is (sv_type (sv_true ())) SVt_IV "... sv_true returns the right SV type (IV because it's 1)";;
is (sv_type (sv_false ())) SVt_IV "... sv_false returns the right SV type (IV because it's 0)";;

(* Check for memory errors. *)
Gc.full_major ()