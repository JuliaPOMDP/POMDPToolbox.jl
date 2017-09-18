let
    d = SparseCat([:a, :b, :d], [0.4, 0.5, 0.1])
    c = collect(weighted_iterator(d))
    @test c == [:a=>0.4, :b=>0.5, :d=>0.1]
    @test pdf(d, :c) == 0.0
    @test pdf(d, :a) == 0.4
    @test mode(d) == :b
end
