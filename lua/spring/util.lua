local M = {}

local E = require "spring.enum"
local H = require "spring.helper"

local spring_find_table = {}
local spring_preview_table = {}

M.get_annotation = function(method)
  local annotation = E.annotation[method .. "_MAPPING"]
  return annotation
end

M.get_method = function(annotation)
  local method = string.upper((annotation):gsub("^@", ""):gsub("Mapping$", ""))
  return method
end

local get_mapping_value = function(mapping, path)
  if not mapping then
    return ""
  end

  local _, value = mapping:match '@(.-)%("%s*(/.-)"%)'

  if value then
    return value
  end

  local variable_value = mapping:match "%((.-)%)"

  if variable_value then
    local cmd = "rg" .. " " .. variable_value .. " " .. "=" .. " " .. path
    local grep_results = H.run_cmd(cmd)
    variable_value = grep_results:match '"(%/.-)"'

    return variable_value
  end

  return ""
end

local get_grep_cmd = function(annotation)
  if annotation == E.annotation.REQUEST_MAPPING then
    return "rg '@RequestMapping(([^)]*?))' --multiline --type java --line-number --trim --vimgrep"
  elseif annotation == E.annotation.GET_MAPPING then
    return "rg '@GetMapping' --multiline --type java --line-number --trim --vimgrep"
  elseif annotation == E.annotation.POST_MAPPING then
    return "rg '@PostMapping' --multiline --type java --line-number --trim --vimgrep"
  elseif annotation == E.annotation.PUT_MAPPING then
    return "rg '@PutMapping' --multiline --type java --line-number --trim --vimgrep"
  elseif annotation == E.annotation.DELETE_MAPPING then
    return "rg '@DeleteMapping' --multiline --type java --line-number --trim --vimgrep"
  else
    local message = "not supported annotation: " .. annotation
    error(message)
  end
end

M.get_request_mapping_value = function(path)
  if not spring_find_table[path] then
    return ""
  end

  if not spring_find_table[path][E.annotation.REQUEST_MAPPING] then
    return ""
  end

  if not spring_find_table[path][E.annotation.REQUEST_MAPPING].value then
    return ""
  end

  return spring_find_table[path][E.annotation.REQUEST_MAPPING].value
end

M.get_request_mapping_line_number = function(path)
  if not spring_find_table[path] then
    return nil
  end

  if not spring_find_table[path][E.annotation.REQUEST_MAPPING] then
    return nil
  end

  if not spring_find_table[path][E.annotation.REQUEST_MAPPING].line_number then
    return nil
  end

  return spring_find_table[path][E.annotation.REQUEST_MAPPING].line_number
end

M.set_spring_tables = function()
  spring_find_table = {}
  spring_preview_table = {}
end

M.get_spring_priview_table = function()
  return spring_preview_table
end

M.get_spring_find_table = function()
  return spring_find_table
end

M.create_spring_preview_table = function(annotation)
  for path, mapping_object in pairs(spring_find_table) do
    local request_mapping_value = M.get_request_mapping_value(path)
    if mapping_object[annotation] then
      local method = M.get_method(annotation)
      for _, mapping_item in ipairs(mapping_object[annotation]) do
        local method_mapping_value = mapping_item.value or ""
        local line_number = mapping_item.line_number
        local column = mapping_item.column
        local endpoint = method .. " " .. request_mapping_value .. method_mapping_value
        spring_preview_table[endpoint] = {
          path = path,
          line_number = line_number,
          column = column,
        }
      end
    end
  end
end

local is_mapping_has_option = function(mapping)
  if H.find(mapping, "method =") ~= nil then
    return true
  end

  if H.find(mapping, "value =") ~= nil then
    return true
  end

  return false
end

local is_request_mapping = function(mapping)
  return H.find(mapping, E.annotation.REQUEST_MAPPING)
end

local function split_request_mapping(mapping_string)
  local path, line_number, column = H.split(mapping_string, ":")
  local mapping_methods = mapping_string:match "method%s*=%s*(%b{})"
  local mapping_method = mapping_string:match "method%s*=%s*([%w%.]+)"
  local mapping_value = mapping_string:match 'value%s*=%s*"([^"]+)"' or ""
  local mapping_method_list = {}

  if mapping_methods then
    for method in mapping_methods:gmatch "RequestMethod%.(%w+)" do
      table.insert(mapping_method_list, method:gsub("RequestMethod%.", ""):upper())
    end
  elseif mapping_method then
    table.insert(mapping_method_list, mapping_method:gsub("RequestMethod%.", ""):upper())
  else
    mapping_method_list = nil
  end

  return path, line_number, column, mapping_value, mapping_method_list
end

local function split_object_mapping(mapping_string)
  local path, line_number, column = H.split(mapping_string, ":")
  local mapping_value = mapping_string:match 'value%s*=%s*"([^"]+)"' or ""

  return path, line_number, column, mapping_value
end

local create_find_table_if_not_exist = function(path, annotation)
  if not spring_find_table[path] then
    spring_find_table[path] = {}
  end

  if not spring_find_table[path][annotation] then
    spring_find_table[path][annotation] = {}
  end
end

local insert_to_find_table = function(opts)
  table.insert(
    spring_find_table[opts.path][opts.annotation],
    { value = opts.value, line_number = opts.line_number, column = opts.column }
  )
end

local insert_to_find_request_table = function(opts)
  spring_find_table[opts.path][opts.annotation] =
    { value = opts.value, line_number = opts.line_number, column = opts.column }
end

M.create_spring_find_table = function(annotation)
  local cmd = get_grep_cmd(annotation)
  local grep_results = H.run_cmd(cmd)

  for line in tostring(grep_results):gmatch "[^\n]+" do
    if is_mapping_has_option(line) then
      if is_request_mapping(line) then
        local path, line_number, column, mapping_value, mapping_method = split_request_mapping(line)
        if mapping_method == nil then
          create_find_table_if_not_exist(path, E.annotation.REQUEST_MAPPING)
          insert_to_find_request_table {
            path = path,
            annotation = annotation,
            mapping = mapping_value,
            line_number = line_number,
            column = column,
          }
        else
          for _, method in ipairs(mapping_method) do
            local mapping_annotation = M.get_annotation(method)
            create_find_table_if_not_exist(path, mapping_annotation)
            insert_to_find_table {
              path = path,
              annotation = mapping_annotation,
              value = mapping_value,
              line_number = line_number,
              column = column,
            }
          end
        end
      else
        local path, line_number, column, mapping_value = split_object_mapping(line)
        create_find_table_if_not_exist(path, annotation)
        insert_to_find_table {
          path = path,
          annotation = annotation,
          value = mapping_value,
          line_number = line_number,
          column = column,
        }
      end
    else
      local path, line_number, column, value = H.split(line, ":")
      create_find_table_if_not_exist(path, annotation)
      if annotation == E.annotation.REQUEST_MAPPING then
        insert_to_find_request_table {
          path = path,
          annotation = annotation,
          value = get_mapping_value(value, path),
          line_number = line_number,
          column = column,
        }
      else
        insert_to_find_table {
          path = path,
          annotation = annotation,
          value = get_mapping_value(value, path),
          line_number = line_number,
          column = column,
        }
      end
    end
  end
end

M.set_cursor_on_entry = function(entry, bufnr, winid)
  local lnum, lnend = entry.lnum - 1, (entry.lnend or entry.lnum) - 1
  local middle_ln = math.floor(lnum + (lnend - lnum) / 2) + 1
  pcall(vim.api.nvim_win_set_cursor, winid, { middle_ln, 0 })
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd "norm! zz"
  end)
end

M.check_duplicate = function(find_table)
  local seen = {} -- 중복을 확인하기 위한 테이블 생성
  local result = {} -- 중복이 제거된 값을 담을 새로운 테이블

  for _, value in ipairs(find_table) do
    if not seen[value] then
      table.insert(result, value) -- 중복되지 않는 값만 새로운 테이블에 추가
      seen[value] = true -- 해당 값이 등장했음을 표시
    end
  end

  return result
end

return M
