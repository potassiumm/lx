local InputService = cloneref(game:GetService('UserInputService'));
local TextService = cloneref(game:GetService('TextService'));
local CoreGui = cloneref(game:GetService('CoreGui'));
local Teams = cloneref(game:GetService('Teams'));
local Players = cloneref(game:GetService('Players'));
local RunService = cloneref(game:GetService('RunService'))
local TweenService = cloneref(game:GetService('TweenService'));
local Lighting = cloneref(game:GetService('Lighting'));
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);
local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;
local Toggles = {};
local Options = {};
getgenv().Toggles = Toggles;
getgenv().Options = Options;
local Library = {
    Registry = {};
    RegistryMap = {};
    HudRegistry = {};
    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(24, 24, 24);
    BackgroundColor = Color3.fromRGB(20, 20, 20);
    AccentColor = Color3.fromRGB(71, 119, 182);
    OutlineColor = Color3.fromRGB(31, 31, 31);
    RiskColor = Color3.fromRGB(255, 50, 50),
    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.RobotoMono,
    FontSize = 14,
    OpenedFrames = {};
    DependencyBoxes = {};
    Signals = {};
    ScreenGui = ScreenGui;
    Windows = {};
    Toggled = false;
    WireframeDrag = true;
    UseBlur = false;
    BlurSize = 15;
    KeybindMode = 'All';
    NotifyConfig = {
        Alignment = 'Center';
        BarSide = 'Bottom';
        PositionX = 0;
        PositionY = 39;
        ScaleX = 0.5;
        ScaleY = 0.6;
        AnchorPoint = Vector2.new(0.5, 0);
        Transparency = 0.25;
        ClipDescendants = true;
        ClipPastDistance = 200;
        ForceColor = false;
        ForceColorValue = Color3.fromRGB(71, 119, 182);
        FontColorValue = Color3.fromRGB(255, 255, 255);
        SortOrder = 'Default';
    };
    TooltipResetters = {};
    MinSize = Vector2.new(440, 460);
};
_G.UIUnlocked = false;
Library.NotificationStyle = Library.NotifyConfig;
Library.KeyPickerList = {};
Library.CursorLoopRunning = false;
function Library:CursorPos()
    local loc = InputService:GetMouseLocation()
    local insetY = 0
    pcall(function()
        insetY = game:GetService("GuiService"):GetGuiInset().Y
    end)
    return loc.X, loc.Y - insetY
end
Library.BlurEffect = Instance.new("BlurEffect")
Library.BlurEffect.Name = "LinoriaBlur"
Library.BlurEffect.Size = 0
Library.BlurEffect.Enabled = false
pcall(function() Library.BlurEffect.Parent = Lighting end)
function Library:UpdateBlur()
    if Library.UseBlur then
        if Library.Toggled then
            Library.BlurEffect.Enabled = true
            TweenService:Create(Library.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = Library.BlurSize}):Play()
        end
    else
        local tween = TweenService:Create(Library.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = 0})
        tween:Play()
        task.delay(0.2, function()
            if not Library.UseBlur then
                Library.BlurEffect.Enabled = false
            end
        end)
    end
end
function Library:SetFontSize(Size)
    Library.FontSize = Size
    for _, descendant in pairs(ScreenGui:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
            local offset = descendant:GetAttribute("FontSizeOffset")
            if offset then
                descendant.TextSize = Size + offset
            end
        end
    end
    local mobileUI = CoreGui:FindFirstChild("LinoriaMobileUI")
    if mobileUI then
        for _, descendant in pairs(mobileUI:GetDescendants()) do
            if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
                local offset = descendant:GetAttribute("FontSizeOffset")
                if offset then
                    descendant.TextSize = Size + offset
                end
            end
        end
    end
end
local RainbowStep = 0
local Hue = 0
table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    if RainbowStep >= (1 / 60) then
        RainbowStep = 0
        Hue = Hue + (1 / 400);
        if Hue > 1 then
            Hue = 0;
        end;
        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))
local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;
    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);
    return PlayerList;
end;
local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;
    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    return TeamList;
end;
function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;
    if not Library.NotifyOnError then
        return f(...);
    end;
    local success, event = pcall(f, ...);
    if not success then
        local _, i = event:find(":%d+: ");
        if not i then
            return Library:Notify(event);
        end;
        return Library:Notify(event:sub(i + 1), 3);
    end;
end;
function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;
function Library:Create(Class, Properties)
    local _Instance = Class;
    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;
    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;
    if _Instance:IsA("TextLabel") or _Instance:IsA("TextBox") or _Instance:IsA("TextButton") then
        if Properties.TextSize then
            _Instance:SetAttribute("FontSizeOffset", Properties.TextSize - Library.FontSize)
        else
            _Instance:SetAttribute("FontSizeOffset", 0)
        end
    end
    return _Instance;
end;
function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;
    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;
function Library:ApplyGlow(Inst)
end;
function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = Library.FontSize + 2;
        TextStrokeTransparency = 0;
    });
    Library:ApplyTextStroke(_Instance);
    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);
    return Library:Create(_Instance, Properties);
end;
function Library:MakeDraggable(Instance, Cutoff, IsWindow)
    Instance.Active = true;
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            if IsWindow and InputService.TouchEnabled and not _G.UIUnlocked then
                return
            end
            local StartPos = Instance.Position
            local DragStart = Input.Position
            if (DragStart.Y - Instance.AbsolutePosition.Y) > (Cutoff or 40) then
                return
            end
            local Dragging = true
            local HasMoved = false
            local Wireframe = nil
            local ChangedConn, EndedConn
            ChangedConn = InputService.InputChanged:Connect(function(Change)
                if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                    local Delta = Change.Position - DragStart
                    if IsWindow and Library.WireframeDrag then
                        if not HasMoved and Delta.Magnitude > 2 then
                            HasMoved = true
                            Wireframe = Library:Create("Frame", {
                                Size = Instance.Size,
                                Position = Instance.Position,
                                AnchorPoint = Instance.AnchorPoint,
                                BackgroundTransparency = 1,
                                Active = false,
                                ZIndex = 100000,
                                Parent = ScreenGui
                            })
                            local stroke = Library:Create("UIStroke", {
                                Color = Library.AccentColor,
                                Thickness = 1,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                Parent = Wireframe
                            })
                        end
                        if HasMoved and Wireframe then
                            Wireframe.Position = UDim2.new(
                                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                            )
                        end
                    else
                        Instance.Position = UDim2.new(
                            StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                            StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                        )
                    end
                end
            end)
            EndedConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                    ChangedConn:Disconnect()
                    EndedConn:Disconnect()
                    if IsWindow and Library.WireframeDrag and HasMoved and Wireframe then
                        Instance.Position = Wireframe.Position
                        Wireframe:Destroy()
                        Wireframe = nil
                    end
                end
            end)
        end
    end)
end;
function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, Library.FontSize);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,
        Visible = false,
    })
    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = Library.FontSize;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,
        Parent = Tooltip;
    });
    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });
    local IsHovering = false
    local TooltipLoop = nil
        local function placeTooltip()
        local cx, cy = Library:CursorPos()
        local inset = Vector2.zero
        pcall(function()
            inset = game:GetService("GuiService"):GetGuiInset()
        end)
        local offsetX, offsetY = 14, 18
        local cam = workspace.CurrentCamera
        local vw = (cam and cam.ViewportSize.X or 1920) - inset.X
        local vh = (cam and cam.ViewportSize.Y or 1080) - inset.Y
        local tw = Tooltip.AbsoluteSize.X
        local th = Tooltip.AbsoluteSize.Y
        if tw <= 0 then tw = Tooltip.Size.X.Offset end
        if th <= 0 then th = Tooltip.Size.Y.Offset end
        local x = cx + 14;
        local y = cy - 22.5;
        if y < 4 then y = cy + 2 end
        if x + tw > vw - 4 then x = vw - tw - 4 end
        if y + th > vh - 4 then y = cy - th - 6 end
        if x < 4 then x = 4 end
        if y < 4 then y = 4 end
        Tooltip.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
    end
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end
        IsHovering = true
        Tooltip.Visible = true
        placeTooltip()
        if TooltipLoop then return end
        TooltipLoop = true
        task.spawn(function()
            while IsHovering do
                RunService.Heartbeat:Wait()
                if Tooltip and Tooltip.Parent then
                    placeTooltip()
                end
            end
            TooltipLoop = nil
        end)
    end)
    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
    local function hide_if_hidden()
        IsHovering = false
        Tooltip.Visible = false
    end
    HoverInstance:GetPropertyChangedSignal('Visible'):Connect(function()
        if not HoverInstance.Visible then
            hide_if_hidden()
        end
    end)
    table.insert(Library.TooltipResetters, hide_if_hidden)
end
function Library:HideAllTooltips()
    for _, resetter in ipairs(Library.TooltipResetters) do
        pcall(resetter)
    end
end
Library.ResizeHooks = {};
function Library:OnResize(Callback)
    if type(Callback) ~= 'function' then return end;
    table.insert(Library.ResizeHooks, Callback);
    task.defer(function()
        pcall(Callback);
    end);
end;
function Library:FireResize()
    for _, Callback in ipairs(Library.ResizeHooks) do
        pcall(Callback);
    end;
end;
function Library:QueueResize()
    if Library._ResizeQueued then return end;
    Library._ResizeQueued = true;
    task.defer(function()
        Library._ResizeQueued = false;
        Library:FireResize();
    end);
end;
function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];
        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;
            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];
        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;
            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;
function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        if Frame and Frame.Parent then
            local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
            local x, y = Library:CursorPos()
            if x >= AbsPos.X and x <= AbsPos.X + AbsSize.X
                and y >= AbsPos.Y and y <= AbsPos.Y + AbsSize.Y then
                return true;
            end;
        end
    end;
    return false;
end;
function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    local x, y = Library:CursorPos()
    if x >= AbsPos.X and x <= AbsPos.X + AbsSize.X
        and y >= AbsPos.Y and y <= AbsPos.Y + AbsSize.Y then
        return true;
    end;
end;
function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;
function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;
function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;
function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);
function Library:AddToRegistry(Instance, Properties, IsHud)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance)
    end
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };
    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;
    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;
function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];
    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;
        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;
        Library.RegistryMap[Instance] = nil;
    end;
end;
function Library:UpdateColorsUsingRegistry()
    for Idx = #Library.Registry, 1, -1 do
        local Object = Library.Registry[Idx]
        if not Object.Instance or not Object.Instance.Parent then
            table.remove(Library.Registry, Idx)
            if Object.Instance then Library.RegistryMap[Object.Instance] = nil end
        else
            for Property, ColorIdx in next, Object.Properties do
                if type(ColorIdx) == 'string' then
                    Object.Instance[Property] = Library[ColorIdx];
                elseif type(ColorIdx) == 'function' then
                    Object.Instance[Property] = ColorIdx()
                end
            end;
        end
    end;
end;
function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end
function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end
    local Callbacks = Library.UnloadCallbacks
    Library.UnloadCallbacks = {}
    for _, Callback in ipairs(Callbacks) do
        pcall(Callback)
    end
    if Library._UnloadCallback then
        pcall(Library._UnloadCallback)
    end
    if Library.BlurEffect then
        Library.BlurEffect:Destroy()
    end
    ScreenGui:Destroy()
end
Library._UnloadCallback = nil
Library.UnloadCallbacks = {}
function Library:OnUnload(Callback)
    if type(Callback) == 'function' then
        table.insert(Library.UnloadCallbacks, Callback)
    end
end
Library.ToggleCallbacks = {}
function Library:OnToggle(Callback)
    if type(Callback) == 'function' then
        table.insert(Library.ToggleCallbacks, Callback)
    end
end
Library:OnUnload(function()
    pcall(function()
        local Lighting = game:GetService("Lighting")
        for _, Name in next, { "menublur", "XyroMenuBlur" } do
            local blur = Lighting:FindFirstChild(Name)
            if blur then blur:Destroy() end
        end
    end)
end)
Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))
local BaseAddons = {};
do
    local Funcs = {};
    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        assert(Info.Default, 'AddColorPicker: Missing default value.');
        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };
        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);
            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;
        ColorPicker:SetHSVFromRGB(ColorPicker.Value);
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });
        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });
        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)
        Library:OnResize(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)
        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });
        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });
        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });
        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });
        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })
        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });
        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });
        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });
        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });
        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });
        Library:ApplyTextStroke(HueBox);
        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });
        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });
        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        if Info.Transparency then
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });
            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });
            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });
            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });
            TransparencyCursor = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
        end;
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = Library.FontSize;
            Text = ColorPicker.Title,
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });
        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,
                Visible = false,
                Parent = ScreenGui
            })
            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });
            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });
            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });
            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end
            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end
                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end
            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)
            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)
            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });
            function ContextMenu:Show()
                self.Container.Visible = true
            end
            function ContextMenu:Hide()
                self.Container.Visible = false
            end
            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end
                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = Library.FontSize - 1;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });
                Library:OnHighlight(Button, Button,
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );
                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                    Callback()
                end)
            end
            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)
            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)
            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)
            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)
        end
        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });
        local SequenceTable = {};
        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;
        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });
        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end
            ColorPicker:Display()
        end)
        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end
            ColorPicker:Display()
        end)
        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);
            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });
            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;
            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);
            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;
        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;
        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;
            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;
        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;
        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;
        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;
        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateColor(PosX, PosY)
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(PosX, MinX, MaxX);
                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(PosY, MinY, MaxY);
                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                end
                UpdateColor(Input.Position.X, Input.Position.Y)
                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateColor(Change.Position.X, Change.Position.Y)
                    end
                end)
                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end);
        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateHue(PosY)
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(PosY, MinY, MaxY);
                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                end
                UpdateHue(Input.Position.Y)
                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateHue(Change.Position.Y)
                    end
                end)
                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end);
        DisplayFrame.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);
        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    local function UpdateAlpha(PosX)
                        local MinX = TransparencyBoxInner.AbsolutePosition.X;
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                        local MouseX = math.clamp(PosX, MinX, MaxX);
                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));
                        ColorPicker:Display();
                    end
                    UpdateAlpha(Input.Position.X)
                    local ChangedConn = InputService.InputChanged:Connect(function(Change)
                        if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                            UpdateAlpha(Change.Position.X)
                        end
                    end)
                    local EndedConn
                    EndedConn = InputService.InputEnded:Connect(function(EndInput)
                        if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                            ChangedConn:Disconnect()
                            EndedConn:Disconnect()
                            Library:AttemptSave()
                        end
                    end)
                end
            end);
        end;
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;
                local DFPos = DisplayFrame.AbsolutePosition;
                local DFSize = DisplayFrame.AbsoluteSize;
                local pos = Input.Position
                if pos.X < AbsPos.X or pos.X > AbsPos.X + AbsSize.X
                    or pos.Y < DFPos.Y or pos.Y > AbsPos.Y + AbsSize.Y then
                    if not (pos.X >= DFPos.X and pos.X <= DFPos.X + DFSize.X
                        and pos.Y >= DFPos.Y and pos.Y <= DFPos.Y + DFSize.Y) then
                        ColorPicker:Hide();
                    end
                end;
                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end;
            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))
        function ColorPicker:GetTransparency()
            return ColorPicker.Transparency;
        end;
        function ColorPicker:OnTransparencyChanged(Func)
            ColorPicker.TransparencyChanged = Func;
            Func(ColorPicker.Transparency);
        end;
        local _OrigDisplay = ColorPicker.Display;
        ColorPicker.Display = function(self)
            _OrigDisplay(self);
            Library:SafeCallback(ColorPicker.TransparencyChanged, ColorPicker.Transparency);
        end;
        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame
        Options[Idx] = ColorPicker;
        return self;
    end;
    function Funcs:AddColorPickerAlpha(Idx, Info)
        Info = Info or {};
        if Info.Transparency == nil then
            Info.Transparency = 0;
        end;
        return Funcs.AddColorPicker(self, Idx, Info);
    end;
    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;
        assert(Info.Default, 'AddKeyPicker: Missing default value.');
        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;
            SyncToggleState = Info.SyncToggleState or false;
        };
        if KeyPicker.SyncToggleState and not Info.Modes then
            Info.Modes = { 'Always', 'Toggle', 'Hold' }
        end
        if Info.Modes then
            local Matched = false
            for _, M in next, Info.Modes do
                if M == Info.Mode then
                    Matched = true
                    break
                end
            end
            KeyPicker.Mode = Matched and Info.Mode or Info.Modes[1]
        elseif Info.Mode then
            KeyPicker.Mode = Info.Mode
        end
        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });
        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize - 1;
            Text = (Info.Default == 'None' or Info.Default == '' or Info.Default == '--' or Info.Default == 'Unknown') and '...' or Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });
        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(0, 0);
            Size = UDim2.new(0, 72, 0, 47);
            Visible = false;
            ZIndex = 200;
            Parent = ScreenGui;
        });
        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 201;
            Parent = ModeSelectOuter;
        });
        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });
        local function updateModeSelectPos()
            local abs = PickOuter.AbsolutePosition
            local asz = PickOuter.AbsoluteSize
            local menuH = ModeSelectOuter.Size.Y.Offset
            local menuW = ModeSelectOuter.Size.X.Offset
            local cam = workspace.CurrentCamera
            local vw = (cam and cam.ViewportSize.X or 1920)
            local vh = (cam and cam.ViewportSize.Y or 1080)
            local x = abs.X + asz.X + 4
            local y = abs.Y + 1
            if x + menuW > vw - 4 then
                x = abs.X - menuW - 4
            end
            if y + menuH > vh - 4 then
                y = vh - 4 - menuH
            end
            if x < 4 then x = 4 end
            if y < 4 then y = 4 end
            ModeSelectOuter.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
        end
        updateModeSelectPos();
        Library:OnResize(function()
            if ModeSelectOuter.Visible then
                updateModeSelectPos();
            end;
        end);
        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateModeSelectPos);
        ToggleLabel:GetPropertyChangedSignal('AbsoluteSize'):Connect(updateModeSelectPos);
        PickOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateModeSelectPos);
        local KeybindEntry = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Visible = false,
            ZIndex = 110,
            Parent = Library.KeybindContainer,
        })
        local ContainerLabel = Library:CreateLabel({
            Position = UDim2.new(0, 2, 0, 0),
            Size = UDim2.new(1, -4, 1, 0),
            TextSize = Library.FontSize - 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 111,
            Parent = KeybindEntry,
        }, true)
        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        ModeSelectOuter.Size = UDim2.new(0, 72, 0, (#Modes * 15) + 2);
        local ModeButtons = {};
        for Idx, Mode in next, Modes do
            local ModeButton = {};
            local Btn = Library:Create('TextButton', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 15);
                Text = Mode;
                Font = Library.Font;
                TextSize = Library.FontSize - 1;
                TextColor3 = Library.FontColor;
                AutoButtonColor = false;
                Active = true;
                ZIndex = 202;
                Parent = ModeSelectInner;
            });
            Library:AddToRegistry(Btn, {
                TextColor3 = 'FontColor';
            });
            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;
                KeyPicker.Mode = Mode;
                Btn.TextColor3 = Library.AccentColor;
                if Library.RegistryMap[Btn] then
                    Library.RegistryMap[Btn].Properties.TextColor3 = 'AccentColor';
                end
            end;
            function ModeButton:Deselect()
                Btn.TextColor3 = Library.FontColor;
                if Library.RegistryMap[Btn] then
                    Library.RegistryMap[Btn].Properties.TextColor3 = 'FontColor';
                end
            end;
            local function onPick()
                ModeButton:Select();
                Library:AttemptSave();
            end
            Btn.MouseButton1Click:Connect(onPick)
            Btn.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1
                    or Input.UserInputType == Enum.UserInputType.Touch then
                    onPick();
                end
            end);
            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;
            ModeButtons[Mode] = ModeButton;
        end;
        function KeyPicker:Update()
            if Info.NoUI then
                if KeybindEntry then KeybindEntry.Visible = false end
                return;
            end;
            local State = KeyPicker:GetState();
            local RawKey = tostring(KeyPicker.Value or '');
            if RawKey == '' or RawKey == 'None' or RawKey == '--' or RawKey:lower() == 'unknown' then
                if KeybindEntry then KeybindEntry.Visible = false end
                return;
            end;
            local displayKey = (RawKey == 'None' or RawKey == '' or RawKey == '--' or RawKey == 'Unknown') and '...' or RawKey
            ContainerLabel.Text = string.format('[%s] %s (%s)', displayKey, Info.Text, KeyPicker.Mode);
            local kbMode = Library.KeybindMode or 'All'
            if kbMode == 'Active' then
                KeybindEntry.Visible = State == true
            elseif kbMode == 'Toggled' then
                local parentOn = false
                if ParentObj and ParentObj.Type == 'Toggle' then
                    parentOn = ParentObj.Value == true
                elseif KeyPicker.SyncToggleState and ParentObj then
                    parentOn = ParentObj.Value == true
                else
                    parentOn = true
                end
                KeybindEntry.Visible = parentOn
            else
                KeybindEntry.Visible = true
            end
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';
            local YSize = 0
            local XSize = 0
            for _, Frame in next, Library.KeybindContainer:GetChildren() do
                if Frame:IsA('Frame') and Frame.Visible then
                    YSize = YSize + 18;
                    local LabelChild = Frame:FindFirstChildOfClass('TextLabel')
                    if LabelChild and (LabelChild.TextBounds.X + 20 > XSize) then
                        XSize = LabelChild.TextBounds.X + 20
                    end
                end;
            end;
            local shown = 0
            for _, F in next, Library.KeybindContainer:GetChildren() do
                if F:IsA('Frame') and F.Visible then
                    shown = shown + 1
                end
            end
            if Library.KeybindNoneLabel then
                Library.KeybindNoneLabel.Visible = (shown == 0)
            end
            if shown == 0 then
                Library.KeybindFrame.Size = UDim2.new(0, 210, 0, 43)
            else
                Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10 + 15, 210), 0, YSize + 23)
            end
        end;
        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end
                local Key = KeyPicker.Value;
                if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                        or Key == 'Touch' and InputService:IsMouseButtonPressed(Enum.UserInputType.Touch)
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;
        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = (Key == 'None' or Key == '' or Key == '--' or Key == 'Unknown') and '...' or Key;
            KeyPicker.Value = Key;
            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select();
            elseif ModeButtons[KeyPicker.Mode] then
                ModeButtons[KeyPicker.Mode]:Select();
            end;
            KeyPicker:Update();
        end;
        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end
        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end
        KeyPicker.ModeSelectOuter = ModeSelectOuter;
        KeyPicker.KeybindEntry = KeybindEntry;
        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
            table.insert(Library.KeyPickerList, KeyPicker)
        end
        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end
            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end
        local Picking = false;
        local LongPressTime = Info.LongPressTime or 0.55;
        local TouchMoveThreshold = Info.TouchMoveThreshold or 10;
        local function OpenModeSelect()
            if ModeSelectOuter.Visible then
                ModeSelectOuter.Visible = false;
                return;
            end;
            updateModeSelectPos();
            ModeSelectOuter.Visible = true;
        end;
        local function BeginPicking()
            if Picking then
                return;
            end;
            Picking = true;
            Library.PickingKeybind = true;
            DisplayLabel.Text = '';
            local Break;
            local Dots = { '.', '..', '...' };
            local Step = 1;
            task.spawn(function()
                while (not Break) do
                    DisplayLabel.Text = Dots[Step];
                    Step = (Step % #Dots) + 1;
                    wait(0.4);
                end;
            end);
            wait(0.2);
            local Event;
            Event = InputService.InputBegan:Connect(function(Input)
                local Key;
                if Input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = Input.KeyCode.Name;
                elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Key = 'MB1';
                elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                    Key = 'MB2';
                elseif Input.UserInputType == Enum.UserInputType.Touch then
                    Key = 'Touch';
                end;
                if not Key then
                    return;
                end;
                Break = true;
                Picking = false;
                DisplayLabel.Text = Key;
                KeyPicker.Value = Key;
                Library.LastBoundKey = Key;
                Library.LastBoundTime = os.clock();
                task.defer(function()
                    Library.PickingKeybind = false;
                end);
                Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)
                Library:AttemptSave();
                Event:Disconnect();
            end);
        end;
        PickOuter.InputBegan:Connect(function(Input)
            if Library:MouseIsOverOpenedFrame() then
                return;
            end;
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                BeginPicking();
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                OpenModeSelect();
            elseif Input.UserInputType == Enum.UserInputType.Touch then
                local StartPosition = Input.Position;
                local TouchMoved = false;
                local TouchEnded = false;
                local LongPressed = false;
                local ChangedConn;
                local EndedConn;
                ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change == Input then
                        if (Change.Position - StartPosition).Magnitude > TouchMoveThreshold then
                            TouchMoved = true;
                        end;
                    end;
                end);
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input then
                        TouchEnded = true;
                        if ChangedConn then
                            ChangedConn:Disconnect();
                        end;
                        if EndedConn then
                            EndedConn:Disconnect();
                        end;
                        if (not LongPressed) and (not TouchMoved) then
                            task.spawn(BeginPicking);
                        end;
                    end;
                end);
                task.delay(LongPressTime, function()
                    if TouchEnded or TouchMoved then
                        return;
                    end;
                    LongPressed = true;
                    if ChangedConn then
                        ChangedConn:Disconnect();
                    end;
                    if EndedConn then
                        EndedConn:Disconnect();
                    end;
                    OpenModeSelect();
                end);
            end;
        end);
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;
                    if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2
                        or Key == 'Touch' and Input.UserInputType == Enum.UserInputType.Touch then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;
                KeyPicker:Update();
            end;
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;
                local pos = Input.Position
                if pos.X < AbsPos.X or pos.X > AbsPos.X + AbsSize.X
                    or pos.Y < AbsPos.Y or pos.Y > AbsPos.Y + AbsSize.Y then
                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))
        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end))
        KeyPicker:Update();
        Options[Idx] = KeyPicker;
        return self;
    end;
    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;
local BaseGroupbox = {};
do
    local Funcs = {};
    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;
        return Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;
    function Funcs:AddScrollingFrame(Info)
        Info = Info or {};
        local Groupbox = self;
        local Container = Groupbox.Container;
        local Height = Info.Height or 207;
        local Outer = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, Height);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(Outer, { BorderColor3 = 'Black' });
        local Inner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = Outer;
        });
        Library:AddToRegistry(Inner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1));
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212));
            });
            Rotation = 90;
            Parent = Inner;
        });
        local Scroll = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            AutomaticCanvasSize = Enum.AutomaticSize.Y;
            ScrollBarThickness = 0;
            ScrollingDirection = Enum.ScrollingDirection.XY;
            ClipsDescendants = true;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 100;
            Parent = Inner;
        });
        Library:Create('UIGridLayout', {
            CellSize = UDim2.fromOffset(100, 100);
            CellPadding = UDim2.fromOffset(5, 5);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Left;
            VerticalAlignment = Enum.VerticalAlignment.Top;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scroll;
        });
        Groupbox:Resize();
        return Scroll;
    end;
    function Funcs:AddRow(Columns)
        local Groupbox = self
        local Container = Groupbox.Container
        local ColumnsCount = type(Columns) == 'number' and math.max(1, Columns) or 2
        local RowOuter = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 1,
            Parent = Container
        })
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = RowOuter
        })
        local Boxes = {}
        for i = 1, ColumnsCount do
            local Box = { Type = 'Groupbox' }
            local BoxContainer = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1 / ColumnsCount, -((ColumnsCount - 1) * 8) / ColumnsCount, 1, 0),
                ZIndex = 1,
                Parent = RowOuter
            })
            local BoxLayout = Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = BoxContainer
            })
            Box.Container = BoxContainer
            setmetatable(Box, BaseGroupbox)
            function Box:Resize()
                local maxHeight = 0
                for _, child in next, RowOuter:GetChildren() do
                    if child:IsA('Frame') then
                        local layout = child:FindFirstChildOfClass('UIListLayout')
                        if layout and layout.AbsoluteContentSize.Y > maxHeight then
                            maxHeight = layout.AbsoluteContentSize.Y
                        end
                    end
                end
                RowOuter.Size = UDim2.new(1, 0, 0, maxHeight)
                if Groupbox.Resize then
                    Groupbox:Resize()
                end
            end
            BoxLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Box:Resize()
            end)
            table.insert(Boxes, Box)
        end
        Groupbox:AddBlank(1)
        if Groupbox.Resize then Groupbox:Resize() end
        return unpack(Boxes)
    end;
    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};
        local Groupbox = self;
        local Container = Groupbox.Container;
        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = Library.FontSize;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });
        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end
        Label.TextLabel = TextLabel;
        Label.Container = Container;
        function Label:SetText(Text)
            TextLabel.Text = Text
            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end
            Groupbox:Resize();
        end
        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end
        Groupbox:AddBlank(5);
        Groupbox:Resize();
        return Label;
    end;
    function Funcs:AddButton(...)
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end
            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end
        ProcessButtonParams('Button', Button, ...)
        local Groupbox = self;
        local Container = Groupbox.Container;
        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });
            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });
            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = Library.FontSize;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });
            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            });
            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });
            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });
            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'OutlineColor' },
                { BorderColor3 = 'Black' }
            );
            return Outer, Inner, Label
        end
        local function InitEvents(Button)
            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                    return false
                end
                return true
            end
            local function WaitForConfirm(Timeout)
                local bindable = Instance.new('BindableEvent')
                local done = false
                local armClock = os.clock()
                local connection
                local function Resolve(value)
                    if done then return end
                    done = true
                    if connection then
                        connection:Disconnect()
                        connection = nil
                    end
                    bindable:Fire(value)
                end
                connection = InputService.InputBegan:Connect(function(Input)
                    if os.clock() - armClock < 0.1 then
                        return
                    end
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                    local AbsPos, AbsSize = Button.Outer.AbsolutePosition, Button.Outer.AbsoluteSize;
                    local Pos = Input.Position;
                    local OverButton = Pos.X >= AbsPos.X and Pos.X <= AbsPos.X + AbsSize.X
                        and Pos.Y >= AbsPos.Y and Pos.Y <= AbsPos.Y + AbsSize.Y;
                    Resolve(OverButton and ValidateClick(Input));
                end)
                task.delay(Timeout, function()
                    Resolve(false)
                end)
                local clicked = bindable.Event:Wait()
                bindable:Destroy()
                return clicked
            end
            local function ArmPrompt()
                Library:RemoveFromRegistry(Button.Label)
                Library:AddToRegistry(Button.Label, { TextColor3 = 'RiskColor' })
                Button.Label.TextColor3 = Library.RiskColor
                Button.Label.Text = 'Are you sure?'
            end
            local function RestorePrompt()
                Library:RemoveFromRegistry(Button.Label)
                Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })
                Button.Label.TextColor3 = Library.FontColor
                Button.Label.Text = Button.Text
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end
                if Button.DoubleClick then
                    Button.Locked = true
                    ArmPrompt()
                    local clicked = WaitForConfirm(4)
                    RestorePrompt()
                    Button.Locked = false
                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end
                    return
                end
                Library:SafeCallback(Button.Func);
            end)
        end
        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container
        InitEvents(Button)
        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end
        function Button:AddButton(...)
            local SubButton = {}
            ProcessButtonParams('SubButton', SubButton, ...)
            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)
            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)
            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.new(1, -2, 1, 0)
            SubButton.Outer.Parent = self.Outer
            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                 end
                return SubButton
            end
            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end
            InitEvents(SubButton)
            return SubButton
        end
        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end
        Groupbox:AddBlank(5);
        Groupbox:Resize();
        return Button;
    end;
    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container
        local Divider = {
            Type = 'Divider',
        }
        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });
        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });
        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });
        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end
    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')
        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };
        local Groupbox = self;
        local Container = Groupbox.Container;
        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });
        Groupbox:AddBlank(1);
        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });
        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'OutlineColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });
        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            ZIndex = 7;
            Parent = TextBoxInner;
        })
        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';
            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 7;
            Parent = Container;
        });
        Library:ApplyTextStroke(Box);
        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;
            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end
            Textbox.Value = Text;
            Box.Text = Text;
            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;
        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end
        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X
            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X
                    local currentCursorPos = Box.Position.X.Offset + width
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end
        task.spawn(Update)
        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)
        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });
        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;
        Groupbox:AddBlank(5);
        Groupbox:Resize();
        Options[Idx] = Textbox;
        return Textbox;
    end;
    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')
        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';
            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };
        local Groupbox = self;
        local Container = Groupbox.Container;
        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });
        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });
        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });
        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });
        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'OutlineColor' },
            { BorderColor3 = 'Black' }
        );
        function Toggle:UpdateColors()
            Toggle:Display();
        end;
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end
        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;
            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;
        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;
        function Toggle:SetValue(Bool)
            Bool = (not not Bool);
            Toggle.Value = Bool;
            Toggle:Display();
            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end
            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;
        function Toggle:SetSilent(Bool)
            Bool = (not not Bool);
            if Toggle.Value == Bool then return end;
            Toggle.Value = Bool;
            Toggle:Display();
            Library:UpdateDependencyBoxes();
        end;
        ToggleRegion.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave();
            end;
        end);
        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end
        Toggle:Display();
        Library:OnResize(function()
            local RowWidth = Container.AbsoluteSize.X;
            ToggleLabel.Size = UDim2.new(0, math.max(RowWidth - 25, 40), 1, 0);
        end);
        local ToggleBlank = Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();
        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        Toggle.Outer = ToggleOuter;
        Toggle.Blank = ToggleBlank;
        Toggle.Hidden = false;
        function Toggle:SetVisible(Bool)
            Bool = Bool == true;
            local Hidden = not Bool;
            if Toggle.Hidden == Hidden then return end;
            Toggle.Hidden = Hidden;
            ToggleOuter.Visible = Bool;
            ToggleBlank.Visible = Bool;
            Groupbox:Resize();
        end;
        setmetatable(Toggle, BaseAddons);
        Toggles[Idx] = Toggle;
        Library:UpdateDependencyBoxes();
        return Toggle;
    end;
    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');
        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };
        local Groupbox = self;
        local Container = Groupbox.Container;
        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(SliderOuter, { BorderColor3 = 'Black' });
        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });
        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });
        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });
        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });
        Library:AddToRegistry(HideBorderRight, { BackgroundColor3 = 'AccentColor' });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize;
            Text = '';
            ZIndex = 9;
            Parent = SliderInner;
        });
        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'OutlineColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end
        local function GetMaxSize()
            local abs = SliderInner.AbsoluteSize.X
            if abs > 0 then
                Slider.MaxSize = abs
            end
            return Slider.MaxSize
        end;
        SliderInner:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            if SliderInner.AbsoluteSize.X > 0 then
                Slider:Display();
            end
        end);
        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;
        function Slider:Display()
            local Suffix = Info.Suffix or '';
            DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix;
            local Frac = Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, 1);
            if Slider._Tween then
                Slider._Tween:Cancel();
            end
            Slider._Tween = TweenService:Create(Fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(Frac, 0, 1, 0);
            });
            Slider._Tween:Play();
            HideBorderRight.Visible = not (Frac == 1 or Frac == 0);
        end;
        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;
        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;
            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;
        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, GetMaxSize(), Slider.Min, Slider.Max));
        end;
        function Slider:SetValue(Str)
            local Num = tonumber(Str);
            if (not Num) then return; end;
            Num = math.clamp(Num, Slider.Min, Slider.Max);
            Slider.Value = Num;
            Slider:Display();
            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;
        SliderInner.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch)
                and not Library:MouseIsOverOpenedFrame() then
                local function UpdateSlider(PosX)
                    local gPos = Fill.AbsolutePosition.X
                    local Diff = PosX - gPos
                    local nX = math.clamp(Diff, 0, GetMaxSize())
                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;
                    Slider.Value = nValue;
                    Slider:Display();
                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed, Slider.Value);
                    end;
                end
                UpdateSlider(Input.Position.X)
                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateSlider(Change.Position.X)
                    end
                end)
                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end;
        end);
        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();
        Options[Idx] = Slider;
        return Slider;
    end;

    function Funcs:AddDoubleSlider(IdxA, InfoA, IdxB, InfoB)
        assert(InfoA.Default ~= nil, 'AddDoubleSlider: InfoA missing Default.');
        assert(InfoA.Text, 'AddDoubleSlider: InfoA missing Text.');
        assert(InfoA.Min ~= nil, 'AddDoubleSlider: InfoA missing Min.');
        assert(InfoA.Max ~= nil, 'AddDoubleSlider: InfoA missing Max.');
        assert(InfoA.Rounding ~= nil, 'AddDoubleSlider: InfoA missing Rounding.');
        assert(InfoB.Default ~= nil, 'AddDoubleSlider: InfoB missing Default.');
        assert(InfoB.Text, 'AddDoubleSlider: InfoB missing Text.');
        assert(InfoB.Min ~= nil, 'AddDoubleSlider: InfoB missing Min.');
        assert(InfoB.Max ~= nil, 'AddDoubleSlider: InfoB missing Max.');
        assert(InfoB.Rounding ~= nil, 'AddDoubleSlider: InfoB missing Rounding.');

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RowFrame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        local function MakeHalfSlider(Info, Idx, PosOffset)
            local Slider = {
                Value = Info.Default;
                Min = Info.Min;
                Max = Info.Max;
                Rounding = Info.Rounding;
                MaxSize = 112;
                Type = 'Slider';
                Callback = Info.Callback or function() end;
            };

            local SliderOuter = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Position = PosOffset;
                Size = UDim2.new(0.5, -3, 1, 0);
                ZIndex = 5;
                Parent = RowFrame;
            });
            Library:AddToRegistry(SliderOuter, { BorderColor3 = 'Black' });

            local SliderInner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = SliderOuter;
            });
            Library:AddToRegistry(SliderInner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });

            local Fill = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderColor3 = Library.AccentColorDark;
                Size = UDim2.new(0, 0, 1, 0);
                ZIndex = 7;
                Parent = SliderInner;
            });
            Library:AddToRegistry(Fill, {
                BackgroundColor3 = 'AccentColor';
                BorderColor3 = 'AccentColorDark';
            });

            local HideBorderRight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Position = UDim2.new(1, 0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 8;
                Parent = Fill;
            });
            Library:AddToRegistry(HideBorderRight, { BackgroundColor3 = 'AccentColor' });

            local DisplayLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = Library.FontSize;
                Text = '';
                ZIndex = 9;
                Parent = SliderInner;
            });

            Library:OnHighlight(SliderOuter, SliderOuter,
                { BorderColor3 = 'OutlineColor' },
                { BorderColor3 = 'Black' }
            );

            if type(Info.Tooltip) == 'string' then
                Library:AddToolTip(Info.Tooltip, SliderOuter)
            end

            local function GetMaxSize()
                local abs = SliderInner.AbsoluteSize.X
                if abs > 0 then
                    Slider.MaxSize = abs
                end
                return Slider.MaxSize
            end

            local function Round(Value)
                if Slider.Rounding == 0 then return math.floor(Value) end
                return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
            end

            function Slider:UpdateColors()
                Fill.BackgroundColor3 = Library.AccentColor;
                Fill.BorderColor3 = Library.AccentColorDark;
            end

            function Slider:Display()
                local Suffix = Info.Suffix or '';
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix;
                local Frac = Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, 1);
                Fill.Size = UDim2.new(Frac, 0, 1, 0);
                HideBorderRight.Visible = not (Frac == 1 or Frac == 0);
            end

            Library:OnResize(function()
                Slider:Display();
            end);

            function Slider:OnChanged(Func)
                Slider.Changed = Func;
                Func(Slider.Value);
            end

            function Slider:GetValueFromXOffset(X)
                return Round(Library:MapValue(X, 0, GetMaxSize(), Slider.Min, Slider.Max));
            end

            function Slider:SetValue(Str)
                local Num = tonumber(Str);
                if not Num then return end
                Num = math.clamp(Num, Slider.Min, Slider.Max);
                Slider.Value = Num;
                Slider:Display();
                Library:SafeCallback(Slider.Callback, Slider.Value);
                Library:SafeCallback(Slider.Changed, Slider.Value);
            end

            SliderInner.InputBegan:Connect(function(Input)
                if (Input.UserInputType == Enum.UserInputType.MouseButton1
                    or Input.UserInputType == Enum.UserInputType.Touch)
                    and not Library:MouseIsOverOpenedFrame() then

                    local function UpdateSlider(PosX)
                        local gPos = Fill.AbsolutePosition.X;
                        local Diff = PosX - gPos;
                        local nX = math.clamp(Diff, 0, GetMaxSize());
                        local nValue = Slider:GetValueFromXOffset(nX);
                        local OldValue = Slider.Value;
                        Slider.Value = nValue;
                        Slider:Display();
                        if nValue ~= OldValue then
                            Library:SafeCallback(Slider.Callback, Slider.Value);
                            Library:SafeCallback(Slider.Changed, Slider.Value);
                        end
                    end

                    UpdateSlider(Input.Position.X);

                    local ChangedConn = InputService.InputChanged:Connect(function(Change)
                        if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                            UpdateSlider(Change.Position.X);
                        end
                    end);

                    local EndedConn;
                    EndedConn = InputService.InputEnded:Connect(function(EndInput)
                        if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                            ChangedConn:Disconnect();
                            EndedConn:Disconnect();
                            Library:AttemptSave();
                        end
                    end);
                end
            end);

            Slider:Display();
            Options[Idx] = Slider;
            return Slider;
        end

        local SliderA = MakeHalfSlider(InfoA, IdxA, UDim2.new(0, 0, 0, 0));
        local SliderB = MakeHalfSlider(InfoB, IdxB, UDim2.new(0.5, 1, 0, 0));

        Groupbox:AddBlank(InfoA.BlankSize or InfoB.BlankSize or 6);
        Groupbox:Resize();

        return SliderA, SliderB;
    end;

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;
        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')
        if (not Info.Text) then
            Info.Compact = true;
        end;
        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback = Info.Callback or function(Value) end;
        };
        local Groupbox = self;
        local Container = Groupbox.Container;
        local RelativeOffset = 0;
        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = Library.FontSize;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });
            Groupbox:AddBlank(3);
        end
        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;
        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });
        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });
        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });
        local DropdownArrow = Library:CreateLabel({
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Text = '>';
            TextSize = 13;
            TextXAlignment = Enum.TextXAlignment.Center;
            TextYAlignment = Enum.TextYAlignment.Center;
            ZIndex = 7;
            Parent = DropdownInner;
        });
        Library:AddToRegistry(DropdownArrow, {
            TextColor3 = 'FontColor';
        });
        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -22, 1, 0);
            TextSize = Library.FontSize;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });
        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'OutlineColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end
        local MAX_DROPDOWN_ITEMS = 8;
        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });
        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
        end;
        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end;
        Library:OnResize(function()
            if ListOuter.Visible then
                RecalculateListPosition();
                ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, ListOuter.Size.Y.Offset);
            end;
        end);
        RecalculateListPosition();
        RecalculateListSize();
        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);
        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });
        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });
        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });
        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';
            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;
                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;
            ItemList.Text = (Str == '' and '--' or Str);
        end;
        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};
                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;
                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;
        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values;
            local Buttons = {};
            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;
            local Count = 0;
            for Idx, Value in next, Values do
                local Table = {};
                Count = Count + 1;
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });
                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = Library.FontSize;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });
                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );
                local Selected;
                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;
                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;
                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;
                ButtonLabel.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                        local Try = not Selected;
                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;
                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;
                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;
                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;
                            Table:UpdateButton();
                            Dropdown:Display();
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
                            Library:AttemptSave();
                        end;
                    end;
                end);
                Table:UpdateButton();
                Dropdown:Display();
                Buttons[Button] = Table;
            end;
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);
            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            RecalculateListSize(Y);
        end;
        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;
            Dropdown:BuildDropdownList();
        end;
        function Dropdown:OpenDropdown()
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = function()
                Dropdown:CloseDropdown();
            end;
            DropdownArrow.Rotation = 90;
            RecalculateListPosition();
            RecalculateListSize(ListOuter.Size.Y.Offset);
        end;
        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0; 
        end;
        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;
        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};
                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;
                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;
            Dropdown:BuildDropdownList();
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;
        DropdownOuter.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;
                local pos = Input.Position
                if pos.X < AbsPos.X or pos.X > AbsPos.X + AbsSize.X
                    or pos.Y < (AbsPos.Y - 20 - 1) or pos.Y > AbsPos.Y + AbsSize.Y then
                    Dropdown:CloseDropdown();
                end;
            end;
        end));
        Dropdown:BuildDropdownList();
        Dropdown:Display();
        local Defaults = {}
        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end
        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end
                if (not Info.Multi) then break end
            end
            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end
        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();
        Options[Idx] = Dropdown;
        return Dropdown;
    end;
    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };
        local Groupbox = self;
        local Container = Groupbox.Container;
        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });
        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });
        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });
        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;
        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);
        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);
        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];
                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;
            Holder.Visible = true;
            Depbox:Resize();
        end;
        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;
            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;
        Depbox.Container = Frame;
        setmetatable(Depbox, BaseGroupbox);
        table.insert(Library.DependencyBoxes, Depbox);
        return Depbox;
    end;
    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        AnchorPoint = Library.NotifyConfig.AnchorPoint or Vector2.new(0.5, 0.5);
        Position = UDim2.new(Library.NotifyConfig.ScaleX or 0.5, Library.NotifyConfig.PositionX or 0, Library.NotifyConfig.ScaleY or 0.6, Library.NotifyConfig.PositionY or 0);
        Size = UDim2.new(0, 2560, 0, Library.NotifyConfig.ClipPastDistance or 200);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = ScreenGui;
    });
    Library.NotifLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        VerticalAlignment = Enum.VerticalAlignment.Top;
        Parent = Library.NotificationArea;
    });
    local function Library_UpdateNotifAlignment()
        local cfg = Library.NotifyConfig
        local area = Library.NotificationArea
        local layout = Library.NotifLayout
        local scaleX = tonumber(cfg.ScaleX)
        local scaleY = tonumber(cfg.ScaleY)
        local anchor = cfg.AnchorPoint or Vector2.new(0.5, 0.5)
        area.AnchorPoint = anchor
        if scaleX ~= nil and scaleY ~= nil then
            area.Position = UDim2.new(math.clamp(scaleX, 0, 1), cfg.PositionX or 0, math.clamp(scaleY, 0, 1), cfg.PositionY or 0)
        else
            area.Position = UDim2.new(0, cfg.PositionX or 0, 0, cfg.PositionY or 0)
        end
        local align = cfg.Alignment or 'Center'
        if align == 'Left' then
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        elseif align == 'Right' then
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        else
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        end
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        area.Size = UDim2.new(0, 2560, 0, math.max(tonumber(cfg.ClipPastDistance) or 200, 1))
        area.ClipsDescendants = cfg.ClipDescendants ~= false
    end
    function Library:SetNotificationPosition(config)
        if type(config) ~= 'table' then return end
        for Key, Value in next, config do
            Library.NotifyConfig[Key] = Value
        end
        Library_UpdateNotifAlignment()
    end
    Library.UpdateNotifAlignment = Library_UpdateNotifAlignment
    Library_UpdateNotifAlignment()
    local NotifyBarSize = {
        Left = UDim2.new(0, 3, 1, 2);
        Right = UDim2.new(0, 3, 1, 2);
        Top = UDim2.new(1, 2, 0, 3);
        Bottom = UDim2.new(1, 2, 0, 3);
    };
    local NotifyBarPosition = {
        Left = UDim2.new(0, -1, 0, -1);
        Right = UDim2.new(1, -2, 0, -1);
        Top = UDim2.new(0, -1, 0, -1);
        Bottom = UDim2.new(0, -1, 1, -2);
    };

    function Library:Notify(Text, Time)
        local cfg = Library.NotifyConfig
        local style = Library.NotificationStyle or cfg
        local transparency = math.clamp(tonumber(style.Transparency) or 0, 0, 1)
        local barSide = style.BarSide or 'Left'

        local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);
        YSize = YSize + 7
        local TargetW = XSize + 8 + 4;
        local FinalH = YSize;

        local outerColor = Library.MainColor;
        local borderColor = Library.OutlineColor;
        local barColor = style.ForceColor and (style.ForceColorValue or Library.AccentColor) or Library.AccentColor;
        local textColor = style.ForceColor and (style.FontColorValue or Library.FontColor) or Library.FontColor;

        if cfg.SortOrder == 'Newest First' then
            Library._NotifyOrder = (Library._NotifyOrder or 0) - 1;
        else
            Library._NotifyOrder = (Library._NotifyOrder or 0) + 1;
        end

        local NotifyOuter = Library:Create('Frame', {
            BackgroundColor3 = outerColor;
            BorderColor3 = Color3.new(0, 0, 0);
            BorderSizePixel = 0;
            LayoutOrder = Library._NotifyOrder;
            Size = UDim2.new(0, 0, 0, YSize);
            ClipsDescendants = style.ClipDescendants ~= false;
            BackgroundTransparency = 1;
            ZIndex = 100;
            Parent = Library.NotificationArea;
        });
        Library:AddToRegistry(NotifyOuter, { BackgroundColor3 = 'MainColor' }, true);
        local NotifyInner = Library:Create('Frame', {
            BackgroundColor3 = outerColor;
            BorderColor3 = borderColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            BackgroundTransparency = 1;
            ZIndex = 101;
            Parent = NotifyOuter;
        });
        Library:AddToRegistry(NotifyInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        }, true);
        local InnerFrame = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Position = UDim2.new(0, 1, 0, 1);
            Size = UDim2.new(1, -2, 1, -2);
            BackgroundTransparency = transparency;
            ZIndex = 102;
            Parent = NotifyInner;
        });
        local Gradient = Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(outerColor)),
                ColorSequenceKeypoint.new(1, outerColor),
            });
            Rotation = -90;
            Parent = InnerFrame;
        });
        Library:AddToRegistry(Gradient, {
            Color = function()
                return ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                    ColorSequenceKeypoint.new(1, Library.MainColor),
                });
            end
        });
        local NotifyLabel = Library:CreateLabel({
            Position = UDim2.new(0, 4, 0, 0);
            Size = UDim2.new(1, -4, 1, 0);
            Text = Text;
            TextColor3 = textColor;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            ZIndex = 103;
            Parent = InnerFrame;
        });
        Library:AddToRegistry(NotifyLabel, { TextColor3 = 'FontColor' }, true);
        local Bar = Library:Create('Frame', {
            BackgroundColor3 = barColor;
            BorderSizePixel = 0;
            Position = NotifyBarPosition[barSide] or NotifyBarPosition.Left;
            Size = NotifyBarSize[barSide] or NotifyBarSize.Left;
            ZIndex = 104;
            Parent = NotifyOuter;
        });
        Library:AddToRegistry(Bar, { BackgroundColor3 = 'AccentColor' }, true);

        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, TargetW, 0, YSize), 'Out', 'Quad', 0.4, true);
        task.spawn(function()
            task.wait(Time or 5);
            pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, FinalH), 'Out', 'Quad', 0.4, true);
            task.wait(0.4);
            NotifyOuter:Destroy();
        end);
    end
end
Library.NotificationAreaBottom = Library:Create('Frame', {
    BackgroundTransparency = 1;
    Position = UDim2.new(0.5, 0, 1, -20);
    AnchorPoint = Vector2.new(0.5, 1);
    Size = UDim2.new(0, 300, 0, 0);
    AutomaticSize = Enum.AutomaticSize.Y;
    ZIndex = 100;
    Parent = ScreenGui;
});
Library.NotifLayoutBottom = Library:Create('UIListLayout', {
    Padding = UDim.new(0, 4);
    FillDirection = Enum.FillDirection.Vertical;
    SortOrder = Enum.SortOrder.LayoutOrder;
    VerticalAlignment = Enum.VerticalAlignment.Bottom;
    HorizontalAlignment = Enum.HorizontalAlignment.Center;
    Parent = Library.NotificationAreaBottom;
});
function Library:NotifyBottomCenter(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, Library.FontSize)
    YSize = YSize + 7
    local BAR_THICK = 3
    local finalWidth = XSize + 8 + 4
    local maxWidth = 300
    if finalWidth > maxWidth then finalWidth = maxWidth end
    local Wrap = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 0, YSize);
        ZIndex = 100;
        Parent = Library.NotificationAreaBottom;
    });
    local NotifyOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        Position = UDim2.new(0.5, 0, 0.5, 0);
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderColor3 = Color3.new(0, 0, 0);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Wrap;
    });
    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });
    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, BAR_THICK + 1);
        Size = UDim2.new(1, -2, 1, -(BAR_THICK + 2));
        ZIndex = 102;
        Parent = NotifyInner;
    });
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });
    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -8, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Center;
        TextSize = Library.FontSize;
        ZIndex = 103;
        Parent = InnerFrame;
    });
    local AccentBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, -1, 0, -1);
        Size = UDim2.new(1, 2, 0, BAR_THICK);
        ZIndex = 104;
        Parent = NotifyOuter;
    });
    Library:AddToRegistry(AccentBar, {
        BackgroundColor3 = 'AccentColor';
    }, true);
    local tweenIn = TweenService:Create(NotifyOuter,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, finalWidth, 0, YSize)}
    )
    tweenIn:Play()
    task.spawn(function()
        wait(Time or 5)
        local tweenOut = TweenService:Create(NotifyOuter,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, YSize)}
        )
        tweenOut:Play()
        tweenOut.Completed:Wait()
        Wrap:Destroy()
    end)
end
do
    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 213, 0, 20);
        ClipsDescendants = true;
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });
    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });
    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });
    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = Library.FontSize;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });
    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);
    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });
    Library:ApplyGlow(KeybindOuter);
    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });
    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });
    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor';
    }, true);
    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left;
        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });
    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });
    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })
    Library.KeybindFrame = KeybindOuter;
    Library.KeybindInner = KeybindInner;
    Library.KeybindContainer = KeybindContainer;
    Library.KeybindNoneLabel = Library:CreateLabel({
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(1, -4, 0, 18);
        TextSize = Library.FontSize - 1;
        TextXAlignment = Enum.TextXAlignment.Left;
        Text = 'no keybinds';
        Visible = false;
        ZIndex = 111;
        Parent = KeybindContainer,
    }, true)
    Library:MakeDraggable(KeybindOuter);
end
function Library:SetKeybindMode(Mode)
    assert(Mode == 'All' or Mode == 'Active' or Mode == 'Toggled',
        "SetKeybindMode: Mode must be 'All', 'Active', or 'Toggled'")
    Library.KeybindMode = Mode
    Library:RefreshKeybinds()
end
function Library:RefreshKeybinds()
    local Visible = 0
    for _, kp in ipairs(Library.KeyPickerList) do
        if not kp.NoUI and kp.Value ~= nil and kp.Value ~= '' and kp.Value ~= 'Unknown' and kp.Value ~= 'None' then
            pcall(function() kp:Update() end)
            if kp.KeybindEntry and kp.KeybindEntry.Visible then
                Visible = Visible + 1
            end
        else
            pcall(function()
                if kp.KeybindEntry then kp.KeybindEntry.Visible = false end
            end)
        end
    end
    if Library.KeybindNoneLabel then
        Library.KeybindNoneLabel.Visible = (Visible == 0)
    end
    if Library.KeybindFrame and Visible == 0 then
        Library.KeybindFrame.Size = UDim2.new(0, 210, 0, 20 + 18 + 5)
    end
end
function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;
function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, Library.FontSize);
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
    Library:SetWatermarkVisibility(true)
    Library.WatermarkText.Text = Text;
end;
local BackgroundItems = {
    { Name = 'sword', Id = 'rbxassetid://48094745', Scale = 1 };
    { Name = 'cross', Id = 'rbxassetid://4411430922', Scale = 1 };
    { Name = 'heart', Id = 'rbxassetid://1717708486', Scale = 1 };
    { Name = 'catholic cross', Id = 'rbxassetid://11468548833', Scale = 0.3 };
    { Name = 'orthodox cross', Id = 'rbxassetid://103455023111282', Union = true, Scale = 0.35 };
    { Name = 'unnamed enhancements', Id = 'rbxassetid://140725710733849', Union = true, Scale = 0.5 };
}

local BackgroundState = nil

local function EnsureBackground()
    if BackgroundState then return BackgroundState end
    local Lighting = game:GetService('Lighting');
    local RunService = game:GetService('RunService');
    local InsertService = game:GetService('InsertService');

    local Correction = Lighting:FindFirstChild('backgroundcolor');
    if not Correction then
        Correction = Instance.new('ColorCorrectionEffect');
        Correction.Name = 'backgroundcolor';
        Correction.Parent = Lighting;
    end

    local Blur = Lighting:FindFirstChild('backgroundblur');
    if not Blur then
        Blur = Instance.new('BlurEffect');
        Blur.Name = 'backgroundblur';
        Blur.Size = 0;
        Blur.Enabled = false;
        Blur.Parent = Lighting;
    end

    local GuiHolder = Instance.new('ScreenGui');
    GuiHolder.Name = 'xyrobackground';
    GuiHolder.ResetOnSpawn = false;
    GuiHolder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
    GuiHolder.DisplayOrder = 1;
    ProtectGui(GuiHolder);
    local GuiRoot = CoreGui;
    pcall(function()
        if type(gethui) == 'function' then
            GuiRoot = gethui();
        end
    end);
    GuiHolder.Parent = GuiRoot;

    local Viewport = Instance.new('ViewportFrame');
    Viewport.Name = 'viewport';
    Viewport.Size = UDim2.new(1, 0, 1, 0);
    Viewport.BackgroundColor3 = Color3.new(0, 0, 0);
    Viewport.BackgroundTransparency = 1;
    Viewport.BorderSizePixel = 0;
    Viewport.Active = false;
    Viewport.Ambient = Color3.fromRGB(128, 128, 128);
    Viewport.LightColor = Color3.fromRGB(255, 255, 255);
    Viewport.LightDirection = Vector3.new(-1, -1, -1);
    Viewport.Visible = false;
    Viewport.Parent = GuiHolder;

    local World = Instance.new('WorldModel');
    World.Name = 'world';
    World.Parent = Viewport;

    local ViewCamera = Instance.new('Camera');
    ViewCamera.Name = 'camera';
    ViewCamera.FieldOfView = 70;
    ViewCamera.CFrame = CFrame.new();
    ViewCamera.Parent = World;
    Viewport.CurrentCamera = ViewCamera;

    local Item = Instance.new('Part');
    Item.Name = 'backgrounditem';
    Item.Anchored = true;
    Item.CanCollide = false;
    Item.CanQuery = false;
    Item.CanTouch = false;
    Item.CastShadow = false;
    Item.Massless = true;
    Item.Size = Vector3.new(4, 4, 0.08);
    Item.Color = Color3.fromRGB(255, 255, 255);
    Item.Transparency = 1;
    Item.Material = Enum.Material.Plastic;
    Item.Reflectance = 0;
    Item.Parent = World;

    local Mesh = Instance.new('SpecialMesh');
    Mesh.MeshType = Enum.MeshType.FileMesh;
    Mesh.Scale = Vector3.new(1, 1, 0.02);
    Mesh.Parent = Item;

    BackgroundState = {
        Item = Item;
        Mesh = Mesh;
        Correction = Correction;
        Blur = Blur;
        Gui = GuiHolder;
        Viewport = Viewport;
        World = World;
        ViewCamera = ViewCamera;
        InsertService = InsertService;
        Union = nil;
        Spin = 0;
        Speed = 10;
        Transparency = 100;
        Color = Item.Color;
        Reflectance = 0;
        Material = Enum.Material.Plastic;
        TintColor = Color3.fromRGB(255, 255, 255);
        TintAmount = 0;
        BlurSize = 0;
        TargetSize = 4;
        Flatten = 0.02;
        Connection = nil;
    };

    local State = BackgroundState;

    local function IsShown()
        return Library.Toggled == true;
    end

    local function ApplyTint()
        local A = math.clamp(tonumber(State.TintAmount) or 0, 0, 100) / 100;
        local Keep = 1 - A;
        State.Correction.TintColor = Color3.new(
            Keep + State.TintColor.R * A,
            Keep + State.TintColor.G * A,
            Keep + State.TintColor.B * A
        );
        State.Correction.Enabled = IsShown();
    end

    local function ApplyBlur()
        State.Blur.Size = math.clamp(tonumber(State.BlurSize) or 0, 0, 100);
        State.Blur.Enabled = IsShown() and State.Blur.Size > 0;
    end

    local function PlaceTarget()
        local Target = State.Union or State.Item;
        Target.CFrame = CFrame.new(0, 0, -14) * CFrame.Angles(0, State.Spin, 0);
    end

    local function ApplyItem()
        local Target = State.Union or State.Item;
        local T = math.clamp(tonumber(State.Transparency) or 100, 0, 100) / 100;
        Target.Transparency = T;
        Target.Color = State.Color;
        pcall(function() Target.Reflectance = State.Reflectance end);
        Target.Material = State.Material;
        local Show = IsShown() and T < 1;
        Target.Parent = State.World;
        if State.Union then
            State.Item.Parent = nil;
        end
        if Show then
            PlaceTarget();
        end
        State.Viewport.Visible = Show;
        State.Gui.Enabled = Show;
    end

    local function Refresh()
        ApplyTint();
        ApplyBlur();
        ApplyItem();
    end

    local function LoadUnionPart(Def)
        local Digits = Def.Id:match('%d+');
        if not Digits then return nil end
        local Container = nil;
        if type(game.GetObjects) == 'function' then
            local Ok, Objects = pcall(function() return game:GetObjects('rbxassetid://' .. Digits) end);
            if Ok and type(Objects) == 'table' then
                Container = Objects[1];
            end
        end
        if not Container then
            local Ok, Result = pcall(function() return State.InsertService:LoadAsset(tonumber(Digits)) end);
            if Ok and Result then
                Container = Result;
            end
        end
        if not Container then return nil end
        local Found = nil;
        pcall(function() Found = Container:FindFirstChildWhichIsA('BasePart', true) end);
        local Cloned = nil;
        if Found then
            Cloned = Found:Clone();
        end
        pcall(function() Container:Destroy() end);
        if not Cloned then return nil end
        Cloned.Anchored = true;
        Cloned.CanCollide = false;
        Cloned.CanQuery = false;
        Cloned.CanTouch = false;
        Cloned.CastShadow = false;
        Cloned.Massless = true;
        return Cloned;
    end

    local function FitTarget(Target, Scale)
        local Size = Target.Size;
        local Max = math.max(Size.X, Size.Y, Size.Z);
        if Max <= 0 then return end
        local Factor = (State.TargetSize * Scale) / Max;
        Target.Size = Vector3.new(Size.X * Factor, Size.Y * Factor, Size.Z * Factor * State.Flatten);
    end

    local function SetItem(Name)
        local Def = nil;
        for _, Entry in ipairs(BackgroundItems) do
            if Entry.Name == Name then
                Def = Entry;
                break;
            end
        end
        if not Def then return end
        if State.Union then
            pcall(function() State.Union:Destroy() end);
            State.Union = nil;
        end
        State.Item.Parent = State.World;
        local Scale = tonumber(Def.Scale) or 1;
        local Loaded = nil;
        if Def.Union then
            Loaded = LoadUnionPart(Def);
            if not Loaded then
                pcall(function() Library:Notify('failed to load background item: ' .. tostring(Name), 4) end);
            end
        end
        if Loaded then
            State.Union = Loaded;
            FitTarget(Loaded, Scale);
            State.Item.Parent = nil;
        else
            State.Mesh.MeshId = Def.Union and '' or Def.Id;
            State.Mesh.Scale = Vector3.new(Scale, Scale, Scale * State.Flatten);
        end
        ApplyItem();
    end

    State.ApplyTint = ApplyTint;
    State.ApplyBlur = ApplyBlur;
    State.ApplyItem = ApplyItem;
    State.SetItem = SetItem;
    State.Refresh = Refresh;

    Library:OnToggle(Refresh);

    State.Connection = RunService.RenderStepped:Connect(function(Dt)
        if not State.Viewport.Visible then return end
        State.Spin = State.Spin + math.rad(State.Speed) * Dt;
        PlaceTarget();
    end);

    Library:OnUnload(function()
        pcall(function() if State.Connection then State.Connection:Disconnect() end end);
        pcall(function() if State.Gui then State.Gui:Destroy() end end);
        pcall(function() if State.Union then State.Union:Destroy() end end);
        pcall(function() State.Item:Destroy() end);
        pcall(function() State.Correction:Destroy() end);
        pcall(function() State.Blur:Destroy() end);
    end);

    Refresh();

    return BackgroundState;
end

function Library:CreateSettingsPanes(Tab, Config)
    Config = Config or {};
    local IdPrefix = Config.IdPrefix or 'library_';
    local function Id(Name)
        return IdPrefix .. Name;
    end

    local State = EnsureBackground();

    local MenuBox = Tab:AddLeftTabbox(Id('menu_panes'));
    local MenuPane = MenuBox:AddTab('menu');
    local NotifPane = MenuBox:AddTab('notifications');
    local LookBox = Tab:AddLeftTabbox(Id('appearance_panes'));
    local ThemesPane = LookBox:AddTab('themes');
    local BackgroundPane = LookBox:AddTab('background');

    local AlignmentMap = { left = 'Left', center = 'Center', right = 'Right' };
    local BarSideMap = { top = 'Top', bottom = 'Bottom', left = 'Left', right = 'Right' };
    local SortMap = { ['default'] = 'Default', ['newest first'] = 'Newest First' };
    local MaterialNames = {
        { Label = 'plastic', Value = 'Plastic' };
        { Label = 'smooth plastic', Value = 'SmoothPlastic' };
        { Label = 'neon', Value = 'Neon' };
        { Label = 'metal', Value = 'Metal' };
        { Label = 'glass', Value = 'Glass' };
        { Label = 'force field', Value = 'ForceField' };
        { Label = 'wood', Value = 'Wood' };
        { Label = 'marble', Value = 'Marble' };
        { Label = 'slate', Value = 'Slate' };
    };
    local MaterialLabels = {};
    local MaterialLookup = {};
    for _, Entry in ipairs(MaterialNames) do
        table.insert(MaterialLabels, Entry.Label);
        MaterialLookup[Entry.Label] = Entry.Value;
    end

    local ItemLabels = {};
    local ItemLookup = {};
    for _, Entry in ipairs(BackgroundItems) do
        table.insert(ItemLabels, Entry.Name);
        ItemLookup[Entry.Name] = Entry.Name;
    end

    local function MapValue(Map, Value)
        if type(Value) ~= 'string' then return Value end
        return Map[string.lower(Value)] or Value;
    end

    local function RefreshKeybindMenu()
        local Frame = Library.KeybindFrame;
        if not Frame then return end
        local Mode = Options[Id('keybind_menu_mode')];
        Mode = string.lower(tostring(Mode and Mode.Value or 'toggled'));
        local Shown = Toggles[Id('keybinds')];
        Shown = Shown and Shown.Value == true;
        if Mode == 'always' then
            Shown = true;
        elseif Mode == 'hidden' then
            Shown = false;
        end
        Frame.Visible = Shown;
    end

    local function ApplyMenuTransparency(Value)
        local Outer = Library.KeybindFrame;
        local Inner = Library.KeybindInner;
        if not Outer then return end
        local T = math.clamp(tonumber(Value) or 100, 0, 100) / 100;
        pcall(function() Outer.BackgroundTransparency = T end);
        pcall(function() if Inner then Inner.BackgroundTransparency = T end end);
    end

    MenuPane:AddLabel('menu bind'):AddKeyPicker(Id('menu_bind'), {
        Default = 'RightShift';
        NoUI = true;
        Text = 'menu toggle key';
        Modes = { 'Toggle' };
    });
    Library.ToggleKeybind = Options[Id('menu_bind')];
    MenuPane:AddToggle(Id('keybinds'), { Text = 'keybind menu', Default = false, Callback = RefreshKeybindMenu });
    MenuPane:AddSlider(Id('menu_transparency'), {
        Text = 'menu transparency';
        Min = 0;
        Max = 100;
        Default = 100;
        Rounding = 0;
        Suffix = '%';
        Callback = ApplyMenuTransparency;
    });
    MenuPane:AddDropdown(Id('keybind_menu_mode'), {
        Text = 'keybind menu mode';
        Values = { 'toggled', 'always', 'hidden' };
        Default = 'toggled';
        Callback = RefreshKeybindMenu;
    });
    RefreshKeybindMenu();
    ApplyMenuTransparency(100);

    NotifPane:AddToggle(Id('notify_clip'), {
        Text = 'clip descendants';
        Default = true;
        Callback = function(Value)
            Library:SetNotificationPosition({ ClipDescendants = Value == true });
        end;
    });
    NotifPane:AddSlider(Id('notify_clip_distance'), {
        Text = 'clip past distance';
        Min = 50;
        Max = 600;
        Default = 200;
        Rounding = 0;
        Suffix = 'px';
        Callback = function(Value)
            Library:SetNotificationPosition({ ClipPastDistance = Value });
        end;
    });
    NotifPane:AddToggle(Id('notify_force_color'), {
        Text = 'force color';
        Default = false;
        Callback = function(Value)
            Library:SetNotificationPosition({ ForceColor = Value == true });
        end;
    }):AddColorPicker(Id('notify_force_value'), {
        Default = Color3.fromRGB(71, 119, 182);
        Title = 'force color';
        Callback = function(Color)
            Library:SetNotificationPosition({ ForceColorValue = Color });
        end;
    });
    NotifPane:AddSlider(Id('notify_pos_x'), {
        Text = 'position x';
        Min = 0;
        Max = 100;
        Default = 50;
        Rounding = 0;
        Suffix = '%';
        Callback = function(Value)
            Library:SetNotificationPosition({ ScaleX = Value / 100 });
        end;
    });
    NotifPane:AddSlider(Id('notify_pos_y'), {
        Text = 'position y';
        Min = 0;
        Max = 100;
        Default = 60;
        Rounding = 0;
        Suffix = '%';
        Callback = function(Value)
            Library:SetNotificationPosition({ ScaleY = Value / 100 });
        end;
    });
    NotifPane:AddSlider(Id('notify_transparency'), {
        Text = 'transparency';
        Min = 0;
        Max = 100;
        Default = 25;
        Rounding = 0;
        Suffix = '%';
        Callback = function(Value)
            Library:SetNotificationPosition({ Transparency = Value / 100 });
        end;
    });
    NotifPane:AddDropdown(Id('notify_alignment'), {
        Text = 'alignment';
        Values = { 'left', 'center', 'right' };
        Default = 'center';
        Callback = function(Value)
            Library:SetNotificationPosition({ Alignment = MapValue(AlignmentMap, Value) });
        end;
    });
    NotifPane:AddDropdown(Id('notify_bar_side'), {
        Text = 'bar side';
        Values = { 'top', 'bottom', 'left', 'right' };
        Default = 'bottom';
        Callback = function(Value)
            Library:SetNotificationPosition({ BarSide = MapValue(BarSideMap, Value) });
        end;
    });
    NotifPane:AddDropdown(Id('notify_sort'), {
        Text = 'sort order';
        Values = { 'default', 'newest first' };
        Default = 'default';
        Callback = function(Value)
            Library:SetNotificationPosition({ SortOrder = MapValue(SortMap, Value) });
        end;
    });
    NotifPane:AddButton('send notification', function()
        Library:Notify('example notification', 4);
    end);

    BackgroundPane:AddLabel('item color'):AddColorPicker(Id('background_item_color'), {
        Default = Color3.fromRGB(255, 255, 255);
        Title = 'item color';
        Callback = function(Color)
            State.Color = Color;
            State.ApplyItem();
        end;
    });
    BackgroundPane:AddDropdown(Id('background_item'), {
        Text = 'item';
        Values = ItemLabels;
        Default = 'sword';
        Callback = function(Value)
            State.SetItem(MapValue(ItemLookup, Value));
        end;
    });
    BackgroundPane:AddSlider(Id('background_item_transparency'), {
        Text = 'item transparency';
        Min = 0;
        Max = 100;
        Default = 0;
        Rounding = 0;
        Suffix = '%';
        Callback = function(Value)
            State.Transparency = Value;
            State.ApplyItem();
        end;
    });
    BackgroundPane:AddSlider(Id('background_reflectance'), {
        Text = 'reflectance';
        Min = 0;
        Max = 100;
        Default = 0;
        Rounding = 0;
        Suffix = '%';
        Callback = function(Value)
            State.Reflectance = math.clamp(Value / 100, 0, 1);
            State.ApplyItem();
        end;
    });
    BackgroundPane:AddSlider(Id('background_speed'), {
        Text = 'speed';
        Min = 0;
        Max = 100;
        Default = 10;
        Rounding = 0;
        Callback = function(Value)
            State.Speed = Value;
        end;
    });
    BackgroundPane:AddDropdown(Id('background_material'), {
        Text = 'material';
        Values = MaterialLabels;
        Default = 'plastic';
        Callback = function(Value)
            local Mapped = MapValue(MaterialLookup, Value);
            local Ok, Parsed = pcall(function() return Enum.Material[Mapped] end);
            if Ok and Parsed then
                State.Material = Parsed;
                State.ApplyItem();
            end
        end;
    });
    BackgroundPane:AddDivider();
    BackgroundPane:AddLabel('background color'):AddColorPicker(Id('background_color'), {
        Default = Color3.fromRGB(255, 255, 255);
        Title = 'background color';
        Callback = function(Color)
            State.TintColor = Color;
            State.ApplyTint();
        end;
    });
    BackgroundPane:AddSlider(Id('background_transparency'), {
        Text = 'background transparency';
        Min = 0;
        Max = 100;
        Default = 100;
        Rounding = 0;
        Suffix = '%';
        Callback = function(Value)
            State.TintAmount = 100 - Value;
            State.ApplyTint();
        end;
    });
    BackgroundPane:AddSlider(Id('background_blur'), {
        Text = 'blur';
        Min = 0;
        Max = 100;
        Default = 0;
        Rounding = 0;
        Callback = function(Value)
            State.BlurSize = Value;
            State.ApplyBlur();
        end;
    });
    BackgroundPane:AddSlider(Id('background_contrast'), {
        Text = 'contrast';
        Min = -100;
        Max = 100;
        Default = 0;
        Rounding = 0;
        Callback = function(Value)
            State.Correction.Contrast = Value / 100;
        end;
    });
    BackgroundPane:AddSlider(Id('background_saturation'), {
        Text = 'saturation';
        Min = -100;
        Max = 100;
        Default = 0;
        Rounding = 0;
        Callback = function(Value)
            State.Correction.Saturation = Value / 100;
        end;
    });
    BackgroundPane:AddSlider(Id('background_brightness'), {
        Text = 'brightness';
        Min = -100;
        Max = 100;
        Default = 0;
        Rounding = 0;
        Callback = function(Value)
            State.Correction.Brightness = Value / 100;
        end;
    });

    State.Transparency = 0;
    State.Reflectance = 0;
    State.Speed = 10;
    State.SetItem('sword');
    State.Refresh();

    return {
        Menu = MenuPane;
        Notifications = NotifPane;
        Themes = ThemesPane;
        Background = BackgroundPane;
    };
end

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }
    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end
    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 6 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 650) end
    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if InputService.TouchEnabled then
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        local maxWidth = math.min(Config.Size.X.Offset, vp.X - 20)
        local maxHeight = math.min(Config.Size.Y.Offset, vp.Y - 60)
        Config.Size = UDim2.fromOffset(maxWidth, maxHeight)
    end
    if Config.Center then
        Config.AnchorPoint = Vector2.zero
        Config.Position = UDim2.new(0.5, math.floor(-Config.Size.X.Offset / 2), 0.5, math.floor(-Config.Size.Y.Offset / 2))
    end
    local Window = {
        Tabs = {};
    };
    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });
    Library:MakeDraggable(Outer, 25, true);
    local Inner = Library:Create('Frame', {
        Name = "Inner",
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });
    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Outer:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        Library:QueueResize();
    end);
    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 25);
        Text = Config.Title or '';
        RichText = true;
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 1;
        Parent = Inner;
    });
    local MapNameLabel = Library:CreateLabel({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -7, 0, 0),
        Size = UDim2.new(0, 0, 0, 25),
        Text = 'Loading...',
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 1;
        Parent = Inner;
    });
    Library:RemoveFromRegistry(MapNameLabel);
    Library:AddToRegistry(MapNameLabel, {
        TextColor3 = 'AccentColor';
    });
    MapNameLabel.TextColor3 = Library.AccentColor;
    if Config.StatusLabel then
        MapNameLabel.Text = '';
        Window.StatusLabel = MapNameLabel;
    else
        task.spawn(function()
            local success, info = pcall(function()
                return cloneref(game:GetService("MarketplaceService")):GetProductInfo(game.PlaceId)
            end)
            if success and info and info.Name then
                MapNameLabel.Text = info.Name
            else
                MapNameLabel.Text = game.Name or "Unknown Map"
            end
        end)
    end
    local TabBarOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 0, 29);
        ZIndex = 1;
        Parent = Inner;
    });
    Library:AddToRegistry(TabBarOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });
    local TabBarInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = TabBarOuter;
    });
    Library:AddToRegistry(TabBarInner, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -8, 1, 0);
        ZIndex = 1;
        Parent = TabBarInner;
    });
    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        VerticalAlignment = Enum.VerticalAlignment.Center;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });
    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 58);
        Size = UDim2.new(1, -16, 1, -66);
        ZIndex = 1;
        Parent = Inner;
    });
    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });
    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });
    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 1, -16);
        ZIndex = 2;
        Parent = MainSectionInner;
    });
    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Outer.ClipsDescendants = true;
    local CornerCircle = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.AccentColor;
        BackgroundTransparency = 0.5;
        BorderSizePixel = 0;
        Position = UDim2.new(1, 0, 1, 0);
        Size = UDim2.fromOffset(46, 46);
        ZIndex = 10;
        Parent = Inner;
    });
    Library:Create('UICorner', {
        CornerRadius = UDim.new(1, 0);
        Parent = CornerCircle;
    });
    Library:AddToRegistry(CornerCircle, {
        BackgroundColor3 = 'AccentColor';
    });
    local ResizeWireframe = nil;
    local ResizeStartPos = nil;
    local ResizeStartSize = nil;
    local IsResizing = false;
    local function UpdateResizeWireframe(delta)
        if not ResizeWireframe then
            ResizeWireframe = Library:Create("Frame", {
                Size = Outer.Size,
                Position = Outer.Position,
                AnchorPoint = Outer.AnchorPoint,
                BackgroundTransparency = 1,
                Active = false,
                ZIndex = 100000,
                Parent = ScreenGui,
            });
            local stroke = Library:Create("UIStroke", {
                Color = Library.AccentColor,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = ResizeWireframe,
            });
            Library:AddToRegistry(stroke, { Color = 'AccentColor' });
        end
        local minSize = Library.MinSize or Vector2.new(200, 150);
        local newSize = UDim2.new(
            ResizeStartSize.X.Scale,
            math.max(minSize.X, ResizeStartSize.X.Offset + delta.X),
            ResizeStartSize.Y.Scale,
            math.max(minSize.Y, ResizeStartSize.Y.Offset + delta.Y)
        );
        ResizeWireframe.Size = newSize;
        ResizeWireframe.Position = Outer.Position;
    end
    CornerCircle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not Library.Toggled then return end
            IsResizing = true;
            ResizeStartPos = input.Position;
            ResizeStartSize = Outer.Size;
            UpdateResizeWireframe(Vector2.new(0, 0));
        end
    end);
    Library:GiveSignal(InputService.InputChanged:Connect(function(input)
        if IsResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - ResizeStartPos;
            UpdateResizeWireframe(delta);
        end
    end));
    Library:GiveSignal(InputService.InputEnded:Connect(function(input)
        if IsResizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            IsResizing = false;
            if ResizeWireframe then
                Outer.Size = ResizeWireframe.Size;
                ResizeWireframe:Destroy();
                ResizeWireframe = nil;
                Library:AttemptSave();
            end
        end
    end));
    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;
    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };
        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, Library.FontSize + 2);
        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderSizePixel = 1;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 0.75, 0);
            ZIndex = 1;
            Parent = TabArea;
        });
        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        local TabIndicator = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            Visible = false;
            ZIndex = 104;
            Parent = TabButton;
        });
        Library:AddToRegistry(TabIndicator, { BackgroundColor3 = 'AccentColor' });
        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });
        local Blocker = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 0, 0, 0);
            Visible = false;
            Parent = TabButton;
        });
        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });
        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });
        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });
        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
            end);
        end;
        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab();
            end;
            Library:CloseAllOpenMenus();
            Library:HideAllTooltips();
            Blocker.BackgroundTransparency = 0;
            TabFrame.Visible = true;
            TabIndicator.Visible = true;
        end;
        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            TabFrame.Visible = false;
            TabIndicator.Visible = false;
        end;
        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;
        function Tab:AddGroupbox(Info)
            local Groupbox = {};
            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });
            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });
            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 0, 0, 2);
                TextSize = Library.FontSize;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Center;
                ZIndex = 5;
                Parent = BoxInner;
            });
            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });
            function Groupbox:Resize()
                local Size = 0;
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA('UIListLayout')) and Element.Visible then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;
                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
            end;
            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);
            Groupbox:AddBlank(3);
            Groupbox:Resize();
            Tab.Groupboxes[Info.Name] = Groupbox;
            return Groupbox;
        end;
        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;
        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;
        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };
            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });
            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });
            function Tabbox:AddTab(Name)
                local Tab = {};
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });
                local TabOverlay = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderSizePixel = 1;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Inset;
                    Size = UDim2.new(1, 0, 1, 0);
                    ZIndex = 7;
                    Parent = Button;
                });
                Library:AddToRegistry(TabOverlay, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });
                local TabHighlight = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 8;
                    Parent = Button;
                });
                Library:AddToRegistry(TabHighlight, {
                    BackgroundColor3 = 'AccentColor';
                });
                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = Library.FontSize;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });
                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });
                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });
                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });
                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;
                    Library:CloseAllOpenMenus();
                    Container.Visible = true;
                    Block.Visible = true;
                    TabOverlay.Visible = false;
                    TabHighlight.Visible = true;
                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';
                    Tab:Resize();
                end;
                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;
                    TabOverlay.Visible = true;
                    TabHighlight.Visible = false;
                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;
                function Tab:Resize()
                    local TabCount = 0;
                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1;
                    end;
                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;
                    if (not Container.Visible) then
                        return;
                    end;
                    local Size = 0;
                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;
                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
                end;
                Button.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);
                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;
                setmetatable(Tab, BaseGroupbox);
                Tab:AddBlank(3);
                Tab:Resize();
                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;
                return Tab;
            end;
            Tab.Tabboxes[Info.Name or ''] = Tabbox;
            return Tabbox;
        end;
        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;
        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;
        TabButton.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                Tab:ShowTab();
            end;
        end);
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;
        Window.Tabs[Name] = Tab;
        return Tab;
    end;
    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });
    function Library:CloseAllOpenMenus()
        for Frame in next, Library.OpenedFrames do
            local Entry = Library.OpenedFrames[Frame];
            if type(Entry) == 'function' then
                pcall(Entry);
            end
            if Frame and Frame.Visible then
                Frame.Visible = false;
            end
            Library.OpenedFrames[Frame] = nil;
        end;
        for _, resetter in ipairs(Library.TooltipResetters) do
            pcall(resetter);
        end;
        for _, kp in ipairs(Library.KeyPickerList) do
            pcall(function()
                if kp.ModeSelectOuter then kp.ModeSelectOuter.Visible = false end;
            end);
        end;
    end;
    Library.CloseAllOpenMenus = Library.CloseAllOpenMenus;
    function Library:Toggle()
        Library.Toggled = not Library.Toggled;
        for _, W in ipairs(Library.Windows) do
            if W.AutoToggle then
                W.Visible = Library.Toggled;
                W.Outer.Visible = Library.Toggled;
            end;
        end;
        local Primary = Library.Windows[1];
        if Primary and Primary.ModalElement then
            Primary.ModalElement.Modal = Library.Toggled;
        end;
        pcall(function()
            local Lighting = game:GetService("Lighting")
            local MenuBlur = Lighting:FindFirstChild("menublur")
            if not MenuBlur or not MenuBlur:IsA("BlurEffect") then
                MenuBlur = Instance.new("BlurEffect")
                MenuBlur.Name = "menublur"
                MenuBlur.Size = 0
                MenuBlur.Parent = Lighting
            end
            MenuBlur.Size = Library.Toggled and 20 or 0
            MenuBlur.Enabled = Library.Toggled
        end);
        if not Library.Toggled then
            Library:CloseAllOpenMenus();
            Library:HideAllTooltips();
        end;
        if Library.Toggled and not Library.CursorLoopRunning then
            Library.CursorLoopRunning = true
            task.spawn(function()
                local State = InputService.MouseIconEnabled;
                local Cursor = Drawing.new('Triangle');
                Cursor.Thickness = 1;
                Cursor.Filled = true;
                Cursor.Visible = true;
                local CursorOutline = Drawing.new('Triangle');
                CursorOutline.Thickness = 1;
                CursorOutline.Filled = false;
                CursorOutline.Color = Color3.new(0, 0, 0);
                CursorOutline.Visible = true;
                while Library.Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false;
                    local mPos = InputService:GetMouseLocation();
                    Cursor.Color = Library.AccentColor;
                    Cursor.PointA = Vector2.new(mPos.X, mPos.Y);
                    Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6);
                    Cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16);
                    CursorOutline.PointA = Cursor.PointA;
                    CursorOutline.PointB = Cursor.PointB;
                    CursorOutline.PointC = Cursor.PointC;
                    RenderStepped:Wait();
                end;
                InputService.MouseIconEnabled = State;
                Cursor:Remove();
                CursorOutline:Remove();
                Library.CursorLoopRunning = false
            end);
        end;
        if Library.UseBlur then
            if Library.Toggled then
                Library.BlurEffect.Enabled = true
                Library.BlurEffect.Size = Library.BlurSize
            else
                Library.BlurEffect.Size = 0
                Library.BlurEffect.Enabled = false
            end
        else
            Library.BlurEffect.Size = 0
            Library.BlurEffect.Enabled = false
        end
        for _, Callback in ipairs(Library.ToggleCallbacks) do
            pcall(Callback, Library.Toggled)
        end
    end
    if not Library.ToggleSignalConnected then
        Library.ToggleSignalConnected = true
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
            if Library.PickingKeybind then return end
            local isToggleKey = false
            if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
                if Library.ToggleKeybind.Mode and Library.ToggleKeybind.Mode ~= 'Toggle' then return end
                if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                    if Library.LastBoundKey == Library.ToggleKeybind.Value and (os.clock() - (Library.LastBoundTime or 0)) < 0.5 then
                        return
                    end
                    isToggleKey = true
                end
            elseif type(Library.ToggleKeybind) == 'string' then
                if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind then
                    isToggleKey = true
                end
            elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
                isToggleKey = true
            end
            if isToggleKey then task.spawn(Library.Toggle) end
        end))
    end
    Window.Holder = Outer;
    Window.Outer = Outer;
    Window.ModalElement = ModalElement;
    Window.Visible = false;
    Window.AutoToggle = Config.AutoToggle ~= false;
    function Window:SetVisible(Bool)
        Bool = Bool == true;
        Window.Visible = Bool;
        Window.Outer.Visible = Bool;
        if not Bool then
            Library:CloseAllOpenMenus();
            Library:HideAllTooltips();
        end;
        return Bool;
    end;
    table.insert(Library.Windows, Window);
    if Config.AutoShow then task.spawn(Library.Toggle) end
    return Window;
end;
local function OnPlayerChange()
    local PlayerList = GetPlayersString();
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;
Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);
if InputService.TouchEnabled then
    local MobileGui = Instance.new("ScreenGui")
    MobileGui.Name = "LinoriaMobileUI"
    MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ProtectGui(MobileGui)
    MobileGui.Parent = CoreGui
    local BTN_W, BTN_H = 88, 30
    local BTN_GAP = 40
    local function CreateMobileButton(name, text, startPos)
        local Outer = Library:Create('Frame', {
            Name = name .. "Outer",
            BackgroundColor3 = Library.OutlineColor,
            BorderSizePixel = 0,
            Position = startPos,
            Size = UDim2.new(0, BTN_W, 0, BTN_H),
            ZIndex = 300,
            Parent = MobileGui,
            Active = true,
        })
        Library:AddToRegistry(Outer, { BackgroundColor3 = 'OutlineColor' })
        local AccentFrame = Library:Create('Frame', {
            Name = name .. "Accent",
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 301,
            Parent = Outer,
        })
        Library:AddToRegistry(AccentFrame, { BackgroundColor3 = 'AccentColor' })
        local Inner = Library:Create('Frame', {
            Name = name .. "Inner",
            BackgroundColor3 = Color3.fromRGB(8, 8, 12),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 302,
            Parent = AccentFrame,
        })
        local GradientOverlay = Library:Create('Frame', {
            Name = name .. "Gradient",
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 303,
            Parent = Inner,
        })
        Library:Create('UIGradient', {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.90),
                NumberSequenceKeypoint.new(1, 1.0)
            }),
            Rotation = 90,
            Parent = GradientOverlay,
        })
        local Btn = Library:Create('TextButton', {
            Name = name .. "Btn",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.Code,
            Text = text,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = Library.FontSize - 1,
            ZIndex = 304,
            Parent = Inner,
            Active = true,
        })
        return Outer, Btn
    end
    local ToggleOuter, ToggleBtn = CreateMobileButton("Toggle", "Toggle UI", UDim2.new(0, 10, 0, 10))
    local LockOuter, LockBtn = CreateMobileButton("Lock", "Unlock UI", UDim2.new(0, 10, 0, 10 + BTN_H + (BTN_GAP - BTN_H)))
    local function BindMobileButtonAction(Btn, Outer, ClickAction)
        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPos = nil
        local hasMoved = false
        Btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                hasMoved = false
                dragStart = input.Position
                startPos = Outer.Position
                dragInput = input
                local connection
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        connection:Disconnect()
                        if not hasMoved then
                            ClickAction()
                        end
                    end
                end)
            end
        end)
        InputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 3 then
                    hasMoved = true
                end
                if _G.UIUnlocked and hasMoved then
                    Outer.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end
        end)
    end
    BindMobileButtonAction(ToggleBtn, ToggleOuter, function()
        Library:Toggle()
    end)
    BindMobileButtonAction(LockBtn, LockOuter, function()
        _G.UIUnlocked = not _G.UIUnlocked
        LockBtn.Text = _G.UIUnlocked and "Lock UI" or "Unlock UI"
        LockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    local _origUpdate = Library.UpdateColorsUsingRegistry
    Library.UpdateColorsUsingRegistry = function(self)
        _origUpdate(self)
    end
end
getgenv().Library = Library
return Library
