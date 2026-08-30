--!strict
--[[
	Theme
	Petits utilitaires de construction d'interface, pour éviter de répéter
	trente lignes de propriétés à chaque frame.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local Theme = {}

Theme.Palette = GameConfig.Palette
Theme.TitleFont = Enum.Font.GothamBlack
Theme.HeadingFont = Enum.Font.GothamBold
Theme.BodyFont = Enum.Font.Gotham

--- Crée une instance avec ses propriétés et ses enfants d'un coup.
function Theme.create(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = Instance.new(className)
	if props then
		local parent = props.Parent
		props.Parent = nil
		for key, value in pairs(props) do
			(instance :: any)[key] = value
		end
		if children then
			for _, child in ipairs(children) do
				child.Parent = instance
			end
		end
		if parent then
			instance.Parent = parent
		end
	elseif children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	return instance
end

function Theme.corner(radius: number): UICorner
	--- Fenêtre modale : fond assombri, cadre, titre et bouton de fermeture.
--- Renvoie la racine (à afficher/masquer) et le conteneur de contenu.
function Theme.window(parent: Instance, titleText: string, size: UDim2): (Frame, Frame)
	local root = Theme.create("Frame", {
		Name = titleText,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
		Parent = parent,
	})

	local window = Theme.panel({
		Name = "Fenêtre",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundTransparency = 0.02,
		ZIndex = 31,
		Parent = root,
	})

	local header = Theme.create("Frame", {
		Name = "Entête",
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = window,
	})

	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = titleText,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	})

	local close = Theme.create("TextButton", {
		Name = "Fermer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = Theme.Palette.panelLight,
		AutoButtonColor = true,
		Font = Theme.HeadingFont,
		Text = "X",
		TextSize = 18,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	}, { Theme.corner(8) })

	close.Activated:Connect(function()
		root.Visible = false
	end)

	local content = Theme.create("Frame", {
		Name = "Contenu",
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 1, -54),
		BackgroundTransparency = 1,
		ZIndex = 31,
		Parent = window,
	})
	Theme.padding(16).Parent = content

	return root, content
end

return Theme.create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

function Theme.stroke(color: Color3?, thickness: number?, transparency: number?): UIStroke
	--- Fenêtre modale : fond assombri, cadre, titre et bouton de fermeture.
--- Renvoie la racine (à afficher/masquer) et le conteneur de contenu.
function Theme.window(parent: Instance, titleText: string, size: UDim2): (Frame, Frame)
	local root = Theme.create("Frame", {
		Name = titleText,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
		Parent = parent,
	})

	local window = Theme.panel({
		Name = "Fenêtre",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundTransparency = 0.02,
		ZIndex = 31,
		Parent = root,
	})

	local header = Theme.create("Frame", {
		Name = "Entête",
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = window,
	})

	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = titleText,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	})

	local close = Theme.create("TextButton", {
		Name = "Fermer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = Theme.Palette.panelLight,
		AutoButtonColor = true,
		Font = Theme.HeadingFont,
		Text = "X",
		TextSize = 18,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	}, { Theme.corner(8) })

	close.Activated:Connect(function()
		root.Visible = false
	end)

	local content = Theme.create("Frame", {
		Name = "Contenu",
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 1, -54),
		BackgroundTransparency = 1,
		ZIndex = 31,
		Parent = window,
	})
	Theme.padding(16).Parent = content

	return root, content
end

return Theme.create("UIStroke", {
		Color = color or Theme.Palette.stroke,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.padding(all: number): UIPadding
	--- Fenêtre modale : fond assombri, cadre, titre et bouton de fermeture.
--- Renvoie la racine (à afficher/masquer) et le conteneur de contenu.
function Theme.window(parent: Instance, titleText: string, size: UDim2): (Frame, Frame)
	local root = Theme.create("Frame", {
		Name = titleText,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
		Parent = parent,
	})

	local window = Theme.panel({
		Name = "Fenêtre",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundTransparency = 0.02,
		ZIndex = 31,
		Parent = root,
	})

	local header = Theme.create("Frame", {
		Name = "Entête",
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = window,
	})

	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = titleText,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	})

	local close = Theme.create("TextButton", {
		Name = "Fermer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = Theme.Palette.panelLight,
		AutoButtonColor = true,
		Font = Theme.HeadingFont,
		Text = "X",
		TextSize = 18,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	}, { Theme.corner(8) })

	close.Activated:Connect(function()
		root.Visible = false
	end)

	local content = Theme.create("Frame", {
		Name = "Contenu",
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 1, -54),
		BackgroundTransparency = 1,
		ZIndex = 31,
		Parent = window,
	})
	Theme.padding(16).Parent = content

	return root, content
end

return Theme.create("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
	})
end

function Theme.gradient(from: Color3, to: Color3, rotation: number?): UIGradient
	--- Fenêtre modale : fond assombri, cadre, titre et bouton de fermeture.
--- Renvoie la racine (à afficher/masquer) et le conteneur de contenu.
function Theme.window(parent: Instance, titleText: string, size: UDim2): (Frame, Frame)
	local root = Theme.create("Frame", {
		Name = titleText,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
		Parent = parent,
	})

	local window = Theme.panel({
		Name = "Fenêtre",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundTransparency = 0.02,
		ZIndex = 31,
		Parent = root,
	})

	local header = Theme.create("Frame", {
		Name = "Entête",
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = window,
	})

	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = titleText,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	})

	local close = Theme.create("TextButton", {
		Name = "Fermer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = Theme.Palette.panelLight,
		AutoButtonColor = true,
		Font = Theme.HeadingFont,
		Text = "X",
		TextSize = 18,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	}, { Theme.corner(8) })

	close.Activated:Connect(function()
		root.Visible = false
	end)

	local content = Theme.create("Frame", {
		Name = "Contenu",
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 1, -54),
		BackgroundTransparency = 1,
		ZIndex = 31,
		Parent = window,
	})
	Theme.padding(16).Parent = content

	return root, content
end

return Theme.create("UIGradient", {
		Color = ColorSequence.new(from, to),
		Rotation = rotation or 90,
	})
end

--- Panneau standard (fond sombre + liseré violet).
function Theme.panel(props: { [string]: any }?): Frame
	local options: { [string]: any } = props or {}
	if options.BackgroundColor3 == nil then
		options.BackgroundColor3 = Theme.Palette.panel
	end
	local frame = Theme.create("Frame", options)
	frame.BorderSizePixel = 0
	Theme.corner(10).Parent = frame
	Theme.stroke(Theme.Palette.stroke, 2, 0.35).Parent = frame
	return frame
end

--- Bouton rectangulaire du menu (style du croquis : cadre fin, texte centré).
function Theme.menuButton(text: string, order: number): TextButton
	local button = Theme.create("TextButton", {
		Name = text,
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = Theme.Palette.panel,
		BackgroundTransparency = 0.15,
		AutoButtonColor = false,
		Text = text,
		Font = Theme.HeadingFont,
		TextSize = 28,
		TextColor3 = Theme.Palette.text,
		LayoutOrder = order,
		BorderSizePixel = 0,
	}, {
		Theme.corner(6),
		Theme.stroke(Theme.Palette.text, 2, 0.15),
	})
	return button
end

--- Barre de progression simple (vie, énergie, XP).
function Theme.bar(color: Color3): (Frame, Frame)
	local background = Theme.create("Frame", {
		BackgroundColor3 = Color3.fromRGB(14, 14, 22),
		BorderSizePixel = 0,
	}, { Theme.corner(6), Theme.stroke(Color3.fromRGB(60, 60, 84), 1, 0.4) })

	local fill = Theme.create("Frame", {
		Name = "Remplissage",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = background,
	}, { Theme.corner(6) })

	return background, fill
end

--- Fenêtre modale : fond assombri, cadre, titre et bouton de fermeture.
--- Renvoie la racine (à afficher/masquer) et le conteneur de contenu.
function Theme.window(parent: Instance, titleText: string, size: UDim2): (Frame, Frame)
	local root = Theme.create("Frame", {
		Name = titleText,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
		Parent = parent,
	})

	local window = Theme.panel({
		Name = "Fenêtre",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundTransparency = 0.02,
		ZIndex = 31,
		Parent = root,
	})

	local header = Theme.create("Frame", {
		Name = "Entête",
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = window,
	})

	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = titleText,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	})

	local close = Theme.create("TextButton", {
		Name = "Fermer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = Theme.Palette.panelLight,
		AutoButtonColor = true,
		Font = Theme.HeadingFont,
		Text = "X",
		TextSize = 18,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	}, { Theme.corner(8) })

	close.Activated:Connect(function()
		root.Visible = false
	end)

	local content = Theme.create("Frame", {
		Name = "Contenu",
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 1, -54),
		BackgroundTransparency = 1,
		ZIndex = 31,
		Parent = window,
	})
	Theme.padding(16).Parent = content

	return root, content
end

return Theme
