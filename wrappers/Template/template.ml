
open PoCaml.Scalar
open PoCaml.Ref
open PoCaml.Code
open PoCaml.Utils

exception Error of string

let init () = ignore(PoCaml.Env.eval "use Template")

class template sv =
object (self)

    method process file (vars : PoCaml.Utils.variant) =
        let output = sv_of_string "" in
        let args = [ 
            sv_of_string file; 
            perl_of_variant vars; 
            ref_of_sv output;
        ] in
        let result = call_method_in_scalar sv "process" args in
        if not (sv_is_true result) then
            raise (Error self#error)
        else
            string_of_sv output

    method error =
        string_of_sv (call_method_in_scalar sv "error" [])

end

let new_template 
    ?start_tag ?end_tag ?tag_style ?pre_chomp ?post_chomp ?trim
    ?interpolate ?anycase ?include_path ?delimiter ?absolute ?relative
    ?default ?blocks ?auto_reset ?recursion ?variables ?constants
    ?constant_namespace ?namespace ?pre_process ?post_process ?process
    ?wrapper ?error ?errors ?eval_perl ?debug ?debug_format ?cache_size 
    ?compile_ext ?compile_dir ?plugins ?plugin_base ?load_perl ?v1dollar 
    ?tolerant () =

    let args = ref [] in

    let may f = function 
        | None   -> () 
        | Some v -> let (k, v) = (f v) in
                    args := sv_of_string k :: v :: !args;
                    ()
    in
    
    let av_of_string_list list =
        PoCaml.Array.create 
            ~with_list:(List.map (sv_of_string) list) ()
    in
    
    let hv_of_string_pair_list pairs =
        PoCaml.Hash.create 
            ~with_assoc:(List.map (fun (k, v) -> k, (sv_of_string v)) pairs) ()
    in

    may (fun v -> "START_TAG"          ,(sv_of_string    v)) start_tag;
    may (fun v -> "END_TAG"            ,(sv_of_string    v)) end_tag;
    may (fun v -> "TAG_STYLE"          ,(sv_of_string    v)) tag_style;
    may (fun v -> "PRE_CHOMP"          ,(sv_of_bool      v)) pre_chomp;
    may (fun v -> "POST_CHOMP"         ,(sv_of_bool      v)) post_chomp;
    may (fun v -> "TRIM"               ,(sv_of_bool      v)) trim;
    may (fun v -> "INTERPOLATE"        ,(sv_of_bool      v)) interpolate;
    may (fun v -> "ANYCASE"            ,(sv_of_bool      v)) anycase;
    may (fun v -> "DELIMITER"          ,(sv_of_string    v)) delimiter;
    may (fun v -> "ABSOLUTE"           ,(sv_of_bool      v)) absolute;
    may (fun v -> "RELATIVE"           ,(sv_of_bool      v)) relative;
    may (fun v -> "DEFAULT"            ,(sv_of_string    v)) default;
    may (fun v -> "AUTO_RESET"         ,(sv_of_bool      v)) auto_reset;
    may (fun v -> "RECURSION"          ,(sv_of_bool      v)) recursion;
    may (fun v -> "VARIABLES"          ,(perl_of_variant v)) variables;
    may (fun v -> "CONSTANTS"          ,(perl_of_variant v)) constants;
    may (fun v -> "CONSTANT_NAMESPACE" ,(sv_of_string    v)) constant_namespace;
    may (fun v -> "NAMESPACE"          ,(perl_of_variant v)) namespace;
    may (fun v -> "ERROR"              ,(sv_of_string    v)) error;            
    may (fun v -> "EVAL_PERL"          ,(sv_of_bool      v)) eval_perl;
    may (fun v -> "DEBUG"              ,(sv_of_string    v)) debug;
    may (fun v -> "DEBUG_FORMAT"       ,(sv_of_string    v)) debug_format;
    may (fun v -> "CACHE_SIZE"         ,(sv_of_int       v)) cache_size;
    may (fun v -> "COMPILE_EXT"        ,(sv_of_string    v)) compile_ext;
    may (fun v -> "COMPILE_DIR"        ,(sv_of_string    v)) compile_dir;    
    may (fun v -> "LOAD_PERL"          ,(sv_of_bool      v)) load_perl;
    may (fun v -> "V1DOLLAR"           ,(sv_of_bool      v)) v1dollar;
    may (fun v -> "TOLERANT"           ,(sv_of_bool      v)) tolerant;
            
    may (fun v -> "INCLUDE_PATH" ,(ref_of_av (av_of_string_list      v))) include_path;            
    may (fun v -> "BLOCKS"       ,(ref_of_hv (hv_of_string_pair_list v))) blocks;            
    may (fun v -> "PRE_PROCESS"  ,(ref_of_av (av_of_string_list      v))) pre_process;
    may (fun v -> "POST_PROCESS" ,(ref_of_av (av_of_string_list      v))) post_process;
    may (fun v -> "PROCESS"      ,(ref_of_av (av_of_string_list      v))) process;
    may (fun v -> "WRAPPER"      ,(ref_of_av (av_of_string_list      v))) wrapper;
    may (fun v -> "ERRORS"       ,(ref_of_hv (hv_of_string_pair_list v))) errors;
    may (fun v -> "PLUGINS"      ,(ref_of_hv (hv_of_string_pair_list v))) plugins;
    may (fun v -> "PLUGIN_BASE"  ,(ref_of_av (av_of_string_list      v))) plugin_base;

    let sv = call_class_method_in_scalar "Template" "new" !args in
    new template sv
