import { createPlugin, Plugin, ExtismPluginOptions, Manifest, ManifestWasm, CurrentPlugin } from '../src/index';
import { readFile } from 'fs/promises';

async function newPlugin(
  moduleName: string | Manifest | ManifestWasm | Buffer,
  optionsConfig?: (opts: ExtismPluginOptions) => void): Promise<Plugin> {
  let options = {
    useWasi: true,
  }

  if (optionsConfig) {
    optionsConfig(options);
  }

  let module: Manifest | ManifestWasm | Buffer;
  if (typeof moduleName == 'string') {
    module = {
      data: await readFile(`wasm/${moduleName}`),
    };
  } else {
    module = moduleName;
  }

  const plugin = createPlugin(module, options);
  return plugin;
}

describe('test extism', () => {
  test('fails on hash mismatch', async () => {
    await expect(newPlugin({
      data: await readFile("wasm/count_vowels.wasm"),
      name: "code",
      hash: "-----------"
    })).rejects.toThrow(/Plugin error/);
  });

  test('can create and call a plugin', async () => {
    const plugin = await newPlugin('count_vowels.wasm');
    let output = plugin.call('count_vowels', 'this is a test');

    let result = output?.json();
    expect(result['count']).toBe(4);
    output = plugin.call('count_vowels', 'this is a test again');
    result = output?.json();
    expect(result['count']).toBe(7);
    output = plugin.call('count_vowels', 'this is a test thrice');
    result = output?.json();
    expect(result['count']).toBe(6);
    output = plugin.call('count_vowels', '🌎hello🌎world🌎');
    result = output?.json();
    expect(result['count']).toBe(3);
  });

  test('can detect if function exists or not', async () => {
    const plugin = await newPlugin('count_vowels.wasm');
    expect(plugin.functionExists('count_vowels')).toBe(true);
    expect(plugin.functionExists('i_dont_extist')).toBe(false);
  });

  test('errors when function is not known', async () => {
    const plugin = await newPlugin('count_vowels.wasm');
    expect(() => plugin.call('i_dont_exist', 'example-input')).toThrow('Plugin error: function does not exist i_dont_exist');
    // expect(plugin.call('i_dont_exist', 'example-input')).rejects.toThrow('Plugin error: function does not exist i_dont_exist');
  });

  test('plugin can allocate memory', async () => {
    const plugin = await newPlugin('alloc.wasm');
    plugin.call("run_test", "")
  });

  test('plugin can fail gracefuly', async () => {
    const plugin = await newPlugin('fail.wasm');
    expect(() => plugin.call("run_test", "")).toThrowError(/Call error/);
  });

  test('host functions works', async () => {
    const kv = new Map<string, Uint8Array>();

    const plugin = await newPlugin('count_vowels_kvstore.wasm', options => {
      options.functions ??= {};

      options.functions["extism:host/user"] = {
        kv_read(cp, offs) {
          const key = cp.read(offs)?.text()!;
          const value = kv.get(key) ?? new Uint8Array([0, 0, 0, 0]);
          return cp.store(value);
        },
        kv_write(cp, kOffs, vOffs) {
          const key = cp.read(kOffs)?.text()!;
          const value = cp.read(vOffs)?.bytes()!;
          kv.set(key, value);
        }
      }
    });

    let result;
    for (let i = 0; i < 3; i++) {
      const output = plugin.call('count_vowels', 'aaa');
      result = output?.json();
    }

    expect(result).toStrictEqual({
      count: 3,
      total: 9,
      vowels: "aeiouAEIOU"
    })
  });

  test('can deny http requests', async () => {
    const plugin = await newPlugin('http.wasm');
    await expect(() => plugin.call("run_test", "")).rejects.toThrowError(/Call error/);
  });

  test('can initialize haskell runtime', async () => {
    console.trace = jest.fn();

    const plugin = await newPlugin('hello_haskell.wasm', options => {
      options.config = {
        "greeting": "Howdy"
      };
    });

    {
      const output = await plugin.call("testing", "John");
      const result = output;

      expect(result).toBe("Howdy, John")
    }

    {
      const output = await plugin.call("testing", "Ben");
      const result = output;

      expect(result).toBe("Howdy, Ben")
    }

    expect(console.debug).toHaveBeenCalledWith("Haskell (normal) runtime detected.");
  });
});
