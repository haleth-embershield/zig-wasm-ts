// UI manager for handling user interface elements and interactions

interface GameApp {
  canvas: any;
  wasmLoader: any;
  audio: any;
  logger: {
    log(message: string): void;
    error(message: string): void;
    warn(message: string): void;
  };
  startGame(): void;
  togglePause(): void;
}

export class UIManager {
  private gameApp: GameApp;
  private selectedTowerType: number = 0;
  private startButton: HTMLElement | null = null;
  private pauseButton: HTMLElement | null = null;
  private towerButtons: {
    line: HTMLElement | null;
    triangle: HTMLElement | null;
    square: HTMLElement | null;
    pentagon: HTMLElement | null;
  } = {
    line: null,
    triangle: null,
    square: null,
    pentagon: null
  };
  private logContainer: HTMLElement | null = null;
  private logToggle: HTMLElement | null = null;
  private logBuffer: string[] = [];

  constructor(gameApp: GameApp) {
    this.gameApp = gameApp;
  }

  /**
   * Initialize the UI elements
   */
  initialize(): void {
    // Get UI elements
    this.startButton = document.getElementById('start-button');
    this.pauseButton = document.getElementById('pause-button');
    this.logContainer = document.getElementById('log-container');
    this.logToggle = document.getElementById('log-toggle');
    
    // Tower buttons
    this.towerButtons = {
      line: document.getElementById('tower-line'),
      triangle: document.getElementById('tower-triangle'),
      square: document.getElementById('tower-square'),
      pentagon: document.getElementById('tower-pentagon')
    };
    
    // Add event listeners
    if (this.startButton) {
      this.startButton.addEventListener('click', () => this.gameApp.startGame());
    }
    
    if (this.pauseButton) {
      this.pauseButton.addEventListener('click', () => this.gameApp.togglePause());
    }
    
    // Tower selection buttons
    if (this.towerButtons.line) {
      this.towerButtons.line.addEventListener('click', () => this.selectTower(1));
    }
    
    if (this.towerButtons.triangle) {
      this.towerButtons.triangle.addEventListener('click', () => this.selectTower(2));
    }
    
    if (this.towerButtons.square) {
      this.towerButtons.square.addEventListener('click', () => this.selectTower(3));
    }
    
    if (this.towerButtons.pentagon) {
      this.towerButtons.pentagon.addEventListener('click', () => this.selectTower(4));
    }
    
    // Log toggle
    if (this.logToggle) {
      this.logToggle.addEventListener('click', () => this.toggleLog());
    }
    
    // Process any buffered log messages
    this.processLogBuffer();
    
    this.gameApp.logger.log('UI initialized');
  }

  /**
   * Process any log messages that were received before UI was ready
   */
  private processLogBuffer(): void {
    if (this.logBuffer.length > 0 && this.logContainer) {
      // Clear the initial placeholder message
      this.logContainer.innerHTML = '';
      
      // Add all buffered messages
      for (const message of this.logBuffer) {
        this.addLogEntryDirect(message);
      }
      
      // Clear the buffer
      this.logBuffer = [];
    }
  }

  /**
   * Select tower type
   */
  selectTower(towerType: number): void {
    // Update UI
    Object.values(this.towerButtons).forEach(btn => {
      if (btn) btn.classList.remove('active');
    });
    
    // Set active class based on selection
    switch(towerType) {
      case 1: 
        if (this.towerButtons.line) this.towerButtons.line.classList.add('active'); 
        break;
      case 2: 
        if (this.towerButtons.triangle) this.towerButtons.triangle.classList.add('active'); 
        break;
      case 3: 
        if (this.towerButtons.square) this.towerButtons.square.classList.add('active'); 
        break;
      case 4: 
        if (this.towerButtons.pentagon) this.towerButtons.pentagon.classList.add('active'); 
        break;
      default: 
        break; // For ESC key (deselect)
    }
    
    // Call WASM function to set selected tower type
    this.gameApp.wasmLoader.selectTowerType(towerType);
    
    // Update canvas manager
    this.gameApp.canvas.setSelectedTowerType(towerType);
  }

  /**
   * Deselect all towers
   */
  deselectTowers(): void {
    this.selectTower(0);
  }

  /**
   * Add log entry to the log container
   */
  addLogEntry(message: string): void {
    if (!this.logContainer) {
      // If log container isn't ready yet, buffer the message
      this.logBuffer.push(message);
      return;
    }
    
    this.addLogEntryDirect(message);
  }

  /**
   * Directly add a log entry to the container (no buffering)
   */
  private addLogEntryDirect(message: string): void {
    if (!this.logContainer) return;
    
    const entry = document.createElement('div');
    entry.className = 'log-entry';
    entry.textContent = message;
    this.logContainer.appendChild(entry);
    
    // Auto-scroll to bottom
    this.logContainer.scrollTop = this.logContainer.scrollHeight;
    
    // Limit number of entries
    while (this.logContainer.children.length > 100) {
      const firstChild = this.logContainer.firstChild;
      if (firstChild) {
        this.logContainer.removeChild(firstChild);
      }
    }
  }

  /**
   * Toggle log visibility
   */
  private toggleLog(): void {
    if (!this.logContainer || !this.logToggle) return;
    
    this.logContainer.classList.toggle('hidden');
    this.logToggle.classList.toggle('collapsed');
  }

  /**
   * Update the money display
   */
  updateMoneyDisplay(newMoney?: number): void {
    const moneyElement = document.getElementById('money');
    if (moneyElement && newMoney !== undefined) {
      moneyElement.textContent = `$${newMoney}`;
    }
  }

  /**
   * Update the score display
   */
  updateScoreDisplay(newScore?: number): void {
    const scoreElement = document.getElementById('score');
    if (scoreElement && newScore !== undefined) {
      scoreElement.textContent = `Score: ${newScore}`;
    }
  }

  /**
   * Update the wave display
   */
  updateWaveDisplay(newWave?: number): void {
    const waveElement = document.getElementById('wave');
    if (waveElement && newWave !== undefined) {
      waveElement.textContent = `Wave: ${newWave}`;
    }
  }

  /**
   * Show a message to the player
   */
  showMessage(message: string, duration: number = 3000): void {
    const messageElement = document.getElementById('message');
    if (!messageElement) return;
    
    messageElement.textContent = message;
    messageElement.classList.add('visible');
    
    setTimeout(() => {
      messageElement.classList.remove('visible');
    }, duration);
  }

  /**
   * Show the game over screen
   */
  showGameOver(finalScore: number, victory: boolean = false): void {
    const gameOverElement = document.getElementById('game-over');
    const gameOverTitleElement = document.getElementById('game-over-title');
    const gameOverScoreElement = document.getElementById('game-over-score');
    
    if (!gameOverElement || !gameOverTitleElement || !gameOverScoreElement) return;
    
    // Set title and score
    gameOverTitleElement.textContent = victory ? 'Victory!' : 'Game Over';
    gameOverScoreElement.textContent = `Final Score: ${finalScore}`;
    
    // Show the game over screen
    gameOverElement.classList.add('visible');
    
    // Play appropriate sound
    this.gameApp.audio.playSound(victory ? 'levelComplete' : 'levelFail');
  }

  /**
   * Get the currently selected tower type
   */
  getSelectedTowerType(): number {
    return this.selectedTowerType;
  }
} 