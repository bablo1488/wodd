--[[
        ==============================================================
          WODD VISUALS  -  клиентское меню визуальных настроек
        ==============================================================
          * 100% клиент: ничего не меняет на сервере
          * Insert - открыть/закрыть меню (клавиша меняется в топбаре)
          * World Color - колор-пикер: красит тинт + Ambient + туман + атмосферу
          * Дождь и снег - 3D-частицы вокруг камеры, звук дождя, ветер
          * Гроза - неоновые молнии в небе + звуки грома + тряска камеры
          * Аура: крылья сакуры (офсеты X/Y/Z, взмах, лепестки), нимб, глоу
          * Волны под персонажем: изгибающиеся кольца (скорость/изгиб/офсеты)
          * Темы меню: тёмная и светлая + свой цвет акцента
          * Освещение / Небо / Эффекты / Камера / Аура / Погода / Настройки
          * Пресеты в один клик: День, Закат, Ночь, Кино, Гроза, Снегопад
          * Настройки меню: масштаб, прозрачность, блюр, FPS, автосейв
          * RU / EN переключатель, автосохранение настроек (экзекьютор)

          УСТАНОВКА:
            Studio:     LocalScript -> StarterPlayer -> StarterPlayerScripts
            Экзекьютор: выполнить файл целиком
        ==============================================================
]]

-- ================================ КОНФИГ ================================
local CONFIG = {
        TOGGLE_KEY  = Enum.KeyCode.Insert,            -- клавиша меню
        CONFIG_FILE = "WoddVisuals.json",             -- файл автосейва
        RAIN_SOUND  = "rbxassetid://85638512569947",  -- звук дождя (можно заменить своим ID)
        WIND_SOUND  = "rbxassetid://9118704851",      -- звук ветра (можно заменить своим ID)
        THUNDER_SOUNDS = {                            -- звуки грома (пул, выбирается случайный)
                "rbxassetid://9120019553",
                "rbxassetid://9120019837",
                "rbxassetid://131300621",
                "rbxassetid://262089118",
        },
        PETAL_TEXTURE   = "rbxasset://textures/particles/smoke_main.dds",    -- текстура лепестков сакуры (можно заменить своим rbxassetid://)
        SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds", -- текстура искр нимба (можно заменить своим rbxassetid://)
        ACCENT      = Color3.fromRGB(125, 170, 255),  -- акцент меню
        ACCENT2     = Color3.fromRGB(196, 148, 255),  -- второй акцент (градиенты)
}

-- =============================== СЕРВИСЫ ================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        LocalPlayer = Players.LocalPlayer
end

local IS_STUDIO = RunService:IsStudio()

-- ==================== СРЕДА: КУДА КЛАСТЬ GUI ====================
local function getGuiParent()
        if IS_STUDIO then
                return LocalPlayer:WaitForChild("PlayerGui")
        end
        local ok, hiddenUI = pcall(function()
                if type(gethui) == "function" then
                        return gethui()
                end
                return nil
        end)
        if ok and hiddenUI then
                return hiddenUI
        end
        return game:GetService("CoreGui")
end

-- ================ ПОВТОРНЫЙ ЗАПУСК: ЧИСТИМ СТАРОЕ ================
local function cleanupOld()
        pcall(function()
                RunService:UnbindFromRenderStep("WoddPerFrame")
        end)
        -- возвращаем мир к исходному виду (снимок самого первого запуска за сессию)
        local saved = nil
        pcall(function()
                saved = _G.WoddSavedOrig
        end)
        if type(saved) == "table" then
                pcall(function()
                        Lighting.Brightness               = saved.Brightness
                        Lighting.ClockTime                = saved.ClockTime
                        Lighting.ExposureCompensation     = saved.ExposureCompensation
                        Lighting.GlobalShadows            = saved.GlobalShadows
                        Lighting.ShadowSoftness           = saved.ShadowSoftness
                        Lighting.Ambient                  = saved.Ambient
                        Lighting.OutdoorAmbient           = saved.OutdoorAmbient
                        Lighting.FogColor                 = saved.FogColor
                        Lighting.FogStart                 = saved.FogStart
                        Lighting.FogEnd                   = saved.FogEnd
                        local terr = workspace:FindFirstChildOfClass("Terrain")
                        if terr then
                                terr.WaterWaveSize     = saved.WaterWaveSize
                                terr.WaterWaveSpeed    = saved.WaterWaveSpeed
                                terr.WaterReflectance  = saved.WaterReflectance
                                terr.WaterTransparency = saved.WaterTransparency
                        end
                        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
                        if atmo and saved.AtmoDensity then
                                atmo.Density = saved.AtmoDensity
                                atmo.Offset  = saved.AtmoOffset
                                atmo.Glare   = saved.AtmoGlare
                                atmo.Haze    = saved.AtmoHaze
                                atmo.Color   = saved.AtmoColor
                                atmo.Decay   = saved.AtmoDecay
                        end
                        local sk = Lighting:FindFirstChildOfClass("Sky")
                        if sk and saved.Stars then
                                sk.StarCount            = saved.Stars
                                sk.CelestialBodiesShown = saved.Bodies
                        end
                        local cam = workspace.CurrentCamera
                        if cam and saved.FieldOfView then
                                cam.FieldOfView = saved.FieldOfView
                        end
                end)
        end

        local roots = {}
        local okA, guiA = pcall(getGuiParent)
        if okA and guiA then
                roots[#roots + 1] = guiA
        end
        local okB, guiB = pcall(function()
                return game:GetService("CoreGui")
        end)
        if okB and guiB then
                roots[#roots + 1] = guiB
        end
        local okC, guiC = pcall(function()
                return LocalPlayer:FindFirstChild("PlayerGui")
        end)
        if okC and guiC then
                roots[#roots + 1] = guiC
        end

        for _, root in ipairs(roots) do
                local old = root:FindFirstChild("WoddVisuals")
                if old then
                        old:Destroy()
                end
        end

        for _, inst in ipairs(workspace:GetChildren()) do
                if string.sub(inst.Name, 1, 11) == "WoddWeather" or inst.Name == "WoddAura" then
                        inst:Destroy()
                end
        end
        for _, inst in ipairs(Lighting:GetChildren()) do
                if string.sub(inst.Name, 1, 4) == "Wodd" then
                        inst:Destroy()
                end
        end
        -- хвосты прошлого запуска: болты в камере, глоу/свет на персонаже
        pcall(function()
                local cam = workspace.CurrentCamera
                if cam then
                        for _, inst in ipairs(cam:GetChildren()) do
                                if inst.Name == "WoddBolt" then
                                        inst:Destroy()
                                end
                        end
                end
        end)
        pcall(function()
                local ch = LocalPlayer.Character
                if ch then
                        for _, d in ipairs(ch:GetDescendants()) do
                                if d.Name == "WoddGlow" or d.Name == "WoddGlowLight" then
                                        d:Destroy()
                                end
                        end
                end
        end)
end
cleanupOld()

-- ============== ЗАХВАТ ИСХОДНЫХ ЗНАЧЕНИЙ (для сброса) ==============
local Terrain = workspace:WaitForChild("Terrain")

local ORIG = {}

local startCam = workspace.CurrentCamera
ORIG.FieldOfView = startCam and startCam.FieldOfView or 70

ORIG.Brightness               = Lighting.Brightness
ORIG.ClockTime                = Lighting.ClockTime
ORIG.ExposureCompensation     = Lighting.ExposureCompensation
ORIG.GlobalShadows            = Lighting.GlobalShadows
ORIG.ShadowSoftness           = Lighting.ShadowSoftness
ORIG.EnvironmentDiffuseScale  = Lighting.EnvironmentDiffuseScale
ORIG.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
ORIG.Ambient                  = Lighting.Ambient
ORIG.OutdoorAmbient           = Lighting.OutdoorAmbient
ORIG.FogColor                 = Lighting.FogColor
ORIG.FogStart                 = Lighting.FogStart
ORIG.FogEnd                   = Lighting.FogEnd

ORIG.WaterWaveSize     = Terrain.WaterWaveSize
ORIG.WaterWaveSpeed    = Terrain.WaterWaveSpeed
ORIG.WaterReflectance  = Terrain.WaterReflectance
ORIG.WaterTransparency = Terrain.WaterTransparency

-- Атмосфера: берём существующую или создаём нейтральную (Density 0 = не меняет вид)
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name    = "WoddAtmosphere"
        atmosphere.Density = 0
        atmosphere.Offset  = 0
        atmosphere.Color   = Color3.new(1, 1, 1)
        atmosphere.Decay   = Color3.new(1, 1, 1)
        atmosphere.Glare   = 0
        atmosphere.Haze    = 0
        atmosphere.Parent  = Lighting
end

-- Небо: берём существующее или создаём стандартное
local sky = Lighting:FindFirstChildOfClass("Sky")
if not sky then
        sky = Instance.new("Sky")
        sky.Name   = "WoddSky"
        sky.Parent = Lighting
end

ORIG.AtmoDensity = atmosphere.Density
ORIG.AtmoOffset  = atmosphere.Offset
ORIG.AtmoGlare   = atmosphere.Glare
ORIG.AtmoHaze    = atmosphere.Haze
ORIG.AtmoColor   = atmosphere.Color
ORIG.AtmoDecay   = atmosphere.Decay
ORIG.Stars       = sky.StarCount
ORIG.Bodies      = sky.CelestialBodiesShown


-- снимок исходных значений для повторных запусков в этой же сессии
pcall(function()
        _G.WoddSavedOrig = ORIG
end)

-- ===================== ПОСТ-ЭФФЕКТЫ (НАШИ ЭКЗЕМПЛЯРЫ) =====================
local function newEffect(className, props)
        local inst = Instance.new(className)
        for k, v in pairs(props) do
                inst[k] = v
        end
        inst.Parent = Lighting
        return inst
end

local colorCorrection = newEffect("ColorCorrectionEffect", {
        Name = "WoddCC", Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1),
})
local bloom = newEffect("BloomEffect", {
        Name = "WoddBloom", Intensity = 0, Size = 24, Threshold = 0.95,
})
local sunRays = newEffect("SunRaysEffect", {
        Name = "WoddSunRays", Intensity = 0, Spread = 0.5,
})
local blur = newEffect("BlurEffect", {
        Name = "WoddBlur", Size = 0,
})
local dof = newEffect("DepthOfFieldEffect", {
        Name = "WoddDoF", Enabled = false, FarIntensity = 0.2, NearIntensity = 0, FocusDistance = 35, InFocusRadius = 40,
})

local menuBlur = newEffect("BlurEffect", {
        Name = "WoddMenuBlur", Size = 0,
})

-- ============================ ДВИЖОК ПОГОДЫ ============================
local weatherPart = Instance.new("Part")
weatherPart.Name         = "WoddWeather"
weatherPart.Anchored     = true
weatherPart.CanCollide   = false
weatherPart.CanQuery     = false
weatherPart.CanTouch     = false
weatherPart.CastShadow   = false
weatherPart.Transparency = 1
weatherPart.Size         = Vector3.new(130, 1, 130)
weatherPart.CFrame       = CFrame.new(0, 5000, 0)
weatherPart.Parent       = workspace

local snowPart = Instance.new("Part")
snowPart.Name         = "WoddWeatherSnow"
snowPart.Anchored     = true
snowPart.CanCollide   = false
snowPart.CanQuery     = false
snowPart.CanTouch     = false
snowPart.CastShadow   = false
snowPart.Transparency = 1
snowPart.Size         = Vector3.new(90, 1, 90)
snowPart.CFrame       = CFrame.new(0, 5000, 0)
snowPart.Parent       = workspace

-- Дождь: капли-шлейфы (Squash растягивает частицу вертикально)
local rainEmitter = Instance.new("ParticleEmitter")
rainEmitter.Name              = "WoddRain"
rainEmitter.Texture           = "rbxasset://textures/particles/sparkles_main.dds"
rainEmitter.Shape             = Enum.ParticleEmitterShape.Box
rainEmitter.ShapeStyle        = Enum.ParticleEmitterShapeStyle.Volume
rainEmitter.EmissionDirection = Enum.NormalId.Bottom
rainEmitter.Speed             = NumberRange.new(55)
rainEmitter.Lifetime          = NumberRange.new(0.6, 0.7)
rainEmitter.Rate              = 0
rainEmitter.Size              = NumberSequence.new(0.35)
rainEmitter.Squash            = NumberSequence.new(3.5)
rainEmitter.Transparency      = NumberSequence.new(0.35)
rainEmitter.Color             = ColorSequence.new(Color3.fromRGB(180, 200, 230))
rainEmitter.LightEmission     = 0.6
rainEmitter.LightInfluence    = 0
rainEmitter.Rotation          = NumberRange.new(0, 0)
rainEmitter.Enabled           = false
rainEmitter.Parent            = weatherPart

-- Снег: медленные вращающиеся хлопья с ветром
local snowEmitter = Instance.new("ParticleEmitter")
snowEmitter.Name              = "WoddSnow"
snowEmitter.Texture           = "rbxasset://textures/particles/sparkles_main.dds"
snowEmitter.Shape             = Enum.ParticleEmitterShape.Box
snowEmitter.ShapeStyle        = Enum.ParticleEmitterShapeStyle.Volume
snowEmitter.EmissionDirection = Enum.NormalId.Bottom
snowEmitter.Speed             = NumberRange.new(7)
snowEmitter.Lifetime          = NumberRange.new(4, 5)
snowEmitter.Rate              = 0
snowEmitter.Size              = NumberSequence.new(0.45)
snowEmitter.Rotation          = NumberRange.new(-180, 180)
snowEmitter.RotSpeed          = NumberRange.new(-40, 40)
snowEmitter.Transparency      = NumberSequence.new(0.1)
snowEmitter.Color             = ColorSequence.new(Color3.new(1, 1, 1))
snowEmitter.LightEmission     = 0.3
snowEmitter.LightInfluence    = 0
snowEmitter.Enabled           = false
snowEmitter.Parent            = snowPart

local rainSound = Instance.new("Sound")
rainSound.Name    = "WoddRainSound"
rainSound.SoundId = CONFIG.RAIN_SOUND
rainSound.Looped  = true
rainSound.Volume  = 0.5

local windSound = Instance.new("Sound")
windSound.Name    = "WoddWindSound"
windSound.SoundId = CONFIG.WIND_SOUND
windSound.Looped  = true
windSound.Volume  = 0

local thunderPool = {}
for i = 1, 4 do
        local snd = Instance.new("Sound")
        snd.Name   = "WoddThunder" .. i
        snd.Volume = 0
        thunderPool[i] = snd
end
local thunderIdx = 0

-- ============================== СОСТОЯНИЕ ==============================
local S = {
        -- World Color
        world_color    = {1, 1, 1},
        world_strength = 1,
        sync_ambient   = true,
        sync_fog       = true,
        sync_atmo      = true,

        -- Освещение
        light_brightness = ORIG.Brightness,
        light_time       = ORIG.ClockTime,
        light_exposure   = ORIG.ExposureCompensation,
        light_shadows    = ORIG.GlobalShadows,
        light_softness   = ORIG.ShadowSoftness,
        light_diffuse    = ORIG.EnvironmentDiffuseScale,
        light_specular   = ORIG.EnvironmentSpecularScale,

        -- Небо / туман / вода
        atmo_density      = atmosphere.Density,
        atmo_offset       = atmosphere.Offset,
        atmo_glare        = atmosphere.Glare,
        atmo_haze         = atmosphere.Haze,
        fog_start         = ORIG.FogStart,
        fog_end           = ORIG.FogEnd,
        water_wavesize    = ORIG.WaterWaveSize,
        water_wavespeed   = ORIG.WaterWaveSpeed,
        water_reflect     = ORIG.WaterReflectance,
        water_transparent = ORIG.WaterTransparency,
        sky_stars         = sky.StarCount,
        sky_bodies        = sky.CelestialBodiesShown,

        -- Цветокоррекция
        cc_brightness = 0,
        cc_contrast   = 0,
        cc_saturation = 0,

        -- Пост-эффекты
        bloom_intensity = 0,
        bloom_size      = 24,
        bloom_threshold = 0.95,
        sunrays_intensity = 0,
        sunrays_spread    = 0.5,
        blur_size       = 0,
        dof_enabled     = false,
        dof_far         = 0.2,
        dof_focus       = 35,
        dof_radius      = 40,

        -- Камера
        cam_fov        = ORIG.FieldOfView,
        cam_fov_smooth = true,
        cam_roll       = 0,

        hide_char = false,

        -- Погода
        rain_enabled      = false,
        rain_intensity    = 40,
        rain_speed        = 55,
        rain_size         = 0.35,
        rain_transparency = 0.35,
        rain_color        = {180 / 255, 200 / 255, 230 / 255},
        rain_sound        = true,
        rain_volume       = 0.5,

        snow_enabled      = false,
        snow_intensity    = 35,
        snow_speed        = 7,
        snow_size         = 0.45,
        snow_transparency = 0.1,
        snow_color        = {1, 1, 1},

        wind        = 0,
        lightning   = false,

        -- Гроза
        thunder        = true,
        thunder_volume = 0.8,
        bolts          = true,
        storm_shake    = false,
        wind_sound     = true,

        -- Аура: крылья сакуры
        wings_enabled   = false,
        wings_color     = {1, 0.62, 0.78},
        wings_scale     = 1,
        wings_ox        = 0,
        wings_oy        = 0.5,
        wings_oz        = 0.8,
        wings_opacity   = 0.25,
        wings_flap      = 1,
        wings_particles = true,

        -- Аура: нимб
        nimbus_enabled   = false,
        nimbus_color     = {1, 0.82, 0.4},
        nimbus_scale     = 1,
        nimbus_ox        = 0,
        nimbus_oy        = 2.1,
        nimbus_oz        = 0,
        nimbus_spin      = 0.6,
        nimbus_glow      = 1.2,
        nimbus_particles = true,

        -- Аура: глоу персонажа
        glow_enabled = false,
        glow_color   = {0.55, 0.7, 1},
        glow_fill    = 0.55,
        glow_outline = 0.35,
        glow_light   = 1,
        glow_pulse   = false,
        glow_through = false,

        -- Аура: волны под персонажем
        waves_enabled = false,
        waves_color   = {0.45, 0.75, 1},
        waves_scale   = 1,
        waves_speed   = 1,
        waves_bend    = 0.45,
        waves_opacity = 0.18,
        waves_ox      = 0,
        waves_oy      = -2.8,
        waves_oz      = 0,

        -- Интерфейс (вкладка Настройки)
        ui_scale        = 1,
        ui_transparency = 0.22,
        ui_blur         = false,
        ui_fps          = false,
        ui_autosave     = true,
        ui_lang         = "ru",
        watermark       = true,
        char_tag        = true,
        ui_dark         = true,
        ui_accent       = {125 / 255, 170 / 255, 1},
}

-- Снимок "заводских" настроек (до загрузки конфига) — для кнопки Сброс
local function copyState(src)
        local dst = {}
        for k, v in pairs(src) do
                if type(v) == "table" then
                        dst[k] = {v[1], v[2], v[3]}
                else
                        dst[k] = v
                end
        end
        return dst
end
local S0 = copyState(S)

-- ====================== АВТОСОХРАНЕНИЕ (ЭКЗЕКЬЮТОР) ======================
local function serializeState()
        local data = {}
        for k, v in pairs(S) do
                if type(v) == "table" then
                        data[k] = {r = v[1], g = v[2], b = v[3]}
                else
                        data[k] = v
                end
        end
        return HttpService:JSONEncode(data)
end

local function loadSavedConfig()
        if IS_STUDIO then
                return
        end
        if type(isfile) ~= "function" or type(readfile) ~= "function" then
                return
        end
        pcall(function()
                if isfile(CONFIG.CONFIG_FILE) then
                        local raw = readfile(CONFIG.CONFIG_FILE)
                        local data = HttpService:JSONDecode(raw)
                        for k, v in pairs(data) do
                                if S[k] ~= nil then
                                        if type(v) == "table" and type(S[k]) == "table" then
                                                S[k] = {v.r or v[1] or 1, v.g or v[2] or 1, v.b or v[3] or 1}
                                        elseif type(v) == type(S[k]) then
                                                S[k] = v
                                        end
                                end
                        end
                end
        end)
end

local saveDirty = false
local function scheduleSave()
        if S.ui_autosave == false then
                return
        end
        saveDirty = true
        task.delay(0.8, function()
                if not saveDirty then
                        return
                end
                saveDirty = false
                if IS_STUDIO then
                        return
                end
                if type(writefile) ~= "function" then
                        return
                end
                pcall(function()
                        writefile(CONFIG.CONFIG_FILE, serializeState())
                end)
        end)
end

-- ============================ ПРИМЕНЕНИЕ ============================
local function applyWorldColor()
        local c = S.world_color
        local base = Color3.new(c[1], c[2], c[3])
        local tint = Color3.new(1, 1, 1):Lerp(base, S.world_strength)
        colorCorrection.TintColor = tint
        if S.sync_ambient then
                Lighting.Ambient        = tint
                Lighting.OutdoorAmbient = tint
        end
        if S.sync_fog then
                Lighting.FogColor = tint
        end
        if S.sync_atmo then
                atmosphere.Color = tint
                atmosphere.Decay = tint
        end
end

local function applyLighting()
        Lighting.Brightness               = S.light_brightness
        Lighting.ClockTime                = S.light_time
        Lighting.ExposureCompensation     = S.light_exposure
        Lighting.GlobalShadows            = S.light_shadows
        Lighting.ShadowSoftness           = S.light_softness
        Lighting.EnvironmentDiffuseScale  = S.light_diffuse
        Lighting.EnvironmentSpecularScale = S.light_specular
end

local function applySky()
        atmosphere.Density = S.atmo_density
        atmosphere.Offset  = S.atmo_offset
        atmosphere.Glare   = S.atmo_glare
        atmosphere.Haze    = S.atmo_haze
        Lighting.FogStart  = S.fog_start
        Lighting.FogEnd    = S.fog_end
        Terrain.WaterWaveSize    = S.water_wavesize
        Terrain.WaterWaveSpeed   = S.water_wavespeed
        Terrain.WaterReflectance = S.water_reflect
        Terrain.WaterTransparency = S.water_transparent
        sky.StarCount            = S.sky_stars
        sky.CelestialBodiesShown = S.sky_bodies
end

local function applyEffects()
        colorCorrection.Brightness = S.cc_brightness
        colorCorrection.Contrast   = S.cc_contrast
        colorCorrection.Saturation = S.cc_saturation
        bloom.Intensity = S.bloom_intensity
        bloom.Size      = S.bloom_size
        bloom.Threshold = S.bloom_threshold
        sunRays.Intensity = S.sunrays_intensity
        sunRays.Spread    = S.sunrays_spread
        blur.Size    = S.blur_size
        dof.Enabled        = S.dof_enabled
        dof.FarIntensity   = S.dof_far
        dof.FocusDistance  = S.dof_focus
        dof.InFocusRadius  = S.dof_radius
end

local function updateRainSound()
        rainSound.Volume = S.rain_volume
        local want = S.rain_enabled and S.rain_sound
        if want and not rainSound.IsPlaying then
                rainSound:Play()
        elseif not want and rainSound.IsPlaying then
                rainSound:Stop()
        end
end

local function updateWindSound()
        local vol = math.abs(S.wind) / 10 * 0.7
        local want = S.wind_sound and vol > 0.03 and (S.rain_enabled or S.snow_enabled)
        if want and not windSound.IsPlaying then
                windSound:Play()
        elseif not want and windSound.IsPlaying then
                windSound:Stop()
        end
        if want then
                windSound.Volume = vol
        end
end

local function applyWeather()
        -- Облако частиц: большое поле ВЫШЕ камеры; время жизни с запасом,
        -- чтобы частицы пролетали НИЖЕ уровня глаз — при ходьбе дождь/снег
        -- не обрывается и не выглядит начавшимся заново.
        local rainLife = math.clamp(57 / math.max(S.rain_speed, 1) * 1.25, 0.5, 1.6)
        rainEmitter.Enabled      = S.rain_enabled
        rainEmitter.Rate         = S.rain_intensity / 100 * 8000
        rainEmitter.Speed        = NumberRange.new(S.rain_speed)
        rainEmitter.Lifetime     = NumberRange.new(rainLife * 0.85, rainLife * 1.05)
        rainEmitter.Size         = NumberSequence.new(S.rain_size)
        rainEmitter.Transparency = NumberSequence.new(S.rain_transparency)
        local rc = S.rain_color
        rainEmitter.Color       = ColorSequence.new(Color3.new(rc[1], rc[2], rc[3]))
        rainEmitter.Acceleration = Vector3.new(S.wind * 0.4, 0, 0)

        local snowLife = math.clamp(45 / math.max(S.snow_speed, 1) * 1.15, 1.5, 12)
        snowEmitter.Enabled      = S.snow_enabled
        snowEmitter.Rate         = S.snow_intensity / 100 * 1200
        snowEmitter.Speed        = NumberRange.new(S.snow_speed)
        snowEmitter.Lifetime     = NumberRange.new(snowLife * 0.9, snowLife * 1.05)
        snowEmitter.Size         = NumberSequence.new(S.snow_size)
        snowEmitter.Transparency = NumberSequence.new(S.snow_transparency)
        local sc = S.snow_color
        snowEmitter.Color       = ColorSequence.new(Color3.new(sc[1], sc[2], sc[3]))
        snowEmitter.Acceleration = Vector3.new(S.wind, 0, 0)

        updateRainSound()
        updateWindSound()
end

-- forward-объявления ауры (определены ниже, блок "АУРА")
local applyAura
local auraReset
local menuThemeChanged -- перекраска меню (присваивается в части UI)

-- какое применение дёргать при смене цвета из пикера
local function applyColorDependent(key)
        if key == "world_color" then
                applyWorldColor()
        elseif key == "rain_color" or key == "snow_color" then
                applyWeather()
        elseif key == "wings_color" or key == "nimbus_color" or key == "glow_color" or key == "waves_color" then
                applyAura()
        elseif key == "ui_accent" then
                if menuThemeChanged then
                        menuThemeChanged()
                end
        end
end

-- ===================== КАДРОВЫЙ ЦИКЛ (камера/FOV/наклон) =====================
local runFlag = true
local shakeAmp = 0
local perFrameHooks = {}

-- ============== СКРЫТИЕ ПЕРСОНАЖА (чисто клиентски) ==============
local charVisuals = {}
local function rebuildCharVisuals()
        charVisuals = {}
        local char = LocalPlayer.Character
        if not char then
                return
        end
        for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then
                        charVisuals[#charVisuals + 1] = {inst = d, orig = nil, isDecal = false}
                elseif d:IsA("Decal") then
                        charVisuals[#charVisuals + 1] = {inst = d, orig = d.Transparency, isDecal = true}
                end
        end
end
local function refreshCharVisuals()
        rebuildCharVisuals()
end
local hideCharApplied = false
local auraResetOnSpawn -- присваивается ниже (блок "АУРА")
LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.3)
        rebuildCharVisuals()
        if auraResetOnSpawn then
                auraResetOnSpawn()
        end
end)
rebuildCharVisuals()

-- ВАЖНО: правильное имя API — BindToRenderStep (без "ped")
RunService:BindToRenderStep("WoddPerFrame", Enum.RenderPriority.Camera.Value + 2, function(dt)
        local cam = workspace.CurrentCamera
        if not cam then
                return
        end
        -- облако погоды жёстко следует за камерой (уже испущенные частицы остаются в мире)
        if weatherPart.Parent then
                weatherPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 45, 0))
        end
        if snowPart.Parent then
                snowPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 35, 0))
        end
        if S.cam_fov_smooth then
                local current = cam.FieldOfView
                cam.FieldOfView = current + (S.cam_fov - current) * 0.18
        else
                cam.FieldOfView = S.cam_fov
        end
        if math.abs(S.cam_roll) > 0.05 then
                cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, math.rad(S.cam_roll))
        end
        -- тряска камеры при ударе молнии
        if shakeAmp > 0.003 then
                cam.CFrame = cam.CFrame * CFrame.Angles(
                        (math.random() - 0.5) * shakeAmp * 0.08,
                        (math.random() - 0.5) * shakeAmp * 0.08,
                        (math.random() - 0.5) * shakeAmp * 0.12
                )
                shakeAmp = shakeAmp * 0.9
        end
        -- скрытие персонажа
        if S.hide_char then
                for _, item in ipairs(charVisuals) do
                        if item.isDecal then
                                item.inst.Transparency = 1
                        else
                                item.inst.LocalTransparencyModifier = 1
                        end
                end
                hideCharApplied = true
        elseif hideCharApplied then
                for _, item in ipairs(charVisuals) do
                        if item.isDecal then
                                item.inst.Transparency = item.orig
                        else
                                item.inst.LocalTransparencyModifier = 0
                        end
                end
                hideCharApplied = false
        end
        -- хуки (FPS-счётчик и т.п.)
        for i = 1, #perFrameHooks do
                perFrameHooks[i](dt)
        end
end)

-- ============================== МОЛНИИ ==============================
local boltFolder = nil

local function clearBolt()
        if boltFolder then
                pcall(function()
                        boltFolder:Destroy()
                end)
                boltFolder = nil
        end
end

-- неоновая зигзаг-молния в небе (видна только этому игроку — парент в камеру)
local function spawnBolt()
        local cam = workspace.CurrentCamera
        if not cam then
                return
        end
        clearBolt()

        local origin = cam.CFrame.Position
        local yaw    = (math.random() - 0.5) * math.rad(140)
        local dist   = 120 + math.random() * 220
        local look   = (CFrame.new(origin) * CFrame.Angles(0, yaw, 0)).LookVector
        local top    = origin + look * dist + Vector3.new(0, 120 + math.random() * 90, 0)
        local bottom = origin + look * dist + Vector3.new(0, -20 - math.random() * 20, 0)

        local pts = {top}
        local segs = 9 + math.random(3)
        for i = 1, segs do
                local t = i / segs
                pts[#pts + 1] = Vector3.new(
                        top.X + (bottom.X - top.X) * t + (math.random() - 0.5) * 18,
                        top.Y + (bottom.Y - top.Y) * t,
                        top.Z + (bottom.Z - top.Z) * t + (math.random() - 0.5) * 18
                )
        end

        local folder = Instance.new("Folder")
        folder.Name = "WoddBolt"

        local width = 0.7 + math.random() * 0.8
        local segParts = {}
        for i = 1, #pts - 1 do
                local a = pts[i]
                local b = pts[i + 1]
                local len = (b - a).Magnitude
                if len > 1 then
                        local part = Instance.new("Part")
                        part.Anchored     = true
                        part.CanCollide   = false
                        part.CanQuery     = false
                        part.CanTouch     = false
                        part.CastShadow   = false
                        part.Material     = Enum.Material.Neon
                        part.Color        = Color3.fromRGB(225, 235, 255)
                        part.Transparency = 0.05
                        part.Size         = Vector3.new(width * (0.7 + math.random() * 0.6), width * (0.7 + math.random() * 0.6), len)
                        part.CFrame       = CFrame.lookAt((a + b) / 2, b)
                        part.Parent       = folder
                        segParts[#segParts + 1] = part
                end
        end

        -- пара коротких ответвлений
        for _ = 1, math.random(1, 2) do
                local prev = pts[math.random(3, math.max(3, #pts - 3))]
                local bdir = Vector3.new(math.random() - 0.5, -0.9 - math.random() * 0.5, math.random() - 0.5).Unit
                local stepLen = 8 + math.random() * 10
                for _ = 1, 3 do
                        local nxt = prev + bdir * stepLen + Vector3.new((math.random() - 0.5) * 6, 0, (math.random() - 0.5) * 6)
                        local len = (nxt - prev).Magnitude
                        if len > 1 then
                                local part = Instance.new("Part")
                                part.Anchored     = true
                                part.CanCollide   = false
                                part.CanQuery     = false
                                part.CanTouch     = false
                                part.CastShadow   = false
                                part.Material     = Enum.Material.Neon
                                part.Color        = Color3.fromRGB(225, 235, 255)
                                part.Transparency = 0.25
                                part.Size         = Vector3.new(width * 0.45, width * 0.45, len)
                                part.CFrame       = CFrame.lookAt((prev + nxt) / 2, nxt)
                                part.Parent       = folder
                                segParts[#segParts + 1] = part
                        end
                        prev = nxt
                end
        end

        -- световая вспышка у середины болта
        if segParts[4] then
                local light = Instance.new("PointLight")
                light.Brightness = 10
                light.Range      = 140
                light.Color      = Color3.fromRGB(210, 225, 255)
                light.Parent     = segParts[4]
        end

        folder.Parent = cam
        boltFolder = folder

        -- мерцание и затухание
        task.spawn(function()
                local seq = {0.05, 0, 0.15, 0.02, 0.35, 0.2, 0.7, 1}
                for _, tr in ipairs(seq) do
                        if not folder.Parent then
                                return
                        end
                        for _, p in ipairs(segParts) do
                                p.Transparency = math.clamp(tr + (math.random() - 0.5) * 0.1, 0, 1)
                        end
                        task.wait(0.04 + math.random() * 0.05)
                end
                if folder.Parent then
                        folder:Destroy()
                end
                if boltFolder == folder then
                        boltFolder = nil
                end
        end)
end

-- ============================== ГРОМ ==============================
local function playThunder()
        local ids = CONFIG.THUNDER_SOUNDS
        if #ids == 0 then
                return
        end
        thunderIdx = (thunderIdx % #thunderPool) + 1
        local snd = thunderPool[thunderIdx]
        snd.SoundId       = ids[math.random(#ids)]
        snd.Volume        = (0.45 + math.random() * 0.55) * S.thunder_volume
        snd.PlaybackSpeed = 0.8 + math.random() * 0.35
        snd:Play()
end

local function tweenBrightness(toValue, dur)
        local tw = TweenService:Create(
                colorCorrection,
                TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Brightness = toValue}
        )
        tw:Play()
end

local function lightningStrike()
        -- двойная вспышка на экране
        task.spawn(function()
                local base = S.cc_brightness
                local peak = math.clamp(base + 0.4 + math.random() * 0.3, -3, 3)
                tweenBrightness(peak, 0.05)
                task.wait(0.07)
                tweenBrightness(base + (peak - base) * 0.3, 0.1)
                task.wait(0.12)
                if math.random() < 0.65 then
                        tweenBrightness(peak * 0.85, 0.04)
                        task.wait(0.06)
                end
                tweenBrightness(base, 0.5)
        end)

        if S.bolts then
                spawnBolt()
        end
        if S.storm_shake then
                shakeAmp = 0.55 + math.random() * 0.3
        end
        if S.thunder then
                task.delay(0.12 + math.random(), function()
                        if runFlag and S.thunder then
                                playThunder()
                        end
                end)
        end
end

task.spawn(function()
        while runFlag do
                if not S.lightning then
                        task.wait(0.4)
                else
                        task.wait(2.5 + math.random() * 7)
                        if runFlag and S.lightning then
                                lightningStrike()
                        end
                end
        end
end)

-- ============================== АУРА (крылья / нимб / глоу) ==============================
-- Всё чисто клиентское: детали живут в workspace/WoddAura и каждый кадр
-- позиционируются относительно HumanoidRootPart — никаких сварок и сервера.
-- Офсеты X/Y/Z, размер, взмах, вращение применяются на лету.

local auraFolder, auraHighlight, auraGlowLight = nil, nil, nil
local wingAnchor, petalEmitter = nil, nil
local nimbusAnchor, nimbusLight, sparkleEmitter = nil, nil, nil
local wingParts, wingData, nimbusSegs, waveSegs = {}, {}, {}, {}
local auraVis = {wings = false, nimbus = false, waves = false}
local auraTime = 0

local NIMBUS_SEGS = 22
-- силуэт крыла: угол от вертикали (градусы) + длина пера (стадs)
local WING_LAYOUT = {
        {ang = 14,  len = 3.0},
        {ang = 34,  len = 3.3},
        {ang = 54,  len = 3.1},
        {ang = 72,  len = 2.6},
        {ang = 88,  len = 2.0},
        {ang = 102, len = 1.45},
}
local NIMBUS_TILT = CFrame.Angles(math.rad(-8), 0, 0)
local WAVE_RINGS = 3 -- сколько колец волн под персонажем
local WAVE_SEGS  = 22 -- сегментов в каждом кольце

local function newAuraPart(name, parent)
        local p = Instance.new("Part")
        p.Name         = name
        p.Anchored     = true
        p.CanCollide   = false
        p.CanQuery     = false
        p.CanTouch     = false
        p.CastShadow   = false
        p.Transparency = 1
        p.Size         = Vector3.new(0.1, 0.1, 0.1)
        p.Parent       = parent
        return p
end

local function auraTeardown()
        if auraFolder then
                pcall(function()
                        auraFolder:Destroy()
                end)
                auraFolder = nil
        end
        if auraHighlight then
                pcall(function()
                        auraHighlight:Destroy()
                end)
                auraHighlight = nil
        end
        if auraGlowLight then
                pcall(function()
                        auraGlowLight:Destroy()
                end)
                auraGlowLight = nil
        end
        wingParts, wingData, nimbusSegs, waveSegs = {}, {}, {}, {}
        wingAnchor, petalEmitter = nil, nil
        nimbusAnchor, nimbusLight, sparkleEmitter = nil, nil, nil
        auraVis.wings, auraVis.nimbus, auraVis.waves = false, false, false
end

local function ensureAura()
        if auraFolder and auraFolder.Parent then
                return
        end
        auraTeardown()
        auraFolder = Instance.new("Folder")
        auraFolder.Name = "WoddAura"

        -- якорь лепестков у крыльев
        wingAnchor = newAuraPart("WoddWingAnchor", auraFolder)
        petalEmitter = Instance.new("ParticleEmitter")
        petalEmitter.Name              = "WoddPetals"
        petalEmitter.Texture           = CONFIG.PETAL_TEXTURE
        petalEmitter.Shape             = Enum.ParticleEmitterShape.Box
        petalEmitter.ShapeStyle        = Enum.ParticleEmitterShapeStyle.Volume
        petalEmitter.EmissionDirection = Enum.NormalId.Bottom
        petalEmitter.Rate              = 12
        petalEmitter.Speed             = NumberRange.new(1.2, 2)
        petalEmitter.Lifetime          = NumberRange.new(1.8, 2.8)
        petalEmitter.Size              = NumberSequence.new(0.3)
        petalEmitter.Rotation          = NumberRange.new(-180, 180)
        petalEmitter.RotSpeed          = NumberRange.new(-90, 90)
        petalEmitter.Transparency      = NumberSequence.new(0.25)
        petalEmitter.LightEmission     = 0.35
        petalEmitter.LightInfluence    = 0
        petalEmitter.Drag              = 1.2
        petalEmitter.Acceleration      = Vector3.new(0, -2.2, 0)
        petalEmitter.Enabled           = false
        petalEmitter.Parent            = wingAnchor

        -- якорь искр у нимба + свет
        nimbusAnchor = newAuraPart("WoddNimbusAnchor", auraFolder)
        nimbusLight = Instance.new("PointLight")
        nimbusLight.Name       = "WoddNimbusLight"
        nimbusLight.Enabled    = false
        nimbusLight.Shadows    = false
        nimbusLight.Range      = 7
        nimbusLight.Parent     = nimbusAnchor
        sparkleEmitter = Instance.new("ParticleEmitter")
        sparkleEmitter.Name              = "WoddSparkles"
        sparkleEmitter.Texture           = CONFIG.SPARKLE_TEXTURE
        sparkleEmitter.Shape             = Enum.ParticleEmitterShape.Box
        sparkleEmitter.ShapeStyle        = Enum.ParticleEmitterShapeStyle.Volume
        sparkleEmitter.EmissionDirection = Enum.NormalId.Bottom
        sparkleEmitter.Rate              = 8
        sparkleEmitter.Speed             = NumberRange.new(0.4, 0.8)
        sparkleEmitter.Lifetime          = NumberRange.new(1.2, 2)
        sparkleEmitter.Size              = NumberSequence.new(0.22)
        sparkleEmitter.RotSpeed          = NumberRange.new(-40, 40)
        sparkleEmitter.Transparency      = NumberSequence.new(0.2)
        sparkleEmitter.LightEmission     = 0.9
        sparkleEmitter.LightInfluence    = 0
        sparkleEmitter.Drag              = 1
        sparkleEmitter.Acceleration      = Vector3.new(0, -1, 0)
        sparkleEmitter.Enabled           = false
        sparkleEmitter.Parent            = nimbusAnchor

        -- перья крыльев: 2 стороны x 6 перьев + мягкая оболочка у каждого
        for side = -1, 1, 2 do
                for i, spec in ipairs(WING_LAYOUT) do
                        local feather = newAuraPart("WoddFeather", auraFolder)
                        feather.Material = Enum.Material.Neon
                        local shell = newAuraPart("WoddFeatherAura", auraFolder)
                        shell.Material = Enum.Material.Neon
                        wingParts[#wingParts + 1] = {feather = feather, shell = shell}
                        wingData[#wingData + 1] = {
                                side = side,
                                ang  = math.rad(spec.ang),
                                len  = spec.len,
                                k    = i / #WING_LAYOUT,
                        }
                end
        end

        -- сегменты кольца нимба
        for i = 1, NIMBUS_SEGS do
                local seg = newAuraPart("WoddNimbusSeg", auraFolder)
                seg.Material = Enum.Material.Neon
                local shell = newAuraPart("WoddNimbusHalo", auraFolder)
                shell.Material = Enum.Material.Neon
                nimbusSegs[i] = {part = seg, shell = shell, a = (i / NIMBUS_SEGS) * math.pi * 2}
        end

        -- кольца волн под персонажем (изгибаются бегущей синусоидой)
        for ring = 1, WAVE_RINGS do
                for i = 1, WAVE_SEGS do
                        local seg = newAuraPart("WoddWaveSeg", auraFolder)
                        seg.Material = Enum.Material.Neon
                        local shell = newAuraPart("WoddWaveGlow", auraFolder)
                        shell.Material = Enum.Material.Neon
                        waveSegs[#waveSegs + 1] = {
                                part  = seg,
                                shell = shell,
                                a     = (i / WAVE_SEGS) * math.pi * 2,
                                ring  = ring,
                        }
                end
        end

        auraFolder.Parent = workspace
end

applyAura = function()
        local char = LocalPlayer.Character

        -- ГЛОУ: Highlight на персонаже (создаём/убираем только при переключении)
        if S.glow_enabled and char then
                if not auraHighlight or auraHighlight.Parent ~= char then
                        if auraHighlight then
                                pcall(function()
                                        auraHighlight:Destroy()
                                end)
                        end
                        auraHighlight = Instance.new("Highlight")
                        auraHighlight.Name = "WoddGlow"
                        auraHighlight.Parent = char
                end
                local gc = Color3.new(S.glow_color[1], S.glow_color[2], S.glow_color[3])
                auraHighlight.FillColor           = gc
                auraHighlight.OutlineColor        = gc
                auraHighlight.FillTransparency    = math.clamp(1 - S.glow_fill, 0, 1)
                auraHighlight.OutlineTransparency = math.clamp(S.glow_outline, 0, 1)
                auraHighlight.DepthMode = S.glow_through and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        else
                if auraHighlight then
                        pcall(function()
                                auraHighlight:Destroy()
                        end)
                        auraHighlight = nil
                end
        end

        -- свет глоу в корпусе персонажа
        if S.glow_enabled and S.glow_light > 0.01 and char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                        if not auraGlowLight or auraGlowLight.Parent ~= hrp then
                                if auraGlowLight then
                                        pcall(function()
                                                auraGlowLight:Destroy()
                                        end)
                                end
                                auraGlowLight = Instance.new("PointLight")
                                auraGlowLight.Name      = "WoddGlowLight"
                                auraGlowLight.Shadows   = false
                                auraGlowLight.Range     = 14
                                auraGlowLight.Parent    = hrp
                        end
                        auraGlowLight.Color      = Color3.new(S.glow_color[1], S.glow_color[2], S.glow_color[3])
                        auraGlowLight.Brightness = S.glow_light
                end
        else
                if auraGlowLight then
                        pcall(function()
                                auraGlowLight:Destroy()
                        end)
                        auraGlowLight = nil
                end
        end

        -- крылья / нимб / волны живут в общей папке
        if S.wings_enabled or S.nimbus_enabled or S.waves_enabled then
                ensureAura()
        elseif auraFolder then
                auraTeardown()
                return
        end
        auraVis.wings  = S.wings_enabled and auraFolder ~= nil
        auraVis.nimbus = S.nimbus_enabled and auraFolder ~= nil
        auraVis.waves  = S.waves_enabled and auraFolder ~= nil

        -- СВОЙСТВА КРЫЛЬЕВ
        if auraFolder then
                local wc = Color3.new(S.wings_color[1], S.wings_color[2], S.wings_color[3])
                local ws = S.wings_scale
                for i, wp in ipairs(wingParts) do
                        local len = wingData[i].len * ws
                        wp.feather.Size = Vector3.new(0.22 * ws, len, 0.5 * ws)
                        wp.shell.Size   = wp.feather.Size * 1.5
                        wp.feather.Color = wc
                        wp.shell.Color   = wc
                        wp.feather.Transparency = auraVis.wings and math.clamp(S.wings_opacity, 0, 1) or 1
                        wp.shell.Transparency   = auraVis.wings and math.clamp(S.wings_opacity + 0.45, 0, 1) or 1
                end
                petalEmitter.Enabled = auraVis.wings and S.wings_particles
                petalEmitter.Color   = ColorSequence.new(wc)
                wingAnchor.Size = Vector3.new(4.4 * ws, 1.4 * ws, 1)

                -- СВОЙСТВА НИМБА
                local nc = Color3.new(S.nimbus_color[1], S.nimbus_color[2], S.nimbus_color[3])
                local ns = S.nimbus_scale
                local segLen = (2 * math.pi * 1.05 * ns / NIMBUS_SEGS) * 0.72
                for _, seg in ipairs(nimbusSegs) do
                        seg.part.Size = Vector3.new(0.15 * ns, 0.15 * ns, segLen)
                        seg.shell.Size = seg.part.Size * 1.7
                        seg.part.Color = nc
                        seg.shell.Color = nc
                        seg.part.Transparency = auraVis.nimbus and 0.1 or 1
                        seg.shell.Transparency = auraVis.nimbus and 0.6 or 1
                end
                nimbusLight.Enabled    = auraVis.nimbus and S.nimbus_glow > 0.01
                nimbusLight.Brightness = S.nimbus_glow
                nimbusLight.Color      = nc
                nimbusLight.Range      = 7 * ns
                sparkleEmitter.Enabled = auraVis.nimbus and S.nimbus_particles
                sparkleEmitter.Color   = ColorSequence.new(nc)
                nimbusAnchor.Size = Vector3.new(2 * 1.05 * ns, 0.4, 2 * 1.05 * ns)

                -- СВОЙСТВА ВОЛН
                local wvc = Color3.new(S.waves_color[1], S.waves_color[2], S.waves_color[3])
                local wvs = S.waves_scale
                for _, seg in ipairs(waveSegs) do
                        local r = (0.8 + seg.ring * 0.6) * wvs
                        local segLen = (2 * math.pi * r / WAVE_SEGS) * 0.62
                        seg.part.Size  = Vector3.new(0.16 * wvs, 0.12 * wvs, segLen)
                        seg.shell.Size = seg.part.Size * 1.6
                        seg.part.Color = wvc
                        seg.shell.Color = wvc
                        local baseTr = math.clamp(S.waves_opacity, 0, 1)
                        seg.part.Transparency = auraVis.waves and math.clamp(baseTr + seg.ring * 0.07, 0, 1) or 1
                        seg.shell.Transparency = auraVis.waves and math.clamp(baseTr + 0.4 + seg.ring * 0.07, 0, 1) or 1
                end
        end
end

auraReset = function()
        auraTeardown()
        if S.wings_enabled or S.nimbus_enabled or S.glow_enabled or S.waves_enabled then
                applyAura()
        end
end
auraResetOnSpawn = auraReset

-- кадровое обновление ауры (CFrame перьев/колец, пульс глоу)
perFrameHooks[#perFrameHooks + 1] = function(dt)
        if not (auraVis.wings or auraVis.nimbus or auraVis.waves or (S.glow_pulse and auraHighlight)) then
                return
        end
        auraTime = auraTime + dt
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not auraFolder then
                -- персонажа нет (не заспаунен / умер): частицы не сыплются в нулях мира,
                -- а детали ауры прячем целиком — иначе они висят в воздухе на последних позициях
                if petalEmitter then
                        petalEmitter.Enabled = false
                end
                if sparkleEmitter then
                        sparkleEmitter.Enabled = false
                end
                if auraFolder and auraFolder.Parent then
                        auraFolder.Parent = nil
                end
                return
        end
        if not auraFolder.Parent then
                -- персонаж вернулся: возвращаем папку в мир и восстанавливаем частицы
                auraFolder.Parent = workspace
                if petalEmitter then
                        petalEmitter.Enabled = auraVis.wings and S.wings_particles
                end
                if sparkleEmitter then
                        sparkleEmitter.Enabled = auraVis.nimbus and S.nimbus_particles
                end
        end
        local base = hrp.CFrame

        -- пульсация глоу
        if S.glow_pulse and auraHighlight and auraHighlight.Parent then
                auraHighlight.FillTransparency = math.clamp(1 - S.glow_fill + math.sin(auraTime * 2.6) * 0.13, 0, 1)
        end

        -- КРЫЛЬЯ: веер перьев за спиной + взмах
        if auraVis.wings then
                local anchor = base * CFrame.new(S.wings_ox, S.wings_oy, S.wings_oz)
                wingAnchor.CFrame = anchor
                local spd = math.max(S.wings_flap, 0)
                local flapAmp = 0.12 * math.clamp(S.wings_flap, 0, 2)
                local flap = (spd > 0.001) and (math.sin(auraTime * 2.4 * spd) * flapAmp) or 0
                local s = S.wings_scale
                local backDir = base:VectorToWorldSpace(Vector3.new(0, 0, 1))
                for i, wp in ipairs(wingParts) do
                        local d = wingData[i]
                        local th = d.ang + flap * (0.4 + d.k)
                        local dirWorld = base:VectorToWorldSpace(Vector3.new(d.side * math.sin(th), math.cos(th), 0))
                        local pos = anchor.Position + dirWorld * (d.len * s * 0.5)
                        local xAxis = dirWorld:Cross(backDir)
                        xAxis = (xAxis.Magnitude > 0.01) and xAxis.Unit or Vector3.new(1, 0, 0)
                        local cf = CFrame.fromMatrix(pos, xAxis, dirWorld, backDir)
                        wp.feather.CFrame = cf
                        wp.shell.CFrame = cf
                end
        end

        -- НИМБ: вращающееся кольцо над головой с покачиванием
        if auraVis.nimbus then
                local bob = math.sin(auraTime * 1.7) * 0.07
                local center = base * CFrame.new(S.nimbus_ox, S.nimbus_oy + bob, S.nimbus_oz)
                nimbusAnchor.CFrame = center
                local tilted = base * NIMBUS_TILT
                local r = 1.05 * S.nimbus_scale
                for _, seg in ipairs(nimbusSegs) do
                        local a = seg.a + auraTime * S.nimbus_spin
                        local dirWorld = tilted:VectorToWorldSpace(Vector3.new(math.cos(a), 0, math.sin(a)))
                        local pos = center.Position + dirWorld * r
                        seg.part.CFrame = CFrame.lookAt(pos, pos + dirWorld)
                        seg.shell.CFrame = seg.part.CFrame
                end
        end

        -- ВОЛНЫ: изгибающиеся кольца под персонажем
        if auraVis.waves then
                local center = base * CFrame.new(S.waves_ox, S.waves_oy, S.waves_oz)
                local t = auraTime * math.max(S.waves_speed, 0) * 2.2
                local bend = S.waves_bend
                for _, seg in ipairs(waveSegs) do
                        local k = seg.ring
                        local spin = (k % 2 == 0) and -0.22 or 0.26
                        local a = seg.a + auraTime * spin
                        local wfreq = 1.5 + k * 0.5
                        local wamp = bend * (0.45 + k * 0.28)
                        local ph = a * wfreq - t * (0.8 + k * 0.25)
                        local r = (0.8 + k * 0.6) * S.waves_scale * (1 + 0.05 * math.sin(a * 3 - t))
                        local y = math.sin(ph) * wamp
                        local pos = center.Position + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
                        local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
                        -- наклон сегмента по склону волны — кольца визуально «сгибаются»
                        local slope = math.cos(ph) * wfreq * wamp / math.max(r, 0.1)
                        local tilt = math.atan(math.clamp(slope, -1.3, 1.3))
                        local cf = CFrame.lookAt(pos, pos + tangent) * CFrame.Angles(tilt, 0, 0)
                        seg.part.CFrame = cf
                        seg.shell.CFrame = cf
                end
        end
end

-- ================== ПОЛНЫЙ ВОЗВРАТ МИРА К ИСХОДУ ==================
local function restoreOriginal()
        Lighting.Brightness               = ORIG.Brightness
        Lighting.ClockTime                = ORIG.ClockTime
        Lighting.ExposureCompensation     = ORIG.ExposureCompensation
        Lighting.GlobalShadows            = ORIG.GlobalShadows
        Lighting.ShadowSoftness           = ORIG.ShadowSoftness
        Lighting.EnvironmentDiffuseScale  = ORIG.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = ORIG.EnvironmentSpecularScale
        Lighting.Ambient                  = ORIG.Ambient
        Lighting.OutdoorAmbient           = ORIG.OutdoorAmbient
        Lighting.FogColor                 = ORIG.FogColor
        Lighting.FogStart                 = ORIG.FogStart
        Lighting.FogEnd                   = ORIG.FogEnd
        Terrain.WaterWaveSize     = ORIG.WaterWaveSize
        Terrain.WaterWaveSpeed    = ORIG.WaterWaveSpeed
        Terrain.WaterReflectance  = ORIG.WaterReflectance
        Terrain.WaterTransparency = ORIG.WaterTransparency
        atmosphere.Density = ORIG.AtmoDensity
        atmosphere.Offset  = ORIG.AtmoOffset
        atmosphere.Glare   = ORIG.AtmoGlare
        atmosphere.Haze    = ORIG.AtmoHaze
        atmosphere.Color   = ORIG.AtmoColor
        atmosphere.Decay   = ORIG.AtmoDecay
        sky.StarCount            = ORIG.Stars
        sky.CelestialBodiesShown = ORIG.Bodies
        colorCorrection.Brightness = 0
        colorCorrection.Contrast   = 0
        colorCorrection.Saturation = 0
        colorCorrection.TintColor  = Color3.new(1, 1, 1)
        bloom.Intensity   = 0
        sunRays.Intensity = 0
        blur.Size         = 0
        menuBlur.Size     = 0
        dof.Enabled       = false
        local cam = workspace.CurrentCamera
        if cam then
                cam.FieldOfView = ORIG.FieldOfView
        end
        clearBolt()
        if auraTeardown then
                pcall(auraTeardown)
        end
        pcall(function()
                weatherPart:Destroy()
                snowPart:Destroy()
        end)
        rainSound:Stop()
        windSound:Stop()
        for _, snd in ipairs(thunderPool) do
                snd:Stop()
        end
end

-- ============================== ЛОКАЛИЗАЦИЯ ==============================
local LANG = "ru"

-- ======================= ЗАГРУЖАЕМ СОХРАНЁННЫЙ КОНФИГ =======================
loadSavedConfig()

if S.ui_lang == "en" then
        LANG = "en"
end
local L10N = {
        ru = {
                sub_title      = "ВИЗУАЛЫ",
                tab_world      = "Мир",
                tab_lighting   = "Освещение",
                tab_sky        = "Небо",
                tab_effects    = "Эффекты",
                tab_camera     = "Камера",
                tab_weather    = "Погода",
                btn_reset      = "Сброс",
                key_prefix     = "Клавиша",
                rebinding      = "Нажми клавишу...",
                toast_hint     = "Insert — открыть/закрыть меню",
                picker_title   = "Выбор цвета",
                picker_ok      = "Готово",

                sec_worldcolor = "Цвет мира",
                sec_light      = "Освещение",
                sec_atmo       = "Атмосфера",
                sec_fog        = "Туман",
                sec_water      = "Вода",
                sec_skytop     = "Небо",
                sec_cc         = "Цветокоррекция",
                sec_bloom      = "Свечение (Bloom)",
                sec_sunrays    = "Лучи солнца",
                sec_blur       = "Размытие",
                sec_dof        = "Глубина резкости",
                sec_cam        = "Камера",
                sec_rain       = "Дождь",
                sec_snow       = "Снег",
                sec_general    = "Общее",

                wc_picker      = "World Color",
                wc_strength    = "Сила тинта",
                wc_sync_ambient= "Красить Ambient",
                wc_sync_fog    = "Красить туман",
                wc_sync_atmo   = "Красить атмосферу",
                wc_reset       = "Сбросить цвет",

                light_brightness = "Яркость",
                light_time       = "Время суток",
                light_exposure   = "Экспозиция",
                light_shadows    = "Тени",
                light_softness   = "Мягкость теней",
                light_diffuse    = "Env diffuse",
                light_specular   = "Env specular",

                atmo_density = "Плотность",
                atmo_offset  = "Смещение",
                atmo_glare   = "Блеск",
                atmo_haze    = "Дымка",

                fog_start = "Начало тумана",
                fog_end   = "Конец тумана",

                water_wavesize    = "Размер волн",
                water_wavespeed   = "Скорость волн",
                water_reflect     = "Отражения",
                water_transparent = "Прозрачность воды",

                sky_stars  = "Звёзды",
                sky_bodies = "Солнце и луна",

                cc_brightness = "Яркость",
                cc_contrast   = "Контраст",
                cc_saturation = "Насыщенность",

                bloom_intensity  = "Интенсивность",
                bloom_size       = "Радиус",
                bloom_threshold  = "Порог",
                sunrays_intensity= "Интенсивность",
                sunrays_spread   = "Разлёт",
                blur_size        = "Радиус",

                dof_enable = "Включить",
                dof_far    = "Дальняя резкость",
                dof_focus  = "Дистанция фокуса",
                dof_radius = "Радиус фокуса",

                cam_fov    = "Поле зрения",
                cam_smooth = "Плавный FOV",
                cam_roll   = "Наклон",

                rain_toggle       = "Дождь",
                rain_intensity    = "Интенсивность",
                rain_speed        = "Скорость",
                rain_size         = "Размер капель",
                rain_transparency = "Прозрачность",
                rain_color        = "Цвет",
                rain_sound        = "Звук дождя",
                rain_volume       = "Громкость",

                snow_toggle       = "Снег",
                snow_intensity    = "Интенсивность",
                snow_speed        = "Скорость",
                snow_size         = "Размер хлопьев",
                snow_transparency = "Прозрачность",
                snow_color        = "Цвет",

                wind      = "Ветер",
                lightning = "Молнии",

                tab_settings   = "Настройки",
                sec_interface  = "Интерфейс",
                sec_presets    = "Пресеты",
                ui_scale        = "Масштаб меню",
                ui_transparency = "Прозрачность окна",
                ui_blur         = "Блюр за меню",
                ui_fps          = "Счётчик FPS",
                ui_autosave     = "Автосохранение",
                ui_watermark    = "Ватермарка",
                ui_chartag      = "Тег персонажа",
                sec_theme       = "Тема меню",
                ui_dark         = "Тёмная тема",
                ui_accent       = "Цвет акцента",
                tag_world  = "Мир",
                tag_rain   = "Дождь",
                tag_snow   = "Снег",
                tag_storm  = "Гроза",
                tag_wings  = "Крылья",
                tag_nimbus = "Нимб",
                tag_glow   = "Глоу",
                lang_row        = "Язык / Language",

                sec_thunder     = "Гроза",
                thunder         = "Звук грома",
                thunder_volume  = "Громкость грома",
                bolts           = "Молнии в небе",
                storm_shake     = "Тряска камеры",
                wind_sound      = "Звук ветра",

                hide_char       = "Скрыть персонажа",

                preset_day      = "День",
                preset_sunset   = "Закат",
                preset_night    = "Ночь",
                preset_cinema   = "Кино",
                preset_storm    = "Гроза",
                preset_snow     = "Снегопад",
                preset_clear    = "Ясно",

                tab_aura      = "Аура",
                sec_wings     = "Крылья сакуры",
                sec_nimbus    = "Нимб",
                sec_glow      = "Глоу",
                wings_toggle    = "Крылья",
                wings_color     = "Цвет",
                wings_scale     = "Размер",
                wings_ox        = "Офсет X",
                wings_oy        = "Офсет Y",
                wings_oz        = "Офсет Z",
                wings_opacity   = "Плотность",
                wings_flap      = "Взмах",
                wings_particles = "Лепестки сакуры",
                nimbus_toggle    = "Нимб",
                nimbus_color     = "Цвет",
                nimbus_scale     = "Размер",
                nimbus_ox        = "Офсет X",
                nimbus_oy        = "Высота",
                nimbus_oz        = "Офсет Z",
                nimbus_spin      = "Вращение",
                nimbus_glow      = "Свечение",
                nimbus_particles = "Искры",
                glow_toggle   = "Глоу персонажа",
                glow_color    = "Цвет",
                glow_fill     = "Заливка",
                glow_outline  = "Контур",
                glow_light    = "Свет",
                glow_pulse    = "Пульсация",
                glow_through  = "Сквозь стены",
                sec_waves     = "Волны",
                waves_toggle  = "Волны",
                waves_color   = "Цвет",
                waves_scale   = "Размер",
                waves_speed   = "Скорость",
                waves_bend    = "Изгиб",
                waves_opacity = "Плотность",
                waves_ox      = "Офсет X",
                waves_oy      = "Высота",
                waves_oz      = "Офсет Z",
                tag_waves     = "Волны",
        },
        en = {
                sub_title      = "VISUALS",
                tab_world      = "World",
                tab_lighting   = "Lighting",
                tab_sky        = "Sky",
                tab_effects    = "Effects",
                tab_camera     = "Camera",
                tab_weather    = "Weather",
                btn_reset      = "Reset",
                key_prefix     = "Key",
                rebinding      = "Press a key...",
                toast_hint     = "Insert — open/close menu",
                picker_title   = "Pick a color",
                picker_ok      = "Done",

                sec_worldcolor = "World color",
                sec_light      = "Lighting",
                sec_atmo       = "Atmosphere",
                sec_fog        = "Fog",
                sec_water      = "Water",
                sec_skytop     = "Sky",
                sec_cc         = "Color correction",
                sec_bloom      = "Bloom",
                sec_sunrays    = "Sun rays",
                sec_blur       = "Blur",
                sec_dof        = "Depth of field",
                sec_cam        = "Camera",
                sec_rain       = "Rain",
                sec_snow       = "Snow",
                sec_general    = "General",

                wc_picker       = "World Color",
                wc_strength     = "Tint strength",
                wc_sync_ambient = "Paint Ambient",
                wc_sync_fog     = "Paint fog",
                wc_sync_atmo    = "Paint atmosphere",
                wc_reset        = "Reset color",

                light_brightness = "Brightness",
                light_time       = "Time of day",
                light_exposure   = "Exposure",
                light_shadows    = "Shadows",
                light_softness   = "Soft shadows",
                light_diffuse    = "Env diffuse",
                light_specular   = "Env specular",

                atmo_density = "Density",
                atmo_offset  = "Offset",
                atmo_glare   = "Glare",
                atmo_haze    = "Haze",

                fog_start = "Fog start",
                fog_end   = "Fog end",

                water_wavesize    = "Wave size",
                water_wavespeed   = "Wave speed",
                water_reflect     = "Reflectance",
                water_transparent = "Water transparency",

                sky_stars  = "Stars",
                sky_bodies = "Sun & moon",

                cc_brightness    = "Brightness",
                cc_contrast      = "Contrast",
                cc_saturation    = "Saturation",

                bloom_intensity  = "Intensity",
                bloom_size       = "Radius",
                bloom_threshold  = "Threshold",
                sunrays_intensity= "Intensity",
                sunrays_spread   = "Spread",
                blur_size        = "Radius",

                dof_enable = "Enable",
                dof_far    = "Far intensity",
                dof_focus  = "Focus distance",
                dof_radius = "Focus radius",

                cam_fov    = "Field of view",
                cam_smooth = "Smooth FOV",
                cam_roll   = "Roll",

                rain_toggle       = "Rain",
                rain_intensity    = "Intensity",
                rain_speed        = "Speed",
                rain_size         = "Drop size",
                rain_transparency = "Transparency",
                rain_color        = "Color",
                rain_sound        = "Rain sound",
                rain_volume       = "Volume",

                snow_toggle       = "Snow",
                snow_intensity    = "Intensity",
                snow_speed        = "Speed",
                snow_size         = "Flake size",
                snow_transparency = "Transparency",
                snow_color        = "Color",

                wind      = "Wind",
                lightning = "Lightning",

                tab_settings   = "Settings",
                sec_interface  = "Interface",
                sec_presets    = "Presets",
                ui_scale        = "Menu scale",
                ui_transparency = "Window transparency",
                ui_blur         = "Blur behind menu",
                ui_fps          = "FPS counter",
                ui_autosave     = "Auto-save",
                ui_watermark    = "Watermark",
                ui_chartag      = "Character tag",
                sec_theme       = "Menu theme",
                ui_dark         = "Dark theme",
                ui_accent       = "Accent color",
                tag_world  = "World",
                tag_rain   = "Rain",
                tag_snow   = "Snow",
                tag_storm  = "Storm",
                tag_wings  = "Wings",
                tag_nimbus = "Nimbus",
                tag_glow   = "Glow",
                lang_row        = "Language / Язык",

                sec_thunder     = "Thunderstorm",
                thunder         = "Thunder sound",
                thunder_volume  = "Thunder volume",
                bolts           = "Sky bolts",
                storm_shake     = "Camera shake",
                wind_sound      = "Wind sound",

                hide_char       = "Hide character",

                preset_day      = "Day",
                preset_sunset   = "Sunset",
                preset_night    = "Night",
                preset_cinema   = "Cinematic",
                preset_storm    = "Storm",
                preset_snow     = "Snowfall",
                preset_clear    = "Clear",

                tab_aura      = "Aura",
                sec_wings     = "Sakura wings",
                sec_nimbus    = "Nimbus",
                sec_glow      = "Glow",
                wings_toggle    = "Wings",
                wings_color     = "Color",
                wings_scale     = "Size",
                wings_ox        = "Offset X",
                wings_oy        = "Offset Y",
                wings_oz        = "Offset Z",
                wings_opacity   = "Density",
                wings_flap      = "Flap",
                wings_particles = "Sakura petals",
                nimbus_toggle    = "Nimbus",
                nimbus_color     = "Color",
                nimbus_scale     = "Size",
                nimbus_ox        = "Offset X",
                nimbus_oy        = "Height",
                nimbus_oz        = "Offset Z",
                nimbus_spin      = "Spin",
                nimbus_glow      = "Glow",
                nimbus_particles = "Sparkles",
                glow_toggle   = "Character glow",
                glow_color    = "Color",
                glow_fill     = "Fill",
                glow_outline  = "Outline",
                glow_light    = "Light",
                glow_pulse    = "Pulse",
                glow_through  = "Through walls",
                sec_waves     = "Waves",
                waves_toggle  = "Waves",
                waves_color   = "Color",
                waves_scale   = "Size",
                waves_speed   = "Speed",
                waves_bend    = "Bend",
                waves_opacity = "Density",
                waves_ox      = "Offset X",
                waves_oy      = "Height",
                waves_oz      = "Offset Z",
                tag_waves     = "Waves",
        },
}

local function T(key)
        local dict = L10N[LANG]
        if dict and dict[key] then
                return dict[key]
        end
        return key
end

-- реестры текстов для переключения языка на лету
local textRegistry    = {}
local dynamicRegistry = {}

local function registerText(label, key)
        textRegistry[#textRegistry + 1] = {label = label, key = key}
        label.Text = T(key)
end

local function registerDynamic(fn)
        dynamicRegistry[#dynamicRegistry + 1] = fn
        fn()
end

-- ================================ ТЕМА ================================
-- Две готовые темы (тёмная / светлая) + свой цвет акцента (S.ui_accent).
-- bindTheme регистрирует элемент: при смене темы всё перекрашивается на лету.
local THEMES = {
        dark = {
                windowBg            = Color3.fromRGB(16, 18, 25),
                windowBgTop         = Color3.fromRGB(26, 29, 42),
                windowBgBottom      = Color3.fromRGB(10, 11, 17),
                sidebar             = Color3.fromRGB(255, 255, 255),
                sidebarTransparency = 0.55,
                layer               = Color3.fromRGB(255, 255, 255),
                rowTransparency     = 0.94,
                rowHover            = 0.90,
                text                = Color3.fromRGB(240, 244, 252),
                textDim             = Color3.fromRGB(168, 176, 194),
                textFaint           = Color3.fromRGB(128, 136, 155),
                toggleOff           = Color3.fromRGB(66, 72, 88),
                knob                = Color3.fromRGB(220, 224, 235),
                logoBase            = Color3.fromRGB(255, 255, 255),
        },
        white = {
                windowBg            = Color3.fromRGB(237, 240, 247),
                windowBgTop         = Color3.fromRGB(250, 251, 254),
                windowBgBottom      = Color3.fromRGB(222, 226, 237),
                sidebar             = Color3.fromRGB(255, 255, 255),
                sidebarTransparency = 0.32,
                layer               = Color3.fromRGB(24, 28, 40),
                rowTransparency     = 0.93,
                rowHover            = 0.88,
                text                = Color3.fromRGB(30, 34, 47),
                textDim             = Color3.fromRGB(88, 96, 114),
                textFaint           = Color3.fromRGB(130, 138, 154),
                toggleOff           = Color3.fromRGB(178, 185, 199),
                knob                = Color3.fromRGB(255, 255, 255),
                logoBase            = Color3.fromRGB(24, 28, 40),
        },
}

local THEME = {
        windowTransparency = 0.22, -- не зависит от темы
}

local themeBinds, themeFns = {}, {}

-- привязка свойства элемента к ключу темы
local function bindTheme(obj, prop, key)
        themeBinds[#themeBinds + 1] = {obj = obj, prop = prop, key = key}
        obj[prop] = THEME[key]
end

-- произвольная перекраска (градиенты и т.п.)
local function bindThemeFn(fn)
        themeFns[#themeFns + 1] = fn
        fn()
end

-- акцент берётся из S.ui_accent, второй — производный, текст на акценте — авто-контраст
local function computeAccentColors()
        local c = S.ui_accent
        local accent = Color3.new(c[1] or 125 / 255, c[2] or 170 / 255, c[3] or 1)
        local h, s, v = accent:ToHSV()
        local accent2 = Color3.fromHSV(
                (h + 0.09) % 1,
                math.clamp(s * 0.82, 0, 1),
                math.clamp(v * 0.92 + 0.08, 0, 1)
        )
        local lum = 0.299 * accent.R + 0.587 * accent.G + 0.114 * accent.B
        local onAccent = (lum > 0.6) and Color3.fromRGB(24, 28, 40) or Color3.new(1, 1, 1)
        return accent, accent2, onAccent
end

-- применяет тему: перекрашивает всё зарегистрированное через bindTheme/bindThemeFn
local function applyMenuTheme()
        local preset = (S.ui_dark == false) and THEMES.white or THEMES.dark
        for k, v in pairs(preset) do
                THEME[k] = v
        end
        THEME.accent, THEME.accent2, THEME.onAccent = computeAccentColors()
        for _, b in ipairs(themeBinds) do
                pcall(function()
                        b.obj[b.prop] = THEME[b.key]
                end)
        end
        for _, fn in ipairs(themeFns) do
                pcall(fn)
        end
end
applyMenuTheme()

-- ======================= ХЕЛПЕРЫ СОЗДАНИЯ ИНСТАНСОВ =======================
local function create(className, props)
        local inst = Instance.new(className)
        local parent = nil
        for k, v in pairs(props or {}) do
                if k == "Parent" then
                        parent = v
                else
                        inst[k] = v
                end
        end
        if parent then
                inst.Parent = parent
        end
        return inst
end

local function round(inst, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius)
        c.Parent = inst
        return c
end

local function stroke(inst, color, transparency, thickness)
        local s = Instance.new("UIStroke")
        s.Color        = color or Color3.fromRGB(255, 255, 255)
        s.Transparency = transparency or 0.85
        s.Thickness    = thickness or 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = inst
        return s
end

local function hoverify(btn, baseTransparency, hoverTransparency)
        btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = hoverTransparency}):Play()
        end)
        btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = baseTransparency}):Play()
        end)
end

-- ============================== ЭКРАН / ОКНО ==============================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "WoddVisuals"
ScreenGui.ResetOnSpawn    = false
ScreenGui.IgnoreGuiInset  = true
ScreenGui.DisplayOrder    = 9999
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = getGuiParent()

local WINDOW_W, WINDOW_H = 660, 460

-- мягкая тень под окном (классический shadow-спрайт, sibling ниже окна)
local shadow = create("ImageLabel", {
        Name                   = "WindowShadow",
        Size                   = UDim2.new(1, 140, 1, 140),
        Position               = UDim2.new(0.5, 0, 0.5, 10),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://6014261993",
        ImageColor3            = Color3.new(0, 0, 0),
        ImageTransparency      = 0.6,
        ScaleType              = Enum.ScaleType.Slice,
        SliceCenter            = Rect.new(49, 49, 450, 450),
        ZIndex                 = 0,
        Parent                 = ScreenGui,
})

local window = create("Frame", {
        Name                   = "MainWindow",
        Size                   = UDim2.new(0, WINDOW_W, 0, WINDOW_H),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = Color3.new(1, 1, 1), -- тон задаёт градиент ниже
        BackgroundTransparency = THEME.windowTransparency,
        BorderSizePixel        = 0,
        Parent                 = ScreenGui,
})
round(window, 16)
stroke(window, Color3.fromRGB(255, 255, 255), 0.82, 1)

-- вертикальный градиент фона окна (стекло)
local windowGrad = Instance.new("UIGradient")
windowGrad.Rotation = 90
windowGrad.Parent = window
bindThemeFn(function()
        windowGrad.Color = ColorSequence.new(THEME.windowBgTop, THEME.windowBgBottom)
end)

-- акцентная обводка снаружи (мягкое свечение рамки)
local windowGlow = Instance.new("UIStroke")
windowGlow.Transparency = 0.88
windowGlow.Thickness = 1.6
windowGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
windowGlow.Parent = window
bindTheme(windowGlow, "Color", "accent")

local uiScale = Instance.new("UIScale")
uiScale.Parent = window

-- верхняя панель (тоже перетаскивание)
local titleBar = create("Frame", {
        Name                   = "TitleBar",
        Size                   = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent                 = window,
})

local titleLabel = create("TextLabel", {
        Name                   = "Title",
        Text                   = "WODD",
        Font                   = Enum.Font.GothamBlack,
        TextSize               = 17,
        TextColor3             = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 16, 0, 7),
        Size                   = UDim2.new(0, 120, 0, 18),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = titleBar,
})
do -- градиент по буквам заголовка (перекрашивается темой)
        local tg = Instance.new("UIGradient")
        tg.Parent = titleLabel
        bindThemeFn(function()
                tg.Color = ColorSequence.new(THEME.logoBase, THEME.accent)
        end)
end

local versionBadge = create("TextLabel", { -- бейдж версии
        Name                   = "VersionBadge",
        Text                   = "v4",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 9,
        TextColor3             = THEME.textFaint,
        BackgroundColor3       = THEME.layer,
        BackgroundTransparency = 0.9,
        Position               = UDim2.new(0, 63, 0, 10),
        Size                   = UDim2.new(0, 20, 0, 12),
        BorderSizePixel        = 0,
        Parent                 = titleBar,
})
round(versionBadge, 4)
bindTheme(versionBadge, "TextColor3", "textFaint")
bindTheme(versionBadge, "BackgroundColor3", "layer")

local subTitle = create("TextLabel", {
        Name                   = "SubTitle",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 9,
        TextColor3             = THEME.accent,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 16, 0, 26),
        Size                   = UDim2.new(0, 120, 0, 10),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = titleBar,
})
registerText(subTitle, "sub_title")
bindTheme(subTitle, "TextColor3", "accent")

do -- акцентная градиентная линия под топбаром
        local divider = create("Frame", {
                Name                   = "Divider",
                Size                   = UDim2.new(1, -24, 0, 2),
                Position               = UDim2.new(0, 12, 0, 44),
                BackgroundColor3       = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.25,
                BorderSizePixel        = 0,
                Parent                 = window,
        })
        round(divider, 1)
        local dg = Instance.new("UIGradient")
        dg.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, THEME.accent),
                ColorSequenceKeypoint.new(0.55, THEME.accent2),
                ColorSequenceKeypoint.new(1, THEME.accent),
        })
        dg.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.15),
                NumberSequenceKeypoint.new(0.5, 0.55),
                NumberSequenceKeypoint.new(1, 0.15),
        })
        dg.Parent = divider
        bindThemeFn(function()
                dg.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, THEME.accent),
                        ColorSequenceKeypoint.new(0.55, THEME.accent2),
                        ColorSequenceKeypoint.new(1, THEME.accent),
                })
        end)
end

-- кнопки в топбаре
local function topButton(width, textSize)
        local btn = create("TextButton", {
                Size                   = UDim2.new(0, width, 0, 26),
                AnchorPoint            = Vector2.new(0, 0.5), -- центр по вертикали тайтбара
                BackgroundColor3       = THEME.layer,
                BackgroundTransparency = 0.92,
                BorderSizePixel        = 0,
                AutoButtonColor        = false,
                Font                   = Enum.Font.GothamMedium,
                TextSize               = textSize or 12,
                TextColor3             = THEME.textDim,
                Text                   = "",
                Parent                 = titleBar,
        })
        round(btn, 8)
        hoverify(btn, 0.92, 0.86)
        bindTheme(btn, "BackgroundColor3", "layer")
        bindTheme(btn, "TextColor3", "textDim")
        return btn
end

local langButton = topButton(42)
langButton.Position = UDim2.new(1, -266, 0.5, 0)
bindTheme(langButton, "TextColor3", "accent")
langButton.Text = "RU"

local keyButton = topButton(104)
keyButton.Position = UDim2.new(1, -218, 0.5, 0)

local resetButton = topButton(66, 11)
resetButton.Position = UDim2.new(1, -108, 0.5, 0)
registerText(resetButton, "btn_reset")

local closeButton = topButton(30, 15)
closeButton.Position = UDim2.new(1, -36, 0.5, 0)
closeButton.Text = "×"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.MouseEnter:Connect(function()
        closeButton.TextColor3 = Color3.fromRGB(255, 118, 118)
end)
closeButton.MouseLeave:Connect(function()
        closeButton.TextColor3 = THEME.textDim
end)

-- ============================== ПЕРЕТАСКИВАНИЕ ==============================
do
        local dragging = false
        local dragStart, startPos
        titleBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging  = true
                        dragStart = input.Position
                        startPos  = window.Position
                end
        end)
        UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local delta = input.Position - dragStart
                        -- окно нельзя утащить за пределы экрана (хотя бы 90px видимых)
                        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
                        local minX = 90 - WINDOW_W / 2 - vp.X / 2
                        local maxX = vp.X / 2 + WINDOW_W / 2 - 90
                        local minY = 90 - WINDOW_H / 2 - vp.Y / 2
                        local maxY = vp.Y / 2 + WINDOW_H / 2 - 90
                        local ox = math.clamp(startPos.X.Offset + delta.X, minX, maxX)
                        local oy = math.clamp(startPos.Y.Offset + delta.Y, minY, maxY)
                        window.Position = UDim2.new(startPos.X.Scale, ox, startPos.Y.Scale, oy)
                        if shadow then
                                shadow.Position = UDim2.new(startPos.X.Scale, ox, startPos.Y.Scale, oy + 10)
                        end
                end
        end)
        UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                end
        end)
end

-- ============================== САЙДБАР / ТАБЫ ==============================
local sidebar = create("Frame", {
        Name                   = "Sidebar",
        Size                   = UDim2.new(0, 148, 1, -46),
        Position               = UDim2.new(0, 0, 0, 46),
        BackgroundColor3       = THEME.sidebar,
        BackgroundTransparency = THEME.sidebarTransparency,
        BorderSizePixel        = 0,
        Parent                 = window,
})
bindTheme(sidebar, "BackgroundColor3", "sidebar")
bindTheme(sidebar, "BackgroundTransparency", "sidebarTransparency")

local sidebarList = Instance.new("UIListLayout")
sidebarList.Padding = UDim.new(0, 4)
sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
sidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarList.Parent = sidebar

local sidebarPad = Instance.new("UIPadding")
sidebarPad.PaddingTop = UDim.new(0, 8)
sidebarPad.Parent = sidebar

local contentArea = create("Frame", {
        Name                   = "Content",
        Size                   = UDim2.new(1, -148, 1, -58),
        Position               = UDim2.new(0, 148, 0, 46),
        BackgroundTransparency = 1,
        ClipsDescendants       = true,
        Parent                 = window,
})

local tabs = {}
local tabOrder = {"world", "lighting", "sky", "effects", "camera", "aura", "weather", "settings"}
local tabLabelKeys = {
        world    = "tab_world",
        lighting = "tab_lighting",
        sky      = "tab_sky",
        effects  = "tab_effects",
        camera   = "tab_camera",
        aura     = "tab_aura",
        weather  = "tab_weather",

        settings = "tab_settings",
}
local layoutOrderCounter = 0
local function nextOrder()
        layoutOrderCounter = layoutOrderCounter + 1
        return layoutOrderCounter
end

local currentTab = nil

local function selectTab(name)
        currentTab = name
        for tabName, tab in pairs(tabs) do
                local active = (tabName == name)
                tab.active = active
                tab.scroll.Visible = active
                TweenService:Create(tab.indicator, TweenInfo.new(0.15), {BackgroundTransparency = active and 0 or 1}):Play()
                tab.label.TextColor3 = active and THEME.onAccent or THEME.textDim
                tab.label.Font = active and Enum.Font.GothamBold or Enum.Font.GothamMedium
                TweenService:Create(tab.button, TweenInfo.new(0.15), {BackgroundTransparency = active and 0.85 or 1}):Play()
                TweenService:Create(tab.stroke, TweenInfo.new(0.15), {Transparency = active and 0.45 or 1}):Play()
        end
end

local function makeTab(name)
        local btn = create("TextButton", {
                Size                   = UDim2.new(1, -16, 0, 32),
                BackgroundColor3       = THEME.accent,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                AutoButtonColor        = false,
                Text                   = "",
                Parent                 = sidebar,
        })
        round(btn, 9)
        local btnStroke = stroke(btn, THEME.accent, 1, 1)
        bindTheme(btn, "BackgroundColor3", "accent")
        bindTheme(btnStroke, "Color", "accent")

        local indicator = create("Frame", {
                Size                   = UDim2.new(0, 3, 0, 14),
                Position               = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint            = Vector2.new(0, 0.5),
                BackgroundColor3       = THEME.accent,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Parent                 = btn,
        })
        round(indicator, 2)
        bindTheme(indicator, "BackgroundColor3", "accent")

        local label = create("TextLabel", {
                Size                   = UDim2.new(1, -18, 1, 0),
                Position               = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamMedium,
                TextSize               = 13,
                TextColor3             = THEME.textDim,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                Parent                 = btn,
        })
        registerText(label, tabLabelKeys[name])

        -- свой hover: не трогаем активную таблетку
        btn.MouseEnter:Connect(function()
                if not (tabs[name] and tabs[name].active) then
                        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0.93}):Play()
                end
        end)
        btn.MouseLeave:Connect(function()
                if not (tabs[name] and tabs[name].active) then
                        TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
                end
        end)

        btn.Activated:Connect(function()
                selectTab(name)
        end)

        local scroll = create("ScrollingFrame", {
                Name                   = "Scroll_" .. name,
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Visible                = false,
                ScrollBarThickness     = 4,
                ScrollBarImageTransparency = 0.5,
                CanvasSize             = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize    = Enum.AutomaticSize.Y,
                Parent                 = contentArea,
        })

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 6)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = scroll

        local pad = Instance.new("UIPadding")
        pad.PaddingTop    = UDim.new(0, 4)
        pad.PaddingBottom = UDim.new(0, 12)
        pad.PaddingLeft   = UDim.new(0, 6)
        pad.PaddingRight  = UDim.new(0, 10)
        pad.Parent = scroll

        tabs[name] = {button = btn, label = label, indicator = indicator, scroll = scroll, stroke = btnStroke, active = false}
        return scroll
end

-- создаём все табы
for _, name in ipairs(tabOrder) do
        makeTab(name)
end

-- ==================== ПОКАЗ / СКРЫТИЕ ОКНА (Insert) ====================
local pickerPopup = nil -- (создаётся ниже в компонентах)

local function updateMenuBlur()
        if menuBlur then
                menuBlur.Size = (window.Visible and S.ui_blur) and 12 or 0
        end
end

local function setWindowVisible(state)
        if pickerPopup then
                pickerPopup.Visible = false
        end
        window.Visible = state
        shadow.Visible = state -- затемнение/тень убирается вместе с меню
        updateMenuBlur()
        if state then
                uiScale.Scale = S.ui_scale * 0.96
                TweenService:Create(uiScale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = S.ui_scale}):Play()
        end
end

local function toggleWindow()
        setWindowVisible(not window.Visible)
end

closeButton.Activated:Connect(function()
        setWindowVisible(false)
end)

registerDynamic(function()
        langButton.Text = string.upper(LANG)
end)

-- ============================ ЯЗЫК ============================
local function applyLanguageTexts()
        for _, item in ipairs(textRegistry) do
                item.label.Text = T(item.key)
        end
        for _, fn in ipairs(dynamicRegistry) do
                fn()
        end
end

local function toggleLanguage()
        if LANG == "ru" then
                LANG = "en"
        else
                LANG = "ru"
        end
        S.ui_lang = LANG
        applyLanguageTexts()
        scheduleSave()
end

langButton.Activated:Connect(toggleLanguage)

-- ======================= FPS-СЧЁТЧИК (Настройки) =======================
local fpsAcc, fpsFrames = 0, 0
local fpsLabel = create("TextLabel", {
        Size                   = UDim2.new(0, 46, 0, 16),
        Position               = UDim2.new(1, -318, 0.5, 0),
        AnchorPoint            = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 10,
        TextColor3             = THEME.textFaint,
        TextXAlignment         = Enum.TextXAlignment.Right,
        Text                   = "",
        Parent                 = titleBar,
})
bindTheme(fpsLabel, "TextColor3", "textFaint")

perFrameHooks[#perFrameHooks + 1] = function(dt)
        if not S.ui_fps then
                if fpsLabel.Text ~= "" then
                        fpsLabel.Text = ""
                end
                return
        end
        fpsAcc = fpsAcc + dt
        fpsFrames = fpsFrames + 1
        if fpsAcc >= 0.5 then
                fpsLabel.Text = tostring(math.floor(fpsFrames / fpsAcc + 0.5)) .. " fps"
                fpsAcc = 0
                fpsFrames = 0
        end
end

-- ======================= РЕЕСТР ОБНОВЛЕНИЙ КОНТРОЛОВ =======================
local refreshers = {}
local function registerRefresher(fn)
        refreshers[#refreshers + 1] = fn
        return fn
end
local function refreshAll()
        for _, fn in ipairs(refreshers) do
                fn()
        end
end

-- ============================ ФОРМАТЫ ЗНАЧЕНИЙ ============================
local function fmtInt(v)
        return string.format("%d", v)
end
local function fmt1(v)
        return string.format("%.1f", v)
end
local function fmt2(v)
        return string.format("%.2f", v)
end
local function fmtPct(v)
        return string.format("%d%%", math.floor(v * 100 + 0.5))
end
local function fmtPct100(v)
        return string.format("%d%%", v)
end
local function fmtTime(v)
        local h = math.floor(v)
        local m = math.floor((v - h) * 60 + 0.5)
        if m >= 60 then
                h = (h + 1) % 24
                m = 0
        end
        return string.format("%02d:%02d", h, m)
end

-- ============================== БАЗОВЫЕ РЯДЫ ==============================
local function makeRow(parent, height)
        local row = create("TextButton", {
                Size                   = UDim2.new(1, 0, 0, height or 36),
                BackgroundColor3       = THEME.layer,
                BackgroundTransparency = THEME.rowTransparency,
                BorderSizePixel        = 0,
                AutoButtonColor        = false,
                Text                   = "",
                LayoutOrder            = nextOrder(),
                Parent                 = parent,
        })
        round(row, 8)
        hoverify(row, THEME.rowTransparency, THEME.rowHover)
        bindTheme(row, "BackgroundColor3", "layer")
        return row
end

local function makeSection(parent, titleKey)
        local holder = create("Frame", {
                Size                   = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                LayoutOrder            = nextOrder(),
                Parent                 = parent,
        })
        -- акцентная засечка перед заголовком секции
        local dash = create("Frame", {
                Size                   = UDim2.new(0, 3, 0, 12),
                Position               = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint            = Vector2.new(0, 0.5),
                BackgroundColor3       = THEME.accent,
                BackgroundTransparency = 0.35,
                BorderSizePixel        = 0,
                Parent                 = holder,
        })
        round(dash, 2)
        bindTheme(dash, "BackgroundColor3", "accent")
        local label = create("TextLabel", {
                Size                   = UDim2.new(1, -10, 1, 0),
                Position               = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamBold,
                TextSize               = 11,
                TextColor3             = THEME.textFaint,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = holder,
        })
        bindTheme(label, "TextColor3", "textFaint")
        -- секции обновляются через dynamicRegistry, чтобы ВЕРХНИЙ РЕГИСТР сохранялся при смене языка
        dynamicRegistry[#dynamicRegistry + 1] = function()
                label.Text = string.upper(T(titleKey))
        end
        label.Text = string.upper(T(titleKey))
        return holder
end

-- ================================ TOGGLE ================================
local function makeToggle(parent, labelKey, key, onChanged)
        local row = makeRow(parent, 36)

        local label = create("TextLabel", {
                Size                   = UDim2.new(1, -60, 1, 0),
                Position               = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamMedium,
                TextSize               = 13,
                TextColor3             = THEME.text,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                Parent                 = row,
        })
        registerText(label, labelKey)
        bindTheme(label, "TextColor3", "text")

        local track = create("Frame", {
                Size                   = UDim2.new(0, 38, 0, 21),
                Position               = UDim2.new(1, -12, 0.5, 0),
                AnchorPoint            = Vector2.new(1, 0.5),
                BackgroundColor3       = THEME.toggleOff,
                BackgroundTransparency = 0.35,
                BorderSizePixel        = 0,
                Parent                 = row,
        })
        round(track, 11)

        local knob = create("Frame", {
                Size                   = UDim2.new(0, 15, 0, 15),
                Position               = UDim2.new(0.5, -9, 0.5, 0),
                AnchorPoint            = Vector2.new(0.5, 0.5),
                BackgroundColor3       = Color3.fromRGB(220, 224, 235),
                BorderSizePixel        = 0,
                Parent                 = track,
        })
        round(knob, 8)
        bindTheme(knob, "BackgroundColor3", "knob")

        local function refresh()
                local on = S[key] and true or false
                track.BackgroundColor3       = on and THEME.accent or THEME.toggleOff
                track.BackgroundTransparency = on and 0.1 or 0.35
                local knobTween = TweenService:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = on and UDim2.new(0.5, 9, 0.5, 0) or UDim2.new(0.5, -9, 0.5, 0),
                })
                knobTween:Play()
        end

        row.Activated:Connect(function()
                S[key] = not S[key]
                refresh()
                if onChanged then
                        onChanged(S[key])
                end
                scheduleSave()
        end)

        registerRefresher(refresh)
        refresh()
end

-- ================================ SLIDER ================================
local function makeSlider(parent, labelKey, key, minV, maxV, step, formatFn, onChanged)
        local row = makeRow(parent, 50)

        local label = create("TextLabel", {
                Size                   = UDim2.new(1, -70, 0, 16),
                Position               = UDim2.new(0, 10, 0, 6),
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamMedium,
                TextSize               = 13,
                TextColor3             = THEME.text,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                Parent                 = row,
        })
        registerText(label, labelKey)
        bindTheme(label, "TextColor3", "text")

        local valueLabel = create("TextLabel", {
                Size                   = UDim2.new(0, 62, 0, 16),
                Position               = UDim2.new(1, -10, 0, 6),
                AnchorPoint            = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamBold,
                TextSize               = 12,
                TextColor3             = THEME.accent,
                TextXAlignment         = Enum.TextXAlignment.Right,
                Parent                 = row,
        })

        bindTheme(valueLabel, "TextColor3", "accent")

        local hit = create("TextButton", {
                Size                   = UDim2.new(1, -20, 0, 18),
                Position               = UDim2.new(0, 10, 0, 27),
                BackgroundTransparency = 1,
                AutoButtonColor        = false,
                Text                   = "",
                Parent                 = row,
        })

        local bar = create("Frame", {
                Size                   = UDim2.new(1, 0, 0, 6),
                Position               = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint            = Vector2.new(0, 0.5),
                BackgroundColor3       = THEME.layer,
                BackgroundTransparency = 0.82,
                BorderSizePixel        = 0,
                Parent                 = hit,
        })
        round(bar, 3)
        bindTheme(bar, "BackgroundColor3", "layer")

        local fill = create("Frame", {
                Size                   = UDim2.new(0, 0, 1, 0),
                BackgroundColor3       = THEME.accent,
                BackgroundTransparency = 0.1,
                BorderSizePixel        = 0,
                Parent                 = bar,
        })
        round(fill, 3)
        bindTheme(fill, "BackgroundColor3", "accent")
        do -- градиент по заливке слайдера (перекрашивается темой)
                local fg = Instance.new("UIGradient")
                fg.Parent = fill
                bindThemeFn(function()
                        fg.Color = ColorSequence.new(THEME.accent, THEME.accent2)
                end)
        end

        local knob = create("Frame", {
                Size                   = UDim2.new(0, 12, 0, 12),
                Position               = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint            = Vector2.new(0.5, 0.5),
                BackgroundColor3       = Color3.fromRGB(255, 255, 255),
                BorderSizePixel        = 0,
                Parent                 = bar,
        })
        round(knob, 6)
        stroke(knob, Color3.fromRGB(0, 0, 0), 0.6, 1)

        local function alphaFromValue(v)
                return (v - minV) / (maxV - minV)
        end

        local function valueFromAlpha(a)
                local v = minV + (maxV - minV) * a
                if step and step > 0 then
                        v = math.floor(v / step + 0.5) * step
                end
                if v < minV then v = minV end
                if v > maxV then v = maxV end
                return v
        end

        local function setValue(v, skipSave)
                S[key] = v
                local a = alphaFromValue(v)
                if a < 0 then a = 0 end
                if a > 1 then a = 1 end
                fill.Size = UDim2.new(a, 0, 1, 0)
                knob.Position = UDim2.new(a, 0, 0.5, 0)
                valueLabel.Text = formatFn(v)
                if onChanged then
                        onChanged(v)
                end
                if not skipSave then
                        scheduleSave()
                end
        end

        local function refresh()
                setValue(S[key], true)
        end

        local dragging = false
        hit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        local a = (input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
                        setValue(valueFromAlpha(math.clamp(a, 0, 1)))
                end
        end)
        UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local a = (input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
                        setValue(valueFromAlpha(math.clamp(a, 0, 1)))
                end
        end)
        UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                end
        end)

        registerRefresher(refresh)
        refresh()
end

-- ================================ BUTTON ================================
local function makeButton(parent, labelKey, callback)
        local row = makeRow(parent, 32)
        row.Font = Enum.Font.GothamMedium
        row.TextSize = 12
        row.TextColor3 = THEME.text
        bindTheme(row, "TextColor3", "text")
        registerText(row, labelKey)
        row.MouseEnter:Connect(function()
                row.TextColor3 = THEME.accent
        end)
        row.MouseLeave:Connect(function()
                row.TextColor3 = THEME.text
        end)
        row.Activated:Connect(function()
                callback()
        end)
        return row
end

-- ============================ COLOR PICKER ============================
-- один глобальный попап; открывается у нажатой кнопки
local pH, pS, pV = 0, 0, 1
local pickerKey, pickerSwatch, pickerCallback = nil, nil, nil

local popupW, popupH = 212, 246
pickerPopup = create("Frame", {
        Name                   = "WoddColorPicker",
        Size                   = UDim2.new(0, popupW, 0, popupH),
        Visible                = false,
        ZIndex                 = 50,
        BackgroundColor3       = THEME.windowBg,
        BackgroundTransparency = 0.08,
        BorderSizePixel        = 0,
        Parent                 = ScreenGui,
})
round(pickerPopup, 12)
stroke(pickerPopup, Color3.fromRGB(255, 255, 255), 0.75, 1)
bindTheme(pickerPopup, "BackgroundColor3", "windowBg")

local pickerTitle = create("TextLabel", {
        Size                   = UDim2.new(1, -20, 0, 16),
        Position               = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 12,
        TextColor3             = THEME.text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 51,
        Parent                 = pickerPopup,
})
bindTheme(pickerTitle, "TextColor3", "text")
dynamicRegistry[#dynamicRegistry + 1] = function()
        pickerTitle.Text = string.upper(T("picker_title"))
end
pickerTitle.Text = string.upper(T("picker_title"))

-- превью цвета
local previewFrame = create("Frame", {
        Size                   = UDim2.new(0, 46, 0, 16),
        Position               = UDim2.new(1, -12, 0, 8),
        AnchorPoint            = Vector2.new(1, 0),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BorderSizePixel        = 0,
        ZIndex                 = 51,
        Parent                 = pickerPopup,
})
round(previewFrame, 6)
stroke(previewFrame, Color3.fromRGB(255, 255, 255), 0.6, 1)

-- HSV-квадрат (S по X, V по Y)
local svBase = create("TextButton", {
        Size                   = UDim2.new(1, -24, 0, 118),
        Position               = UDim2.new(0, 12, 0, 32),
        BackgroundColor3       = Color3.fromHSV(0, 1, 1),
        BorderSizePixel        = 0,
        AutoButtonColor        = false,
        Text                   = "",
        ZIndex                 = 51,
        Parent                 = pickerPopup,
})
round(svBase, 8)

local svWhite = create("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0,
        BorderSizePixel        = 0,
        ZIndex                 = 52,
        Parent                 = svBase,
})
round(svWhite, 8)
local gradWhite = Instance.new("UIGradient")
gradWhite.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
gradWhite.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
})
gradWhite.Rotation = 0
gradWhite.Parent = svWhite

local svBlack = create("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundColor3       = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0,
        BorderSizePixel        = 0,
        ZIndex                 = 53,
        Parent                 = svBase,
})
round(svBlack, 8)
local gradBlack = Instance.new("UIGradient")
gradBlack.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0))
gradBlack.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
})
gradBlack.Rotation = 90
gradBlack.Parent = svBlack

local svCursor = create("Frame", {
        Size                   = UDim2.new(0, 10, 0, 10),
        Position               = UDim2.new(0, 0, 0, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        BorderSizePixel        = 0,
        ZIndex                 = 54,
        Parent                 = svBase,
})
round(svCursor, 5)
stroke(svCursor, Color3.fromRGB(0, 0, 0), 0.4, 1)

-- hue-полоса
local hueBar = create("TextButton", {
        Size                   = UDim2.new(1, -24, 0, 12),
        Position               = UDim2.new(0, 12, 0, 158),
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        BorderSizePixel        = 0,
        AutoButtonColor        = false,
        Text                   = "",
        ZIndex                 = 51,
        Parent                 = pickerPopup,
})
round(hueBar, 6)
local gradHue = Instance.new("UIGradient")
gradHue.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
})
gradHue.Parent = hueBar

local hueCursor = create("Frame", {
        Size                   = UDim2.new(0, 4, 1, 4),
        Position               = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        BorderSizePixel        = 0,
        ZIndex                 = 54,
        Parent                 = hueBar,
})
round(hueCursor, 2)
stroke(hueCursor, Color3.fromRGB(0, 0, 0), 0.4, 1)

-- hex-поле
local hexBox = create("TextBox", {
        Size                   = UDim2.new(0, 96, 0, 20),
        Position               = UDim2.new(0, 12, 0, 180),
        BackgroundColor3       = THEME.layer,
        BackgroundTransparency = 0.88,
        BorderSizePixel        = 0,
        Font                   = Enum.Font.Code,
        TextSize               = 12,
        TextColor3             = THEME.text,
        Text                   = "#FFFFFF",
        ClearTextOnFocus       = false,
        ZIndex                 = 51,
        Parent                 = pickerPopup,
})
round(hexBox, 6)
bindTheme(hexBox, "BackgroundColor3", "layer")
bindTheme(hexBox, "TextColor3", "text")

-- кнопка Готово
local okButton = create("TextButton", {
        Size                   = UDim2.new(0, 86, 0, 20),
        Position               = UDim2.new(1, -12, 0, 180),
        AnchorPoint            = Vector2.new(1, 0),
        BackgroundColor3       = THEME.accent,
        BackgroundTransparency = 0.15,
        BorderSizePixel        = 0,
        AutoButtonColor        = false,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 11,
        TextColor3             = THEME.onAccent,
        ZIndex                 = 51,
        Parent                 = pickerPopup,
})
round(okButton, 6)
registerText(okButton, "picker_ok")
bindTheme(okButton, "BackgroundColor3", "accent")
bindTheme(okButton, "TextColor3", "onAccent")

local function currentColor()
        return Color3.fromHSV(pH, pS, pV)
end

local function refreshPickerVisuals()
        local color = currentColor()
        svBase.BackgroundColor3 = Color3.fromHSV(pH, 1, 1)
        svCursor.Position = UDim2.new(pS, 0, 1 - pV, 0)
        hueCursor.Position = UDim2.new(pH, 0, 0.5, 0)
        previewFrame.BackgroundColor3 = color
        hexBox.Text = string.format("#%02X%02X%02X",
                math.floor(color.R * 255 + 0.5),
                math.floor(color.G * 255 + 0.5),
                math.floor(color.B * 255 + 0.5))
        if pickerSwatch then
                pickerSwatch.BackgroundColor3 = color
        end
        if pickerCallback then
                pickerCallback(color)
        end
end

local function setPickerColor(color)
        local h, s, v = color:ToHSV()
        pH, pS, pV = h, s, v
        refreshPickerVisuals()
end

-- перетаскивание по квадратно/полосе
local draggingSV, draggingHue = false, false

svBase.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSV = true
                local aX = (input.Position.X - svBase.AbsolutePosition.X) / math.max(svBase.AbsoluteSize.X, 1)
                local aY = (input.Position.Y - svBase.AbsolutePosition.Y) / math.max(svBase.AbsoluteSize.Y, 1)
                pS = math.clamp(aX, 0, 1)
                pV = 1 - math.clamp(aY, 0, 1)
                refreshPickerVisuals()
        end
end)
hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingHue = true
                local a = (input.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1)
                pH = math.clamp(a, 0, 1)
                refreshPickerVisuals()
        end
end)
UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                if draggingSV then
                        local aX = (input.Position.X - svBase.AbsolutePosition.X) / math.max(svBase.AbsoluteSize.X, 1)
                        local aY = (input.Position.Y - svBase.AbsolutePosition.Y) / math.max(svBase.AbsoluteSize.Y, 1)
                        pS = math.clamp(aX, 0, 1)
                        pV = 1 - math.clamp(aY, 0, 1)
                        refreshPickerVisuals()
                elseif draggingHue then
                        local a = (input.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1)
                        pH = math.clamp(a, 0, 1)
                        refreshPickerVisuals()
                end
        end
end)
UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSV = false
                draggingHue = false
        end
end)

hexBox.FocusLost:Connect(function(enterPressed)
        if not enterPressed then
                return
        end
        local txt = string.gsub(string.gsub(hexBox.Text, "#", ""), "%s", "")
        if string.len(txt) == 6 then
                local num = tonumber(txt, 16)
                if num then
                        local r = math.floor(num / 65536) % 256
                        local g = math.floor(num / 256) % 256
                        local b = num % 256
                        setPickerColor(Color3.fromRGB(r, g, b))
                        return
                end
        end
        refreshPickerVisuals()
end)

okButton.Activated:Connect(function()
        pickerPopup.Visible = false
end)

-- клик мимо попапа закрывает его
UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 and pickerPopup.Visible then
                local m = UserInputService:GetMouseLocation()
                local p, s = pickerPopup.AbsolutePosition, pickerPopup.AbsoluteSize
                if m.X < p.X or m.X > p.X + s.X or m.Y < p.Y or m.Y > p.Y + s.Y then
                        pickerPopup.Visible = false
                end
        end
end)

local function openPicker(key, swatch)
        pickerKey = key
        pickerSwatch = swatch
        pickerCallback = function(color)
                S[key] = {color.R, color.G, color.B}
                applyColorDependent(key)
                scheduleSave()
        end
        setPickerColor(Color3.new(S[key][1], S[key][2], S[key][3]))
        local pos = swatch.AbsolutePosition
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        local x = math.clamp(pos.X - popupW - 10, 8, math.max(vp.X - popupW - 8, 8))
        local y = math.clamp(pos.Y - 24, 8, math.max(vp.Y - popupH - 8, 8))
        pickerPopup.Position = UDim2.fromOffset(x, y)
        pickerPopup.Visible = true
end

-- ряд с кнопкой-образцом цвета
local function makeColorRow(parent, labelKey, key)
        local row = makeRow(parent, 36)

        local label = create("TextLabel", {
                Size                   = UDim2.new(1, -70, 1, 0),
                Position               = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamMedium,
                TextSize               = 13,
                TextColor3             = THEME.text,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                Parent                 = row,
        })
        registerText(label, labelKey)
        bindTheme(label, "TextColor3", "text")

        local swatch = create("Frame", {
                Size                   = UDim2.new(0, 40, 0, 20),
                Position               = UDim2.new(1, -12, 0.5, 0),
                AnchorPoint            = Vector2.new(1, 0.5),
                BackgroundColor3       = Color3.new(S[key][1], S[key][2], S[key][3]),
                BorderSizePixel        = 0,
                Parent                 = row,
        })
        round(swatch, 6)
        stroke(swatch, Color3.fromRGB(255, 255, 255), 0.7, 1)

        row.Activated:Connect(function()
                openPicker(key, swatch)
        end)

        registerRefresher(function()
                swatch.BackgroundColor3 = Color3.new(S[key][1], S[key][2], S[key][3])
        end)
end

-- =============================== ТАБ: МИР ===============================
do
        local scroll = tabs.world.scroll
        makeSection(scroll, "sec_worldcolor")
        makeColorRow(scroll, "wc_picker", "world_color")
        makeSlider(scroll, "wc_strength", "world_strength", 0, 1, 0.05, fmtPct, function()
                applyWorldColor()
        end)
        makeToggle(scroll, "wc_sync_ambient", "sync_ambient", function(on)
                if not on then
                        Lighting.Ambient        = ORIG.Ambient
                        Lighting.OutdoorAmbient = ORIG.OutdoorAmbient
                end
                applyWorldColor()
        end)
        makeToggle(scroll, "wc_sync_fog", "sync_fog", function(on)
                if not on then
                        Lighting.FogColor = ORIG.FogColor
                end
                applyWorldColor()
        end)
        makeToggle(scroll, "wc_sync_atmo", "sync_atmo", function(on)
                if not on then
                        atmosphere.Color = ORIG.AtmoColor
                        atmosphere.Decay = ORIG.AtmoDecay
                end
                applyWorldColor()
        end)
        makeButton(scroll, "wc_reset", function()
                S.world_color = {1, 1, 1}
                S.world_strength = 1
                refreshAll()
                applyWorldColor()
                scheduleSave()
        end)
end

-- ============================ ТАБ: ОСВЕЩЕНИЕ ============================
do
        local scroll = tabs.lighting.scroll

        makeSection(scroll, "sec_presets")
        makeButton(scroll, "preset_day", function()
                S.light_time = 14
                S.light_brightness = 3
                S.light_exposure = 0.1
                S.atmo_density = 0.35
                S.atmo_haze = 0
                S.cc_saturation = 0.05
                applyLighting()
                applySky()
                applyEffects()
                refreshAll()
                scheduleSave()
        end)
        makeButton(scroll, "preset_sunset", function()
                S.light_time = 18.2
                S.light_brightness = 2.5
                S.light_exposure = 0.15
                S.atmo_density = 0.45
                S.atmo_haze = 1.2
                S.cc_brightness = 0.02
                S.cc_contrast = 0.05
                S.cc_saturation = 0.1
                S.sunrays_intensity = 0.2
                applyLighting()
                applySky()
                applyEffects()
                refreshAll()
                scheduleSave()
        end)
        makeButton(scroll, "preset_night", function()
                S.light_time = 0.5
                S.light_brightness = 1.5
                S.light_exposure = -0.2
                S.sky_stars = 2500
                S.sky_bodies = true
                S.cc_saturation = -0.05
                S.fog_end = 800
                applyLighting()
                applySky()
                applyEffects()
                refreshAll()
                scheduleSave()
        end)
        makeButton(scroll, "preset_cinema", function()
                S.cc_contrast = 0.15
                S.cc_saturation = -0.15
                S.bloom_intensity = 0.4
                S.bloom_size = 32
                S.bloom_threshold = 1.2
                S.dof_enabled = true
                S.dof_focus = 35
                S.dof_radius = 60
                S.dof_far = 0.3
                S.cam_fov = 60
                applyEffects()
                refreshAll()
                scheduleSave()
        end)
        makeSection(scroll, "sec_light")
        makeSlider(scroll, "light_brightness", "light_brightness", 0, 10, 0.1, fmt1, applyLighting)
        makeSlider(scroll, "light_time", "light_time", 0, 24, 0.25, fmtTime, applyLighting)
        makeSlider(scroll, "light_exposure", "light_exposure", -3, 3, 0.05, fmt2, applyLighting)
        makeToggle(scroll, "light_shadows", "light_shadows", applyLighting)
        makeSlider(scroll, "light_softness", "light_softness", 0, 1, 0.05, fmtPct, applyLighting)
        makeSlider(scroll, "light_diffuse", "light_diffuse", 0, 1, 0.05, fmtPct, applyLighting)
        makeSlider(scroll, "light_specular", "light_specular", 0, 1, 0.05, fmtPct, applyLighting)
end

-- ============================== ТАБ: НЕБО ==============================
do
        local scroll = tabs.sky.scroll
        makeSection(scroll, "sec_atmo")
        makeSlider(scroll, "atmo_density", "atmo_density", 0, 1, 0.01, fmt2, applySky)
        makeSlider(scroll, "atmo_offset", "atmo_offset", -1, 1, 0.01, fmt2, applySky)
        makeSlider(scroll, "atmo_glare", "atmo_glare", 0, 2, 0.05, fmt2, applySky)
        makeSlider(scroll, "atmo_haze", "atmo_haze", 0, 10, 0.1, fmt1, applySky)
        makeSection(scroll, "sec_fog")
        makeSlider(scroll, "fog_start", "fog_start", 0, 500, 5, fmtInt, applySky)
        makeSlider(scroll, "fog_end", "fog_end", 100, 2000, 25, fmtInt, applySky)
        makeSection(scroll, "sec_water")
        makeSlider(scroll, "water_wavesize", "water_wavesize", 0, 10, 0.1, fmt1, applySky)
        makeSlider(scroll, "water_wavespeed", "water_wavespeed", 0, 50, 1, fmtInt, applySky)
        makeSlider(scroll, "water_reflect", "water_reflect", 0, 1, 0.05, fmtPct, applySky)
        makeSlider(scroll, "water_transparent", "water_transparent", 0, 1, 0.05, fmtPct, applySky)
        makeSection(scroll, "sec_skytop")
        makeSlider(scroll, "sky_stars", "sky_stars", 0, 3000, 50, fmtInt, applySky)
        makeToggle(scroll, "sky_bodies", "sky_bodies", applySky)
end

-- ============================ ТАБ: ЭФФЕКТЫ ============================
do
        local scroll = tabs.effects.scroll
        makeSection(scroll, "sec_cc")
        makeSlider(scroll, "cc_brightness", "cc_brightness", -1, 1, 0.01, fmt2, applyEffects)
        makeSlider(scroll, "cc_contrast", "cc_contrast", -1, 1, 0.01, fmt2, applyEffects)
        makeSlider(scroll, "cc_saturation", "cc_saturation", -1, 2, 0.01, fmt2, applyEffects)
        makeSection(scroll, "sec_bloom")
        makeSlider(scroll, "bloom_intensity", "bloom_intensity", 0, 3, 0.05, fmt2, applyEffects)
        makeSlider(scroll, "bloom_size", "bloom_size", 0, 64, 1, fmtInt, applyEffects)
        makeSlider(scroll, "bloom_threshold", "bloom_threshold", 0, 3, 0.05, fmt2, applyEffects)
        makeSection(scroll, "sec_sunrays")
        makeSlider(scroll, "sunrays_intensity", "sunrays_intensity", 0, 1, 0.01, fmt2, applyEffects)
        makeSlider(scroll, "sunrays_spread", "sunrays_spread", 0, 1, 0.01, fmt2, applyEffects)
        makeSection(scroll, "sec_blur")
        makeSlider(scroll, "blur_size", "blur_size", 0, 30, 0.5, fmt1, applyEffects)
        makeSection(scroll, "sec_dof")
        makeToggle(scroll, "dof_enable", "dof_enabled", applyEffects)
        makeSlider(scroll, "dof_far", "dof_far", 0, 1, 0.05, fmtPct, applyEffects)
        makeSlider(scroll, "dof_focus", "dof_focus", 1, 150, 1, fmtInt, applyEffects)
        makeSlider(scroll, "dof_radius", "dof_radius", 0, 100, 1, fmtInt, applyEffects)
end

-- ============================= ТАБ: КАМЕРА =============================
do
        local scroll = tabs.camera.scroll
        makeSection(scroll, "sec_cam")
        makeSlider(scroll, "cam_fov", "cam_fov", 30, 120, 1, fmtInt, nil)
        makeToggle(scroll, "cam_smooth", "cam_fov_smooth", nil)
        makeSlider(scroll, "cam_roll", "cam_roll", -45, 45, 1, fmtInt, nil)

        makeToggle(scroll, "hide_char", "hide_char", function()
                refreshCharVisuals()
        end)
end

-- ============================== ТАБ: АУРА ==============================
do
        local scroll = tabs.aura.scroll

        makeSection(scroll, "sec_wings")
        makeToggle(scroll, "wings_toggle", "wings_enabled", applyAura)
        makeColorRow(scroll, "wings_color", "wings_color")
        makeSlider(scroll, "wings_scale", "wings_scale", 0.4, 2.5, 0.05, fmt2, applyAura)
        makeSlider(scroll, "wings_ox", "wings_ox", -3, 3, 0.1, fmt1, nil)
        makeSlider(scroll, "wings_oy", "wings_oy", -2, 3, 0.1, fmt1, nil)
        makeSlider(scroll, "wings_oz", "wings_oz", -2, 3, 0.1, fmt1, nil)
        makeSlider(scroll, "wings_opacity", "wings_opacity", 0, 0.9, 0.05, fmtPct, applyAura)
        makeSlider(scroll, "wings_flap", "wings_flap", 0, 3, 0.1, fmt1, nil)
        makeToggle(scroll, "wings_particles", "wings_particles", applyAura)

        makeSection(scroll, "sec_nimbus")
        makeToggle(scroll, "nimbus_toggle", "nimbus_enabled", applyAura)
        makeColorRow(scroll, "nimbus_color", "nimbus_color")
        makeSlider(scroll, "nimbus_scale", "nimbus_scale", 0.4, 2.5, 0.05, fmt2, applyAura)
        makeSlider(scroll, "nimbus_ox", "nimbus_ox", -3, 3, 0.1, fmt1, nil)
        makeSlider(scroll, "nimbus_oy", "nimbus_oy", 0, 4, 0.1, fmt1, nil)
        makeSlider(scroll, "nimbus_oz", "nimbus_oz", -3, 3, 0.1, fmt1, nil)
        makeSlider(scroll, "nimbus_spin", "nimbus_spin", -3, 3, 0.1, fmt1, nil)
        makeSlider(scroll, "nimbus_glow", "nimbus_glow", 0, 5, 0.1, fmt1, applyAura)
        makeToggle(scroll, "nimbus_particles", "nimbus_particles", applyAura)

        makeSection(scroll, "sec_glow")
        makeToggle(scroll, "glow_toggle", "glow_enabled", applyAura)
        makeColorRow(scroll, "glow_color", "glow_color")
        makeSlider(scroll, "glow_fill", "glow_fill", 0, 1, 0.05, fmtPct, applyAura)
        makeSlider(scroll, "glow_outline", "glow_outline", 0, 1, 0.05, fmtPct, applyAura)
        makeSlider(scroll, "glow_light", "glow_light", 0, 5, 0.1, fmt1, applyAura)
        makeToggle(scroll, "glow_pulse", "glow_pulse", nil)
        makeToggle(scroll, "glow_through", "glow_through", applyAura)

        makeSection(scroll, "sec_waves")
        makeToggle(scroll, "waves_toggle", "waves_enabled", applyAura)
        makeColorRow(scroll, "waves_color", "waves_color")
        makeSlider(scroll, "waves_scale", "waves_scale", 0.4, 3, 0.05, fmt2, applyAura)
        makeSlider(scroll, "waves_speed", "waves_speed", 0, 3, 0.1, fmt1, nil)
        makeSlider(scroll, "waves_bend", "waves_bend", 0, 1.5, 0.05, fmt2, nil)
        makeSlider(scroll, "waves_opacity", "waves_opacity", 0, 0.9, 0.05, fmtPct, applyAura)
        makeSlider(scroll, "waves_ox", "waves_ox", -3, 3, 0.1, fmt1, nil)
        makeSlider(scroll, "waves_oy", "waves_oy", -4, 0, 0.1, fmt1, nil)
        makeSlider(scroll, "waves_oz", "waves_oz", -3, 3, 0.1, fmt1, nil)
end

-- ============================= ТАБ: ПОГОДА =============================
do
        local scroll = tabs.weather.scroll

        makeSection(scroll, "sec_presets")
        makeButton(scroll, "preset_storm", function()
                S.rain_enabled = true
                S.rain_intensity = 85
                S.rain_speed = 62
                S.snow_enabled = false
                S.wind = 5
                S.lightning = true
                S.bolts = true
                S.thunder = true
                S.light_time = 16
                S.light_exposure = -0.35
                S.atmo_density = 0.55
                S.fog_end = 700
                applyWeather()
                applyLighting()
                applySky()
                refreshAll()
                scheduleSave()
        end)
        makeButton(scroll, "preset_snow", function()
                S.snow_enabled = true
                S.snow_intensity = 70
                S.snow_speed = 6
                S.rain_enabled = false
                S.wind = -3
                S.lightning = false
                S.light_time = 16
                S.light_exposure = 0.05
                S.atmo_density = 0.4
                applyWeather()
                applyLighting()
                applySky()
                refreshAll()
                scheduleSave()
        end)
        makeButton(scroll, "preset_clear", function()
                S.rain_enabled = false
                S.snow_enabled = false
                S.lightning = false
                S.wind = 0
                S.light_exposure = 0
                S.atmo_density = 0.3
                applyWeather()
                applyLighting()
                applySky()
                refreshAll()
                scheduleSave()
        end)
        makeSection(scroll, "sec_rain")
        makeToggle(scroll, "rain_toggle", "rain_enabled", applyWeather)
        makeSlider(scroll, "rain_intensity", "rain_intensity", 0, 100, 5, fmtPct100, applyWeather)
        makeSlider(scroll, "rain_speed", "rain_speed", 30, 90, 1, fmtInt, applyWeather)
        makeSlider(scroll, "rain_size", "rain_size", 0.15, 0.8, 0.05, fmt2, applyWeather)
        makeSlider(scroll, "rain_transparency", "rain_transparency", 0, 0.9, 0.05, fmtPct, applyWeather)
        makeColorRow(scroll, "rain_color", "rain_color")
        makeToggle(scroll, "rain_sound", "rain_sound", function()
                updateRainSound()
        end)
        makeSlider(scroll, "rain_volume", "rain_volume", 0, 2, 0.05, fmt2, function()
                updateRainSound()
        end)
        makeSection(scroll, "sec_snow")
        makeToggle(scroll, "snow_toggle", "snow_enabled", applyWeather)
        makeSlider(scroll, "snow_intensity", "snow_intensity", 0, 100, 5, fmtPct100, applyWeather)
        makeSlider(scroll, "snow_speed", "snow_speed", 3, 15, 1, fmtInt, applyWeather)
        makeSlider(scroll, "snow_size", "snow_size", 0.2, 1, 0.05, fmt2, applyWeather)
        makeSlider(scroll, "snow_transparency", "snow_transparency", 0, 0.9, 0.05, fmtPct, applyWeather)
        makeColorRow(scroll, "snow_color", "snow_color")
        makeSection(scroll, "sec_general")
        makeSlider(scroll, "wind", "wind", -10, 10, 1, fmtInt, applyWeather)
        makeToggle(scroll, "wind_sound", "wind_sound", function()
                updateWindSound()
        end)
        makeToggle(scroll, "lightning", "lightning", nil)
        makeSection(scroll, "sec_thunder")
        makeToggle(scroll, "bolts", "bolts", nil)
        makeToggle(scroll, "thunder", "thunder", nil)
        makeSlider(scroll, "thunder_volume", "thunder_volume", 0, 2, 0.05, fmt2, nil)
        makeToggle(scroll, "storm_shake", "storm_shake", nil)
end

-- ============================ ВАТЕРМАРКИ ============================
local wmSetVisible
do
        local playerName = LocalPlayer.DisplayName or LocalPlayer.Name

        -- главная ватермарка (можно перетаскивать)
        local wm = create("Frame", {
                Name                   = "WoddWatermark",
                Size                   = UDim2.new(0, 0, 0, 26),
                AutomaticSize          = Enum.AutomaticSize.X,
                Position               = UDim2.new(1, -12, 0, 12),
                AnchorPoint            = Vector2.new(1, 0),
                BackgroundColor3       = THEME.windowBg,
                BackgroundTransparency = 0.25,
                BorderSizePixel        = 0,
                Active                 = true, -- не кликает сквозь в игру
                ZIndex                 = 3,
                Parent                 = ScreenGui,
        })
        round(wm, 8)
        stroke(wm, Color3.fromRGB(255, 255, 255), 0.8, 1)
        bindTheme(wm, "BackgroundColor3", "windowBg")

        local wmList = Instance.new("UIListLayout")
        wmList.FillDirection       = Enum.FillDirection.Horizontal
        wmList.VerticalAlignment   = Enum.VerticalAlignment.Center
        wmList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        wmList.SortOrder           = Enum.SortOrder.LayoutOrder
        wmList.Padding             = UDim.new(0, 6)
        wmList.Parent              = wm

        local wmPad = Instance.new("UIPadding")
        wmPad.PaddingLeft  = UDim.new(0, 11)
        wmPad.PaddingRight = UDim.new(0, 11)
        wmPad.Parent = wm

        local wmDot = create("Frame", {
                Size                   = UDim2.new(0, 6, 0, 6),
                BackgroundColor3       = THEME.accent,
                BorderSizePixel        = 0,
                LayoutOrder            = 1,
                Parent                 = wm,
        })
        round(wmDot, 3)
        bindTheme(wmDot, "BackgroundColor3", "accent")

        local wmLogo = create("TextLabel", {
                Size                   = UDim2.new(0, 0, 0, 14),
                AutomaticSize          = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamBlack,
                TextSize               = 12,
                TextColor3             = Color3.new(1, 1, 1),
                Text                   = "WODD",
                LayoutOrder            = 2,
                Parent                 = wm,
        })
        do -- градиент по логотипу (перекрашивается темой)
                local lg = Instance.new("UIGradient")
                lg.Parent = wmLogo
                bindThemeFn(function()
                        lg.Color = ColorSequence.new(THEME.logoBase, THEME.accent)
                end)
        end

        local wmName = create("TextLabel", {
                Size                   = UDim2.new(0, 0, 0, 14),
                AutomaticSize          = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamMedium,
                TextSize               = 11,
                TextColor3             = THEME.textDim,
                Text                   = playerName,
                LayoutOrder            = 3,
                Parent                 = wm,
        })
        bindTheme(wmName, "TextColor3", "textDim")

        local wmFps = create("TextLabel", {
                Size                   = UDim2.new(0, 0, 0, 14),
                AutomaticSize          = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamBold,
                TextSize               = 11,
                TextColor3             = THEME.accent,
                Text                   = "",
                LayoutOrder            = 4,
                Parent                 = wm,
        })
        bindTheme(wmFps, "TextColor3", "accent")

        -- мини-ватермарка в нижнем левом углу
        local wmMini = create("TextLabel", {
                Name                   = "WoddWatermarkMini",
                Size                   = UDim2.new(0, 110, 0, 14),
                Position               = UDim2.new(0, 12, 1, -10),
                AnchorPoint            = Vector2.new(0, 1),
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamBold,
                TextSize               = 10,
                TextColor3             = THEME.textFaint,
                TextTransparency       = 0.35,
                Text                   = "wodd • visuals",
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 3,
                Parent                 = ScreenGui,
        })
        bindTheme(wmMini, "TextColor3", "textFaint")

        -- FPS для ватермарки (обновление раз в полсекунды)
        local wmAcc, wmFrames = 0, 0
        perFrameHooks[#perFrameHooks + 1] = function(dt)
                wmAcc   = wmAcc + dt
                wmFrames = wmFrames + 1
                if wmAcc >= 0.5 then
                        wmFps.Text = tostring(math.floor(wmFrames / wmAcc + 0.5)) .. " FPS"
                        wmAcc   = 0
                        wmFrames = 0
                end
        end

        -- перетаскивание ватермарки
        do
                local dragging = false
                local dragStart, startPos
                wm.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                dragging  = true
                                dragStart = input.Position
                                startPos  = wm.Position
                        end
                end)
                UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                local delta = input.Position - dragStart
                                -- ватермарку нельзя утащить за пределы экрана
                                local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
                                local ox = math.clamp(startPos.X.Offset + delta.X, 60 - vp.X, -10)
                                local oy = math.clamp(startPos.Y.Offset + delta.Y, 10, vp.Y - 40)
                                wm.Position = UDim2.new(startPos.X.Scale, ox, startPos.Y.Scale, oy)
                        end
                end)
                UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                dragging = false
                        end
                end)
        end

        wmSetVisible = function(state)
                wm.Visible    = state and true or false
                wmMini.Visible = state and true or false
        end
end
wmSetVisible(S.watermark)

-- ============================ ТЕГ ПЕРСОНАЖА ============================
local charTagSetVisible
do
        local tagGui, tagFeat

        local function buildTag(head)
                tagGui = create("BillboardGui", {
                        Name         = "WoddCharTag",
                        Adornee      = head,
                        Size         = UDim2.new(0, 172, 0, 58),
                        StudsOffset  = Vector3.new(0, 2, 0),
                        AlwaysOnTop  = true,
                        MaxDistance  = 120,
                        ResetOnSpawn = false,
                        Parent       = ScreenGui,
                })

                local bg = create("Frame", {
                        Size                   = UDim2.new(1, 0, 1, 0),
                        BackgroundColor3       = THEME.windowBg,
                        BackgroundTransparency = 0.25,
                        BorderSizePixel        = 0,
                        Parent                 = tagGui,
                })
                round(bg, 10)
                stroke(bg, Color3.fromRGB(255, 255, 255), 0.8, 1)
                bindTheme(bg, "BackgroundColor3", "windowBg")

                -- строка 1: точка + WODD
                local top = create("Frame", {
                        Size                   = UDim2.new(1, -16, 0, 16),
                        Position               = UDim2.new(0, 8, 0, 8),
                        BackgroundTransparency = 1,
                        Parent                 = bg,
                })
                local topList = Instance.new("UIListLayout")
                topList.FillDirection       = Enum.FillDirection.Horizontal
                topList.VerticalAlignment   = Enum.VerticalAlignment.Center
                topList.HorizontalAlignment = Enum.HorizontalAlignment.Center
                topList.SortOrder           = Enum.SortOrder.LayoutOrder
                topList.Padding             = UDim.new(0, 5)
                topList.Parent              = top

                local tagDot = create("Frame", {
                        Size                   = UDim2.new(0, 6, 0, 6),
                        BackgroundColor3       = THEME.accent,
                        BorderSizePixel        = 0,
                        LayoutOrder            = 1,
                        Parent                 = top,
                })
                round(tagDot, 3)
                bindTheme(tagDot, "BackgroundColor3", "accent")

                local tagLogo = create("TextLabel", {
                        Size                   = UDim2.new(0, 0, 0, 14),
                        AutomaticSize          = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Font                   = Enum.Font.GothamBlack,
                        TextSize               = 12,
                        TextColor3             = Color3.new(1, 1, 1),
                        Text                   = "WODD",
                        LayoutOrder            = 2,
                        Parent                 = top,
                })
                do -- градиент по логотипу (перекрашивается темой)
                        local lg = Instance.new("UIGradient")
                        lg.Parent = tagLogo
                        bindThemeFn(function()
                                lg.Color = ColorSequence.new(THEME.logoBase, THEME.accent)
                        end)
                end

                -- строка 2: активные фичи (обновляется на лету)
                tagFeat = create("TextLabel", {
                        Size                   = UDim2.new(1, -16, 0, 28),
                        Position               = UDim2.new(0, 8, 0, 26),
                        BackgroundTransparency = 1,
                        Font                   = Enum.Font.GothamMedium,
                        TextSize               = 10,
                        TextColor3             = THEME.textDim,
                        TextWrapped            = true,
                        Text                   = "",
                        Parent                 = bg,
                })
                bindTheme(tagFeat, "TextColor3", "textDim")
        end

        -- список активных визуалов
        local function activeFeatures()
                local t = {}
                local wc = S.world_color
                if wc[1] < 0.99 or wc[2] < 0.99 or wc[3] < 0.99 then
                        t[#t + 1] = T("tag_world")
                end
                if S.rain_enabled then
                        t[#t + 1] = T("tag_rain")
                end
                if S.snow_enabled then
                        t[#t + 1] = T("tag_snow")
                end
                if S.lightning or S.bolts then
                        t[#t + 1] = T("tag_storm")
                end
                if S.wings_enabled then
                        t[#t + 1] = T("tag_wings")
                end
                if S.nimbus_enabled then
                        t[#t + 1] = T("tag_nimbus")
                end
                if S.waves_enabled then
                        t[#t + 1] = T("tag_waves")
                end
                if S.glow_enabled then
                        t[#t + 1] = T("tag_glow")
                end
                return table.concat(t, ", ")
        end

        -- respawn-сейф: пересоздаём тег, обновляем список фич раз в 0.4с
        local tagAcc = 0
        perFrameHooks[#perFrameHooks + 1] = function(dt)
                if not S.char_tag then
                        if tagGui then
                                tagGui:Destroy()
                                tagGui  = nil
                                tagFeat = nil
                        end
                        return
                end
                local ch   = LocalPlayer.Character
                local head = ch and ch:FindFirstChild("Head")
                if not head then
                        return
                end
                if not tagGui then
                        buildTag(head)
                end
                if tagGui.Adornee ~= head then
                        tagGui.Adornee = head -- после респауна
                end
                tagAcc = tagAcc + dt
                if tagAcc >= 0.4 then
                        tagAcc = 0
                        if tagFeat then
                                local s = activeFeatures()
                                if s == "" then
                                        s = T("sub_title")
                                end
                                if tagFeat.Text ~= s then
                                        tagFeat.Text = s
                                end
                        end
                end
        end

        charTagSetVisible = function(state)
                if state == false and tagGui then
                        tagGui:Destroy()
                        tagGui  = nil
                        tagFeat = nil
                end
        end
end

-- ============================ ТЕМА МЕНЮ ============================
-- вызывается при смене акцента из колор-пикера и при сбросе настроек
menuThemeChanged = function()
        applyMenuTheme()
        if currentTab then
                selectTab(currentTab)
        end
        refreshAll()
end

-- ============================ ТАБ: НАСТРОЙКИ ============================
do
        local scroll = tabs.settings.scroll
        makeSection(scroll, "sec_interface")
        makeSlider(scroll, "ui_scale", "ui_scale", 0.7, 1.3, 0.05, fmtPct, function(v)
                uiScale.Scale = v
        end)
        makeSlider(scroll, "ui_transparency", "ui_transparency", 0, 0.7, 0.05, fmtPct, function(v)
                window.BackgroundTransparency = v
        end)
        makeToggle(scroll, "ui_blur", "ui_blur", function()
                updateMenuBlur()
        end)
        makeToggle(scroll, "ui_fps", "ui_fps", nil)
        makeToggle(scroll, "ui_autosave", "ui_autosave", nil)
        makeToggle(scroll, "ui_watermark", "watermark", function(on)
                wmSetVisible(on)
        end)
        makeToggle(scroll, "ui_chartag", "char_tag", function(on)
                charTagSetVisible(on)
        end)
        makeSection(scroll, "sec_theme")
        makeToggle(scroll, "ui_dark", "ui_dark", function()
                applyMenuTheme()
                if currentTab then
                        selectTab(currentTab)
                end
                refreshAll()
        end)
        makeColorRow(scroll, "ui_accent", "ui_accent")
        makeButton(scroll, "lang_row", function()
                toggleLanguage()
        end)
end


-- =========================== СБРОС ВСЕГО ===========================
local function applyAll()
        applyWorldColor()
        applyLighting()
        applySky()
        applyEffects()
        applyAura()
        applyWeather()
end

resetButton.Activated:Connect(function()
        local restored = copyState(S0)
        for k, v in pairs(restored) do
                S[k] = v
        end
        applyAll()
        refreshAll()
        uiScale.Scale = S.ui_scale
        window.BackgroundTransparency = S.ui_transparency
        updateMenuBlur()
        wmSetVisible(S.watermark)
        charTagSetVisible(S.char_tag)
        menuThemeChanged() -- тема и акцент тоже возвращаются к заводским
        refreshCharVisuals()
        if LANG ~= S.ui_lang then
                LANG = S.ui_lang
                applyLanguageTexts()
        end
        scheduleSave()
end)

-- ================== КЛАВИША INSERT + ПЕРЕНАЗНАЧЕНИЕ ==================
local rebinding = false

local function keybindText()
        return T("key_prefix") .. ": " .. CONFIG.TOGGLE_KEY.Name
end
registerDynamic(function()
        if not rebinding then
                keyButton.Text = keybindText()
        end
end)

keyButton.Activated:Connect(function()
        rebinding = true
        keyButton.Text = T("rebinding")
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if rebinding then
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        rebinding = false -- отмена переназначения кликом мыши
                        keyButton.Text = keybindText()
                elseif input.UserInputType == Enum.UserInputType.Keyboard and not gameProcessed then
                        CONFIG.TOGGLE_KEY = input.KeyCode
                        rebinding = false
                        keyButton.Text = keybindText()
                end
                return
        end
        if input.KeyCode == CONFIG.TOGGLE_KEY and not gameProcessed then
                toggleWindow()
        end
end)

-- ============================ ПОДСКАЗКА ============================
do
        local toast = create("Frame", {
                Size                   = UDim2.new(0, 260, 0, 34),
                Position               = UDim2.new(0.5, 0, 1, -60),
                AnchorPoint            = Vector2.new(0.5, 0.5),
                BackgroundColor3       = THEME.windowBg,
                BackgroundTransparency = 0.15,
                BorderSizePixel        = 0,
                Parent                 = ScreenGui,
        })
        round(toast, 10)
        stroke(toast, Color3.fromRGB(255, 255, 255), 0.8, 1)
        bindTheme(toast, "BackgroundColor3", "windowBg")

        local toastLabel = create("TextLabel", {
                Size                   = UDim2.new(1, -16, 1, 0),
                Position               = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Font                   = Enum.Font.GothamMedium,
                TextSize               = 12,
                TextColor3             = THEME.text,
                Text                   = T("toast_hint"),
                Parent                 = toast,
        })
        bindTheme(toastLabel, "TextColor3", "text")

        task.delay(6, function()
                local fade = TweenService:Create(toast, TweenInfo.new(0.6), {BackgroundTransparency = 1})
                local fadeText = TweenService:Create(toastLabel, TweenInfo.new(0.6), {TextTransparency = 1})
                fade:Play()
                fadeText:Play()
                fade.Completed:Wait()
                toast:Destroy()
        end)
end

-- ============================ ИНИЦИАЛИЗАЦИЯ ============================
rainSound.Parent = ScreenGui
windSound.Parent = ScreenGui
for _, snd in ipairs(thunderPool) do
        snd.Parent = ScreenGui
end

applyAll()
refreshAll()
selectTab("world")
setWindowVisible(true)

ScreenGui.Destroying:Connect(function()
        runFlag = false
        pcall(function()
                RunService:UnbindFromRenderStep("WoddPerFrame")
        end)
        pcall(restoreOriginal)
end)
