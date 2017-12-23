abstract type Sim end

struct POMDPSim <: Sim
    simulator::Simulator
    pomdp::POMDP
    policy::Policy
    updater::Updater
    initial_belief::Any
    initial_state::Any
    metadata::Dict{Symbol}
end

struct MDPSim <: Sim
    simulator::Simulator
    mdp::MDP
    policy::Policy
    initial_state::Any
    metadata::Dict{Symbol}
end

"""
    Sim(p::POMDP, policy::Policy, metadata=Dict(:note=>"a note"))
    Sim(p::POMDP, policy::Policy[, updater[, initial_belief[, initial_state]]]; kwargs...)

Create a `Sim` object that represents a POMDP simulation.
"""
function Sim(pomdp::POMDP,
                    policy::Policy,
                    up=updater(policy),
                    initial_belief=initial_state_distribution(pomdp),
                    initial_state=nothing;
                    rng::AbstractRNG=Base.GLOBAL_RNG,
                    max_steps::Int=typemax(Int),
                    simulator::Simulator=HistoryRecorder(rng=rng, max_steps=max_steps),
                    metadata::Dict{Symbol}=Dict{Symbol, Any}()
                   )

    if initial_state == nothing && state_type(pomdp) != Void
        is = rand(rng, initial_belief)
    else
        is = initial_state
    end
    return POMDPSim(simulator, pomdp, policy, up, initial_belief, is, metadata)
end

"""
    Sim(p::MDP, policy::Policy, metadata=Dict(:note=>"a note"))
    Sim(p::MDP, policy::Policy[, initial_state]; kwargs...)

Create a `Sim` object that represents a MDP simulation.

A vector of `Sim` objects can be executed with `run` or `run_parallel`.

## Keyword Arguments
- `rng::AbstractRNG=Base.GLOBAL_RNG`
- `max_steps::Int=typemax(Int)`
- `simulator::Simulator=HistoryRecorder(rng=rng, max_steps=max_steps)`
- `metadata::Dict{Symbol}=Dict{Symbol, Any}()` a dictionary of metadata for the sim that will be recorded, e.g. `Dict(:solver_iterations=>500)`.
"""
function Sim(mdp::MDP,
             policy::Policy,
             initial_state=nothing;
             rng::AbstractRNG=Base.GLOBAL_RNG,
             max_steps::Int=typemax(Int),
             simulator::Simulator=HistoryRecorder(rng=rng, max_steps=max_steps),
             metadata::Dict{Symbol}=Dict{Symbol, Any}()
            )

    if initial_state == nothing && state_type(mdp) != Void
        is = POMDPs.initial_state(mdp, rng) 
    else
        is = initial_state
    end
    return MDPSim(simulator, mdp, policy, is, metadata)
end

POMDPs.simulate(s::POMDPSim) = simulate(s.simulator, s.pomdp, s.policy, s.updater, s.initial_belief, s.initial_state)
POMDPs.simulate(s::MDPSim) = simulate(s.simulator, s.mdp, s.policy, s.initial_state)

default_process(s::Sim, r::Float64) = :reward=>r
default_process(s::Sim, hist::SimHistory) = default_process(s, discounted_reward(hist))

run_parallel(queue::AbstractVector; kwargs...) = run_parallel(default_process, queue; kwargs...)

"""
    run_parallel(queue::Vector{Sim})
    run_parallel(f::Function, queue::Vector{Sim})

Run `Sim` objects in `queue` in parallel and return results as a `DataFrame`.

By default, the `DataFrame` will contain the reward for each simulation and the metadata provided to the sim.

# Arguments
- `queue`: List of `Sim` objects to be executed
- `f`: Function to process the results of each simulation
This function should take two arguments, (1) the `Sim` that was executed and (2) the result of the simulation, by default a `SimHistory`. It should return a dictionary or vector of pairs of `Symbol`s and values that will appear in the dataframe. See Examples below.

## Keyword Arguments
- `progress`: a `ProgressMeter.Progress` for showing progress through the simulations; `progress=false` will suppress the progress meter

# Examples

```julia
run_parallel(queue) do sim, hist
    return [:n_steps=>n_steps(hist), :reward=>discounted_reward(hist)]
end
```
will return a dataframe with with the number of steps and the reward in it.
"""
function run_parallel(process::Function, queue::AbstractVector;
                      progress=Progress(length(queue), desc="Simulating..."),
                      proc_warn=true)

    #=
    frame_lines = pmap(progress, queue) do sim
        result = simulate(sim)
        return process(sim, result)
    end
    =#

    np = nprocs()
    if np == 1 && proc_warn
        warn("""
             run_parallel(...) was started with only 1 process, so simulations will be run in serial. 

             To supress this warning, use run_parallel(..., proc_warn=false).

             To use multiple processes, use addprocs() or the -p option (e.g. julia -p 4).
             """)
    end
    n = length(queue)
    i = 1
    prog = 0
    # based on the simple implementation of pmap here: https://docs.julialang.org/en/latest/manual/parallel-computing
    frame_lines = Vector{Any}(n)
    nextidx() = (idx=i; i+=1; idx)
    prog_lock = ReentrantLock()
    @sync begin 
        for p in 1:np
            if np == 1 || p != myid()
                @async begin
                    while true
                        idx = nextidx()
                        if idx > n
                            break
                        end
                        frame_lines[idx] = remotecall_fetch(p, queue[idx]) do sim
                            result = simulate(sim)
                            output = process(sim, result)
                            append_metadata(output, sim.metadata)
                        end
                        if progress isa Progress
                            lock(prog_lock)
                            update!(progress, prog+=1)
                            unlock(prog_lock)
                        end
                    end
                end
            end
        end
    end
    lock(prog_lock)
    finish!(progress)
    unlock(prog_lock)

    return create_dataframe(frame_lines)
end

Base.run(queue::AbstractVector) = run(default_process, queue)

"""
    run(queue::Vector{Sim})
    run(f::Function, queue::Vector{Sim})

Run the `Sim` objects in `queue` on a single process and return the results as a dataframe.

See `run_parallel` for more information.
"""
function Base.run(process::Function, queue::AbstractVector; show_progress=true)
    lines = []
    if show_progress
        @showprogress for sim in queue
            result = simulate(sim)
            push!(lines, process(sim, result))
        end
    else
        for sim in queue
            result = simulate(sim)
            output = process(sim, result)
            line = append_metadata(output, sim.metadata)
            push!(lines, line)
        end
    end
    return create_dataframe(lines)
end

append_metadata(single::Pair, metadata::Dict) = vcat(Any[single], collect(metadata))
append_metadata(pairvec::AbstractVector, metadata::Dict) = vcat(pairvec, collect(metadata))
append_metadata(d::Dict, metadata::Dict) = merge!(d, metadata)

metadata_as_pairs(s::Sim) = convert(Array{Any}, collect(s.metadata))

function create_dataframe(lines::Vector)
    master = Dict{Symbol, AbstractVector}()
    for line in lines
        push_line!(master, line)
    end
    return DataFrame(master)
end

function _push_line!(d::Dict{Symbol, AbstractVector}, line)
    if isempty(d)
        len = 0
    else
        len = length(first(values(d)))
    end
    for (key, val) in line
        if !haskey(d, key)
            d[key] = Array{Any}(len)
        end
        data = d[key]
        if !(typeof(val) <: eltype(data))
            d[key] = convert(Array{Any,1}, data)
        end
        push!(d[key], val)
    end
    for da in values(d)
        if length(da) < len + 1
            push!(da, missing)
        end
    end
    return d
end
push_line!(d::Dict{Symbol, AbstractVector}, line::Dict) = _push_line!(d, line)
push_line!(d::Dict{Symbol, AbstractVector}, line::DataFrame) = _push_line!(d, n=>first(line[n]) for n in names(line))
push_line!(d::Dict{Symbol, AbstractVector}, line::AbstractVector) = _push_line!(d, line)
push_line!(d::Dict{Symbol, AbstractVector}, line::Tuple) = _push_line!(d, line)
push_line!(d::Dict{Symbol, AbstractVector}, line::Pair) = _push_line!(d, (line,))
