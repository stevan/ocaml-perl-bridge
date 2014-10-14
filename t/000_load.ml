#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;

plan 1;;

(* Just reference PoCaml and 
   force it to be loaded ... 
   nothing else here to see *)
   
ok (PoCaml.Scalar.sv_is_true (PoCaml.Scalar.sv_true ())) "... passed";;

(* Check for memory errors. *)
Gc.full_major ()