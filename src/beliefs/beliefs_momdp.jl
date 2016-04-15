# Check if MOMDPs is installed
if isdir(Pkg.dir("MOMDPs"))

using MOMDPs


type DiscreteMOMDPUpdater <: BeliefUpdater
    momdp::POMDP
end

create_belief(updater::DiscreteMOMDPUpdater) = DiscreteBelief(length(collect(iterator(part_obs_space(updater.momdp)))))


# Updates the belief for a MOMDP with x fully observable variables index
function update(updater::DiscreteMOMDPUpdater, bold::DiscreteBelief, a::Action, o::Observation, x, bnew::DiscreteBelief=create_belief(updater))
    pomdp = updater.momdp
    # asset that number of part observable states is size of belief
    yspace = part_obs_space(pomdp)
    ystates = iterator(yspace)
    @assert length(collect(ystates)) == b.n
    b.valid = true
    # initialize distributions
    od = create_observation_distribution(pomdp)
    td = create_partially_obs_transition(pomdp)
    # initialize belief
    fill!(bnew, 0.0)
    # iterate through all the partially observable states
    for (i, yp) in enumerate(ystates)
        # update the distributions
        od = observation(pomdp, x, yp, a, od)
        # get prob of observation o from current distribution
        probo = pdf(od, o)
        # if observation prob is 0.0, then skip rest of update b/c bnew[i] is zero
        probo == 0.0 ? (continue) : (nothing)
        b_sum = 0.0 # belief for state sp
        for (j, y) in enumerate(ystates) 
            td = transition(pomdp, x, y, a, td)
            pp = pdf(td, yp)
            b_sum += pp * bold[j]
        end
        bnew[i] = probo * b_sum
    end
    norm = sum(new_belief)
    # if norm is zero, the update was invalid - reset to uniform
    if norm == 0.0
        u = 1.0/length(bnew)
        fill!(bnew, u)
    else
        for i = 1:length(bnew); bnew[i] /= norm; end
    end
    bnew
end

end # if check for MOMDPs
