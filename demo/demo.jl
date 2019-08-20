include("../src/Component.jl");
include("../src/React.jl");

tog = Toggle()
cho = Choice()
sli = Slider()

b_set = @bind_set (tog, cho, sli)

update_text = @output_fn (b_set...)::String begin
    print(__update_hash)

    return "tog: " * string(tog) * ", cho: " * string(cho) * "sli: " * string(sli)
end

txt = TextOutput(update_text)

ui = SplitView([
    StackView([
        tog,
        cho,
        sli
    ]),
    StackView([
        txt
    ])])

app = setup_app(ui)

run_app(app)
