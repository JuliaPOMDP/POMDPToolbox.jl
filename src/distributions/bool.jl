"""
    BoolDistribution

A distribution that provides the probabilities of true or false. 
Can construct with `BoolDistribution(p_true)`.
"""
struct BoolDistribution
    p::Float64 # probability of true
end

pdf(d::BoolDistribution, s::Bool) = s ? d.p : 1.0-d.p

rand(rng::AbstractRNG, d::BoolDistribution) = rand(rng) <= d.p

iterator(d::BoolDistribution) = [true, false]

==(d1::BoolDistribution, d2::BoolDistribution) = d1.p == d2.p

Base.hash(d::BoolDistribution) = hash(d.p)

Base.length(d::BoolDistribution) = 2
