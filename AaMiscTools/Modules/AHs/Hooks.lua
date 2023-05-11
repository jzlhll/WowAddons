local _, addon = ...;addon.AHCustomScan = addon.AHCustomScan or {}
local AH = addon.AHCustomScan

local curItemLink, shownItemLink
local lastShowTs = 0

AH.initHookTooltip = function()
    if GameTooltip.SetItemKey then
        local func = function(tip, itemID, itemLevel, itemSuffix)
          local info = C_TooltipInfo.GetItemKey(itemID, itemLevel, itemSuffix)
          if info == nil then
            return
          end
          TooltipUtil.SurfaceArgs(info)
          if info.hyperlink then
            local hyperlink = info.hyperlink
            -- Necessary as for recipes the crafted item is returned info.hyperlink,
            -- so we check we actually got the recipe item
            if GetItemInfoInstant(info.hyperlink) ~= itemID then
              hyperlink = select(2, GetItemInfo(itemID))
            end
            AH:ShowTipWithPricing(tip, hyperlink)
          end
        end

        hooksecurefunc(GameTooltip, "SetItemKey", func)
    end

    hooksecurefunc(GameTooltip, "SetItemByID", function (tip, itemID)
        if not itemID then
          return
        end
        local itemLink = select(2, GetItemInfo(itemID))
        AH:ShowTipWithPricing(tip, itemLink)
    end)

    if GameTooltip.SetTradeSkillItem then -- Classic
        hooksecurefunc(GameTooltip, "SetTradeSkillItem", function(tip, recipeIndex, reagentIndex)
            local itemLink, itemCount
            if reagentIndex ~= nil then
              itemLink = GetTradeSkillReagentItemLink(recipeIndex, reagentIndex)
              itemCount = select(3, GetTradeSkillReagentInfo(recipeIndex, reagentIndex))
            else
              itemLink = GetTradeSkillItemLink(recipeIndex);
              itemCount  = GetTradeSkillNumMade(recipeIndex);
            end
            AH:ShowTipWithPricing(tip, itemLink)
        end)
    end

    if GameTooltip.SetAuctionItem then
        hooksecurefunc(GameTooltip, "SetAuctionItem", function(tip, viewType, index)
          local itemCount = select(3, GetAuctionItemInfo(viewType, index))
          local itemLink = GetAuctionItemLink(viewType, index)
      
          AH:ShowTipWithPricing(tip, itemLink)
        end)
    end

    hooksecurefunc(GameTooltip, "SetInventoryItem", function(tip, unit, slot)
        local itemLink = GetInventoryItemLink(unit, slot)
        AH:ShowTipWithPricing(tip, itemLink)
    end)

    hooksecurefunc(GameTooltip, "SetGuildBankItem", function(tip, tab, slot)
        local itemLink = GetGuildBankItemLink(tab, slot)
      
        AH:ShowTipWithPricing(tip, itemLink)
    end)

    hooksecurefunc(GameTooltip, "SetLootItem", function (tip, slot)
        if LootSlotHasItem(slot) then
          local itemLink, _, _ = GetLootSlotLink(slot);
          AH:ShowTipWithPricing(tip, itemLink)
        end
    end)

    -- hooksecurefunc(GameTooltip, "SetInboxItem", function(tip, index, attachIndex)
    --     local attachmentIndex = attachIndex or 1
    --     local itemLink = GetInboxItemLink(index, attachmentIndex)
    --     AH:ShowTipWithPricing(tip, itemLink)
    -- end)

    local SetHyperlink = function (tip, link)
        if not link then return end
        AH:ShowTipWithPricing(tip, link)
    end

    local SetBagItem = function(tip, bag, slot)
        local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
    
        if C_Item.DoesItemExist(itemLocation) then
          local itemLink = C_Item.GetItemLink(itemLocation)
          AH:ShowTipWithPricing(tip, itemLink)
          curItemLink = itemLink
        end
    end

    hooksecurefunc(ItemRefTooltip, "SetHyperlink", SetHyperlink)
    hooksecurefunc(GameTooltip, "SetBagItem", SetBagItem)
    hooksecurefunc(ItemRefTooltip, "SetBagItem", SetBagItem)
end