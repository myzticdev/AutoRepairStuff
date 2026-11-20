local addonName = ...
local modeVariable = "AutoRepairStuffMode"
local repairCheck

local function StopRepairCheck()
    if repairCheck then
        repairCheck:Cancel()
        repairCheck = nil
    end
end

local function RepairAndReport(cost, useGuildFunds)
    RepairAllItems(useGuildFunds)
    if AutoRepairStuffOptions.hideRepairMessage then
        return
    end

    local funding = useGuildFunds and "guild gold" or "your gold"

    -- The vendor cost updates after the server processes the repair.
    repairCheck = C_Timer.NewTicker(0.1, function()
        if GetRepairAllCost() == 0 then
            StopRepairCheck()
            print(("|cff00ff00Auto Repaired for %s with %s|r"):format(
                C_CurrencyInfo.GetCoinTextureString(cost), funding))
        end
    end, 30)
end

local function MeetsDurabilityThreshold()
    local threshold = AutoRepairStuffOptions.durabilityThreshold
    if threshold == 0 then
        return true
    end

    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local current, maximum = GetInventoryItemDurability(slot)
        if current and maximum and maximum > 0 and current * 100 < maximum * threshold then
            return true
        end
    end

    return false
end

local function RepairAtVendor()
    if AutoRepairStuffMode == "off" or not CanMerchantRepair() then
        return
    end

    local cost, canRepair = GetRepairAllCost()
    if not canRepair or not cost or cost <= 0 or not MeetsDurabilityThreshold() then
        return
    end

    if AutoRepairStuffMode == "guild" and CanGuildBankRepair() then
        local allowance = GetGuildBankWithdrawMoney()
        -- A value of -1 means the guild rank has no daily limit.
        if allowance == -1 or (allowance and allowance >= cost) then
            RepairAndReport(cost, true)
            return
        end
    end

    if GetMoney() >= cost then
        RepairAndReport(cost, false)
    else
        print("Auto Repair: Not enough gold to repair all items.")
    end
end

local function RegisterRepairSettings()
    local category = Settings.RegisterVerticalLayoutCategory("Auto Repair")
    local setting = Settings.RegisterProxySetting(category, modeVariable,
        Settings.VarType.String, "Repair mode", "personal",
        function() return AutoRepairStuffMode end,
        function(mode) AutoRepairStuffMode = mode end)

    Settings.CreateDropdown(category, setting, function()
        local options = Settings.CreateControlTextContainer()
        options:Add("personal", "Your gold")
        options:Add("guild", "Guild gold when available")
        options:Add("off", "Off")
        return options:GetData()
    end, "Choose how to pay for automatic repairs. Guild mode uses your gold if your rank or allowance does not cover the repair.")
    local hideMessage = Settings.RegisterAddOnSetting(category, "AutoRepairStuffHideRepairMessage",
        "hideRepairMessage", AutoRepairStuffOptions, Settings.VarType.Boolean, "Hide repair message", false)
    Settings.CreateCheckbox(category, hideMessage, "Hide the chat message after a successful automatic repair.")

    local threshold = Settings.RegisterAddOnSetting(category, "AutoRepairStuffDurabilityThreshold",
        "durabilityThreshold", AutoRepairStuffOptions, Settings.VarType.Number, "Durability threshold", 0)
    local slider = Settings.CreateSliderOptions(0, 100, 1)
    slider:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        if value == 0 then
            return "Any damage"
        end
        return ("%d%%"):format(value)
    end)
    Settings.CreateSlider(category, threshold, slider,
        "Repair when any equipped item falls below this percentage. Any damage repairs whenever the vendor has a repair bill.")
    Settings.RegisterAddOnCategory(category)
end

local function SetRepairMode(message)
    local mode = message:match("^%s*(%S*)%s*$")
    mode = mode and mode:lower()

    if mode == "personal" or mode == "guild" or mode == "off" then
        AutoRepairStuffMode = mode
        Settings.NotifyUpdate(modeVariable)
    elseif mode ~= "" then
        print("Auto Repair: Use /autorepair [personal | guild | off].")
        return
    end

    print("Auto Repair: " .. AutoRepairStuffMode)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" then
        if loadedAddon ~= addonName then
            return
        end

        if AutoRepairStuffMode ~= "guild" and AutoRepairStuffMode ~= "off" then
            AutoRepairStuffMode = "personal"
        end

        if type(AutoRepairStuffOptions) ~= "table" then
            AutoRepairStuffOptions = {}
        end
        AutoRepairStuffOptions.hideRepairMessage = AutoRepairStuffOptions.hideRepairMessage == true
        local threshold = tonumber(AutoRepairStuffOptions.durabilityThreshold) or 0
        AutoRepairStuffOptions.durabilityThreshold = math.max(0, math.min(100, math.floor(threshold)))

        SLASH_AUTOREPAIRSTUFF1 = "/autorepair"
        SlashCmdList.AUTOREPAIRSTUFF = SetRepairMode
        self:UnregisterEvent("ADDON_LOADED")
        self:RegisterEvent("MERCHANT_SHOW")
        self:RegisterEvent("MERCHANT_CLOSED")
        RegisterRepairSettings()
        return
    end

    StopRepairCheck()
    if event == "MERCHANT_SHOW" then
        RepairAtVendor()
    end
end)
