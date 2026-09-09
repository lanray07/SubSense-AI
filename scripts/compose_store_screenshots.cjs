// Compose code-native store layouts around intact simulator captures.
const fs = require('fs');
const path = require('path');
const sharp = require(process.env.CODEX_NODE_MODULES ? path.join(process.env.CODEX_NODE_MODULES, 'sharp') : 'sharp');
const root = path.join(__dirname, '..', 'assets', 'app-store');
const ipad = process.argv.includes('--ipad');
const source = path.join(root, ipad ? 'raw-ipad' : 'raw');
const dest = path.join(root, ipad ? 'ipad-13' : 'iphone-6.5');
const W = ipad ? 2064 : 1284, H = ipad ? 2752 : 2778;
fs.mkdirSync(dest,{recursive:true});
const panels = [
  ['store-01-home','Your subscriptions.','A clearer picture.','SEE YOUR RECURRING SPENDING'],
  ['store-02-subscriptions','Every plan.','One calm place.','ORGANISE YOUR SUBSCRIPTIONS'],
  ['store-03-insights','Small changes.','More possibilities.','EXPLORE YOUR SPENDING'],
  ['store-04-copilot','A little guidance.','More clarity.','YOUR LOCAL SUBSCRIPTION COPILOT'],
  ...(ipad ? [
  ['store-05-detail','Every commitment.','In clearer detail.','COST, USAGE AND VALUE'],
  ['store-06-settings','Your space.','Your preferences.','MAKE SUBSENSE YOURS'],
  ['store-07-goals','Make room for','what matters.','YOUR PROFILE AND SAVINGS GOAL'],
  ['store-08-reminders','A timely reminder.','A little more calm.','PLAN YOUR RENEWAL REMINDERS'],
  ] : [
  ['store-05-renewals','See what’s next.','Stay a step ahead.','YOUR RENEWALS, TOGETHER'],
  ['store-06-simulator','Explore the change.','See the possibility.','MODEL YOUR SAVINGS'],
  ['store-07-health','Know the score.','Understand the why.','YOUR SUBSCRIPTION HEALTH'],
  ['store-08-privacy','Your information.','Your private space.','LOCAL BY DESIGN'],
  ]),
];
async function main(){
  for(const [name,one,two,kicker] of panels){
    const file = path.join(source,`${name}.png`);
    if(!fs.existsSync(file)) {
      if(process.argv.includes('--available')) continue;
      throw new Error(`Missing actual app capture: ${file}`);
    }
    const meta=await sharp(file).metadata();
    if(meta.width!==W||meta.height!==H)throw new Error(`Unexpected capture size: ${meta.width}x${meta.height}`);
    const data=fs.readFileSync(file).toString('base64');
    let svg=`<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1284" height="2778" viewBox="0 0 1284 2778">
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
    if(ipad) {
      svg = svg.replace('width="1284" height="2778" viewBox="0 0 1284 2778"',`width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"`)
        .replace('<rect width="1284" height="2778"',`<rect width="${W}" height="${H}"`)
        .replaceAll('x="642"','x="1032"').replaceAll('font-size="94"','font-size="112"')
        .replace('x="104" y="450" width="1076" height="2300"','x="208" y="474" width="1648" height="2181.33"')
        .replace('x="115" y="461" width="1054" height="2278"','x="220" y="486" width="1624" height="2157.33"')
        .replace('x="127" y="475" width="1030" height="2228.4112"','x="232" y="498" width="1600" height="2133.3333"');
    }
    await sharp(Buffer.from(svg),{limitInputPixels:false}).flatten({background:'#192e26'}).removeAlpha().png().toFile(path.join(dest,`${name}-${W}x${H}.png`));
  }
}
main().catch(e=>{console.error(e);process.exit(1)});
