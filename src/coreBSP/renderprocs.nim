import opengl

type
  Buffers* = object
    VAO*, VBO*, EBO* : GLuint

type
  RenderableObject* = object
    vertices*: seq[seq[float32]]
    indices*: seq[seq[uint32]]
    buffers*: seq[Buffers]

type
  IntPair* = tuple
    a: int32
    b: int32

var textures_IDs*: seq[GLuint]
var lightmap_IDs*:  seq[GLuint]
var intpairs*: seq[IntPair]

template loadLightmaps*(lightmaps: untyped) =
  var white : seq[float32] = @[0.5'f32, 0.5, 0.5]
  var checker : array[12, byte] = [255'u8, 255, 255, 0, 0, 0, 0, 0, 0, 255, 255, 255]
  var missingLM: GLuint

  glGenTextures(1, missingLM.addr)
  glBindTexture(GL_TEXTURE_2D,missingLM)
  glTexImage2D(GL_TEXTURE_2D, 0'i32, GL_RGB.GLint, 1, 1, 0, GL_RGB, cGL_FLOAT, addr white[0])
  glGenerateMipmap(GL_TEXTURE_2D)

  for lm in 0 ..< lightmaps.len:
    glGenTextures(1, lightmap_IDs[lm].addr)
    glBindTexture(GL_TEXTURE_2D,lightmap_IDs[lm])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB.GLint, 128, 128, 0, GL_RGB, GL_UNSIGNED_BYTE, addr lightmaps[lm].imageBits)
    glGenerateMipmap(GL_TEXTURE_2D)
  lightmap_IDs.add(missingLM)

template loadTextures*(textures: untyped) =
  let missingTEX = loadTextureWithMips(appDir&"/baseq3/textures/_engine/missing.png")

  for i in 0 ..< textures.len:
    let texturepath = textures[i].name.join.split({'\0'}).join() # remove null terminated chars
    let path = (appDir / "baseq3" / texturepath)
    # echo path
    if existsFile(path & ".jpg"):
      textures_IDs[i] = loadTextureWithMips(path & ".jpg")
    elif existsFile(path & ".tga"):
      textures_IDs[i] = loadTextureWithMips(path & ".tga")
    else: textures_IDs[i] = missingTEX

template pushVertex*(container: var seq[seq[float32]], index: int, element: untyped) =
  container[index].add(element.vPosition[0])
  container[index].add(element.vPosition[1])
  container[index].add(element.vPosition[2])
  container[index].add(element.vTextureCoord[0])
  container[index].add(element.vTextureCoord[1])
  container[index].add(element.vLightmapCoord[0])
  container[index].add(element.vLightmapCoord[1])


proc CreateBuffers*(obj: RenderableObject) =

  glEnableVertexAttribArray(0)
  glEnableVertexAttribArray(1)
  glEnableVertexAttribArray(2)

  for f in 0 ..< obj.vertices.len:
    if obj.vertices[f].len != 0:
      glGenBuffers(1, obj.buffers[f].VBO.unsafeAddr)
      glBindBuffer(GL_ARRAY_BUFFER, obj.buffers[f].VBO)
      glBufferData(GL_ARRAY_BUFFER, obj.vertices[f].len*sizeof(GLfloat), obj.vertices[f][0].unsafeAddr, GL_STATIC_DRAW)

      glGenBuffers(1, obj.buffers[f].EBO.unsafeAddr)
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj.buffers[f].EBO)
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, obj.indices[f].len*sizeof(uint32), obj.indices[f][0].unsafeAddr, GL_STATIC_DRAW)


proc renderFaces*(obj: RenderableObject) =

  var tid, lmid : GLuint
  let missinglm = lightmap_IDs[lightmap_IDs.high]

  for f in 0 ..< obj.vertices.len:
    if obj.vertices[f].len != 0:

      tid = textures_IDs[intpairs[f].a]
      if intpairs[f].b >= 0:
        lmid = lightmap_IDs[intpairs[f].b]
      else:
        lmid = missinglm

      glActiveTexture(GL_TEXTURE0)
      glBindTexture(GL_TEXTURE_2D, tid)
      glActiveTexture(GL_TEXTURE1)
      glBindTexture(GL_TEXTURE_2D, lmid)

      glBindBuffer(GL_ARRAY_BUFFER,obj.buffers[f].VBO)
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj.buffers[f].EBO)

      glVertexAttribPointer(0, 3, cGL_FLOAT, false, 7 * sizeof(float32), cast[pointer](0))
      glVertexAttribPointer(1, 2, cGL_FLOAT, false, 7 * sizeof(float32), cast[pointer](3 * sizeof(float32)))
      glVertexAttribPointer(2, 2, cGL_FLOAT, false, 7 * sizeof(float32), cast[pointer](5 * sizeof(float32)))

      glDrawElements(GL_TRIANGLES, obj.indices[f].len.GLsizei, GL_UNSIGNED_INT, cast[pointer](0))


proc defaultGLsetup*() =
  glEnable(GL_DEPTH_TEST)
  glEnable(GL_CULL_FACE)
  glCullFace(GL_FRONT)