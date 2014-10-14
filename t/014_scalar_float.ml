#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;
open PoCaml.Scalar;;
open PoCaml.Env;;

plan 3;;

(* float *)
is (float_of_sv (eval "10.5")) 10.5 "... float_of_sv (eval '10.5') = 10.5";;
is (float_of_sv (sv_of_float 42.3)) 42.3 "... float_of_sv (sv_of_float 42.3) = 42.3";;

is (sv_type (sv_of_float 23.)) SVt_NV "... sv_of_float returns the right SV type";;

(* Check for memory errors. *)
Gc.full_major ()