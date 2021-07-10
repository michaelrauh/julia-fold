using EllipsisNotation
using Traceur
include("types.jl")


function filter_rotate_and_increment(dims, new_boxes, state)
    known_boxes = get(state.boxes, dims, Set())
    filtered_boxes = filter(!(x -> x in known_boxes), new_boxes)
    increment = Set(vcat(map(rotations, filtered_boxes)...))
    update_state_values(state, increment, dims)
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

function reconstitute_from_data(diagonals, data)
    dims = size(data)
    minor_dim = dims[length(dims)]
    Ortho(data, data[.., 1:minor_dim-1], data[.., 2:minor_dim], diagonals)
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


function bump_last_dim(dims)
    ans = collect(dims)
    ans[end] += 1
    Tuple(ans)
end

function combine_winners(l, r)
    # TODO remove repeated calls
    data = reshape(cat(get_desired_phrases(l.data, r.data)..., dims=(2)), bump_last_dim(size(l.data)))
    diagonals = vcat([first(l.diagonals)], map(union, l.diagonals[2:end], r.diagonals[1:end-1]), [last(r.diagonals)])
    reconstitute_from_data(diagonals, data)
end
