### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ dce8dbce-c8b4-11ed-3263-65232dc16f8d
begin
	using PlutoUI, Dates, Plots, PlotThemes, StatsBase, LinearAlgebra, Interpolations, SmoothingSplines, Distributions, LsqFit, Downloads
	theme(:default) # :dark)
end

# ╔═╡ 9273a0e2-6233-42c2-8419-3190a0b79a18
html"<button onclick='present()'>present</button>"

# ╔═╡ 6344e5de-7e6e-4efd-9ce5-c2140eaf38da
TableOfContents()

# ╔═╡ 754dbb34-631a-4aea-8660-443f70f11ea9
md"""
## Statistics of Supernova Remnants

This tutorial is based on the paper, *A Statistical Analysis of Galactic Radio Supernova Remnants,* by S. Ranasinghe and D. Leahy, whom we acknowledge for communication that assisted our understanding.
"""

# ╔═╡ a7f8f920-5ee8-420a-bcb2-fcd30dde7d28

md"""
!!! tip

    The `PlotThemes` package allows for selection of a dark background for plots.


"""

# ╔═╡ 12b1a873-a22d-4fbc-bacb-f37b3767d2a2
md"If you desire a dark background, then check this box: $(@bind darkTH CheckBox(default = false))"

# ╔═╡ 94062cd4-b278-444d-b93e-694d26d30b50
if darkTH theme(:dark) else theme(:default) end

# ╔═╡ c8bacb96-8c31-4f7c-a42c-c94b5df0dd23
module MRTables

export MRTable, Field

struct Field
    range::UnitRange
	type::String
    unit::Union{String, Nothing}
    label::Union{String, Nothing}
    comment::Union{String, Nothing}
end

function Field(r::AbstractString, f::AbstractString, u::AbstractString, l::AbstractString, c::AbstractString)
    Field(range(parse.(Int, split(r, '-'))...),
          f,
          u == "---" ? nothing : u,
          l == "---" ? nothing : l,
          c == "---" ? nothing : c)
end

struct MRTable
    title::AbstractString
    authors::AbstractString
    table::AbstractString
    filename::AbstractString
    notes::Vector{Any}
    format::Vector{Field}
    data::Vector{Tuple}
end

const header_regex = [r"Title:\s*(?<article_title>\N*)\s*",
                      r"Authors:\s*(?<authors>\N*)\s*",
                      r"Table:\s*(?<table_title>\N*)\s*",
                      r"Description of file:\s*(?<filename>\N*)\s*"]
const note_regex   = r"Note\s+\((?<number>\d+)\):\s+(?<label>\N*)"
const field_regex  = r"\s*(?<range>\d+\s*-\s*\d+)\s+(?<format>\S+)\s+(?<unit>\S+)\s+(?<label>\S+)\s+(?<comment>\N+)"

const real_values  = Dict('I'=>Int, 'F'=>Float64)

function parse_data(field, line)
    if field.type[1] in keys(real_values) && length(strip(line[field.range])) > 0
        value = parse(real_values[field.type[1]], line[field.range])
    elseif length(strip(line[field.range])) == 0
        value = missing
    else
        value = strip(line[field.range])
    end
    value
end

function MRTable(filename::String)

    lines = eachline(filename)

    #   Read header lines
    header = Dict()
    for line in lines
        if match(r"^-+$", line) != nothing
            break
        end
        for regex in header_regex
            if (matched = match(regex, line)) != nothing
                header[keys(matched)[1]] = String(matched[1])
            end
        end
    end

    #   Read format lines
    format = []
    for line in lines
        if match(r"^-+$", line) != nothing && length(format) > 0
            break
        elseif (matched = match(field_regex, line)) != nothing
            push!(format, Field(matched.captures...))
        end
    end

    #   Read note lines
    notes, note::Vector{Union{Tuple, String}}, j = [], [], 0
    for line in lines
        if match(r"^-+$", line) != nothing
            break
        elseif (matched = match(note_regex, line)) != nothing
            j = parse(Int, (matched["number"]))
            note = [(j, matched["label"])]
            push!(notes, note)
        elseif j > 0
            push!(note, line)
        end
    end
    
    #   Read data lines
    data = []
    for line in lines
        if match(r"^-+$", line) != nothing
            break
        end
        push!(data, Tuple([parse_data(field, line) for field in format]))
    end
    
    MRTable(header["article_title"], header["authors"], header["table_title"],
        header["filename"], notes, format, data)
end

end

# ╔═╡ d10e1824-f773-41cf-9b69-5b296f245fd6
md"""
### Read the machine readable table (MRT) file

The data for this tutorial is in a standard "Machine Readable Table" from _The Astrophysical Journal_.
 - [Here](https://journals.aas.org/mrt-overview/) is the link to the standard.
 - [Here](https://iopscience.iop.org/article/10.3847/1538-4365/acc1de#apjsacc1det1) is the link to table.

However, the tutorial website already has a copy, which we will use.

    allInfo = MRTables.MRTable(Downloads.download("https://github.com/barrettp/JuliaAASWorkshop/raw/main/apjsacc1det1_mrt.txt"))
"""

# ╔═╡ f07f26a4-54be-4561-8565-0aaace111969
allInfo = MRTables.MRTable(Downloads.download("https://github.com/barrettp/JuliaAASWorkshop/raw/main/apjsacc1det1_mrt.txt"))

# ╔═╡ 81265717-bcbf-4a70-a7a6-9f770f47ce42
md"""

We find $(length(allInfo.data)) rows of SNR data and clarifying notations.

!!! note
    Note that the module that reads the MRT data takes advantage of Julia's "missing" singleton, which is a recommended Julia standard. Where data are not provided, one need not worry about any particular form or special symbol(s), and in what follows, we shall benefit from this uniformity.
"""

# ╔═╡ 84c802b9-69a6-4524-8e5d-766043fb98dc
md"""
### Producing (and then fitting) a histogram of SNR diameters.

Because we'll be looking at data in columns, to save a little typing we define a (one-line) function, `goDownColumn`, that does the marching down the provided column and also implements a `skipmissing`.

The `skipmissing` takes effect (typically with `collect`) later to produce arrays of the values.  Without `skipmissing`, Julia creates a "Union" of {Missing, Float64}, and the `missing`s would then be included in the final data array.

    goDownCol(col::Int64) = skipmissing([row[col] for row in allInfo.data])
"""

# ╔═╡ 77406430-6687-461e-bb4e-b6dabb873266


# ╔═╡ 5f447a92-ec35-4997-b0a0-6c1c8ed2b199
md"""
    typeof(([row[colRadius] for row in allInfo.data]))
"""

# ╔═╡ 1e7de711-6ddb-479b-8b97-cd42e0bb4421


# ╔═╡ c86d69ba-19a6-4367-b505-af9af27b977c
md"""
    typeof(skipmissing([row[colRadius] for row = allInfo.data]))
"""

# ╔═╡ cbaa2844-7054-4e8a-8d92-9706a6a49cef


# ╔═╡ 39044a6f-c1e4-48a9-988a-50a8194d0224
md"""
Columns we will be using throughout are defined here by hand, and we can confirm the correct number has been chosen by looking at `format`. The "comment" for `colRadius` lets us know that for additional information, there is a note, (4), to read.

	begin
    	colRadius = 41
	    colDistanceLimit = 40
	    colSNRname = 3
	    colFluxDensity = 44
	    colSNRType = 6
	    colAge = 32
	    colAgeLimit = 31
	    xAxisLabel_Dhist = "SNR Diameter, D (pc)"
	    yAxisLabelCount = "Number"
	    yAxisLabelPDF = "Probability Density (pc\$\\textrm{^{-1}}\$)"
	end
"""

# ╔═╡ 15439e8c-e40a-44fe-a881-f54eafcef952


# ╔═╡ e9629629-7870-4b7a-a457-cc4890245d99
md"""
Show the format for `colRadius`.

     allInfo.format[colRadius]
"""

# ╔═╡ 4d375940-79b4-4764-8d06-10982b37c809


# ╔═╡ 62b0759b-d78d-4e03-95fc-0d87e7935857
md"""
The format for `colRadius` references Note 4. Let's take a look at it.

    allInfo.notes[4]
"""

# ╔═╡ 2c9baa7f-1949-4ba7-bbf0-33ea49877b19


# ╔═╡ b48e97b0-8e8e-4710-87fe-7e3a7bee007d
md"""
As an aside, with `findall`, which yields the indices satisfying a given condition, I start the variable with `ind_` to remind myself that these are the indices of some variable, not the variable itself.

We first "go down" the column that contains the radii information, taking only the ones that are not missing (`!ismissing(x)`).  As noted above, the `goDownCol` function contains the `skipmissing` command.

    ind_nonMissingRadii = findall(x -> !ismissing(x), goDownCol(colRadius))
"""

# ╔═╡ 0618b8ae-17fd-432c-a84b-d079c9038658


# ╔═╡ 1948458d-31ba-46d2-915b-b3aba9dabf61
md"""
Collect the non-missing diameter indices; initially, we find 219.

We then need to exclude one specific SNR and because some distances are given as upper or lower limits, another 4.
"""

# ╔═╡ 3cfd5406-a4e3-4ecf-86ea-e30e67e18bf2
md"""
We need the index to the problematic SNR that is too close to the Galactic Center (G1.4 -0.1).

    ind_G1p4M0p1 = findall(x -> x == "G1.4 -0.1", goDownCol(colSNRname))
"""

# ╔═╡ 48d4e255-df17-40ab-9edb-a8a770a116bb


# ╔═╡ f3822529-62fa-4275-bd0e-ea410b22fa59
md"""
By looking at the two variables above, we can see immediately that the index for that SNR, index 5, is already not included in the "nonMissingRadii," but in a more general case, we can check  with `in(item, collection)`, and the "false" response confirms its absence.

    in(ind_G1p4M0p1, ind_nonMissingRadii)
"""

# ╔═╡ 619b64b4-fe02-4954-a02e-d7f8d979546d


# ╔═╡ 2e3cf549-0616-4809-ba38-73f7c6a94c34
md"""
Now we find the indices of the SNRs to be excluded because their distances are given only as limits, and then we use `symdiff` (if you will, the opposiste of `intersect`: "set of non-overlapping items between two sets") to remove them from the array of desired indices.

    ind_UpperOrLowerLimits_OnDistance = findall(x -> x in [">", "<"], goDownCol(colDistanceLimit))
"""

# ╔═╡ bde10148-2a5f-4597-8e81-f54d71f05728


# ╔═╡ 1b13dc19-adcb-493b-a571-aa2811f79398
md"""
Get indices of good radii.

    ind_goodRadii = symdiff(ind_nonMissingRadii, ind_UpperOrLowerLimits_OnDistance)
"""

# ╔═╡ e11428ed-8814-417c-8746-6d98b14d28f8


# ╔═╡ 1734423f-9bf5-4d0e-b135-c550405f8783
md"""
We go down the column again, but this time selecting only the indices that we have whittled down to the good ones, and we multiply those radii by 2 to get the SNR diameters. The yield is 215 SNRs.

    begin
	    diameters = 2*goDownCol(colRadius)[ind_goodRadii]
	    nDiam = length(diameters)
    end
"""

# ╔═╡ 06e9ea84-bb8e-4c29-93d2-9e8db8fa7dd3


# ╔═╡ c7939c4f-c446-4099-8f3b-9ab3f410129f
md"""
### Histogram of SNR diameters

We will begin by fitting a histogram to the diameters. This unadorned statistical function performs simple counting with automatic binning into bins of 20 pc. The bins' `edges` are given, as are the resulting `weights` (counts) in each bin. We see, too, that the left side of each bin is included but the right side is not. (If there was a diameter exactly at the right edge, an additional bin would have been needed.)

    yFit = fit(Histogram, diameters)
"""

# ╔═╡ aded4bdf-3511-49ee-9072-3f6f7f55e8a9


# ╔═╡ 7da41643-f486-4e2f-9ee2-06af0d7395d4
md"""
A check on the sum of the weights shows we have not missed any SNRs.

    sum(yFit.weights)
"""

# ╔═╡ 2ec1a630-cde0-4d8f-b9b5-170fa1d122c6


# ╔═╡ 14a44aba-00c1-4b0a-abfd-cfd04147d2e2
md"""
Plot the histogram.

    plot(yFit, label = "automatic binning", xlabel = xAxisLabel_Dhist, ylabel = yAxisLabelCount)
"""

# ╔═╡ 029336a2-e4db-47f9-8fff-6d751bcf4c4d


# ╔═╡ b54e32a0-b0b7-4fae-826d-2c61cf85dcc1
md"""
Let's change the bin size to 10 pc and create `yFit2`.

We retain the first and last edges from the automatic procedure.

    begin
	    binSize = 10
	    firstEdge = first(yFit.edges[1]) # is zero
	    lastEdge =  last(yFit.edges[1])  # is 180
	    edgeRange = firstEdge:binSize:lastEdge
    end
"""

# ╔═╡ 53fcf13c-c5d1-425e-bc1a-241aaea7f9c5


# ╔═╡ 51f6bf67-bec3-4233-a204-3d1919367fed
md"""
    yFit2 = fit(Histogram, diameters, edgeRange)
"""

# ╔═╡ bc29b8ce-4d25-4faa-b53a-17d2c8f81705


# ╔═╡ 0c2ed5dd-1085-4ee7-8969-2961b319978d
md"""
Replot histogram.

    plot(yFit2, label = "bin size specified to 10 pc",  xlabel = xAxisLabel_Dhist, ylabel = yAxisLabelCount)
"""

# ╔═╡ 940ee3ff-0e76-4806-8345-d3acd351fbff


# ╔═╡ 22a4c491-37f0-4e10-82e1-a9512ab1ef17
md"""
Now change the y axis to a probability density function: `isdensity` becomes `true` when we "normalize" the fit: `h = normalize(yFit2, mode= :pdf)`.

Make the x axis more informative.

    h = normalize(yFit2, mode= :pdf)
"""

# ╔═╡ edd772bd-1152-4aca-ac19-58df089fae40


# ╔═╡ 4ec97f31-089e-4e89-bdd3-d8f03892ad31


# ╔═╡ 23bebd3d-c744-44ad-b01d-bff674a36b07
md"""
### Cubic Spline interpolation

Can do a cubic spline interpolation on the pdf and then turn it into a function.

First, the interpolation, which goes through every point.

    cubicInterp = Interpolations.interpolate(h.weights, BSpline(Cubic(Line(OnCell()))))
"""

# ╔═╡ 754a4149-8d0e-40bf-9f9e-a18b193dfe71


# ╔═╡ a3092e77-6888-4d58-aca1-37944a4896fb
md"""
Plot spline interpolation.

    begin
        scatter(yFit2.edges[1][1:18, 1], h.weights,  xlabel = xAxisLabel_Dhist, ylabel = yAxisLabelPDF, xlims = (firstEdge, lastEdge), xticks = (firstEdge:(2*binSize):lastEdge), xminorticks = 2, widen = true, label = "")
       plot!(yFit2.edges[1][1:18, 1], cubicInterp, label = "", title = "Interpolation")
    end
"""

# ╔═╡ 10476ffe-2b37-4e15-9ef8-543c5c146e77


# ╔═╡ c1c15ecc-1f72-402c-bcc5-d1adc4814f38
md"""
The "scaling" turns the interpolation into a function that can be evaluated at intermediate values to prodce a smooth line.

Because the orignal has 18 points (18 bins, 19 edges), the scaling function requires 18; hence we start it at 1 (second edge divided by binSize:

    yFit2.edges[1][2])/binSize = $(yFit2.edges[1][2]/binSize))

and not at `firstEdge`.
"""

# ╔═╡ 791fb1ff-6fce-4023-9908-c254513da7eb
md"""
    cubicScaled = Interpolations.scale(cubicInterp, 1:binSize:lastEdge)
"""

# ╔═╡ 635ec2cd-a3b3-4629-ac6d-9fc4853a3749


# ╔═╡ b02bfcc7-5d37-405c-8862-493b9c28fc38
md"""
    typeof(cubicScaled)
"""

# ╔═╡ 4dda961e-a2ff-403f-9087-48254dac1d77


# ╔═╡ 2409c827-9d9d-44b4-91fb-a1516dcdc632
md"""
As an example of how the new variable can be evaluated at any (internal) point, `cubicScaled(166)`.

`cubicScaled(176)` fails because `1:binSize:lastEdge` corresponds to the 18 points 1.0:10.0:171.0.

For plotting, we could create a new variable, `cubicFiner = [cubicScaled(i) for i=0:176]`, with values at about ten times as many points that could then be plotted.

We would have to be careful about the x variable, which corresponds to the index, which starts at 1 and would correspond to the first index of `cubicFiner` unless explicitly directed.

Better, we can simply plot the scaled variable function directly, and the limits being plotted are clear: `plot(x -> cubicScaled(x), lowerLimit, upperLimit)`.

    cubicFiner = [cubicScaled(i) for i=0:176]
"""

# ╔═╡ 7c5fb45c-a687-4ed2-8c5f-e93f1d48fac7


# ╔═╡ b3607a9a-2472-4e15-8e90-d2da6675949f
md"""
Plot both the histogram and the spline on the smae plot.

    begin
        plot(h, label = "", xlabel = xAxisLabel_Dhist, ylabel = yAxisLabelPDF, xlims = (firstEdge, lastEdge), xticks = (firstEdge:2*binSize:lastEdge), xminorticks = 2, widen = true)
        plot!(x -> cubicScaled(x), 0, 176, linewidth=2, color = :black, label = "interpolated")
    end
"""

# ╔═╡ a5bc399a-3f49-4e17-a136-df02f5bd7e4a


# ╔═╡ eeba065c-942e-46f0-a3eb-d89e90bc514a
md"""
However, suppose instead we want a smoothing (as in the figure in the paper) that does not hit the points exactly but, instead, well, smooths them.

Again we need 18 points on the x axis, but now we want to start at zero, so we can use:

    yFit2.edges[1][1:18, 1]
	
or

    firstEdge:binSize:lastEdge - 1
"""

# ╔═╡ afe53e77-d73b-439f-8746-dc27c399dc59


# ╔═╡ ae34a53f-da42-42ac-b283-eefa09f3c86d
md"""

    smooth = fit(SmoothingSpline, yFit2.edges[1][1:18, 1], h.weights, 250.0) # λ=250.0 

!!! note
 
     "This smoothing function is based on:"
     [1] Reinsch, Christian H. "Smoothing by spline functions." Numerische mathematik 10.3 (1967): 177-183. 

     [2] Green, Peter J., and Bernard W. Silverman. Nonparametric regression and generalized linear models: a roughness penalty approach. CRC Press, 1993.
"""

# ╔═╡ e2f76f80-4f4a-4304-ad6f-fea7b4042019
 

# ╔═╡ cdfc3aeb-169d-438f-8482-a78282b6c674
md"""
And again we have the choice between plotting a new variable with a finer distribution or plotting the function directly, but with this package, the transition to a functional form of `smooth` is:

    smoothFiner = [predict(smooth, i) for i = 0:176.]

The `176.` ensures that we are using floating point numbers and not integers.
"""

# ╔═╡ 54fb1116-4887-4690-8c14-e70e206ce033


# ╔═╡ 539d14a0-627e-482a-91c7-27df784ca323
md"""
We now add the means and the standard error to the plot as vertical lines with `vline!`.

    begin
        ArithMean = mean(diameters)
        GeoMean = geomean(diameters)
        DStdError = std(diameters)/sqrt(length(diameters))
    end
"""

# ╔═╡ 09f7e727-c45a-424c-8a12-62c952a85814


# ╔═╡ 758a6437-156f-4b95-b522-341950203175
md"""
Recreate histogram-spline plot marking the means.

    begin
        annGeoMean = (65, 0.025, text("$(round(GeoMean, digits = 1)) = geometric mean", :red, 10))
        annArithMean = (72, 0.022, text("$(round(ArithMean, digits = 1)) \$\\pm\$ $(round(DStdError, digits = 1)) = arithmetic mean", :red, 10))
        plot(h, xlabel = xAxisLabel_Dhist, ylabel = yAxisLabelPDF, label = "", xlims = (firstEdge, lastEdge), xticks = (firstEdge:2*binSize:lastEdge), xminorticks = 2, widen = true)
       plot!(x -> cubicScaled(x), 0, 176, linewidth=2, color = :black, label = "interpolated")
       plot!(x -> predict(smooth, x), 0, 176, linewidth = 3, color = :orange, label = "smoothed")
       vline!([ArithMean], linewidth = 3, label = "", ann = annArithMean)
       vline!([GeoMean], linewidth = 3, label = "", ann = annGeoMean)
    end
"""

# ╔═╡ 66cc97b4-77f7-4cb3-8c7d-fc58990e6cc3


# ╔═╡ 7ae4956c-b5e0-41fa-8b34-2e71e3cfd6f5
md"""
### Empirical Cumulative Distribution Function

With standard functional distributions, e.g., Normal, use the Distributions package. Here, the function `ecdf` could be used, resulting in a type "ECDF{Vector{Float64}, Weights{Float64, Float64, Vector{Float64}}}"

Instead, we need only two lines to contruct the CDF manually (and the fitting that then can follow is more direct). We create a range from 1 to `nDiam` and broadcast a division by `nDiam`.  Then we sort the diameters and make the plot.

    begin
        empiricalCDF = (1:nDiam)./nDiam
        sortedD = sort(diameters)
    end
"""

# ╔═╡ 2f902640-65c2-4e97-8cca-ebc58c3bd5b5


# ╔═╡ 417dd70f-6895-4117-b7d5-8a3159a2c1fc
md"""
Plot the cumulative distribution.

    scatter(sortedD, empiricalCDF, xlabel = xAxisLabel_Dhist, ylabel = "Fraction of SNRs", title = "Empirical Cumuluative Distribution", label = "", xlims = (firstEdge, lastEdge), xticks = (firstEdge:2*binSize:lastEdge), xminorticks = 2, widen = true)
"""

# ╔═╡ 08c95754-1919-48d5-9610-5e9667864d91


# ╔═╡ f6938470-42a8-471d-99a2-fe22d81aefa7
md"""
We can also do an interpolated ECDF.

    interpECDF = Interpolations.interpolate(empiricalCDF, BSpline(Cubic(Line(OnCell()))))
"""

# ╔═╡ 1362c5e8-a8df-4daa-ae02-3b9c3e779e80


# ╔═╡ 1209bcc5-1fc4-4c31-8031-836c191f2e15
md"""
As before, an interpolated version would allow determination at intermediate values, but scaling would not be needed because the interprolation is already scaled to the proper x-axis limits.

    scatter(sortedD, interpECDF)

would reproduce the above plot.    
"""

# ╔═╡ e77886fa-4145-402e-8674-ec0146608073


# ╔═╡ a58f3563-ec5d-459d-89ea-892a964d53a6
md"""
### The SNR Σ -- D Relation

All the SNRs with diameter estimations do not  have 1 GHz flux densities. A further subset of those that remain  are shell-type, and those are the ones we wish to plot.

Again we use `findall` and `intersect` to find the indices of the ones with flux densities that are shell type, plotting those with "good Sigma."  Additionally, we will use a best-fit line to Σ--D and a color bar of the ages of the remnants.

    begin
        ind_FluxDensities = findall(x -> !ismissing(x), goDownCol(colFluxDensity))
        ind_shellType = findall(x -> x=="S", goDownCol(colSNRType))
        ind_RadiiWFluxDen = intersect(ind_goodRadii, ind_FluxDensities)
        ind_goodSigma = intersect(ind_shellType, ind_RadiiWFluxDen)
        length(ind_RadiiWFluxDen) # we get 185; the paper says 187
        diametersΣShells = 2*goDownCol(colRadius)[ind_goodSigma]
        ΣShells = goDownCol(colFluxDensity)[ind_goodSigma]
    end
"""

# ╔═╡ 21a191f5-4b90-48e3-ab46-57352552040b


# ╔═╡ b8725478-19c6-4c62-9c8f-274cf768bfc9
md"""
#### Age in kilo years

Here we're ignoring scientific niceties such as limits.

And we note the function `extrema`, which delivers the minimum and maximum of a variable at one shot.

    ind_AgeLimits = findall(x -> x in [">", "<"], goDownCol(colAgeLimit))
"""

# ╔═╡ 575922c3-2007-45ad-9ced-a68f7c56f789


# ╔═╡ 6ca08891-0490-489c-8d8c-0dcccd399794
md"""
Find all ages of SNR in the table.

    begin
        ind_MissingAge = findall(x -> ismissing(x), [row[colAge] for row in allInfo.data]) 
        ind_goodSigmaMissingAge = intersect(ind_MissingAge, ind_goodSigma)
        ind_goodSigmaWithAge = symdiff(ind_goodSigma, ind_goodSigmaMissingAge)
        diametersToPlot = 2*goDownCol(colRadius)[ind_goodSigmaWithAge]
        ΣShellsToPlot = goDownCol(colFluxDensity)[ind_goodSigmaWithAge]
        agesToPlot = goDownCol(colAge)[ind_goodSigmaWithAge]
        extrema(agesToPlot)
    end
"""

# ╔═╡ f2b86512-40a3-4f99-a0c3-937cfe684a14


# ╔═╡ 14daec81-e47e-43d7-9a5c-1f5ed5844eee
md"""
The extremes let us know immediately that we'll need to use the logarithms of the ages also.

    begin
        z = agesToPlot
        ticks = 10.0 .^ collect(range(-2, length = 7))
        Ylabel = "\$\\textrm{\\Sigma_{1GHz} (10^{-21} W m^{-2} Hz^{-1} Sr^{-1}}\$)" 
        scatter(diametersToPlot, ΣShellsToPlot, zcolor = log10.(z), yaxis=:log, xaxis=:log, label="", xlabel=xAxisLabel_Dhist, ylabel=Ylabel, xlims=(0.1, 200), xticks=ticks, xminorticks=9, ylims=(0.01, 10.0^(4.5)), yticks=ticks, yminorticks=9, widen=true, colorbar_title="Log age")
    end
"""

# ╔═╡ c5615313-31ac-4993-8e88-987b4b6e0851


# ╔═╡ a239a50b-db01-4342-9c8d-821e63290a7a
md"""
We do a best fit on Σ--D and here plot the logarithms directly (instead of letting the plotting function take them).

    begin
        XX, YY = log10.(diametersToPlot), log10.(ΣShellsToPlot)
        minXX, maxXX = extrema(XX)[1], extrema(XX)[2]
    end
"""

# ╔═╡ ade1768e-c5ee-4cd5-ad9f-19948265b9c3


# ╔═╡ 9ae6b1ec-b446-4652-a1e1-f9629c47f1c3
md"""
The straight-line model to be fit is here.

    begin
        @. model(t, p) = p[1] * t + p[2]
        p0 = [-1.5, 10]
    end
"""

# ╔═╡ c39c4144-de4a-407d-beda-2f481bdc8f49


# ╔═╡ 295d30f4-4a03-45d5-8dec-86d836da13ae
md"""
Use the Levenberg-Marquart least squares algorithm to fit a straight line through the data.

    LSfit = LsqFit.curve_fit(model, XX, YY, p0)
"""

# ╔═╡ 263833e1-3105-4c56-a3dc-30ae6934e1f8


# ╔═╡ 877ccfff-de5d-46d5-aff8-0bd71d14e996
md"""
We use the results of the model to get the Σ values at the minimum and maximum diameters, which we then plot.

    begin
        m = LSfit.param[1]
        b = LSfit.param[2]
        @. results(x) = m * x + b
        twoYs = results([minXX, maxXX])
    end
"""

# ╔═╡ d7b126b1-f5b6-4e38-a40e-2d6918fda741


# ╔═╡ 2bd1f2be-9318-44e8-9791-c8d1451b4522
md"""
Create a scatter plot with best fit line.

    begin
        scatter(XX, YY, zcolor=log10.(z), label="", xlabel="Log "*xAxisLabel_Dhist, ylabel="Log "*Ylabel, xminorticks=9,  widen=true, colorbar_title="Log age ")
        scatter!([minXX, maxXX], twoYs, label="")
        plot!([minXX, maxXX], twoYs, label="")
    end
"""

# ╔═╡ 35405245-31b4-400b-9c42-b957f606188c


# ╔═╡ 57e60f44-342a-4023-8011-cfc425908744
md"""
!!! note

    What have we learned?

    - With the newly created MRTs module, machine-readable ApJ tables can be read.
      - It made major use of structs to create composite types.
      - To disambiguate the text file, Regular Expressions operating on Strings were needed throughout.
      - The `eachline` command executed on the filename allowed for implicit iteration over all the file lines.
      - Perhaps most important, by replacing blank entries with the Julia standard, "missing," subsequent processing was standardized.
    - Histogram and Cumulative Distribution Creation 
      - A one-line function to march down the MRT's columns used `skipmissing`, which accepts the missing values initially, but when "collected" into an array, they are not included.
      - To pull out the desired values, `findall` generates indices meeting specified conditions.
      - Then `intersect` and `symdiff` were used to produce arrays containing what was desired.
      - The SNR diameters were `fit` to a Histogram function, first with automatic binning, and then with a specified bin size.
      - Instead of counts, the Histogram output was changed to a density.
      - he Interpolations package was used to create a function that reproduced the points.
      - The SmoothingSplines packaged was used to produce a smooth function over the points.
      - Plotting the function could then be accomplished directly in the plotting command.
      - Two different means were generated and placed as vertical lines.
      - Broadcasting was used to write a one-line empirical CDF.
    - The Σ -- D Relationship
      - After further selection of diameters, densities, and ages, the LsqFit package was used to find a best fit.
      - Two different ways of plotting logarithms were used.

    - Finally, we reiterate that as long as someone has the appropriate MRT file to read (and Julia, of course!), this notebook will work. It can also be exported from Pluto as an html file and viewed without Julia.
"""

# ╔═╡ 8237e174-f6ee-4b4a-9928-dfe7b239b467
html"<button onclick='present()'>present</button>"

# ╔═╡ Cell order:
# ╟─9273a0e2-6233-42c2-8419-3190a0b79a18
# ╟─dce8dbce-c8b4-11ed-3263-65232dc16f8d
# ╟─6344e5de-7e6e-4efd-9ce5-c2140eaf38da
# ╟─754dbb34-631a-4aea-8660-443f70f11ea9
# ╟─a7f8f920-5ee8-420a-bcb2-fcd30dde7d28
# ╟─12b1a873-a22d-4fbc-bacb-f37b3767d2a2
# ╟─94062cd4-b278-444d-b93e-694d26d30b50
# ╟─c8bacb96-8c31-4f7c-a42c-c94b5df0dd23
# ╟─d10e1824-f773-41cf-9b69-5b296f245fd6
# ╟─f07f26a4-54be-4561-8565-0aaace111969
# ╟─81265717-bcbf-4a70-a7a6-9f770f47ce42
# ╟─84c802b9-69a6-4524-8e5d-766043fb98dc
# ╠═77406430-6687-461e-bb4e-b6dabb873266
# ╟─5f447a92-ec35-4997-b0a0-6c1c8ed2b199
# ╠═1e7de711-6ddb-479b-8b97-cd42e0bb4421
# ╟─c86d69ba-19a6-4367-b505-af9af27b977c
# ╠═cbaa2844-7054-4e8a-8d92-9706a6a49cef
# ╟─39044a6f-c1e4-48a9-988a-50a8194d0224
# ╠═15439e8c-e40a-44fe-a881-f54eafcef952
# ╟─e9629629-7870-4b7a-a457-cc4890245d99
# ╠═4d375940-79b4-4764-8d06-10982b37c809
# ╟─62b0759b-d78d-4e03-95fc-0d87e7935857
# ╠═2c9baa7f-1949-4ba7-bbf0-33ea49877b19
# ╟─b48e97b0-8e8e-4710-87fe-7e3a7bee007d
# ╠═0618b8ae-17fd-432c-a84b-d079c9038658
# ╟─1948458d-31ba-46d2-915b-b3aba9dabf61
# ╟─3cfd5406-a4e3-4ecf-86ea-e30e67e18bf2
# ╠═48d4e255-df17-40ab-9edb-a8a770a116bb
# ╟─f3822529-62fa-4275-bd0e-ea410b22fa59
# ╠═619b64b4-fe02-4954-a02e-d7f8d979546d
# ╟─2e3cf549-0616-4809-ba38-73f7c6a94c34
# ╠═bde10148-2a5f-4597-8e81-f54d71f05728
# ╟─1b13dc19-adcb-493b-a571-aa2811f79398
# ╠═e11428ed-8814-417c-8746-6d98b14d28f8
# ╟─1734423f-9bf5-4d0e-b135-c550405f8783
# ╠═06e9ea84-bb8e-4c29-93d2-9e8db8fa7dd3
# ╟─c7939c4f-c446-4099-8f3b-9ab3f410129f
# ╠═aded4bdf-3511-49ee-9072-3f6f7f55e8a9
# ╟─7da41643-f486-4e2f-9ee2-06af0d7395d4
# ╠═2ec1a630-cde0-4d8f-b9b5-170fa1d122c6
# ╟─14a44aba-00c1-4b0a-abfd-cfd04147d2e2
# ╠═029336a2-e4db-47f9-8fff-6d751bcf4c4d
# ╟─b54e32a0-b0b7-4fae-826d-2c61cf85dcc1
# ╠═53fcf13c-c5d1-425e-bc1a-241aaea7f9c5
# ╟─51f6bf67-bec3-4233-a204-3d1919367fed
# ╠═bc29b8ce-4d25-4faa-b53a-17d2c8f81705
# ╟─0c2ed5dd-1085-4ee7-8969-2961b319978d
# ╠═940ee3ff-0e76-4806-8345-d3acd351fbff
# ╟─22a4c491-37f0-4e10-82e1-a9512ab1ef17
# ╠═edd772bd-1152-4aca-ac19-58df089fae40
# ╠═4ec97f31-089e-4e89-bdd3-d8f03892ad31
# ╟─23bebd3d-c744-44ad-b01d-bff674a36b07
# ╠═754a4149-8d0e-40bf-9f9e-a18b193dfe71
# ╟─a3092e77-6888-4d58-aca1-37944a4896fb
# ╠═10476ffe-2b37-4e15-9ef8-543c5c146e77
# ╟─c1c15ecc-1f72-402c-bcc5-d1adc4814f38
# ╟─791fb1ff-6fce-4023-9908-c254513da7eb
# ╠═635ec2cd-a3b3-4629-ac6d-9fc4853a3749
# ╟─b02bfcc7-5d37-405c-8862-493b9c28fc38
# ╠═4dda961e-a2ff-403f-9087-48254dac1d77
# ╟─2409c827-9d9d-44b4-91fb-a1516dcdc632
# ╠═7c5fb45c-a687-4ed2-8c5f-e93f1d48fac7
# ╟─b3607a9a-2472-4e15-8e90-d2da6675949f
# ╠═a5bc399a-3f49-4e17-a136-df02f5bd7e4a
# ╟─eeba065c-942e-46f0-a3eb-d89e90bc514a
# ╠═afe53e77-d73b-439f-8746-dc27c399dc59
# ╟─ae34a53f-da42-42ac-b283-eefa09f3c86d
# ╠═e2f76f80-4f4a-4304-ad6f-fea7b4042019
# ╟─cdfc3aeb-169d-438f-8482-a78282b6c674
# ╠═54fb1116-4887-4690-8c14-e70e206ce033
# ╟─539d14a0-627e-482a-91c7-27df784ca323
# ╠═09f7e727-c45a-424c-8a12-62c952a85814
# ╟─758a6437-156f-4b95-b522-341950203175
# ╠═66cc97b4-77f7-4cb3-8c7d-fc58990e6cc3
# ╟─7ae4956c-b5e0-41fa-8b34-2e71e3cfd6f5
# ╠═2f902640-65c2-4e97-8cca-ebc58c3bd5b5
# ╟─417dd70f-6895-4117-b7d5-8a3159a2c1fc
# ╠═08c95754-1919-48d5-9610-5e9667864d91
# ╟─f6938470-42a8-471d-99a2-fe22d81aefa7
# ╠═1362c5e8-a8df-4daa-ae02-3b9c3e779e80
# ╟─1209bcc5-1fc4-4c31-8031-836c191f2e15
# ╠═e77886fa-4145-402e-8674-ec0146608073
# ╟─a58f3563-ec5d-459d-89ea-892a964d53a6
# ╠═21a191f5-4b90-48e3-ab46-57352552040b
# ╟─b8725478-19c6-4c62-9c8f-274cf768bfc9
# ╠═575922c3-2007-45ad-9ced-a68f7c56f789
# ╟─6ca08891-0490-489c-8d8c-0dcccd399794
# ╠═f2b86512-40a3-4f99-a0c3-937cfe684a14
# ╟─14daec81-e47e-43d7-9a5c-1f5ed5844eee
# ╠═c5615313-31ac-4993-8e88-987b4b6e0851
# ╟─a239a50b-db01-4342-9c8d-821e63290a7a
# ╠═ade1768e-c5ee-4cd5-ad9f-19948265b9c3
# ╟─9ae6b1ec-b446-4652-a1e1-f9629c47f1c3
# ╠═c39c4144-de4a-407d-beda-2f481bdc8f49
# ╟─295d30f4-4a03-45d5-8dec-86d836da13ae
# ╠═263833e1-3105-4c56-a3dc-30ae6934e1f8
# ╟─877ccfff-de5d-46d5-aff8-0bd71d14e996
# ╠═d7b126b1-f5b6-4e38-a40e-2d6918fda741
# ╟─2bd1f2be-9318-44e8-9791-c8d1451b4522
# ╠═35405245-31b4-400b-9c42-b957f606188c
# ╟─57e60f44-342a-4023-8011-cfc425908744
# ╟─8237e174-f6ee-4b4a-9928-dfe7b239b467
