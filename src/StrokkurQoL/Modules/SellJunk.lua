local _, ns = ...

local function SellJunkManually()
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == Enum.ItemQuality.Poor and not info.hasNoValue then
                C_Container.UseContainerItem(bag, slot)
            end
        end
    end
end

ns.RegisterModule({
    key = "sellJunk",
    name = "Grauen Plunder verkaufen",
    tooltip = "Verkauft beim Händler automatisch alle grauen Gegenstände.",
    default = true,
    events = {
        MERCHANT_SHOW = function()
            if C_MerchantFrame and C_MerchantFrame.SellAllJunkItems then
                C_MerchantFrame.SellAllJunkItems()
            else
                SellJunkManually()
            end
        end,
    },
})
