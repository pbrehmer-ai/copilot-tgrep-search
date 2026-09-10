"""Exercise the optional installer in an isolated child-process user profile."""
import json, os, shutil, subprocess, tempfile, unittest
from pathlib import Path


class McpInstallTests(unittest.TestCase):
    def test_preview_install_update_and_collision_preserve_unrelated_config(self):
        pwsh = shutil.which('pwsh')
        node = shutil.which('node')
        tgrep = Path(os.environ.get('LOCALAPPDATA', '')) / 'Programs/copilot-tgrep/1.0.5/tgrep.exe'
        if not pwsh or not node or not tgrep.exists():
            self.skipTest('Requires approved pwsh, Node.js 22+ and tgrep 1.0.5')
        fixture = Path(tempfile.mkdtemp(prefix='copilot-mcp-install-'))
        profile = fixture / 'profile'
        profile.mkdir()
        source = fixture / 'source'
        source.mkdir()
        config = profile / '.mcp.json'
        original = {'servers': {'unrelated': {'url': 'https://example.invalid/mcp'}}, 'preserve': True}
        config.write_text(json.dumps(original))
        env = dict(os.environ, USERPROFILE=str(profile), LOCALAPPDATA=str(fixture / 'local'))
        env['PATH'] = str(tgrep.parent) + os.pathsep + env['PATH']
        installer = Path(__file__).resolve().parents[1] / 'scripts/Install-Mcp.ps1'
        command = [pwsh, '-NoLogo', '-NoProfile', '-File', str(installer), '-RepositoryRoot', str(source), '-NodePath', node, '-IncludeInvestigator']
        def run(*args):
            return subprocess.run(command + list(args), env=env, capture_output=True, text=True, timeout=30)
        before = config.read_bytes()
        preview = run('-WhatIf')
        self.assertEqual(preview.returncode, 0, preview.stderr)
        self.assertEqual(config.read_bytes(), before)
        self.assertFalse((fixture / 'local').exists())
        first = run()
        self.assertEqual(first.returncode, 0, first.stderr)
        installed = json.loads(config.read_text())
        self.assertTrue(installed['preserve'])
        self.assertEqual(installed['servers']['unrelated'], original['servers']['unrelated'])
        server = Path(installed['servers']['tgrep']['args'][0])
        self.assertTrue(server.exists())
        self.assertTrue((profile / '.github/agents/tgrep-investigator.agent.md').exists())
        second = run()
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(json.loads(config.read_text()), installed)
        installed['servers']['tgrep']['args'][0] = 'unrelated-server.mjs'
        config.write_text(json.dumps(installed))
        collision_bytes = config.read_bytes()
        collision = run()
        self.assertNotEqual(collision.returncode, 0)
        self.assertEqual(config.read_bytes(), collision_bytes)


if __name__ == '__main__':
    unittest.main()
