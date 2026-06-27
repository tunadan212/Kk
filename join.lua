local HS      = game:GetService("HttpService")
local TS      = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local RunSvc  = game:GetService("RunService")
local LP      = Players.LocalPlayer

local SEA_PLACE = {["1"]=2753915549,["2"]=4442272183,["3"]=7449423635}
local SEA_MAP   = {
    [2753915549]="1",[4442272183]="2",[79091703265657]="2",
    [7449423635]="3",[11456555699]="3",
}

local STATE_FILE = "bfj_state.json"

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
    if writefile then pcall(writefile, STATE_FILE, "{}") end
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

saveState(state)

print(string.format("[BFJ] Sea hiện tại: %s | Target: Sea %s", CURRENT_SEA, TARGET_SEA))
print(string.format("[BFJ] JobId: %s", TARGET_JOB ~= "" and TARGET_JOB:sub(1,8).."..." or "none"))

local function selectPirates()
    print("[BFJ] Selecting Pirates...")
    task.wait(3)
    local rem    = RS:FindFirstChild("Remotes")
    local CommF_ = rem and rem:FindFirstChild("CommF_")
    if CommF_ then
        for _, name in ipairs({"SelectTeam","ChooseSide","SetTeam","JoinTeam","SelectFaction"}) do
            pcall(function() CommF_:InvokeServer(name, "Pirates") end)
            task.wait(0.3)
        end
    end
    local function clickBtn()
        local ok, gui = pcall(function() return LP:WaitForChild("PlayerGui", 5) end)
        if not ok or not gui then return false end
        for _, obj in ipairs(gui:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                if (obj.Text or ""):lower():find("pirate") then
                    pcall(function() obj.MouseButton1Click:Fire() end)
                    pcall(function() obj:Activate() end)
                    print("[BFJ] Clicked Pirates:", obj.Name)
                    return true
                end
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
    print("[BFJ] Tween đến cafe Sea 2...")
    task.wait(2)
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local cafePos = Vector3.new(-380.42, 71.67, 258.81)
    local arrived = false
    local conn
    conn = RunSvc.Heartbeat:Connect(function()
        local c = LP.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then conn:Disconnect(); return end
        local dist = (h.Position - cafePos).Magnitude
        if dist < 5 then arrived = true; conn:Disconnect(); return end
        pcall(function() h.CFrame = h.CFrame:Lerp(CFrame.new(cafePos), 0.15) end)
    end)
    local t = 0
    while not arrived and t < 25 do task.wait(0.1); t += 0.1 end
    pcall(function() conn:Disconnect() end)
    print("[BFJ] Cafe arrived:", arrived)
end

local function navigateSea3()
    print("[BFJ] Teleport vào MapTeleportA (Boat Castle → Mansion)...")
    task.wait(2)

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")

    local hitbox = workspace.Map["Boat Castle"].MapTeleportA.Hitbox
    local pos    = hitbox.Position

    print("[BFJ] Hitbox pos:", pos)

    pcall(function()
        hrp.Anchored = true
        hrp.CFrame   = CFrame.new(pos)
    end)

    local frame = 0
    local conn
    conn = RunSvc.Heartbeat:Connect(function()
        frame += 1
        if frame > 180 then
            conn:Disconnect()
            pcall(function() hrp.Anchored = false end)
            print("[BFJ] Castle teleport done ✅")
            return
        end
        pcall(function() hrp.CFrame = CFrame.new(pos) end)
    end)
end

local function doTeleport(placeId, jobId)
    if jobId and jobId ~= "" then
        local ok, err = pcall(function()
            TS:TeleportToPlaceInstance(placeId, jobId, LP)
        end)
        if ok then return end
        warn("[BFJ] TeleportToPlaceInstance fail:", err)
    end
    local ok, err = pcall(function() TS:Teleport(placeId, LP) end)
    if not ok then warn("[BFJ] Teleport fail:", err) end
end

task.spawn(function()
    task.wait(1)

    if CURRENT_SEA == TARGET_SEA then
        if TARGET_JOB ~= "" and CURRENT_JOB ~= TARGET_JOB then
            print("[BFJ] Đúng sea! Joining server:", TARGET_JOB:sub(1,8).."...")
            doTeleport(SEA_PLACE[TARGET_SEA], TARGET_JOB)
        else
            print("[BFJ] Đúng server! Navigate...")
            selectPirates()
            task.wait(2)
            if TARGET_SEA == "2" then
                navigateSea2()
            elseif TARGET_SEA == "3" then
                navigateSea3()
            end
            clearState()
            print("[BFJ] Complete ✅")
        end
    else
        local cur      = tonumber(CURRENT_SEA) or 1
        local tgt      = tonumber(TARGET_SEA)  or 3
        local next     = cur + (tgt > cur and 1 or -1)
        local nextSea  = tostring(next)
        local nextPlace = SEA_PLACE[nextSea]

        print(string.format("[BFJ] Route: Sea%s → Sea%s → ... → Sea%s",
            CURRENT_SEA, nextSea, TARGET_SEA))

        if nextPlace then
            saveState(state)
            task.wait(1)
            doTeleport(nextPlace, "")
        else
            warn("[BFJ] Không có PlaceId cho Sea", nextSea)
        end
    end
end)
