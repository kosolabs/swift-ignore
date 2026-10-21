# Changelog

## [0.2.0](https://github.com/kosolabs/swift-ignore/compare/v0.1.0...v0.2.0) (2026-10-21)


### ⚠ BREAKING CHANGES

* the module and product are now Ignore. Ignore is now the internal IgnoreStack, Glob is Rule, Match is no longer generic and its cases are unmatched/ignored/included, and isDir: is isDirectory:.

### Features

* add IgnoreTree and rename the API ([#12](https://github.com/kosolabs/swift-ignore/issues/12)) ([c9e3b73](https://github.com/kosolabs/swift-ignore/commit/c9e3b736b827aecc08cbf04651a6ee1a297cae6f))

## 0.1.0 (2026-10-19)


### Features

* add glob matcher ([#6](https://github.com/kosolabs/swift-ignore/issues/6)) ([384892a](https://github.com/kosolabs/swift-ignore/commit/384892a3da60aa1f99e41e94f2e884e5c9af877d))
* implement IgnoreRules ([#8](https://github.com/kosolabs/swift-ignore/issues/8)) ([5f17203](https://github.com/kosolabs/swift-ignore/commit/5f17203ccfb80ae37d6ac7b994da2d1de23ae439))
* implement the Ignore directory stack ([#9](https://github.com/kosolabs/swift-ignore/issues/9)) ([e300c83](https://github.com/kosolabs/swift-ignore/commit/e300c837968d51fada9b579b6fce0f4be6547ed8))
* match entry names in Ignore.matched and trim the public API ([#11](https://github.com/kosolabs/swift-ignore/issues/11)) ([d6088ab](https://github.com/kosolabs/swift-ignore/commit/d6088abdaee9cc72853f4463bb355aa3a0058b6c))
