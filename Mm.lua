--[[
    1NXITER UI LIBRARY - EDIÇÃO AUTO TREINO
    Baseada no script original, agora generalizada para reuso.
    Características:
    - Tema escuro com detalhes em vermelho
    - Bolinha flutuante para minimizar
    - Animações suaves em todos os elementos
    - Sistema de abas com sidebar
    - Componentes: botão, toggle, slider, dropdown, input, keybind, label, profile card
    - Notificações elegantes
    - Sistema de configuração (save/load) opcional
]]

local Library = {
    Flags = {},
    Theme = {
        Background = Color3.fromRGB(20, 20, 20),
        Sidebar    = Color3.fromRGB(30, 0, 0),
        Header     = Color3.fromRGB(180, 0, 0),
        Accent     = Color3.fromRGB(255, 30, 30),
        TextLight  = Color3.fromRGB(240, 240, 240),
        TextDim    = Color3.fromRGB(150, 150, 150),
        ItemBg     = Color3.fromRGB(35, 35, 35),
        Success    = Color3.fromRGB(0, 255, 100),
        Gold       = Color3.fromRGB(255, 215, 0)
    }
}

-- Serviços
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- Utilitários internos
local function Tween(obj, props, time, easing)
    easing = easing or Enum.EasingStyle.Quart
    TweenService:Create(obj, TweenInfo.new(time or 0.3, easing, Enum.EasingDirection.Out), props):Play()
end

local function MakeDraggable(obj, dragArea)
    dragArea = dragArea or obj
    local dragging, dragStart, objStart
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            objStart = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                obj.Position = UDim2.new(objStart.X.Scale, objStart.X.Offset + delta.X, objStart.Y.Scale, objStart.Y.Offset + delta.Y)
            end
        end
    end)
end

-- Sistema de notificações
local NotifyGui = Instance.new("ScreenGui")
NotifyGui.Name = "1NXNotify"
NotifyGui.Parent = CoreGui
NotifyGui.Enabled = true
NotifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local NotifyHolder = Instance.new("Frame")
NotifyHolder.Name = "Holder"
NotifyHolder.Size = UDim2.new(0, 320, 1, -20)
NotifyHolder.Position = UDim2.new(1, -330, 0, 10)
NotifyHolder.BackgroundTransparency = 1
NotifyHolder.Parent = NotifyGui

local NotifyList = Instance.new("UIListLayout")
NotifyList.VerticalAlignment = Enum.VerticalAlignment.Top
NotifyList.Padding = UDim.new(0, 8)
NotifyList.Parent = NotifyHolder

function Library:Notify(title, message, duration)
    duration = duration or 4
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 65)
    frame.BackgroundColor3 = self.Theme.Background
    frame.BorderSizePixel = 0
    frame.Position = UDim2.new(1.5, 0, 0, 0)
    frame.Parent = NotifyHolder
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.Theme.Accent
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 25)
    titleLbl.Position = UDim2.new(0, 10, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title:upper()
    titleLbl.TextColor3 = self.Theme.Accent
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = frame

    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size = UDim2.new(1, -20, 0, 30)
    msgLbl.Position = UDim2.new(0, 10, 0, 28)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = message
    msgLbl.TextColor3 = self.Theme.TextLight
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.TextSize = 12
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextWrapped = true
    msgLbl.Parent = frame

    Tween(frame, {Position = UDim2.new(0, 0, 0, 0)})
    task.delay(duration, function()
        Tween(frame, {Position = UDim2.new(1.5, 0, 0, 0)})
        task.wait(0.3)
        frame:Destroy()
    end)
end

-- Sistema de configuração (opcional)
function Library:SaveConfig(name)
    local success, err = pcall(function()
        if writefile then
            local json = HttpService:JSONEncode(self.Flags)
            writefile(name .. ".1nx", json)
            self:Notify("Config", "Configuração '" .. name .. "' salva!", 3)
        else
            warn("writefile não suportado")
        end
    end)
    if not success then warn("Erro ao salvar config:", err) end
end

function Library:LoadConfig(name)
    if isfile and isfile(name .. ".1nx") then
        local json = readfile(name .. ".1nx")
        local data = HttpService:JSONDecode(json)
        for k, v in pairs(data) do
            self.Flags[k] = v
        end
        self:Notify("Config", "Configuração '" .. name .. "' carregada!", 3)
        return data
    end
end

-- Criação da janela principal
function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "1NXITER UI"
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
    local useMinimize = config.MinimizeButton ~= false
    local theme = config.Theme or {}
    for k, v in pairs(theme) do
        self.Theme[k] = v
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "1NXITER_" .. title:gsub("%s+", "")
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Bolinha flutuante (minimizado)
    local bubble = Instance.new("TextButton")
    bubble.Name = "Bubble"
    bubble.Size = UDim2.new(0, 50, 0, 50)
    bubble.Position = UDim2.new(0, 50, 0, 50)
    bubble.BackgroundColor3 = self.Theme.Background
    bubble.Text = ""
    bubble.Visible = false
    bubble.Parent = screenGui
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)
    local bubbleStroke = Instance.new("UIStroke")
    bubbleStroke.Color = self.Theme.Accent
    bubbleStroke.Thickness = 2
    bubbleStroke.Parent = bubble
    local bubbleIcon = Instance.new("TextLabel")
    bubbleIcon.Size = UDim2.new(1, 0, 1, 0)
    bubbleIcon.BackgroundTransparency = 1
    bubbleIcon.Text = "1NX"
    bubbleIcon.TextColor3 = self.Theme.Accent
    bubbleIcon.Font = Enum.Font.GothamBlack
    bubbleIcon.TextSize = 14
    bubbleIcon.Parent = bubble
    MakeDraggable(bubble)

    -- Janela principal
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 520, 0, 380)
    main.Position = UDim2.new(0.5, -260, 0.5, -190)
    main.BackgroundColor3 = self.Theme.Background
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screenGui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = self.Theme.Header
    header.BorderSizePixel = 0
    header.Parent = main
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)
    -- Correção do canto inferior do header
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 10)
    headerFix.Position = UDim2.new(0, 0, 1, -10)
    headerFix.BackgroundColor3 = self.Theme.Header
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0.8, 0, 1, 0)
    titleLbl.Position = UDim2.new(0.05, 0, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title:upper()
    titleLbl.TextColor3 = self.Theme.TextLight
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 16
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = header

    -- Botões do header
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 35, 1, 0)
    minimizeBtn.Position = UDim2.new(1, -70, 0, 0)
    minimizeBtn.BackgroundTransparency = 1
    minimizeBtn.Text = "—"
    minimizeBtn.TextColor3 = self.Theme.TextLight
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 20
    minimizeBtn.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 1, 0)
    closeBtn.Position = UDim2.new(1, -35, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = self.Theme.TextLight
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = header

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 50, 1, -40)
    sidebar.Position = UDim2.new(0, 0, 0, 40)
    sidebar.BackgroundColor3 = self.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)
    local sidebarFix = Instance.new("Frame")
    sidebarFix.Size = UDim2.new(1, 0, 0, 20)
    sidebarFix.BackgroundColor3 = self.Theme.Sidebar
    sidebarFix.BorderSizePixel = 0
    sidebarFix.Parent = sidebar

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.Padding = UDim.new(0, 15)
    sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    sidebarLayout.Parent = sidebar

    -- Container de abas
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -60, 1, -50)
    container.Position = UDim2.new(0, 55, 0, 45)
    container.BackgroundTransparency = 1
    container.Parent = main

    -- Toggle da janela via tecla
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == toggleKey and not gameProcessed then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)

    -- Lógica de minimizar
    if useMinimize then
        minimizeBtn.Visible = true
        minimizeBtn.MouseButton1Click:Connect(function()
            main.Visible = false
            bubble.Visible = true
        end)
        bubble.MouseButton1Click:Connect(function()
            bubble.Visible = false
            main.Visible = true
        end)
    else
        minimizeBtn.Visible = false
    end

    -- Fechar a UI completamente
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Arrastar a janela
    MakeDraggable(main, header)

    -- Animação de entrada
    main.Size = UDim2.new(0, 0, 0, 0)
    Tween(main, {Size = UDim2.new(0, 520, 0, 380)}, 0.6)

    -- Tabela da janela que será retornada
    local window = {Tabs = {}, Pages = {}, SidebarButtons = {}}

    -- Método para adicionar aba
    function window:AddTab(name)
        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = self.Theme.Accent
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Parent = container
        page.Visible = false

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        pageLayout.Parent = page

        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 10)
        end)

        -- Botão na sidebar
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 35, 0, 35)
        btn.BackgroundTransparency = 1
        btn.Text = name:sub(1, 1) -- primeira letra como ícone
        btn.TextColor3 = self.Theme.TextDim
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 20
        btn.Parent = sidebar

        table.insert(self.SidebarButtons, btn)

        btn.MouseButton1Click:Connect(function()
            for _, p in pairs(container:GetChildren()) do
                if p:IsA("ScrollingFrame") then
                    p.Visible = false
                end
            end
            for _, b in pairs(sidebar:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextColor3 = self.Theme.TextDim
                end
            end
            page.Visible = true
            btn.TextColor3 = self.Theme.Accent
        end)

        -- Se for a primeira aba, ativa
        if #container:GetChildren() == 1 then
            page.Visible = true
            btn.TextColor3 = self.Theme.Accent
        end

        -- Tabela de elementos da aba
        local tab = {}

        -- Adicionar botão
        function tab:AddButton(settings)
            settings = settings or {}
            local text = settings.Text or "Botão"
            local callback = settings.Callback or function() end

            local btnElem = Instance.new("TextButton")
            btnElem.Size = UDim2.new(0.95, 0, 0, 35)
            btnElem.BackgroundColor3 = self.Theme.ItemBg
            btnElem.Text = "   " .. text
            btnElem.TextColor3 = self.Theme.TextLight
            btnElem.Font = Enum.Font.GothamSemibold
            btnElem.TextSize = 14
            btnElem.TextXAlignment = Enum.TextXAlignment.Left
            btnElem.AutoButtonColor = false
            btnElem.Parent = page
            Instance.new("UICorner", btnElem).CornerRadius = UDim.new(0, 6)
            local stroke = Instance.new("UIStroke")
            stroke.Color = self.Theme.Accent
            stroke.Thickness = 1
            stroke.Parent = btnElem

            btnElem.MouseButton1Click:Connect(function()
                Tween(btnElem, {BackgroundColor3 = self.Theme.Accent}, 0.1)
                task.wait(0.1)
                Tween(btnElem, {BackgroundColor3 = self.Theme.ItemBg}, 0.1)
                callback()
            end)

            return btnElem
        end

        -- Adicionar toggle
        function tab:AddToggle(settings)
            settings = settings or {}
            local text = settings.Text or "Toggle"
            local default = settings.Default or false
            local flag = settings.Flag
            local callback = settings.Callback or function() end

            if flag then Library.Flags[flag] = default end

            local container = Instance.new("Frame")
            container.Size = UDim2.new(0.95, 0, 0, 30)
            container.BackgroundTransparency = 1
            container.Parent = page

            local box = Instance.new("TextButton")
            box.Size = UDim2.new(0, 20, 0, 20)
            box.Position = UDim2.new(0, 0, 0.5, -10)
            box.BackgroundColor3 = self.Theme.ItemBg
            box.Text = ""
            box.AutoButtonColor = false
            box.Parent = container
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
            local stroke = Instance.new("UIStroke")
            stroke.Color = default and self.Theme.Accent or self.Theme.TextDim
            stroke.Thickness = 1
            stroke.Parent = box

            local check = Instance.new("Frame")
            check.Size = UDim2.new(0, 14, 0, 14)
            check.AnchorPoint = Vector2.new(0.5, 0.5)
            check.Position = UDim2.new(0.5, 0, 0.5, 0)
            check.BackgroundColor3 = self.Theme.Accent
            check.BorderSizePixel = 0
            check.Visible = default
            check.Parent = box
            Instance.new("UICorner", check).CornerRadius = UDim.new(0, 3)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -30, 1, 0)
            lbl.Position = UDim2.new(0, 30, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = default and self.Theme.TextLight or self.Theme.TextDim
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = container

            local function setState(state)
                default = state
                check.Visible = state
                stroke.Color = state and self.Theme.Accent or self.Theme.TextDim
                lbl.TextColor3 = state and self.Theme.TextLight or self.Theme.TextDim
                if flag then Library.Flags[flag] = state end
                callback(state)
            end

            box.MouseButton1Click:Connect(function()
                setState(not default)
            end)

            -- Também pode clicar no texto
            container.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    setState(not default)
                end
            end)

            return container
        end

        -- Adicionar slider
        function tab:AddSlider(settings)
            settings = settings or {}
            local text = settings.Text or "Slider"
            local min = settings.Min or 0
            local max = settings.Max or 100
            local default = settings.Default or min
            local flag = settings.Flag
            local callback = settings.Callback or function() end
            local decimals = settings.Decimals or 0

            if flag then Library.Flags[flag] = default end

            local container = Instance.new("Frame")
            container.Size = UDim2.new(0.95, 0, 0, 55)
            container.BackgroundColor3 = self.Theme.ItemBg
            container.Parent = page
            Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
            local stroke = Instance.new("UIStroke")
            stroke.Color = self.Theme.TextDim
            stroke.Thickness = 1
            stroke.Parent = container

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 0, 20)
            lbl.Position = UDim2.new(0, 10, 0, 5)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = self.Theme.TextLight
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = container

            local valueLbl = Instance.new("TextLabel")
            valueLbl.Size = UDim2.new(0, 50, 0, 20)
            valueLbl.Position = UDim2.new(1, -60, 0, 5)
            valueLbl.BackgroundTransparency = 1
            valueLbl.Text = tostring(default)
            valueLbl.TextColor3 = self.Theme.Accent
            valueLbl.Font = Enum.Font.GothamBold
            valueLbl.TextSize = 12
            valueLbl.Parent = container

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -20, 0, 8)
            barBg.Position = UDim2.new(0, 10, 0, 35)
            barBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            barBg.Parent = container
            Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = self.Theme.Accent
            fill.Parent = barBg
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local dragging = false

            local function updateFromInput(input)
    local pos = input.Position.X
    local barPos = barBg.AbsolutePosition.X
    local barSize = barBg.AbsoluteSize.X
    local percent = (pos - barPos) / barSize
    percent = math.max(0, math.min(1, percent))

    local value = min + (max - min) * percent
    
    if decimals == 0 then
        value = math.floor(value + 0.5)
    else
        value = tonumber(string.format("%." .. decimals .. "f", value))
    end
    
    fill.Size = UDim2.new(percent, 0, 1, 0)
    valueLbl.Text = tostring(value)
    
    if flag then
        Library.Flags[flag] = value
    end
    
    callback(value)
end

barBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        updateFromInput(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateFromInput(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

return container
