-- Copyright (c) 2023 Branko Majic
-- Provided under MIT license. See LICENSE for details.


local utils = {}


--- Determines setter and getter functions for logistic slots for passed-in entity.
--
-- Characters and spidertrons use differently named functions, and this little helper allows to abstract away this
-- detail.
--
-- @param entity LuaEntity Entity for which to get setter/getter.
--
-- @return {function, function} Setter and getter function for manipulating the logistics slots of an entity.
--
function utils.get_logistic_slot_functions(entity)

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
function utils.is_blank_deconstruction_planner(item_stack)
    if item_stack.valid_for_read and
        item_stack.is_deconstruction_item and
        table_size(item_stack.entity_filters) == 0 and
        table_size(item_stack.tile_filters) == 0 then

        return true
    end

    return false
end


--- Determines what entity the current GUI is opened for.
--
-- In case of an invalid entity, an error message is shown to the player.
--
-- @param LuaPlayer Player to check the opened GUI for.
--
-- @return LuaEntity|nil Entity for which the current GUI is opened for, or nil in case of unsupported entity.
--
function utils.get_opened_gui_entity(player)

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


return utils
