#version 300 es

precision highp float;

#define AA 1

in vec2 norm_coords;

uniform vec3 camera_position;
uniform vec3 camera_direction;
uniform vec3 camera_right;
uniform vec3 camera_up;

uniform float field_of_view;

uniform float max_steps;
uniform float max_dist;
uniform float surf_dist;
uniform float glow_intensity;

uniform int shape_modifier;
uniform int iteration_count;

uniform int canvas_size;

out vec4 fragmentColor;

// Attempts to do something with the original function. Doesn't really work
// float GetDist(vec3 pos) {

//   // Distance between entities
//   float padding = 0.;
//   padding += 1.;

//   float x = mod(pos.x * 0.5, padding);
//   float y = mod(pos.y * 0.5, padding);
//   float z = mod(pos.z * 0.5, padding);

//   float yy = abs(y - (padding) / 2.) - 0.5;
//   float xx = abs(x - (padding) / 2.) - 0.5;
//   float zz = abs(z - (padding) / 2.) - 0.5;
 
//   float d1 = max(xx, max(yy, zz)); // Distance to the box
//   float d = d1; 
//   float p = shape_modifier;
  
//   for (int i = 1; i <= iteration_count; ++i) {
//     if (i > int(iteration_count)) break;
//     float xa = mod(3. * x * p, 3.);
//     float ya = mod(3. * y * p, 3.);
//     float za = mod(3. * z * p, 3.);

//     p *= float(shape_modifier);

//     float xx = abs(xa - (padding) / 2.) - (padding) / 2.;
//     float yy = abs(ya - (padding) / 2.) - (padding) / 2.; 
//     float zz = abs(za - (padding) / 2.) - (padding) / 2.;
    
//     d1 = min(max(xx, zz), min(max(xx, yy), max(yy, zz))) / p; // Distance inside the 3 axis-aligned square tubes

//     d = max(d, d1); // Intersection
//   }

//   return d;
// }

float GetDist(vec3 pos) {
  float x = pos.x;
  float y = pos.y;
  float z = pos.z;

  // Loop the space so the object is infinitely repeated
  // Currently broken (only when looking in positive direction - why?)
  // x = mod(x * 0.5 + 1., 2.);
  // y = mod(y * 0.5 + 1., 2.);
  // z = mod(z * 0.5 + 1., 2.);

  float xx = abs(x - 0.5) - 0.5;
  float yy = abs(y - 0.5) - 0.5;
  float zz = abs(z - 0.5) - 0.5;
 
  float d1 = max(xx, max(yy, zz)); // Distance to the box
  float d = d1; 
  float p = 1.;
  
  for (int i = 1; i <= iteration_count; ++i) {
    if( i > int(iteration_count)) break;
    float xa = mod(3.0 * x * p, 3.0);
    float ya = mod(3.0 * y * p, 3.0);
    float za = mod(3.0 * z * p, 3.0);
    
    p *= float(int(shape_modifier));

    float xx = 0.5 - abs(xa - 1.5);
    float yy = 0.5 - abs(ya - 1.5); 
    float zz = 0.5 - abs(za - 1.5);
    
    d1 = min(max(xx, zz), min(max(xx, yy), max(yy, zz))) / p; // Distance inside the 3 axis-aligned square tubes

    d = max(d, d1); // Intersection
  }

  return d;
}

vec3 RayMarch(vec3 ro, vec3 rd) {
  // ro = ray origin
  // rd = ray direction
  // dO = distance to origin

  float dO = 0.;
  float min_dist = max_dist;

  for(float steps_num = 0.; steps_num < max_steps; steps_num++) {
    vec3 p = ro + rd * dO;
    float dS = GetDist(p);
    vec3 rp = p + rd * dS;
    dO += dS;
    if (dS < min_dist) min_dist = dS;

    // if(dS < surf_dist) return vec3 (dO, 1, min_dist);
    if(dO > max_dist || dS < surf_dist) return vec3(distance(ro, rp), steps_num, min_dist);
  }

  return vec3(dO, max_steps, min_dist);
}

vec3 GetNormal(vec3 p) {
  float d = 0.;
  vec2 e = vec2(surf_dist * 2., 0);

  vec3 n = d - vec3(
    GetDist(p - e.xyy),
    GetDist(p - e.yxy),
    GetDist(p - e.yyx)
  );

  return normalize(n);
}

float GetLight(vec3 p, float d) {
  // Light source located directly on camera
  vec3 light_pos = camera_position;

  // Light source in a static position
  // vec3 light_pos = vec3(-1, 1, 1);

  // How dark is it in places where light doesn't reach
  float light_lower_bound = .2;

  vec3 l = normalize(light_pos - p);
  vec3 n = GetNormal(p);

  float dif = clamp(dot(n, l), light_lower_bound, 1.);
  float light_fading = .025;

  dif *= exp( - d * light_fading);

  return dif;
}

void main() {  
  vec3 col = vec3(0);

  vec3 forward = normalize(camera_direction);
  vec3 right = normalize(camera_right);
  vec3 up = normalize(camera_up);

  float fov = field_of_view;
  float dist = 0.;
  float steps = 0.;
  float min_dist = 0.;

  vec3 rd;
  float pixel_size = 2. / float(canvas_size);
  float delta = pixel_size / 2.0 / float(AA);

  // With no antialiasing
  rd = normalize(forward + fov * norm_coords.x * right + fov * norm_coords.y * up);
  vec3 ray_info = RayMarch(camera_position, rd);
  dist += ray_info.x;
  steps += ray_info.y;
  min_dist += ray_info.z;

  // With antialiasing
  // for(int i = 1; i <= AA; i++)
  // {
  //   for(int j = 1; j <= AA; j++)
  //   {
  //     rd = normalize(forward + fov * (norm_coords.x + float(i) * delta - pixel_size/2.) * right + fov * (norm_coords.y + float(j) * delta - pixel_size/2.) * up);
  //     vec3 ray_info = RayMarch(camera_position, rd);
  //     dist += ray_info.x;
  //     steps += ray_info.y;
  //     min_dist += ray_info.z;
  //   }
  // }

  // dist /= float(AA*AA);
  // steps /= float(AA*AA);
  // min_dist /= float(AA*AA);

  vec3 p = camera_position + rd * dist;
  float dif = GetLight(p, steps);

  col = vec3(dif);

  // Testing setup
  // fragmentColor = vec4(normalize(vec3(dist, steps / 20., min_dist * 10000.)), 1.0);

  // With glow
  // fragmentColor = vec4(col.x * 2., (col.x + steps / max_steps * glow_intensity) / 2., col.x * 2., 1.0);
  fragmentColor = vec4(steps * 2. / max_steps * glow_intensity, (col.x + steps / max_steps * glow_intensity) / 2., col.x, 1.0);

  // Black & white
  // fragmentColor = vec4(col, 1.0);

  // White & black
  // fragmentColor = vec4(1.0 - col, 1.0);
}
