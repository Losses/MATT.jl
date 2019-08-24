using Mux, Base64, DataFrames, Parameters
import Mux.WebSockets

PORT = 2333

function WS_IO(app)
    return x -> ws_io(x, app)
end

@with_kw struct EncodedOutput
    type::String
    content::String
    parameters::Union{Dict{String, String}, Nothing} = nothing
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
    local connection_hash = uuid4()
    local conn = x[:socket]

    @info "Incomming connection" connection_hash

    while !eof(conn)
        local update_hash = uuid4()
        local data = String(WebSockets.readguarded(conn)[1])
        local parsed_data = try JSON.parse(data) catch e; end

        @info "Received message" update_hash parsed_data

        @validate_input(conn, isnothing(parsed_data), "Failed to parse the request to JSON")
        @validate_input(conn, !(typeof(parsed_data) <: Dict), "The request should be an Object")
        @validate_input(conn, !haskey(parsed_data, "command"), "No command provided")

        @info "Validated the message" update_hash

        if parsed_data["command"] == "update"

            @info "Matched command" update_hash

            """
            Client side should pass an update command in the following format:

            {
              "command": "update",
              "bind_set": "<UUID of bind set>",
              "input": {
                "<UUID of input>": "<value of input>",
                "...": "..."
              }
            }

            Example requirement:

            ```
            {
              "command": "update",
              "bind_set": "4c274ad0-9373-4e08-84b1-9a86f9aba145",
              "input": {
                "bdea432c-e94f-4def-ab43-6587beb93607": true
              }
            }
            ```

            Error messages:
            * **1-02-001**: No bind set provided, provide a UUID of the bind set;
            * **1-02-002**: Invalid bind set hash, will be thrown while faild to parse the bind set hash to UUID;
            * **1-02-003**: Bind set not found, the bind set client side provided is not defined in the MATT app;
            * **1-02-004**: No input provided, will be thrown while no input field found in the request;
            * **1-02-005**: Input should be an object, the input field should be a Javascript Object, but something else provided;
            * **1-02-006**: Mismatch input type, the input parameters provided can't be converted to predefinded type.
            """
            @validate_input(conn, !haskey(parsed_data, "bind_set"), "No bind set provided")
            @validate_input(conn, !haskey(parsed_data, "input"), "No input provided")

            @info "validated the input" update_hash

            local bind_set_hash = try UUID(parsed_data["bind_set"]) catch e; end

            @validate_input(conn, isnothing(bind_set_hash), "Invalid bind set hash, should be an UUID")
            @validate_input(conn, !haskey(app.bind_output, bind_set_hash), "Bind set not found")
            @validate_input(conn, !(typeof(parsed_data["input"]) <: Dict{String, Any}), "Input should be an Object")

            @info "validated bind set" update_hash

            local bind_set = app.bind_sets[bind_set_hash]
            local paras_valid = true

            local output_fn_paras = Vector{Pair{Symbol, Any}}([Pair(:__update_hash, update_hash)])

            for bind in bind_set.binds
                local input_hash = bind.component.hash
                local input_hash_str = string(input_hash)
                if !haskey(parsed_data["input"], input_hash_str)
                    paras_valid = false
                    break
                end

                local input_data = parsed_data["input"][input_hash_str]
                local input_type = typeof(app.input_components[input_hash]).parameters[1]
                local input_var_name = app.binds[bind.hash].variable
                local parsed_input = try input_type(input_data) catch e; end

                if isnothing(parsed_input)
                    paras_valid = false
                    break
                end

                append!(output_fn_paras, [Pair(Symbol(input_var_name), parsed_input)])
            end

            @validate_input(conn, !paras_valid, "Mismatch input type")

            @info "validated input" update_hash

            local output_hashes = app.bind_output[bind_set.hash]

            for output_hash in output_hashes
                local callback = app.output_components[output_hash].callback
                local call_result = callback.fn(;output_fn_paras...)
                local encoded_output = ws_encode(call_result)

                local response = json(
                    Dict(
                        "command" => "update",
                        "output" => output_hashes,
                        "detail" => call_result
                    )
                )

                WebSockets.writeguarded(conn, response)
            end
        else
            @validate_input(conn, true, "Invalid command")
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

    local app_hash = x.hash

    @info "MATT initialized" app_hash

    WebSockets.serve(
        WebSockets.ServerWS(
            Mux.http_handler(h),
            Mux.ws_handler(w),
        ), port);
end
