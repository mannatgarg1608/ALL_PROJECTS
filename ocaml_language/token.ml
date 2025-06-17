(* Define the different types of tokens that the lexer can recognize *)
type token =
  | IF | THEN | ELSEIF | ELSE | FOR | WHILE
  | INPUT | PRINT
  | INPUT_FILE of string (* Represents an input file token with filename *)
  | PRINT_OUT of string (* Represents an output file token with filename *)
  | INT_MAX of int | INT_MIN of int (* Represents integer limits *)
  | DOT | ANG | MAG | DIM | TRANS | DETERMINANT (* Mathematical operations *)
  | AND | OR | NOT (* Logical operators *)
  | PLUS | MINUS | TIMES | DIVIDE | ASSIGN (* Arithmetic operators *)
  | EQ | NEQ | GT | LT | GEQ | LEQ (* Comparison operators *)
  | SEMICOLON | LPAREN | RPAREN | LBRACE | RBRACE | LBRACKET | RBRACKET (* Delimiters *)
  | ABS (* Absolute function *)
  | INT of int (* Represents an integer value *)
  | FLOAT of float (* Represents a floating-point value *)
  | VECTOR_INT of int list (* Represents a vector of integers *)
  | VECTOR_FLOAT of float list (* Represents a vector of floats *)
  | MATRIX_INT of int list list (* Represents a matrix of integers *)
  | MATRIX_FLOAT of float list list (* Represents a matrix of floats *)
  | ID of string (* Represents an identifier *)
  | BOOL of bool (* Represents a boolean value *)
  | INT_TYPE | FLOAT_TYPE | VECTOR_INT_TYPE | VECTOR_FLOAT_TYPE |MATRIX_INT_TYPE |MATRIX_FLOAT_TYPE (* Represents the type of a variable *)
  | BOOL_TYPE 
  | COMMA
  | POW
  | SQRT
  (* |INVERSE *)
  |MINOR| REM
  | EOF (* End of file token *)

(* Convert a token into its string representation *)
let token_to_string = function
  | IF -> "IF" | THEN -> "THEN" | ELSEIF -> "ELSEIF" | ELSE -> "ELSE"
  | FOR -> "FOR" | WHILE -> "WHILE"
  | INPUT -> "INPUT()" | PRINT -> "PRINT()"
  | INPUT_FILE f -> "INPUT(" ^ f ^ ")"
  | PRINT_OUT f -> "PRINT(" ^ f ^ ")"
  | INT_MAX i -> "INT_MAX(" ^ string_of_int i ^ ")"
  | INT_MIN i -> "INT_MIN(" ^ string_of_int i ^ ")"
  | DOT -> "DOT" | ANG -> "ANG" | MAG -> "MAG" | DIM -> "DIM"
  | TRANS -> "TRANS" | DETERMINANT -> "DETERMINANT"
  | AND -> "AND" | OR -> "OR" | NOT -> "NOT"
  | PLUS -> "PLUS" | MINUS -> "MINUS" | TIMES -> "TIMES" | DIVIDE -> "DIVIDE"
  | ASSIGN -> "ASSIGN"
  | EQ -> "EQ" | NEQ -> "NEQ" | GT -> "GT" | LT -> "LT" | GEQ -> "GEQ" | LEQ -> "LEQ"
  | SEMICOLON -> "SEMICOLON" | LPAREN -> "LPAREN" | RPAREN -> "RPAREN"
  | LBRACE -> "LBRACE" | RBRACE -> "RBRACE" | LBRACKET -> "LBRACKET" | RBRACKET -> "RBRACKET"
  | ABS -> "ABS"
  | INT i -> "INT(" ^ string_of_int i ^ ")"
  | FLOAT f -> "FLOAT(" ^ string_of_float f ^ ")"
  | VECTOR_INT vi -> "VECTOR_INT([" ^ String.concat "; " (List.map string_of_int vi) ^ "])"
  | VECTOR_FLOAT vf -> "VECTOR_FLOAT([" ^ String.concat "; " (List.map string_of_float vf) ^ "])"
  | MATRIX_INT mi -> "MATRIX_INT([" ^ String.concat "; " (List.map (fun row -> "[" ^ String.concat "; " (List.map string_of_int row) ^ "]") mi) ^ "])"
  | MATRIX_FLOAT mf -> "MATRIX_FLOAT([" ^ String.concat "; " (List.map (fun row -> "[" ^ String.concat "; " (List.map string_of_float row) ^ "]") mf) ^ "])"
  | ID s -> "ID(" ^ s ^ ")"
  | BOOL b -> "BOOL(" ^ string_of_bool b ^ ")"
  | INT_TYPE -> "INT_TYPE" | FLOAT_TYPE -> "FLOAT_TYPE"
  | VECTOR_INT_TYPE -> "VECTOR_INT_TYPE" | VECTOR_FLOAT_TYPE -> "VECTOR_FLOAT_TYPE"
  | MATRIX_INT_TYPE -> "MATRIX_INT_TYPE" | MATRIX_FLOAT_TYPE -> "MATRIX_FLOAT_TYPE"
  | BOOL_TYPE -> "BOOL_TYPE"
  | SQRT -> "SQRT"
  | COMMA -> "COMMA"
  | POW -> "POW"
  (* | INVERSE -> "INVERSE" *)
  | MINOR -> "MINOR"
  |REM -> "REM"
  | EOF -> "EOF"



(* Function to parse a vector of integers from a string representation *)
let parse_vector_int v =
  let inner = String.sub v 1 (String.length v - 2) in (* Remove surrounding brackets *)
  let string_vector = String.split_on_char ',' inner in (* Split by commas *)
  List.map (fun s -> int_of_string (String.trim s)) string_vector (* Convert to integers *)


(* Function to parse a matrix (list of integer lists) from a string representation *)
let parse_matrix_int matrix =
  let inner = String.sub matrix 1 (String.length matrix - 2) in (* Remove outer brackets *)
  let string_vectors = String.split_on_char ']' inner 
    |> List.filter (fun s -> String.trim s <> "") 
    |> List.map (fun s -> 
      if s.[0] = ',' then String.sub s 1 (String.length s - 1) ^ "]" (* Handle leading commas *)
      else s ^ "]"
    )
  in
  List.map parse_vector_int string_vectors (* Convert each row to integer list *)
  
(* Function to parse a vector of floats from a string representation *)
let parse_vector_float v =
  let inner= String.sub v 1 (String.length v - 2) in (* Remove brackets *)
  let string_vector = String.split_on_char ',' inner in (* Split by commas *)
  List.map (fun s -> float_of_string (String.trim s)) string_vector (* Convert to floats *)

(* Function to parse a matrix (list of float lists) from a string representation *)
let parse_matrix_float matrix =
  let inner = String.sub matrix 1 (String.length matrix- 2) in (* Remove outer brackets *)
  let string_vectors = String.split_on_char ']' inner
    |> List.filter (fun s -> String.trim s <> "") 
    |> List.map (fun s -> 
      if s.[0] = ',' then String.sub s 1 (String.length s - 1) ^ "]" (* Handle leading commas *)
      else s ^ "]"
    )
  in
  List.map parse_vector_float string_vectors (* Convert each row to float list *)
