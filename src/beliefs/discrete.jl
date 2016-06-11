# Maintained by Max Egorov

type DiscreteBelief 
    b::Vector{Float64}
    bp::Vector{Float64}
    n::Int64
    valid::Bool
end
# Constructor with uniform belief
function DiscreteBelief(n::Int64)
    b = zeros(n) + 1.0/n
    bp = zeros(n) + 1.0/n
    return DiscreteBelief(b, bp, n, true)
end
# Constructor for user defined initial belief
function DiscreteBelief(b::Vector{Float64})
    n = length(b)
    bp = deepcopy(b)
    bpp = deepcopy(b)
    return DiscreteBelief(bpp, bp, n, true)
end

type DiscreteUpdater <: Updater{DiscreteBelief}
    # convenience type
    pomdp::POMDP
end

vec(b::DiscreteBelief) = b.b

Base.length(b::DiscreteBelief) = b.n
index(b::DiscreteBelief, i::Int64) = i
weight(b::DiscreteBelief, i::Int64) = b.b[i]
valid(b::DiscreteBelief) = b.valid

function Base.fill!(b::DiscreteBelief, x::Float64)
    fill!(b.b, x)
    fill!(b.bp, x)
    b
end

function Base.fill!(b::DiscreteBelief, idxs::Vector{Int64}, vals::Vector{Float64})
    fill!(b.b, 0.0)
    fill!(b.bp, 0.0)
    for i = 1:length(idxs)
        index = idxs[i]
        index > 0 ? (b[index] = vals[i]) : nothing 
    end
    b
end

function Base.setindex!(b::DiscreteBelief, x::Float64, i::Int64) 
    b.b[i] = x
    b.bp[i] = x
    b
end

function Base.getindex(b::DiscreteBelief, i::Int64)
    return b.b[i]
end

function Base.copy!(b1::DiscreteBelief, b2::DiscreteBelief)
    copy!(b1.b, b2.b)
    copy!(b1.bp, b2.bp)
end

Base.sum(b::DiscreteBelief) = sum(b.b)

create_belief(bu::DiscreteUpdater) = DiscreteBelief(n_states(bu.pomdp))


function initialize_belief(bu::DiscreteUpdater, dist::AbstractDistribution, belief::DiscreteBelief = create_belief(bu))
    belief = fill!(belief, 0.0)
    for s in iterator(dist)
        sidx = state_index(bu.pomdp, s) 
        belief[sidx] = pdf(dist, s)  
    end
    return belief
end


# Updates the belief given the current action and observation
function update{A,O}(bu::DiscreteUpdater, bold::DiscreteBelief, a::A, o::O, bnew::DiscreteBelief=create_belief(bu))
    pomdp = bu.pomdp
    # initialize spaces
    sspace = states(pomdp)
    pomdp_states = iterator(sspace)
    # ensure belief state sizes match 
    @assert length(bold) == length(bnew)
    # initialize distributions
    od = create_observation_distribution(pomdp)
    td = create_transition_distribution(pomdp)
    # initialize belief 
    fill!(bnew, 0.0)
    # iterate through each state in belief vector
    for (i, sp) in enumerate(pomdp_states)
        # get the distributions
        observation(pomdp, sp, a, od)
        # get prob of observation o from current distribution
        probo = pdf(od, o)
        # if observation prob is 0.0, then skip rest of update b/c bnew[i] is zero
        probo == 0.0 ? (continue) : (nothing)
        b_sum = 0.0 # belief for state sp
        for (j, s) in enumerate(pomdp_states)
            transition(pomdp, s, a, td)
            pp = pdf(td, sp)
            b_sum += pp * bold[j]
        end
        bnew[i] = probo * b_sum
    end
    norm = sum(bnew)
    # if norm is zero, the update was invalid - reset to uniform
    if norm == 0.0
        u = 1.0/length(bnew)
        fill!(bnew, u)
    else
        for i = 1:length(bnew); bnew[i] /= norm; end
    end
    bnew
end


# alphas are |A|x|S|
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
