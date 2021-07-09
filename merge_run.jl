include("./run.jl")

function merge_state(s1, s2)
    State(
    mergewith(union, s1.lhs_center_to_ortho, s2.lhs_center_to_ortho),
    mergewith(union, s1.rhs_center_to_ortho, s2.rhs_center_to_ortho),
    mergewith(union, s1.boxes, s2.boxes),
    Set())
end

function merge_starting_config(all_prevs1, all_nexts1, all_phrases1, vocab1, all_prevs2, all_nexts2, all_phrases2, vocab2)
    return mergewith(union, all_prevs1, all_prevs2),
    mergewith(union, all_nexts1, all_nexts2),
    union(all_phrases1, all_phrases2),
    get_vocab(vcat(vocab1..., vocab2...))
end

function merge_run(f1, f2)
    all_prevs1, all_nexts1, all_phrases1, vocab1, state1 = make_starting_config(f1)
    all_prevs2, all_nexts2, all_phrases2, vocab2, state2 = make_starting_config(f2)

    state = merge_state(go(all_prevs1, all_nexts1, all_phrases1, vocab1, state1), go(all_prevs2, all_nexts2, all_phrases2, vocab2, state2))
    all_prevs3, all_nexts3, all_phrases3, vocab3 = merge_starting_config(all_prevs1, all_nexts1, all_phrases1, vocab1, all_prevs2, all_nexts2, all_phrases2, vocab2)
    go(all_prevs3, all_nexts3, all_phrases3, vocab3, state)
end

println(merge_run("example1.txt", "example2.txt").boxes)
