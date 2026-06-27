local SCRIPT_URL = "https://raw.githubusercontent.com/tunadan212/Kk/refs/heads/main/join.lua"

local HS      = game:GetService("HttpService")
local TS      = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local RunSvc  = game:GetService("RunService")
local LP      = Players.LocalPlayer

local SEA_MAP = {
    [2753915549]      = "1",
    [4442272183]      = "2",
    [79091703265657]  = "2",
    [7449423635]      = "3",
    [11456555699]     = "3",
    [100117331123089] = "3",
}

local SEA_PLACE = {
    ["1"] = 2753915549,
    ["2"] = 4442272183,
    ["3"] = 100117331123089,
}

local TRAVEL_CMD = {
    ["1→2"] = "TravelDressrosa",
    ["2→1"] = "TravelDressrosa",
    ["2→3"] = "TravelZou",
    ["3→2"] = "TravelZou",
}

local STATE_FILE = "bfj_state.json"
local AUTOEXEC   = "autoexec/bfj_auto.lua"

local function saveState(data)
    if writefile then pcall(writefile, STATE_FILE, HS:JSONEncode(data)) end
end

local function loadState()
    if readfile then
        local ok, content = pcall(readfile, STATE_FILE)
        if ok and content and content ~= "" and content ~= "{}" then
            local ok2, data = pcall(function() return HS:JSONDecode(content) end)
            if ok2 and type(data) == "table" then return data end
        end
    end
    return {}
end

local function clearState()
    if writefile then
        pcall(writefile, STATE_FILE, "{}")
        pcall(writefile, AUTOEXEC, "")
    end
end

local function setupAutoExec()
    if not writefile then return end
    local code = string.format([[
task.wait(5)
local ok, d = pcall(readfile, "bfj_state.json")
if ok and d and d ~= "{}" and d ~= "" then
    pcall(function()
        loadstring(game:HttpGet("%s", true))()
    end)
end
]], SCRIPT_URL)
    pcall(writefile, AUTOEXEC, code)
    print("[BFJ] AutoExec ✅")
end

local state = loadState()
if getgenv().Sea      then state.Sea      = tostring(getgenv().Sea)      end
if getgenv().jobId    then state.jobId    = tostring(getgenv().jobId)    end
if getgenv().USERNAME then state.USERNAME = tostring(getgenv().USERNAME) end

local TARGET_SEA  = state.Sea      or "2"
local TARGET_JOB  = state.jobId    or ""
local USERNAME    = state.USERNAME or ""
local CURRENT_SEA = SEA_MAP[game.PlaceId] or "1"
local CURRENT_JOB = game.JobId

print("[BFJ] PlaceId:", game.PlaceId)
print("[BFJ] Sea:", CURRENT_SEA, "→ Target Sea:", TARGET_SEA)
print("[BFJ] JobId:", TARGET_JOB ~= "" and TARGET_JOB or "NONE")

local CommF_ = RS:WaitForChild("Remotes"):WaitForChild("CommF_")

local function selectPirates()
    task.wait(3)
    for _, n in ipairs({"SelectTeam","ChooseSide","SetTeam","SelectFaction"}) do
        pcall(function() CommF_:InvokeServer(n, "Pirates") end)
        task.wait(0.3)
    end
    local function clickBtn()
        local ok, gui = pcall(function() return LP:WaitForChild("PlayerGui", 5) end)
        if not ok then return false end
        for _, obj in ipairs(gui:GetDescendants()) do
            if (obj:IsA("TextButton") or obj:IsA("ImageButton"))
            and (obj.Text or ""):lower():find("pirate") then
                pcall(function() obj.MouseButton1Click:Fire() end)
                print("[BFJ] Pirates clicked:", obj.Name)
                return true
            end
        end
        return false
    end
    for _ = 1, 10 do
        if clickBtn() then break end
        task.wait(1)
    end
    print("[BFJ] Pirates done")
end

local function navigateSea2()
    task.wait(2)
    print("[BFJ] Tween cafe Sea 2...")
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local dest = Vector3.new(-380.42, 71.67, 258.81)
    local done = false
    local conn
    conn = RunSvc.Heartbeat:Connect(function()
        local c = LP.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then conn:Disconnect(); return end
        if (h.Position - dest).Magnitude < 5 then done = true; conn:Disconnect(); return end
        pcall(function() h.CFrame = h.CFrame:Lerp(CFrame.new(dest), 0.15) end)
    end)
    local t = 0
    while not done and t < 25 do task.wait(0.1); t += 0.1 end
    pcall(function() conn:Disconnect() end)
    print("[BFJ] Cafe:", done)
end

local function navigateSea3()
    task.wait(2)
    print("[BFJ] Teleport MapTeleportA...")
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local ok, hitbox = pcall(function()
        return workspace.Map["Boat Castle"].MapTeleportA.Hitbox
    end)
    if not ok or not hitbox then
        warn("[BFJ] MapTeleportA.Hitbox không tìm thấy!")
        return
    end
    local pos = hitbox.Position
    print("[BFJ] Hitbox:", pos)
    pcall(function() hrp.Anchored = true; hrp.CFrame = CFrame.new(pos) end)
    local frame = 0
    local conn
    conn = RunSvc.Heartbeat:Connect(function()
        frame += 1
        if frame > 180 then
            conn:Disconnect()
            pcall(function() hrp.Anchored = false end)
            print("[BFJ] Triggered ✅")
            return
        end
        pcall(function() hrp.CFrame = CFrame.new(pos) end)
    end)
end

local function joinJobId(targetSea, targetJob)
    local placeId = SEA_PLACE[targetSea]
    if not placeId then warn("[BFJ] Không có PlaceId cho Sea", targetSea); return false end

    print(string.format("[BFJ] Join jobId: %s (Sea%s)...", targetJob:sub(1,8).."...", targetSea))
    local ok, err = pcall(function()
        TS:TeleportToPlaceInstance(placeId, targetJob, LP)
    end)
    if ok then
        print("[BFJ] TeleportToPlaceInstance ✅")
        return true
    end
    warn("[BFJ] TeleportToPlaceInstance fail:", err)
    return false
end

local function travelSea(currentSea, targetSea)
    local cur  = tonumber(currentSea) or 1
    local tgt  = tonumber(targetSea)  or 3
    local next = tostring(cur + (tgt > cur and 1 or -1))
    local key  = currentSea.."→"..next
    local cmd  = TRAVEL_CMD[key]
    if not cmd then warn("[BFJ] Không có travel cmd:", key); return end
    print(string.format("[BFJ] Travel Sea%s → Sea%s | %s", currentSea, next, cmd))
    saveState(state)
    setupAutoExec()
    task.wait(1)
    local ok, err = pcall(function() CommF_:InvokeServer(cmd) end)
    print("[BFJ] Travel:", ok, err or "")
end

task.spawn(function()
    task.wait(1)

    if TARGET_SEA == "" then
        warn("[BFJ] Không có target sea!")
        return
    end

    -- CASE 1: Đúng sea + đúng server → navigate đến trade area
    if CURRENT_SEA == TARGET_SEA and (TARGET_JOB == "" or CURRENT_JOB == TARGET_JOB) then
        print("[BFJ] ✅ Đúng server! Navigate...")
        clearState()
        selectPirates()
        task.wait(2)
        if TARGET_SEA == "2" then
            navigateSea2()
        elseif TARGET_SEA == "3" then
            navigateSea3()
        end
        return
    end

    -- CASE 2: Đúng sea, sai server → join thẳng jobId
    if CURRENT_SEA == TARGET_SEA and TARGET_JOB ~= "" and CURRENT_JOB ~= TARGET_JOB then
        print("[BFJ] Đúng sea, sai server → join jobId...")
        saveState(state)
        setupAutoExec()
        task.wait(1)
        joinJobId(TARGET_SEA, TARGET_JOB)
        return
    end

    -- CASE 3: Sai sea → travel tuần tự
    -- Sau khi travel xong, autoexec chạy lại:
    --   → nếu đúng sea rồi → join jobId (CASE 2)
    --   → nếu vẫn sai sea → travel tiếp (CASE 3)
    print("[BFJ] Sai sea → travel tuần tự...")
    travelSea(CURRENT_SEA, TARGET_SEA)
end)
