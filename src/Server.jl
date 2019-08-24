using Mux, Base64, DataFrames, Parameters
import Mux.WebSockets

PORT = 2333

function WS_IO(app)
    return x -> ws_io(x, app)
end

@with_kw struct EncodedOutput
    type::String
    content::String
    parameters::Dict{String, String}
end

function ws_encode(x::String)
    EncodedOutput(
        type = "string",
        content = x
    )
end

# function ws_encode(x::Plot)
#
# end

function ws_encode(x::DataFrame)

end

function ws_encode(x::Number)

end

macro validate_input(conn, condition, error_msg)
    quote
        if $(esc(condition))
            @error $error_msg

            local response = json(
                Dict{String, String}(
                    "command" => "error",
                    "message" => $error_msg
                )
            )

            WebSockets.writeguarded($conn, response)

            continue
        end
    end
end

function ws_io(x, app::MATTApp)
    local conn = x[:socket]

    while !eof(conn)
        local update_hash = uuid4()
        local data = String(WebSockets.readguarded(conn)[1])
        local parsed_data = try JSON.parse(data) catch e; end

        @validate_input(conn, isnothing(parsed_data), "Failed to parse the request to JSON")
        @validate_input(conn, !(typeof(parsed_data) <: Dict), "The request should be an Object")
        @validate_input(conn, !haskey(parsed_data, "command"), "No command provided")

        if parsed_data["command"] == "update"
            @validate_input(conn, !haskey(parsed_data, "bind_set"), "No bind set provided")
            @validate_input(conn, !haskey(parsed_data, "input"), "No input provided")

            local bind_set_hash = try UUID(parsed_data["bind_set"]) catch e; end
            @validate_input(conn, isnothing(bind_set_hash), "Invalid bind set hash, should be an UUID")
            @validate_input(conn, !haskey(app.bind_output, bind_set_hash), "Bind set not found")
            @validate_input(conn, !(typeof(parsed_data["input"]) <: Dict{String, Any}), "Input should be an Object")

            local bind_set = app.bind_sets[bind_set_hash]
            local paras_valid = true

            local output_fn_paras = Vector{Any}([Symbol("output_fn")])

            for bind in bind_set.binds
                local input_hash = bind.input.hash
                local input_hash_str = string(input_hash)
                if !haskey(parsed_data["input"], input_hash_str)
                    paras_valid = false
                    break
                end

                local input_data = parsed_data["input"][input_hash_str]
                local input_type = app.input_components[input_hash].parameters[1]
                local input_var_name = app.binds[bind.hash].variable
                local parsed_input = try input_type(input_data) catch e; end

                if isnothing(parsed_input)
                    paras_valid = false
                    break
                end

                append!(output_fn_paras, [Expr(:kw, [Symbol(input_var_name), parsed_input])])
            end

            @validate_input(conn, !paras_valid, "Mismatch input type")

            local output_hashes = app.bind_output[bind_set.hash]

            for output_hash in output_hashes
                local output_fn = app.outputs[output_hash].callback.fn
                local call_expr = Expr(:call, output_fn_paras)

                local call_result = ws_encode(eval(output_hash))
                local response = json(
                    Dict(
                        "command" => "update",
                        "output" => output_hashes,
                        "detail" => call_result
                    )
                )

                WebSockets.writeguarded(conn, response)
            end
        end
    end
end

function run_app(x::StaticComponent; port::Int64 = 2333)
    run_app(setup_app(x), port = port)
end

function run_app(x::MATTApp; port::Int64 = 2333)
    @app h = (
        Mux.defaults,
        page("/", respond("<h1>Hello World!</h1>")),
        page("/ui", respond(x.serialized_app)),
        Mux.notfound());

    @app w = (
        Mux.wdefaults,
        route("/MATT-io", WS_IO(x)),
        Mux.wclose,
        Mux.notfound());

    WebSockets.serve(
        WebSockets.ServerWS(
            Mux.http_handler(h),
            Mux.ws_handler(w),
        ), port);
end
