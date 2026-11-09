import { Link } from 'react-router-dom';
import { ExternalLink } from 'lucide-react';
import { GithubIcon } from './GithubIcon';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const Footer = () => {
  return (
    <footer className="bg-[#090E17] border-t border-slate-800/80 text-slate-400 text-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-10">
          {/* Column 1: Brand & Statement */}
          <div className="lg:col-span-2 space-y-4">
            <Link to="/" className="flex items-center gap-3 group inline-flex">
              <div className="w-9 h-9 rounded-xl bg-[#14243B] border border-[#3978F6] flex items-center justify-center">
                <span className="text-[#39C6B0] font-black text-lg">N</span>
              </div>
              <span className="text-white font-extrabold text-xl tracking-wider">NEXORA</span>
            </Link>

            <p className="text-xs font-mono text-[#39C6B0] tracking-widest uppercase font-semibold">
              PRIVATE BY DESIGN. OPEN BY NATURE.
            </p>

            <p className="text-xs text-slate-400 max-w-sm leading-relaxed">
              NEXORA is a modern Android application for secure, fast, and convenient file sharing between supported devices. Direct local network streaming with zero cloud telemetry.
            </p>

            <div className="pt-2 flex items-center gap-2 text-xs text-slate-400 font-mono">
              <span className="w-2 h-2 rounded-full bg-[#39C6B0]" />
              <span>Release {RELEASE_INFO.tag} (Build {RELEASE_INFO.buildNumber}) • Apache 2.0</span>
            </div>
          </div>

          {/* Column 2: Navigation & Product */}
          <div>
            <h4 className="text-white font-bold text-xs uppercase tracking-wider mb-4">Product</h4>
            <ul className="space-y-2.5 text-xs">
              <li><a href="/#features" className="hover:text-white transition-colors">Key Features</a></li>
              <li><a href="/#architecture" className="hover:text-white transition-colors">Architecture & Protocols</a></li>
              <li><a href="/#compatibility" className="hover:text-white transition-colors">Android Ecosystem</a></li>
              <li><a href="/#download" className="hover:text-[#3978F6] transition-colors font-semibold">Download Android APK</a></li>
              <li><a href={RELEASE_INFO.releasesArchiveUrl} target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors flex items-center gap-1">Release History <ExternalLink className="w-3 h-3" /></a></li>
            </ul>
          </div>

          {/* Column 3: Trust & Governance */}
          <div>
            <h4 className="text-white font-bold text-xs uppercase tracking-wider mb-4">Trust & Legal</h4>
            <ul className="space-y-2.5 text-xs">
              <li><Link to="/privacy" className="hover:text-[#39C6B0] transition-colors font-medium">Privacy Policy</Link></li>
              <li><Link to="/security" className="hover:text-[#39C6B0] transition-colors font-medium">Security Policy</Link></li>
              <li><Link to="/terms" className="hover:text-white transition-colors">Terms of Use</Link></li>
              <li><Link to="/licenses" className="hover:text-white transition-colors">Open Source Licenses</Link></li>
            </ul>
          </div>

          {/* Column 4: Community & Maintainer */}
          <div>
            <h4 className="text-white font-bold text-xs uppercase tracking-wider mb-4">Community</h4>
            <ul className="space-y-2.5 text-xs">
              <li><Link to="/support" className="hover:text-white transition-colors">FAQ & Support</Link></li>
              <li><Link to="/contact" className="hover:text-white transition-colors">Contact & Maintainer</Link></li>
              <li><a href={RELEASE_INFO.repoUrl} target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors flex items-center gap-1">GitHub Repository <GithubIcon className="w-3.5 h-3.5" /></a></li>
              <li><a href={RELEASE_INFO.issuesUrl} target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors flex items-center gap-1">Issue Tracker <ExternalLink className="w-3 h-3" /></a></li>
              <li><a href={RELEASE_INFO.maintainerUrl} target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors flex items-center gap-1">CodeByArnob <ExternalLink className="w-3 h-3" /></a></li>
            </ul>
          </div>
        </div>

        {/* Bottom Credits Strip */}
        <div className="mt-12 pt-8 border-t border-slate-800/80 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs">
          <p className="text-slate-500">
            © 2026 NEXORA Open Source Project. Licensed under the <a href="https://www.apache.org/licenses/LICENSE-2.0" target="_blank" rel="noopener noreferrer" className="text-slate-400 hover:text-white underline">Apache License 2.0</a>.
          </p>

          <p className="flex items-center gap-1.5 text-slate-400">
            <span>Maintained with senior craftsmanship by</span>
            <a
              href={RELEASE_INFO.maintainerUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#39C6B0] hover:underline font-bold"
            >
              CodeByArnob
            </a>
          </p>
        </div>
      </div>
    </footer>
  );
};
