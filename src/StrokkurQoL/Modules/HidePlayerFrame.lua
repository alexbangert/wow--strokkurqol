local _, ns = ...

-- Blendet das Blizzard-Spielerframe aus, solange die Raid- bzw. Party-Container
-- von EUIStandaloneRaidFrames sichtbar sind.
--
-- Statt EUIs Sichtbarkeitsregeln nachzubauen (Solo, Arena, Small Raid, ...),
-- hängen wir uns per SecureHandlerWrapScript an OnShow/OnHide der beiden
-- EUI-Container. Der Code läuft dadurch in der sicheren Umgebung und darf das
-- Spielerframe auch im Kampf ein-/ausblenden.

local UPDATE = [[
    local player = self:GetFrameRef("player")
    if not player then return end
    local hide = false
    if self:GetAttribute("enabled") then
        local raid, party = self:GetFrameRef("raid"), self:GetFrameRef("party")
        if self:GetAttribute("hideRaid") and raid and raid:IsShown() then hide = true end
        if self:GetAttribute("hideParty") and party and party:IsShown() then hide = true end
    end
    if hide then player:Hide() else player:Show() end
]]

local ctrl          -- sicherer Handler-Frame
local hooked = false
local touched = false -- haben wir das Spielerframe je verändert?
local pending = false
local retries = 0

local function FindContainers()
    local raid = _G.EUICoreStandaloneRaidFramesRaidFrameContainer
    local partyHeader = _G.ERFPartyHeader
    local party = partyHeader and partyHeader:GetParent()
    return raid, party
end

local function Hook()
    if hooked then return true end
    local raid, party = FindContainers()
    if not raid or not party then return false end
    if not raid:IsProtected() or not party:IsProtected() then
        ns.Print("EUI-Raidframes nicht geschützt – Spielerframe kann nicht gekoppelt werden.")
        return false
    end

    ctrl = CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate")
    ctrl:SetFrameRef("player", PlayerFrame)
    ctrl:SetFrameRef("raid", raid)
    ctrl:SetFrameRef("party", party)
    ctrl:SetAttribute("update", UPDATE)

    local body = [[ owner:RunAttribute("update") ]]
    for _, f in ipairs({ raid, party }) do
        SecureHandlerWrapScript(f, "OnShow", ctrl, body)
        SecureHandlerWrapScript(f, "OnHide", ctrl, body)
    end
    hooked = true
    return true
end

local waiter = CreateFrame("Frame")

function ns.ApplyHidePlayerFrame()
    local enabled = ns.Get("hidePlayerFrame") and true or false
    if not enabled and not touched then return end -- nie aktiv gewesen: nichts anfassen

    -- Attribute an geschützten Frames lassen sich im Kampf nicht setzen
    if InCombatLockdown() then
        pending = true
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    if not Hook() then
        -- EUI baut seine Container erst nach dem Login; ein paar Sekunden lang erneut versuchen
        if enabled and retries < 15 then
            retries = retries + 1
            C_Timer.After(1, ns.ApplyHidePlayerFrame)
        end
        return
    end

    ctrl:SetAttribute("enabled", enabled)
    ctrl:SetAttribute("hideRaid", ns.Get("hidePlayerInRaid") and true or false)
    ctrl:SetAttribute("hideParty", ns.Get("hidePlayerInParty") and true or false)
    SecureHandlerExecute(ctrl, [[ self:RunAttribute("update") ]])
    touched = true
end

waiter:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent(event)
    if not pending then return end
    pending = false
    ns.ApplyHidePlayerFrame()
end)

ns.RegisterModule({
    key = "hidePlayerFrame",
    name = "Spielerframe bei Raidframes ausblenden",
    tooltip = "Versteckt dein Spielerframe, solange die EUI-Raid- bzw. Partyframes angezeigt werden (inkl. \"Show When Solo\"). Funktioniert auch im Kampf.",
    default = false,
    options = {
        {
            key = "hidePlayerInRaid",
            name = "Bei Raidframes ausblenden",
            tooltip = "Wenn die EUI-Raidframes sichtbar sind.",
            default = true,
        },
        {
            key = "hidePlayerInParty",
            name = "Bei Partyframes ausblenden",
            tooltip = "Wenn die EUI-Partyframes sichtbar sind.",
            default = true,
        },
    },
    apply = ns.ApplyHidePlayerFrame,
})
