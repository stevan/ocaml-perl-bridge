#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;

plan 1;;

ok true "... passed";;

(* Check for memory errors. *)
Gc.full_major ()