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


--- Appends personal logistics requests specified via passed-in combinators.
--
-- @param entity LuaEntity Entity for which to append the requests.
-- @param combinators {LuaEntity} List of constant combinators defining the requests.
--
function requests.append(entity, combinators)

    local set_logistic_slot, _ = utils.get_logistic_slot_functions(entity)
    local slots = template.constant_combinators_to_personal_logistics_configuration(combinators)

    -- Find offset for appending new requests from the first available row.
    local slot_index_offset = math.ceil(entity.request_slot_count / 10) * 10

    for slot_index, slot in pairs(slots) do
        set_logistic_slot(slot_index_offset + slot_index, slot)
    end

end


--- Increments personal logistics requests by amounts specified via passed-in combinators.
--
-- @param entity LuaEntity Entity for which to increment the requests.
-- @param combinators {LuaEntity} List of constant combinators defining the requests.
--
function requests.increment(entity, combinators)

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

    -- Convert constant combinators into personal logistics configuration.
    local slots = template.constant_combinators_to_personal_logistics_configuration(combinators)

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


--- Decrements personal logistics requests by amounts specified via passed-in combinators.
--
-- @param entity LuaEntity Entity for which to decrement the requests.
-- @param combinators {LuaEntity} List of constant combinators defining the requests.
--
function requests.decrement(entity, combinators)

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

    -- Convert constant combinators into personal logistics configuration.
    local slots = template.constant_combinators_to_personal_logistics_configuration(combinators)

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


return requests
