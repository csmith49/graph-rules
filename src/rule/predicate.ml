(* predicates are filters applied to particular attributes *)

module Clause : (sig
    type t
    val clause : string -> Filter.t -> t
    val attribute : t -> string
    val filter : t -> Filter.t
    val to_string : t -> string
    val apply : t -> Value.Map.t -> bool
    val to_json : t -> JSON.t
    val of_json : JSON.t -> t option
end) = struct
    type t = {
        attribute : string;
        filter : Filter.t;
    }

    let clause s f = {
        attribute = s;
        filter = f;
    }

    let attribute c = c.attribute
    let filter c = c.filter

    let to_string c = Printf.sprintf "%s @ %s" (Filter.to_string c.filter) (c.attribute)

    let apply c m = match Value.Map.get c.attribute m with
        | Some value -> Filter.apply c.filter value
        | _ -> false

    let to_json c = `Assoc [
        ("attribute", `String c.attribute);
        ("filter", Filter.to_json c.filter)
    ]
    let of_json json =
        let attribute = json
            |> JSON.assoc "attribute"
            |> CCOpt.flat_map JSON.to_string_lit in
        let filter = json
            |> JSON.assoc "filter"
            |> CCOpt.flat_map Filter.of_json in
        match attribute, filter with
            | Some attr, Some f -> Some {
                attribute = attr;
                filter = f;
            }
            | _ -> None
end

type t = Clause.t list

let to_string p = p
    |> CCList.map Clause.to_string
    |> CCString.concat " & "

let apply p m = p |> CCList.for_all (fun c -> Clause.apply c m)

let select_clause p i = CCList.nth_opt p i |> CCOpt.map CCList.return

(* json manipulation *)
let to_json p =
    let clauses = p
        |> CCList.map Clause.to_json in
    `List clauses
let of_json json = json
    |> JSON.flatten_list
    |> CCList.map Clause.of_json
    |> CCOpt.sequence_l