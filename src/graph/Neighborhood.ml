open Sig

module Make (G : SemanticGraph) : Neighborhood with
    type vertex = G.vertex and
    type edge = G.edge and
    type graph = G.t
= struct
    module VertexSet = CCSet.Make(G.Vertex)

    type t = VertexSet.t
    type vertex = G.vertex
    type edge = G.edge
    type graph = G.t

    let mem n vertex = VertexSet.mem vertex n
    let to_list n = VertexSet.to_list n

    let starts_in n edge = mem n (G.Edge.source edge)
    let ends_in n edge = mem n (G.Edge.destination edge)
    let mem_edge n edge = (starts_in n edge) && (ends_in n edge)

    let one_hop vertex graph =
        let ins = G.in_edges graph vertex |> CCList.map (G.Edge.source) in
        let outs = G.out_edges graph vertex |> CCList.map (G.Edge.destination) in
        VertexSet.of_list (ins @ outs)
        
    let rec n_hop n vertex graph = if n <= 1 then one_hop vertex graph else
        let neighborhood = to_list (n_hop (n - 1) vertex graph) in
        let ins = neighborhood
            |> CCList.flat_map (G.in_edges graph)
            |> CCList.map G.Edge.source in
        let outs = neighborhood
            |> CCList.flat_map (G.out_edges graph)
            |> CCList.map G.Edge.destination in
        VertexSet.of_list (ins @ outs)

    let n_hop_subgraph n vertex graph =
        let neighborhood = n_hop n vertex graph in
        let vertices = to_list neighborhood in
        let edges = G.edges graph
            |> CCList.filter (mem_edge neighborhood) in
        let subgraph = CCList.fold_left (fun g -> fun v -> match G.label g v with
            | Some label -> G.add_labeled_vertex g v label
            | None -> G.add_vertex g v
        ) G.empty vertices in
        CCList.fold_left G.add_edge subgraph edges
end