import strutils
import bspstruct
import times

proc readBSP*(filename: string): q3bspmap =

  var start: float
  start = cpuTime()

  let f = open(filename)

  var
    header: tBSPHeader
    lumps: array[kMaxLumps.int, tBSPLump]
    bsp: q3bspmap


  discard f.readBuffer(header.addr, sizeof(tBSPHeader))
  discard f.readBuffer(lumps.addr, sizeof(lumps))

  var
    num_vertices: int =  lumps[kVertices.int].length div sizeof(tBSPVertex)
    num_indices: int =   lumps[kIndices.int].length div sizeof(int32)
    num_faces: int =     lumps[kFaces.int].length div sizeof(tBSPFace)
    num_textures: int =  lumps[kTextures.int].length div sizeof(tBSPTexture)
    num_lightmaps: int = lumps[kLightmaps.int].length div sizeof(tBSPLightmap)

  bsp.vertices.setLen(num_vertices)
  bsp.indices.setLen(num_indices)
  bsp.faces.setLen(num_faces)
  bsp.textures.setLen(num_textures)
  bsp.lightmaps.setLen(num_lightmaps)

  echo header
  echo "reading vertices"
  discard fseek(f, lumps[kVertices.int].offset, 0)
  for v in 0 ..< num_vertices:
    discard f.readBuffer(bsp.vertices[v].addr, sizeof(tBSPVertex))

  for i in 0 ..< num_vertices:
    var temp: float32 = bsp.vertices[i].vPosition.arr[1]
    bsp.vertices[i].vPosition.arr[1] = bsp.vertices[i].vPosition.arr[2]
    bsp.vertices[i].vPosition.arr[2] = -temp


  echo "reading indices"
  discard fseek(f, lumps[kIndices.int].offset, 0)
  for i in 0 ..< num_indices:
    discard f.readBuffer(bsp.indices[i].addr, sizeof(int32))
  # for i in indices: echo i

  echo "reading faces"
  discard fseek(f, lumps[kFaces.int].offset, 0)
  for v in 0 ..< num_faces:
    discard f.readBuffer(bsp.faces[v].addr, sizeof(tBSPFace))

  echo "reading textures"
  discard fseek(f, lumps[kTextures.int].offset, 0)
  for v in 0 ..< num_textures:
    discard f.readBuffer(bsp.textures[v].addr, sizeof(tBSPTexture))

  echo "reading ", num_lightmaps, " lightmaps"
  discard fseek(f, lumps[kLightmaps.int].offset, 0)
  for v in 0 ..< num_lightmaps:
    discard f.readBuffer(bsp.lightmaps[v].addr, sizeof(tBSPLightmap))

  echo "reading ", filename, " took ", cpuTime() - start, "[s]"

  return bsp

#  nim -d:release --opt:size --passl:"-s" c -r --parallelBuild:4 -o:coreBSP src\coreBSP.nim baseq3\maps\Level.bsp