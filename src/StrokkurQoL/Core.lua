local ADDON_NAME, ns = ...

ns.modules = {}
ns.defaults = {}

local frame = CreateFrame("Frame")
local handlers = {} -- event -> { fn, fn, ... }

function ns.Print(...)
    print("|cff33bbffStrokkurQoL|r:", ...)
end

-- Registriert ein Modul.
-- def = {
--   key      = "autoRepair",            -- Haupt-Schalter (boolean in SavedVariables)
--   name     = "Automatisch reparieren",
--   tooltip  = "Beschreibung, wird im Einstellungsfenster angezeigt",
--   default  = true,
--   options  = {                        -- optionale Unter-Einstellungen
--     { key = "autoRepairGuild", name = "...", tooltip = "...", default = true },
--   },
--   events   = { MERCHANT_SHOW = function(...) end },
--   apply    = function() end,           -- optional: wird beim Login und bei jeder
--                                        -- Änderung einer Einstellung des Moduls
--                                        -- aufgerufen (auch wenn es deaktiviert wird)
-- }
local keyOwner = {} -- Einstellungs-Schlüssel -> Modul

function ns.RegisterModule(def)
    table.insert(ns.modules, def)
    ns.defaults[def.key] = def.default
    keyOwner[def.key] = def
    for _, opt in ipairs(def.options or {}) do
        ns.defaults[opt.key] = opt.default
        keyOwner[opt.key] = def
    end
    for event, fn in pairs(def.events or {}) do
        if not handlers[event] then
            handlers[event] = {}
            frame:RegisterEvent(event)
        end
        table.insert(handlers[event], function(...)
            if ns.db and ns.db[def.key] then fn(...) end
        end)
    end
end

function ns.Get(key)
    return ns.db and ns.db[key]
end

local function ApplyModule(mod)
    if mod and mod.apply then mod.apply() end
end

function ns.Set(key, value)
    ns.db[key] = value
    ApplyModule(keyOwner[key])
end

function ns.ResetToDefaults()
    for k, v in pairs(ns.defaults) do
        ns.db[k] = v
    end
    for _, mod in ipairs(ns.modules) do ApplyModule(mod) end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON_NAME then return end
        StrokkurQoLDB = StrokkurQoLDB or {}
        for k, v in pairs(ns.defaults) do
            if StrokkurQoLDB[k] == nil then StrokkurQoLDB[k] = v end
        end
        ns.db = StrokkurQoLDB
        if ns.InitOptions then ns.InitOptions() end
        frame:UnregisterEvent("ADDON_LOADED")
        return
    end
    if event == "PLAYER_LOGIN" then
        for _, mod in ipairs(ns.modules) do ApplyModule(mod) end
        return
    end
    local list = handlers[event]
    if list then
        for _, fn in ipairs(list) do fn(...) end
    end
end)
