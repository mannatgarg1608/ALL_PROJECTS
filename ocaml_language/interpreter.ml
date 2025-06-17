open Ast 
open Function
open Parser
open Lexer


let rec eval_expr  var_table_value expr = 
    match expr with 
    | LitInt i -> LitInt i 
    | Var(id) -> if Hashtbl.mem var_table_value id then Hashtbl.find var_table_value id
    else failwith ("Undefined variable: " ^ id)
    | LitFloat f -> LitFloat f
    | LitBool b -> LitBool b 
    | VectorIntLit(dim, elements) -> VectorIntLit(dim, elements)
    | VectorFloatLit(dim, elements) -> VectorFloatLit(dim, elements)
    | MatrixIntLit(rows,cols, elements) -> MatrixIntLit(rows,cols, elements)
    | MatrixFloatLit(rows,cols, elements) ->  MatrixFloatLit(rows,cols, elements)
    (* define these functions *)
    |Minor(id,a,b)->
      let x = match eval_expr var_table_value a with
      | LitInt i -> i
      | _ -> failwith "Row index must be an integer"
    in
    let y = match eval_expr var_table_value b with
      | LitInt j -> j
      | _ -> failwith "Column index must be an integer"
    in
      if Hashtbl.mem var_table_value id then 
        match Hashtbl.find var_table_value id with
          | MatrixIntLit (rows, cols, elements) ->
              (* Ensure the indices are within bounds *)
              if x < 0 || x >= rows || y < 0 || y >= cols then
                failwith "Matrix index out of bounds"
              else
                    MatrixIntLit(rows-1,cols-1,matrix_minor_int elements x y )
          | MatrixFloatLit (rows, cols, elements) ->
              (* Ensure the indices are within bounds *)
              if x < 0 || x >= rows || y < 0 || y >= cols then
                failwith "Matrix index out of bounds"
              else  
                MatrixFloatLit(rows-1,cols-1,matrix_minor_float elements x y )
          | _ -> failwith "Variable is not a matrix"
        else
          failwith ("Undefined matrix: " ^ id)
    | MatrixRef(id,a,b) -> 
        let x = match eval_expr var_table_value a with
          | LitInt i -> i
          | _ -> failwith "Row index must be an integer"
        in
        let y = match eval_expr var_table_value b with
          | LitInt j -> j
          | _ -> failwith "Column index must be an integer"
        in
        (* Check if the matrix exists in the variable table *)
        if Hashtbl.mem var_table_value id then
          match Hashtbl.find var_table_value id with
          | MatrixIntLit (rows, cols, elements) ->
              (* Ensure the indices are within bounds *)
              if x < 0 || x >= rows || y < 0 || y >= cols then
                failwith "Matrix index out of bounds"
              else
                (* Return the matrix element *)
              LitInt( List.nth (List.nth elements x) y )
          | MatrixFloatLit (rows, cols, elements) ->
              (* Ensure the indices are within bounds *)
              if x < 0 || x >= rows || y < 0 || y >= cols then
                failwith "Matrix index out of bounds"
              else
                (* Return the matrix element *)
              LitFloat( List.nth (List.nth elements x) y )
          | _ -> failwith "Variable is not a matrix"
        else
          failwith ("Undefined matrix: " ^ id) 
    |VectorRef(id,a) -> 
        let x = match eval_expr var_table_value a with
          | LitInt i -> i
          | _ -> failwith "Index must be an integer"
        in
        (* Check if the vector exists in the variable table *)
        if Hashtbl.mem var_table_value id then
          match Hashtbl.find var_table_value id with
          | VectorIntLit (dim, elements) ->
              (* Ensure the index is within bounds *)
              if x < 0 || x >= dim then
                failwith "Vector index out of bounds"
              else
                (* Return the vector element *)
                LitInt (List.nth elements x )
          | VectorFloatLit (dim, elements) ->
              (* Ensure the index is within bounds *)
              if x < 0 || x >= dim then
                failwith "Vector index out of bounds"
              else
                (* Return the vector element *)
              LitFloat (List.nth elements x )
          | _ -> failwith "Variable is not a vector"
        else
          failwith ("Undefined vector: " ^ id)
    |Unop (command,b) -> 
      let operand = eval_expr var_table_value b in 
      (match command,operand with 
      | IntSqrt, LitInt i -> LitFloat (sqrt (float_of_int i))
      | FloatSqrt, LitFloat f -> LitFloat ( sqrt(f))
      | IntAbs , LitInt i -> LitInt (abs i)
      | FloatAbs , LitFloat f -> LitFloat (abs_float f)
      | IntNeg , LitInt i -> LitInt (-i)
      | FloatNeg , LitFloat f-> LitFloat(-.f)
      | BoolNot , LitBool b -> if b = true then LitBool false else LitBool true
      | VectorMag, VectorIntLit(dim,elements) -> 
          let sum = List.fold_left (fun acc x -> acc + (x * x)) 0 elements in
          LitFloat (sqrt (float_of_int sum))
      | VectorMag, VectorFloatLit(dim,elements) ->
          let sum = List.fold_left (fun acc x -> acc +. (x *. x)) 0.0 elements in
          LitFloat (sqrt sum)
      | MatrixMag, MatrixIntLit(rows,cols,elements) ->
          let sum = List.fold_left (fun acc row -> acc + (List.fold_left (fun acc x -> acc + (x * x)) 0 row)) 0 elements in
          LitFloat (sqrt (float_of_int sum))
      | MatrixMag, MatrixFloatLit(rows,cols,elements) ->
          let sum = List.fold_left (fun acc row -> acc +. (List.fold_left (fun acc x -> acc +. (x *. x)) 0.0 row)) 0.0 elements in
          LitFloat (sqrt sum)
      | VectorDim, VectorIntLit(dim,elements) -> LitInt(dim)
      | VectorDim, VectorFloatLit(dim,elements) -> LitInt(dim)
      | MatrixDim, MatrixIntLit(rows,cols,elements) -> LitInt(rows + cols)
      |MatrixDim , MatrixFloatLit(rows,cols,elements) -> LitInt(rows + cols)
    (*convert the below in form of basic functions *)
      |MatrixTrans, MatrixIntLit(rows,cols,elements) -> 
        let transposed = List.init cols (fun i -> List.map (fun row -> List.nth row i) elements) in
            MatrixIntLit (cols, rows, transposed)
      |MatrixTrans, MatrixFloatLit(rows,cols,elements) -> 
        let transposed = List.init cols (fun i -> List.map (fun row -> List.nth row i) elements) in
            MatrixFloatLit (cols, rows, transposed)
      (* define these functions*)
      | MatrixDet, MatrixIntLit(rows,cols,elements) when rows = cols->
        LitInt (determinant_int elements)
      | MatrixDet, MatrixFloatLit(rows,cols,elements) when rows = cols->
          LitFloat (determinant_float elements)
      (* |MatrixInverse,MatrixFloatLit(rows,cols,elements) ->
        MatrixFloatLit (rows,cols, inverse_float elements)
      |MatrixInverse,MatrixIntLit(rows,cols,elements) ->
        MatrixFloatLit (rows,cols, inverse_int elements) *)
      | _ -> failwith "Unsupported expression for the unop operation" )
    |Binop (a, command, b) -> 
      let operand1 = eval_expr var_table_value a and operand2 = eval_expr var_table_value b in 
      (match operand1,command,operand2 with 
      |LitInt i ,IntArith op, LitInt j ->
        (match op with
          |Add -> LitInt(i+j)
          |Sub -> LitInt(i-j)
          |Mul -> LitInt(i*j)
          |Pow -> LitInt (int_of_float ((float_of_int i) ** (float_of_int j)))
          |Rem -> LitInt(i mod j)
          |Div -> if j = 0 then failwith "Division by zero" else LitInt (i / j)
          | _ -> failwith "Unsupported expression type for operation on integers")
      |LitFloat i ,FloatArith op,LitFloat j ->
        (match op with
        |Add -> LitFloat(i +. j)
        |Sub -> LitFloat(i-.j)
        |Mul -> LitFloat(i*.j)
        |Pow -> LitFloat (i ** j)
        |Div -> if j = 0. then failwith "Division by zero" else LitFloat (i /. j)
        | _ -> failwith "Unsupported expression type for operations on float")
      |LitInt i , FloatArith op , LitFloat j -> if op = Pow then LitFloat ((float_of_int i) ** j) else   failwith "Unsupported expression type for power operation"
      |LitFloat i , FloatArith op , LitInt j -> if op = Pow then LitFloat (i** (float_of_int j)) else   failwith "Unsupported expression type for power operation"
      (*define these funcctions*)
      |VectorIntLit (dim1, elements1),VectorArith op , VectorIntLit (dim2, elements2)-> 
        (match op with 
        |Add -> VectorIntLit (dim1,vector_int_add elements1 elements2 )
        |Sub -> VectorIntLit (dim1,vector_int_sub elements1 elements2 )
        |Dot -> LitInt(vector_int_dot  elements1 elements2 )
        | _ -> failwith "Unsupported expression type for vector similar operations"  
        )
      |VectorFloatLit (dim1, elements1),VectorArith op , VectorFloatLit (dim2, elements2)-> 
        (match op with 
        |Add -> VectorFloatLit (dim1,vector_float_add  elements1 elements2 )
        |Sub -> VectorFloatLit (dim1,vector_float_sub  elements1 elements2)
        |Dot -> LitFloat(vector_float_dot  elements1 elements2 )
        | _ -> failwith "Unsupported expression type for vector similar opertaions"  
        )
      |VectorFloatLit(dim,elements),VectorArith op,LitFloat f -> if op = Div then VectorFloatLit(dim,vector_float_div  elements f )else  failwith "Unsupported expression type for operation division on vectors"
      |VectorIntLit(dim,elements),VectorArith op,LitInt i -> if op = Div then VectorFloatLit(dim,vector_int_div  elements i ) else  failwith "Unsupported expression type for opertaion division on vectors"
      |VectorIntLit (dim1, elements1),DotProduct , VectorIntLit (dim2, elements2)-> LitInt(vector_int_dot  elements1 elements2 )
      |VectorFloatLit (dim1, elements1),DotProduct , VectorFloatLit (dim2, elements2) ->  LitFloat(vector_float_dot  elements1 elements2 )
      |LitInt i,VectorScalarMult,VectorIntLit (dim, elements) ->  VectorIntLit(dim,vector_int_scalar_mult  i elements )
      (* just remember you have not created it in the ast , you forgot it in the parser*)
      |LitFloat i,VectorScalarMult,VectorFloatLit (dim, elements) ->  VectorFloatLit(dim,vector_float_scalar_mult  i elements )
      |VectorFloatLit(dim1,elements1),AngleFunctionFloat,VectorFloatLit(dim2,elements2) -> 
        let angle = vector_float_angle  elements1 elements2  in
        LitFloat (angle)
      |VectorIntLit(dim1,elements1),AnglefunctionInt,VectorIntLit(dim2,elements2) ->
        let angle = vector_int_angle  elements1 elements2  in
        LitInt (int_of_float angle)
      |MatrixIntLit(rows1,cols1,elements1),MatrixArith op,MatrixIntLit(rows2,cols2,elements2) -> 
        (match op with 
        |Add -> MatrixIntLit (rows1,cols1,matrix_int_add  elements1 elements2 )
        |Sub -> MatrixIntLit (rows1,cols1,matrix_int_sub elements1 elements2 )
        (* |Mul -> MatrixIntLit (rows1,cols1,matrix_int_mul (elements1,elements2)) *)
        | _ -> failwith "Unsupported expression type for matrix similar opertaions"  
        )
      |MatrixFloatLit(rows1,cols1,elements1),MatrixArith op,MatrixFloatLit(rows2,cols2,elements2) ->
        (match op with 
        |Add -> MatrixFloatLit (rows1,cols1,matrix_float_add elements1 elements2 )
        |Sub -> MatrixFloatLit (rows1,cols1,matrix_float_sub  elements1 elements2 )
        (* |Mul -> MatrixFloatLit (rows1,cols1,matrix_float_mul (elements1,elements2)) *)
        | _ -> failwith "Unsupported expression type for matrix ximilar operations"  
        )
      |MatrixIntLit(rows1,cols1,elements1),MatrixMultiply,MatrixIntLit(rows2,cols2,elements2) ->
        if cols1 <> rows2 then failwith "Matrix dimensions do not match for multiplication"
        else
          let result = matrix_int_matrix_mul  elements1 elements2  in
          MatrixIntLit (rows1,cols2,result)
      |MatrixFloatLit(rows1,cols1,elements1),MatrixMultiply,MatrixFloatLit(rows2,cols2,elements2) ->
        if cols1 <> rows2 then failwith "Matrix dimensions do not match for multiplication"
        else
          let result = matrix_float_matrix_mul elements1 elements2 in
          MatrixFloatLit (rows1,cols2,result)
      |LitInt i,MatrixMultiply,MatrixIntLit(rows2,cols2,elements2) ->
        let result = matrix_int_scalar_mult i elements2  in
        MatrixIntLit (rows2,cols2,result)
      |LitFloat i,MatrixMultiply,MatrixFloatLit(rows2,cols2,elements2) ->
        let result = matrix_float_scalar_mult  i elements2 in
        MatrixFloatLit (rows2,cols2,result)
      |MatrixIntLit(rows1,cols1,elements1),MatrixMultiply,VectorIntLit(dim,elements2) ->
        if cols1 <> dim then failwith "Matrix and vector dimensions do not match for multiplication"
        else
          let result = matrix_int_vector_mul elements1 elements2 in
          VectorIntLit (rows1,result)
      |MatrixFloatLit(rows1,cols1,elements1),MatrixMultiply,VectorFloatLit(dim,elements2) ->
        if cols1 <> dim then failwith "Matrix and vector dimensions do not match for multiplication"
        else
          let result = matrix_float_vector_mul elements1 elements2 in
          VectorFloatLit (rows1,result)
      |LitBool b1,Andfunction, LitBool b2 -> if b1 = true && b2 = true then LitBool true else LitBool false
      |LitBool b1,Orfunction, LitBool b2 -> if b1 = true || b2 = true then LitBool true else LitBool false
      |e1,Equality,e2 -> 
        (match e1,e2 with 
        |LitInt i1, LitInt i2 -> if i1 = i2 then LitBool true else LitBool false
        |LitFloat f1, LitFloat f2 -> if f1 = f2 then LitBool true else LitBool false  
        (* |LitBool b1, LitBool b2 -> if b1 = b2 then LitBool true else LitBool false *)
        | _ -> failwith "Unsupported expression type for bool operations"  )
      |e1,Inequality,e2 -> 
        (match e1,e2 with 
        |LitInt i1, LitInt i2 -> if i1 <> i2 then LitBool true else LitBool false
        |LitFloat f1, LitFloat f2 -> if f1 <> f2 then LitBool true else LitBool false  
        (* |LitBool b1, LitBool b2 -> if b1 = b2 then LitBool true else LitBool false *)
        | _ -> failwith "Unsupported expression type for bool opertaions"  )
      |e1,LessThan,e2 -> 
        (match e1,e2 with 
        |LitInt i1, LitInt i2 -> if i1 < i2 then LitBool true else LitBool false
        |LitFloat f1, LitFloat f2 -> if f1 < f2 then LitBool true else LitBool false  
        | _ -> failwith "Unsupported expression type for bool opertaions"  )
      |e1,GreaterThan,e2 -> 
        (match e1,e2 with 
        |LitInt i1, LitInt i2 -> if i1 > i2 then LitBool true else LitBool false
        |LitFloat f1, LitFloat f2 -> if f1 > f2 then LitBool true else LitBool false  
        | _ -> failwith "Unsupported expression type for bool operations"  )
      |e1,LessThanEqual,e2 -> 
        (match e1,e2 with 
        |LitInt i1, LitInt i2 -> if i1 <= i2 then LitBool true else LitBool false
        |LitFloat f1, LitFloat f2 -> if f1 <= f2 then LitBool true else LitBool false  
        | _ -> failwith "Unsupported expression type for bool opertaions"  )
      |e1,GreaterThanEqual,e2 -> 
        (match e1,e2 with 
        |LitInt i1, LitInt i2 -> if i1 >= i2 then LitBool true else LitBool false
        |LitFloat f1, LitFloat f2 -> if f1 >= f2 then LitBool true else LitBool false  
        | _ -> failwith "Unsupported expression type for bool opertaions"  )
      | _ -> failwith "Unsupported expression type for binop opertaions"  )
    | _ -> failwith "Unsupported expression type for eval_expr"

(* Function to evaluate a program *)





let rec eval_cmd var_table_value cmd =
  match cmd with 
  | Assign (id, expr) -> 
    let value = eval_expr var_table_value expr in 
    if Hashtbl.mem var_table_value id then
      Hashtbl.replace var_table_value id value
    else Hashtbl.add var_table_value id value;var_table_value
    (*write these functions*)
  |InputFileAssign(id, typed,filename) ->
    let a = read_from_file filename typed in 
    if Hashtbl.mem var_table_value id then
      Hashtbl.replace var_table_value id a
    else Hashtbl.add var_table_value id a;var_table_value
  |InputAssign(id,typed)->
    let a =read_from_stdin typed in 
    if Hashtbl.mem var_table_value id then
      Hashtbl.replace var_table_value id a
    else Hashtbl.add var_table_value id a;var_table_value
  |Declare(id) ->
    if (Hashtbl.mem var_table id) then
      let default_value =
        (match Hashtbl.find var_table id with 
        |TInt -> LitInt 0
        |TFloat -> LitFloat 0.0
        |TBool -> LitBool false
        |TVectorInt dim -> VectorIntLit(dim,List.init dim (fun _ -> 0))
        |TVectorFloat dim -> VectorFloatLit(dim,List.init dim (fun _ -> 0.0))
        |TMatrixInt (rows,cols) -> MatrixIntLit(rows,cols,List.init rows (fun _ -> List.init cols (fun _ -> 0)) )
        |TMatrixFloat (rows,cols) -> MatrixFloatLit(rows,cols,List.init rows (fun _ -> List.init cols (fun _ -> 0.0)) )
        )
      in Hashtbl.add var_table_value id default_value
    else failwith("Redeclared value and thus cannot be processed"); var_table_value 
  |Printout(id)-> 
    if Hashtbl.mem var_table_value id then 
      print_value (Hashtbl.find var_table_value id) ;var_table_value
  |If(condition,then_commands,else_if_commands)->
    let if_condition = eval_expr var_table_value condition in 
      (match if_condition with 
        |LitBool true-> List.fold_left eval_cmd var_table_value then_commands
        |LitBool false -> 
          (* correct this aprt here for eval of commadn list*)
            let rec run_for_elseifs if_else_commands= 
             ( match if_else_commands with
              |[] -> var_table_value
              |(elseif_condition, commands) :: rest->
                (match eval_expr var_table_value elseif_condition with
                | LitBool true -> List.fold_left eval_cmd var_table_value commands
                | LitBool false -> run_for_elseifs rest
                | _ -> raise (failwith "Elseif condition must be a boolean")  )
              | _ -> failwith "if else if condition must be bool" )
              in run_for_elseifs else_if_commands
        | _ ->  failwith "if else if condition must be bool" )
  |IfElse(condition,then_commands,else_commands)->
    let cond_val = eval_expr var_table_value condition in
     ( match cond_val with
      | LitBool true -> List.fold_left eval_cmd var_table_value then_commands
      | LitBool false -> List.fold_left eval_cmd var_table_value else_commands
      | _ -> raise (failwith "If condition must be a boolean"))
    (* left with for loop , while loop , print and the smaller functions to be defined*)
  |For (id,start,end_expr,iterate_id,iterate_expr,body) ->
    Hashtbl.replace var_table_value id (LitInt start);
    let rec for_loop var_table_val =
      let ending_value = eval_expr var_table_value end_expr in 
       match ending_value with 
       | LitBool true ->
        let new_table = List.fold_left eval_cmd var_table_value body in
        let new_value = eval_expr new_table iterate_expr in
        Hashtbl.replace new_table iterate_id new_value;
        for_loop new_table
       | LitBool false -> var_table_value
       |_ -> raise (failwith "For loop condition must be a boolean")
       in for_loop var_table_value
  |While(condition, commands)->
    let rec while_loop var_table_value=
      let condition_current = eval_expr var_table_value condition in
      match condition_current with 
      |LitBool true -> 
      let new_table = List.fold_left eval_cmd var_table_value commands 
          in while_loop new_table
      |LitBool false -> var_table_value
      |_ -> failwith "While loop condition must be a boolean"
      in while_loop var_table_value
  |Seq(commandList) ->
    List.fold_left eval_cmd var_table_value commandList
  | MatrixAssign (id, a, b, value) ->
    let x = match eval_expr var_table_value a with
      | LitInt i -> i
      | _ -> failwith "Row index must be an integer"
    in
    let y = match eval_expr var_table_value b with
      | LitInt j -> j
      | _ -> failwith "Column index must be an integer"
    in
    (* Check if the matrix exists in the variable table *)
    if Hashtbl.mem var_table_value id then
      match Hashtbl.find var_table_value id with
      | MatrixIntLit (rows, cols, elements) ->
          let v = match eval_expr var_table_value value with
            | LitInt k -> k
            | _ -> failwith "Assigned value must be an integer"
          in
          (* Ensure the indices are within bounds *)
          if x < 0 || x >= rows || y < 0 || y >= cols then
            failwith "Matrix index out of bounds"
          else
            (* Update the matrix element *)
            let updated_elements =
              List.mapi (fun i row ->
                if i = x then
                  List.mapi (fun j elem -> if j = y then v else elem) row
                else row
              ) elements
            in
            (* Store the updated matrix back in the variable table *)
            Hashtbl.replace var_table_value id (MatrixIntLit (rows, cols, updated_elements));var_table_value
      | MatrixFloatLit (rows, cols, elements) ->
          let v = match eval_expr var_table_value value with
            | LitFloat f -> f
            | _ -> failwith "Assigned value must be a float"
          in
          (* Ensure the indices are within bounds *)
          if x < 0 || x >= rows || y < 0 || y >= cols then
            failwith "Matrix index out of bounds"
          else
            (* Update the matrix element *)
            let updated_elements =
              List.mapi (fun i row ->
                if i = x then
                  List.mapi (fun j elem -> if j = y then v else elem) row
                else row
              ) elements
            in
            (* Store the updated matrix back in the variable table *)
            Hashtbl.replace var_table_value id (MatrixFloatLit (rows, cols, updated_elements));var_table_value
      | _ -> failwith "Variable is not a matrix"
    else
        failwith ("Undefined matrix: " ^ id)
  |VectorAssign(id,a,value)->
    let x = match eval_expr var_table_value a with
    | LitInt i -> i
    | _ -> failwith "Row index must be an integer"
  in
  (* Check if the matrix exists in the variable table *)
  if Hashtbl.mem var_table_value id then
    match Hashtbl.find var_table_value id with
    | VectorIntLit (dims, elements) ->
        let v = match eval_expr var_table_value value with
          | LitInt k -> k
          | _ -> failwith "Assigned value must be an integer"
        in
        (* Ensure the indices are within bounds *)
        if x < 0 || x >= dims then
          failwith "Vector index out of bounds"
        else
          (* Update the matrix element *)
          let updated_elements =
            List.mapi (fun i elem ->
              if i = x then v else elem ) elements
          in
          (* Store the updated matrix back in the variable table *)
          Hashtbl.replace var_table_value id (VectorIntLit (dims,updated_elements));var_table_value
    | VectorFloatLit (dims, elements) ->
        let v = match eval_expr var_table_value value with
          | LitFloat f -> f
          | _ -> failwith "Assigned value must be a float"
        in
        (* Ensure the indices are within bounds *)
        if x < 0 || x >= dims then
          failwith "Matrix index out of bounds"
        else
          (* Update the matrix element *)
          let updated_elements =
            List.mapi (fun i elem ->
              if i = x then v else elem
            ) elements
          in
          (* Store the updated matrix back in the variable table *)
          Hashtbl.replace var_table_value id (VectorFloatLit (dims, updated_elements));var_table_value
    | _ -> failwith "Variable is not a matrix"
  else
      failwith ("Undefined matrix: " ^ id)
  |_ ->failwith ("Undefined variable: ")


let rec eval_cmds var_table_value  cmds =
  List.fold_left eval_cmd var_table_value cmds
  