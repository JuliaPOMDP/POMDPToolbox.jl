ordered_actions{S,A}(mdp::Union{MDP{S,A},POMDP{S,A}}) = ordered_vector(A, a->action_index(mdp,a), iterator(actions(mdp)), n_actions(mdp))
ordered_states{S}(mdp::Union{MDP{S},POMDP{S}}) = ordered_vector(S, s->state_index(mdp,s), iterator(states(mdp)), n_states(mdp))
ordered_observations{S,A,O}(pomdp::POMDP{S,A,O}) = ordered_vector(S, o->observation_index(mdp,o), iterator(observations(mdp)), n_observations(mdp))

function ordered_vector(T::Type, index::Function, iterator, len=length(iterator))
    a = Array(T, len)
    gotten = falses(len)
    for x in iterator
        id = index(x)
        a[id] = x
        gotten[id] = true
    end
    @assert all(gotten)
    return a
end
