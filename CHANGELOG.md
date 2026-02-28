# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.2] - 2026-02-28

### Changed
- GitHub Actions workflow: added Docker layer caching (`cache-from/cache-to: type=gha`) to speed up builds on repeated releases
- GitHub Actions workflow: added job summary step — after each release, the Actions UI shows a table with all published tags and their Docker Hub links

## [1.4.1] - 2026-02-28

### Fixed
- Crop filter not applied when `-T` (title) parameter is absent: `process_video_segment()` was falling back to `-c copy` (stream copy) even when a crop filter was built, because the re-encoding branch was gated only on `add_label`/`title_text` checks. Now the decision is based on whether a filter string is actually present, ensuring crop is always applied regardless of other options.

## [1.4.0] - 2026-02-16

### Added
- New crop parameters to remove unwanted borders from videos:
  - `--crop-top N` - Crop N pixels from top
  - `--crop-bottom N` - Crop N pixels from bottom
  - `--crop-left N` - Crop N pixels from left
  - `--crop-right N` - Crop N pixels from right
- `build_crop_filter()` function in core to handle crop filter generation
- Crop filters are applied before text overlays for optimal quality
- Examples in documentation for letterbox and pillarbox removal

### Changed
- Updated `build_ffmpeg_filter()` to accept crop parameters (4 new parameters)
- Enhanced README.md with crop usage examples
- Crop filter concatenation logic to preserve existing filters

### Technical
- FFmpeg crop filter syntax: `crop=in_w-left-right:in_h-top-bottom:left:top`
- Crop is the first filter applied in the chain, followed by drawtext filters
- All crop parameters default to 0 (no cropping)

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

[1.4.2]: https://github.com/kekkooo86/video-splitter/compare/v1.4.1...v1.4.2
[1.4.1]: https://github.com/kekkooo86/video-splitter/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/kekkooo86/video-splitter/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/kekkooo86/video-splitter/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/kekkooo86/video-splitter/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/kekkooo86/video-splitter/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/kekkooo86/video-splitter/releases/tag/v1.0.0

