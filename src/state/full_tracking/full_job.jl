
abstract type PositionRecord end

mutable struct FullJob 
    history::Vector{PositionRecord}
end

struct InTransit <: PositionRecord
    time::Float64 #time transit started
    end_time::Float64 #time transit will end
end

struct InQueue <: PositionRecord
    time::Float64 #time entered queue
    queue::Int #queue index
end

struct LeaveSystem <: PositionRecord
    time::Float64 #time left system
end

FullJob() = FullJob([])
FullJob(entry::PositionRecord) = FullJob([entry])

""" Returns the time the job entered the system """
entry_time(job::FullJob)::Float64 = first(job.history).time

""" Returns the time the job exited the system or time of last event if still in the system """
exit_time(job::FullJob)::Float64 = last(job.history).time

""" Returns the duration of time the job has spent in the system """
duration(job::FullJob)::Float64 = exit_time(job) - entry_time(job)


function push!(job::FullJob, pos::PositionRecord)
    push!(job.history, pos)
end

isless(p1::PositionRecord, p2::PositionRecord) = p1.time < p2.time
isless(p1::InTransit, p2::InTransit) = p1.end_time < p2.end_time
isless(j1::FullJob, j2::FullJob) = last(j1.history) < last(j2.history)

function show(io::IO, job::FullJob)
    print(io, "FullJob(Entry: $(entry_time(job)), Pos: $(last(job.history)), Duration: $(duration(job)))")
end

function show(io::IO, pos::InTransit)
    print(io, "(T: $(round(pos.time, digits = 4)))")
end

function show(io::IO, pos::InQueue)
    print(io, "(Q$(pos.queue): $(round(pos.time, digits = 4)))")
end

function show(io::IO, pos::LeaveSystem)
    print(io, "(E: $(round(pos.time, digits = 4)))")
end

function show(io::IO, history::Vector{PositionRecord})
    length(history) == 0 && print(io, "[]") && return
    print(io, "[$(first(history))")
    for i in 2:length(history)
        print(io, "-> $(history[i])")
    end
    print(io, "]")
end