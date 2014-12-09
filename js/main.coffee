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

  run: ($scene_place, objFile) ->
    console.log "parsing..."
    parseObjFile objFile
    .then (objData) ->
      console.log "creating..."
      createScene $scene_place, objData
    .then ($scene) -> setScene $scene
    .then ->
      console.log "done!"


  createScene = ($place, objData, scale=10) ->
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

        v = [objV[face[0].vNumber], objV[face[1].vNumber], objV[face[2].vNumber]]
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
        if false
          # texture mode
        else
          color = Math.round 220 +  Math.abs(theta / Math.PI) * (256 - 220)
          $face.css
            "border-style": "solid"
            "border-width": "#{height * scale}em #{width * scale}em 0 0"
            "border-color": "rgba(#{color}, #{color}, #{color}, 1) transparent transparent transparent"
        $obj.append $face
    d.resolve $place
    d.promise()


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

    getFile = (file) ->
      d_ = new $.Deferred
      $.get file
        .done (data, textStatus) ->
          d_.resolve data
        .fail (jqxhr, settings, exception) ->
          console.log "file not found!"
          d_.reject(jqxhr)
      d_.promise()

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

  sin = (x) -> Math.sin(x)
  cos = (x) -> Math.cos(x)
  atan2 = (y, x) -> Math.atan2(y, x)

$ =>
  new CSSRize().run $("#scene"), "data/sphere.obj"