local httpService = game:GetService('HttpService')

local SaveManager = {} do
	SaveManager.Folder = 'Xyro/rivals/'
	SaveManager.Ignore = {}
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) 
				return { type = 'Toggle', idx = idx, value = object.Value } 
			end,
			Load = function(idx, data)
				if Toggles[idx] then 
					Toggles[idx]:SetValue(data.value)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = 'Slider', idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue(data.value)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = 'Dropdown', idx = idx, value = object.Value, mutli = object.Multi }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue(data.value)
				end
			end,
		},
		ColorPicker = {
			Save = function(idx, object)
				return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
				end
			end,
		},
		KeyPicker = {
			Save = function(idx, object)
				return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue({ data.key, data.mode })
				end
			end,
		},

		Input = {
			Save = function(idx, object)
				return { type = 'Input', idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] and type(data.text) == 'string' then
					Options[idx]:SetValue(data.text)
				end
			end,
		},
	}

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

	function SaveManager:Save(name)
		if (not name) then
			return false, 'no config file is selected'
		end

		local fullPath = self.Folder .. '/settings/' .. name .. '.json'

		local data = {
			objects = {}
		}

		for idx, toggle in next, Toggles do
			if self.Ignore[idx] then continue end

			table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
		end

		for idx, option in next, Options do
			if not self.Parser[option.Type] then continue end
			if self.Ignore[idx] then continue end

			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end	

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then
			return false, 'failed to encode data'
		end

		writefile(fullPath, encoded)
		return true
	end

	function SaveManager:Load(name)
		if (not name) then
			return false, 'no config file is selected'
		end
		
		local file = self.Folder .. '/settings/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success then return false, 'decode error' end

		for _, option in next, decoded.objects do
			if self.Parser[option.type] then
				task.spawn(function() self.Parser[option.type].Load(option.idx, option) end)
			end
		end

		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({ 
			"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
			"ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {
			self.Folder,
			self.Folder .. '/themes',
			self.Folder .. '/settings'
		}

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function SaveManager:RefreshConfigList()
		local list = listfiles(self.Folder .. '/settings')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then

				local pos = file:find('.json', 1, true)
				local start = pos

				local char = file:sub(pos, pos)
				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1, start - 1))
				end
			end
		end
		
		return out
	end

	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	function SaveManager:LoadAutoloadConfig()
		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('failed to load autoload config: ' .. err)
			end

			self.Library:Notify(string.format('auto loaded config %q', name))
		end
	end


	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, 'Must set SaveManager.Library')

		local section = tab:AddRightGroupbox('configuration')

		section:AddInput('SaveManager_ConfigName', { Text = 'config name' })
		section:AddDropdown('SaveManager_ConfigList', { Text = 'config list', Values = self:RefreshConfigList(), AllowNull = true })

		section:AddDivider()

		local createBtn = section:AddButton({ Text = 'create', DoubleClick = true, Func = function()
			local name = Options.SaveManager_ConfigName.Value

			if name:gsub(' ', '') == '' then
				return self.Library:Notify('invalid config name (empty)', 2)
			end

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('failed to save config: ' .. err)
			end

			self.Library:Notify(string.format('created config %q', name))

			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end})
		createBtn:AddButton({ Text = 'load', DoubleClick = true, Func = function()
			local name = Options.SaveManager_ConfigList.Value

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('failed to load config: ' .. err)
			end

			self.Library:Notify(string.format('loaded config %q', name))
		end})

		local overwriteBtn = section:AddButton({ Text = 'overwrite', DoubleClick = true, Func = function()
			local name = Options.SaveManager_ConfigList.Value

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('failed to overwrite config: ' .. err)
			end

			self.Library:Notify(string.format('overwrote config %q', name))
		end})
		overwriteBtn:AddButton({ Text = 'refresh list', Func = function()
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end})

		local autoloadBtn = section:AddButton({ Text = 'set as autoload', Func = function()
			local name = Options.SaveManager_ConfigList.Value
			writefile(self.Folder .. '/settings/autoload.txt', name)
			SaveManager.AutoloadLabel:SetText('current autoload config: ' .. name)
			self.Library:Notify(string.format('set %q to auto load', name))
		end})
		autoloadBtn:AddButton({ Text = 'remove autoload', Func = function()
			local autoload_path = self.Folder .. '/settings/autoload.txt'
			if not isfile(autoload_path) then
				return self.Library:Notify('no autoload config set', 2)
			end
			pcall(delfile, autoload_path)
			if isfile(autoload_path) then
				return self.Library:Notify('failed to remove autoload config', 3)
			end
			SaveManager.AutoloadLabel:SetText('current autoload config: none')
			self.Library:Notify('autoload removed')
		end})

		section:AddDivider()

		section:AddInput('SaveManager_ConfigString', { Text = 'config string (paste)', Default = '' })
		local pasteBtn = section:AddButton({ Text = 'load string', DoubleClick = true, Func = function()
			local raw = Options.SaveManager_ConfigString.Value
			if type(raw) ~= 'string' or raw:gsub('%s', '') == '' then
				return self.Library:Notify('no config string pasted', 2)
			end

			local ok, data = pcall(httpService.JSONDecode, httpService, raw)
			if not ok or type(data) ~= 'table' or type(data.objects) ~= 'table' then
				return self.Library:Notify('invalid config string', 3)
			end

			for _, option in next, data.objects do
				if self.Parser[option.type] then
					task.spawn(function() self.Parser[option.type].Load(option.idx, option) end)
				end
			end

			self.Library:Notify('loaded config from string')
		end})
		pasteBtn:AddButton({ Text = 'copy string', Func = function()
			local name = Options.SaveManager_ConfigList.Value
			if not name then
				return self.Library:Notify('no config selected', 2)
			end

			local path = self.Folder .. '/settings/' .. name .. '.json'
			if not isfile(path) then
				return self.Library:Notify('invalid file', 2)
			end

			local ok, raw = pcall(readfile, path)
			if not ok then
				return self.Library:Notify('failed to read config', 3)
			end

			if type(setclipboard) == 'function' then
				setclipboard(raw)
				self.Library:Notify(string.format('copied config %q to clipboard', name))
			else
				self.Library:Notify('clipboard unavailable', 3)
			end
		end})

		SaveManager.AutoloadLabel = section:AddLabel('current autoload config: none', true)

		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')
			SaveManager.AutoloadLabel:SetText('current autoload config: ' .. name)
		end

		SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName', 'SaveManager_ConfigString' })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
