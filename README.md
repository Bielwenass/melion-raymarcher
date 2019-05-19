# melion-raymarcher
A primitive raymarching WebGL renderer for HTML canvas made as a Vue.js component for convenience. It can be easily fit to work with vanilla js if you wish to do so.

Quick setup
```
npm i
npm run serve
```

You can move the camera using w/s keys for movement on Z axis, a/d for X axis and q/e for Y axis. Rotate the camera by dragging on canvas, change fov with the mouse wheel.

This is a simple barebones renderer, edit fragment.glsl to create your own shaders. By default there is a broken Sierpinski tetrahedron.

This is what you should see after opening the page:

![](https://imgur.com/ja3NEmo.png)
