// All backends expose single `run` functions that will create a window with debug widget
mod boilerplate_glium;
mod boilerplate_glow;
mod boilerplate_sdl2;

fn main() {
    // NOTE: On my machine glow and glium backends cause double letters in text inputs
    // only sdl2 works correctly

    // NOTE: glium backend looks blurry
    boilerplate_sdl2::run();
}
