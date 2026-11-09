import React from 'react';
import { Smartphone, Tablet, Cpu, CheckCircle2, Download } from 'lucide-react';
import { RELEASE_INFO } from '../constants/releaseInfo';

export const CompatibilityMatrix: React.FC = () => {
  return (
    <section id="compatibility" className="py-24 bg-[#14243B]/40 border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#3978F6]/10 border border-[#3978F6]/30 text-[#3978F6] text-xs font-semibold uppercase tracking-wider mb-4">
            <Smartphone className="w-3.5 h-3.5" />
            Android Ecosystem Support
          </div>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white tracking-tight">
            Optimized for Every <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#3978F6] to-[#39C6B0]">
              Android Device & Architecture
            </span>
          </h2>
          <p className="mt-4 text-base sm:text-lg text-slate-300">
            NEXORA delivers high-performance P2P file sharing across Android smartphones, tablets, foldables, and Chromebooks running Android runtime.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Card 1: Modern Android (ARM64-v8a) */}
          <div className="relative p-8 rounded-3xl bg-gradient-to-b from-[#17243A] to-[#0D1420] border-2 border-[#3978F6] shadow-xl shadow-[#3978F6]/10 flex flex-col justify-between">
            <div className="absolute -top-3.5 left-8 px-3 py-1 rounded-full bg-[#3978F6] text-white text-[10px] font-black uppercase tracking-wider shadow">
              Recommended • 64-Bit Android
            </div>

            <div>
              <div className="w-14 h-14 rounded-2xl bg-[#3978F6]/15 text-[#3978F6] flex items-center justify-center mb-6">
                <Smartphone className="w-8 h-8" />
              </div>
              <h3 className="text-2xl font-bold text-white">Modern Android</h3>
              <p className="text-xs text-[#39C6B0] font-mono mt-1">ARM64-v8a Architecture</p>

              <div className="mt-6 space-y-3 text-xs text-slate-300">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>OS Support:</strong> Android 11 through Android 15 (API 30–35)</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Architecture:</strong> arm64-v8a (AArch64 optimized)</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Background Service:</strong> Native dataSync Foreground Service</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Discovery:</strong> WifiManager MulticastLock active</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Package Size:</strong> Highly optimized ~25.0 MB</span>
                </div>
              </div>
            </div>

            <div className="mt-8 pt-6 border-t border-slate-700/60">
              <a
                href={RELEASE_INFO.downloadArm64ApkUrl}
                className="w-full flex items-center justify-center gap-2 py-3 text-xs font-bold text-white bg-[#3978F6] hover:bg-[#2563EB] rounded-xl shadow-lg transition-all"
              >
                <Download className="w-4 h-4" />
                <span>Download ARM64 APK ({RELEASE_INFO.tag})</span>
              </a>
            </div>
          </div>

          {/* Card 2: Legacy Android (ARMv7) */}
          <div className="p-8 rounded-3xl bg-[#17243A]/60 border border-slate-700/80 flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 rounded-2xl bg-[#39C6B0]/15 text-[#39C6B0] flex items-center justify-center mb-6">
                <Cpu className="w-8 h-8" />
              </div>
              <h3 className="text-2xl font-bold text-white">Legacy Android</h3>
              <p className="text-xs text-slate-400 font-mono mt-1">armeabi-v7a (32-bit)</p>

              <div className="mt-6 space-y-3 text-xs text-slate-300">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>OS Support:</strong> Android 8.0 Oreo to Android 10 (API 26–29)</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Architecture:</strong> armeabi-v7a (32-bit ARM)</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Storage:</strong> Android SAF & Download Directory Support</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Compatibility:</strong> Low-spec & older Android smartphones</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Package Size:</strong> Ultra-lean ~20.9 MB</span>
                </div>
              </div>
            </div>

            <div className="mt-8 pt-6 border-t border-slate-700/60">
              <a
                href={RELEASE_INFO.downloadArmv7ApkUrl}
                className="w-full flex items-center justify-center gap-2 py-3 text-xs font-bold text-white bg-[#14243B] hover:bg-slate-700 border border-slate-600 rounded-xl shadow-lg transition-all"
              >
                <Download className="w-4 h-4" />
                <span>Download ARMv7 APK ({RELEASE_INFO.tag})</span>
              </a>
            </div>
          </div>

          {/* Card 3: Tablets, Foldables & Emulators */}
          <div className="p-8 rounded-3xl bg-[#17243A]/60 border border-slate-700/80 flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 rounded-2xl bg-[#3978F6]/15 text-[#3978F6] flex items-center justify-center mb-6">
                <Tablet className="w-8 h-8" />
              </div>
              <h3 className="text-2xl font-bold text-white">Tablets & x86_64</h3>
              <p className="text-xs text-slate-400 font-mono mt-1">x86_64 / Large Screens</p>

              <div className="mt-6 space-y-3 text-xs text-slate-300">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Hardware:</strong> Android tablets, ChromeOS, emulators</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>UI Layout:</strong> Responsive Flutter grid & split-pane adaptivity</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>QR Scanning:</strong> Full-screen high-res CameraX scanner</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Packaging:</strong> x86_64 standalone APK & universal package</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0] shrink-0" />
                  <span><strong>Package Size:</strong> Split ABI: ~27.4 MB / Universal: ~50.6 MB</span>
                </div>
              </div>
            </div>

            <div className="mt-8 pt-6 border-t border-slate-700/60">
              <a
                href={RELEASE_INFO.downloadX86ApkUrl}
                className="w-full flex items-center justify-center gap-2 py-3 text-xs font-semibold text-slate-300 bg-[#0D1420] hover:bg-slate-800 border border-slate-700 rounded-xl transition-all"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Download x86_64 APK</span>
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
