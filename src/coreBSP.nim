import opengl
import glm
import os
import coreBSP/[bspfile, renderprocs, world, shaderhelper, sdlhelper, camera_util]


if paramCount() == 0:
  quit("Please specify BSP map as parameter.\nExample: coreBSP.exe baseq3/maps/q3dm1.bsp")

let appDir = getAppDir()

let mainWindow = sdlinit(800, 600, "coreBSP : Nim")
let mainCamera = newCamera(vec3(0.0'f32, 600.0'f32, 0.0'f32))
let mainShader = createAndLinkProgram(
  appDir&"/shaders/simple.vert",
  appDir&"/shaders/simple.frag"
  )

mainShader.use()
mainShader.setInt("TEX",0)
mainShader.setInt("LMAP",1)

var bsp = readBSP( paramStr(1) )
var FACE : RenderableObject
var PATCH : RenderableObject

SortFaces(bsp.addr, FACE.addr, PATCH.addr)

CreateBuffers(FACE)
CreateBuffers(PATCH)

defaultGLsetup()
SDLshowWindow(mainWindow)

while run:
  Update(mainCamera)

  glClearColor(0.055, 0.066, 0.1, 1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

  TransformCamera(mainShader, mainCamera)

  renderFaces(FACE)
  renderFaces(PATCH)

  SwapBuffers()
