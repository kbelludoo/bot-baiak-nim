import std/[asyncdispatch, httpclient, json, strutils, uri]
import types

const
  DefaultTrpcBase* = "https://baiakidle.com/api/trpc"
  DefaultUserAgent* = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

type
  TRPCClient* = ref object
    baseUrl*: string
    token*: string

proc newTRPCClient*(token: string, origin: string = "", bindIp: string = ""): TRPCClient =
  new(result)
  result.baseUrl = if origin.len == 0: DefaultTrpcBase else: origin.strip(chars = {'/'}) & "/api/trpc"
  result.token = token

proc defaultHeaders(self: TRPCClient): HttpHeaders =
  result = newHttpHeaders({
    "User-Agent": DefaultUserAgent,
    "Accept": "application/json",
    "sec-ch-ua": "\"Chromium\";v=\"128\", \"Not;A=Brand\";v=\"24\", \"Google Chrome\";v=\"128\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\""
  })
  if self.token.len > 0:
    result["Authorization"] = "Bearer " & self.token

proc unwrapResponse(body: string): JsonNode =
  var parsed: JsonNode
  try:
    parsed = parseJson(body)
  except CatchableError:
    return newJNull()

  var first = parsed
  if parsed != nil and parsed.kind == JArray and parsed.len > 0:
    first = parsed[0]

  if first != nil and first.kind == JObject:
    let errNode = first{"error"}
    if errNode != nil and errNode.kind != JNull:
      raise newException(IOError, "tRPC error: " & $errNode)

    let resNode = first{"result"}
    if resNode != nil and resNode.kind == JObject:
      let dataNode = resNode{"data"}
      if dataNode != nil:
        if dataNode.kind == JObject and dataNode.hasKey("json"):
          return dataNode["json"]
        return dataNode
    return first

  result = if first != nil: first else: newJNull()

proc query*(self: TRPCClient, path: string, input: JsonNode = newJNull()): Future[JsonNode] {.async.} =
  let wrapped = %*{"0": input}
  let encodedInput = encodeUrl($wrapped)
  let url = self.baseUrl & "/" & path & "?batch=1&input=" & encodedInput

  let client = newAsyncHttpClient()
  client.headers = self.defaultHeaders()
  try:
    let resp = await client.get(url)
    let body = await resp.body
    client.close()
    result = unwrapResponse(body)
  except Exception as e:
    client.close()
    raise e

proc mutate*(self: TRPCClient, path: string, input: JsonNode): Future[JsonNode] {.async.} =
  let wrapped = %*{"0": input}
  let url = self.baseUrl & "/" & path & "?batch=1"

  let client = newAsyncHttpClient()
  var headers = self.defaultHeaders()
  headers["Content-Type"] = "application/json"
  client.headers = headers
  try:
    let resp = await client.post(url, body = $wrapped)
    let body = await resp.body
    client.close()
    result = unwrapResponse(body)
  except Exception as e:
    client.close()
    raise e

proc getCharacters*(self: TRPCClient): Future[seq[CharacterInfo]] {.async.} =
  let val = await self.query("characters.list")
  var list: seq[CharacterInfo] = @[]

  if val != nil and val.kind == JArray:
    for item in val:
      if item != nil and item.kind == JObject:
        var idStr = ""
        if item.hasKey("id"):
          if item["id"].kind == JString: idStr = item["id"].getStr()
          elif item["id"].kind == JInt: idStr = $item["id"].getInt()
          else: idStr = $item["id"]

        let name = item{"name"}.getStr()
        let vocation = item{"vocation"}.getStr()
        let level = item{"level"}.getInt(1)
        let stamina = item{"stamina"}.getInt(42)
        let gold = item{"gold"}.getBiggestInt(0)

        list.add(CharacterInfo(
          id: idStr,
          name: name,
          vocation: vocation,
          level: level,
          stamina: stamina,
          gold: gold
        ))

  result = list

proc enterHunt*(self: TRPCClient, huntId: string): Future[JsonNode] {.async.} =
  result = await self.mutate("hunts.enter", %*{"huntId": huntId})

proc buyVip*(self: TRPCClient): Future[JsonNode] {.async.} =
  result = await self.mutate("shop.buyVip", %*{})
