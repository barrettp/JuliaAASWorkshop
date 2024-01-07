### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ 947ccfa4-57be-4753-b9fa-c101fb52ee1b
using PlutoUI; TableOfContents()

# ╔═╡ 5ddccdea-fb04-11ed-343e-4753618b2032
md"""
## Using the ModelingTookKit

### Component-Based Modeling

In this tutorial, we will build a hierarchical acausal component-based model of the RC circuit. The RC circuit is a simple example where we connect a resistor and a capacitor. Kirchhoff's laws are then applied to state equalities between currents and voltages. This specifies a differential-algebraic equation (DAE) system, where the algebraic equations are given by the constraints and equalities between different component variables. We then simplify this to an ODE by eliminating the equalities before solving. Let's see this in action.

First install the packages: ModelingToolkit, Plots, and DifferentialEquations.
"""

# ╔═╡ ac2dfe85-12b6-422d-95fc-6593241746b5


# ╔═╡ bcc0bbb5-3be6-4420-90d3-31e19321469e
md"""
Create the time variable to be used by the circuit.

The '@' character prefix means that 'variables' and 'connector' are macros, which are like functions. Macros are code generators. They make programming easier and faster.

    @variables t
"""

# ╔═╡ 0f11bce2-2d07-42c1-8b17-d6962713ab12


# ╔═╡ a383f6b4-8d9b-4e23-92f5-1efbb1f66495
md"""
First, lets make each component of the circuit, starting with the 'Pin'. At each input and output pin, a component has two values: the current and the voltage. The Pin item will be used to store these values. When two Pins in a circuit are connected together, they satisfy Kirchhoff's laws, i.e., the currents sum to zero and the voltages are equal. `[connect = Flow]` informs the model that this is the case.

Note that each component has a `name` keyword argument. This allows us to name each instance of the same component. For example,

    Pin(name = :mypin1)

or equivalently, using the @named macro:

    @named mypin1 = Pin()

Create the Pin function.

    @connector function Pin(; name)
        sts = @variables v(t)=1.0 i(t)=1.0 [connect = Flow]
        ODESystem(Equation[], t, sts, []; name = name)
    end
"""

# ╔═╡ 2bcbe707-b382-428e-9c07-f0024e844174


# ╔═╡ 40df2af5-cfb1-4700-9aa2-2bd544566465
md"""
A simple abstract component with two pins is called a 'OnePort`. The equations specify that: (1) the voltage difference between the positive pin and negative pin is the voltage difference of the component, (2) the current between the two pins must sum to zero, and (3) the current of the component is that of the positive pin.

Note that constants and parameters use the `=` character, while equations use the `~` character, which means equivalent.

!!! info

    Julia provides two types of inheritance: *type* inheritance and *method* inheritance. `OnePort` is an example of method inheritance.
"""

# ╔═╡ 53fb1346-06ed-4258-ad41-79597f544dad
md"""

    @component function OnePort(; name)
        @named p = Pin()
        @named n = Pin()
        sts = @variables v(t)=1.0 i(t)=1.0
        eqs = [v ~ p.v - n.v
               0 ~ p.i + n.i
               i ~ p.i]
        compose(ODESystem(eqs, t, sts, []; name = name), p, n)
    end
"""

# ╔═╡ 600ed835-f3f8-4a77-a5a8-65d2fd559b1a


# ╔═╡ f455c062-aa6a-410f-a3ce-bc6059b1784b
md"""
The first actual component is the Source, which generates a current and has a constant voltage. It can be thought of as an OnePort component where the voltage is kept constant.

Note that we have provided the component with a default parameter for the source's voltage. It will be use if we don't provide a value. Also, note the use of `@unpack` and `extend`. `@unpack` means that we only want to use `OnePort`'s equations and states and `extend` means that we want to extend the system of equations. 

    @component function Source(; name, V = 1.0)
        @named oneport = OnePort()
        @unpack v = oneport
        ps = @parameters V = V
        eqs = [
            V ~ v,
        ]
        extend(ODESystem(eqs, t, [], ps; name = name), oneport)
    end
"""

# ╔═╡ b5745288-0382-4871-921c-507ec1f3d4a5


# ╔═╡ 5692148c-d0f9-454b-9fc4-eff8c3844c1a
md"""
The second component is the Resistor. It has OnePort where the voltage obeys Ohm's law: `V = I*R`.

    @component function Resistor(; name, R = 1.0)
        @named oneport = OnePort()
        @unpack v, i = oneport
        ps = @parameters R = R
        eqs = [
           v ~ i * R,
        ]
        extend(ODESystem(eqs, t, [], ps; name = name), oneport)
    end
"""

# ╔═╡ 9ad61fc6-e82a-4672-9d10-83fd6aa34825


# ╔═╡ 915242bd-b732-4a8f-bb00-86bf4cfcdb9e
md"""
The third component is the Capacitor. The derivative of the voltage is equivalent to current divided by the capacitance.

    @component function Capacitor(; name, C = 1.0)
        @named oneport = OnePort()
        @unpack v, i = oneport
        ps = @parameters C = C
        D = Differential(t)
        eqs = [
            D(v) ~ i / C,
        ]
        extend(ODESystem(eqs, t, [], ps; name = name), oneport)
    end
"""

# ╔═╡ dca6102d-2490-461c-9075-ff53c6263aa8


# ╔═╡ 92a5e7aa-1c4a-4069-b15a-d4ccfd76c915
md"""
The final component is the ground, where the voltage must be zero.

    @component function Ground(; name)
        @named g = Pin()
        eqs = [g.v ~ 0]
        compose(ODESystem(eqs, t, [], []; name = name), g)
    end
"""

# ╔═╡ 3b4b7e7e-de79-4ffa-9da2-68f39108bf37


# ╔═╡ 09d464a2-a97a-46d5-a57c-95fec659d38b
md"""
Now that we have all of the componets, let's create the circuit.

First, initialize the value of each component to 1 .

    R, C, V = 1.0, 1.0, 1.0
"""

# ╔═╡ 05c045d6-d04a-47fa-b9c2-677eacc21d08


# ╔═╡ 0a72fb7d-7a33-45bc-8bc8-41ef47f7eb05
md"""
Instantiate each component, i.e., the source, ground, resistor, and capacitor.

    @named source = Source(V = V)
"""

# ╔═╡ 83afd0e6-8af3-4505-818b-499d806b8506


# ╔═╡ 5a18a5de-a0f1-4b11-9e78-e8b356288b74
md"""
    @named resistor = Resistor(R = R)
"""

# ╔═╡ 1ef2fb6d-868d-44c2-ab60-d3ea2f102067


# ╔═╡ 7dca1470-ac07-416c-92b2-8004f47bfaff
md"""
    @named capacitor = Capacitor(C = C)
"""

# ╔═╡ 810a0f94-1453-4403-9858-72973f3ecdab


# ╔═╡ 981f3ffd-e398-4a2d-90d8-e56bd6868a27
md"""
    @named ground = Ground()
"""

# ╔═╡ 14637c4d-1ff6-429d-8479-8d930171152e


# ╔═╡ d268ffed-2a78-46f4-9ccb-1eac1b6fbbd5
md"""
Now that all components are instantiated, we can connect them together to form a simple RC circuit. Connect the positive pin of the source to the positive pin of the resistor, the negative pin of the resistor to the positive pin of the capacitor, etc.

    rc_eqs = [connect(source.p, resistor.p)
          connect(resistor.n, capacitor.p)
          connect(capacitor.n, source.n)
          connect(capacitor.n, ground.g)]
"""

# ╔═╡ 48e8416d-188d-4de0-a9a5-343a7780f53b


# ╔═╡ 7a8a77f3-2d65-4d93-a077-6f209443bf45
md"""
An RC circuit is an ordinary differential equation (ODE). So we can solve it using an ODE system.

    @named _rc_model = ODESystem(rc_eqs, t)
"""

# ╔═╡ 5c02aaa4-b7d7-4e8a-ab00-b0761f9b8bfa


# ╔═╡ 669cc83c-9a31-4932-bfbe-e227e16c1859
md"""
    @named rc_model = compose(_rc_model, [resistor, capacitor, source, ground])
"""

# ╔═╡ c9af7b2c-1bac-49d7-93be-4eedc3c40adf


# ╔═╡ 9d97a09a-80ef-4a6f-91bf-81308c532acb
md"""
Note that this model has no causal attributes, so it is acausal. The set of equations forms a system of differential-algebraic equations (DAEs) that define the evolution of each state of the system. The states are:

    states(rc_model)
"""

# ╔═╡ a8c3e1b6-0e31-4192-a75e-bb15d643d5e1


# ╔═╡ 028008d8-933a-4dc4-8644-49001c6e6df8
md"""
and the parameters are:

    parameters(rc_model)
"""

# ╔═╡ 9b9c8efb-0149-4d96-9cf6-e458a8f5124f


# ╔═╡ 16bf314b-938b-4bd3-9b4a-06b98774a3c7
md"""
The system can be solved directly as a DAE using one of the DAE solvers from `DifferentialEquations.jl`. However, it is possible to simplify the system by using `structural_simplify` to eliminate many unnecessary states. 

    sys = structural_simplify(rc_model)
"""

# ╔═╡ d04fb8e1-3e04-4254-a6d2-5d4e6fae462a
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ d24e7f9e-a870-4691-844e-487a174313d1
md"""
The structural simplification reduces two equations and a single state. One equation is a differential equation and the other is an algebraic equation.

    states(sys)
"""

# ╔═╡ ed1c1aff-1242-4d8b-9d12-2c507700a999


# ╔═╡ ef9b5a04-00f3-4b69-8b99-e9e630b5d91b
md"""
We can set the initial conditions of the state and solve the system by converting it to an `ODEProblem` in mass matrix form using a DAE solver.

Set the initialize capacitor voltage to zero.

    u0 = [capacitor.v => 0.0,
          capacitor.i => 0.0]
"""

# ╔═╡ d2928701-a74e-4990-9889-d4838b77685c
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ 957ec863-f8d2-4a66-9d8d-47b71f602c85
md"""
    prob = ODAEProblem(sys, u0, (0, 10.0))
"""

# ╔═╡ bd6ac8f6-c3ce-4d24-a45b-14c68f69dfe5


# ╔═╡ 20db2aec-57e9-408c-8cc7-e383db22e820
md"""
Finally, solve the problem.

    sol = solve(prob, Rodas4())
"""

# ╔═╡ aa487e9c-7230-478a-a4c6-ea9d477dd0d9


# ╔═╡ 61c45a48-cb63-4f59-9ade-e1122917b8ba
md"""
Plot the solution.

    plot(sol)
"""

# ╔═╡ 1c1705ee-1e0e-48ad-8477-7ae8903a2b67


# ╔═╡ e3203d6e-3980-4ed1-924f-413d6648006a
md"""
    plot(sol, idxs=[resistor.v])
"""

# ╔═╡ 836e5ca2-3e32-4af0-8bab-e1ebbbf08672


# ╔═╡ c7d139b4-2885-483a-a3e0-625b0a37dba5
md"""
###  RLC Circuit

Let's create an RLC circuit by adding an inductor. The derivative of the current is the voltage divided by the inductance (L)

    function Inductor(; name, L=1.0)
        @named oneport = OnePort()
        @unpack v, i = oneport
        ps = @parameters L = L
        D = Differential(t)
        eqs = [
            D(i) ~ v / L
        ]
        extend(ODESystem(eqs, t, [], ps; name=name), oneport)
    end
"""

# ╔═╡ 75936cb3-50b6-4c65-996f-cab1baabdad6


# ╔═╡ 34849d6c-ad99-4dfe-b9c3-6c1b60a83990
md"""
    L = 1.0
"""

# ╔═╡ d0d1b702-2d8b-4235-b17c-e8c7c0619c8e


# ╔═╡ 088957b7-1c4e-4d78-a757-a2cc724ddd77
md"""
    @named inductor = Inductor(L = L)
"""

# ╔═╡ 4952862e-1d7b-4f0c-a7e9-6736581f9eaa


# ╔═╡ d8dcf6b6-96f0-4271-b546-831b064eee63
md"""
Now insert the inductor into the system and reconnect the pins.

    rlc_eqs = [connect(source.p, resistor.p)
               connect(resistor.n, inductor.p)
               connect(inductor.n, capacitor.p)
               connect(capacitor.n, source.n)
               connect(capacitor.n, ground.g)]
"""

# ╔═╡ 22fc1e2c-059b-4d6b-9d64-c2d8bbdd2fd5


# ╔═╡ 7fad9c86-6d6a-4dd2-a8cd-62ba6ae5cc3c
md"""
The RLC circuit is also an ordinary differential equation (ODE). So we can also solve it using an ODE system.

    @named _rlc_model = ODESystem(rlc_eqs, t)
"""

# ╔═╡ d0da5f10-7528-491e-8729-6355d4a54c14


# ╔═╡ 6a05cf51-a67f-4816-8c16-03e902cacf87
md"""
    @named rlc_model = compose(_rlc_model,
							[resistor, inductor, capacitor, source, ground])
"""

# ╔═╡ 83145b29-1cfd-4dc4-b09b-b4110fdb8fa4


# ╔═╡ 08d7d7d1-c87c-4c87-9d30-1859725f544c
md"""
Let's again simplify the equations.

    sys2 = structural_simplify(rlc_model)
"""

# ╔═╡ ecee156b-5b1f-41a3-a63a-4be3ab1c2c6e


# ╔═╡ fc990bcc-5cbb-4f73-84a6-4fc90699b3cc
md"""
Set the initialize capacitor voltage to zero.

    u02 = [capacitor.v => 0.0,
          capacitor.i => 0.0]
"""

# ╔═╡ 0d48fd98-1c18-4666-9b1f-919272d9322c


# ╔═╡ 91dd04a0-0d12-4864-bb0f-1796b55c99c0
md"""
    prob2 = ODAEProblem(sys2, u02, (0, 10.0))
"""

# ╔═╡ a9865b99-8dd0-4c2c-822d-2c0d8eda03da


# ╔═╡ fdc2c4cb-c2aa-4d66-ab0e-58cca4ae3488
md"""
    sol2 = solve(prob, Rodas4())
"""

# ╔═╡ 597d293f-cc7a-4ce3-8c6a-ca531f1054bb


# ╔═╡ e36cc66b-c393-47d7-ad18-dbc303dfd129
md"""
    plot(sol2)
"""

# ╔═╡ dda2f863-5fad-410a-b3ac-995691abc0a7


# ╔═╡ b52b22ae-0943-451a-b602-2b3ff8de53ae
md"""
!!! note

    What have we learned?

    * Julia has type and method inheritance.
    * Julia does symbolic manipulation. And it is very good at it.
    * Julia can compile the symbolic code to numerical code and execute it.
"""

# ╔═╡ Cell order:
# ╟─947ccfa4-57be-4753-b9fa-c101fb52ee1b
# ╟─5ddccdea-fb04-11ed-343e-4753618b2032
# ╠═ac2dfe85-12b6-422d-95fc-6593241746b5
# ╟─bcc0bbb5-3be6-4420-90d3-31e19321469e
# ╠═0f11bce2-2d07-42c1-8b17-d6962713ab12
# ╟─a383f6b4-8d9b-4e23-92f5-1efbb1f66495
# ╠═2bcbe707-b382-428e-9c07-f0024e844174
# ╟─40df2af5-cfb1-4700-9aa2-2bd544566465
# ╟─53fb1346-06ed-4258-ad41-79597f544dad
# ╠═600ed835-f3f8-4a77-a5a8-65d2fd559b1a
# ╟─f455c062-aa6a-410f-a3ce-bc6059b1784b
# ╠═b5745288-0382-4871-921c-507ec1f3d4a5
# ╟─5692148c-d0f9-454b-9fc4-eff8c3844c1a
# ╠═9ad61fc6-e82a-4672-9d10-83fd6aa34825
# ╟─915242bd-b732-4a8f-bb00-86bf4cfcdb9e
# ╠═dca6102d-2490-461c-9075-ff53c6263aa8
# ╟─92a5e7aa-1c4a-4069-b15a-d4ccfd76c915
# ╠═3b4b7e7e-de79-4ffa-9da2-68f39108bf37
# ╟─09d464a2-a97a-46d5-a57c-95fec659d38b
# ╠═05c045d6-d04a-47fa-b9c2-677eacc21d08
# ╟─0a72fb7d-7a33-45bc-8bc8-41ef47f7eb05
# ╠═83afd0e6-8af3-4505-818b-499d806b8506
# ╟─5a18a5de-a0f1-4b11-9e78-e8b356288b74
# ╠═1ef2fb6d-868d-44c2-ab60-d3ea2f102067
# ╟─7dca1470-ac07-416c-92b2-8004f47bfaff
# ╠═810a0f94-1453-4403-9858-72973f3ecdab
# ╟─981f3ffd-e398-4a2d-90d8-e56bd6868a27
# ╠═14637c4d-1ff6-429d-8479-8d930171152e
# ╟─d268ffed-2a78-46f4-9ccb-1eac1b6fbbd5
# ╠═48e8416d-188d-4de0-a9a5-343a7780f53b
# ╟─7a8a77f3-2d65-4d93-a077-6f209443bf45
# ╠═5c02aaa4-b7d7-4e8a-ab00-b0761f9b8bfa
# ╟─669cc83c-9a31-4932-bfbe-e227e16c1859
# ╠═c9af7b2c-1bac-49d7-93be-4eedc3c40adf
# ╟─9d97a09a-80ef-4a6f-91bf-81308c532acb
# ╠═a8c3e1b6-0e31-4192-a75e-bb15d643d5e1
# ╟─028008d8-933a-4dc4-8644-49001c6e6df8
# ╠═9b9c8efb-0149-4d96-9cf6-e458a8f5124f
# ╟─16bf314b-938b-4bd3-9b4a-06b98774a3c7
# ╠═d04fb8e1-3e04-4254-a6d2-5d4e6fae462a
# ╟─d24e7f9e-a870-4691-844e-487a174313d1
# ╠═ed1c1aff-1242-4d8b-9d12-2c507700a999
# ╟─ef9b5a04-00f3-4b69-8b99-e9e630b5d91b
# ╠═d2928701-a74e-4990-9889-d4838b77685c
# ╟─957ec863-f8d2-4a66-9d8d-47b71f602c85
# ╠═bd6ac8f6-c3ce-4d24-a45b-14c68f69dfe5
# ╟─20db2aec-57e9-408c-8cc7-e383db22e820
# ╠═aa487e9c-7230-478a-a4c6-ea9d477dd0d9
# ╟─61c45a48-cb63-4f59-9ade-e1122917b8ba
# ╠═1c1705ee-1e0e-48ad-8477-7ae8903a2b67
# ╟─e3203d6e-3980-4ed1-924f-413d6648006a
# ╠═836e5ca2-3e32-4af0-8bab-e1ebbbf08672
# ╟─c7d139b4-2885-483a-a3e0-625b0a37dba5
# ╠═75936cb3-50b6-4c65-996f-cab1baabdad6
# ╟─34849d6c-ad99-4dfe-b9c3-6c1b60a83990
# ╠═d0d1b702-2d8b-4235-b17c-e8c7c0619c8e
# ╟─088957b7-1c4e-4d78-a757-a2cc724ddd77
# ╠═4952862e-1d7b-4f0c-a7e9-6736581f9eaa
# ╟─d8dcf6b6-96f0-4271-b546-831b064eee63
# ╠═22fc1e2c-059b-4d6b-9d64-c2d8bbdd2fd5
# ╟─7fad9c86-6d6a-4dd2-a8cd-62ba6ae5cc3c
# ╠═d0da5f10-7528-491e-8729-6355d4a54c14
# ╟─6a05cf51-a67f-4816-8c16-03e902cacf87
# ╠═83145b29-1cfd-4dc4-b09b-b4110fdb8fa4
# ╟─08d7d7d1-c87c-4c87-9d30-1859725f544c
# ╠═ecee156b-5b1f-41a3-a63a-4be3ab1c2c6e
# ╟─fc990bcc-5cbb-4f73-84a6-4fc90699b3cc
# ╠═0d48fd98-1c18-4666-9b1f-919272d9322c
# ╟─91dd04a0-0d12-4864-bb0f-1796b55c99c0
# ╠═a9865b99-8dd0-4c2c-822d-2c0d8eda03da
# ╟─fdc2c4cb-c2aa-4d66-ab0e-58cca4ae3488
# ╠═597d293f-cc7a-4ce3-8c6a-ca531f1054bb
# ╟─e36cc66b-c393-47d7-ad18-dbc303dfd129
# ╠═dda2f863-5fad-410a-b3ac-995691abc0a7
# ╟─b52b22ae-0943-451a-b602-2b3ff8de53ae
