struct Ortho
    data
    lhs_center
    rhs_center
    diagonals
end

struct State
    lhs_center_to_ortho
    rhs_center_to_ortho
    boxes
    increment
end

function make_ortho(a, b, c, d) :: Ortho
    data = [a b; c d]
    lhs_center = [a; c]
    rhs_center = [b; d]
    diagonals = [Set([a]), Set([b, c]), Set([(d)])]
    Ortho(data, lhs_center, rhs_center, diagonals)
end

"""
a b
c d
d <- c <- a -> b -> d' where d = d', b != c"""
function make_atom(
    word::String,
    next::Dict{String,Set{String}},
    prev::Dict{String,Set{String}},
)::Set{Ortho}
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

function read_file_to_arrays(filename::String)::Vector{Vector{String}}
    open(filename) do f
        map(split(read(f, String), ".")) do y
            y |> split |> x -> join(x, " ") |> x -> replace(x, r"[^a-zA-Z0-9_\ ]" => "") |> lowercase |> split
        end
    end
end

function get_all(f::Function, l::Vector{Vector{String}})::Dict{String,Set{String}}
    mergewith(union, map(f, l)...)
end

function if_longer_two_then(f::Function, l::Vector{String})
    if length(l) < 2
        Dict()
    else
        f(l)
    end
end

function prevs(l::Vector{String})::Dict{String,Set{String}}
    if_longer_two_then(x -> mergewith(union, Dict(x[2] => Set([first(x)])), prevs(x[2:end])), l)
end

function nexts(l::Vector{String})::Dict{String,Set{String}}
    if_longer_two_then(x -> mergewith(union, Dict(first(x) => Set([x[2]])), nexts(x[2:end])), l)
end

file_arrays = read_file_to_arrays("example1.txt")
all_prevs = get_all(prevs, file_arrays)
all_nexts = get_all(nexts, file_arrays)

vocab = vcat(file_arrays...) |> sort |> unique

some_orthos = filter(!isempty, vocab .|> x -> make_atom(x, all_nexts, all_prevs))

function ingest_word(state, next, prev, word)
    known_boxes = get(state.boxes, [2, 2], Set())
    new_boxes = make_atom(word, next, prev)
    increment = filter(!(x -> x in known_boxes), new_boxes)
    lhs_center_to_ortho = mergewith(union, state.lhs_center_to_ortho, map(x -> Dict(getfield(x, :lhs_center) => getfield(x, :data)), collect(increment))...)
    rhs_center_to_ortho = mergewith(union, state.rhs_center_to_ortho, map(x -> Dict(getfield(x, :rhs_center) => getfield(x, :data)), collect(increment))...)
    boxes = mergewith(union, state.boxes, Dict([2, 2] => increment))
    State(lhs_center_to_ortho, rhs_center_to_ortho, boxes, increment)
end

function empty_state()
    State(Dict(), Dict(), Dict(), Set())
end

ingest_word(empty_state(), all_nexts, all_prevs, first(vocab))

s = empty_state()
for word in vocab
    s = ingest_word(s, all_nexts, all_prevs, word)
end

s
