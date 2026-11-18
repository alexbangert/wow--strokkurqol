local _, ns = ...

ns.RegisterModule({
    key = "autoRepair",
    name = "Automatisch reparieren",
    tooltip = "Repariert beim Händler automatisch alle Gegenstände.",
    default = true,
    options = {
        {
            key = "autoRepairGuild",
            name = "Gildenbank bevorzugen",
            tooltip = "Zuerst mit Gildengold reparieren, falls erlaubt.",
            default = true,
        },
    },
    events = {
        MERCHANT_SHOW = function()
            if not CanMerchantRepair() then return end
            local cost, canRepair = GetRepairAllCost()
            if not canRepair or cost <= 0 then return end

            if ns.Get("autoRepairGuild") and IsInGuild() and CanGuildBankRepair and CanGuildBankRepair() then
                RepairAllItems(true)
                ns.Print("Repariert (Gilde):", GetMoneyString(cost))
            elseif GetMoney() >= cost then
                RepairAllItems(false)
                ns.Print("Repariert:", GetMoneyString(cost))
            else
                ns.Print("Nicht genug Gold zum Reparieren.")
            end
        end,
    },
})
