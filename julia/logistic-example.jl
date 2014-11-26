#using Gadfly

push!(LOAD_PATH, pwd())
using Lyaponuv

@everywhere function logistic(x, mu)
    x_next = mu * x * (1 - x) 
    return(x_next)
end

@everywhere function main(x)
	n = 100
	mu = 4
	logistic_time_series = Array(Float64, n)
	for i=1:n
	    logistic_time_series[i] = logistic(x, mu)
	    x=logistic_time_series[i]
	end

	J = 1  ## reconstruction delay
	m = 3  ## embedding dimens

	next_x_values = 1
	sample_size = 25
	series = deepcopy(logistic_time_series)
	for j=1:next_x_values
	    val = lyaponuv_next(series, J, m, 10, sample_size)
	    append!(series, [val])
	end
	return(0)
end

for xi in rand(10)
	println("Starting process")
	r = main(xi)
end
