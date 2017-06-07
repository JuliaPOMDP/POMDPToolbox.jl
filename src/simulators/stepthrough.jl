# StepSimulator
# maintained by @zsunberg

type StepSimulator
    rng::AbstractRNG
    initial_state::Nullable{Any}
    max_steps::Nullable{Any}
    spec
end

get_initial_state(sim, mdp)

function simulate{S,A}(sim::StepSimulator, mdp::MDP{S,A}, policy::Policy, init_state::S=get_initial_state(sim, mdp))
    return MDPSimIterator{(:s,:a,:r,:sp), typeof(mdp), typeof(policy), S}(mdp, policy, init_state)
end

immutable MDPSimIterator{SPEC, M<:MDP, P<:Policy, RNG<:AbstractRNG, S}
    mdp::M
    policy::P
    rng::RNG
    init_state::S
end

Base.done{S}(it::MDPSimIterator, is::Tuple{Int, S}) = isterminal(it.mdp, is[2]) || is[1] > max_steps
Base.start(it::MDPSimIterator) = (1, it.init_state)
function Base.step(it::MDPSimIterator, is::Tuple{Int, S})
    s = is[2]
    a = action(it.policy, s)
    sp, r = generate_sr(it.mdp, s, a, it.rng)
    return (out_tuple(it, (s, a, r, sp)), (is[1]+1, sp))
end



immutable POMDPSimIterator{SPEC, M<:POMDP, P<:Policy, U<:Updater}
    pomdp::M
    policy::P
    updater::U
end


# all is (s, a, r, sp) for mdps, (s, a, r, sp, b, o, bp) for POMDPs
sym_to_ind = Dict(sym=>i for (i, sym) in enumerate([:s,:a,:r,:sp,:b,:o,:bp]))

@generated function out_tuple(it::Union{MDPSimIterator, POMDPSimIterator}, all::Tuple)
    spec = it.parameters[1]     
    if isa(spec, Tuple)
        calls = []
        for sym in spec
            push!(calls, :(all[$(sym_to_ind[sym])]))
        end

        return quote
            return tuple($(calls...))
        end
    else
        @assert isa(spec, Symbol)
        return quote
            return all[$(sym_to_ind[spec])]
        end
    end
end

function get_initial_state(sim::Simulator, initial_state_dist)
    if isnull(sim.initial_state)
        return rand(sim.rng, initial_state_dist)
    else
        return get(sim.initial_state)
    end
end

function get_initial_state(sim::Simulator, mdp::Union{MDP,POMDP})
    if isnull(sim.initial_state)
        return initial_state(mdp, sim.rng)
    else
        return get(sim.initial_state)
    end
end
