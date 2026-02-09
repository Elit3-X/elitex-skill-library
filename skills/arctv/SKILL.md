---
name: arctv
description: Core guidelines and patterns for ArcTV Player development.
---

# ArcTV Player Project Guidelines

## Core Principles
- **Clean-Room Implementation**: DO NOT COPY GPL CODE. All implementations must be clean-room and conform to permissive or proprietary licensing as required.
- **Premium UI/UX**: Focus on vibrant aesthetics, smooth transitions, and perfect D-pad navigation for TV.
- **Deterministic State**: Use `package:clock` for all time-based logic (trials, activations) to ensure testability.
- **Ralph Wiggum Micro-Loop**: Small change → melos bootstrap → analyze → test → run → fix → commit.

## Technical Patterns
- **Monorepo**: Melos-managed Flutter project.
- **State Management**: Riverpod for DI and reactive state.
- **Persistence**: Drift (SQLite) for all local data.
- **Network**: Dio for API integrations (TMDB, Xtream).

## Platform focus
- **Android TV**: Perfect focus management, Netflix-style keyboard.
- **Android Touch**: Responsive layouts, thumb-friendly navigation.
- **Windows**: Desktop-optimized layouts.

## Monetization / Licensing
- **Device-Locked Activation**: Activation starts on user action (IPTV activation), not app launch.
- **Trial**: 30 days from activation event.
- **Activation ID**: Cryptographic identity generated locally, not based on real MAC addresses.
