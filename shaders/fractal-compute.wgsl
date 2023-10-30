struct Particle {
  pos: vec3<f32>,
  ages: f32,
  prev_pos: vec3<f32>,
  distance: f32,
}

struct Params {
  delta_t: f32,
  height: f32,
  width: f32,
  opacity: f32,
}

struct Particles {
  particles: array<Particle>,
}

@binding(0) @group(0) var<uniform> params: Params;
@binding(1) @group(0) var<storage, read> particles_a: Particles;
@binding(2) @group(0) var<storage, read_write> particles_b: Particles;

const tau = 10f;
const rou = 28f;

struct LorenzResult {
  position: vec3f,
  velocity: vec3f,
  distance: f32,
}

fn lorenz(p: vec3f, dt: f32) -> LorenzResult {
  let beta = 8.0 / 3.0;
  let dx = tau * (p.y - p.x);
  let dy = p.x * (rou - p.z) - p.y;
  let dz = p.x * p.y - beta * p.z;
  let d = vec3<f32>(dx, dy, dz) * dt;
  return LorenzResult(
    p + d,
    vec3(dx,dy,dz),
    length(d) * 2.1
  );
}


fn sprott(p: vec3f, dt: f32) -> LorenzResult {
  const a = 2.07;
  const b = 1.79;
  let x = p.x;
  let y = p.y;
  let z = p.z;
  let dx = y + a*x*y + x*z;
  let dy = 1.0 - b*x*x + y*z;
  let dz = x - x*x - y * y;
  let d = vec3<f32>(dx, dy, dz) * dt;
  return LorenzResult(
    p + d,
    vec3(dx,dy,dz),
    length(d) * 10.1
  );
}

/// https://www.dynamicmath.xyz/strange-attractors/
fn four_wing(p: vec3f, dt: f32) -> LorenzResult {
  const a = 0.2;
  const b = 0.01;
  const c = -0.4;
  let x = p.x;
  let y = p.y;
  let z = p.z;
  let dx = a * x + y * z;
  let dy = b * x + c*y - x*z;
  let dz = - z - x*y;
  var d = vec3<f32>(dx, dy, dz) * dt;
  // let dl = length(d);
  // if (dl > 0.2) {
  //   d = d / dl * 0.2;
  // } else if (dl < 0.01) {
  //   d = d / dl * 0.01;
  // }
  var next = p + d;
  if (length(next) > 100.0) {
    next = vec3(0.1);
  }
  return LorenzResult(
    next,
    vec3(dx,dy,dz),
    length(d) * 8.8
  );
}

/// ok
fn aizawa(p: vec3f, dt: f32) -> LorenzResult {
  let a = 0.95;
  let b = 0.7;
  let c = 0.6;
  let d0 = 3.5;
  let e = 0.25;
  let f = 0.1;

  let x = p.x;
  let y = p.y;
  let z = p.z;

  let dx = (z-b)*x - d0*y;
  let dy = d0*x + (z-b)*y;
  let dz = c + a*z - pow(z,3.0)/3.0 - (x*x+y*y)*(1.+e*z)+f*z*pow(x,3.0);

  var d = vec3<f32>(dx, dy, dz) * dt * 10.;
  // let dl = length(d);
  // if (dl > 0.2) {
  //   d = d / dl * 0.2;
  // } else if (dl < 0.01) {
  //   d = d / dl * 0.01;
  // }
  let next = p + d;
  // if (length(next) > 100.0) {
  //   next = vec3(0.1);
  // }
  return LorenzResult(
    next,
    vec3(dx,dy,dz),
    length(d) * 8.8
  );
}


fn rand(n: f32) -> f32 { return fract(sin(n) * 43758.5453123); }

// https://github.com/austinEng/Project6-Vulkan-Flocking/blob/master/data/shaders/computeparticles/particle.comp
@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) GlobalInvocationID: vec3<u32>) {
  var index = GlobalInvocationID.x;

  var v_pos = particles_a.particles[index].pos;
  // let dd = floor(f32(index) / 80.0);

  let inner_idx = f32(index % 24u);
  let group_idx = floor(f32(index) / 24.0);

  if (index % 24u != 0u) {
    let prev = index - 1u;
    particles_b.particles[index].pos = particles_a.particles[prev].pos;
    // particles_b.particles[index].ages = particles_a.particles[prev].ages;
    particles_b.particles[index].ages = inner_idx;
    particles_b.particles[index].prev_pos = particles_a.particles[prev].prev_pos;
    // particles_b.particles[index].distance = particles_a.particles[prev].distance;
    particles_b.particles[index].distance = group_idx;
    return;
  }

  // let ret = lorenz(v_pos, params.delta_t * 0.01 * (2. + 2. * rand(f32(index))));
  // let ret = four_wing(v_pos, params.delta_t * 0.01 * (20. + 2. * rand(f32(index))));
  let ret = aizawa(v_pos, params.delta_t * 0.001 * (12. + 4. * rand(f32(index))));

  // let ret = lorenz(v_pos, params.delta_t * 0.2);
  // let ret = chen(v_pos, params.delta_t * 0.8);

  // Write back
  particles_b.particles[index].pos = ret.position;
  particles_b.particles[index].ages = inner_idx;
  particles_b.particles[index].prev_pos = v_pos;
  // particles_b.particles[index].distance += ret.distance;
  particles_b.particles[index].distance = group_idx;

}
