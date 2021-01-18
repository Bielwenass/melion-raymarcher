<template>
  <div class="wrapper">
    <div class="canvas-container">
      <canvas class="main-canvas" ref="renderCanvas"
        @mousedown="startDragging($event)"
        @mousemove="drag($event)"
        @mouseup="stopDragging($event)"
        @wheel="handleScroll($event)"/>
    </div>
    <div class="controls-container">
      <div>
        <span>Manual rotation adjust</span>
        <button @click="manualRot(0, 0.2)">x +</button>
        <button @click="manualRot(0, -0.2)">x -</button>
        <button @click="manualRot(1, 0.2)">y +</button>
        <button @click="manualRot(1, -0.2)">y -</button>
        <button @click="manualRot(2, 0.2)">z +</button>
        <button @click="manualRot(2, -0.2)">z -</button>
      </div>
      <div>Step size: <input type="text" v-model.number="stepSize"></div>
      <div> pos: {{ roundArray(uniformValues.camera_position) }} </div>
      <div> dir: {{ roundArray(uniformValues.camera_direction) }} </div>
      <div> fov: {{ uniformValues.field_of_view }} </div>
      <button @click="saveImage()">Save image</button>
      <a class="virtual-link" ref="vlink"></a>
    </div>
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
        camera_position: new Float32Array([-1, 0.5, 0.5]),
        camera_direction: new Float32Array([1, 0, 0]),
        camera_right: new Float32Array([0, 0, -1]),
        camera_up: new Float32Array([0, 1, 0]),
        field_of_view: new Float32Array([0.7])
      },
      canvasInfo: null,
      stepSize: 0.05,
      dragData: {
        active: false,
        startingPoint: {
          x: null,
          y: null
        },
        cameraInitialRotation: [1, 0, 0]
      }
    }
  },
  mounted () {
    const canvas = this.$refs.renderCanvas
    this.canvasInfo = canvas.getBoundingClientRect()
    this.gl = canvas.getContext('webgl2', { preserveDrawingBuffer: true }) || canvas.getContext('experimental-webgl', { preserveDrawingBuffer: true })
    canvas.width = 900
    canvas.height = 900

    this.gl.viewport(0, 0, this.gl.drawingBufferWidth, this.gl.drawingBufferHeight)

    this.setupWebGL(this.gl)

    window.addEventListener('keypress', e => {
      this.handleKeypress(e)
    })
  },
  beforeDestroy () {
    this.gl.useProgram(null)
  },
  methods: {
    setupWebGL (gl) {
      const vertexShader = gl.createShader(gl.VERTEX_SHADER)
      gl.shaderSource(vertexShader, vertexSource)
      gl.compileShader(vertexShader)

      if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
        console.error(gl.getShaderInfoLog(vertexShader))
        return
      }

      const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)
      gl.shaderSource(fragmentShader, fragmentSource)
      gl.compileShader(fragmentShader)

      if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
        console.error(gl.getShaderInfoLog(fragmentShader))
        return
      }

      const program = gl.createProgram()
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
      const gl = this.gl

      // Only created once
      if (!this.buffer) {
        const triangles = [
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

      const attributeLocations = {
        vert_position: gl.getAttribLocation(this.program, 'vert_position')
      }

      const uniformLocations = {
        camera_position: gl.getUniformLocation(this.program, 'camera_position'),
        camera_direction: gl.getUniformLocation(this.program, 'camera_direction'),
        camera_right: gl.getUniformLocation(this.program, 'camera_right'),
        camera_up: gl.getUniformLocation(this.program, 'camera_up'),
        field_of_view: gl.getUniformLocation(this.program, 'field_of_view')
      }

      gl.vertexAttribPointer(attributeLocations.vert_position, 2, gl.FLOAT, gl.FALSE, 2 * Float32Array.BYTES_PER_ELEMENT, 0)
      gl.enableVertexAttribArray(attributeLocations.vert_position)

      gl.useProgram(this.program)

      gl.uniform3fv(uniformLocations.camera_position, this.uniformValues.camera_position)
      gl.uniform3fv(uniformLocations.camera_direction, this.uniformValues.camera_direction)
      gl.uniform3fv(uniformLocations.camera_right, this.uniformValues.camera_right)
      gl.uniform3fv(uniformLocations.camera_up, this.uniformValues.camera_up)
      gl.uniform1fv(uniformLocations.field_of_view, this.uniformValues.field_of_view)

      // Draw 6 vertices => 2 triangles:
      gl.drawArrays(this.gl.TRIANGLES, 0, 6)

      // Cleanup:
      gl.bindBuffer(this.gl.ARRAY_BUFFER, null)
    },
    shiftWithAlpha (origin, axis, alpha) {
      return new Float32Array([origin[0] + axis[0] * alpha, origin[1] + axis[1] * alpha, origin[2] + axis[2] * alpha])
    },
    handleKeypress (event) {
      const key = event.code
      let keySensetivity = this.stepSize
      keySensetivity *= event.shiftKey ? 10 : 1
      switch (key) {
        case 'KeyW':
          this.uniformValues.camera_position = this.shiftWithAlpha(this.uniformValues.camera_position, this.uniformValues.camera_direction, keySensetivity)
          break
        case 'KeyA':
          this.uniformValues.camera_position = this.shiftWithAlpha(this.uniformValues.camera_position, this.uniformValues.camera_right, -keySensetivity)
          break
        case 'KeyS':
          this.uniformValues.camera_position = this.shiftWithAlpha(this.uniformValues.camera_position, this.uniformValues.camera_direction, -keySensetivity)
          break
        case 'KeyD':
          this.uniformValues.camera_position = this.shiftWithAlpha(this.uniformValues.camera_position, this.uniformValues.camera_right, keySensetivity)
          break
        case 'KeyQ':
          this.uniformValues.camera_position = this.shiftWithAlpha(this.uniformValues.camera_position, this.uniformValues.camera_up, -keySensetivity)
          break
        case 'KeyE':
          this.uniformValues.camera_position = this.shiftWithAlpha(this.uniformValues.camera_position, this.uniformValues.camera_up, keySensetivity)
          break
        default:
          return
      }

      event.preventDefault()
      this.drawFullscreenQuad()
    },
    cross (a, b) {
      return new Float32Array([a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]])
    },
    normalize (v) {
      const len = Math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2)
      return new Float32Array([v[0] / len, v[1] / len, v[2] / len])
    },
    rotateAround (axis, angle, vec) {
      axis = this.normalize(axis)
      const s = Math.sin(angle)
      const c = Math.cos(angle)
      const oc = 1.0 - c

      const mat3 = [
        [oc * axis[0] * axis[0] + c, oc * axis[0] * axis[1] - axis[2] * s, oc * axis[2] * axis[0] + axis[1] * s],
        [oc * axis[0] * axis[1] + axis[2] * s, oc * axis[1] * axis[1] + c, oc * axis[1] * axis[2] - axis[0] * s],
        [oc * axis[2] * axis[0] - axis[1] * s, oc * axis[1] * axis[2] + axis[0] * s, oc * axis[2] * axis[2] + c]
      ]

      const res = new Float32Array([0, 0, 0])
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 3; j++) {
          res[i] += vec[j] * mat3[i][j]
        }
      }

      return res
    },
    startDragging (event) {
      this.dragData.startingPoint = {
        x: event.clientX,
        y: event.clientY
      }
      this.dragData.cameraInitialRotation = this.uniformValues.camera_direction
      this.dragData.active = true
    },
    drag (event) {
      if (!this.dragData.active) return
      const relativeDrag = {
        x: -(event.clientX - this.dragData.startingPoint.x) / this.canvasInfo.width,
        y: -(event.clientY - this.dragData.startingPoint.y) / this.canvasInfo.height
      }

      // const sensitivity = 1.5
      const sensitivity = this.uniformValues.field_of_view[0] * 2
      relativeDrag.x *= sensitivity
      relativeDrag.y *= sensitivity
      let up = this.uniformValues.camera_up
      let newCameraRotation = this.rotateAround(up, relativeDrag.x, this.uniformValues.camera_direction)
      const right = this.rotateAround(up, relativeDrag.x, this.uniformValues.camera_right)

      newCameraRotation = this.rotateAround(right, relativeDrag.y, newCameraRotation)
      up = this.rotateAround(right, relativeDrag.y, up)

      this.uniformValues.camera_direction = newCameraRotation
      this.uniformValues.camera_right = right
      this.uniformValues.camera_up = up

      this.dragData.startingPoint = {
        x: event.clientX,
        y: event.clientY
      }

      this.drawFullscreenQuad()
    },
    stopDragging () {
      if (!this.dragData.active) return
      this.dragData.active = false
    },
    handleScroll (event) {
      this.uniformValues.field_of_view[0] *= 1 + (Math.sign(event.deltaY) / 30)
      this.drawFullscreenQuad()
    },
    manualRot (coord, value) {
      const newCameraRotation = new Float32Array(this.uniformValues.camera_direction)
      newCameraRotation[coord] += value
      this.uniformValues.camera_direction = newCameraRotation
      this.drawFullscreenQuad()
    },
    roundArray (arr) {
      // Count how many numbers are there in the decimal part and round accordingly
      const decimalLength = (this.stepSize + '').split('.')[1].length
      const newArr = `x = ${arr[0].toFixed(decimalLength)}, y = ${arr[1].toFixed(decimalLength)}, z = ${arr[2].toFixed(decimalLength)}`
      return newArr
    },
    saveImage () {
      const canvas = this.$refs.renderCanvas
      const url = canvas.toDataURL('image/png').replace(/^data:image\/[^;]/, 'data:application/octet-stream')
      const link = this.$refs.vlink

      link.href = url
      link.download = `melion-screenshot-${Math.floor(Date.now() / 1000)}.png`
      link.click()

      window.URL.revokeObjectURL(url)
    }
  }
}
</script>

<style scoped>

.wrapper {
  text-align: center;
}

.main-canvas {
  height: 900px;
  width: 900px;
}

.controls-container {
  position: fixed;
  top: 0;
  right: 0;
  padding: 15px;
  text-align: left;
  line-height: 1.15vw;
  font-size: .7vw;
}

.virtual-link {
  display: none;
}

</style>
