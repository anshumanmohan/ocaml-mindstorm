(* File: solver.ml

   Copyright (C) 2008

     Julie de Pril <julie_87@users.sourceforge.net>

     Christophe Troestler <chris_77@users.sourceforge.net>
     WWW: http://math.umh.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 2.1 or
   later as published by the Free Software Foundation, with the special
   exception on linking described in the file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. *)


(** Functor using a [Phase] module to develop some strategies to find a
    sequence of moves to get into a goal state. *)
module Make(P:
  sig
    type t
    module Move : Rubik.MoveT
    val compare : t -> t -> int
    val max_moves : int
    val initialize_mul : ?file:string -> unit -> (t -> Move.t -> t)
    val initialize_pruning : ?file:string -> (t -> Move.t -> t) ->  (t -> int)
  end) =
struct

  open Rubik

  module PQ = Priority_queue

  let mul = P.initialize_mul()
  let prun = P.initialize_pruning mul

  (** [search_seq_to_goal p in_goal] returns a list of moves that lead
      to the a permutation [q] (such that [in_goal q] is true) from
      the permutation [p]. *)
  let search_seq_to_goal first is_in_goal =
    (* No sequence of moves found, so exit with error *)
    let no_seq() = exit 2 in
    (* [get_children p] returns the "children" of the permutation [p] (ie all
       the permutations we can reach by applying a single move to [p]) with
       the associated move. *)
    let get_children p = List.map (fun move -> (mul p move, move)) P.Move.all in
    (* [aStar] recursively searches a sequence of moves to get into the goal
       state. (A* algorithm) *)
    let rec aStar opened =
      (* [opened] is the set of all pending candidates. *)
      if PQ.is_empty opened (* No more candidates. *) then no_seq()
      else
        let (p,seq,pcost) = PQ.take opened in
        if is_in_goal p (* Get into the goal state! *) then List.rev seq
        else begin
          let children = get_children p in
          (* We update the set [opened] with the children of [p]. *)
          let opened =
            List.fold_left begin fun opened (child,m) ->
              let fchild = pcost+1 + prun child in
              if fchild <= P.max_moves then (* The path is not too long. *)
                let c = (child, m::seq, pcost+1) in
                PQ.add fchild c opened;
                opened
              else opened
            end
              opened children
          in
          aStar opened
        end
    in
    let start = (first,[],0) in
    let opened = PQ.make (P.max_moves+1) in
    PQ.add (prun first) start opened;
    aStar opened

end

module Solver1 = Make(Rubik.Phase1)
module Solver2 = Make(Rubik.Phase2)
open Rubik
open Printf

let genP1 m = Phase1.Move.generator m
let genP2 m = Phase2.Move.generator m

let print_move (g,i) =
  let print_gen g = Printf.printf "Move: %s , %i \n%!" g i in
  match g with
  | F -> print_gen "F"
  | B -> print_gen "B"
  | L -> print_gen "L"
  | R -> print_gen "R"
  | U -> print_gen "U"
  | D -> print_gen "D"

let rec print gen s = List.iter (fun m -> print_move (gen m)) s

let () =
  let moves = [F,3; R,2; U,1; B,3; D,1; L,2; R,3; U,2; F,2; B,1; L,3; F,1;
               R,1; U,3; B,1; D,2; L,3; B,2] in
  let moves = List.map (fun m -> Cubie.move (Move.make m)) moves in
  let cube = List.fold_left Cubie.mul Cubie.id moves in
  let cubeP1 = Phase1.of_cube cube in
  let seq1 = Solver1.search_seq_to_goal cubeP1 Phase1.in_G1 in
  Printf.printf "Sequence phase 1: \n%!";
  print genP1 seq1;
 (* let module Motor = Mindstorm.Motor in
  let conn = let bt =
    if Array.length Sys.argv < 2 then (
      printf "%s <bluetooth addr>\n" Sys.argv.(0);
      exit 1;
    )
    else Sys.argv.(1) in Mindstorm.connect_bluetooth bt in
  let module C =
  struct
    let conn = conn
    let motor_fighter = Motor.a
    let motor_hand = Motor.b
    let motor_pf = Motor.c
    let push_hand_port = `S2
    let push_fighter_port = `S1
    let cog_is_set_left = true
  end in
  let module M = Translator.Make(C) in
  List.iter M.make (List.map Phase1.Move.generator seq1);*)
  let cube2 =
    List.fold_left (fun c m -> Cubie.mul c (Cubie.move m)) cube seq1 in
  Gc.major();
  let cubeP2 = Phase2.of_cube cube2 in
  Printf.printf "Sequence phase 2: \n%!";
  let seq2 = Solver2.search_seq_to_goal cubeP2 Phase2.is_identity in
  print genP2 seq2;
  let goal =
    List.fold_left (fun c m -> Cubie.mul c (Phase2.Move.move m)) cube2 seq2 in
  if Cubie.is_identity goal then Printf.printf "Wouhouuu!! \n%!"




