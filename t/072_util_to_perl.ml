#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;

#load "poCaml.cma";;

open TestSimple;;
open PoCaml.Utils;;

PoCaml.Env.eval("
    sub is_undef { not defined $_[0] }
    sub is_one { $_[0] == 1 }
    sub is_two_point_five { $_[0] == 2.5 }
    sub is_foo_string { $_[0] eq 'Foo' }  
    sub is_array_of_ints {
        # [ 1, 2, 3, 4]
        $_[0]->[0] == 1 &&
        $_[0]->[1] == 2 &&
        $_[0]->[2] == 3 &&
        $_[0]->[3] == 4                         
    }  
    sub is_mixed_array {
        # [1, 'foo', 2.5, [1, 2]]    
        $_[0]->[0] == 1      &&
        $_[0]->[1] eq 'foo'  &&
        $_[0]->[2] == 2.5    &&
        $_[0]->[3]->[0] == 1 &&
        $_[0]->[3]->[1] == 2        
    }
    sub is_basic_hash {
        # { foo => 1, bar => 2.5 }
        scalar(keys(%{$_[0]})) == 2 &&
        $_[0]->{foo} == 1           &&
        $_[0]->{bar} == 2.5
    }
    sub is_mixed_hash {
        # { foo => [1, 2, 3, 'bar']}
        scalar(keys(%{$_[0]})) == 1      &&
        ref($_[0]->{foo}) eq 'ARRAY' &&
        $_[0]->{foo}->[0] == 1       &&
        $_[0]->{foo}->[1] == 2       &&
        $_[0]->{foo}->[2] == 3       &&                
        $_[0]->{foo}->[3] eq 'bar'        
    }    
")

let test_sv f arg =
    try 
        (PoCaml.Scalar.sv_is_true (PoCaml.Code.call_in_scalar ~fn:f [ arg ]))
    with 
        _ -> false
;;

plan 8;;

(* basic scalars *)

ok (test_sv "is_undef"          (perl_of_variant `Null))           "... perl_of_variant successfull";;
ok (test_sv "is_one"            (perl_of_variant (`Int 1)))        "... perl_of_variant successfull";;
ok (test_sv "is_two_point_five" (perl_of_variant (`Float 2.5)))    "... perl_of_variant successfull";;
ok (test_sv "is_foo_string"     (perl_of_variant (`String "Foo"))) "... perl_of_variant successfull";;

(* basic arrayrefs *)

ok
    (test_sv "is_array_of_ints" 
        (perl_of_variant 
            (`Array [`Int 1; `Int 2; `Int 3; `Int 4])))
"... perl_of_variant successfull";;

ok
    (test_sv "is_mixed_array" 
        (perl_of_variant 
            (`Array [`Int 1; `String "foo"; `Float 2.5; `Array [`Int 1; `Int 2]])))
"... perl_of_variant successfull";;

(* basic hashrefs *)

ok
    (test_sv "is_basic_hash" 
        (perl_of_variant (`Hash [("foo", `Int 1); ("bar", `Float 2.5)])))
"... perl_of_variant successfull";;


ok
    (test_sv "is_mixed_hash" 
        (perl_of_variant 
            (`Hash [("foo", `Array [`Int 1; `Int 2; `Int 3; `String "bar"])])))
"... perl_of_variant successfull";;




(* Check for memory errors. *)
Gc.full_major ()