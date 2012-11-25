require 'sui'

import mouse from love
import setColor, setFont, newFont from love.graphics

value1 = 0
ui_x, ui_y = 100, 100
text = ""

value2f = -> math.min(value1 * 4, 100)

clicked1 = 0
clicked2 = false
mouse_x, mouse_y = 0, 0

-- these shrink-wrapped variables are initialized in love.load
font = -> newFont(16)
bigFont = -> newFont(24)
ui = -> sui.vbox 5, {
	sui.font bigFont, sui.label 200, 24, "Hello, world!"
	sui.label 200, 16, -> tostring value1
	sui.bc {50, 50, 50, 255}, sui.hbar 200, 16, -> value1 / 100
	sui.hbox 5, {
		sui.pie 50, -> value1 / 100
		sui.margin 10, 10, sui.pie 30, -> 1 - value1 / 100
		sui.fc -> if value2f() == 100
				return {255, 128, 64, 255},
			sui.pie 50, -> value2f() / 100
	}
	sui.label 200, 16, -> "Type away! #text = " .. tostring(#text)
	sui.label 200, 16, -> text
	sui.margin 5, 5, sui.mousepressed (x, y, button) ->
			if button == 'l'
				clicked1 = 1
				mouse_x, mouse_y = x, y,
		sui.bc {50, 50, 50, 255}, sui.margin 30, 20, sui.label 120, 32, ->
			if clicked1 > 0
				"You clicked at \n#{mouse_x}, #{mouse_y}"
			else
				'Click me!'
}

love.load = (arg) ->
	-- initialize shrink-wrapped variables
	font = font()
	bigFont = bigFont()
	ui = ui()
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
	return

love.draw = ->
	ui.draw(ui_x, ui_y)
	return

love.mousepressed = (x, y, button) ->
	ui.mousepressed(ui_x, ui_y, x, y, button)
	return

love.keypressed = (key, unicode) ->
	switch key
		when 'f5'
			love.filesystem.load('sui.lua')()
			love.filesystem.load('main.lua')()
			love.load()
		when 'f6'
			screenshot = love.graphics.newScreenshot()
			screenshot\encode('out.png')
			print 'screenshot saved'
		when 'backspace'
			text = string.sub(text, 1, -2)
		when 'return'
			text ..= '\n'
		else
			if 0x20 <= unicode and unicode < 0x7F
				text ..= string.char(unicode)
	return
