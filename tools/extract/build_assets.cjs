// wk.json (from extract.cjs) → assets/learn/{words,book,quiz}.json
const fs=require('fs');const o=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));const out=process.argv[3];
fs.writeFileSync(out+'/words.json',JSON.stringify(o.RAW.map(w=>w.slice(0,5))));
const book={};for(const L of ['A1','A2'])book[L]=o.BOOK[L].map(c=>({n:c.n,t:c.t,r:c.r.map((r,i)=>({id:L+'.'+c.n+'.'+i,t:{ru:r.t},ex:r.ex,b:{ru:r.b},tr:r.tr||[]}))}));
fs.writeFileSync(out+'/book.json',JSON.stringify(book));
fs.writeFileSync(out+'/quiz.json',JSON.stringify(o.QZ));
console.log('ok');
