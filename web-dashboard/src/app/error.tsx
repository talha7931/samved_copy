'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { EmptyState } from '@/components/shared/DataDisplay';

interface ErrorProps {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function GlobalError({ error, reset }: ErrorProps) {
  useEffect(() => {
    // In a production app, this would be wired to Sentry or Datadog
    // Example: Sentry.captureException(error);
    console.error('Captured by Next.js Global Error Boundary:', error);
  }, [error]);

  return (
    <div className="flex h-screen w-full flex-col items-center justify-center bg-slate-50 p-6">
      <div className="mx-auto max-w-md text-center">
        <EmptyState
          icon="gpp_bad"
          message="A critical system error occurred"
          className="border-none bg-transparent shadow-none"
        />
        <div className="mt-4 rounded-xl border border-red-200 bg-red-50 p-4 text-left">
          <p className="text-[10px] font-black uppercase tracking-widest text-red-500">Error Details</p>
          <p className="mt-1 text-sm font-bold text-red-900">{error.message || 'Unknown error occurred.'}</p>
          {error.digest && (
            <p className="mt-2 font-mono text-[9px] text-red-400">Digest: {error.digest}</p>
          )}
        </div>
        <div className="mt-8 flex items-center justify-center gap-4">
          <button
            onClick={() => reset()}
            className="rounded-lg bg-slate-900 px-6 py-2.5 text-sm font-bold text-white transition-all hover:bg-slate-800"
          >
            Try Again
          </button>
          <Link
            href="/login"
            className="rounded-lg border border-slate-200 bg-white px-6 py-2.5 text-sm font-bold text-slate-700 transition-all hover:bg-slate-50"
          >
            Return to Login
          </Link>
        </div>
      </div>
    </div>
  );
}
