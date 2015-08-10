import Objects
import Loop
import glfw3 as glfw
import opengl

var window: Window
var w = 640, h = 400, angle = 45.0

proc Initialize =
  loadExtensions()
  doAssert glfw.Init() != 0
  
proc CreateWindow =
  window = glfw.CreateWindow(w, h, "GLFW WINDOW", nil, nil)
  glfw.MakeContextCurrent(window)

proc MainLoop =
  while glfw.WindowShouldClose(window) == 0:
    Loop.DrawStep(Objects.everything)
    glfw.SwapBuffers(window)
    glfw.PollEvents()
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == 1:
      glfw.SetWindowShouldClose(window, 1)

proc Finish =
  glfw.DestroyWindow(window)
  glfw.Terminate()

Initialize()
CreateWindow()
Objects.Initialize(w, h, angle)
MainLoop()
Finish()