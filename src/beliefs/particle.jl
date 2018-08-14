# DEPRECATED Please use https://github.com/JuliaPOMDP/ParticleFilters.jl instead
# maintained by @ebalaban
# Particle-based belief and state distribution types

"""
DEPRECATED: Please use https://github.com/JuliaPOMDP/ParticleFilters.jl instead

Belief particle type that contains a state and its probability
"""
mutable struct Particle{T} # should be immutable?
    state::T # particle state
    weight::Float64 # particle prob
end

"""
DEPRECATED: Please use https://github.com/JuliaPOMDP/ParticleFilters.jl instead

ParticleBelief type. Fields:

    -particles: a vector particles (state and weight) in the belief 
    -probs_dict: dictionary maps states to weights (used in pdf only)
    -probs_arr: weights of each particle in particles (for convenience)
    -keep_dict: boolean flag for keeping track of dictionary
"""
mutable struct ParticleBelief{T}
    particles::Vector{Particle{T}} # array of particles
    probs_dict::Dict{T, Float64} # dict state => prob
    probs_arr::Vector{Float64} # particle weights
    keep_dict::Bool # for more efficient pdf
end
function ParticleBelief(particles::Vector{Particle{S}}) where {S}
    warn("POMDPToolbox.ParticleBelief is deprecated, please use the beliefs from https://github.com/JuliaPOMDP/ParticleFilters.jl instead.")
    return ParticleBelief(particles, Dict{S,Float64}(), Float64[p.weight for p in particles], false)
end
const ParticleDistribution{T} = ParticleBelief{T}


function pdf(b::ParticleBelief{S}, s::S) where {S}
    if !b.keep_dict
        # search through the particle array (very slow)
        w = 0.0
        for (i, p) in enumerate(b.particles)
            if p.state == s
                w += p.weight
            end
        end
        return w
    else
        # tracking probs in dict (more efficient)
        haskey(b.probs_dict, s) ? (return b.probs_dict[s]) : (return 0.0)
    end
    return 0.0
end

function rand(rng::AbstractRNG, b::ParticleBelief{S}) where {S}
    cat = Weights(b.probs_arr)
    k = sample(rng, cat)
    s = b.particles[k].state
    return s
end
rand(rng::AbstractRNG, b::ParticleBelief{S}, s::S) where {S} = rand(rng, b)

mean(b::ParticleBelief) = sum(p.weight*p.state for p in b.particles)/sum(p.weight for p in b.particles)

function mode(b::ParticleBelief{T}) where {T} # don't know if this is efficient
    d = Dict{T, Float64}()
    best_weight = first(b.particles).weight
    most_likely = first(b.particles).state
    for p in b.particles
        if haskey(d, p.state)
            d[p.state] += p.weight
        else
            d[p.state] = p.weight
        end
        if d[p.state] > best_weight
            best_weight = d[p.state]
            most_likely = p.state
        end
    end
    return most_likely
end

"""
DEPRECATED: Please use https://github.com/JuliaPOMDP/ParticleFilters.jl instead

Updater for ParticleBelief that implements 
the sampling importance resampling (SIR) algorithm. Fields:

    -pomdp: problem model
    -n: number of particles for this updater
    -rng: random number generator for generating state and observations from pomdp model
    -keep_dict: boolean for keeping a dictionary of particles (for pdf only)
"""
mutable struct SIRParticleUpdater <: Updater
    pomdp::POMDP # POMDP model
    n::Int64 # number of particles
    rng::AbstractRNG
    keep_dict::Bool
    function SIRParticleUpdater(pomdp::POMDP, n::Int64, rng::AbstractRNG, keep_dict::Bool)
        warn("POMDPToolbox.SIRParticleUpdater is deprecated. Please use https://github.com/JuliaPOMDP/ParticleFilters.jl instead.")
        new(pomdp, n, rng, keep_dict)
    end
end
function SIRParticleUpdater(pomdp::POMDP, n::Int64; rng::AbstractRNG=Base.GLOBAL_RNG, keep_dict::Bool=true) 
    SIRParticleUpdater(pomdp, n, rng, keep_dict)
end

function create_belief(up::SIRParticleUpdater) 
    st = state_type(typeof(up.pomdp))
    particles = Array{Particle{st}}(up.n)
    w = 1.0 / up.n
    probs = Dict{st, Float64}()  
    probs_arr = zeros(up.n)
    return ParticleBelief(particles, probs, probs_arr, up.keep_dict)
end

function initialize_belief(up::SIRParticleUpdater, d::Any, b::ParticleBelief = create_belief(up))
    w = 1.0 / up.n # start with a uniform weight
    for i = 1:up.n
        # sample a state from initial dist
        s = rand(up.rng, d)
        # add particle
        p = Particle(s, w)
        b.particles[i] = p 
        # update dict
        if haskey(b.probs_dict, s)
            b.probs_dict[s] += w
        else
            b.probs_dict[deepcopy(s)] = w
        end
    end
    return b
end

function update(bu::SIRParticleUpdater, bold::ParticleBelief, a::A, o::O, bnew::ParticleBelief=create_belief(bu)) where {A,O}
    
    rng = bu.rng
    particles = bold.particles
    pomdp = bu.pomdp

    for i = 1:bu.n
        # step particles forward
        s = particles[i].state
        sp = generate_s(pomdp, s, a, rng)
        # compute obs likelihoods
        od = observation(pomdp, s, a, sp)
        bnew.probs_arr[i] = pdf(od, o)
        particles[i].state = sp
    end

    particles = normalize!(particles)
    bnew.probs_arr /= sum(bnew.probs_arr)

    cat = Weights(bnew.probs_arr)

    w = 1.0 / bu.n
    bu.keep_dict ? (empty!(bnew.probs_dict)) : (nothing)
    # resample
    for i = 1:bu.n
        k = sample(rng, cat)
        sp = particles[k].state
        bnew.particles[i] = Particle(deepcopy(sp), w) # XXX slow?
        if bu.keep_dict
            haskey(bnew.probs_dict, sp) ? (bnew.probs_dict[sp] += w) : (bnew.probs_dict[deepcopy(sp)] = w) 
        end
    end
    fill!(bnew.probs_arr, w)
    return bnew
end

function normalize!(particles::Vector{Particle{s}}) where {s}
    prob_sum = 0.0
    for p in particles
        prob_sum += p.weight
    end
    for p in particles
        p.weight /= prob_sum
    end
    return particles
end
