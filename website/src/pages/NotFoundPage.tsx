import { Link } from 'react-router-dom';
import { Home, AlertCircle } from 'lucide-react';

export const NotFoundPage = () => {
  return (
    <div className="py-24 sm:py-32 bg-[#0D1420] text-center px-4 flex flex-col items-center justify-center min-h-[70vh]">
      <div className="w-16 h-16 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-400 flex items-center justify-center mb-6">
        <AlertCircle className="w-8 h-8" />
      </div>

      <span className="text-xs font-mono text-[#3978F6] uppercase tracking-widest font-bold">
        Error 404
      </span>

      <h1 className="text-4xl sm:text-5xl font-extrabold text-white tracking-tight mt-2">
        Page Not Found
      </h1>

      <p className="mt-4 text-base text-slate-300 max-w-md">
        The page you are looking for does not exist or has been relocated in our peer-to-peer network.
      </p>

      <div className="mt-8 flex items-center gap-4">
        <Link
          to="/"
          className="flex items-center gap-2 px-6 py-3 rounded-xl bg-[#3978F6] hover:bg-[#2563EB] text-white text-xs font-bold transition-all shadow-lg shadow-[#3978F6]/20"
        >
          <Home className="w-4 h-4" />
          <span>Return Home</span>
        </Link>
      </div>
    </div>
  );
};
