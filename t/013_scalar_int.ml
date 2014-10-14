#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;
open PoCaml.Scalar;;
open PoCaml.Env;;

plan 3;;

(* ints *)
is (int_of_sv (eval "10")) 10 "... int_of_sv (eval '10') = 10";;
is (int_of_sv (sv_of_int 42)) 42 "... int_of_sv (sv_of_int 42) = 42";;

is (sv_type (sv_of_int 23)) SVt_IV "... sv_of_int returns the right SV type";;

(* Check for memory errors. *)
Gc.full_major ()