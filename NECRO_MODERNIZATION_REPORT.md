# ChildProcess Modernization Report

This branch modernizes `childprocess` for Ruby 4.0.6 (and current maintained
Rubies generally). The gem's core design was already in good shape -- v5.0
(2024) had already replaced the old `ffi`/`posix_spawn` backends with a
single `Process.spawn`-based implementation, so there was no C-extension or
platform-fork logic to port. The work here is concentrated on dependency
health, test rigor, lint/documentation hygiene, and CI.

## TL;DR

- `bundle install` was **broken on a fresh checkout** before this branch
  (the `coveralls` dev dependency doesn't resolve). Fixed by replacing it
  with `simplecov`.
- Test coverage: **86.9% → 100%** (line coverage), with a real bug found
  and fixed along the way (see below).
- `required_ruby_version` raised from `>= 2.4.0` to `>= 3.2`; `.ruby-version`
  pinned to `4.0.6`; CI matrix now covers Ruby 3.2, 3.3, 3.4, 4.0, `head`,
  JRuby and TruffleRuby.
- RuboCop (+ `rubocop-performance`, `rubocop-rspec`) added, whole codebase
  passes with zero offenses.
- `bundler-audit` added as a CI job; zero vulnerabilities found in the
  current dependency set.
- 100% YARD documentation coverage on the public API.
- No application code needed changes to run on Ruby 4.0.6 -- the suite
  passed cleanly (with `-w`, no deprecation warnings) as soon as the
  dependency chain was fixed.

## Dependency changes

| Gem | Before | After | Why |
|---|---|---|---|
| `coveralls` | `< 1.0` (dev) | *removed* | Effectively dead upstream -- pulls in an unresolvable dependency chain on current RubyGems/Bundler, so `bundle install` failed outright on a clean checkout. |
| `simplecov` | -- | `~> 0.22` (dev, new) | Modern, actively maintained coverage tool; drop-in replacement for the local-report half of what Coveralls did (Coveralls' value-add was hosted reporting, which isn't configured for this repo anyway). |
| `rspec` | `~> 3.0` (dev) | `~> 3.13` (dev) | Current stable line; no spec-level API changes required beyond one pre-existing bug (see below). |
| `yard` | `~> 0.0` (dev) | `~> 0.9` (dev) | The `~> 0.0` constraint was effectively unconstrained/stale; pinned to the current stable line. |
| `rake` | unpinned, only in `Gemfile` | `~> 13.0` (dev, gemspec) | Declared as a real dev dependency instead of a bare `gem 'rake'` in the Gemfile, so `gem build`/CI get a consistent, pinned version. |
| `rubocop` | -- | `~> 1.88` (dev, new) | Linting, requested by the modernization brief. |
| `rubocop-performance` | -- | `~> 1.26` (dev, new) | Companion perf cops. |
| `rubocop-rspec` | -- | `~> 3.10` (dev, new) | Companion RSpec cops. |
| `bundler-audit` | -- | `~> 0.9` (dev, new) | Dependency vulnerability scanning, wired into CI. |
| `logger` | `~> 1.5` (runtime) | `~> 1.5` (runtime, unchanged) | Already added in a prior PR (#199) to silence the Ruby 3.4 "logger is no longer a default gem" warning; still correct and needed on 4.0.6. |

The `Gemfile`'s Ruby-2.4-only `term-ansicolor` pin (a transitive workaround
for old Coveralls versions) was removed along with `coveralls` itself --
it's dead weight now that the floor is Ruby 3.2.

No runtime dependency other than `logger` exists; the gem's only
non-stdlib runtime footprint remains minimal by design.

## Security

- `bundle exec bundler-audit check --update` reports **no vulnerabilities**
  against the current `ruby-advisory-db` for the resolved dependency set.
  Added as a dedicated `audit` job in CI so this is checked on every push.
- The only thing resembling a "finding" was the broken `coveralls`
  dependency chain itself (a supply-chain health issue more than a CVE):
  a dev dependency that can no longer be installed is a liability for
  contributors and CI alike. Resolved by removing it (see Dependency
  changes above).
- `Security/Eval` (RuboCop) flags several `eval(...)` calls in
  `spec/childprocess_spec.rb`. These deserialize `Hash#inspect`/
  `Array#inspect` output that a child process -- spawned by the very same
  spec, from a tempfile the spec itself wrote -- reports its `ENV`/`ARGV`
  as. It's not attacker-controlled input, so the cop is excluded for that
  one file with a comment explaining why, rather than papering over it or
  rewriting a working test technique for cosmetic reasons.

## Compatibility fixes for Ruby 4.0.6

Short version: **none were needed in the library code.** The full suite
ran clean on 4.0.6, including under `-w` (no deprecation warnings), as
soon as `bundle install` could complete (i.e. once `coveralls` was
replaced). This is because:

- The gem already dropped its `ffi`-based Windows backend and the
  `posix_spawn`-via-C-extension path in v5.0, in favor of a pure
  `Process.spawn`/`Process.waitpid2`/`Process.kill` implementation. There
  was no native extension or removed-stdlib surface to port.
  `ChildProcess.posix_spawn=`/`.posix_spawn?` remain as inert, backward
  -compatible no-op API surface (some consumers, e.g. via the README's
  JRuby caveat, still call `ChildProcess.posix_spawn = true`).
- `logger` was already added as an explicit runtime dependency in a
  prior PR for the Ruby 3.4 "moved to a default gem" change, and
  `ostruct` was already removed. Both remain correct for 4.0.6.

Declared explicitly for 4.0.6:

- `.ruby-version` added, pinned to `4.0.6`.
- `childprocess.gemspec`: `required_ruby_version` raised from `>= 2.4.0`
  to `>= 3.2` -- a floor the gem's dev tooling (`simplecov` 1.x,
  `rubocop-rspec` 3.x) already assumes, and consistent with actually
  testing/supporting only non-EOL-or-recent Rubies going forward.
- CI matrix (`.github/workflows/ci.yml`): dropped Ruby 2.4-3.1 (now below
  the floor / EOL), added `4.0`, kept `3.2`/`3.3`/`3.4`/`head`/`jruby`/
  `truffleruby`. Also bumped `actions/checkout` to `v4` (v2 is EOL) and
  added two new jobs, `lint` (RuboCop) and `audit` (bundler-audit).

## Test coverage: 86.9% → 100%

The very first successful coverage run (once `simplecov` replaced the
broken `coveralls`) measured **86.92%** line coverage (226/260). Getting
to 100% (280/280 -- the line count grew as documentation and small
refactors were added) involved:

- New spec files: `spec/abstract_process_spec.rb`,
  `spec/process_spawn_process_spec.rb`, and a substantial expansion of
  `spec/windows_spec.rb` (previously entirely skipped outside of Windows
  CI runners -- it's now exercised on every platform, since
  `Windows::Process`/`Windows::IO` are plain Ruby with `::Process.spawn`
  stubbed out, not OS-specific code).
- Expanded `spec/childprocess_spec.rb` to cover `.platform`,
  `.platform_name`, `.linux?`, `.jruby?`, `.unix?`/`.windows?`, the
  `posix_spawn*` family, `.close_on_exec`'s error path, `.new`/`.build`'s
  per-OS dispatch and its unsupported-platform error, and every branch of
  `.os`'s host-OS detection (macOS, Windows, Cygwin, Solaris, AIX, and the
  "unknown OS" error).
- Removed one genuinely dead method, `ChildProcess.warn_once` (private,
  never called anywhere in the codebase) rather than writing a test to
  cover unreachable code.
- One line -- the top-level `if ChildProcess.windows? / else` require
  dispatch in `lib/childprocess.rb` -- is marked with SimpleCov's
  `# :nocov:`. Exactly one branch of that dispatch can ever run in a given
  OS/process, symmetrically on every CI platform (on Windows CI, the
  `unix` branch would be the "uncovered" one instead), so no single test
  run can ever exercise both sides of it. This is the one deliberate,
  documented coverage exclusion in the suite.

### A real bug caught along the way

`spec/platform_detection_spec.rb`'s `expected_arch_for_host_cpu` shared
example had a pre-existing bug: it stubbed `RbConfig::CONFIG['host_cpu']`
to return `expected_arch` instead of the actual `host_cpu` parameter. For
the macOS/i686-64-bit-workaround test in particular, this meant the stub
fed back `"x86_64"` as the *host_cpu* value, which matches a *different*
`case/when` branch than the one the test was supposedly exercising -- so
the test passed, but never actually ran the code path
(`workaround_older_macosx_misreported_cpu?`) it claimed to. Fixed by
stubbing the correct value; this is what let `lib/childprocess.rb`'s
64-bit-Darwin-misreported-as-i686 workaround get real coverage instead of
a false-positive pass.

### A self-caught regression

While bringing the codebase up to RuboCop's default style (`rubocop -A`),
one autocorrect changed `pid = nil if pid == 0` to `pid = nil if
pid.zero?` in `ProcessSpawnProcess#exited?`. `Process.waitpid2(..., 
Process::WNOHANG)` returns bare `nil` (not `[nil, nil]`) while the child
is still running, which is the common case for `#exited?`/`#alive?` on a
live process -- so `pid.zero?` crashed with `NoMethodError` on every call
made while a process was still alive. The full test suite (116 examples)
still passed after that autocorrect, only because the run confirming
100% coverage predated it. Re-running the suite after the RuboCop pass
caught this immediately. Fixed with `pid&.zero?`, which is both
crash-safe and satisfies the same style cop.

This wasn't shipped -- it's called out here as a concrete illustration of
why "lint autocorrect + rerun the full suite before considering it done"
matters, not as an outstanding issue.

## Lint (RuboCop)

- `.rubocop.yml` added: `rubocop-performance` + `rubocop-rspec` plugins,
  `NewCops: enable`, `TargetRubyVersion: 3.2`.
- The codebase (11 lib files + 12 spec files) now passes with **zero
  offenses**. Most of the ~580 initial offenses were mechanical (string
  quoting, `frozen_string_literal`, hash syntax, redundant `self`,
  guard clauses, etc.) and safely autocorrected (after the regression
  above was caught and fixed by hand).
- `lib/childprocess/process_spawn_process.rb#launch_process` was
  genuinely too complex (flagged by four separate RuboCop metrics --
  ABC size, cyclomatic complexity, perceived complexity, method length).
  Refactored into `#launch_process` (orchestration),
  `#base_spawn_options`, `#sanitized_environment`, and `#spawn_args`,
  each with a single, documented responsibility. Behavior is unchanged
  (verified by the full suite before/after).
- A handful of cops are deliberately tuned down or excluded, each with an
  inline rationale comment in `.rubocop.yml` or the source: dev
  dependencies staying in the gemspec rather than moving to the Gemfile;
  `has_fileno?`/`has_to_io?`/`set_exit_code` keeping their existing,
  clearer names over the cops' preferred alternatives; `before(:all)`/
  `RSpec/InstanceVariable` for the one spec that deliberately saves/
  restores global `RbConfig` state once per describe block; the
  already-discussed `Security/Eval` exclusion; and the spec file naming
  convention (`childprocess_spec.rb`, matching the gem/module name)
  over the cop's ActiveSupport-style `child_process_spec.rb` inflection.

## Documentation

- 100% YARD documentation coverage (`bundle exec yard stats`): all 3
  modules, 12 classes, 2 constants, 12 attributes, and 31 methods across
  the library now have doc comments, including `@param`/`@return`/
  `@raise` tags where relevant and a top-level usage example on the
  `ChildProcess` module itself.
- This also fixed a latent documentation bug: `ChildProcess.posix_spawn=`
  had a doc comment ("Set this to true to enable experimental use of
  posix_spawn.") that, after an earlier RuboCop autocorrect merged it
  into an `attr_writer` declaration, ended up floating above the
  unrelated `#os` method instead. Re-attached to the right place.

## README

- Requirements section updated to the new floor (Ruby 3.2+) and the
  actual CI matrix.
- Removed the Coveralls badge (no longer accurate -- nothing reports to
  it anymore) and added a short note on how coverage is measured now.
- Added a "Development" section with the day-to-day commands
  (`rake spec`, `rubocop`, `yard doc`, `bundler-audit`).
- "Note on Patches/Pull Requests" and "Publishing a New Release" referred
  to a `dev` branch and Travis CI links that no longer exist for this
  repo (it's `master`-only with GitHub Actions); updated to match reality.

## Everything else

- `.gitignore`: `.ruby-version` was previously ignored, which would have
  silently dropped the new pin from any commit; removed that line. Added
  `.yardoc`/`doc` (generated YARD artifacts).
- `gem build childprocess.gemspec` succeeds and `gemspec.validate` emits
  no warnings (covered by the existing "validates cleanly" spec, now
  using `Gem::Specification.load` instead of a hand-rolled `eval` of the
  gemspec file).

## Not done / out of scope

Nothing was blocking. The one thing intentionally left as-is: the
`Code Climate` badge in the README wasn't touched, since it's unrelated
to any dependency/tooling change made here and its status is unknown/
unverifiable from this environment (no credentials to check it).
