import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const read = path => readFileSync(new URL(`../../../${path}`, import.meta.url), 'utf8');
test('CLI owns the complete profile bootstrap even with the historical wrapper gitlink', () => {
  const config = JSON.parse(read('.github/matlab-ci.json'));
  for (const prefix of ['', 'legacy_']) {
    const text = read(config[`${prefix}fixture_path`]).replaceAll('\r\n', '\n');
    assert.equal(createHash('sha256').update(text).digest('hex'), config[`${prefix}fixture_sha256`]);
  }
  for (const helper of ['runMandatoryConformance', 'getConformanceProfile', 'classifyConformanceApi']) {
    assert.match(read(`ci/${helper}Cli.m`), new RegExp(`${helper}Cli\\(`));
  }
  const entry = read('conformance/runCliConformance.m');
  assert.match(entry, /fullfile\(root, 'ci'\)/);
  assert.match(entry, /runMandatoryConformanceCli\(@wss_cli.createController, csLibDir\)/);
  assert.match(read('ci/runCliCi.m'), /runMandatoryConformanceCli\(@wss_cli.createController/);
  const dispatcher = read('ci/runMandatoryConformanceCli.m');
  assert.match(dispatcher, /getConformanceProfileCli\(payload\)/);
  assert.match(dispatcher, /Canonical fixture hash mismatch/);
  assert.match(dispatcher, /checkCases\(multi,/);
});