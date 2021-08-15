import glm
import os
import coreBSP/[renderprocs, world, shaderhelper, sdlhelper, camera_util]


if paramCount() == 0:
  quit("Please specify BSP map as parameter.\nExample: coreBSP.exe baseq3/maps/q3dm1.bsp")

let mainWindow = sdlinit(800, 600, "coreBSP : Nim")
let mainCamera = newCamera(vec3(0.0'f32, 600.0'f32, 0.0'f32))
let mainShader = initShaders()

let bsp = loadBsp(paramStr(1))

defaultGLsetup()
SDLshowWindow(mainWindow)

while run:
  Update(mainCamera)

  renderBackground()

  TransformCamera(mainShader, mainCamera)

  renderFaces(bsp.faces)
  renderFaces(bsp.patches)

  SwapBuffers()
