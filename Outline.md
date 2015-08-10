Loading
=======
* Load cube maps.
- Mipmap cube maps.
- Create rays from cube maps.
	Create n rays per bright spot until maximum number is reached.
+ Load vertices. (And surfaces and groups.)
- Calculate normals for vertices.

OpenGL objects
==============
+ Arrays: groups, surfaces, triangles and vertices.
- Indices: group -> surfaces, surface -> triangles.
- Textures: light maps (per surface or a big shared one. Max is low as 16).
* Buffers:
	* Rays (camera, lights, 2 x alternating bounces)
	- Pixels (extra pass so points can become ovals?)
* Shaders

Pass 1 (light tracing)
======================
- Create rays from emission surfaces.
	(Emit rays from points via geometry shader.)
- Find intersecting triangles.
- Draw into surface’s lighting texture. (Circles? Squares?)
  Size = angle (or separation) * distance. Problematic mapping UVs to geometry (if size too big). Needs distorting by ray vs normal.
  Alpha = R^2 / 3*distance^2 (or 3*width^2) * scatter.
- Bounce rays and repeat.

Pass 2 (view tracing)
=====================
* Create rays from camera, with offset copies for aperture and depth of field.
	(Emit rays from rectangles via geometry shader.)
+ Find intersecting triangles.
 Calculate colour based on intersection (blur background if scattering).
+ Mix (scatter/2 * light map) with (1 - scatter/2) * bounces.
+ Bounce rays and repeat.

* Version 1
+ Version 2
- Version 3