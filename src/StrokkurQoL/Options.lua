local ADDON_NAME, ns = ...

local WIDTH, HEIGHT = 460, 420
local ROW_GAP = 8
local SUB_INDENT = 24

local window       -- Hauptfenster
local widgets = {} -- alle Checkboxen, zum Aktualisieren

---------------------------------------------------------------------------
-- Bausteine
---------------------------------------------------------------------------

local function SetCheckEnabled(cb, enabled)
    cb:SetEnabled(enabled)
    local c = enabled and NORMAL_FONT_COLOR or GRAY_FONT_COLOR
    cb.label:SetTextColor(c:GetRGB())
    cb.desc:SetAlpha(enabled and 1 or 0.5)
end

local function RefreshAll()
    for _, cb in ipairs(widgets) do
        cb:SetChecked(ns.Get(cb.key) and true or false)
        if cb.parentKey then
            SetCheckEnabled(cb, ns.Get(cb.parentKey) and true or false)
        end
    end
end

-- Erzeugt eine Checkbox mit Titel und Beschreibung.
-- Gibt die Checkbox und die verbrauchte Höhe zurück.
local function CreateCheck(parent, x, y, def, parentKey)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetSize(26, 26)
    cb.key = def.key
    cb.parentKey = parentKey

    cb.label = cb:CreateFontString(nil, "OVERLAY", parentKey and "GameFontNormal" or "GameFontNormalLarge")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    cb.label:SetText(def.name)

    cb.desc = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cb.desc:SetPoint("TOPLEFT", cb.label, "BOTTOMLEFT", 0, -3)
    cb.desc:SetWidth(WIDTH - 90 - x)
    cb.desc:SetJustifyH("LEFT")
    cb.desc:SetText(def.tooltip or "")

    cb:SetScript("OnClick", function(self)
        ns.Set(self.key, self:GetChecked())
        PlaySound(self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
            or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        RefreshAll()
    end)

    table.insert(widgets, cb)
    local height = 26 + (def.tooltip and (cb.desc:GetStringHeight() + 2) or 0)
    return cb, height
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------

local function BuildWindow()
    local f = CreateFrame("Frame", "StrokkurQoLSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnShow", RefreshAll)
    f:Hide()
    tinsert(UISpecialFrames, f:GetName()) -- mit ESC schließen

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", 0, -5)
    f.title:SetText("StrokkurQoL – Einstellungen")

    -- Scrollbereich für die Module
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -32)
    scroll:SetPoint("BOTTOMRIGHT", -32, 44)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WIDTH - 50, 1)
    scroll:SetScrollChild(content)

    local y = -4
    for i, mod in ipairs(ns.modules) do
        if i > 1 then
            local line = content:CreateTexture(nil, "ARTWORK")
            line:SetColorTexture(1, 1, 1, 0.12)
            line:SetHeight(1)
            line:SetPoint("TOPLEFT", 4, y - 2)
            line:SetPoint("TOPRIGHT", -4, y - 2)
            y = y - ROW_GAP
        end

        local _, h = CreateCheck(content, 4, y, mod)
        y = y - h - ROW_GAP

        for _, opt in ipairs(mod.options or {}) do
            local _, sh = CreateCheck(content, 4 + SUB_INDENT, y, opt, mod.key)
            y = y - sh - ROW_GAP
        end
    end
    content:SetHeight(-y)

    -- Untere Leiste
    local reset = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    reset:SetSize(140, 24)
    reset:SetPoint("BOTTOMLEFT", 12, 12)
    reset:SetText("Standardwerte")
    reset:SetScript("OnClick", function()
        ns.ResetToDefaults()
        RefreshAll()
        ns.Print("Einstellungen zurückgesetzt.")
    end)

    local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    close:SetSize(100, 24)
    close:SetPoint("BOTTOMRIGHT", -12, 12)
    close:SetText(CLOSE)
    close:SetScript("OnClick", function() f:Hide() end)

    local version = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    version:SetPoint("BOTTOM", 0, 18)
    version:SetText("v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))

    return f
end

function ns.ToggleSettings()
    window = window or BuildWindow()
    window:SetShown(not window:IsShown())
end

---------------------------------------------------------------------------
-- Einstiegspunkte: Blizzard-Optionen, Addon-Compartment, Slash-Befehl
---------------------------------------------------------------------------

function ns.InitOptions()
    -- Kleine Seite in Esc > Optionen > AddOns, die auf das eigene Fenster verweist
    local panel = CreateFrame("Frame")
    local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    text:SetPoint("TOPLEFT", 16, -16)
    text:SetText("StrokkurQoL")

    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(200, 26)
    btn:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -12)
    btn:SetText("Einstellungen öffnen")
    btn:SetScript("OnClick", function()
        HideUIPanel(SettingsPanel)
        ns.ToggleSettings()
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, "StrokkurQoL")
    Settings.RegisterAddOnCategory(category)
end

-- In der TOC als AddonCompartmentFunc eingetragen (Addon-Knopf an der Minimap)
function StrokkurQoL_OnAddonCompartmentClick()
    ns.ToggleSettings()
end

SLASH_STROKKURQOL1 = "/sqol"
SlashCmdList.STROKKURQOL = function()
    ns.ToggleSettings()
end
