using Parameters, UUIDs, JSON

include("./Component.jl");

JSON.lower(x::UUID) = string(x)

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

    return ParsedJSXTree(
        jsx_tree = jsx_tree,
        update_rules = update_rules
    )
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

    return ParsedJSXTree(
        jsx_tree = jsx_tree,
        update_rules = update_rules
    )
end

@with_kw struct ParsedJSXTree
    jsx_tree::JSXElement
    update_rules::Vector{UpdateRule}
end

function parse_tree(x::StaticComponent)
    local update_rules::Vector{UpdateRule} = []

    if !isnothing(x.children)
        local children::Vector{JSXElement} = []

        for i in x.children
            local parsed_tree = parse_tree(i)

            append!(update_rules, parsed_tree.update_rules)
            append!(children, [parsed_tree.jsx_tree])
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

    return ParsedJSXTree(
        jsx_tree = jsx_tree,
        update_rules = update_rules
    )
end

@with_kw struct MattApp
    hash::UUID = uuid4()
    jsx_tree::JSXElement
    update_rules::Vector{UpdateRule}
    input_bind::Dict{UUID, Vector{UUID}}
    bind_output::Dict{UUID, Vector{UUID}}
end

function setup_app(x::ParsedJSXTree)
    setup_app(x.jsx_tree, x.update_rules)
end

function setup_app(x::StaticComponent)
    setup_app(parse_tree(x))
end

function setup_app(
    jsx_tree::JSXElement,
    update_rules::Vector{UpdateRule})

    # Input -> Bind
    local input_bind = Dict{UUID, Vector{UUID}}()

    # Bind -> Output
    local bind_output = Dict{UUID, Vector{UUID}}()

    for rule in update_rules
        if haskey(bind_output, rule.bind)
            append!(bind_output[rule.bind], [rule.output])
        else
            bind_output[rule.bind] = [rule.output]
        end

        for input_hash in rule.input
            if haskey(input_bind, input_hash)
                append!(input_bind[input_hash], [rule.bind])
            else
                input_bind[input_hash] = [rule.bind]
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
