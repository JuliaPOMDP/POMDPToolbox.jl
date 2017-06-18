# provides compatibility with Distributions.jl
# maintained by @zsunberg

import Distributions
import Distributions: Distribution, UnivariateDistribution, MultivariateDistribution, Matrixvariate
import Distributions: Categorical, MvNormal

@generated function rand(rng::AbstractRNG, d::Distribution)
    Core.println("""
         WARNING: You are using a $d distribution from Distributions.jl. This will work, but simulations will not be repeatable because Distributions.jl does not support non-global random number generators (i.e. there is no `rand(rng::AbstractRNG, d::$d)`)

         For more information, or help Distributions.jl to support this, see https://github.com/JuliaStats/Distributions.jl/issues/436

         To disable this warning, use `rand(rng::AbstractRNG, d::$d) = rand(d)` (you will still not be able to repeat simulations).
         """)
    return quote
        rand(d)
    end
end

rand(rng::AbstractRNG, d::UnivariateDistribution) = Distributions.quantile(d, rand(rng)) # fallback

iterator(d::Categorical) = 1:Distributions.ncategories(d)

# sampletype(d::UnivariateDistribution) = eltype(d)
# sampletype(d::MultivariateDistribution) = Vector{eltype(d)}
# sampletype(d::Distribution{Matrixvariate}) = Matrix{eltype(d)}

# for MvNormal - this should be removed once Distributions.jl PR #597 is in a tagged Distributions.jl release
rand(rng::AbstractRNG, d::MvNormal) = _rand!(rng, d, Vector{eltype(d)}(length(d)))

function _rand!(rng::AbstractRNG, d::MvNormal, x::VecOrMat)
    Distributions.add!(Distributions.unwhiten!(d.Σ, randn!(rng, x)), d.μ)
end
