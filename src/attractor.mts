import { createRenderer, resetCanvasSize } from "@triadica/protea";
import attractorSprite from "../shaders/attractor-sprite.wgsl?raw";
import attractorCompute from "../shaders/attractor-compute.wgsl?raw";

export let loadAttractorRenderer = async (canvas: HTMLCanvasElement) => {
  let seedSize = 2000000;

  let renderFrame = await createRenderer(
    canvas,
    {
      seedSize,
      seedData: makeSeed(seedSize, 0),
      params: loadParams(),
      computeShader: attractorCompute,
    },
    {
      vertexCount: 1,
      vertexData: loadVertex(),
      indexData: [0, 1, 2, 1, 2, 3],
      vertexBufferLayout: vertexBufferLayout,
      renderShader: attractorSprite,
      // topology: "line-list",
      bgColor: [0.1, 0.0, 0.2, 1.0],
    }
  );

  return renderFrame;
};

function rand_middle(n: number) {
  return n * (Math.random() - 0.5);
}

function makeSeed(numParticles: number, scale: number): Float32Array {
  const buf = new Float32Array(numParticles * 8);

  for (let i = 0; i < numParticles; ++i) {
    let b = 8 * i;
    buf[b + 0] = rand_middle(4.8);
    buf[b + 1] = rand_middle(4.8);
    buf[b + 2] = rand_middle(4.8);
    buf[b + 3] = rand_middle(0.8); // ages
    buf[b + 4] = 0;
    buf[b + 5] = 0;
    buf[b + 6] = 0;
    buf[b + 7] = 0; // distance
  }

  return buf;
}

function loadParams(): number[] {
  return [
    0.04, // deltaT
    0.06, // height
    0.004, // width
    0.99, // opacity
  ];
}

function loadVertex(): number[] {
  // prettier-ignore
  return [
    0, 1, 2, 3
    // -0.06, -0.06, -0.03,
    // 0.06, -0.06, -0.03,
    // 0.0, 0.06, 0,
    // 0.0, -0.06, 0.03,
  ];
}

let vertexBufferLayout: GPUVertexBufferLayout[] = [
  {
    // instanced particles buffer
    arrayStride: 8 * 4,
    stepMode: "instance",
    attributes: [
      { shaderLocation: 0, offset: 0, format: "float32x3" },
      { shaderLocation: 1, offset: 3 * 4, format: "float32" },
      { shaderLocation: 2, offset: 4 * 4, format: "float32x3" },
      { shaderLocation: 3, offset: 7 * 4, format: "float32" },
    ],
  },
  {
    // vertex buffer
    arrayStride: 1 * 4,
    stepMode: "vertex",
    attributes: [{ shaderLocation: 4, offset: 0, format: "uint32" }],
  },
];
