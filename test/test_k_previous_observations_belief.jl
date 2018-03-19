using POMDPToolbox
using POMDPModels
using Base.Test


function test_initial_belief(b0, o0)
    for i=1:5
        if b0[i] != o0
            return false
        end
    end
    return true
end

rng = MersenneTwister(0)
pomdp = RandomPOMDP()

# test constructor
up = KMarkovUpdater(5)

o0 = rand(rng, observations(pomdp))
b0 = initialize_belief(up, o0)

@test typeof(b0[1]) == typeof(o0)
@test length(b0) == up.k == 5
@test test_initial_belief(b0, o0)

# generate random observation and stack them
o = rand(rng, observations(pomdp))
b = b0
bp = update(up, b, rand(rng, actions(pomdp)), o)
@test bp[end] == o
@test length(bp) == up.k == 5
@test bp[1:end-1] == fill(o0, length(bp)-1)

# check that b is unchanged
@test b == initialize_belief(up, o0)

b = bp
op = rand(rng, observations(pomdp))
bp = update(up, bp, rand(rng, actions(pomdp)), op)
@test bp[end] == op
@test bp[end-1] == o
@test length(bp) == up.k == 5
@test bp[1:end-2] == fill(o0, length(bp)-2)
