// Type definitions for tower-def-geometry WASM module

// Interface for all exported functions from the WASM module
export interface WasmModule {
  // Game initialization
  init(width: number, height: number): void;
  resetGame(): void;
  
  // Game update and interaction
  update(deltaTime: number): void;
  handleClick(x: number, y: number): void;
  
  // Tower placement and selection
  selectTowerType(towerType: number): void;
  canPlaceTower(x: number, y: number): boolean;
  getTowerRange(): number;
  
  // Memory management functions (if needed)
  memory: WebAssembly.Memory;
  
  // Add additional exported functions as needed
} 