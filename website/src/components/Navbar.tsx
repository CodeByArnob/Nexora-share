import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Download, Menu, X, Shield, Cpu, Smartphone, HelpCircle } from 'lucide-react';
import { GithubIcon } from './GithubIcon';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const Navbar = () => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();
  const isHome = location.pathname === '/' || location.pathname === '';

  const getSectionHref = (id: string) => {
    return isHome ? `#${id}` : `/#${id}`;
  };

  return (
    <header className="sticky top-0 z-50 w-full bg-[#0D1420]/85 backdrop-blur-md border-b border-slate-800/80 transition-all">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-18 flex items-center justify-between">
        {/* Brand Logo */}
        <Link to="/" className="flex items-center gap-3 group focus:outline-none focus:ring-2 focus:ring-[#3978F6] rounded-lg p-1">
          <div className="w-10 h-10 rounded-xl bg-[#14243B] border border-[#3978F6] flex items-center justify-center shadow-lg shadow-[#3978F6]/10 group-hover:border-[#39C6B0] transition-colors">
            <span className="text-[#39C6B0] font-black text-xl tracking-tight">N</span>
          </div>
          <div className="flex flex-col">
            <span className="text-white font-extrabold text-xl tracking-wider leading-none">NEXORA</span>
            <span className="text-[10px] text-slate-400 font-mono tracking-widest uppercase mt-0.5">P2P File Share</span>
          </div>
        </Link>

        {/* Desktop Navigation Links */}
        <nav className="hidden md:flex items-center gap-7 text-sm font-medium text-slate-300">
          <a href={getSectionHref('features')} className="hover:text-[#39C6B0] transition-colors">Features</a>
          <a href={getSectionHref('architecture')} className="hover:text-[#39C6B0] transition-colors">Architecture</a>
          <Link to="/security" className="hover:text-[#39C6B0] transition-colors">Security</Link>
          <a href={getSectionHref('compatibility')} className="hover:text-[#39C6B0] transition-colors">Platforms</a>
          <Link to="/privacy" className="hover:text-[#39C6B0] transition-colors">Privacy</Link>
          <Link to="/support" className="hover:text-[#39C6B0] transition-colors">FAQ & Support</Link>
        </nav>

        {/* Right CTA Actions */}
        <div className="hidden lg:flex items-center gap-3">
          <a
            href={RELEASE_INFO.repoUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 px-3.5 py-2 text-xs font-semibold text-slate-300 bg-[#17243A] hover:bg-slate-800 border border-slate-700/60 rounded-xl transition-all hover:text-white"
            title="GitHub Repository"
          >
            <GithubIcon className="w-4 h-4" />
            <span>GitHub</span>
          </a>

          <a
            href={RELEASE_INFO.downloadLatestApkUrl}
            className="flex items-center gap-2 px-4 py-2 text-xs font-bold text-white bg-gradient-to-r from-[#3978F6] to-[#2563EB] hover:from-[#2563EB] hover:to-[#1D4ED8] rounded-xl shadow-lg shadow-[#3978F6]/25 transition-all hover:scale-[1.02] active:scale-[0.98]"
          >
            <Download className="w-4 h-4 animate-bounce" />
            <span>Download APK</span>
            <span className="text-[10px] bg-white/20 px-1.5 py-0.5 rounded font-mono">v1.0.0</span>
          </a>
        </div>

        {/* Mobile Hamburger Button */}
        <div className="md:hidden flex items-center gap-2">
          <a
            href={RELEASE_INFO.downloadLatestApkUrl}
            className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold text-white bg-[#3978F6] rounded-lg"
          >
            <Download className="w-3.5 h-3.5" />
            <span>APK</span>
          </a>
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="p-2 text-slate-400 hover:text-white focus:outline-none focus:ring-2 focus:ring-[#3978F6] rounded-lg"
            aria-label="Toggle navigation menu"
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden bg-[#0D1420] border-b border-slate-800 px-4 pt-3 pb-6 space-y-3">
          <nav className="flex flex-col space-y-2 text-base font-medium text-slate-300">
            <a
              href={getSectionHref('features')}
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-[#17243A] hover:text-[#39C6B0]"
            >
              <Smartphone className="w-5 h-5 text-[#3978F6]" />
              <span>Features</span>
            </a>
            <a
              href={getSectionHref('architecture')}
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-[#17243A] hover:text-[#39C6B0]"
            >
              <Cpu className="w-5 h-5 text-[#3978F6]" />
              <span>Architecture & Protocol</span>
            </a>
            <Link
              to="/security"
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-[#17243A] hover:text-[#39C6B0]"
            >
              <Shield className="w-5 h-5 text-[#39C6B0]" />
              <span>Security Policy</span>
            </Link>
            <a
              href={getSectionHref('compatibility')}
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-[#17243A] hover:text-[#39C6B0]"
            >
              <Smartphone className="w-5 h-5 text-[#3978F6]" />
              <span>Platform Compatibility</span>
            </a>
            <Link
              to="/privacy"
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-[#17243A] hover:text-[#39C6B0]"
            >
              <Shield className="w-5 h-5 text-[#39C6B0]" />
              <span>Privacy Policy</span>
            </Link>
            <Link
              to="/support"
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-[#17243A] hover:text-[#39C6B0]"
            >
              <HelpCircle className="w-5 h-5 text-[#3978F6]" />
              <span>Support & FAQ</span>
            </Link>
          </nav>

          <div className="pt-3 border-t border-slate-800 flex flex-col gap-2">
            <a
              href={RELEASE_INFO.downloadLatestApkUrl}
              className="w-full flex items-center justify-center gap-2 py-3 text-sm font-bold text-white bg-gradient-to-r from-[#3978F6] to-[#2563EB] rounded-xl shadow-lg"
            >
              <Download className="w-4 h-4" />
              <span>Download NEXORA for Android (54MB)</span>
            </a>
            <a
              href={RELEASE_INFO.repoUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full flex items-center justify-center gap-2 py-2.5 text-sm font-medium text-slate-300 bg-[#17243A] border border-slate-700/60 rounded-xl"
            >
              <GithubIcon className="w-4 h-4" />
              <span>View on GitHub</span>
            </a>
          </div>
        </div>
      )}
    </header>
  );
};
