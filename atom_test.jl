using Test

include("./atom.jl")

@test make_atom(
    "d",
    Dict("a" => Set(["b", "c"]), "b" => Set(["d"]), "c" => Set(["d"])),
    Dict("b" => Set(["a"]), "c" => Set(["a"]), "d" => Set(["b", "c"])),
) == Set([
    Ortho(["a" "b"; "c" "d"], ["a", "c"], ["b", "d"], Set{String}[Set(["a"]), Set(["c", "b"]), Set(["d"])]),
    Ortho(["a" "c"; "b" "d"], ["a", "b"], ["c", "d"], Set{String}[Set(["a"]), Set(["c", "b"]), Set(["d"])]),
])
