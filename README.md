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

## Content

POMDPToolbox contains tools for updating POMDP beliefs, defining POMDP models, and simulating POMDP policies. 
