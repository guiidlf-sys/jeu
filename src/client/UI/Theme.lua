--!strict
--[[
	Theme
	Le système de design du jeu. Tout ce qui donne son identité visuelle à
	l'interface vit ici : palette, typographies, panneaux anguleux à équerres,
	boutons, jauges, fenêtres modales et animations.

	Principe : des cadres nets plutôt que des coins arrondis, des équerres aux
	angles comme sur les interfaces « système » d'anime, des dégradés sombres
	et deux accents lumineux (violet maudit, cyan spirituel).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local Theme = {}

Theme.Palette = GameConfig.Palette

------------------------------------------------------------------
-- Typographies
------------------------------------------------------------------
-- Certaines polices n'existent pas sur toutes les versions du client :
-- on tente la première disponible, avec un repli sûr.
local function resolveFont(candidates: { string }, fallback: Enum.Font): Enum.Font
	for _, name in ipairs(candidates) do
		local ok, value = pcall(function()
			return (Enum.Font :: any)[name]
		end)
		if ok and value then
			return value
		end
	end
	return fallback
end

Theme.TitleFont = resolveFont({ "Sarpanch", "GothamBlack" }, Enum.Font.GothamBlack)
Theme.DisplayFont = resolveFont({ "Michroma", "Sarpanch", "GothamBlack" }, Enum.Font.GothamBlack)
Theme.HeadingFont = resolveFont({ "GothamBold", "GothamBlack" }, Enum.Font.GothamBold)
Theme.BodyFont = resolveFont({ "Gotham", "SourceSans" }, Enum.Font.Gotham)
Theme.NumberFont = resolveFont({ "GothamBlack", "SourceSansBold" }, Enum.Font.GothamBlack)

------------------------------------------------------------------
-- Base
------------------------------------------------------------------

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
	return Theme.create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

function Theme.stroke(color: Color3?, thickness: number?, transparency: number?): UIStroke
	return Theme.create("UIStroke", {
		Color = color or Theme.Palette.stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.padding(all: number, horizontal: number?): UIPadding
	local side = horizontal or all
	return Theme.create("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, side),
		PaddingRight = UDim.new(0, side),
	})
end

function Theme.list(direction: Enum.FillDirection?, padding: number?, align: Enum.HorizontalAlignment?): UIListLayout
	return Theme.create("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 8),
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function Theme.gradient(from: Color3, to: Color3, rotation: number?): UIGradient
	return Theme.create("UIGradient", {
		Color = ColorSequence.new(from, to),
		Rotation = rotation or 90,
	})
end

------------------------------------------------------------------
-- Décorations
------------------------------------------------------------------

--- Équerres lumineuses aux quatre angles : la signature visuelle du jeu.
function Theme.brackets(parent: GuiObject, color: Color3?, length: number?, thickness: number?)
	local tone = color or Theme.Palette.accent
	local size = length or 16
	local weight = thickness or 2

	local corners = {
		{ anchor = Vector2.new(0, 0), position = UDim2.fromScale(0, 0), x = 1, y = 1 },
		{ anchor = Vector2.new(1, 0), position = UDim2.fromScale(1, 0), x = -1, y = 1 },
		{ anchor = Vector2.new(0, 1), position = UDim2.fromScale(0, 1), x = 1, y = -1 },
		{ anchor = Vector2.new(1, 1), position = UDim2.fromScale(1, 1), x = -1, y = -1 },
	}

	local holder = Theme.create("Frame", {
		Name = "Équerres",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = (parent.ZIndex or 1) + 1,
		Parent = parent,
	})

	for index, corner in ipairs(corners) do
		-- Une barre horizontale et une barre verticale par angle.
		Theme.create("Frame", {
			Name = "H" .. index,
			AnchorPoint = corner.anchor,
			Position = corner.position,
			Size = UDim2.fromOffset(size, weight),
			BackgroundColor3 = tone,
			BorderSizePixel = 0,
			ZIndex = holder.ZIndex,
			Parent = holder,
		})
		Theme.create("Frame", {
			Name = "V" .. index,
			AnchorPoint = corner.anchor,
			Position = corner.position,
			Size = UDim2.fromOffset(weight, size),
			BackgroundColor3 = tone,
			BorderSizePixel = 0,
			ZIndex = holder.ZIndex,
			Parent = holder,
		})
	end

	return holder
end

--- Halo : deux cadres concentriques translucides, faute d'ombres portées.
function Theme.glow(target: GuiObject, color: Color3?, intensity: number?)
	local tone = color or Theme.Palette.accent
	local strength = intensity or 1

	for index = 1, 2 do
		local spread = 4 * index
		Theme.create("Frame", {
			Name = "Halo" .. index,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, spread * 2, 1, spread * 2),
			BackgroundTransparency = 1,
			ZIndex = math.max((target.ZIndex or 1) - 1, 0),
			Parent = target,
		}, {
			Theme.stroke(tone, 1, 1 - (0.16 * strength) / index),
		})
	end
end

--- Filet lumineux horizontal (séparateur, soulignement de titre).
function Theme.rule(color: Color3?, thickness: number?): Frame
	return Theme.create("Frame", {
		Name = "Filet",
		Size = UDim2.new(1, 0, 0, thickness or 1),
		BackgroundColor3 = color or Theme.Palette.stroke,
		BorderSizePixel = 0,
	}, {
		Theme.create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(0.75, 0.75),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
end

--- Petite étiquette anguleuse (catégorie, rang, raccourci clavier).
function Theme.chip(text: string, color: Color3, props: { [string]: any }?): TextLabel
	local options: { [string]: any } = props or {}
	options.BackgroundColor3 = color
	options.BackgroundTransparency = 0.82
	options.BorderSizePixel = 0
	options.Font = Theme.HeadingFont
	options.Text = text
	options.TextColor3 = color
	options.TextSize = options.TextSize or 11

	local chip = Theme.create("TextLabel", options)
	Theme.corner(3).Parent = chip
	Theme.stroke(color, 1, 0.55).Parent = chip
	return chip
end

------------------------------------------------------------------
-- Panneaux
------------------------------------------------------------------

export type PanelOptions = {
	accent: Color3?,
	brackets: boolean?,
	glow: boolean?,
	gradient: boolean?,
}

--- Panneau standard : fond dégradé, liseré fin, équerres aux angles.
function Theme.panel(props: { [string]: any }?, options: PanelOptions?): Frame
	local settings: PanelOptions = options or {}
	local tone = settings.accent or Theme.Palette.stroke

	local values: { [string]: any } = props or {}
	if values.BackgroundColor3 == nil then
		values.BackgroundColor3 = Theme.Palette.panel
	end
	if values.BackgroundTransparency == nil then
		values.BackgroundTransparency = 0.06
	end

	local frame = Theme.create("Frame", values)
	frame.BorderSizePixel = 0

	Theme.corner(4).Parent = frame
	Theme.stroke(tone, 1, 0.45).Parent = frame

	if settings.gradient ~= false then
		Theme.create("UIGradient", {
			Color = ColorSequence.new(Theme.Palette.panelLight, Theme.Palette.panel),
			Rotation = 90,
			Parent = frame,
		})
	end

	if settings.brackets ~= false then
		Theme.brackets(frame, settings.accent or Theme.Palette.accent, 14, 2)
	end

	if settings.glow then
		Theme.glow(frame, settings.accent or Theme.Palette.accent)
	end

	return frame
end

--- Zone de contenu d'un panneau. À utiliser dès qu'on veut un UIListLayout
--- ou un UIGridLayout dedans : les décorations (équerres, halos) sont des
--- GuiObject, un layout posé sur le panneau leur donnerait une place.
function Theme.content(panel: GuiObject, padding: number?, side: number?): Frame
	local frame = Theme.create("Frame", {
		Name = "Contenu",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = (panel.ZIndex or 1) + 1,
		Parent = panel,
	})
	if padding then
		Theme.padding(padding, side).Parent = frame
	end
	return frame
end

------------------------------------------------------------------
-- Boutons
------------------------------------------------------------------

--- Anime un bouton au survol : liseré qui s'allume, fond qui se teinte.
function Theme.hover(button: GuiButton, accent: Color3, baseColor: Color3?, baseTransparency: number?)
	local stroke = button:FindFirstChildOfClass("UIStroke")
	local restColor = baseColor or button.BackgroundColor3
	local restTransparency = baseTransparency or button.BackgroundTransparency

	local function animate(hovering: boolean)
		TweenService:Create(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {
			BackgroundColor3 = if hovering then accent else restColor,
			BackgroundTransparency = if hovering then 0.35 else restTransparency,
		}):Play()
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.14), {
				Color = accent,
				Transparency = if hovering then 0 else 0.45,
			}):Play()
		end
	end

	button.MouseEnter:Connect(function()
		-- On mémorise l'état courant : il a pu changer depuis la création.
		restColor = button.BackgroundColor3
		restTransparency = button.BackgroundTransparency
		animate(true)
	end)
	button.MouseLeave:Connect(function()
		animate(false)
	end)
end

--- Bouton d'action compact, utilisé partout dans les fenêtres.
function Theme.button(text: string, accent: Color3, props: { [string]: any }?): TextButton
	local values: { [string]: any } = props or {}
	values.BackgroundColor3 = values.BackgroundColor3 or Theme.Palette.panelLight
	values.BackgroundTransparency = values.BackgroundTransparency or 0.2
	values.AutoButtonColor = false
	values.Font = Theme.HeadingFont
	values.Text = text
	values.TextSize = values.TextSize or 14
	values.TextColor3 = values.TextColor3 or Theme.Palette.text
	values.BorderSizePixel = 0

	local button = Theme.create("TextButton", values)
	Theme.corner(3).Parent = button
	Theme.stroke(accent, 1, 0.45).Parent = button
	Theme.hover(button, accent)

	-- Barre d'accent à gauche : donne du poids sans surcharger.
	Theme.create("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = button.ZIndex + 1,
		Parent = button,
	})

	return button
end

--- Grande dalle du menu principal (« JOUER », « BOUTIQUE »…).
function Theme.menuButton(text: string, order: number): TextButton
	local button = Theme.create("TextButton", {
		Name = text,
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = Theme.Palette.panel,
		BackgroundTransparency = 0.25,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		BorderSizePixel = 0,
	}, {
		Theme.corner(3),
		Theme.stroke(Theme.Palette.stroke, 1, 0.4),
		Theme.create("UIGradient", {
			Color = ColorSequence.new(Theme.Palette.panelLight, Theme.Palette.panel),
			Rotation = 90,
		}),
	})

	Theme.brackets(button, Theme.Palette.accent, 12, 2)

	-- Barre d'accent qui s'étire au survol.
	local accentBar = Theme.create("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Palette.accent,
		BorderSizePixel = 0,
		ZIndex = button.ZIndex + 2,
		Parent = button,
	})

	local stroke = button:FindFirstChildOfClass("UIStroke")

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 0.08,
		}):Play()
		TweenService:Create(accentBar, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 3, 1, 0),
		}):Play()
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.16), {
				Color = Theme.Palette.accent,
				Transparency = 0,
			}):Play()
		end
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 0.25,
		}):Play()
		TweenService:Create(accentBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 3, 0, 18),
		}):Play()
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.16), {
				Color = Theme.Palette.stroke,
				Transparency = 0.4,
			}):Play()
		end
	end)

	return button
end

------------------------------------------------------------------
-- Jauges
------------------------------------------------------------------

--- Jauge : fond creusé, remplissage dégradé, reflet en haut.
function Theme.bar(color: Color3): (Frame, Frame)
	local background = Theme.create("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 9, 16),
		BorderSizePixel = 0,
	}, {
		Theme.corner(2),
		Theme.stroke(Color3.fromRGB(52, 48, 76), 1, 0.35),
	})

	local fill = Theme.create("Frame", {
		Name = "Remplissage",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = background,
	}, {
		Theme.corner(2),
		Theme.create("UIGradient", {
			Color = ColorSequence.new(color, color:Lerp(Color3.new(0, 0, 0), 0.45)),
			Rotation = 90,
		}),
	})

	-- Reflet supérieur.
	Theme.create("Frame", {
		Name = "Reflet",
		Size = UDim2.new(1, 0, 0.35, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = fill.ZIndex + 1,
		Parent = fill,
	})

	return background, fill
end

------------------------------------------------------------------
-- Animations utilitaires
------------------------------------------------------------------

--- Fait glisser un dégradé en boucle : effet de balayage lumineux.
function Theme.shimmer(target: GuiObject, color: Color3, duration: number?)
	local gradient = Theme.create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.45, color),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.55, color),
			ColorSequenceKeypoint.new(1, color),
		}),
		Offset = Vector2.new(-1, 0),
		Parent = target,
	})

	local tween = TweenService:Create(
		gradient,
		TweenInfo.new(duration or 3.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 1.5),
		{ Offset = Vector2.new(1, 0) }
	)
	tween:Play()
	return gradient
end

--- Pulsation lente d'un liseré, pour attirer l'œil sans agresser.
function Theme.pulse(stroke: UIStroke, from: number?, to: number?, duration: number?)
	stroke.Transparency = from or 0.6
	TweenService:Create(
		stroke,
		TweenInfo.new(duration or 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = to or 0.05 }
	):Play()
end

------------------------------------------------------------------
-- Fenêtres modales
------------------------------------------------------------------

--- Fenêtre : fond assombri, cadre à équerres, titre en police d'affichage.
--- Renvoie la racine (à afficher/masquer) et le conteneur de contenu.
function Theme.window(parent: Instance, titleText: string, size: UDim2): (Frame, Frame)
	local root = Theme.create("Frame", {
		Name = titleText,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Palette.void,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
		Parent = parent,
	})

	local window = Theme.panel({
		Name = "Fenêtre",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0.88, 0),
		BackgroundTransparency = 0.02,
		ZIndex = 31,
		Parent = root,
	}, { accent = Theme.Palette.accent, brackets = true, glow = true })

	-- Reste lisible sur petit écran, sans jamais dépasser la taille voulue.
	Theme.create("UISizeConstraint", {
		MaxSize = Vector2.new(size.X.Offset, size.Y.Offset),
		MinSize = Vector2.new(360, 320),
		Parent = window,
	})

	local header = Theme.create("Frame", {
		Name = "Entête",
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = window,
	})

	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(24, 12),
		Size = UDim2.new(1, -90, 0, 26),
		BackgroundTransparency = 1,
		Font = Theme.DisplayFont,
		Text = titleText,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Palette.text,
		ZIndex = 32,
		Parent = header,
	})

	local underline = Theme.create("Frame", {
		Name = "Soulignement",
		Position = UDim2.fromOffset(24, 44),
		Size = UDim2.fromOffset(64, 2),
		BackgroundColor3 = Theme.Palette.accent,
		BorderSizePixel = 0,
		ZIndex = 32,
		Parent = header,
	})
	Theme.shimmer(underline, Theme.Palette.accent, 2.5)

	local close = Theme.create("TextButton", {
		Name = "Fermer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Theme.Palette.panelLight,
		BackgroundTransparency = 0.2,
		AutoButtonColor = false,
		Font = Theme.HeadingFont,
		Text = "✕",
		TextSize = 16,
		TextColor3 = Theme.Palette.textDim,
		BorderSizePixel = 0,
		ZIndex = 32,
		Parent = header,
	}, { Theme.corner(3), Theme.stroke(Theme.Palette.stroke, 1, 0.45) })
	Theme.hover(close, Theme.Palette.danger)

	close.Activated:Connect(function()
		root.Visible = false
	end)

	local content = Theme.create("Frame", {
		Name = "Contenu",
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 1, -62),
		BackgroundTransparency = 1,
		ZIndex = 31,
		Parent = window,
	})
	Theme.padding(20, 24).Parent = content

	-- Ouverture animée : la fenêtre grandit légèrement en apparaissant.
	root:GetPropertyChangedSignal("Visible"):Connect(function()
		if not root.Visible then
			return
		end
		window.Size = UDim2.new(0.9, 0, 0.85, 0)
		TweenService:Create(window, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.92, 0, 0.88, 0),
		}):Play()

		root.BackgroundTransparency = 1
		TweenService:Create(root, TweenInfo.new(0.2), { BackgroundTransparency = 0.35 }):Play()
	end)

	return root, content
end

return Theme
