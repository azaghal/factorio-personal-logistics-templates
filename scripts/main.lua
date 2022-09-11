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

    for _, entity in pairs(entities) do
        -- Only constant combinators are allowed in the list.
        if entity.name ~= "constant-combinator" then
            return false
        end

        -- All constant combinator filters must specify an item.
        for _, filter in pairs(entity.control_behavior and entity.control_behavior.filters or {}) do
            if filter.signal.type ~= "item" then
                return false
            end
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


--- Converts personal logistics configuration into list of (blueprint entity) constant combinators.
--
-- Each row of personal logistics configuration is represented as a single constant combinator in the resulting
-- list. Top row of constant combinator filters is used for minimum quantities, while bottom represents maximum
-- quantities. Filter icons are used to represent item in the slot.
--
-- Since combinators use _unsigned_ 32-bit integers, and personal logistics slots use _signed_ 32-bit integers,
-- overflowing values are stored as negative values, with -1 corresponding to 2147483648, and -2147483648 corresponding
-- to 4294967296.
--
-- @param player LuaPlayer Player for which to generate the list of blueprint entities.
--
-- @return {BlueprintEntity} List of blueprint entities (constant combinators) representing the configuration.
--
function main.personal_logistics_configuration_to_constant_combinators(player)

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

    return combinators
end


--- Converts list of (blueprint entity) constant combinators into personal logistics configuration.
--
-- @param combinators {BlueprintEntity} List of constant combinators representing personal logistics configuration.
--
-- @return {uint = LogisticParameters} Mapping between personal logistic slot indices and slot configuration.
--
function main.constant_combinators_to_personal_logistics_configuration(combinators)
    local slots = {}

    -- Sort the passed-in combinators by coordinates - this should ensure that even if player was creating/modifying the
    -- template by hand, it should still have correct ordering.
    local sort_by_coordinate = function(elem1, elem2)
        if elem1.position.x < elem2.position.x then
            return true
        elseif elem1.position.x == elem2.position.x and elem1.position.y < elem2.position.y then
            return true
        end

        return false
    end
    table.sort(combinators, sort_by_coordinate)

    -- Each combinator represents one row of personal logistics.
    for row, combinator in pairs(combinators) do
        local slot_offset = (row - 1) * 10
        if combinator.control_behavior then
            -- Extract slot configuration from combinator filters.
            for _, filter in pairs(combinator.control_behavior.filters) do
                if filter.index <= 10 then
                    local slot_index = slot_offset + filter.index
                    slots[slot_index] = slots[slot_index] or {}
                    slots[slot_index].name = filter.signal.name
                    slots[slot_index].min = filter.count < 0 and - filter.count + 2147483647 or filter.count
                else
                    local slot_index = slot_offset + filter.index - 10
                    slots[slot_index] = slots[slot_index] or {}
                    slots[slot_index].name = filter.signal.name
                    slots[slot_index].max = filter.count < 0 and - filter.count + 2147483647 or filter.count
                end
            end
        end
    end

    -- Ensure that minimum is not greater than maximum (to avoid game crashes when setting the slot configuration).
    for slot_index, slot in pairs(slots) do
        if slot.min and slot.max and slot.min > slot.max then
            slot.min, slot.max = slot.max, slot.min
        end
    end

    return slots
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

    local entities = main.personal_logistics_configuration_to_constant_combinators(player)

    player.cursor_stack.set_blueprint_entities(entities)

    main.update_button_visibility(player)
end


--- Imports personal logistics template from a held blueprint.
--
-- @param player LuaPlayer Player that has requested the import.
--
function main.import(player)
    local entities = player.get_blueprint_entities()

    if not main.is_valid_template(entities) then
        player.print({"error.plt-invalid-template"})
        return
    end

    -- Clear the existing configuration.
    for i = 1, player.character.request_slot_count do
        player.set_personal_logistic_slot(i, {})
    end

    -- Set slot configuration from blueprint template.
    local slots = main.constant_combinators_to_personal_logistics_configuration(entities)
    for slot_index, slot in pairs(slots) do
        player.set_personal_logistic_slot(slot_index, slot)
    end
end


--- Registers GUI handlers for the module.
--
function main.register_gui_handlers()
    gui.register_handler("plt_export_button", main.export)
    gui.register_handler("plt_import_button", main.import)
end


return main
