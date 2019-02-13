precision highp float;

#define MAX_STEPS 1000
#define MAX_DIST 10000.
#define SURF_DIST .01

varying vec2 norm_coords;

uniform vec3 camera_position;

float GetDist(vec3 p) {
  vec4 s = vec4(4, 4, 4, 1);
  
  float plane_dist = p.y;

  p = vec3(mod(p.x, 8.), mod(p.y, 8.), mod(p.z, 8.));

  float sphere_dist = length(p-s.xyz)-s.w;
    
  float d = sphere_dist;

  return min(d, plane_dist);
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

  vec2 uv = norm_coords;

  vec3 col = vec3(0);

  vec3 ro = camera_position;
  vec3 rd = normalize(vec3(uv.x, uv.y, 1));

  float d = RayMarch(ro, rd);

  vec3 p = ro + rd * d;

  float dif = GetLight(p);
  col = vec3(dif);
  
  gl_FragColor = vec4(col, 1.0);
}
