import GLBoilerplate as GL

import opengl

type vec4   = array[0..3, float]
type Ray    = array[0..3, vec4]
type Vertex = array[0..2, float]

type Scene* = tuple
  background: GLuint
  cameraRays: GLuint
  rayBuffers: array[0..1, GLuint]
# rayMaker:   GLuint
  rayTracer:  GLuint
# objects:    array[0..5, GLuint] # groups, surfaces, triangles, vertices + 2*indices

var everything*: Scene

proc Initialize* (w: int, h: int, angle: float) =
  everything = (
    background: GL.cubeMap(),
    cameraRays: GL.buffer(),
    rayBuffers: [GL.buffer(), GL.buffer()],
#   rayMaker:   GL.shader(),
    rayTracer:  GL.shader() )
#   objects:    GL.texBuffer()