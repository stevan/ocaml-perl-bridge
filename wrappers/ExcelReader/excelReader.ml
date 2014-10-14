
open PoCaml.Scalar
open PoCaml.Ref
open PoCaml.Code

exception Error of string

let init () = ignore (PoCaml.Env.eval "use Spreadsheet::ParseExcel")

(** misc. utility functions *)

let fetch_hash_key_from_obj sv key =
    let hv = hv_of_ref sv in
    try 
        PoCaml.Hash.get hv key
    with 
        Not_found -> sv_undef ()

let int_of_sv_or_undef sv =
    if sv_is_undef sv then 0 else int_of_sv sv

(** class wrappers *)

class worksheet sv =
object (self)

    (** private methods *)

    method private clean_value value =
        if sv_is_true value then
            string_of_sv (call_method_in_scalar value "Value" [])
        else 
            ""

    method private clean_row row =
        PoCaml.Array.map (fun value -> self#clean_value value) (av_of_ref row)        

    method private get_rows_as_array =
        av_of_ref (fetch_hash_key_from_obj sv "Cells")

    (** public methods *)

    (** property accessors *)
    method name = 
        string_of_sv (fetch_hash_key_from_obj sv "Name")

    method max_row = 
        int_of_sv_or_undef (fetch_hash_key_from_obj sv "MaxRow")
        
    method min_row = 
        int_of_sv_or_undef (fetch_hash_key_from_obj sv "MinRow")
        
    method max_col = 
        int_of_sv_or_undef (fetch_hash_key_from_obj sv "MaxCol")

    method min_col = 
        int_of_sv_or_undef (fetch_hash_key_from_obj sv "MinCol")        

    (** virtual property accessors *)
        
    method number_of_rows =        
        let num_rows = self#max_row - self#min_row in
        if num_rows = 0 then 0 else num_rows + 1        
        
    method number_of_cols =
        let num_cols = self#max_col - self#min_col in
        if num_cols = 0 then 0 else num_cols + 1
    
    (** misc. predicates *)
    
    method has_data =
        not (self#min_row = self#max_row)
    
    (** row accessing and processing functions *)
    
    method get_row_at i = 
        if i > self#max_row then 
            raise (Error "Index out of bounds")
        else
            let row = PoCaml.Array.get (self#get_rows_as_array) i in
            self#clean_row row

    method map_rows : 'a . (string list -> 'a) -> 'a list =
        fun f -> 
            PoCaml.Array.map 
                (fun row -> f (self#clean_row row)) 
                self#get_rows_as_array
    
    method iter_rows (f : string list -> unit) =
        let row = self#get_rows_as_array in
        for i = 0 to PoCaml.Array.length row - 1 do
            f (self#clean_row (PoCaml.Array.get row i));
        done;

    method extract_rectangle ~top ~left ~bottom ~right () =
        if top    > self#max_row or 
           left   > self#max_col or
           bottom > self#max_row or
           right  > self#max_col then
            raise (Error "coordinates out of bounds") 
        else         
            let rec collect_cols i row acc =
                if i < left then 
                    acc
                else 
                    collect_cols (i-1) row ((self#clean_value (PoCaml.Array.get row i))::acc)
            in
            let result = ref [] in
            let rows = self#get_rows_as_array in
            for i = top to bottom do
                let row = av_of_ref (PoCaml.Array.get rows i) in
                result := (collect_cols right row []) :: !result
            done;        
            List.rev !result

end

class workbook sv =
object (self)

    (** public methods *)
    
    (** property accessors *)
    
    method filename = 
        string_of_sv (fetch_hash_key_from_obj sv "File")
        
    method file_author = 
        string_of_sv (fetch_hash_key_from_obj sv "Author")        

    (** worksheet accessors *)

    method worksheets = 
        PoCaml.Array.map 
            (fun s -> new worksheet s)
            (av_of_ref (fetch_hash_key_from_obj sv "Worksheet"))        

    method find_worksheet_by_name name =
        new worksheet (call_method_in_scalar sv "Worksheet" [ (sv_of_string name) ])

end

(** constructor *)
let load_file filename =
    let w = call_method_in_scalar
                (call_class_method_in_scalar "Spreadsheet::ParseExcel" "new" [])
                "Parse" 
                [ (sv_of_string filename) ] 
    in
    if sv_is_undef w then
        raise (Error ("Cannot read Excel file: " ^ filename))
    else 
        new workbook w 


