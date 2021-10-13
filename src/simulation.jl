##############################################
######### Define all processing ##############
##############################################

#This is an abstract function 
"""
It will generally be called as 
       new_timed_events = process_event(time, state, event)
It will generate 0 or more new timed events based on the current event
"""
function process_event end

function process_event(time::Float64, state::State, es_event::EndSimEvent)::Vector{TimedEvent}
    println("Ending simulation at time $time.")
    return []
end

function process_event(time::Float64, state::State, ls_event::LogStateEvent)::Vector{TimedEvent}
    println("Logging state at time $time.")
    println(state)
    return []
end;

""" Adds a new job to the system """
function process_event(time::Float64, state::State, arrival_event::ExternalArrivalEvent)::Vector{TimedEvent}
    new_timed_events = TimedEvent[]

    next_q = get_entry_queue(state)
    append!(new_timed_events, add_to_queue(next_q, time, state))

    #prepare next arrival
    push!(new_timed_events, TimedEvent(ExternalArrivalEvent(), time + next_arrival_time(state)))

    return new_timed_events
end

""" Process an end of service event """
function process_event(time::Float64, state::State, eos_event::EndOfServiceAtQueueEvent)::Vector{TimedEvent}
    q = eos_event.q
    new_timed_events = TimedEvent[]
    
    #if another customer in the queue then start a new service
    if num_in_queue(q, state) > 1
        push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q), time + next_service_time(state, q))) 
    end
    
    #Finds new queue using routing matrix
    append!(new_timed_events, add_to_transit(q, time, state, job = pop_queue(q, state)))

    return new_timed_events
end

""" Process a transit event """
function process_event(time::Float64, state::State, transit_event::InTransitEvent)::Vector{TimedEvent}
    return add_to_queue(transit_event.q, time, state, job = pop_transit(state))
end

"""
The main simulation function gets an initial state and an initial event that gets things going.
Optional arguments are the maximal time for the simulation, times for logging events, and a call back function.
"""
function simulate(init_state::State; 
                    init_timed_event::TimedEvent = TimedEvent(ExternalArrivalEvent(), 0.0), 
                    max_time::Real = 10.0, 
                    log_times::Vector{Float64} = Float64[],
                    call_back = (time,state) -> nothing)

    #The event queue
    priority_queue = BinaryMinHeap{TimedEvent}()

    #Put the standard events in the queue
    push!(priority_queue, init_timed_event)
    push!(priority_queue, TimedEvent(EndSimEvent(), max_time))
    for lt in log_times
        push!(priority_queue,TimedEvent(LogStateEvent(), lt))
    end

    #initilize the state
    state = deepcopy(init_state)
    time = 0.0

    call_back(time, state)

    #The main discrete event simulation loop
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
        for new_event in new_timed_events
            push!(priority_queue, new_event)
        end

        call_back(time, state)
    end
end
