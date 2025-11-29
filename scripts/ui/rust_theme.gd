extends Node

const RUST_COLORS := {
	"bg_dark": Color(0.08, 0.08, 0.09, 0.95),
	"bg_medium": Color(0.12, 0.12, 0.13, 0.95),
	"bg_light": Color(0.18, 0.18, 0.19, 0.9),
	"border": Color(0.35, 0.32, 0.28, 0.8),
	"border_highlight": Color(0.6, 0.5, 0.35, 1.0),
	"accent": Color(0.85, 0.65, 0.35, 1.0),
	"accent_dark": Color(0.6, 0.45, 0.25, 1.0),
	"text": Color(0.9, 0.88, 0.82, 1.0),
	"text_dim": Color(0.6, 0.58, 0.52, 1.0),
	"health": Color(0.8, 0.2, 0.2, 1.0),
	"health_bg": Color(0.3, 0.1, 0.1, 0.8),
	"stamina": Color(0.2, 0.6, 0.8, 1.0),
	"stamina_bg": Color(0.1, 0.2, 0.3, 0.8),
	"hunger": Color(0.85, 0.55, 0.25, 1.0),
	"hunger_bg": Color(0.3, 0.2, 0.1, 0.8),
	"thirst": Color(0.3, 0.6, 0.9, 1.0),
	"thirst_bg": Color(0.1, 0.2, 0.35, 0.8),
	"success": Color(0.3, 0.7, 0.3, 1.0),
	"warning": Color(0.9, 0.7, 0.2, 1.0),
	"danger": Color(0.9, 0.3, 0.2, 1.0),
	"slot_empty": Color(0.15, 0.15, 0.16, 0.9),
	"slot_filled": Color(0.2, 0.2, 0.22, 0.95),
	"slot_selected": Color(0.4, 0.35, 0.25, 1.0)
}

static func create_panel_style(bg_color: Color = RUST_COLORS["bg_dark"], border_color: Color = RUST_COLORS["border"], corner_radius: int = 4) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner_radius)
	style.set_content_margin_all(8)
	return style

static func create_button_style_normal() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = RUST_COLORS["bg_light"]
	style.border_color = RUST_COLORS["border"]
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	return style

static func create_button_style_hover() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = RUST_COLORS["accent_dark"]
	style.border_color = RUST_COLORS["accent"]
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	return style

static func create_button_style_pressed() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = RUST_COLORS["accent"]
	style.border_color = RUST_COLORS["border_highlight"]
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	return style

static func create_progress_bar_bg() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = Color(0.2, 0.2, 0.2, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style

static func create_progress_bar_fill(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style

static func create_slot_style_empty() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = RUST_COLORS["slot_empty"]
	style.border_color = RUST_COLORS["border"]
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

static func create_slot_style_filled() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = RUST_COLORS["slot_filled"]
	style.border_color = RUST_COLORS["border"]
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

static func create_slot_style_selected() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = RUST_COLORS["slot_selected"]
	style.border_color = RUST_COLORS["accent"]
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style

static func apply_to_panel(panel: Panel):
	panel.add_theme_stylebox_override("panel", create_panel_style())

static func apply_to_button(button: Button):
	button.add_theme_stylebox_override("normal", create_button_style_normal())
	button.add_theme_stylebox_override("hover", create_button_style_hover())
	button.add_theme_stylebox_override("pressed", create_button_style_pressed())
	button.add_theme_color_override("font_color", RUST_COLORS["text"])
	button.add_theme_color_override("font_hover_color", RUST_COLORS["text"])
	button.add_theme_color_override("font_pressed_color", Color(0.1, 0.1, 0.1))

static func apply_to_label(label: Label, color: Color = RUST_COLORS["text"]):
	label.add_theme_color_override("font_color", color)

static func apply_to_progress_bar(bar: ProgressBar, fill_color: Color):
	bar.add_theme_stylebox_override("background", create_progress_bar_bg())
	bar.add_theme_stylebox_override("fill", create_progress_bar_fill(fill_color))

static func create_theme() -> Theme:
	var theme = Theme.new()
	
	theme.set_stylebox("panel", "Panel", create_panel_style())
	
	theme.set_stylebox("normal", "Button", create_button_style_normal())
	theme.set_stylebox("hover", "Button", create_button_style_hover())
	theme.set_stylebox("pressed", "Button", create_button_style_pressed())
	theme.set_color("font_color", "Button", RUST_COLORS["text"])
	theme.set_color("font_hover_color", "Button", RUST_COLORS["text"])
	theme.set_color("font_pressed_color", "Button", Color(0.1, 0.1, 0.1))
	
	theme.set_color("font_color", "Label", RUST_COLORS["text"])
	
	theme.set_stylebox("background", "ProgressBar", create_progress_bar_bg())
	
	return theme
