# Goals: minimize calls to ordered_states (allocates memory)

# needs pomdp for state_index in pdf(b, s)
# needs list of ordered_states for rand(b)
mutable struct DiscreteBelief{P<:POMDP, S}
    pomdp::P
    state_list::Vector{S}       # vector of ordered states
    b::Vector{Float64}
end
function DiscreteBelief(pomdp)
    state_list = ordered_states(pomdp)
    ns = n_states(pomdp)

    b = ones(ns) / ns

    return DiscreteBelief(pomdp, state_list, b)
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

# should the belief just store the length so we don't have to count?
Base.length(b::DiscreteBelief) = length(b.b)

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

# Will this cause excessive calls to DiscreteBelief ?
create_belief(bu::DiscreteUpdater) = DiscreteBelief(bu.pomdp)

function initialize_belief(bu::DiscreteUpdater, dist::Any, belief::DiscreteBelief=create_belief(bu))
    belief = fill!(belief, 0.0)
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
        error("INVALID BELIEF UPDATE")
    else
        for i = 1:length(bp); bp[i] /= bp_sum; end
    end

    return DiscreteBelief(pomdp, b.state_list, bp)
end
