class Vector
  constructor: (x, y, z) ->
    if x.x? and y.x?
      @x = y.x - x.x
      @y = y.y - x.y
      @z = y.z - x.z
    else
      @x = x; @y = y; @z = z

  add: (vector) ->
    new Vector @x + vector.x, @y + vector.y, @z + vector.z
  sub: (vector) ->
    new Vector @x + vector.x, @y - vector.y, @z - vector.z
  dot: (vector) ->
    @x * vector.x + @y * vector.y + @z * vector.z
  cross: (vector) ->
    new Vector(
      @y * vector.z - @z * vector.y,
      @z * vector.x - @x * vector.z,
      @x * vector.y - @y * vector.x
    )
  norm: ->
    Math.sqrt @x * @x + @y * @y + @z * @z

class CSSRize
  _objData = null

  run: ($scene_place, objFile, texFile=null, texResolution=null) ->
    console.log "parsing..."
    parseObjFile objFile
    .then (objData) ->
      d = new $.Deferred
      if texFile?
        if texResolution?
          texImg = new Image texResolution, texResolution
        else
          texImg = new Image()
        texImg.onload = ->
          if texResolution?
            canvas = $('<canvas>').get 0
            ctx = canvas.getContext "2d"
            canvas.width = texResolution
            canvas.height = texResolution
            ctx.drawImage texImg, 0, 0, texResolution, texResolution
            d.resolve objData, canvas
          else
            d.resolve objData, texImg
        texImg.onerror = -> d.resolve objData
        texImg.src = texFile
      else
        d.resolve objData
      d.promise()
    .then (objData, texImg=null) ->
      console.log "creating..."
      createScene $scene_place, objData, texImg
    .then ($scene) -> setScene $scene
    .then ->
      console.log "done!"



  createScene = ($place, objData, texImg=null, scale=10) ->
    d = new $.Deferred
    objV= objData.vertex
    objT = objData.texture
    objF = objData.face

    $obj = $('<div class="rize_obj"></div>')
    $place.addClass "rize_scene"
      .append $obj

    for fNumber, face of objF
      if face.length is 3
        $face = $('<div class="rize_face"></div>')

        v = [objV[face[0].vNumber], objV[face[2].vNumber], objV[face[1].vNumber]]
        vecPQ = new Vector v[1], v[0]
        vecPR = new Vector v[2], v[0]
        theta = - atan2 vecPQ.y, vecPQ.x
        vecPQ1 = new Vector vecPQ.x * cos(theta) + vecPQ.y * -sin(theta),
                            vecPQ.x * sin(theta) + vecPQ.y * cos(theta),
                            vecPQ.z
        vecPR1 = new Vector vecPR.x * cos(theta) + vecPR.y * -sin(theta),
                            vecPR.x * sin(theta) + vecPR.y * cos(theta),
                            vecPR.z
        phi = Math.PI / 2 - atan2 vecPQ1.x, vecPQ1.z
        vecPR2 = new Vector vecPR1.x * cos(phi) + vecPR1.z * sin(phi),
                            vecPR1.y,
                            vecPR1.x * -sin(phi) + vecPR1.z * cos(phi)
        psi = - atan2 vecPR2.z, vecPR2.y
        width = vecPQ.norm()
        height = vecPQ.cross(vecPR).norm() / width
        rad = Math.acos vecPQ.dot(vecPR) / (vecPQ.norm() * vecPR.norm())
        $face.css
          transform: "translate3D(#{v[0].x * scale}em, "\
                               + "#{v[0].y * scale}em, "\
                               + "#{v[0].z * scale}em) "\
                   + "matrix3D(                                   #{-cos(theta) * cos(phi)},                                     #{sin(theta) * cos(phi)},            #{-sin(phi)}, 0, "\
                            + "#{-sin(theta) * cos(psi) - cos(theta) * sin(phi) * sin(psi)}, #{-cos(theta) * cos(psi) + sin(theta) * sin(phi) * sin(psi)},  #{cos(phi) * sin(psi)}, 0, "\
                            + "#{-sin(theta) * sin(psi) + cos(theta) * sin(phi) * cos(psi)}, #{-cos(theta) * sin(psi) - sin(theta) * sin(phi) * cos(psi)}, #{-cos(phi) * cos(psi)}, 0, "\
                            + "                                                           0,                                                            0,                       0, 1) "\
            + "skewX(#{Math.PI / 2 - rad}rad)"\
            + ""
        if texImg? and (blob = createTextureBlob texImg, objT[face[0].vtNumber], objT[face[1].vtNumber], objT[face[2].vtNumber])?
          $face.css
            width: "#{width * scale}em"
            height: "#{height * scale}em"
            "background-image": "url(#{blob})"
        else
          color = Math.round 220 +  Math.abs(theta / Math.PI) * (256 - 220)
          $face.css
            "border-style": "solid"
            "border-width": "#{height * scale}em #{width * scale}em 0 0"
            "border-color": "rgba(#{color}, #{color}, #{color}, 0.5) transparent transparent transparent"
        $obj.append $face
    d.resolve $place
    d.promise()


  createTextureBlob = (texture, vtP, vtQ, vtR) ->
    if not vtP? or not vtQ? or not vtR? or not vtP.x? or not vtQ.x? or not vtR.x?
      return null
    canvas = $('<canvas>').get 0
    context = canvas.getContext "2d"
    texWidth = texture.width
    texHeight = texture.height
    tx = (vt) -> vt.x * texWidth
    ty = (vt) -> (1 - vt.y) * texHeight

    vtS =
      x: vtP.x + (vtQ.x - vtP.x) + (vtR.x - vtP.x)
      y: vtP.y + (vtQ.y - vtP.y) + (vtR.y - vtP.y)
    areaX = Math.min(tx(vtP), tx(vtQ), tx(vtR), tx(vtS))
    areaY = Math.min(ty(vtP), ty(vtQ), ty(vtR), ty(vtS))
    areaWidth  = Math.max(tx(vtP), tx(vtQ), tx(vtR), tx(vtS)) - areaX
    areaHeight = Math.max(ty(vtP), ty(vtQ), ty(vtR), ty(vtS)) - areaY


    theta = - atan2(ty(vtR) - ty(vtP), tx(vtR) - tx(vtP))
    phi = atan2(ty(vtQ) - ty(vtP), tx(vtQ) - tx(vtP)) + theta + Math.PI / 2
    canvas.width  =  norm([tx(vtR) - tx(vtP), ty(vtR) - ty(vtP)])
    canvas.height = (norm([tx(vtQ) - tx(vtP), ty(vtQ) - ty(vtP)]) * cos(Math.PI + phi))

    context.beginPath()
    context.moveTo 0, 0
    context.lineTo canvas.width * 1.05, 0
    context.lineTo 0, canvas.height * 1.05
    context.closePath()
    context.clip()

    context.transform 1, 0, tan(phi), 1, 0, 0
    context.transform cos(theta), sin(theta), -sin(theta), cos(theta), 0, 0
    context.drawImage texture, areaX, areaY, areaWidth, areaHeight,
                      (areaX - tx(vtP)), (areaY - ty(vtP)), areaWidth, areaHeight
    canvas.toDataURL()


  setScene = ($place) ->
    d = new $.Deferred
    x = 0
    y = 0

    $place.on "mousemove", (events) =>
      @$rotatee?.css "transform", "rotateY(#{events.clientX - @x}deg)"\
                                + "rotateX(#{@y - events.clientY}deg)"
    .on "mouseup", (events) =>
      @$rotatee = null

    $place.on "mousedown", (events) =>
      unless @$rotatee?
        @$rotatee = $place.find(".rize_obj")
        @x = events.clientX
        @y = events.clientY
    d.resolve $place
    d.promise()


  parseObjFile = (objFile) ->
    d = new $.Deferred
    objData = {}
    objData.vertex = {}
    objData.texture = {}
    objData.face = {}

    getFile objFile
    .then (data) ->
      vNumber = 1
      vtNumber = 1
      fNumber = 1
      for buf in data.split "\n"
        if buf.indexOf("#") is 0
          continue

        tokens = buf.split " "
        if tokens.length < 1
          continue
        switch tokens[0].toLowerCase()
          when "usemtl"
            continue
          when "v"
            objData.vertex[vNumber] =
              x: + tokens[1]
              y: - tokens[2]
              z: + tokens[3]
            vNumber += 1
          when "vt"
            objData.texture[vtNumber] =
              x: + tokens[1]
              y: + tokens[2]
            vtNumber += 1
          when "f"
            faces = []
            tokens.shift()
            for tok in tokens
              info = tok.split "/"
              face = {}
              face.vNumber  = + info[0]
              face.vtNumber = + info[1] if info[1]? and info[1] isnt ""
              face.vnNumber = + info[2] if info[2]? and info[2] isnt ""
              faces.push face
            objData.face[fNumber] = faces
            fNumber += 1
          else
            continue
      _objData = objData
      d.resolve objData
    d.promise()


  getFile = (file) ->
    d = new $.Deferred
    $.get file
    .done (data, textStatus) ->
      d.resolve data
    .fail (jqxhr, settings, exception) ->
      console.log "file not found! : #{file}"
      d.reject jqxhr
    d.promise()


  sin = (x) -> Math.sin(x)
  cos = (x) -> Math.cos(x)
  tan = (x) -> Math.tan(x)
  atan2 = (y, x) -> Math.atan2(y, x)
  norm = (arr, sum=0) ->
    if arr.length is 0
      Math.sqrt sum
    else
      s = arr.shift()
      norm(arr, sum + s * s)


  _exportTestTexture = ($scene_place, objData, texImg) ->
    parseObjFile objFile
    .then (objData) ->
      texImg = new Image()
      texImg.onload = ->
        $canvas = $('<canvas>')
        canvas = $canvas.get 0
        ctx = canvas.getContext "2d"
        canvas.width = texImg.width
        canvas.height = texImg.height
        ctx.drawImage texImg, 0, 0
        for vtNumber, vt of objData.texture
          ctx.fillRect vt.x * canvas.width - 3, (1 - vt.y) * canvas.height - 3, 6, 6
        $scene_place.append $canvas
      texImg.src = texFile


$ =>
  new CSSRize().run $("#scene"), "data/sphere.obj", "data/sphere.png", 2048