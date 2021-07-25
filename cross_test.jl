using Test

include("./cross.jl")

# a b
# c d

# e f
# g h

nexts = Dict("a"=>Set(["e"]), "b"=>Set(["f"]), "c"=>Set(["g"]), "d"=>Set(["h"]))
prevs = Dict()

current = Ortho(
    ["a" "b"; "c" "d"],
    ["a"; "c"],
    ["b"; "d"],
    Set{String}[Set(["a"]), Set(["b", "c"]), Set(["d"])])

other = Ortho(
    ["e" "f"; "g" "h"],
    ["e"; "g"],
    ["f"; "h"],
    Set{String}[Set(["e"]), Set(["f", "g"]), Set(["h"])])

state = State(
    Dict(),
    Dict(),
    Dict((2, 2) => Set([other])),
    Set()
)
# TODO add assert
increase_dimensionality(nexts, prevs, state, current)
