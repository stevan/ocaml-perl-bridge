#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;
#require "unix";;
#require "poCaml";;
#require "extLib";;

#load "dBI.cma";;

open TestSimple;;
open PoCaml.Utils;;

DBI.init();;

let db_file = "t/dbfile.db";;
try Unix.unlink db_file with _ -> ();;

let dbh = DBI.connect ("dbi:SQLite:dbname=" ^ db_file) "" "";;

let setup () = 
    ignore (dbh#do_sql "CREATE TABLE foo (
                    bar int,
                    baz float,
                    gorch varchar(50)
                )");
    ignore (dbh#do_sql "INSERT INTO foo (bar, baz, gorch) VALUES(1, 2.5, 'hello')");
    ignore (dbh#do_sql "INSERT INTO foo (bar, baz, gorch) VALUES(2, 5.75, 'world')"); 
;;
                
setup ();;

let sth1 = dbh#prepare "SELECT bar, baz, gorch FROM foo WHERE bar = ?";;
let sth2 = dbh#prepare "SELECT bar, baz, gorch FROM foo";;

plan 4;;

(
    sth1#execute ~params:(`Int 1) ();
    (is sth1#fetch_row 
        (`Array [ `Float 1.; `Float 2.5; `String "hello" ])
        "... execute w/ params worked ")
);;

is sth1#fetch_row `Null "... fetch_row has exhausted the results";;

(
    sth1#execute ~params:(`Int 2) ();
    (is sth1#fetch_row 
        (`Array [ `Float 2.; `Float 5.75; `String "world" ])
        "... execute w/ params worked ")
);;

(
    sth2#execute ();
    (is (sth2#map (fun x -> x))
        [
        (`Array [ `Float 1.; `Float 2.5; `String "hello" ]);
        (`Array [ `Float 2.; `Float 5.75; `String "world" ]);        
        ]
        "... excute w/out params worked")
);;

sth1#finish;;
sth2#finish;;

dbh#disconnect;;

try Unix.unlink db_file with _ -> ();;
