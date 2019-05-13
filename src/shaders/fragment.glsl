precision highp float;

#define MAX_STEPS 1000
#define MAX_DIST 10000.
#define SURF_DIST .005

varying vec2 norm_coords;

uniform vec3 camera_position;
uniform vec3 camera_direction;
uniform vec3 camera_right;
uniform vec3 camera_up;

float GetDist(vec3 p) {
  vec4 s = vec4(4, 4, 4, 6);

  float plane_distX = p.y;
  float plane_distY = -(p.x - 4.);
  float plane_distY2 = p.x + 4.;

  p = vec3(mod(p.x, 8.), mod(p.y, 8.), mod(p.z, 8.));

  float sphere_dist = -(length(p-s.xyz)-s.w);
    
  float d = sphere_dist;

  return d;
  // return min(d, min(plane_distX, min(plane_distY, plane_distY2)));
}

float RayMarch(vec3 ro, vec3 rd) {
  float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
      vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || dS<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
  float d = GetDist(p);
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(0, 5, 6);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l);
    if(d<length(lightPos-p)) dif *= .4;
    
    return dif;
}

void main() {

  vec3 col = vec3(0);

  vec3 forward = normalize(camera_direction);
  vec3 right = normalize(camera_right);
  vec3 up = normalize(camera_up);

  float fov = 0.70;

  vec3 rd = normalize(forward + fov * norm_coords.x * right + fov * norm_coords.y * up);

  float d = RayMarch(camera_position, rd);

  vec3 p = camera_position + rd * d;

  float dif = GetLight(p);
  col = vec3(dif);

  gl_FragColor = vec4(col, 1.0);
}
