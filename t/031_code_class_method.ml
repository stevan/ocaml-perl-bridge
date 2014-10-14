#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;

open PoCaml.Env;;
open PoCaml.Scalar;;
open PoCaml.Code;;

(* create some perl functions to call *)
ignore(eval "
package Foo;
sub basic { 'Hello OCaml World' }
sub basic_w_args { 'Hello ' . $_[1] }
sub basic_array { (1, 2, 3, 4) }
sub basic_array_w_context { 
    wantarray ? ('called', 'in', 'array') : 'called in scalar' 
}
");;

plan 11;;

(* call in void context *)

is (call_class_method_in_void "Foo" "basic" []) () "... called basic in void okay";;
is (call_class_method_in_void "Foo" "basic_w_args" [ sv_of_string "foo" ]) () "... called basic_w_args in void okay";;
is (call_class_method_in_void "Foo" "basic_array" []) () "... called basic_array in void okay";;
is (call_class_method_in_void "Foo" "basic_array_w_context" []) () "... called basic_array_w_context in void okay";;

(* call in scalar context *)

let rv = call_class_method_in_scalar "Foo" "basic" [] in
is (string_of_sv rv) "Hello OCaml World" "... called basic in scalar okay";;

let rv = call_class_method_in_scalar "Foo" "basic_w_args" [ sv_of_string "Perl World" ] in
is (string_of_sv rv) "Hello Perl World" "... called basic_w_args in scalar okay";;

(* call in array context *)

let rv = call_class_method_in_array "Foo" "basic" [] in
is (List.map (string_of_sv) rv) ["Hello OCaml World"] "... called basic in scalar okay";;

let rv = call_class_method_in_array "Foo" "basic_w_args" [ sv_of_string "Perl World" ] in
is (List.map (string_of_sv) rv) ["Hello Perl World"] "... called basic_w_args in scalar okay";;

let rv = call_class_method_in_array "Foo" "basic_array" [] in
is (List.map (int_of_sv) rv) [ 1; 2; 3; 4 ] "... called basic_array in array okay";;

(* context sensitive calls *)

let rv = call_class_method_in_array "Foo" "basic_array_w_context" [] in
is (List.map (string_of_sv) rv) [ "called"; "in"; "array" ] "... called basic_array_w_context in array okay";;

let rv = call_class_method_in_scalar "Foo" "basic_array_w_context" [] in
is (string_of_sv rv) "called in scalar" "... called basic_array_w_context in scalar okay";;


(* Check for memory errors. *)
Gc.full_major ()