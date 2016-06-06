# maintained by @ebalaban
# Particle-based belief and state distribution types

type Particle{T}
    state::T # particle state
    weight::Float64 # particle prob
end

type ParticleBelief{T} <: AbstractDistribution{T}
    particles::Vector{Particle{T}} # array of particles
    probs_dict::Dict{T, Float64} # dict state => prob
    probs_arr::Vector{Float64} # particle weights
    keep_dict::Bool # for more efficient pdf
end

typealias ParticleDistribution{T} ParticleBelief{T}

function pdf{S}(b::ParticleBelief{S}, s::S)
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

type SIRParticleUpdater <: Updater{ParticleBelief}
    pomdp::POMDP # POMDP model
    td::AbstractDistribution
    od::AbstractDistribution
    n::Int64 # number of particles
    rng::AbstractRNG
    keep_dict::Bool
end
function SIRParticleUpdater(pomdp::POMDP, n::Int64; rng::AbstractRNG=MersenneTwister(), keep_dict::Bool=true) 
    SIRParticleUpdater(pomdp, create_transition_distribution(pomdp), create_observation_distribution(pomdp), n, rng, keep_dict)
end

function create_belief(up::SIRParticleUpdater) 
    s = create_state(up.pomdp)
    st = typeof(s)
    particles = Array(Particle{st}, up.n)
    w = 1.0 / up.n
    for i = 1:up.n
        particles[i] = Particle{st}(deepcopy(s), w)
    end
    probs = Dict{st, Float64}()  
    probs_arr = zeros(up.n)
    return ParticleBelief(particles, probs, probs_arr, up.keep_dict)
end

function initialize_belief(up::SIRParticleUpdater, d::AbstractDistribution, b::ParticleBelief = create_belief(up))
    w = 1.0 / up.n # start with a uniform weight
    for i = 1:up.n
        # sample a state from initial dist
        s = create_state(up.pomdp)
        s = rand(up.rng, d, s)
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

function update{A,O}(bu::SIRParticleUpdater, bold::ParticleBelief, a::A, o::O, bnew::ParticleBelief=create_belief(bu))
    
    rng = bu.rng
    particles = bold.particles
    pomdp = bu.pomdp
    td = bu.td
    od = bu.od

    for i = 1:bu.n
        # step particles forward
        s = particles[i].state
        td = transition(pomdp, s, a, td)
        sp = rand(rng, td, s)
        # compute obs likelihoods
        od = observation(pomdp, s, a, sp, od)
        bnew.probs_arr[i] = pdf(od, o)
        particles[i].state = sp
    end

    particles = normalize!(particles)
    bnew.probs_arr /= sum(bnew.probs_arr)

    cat = Categorical(bnew.probs_arr)

    w = 1.0 / bu.n
    bu.keep_dict ? (empty!(bnew.probs_dict)) : (nothing)
    # resample
    for i = 1:bu.n
        k = rand(cat) 
        sp = particles[k].state
        bnew.particles[i].state = deepcopy(sp)
        bnew.particles[i].weight = w
        if bu.keep_dict
            haskey(bnew.probs_dict, sp) ? (bnew.probs_dict[sp] += w) : (bnew.probs_dict[deepcopy(sp)] = w) 
        end
    end
    fill!(bnew.probs_arr, w)
    return bnew
end

function normalize!{s}(particles::Vector{Particle{s}}) 
    prob_sum = 0.0
    for p in particles
        prob_sum += p.weight
    end
    for p in particles
        p.weight /= prob_sum
    end
    return particles
end
