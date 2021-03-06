## TODO: Remove
const _LSEP = UInt8('\n')
const _EOL = UInt8('}')
const _BOL = UInt8('{')
const _ABOL = UInt8('[')
const _INT_MAX = typemax(Int)

const _RowType = SubArray{UInt8,1,Array{UInt8,1},Tuple{UnitRange{Int}},true}
## Detect space in UInt8
import Base: isspace
@inline Base.isspace(c::UInt8) =
c == 0x20 || 0x09 <= c <= 0x0d || c == 0x85 || c == 0xa0

## Raw row utils
@inline _equaleol(c::UInt8) = (c == 0x0a) # 0x0a == UInt8('\n')
function _findnexteol(buf::Vector{UInt8}, size::Int, index::Int)
    while true
        if _equaleol(@inbounds(buf[index])) || isequal(index, size)
            return index
        else
            index += 1
        end
    end
end

function _findpreveol(buf::Vector{UInt8}, filestart::Int, index::Int)
    while true
        if _equaleol(@inbounds(buf[index])) || isequal(index, filestart)
            return index
        else
            index -= 1
        end
    end
end

function skiprows(buf::Vector{UInt8}, size::Int, n::Int, from::Int)
    isequal(from, size) && (return size)
    for _ in 1:n
        from = _findnexteol(buf, size, from+1)
        isequal(from, size) && (return size)
    end
    return from
end

function partitionrows(nrows::Int, nworkers::Int)
    partitionsize = (nrows + 1) ÷ nworkers
    parts = Vector{UnitRange{Int}}(undef, nworkers)
    parts[1] = 1:partitionsize
    for i in 2:(nworkers-1)
        parts[i] = (((i-1) * partitionsize)+1):(i * partitionsize)
    end
    parts[nworkers] = (last(parts[nworkers-1])+1):nrows
    return parts
end

function rowindex(rows::T, row::Int) where T
    return @inbounds((rows[row]+1):rows[row+1])
end

function indexrows(buf::T, size::Int, nrows::Int, start::Int) where {T}
    rows = Vector{Int}(undef, 1)
    rows[1] = start
    for i in 1:nrows
        start = _findnexteol(buf, size, start+1)
        push!(rows, start)
        isequal(start, size) && (return rows)
    end
    return rows
end

function tindexrows(buf::T, size::Int, nworkers::Int) where {T}
    parts = partitionbuf(buf, size, nworkers)
    nparts = length(parts)
    out = Vector{Task}(undef, nparts)
    for i in 1:nparts
        out[i] = @spawn indexrows(buf, last(parts[i]), typemax(Int), _findnexteol(buf, size, first(parts[i])+1))
    end
    ret = mapfoldl(fetch, vcat, out)
    pushfirst!(ret, 0)
    return ret
end

function partitionbuf(buf::T, size::Int, nworkers::Int) where {T}
    guessize = cld(size, nworkers)
    parts = Vector{UnitRange{Int}}(undef, nworkers)
    parts[1] = 1:_findnexteol(buf, size, guessize)
    for i in 2:(nworkers - 1)
        parts[i] = (last(parts[i-1])):_findnexteol(buf, size, (i * guessize))
    end
    parts[nworkers] = (last(parts[nworkers-1])):size
    return parts[length.(parts) .> 1]
end

## Reading Utils
function _eatwhitespace(row::_RowType)
    for (i, c) in pairs(row)
        !isspace(c) && (return @inbounds(@view(row[i:end])))
    end
    @inbounds(@view(row[end:end]))
end

function parserow(row::_RowType, structtype::Nothing)
    return JSON3.read(_eatwhitespace(row))
end

function parserow(row::_RowType, structtype::DataType)
    return JSON3.read(_eatwhitespace(row), structtype)
end

function parserows(buf::Vector{UInt8}, rows::Vector{Int}, indices, RT, structtype, nworkers::Int)
   if nworkers > 1
       return _tparserrows(buf, rows, indices, RT, structtype, nworkers)
   else
       return _parserows(buf, rows, indices, RT, structtype)
   end
end

function _tparserrows(buf::Vector{UInt8}, rows::Vector{Int}, indices, RT, structtype, nworkers::Int)
    parts = partitionrows(length(indices), nworkers)
    prows = Vector{RT}(undef, length(indices))
    plen = length(parts[1])
    @sync for i in 1:nworkers
        @spawn begin
            crows = indices[parts[i]]
            for (j, row) in pairs(crows)
                rindices = rowindex(rows, row)
                prows[(i-1) * plen + j] = parserow(@inbounds(@view(buf[rindices])), structtype)
            end
        end
    end
    return prows
end

function _parserows(buf::Vector{UInt8}, rows::Vector{Int}, indices, RT,  structtype)
    prows = Vector{RT}(undef, length(indices))
    for (i, row) in pairs(indices)
        rindices = rowindex(rows, row)
        prows[i] = parserow(@inbounds(@view(buf[rindices])), structtype)
    end
    return prows
end

function _tmaterialize(buf::Vector{UInt8}, rows::Vector{Int}, indices, names, structtype, nworkers::Int)
    parts = partitionrows(length(indices), nworkers)
    prows = Vector{NamedTuple{names, T} where T<:Tuple}(undef, length(indices))
    plen = length(parts[1])
    @sync for i in 1:nworkers
        @spawn begin
            crows = indices[parts[i]]
            for (j, row) in pairs(crows)
                rindices = rowindex(rows, row)
                row = parserow(@inbounds(@view(buf[rindices])), structtype)
                rnames = propertynames(row)
                prows[(i-1) * plen + j] = (;zip(rnames, [getproperty(row, n) for n in rnames])...)
            end
        end
    end
    return prows
end

function _materialize(buf::Vector{UInt8}, rows::Vector{Int}, indices, names, structtype)
    prows = Vector{NamedTuple{names, T} where T<:Tuple}(undef, length(indices))
    for (j, row) in pairs(indices)
        rindices = rowindex(rows, row)
        row = parserow(@inbounds(@view(buf[rindices])), structtype)
        rnames = propertynames(row)
        prows[j] = (;zip(rnames, [getproperty(row, n) for n in rnames])...)
    end
    return prows
end

function _filter(buf::Vector{UInt8}, f, rowtype, lineindex::Vector{Int}, structtype)
    prows = Vector{rowtype}(undef, 0)
    for row in 1:length(lineindex)-1
        rindices = rowindex(lineindex, row)
        row = parserow(@inbounds(@view(buf[rindices])), structtype)
        f(row) && push!(prows, row)
    end
    return prows
end

function _findall(lines::LineIndex, f)
    inds = Int[]
    for (i, row) in enumerate(lines)
        f(row) && push!(inds, i)
    end
    return inds
end

function _tfindall(buf::Vector{UInt8}, f, lineindex::Vector{Int}, nworkers::Int, structtype)
    tvec = Vector{Task}(undef, nworkers)
    parts = partitionrows(length(lineindex), nworkers)
    @sync for (i, part) in enumerate(parts)
        tvec[i] = @spawn begin
            out_i = Int[]
            for row in part
                index = rowindex(lineindex, row)
                rp = parserow(@inbounds(@view(buf[index])), structtype)
                f(rp) && push!(out_i, rp)
            end
            out_i
        end
    end
    return mapfoldl(fetch, vcat, tvec)
end

function _findnext(lines, f, i)
    len = length(lines)
    while !f(@inbounds(lines[i])) && i < len
        i += 1
    end
    return f(@inbounds(lines[i])) ? i : nothing
end

function _findprev(lines, f, i)
    while !f(@inbounds(lines[i])) && i > 1
        i -=1
    end
    return f(@inbounds(lines[i])) ? i : nothing
end

function _ftmaterialize(buf::Vector{UInt8}, f::Function, outtype, rows::Vector{Int}, indices, structtype, nworkers::Int)
    parts = partitionrows(length(indices), nworkers)
    prows = Vector{outtype}(undef, length(indices))
    plen = length(parts[1])
    @sync for i in 1:nworkers
        @spawn begin
            crows = indices[parts[i]]
            for (j, row) in pairs(crows)
                rindices = rowindex(rows, row)
                rp = parserow(@inbounds(@view(buf[rindices])), structtype)
                prows[(i-1) * plen + j] = f(rp)
            end
        end
    end
    return prows
end

function _tfilter(buf::Vector{UInt8}, f, rowtype, lineindex::Vector{Int}, structtype, nworkers::Int)
    parts = partitionrows(length(lineindex)-1, nworkers)
    rowbuf = [rowtype[] for _ in 1:nworkers]
    @sync for i in 1:nworkers
        @spawn begin
            for row in parts[i]
                rindices = rowindex(lineindex, row)
                rp = parserow(@inbounds(@view(buf[rindices])), structtype)
                f(rp) && push!(rowbuf[i], rp)
            end
        end
    end
    return foldl(vcat, rowbuf)
end

function _fmaterialize(buf::Vector{UInt8}, f::Function, outtype, rows::Vector{Int}, indices, structtype)
    prows = Vector{outtype}(undef, length(indices))
    for (j, row) in pairs(indices)
        rindices = rowindex(rows, row)
        rp = parserow(@inbounds(@view(buf[rindices])), structtype)
        prows[j] = f(rp)
    end
    return prows
end

function _columnwise(lines, coltypes)
    lookup = Dict{Symbol, Int}()
    columns = Vector{AbstractVector}(undef, 0)
    ncols = 0
    # Allocate known columns
    if !isnothing(coltypes)
        for (k, v) in coltypes
            ncols += 1
            lookup[k] = ncols
            push!(columns, Vector{v}(undef,length(lines)))
        end # for
    end # if
    # Add rows
    for (i, row) in enumerate(lines)
        rnames = propertynames(row)
        # Add values
        for name in rnames
            # Known columns
            if haskey(lookup, name)
                columns[lookup[name]][i] = row[name]
            # Unknonw columns
            else
                ncols += 1
                push!(columns, Vector{Union{Missing, Any}}(undef, length(lines)))
                @inbounds columns[ncols][1:(i-1)] .= missing
                lookup[name] = ncols
                columns[ncols][i] = row[name]
            end # if
        end # for rnames
        # Missing in current row
        mnames = filter(x -> x ∉ rnames, collect(keys(lookup)))
        for name in mnames
           columns[lookup[name]][i] = missing
        end # for mnames
    end # for lines
    fcolnames = sort(collect(keys(lookup)), by = k -> lookup[k])
    if !isnothing(coltypes)
        untyped = filter(x -> x ∉ collect(keys(coltypes)), fcolnames)
    else
        untyped = fcolnames
    end
    for col in untyped
        columns[lookup[col]] = [promote(columns[lookup[col]]...)...]
    end
    return (;zip(fcolnames, columns)...)
end # fun



JSON3.StructType(::Type{CategoricalArrays.CategoricalValue{T, M}} where {T, M}) = JSON3.StringType()
