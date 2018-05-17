pomdp = BabyPOMDP()

bu = DiscreteUpdater(pomdp)
b0 = initialize_belief(bu, initial_state_distribution(pomdp))

# these values were gotten from FIB.jl
alphas = [-29.4557 -36.5093; -19.4557 -16.0629]
policy = AlphaVectorPolicy(pomdp, alphas)

# initial belief is 100% confidence in baby not being hungry
@test isapprox(value(policy, b0), -16.0629)
@test isapprox(value(policy, [0.0,1.0]), -16.0629)

# because baby isn't hungry, policy should not feed (return false)
@test action(policy, b0) == false

# try pushing new vector
push!(policy, [0.0,0.0], true)

@test value(policy, b0) == 0.0
@test action(policy, b0) == true

