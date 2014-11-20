module Lyaponuv

export lyaponuv_k, lyaponuv, lyaponuv_exp

function lyaponuv_k(time_series, J, m, ref)
    N = length(time_series)
    M = N - (m - 1) * J
    X = Array(Float64, m, M)
    i = 1
    for i=1:M
        X[:,i] = time_series[i:J:(i+(m-1)*J)]
    end

    NORMS = Array(Float64, M, M)
    for i=1:M
        for j=i:M
            if i == j
                NORMS[i, j]=9999.   #arbitrarily large number
            else
                NORMS[i,j] = vecnorm(X[:, i] - X[:, j])  #eucilidean norm
                NORMS[j,i] = NORMS[i, j]      # matrix is symmetric
            end
        end
    end
    
    # match pairs with lowest eucilidean values
    pairs = Array(Int, M)
    for row in 1:M
        mn, idx = findmin(NORMS[row, :])
        pairs[row] = idx
    end

    y = Array(Float64, ref)
    for i=0:ref-1
        agg = 0 
        count = 0
        for j=1:M
            jhat = pairs[j]+i
            jtrue = j+i

            if jhat <= M && jtrue <= M
                agg = agg + log(vecnorm(X[:, jtrue] - X[:, jhat]))
                count = count + 1
            end
        end
        y[i+1] = agg/count # divide by delta-t also?
    end
    return(y)
end

function lyaponuv_exp(series)
    nn = !isnan(series)
    A = ones(length(series), 2)
    A[:,1] = linspace(1, length(series), length(series))
    gradient = \(A, series)
    return(gradient[1])
end

function lyaponuv(time_series, J, m, ref)
	ts = lyaponuv_k(time_series, J, m, ref)
	exponent = lyaponuv_exp(ts[isfinite(ts)])  ## only input those which are finite
	return(exponent)
end

end