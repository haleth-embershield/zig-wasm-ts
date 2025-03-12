# Zig + TypeScript + WebAssembly Project Template

A modern project template for building web applications using Zig for backend logic compiled to WebAssembly, with a TypeScript frontend. The template uses a tower defense game as an example implementation.

## Technology Stack

This template demonstrates a lightweight but powerful architecture:

- **Backend**: [Zig](https://ziglang.org/) (v0.14+) compiled to WebAssembly
- **Frontend**: [TypeScript](https://www.typescriptlang.org/) with strict type-checking 
- **Package Manager & Build Tool**: [Bun](https://bun.sh/) for fast dependency management, TypeScript compilation, and development server
- **Development Server**: Bun's built-in server for local development

## Why This Stack?

### Zig + WebAssembly
- **Performance**: Near-native performance for compute-intensive operations
- **Memory Safety**: Zig provides memory safety without garbage collection
- **Small Footprint**: Minimal runtime and small binary sizes
- **WebAssembly**: Runs in all modern browsers without plugins

### TypeScript Frontend
- **Type Safety**: Catch errors at compile time rather than runtime
- **Better IDE Support**: Rich code completion and inline documentation
- **Maintainability**: Types as documentation and easier refactoring
- **Modern JavaScript**: Access to the latest ECMAScript features with backwards compatibility

### Bun
- **All-in-One Tool**: Package manager, bundler, and development server in one
- **Speed**: Extremely fast package installation and builds (up to 30x faster than npm)
- **Simplicity**: Minimal configuration needed
- **Developer Experience**: Quick feedback loop during development
- **TypeScript Support**: Native TypeScript support without additional tools

## Requirements

- [Zig](https://ziglang.org/download/) v0.14.0+
- [Bun](https://bun.sh/docs/installation) v1.0.0+
- Modern web browser with WebAssembly support

## Project Structure

```
project-root/
├── src/                      # Zig source code
│   └── assets/              # Game assets bundled into WASM (sprites, levels, etc)
├── build.zig                 # Zig build system configuration
├── web/                      # Frontend code
│   ├── src/                  # TypeScript source files
│   │   ├── main.ts           # Main entry point
│   │   ├── wasm/             # WASM interaction layer
│   │   ├── game/             # Application-specific logic
│   │   ├── renderer/         # Rendering utilities
│   │   ├── audio/            # Audio system
│   │   └── ui/               # UI components
│   ├── types/                # TypeScript declaration files
│   │   └── wasm.d.ts         # Type definitions for WASM functions
│   ├── styles/               # CSS files
│   ├── public/               # Static web assets (images, fonts, sounds, etc)
│   └── index.html            # Main HTML file
├── dist/                     # Output directory for built files
├── package.json              # Bun dependencies and scripts
└── tsconfig.json             # TypeScript configuration
```

## Getting Started

### Initial Setup

1. Clone this repository:
```bash
git clone https://github.com/yourusername/zig-ts-wasm-template.git
cd zig-ts-wasm-template
```

2. Install dependencies:
```bash
bun install
```

### Development Workflow

#### For TypeScript Frontend Development

```bash
# Start the development server with hot reloading
bun run dev
```

#### For Full-Stack Development (Zig + TypeScript)

```bash
# Build everything and start the server
zig build run
```

This command:
1. Compiles Zig code to WebAssembly
2. Compiles TypeScript to JavaScript
3. Bundles JS files
4. Copies all assets to the dist directory
5. Starts the Bun development server

#### Other Useful Commands

```bash
# Type check TypeScript without emitting files
bun run check

# Lint TypeScript files
bun run lint

# Format TypeScript files
bun run format

# Build without starting the server
zig build deploy
```

## Example Implementation

This template includes a minimal tower defense game implementation:

- Zig backend handles game logic, physics, and state management
- TypeScript frontend provides UI, rendering, and audio
- WebAssembly connects the two, providing type-safe communication

### Game Features

- Four unique geometric towers with different attack patterns
- Wave-based enemy progression
- Grid-based tower placement system
- Visual and audio feedback

## Creating Your Own Project

To use this as a template for your own project:

1. Replace the game-specific logic in `src/` with your own Zig code
2. Update the TypeScript interfaces in `web/types/wasm.d.ts` to match your exports
3. Modify the frontend in `web/src/` to implement your application UI
4. Update this README.md with your project details

## Future Enhancements

### WebGPU Integration
A stretch goal for this template is to incorporate WebGPU for hardware-accelerated graphics:
- Initially using ThreeJS with WebGPU renderer
- Eventually moving to direct Zig WebGPU bindings for maximum performance
- Enabling high-performance 3D graphics and compute capabilities

## Contributing

Contributions to improve this template are welcome! Please feel free to submit issues or pull requests.

## License

MIT
