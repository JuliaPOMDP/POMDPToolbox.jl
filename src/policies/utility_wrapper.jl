"""
    PolicyWrapper

Flexible utility wrapper for a policy designed for collecting statistics about planning.

Carries a function, a policy, and a payload (that can be any type).

The function should typically be defined with the do syntax, each time action is called on the wrapper, this function will be called with three arguments: the policy, the payload, and the current state or belief. The function should return an appropriate action. The idea is that, in this function, `action(policy, s)` should be called, statistics from the policy/planner should be collected and saved in the payload, exceptions can be handled, and the action should be returned.

Example:

    using POMDPModels
    using POMDPToolbox

    mdp = GridWorld()
    policy = RandomPolicy(mdp)
    counts = Dict(a=>0 for a in iterator(actions(mdp)))

    wrapper = PolicyWrapper(policy, payload=counts) do policy, counts, s
        a = action(policy, s)
        counts[a] += 1
        return a
    end

    h = simulate(HistoryRecorder(max_steps=100), mdp, wrapper)
    for (a, count) in wrapper.payload
        println("policy chose action \$a \$count of \$(n_steps(h)) times.")
    end
"""
mutable struct PolicyWrapper{P<:Policy, F<:Function, PL} <: Policy
    f::F
    policy::P
    payload::PL
end

function PolicyWrapper(f::Function, policy::Policy; payload=nothing)
    return PolicyWrapper(f, policy, payload)
end

function PolicyWrapper(policy::Policy; payload=nothing)
    return PolicyWrapper((p,s)->action(p.policy,s), policy, payload)
end

action(p::PolicyWrapper, s) = p.f(p.policy, p.payload, s)

updater(p::PolicyWrapper) = updater(p.policy)
