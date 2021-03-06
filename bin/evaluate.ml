let output_file = ref ""
let problem_file = ref ""
let motif_file = ref ""

let spec_list = [
    ("--problem", Arg.Set_string problem_file, "Problem declaration file");
    ("--output", Arg.Set_string output_file, "Output file");
    ("--motifs", Arg.Set_string motif_file, "Synthesized motifs");
]

let usage_msg = "Motif Evaluation for Hera"
let _ = Arg.parse spec_list print_endline usage_msg

let _ = print_endline "Starting evaluation..."

(* load the problem file and get the filepaths to evaluate *)
let _ = print_string "Loading files..."
let files = !problem_file
    |> Yojson.Basic.from_file
    |> Domain.Problem.of_json
    |> CCOpt.map Domain.Problem.files
    |> CCOpt.get_exn
let num_files = CCList.length files
let _ = Printf.printf "found %d files.\n" num_files

(* load the motifs *)
let _ = print_string "Loading motifs..."
let motifs = !motif_file
    |> Yojson.Basic.from_file
    |> Utility.JSON.list Matcher.Motif.of_json
    |> CCOpt.get_exn
let _ = Printf.printf "found %d motifs.\n" (CCList.length motifs)

(* now build the sparse image *)
let _ = print_endline "Building image..."
let sparse_image = ref (Domain.SparseImage.of_motifs motifs)
let _ = CCList.iteri (fun i -> fun filename ->
    let _ = Printf.printf "Evaluating %s (%d/%d)\n%!" filename i num_files in
    let db = Domain.SQL.of_string filename in
    let images = CCList.map (Domain.SQL.evaluate db) motifs in
    let _ = Domain.SQL.close db in
    sparse_image := Domain.SparseImage.add_results filename images !sparse_image
) files
let _ = Yojson.Basic.to_file !output_file (Domain.SparseImage.to_json !sparse_image)
let _ = Printf.printf "...done. Output written to %s\n" !output_file