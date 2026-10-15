local httpService = game:GetService('HttpService')
local ThemeManager = {} do
	ThemeManager.Folder = 'Xyro/rivals/'

	ThemeManager.Library = nil

	ThemeManager.ThemeFields = {
		'FontColor',
		'RiskColor',
		'MainColor',
		'AccentColor',
		'BackgroundColor',
		'OutlineColor',
		'BackColor',
		'BackTransparency',
		'BlurSize',
		'Contrast',
		'Saturation',
		'Brightness',
		'SwordColor',
		'SwordTransparency',
		'SwordReflectance',
		'SwordMaterial',
		'SwordSpeed',
	}

	local function decode(hex)
		if type(hex) ~= 'string' then
			return hex
		end
		local ok, col = pcall(Color3.fromHex, hex)
		if ok then
			return col
		end
		local r = tonumber(hex:sub(1, 2), 16) or 0
		local g = tonumber(hex:sub(3, 4), 16) or 0
		local b = tonumber(hex:sub(5, 6), 16) or 0
		return Color3.fromRGB(r, g, b)
	end

	local function encode(value)
		if typeof(value) == 'Color3' then
			return value:ToHex()
		end
		return value
	end

	local THEMES_JSON = [[
{"FontColor":"ffffff","MainColor":"131313","AccentColor":"a2cdff","BackgroundColor":"151515","OutlineColor":"212121","RiskColor":"ff3232",
 "SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon",
 "Contrast":"0","Saturation":"0","Brightness":"0",
 "BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}
	]]

	ThemeManager.BuiltInThemes = {
		['Default'] = { 1, httpService:JSONDecode(THEMES_JSON) },
		['Tokyo Night'] = { 2, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6956cb","BackgroundColor":"15151e","OutlineColor":"272727","RiskColor":"fb5f5f","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['Nord'] = { 3, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"1c1e20","AccentColor":"9effc8","BackgroundColor":"1c1e20","OutlineColor":"24282d","RiskColor":"ff7a00","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['Skeet'] = { 4, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"131313","AccentColor":"81ff54","BackgroundColor":"151515","OutlineColor":"2a2a2a","RiskColor":"e50000","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['Fatality'] = { 5, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"181537","AccentColor":"ca0756","BackgroundColor":"201c46","OutlineColor":"39335a","RiskColor":"e50000","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['Neverlose'] = { 6, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"0c1014","AccentColor":"01a3f1","BackgroundColor":"0c0f14","OutlineColor":"191919","RiskColor":"e50000","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['Onetap'] = { 7, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"1e1d22","AccentColor":"faa614","BackgroundColor":"18181c","OutlineColor":"313033","RiskColor":"e50000","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['Imgui'] = { 8, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"151617","AccentColor":"406ba8","BackgroundColor":"151617","OutlineColor":"242424","RiskColor":"e50000","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['Iniuria'] = { 9, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"1e1d1e","AccentColor":"c41275","BackgroundColor":"1e1d1e","OutlineColor":"33252b","RiskColor":"e50000","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['Primordial'] = { 10, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"181818","AccentColor":"d7a6b0","BackgroundColor":"1f1f1f","OutlineColor":"2a2a2a","RiskColor":"e50000","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['Monolith'] = { 11, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"141115","AccentColor":"c707bd","BackgroundColor":"171417","OutlineColor":"272427","RiskColor":"e50000","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['V3rmillion'] = { 12, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"202020","AccentColor":"cd1818","BackgroundColor":"202020","OutlineColor":"2a2a2a","RiskColor":"e50000","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
		['Dark'] = { 13, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"0a0a0a","AccentColor":"5945ff","BackgroundColor":"0a0a0a","OutlineColor":"171717","RiskColor":"e50000","SwordColor":"ffffff","SwordTransparency":"0","SwordReflectance":"0","SwordSpeed":"0.15","SwordMaterial":"Neon","Contrast":"0","Saturation":"0","Brightness":"0","BackColor":"000000","BlurSize":"15","BackTransparency":"0.7"}]]) },
	}

	local function pushOption(key, value)
		if not (Options and Options[key]) then
			return
		end
		local option = Options[key]
		if typeof(value) == 'Color3' then
			if option.SetValueRGB then
				option:SetValueRGB(value)
			end
		elseif option.SetValue then
			option:SetValue(value)
		end
	end

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		local scheme = customThemeData or data[2]

		for key, value in next, scheme do
			if type(key) == 'string' and key:find('Color') then
				local col = decode(value)
				self.Library[key] = col
				pushOption(key, col)
			else
				local coerced = tonumber(value)
				if coerced == nil then coerced = value end
				self.Library[key] = coerced
				pushOption(key, coerced)
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		for _, field in next, self.ThemeFields do
			if Options and Options[field] then
				local value = Options[field].Value
				if value ~= nil then
					self.Library[field] = value
				end
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
			theme = self.DefaultTheme
		end

		if isDefault then
			Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:CreateThemeManager(groupbox)
		groupbox:AddLabel('background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor })
		groupbox:AddLabel('main color')    :AddColorPicker('MainColor',    { Default = self.Library.MainColor })
		groupbox:AddLabel('accent color')  :AddColorPicker('AccentColor',  { Default = self.Library.AccentColor })
		groupbox:AddLabel('outline color') :AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor })
		groupbox:AddLabel('font color')    :AddColorPicker('FontColor',    { Default = self.Library.FontColor })
		groupbox:AddLabel('risk text color'):AddColorPicker('RiskColor',   { Default = self.Library.RiskColor })

		local ThemesArray = {}
		for Name in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		groupbox:AddDivider()
		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'theme list', Values = ThemesArray, Default = 1 })

		groupbox:AddButton('set as default', function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format('set default theme to %q', Options.ThemeManager_ThemeList.Value))
		end)

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		groupbox:AddDivider()
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'custom theme name' })
		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		groupbox:AddDivider()

		groupbox:AddButton('save theme', function()
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)

			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		groupbox:AddButton({ Text = 'load theme', DoubleClick = true, Func = function()
			self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value)
		end })

		groupbox:AddButton({ Text = 'overwrite theme', DoubleClick = true, Func = function()
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)
			self.Library:Notify(string.format('overwrote theme %q', Options.ThemeManager_CustomThemeName.Value))
		end })

		groupbox:AddButton('refresh list', function()
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		groupbox:AddButton({ Text = 'delete custom theme', DoubleClick = true, Func = function()
			local name = Options.ThemeManager_CustomThemeList.Value
			if name == nil or name == '' then return end
			local path = self.Folder .. '/themes/' .. name
			if not isfile(path) and isfile(path .. '.json') then
				path = path .. '.json'
			end
			if isfile(path) then
				pcall(delfile, path)
				Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
				Options.ThemeManager_CustomThemeList:SetValue(nil)
				self.Library:Notify(string.format('deleted theme %q', name))
			end
		end })

		groupbox:AddButton('set as default', function()
			if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format('set default theme to %q', Options.ThemeManager_CustomThemeList.Value))
			end
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		for _, field in next, self.ThemeFields do
			if Options and Options[field] and Options[field].OnChanged then
				Options[field]:OnChanged(UpdateTheme)
			end
		end
	end

	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file
		if not isfile(path) and not file:find('%.json$') and isfile(path .. '.json') then
			path = path .. '.json'
		end
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)

		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:SaveCustomTheme(file)
		if not file or file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3)
		end

		local theme = {}
		for _, field in next, self.ThemeFields do
			if Options and Options[field] and Options[field].Value ~= nil then
				theme[field] = encode(Options[field].Value)
			elseif self.Library[field] ~= nil then
				theme[field] = encode(self.Library[field])
			end
		end

		writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				local pos = file:find('.json', 1, true)
				local char = file:sub(pos, pos)

				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					local name = file:sub(pos + 1)
					if name:sub(-5) == '.json' then
						name = name:sub(1, -6)
					end
					table.insert(out, name)
				end
			end
		end

		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		table.insert(paths, self.Folder .. '/themes')
		table.insert(paths, self.Folder .. '/settings')

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddLeftGroupbox('themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager
