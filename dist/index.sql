CREATE OR REPLACE FUNCTION extism_create_plugin(manifest integer, opts integer)
RETURNS integer
LANGUAGE plv8
AS $function$
    "use strict";
    var __create = Object.create;
    var __defProp = Object.defineProperty;
    var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
    var __getOwnPropNames = Object.getOwnPropertyNames;
    var __getProtoOf = Object.getPrototypeOf;
    var __hasOwnProp = Object.prototype.hasOwnProperty;
    var __commonJS = (cb, mod) => function __require() {
      return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
    };
    var __export = (target, all) => {
      for (var name in all)
        __defProp(target, name, { get: all[name], enumerable: true });
    };
    var __copyProps = (to, from, except, desc) => {
      if (from && typeof from === "object" || typeof from === "function") {
        for (let key of __getOwnPropNames(from))
          if (!__hasOwnProp.call(to, key) && key !== except)
            __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
      }
      return to;
    };
    var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
      isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
      mod
    ));
    var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);
    
    // node_modules/base64-js/index.js
    var require_base64_js = __commonJS({
      "node_modules/base64-js/index.js"(exports) {
        "use strict";
        exports.byteLength = byteLength;
        exports.toByteArray = toByteArray2;
        exports.fromByteArray = fromByteArray;
        var lookup = [];
        var revLookup = [];
        var Arr = typeof Uint8Array !== "undefined" ? Uint8Array : Array;
        var code = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        for (i = 0, len = code.length; i < len; ++i) {
          lookup[i] = code[i];
          revLookup[code.charCodeAt(i)] = i;
        }
        var i;
        var len;
        revLookup["-".charCodeAt(0)] = 62;
        revLookup["_".charCodeAt(0)] = 63;
        function getLens(b64) {
          var len2 = b64.length;
          if (len2 % 4 > 0) {
            throw new Error("Invalid string. Length must be a multiple of 4");
          }
          var validLen = b64.indexOf("=");
          if (validLen === -1)
            validLen = len2;
          var placeHoldersLen = validLen === len2 ? 0 : 4 - validLen % 4;
          return [validLen, placeHoldersLen];
        }
        function byteLength(b64) {
          var lens = getLens(b64);
          var validLen = lens[0];
          var placeHoldersLen = lens[1];
          return (validLen + placeHoldersLen) * 3 / 4 - placeHoldersLen;
        }
        function _byteLength(b64, validLen, placeHoldersLen) {
          return (validLen + placeHoldersLen) * 3 / 4 - placeHoldersLen;
        }
        function toByteArray2(b64) {
          var tmp;
          var lens = getLens(b64);
          var validLen = lens[0];
          var placeHoldersLen = lens[1];
          var arr = new Arr(_byteLength(b64, validLen, placeHoldersLen));
          var curByte = 0;
          var len2 = placeHoldersLen > 0 ? validLen - 4 : validLen;
          var i2;
          for (i2 = 0; i2 < len2; i2 += 4) {
            tmp = revLookup[b64.charCodeAt(i2)] << 18 | revLookup[b64.charCodeAt(i2 + 1)] << 12 | revLookup[b64.charCodeAt(i2 + 2)] << 6 | revLookup[b64.charCodeAt(i2 + 3)];
            arr[curByte++] = tmp >> 16 & 255;
            arr[curByte++] = tmp >> 8 & 255;
            arr[curByte++] = tmp & 255;
          }
          if (placeHoldersLen === 2) {
            tmp = revLookup[b64.charCodeAt(i2)] << 2 | revLookup[b64.charCodeAt(i2 + 1)] >> 4;
            arr[curByte++] = tmp & 255;
          }
          if (placeHoldersLen === 1) {
            tmp = revLookup[b64.charCodeAt(i2)] << 10 | revLookup[b64.charCodeAt(i2 + 1)] << 4 | revLookup[b64.charCodeAt(i2 + 2)] >> 2;
            arr[curByte++] = tmp >> 8 & 255;
            arr[curByte++] = tmp & 255;
          }
          return arr;
        }
        function tripletToBase64(num) {
          return lookup[num >> 18 & 63] + lookup[num >> 12 & 63] + lookup[num >> 6 & 63] + lookup[num & 63];
        }
        function encodeChunk(uint8, start, end) {
          var tmp;
          var output = [];
          for (var i2 = start; i2 < end; i2 += 3) {
            tmp = (uint8[i2] << 16 & 16711680) + (uint8[i2 + 1] << 8 & 65280) + (uint8[i2 + 2] & 255);
            output.push(tripletToBase64(tmp));
          }
          return output.join("");
        }
        function fromByteArray(uint8) {
          var tmp;
          var len2 = uint8.length;
          var extraBytes = len2 % 3;
          var parts = [];
          var maxChunkLength = 16383;
          for (var i2 = 0, len22 = len2 - extraBytes; i2 < len22; i2 += maxChunkLength) {
            parts.push(encodeChunk(uint8, i2, i2 + maxChunkLength > len22 ? len22 : i2 + maxChunkLength));
          }
          if (extraBytes === 1) {
            tmp = uint8[len2 - 1];
            parts.push(
              lookup[tmp >> 2] + lookup[tmp << 4 & 63] + "=="
            );
          } else if (extraBytes === 2) {
            tmp = (uint8[len2 - 2] << 8) + uint8[len2 - 1];
            parts.push(
              lookup[tmp >> 10] + lookup[tmp >> 4 & 63] + lookup[tmp << 2 & 63] + "="
            );
          }
          return parts.join("");
        }
      }
    });
    
    // (disabled):crypto
    var require_crypto = __commonJS({
      "(disabled):crypto"() {
      }
    });
    
    // (disabled):buffer
    var require_buffer = __commonJS({
      "(disabled):buffer"() {
      }
    });
    
    // node_modules/js-sha256/src/sha256.js
    var require_sha256 = __commonJS({
      "node_modules/js-sha256/src/sha256.js"(exports, module2) {
        (function() {
          "use strict";
          var ERROR2 = "input is invalid type";
          var WINDOW = typeof window === "object";
          var root = WINDOW ? window : {};
          if (root.JS_SHA256_NO_WINDOW) {
            WINDOW = false;
          }
          var WEB_WORKER = !WINDOW && typeof self === "object";
          var NODE_JS = !root.JS_SHA256_NO_NODE_JS && typeof process === "object" && process.versions && process.versions.node;
          if (NODE_JS) {
            root = global;
          } else if (WEB_WORKER) {
            root = self;
          }
          var COMMON_JS = !root.JS_SHA256_NO_COMMON_JS && typeof module2 === "object" && module2.exports;
          var AMD = typeof define === "function" && define.amd;
          var ARRAY_BUFFER = !root.JS_SHA256_NO_ARRAY_BUFFER && typeof ArrayBuffer !== "undefined";
          var HEX_CHARS = "0123456789abcdef".split("");
          var EXTRA = [-2147483648, 8388608, 32768, 128];
          var SHIFT = [24, 16, 8, 0];
          var K = [
            1116352408,
            1899447441,
            3049323471,
            3921009573,
            961987163,
            1508970993,
            2453635748,
            2870763221,
            3624381080,
            310598401,
            607225278,
            1426881987,
            1925078388,
            2162078206,
            2614888103,
            3248222580,
            3835390401,
            4022224774,
            264347078,
            604807628,
            770255983,
            1249150122,
            1555081692,
            1996064986,
            2554220882,
            2821834349,
            2952996808,
            3210313671,
            3336571891,
            3584528711,
            113926993,
            338241895,
            666307205,
            773529912,
            1294757372,
            1396182291,
            1695183700,
            1986661051,
            2177026350,
            2456956037,
            2730485921,
            2820302411,
            3259730800,
            3345764771,
            3516065817,
            3600352804,
            4094571909,
            275423344,
            430227734,
            506948616,
            659060556,
            883997877,
            958139571,
            1322822218,
            1537002063,
            1747873779,
            1955562222,
            2024104815,
            2227730452,
            2361852424,
            2428436474,
            2756734187,
            3204031479,
            3329325298
          ];
          var OUTPUT_TYPES = ["hex", "array", "digest", "arrayBuffer"];
          var blocks = [];
          if (root.JS_SHA256_NO_NODE_JS || !Array.isArray) {
            Array.isArray = function(obj) {
              return Object.prototype.toString.call(obj) === "[object Array]";
            };
          }
          if (ARRAY_BUFFER && (root.JS_SHA256_NO_ARRAY_BUFFER_IS_VIEW || !ArrayBuffer.isView)) {
            ArrayBuffer.isView = function(obj) {
              return typeof obj === "object" && obj.buffer && obj.buffer.constructor === ArrayBuffer;
            };
          }
          var createOutputMethod = function(outputType, is224) {
            return function(message) {
              return new Sha256(is224, true).update(message)[outputType]();
            };
          };
          var createMethod = function(is224) {
            var method = createOutputMethod("hex", is224);
            if (NODE_JS) {
              method = nodeWrap(method, is224);
            }
            method.create = function() {
              return new Sha256(is224);
            };
            method.update = function(message) {
              return method.create().update(message);
            };
            for (var i = 0; i < OUTPUT_TYPES.length; ++i) {
              var type = OUTPUT_TYPES[i];
              method[type] = createOutputMethod(type, is224);
            }
            return method;
          };
          var nodeWrap = function(method, is224) {
            var crypto = require_crypto();
            var Buffer2 = require_buffer().Buffer;
            var algorithm = is224 ? "sha224" : "sha256";
            var bufferFrom;
            if (Buffer2.from && !root.JS_SHA256_NO_BUFFER_FROM) {
              bufferFrom = Buffer2.from;
            } else {
              bufferFrom = function(message) {
                return new Buffer2(message);
              };
            }
            var nodeMethod = function(message) {
              if (typeof message === "string") {
                return crypto.createHash(algorithm).update(message, "utf8").digest("hex");
              } else {
                if (message === null || message === void 0) {
                  throw new Error(ERROR2);
                } else if (message.constructor === ArrayBuffer) {
                  message = new Uint8Array(message);
                }
              }
              if (Array.isArray(message) || ArrayBuffer.isView(message) || message.constructor === Buffer2) {
                return crypto.createHash(algorithm).update(bufferFrom(message)).digest("hex");
              } else {
                return method(message);
              }
            };
            return nodeMethod;
          };
          var createHmacOutputMethod = function(outputType, is224) {
            return function(key, message) {
              return new HmacSha256(key, is224, true).update(message)[outputType]();
            };
          };
          var createHmacMethod = function(is224) {
            var method = createHmacOutputMethod("hex", is224);
            method.create = function(key) {
              return new HmacSha256(key, is224);
            };
            method.update = function(key, message) {
              return method.create(key).update(message);
            };
            for (var i = 0; i < OUTPUT_TYPES.length; ++i) {
              var type = OUTPUT_TYPES[i];
              method[type] = createHmacOutputMethod(type, is224);
            }
            return method;
          };
          function Sha256(is224, sharedMemory) {
            if (sharedMemory) {
              blocks[0] = blocks[16] = blocks[1] = blocks[2] = blocks[3] = blocks[4] = blocks[5] = blocks[6] = blocks[7] = blocks[8] = blocks[9] = blocks[10] = blocks[11] = blocks[12] = blocks[13] = blocks[14] = blocks[15] = 0;
              this.blocks = blocks;
            } else {
              this.blocks = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            }
            if (is224) {
              this.h0 = 3238371032;
              this.h1 = 914150663;
              this.h2 = 812702999;
              this.h3 = 4144912697;
              this.h4 = 4290775857;
              this.h5 = 1750603025;
              this.h6 = 1694076839;
              this.h7 = 3204075428;
            } else {
              this.h0 = 1779033703;
              this.h1 = 3144134277;
              this.h2 = 1013904242;
              this.h3 = 2773480762;
              this.h4 = 1359893119;
              this.h5 = 2600822924;
              this.h6 = 528734635;
              this.h7 = 1541459225;
            }
            this.block = this.start = this.bytes = this.hBytes = 0;
            this.finalized = this.hashed = false;
            this.first = true;
            this.is224 = is224;
          }
          Sha256.prototype.update = function(message) {
            if (this.finalized) {
              return;
            }
            var notString, type = typeof message;
            if (type !== "string") {
              if (type === "object") {
                if (message === null) {
                  throw new Error(ERROR2);
                } else if (ARRAY_BUFFER && message.constructor === ArrayBuffer) {
                  message = new Uint8Array(message);
                } else if (!Array.isArray(message)) {
                  if (!ARRAY_BUFFER || !ArrayBuffer.isView(message)) {
                    throw new Error(ERROR2);
                  }
                }
              } else {
                throw new Error(ERROR2);
              }
              notString = true;
            }
            var code, index = 0, i, length = message.length, blocks2 = this.blocks;
            while (index < length) {
              if (this.hashed) {
                this.hashed = false;
                blocks2[0] = this.block;
                this.block = blocks2[16] = blocks2[1] = blocks2[2] = blocks2[3] = blocks2[4] = blocks2[5] = blocks2[6] = blocks2[7] = blocks2[8] = blocks2[9] = blocks2[10] = blocks2[11] = blocks2[12] = blocks2[13] = blocks2[14] = blocks2[15] = 0;
              }
              if (notString) {
                for (i = this.start; index < length && i < 64; ++index) {
                  blocks2[i >>> 2] |= message[index] << SHIFT[i++ & 3];
                }
              } else {
                for (i = this.start; index < length && i < 64; ++index) {
                  code = message.charCodeAt(index);
                  if (code < 128) {
                    blocks2[i >>> 2] |= code << SHIFT[i++ & 3];
                  } else if (code < 2048) {
                    blocks2[i >>> 2] |= (192 | code >>> 6) << SHIFT[i++ & 3];
                    blocks2[i >>> 2] |= (128 | code & 63) << SHIFT[i++ & 3];
                  } else if (code < 55296 || code >= 57344) {
                    blocks2[i >>> 2] |= (224 | code >>> 12) << SHIFT[i++ & 3];
                    blocks2[i >>> 2] |= (128 | code >>> 6 & 63) << SHIFT[i++ & 3];
                    blocks2[i >>> 2] |= (128 | code & 63) << SHIFT[i++ & 3];
                  } else {
                    code = 65536 + ((code & 1023) << 10 | message.charCodeAt(++index) & 1023);
                    blocks2[i >>> 2] |= (240 | code >>> 18) << SHIFT[i++ & 3];
                    blocks2[i >>> 2] |= (128 | code >>> 12 & 63) << SHIFT[i++ & 3];
                    blocks2[i >>> 2] |= (128 | code >>> 6 & 63) << SHIFT[i++ & 3];
                    blocks2[i >>> 2] |= (128 | code & 63) << SHIFT[i++ & 3];
                  }
                }
              }
              this.lastByteIndex = i;
              this.bytes += i - this.start;
              if (i >= 64) {
                this.block = blocks2[16];
                this.start = i - 64;
                this.hash();
                this.hashed = true;
              } else {
                this.start = i;
              }
            }
            if (this.bytes > 4294967295) {
              this.hBytes += this.bytes / 4294967296 << 0;
              this.bytes = this.bytes % 4294967296;
            }
            return this;
          };
          Sha256.prototype.finalize = function() {
            if (this.finalized) {
              return;
            }
            this.finalized = true;
            var blocks2 = this.blocks, i = this.lastByteIndex;
            blocks2[16] = this.block;
            blocks2[i >>> 2] |= EXTRA[i & 3];
            this.block = blocks2[16];
            if (i >= 56) {
              if (!this.hashed) {
                this.hash();
              }
              blocks2[0] = this.block;
              blocks2[16] = blocks2[1] = blocks2[2] = blocks2[3] = blocks2[4] = blocks2[5] = blocks2[6] = blocks2[7] = blocks2[8] = blocks2[9] = blocks2[10] = blocks2[11] = blocks2[12] = blocks2[13] = blocks2[14] = blocks2[15] = 0;
            }
            blocks2[14] = this.hBytes << 3 | this.bytes >>> 29;
            blocks2[15] = this.bytes << 3;
            this.hash();
          };
          Sha256.prototype.hash = function() {
            var a = this.h0, b = this.h1, c = this.h2, d = this.h3, e = this.h4, f = this.h5, g = this.h6, h = this.h7, blocks2 = this.blocks, j, s0, s1, maj, t1, t2, ch, ab, da, cd, bc;
            for (j = 16; j < 64; ++j) {
              t1 = blocks2[j - 15];
              s0 = (t1 >>> 7 | t1 << 25) ^ (t1 >>> 18 | t1 << 14) ^ t1 >>> 3;
              t1 = blocks2[j - 2];
              s1 = (t1 >>> 17 | t1 << 15) ^ (t1 >>> 19 | t1 << 13) ^ t1 >>> 10;
              blocks2[j] = blocks2[j - 16] + s0 + blocks2[j - 7] + s1 << 0;
            }
            bc = b & c;
            for (j = 0; j < 64; j += 4) {
              if (this.first) {
                if (this.is224) {
                  ab = 300032;
                  t1 = blocks2[0] - 1413257819;
                  h = t1 - 150054599 << 0;
                  d = t1 + 24177077 << 0;
                } else {
                  ab = 704751109;
                  t1 = blocks2[0] - 210244248;
                  h = t1 - 1521486534 << 0;
                  d = t1 + 143694565 << 0;
                }
                this.first = false;
              } else {
                s0 = (a >>> 2 | a << 30) ^ (a >>> 13 | a << 19) ^ (a >>> 22 | a << 10);
                s1 = (e >>> 6 | e << 26) ^ (e >>> 11 | e << 21) ^ (e >>> 25 | e << 7);
                ab = a & b;
                maj = ab ^ a & c ^ bc;
                ch = e & f ^ ~e & g;
                t1 = h + s1 + ch + K[j] + blocks2[j];
                t2 = s0 + maj;
                h = d + t1 << 0;
                d = t1 + t2 << 0;
              }
              s0 = (d >>> 2 | d << 30) ^ (d >>> 13 | d << 19) ^ (d >>> 22 | d << 10);
              s1 = (h >>> 6 | h << 26) ^ (h >>> 11 | h << 21) ^ (h >>> 25 | h << 7);
              da = d & a;
              maj = da ^ d & b ^ ab;
              ch = h & e ^ ~h & f;
              t1 = g + s1 + ch + K[j + 1] + blocks2[j + 1];
              t2 = s0 + maj;
              g = c + t1 << 0;
              c = t1 + t2 << 0;
              s0 = (c >>> 2 | c << 30) ^ (c >>> 13 | c << 19) ^ (c >>> 22 | c << 10);
              s1 = (g >>> 6 | g << 26) ^ (g >>> 11 | g << 21) ^ (g >>> 25 | g << 7);
              cd = c & d;
              maj = cd ^ c & a ^ da;
              ch = g & h ^ ~g & e;
              t1 = f + s1 + ch + K[j + 2] + blocks2[j + 2];
              t2 = s0 + maj;
              f = b + t1 << 0;
              b = t1 + t2 << 0;
              s0 = (b >>> 2 | b << 30) ^ (b >>> 13 | b << 19) ^ (b >>> 22 | b << 10);
              s1 = (f >>> 6 | f << 26) ^ (f >>> 11 | f << 21) ^ (f >>> 25 | f << 7);
              bc = b & c;
              maj = bc ^ b & d ^ cd;
              ch = f & g ^ ~f & h;
              t1 = e + s1 + ch + K[j + 3] + blocks2[j + 3];
              t2 = s0 + maj;
              e = a + t1 << 0;
              a = t1 + t2 << 0;
              this.chromeBugWorkAround = true;
            }
            this.h0 = this.h0 + a << 0;
            this.h1 = this.h1 + b << 0;
            this.h2 = this.h2 + c << 0;
            this.h3 = this.h3 + d << 0;
            this.h4 = this.h4 + e << 0;
            this.h5 = this.h5 + f << 0;
            this.h6 = this.h6 + g << 0;
            this.h7 = this.h7 + h << 0;
          };
          Sha256.prototype.hex = function() {
            this.finalize();
            var h0 = this.h0, h1 = this.h1, h2 = this.h2, h3 = this.h3, h4 = this.h4, h5 = this.h5, h6 = this.h6, h7 = this.h7;
            var hex = HEX_CHARS[h0 >>> 28 & 15] + HEX_CHARS[h0 >>> 24 & 15] + HEX_CHARS[h0 >>> 20 & 15] + HEX_CHARS[h0 >>> 16 & 15] + HEX_CHARS[h0 >>> 12 & 15] + HEX_CHARS[h0 >>> 8 & 15] + HEX_CHARS[h0 >>> 4 & 15] + HEX_CHARS[h0 & 15] + HEX_CHARS[h1 >>> 28 & 15] + HEX_CHARS[h1 >>> 24 & 15] + HEX_CHARS[h1 >>> 20 & 15] + HEX_CHARS[h1 >>> 16 & 15] + HEX_CHARS[h1 >>> 12 & 15] + HEX_CHARS[h1 >>> 8 & 15] + HEX_CHARS[h1 >>> 4 & 15] + HEX_CHARS[h1 & 15] + HEX_CHARS[h2 >>> 28 & 15] + HEX_CHARS[h2 >>> 24 & 15] + HEX_CHARS[h2 >>> 20 & 15] + HEX_CHARS[h2 >>> 16 & 15] + HEX_CHARS[h2 >>> 12 & 15] + HEX_CHARS[h2 >>> 8 & 15] + HEX_CHARS[h2 >>> 4 & 15] + HEX_CHARS[h2 & 15] + HEX_CHARS[h3 >>> 28 & 15] + HEX_CHARS[h3 >>> 24 & 15] + HEX_CHARS[h3 >>> 20 & 15] + HEX_CHARS[h3 >>> 16 & 15] + HEX_CHARS[h3 >>> 12 & 15] + HEX_CHARS[h3 >>> 8 & 15] + HEX_CHARS[h3 >>> 4 & 15] + HEX_CHARS[h3 & 15] + HEX_CHARS[h4 >>> 28 & 15] + HEX_CHARS[h4 >>> 24 & 15] + HEX_CHARS[h4 >>> 20 & 15] + HEX_CHARS[h4 >>> 16 & 15] + HEX_CHARS[h4 >>> 12 & 15] + HEX_CHARS[h4 >>> 8 & 15] + HEX_CHARS[h4 >>> 4 & 15] + HEX_CHARS[h4 & 15] + HEX_CHARS[h5 >>> 28 & 15] + HEX_CHARS[h5 >>> 24 & 15] + HEX_CHARS[h5 >>> 20 & 15] + HEX_CHARS[h5 >>> 16 & 15] + HEX_CHARS[h5 >>> 12 & 15] + HEX_CHARS[h5 >>> 8 & 15] + HEX_CHARS[h5 >>> 4 & 15] + HEX_CHARS[h5 & 15] + HEX_CHARS[h6 >>> 28 & 15] + HEX_CHARS[h6 >>> 24 & 15] + HEX_CHARS[h6 >>> 20 & 15] + HEX_CHARS[h6 >>> 16 & 15] + HEX_CHARS[h6 >>> 12 & 15] + HEX_CHARS[h6 >>> 8 & 15] + HEX_CHARS[h6 >>> 4 & 15] + HEX_CHARS[h6 & 15];
            if (!this.is224) {
              hex += HEX_CHARS[h7 >>> 28 & 15] + HEX_CHARS[h7 >>> 24 & 15] + HEX_CHARS[h7 >>> 20 & 15] + HEX_CHARS[h7 >>> 16 & 15] + HEX_CHARS[h7 >>> 12 & 15] + HEX_CHARS[h7 >>> 8 & 15] + HEX_CHARS[h7 >>> 4 & 15] + HEX_CHARS[h7 & 15];
            }
            return hex;
          };
          Sha256.prototype.toString = Sha256.prototype.hex;
          Sha256.prototype.digest = function() {
            this.finalize();
            var h0 = this.h0, h1 = this.h1, h2 = this.h2, h3 = this.h3, h4 = this.h4, h5 = this.h5, h6 = this.h6, h7 = this.h7;
            var arr = [
              h0 >>> 24 & 255,
              h0 >>> 16 & 255,
              h0 >>> 8 & 255,
              h0 & 255,
              h1 >>> 24 & 255,
              h1 >>> 16 & 255,
              h1 >>> 8 & 255,
              h1 & 255,
              h2 >>> 24 & 255,
              h2 >>> 16 & 255,
              h2 >>> 8 & 255,
              h2 & 255,
              h3 >>> 24 & 255,
              h3 >>> 16 & 255,
              h3 >>> 8 & 255,
              h3 & 255,
              h4 >>> 24 & 255,
              h4 >>> 16 & 255,
              h4 >>> 8 & 255,
              h4 & 255,
              h5 >>> 24 & 255,
              h5 >>> 16 & 255,
              h5 >>> 8 & 255,
              h5 & 255,
              h6 >>> 24 & 255,
              h6 >>> 16 & 255,
              h6 >>> 8 & 255,
              h6 & 255
            ];
            if (!this.is224) {
              arr.push(h7 >>> 24 & 255, h7 >>> 16 & 255, h7 >>> 8 & 255, h7 & 255);
            }
            return arr;
          };
          Sha256.prototype.array = Sha256.prototype.digest;
          Sha256.prototype.arrayBuffer = function() {
            this.finalize();
            var buffer = new ArrayBuffer(this.is224 ? 28 : 32);
            var dataView = new DataView(buffer);
            dataView.setUint32(0, this.h0);
            dataView.setUint32(4, this.h1);
            dataView.setUint32(8, this.h2);
            dataView.setUint32(12, this.h3);
            dataView.setUint32(16, this.h4);
            dataView.setUint32(20, this.h5);
            dataView.setUint32(24, this.h6);
            if (!this.is224) {
              dataView.setUint32(28, this.h7);
            }
            return buffer;
          };
          function HmacSha256(key, is224, sharedMemory) {
            var i, type = typeof key;
            if (type === "string") {
              var bytes = [], length = key.length, index = 0, code;
              for (i = 0; i < length; ++i) {
                code = key.charCodeAt(i);
                if (code < 128) {
                  bytes[index++] = code;
                } else if (code < 2048) {
                  bytes[index++] = 192 | code >>> 6;
                  bytes[index++] = 128 | code & 63;
                } else if (code < 55296 || code >= 57344) {
                  bytes[index++] = 224 | code >>> 12;
                  bytes[index++] = 128 | code >>> 6 & 63;
                  bytes[index++] = 128 | code & 63;
                } else {
                  code = 65536 + ((code & 1023) << 10 | key.charCodeAt(++i) & 1023);
                  bytes[index++] = 240 | code >>> 18;
                  bytes[index++] = 128 | code >>> 12 & 63;
                  bytes[index++] = 128 | code >>> 6 & 63;
                  bytes[index++] = 128 | code & 63;
                }
              }
              key = bytes;
            } else {
              if (type === "object") {
                if (key === null) {
                  throw new Error(ERROR2);
                } else if (ARRAY_BUFFER && key.constructor === ArrayBuffer) {
                  key = new Uint8Array(key);
                } else if (!Array.isArray(key)) {
                  if (!ARRAY_BUFFER || !ArrayBuffer.isView(key)) {
                    throw new Error(ERROR2);
                  }
                }
              } else {
                throw new Error(ERROR2);
              }
            }
            if (key.length > 64) {
              key = new Sha256(is224, true).update(key).array();
            }
            var oKeyPad = [], iKeyPad = [];
            for (i = 0; i < 64; ++i) {
              var b = key[i] || 0;
              oKeyPad[i] = 92 ^ b;
              iKeyPad[i] = 54 ^ b;
            }
            Sha256.call(this, is224, sharedMemory);
            this.update(iKeyPad);
            this.oKeyPad = oKeyPad;
            this.inner = true;
            this.sharedMemory = sharedMemory;
          }
          HmacSha256.prototype = new Sha256();
          HmacSha256.prototype.finalize = function() {
            Sha256.prototype.finalize.call(this);
            if (this.inner) {
              this.inner = false;
              var innerHash = this.array();
              Sha256.call(this, this.is224, this.sharedMemory);
              this.update(this.oKeyPad);
              this.update(innerHash);
              Sha256.prototype.finalize.call(this);
            }
          };
          var exports2 = createMethod();
          exports2.sha256 = exports2;
          exports2.sha224 = createMethod(true);
          exports2.sha256.hmac = createHmacMethod();
          exports2.sha224.hmac = createHmacMethod(true);
          if (COMMON_JS) {
            module2.exports = exports2;
          } else {
            root.sha256 = exports2.sha256;
            root.sha224 = exports2.sha224;
            if (AMD) {
              define(function() {
                return exports2;
              });
            }
          }
        })();
      }
    });
    
    // src/index.ts
    var src_exports = {};
    __export(src_exports, {
      CurrentPlugin: () => CurrentPlugin,
      LogLevel: () => LogLevel,
      Plugin: () => Plugin,
      PluginOutput: () => PluginOutput,
      PluginWasi: () => PluginWasi,
      createPlugin: () => createPlugin,
      decodeString: () => decodeString,
      embeddedRuntime: () => embeddedRuntime,
      embeddedRuntimeHash: () => embeddedRuntimeHash,
      encodeString: () => encodeString,
      instantiateExtismRuntime: () => instantiateExtismRuntime
    });
    
    var import_base64_js = __toESM(require_base64_js());
    var import_js_sha256 = __toESM(require_sha256());
    var PluginOutput = class extends DataView {
      #output;
      constructor(output) {
        super(output.buffer);
        this.#output = output;
      }
      json() {
        return JSON.parse(this.text());
      }
      text() {
        return decodeString(this.#output);
      }
      bytes() {
        return this.#output;
      }
      arrayBuffer() {
        return this.#output.buffer;
      }
    };
    var LogLevel = /* @__PURE__ */ ((LogLevel2) => {
      LogLevel2["trace"] = "trace";
      LogLevel2["debug"] = "debug";
      LogLevel2["info"] = "info";
      LogLevel2["warn"] = "warn";
      LogLevel2["error"] = "error";
      return LogLevel2;
    })(LogLevel || {});
    function logLevelToNumber(level) {
      const levels = {
        ["trace" /* trace */]: 0,
        ["debug" /* debug */]: 1,
        ["info" /* info */]: 2,
        ["warn" /* warn */]: 3,
        ["error" /* error */]: 4
      };
      return levels[level];
    }
    var Plugin = class {
      moduleData;
      currentPlugin;
      vars;
      output;
      module;
      options;
      lastStatusCode = 0;
      guestRuntime;
      logLevel = "info" /* info */;
      constructor(extism, moduleData, options) {
        this.moduleData = moduleData;
        this.currentPlugin = new CurrentPlugin(this, extism);
        this.vars = {};
        this.output = new Uint8Array();
        this.options = options;
        this.guestRuntime = { type: GuestRuntimeType.None, init: () => {
        }, initialized: true };
      }
      getExports() {
        const module2 = this.instantiateModule();
        return module2.instance.exports;
      }
      getImports() {
        const module2 = this.instantiateModule();
        return WebAssembly.Module.imports(module2.module);
      }
      getInstance() {
        const module2 = this.instantiateModule();
        return module2.instance;
      }
      setLogLevel(level) {
        this.logLevel = level;
      }
      getLogLevel() {
        return this.logLevel;
      }
      functionExists(name) {
        const module2 = this.instantiateModule();
        return module2.instance.exports[name] ? true : false;
      }
      callRaw(func_name, input) {
        const module2 = this.instantiateModule();
        this.currentPlugin.reset();
        const inputOffset = this.currentPlugin.store(input);
        this.currentPlugin.inputSet(inputOffset, BigInt(input.length));
        let func = module2.instance.exports[func_name];
        if (!func) {
          throw Error(`Plugin error: function does not exist ${func_name}`);
        }
        if (func_name != "_start" && !this.guestRuntime.initialized) {
          this.guestRuntime.init();
          this.guestRuntime.initialized = true;
        }
        func();
        return this.output;
      }
      call(func_name, input) {
        const output = this.callRaw(func_name, encodeString(input));
        return new PluginOutput(output);
      }
      loadWasi(options) {
        const args = [];
        const envVars = [];
        return new PluginWasi();
      }
      instantiateModule() {
        if (this.module) {
          return this.module;
        }
        const pluginWasi = this.options.useWasi ? this.loadWasi(this.options) : void 0;
        let imports = {
          wasi_snapshot_preview1: pluginWasi?.importObject(),
          "extism:host/env": this.makeEnv()
        };
        for (const m in this.options.functions) {
          imports[m] = imports[m] || {};
          const map = this.options.functions[m];
          for (const f in map) {
            imports[m][f] = this.options.functions[m][f];
          }
        }
        for (const m in imports) {
          if (m === "wasi_snapshot_preview1") {
            continue;
          }
          for (const f in imports[m]) {
            imports[m][f] = imports[m][f].bind(null, this.currentPlugin);
          }
        }
        const mod = new WebAssembly.Module(this.moduleData);
        const instance = new WebAssembly.Instance(mod, imports);
        this.module = {
          module: this.moduleData,
          instance
        };
        if (pluginWasi) {
          pluginWasi.initialize(this.module.instance);
        }
        this.guestRuntime = detectGuestRuntime(this.module.instance);
        return this.module;
      }
      makeEnv() {
        let plugin = this;
        var env = {
          alloc(cp, n) {
            const response = cp.alloc(n);
            return response;
          },
          length_unsafe(cp, n) {
            return cp.lengthUnsafe(n);
          },
          free(cp, n) {
            cp.free(n);
          },
          load_u8(cp, n) {
            return cp.getMemoryBuffer()[Number(n)];
          },
          load_u64(cp, n) {
            let cast = new DataView(cp.getMemory().buffer, Number(n));
            return cast.getBigUint64(0, true);
          },
          store_u8(cp, offset, n) {
            cp.getMemoryBuffer()[Number(offset)] = Number(n);
          },
          store_u64(cp, offset, n) {
            const tmp = new DataView(cp.getMemory().buffer, Number(offset));
            tmp.setBigUint64(0, n, true);
          },
          input_offset(cp) {
            return cp.inputOffset();
          },
          input_length(cp) {
            return cp.inputLength();
          },
          input_load_u8(cp, i) {
            return cp.inputLoadU8(i);
          },
          input_load_u64(cp, idx) {
            return cp.inputLoadU64(idx);
          },
          output_set(cp, offset, length) {
            const offs = Number(offset);
            const len = Number(length);
            plugin.output = cp.getMemoryBuffer().slice(offs, offs + len);
          },
          error_set(cp, i) {
            throw new Error(`Call error: ${cp.read(i)?.text()}`);
          },
          config_get(cp, i) {
            if (typeof plugin.options.config === "undefined") {
              return BigInt(0);
            }
            const key = cp.read(i)?.text();
            if (!key) {
              return BigInt(0);
            }
            const value = plugin.options.config[key];
            if (typeof value === "undefined") {
              return BigInt(0);
            }
            return cp.store(value);
          },
          var_get(cp, i) {
            const key = cp.read(i)?.text();
            if (!key) {
              return BigInt(0);
            }
            const value = cp.vars[key];
            if (typeof value === "undefined") {
              return BigInt(0);
            }
            return cp.store(value);
          },
          var_set(cp, n, i) {
            const key = cp.read(n)?.text();
            if (!key) {
              return;
            }
            const value = cp.read(i)?.bytes();
            if (!value) {
              return;
            }
            cp.vars[key] = value;
          },
          http_request(cp, requestOffset, bodyOffset) {
            throw new Error("Call error: http requests are not supported.");
          },
          http_status_code() {
            return plugin.lastStatusCode;
          },
          length(cp, i) {
            return cp.length(i);
          },
          log_trace(cp, i) {
            if (logLevelToNumber(plugin.logLevel) > logLevelToNumber("trace" /* trace */)) {
              return;
            }
            const s = cp.read(i)?.text();
            plv8.elog(DEBUG5, s);
          },
          log_debug(cp, i) {
            if (logLevelToNumber(plugin.logLevel) > logLevelToNumber("debug" /* debug */)) {
              return;
            }
            const s = cp.read(i)?.text();
            plv8.elog(DEBUG1, s);
          },
          log_info(cp, i) {
            if (logLevelToNumber(plugin.logLevel) > logLevelToNumber("info" /* info */)) {
              return;
            }
            const s = cp.read(i)?.text();
            plv8.elog(INFO, s);
          },
          log_warn(cp, i) {
            if (logLevelToNumber(plugin.logLevel) > logLevelToNumber("warn" /* warn */)) {
              return;
            }
            const s = cp.read(i)?.text();
            plv8.elog(WARNING, s);
          },
          log_error(cp, i) {
            const s = cp.read(i)?.text();
            plv8.elog(ERROR, s);
          },
          get_log_level: () => {
            return logLevelToNumber(plugin.logLevel);
          }
        };
        return env;
      }
    };
    var PluginWasi = class {
      imports;
      inst = null;
      args;
      env;
      constructor(args = [], env = []) {
        this.args = args;
        this.env = env;
        const self2 = this;
        function memory() {
          return self2.inst.exports.memory;
        }
        this.imports = {
          fd_write: (fd, iovs, iovs_len, nwritten) => {
            if (fd < 0 || fd > 2) {
              throw new Error("fd_write not implemented");
            }
            const buffer = memory().buffer;
            const view = new DataView(buffer);
            let written = 0;
            let totalLength = 0;
            for (let i = 0; i < iovs_len; i++) {
              const len = view.getUint32(iovs + i * 8 + 4, true);
              totalLength += len;
            }
            const temp = new Uint8Array(totalLength);
            for (let i = 0; i < iovs_len; i++) {
              const iov = view.getUint32(iovs + i * 8, true);
              const len = view.getUint32(iovs + i * 8 + 4, true);
              const bytes = new Uint8Array(buffer, iov, len);
              temp.set(bytes, written);
              written += len;
            }
            const output = new TextDecoder().decode(temp);
            console.log(output);
            view.setUint32(nwritten, written, true);
            return 0;
          },
          fd_close(fd) {
            if (fd < 0 || fd > 2) {
              throw new Error("fd_close not implemented");
            }
            return 0;
          },
          fd_seek(fd, offset, whence, newoffset) {
            throw new Error("fd_seek not implemented");
          },
          fd_fdstat_get(fd, buf) {
            throw new Error("fd_fdstat_get not implemented");
          },
          fd_read(fd, iovs_ptr, iovs_len, nread_ptr) {
            throw new Error("fd_read not implemented");
          },
          fd_fdstat_set_flags(fd, flags) {
            throw new Error("fd_fdstat_set_flags not implemented");
          },
          fd_filestat_get(fd, buf) {
            throw new Error("fd_filestat_get not implemented");
          },
          fd_filestat_set_size(fd, size) {
            throw new Error("fd_filestat_set_size not implemented");
          },
          path_create_directory(fd, path_ptr, path_len) {
            throw new Error("path_create_directory not implemented");
          },
          path_filestat_get(fd, flags, path_ptr, path_len, filestat_ptr) {
            throw new Error("path_filestat_get not implemented");
          },
          fd_prestat_get(fd, buf_ptr) {
            throw new Error("fd_prestat_get not implemented");
          },
          fd_prestat_dir_name(fd, path_ptr, path_len) {
            throw new Error("fd_prestat_dir_name not implemented");
          },
          path_open(fd, dirflags, path_ptr, path_len, oflags, fs_rights_base, fs_rights_inheriting, fd_flags, opened_fd_ptr) {
            throw new Error("path_open not implemented");
          },
          poll_oneoff(in_ptr, out_ptr, nsubscriptions, nevents) {
            throw new Error("poll_oneoff not implemented");
          },
          proc_exit(rval) {
            throw new Error(`proc_exit: ${rval}`);
          },
          clock_time_get(id, precision, time) {
            const buffer = new DataView(memory().buffer);
            buffer.setBigUint64(
              time,
              BigInt(new Date().getTime()) * 1000000n,
              true
            );
            return 0;
          },
          args_sizes_get(argc, argv_buf_size) {
            const buffer = new DataView(memory().buffer);
            buffer.setUint32(argc, self2.args.length, true);
            let buf_size = 0;
            for (const arg of self2.args) {
              buf_size += arg.length + 1;
            }
            buffer.setUint32(argv_buf_size, buf_size, true);
            return 0;
          },
          args_get(argv, argv_buf) {
            const buffer = new DataView(memory().buffer);
            const buffer8 = new Uint8Array(memory().buffer);
            const orig_argv_buf = argv_buf;
            for (let i = 0; i < self2.args.length; i++) {
              buffer.setUint32(argv, argv_buf, true);
              argv += 4;
              const arg = new TextEncoder().encode(self2.args[i]);
              buffer8.set(arg, argv_buf);
              buffer.setUint8(argv_buf + arg.length, 0);
              argv_buf += arg.length + 1;
            }
            return 0;
          },
          environ_sizes_get(environ_count, environ_size) {
            const buffer = new DataView(memory().buffer);
            buffer.setUint32(environ_count, self2.env.length, true);
            let buf_size = 0;
            for (const environ of self2.env) {
              buf_size += environ.length + 1;
            }
            buffer.setUint32(environ_size, buf_size, true);
            return 0;
          },
          environ_get(environ, environ_buf) {
            const buffer = new DataView(memory().buffer);
            const buffer8 = new Uint8Array(memory().buffer);
            const orig_environ_buf = environ_buf;
            for (let i = 0; i < self2.env.length; i++) {
              buffer.setUint32(environ, environ_buf, true);
              environ += 4;
              const e = new TextEncoder().encode(self2.env[i]);
              buffer8.set(e, environ_buf);
              buffer.setUint8(environ_buf + e.length, 0);
              environ_buf += e.length + 1;
            }
            return 0;
          },
          random_get(buf, buf_len) {
            const buffer = new DataView(memory().buffer);
            for (let i = 0; i < buf_len; i++) {
              const randomByte = Math.floor(Math.random() * 256);
              buffer.setUint8(buf + i, randomByte);
            }
            return 0;
          }
        };
      }
      importObject() {
        return this.imports;
      }
      initialize(instance) {
        if (!instance.exports.memory) {
          throw new Error("The module has to export a default memory.");
        }
        this.inst = instance;
      }
    };
    var GuestRuntimeType = /* @__PURE__ */ ((GuestRuntimeType2) => {
      GuestRuntimeType2[GuestRuntimeType2["None"] = 0] = "None";
      GuestRuntimeType2[GuestRuntimeType2["Haskell"] = 1] = "Haskell";
      GuestRuntimeType2[GuestRuntimeType2["Wasi"] = 2] = "Wasi";
      return GuestRuntimeType2;
    })(GuestRuntimeType || {});
    function fetchModuleData(manifestData) {
      let moduleData = null;
      if (manifestData instanceof Uint8Array) {
        moduleData = { data: manifestData };
      } else if (manifestData.wasm) {
        const wasmData = manifestData.wasm;
        if (wasmData.length > 1)
          throw Error("This runtime only supports one module in Manifest.wasm");
        const wasm = wasmData[0];
        moduleData = wasm;
      } else if (manifestData.data) {
        moduleData = manifestData;
      }
      if (!moduleData) {
        throw Error(`Unsure how to interpret manifest ${manifestData}`);
      }
      const expected = moduleData.hash;
      if (expected) {
        const actual = (0, import_js_sha256.sha256)(moduleData.data);
        if (actual !== expected) {
          throw Error(`Plugin error: hash mismatch. Expected: ${expected}. Actual: ${actual}`);
        }
      }
      return moduleData.data;
    }
    function haskellRuntime(module2) {
      const haskellInit = module2.exports.hs_init;
      if (!haskellInit) {
        return null;
      }
      const reactorInit = module2.exports._initialize;
      let init = () => {
        if (reactorInit) {
          reactorInit();
        }
        haskellInit();
      };
      const kind = reactorInit ? "reactor" : "normal";
      return { type: 1 /* Haskell */, init, initialized: false };
    }
    function wasiRuntime(module2) {
      const reactorInit = module2.exports._initialize;
      const commandInit = module2.exports.__wasm_call_ctors;
      let init;
      if (reactorInit) {
        init = () => reactorInit();
      } else if (commandInit) {
        init = () => commandInit();
      } else {
        return null;
      }
      const kind = reactorInit ? "reactor" : "command";
      return { type: 2 /* Wasi */, init, initialized: false };
    }
    function detectGuestRuntime(module2) {
      const none = { init: () => {
      }, type: 0 /* None */, initialized: true };
      return haskellRuntime(module2) ?? wasiRuntime(module2) ?? none;
    }
    function instantiateExtismRuntime(runtime) {
      if (!runtime) {
        throw Error("Please specify Extism runtime.");
      }
      const extismWasm = fetchModuleData(runtime);
      const extismModule = new WebAssembly.Module(extismWasm);
      const extismInstance = new WebAssembly.Instance(extismModule, {});
      return extismInstance;
    }
    var embeddedRuntime = "AGFzbQEAAAABLQlgAAF+YAF+AX5gAn5+AGADf39/AX9gAX4AYAF+AX9gAn9+AX9gAn5/AGAAAAMYFwMDBgEEAQEFAQUBBwICAgAAAAAIBAAABQMBABAGFgNvAdBvC38AQYCAwAALfwBBgIDAAAsHsQIYBm1lbW9yeQIABWFsbG9jAAMEZnJlZQAEDWxlbmd0aF91bnNhZmUABQZsZW5ndGgABgdsb2FkX3U4AAcIbG9hZF91NjQACA1pbnB1dF9sb2FkX3U4AAkOaW5wdXRfbG9hZF91NjQACghzdG9yZV91OAALCXN0b3JlX3U2NAAMCWlucHV0X3NldAANCm91dHB1dF9zZXQADgxpbnB1dF9sZW5ndGgADwxpbnB1dF9vZmZzZXQAEA1vdXRwdXRfbGVuZ3RoABENb3V0cHV0X29mZnNldAASBXJlc2V0ABMJZXJyb3Jfc2V0ABQJZXJyb3JfZ2V0ABUMbWVtb3J5X2J5dGVzABYKX19kYXRhX2VuZAMCC19faGVhcF9iYXNlAwEOZXh0aXNtX2NvbnRleHQDAArtFxe1AQEDfwJAAkAgAkEQTw0AIAAhAwwBCyAAQQAgAGtBA3EiBGohBQJAIARFDQAgACEDA0AgAyABOgAAIANBAWoiAyAFSQ0ACwsgBSACIARrIgRBfHEiAmohAwJAIAJBAUgNACABQf8BcUGBgoQIbCECA0AgBSACNgIAIAVBBGoiBSADSQ0ACwsgBEEDcSECCwJAIAJFDQAgAyACaiEFA0AgAyABOgAAIANBAWoiAyAFSQ0ACwsgAAsKACAAIAEgAhAAC8ACAgR/BX4gAEHAAGohAgJAIAFCDHwiBiAAKQMQIAApAwgiB31CQHwiCFQNAAJAIAYgB1YNACAHIAKtIgl8IgogCVgNACABpyEDIAIhBAJAAkADQAJAAkACQCAELQAADgMFAAEACyAEKAIEIQUMAQsgBCgCBCIFIANPDQILIAogBCAFakEMaiIErVgNAwwACwALIAUgA2siAEGAAUkNACAEQQA2AgggBCAAQXRqNgIEIAQgAGoiBEEANgIIIAQgAzYCBCAEQQI6AAALIARBAToAACAEIAM2AgggBA8LAkAgBiAIfSIKQv//A4NCAFIgCkIQiKdqIgRAAEF/Rw0AQQAPCyAAIAApAxAgBK1CEIZ8NwMQCyAAIAApAwggBnw3AwggB6cgAmoiBCABpyIANgIIIAQgADYCBCAEQQE6AAAgBAuMAQEBfwJAIABQRQ0AQgAPC0EAQQAtAAEiAUEBIAEbOgABAkACQCABDQACQD8ADQBBAUAAQX9GDQILQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQARoLQQEgABACIgFBDGqtQgAgARsPCwAL6gECAn8BfgJAIABQDQBBAEEALQABIgFBASABGzoAAQJAAkAgAQ0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEAEaCz8AIQEgAELAAFQNASABrUIQhiAAVA0BIABCwQB8IQNBwQAhAQJAA0AgAUEMaiECAkAgAS0AAEEBRw0AIAKtIABRDQILIAMgAiABKAIEaiIBrVYNAAwDCwALIAFBAjoAAEEAKQMhIABSDQFBAEIANwMpDwsACwtCAgF+AX9CACEBAkAgAFANAD8AIQIgAELAAFQNACACrUIQhiAAVA0AIACnQXRqIgItAABBAUcNACACNQIIIQELIAEL1wECAn8BfgJAAkACQCAAUA0AQQBBAC0AASIBQQEgARs6AAECQCABDQACQD8ADQBBAUAAQX9GDQQLQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQARoLPwAhASAAQsAAVA0AIAGtQhCGIABUDQAgAELBAHwhA0HBACEBA0AgAUEMaiECAkAgAS0AAEEBRw0AIAKtIABRDQMLIAMgAiABKAIEaiIBrVYNAAsLQgAPCyABNQIIDwsACywBAn8/ACEBQQAhAgJAIABCwABUDQAgAa1CEIYgAFQNACAApy0AACECCyACCzMCAX8Cfj8AIQFCACECAkAgAEIHfCIDQsAAVA0AIAMgAa1CEIZWDQAgAKcpAwAhAgsgAguQAQECf0EAIQFBAEEALQABIgJBASACGzoAAQJAAkAgAg0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEAEaCwJAQQApAykgAFgNAEEAKQMhIAB8py0AACEBCyABDwsAC5UBAgF/AX5BAEEALQABIgFBASABGzoAAQJAAkAgAQ0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEAEaC0IAIQICQCAAQgh8QQApAylWDQBBACkDISAAfKcpAwAhAgsgAg8LAAsmAQF/PwAhAgJAIABCwABUDQAgAq1CEIYgAFQNACAApyABOgAACwstAgF/AX4/ACECAkAgAEIHfCIDQsAAVA0AIAMgAq1CEIZWDQAgAKcgATcDAAsLtgECAX8BfkEAQQAtAAEiAkEBIAIbOgABAkACQCACDQACQD8ADQBBAUAAQX9GDQILQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQARoLAkAgAELBAFQNAEEAKQMRQsEAfCAAWA0AIAAgAXxCf3wiA0LBAFQNACADQQApAxFCwQB8Wg0AQQAgADcDIUEAIAE3AykLDwsAC7YBAgF/AX5BAEEALQABIgJBASACGzoAAQJAAkAgAg0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEAEaCwJAIABCwQBUDQBBACkDEULBAHwgAFgNACAAIAF8Qn98IgNCwQBUDQAgA0EAKQMRQsEAfFoNAEEAIAA3AzFBACABNwM5Cw8LAAt0AQF/QQBBAC0AASIAQQEgABs6AAECQAJAIAANAAJAPwANAEEBQABBf0YNAgtBAEIANwMhQQBCADcDKUEAQgA3AzFBAEIANwM5QQBCADcDGUEAQsD/AzcDEUEAQgA3AwlBwQBBAEGQARABGgtBACkDKQ8LAAt0AQF/QQBBAC0AASIAQQEgABs6AAECQAJAIAANAAJAPwANAEEBQABBf0YNAgtBAEIANwMhQQBCADcDKUEAQgA3AzFBAEIANwM5QQBCADcDGUEAQsD/AzcDEUEAQgA3AwlBwQBBAEGQARABGgtBACkDIQ8LAAt0AQF/QQBBAC0AASIAQQEgABs6AAECQAJAIAANAAJAPwANAEEBQABBf0YNAgtBAEIANwMhQQBCADcDKUEAQgA3AzFBAEIANwM5QQBCADcDGUEAQsD/AzcDEUEAQgA3AwlBwQBBAEGQARABGgtBACkDOQ8LAAt0AQF/QQBBAC0AASIAQQEgABs6AAECQAJAIAANAAJAPwANAEEBQABBf0YNAgtBAEIANwMhQQBCADcDKUEAQgA3AzFBAEIANwM5QQBCADcDGUEAQsD/AzcDEUEAQgA3AwlBwQBBAEGQARABGgtBACkDMQ8LAAuqAQEBf0EAQQAtAAEiAEEBIAAbOgABAkACQCAADQACQD8ADQBBAUAAQX9GDQILQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQARoLQQAoAgkhAEEAQgA3AwlBwQBBACAAEAEaQQBCADcDGUEAQgA3AzlBAEIANwMxQQBCADcDKUEAQgA3AyEPCwALlwEBAX9BAEEALQABIgFBASABGzoAAQJAAkAgAQ0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEAEaCwJAAkAgAFANACAAQsAAWA0BQQApAxFCwQB8IABYDQELQQAgADcDGQsPCwALdAEBf0EAQQAtAAEiAEEBIAAbOgABAkACQCAADQACQD8ADQBBAUAAQX9GDQILQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQARoLQQApAxkPCwALdAEBf0EAQQAtAAEiAEEBIAAbOgABAkACQCAADQACQD8ADQBBAUAAQX9GDQILQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQARoLQQApAxEPCwAL";
    var embeddedRuntimeHash = "d1389b31abecf23eec65b4430d86f99f736aeb05c40948dbbe2f88cb17815803";
    var CurrentPlugin = class {
      vars;
      plugin;
      #extism;
      constructor(plugin, extism) {
        this.vars = {};
        this.plugin = plugin;
        this.#extism = extism;
      }
      setVariable(name, value) {
        if (value instanceof Uint8Array) {
          this.vars[name] = value;
        } else if (typeof value === "string") {
          this.vars[name] = encodeString(value);
        } else if (typeof value === "number") {
          this.vars[name] = this.uintToLEBytes(value);
        } else {
          const typeName = value?.constructor.name || (value === null ? "null" : typeof value);
          throw new TypeError(`Invalid plugin variable type. Expected Uint8Array, string, or number, got ${typeName}`);
        }
      }
      getVariable(name) {
        const value = this.vars[name];
        if (!value) {
          throw new Error(`Variable ${name} not found`);
        }
        return new PluginOutput(value);
      }
      uintToLEBytes(num) {
        const bytes = new Uint8Array(4);
        new DataView(bytes.buffer).setUint32(0, num, true);
        return bytes;
      }
      reset() {
        return this.#extism.exports.reset();
      }
      alloc(length) {
        return this.#extism.exports.alloc(length);
      }
      getMemory() {
        return this.#extism.exports.memory;
      }
      getMemoryBuffer() {
        return new Uint8Array(this.getMemory().buffer);
      }
      read(offset) {
        if (offset == BigInt(0)) {
          return null;
        }
        const length = this.length(offset);
        const buffer = new Uint8Array(this.getMemory().buffer, Number(offset), Number(length));
        return new PluginOutput(new Uint8Array(buffer));
      }
      store(data) {
        const offs = this.alloc(BigInt(data.length));
        const buffer = new Uint8Array(this.getMemory().buffer, Number(offs), data.length);
        if (typeof data === "string") {
          buffer.set(encodeString(data));
        } else {
          buffer.set(data);
        }
        return offs;
      }
      length(offset) {
        return this.#extism.exports.length(offset);
      }
      lengthUnsafe(offset) {
        return this.#extism.exports.length_unsafe(offset);
      }
      inputLength() {
        return this.#extism.exports.input_length();
      }
      inputOffset() {
        return this.#extism.exports.input_offset();
      }
      inputSet(offset, len) {
        this.#extism.exports.input_set(offset, len);
      }
      inputLoadU8(offset) {
        return this.#extism.exports.input_load_u8(offset);
      }
      inputLoadU64(offset) {
        return this.#extism.exports.input_load_u64(offset);
      }
      free(offset) {
        if (offset == BigInt(0)) {
          return;
        }
        this.#extism.exports.free(offset);
      }
    };
    function encodeString(str) {
      var arr = [];
      for (var i = 0, len = str.length; i < len; i++) {
        arr.push(str.charCodeAt(i));
      }
      return new Uint8Array(arr);
    }
    function decodeString(arr) {
      var str = "";
      for (var i = 0, len = arr.length; i < len; i++) {
        str += String.fromCharCode(arr[i]);
      }
      return str;
    }
    function createPlugin(manifest, opts = {}) {
      const runtimeBuffer = (0, import_base64_js.toByteArray)(embeddedRuntime);
      const runtime = instantiateExtismRuntime({
        data: runtimeBuffer,
        hash: embeddedRuntimeHash
      });
      const module2 = fetchModuleData(manifest);
      return new Plugin(runtime, module2, opts);
    }
    /**
     * [js-sha256]{@link https://github.com/emn178/js-sha256}
     *
     * @version 0.11.0
     * @author Chen, Yi-Cyuan [emn178@gmail.com]
     * @copyright Chen, Yi-Cyuan 2014-2024
     * @license MIT
     */
    

    return createPlugin(manifest, opts);
$function$
;

CREATE OR REPLACE FUNCTION extism_call(wasm bytea, func text, input text)
 RETURNS text
 LANGUAGE plv8
AS $function$
    const createPlugin = plv8.find_function("extism_create_plugin");
    const plugin = createPlugin(wasm, {
        useWasi: true
    });

    return plugin.call(func, input);
$function$
;