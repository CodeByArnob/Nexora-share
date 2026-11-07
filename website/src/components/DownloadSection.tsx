import { useState } from 'react';
import { Download, ShieldCheck, Copy, Check, FileCheck, ExternalLink, HelpCircle } from 'lucide-react';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const DownloadSection = () => {
  const [copiedSha, setCopiedSha] = useState(false);

  const handleCopySha = () => {
    navigator.clipboard.writeText(RELEASE_INFO.apkSha256);
    setCopiedSha(true);
    setTimeout(() => setCopiedSha(false), 2000);
  };

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
        </div>

        {/* Primary Download Showcase Box */}
        <div className="max-w-4xl mx-auto p-8 sm:p-10 rounded-3xl bg-gradient-to-br from-[#17243A] to-[#0D1420] border-2 border-[#3978F6] shadow-2xl shadow-[#3978F6]/20">
          <div className="flex flex-col lg:flex-row items-center justify-between gap-8">
            <div className="space-y-4 text-center lg:text-left">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#39C6B0]/15 border border-[#39C6B0]/30 text-[#39C6B0] text-xs font-bold">
                <span className="w-2 h-2 rounded-full bg-[#39C6B0] animate-pulse" />
                Latest Stable Release: {RELEASE_INFO.tag} (Build {RELEASE_INFO.buildNumber})
              </div>

              <h3 className="text-2xl sm:text-3xl font-extrabold text-white">
                NEXORA for Android
              </h3>

              <p className="text-sm text-slate-300 max-w-md">
                Universal package compatible with all Android devices running Android 8.0 Oreo through Android 15.
              </p>

              <div className="flex flex-wrap items-center justify-center lg:justify-start gap-4 text-xs font-mono text-slate-400">
                <span>Size: <strong className="text-white">{RELEASE_INFO.apkSize}</strong></span>
                <span>•</span>
                <span>Format: <strong className="text-white">Universal APK</strong></span>
                <span>•</span>
                <span>Released: <strong className="text-white">{RELEASE_INFO.releaseDate}</strong></span>
              </div>
            </div>

            {/* Download CTA Action */}
            <div className="flex flex-col items-center gap-3 w-full sm:w-auto">
              <a
                href={RELEASE_INFO.downloadLatestApkUrl}
                className="w-full sm:w-72 flex items-center justify-center gap-3 py-4 px-6 rounded-2xl bg-gradient-to-r from-[#3978F6] via-[#2563EB] to-[#1D4ED8] hover:from-[#2563EB] hover:to-[#1E40AF] text-white font-extrabold text-base shadow-xl shadow-[#3978F6]/30 transition-all hover:scale-[1.02] active:scale-[0.98]"
              >
                <Download className="w-5 h-5 animate-bounce" />
                <span>Download APK (54.4MB)</span>
              </a>

              <a
                href={RELEASE_INFO.latestReleasePageUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-xs text-slate-400 hover:text-[#39C6B0] flex items-center gap-1.5 transition-colors"
              >
                <span>View Release on GitHub</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>

          {/* Cryptographic SHA-256 Checksum Card */}
          <div className="mt-8 pt-6 border-t border-slate-700/80">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 bg-[#0D1420]/80 p-4 rounded-xl border border-slate-800">
              <div className="flex items-center gap-2 overflow-hidden w-full">
                <ShieldCheck className="w-5 h-5 text-[#39C6B0] shrink-0" />
                <div className="overflow-hidden">
                  <span className="text-[10px] uppercase font-mono text-slate-400 block">SHA-256 Cryptographic Checksum</span>
                  <code className="text-[11px] sm:text-xs text-slate-200 font-mono truncate block">
                    {RELEASE_INFO.apkSha256}
                  </code>
                </div>
              </div>

              <button
                onClick={handleCopySha}
                className="shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#14243B] hover:bg-slate-700 text-xs font-semibold text-slate-300 hover:text-white transition-all border border-slate-700"
                title="Copy SHA-256 Hash"
              >
                {copiedSha ? (
                  <>
                    <Check className="w-3.5 h-3.5 text-[#39C6B0]" />
                    <span className="text-[#39C6B0]">Copied!</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-3.5 h-3.5" />
                    <span>Copy Hash</span>
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Additional Packages & Archive */}
          <div className="mt-6 flex flex-wrap items-center justify-between gap-4 text-xs text-slate-400">
            <div className="flex items-center gap-4">
              <a
                href={`${RELEASE_INFO.latestReleasePageUrl}/download/${RELEASE_INFO.aabFileName}`}
                className="hover:text-white flex items-center gap-1 transition-colors"
              >
                <FileCheck className="w-4 h-4 text-[#3978F6]" />
                <span>Google Play Bundle ({RELEASE_INFO.aabSize})</span>
              </a>
              <span>•</span>
              <a
                href={`${RELEASE_INFO.latestReleasePageUrl}/download/SHA256SUMS.txt`}
                className="hover:text-white flex items-center gap-1 transition-colors"
              >
                <span>SHA256SUMS.txt</span>
              </a>
            </div>

            <a
              href={RELEASE_INFO.releasesArchiveUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-[#39C6B0] flex items-center gap-1 transition-colors font-medium"
            >
              <span>Browse All Previous Releases & Changelogs</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>

        {/* Step-by-Step Android Installation Guide */}
        <div className="max-w-4xl mx-auto mt-16 p-8 rounded-3xl bg-[#14243B]/40 border border-slate-800">
          <h4 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
            <HelpCircle className="w-5 h-5 text-[#3978F6]" />
            <span>How to Install on Android Devices</span>
          </h4>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="p-4 rounded-xl bg-[#0D1420]/80 border border-slate-800">
              <span className="w-7 h-7 rounded-lg bg-[#3978F6] text-white font-bold text-xs flex items-center justify-center mb-3">
                1
              </span>
              <h5 className="text-sm font-bold text-white">Download APK</h5>
              <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                Tap the download button above on your Android phone or tablet.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-[#0D1420]/80 border border-slate-800">
              <span className="w-7 h-7 rounded-lg bg-[#3978F6] text-white font-bold text-xs flex items-center justify-center mb-3">
                2
              </span>
              <h5 className="text-sm font-bold text-white">Open File</h5>
              <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                When download completes, open <code className="text-slate-300">nexora-v1.0.0-release.apk</code> from notifications or Downloads.
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
                Tap Install, launch NEXORA, and connect devices to the same Wi-Fi or hotspot!
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
