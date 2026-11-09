import std/[os, strutils, random]

const
  DefaultUserAgent* = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
  DeviceFileName* = "baiak_device"

proc djb2Hex*(input: string): string =
  var hash: uint32 = 5381
  for c in input:
    hash = ((hash shl 5) + hash) + uint32(ord(c))
  result = toHex(hash, 8).toLowerAscii()

proc generateDeviceId*(): string =
  const hexChars = "0123456789abcdef"
  randomize()
  result = newString(32)
  for i in 0 ..< 32:
    result[i] = hexChars[rand(hexChars.len - 1)]

proc getOrCreateDeviceId*(accountId: string): string =
  let dir = "data" / accountId
  let path = dir / DeviceFileName
  if fileExists(path):
    try:
      let content = readFile(path).strip()
      if content.len > 0:
        return content
    except CatchableError:
      discard

  let devId = generateDeviceId()
  try:
    createDir(dir)
    writeFile(path, devId)
  except CatchableError:
    discard
  result = devId

proc buildFingerprint*(accountId: string): string =
  let devId = getOrCreateDeviceId(accountId)
  let cleanId = if devId.len > 32: devId[0 ..< 32] else: devId
  let raw = DefaultUserAgent & "|1920|1080|24|-180|pt-BR"
  result = cleanId & "-" & djb2Hex(raw)
