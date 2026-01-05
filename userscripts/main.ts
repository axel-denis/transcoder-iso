import { readFileSync, writeFileSync } from "node:fs";
import { generateVideoLibrary, type VideoFile } from "./lib.ts";

(async () => {
    const foldersToScan = process.argv.slice(2);

    let library;

    if (foldersToScan.length > 0) {
        console.log("Will scan folders:");
        foldersToScan.forEach(f => console.log(f))

        library = await generateVideoLibrary(foldersToScan) as VideoFile[];

        writeFileSync("cache.json", JSON.stringify(library));
    } else {
        console.log("Using cache");
        library = JSON.parse(readFileSync("cache.json").toString()) as VideoFile[]
        console.log(`${library.length} medias found in cache`);
    }

    const h264files = library
        .filter(v => v.codec === "h264")
        .map(v => {return {
            name: v.fileName,
            path: v.filePath,
            size: (v.sizeBytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB',
        }})

    writeFileSync("out.json", JSON.stringify(h264files));
})();