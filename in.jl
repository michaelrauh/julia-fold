include("util.jl")

function increase_minor_axis_size(phrases, state::State, current::Ortho)
    next_dims = bump_last_dim(size(current.data))
    new_boxes = combine_in_axis(phrases, state.lhs_center_to_ortho, state.rhs_center_to_ortho, current)
    filter_rotate_and_increment(next_dims, new_boxes, state)
end

function get_phrases(arr)
    dims = size(arr)
    volume = reduce(*, dims)
    phrase_length = dims[end]
    remaining_volume = Integer(volume // phrase_length)
    A = reshape(arr, (remaining_volume, phrase_length))
    map(x -> A[x, ..], range(1, stop = remaining_volume))
end

function get_words(arr)
    map(last, get_phrases(arr))
end

function get_desired_phrases(l, r)
    map(vcat, get_phrases(l), get_words(r))
end

function phrase_filter(phrases, l, r)
    desired = get_desired_phrases(l, r)
    for phrase in desired
        if !(phrase in phrases)
            return false
        end
        return true
    end
end

function combine_in_axis(
    phrases,
    lhs_center_to_ortho::Dict{Array{String},Set{Ortho}},
    rhs_center_to_ortho::Dict{Array{String},Set{Ortho}},
    current::Ortho,
)::Array{Ortho}
    left_candidates = collect(get(lhs_center_to_ortho, current.rhs_center, Set()))
    left_winners = map(
        x -> combine_winners(current, x),
        filter(
            x -> phrase_filter(phrases, current.data, x.data),
            left_candidates,
        ),
    )
    right_candidates = collect(get(rhs_center_to_ortho, current.lhs_center, Set()))
    right_winners = map(
        x -> combine_winners(x, current),
        filter(
            x -> phrase_filter(phrases, x.data, current.data),
            right_candidates,
        ),
    )

    vcat(left_winners..., right_winners...)
end
