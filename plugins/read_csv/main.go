package main

import (
	"encoding/csv"
	"encoding/json"
	"os"

	"github.com/extism/go-pdk"
)

type PluginMetadata struct {
	EntryPoint  string            `json:"entryPoint"`
	Parameters  map[string]string `json:"parameters"`
	ReturnType  string            `json:"returnType"`
	ReturnField string            `json:"returnField"`
}

type Params struct {
	Path string `json:"path"`
}

// //export __wasm_call_ctors
// func __wasm_call_ctors()

// //export _initialize
// func _initialize() {
// 	__wasm_call_ctors()
// }

//export metadata
func metadata() int32 {
	plugin := PluginMetadata{
		EntryPoint: "_start",
		Parameters: map[string]string{
			"path": "String",
		},
		ReturnType:  "JsonArray",
		ReturnField: "rows",
	}

	out, err := json.Marshal(plugin)
	if err != nil {
		panic(err)
	}

	pdk.Output(out)

	return 0
}

func read_csv() int32 {
	params := Params{}

	err := json.Unmarshal(pdk.Input(), &params)
	if err != nil {
		panic(err)
	}

	file, err := os.Open(params.Path)
	if err != nil {
		panic(err)
	}

	defer file.Close()

	reader := csv.NewReader(file)
	headers, err := reader.Read()
	if err != nil {
		panic(err)
	}

	var jsonArray []map[string]interface{}

	for {
		record, err := reader.Read()
		if err != nil {
			break
		}

		jsonObject := make(map[string]interface{})
		for i, value := range record {
			jsonObject[headers[i]] = value
		}

		jsonArray = append(jsonArray, jsonObject)
	}

	buff, err := json.Marshal(map[string]interface{}{"rows": jsonArray})

	if err != nil {
		panic(err)
	}

	mem := pdk.AllocateBytes(buff)
	pdk.OutputMemory(mem)

	return 8
}

func main() {
	read_csv()
}
