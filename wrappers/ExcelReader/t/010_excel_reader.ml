#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "testSimple";;
#require "poCaml";;

#load "excelReader.cma";;

open TestSimple;;

ExcelReader.init();;

let r             = ExcelReader.load_file "t/excel/test.xls";;
let words_sheet   = r#find_worksheet_by_name "words";;
let numbers_sheet = r#find_worksheet_by_name "numbers";;
let blank_sheet   = r#find_worksheet_by_name "blank";;

plan 34;;

(is 
    (List.map (fun s -> s#name) r#worksheets)
    ["words";"numbers";"blank"]
    "... got the names of all the sheets we expected");;

(is words_sheet#name "words" "... find_sheet_by_name works");;
(ok words_sheet#has_data "... has_data works");;
(is words_sheet#min_row 0 "... min_row works");;
(is words_sheet#max_row 1 "... max_row works");;
(is words_sheet#min_col 0 "... min_col works");;
(is words_sheet#max_col 1 "... max_col works");;
(is words_sheet#number_of_rows 2 "... number_of_rows works");;
(is words_sheet#number_of_cols 2 "... number_of_cols works");;
(is 
    (words_sheet#get_row_at 0)
    ["foo";"bar"]
    "... words first row is correct");;
(is 
    (words_sheet#get_row_at 1)
    ["bar";"baz"]
    "... words second row is correct");;
(is 
    (words_sheet#map_rows (fun row -> row))
    [["foo";"bar"];["bar";"baz"]]
    "... words map_rows is correct");;
(let rows = ref [] in
    (words_sheet#iter_rows (fun row -> rows := (row :: !rows); ()));
    (is 
        (List.rev !rows)
        [["foo";"bar"];["bar";"baz"]]
        "... words iter_rows is correct");       
);;

(is numbers_sheet#name "numbers" "... find_sheet_by_name works");;
(ok numbers_sheet#has_data "... has_data works");;
(is numbers_sheet#min_row 0 "... min_row works");;
(is numbers_sheet#max_row 3 "... max_row works");;
(is numbers_sheet#min_col 0 "... min_col works");;
(is numbers_sheet#max_col 2 "... max_col works");;
(is numbers_sheet#number_of_rows 4 "... number_of_rows works");;
(is numbers_sheet#number_of_cols 3 "... number_of_cols works");;

(is 
    (numbers_sheet#get_row_at 0)
    ["1";"2";"3"]
    "... numbers first row is correct");;
(is 
    (numbers_sheet#get_row_at 1)
    ["2";"3";"4"]
    "... numbers second row is correct");;
(is 
    (numbers_sheet#map_rows (fun row -> row))
    [["1";"2";"3"];["2";"3";"4"];["3";"4";"5"];["4";"5";"6"]]
    "... numbers map_rows");; 
(let rows = ref [] in
    (numbers_sheet#iter_rows (fun row -> rows := (row :: !rows); ()));
    (is 
        (List.rev !rows)
        [["1";"2";"3"];["2";"3";"4"];["3";"4";"5"];["4";"5";"6"]]
        "... numbers iter_rows");     
);;

(is 
    (numbers_sheet#extract_rectangle ~top:0 ~left:0 ~right:1 ~bottom:2 ())
    [["1";"2"];["2";"3"];["3";"4"]]
    "... extract rectangle is correct");;

(is blank_sheet#name "blank" "... find_sheet_by_name works");;  
(ok (not blank_sheet#has_data) "... has_data works");;  
(is blank_sheet#min_row 0 "... min_row works");;
(is blank_sheet#max_row 0 "... max_row works");;
(is blank_sheet#min_col 0 "... min_col works");;
(is blank_sheet#max_col 0 "... max_col works");;
(is blank_sheet#number_of_rows 0 "... number_of_rows works");;
(is blank_sheet#number_of_cols 0 "... number_of_cols works");; 

