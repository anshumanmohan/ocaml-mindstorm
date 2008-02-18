(* File : run.ml *)
open Printf

module Motor = Mindstorm.Motor

let conn = let bt =
  if Array.length Sys.argv < 2 then (
    printf "%s <bluetooth addr>\n" Sys.argv.(0);
    exit 1;
  )
  else Sys.argv.(1) in Mindstorm.connect_bluetooth bt

module C =
  struct
    let conn = conn
    let light_port = `S3
    let ultra_port = `S4
    let switch_port = `S2
    let motor_ultra = Motor.c
    let motor_left = Motor.a
    let motor_right = Motor.b

    module Labyrinth = Display.Make(Labyrinth)
  end

module Solver = Solver.Make(C)

let () =
  let rec solve () = Solver.follow_path look (Solver.next_case_to_explore())
  and look () = Solver.look_walls solve in
  Solver.look_wall_back look;
  Solver.run_loop()