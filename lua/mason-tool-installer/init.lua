local mr = require 'mason-registry'

local SETTINGS = {
  ensure_installed = {},
  auto_update = false,
  auto_install = true,
}

local setup = function(settings)
  SETTINGS = vim.tbl_deep_extend('force', SETTINGS, settings)
end

local show = function(msg)
  vim.schedule_wrap(print(string.format('[mason-tool-installer] %s', msg)))
end

local show_error = function(msg)
  vim.schedule_wrap(vim.api.nvim_err_writeln(string.format('[mason-tool-installer] %s', msg)))
end

local do_install = function(p, version)
  if version ~= nil then
    show(string.format('%s: updating to %s', p.name, version))
  else
    show(string.format('%s: installing', p.name))
  end
  p:on('install:success', function()
    show(string.format('%s: successfully installed', p.name))
  end)
  p:on('install:failed', function()
    show_error(string.format('%s: failed to install', p.name))
  end)
  p:install { version = version }
end

local check_install = function()
  print 'check install'
  for _, item in ipairs(SETTINGS['ensure_installed']) do
    local name, version, auto_update
    if type(item) == 'table' then
      name = item[1]
      version = item.version
      auto_update = item.auto_update
    else
      name = item
    end
    local p = mr.get_package(name)
    if p:is_installed() then
      if version ~= nil then
        p:get_installed_version(function(ok, installed_version)
          if ok and installed_version ~= version then
            do_install(p, version)
          end
        end)
      elseif auto_update or (auto_update == nil and SETTINGS['auto_update']) then
        p:check_new_version(function(ok, version)
          if ok then
            do_install(p, version.latest_version)
          end
        end)
      end
    else
      do_install(p, version)
    end
  end
end

local auto_install = function()
  if SETTINGS['auto_install'] then
    check_install()
  end
end

return {
  auto_install = auto_install,
  check_install = check_install,
  setup = setup,
}
