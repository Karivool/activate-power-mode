{CompositeDisposable} = require "atom"
throttle = require "lodash.throttle"
colorHelper = require "../color-helper"
effect = require "../default-effect"

module.exports =
  colorHelper: colorHelper
  effect: effect
  subscriptions: null
  conf: []

  enable: (api) ->
    @initConfigSubscribers()
    @colorHelper.init()

  disable: ->
    @destroy()

  onChangePane: (editor, editorElement) ->
    @resetCanvas()
    @setupCanvas editor, editorElement if editor

  onNewCursor: (cursor) ->
    cursor.spawn = throttle @spawn.bind(this), 25, trailing: false

  onInput: (cursor, screenPosition) ->
    cursor.spawn cursor, screenPosition

  init: ->
    @effect.init()
    @animationOn()

  resetCanvas: ->
    @animationOff()
    @editor = null
    @editorElement = null

  animationOff: ->
    cancelAnimationFrame(@animationFrame)
    @animationFrame = null

  animationOn: ->
    @animationFrame = requestAnimationFrame @animate.bind(this)

  destroy: ->
    @resetCanvas()
    @effect.disable()
    @canvas?.parentNode.removeChild @canvas
    @canvas = null
    @subscriptions?.dispose()
    @colorHelper.disable()

  setupCanvas: (editor, editorElement) ->
    if not @canvas
      @canvas = document.createElement "canvas"
      @context = @canvas.getContext "2d"
      @canvas.classList.add "power-mode-canvas"
      @initConfigSubscribers()

    editorElement.appendChild @canvas

    @canvas.style.display = "block"
    @scrollView = editorElement.querySelector(".scroll-view")
    @editorElement = editorElement
    @editor = editor
    @updateCanvasDimesions()
    @calculateOffsets()
    @editorElement.addEventListener 'resize', =>
      @updateCanvasDimesions()
      @calculateOffsets()

    @init()

  observe: (key) ->
    @subscriptions.add atom.config.observe "activate-power-mode.particles.#{key}", (value) =>
      @conf[key] = value

  initConfigSubscribers: ->
    @subscriptions = new CompositeDisposable
    @observe 'spawnCount.min'
    @observe 'spawnCount.max'
    @observe 'totalCount.max'
    @observe 'size.min'
    @observe 'size.max'

  spawn: (cursor, screenPosition) ->
    position = @calculatePositions screenPosition
    colorGenerator = @colorHelper.generateColors cursor, @editorElement
    @effect.spawn position, colorGenerator, @conf

  calculatePositions: (screenPosition) ->
    {left, top} = @editorElement.pixelPositionForScreenPosition screenPosition
    left: left + @offsetLeft - @editorElement.getScrollLeft()
    top: top + @offsetTop - @editorElement.getScrollTop() + @editor.getLineHeightInPixels() / 2

  calculateOffsets: ->
    @offsetLeft = @scrollView.offsetLeft
    @offsetTop = @scrollView.offsetTop

  updateCanvasDimesions: ->
    @canvas.width = @editorElement.offsetWidth
    @canvas.height = @editorElement.offsetHeight

  animate: ->
    @animationOn()
    @canvas.width = @canvas.width

    @effect.animate(@context)
