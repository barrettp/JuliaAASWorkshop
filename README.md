# Julia AAS Workshop

[**Jump to installation instructions**](#installation-instructions)

[**Jump to workshop contents**](#workshop-contents)

This repository contains material for the AAS Workshop "An Introduction to the Julia Programming Language"

Date: **Sunday, January 7, 2024, 9:00 am - 5:00 pm (hybrid)**

The Julia programming language can be considered the successor to Scientific Python (SciPy). The language is designed for scientific computing by having built-in multidimensional arrays and parallel processing features. Yet, it can also be used as a general-purpose programming language like Python. Unlike Python, Julia solves the two-language problem by using just-in-time (JIT) compilation to generate machine code from high level expressions. In most cases, Julia is as fast as C, and in some cases faster. Julia is also a composable language, so independent libraries or packages usually work well together without any modification. These important features make Julia a very productive language for scientific software development by significantly reducing the number of lines of code. In essence, Julia is Python with Numba built-in. 

The objectives of this tutorial are: (1) to introduce astronomers and software developers to the basic language syntax, features, and power of the Julia programming language, (2) to compare and contrast Julia’s design features to those of C/C++ and Python, and (3) to show that Julia provides an easy migration path from languages such as C/C++, FORTRAN, and Python. In other words, it is not necessary to rewrite all of your code all at once.

The workshop is divided into morning and afternoon sessions. The morning session contains three one hour tutorials, while the afternoon session contains six half hour tutorials. The morning tutorials will introduce a few features of the language, such as unicode characters, multi-dimensional arrays, and functions, while using various Julia packages to perform simple data analysis using multiwavelength data. The afternoon tutorials will introduce a few language concepts, such as composability, multiple dispatch, and macros, while cover some advanced programming techniques, such as calling Python, using macros, optimizing code, creating packges, and parallel computation.

## Installation Instructions

We will be using Julia and Pluto notebooks to make the installation process as easy and painless as possible. Please follow these installation instructions before the start of the workshop. If you run into to difficulties, please feel free to contact the organizers or let us know at the start of the workshop.

Note: Pluto notebooks are not compatible with Jupyter.

### Installing Julia
Please [install the latest stable version of Julia](https://julialang.org/downloads/) (1.9.4 as of Dec, 2023) on you computer. Make sure to use the links on the official Julia website linked above, rather than any 3rd party package manager (e.g. homebrew, apt, nuget, etc.).

For more advanced users, [JuliaUp](https://github.com/JuliaLang/juliaup) can be used to install, update, and switch between versions of Julia. 

<details>
<summary>MacOS Instructions</summary>
If you have a new mac with an M1 processor, make sure to select the "M-series Processor" link for improved performance.
</details>

<details>
<summary>Windows Instructions</summary>
This <a href="https://www.microsoft.com/store/apps/9NJNWW8PVKMN">Microsoft Store</a> link can also be used to install JuliaUp.

We strongly recomend you use the Windows Terminal included in Windows 11 or downloadable from this <a href="https://aka.ms/terminal">Microsoft Store link</a>. Windows Terminal has improved font and math symbol rendering compared to the antiquated `cmd.exe`.
</details>

<details>
<summary>Linux Instructions</summary>
After downloading the correct version of Julia for your operating system, expand the archive (e.g. <code>tar -xvf julia-xyz.tar.gz</code>) and place the binary <code>julia-xyz/bin/julia</code> in your <code>PATH</code>.

The versions of Julia included in OS package managers (yum, apt, pacman, etc) frequently have bugs not seen in the offical binaries and should be avoided. For more information, <a href="https://julialang.org/downloads/platform/#a_brief_note_about_unofficial_binaries">see here</a>.
</details>

<details>
<summary>Docker</summary>
Julia runs in lightweight, self-contained environments. It is therefore not usually necessary to install Julia within Docker for the sake of reproducibility.
</details>

Once you have installed Julia, run the following command in your terminal to install Pluto:
```bash
julia -e 'using Pkg; Pkg.add("Pluto")'
```

Set the desired number of threads Julia should run with using an environment variable:

**Windows:**
```cmd
SET JULIA_NUM_THREADS=auto
```
**Mac & Linux:**
```bash
export JULIA_NUM_THREADS=auto
```


Then, in the same terminal, start Julia by running:
```bash
julia
```

To start Pluto, run the following from inside Julia:
```julia-repl
julia> using Pluto
julia> Pluto.run()
```

### Note on Python
In one section, we will demonstrate how you can use Python libraries inside Julia. You do not have to have a Python installed in advance.

## Workshop Contents

The material for each section is stored as a [Pluto notebook](https://plutojl.org/). 

Copy the link for a given section below and paste it into the "Open a Notebook" box in Pluto.

The morning content is notebooks 1-3, while the afternoon is notebooks 4-9.

| Topic | Link | 
|-------|------|
| 01. Introducing Julia | https://github.com/barrettp/JuliaAASWorkshop/raw/main/01-intro-to-julia.jl |
| 02. Modeling an LC Circuit | https://github.com/barrettp/JuliaAASWorkshop/raw/main/02-doing-modeling.jl |
| 03. Statistics of SNRs | https://github.com/barrettp/JuliaAASWorkshop/raw/main/03-doing-statistics.jl |
| 04. Calling Python | https://github.com/barrettp/JuliaAASWorkshop/raw/main/04-calling-python.jl |
| 05. Using Macros | https://github.com/barrettp/JuliaAASWorkshop/raw/main/05-using-macros.jl |
| 06. Astronomy Packages | https://github.com/barrettp/JuliaAASWorkshop/raw/main/06-astro-packages.jl |
| 07. Optimizing Code | https://github.com/barrettp/JuliaAASWorkshop/raw/main/07-optimizing-code.jl |
| 08. Parallel Computing | https://github.com/barrettp/JuliaAASWorkshop/raw/main/08-parallel-computing.jl |
| 09. Creating Packages | https://github.com/barrettp/JuliaAASWorkshop/raw/main/09-creating-packages.jl | 
| 10. Questions and Special Topics | |
