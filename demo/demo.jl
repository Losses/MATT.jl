include("../src/Component.jl")

tog = Toggle()
cho = Choice()
sli = Slider()

update_text = @output_fn [tog, cho, sli] begin
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
    ])
])

run_app(app)
