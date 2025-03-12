// Development server with auto-rebuild functionality
import { spawn } from 'node:child_process';
import { watch } from 'fs';

// Build the TypeScript files initially
console.log('🔨 Building TypeScript files...');
const initialBuild = spawn('bun', ['build', 'web/src/main.ts', '--outdir', 'dist/js'], { stdio: 'inherit' });

initialBuild.on('close', (code) => {
  if (code !== 0) {
    console.error('❌ Initial build failed');
    process.exit(1);
  }
  
  console.log('✅ Initial build complete');
  startServer();
});

function startServer() {
  // Start the HTTP server
  console.log('🚀 Starting development server...');
  
  // Create HTTP server directly instead of spawning a separate process
  const server = Bun.serve({
    port: 8080,
    async fetch(req) {
      // Get the URL path
      const url = new URL(req.url);
      let path = url.pathname;
      
      // Default to index.html for the root path
      if (path === "/" || path === "") {
        path = "/index.html";
      }
      
      // Serve the file from the dist directory
      const filePath = `./dist${path}`;
      
      try {
        const file = Bun.file(filePath);
        // Check if file exists
        const exists = await file.exists();
        if (!exists) {
          console.log(`File not found: ${filePath}`);
          return new Response("Not Found", { status: 404 });
        }
        
        return new Response(file);
      } catch (error) {
        console.error(`Error serving ${filePath}:`, error);
        return new Response("Server Error", { status: 500 });
      }
    },
  });
  
  console.log(`Server running at http://localhost:${server.port}`);
  
  // Watch for changes in the web directory
  console.log('👀 Watching for file changes...');
  
  // Watch TypeScript files
  const tsWatcher = watch('./web', { recursive: true }, (eventType, filename) => {
    if (filename && filename.endsWith('.ts')) {
      console.log(`🔄 TypeScript file changed: ${filename}`);
      console.log('🔨 Rebuilding...');
      
      const rebuild = spawn('bun', ['build', 'web/src/main.ts', '--outdir', 'dist/js'], { stdio: 'inherit' });
      
      rebuild.on('close', (code) => {
        if (code === 0) {
          console.log('✅ Rebuild complete');
        } else {
          console.error('❌ Rebuild failed');
        }
      });
    }
  });
  
  // Watch HTML and CSS files
  const htmlCssWatcher = watch('./web', { recursive: true }, (eventType, filename) => {
    if (filename && (filename.endsWith('.html') || filename.endsWith('.css'))) {
      console.log(`🔄 HTML/CSS file changed: ${filename}`);
      // You might want to copy these files to the dist directory if needed
    }
  });
  
  // Handle server termination
  process.on('SIGINT', () => {
    console.log('🛑 Stopping development server...');
    tsWatcher.close();
    htmlCssWatcher.close();
    process.exit(0);
  });
} 