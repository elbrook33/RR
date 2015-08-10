/*
  * -------------------------
  * Vertex shader: Trace rays
  * -------------------------
  * - Find the nearest triangle in a ray’s path.
  * - Pass along intersection details to geometry shader for scattering.
  */

in  vec4 ray[4]; // pos/size, dir/scatter, color/alpha, pixel/IOR/0
out vec4 intersection[5]; // pos/size, ray/scatter, color/a, pixel/2*IOR, normal/0
out vec4 pixel[2]; // For the bounceless. color/a, pixel/surface/size
uniform samplerBuffer groups,    index_g_to_s,
                      surfaces,  index_s_to_t,
                      triangles, vertices;
uniform int g_num, g_size, gi_size, s_size, si_size;
uniform float far;
uniform samplerCube background;
uniform sampler2D light_map;
uniform bool light_pass;

//
// Vector math
float adjL(vec3 H, vec3 Ua) { return dot(H, Ua);              }
vec3  adj (vec3 H, vec3 Ua) { return Ua*adjL(H, Ua);          }
float oppL(vec3 H, vec3 Ua) { return length(cross(H, Ua));    }
vec3  opp (vec3 H, vec3 Ua) { return cross(Ua, cross(H, Ua)); }
vec3 uOpp (vec3 H, vec3 Ua) { return normalize(opp(H, Ua));   }
vec3 common_plane    (vec3 A, vec3 B) { return cross(A, B);   }
vec3 intersect_planes(vec3 A, vec3 B) { return cross(A, B);   }
vec3[2] intersect_lines(vec3 p1, vec3 dir1, vec3 p2, vec3 dir2) {
  float u = length(cross(dir2, p1-p2)) / length(cross(dir2, dir1));
  vec3  p = p1 + u*dir1;
  float v = length(p - p2);
  return { p, vec3(u, v, 0.0) };
}
vec3 unit_ortho(vec3 U, vec3 coplanar) { return normalize(cross( U, cross(U, coplanar) )); }
vec2 pointUV_in_triangle(vec3 t[3], vec3 p) {
  vec3 ortho1 = unit_ortho( t[1], t[2] );
  vec3 r      = p - t[0];
  float v     = dot( r, ortho1 ) / dot( t[2], ortho1 ) * length( t[2] );
  float u     = length( r - v*normalize(t[2]) ) / length(t[1]);
  return vec2( u, v );
}

//
// Texel helpers
float   get(int i, samplerBuffer b) { return texelFetch( b, i ).r;   }
vec3   get3(int i, samplerBuffer b) { return texelFetch( b, i ).rgb; }
int    geti(int i, samplerBuffer b) { return texelFetch( b, i ).r;   }
ivec2 get2i(int i, samplerBuffer b) { return texelFetch( b, i ).rg;  }
ivec3 get3i(int i, samplerBuffer b) { return texelFetch( b, i ).rgb; }

//
// Interpret intersection results
void finalize_with_matched_triangle( int surface, int triangle, vec2 UV ) {
  if( triangle == -1 ) { // No hits: sample cube map (with LOD).
    pixel[color] = ray[color] * textureLod(background, ray[dir], /* Calculate LOD */);
  } else if( get(surface + emission, surfaces) > 0.0 ) { // Emission: grab color.
    pixel[color] = ray[color] * get3(surface + s_color, surfaces);
  } else { // Diffuse/glossy triangle: interpolate.
    ivec3 v         =   get3i( triangle, triangles );
    vec3[3] normals = { get3( v.x + 1, vertices ),
                        get3( v.y + 1, vertices ),
                        get3( v.z + 1, vertices ) };
    intersection[normal] =
      normalize( mix( normals[0], mix(normals[1], normals[2], 0.5*(UV.y - UV.x + 1.0)), UV.x + UV.y ) );
    // Incorporate roundness parameter.
    // Write out.
    intersection[dir]     = ray[dir];
    intersection[color]   = ray[color] * get3( surface + s_color, surfaces );
    intersection[pixa]    = ray[pixa];
    intersection[scatIOR] = vec3(
      clamp( ray[scatIOR].s + get( surface + s_scatter, surfaces ), 0.0, 1.0 ),
      ray[scatIOR].y, // IOR_from
      get( surface + s_IOR, surfaces ) ); // IOR_to
    if( light_pass ) {
      float a = light_size*light_size / z*z
      float R = tan(scatter*M_PI)*z;
      pixel[color] = ...
}}}

//
// Triangle-ray collision
vec3 intersect_triangles( ivec2 indices, float nearest_z, inout int t_hit ) {
  // Set up record for best hit.
  vec3 best_UVZ = vec3( 0.0, 0.0, nearest_z );
  for( int i=indices.x; i <= indices.y; i++ ) {
    // Load triangle.
    ivec3 verts = get3i( i, triangles );
    vec3[3]  t  = { get3(verts.x, vertices),
             t[0] - get3(verts.y, vertices),
             t[0] - get3(verts.z, vertices) };
    vec3[2] hit = intersect_lines(
      ray[pos], ray[dir],
      t[0], intersect_planes( common_plane(ray[dir], t[0]-ray[pos]), common_plane(t[1], t[2]) ));
    float z = hit[1].s;
    if(z <= 0.0) continue;
    if(z < nearest_z) {
      vec2 UV = pointUV_in_triangle( t, hit[0] );
      if( UV > vec2(0.0, 0.0) && UV.x + UV.y <= 1.0 ) {
        // Record as current best hit.
        t_hit             = i;
        best_UVZ          = vec3( UV, z );
        intersection[pos] = hit[0];
  }}}
  return best_UVZ;
}

//
// Surface-ray collision
void intersect_surfaces( ivec2 indices, float nearest_z, inout ivec2 s_hit ) {
  vec3 best_UVZ = vec3( 0.0, 0.0, nearest_z );
  for( int s=indices.x; s <= indices.y; s++ ) {
    vec3 center = get3( s*s_size, surfaces );
    vec3 bounds = get3( s*s_size+3, surfaces );
    if( abs(opp( center-ray[pos], ray[dir] )) < bounds ) {
      int hit  = -1;
      vec3 UVZ = intersect_triangles( get2i(s*si_size, index_s_to_t), best_UVZ.z, hit );
      if( hit != -1 ) {
        best_UVZ = UVZ;
        s_hit = ivec2( s, hit );
  }}}
  return best_UVZ;
}

//
// Group-ray collision
void main() {
  ivec2 best_hit = ivec2( -1 ); // group, surface, triangle
  vec3 best_UVZ  = vec3( 0.0, 0.0, far );
  for( int g=0; g < g_num; g++ ) {
    vec3 center = get3( g*g_size, groups );
    vec3 bounds = get3( g*g_size+3, groups );
    if( abs(opp( center-ray[pos], ray[dir] )) < bounds ) {
      ivec2 s_hit = ivec2( -1 );
      vec3 UVZ = intersect_surfaces( get2i(g*gi_size, index_g_to_s), UVZ.z, s_hit );
      if( s_hit.s != -1 ) {
        best_UVZ = UVZ;
        best_hit = s_hit;
  }}}
  finalize_with_matched_triangle( best_hit.s*s_size, best_hit.t );
}
