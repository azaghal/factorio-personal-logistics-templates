-- Copyright (c) 2022 Branko Majic
-- Provided under MIT license. See LICENSE for details.


local gui = require("scripts.gui")


local main = {}


--- Initialises global mod data.
--
function main.initialise_data()
    global.player_data = global.player_data or {}

    for index, player in pairs(game.players) do
        main.initialise_player_data(player)
    end
end


--- Initialiases global mod data for a specific player.
--
-- @param player LuaPlayer Player for which to initialise the data.
--
function main.initialise_player_data(player)
    global.player_data[player.index] = global.player_data[player.index] or {}

    gui.initialise(player)
end


--- Destroys all mod data for a specific player.
--
-- @param player LuaPlayer Player for which to destroy the data.
--
function main.destroy_player_data(player)
    gui.destroy(player)

    global.player_data[player.index] = nil
end


--- Checks if passed-in list of blueprint entities constitute a valid personal logistics template that can be imported.
--
-- @param entities {BlueprintEntity} List of blueprint entities to check.

function main.is_valid_template(entities)

    -- List must contain at least one entity.
    if table_size(entities) == 0 then
        return false
    end

    -- Only constant combinators are allowed in the list.
    for _, entity in pairs(entities) do
        if entity.name ~= "constant-combinator" then
            return false
        end
    end

    return true
end


--- Updates visibility of import/export buttons for a given player based on held cursor stack.
--
-- @param player LuaPlayer Player for which to update button visibility.
--
function main.update_button_visibility(player)

    -- Retrieve list of blueprint entities.
    local entities = player.get_blueprint_entities() or {}

    if table_size(entities) == 0 and player.is_cursor_blueprint() and player.cursor_stack.valid_for_read then
        gui.set_mode(player, "export")
    elseif main.is_valid_template(entities) then
        gui.set_mode(player, "import")
    else
        gui.set_mode(player, "hidden")
    end

end


--- Exports personal logistics template for given player into a held (empty) blueprint.
--
-- @param player LuaPlayer Player that has requested the export.
--
function main.export(player)

    -- Make sure the player is holding an empty blueprint before proceeding.
    if not (player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == "blueprint") then
        player.print({"error.plt-blueprint-not-empty"})
        return
    end

    -- Initialise list of constant combinators that will hold the template. Combinators are meant to be laid-out in a
    -- grid pattern, and populated column by column. Each column can contain a maximum of 10 combinators.
    local combinators = {}

    for i = 1, math.ceil(player.character.request_slot_count/10) do
        local x = math.ceil(i/10)
        local y = i % 10
        y = y == 0 and 10 or y

        table.insert(
            combinators,
            {
                entity_number = i,
                name = "constant-combinator",
                position = {x = x, y = y},
                control_behavior = {filters = {}}
            }
        )
    end

    -- Populate combinators with slot requests.
    for slot_index = 1, player.character.request_slot_count do
        local slot = player.get_personal_logistic_slot(slot_index)

        if slot.name then
            -- Each combinator stores configuration for 10 slots at a time.
            local combinator = combinators[math.ceil(slot_index/10)]
            local filter_index = slot_index % 10
            filter_index = filter_index == 0 and 10 or filter_index

            -- Minimum quantities are kept in the first row of a combinator.
            local filter_min = {
                index = filter_index,
                -- Combinator signals use signed 32-bit integers, whereas slot requests are unsigned 32-bit
                -- integers. Store overflows as negative values.
                count = slot.min > 2147483647 and - slot.min + 2147483647 or slot.min,
                signal = {
                    name = slot.name,
                    type = "item"
                }
            }
            table.insert(combinator.control_behavior.filters, filter_min)

            -- Maximum quantities are kept in the second row of a combinator.
            local filter_max = {
                index = filter_index + 10,
                -- Combinator signals use signed 32-bit integers, whereas slot requests are unsigned 32-bit
                -- integers. Store overflows as negative values.
                count = slot.max > 2147483647 and - slot.max + 2147483647 or slot.max,
                signal = {
                    name = slot.name,
                    type = "item"
                }
            }
            table.insert(combinator.control_behavior.filters, filter_max)
        end
    end

    player.cursor_stack.set_blueprint_entities(combinators)
end


--- Registers GUI handlers for the module.
--
function main.register_gui_handlers()
    gui.register_handler("plt_export_button", main.export)
end


return main
