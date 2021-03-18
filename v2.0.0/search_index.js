var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = JSONLines","category":"page"},{"location":"#JSONLines","page":"Home","title":"JSONLines","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"A simple package to read (parts of) a JSON Lines files. The main purpose is to read files that are larger than memory. The two main functions are LineIndex and LineIterator which return an index of the rows in the given file and an iterator over the file, respectively. The LineIndex is Tables.jl compatible and can directly be piped into e.g. a DataFrame if every row in the result has the same schema (i.e. the same variables). See also materialize and columnwise. It allows memory-efficient loading of rows of a JSON Lines file. In order to select the rows skip and nrows can be used to index nrows rows after skipping skip rows. The file is mmaped and only the required rows are loaded into RAM. Files must contain a valid JSON object (denoted by {\"String1\":ELEMENT1, \"String2\":ELEMENT2, ...}) on each line. JSON parsing is done using the JSON3.jl package. Lines can be separated by \\n or \\r\\n and some whitespace characters are allowed at the beginning of a line before the JSON object and the newline character (basically all that can be represented as a single UInt8). Typically a file would look like this: ","category":"page"},{"location":"","page":"Home","title":"Home","text":"{\"name\":\"Daniel\",\"organization\":\"IMSM\"}\n{\"name\":\"Peter\",\"organization\":\"StatMath\"}","category":"page"},{"location":"","page":"Home","title":"Home","text":"There is experimental support for JSON Arrays on each line where the first line after skip contains the names of the columns.","category":"page"},{"location":"","page":"Home","title":"Home","text":"[\"name\", \"organization\"]\n[\"Daniel\", \"IMSM\"]\n[\"Peter\", \"StatMath]","category":"page"},{"location":"","page":"Home","title":"Home","text":"This should work but is not tested thoroughly.","category":"page"},{"location":"#Getting-Started","page":"Home","title":"Getting Started","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"(@v1.5) pkg> add JSONLines","category":"page"},{"location":"#Functions","page":"Home","title":"Functions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [JSONLines]","category":"page"},{"location":"#JSONLines.LineIndex-Tuple{String}","page":"Home","title":"JSONLines.LineIndex","text":"LineIndex(path::String; filestart::Int = 0, skip::Int = 0, nrows::Int = typemax(Int), structtype = nothing, schemafrom::UnitRange{Int} = 1:10, nworkers::Int = 1)\n\nCreate an index of a JSONLines file at path\n\nKeyword Arguments:\nfilestart=0: Number of bytes to skip before reading the file\nskip=0: Number of rows to skip before parsing\nnrows=typemax(Int): Maximum number of rows to index\nstructtype=nothing: StructType passed to JSON3.read for each row\nschemafrom=1:10: Rows to parse initially to determine columnnames and columntypes\nnworkers=1: Number of threads to use for operations on the LineIndex\n\n\n\n\n\n","category":"method"},{"location":"#JSONLines.LineIterator-Tuple{String}","page":"Home","title":"JSONLines.LineIterator","text":"LineIterator(path::String; filestart = 1, structtype = nothing)\n\nCreate an iterator of a JSONLines file at path.\n\nKeyword Arguments:\nfilestart=1: Row at which to start the iterator\nstructtype=nothing: StructType passed to JSON3.read for each row\n\n\n\n\n\n","category":"method"},{"location":"#Base.filter-Tuple{Function,LineIndex}","page":"Home","title":"Base.filter","text":"filter(f::Function, lines::LineIndex)\n\nReturn rows of lines for which f evaluates to true\n\n\n\n\n\n","category":"method"},{"location":"#Base.findall-Tuple{Function,LineIndex}","page":"Home","title":"Base.findall","text":"findall(f::Function, lines::LineIndex)\n\nReturn indices of lines for which f evaluates to true\n\n\n\n\n\n","category":"method"},{"location":"#Base.findfirst-Tuple{Function,LineIndex}","page":"Home","title":"Base.findfirst","text":"findfirst(f::Function, lines::LineIndex)\n\nReturn index of first row for which f returns true\n\n\n\n\n\n","category":"method"},{"location":"#Base.findlast-Tuple{Function,LineIndex}","page":"Home","title":"Base.findlast","text":"findlast(f::Function, lines::LineIndex)\n\nReturn index of last row for which f returns true\n\n\n\n\n\n","category":"method"},{"location":"#Base.findnext-Tuple{Function,LineIndex,Int64}","page":"Home","title":"Base.findnext","text":"findnext(f::Function, lines::LineIndex, i::Int)\n\nReturn index of next row for which f returns true starting at row i\n\n\n\n\n\n","category":"method"},{"location":"#Base.findprev-Tuple{Function,LineIndex,Int64}","page":"Home","title":"Base.findprev","text":"findnext(f::Function, lines::LineIndex, i::Int)\n\nReturn index of previous row for which f returns true starting at row i\n\n\n\n\n\n","category":"method"},{"location":"#JSONLines.columnnames-Tuple{LineIndex}","page":"Home","title":"JSONLines.columnnames","text":"columnnames(lines::LineIndex)\n\nReturns the columnnames of the LineIndex\n\n\n\n\n\n","category":"method"},{"location":"#JSONLines.columntypes-Tuple{LineIndex}","page":"Home","title":"JSONLines.columntypes","text":"columntypes(lines::LineIndex)\n\nReturns current value of columntypes of lines.\n\n\n\n\n\n","category":"method"},{"location":"#JSONLines.columnwise-Tuple{LineIndex}","page":"Home","title":"JSONLines.columnwise","text":"columnwise(lines::LineIndex; coltypes = lines.columntypes)\n\nParse lines to columnwise vectors. Similar to Tables.columntable\n\n\n\n\n\n","category":"method"},{"location":"#JSONLines.gettypes","page":"Home","title":"JSONLines.gettypes","text":"gettypes(lines::LineIndex, rows = 1:5)\n\nInfer types of columns in lines based on rows selected. Returns Dict of types.\n\n\n\n\n\n","category":"function"},{"location":"#JSONLines.materialize","page":"Home","title":"JSONLines.materialize","text":"materialize(lines::LineIndex, rows::Union{UnitRange{Int}, Vector{Int}} = 1:length(lines))\n\nReturn a Vector{NamedTuple} of the rows selected. Similar to Tables.rowtable\n\n\n\n\n\n","category":"function"},{"location":"#JSONLines.materialize-2","page":"Home","title":"JSONLines.materialize","text":"materialize(lines::LineIndex,  f::Function, rows::Union{UnitRange{Int}, Vector{Int}} = 1:length(lines); eltype = T where T)\n\nApply f to rows selected. eltype of result can be specified as keyword argument.\n\n\n\n\n\n","category":"function"},{"location":"#JSONLines.select-Tuple{String,Vararg{Any,N} where N}","page":"Home","title":"JSONLines.select","text":"select(path::String, cols...; nworkers = 1) => LineIndex\n\npath: Path to JSONLines file \ncols...: Columnnames to be selected\nKeyword Argument:\nnworkers=1: Number of threads to use for operations on the resulting LineIndex\n\n\n\n\n\n","category":"method"},{"location":"#JSONLines.settype!-Tuple{LineIndex,Union{Pair{Symbol,DataType}, Pair{Symbol,Union}, Pair{Symbol,UnionAll}}}","page":"Home","title":"JSONLines.settype!","text":"settype!(lines::LineIndex, p::Union{Pair{Symbol, DataType},Pair{Symbol, UnionAll}, Pair{Symbol, Union}})\n\nSet a single columntype using :col => Type.\n\n\n\n\n\n","category":"method"},{"location":"#JSONLines.settypes!","page":"Home","title":"JSONLines.settypes!","text":"settypes!(lines::LineIndex, rows::Union{UnitRange{Int}, Vector{Int}} = 1:5)\n\nInfer types of columns in lines based on rows selected. Overwrites existing types.\n\n\n\n\n\n","category":"function"},{"location":"#JSONLines.settypes!-Tuple{LineIndex,Union{Dict{Symbol,DataType}, Dict{Symbol,Union}, Dict{Symbol,UnionAll}}}","page":"Home","title":"JSONLines.settypes!","text":"settypes!(lines::LineIndex, d::Union{Dict{Symbol, DataType}, Dict{Symbol, UnionAll}, Dict{Symbol, Union}})\n\nManually set types for columns. d is a Dict in which keys are Symbols corresponding to columnnames and values are the datatypes.\n\n\n\n\n\n","category":"method"},{"location":"#JSONLines.writelines-Tuple{String,Any}","page":"Home","title":"JSONLines.writelines","text":"writelines(path::String, rows; nworkers = 1, mode = \"w\")\n\nWrite rows to JSONLines file path\n\npath: Path to output file\nrows: Tables.jl compatible data\nKeyword Arguments:\nnworkers=1: Number of threads to use for parsing to JSONLines\nmode=\"w\": Mode the file is opened in. See I/O and Network\n\n\n\n\n\n","category":"method"},{"location":"#JSONLines.@MStructType-Tuple{Any,Vararg{Any,N} where N}","page":"Home","title":"JSONLines.@MStructType","text":"@MStructType name fieldnames...\n\nThis macro gives a convenient syntax for declaring mutable StructTypes for reading specific variables from a JSONLines file. Also defines row[:col] access for rows of the resulting type.\n\nname: Name of the StructType\nfieldnames...: Names of the variables to be read (must be the same as in the file)\n\n\n\n\n\n","category":"macro"}]
}