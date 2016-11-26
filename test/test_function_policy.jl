
p = FunctionPolicy(x::Bool->!x)
@test action(p, true) == false

s = FunctionSolver(x::Int->2*x)
p = solve(s, GridWorld())
@test action(p, 10) == 20
