let
    d = SparseCat([:a, :b, :d], [0.4, 0.5, 0.1])
    c = collect(weighted_iterator(d))
    @test c == [:a=>0.4, :b=>0.5, :d=>0.1]
    @test pdf(d, :c) == 0.0
    @test pdf(d, :a) == 0.4
    @test mode(d) == :b
    @inferred rand(Base.GLOBAL_RNG, d)

    rng = MersenneTwister(14)
    samples = Symbol[]
    N = 100_000
    @time for i in 1:N
        push!(samples, rand(rng, d))
    end
    @test isapprox(count(samples.==:a)/N, pdf(d,:a), atol=0.005)
    @test isapprox(count(samples.==:b)/N, pdf(d,:b), atol=0.005)
    @test isapprox(count(samples.==:c)/N, pdf(d,:c), atol=0.005)
    @test isapprox(count(samples.==:d)/N, pdf(d,:d), atol=0.005)
end
