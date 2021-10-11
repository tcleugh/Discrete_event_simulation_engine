abstract type State end

@with_kw struct NetworkParameters
    L::Int #Number of queues
    gamma_scv::Float64 #This is constant for all scenarios at 3.0
    λ::Float64 #This is undefined for the scenarios since it is varied
    η::Float64 #This is assumed constant for all scenarios at 4.0
    μ_vector::Vector{Float64} #service rates
    P::Matrix{Float64} #routing matrix
    Q::Matrix{Float64} #overflow matrix
    p_e::Vector{Float64} #external arrival distribution
    K::Vector{Int} #Queue capacity, -1 means infinity 
end

function NetworkParameters(params::NetworkParameters; λ::Float64 = NaN)
    return NetworkParameters(L = params.L, 
                             gamma_scv = params.gamma_scv, 
                             λ = λ,
                             η = params.η,
                             μ_vector = copy(params.μ_vector),
                             P = copy(params.P),
                             Q = copy(params.Q),
                             p_e = copy(params.p_e),
                             K = copy(params.K))
end

mutable struct NetworkState <: State
    queues::Vector{Int} #A vector which indicates the number of customers in each queue
    in_transit::Int
    params::NetworkParameters #The parameters of the tandem queueing system
end

mutable struct TrackedNetworkState <: State
    queues::Vector{Vector{Job}} #A vector of queues holding the jobs waiting in buffer
    in_transit::BinaryMinHeap{Job} #Jobs in transit between queues
    left_system::Vector{Job} #Jobs that have left the system
    params::NetworkParameters #The parameters of the tandem queueing system
end