# a convenient way of interacting with a simulation
# maintained by @zsunberg

"""
    sim(polfunc::Function, mdp::MDP)
    sim(polfunc::Function, pomdp::POMDP)

Alternative way of running a simulation with a function specifying how to calculate the action at each timestep.

The intended usage is

    sim(mdp) do s
        # code that calculates action `a` based on `s` - this is the policy
        # you can also do other things like display something
        return a
    end

for an MDP or

    sim(pomdp) do o
        # code that does belief updates with observation `o` and calculates `a`
        # you can also do other things like display something
        return a
    end

for a POMDP.

Use the `simulator` keyword argument to specify any simulator to run the simulation. If nothing is specified for the simulator, a HistoryRecorder will be used as the simulator, with all keyword arguments forwarded to it, e.g.

    sim(mdp, max_steps=100) do s
        # ...
    end

will limit the simulation to 100 steps
"""
function sim end

function sim(polfunc::Function, mdp::MDP,
             init_state=initial_state(mdp, Base.GLOBAL_RNG);
             simulator=nothing,
             kwargs...
            )
    if simulator==nothing
        simulator = HistoryRecorder(;kwargs...)
    end
    policy = FunctionPolicy(polfunc)
    simulate(simulator, mdp, policy, init_state)
end

function sim(polfunc::Function, pomdp::POMDP,
             init_state=initial_state(pomdp, Base.GLOBAL_RNG);
             simulator=nothing,
             init_obs=default_init_obs(pomdp, init_state),
             updater=PrimedPreviousObservationUpdater{Any}(init_obs),
             kwargs...
            )
    if simulator==nothing
        simulator = HistoryRecorder(;initial_state=init_state, kwargs...)
    end
    policy = FunctionPolicy(polfunc)
    simulate(simulator, pomdp, policy, updater)
end

function default_init_obs(p::POMDP, s)
    if implemented(generate_o, Tuple{typeof(p), typeof(s), typeof(Base.GLOBAL_RNG)})
        return generate_o(p, s, Base.GLOBAL_RNG)
    else
        return nothing
    end
end
