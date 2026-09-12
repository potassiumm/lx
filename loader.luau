if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("! main load")

local base = 'https://raw.githubusercontent.com/potassiumm/lx/main/games/'

local games = {
    [1848960] = 'mm2.luau',
    [892039974] = 'deagle-arena.luau',
    [1047647644] = 'one-tap.luau',
    [2613928] = 'arsenal.luau',
    [4619164] = 'sell-lemons.luau',
    [7507335] = 'spelling-bee.luau', -- bsb
    [33556221] = 'spelling-bee.luau', -- ssb
    [16812202] = 'spelling-bee.luau', -- fsb
    [358916245] = 'spelling-bee.luau', -- csb
    [2682905822] = 'spelling-bee.luau', -- xzsb
    [783008896] = 'jump-to-steal.luau',
}

local cid = game.CreatorId
print(cid)
local file = games[cid]
if not file then warn("! unsupported game") return end
print("! "..file)
loadstring(game:HttpGet(base .. file))()
task.wait(0.125)
print("! .gg/s5TcXmE74k")
