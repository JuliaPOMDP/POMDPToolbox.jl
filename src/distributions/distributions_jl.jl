# (begrudgingly) provides compatibility with Distributions.jl
# maintained by @zsunberg

import Distributions
import Distributions: Distribution, UnivariateDistribution, Categorical

@generated function rand(rng::AbstractRNG, d::Distribution)
    warn("""
         You are using a $d distribution from Distributions.jl. This will work, but simulations will not be repeatable because Distributions.jl does not support arbitrary random number generators (i.e. there is no `rand(rng::AbstractRNG, d::$d)`)

         For more information, or to encourage Distributions.jl to support this, see https://github.com/JuliaStats/Distributions.jl/issues/436

         To disable this warning, use `rand(rng::AbstractRNG, d::$d) = rand(d)` (you will still not be able to repeat simulations).
         """)
    return quote
        rand(d)
    end
end

rand(rng::AbstractRNG, d::UnivariateDistribution) = Distributions.quantile(d, rand(rng))

pdf(d::Distribution, x) = Distributions.pdf(d,x)
iterator(d::Categorical) = 1:Distributions.ncategories(d)
