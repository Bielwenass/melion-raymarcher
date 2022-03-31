<template>
  <div class="wrapper">
    <div class="canvas-container">
      <canvas
        ref="renderCanvas"
        class="main-canvas"
        @mousedown="startDragging($event)"
        @mousemove="drag($event)"
        @mouseup="stopDragging($event)"
        @wheel="handleScroll($event)"
      />
    </div>
    <div class="controls-container">
      <button @click="saveImage()">
        Save image
      </button>
      <a
        ref="vlink"
        class="virtual-link"
      />

      <div>
        Shape modifier
        <input
          type="range"
          min="-15"
          max="15"
          step="1"
          :value="uniformValues.shape_modifier"
          @input="updateUniformValue('shape_modifier', $event.target.value)"
        >
        {{ uniformValues.shape_modifier }}
      </div>
      <div>
        Iterations
        <input
          type="range"
          min="1"
          max="20"
          step="1"
          :value="uniformValues.iteration_count"
          @input="updateUniformValue('iteration_count', $event.target.value)"
        >
        {{ uniformValues.iteration_count }}
      </div>
      <div>
        Surf dist
        <input
          type="range"
          min="0.005"
          max="0.1"
          step="0.005"
          :value="Math.pow(uniformValues.surf_dist, 1 / 3)"
          @input="updateUniformValue('surf_dist', $event.target.value ** 3)"
        >
        {{ uniformValues.surf_dist.toFixed(7) }}
      </div>
      <div>
        Glow intensity
        <input
          type="range"
          min="0"
          max="10"
          step="0.01"
          :value="uniformValues.glow_intensity"
          @input="updateUniformValue('glow_intensity', $event.target.value)"
        >
        {{ uniformValues.glow_intensity }}
      </div>
      <div>
        Max steps
        <input
          type="range"
          min="1"
          max="30"
          :value="Math.sqrt(uniformValues.max_steps)"
          @input="updateUniformValue('max_steps', $event.target.value ** 2)"
        >
        {{ uniformValues.max_steps }}
      </div>
      <div>
        Max dist
        <input
          type="range"
          min="1"
          max="100"
          :value="Math.sqrt(uniformValues.max_dist)"
          @input="updateUniformValue('max_dist', $event.target.value ** 2)"
        >
        {{ uniformValues.max_dist }}
      </div>

      <div>Position: {{ roundArray(uniformValues.camera_position) }} </div>
      <div>
        Step size: <input
          v-model.number="stepSize"
          type="text"
        >
      </div>
      <div>Direction: {{ roundArray(uniformValues.camera_direction) }} </div>
      <div>
        <span>Manual camera rotation adjust </span>
        <br>
        <button @click="manualRot(0, 0.2)">
          x +
        </button>
        <button @click="manualRot(0, -0.2)">
          x -
        </button>
        <button @click="manualRot(1, 0.2)">
          y +
        </button>
        <button @click="manualRot(1, -0.2)">
          y -
        </button>
        <button @click="manualRot(2, 0.2)">
          z +
        </button>
        <button @click="manualRot(2, -0.2)">
          z -
        </button>
      </div>
      <div> FOV: {{ uniformValues.field_of_view.toFixed(5) }} </div>
    </div>
  </div>
</template>

<script>
const fragmentSource = require('@/shaders/fragment.glsl')
const vertexSource = require('@/shaders/vertex.glsl')

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
        field_of_view: 0.7,
        max_steps: 256,
        max_dist: 900,
        surf_dist: 0.000064,
        glow_intensity: 0.4,
        shape_modifier: -11,
        iteration_count: 5,
        canvas_size: 900
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
        field_of_view: gl.getUniformLocation(this.program, 'field_of_view'),
        max_steps: gl.getUniformLocation(this.program, 'max_steps'),
        max_dist: gl.getUniformLocation(this.program, 'max_dist'),
        surf_dist: gl.getUniformLocation(this.program, 'surf_dist'),
        glow_intensity: gl.getUniformLocation(this.program, 'glow_intensity'),
        shape_modifier: gl.getUniformLocation(this.program, 'shape_modifier'),
        iteration_count: gl.getUniformLocation(this.program, 'iteration_count'),
        canvas_size: gl.getUniformLocation(this.program, 'canvas_size')
      }

      gl.vertexAttribPointer(
        attributeLocations.vert_position,
        2,
        gl.FLOAT,
        gl.FALSE,
        2 * Float32Array.BYTES_PER_ELEMENT,
        0
      )
      gl.enableVertexAttribArray(attributeLocations.vert_position)

      gl.useProgram(this.program)

      gl.uniform3fv(uniformLocations.camera_position, this.uniformValues.camera_position)
      gl.uniform3fv(uniformLocations.camera_direction, this.uniformValues.camera_direction)
      gl.uniform3fv(uniformLocations.camera_right, this.uniformValues.camera_right)
      gl.uniform3fv(uniformLocations.camera_up, this.uniformValues.camera_up)
      gl.uniform1f(uniformLocations.field_of_view, this.uniformValues.field_of_view)
      gl.uniform1f(uniformLocations.max_steps, this.uniformValues.max_steps)
      gl.uniform1f(uniformLocations.max_dist, this.uniformValues.max_dist)
      gl.uniform1f(uniformLocations.surf_dist, this.uniformValues.surf_dist)
      gl.uniform1f(uniformLocations.glow_intensity, this.uniformValues.glow_intensity)
      gl.uniform1i(uniformLocations.shape_modifier, this.uniformValues.shape_modifier)
      gl.uniform1i(uniformLocations.iteration_count, this.uniformValues.iteration_count)
      gl.uniform1i(uniformLocations.canvas_size, this.uniformValues.canvas_size)

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
          this.uniformValues.camera_position = this.shiftWithAlpha(
            this.uniformValues.camera_position,
            this.uniformValues.camera_direction,
            keySensetivity
          )
          break
        case 'KeyA':
          this.uniformValues.camera_position = this.shiftWithAlpha(
            this.uniformValues.camera_position,
            this.uniformValues.camera_right,
            -keySensetivity
          )
          break
        case 'KeyS':
          this.uniformValues.camera_position = this.shiftWithAlpha(
            this.uniformValues.camera_position,
            this.uniformValues.camera_direction,
            -keySensetivity
          )
          break
        case 'KeyD':
          this.uniformValues.camera_position = this.shiftWithAlpha(
            this.uniformValues.camera_position,
            this.uniformValues.camera_right,
            keySensetivity
          )
          break
        case 'KeyQ':
          this.uniformValues.camera_position = this.shiftWithAlpha(
            this.uniformValues.camera_position,
            this.uniformValues.camera_up,
            -keySensetivity
          )
          break
        case 'KeyE':
          this.uniformValues.camera_position = this.shiftWithAlpha(
            this.uniformValues.camera_position,
            this.uniformValues.camera_up,
            keySensetivity
          )
          break
        default:
          return
      }

      event.preventDefault()
      this.drawFullscreenQuad()
    },
    updateUniformValue (key, value) {
      this.uniformValues[key] = value
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
      const sensitivity = this.uniformValues.field_of_view * 2

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
      this.uniformValues.field_of_view *= 1 + (Math.sign(event.deltaY) / 30)
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
      const newArr = `
        x = ${arr[0].toFixed(decimalLength)}, 
        y = ${arr[1].toFixed(decimalLength)},
        z = ${arr[2].toFixed(decimalLength)}`

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
  min-width: 21vmax;
  padding: 15px;
  text-align: left;
  line-height: 1.2vmax;
  font-size: .9vmax;
}

.virtual-link {
  display: none;
}

</style>
