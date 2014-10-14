
type sv
type av
type hv

exception Perl_exception of string

(* ---------------------------------------------------------------
 *  Initialization
 * ---------------------------------------------------------------
 * This must happen first, otherwise other parts of the
 * program will segfault because of a missing interpreter.
 *)

external c_init : unit -> unit = "pocaml_init"

let () =
  Callback.register_exception "pocaml_perl_failure" (Perl_exception "");
  c_init ();				(* Initialise C code. *)
  ()

(** 
    These modules are suitable for opening:
    
        PoCaml.Scalar
        PoCaml.Ref
        PoCaml.Code
        PoCaml.Env  
        PoCaml.Utils                     
    
    These modules are /not/ suitable for opening  
    
        PoCaml.Array
        PoCaml.Hash
**)

(** Functions for Scalars *)

module Scalar =
struct

    type sv_t = SVt_NULL
              | SVt_IV
    	      | SVt_NV
    	      | SVt_PV
    	      | SVt_RV
    	      | SVt_PVAV
    	      | SVt_PVHV
    	      | SVt_PVCV
    	      | SVt_PVGV
    	      | SVt_PVMG
    	      
    (** SV type functions *)
    external sv_type : sv -> sv_t = "pocaml_sv_type"

    let string_of_sv_t = function
        | SVt_NULL  -> "SVt_NULL"
        | SVt_IV    -> "SVt_IV"
        | SVt_NV    -> "SVt_NV"
        | SVt_PV    -> "SVt_PV"
        | SVt_RV    -> "SVt_RV"
        | SVt_PVAV  -> "SVt_PVAV"
        | SVt_PVHV  -> "SVt_PVHV"
        | SVt_PVCV  -> "SVt_PVCV"
        | SVt_PVGV  -> "SVt_PVGV"
        | SVt_PVMG  -> "SVt_PVMG"

    let name_of_sv_t = function
        | SVt_NULL  -> "UNDEF"
        | SVt_IV    -> "INT"
        | SVt_NV    -> "FLOAT"
        | SVt_PV    -> "STRING"
        | SVt_RV    -> "REF"
        | SVt_PVAV  -> "ARRAY"
        | SVt_PVHV  -> "HASH"
        | SVt_PVCV  -> "CODE"
        | SVt_PVGV  -> "GLOB"
        | SVt_PVMG  -> "MAGIC"    	      

    (** Unit <-> SV *)
    external sv_undef     : unit   -> sv     = "pocaml_sv_undef"
    external sv_is_undef  : sv     -> bool   = "pocaml_sv_is_undef"

    (** Int <-> SV *)
    external int_of_sv    : sv     -> int    = "pocaml_int_of_sv"
    external sv_of_int    : int    -> sv     = "pocaml_sv_of_int"

    (** Float <-> SV *)
    external float_of_sv  : sv     -> float  = "pocaml_float_of_sv"
    external sv_of_float  : float  -> sv     = "pocaml_sv_of_float"

    (** String <-> SV *)
    external string_of_sv : sv     -> string = "pocaml_string_of_sv"
    external sv_of_string : string -> sv     = "pocaml_sv_of_string"

    (** Bool <-> SV *)
    external sv_is_true   : sv     -> bool   = "pocaml_sv_is_true"

    let bool_of_sv   = sv_is_true
    let sv_true ()   = sv_of_int 1
    let sv_false ()  = sv_of_int 0
    let sv_of_bool b = if b then sv_true () else sv_false ()

end

(** Functions for references *)

module Ref =
struct

    external ref_of_sv : sv -> sv = "pocaml_scalarref"
    external ref_of_av : av -> sv = "pocaml_arrayref"
    external ref_of_hv : hv -> sv = "pocaml_hashref"

    external sv_of_ref : sv -> sv = "pocaml_deref"
    external av_of_ref : sv -> av = "pocaml_deref_array"
    external hv_of_ref : sv -> hv = "pocaml_deref_hash"

    (* returns an sv_t corresponding to the type
       of reference or throws an execption *)
    let reftype sv =
        if Scalar.sv_type sv <> Scalar.SVt_RV then
            raise (Perl_exception "Not a ref type")
        else
            try  Scalar.sv_type (sv_of_ref sv)
            with Invalid_argument(_) ->
                try  ignore(av_of_ref sv); Scalar.SVt_PVAV
                with Invalid_argument(_) ->
                    try  ignore(hv_of_ref sv); Scalar.SVt_PVHV
                    with Invalid_argument(_) ->
                         raise (Perl_exception "Unknown ref type")

    let string_of_reftype sv = Scalar.string_of_sv_t (reftype sv)
    let name_of_reftype   sv = Scalar.name_of_sv_t   (reftype sv)

end

(** Functions for CVs *)

module Code =
struct

    external call_in_scalar : ?sv:sv -> ?fn:string -> sv list -> sv      = "pocaml_call"
    external call_in_array  : ?sv:sv -> ?fn:string -> sv list -> sv list = "pocaml_call_array"
    external call_in_void   : ?sv:sv -> ?fn:string -> sv list -> unit    = "pocaml_call_void"

    external call_method_in_scalar : sv -> string -> sv list -> sv      = "pocaml_call_method"
    external call_method_in_array  : sv -> string -> sv list -> sv list = "pocaml_call_method_array"
    external call_method_in_void   : sv -> string -> sv list -> unit    = "pocaml_call_method_void"

    external call_class_method_in_scalar : string -> string -> sv list -> sv      = "pocaml_call_class_method"
    external call_class_method_in_array  : string -> string -> sv list -> sv list = "pocaml_call_class_method_array"
    external call_class_method_in_void   : string -> string -> sv list -> unit    = "pocaml_call_class_method_void"

end

(** Functions for calling into the Perl interpreter *)

module Env =
struct

    external get_sv : ?create:bool -> string -> sv = "pocaml_get_sv"
    external get_av : ?create:bool -> string -> av = "pocaml_get_av"
    external get_hv : ?create:bool -> string -> hv = "pocaml_get_hv"

    external eval : string -> sv = "pocaml_eval"

end

(** Functions for AVs *)

module Array =
struct

    external create_empty : unit    -> av = "pocaml_av_empty"
    external from_list    : sv list -> av = "pocaml_av_of_sv_list"

    let create ?with_list () =
        match with_list with
            | None     -> create_empty ()
            | Some(xs) -> from_list xs

    external push    : av -> sv -> unit        = "pocaml_av_push"
    external pop     : av -> sv                = "pocaml_av_pop"
    external shift   : av -> sv                = "pocaml_av_shift"
    external unshift : av -> sv -> unit        = "pocaml_av_unshift"
    external length  : av -> int               = "pocaml_av_length"
    external set     : av -> int -> sv -> unit = "pocaml_av_set"
    external get     : av -> int -> sv         = "pocaml_av_get"
    external clear   : av -> unit              = "pocaml_av_clear"
    external undef   : av -> unit              = "pocaml_av_undef"
    external extend  : av -> int -> unit       = "pocaml_av_extend"

    let to_list av =
        let list = ref [] in
        for i = 0 to length av - 1 do
            list := get av i :: !list
        done;
        List.rev !list

    let map  f av = List.map    f (to_list av)
    let grep f av = List.filter f (to_list av)        

end

(** Functions for HVs *)

module Hash =
struct

    external create_empty : unit -> hv = "pocaml_hv_empty"
    external set : hv -> string -> sv -> unit = "pocaml_hv_set"

    let from_assoc xs =
        let hv = create_empty () in
        List.iter (fun (k, v) -> set hv k v) xs;
        hv

    let create ?with_assoc () =
        match with_assoc with
            | None     -> create_empty ()
            | Some(xs) -> from_assoc xs

    external get    : hv   -> string -> sv   = "pocaml_hv_get"
    external exists : hv   -> string -> bool = "pocaml_hv_exists"
    external delete : hv   -> string -> unit = "pocaml_hv_delete"
    external clear  : hv   -> unit           = "pocaml_hv_clear"
    external undef  : hv   -> unit           = "pocaml_hv_undef"

    module Iter =
    struct
        type he

        external init   : hv -> Int32.t     = "pocaml_hv_iterinit"
        external next   : hv -> he          = "pocaml_hv_iternext"
        external key    : he -> string      = "pocaml_hv_iterkey"
        external value  : hv -> he -> sv    = "pocaml_hv_iterval"
        external nextsv : hv -> string * sv = "pocaml_hv_iternextsv"
    end

    let to_assoc hv =
        ignore (Iter.init hv);
        let rec loop acc =
            try
                let k, v = Iter.nextsv hv in
                loop ((k, v) :: acc)
            with
                Not_found -> acc
        in loop []

    let keys hv =
        ignore (Iter.init hv);
        let rec loop acc =
            try
                let he = Iter.next hv in
                let k  = Iter.key he in
                loop (k :: acc)
            with
                Not_found -> acc
        in loop []

    let values hv =
        ignore (Iter.init hv);
        let rec loop acc =
            try
                let he = Iter.next hv in
                let v  = Iter.value hv he in
                loop (v :: acc)
            with
                Not_found -> acc
        in loop []

end

(* A polymorphic variant type to represent Perl values 
   in a more Ocaml-ish way, along with functions for 
   converting between representations *)

module Utils =
struct

    exception Cannot_convert of string

    type variant = [ `Null
                   | `String of string
                   | `Int    of int
                   | `Float  of float
                   | `Bool   of bool
                   | `Array  of variant list
                   | `Hash   of (string * variant) list       
                   ]

     (** Perl <-> Variant *)

     let rec perl_of_variant = function
         | `Null      -> Scalar.sv_undef ()
         | `String s  -> Scalar.sv_of_string s
         | `Int i     -> Scalar.sv_of_int i
         | `Float f   -> Scalar.sv_of_float f
         | `Bool b    -> Scalar.sv_of_bool b
         | `Array xs  -> Ref.ref_of_av 
                            (Array.from_list (List.map perl_of_variant xs))
         | `Hash xs   -> Ref.ref_of_hv
             (let hv = Hash.create_empty () in
                List.iter (fun (k, v) -> Hash.set hv k (perl_of_variant v)) xs;
                hv)

     let rec variant_of_perl x = 
         let is_scalar_ref s_ref = 
             try  ignore(Ref.sv_of_ref(s_ref)); true
             with Invalid_argument(_) -> false
         in
         let reftype s = 
             try  ignore(Ref.av_of_ref s); Scalar.SVt_PVAV
             with Invalid_argument(_) -> 
                 try  ignore(Ref.hv_of_ref s); Scalar.SVt_PVHV
                 with Invalid_argument(_) -> raise (Cannot_convert "Cannot convert unknown reftype")                           
         in
         let rec loop sv_type = 
             match sv_type with
                 | Scalar.SVt_NULL -> `Null
                 | Scalar.SVt_IV   -> `Int(Scalar.int_of_sv x)
                 | Scalar.SVt_NV   -> `Float(Scalar.float_of_sv x)
                 | Scalar.SVt_PV   -> `String(Scalar.string_of_sv x)    
                 | Scalar.SVt_PVAV -> `Array(Array.map variant_of_perl (Ref.av_of_ref x))
                 | Scalar.SVt_PVHV -> `Hash(List.map 
                                             (fun (k,v) -> (k, (variant_of_perl v))) 
                                             (Hash.to_assoc (Ref.hv_of_ref x)))            
                 | Scalar.SVt_RV 
                     when is_scalar_ref(x)
                                 -> variant_of_perl (Ref.sv_of_ref x)
                 | Scalar.SVt_RV   -> loop (reftype x)
                 | Scalar.SVt_PVMG -> raise (Cannot_convert "Cannot convert magic value")    
                 | Scalar.SVt_PVGV -> raise (Cannot_convert "Cannot convert Glob (possibly a file handle)")      
                 | Scalar.SVt_PVCV -> raise (Cannot_convert "Cannot convert Code value")        
         in loop (Scalar.sv_type x)

end





