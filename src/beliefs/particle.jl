# maintained by @ebalaban
# Particle-based belief and state distribution types

type Particle{T}
    state::T
    weight::Float64
end

type ParticleBelief{T} <: AbstractDistribution{T}
    particles::Vector{Particle{T}}
end

typealias ParticleDistribution{T} ParticleBelief{T}