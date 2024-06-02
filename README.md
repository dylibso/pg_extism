# pg_extism

**Note**: This is an experimental SDK.

## Getting started
Make sure [`plv8`](https://github.com/plv8/plv8) is installed:
```sql
create extension plv8;
```

Now run the script in [dist/index.sql](./dist/index.sql) and you'll get two SQL functions: `extism_create_plugin` and `extism_call`.

## Use pg_extism

Assume you have a table called `plugins`:
```sql
CREATE TABLE public.plugins (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"data" bytea NULL,
	"name" varchar NULL,
	CONSTRAINT plugins_pk PRIMARY KEY (id)
);
```

Insert a few plugins into the table. And then call:

```sql
select extism_call(data, 'count_vowels', 'Hello World!') from plugins where id = 2;
```

**Note:** this assumes the plugin with id `2` has a function called `count_vowels`. You can find the plugin [here](https://github.com/extism/plugins/releases).

If you want more control over your plugin, you can use `extism_create_plugin`:

```sql
CREATE TABLE public.kv (
	id serial4 NOT NULL,
	"key" bytea NOT NULL,
	value bytea NULL,
	CONSTRAINT kv_pkey PRIMARY KEY (id)
);

CREATE OR REPLACE FUNCTION public.count_vowels_kv(input character varying)
 RETURNS character varying
 LANGUAGE plv8
AS $function$
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

	const createPlugin = plv8.find_function("extism_create_plugin");
	const wasm = plv8.execute("select data from plugins where id = 3")[0]; -- Assume our plugin ID is 3
	const opts = {
		useWasi: true,
		
		functions: {
			"extism:host/user": {
				kv_read(cp, offs) {
	                const key = cp.readString(offs);
				    let result = plv8.execute("SELECT value FROM kv WHERE key = $1", [key]);
				    let value = result.length > 0 ? result[0].value : new Uint8Array([0, 0, 0, 0]);
				    return cp.writeBytes(value);
	            },
	            kv_write(cp, kOffs, vOffs) {
					const key = cp.readString(kOffs);
				    const value = cp.readBytes(vOffs);
				    let result = plv8.execute("SELECT value FROM kv WHERE key = $1", [key]);
				    if (result.length > 0) {
				        plv8.execute("UPDATE kv SET value = $1 WHERE key = $2", [value, key]);
				    } else {
				        plv8.execute("INSERT INTO kv (key, value) VALUES ($1, $2)", [key, value]);
				    }
	            }
			}
		}
	};

	const plugin = createPlugin(wasm, opts);
	return decodeString(plugin.call("count_vowels", encodeString(input)))
$function$
;

```
The above example shows how you can use `extism_create_plugin` to supply your own host functions to the plugin. You can find th source code for the plugin [here](https://github.com/extism/plugins/tree/main/count_vowels_kvstore).
