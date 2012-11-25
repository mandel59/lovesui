export sui

import graphics, mouse from love

tau = 2 * math.pi
quarter_tau = 0.25 * tau

copy = (obj) ->
	{k, v for k, v in pairs obj}

lazy = (obj) ->
	if type(obj) == 'function'
		obj
	else
		-> obj

sui = {}

sui.vbox = (padding, widgets) ->
	func = (f) -> (x, y, ...) ->
		ox, oy = 0, 0
		for i = 1, #widgets
			w, h = f widgets[i], x, y + oy, ...
			ox = math.max ox, w
			oy += h + padding
		return ox, oy - padding
	draw = func (wid, x, y) -> wid.draw x, y
	size = func (wid, x, y) -> wid.size()
	ms = (name) -> func (wid, x, y, ...) ->
		f = wid[name]
		if type(f) == 'function'
			f(x, y, ...)
		else
			wid.size()
	return {draw: draw, size: size,
		mousepressed: ms 'mousepressed',
		mousereleased: ms 'mousereleased',
		children: widgets}

sui.hbox = (padding, widgets) ->
	func = (f) -> (x, y, ...) ->
		ox, oy = 0, 0
		for i = 1, #widgets
			w, h = f widgets[i], x + ox, y, ...
			ox += w + padding
			oy = math.max oy, h
		return ox - padding, oy
	draw = func (wid, x, y) -> wid.draw x, y
	size = func (wid, x, y) -> wid.size()
	ms = (name) -> func (wid, x, y, ...) ->
		f = wid[name]
		if type(f) == 'function'
			f(x, y, ...)
		else
			wid.size()
	return {draw: draw, size: size,
		mousepressed: ms 'mousepressed',
		mousereleased: ms 'mousereleased',
		children: widgets}

sui.margin = (marginx, marginy, widget) ->
	children = {widget}
	draw = (x, y) ->
		w, h = children[1].draw x + marginx, y + marginy
		return w + marginx + marginx, h + marginy + marginy
	size = ->
		w, h = children[1].size()
		return w + marginx + marginx, h + marginy + marginy
	ms = (name) -> (x, y, ...) ->
		f = children[1][name]
		w, h = if type(f) == 'function'
			f(x + marginx, y + marginy, ...)
		else
			children[1].size()
		return w + marginx + marginx, h + marginy + marginy
	return {draw: draw, size: size,
		mousepressed: ms 'mousepressed',
		mousereleased: ms 'mousereleased',
		children: children}

sui.mousepressed = (handler, widget) ->
	nwidget = copy(widget)
	nwidget.mousepressed = (wx, wy, mx, my, button) ->
		x, y = mx - wx, my - wy
		w, h = widget.size()
		if 0 <= x and x < w and 0 <= y and y < h
			handler(x, y, button)
		return w, h
	return nwidget

sui.mousereleased = (handler, widget) ->
	nwidget = copy(widget)
	nwidget.mousepressed = (wx, wy, mx, my, button) ->
		x, y = mx - wx, my - wy
		w, h = widget.size()
		if 0 <= x and x < w and 0 <= y and y < h
			handler(x, y, button)
		return w, h
	return nwidget

sui.font = (font, widget) ->
	nwidget = copy(widget)
	reader = lazy(font)
	nwidget.draw = (x, y) ->
		prev = graphics.getFont()
		graphics.setFont reader()
		w, h = widget.draw x, y
		graphics.setFont prev
		return w, h
	return nwidget

sui.fc = (color, widget) ->
	nwidget = copy(widget)
	reader = lazy(color)
	nwidget.draw = (x, y) ->
		c = reader()
		if c == nil
			return widget.draw x, y
		r, g, b, a = graphics.getColor()
		graphics.setColor c
		w, h = widget.draw x, y
		graphics.setColor r, g, b, a
		return w, h
	return nwidget

sui.bc = (color, widget) ->
	nwidget = copy(widget)
	reader = lazy(color)
	nwidget.draw = (x, y) ->
		c = reader()
		if c == nil
			return widget.draw x, y
		r, g, b, a = graphics.getColor()
		graphics.setColor c
		w, h = widget.size()
		graphics.rectangle 'fill', x, y, w, h
		graphics.setColor r, g, b, a
		return widget.draw x, y
	return nwidget

sui.label = (w, h, caption) ->
	reader = lazy(caption)
	draw = (x, y) ->
		graphics.print reader(), x, y
		return w, h
	size = -> return w, h
	return {draw: draw, size: size}

sui.hbar = (w, h, value) ->
	reader = lazy(value)
	draw = (x, y) ->
		graphics.rectangle 'fill', x, y, w * reader(), h
		return w, h
	size = -> return w, h
	return {draw: draw, size: size}

sui.pie = (diameter, value) ->
	r = diameter / 2
	reader = lazy(value)
	draw = (x, y) ->
		graphics.arc 'fill', x + r, y + r, r, -quarter_tau, tau * reader() - quarter_tau
		return diameter, diameter
	size = -> return diameter, diameter
	return {draw: draw, size: size}
