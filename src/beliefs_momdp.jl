# Check if MOMDPs is installed
if isdir(Pkg.dir("MOMDPs"))

using MOMDPs

function update_belief(pomdp::MOMDP, x::Int64, a::Int64, o::Int64)
    yspace = part_obs_space(pomdp)
    ystates = domain(yspace)
    ns = length(collect(ystates))
    b = DiscreteBelief(ns)
    update_belief!(b, pomdp, a, o)
    return b
end

# Updates the belief for a MOMDP with x fully observable variables index
function update_belief!(b::DiscreteBelief, pomdp::MOMDP, x::Int64, a::Int64, o::Int64)
    # asset that number of part observable states is size of belief
    yspace = part_obs_space(pomdp)
    ystates = domain(yspace)
    @assert length(collect(ystates)) == b.n

    od = create_observation(pomdp)
    td1 = create_partially_obs_transition(pomdp)
    td2 = create_partially_obs_transition(pomdp)

    belief = b.b
    new_belief = b.bp
    fill!(new_belief, 0.0)

    for (i, yp) in enumerate(ystates)
        b_sum = 0.0
        transition!(td1, pomdp, x, yp, a) 
        observation!(od, pomdp, x, yp, a)
        for iy = 1:length(td1) 
            p = weight(td1, iy)
            if p > 0.0
                y = index(td1, iy)
                transition!(td2, pomdp, x, y, a) 
                for jy = 1:length(td2) 
                    pp = weight(td2, jy)        
                    if pp > 0.0
                        ypidx = index(td2, jy)
                        if ypidx == yp
                            b_sum += pp*belief[y] 
                        end
                    end
                end
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
    # if norm is zero, the update was invalid - reset to uniform
    if norm == 0.0
        u = 1.0/length(b)
        fill!(b, u)
    else
        for i = 1:length(new_belief) new_belief[i] /= norm end
        belief[1:end] = new_belief[1:end]
    end
    b
end

end # if check for MOMDPs
