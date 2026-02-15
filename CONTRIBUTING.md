# Contributing to Video Splitter

Thank you for your interest in contributing! 🎉

## 📋 How to Contribute

### Reporting Issues

1. Check if the issue already exists
2. Provide a clear description
3. Include steps to reproduce
4. Share your environment (OS, Docker version, etc.)

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 🧪 Testing

Before submitting:

1. **Test locally:**
   ```bash
   ./split_video.sh -i test.mp4 -T "Test" --test-first
   ```

2. **Test with Docker:**
   ```bash
   docker build -t video-splitter:test .
   docker run -v $(pwd):/videos video-splitter:test -i test.mp4 --test-first
   ```

3. **Check all video segments** to ensure titles appear correctly

## 🏗️ Architecture

The project uses a modular architecture:

- `split_video_core.sh` - Pure functions (no execution logic)
- `split_video.sh` - Local wrapper (uses Docker for ffmpeg)
- `split_video_docker.sh` - Docker wrapper (uses native ffmpeg)

This design eliminates code duplication and makes maintenance easier.

## 📝 Code Style

- Use clear variable names
- Add comments for complex logic
- Follow existing code patterns
- Keep functions focused and reusable

## 🐛 Known Issues

Check the [Issues](https://github.com/kekkooo86/video-splitter/issues) page for known problems and feature requests.

## 💡 Feature Ideas

Have an idea? Open an issue with the `enhancement` label!

Some ideas we're considering:
- Web UI for video splitting
- Batch processing multiple videos
- Custom font selection
- Audio normalization
- Video quality presets
- Multiple output formats
- Custom watermarks
- Transition effects between segments

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You!

Every contribution, no matter how small, is appreciated! ❤️

