using Parameters, UUIDs

include("./Component.jl");

@with_kw struct JSXElement
    hash::UUID = uuid4()
    tag::String = "div"
    props::Union{Dict{String, Any}, Nothing} = nothing
    children::Union{Vector{JSXElement}, Nothing} = nothing
end

# BindSet -> Input
@with_kw struct UpdateRule
    # Should be the hash of `BindSet`
    bind::UUID = uuid4()
    input::Vector{UUID}
    output::UUID
end

function parse_tree(x::InputComponent)
    local update_rules::Vector{UpdateRule} = []

    local jsx_tree = JSXElement(
        hash = x.hash,
        tag = x.component,
        props = x.parameters,
        children = nothing
    )

    return (jsx_tree, update_rules)
end

function parse_tree(x::OutputComponent)
    local update_rules::Vector{UpdateRule} = []

    local jsx_tree = JSXElement(
        hash = x.hash,
        tag = x.component,
        props = x.parameters,
        children = nothing
    )

    local inputs::Vector{UUID} = []

    for bind in x.callback.bind_set.binds
        append!(inputs, [bind.component.hash])
    end

    append!(update_rules, [UpdateRule(
        bind = x.callback.bind_set.hash,
        input = inputs,
        output = x.hash
    )])

    return (jsx_tree, update_rules)
end

function parse_tree(x::StaticComponent)
    local update_rules::Vector{UpdateRule} = []

    if !isnothing(x.children)
        local children::Vector{JSXElement} = []

        for i in x.children
            (sub_jsx_tree, sub_update_rules) = parse_tree(i)

            append!(update_rules, sub_update_rules)
            append!(children, [sub_jsx_tree])
        end
    else
        local children = nothing
    end

    local jsx_tree = JSXElement(
        hash = x.hash,
        tag = x.component,
        props = x.parameters,
        children = children
    )

    return (jsx_tree, update_rules)
end

@with_kw struct MattApp
    hash::UUID = uuid4()
    jsx_tree::JSXElement
    update_rules::Vector{UpdateRule}
    input_bind::Dict{UUID, Vector{UUID}}
    bind_output::Dict{UUID, Vector{UUID}}
end

function setup_app(
    jsx_tree::JSXElement,
    update_rules::Vector{UpdateRule})

    # Input -> Bind
    local input_bind::Dict{UUID, Vector{UUID}} = Dict()

    # Bind -> Output
    local bind_output::Dict{UUID, Vector{UUID}} = Dict()

    for rule in update_rules
        if haskey(bind_output, rule.bind)
            append!(bind_output[rule.bind], [rule.output])
        else
            bind_output[rule.bind] = [rule.output]
        end

        for input_hash in rule.input
            if haskey(input_bind, input_hash)
                append!(input_hash[input_hash], [rule.bind])
            else
                input_hash[input_hash] = [rule.bind]
            end
        end

        MattApp(
            jsx_tree = jsx_tree,
            update_rules = update_rules,
            input_bind = input_bind,
            bind_output = bind_output
        )
    end
end
