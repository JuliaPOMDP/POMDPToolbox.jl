######################################################################
# alpha_vector.jl
#
# implements policy that is a set of alpha vectors
######################################################################

struct AlphaVectorPolicy{P<:POMDP, A} <: Policy
    pomdp::P
    alphas::Vector{Vector{Float64}}
    action_map::Vector{A}
end
function AlphaVectorPolicy(pomdp::POMDP, alphas)
    AlphaVectorPolicy(pomdp, alphas, ordered_actions(pomdp))
end
# assumes alphas is |S| x |A|
function AlphaVectorPolicy(p::POMDP, alphas::Matrix{Float64}, action_map)
    # turn alphas into vector of vectors
    num_actions = size(alphas, 2)
    alpha_vecs = Vector{Float64}[]
    for i = 1:num_actions
        push!(alpha_vecs, vec(alphas[:,i]))
    end

    AlphaVectorPolicy(p, alpha_vecs, action_map)
end



updater(p::AlphaVectorPolicy) = DiscreteUpdater(p.pomdp)

value(p::AlphaVectorPolicy, b::DiscreteBelief) = value(p, b.b)
function value(p::AlphaVectorPolicy, b::Vector{Float64})
    maximum(dot(b,a) for a in p.alphas)
end

function action(p::AlphaVectorPolicy, b::DiscreteBelief)
    num_vectors = length(p.alphas)
    best_idx = 1
    max_value = -Inf
    for i = 1:num_vectors
        temp_value = dot(b.b, p.alphas[i])
        if temp_value > max_value
            max_value = temp_value
            best_idx = i
        end
    end
    return p.action_map[best_idx]
end

function Base.push!(p::AlphaVectorPolicy, alpha::Vector{Float64}, a)
    push!(p.alphas, alpha)
    push!(p.action_map, a)
end

function action(p::AlphaVectorPolicy, b)
    return action(p, DiscreteBelief(p.pomdp, belief_vector(p, b)))
end


"""
Given a belief, return a vector representation bv where bv[i] is the probability
of being in the i-th state 
    belief_vector(p::AlphaVectorPolicy, b)
"""
function belief_vector(p::AlphaVectorPolicy, b)
    bv = Vector{Float64}(n_states(p.pomdp))
    for (i, s) in enumerate(ordered_states(p.pomdp))
        bv[i] = pdf(b, s)
    end
    return bv
end

"""
Given a particle belief, return the unnormalized utility function that weights each state value by the weight of 
the corresponding particle 
    unnormalized_util(p::AlphaVectorPolicy, b::AbstractParticleBelief)
"""
function unnormalized_util(p::AlphaVectorPolicy, b::AbstractParticleBelief)
    util = zeros(n_actions(p.pomdp))
    for (i, s) in enumerate(particles(b))
        j = state_index(p.pomdp, s)
        util += weight(b, i)*getindex.(p.alphas, (j,))
    end
    return util
end

function action(p::AlphaVectorPolicy, b::AbstractParticleBelief)
    util = unnormalized_util(p, b)
    ihi = indmax(util)
    return p.action_map[ihi]
end

value(p::AlphaVectorPolicy, b::AbstractParticleBelief) = maximum(unnormalized_util(p, b))/weight_sum(b)
