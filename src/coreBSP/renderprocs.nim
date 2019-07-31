import opengl
import q3shaderparser
import strutils


type
  Buffers* = object
    VAO*, VBO*, EBO* : GLuint

type
  IntPair* = tuple
    a: int32
    b: int32

type
  RenderableObject* = object
    vertices*: seq[seq[float32]]
    indices*: seq[seq[uint32]]
    buffers*: seq[Buffers]
    texPair*: seq[tuple[a: GLuint, b: GLuint]]

var textures_IDs*: seq[GLuint]
var lightmap_IDs*:  seq[GLuint]
var intpairs*: seq[IntPair]


template loadLightmaps*(lightmaps: untyped) =
  let white : array[3, float32] = [0.5'f32, 0.5, 0.5]
  let checker : array[12, byte] = [255'u8, 255, 255, 0, 0, 0, 0, 0, 0, 255, 255, 255]
  var missingLM: GLuint

  glGenTextures(1, missingLM.addr)
  glBindTexture(GL_TEXTURE_2D,missingLM)
  glTexImage2D(GL_TEXTURE_2D, 0'i32, GL_RGB.GLint, 1, 1, 0, GL_RGB, cGL_FLOAT, unsafeAddr white[0])
  glGenerateMipmap(GL_TEXTURE_2D)

  for lm in 0 ..< lightmaps.len:
    glGenTextures(1, lightmap_IDs[lm].addr)
    glBindTexture(GL_TEXTURE_2D,lightmap_IDs[lm])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB.GLint, 128, 128, 0, GL_RGB, GL_UNSIGNED_BYTE, addr lightmaps[lm].imageBits)
    glGenerateMipmap(GL_TEXTURE_2D)
  lightmap_IDs.add(missingLM)


template loadTextures*(mapname: string, textures: untyped) =
  let missingTEX = loadTextureWithMips(appDir&"/baseq3/textures/_engine/missing.png")
  let skyflags = [3124, 3092, 134193, 1044, 1076]
  let shaderBlocks = parseq3shader(mapname)
  var stextures = newseq[string](shaderBlocks.len)

  for sb in 0 ..< shaderBlocks.len:
    stextures[sb] = shaderBlocks[sb].bsptexture

  for i in 0 ..< textures.len:
    let texturepath = textures[i].name.join.split({'\0'}).join() # remove null terminated chars
    let textureflag = textures[i].flags
    let path = (appDir / "baseq3" / texturepath)

    if existsFile(path & ".jpg"):
      textures_IDs[i] = loadTextureWithMips(path & ".jpg")
    elif existsFile(path & ".tga"):
      textures_IDs[i] = loadTextureWithMips(path & ".tga")
    elif shaderBlocks.len != 0:

      let pos = find(stextures, texturepath)
      if pos == -1:
        textures_IDs[i] = missingTEX
      else:
        let istrng = shaderBlocks[pos].internalstrings
        if istrng.len == 0:
          # echo "MISSING: ", texturepath
          textures_IDs[i] = missingTEX
          continue
        for istr in istrng:
          let rtex = appDir / "baseq3" / istr.split(" ")[1] # remove "map "
          if existsFile(rtex):
            textures_IDs[i] = loadTextureWithMips(rtex)
          elif existsFile(rtex.split(".tga")[0] & ".jpg"):
            textures_IDs[i] = loadTextureWithMips(rtex.split(".tga")[0] & ".jpg")
          else:
            textures_IDs[i] = missingTEX
            # echo "MISSING ON DISK: ", texturepath & " > " & istr
    else:
      textures_IDs[i] = missingTEX


template pushVertex*(container: seq[seq[float32]], index: int, element: untyped) =
    # this is faster than container[index].add
    let currentLen = container[index].len
    container[index].setLen(currentLen + 7)

    container[index][currentLen + 0] = element.vPosition[0]
    container[index][currentLen + 1] = element.vPosition[1]
    container[index][currentLen + 2] = element.vPosition[2]
    container[index][currentLen + 3] = element.vTextureCoord[0]
    container[index][currentLen + 4] = element.vTextureCoord[1]
    container[index][currentLen + 5] = element.vLightmapCoord[0]
    container[index][currentLen + 6] = element.vLightmapCoord[1]


proc CreateBuffers*(obj: RenderableObject) {.inline.} =
  for f in 0 ..< obj.vertices.len:
    if obj.vertices[f].len != 0:

      glGenVertexArrays(1 ,obj.buffers[f].VAO.unsafeAddr)
      glBindVertexArray(obj.buffers[f].VAO)

      glGenBuffers(1, obj.buffers[f].VBO.unsafeAddr)
      glBindBuffer(GL_ARRAY_BUFFER, obj.buffers[f].VBO)
      glBufferData(GL_ARRAY_BUFFER, obj.vertices[f].len*sizeof(GLfloat), obj.vertices[f][0].unsafeAddr, GL_STATIC_DRAW)

      glGenBuffers(1, obj.buffers[f].EBO.unsafeAddr)
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj.buffers[f].EBO)
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, obj.indices[f].len*sizeof(uint32), obj.indices[f][0].unsafeAddr, GL_STATIC_DRAW)


proc renderFaces*(obj: RenderableObject) {.inline.} =
  for f in 0 ..< intpairs.len:
    if obj.buffers[f].VAO == 0: continue

    let tid = obj.texPair[f].a
    let lmid = obj.texPair[f].b

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, tid)
    glActiveTexture(GL_TEXTURE1)
    glBindTexture(GL_TEXTURE_2D, lmid)

    glBindBuffer(GL_ARRAY_BUFFER,obj.buffers[f].VBO)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj.buffers[f].EBO)

    glVertexAttribPointer(0, 3, cGL_FLOAT, false, 7 * sizeof(float32), cast[pointer](0))
    glVertexAttribPointer(1, 2, cGL_FLOAT, false, 7 * sizeof(float32), cast[pointer](3 * sizeof(float32)))
    glVertexAttribPointer(2, 2, cGL_FLOAT, false, 7 * sizeof(float32), cast[pointer](5 * sizeof(float32)))

    glEnableVertexAttribArray(0)
    glEnableVertexAttribArray(1)
    glEnableVertexAttribArray(2)

    glDrawElements(GL_TRIANGLES, obj.indices[f].len.GLsizei, GL_UNSIGNED_INT, cast[pointer](0))


proc defaultGLsetup*() =
  glEnable(GL_DEPTH_TEST)
  glEnable(GL_CULL_FACE)
  glCullFace(GL_FRONT)