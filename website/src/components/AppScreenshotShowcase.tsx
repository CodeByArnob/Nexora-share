import React from 'react';
import { Smartphone, Shield, Wifi, Zap, CheckCircle2 } from 'lucide-react';

export const AppScreenshotShowcase: React.FC = () => {
  return (
    <section className="py-20 relative overflow-hidden bg-gradient-to-b from-[#0D1420] via-[#14243B]/40 to-[#0D1420]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#3978F6]/10 border border-[#3978F6]/30 text-[#3978F6] text-xs font-semibold uppercase tracking-wider mb-4">
            <Smartphone className="w-3.5 h-3.5" />
            Verified Production Interface
          </div>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white tracking-tight">
            Designed for Simplicity. <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#3978F6] to-[#39C6B0]">
              Engineered for Precision.
            </span>
          </h2>
          <p className="mt-4 text-base sm:text-lg text-slate-300">
            A real capture of NEXORA running on physical hardware. No mockups, no false promises—pure peer-to-peer performance with modern Material 3 design.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          {/* Left Feature Callouts */}
          <div className="lg:col-span-4 space-y-6 order-2 lg:order-1">
            <div className="p-5 rounded-2xl bg-[#17243A]/80 border border-slate-700/70 hover:border-[#3978F6] transition-all hover:translate-x-1 shadow-lg">
              <div className="w-10 h-10 rounded-xl bg-[#3978F6]/15 text-[#3978F6] flex items-center justify-center mb-3">
                <Wifi className="w-5 h-5" />
              </div>
              <h3 className="text-white font-bold text-base">Instant Local Discovery</h3>
              <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                Uses Android <code className="text-slate-300">MulticastLock</code> and subnet-directed broadcasts (<code className="text-slate-300">192.168.x.255</code>) to eliminate sleep drops and discover peers under 100ms.
              </p>
            </div>

            <div className="p-5 rounded-2xl bg-[#17243A]/80 border border-slate-700/70 hover:border-[#39C6B0] transition-all hover:translate-x-1 shadow-lg">
              <div className="w-10 h-10 rounded-xl bg-[#39C6B0]/15 text-[#39C6B0] flex items-center justify-center mb-3">
                <Shield className="w-5 h-5" />
              </div>
              <h3 className="text-white font-bold text-base">Explicit Receiver Consent</h3>
              <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                Senders cannot push files without your permission. Receivers inspect file count, manifest, and byte weight before approving.
              </p>
            </div>

            <div className="p-5 rounded-2xl bg-[#17243A]/80 border border-slate-700/70 hover:border-[#3978F6] transition-all hover:translate-x-1 shadow-lg">
              <div className="w-10 h-10 rounded-xl bg-[#3978F6]/15 text-[#3978F6] flex items-center justify-center mb-3">
                <Zap className="w-5 h-5" />
              </div>
              <h3 className="text-white font-bold text-base">Direct IP & AP Isolation Bypass</h3>
              <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
                On university, office, or hotel Wi-Fi networks where routers block broadcast, tap "Add IP" or scan the QR code to pair directly over TCP.
              </p>
            </div>
          </div>

          {/* Central Real Phone Mockup */}
          <div className="lg:col-span-4 flex justify-center order-1 lg:order-2">
            <div className="relative w-72 sm:w-80 rounded-[44px] p-3 bg-gradient-to-b from-slate-700 via-slate-800 to-slate-900 shadow-2xl shadow-[#3978F6]/20 border-4 border-slate-600/50">
              {/* Phone Speaker & Camera Notch */}
              <div className="absolute top-6 left-1/2 -translate-x-1/2 w-24 h-4 bg-black rounded-full z-20 flex items-center justify-end px-3">
                <div className="w-2.5 h-2.5 rounded-full bg-slate-900 border border-slate-800" />
              </div>

              {/* Real Screen Capture */}
              <div className="relative w-full rounded-[34px] overflow-hidden bg-[#0D1420] border border-slate-800 aspect-[9/19.5]">
                <img
                  src="/Nexora-share/app_home_screenshot.jpg"
                  alt="NEXORA Android Mobile Application Live Screen"
                  className="w-full h-full object-cover object-top"
                  loading="lazy"
                />
              </div>

              {/* Reflection Highlight */}
              <div className="absolute inset-0 rounded-[44px] bg-gradient-to-tr from-transparent via-white/5 to-transparent pointer-events-none" />
            </div>
          </div>

          {/* Right Highlights & Technical Truths */}
          <div className="lg:col-span-4 space-y-6 order-3">
            <div className="p-6 rounded-2xl bg-gradient-to-br from-[#14243B] to-[#17243A] border border-slate-700 shadow-lg">
              <h4 className="text-xs font-mono uppercase tracking-widest text-[#39C6B0] mb-2 font-bold">
                Hardware Truth
              </h4>
              <p className="text-white font-bold text-lg leading-snug">
                Verified on Real Devices
              </p>
              <p className="text-xs text-slate-300 mt-2 leading-relaxed">
                Tested and verified on physical Android hardware (Realme RMX3085, Android 13/14) with Flutter Impeller Vulkan engine and Rust zero-copy backend.
              </p>

              <div className="mt-4 pt-4 border-t border-slate-700/60 space-y-2 text-xs font-medium text-slate-300">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0]" />
                  <span>APK Size: Exactly 54.4 MB (Universal)</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0]" />
                  <span>Bounded RAM: Under 30MB during streaming</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#39C6B0]" />
                  <span>Foreground Service: Background active</span>
                </div>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-[#0D1420] border border-slate-800">
              <h4 className="text-xs font-mono uppercase tracking-widest text-[#3978F6] mb-2 font-bold">
                No Cloud Dependency
              </h4>
              <p className="text-sm text-slate-300 leading-relaxed">
                NEXORA works completely offline in forests, airplanes, classrooms, or disconnected field environments. All you need is an active Wi-Fi access point or phone hotspot.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
