Random.seed!(2333)

include("../src/Component.jl");
include("../src/React.jl");
include("../src/Server.jl");

tog = Toggle()
cho = Choice()
sli = Slider()

b_set = @bind_set (tog, cho, sli)

update_text = @output_fn (b_set...)::String begin
    print(__update_hash)

    return "tog: " * string(tog) * ", cho: " * string(cho) * "sli: " * string(sli)
end

txt = TextOutput(update_text)

app = SplitView([
    StackView([
        tog,
        cho,
        sli
    ]),
    StackView([
        txt
    ])])

run_app(app)
