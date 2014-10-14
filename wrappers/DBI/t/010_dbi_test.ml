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

plan 5;;
    
is dbh#ping true "... ping is successful";;

is (dbh#select_row "SELECT bar, baz, gorch FROM foo")
    (`Array [ `Float 1.; `Float 2.5; `String "hello" ])
    "... selectrow_arrayref worked";;
    
is (dbh#select_all "SELECT bar, baz, gorch FROM foo")
    (`Array [
        `Array [ `Float 1.; `Float 2.5; `String "hello" ];
        `Array [ `Float 2.; `Float 5.75; `String "world" ];
    ])
    "... selectall_arrayref worked";;

is (dbh#do_sql "INSERT INTO foo (bar, baz, gorch) VALUES(3, 10.25, 'boo')")
    1 
    "... do_sql worked";;

is (dbh#select_all "SELECT bar, baz, gorch FROM foo")
    (`Array [
        `Array [ `Float 1.; `Float 2.5; `String "hello" ];
        `Array [ `Float 2.; `Float 5.75; `String "world" ];
        `Array [ `Float 3.; `Float 10.25; `String "boo" ];        
    ])
    "... selectall_arrayref worked";;

dbh#disconnect;;

try Unix.unlink db_file with _ -> ();;

    
