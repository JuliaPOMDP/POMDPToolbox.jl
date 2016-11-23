# sample function for WeightVec that uses an arbitrary rng
# maintained by @zsunberg
# A WeightVec can often be used in place of a Categorical Distribution

import StatsBase: WeightVec, sample
import Iterators

function sample(rng::AbstractRNG, wv::WeightVec)
    t = rand(rng) * sum(wv)
    w = values(wv)
    n = length(w)
    i = 1
    cw = w[1]
    while cw < t && i < n
        i += 1
        @inbounds cw += w[i]
    end
    return i
end

sample(rng::AbstractRNG, a::AbstractArray, wv::WeightVec) = a[sample(rng,wv)]
sample(rng::AbstractRNG, iterable, wv::WeightVec) = Iterators.nth(iterable, sample(rng, wv))
