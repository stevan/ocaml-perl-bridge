
open PoCaml.Scalar
open PoCaml.Code
open PoCaml.Utils

exception DBI_Error of string

let init () = ignore(PoCaml.Env.eval "use DBI")

let build_error ?dbh () =
    match dbh with
        | None    -> (DBI_Error (string_of_sv (PoCaml.Env.eval "$DBI::errstr")))
        | Some(d) -> (DBI_Error (string_of_sv (call_method_in_scalar d "errstr" [])))

class sth_wrapper sth = 
object (self)

    method execute ?(params : PoCaml.Utils.variant option) () = 
        ignore (
        match params with 
            | None    -> call_method_in_scalar sth "execute" []
            | Some(p) -> call_method_in_scalar sth "execute" [ (perl_of_variant p) ]
        ); ()
                    
    method fetch_row = 
        let results = call_method_in_scalar sth "fetchrow_arrayref" [] in
        variant_of_perl results  
    
    method map : 'a . (PoCaml.Utils.variant -> 'a) -> 'a list = 
        fun f -> 
            let rec loop acc =
                let results = self#fetch_row in
                match results with 
                    | `Null -> List.rev acc
                    | _     -> loop ((f results)::acc)
            in loop []

    method iter (f : PoCaml.Utils.variant -> unit) = 
        let rec loop () =
            let results = self#fetch_row in
            match results with 
                | `Null -> ()
                | _     -> (f results); loop ()
        in loop ()
    
    method finish =
        ignore(call_method_in_scalar sth "finish" [])
                         
end        

class dbh_wrapper dbh = 
object (self)

    method quote string =
        string_of_sv (call_method_in_scalar dbh "quote" [ (sv_of_string string) ])

    method ping = 
        let r = call_method_in_scalar dbh "ping" [] in
        sv_is_true r

    (** formerly &do, but thats an OCaml keyword *)
    method do_sql sql = 
        let rv = call_method_in_scalar dbh "do" [ (sv_of_string sql) ] in
        if sv_is_undef rv then
            raise (build_error ~dbh:dbh ())
        else 
            int_of_sv rv

    method select_row sql : PoCaml.Utils.variant =
        let results = call_method_in_scalar dbh "selectrow_arrayref" [ (sv_of_string sql) ] in
        if sv_is_undef results then
            raise (build_error ~dbh:dbh ())
        else            
            variant_of_perl results         
              
    method select_all sql : PoCaml.Utils.variant =
        let results = call_method_in_scalar dbh "selectall_arrayref" [ (sv_of_string sql) ] in
        if sv_is_undef results then
            raise (build_error ~dbh:dbh ())
        else            
            variant_of_perl results                  
              
    method prepare sql =
        let sth = call_method_in_scalar dbh "prepare" [ (sv_of_string sql) ] in
        if sv_is_true sth then
            new sth_wrapper sth
        else 
            raise (build_error ~dbh:dbh ())
    
    method disconnect =
        let rv = call_method_in_scalar dbh "disconnect" [] in
        if sv_is_undef rv then
            raise (build_error ~dbh:dbh ())
        else 
            ()
            
end    

let connect dsn username password =
    let dbh = call_class_method_in_scalar 
                "DBI" 
                "connect" 
                [ 
                  (sv_of_string dsn); 
                  (sv_of_string username); 
                  (sv_of_string password);
                  (perl_of_variant (`Hash [ 
                      ("PrintError", `Int 0);
                      ("RaiseError", `Int 1);                          
                  ])); 
                ] 
    in 
        if sv_is_true dbh then
            new dbh_wrapper dbh 
        else 
            raise (build_error ())


