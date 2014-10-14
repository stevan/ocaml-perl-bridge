#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "unix";;
#require "poCaml";;

module YAML =
struct

open PoCaml.Scalar
open PoCaml.Code
open PoCaml.Utils

let init () = ignore (PoCaml.Env.eval "use YAML::Syck")

let load yaml =
    variant_of_perl (call_in_scalar ~fn:"YAML::Syck::Load" [ sv_of_string yaml ])

let dump var = 
    string_of_sv (call_in_scalar ~fn:"YAML::Syck::Dump" [ perl_of_variant var ])

end

let _ = 
YAML.init ();
(YAML.load "---
foo:
    bar: 
        - 1
        - 2
        - 3
"),
(YAML.dump (`Hash [
  ("foo", 
    `Hash [
        ("bar", 
            `Array [
                `Int 1; 
                `Int 2; 
                `Int 3;
            ]
        )
    ])
]))
;;