### StochasticPolicy ###
# maintained by @etotheipluspi

mutable struct StochasticPolicy{D, RNG <: AbstractRNG} <: Policy
    distribution::D
    rng::RNG
end
# The constructor below should be used to create the policy so that the action space is initialized correctly
StochasticPolicy(distribution; rng=Base.GLOBAL_RNG) = StochasticPolicy(distribution, rng)

## policy execution ##
function action(policy::StochasticPolicy, s)
    return rand(policy.rng, policy.distribution)
end

## convenience functions ##
updater(policy::StochasticPolicy) = VoidUpdater() # since the stochastic policy does not depend on the belief

# Samples actions uniformly
UniformRandomPolicy(problem, rng=Base.GLOBAL_RNG) = StochasticPolicy(actions(problem), rng)


mutable struct CategoricalTabularPolicy <: Policy
    stochastic::StochasticPolicy
    value::ValuePolicy
end
CategoricalTabularPolicy(mdp::Union{POMDP,MDP}; rng=Base.GLOBAL_RNG) = CategoricalTabularPolicy(StochasticPolicy(Weights(zeros(n_actions(mdp)))), ValuePolicy(mdp))

function action(policy::CategoricalTabularPolicy, s)
    policy.stochastic.distribution = Weights(policy.value.value_table[state_index(policy.value.mdp, s),:])
    return policy.value.act[sample(policy.stochastic.rng, policy.stochastic.distribution)]
end


mutable struct EpsGreedyPolicy <: Policy
    eps::Float64
    val::ValuePolicy
    uni::StochasticPolicy
end

EpsGreedyPolicy(mdp::Union{MDP,POMDP}, eps::Float64;
                rng=Base.GLOBAL_RNG) = EpsGreedyPolicy(eps, ValuePolicy(mdp), UniformRandomPolicy(mdp, rng))

function action(policy::EpsGreedyPolicy, s)
    if rand(policy.uni.rng) > policy.eps
        return action(policy.val, s)
    else
        return action(policy.uni, s)
    end
end
