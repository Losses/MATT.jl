using Parameters, UUIDs

abstract type Component end

@with_kw struct InputComponent{T} <: Component
    hash::UUID = uuid4()
    component::String
    default::T
    parameters:: Union{Dict{String, Any}, Nothing}
end

@with_kw struct StaticComponent <: Component
    hash::UUID = uuid4()
    component::String
    parameters:: Union{Dict{String, Any}, Nothing}
    child::Vector{Component}
end

@with_kw struct Bind
    hash::UUID = uuid4()
    variable::String
    component::InputComponent
end

@with_kw struct BindSet
    hash::UUID = uuid4()
    binds::Array{Bind}
end

@with_kw struct OutputCallback
    hash::UUID = uuid4()
    binds::BindSet
    fn::Function
end

@with_kw struct UpdateScope
    hash::UUID = uuid4()
    binds::BindSet
end

@with_kw struct OutputComponent{T} <: Component
    hash::UUID = uuid4()
    callback::OutputCallback
    parameters::Union{Dict{String, Any}, Nothing}
end

macro bind_set(binds)
    if binds.head == :...
        local returned_bind = eval(binds.args[1])
        local returned_bind_type = typeof(returned_bind)

        if returned_bind_type !== BindSet
            throw(ArgumentError("`binsSet` expected, but " * string(returned_bind) * " given"))
        end

        return returned_bind
    end

    if binds.head !== :tuple
        throw(ArgumentError("binds should be tuple, " * string(binds.head) * " provided"))
    end

    local parsed_binds::Vector{Bind} = []

    for i in 1:length(binds.args)
        if typeof(binds.args[i]) == Expr
            if binds.args[i].head !== :...
                throw(ArgumentError("unknown syntax"))
            end

            local bind_set = eval(binds.args[i].args[1])

            if typeof(bind_set) != BindSet
                throw(ArgumentError("`BindSet` expected, but " * string(typeof(bind_set)) * " given"))
            end

            for bind in bind_set.binds
                append!(parsed_binds, [Bind(
                    variable = bind.variable,
                    component = bind.component
                )])
            end
        elseif typeof(binds.args[i]) == Symbol
            local bind_variable = string(binds.args[i])
            local bind_component = eval(binds.args[i])
            local component_type = typeof(bind_component)

            if !(component_type <: InputComponent)
                throw(ArgumentError(bind_variable * " is expected to be `InputComponent`, but " * string(component_type) * " given"))
            end

            append!(parsed_binds, [Bind(
                variable = bind_variable,
                component = bind_component
            )])
        else
            throw(ArgumentError("element of " * string(binds.args[i]) * " should be `Expr` or `Symbol`, " * string(typeof(binds.args[i])) * " provided"))
        end
    end

    return BindSet(
        binds = parsed_binds
    )
end

macro output_fn(definition, block)
    if definition.head !== :(::)
        throw(ArgumentError("bind definition must have two parts, concate with `::`"))
    end

    local binds = definition.args[1]
    local output_type = definition.args[2]

    local bind_set = eval(:(@bind_set $binds))

    local call_paras::Vector{Expr} = [Expr(:(::), :__update_hash, UUID)]

    for i in 1:length(bind_set.binds)
        local para_name = Symbol(bind_set.binds[i].variable)
        local para_type = typeof(bind_set.binds[i].component).parameters[1]
        local var_def = Expr(:(::), para_name, para_type)

        append!(call_paras, [var_def])
    end

    local fn_paras = Expr(
        :(::), Expr(
            :call, :__internal_output_callback, Expr(
                :parameters, call_paras...
            )
        ), Symbol(output_type))

        local fn_expr = Expr(:function, fn_paras, block)
        local fn = eval(fn_expr)

        print(fn_expr)

        OutputCallback(
            binds = bind_set,
            fn = fn
        )
end

function Toggle(
    label::String = "",
    default::Bool = false;
    inline_label::Bool = false,
    on_text::String = "On",
    off_text::String = "Off")
    InputComponent{Bool}(
        component = "Toggle",
        default = default,
        parameters = Dict(
            "label"       => label,
            "inlineLabel" => inline_label,
            "onText"      => on_text,
            "offText"     => off_text
        )
    )
end

@with_kw struct ChoiceOption
    key::String = ""
    option::String = ""
end

function Choice(
    label::String = "",
    default::String = "";
    options::Dict{String, String} = Dict("" => ""))
    @assert haskey(options, default) "default option is not in `options`"

    options_para::Vector{ChoiceOption} = []

    for (k, v) in options
        append!(options_para, [ChoiceOption(k, v)])
    end

    InputComponent{String}(
        component = "ChoiceGroup",
        default = default,
        parameters = Dict(
            "label"              => label,
            "options"            => options_para,
            "defaultSelectedKey" => default
        )
    )
end

function Slider(
    label::String = "",
    default::Float64 = 0.0;
    min::Float64 = 0.0,
    max::Float64 = 10.0,
    step::Float64 = 1.0,
    show_value::Bool = true,
    origin_from_zero::Bool = false,
    vertical::Bool = false)
    InputComponent{Float64}(
        component = "Slider",
        default = default,
        parameters = Dict(
            "min"            => min,
            "max"            => max,
            "step"           => step,
            "showValue"      => show_value,
            "originFromZero" => origin_from_zero,
            "vertical"       => vertical
        )
    )
end

function TextOutput(
    callback::OutputCallback;
    monospace::Bool = false)
    OutputComponent{String}(
        callback = callback,
        parameters = Dict(
            "monospace" => monospace
        )
    )
end

function SplitView(
    child::Vector{Component};
    widths::Vector{Int64})
    StaticComponent(
        component = "SplitView",
        parameters = Dict(
            "widths" => widths
        )
    )
end

function StackView(
    child::Vector{Component})
    StaticComponent(
        component = "StackView",
        parameters = nothing
    )
end
