#using Gadfly

push!(LOAD_PATH, pwd())
using Lyaponuv

function logistic(x, mu)
    x_next = mu * x * (1 - x) 
    return(x_next)
end

x = rand(1)[1]
n = 10000
mu = 4
logistic_time_series = Array(Float64, n)
for i=1:n
    logistic_time_series[i] = logistic(x, mu)
    x=logistic_time_series[i]
end

J = 1  ## reconstruction delay
m = 3  ## embedding dimens

next_x_values = 1
sample_size = 5
series = deepcopy(logistic_time_series)
for j=1:next_x_values
    val = lyaponuv_next(series, J, m, 10, sample_size)
    append!(series, [val])
end

