# ghostty-shaders

Watercolor wash backgrounds for [Ghostty](https://ghostty.org) terminal.

## Shaders

- **flat-wash-bg.glsl** — Uniform color with organic edges.
- **graded-wash-bg.glsl** — Fades from full color to transparent, top to bottom.
- **variegated-wash-bg.glsl** — Two colors blending into each other.

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

## Randomize per window

`randomize-shader.sh` picks a random shader each time it runs. Add to your `.zshrc`:

```bash
source /path/to/ghostty-shaders/randomize-shader.sh
```

Then point your Ghostty config to the symlink it creates:

```
custom-shader = /path/to/ghostty-shaders/active-shader.glsl
```
