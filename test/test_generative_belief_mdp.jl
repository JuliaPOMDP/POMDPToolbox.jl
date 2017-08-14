let
    pomdp = BabyPOMDP()
    updater = BabyBeliefUpdater(pomdp)

    bmdp = GenerativeBeliefMDP(pomdp, updater)
    b = initial_state(bmdp, Base.GLOBAL_RNG)
    @inferred generate_sr(bmdp, b, true, MersenneTwister(4))
end
