local addonName = ...
local repairCheck

local function StopRepairCheck()
    if repairCheck then
        repairCheck:Cancel()
        repairCheck = nil
    end
end

local function RepairAndReport(cost, useGuildFunds)
    local funding = useGuildFunds and "guild funds" or "personal gold"
    RepairAllItems(useGuildFunds)

    -- The vendor cost updates after the server processes the repair.
    repairCheck = C_Timer.NewTicker(0.1, function()
        if GetRepairAllCost() == 0 then
            StopRepairCheck()
            print(("Auto Repair: Repaired for %s using %s."):format(
                GetCoinTextureString(cost), funding))
        end
    end, 30)
end

local function RepairAtVendor()
    if AutoRepairStuffMode == "off" or not CanMerchantRepair() then
        return
    end

    local cost, canRepair = GetRepairAllCost()
    if not canRepair or not cost or cost <= 0 then
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

local function SetRepairMode(message)
    local mode = message:match("^%s*(%S*)%s*$")
    mode = mode and mode:lower()

    if mode == "personal" or mode == "guild" or mode == "off" then
        AutoRepairStuffMode = mode
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

        SLASH_AUTOREPAIRSTUFF1 = "/autorepair"
        SlashCmdList.AUTOREPAIRSTUFF = SetRepairMode
        self:UnregisterEvent("ADDON_LOADED")
        self:RegisterEvent("MERCHANT_SHOW")
        self:RegisterEvent("MERCHANT_CLOSED")
        return
    end

    StopRepairCheck()
    if event == "MERCHANT_SHOW" then
        RepairAtVendor()
    end
end)
