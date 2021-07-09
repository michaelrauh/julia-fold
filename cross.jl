include("util.jl")

function increase_dimensionality(nexts, prevs, state, current)
    dims = size(current.data)
    next_dims = increase_dims_size(dims)
    new_boxes = combine_across_axis(nexts, prevs, get(state.boxes, dims, Set()), current)
    filter_rotate_and_increment(next_dims, new_boxes, state)
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
