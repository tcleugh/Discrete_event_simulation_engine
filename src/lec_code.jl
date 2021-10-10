###### dump of all relevant code from the lecture notebooks ###########
###### dont try to run, just here for easy copy pasting     ###########




using Distributions, Random, Plots
Random.seed!(0)

call_duration() = rand(Exponential(7.0))
money_made(duration::Float64)::Float64 = duration ≤ 1.5 ? 0.0 : 2.5 * duration

function simulate()
    current_worker_calls = [call_duration() for _ in 1:5] # initialize: all workers start a call at t=0

    event_list = copy(current_worker_calls) 
    revenue = 0.0
    t = 0.0

    times_log = Float64[]
    revenue_log = Float64[]

    while true
        # find the worker that has just finished their call
        i = argmin(event_list) # note - performance bottleneck
        # advance time to that call
        t = event_list[i]
        if t ≥ 60 # trigger simulation end
            push!(times_log, 60)
            push!(revenue_log, revenue)
            break
        end
        # record the event
        push!(times_log, t)
        revenue += money_made(current_worker_calls[i])
        push!(revenue_log,revenue)
        # engage worker in new call and set the call-finish event
        current_worker_calls[i] = call_duration()
        event_list[i] = t + current_worker_calls[i]
    end
    return (times_log, revenue_log)
end

"""
This function is designed to stich_steps of a discrete event curve.
"""
function stich_steps(epochs, values)
    n = length(epochs)
    new_epochs  = [epochs[1]]
    new_values = [values[1]]
    for i in 2:n
        push!(new_epochs, epochs[i])
        push!(new_values, values[i-1])
        push!(new_epochs, epochs[i])
        push!(new_values, values[i])
    end
    return (new_epochs, new_values)
end

plot(stich_steps(simulate()...)..., label = false, 
     xlabel = "Time", ylabel = "Revenue")
plot!(stich_steps(simulate()...)..., label = false)
plot!(stich_steps(simulate()...)..., label = false)


Random.seed!(1)

function queue_simulator(T, arrival_function, service_function, capacity = Inf, init_queue = 0)
    t = 0.0
    queue = init_queue
    queue_integral = 0.0

    next_arrival = arrival_function()
    next_service = queue == 0 ? Inf : service_function()

    while t < T
        t_prev = t
        q_prev = queue
        if next_service < next_arrival
            t = next_service
            queue -= 1
            if queue > 0
                next_service = t + service_function()
            else
                next_service = Inf
            end
        else
            t = next_arrival
            if queue == 0
                next_service = t + service_function()
            end
            if queue < capacity
                queue += 1
            end
            next_arrival = t + arrival_function()
        end
        queue_integral += (t - t_prev) * q_prev
    end
    return queue_integral / t
end

λ = 0.82   # \lamda + [TAB]
μ = 1.3    # \mu + [TAB]
K = 5
ρ = λ / μ  # \rho + [TAB]
T = 10^6

# These are formulas from queueing theory 
mm1_theory = ρ/(1-ρ)
md1_theory = ρ/(1-ρ)*(2-ρ)/2
mm1k_theory = ρ/(1-ρ)*(1-(K+1)*ρ^K+K*ρ^(K+1))/(1-ρ^(K+1))

mm1_estimate = queue_simulator(
    T,
    () -> rand(Exponential(1/λ)),
    () -> rand(Exponential(1/μ))
)
md1_estimate = queue_simulator(
    T,
    () -> rand(Exponential(1/λ)),
    () -> 1/μ
)
mm1k_estimate = queue_simulator(
    T,
    () -> rand(Exponential(1/λ)),
    () -> rand(Exponential(1/μ)),
    K
)

println("The load on the system: $(p)")
println("Queueing theory: $((mm1_theory, md1_theory, mm1k_theory))")
println("Via simulation: $((mm1_estimate, md1_estimate, mm1k_estimate))")








using DataStructures
import Base: isless

abstract type Event end
abstract type State end

# Captures an event and the time it takes place
struct TimedEvent
    event::Event
    time::Float64
end

# Comparison of two timed events - this will allow us to use them in a heap/priority-queue
isless(te1::TimedEvent, te2::TimedEvent) = te1.time < te2.time

"""
    new_timed_events = process_event(time, state, event)

Generate an array of 0 or more new `TimedEvent`s based on the current `event` and `state`.
"""
function process_event end # This defines a function with zero methods (to be added later)

# Generic events that we can always use

"""
    EndSimEvent()

Return an event that ends the simulation.
"""
struct EndSimEvent <: Event end

function process_event(time::Float64, state::State, es_event::EndSimEvent)
    println("Ending simulation at time $time.")
    return []
end

"""
    LogStateEvent()

Return an event that prints a log of the current simulation state.
"""
struct LogStateEvent <: Event end

function process_event(time::Float64, state::State, ls_event::LogStateEvent)
    println("Logging state at time $time.")
    println(state)
    return []
end

"""
The main simulation function gets an initial state and an initial event
that gets things going. Optional arguments are the maximal time for the
simulation, times for logging events, and a call-back function.
"""
function simulate(init_state::State, init_timed_event::TimedEvent
                    ; 
                    max_time::Float64 = 10.0, 
                    log_times::Vector{Float64} = Float64[],
                    callback = (time, state) -> nothing)

    # The event queue
    priority_queue = BinaryMinHeap{TimedEvent}()

    # Put the standard events in the queue
    push!(priority_queue, init_timed_event)
    push!(priority_queue, TimedEvent(EndSimEvent(), max_time))
    for log_time in log_times
        push!(priority_queue, TimedEvent(LogStateEvent(), log_time))
    end

    # initilize the state
    state = deepcopy(init_state)
    time = 0.0

    # Callback at simulation start
    callback(time, state)

    # The main discrete event simulation loop - SIMPLE!
    while true
        # Get the next event
        timed_event = pop!(priority_queue)

        # Advance the time
        time = timed_event.time

        # Act on the event
        new_timed_events = process_event(time, state, timed_event.event) 

        # If the event was an end of simulation then stop
        if timed_event.event isa EndSimEvent
            break 
        end

        # The event may spawn 0 or more events which we put in the priority queue 
        for nte in new_timed_events
            push!(priority_queue,nte)
        end

        # Callback for each simulation event
        callback(time, state)
    end
end;



Random.seed!(0)

λ = 1.8
μ = 2.0
 
mutable struct QueueState <: State
    number_in_system::Int # If ≥ 1 then server is busy, If = 0 server is idle.
end

struct ArrivalEvent <: Event end
struct EndOfServiceEvent <: Event end

# Process an arrival event
function process_event(time::Float64, state::State, ::ArrivalEvent)
    # Increase number in system
    state.number_in_system += 1
    new_timed_events = TimedEvent[]

    # Prepare next arrival
    push!(new_timed_events,TimedEvent(ArrivalEvent(),time + rand(Exponential(1/λ))))

    # If this is the only job on the server
    state.number_in_system == 1 && push!(new_timed_events,TimedEvent(EndOfServiceEvent(), time + 1/μ))
    return new_timed_events
end

# Process an end of service event 
function process_event(time::Float64, state::State, ::EndOfServiceEvent)
    # Release a customer from the system
    state.number_in_system -= 1 
    @assert state.number_in_system ≥ 0
    return state.number_in_system ≥ 1 ? [TimedEvent(EndOfServiceEvent(), time + 1/μ)] : TimedEvent[]
end




simulate(QueueState(0), TimedEvent(ArrivalEvent(),0.0), log_times = [5.3,7.5])

using Plots
Random.seed!(0)

time_traj, queue_traj = Float64[], Int[]

function record_trajectory(time::Float64, state::QueueState) 
    push!(time_traj, time)
    push!(queue_traj, state.number_in_system)
    return nothing
end

simulate(QueueState(0), TimedEvent(ArrivalEvent(),0.0), max_time = 100.0, callback = record_trajectory)








plot(stich_steps(time_traj, queue_traj)... ,
             label = false, xlabel = "Time", ylabel = "Queue size (number in system)" )


             Random.seed!(0)

             λ = 1.8
             μ = 2.0
             
             prev_time = 0.0
             prev_state = 0
             integral = 0.0
             
             function add_to_integral(time::Float64, state::QueueState) 
                 # Make sure to use the variables above
                 global prev_time, prev_state, integral
             
                 diff = time - prev_time
                 integral += prev_state * diff
                 prev_time = time
                 prev_state = state.number_in_system
             
                 return nothing
             end
             
             simulate(QueueState(0), TimedEvent(ArrivalEvent(),0.0), max_time = 10.0^6, callback = add_to_integral)
             println("Simulated mean queue length: ", integral / 10^6 )
             
             ρ = λ / μ
             md1_theory = ρ/(1-ρ)*(2-ρ)/2
             println("Theoretical mean queue length: ", md1_theory)