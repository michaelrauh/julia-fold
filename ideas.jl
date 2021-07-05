# TODO dedup code here from ingest_word
function increase_minor_axis_size(phrases, state, current)
    dims = size(current.data)
    known_boxes = get(state.boxes, dims, Set())
    new_boxes = combine_in_axis(phrases, state.lhs_center_to_ortho, state.rhs_center_to_ortho, current)
    increment = filter(!(x -> x in known_boxes), new_boxes)
    lhs_center_to_ortho = mergewith(
        union,
        state.lhs_center_to_ortho,
        map(x -> Dict(getfield(x, :lhs_center) => x), collect(increment))...,
    )
    rhs_center_to_ortho = mergewith(
        union,
        state.rhs_center_to_ortho,
        map(x -> Dict(getfield(x, :rhs_center) => x), collect(increment))...,
    )
    boxes = mergewith(union, state.boxes, Dict(bump_last_dim(dims) => increment))
    State(lhs_center_to_ortho, rhs_center_to_ortho, boxes, increment)
end

function bump_last_dim(dims)
    ans = [x for x in dims]
    ans[end] += 1
    Tuple(ans)
end

# TODO skip making rotations if the original is already there (they will be filtered)
function combine_in_axis(phrases, lhs_center_to_ortho, rhs_center_to_ortho, current)
    vcat(map(rotations, combine(phrases, lhs_center_to_ortho, rhs_center_to_ortho, current))...)
end

function combine(phrases, lhs_center_to_ortho, rhs_center_to_ortho, current)
    left_combine_candidates = get(lhs_center_to_ortho, current.rhs_center, Set())
    left_selected_candidates =
        filter(x -> phrase_filter(phrases, current.data, x.data), collect(left_combine_candidates))
    left_winners = map(x -> combine_winners(current, x), left_selected_candidates)

    # TODO dedup this while respecting differences in arg order. Consider function combinator
    right_combine_candidates = get(rhs_center_to_ortho, current.rhs_center, Set())
    print(collect(right_combine_candidates))
    right_selected_candidates =
        filter(x -> phrase_filter(phrases, x.data, current.data), collect(right_combine_candidates))
    right_winners = map(x -> combine_winners(x, current), right_selected_candidates)

    vcat(left_winners..., right_winners...)
end

combine(all_phrases, state.lhs_center_to_ortho, state.rhs_center_to_ortho, first(state.boxes[(2, 2)]))

for ortho in collect(state.boxes[(2, 2)])
    state = increase_minor_axis_size(all_phrases, state, ortho)
end
