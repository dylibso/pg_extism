CREATE OR REPLACE FUNCTION extism_create_plugin(manifest integer, opts integer)
RETURNS integer
LANGUAGE plv8
AS $function$
    <%- content %>
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