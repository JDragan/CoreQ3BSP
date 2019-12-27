import opengl
import glm
import os
import strutils
import coreBSP/[bspfile, renderprocs, world, shaderhelper, sdlhelper, camera_util]


if paramCount() == 0:
  quit("Please specify BSP map as parameter.\nExample: coreBSP.exe baseq3/maps/q3dm1.bsp")

let appDir = getAppDir()

let mainWindow = sdlinit(800, 600, "coreBSP : Nim")
let mainCamera = newCamera(vec3(0.0'f32, 600.0'f32, 0.0'f32))
let mainShader = createAndLinkProgram(appDir&"/shaders/simple.vert",
                                     appDir&"/shaders/simple.frag")

mainShader.use()
mainShader.setInt("TEX",0)
mainShader.setInt("LMAP",1)

var bsp = readBSP( paramStr(1) )

var FACE : RenderableObject
var PATCH : RenderableObject


proc SortFaces() =
  for f in 0 ..< bsp.faces.len: # make pairs
    let face = bsp.faces[f]

    let thepair = (face.textureID, face.lightmapID)
    var pos = find(intpairs, thepair)

    if pos == -1: intpairs.add(thepair)

  # set lengths
  FACE.vertices.setLen(intpairs.len)
  FACE.indices.setLen(intpairs.len)
  FACE.buffers.setLen(intpairs.len)
  FACE.texPair.setLen(intpairs.len)

  PATCH.vertices.setLen(intpairs.len)
  PATCH.indices.setLen(intpairs.len)
  PATCH.buffers.setLen(intpairs.len)
  PATCH.texPair.setLen(intpairs.len)

  textures_IDs.setLen(bsp.textures.len)
  lightmap_IDs.setLen(bsp.lightmaps.len)
  # echo "tPairs size: ", intpairs.len

  loadLightmaps(bsp.lightmaps)
  loadTextures(bsp.name, bsp.textures)

  # create faces
  for f in 0 ..< bsp.faces.len:
    let face = bsp.faces[f]
    let thepair = (face.textureID, face.lightmapID)
    let pos = find(intpairs, thepair)

    if (bsp.faces[f].facetype != 2):
      CreateFace(f, pos.int, bsp, FACE.addr)
    else:
      CreatePatch(f, pos.int, bsp, PATCH.addr)


SortFaces()

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
