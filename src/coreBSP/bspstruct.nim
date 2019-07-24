import glm


proc fseek*(f: File, offset: clong, whence: int) {.importc: "fseek", header: "<stdio.h>", tags: [].}

type eLumps* = enum
  kEntities,
  kTextures,
  kPlanes,
  kNodes,
  kLeafs,
  kLeafFaces,
  kLeafBrushes,
  kModels,
  kBrushes,
  kBrushSides,
  kVertices,
  kIndices
  kShaders,
  kFaces,
  kLightmaps,
  kLightVolumes,
  kVisData,
  kMaxLumps

type
  tBSPHeader* = object
    q3magic*: array[4, char]
    version*: int32

  tBSPLump* = object
    offset*: int32
    length*: int32

  tBSPVertex* = object
    vPosition*: Vec3f
    vTextureCoord*: Vec2f
    vLightmapCoord*: Vec2f
    vNormal*: Vec3f
    color*: array[4, byte]

  tBSPFace* = object
    textureID*: int32
    effect*: int32
    facetype*: int32
    startVertIndex*: int32
    numOfVerts*: int32
    startIndex*: int32
    numOfIndices*: int32
    lightmapID*: int32
    lMapCorner*: array[2, int32]
    lMapSize*: array[2, int32]
    lMapPos*: Vec3f
    lMapVecs*: array[2, Vec3f]
    vNormal*: Vec3f
    size*: array[2, int32]

  tBSPTexture* = object
    name*: array[64, char]
    flags*: int32
    contents*: int32

  tBSPLightmap* = object
    imageBits*: array[128*128*3, byte]

  q3bspmap* = object
    indices*: seq[int32]
    vertices*: seq[tBSPVertex]
    faces*: seq[tBSPFace]
    textures*: seq[tBSPTexture]
    lightmaps*: seq[tBSPLightmap]
    name*: string