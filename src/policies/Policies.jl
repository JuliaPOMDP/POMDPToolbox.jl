module Policies

using POMDPs
import POMDPs: action, value, solve, updater

using POMDPToolbox.BeliefUpdaters
using POMDPToolbox: ordered_actions
using Random
using StatsBase # for Weights
using Nullables

export
    AlphaVectorPolicy

include("alpha_vector.jl")

export
    FunctionPolicy,
    FunctionSolver

include("function.jl")

export
    RandomPolicy,
    RandomSolver

include("random.jl")

export
    VectorPolicy,
    VectorSolver,
    ValuePolicy

include("vector.jl")

export
    StochasticPolicy,
    UniformRandomPolicy,
    CategoricalTabularPolicy,
    EpsGreedyPolicy

include("stochastic.jl")

export
    PolicyWrapper,
    payload

include("utility_wrapper.jl")


end
