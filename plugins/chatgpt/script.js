function metadata() {
    const metadata = {
        entryPoint: "chatgpt",
        parameters: {
            "prompt": "String",
            "payload": "String"
        },
        returnType: "String",
        returnField: "response"
    };

    Host.outputString(JSON.stringify(metadata))
}


function chatgpt() {
    const { prompt, payload } = JSON.parse(Host.inputString());

    let body = JSON.stringify({
        "model": "gpt-3.5-turbo",
        "messages": [
            {
                "role": "user",
                "content": `${prompt} ${payload}`
            }
        ]
    });

    let httpResponse = Http.request(
        {
            url: "https://api.openai.com/v1/chat/completions",
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${Config.get("openai_apikey")}`
            }
        },
        body
    );

    let response = JSON.parse(httpResponse.body)

    if (!response.choices || !response.choices[0]) {
        throw new Error(`Unexpected response from OpenAI: ${httpResponse.body}`);
    }

    console.log("LLM: Received Response from OpenAI", response.choices[0].message.content);

    Host.outputString(JSON.stringify({
        response: response.choices[0].message.content
    }));
}

module.exports = { chatgpt, metadata }