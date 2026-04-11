# Version History

## [1.2.0] - 2026-04-10
- added scoped annotation-sidecar loading support for documentation builders so generated class reference pages keep markdown sidecars without incurring annotation sidecar lookup overhead in ordinary runtime code

## [1.1.1] - 2026-03-22
- Preserved existing tutorial image files when regenerated figures are pixel-identical, reducing unnecessary PNG churn in downstream repos

## [1.1.0] - 2026-03-21
- Added `TutorialDocumentation` and `TutorialBuildRuntime` for generating tutorial pages and figures from runnable MATLAB scripts

## [1.0.1] - 2026-01-01
- De-denting docs to fix markdown parsing
