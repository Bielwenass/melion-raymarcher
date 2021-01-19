# Melion Raymarcher
A primitive raymarching WebGL renderer for HTML canvas made as a Vue.js component for convenience. It can be easily altered to work with vanilla js if you wish so. Distance function could use a lot of work to render actual fractals. I haven't quite figured it out yet.

Quick setup (requires Node.js):
```
git clone https://github.com/Bielwenass/melion-raymarcher.git
cd melion-raymarcher
npm install
npm run serve
```

You can move the camera using w/s keys for movement on Z axis, a/d for X axis and q/e for Y axis. Rotate the camera by dragging on canvas, change FOV with the mouse wheel.

This is a simple barebones renderer, edit fragment.glsl to create your own shaders. You can also experiment with the default one.

Use controls on the right to tweak the rendering parameters to your liking and immediately see how they affect the final image.

![](https://imgur.com/hthTL3L.png)

This will be your view right after opening the page:

![](https://imgur.com/bKKPXwu.png)
