// Generated by CoffeeScript 1.8.0
(function() {
  var CSSRize, Vector;

  Vector = (function() {
    function Vector(x, y, z) {
      if ((x.x != null) && (y.x != null)) {
        this.x = y.x - x.x;
        this.y = y.y - x.y;
        this.z = y.z - x.z;
      } else {
        this.x = x;
        this.y = y;
        this.z = z;
      }
    }

    Vector.prototype.add = function(vector) {
      return new Vector(this.x + vector.x, this.y + vector.y, this.z + vector.z);
    };

    Vector.prototype.sub = function(vector) {
      return new Vector(this.x + vector.x, this.y - vector.y, this.z - vector.z);
    };

    Vector.prototype.dot = function(vector) {
      return this.x * vector.x + this.y * vector.y + this.z * vector.z;
    };

    Vector.prototype.cross = function(vector) {
      return new Vector(this.y * vector.z - this.z * vector.y, this.z * vector.x - this.x * vector.z, this.x * vector.y - this.y * vector.x);
    };

    Vector.prototype.norm = function() {
      return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    };

    return Vector;

  })();

  CSSRize = (function() {
    var atan2, cos, createScene, parseObjFile, setScene, sin, _objData;

    function CSSRize() {}

    _objData = null;

    CSSRize.prototype.run = function($scene_place, objFile) {
      console.log("parsing...");
      return parseObjFile(objFile).then(function(objData) {
        console.log("creating...");
        return createScene($scene_place, objData);
      }).then(function($scene) {
        return setScene($scene);
      }).then(function() {
        return console.log("done!");
      });
    };

    createScene = function($place, objData, scale) {
      var $face, $obj, color, d, fNumber, face, height, objF, objT, objV, phi, psi, rad, theta, v, vecPQ, vecPQ1, vecPR, vecPR1, vecPR2, width;
      if (scale == null) {
        scale = 10;
      }
      d = new $.Deferred;
      objV = objData.vertex;
      objT = objData.texture;
      objF = objData.face;
      $obj = $('<div class="rize_obj"></div>');
      $place.addClass("rize_scene").append($obj);
      for (fNumber in objF) {
        face = objF[fNumber];
        if (face.length === 3) {
          $face = $('<div class="rize_face"></div>');
          v = [objV[face[0].vNumber], objV[face[1].vNumber], objV[face[2].vNumber]];
          vecPQ = new Vector(v[1], v[0]);
          vecPR = new Vector(v[2], v[0]);
          theta = -atan2(vecPQ.y, vecPQ.x);
          vecPQ1 = new Vector(vecPQ.x * cos(theta) + vecPQ.y * -sin(theta), vecPQ.x * sin(theta) + vecPQ.y * cos(theta), vecPQ.z);
          vecPR1 = new Vector(vecPR.x * cos(theta) + vecPR.y * -sin(theta), vecPR.x * sin(theta) + vecPR.y * cos(theta), vecPR.z);
          phi = Math.PI / 2 - atan2(vecPQ1.x, vecPQ1.z);
          vecPR2 = new Vector(vecPR1.x * cos(phi) + vecPR1.z * sin(phi), vecPR1.y, vecPR1.x * -sin(phi) + vecPR1.z * cos(phi));
          psi = -atan2(vecPR2.z, vecPR2.y);
          width = vecPQ.norm();
          height = vecPQ.cross(vecPR).norm() / width;
          rad = Math.acos(vecPQ.dot(vecPR) / (vecPQ.norm() * vecPR.norm()));
          $face.css({
            transform: ("translate3D(" + (v[0].x * scale) + "em, ") + ("" + (v[0].y * scale) + "em, ") + ("" + (v[0].z * scale) + "em) ") + ("matrix3D(                                   " + (-cos(theta) * cos(phi)) + ",                                     " + (sin(theta) * cos(phi)) + ",            " + (-sin(phi)) + ", 0, ") + ("" + (-sin(theta) * cos(psi) - cos(theta) * sin(phi) * sin(psi)) + ", " + (-cos(theta) * cos(psi) + sin(theta) * sin(phi) * sin(psi)) + ",  " + (cos(phi) * sin(psi)) + ", 0, ") + ("" + (-sin(theta) * sin(psi) + cos(theta) * sin(phi) * cos(psi)) + ", " + (-cos(theta) * sin(psi) - sin(theta) * sin(phi) * cos(psi)) + ", " + (-cos(phi) * cos(psi)) + ", 0, ") + "                                                           0,                                                            0,                       0, 1) " + ("skewX(" + (Math.PI / 2 - rad) + "rad)") + ""
          });
          if (false) {

          } else {
            color = Math.round(220 + Math.abs(theta / Math.PI) * (256 - 220));
            $face.css({
              "border-style": "solid",
              "border-width": "" + (height * scale) + "em " + (width * scale) + "em 0 0",
              "border-color": "rgba(" + color + ", " + color + ", " + color + ", 1) transparent transparent transparent"
            });
          }
          $obj.append($face);
        }
      }
      d.resolve($place);
      return d.promise();
    };

    setScene = function($place) {
      var d, x, y;
      d = new $.Deferred;
      x = 0;
      y = 0;
      $place.on("mousemove", (function(_this) {
        return function(events) {
          var _ref;
          return (_ref = _this.$rotatee) != null ? _ref.css("transform", ("rotateY(" + (events.clientX - _this.x) + "deg)") + ("rotateX(" + (_this.y - events.clientY) + "deg)")) : void 0;
        };
      })(this)).on("mouseup", (function(_this) {
        return function(events) {
          return _this.$rotatee = null;
        };
      })(this));
      $place.on("mousedown", (function(_this) {
        return function(events) {
          if (_this.$rotatee == null) {
            _this.$rotatee = $place.find(".rize_obj");
            _this.x = events.clientX;
            return _this.y = events.clientY;
          }
        };
      })(this));
      d.resolve($place);
      return d.promise();
    };

    parseObjFile = function(objFile) {
      var d, getFile, objData;
      d = new $.Deferred;
      objData = {};
      objData.vertex = {};
      objData.texture = {};
      objData.face = {};
      getFile = function(file) {
        var d_;
        d_ = new $.Deferred;
        $.get(file).done(function(data, textStatus) {
          return d_.resolve(data);
        }).fail(function(jqxhr, settings, exception) {
          console.log("file not found!");
          return d_.reject(jqxhr);
        });
        return d_.promise();
      };
      getFile(objFile).then(function(data) {
        var buf, fNumber, face, faces, info, tok, tokens, vNumber, vtNumber, _i, _j, _len, _len1, _ref;
        vNumber = 1;
        vtNumber = 1;
        fNumber = 1;
        _ref = data.split("\n");
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          buf = _ref[_i];
          if (buf.indexOf("#") === 0) {
            continue;
          }
          tokens = buf.split(" ");
          if (tokens.length < 1) {
            continue;
          }
          switch (tokens[0].toLowerCase()) {
            case "usemtl":
              continue;
            case "v":
              objData.vertex[vNumber] = {
                x: +tokens[1],
                y: -tokens[2],
                z: +tokens[3]
              };
              vNumber += 1;
              break;
            case "vt":
              objData.texture[vtNumber] = {
                x: +tokens[1],
                y: +tokens[2]
              };
              vtNumber += 1;
              break;
            case "f":
              faces = [];
              tokens.shift();
              for (_j = 0, _len1 = tokens.length; _j < _len1; _j++) {
                tok = tokens[_j];
                info = tok.split("/");
                face = {};
                face.vNumber = +info[0];
                if ((info[1] != null) && info[1] !== "") {
                  face.vtNumber = +info[1];
                }
                if ((info[2] != null) && info[2] !== "") {
                  face.vnNumber = +info[2];
                }
                faces.push(face);
              }
              objData.face[fNumber] = faces;
              fNumber += 1;
              break;
            default:
              continue;
          }
        }
        _objData = objData;
        return d.resolve(objData);
      });
      return d.promise();
    };

    sin = function(x) {
      return Math.sin(x);
    };

    cos = function(x) {
      return Math.cos(x);
    };

    atan2 = function(y, x) {
      return Math.atan2(y, x);
    };

    return CSSRize;

  })();

  $((function(_this) {
    return function() {
      return new CSSRize().run($("#scene"), "data/sphere.obj");
    };
  })(this));

}).call(this);

//# sourceMappingURL=main.js.map