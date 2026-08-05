-- ===== SAFETY FALLBACK FOR table.clear =====
if not table.clear then
    function table.clear(t)
        for k in pairs(t) do
            t[k] = nil
        end
    end
end

_G.ScriptEnabled = true
_G.AutoWriteEnabled = false
_G.AutoSubmitEnabled = false
_G.RiddleSolverEnabled = false
_G.SubmitAfterCount = 1
_G.SubmitAttempts = 3

-- ========== ABSOLUTE MAXIMUM SPEED ==========
local FAST_WAIT = 0.000000000000000000000000000000000000000000000000000000000000000001
local MAX_SPEED = true

local enteredCodes = {}
local activeConnections = {}

local latestCode = nil
local lastWrittenCode = nil
local lastAttemptedCode = nil
local lastSubmittedBatch = {}
local autoWriteConn = nil

local pendingQueue = {}
local pendingSeen = {}
local writeBusy = false

local collectedCodes = {}
local collectedSeen = {}
local CODE_SEPARATOR = ""

local ScreenGui = nil
local MainFrame = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- ===== CONFIG PERSISTENCE =====
local CONFIG_PATH = "NexusHub_AutoCode_config.json"

local hasFS = (writefile and readfile and isfile) and true or false

local defaultConfig = {
    panelX = nil,
    panelY = nil,
}

local config = {}
for k, v in pairs(defaultConfig) do config[k] = v end

local function loadConfig()
    if not hasFS then return end
    if not isfile(CONFIG_PATH) then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_PATH))
    end)
    if ok and type(data) == "table" then
        for k in pairs(defaultConfig) do
            if data[k] ~= nil then config[k] = data[k] end
        end
    end
end

local pendingSave = false
local function saveConfig()
    if not hasFS then return end
    if pendingSave then return end
    pendingSave = true
    task.defer(function()
        pendingSave = false
        pcall(function()
            writefile(CONFIG_PATH, HttpService:JSONEncode(config))
        end)
    end)
end

loadConfig()

-- ===== COMPLETE STEAL A BRAINROT + SPYDERSAMMY DATABASE =====
local SAB_DB = {
    ["how old am i"] = "24",
    ["how old is sammy"] = "24",
    ["my age"] = "24",
    ["sammy age"] = "24",
    ["age"] = "24",
    ["where am i from"] = "BRAZIL",
    ["where is sammy from"] = "BRAZIL",
    ["my country"] = "BRAZIL",
    ["sammy country"] = "BRAZIL",
    ["favorite color"] = "BLUE",
    ["fav color"] = "BLUE",
    ["my color"] = "BLUE",
    ["sammy color"] = "BLUE",
    ["color"] = "BLUE",
    ["favorite football player"] = "RONALDO",
    ["fav football player"] = "RONALDO",
    ["my favorite football player"] = "RONALDO",
    ["ronaldo"] = "RONALDO",
    ["game created on"] = "FRIDAY",
    ["created on"] = "FRIDAY",
    ["what day was the game created"] = "FRIDAY",
    ["what day was sab created"] = "FRIDAY",
    ["game creation day"] = "FRIDAY",
    ["seventh mutation"] = "CURSED",
    ["7th mutation"] = "CURSED",
    ["eighth mutation"] = "DIVINE",
    ["8th mutation"] = "DIVINE",
    ["ninth mutation"] = "CYBER",
    ["9th mutation"] = "CYBER",
    ["tenth mutation"] = "PHANTOM",
    ["10th mutation"] = "PHANTOM",
    ["first machine"] = "RAINBOW MACHINE",
    ["1st machine"] = "RAINBOW MACHINE",
    ["second machine"] = "BUBBLEGUM MACHINE",
    ["2nd machine"] = "BUBBLEGUM MACHINE",
    ["third machine"] = "FUSE MACHINE",
    ["3rd machine"] = "FUSE MACHINE",
    ["fourth machine"] = "CRAFT MACHINE",
    ["4th machine"] = "CRAFT MACHINE",
    ["fifth machine"] = "WITCH FUSE",
    ["5th machine"] = "WITCH FUSE",
    ["sixth machine"] = "BRAINROT DEALER",
    ["6th machine"] = "BRAINROT DEALER",
    ["seventh machine"] = "BRAINROT TRADER",
    ["7th machine"] = "BRAINROT TRADER",
    ["eighth machine"] = "SANTA'S FUSE",
    ["8th machine"] = "SANTA'S FUSE",
    ["ninth machine"] = "SANTA'S SHOP",
    ["9th machine"] = "SANTA'S SHOP",
    ["tenth machine"] = "NEW YEAR'S MACHINE",
    ["10th machine"] = "NEW YEAR'S MACHINE",
    ["eleventh machine"] = "DUELS MACHINE",
    ["11th machine"] = "DUELS MACHINE",
    ["twelfth machine"] = "CUPID'S MACHINE",
    ["12th machine"] = "CUPID'S MACHINE",
    ["thirteenth machine"] = "TRADE MACHINE",
    ["13th machine"] = "TRADE MACHINE",
    ["fourteenth machine"] = "DIVINE FUSE",
    ["14th machine"] = "DIVINE FUSE",
    ["fifteenth machine"] = "EGG INCUBATOR",
    ["15th machine"] = "EGG INCUBATOR",
    ["sixteenth machine"] = "CYBER CRAFT MACHINE",
    ["16th machine"] = "CYBER CRAFT MACHINE",
    ["seventeenth machine"] = "SUMMER FUSE",
    ["17th machine"] = "SUMMER FUSE",
    ["eighteenth machine"] = "LOS TRADERS",
    ["18th machine"] = "LOS TRADERS",
    ["og brainrot cannot be obtained"] = "HEADLESS HORSEMAN",
    ["headless horseman"] = "HEADLESS HORSEMAN",
    ["first og added"] = "STRAWBERRYELEPHANT",
    ["1st og"] = "STRAWBERRYELEPHANT",
    ["second og added"] = "MEOWL",
    ["2nd og"] = "MEOWL",
    ["third og added"] = "SKIBIDITOILET",
    ["3rd og"] = "SKIBIDITOILET",
    ["fifth og added"] = "JOHNPORK",
    ["5th og"] = "JOHNPORK",
    ["highest rarity"] = "OG",
    ["fire represents"] = "DRAGON",
    ["fire stands for"] = "DRAGON",
    ["won the world cup"] = "ARGENTINA",
    ["world cup winner"] = "ARGENTINA",
    ["world cup"] = "ARGENTINA",
    ["worst game owner"] = "SECRETLOKII",
    ["most boring game owner"] = "SECRETLOKII",
    ["most boring game on roblox"] = "KEYBOARDESCAPE",
    ["spawned during admin abuse war"] = "RACOONINI JANDELINI",
    ["won the admin abuse war"] = "GROWAGARDEN",
    ["worst secret"] = "KARKERKARKURKUR",
    ["maximum server size"] = "EIGHT",
    ["max server size"] = "EIGHT",
    ["brother of hydra bunny"] = "CERBERUS",
    ["hydra bunny brother"] = "CERBERUS",
    ["release month"] = "MAY",
    ["release year"] = "2025",
    ["release date"] = "MAY162025",
    ["code 1"] = "SAB2024",
    ["code 2"] = "SAMMYGIFT",
    ["code 3"] = "BRAINROT",
    ["code 4"] = "SPYDER",
    ["code 5"] = "RELEASE",
    ["code 6"] = "MAY25",
    ["code 7"] = "BLUEBOY",
    ["code 8"] = "KEYBOARD",
    ["code 9"] = "ESCAPE",
    ["code 10"] = "RAINBOW",
    ["total codes"] = "247",
    ["active codes"] = "89",
    ["expired codes"] = "158",
    ["rare codes"] = "12",
    ["legendary codes"] = "3",
    ["mythic codes"] = "1",
}

-- ========== FETCH SPYDERSAMMY USERID ==========
local targetUserId = nil
task.spawn(function()
    local success, result = pcall(function()
        return Players:GetUserIdFromNameAsync("SpyderSammy")
    end)
    if success then
        targetUserId = result
        print("[Auto Code] SpyderSammy UserID: " .. tostring(targetUserId))
    else
        warn("[Auto Code] Failed to fetch SpyderSammy UserID: " .. tostring(result))
    end
end)

-- ========== SPYDERSAMMY UI SCANNER ==========
local function isAvatarImage(imageLabel)
    if not imageLabel.Visible or imageLabel.Image == "" then return false end
    local imgStr = string.lower(imageLabel.Image)
    if targetUserId and string.find(imgStr, tostring(targetUserId)) then
        return true
    end
    return false
end

local function verifySourceIsSammy(textObj)
    if textObj:IsDescendantOf(MainFrame) then return false end

    local container = textObj.Parent
    while container and not container:IsA("ScreenGui") and container.Name ~= "PlayerGui" do
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("TextLabel") and string.find(string.lower(item.Text), "spydersammy") then
                return true
            end
        end
        for _, item in ipairs(container:GetDescendants()) do
            if item:IsA("ImageLabel") and isAvatarImage(item) then
                return true
            end
        end
        if container.Parent and (container.Parent:IsA("Frame") or container.Parent:IsA("ImageLabel") or container.Parent:IsA("CanvasGroup")) then
            container = container.Parent
        else
            break
        end
    end
    return false
end

-- ========== ANSWER QUESTION - RIDDLE SOLVER ==========
local function answerQuestion(text)
    if not _G.RiddleSolverEnabled then return nil end
    if not text or text == "" then return nil end
    local l = text:lower()

    local clean = l:gsub("what%s+is", ""):gsub("what%s+are", ""):gsub("what%s+was", ""):gsub("what%s+were", "")
    clean = clean:gsub("who%s+is", ""):gsub("who%s+was", ""):gsub("when%s+is", ""):gsub("when%s+was", "")
    clean = clean:gsub("where%s+is", ""):gsub("where%s+are", ""):gsub("how%s+old", ""):gsub("how%s+tall", "")
    clean = clean:gsub("how%s+many", ""):gsub("how%s+much", ""):gsub("do%s+you%s+know", ""):gsub("can%s+you%s+tell", "")
    clean = clean:gsub("tell%s+me", ""):gsub("i%s+need", ""):gsub("give%s+me", ""):gsub("what's", ""):gsub("whats", "")
    clean = clean:gsub("my%s+", ""):gsub("am%s+i", ""):gsub("do%s+i", ""):gsub("did%s+i", ""):gsub("have%s+i", "")
    clean = clean:gsub("the%s+", ""):gsub("a%s+", ""):gsub("an%s+", ""):gsub("of%s+", ""):gsub("for%s+", "")
    clean = clean:gsub("[%?%.%,!]", ""):gsub("^%s+", ""):gsub("%s+$", "")

    if clean == "" then
        clean = l:gsub("[%?%.%,!]", "")
    end

    if l:find("fortnite") or l:find("fn ") or l:find("battle royale") or l:find("epic games") then
        return "SAB ONLY"
    end

    if SAB_DB[clean] then
        return SAB_DB[clean]
    end

    for key, value in pairs(SAB_DB) do
        if clean:find(key) or key:find(clean) then
            return value
        end
        if #key > 3 and #clean > 2 then
            for word in key:gmatch("%S+") do
                if #word > 2 and (clean:find(word) or word:find(clean)) then
                    return value
                end
            end
        end
    end

    if l:find("game created") or l:find("created on") or l:find("made on") then
        if l:find("day") or l:find("when") then return "FRIDAY" end
    end
    if l:find("football") or l:find("soccer") then
        if l:find("favorite") or l:find("fav") or l:find("player") then return "RONALDO" end
    end
    if l:find("ronaldo") then return "RONALDO" end
    if l:find("worst game") or l:find("boring game") then
        if l:find("owner") then return "SECRETLOKII" else return "KEYBOARDESCAPE" end
    end
    if l:find("world cup") then return "ARGENTINA" end
    if l:find("mutation") then
        if l:find("7") or l:find("seven") then return "CURSED" end
        if l:find("8") or l:find("eight") then return "DIVINE" end
        if l:find("9") or l:find("nine") then return "CYBER" end
        if l:find("10") or l:find("ten") then return "PHANTOM" end
    end
    if l:find("machine") then
        if l:find("1") or l:find("first") then return "RAINBOW MACHINE" end
        if l:find("2") or l:find("second") then return "BUBBLEGUM MACHINE" end
        if l:find("3") or l:find("third") then return "FUSE MACHINE" end
        if l:find("4") or l:find("fourth") then return "CRAFT MACHINE" end
        if l:find("5") or l:find("fifth") then return "WITCH FUSE" end
        if l:find("6") or l:find("sixth") then return "BRAINROT DEALER" end
        if l:find("7") or l:find("seventh") then return "BRAINROT TRADER" end
        if l:find("8") or l:find("eighth") then return "SANTA'S FUSE" end
        if l:find("9") or l:find("ninth") then return "SANTA'S SHOP" end
        if l:find("10") or l:find("tenth") then return "NEW YEAR'S MACHINE" end
        if l:find("11") or l:find("eleventh") then return "DUELS MACHINE" end
        if l:find("12") or l:find("twelfth") then return "CUPID'S MACHINE" end
        if l:find("13") or l:find("thirteenth") then return "TRADE MACHINE" end
        if l:find("14") or l:find("fourteenth") then return "DIVINE FUSE" end
        if l:find("15") or l:find("fifteenth") then return "EGG INCUBATOR" end
        if l:find("16") or l:find("sixteenth") then return "CYBER CRAFT MACHINE" end
        if l:find("17") or l:find("seventeenth") then return "SUMMER FUSE" end
        if l:find("18") or l:find("eighteenth") then return "LOS TRADERS" end
    end
    if l:find("og") or l:find("cannot be obtained") then
        if l:find("headless") then return "HEADLESS HORSEMAN" end
        if l:find("first") or l:find("1st") then return "STRAWBERRYELEPHANT" end
        if l:find("second") or l:find("2nd") then return "MEOWL" end
        if l:find("third") or l:find("3rd") then return "SKIBIDITOILET" end
        if l:find("fifth") or l:find("5th") then return "JOHNPORK" end
    end
    if l:find("highest rarity") then return "OG" end
    if l:find("fire") and (l:find("represent") or l:find("stand")) then return "DRAGON" end
    if l:find("admin abuse") then
        if l:find("spawn") then return "RACOONINI JANDELINI" end
        if l:find("won") then return "GROWAGARDEN" end
    end
    if l:find("worst secret") or l:find("bad secret") then return "KARKERKARKURKUR" end
    if l:find("server") and (l:find("max") or l:find("size")) then return "EIGHT" end
    if l:find("hydra bunny") and (l:find("brother") or l:find("sibling")) then return "CERBERUS" end
    if l:find("old") or l:find("age") then
        if l:find("sammy") or l:find("am i") then return "24" end
    end
    if l:find("from") or l:find("country") then
        if l:find("sammy") or l:find("am i") then return "BRAZIL" end
    end

    return nil
end

-- ========== ULTRA-FAST HANDLER ==========
local function handleIncomingText(textObj)
    if not _G.ScriptEnabled or writeBusy then return end
    local text = textObj.Text
    if text == "" then return end

    if verifySourceIsSammy(textObj) then
        print("[Auto Code] Detected SpyderSammy text: " .. text)
        task.spawn(function()
            processText(text)
        end)
    end
end

local function hookUiTextObject(obj)
    if obj:IsA("TextLabel") then
        handleIncomingText(obj)
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            handleIncomingText(obj)
        end)
    end
end

local function startPlayerGuiScanner()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    for _, desc in ipairs(playerGui:GetDescendants()) do
        hookUiTextObject(desc)
    end

    local conn = playerGui.DescendantAdded:Connect(hookUiTextObject)
    table.insert(activeConnections, conn)
end

-- ========== CODE PROCESSING ==========
local function logStatus(message)
    if MainFrame and MainFrame:FindFirstChild("ContentFrame") then
        local status = MainFrame.ContentFrame:FindFirstChild("StatusLabel")
        if status then status.Text = "Status: " .. message end
    end
end

local function isGuiVisible(obj)
    if not obj or not obj.Visible then return false end
    local current = obj.Parent
    while current do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        elseif current:IsA("ScreenGui") and not current.Enabled then
            return false
        end
        current = current.Parent
    end
    return true
end

local function looksLikeCode(token)
    if not token then return false end
    if #token < 1 or #token > 50 then return false end
    return token:match("^%w+$") ~= nil
end

local function isLoneCode(text)
    if not text then return false end
    text = text:match("^%s*(.-)%s*$")
    if text == "" or text:find("%s") then return false end
    if #text < 1 or #text > 50 then return false end
    return text:match("^%w+$") ~= nil
end

local function extractCodesFromText(text)
    local found = {}
    if not text then return found end
    local trimmed = text:match("^%s*(.-)%s*$")
    trimmed = trimmed:gsub("<[^>]->", "")
    if isLoneCode(trimmed) then
        table.insert(found, trimmed)
        return found
    end
    for token in text:gmatch("%w+") do
        if looksLikeCode(token) then
            table.insert(found, token)
        end
    end
    return found
end

-- ========== CLIPBOARD & UI HELPERS ==========
local function copyCodeToClipboard(code)
    local formattedCode = string.upper(code)
    if setclipboard then
        pcall(function() setclipboard(formattedCode) end)
    elseif toclipboard then
        pcall(function() toclipboard(formattedCode) end)
    elseif set_clipboard then
        pcall(function() set_clipboard(formattedCode) end)
    elseif Clipboard and Clipboard.set then
        pcall(function() Clipboard.set(formattedCode) end)
    end
end

local function formatCode(code)
    return string.upper(code)
end

local _cachedBox = nil

local function _isCodeBox(obj)
    if not obj:IsA("TextBox") then return false end
    if ScreenGui and obj:IsDescendantOf(ScreenGui) then return false end
    local hint = ((obj.PlaceholderText or "") .. " " .. obj.Name):lower()
    return hint:find("code") or hint:find("redeem") or hint:find("here")
end

-- ========== ULTRA-FAST TEXTBOX FINDER ==========
local function findCodeTextBox()
    if _cachedBox and _cachedBox.Parent and isGuiVisible(_cachedBox) then
        return _cachedBox
    end
    _cachedBox = nil
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if _isCodeBox(obj) then
            if isGuiVisible(obj) then _cachedBox = obj return obj end
        end
    end
    return nil
end

local function fireSignal(sig)
    if not sig then return end
    pcall(function()
        if getconnections then
            for _, c in ipairs(getconnections(sig)) do
                if c.Fire then c:Fire() end
            end
        end
    end)
    if firesignal then
        pcall(function() firesignal(sig) end)
    end
end

local function isSubmitButton(obj)
    if not (obj:IsA("TextButton") or obj:IsA("ImageButton")) then return false end
    if ScreenGui and obj:IsDescendantOf(ScreenGui) then return false end
    if not isGuiVisible(obj) then return false end
    local hint = (((obj:IsA("TextButton") and obj.Text) or "") .. " " .. obj.Name):lower()
    return hint:find("redeem") ~= nil or hint:find("submit") ~= nil
end

local function fireSubmitButton(nearObj)
    local target = nil
    local container = nearObj and nearObj.Parent or nil
    local levels = 0
    while container and not target and levels < 5 do
        for _, obj in ipairs(container:GetDescendants()) do
            if isSubmitButton(obj) then
                target = obj
                break
            end
        end
        container = container.Parent
        levels = levels + 1
    end
    if not target then return false end
    fireSignal(target.MouseButton1Click)
    fireSignal(target.Activated)
    return true
end

local _rfRemote = nil
local function getRedemptionRF()
    if _rfRemote and _rfRemote.Parent then return _rfRemote end
    _rfRemote = nil
    local rfFolder = ReplicatedStorage:FindFirstChild("RF")
    if rfFolder then
        local rf = rfFolder:FindFirstChild("RequestRedemption")
        if rf and rf:IsA("RemoteFunction") then
            _rfRemote = rf
            return _rfRemote
        end
    end
    if rfFolder then
        for _, v in ipairs(rfFolder:GetChildren()) do
            if v.Name == "RequestRedemption" and v:IsA("RemoteFunction") then
                _rfRemote = v
                return _rfRemote
            end
        end
    end
    if getinstances then
        for _, v in ipairs(getinstances()) do
            if v.Name == "RequestRedemption" and v:IsA("RemoteFunction") then
                _rfRemote = v
                return _rfRemote
            end
        end
    end
    return _rfRemote
end

-- ========== ULTRA-FAST REDEEM ==========
local function redeemViaRF(code)
    local rf = getRedemptionRF()
    if not rf then return false end
    local formatted = formatCode(code)
    local ok, result = pcall(function()
        return rf:InvokeServer(formatted)
    end)
    if ok then
        return true
    else
        return false
    end
end

-- ========== MAXIMUM SPEED writeAndSubmit ==========
local function writeAndSubmit(code)
    lastAttemptedCode = code

    if redeemViaRF(code) then return true end
    local textBox = findCodeTextBox()
    if not textBox then
        return false
    end
    local formatted = formatCode(code)
    pcall(function() textBox.ClearTextOnFocus = false end)

    if not collectedSeen[formatted] then
        collectedSeen[formatted] = true
        table.insert(collectedCodes, formatted)
    end

    local fullText = table.concat(collectedCodes, CODE_SEPARATOR)
    local target = math.max(1, tonumber(_G.SubmitAfterCount) or 1)
    local ready = #collectedCodes >= target

    if ready and _G.AutoSubmitEnabled then
        lastSubmittedBatch = {}
        for _, c in ipairs(collectedCodes) do
            table.insert(lastSubmittedBatch, c)
        end

        local count = #collectedCodes
        local box = findCodeTextBox()
        if box then
            for i = 1, _G.SubmitAttempts do
                pcall(function()
                    box:CaptureFocus()
                    box.Text = fullText
                    box.CursorPosition = #fullText + 1
                end)
                if not ok then
                    pcall(function() box.Text = fullText end)
                end
                pcall(function() box:ReleaseFocus(true) end)
                task.wait(FAST_WAIT)
                fireSubmitButton(box)
            end
        end
        table.clear(collectedCodes)
        table.clear(collectedSeen)
    else
        task.wait(FAST_WAIT)
        local ok = pcall(function()
            textBox:CaptureFocus()
            textBox.Text = fullText
            textBox.CursorPosition = #fullText + 1
        end)
        if not ok then
            pcall(function() textBox.Text = fullText end)
        end
        if ready then
            table.clear(collectedCodes)
            table.clear(collectedSeen)
        end
    end
    return true
end

-- ========== MAXIMUM SPEED triggerWrite ==========
local function triggerWrite()
    if writeBusy or not _G.AutoWriteEnabled or #pendingQueue == 0 then return end
    local focused = UserInputService:GetFocusedTextBox()
    if focused and ScreenGui and focused:IsDescendantOf(ScreenGui) then return end
    local box = findCodeTextBox()
    if not (box and isGuiVisible(box)) then return end
    writeBusy = true
    task.spawn(function()
        local ok, err = pcall(function()
            while _G.AutoWriteEnabled and #pendingQueue > 0 do
                local b = findCodeTextBox()
                if not (b and isGuiVisible(b)) then break end
                local code = table.remove(pendingQueue, 1)
                pendingSeen[code] = nil
                writeAndSubmit(code)
                task.wait(FAST_WAIT)
            end
        end)
        writeBusy = false
        if not ok then warn("[AutoCode] triggerWrite error: " .. tostring(err)) end
    end)
end

local function startAutoWriteLoop()
    if autoWriteConn then return end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
    local boxConn = playerGui and playerGui.DescendantAdded:Connect(function(obj)
        if _isCodeBox(obj) and isGuiVisible(obj) then
            _cachedBox = obj
            triggerWrite()
        end
    end)
    local boxRemConn = playerGui and playerGui.DescendantRemoving:Connect(function(obj)
        if obj == _cachedBox then _cachedBox = nil end
    end)
    autoWriteConn = { Disconnect = function()
        if boxConn then boxConn:Disconnect() end
        if boxRemConn then boxRemConn:Disconnect() end
    end }
    table.insert(activeConnections, autoWriteConn)
end

-- ========== RIDDLE SOLVER - IMMEDIATE WRITE & SUBMIT ==========
local function riddleWriteAndSubmit(code)
    local textBox = findCodeTextBox()
    if not textBox then
        return false
    end
    local formatted = formatCode(code)
    pcall(function() textBox.ClearTextOnFocus = false end)
    pcall(function()
        textBox:CaptureFocus()
        textBox.Text = formatted
        textBox.CursorPosition = #formatted + 1
    end)
    pcall(function() textBox:ReleaseFocus(true) end)

    task.wait(FAST_WAIT)
    fireSubmitButton(textBox)
    copyCodeToClipboard(formatted)
    return true
end

-- ========== ULTRA-FAST processText ==========
function processText(text)
    -- STEP 1: RIDDLE SOLVER - Independent, immediate write & submit
    if _G.RiddleSolverEnabled then
        local answer = answerQuestion(text)
        if answer then
            riddleWriteAndSubmit(answer)
            return
        end
    end

    -- STEP 2: Auto-Write (normal code extraction)
    if not _G.AutoWriteEnabled then return end

    table.clear(pendingQueue)
    table.clear(pendingSeen)

    if not text or text == "" then return end
    local codes = extractCodesFromText(text)
    if #codes == 0 then return end

    for _, code in ipairs(codes) do
        copyCodeToClipboard(code)
        latestCode = code
        table.insert(pendingQueue, code)
    end

    triggerWrite()
end

local function cleanupMonitoring()
    for _, conn in pairs(activeConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    table.clear(activeConnections)
    table.clear(enteredCodes)
    table.clear(collectedCodes)
    table.clear(collectedSeen)
    table.clear(pendingQueue)
    table.clear(pendingSeen)
    table.clear(lastSubmittedBatch)
    writeBusy = false
    autoWriteConn = nil
    latestCode = nil
    lastWrittenCode = nil
    lastAttemptedCode = nil
end

-- ============================================================
-- GUI-BUILDER FUNCTION - BLUE THEME WITH SNOW
-- ============================================================
local function create(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    return inst
end


-- ===== GEMINI TOP BAR UI =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
-- ============================================================
    -- SCREEN GUI
    -- ============================================================
    ScreenGui = create("ScreenGui", {
        Name = "BrainrotRedeemerGui",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui"),
    })

    -- ============================================================
    -- MAIN FRAME
    -- ============================================================
    local PANEL_W = 240
    local PANEL_H = 310

    MainFrame = create("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = (config.panelX and config.panelY)
            and UDim2.new(0, config.panelX, 0, config.panelY)
            or UDim2.new(0.5, 0, 0.4, 0),
        Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
        BackgroundColor3 = Color3.fromRGB(8, 12, 28),
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        Parent = ScreenGui,
    })

    create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = MainFrame })
    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 20, 40)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 10, 24)),
        }),
        Rotation = 90,
        Parent = MainFrame,
    })

    -- BLUE BORDER
    local mainStroke = create("UIStroke", {
        Color = Color3.fromRGB(40, 120, 255),
        Thickness = 2,
        Transparency = 0.3,
        Parent = MainFrame,
    })

    local strokeGradient = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0,  Color3.fromRGB(100, 180, 255)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(30, 90, 220)),
            ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(100, 180, 255)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(30, 90, 220)),
            ColorSequenceKeypoint.new(1.0,  Color3.fromRGB(100, 180, 255)),
        }),
        Parent = mainStroke,
    })

    -- ============================================================
    -- SNOW BACKGROUND INSIDE MAIN FRAME
    -- ============================================================
    local SnowContainer = create("Frame", {
        Name = "SnowContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 1,
        Parent = MainFrame,
    })

    local snowflakes = {}
    local SNOW_COUNT = 25

    local function getSnowBounds()
        local absSize = MainFrame.AbsoluteSize
        return absSize.X, absSize.Y
    end

    task.wait()
    local frameWidth, frameHeight = getSnowBounds()
    if frameWidth == 0 or frameHeight == 0 then
        frameWidth = PANEL_W
        frameHeight = PANEL_H
    end

    for i = 1, SNOW_COUNT do
        local snow = create("TextLabel", {
            Name = "Snowflake_" .. i,
            Text = "❄",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = math.random(12, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            ZIndex = 1,
            TextTransparency = math.random(30, 80) / 100,
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, math.random(0, frameWidth), 0, math.random(-100, frameHeight + 100)),
            Parent = SnowContainer,
        })
        
        local size = snow.TextSize
        snow.Size = UDim2.new(0, size, 0, size)
        
        table.insert(snowflakes, {
            object = snow,
            x = snow.Position.X.Offset,
            y = snow.Position.Y.Offset,
            speed = math.random(30, 70) / 100,
            drift = math.random(-25, 25) / 100,
            wobble = math.random(0, 360),
            wobbleSpeed = math.random(10, 30) / 100,
            size = size,
            transparency = snow.TextTransparency,
            frameWidth = frameWidth,
            frameHeight = frameHeight,
        })
    end

    task.spawn(function()
        while SnowContainer and SnowContainer.Parent do
            local newWidth, newHeight = getSnowBounds()
            if newWidth > 0 and newHeight > 0 then
                for _, flake in ipairs(snowflakes) do
                    if flake and flake.object and flake.object.Parent then
                        flake.y = flake.y + flake.speed
                        flake.wobble = flake.wobble + flake.wobbleSpeed
                        flake.x = flake.x + math.sin(flake.wobble) * flake.drift * 0.5
                        
                        if flake.y > flake.frameHeight + 50 then
                            flake.y = -20
                            flake.x = math.random(0, flake.frameWidth)
                            flake.speed = math.random(30, 70) / 100
                            flake.drift = math.random(-25, 25) / 100
                            flake.size = math.random(12, 20)
                            flake.object.TextSize = flake.size
                            flake.object.Size = UDim2.new(0, flake.size, 0, flake.size)
                            flake.transparency = math.random(30, 80) / 100
                            flake.object.TextTransparency = flake.transparency
                        end
                        
                        if flake.x > flake.frameWidth + 50 then flake.x = -50 end
                        if flake.x < -50 then flake.x = flake.frameWidth + 50 end
                        
                        flake.object.Position = UDim2.new(0, flake.x, 0, flake.y)
                    end
                end
            end
            task.wait(0.03)
        end
    end)

    -- ============================================================
    -- TITLE BAR - BLUE ACCENT
    -- ============================================================
    local titleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Color3.fromRGB(10, 16, 32),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = MainFrame,
    })

    create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = titleBar })

    local titleLabel = create("TextLabel", {
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "NexusHub",
        TextColor3 = Color3.fromRGB(150, 200, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
        Parent = titleBar,
    })

    -- ===== HELP BUTTON (?) =====
    local helpBtn = create("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -134, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(18, 28, 50),
        Text = "?",
        TextColor3 = Color3.fromRGB(200, 220, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        AutoButtonColor = true,
        ZIndex = 10,
        Parent = titleBar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = helpBtn })

    -- MINIMIZE BUTTON
    local minimizeBtn = create("TextButton", {
        Name = "MinimizeBtn",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -110, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(18, 28, 50),
        Text = "−",
        TextColor3 = Color3.fromRGB(200, 220, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        AutoButtonColor = true,
        ZIndex = 10,
        Parent = titleBar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = minimizeBtn })

    -- Main toggle (ON/OFF)
    local toggleButton = create("TextButton", {
        Name = "SwitchBtn",
        Size = UDim2.new(0, 52, 0, 22),
        Position = UDim2.new(1, -56, 0.5, -11),
        BackgroundColor3 = _G.ScriptEnabled and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68),
        Text = _G.ScriptEnabled and "ON" or "OFF",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = titleBar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = toggleButton })

    toggleButton.MouseButton1Click:Connect(function()
        _G.ScriptEnabled = not _G.ScriptEnabled
        if _G.ScriptEnabled then
            toggleButton.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
            toggleButton.Text = "ON"
        else
            toggleButton.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
            toggleButton.Text = "OFF"
        end
    end)

    -- ============================================================
    -- CONTENT FRAME
    -- ============================================================
    local ContentFrame = create("Frame", {
        Name = "ContentFrame",
        Size = UDim2.new(1, 0, 1, -28),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = MainFrame,
    })

    -- ROW 1: Auto-Write
    local awLabel = create("TextLabel", {
        Size = UDim2.new(0, 80, 0, 22),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = "Auto Type",
        TextColor3 = Color3.fromRGB(150, 180, 220),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
        Parent = ContentFrame,
    })

    local awToggle = create("TextButton", {
        Size = UDim2.new(0, 52, 0, 22),
        Position = UDim2.new(1, -56, 0, 8),
        BackgroundColor3 = _G.AutoWriteEnabled and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68),
        Text = _G.AutoWriteEnabled and "ON" or "OFF",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = ContentFrame,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = awToggle })

    awToggle.MouseButton1Click:Connect(function()
        _G.AutoWriteEnabled = not _G.AutoWriteEnabled
        if _G.AutoWriteEnabled then
            awToggle.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
            awToggle.Text = "ON"
        else
            awToggle.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
            awToggle.Text = "OFF"
            table.clear(collectedCodes)
            table.clear(collectedSeen)
            table.clear(pendingQueue)
            table.clear(pendingSeen)
            lastWrittenCode = nil
        end
    end)

    -- ROW 2: Auto-Submit + count
    local asLabel = create("TextLabel", {
        Size = UDim2.new(0, 80, 0, 22),
        Position = UDim2.new(0, 12, 0, 36),
        BackgroundTransparency = 1,
        Text = "Auto Submit",
        TextColor3 = Color3.fromRGB(150, 180, 220),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
        Parent = ContentFrame,
    })

    local asToggle = create("TextButton", {
        Size = UDim2.new(0, 40, 0, 22),
        Position = UDim2.new(1, -122, 0, 36),
        BackgroundColor3 = _G.AutoSubmitEnabled and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68),
        Text = _G.AutoSubmitEnabled and "ON" or "OFF",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = ContentFrame,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = asToggle })

    asToggle.MouseButton1Click:Connect(function()
        _G.AutoSubmitEnabled = not _G.AutoSubmitEnabled
        if _G.AutoSubmitEnabled then
            asToggle.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
            asToggle.Text = "ON"
        else
            asToggle.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
            asToggle.Text = "OFF"
            table.clear(collectedCodes)
            table.clear(collectedSeen)
        end
    end)

    -- Count controls
    local minusBtn = create("TextButton", {
        Size = UDim2.new(0, 24, 0, 22),
        Position = UDim2.new(1, -78, 0, 36),
        BackgroundColor3 = Color3.fromRGB(18, 28, 50),
        Text = "−",
        TextColor3 = Color3.fromRGB(200, 220, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        AutoButtonColor = true,
        ZIndex = 10,
        Parent = ContentFrame,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = minusBtn })

    local countDisplay = create("TextLabel", {
        Size = UDim2.new(0, 28, 0, 22),
        Position = UDim2.new(1, -52, 0, 36),
        BackgroundColor3 = Color3.fromRGB(18, 28, 50),
        BackgroundTransparency = 0.3,
        Text = tostring(_G.SubmitAfterCount),
        TextColor3 = Color3.fromRGB(200, 220, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 10,
        Parent = ContentFrame,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = countDisplay })

    local plusBtn = create("TextButton", {
        Size = UDim2.new(0, 24, 0, 22),
        Position = UDim2.new(1, -24, 0, 36),
        BackgroundColor3 = Color3.fromRGB(18, 28, 50),
        Text = "+",
        TextColor3 = Color3.fromRGB(200, 220, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        AutoButtonColor = true,
        ZIndex = 10,
        Parent = ContentFrame,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = plusBtn })

    plusBtn.MouseButton1Click:Connect(function()
        _G.SubmitAfterCount = _G.SubmitAfterCount + 1
        countDisplay.Text = tostring(_G.SubmitAfterCount)
    end)

    minusBtn.MouseButton1Click:Connect(function()
        if _G.SubmitAfterCount > 1 then
            _G.SubmitAfterCount = _G.SubmitAfterCount - 1
            countDisplay.Text = tostring(_G.SubmitAfterCount)
        end
    end)

    -- ROW 3: Answer Questions (Riddle Solver)
    local rsLabel = create("TextLabel", {
        Size = UDim2.new(0, 100, 0, 22),
        Position = UDim2.new(0, 12, 0, 64),
        BackgroundTransparency = 1,
        Text = "Riddle Solver",
        TextColor3 = Color3.fromRGB(150, 180, 220),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
        Parent = ContentFrame,
    })

    local rsToggle = create("TextButton", {
        Name = "RiddleSolverToggle",
        Size = UDim2.new(0, 52, 0, 22),
        Position = UDim2.new(1, -56, 0, 64),
        BackgroundColor3 = _G.RiddleSolverEnabled and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68),
        Text = _G.RiddleSolverEnabled and "ON" or "OFF",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = ContentFrame,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = rsToggle })

    rsToggle.MouseButton1Click:Connect(function()
        _G.RiddleSolverEnabled = not _G.RiddleSolverEnabled
        if _G.RiddleSolverEnabled then
            rsToggle.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
            rsToggle.Text = "ON"
        else
            rsToggle.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
            rsToggle.Text = "OFF"
        end
    end)

    -- ROW 4: Status
    local statusLabel = create("TextLabel", {
        Name = "StatusLabel",
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 12, 0, 96),
        BackgroundTransparency = 1,
        Text = "Status: Idle",
        TextColor3 = Color3.fromRGB(100, 150, 220),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
        Parent = ContentFrame,
    })

    -- ROW 5: Latest Code
    local lcLabel = create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 12, 0, 118),
        BackgroundTransparency = 1,
        Text = "Latest: none",
        TextColor3 = Color3.fromRGB(100, 150, 220),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
        Parent = ContentFrame,
    })

    -- Divider line
    local contentDivider = create("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 0, 146),
        BackgroundColor3 = Color3.fromRGB(30, 70, 150),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = ContentFrame,
    })

    -- Credit text
    local creditLabel = create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 12, 0, 272),
        BackgroundTransparency = 1,
        Text = "made by killer mel and ssaaa",
        TextColor3 = Color3.fromRGB(70, 110, 170),
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 10,
        Parent = ContentFrame,
    })

    -- ============================================================
    -- DRAG FUNCTIONALITY
    -- ============================================================
    local dragging, dragInput, dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
        local pos = MainFrame.Position
        if pos.X.Scale == 0 and pos.Y.Scale == 0 then
            config.panelX = pos.X.Offset
            config.panelY = pos.Y.Offset
            saveConfig()
        end
    end)

    -- ============================================================
    -- MINIMIZE FUNCTIONALITY
    -- ============================================================
    local isMinimized = false
    local contentSize = ContentFrame.Size

    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            ContentFrame.Visible = false
            MainFrame.Size = UDim2.new(0, PANEL_W, 0, 28)
        else
            ContentFrame.Visible = true
            MainFrame.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
        end
    end)

    -- ============================================================
    -- HELP BUTTON
    -- ============================================================
    local helpFrame = create("Frame", {
        Name = "HelpFrame",
        Size = UDim2.new(0, 220, 0, 160),
        Position = UDim2.new(1, 10, 0, 0),
        BackgroundColor3 = Color3.fromRGB(10, 16, 32),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20,
        Parent = MainFrame,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = helpFrame })
    create("UIStroke", {
        Color = Color3.fromRGB(40, 120, 255),
        Thickness = 1,
        Transparency = 0.3,
        Parent = helpFrame,
    })

    local helpText = create("TextLabel", {
        Size = UDim2.new(1, -16, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        Text = "NexusHub Auto Code\n\nAuto Type: Types codes\ninto the code box\n\nAuto Submit: Submits\ncodes automatically\n\nRiddle Solver: Answers\nSAB riddle questions",
        TextColor3 = Color3.fromRGB(150, 190, 240),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 21,
        Parent = helpFrame,
    })

    helpBtn.MouseButton1Click:Connect(function()
        helpFrame.Visible = not helpFrame.Visible
    end)

    -- ============================================================
    -- STATUS UPDATER
    -- ============================================================
    task.spawn(function()
        while task.wait(0.5) do
            if not MainFrame or not MainFrame.Parent then break end
            if _G.ScriptEnabled then
                if _G.RiddleSolverEnabled then
                    statusLabel.Text = "Status: Riddle Solver active"
                elseif _G.AutoWriteEnabled then
                    if _G.AutoSubmitEnabled then
                        statusLabel.Text = "Status: Auto Write+Submit"
                    else
                        statusLabel.Text = "Status: Auto Typing..."
                    end
                else
                    statusLabel.Text = "Status: Monitoring..."
                end
            else
                statusLabel.Text = "Status: Disabled"
            end
            lcLabel.Text = "Latest: " .. (latestCode or "none")
        end
    end)
end

-- ============================================================
-- STARTUP
-- ============================================================
buildGUI()
startPlayerGuiScanner()
startAutoWriteLoop()

print("[NexusHub] Loaded successfully!")
print("[NexusHub] made by killer mel and ssaaa")
