// Canvas manager for handling rendering and canvas interactions

export class CanvasManager {
  private canvas: HTMLCanvasElement | null = null;
  private ctx: CanvasRenderingContext2D | null = null;
  private originalWidth: number = 800;
  private originalHeight: number = 600;
  private scaleX: number = 1;
  private scaleY: number = 1;
  private currentHoverX: number = -1;
  private currentHoverY: number = -1;
  private selectedTowerType: number = 0;
  private canvasId: string;
  private isTouchDevice: boolean;

  constructor(canvasId: string) {
    this.canvasId = canvasId;
    this.isTouchDevice = 'ontouchstart' in window;
  }

  /**
   * Initialize the canvas and set up event listeners
   */
  initialize(): { width: number, height: number } {
    // Get canvas element
    this.canvas = document.getElementById(this.canvasId) as HTMLCanvasElement;
    if (!this.canvas) {
      throw new Error(`Canvas element with ID '${this.canvasId}' not found`);
    }

    // Get 2D context
    this.ctx = this.canvas.getContext('2d');
    if (!this.ctx) {
      throw new Error('Failed to get 2D context from canvas');
    }

    // Store original dimensions
    this.originalWidth = this.canvas.width;
    this.originalHeight = this.canvas.height;

    // Setup event listeners
    this.setupEventListeners();
    
    // Initial resize
    this.handleResize();

    return { width: this.originalWidth, height: this.originalHeight };
  }

  /**
   * Set up event listeners based on device type
   */
  private setupEventListeners(): void {
    if (!this.canvas) return;
    
    // Mouse events for desktop
    this.canvas.addEventListener('mousemove', this.handleMouseMove.bind(this));
    this.canvas.addEventListener('mouseleave', this.handleMouseLeave.bind(this));
    this.canvas.addEventListener('click', this.handleClick.bind(this));
    
    // Touch events for mobile
    if (this.isTouchDevice) {
      this.canvas.addEventListener('touchstart', this.handleTouchStart.bind(this));
      this.canvas.addEventListener('touchmove', this.handleTouchMove.bind(this));
      this.canvas.addEventListener('touchend', this.handleTouchEnd.bind(this));
    }
    
    // Resize event
    window.addEventListener('resize', this.handleResize.bind(this));
  }

  /**
   * Handle window resize
   */
  private handleResize(): void {
    if (!this.canvas) return;
    
    const containerWidth = this.canvas.parentElement?.clientWidth || window.innerWidth;
    
    // Calculate the display size of the canvas
    const displayWidth = containerWidth;
    const displayHeight = (this.originalHeight / this.originalWidth) * displayWidth;
    
    // Set the canvas display size (CSS)
    this.canvas.style.width = `${displayWidth}px`;
    this.canvas.style.height = `${displayHeight}px`;
    
    // Set the canvas internal resolution (actual size)
    this.canvas.width = this.originalWidth;
    this.canvas.height = this.originalHeight;
    
    // Calculate the new scale factors
    this.scaleX = this.canvas.width / this.originalWidth;
    this.scaleY = this.canvas.height / this.originalHeight;
  }

  /**
   * Convert screen coordinates to game world coordinates
   */
  private screenToWorld(screenX: number, screenY: number): { x: number, y: number } {
    if (!this.canvas) return { x: 0, y: 0 };
    
    // Get the canvas's current display dimensions
    const rect = this.canvas.getBoundingClientRect();
    const scaleX = this.canvas.width / rect.width;
    const scaleY = this.canvas.height / rect.height;
    
    return {
      x: screenX * scaleX,
      y: screenY * scaleY
    };
  }

  /**
   * Clear the canvas
   */
  clear(): void {
    if (!this.ctx || !this.canvas) return;
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
  }

  /**
   * Draw a rectangle
   */
  drawRect(x: number, y: number, width: number, height: number, r: number, g: number, b: number): void {
    if (!this.ctx) return;
    this.ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
    this.ctx.fillRect(x, y, width, height);
  }

  /**
   * Draw a circle
   */
  drawCircle(x: number, y: number, radius: number, r: number, g: number, b: number, fill: boolean): void {
    if (!this.ctx) return;
    this.ctx.beginPath();
    this.ctx.arc(x, y, radius, 0, Math.PI * 2);
    if (fill) {
      this.ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
      this.ctx.fill();
    } else {
      this.ctx.strokeStyle = `rgb(${r}, ${g}, ${b})`;
      this.ctx.lineWidth = 2;
      this.ctx.stroke();
    }
  }

  /**
   * Draw a line
   */
  drawLine(x1: number, y1: number, x2: number, y2: number, thickness: number, r: number, g: number, b: number): void {
    if (!this.ctx) return;
    this.ctx.beginPath();
    this.ctx.moveTo(x1, y1);
    this.ctx.lineTo(x2, y2);
    this.ctx.strokeStyle = `rgb(${r}, ${g}, ${b})`;
    this.ctx.lineWidth = thickness;
    this.ctx.stroke();
  }

  /**
   * Draw a triangle
   */
  drawTriangle(x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, r: number, g: number, b: number, fill: boolean): void {
    if (!this.ctx) return;
    this.ctx.beginPath();
    this.ctx.moveTo(x1, y1);
    this.ctx.lineTo(x2, y2);
    this.ctx.lineTo(x3, y3);
    this.ctx.closePath();
    if (fill) {
      this.ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
      this.ctx.fill();
    } else {
      this.ctx.strokeStyle = `rgb(${r}, ${g}, ${b})`;
      this.ctx.lineWidth = 2;
      this.ctx.stroke();
    }
  }

  /**
   * Draw text
   */
  drawText(x: number, y: number, text: string, size: number, r: number, g: number, b: number): void {
    if (!this.ctx) return;
    this.ctx.font = `${size}px sans-serif`;
    this.ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
    this.ctx.fillText(text, x, y);
  }

  /**
   * Draw tower placement preview
   */
  drawTowerPreview(x: number, y: number, canPlace: boolean, range: number): void {
    if (!this.ctx || x < 0 || y < 0) return;
    
    // Draw tower placement indicator
    this.ctx.beginPath();
    this.ctx.arc(x, y, 20, 0, Math.PI * 2);
    this.ctx.strokeStyle = canPlace ? 'rgba(0, 255, 238, 0.5)' : 'rgba(255, 0, 0, 0.5)';
    this.ctx.lineWidth = 2;
    this.ctx.stroke();
    
    // Draw tower range indicator if placement is valid
    if (canPlace && range > 0) {
      this.ctx.beginPath();
      this.ctx.arc(x, y, range, 0, Math.PI * 2);
      this.ctx.strokeStyle = 'rgba(0, 255, 238, 0.2)';
      this.ctx.lineWidth = 1;
      this.ctx.stroke();
    }
    
    if (!canPlace) {
      // Draw X
      this.ctx.beginPath();
      this.ctx.moveTo(x - 15, y - 15);
      this.ctx.lineTo(x + 15, y + 15);
      this.ctx.moveTo(x + 15, y - 15);
      this.ctx.lineTo(x - 15, y + 15);
      this.ctx.strokeStyle = 'rgba(255, 0, 0, 0.5)';
      this.ctx.stroke();
    }
  }

  /**
   * Handle mouse move for tower placement preview
   */
  private handleMouseMove(event: MouseEvent): void {
    if (!this.canvas) return;
    
    const rect = this.canvas.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    
    // Convert to world coordinates
    const worldPos = this.screenToWorld(x, y);
    
    // Snap to grid (40x40)
    this.currentHoverX = Math.floor(worldPos.x / 40) * 40 + 20;
    this.currentHoverY = Math.floor(worldPos.y / 40) * 40 + 20;
  }

  /**
   * Handle mouse leave
   */
  private handleMouseLeave(): void {
    this.currentHoverX = -1;
    this.currentHoverY = -1;
  }

  /**
   * Handle canvas click
   */
  private handleClick(event: MouseEvent): void {
    if (!this.canvas) return;
    
    // This will be delegated to the app through the WasmLoader
    const gameApp = (window as any).gameApp;
    if (gameApp && gameApp.wasmLoader) {
      const rect = this.canvas.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const y = event.clientY - rect.top;
      
      // Convert to world coordinates
      const worldPos = this.screenToWorld(x, y);
      
      gameApp.wasmLoader.handleClick(worldPos.x, worldPos.y);
    }
  }

  /**
   * Handle touch start event
   */
  private handleTouchStart(event: TouchEvent): void {
    if (!this.canvas) return;
    event.preventDefault();
    
    if (event.touches.length === 1) {
      const touch = event.touches[0];
      const rect = this.canvas.getBoundingClientRect();
      const x = touch.clientX - rect.left;
      const y = touch.clientY - rect.top;
      
      // Convert to world coordinates
      const worldPos = this.screenToWorld(x, y);
      
      // Snap to grid (40x40)
      this.currentHoverX = Math.floor(worldPos.x / 40) * 40 + 20;
      this.currentHoverY = Math.floor(worldPos.y / 40) * 40 + 20;
    }
  }

  /**
   * Handle touch move event
   */
  private handleTouchMove(event: TouchEvent): void {
    if (!this.canvas) return;
    event.preventDefault();
    
    if (event.touches.length === 1) {
      const touch = event.touches[0];
      const rect = this.canvas.getBoundingClientRect();
      const x = touch.clientX - rect.left;
      const y = touch.clientY - rect.top;
      
      // Convert to world coordinates
      const worldPos = this.screenToWorld(x, y);
      
      // Snap to grid (40x40)
      this.currentHoverX = Math.floor(worldPos.x / 40) * 40 + 20;
      this.currentHoverY = Math.floor(worldPos.y / 40) * 40 + 20;
    }
  }

  /**
   * Handle touch end event
   */
  private handleTouchEnd(event: TouchEvent): void {
    if (!this.canvas) return;
    event.preventDefault();
    
    // Handle as a click
    const gameApp = (window as any).gameApp;
    if (gameApp && gameApp.wasmLoader) {
      gameApp.wasmLoader.handleClick(this.currentHoverX, this.currentHoverY);
    }
    
    // Reset hover position
    this.currentHoverX = -1;
    this.currentHoverY = -1;
  }

  /**
   * Set the currently selected tower type
   */
  setSelectedTowerType(type: number): void {
    this.selectedTowerType = type;
  }

  /**
   * Get the canvas element
   */
  getCanvas(): HTMLCanvasElement | null {
    return this.canvas;
  }

  /**
   * Get the canvas context
   */
  getContext(): CanvasRenderingContext2D | null {
    return this.ctx;
  }

  /**
   * Get the canvas dimensions
   */
  getDimensions(): { width: number, height: number } {
    return { 
      width: this.canvas?.width || this.originalWidth, 
      height: this.canvas?.height || this.originalHeight 
    };
  }

  /**
   * Get the current hover position
   */
  getHoverPosition(): { x: number, y: number } {
    return { x: this.currentHoverX, y: this.currentHoverY };
  }
} 