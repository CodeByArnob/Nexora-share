import React from 'react';
import { Smartphone, Laptop, Terminal, CheckCircle2, Download, ExternalLink } from 'lucide-react';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const CompatibilityMatrix: React.FC = () => {
  return (
    <section id="compatibility" className="py-24 bg-[#14243B]/40 border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#3978F6]/10 border border-[#3978F6]/30 text-[#3978F6] text-xs font-semibold uppercase tracking-wider mb-4">
            <Smartphone className="w-3.5 h-3.5" />
            Cross-Platform Support
          </div>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white tracking-tight">
            Seamless Performance Across <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#3978F6] to-[#39C6B0]">
              Mobile & Desktop Hardware
            </span>
          </h2>
          <p className="mt-4 text-base sm:text-lg text-slate-300">
            NEXORA delivers high-performance P2P file sharing across Android phones, tablets, Windows laptops, and Linux workstations.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Card 1: Android (Production Released) */}
          <div className="relative p-8 rounded-3xl bg-gradient-to-b from-[#17243A] to-[#0D1420] border-2 border-[#3978F6] shadow-xl shadow-[#3978F6]/10 flex flex-col justify-between">
            <div className="absolute -top-3.5 left-8 px-3 py-1 rounded-full bg-[#3978F6] text-white text-[10px] font-black uppercase tracking-wider shadow">
              Official Production Release Available
            </div>

            <div>
              <div className="w-14 h-14 rounded-2xl bg-[#3978F6]/15 text-[#3978F6] flex items-center justify-center mb-6">
                <Smartphone className="w-8 h-8" />
              </div>
              <h3 className="text-2xl font-bold text-white">Android Mobile</h3>
              <p className="text-xs text-[#39C6B0] font-mono mt-1">Universal APK & Google Play AAB</p>

              <div className="mt-6 space-y-3 text-xs text-slate-300">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>OS Support:</strong> Android 8.0 to Android 15</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Architecture:</strong> ARM64-v8a, ARMv7, x86_64</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Background:</strong> Native Foreground Service (dataSync)</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Discovery:</strong> WifiManager MulticastLock active</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Package Size:</strong> Split ABI: ~21-25 MB (ARM64) / ~50 MB (Universal)</span>
                </div>
              </div>
            </div>

            <div className="mt-8 pt-6 border-t border-slate-700/60">
              <a
                href={RELEASE_INFO.downloadLatestApkUrl}
                className="w-full flex items-center justify-center gap-2 py-3 text-xs font-bold text-white bg-[#3978F6] hover:bg-[#2563EB] rounded-xl shadow-lg transition-all"
              >
                <Download className="w-4 h-4" />
                <span>Download Android APK ({RELEASE_INFO.tag})</span>
              </a>
            </div>
          </div>

          {/* Card 2: Windows Desktop */}
          <div className="p-8 rounded-3xl bg-[#17243A]/60 border border-slate-700/80 flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 rounded-2xl bg-[#39C6B0]/15 text-[#39C6B0] flex items-center justify-center mb-6">
                <Laptop className="w-8 h-8" />
              </div>
              <h3 className="text-2xl font-bold text-white">Windows PC</h3>
              <p className="text-xs text-slate-400 font-mono mt-1">Standalone Executable (.exe)</p>

              <div className="mt-6 space-y-3 text-xs text-slate-300">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>OS Support:</strong> Windows 10 & Windows 11 (64-bit)</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Architecture:</strong> x86_64</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>System Integration:</strong> System tray & notifications</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Security:</strong> PathSanitizer neutralizes CON/PRN</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Build:</strong> Visual Studio C++ Runner + Flutter</span>
                </div>
              </div>
            </div>

            <div className="mt-8 pt-6 border-t border-slate-700/60">
              <a
                href={RELEASE_INFO.downloadWindowsSetupUrl}
                className="w-full flex items-center justify-center gap-2 py-3 text-xs font-bold text-white bg-[#3978F6] hover:bg-[#2563EB] rounded-xl shadow-lg transition-all"
              >
                <Download className="w-4 h-4" />
                <span>Download Windows Setup ({RELEASE_INFO.tag})</span>
              </a>
            </div>
          </div>

          {/* Card 3: Linux Desktop */}
          <div className="p-8 rounded-3xl bg-[#17243A]/60 border border-slate-700/80 flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 rounded-2xl bg-[#3978F6]/15 text-[#3978F6] flex items-center justify-center mb-6">
                <Terminal className="w-8 h-8" />
              </div>
              <h3 className="text-2xl font-bold text-white">Linux Desktop</h3>
              <p className="text-xs text-slate-400 font-mono mt-1">AppImage, Flatpak & Debian (.deb)</p>

              <div className="mt-6 space-y-3 text-xs text-slate-300">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Distros:</strong> Ubuntu, Fedora, Debian, Arch Linux</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Display:</strong> X11 & native Wayland acceleration</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Packaging:</strong> AppStream & XDG desktop specification</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Security:</strong> UNIX path traversal neutralization</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Engine:</strong> Linux GTK3 runner with Rust Tokio core</span>
                </div>
              </div>
            </div>

            <div className="mt-8 pt-6 border-t border-slate-700/60">
              <a
                href={`${RELEASE_INFO.repoUrl}/tree/main/packaging`}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full flex items-center justify-center gap-2 py-3 text-xs font-semibold text-slate-300 bg-[#0D1420] hover:bg-slate-800 border border-slate-700 rounded-xl transition-all"
              >
                <span>View Packaging Manifests</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
