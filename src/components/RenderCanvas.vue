<template>
  <div>
    <div class="canvas-container">
      <canvas class="main-canvas" ref="renderCanvas"/>
    </div>
    <button @click="saveImage()">Save image</button>
  </div>
</template>

<script>

const vertexSource = require('@/shaders/vertex.glsl')
const fragmentSource = require('@/shaders/fragment.glsl')

export default {
  data () {
    return {
      gl: null,
      buffer: null,
      program: null,
      uniformValues: {
        camera_position: new Float32Array([0, 1, 0])
      }
    }
  },
  mounted () {
    let canvas = this.$refs.renderCanvas
    this.gl = canvas.getContext('webgl2', { preserveDrawingBuffer: true }) || canvas.getContext('experimental-webgl', { preserveDrawingBuffer: true })
    canvas.width = 800
    canvas.height = 800

    this.gl.viewport(0, 0, this.gl.drawingBufferWidth, this.gl.drawingBufferHeight)

    this.setupWebGL(this.gl)

    window.addEventListener('keypress', e => {
      this.handleKeypress(String.fromCharCode(e.keyCode))
    })
  },
  beforeDestroy () {
    this.gl.useProgram(null)
  },
  methods: {
    setupWebGL (gl) {
      let vertexShader = gl.createShader(gl.VERTEX_SHADER)
      gl.shaderSource(vertexShader, vertexSource)
      gl.compileShader(vertexShader)

      if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
        console.error(gl.getShaderInfoLog(vertexShader))
        return
      }

      let fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)
      gl.shaderSource(fragmentShader, fragmentSource)
      gl.compileShader(fragmentShader)

      if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
        console.error(gl.getShaderInfoLog(fragmentShader))
        return
      }

      let program = gl.createProgram()
      gl.attachShader(program, vertexShader)
      gl.attachShader(program, fragmentShader)
      gl.linkProgram(program)

      gl.detachShader(program, vertexShader)
      gl.detachShader(program, fragmentShader)
      gl.deleteShader(vertexShader)
      gl.deleteShader(fragmentShader)

      if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        console.log(gl.LINK_STATUS)
        console.log(gl.getProgramInfoLog(program))
        return
      }

      this.program = program

      this.drawFullscreenQuad()
    },
    drawFullscreenQuad () {
      let gl = this.gl

      // Only created once
      if (!this.buffer) {
        let triangles = [
          // First triangle
          1.0, 1.0,
          -1.0, 1.0,
          -1.0, -1.0,
          // Second triangle
          -1.0, -1.0,
          1.0, -1.0,
          1.0, 1.0
        ]

        this.buffer = gl.createBuffer()
        gl.bindBuffer(gl.ARRAY_BUFFER, this.buffer)
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(triangles), gl.STATIC_DRAW)
      }

      gl.bindBuffer(gl.ARRAY_BUFFER, this.buffer)

      let attributeLocations = {
        vert_position: gl.getAttribLocation(this.program, 'vert_position')
      }

      let uniformLocations = {
        camera_position: gl.getUniformLocation(this.program, 'camera_position')
      }

      gl.vertexAttribPointer(attributeLocations.vert_position, 2, gl.FLOAT, gl.FALSE, 2 * Float32Array.BYTES_PER_ELEMENT, 0)
      gl.enableVertexAttribArray(attributeLocations.vert_position)

      gl.useProgram(this.program)

      gl.uniform3fv(uniformLocations.camera_position, this.uniformValues.camera_position)

      // Draw 6 vertices => 2 triangles:
      gl.drawArrays(this.gl.TRIANGLES, 0, 6)

      // Cleanup:
      gl.bindBuffer(this.gl.ARRAY_BUFFER, null)
    },
    handleKeypress (key) {
      switch (key) {
        case 'w':
          this.uniformValues.camera_position[2]++
          break
        case 'a':
          this.uniformValues.camera_position[0]--
          break
        case 's':
          this.uniformValues.camera_position[2]--
          break
        case 'd':
          this.uniformValues.camera_position[0]++
          break
        case 'q':
          this.uniformValues.camera_position[1]--
          break
        case 'e':
          this.uniformValues.camera_position[1]++
          break
      }
      this.drawFullscreenQuad()
    },
    saveImage () {
      let canvas = this.$refs.renderCanvas
      var image = canvas.toDataURL('image/png').replace('image/png', 'image/octet-stream')
      window.location.href = image
    }
  }
}
</script>

<style scoped lang="sass">

div
  text-align: center

.main-canvas
  height: 800px
  width: 800px

</style>
