open Alphabetamem
open Board

let bt_pincer = ref "00:16:53:0C:84:49"
and bt_scan = ref "00:16:53:0A:F3:3C"
and if_computer = ref true

let spec = Arg.align ["--pince", Arg.Set_string bt_pincer,
                      "<bt_address>set the bluetooth address of the brick
which uses the pincer";
                      "--scan", Arg.Set_string bt_scan,
                      "<bt_address>set the bluetooth address of the brick
which uses the scan";
                      "--human_first", Arg.Clear if_computer,
                      " set first player"]
let () = Arg.parse spec (fun _ -> raise (Arg.Bad "no anonymous arg"))
  "run_connect4 <option>"

module Conn =
struct
  let r = Robot.make()
  let conn_pincer, conn_scan, fst_computer =
    Mindstorm.connect_bluetooth !bt_pincer,
    Mindstorm.connect_bluetooth !bt_scan,
    !if_computer
end

module P = Pincer.Run(Conn)
module S = ScanPiece2.Run(Conn)

(*si fst_player est vrai, ca veut dire que c'est a l'ordi de commencer,
  on lance donc alphabeta puis la pince et enfin le scan*)
let rec step game col =
  if col <> -1 then
    (
        Gamemem.makemove game col;
        Board.add_piece_to_board Graphics.red col
    );
  (*on verifie que le jeu n'est pas gagn� ou match nul*)
  if (col <> -1) &&
    (Gamemem.get_game_result game = Gamemem.WIN || Gamemem.draw game)
  then
    (
      if Gamemem.draw game then Board.draw()
      else Board.red_success();
      S.return_init_pos Board.close_when_clicked
    )

  else
    (
      (*on cherche la colonne a jouer*)
      Board.write_player_turn Graphics.yellow;
      let v, col_to_play = Alphabetamem.alphabeta game 9 Gamemem.groupeval in
      Gamemem.makemove game col_to_play;
      Printf.printf "%s%f%s%!" "Valeur du jeu : " v "\n";
      Board.add_piece_to_board Graphics.yellow col_to_play;
      (*la pince va mettre la piece dans la colonne a jouer
        et on va scanner pour voir si le joueur a joue*)
      if Gamemem.get_game_result game = Gamemem.WIN || Gamemem.draw game
      then
        (
          Printf.printf"c fini, on stoppe apr�s avoir ajoute la piece\n%!";
          if Gamemem.draw game then Board.draw()
          else Board.yellow_success();
          Printf.printf"LE ROBOT GAGNE\n%!";
          P.put_piece col_to_play
            (fun () -> S.return_init_pos Board.close_when_clicked)
        )
      else
        (
          Board.write_player_turn Graphics.red;
          P.put_piece col_to_play
            (fun () -> S.scan col_to_play (fun c -> step game c))
        )
    )

let () =
  Board.gameboard ();
  let game = Gamemem.make_board() in
  Gamemem.initboard game;
  if Conn.fst_computer then step game (-1)
  else S.scan (-1) (fun c -> step game c);
  Robot.run Conn.r
