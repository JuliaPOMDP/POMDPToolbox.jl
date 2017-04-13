# POMDPToolbox
[![Build Status](https://travis-ci.org/JuliaPOMDP/POMDPToolbox.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/POMDPToolbox.jl)
[![Coverage Status](https://coveralls.io/repos/github/JuliaPOMDP/POMDPToolbox.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaPOMDP/POMDPToolbox.jl?branch=master)

Support tools for POMDPs.jl. This is a supported [JuliaPOMDP](https://github.com/JuliaPOMDP) package that provides tools
for belief updating, problem modeling, and running simulations. 

## Installation

This package requires [POMDPs.jl](https://github.com/JuliaPOMDP). To install this module run the following command:

```julia
using POMDPs
POMDPs.add("POMDPToolbox")
```

## Code structure

Within src, there are three directories representing classes of tools, beliefs, policies, and simulators.

Within each class directory, each file contains one tool. Each file should clearly indicate who is the maintainer of that file.

## Tools

### Beliefs
  discrete.jl
  particle.jl
  previous_observation.jl
  void.jl
### Convenience
  implementations.jl
### Distributions
  distributions_jl.jl
### Model
  initial.jl
  ordered_spaces.jl
### Policies
  function.jl
  random.jl
  stochastic.jl
  vector.jl
### Random
  weight_vec.jl
### Simulators
  history.jl
  history_recorder.jl
  rollout.jl
  sim.jl
### Testing
  model.jl
  solver.jl

