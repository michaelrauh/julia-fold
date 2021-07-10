include("./run.jl")

function merge_state(s1, s2)
    State(
    mergewith(union, s1.lhs_center_to_ortho, s2.lhs_center_to_ortho),
    mergewith(union, s1.rhs_center_to_ortho, s2.rhs_center_to_ortho),
    mergewith(union, s1.boxes, s2.boxes),
    Set())
end

function merge_starting_config(c1, c2)
    return mergewith(union, c1.prevs, c2.prevs),
    mergewith(union, c1.nexts, c2.nexts),
    union(c1.phrases, c2.phrases),
    get_vocab(vcat(c1.vocab..., c2.vocab...))
end

function merge_run(f1, f2)
    config1 = make_starting_config(f1)
    config2 = make_starting_config(f2)
    state1 = empty_state()
    state2 = empty_state()

    state = merge_state(go(config1, state1), go(config2, state2))
    all_prevs3, all_nexts3, all_phrases3, vocab3 = merge_starting_config(config1, config2)
    go(Config(all_prevs3, all_nexts3, all_phrases3, vocab3), state)
end

println(merge_run("example1.txt", "example2.txt").boxes)
