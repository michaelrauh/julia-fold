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

function read_file_to_arrays(filename :: String) :: Vector{Vector{String}}
    open(filename) do f
        map(split(read(f, String), ".")) do y
            y |> split |> x -> join(x, " ") |> x -> replace(x, r"[^a-zA-Z0-9_\ ]" => "") |> lowercase |> split
        end
    end
end

read_file_to_arrays("example1.txt")

function get_all(f :: Function, l :: Vector{Vector{String}}) :: Dict{String, Set{String}}
    mergewith(union, map(f, l)...)
end

function if_longer_two_then(f :: Function, l :: Vector{String})
    if length(l) < 2
        Dict()
    else
        f(l)
    end
end

function prevs(l :: Vector{String}) :: Dict{String, Set{String}}
    if_longer_two_then(x -> mergewith(union, Dict(x[2]=>Set([first(x)])), prevs(x[2:end])), l)
end

function nexts(l :: Vector{String}) :: Dict{String, Set{String}}
    if_longer_two_then(x -> mergewith(union, Dict(first(x)=>Set([x[2]])), nexts(x[2:end])), l)
end

get_all(prevs, [["a", "b", "c"], ["d", "e", "f"], ["e", "b"]])
get_all(prevs, read_file_to_arrays("example1.txt"))
get_all(nexts, read_file_to_arrays("example1.txt"))
