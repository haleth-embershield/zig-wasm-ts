// TypeScript implementation of the WASM loader
import type { WasmModule } from "../../types/wasm.d.ts";

// Define logger type for compatibility
interface Logger {
  log(message: string): void;
  error(message: string): void;
  warn(message: string): void;
}

export class WasmLoader {
  private wasmModule: WasmModule | null = null;
  private logger: Logger;
  private gameApp: any; // Reference to the main game application

  constructor(gameApp: any, logger?: Logger) {
    this.gameApp = gameApp;
    this.logger = logger || console;
  }

  /**
   * Check if the WASM module has been loaded
   * @returns True if the WASM module is loaded, false otherwise
   */
  isLoaded(): boolean {
    return this.wasmModule !== null;
  }

  /**
   * Load and instantiate the WebAssembly module
   * @returns Promise resolving to the initialized WASM module
   */
  async loadWasm(): Promise<WasmModule> {
    if (this.wasmModule) return this.wasmModule;
    
    try {
      this.logger.log("Loading WASM module...");
      
      // Define JavaScript functions that will be called from Zig
      const importObject = {
        env: {
          // Example of a logging function that can be called from Zig
          consoleLog: (ptr: number, len: number) => {
            // Implementation would depend on how strings are passed from Zig
            // This is a placeholder
            this.logger.log(`[WASM] Log message from ptr ${ptr}, len: ${len}`);
          },
          // Audio functions called from Zig
          playLevelCompleteSound: () => {
            this.logger.log("Playing level complete sound");
            this.gameApp.audio.playSound('levelComplete');
          },
          playLevelFailSound: () => {
            this.logger.log("Playing level fail sound");
            this.gameApp.audio.playSound('levelFail');
          },
          playTowerShootSound: () => {
            this.logger.log("Playing tower shoot sound");
            this.gameApp.audio.playSound('towerShoot');
          },
          playEnemyExplosionSound: () => {
            this.logger.log("Playing enemy explosion sound");
            this.gameApp.audio.playSound('enemyExplosion');
          },
          playEnemyHitSound: () => {
            this.logger.log("Playing enemy hit sound");
            this.gameApp.audio.playSound('enemyHit');
          },
          // Canvas rendering functions
          clearCanvas: () => {
            const ctx = this.gameApp.canvas.getContext();
            const { width, height } = this.gameApp.canvas.getDimensions();
            if (ctx) {
              ctx.clearRect(0, 0, width, height);
            }
          },
          drawRect: (x: number, y: number, width: number, height: number, r: number, g: number, b: number) => {
            const ctx = this.gameApp.canvas.getContext();
            if (ctx) {
              ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
              ctx.fillRect(x, y, width, height);
            }
          },
          drawCircle: (x: number, y: number, radius: number, r: number, g: number, b: number, fill: boolean) => {
            const ctx = this.gameApp.canvas.getContext();
            if (ctx) {
              ctx.beginPath();
              ctx.arc(x, y, radius, 0, Math.PI * 2);
              if (fill) {
                ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
                ctx.fill();
              } else {
                ctx.strokeStyle = `rgb(${r}, ${g}, ${b})`;
                ctx.stroke();
              }
            }
          },
          drawLine: (x1: number, y1: number, x2: number, y2: number, thickness: number, r: number, g: number, b: number) => {
            const ctx = this.gameApp.canvas.getContext();
            if (ctx) {
              ctx.beginPath();
              ctx.moveTo(x1, y1);
              ctx.lineTo(x2, y2);
              ctx.strokeStyle = `rgb(${r}, ${g}, ${b})`;
              ctx.lineWidth = thickness;
              ctx.stroke();
            }
          },
          drawTriangle: (x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, r: number, g: number, b: number, fill: boolean) => {
            const ctx = this.gameApp.canvas.getContext();
            if (ctx) {
              ctx.beginPath();
              ctx.moveTo(x1, y1);
              ctx.lineTo(x2, y2);
              ctx.lineTo(x3, y3);
              ctx.closePath();
              if (fill) {
                ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
                ctx.fill();
              } else {
                ctx.strokeStyle = `rgb(${r}, ${g}, ${b})`;
                ctx.stroke();
              }
            }
          },
          drawText: (x: number, y: number, text_ptr: number, text_len: number, size: number, r: number, g: number, b: number) => {
            const ctx = this.gameApp.canvas.getContext();
            if (!ctx) return;
            
            try {
              // We need to wait until the WASM module is instantiated to access memory
              if (!this.wasmModule || !this.wasmModule.memory) {
                // Draw a placeholder rectangle until WASM is fully loaded
                ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
                ctx.fillRect(x, y - size, size * 5, size);
                return;
              }
              
              // Create a view into the WebAssembly memory
              const memoryView = new Uint8Array(this.wasmModule.memory.buffer);
              
              // Extract the text from memory
              const textBytes = memoryView.slice(text_ptr, text_ptr + text_len);
              const text = new TextDecoder().decode(textBytes);
              
              // Draw the text
              ctx.font = `${size}px sans-serif`;
              ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
              ctx.fillText(text, x, y);
            } catch (error) {
              this.logger.error(`Error drawing text: ${error}`);
              
              // Fallback to drawing a placeholder rectangle
              ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
              ctx.fillRect(x, y - size, size * 5, size);
            }
          }
        }
      };
      
      // Fetch and instantiate the WASM module
      const response = await fetch('towerd.wasm');
      const bytes = await response.arrayBuffer();
      const { instance } = await WebAssembly.instantiate(bytes, importObject);
      
      // Cast the exports to our WasmModule interface
      this.wasmModule = instance.exports as unknown as WasmModule;
      
      // Verify that memory is accessible
      if (!this.wasmModule.memory) {
        this.logger.warn("WebAssembly memory not exported. Text rendering may not work correctly.");
      } else {
        this.logger.log("WebAssembly memory initialized successfully");
      }
      
      this.logger.log("WASM module loaded successfully");
      return this.wasmModule;
    } catch (error) {
      this.logger.error(`Failed to load WASM module: ${error}`);
      throw error;
    }
  }

  /**
   * Initialize the WASM module with the canvas dimensions
   * @param width Canvas width
   * @param height Canvas height
   */
  async initializeGame(width: number, height: number): Promise<void> {
    const wasm = await this.loadWasm();
    wasm.init(width, height);
    this.logger.log(`Game initialized with canvas size: ${width}x${height}`);
  }

  /**
   * Reset the game state
   */
  async resetGame(): Promise<void> {
    const wasm = await this.loadWasm();
    wasm.resetGame();
    this.logger.log("Game reset");
  }

  /**
   * Update the game state
   * @param deltaTime Time elapsed since the last frame in seconds
   */
  async updateGame(deltaTime: number): Promise<void> {
    const wasm = await this.loadWasm();
    wasm.update(deltaTime);
  }

  /**
   * Handle mouse click at the specified coordinates
   * @param x X coordinate
   * @param y Y coordinate
   */
  async handleClick(x: number, y: number): Promise<void> {
    const wasm = await this.loadWasm();
    wasm.handleClick(x, y);
  }

  /**
   * Select tower type to be placed
   * @param towerType Tower type identifier
   */
  async selectTowerType(towerType: number): Promise<void> {
    const wasm = await this.loadWasm();
    wasm.selectTowerType(towerType);
  }

  /**
   * Check if a tower can be placed at the specified coordinates
   * @param x X coordinate
   * @param y Y coordinate
   * @returns True if a tower can be placed, false otherwise
   */
  async canPlaceTower(x: number, y: number): Promise<boolean> {
    const wasm = await this.loadWasm();
    return wasm.canPlaceTower(x, y);
  }

  /**
   * Get the range of the currently selected tower type
   * @returns The tower range value
   */
  async getTowerRange(): Promise<number> {
    const wasm = await this.loadWasm();
    return wasm.getTowerRange();
  }
} 