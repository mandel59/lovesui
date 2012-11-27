require 'sui'

import mouse from love
import setColor, setFont, newFont from love.graphics

value1 = 0
ui_x, ui_y = 100, 100
text = ""

value2f = -> math.min(value1 * 4, 100)

clicked1 = 0
mouse_x, mouse_y = 0, 0

-- these shrink-wrapped variables are initialized in love.load
font = -> newFont(16)
bigFont = -> newFont(24)

local ui
focus_get = (widget) ->
	local obj
	obj = sui.focusstop sui.mousepressed ->
			changefocus = ui.changefocus
			if type(changefocus) == 'function'
				changefocus(obj),
		widget
	return obj
ui = sui.focusroot sui.vbox 5, {
	focus_get sui.focusbc {64, 64, 64, 255},
		sui.font -> bigFont,
			sui.label 200, 24, "Hello, world!"
	focus_get sui.focusbc {64, 64, 64, 255},
		sui.label 200, 16, -> tostring value1
	sui.bc {50, 50, 50, 255}, sui.hbar 200, 16, -> value1 / 100
	focus_get sui.focusbc {64, 64, 64, 255}, sui.hbox 5, {
		sui.focusstop sui.focusbc {64, 64, 64, 255},
			sui.pie 50, -> value1 / 100
		sui.margin 10, 10, sui.focusstop sui.focusbc {64, 64, 64, 255},
			sui.pie 30, -> 1 - value1 / 100
		sui.focusstop sui.focusbc {64, 64, 64, 255},
			sui.fc -> if value2f() == 100 then return {255, 128, 64, 255},
				sui.pie 50, -> value2f() / 100
	}
	focus_get sui.bc {32, 32, 32, 255}, sui.focusbc {64, 64, 64, 255}, sui.vbox 5, {
		sui.focusoption {
			[true]: sui.label 200, 16, -> "Type away! #text = " .. tostring(#text)
			[false]: sui.label 200, 16, -> "Focus on me!"
		}
		sui.focusevent 'keypressed', (key, unicode) ->
				if key == 'backspace'
					text = string.sub(text, 1, -2)
				elseif 0x20 <= unicode and unicode < 0x7F
					text ..= string.char(unicode),
			sui.label 200, 16, -> text
	}
	focus_get sui.focusbc {64, 64, 64, 255}, sui.margin 5, 5, sui.clicked (x, y, button) ->
			if button == 'l'
				clicked1 = 1
				mouse_x, mouse_y = x, y,
		sui.bc {50, 50, 50, 255},
			sui.margin 30, 20,
				sui.label 120, 32, ->
					if clicked1 > 0
						"You clicked at \n#{mouse_x}, #{mouse_y}"
					else
						'Click me!'
}

love.load = (arg) ->
	-- initialize shrink-wrapped variables
	font = font()
	bigFont = bigFont()
	-- settings
	setFont font
	setColor 200, 200, 200
	return

love.update = (dt) ->
	value1 += 2 * dt
	if value1 > 100
		value1 = 0
	if clicked1 > 0
		clicked1 -= dt
	ui.update(dt)
	return

love.draw = ->
	ui.draw(ui_x, ui_y)
	return

love.mousepressed = (x, y, button) ->
	ui.mousepressed(ui_x, ui_y, x, y, button)
	return

love.mousereleased = (x, y, button) ->
	ui.mousereleased(ui_x, ui_y, x, y, button)
	return

love.keypressed = (key, unicode) ->
	switch key
		when 'tab'
			ui.changefocus(love.keyboard.isDown('lshift', 'rshift'))
		when 'f5'
			love.filesystem.load('sui.lua')()
			love.filesystem.load('main.lua')()
			love.load()
		when 'f6'
			screenshot = love.graphics.newScreenshot()
			screenshot\encode('out.png')
			print 'screenshot saved'
		else
			ui.keypressed(key, unicode)
	return
