import std/[json]

type
  GameCredentials* = object
    token*: string
    email*: string
    password*: string
    origin*: string

  GameSettings* = object
    huntTarget*: string
    priority*: string
    autoHunt*: bool
    autoSell*: bool
    autoHeal*: bool
    autoDaily*: bool
    autoTreino*: bool
    autoBuyVip*: bool
    autoAuction*: bool
    bindIp*: string

  AccountConfig* = object
    id*: string
    name*: string
    enabled*: bool
    credentials*: GameCredentials
    settings*: GameSettings

  CharacterInfo* = object
    id*: string
    name*: string
    vocation*: string
    level*: int
    stamina*: int
    gold*: int64

  HuntInfo* = object
    id*: string
    name*: string
    minLevel*: int
    monsters*: seq[string]
    maxAlive*: int
    spawnMs*: float
    avgHp*: float
    avgExp*: float
    goldKill*: float
    avgDmg*: float

  SafeBoss* = object
    id*: string
    name*: string
    minLevel*: int

proc defaultSettings*(): GameSettings =
  result = GameSettings(
    huntTarget: "refiner-cave",
    priority: "balanced",
    autoHunt: true,
    autoSell: true,
    autoHeal: true,
    autoDaily: true,
    autoTreino: true,
    autoBuyVip: true,
    autoAuction: true,
    bindIp: ""
  )

proc parseAccountConfig*(node: JsonNode): AccountConfig =
  result.id = node{"id"}.getStr()
  result.name = node{"name"}.getStr()
  result.enabled = node{"enabled"}.getBool(true)

  if node.hasKey("credentials"):
    let creds = node["credentials"]
    result.credentials.token = creds{"token"}.getStr()
    result.credentials.email = creds{"email"}.getStr()
    result.credentials.password = creds{"password"}.getStr()
    result.credentials.origin = creds{"origin"}.getStr("https://baiakidle.com")

  result.settings = defaultSettings()
  if node.hasKey("settings"):
    let s = node["settings"]
    if s.hasKey("hunt_target"): result.settings.huntTarget = s["hunt_target"].getStr()
    elif s.hasKey("huntTarget"): result.settings.huntTarget = s["huntTarget"].getStr()
    if s.hasKey("priority"): result.settings.priority = s["priority"].getStr()
    if s.hasKey("auto_hunt"): result.settings.autoHunt = s["auto_hunt"].getBool(true)
    elif s.hasKey("autoHunt"): result.settings.autoHunt = s["autoHunt"].getBool(true)
    if s.hasKey("auto_sell"): result.settings.autoSell = s["auto_sell"].getBool(true)
    elif s.hasKey("autoSell"): result.settings.autoSell = s["autoSell"].getBool(true)
    if s.hasKey("auto_heal"): result.settings.autoHeal = s["auto_heal"].getBool(true)
    elif s.hasKey("autoHeal"): result.settings.autoHeal = s["autoHeal"].getBool(true)
    if s.hasKey("auto_daily"): result.settings.autoDaily = s["auto_daily"].getBool(true)
    elif s.hasKey("autoDaily"): result.settings.autoDaily = s["autoDaily"].getBool(true)
    if s.hasKey("auto_treino"): result.settings.autoTreino = s["auto_treino"].getBool(true)
    elif s.hasKey("autoTreino"): result.settings.autoTreino = s["autoTreino"].getBool(true)
    if s.hasKey("auto_buy_vip"): result.settings.autoBuyVip = s["auto_buy_vip"].getBool(true)
    elif s.hasKey("autoBuyVip"): result.settings.autoBuyVip = s["autoBuyVip"].getBool(true)
    if s.hasKey("auto_auction"): result.settings.autoAuction = s["auto_auction"].getBool(true)
    elif s.hasKey("autoAuction"): result.settings.autoAuction = s["autoAuction"].getBool(true)
    if s.hasKey("bind_ip"): result.settings.bindIp = s["bind_ip"].getStr()
    elif s.hasKey("bindIp"): result.settings.bindIp = s["bindIp"].getStr()
