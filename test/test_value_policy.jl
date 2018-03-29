gw = GridWorld(sx=2, sy=2, rs=[GridWorldState(1,1)], rv=[10.0])
s = initial_state(gw, MersenneTwister(4))

policy = ValuePolicy(gw)

for s in iterator(states(gw))
    @test action(policy, s) isa action_type(gw)
end

@get_requirements ValuePolicy(gw)
@get_requirements action(policy, s)
