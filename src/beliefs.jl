type DiscreteBelief <: Belief
    b::Vector{Float64}
    bp::Vector{Float64}
    n::Int64
end
# Constructor with uniform belief
function DiscreteBelief(n::Int64)
    b = zeros(n) + 1.0/n
    bp = zeros(n) + 1.0/n
    return DiscreteBelief(b, bp, n)
end
# Constructor for user defined initial belief
function DiscreteBelief(b::Vector{Float64})
    n = length(b)
    bp = deepcopy(b)
    return DiscreteBelief(b, bp, n)
end


function update_belief(pomdp::POMDP, a::Int64, o::Int64)
    ns = n_states(pomdp)
    b = DiscreteBelief(ns)
    update_belief!(b, pomdp, a, o)
    return b
end

# TODO(max): Support for non-integer actions/observations? Will need mapping functions
# Updates the belief given the current action and observation
function update_belief!(b::DiscreteBelief, pomdp::POMDP, a::Int64, o::Int64)
    sspace = space(pomdp)
    pomdp_states = domain(sspace)
    @assert length(collect(pomdp_states)) == b.n

    od = create_observation(pomdp)
    td = create_transition(pomdp)

    belief = b.b
    new_belief = b.bp
    fill!(new_belief, 0.0)
    
    for (i, s) in enumerate(pomdp_states)
        b_sum = 0.0
        transition!(td, pomdp, s, a) 
        observation!(od, pomdp, s, a)
        for is = 1:length(td)
            t_prob = weight(td, is)
            if t_prob > 0.0
                idx = index(td, is)
                b_sum += t_prob*belief[idx] 
            end
        end
        for io = 1:length(od)
            idx = index(od, io)
            if idx == o
                new_belief[i] = weight(od, io)*b_sum
                break
            end
        end
    end
    norm = sum(new_belief)
    for i = 1:length(new_belief) new_belief[i] /= norm end
    b
end

