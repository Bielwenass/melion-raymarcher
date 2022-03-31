<template>
  <div id="app">
    <RenderCanvas />
  </div>
</template>

<script>
import RenderCanvas from './components/RenderCanvas.vue'

export default {
  name: 'App',
  components: {
    RenderCanvas
  }
}
</script>

<style>
@import "assets/normalize.min.css";

body {
  font-family: monospace;
  background-color: black;
  background-image: url("assets/dots.png");
  color: white;
}

</style>
