(* Exception definitions for type errors and general exceptions *)
exception TypeError of string
exception Exception

(* Importing Hashtbl for variable table management *)


open Hashtbl 
(* Type definitions *)  
type typ =
  | TInt  (* Integer type *)
  | TFloat  (* Float type *)
  | TBool  (* Boolean type *)
  | TVectorInt of int  (* Integer vector with a specific dimension *)
  | TVectorFloat of int  (* Float vector with a specific dimension *)
  | TMatrixInt of int * int  (* Integer matrix with rows and columns *)
  | TMatrixFloat of int * int  (* Float matrix with rows and columns *)


(* Variable table to store variable names and their types *)
let var_table : (string, typ) Hashtbl.t = Hashtbl.create 100

(* Literal definitions for constants *)
type return_literal =
  | LitInt of int  (* Integer literal *)
  | LitFloat of float  (* Float literal *)
  | LitBool of bool  (* Boolean literal *)


(* Expression definitions for supported operations and constructs *)
type return_expr =
  | Var of string  (* Variable reference *)
  | LitInt of int  (* Integer literal *)
  | LitFloat of float  (* Float literal *)
  | LitBool of bool  (* Boolean literal *)
  | Binop of return_expr * return_binop * return_expr  (* Binary operation *)
  | Unop of return_unop * return_expr  (* Unary operation *)
  | VectorIntLit of int * int list  (* Integer vector literal with dimension and values *)
  | VectorFloatLit of int * float list  (* Float vector literal with dimension and values *)
  | MatrixIntLit of int * int * int list list  (* Integer matrix literal with rows, columns, and values *)
  | MatrixFloatLit of int * int * float list list  (* Float matrix literal with rows, columns, and values *)
  | MatrixRef of string * return_expr * return_expr  (* Matrix element reference *)
  | VectorRef of string * return_expr  (* Vector element reference *)
  | Minor of string * return_expr * return_expr  (* Minor matrix calculation *)


(* Unary operation definitions *)
and return_unop =
  | Ang | Determinant | Mag | Dim | Trans | Not | Abs | IntAbs | FloatAbs | Sqrt | IntSqrt | FloatSqrt 
  (* | Inverse | MatrixInverse *)
  | Neg  (* Negation *)
  | IntNeg  (* Integer negation *)
  | FloatNeg  (* Float negation *)
  | BoolNot  (* Boolean negation *)
  | VectorMag  (* Magnitude of a vector *)
  | VectorDim  (* Dimension of a vector *)
  | MatrixTrans  (* Transpose of a matrix *)
  | MatrixDet  (* Determinant of a matrix *)
  | MatrixDim  (* Dimension of a matrix *)
  | MatrixMag  (* Magnitude of a matrix *)

(* Binary operation definitions *)
and return_binop =
  | Eq | Neq | Lt | Gt | Leq | Geq | And | Or | Ang | Pow |Rem
  | Add | Sub | Mul | Div | Dot
  | AnglefunctionInt | AngleFunctionFloat
  | IntArith of return_binop  (* Integer arithmetic *)
  | FloatArith of return_binop  (* Float arithmetic *)
  | VectorArith of return_binop  (* Vector arithmetic *)
  | MatrixArith of return_binop  (* Matrix arithmetic *)
  | DotProduct  (* Dot product of vectors *)
  | VectorScalarMult  (* Scalar multiplication with a vector *)
  | MatrixMultiply  (* Matrix multiplication *)
  | Equality  (* Equality comparison *)
  | Inequality  (* Inequality comparison *)
  | LessThan  (* Less than comparison *)
  | GreaterThan  (* Greater than comparison *)
  | LessThanEqual  (* Less than or equal comparison *)
  | GreaterThanEqual  (* Greater than or equal comparison *)
  | Andfunction  (* Logical AND *)
  | Orfunction  (* Logical OR *)


(* Command definitions for supported statements *)
type return_cmd =
  | Assign of string * return_expr  (* Variable assignment *)
  | InputFileAssign of string * typ * string  (* Input file assignment *)
  | InputAssign of string * typ  (* Input assignment *)
  | Declare of string  (* Variable declaration *)
  | If of return_expr * return_cmd list * (return_expr * return_cmd list) list  (* If statement with optional elseif clauses *)
  | IfElse of return_expr * return_cmd list * return_cmd list  (* If-else statement *)
  | While of return_expr * return_cmd list  (* While loop *)
  | For of string * int * return_expr * string * return_expr * return_cmd list  (* For loop *)
  | InputFile of string  (* Input file command *)
  | Input  (* Input command *)
  | Printout of string  (* Printout command *)
  | Print  (* Print command *)
  | Seq of return_cmd list  (* Sequence of commands *)
  | VectorAssign of string * return_expr * return_expr  (* Assign to vector element *)
  | MatrixAssign of string * return_expr * return_expr * return_expr  (* Assign to matrix element *)

(* Program is a list of commands *)
type program = return_cmd list
  
  (* Type checking function *)

let rec type_of var_table env = 
  match env with
  | LitInt _ -> TInt
  | LitFloat _ -> TFloat
  | LitBool _ -> TBool
  | VectorIntLit (dim, _) -> TVectorInt(dim)
  | VectorFloatLit(dim, _) -> TVectorFloat(dim)
  | MatrixIntLit(rows, cols, _) -> TMatrixInt(rows, cols)
  | MatrixFloatLit(rows, cols, _) -> TMatrixFloat(rows, cols)
  | Minor (name, a, b) -> 
    let matrix_type = Hashtbl.find var_table name in
    (match matrix_type with
    | TMatrixInt(rows, cols) ->
        (* Check that row and col are integers *)
        (match type_of var_table a, type_of var_table b with
        | TInt, TInt -> TMatrixInt(rows-1,cols-1)
        | _ -> raise (TypeError "Matrix indices must be integers"))
    | TMatrixFloat(rows, cols) ->
        (* Check that row and col are integers *)
        (match type_of var_table a, type_of var_table b with
        | TInt, TInt -> TMatrixFloat(rows-1,cols-1)
        | _ -> raise (TypeError "Matrix indices must be integers"))
    | _ -> raise (TypeError "Variable is not a matrix"))
  | MatrixRef(name, a, b) -> 
    let matrix_type = Hashtbl.find var_table name in
    (match matrix_type with
    | TMatrixInt(rows, cols) ->
        (* Check that row and col are integers *)
        (match type_of var_table a, type_of var_table b with
        | TInt, TInt -> TInt
        | _ -> raise (TypeError "Matrix indices must be integers"))
    | TMatrixFloat(rows, cols) ->
        (* Check that row and col are integers *)
        (match type_of var_table a, type_of var_table b with
        | TInt, TInt -> TFloat
        | _ -> raise (TypeError "Matrix indices must be integers"))
    | _ -> raise (TypeError "Variable is not a matrix"))
  | VectorRef(name, a) -> 
    let vector_type = Hashtbl.find var_table name in
    (match vector_type with
    | TVectorInt _->
        (* Check that index are integers *)
        (match type_of var_table a with
        | TInt -> TInt
        | _ -> raise (TypeError "Matrix indices must be integers"))
    | TMatrixFloat _ ->
        (* Check that row  index  are integers *)
        (match type_of var_table a with
        | TInt -> TFloat
        | _ -> raise (TypeError "Matrix indices must be integers"))
    | _ -> raise (TypeError "Variable is not a matrix"))
  | Var name -> Hashtbl.find var_table name 
  | Binop(e1, op, e2) -> 
    let t1 = type_of var_table e1 and t2 = type_of var_table e2 in
    (match op, t1, t2 with
        | (Rem |IntArith Rem) ,TInt,TInt -> TInt
        | (Add | Sub |IntArith Add | IntArith Sub |Pow |IntArith Pow |Mul | IntArith Mul), TInt, TInt -> TInt
        | (Add | Sub |FloatArith Add |FloatArith Sub|Pow|FloatArith Pow ), TFloat, TFloat -> TFloat
        | (Div | FloatArith Div), TInt, TInt -> TFloat
        | (Mul | Div | FloatArith Mul |FloatArith Div), TFloat, TFloat -> TFloat
        | (Div | VectorArith Div), TVectorFloat(dim),TFloat ->  TVectorFloat(dim)
        | (Div | VectorArith Div), TVectorInt(dim),TInt ->  TVectorFloat(dim)
        | (Pow |FloatArith Pow), TInt, TFloat -> TFloat
        | (Pow| FloatArith Pow), TFloat, TInt -> TFloat
        | (Add | Sub |VectorArith Add | VectorArith Sub), TVectorInt(dim1), TVectorInt(dim2) -> if dim1 == dim2 then TVectorInt(dim1) else raise (TypeError "Dimension mismatch")
        | (Add | Sub |VectorArith Add | VectorArith Sub), TVectorFloat(dim1), TVectorFloat(dim2) -> if dim1 == dim2 then TVectorFloat(dim1) else raise (TypeError "Dimension mismatch")
        | (Add | Sub |MatrixArith Add | MatrixArith Sub), TMatrixInt(rows1, cols1), TMatrixInt(rows2, cols2) -> if rows1 == rows2 && cols1 == cols2 then TMatrixInt(rows1, cols1) else raise (TypeError "Dimension mismatch")
        | (Add | Sub |MatrixArith Add | MatrixArith Sub), TMatrixFloat(rows1, cols1), TMatrixFloat(rows2, cols2) -> if rows1 == rows2 && cols1 == cols2 then TMatrixFloat(rows1, cols1) else raise (TypeError "Dimension mismatch")
        | (MatrixArith Div | Div),TMatrixInt(rows1, cols1),TInt -> TMatrixFloat(rows1, cols1)
        | (MatrixArith Div | Div),TMatrixFloat(rows1, cols1),TFloat -> TMatrixFloat(rows1, cols1)
        | (Dot | DotProduct ), TVectorInt(dim1), TVectorInt(dim2) -> if dim1 == dim2 then TInt else raise (TypeError "Dimension mismatch")
        | (Dot | DotProduct ), TVectorFloat(dim1), TVectorFloat(dim2) -> if dim1 == dim2 then TFloat else raise (TypeError "Dimension mismatch")
        | (Mul| VectorScalarMult), TInt, TVectorInt(dim) -> TVectorInt(dim)
        | (Mul| VectorScalarMult), TFloat, TVectorFloat(dim) -> TVectorFloat(dim)
        | (Mul | MatrixMultiply), TMatrixInt(rows1, cols1), TMatrixInt(rows2, cols2) -> if cols1 == rows2 then TMatrixInt(rows1, cols2) else raise (TypeError "Dimension mismatch")
        | (Mul | MatrixMultiply), TMatrixFloat(rows1, cols1), TMatrixFloat(rows2, cols2) -> if cols1 == rows2 then TMatrixFloat(rows1, cols2) else raise (TypeError "Dimension mismatch")
        | (Mul| MatrixMultiply), TInt,TMatrixInt(rows1, cols1) -> TMatrixInt(rows1, cols1)
        | (Mul| MatrixMultiply), TFloat, TMatrixFloat(rows1, cols1) -> TMatrixFloat(rows1, cols1)
        | (Mul | MatrixMultiply), TMatrixInt(rows1, cols1),TVectorInt(dim) -> if cols1 == dim then TVectorInt(rows1) else raise (TypeError "Dimension mismatch")
        | (Mul | MatrixMultiply), TMatrixFloat(rows1, cols1), TVectorFloat(dim) -> if cols1 == dim then TVectorFloat(rows1) else raise (TypeError "Dimension mismatch")
        | (Eq |Equality), t1, t2 -> if t1 == t2 then TBool else raise (TypeError "Type mismatch")
        | (Neq | Inequality), t1, t2 -> if t1 == t2 then TBool else raise (TypeError "Type mismatch")
        | (Lt | LessThan), t1, t2 -> if t1 == t2 then TBool else raise (TypeError "Type mismatch")
        | (Gt | GreaterThan), t1, t2 -> if t1 == t2 then TBool else raise (TypeError "Type mismatch")
        | (Leq | LessThanEqual), t1, t2 -> if t1 == t2 then TBool else raise (TypeError "Type mismatch")
        | (Geq | GreaterThanEqual), t1, t2 -> if t1 == t2 then TBool else raise (TypeError "Type mismatch")
        | (And | Andfunction), TBool, TBool -> TBool
        | (Or| Orfunction), TBool, TBool -> TBool
        | (Ang | AnglefunctionInt), TVectorInt(dim1), TVectorInt(dim2) -> if dim1 == dim2 then TInt else raise (TypeError "Dimension mismatch")
        | (Ang |AngleFunctionFloat), TVectorFloat(dim1), TVectorFloat(dim2) -> if dim1 == dim2 then TFloat else raise (TypeError "Dimension mismatch")
        | _ -> raise (TypeError "Invalid operands"))
  | Unop(op, e) -> 
    let t = type_of var_table e in
    (match op, t with
    (* | (Inverse|MatrixInverse), TMatrixInt(cols, rows) ->  TMatrixFloat(cols, rows)
    | (Inverse|MatrixInverse), TMatrixFloat(cols, rows) ->  TMatrixFloat(cols, rows) *)
    | (Sqrt| IntSqrt|FloatSqrt), TInt -> TFloat
    | (Sqrt| IntSqrt|FloatSqrt), TFloat -> TFloat
    | (Abs| IntAbs), TInt -> TInt
    | (Abs| FloatAbs), TFloat -> TFloat
    | (Neg| IntNeg), TInt -> TInt
    | (Neg| FloatNeg), TFloat -> TFloat
    | (Not| BoolNot), TBool -> TBool
    | (Mag|VectorMag), TVectorInt(_) -> TFloat
    | (Mag|VectorMag), TVectorFloat(_) -> TFloat
    | (Mag|MatrixMag), TMatrixInt(_,_) -> TFloat
    | (Mag|MatrixMag), TMatrixFloat(_,_) -> TFloat
    | (Dim|VectorDim), TVectorInt(_) -> TInt
    | (Dim| VectorDim), TVectorFloat(_) -> TInt
    | (Dim|MatrixDim), TMatrixInt(_,_) -> TInt
    | (Dim|MatrixDim), TMatrixFloat(_,_) -> TInt
    | (Trans |MatrixTrans), TMatrixInt(rows, cols) -> TMatrixInt(cols, rows)
    | (Trans|MatrixTrans), TMatrixFloat(rows, cols) -> TMatrixFloat(cols, rows)
    | (Determinant| MatrixDet), TMatrixInt(_,_) -> TInt
    | (Determinant | MatrixDet), TMatrixFloat(_,_) -> TFloat
    | _ -> raise (TypeError "invalid operand"))
  



(* Type checking integration *)
let check_binop op e1 e2 =
  let check_binop1 op t1 t2 =
    match op, t1, t2 with
    | (Add | Sub |Pow |Rem), TInt, TInt -> Binop(e1, IntArith op, e2)
    | (Add | Sub | Pow), TFloat, TFloat -> Binop(e1, FloatArith op, e2)
    | Pow, TInt, TFloat -> Binop(e1, FloatArith op, e2)
    | Pow, TFloat, TInt -> Binop(e1, FloatArith op, e2)
    | (Add | Sub), TVectorInt(dim1), TVectorInt(dim2) -> if dim1 == dim2 then Binop(e1, VectorArith op, e2) else raise (TypeError "Dimension mismatch")
    | (Add | Sub), TVectorFloat(dim1), TVectorFloat(dim2) -> if dim1 == dim2 then Binop(e1, VectorArith op, e2) else raise (TypeError "Dimension mismatch")
    | (Add | Sub), TMatrixInt(rows1, cols1), TMatrixInt(rows2, cols2) -> if rows1 == rows2 && cols1 == cols2 then Binop(e1, MatrixArith op, e2) else raise (TypeError "Dimension mismatch")
    | (Add | Sub), TMatrixFloat(rows1, cols1), TMatrixFloat(rows2, cols2) -> if rows1 == rows2 && cols1 == cols2 then Binop(e1, MatrixArith op, e2) else raise (TypeError "Dimension mismatch")
    | (Mul | Div), TInt, TInt -> Binop(e1, IntArith op, e2)
    | (Mul | Div), TFloat, TFloat -> Binop(e1, FloatArith op, e2)
    | Div , TVectorFloat(dim),TFloat ->  Binop(e1, VectorArith op, e2)
    | Div , TVectorInt(dim),TInt ->   Binop(e1, VectorArith op, e2)
    | Dot, TVectorInt(dim1), TVectorInt(dim2) -> if dim1 == dim2 then Binop(e1, DotProduct, e2) else raise (TypeError "Dimension mismatch")
    | Dot, TVectorFloat(dim1), TVectorFloat(dim2) -> if dim1 == dim2 then Binop(e1, DotProduct, e2) else raise (TypeError "Dimension mismatch")
    (* this line is added now*)
    | Mul, TFloat,TVectorFloat(_) -> Binop(e1, VectorScalarMult, e2)
    | Mul, TInt, TVectorInt(_) -> Binop(e1, VectorScalarMult, e2)
    | Mul, TMatrixInt(rows1, cols1), TMatrixInt(rows2, cols2) -> if cols1 == rows2 then Binop(e1, MatrixMultiply, e2) else raise (TypeError "Dimension mismatch")
    | Mul, TMatrixFloat(rows1, cols1), TMatrixFloat(rows2, cols2) -> if cols1 == rows2 then Binop(e1, MatrixMultiply, e2) else raise (TypeError "Dimension mismatch")
    | Mul, TInt,TMatrixInt(rows1, cols1) -> Binop(e1, MatrixMultiply, e2)
    | Mul, TFloat, TMatrixFloat(rows1, cols1) ->Binop(e1, MatrixMultiply, e2)
    | Mul, TMatrixInt(rows1, cols1),TVectorInt(dim) -> if cols1 == dim then Binop(e1, MatrixMultiply, e2) else raise (TypeError "Dimension mismatch")
    | Mul, TMatrixFloat(rows1, cols1), TVectorFloat(dim) -> if cols1 == dim then Binop(e1, MatrixMultiply, e2) else raise (TypeError "Dimension mismatch")
    | Eq, t1, t2 -> if t1 == t2 then Binop(e1, Equality, e2) else raise (TypeError "Type mismatch")
    | Neq, t1, t2 -> if t1 == t2 then Binop(e1, Inequality, e2) else raise (TypeError "Type mismatch")
    | Lt, t1, t2 -> if t1 == t2 then Binop(e1, LessThan, e2) else raise (TypeError "Type mismatch")
    | Gt, t1, t2 -> if t1 == t2 then Binop(e1, GreaterThan, e2) else raise (TypeError "Type mismatch")
    | Leq, t1, t2 -> if t1 == t2 then Binop(e1, LessThanEqual, e2) else raise (TypeError "Type mismatch")
    | Geq, t1, t2 -> if t1 == t2 then Binop(e1, GreaterThanEqual, e2) else raise (TypeError "Type mismatch")
    | And, TBool, TBool -> Binop(e1, Andfunction, e2)
    | Or, TBool, TBool -> Binop(e1, Orfunction, e2)
    | Ang, TVectorInt(dim1), TVectorInt(dim2) -> if dim1 == dim2 then Binop(e1, AnglefunctionInt, e2) else raise (TypeError "Dimension mismatch")
    | Ang, TVectorFloat(dim1), TVectorFloat(dim2) -> if dim1 == dim2 then Binop(e1, AngleFunctionFloat, e2) else raise (TypeError "Dimension mismatch")
    | _ -> raise (TypeError ("Invalid operands for " ))
  in check_binop1 op (type_of var_table e1) (type_of var_table e2)


let check_unop op e =
  let t = type_of var_table e in
  match op, t with
    (* |Inverse,TMatrixInt(_,_) -> Unop(MatrixInverse, e)
    |Inverse,TMatrixFloat(_,_) -> Unop(MatrixInverse, e) *)
    | Sqrt, TInt -> Unop(IntSqrt, e)
    | Sqrt, TFloat -> Unop(FloatSqrt, e)
    | Abs, TInt -> Unop(IntAbs, e)
    | Abs, TFloat -> Unop(FloatAbs, e)
    | Neg, TInt -> Unop(IntNeg, e)
    | Neg, TFloat -> Unop(FloatNeg, e)
    | Not, TBool -> Unop(BoolNot, e)
    | Mag, TVectorInt(_) -> Unop(VectorMag, e)
    | Mag, TVectorFloat(_) -> Unop(VectorMag, e)
    | Mag, TMatrixInt(_,_) -> Unop(MatrixMag, e)
    | Mag, TMatrixFloat(_,_) -> Unop(MatrixMag, e)
    | Dim, TVectorInt(_) -> Unop(VectorDim, e)
    | Dim, TVectorFloat(_) -> Unop(VectorDim, e)
    | Dim, TMatrixInt(_,_) -> Unop(MatrixDim, e)
    | Dim, TMatrixFloat(_,_) -> Unop(MatrixDim, e)
    | Trans, TMatrixInt(_,_) -> Unop(MatrixTrans, e)
    | Trans, TMatrixFloat(_,_) -> Unop(MatrixTrans, e)
    | Determinant, TMatrixInt(_,_) -> Unop(MatrixDet, e)
    | Determinant, TMatrixFloat(_,_) -> Unop(MatrixDet, e)
    | _ -> raise (TypeError "Invalid operand")



let rec string_of_return_expr = function 
| Var v ->  Printf.sprintf "Var(%s)" v
| LitInt i -> Printf.sprintf "Int(%d)" i
| LitFloat f -> Printf.sprintf "Float(%f)" f
| LitBool b -> Printf.sprintf "Bool(%b)" b
| MatrixRef (name, a, b) -> Printf.sprintf "MatrixRef(%s, %s, %s)" name (string_of_return_expr a) (string_of_return_expr b)
| VectorRef (name, a) -> Printf.sprintf "VectorRef(%s, %s)" name (string_of_return_expr a)
| Minor(name,a,b) ->  Printf.sprintf "MatrixMinor(%s, %s, %s)" name (string_of_return_expr a) (string_of_return_expr b)
| Binop (e1,op,e2) -> Printf.sprintf "Binop(%s, %s, %s)" 
(string_of_return_binop op) 
(string_of_return_expr e1) 
(string_of_return_expr e2)
| Unop (op ,e) -> Printf.sprintf "Unop(%s, %s)" 
(string_of_return_unop op) 
(string_of_return_expr e)
| VectorIntLit (_,il) -> "VectorInt[" ^ String.concat ", " (List.map string_of_int il) ^ "]"
| VectorFloatLit  (_,fl) -> "VectorFloat[" ^ String.concat ", " (List.map string_of_float fl) ^ "]"
| MatrixIntLit (_,_,ill) -> "MatrixInt[" ^ String.concat ", " (List.map (fun row -> "[" ^ String.concat ", " (List.map string_of_int row) ^ "]" ) ill ) ^"]"
| MatrixFloatLit (_,_,fll )-> "MatrixFLoat[" ^ String.concat ", " (List.map (fun row1-> "[" ^ String.concat ", " (List.map string_of_float row1)^ "]" ) fll ) ^"]"

and string_of_return_binop = function 
| Pow -> "Pow"
| Add -> "Add"
| Sub -> "Sub"
| Mul -> "mult"
| Div -> "div"
| Dot -> "dot"
| AnglefunctionInt -> "angle"
| AngleFunctionFloat -> "angle"
| IntArith rb -> string_of_return_binop rb
| FloatArith rb -> string_of_return_binop rb
| VectorArith rb -> string_of_return_binop rb
| MatrixArith rb -> string_of_return_binop rb
| DotProduct -> "dot"
| VectorScalarMult -> "dot"
| MatrixMultiply -> "MULT"
| Equality -> "EQ"
| Inequality -> "NEQ"
| LessThan -> "LT"
| GreaterThan -> "GT"
| LessThanEqual -> "GTEQ"
| GreaterThanEqual -> "LTEQ"
| Andfunction -> "AND"
| Orfunction -> "OR"
| Rem -> "REM"
| _ -> raise Exception



and string_of_return_unop = function
  | IntSqrt -> "sqrt"
  | FloatSqrt -> "sqrt"
  | IntNeg -> "-"
  | FloatNeg -> "-"
  | BoolNot -> "not"
  | VectorMag -> "mag"
  | VectorDim -> "dim"
  | MatrixTrans -> "trans"
  | MatrixDet -> "Det"
  | MatrixDim -> "dim"
  | IntAbs -> "abs"
  | FloatAbs -> "abs"
  | MatrixMag -> "mag"
  (* | MatrixInverse -> "inverse" *)
  | _ -> "wrong"


let rec string_of_typ = function
| TInt -> "int"
| TFloat -> "float"
| TBool -> "bool"
| TVectorInt dim -> Printf.sprintf "vector_int(%d)" dim
| TVectorFloat dim -> Printf.sprintf "vector_float(%d)" dim
| TMatrixInt (rows, cols) -> Printf.sprintf "matrix_int(%d, %d)" rows cols
| TMatrixFloat (rows, cols) -> Printf.sprintf "matrix_float(%d, %d)" rows cols




let rec string_of_return_cmd = function
| Assign (v, e) -> Printf.sprintf "Assign(%s, %s)" v (string_of_return_expr e)
| VectorAssign(v,i,e)-> Printf.sprintf "VectorAssign(%s[%s],%s)" v (string_of_return_expr i) (string_of_return_expr e)
| MatrixAssign(v,i,j,e)-> Printf.sprintf "MatrixAssign(%s[%s,%s],%s)" v (string_of_return_expr i) (string_of_return_expr j) (string_of_return_expr e)
| InputFileAssign (v, t, f) -> Printf.sprintf "InputFileAssign(%s, %s, %s)" v (string_of_typ t) f
| InputAssign (v, t) -> Printf.sprintf "InputAssign(%s, %s)" v (string_of_typ t)
| Declare v -> Printf.sprintf "Declare(%s)" v
| If (e, cmds1, elseif_cmds) -> 
  Printf.sprintf "If(%s, [%s], [%s])" 
  (string_of_return_expr e) 
  (string_of_return_cmds cmds1) 
  (String.concat "; " 
    (List.map (fun (cond, cmds) -> 
      Printf.sprintf "(%s, [%s])" 
        (string_of_return_expr cond) 
        (string_of_return_cmds cmds)) elseif_cmds))
| IfElse (e, cmds1, cmds2) -> 
  Printf.sprintf "IfElse(%s, [%s], [%s])" 
  (string_of_return_expr e) 
  (string_of_return_cmds cmds1) 
  (string_of_return_cmds cmds2)
| While (e, cmds) -> 
    "while (" ^ string_of_return_expr e ^ ") {\n" ^ string_of_return_cmds cmds ^ "\n}"
| For (v, e1, e2, v2, e3, cmds) -> 
    "for (" ^ v ^ " = " ^ string_of_int e1 ^ "; " ^ string_of_return_expr e2 ^ "; " ^ v2 ^ " = " ^ string_of_return_expr e3 ^ ") {\n" ^ string_of_return_cmds cmds ^ "\n}"
| InputFile f -> "input_file " ^ f
| Input -> "Input()"
| Printout e -> "print(" ^ e ^ ")"
| Print -> "Print()"
| Seq cmds -> Printf.sprintf "Seq([%s])" (string_of_return_cmds cmds)

and string_of_return_cmds cmds = String.concat ";\n" (List.map string_of_return_cmd cmds)

let string_of_prog cmds = string_of_return_cmds cmds
