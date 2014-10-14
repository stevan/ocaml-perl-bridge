#!/usr/local/bin/ocamlrun /usr/local/bin/ocaml

#use "topfind";;
#require "unix";;
#require "poCaml";;

open PoCaml.Scalar
open PoCaml.Code

exception Error of string

(** types *)

type alignment      = Top  | Middle | Bottom
type vert_alignment = Left | Right  | Center
           
type color = GreyScale of float
           | RGBColor  of float * float * float
           | CMYKColor of float * float * float * float

type style = Fill        of color
           | Stroke      of color
           | Fill_Stroke of color * color

(** point as in "unit of measurement", not cartisian *)
type point = float
type coord = Coord of point * point

type node = Circle   of coord * point         * style
          | Rect     of coord * point * point * style
          | Line     of coord * point * point * style
          | Compound of node list

type page = Page of node list

type document_info = { 
    filename    : string;
    page_height : point; 
    page_width  : point;
    buffer      : PoCaml.sv
}

type document = PDFDocument of document_info * page list

(** utility functions *)

let inch inches = 72.0 *. inches

(** initilize the library *)

let init () = ignore (PoCaml.Env.eval "use pdflib_pl;")

(** color functions *) 

let set_style pdf style = 
    let set_color style_string color =
        match color with 
            | GreyScale(grey) -> 
                call_in_void ~fn:"pdflib_pl::PDF_setcolor" [
                    pdf.buffer;
                    (sv_of_string style_string);
                    (sv_of_string "grey");  
                    (sv_of_float grey);
                    (sv_of_float 0.);
                    (sv_of_float 0.);
                    (sv_of_float 0.);                                                           
                ]
            | RGBColor(r, g, b) -> 
                call_in_void ~fn:"pdflib_pl::PDF_setcolor" [
                    pdf.buffer;
                    (sv_of_string style_string);
                    (sv_of_string "rgb");  
                    (sv_of_float r);
                    (sv_of_float g);
                    (sv_of_float b);
                    (sv_of_float 0.);                                                           
                ]        
            | CMYKColor(c, m, y, k) -> 
                call_in_void ~fn:"pdflib_pl::PDF_setcolor" [
                    pdf.buffer;
                    (sv_of_string style_string);
                    (sv_of_string "cmyk");    
                    (sv_of_float c);
                    (sv_of_float m);
                    (sv_of_float y);
                    (sv_of_float k);                                                           
                ]
    in 
    match style with
        | Fill(color)   -> set_color "fill" color
        | Stroke(color) -> set_color "stroke" color
        | Fill_Stroke(fill_color, stroke_color) -> 
            set_color "fill"   fill_color;
            set_color "stroke" stroke_color
    

let apply_style pdf = function  
    | Fill(_)        -> call_in_void ~fn:"pdflib_pl::PDF_fill"        [ pdf.buffer ]     
    | Stroke(_)      -> call_in_void ~fn:"pdflib_pl::PDF_stroke"      [ pdf.buffer ]    
    | Fill_Stroke(_) -> call_in_void ~fn:"pdflib_pl::PDF_fill_stroke" [ pdf.buffer ]    

(** node functions *)

let rec draw_node pdf node = 
    let x_coord x offset = 
        sv_of_float ((pdf.page_height -. x) -. offset)
    in
    let y_coord y = 
        sv_of_float y
    in   
    match node with 
        | Circle(Coord(x, y), r, style)  -> 
            (set_style pdf style);
        	(call_in_void ~fn:"pdflib_pl::PDF_circle" [
                pdf.buffer; 
                (y_coord (y +. r)); 
                (x_coord x r); 
                (sv_of_float r);                     
            ]);  
            (apply_style pdf style)        
        | Rect(Coord(x, y), height, width, style) -> 
            (set_style pdf style);
        	(call_in_void ~fn:"pdflib_pl::PDF_rect" [
                pdf.buffer; 
                (y_coord y); 
                (x_coord x height); 
                (sv_of_float width);            
                (sv_of_float height);                          
            ]);  
            (apply_style pdf style)
        | Line(Coord(x, y), width, weight, style) ->
            (set_style pdf style);
        	(call_in_void ~fn:"pdflib_pl::PDF_rect" [
                pdf.buffer; 
                (y_coord y); 
                (x_coord x weight);
                (sv_of_float width);            
                (sv_of_float weight);                          
            ]);  
            (apply_style pdf style);
        | Compound(nodes) -> 
            List.iter (
                fun node -> 
                    call_in_void ~fn:"pdflib_pl::PDF_save" [ pdf.buffer ];
                    draw_node pdf node;
                    call_in_void ~fn:"pdflib_pl::PDF_restore" [ pdf.buffer ];            
            ) nodes

(** page functions *)

let open_page pdf = 
    call_in_void ~fn:"pdflib_pl::PDF_begin_page" [
	    pdf.buffer; 
	    (sv_of_float pdf.page_width);
	    (sv_of_float pdf.page_height);
    ]

let close_page pdf =
    call_in_void ~fn:"pdflib_pl::PDF_end_page" [ pdf.buffer ] 

let draw_page pdf = function Page(nodes) ->
    List.iter (
        fun node -> 
            call_in_void ~fn:"pdflib_pl::PDF_save" [ pdf.buffer ];
            draw_node pdf node;
            call_in_void ~fn:"pdflib_pl::PDF_restore" [ pdf.buffer ];            
    ) nodes

(** document functions *)

let create_buffer () = call_in_scalar ~fn:"pdflib_pl::PDF_new" []

let open_document pdf = 
    let rv = call_in_scalar ~fn:"pdflib_pl::PDF_open_file" [
        pdf.buffer; 
        (sv_of_string pdf.filename);
    ] in if (int_of_sv rv) = -1 then 
        raise (Error ("Could not open PDF file (" ^ pdf.filename ^ ")"))
    else
        ()

let close_document pdf =
    call_in_void ~fn:"pdflib_pl::PDF_close" [ pdf.buffer ]

let write_document doc = 
    let PDFDocument(pdf, pages) = doc in
    open_document pdf;
    List.iter (
        fun page -> 
            open_page pdf;
            draw_page pdf page;
            close_page pdf;        
    ) pages;
    close_document pdf     

(** test *)

let _ = 
    init();
    let test_file = "/Users/stevan/Desktop/test.pdf" in
    let pdf = PDFDocument(
        { 
            filename    = test_file;
            page_height = inch(11.);
            page_width  = inch(8.5);
            buffer      = create_buffer ();            
        },
        [
            Page([
                Compound(
                    List.map 
                    (fun x -> 
                        Rect(
                            Coord((x *. 10.), (x *. 10.)),
                            (x *. 20.), (x *. 20.),
                            Fill_Stroke(
                                RGBColor(1., (x /. 10.), 0.),
                                RGBColor(0., 0., 0.)                            
                            )
                        ))
                     [ 1.; 2.; 3.; 4.; 5.; 6.; 7.; 8.; 9.; 10.; ]
                 );
                 Line(
                     Coord(inch(3.), inch(3.)),
                     200., 2.,
                     Fill(RGBColor(0.5, 0.5, 0.5))                
                 );                 
            ]);
            Page([
                Rect(
                    Coord(inch(1.), inch(1.)),
                    10., 10.,
                    Fill(RGBColor(0.5, 0.5, 0.5))
                )
            ]);            
        ]
    ) in 
    (try Unix.unlink test_file with _ -> ());  
    write_document pdf;        
;;







