#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;
open PoCaml.Env;;
open PoCaml.Scalar;;

ignore(eval "
$scalar_val = 42;
@array_val  = (1, 2, 3, 4);
%hash_val   = (one => 1, two => 2, three => 3);
");;

plan 6;;

is (int_of_sv (eval "42")) 42 "... evaluated a perl value correctly";;
ok (sv_is_undef (eval "undef")) "... evaluated a perl value correctly";;
ok (sv_is_true (eval "1")) "... evaluated a perl value correctly";;

is (int_of_sv (get_sv "scalar_val")) 42 "... fetched a perl sv value correctly";;
is (PoCaml.Array.map (int_of_sv) (get_av "array_val")) [1;2;3;4] "... fetched a perl av value correctly";;

is (List.sort (compare) (List.map (int_of_sv) (PoCaml.Hash.values (get_hv "hash_val"))))
   [1;2;3] 
   "... fetched a perl hv value correctly";;

(* Check for memory errors. *)
Gc.full_major ()