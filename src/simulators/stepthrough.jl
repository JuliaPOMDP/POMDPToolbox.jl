# StepSimulator
# maintained by @zsunberg

mutable struct StepSimulator <: Simulator
    rng::AbstractRNG
    initial_state::Nullable{Any}
    max_steps::Nullable{Any}
    spec
end
function StepSimulator(spec; rng=Base.GLOBAL_RNG, initial_state=nothing, max_steps=nothing)
    return StepSimulator(rng, initial_state, max_steps, spec)
end

function simulate{S}(sim::StepSimulator, mdp::MDP{S}, policy::Policy, init_state::S=get_initial_state(sim, mdp))
    symtuple = convert_spec(sim.spec, MDP)
    return MDPSimIterator(symtuple, mdp, policy, sim.rng, init_state, get(sim.max_steps, typemax(Int64)))
end

function simulate(sim::StepSimulator, pomdp::POMDP, policy::Policy, bu::Updater=updater(policy))
    dist = initial_state_distribution(pomdp)    
    return simulate(sim, pomdp, policy, bu, dist)
end

function simulate(sim::StepSimulator, pomdp::POMDP, policy::Policy, bu::Updater, dist::Any)
    initial_state = get_initial_state(sim, dist)
    initial_belief = initialize_belief(bu, dist)
    symtuple = convert_spec(sim.spec, POMDP)
    return POMDPSimIterator(symtuple, pomdp, policy, bu, sim.rng, initial_belief, initial_state, get(sim.max_steps, typemax(Int64)))
end

struct MDPSimIterator{SPEC, M<:MDP, P<:Policy, RNG<:AbstractRNG, S}
    mdp::M
    policy::P
    rng::RNG
    init_state::S
    max_steps::Int
end

function MDPSimIterator(spec::Union{Tuple, Symbol}, mdp::MDP, policy::Policy, rng::AbstractRNG, init_state, max_steps::Int) 
    return MDPSimIterator{spec, typeof(mdp), typeof(policy), typeof(rng), typeof(init_state)}(mdp, policy, rng, init_state, max_steps)
end

Base.done{S}(it::MDPSimIterator, is::Tuple{Int, S}) = isterminal(it.mdp, is[2]) || is[1] > it.max_steps
Base.start(it::MDPSimIterator) = (1, it.init_state)
function Base.next{S}(it::MDPSimIterator, is::Tuple{Int, S})
    s = is[2]
    a = action(it.policy, s)
    sp, r = generate_sr(it.mdp, s, a, it.rng)
    return (out_tuple(it, (s, a, r, sp)), (is[1]+1, sp))
end

struct POMDPSimIterator{SPEC, M<:POMDP, P<:Policy, U<:Updater, RNG<:AbstractRNG, B, S}
    pomdp::M
    policy::P
    updater::U
    rng::RNG
    init_belief::B
    init_state::S
    max_steps::Int
end
function POMDPSimIterator(spec::Union{Tuple,Symbol}, pomdp::POMDP, policy::Policy, up::Updater, rng::AbstractRNG, init_belief, init_state, max_steps::Int) 
    return POMDPSimIterator{spec,
                            typeof(pomdp),
                            typeof(policy),
                            typeof(up),
                            typeof(rng),
                            typeof(init_belief),
                            typeof(init_state)}(pomdp,
                                                policy,
                                                up,
                                                rng,
                                                init_belief,
                                                init_state,
                                                max_steps)
end

Base.done{S,B}(it::POMDPSimIterator, is::Tuple{Int, S, B}) = isterminal(it.pomdp, is[2]) || is[1] > it.max_steps
Base.start(it::POMDPSimIterator) = (1, it.init_state, it.init_belief)
function Base.next{S,B}(it::POMDPSimIterator, is::Tuple{Int, S, B})
    s = is[2]
    b = is[3]
    a = action(it.policy, b)
    sp, o, r = generate_sor(it.pomdp, s, a, it.rng)
    bp = update(it.updater, b, a, o)
    return (out_tuple(it, (s, a, r, sp, b, o, bp)), (is[1]+1, sp, bp))
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
        @assert isa(spec, Symbol) "Invalid specification: $spec is not a Symbol or Tuple."
        return quote
            return all[$(sym_to_ind[spec])]
        end
    end
end

convert_spec(spec, T::Type{POMDP}) = convert_spec(spec, Set(tuple(:sp, :bp, :s, :a, :r, :b, :o)))
convert_spec(spec, T::Type{MDP}) = convert_spec(spec, Set(tuple(:sp, :s, :a, :r)))

function convert_spec(spec, recognized::Set{Symbol})
    conv = convert_spec(spec)
    for s in (isa(conv, Tuple) ? conv : tuple(conv))
        if !(s in recognized)
            warn("uncrecognized symbol $s in step iteration specification $spec.")
        end
    end
    return conv
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
    for s in spec
        @assert isa(s, Symbol)
    end
    return spec
end

convert_spec(spec::Symbol) = spec

"""
    stepthrough(problem, policy, [spec])
    stepthrough(problem, policy, [spec], [rng=rng], [max_steps=max_steps], [initial_state=initial_state])

Create a simulation iterator. This is intended to be used with for loop syntax to output the results of each step *as the simulation is being run*. 

Example:

    pomdp = BabyPOMDP()
    policy = RandomPolicy(pomdp)

    for (s, a, o, r) in stepthrough(pomdp, policy, "s,a,o,r", max_steps=10)
        println("in state \$s")
        println("took action \$o")
        println("received observation \$o and reward \$r")
    end

The spec argument can be a string, tuple of symbols, or single symbol and follows the same pattern as `eachstep` called on a `SimHistory` object.

Under the hood, this function creates a `StepSimulator` with `spec` and returns a `[PO]MDPSimIterator` by calling simulate with all of the arguments except `spec`. All keyword arguments are passed to the `StepSimulator` constructor.
"""
function stepthrough end # for documentation

function stepthrough(mdp::MDP, policy::Policy, spec::Union{String, Tuple, Symbol}=(:s,:a,:r,:sp); kwargs...)
    sim = StepSimulator(spec; kwargs...)
    return simulate(sim, mdp, policy)
end

"""
    stepthrough(mdp::MDP, policy::Policy, [init_state], [spec="sarsp"]; [kwargs...])

Step through an mdp simulation. The initial state is optional. If no spec is given, (s, a, r, sp) is used.
"""
function stepthrough{S}(mdp::MDP{S},
                        policy::Policy,
                        init_state::S,
                        spec::Union{String, Tuple, Symbol}=(:s,:a,:r,:sp);
                        kwargs...)
    sim = StepSimulator(spec; kwargs...)
    return simulate(sim, mdp, policy, init_state)
end

"""
    stepthrough(pomdp::POMDP, policy::Policy, [up::Updater, [initial_belief]], [spec="ao"]; [kwargs...])

Step through a pomdp simulation. the updater and initial belief are optional. If no spec is given, (a, o) is used.
"""
function stepthrough(pomdp::POMDP, policy::Policy, args...; kwargs...)
    spec_included=false
    if isa(last(args), Union{String, Tuple, Symbol})
        spec = last(args)
        spec_included = true
    else
        spec=(:a,:o)
    end
    sim = StepSimulator(spec; kwargs...)
    return simulate(sim, pomdp, policy, args[1:end-spec_included]...)
end

