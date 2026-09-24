--[[
    xyro
    Copyright (c) 2026 nick (.weound)
    Licensed under the Non-Commercial Share-Alike License (see LICENSE in the repo root).
--]]

local prev_lib = getgenv().lx_jfa_lib
local gen = (getgenv().lx_jfa_gen or 0) + 1
getgenv().lx_jfa_gen = gen
getgenv().lx_jfa_abort = true
if prev_lib then pcall(function() prev_lib:unload() end) end
task.wait(0.6)
getgenv().lx_jfa_abort = false

local function check(func)
    local f = _G[func] or getfenv(0)[func] or
    (func == "gethui" and gethui) or
    (func == "setclipboard" and setclipboard) or
    (func == "loadstring" and loadstring) or
    (func == "newcclosure" and newcclosure) or
    (func == "checkcaller" and checkcaller) or
    (func == "firetouchinterest" and firetouchinterest) or
    (func == "firesignal" and firesignal) or
    (func == "setproximitypromptduration" and setproximitypromptduration)

    if not f or type(f) ~= "function" then
        if func == "setproximitypromptduration" or func == "firetouchinterest" then
            warn("missing optional function '" .. func .. "'")
            return true
        end
        warn("your executor does not support '" .. func .. "', bye")
        return false
    end
    return true
end

local funcs = {"getgenv", "newcclosure", "checkcaller", "loadstring", "gethui", "setclipboard", "firetouchinterest", "firesignal", "setproximitypromptduration"}
for _, f in ipairs(funcs) do
    if not check(f) then return end
end

if not game.HttpGet then
    warn("your executor does not support 'HttpGet', bye")
    return
end

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/potassiumm/lx/main/ui/fware/library.luau"))()
getgenv().lx_jfa_lib = library
getgenv().lx_jfa_on = true

library.directory = "Xyro/jump-for-animals"

local players = game:GetService("Players")
local gen = getgenv().lx_jfa_gen
local function alive()
    return getgenv().lx_jfa_gen == gen
end
local uis = game:GetService("UserInputService")
local run = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")
local ws = workspace
local plr = players.LocalPlayer
local cam = ws.CurrentCamera
local hs = game:GetService("HttpService")
local tps = game:GetService("TeleportService")
local light = game:GetService("Lighting")
local setclipboard = setclipboard or function() end
local gethui = gethui or function() return game:GetService("CoreGui") end
local rem = rs:WaitForChild("Remotes")
local map = ws:WaitForChild("Map")
local stages = map:WaitForChild("Stages")

local rarity_rank = {Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Divine = 7, Celestial = 8, Eternal = 9}
local rarity_list = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Celestial", "Eternal"}
local rarity_color = {
    Common = Color3.fromRGB(180, 180, 180),
    Uncommon = Color3.fromRGB(90, 255, 120),
    Rare = Color3.fromRGB(60, 160, 255),
    Epic = Color3.fromRGB(170, 80, 255),
    Legendary = Color3.fromRGB(255, 180, 40),
    Mythic = Color3.fromRGB(255, 80, 80),
    Divine = Color3.fromRGB(255, 220, 90),
    Celestial = Color3.fromRGB(120, 200, 255),
    Eternal = Color3.new(1, 1, 1)
}

local area_index = {}
do
    local ok, Areas = pcall(require, rs.Settings.Areas)
    if ok and type(Areas.List) == "table" then
        for i, a in ipairs(Areas.List) do area_index[a.Name] = i end
    end
end

local w = library:window({
    title = "xyro",
    subtitle = " - jump for animals",
    size = UDim2.new(0, 650, 0, 450),
    icon = "moon",
    changelog_url = "https://raw.githubusercontent.com/potassiumm/lx/main/changelogs/jump-for-animals.md",
    discord_link = "discord.gg/n6SzrKpVnU",
    script_url = "https://raw.githubusercontent.com/potassiumm/lx/main/games/jump-for-animals.luau"
})

local t1 = w:tab({ name = "steal", icon = "target", search = true })
local t2 = w:tab({ name = "eggs", icon = "egg", search = true })
local t3 = w:tab({ name = "train", icon = "swords", search = true })
local t4 = w:tab({ name = "rewards", icon = "rocket", search = true })
local t5 = w:tab({ name = "player", icon = "user", search = true })
local t6 = w:tab({ name = "visuals", icon = "eye", search = true })
local t7 = w:tab({ name = "misc", icon = "settings", search = true })

local function fire(name, ...)
    local args = {...}
    pcall(function()
        rem[name]:FireServer(unpack(args))
    end)
end

local notif_q = {}
local function notify(text, dur)
    if #notif_q > 8 then table.remove(notif_q, 1) end
    table.insert(notif_q, {tostring(text), tonumber(dur) or 4})
end

task.spawn(function()
    while alive() do
        local nn = table.remove(notif_q, 1)
        if nn then
            pcall(function()
                w:notification({ text = nn[1], duration = nn[2] })
            end)
            task.wait(0.35)
        else
            task.wait(0.2)
        end
    end
end)

local function my_plot()
    local pv = plr:FindFirstChild("Plot")
    return pv and pv.Value or nil
end

local function start_pos()
    local st = map:FindFirstChild("Start")
    if not st then return nil end
    local p = st:IsA("Model") and (st.PrimaryPart or st:FindFirstChildWhichIsA("BasePart", true)) or st
    return p and p.Position or nil
end

local function plot_spawn()
    local plot = my_plot()
    if not plot then return nil end
    for _, nm in ipairs({"Spawn", "PlotSpawn", "SpawnPoint", "Base"}) do
        local p = plot:FindFirstChild(nm, true)
        if p and p:IsA("BasePart") then return p.Position end
    end
    local det = plot:FindFirstChild("Detector")
    return det and det.Position or nil
end

local carrying = function() return (tonumber(plr:GetAttribute("CarriedEggCount")) or 0) > 0 end
local carry_count = function() return tonumber(plr:GetAttribute("CarriedEggCount")) or 0 end
local carry_cap = function() return tonumber(plr:GetAttribute("EggCarryCapacity")) or 1 end

local tp_mode = true
local glide_speed = 150
local steal_status = ""
getgenv().lx_jfa_status = ""

local function set_status(s)
    steal_status = s
    getgenv().lx_jfa_status = s
end

local function move_to(pos, hold)
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if typeof(pos) ~= "Vector3" then return false end
    local cf = CFrame.new(pos + Vector3.new(0, 3.5, 0))
    if tp_mode then
        hrp.Anchored = true
        hrp.CFrame = cf
        task.wait(hold or 0.15)
        hrp.Anchored = false
        return true
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    hrp.Anchored = true
    local start = hrp.CFrame
    local dist = (cf.Position - start.Position).Magnitude
    local dur = math.max(dist / math.max(glide_speed, 5), 0.05)
    local t0 = os.clock()
    while os.clock() - t0 < dur + 2 do
        if getgenv().lx_jfa_abort or not alive() then break end
        if hrp.Parent == nil then break end
        local a = math.clamp((os.clock() - t0) / dur, 0, 1)
        hrp.CFrame = start:Lerp(cf, a)
        if a >= 1 then break end
        run.RenderStepped:Wait()
    end
    hrp.Anchored = false
    task.wait(hold or 0.15)
    return true
end

local egg_cache = {}
local egg_cache_t = 0
local species_rarity = {}
local pet_snapshot = {}

local function field_eggs()
    if os.clock() - egg_cache_t < 0.4 then return egg_cache end
    egg_cache_t = os.clock()
    local out = {}
    for _, st in ipairs(stages:GetChildren()) do
        local se = st:FindFirstChild("SpawnedEggs")
        if se then
            for _, egg in ipairs(se:GetChildren()) do
                local root = egg:FindFirstChild("EggRoot")
                if root and egg.Parent then
                    local att = root:FindFirstChild("EggPromptAttachment")
                    local prompt = att and att:FindFirstChild("CollectPrompt") or root:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                    out[#out + 1] = {
                        egg = egg,
                        root = root,
                        prompt = prompt,
                        area = tostring(egg:GetAttribute("AreaName") or st.Name),
                        spawner = tostring(egg:GetAttribute("SpawnerName") or "1"),
                        rarity = tostring(egg:GetAttribute("Rarity") or "Common"),
                        species = tostring(egg:GetAttribute("Species") or egg.Name),
                        ai = area_index[tostring(egg:GetAttribute("AreaName") or st.Name)] or 0
                    }
                    species_rarity[out[#out].species] = out[#out].rarity
                    end
                end
            end
        end
    end
    egg_cache = out
    return out
end

local area_req = {}
local last_req = {v = 0, t = 0}
local egg_fail = {}

local jp_req = {
    ["Coral Reef1"] = 60, ["Coral Reef2"] = 80,
    ["Winter1"] = 115, ["Winter2"] = 150,
    ["Desert1"] = 180, ["Desert2"] = 205,
    ["Crystal Mines1"] = 210, ["Crystal Mines2"] = 230,
    ["Jungle1"] = 245, ["Jungle2"] = 265,
    ["Mystic Isles1"] = 285, ["Mystic Isles2"] = 305,
    ["Prehistoric1"] = 325, ["Prehistoric2"] = 395,
    ["Celestial Heights1"] = 450, ["Celestial Heights2"] = 510,
    ["Savannah1"] = 575, ["Savannah2"] = 640
}

rem.Notification.OnClientEvent:Connect(function(a, b)
    local txt = type(a) == "table" and tostring(a.Text or a.Message) or tostring(b or a)
    local num = string.match(txt, "You need (%d+) Jump Power")
    if num then
        last_req.v = tonumber(num) or 0
        last_req.t = os.clock()
    end
end)

local steal_biomes = {}
local steal_minrarity = 0
local steal_top_zone = false
local top_zone_seen = 1

local function my_jp()
    local jp = plr:FindFirstChild("JumpPower")
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    local v = jp and tonumber(jp.Value) or 0
    if v < 1 and hum and hum.UseJumpPower then v = tonumber(hum.JumpPower) or 0 end
    return v
end

local function egg_req(rec)
    local key = rec.area .. tostring(rec.spawner or "")
    local static = jp_req[key]
    if static then return static end
    return area_req[rec.ai]
end

local function steal_pick()
    local best, bestd = nil, math.huge
    local bestscore = -1
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    local eggs = field_eggs()
    local jp = my_jp()
    local now = os.clock()
    for u, t in pairs(egg_fail) do
        if now - t > 6 then egg_fail[u] = nil end
    end
    local maxai = 0
    if steal_top_zone then
        for _, rec in ipairs(eggs) do
            if next(steal_biomes) == nil or steal_biomes[rec.area] then
                local req = egg_req(rec)
                if not req or req <= jp then
                    if rec.ai > maxai then maxai = rec.ai end
                end
            end
        end
        if maxai == 0 then maxai = top_zone_seen end
    end
    for _, rec in ipairs(eggs) do
        if next(steal_biomes) ~= nil and not steal_biomes[rec.area] then continue end
        if steal_top_zone and rec.ai > maxai then continue end
        local req = egg_req(rec)
        if req and req > jp then continue end
        local rank = rarity_rank[rec.rarity] or 1
        if rank < steal_minrarity then continue end
        local fu = rec.root:GetDebugId()
        if egg_fail[fu] then continue end
        local score = rank * 1000000 + rec.ai * 5000
        local d = (hrp and (hrp.Position - rec.root.Position).Magnitude) or 0
        if score > bestscore or (score == bestscore and d < bestd) then
            bestscore = score
            bestd = d
            best = rec
        end
    end
    return best
end

local function fire_prompt(prompt)
    if not prompt then return false end
    local okf = pcall(function()
        fireproximityprompt(prompt)
    end)
    if okf then return true end
    return pcall(function()
        firesignal(prompt.Triggered, plr)
    end)
end

local function deliver(timeout)
    local t0 = os.clock()
    local sp = start_pos()
    if not sp then return false end
    while carrying() and os.clock() - t0 < (timeout or 10) do
        if getgenv().lx_jfa_abort then return false end
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = true
            hrp.CFrame = CFrame.new(sp + Vector3.new(0, 3.5, 0))
            task.wait(0.12)
            hrp.Anchored = false
        end
        task.wait(0.15)
        if not carrying() then return true end
    end
    return not carrying()
end

local function steal_one(rec)
    if not rec or not rec.root or not rec.root.Parent then return false end
    if getgenv().lx_jfa_abort then return false end
    set_status("egg " .. rec.species .. " [" .. rec.rarity .. "]")
    move_to(rec.root.Position, 0.05)
    if getgenv().lx_jfa_abort then return false end
    if not rec.prompt or not rec.prompt.Parent then
        set_status("egg has no prompt")
        return false
    end
    set_status("grabbing egg")
    fire_prompt(rec.prompt)
    local t0 = os.clock()
    while carry_count() < 1 and os.clock() - t0 < 0.7 do
        task.wait(0.04)
        if getgenv().lx_jfa_abort then return false end
    end
    if carry_count() < 1 then
        fire_prompt(rec.prompt)
        t0 = os.clock()
        while carry_count() < 1 and os.clock() - t0 < 1 do
            task.wait(0.04)
            if getgenv().lx_jfa_abort then return false end
        end
    end
    if carry_count() < 1 then
        if os.clock() - last_req.t < 3 and last_req.v > 0 then
            area_req[rec.ai] = last_req.v
            set_status("area locked - needs " .. last_req.v .. " jp")
            last_req.v = 0
        end
        egg_fail[rec.root:GetDebugId()] = os.clock()
        set_status("grab failed")
        return false
    end
    if rec.ai > top_zone_seen then top_zone_seen = rec.ai end
    set_status("delivering")
    local got = carry_count()
    local okd = deliver(10)
    if okd then
        notify("delivered " .. got .. " egg(s)", 2)
        set_status("secured")
        task.wait(0.15)
    else
        set_status("deliver failed")
    end
    return okd
end

local auto_steal = false
local steal_run = 0
local fossil_on = false
local fossil_active = false
local fossil_work = nil

local function steal_loop(runid)
    while auto_steal and alive() and steal_run == runid and not getgenv().lx_jfa_abort do
        local okl, lerr = pcall(function()
            if getgenv().lx_jfa_abort or steal_run ~= runid then return end
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then task.wait(1) return end
            if (fossil_on and fossil_active) or (tonumber(plr:GetAttribute("CarriedFossilCount")) or 0) > 0 then
                set_status("fossils first")
                task.wait(1)
                return
            end
            if carry_count() >= carry_cap() then
                set_status("delivering")
                deliver(12)
                return
            end
            local rec = steal_pick()
            if not rec then
                if carrying() then
                    deliver(12)
                else
                    set_status("no egg found")
                    task.wait(1)
                end
                return
            end
            steal_one(rec)
        end)
        if not okl then
            set_status("steal err")
            notify("steal error: " .. tostring(lerr), 3)
            task.wait(1)
        end
        if getgenv().lx_jfa_abort or steal_run ~= runid then break end
    end
end

do

local s1 = t1:section({ name = "steal" })

library.toggle(s1, { name = "auto steal", default = false, callback = function(v)
    auto_steal = v
    if not v then
        if (steal_run or 0) > 0 then
            getgenv().lx_jfa_abort = true
        end
        return
    end
    local runid = steal_run + 1
    steal_run = runid
    getgenv().lx_jfa_abort = false
    task.spawn(function()
        steal_loop(runid)
        if steal_run == runid then
            set_status("")
            notify("auto steal stopped")
        end
    end)
end })

library.dropdown(s1, { name = "areas", options = (function()
    local l = {}
    for nm in pairs(area_index) do table.insert(l, nm) end
    table.sort(l, function(a, b) return area_index[a] < area_index[b] end)
    return l
end)(), multiple = true, default = {}, callback = function(v)
    steal_biomes = {}
    for _, b in ipairs(v) do steal_biomes[b] = true end
end })

library.dropdown(s1, { name = "min rarity", options = {"any", unpack(rarity_list)}, default = "any", callback = function(v)
    steal_minrarity = v == "any" and 0 or (rarity_rank[v] or 0)
end })

library.toggle(s1, { name = "target best zone and under", default = false, callback = function(v) steal_top_zone = v end })

local inst_on = false

library.toggle(s1, { name = "instant steal", default = false, callback = function(v)
    inst_on = v
    if v then
        task.spawn(function()
            while inst_on and alive() do
                for _, pr in ipairs(ws:GetDescendants()) do
                    if pr:IsA("ProximityPrompt") and pr.HoldDuration > 0 then
                        pcall(function() pr.HoldDuration = 0 end)
                        pcall(setproximitypromptduration, pr, 0)
                    end
                end
                task.wait(20)
            end
        end)
    end
end })

library.toggle(s1, { name = "tp mode", default = true, callback = function(v) tp_mode = v end })
library.slider(s1, { name = "glide speed", min = 20, max = 400, default = 150, callback = function(v) glide_speed = v end })

library.button(s1, { name = "steal best egg now", callback = function()
    task.spawn(function()
        local rec = steal_pick()
        if rec then steal_one(rec) end
    end)
end })

library.button(s1, { name = "deliver held eggs", callback = function()
    task.spawn(function()
        deliver(12)
    end)
end })

local anti_guard = false
local guard_conn = nil

library.toggle(s1, { name = "disable guards", default = false, callback = function(v)
    anti_guard = v
    if v then
        task.spawn(function()
            while anti_guard and alive() do
                map:SetAttribute("GuardStunnedUntil", ws:GetServerTimeNow() + 30)
                local cg = map:FindFirstChild("ClientGuards")
                if cg then cg:Destroy() end
                task.wait(4)
            end
        end)
    end
end })

local anti_fling = false

library.toggle(s1, { name = "anti fling", default = false, callback = function(v)
    anti_fling = v
end })

run.Heartbeat:Connect(function()
    if not anti_fling or not alive() then return end
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local v = hrp.AssemblyLinearVelocity
    local flat = Vector3.new(v.X, 0, v.Z)
    if flat.Magnitude > 120 then
        hrp.AssemblyLinearVelocity = flat.Unit * 60 + Vector3.new(0, math.max(v.Y, 0), 0)
    end
end)

local function fossil_station()
    local fe = map:FindFirstChild("FossilEvent")
    local st = fe and fe:FindFirstChild("Station")
    local spot = st and st:FindFirstChild("FossilSpot", true)
    local pp = st and st:FindFirstChild("PlacePrompt", true)
    local pos = spot and spot.Position or nil
    if not pos and pp and pp.Parent and pp.Parent:IsA("Attachment") then
        pos = pp.Parent.WorldPosition
    end
    return pos, pp
end

local fossil_fail = {}

local function fossil_req(f)
    local an = tostring(f:GetAttribute("AreaName") or "")
    local s = jp_req[an .. tostring(f:GetAttribute("SpawnerName") or "")]
    if s then return s end
    return area_req[area_index[an]]
end

local function free_fossil()
    local jp = my_jp()
    local now = os.clock()
    for u, t in pairs(fossil_fail) do
        if now - t > 6 then fossil_fail[u] = nil end
    end
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    local best, bestscore = nil, -1
    for _, st in ipairs(stages:GetChildren()) do
        local sf = st:FindFirstChild("SpawnedFossils")
        if sf then
            for _, f in ipairs(sf:GetChildren()) do
                local carriedby = tonumber(f:GetAttribute("CarriedByUserId")) or 0
                local p = f:FindFirstChild("DigPrompt", true)
                if p and p.Enabled and carriedby == 0 and not fossil_fail[f:GetDebugId()] then
                    local req = fossil_req(f)
                    if not req or req <= jp then
                        local frag = tonumber(f:GetAttribute("Fragments")) or 0
                        local d = hrp and (hrp.Position - f:GetPivot().Position).Magnitude or 0
                        local score = frag * 1000 - d
                        if score > bestscore then
                            bestscore = score
                            best = {f = f, p = p}
                        end
                    end
                end
            end
        end
    end
    return best
end

fossil_work = function()
    if (plr:GetAttribute("PendingFossilName") or "") ~= "" then return true end
    if (tonumber(plr:GetAttribute("CarriedFossilCount")) or 0) > 0 then return true end
    return free_fossil() ~= nil
end

library.toggle(s1, { name = "auto steal fossils", default = false, callback = function(v)
    fossil_on = v
    if fossil_on then
        task.spawn(function()
            while fossil_on and alive() do
                local ok, err = pcall(function()                    if map:GetAttribute("FossilEventActive") ~= true then
                        fossil_active = false
                        set_status("fossils - event not active")
                        task.wait(5)
                        return
                    end
                    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                    if not hum or hum.Health <= 0 then task.wait(1) return end
                    fossil_active = true
                    local pending = plr:GetAttribute("PendingFossilName")
                    if pending ~= nil and pending ~= "" then
                        set_status("cleaning fossil")
                        local sspot = fossil_station()
                        if sspot then move_to(sspot, 0.1) end
                        fire("Fossil", "Finish")
                        fire("Fossil", "Finish")
                        task.wait(1.5)
                        if (plr:GetAttribute("PendingFossilName") or "") ~= "" then
                            local started = tonumber(plr:GetAttribute("PendingFossilStartedAt")) or 0
                            local left = started + 8.5 - ws:GetServerTimeNow()
                            if left > 0 then task.wait(left) end
                            fire("Fossil", "Finish")
                            task.wait(1)
                        end
                        notify("fossil cleaned: " .. tostring(pending), 2)
                        return
                    end
                    if (tonumber(plr:GetAttribute("CarriedFossilCount")) or 0) > 0 then
                        set_status("placing fossil")
                        local sspot, spp = fossil_station()
                        if sspot and spp then
                            move_to(sspot, 0.05)
                            for _ = 1, 3 do
                                pcall(function() fireproximityprompt(spp) end)
                                local t0 = os.clock()
                                while (plr:GetAttribute("PendingFossilName") or "") == "" and os.clock() - t0 < 0.8 do
                                    task.wait(0.05)
                                end
                                if (plr:GetAttribute("PendingFossilName") or "") ~= "" then break end
                                move_to(sspot, 0.05)
                            end
                        end
                        return
                    end
                    local pick = free_fossil()
                    if not pick then
                        fossil_active = false
                        set_status("fossils - none reachable")
                        task.wait(3)
                        return
                    end
                    set_status("digging fossil")
                    local dpos = pick.p.Parent and pick.p.Parent:IsA("Attachment") and pick.p.Parent.WorldPosition or pick.f:GetPivot().Position
                    for _ = 1, 3 do
                        move_to(dpos, 0.05)
                        pcall(function() fireproximityprompt(pick.p) end)
                        local t0 = os.clock()
                        while (tonumber(plr:GetAttribute("CarriedFossilCount")) or 0) == 0 and os.clock() - t0 < 0.9 do
                            task.wait(0.05)
                        end
                        if (tonumber(plr:GetAttribute("CarriedFossilCount")) or 0) > 0 then break end
                    end
                    if (tonumber(plr:GetAttribute("CarriedFossilCount")) or 0) == 0 then
                        fossil_fail[pick.f:GetDebugId()] = math.huge
                        local an = tostring(pick.f:GetAttribute("AreaName") or "")
                        local ai2 = area_index[an]
                        if os.clock() - last_req.t < 3 and last_req.v > 0 and ai2 then
                            area_req[ai2] = last_req.v
                            last_req.v = 0
                        elseif ai2 and area_req[ai2] == nil then
                            area_req[ai2] = my_jp() + 1
                        end
                        task.wait(2)
                    end
                end)
                if not ok then
                    set_status("fossil err")
                    notify("fossil error: " .. tostring(err), 3)
                    task.wait(1)
                end
            end
        end)
    end
end })

end

do

local s2 = t2:section({ name = "eggs" })

local plant_on = false
local plant_i = 0
pet_snapshot = {}
local busy_until = 0

rem.PetInventory.OnClientEvent:Connect(function(a, b, c, d, e)
    if a == "Snapshot" and type(b) == "table" then
        pet_snapshot.items = b
        pet_snapshot.t = os.clock()
        pet_snapshot.active = tonumber(c) or 0
        pet_snapshot.price = tonumber(d) or 0
        pet_snapshot.slots = tonumber(e) or 0
    end
end)

rem.Notification.OnClientEvent:Connect(function(a, b)
    local txt = type(a) == "table" and tostring(a.Text or a.Message) or tostring(b or a)
    if string.find(txt, "spots are busy") then busy_until = os.clock() + 8 end
end)

local function snapshot_eggs()
    local out = {}
    if type(pet_snapshot.items) == "table" then
        for _, v in ipairs(pet_snapshot.items) do
            if type(v) == "table" and v.Kind == "Egg" then out[#out+1] = v end
        end
    end
    return out
end

local function egg_tools()
    local out = {}
    local bp = plr:FindFirstChild("Backpack")
    local ch = plr.Character
    local scan = function(c)
        if c:IsA("Tool") and typeof(c:GetAttribute("EggId")) == "string" then
            out[c:GetAttribute("EggId")] = c
        end
    end
    if bp then for _, t in ipairs(bp:GetChildren()) do scan(t) end end
    if ch then for _, t in ipairs(ch:GetChildren()) do scan(t) end end
    return out
end

local function try_place(egid, gx, gz)
    local plot = my_plot()
    if not plot then return nil end
    local det = plot:FindFirstChild("Detector")
    if not det then return nil end
    local pos = det.Position + Vector3.new(gx, det.Size.Y * 0.5, gz)
    fire("PlaceEggRequest", egid, pos)
    return true
end

local function placed_eggs()
    local out = {}
    local plot = my_plot()
    local pe = plot and plot:FindFirstChild("PlacedEggs")
    if pe then
        for _, m in ipairs(pe:GetChildren()) do
            local egid = m:GetAttribute("EggId")
            if typeof(egid) == "string" then out[egid] = m end
        end
    end
    return out
end

library.toggle(s2, { name = "auto place eggs", default = false, callback = function(v)
    plant_on = v
    if plant_on then
        task.spawn(function()
            while plant_on and alive() do
                if os.clock() < busy_until then task.wait(1.5) continue end
                local fresh = (os.clock() - (pet_snapshot.t or 0)) < 4
                if not fresh then
                    fire("PetInventory", "Get")
                    task.wait(0.3)
                end
                if #snapshot_eggs() >= 8 then task.wait(5) continue end
                local tools = egg_tools()
                local bestlist = {}
                for Eid, t2 in pairs(tools) do
                    local sp = string.gsub(t2.Name, " Egg$", "")
                    local rk = rarity_rank[species_rarity[sp]] or 0
                    bestlist[#bestlist+1] = {id = Eid, tool = t2, rank = rk}
                end
                table.sort(bestlist, function(a, b) return a.rank > b.rank end)
                local pick = bestlist[1]
                if not pick then
                    task.wait(3)
                    continue
                end
                local egid, tool = pick.id, pick.tool
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and tool.Parent ~= plr.Character then
                    hum:EquipTool(tool)
                    task.wait(0.3)
                end
                if tool.Parent ~= plr.Character then
                    task.wait(0.8)
                    continue
                end
                local plot = my_plot()
                local det = plot and plot:FindFirstChild("Detector")
                if not det then task.wait(2) continue end
                local col = plant_i % 7
                local row = math.floor(plant_i / 7) % 5
                local gx = (col - 3) * 7.5
                local gz = (row - 2) * 7.5
                plant_i = plant_i + 1
                fire("PlaceEggRequest", egid, det.Position + Vector3.new(gx, det.Size.Y * 0.5, gz))
                task.wait(0.25)
            end
        end)
    end
end })

local function placed_eggs()
    local out = {}
    local plot = my_plot()
    local pe = plot and plot:FindFirstChild("PlacedEggs")
    if pe then
        for _, m in ipairs(pe:GetChildren()) do
            local egid = m:GetAttribute("EggId")
            if typeof(egid) == "string" then out[egid] = m end
        end
    end
    return out
end

local hatch_on = false

library.toggle(s2, { name = "auto hatch eggs", default = false, callback = function(v)
    hatch_on = v
    if hatch_on then
        task.spawn(function()
            while hatch_on and alive() do
                local fresh = (os.clock() - (pet_snapshot.t or 0)) < 4
                if not fresh then
                    fire("PetInventory", "Get")
                    task.wait(0.45)
                end
                local now = ws:GetServerTimeNow()
                local ready = {}
                for _, v in ipairs(snapshot_eggs()) do
                    local ha = tonumber(v.HatchAt) or 0
                    if ha > 0 and ha <= now + 1 then
                        local rk = rarity_rank[species_rarity[string.gsub(tostring(v.Name), " Egg$", "")]] or 0
                        ready[#ready+1] = {v = v, rk = rk}
                    end
                end
                table.sort(ready, function(a, b) return a.rk > b.rk end)
                if #ready > 0 then
                    fire("PetInventory", "Get")
                    task.wait(1)
                    local now2 = ws:GetServerTimeNow()
                    local due = {}
                    for _, v in ipairs(snapshot_eggs()) do
                        local ha = tonumber(v.HatchAt) or 0
                        if ha > 0 and ha <= now2 + 1 then
                            local rk = rarity_rank[species_rarity[string.gsub(tostring(v.Name), " Egg$", "")]] or 0
                            due[#due+1] = {v = v, rk = rk}
                        end
                    end
                    table.sort(due, function(a, b) return a.rk > b.rk end)
                    for _, r in ipairs(due) do
                        fire("PetInventory", "EggAction", r.v.Id)
                    end
                    task.wait(1)
                else
                    task.wait(1.5)
                end
            end
        end)
    end
end })

library.button(s2, { name = "hatch all now", callback = function()
    task.spawn(function()
        fire("PetInventory", "Get")
        task.wait(1)
        local now = ws:GetServerTimeNow()
        local n2 = 0
        for _, v in ipairs(snapshot_eggs()) do
            if (tonumber(v.HatchAt) or 0) <= now + 1 then
                fire("PetInventory", "EggAction", v.Id)
                n2 = n2 + 1
                task.wait(0.8)
            end
        end
        notify("hatch pass: " .. n2 .. " attempted", 3)
    end)
end })

local sell_on = false
local sell_interval = 60

local function held_pet_tool()
    local ch = plr.Character
    if ch then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("IsPetInventoryTool") == true then return t end
        end
    end
    return nil
end

local function next_pet_tool()
    local bp = plr:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("IsPetInventoryTool") == true then return t end
        end
    end
    return nil
end

library.toggle(s2, { name = "auto sell animals", default = false, callback = function(v)
    sell_on = v
    if sell_on then
        task.spawn(function()
            while sell_on and alive() do
                local tool = held_pet_tool() or next_pet_tool()
                if not tool then task.wait(3) continue end
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then task.wait(1) continue end
                if tool.Parent ~= plr.Character then
                    hum:EquipTool(tool)
                    task.wait(0.4)
                end
                if not held_pet_tool() then task.wait(0.8) continue end
                local sell = map:FindFirstChild("Sell")
                local det = sell and sell:FindFirstChild("Detector", true)
                if det then
                    move_to(det.Position, 0.15)
                    fire("Sell")
                    task.wait(1)
                else
                    task.wait(2)
                end
            end
        end)
    end
end })

library.slider(s2, { name = "sell interval", min = 15, max = 300, default = 60, callback = function(v) sell_interval = v end })

end

do

local s3 = t3:section({ name = "training" })

local squat_on = false
local idle_train = false
local idle_since = 0
local squat_target = 0

local function click_bonus()
    local ui = plr:FindFirstChild("PlayerGui")
    local pg = ui and ui:FindFirstChild("UI")
    if not pg then return false end
    local b = pg:FindFirstChild("SquatBonus")
    if not b or not b.Visible then return false end
    local main = b:FindFirstChild("Main")
    local det = main and main:FindFirstChild("Detector")
    if det and det:IsA("GuiButton") then
        pcall(function()
            firesignal(det.Activated)
        end)
        return true
    end
    return false
end

local function is_night_now()
    return light.ClockTime < 5.5 or light.ClockTime > 18.5
end

library.toggle(s3, { name = "auto squat", default = false, callback = function(v)
    squat_on = v
end })

library.toggle(s3, { name = "train when idle", default = false, callback = function(v)
    idle_train = v
end })

library.slider(s3, { name = "stop at jump power", min = 0, max = 800, default = 0, callback = function(v) squat_target = v end })

local barbell_on = false

local function cash_amount()
    local ls = plr:FindFirstChild("leaderstats")
    local c = ls and ls:FindFirstChild("Cash")
    if not c then return 0 end
    local v = c:FindFirstChild("V") or c:FindFirstChildOfClass("NumberValue") or c:FindFirstChildOfClass("IntValue")
    return tonumber(v and v.Value) or tonumber(c.Value) or 0
end

library.toggle(s3, { name = "auto upgrade barbell", default = false, callback = function(v)
    barbell_on = v
    if barbell_on then
        task.spawn(function()
            while barbell_on and alive() do
                local lvl = plr:FindFirstChild("BarbellLevel")
                local ok, cfg = pcall(require, rs.Settings.BarbellUpgrades)
                local nxt = (ok and cfg and cfg.GetNext and lvl) and cfg.GetNext(lvl.Value) or nil
                local price = nxt and tonumber(nxt.CashPrice) or 0
                if price > 0 and cash_amount() >= price then
                    local pl = my_plot()
                    local prompt = pl and pl:FindFirstChild("BarbellUpgradePrompt", true)
                    if prompt then
                        set_status("upgrading barbell")
                        move_to(prompt.Parent.Position, 0.1)
                        pcall(function() fireproximityprompt(prompt) end)
                        task.wait(1.5)
                    end
                end
                task.wait(2)
            end
        end)
    end
end })

local plot_up = false

library.toggle(s3, { name = "auto upgrade plot", default = false, callback = function(v)
    plot_up = v
    if plot_up then
        task.spawn(function()
            while plot_up and alive() do
                local fresh = (os.clock() - (pet_snapshot.t or 0)) < 6
                if not fresh then
                    fire("PetInventory", "Get")
                    task.wait(1)
                end
                local price = tonumber(pet_snapshot.price) or 0
                if price > 0 and cash_amount() >= price then
                    fire("PetInventory", "BuyEquipSlot")
                    set_status("upgrading plot")
                    task.wait(1.5)
                else
                    task.wait(4)
                end
            end
        end)
    end
end })

library.button(s3, { name = "stop squatting", callback = function()
    fire("StopSquattingRequest")
end })

task.spawn(function()
    while alive() do
        local want = false
        if squat_on then
            want = true
        elseif idle_train then
            if steal_pick and fossil_work and ((auto_steal and steal_pick()) or (fossil_on and map:GetAttribute("FossilEventActive") == true and fossil_work())) then
                want = false
            else
                want = is_night_now() or (os.clock() - idle_since >= 0.5)
            end
        end
        if not (squat_on or idle_train) then
            if plr:GetAttribute("IsSquatting") == true then fire("StopSquattingRequest") end
            task.wait(1)
            continue
        end
        local jp = plr:FindFirstChild("JumpPower")
        local jpnow = jp and tonumber(jp.Value) or 0
        if want and squat_target > 0 and jpnow >= squat_target then
            want = false
            set_status("squat target reached")
        end
        if not want then
            if plr:GetAttribute("IsSquatting") == true then fire("StopSquattingRequest") end
            task.wait(1.5)
            continue
        end
        local plot = my_plot()
        local det = plot and plot:FindFirstChild("SquatZone") and plot.SquatZone:FindFirstChild("Floor") and plot.SquatZone.Floor:FindFirstChild("Detector")
        if not det then task.wait(2) continue end
        if plr:GetAttribute("IsSquatting") ~= true then
            set_status("going to squat")
            move_to(det.Position, 0.15)
            task.wait(0.2)
            fire("SquatTrainingRequest", det)
            task.wait(1.2)
            if plr:GetAttribute("IsSquatting") ~= true then
                move_to(det.Position, 0.15)
                task.wait(0.2)
                fire("SquatTrainingRequest", det)
                task.wait(1.2)
            end
            if steal_pick and fossil_work and ((auto_steal and steal_pick()) or (fossil_on and map:GetAttribute("FossilEventActive") == true and fossil_work())) then
                fire("StopSquattingRequest")
                task.wait(0.5)
                continue
            end
        else
            set_status("squatting (" .. jpnow .. " jp)")
            if plr:GetAttribute("SquatBonusAvailable") == true then
                local bv = tonumber(plr:GetAttribute("SquatBonusVersion")) or 0
                fire("SquatBonusRequest", math.floor(bv))
            end
            click_bonus()
            task.wait(0.2)
        end
        task.wait(0.4)
    end
end)

local s3b = t3:section({ name = "pets" })
library.button(s3b, { name = "equip best pets", callback = function()
    fire("PetInventory", "EquipBest")
    notify("equip best sent", 3)
end })

local best_on = false

library.toggle(s3b, { name = "auto equip best pets", default = false, callback = function(v)
    best_on = v
    if best_on then
        task.spawn(function()
            while best_on and alive() do
                fire("PetInventory", "EquipBest")
                task.wait(20)
            end
        end)
    end
end })

end

do

local s4 = t4:section({ name = "rewards" })

library.toggle(s4, { name = "auto claim offline cash", default = false, callback = function(v)
    local on = v
    if on then
        task.spawn(function()
            while on and alive() do
                fire("OfflineRewards", "Claim")
                task.wait(15)
            end
        end)
    end
end })

library.toggle(s4, { name = "auto claim index rewards", default = false, callback = function(v)
    local on = v
    if on then
        task.spawn(function()
            while on and alive() do
                fire("ClaimAnimalIndexReward", "__ALL__")
                task.wait(30)
            end
        end)
    end
end })

library.toggle(s4, { name = "auto claim group reward", default = false, callback = function(v)
    local on = v
    if on then
        task.spawn(function()
            while on and alive() do
                fire("GroupReward", "Claim")
                task.wait(60)
            end
        end)
    end
end })

local code_in = ""

library.textbox(s4, { placeholder = "redeem code", callback = function(v) code_in = v end })
library.button(s4, { name = "redeem code", callback = function()
    if code_in == "" then return end
    fire("Codes", "Redeem", code_in)
    notify("code sent", 3)
end })

local trail_sel = ""

library.button(t4, { name = "equip owned trail", callback = function()
    fire("Trails", "Select", trail_sel ~= "" and trail_sel or "Default")
end })

end

do

local s5 = t5:section({ name = "character" })

local walkspeed_on = false
local walkspeed_val = 16

library.toggle(s5, { name = "walkspeed override", default = false, callback = function(v) walkspeed_on = v end })
library.slider(s5, { name = "walkspeed", min = 16, max = 300, default = 16, callback = function(v) walkspeed_val = v end })

local jumppower_on = false
local jumppower_val = 50

library.toggle(s5, { name = "jump power override", default = false, callback = function(v) jumppower_on = v end })
library.slider(s5, { name = "jump power", min = 50, max = 500, default = 50, callback = function(v) jumppower_val = v end })

local infjump = false
uis.JumpRequest:Connect(function()
    if infjump and alive() then
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

library.toggle(s5, { name = "infinite jump", default = false, callback = function(v) infjump = v end })

local noclip = false

library.toggle(s5, { name = "noclip", default = false, callback = function(v) noclip = v end })

run.Stepped:Connect(function()
    if not alive() then return end
    local char = plr.Character
    if not char then return end
    if noclip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if walkspeed_on and hum.WalkSpeed ~= walkspeed_val then hum.WalkSpeed = walkspeed_val end
        if jumppower_on then
            hum.UseJumpPower = true
            if hum.JumpPower ~= jumppower_val then hum.JumpPower = jumppower_val end
        end
    end
end)

local s5b = t5:section({ name = "teleports" })

library.button(s5b, { name = "go to my plot", callback = function()
    task.spawn(function()
        local p = plot_spawn()
        if p then move_to(p, 0.2) end
    end)
end })

library.button(s5b, { name = "go to start", callback = function()
    task.spawn(function()
        local p = start_pos()
        if p then move_to(p, 0.2) end
    end)
end })

library.button(s5b, { name = "go to nearest egg", callback = function()
    task.spawn(function()
        local rec = steal_pick()
        if rec then move_to(rec.root.Position, 0.2) end
    end)
end })

library.button(s5b, { name = "go to squat zone", callback = function()
    task.spawn(function()
        local plot = my_plot()
        local det = plot and plot.SquatZone and plot.SquatZone.Floor and plot.SquatZone.Floor:FindFirstChild("Detector")
        if det then move_to(det.Position, 0.2) end
    end)
end })

end

do

local s6 = t6:section({ name = "eggs" })

local tr_from = "bottom center"
local tr_to = "humanoid root part"

local function screen_anchor(c)
    local vpc = c.ViewportSize
    if tr_from == "top center" then return Vector2.new(vpc.X / 2, 0) end
    if tr_from == "bottom left" then return Vector2.new(0, vpc.Y) end
    if tr_from == "bottom right" then return Vector2.new(vpc.X, vpc.Y) end
    if tr_from == "top left" then return Vector2.new(0, 0) end
    if tr_from == "top right" then return Vector2.new(vpc.X, 0) end
    return Vector2.new(vpc.X / 2, vpc.Y)
end

local egg_esp = false
local egg_esp_min = 0
local egg_tracers = false
local egg_draws = {}
local egg_lines = {}

run.RenderStepped:Connect(function()
    if not alive() then return end
    if not egg_esp and not egg_tracers then
        for _, d in pairs(egg_draws) do d.Visible = false end
        for _, l in pairs(egg_lines) do l.Visible = false end
        return
    end
    local cam = ws.CurrentCamera
    if not cam or not cam.Parent then return end
    local drawn = {}
    local spt = screen_anchor(cam)
    for _, rec in ipairs(field_eggs()) do
        local rank = rarity_rank[rec.rarity] or 1
        if rank >= egg_esp_min then
            local vp, vis = cam:WorldToViewportPoint(rec.root.Position)
            local key = rec.root:GetDebugId()
            drawn[key] = true
            if vis then
                local col = rarity_color[rec.rarity] or Color3.new(1, 1, 1)
                if egg_tracers and spt then
                    local l = egg_lines[key]
                    if not l then
                        l = Drawing.new("Line")
                        l.Thickness = 1.5
                        egg_lines[key] = l
                    end
                    l.From = spt
                    l.To = Vector2.new(vp.X, vp.Y)
                    l.Color = col
                    l.Visible = true
                end
                local d = egg_draws[key]
                if not d then
                    d = Drawing.new("Text")
                    d.Size = 13
                    d.Center = true
                    d.Outline = true
                    d.Font = 2
                    egg_draws[key] = d
                end
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                local dist = hrp and math.floor((hrp.Position - rec.root.Position).Magnitude) or 0
                d.Text = rec.species .. " [" .. rec.rarity .. "] " .. dist .. "m"
                d.Color = col
                d.Position = Vector2.new(vp.X, vp.Y)
                d.Visible = egg_esp
            else
                if egg_draws[key] then egg_draws[key].Visible = false end
                if egg_lines[key] then egg_lines[key].Visible = false end
            end
        end
    end
    for key, d in pairs(egg_draws) do
        if not drawn[key] then d.Visible = false end
    end
    for key, l in pairs(egg_lines) do
        if not drawn[key] then l.Visible = false end
    end
end)

library.toggle(s6, { name = "egg esp", default = false, callback = function(v) egg_esp = v end })
library.toggle(s6, { name = "egg tracers", default = false, callback = function(v) egg_tracers = v end })
library.dropdown(s6, { name = "egg esp min rarity", options = {"any", unpack(rarity_list)}, default = "any", callback = function(v)
    egg_esp_min = v == "any" and 0 or (rarity_rank[v] or 0)
end })

local s6b = t6:section({ name = "players" })

local plr_esp = false
local plr_tracers = false
local plr_draws = {}
local plr_lines = {}

local function anchor_of(p)
    local ch = p.Character
    if not ch then return nil end
    if tr_to == "head" then
        local h = ch:FindFirstChild("Head")
        if h then return h end
    elseif tr_to == "left hand" then
        local h = ch:FindFirstChild("LeftHand") or ch:FindFirstChild("Left Arm")
        if h then return h end
    elseif tr_to == "right hand" then
        local h = ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm")
        if h then return h end
    elseif tr_to == "torso" then
        local h = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
        if h then return h end
    end
    return ch:FindFirstChild("HumanoidRootPart")
end

run.RenderStepped:Connect(function()
    if not alive() then return end
    local c = ws.CurrentCamera
    if not plr_esp then
        for _, d in pairs(plr_draws) do d.Visible = false end
    end
    if not plr_tracers or not c or not c.Parent then
        for _, t in pairs(plr_lines) do t.Visible = false end
        return
    end
    local drawn = {}
    local spt = screen_anchor(c)
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= plr then
            local a = anchor_of(p)
            if a then
                local vp = c:WorldToViewportPoint(a.Position)
                local key = p.UserId
                drawn[key] = true
                if typeof(vp) == "Vector3" and vp.Z > 0 then
                    local l = plr_lines[key]
                    if not l then
                        l = Drawing.new("Line")
                        l.Thickness = 1.5
                        l.Color = Color3.new(0.4, 0.7, 1)
                        plr_lines[key] = l
                    end
                    l.From = spt
                    l.To = Vector2.new(vp.X, vp.Y)
                    l.Visible = true
                else
                    if plr_lines[key] then plr_lines[key].Visible = false end
                end
                if plr_esp and typeof(vp) == "Vector3" and vp.Z > 0 then
                    local d = plr_draws[key]
                    if not d then
                        d = Drawing.new("Text")
                        d.Size = 13
                        d.Center = true
                        d.Outline = true
                        d.Font = 2
                        plr_draws[key] = d
                    end
                    local carry = (tonumber(p:GetAttribute("CarriedEggCount")) or 0) > 0
                    d.Text = p.Name .. " [" .. math.floor((c.CFrame.Position - a.Position).Magnitude) .. "]" .. (carry and " CARRYING" or "")
                    d.Color = carry and Color3.new(1, 0.3, 0.3) or Color3.new(0.4, 0.7, 1)
                    d.Position = Vector2.new(vp.X, vp.Y)
                    d.Visible = true
                end
            end
        end
    end
    for key, d in pairs(plr_draws) do
        if not drawn[key] then d.Visible = false end
    end
    for key, l in pairs(plr_lines) do
        if not drawn[key] then l.Visible = false end
    end
end)

library.toggle(s6b, { name = "player esp", default = false, callback = function(v) plr_esp = v end })
library.toggle(s6b, { name = "player tracers", default = false, callback = function(v) plr_tracers = v end })
library.toggle(s6b, { name = "tracer start", options = {"bottom center", "top center", "bottom left", "bottom right", "top left", "top right"}, default = "bottom center", callback = function(v) tr_from = v end })
library.dropdown(s6b, { name = "tracer end", options = {"humanoid root part", "head", "torso", "left hand", "right hand"}, default = "humanoid root part", callback = function(v) tr_to = v end })

do

local s6g = t6:section({ name = "guards" })

local guard_esp = false
local guard_tracers = false
local guard_draws = {}
local guard_lines = {}

local function guard_anchor(g)
    local hum = g:FindFirstChildOfClass("Humanoid")
    if hum and hum.RootPart then return hum.RootPart end
    local h = g:FindFirstChild("Head") or g:FindFirstChild("HumanoidRootPart")
    if h then return h end
    return g:FindFirstChildWhichIsA("BasePart", true)
end

run.RenderStepped:Connect(function()
    if not alive() then return end
    local c = ws.CurrentCamera
    if not guard_esp and not guard_tracers then
        for _, d in pairs(guard_draws) do d.Visible = false end
        for _, l in pairs(guard_lines) do l.Visible = false end
        return
    end
    if not c or not c.Parent then return end
    local cg = map:FindFirstChild("ClientGuards")
    local drawn = {}
    local spt = screen_anchor(c)
    if cg then
        for _, g in ipairs(cg:GetChildren()) do
            if g:IsA("Model") then
                local a = guard_anchor(g)
                if a then
                    local vp = c:WorldToViewportPoint(a.Position)
                    local key = g:GetDebugId()
                    drawn[key] = true
                    if typeof(vp) == "Vector3" and vp.Z > 0 then
                        if guard_tracers then
                            local l = guard_lines[key]
                            if not l then
                                l = Drawing.new("Line")
                                l.Thickness = 1.5
                                l.Color = Color3.new(1, 0.55, 0.2)
                                guard_lines[key] = l
                            end
                            l.From = spt
                            l.To = Vector2.new(vp.X, vp.Y)
                            l.Visible = true
                        end
                        if guard_esp then
                            local d = guard_draws[key]
                            if not d then
                                d = Drawing.new("Text")
                                d.Size = 13
                                d.Center = true
                                d.Outline = true
                                d.Font = 2
                                d.Color = Color3.new(1, 0.55, 0.2)
                                guard_draws[key] = d
                            end
                            d.Text = "guard " .. g.Name .. " [" .. math.floor((c.CFrame.Position - a.Position).Magnitude) .. "]"
                            d.Position = Vector2.new(vp.X, vp.Y)
                            d.Visible = true
                        end
                    else
                        if guard_draws[key] then guard_draws[key].Visible = false end
                        if guard_lines[key] then guard_lines[key].Visible = false end
                    end
                end
            end
        end
    end
    for key, d in pairs(guard_draws) do
        if not drawn[key] then d.Visible = false end
    end
    for key, l in pairs(guard_lines) do
        if not drawn[key] then l.Visible = false end
    end
end)

library.toggle(s6g, { name = "guard esp", default = false, callback = function(v) guard_esp = v end })
library.toggle(s6g, { name = "guard tracers", default = false, callback = function(v) guard_tracers = v end })

end

do

local s6f = t6:section({ name = "fossils" })

local fossil_esp = false
local fossil_tracers = false
local frag_esp = false
local fossil_draws = {}
local fossil_lines = {}

local function fossil_color(size)
    if size == "Mythical" then return Color3.fromRGB(255, 80, 220) end
    if size == "Ancient" then return Color3.fromRGB(120, 220, 255) end
    if size == "Rare" then return Color3.fromRGB(255, 170, 40) end
    if size == "Large" then return Color3.fromRGB(200, 120, 80) end
    return Color3.fromRGB(235, 220, 170)
end

run.RenderStepped:Connect(function()
    if not alive() then return end
    local c = ws.CurrentCamera
    if not fossil_esp and not fossil_tracers and not frag_esp then
        for _, d in pairs(fossil_draws) do d.Visible = false end
        for _, l in pairs(fossil_lines) do l.Visible = false end
        return
    end
    if not c or not c.Parent then return end
    local drawn = {}
    local spt = screen_anchor(c)
    for _, st in ipairs(stages:GetChildren()) do
        local sf = st:FindFirstChild("SpawnedFossils")
        if sf then
            for _, f in ipairs(sf:GetChildren()) do
                local carriedby = tonumber(f:GetAttribute("CarriedByUserId")) or 0
                if carriedby == 0 then
                    local a = f:FindFirstChild("Stand") or f:FindFirstChildWhichIsA("BasePart", true)
                    if a then
                        local vp = c:WorldToViewportPoint(a.Position)
                        local key = f:GetDebugId()
                        drawn[key] = true
                        if typeof(vp) == "Vector3" and vp.Z > 0 then
                            local col = fossil_color(f:GetAttribute("Size"))
                            if fossil_tracers then
                                local l = fossil_lines[key]
                                if not l then
                                    l = Drawing.new("Line")
                                    l.Thickness = 1.5
                                    fossil_lines[key] = l
                                end
                                l.From = spt
                                l.To = Vector2.new(vp.X, vp.Y)
                                l.Color = col
                                l.Visible = true
                            end
                            if frag_esp then
                                local fk = key .. "_f"
                                drawn[fk] = true
                                local fd = fossil_draws[fk]
                                if not fd then
                                    fd = Drawing.new("Text")
                                    fd.Size = 13
                                    fd.Center = true
                                    fd.Outline = true
                                    fd.Font = 2
                                    fd.Color = Color3.fromRGB(200, 120, 255)
                                    fossil_draws[fk] = fd
                                end
                                fd.Text = tostring(tonumber(f:GetAttribute("Fragments")) or 0) .. " frags"
                                fd.Position = Vector2.new(vp.X, vp.Y)
                                fd.Visible = true
                            end
                            if fossil_esp then
                                local d = fossil_draws[key]
                                if not d then
                                    d = Drawing.new("Text")
                                    d.Size = 13
                                    d.Center = true
                                    d.Outline = true
                                    d.Font = 2
                                    fossil_draws[key] = d
                                end
                                local dist = math.floor((c.CFrame.Position - a.Position).Magnitude)
                                d.Text = tostring(f:GetAttribute("FossilName") or f.Name) .. " [" .. tostring(f:GetAttribute("FossilSize") or "?") .. "] " .. dist .. "m"
                                if frag_esp then
                                    d.Text = d.Text .. " (" .. tostring(tonumber(f:GetAttribute("Fragments")) or 0) .. " frags)"
                                    d.Position = Vector2.new(vp.X, vp.Y + 14)
                                else
                                    d.Position = Vector2.new(vp.X, vp.Y)
                                end
                                d.Color = col
                                d.Visible = true
                            end
                        else
                            if fossil_draws[key] then fossil_draws[key].Visible = false end
                            if fossil_lines[key] then fossil_lines[key].Visible = false end
                        end
                    end
                end
            end
        end
    end
    for key, d in pairs(fossil_draws) do
        if not drawn[key] then d.Visible = false end
    end
    for key, l in pairs(fossil_lines) do
        if not drawn[key] then l.Visible = false end
    end
end)

library.toggle(s6f, { name = "fossil esp", default = false, callback = function(v) fossil_esp = v end })
library.toggle(s6f, { name = "fossil tracers", default = false, callback = function(v) fossil_tracers = v end })
library.toggle(s6f, { name = "fragment esp", default = false, callback = function(v) frag_esp = v end })

local buy_egg = false

library.toggle(s6f, { name = "auto buy fragment egg", default = false, callback = function(v)
    buy_egg = v
    if buy_egg then
        task.spawn(function()
            while buy_egg and alive() do
                local ok, err = pcall(function()
                    local fe = map:FindFirstChild("FossilEvent")
                    local es = fe and fe:FindFirstChild("EggStand")
                    local bp = es and es:FindFirstChild("BuyPrompt", true)
                    if not bp or not bp.Enabled then
                        set_status("egg stand - unavailable")
                        task.wait(3)
                        return
                    end
                    local cost = tonumber(string.match(tostring(bp.ObjectText), "(%d[%d%.]*)")) or 0
                    local frags = plr:FindFirstChild("Fragments")
                    local have = frags and tonumber(frags.Value) or 0
                    local at = bp.Parent and bp.Parent:IsA("Attachment") and bp.Parent.WorldPosition or (es:FindFirstChild("Prompt", true) and es.Prompt.Position)
                    if not at then task.wait(2) return end
                    if have < cost then
                        set_status("egg stand - need " .. (cost - have) .. " more frags")
                        task.wait(4)
                        return
                    end
                    set_status("buying fossiled egg (" .. cost .. " frags)")
                    for _ = 1, 3 do
                        move_to(at, 0.05)
                        pcall(function() fireproximityprompt(bp) end)
                        local t0 = os.clock()
                        local f2 = plr:FindFirstChild("Fragments")
                        while f2 and tonumber(f2.Value) == have and os.clock() - t0 < 1 do
                            task.wait(0.05)
                        end
                        if f2 and tonumber(f2.Value) < have then break end
                    end
                end)
                if not ok then
                    set_status("buy egg err")
                    notify("buy egg error: " .. tostring(err), 3)
                    task.wait(1)
                end
                task.wait(2)
            end
        end)
    end
end })

end

local s6c = t6:section({ name = "client" })

library.toggle(s6c, { name = "fullbright", default = false, callback = function(v)
    if v then
        light.Brightness = 3
        light.ClockTime = 14
        light.FogEnd = 100000
        light.GlobalShadows = false
        light.Ambient = Color3.new(1, 1, 1)
    else
        light.Brightness = 1
        light.GlobalShadows = true
        light.Ambient = Color3.new(0, 0, 0)
    end
end })

local fps_conn

library.toggle(s6c, { name = "ultra performance", default = false, callback = function(v)
    if v then
        for _, d in pairs(ws:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Material = Enum.Material.SmoothPlastic
                d.Reflectance = 0
            elseif d:IsA("Decal") or d:IsA("Texture") then
                d.Transparency = 1
            elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") then
                d.Enabled = false
            end
        end
        fps_conn = ws.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then
                d.Material = Enum.Material.SmoothPlastic
                d.Reflectance = 0
            elseif d:IsA("Decal") or d:IsA("Texture") then
                d.Transparency = 1
            elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") then
                d.Enabled = false
            end
        end)
    else
        if fps_conn then fps_conn:Disconnect() end
    end
end })

end

do

local s7 = t7:section({ name = "misc" })

local hud_on = false
local hud_tl = nil

library.toggle(s7, { name = "status hud", default = false, callback = function(v)
    hud_on = v
    if not v then
        if hud_tl then hud_tl:Destroy() end
        hud_tl = nil
    end
end })

run.RenderStepped:Connect(function()
    if not hud_on or not alive() then return end
    if not hud_tl or not hud_tl.Parent then
        local root = library.gui
        if not root or not root.Parent then return end
        hud_tl = Instance.new("TextLabel")
        hud_tl.Name = "lx_jfa_hud"
        hud_tl.Size = UDim2.new(0, 540, 0, 22)
        hud_tl.Position = UDim2.new(0.5, -270, 0, -30)
        hud_tl.BackgroundColor3 = Color3.new(0, 0, 0)
        hud_tl.BackgroundTransparency = 0.45
        hud_tl.BorderSizePixel = 0
        hud_tl.TextColor3 = Color3.new(1, 1, 1)
        hud_tl.Font = Enum.Font.Gotham
        hud_tl.TextSize = 13
        hud_tl.Text = ""
        hud_tl.Visible = true
        hud_tl.Parent = root
    end
    hud_tl.Visible = true
    local jp = plr:FindFirstChild("JumpPower")
    local carry = carry_count() .. "/" .. carry_cap()
    hud_tl.Text = (carrying() and "CARRYING " .. carry .. " | " or "") .. (steal_status ~= "" and (steal_status .. " | ") or "") .. "jp " .. tostring(jp and jp.Value or "?")
end)

library.toggle(s7, { name = "anti afk", default = false, callback = function(v)
    local on = v
    plr.Idled:Connect(function()
        if on then
            local v2 = Instance.new("VirtualInputManager")
            v2:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait()
            v2:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end)
end })

library.button(s7, { name = "rejoin", callback = function()
    tps:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end })

library.button(s7, { name = "server hop", callback = function()
    local ok, r = pcall(function()
        return hs:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
    end)
    if not ok or not r.data then return end
    for _, s in ipairs(r.data) do
        if s.id ~= game.JobId and s.playing < s.maxPlayers then
            tps:TeleportToPlaceInstance(game.PlaceId, s.id, plr)
            return
        end
    end
end })

library.button(s7, { name = "copy job id", callback = function()
    setclipboard(game.JobId)
end })

end