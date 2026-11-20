// Evaluates the Wortkreis script with a stub DOM and dumps its data as JSON.
// node extract.cjs wortkreis.html out-wk.json [out-trainers.json]
const fs = require('fs'), vm = require('vm');
const html = fs.readFileSync(process.argv[2], 'utf8');
const src = html.split('<script>')[1].split('</script>')[0];
const el = () => new Proxy(function () {}, {
  get: (t, k) => k === 'innerHTML' || k === 'textContent' ? '' : k === 'classList' ? {add() {}, remove() {}, toggle() {}, contains() { return false; }} : k === 'style' ? {} : el(),
  apply: () => el(), set: () => true,
});
const ctx = {console, Math, Date, JSON, Object, Array, String, Number, RegExp, parseInt, parseFloat, isNaN, encodeURIComponent,
  setTimeout() {}, clearTimeout() {}, setInterval() {}, clearInterval() {},
  document: el(), window: {speechSynthesis: {getVoices: () => []}, addEventListener() {}}, localStorage: {getItem: () => null, setItem() {}},
  location: {hash: ''}, navigator: {language: 'ru'}, URLSearchParams};
ctx.window.window = ctx.window; ctx.__x = {};
vm.createContext(ctx);
const body = src.replace(/^\s*\(function\(\)\{/, '').replace(/\}\)\(\);\s*$/, '').replace(/renderHome\(\);\s*initCloud\(\);\s*$/, '');
const tail = `
__x.out={RAW,BOOK,QZ,AJ,CHNAME};
__x.tr={PR,PRK,SUBJ,PV,PP,NT,NP,NV,NTIME,NTHRU,NNOT,NDRINK,NTOOL,AT,XP,XF,GENT,GENX,CHUNK,QOPT,CASEHINT,PRHINT,CEXP,
  CL:CL.map(function(l){return {id:l.id,name:l.name,d:l.d,mode:l.mode||"",chunks:!!l.chunks};}),
  EXV,BASK,VP,VSUBJ,VPL,VPERS,WO,DA,ORD,ORDW,SEPI,PERF,GREC,GGIFT,WUN,TIMEI,POL,ZS,ZD,TOPV,VDESC,VORDER,VAN,AJ,AJM,
  SHEET:VORDER.reduce(function(o,k){o[k]=vSheetFor(k);return o;},{}),
  AJT:{d:ajTable("d"),i:ajTable("i"),z:ajTable("z")}};`;
vm.runInContext('(function(){' + body + '\n;' + tail + '})()', ctx, {filename: 'wk.js'});
const o = ctx.__x.out;
fs.writeFileSync(process.argv[3], JSON.stringify(o));
if (process.argv[4]) fs.writeFileSync(process.argv[4], JSON.stringify(ctx.__x.tr));
console.log('words', o.RAW.length, 'A1', o.BOOK.A1.length, 'A2', o.BOOK.A2.length, 'QZ', Object.keys(o.QZ).length);
