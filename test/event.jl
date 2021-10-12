import Base: isless

abstract type Event end

#Captures an event and the time it takes place
struct TimedEvent
    event::Event
    time::Float64
end

#Comparison of two timed events - this will allow us to use them in a heap/priority-queue
isless(te1::TimedEvent,te2::TimedEvent) = te1.time < te2.time

#Generic events that we can always use
struct EndSimEvent <: Event end
struct LogStateEvent <: Event end

#External arrival to the first queue
struct ExternalArrivalEvent <: Event end
 
struct EndOfServiceAtQueueEvent <: Event
    q::Int #The index of the queue where service finished
end

struct InTransitEvent <: Event
    q::Int #The index of the destination queue
end

mutable struct Job 
    event_time::Float64 #not sure 
    entry_time::Float64 #time of job entry into system
    exit_time::Float64 #time of job exit from system
end

isless(j1::Job, j2::Job) = j1.event_time < j2.event_time
