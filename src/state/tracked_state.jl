import Base: push!, isless

abstract type PositionRecord end

struct InTransit <: PositionRecord
    time::Float64
end

struct InQueue <: PositionRecord
    time::Float64
    queue::Int
end

struct LeaveSystem <: PositionRecord
    time::Float64
end

mutable struct JobPath 
    history::Vector{PositionRecord}
end

JobPath() = JobPath([])
JobPath(entry::PositionRecord) = JobPath([entry])

duration(job::JobPath)::Float64 = last(job.history).time - first(job.history).time


function push!(job::JobPath, pos::PositionRecord)
    push!(job.history, pos)
end

isless(j1::JobPath, j2::JobPath) = last(j1.history).time < last(j2.history).time

mutable struct FullTrackedNetworkState <: State
    queues::Vector{Vector{JobPath}} #A vector of queues holding the jobs waiting in buffer
    in_transit::BinaryMinHeap{JobPath} #Jobs in transit between queues
    left_system::Vector{JobPath} #Jobs that have left the system
    params::NetworkParameters #The parameters of the queueing system
end

"""
Constructs an initilized tracked network state from the given parameters
"""
FullTrackedNetworkState(params::NetworkParameters) = FullTrackedNetworkState([Vector{JobPath}[] for _ in 1:params.L], # Initial queues
                                                                     BinaryMinHeap{JobPath}(),                # Intial transit
                                                                     Vector{JobPath}[],                       # Initial left system
                                                                     params
                                                                    )

"""
Constructs an initilized tracked network state from the given parameters and altered λ
"""
FullTrackedNetworkState(params::NetworkParameters, λ::Float64) = FullTrackedNetworkState([Vector{JobPath}[] for _ in 1:params.L], # Initial queues
                                                                                 BinaryMinHeap{JobPath}(),                # Intial transit
                                                                                 Vector{JobPath}[],                       # Initial left system
                                                                                 NetworkParameters(params, λ = λ)
                                                                                )


queued_count(tns::FullTrackedNetworkState)::Int = sum([length(tns.queues[i]) for i in 1:length(tns.queues)])
transit_count(tns::FullTrackedNetworkState)::Int = length(tns.in_transit)
total_count(tns::FullTrackedNetworkState)::Int = queued_count(tns) + transit_count(tns) 
