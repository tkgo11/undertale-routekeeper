#!/usr/bin/env python3
"""Exact installed-game preparation. No Steam/game launch, save access or upload."""
import argparse
import json
import os
import stat
import uuid
from pathlib import Path
import sys

import runtime_lab as lab
import screen_verify as s
import windows_e2e as e


def prepare(source, output, compiler, builder):
    source=s.no_links(source);output=s.no_links(output);compiler=s.no_links(compiler);builder=s.no_links(builder)
    expected=e.profile();pins=e.source_pins()
    tool_pins={p:s.hash_file(p,256*1024*1024) for p in (compiler,builder)}
    if any(not p.is_file() for p in tool_pins):raise ValueError('Compiler and builder must be regular files')
    lab.prepare_installed(source,output)
    command=[str(builder)] if builder.suffix.lower()=='.exe' else ['dotnet',str(builder)]
    candidate=output/'candidate.win'
    e.bounded_command([*command,'build',str(output/'original/Undertale/data.win'),str(candidate),str(compiler),str(e.ROOT)],output/'build-private.log')
    candidate=s.no_links(candidate)
    size=candidate.stat().st_size
    if size>256*1024*1024 or s.hash_file(candidate,256*1024*1024)!=expected['PatchedSha256']:raise e.StopRun('Candidate identity differs from the inspected profile')
    # Revalidate pristine copies before replacing only the owned patched data.
    identity=lab.verify(output)
    files=[dict(f,path=f['path'][10:]) for f in identity['files']]
    lab.verify_original_tree(output/'runs/patched',files)
    target=s.no_links(output/'runs/patched/data.win')
    if target.stat().st_nlink!=1:raise ValueError('Hardlinked patched target refused')
    temporary=s.no_links(target.with_name('.candidate-'+uuid.uuid4().hex))
    lab.copy_exact_file(candidate,temporary,size,expected['PatchedSha256'])
    target=s.no_links(target)
    if target.stat().st_nlink!=1 or not stat.S_ISREG(target.stat().st_mode):raise ValueError('Changed patched target refused')
    os.replace(temporary,target)
    for case in ('original','patched'):e.verify_copy(output,case)
    lab.verify(output);e.check_pins(pins)
    lab.verify_original_tree(source,files)
    if any(s.hash_file(p,256*1024*1024)!=digest for p,digest in tool_pins.items()):raise ValueError('Compiler/builder changed during preparation')
    record=dict(schema=1,profile=expected['Id'],status=expected['Status'],harness=pins,
                repositoryHead=e.repository_head(),originalSha256=lab.DATA_SHA,candidateSha256=expected['PatchedSha256'],runnerSha256=lab.RUNNER_SHA,
                inputKind='READ_ONLY_INSTALLED_COPY',preparationTools=dict(compilerSha256=tool_pins[compiler],builderSha256=tool_pins[builder]),runtime='NOT_RUN')
    raw=s.canonical(record);s.put(output/'prepared.json',raw);s.put(output/'prepared.sha256',(s.digest(raw)+'\n').encode())
    return record


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source',type=Path,required=True);parser.add_argument('--work',type=Path,required=True)
    parser.add_argument('--compiler',type=Path,required=True);parser.add_argument('--builder',type=Path,required=True)
    args=parser.parse_args()
    try:
        prepare(args.source,args.work,args.compiler,args.builder)
        print(json.dumps(dict(result='PREPARED_INSPECTED_COPY',gameplay='NOT_RUN',originalInstallation='UNCHANGED')))
        return 0
    except (OSError,ValueError,KeyError,TypeError) as error:
        print(json.dumps(dict(result='BLOCKED',reason=str(error))),file=sys.stderr);return 2


if __name__=='__main__':raise SystemExit(main())
