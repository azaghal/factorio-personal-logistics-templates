-- Copyright (c) 2023 Branko Majic
-- Provided under MIT license. See LICENSE for details.


local template = require("scripts.template")
local utils = require("scripts.utils")


local requests = {}


--- Exports personal logistics requests template into passed-in blueprint.
--
-- @param entity LuaEntity Entity to export the template for.
-- @param blueprint LuaItemStack Empty blueprint to export the blueprints into.
--
function requests.export_into_blueprint(entity, blueprint)

    local combinators = template.personal_logistics_configuration_to_constant_combinators(entity)

    -- Set the blueprint content and change default icons.
    blueprint.set_blueprint_entities(combinators)
    blueprint.blueprint_icons = {
        { index = 1, signal = {type = "virtual", name = "signal-P"}},
        { index = 2, signal = {type = "virtual", name = "signal-L"}},
        { index = 3, signal = {type = "virtual", name = "signal-T"}},
    }

end


--- Clears personal logistics requests for passed-in entity.
--
-- @param entity LuaEntity Entity for which to clear the requests.
--
function requests.clear(entity)

    local set_logistic_slot, _ = utils.get_logistic_slot_functions(entity)

    for i = 1, entity.request_slot_count do
        set_logistic_slot(i, {})
    end

end


--- Appends personal logistics requests with preserved layout.
--
-- @param entity LuaEntity Entity for which to append the requests.
-- @param logistic_requests {uint = LogisticParameters} Mapping between personal logistic slot indices and slot configurations.
--
function requests.append(entity, logistic_requests)

    local set_logistic_slot, _ = utils.get_logistic_slot_functions(entity)

    -- Find offset for appending new requests from the first available row.
    local slot_index_offset = math.ceil(entity.request_slot_count / 10) * 10

    for slot_index, slot in pairs(logistic_requests) do
        set_logistic_slot(slot_index_offset + slot_index, slot)
    end

end


--- Increments and appends (new) personal logistics requests.
--
-- @param entity LuaEntity Entity for which to increment the requests.
-- @param logistic_requests {uint = LogisticParameters} Mapping between personal logistic slot indices and slot configurations.
--
function requests.increment(entity, logistic_requests)

    local set_logistic_slot, get_logistic_slot = utils.get_logistic_slot_functions(entity)

    -- Retrieve existing requests.
    local already_requesting = {}
    for slot_index = 1, entity.request_slot_count do
        local slot = get_logistic_slot(slot_index)
        if slot.name then
            slot.index = slot_index
            already_requesting[slot.name] = slot
        end
    end

    -- Find first empty row for appending new requests.
    local empty_slot_index = math.ceil(entity.request_slot_count / 10) * 10 + 1

    -- Process all slots, update existing slots, and append new ones.
    for _, slot in pairs(logistic_requests) do
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


--- Decrements personal logistics requests by amounts specified via passed-in logistics requests.
--
-- @param entity LuaEntity Entity for which to decrement the requests.
-- @param logistic_requests {uint = LogisticParameters} Mapping between personal logistic slot indices and slot configurations.
--
function requests.decrement(entity, logistic_requests)

    -- Determine what functions to use for setting/getting logistic slot information.
    local set_logistic_slot, get_logistic_slot = utils.get_logistic_slot_functions(entity)

    -- Retrieve existing requests.
    local already_requesting = {}
    for slot_index = 1, entity.request_slot_count do
        local slot = get_logistic_slot(slot_index)
        if slot.name then
            slot.index = slot_index
            already_requesting[slot.name] = slot
        end
    end

    -- Process all slots, decrementing the requested minimum/maximum quantities.
    for _, slot in pairs(logistic_requests) do

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


--- Sets personal logistics requests to exact values as specified via passed-in logistics requests.
--
-- @param entity LuaEntity Entity for which to set the requests.
-- @param logistic_requests {uint = LogisticParameters} Mapping between personal logistic slot indices and slot configurations.
--
function requests.set(entity, logistic_requests)

    -- Determine what functions to use for setting/getting logistic slot information.
    local set_logistic_slot, get_logistic_slot = utils.get_logistic_slot_functions(entity)

    -- Retrieve existing requests.
    local already_requesting = {}
    for slot_index = 1, entity.request_slot_count do
        local slot = get_logistic_slot(slot_index)
        if slot.name then
            slot.index = slot_index
            already_requesting[slot.name] = slot
        end
    end

    -- Find first empty row for appending new requests.
    local empty_slot_index = math.ceil(entity.request_slot_count / 10) * 10 + 1

    -- Process all slots, update existing slots, and append new ones.
    for _, slot in pairs(logistic_requests) do
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


--- Sets auto-trash requests for an entity.
--
-- Primarily useful for working with construction spidertrons to ensure their inventories never get filled-up.
--
-- @param entity LuaEntity Entity for which to set the requests.
--
function requests.auto_trash(entity)

    -- Determine what functions to use for setting/getting logistic slot information.
    local set_logistic_slot, get_logistic_slot = utils.get_logistic_slot_functions(entity)

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
    local auto_trash_info = template.get_auto_trash_info(entity)

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


--- Clear auto-trash requests for an entity.
--
-- @param entity LuaEntity Entity for which to clear the auto-trash requests.
--
function requests.clear_auto_trash(entity)

    -- Determine what function to use for setting logistic slot information.
    local set_logistic_slot, _ = utils.get_logistic_slot_functions(entity)

    -- Fetch information about auto-trash slots.
    local auto_trash_info = template.get_auto_trash_info(entity)

    -- Clear auto-trash slots.
    for slot_index, _ in pairs(auto_trash_info.slots) do
       set_logistic_slot(slot_index, { name=nil } )
    end

end


return requests
