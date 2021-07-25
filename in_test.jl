using Test

include("./in.jl")

Ortho(
    ["a" "b" "e"; "c" "d" "f"],
    ["a" "b"; "c" "d"],
    ["b" "e"; "d" "f"],
    Set{String}[Set(["a"]), Set(["b", "c"]), Set(["e", "d"]), Set(["f"])],
) in increase_minor_axis_size(
    Set([["a", "b", "e"], ["c", "d", "f"], ["a", "c"], ["b", "d"], ["e", "f"]]),
    State(
        Dict{Array{String,N} where N,Set{Ortho}}(
            ["a", "c"] => Set([
                Ortho(["a" "b"; "c" "d"], ["a", "c"], ["b", "d"], Set{String}[Set(["a"]), Set(["c", "b"]), Set(["d"])]),
            ]),
        ),
        Dict{Array{String,N} where N,Set{Ortho}}(
            ["b", "d"] => Set([
                Ortho(["a" "b"; "c" "d"], ["a", "c"], ["b", "d"], Set{String}[Set(["a"]), Set(["c", "b"]), Set(["d"])]),
            ]),
        ),
        Dict{Any,Set{Ortho}}(
            (2, 2) => Set([
                Ortho(["a" "b"; "c" "d"], ["a", "c"], ["b", "d"], Set{String}[Set(["a"]), Set(["c", "b"]), Set(["d"])]),
            ]),
        ),
        Set(),
    ),
    Ortho(["b" "e"; "d" "f"], ["b", "d"], ["e", "f"], Set{String}[Set(["b"]), Set(["e", "d"]), Set(["f"])]),
).boxes[(2, 3)]

combine_in_axis(
    Set([["a", "b", "e"], ["c", "d", "f"], ["a", "c"], ["b", "d"], ["e", "f"]]),
    Dict{Array{String,N} where N,Set{Ortho}}(
        ["a", "c"] => Set([
            Ortho(["a" "b"; "c" "d"], ["a", "c"], ["b", "d"], Set{String}[Set(["a"]), Set(["c", "b"]), Set(["d"])]),
        ]),
    ),
    Dict{Array{String,N} where N,Set{Ortho}}(
        ["b", "d"] => Set([
            Ortho(["a" "b"; "c" "d"], ["a", "c"], ["b", "d"], Set{String}[Set(["a"]), Set(["c", "b"]), Set(["d"])]),
        ]),
    ),
    Ortho(["b" "e"; "d" "f"], ["b", "d"], ["e", "f"], Set{String}[Set(["b"]), Set(["e", "d"]), Set(["f"])]),
)
