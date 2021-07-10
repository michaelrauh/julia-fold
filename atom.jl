include("util.jl")

function make_ortho(a::String, b::String, c::String, d::String)::Ortho
    data = [a b; c d]
    lhs_center = [a; c]
    rhs_center = [b; d]
    diagonals = [Set([a]), Set([b, c]), Set([d])]
    Ortho(data, lhs_center, rhs_center, diagonals)
end

"""
a b
c d
d <- c <- a -> b -> d' where d = d', b != c"""
function make_atom(word::String, next::Dict{String,Set{String}}, prev::Dict{String,Set{String}})::Set{Ortho}
    ans = Set()
    d = word
    for c in get(prev, d, Set())
        for a in get(prev, c, Set())
            for b in get(next, a, Set())
                for d_prime in get(next, b, Set())
                    if d == d_prime && b != c
                        push!(ans, make_ortho(a, b, c, d))
                    end
                end
            end
        end
    end
    return ans
end

function ingest_word(state::State, next::Dict{String,Set{String}}, prev::Dict{String,Set{String}}, word::String)::State
    dims = (2, 2)
    known_boxes = get(state.boxes, dims, Set())
    new_boxes = make_atom(word, next, prev)
    increment = filter(!(x -> x in known_boxes), new_boxes)
    update_state_values(state, increment, dims)
end
