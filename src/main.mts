import { setupInitials } from "@triadica/protea";

import { loadAttractorRenderer } from "./attractor.mjs";
import { loadFractalRenderer } from "./fractal.mjs";

const paramsString = location.search.slice(1);
const searchParams = new URLSearchParams(paramsString);

let shape = (searchParams.get("shape") || "attractor") as
  | "attractor"
  | "fractal";

let instanceRenderer: Awaited<
  ReturnType<Awaited<typeof loadAttractorRenderer>>
>;

let canvas = document.querySelector("#canvas-container") as HTMLCanvasElement;

window.__skipComputing = false;

window.onload = async () => {
  await setupInitials(canvas);

  if (shape === "fractal") {
    instanceRenderer = await loadFractalRenderer(canvas);
  } else {
    instanceRenderer = await loadAttractorRenderer(canvas);
  }

  let t = 0;
  let renderer = () => {
    t++;
    setTimeout(() => {
      requestAnimationFrame(renderer);
    }, 10);
    if (!window.stopped) {
      instanceRenderer(t, window.__skipComputing);
    }
  };

  renderer();
};

if (import.meta.hot) {
  // newModule is undefined when SyntaxError happened
  import.meta.hot.accept("./attractor.mjs", async (newModule) => {
    if (newModule && shape === "attractor") {
      instanceRenderer = await newModule.loadAttractorRenderer(canvas);
    }
  });

  import.meta.hot.accept("./fractal.mjs", async (newModule) => {
    if (newModule && shape === "fractal") {
      instanceRenderer = await newModule.loadFractalRenderer(canvas);
    }
  });
}
