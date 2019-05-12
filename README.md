# melion-raymarcher
A primitive raymarching renderer for HTML canvas built on Vue.js

Quick setup
```
npm i
npm run serve
```

You can move the camera using w/s keys for movement on Z axis, a/d for X axis and q/e for Y axis. There is no way to rotate the camera yet.

This is a simple barebones renderer, edit fragment.glsl to create your own shaders. By default there is a plane on x = 0 and a sphere looped in XYZ planes.

This is what you should see after opening the page:

![](https://i.imgur.com/SxXktWC.png)
