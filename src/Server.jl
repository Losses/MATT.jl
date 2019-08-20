using Mux
import Mux.WebSockets

PORT = 2333

function ws_io(x)
    local conn = x[:socket]

    while !eof(conn)
        data = WebSockets.readguarded(conn)
        data_str = String(data[1])
        println("Received data: " * data_str)

        WebSockets.writeguarded(conn, "Hey, I've received " * data_str)
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
        route("/MATT-io", ws_io),
        Mux.wclose,
        Mux.notfound());

    WebSockets.serve(
        WebSockets.ServerWS(
            Mux.http_handler(h),
            Mux.ws_handler(w),
        ), port);
end
