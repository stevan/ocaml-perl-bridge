#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;
open PoCaml.Scalar;;
open PoCaml.Env;;

plan 3;;

(* string *)
is (string_of_sv (eval "'foo'")) "foo" "... string_of_sv (eval 'foo') = 'foo'";;
is (string_of_sv (sv_of_string "bar")) "bar" "... string_of_sv (sv_of_string 'bar') = 'bar'";;

is (sv_type (sv_of_string "baz")) SVt_PV "... sv_of_string returns the right SV type";;

(* Check for memory errors. *)
Gc.full_major ()