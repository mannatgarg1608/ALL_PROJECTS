open Hashtbl
open Ast  


let vector_int_add v1 v2 =
  List.map2 ( + ) v1 v2

let vector_float_add v1 v2 =
  List.map2 ( +. ) v1 v2

let vector_int_sub  v1 v2 =
  List.map2 ( - ) v1 v2

let vector_float_sub  v1 v2 =
  List.map2 ( -. ) v1 v2

let vector_int_dot v1 v2  =
List.fold_left ( + ) 0 (List.map2 ( * ) v1 v2 )

let vector_float_dot v1 v2 =
List.fold_left ( +. ) 0. (List.map2 ( *. ) v1 v2 )


let vector_int_div v scalar=
List.map (fun x -> float_of_int x /. float_of_int scalar) v


let vector_float_div v scalar =
List.map (fun x -> x /. scalar) v

let vector_int_scalar_mult scalar v =
  List.map (fun x -> scalar * x) v

let vector_float_scalar_mult scalar v =
  List.map (fun x -> scalar *. x) v


(* Vector operations *)
let vector_int_add v1 v2 =
  if List.length v1 <> List.length v2 then
    failwith "Vector dimensions must match for addition"
  else
    List.map2 (+) v1 v2

let vector_int_sub v1 v2 =
  if List.length v1 <> List.length v2 then
    failwith "Vector dimensions must match for subtraction"
  else
    List.map2 (-) v1 v2

let vector_int_dot v1 v2 =
  if List.length v1 <> List.length v2 then
    failwith "Vector dimensions must match for dot product"
  else
    List.fold_left (+) 0 (List.map2 ( * ) v1 v2)

let vector_float_add v1 v2 =
  if List.length v1 <> List.length v2 then
    failwith "Vector dimensions must match for addition"
  else
    List.map2 (+.) v1 v2

let vector_float_sub v1 v2 =
  if List.length v1 <> List.length v2 then
    failwith "Vector dimensions must match for subtraction"
  else
    List.map2 (-.) v1 v2

let vector_float_dot v1 v2 =
  if List.length v1 <> List.length v2 then
    failwith "Vector dimensions must match for dot product"
  else
    List.fold_left (+.) 0.0 (List.map2 ( *. ) v1 v2)

let vector_int_div v scalar =
  if scalar = 0 then
    failwith "Division by zero"
  else
    List.map (fun x -> float_of_int x /. float_of_int scalar) v

let vector_float_div v scalar =
  if scalar = 0.0 then
    failwith "Division by zero"
  else
    List.map (fun x -> x /. scalar) v

let vector_int_scalar_mult scalar v =
  List.map (fun x -> scalar * x) v

let vector_float_scalar_mult scalar v =
  List.map (fun x -> scalar *. x) v

let vector_float_angle v1 v2 =
  let dot = vector_float_dot v1 v2 in
  let mag1 = sqrt (vector_float_dot v1 v1) in
  let mag2 = sqrt (vector_float_dot v2 v2) in
  if mag1 = 0.0 || mag2 = 0.0 then
    failwith "Cannot compute angle with zero vector"
  else
    acos (dot /. (mag1 *. mag2))

let vector_int_angle v1 v2 =
  let float_v1 = List.map float_of_int v1 in
  let float_v2 = List.map float_of_int v2 in
  vector_float_angle float_v1 float_v2

let matrix_int_add m1 m2=
    List.map2 (fun row1 row2 -> vector_int_add row1 row2) m1 m2

let matrix_float_add m1 m2 =
  List.map2 (fun row1 row2 -> vector_float_add row1 row2) m1 m2

let matrix_int_sub m1 m2 =
  List.map2 (fun row1 row2 -> vector_int_sub row1 row2) m1 m2

let matrix_float_sub m1 m2 =
  List.map2 (fun row1 row2 -> vector_float_sub row1 row2) m1 m2

let matrix_int_vector_mul m v =
  List.map (fun row -> vector_int_dot row v) m

let matrix_float_vector_mul m v =
  List.map (fun row -> vector_float_dot row v) m


let matrix_int_scalar_mult scalar m =
  List.map (fun row -> vector_int_scalar_mult scalar row ) m

let matrix_float_scalar_mult scalar m =
  List.map (fun row -> vector_float_scalar_mult scalar row) m

let matrix_int_matrix_mul m1 m2 =
  (* Convert m2 to column vectors *)
  let cols = List.length (List.hd m2) in
  let m2_cols = List.init cols (fun j ->
    List.map (fun row -> List.nth row j) m2
  ) in
  
  (* Multiply each row of m1 with each column of m2 *)
  List.map (fun row ->List.map (fun col ->vector_int_dot row col) m2_cols) m1


let matrix_float_matrix_mul m1 m2 =
  (* Convert m2 to column vectors *)
  let cols = List.length (List.hd m2) in
  let m2_cols = List.init cols (fun j ->
    List.map (fun row -> List.nth row j) m2
  ) in
  
  (* Multiply each row of m1 with each column of m2 *)
  List.map (fun row ->List.map (fun col ->vector_float_dot row col) m2_cols) m1

let matrix_minor_int m row_to_remove col_to_remove =
  m |> List.filteri (fun i _ -> i <> row_to_remove)
    |> List.map (fun row -> 
          List.filteri (fun j _ -> j <> col_to_remove) row)


let matrix_minor_float m row_to_remove col_to_remove =
m |> List.filteri (fun i _ -> i <> row_to_remove)
  |> List.map (fun row -> 
        List.filteri (fun j _ -> j <> col_to_remove) row)


let rec determinant_int m =
  let n = List.length m in
  if n=0 then 1 
  else if n=1 then List.hd (List.hd m)
  else if n=2 then 
  let a= List.nth (List.nth m 0) 0 in
  let b= List.nth (List.nth m 0) 1 in 
  let c=List.nth (List.nth m 1) 0 in
  let d=List.nth (List.nth m 1) 1 in
  a * d - b * c
 else 
  let row =List.hd m in 
  let rec cofactor_det index determinant sign =
  if index> n then determinant
  else
    let minor = matrix_minor_int m 0 index in
    let determinant_minor = determinant_int minor in
    let current = sign *(List.nth row index)*determinant_minor in
    cofactor_det (index+1) (current+determinant) (-sign)
  in cofactor_det 0 0 1




let rec determinant_float m =
  let n = List.length m in
  if n=0 then 1.0
  else if n=1 then List.hd (List.hd m)
  else if n=2 then 
  let a= List.nth (List.nth m 0) 0 in
  let b= List.nth (List.nth m 0) 1 in 
  let c=List.nth (List.nth m 1) 0 in
  let d=List.nth (List.nth m 1) 1 in
  a *. d -. b *. c
  else 
  let row =List.hd m in 
  let rec cofactor_det index determinant sign =
  if index> n then determinant
  else 
    let minor = matrix_minor_float m 0 index in
    let determinant_minor = determinant_float minor in
    let current = sign *. (List.nth row index) *. determinant_minor in
    cofactor_det (index+1) (current +. determinant) (-.sign)
  in cofactor_det 0 0.0 1.0

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

  

let read_from_file filename expected_type =
  try
    let ic = open_in filename in
    match expected_type with
    | TInt ->
        let line = input_line ic in
        close_in ic;
        LitInt (int_of_string (String.trim line))
    | TFloat ->
        let line = input_line ic in
        close_in ic;
        LitFloat (float_of_string (String.trim line))
    | TBool ->
        let line = input_line ic in
        close_in ic;
        LitBool (bool_of_string (String.trim line))
    |TVectorInt expected_dim -> 
      let dim_line = input_line ic in
      let actual_dim = int_of_string (String.trim dim_line) in
      if actual_dim != expected_dim then begin
        close_in ic;
        failwith (Printf.sprintf "Vector dimension mismatch: expected %d, got %d" 
                  expected_dim actual_dim)
      end;
      let elements_line = input_line ic in
        close_in ic;

      let elements = parse_vector_int elements_line in
      
      (* Double-check that the number of elements matches the dimension *)
      if List.length elements != actual_dim then
        failwith (Printf.sprintf "Vector element count mismatch: expected %d, got %d" 
                  actual_dim (List.length elements))
      else
        VectorIntLit (actual_dim, elements)
    | TVectorFloat expected_dim ->
      (* First line contains dimension *)
      let dim_line = input_line ic in
      let actual_dim = int_of_string (String.trim dim_line) in
      
      (* Check if dimensions match *)
      if actual_dim != expected_dim then begin
        close_in ic;
        failwith (Printf.sprintf "Vector dimension mismatch: expected %d, got %d" 
                  expected_dim actual_dim)
      end;
      
      (* Second line contains vector elements *)
      let elements_line = input_line ic in
      close_in ic;
      
      let elements = parse_vector_float elements_line in
      
      (* Double-check that the number of elements matches the dimension *)
      if List.length elements != actual_dim then
        failwith (Printf.sprintf "Vector element count mismatch: expected %d, got %d" 
                  actual_dim (List.length elements))
      else
        VectorFloatLit (actual_dim, elements)

    | TMatrixInt (expected_rows, expected_cols) ->
      (* First line contains dimensions as "rows cols" *)
      let dim_line = input_line ic in
      let dims = String.split_on_char ',' (String.trim dim_line) in
      if List.length dims != 2 then
        failwith "Invalid matrix dimensions format in file";
      
      let actual_rows = int_of_string (List.nth dims 0) in
      let actual_cols = int_of_string (List.nth dims 1) in
      
      (* Check if dimensions match *)
      if actual_rows != expected_rows || actual_cols != expected_cols then begin
        close_in ic;
        failwith (Printf.sprintf "Matrix dimension mismatch: expected %dx%d, got %dx%d" 
                  expected_rows expected_cols actual_rows actual_cols)
      end;
      
      (* Second line contains matrix elements *)
      let matrix_line = input_line ic in
      close_in ic;
      
      let rows = parse_matrix_int matrix_line in
      
      (* Check if row count matches *)
      if List.length rows != actual_rows then
        failwith (Printf.sprintf "Matrix row count mismatch: expected %d, got %d" 
                  actual_rows (List.length rows))
      else
        (* Check if all rows have the expected number of columns *)
        let valid_cols = List.for_all (fun row -> List.length row = actual_cols) rows in
        if not valid_cols then
          failwith (Printf.sprintf "Some matrix rows don't have the expected column count: %d" actual_cols)
        else
          MatrixIntLit (actual_rows, actual_cols, rows)
    | TMatrixFloat (expected_rows, expected_cols) ->
      (* First line contains dimensions as "rows cols" *)
      let dim_line = input_line ic in
      let dims = String.split_on_char ',' (String.trim dim_line) in
      if List.length dims != 2 then
        failwith "Invalid matrix dimensions format in file";
      
      let actual_rows = int_of_string (List.nth dims 0) in
      let actual_cols = int_of_string (List.nth dims 1) in
      
      (* Check if dimensions match *)
      if actual_rows != expected_rows || actual_cols != expected_cols then begin
        close_in ic;
        failwith (Printf.sprintf "Matrix dimension mismatch: expected %dx%d, got %dx%d" 
                  expected_rows expected_cols actual_rows actual_cols)
      end;
      
      (* Second line contains matrix elements *)
      let matrix_line = input_line ic in
      close_in ic;
      
      let rows = parse_matrix_float matrix_line in
      
      (* Check if row count matches *)
      if List.length rows != actual_rows then
        failwith (Printf.sprintf "Matrix row count mismatch: expected %d, got %d" 
                  actual_rows (List.length rows))
      else
        (* Check if all rows have the expected number of columns *)
        let valid_cols = List.for_all (fun row -> List.length row = actual_cols) rows in
        if not valid_cols then
          failwith (Printf.sprintf "Some matrix rows don't have the expected column count: %d" actual_cols)
        else
          MatrixFloatLit (actual_rows, actual_cols, rows)
with
| Sys_error msg -> failwith ("File error: " ^ msg)
| End_of_file -> failwith "File is empty"
| Failure msg -> failwith ("Parsing error: " ^ msg)


let read_from_stdin expected_type =
  match expected_type with
  | TInt ->
      print_string "Enter integer: ";
      flush stdout;
      let line = read_line () in
      LitInt (int_of_string (String.trim line))
  
  | TFloat ->
      print_string "Enter float: ";
      flush stdout;
      let line = read_line () in
      LitFloat (float_of_string (String.trim line))
  
  | TBool ->
      print_string "Enter boolean (true/false): ";
      flush stdout;
      let line = read_line () in
      LitBool (bool_of_string (String.trim line))
  
  | TVectorInt expected_dim ->
      (* print_string (Printf.sprintf "Enter vector dimension (should be %d): " expected_dim); *)
      flush stdout;
      let dim_line = read_line () in
      let actual_dim = int_of_string (String.trim dim_line) in
      (* Check if dimensions match *)
      if actual_dim != expected_dim then
        failwith (Printf.sprintf "Vector dimension mismatch: expected %d, got %d" 
                  expected_dim actual_dim);
      (* print_string (Printf.sprintf "Enter %d integer elements in format [a,b,c,...]: " actual_dim); *)
      flush stdout;
      let elements_line = read_line () in
      let elements = parse_vector_int elements_line in
      
      (* Double-check that the number of elements matches the dimension *)
      if List.length elements != actual_dim then
        failwith (Printf.sprintf "Vector element count mismatch: expected %d, got %d" 
                  actual_dim (List.length elements))
      else
        VectorIntLit (actual_dim, elements)
  
  | TVectorFloat expected_dim ->
      (* print_string (Printf.sprintf "Enter vector dimension (should be %d): " expected_dim); *)
      flush stdout;
      let dim_line = read_line () in
      let actual_dim = int_of_string (String.trim dim_line) in
      
      (* Check if dimensions match *)
      if actual_dim != expected_dim then
        failwith (Printf.sprintf "Vector dimension mismatch: expected %d, got %d" 
                  expected_dim actual_dim);
      
      (* print_string (Printf.sprintf "Enter %d float elements in format [a,b,c,...]: " actual_dim); *)
      flush stdout;
      let elements_line = read_line () in
      
      let elements = parse_vector_float elements_line in
      
      (* Double-check that the number of elements matches the dimension *)
      if List.length elements != actual_dim then
        failwith (Printf.sprintf "Vector element count mismatch: expected %d, got %d" 
                  actual_dim (List.length elements))
      else
        VectorFloatLit (actual_dim, elements)
  
  | TMatrixInt (expected_rows, expected_cols) ->
      (* print_string (Printf.sprintf "Enter matrix dimensions (should be %d %d): " expected_rows expected_cols); *)
      flush stdout;
      let dim_line = read_line () in
      let dims = String.split_on_char ',' (String.trim dim_line) in
      
      if List.length dims != 2 then
        failwith "Invalid matrix dimensions format";
      
      let actual_rows = int_of_string (List.nth dims 0) in
      let actual_cols = int_of_string (List.nth dims 1) in
      
      (* Check if dimensions match *)
      if actual_rows != expected_rows || actual_cols != expected_cols then
        failwith (Printf.sprintf "Matrix dimension mismatch: expected %dx%d, got %dx%d" 
                  expected_rows expected_cols actual_rows actual_cols);
      
      (* print_string (Printf.sprintf "Enter %dx%d integer matrix in format [[a,b],[c,d],...]: " 
                   actual_rows actual_cols); *)
      flush stdout;
      let matrix_line = read_line () in
      
      let rows = parse_matrix_int matrix_line in
      
      (* Check if row count matches *)
      if List.length rows != actual_rows then
        failwith (Printf.sprintf "Matrix row count mismatch: expected %d, got %d" 
                  actual_rows (List.length rows))
      else
        (* Check if all rows have the expected number of columns *)
        let valid_cols = List.for_all (fun row -> List.length row = actual_cols) rows in
        if not valid_cols then
          failwith (Printf.sprintf "Some matrix rows don't have the expected column count: %d" actual_cols)
        else
          MatrixIntLit (actual_rows, actual_cols, rows)
  
  | TMatrixFloat (expected_rows, expected_cols) ->
      (* print_string (Printf.sprintf "Enter matrix dimensions (should be %d %d): " expected_rows expected_cols); *)
      flush stdout;
      let dim_line = read_line () in
      let dims = String.split_on_char ',' (String.trim dim_line) in
      
      if List.length dims != 2 then
        failwith "Invalid matrix dimensions format";
      
      let actual_rows = int_of_string (List.nth dims 0) in
      let actual_cols = int_of_string (List.nth dims 1) in
      
      (* Check if dimensions match *)
      if actual_rows != expected_rows || actual_cols != expected_cols then
        failwith (Printf.sprintf "Matrix dimension mismatch: expected %dx%d, got %dx%d" 
                  expected_rows expected_cols actual_rows actual_cols);
      
      (* print_string (Printf.sprintf "Enter %dx%d float matrix in format [[a,b],[c,d],...]: " 
                   actual_rows actual_cols); *)
      flush stdout;
      let matrix_line = read_line () in
      
      let rows = parse_matrix_float matrix_line in
      
      (* Check if row count matches *)
      if List.length rows != actual_rows then
        failwith (Printf.sprintf "Matrix row count mismatch: expected %d, got %d" 
                  actual_rows (List.length rows))
      else
        (* Check if all rows have the expected number of columns *)
        let valid_cols = List.for_all (fun row -> List.length row = actual_cols) rows in
        if not valid_cols then
          failwith (Printf.sprintf "Some matrix rows don't have the expected column count: %d" actual_cols)
        else
          MatrixFloatLit (actual_rows, actual_cols, rows)


let print_value value =
match value with
| LitInt i -> 
  Printf.printf "%d\n" i

| LitFloat f -> 
  Printf.printf "%F\n" f

| LitBool b -> 
  Printf.printf "%b\n" b

| VectorIntLit (dim, elements) ->
  Printf.printf "[";
  List.iteri (fun i x -> 
    Printf.printf "%d" x;
    if i < dim - 1 then Printf.printf ", "
  ) elements;
  Printf.printf "]\n"

| VectorFloatLit (dim, elements) ->
  Printf.printf "[";
  List.iteri (fun i x -> 
    Printf.printf "%F" x;
    if i < dim - 1 then Printf.printf ", "
  ) elements;
  Printf.printf "]\n"

| MatrixIntLit (rows, cols, matrix) ->
  Printf.printf "[ ";
  List.iteri (fun i row ->
    Printf.printf "[";
    List.iteri (fun j x -> 
      Printf.printf "%d" x;
      if j < cols - 1 then Printf.printf ", "
    ) row;
    Printf.printf "]";
    if i < rows - 1 then Printf.printf "," else Printf.printf " "
  ) matrix;
  Printf.printf "]\n"

| MatrixFloatLit (rows, cols, matrix) ->
  Printf.printf "[ ";
  List.iteri (fun i row ->
    Printf.printf "[";
    List.iteri (fun j x -> 
      Printf.printf "%F" x;
      if j < cols - 1 then Printf.printf ", "
    ) row;
    Printf.printf "]";
    if i < rows - 1 then Printf.printf "," else Printf.printf " "
  ) matrix;
  Printf.printf "]\n"
| _ -> failwith " wrong thing to be printed"