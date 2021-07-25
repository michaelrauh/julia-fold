include("./atom.jl")
include("./cross.jl")
include("./in.jl")

function read_file_to_arrays(filename::String)::Vector{Vector{String}}
    ans = open(filename) do f
        map(split(read(f, String), ".")) do y
            y |> split |> x -> join(x, " ") |> x -> replace(x, r"[^a-zA-Z0-9_\ ]" => "") |> lowercase |> split
        end
    end
    filter(x -> !isempty(x), ans)
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

function empty_state()
    State(Dict(), Dict(), Dict(), Set())
end

function get_all_prevs(x)
    function prevs(l::Vector{String})::Dict{String,Set{String}}
        if length(l) < 2
            Dict()
        else
            mergewith(union, Dict(l[2] => Set([first(l)])), prevs(l[2:end]))
        end
    end
    mergewith(union, map(prevs, x)...)
end

function get_all_nexts(x)
    function nexts(l::Vector{String})::Dict{String,Set{String}}
        if length(l) < 2
            Dict()
        else
            mergewith(union, Dict(first(l) => Set([l[2]])), nexts(l[2:end]))
        end
    end

    mergewith(union, map(nexts, x)...)
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

function make_starting_config(filename)
    file_arrays = read_file_to_arrays(filename)
    all_prevs = get_all_prevs(file_arrays)
    all_nexts = get_all_nexts(file_arrays)
    all_phrases = make_phrases(file_arrays)
    vocab = get_vocab(file_arrays)
    Config(all_prevs, all_nexts, all_phrases, vocab)
end

function go(config, state)
    for word in config.vocab
        state = sift(ingest_word(state, config.nexts, config.prevs, word), config.nexts, config.prevs, config.phrases)
    end
    state
end

function decrement(state)
    State(state.lhs_center_to_ortho, state.rhs_center_to_ortho, state.boxes, Set(collect(state.increment)[2:end]))
end

# TODO consider using a work queue instead of recursion
function sift(state, all_nexts, all_prevs, all_phrases)
    if isempty(state.increment)
        return state
    end

    current = first(state.increment)
    if base_dimension(size(current.data))
        state = sift(increase_dimensionality(all_nexts, all_prevs, state, current), all_nexts, all_prevs, all_phrases)
    end

    state = sift(increase_minor_axis_size(all_phrases, state, current), all_nexts, all_prevs, all_phrases)
    sift(decrement(state), all_nexts, all_prevs, all_phrases)
end
