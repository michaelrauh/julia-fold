"""
a b
c d
d <- c <- a -> b -> d' where d = d', b != c"""
function make_atom(
    word::String,
    next::Dict{String,Set{String}},
    prev::Dict{String,Set{String}},
)::Set{Tuple{String,String,String,String}}
    ans = Set()
    d = word
    for c in get(prev, d, Set())
        for a in get(prev, c, Set())
            for b in get(next, a, Set())
                for d_prime in get(next, b, Set())
                    if d == d_prime && b != c
                        push!(ans, (a, b, c, d))
                    end
                end
            end
        end
    end
    return ans
end

next = Dict{String,Set{String}}("a" => Set(["b", "c"]), "b" => Set(["d"]), "c" => Set(["d"]))
prev = Dict{String,Set{String}}("b" => Set(["a"]), "c" => Set(["a", "d"]), "d" => Set(["b", "c"]))

make_atom("d", next, prev)
