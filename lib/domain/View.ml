exception ViewException

(* the types *)
type label = string
type attribute = string

type t = {
    labels : label list;
    attributes : attribute list;
}

let empty = {
    labels = [];
    attributes = [];
}

let add_attributes attrs view = {
    view with attributes = attrs @ view.attributes
}
let add_labels labels view = {
    view with labels = labels @ view.labels
}

let combine : t list -> t = fun vs ->
    let labels = vs
        |> CCList.flat_map (fun v -> v.labels) 
        |> CCList.uniq ~eq:(=) in
    let attrs = vs
        |> CCList.flat_map (fun v -> v.attributes)
        |> CCList.uniq ~eq:(=) in
    {
        labels = labels;
        attributes = attrs;
    }

let subsample lbls attrs view =
    let lbl_dist = view.labels
        |> CCRandom.choose_return 
        |> CCRandom.sample_without_duplicates ~cmp:CCString.compare lbls in
    let attr_dist = view.attributes
        |> CCRandom.choose_return 
        |> CCRandom.sample_without_duplicates ~cmp:CCString.compare attrs in
    {
        labels = 
            if lbls < (CCList.length view.labels) then 
                if lbls = 0 then [] else CCRandom.run lbl_dist 
            else view.labels;
        attributes =
            if attrs < (CCList.length view.attributes) then
                if attrs = 0 then [] else CCRandom.run attr_dist 
            else view.attributes;
    }


let labels : t -> label list = fun c -> c.labels
let attributes : t -> attribute list = fun c -> c.attributes

let of_json : Yojson.Basic.t -> t option = fun json ->
    let labels = json
        |> Utility.JSON.get
            "labels"
            (Utility.JSON.list Utility.JSON.string) in
    let attributes = json
        |> Utility.JSON.get
            "attributes"
            (Utility.JSON.list Utility.JSON.string) in
    match labels, attributes with
        | Some labels, Some attributes -> Some
            {
                labels = labels;
                attributes = attributes;
            }
        | _ -> None

(* loading from file *)
let from_file : string -> t = fun filename -> filename
    |> Yojson.Basic.from_file
    |> of_json
    |> CCOpt.get_exn

(* makes assumptions about where views are stored *)
let of_string : string -> t = fun view_name ->
    Printf.sprintf "./views/%s.json" view_name |> from_file