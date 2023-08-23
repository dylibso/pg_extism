use extism::*;
use extism_manifest::*;
use pgx::{prelude::*, Json};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::env;

pgx::pg_module_magic!();

#[derive(Debug, Serialize, Deserialize)]
enum Type {
    String,
    Number,
    Json,
    StringArray,
    NumberArray,
    JsonArray,
}

#[derive(Serialize, Deserialize)]
struct PluginMetadata {
    #[serde(rename = "entryPoint")]
    entry_point: String,
    parameters: BTreeMap<String, Type>,
    #[serde(rename = "returnType")]
    return_type: Type,
    #[serde(rename = "returnField")]
    return_field: String,
}

#[pg_extern]
fn extism_call(path: &str, name: &str, input: Json) -> Result<Json, Error> {
    let json_string = serde_json::to_string(&input.0).unwrap();

    let mut plugin = new_plugin(path);

    let data = match plugin.call(name, json_string) {
        Ok(v) => v,
        Err(e) => error!("Error while calling plugin: {}", e),
    };

    let output = match std::str::from_utf8(data) {
        Ok(v) => v,
        Err(e) => error!("Invalid UTF-8 sequence: {}", e),
    };

    let response_json: serde_json::Value = serde_json::from_str(output).unwrap();

    Ok(pgx::Json(response_json))
}

#[pg_extern]
fn extism_define(path: &str, name: &str) -> Result<(), Error> {
    let mut plugin = new_plugin(path);

    if !plugin.has_function("metadata") {
        error!("Expected a `metadata` function.");
    }

    let metadata_json = match plugin.call("metadata", "") {
        Ok(v) => v,
        Err(err) => error!("Failed to call metadata function: {}", err),
    };

    let metadata: PluginMetadata = match serde_json::from_slice(metadata_json) {
        Ok(v) => v,
        Err(err) => error!("Failed to deserialize metadata: {}", err),
    };

    // Write an SQL function that calls `extism_call` when it's run
    let sql = generate_dynamic_function(path, name, &metadata);
    Ok(pgx::Spi::run(&sql)?)
}

fn generate_dynamic_function(path: &str, name: &str, metadata: &PluginMetadata) -> String {
    let mut sql = format!("CREATE OR REPLACE FUNCTION {}(", name);

    let mut params_sql = Vec::new();

    for (param_name, param_type) in &metadata.parameters {
        params_sql.push(format!("{} {}", param_name, type_to_sql(param_type)));
    }

    params_sql.reverse();

    sql.push_str(&params_sql.join(", "));
    sql.push_str(&format!(
        ") RETURNS {} AS $$\n",
        type_to_sql(&metadata.return_type)
    ));

    sql.push_str("DECLARE\n");
    sql.push_str("    result_json json;\n");
    sql.push_str("    input_param json;\n");
    sql.push_str("BEGIN\n");
    sql.push_str("    -- Construct JSON object from parameters\n");
    sql.push_str("    input_param := json_build_object(\n");

    let mut params = Vec::new();

    for (param_name, _) in &metadata.parameters {
        params.push(format!("\t'{}', {}", param_name, param_name));
    }

    sql.push_str(&params.join(",\n"));

    sql.push_str("\n\t);\n");
    sql.push_str("    -- Call the extism_define function using the provided parameters\n");
    sql.push_str(&format!(
        "    SELECT extism_call('{}', '{}', input_param) INTO result_json;\n",
        path, metadata.entry_point
    ));

    sql.push_str("    -- Return the desired field from the result JSON\n");
    sql.push_str("    RETURN ");
    match metadata.return_type {
        Type::StringArray | Type::NumberArray | Type::JsonArray => {
            sql.push_str(&format!(
                "QUERY SELECT value::{} FROM json_array_elements((result_json->'{}')::json)",
                inner_type_to_sql(&metadata.return_type),
                metadata.return_field));
        }
        _ => {
            sql.push_str("(result_json->'");
            sql.push_str(&metadata.return_field);
            sql.push_str("')::");
            sql.push_str(&type_to_sql(&metadata.return_type));
        }
    }
    sql.push_str(";\n");

    sql.push_str("EXCEPTION\n");
    sql.push_str("    WHEN others THEN\n");
    sql.push_str("        -- Handle exceptions if necessary\n");
    sql.push_str("        RAISE NOTICE 'An error occurred: %', SQLERRM;\n");

    if !is_array(&metadata.return_type) {
        sql.push_str("        RETURN NULL;\n");
    }

    sql.push_str("END;\n");
    sql.push_str("$$ LANGUAGE plpgsql;");

    sql
}

#[pg_extern]
fn to_lowercase(input: &str) -> String {
    input.to_lowercase()
}

fn type_to_sql(param_type: &Type) -> String {
    match param_type {
        Type::Number => "NUMERIC".to_owned(),
        Type::String => "TEXT".to_owned(),
        Type::Json => "JSON".to_owned(),
        Type::StringArray => "SETOF TEXT".to_owned(),
        Type::NumberArray => "SETOF NUMERIC".to_owned(),
        Type::JsonArray => "SETOF JSON".to_owned(),
    }
}

fn inner_type_to_sql(param_type: &Type) -> String {
    match param_type {
        Type::StringArray => type_to_sql(&Type::String),
        Type::NumberArray => type_to_sql(&Type::Number),
        Type::JsonArray => type_to_sql(&Type::Json),
        _ => panic!("Type is not an array: {}", type_to_sql(param_type)),
    }
}

fn is_array(param_type: &Type) -> bool {
    match param_type {
        Type::StringArray | Type::NumberArray | Type::JsonArray => true,
        _ => false,
    }
}

fn new_plugin<'a>(path: &'a str) -> Plugin<'a> {
    let openai_api_key = env::var("OPENAI_API_KEY")
        .expect("Error: `OPENAI_API_KEY` environment variable not found");

    let manifest = Manifest::new(vec![Wasm::file(path)])
        .with_memory_options(MemoryOptions { max_pages: Some(5) })
        .with_allowed_host("api.openai.com")
        .with_allowed_path("/", "/")
        .with_config(vec![("openai_apikey".to_string(), openai_api_key)].into_iter())
        .with_timeout(std::time::Duration::from_secs(10));

    return Plugin::create_with_manifest(&manifest, [], true).unwrap();
}

#[cfg(any(test, feature = "pg_test"))]
#[pg_schema]
mod tests {
    use pgx::prelude::*;

    use crate::extism_call;

    #[pg_test]
    fn test_extism_call_count_vowels() {
        Spi::run("select extism_define('/mnt/d/dylibso/pg_extism/src/code.wasm', 'count_vowels');")
            .unwrap();
        let result = Spi::get_one::<i32>("select count_vowels('aaabbb')->'count';");
        assert_eq!(Ok(Some(3)), result);
    }
}

/// This module is required by `cargo pgx test` invocations.
/// It must be visible at the root of your extension crate.
#[cfg(test)]
pub mod pg_test {
    pub fn setup(_options: Vec<&str>) {
        // perform one-off initialization when the pg_test framework starts
    }

    pub fn postgresql_conf_options() -> Vec<&'static str> {
        // return any postgresql.conf settings that are required for your tests
        vec![]
    }
}
