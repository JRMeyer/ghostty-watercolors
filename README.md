# ghostty-shaders

Watercolor wash backgrounds for [Ghostty](https://ghostty.org) terminal.

## Shaders

- **flat-wash-bg.glsl** — Uniform color with organic edges.
- **graded-wash-bg.glsl** — Fades from full color to transparent, top to bottom.
- **variegated-wash-bg.glsl** — Two colors blending into each other.
- **wet-on-wet-bg.glsl** — Soft, bleeding color regions like pigment dropped on wet paper.
- **glazing-bg.glsl** — Multiple transparent color layers stacked with visible overlap.
- **granulating-bg.glsl** — Pigment settles into paper texture, creating a speckled, grainy look.
- **salt-bg.glsl** — Fine speckled texture where salt crystals disrupted the wash.
- **cauliflower-bg.glsl** — Backruns with fractal edges where wet paint crept into drying areas.
- **splatter-bg.glsl** — Random droplets scattered across a light wash, like flicking a loaded brush.

## Usage

Add to your Ghostty config (`~/.config/ghostty/config`):

```
custom-shader = /path/to/shader.glsl
background-opacity = 0.85
```

Optional config for extra breathing room:

```
window-padding-x = 64
window-padding-y = 64
```

Each shader uses a `WASH_HUE` placeholder for the color. Replace it with a value between `0.0` and `1.0` to pick a hue, e.g.:

```bash
sed 's/WASH_HUE/0.6/g' flat-wash-bg.glsl > my-shader.glsl
```

## Randomize per window

`randomize-shader.sh` picks a random shader **and** a random color each time it runs, generating `active-shader.glsl`. Add to your `.zshrc`:

```bash
source /path/to/ghostty-shaders/randomize-shader.sh
```

Then point your Ghostty config to the generated file:

```
custom-shader = /path/to/ghostty-shaders/active-shader.glsl
```

Each new terminal window gets a different wash type and color.
