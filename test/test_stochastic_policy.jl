let

using POMDPToolbox
using POMDPModels

problem = GridWorld()

policy = UniformRandomPolicy(problem)
sim = RolloutSimulator(max_steps=10)
simulate(sim, problem, policy)

policy = CategoricalTabularPolicy(problem)
sim = RolloutSimulator(max_steps=10)
simulate(sim, problem, policy)

policy = EpsGreedyPolicy(problem, 0.5)
sim = RolloutSimulator(max_steps=10)
simulate(sim, problem, policy)

end
