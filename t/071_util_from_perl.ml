#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;
open PoCaml.Utils;;

plan 8;;

(* basic scalars *)

is (variant_of_perl(PoCaml.Env.eval("undef"))) (`Null)         "... variant_of_perl successfull";;
is (variant_of_perl(PoCaml.Env.eval("1")))     (`Int 1)        "... variant_of_perl successfull";;
is (variant_of_perl(PoCaml.Env.eval("1.5")))   (`Float 1.5)    "... variant_of_perl successfull";;
is (variant_of_perl(PoCaml.Env.eval("'Foo'"))) (`String "Foo") "... variant_of_perl successfull";;

(* basic array refs *)

is
    (variant_of_perl(PoCaml.Env.eval("[1, 2, 3, 4]")))
    (`Array [`Int 1; `Int 2; `Int 3; `Int 4])
"... variant_of_perl successfull";;

is
    (variant_of_perl(PoCaml.Env.eval("[1, 'foo', 2.5, [1, 2]]")))
    (`Array [`Int 1; `String "foo"; `Float 2.5; `Array [`Int 1; `Int 2]])
"... variant_of_perl successfull";;

(* basic hashrefs *)

is
    (variant_of_perl(PoCaml.Env.eval("{ foo => 1, bar => 2.5 }")))
    (`Hash [("foo", `Int 1); ("bar", `Float 2.5)])
"... variant_of_perl successfull";;


is
    (variant_of_perl(PoCaml.Env.eval("{ foo => [1, 2, 3, 'bar']}")))
    (`Hash [("foo", `Array [`Int 1; `Int 2; `Int 3; `String "bar"])])
"... variant_of_perl successfull";;



(* Check for memory errors. *)
Gc.full_major ()