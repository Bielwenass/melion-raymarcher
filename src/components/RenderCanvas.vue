<template>
  <div>
    <div class="canvas-container">
      <canvas class="main-canvas" ref="renderCanvas"
        @mousedown="startDragging($event)"
        @mousemove="drag($event)"
        @mouseup="stopDragging($event)"/>
    </div>
    <button @click="manualRot(0, 0.2)">x +</button>
    <button @click="manualRot(0, -0.2)">x -</button>
    <button @click="manualRot(1, 0.2)">y +</button>
    <button @click="manualRot(1, -0.2)">y -</button>
    <button @click="manualRot(2, 0.2)">z +</button>
    <button @click="manualRot(2, -0.2)">z -</button>
    <div> {{ uniformValues.camera_rotation }} </div>
    <button @click="saveImage()">Save image</button>
    <a class="virtual-link" ref="vlink"></a>
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
        camera_position: new Float32Array([2, 2, 0]),
        camera_rotation: new Float32Array([0, 0, 1])
      },
      canvasInfo: null,
      dragData: {
        active: false,
        startingPoint: {
          x: null,
          y: null
        },
        cameraInitialRotation: [0, 0, 1]
      }
    }
  },
  mounted () {
    let canvas = this.$refs.renderCanvas
    this.canvasInfo = canvas.getBoundingClientRect()
    this.gl = canvas.getContext('webgl2', { preserveDrawingBuffer: true }) || canvas.getContext('experimental-webgl', { preserveDrawingBuffer: true })
    canvas.width = 900
    canvas.height = 900

    this.gl.viewport(0, 0, this.gl.drawingBufferWidth, this.gl.drawingBufferHeight)

    this.setupWebGL(this.gl)

    window.addEventListener('keypress', e => {
      this.handleKeypress(e.key)
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
        camera_position: gl.getUniformLocation(this.program, 'camera_position'),
        camera_rotation: gl.getUniformLocation(this.program, 'camera_rotation')
      }

      gl.vertexAttribPointer(attributeLocations.vert_position, 2, gl.FLOAT, gl.FALSE, 2 * Float32Array.BYTES_PER_ELEMENT, 0)
      gl.enableVertexAttribArray(attributeLocations.vert_position)

      gl.useProgram(this.program)

      gl.uniform3fv(uniformLocations.camera_position, this.uniformValues.camera_position)
      gl.uniform3fv(uniformLocations.camera_rotation, this.uniformValues.camera_rotation)

      // Draw 6 vertices => 2 triangles:
      gl.drawArrays(this.gl.TRIANGLES, 0, 6)

      // Cleanup:
      gl.bindBuffer(this.gl.ARRAY_BUFFER, null)
    },
    handleKeypress (key) {
      switch (key) {
        case 'w':
        case '8':
          this.uniformValues.camera_position[2]++
          break
        case 'a':
        case '4':
          this.uniformValues.camera_position[0]--
          break
        case 's':
        case '2':
          this.uniformValues.camera_position[2]--
          break
        case 'd':
        case '6':
          this.uniformValues.camera_position[0]++
          break
        case 'q':
        case '7':
          this.uniformValues.camera_position[1]--
          break
        case 'e':
        case '9':
          this.uniformValues.camera_position[1]++
          break
      }
      this.drawFullscreenQuad()
    },
    startDragging (event) {
      this.dragData.startingPoint = {
        x: event.clientX,
        y: event.clientY
      }
      this.dragData.cameraInitialRotation = this.uniformValues.camera_rotation
      this.dragData.active = true
    },
    drag (event) {
      if (!this.dragData.active) return
      let relativeDrag = {
        x: (event.clientX - this.dragData.startingPoint.x) / this.canvasInfo.width,
        y: -(event.clientY - this.dragData.startingPoint.y) / this.canvasInfo.height
      }

      relativeDrag.x *= 4
      relativeDrag.y *= 4

      let newCameraRotation = new Float32Array([
        relativeDrag.x + this.dragData.cameraInitialRotation[0],
        relativeDrag.y + this.dragData.cameraInitialRotation[1],
        Math.cos(relativeDrag.x) - Math.sin(relativeDrag.y) + this.dragData.cameraInitialRotation[2]
      ])

      this.uniformValues.camera_rotation = newCameraRotation

      this.drawFullscreenQuad()
    },
    stopDragging () {
      if (!this.dragData.active) return
      this.dragData.active = false
    },
    manualRot (coord, value) {
      let newCameraRotation = this.uniformValues.camera_rotation
      newCameraRotation[coord] += value
      this.uniformValues.camera_rotation = newCameraRotation
      this.drawFullscreenQuad()
    },
    saveImage () {
      let canvas = this.$refs.renderCanvas
      let url = canvas.toDataURL('image/png').replace(/^data:image\/[^;]/, 'data:application/octet-stream')
      let link = this.$refs.vlink

      link.href = url
      link.download = `melion-screenshot-${Math.floor(Date.now() / 1000)}.png`
      link.click()

      window.URL.revokeObjectURL(url)
    }
  }
}
</script>

<style scoped lang="sass">

div
  text-align: center

.main-canvas
  height: 900px
  width: 900px

.virtual-link
  display: none

</style>
