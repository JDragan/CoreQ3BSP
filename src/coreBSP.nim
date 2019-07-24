import opengl
import glm
import os
import sequtils, strutils
import coreBSP/[bspfile, q3patch, renderprocs, shaderhelper, sdlhelper]


if paramCount() == 0:
  quit("Please specify BSP map as parameter.\nExample: coreBSP.exe baseq3/maps/q3dm1.bsp")

let mainWindow = sdlinit(800, 600, "coreBSP : Nim")


let appDir = getAppDir()
let ourShader = createAndLinkProgram(appDir&"/shaders/simple.vert",
                                     appDir&"/shaders/simple.frag")

ourShader.use()
ourShader.setInt("TEX",0)
ourShader.setInt("LMAP",1)

var bsp = readBSP( paramStr(1) )

var FACE : RenderableObject
var PATCH : RenderableObject

proc CreateFace(f: int, pos: int) =

  var face = bsp.faces[f]
  var indice_offset : uint32

  for v in 0 ..< face.numOfVerts:
    var vertex = bsp.vertices[face.startVertIndex + v];
    pushVertex(FACE.vertices, pos, vertex)

  if FACE.indices[pos].len == 0:
    indice_offset = 0
  else:
    indice_offset = max(FACE.indices[pos]) + 1

  for j in 0 ..< face.numOfIndices:
    FACE.indices[pos].add((cast[uint32](bsp.indices[j + face.startIndex]) + indice_offset))


proc CreatePatch(index: int, pos: int) =

  var face = bsp.faces[index]
  var patch : tBSPPatch

  var numPatchesWidth = (face.size[0] - 1) shr 1
  var numPatchesHeight = (face.size[1] - 1) shr 1

  patch.bezierpatches.setLen(numPatchesWidth * numPatchesHeight)
  for y in 0 ..< numPatchesHeight:
    for x in 0 ..< numPatchesWidth:
      for row in 0..2:
        for col in 0..2:
          var patchIdx = y * numPatchesWidth + x
          var cpIdx = row * 3 + col

          var vtx_id = bsp.vertices[face.startVertIndex +
            (y * 2 * face.size[0] + x * 2) + row * face.size[0] + col]

          patch.bezierpatches[patchIdx].controlpoints[cpIdx] = vtx_id

  for bzpatch in patch.bezierpatches:
    var bp = Subdivide(bzpatch)
    var indice_offset : uint32

    for vertex in bp.patchVertices:
      pushVertex(PATCH.vertices, pos, vertex)

    if PATCH.indices[pos].len == 0:
      indice_offset = 0
    else:
      indice_offset = max(PATCH.indices[pos]) + 1

    for indice in bp.patchIndices:
      PATCH.indices[pos].add(indice.uint32 + indice_offset)


proc SortFaces() =
  # make pairs
  for f in 0 ..< bsp.faces.len:
    var face = bsp.faces[f]

    var thepair = (face.textureID, face.lightmapID)
    var pos = find(intpairs, thepair)

    if pos == -1: intpairs.add(thepair)

  # set lengths
  FACE.vertices.setLen(intpairs.len)
  FACE.indices.setLen(intpairs.len)
  FACE.buffers.setLen(intpairs.len)
  PATCH.vertices.setLen(intpairs.len)
  PATCH.indices.setLen(intpairs.len)
  PATCH.buffers.setLen(intpairs.len)
  textures_IDs.setLen(bsp.textures.len)
  lightmap_IDs.setLen(bsp.lightmaps.len)
  echo "tPairs size: ", intpairs.len

  # create faces
  for f in 0 ..< bsp.faces.len:
    var face = bsp.faces[f]
    var thepair = (face.textureID, face.lightmapID)
    var pos = find(intpairs, thepair)

    if (bsp.faces[f].facetype != 2):
      CreateFace(f, pos.int)
    else:
      CreatePatch(f, pos.int)


SortFaces()
CreateBuffers(FACE)
CreateBuffers(PATCH)
loadLightmaps(bsp.lightmaps)
loadTextures(bsp.name, bsp.textures)

defaultGLsetup()
SDLshowWindow(mainWindow)

while run:
  Update()

  glClearColor(0.055, 0.066, 0.1, 1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

  TransformCamera(ourShader.GLuint)

  renderFaces(FACE)
  renderFaces(PATCH)

  SwapBuffers()
