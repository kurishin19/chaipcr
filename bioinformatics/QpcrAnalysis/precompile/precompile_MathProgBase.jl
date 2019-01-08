function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(Tuple{typeof(MathProgBase.SolverInterface.eval_jac_g), JuMP.NLPEvaluator, Array{Float64, 1}, Array{Float64, 1}})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.eval_f), JuMP.NLPEvaluator, Array{Float64, 1}})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.jac_structure), JuMP.NLPEvaluator})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.hesslag_structure), JuMP.NLPEvaluator})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.initialize), JuMP.NLPEvaluator, Array{Symbol, 1}})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.features_available), JuMP.NLPEvaluator})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.eval_g), JuMP.NLPEvaluator, Array{Float64, 1}, Array{Float64, 1}})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.status), Ipopt.IpoptMathProgModel})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.eval_hesslag), JuMP.NLPEvaluator, Array{Float64, 1}, Array{Float64, 1}, Float64, Array{Float64, 1}})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.eval_grad_f), JuMP.NLPEvaluator, Array{Float64, 1}, Array{Float64, 1}})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.loadproblem!), Ipopt.IpoptMathProgModel, Int64, Int64, Array{Float64, 1}, Array{Float64, 1}, Array{Float64, 1}, Array{Float64, 1}, Symbol, JuMP.NLPEvaluator})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.getobjval), Ipopt.IpoptMathProgModel})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.NonlinearModel), Ipopt.IpoptSolver})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.setwarmstart!), Ipopt.IpoptMathProgModel, Array{Float64, 1}})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.getsolution), Ipopt.IpoptMathProgModel})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.getreducedcosts), Ipopt.IpoptMathProgModel})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.optimize!), Ipopt.IpoptMathProgModel})
    precompile(Tuple{typeof(MathProgBase.SolverInterface.getconstrduals), Ipopt.IpoptMathProgModel})
end