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
    num_vectors = length(p.alphas)
    max_value = -Inf
    for i = 1:num_vectors
        temp_value = dot(b, p.alphas[i])
        temp_value > max_value && (max_value = temp_value)
    end
    return max_value
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
