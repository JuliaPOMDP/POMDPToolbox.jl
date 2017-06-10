# StepSimulator
# maintained by @zsunberg

type StepSimulator
    rng::AbstractRNG
    initial_state::Nullable{Any}
    max_steps::Nullable{Any}
    spec
end

function simulate{S}(sim::StepSimulator, mdp::MDP{S}, policy::Policy, init_state::S=get_initial_state(sim, mdp))
    symtuple = convert_spec(sim.spec, MDP)
    return MDPSimIterator{symtuple,
                          typeof(mdp),
                          typeof(policy),
                          typeof(sim.rng), S}(mdp,
                                              policy,
                                              sim.rng,
                                              init_state,
                                              max_steps)
end

function simulate(sim::StepSimulator, pomdp::POMDP, policy::Policy, bu::Updater=updater(policy))
    dist = initial_state_distribution(pomdp)    
    return simulate(sim, pomdp, policy, bu, dist)
end

function simulate(sim::StepSimulator, pomdp::POMDP, policy::Policy, bu::Updater, dist::Any)
    initial_state = get_initial_state(sim, dist)
    initial_belief = initialize_belief(bu, dist)
    symtuple = convert_spec(sim.spec, POMDP)
    return POMDPSimIterator{symtuple,
                            typeof(pomdp),
                            typeof(policy),
                            typeof(bu),
                            typeof(rng)
                           }
end

immutable MDPSimIterator{SPEC, M<:MDP, P<:Policy, RNG<:AbstractRNG, S}
    mdp::M
    policy::P
    rng::RNG
    init_state::S
    max_steps::Int
end

Base.done{S}(it::MDPSimIterator, is::Tuple{Int, S}) = isterminal(it.mdp, is[2]) || is[1] > max_steps
Base.start(it::MDPSimIterator) = (1, it.init_state)
function Base.step(it::MDPSimIterator, is::Tuple{Int, S})
    s = is[2]
    a = action(it.policy, s)
    sp, r = generate_sr(it.mdp, s, a, it.rng)
    return (out_tuple(it, (s, a, r, sp)), (is[1]+1, sp))
end

immutable POMDPSimIterator{SPEC, M<:POMDP, P<:Policy, U<:Updater, RNG<:AbstractRNG, B, S}
    pomdp::M
    policy::P
    updater::U
    rng::RNG
    init_belief::B
    init_state::S
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

function convert_spec(spec, T::Type{POMDP})
    st = convert_spec(spec)
end

function convert_spec(spec, T::Type{MDP})
    st = convert_spec(spec)
end

function convert_spec(spec::String)
    syms = [Symbol(m.match) for m in eachmatch(r"(sp|bp|s|a|r|b|o)", spec)]
    if length(syms) == 0
        error("$spec does not contain any valid symbols for step iterator output. Valid symbols are sp, bp, s, a, r, b, o")
    end
    if length(syms) == 1
        return Symbol(first(syms))
    else
        return tuple(syms...)
    end
end

function convert_spec(spec::Tuple)
end

function convert_spec(spec::Symbol)
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
