(* simple wrapper around yojson, with utility functions for converting to/from *)

(* base type, so we don't have to write two periods every time *)
type t = Yojson.Basic.t

exception JSONFileError of string

(* file-based io *)
let from_file : string -> t = fun filename ->
    try Yojson.Basic.from_file filename
    with _ -> raise (JSONFileError (Printf.sprintf "JSON file %s not found" filename))
let to_file : string -> t -> unit = Yojson.Basic.to_file

(* utility functions *)
let assoc : string -> t -> t option = fun key -> function
    | `Assoc ls -> ls |> CCList.assoc_opt ~eq:CCString.equal key
    | _ -> None
let of_assoc : (string * t) list -> t = fun ls -> `Assoc ls

let flatten_list : t -> t list = function
    | `List ls -> ls
    | _ -> []
let of_list : t list -> t = fun ls -> `List ls

(* casting to ocaml literals *)
let to_string_lit : t -> string option = function
    | `String s -> Some s
    | _ -> None