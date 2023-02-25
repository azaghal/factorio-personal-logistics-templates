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


return requests
