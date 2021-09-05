import
    opengl,
    glm,
    # vmath,
    stb_image/read as stbi

template createProgram*() : GLuint  = glCreateProgram()

template createShader*(shaderType:GLenum) : GLuint  =
    glCreateShader(shaderType)

template getProgramLinkStatus*(program:GLuint) : bool  =
    var r : GLint
    glGetProgramiv(program.GLuint,GL_LINK_STATUS,addr r)
    r.bool

template getUniformLocation*(program: GLuint, name: string) : GLuint  =
    glGetUniformLocation(program,name).GLuint

template setInt*(program:GLuint, name: string, value: GLuint) =
    glUniform1i(getUniformLocation(program,name).GLint,value.GLint)

template setMat4*(program: GLuint, name: string, value: var Mat4f) =
  glUniformMatrix4fv(glGetUniformLocation(program, name), 1, GL_FALSE, value.caddr)

template deleteShader*(shader:GLuint)  = glDeleteShader(shader.GLuint)

template linkProgram*(program:GLuint)  = glLinkProgram(program.GLuint)

template attachShader*(program:GLuint, shader:GLuint)  = glAttachShader(program.GLuint,shader.GLuint)

template compileShader*(shader:GLuint)  = glCompileShader(shader.GLuint)

template shaderSource*(shader:GLuint, src: string) =
    let cstr =  allocCStringArray([src])
    glShaderSource(shader.GLuint, 1, cstr, nil)
    deallocCStringArray(cstr)

template getProgramInfoLog*(program:GLuint) : string  =
    var logLen : GLint
    glGetProgramiv(program.GLuint,GL_INFO_LOG_LENGTH, addr logLen)
    var logStr = cast[ptr GLchar](alloc(logLen))
    glGetProgramInfoLog(program.GLuint,logLen,addr logLen,logStr)
    $logStr

template getShaderInfoLog*(shader:GLuint) : string =
    var logLen : GLint
    glGetShaderiv(shader.GLuint,GL_INFO_LOG_LENGTH, addr logLen)
    var logStr = cast[ptr GLchar](alloc(logLen))
    glGetShaderInfoLog(shader.GLuint,logLen,addr logLen,logStr)
    $logStr

template getShaderCompileStatus*(shader:GLuint) : bool  =
    var r : GLint
    glGetShaderiv(shader.GLuint,GL_COMPILE_STATUS,addr r)
    r.bool

template use*(program:GLuint)  =
    glUseProgram(program.GLuint)

# Compiles and attaches in 1 step with error reporting
proc compileAndAttachShader*(shaderType:GLenum, shaderPath: string, programId:GLuint) : GLuint =
    let shaderId = createShader(shaderType)
    shaderSource(shaderId,readFile(shaderPath))
    compileShader(shaderId)
    if not getShaderCompileStatus(shaderId):
        echo "Shader Compile Error ("&shaderPath&"):"
        echo getShaderInfoLog(shaderId)
    else:
        attachShader(programId,shaderId)
    shaderId


# Handles everything needed to set up a shader, with error reporting
proc createAndLinkProgram*(vertexPath:string, fragmentPath:string, geometryPath:string = "") : GLuint =
    let programId = createProgram()
    let vert = compileAndAttachShader(GL_VERTEX_SHADER,vertexPath,programId)
    let frag = compileAndAttachShader(GL_FRAGMENT_SHADER,fragmentPath,programId)
    let geo =
        if geometryPath != "":
            compileAndAttachShader(GL_GEOMETRY_SHADER,geometryPath,programId)
        else:
            0.GLuint

    linkProgram(programId)

    if not getProgramLinkStatus(programId):
        echo "Link Error:"
        echo getProgramInfoLog(programId)

    deleteShader(vert)
    deleteShader(frag)
    if geometryPath != "": deleteShader(geo)
    programId

import os

proc initShaders*(): GLuint =
    let appDir = getAppDir()

    let shader = createAndLinkProgram(
    appDir&"/shaders/simple.vert",
    appDir&"/shaders/simple.frag"
    )

    shader.use()
    shader.setInt("TEX", 0)
    shader.setInt("LMAP", 1)
    return shader


template texImage2D*[T](target:GLenum, level:int32, internalFormat:GLEnum, width:int32, height:int32, format:GLenum, pixelType:GLenum, data: openArray[T] )  =
    glTexImage2D(target,level.GLint,internalFormat.GLint,width.GLsizei,height.GLsizei,0,format,pixelType,data[0].unsafeAddr)

template genBindTexture*(target:GLenum) : GLuint =
    var tex : GLuint
    glGenTextures(1.GLsizei,addr tex)
    glBindTexture(target, tex)
    tex

proc loadTextureWithMips*(path:string, gammaCorrection:bool = false) : GLuint =
    let textureId = genBindTexture(GL_Texture2D)
    # stbi.setFlipVerticallyOnLoad(true)
    var width,height,channels:int
    let data = stbi.load(path,width,height,channels,stbi.Default)
    if data.len != 0:
        let gammaFormat =  GL_RGB

        let (internalFormat,dataFormat,param) =
            if channels == 1:
                (GL_RED,GL_RED,GL_REPEAT)
            elif channels == 3:
                (gammaFormat,GL_RGB,GL_REPEAT)
            elif channels == 4:
                (gammaFormat,GL_RGBA,GL_REPEAT)
            else:
                ( echo "texture unknown, assuming rgb";
                        (GL_RGB,GL_RGB,GL_REPEAT) )

        texImage2D(GL_TEXTURE_2D,
                    0'i32,
                    internalFormat,
                    width.int32,
                    height.int32,
                    dataFormat,
                    GL_UNSIGNED_BYTE,
                    data)

        glGenerateMipmap(GL_TEXTURE_2D)

        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,param)
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,param)
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR)
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
        textureId
    else:
        echo "Failure to Load Image"
        0.GLuint