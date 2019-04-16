import glm
import bspstruct

type
  BezierPatch* = object
    controlpoints*: array[9, tBSPVertex]
    patchVertices*: seq[tBSPVertex]
    patchIndices*: seq[int32]
    textureID*: int32
    lightmapID*: int32

  tBSPPatch* = object
    bezierpatches*: seq[BezierPatch]
    textureID*: int32
    lightmapID*: int32

proc `*`(v1: tBSPVertex, d: float): tBSPVertex =
  var temp : tBSPVertex
  temp.vPosition = v1.vPosition * d
  temp.vTextureCoord = v1.vTextureCoord * d
  temp.vLightmapCoord = v1.vLightmapCoord * d
  temp

proc `+`(v1: tBSPVertex, v2: tBSPVertex): tBSPVertex =
  var temp : tBSPVertex
  temp.vPosition = v1.vPosition + v2.vPosition;
  temp.vTextureCoord = v1.vTextureCoord + v2.vTextureCoord;
  temp.vLightmapCoord = v1.vLightmapCoord + v2.vLightmapCoord;
  return temp;

proc Subdivide*(bezierpatch: BezierPatch): ptr BezierPatch =

  var L = 10
  var L1 = L + 1 # The number of vertices along a side is 1 + num edges

  var bp = bezierpatch.unsafeAddr
  bp.patchVertices.setLen(L1 * L1)
  # Compute the vertices

  for i in 0..L:
    var a = i / L;
    var b = 1 - a;

    bp.patchVertices[i] = bp.controlpoints[0] * (b * b) +
                          bp.controlpoints[3] * (2 * b * a) +
                          bp.controlpoints[6] * (a * a);

    var temp : array[3, tBSPVertex]

    for j in 0..2:
      var k = 3 * j;
      temp[j] = bp.controlpoints[k + 0] * (b * b) +
                bp.controlpoints[k + 1] * (2 * b * a) +
                bp.controlpoints[k + 2] * (a * a)

    for j in 0..L:
      var a = j / L;
      var b = 1.0 - a;

      bp.patchVertices[i * L1 + j] =
          temp[0] * (b * b) + temp[1] * (2 * b * a) + temp[2] * (a * a)

  ## Compute the indices so we can
  ## render them directly with GL_TRIANGLES
  bp.patchIndices.setLen(L * L * 6)

  var count = 0

  for i in 0 ..< L:
    for _ in 0 ..< L:
      var offset = count * 6;

      bp.patchIndices[0 + offset] = (L + 1 + count + i).int32
      bp.patchIndices[1 + offset] = (count + i).int32
      bp.patchIndices[2 + offset] = (L + 2 + count + i).int32

      bp.patchIndices[3 + offset] = (L + 2 + count + i).int32
      bp.patchIndices[4 + offset] = (count + i).int32
      bp.patchIndices[5 + offset] = (1 + count + i).int32

      inc count

  return bp
