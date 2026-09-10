-- ==========================================
-- ⚠️ WAJIB DI ATAS SCRIPT: Mencegah error kalau pakai AutoExecute
-- ==========================================
repeat task.wait() until game:IsLoaded()
task.wait(2) -- Jeda ekstra biar data UI/Inventory server selesai dimuat

-- ==========================================
-- 🛡️ ANTI-AFK NATIVE (Mencegah Kick Roblox 20 Menit)
-- ==========================================
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local gc = getconnections or get_connections
if gc then
    for i, connection in pairs(gc(LocalPlayer.Idled)) do
        connection:Disable()
    end
    print("✅ Anti-AFK VIP (getconnections) Aktif!")
else
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    warn("⚠️ Anti-AFK Cadangan (VirtualUser) Aktif.")
end

-- ==========================================
-- 🎨 SETUP RAYFIELD UI
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Roll, Tower & Upgrades",
    LoadingTitle = "Memuat Script...",
    LoadingSubtitle = "Script by Gemii AI",
    ConfigurationSaving = {
        Enabled = true, 
        FolderName = "GemiiHub", 
        FileName = "AutoGameConfig" 
    }
})

-- ==========================================
-- SETUP REMOTES & DATABASE
-- ==========================================
local Network = game:GetService("ReplicatedStorage"):WaitForChild("Network")

local RollRemote = Network:WaitForChild("RollService"):WaitForChild("RF"):WaitForChild("RollDice")
local EquipBestRemote = Network:WaitForChild("PlotService"):WaitForChild("RE"):WaitForChild("EquipBest")
local CollectBalanceRemote = Network:WaitForChild("PlotService"):WaitForChild("RE"):WaitForChild("CollectBalance")

local PlayTowerRemote = Network:WaitForChild("Towers"):WaitForChild("RF"):WaitForChild("PlayTower")
local CompleteFloorRemote = Network:WaitForChild("Towers"):WaitForChild("RF"):WaitForChild("CompleteTowerFloor")
local CancelTowerRemote = Network:WaitForChild("Towers"):WaitForChild("RF"):WaitForChild("CancelTower")
local EquipBestTowerRemote = Network:WaitForChild("Towers"):WaitForChild("RE"):WaitForChild("EquipBestTowerTeam")

local BuyUpgradeRemote = Network:WaitForChild("RE"):WaitForChild("BuyUpgrade")
local TradeRemote = Network:WaitForChild("TradeService"):WaitForChild("RE"):WaitForChild("ChangeOffer")
local TradeEventRemote = Network:WaitForChild("TradeService"):WaitForChild("RE"):WaitForChild("TradeEvent")
local BuyDiceRemote = Network:WaitForChild("DiceShopService"):WaitForChild("RE"):WaitForChild("BuyDice")

local RarityDatabase = {
    ["Titanic Krillan"] = "1 in 10,000",
    ["Karakter Biasa"] = "1 in 10",
}

local DiceHierarchy = {
    "Normal", "Fire", "Water", "Nature", "Lightning", "Ice", "Magma", 
    "Storm", "Shadow", "Light", "Blood Moon", "Void", "Solar", "Lunar", 
    "Galaxy", "Black Hole", "Dragon", "Royal", "Prismatic", "Arcane", 
    "Corrupted", "Titan", "Chrono"
}

-- ==========================================
-- 🕵️ HOOKING DEWA (BLOKIR REJOIN + DUAL SCAN TRADE)
-- ==========================================
local item1Name = nil
local item1Target = 0
local item1Current = 0

local item2Name = nil
local item2Target = 0
local item2Current = 0

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = tostring(getnamecallmethod()):lower()
    local args = {...}
    
    if not checkcaller() then
        if method == "teleport" and self == TeleportService then
            if args[1] == game.PlaceId then
                warn("Bypass 19 Menit Aktif: Rejoin diblokir oleh script!")
                return nil 
            end
        end
        
        if method == "fireserver" and tostring(self) == "ChangeOffer" then
            if args[1] and type(args[1]) == "string" and args[2] == 1 then
                local clickedItem = args[1]
                if item1Name == nil or item1Name == clickedItem then
                    item1Name = clickedItem
                elseif item2Name == nil or item2Name == clickedItem then
                    item2Name = clickedItem
                end
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

TradeEventRemote.OnClientEvent:Connect(function(action, data)
    if action == "Updated" and type(data) == "table" and data.ownOffer then
        if item1Name then item1Current = data.ownOffer[item1Name] or 0 end
        if item2Name then item2Current = data.ownOffer[item2Name] or 0 end
    elseif action == "Started" or action == "Ended" then
        item1Current = 0
        item2Current = 0
    end
end)

-- ==========================================
-- TAB 1: MAIN MENU (ROLL, PLOT & DICE)
-- ==========================================
local MainTab = Window:CreateTab("Main Menu", 4483362458) 

local SpeedLabel = MainTab:CreateLabel("Kecepatan Roll: Menunggu data...")
local RollDetails = MainTab:CreateParagraph({
    Title = "Status Roll Terakhir", 
    Content = "Belum ada karakter yang didapat."
})

local autoRoll = false
MainTab:CreateToggle({
    Name = "Enable Auto Roll",
    CurrentValue = false,
    Flag = "AutoRollToggle", 
    Callback = function(Value)
        autoRoll = Value
        if autoRoll then
            task.spawn(function()
                local lastRollTime = os.clock()
                while autoRoll do
                    local success, response = pcall(function() return RollRemote:InvokeServer() end)
                    local currentTime = os.clock()
                    local timeTaken = currentTime - lastRollTime
                    if success and response and type(response) == "table" and response[1] then
                        local rollData = response[1]
                        local charName = rollData.result or "Unknown"
                        local rarity = RarityDatabase[charName] or "1 in ??"
                        lastRollTime = currentTime
                        SpeedLabel:Set(string.format("Kecepatan Roll: %.2f detik / roll", timeTaken))
                        RollDetails:Set({Title = "✅ Mendapatkan: " .. charName, Content = string.format("Karakter : %s\nRarity : %s", charName, rarity)})
                    end
                    task.wait(0.05) 
                end
            end)
        else
            SpeedLabel:Set("Kecepatan Roll: Berhenti")
        end
    end,
})

local autoEquip = false
MainTab:CreateToggle({
    Name = "Auto Equip Best Character",
    CurrentValue = false,
    Flag = "AutoEquipToggle",
    Callback = function(Value)
        autoEquip = Value
        if autoEquip then task.spawn(function() while autoEquip do pcall(function() EquipBestRemote:FireServer() end); task.wait(3) end end) end
    end,
})

local autoBuyDice = false
MainTab:CreateToggle({
    Name = "Auto Buy Best Dice",
    CurrentValue = false,
    Flag = "AutoBuyDiceToggle",
    Callback = function(Value)
        autoBuyDice = Value
        if autoBuyDice then
            task.spawn(function()
                while autoBuyDice do
                    for _, diceName in ipairs(DiceHierarchy) do
                        if not autoBuyDice then break end
                        pcall(function() BuyDiceRemote:FireServer(diceName) end)
                        task.wait(0.6) 
                    end
                    task.wait(5)
                end
            end)
        end
    end,
})

local autoCollect = false
MainTab:CreateToggle({
    Name = "Auto Collect Gold",
    CurrentValue = false,
    Flag = "AutoCollectToggle",
    Callback = function(Value)
        autoCollect = Value
        if autoCollect then
            task.spawn(function()
                while autoCollect do
                    for i = 1, 20 do
                        if not autoCollect then break end 
                        pcall(function() CollectBalanceRemote:FireServer(i) end)
                        task.wait(0.05) 
                    end
                    task.wait(2) 
                end
            end)
        end
    end,
})

-- ==========================================
-- TAB 2: AUTO UPGRADES (RESTORED FULLY)
-- ==========================================
local UpgradeTab = Window:CreateTab("Auto Upgrades", 4483362458) 

UpgradeTab:CreateParagraph({
    Title = "💡 Info Upgrade Tree", 
    Content = "Beberapa upgrade butuh syarat jalur lain. Contoh: Roll Speed butuh Luck IV. Aktifkan Luck juga agar Roll Speed jalan."
})

local UpgradesData = {
    Money = {"Money I", "Money II", "Money III", "Money IV", "Money V", "Money VI", "Money VII", "Money VIII", "Money IX", "Money X", "Money XI", "Money XII"},
    Luck = {"Luck I", "Luck II", "Luck III", "Luck IV", "Luck V", "Luck VI", "Luck VII", "Luck VIII", "Luck IX", "Luck X", "Luck XI", "Luck XII"},
    RollSpeed = {"Roll Speed I", "Roll Speed II", "Roll Speed III", "Roll Speed IV", "Roll Speed V", "Roll Speed VI"},
    Damage = {"Damage I", "Damage II", "Damage III", "Damage IV", "Damage V", "Damage VI", "Damage VII", "Damage VIII", "Damage IX"},
    UnitStorage = {"Unit Storage I", "Unit Storage II", "Unit Storage III", "Unit Storage IV", "Unit Storage V", "Unit Storage VI", "Unit Storage VII", "Unit Storage VIII"}
}

local function processUpgrades(listTable)
    for _, upgradeName in ipairs(listTable) do
        pcall(function() BuyUpgradeRemote:FireServer(upgradeName) end)
        task.wait(0.1) 
    end
end

local autoMoneyUp = false
UpgradeTab:CreateToggle({
    Name = "Fokus: Auto Money Multiplier",
    CurrentValue = false,
    Flag = "AutoMoneyUpToggle",
    Callback = function(Value)
        autoMoneyUp = Value
        if autoMoneyUp then task.spawn(function() while autoMoneyUp do processUpgrades(UpgradesData.Money); task.wait(3) end end) end
    end,
})

local autoLuckUp = false
UpgradeTab:CreateToggle({
    Name = "Fokus: Auto Luck",
    CurrentValue = false,
    Flag = "AutoLuckUpToggle",
    Callback = function(Value)
        autoLuckUp = Value
        if autoLuckUp then task.spawn(function() while autoLuckUp do processUpgrades(UpgradesData.Luck); task.wait(3) end end) end
    end,
})

local autoRollSpeedUp = false
UpgradeTab:CreateToggle({
    Name = "Fokus: Auto Roll Speed",
    CurrentValue = false,
    Flag = "AutoRollSpeedUpToggle",
    Callback = function(Value)
        autoRollSpeedUp = Value
        if autoRollSpeedUp then task.spawn(function() while autoRollSpeedUp do processUpgrades(UpgradesData.RollSpeed); task.wait(3) end end) end
    end,
})

local autoAllUp = false
UpgradeTab:CreateToggle({
    Name = "MAXIMUM: Auto Beli SEMUA Upgrade",
    CurrentValue = false,
    Flag = "AutoAllUpToggle",
    Callback = function(Value)
        autoAllUp = Value
        if autoAllUp then
            task.spawn(function()
                while autoAllUp do
                    processUpgrades(UpgradesData.Money)
                    processUpgrades(UpgradesData.Luck)
                    processUpgrades(UpgradesData.RollSpeed)
                    processUpgrades(UpgradesData.Damage)
                    processUpgrades(UpgradesData.UnitStorage)
                    task.wait(5)
                end
            end)
        end
    end,
})

-- ==========================================
-- TAB 3: TOWER 
-- ==========================================
local TowerTab = Window:CreateTab("Towers", 4483362458) 

local TowerInfoLabel = TowerTab:CreateLabel("Status Tower: Belum Mulai")
local TowerRewardsDetails = TowerTab:CreateParagraph({
    Title = "Hadiah Run Terakhir", 
    Content = "Belum ada run yang diselesaikan."
})

TowerTab:CreateButton({
    Name = "Equip Best Tower Team",
    Callback = function() pcall(function() EquipBestTowerRemote:FireServer() end) end,
})

local selectedTower = "Dragon Tower"
TowerTab:CreateDropdown({
    Name = "Pilih Tingkat Tower",
    Options = {"Dragon Tower", "Cursed Tower", "Pirate Tower", "Infinity Tower"},
    CurrentOption = {"Dragon Tower"},
    MultipleOptions = false,
    Flag = "TowerDropdown",
    Callback = function(Option) selectedTower = Option[1] end,
})

local autoPlayTower = false
TowerTab:CreateToggle({
    Name = "Auto Play Tower",
    CurrentValue = false,
    Flag = "AutoTowerToggle",
    Callback = function(Value)
        autoPlayTower = Value
        if autoPlayTower then
            task.spawn(function()
                while autoPlayTower do
                    pcall(function() PlayTowerRemote:InvokeServer(selectedTower) end)
                    task.wait(1)
                    local isTowerActive = true
                    local latestFloor = "1"
                    while autoPlayTower and isTowerActive do
                        local success, response = pcall(function() return CompleteFloorRemote:InvokeServer() end)
                        if success and type(response) == "table" then
                            for _, actionData in ipairs(response) do
                                if actionData.floor then latestFloor = tostring(actionData.floor) end
                                if actionData.action == "ended" then
                                    isTowerActive = false 
                                    local rewardsText = ""
                                    if actionData.rewards and type(actionData.rewards) == "table" then
                                        for itemName, itemAmount in pairs(actionData.rewards) do
                                            rewardsText = rewardsText .. "🎁 " .. itemName .. " : " .. tostring(itemAmount) .. "\n"
                                        end
                                    end
                                    if rewardsText == "" then rewardsText = "Tidak ada hadiah didapat (Gagal)." end
                                    TowerRewardsDetails:Set({Title = "✅ Hasil: " .. selectedTower .. " (Floor " .. latestFloor .. ")", Content = rewardsText})
                                end
                            end
                            if isTowerActive then TowerInfoLabel:Set(string.format("Status: %s (Lantai: %s)", selectedTower, latestFloor)) end
                            task.wait(2.2) 
                        else
                            task.wait(1)
                        end
                    end
                    if autoPlayTower then
                        TowerInfoLabel:Set("Status: Tower Selesai, Restarting...")
                        task.wait(2.5) 
                    end
                end
            end)
        else
            TowerInfoLabel:Set("Status: Berhenti (Tower Dibatalkan)")
            pcall(function() CancelTowerRemote:InvokeServer() end)
            task.spawn(function() task.wait(0.5); pcall(function() CompleteFloorRemote:InvokeServer() end) end)
        end
    end,
})

-- ==========================================
-- TAB 4: DUAL AUTO TRADE (MULTI ADD)
-- ==========================================
local TradeTab = Window:CreateTab("Auto Trade", 4483362458) 

TradeTab:CreateParagraph({
    Title = "Cara Pakai Dual Scanner", 
    Content = "Buka Trade, klik manual item 1. Lalu klik manual item 2. Keduanya otomatis masuk ke Slot di bawah. Jika hanya 1 item, abaikan Slot 2."
})

local Slot1Label = TradeTab:CreateLabel("🔴 SLOT 1: Kosong | Di Trade: 0")
local Slot2Label = TradeTab:CreateLabel("🔵 SLOT 2: Kosong | Di Trade: 0")
local ProgressLabel = TradeTab:CreateLabel("Status: Menunggu eksekusi...")

task.spawn(function()
    while task.wait(0.2) do
        local n1 = item1Name or "Kosong"
        local n2 = item2Name or "Kosong"
        Slot1Label:Set("🔴 SLOT 1: " .. n1 .. " | Di Trade: " .. tostring(item1Current))
        Slot2Label:Set("🔵 SLOT 2: " .. n2 .. " | Di Trade: " .. tostring(item2Current))
    end
end)

TradeTab:CreateButton({
    Name = "🧹 Reset Slot Scanner",
    Callback = function()
        item1Name, item2Name = nil, nil
        item1Target, item2Target = 0, 0
        Rayfield:Notify({Title = "Reset", Content = "Semua slot berhasil dibersihkan!", Duration = 2})
    end,
})

TradeTab:CreateInput({
    Name = "Item Target 1 (Manual)",
    PlaceholderText = "Contoh: Gems",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        if Text and Text ~= "" then item1Name = Text end
    end,
})
TradeTab:CreateInput({
    Name = "Jumlah Tambahan (Slot 1)",
    PlaceholderText = "Contoh: 99",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) item1Target = tonumber(Text) or 0 end,
})

TradeTab:CreateInput({
    Name = "Item Target 2 (Manual)",
    PlaceholderText = "Contoh: Trait Reroll",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        if Text and Text ~= "" then item2Name = Text end
    end,
})
TradeTab:CreateInput({
    Name = "Jumlah Tambahan (Slot 2)",
    PlaceholderText = "Contoh: 50",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) item2Target = tonumber(Text) or 0 end,
})

local tradeDelay = 0.1
TradeTab:CreateSlider({
    Name = "Jeda Tembakan (Anti-Drop)",
    Range = {0.05, 1.0},
    Increment = 0.05,
    Suffix = "Detik",
    CurrentValue = 0.1,
    Flag = "TradeDelaySlider",
    Callback = function(Value) tradeDelay = Value end,
})

local isTrading = false
local AutoAddToggle 

AutoAddToggle = TradeTab:CreateToggle({
    Name = "🚀 Nyalakan Multi Auto Add",
    CurrentValue = false,
    Flag = "MultiAutoAddToggle",
    Callback = function(Value)
        isTrading = Value
        if isTrading then
            if not item1Name and not item2Name then
                Rayfield:Notify({Title = "Gagal", Content = "Isi minimal satu slot dulu cuy!", Duration = 3})
                task.spawn(function() AutoAddToggle:Set(false) end)
                return
            end
            
            local targetTotal1 = item1Current + item1Target
            local targetTotal2 = item2Current + item2Target
            
            Rayfield:Notify({Title = "Multi Add Aktif", Content = "Memproses item...", Duration = 3})
            
            task.spawn(function()
                while isTrading do
                    local done1 = true
                    local done2 = true
                    
                    if item1Name and item1Current < targetTotal1 then
                        pcall(function() TradeRemote:FireServer(item1Name, 1) end)
                        done1 = false
                        task.wait(tradeDelay)
                    end
                    
                    if item2Name and item2Current < targetTotal2 then
                        pcall(function() TradeRemote:FireServer(item2Name, 1) end)
                        done2 = false
                        task.wait(tradeDelay)
                    end
                    
                    ProgressLabel:Set(string.format("Status: S1(%d/%d) | S2(%d/%d)", item1Current, targetTotal1, item2Current, targetTotal2))
                    
                    if done1 and done2 then
                        break
                    end
                end
                
                if isTrading then 
                    Rayfield:Notify({Title = "Selesai", Content = "Semua target tercapai!", Duration = 4})
                    ProgressLabel:Set("Status: Selesai! (Target Tercapai)")
                    AutoAddToggle:Set(false) 
                end
            end)
        else
            ProgressLabel:Set("Status: Diberhentikan.")
        end
    end,
})

-- ==========================================
-- TAB 5: ⚙️ FPS BOOST & OPTIMIZATION
-- ==========================================
local OptimizationTab = Window:CreateTab("⚙️ FPS Boost", 4483362458) 

OptimizationTab:CreateParagraph({
    Title = "Peringatan Mode Kentang", 
    Content = "Mengeksekusi fitur ini akan mengubah grafis game menjadi kotak-kotak, menghapus efek bayangan, dan membuat seluruh map menjadi ABU-ABU. Loop aktif tiap 10 detik!"
})

local isPotatoMode = false
OptimizationTab:CreateToggle({
    Name = "🚀 Mode Kentang Extreme (Abu-Abu)",
    CurrentValue = false,
    Flag = "PotatoModeToggle",
    Callback = function(Value)
        isPotatoMode = Value
        if isPotatoMode then
            task.spawn(function()
                local Lighting = game:GetService("Lighting")
                local Terrain = workspace:FindFirstChildOfClass("Terrain")
                
                while isPotatoMode do
                    pcall(function()
                        Lighting.GlobalShadows = false
                        Lighting.FogEnd = 9e9
                        Lighting.ShadowSoftness = 0
                        Lighting.Brightness = 1
                        
                        if sethiddenproperty then
                            pcall(function() sethiddenproperty(Lighting, "Technology", 2) end)
                        end
                        
                        for _, v in pairs(Lighting:GetDescendants()) do
                            if v:IsA("PostEffect") then v.Enabled = false end
                        end
                        
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.Material = Enum.Material.SmoothPlastic
                                v.Reflectance = 0
                                v.CastShadow = false
                                v.Color = Color3.fromRGB(120, 120, 120) 
                            elseif v:IsA("Decal") or v:IsA("Texture") then
                                v.Transparency = 1
                            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                                v.Enabled = false
                            end
                        end
                        
                        if Terrain then
                            Terrain.WaterWaveSize = 0
                            Terrain.WaterWaveSpeed = 0
                            Terrain.WaterReflectance = 0
                            Terrain.WaterTransparency = 0
                        end
                    end)
                    task.wait(10)
                end
            end)
        end
    end,
})

local blackScreenUI = nil
OptimizationTab:CreateToggle({
    Name = "Mode Hemat Baterai (Layar Hitam)",
    CurrentValue = false,
    Flag = "BlackScreenToggle",
    Callback = function(Value)
        if Value then
            if not blackScreenUI then
                blackScreenUI = Instance.new("ScreenGui")
                blackScreenUI.Name = "AntiLagBlackScreen"
                blackScreenUI.IgnoreGuiInset = true
                blackScreenUI.ResetOnSpawn = false
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundColor3 = Color3.new(0, 0, 0)
                frame.Parent = blackScreenUI
                
                local text = Instance.new("TextLabel")
                text.Size = UDim2.new(1, 0, 1, 0)
                text.BackgroundTransparency = 1
                text.Text = "MODE HEMAT BATERAI AKTIF\n(Buka menu script untuk mematikan)"
                text.TextColor3 = Color3.new(1, 1, 1)
                text.TextSize = 24
                text.Font = Enum.Font.SourceSansBold
                text.Parent = frame
            end
            
            local success = pcall(function()
                blackScreenUI.Parent = game:GetService("CoreGui")
            end)
            if not success then
                blackScreenUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
            end
            
            if setfpscap then pcall(function() setfpscap(15) end) end
            
        else
            if blackScreenUI then
                blackScreenUI.Parent = nil
            end
            if setfpscap then pcall(function() setfpscap(60) end) end
        end
    end,
})

-- ==========================================
-- AUTO LOAD CONFIGURATION
-- ==========================================
Rayfield:LoadConfiguration()
