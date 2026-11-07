import React from 'react';
import { Wifi, Cpu, RefreshCw, ShieldOff, QrCode, BatteryCharging, FolderTree, UserCheck } from 'lucide-react';

interface FeatureCard {
  icon: React.ReactNode;
  title: string;
  badge: string;
  description: string;
  techHighlight: string;
}

const FEATURES: FeatureCard[] = [
  {
    icon: <Wifi className="w-6 h-6 text-[#3978F6]" />,
    title: 'Subnet-Directed Peer Discovery',
    badge: 'Hardware MulticastLock',
    description:
      'Discovers nearby devices instantaneously using Android native MulticastLock and directed subnet broadcasts (192.168.x.255). No dropped packets during phone screen sleep.',
    techHighlight: 'UDP Multicast (224.0.0.167:48843) + Direct Subnet Broadcast',
  },
  {
    icon: <Cpu className="w-6 h-6 text-[#39C6B0]" />,
    title: 'Bounded-Memory Streaming',
    badge: 'Fixed 1MB Buffer',
    description:
      'Streams multi-gigabyte files (5GB, 10GB+) with fixed 1MB RAM chunks and receiver backpressure flow control. Never causes memory inflation or Out-Of-Memory (OOM) crashes.',
    techHighlight: 'RAM stays under 30MB during continuous full-speed streaming',
  },
  {
    icon: <RefreshCw className="w-6 h-6 text-[#3978F6]" />,
    title: 'Verified Checkpoint Resumption',
    badge: 'Zero Retransmission',
    description:
      'Interrupted by network disconnects or phone reboots? NEXORA logs every verified chunk in SQLite and resumes streaming from the exact byte without restarting.',
    techHighlight: 'SQLite WAL checkpoint ledger + Chunk-level SHA-256 verification',
  },
  {
    icon: <ShieldOff className="w-6 h-6 text-[#39C6B0]" />,
    title: 'Zero Cloud & Zero Telemetry',
    badge: '100% Private',
    description:
      'No registration, no accounts, no cloud servers, no analytics, and no tracking SDKs. Data travels strictly over your local Wi-Fi, Ethernet, or mobile hotspot.',
    techHighlight: 'Completely localized direct TCP socket transmission',
  },
  {
    icon: <QrCode className="w-6 h-6 text-[#3978F6]" />,
    title: 'Direct IP & QR Pairing Fallback',
    badge: 'AP Isolation Bypass',
    description:
      'On corporate, hotel, or university Wi-Fi networks where routers block peer-to-peer broadcasts, enter the peer IP directly or scan the pairing QR code.',
    techHighlight: 'Bypasses router Client Isolation with direct TCP socket targeting',
  },
  {
    icon: <BatteryCharging className="w-6 h-6 text-[#39C6B0]" />,
    title: 'Android Foreground Service',
    badge: 'Android 14+ Compliant',
    description:
      'Transfers continue seamlessly when you switch apps, answer calls, or lock your phone, powered by an Android native dataSync Foreground Service and WakeLock.',
    techHighlight: 'Persistent notification channel with live progress & transfer speed',
  },
  {
    icon: <FolderTree className="w-6 h-6 text-[#3978F6]" />,
    title: 'Hierarchical Folder Streaming',
    badge: 'PathSanitizer Protected',
    description:
      'Send nested folder hierarchies preserving subdirectories. Built-in security layers sanitize paths against directory traversal attacks (.. and Windows reserved names).',
    techHighlight: 'Multi-file manifest framing + OS path escaping neutralizer',
  },
  {
    icon: <UserCheck className="w-6 h-6 text-[#39C6B0]" />,
    title: 'Explicit Receiver Consent',
    badge: 'Zero Silent Pushing',
    description:
      'Unsolicited files cannot be forced onto your device. Receivers inspect sender identity, file names, count, and size before explicitly confirming.',
    techHighlight: 'TransferOffer & TransferAccept handshake authorization barrier',
  },
];

export const FeatureGrid: React.FC = () => {
  return (
    <section id="features" className="py-24 bg-[#0D1420]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#39C6B0]/10 border border-[#39C6B0]/30 text-[#39C6B0] text-xs font-semibold uppercase tracking-wider mb-4">
            <Cpu className="w-3.5 h-3.5" />
            Core Capabilities
          </div>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white tracking-tight">
            Engineered Without Compromise. <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#3978F6] to-[#39C6B0]">
              Built for Real-World Reliability.
            </span>
          </h2>
          <p className="mt-4 text-base sm:text-lg text-slate-300">
            Every feature in NEXORA is backed by verified code in our open-source Rust and Flutter repositories.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {FEATURES.map((feat, idx) => (
            <div
              key={idx}
              className="p-6 rounded-2xl bg-[#14243B]/40 hover:bg-[#14243B]/80 border border-slate-800 hover:border-slate-700 transition-all hover:-translate-y-1 shadow-lg flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div className="w-12 h-12 rounded-xl bg-[#0D1420] border border-slate-800 flex items-center justify-center">
                    {feat.icon}
                  </div>
                  <span className="text-[10px] font-mono text-[#39C6B0] bg-[#39C6B0]/10 px-2.5 py-0.5 rounded-full border border-[#39C6B0]/20 font-semibold">
                    {feat.badge}
                  </span>
                </div>

                <h3 className="text-white font-bold text-base leading-snug">
                  {feat.title}
                </h3>

                <p className="text-xs text-slate-400 mt-2 leading-relaxed">
                  {feat.description}
                </p>
              </div>

              <div className="mt-5 pt-4 border-t border-slate-800/80">
                <p className="text-[11px] font-mono text-slate-400">
                  <strong className="text-slate-300">Spec:</strong> {feat.techHighlight}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
