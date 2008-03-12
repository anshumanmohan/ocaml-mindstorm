(* File: display_base.ml

   Copyright (C) 2008

     Christophe Troestler <Christophe.Troestler@umh.ac.be>
     WWW: http://math.umh.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 2.1 or
   later as published by the Free Software Foundation, with the special
   exception on linking described in the file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. *)

open Printf
open Rubik

let int_of_face = function
  | F -> 0 | B -> 1 | L -> 2 | R -> 3 | U -> 4 | D -> 5

type color = int

let rgb r g b = (r lsl 16) lor (g lsl 8) lor b
let get_rgb c = ((c lsr 16) land 0xFF, (c lsr 8) land 0xFF, c land 0xFF)

(** Geometric information to draw the cube *)
type geom = {
  xy0 : float * float;
  width : float;
  height : float;
  angle : int;
  color_F : color;
  color_B : color;
  color_L : color;
  color_R : color;
  color_U : color;
  color_D : color;
  color_lines : color;
}

let geom = {
  xy0 = (0.,0.);
  width = 30.;
  height = 30.;
  angle = 45;
  color_F = rgb 255 255 255;            (* white *)
  color_B = rgb 248 242 84;             (* yellow *)
  color_L = rgb 0 213 106;              (* green *)
  color_R = rgb 0 25 211;               (* blue *)
  color_U = rgb 255 139 20;             (* orange *)
  color_D = rgb 236 29 64;              (* red *)
  color_lines = rgb 0 0 0;
}

type facelets_color = generator array
  (* To each face letter [f], we associate a color.  After
     permutation, the color of the facelet [j] of face [f] is given by
     the color associated to the face [colors.(9 * int_of_face f +
     j)].  The facelets are numbered according to the scheme:

     -------------
     | 0 | 1 | 2 |
     -------------
     | 3 | 4 | 5 |
     -------------
     | 6 | 7 | 8 |
     -------------

     (the center facelet does not move so always receives the color
     associated to the face).  *)

(** Return an facelets color array whose center facelets are set (they
    do not move) and all other are arbotrarily initialized. *)
let make_facelets_color () =
  let colors = Array.make 54 F in
  (* Set the other 5 center facelets *)
  colors.(9 + 4) <- B;
  colors.(18 + 4) <- L;
  colors.(27 + 4) <- R;
  colors.(36 + 4) <- U;
  colors.(45 + 4) <- D;
  colors
;;

(* Conversion from a Cubie representation
 ***********************************************************************)

(** Return the 3 facelets of a corner, the first being the reference
    face and the subsequent ones being given CW. *)
let facelets_of_corner = function
  | Cubie.URF -> [| (U,8); (R,0); (F,2) |]
  | Cubie.UFL -> [| (U,6); (F,0); (L,2) |]
  | Cubie.ULB -> [| (U,0); (L,0); (B,2) |]
  | Cubie.UBR -> [| (U,2); (B,0); (R,2) |]
  | Cubie.DFR -> [| (D,2); (F,8); (R,6) |]
  | Cubie.DLF -> [| (D,0); (L,8); (F,6) |]
  | Cubie.DBL -> [| (D,6); (B,8); (L,6) |]
  | Cubie.DRB -> [| (D,8); (R,8); (B,6) |]

let corner_list =
  [ Cubie.URF; Cubie.UFL; Cubie.ULB; Cubie.UBR;
    Cubie.DFR; Cubie.DLF; Cubie.DBL; Cubie.DRB ]

(** Return the 2 facelets of an edge, the reference facelet being
    first.  *)
let facelets_of_edge = function
  | Cubie.UR -> [| (U,5); (R,1) |]
  | Cubie.UF -> [| (U,7); (F,1) |]
  | Cubie.UL -> [| (U,3); (L,1) |]
  | Cubie.UB -> [| (U,1); (B,1) |]
  | Cubie.DR -> [| (D,5); (R,7) |]
  | Cubie.DF -> [| (D,1); (F,7) |]
  | Cubie.DL -> [| (D,3); (L,7) |]
  | Cubie.DB -> [| (D,7); (B,7) |]
  | Cubie.FR -> [| (F,5); (R,3) |]
  | Cubie.FL -> [| (F,3); (L,5) |]
  | Cubie.BL -> [| (B,5); (L,3) |]
  | Cubie.BR -> [| (B,3); (R,5) |]

let edge_list =
  [ Cubie.UR; Cubie.UF; Cubie.UL; Cubie.UB;
    Cubie.DR; Cubie.DF; Cubie.DL; Cubie.DB;
    Cubie.FR; Cubie.FL; Cubie.BL; Cubie.BR ]


(** Return a color matrix (such as described for the type [geom]) for
    a given [cube]. *)
let colors_of_cube cube =
  let colors = make_facelets_color() in
  let set_color (f, j) v = colors.(9 * int_of_face f + j) <- v in
  List.iter begin fun c ->
    let (c', o') = Cubie.corner cube c in
    let facelets = facelets_of_corner c
    and facelets' = facelets_of_corner c' in
    for i = 0 to 2 do
      set_color (facelets.((i + o') mod 3)) (fst(facelets'.(i)))
    done
  end corner_list;
  List.iter begin fun e ->
    let (e', o') = Cubie.edge cube e in
    let facelets = facelets_of_edge e
    and facelets' = facelets_of_edge e' in
    for i = 0 to 1 do
      set_color (facelets.((i + o') mod 2)) (fst(facelets'.(i)))
    done
  end edge_list;
  colors

let pi = 4. *. atan 1.

(* Operations on 2-dim vector space *)
let ( +! ) (x1,y1) (x2,y2) = (x1 +. x2, y1 +. y2)
let ( *! ) a (x,y) = (a *. x, a *. y)

(* Draw a cube given in the facelets color form. *)
let draw_cube_colors ~fill_poly ?(geom=geom) (colors: facelets_color) =
  let a = float geom.angle *. pi /. 180. in
  let e1 = (geom.width, 0.)
  and e3 = (0., geom.height)
  and e2 = (geom.width *. cos a, geom.width *. sin a) in
  let draw_face f =
    let dxy, v1, v2 = match f with
      | F -> 3. *! e1 +! 3. *! e3,              e1, e3
      | B -> 6. *! e1 +! 3. *! e3 +! 3. *! e2,  e1, e3
      | L -> 3. *! e3,                          e1, e3
      | R -> 6. *! e1 +! 3. *! e3,              e2, e3
      | U -> 3. *! e1 +! 6. *! e3,              e1, e2
      | D -> 3. *! e1,                          e1, e3  in
    let xy0 = geom.xy0 +! dxy in
    for i = 0 to 2 do
      for j = 0 to 2 do
        let xy = xy0 +! float i *! v1 +! float j *! v2 in
        let poly = [| xy;  xy +! v1;  xy +! v1 +! v2;  xy +! v2 |] in
        fill_poly f poly
      done
    done
  in
  generator_iter draw_face
;;

let round x = truncate(x +. 0.5) (* rounds a float *)

let color_of_face geom = function
  | F -> geom.color_F
  | B -> geom.color_B
  | L -> geom.color_L
  | R -> geom.color_R
  | U -> geom.color_U
  | D -> geom.color_D

let cube ?(geom=geom) cube =
  let fill_poly color poly =
    let poly = Array.map (fun (x,y) -> (round x, round y)) poly in
    Graphics.set_color (color_of_face geom color);
    Graphics.fill_poly poly;
    Graphics.set_color geom.color_lines;
    Graphics.draw_poly poly in
  draw_cube_colors ~fill_poly ~geom (colors_of_cube cube)


let texcolor_of_face = function
  | F -> "rubik-F"
  | B -> "rubik-B"
  | L -> "rubik-L"
  | R -> "rubik-R"
  | U -> "rubik-U"
  | D -> "rubik-D"

let cube_tikz fh ?(geom=geom) cube =
  let fill_poly color poly =
    let poly = Array.map (fun (x,y) -> sprintf "(%f,%f)" x y) poly in
    fprintf fh "\\draw[color=rubikline,fill=%s] %s -- cycle;\n"
      (texcolor_of_face color) (String.concat " -- " (Array.to_list poly));
  in
  (* Define the colors *)
  let r, g, b = get_rgb geom.color_lines in
  fprintf fh "\\definecolor{rubikline}{RGB}{%i,%i,%i}\n" r g b;
  generator_iter begin fun f ->
    let r, g, b = get_rgb (color_of_face geom f) in
    fprintf fh "\\definecolor{%s}{RGB}{%i,%i,%i}\n" (texcolor_of_face f) r g b;
  end;
  draw_cube_colors ~fill_poly ~geom (colors_of_cube cube)



(* Conversion to a Cubie representation
 ***********************************************************************)

(* Return the facelet (more precisely [Some (face, index)]) of a
   coordinate (x,y) according to the geometry of the figure of the
   cube.  Returns [None] is the point [(x,y)] is outside the cube
   figure. *)
let facelet_of_coord geom (x,y) =
  ()