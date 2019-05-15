precision highp float;

#define MAX_STEPS 1000.
#define MAX_DIST 10000.
#define SURF_DIST .0005

#define SIZE 900

#define AA 5

varying vec2 norm_coords;

uniform vec3 camera_position;
uniform vec3 camera_direction;
uniform vec3 camera_right;
uniform vec3 camera_up;


float GetDist(vec3 z) {
  const int Iterations = 20;
  float Offset = 1.;
  float Scale = 2.;
  float r;
  int i = 0;
  for (int n = 0; n < Iterations; n++) {
    if(z.x+z.y<0.) z.xy = -z.yx; // fold 1
    if(z.x+z.z<0.) z.xz = -z.zx; // fold 2
    if(z.y+z.z<0.) z.zy = -z.yz; // fold 3
    z = z*Scale - Offset*(Scale-1.0);
    i = n;
  }
  return (length(z) ) * pow(Scale, -float(i));
}

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

vec2 RayMarch(vec3 ro, vec3 rd) {
  float dO=0.;


  for(float i = 0.; i<MAX_STEPS; i++) {
    vec3 p = ro + rd*dO;
    float dS = GetDist(p);
    dO += dS;
    if(dO>MAX_DIST || dS<SURF_DIST) return vec2(dO, i);
  }

  return vec2(dO, MAX_STEPS);
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
  vec3 l = normalize(lightPos-p);
  vec3 n = GetNormal(p);

  float dif = clamp(dot(n, l), 0.7, 1.);
  float light_fading = .05;

  dif *= exp( - d * light_fading);

  return dif;
}

void main() {
   
  vec3 col = vec3(0);

 
  
  vec3 forward = normalize(camera_direction);
  vec3 right = normalize(camera_right);
  vec3 up = normalize(camera_up);

  float fov = 0.70;
  float dist =0.;
  float steps = 0.;

  vec3 rd;
  float pixel_size = 2. / float(SIZE);
  float delta = pixel_size / 2.0 / float(AA);
  
  for(int i = 1; i <= AA; i++)
  {
    for(int j = 1; j <= AA; j++)
    {
      rd = normalize(forward + fov * (norm_coords.x + float(i) * delta - pixel_size/2.) * right + fov * (norm_coords.y + float(j) * delta - pixel_size/2.) * up);
      vec2 ray_info = RayMarch(camera_position, rd);
      dist += ray_info.x;
      steps +=  ray_info.y;
    }
  }
  dist /= float(AA*AA);
  steps /= float(AA*AA);

  vec3 p = camera_position + rd * dist;

  float dif = GetLight(p, steps);
  col = vec3(dif);

  gl_FragColor = vec4(col, 1.0);
}
