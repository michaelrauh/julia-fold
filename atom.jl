using EllipsisNotation
using Traceur

struct Ortho
    data::Array{String}
    lhs_center::Array{String}
    rhs_center::Array{String}
    diagonals::Array{Set{String}}
end

struct State
    lhs_center_to_ortho::Dict{Array{String},Set{Ortho}}
    rhs_center_to_ortho::Dict{Array{String},Set{Ortho}}
    boxes::Dict{Any,Set{Ortho}}
    increment::Set{Ortho}
end

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

function read_file_to_arrays(filename::String)::Vector{Vector{String}}
    ans = open(filename) do f
        map(split(read(f, String), ".")) do y
            y |> split |> x -> join(x, " ") |> x -> replace(x, r"[^a-zA-Z0-9_\ ]" => "") |> lowercase |> split
        end
    end
    filter(x -> !isempty(x), ans)
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

function make_phrases(sentences_list)
    union(map(tails, sentences_list)...)
end

function tails(sentence)
    if length(sentence) == 1
        Set([sentence])
    else
        union(Set([sentence]), tails(sentence[2:end]))
    end
end

function update_state_values(state::State, increment, box_update_key)
    lhs_center_to_ortho = mergewith(
        union,
        state.lhs_center_to_ortho,
        map(x -> Dict(getfield(x, :lhs_center) => Set([x])), collect(increment))...,
    )
    rhs_center_to_ortho = mergewith(
        union,
        state.rhs_center_to_ortho,
        map(x -> Dict(getfield(x, :rhs_center) => Set([x])), collect(increment))...,
    )
    boxes = mergewith(union, state.boxes, Dict(box_update_key => increment))
    State(lhs_center_to_ortho, rhs_center_to_ortho, boxes, increment)
end

@trace function ingest_word(state::State, next::Dict{String,Set{String}}, prev::Dict{String,Set{String}}, word::String)::State
    dims = (2, 2)
    known_boxes = get(state.boxes, dims, Set())
    new_boxes = make_atom(word, next, prev)
    increment = filter(!(x -> x in known_boxes), new_boxes)
    update_state_values(state, increment, dims)
end

function bump_last_dim(dims)
    ans = collect(dims)
    ans[end] += 1
    Tuple(ans)
end

function get_phrases(arr)
    dims = size(arr)
    volume = reduce(*, dims)
    phrase_length = dims[end]
    remaining_volume = Integer(volume // phrase_length)
    A = reshape(arr, (remaining_volume, phrase_length))
    map(x -> A[x,..], range(1, stop=remaining_volume))
end

function get_words(arr)
    map(last, get_phrases(A))
end

function get_desired_phrases(l, r)
    map(vcat, get_phrases(l), get_words(r))
end

function phrase_filter(phrases, l, r)
    for phrase in get_desired_phrases(l, r)
        if !(phrase in phrases)
            return false
        end
        return true
    end
end

function combine_winners(l, r)
    # TODO remove repeated calls
    data = reshape(cat(get_desired_phrases(l.data, r.data)..., dims=(2)), bump_last_dim(size(l.data)))
    diagonals = vcat([first(l.diagonals)], map(union, l.diagonals[2:end], r.diagonals[1:end-1]), [last(r.diagonals)])
    reconstitute_from_data(diagonals, data)
end

function combine_in_axis(
    phrases,
    lhs_center_to_ortho::Dict{Array{String},Set{Ortho}},
    rhs_center_to_ortho::Dict{Array{String},Set{Ortho}},
    current::Ortho,
)::Array{Ortho}
    left_winners = map(
        x -> combine_winners(current, x),
        filter(
            x -> phrase_filter(phrases, current.data, x.data),
            collect(get(lhs_center_to_ortho, current.rhs_center, Set())),
        ),
    )

    right_winners = map(
        x -> combine_winners(x, current),
        filter(
            x -> phrase_filter(phrases, x.data, current.data),
            collect(get(rhs_center_to_ortho, current.lhs_center, Set())),
        ),
    )

    vcat(left_winners..., right_winners...)
end

function reconstitute_from_data(diagonals, data)
    dims = size(data)
    minor_dim = dims[length(dims)]
    Ortho(data, data[.., 1:minor_dim-1], data[.., 2:minor_dim], diagonals)
end

# TODO consider permutedimsarray and array views generally
function rotate_data(d::Array)
    dimensionality = length(size(d))
    transforms = map(x -> [dimensionality, x], range(1, stop = dimensionality - 1))
    map(x -> permutedims(d, x), transforms)
end

function rotations(o::Ortho)
    datas = rotate_data(o.data)
    vcat(o, map(x -> reconstitute_from_data(o.diagonals, x), datas)...)
end

function increase_minor_axis_size(phrases, state::State, current::Ortho)
    next_dims = bump_last_dim(size(current.data))
    new_boxes = combine_in_axis(phrases, state.lhs_center_to_ortho, state.rhs_center_to_ortho, current)
    filter_rotate_and_increment(next_dims, new_boxes, state)
end

function increase_dimensionality(nexts, prevs, state, current)
    dims = size(current.data)
    next_dims = increase_dims_size(dims)
    new_boxes = combine_across_axis(nexts, prevs, get(state.boxes, dims, Set()), current)
    filter_rotate_and_increment(next_dims, new_boxes, state)
end

function filter_rotate_and_increment(dims, new_boxes, state)
    known_boxes = get(state.boxes, dims, Set())
    filtered_boxes = filter(!(x -> x in known_boxes), new_boxes)
    increment = Set(vcat(map(rotations, filtered_boxes)...))
    update_state_values(state, increment, dims)
end

function empty_state()
    State(Dict(), Dict(), Dict(), Set())
end

function increase_dims_size(dims)
    Tuple(vcat(collect(dims), [2]))
end

function next_filter(nexts, l, r)
    for (left, right) in zip(collect(l.data), collect(r.data))
        if !(right in get(nexts, left, Set()))
            return false
        end
    end
    return true
end

# TODO consider using andmap
function diagonal_filter(l, r)
    for (left, right) in zip(l[2:end], r[1:end-1])
        if !(isdisjoint(left, right))
            return false
        end
    end
    return true
end

# TODO dedup
function combine_across_axis(nexts, prevs, candidates, current)
    next_candidates = filter(x -> next_filter(nexts, current, x), candidates)
    prev_candidates = filter(x -> next_filter(prevs, current, x), candidates)

    selected_next_candidates = filter(x -> diagonal_filter(current.diagonals, x.diagonals), next_candidates)
    selected_prev_candidates = filter(x -> diagonal_filter(x.diagonals, current.diagonals), prev_candidates)

    next_winners = map(x -> combine_winners(current, x), collect(selected_next_candidates))
    prev_winners = map(x -> combine_winners(x, current), collect(selected_prev_candidates))

    vcat(next_winners..., prev_winners...)
end

function andmap(f, xs)
    for x in xs
        if !f(x)
            return false
        end
        return true
    end
end

function get_all_prevs(x)
    get_all(prevs, x)
end

function get_all_nexts(x)
    get_all(nexts, x)
end

function get_vocab(x)
    vcat(x...) |> sort |> unique
end

function base_dimension(dims)
    for dim in collect(dims)
        if dim != 2
            return false
        end
    end
    return true
end

function go(filename)
    file_arrays = read_file_to_arrays("example1.txt")
    all_prevs = get_all_prevs(file_arrays)
    all_nexts = get_all_nexts(file_arrays)
    all_phrases = make_phrases(file_arrays)
    vocab = get_vocab(file_arrays)

    state = empty_state()
    for word in vocab
        state = sift(ingest_word(state, all_nexts, all_prevs, word), all_nexts, all_prevs)
    end
    state
end

function decrement(state)
    State(state.lhs_center_to_ortho, state.rhs_center_to_ortho, state.boxes, Set(collect(state.increment)[2:end]))
end

# TODO consider using a work queue instead of recursion
function sift(state, all_nexts, all_prevs)
    if isempty(state.increment)
        return state
    end

    current = first(state.increment)
    if base_dimension(size(current.data))
        state = sift(increase_dimensionality(all_nexts, all_prevs, state, current), all_nexts, all_prevs)
    end

    state = sift(increase_minor_axis_size(all_phrases, state, current), all_nexts, all_prevs)
    sift(decrement(state), all_nexts, all_prevs)
end

# TODO implement state merging
go("example1.txt")
