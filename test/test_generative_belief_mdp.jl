let
    pomdp = BabyPOMDP()
    up = updater(pomdp)

    bmdp = GenerativeBeliefMDP(pomdp, up)
    b = initial_state(bmdp, Base.GLOBAL_RNG)
    @inferred generate_sr(bmdp, b, true, MersenneTwister(4))
end
