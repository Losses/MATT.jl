using Parameters, UUIDs, JSON

JSON.lower(x::UUID) = string(x)

@with_kw struct JSXElement
    hash::UUID = uuid4()
    tag::String = "div"
    props::Union{Dict{String, Any}, Nothing} = nothing
    children::Union{Vector{JSXElement}, Nothing} = nothing
    data_type::Union{DataType, Nothing} = nothing
    component_type::String # Input? Output? Static?
end

# BindSet -> Input
@with_kw struct UpdateRule
    # Should be the hash of `BindSet`
    bind_set::UUID = uuid4()
    input::Vector{UUID}
    output::UUID
end

function parse_tree(x::InputComponent)
    local update_rules = Vector{UpdateRule}()
    local components = Vector{Component}()

    local props = isnothing(x.parameters) ? x.parameters : Dict{String, Any}()

    if !isnothing(x.default)
        props["value"] = x.default
    end

    append!(components, [x])

    local jsx_tree = JSXElement(
        hash = x.hash,
        tag = x.component,
        props = props,
        children = nothing,
        component_type = "input",
        data_type = typeof(x).parameters[1]
    )

    return ParsedJSXTree(
        jsx_tree = jsx_tree,
        update_rules = update_rules,
        components = components
    )
end

function parse_tree(x::OutputComponent)
    local update_rules = Vector{UpdateRule}()
    local components = Vector{Component}()

    append!(components, [x])

    local jsx_tree = JSXElement(
        hash = x.hash,
        tag = x.component,
        props = x.parameters,
        children = nothing,
        component_type = "output",
        data_type = typeof(x).parameters[1]
    )

    local inputs = Vector{UUID}()

    for bind in x.callback.bind_set.binds
        append!(inputs, [bind.component.hash])
    end

    append!(update_rules, [UpdateRule(
        bind_set = x.callback.bind_set.hash,
        input = inputs,
        output = x.hash
    )])

    return ParsedJSXTree(
        jsx_tree = jsx_tree,
        update_rules = update_rules,
        components = components
    )
end

@with_kw struct ParsedJSXTree
    jsx_tree::JSXElement
    update_rules::Vector{UpdateRule}
    components::Vector{Component}
end

function parse_tree(x::StaticComponent)
    local update_rules = Vector{UpdateRule}()
    local components = Vector{Component}()

    append!(components, [x])

    if !isnothing(x.children)
        local children = Vector{JSXElement}()

        for i in x.children
            local parsed_tree = parse_tree(i)

            append!(update_rules, parsed_tree.update_rules)
            append!(children, [parsed_tree.jsx_tree])
            append!(components, parsed_tree.components)
        end
    else
        local children = nothing
    end

    local jsx_tree = JSXElement(
        hash = x.hash,
        tag = x.component,
        props = x.parameters,
        children = children,
        component_type = "static",
        data_type = nothing
    )

    return ParsedJSXTree(
        jsx_tree = jsx_tree,
        update_rules = update_rules,
        components = components
    )
end

@with_kw struct MATTApp
    hash::UUID = uuid4()
    jsx_tree::JSXElement
    binds::Dict{UUID, Bind}
    bind_sets::Dict{UUID, BindSet}
    input_components::Dict{UUID, InputComponent}
    output_components::Dict{UUID, OutputComponent}
    update_rules::Dict{UUID, UpdateRule}
    input_bind::Dict{UUID, Vector{UUID}}
    bind_input::Dict{UUID, Vector{UUID}}
    bind_output::Dict{UUID, Vector{UUID}}
    serialized_app::String
end

function setup_app(x::ParsedJSXTree)
    setup_app(x.jsx_tree, x.update_rules, x.components)
end

function setup_app(x::StaticComponent)
    setup_app(parse_tree(x))
end

function setup_app(
    jsx_tree::JSXElement,
    update_rules::Vector{UpdateRule},
    components::Vector{T} where T <: Component)

    local input_components = Dict{UUID, InputComponent}()
    local output_components = Dict{UUID, OutputComponent}()
    local binds = Dict{UUID, Bind}()
    local bind_sets = Dict{UUID, BindSet}()
    local input_bind = Dict{UUID, Vector{UUID}}()
    local bind_input = Dict{UUID, Vector{UUID}}()
    local bind_output = Dict{UUID, Vector{UUID}}()
    local update_rules_dict = Dict{UUID, UpdateRule}()

    for rule in update_rules
        bind_input[rule.bind_set] = rule.input
        update_rules_dict[rule.bind_set] = rule

        if haskey(bind_output, rule.bind_set)
            append!(bind_output[rule.bind_set], [rule.output])
        else
            bind_output[rule.bind_set] = [rule.output]
        end

        for input_hash in rule.input
            if haskey(input_bind, input_hash)
                append!(input_bind[input_hash], [rule.bind_set])
            else
                input_bind[input_hash] = [rule.bind_set]
            end
        end
    end

    local app_ui_def = Dict(
        "jsx_tree" => jsx_tree,
        "input_bind" => input_bind,
        "bind_input" => bind_input,
    )

    for component in components
        if typeof(component) <: InputComponent
            input_components[component.hash] = component
        elseif typeof(component) <: OutputComponent
            output_components[component.hash] = component

            local bind_set_hash = component.callback.bind_set.hash
            if !haskey(bind_sets, bind_set_hash)
                bind_sets[bind_set_hash] = component.callback.bind_set
            end
        end
    end

    for bind_set in values(bind_sets)
        for bind in bind_set.binds
            !haskey(binds, bind.hash) && (binds[bind.hash] = bind)
        end
    end

    MATTApp(
        jsx_tree = jsx_tree,
        binds = binds,
        bind_sets = bind_sets,
        input_components = input_components,
        output_components = output_components,
        update_rules = update_rules_dict,
        input_bind = input_bind,
        bind_input = bind_input,
        bind_output = bind_output,
        serialized_app = json(app_ui_def),
    )
end
