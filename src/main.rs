mod boilerplate_glium;

fn main() {
    boilerplate_glium::run();

    // let mut counter = 0;
    // let mut buf = String::new();

    // render(|ui| {
    //     ui.window("Domineering")
    //         .opened(&mut true)
    //         .position([20.0, 20.0], Condition::Appearing)
    //         .size([500.0, 350.0], Condition::Appearing)
    //         .resizable(false)
    //         .build(|| {
    //             ui.text("foo");
    //             ui.input_text("bar", &mut buf).build();
    //         });

    //     counter += 1;
    // });
}
