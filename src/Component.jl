using Parameters, UUIDs

abstract type Component end

@with_kw struct InputComponent{T}
    hash::UUID = uuid4()
    component::String
    default::T
    parameters:: Union(Dict{String, Any}, Nothing)
end

abstract type InputComponent <: Component

@with_kw struct StaticComponent
    hash::UUID = uuid4()
    component::String
    parameters:: Union(Dict{String, Any}, Nothing)
    child::Vector{Component}
end

abstract type StaticComponent <: Component

@with_kw struct OutputCallback
    hash::UUID = uuid4()
    bind::Array{InputComponent}
    fn::Function
end

@with_kw struct UpdateScope
end

@with_kw struct OutputComponent{T}
    hash::UUID = uuid4()
    callback::OutputCallback
    parameters::Union(Dict{String, Any}, Nothing)
end

abstract type OutputComponent <: Component

macro output_fn(bind, block)
    local fn_block = [block]
    local para_types::Vector{String} = []

    for i in 1:length(bind.args)
        append!(para_types, [string(bind.args[i])])
    end

    return quote
        local bind = $(bind)
        local para_types = $(para_types)
        local call_paras::Vector{Expr} = [Expr(:(::), :__update_hash, UUID)]

        for i in 1:length(bind)
            local para_name = Symbol(para_types[i])
            local para_type = typeof(bind[i]).parameters[1]
            local var_def = Expr(:(::), para_name, para_type)

            append!(call_paras, [var_def])
        end

        local fn_paras = Expr(:tuple, Expr(:parameters, call_paras...))
        local fn_block = $(fn_block)
        local fn_expr = Expr(:function, fn_paras, fn_block[1])
        local fn = eval(fn_expr)

        OutputCallback(
            bind = $(bind),
            fn = fn
        )
    end
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
    OutputComponent(
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
