import opengl
import glm
import os
import strutils
import coreBSP/[bspfile, q3patch, renderprocs, shaderhelper, sdlhelper, camera_util]


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

proc CreateFace(f: int, pos: int) =

  let face = bsp.faces[f]
  var indice_offset : uint32

  for v in 0 ..< face.numOfVerts: # fill vertices
    let vertex = bsp.vertices[face.startVertIndex + v];
    pushVertex(FACE.vertices, pos, vertex)

  if FACE.indices[pos].len == 0: # calc indice offset
    indice_offset = 0
  else:
    indice_offset = max(FACE.indices[pos]) + 1

  for j in 0 ..< face.numOfIndices: # fill indices
    FACE.indices[pos].add((bsp.indices[j + face.startIndex]).uint32 + indice_offset)

  FACE.texPair[pos].a = textures_IDs[face.textureID] # set texture ids
  if intpairs[pos].b >= 0:
    FACE.texPair[pos].b = lightmap_IDs[face.lightmapID]
  else:
    FACE.texPair[pos].b = lightmap_IDs[lightmap_IDs.high] # missing lightmap id=1

proc CreatePatch(index: int, pos: int) =

  let face = bsp.faces[index]
  var patch : tBSPPatch

  let numPatchesWidth = (face.size[0] - 1) shr 1
  let numPatchesHeight = (face.size[1] - 1) shr 1

  patch.bezierpatches.setLen(numPatchesWidth * numPatchesHeight)
  for y in 0 ..< numPatchesHeight:
    for x in 0 ..< numPatchesWidth:
      for row in 0..2:
        for col in 0..2:
          let patchIdx = y * numPatchesWidth + x
          let cpIdx = row * 3 + col

          let vtx_id = bsp.vertices[face.startVertIndex +
            (y * 2 * face.size[0] + x * 2) + row * face.size[0] + col]

          patch.bezierpatches[patchIdx].controlpoints[cpIdx] = vtx_id

  for bzpatch in patch.bezierpatches:
    let bp = Subdivide(bzpatch)
    var indice_offset : uint32

    for vertex in bp.patchVertices:
      pushVertex(PATCH.vertices, pos, vertex)

    if PATCH.indices[pos].len == 0:
      indice_offset = 0
    else:
      indice_offset = max(PATCH.indices[pos]) + 1

    for indice in bp.patchIndices:
      PATCH.indices[pos].add(indice.uint32 + indice_offset)

  PATCH.texPair[pos].a = textures_IDs[face.textureID]
  if intpairs[pos].b >= 0:
    PATCH.texPair[pos].b = lightmap_IDs[face.lightmapID]
  else: PATCH.texPair[pos].b = lightmap_IDs[lightmap_IDs.high]


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
      CreateFace(f, pos.int)
    else:
      CreatePatch(f, pos.int)


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
