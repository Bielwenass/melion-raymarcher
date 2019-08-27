#version 300 es

precision highp float;

#define MAX_STEPS 1000.
#define MAX_DIST 1000.
#define SURF_DIST .0000005

#define SIZE 850

#define AA 1

in vec2 norm_coords;

uniform vec3 camera_position;
uniform vec3 camera_direction;
uniform vec3 camera_right;
uniform vec3 camera_up;
uniform float field_of_view;

out vec4 fragmentColor;

// float GetDist(vec3 w) {
//   return sin(w.x)-cos(w.y)-cos(w.z);
// }

// float GetDist(vec3 z) {
//   const int Iterations = 15;
//   float Offset = 1.;
//   float Scale = 2.1;
//   float r;
//   int i = 0;
//   for (int n = 0; n < Iterations; n++) {
//     if(z.x+z.y<0.) z.xy = -z.yx; // fold 1
//     if(z.x+z.z<0.) z.xz = -z.zx; // fold 2
//     if(z.y+z.z<0.) z.zy = -z.yz; // fold 3
//     z = z*Scale - Offset*(Scale-1.0);
//     i = n;
//   }
//   return (length(z) ) * pow(Scale, -float(i));
// }

float GetDist(vec3 pos) {
  int Iterations = 32;
  int Modifier = -5;

  // pos = vec3(mod(pos.x, 8.), mod(pos.y, 8.), mod(pos.z, 8.));
  //by recursively digging a box
  float x = pos.x;
  float y = pos.y;
  float z = pos.z;
  
  x = mod(x * 0.5 + 1., 1.);
  y = mod(y * 0.5 + 1., 1.);
  z = mod(z * 0.5 + 1., 1.); 

  float xx = abs(x-0.5)-0.5;
  float yy = abs(y-0.5)-0.5;
  float zz = abs(z-0.5)-0.5;
 
  float d1 = max(xx, max(yy, zz)); //distance to the box
  float d = d1; 
  float p = 1.0;
  
  int maxIter = int(Iterations);
  
  for (int i=1; i<=5; ++i) 
  {
    if( i > int(Iterations)) break;
    float xa = mod(3.0*x*p, 3.0);
    float ya = mod(3.0*y*p, 3.0);
    float za = mod(3.0*z*p, 3.0);
    
    //p*=3.0;
    p *= float(int(Modifier));

    float xx = 0.5-abs(xa - 1.5);
    float yy = 0.5-abs(ya - 1.5); 
    float zz = 0.5-abs(za - 1.5);
    
    d1 = min(max(xx, zz), min(max(xx, yy), max(yy, zz))) / p; //distance inside the 3 axis-aligned square tubes

    d = max(d, d1); //intersection
  }

  return d;
}

// float GetDist(vec3 z) {
//   const int Iterations = 20;
//   float Offset = 1.;
//   float Scale = 2.1;
//   vec3 a1 = vec3(1,1,1);
//   vec3 a2 = vec3(-1,-1,1);
//   vec3 a3 = vec3(1,-1,-1);
//   vec3 a4 = vec3(-1,1,-1);
//   vec3 c;
//   int i = 0;
//   float dist, d;
//   for (int n = 0; n < Iterations; n++) {
//     c = a1; dist = length(z-a1);
//     d = length(z-a2); if (d < dist) { c = a2; dist=d; }
//     d = length(z-a3); if (d < dist) { c = a3; dist=d; }
//     d = length(z-a4); if (d < dist) { c = a4; dist=d; }
//     z = Scale*z-c*(Scale-1.0);
//     i = n;
//   }

//   return length(z) * pow(Scale, float(-i));
// }

// float GetDist(vec3 p) {
//   vec4 s = vec4(4, 4, 4, 6);

//   float plane_distX = p.y;
//   float plane_distY = -(p.x - 4.);
//   float plane_distY2 = p.x + 4.;

//   p = vec3(mod(p.x, 8.), mod(p.y, 8.), mod(p.z, 8.));

//   float sphere_dist = -(length(p-s.xyz)-s.w);

//   float d = sphere_dist;

//   return d;
//   // return min(d, min(plane_distX, min(plane_distY, plane_distY2)));
// }

vec3 RayMarch(vec3 ro, vec3 rd) {
  float dO=0.;
  float min_dist = MAX_DIST;

  for(float i = 0.; i<MAX_STEPS; i++) {
    vec3 p = ro + rd*dO;
    float dS = GetDist(p);
    dO += dS;
    if (dS < min_dist) min_dist = dS;
    // if(dO>MAX_DIST) return normalize(vec3(dO / MAX_DIST, 0, i));
    // if(dS<SURF_DIST) return normalize(vec3 (0, 1, 0));
    if(dO>MAX_DIST || dS<SURF_DIST) return vec3(dO, i, min_dist);
  }

  // return vec3(0, 0, 1);
  return vec3(dO, MAX_STEPS, min_dist);
}

vec3 GetNormal(vec3 p) {
  float d = 0.;
  vec2 e = vec2(SURF_DIST * 2., 0);

  vec3 n = d - vec3(
    GetDist(p-e.xyy),
    GetDist(p-e.yxy),
    GetDist(p-e.yyx)
  );

  return normalize(n);
}

float GetLight(vec3 p, float d) {
  vec3 lightPos = camera_position;
  // vec3 lightPos = vec3(-1, 1, 1);
  vec3 l = normalize(lightPos-p);
  vec3 n = GetNormal(p);

  float dif = clamp(dot(n, l), 1., 1.);
  float light_fading = .03;

  dif *= exp( - d * light_fading);

  return dif;
}

void main() {  
  vec3 col = vec3(0);

  vec3 forward = normalize(camera_direction);
  vec3 right = normalize(camera_right);
  vec3 up = normalize(camera_up);

  float fov = field_of_view;
  float dist =0.;
  float steps = 0.;
  float min_dist = 0.;

  vec3 rd;
  float pixel_size = 2. / float(SIZE);
  float delta = pixel_size / 2.0 / float(AA);

  // --- with no antialiasing ---
  // rd = normalize(forward + fov * norm_coords.x * right + fov * norm_coords.y * up);
  // vec3 ray_info = RayMarch(camera_position, rd);
  // dist += ray_info.x;
  // steps += ray_info.y;
  // min_dist += ray_info.z;

  for(int i = 1; i <= AA; i++)
  {
    for(int j = 1; j <= AA; j++)
    {
      rd = normalize(forward + fov * (norm_coords.x + float(i) * delta - pixel_size/2.) * right + fov * (norm_coords.y + float(j) * delta - pixel_size/2.) * up);
      vec3 ray_info = RayMarch(camera_position, rd);
      dist += ray_info.x;
      steps += ray_info.y;
      min_dist += ray_info.z;
    }
  }

  dist /= float(AA*AA);
  steps /= float(AA*AA);
  min_dist /= float(AA*AA);

  vec3 p = camera_position + rd * dist;

  float dif = GetLight(p, steps);
  col = vec3(dif);

  // fragmentColor = vec4(dist, dist, min_dist, 1.0);
  // fragmentColor = vec4(normalize(vec3(dist, steps, min_dist * 1000.)), 1.0);
  fragmentColor = vec4(col.x, steps / 2000., steps / 2000., 1.0);
}
