import { Download, ShieldCheck, FileCheck, ExternalLink, HelpCircle, Laptop, Smartphone } from 'lucide-react';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const DownloadSection = () => {
  return (
    <section id="download" className="py-24 bg-gradient-to-b from-[#0D1420] via-[#14243B]/60 to-[#0D1420] border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#3978F6]/10 border border-[#3978F6]/30 text-[#3978F6] text-xs font-semibold uppercase tracking-wider mb-4">
            <Download className="w-3.5 h-3.5" />
            Official Release Distribution
          </div>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white tracking-tight">
            Download NEXORA. <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#3978F6] to-[#39C6B0]">
              Start Sharing Anywhere.
            </span>
          </h2>
          <p className="mt-4 text-base sm:text-lg text-slate-300">
            Get the verified production release directly from GitHub. Zero ads, zero trackers, 100% open source.
          </p>
          <div className="mt-3 inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#39C6B0]/15 border border-[#39C6B0]/30 text-[#39C6B0] text-xs font-bold">
            <span className="w-2 h-2 rounded-full bg-[#39C6B0] animate-pulse" />
            Latest Stable Release: {RELEASE_INFO.tag} (Build {RELEASE_INFO.buildNumber}) • Released: {RELEASE_INFO.releaseDate}
          </div>
        </div>

        {/* Dual Platform Showcase Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 max-w-6xl mx-auto">
          {/* Card 1: Android Platform */}
          <div className="p-8 sm:p-10 rounded-3xl bg-gradient-to-br from-[#17243A] to-[#0D1420] border-2 border-[#3978F6] shadow-2xl shadow-[#3978F6]/15 flex flex-col justify-between">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="w-12 h-12 rounded-2xl bg-[#3978F6]/20 text-[#3978F6] flex items-center justify-center">
                  <Smartphone className="w-6 h-6" />
                </div>
                <span className="text-xs font-mono text-[#39C6B0] bg-[#39C6B0]/10 px-2.5 py-1 rounded-full font-semibold">
                  Android 8.0 – 15
                </span>
              </div>

              <h3 className="text-2xl sm:text-3xl font-extrabold text-white">
                NEXORA for Android
              </h3>

              <p className="text-sm text-slate-300">
                Optimized split-per-ABI packages with native SQLite and instant large-file initiation.
              </p>

              <div className="space-y-2 pt-2 text-xs text-slate-300">
                <div className="flex justify-between py-1.5 border-b border-slate-800">
                  <span className="text-slate-400">ARM64-v8a (Recommended):</span>
                  <strong className="text-white font-mono">{RELEASE_INFO.apkArm64Size}</strong>
                </div>
                <div className="flex justify-between py-1.5 border-b border-slate-800">
                  <span className="text-slate-400">Universal Package:</span>
                  <strong className="text-white font-mono">{RELEASE_INFO.apkUniversalSize}</strong>
                </div>
                <div className="flex justify-between py-1.5 border-b border-slate-800">
                  <span className="text-slate-400">ARMv7 (Legacy 32-bit):</span>
                  <strong className="text-white font-mono">{RELEASE_INFO.apkArmv7Size}</strong>
                </div>
              </div>
            </div>

            <div className="mt-8 space-y-3">
              <a
                href={RELEASE_INFO.downloadArm64ApkUrl}
                className="w-full flex items-center justify-center gap-3 py-4 px-6 rounded-2xl bg-gradient-to-r from-[#3978F6] via-[#2563EB] to-[#1D4ED8] hover:from-[#2563EB] hover:to-[#1E40AF] text-white font-extrabold text-sm shadow-xl shadow-[#3978F6]/25 transition-all hover:scale-[1.01] active:scale-[0.99]"
              >
                <Download className="w-4 h-4 animate-bounce" />
                <span>Download ARM64 APK ({RELEASE_INFO.apkArm64Size})</span>
              </a>

              <div className="flex flex-wrap items-center justify-center gap-3 text-xs text-slate-400 pt-1">
                <a href={RELEASE_INFO.downloadUniversalApkUrl} className="hover:text-white underline transition-colors">
                  Universal APK ({RELEASE_INFO.apkUniversalSize})
                </a>
                <span>•</span>
                <a href={RELEASE_INFO.downloadArmv7ApkUrl} className="hover:text-white underline transition-colors">
                  ARMv7
                </a>
                <span>•</span>
                <a href={RELEASE_INFO.downloadAabUrl} className="hover:text-white underline transition-colors">
                  Play Bundle (AAB)
                </a>
              </div>
            </div>
          </div>

          {/* Card 2: Windows Desktop Platform */}
          <div className="p-8 sm:p-10 rounded-3xl bg-gradient-to-br from-[#17243A] to-[#0D1420] border-2 border-[#39C6B0] shadow-2xl shadow-[#39C6B0]/15 flex flex-col justify-between">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="w-12 h-12 rounded-2xl bg-[#39C6B0]/20 text-[#39C6B0] flex items-center justify-center">
                  <Laptop className="w-6 h-6" />
                </div>
                <span className="text-xs font-mono text-[#3978F6] bg-[#3978F6]/10 px-2.5 py-1 rounded-full font-semibold">
                  Windows 10 / 11 (x64)
                </span>
              </div>

              <h3 className="text-2xl sm:text-3xl font-extrabold text-white">
                NEXORA for Windows
              </h3>

              <p className="text-sm text-slate-300">
                Official Inno Setup installer with branded icon assets, Start Menu & Desktop shortcuts, and automated firewall rules.
              </p>

              <div className="space-y-2 pt-2 text-xs text-slate-300">
                <div className="flex justify-between py-1.5 border-b border-slate-800">
                  <span className="text-slate-400">Setup Installer (.exe):</span>
                  <strong className="text-white font-mono">{RELEASE_INFO.windowsSetupSize}</strong>
                </div>
                <div className="flex justify-between py-1.5 border-b border-slate-800">
                  <span className="text-slate-400">Standalone Portable (.zip):</span>
                  <strong className="text-white font-mono">{RELEASE_INFO.windowsPortableSize}</strong>
                </div>
                <div className="flex justify-between py-1.5 border-b border-slate-800">
                  <span className="text-slate-400">System Integration:</span>
                  <strong className="text-white">Auto Firewall & System Tray</strong>
                </div>
              </div>
            </div>

            <div className="mt-8 space-y-3">
              <a
                href={RELEASE_INFO.downloadWindowsSetupUrl}
                className="w-full flex items-center justify-center gap-3 py-4 px-6 rounded-2xl bg-gradient-to-r from-[#00E5FF] via-[#0284C7] to-[#0369A1] hover:from-[#0284C7] hover:to-[#075985] text-[#0A0F1D] hover:text-white font-extrabold text-sm shadow-xl shadow-[#00E5FF]/20 transition-all hover:scale-[1.01] active:scale-[0.99]"
              >
                <Download className="w-4 h-4 animate-bounce" />
                <span>Download Windows Setup (.exe)</span>
              </a>

              <div className="flex flex-wrap items-center justify-center gap-3 text-xs text-slate-400 pt-1">
                <a href={RELEASE_INFO.downloadWindowsPortableUrl} className="hover:text-white underline transition-colors">
                  Portable ZIP ({RELEASE_INFO.windowsPortableSize})
                </a>
                <span>•</span>
                <a href={`${RELEASE_INFO.latestReleasePageUrl}`} target="_blank" rel="noopener noreferrer" className="hover:text-[#39C6B0] flex items-center gap-1 transition-colors">
                  <span>GitHub Release</span>
                  <ExternalLink className="w-3 h-3" />
                </a>
              </div>
            </div>
          </div>
        </div>

        {/* Cryptographic SHA-256 Checksum Card */}
        <div className="max-w-4xl mx-auto mt-10 p-6 rounded-2xl bg-[#0D1420]/90 border border-slate-800">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <ShieldCheck className="w-6 h-6 text-[#39C6B0] shrink-0" />
              <div>
                <span className="text-xs uppercase font-mono text-slate-400 block font-semibold">Cryptographic Integrity Ledger</span>
                <p className="text-xs text-slate-300">Every release artifact is SHA-256 hashed and verified automatically in GitHub Actions.</p>
              </div>
            </div>

            <a
              href={`${RELEASE_INFO.latestReleasePageUrl}/download/SHA256SUMS.txt`}
              target="_blank"
              rel="noopener noreferrer"
              className="shrink-0 flex items-center gap-2 px-4 py-2 rounded-xl bg-[#14243B] hover:bg-slate-700 text-xs font-semibold text-slate-200 hover:text-white transition-all border border-slate-700"
            >
              <FileCheck className="w-4 h-4 text-[#3978F6]" />
              <span>Download SHA256SUMS.txt</span>
            </a>
          </div>
        </div>

        {/* Step-by-Step Android Installation Guide */}
        <div className="max-w-4xl mx-auto mt-16 p-8 rounded-3xl bg-[#14243B]/40 border border-slate-800">
          <h4 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
            <HelpCircle className="w-5 h-5 text-[#3978F6]" />
            <span>How to Install NEXORA on Android Devices</span>
          </h4>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="p-4 rounded-xl bg-[#0D1420]/80 border border-slate-800">
              <span className="w-7 h-7 rounded-lg bg-[#3978F6] text-white font-bold text-xs flex items-center justify-center mb-3">
                1
              </span>
              <h5 className="text-sm font-bold text-white">Download APK</h5>
              <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                Tap ARM64 APK on your modern Android phone or tablet.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-[#0D1420]/80 border border-slate-800">
              <span className="w-7 h-7 rounded-lg bg-[#3978F6] text-white font-bold text-xs flex items-center justify-center mb-3">
                2
              </span>
              <h5 className="text-sm font-bold text-white">Open File</h5>
              <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                When download completes, open <code className="text-slate-300 font-mono text-[11px]">{RELEASE_INFO.apkArm64FileName}</code>.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-[#0D1420]/80 border border-slate-800">
              <span className="w-7 h-7 rounded-lg bg-[#3978F6] text-white font-bold text-xs flex items-center justify-center mb-3">
                3
              </span>
              <h5 className="text-sm font-bold text-white">Enable Unknown Apps</h5>
              <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                If prompted, toggle "Allow from this source" in Settings for your browser or file manager.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-[#0D1420]/80 border border-slate-800">
              <span className="w-7 h-7 rounded-lg bg-[#39C6B0] text-[#0D1420] font-bold text-xs flex items-center justify-center mb-3">
                4
              </span>
              <h5 className="text-sm font-bold text-white">Launch & Share</h5>
              <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                Tap Install, launch NEXORA, and connect devices to the same local Wi-Fi or hotspot!
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
