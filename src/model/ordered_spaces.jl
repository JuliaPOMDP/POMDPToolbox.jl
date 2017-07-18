# these functions return vectors of states, actions and observations, ordered according to state_index, action_index, etc.

ordered_actions(mdp::Union{MDP,POMDP}) = ordered_vector(action_type(typeof(mdp)), a->action_index(mdp,a), iterator(actions(mdp)), n_actions(mdp))
ordered_states(mdp::Union{MDP,POMDP}) = ordered_vector(state_type(typeof(mdp)), s->state_index(mdp,s), iterator(states(mdp)), n_states(mdp))
ordered_observations(pomdp::POMDP) = ordered_vector(obs_type(typeof(pomdp)), o->obs_index(pomdp,o), iterator(observations(pomdp)), n_observations(pomdp))

function ordered_vector(T::Type, index::Function, iterator, len=length(iterator))
    a = Array{T}(len)
    gotten = falses(len)
    for x in iterator
        id = index(x)
        a[id] = x
        gotten[id] = true
    end
    @assert all(gotten)
    return a
end

@POMDP_require ordered_actions(mdp::Union{MDP,POMDP}) begin
    P = typeof(mdp)
    @req action_index(::P, ::action_type(P))
    @req n_actions(::P)
    @req actions(::P)
    as = actions(mdp)
    @req iterator(::typeof(as))
end

@POMDP_require ordered_states(mdp::Union{MDP,POMDP}) begin
    P = typeof(mdp)
    @req state_index(::P, ::state_type(P))
    @req n_states(::P)
    @req states(::P)
    as = states(mdp)
    @req iterator(::typeof(as))
end

@POMDP_require ordered_observations(mdp::Union{MDP,POMDP}) begin
    P = typeof(mdp)
    @req obs_index(::P, ::obs_type(P))
    @req n_observations(::P)
    @req observations(::P)
    as = observations(mdp)
    @req iterator(::typeof(as))
end
