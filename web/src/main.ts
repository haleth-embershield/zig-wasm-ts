// Main TypeScript entry point for the game's frontend

import { AudioManager } from './audio/audio-manager';
import { WasmLoader } from './wasm/wasm-loader';
import { UIManager } from './ui/ui-manager';
import { CanvasManager } from './renderer/canvas-manager';

// Logger implementation
class Logger {
  private logContainer: HTMLElement | null = null;

  constructor() {
    // Wait for DOM to load
    window.addEventListener('DOMContentLoaded', () => {
      this.logContainer = document.getElementById('log-container');
    });
  }

  log(message: string): void {
    console.log(message);
    this.appendToLogContainer(message);
  }

  error(message: string): void {
    console.error(message);
    this.appendToLogContainer(`ERROR: ${message}`, 'error');
  }

  warn(message: string): void {
    console.warn(message);
    this.appendToLogContainer(`WARNING: ${message}`, 'warning');
  }

  private appendToLogContainer(message: string, type: 'log' | 'error' | 'warning' = 'log'): void {
    if (!this.logContainer) return;

    const entry = document.createElement('div');
    entry.className = `log-entry log-${type}`;
    entry.textContent = message;
    this.logContainer.appendChild(entry);
    
    // Auto-scroll to bottom
    this.logContainer.scrollTop = this.logContainer.scrollHeight;
    
    // Limit number of entries (like in the original)
    while (this.logContainer.children.length > 100) {
      const firstChild = this.logContainer.firstChild;
      if (firstChild) {
        this.logContainer.removeChild(firstChild);
      }
    }
  }
}

// Main application class
class GameApplication {
  // Components
  public canvas: CanvasManager;
  public audio: AudioManager;
  public ui: UIManager;
  public wasmLoader: WasmLoader;
  public logger: Logger;
  
  // Game state
  private isPaused: boolean = false;
  private lastTimestamp: number = 0;
  private animationFrameId: number | null = null;
  
  constructor() {
    // Initialize logger
    this.logger = new Logger();
    
    // Initialize components
    this.canvas = new CanvasManager('canvas');
    this.audio = new AudioManager(this.logger);
    this.ui = new UIManager(this);
    this.wasmLoader = new WasmLoader(this, this.logger);
    
    // Bind methods
    this.animate = this.animate.bind(this);
    this.handleKeyDown = this.handleKeyDown.bind(this);
    
    // Add event listeners
    window.addEventListener('keydown', this.handleKeyDown);
  }
  
  // Initialize the application
  async init(): Promise<void> {
    try {
      // First initialize UI
      this.ui.initialize();
      
      // Update status
      this.updateStatus('Loading audio and WASM...');
      
      // Then load audio files
      await this.audio.loadSounds();
      
      // Finally load WASM module
      const { width, height } = this.canvas.initialize();
      await this.wasmLoader.loadWasm();
      await this.wasmLoader.initializeGame(width, height);
      
      // Update status
      this.updateStatus('Game ready');
    } catch (error) {
      this.logger.error(`Initialization error: ${error}`);
      this.updateStatus(`Error: ${error}`);
    }
  }
  
  // Start the game
  startGame(): void {
    if (!this.wasmLoader.isLoaded()) return;
    
    // Reset game state if needed
    this.wasmLoader.resetGame();
    
    this.isPaused = false;
    this.updateStatus('Game started');
    
    // Start animation loop if not already running
    if (!this.animationFrameId) {
      this.startAnimationLoop();
    }
  }
  
  // Toggle pause state
  togglePause(): void {
    if (!this.wasmLoader.isLoaded()) return;
    
    this.isPaused = !this.isPaused;
    this.updateStatus(this.isPaused ? 'Game paused' : 'Game resumed');
    
    if (!this.isPaused && !this.animationFrameId) {
      this.startAnimationLoop();
    } else if (this.isPaused && this.animationFrameId !== null) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }
  }
  
  // Start animation loop
  private startAnimationLoop(): void {
    this.lastTimestamp = performance.now();
    this.animationFrameId = requestAnimationFrame(this.animate);
  }
  
  // Animation frame handler
  private animate(timestamp: number): void {
    // If paused, don't request next frame
    if (this.isPaused) {
      this.animationFrameId = null;
      return;
    }
    
    // Calculate delta time in seconds
    const deltaTime = (timestamp - this.lastTimestamp) / 1000;
    this.lastTimestamp = timestamp;
    
    try {
      // Update game state through WASM
      this.wasmLoader.updateGame(deltaTime);
      
      // Draw tower preview if hovering
      const { x, y } = this.canvas.getHoverPosition();
      if (x >= 0 && y >= 0) {
        this.wasmLoader.canPlaceTower(x, y).then(canPlace => {
          this.wasmLoader.getTowerRange().then(range => {
            this.canvas.drawTowerPreview(x, y, canPlace, range);
          });
        });
      }
      
      // Continue animation loop
      this.animationFrameId = requestAnimationFrame(this.animate);
    } catch (error) {
      this.logger.error(`Animation error: ${error}`);
      this.updateStatus('Game error occurred');
      
      // Stop animation loop on error
      if (this.animationFrameId !== null) {
        cancelAnimationFrame(this.animationFrameId);
        this.animationFrameId = null;
      }
    }
  }
  
  // Handle keyboard events
  private handleKeyDown(event: KeyboardEvent): void {
    if (!this.wasmLoader.isLoaded()) return;
    
    switch(event.key) {
      case '1': 
        this.ui.selectTower(1);
        break;
      case '2': 
        this.ui.selectTower(2);
        break;
      case '3': 
        this.ui.selectTower(3);
        break;
      case '4': 
        this.ui.selectTower(4);
        break;
      case 'Escape': 
        this.ui.deselectTowers();
        break;
      case ' ': // Space bar
        event.preventDefault();
        this.togglePause();
        break;
    }
  }
  
  // Update status message
  private updateStatus(message: string): void {
    const statusElement = document.getElementById('status');
    if (statusElement) {
      statusElement.textContent = message;
    }
  }
}

// Initialize the application when the DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  const app = new GameApplication();
  app.init();
  
  // Make app globally accessible for debugging
  (window as any).gameApp = app;
}); 