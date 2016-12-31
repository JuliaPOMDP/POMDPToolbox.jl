import Distributions.MvNormal
import Distributions.Categorical

mvn = MvNormal([1.2,2.3], [1.4 1.0; 1.0 1.2])

@test_approx_eq pdf(mvn, [1.0, 1.0]) 0.04794537749882221

println("There should be a warning below.")
rand(MersenneTwister(12), mvn)

cat = Categorical(3)
println("There should NOT be a warning between here")
rand(MersenneTwister(12), cat)
println("and here.")
