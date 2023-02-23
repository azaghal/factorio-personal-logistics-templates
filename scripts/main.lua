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


--- Updates global mod data.
--
-- @param old_version string Old version of mod.
-- @param new_version string New version of mod.
--
function main.update_data(old_version, new_version)

    -- Ensure the GUI definition is up-to-date for all players.
    if new_version ~= old_version then
        for index, player in pairs(game.players) do
            gui.destroy_player_data(player)
            gui.initialise(player)
        end
    end

end


--- Destroys all mod data for a specific player.
--
-- @param player LuaPlayer Player for which to destroy the data.
--
function main.destroy_player_data(player)
    gui.destroy_player_data(player)

    global.player_data[player.index] = nil
end


--- Checks if passed-in list of blueprint entities constitute a valid personal logistics template that can be imported.
--
-- @param entities {BlueprintEntity} List of blueprint entities to check.
--
-- @return bool true if passed-in entities constitute valid personal logistics template, false otherwise.
--
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


--- Determines setter and getter functions for logistic slots for passed-in entity.
--
-- Characters and spidertrons use differently named functions, and this little helper allows to abstract away this
-- detail.
--
-- @param entity LuaEntity Entity for which to get setter/getter.
--
-- @return {function, function} Setter and getter function for manipulating the logistics slots of an entity.
--
function main.get_logistic_slot_functions(entity)

    local set_logistic_slot =
        entity.type == "character" and entity.set_personal_logistic_slot or
        entity.type == "spider-vehicle" and entity.set_vehicle_logistic_slot or
        nil

    local get_logistic_slot =
        entity.type == "character" and entity.get_personal_logistic_slot or
        entity.type == "spider-vehicle" and entity.get_vehicle_logistic_slot or
        nil

    return set_logistic_slot, get_logistic_slot
end


--- Checks if item stack is a blank deconstruction planner.
--
-- @param item_stack LuaItemStack Item stack to check.
--
-- @return bool true if passted-in item stack is blank deconstruction planner, false otherwise.
--
function main.is_blank_deconstruction_planner(item_stack)
    if item_stack.valid_for_read and
        item_stack.is_deconstruction_item and
        table_size(item_stack.entity_filters) == 0 and
        table_size(item_stack.tile_filters) == 0 then

        return true
    end

    return false
end


--- Updates visibility of import/export buttons for a given player based on held cursor stack.
--
-- @param player LuaPlayer Player for which to update button visibility.
--
function main.update_button_visibility(player)

    -- Retrieve list of blueprint entities.
    local entities = player.get_blueprint_entities() or {}

    if not player.character or not player.force.character_logistic_requests then
        gui.set_mode(player, "hidden")
    elseif table_size(entities) == 0 and player.is_cursor_blueprint() and player.cursor_stack.valid_for_read then
        gui.set_mode(player, "export")
    elseif main.is_valid_template(entities) then
        gui.set_mode(player, "import")
    elseif main.is_blank_deconstruction_planner(player.cursor_stack) then
        gui.set_mode(player, "modify")
    else
        gui.set_mode(player, "hidden")
    end

end


--- Determines what entity the current GUI is opened for.
--
-- In case of an invalid entity, an error message is shown to the player.
--
-- @param LuaPlayer Player to check the opened GUI for.
--
-- @return LuaEntity|nil Entity for which the current GUI is opened for, or nil in case of unsupported entity.
--
function main.get_opened_gui_entity(player)

    if player.opened_gui_type == defines.gui_type.controller then
        entity = player.character
    elseif player.opened_gui_type == defines.gui_type.entity and player.opened.type == "spider-vehicle" then
        entity = player.opened
    else
        player.print({"error.plt-invalid-entity"})
        entity = nil
    end

    return entity
end


--- Converts personal logistics configuration into list of (blueprint entity) constant combinators.
--
-- Each row of personal logistics configuration is represented as a single constant combinator in the resulting
-- list. Top row of constant combinator filters is used for minimum quantities, while bottom represents maximum
-- quantities. Filter icons are used to represent item in the slot.
--
-- Since combinators use _signed_ 32-bit integers, and personal logistics slots use _unsigned_ 32-bit integers,
-- overflowing values are stored as negative values, with -1 corresponding to 2147483648, and -2147483648 corresponding
-- to 4294967296.
--
-- @param entity LuaEntity Entity for which to generate the list of blueprint entities. Must be character or spidetron.
--
-- @return {BlueprintEntity} List of blueprint entities (constant combinators) representing the configuration.
--
function main.personal_logistics_configuration_to_constant_combinators(entity)

    -- Determine function to invoke for reading logistic slot information.
    local get_logistic_slot =
        entity.type == "character" and entity.get_personal_logistic_slot or
        entity.type == "spider-vehicle" and entity.get_vehicle_logistic_slot

    -- Initialise list of constant combinators that will hold the template. Combinators are meant to be laid-out in a
    -- grid pattern, and populated column by column. Each column can contain a maximum of 10 combinators. Make sure that
    -- at least one combinator is added in case there are no personal logistics requests configured.
    local combinators = {}

    for i = 1, entity.request_slot_count == 0 and 1 or math.ceil(entity.request_slot_count/10) do
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
    for slot_index = 1, entity.request_slot_count do
        local slot = get_logistic_slot(slot_index)

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

    -- Determine what entity is targeted.
    local entity = main.get_opened_gui_entity(player)
    if not entity then
        return
    end

    local combinators = main.personal_logistics_configuration_to_constant_combinators(entity)

    -- Set the blueprint content and change default icons.
    player.cursor_stack.set_blueprint_entities(combinators)
    player.cursor_stack.blueprint_icons = {
        { index = 1, signal = {type = "virtual", name = "signal-P"}},
        { index = 2, signal = {type = "virtual", name = "signal-L"}},
        { index = 3, signal = {type = "virtual", name = "signal-T"}},
    }

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

    -- Determine what entity is targeted.
    local entity = main.get_opened_gui_entity(player)
    if not entity then
        return
    end

    -- Determine what functions to use for setting/getting logistic slot information.
    local set_logistic_slot, get_logistic_slot = main.get_logistic_slot_functions(entity)

    -- Clear the existing configuration.
    for i = 1, entity.request_slot_count do
        set_logistic_slot(i, {})
    end

    -- Set slot configuration from blueprint template.
    local slots = main.constant_combinators_to_personal_logistics_configuration(entities)
    for slot_index, slot in pairs(slots) do
        set_logistic_slot(slot_index, slot)
    end
end


--- Add and increment personal logistics requests using the held blueprint.
--
-- @param player LuaPlayer Player that has requested the increment.
--
function main.increment(player)
    local entities = player.get_blueprint_entities()

    if not main.is_valid_template(entities) then
        player.print({"error.plt-invalid-template"})
        return
    end

    -- Determine what entity is targeted.
    local entity = main.get_opened_gui_entity(player)
    if not entity then
        return
    end

    -- Determine what functions to use for setting/getting logistic slot information.
    local set_logistic_slot, get_logistic_slot = main.get_logistic_slot_functions(entity)

    -- Retrieve existing requests.
    local already_requesting = {}
    for slot_index = 1, entity.request_slot_count do
        local slot = get_logistic_slot(slot_index)
        if slot.name then
            slot.index = slot_index
            already_requesting[slot.name] = slot
        end
    end

    -- Convert constant combinators into personal logistics configuration.
    local slots = main.constant_combinators_to_personal_logistics_configuration(entities)

    -- Find first empty row for appending new requests.
    local empty_slot_index = math.ceil(entity.request_slot_count / 10) * 10 + 1

    -- Process all slots, update existing slots, and append new ones.
    for _, slot in pairs(slots) do
        local slot_index

        if already_requesting[slot.name] then
            slot.min = slot.min + already_requesting[slot.name].min
            slot.max = slot.max + already_requesting[slot.name].max
            slot.min = slot.min < 4294967296 and slot.min or 4294967295
            slot.max = slot.max < 4294967296 and slot.max or 4294967295
            slot_index = already_requesting[slot.name].index
        else
            slot_index = empty_slot_index
            empty_slot_index = empty_slot_index + 1
        end

        set_logistic_slot(slot_index, slot)
    end
end


--- Decrement personal logistics requests using the held blueprint.
--
-- @param player LuaPlayer Player that has requested the decrement.
--
function main.decrement(player)
    local entities = player.get_blueprint_entities()

    if not main.is_valid_template(entities) then
        player.print({"error.plt-invalid-template"})
        return
    end

    -- Determine what entity is targeted.
    local entity = main.get_opened_gui_entity(player)
    if not entity then
        return
    end

    -- Determine what functions to use for setting/getting logistic slot information.
    local set_logistic_slot, get_logistic_slot = main.get_logistic_slot_functions(entity)

    -- Retrieve existing requests.
    local already_requesting = {}
    for slot_index = 1, entity.request_slot_count do
        local slot = get_logistic_slot(slot_index)
        if slot.name then
            slot.index = slot_index
            already_requesting[slot.name] = slot
        end
    end

    -- Convert constant combinators into personal logistics configuration.
    local slots = main.constant_combinators_to_personal_logistics_configuration(entities)

    -- Process all slots, decrementing the requested minimum/maximum quantities.
    for _, slot in pairs(slots) do

        if already_requesting[slot.name] then

            -- Clear the request slot if minimum is already at zero, and new maximum would end-up being zero as well
            -- (this makes more sense from player's perspective). Otherwise keep the slot, but with decremented values.
            if already_requesting[slot.name].min == 0 and slot.max >= already_requesting[slot.name].max then

                set_logistic_slot(already_requesting[slot.name].index, {})

            else

                -- Decrement minimum first. It must be greater than zero.
                slot.min = already_requesting[slot.name].min - slot.min
                slot.min = slot.min > 0 and slot.min or 0

                -- Decrementing maximum is more complex.  4294967295 corresponds to infinity. We apply the following logic:
                --
                --   1. (infinity - infinity) = infinity
                --   2. (infinity - finite) = infinity
                --   3. (finite - finite) = finite (perform substraction)
                slot.max =
                    already_requesting[slot.name].max == 4294967295 and slot.max == 4294967295 and 4294967295 or
                    already_requesting[slot.name].max == 4294967295 and 4294967295 or
                    already_requesting[slot.name].max - slot.max 

                -- Maximum must be greater or equal to minimum.
                slot.max =
                    slot.min > slot.max and slot.min or
                    slot.max

                set_logistic_slot(already_requesting[slot.name].index, slot)

            end

        end

    end
end


--- Set logistics requests using the held blueprint.
--
-- @param player LuaPlayer Player that has requested the setting of requests.
--
function main.set(player)
    local entities = player.get_blueprint_entities()

    if not main.is_valid_template(entities) then
        player.print({"error.plt-invalid-template"})
        return
    end

    -- Determine what entity is targeted.
    local entity = main.get_opened_gui_entity(player)
    if not entity then
        return
    end

    -- Determine what functions to use for setting/getting logistic slot information.
    local set_logistic_slot, get_logistic_slot = main.get_logistic_slot_functions(entity)

    -- Retrieve existing requests.
    local already_requesting = {}
    for slot_index = 1, entity.request_slot_count do
        local slot = get_logistic_slot(slot_index)
        if slot.name then
            slot.index = slot_index
            already_requesting[slot.name] = slot
        end
    end

    -- Convert constant combinators into personal logistics configuration.
    local slots = main.constant_combinators_to_personal_logistics_configuration(entities)

    -- Find first empty row for appending new requests.
    local empty_slot_index = math.ceil(entity.request_slot_count / 10) * 10 + 1

    -- Process all slots, update existing slots, and append new ones.
    for _, slot in pairs(slots) do
        local slot_index

        if already_requesting[slot.name] then
            slot_index = already_requesting[slot.name].index
        else
            slot_index = empty_slot_index
            empty_slot_index = empty_slot_index + 1
        end

        set_logistic_slot(slot_index, slot)
    end
end


--- Sets-up auto-trashing of all currently unrequested items (setting the maximum amount to zero).
--
-- This function is primarily useful for working with construction spidertrons to ensure their inventories never get
-- filled-up.
--
-- @param player LuaPlayer Player that has requested the auto-trashing.
--
function main.auto_trash(player)

    -- Determine what entity is targeted.
    local entity = main.get_opened_gui_entity(player)
    if not entity then
        return
    end

    -- Determine what functions to use for setting/getting logistic slot information.
    local set_logistic_slot, get_logistic_slot = main.get_logistic_slot_functions(entity)

    -- Retrieve existing requests.
    local already_requesting = {}
    for slot_index = 1, entity.request_slot_count do
        local slot = get_logistic_slot(slot_index)
        if slot.name then
            already_requesting[slot.name] = true
        end
    end

    -- Exclude all blueprint and hidden items.
    local item_prototypes = game.get_filtered_item_prototypes({
            {filter = "type", type = "blueprint", invert = true},
            {filter = "type", type = "deconstruction-item", invert = true, mode = "and"},
            {filter = "type", type = "upgrade-item", invert = true, mode = "and"},
            {filter = "type", type = "blueprint-book", invert = true, mode = "and"},
            {filter = "flag", flag = "hidden", invert = true, mode = "and"}
    })

    -- Retrieve information about the existing auto-trash requests.
    local auto_trash_info = main.get_auto_trash_info(entity)

    -- Keep track of slot index where request should be added. Setting this to zero ensures we can compare it later on
    -- against auto_trash_info.append in the loop.
    local slot_index = 0

    -- Populate auto-trash slots.
    for item_name, item_prototype in pairs(item_prototypes) do

        if not already_requesting[item_name] then

            -- Grab first gap in auto-trash slots (if any).
            local slot_gap = table.remove(auto_trash_info.gaps, 1)

            -- Try to populate auto-trash slot gaps first, then start appending at the end.
            slot_index =
                slot_gap ~= nil and slot_gap or
                slot_index < auto_trash_info.append and auto_trash_info.append or
                slot_index + 1

            local slot = {
                name = item_name,
                min = 0,
                max = 0
            }
            set_logistic_slot(slot_index, slot)

        end

    end

end


--- Retrieves information about auto-trash requests in entity's personal logistics requests.
--
-- Function can be used even in situations where no auto-trash requests are defined - this way it is easy to determine
-- where to start adding new ones.
--
-- Returned information covers:
--
--   - Index of slot where the auto-trash requests begin at (always beginning of the row).
--   - First available slot index that can be used for appending new auto-trash requests.
--   - List of empty slot indices corresponding to gaps in auto-trash slot layout.
--   - Mapping between slot indices and request parameters.
--   - Mapping between requested item names and request parameters.
--
-- @param entity LuaEntity Entity for which to fetch the information.
--
-- @return { from = int, append = int, gaps = { int }, slots = { int = LogisticParameters }, items = { string = LogisticParameters  } }
--
function main.get_auto_trash_info(entity)

    -- Set-up structure for storing information.
    local auto_trash_info = {
        from = nil,
        append = nil,
        gaps = {},
        slots = {},
        items = {}
    }

    -- Bail-out early if not a single request is set. Leave the first two rows blank.
    if entity.request_slot_count == 0 then

        -- Leave two blank rows, no requests are set whatsoever.
        auto_trash_info.from = 21
        auto_trash_info.append = 21

        return auto_trash_info

    end

    -- Determine getter function for logistic slot information.
    local _, get_logistic_slot = main.get_logistic_slot_functions(entity)

    -- Keep track of previous and current row type.
    local row_type, previous_row_type

    -- Assume that there are no auto-trash requests set. Leave a gap of two blank rows after the final request.
    auto_trash_info.from = entity.request_slot_count - entity.request_slot_count % 10 + 31

    -- Iterate personal logistics requests back-to-front.
    for slot_index = entity.request_slot_count, 1, -1 do

        -- Fetch the slot and determine its type.
        local slot = get_logistic_slot(slot_index)
        local slot_type =
            slot.name == nil and "blank" or
            slot.min == 0 and slot.max == 0 and "trash" or
            "regular"

        -- Drop out of the loop the moment we hit the first regular request.
        if slot_type == "regular" then
            break
        end

        -- Row type is based on most significant slot type in the row (regular > trash > blank). Row type can never be
        -- regular at this point because we bail-out from the loop the moment we hit a regular request.
        row_type =
            (row_type == "trash" or slot_type == "trash") and "trash" or
            slot_type

        -- Detect when a whole row has been read.
        if slot_index % 10 == 1 then

            -- Auto-trash requests are always separated by at least one blank row from regular requests. Every time a
            -- blank row has bin hit, the auto-trash starting point is updated. Previous row is checked in order to try
            -- to leave two blank rows in-between regular and auto-trash requests (if possible).
            if row_type == "blank" and previous_row_type == "blank" then
                auto_trash_info.from = slot_index + 20
            elseif row_type == "blank" then
                auto_trash_info.from = slot_index + 10
            end

            -- Reset row types for next iteration.
            previous_row_type = row_type
            row_type = nil
        end

    end

    -- Figure out slot index where new auto-trash requests can be added at.
    auto_trash_info.append =
        auto_trash_info.from > entity.request_slot_count and auto_trash_info.from or
        entity.request_slot_count + 1

    -- Now that we know where the auto-trash requests begin, extract information for all of them.
    for slot_index = auto_trash_info.from, entity.request_slot_count do

        local slot = get_logistic_slot(slot_index)

        if slot.name then
            auto_trash_info.slots[slot_index] = slot
            auto_trash_info.items[slot.name] = slot
        else
            table.insert(auto_trash_info.gaps, slot_index)
        end

    end

    return auto_trash_info
end


--- Clears all auto-trash personal logistics requests.
--
-- @param player LuaPlayer Player that has requested clearing of all auto-trash requests.
--
function main.clear_auto_trash(player)

    -- Determine what entity is targeted.
    local entity = main.get_opened_gui_entity(player)
    if not entity then
        return
    end

    -- Determine what function to use for setting logistic slot information.
    local set_logistic_slot, _ = main.get_logistic_slot_functions(entity)

    -- Fetch information about auto-trash slots.
    local auto_trash_info = main.get_auto_trash_info(entity)

    -- Clear auto-trash slots.
    for slot_index, _ in pairs(auto_trash_info.slots) do
       set_logistic_slot(slot_index, { name=nil } )
    end

end


--- Clears all personal logistic requests.
--
-- @param player LuaPlayer Player that has requested clearing of all requests.
--
function main.clear_requests_button(player)

    -- Determine what entity is targeted.
    local entity = main.get_opened_gui_entity(player)
    if not entity then
        return
    end

    -- Determine what functions to use for setting/getting logistic slot information.
    local set_logistic_slot, get_logistic_slot = main.get_logistic_slot_functions(entity)

    -- Clear all requests.
    for slot_index = 1, entity.request_slot_count do
        set_logistic_slot(slot_index, {})
    end

end


--- Registers GUI handlers for the module.
--
function main.register_gui_handlers()
    gui.register_handler("plt_export_button", main.export)
    gui.register_handler("plt_import_button", main.import)
    gui.register_handler("plt_increment_button", main.increment)
    gui.register_handler("plt_decrement_button", main.decrement)
    gui.register_handler("plt_set_button", main.set)
    gui.register_handler("plt_auto_trash_button", main.auto_trash)
    gui.register_handler("plt_clear_auto_trash_button", main.clear_auto_trash)
    gui.register_handler("plt_clear_requests_button", main.clear_requests_button)
end


return main
