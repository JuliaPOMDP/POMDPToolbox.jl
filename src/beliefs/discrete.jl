# Goals: minimize calls to ordered_states (allocates memory)

# needs pomdp for state_index in pdf(b, s)
# needs list of ordered_states for rand(b)
struct DiscreteBelief{P<:POMDP, S}
    pomdp::P
    state_list::Vector{S}       # vector of ordered states
    b::Vector{Float64}
end
function DiscreteBelief(pomdp, b::Vector{Float64})
    return DiscreteBelief(pomdp, ordered_states(pomdp), b)
end


"""
Returns a DiscreteBelief with equal probability for each state.
"""
function uniform_belief(pomdp)
    state_list = ordered_states(pomdp)
    ns = length(state_list)
    return DiscreteBelief(pomdp, state_list, ones(ns) / ns)
end


pdf(b::DiscreteBelief, s) = b.b[state_index(b.pomdp, s)]

function rand(rng::AbstractRNG, b::DiscreteBelief)
    i = sample(rng, Weights(b.b))
    return b.state_list[i]
end

function Base.fill!(b::DiscreteBelief, x::Float64)
    fill!(b.b, x)
    return b
end

Base.length(b::DiscreteBelief) = length(b.b)

# equality only depends on belief values
# does not check that POMDP is the same;
#  if you are comparing beliefs from different POMDPs you are beyond help
==(b1::DiscreteBelief, b2::DiscreteBelief) = b1.b == b2.b

# I think this is a disaster and should be removed, but SARSOP.jl uses it
# 
# alphas are |A|x|S| (LD: it looks like |S|x|A|)
# computes dot product of alpha vectors and belief
# util is array with utility of each alpha vecotr for belief b
function product(alphas::Matrix{Float64}, b::DiscreteBelief)
    @assert size(alphas, 1) == length(b) "Alpha and belief sizes not equal"
    n = size(alphas, 2) 
    util = zeros(n)
    for i = 1:n
        s = 0.0
        for j = 1:length(b)
            s += alphas[j,i]*b[j]
        end
        util[i] = s
    end
    return util
end



mutable struct DiscreteUpdater{P<:POMDP} <: Updater
    pomdp::P
end


function initialize_belief(bu::DiscreteUpdater, dist::Any)
    state_list = ordered_states(bu.pomdp)
    ns = length(state_list)
    b = ones(ns) / ns
    belief = DiscreteBelief(bu.pomdp, state_list, b)
    for s in iterator(dist)
        sidx = state_index(bu.pomdp, s)
        belief.b[sidx] = pdf(dist, s)
    end
    return belief
end

function update(bu::DiscreteUpdater, b::DiscreteBelief, a, o)
    pomdp = b.pomdp
    state_space = b.state_list
    bp = zeros(length(state_space))

    bp_sum = 0.0   # to normalize the distribution

    for (spi, sp) in enumerate(state_space)

        # po = O(a, sp, o)
        od = observation(pomdp, a, sp)
        po = pdf(od, o)

        if po == 0.0
            continue
        end

        b_sum = 0.0
        for (si, s) in enumerate(state_space)
            td = transition(pomdp, s, a)
            pp = pdf(td, sp)
            b_sum += pp * b.b[si]
        end

        bp[spi] = po * b_sum
        bp_sum += bp[spi]
    end

    if bp_sum == 0.0
        error("""
              Failed discrete belief update: new probabilities sum to zero.

              b = $b
              a = $a
              o = $o

              Failed discrete belief update: new probabilities sum to zero.
             """)
    else
        for i = 1:length(bp); bp[i] /= bp_sum; end
    end

    return DiscreteBelief(pomdp, b.state_list, bp)
end
