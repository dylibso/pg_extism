const { build } = require("esbuild");
const { peerDependencies } = require('./package.json')
const { readFile, writeFile } = require('fs').promises
const { render } = require('ejs');

async function main() {
    const sharedConfig = {
        bundle: true,
        minify: false,
        drop: [], // preseve debugger statements
        external: Object.keys(peerDependencies || {}),
    };

    const path = "dist/index.js";

    // NodeJS CSJ
    await build({
        ...sharedConfig,
        entryPoints: ["src/index.ts"],
        platform: 'browser', // for CJS
        format: "cjs",
        outfile: path,
        external: []
    });

    // remove `module.exports = __toCommonJS(src_exports);`
    const file = await readFile(path, 'utf8');
    const content = file.replace(/module\.exports = __toCommonJS\(src_exports\);/g, '');
    await writeFile(path, content);

    const template = await readFile('template.sql', 'utf8');
    const sql = render(template, { content: indent(content, 1) });

    await writeFile('dist/index.sql', sql, 'utf8');
}

function indent(text, depth) {
    let output = '';
    for (const line of text.split("\n")) {
        if (output != '') { // don't indent first line
            for (let i = 0; i < depth; i++) {
                output += '    ';
            }
        }

        output += line + '\n';
    }

    return output;
}

main()