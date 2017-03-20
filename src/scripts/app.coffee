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



new class Field
  constructor: ->
    document.getElementsByTagName('button')[0].addEventListener "click", () => @resetWins()

    @count = 7

    if not localStorage.getItem('wins')?  then localStorage.setItem('wins', 0)
    if not localStorage.getItem('count')? then localStorage.setItem('count', @count)

    @updateWinsView()

    @setBackground()
    @start()

  resetWins: ->
    localStorage.removeItem('wins')
    localStorage.setItem('wins', 0)
    @updateWinsView()

  updateWinsView: ->
    document.getElementsByClassName('Wins')[0].innerText = localStorage.getItem('wins')

  setBackground: ->
    stage.canvas.style.background = '#eee'

  howMuch: (win) ->
    @count = localStorage.getItem('count')

    if win then t = 'Поздравляем! ' else t = ''
    @count = parseInt(prompt("#{t}Сколько линий?", @count))

    while not _.isNumber(@count) or _.isNaN(@count)
      @count = parseInt(prompt('Нужно только число. Сколько линий?', @count))

    while @count < 4
      @count = parseInt(prompt('Не, так не интересно, давай больше. Сколько линий?', 4))

    localStorage.setItem('count', @count)

  restart: (recreate, win) ->
    @removeAll()
    @start recreate, win

  start: (recreate, win) ->
    if not recreate
      @howMuch win
      @proportion = @getProportion()
      @win = false

    @createCirclesBlock()
    @createLinesBlock()

    @drawCircles()
    @drawLines()

    @setListeners()

    @reverseLayers()

    @checkIntersection true

    @circlesBlock.visible = true
    @linesBlock.visible = true

  setListeners: ->
    for val in @circles
      val.on 'pressmove', () =>
        @drawLines()
        @checkIntersection()

      val.on 'pressup', () =>
        @checkIntersection false, true

  createCirclesBlock: ->
    @circlesBlock = new Container('circles')
    @circlesBlock.visible = false

  createLinesBlock: ->
    @linesBlock = new Container('lines')
    @linesBlock.visible = false

  getProportion: ->
    maxRadius = 25
    minRadius = 13
    rp = (maxRadius - minRadius) / 70
    if @count >= 70 then @radius = minRadius
    else if @count <= 10 then @radius = maxRadius
    else @radius = maxRadius - ((@count - minRadius) * rp)

    maxStrokeWidth = 5
    minStrokeWidth = 2
    lp = (maxStrokeWidth - minStrokeWidth) / 70
    if @count >= 70 then @strokeWidth = minStrokeWidth
    else if @count <= 10 then @strokeWidth = maxStrokeWidth
    else @strokeWidth = maxStrokeWidth - ((@count - minStrokeWidth) * lp)

  drawCircles: ->
    @circles = []

    for i in [0 ... @count]
      circle = new Circle _.random(@radius, totalWidth - @radius * 2), _.random(@radius, totalHeight - @radius * 2), @radius, '#00bfff', @circlesBlock, i
      @circles.push circle

  drawLines: ->
    @clearContainer @linesBlock
    @lines = []

    for val, key in @circles
      next = key + 1
      if not @circles[next]?
        line = new Line val, @circles[0], @strokeWidth, '#bfff00', @linesBlock
        val.line = line
      else
        line = new Line val, @circles[next], @strokeWidth, '#bfff00', @linesBlock
        val.line = line

      @lines.push line

  checkIntersection: (isFirst, finish) ->
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

            x = ((p1.x*p2.y-p2.x*p1.y)*(p4.x-p3.x)-(p3.x*p4.y-p4.x*p3.y)*(p2.x-p1.x))/((p1.y-p2.y)*(p4.x-p3.x)-(p3.y-p4.y)*(p2.x-p1.x))
            y = ((p3.y-p4.y)*x-(p3.x*p4.y-p4.x*p3.y))/(p4.x-p3.x)

            check =
              ((p1.x<=x)and(p2.x>=x)and(p3.x<=x)and(p4.x>=x)) or
              ((p1.y<=y)and(p2.y>=y)and(p3.y<=y)and(p4.y>=y)) or
              ((p1.x<=x)and(p2.x>=x)and(p3.x>=x)and(p4.x<=x)) or
              ((p1.y<=y)and(p2.y>=y)and(p3.y>=y)and(p4.y<=y)) or
              ((p1.x>=x)and(p2.x<=x)and(p3.x<=x)and(p4.x>=x)) or
              ((p1.y>=y)and(p2.y<=y)and(p3.y<=y)and(p4.y>=y)) or
              ((p1.x>=x)and(p2.x<=x)and(p3.x>=x)and(p4.x<=x)) or
              ((p1.y>=y)and(p2.y<=y)and(p3.y>=y)and(p4.y<=y))

            if check
              @circles[q].line.graphics._stroke.style = '#ff0040'
              @circles[e].line.graphics._stroke.style = '#ff0040'


            if finish or isFirst then res.push check

    if isFirst
      if res.every( (val) -> !val)
        @restart isFirst, finish

    if finish
      if res.every( (val) -> !val)
        return if @win
        @win = true
        localStorage.setItem('wins', Number(localStorage.getItem('wins')) + 1)
        @updateWinsView()
        @restart false, true

  reverseLayers :             -> stage.children.reverse() # TODO
  clearContainer: (container) -> container.removeAllChildren()
  removeAll     :             -> stage.removeAllChildren()
