local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild('PlayerGui')
local Env = _G
if type(getgenv) == 'function' then
    local ok, value = pcall(getgenv)
    if ok and type(value) == 'table' then Env = value end
end
for _, key in ipairs({'__EggStudioCleanup', '__AquaFishingCleanup'}) do
    if type(Env[key]) == 'function' then pcall(Env[key]) end
end
local Config = {
    PerfectCastTime = 1.05, CastStartTimeout = 1.5,
    ClickInterval = 0.025, ClickDownTime = 0.025,
    ScanInterval = 0.12, ReadyTimeout = 90, ReelTimeout = 60,
    ToggleKey = Enum.KeyCode.F1, MenuKey = Enum.KeyCode.F6,
    ReducedMotion = false, ProtectInput = true, ShowLauncher = true, SkyMotion = true,
}
local C = {
    bg = Color3.fromRGB(6,9,14), panel = Color3.fromRGB(15,21,31),
    hover = Color3.fromRGB(29,38,53), line = Color3.fromRGB(38,48,64),
    text = Color3.fromRGB(230,234,243), muted = Color3.fromRGB(153,163,183),
    dim = Color3.fromRGB(113,125,147), accent = Color3.fromRGB(163,182,246),
    green = Color3.fromRGB(139,205,185), red = Color3.fromRGB(231,143,153),
}
local S = {
    alive = true, enabled = false, paused = false, blocked = false,
    focused = true, visible = true, minimized = false, epoch = 0,
    autoCast = true, autoReel = true, held = false, cycles = 0, clicks = 0,
    phase = 'Готово к работе', step = 0, page = 'fish', binding = false,
    started = os.clock(), activeSeconds = 0, waitingCycle = false,
    deadline = nil, progress = 0,
}
local UI, Connections, Tweens = {}, {}, setmetatable({}, {__mode = 'k'})
local pressAPI, releaseAPI = mouse1press, mouse1release
local InputAvailable = type(pressAPI) == 'function' and type(releaseAPI) == 'function'
local cleanup, paint, setEnabled, showMenu, showPage, notify
local function connect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(Connections, conn)
    return conn
end
local function new(kind, props, parent)
    local obj = Instance.new(kind)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function rounded(obj, radius)
    new('UICorner', {CornerRadius = UDim.new(0, radius or 14)}, obj)
    return obj
end
local function outline(obj, color, transparency)
    return new('UIStroke', {Color = color or C.line, Thickness = 1,
        Transparency = transparency or 0}, obj)
end
local function tween(obj, props, duration)
    if Tweens[obj] then Tweens[obj]:Cancel() end
    local t = TweenService:Create(obj, TweenInfo.new(Config.ReducedMotion and 0 or (duration or 0.18),
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    Tweens[obj] = t
    t:Play()
end
local function frame(parent, x,y,w,h, color, radius)
    local f = new('Frame', {Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(w,h),
        BackgroundColor3 = color or C.panel, BorderSizePixel = 0}, parent)
    rounded(f, radius)
    return f
end
local function text(parent, value, x,y,w,h, size, color, bold)
    return new('TextLabel', {BackgroundTransparency = 1, Position = UDim2.fromOffset(x,y),
        Size = UDim2.fromOffset(w,h), Text = value, TextSize = size or 13,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextColor3 = color or C.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true}, parent)
end
local function button(parent, value, x,y,w,h, primary, action)
    local base = primary and C.accent or C.panel
    local b = new('TextButton', {Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(w,h),
        BackgroundColor3 = base, BorderSizePixel = 0, AutoButtonColor = false,
        Text = value, TextSize = 12, TextColor3 = primary and C.bg or C.text,
        Font = Enum.Font.GothamBold, Selectable = true}, parent)
    rounded(b, 7)
    if not primary then outline(b) end
    connect(b.MouseEnter, function() tween(b, {BackgroundColor3 = primary and Color3.fromRGB(187,201,255) or C.hover}) end)
    connect(b.MouseLeave, function() tween(b, {BackgroundColor3 = base}) end)
    if action then connect(b.Activated, action) end
    return b
end
local function release()
    if S.held then
        S.held = false
        if InputAvailable then pcall(releaseAPI) end
    end
end
local function invalidate()
    S.epoch = S.epoch + 1
    S.waitingCycle = false
    S.deadline = nil
    S.progress = 0
    release()
end
local function status(value, step)
    S.phase = value
    S.step = step or 0
    if paint then paint() end
end
local Parent = PlayerGui
if type(gethui) == 'function' then
    local ok, p = pcall(gethui)
    if ok and typeof(p) == 'Instance' then Parent = p end
end
for _, name in ipairs({'EggStudioMenu', 'AquaFishing_Menu'}) do
    local old = Parent:FindFirstChild(name)
    if old then old:Destroy() end
end
UI.gui = new('ScreenGui', {Name = 'EggStudioMenu', ResetOnSpawn = false,
    IgnoreGuiInset = false, DisplayOrder = 9999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, Parent)
UI.main = frame(UI.gui,0,0,760,530,C.bg,12)
UI.main.Position = UDim2.new(.5,-380,.5,-265)
UI.main.Active = true
outline(UI.main)
UI.scale = new('UIScale',{Scale = 1},UI.main)
local Sky = {stars = {}, time = 0, tick = 0, nextMeteor = 1.8, meteor = nil}
Sky.random = Random.new(48271)
Sky.layer = new('Frame',{Name = 'NightSky',Size = UDim2.fromScale(1,1),
    BackgroundTransparency = 1,BorderSizePixel = 0,ClipsDescendants = true,
    Active = false,ZIndex = 1},UI.main)
rounded(Sky.layer,12)
function Sky.dot(parent,x,y,size,color,opacity)
    local dot = new('Frame',{AnchorPoint = Vector2.new(.5,.5),Position = UDim2.fromOffset(x,y),
        Size = UDim2.fromOffset(size,size),BackgroundColor3 = color,
        BackgroundTransparency = 1-opacity,BorderSizePixel = 0,Active = false},parent)
    rounded(dot,math.max(1,size))
    return dot
end
for i = 1,192 do
    local rng = Sky.random
    local bright = rng:NextNumber()>.92
    local intensity = bright and rng:NextNumber(.62,.9) or rng:NextNumber(.16,.52)
    local radius = bright and rng:NextNumber(1.25,1.8) or rng:NextNumber(.65,1.15)
    local x,y = rng:NextNumber(10,750),rng:NextNumber(8,522)
    local tint = rng:NextNumber()
    local color = tint<.13 and Color3.fromRGB(241,224,196)
        or tint>.7 and Color3.fromRGB(190,211,245) or Color3.fromRGB(223,230,242)
    local star = {base = intensity,phase = rng:NextNumber(0,math.pi*2),
        speed = rng:NextNumber(.38,1.05),amplitude = bright and .14 or .065}
    if bright then
        star.halo = Sky.dot(Sky.layer,x,y,radius*6,color,intensity*.025)
        star.glow = Sky.dot(Sky.layer,x,y,radius*2.7,color,intensity*.075)
    end
    star.core = Sky.dot(Sky.layer,x,y,radius,color,intensity)
    table.insert(Sky.stars,star)
end
Sky.trail = new('Frame',{Name = 'Meteor',Size = UDim2.fromOffset(1,1),BackgroundTransparency = 1,
    Visible = false,Active = false},Sky.layer)
Sky.tail = new('Frame',{AnchorPoint = Vector2.new(1,.5),Size = UDim2.fromOffset(150,1),
    BackgroundColor3 = Color3.fromRGB(201,219,243),BorderSizePixel = 0},Sky.trail)
new('UIGradient',{Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.45,.88),
    NumberSequenceKeypoint.new(.8,.5),NumberSequenceKeypoint.new(1,.12)})},Sky.tail)
Sky.bloom = new('Frame',{AnchorPoint = Vector2.new(1,.5),Size = UDim2.fromOffset(100,3),
    BackgroundColor3 = Color3.fromRGB(170,196,232),BorderSizePixel = 0},Sky.trail)
new('UIGradient',{Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.6,.96),NumberSequenceKeypoint.new(1,.85)})},Sky.bloom)
Sky.headGlow = Sky.dot(Sky.trail,0,0,7,Color3.fromRGB(209,226,249),.04)
Sky.head = Sky.dot(Sky.trail,0,0,1.7,Color3.fromRGB(248,250,255),.9)
function Sky.spawn()
    local rng = Sky.random
    Sky.meteor = {age = 0,duration = rng:NextNumber(.8,1.15),
        x = rng:NextNumber(15,370),y = rng:NextNumber(8,116),
        distance = rng:NextNumber(310,440),angle = math.rad(rng:NextNumber(20,31)),
        length = rng:NextNumber(110,190)}
    Sky.trail.Rotation = math.deg(Sky.meteor.angle)
    Sky.trail.Visible = true
end
function Sky.step(dt)
    if not S.visible or S.minimized or not S.focused or Config.ReducedMotion or not Config.SkyMotion then
        Sky.trail.Visible = false Sky.meteor = nil
        return
    end
    Sky.tick = Sky.tick+dt
    if Sky.tick<1/24 then return end
    local delta = Sky.tick Sky.tick = 0
    Sky.time = Sky.time+delta
    for _,star in ipairs(Sky.stars) do
        local shimmer = 1+star.amplitude*(math.sin(Sky.time*star.speed+star.phase)
            +.35*math.sin(Sky.time*star.speed*1.73+star.phase*2))
        local intensity = math.clamp(star.base*shimmer,0,1)
        star.core.BackgroundTransparency = 1-intensity
        if star.glow then star.glow.BackgroundTransparency = 1-intensity*.075 end
        if star.halo then star.halo.BackgroundTransparency = 1-intensity*.025 end
    end
    if not Sky.meteor then
        Sky.nextMeteor = Sky.nextMeteor-delta
        if Sky.nextMeteor<=0 then Sky.spawn() end
    end
    local meteor = Sky.meteor
    if meteor then
        meteor.age = meteor.age+delta
        local t = meteor.age/meteor.duration
        if t>=1 then
            Sky.trail.Visible = false Sky.meteor = nil
            Sky.nextMeteor = Sky.random:NextNumber(7,14)
        else
            local fade = math.min(1,t/.12)*math.max(0,math.min(1,(1-t)/.42))
            local travel = meteor.distance*t
            Sky.trail.Position = UDim2.fromOffset(meteor.x+math.cos(meteor.angle)*travel,
                meteor.y+math.sin(meteor.angle)*travel)
            local length = meteor.length*math.min(1,t/.23)
            Sky.tail.Size = UDim2.fromOffset(length,1)
            Sky.bloom.Size = UDim2.fromOffset(length*.85,3)
            Sky.tail.BackgroundTransparency = 1-fade*.76
            Sky.bloom.BackgroundTransparency = 1-fade
            Sky.head.BackgroundTransparency = 1-fade*.95
            Sky.headGlow.BackgroundTransparency = 1-fade*.05
        end
    end
end
connect(RunService.Heartbeat,function(dt) if S.alive then Sky.step(dt) end end)

local applyLayout, resize, cancelBind
UI.header = new('Frame',{Size = UDim2.new(1,0,0,52),BackgroundTransparency = 1,ZIndex = 2},UI.main)
UI.drag = new('TextButton',{Size = UDim2.new(1,-94,1,0),BackgroundTransparency = 1,Text = '',AutoButtonColor = false},UI.header)
UI.brand = new('Frame',{Size = UDim2.fromOffset(250,52),BackgroundTransparency = 1},UI.drag)
local mark = frame(UI.brand,18,16,22,22,C.accent,5)
frame(mark,6,5,3,12,C.bg,1).Rotation = 22
frame(mark,13,5,3,12,C.bg,1).Rotation = 22
text(UI.brand,'AquaFishing',52,9,114,31,18,C.text,true)
UI.badge = text(UI.header,'●  Ожидание',520,13,145,26,11,C.muted)
UI.compactStatus = text(UI.drag,'●  Ожидание',16,10,190,28,12,C.muted,true)
UI.compactStatus.Visible = false
UI.min = button(UI.header,'−',670,10,32,32,false,function()
    S.minimized = not S.minimized
    applyLayout()
end)
UI.close = button(UI.header,'×',710,10,32,32,false,function() showMenu(false) end)
UI.separator = frame(UI.main,18,52,724,1,C.line,0)
UI.separator.ZIndex = 2
UI.body = new('Frame',{Position = UDim2.fromOffset(18,66),Size = UDim2.fromOffset(724,446),BackgroundTransparency = 1,ZIndex = 2},UI.main)
UI.nav = {}
for i,entry in ipairs({{'fish','Рыбалка'},{'settings','Настройки'},{'info','Информация'}}) do
    local key,title = entry[1],entry[2]
    local b = button(UI.body,title,(i-1)*132,0,122,34,false,function() showPage(key) end)
    local line = frame(b,12,32,98,2,C.accent,1)
    line.Visible = false
    UI.nav[key] = {b = b,line = line}
    connect(b.MouseLeave,function()
        tween(b,{BackgroundColor3 = S.page == key and C.hover or C.panel})
    end)
end
UI.keyHint = text(UI.body,'F6 / меню',578,2,145,30,10,C.dim)
UI.keyHint.TextXAlignment = Enum.TextXAlignment.Right
UI.content = new('Frame',{Position = UDim2.fromOffset(0,52),Size = UDim2.fromOffset(724,394),BackgroundTransparency = 1},UI.body)
UI.pages = {}
local function page(key)
    local p = new('ScrollingFrame',{Size = UDim2.fromScale(1,1),BackgroundTransparency = 1,
        BorderSizePixel = 0,ScrollBarThickness = 2,ScrollBarImageColor3 = C.dim,
        CanvasSize = UDim2.fromOffset(0,390),ScrollingDirection = Enum.ScrollingDirection.Y,Visible = false},UI.content)
    UI.pages[key] = p
    return p
end
local function switch(parent,title,x,y,width,initial,callback)
    local row = new('TextButton',{Position = UDim2.fromOffset(x,y),Size = UDim2.fromOffset(width,38),
        BackgroundTransparency = 1,Text = '',AutoButtonColor = false,Selectable = true},parent)
    text(row,title,0,0,width-58,38,12,C.text)
    local track = frame(row,width-38,9,38,20,initial and C.accent or C.line,6)
    local knob = frame(track,initial and 21 or 3,3,14,14,initial and C.bg or C.muted,4)
    local value = initial
    local function apply(v)
        value = v
        tween(track,{BackgroundColor3 = v and C.accent or C.line})
        tween(knob,{Position = UDim2.fromOffset(v and 21 or 3,3),BackgroundColor3 = v and C.bg or C.muted})
    end
    connect(row.Activated,function() apply(not value) callback(value) end)
    return {set = apply}
end
local Fish = page('fish')
text(Fish,'Рыбалка',0,0,480,32,23,C.text,true)
UI.smallBind = text(Fish,'F1',650,4,72,24,11,C.dim)
UI.smallBind.TextXAlignment = Enum.TextXAlignment.Right
local Controls = frame(Fish,0,48,460,198,C.panel,9)
outline(Controls)
Controls.BackgroundTransparency = .12
frame(Controls,0,24,2,36,C.accent,1)
UI.run = button(Controls,'Запустить',18,18,302,42,true,function() setEnabled(not S.enabled) end)
UI.pause = button(Controls,'Пауза',330,18,112,42,false,function()
    if not S.enabled then return end
    S.paused = not S.paused invalidate() status(S.paused and 'Пауза' or 'Ожидание',0)
end)
frame(Controls,18,77,424,1,C.line,0)
switch(Controls,'Авто-заброс',18,90,424,true,function(v) S.autoCast = v invalidate() end)
switch(Controls,'Авто-вытаскивание',18,141,424,true,function(v) S.autoReel = v invalidate() end)
local Stats = frame(Fish,474,48,250,198,C.panel,9)
outline(Stats)
Stats.BackgroundTransparency = .12
text(Stats,'ЦИКЛЫ',18,16,170,18,9,C.dim,true)
UI.cycles = text(Stats,'00',18,42,212,49,38,C.text,true)
UI.cycles.Font = Enum.Font.Code
frame(Stats,18,110,214,1,C.line,0)
text(Stats,'В СЕССИИ',18,131,100,18,9,C.dim,true)
UI.clock = text(Stats,'00:00',137,124,100,30,20,C.muted)
UI.clock.Font = Enum.Font.Code
local Timeline = frame(Fish,0,260,724,66,C.panel,9)
outline(Timeline)
Timeline.BackgroundTransparency = .12
UI.steps = {}
for i,title in ipairs({'Готовность','Зарядка','Поклёвка','Клики'}) do
    local x = 16+(i-1)*177
    UI.steps[i] = text(Timeline,string.format('%02d / %s',i,title),x,10,165,23,11,C.dim)
    UI.steps[i..'bar'] = frame(Timeline,x,46,159,2,C.line,0)
end
UI.status = text(Fish,'Ожидание',0,342,570,28,11,C.muted)
UI.clicks = text(Fish,'0 кликов',602,342,120,28,11,C.dim)
UI.clicks.Font = Enum.Font.Code
UI.clicks.TextXAlignment = Enum.TextXAlignment.Right

local Settings = page('settings')
text(Settings,'Настройки',0,0,480,32,23,C.text,true)
local SettingsCard = frame(Settings,0,48,724,142,C.panel,9)
outline(SettingsCard)
SettingsCard.BackgroundTransparency = .12
local StepRefresh = {}
local function stepper(y,title,key,min,max,step,format)
    text(SettingsCard,title,18,y,425,36,12,C.text)
    local val = text(SettingsCard,'',538,y,104,36,12,C.accent,true)
    val.TextXAlignment = Enum.TextXAlignment.Center
    local function refresh() val.Text = format(Config[key]) end
    local function change(delta)
        Config[key] = math.floor(math.clamp(Config[key]+delta,min,max)/step+.5)*step
        refresh() paint()
    end
    button(SettingsCard,'−',497,y+3,30,30,false,function() change(-step) end)
    button(SettingsCard,'+',660,y+3,46,30,false,function() change(step) end)
    table.insert(StepRefresh,refresh) refresh()
end
stepper(12,'Интервал','ClickInterval',.015,.080,.005,function(v) return string.format('%d мс',math.floor(v*1000+.5)) end)
UI.bindButtons = {}
local function bindRow(y,title,key)
    text(SettingsCard,title,18,y,440,36,12,C.text)
    local b
    b = button(SettingsCard,Config[key].Name,538,y+3,168,30,false,function()
        cancelBind()
        S.binding = key S.bindAt = os.clock()
        b.Text = 'Клавиша…'
        local stamp = S.bindAt
        task.delay(8,function() if S.alive and S.binding and S.bindAt == stamp then cancelBind() end end)
    end)
    UI.bindButtons[key] = b
end
bindRow(54,'Старт / стоп','ToggleKey')
bindRow(96,'Показать / скрыть меню','MenuKey')
cancelBind = function()
    S.binding = false
    for key,b in pairs(UI.bindButtons) do b.Text = Config[key].Name end
end
local Prefs = frame(Settings,0,202,724,136,C.panel,9)
outline(Prefs)
Prefs.BackgroundTransparency = .12
UI.launchSwitch = switch(Prefs,'Плавающая кнопка',18,3,688,true,function(v)
    Config.ShowLauncher = v
    UI.launcher.Visible = not S.visible and v
end)
switch(Prefs,'Защита от кликов по меню',18,47,688,true,function(v) Config.ProtectInput = v end)
switch(Prefs,'Анимация фона',18,91,688,true,function(v) Config.SkyMotion = v end)
Settings.CanvasSize = UDim2.fromOffset(0,392)
button(Settings,'Выгрузить',0,352,130,32,false,function() UI.modal.Visible = true end)
local Info = page('info')
text(Info,'Tempest',0,0,600,32,23,C.text,true)
local function contact(value)
    if type(setclipboard) == 'function' and pcall(setclipboard,value) then notify('Скопировано') else notify(value) end
end
local function contactRow(y,service,value,copy)
    local row = frame(Info,0,y,724,78,C.panel,9)
    outline(row)
    text(row,service,18,12,500,18,10,C.dim,true)
    text(row,value,18,35,580,25,15,C.text,true)
    button(row,'↗',665,23,40,32,false,function() contact(copy) end)
end
contactRow(48,'DISCORD','foreverfame','foreverfame')
contactRow(138,'TELEGRAM','t.me/tempestdevelop','https://t.me/tempestdevelop')

UI.toast = frame(UI.gui,0,0,360,42,C.panel,8)
UI.toast.AnchorPoint = Vector2.new(.5,1)
UI.toast.Position = UDim2.new(.5,0,1,-20)
UI.toast.Visible = false
outline(UI.toast)
UI.toastText = text(UI.toast,'',14,4,332,34,11,C.text)
local toastNumber = 0
notify = function(value)
    toastNumber = toastNumber+1
    local token = toastNumber
    UI.toastText.Text = value UI.toast.Visible = true
    task.delay(3,function() if S.alive and toastNumber == token then UI.toast.Visible = false end end)
end
UI.launcher = frame(UI.gui,24,180,54,50,C.panel,10)
UI.launcher.Active = true
UI.launcher.Visible = false
outline(UI.launcher,C.accent)
UI.launchHandle = new('TextButton',{Size = UDim2.fromScale(1,1),BackgroundTransparency = 1,Text = '//',
    TextSize = 22,Font = Enum.Font.GothamBold,TextColor3 = C.accent,AutoButtonColor = false},UI.launcher)
local dismiss = button(UI.launcher,'×',43,-8,20,20,false,function()
    Config.ShowLauncher = false
    UI.launchSwitch.set(false)
    UI.launcher.Visible = false
    notify('Вернуть меню / '..Config.MenuKey.Name)
end)
dismiss.TextSize = 13
UI.modal = new('TextButton',{Size = UDim2.fromScale(1,1),BackgroundColor3 = C.bg,
    BackgroundTransparency = .08,Text = '',AutoButtonColor = false,Visible = false,ZIndex = 10},UI.main)
local Dialog = frame(UI.modal,170,180,420,158,C.panel,10)
outline(Dialog)
text(Dialog,'Выгрузить скрипт?',20,18,380,35,20,C.text,true)
button(Dialog,'Отмена',20,88,184,40,false,function() UI.modal.Visible = false end)
button(Dialog,'Выгрузить',216,88,184,40,true,function() cleanup() end)
local function compactPhase()
    if not S.enabled then return 'Ожидание' end
    if S.paused or S.blocked then return 'Пауза' end
    return ({'Ожидание','Зарядка','Поклёвка','Клики'})[S.step] or 'Ожидание'
end
paint = function()
    if not S.alive then return end
    local phase = compactPhase()
    local color = not S.enabled and C.muted or (S.paused or S.blocked) and C.accent or C.green
    UI.run.Text = S.enabled and 'Остановить' or 'Запустить'
    UI.pause.Text = S.paused and 'Продолжить' or 'Пауза'
    UI.pause.TextColor3 = S.enabled and C.text or C.dim
    UI.badge.Text = '●  '..phase UI.badge.TextColor3 = color
    UI.compactStatus.Text = '●  '..phase UI.compactStatus.TextColor3 = color
    UI.cycles.Text = string.format('%02d',S.cycles)
    local seconds = math.floor(S.activeSeconds)
    UI.clock.Text = string.format('%02d:%02d',math.floor(seconds/60),seconds%60)
    UI.smallBind.Text = Config.ToggleKey.Name
    UI.keyHint.Text = Config.MenuKey.Name..' / меню'
    UI.clicks.Text = string.format('%d кликов',S.clicks)
    UI.status.Text = S.enabled and (S.blocked and 'Пауза / интерфейс' or S.paused and 'Пауза' or S.phase) or 'Ожидание'
    UI.status.TextColor3 = color
    for i = 1,4 do
        UI.steps[i].TextColor3 = S.enabled and S.step == i and C.accent or C.dim
        UI.steps[i..'bar'].BackgroundColor3 = S.enabled and S.step == i and C.accent or C.line
    end
end
showPage = function(key)
    S.page = key
    for k,p in pairs(UI.pages) do p.Visible = k == key end
    for k,item in pairs(UI.nav) do
        item.b.BackgroundColor3 = k == key and C.hover or C.panel
        item.b.TextColor3 = k == key and C.text or C.muted
        item.line.Visible = k == key
    end
end
showMenu = function(value)
    S.visible = value UI.main.Visible = value
    UI.launcher.Visible = not value and Config.ShowLauncher
    cancelBind() UI.modal.Visible = false
end
setEnabled = function(value)
    if value and not InputAvailable then notify('Нет mouse1press / mouse1release') return end
    if value == S.enabled then return end
    S.enabled = value S.paused = false invalidate()
    status(value and 'Ожидание' or 'Остановлено',value and 1 or 0)
end

local dragInput, dragOrigin, dragPosition, dragTarget, moved
local function cameraSize()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280,720)
end
local function clampPosition(target)
    target = target or UI.main
    local v = cameraSize()
    local size,pos = target.AbsoluteSize,target.AbsolutePosition
    local inset = game:GetService('GuiService'):GetGuiInset()
    local margin = target == UI.launcher and 16 or 8
    local dx = math.clamp(pos.X,margin,math.max(margin,v.X-size.X-margin))-pos.X
    local dy = math.clamp(pos.Y,margin,math.max(margin,v.Y-inset.Y-size.Y-margin))-pos.Y
    local p = target.Position
    target.Position = UDim2.new(p.X.Scale,p.X.Offset+dx,p.Y.Scale,p.Y.Offset+dy)
end
resize = function()
    local v = cameraSize()
    local width,height = S.minimized and 300 or 760,S.minimized and 52 or 530
    UI.scale.Scale = math.min(1,math.max(.1,math.min((v.X-24)/width,(v.Y-60)/height)))
    UI.toast.Size = UDim2.fromOffset(math.min(360,v.X-24),42)
    UI.toastText.Size = UDim2.new(1,-28,1,-8)
    task.defer(function() if S.alive then clampPosition(UI.main) clampPosition(UI.launcher) end end)
end
applyLayout = function()
    UI.main.Size = UDim2.fromOffset(S.minimized and 300 or 760,S.minimized and 52 or 530)
    UI.body.Visible = not S.minimized UI.separator.Visible = not S.minimized
    Sky.layer.Visible = not S.minimized
    UI.brand.Visible = not S.minimized UI.badge.Visible = not S.minimized
    UI.compactStatus.Visible = S.minimized
    UI.min.Position = UDim2.new(1,-90,0,10) UI.close.Position = UDim2.new(1,-50,0,10)
    UI.min.Text = S.minimized and '+' or '−'
    resize()
end
local cameraConn
local function bindCamera()
    if cameraConn then cameraConn:Disconnect() end
    if workspace.CurrentCamera then cameraConn = connect(workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),resize) end
    resize()
end
connect(workspace:GetPropertyChangedSignal('CurrentCamera'),bindCamera)
local function draggable(handle,target)
    connect(handle.InputBegan,function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragInput,dragOrigin,dragPosition,dragTarget,moved = input,input.Position,target.Position,target,false
        end
    end)
end
draggable(UI.drag,UI.main)
draggable(UI.launchHandle,UI.launcher)
connect(UIS.InputChanged,function(input)
    if not dragInput then return end
    if (dragInput.UserInputType == Enum.UserInputType.Touch and input == dragInput)
        or (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = input.Position-dragOrigin
        if d.Magnitude > 6 then moved = true end
        if moved then
            dragTarget.Position = UDim2.new(dragPosition.X.Scale,dragPosition.X.Offset+d.X,dragPosition.Y.Scale,dragPosition.Y.Offset+d.Y)
            clampPosition(dragTarget)
        end
    end
end)
connect(UIS.InputEnded,function(input)
    if input == dragInput or (dragInput and dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
        dragInput = nil dragTarget = nil
    end
end)
connect(UI.launchHandle.Activated,function()
    if not moved then showMenu(true) end
end)
connect(UIS.WindowFocusReleased,function() S.focused = false invalidate() end)
connect(UIS.WindowFocused,function() S.focused = true end)

local Ready, Reel, TextConnections = {}, {}, {}
local function normalize(s)
    s = tostring(s or ''):gsub('<[^>]->',''):gsub('%s+',' ')
    local upper = {'А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я'}
    local lower = {'а','б','в','г','д','е','ё','ж','з','и','й','к','л','м','н','о','п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь','э','ю','я'}
    for i,a in ipairs(upper) do s = s:gsub(a,lower[i]) end
    return string.lower(s)
end
local function contains(s,needle) return string.find(s,needle,1,true) ~= nil end
local ReelPhrases = {'click fast','click quickly','tap rapidly','rapidly click','нажимайте быстро','нажимай быстро','быстро нажим','кликай быстро','быстрые клики'}
local function classify(obj)
    Ready[obj],Reel[obj] = nil,nil
    if not obj.Parent or obj:IsDescendantOf(UI.gui) then return end
    local s = normalize(obj.Text)
    Ready[obj] = (contains(s,'hold to cast') or contains(s,'hold to throw') or
        (contains(s,'удерживайте') and contains(s,'бросить'))) or nil
    for _, phrase in ipairs(ReelPhrases) do
        if contains(s,phrase) then Reel[obj] = true break end
    end
end
local function uncache(obj)
    Ready[obj],Reel[obj] = nil,nil
    if TextConnections[obj] then TextConnections[obj]:Disconnect() TextConnections[obj] = nil end
end
local function cache(obj)
    if obj:IsDescendantOf(UI.gui) then return end
    if not (obj:IsA('TextLabel') or obj:IsA('TextButton') or obj:IsA('TextBox')) or TextConnections[obj] then return end
    classify(obj)
    TextConnections[obj] = obj:GetPropertyChangedSignal('Text'):Connect(function() classify(obj) end)
end
local function visible(obj)
    if not obj:IsDescendantOf(PlayerGui) then return false end
    if obj.TextTransparency >= 1 or obj.AbsoluteSize.X <= 0 or obj.AbsoluteSize.Y <= 0 then return false end
    local p = obj
    while p and p ~= PlayerGui do
        if p:IsA('GuiObject') and not p.Visible then return false end
        if p:IsA('LayerCollector') and not p.Enabled then return false end
        p = p.Parent
    end
    local view = cameraSize()
    local a,b = obj.AbsolutePosition,obj.AbsoluteSize
    return p == PlayerGui and a.X+b.X > 0 and a.Y+b.Y > 0 and a.X < view.X and a.Y < view.Y
end
local function any(list)
    for obj in pairs(list) do if obj.Parent and visible(obj) then return true end end
    return false
end
for _,obj in ipairs(PlayerGui:GetDescendants()) do cache(obj) end
connect(PlayerGui.DescendantAdded,cache)
connect(PlayerGui.DescendantRemoving,uncache)

local function pointerOverMenu()
    if not Config.ProtectInput or not UIS.MouseEnabled then return false end
    local inset = game:GetService('GuiService'):GetGuiInset()
    local point = UIS:GetMouseLocation()-Vector2.new(0,inset.Y)
    local target = S.visible and UI.main or UI.launcher
    local p,size = target.AbsolutePosition,target.AbsoluteSize
    local extra = target == UI.launcher and 12 or 0
    return target.Visible and point.X>=p.X-extra and point.X<=p.X+size.X+extra
        and point.Y>=p.Y-extra and point.Y<=p.Y+size.Y+extra
end
local function canWork(token)
    return S.alive and S.enabled and not S.paused and not S.blocked and S.focused
        and token == S.epoch and not pointerOverMenu() and not UIS:GetFocusedTextBox()
        and not S.binding and not UI.modal.Visible
end
local function sleep(seconds,token)
    local untilTime = os.clock()+seconds
    while os.clock() < untilTime do
        if not canWork(token) then release() return false end
        task.wait(math.min(.025,math.max(0,untilTime-os.clock())))
    end
    return canWork(token)
end
local function press(token)
    if not canWork(token) or not InputAvailable then return false end
    if S.held then return true end
    local ok,err = pcall(pressAPI)
    if not ok then
        setEnabled(false)
        notify('Ошибка ввода: '..tostring(err))
        return false
    end
    S.held = true
    return true
end
local function waitStable(predicate,duration,timeout,token)
    local deadline,stable = os.clock()+timeout,nil
    while canWork(token) and os.clock()<deadline do
        if predicate() then
            stable = stable or os.clock()
            if os.clock()-stable >= duration then return true end
        else stable = nil end
        if not sleep(Config.ScanInterval,token) then return false end
    end
    return false
end
local function cast(token)
    if not any(Ready) then return false end
    status('Начало заброса',2)
    if not press(token) then return false end
    local startDeadline = os.clock()+Config.CastStartTimeout
    while canWork(token) and any(Ready) and os.clock()<startDeadline do
        if not sleep(.02,token) then break end
    end
    if not canWork(token) then release() return false end
    if any(Ready) then
        release()
        status('Проверь удочку',1)
        sleep(1,token)
        return false
    end
    status('Зарядка / 1,05 с',2)
    local started = os.clock()
    S.deadline = started+Config.PerfectCastTime
    local ok = sleep(Config.PerfectCastTime,token)
    release()
    S.deadline = nil
    return ok
end
local function reel(token)
    if not canWork(token) or not S.autoReel then return false end
    local currentPrompt
    local function usable(obj)
        if not obj.Parent or not visible(obj) then return false end
        local parent = obj.Parent
        while parent and parent ~= PlayerGui do
            if parent:IsA('CanvasGroup') and parent.GroupTransparency >= .99 then return false end
            parent = parent.Parent
        end
        return true
    end
    local function readPrompt()
        if not currentPrompt or not Reel[currentPrompt] or not usable(currentPrompt) then
            currentPrompt = nil
            for obj in pairs(Reel) do
                if usable(obj) then currentPrompt = obj break end
            end
        end
        if not currentPrompt then return nil end
        local value = currentPrompt.Text:gsub('<[^>]->',''):match('%(%s*(%d+)%s*%)')
        return currentPrompt,tonumber(value)
    end
    if not readPrompt() or any(Ready) then return false end
    status('Вытаскивание',4)
    S.clicks = 0
    local down = math.clamp(Config.ClickDownTime,.015,.06)
    local interval = math.clamp(Config.ClickInterval,.015,.08)
    local started = os.clock()
    local lastProgress = started
    local lastCounter,missingSince,visibleSince
    local sent = 0
    local function stop(reason)
        release()
        S.waitingCycle = false
        setEnabled(false)
        status(reason,4)
        notify(reason)
        return false
    end
    local function active()
        return canWork(token) and S.autoReel
    end
    local function guardedWait(seconds)
        local deadline = os.clock()+seconds
        while active() do
            if any(Ready) or not readPrompt() then
                release()
                missingSince = missingSince or os.clock()
                visibleSince = nil
                return 'hidden'
            end
            local remaining = deadline-os.clock()
            if remaining <= 0 then return 'ok' end
            task.wait(math.min(.01,remaining))
        end
        release()
        return 'cancelled'
    end
    while active() do
        local now = os.clock()
        local prompt,counter = readPrompt()
        if now-started >= 180 then return stop('Таймаут вытаскивания') end
        if not prompt or any(Ready) then
            release()
            visibleSince = nil
            missingSince = missingSince or now
            if now-missingSince >= .35 then return true end
            task.wait(.015)
        else
            missingSince = nil
            visibleSince = visibleSince or now
            if counter ~= nil then
                S.clicks = counter
                if lastCounter == nil or counter ~= lastCounter then
                    lastCounter = counter
                    lastProgress = now
                end
            end
            if lastCounter ~= nil and sent > 0 and now-lastProgress >= 8 then
                return stop('Счётчик кликов не меняется')
            end
            if now-visibleSince < .08 then
                task.wait(.015)
            else
                if not active() or any(Ready) or not readPrompt() then
                    release()
                elseif not press(token) then
                    release()
                    return false
                else
                    sent = sent+1
                    if counter == nil then S.clicks = sent end
                    local result = guardedWait(down)
                    release()
                    if result == 'cancelled' then return false end
                    if result == 'ok' then
                        result = guardedWait(interval)
                        if result == 'cancelled' then return false end
                    end
                end
            end
        end
    end
    release()
    return false
end
local function nextReady(token)
    status('Завершение',1)
    local ok = waitStable(function() return any(Ready) end,.30,Config.ReadyTimeout,token)
    if ok and S.waitingCycle then
        S.cycles = S.cycles+1
        S.waitingCycle = false
        status('Цикл завершён',1)
        sleep(.2,token)
    elseif canWork(token) then
        S.waitingCycle = false
        status('Таймаут готовности',1)
        sleep(.8,token)
    end
end
local function awaitReel(token)
    status(S.autoReel and 'Поклёвка' or 'Ручное вытаскивание',3)
    local deadline,stable = os.clock()+Config.ReelTimeout,nil
    while canWork(token) and os.clock()<deadline do
        if any(Ready) then
            S.waitingCycle = false
            status('Ожидание',1)
            sleep(.4,token)
            return
        end
        if not S.autoReel then nextReady(token) return end
        if any(Reel) then
            stable = stable or os.clock()
            if os.clock()-stable>=.10 then
                if reel(token) then nextReady(token) end
                return
            end
        else stable = nil end
        if not sleep(Config.ScanInterval,token) then return end
    end
    if canWork(token) then
        S.waitingCycle = false
        status('Нет подсказки',3)
        sleep(.8,token)
    end
end
local function workerCycle(token)
    if any(Reel) and S.autoReel then
        if waitStable(function() return any(Reel) end,.10,1,token) then
            S.waitingCycle = true
            if reel(token) then nextReady(token) end
        end
        return
    end
    if S.autoCast then
        status('Ожидание',1)
        if not waitStable(function() return any(Ready) end,.30,Config.ReadyTimeout,token) then
            if canWork(token) then status('Экипируй удочку',1) sleep(.8,token) end
            return
        end
        if cast(token) then S.waitingCycle = true awaitReel(token) end
    else
        status('Ручной заброс',1)
        if not waitStable(function() return any(Ready) end,.15,Config.ReadyTimeout,token) then return end
        status('Ручной заброс',1)
        if waitStable(function() return not any(Ready) end,.10,Config.ReadyTimeout,token) then
            S.waitingCycle = true
            awaitReel(token)
        end
    end
end

local lastToggle = 0
connect(UIS.InputBegan,function(input,processed)
    if not S.alive or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = input.KeyCode
    if S.binding then
        if key == Enum.KeyCode.Escape then cancelBind()
        elseif key == Enum.KeyCode.Unknown then return
        elseif key == Config[S.binding == 'MenuKey' and 'ToggleKey' or 'MenuKey'] then
            notify('Клавиша уже занята')
        elseif not UIS:GetFocusedTextBox() then
            Config[S.binding] = key cancelBind() paint()
        end
        return
    end
    if UIS:GetFocusedTextBox() or processed then return end
    if key == Config.MenuKey then showMenu(not S.visible)
    elseif key == Config.ToggleKey and os.clock()-lastToggle>.20 then
        lastToggle = os.clock()
        setEnabled(not S.enabled)
    end
end)
local accumulator = 0
connect(RunService.Heartbeat,function(dt)
    if not S.alive then return end
    accumulator = accumulator+dt
    if accumulator<.1 then return end
    local elapsed = accumulator
    accumulator = 0
    local over = pointerOverMenu()
    local blocked = not S.focused or UIS:GetFocusedTextBox() ~= nil or over or S.binding or UI.modal.Visible or dragInput ~= nil
    if blocked ~= S.blocked then
        S.blocked = blocked
        invalidate()
        if not blocked and S.enabled then status('Ожидание',1) end
    end
    if S.enabled and not S.paused and not S.blocked then S.activeSeconds = S.activeSeconds+elapsed end
    paint()
end)
cleanup = function()
    if not S.alive then return end
    S.alive = false S.enabled = false
    invalidate()
    for obj,conn in pairs(TextConnections) do conn:Disconnect() TextConnections[obj] = nil end
    for _,conn in ipairs(Connections) do conn:Disconnect() end
    for _,t in pairs(Tweens) do pcall(function() t:Cancel() end) end
    UI.gui:Destroy()
    if Env.__EggStudioCleanup == cleanup then Env.__EggStudioCleanup = nil end
end
Env.__EggStudioCleanup = cleanup
connect(UI.gui.Destroying,function() if S.alive then cleanup() end end)
bindCamera()
showPage('fish')
applyLayout()
status('Ожидание')
task.spawn(function()
    while S.alive do
        if S.enabled and not S.paused and not S.blocked and S.focused then
            local token = S.epoch
            local ok,err = xpcall(function() workerCycle(token) end,debug.traceback)
            release()
            if not ok and S.alive then
                setEnabled(false)
                warn('[EggStudio] '..tostring(err))
                notify('Ошибка / см. консоль')
            end
        end
        task.wait(.15)
    end
end)
print('[EggStudio] UI ready. Automation OFF. '..Config.ToggleKey.Name..' start/stop; '..Config.MenuKey.Name..' menu.')
