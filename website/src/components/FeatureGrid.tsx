import React from 'react';
import {
  Wifi,
  Zap,
  Lock,
  RefreshCw,
  ShieldOff,
  QrCode,
  BatteryCharging,
  FolderTree,
  UserCheck,
} from 'lucide-react';

interface FeatureItem {
  icon: React.ReactNode;
  title: string;
  badge: string;
  description: string;
  techHighlight: string;
}

const FEATURES: FeatureItem[] = [
  {
    icon: <Wifi className="w-6 h-6 text-[#3978F6]" />,
    title: 'Instant Local Discovery',
    badge: 'Zero Configuration',
    description:
      'Devices running NEXORA on the same network discover each other within milliseconds using UDP multicast broadcasts on port 48843 with native WifiManager MulticastLock.',
    techHighlight: '224.0.0.167 Multicast + Android MulticastLock preservation',
  },
  {
    icon: <Zap className="w-6 h-6 text-[#39C6B0]" />,
    title: 'Gigabit-Speed Streaming',
    badge: 'Raw TCP Throughput',
    description:
      'Transfer files at the maximum physical speed of your Wi-Fi router or hotspot (50+ MB/s on 5GHz 802.11ac/ax) with zero cloud throttles, compression loss, or intermediary proxies.',
    techHighlight: 'Asynchronous buffered I/O with 1MB bounded RAM chunking',
  },
  {
    icon: <Lock className="w-6 h-6 text-[#3978F6]" />,
    title: 'Cryptographic Security',
    badge: 'Ed25519 & SHA-256',
    description:
      'Every device generates a unique Ed25519 keypair. Public key fingerprints verify device identities, while per-chunk SHA-256 checksums prevent corrupted or modified payloads.',
    techHighlight: 'Hardware-backed Ed25519 identity keys + chunk checksums',
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
      'Send nested folder hierarchies preserving subdirectories. Built-in security layers sanitize paths against directory traversal attacks (.. and reserved filenames).',
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
            <Wifi className="w-3.5 h-3.5" />
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

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
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

              <div className="mt-5 pt-3 border-t border-slate-800/80">
                <span className="text-[10px] font-mono text-slate-500 block uppercase font-semibold">Engineering Layer</span>
                <span className="text-xs font-mono text-[#3978F6] font-medium">{feat.techHighlight}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
