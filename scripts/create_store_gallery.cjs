const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..', 'assets', 'app-store');
const labels = ['A clearer picture','One calm place','More possibilities','More clarity','Stay a step ahead','Explore your savings','Understand your score','Your private space'];
function collection(dir) {
  const titles = dir === 'ipad-13' ? [...labels.slice(0,4),'In clearer detail','Your preferences','What matters','A little more calm'] : labels;
  return fs.readdirSync(path.join(root,dir)).filter(x=>x.endsWith('.png')).sort().map((file,i)=>`<figure><a href="${dir}/${file}"><img loading="lazy" src="${dir}/${file}" alt="SubSense ${titles[i]} screenshot"></a><figcaption>${String(i+1).padStart(2,'0')} / ${titles[i]}</figcaption></figure>`).join('\n');
}
const html = `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SubSense AI · App Store assets</title>
<style>body{margin:0;background:#10231a;color:#f6f7ee;font:17px/1.6 system-ui}main{max-width:1500px;margin:auto;padding:60px 32px}small{color:#cde8ae;letter-spacing:.2em}h1{font:clamp(36px,6vw,72px)/1.1 Georgia;max-width:850px}h2{font:34px Georgia;margin-top:64px}p{color:#c5d2c9;max-width:850px}nav{display:flex;gap:24px;flex-wrap:wrap}section{display:grid;grid-template-columns:repeat(4,1fr);gap:22px}figure{margin:0}img{width:100%;display:block;border-radius:16px}figcaption{padding:15px 0;color:#c5d2c9}a{color:inherit}.products{grid-template-columns:repeat(2,minmax(0,380px))}@media(max-width:850px){section{grid-template-columns:repeat(2,1fr)}}@media(max-width:480px){main{padding:32px 20px}section,.products{grid-template-columns:1fr}}</style>
<main><small>SUBSENSE AI / STORE COLLECTION</small><h1>A little more clarity.<br>On every screen.</h1><p>Eight iPhone screenshots, eight native 13-inch iPad screenshots, and coordinated subscription artwork. Full-resolution PNGs, original simulator captures, and editable artwork are included.</p><nav><a href="#iphone">iPhone</a><a href="#ipad">iPad 13-inch</a><a href="#pro">SubSense Pro</a></nav>
<h2 id="iphone">iPhone screenshots</h2><p>1284 × 2778 · Actual app UI with illustrative demo records.</p><section>${collection('iphone-6.5')}</section>
<h2 id="ipad">iPad 13-inch screenshots</h2><p>2064 × 2752 · Captured on iPad Pro 13-inch (M4).</p><section>${collection('ipad-13')}</section>
<h2 id="pro">SubSense Pro</h2><p>1024 × 1024 · Product images with editable SVG sources.</p><section class="products">
${['monthly','annual'].map(x=>`<figure><a href="subscriptions/pro-${x}-1024.png"><img src="subscriptions/pro-${x}-1024.png" alt="SubSense Pro ${x} artwork"></a><figcaption>${x} / <a href="subscriptions/pro-${x}.svg">Editable SVG</a></figcaption></figure>`).join('')}
</section><p><a href="raw/review-pro-purchase.png">Subscription review screenshot</a> · <a href="README.md">Capture provenance</a></p><p>These are still screenshots. App preview videos are a separate format.</p></main></html>`;
fs.writeFileSync(path.join(root,'index.html'),html);
