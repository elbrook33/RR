import opengl

proc cubeMap*: GLuint =
  0.GLuint

proc shader*: GLuint =
  0.GLuint

proc buffer*: GLuint =
  0.GLuint #GL_DYNAMIC_COPY

# proc texBuffer*: GLuint =
#   0.GLuint
#
# proc texture*: GLuint =
#   0.GLuint

proc compute* =
  return

proc draw* =
  glClear(GL_COLOR_BUFFER_BIT)
