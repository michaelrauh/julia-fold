struct Ortho
    data::Array{String}
    lhs_center::Array{String}
    rhs_center::Array{String}
    diagonals::Array{Set{String}}
end

function Base.hash(a::Ortho, h::UInt)
    Base.hash((a.data, a.lhs_center, a.rhs_center,a.diagonals), h)
end

function Base.:(==)(a::Ortho, b::Ortho)
    a.data == b.data && a.lhs_center == b.lhs_center && a.rhs_center == b.rhs_center && a.diagonals == b.diagonals
end

struct State
    lhs_center_to_ortho::Dict{Array{String},Set{Ortho}}
    rhs_center_to_ortho::Dict{Array{String},Set{Ortho}}
    boxes::Dict{Any,Set{Ortho}}
    increment::Set{Ortho}
end

struct Config
    prevs
    nexts
    phrases
    vocab
end
