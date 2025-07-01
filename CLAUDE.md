# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift iOS bookshelf application built with SwiftUI and The Composable Architecture (TCA). The app allows users to manage their book collection with features like scanning, tagging, and statistics.

## Architecture

The project follows a modular architecture with four main Swift packages:

### Core Package (`Core/`)
- **Models**: BookModel, GenreModel, RemindModel, SyncModel - Domain entities
- **Clients**: Abstract interfaces for external services (BookClient, SearchClient, etc.)
- **Features**: TCA reducers and business logic (BookCore, SettingsCore, StatisticsCore)
- Uses The Composable Architecture as the primary state management framework

### Infrastructure Package (`Infrastructure/`)  
- **Live Implementations**: Concrete implementations of Core clients (BookClientLive, SearchClientLive, etc.)
- **Data Layer**: Core Data models (BookRecord, TagRecord) and persistence logic
- **External Services**: Firebase integration for analytics, remote config, and push notifications

### Presentation Package (`Presentation/`)
- **SwiftUI Views**: All UI components and screens
- **Hot Reloading**: Supports live code injection for development via Inject framework
- **Dependencies**: Uses Nuke for image loading, Pulse for network debugging

### Common Package (`Common/`)
- **Scanner**: Camera-based book scanning functionality
- **Updater**: Widget update utilities

## Development Commands

### Setup
```bash
make bootstrap  # Install dependencies and generate code
```

### Testing
```bash
make unit-test  # Run unit tests on iOS Simulator
```

### Code Generation
```bash
make generate   # Generate code and license files
```

### Build
```bash
# Build for iOS Simulator
make create-simulator-app
```

The project uses Xcode workspaces with separate configurations for Development and Production environments.

## Key Development Guidelines

1. Use The Composable Architecture for all state management
2. Always use NavigationStack instead of NavigationView in SwiftUI
3. Implement async/await for asynchronous operations
4. Prioritize performance optimization to avoid unnecessary view recomputation

## Code Generation

The project uses Sourcery for code generation, particularly for API client implementations that require environment-specific configuration (Rakuten API credentials). Generated files are located in `Infrastructure/Sources/*/Generated/` directories.

## Testing Strategy

Unit tests are located in `Core/Tests/` and focus on testing TCA reducers and business logic. Tests run on iOS Simulator with code coverage enabled.