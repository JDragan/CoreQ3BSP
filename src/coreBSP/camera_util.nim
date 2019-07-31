import glm
import shaderhelper
import opengl/private/types

type CameraMovement* = enum
    FORWARD,
    BACKWARD,
    LEFT,
    RIGHT

let YAW = -90.0
let PITCH = 0.0
let MAXPITCH = 89.0
let SPEED = 40.0
let SENSITIVITY = 0.1
let ZOOM = 85.0
let MINZOOM = 1.0
let MAXZOOM = 145.0

type Camera* = ref object
    Position*,Front*,Up*,Right*,WorldUp*:Vec3f
    Yaw*,Pitch*,MovementSpeed*,MouseSensitivity*,Zoom*:float32

proc updateCameraVectors(camera: Camera) =
    camera.Front.x = cos(radians(camera.Yaw)) * cos(radians(camera.Pitch))
    camera.Front.y = sin(radians(camera.Pitch))
    camera.Front.z = sin(radians(camera.Yaw)) * cos(radians(camera.Pitch))
    camera.Front = normalize(camera.Front);
    camera.Right = normalize(cross(camera.Front, camera.WorldUp))
    camera.Up    = normalize(cross(camera.Right, camera.Front))

proc newCamera*(position:Vec3f = vec3(0.0'f32),up:Vec3f = vec3(0.0'f32,1.0'f32,0.0'f32),yaw:float32 = YAW,pitch:float32 = PITCH) : Camera =
    var camera = Camera(
        Position : position,
        WorldUp : up,
        Yaw : yaw,
        MovementSpeed : SPEED,
        MouseSensitivity :SENSITIVITY,
        Zoom : ZOOM,
        Front: vec3(0.0'f32,0.0'f32,-1.0'f32))
    camera.updateCameraVectors()
    camera

proc getViewMatrix*(camera:Camera) : Mat4f =
    lookAt(camera.Position, camera.Position + camera.Front, camera.Up)

proc processKeyboard*(camera:Camera,direction:CameraMovement, deltaTime:float32) =
    let velocity = camera.MovementSpeed*deltaTime
    case direction:
        of FORWARD:
            camera.Position = camera.Position + camera.Front * velocity
        of BACKWARD:
            camera.Position = camera.Position - camera.Front * velocity
        of LEFT:
            camera.Position = camera.Position - camera.Right * velocity
        of RIGHT:
            camera.Position = camera.Position + camera.Right * velocity

proc processMouseMovement*(camera:Camera, xoffset: float32, yoffset:float32, constrainPitch: bool = true) =
    let adjustedXOffset = xoffset * camera.MouseSensitivity
    let adjustedYOffset = yoffset * camera.MouseSensitivity

    camera.Yaw = camera.Yaw + adjustedXOffset
    camera.Pitch = camera.Pitch - adjustedYOffset

    if constrainPitch:
        if camera.Pitch > MAXPITCH:
            camera.Pitch = MAXPITCH
        elif camera.Pitch < -MAXPITCH:
            camera.Pitch = -MAXPITCH

    updateCameraVectors(camera)

proc processMouseScroll*(camera:Camera, yoffset:float32) =
    if camera.Zoom >= MINZOOM and camera.Zoom <= MAXZOOM:
        camera.Zoom = camera.Zoom - yoffset
    if camera.Zoom <= MINZOOM:
        camera.Zoom = MINZOOM
    elif camera.Zoom >= MAXZOOM:
        camera.Zoom = MAXZOOM

proc TransformCamera*(shaderID: GLuint, camera: Camera) =
  var projection = perspective(radians(camera.Zoom),
            4/3, 0.1, 10000.0)
  var view = camera.getViewMatrix()
  var model = mat4(1.0'f32)
  shaderID.setMat4("projection", projection)
  shaderID.setMat4("view", view)
  shaderID.setMat4("model", model)