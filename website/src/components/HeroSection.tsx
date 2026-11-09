import { Download, CheckCircle2, ArrowRight } from 'lucide-react';
import { GithubIcon } from './GithubIcon';
import { RELEASE_INFO } from '../constants/releaseInfo';
import { DeviceVisualizer } from './DeviceVisualizer';

export const HeroSection = () => {
  return (
    <section className="relative pt-12 pb-20 overflow-hidden bg-gradient-to-b from-[#0D1420] via-[#14243B]/30 to-[#0D1420]">
      {/* Background Subtle Gradient Blobs */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] sm:w-[900px] h-[400px] bg-gradient-to-tr from-[#3978F6]/15 via-[#39C6B0]/10 to-transparent rounded-full blur-3xl pointer-events-none -z-10" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-4xl mx-auto space-y-6">
          {/* Release Version Announcement Pill */}
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#17243A] border border-[#3978F6]/40 text-xs font-semibold text-slate-200 shadow-lg shadow-[#3978F6]/10 hover:border-[#39C6B0] transition-colors">
            <span className="w-2 h-2 rounded-full bg-[#39C6B0] animate-ping" />
            <span>NEXORA {RELEASE_INFO.tag} Android Production Release Available</span>
            <span className="text-slate-500">•</span>
            <a href="#download" className="text-[#39C6B0] hover:underline flex items-center gap-1 font-bold">
              Download APK <ArrowRight className="w-3 h-3" />
            </a>
          </div>

          {/* Main Headline */}
          <h1 className="text-4xl sm:text-6xl lg:text-7xl font-black text-white tracking-tight leading-[1.1]">
            Private Local P2P Sharing. <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#3978F6] via-[#60A5FA] to-[#39C6B0]">
              Zero Cloud. Unlimited Speed.
            </span>
          </h1>

          {/* Brand Statements */}
          <div className="flex flex-wrap items-center justify-center gap-3 text-xs sm:text-sm font-mono tracking-wider font-bold">
            <span className="text-[#3978F6] bg-[#3978F6]/10 px-3 py-1 rounded-md border border-[#3978F6]/20">
              CONNECT. SHARE. ANYWHERE.
            </span>
            <span className="text-[#39C6B0] bg-[#39C6B0]/10 px-3 py-1 rounded-md border border-[#39C6B0]/20">
              PRIVATE BY DESIGN. OPEN BY NATURE.
            </span>
          </div>

          {/* Core Description */}
          <p className="text-base sm:text-xl text-slate-300 max-w-2xl mx-auto leading-relaxed font-normal">
            NEXORA is a modern Android application for secure, fast, and convenient file sharing between supported devices. Directly stream multi-gigabyte files over local Wi-Fi or mobile hotspots with zero cloud servers, zero file size limits, and cryptographic SHA-256 integrity verification.
          </p>

          {/* Primary Action Buttons */}
          <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href={RELEASE_INFO.downloadLatestApkUrl}
              className="w-full sm:w-auto flex items-center justify-center gap-3 px-8 py-4 rounded-2xl bg-gradient-to-r from-[#3978F6] to-[#2563EB] hover:from-[#2563EB] hover:to-[#1D4ED8] text-white font-black text-base shadow-2xl shadow-[#3978F6]/30 transition-all hover:scale-[1.02] active:scale-[0.98]"
            >
              <Download className="w-5 h-5 animate-bounce" />
              <span>Download Android APK (ARM64 • {RELEASE_INFO.apkArm64Size})</span>
            </a>

            <a
              href="#download"
              className="w-full sm:w-auto flex items-center justify-center gap-2.5 px-7 py-4 rounded-2xl bg-[#14243B] hover:bg-[#17243A] text-slate-200 hover:text-white font-bold text-base border border-slate-700/80 transition-all shadow-lg"
            >
              <span>All APK Builds & Architectures</span>
            </a>

            <a
              href={RELEASE_INFO.repoUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full sm:w-auto flex items-center justify-center gap-2.5 px-6 py-4 rounded-2xl bg-[#14243B]/60 hover:bg-[#17243A] text-slate-300 hover:text-white font-medium text-base border border-slate-800 transition-all shadow-lg"
            >
              <GithubIcon className="w-5 h-5" />
              <span>GitHub</span>
            </a>
          </div>

          {/* High-Level Feature Badges */}
          <div className="pt-4 flex flex-wrap items-center justify-center gap-y-2 gap-x-6 text-xs text-slate-400">
            <div className="flex items-center gap-1.5">
              <CheckCircle2 className="w-4 h-4 text-[#39C6B0]" />
              <span>Zero Cloud Intermediaries</span>
            </div>
            <div className="flex items-center gap-1.5">
              <CheckCircle2 className="w-4 h-4 text-[#39C6B0]" />
              <span>1MB Bounded RAM Streaming</span>
            </div>
            <div className="flex items-center gap-1.5">
              <CheckCircle2 className="w-4 h-4 text-[#39C6B0]" />
              <span>Android MulticastLock & WakeLock</span>
            </div>
            <div className="flex items-center gap-1.5">
              <CheckCircle2 className="w-4 h-4 text-[#39C6B0]" />
              <span>Direct IP & AP Isolation Fallback</span>
            </div>
          </div>
        </div>

        {/* Embedded Interactive Device Visualizer */}
        <div className="mt-16">
          <DeviceVisualizer />
        </div>
      </div>
    </section>
  );
};
