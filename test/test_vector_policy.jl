gw = GridWorld(sx=2, sy=2, rs=[GridWorldState(1,1)], rv=[10.0])

pvec = fill(GridWorldAction(:left), 5)

solver = VectorSolver(pvec)

p = solve(solver, gw)

for s in iterator(states(gw))
    @test action(p, s) == GridWorldAction(:left)
end

p2 = VectorPolicy(gw, pvec)
for s in iterator(states(gw))
    @test action(p2, s) == GridWorldAction(:left)
end
