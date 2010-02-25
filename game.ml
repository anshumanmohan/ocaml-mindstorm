(*un pion est rouge ou jaune, ou, dans le plateau, aucun pion*)
type piece = Red | Yellow | Empty

(*on peut etre soit un humain, soit un ordinateur*)
type player = Computer | Human

(*un acteur du jeu est un joueur avec une couleur qui lui correspond*)
type actor =
    {
      player : player;
      pion : piece;
      fst_player : bool
    }

(*un couple de la piece courrante, repr�sente une piece et le tableau
  repr�sentant les lignes dont la piece fait partie : horizontal, diagonal...*)
type couple_current_piece =
    {
      mutable current_piece : piece;
      mutable tab_line_piece : int array
    }

(*un evenement c'est l'endroit ou l'on place le pion et la couleur de celui-ci*)
(*attention raw et line d�marre a 0 pour les algos*)
type event =
    {
      col : int;
      line : int;
      piece : piece
    }

(*un jeu c'est un tableau repr�sentant l'�tat du jeu
  un autre tableau repr�sentant le pion et les lignes dont il fait parti
  et une liste des �v�nements plac�s du plus recents au plus vieux*)
type g =
    {
      mutable tab : piece array array;
      mutable tab_line : couple_current_piece array array;
      (*on aurait pu le mettre ac tab mais c pour calculer si on a gagn�
        sans l'arbre qu'on n'a pas encore impl�menter*)
      (*le tab int�rieur et de taille 4, repr�sente les 4 lignes
        : |, -, /, \ *)
      mutable list_event : event list;
      mutable number_of_move : int;
      mutable col_st : int array
    }

(*cr�ation d'un jeu -> on initialise le tableau a vide et la liste d'�v�nement
  est vide*)
let make () =
  {
    tab = Array.init 7 (fun i -> (Array.make 6 Empty));
    tab_line = Array.init 7
      (fun i -> Array.init 6
         (fun i -> {current_piece = Empty; tab_line_piece = Array.make 4 0}));
    list_event = [];
    number_of_move = 0;
    col_st = Array.make 7 0
  }
;;

(*r�cup�ration de la couleur (s'il y a ) du pion en i,j*)
let get_piece current_game j i =
  current_game.tab.(j).(i)
;;

exception Plein;;

(*l'acteur place le pion qui correspond a sa couleur dans la colonne j*)
let move current_game j actor =
  let i = current_game.col_st.(j) in (*i est le nombre de piece dans la
                                       colonne j*)

  if (i <> 6) then
    (
      current_game.col_st.(j) <- i + 1;
      current_game.tab.(j).(i) <- actor.pion;
      current_game.tab_line.(j).(i).current_piece <- actor.pion;
      current_game.number_of_move <- current_game.number_of_move + 1;
      (*on remplit le tab_line_piece du pion courant et on modifie
        les tab des pions de meme couleurs qui lui sont align�s*)
      (* pour la ligne verticale *)
      if (i != 0 && current_game.tab_line.(j).(i-1).current_piece = actor.pion)
      then
        (
          let down = current_game.tab_line.(j).(i-1).tab_line_piece.(0) in
          for k = 0 to down do
            current_game.tab_line.(j).(i-k).tab_line_piece.(0) <- down + 1;
          done
        )
      else current_game.tab_line.(j).(i).tab_line_piece.(0) <- 1;

      (*on r�cup�re les donn�es pour toutes les cases adjacentes sauf
        la verticale pour qui c'est d�j� fait juste au dessus*)
      let l = ref 0
      and r = ref 0
      and up_r = ref 0
      and down_l = ref 0
      and down_r = ref 0
      and up_l = ref 0 in

      if j>0
      then
        (
          if current_game.tab_line.(j-1).(i).current_piece = actor.pion
          then
            l := current_game.tab_line.(j-1).(i).tab_line_piece.(1);

          if(i>0 && current_game.tab_line.(j-1).(i-1).current_piece =
              actor.pion)
          then
            (down_l := current_game.tab_line.(j-1).(i-1).tab_line_piece.(2));

          if (i<5 && current_game.tab_line.(j-1).(i+1).current_piece =
              actor.pion)
          then
            (up_l := current_game.tab_line.(j-1).(i+1).tab_line_piece.(3));
        );

      if j<6
      then
        (
          if current_game.tab_line.(j+1).(i).current_piece = actor.pion
          then
            r := current_game.tab_line.(j+1).(i).tab_line_piece.(1);

          if (i<5 && current_game.tab_line.(j+1).(i+1).current_piece =
              actor.pion)
          then
            up_r := current_game.tab_line.(j+1).(i+1).tab_line_piece.(2);

          if (i>0 && current_game.tab_line.(j+1).(i-1).current_piece =
              actor.pion)
          then
            down_r := current_game.tab_line.(j+1).(i-1).tab_line_piece.(3);
        );

      (*on modifie les donn�es de tav_line pour la case courante*)
      current_game.tab_line.(j).(i).tab_line_piece.(1) <- !l + 1 + !r;
      current_game.tab_line.(j).(i).tab_line_piece.(2) <- !down_l + 1 + !up_r;
      current_game.tab_line.(j).(i).tab_line_piece.(3) <- !up_l + 1 + !down_r;

      (*on modifie les donn�es des cases adjacentes se trouvant dans une
        meme ligne que le pion courant*)
      (*mise � jour de la ligne horizontale*)
      if (!l <> 0) then
        (
          for k = 1 to !l do
            current_game.tab_line.(j-k).(i).tab_line_piece.(1) <- !l + 1 + !r
          done;
        );

      if (!r <> 0) then
        (
          for k = 1 to !r do
            current_game.tab_line.(j+k).(i).tab_line_piece.(1) <- !l  + 1 + !r
          done;
        );

      (*pour la premi�re diagonale*)
      if (!down_l != 0) then
        (
          for k = 1 to !down_l do
            current_game.tab_line.(j-k).(i-k).tab_line_piece.(2) <-
              !down_l + 1 + !up_r
          done;
        );

      if (!up_r != 0) then
        (
          for k = 1 to !up_r do
            current_game.tab_line.(j+k).(i+k).tab_line_piece.(2) <-
              !down_l  + 1 + !up_r
          done;
        );

      (*pour la deuxi�me diagonale*)
      if (!up_l != 0) then
        (
          for k = 1 to !up_l do
            current_game.tab_line.(j-k).(i+k).tab_line_piece.(3) <-
              !up_l + 1 + !down_r
          done;
        );

      if (!down_r != 0) then
        (
          for k = 1 to !down_r do
            current_game.tab_line.(j+k).(i-k).tab_line_piece.(3) <-
              !up_l  + 1 + !down_r
          done;
        );

      (*mise � jour de la liste des �v�nements du jeu*)
      current_game.list_event <-
        [{col = j; line = i; piece = actor.pion}]@current_game.list_event
    )
  else raise Plein
;;

(*retourne de num coup en arri�re dans le jeu*)
let rec remove current_game num =
  if (num<>0)then
    (
      let next_event = List.hd current_game.list_event in
      let j = next_event.col
      and i = next_event.line in
      current_game.col_st.(j) <- current_game.col_st.(j) - 1;
      current_game.tab.(j).(i) <- Empty;
      current_game.tab_line.(j).(i)
      <- {current_piece = Empty; tab_line_piece = [|0;0;0;0|]};
      current_game.number_of_move <- current_game.number_of_move - 1;
      (*plus changer les valeurs des voisins...*)
      current_game.list_event <- List.tl current_game.list_event;
      remove current_game (num-1)
    )
;;

(*creer une copy du jeu courant*)
let copy_game current_game =
  {
    tab = Array.init 7 (fun i -> (Array.copy current_game.tab.(i)));

    tab_line = Array.init 7
      (fun i -> Array.init 6
         (fun j ->
            {current_piece = (current_game.tab_line.(i).(j)).current_piece;
             tab_line_piece = Array.copy
                (current_game.tab_line.(i).(j).tab_line_piece)
            }
         )
      );

    list_event = current_game.list_event;
    number_of_move = current_game.number_of_move;
    col_st = Array.copy current_game.col_st
  }
;;


(*cr�ation d'une nouvelle partie*)
let new_part current_game =
  current_game.tab <- Array.init 7 (fun i -> (Array.make 6 Empty));
  current_game.tab_line <- Array.init 7
    (fun i -> Array.init 6
       (fun i -> ({current_piece = Empty; tab_line_piece = [|0;0;0;0|]})));
  current_game.list_event <- [];
  current_game.number_of_move <- 0;
  current_game.col_st <- Array.make 7 0
;;

(*retourne vrai qd le pion en (i,j) est ds une ligne de 4pions de meme couleur*)
(*faire avec une methode recursif qui garde win*)
let isWin current_game =
  if (current_game.number_of_move <> 0) then
    let i = (List.hd (current_game.list_event)).line
    and j = (List.hd (current_game.list_event)).col in
    let rec winner won k =
      if (won = false && k < 4) then
        if (current_game.tab_line.(j).(i).tab_line_piece.(k) >= 4)
        then winner true k
        else winner won (k+1)
      else won
    in winner false 0
  else false
;;

let p_to_string p =
  if p = Yellow then print_string "Yellow " else if p = Red then
    print_string "Red    " else print_string "Empty  ";;

let tab_to_string tab =
  print_string "\n";
  for i = 0 to (Array.length tab) -1  do
    for j = 0 to (Array.length tab.(i)) -1 do
      p_to_string tab.(i).(j)
    done;
    print_string "\n"
  done;;


let rec alphabeta current_game actor1 ?(iter=1) actor2 alpha beta bobo =
  if(current_game.number_of_move <> 0 && isWin current_game) then
    if (bobo) then ((1. (*/. float iter*)), (List.hd current_game.list_event).col)
    else ((-1. (*/. float iter*)), (List.hd current_game.list_event).col)

  else if (current_game.number_of_move = 42)
  then (0., (List.hd current_game.list_event).col)
  else
    (
      let game = copy_game current_game in
      if (not bobo) then
        (*faire un remove???*)
        let rec cut_beta a b value col_current i =
          if (i < Array.length game.tab) then
            try
              (
                let game_ = copy_game game in
                move game_ i actor1;
                let test_value = fst (alphabeta game_ actor2 actor1 a b
                                        ~iter:(iter+1) (not bobo)) in
                let (value_temp, good_col) = if test_value >= value then
                  (test_value, i) else (value, col_current) in
                if value_temp >= b then (value_temp, good_col)
                else cut_beta (max a value_temp) b value_temp
                  good_col (i+1)
              )
            with plein -> cut_beta a b value col_current (i+1)
          else (value, col_current) in
        cut_beta alpha beta (-1.) 0 0
      else
        let rec cut_alpha a b value col_current i =
          if (i < (Array.length game.tab)) then
            try
              (
                let game_ = copy_game game in
                move game_ i actor1;
                let test_value = fst (alphabeta game_ actor2 actor1 a b
                                        ~iter:(iter+1) (not bobo)) in
                let (value_temp, good_col) = if test_value <= value then
                  (test_value, i) else (value, col_current) in
                if value_temp <= a then (value_temp, good_col)
                else cut_alpha a (min b value_temp) value_temp
                  good_col (i+1)
              )
            with plein -> cut_alpha a b value col_current (i+1)
          else (value, col_current) in
        cut_alpha alpha beta 1. 0 0
    )
;;


let g = make ();;
let player1 = {player = Human; pion = Yellow; fst_player = true};;
let player2 = {player = Human; pion = Red; fst_player = false};;
move g 3 player1;
move g 3 player2;
move g 4 player1;
move g 5 player2;
move g 2 player1;
move g 1 player2;
move g 4 player1;
move g 4 player2;
move g 2 player1;
move g 5 player2;
move g 2 player1;
move g 2 player2;
move g 6 player1;
move g 0 player2;
move g 1 player1;
move g 2 player2;;

move g 1 player1;
move g 3 player2;
move g 3 player1;
move g 1 player2;
move g 1 player1;
move g 6 player2;
move g 5 player1;
move g 5 player2;
move g 4 player1;
move g 4 player2;
move g 6 player1;
move g 6 player2;
move g 6 player1;
move g 2 player2;;


tab_to_string g.tab;;

let couple = alphabeta g player1 player2 (-1.) 1. false;;
move g (snd couple) player1;;
couple;;
tab_to_string g.tab;;
isWin g;;
let couple2 = alphabeta g player2 player1 (-1.) 1. false;;
move g (snd couple2) player2;;
couple2;;
tab_to_string g.tab;;
isWin g;;
print_string "Joueur 1 : ";
print_float (fst couple);
print_string "\nJoueur2 : ";
print_float (fst couple2);;

tab_to_string g.tab;;
alphabeta g player1 player2 (-1.) 1. false;;