import { toByteArray } from "base64-js";
import { initialize } from "esbuild";
import { sha256 } from "js-sha256";

export class PluginOutput extends DataView {
  #output: Uint8Array;
  constructor(output: Uint8Array) {
    super(output.buffer);
    this.#output = output;
  }

  json(): any {
    return JSON.parse(this.text());
  }

  text(): string {
    return decodeString(this.#output);
  }

  bytes(): Uint8Array {
    return this.#output;
  }

  arrayBuffer(): ArrayBufferLike {
    return this.#output.buffer;
  }
}

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
    this.guestRuntime = { type: GuestRuntimeType.None, init: () => { }, initialized: true };
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

    if (func_name != '_start' && !this.guestRuntime.initialized) {
      this.guestRuntime.init();
      this.guestRuntime.initialized = true;
    }

    //@ts-ignore
    func();

    return this.output;
  }

  call(func_name: string, input: string): PluginOutput | null {
    const output = this.callRaw(func_name, encodeString(input));
    return new PluginOutput(output);
  }

  protected loadWasi(options: ExtismPluginOptions): PluginWasi {
    const args: Array<string> = [];
    const envVars: Array<string> = [];

    return new PluginWasi();
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

    if (pluginWasi) {
      pluginWasi.initialize(this.module.instance);
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
        throw new Error(`Call error: ${cp.read(i)?.text()}`);
      },
      config_get(cp: CurrentPlugin, i: bigint): bigint {
        if (typeof plugin.options.config === 'undefined') {
          return BigInt(0);
        }
        const key = cp.read(i)?.text()
        if (!key) {
          return BigInt(0);
        }
        const value = plugin.options.config[key];
        if (typeof value === 'undefined') {
          return BigInt(0);
        }
        return cp.store(value);
      },
      var_get(cp: CurrentPlugin, i: bigint): bigint {
        const key = cp.read(i)?.text();
        if (!key) {
          return BigInt(0);
        }
        const value = cp.vars[key];
        if (typeof value === 'undefined') {
          return BigInt(0);
        }
        return cp.store(value);
      },
      var_set(cp: CurrentPlugin, n: bigint, i: bigint) {
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
      http_request(cp: CurrentPlugin, requestOffset: bigint, bodyOffset: bigint): bigint {
        throw new Error('Call error: http requests are not supported.');
      },
      http_status_code(): number {
        return plugin.lastStatusCode;
      },
      length(cp: CurrentPlugin, i: bigint): bigint {
        return cp.length(i);
      },
      log_warn(cp: CurrentPlugin, i: bigint) {
        const s = cp.read(i)?.text();

        // @ts-ignore
        plv8.elog(WARNING, s);
      },
      log_info(cp: CurrentPlugin, i: bigint) {
        const s = cp.read(i)?.text();
        // @ts-ignore
        plv8.elog(INFO, s);
      },
      log_debug(cp: CurrentPlugin, i: bigint) {
        const s = cp.read(i)?.text();
        // @ts-ignore
        plv8.elog(DEBUG1, s);
      },
      log_error(cp: CurrentPlugin, i: bigint) {
        const s = cp.read(i)?.text();
        // @ts-ignore
        plv8.elog(ERROR, s);
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
  imports: any;
  inst: WebAssembly.Instance | null = null;
  args: string[];
  env: string[];

  constructor(args: string[] = [], env: string[] = []) {
    this.args = args;
    this.env = env;

    const self = this;
    function memory(): WebAssembly.Memory {
      return self.inst!.exports.memory as WebAssembly.Memory;
    }

    this.imports = {
      fd_write: (fd: number, iovs: number, iovs_len: number, nwritten: number) => {
        // we only support stdin, stdout, and stderr
        if (fd < 0 || fd > 2) {
          throw new Error('fd_write not implemented');
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
      fd_close(fd: number): number {
        // we only support stdin, stdout, and stderr
        if (fd < 0 || fd > 2) {
          throw new Error('fd_close not implemented');
        }

        return 0;
      },
      fd_seek(fd: number, offset: bigint, whence: number, newoffset: number): number {
        throw new Error('fd_seek not implemented');
      },
      fd_fdstat_get(fd: number, buf: number): number {
        throw new Error('fd_fdstat_get not implemented');
      },
      fd_read(fd: number, iovs_ptr: number, iovs_len: number, nread_ptr: number): number {
        throw new Error('fd_read not implemented');
      },
      fd_fdstat_set_flags(fd: number, flags: number): number {
        throw new Error('fd_fdstat_set_flags not implemented');
      },
      fd_filestat_get(fd: number, buf: number): number {
        throw new Error('fd_filestat_get not implemented');
      },
      fd_filestat_set_size(fd: number, size: bigint): number {
        throw new Error('fd_filestat_set_size not implemented');
      },
      path_create_directory(fd: number,
        path_ptr: number,
        path_len: number,): number {
        throw new Error('path_create_directory not implemented');
      },
      path_filestat_get(fd: number,
        flags: number,
        path_ptr: number,
        path_len: number,
        filestat_ptr: number): number {
        throw new Error('path_filestat_get not implemented');
      },
      fd_prestat_get(fd: number, buf_ptr: number): number {
        throw new Error('fd_prestat_get not implemented');
      },
      fd_prestat_dir_name(
        fd: number,
        path_ptr: number,
        path_len: number,
      ): number {
        throw new Error('fd_prestat_dir_name not implemented');
      },
      path_open(fd: number,
        dirflags: number,
        path_ptr: number,
        path_len: number,
        oflags: number,
        fs_rights_base: number,
        fs_rights_inheriting: number,
        fd_flags: number,
        opened_fd_ptr: number): number {
        throw new Error('path_open not implemented');
      },
      poll_oneoff(in_ptr: number, out_ptr: number, nsubscriptions: number, nevents: number): number {
        throw new Error('poll_oneoff not implemented');
      },
      proc_exit(rval: number): void {
        throw new Error(`proc_exit: ${rval}`);
      },
      clock_time_get(id: number, precision: bigint, time: number): number {
        const buffer = new DataView(memory().buffer);
        buffer.setBigUint64(
          time,
          BigInt(new Date().getTime()) * 1_000_000n,
          true,
        );

        return 0;
      },
      args_sizes_get(argc: number, argv_buf_size: number): number {
        const buffer = new DataView(memory().buffer);
        buffer.setUint32(argc, self.args.length, true);
        let buf_size = 0;
        for (const arg of self.args) {
          buf_size += arg.length + 1;
        }
        buffer.setUint32(argv_buf_size, buf_size, true);
        return 0;
      },
      args_get(argv: number, argv_buf: number): number {
        const buffer = new DataView(memory().buffer);
        const buffer8 = new Uint8Array(memory().buffer);
        const orig_argv_buf = argv_buf;
        for (let i = 0; i < self.args.length; i++) {
          buffer.setUint32(argv, argv_buf, true);
          argv += 4;
          const arg = new TextEncoder().encode(self.args[i]);
          buffer8.set(arg, argv_buf);
          buffer.setUint8(argv_buf + arg.length, 0);
          argv_buf += arg.length + 1;
        }
        return 0;
      },

      environ_sizes_get(environ_count: number, environ_size: number): number {
        const buffer = new DataView(memory().buffer);
        buffer.setUint32(environ_count, self.env.length, true);
        let buf_size = 0;
        for (const environ of self.env) {
          buf_size += environ.length + 1;
        }
        buffer.setUint32(environ_size, buf_size, true);
        return 0;
      },
      environ_get(environ: number, environ_buf: number): number {
        const buffer = new DataView(memory().buffer);
        const buffer8 = new Uint8Array(memory().buffer);
        const orig_environ_buf = environ_buf;
        for (let i = 0; i < self.env.length; i++) {
          buffer.setUint32(environ, environ_buf, true);
          environ += 4;
          const e = new TextEncoder().encode(self.env[i]);
          buffer8.set(e, environ_buf);
          buffer.setUint8(environ_buf + e.length, 0);
          environ_buf += e.length + 1;
        }
        return 0;
      },
    }
  }

  importObject() {
    return this.imports;
  }

  initialize(instance: WebAssembly.Instance) {
    if (!instance.exports.memory) {
      throw new Error('The module has to export a default memory.');
    }

    this.inst = instance;
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
  let moduleData: ManifestWasm | null = null;

  if (manifestData instanceof Uint8Array) {
    moduleData = { data: manifestData };
  } else if ((manifestData as Manifest).wasm) {
    const wasmData = (manifestData as Manifest).wasm;
    if (wasmData.length > 1) throw Error('This runtime only supports one module in Manifest.wasm');

    const wasm = wasmData[0];
    moduleData = wasm;
  } else if ((manifestData as ManifestWasmData).data) {
    moduleData = (manifestData as ManifestWasmData);
  }

  if (!moduleData) {
    throw Error(`Unsure how to interpret manifest ${manifestData}`);
  }

  const expected = moduleData.hash;
  if (expected) {
    const actual = sha256(moduleData.data);
    if (actual !== expected) {
      throw Error(`Plugin error: hash mismatch. Expected: ${expected}. Actual: ${actual}`);
    }
  }

  return moduleData.data;
}

function haskellRuntime(module: WebAssembly.Instance): GuestRuntime | null {
  const haskellInit = module.exports.hs_init;

  if (!haskellInit) {
    return null;
  }

  const reactorInit = module.exports._initialize;

  let init = () => {
    if (reactorInit) {
      //@ts-ignore
      reactorInit(); 
    }

    //@ts-ignore
    haskellInit();
  }

  const kind = reactorInit ? 'reactor' : 'normal';
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

  return { type: GuestRuntimeType.Wasi, init: init, initialized: false };
}

function detectGuestRuntime(module: WebAssembly.Instance): GuestRuntime {
  const none = { init: () => { }, type: GuestRuntimeType.None, initialized: true };
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
  'AGFzbQEAAAABJwhgA39/fwF/YAF+AX5gAX4AYAF+AX9gAn5/AGACfn4AYAABfmAAAAMXFgAAAQIBAQMBAwEEBQUFBgYGBgcCBgYFAwEAEAYZA38BQYCAwAALfwBBgIDAAAt/AEGAgMAACwegAhcGbWVtb3J5AgAFYWxsb2MAAgRmcmVlAAMNbGVuZ3RoX3Vuc2FmZQAEBmxlbmd0aAAFB2xvYWRfdTgABghsb2FkX3U2NAAHDWlucHV0X2xvYWRfdTgACA5pbnB1dF9sb2FkX3U2NAAJCHN0b3JlX3U4AAoJc3RvcmVfdTY0AAsJaW5wdXRfc2V0AAwKb3V0cHV0X3NldAANDGlucHV0X2xlbmd0aAAODGlucHV0X29mZnNldAAPDW91dHB1dF9sZW5ndGgAEA1vdXRwdXRfb2Zmc2V0ABEFcmVzZXQAEgllcnJvcl9zZXQAEwllcnJvcl9nZXQAFAxtZW1vcnlfYnl0ZXMAFQpfX2RhdGFfZW5kAwELX19oZWFwX2Jhc2UDAgqkGBa1AQEDfwJAAkAgAkEQTw0AIAAhAwwBCyAAQQAgAGtBA3EiBGohBQJAIARFDQAgACEDA0AgAyABOgAAIANBAWoiAyAFSQ0ACwsgBSACIARrIgRBfHEiAmohAwJAIAJBAUgNACABQf8BcUGBgoQIbCECA0AgBSACNgIAIAVBBGoiBSADSQ0ACwsgBEEDcSECCwJAIAJFDQAgAyACaiEFA0AgAyABOgAAIANBAWoiAyAFSQ0ACwsgAAsOACAAIAEgAhCAgICAAAvaAwMBfwN+An8CQCAAUEUNAEIADwtBAEEALQABIgFBASABGzoAAQJAAkACQAJAAkAgAQ0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEIGAgIAAGgtBACkDESECAkACQAJAAkBBACkDCSIDQsEAfCIEQsIAVA0AIACnIQVBwQAhAQNAAkACQAJAIAEtAAAOAwYAAQALIAEoAgQhBgwBCyABKAIEIgYgBU8NAwsgBCABIAZqQQxqIgGtVg0ACwsgAEIMfCIEIAIgA31CQHwiAloNAgwFCyAGIAVrIgZBgAFJDQAgAUEANgIIIAEgBkF0aiIGNgIEIAEgBmoiAUEUakEANgIAIAFBEGogBTYCACABQQxqIgFBAjoAAAsgAUEBOgAAIAEgBTYCCAwECyAEIAJ9IgJC//8Dg0IAUiACQhCIp2oiAUAAQX9HDQFBACEBDAMLAAALQQBBACkDESABrUIQhnw3AxELQQBBACkDCSAEfDcDCSADpyIBQckAaiAApyIGNgIAIAFBxQBqIAY2AgAgAUHBAGoiAUEBOgAACyABQQxqrUIAIAEbC+4BAwF/AX4BfwJAAkAgAEIAUQ0AQQBBAC0AASIBQQEgARs6AAECQCABDQACQD8ADQBBAUAAQX9GDQMLQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQgYCAgAAaCyAAQsAAVA0APwCtQhCGIABUDQAgAELBAHwhAkHBACEBAkADQCABQQxqIQMCQCABLQAAQQFHDQAgA60gAFENAgsgAiADIAEoAgRqIgGtVg0ADAILCyABQQI6AABBACkDISAAUg0AQQBCADcDKQsPCwAACzgCAX4Bf0IAIQECQCAAQj9YDQA/AK1CEIYgAFQNACAAp0F0aiICLQAAQQFHDQAgAjUCCCEBCyABC9oBAwF/AX4BfwJAAkACQCAAUA0AQQBBAC0AASIBQQEgARs6AAECQCABDQACQD8ADQBBAUAAQX9GDQQLQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQgYCAgAAaCyAAQsAAVA0APwCtQhCGIABUDQAgAELBAHwhAkHBACEBA0AgAUEMaiEDAkAgAS0AAEEBRw0AIAOtIABRDQMLIAIgAyABKAIEaiIBrVYNAAsLQgAPCyABNQIIDwsAAAsoAQF/QQAhAQJAIABCwABUDQA/AK1CEIYgAFQNACAApy0AACEBCyABCy0BAn5CACEBAkAgAEIHfCICQsAAVA0AIAI/AK1CEIZWDQAgAKcpAwAhAQsgAQuVAQECf0EAIQFBAEEALQABIgJBASACGzoAAQJAAkAgAg0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEIGAgIAAGgsCQEEAKQMpIABYDQBBACkDISAAfKctAAAhAQsgAQ8LAAALmgECAX8BfkEAQQAtAAEiAUEBIAEbOgABAkACQCABDQACQD8ADQBBAUAAQX9GDQILQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQgYCAgAAaC0IAIQICQCAAQgh8QQApAylWDQBBACkDISAAfKcpAwAhAgsgAg8LAAALIAACQCAAQsAAVA0APwCtQhCGIABUDQAgAKcgAToAAAsLJwEBfgJAIABCB3wiAkLAAFQNACACPwCtQhCGVg0AIACnIAE3AwALC7sBAgF/AX5BAEEALQABIgJBASACGzoAAQJAAkAgAg0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEIGAgIAAGgsCQCAAQsEAVA0AQQApAxFCwQB8IABYDQAgACABfEJ/fCIDQsEAVA0AQQApAxFCwQB8IANYDQBBACAANwMhQQAgATcDKQsPCwAAC7sBAgF/AX5BAEEALQABIgJBASACGzoAAQJAAkAgAg0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEIGAgIAAGgsCQCAAQsEAVA0AQQApAxFCwQB8IABYDQAgACABfEJ/fCIDQsEAVA0AQQApAxFCwQB8IANYDQBBACAANwMxQQAgATcDOQsPCwAAC3kBAX9BAEEALQABIgBBASAAGzoAAQJAAkAgAA0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEIGAgIAAGgtBACkDKQ8LAAALeQEBf0EAQQAtAAEiAEEBIAAbOgABAkACQCAADQACQD8ADQBBAUAAQX9GDQILQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQgYCAgAAaC0EAKQMhDwsAAAt5AQF/QQBBAC0AASIAQQEgABs6AAECQAJAIAANAAJAPwANAEEBQABBf0YNAgtBAEIANwMhQQBCADcDKUEAQgA3AzFBAEIANwM5QQBCADcDGUEAQsD/AzcDEUEAQgA3AwlBwQBBAEGQARCBgICAABoLQQApAzkPCwAAC3kBAX9BAEEALQABIgBBASAAGzoAAQJAAkAgAA0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEIGAgIAAGgtBACkDMQ8LAAALswEBAX9BAEEALQABIgBBASAAGzoAAQJAAkAgAA0AAkA/AA0AQQFAAEF/Rg0CC0EAQgA3AyFBAEIANwMpQQBCADcDMUEAQgA3AzlBAEIANwMZQQBCwP8DNwMRQQBCADcDCUHBAEEAQZABEIGAgIAAGgtBACgCCSEAQQBCADcDCUHBAEEAIAAQgYCAgAAaQQBCADcDGUEAQgA3AzlBAEIANwMxQQBCADcDKUEAQgA3AyEPCwAAC5wBAQF/QQBBAC0AASIBQQEgARs6AAECQAJAIAENAAJAPwANAEEBQABBf0YNAgtBAEIANwMhQQBCADcDKUEAQgA3AzFBAEIANwM5QQBCADcDGUEAQsD/AzcDEUEAQgA3AwlBwQBBAEGQARCBgICAABoLAkACQCAAUA0AIABCwQBUDQFBACkDEULBAHwgAFgNAQtBACAANwMZCw8LAAALeQEBf0EAQQAtAAEiAEEBIAAbOgABAkACQCAADQACQD8ADQBBAUAAQX9GDQILQQBCADcDIUEAQgA3AylBAEIANwMxQQBCADcDOUEAQgA3AxlBAELA/wM3AxFBAEIANwMJQcEAQQBBkAEQgYCAgAAaC0EAKQMZDwsAAAt5AQF/QQBBAC0AASIAQQEgABs6AAECQAJAIAANAAJAPwANAEEBQABBf0YNAgtBAEIANwMhQQBCADcDKUEAQgA3AzFBAEIANwM5QQBCADcDGUEAQsD/AzcDEUEAQgA3AwlBwQBBAEGQARCBgICAABoLQQApAxEPCwAACw==';

export const embeddedRuntimeHash = 'c04772bc7c7541980fe2e35fae881c190fcc8b4dbf20688ab7b42bec175366ca'

export class CurrentPlugin {
  vars: Record<string, Uint8Array>;
  plugin: Plugin;
  #extism: WebAssembly.Instance;

  constructor(plugin: Plugin, extism: WebAssembly.Instance) {
    this.vars = {};
    this.plugin = plugin;
    this.#extism = extism;
  }

  setVariable(name: string, value: Uint8Array | string | number): void {
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

  getVariable(name: string): PluginOutput {
    const value = this.vars[name];
    if (!value) {
      throw new Error(`Variable ${name} not found`);
    }

    return new PluginOutput(value);
  }

  private uintToLEBytes(num: number): Uint8Array {
    const bytes = new Uint8Array(4);
    new DataView(bytes.buffer).setUint32(0, num, true);

    return bytes;
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
  read(offset: bigint): PluginOutput | null {
    if (offset == BigInt(0)) {
      return null;
    }

    const length = this.length(offset);

    const buffer = new Uint8Array(this.getMemory().buffer, Number(offset), Number(length));

    // Copy the buffer because `this.getMemory().buffer` returns a write-through view
    return new PluginOutput(new Uint8Array(buffer));
  }

  /**
   * Allocates bytes to the WebAssembly memory.
   * @param {Uint8Array} data - Byte array to allocate.
   * @returns {bigint} Memory offset.
   */
  store(data: string | Uint8Array): bigint {
    const offs = this.alloc(BigInt(data.length));
    const buffer = new Uint8Array(this.getMemory().buffer, Number(offs), data.length);

    if (typeof data === 'string') {
      buffer.set(encodeString(data));
    } else {
      buffer.set(data);
    }

    return offs;
  }

  /**
   * Retrieves the length of a memory block from a specific offset.
   * @param {bigint} offset - Memory offset.
   * @returns {bigint} Length of the memory block.
   */
  length(offset: bigint): bigint {
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
): Plugin {

  const runtimeBuffer = toByteArray(embeddedRuntime);
  const runtime = instantiateExtismRuntime({
    data: runtimeBuffer,
    hash: embeddedRuntimeHash,
  });

  const module = fetchModuleData(manifest);
  return new Plugin(runtime, module, opts);
}