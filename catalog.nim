import std/[json, tables, strutils]
import types

const EngineHuntsRaw = staticRead("engine_hunts.json")

const PreferredHuntTable*: seq[(int, string)] = @[
  (1, "troll-cave"), (8, "elf-lair"), (9, "amazon-camp"), (10, "minotaur"), (15, "cyclopolis"),
  (30, "refiner-cave"), (50, "giant-spider"), (60, "glooth-cave"), (80, "dragon-lair"),
  (90, "werebadge-cave"), (100, "hydra-cave"), (130, "wyrm-cave"), (140, "werehyaena-cave"),
  (150, "asura-lair"), (170, "wereliones-cave"), (180, "draken-lair"), (190, "cobra-cave"),
  (200, "undeadragon-lair"), (210, "falcon"), (220, "grimeleech-cave"), (240, "choking-cave"),
  (250, "guzzlemaw-cave"), (270, "lionknight-cave"), (290, "megadragon-cave"), (300, "naga-lair"),
  (310, "moonstone-crater"), (350, "gazer-lair"), (370, "forbidden-gardens"), (420, "asura-citadel"),
  (450, "inferniarch-lair"), (500, "livraria-cave"), (510, "thalassara-surroundings"), (610, "lavafungos-cave"),
  (700, "crypt-cave"), (800, "bonyseadevil-cave"), (1500, "draklightsource-cave"), (2000, "radiant-skyhold"),
  (2500, "radiant-skyhold-devoted")
]

var
  huntsById*: Table[string, HuntInfo]
  allHunts*: seq[HuntInfo]
  isCatalogInitialized = false

proc initCatalog*() =
  if isCatalogInitialized: return
  huntsById = initTable[string, HuntInfo]()
  allHunts = @[]

  try:
    let node = parseJson(EngineHuntsRaw)
    if node.hasKey("hunts"):
      for h in node["hunts"]:
        var info: HuntInfo
        info.id = h{"id"}.getStr()
        info.name = h{"name"}.getStr()
        info.minLevel = h{"minLevel"}.getInt(1)
        info.monsters = @[]
        if h.hasKey("monsters"):
          for m in h["monsters"]:
            info.monsters.add(m.getStr())
        info.maxAlive = h{"maxAlive"}.getInt(4)
        info.spawnMs = h{"spawnMs"}.getFloat(500.0)
        info.avgHp = h{"avgHp"}.getFloat(100.0)
        info.avgExp = h{"avgExp"}.getFloat(100.0)
        info.goldKill = h{"goldKill"}.getFloat(10.0)
        info.avgDmg = h{"avgDmg"}.getFloat(10.0)

        huntsById[info.id] = info
        allHunts.add(info)
  except CatchableError as e:
    echo "[Catalog] Erro ao parsear engine_hunts.json: ", e.msg

  isCatalogInitialized = true

proc getHuntFacts*(id: string): (bool, HuntInfo) =
  if not isCatalogInitialized: initCatalog()
  if huntsById.hasKey(id):
    return (true, huntsById[id])
  return (false, HuntInfo())

proc selectBestHunt*(level: int): string =
  result = "troll-cave"
  for pair in PreferredHuntTable:
    if level >= pair[0]:
      result = pair[1]
    else:
      break

initCatalog()
