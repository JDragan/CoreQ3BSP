import sdl2
import opengl
import glm
import times
import camera_util


var window: WindowPtr
let camera = newCamera(vec3(0.0'f32, 600.0'f32, 0.0'f32))
var W, H: cint

proc sdlinit*(screenWidth: cint, screenHeight: cint, name: string = "OpenGL Window"): WindowPtr =

  discard sdl2.init(INIT_EVERYTHING)
  # discard glSetAttribute(SDL_GL_MULTISAMPLESAMPLES, 16)
  discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_COMPATIBILITY);
  discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
  window = createWindow(name, 20, 40, screenWidth, screenHeight,
            SDL_WINDOW_OPENGL or SDL_WINDOW_RESIZABLE)
  hideWindow(window)
  discard setRelativeMouseMode(true.Bool32)
  discard glCreateContext(window)
  discard glSetSwapInterval(0)

  loadExtensions()
  W = screenWidth
  H = screenHeight
  window

proc SDLshowWindow*(win: WindowPtr) =
  showWindow(win)

var
  evt = sdl2.defaultEvent
  run* = true

var currentTime, prevTime: float
prevTime = epochTime()

proc SwapBuffers*() =
  window.glSwapWindow()

proc Update*() =
  currentTime = epochTime()
  let keyState = getKeyboardState()
  let elapsedTime = (currentTime - prevTime).float32*10.0'f32
  prevTime = currentTime
  while pollEvent(evt):
    case evt.kind
      of QuitEvent:
        run = false
        break
      of WindowEvent:
        var windowEvent = cast[WindowEventPtr](addr(evt))
        if windowEvent.event == WindowEvent_Resized:
          W = windowEvent.data1
          H = windowEvent.data2
          glViewport(0, 0, W, H)
      of MouseWheel:
        var wheelEvent = cast[MouseWheelEventPtr](addr(evt))
        camera.processMouseScroll(wheelEvent.y.float32)
      of MouseMotion:
        var motionEvent = cast[MouseMotionEventPtr](addr(evt))
        camera.processMouseMovement(motionEvent.xrel.float32,
                        motionEvent.yrel.float32)
      else:
        discard

  if keyState[SDL_SCANCODE_W.uint8] != 0:
    camera.processKeyboard(FORWARD, elapsedTime)
  if keyState[SDL_SCANCODE_S.uint8] != 0:
    camera.processKeyBoard(BACKWARD, elapsedTime)
  if keyState[SDL_SCANCODE_A.uint8] != 0:
    camera.processKeyBoard(LEFT, elapsedTime)
  if keyState[SDL_SCANCODE_D.uint8] != 0:
    camera.processKeyBoard(RIGHT, elapsedTime)
  if keyState[SDL_SCANCODE_ESCAPE.uint8] != 0:
    run = false


template setMat4*(program: GLuint, name: string, value: var Mat4f) =
  glUniformMatrix4fv(glGetUniformLocation(program, name).GLint, 1, GL_FALSE, value.caddr)

proc TransformCamera*(shaderID: GLuint) =
  var projection = perspective(radians(camera.Zoom),
            W.float32/H.float32, 0.1'f32, 10000.0'f32)
  var view = camera.getViewMatrix()
  var model = mat4(1.0'f32)
  shaderID.setMat4("projection", projection)
  shaderID.setMat4("view", view)
  shaderID.setMat4("model", model)

