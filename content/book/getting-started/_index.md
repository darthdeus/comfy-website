+++
title = "Getting Started"
weight = 2
sort_by = "weight"
template = "docs-section.html"
page_template = "docs-section.html"
insert_anchor_links = "right"
+++

This section is an introduction to Comfy, a fun and simple 2D game engine for
Rust. If you've used [macroquad](https://macroquad.rs/),
[Raylib](https://www.raylib.com/), or [Love2D](https://love2d.org/) you should
feel right at home. If you haven't, don't worry, Comfy is designed to a nice
environment for making games.

**If you just want to see some code, check out the [examples](/examples)**, which
while not exhaustive should cover most of the basics. Notably, the
[`full_game_loop`](https://github.com/darthdeus/comfy/blob/master/comfy/examples/full_game_loop.rs)
example strips away all of comfy's macros and shows a simple setup for a game
loop. A good starting point for a "more realistic" game would be the [`physics
example`](https://github.com/darthdeus/comfy/blob/master/comfy/examples/physics.rs),
which although very simple shows some of the core ideas and principles behind
how we use comfy. That being said, **don't feel limited by what is presented in the examples.
Comfy is by no means prescriptive in how it should be used.**

Comfy uses [hecs](https://docs.rs/hecs/latest/hecs/) for its ECS and bakes its
support into the engine with a few useful types (e.g. `Sprite`,
`AnimatedSprite`, ...), but all of the ECS functionality is built on top of
public immediate mode APIs you can use directly if you prefer, and which are
also used in many of the examples. You should not feel limited by the existing ECS types,
they mainly exist as an evolution of what we use for our own games, but comfy should be flexible
enough so you can build games in whatever way you prefer.

It should be noted that while Comfy doesn't have extensive documentation, we do
have quite a few examples that showcase almost everything users have
needed/asked for. **Please take a look at the [existing
examples](https://github.com/darthdeus/comfy/tree/master/comfy/examples), it's
very likely they'll be able to answer most of your questions :)**

## Drawing a red circle

1. [Install Rust](https://www.rust-lang.org/learn/get-started)

2. From a terminal, create a new Rust project and add comfy as a dependency:

   ```sh
   cargo new my-comfy-game
   cd my-comfy-game
   cargo add comfy
   ```

3. Replace `src/main.rs` with a simple comfy game that draws a red circle:

   ```rust
   use comfy::*;

   simple_game!("Nice red circle", update);

   fn update(_c: &mut EngineContext) {
      draw_circle(vec2(0.0, 0.0), 0.5, RED, 0);
   }
   ```

4. Run your game:

   ```sh
   cargo run
   ```

### How does the game work?

The parameters of circle are simply just `position`, `radius`, `color`, and
`z_index`. Unlike macroquad and a few other engines, all of comfy's drawing
functions accept a `z_index`, and all draw calls will get internally batched
and z-sorted. This means you don't have to worry about the order in which you
draw, just make sure you provide the right `z_index`.

Comfy uses [`glam`](https://docs.rs/glam/latest/glam/) for all of its math, and
also re-exports many of its utility functions, including functions like `vec2`,
`ivec2`, `splat`, etc.

Going back to the above example, the `simple_game!(...)` macro is a convenient
shortcut for game that just want a game loop with `setup/update` (more on
`setup` later). Comfy doesn't do any heavy code generation magic and does not
use procedural macros.

The `update` function accepts a `c: &mut EngineContext`, which is a core
pattern of comfy that you'll see in all the examples, and that we use in all of
our games. The `EngineContext` is a struct that contains references to almost
all of the internal state of the engine, and many utility functions (e.g.
loading assets, configuring post processing, etc.).

The way comfy games are written is that almost every function will accept some
kind of context object as `c`, be it `EngineContext`, or a user-created context
that wraps it as shown in the [physics
example](https://github.com/darthdeus/comfy/blob/master/comfy/examples/physics.rs).

If you don't like this approach, you can build whatever structure you prefer
for your own game code, but over the past year of using comfy quite heavily
we've found that having a single context object greatly simplifies writing game
code, as the developer does not have to worry about "how do I get this other
thing" I need.

You may also notice that `draw_circle(...)` does not actually use `c`.
Internally, comfy uses a few global variables for storing state, which includes
drawing queues, input data, and a few other things. These are collected and
processed in various stages, for example when you call `draw_circle` the GPU
remains untouched, and the parameters you provided are stored in a queue. The
engine then later processes the draw queue, batches all the calls, handles
`z_sorting`, etc. Comfy does these things because it greatly simplifies
gameplay code, and also because while it may not be the most performant
approach, it's still very very fast, and for most games won't even show up in a
profiler.

## Optimizations in debug builds

While Rust as a language can be incredibly fast and efficient, it is _very_
slow in debug builds with no additional configuration. Fortunately, there's a
very simple change you can make that won't have any negative impact and will
just make everything significantly faster. Copy paste the following lines into
your `Cargo.toml`:

```toml
[profile.dev]
opt-level = 1
[profile.dev.package."*"]
opt-level = 1
```

This will enable some level of optimizations for your game code, Comfy, and all
of the dependencies. At level 1 it shouldn't really affect compile times, and
in some cases it actually makes things compile faster because Rust's procedural
macros benefit from optimizations, and they usually account for a large portion
of compile times.

If you'd like to go a step further and improve your compile times, here's
another trick. By default Rust will use a very slow linker.

On Linux this is very easy with the [`mold`
linker](https://github.com/rui314/mold) which is incredibly fast and is
available in your distro's package manager (e.g. `sudo pacman -S mold clang` on
Arch Linux).

```toml
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-Clink-arg=-fuse-ld=mold", "-Zshare-generics=y"]
```

One of the options is `-Zshare-generics=y` which generally helps, but requires
the Nightly version of the Rust compiler. You can get this with `rustup default
nightly`, which on its own should also improve compile times a little bit just
by having more of the newer features. We've been running nightly `rustc` on dev
machines for over two years and in general would recommend it, as the number of
issues one runs into is extremely small. I don't even remember the last time we
had an issue due to using nightly. If you'd like to use the stable version of
`rustc`, simply remove `-Zshare-generics=y` from all of the configurations.

On MacOS the situation is a bit more complicatedl there's a now deprecated
[`zld` linker](https://github.com/michaeleisel/zld), and a commercial MacOS
version of `mold` which is called
[`sold`](https://github.com/bluewhalesystems/sold).

This is something where you'll have to play around a bit and see what you can
get working, but here's an example of using `zld` on Intel MacOS and default
linker but with `share-generics=y` on ARM.

```toml
[target.x86_64-apple-darwin]
rustflags = ["-C", "link-arg=-fuse-ld=/usr/local/bin/zld", "-Zshare-generics=y"]

[target.aarch64-apple-darwin]
rustflags = ["-Zshare-generics=y"]
```

On Windows you'll have to intsall a few dependencies

```
cargo install -f cargo-binutils
rustup component add llvm-tools-preview
```

and then the following should work

```toml
[target.x86_64-pc-windows-msvc]
linker = "rust-lld.exe"
rustflags = []

# Optional: Uncommenting the following improves compile times, but reduces the amount of debug info to 'line number tables only'
# In most cases the gains are negligible, but if you are on macos and have slow compile times you should see significant gains.
# [profile.dev]
# debug = 1
```


## simple game with `setup`

Continuing from the previous example, let's say we want to draw a sprite
instead of a boring circle. This creates a new problem, _how do we load
assets_?

Comfy does not use any kind of complicated asset management solution. We do
have a parallel asset loader, but let's begin simple with just one sprite.

```rust
use comfy::*;

simple_game!("Sprite Example", setup, update);

fn setup(c: &mut EngineContext) {
    c.load_texture_from_bytes(
        // Name of our sprite
        "comfy",
        // &[u8] with the image data.
        include_bytes!("assets/comfy.png")
    );
}

fn update(_c: &mut EngineContext) {
    draw_sprite(
        // Sprites are referenced with their string name.
        // Comfy doesn't use asset handles.
        texture_id("comfy"),
        // position
        Vec2::ZERO,
        // color tint
        WHITE,
        // z_index
        0,
        // size
        splat(5.0),
    );
}
```

The `simple_game!(...)` macro we've used in the first example can also be used
in the case where we want a `setup` function that gets called once when the
game is initialized.

In this case we load a texture from a byte slice, and then draw it. The
`texture_id(...)` function is a simple hashing function which turns string
names into an asset id. Every texture is assigned a unique name to make
referencing it easier. Many engines use asset handles, but we've found them to be
annoying to work with when all you want is to say "draw this sprite".

If you ever run into a scenario where the cost of calling `texture_id(...)` is
too high, you can simply cache the result. That being said, we've never
observed any of this to be a problem in our games.

When you look around the examples in comfy, notably the [sprite
example](https://github.com/darthdeus/comfy/blob/master/comfy/examples/sprite.rs)
you'll notice that we're actually calling `include_bytes!(...)` like this.

```rust
include_bytes!(concat!(env!("CARGO_MANIFEST_DIR"), "/../assets/comfy.png"))
```

Depending on your folder structure and how you run your game you it's likely
going to be enough to just use the simpler variant, but it may be useful to
know about `CARGO_MANIFEST_DIR`.

## What's next?

If you feel like you've already seen enough and just want to make a game, go
ahead! Comfy does contain other features, but most of them should be easily
discoverable, e.g. to see if a key is pressed you would call `is_key_pressed`,
to play a sound you'd call `play_sound`, etc.

The github repository contains many examples under
[`comfy/examples`](https://github.com/darthdeus/comfy/tree/master/comfy/examples)
that show off most of the functionality.

Comfy does have a few more advanced features that don't yet have examples, and
we do plan on adding bigger more complete games as a showcase of how we use
comfy, but even with the examples we have you should be able to make a
reasonably sized 2D game.

If you feel like this wasn't enough, continue reading the next chapter about
how comfy's camera works!
