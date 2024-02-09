ESX = exports["es_extended"]:getSharedObject()

function SendDiscordLog(message)
    local webhook = Crafting.DiscordWebhook
    if webhook ~= "" then
        local embeds = {
            {
                -- The color of the embed in decimal format
                ["color"] = 3447003, -- You can change this to any color you prefer
                ["title"] = "**Crafting Log**", -- Title of the embed
                ["description"] = message, -- The message you want to send
                ["footer"] = {
                    ["text"] = "HW Scripts | Crafting System", -- Footer text
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ") -- Timestamp of when the message is sent
            }
        }

        PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({embeds = embeds}), { ['Content-Type'] = 'application/json' })
    else
        print("Discord webhook URL is not configured.")
    end
end


RegisterServerEvent('hw_crafting:CraftingSuccess')
AddEventHandler('hw_crafting:CraftingSuccess', function(CraftItem)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local item = Crafting.Items[CraftItem]
    for itemname, v in pairs(item.needs) do
        xPlayer.removeInventoryItem(itemname, v.count)
    end
    if CraftItem == "weapon_pistol" or CraftItem == "weapon_combatpistol" then
        xPlayer.addWeapon(CraftItem, 0)
    else
        xPlayer.addInventoryItem(CraftItem, 1)
    end
    -- Discord Log
    SendDiscordLog(xPlayer.getName() .. " has successfully crafted " .. item.label)
    TriggerClientEvent('esx:showNotification', src, "You have made ~b~"..item.label.."~w~!")

    if Crafting.Debug then
        print("^7[^1DEBUG^7] A player crafted an item")
    end

end)

RegisterServerEvent('hw_crafting:CraftingFailed')
AddEventHandler('hw_crafting:CraftingFailed', function(CraftItem)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local item = Crafting.Items[CraftItem]
    local rand = math.random(1,50)
    if rand < 50 then
        for itemname, v in pairs(item.needs) do
            xPlayer.removeInventoryItem(itemname, v.count)
        end
    end
    -- Discord Log
    SendDiscordLog(xPlayer.getName() .. " failed to craft " .. item.label)
    TriggerClientEvent('esx:showNotification', src, "~r~It failed to make ~b~"..item.label)

    if Crafting.Debug then
        print("^7[^1DEBUG^7] A player failed crafting an item")
    end

end)

-- Callback to get your crafting points from the database
ESX.RegisterServerCallback('hw_crafting:GetSkillLevel', function(source, cb)
    local identifier = GetPlayerIdentifiers(source)[1]
    MySQL.Async.fetchAll('SELECT * FROM user_levels WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] ~= nil then
            cb(tonumber(result[1].crafting))
        else
            MySQL.Async.execute('INSERT INTO user_levels (identifier, crafting) VALUES (@identifier, @crafting)', {
                ['@identifier'] = identifier,
                ['@crafting'] = 1
            }, function(rowsChanged)
                return cb(1)
            end)
        end
    end)
end)
-- Check if you have the items
ESX.RegisterServerCallback('hw_crafting:HasTheItems', function(source, cb, CraftItem)
    local xPlayer = ESX.GetPlayerFromId(source)
    local item = Crafting.Items[CraftItem]
    for itemname, v in pairs(item.needs) do
        if xPlayer.getInventoryItem(itemname).count < v.count then
            cb(false)
        end
    end
    cb(true)
end)
-- Adding crafting points function (you can change the math random to whatever you want)
function AddCraftingPoints(source)
    local identifier =  GetPlayerIdentifiers(source)[1]
    MySQL.Sync.execute('UPDATE user_levels SET crafting = crafting + @crafting WHERE identifier = @identifier', {
        ['@crafting'] = math.random(1, 3),
        ['@identifier'] = identifier
    })
end
-- Remove crafting points function (you can change the math random to whatever you want)
function RemoveCraftingPoints(source)
    local identifier = GetPlayerIdentifiers(source)[1]
    MySQL.Async.fetchAll('SELECT * FROM user_levels WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(result1)
        local craftinglevel = tonumber(result1[1].crafting)
        if craftinglevel > 0 then
            MySQL.Sync.execute('UPDATE user_levels SET crafting = crafting - @crafting WHERE identifier = @identifier', {
                ['@crafting'] = 1,
                ['@identifier'] = identifier
            })
        else
            -- nothing has to happen here
            return
	    end
	end)
end
-- Function to get players crafting level
function GetCraftingLevel(source)
    local identifier = GetPlayerIdentifiers(source)[1]
    MySQL.Async.fetchAll('SELECT * FROM user_levels WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] ~= nil then
            return tonumber(result[1].crafting)
        else
            MySQL.Async.execute('INSERT INTO user_levels (identifier, crafting) VALUES (@identifier, @crafting)', {
                ['@identifier'] = identifier,
                ['@crafting'] = 1
            }, function(rowsChanged)
                return 1
            end)
        end
    end)
end