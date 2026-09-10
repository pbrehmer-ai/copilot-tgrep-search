// Dependency-free MCP stdio adapter. Search only; preparation stays in the installer.
import {execFile} from 'node:child_process';
import {realpath, stat} from 'node:fs/promises';
import path from 'node:path';
import readline from 'node:readline';
import {pathToFileURL} from 'node:url';

export const tool = {
  name: 'tgrep_search',
  description: 'Search configured saved source with tgrep. Batch literal terms. Returns sorted candidate paths; evidence=true also returns CURRENT numbered source excerpts for explanation. Reuse supplied lines; read more only for missing code. No setup or skill-file read needed. Index discovery is eventual; current=true requests a direct scan for decisive current absence/counts.',
  inputSchema: {type:'object',additionalProperties:false,properties:{
    patterns:{type:'array',items:{type:'string'},minItems:1,maxItems:4},
    root:{type:'string',description:'Configured absolute source root. Omit if only one root is configured.'},
    globs:{type:'array',items:{type:'string'},description:'Scope, e.g. ["*.cs"]. bin, obj, .git and .vs are always excluded.'},
    evidence:{type:'boolean',default:false},
    regex:{type:'boolean',default:false},
    current:{type:'boolean',default:false},
    paths:{type:'integer',minimum:0,maximum:10,default:3}
  },required:['patterns']},
  annotations:{readOnlyHint:true,destructiveHint:false,idempotentHint:true,openWorldHint:false}
};

const exclusions=['!**/bin/**','!**/obj/**','!**/.git/**','!**/.vs/**'];
// Ordinal casing does not expand characters or merge dotless-i/long-s with ASCII.
const upper=s=>Array.from(s,c=>c==='\u0131'||c==='\u017f'?c:c.toUpperCase().length===c.length?c.toUpperCase():c).join('');
export const comparePaths=(a,b)=>upper(a)<upper(b)?-1:upper(a)>upper(b)?1:a<b?-1:a>b?1:0;
const samePath=(a,b)=>process.platform==='win32'?a.toLowerCase()===b.toLowerCase():a===b;

export async function createSearch({roots,executable}) {
  const allowed=await Promise.all(roots.map(async root=>{
    const p=await realpath(root);
    if (!(await stat(p)).isDirectory() || p===path.parse(p).root) throw Error('Configure a source directory, not a drive root.');
    return p;
  }));
  if(!allowed.length || !path.isAbsolute(executable))throw Error('An absolute executable and at least one root are required.');
  const ready=new Map();
  const run=(root,args)=>new Promise(resolve=>{
    execFile(executable,args,{cwd:root,windowsHide:true,encoding:'utf8',timeout:30000,maxBuffer:8*1024*1024},(error,stdout,stderr)=>{
      const exit=error?(typeof error.code==='number'?error.code:2):0;
      resolve({exit,stdout,stderr:stderr || (error&&exit===2?error.message:''),ok:exit===0||exit===1});
    });
  });
  return async function search(a) {
    if(!a || typeof a!=='object' || Array.isArray(a))throw Error('Expected search arguments.');
    if(Object.keys(a).some(k=>!Object.hasOwn(tool.inputSchema.properties,k)))throw Error('Unknown search option.');
    if(!Array.isArray(a.patterns)||!a.patterns.length||a.patterns.length>4||a.patterns.some(s=>typeof s!=='string'||!s.length||s.length>512||s.includes('\0')))throw Error('Provide 1–4 nonempty patterns, each at most 512 characters.');
    for(const k of ['evidence','regex','current'])if(a[k]!==undefined&&typeof a[k]!=='boolean')throw Error('Expected boolean: '+k);
    const limit=a.paths??3;
    if(!Number.isInteger(limit)||limit<0||limit>10)throw Error('paths must be 0–10.');
    const globs=a.globs??[];
    if(!Array.isArray(globs)||globs.length>16||globs.some(g=>typeof g!=='string'||!g.length||g.length>256||g.includes('\0')))throw Error('Invalid globs.');
    let root;
    if(a.root!==undefined){
      if(typeof a.root!=='string'||!path.isAbsolute(a.root))throw Error('root must be an absolute configured source root.');
      const requested=await realpath(a.root);
      root=allowed.find(p=>samePath(p,requested));
    }else if(allowed.length===1)root=allowed[0];
    if(!root)throw Error('Select one configured root: '+allowed.join(', '));
    const lines=[];
    if(!a.current && Date.now()-(ready.get(root)||0)>30000){
      const status=await run(root,['status','.']);
      if(!status.ok||!/^Server status for /m.test(status.stdout)||!/^\s*Indexing:\s+complete\s*$/m.test(status.stdout)||!/^\s*Watcher:\s+active\b/m.test(status.stdout)){
        return {text:'SETUP REQUIRED: no search ran. Prepare this root with the existing installer or use a scoped direct/IDE search.\n'+status.stdout+status.stderr,isError:true};
      }
      if(status.stderr)lines.push('WARNING: '+status.stderr.trim());
      ready.set(root,Date.now());
    }
    lines.push(a.current?'Direct saved-file scan.':'Indexed candidate discovery (eventual freshness).');
    let budget=8000,failed=false;
    for(const pattern of a.patterns){
      const args=['-l','--color','never'];
      if(!a.regex)args.push('-F');
      if(a.current)args.push('--no-index');
      for(const g of [...globs,...exclusions])args.push('-g',g);
      const result=await run(root,[...args,'--',pattern,'.']);
      if(!result.ok){failed=true;lines.push(`${JSON.stringify(pattern)} ERROR exit=${result.exit}: ${result.stderr}`);continue;}
      if(result.stderr)lines.push('WARNING: '+result.stderr.trim());
      const paths=[...new Set(result.stdout.split(/\r?\n/).filter(Boolean).map(p=>p.replace(/^\.([\\/])/,'').replaceAll('\\','/')))].sort(comparePaths);
      const selected=paths.slice(0,limit);
      lines.push(`${JSON.stringify(pattern)}: ${paths.length} matching files; ${selected.length} shown${paths.length>limit?' (sample)':''}.`,...selected);
      if(!a.evidence)continue;
      // Only three reads run concurrently; each path is canonicalized before access.
      for(let offset=0;offset<selected.length&&budget>0;offset+=3){
        const excerpts=await Promise.all(selected.slice(offset,offset+3).map(async p=>{
          try{
            const full=await realpath(path.resolve(root,p));
            const rel=path.relative(root,full);
            if(rel==='..'||rel.startsWith('..'+path.sep)||path.isAbsolute(rel))throw Error('Path resolves outside configured root.');
            const args=['--json','--no-index','-m','2','-B','3','-A','16'];
            if(!a.regex)args.push('-F');
            return {p,...await run(root,[...args,'--',pattern,full])};
          }catch(e){return {p,ok:false,exit:2,stderr:e.message};}
        }));
        for(const excerpt of excerpts){
          if(!excerpt.ok){failed=true;lines.push(`EVIDENCE ERROR ${excerpt.p}: ${excerpt.stderr}`);continue;}
          if(excerpt.stderr)lines.push(`WARNING ${excerpt.p}: ${excerpt.stderr.trim()}`);
          lines.push(`CURRENT EXCERPT ${excerpt.p} (up to 2 matches, 3 before/16 after):`);
          let found=false;
          for(const recordLine of excerpt.stdout.split(/\r?\n/).filter(Boolean)){
            const record=JSON.parse(recordLine);
            if(!['match','context'].includes(record.type))continue;
            const text=`${record.data.line_number}: ${record.data.lines.text.replace(/[\r\n]+$/,'')}`;
            if(text.length>budget){lines.push('SOURCE BUDGET REACHED; excerpt incomplete.');budget=0;break;}
            lines.push(text);budget-=text.length;found=true;
          }
          if(!found && budget>0)lines.push('No current match: candidate may have changed.');
        }
      }
      if(budget<=0)lines.push('Further source excerpts omitted.');
    }
    return {text:lines.join('\n'),isError:failed};
  };
}

async function main(){
  const roots=[];let executable;
  for(let i=2;i<process.argv.length;i+=2){
    if(process.argv[i]==='--root')roots.push(process.argv[i+1]);
    else if(process.argv[i]==='--exe')executable=process.argv[i+1];
    else throw Error('Use --root <source-root> (repeatable) and --exe <tgrep>.');
  }
  const search=await createSearch({roots,executable});
  const input=readline.createInterface({input:process.stdin,crlfDelay:Infinity});
  let queue=Promise.resolve();
  for await(const line of input){
    queue=queue.then(async()=>{
      let message;
      try{if(line.length>65536)throw Error('Request too large');message=JSON.parse(line);}
      catch{process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:null,error:{code:-32700,message:'Invalid JSON request'}})+'\n');return;}
      if(message.id===undefined)return;
      const send=result=>process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:message.id,result})+'\n');
      switch(message.method){
        case 'initialize':send({protocolVersion:['2024-11-05','2025-03-26','2025-06-18'].includes(message.params?.protocolVersion)?message.params.protocolVersion:'2025-06-18',capabilities:{tools:{}},serverInfo:{name:'copilot-tgrep-search',version:'0.5.0-pilot'}});break;
        case 'ping':send({});break;
        case 'tools/list':send({tools:[tool]});break;
        case 'tools/call':{
          try{
            if(message.params?.name!==tool.name)throw Error('Unknown tool');
            const r=await search(message.params.arguments);
            send({content:[{type:'text',text:r.text}],isError:r.isError});
          }catch(e){send({content:[{type:'text',text:'Search error: '+e.message}],isError:true});}
          break;
        }
        default:process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:message.id,error:{code:-32601,message:'Method not found'}})+'\n');
      }
    }).catch(e=>process.stderr.write('Request failed: '+e.message+'\n'));
  }
  await queue;
}
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href)main().catch(e=>{process.stderr.write(e.message+'\n');process.exitCode=1;});
