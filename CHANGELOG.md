# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-02-16

### Added
- New `-L` parameter to specify custom label text (replaces "Part X" with your custom text)
- Float support for all time-related parameters (`-s`, `-o`, `-S`, `-E`)
- Millisecond precision in time calculations and formatting
- Helper functions for float arithmetic operations (`float_add`, `float_sub`, `float_mul`, `float_div`)
- Helper functions for float comparisons (`float_lt`, `float_gt`, `float_le`, `float_ge`)
- Display of custom label in output information

### Changed
- Updated `format_time()` function to support float values with millisecond precision (HH:MM:SS.mmm format)
- Refactored all arithmetic operations to use `bc` for float calculations
- Updated all time comparisons to support float values
- Enhanced README.md with examples for custom labels and float timing
- Updated help text to indicate float support for time parameters

### Fixed
- Docker output path handling: now correctly saves output next to the video file when running in Docker
- FFmpeg exit code detection: now properly captures ffmpeg status instead of grep status
- Path resolution for both local (using Docker) and Docker container environments

### Technical
- All segment calculations now support decimal values
- Time formatting preserves up to 3 decimal places (milliseconds)
- Backward compatible with integer values
- Uses `awk` and `bc` for float operations
- Uses `${PIPESTATUS[0]}` to capture actual ffmpeg exit status
- Environment detection (`RUNNING_IN_DOCKER`) for correct path handling

## [1.2.0] - 2025-02-15

### Added
- New `-S` parameter to specify start time in seconds (default: 0)
- New `-E` parameter to specify end time in seconds (default: video duration)
- Efficient pre-processing using FFmpeg stream copy for time range trimming
- Automatic cleanup of temporary trimmed files
- Validation for start/end time parameters
- Examples in documentation showing time range usage

### Changed
- Updated Dockerfile version to 1.2.0
- Enhanced README.md with time range examples
- Updated DOCKER_DESCRIPTION.md with new parameters
- Updated help text in both local and Docker scripts

### Technical
- Implemented pre-processing strategy (Option 1) for maximum efficiency
- Uses `-c copy` for fast video trimming without re-encoding
- No changes to core segmentation logic
- Maintains backward compatibility

## [1.1.0] - 2025-02-14

### Added
- Docker support with multi-stage builds
- GitHub Actions workflow for automated Docker Hub publishing
- Professional documentation structure
- MIT License

### Changed
- Cleaned up project structure
- Removed TikTok-specific references
- Focused on generic video splitting functionality

### Fixed
- Font configuration warnings in Docker
- Path handling in Docker environment

## [1.0.0] - 2025-02-13

### Added
- Initial release
- Video splitting with customizable segment duration
- Automatic "Part X" labels
- Centered intro titles with fade effect
- Auto-detect aspect ratio (9:16, 16:9, 1:1)
- Parallel processing support
- Test mode for first segment
- Interactive and CLI modes
- Docker support

[1.2.0]: https://github.com/kekkooo86/video-splitter/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/kekkooo86/video-splitter/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/kekkooo86/video-splitter/releases/tag/v1.0.0

