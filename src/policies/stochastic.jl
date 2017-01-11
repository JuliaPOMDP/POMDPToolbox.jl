### StochasticPolicy ###
# maintained by @etotheipluspi

type StochasticPolicy <: Policy
    rng::AbstractRNG
    distribution
    problem::Union{POMDP,MDP}
    updater::Updater # set this to use a custom updater, by default it will be a void updater
end
# The constructor below should be used to create the policy so that the action space is initialized correctly
StochasticPolicy(problem::Union{POMDP,MDP},
                 distribution;
                 rng=Base.GLOBAL_RNG,
                 updater=VoidUpdater()) = StochasticPolicy(rng, distribution, problem, updater)

## policy execution ##
function action(policy::StochasticPolicy, s)
    return rand(policy.rng, policy.distribution)
end

function action(policy::StochasticPolicy, b::Void)
    return rand(policy.rng, policy.distribution)
end


# Samples actions uniformly
UniformRandomPolicy(problem::Union{POMDP,MDP};
                 rng=Base.GLOBAL_RNG,
                 updater=VoidUpdater()) = StochasticPolicy(rng, actions(problem), problem, updater)



type CategoricalTabularPolicy
    stochastic::StochasticPolicy
    value::ValuePolicy
end
CategoricalTabularPolicy(mdp::Union{POMDP,MDP};
                 rng=Base.GLOBAL_RNG,
                 updater=VoidUpdater()) = CategoricalTabularPolicy(StochasticPolicy(mdp,
                 WeightVec(zeros(n_actions(mdp)))), ValuePolicy(mdp))

function action(policy::CategoricalTabularPolicy, s)
    policy.stochastic.distribution = WeightVec(policy.value.value_table[state_index(policy.stochastic.problem, s),:])
    return p.value.act[sample(policy.stochastic.rng, policy.stochastic.distribution)]
end


type EpsGreedyPolicy <: Policy
    eps::Float64
    val::ValuePolicy
    uni::StochasticPolicy
end

EpsGreedyPolicy(mdp::Union{MDP,POMDP}, eps::Float64;
                rng=Base.GLOBAL_RNG) = EpsGreedyPolicy(eps, ValuePolicy(mdp), UniformRandomPolicy(mdp, rng=rng))

function action(policy::EpsGreedyPolicy, s)
    if rand(policy.uni.rng) > policy.eps
        return action(policy.val, s)
    else
        return action(policy.uni, s)
    end
end

