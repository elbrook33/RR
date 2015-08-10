import Objects
import opengl

proc DrawStep* (scene: Scene) =
  glClear(GL_COLOR_BUFFER_BIT)