using DataStructures
import Base: isless

abstract type Event end
abstract type State end

#Captures an event and the time it takes place
struct TimedEvent
    event::Event
    time::Float64
end

#Comparison of two timed events - this will allow us to use them in a heap/priority-queue
isless(te1::TimedEvent,te2::TimedEvent) = te1.time < te2.time

#This is an abstract function 
"""
It will generally be called as 
       new_timed_events = process_event(time, state, event)
It will generate 0 or more new timed events based on the current event
"""
function process_event end

#Generic events that we can always use
struct EndSimEvent <: Event end
struct LogStateEvent <: Event end

function process_event(time::Float64, state::State, es_event::EndSimEvent)
    println("Ending simulation at time $time.")
    return []
end

function process_event(time::Float64, state::State, ls_event::LogStateEvent)
    println("Logging state at time $time.")
    println(state)
    return []
end;

"""
The main simulation function gets an initial state and an initial event that gets things going.
Optional arguments are the maximal time for the simulation, times for logging events, and a call back function.
"""
function simulate(init_state::State, init_timed_event::TimedEvent
                    ; 
                    max_time::Float64 = 10.0, 
                    log_times::Vector{Float64} = Float64[],
                    call_back = (time,state) -> nothing)

    #The event queue
    priority_queue = BinaryMinHeap{TimedEvent}()

    #Put the standard events in the queue
    push!(priority_queue, init_timed_event)
    push!(priority_queue, TimedEvent(EndSimEvent(),max_time))
    for lt in log_times
        push!(priority_queue,TimedEvent(LogStateEvent(),lt))
    end

    #initilize the state
    state = deepcopy(init_state)
    time = 0.0

    call_back(time,state)

    #The main discrete event simulation loop - SIMPLE!
    while true
        #Get the next event
        timed_event = pop!(priority_queue)

        #advance the time
        time = timed_event.time

        #Act on the event
        new_timed_events = process_event(time, state, timed_event.event) 

        #if the event was an end of simulation then stop
        isa(timed_event.event, EndSimEvent) && break 

        #The event may spawn 0 or more events which we put in the priority queue 
        for nte in new_timed_events
            push!(priority_queue,nte)
        end

        call_back(time,state)
    end
end

"""
A convenience function to make a Gamma distribution with desired rate (inverse of shape) and SCV.
"""
rate_scv_gamma(desired_rate::Float64, desired_scv::Float64) = Gamma(1/desired_scv, desired_scv/desired_rate)

dist = rate_scv_gamma(3.,0.5)
@show mean(dist)
@show scv(dist);

struct TandemNetworkParameters
    num_nodes::Int #The number of nodes (queues/servers) in the system
    λ::Float64 #The external arrival rate to the first queue
    μ_array::Vector{Float64} #The list of the rates of service in each of the queues.
    scv_array::Vector{Float64} #A list of the squared coefficients of service times.
end

mutable struct TandemQueueNetworkState <: State
    queues::Vector{Int} #A vector which indicates the number of customers in each queue
    params::TandemNetworkParameters #The parameters of the tandem queueing system
end
 
#External arrival to the firt queue
struct ExternalArrivalEvent <: Event end
 
struct EndOfServiceAtQueueEvent <: Event
    q::Int #The index of the queue where service finished
end

next_arrival_time(s::State) = rand(Exponential(1/s.params.λ))
next_service_time(s::State, q::Int) = rand(rate_scv_gamma(s.params.μ_array[q], s.params.scv_array[q]))

function process_event(time::Float64, state::State, arrival_event::ExternalArrivalEvent)
    state.queues[1] += 1     #increase number in first queue
    new_timed_events = TimedEvent[]
 
    #prepare next arrival
    push!(new_timed_events, TimedEvent(ExternalArrivalEvent(),time + next_arrival_time(state)))
 
    #if this is the only job on the server engage service
    state.queues[1] == 1 && push!(new_timed_events,
                                TimedEvent(EndOfServiceAtQueueEvent(1), time + next_service_time(state,1)))
    return new_timed_events
end
 
#Process an end of service event
function process_event(time::Float64, state::State, eos_event::EndOfServiceAtQueueEvent)
    q = eos_event.q
    new_timed_events = TimedEvent[]
    
    state.queues[q] -= 1
    @assert state.queues[q] ≥ 0
    
    #if another customer in the queue then start a new service
    if state.queues[q] ≥ 1
        st = next_service_time(state, q)
        push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q), time + st)) 
    end
    
    #If there is a downstream queue
    if q < state.params.num_nodes
        state.queues[q+1] += 1 #move the job to the downstream queue
        
        #if the queue downstream was empty
        if state.queues[q+1] == 1 
            st = next_service_time(state, q)
            push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q+1), time + st)) 
        end
    end
    
    return new_timed_events
end
