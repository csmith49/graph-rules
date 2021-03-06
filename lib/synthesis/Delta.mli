type change = [
    | `Keep
    | `Remove
    | `Weaken of Matcher.Filter.t
]

type vertex = Core.Identifier.t
type edge = vertex * Matcher.Kinder.t * vertex

type index =
    | V of vertex
    | E of edge
type t

(** get the history of changes *)
val changes : t -> (index * change) list

(** add a change safely *)
val add_change : t -> (index * change) -> t option
val add_changes : t -> (index * change) list -> t option

(** get the base motif *)
val motif : t -> Matcher.Motif.t

(** make from a motif *)
val initial : Matcher.Motif.t -> t

(** convert to a motif by applying changes *)
val concretize : t -> Matcher.Motif.t

(** check if we can extend the delta at all *)
val is_total : t -> bool

(** refine a delta to more deltas *)
val refine : t -> t list

(** {1 Partial Order} *)
module PartialOrder : sig
    val entry_eq : (index * change) -> (index * change) -> bool

    val leq : t -> t -> bool
    val equal : t -> t -> bool
end