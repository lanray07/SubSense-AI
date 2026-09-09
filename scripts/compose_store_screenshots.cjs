// Compose code-native store layouts around intact simulator captures.
const fs = require('fs');
const path = require('path');
const sharp = require(process.env.CODEX_NODE_MODULES ? path.join(process.env.CODEX_NODE_MODULES, 'sharp') : 'sharp');
const root = path.join(__dirname, '..', 'assets', 'app-store');
const source = path.join(root, 'raw');
const dest = path.join(root, 'iphone-6.5');
fs.mkdirSync(dest,{recursive:true});
const panels = [
  ['store-01-home','Your subscriptions.','A clearer picture.','SEE YOUR RECURRING SPENDING'],
  ['store-02-subscriptions','Every plan.','One calm place.','ORGANISE YOUR SUBSCRIPTIONS'],
  ['store-03-insights','Small changes.','More possibilities.','EXPLORE YOUR SPENDING'],
  ['store-04-copilot','A little guidance.','More clarity.','YOUR LOCAL SUBSCRIPTION COPILOT'],
];
async function main(){
  for(const [name,one,two,kicker] of panels){
    const file = path.join(source,`${name}.png`);
    if(!fs.existsSync(file))throw new Error(`Missing actual app capture: ${file}`);
    const meta=await sharp(file).metadata();
    if(meta.width!==1284||meta.height!==2778)throw new Error(`Unexpected capture size: ${meta.width}x${meta.height}`);
    const data=fs.readFileSync(file).toString('base64');
    const svg=`<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1284" height="2778" viewBox="0 0 1284 2778">
<defs><linearGradient id="bg" x2="1" y2="1"><stop stop-color="#304d3d"/><stop offset=".65" stop-color="#14291f"/><stop offset="1" stop-color="#0b1912"/></linearGradient></defs>
<rect width="1284" height="2778" fill="url(#bg)"/>
<circle cx="1200" cy="130" r="700" fill="none" stroke="#cde8ae" stroke-opacity=".1" stroke-width="2"/>
<circle cx="1200" cy="130" r="550" fill="none" stroke="#cde8ae" stroke-opacity=".1" stroke-width="2"/>
<text x="642" y="101" text-anchor="middle" fill="#cde8ae" font-family="Arial" font-size="23" letter-spacing="5">${kicker}</text>
<text x="642" y="234" text-anchor="middle" fill="#f7f8ef" font-family="Georgia" font-size="94">${one}</text>
<text x="642" y="346" text-anchor="middle" fill="#f7f8ef" font-family="Georgia" font-size="94">${two}</text>
<rect x="104" y="450" width="1076" height="2300" rx="54" fill="#050d08"/>
<rect x="115" y="461" width="1054" height="2278" rx="44" fill="#fbfcf9"/>
<image x="127" y="475" width="1030" height="2228.4112" xlink:href="data:image/png;base64,${data}"/>
</svg>`;
    await sharp(Buffer.from(svg),{limitInputPixels:false}).flatten({background:'#192e26'}).removeAlpha().png().toFile(path.join(dest,`${name}-1284x2778.png`));
  }
}
main().catch(e=>{console.error(e);process.exit(1)});
