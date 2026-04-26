import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  optimizeDeps: {
    exclude: ['es-toolkit'],
    include: []
  },
  build: {
    rollupOptions: {
      external: ['es-toolkit']
    }
  },
  ssr: {
    noExternal: ['es-toolkit']
  }
})
