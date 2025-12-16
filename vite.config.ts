import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig(({ mode }) => {
  // Ładujemy zmienne z plików .env (jeśli istnieją lokalnie)
  const env = loadEnv(mode, (process as any).cwd(), '');
  
  // Pobieramy API_KEY z process.env (Docker), pliku .env (lokalnie) lub używamy podanego klucza bezpośrednio
  const apiKey = process.env.API_KEY || env.API_KEY || "PoTJPuT1fKV-I7rvclv6HwlWFjnXZuhC5dK-q69du8TXoVOA9nLPw23yNTTyc3YunLWNYfY_11KP-zU4_DZ8JQ==";

  return {
    plugins: [react()],
    define: {
      // Wstrzykujemy wartość klucza bezpośrednio do kodu podczas budowania
      'process.env.API_KEY': JSON.stringify(apiKey)
    },
    server: {
      host: true,
      port: 5173
    }
  };
});