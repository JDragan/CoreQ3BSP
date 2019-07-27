import sdl2
import opengl
import glm
import times
import camera_util
import shaderhelper


var window: WindowPtr
var W, H: cint

proc sdlinit*(screenWidth: cint, screenHeight: cint, name: string = "OpenGL Window"): WindowPtr =

  discard sdl2.init(INIT_EVERYTHING)
  discard glSetAttribute( SDL_GL_DOUBLEBUFFER, 1 );
  discard glSetAttribute( SDL_GL_ACCELERATED_VISUAL, 1 );
  discard glSetAttribute( SDL_GL_RED_SIZE, 8 );
  discard glSetAttribute( SDL_GL_GREEN_SIZE, 8 );
  discard glSetAttribute( SDL_GL_BLUE_SIZE, 8 );
  discard glSetAttribute( SDL_GL_ALPHA_SIZE, 8 );
  discard glSetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 3 );
  discard glSetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 3 );
  discard glSetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );
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

proc Update*(camera: Camera) =
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
