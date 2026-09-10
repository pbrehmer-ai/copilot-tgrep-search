import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,writeFile,mkdir} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {execFileSync,spawn} from 'node:child_process';
import readline from 'node:readline';
import {fileURLToPath} from 'node:url';
import {createSearch,comparePaths} from '../mcp/server.mjs';

const executable=process.env.TGREP_EXE || path.join(process.env.LOCALAPPDATA,'Programs/copilot-tgrep/1.0.5/tgrep.exe');
const root=await mkdtemp(path.join(os.tmpdir(),'tgrep-mcp-fixture-'));
execFileSync('git',['init','--quiet',root],{windowsHide:true});
await writeFile(path.join(root,'B.cs'),'class B {\n  int Needle => 42;\n}\n');
await writeFile(path.join(root,'a.cs'),'// Needle\n');
await writeFile(path.join(root,'ümlaut.cs'),'// Needle\n');
await mkdir(path.join(root,'nested/bin'),{recursive:true});
await writeFile(path.join(root,'nested/bin/ignored.cs'),'// Needle\n');
const search=await createSearch({roots:[root],executable});

test('ordinal path ordering avoids locale collation and expanding case mappings',()=>{
  for(const [a,b] of [['i','ı'],['s','ſ'],['k','K'],['ss','ß'],['z','ä']])assert.ok(comparePaths(a,b)<0);
});

test('literal batches preserve complete counts, scope, sorted sample and current evidence',async()=>{
  const r=await search({patterns:['Needle','class B'],globs:['*.cs'],paths:2,evidence:true,current:true});
  assert.equal(r.isError,false);
  assert.match(r.text, /3 matching files; 2 shown \(sample\)/);
  assert.ok(r.text.indexOf('\na.cs\n')<r.text.indexOf('\nB.cs\n'));
  assert.match(r.text,/2:   int Needle => 42;/);
  assert.doesNotMatch(r.text,/ignored.cs/);
});
test('current evidence sees a saved modification',async()=>{
  await writeFile(path.join(root,'a.cs'),'// Needle updated\n');
  const r=await search({patterns:['Needle'],paths:1,evidence:true,current:true});
  assert.match(r.text,/1: \/\/ Needle updated/);
});
test('unready index is not interpreted as absence',async()=>{
  const r=await search({patterns:['Needle']});
  assert.equal(r.isError,true);assert.match(r.text,/SETUP REQUIRED: no search ran/);
});
test('no-match, literal metacharacters and malformed regex stay distinct',async()=>{
  const absent=await search({patterns:['$(untrusted);['],current:true});
  assert.equal(absent.isError,false);assert.match(absent.text,/0 matching files/);
  const bad=await search({patterns:['['],regex:true,current:true});
  assert.equal(bad.isError,true);assert.match(bad.text,/ERROR exit=2/);
});
test('rejects roots and options outside the configured interface',async()=>{
  await assert.rejects(search({patterns:['Needle'],root:path.dirname(root)}),/configured root/);
  await assert.rejects(search({patterns:['Needle'],flags:['--hidden']}),/Unknown search option/);
  await assert.rejects(search({patterns:['Needle'],paths:1000}),/paths must/);
});
test('long lines do not silently pass the source budget',async()=>{
  await writeFile(path.join(root,'Long.txt'),'Needle '+'.'.repeat(10000));
  const r=await search({patterns:['Needle'],globs:['Long.txt'],evidence:true,current:true});
  assert.match(r.text,/SOURCE BUDGET REACHED/);assert.ok(r.text.length<1000);
});
test('stdio lifecycle, tool schema and tool result work without stdout noise',async()=>{
  const server=fileURLToPath(new URL('../mcp/server.mjs',import.meta.url));
  const child=spawn(process.execPath,[server,'--root',root,'--exe',executable],{windowsHide:true,stdio:['pipe','pipe','pipe']});
  const output=readline.createInterface({input:child.stdout});
  const messages=[];let errors='';child.stderr.on('data',d=>errors+=d);
  for(const m of [
    {id:1,method:'initialize',params:{protocolVersion:'2025-06-18',capabilities:{},clientInfo:{name:'test',version:'1'}}},
    {method:'notifications/initialized'},
    {id:2,method:'tools/list'},
    {id:3,method:'tools/call',params:{name:'tgrep_search',arguments:{patterns:['class B'],current:true}}}
  ])child.stdin.write(JSON.stringify({jsonrpc:'2.0',...m})+'\n');
  child.stdin.end();
  for await(const line of output)messages.push(JSON.parse(line));
  assert.equal(errors,'');assert.equal(messages.length,3);
  assert.equal(messages[0].result.protocolVersion,'2025-06-18');
  assert.equal(messages[1].result.tools.length,1);
  assert.equal(messages[2].result.isError,false);
  assert.match(messages[2].result.content[0].text,/B.cs/);
});
