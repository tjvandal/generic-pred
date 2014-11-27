push!(LOAD_PATH, pwd())

using DataFrames
@everywhere using Lyaponuv

@everywhere function main(data, J, m, r, sliding_window, next_x_points, sample_size)
	ts = deepcopy(data[:DJIA][1:end-next_x_points])
	diff = ts[1:end-1] - ts[2:end]
	println("diff avg:", mean(abs(diff)), "\tdiff std:", std(diff))


	for j=1:next_x_points
	    @time val = lyaponuv_next(ts[end-sliding_window:end], J, m, r, sample_size)
	    append!(ts, [val])
	end
	return(ts)
end


f = "../data/DJA.csv"
data=readtable(f, header=true)

J = 2  ## reconstruction delay
m = 3  ## embedding dimension
r = 11  ## number of reference points to compute exponent
sliding_window = 3000

next_x_points = 365


increment=10
iterations=10
tasks=Array(RemoteRef, iterations)

for s=1:iterations
	tasks[s] = @spawn main(data, J, m, r, sliding_window, next_x_points, s*increment)
	println("starting task: ",s)
end

out = Array(Float64, size(data)[1], iterations+1)
out[:, 1] = data[:DJIA]
for t in 1:iterations
	out[:, t+1] = fetch(tasks[t])
end


cols = [symbol("SampleSize$(i*increment)") for i=1:iterations]
prepend!(cols, [symbol("Real")])
df = DataFrame(out)
names!(df, cols)
df[:Date] = data[:Date]
writetable("results.csv", df)
