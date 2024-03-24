import { toByteArray } from "base64-js";

export class Plugin {
  moduleData: ArrayBuffer;
  currentPlugin: CurrentPlugin;
  vars: Record<string, Uint8Array>;
  input: Uint8Array;
  output: Uint8Array;
  module?: WebAssembly.WebAssemblyInstantiatedSource;
  options: ExtismPluginOptions;
  lastStatusCode: number = 0;
  guestRuntime: GuestRuntime;

  constructor(extism: WebAssembly.Instance, moduleData: ArrayBuffer, options: ExtismPluginOptions) {
    this.moduleData = moduleData;
    this.currentPlugin = new CurrentPlugin(this, extism);
    this.vars = {};
    this.input = new Uint8Array();
    this.output = new Uint8Array();
    this.options = options;
    this.guestRuntime = { type: GuestRuntimeType.None, init: () => {}, initialized: true };
  }

  getExports(): WebAssembly.Exports {
    const module = this.instantiateModule();
    return module.instance.exports;
  }

  getImports(): WebAssembly.ModuleImportDescriptor[] {
    const module = this.instantiateModule();
    return WebAssembly.Module.imports(module.module);
  }

  getInstance(): WebAssembly.Instance {
    const module = this.instantiateModule();
    return module.instance;
  }

  /**
   * Check if a function exists in the WebAssembly module.
   *
   * @param {string} name The function's name
   * @returns {Promise<boolean>} true if the function exists, otherwise false
   */
  functionExists(name: string): boolean {
    const module = this.instantiateModule();
    return module.instance.exports[name] ? true : false;
  }

  /**
   * Call a specific function from the WebAssembly module with provided input.
   *
   * @param {string} func_name The name of the function to call
   * @param {Uint8Array | string} input The input to pass to the function
   * @returns {Promise<Uint8Array>} The result from the function call
   */
  callRaw(func_name: string, input: Uint8Array): Uint8Array {
    const module = this.instantiateModule();

    this.input = input;

    this.currentPlugin.reset();

    let func = module.instance.exports[func_name];
    if (!func) {
      throw Error(`Plugin error: function does not exist ${func_name}`);
    }

    if (func_name != '_start' && this.guestRuntime?.init && !this.guestRuntime.initialized) {
      this.guestRuntime.init();
      this.guestRuntime.initialized = true;
    }

    //@ts-ignore
    func();

    return this.output;
  }

  call(func_name: string, input: string): string {
    return decodeString(this.callRaw(func_name, encodeString(input)));
  }

  protected loadWasi(options: ExtismPluginOptions): PluginWasi {
    const args: Array<string> = [];
    const envVars: Array<string> = [];

    return new PluginWasi({}, {}, instance => this.initialize({}, instance));
  }

  private initialize(wasi: any, instance: WebAssembly.Instance) {
    const wrapper = {
      exports: {
        memory: instance.exports.memory as WebAssembly.Memory,
        _start() {},
      },
    };

    if (!wrapper.exports.memory) {
      throw new Error('The module has to export a default memory.');
    }

    wasi.start(wrapper);
  }

  private supportsHttpRequests(): boolean {
    return false;
  }

  private httpRequest(request: HttpRequest, body: Uint8Array | null): HttpResponse {
    throw new Error('Call error: http requests are not supported.');
  }

  private matches(text: string, pattern: string): boolean {
    // Convert glob pattern to regex
    let regex = new RegExp('^' + pattern.split(/\*+/).map(s => s.split('').map(this.escapeRegExp).join('')).join('.*') + '$');
    return regex.test(text);
  }

  private escapeRegExp(text: string) {
      return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
  }

  private instantiateModule(): WebAssembly.WebAssemblyInstantiatedSource {
    if (this.module) {
      return this.module;
    }

    const pluginWasi = this.options.useWasi ? this.loadWasi(this.options) : undefined;
    let imports = {
      wasi_snapshot_preview1: pluginWasi?.importObject(),
      "extism:host/env": this.makeEnv(),
    } as any;

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
      instance: instance,
    };

    if (this.module.instance.exports._start) {
      pluginWasi?.initialize(this.module.instance);
    }

    this.guestRuntime = detectGuestRuntime(this.module.instance);

    return this.module;
  }

  
  private makeEnv(): any {
    let plugin = this;
    var env: any = {
      alloc(cp: CurrentPlugin, n: bigint): bigint {
        const response = cp.alloc(n);
        return response;
      },
      free(cp: CurrentPlugin, n: bigint) {
        cp.free(n);
      },
      load_u8(cp: CurrentPlugin, n: bigint): number {
        return cp.getMemoryBuffer()[Number(n)];
      },
      load_u64(cp: CurrentPlugin, n: bigint): bigint {
        let cast = new DataView(cp.getMemory().buffer, Number(n));
        return cast.getBigUint64(0, true);
      },
      store_u8(cp: CurrentPlugin, offset: bigint, n: number) {
        cp.getMemoryBuffer()[Number(offset)] = Number(n);
      },
      store_u64(cp: CurrentPlugin, offset: bigint, n: bigint) {
        const tmp = new DataView(cp.getMemory().buffer, Number(offset));
        tmp.setBigUint64(0, n, true);
      },
      input_length(): bigint {
        return BigInt(plugin.input.length);
      },
      input_load_u8(cp: CurrentPlugin, i: bigint): number {
        return plugin.input[Number(i)];
      },
      input_load_u64(cp: CurrentPlugin, idx: bigint): bigint {
        let cast = new DataView(plugin.input.buffer, Number(idx));
        return cast.getBigUint64(0, true);
      },
      output_set(cp: CurrentPlugin, offset: bigint, length: bigint) {
        const offs = Number(offset);
        const len = Number(length);
        plugin.output = cp.getMemoryBuffer().slice(offs, offs + len);
      },
      error_set(cp: CurrentPlugin, i: bigint) {
        throw new Error(`Call error: ${cp.readString(i)}`);
      },
      config_get(cp: CurrentPlugin, i: bigint): bigint {
        if (typeof plugin.options.config === 'undefined') {
          return BigInt(0);
        }
        const key = cp.readString(i);
        if (key === null) {
          return BigInt(0);
        }
        const value = plugin.options.config[key];
        if (typeof value === 'undefined') {
          return BigInt(0);
        }
        return cp.writeString(value);
      },
      var_get(cp: CurrentPlugin, i: bigint): bigint {
        const key = cp.readString(i);
        if (key === null) {
          return BigInt(0);
        }
        const value = cp.vars[key];
        if (typeof value === 'undefined') {
          return BigInt(0);
        }
        return cp.writeBytes(value);
      },
      var_set(cp: CurrentPlugin, n: bigint, i: bigint) {
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
      http_request(cp: CurrentPlugin, requestOffset: bigint, bodyOffset: bigint): bigint {
        if (!plugin.supportsHttpRequests()) {
          cp.free(bodyOffset);
          cp.free(requestOffset);
          throw new Error('Call error: http requests are not supported.');
        }

        const requestJson = cp.readString(requestOffset);
        if (requestJson == null) {
          throw new Error('Call error: Invalid request.');
        }

        var request: HttpRequest = JSON.parse(requestJson);

        // The actual code starts here
        const url = new URL(request.url);
        let hostMatches = false;
        for (const allowedHost of (plugin.options.allowedHosts ?? [])) {
          if (allowedHost === url.hostname) {
            hostMatches = true;
            break;
          }

          // Using minimatch for pattern matching
          const patternMatches = plugin.matches(url.hostname, allowedHost);
          if (patternMatches) {
            hostMatches = true;
            break;
          }
        }

        if (!hostMatches) {
          throw new Error(`Call error: HTTP request to '${request.url}' is not allowed`);
        }

        // TODO: limit number of bytes read to 50 MiB
        const body = cp.readBytes(bodyOffset);
        cp.free(bodyOffset);
        cp.free(requestOffset);

        const response = plugin.httpRequest(request, body);
        plugin.lastStatusCode = response.status;

        const offset = cp.writeBytes(response.body);

        return offset;
      },
      http_status_code(): number {
        return plugin.lastStatusCode;
      },
      length(cp: CurrentPlugin, i: bigint): bigint {
        return cp.getLength(i);
      },
      log_warn(cp: CurrentPlugin, i: bigint) {
        const s = cp.readString(i);
        console.warn(s);
      },
      log_info(cp: CurrentPlugin, i: bigint) {
        const s = cp.readString(i);
        console.log(s);
      },
      log_debug(cp: CurrentPlugin, i: bigint) {
        const s = cp.readString(i);
        console.debug(s);
      },
      log_error(cp: CurrentPlugin, i: bigint) {
        const s = cp.readString(i);
        console.error(s);
      },
    };

    return env;
  }
}

/**
 * Represents a path to a WASM module
 */
export type ManifestWasmFile = {
  path: string;
  name?: string;
  hash?: string;
};

/**
 * Represents the raw bytes of a WASM file loaded into memory
 */
export type ManifestWasmData = {
  data: Uint8Array;
  name?: string;
  hash?: string;
};

/**
 * Represents a url to a WASM module
 */
export type ManifestWasmUrl = {
  url: string;
  name?: string;
  hash?: string;
};

/**
 * {@link ExtismPlugin} Config
 */
export type PluginConfig = { [key: string]: string };

/**
 * The WASM to load as bytes, a path, or a url
 */
export type ManifestWasm = ManifestWasmUrl | ManifestWasmFile | ManifestWasmData;

/**
 * The manifest which describes the {@link ExtismPlugin} code and
 * runtime constraints.
 *
 * @see [Extism > Concepts > Manifest](https://extism.org/docs/concepts/manifest)
 */
export type Manifest = {
  wasm: Array<ManifestWasmData>;
};

/**
 * Options for initializing an Extism plugin.
 */
export interface ExtismPluginOptions {
  /**
   * Whether or not to enable WASI preview 1.
   */
  useWasi?: boolean | undefined;

  /**
   * Whether or not to run the Wasm module in a Worker thread. Requires
   * {@link Capabilities#hasWorkerCapability | `CAPABILITIES.hasWorkerCapability`} to
   * be true.
   */
  runInWorker?: boolean | undefined;

  /**
   * A logger implementation. Must provide `info`, `debug`, `warn`, and `error` methods.
   */
  logger?: Console;

  /**
   * A map of namespaces to function names to host functions.
   *
   * ```js
   * const functions = {
   *   'my_great_namespace': {
   *     'my_func': (callContext: CurrentPlugin, input: bigint) => {
   *       const output = callContext.read(input);
   *       if (output !== null) {
   *         console.log(output.string());
   *       }
   *     }
   *   }
   * }
   * ```
   */
  functions?: { [key: string]: { [key: string]: (callContext: CurrentPlugin, ...args: any[]) => any } } | undefined;
  allowedPaths?: { [key: string]: string } | undefined;
  allowedHosts?: string[] | undefined;
  config?: PluginConfigLike | undefined;
  fetch?: typeof fetch;
  sharedArrayBufferSize?: number;
}

/**
 * {@link Plugin} Config
 */
export interface PluginConfigLike {
  [key: string]: string;
}

/**
 * Provides a unified interface for the supported WASI implementations.
 */
export class PluginWasi {
  wasi: any;
  imports: any;
  #initialize: (instance: WebAssembly.Instance) => void;

  constructor(wasi: any, imports: any, init: (instance: WebAssembly.Instance) => void) {
    this.wasi = wasi;
    this.imports = imports;
    this.#initialize = init;
  }

  importObject() {
    return this.imports;
  }

  initialize(instance: WebAssembly.Instance) {
    this.#initialize(instance);
  }
}

enum GuestRuntimeType {
  None,
  Haskell,
  Wasi,
}

type GuestRuntime = {
  init: () => void;
  initialized: boolean;
  type: GuestRuntimeType;
};

function fetchModuleData(
  manifestData: Manifest | ManifestWasm | ArrayBuffer
) {
  let moduleData: ArrayBuffer | null = null;

  if (manifestData instanceof Uint8Array) {
    moduleData = manifestData;
  } else if ((manifestData as Manifest).wasm) {
    const wasmData = (manifestData as Manifest).wasm;
    if (wasmData.length > 1) throw Error('This runtime only supports one module in Manifest.wasm');

    const wasm = wasmData[0];
    moduleData = wasm.data;
  } else if ((manifestData as ManifestWasmData).data) {
    moduleData = (manifestData as ManifestWasmData).data;
  }

  if (!moduleData) {
    throw Error(`Unsure how to interpret manifest ${manifestData}`);
  }

  return moduleData;
}

function haskellRuntime(module: WebAssembly.Instance): GuestRuntime | null {
  const haskellInit = module.exports.hs_init;

  if (!haskellInit) {
    return null;
  }

  const reactorInit = module.exports._initialize;

  let init: () => void;
  if (reactorInit) {
    //@ts-ignore
    init = () => reactorInit();
  } else {
    //@ts-ignore
    init = () => haskellInit();
  }

  const kind = reactorInit ? 'reactor' : 'normal';
  console.debug(`Haskell (${kind}) runtime detected.`);

  return { type: GuestRuntimeType.Haskell, init: init, initialized: false };
}

function wasiRuntime(module: WebAssembly.Instance): GuestRuntime | null {
  const reactorInit = module.exports._initialize;
  const commandInit = module.exports.__wasm_call_ctors;

  // WASI supports two modules: Reactors and Commands
  // we prioritize Reactors over Commands
  // see: https://github.com/WebAssembly/WASI/blob/main/legacy/application-abi.md

  let init: () => void;
  if (reactorInit) {
    //@ts-ignore
    init = () => reactorInit();
  } else if (commandInit) {
    //@ts-ignore
    init = () => commandInit();
  } else {
    return null;
  }

  const kind = reactorInit ? 'reactor' : 'command';
  console.debug(`WASI (${kind}) runtime detected.`);

  return { type: GuestRuntimeType.Wasi, init: init, initialized: false };
}

function detectGuestRuntime(module: WebAssembly.Instance): GuestRuntime {
  const none = { init: () => {}, type: GuestRuntimeType.None, initialized: true };
  return haskellRuntime(module) ?? wasiRuntime(module) ?? none;
}

export function instantiateExtismRuntime(
  runtime: ManifestWasm | null
): WebAssembly.Instance {
  if (!runtime) {
    throw Error('Please specify Extism runtime.');
  }

  const extismWasm = fetchModuleData(runtime);
  const extismModule = new WebAssembly.Module(extismWasm);
  const extismInstance = new WebAssembly.Instance(extismModule, {});

  return extismInstance;
}

export type HttpResponse = {
  body: Uint8Array;
  status: number;
};

export type HttpRequest = {
  url: string;
  headers: { [key: string]: string };
  method: string;
};

export const embeddedRuntime =
	'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';

export const embeddedRuntimeHash = '80fcbfb1d046f0779adf0e3c4861b264a1c56df2d6c9ee051fc02188e83d45f7'

export class CurrentPlugin {
  vars: Record<string, Uint8Array>;
  plugin: Plugin;
  #extism: WebAssembly.Instance;

  constructor(plugin: Plugin, extism: WebAssembly.Instance) {
    this.vars = {};
    this.plugin = plugin;
    this.#extism = extism;
  }

  setVar(name: string, value: Uint8Array | string | number): void {
    if (value instanceof Uint8Array) {
      this.vars[name] = value;
    } else if (typeof value === 'string') {
      this.vars[name] = encodeString(value);
    } else if (typeof value === 'number') {
      this.vars[name] = this.uintToLEBytes(value);
    } else {
      const typeName = (value as any)?.constructor.name || (value === null ? 'null' : typeof value);
      throw new TypeError(`Invalid plugin variable type. Expected Uint8Array, string, or number, got ${typeName}`);
    }
  }

  readStringVar(name: string): string {
    return decodeString(this.getVar(name));
  }

  getNumberVar(name: string): number {
    const value = this.getVar(name);
    if (value.length < 4) {
      throw new Error(`Variable "${name}" has incorrect length`);
    }

    return this.uintFromLEBytes(value);
  }

  getVar(name: string): Uint8Array {
    const value = this.vars[name];
    if (!value) {
      throw new Error(`Variable ${name} not found`);
    }

    return value;
  }

  private uintToLEBytes(num: number): Uint8Array {
    const bytes = new Uint8Array(4);
    new DataView(bytes.buffer).setUint32(0, num, true);

    return bytes;
  }

  private uintFromLEBytes(bytes: Uint8Array): number {
    return new DataView(bytes.buffer).getUint32(0, true);
  }

  /**
   * Resets Extism memory.
   * @returns {void}
   */
  reset() {
    return (this.#extism.exports.reset as Function)();
  }

  /**
   * Allocates a block of memory.
   * @param {bigint} length - Size of the memory block.
   * @returns {bigint} Offset in the memory.
   */
  alloc(length: bigint): bigint {
    return (this.#extism.exports.alloc as Function)(length);
  }

  /**
   * Retrieves Extism memory.
   * @returns {WebAssembly.Memory} The memory object.
   */
  getMemory(): WebAssembly.Memory {
    return this.#extism.exports.memory as WebAssembly.Memory;
  }

  /**
   * Retrieves Extism memory buffer as Uint8Array.
   * @returns {Uint8Array} The buffer view.
   */
  getMemoryBuffer(): Uint8Array {
    return new Uint8Array(this.getMemory().buffer);
  }

  /**
   * Gets bytes from a specific memory offset.
   * @param {bigint} offset - Memory offset.
   * @returns {Uint8Array | null} Byte array or null if offset is zero.
   */
  readBytes(offset: bigint): Uint8Array | null {
    if (offset == BigInt(0)) {
      return null;
    }

    const length = this.getLength(offset);

    const buffer = new Uint8Array(this.getMemory().buffer, Number(offset), Number(length));

    // Copy the buffer because `this.getMemory().buffer` returns a write-through view
    return new Uint8Array(buffer);
  }

  /**
   * Retrieves a string from a specific memory offset.
   * @param {bigint} offset - Memory offset.
   * @returns {string | null} Decoded string or null if offset is zero.
   */
  readString(offset: bigint): string | null {
    const bytes = this.readBytes(offset);
    if (bytes === null) {
      return null;
    }

    return decodeString(bytes);
  }

  /**
   * Allocates bytes to the WebAssembly memory.
   * @param {Uint8Array} data - Byte array to allocate.
   * @returns {bigint} Memory offset.
   */
  writeBytes(data: Uint8Array): bigint {
    const offs = this.alloc(BigInt(data.length));
    const buffer = new Uint8Array(this.getMemory().buffer, Number(offs), data.length);
    buffer.set(data);
    return offs;
  }

  /**
   * Allocates a string to the WebAssembly memory.
   * @param {string} data - String to allocate.
   * @returns {bigint} Memory offset.
   */
  writeString(data: string): bigint {
    const bytes = encodeString(data);
    return this.writeBytes(bytes);
  }

  /**
   * Retrieves the length of a memory block from a specific offset.
   * @param {bigint} offset - Memory offset.
   * @returns {bigint} Length of the memory block.
   */
  getLength(offset: bigint): bigint {
    return (this.#extism.exports.length as Function)(offset);
  }

  inputLength(): bigint {
    return (this.#extism.exports.input_length as Function)();
  }

  /**
   * Frees a block of memory from a specific offset.
   * @param {bigint} offset - Memory offset to free.
   * @returns {void}
   */
  free(offset: bigint) {
    if (offset == BigInt(0)) {
      return;
    }

    (this.#extism.exports.free as Function)(offset);
  }
}

export function encodeString(str: string) {
  var arr = [];
  for (var i = 0, len = str.length; i < len; i++) {
      arr.push(str.charCodeAt(i));
  }
  return new Uint8Array(arr);
}

export function decodeString(arr: Uint8Array) {
  var str = '';
  for (var i = 0, len = arr.length; i < len; i++) {
      str += String.fromCharCode(arr[i]);
  }
  return str;
}

export function createPlugin(
  manifest: Manifest | ManifestWasm | ArrayBuffer,
  opts: ExtismPluginOptions = {},
) : Plugin {

  const runtimeBuffer = toByteArray(embeddedRuntime);
  const runtime = instantiateExtismRuntime({
    data: runtimeBuffer,
    hash: embeddedRuntimeHash,
  });

  const module = fetchModuleData(manifest);
  return new Plugin(runtime, module, opts);
}