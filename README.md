# Melion Raymarcher

A primitive raymarching WebGL renderer for HTML canvas made as a Vue.js component for convenience. It can quite easily be altered to work with vanilla js if you wish so. Distance function could use a lot of work to render actual random fractals. I haven't quite figured it out yet.

Demo is available for you to play with at [bielwenass.com](https://www.bielwenass.com/).

### Camera movement

Rotate the camera by dragging on canvas, change FOV with the mouse wheel.
- `w` and `s` keys for Z axis
- `a` and `d` keys for X axis
- `q` and `e` keys for Y axis

`Step size` parameter controls the movement speed. Hold `shift` for 10x movement speed.

Default view after opening the page:

![](https://imgur.com/bKKPXwu.png)

Feel free to float around and explore inside the structure.

Use controls on the right to tweak the rendering parameters and immediately see how they affect the image.

![](https://imgur.com/hthTL3L.png)

## Local setup

Node.js v17 is recommended.
```
git clone https://github.com/Bielwenass/melion-raymarcher.git
cd melion-raymarcher
yarn
yarn serve
```

This is a simple barebones renderer, edit fragment.glsl to create your own shaders. You can also experiment with the default one.

