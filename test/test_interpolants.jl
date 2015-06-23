
@test isapprox(POMDPToolbox.Φ(-Inf), 0.0)
@test isapprox(POMDPToolbox.Φ(Inf), 1.0)
@test isapprox(POMDPToolbox.Φ(0.0), 0.5)
@test isapprox(POMDPToolbox.Φ(-1.0), 0.1587, atol=0.0001)
@test isapprox(POMDPToolbox.Φ( 1.0), 0.8413, atol=0.0001)

@test isapprox(POMDPToolbox.zval(0.0, 0.0, 1.0), 0.0)
@test isapprox(POMDPToolbox.zval(0.0, 0.0, 2.0), 0.0)
@test isapprox(POMDPToolbox.zval(1.0, 0.0, 1.0), 1.0)
@test isapprox(POMDPToolbox.zval(1.0, 1.0, 1.0), 0.0)

@test isapprox(POMDPToolbox.cdf(-Inf, 10.0, 10.0), 0.0)
@test isapprox(POMDPToolbox.cdf(10.0, 10.0, 10.0), 0.5)
@test isapprox(POMDPToolbox.cdf(12.0, 10.0,  5.0), 0.65542, atol=1e-5)

interps = Interpolants()
@test interps.length == 0
@test length(interps) == 0

push!(interps, 1, 1.0)
@test interps[1] == (1,1.0)
@test length(interps) == 1

empty!(interps)
@test length(interps) == 0
@test_throws ErrorException interps[1]

interpolants_gaussian_1d!(interps, [-1.0,0.0,1.0], [1,2,3], 0.0, 1.0)
@test interps.indeces[1:3] == [1,2,3]
@test isapprox(interps.weights[1], 0.308537, atol=1e-6)
@test isapprox(interps.weights[2], 0.382924, atol=1e-6)
@test isapprox(interps.weights[3], 0.308537, atol=1e-6)
@test length(interps) == 3
i,v = interps[2]
@test i == 2
@test isapprox(v, 0.382924, atol=1e-6)

interpolants_uniform_1d!(interps, [-1.0,0.0,2.0], [1,2])
@test interps.indeces[4:5] == [1,2]
@test isapprox(interps.weights[4], 0.333333, atol=1e-6)
@test isapprox(interps.weights[5], 0.666666, atol=1e-6)
@test length(interps) == 5
i,v = interps[5]
@test i == 2
@test isapprox(v, 0.666666, atol=1e-6)