import std/[asyncdispatch, httpclient, json, strutils, uri, streams]
import msgpack4nim, msgpack4nim/msgpack2json
import ws
import types

const
  OpHandshake* = 9'u8
  OpJoinRoom* = 10'u8
  OpError* = 11'u8
  OpLeaveRoom* = 12'u8
  OpRoomData* = 13'u8
  OpRoomState* = 14'u8
  OpRoomStatePatch* = 15'u8
  OpPing* = 18'u8
  OpPong* = 19'u8

type
  Seat* = object
    roomId*: string
    sessionId*: string
    reconnectionToken*: string
    processId*: string
    publicAddress*: string

  ColyseusRoom* = ref object
    seat*: Seat
    isJoined*: bool
    isClosed*: bool
    ws*: WebSocket
    onMessage*: proc(msgType: string, payload: JsonNode) {.closure, gcsafe.}

proc newColyseusRoom*(): ColyseusRoom =
  new(result)
  result.isJoined = false
  result.isClosed = false
  result.ws = nil

proc sendAction*(self: ColyseusRoom, action: string, data: JsonNode): Future[bool] {.async.} =
  if self.ws == nil or self.isClosed: return false
  try:
    var s = MsgStream.init()
    s.write(chr(OpRoomData))
    s.pack_type(action)
    fromJsonNode(s, data)
    await self.ws.send(s.data, opcode = Opcode.Binary)
    result = true
  except CatchableError as e:
    echo "[Colyseus] Erro ao enviar ação ", action, ": ", e.msg
    result = false

proc startReader(self: ColyseusRoom) {.async.} =
  while not self.isClosed and self.ws != nil:
    try:
      let bin = await self.ws.receiveBinaryPacket()
      if bin.len == 0:
        continue
      let op = bin[0]
      if op == OpRoomData and bin.len > 1:
        try:
          var s = MsgStream.init(cast[string](bin)[1..^1])
          var msgType: string
          s.unpack(msgType)
          let payload = toJsonNode(s)
          if self.onMessage != nil:
            self.onMessage(msgType, payload)
        except CatchableError:
          discard
      elif op == OpPing:
        try:
          await self.ws.send($chr(OpPong), opcode = Opcode.Binary)
        except CatchableError:
          discard
    except CatchableError as e:
      self.isClosed = true
      break

proc joinOrCreate*(origin: string, roomName: string, options: JsonNode, bindIp: string = ""): Future[ColyseusRoom] {.async.} =
  let cleanOrigin = origin.strip(chars = {'/'})
  let httpUrl = cleanOrigin & "/rt/matchmake/joinOrCreate/" & roomName

  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
  })

  let resp = await client.post(httpUrl, body = $options)
  let bodyStr = await resp.body
  client.close()

  let node = parseJson(bodyStr)
  var seat: Seat

  if node.hasKey("room"):
    let r = node["room"]
    seat.roomId = r{"roomId"}.getStr()
    seat.sessionId = r{"sessionId"}.getStr()
    seat.reconnectionToken = r{"reconnectionToken"}.getStr()
    seat.processId = r{"processId"}.getStr()
    seat.publicAddress = r{"publicAddress"}.getStr()

  if node.hasKey("sessionId") and seat.sessionId.len == 0:
    seat.sessionId = node["sessionId"].getStr()

  var wsUrl: string
  if seat.publicAddress.len > 0:
    wsUrl = "wss://" & seat.publicAddress & "/" & seat.processId & "/" & seat.roomId & "?sessionId=" & encodeUrl(seat.sessionId)
  else:
    let wsScheme = if cleanOrigin.startsWith("https"): "wss" else: "ws"
    let host = cleanOrigin.replace("https://", "").replace("http://", "").strip(chars = {'/'})
    wsUrl = wsScheme & "://" & host & "/rt/" & seat.processId & "/" & seat.roomId & "?sessionId=" & encodeUrl(seat.sessionId)

  echo "[Colyseus] Conectando ao WebSocket da Sala: ", wsUrl
  let room = newColyseusRoom()
  room.seat = seat
  room.ws = await newWebSocket(wsUrl)
  room.isJoined = true

  # Enviar Join Room ACK com Opcode 10
  await room.ws.send($chr(OpJoinRoom), opcode = Opcode.Binary)

  # Disparar loop leitor em background
  asyncCheck room.startReader()

  result = room
