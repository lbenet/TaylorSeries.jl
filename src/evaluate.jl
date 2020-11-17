# This file is part of the TaylorSeries.jl Julia package, MIT license
#
# Luis Benet & David P. Sanders
# UNAM
#
# MIT Expat license
#

## Evaluating ##
"""
    evaluate(a, [dx])

Evaluate a `Taylor1` polynomial using Horner's rule (hand coded). If `dx` is
ommitted, its value is considered as zero. Note that the syntax `a(dx)` is
equivalent to `evaluate(a,dx)`, and `a()` is equivalent to `evaluate(a)`.
"""
function evaluate(a::Taylor1{T}, dx::T) where {T<:Number}
    @inbounds suma = a[end]
    @inbounds for k in a.order-1:-1:0
        suma = suma*dx + a[k]
    end
    suma
end
function evaluate(a::Taylor1{T}, dx::S) where {T<:Number, S<:Number}
    suma = a[end]*one(dx)
    @inbounds for k in a.order-1:-1:0
        suma = suma*dx + a[k]
    end
    suma
end
evaluate(a::Taylor1{T}) where {T<:Number} = a[0]

"""
    evaluate(x, δt)

Evaluates each element of `x::AbstractArray{Taylor1{T},N}`,
representing the dependent variables of an ODE, at *time* δt. Note that the
syntax `x(δt)` is equivalent to `evaluate(x, δt)`, and `x()`
is equivalent to `evaluate(x)`.
"""
evaluate(x::AbstractArray{Taylor1{T},N}, δt::S) where
    {T<:Number, S<:Number, N} = evaluate.(x, δt)
evaluate(a::AbstractArray{Taylor1{T},N}) where {T<:Number, N} =
    evaluate.(a, zero(T))

"""
    evaluate!(x, δt, x0)

Evaluates each element of `x::AbstractArray{Taylor1{T},N}`,
representing the Taylor expansion for the dependent variables
of an ODE at *time* `δt`. It updates the vector `x0` with the
computed values.
"""
function evaluate!(x::AbstractArray{Taylor1{T},N}, δt::T,
        x0::AbstractArray{T,N}) where {T<:Number, N}

    # @assert length(x) == length(x0)
    @inbounds for i in eachindex(x, x0)
        x0[i] = evaluate( x[i], δt )
    end
    nothing
end
function evaluate!(x::AbstractArray{Taylor1{T},N}, δt::S,
        x0::AbstractArray{T,N}) where {T<:Number, S<:Number, N}

    # @assert length(x) == length(x0)
    @inbounds for i in eachindex(x, x0)
        x0[i] = evaluate( x[i], δt )
    end
    nothing
end

"""
    evaluate(a, x)

Substitute `x::Taylor1` as independent variable in a `a::Taylor1` polynomial.
Note that the syntax `a(x)` is equivalent to `evaluate(a, x)`.
"""
evaluate(a::Taylor1{T}, x::Taylor1{S}) where {T<:Number, S<:Number} =
    evaluate(promote(a,x)...)

function evaluate(a::Taylor1{T}, x::Taylor1{T}) where {T<:Number}
    if a.order != x.order
        a, x = fixorder(a, x)
    end
    @inbounds suma = a[end]*one(x)
    @inbounds for k = a.order-1:-1:0
        suma = suma*x + a[k]
    end
    suma
end

function evaluate(a::Taylor1{Taylor1{T}}, x::Taylor1{T}) where {T<:Number}
    @inbounds suma = a[end]*one(x)
    @inbounds for k = a.order-1:-1:0
        suma = suma*x + a[k]
    end
    suma
end
function evaluate(a::Taylor1{T}, x::Taylor1{Taylor1{T}}) where {T<:Number}
    @inbounds suma = a[end]*one(x)
    @inbounds for k = a.order-1:-1:0
        suma = suma*x + a[k]
    end
    suma
end

evaluate(p::Taylor1{T}, x::Array{S}) where {T<:Number, S<:Number} =
    evaluate.([p], x)

#function-like behavior for Taylor1
(p::Taylor1)(x) = evaluate(p, x)

(p::Taylor1)() = evaluate(p)

#function-like behavior for Vector{Taylor1}
(p::AbstractArray{Taylor1{T}})(x) where {T<:Number} = evaluate.(p, x)
(p::AbstractArray{Taylor1{T}})() where {T<:Number} = evaluate.(p)

## Evaluation of multivariable
function evaluate!(x::AbstractArray{TaylorN{T},N}, δx::Array{T,1},
        x0::AbstractArray{T,N}) where {T<:Number, N}

    # @assert length(x) == length(x0)
    @inbounds for i in eachindex(x, x0)
        x0[i] = evaluate( x[i], δx )
    end
    nothing
end

function evaluate!(x::AbstractArray{TaylorN{T},N}, δx::Array{Taylor1{T},1},
        x0::AbstractArray{Taylor1{T},N}) where {T<:NumberNotSeriesN, N}

    # @assert length(x) == length(x0)
    @inbounds for i in eachindex(x, x0)
        x0[i] = evaluate( x[i], δx )
    end
    nothing
end

function evaluate!(x::AbstractArray{TaylorN{T},N}, δx::Array{TaylorN{T},1},
        x0::AbstractArray{TaylorN{T},N}) where {T<:NumberNotSeriesN, N}

    # @assert length(x) == length(x0)
    @inbounds for i in eachindex(x, x0)
        x0[i] = evaluate( x[i], δx )
    end
    nothing
end

function evaluate!(x::AbstractArray{TaylorN{T},N}, δt::T,
        x0::AbstractArray{TaylorN{T},N}) where {T<:Number, N}

    # @assert length(x) == length(x0)
    @inbounds for i in eachindex(x, x0)
        x0[i] = evaluate( x[i], δt )
    end
    nothing
end

"""
    evaluate(a, [vals])

Evaluate a `HomogeneousPolynomial` polynomial at `vals`. If `vals` is ommitted,
it's evaluated at zero. Note that the syntax `a(vals)` is equivalent to
`evaluate(a, vals)`; and `a()` is equivalent to `evaluate(a)`.
"""
function evaluate(a::HomogeneousPolynomial{T}, vals::NTuple{N,S} ) where
        {T<:Number, S<:Number, N}

    @assert N == get_numvars()

    return _evaluate(a, vals)
end

function _evaluate(a::HomogeneousPolynomial{T}, vals::NTuple{N,S} ) where
        {T<:Number, S<:Number, N}

    ct = coeff_table[a.order+1]
    R = promote_type(T,S)
    suma = zero(R)

    for (i,a_coeff) in enumerate(a.coeffs)
        iszero(a_coeff) && continue
        tmp = prod( vals .^ ct[i] )
        suma += a_coeff * tmp
    end

    return suma
end


evaluate(a::HomogeneousPolynomial{T}, vals::Array{S,1} ) where
        {T<:Number, S<:NumberNotSeriesN} = evaluate(a, (vals...,))

evaluate(a::HomogeneousPolynomial, v, vals...) = evaluate(a, (v, vals...,))

evaluate(a::HomogeneousPolynomial, v) = evaluate(a, v...)

function evaluate(a::HomogeneousPolynomial)
    a.order == 0 && return a[1]
    zero(a[1])
end

#function-like behavior for HomogeneousPolynomial
(p::HomogeneousPolynomial)(x) = evaluate(p, x)

(p::HomogeneousPolynomial)(x, v...) = evaluate(p, (x, v...,))

(p::HomogeneousPolynomial)() = evaluate(p)

"""
    evaluate(a, [vals])

Evaluate the `TaylorN` polynomial `a` at `vals`.
If `vals` is ommitted, it's evaluated at zero.
Note that the syntax `a(vals)` is equivalent to `evaluate(a, vals)`; and `a()`
is equivalent to `evaluate(a)`.
"""
function evaluate(a::TaylorN{T}, vals::NTuple{N,S}) where
        {T<:Number,S<:NumberNotSeries, N}

    @assert N == get_numvars()

    R = promote_type(T,S)
    a_length = length(a)
    suma = zeros(R, a_length)
    @inbounds for homPol in length(a):-1:1
        suma[homPol] = evaluate(a.coeffs[homPol], vals)
    end

    return sum( sort!(suma, by=abs2) )
end

evaluate(a::TaylorN, vals) = evaluate(a, (vals...,))

evaluate(a::TaylorN, v, vals...) = evaluate(a, (v, vals...,))

function evaluate(a::TaylorN{T}, vals::NTuple{N,Taylor1{S}}) where
        {T<:Number, S<:NumberNotSeries, N}

    @assert N == get_numvars()

    R = promote_type(T,S)
    ord = maximum( get_order.(vals) )
    suma = Taylor1(zeros(R, ord))

    @inbounds for homPol in length(a):-1:1
        suma += evaluate(a.coeffs[homPol], vals)
    end

    return suma
end

evaluate(a::TaylorN{T}, vals::Array{Taylor1{S},1}) where
    {T<:Number, S<:NumberNotSeriesN} = evaluate(a, (vals...,))

function evaluate(a::TaylorN{Taylor1{T}}, vals::NTuple{N, Taylor1{T}}) where
        {T<:NumberNotSeries, N}

    @assert N == get_numvars()

    ord = maximum( get_order.(vals) )
    suma = Taylor1(zeros(T, ord))

    for homPol in length(a):-1:1
        suma += evaluate(a.coeffs[homPol], vals)
    end

    return suma
end

evaluate(a::TaylorN{Taylor1{T}}, vals::Array{Taylor1{T},1}) where
    {T<:NumberNotSeries} = evaluate(a, (vals...,))

function evaluate(a::TaylorN{T}, vals::NTuple{N, TaylorN{S}}) where
        {T<:Number, S<:NumberNotSeries, N}

    @assert length(vals) == get_numvars()

    R = promote_type(T,eltype(S))
    suma = zero(TaylorN{R})

    for homPol in length(a):-1:1
        suma += evaluate(a.coeffs[homPol], vals)
    end

    return suma
end

evaluate(a::TaylorN{T}, vals::Array{TaylorN{S},1}) where
    {T<:Number, S<:NumberNotSeries} = evaluate(a, (vals...,))

function evaluate(a::TaylorN{T}, s::Symbol, val::S) where
        {T<:Number, S<:NumberNotSeriesN}
    vars = get_variables(T)
    ind = lookupvar(s)
    vars[ind] = val
    evaluate(a, vars)
end

evaluate(a::TaylorN{T}, x::Pair{Symbol,S}) where {T<:Number, S<:NumberNotSeriesN} =
    evaluate(a, first(x), last(x))

evaluate(a::TaylorN{T}) where {T<:Number} = a[0][1]

#High-dim array evaluation
function evaluate(A::AbstractArray{TaylorN{T},N}, δx::Vector{S}) where {T<:Number, S<:Number, N}
    R = promote_type(T,S)
    return evaluate(convert(Array{TaylorN{R},N},A), convert(Vector{R},δx))
end
function evaluate(A::Array{TaylorN{T},N}, δx::Vector{T}) where {T<:Number, N}
    Anew = Array{T}(undef, size(A)...)
    evaluate!(A, δx, Anew)
    return Anew
end
evaluate(A::AbstractArray{TaylorN{T},N}) where {T<:Number, N} = evaluate.(A)

#function-like behavior for TaylorN
(p::TaylorN)(x) = evaluate(p, x)
(p::TaylorN)() = evaluate(p)
(p::TaylorN)(s::Symbol, x) = evaluate(p, s, x)
(p::TaylorN)(x::Pair) = evaluate(p, first(x), last(x))
(p::TaylorN)(x, v...) = evaluate(p, (x, v...,))

#function-like behavior for AbstractArray{TaylorN{T}}
(p::AbstractArray{TaylorN{T}})(x) where {T<:Number} = evaluate(p, x)
(p::AbstractArray{TaylorN{T}})() where {T<:Number} = evaluate(p)
