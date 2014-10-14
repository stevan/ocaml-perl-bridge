#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;
#require "poCaml";;

#load "template.cma";;

open TestSimple;;
open PoCaml.Utils;;

Template.init();;

plan 2;;

(let t = Template.new_template() in
    (is 
        (t#process
            "t/templates/simple.tmpl"
            (`Hash [("foo", `String "World")]))
        "Hello World"
    "... processing the basic template worked")
);;

(let t = Template.new_template() in
    (is 
        (t#process
            "t/templates/complex.tmpl"
            (`Hash [
                ("name", `String "Complex");                
                ("list", `Array [ `Int 1; `Int 2; `Int 3;]);
            ]))
"Looping over 3 elements in Complex.
1
2
3"
    "... processing the complex template worked")
);;

