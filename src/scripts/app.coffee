bodyStyle = document.body.style


stage.enableMouseOver()
createjs.Ticker.setFPS(60)
createjs.Ticker.addEventListener "tick", stage


totalWidth  = stage.canvas.width
totalHeight = stage.canvas.height

class Container
  constructor: (name = '', x = 0, y = 0, parent = stage) ->
    @container = new createjs.Container()

    @container.set
      name: name
      x: x
      y: y


    parent.addChild @container

    return @container



class Draw
  constructor: ->
    @draw = new createjs.Shape()

  setListenersForMoveable: ->
    @draw.on 'mouseover', () =>
      command = @draw.graphics.command
      createjs.Tween.get command, {override: true}
        .to({radius: command.radius + 5}, 500, createjs.Ease.elasticOut)

      bodyStyle.cursor = 'pointer'

    @draw.on 'mouseout', () =>
      command = @draw.graphics.command
      createjs.Tween.get command, {override: true}
        .to({radius: command.radius - 5}, 500, createjs.Ease.elasticOut)

      bodyStyle.cursor = 'default'

    @draw.on 'pressup', () =>
      @localX = @localY = null

    @draw.on 'pressmove', (evt) =>
      @localX ?= evt.localX
      @localY ?= evt.localY

      @draw.x = evt.stageX - @localX
      @draw.y = evt.stageY - @localY

      if @draw.x < @draw.graphics.command.radius then @draw.x = @draw.graphics.command.radius
      if @draw.y < @draw.graphics.command.radius then @draw.y = @draw.graphics.command.radius

      if @draw.x > totalWidth - @draw.graphics.command.radius then @draw.x = totalWidth - @draw.graphics.command.radius
      if @draw.y > totalHeight - @draw.graphics.command.radius then @draw.y = totalHeight - @draw.graphics.command.radius

  addChild: (parent = stage) -> parent.addChild @draw



class Line extends Draw
  constructor: (from, to, width, color, parent = stage) ->
    super

    @draw.graphics.setStrokeStyle(width).beginStroke(color).moveTo(from.x, from.y).lineTo(to.x, to.y)
    # @draw.graphics.setStrokeStyle(width).beginStroke(color).moveTo(from.x, from.y).bezierCurveTo(to.x/1.5, to.y/1.5, to.x/1.2, to.y/1.2, to.x, to.y).endStroke() # когда нибудь в далеком-далеком будущем я к тебе вернусь и сделаю проверку по безье, а не по векторам

    @addChild parent

    return @draw



class Circle extends Draw
  constructor: (x, y, radius, color, parent = stage, number) ->
    super

    @draw.graphics.setStrokeStyle(3).beginStroke('#eee').beginFill(color).drawCircle(0, 0, radius);
    @draw.set
      x: x + radius
      y: y + radius

    @setListenersForMoveable()

    @addChild parent

    return @draw



class Field
  constructor: ->
    @count = 7
    @setBackground()
    @start()

  setBackground: ->
    stage.canvas.style.background = '#eee'

  howMuch: ->
    @count = parseInt(prompt('Сколько шаров?', @count))

    while not _.isNumber(@count) or _.isNaN(@count)
      @count = parseInt(prompt('Нужно только число.. Сколько шаров?', @count))

  restart: ->
    @removeAll()
    @start()

  start: ->
    @howMuch()

    @win = false
    @lines = []
    @circles = []

    @createCirclesBlock()
    @createLinesBlock()

    @drawCircles()
    @drawLines()

    @setListeners()

    @reverseLayers()

  setListeners: ->
    for val in @circles
      val.on 'pressmove', () =>
        @drawLines()

      val.on 'pressup', () =>
        @checkIntersection()

  createCirclesBlock: -> @circlesBlock = new Container('circles')
  createLinesBlock  : -> @linesBlock   = new Container('lines')

  drawCircles: ->
    radius = 30
    for i in [0 ... @count]
      circle = new Circle _.random(radius, totalWidth - radius * 2), _.random(radius, totalHeight - radius * 2), radius, '#00bfff', @circlesBlock, i
      @circles.push circle

  drawLines: ->
    @clearContainer @linesBlock

    for val, key in @circles
      if not @circles[key + 1]?
        line = new Line val, @circles[0], 5, '#ff4000', @linesBlock
      else
        line = new Line val, @circles[key + 1], 5, '#ff4000', @linesBlock
      @lines.push line

  checkIntersection: ->
    res = []
    for q in [0 ... @circles.length]
      w = q + 1
      if not @circles[w]? then w = 0
      if @circles[w]?
        for e in [w + 1 ... @circles.length]
          r = e + 1
          if @circles[r]?
            if w == 0 and r == @circles.length - 1 then continue

            p1 = {x: @circles[q].x / 100, y: (totalHeight - @circles[q].y) / 100 }
            p2 = {x: @circles[w].x / 100, y: (totalHeight - @circles[w].y) / 100 }
            p3 = {x: @circles[e].x / 100, y: (totalHeight - @circles[e].y) / 100 }
            p4 = {x: @circles[r].x / 100, y: (totalHeight - @circles[r].y) / 100 }

            x = ((p1.x*p2.y-p2.x*p1.y)*(p4.x-p3.x)-(p3.x*p4.y-p4.x*p3.y)*(p2.x-p1.x))/((p1.y-p2.y)*(p4.x-p3.x)-(p3.y-p4.y)*(p2.x-p1.x));
            y = ((p3.y-p4.y)*x-(p3.x*p4.y-p4.x*p3.y))/(p4.x-p3.x);

            res.push(
              ((p1.x<=x)and(p2.x>=x)and(p3.x<=x)and(p4.x>=x)) or
              ((p1.y<=y)and(p2.y>=y)and(p3.y<=y)and(p4.y>=y)) or
              ((p1.x<=x)and(p2.x>=x)and(p3.x>=x)and(p4.x<=x)) or
              ((p1.y<=y)and(p2.y>=y)and(p3.y>=y)and(p4.y<=y)) or
              ((p1.x>=x)and(p2.x<=x)and(p3.x<=x)and(p4.x>=x)) or
              ((p1.y>=y)and(p2.y<=y)and(p3.y<=y)and(p4.y>=y)) or
              ((p1.x>=x)and(p2.x<=x)and(p3.x>=x)and(p4.x<=x)) or
              ((p1.y>=y)and(p2.y<=y)and(p3.y>=y)and(p4.y<=y))
            )


    if res.every( (val) -> !val)
      @openWinWidow()

  openWinWidow: =>
    return if @win
    @win = true

    alert('Поздравляем!')
    @restart()

  reverseLayers: ->
    stage.children.reverse()

  clearContainer: (container) -> container.removeAllChildren()

  removeAll: ->
    stage.removeAllChildren()

new Field()
