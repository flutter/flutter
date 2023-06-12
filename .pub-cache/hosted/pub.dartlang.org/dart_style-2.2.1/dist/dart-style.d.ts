// Type definitions for dart-style

interface FormatResult {
  code?: string;
  error?: string;
}

export function formatCode(code: string): FormatResult;
