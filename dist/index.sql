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
    
    // src/index.ts
    var src_exports = {};
    __export(src_exports, {
      CurrentPlugin: () => CurrentPlugin,
      Plugin: () => Plugin,
      PluginWasi: () => PluginWasi,
      createPlugin: () => createPlugin,
      decodeString: () => decodeString,
      embeddedRuntime: () => embeddedRuntime,
      embeddedRuntimeHash: () => embeddedRuntimeHash,
      encodeString: () => encodeString,
      instantiateExtismRuntime: () => instantiateExtismRuntime
    });
    
    var import_base64_js = __toESM(require_base64_js());
    var Plugin = class {
      moduleData;
      currentPlugin;
      vars;
      input;
      output;
      module;
      options;
      lastStatusCode = 0;
      guestRuntime;
      constructor(extism, moduleData, options) {
        this.moduleData = moduleData;
        this.currentPlugin = new CurrentPlugin(this, extism);
        this.vars = {};
        this.input = new Uint8Array();
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
      functionExists(name) {
        const module2 = this.instantiateModule();
        return module2.instance.exports[name] ? true : false;
      }
      callRaw(func_name, input) {
        const module2 = this.instantiateModule();
        this.input = input;
        this.currentPlugin.reset();
        let func = module2.instance.exports[func_name];
        if (!func) {
          throw Error(`Plugin error: function does not exist ${func_name}`);
        }
        if (func_name != "_start" && this.guestRuntime?.init && !this.guestRuntime.initialized) {
          this.guestRuntime.init();
          this.guestRuntime.initialized = true;
        }
        func();
        return this.output;
      }
      call(func_name, input) {
        return decodeString(this.callRaw(func_name, encodeString(input)));
      }
      loadWasi(options) {
        const args = [];
        const envVars = [];
        return new PluginWasi({}, {}, (instance) => this.initialize({}, instance));
      }
      initialize(wasi, instance) {
        const wrapper = {
          exports: {
            memory: instance.exports.memory,
            _start() {
            }
          }
        };
        if (!wrapper.exports.memory) {
          throw new Error("The module has to export a default memory.");
        }
        wasi.start(wrapper);
      }
      supportsHttpRequests() {
        return false;
      }
      httpRequest(request, body) {
        throw new Error("Call error: http requests are not supported.");
      }
      matches(text, pattern) {
        let regex = new RegExp("^" + pattern.split(/\*+/).map((s) => s.split("").map(this.escapeRegExp).join("")).join(".*") + "$");
        return regex.test(text);
      }
      escapeRegExp(text) {
        return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
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
        if (this.module.instance.exports._start) {
          pluginWasi?.initialize(this.module.instance);
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
          input_length() {
            return BigInt(plugin.input.length);
          },
          input_load_u8(cp, i) {
            return plugin.input[Number(i)];
          },
          input_load_u64(cp, idx) {
            let cast = new DataView(plugin.input.buffer, Number(idx));
            return cast.getBigUint64(0, true);
          },
          output_set(cp, offset, length) {
            const offs = Number(offset);
            const len = Number(length);
            plugin.output = cp.getMemoryBuffer().slice(offs, offs + len);
          },
          error_set(cp, i) {
            throw new Error(`Call error: ${cp.readString(i)}`);
          },
          config_get(cp, i) {
            if (typeof plugin.options.config === "undefined") {
              return BigInt(0);
            }
            const key = cp.readString(i);
            if (key === null) {
              return BigInt(0);
            }
            const value = plugin.options.config[key];
            if (typeof value === "undefined") {
              return BigInt(0);
            }
            return cp.writeString(value);
          },
          var_get(cp, i) {
            const key = cp.readString(i);
            if (key === null) {
              return BigInt(0);
            }
            const value = cp.vars[key];
            if (typeof value === "undefined") {
              return BigInt(0);
            }
            return cp.writeBytes(value);
          },
          var_set(cp, n, i) {
            const key = cp.readString(n);
            if (key === null) {
              return;
            }
            const value = cp.readBytes(i);
            if (value === null) {
              return;
            }
            cp.vars[key] = value;
          },
          http_request(cp, requestOffset, bodyOffset) {
            if (!plugin.supportsHttpRequests()) {
              cp.free(bodyOffset);
              cp.free(requestOffset);
              throw new Error("Call error: http requests are not supported.");
            }
            const requestJson = cp.readString(requestOffset);
            if (requestJson == null) {
              throw new Error("Call error: Invalid request.");
            }
            var request = JSON.parse(requestJson);
            const url = new URL(request.url);
            let hostMatches = false;
            for (const allowedHost of plugin.options.allowedHosts ?? []) {
              if (allowedHost === url.hostname) {
                hostMatches = true;
                break;
              }
              const patternMatches = plugin.matches(url.hostname, allowedHost);
              if (patternMatches) {
                hostMatches = true;
                break;
              }
            }
            if (!hostMatches) {
              throw new Error(`Call error: HTTP request to '${request.url}' is not allowed`);
            }
            const body = cp.readBytes(bodyOffset);
            cp.free(bodyOffset);
            cp.free(requestOffset);
            const response = plugin.httpRequest(request, body);
            plugin.lastStatusCode = response.status;
            const offset = cp.writeBytes(response.body);
            return offset;
          },
          http_status_code() {
            return plugin.lastStatusCode;
          },
          length(cp, i) {
            return cp.getLength(i);
          },
          log_warn(cp, i) {
            const s = cp.readString(i);
            console.warn(s);
          },
          log_info(cp, i) {
            const s = cp.readString(i);
            console.log(s);
          },
          log_debug(cp, i) {
            const s = cp.readString(i);
            console.debug(s);
          },
          log_error(cp, i) {
            const s = cp.readString(i);
            console.error(s);
          }
        };
        return env;
      }
    };
    var PluginWasi = class {
      wasi;
      imports;
      #initialize;
      constructor(wasi, imports, init) {
        this.wasi = wasi;
        this.imports = imports;
        this.#initialize = init;
      }
      importObject() {
        return this.imports;
      }
      initialize(instance) {
        this.#initialize(instance);
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
        moduleData = manifestData;
      } else if (manifestData.wasm) {
        const wasmData = manifestData.wasm;
        if (wasmData.length > 1)
          throw Error("This runtime only supports one module in Manifest.wasm");
        const wasm = wasmData[0];
        moduleData = wasm.data;
      } else if (manifestData.data) {
        moduleData = manifestData.data;
      }
      if (!moduleData) {
        throw Error(`Unsure how to interpret manifest ${manifestData}`);
      }
      return moduleData;
    }
    function haskellRuntime(module2) {
      const haskellInit = module2.exports.hs_init;
      if (!haskellInit) {
        return null;
      }
      const reactorInit = module2.exports._initialize;
      let init;
      if (reactorInit) {
        init = () => reactorInit();
      } else {
        init = () => haskellInit();
      }
      const kind = reactorInit ? "reactor" : "normal";
      console.debug(`Haskell (${kind}) runtime detected.`);
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
      console.debug(`WASI (${kind}) runtime detected.`);
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
    var embeddedRuntime = "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";
    var embeddedRuntimeHash = "80fcbfb1d046f0779adf0e3c4861b264a1c56df2d6c9ee051fc02188e83d45f7";
    var CurrentPlugin = class {
      vars;
      plugin;
      #extism;
      constructor(plugin, extism) {
        this.vars = {};
        this.plugin = plugin;
        this.#extism = extism;
      }
      setVar(name, value) {
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
      readStringVar(name) {
        return decodeString(this.getVar(name));
      }
      getNumberVar(name) {
        const value = this.getVar(name);
        if (value.length < 4) {
          throw new Error(`Variable "${name}" has incorrect length`);
        }
        return this.uintFromLEBytes(value);
      }
      getVar(name) {
        const value = this.vars[name];
        if (!value) {
          throw new Error(`Variable ${name} not found`);
        }
        return value;
      }
      uintToLEBytes(num) {
        const bytes = new Uint8Array(4);
        new DataView(bytes.buffer).setUint32(0, num, true);
        return bytes;
      }
      uintFromLEBytes(bytes) {
        return new DataView(bytes.buffer).getUint32(0, true);
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
      readBytes(offset) {
        if (offset == BigInt(0)) {
          return null;
        }
        const length = this.getLength(offset);
        const buffer = new Uint8Array(this.getMemory().buffer, Number(offset), Number(length));
        return new Uint8Array(buffer);
      }
      readString(offset) {
        const bytes = this.readBytes(offset);
        if (bytes === null) {
          return null;
        }
        return decodeString(bytes);
      }
      writeBytes(data) {
        const offs = this.alloc(BigInt(data.length));
        const buffer = new Uint8Array(this.getMemory().buffer, Number(offs), data.length);
        buffer.set(data);
        return offs;
      }
      writeString(data) {
        const bytes = encodeString(data);
        return this.writeBytes(bytes);
      }
      getLength(offset) {
        return this.#extism.exports.length(offset);
      }
      inputLength() {
        return this.#extism.exports.input_length();
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