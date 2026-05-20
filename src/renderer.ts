import fragmentSource from "./shaders/fragment.glsl?raw";
import vertexSource from "./shaders/vertex.glsl?raw";

interface UniformValues {
  camera_position: Float32Array;
  camera_direction: Float32Array;
  camera_right: Float32Array;
  camera_up: Float32Array;
  field_of_view: number;
  max_steps: number;
  max_dist: number;
  surf_dist: number;
  glow_intensity: number;
  shape_modifier: number;
  iteration_count: number;
  canvas_size: number;
}

let gl!: WebGL2RenderingContext;
let buffer: WebGLBuffer | null = null;
let program!: WebGLProgram;
let canvasInfo!: DOMRect;
let stepSize = 0.05;

const uniformValues: UniformValues = {
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
  canvas_size: 900,
};

const dragData = {
  active: false,
  startingPoint: { x: 0, y: 0 },
};

function shiftWithAlpha(
  origin: Float32Array,
  axis: Float32Array,
  alpha: number,
): Float32Array {
  return new Float32Array([
    origin[0] + axis[0] * alpha,
    origin[1] + axis[1] * alpha,
    origin[2] + axis[2] * alpha,
  ]);
}

function normalize(v: Float32Array): Float32Array {
  const len = Math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2);

  return new Float32Array([v[0] / len, v[1] / len, v[2] / len]);
}

function rotateAround(
  axis: Float32Array,
  angle: number,
  vec: Float32Array,
): Float32Array {
  const n = normalize(axis);
  const s = Math.sin(angle);
  const c = Math.cos(angle);
  const oc = 1.0 - c;

  const mat3 = [
    [
      oc * n[0] * n[0] + c,
      oc * n[0] * n[1] - n[2] * s,
      oc * n[2] * n[0] + n[1] * s,
    ],
    [
      oc * n[0] * n[1] + n[2] * s,
      oc * n[1] * n[1] + c,
      oc * n[1] * n[2] - n[0] * s,
    ],
    [
      oc * n[2] * n[0] - n[1] * s,
      oc * n[1] * n[2] + n[0] * s,
      oc * n[2] * n[2] + c,
    ],
  ];

  const res = new Float32Array([0, 0, 0]);

  for (let i = 0; i < 3; i++) {
    for (let j = 0; j < 3; j++) {
      res[i] += vec[j] * mat3[i][j];
    }
  }

  return res;
}

function roundArray(arr: Float32Array): string {
  const decimalLength = String(stepSize).split(".")[1]?.length ?? 0;

  return `x = ${arr[0].toFixed(decimalLength)}, y = ${arr[1].toFixed(decimalLength)}, z = ${arr[2].toFixed(decimalLength)}`;
}

function updateDisplays(): void {
  const setText = (id: string, text: string) => {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
  };

  setText("val-shape-modifier", String(uniformValues.shape_modifier));
  setText("val-iteration-count", String(uniformValues.iteration_count));
  setText("val-surf-dist", uniformValues.surf_dist.toFixed(7));
  setText("val-glow-intensity", String(uniformValues.glow_intensity));
  setText("val-max-steps", String(uniformValues.max_steps));
  setText("val-max-dist", String(uniformValues.max_dist));
  setText("display-position", roundArray(uniformValues.camera_position));
  setText("display-direction", roundArray(uniformValues.camera_direction));
  setText("display-fov", uniformValues.field_of_view.toFixed(5));
}

function draw(): void {
  if (!buffer) {
    const triangles = [
      1.0, 1.0, -1.0, 1.0, -1.0, -1.0, -1.0, -1.0, 1.0, -1.0, 1.0, 1.0,
    ];

    buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(triangles), gl.STATIC_DRAW);
  }

  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);

  const attrLoc = gl.getAttribLocation(program, "vert_position");
  const uniLoc = {
    camera_position: gl.getUniformLocation(program, "camera_position"),
    camera_direction: gl.getUniformLocation(program, "camera_direction"),
    camera_right: gl.getUniformLocation(program, "camera_right"),
    camera_up: gl.getUniformLocation(program, "camera_up"),
    field_of_view: gl.getUniformLocation(program, "field_of_view"),
    max_steps: gl.getUniformLocation(program, "max_steps"),
    max_dist: gl.getUniformLocation(program, "max_dist"),
    surf_dist: gl.getUniformLocation(program, "surf_dist"),
    glow_intensity: gl.getUniformLocation(program, "glow_intensity"),
    shape_modifier: gl.getUniformLocation(program, "shape_modifier"),
    iteration_count: gl.getUniformLocation(program, "iteration_count"),
    canvas_size: gl.getUniformLocation(program, "canvas_size"),
  };

  gl.vertexAttribPointer(
    attrLoc,
    2,
    gl.FLOAT,
    false,
    2 * Float32Array.BYTES_PER_ELEMENT,
    0,
  );
  gl.enableVertexAttribArray(attrLoc);
  gl.useProgram(program);

  gl.uniform3fv(uniLoc.camera_position, uniformValues.camera_position);
  gl.uniform3fv(uniLoc.camera_direction, uniformValues.camera_direction);
  gl.uniform3fv(uniLoc.camera_right, uniformValues.camera_right);
  gl.uniform3fv(uniLoc.camera_up, uniformValues.camera_up);
  gl.uniform1f(uniLoc.field_of_view, uniformValues.field_of_view);
  gl.uniform1f(uniLoc.max_steps, uniformValues.max_steps);
  gl.uniform1f(uniLoc.max_dist, uniformValues.max_dist);
  gl.uniform1f(uniLoc.surf_dist, uniformValues.surf_dist);
  gl.uniform1f(uniLoc.glow_intensity, uniformValues.glow_intensity);
  gl.uniform1i(uniLoc.shape_modifier, uniformValues.shape_modifier);
  gl.uniform1i(uniLoc.iteration_count, uniformValues.iteration_count);
  gl.uniform1i(uniLoc.canvas_size, uniformValues.canvas_size);

  gl.drawArrays(gl.TRIANGLES, 0, 6);
  gl.bindBuffer(gl.ARRAY_BUFFER, null);

  updateDisplays();
}

function setupWebGL(): void {
  const vertexShader = gl.createShader(gl.VERTEX_SHADER);

  if (!vertexShader) return;

  gl.shaderSource(vertexShader, vertexSource);
  gl.compileShader(vertexShader);

  if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
    console.error(gl.getShaderInfoLog(vertexShader));

    return;
  }

  const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);

  if (!fragmentShader) return;

  gl.shaderSource(fragmentShader, fragmentSource);
  gl.compileShader(fragmentShader);

  if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
    console.error(gl.getShaderInfoLog(fragmentShader));

    return;
  }

  const prog = gl.createProgram();

  if (!prog) return;

  gl.attachShader(prog, vertexShader);
  gl.attachShader(prog, fragmentShader);
  gl.linkProgram(prog);
  gl.detachShader(prog, vertexShader);
  gl.detachShader(prog, fragmentShader);
  gl.deleteShader(vertexShader);
  gl.deleteShader(fragmentShader);

  if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
    console.error(gl.getProgramInfoLog(prog));

    return;
  }

  program = prog;
  draw();
}

function handleKeypress(event: KeyboardEvent): void {
  let sensitivity = stepSize;

  sensitivity *= event.shiftKey ? 10 : 1;

  switch (event.code) {
    case "KeyW":
      uniformValues.camera_position = shiftWithAlpha(
        uniformValues.camera_position,
        uniformValues.camera_direction,
        sensitivity,
      );
      break;
    case "KeyA":
      uniformValues.camera_position = shiftWithAlpha(
        uniformValues.camera_position,
        uniformValues.camera_right,
        -sensitivity,
      );
      break;
    case "KeyS":
      uniformValues.camera_position = shiftWithAlpha(
        uniformValues.camera_position,
        uniformValues.camera_direction,
        -sensitivity,
      );
      break;
    case "KeyD":
      uniformValues.camera_position = shiftWithAlpha(
        uniformValues.camera_position,
        uniformValues.camera_right,
        sensitivity,
      );
      break;
    case "KeyQ":
      uniformValues.camera_position = shiftWithAlpha(
        uniformValues.camera_position,
        uniformValues.camera_up,
        -sensitivity,
      );
      break;
    case "KeyE":
      uniformValues.camera_position = shiftWithAlpha(
        uniformValues.camera_position,
        uniformValues.camera_up,
        sensitivity,
      );
      break;
    default:
      return;
  }

  event.preventDefault();
  draw();
}

function startDragging(event: MouseEvent): void {
  dragData.startingPoint = { x: event.clientX, y: event.clientY };
  dragData.active = true;
}

function drag(event: MouseEvent): void {
  if (!dragData.active) return;

  const relativeDrag = {
    x: -(event.clientX - dragData.startingPoint.x) / canvasInfo.width,
    y: -(event.clientY - dragData.startingPoint.y) / canvasInfo.height,
  };

  const sensitivity = uniformValues.field_of_view * 2;

  relativeDrag.x *= sensitivity;
  relativeDrag.y *= sensitivity;

  let up = uniformValues.camera_up;
  let newDir = rotateAround(up, relativeDrag.x, uniformValues.camera_direction);
  const right = rotateAround(up, relativeDrag.x, uniformValues.camera_right);

  newDir = rotateAround(right, relativeDrag.y, newDir);
  up = rotateAround(right, relativeDrag.y, up);

  uniformValues.camera_direction = newDir;
  uniformValues.camera_right = right;
  uniformValues.camera_up = up;
  dragData.startingPoint = { x: event.clientX, y: event.clientY };

  draw();
}

function stopDragging(): void {
  dragData.active = false;
}

function handleScroll(event: WheelEvent): void {
  uniformValues.field_of_view *= 1 + Math.sign(event.deltaY) / 30;
  draw();
}

function manualRot(coord: number, delta: number): void {
  const newDir = new Float32Array(uniformValues.camera_direction);

  newDir[coord] += delta;
  uniformValues.camera_direction = newDir;
  draw();
}

function saveImage(canvas: HTMLCanvasElement): void {
  const url = canvas
    .toDataURL("image/png")
    .replace(/^data:image\/[^;]/, "data:application/octet-stream");
  const link = document.getElementById("virtual-link") as HTMLAnchorElement;

  link.href = url;
  link.download = `melion-screenshot-${Math.floor(Date.now() / 1000)}.png`;
  link.click();
  window.URL.revokeObjectURL(url);
}

function initSliders(): void {
  const bind = (
    id: string,
    getValue: () => number,
    setValue: (v: number) => void,
  ) => {
    const slider = document.getElementById(id) as HTMLInputElement;

    slider.value = String(getValue());
    slider.addEventListener("input", (e) => {
      setValue(Number((e.target as HTMLInputElement).value));
      draw();
    });
  };

  bind(
    "slider-shape-modifier",
    () => uniformValues.shape_modifier,
    (v) => {
      uniformValues.shape_modifier = v;
    },
  );
  bind(
    "slider-iteration-count",
    () => uniformValues.iteration_count,
    (v) => {
      uniformValues.iteration_count = v;
    },
  );
  bind(
    "slider-surf-dist",
    () => Math.cbrt(uniformValues.surf_dist),
    (v) => {
      uniformValues.surf_dist = v ** 3;
    },
  );
  bind(
    "slider-glow-intensity",
    () => uniformValues.glow_intensity,
    (v) => {
      uniformValues.glow_intensity = v;
    },
  );
  bind(
    "slider-max-steps",
    () => Math.sqrt(uniformValues.max_steps),
    (v) => {
      uniformValues.max_steps = v ** 2;
    },
  );
  bind(
    "slider-max-dist",
    () => Math.sqrt(uniformValues.max_dist),
    (v) => {
      uniformValues.max_dist = v ** 2;
    },
  );
}

export function init(canvas: HTMLCanvasElement): void {
  canvasInfo = canvas.getBoundingClientRect();

  const context = canvas.getContext("webgl2", { preserveDrawingBuffer: true });

  if (!context) {
    console.error("WebGL2 not supported");

    return;
  }

  gl = context;
  canvas.width = 900;
  canvas.height = 900;
  gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);

  setupWebGL();

  canvas.addEventListener("mousedown", startDragging);
  canvas.addEventListener("mousemove", drag);
  canvas.addEventListener("mouseup", stopDragging);
  canvas.addEventListener("wheel", handleScroll);
  window.addEventListener("keypress", handleKeypress);

  document.getElementById("save-btn")?.addEventListener("click", () => {
    saveImage(canvas);
  });

  const stepSizeInput = document.getElementById(
    "input-step-size",
  ) as HTMLInputElement;

  stepSizeInput.addEventListener("input", (e) => {
    const parsed = Number((e.target as HTMLInputElement).value);
    if (!Number.isNaN(parsed)) stepSize = parsed;
  });

  document
    .querySelectorAll<HTMLButtonElement>("[data-coord]")
    .forEach((btn) => {
      btn.addEventListener("click", () => {
        manualRot(Number(btn.dataset.coord), Number(btn.dataset.delta));
      });
    });

  initSliders();
  updateDisplays();
}
