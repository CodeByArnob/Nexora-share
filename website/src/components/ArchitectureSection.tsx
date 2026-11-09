import React, { useState } from 'react';
import { Layers, ShieldCheck, RefreshCw, Cpu, Database, Network } from 'lucide-react';

export const ArchitectureSection: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'stack' | 'framing' | 'resume'>('stack');

  return (
    <section id="architecture" className="py-24 bg-[#0D1420] border-t border-slate-800/80">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#39C6B0]/10 border border-[#39C6B0]/30 text-[#39C6B0] text-xs font-semibold uppercase tracking-wider mb-4">
            <Cpu className="w-3.5 h-3.5" />
            Engineering & Protocols
          </div>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white tracking-tight">
            Built for Scalability. <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#3978F6] to-[#39C6B0]">
              Engineered with Rust & Flutter.
            </span>
          </h2>
          <p className="mt-4 text-base sm:text-lg text-slate-300">
            Clean Architecture and SOLID principles govern every layer from zero-copy network frames to reactive Riverpod UI bindings.
          </p>
        </div>

        {/* Interactive Architecture Tabs */}
        <div className="flex justify-center mb-10">
          <div className="inline-flex p-1.5 rounded-2xl bg-[#14243B] border border-slate-700/80">
            <button
              onClick={() => setActiveTab('stack')}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all ${
                activeTab === 'stack'
                  ? 'bg-[#3978F6] text-white shadow-lg'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <Layers className="w-4 h-4" />
              <span>Full-Stack Architecture</span>
            </button>
            <button
              onClick={() => setActiveTab('framing')}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all ${
                activeTab === 'framing'
                  ? 'bg-[#3978F6] text-white shadow-lg'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <Network className="w-4 h-4" />
              <span>Wire Protocol & Framing</span>
            </button>
            <button
              onClick={() => setActiveTab('resume')}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all ${
                activeTab === 'resume'
                  ? 'bg-[#3978F6] text-white shadow-lg'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <RefreshCw className="w-4 h-4" />
              <span>Verified Checkpoint Resumption</span>
            </button>
          </div>
        </div>

        {/* Tab 1: Full-Stack Architecture */}
        {activeTab === 'stack' && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="p-6 rounded-2xl bg-[#17243A]/80 border border-slate-700">
              <div className="w-12 h-12 rounded-xl bg-[#3978F6]/15 text-[#3978F6] flex items-center justify-center mb-4">
                <Layers className="w-6 h-6" />
              </div>
              <h3 className="text-white font-bold text-lg">Presentation Layer</h3>
              <p className="text-xs text-[#39C6B0] font-mono mt-1">Flutter Material 3 & Riverpod</p>
              <p className="text-sm text-slate-300 mt-3 leading-relaxed">
                Modern declarative UI engineered specifically for Android devices. Reactive state management with zero UI thread blockages during heavy disk streaming.
              </p>
              <ul className="mt-4 space-y-2 text-xs text-slate-400 font-mono">
                <li>• GoRouter navigation shell</li>
                <li>• 60/120 FPS Impeller Vulkan backend</li>
                <li>• Accessible reduced-motion mode</li>
              </ul>
            </div>

            <div className="p-6 rounded-2xl bg-[#17243A]/80 border border-slate-700">
              <div className="w-12 h-12 rounded-xl bg-[#39C6B0]/15 text-[#39C6B0] flex items-center justify-center mb-4">
                <Cpu className="w-6 h-6" />
              </div>
              <h3 className="text-white font-bold text-lg">Core Engine Layer</h3>
              <p className="text-xs text-[#3978F6] font-mono mt-1">Rust Zero-Copy Networking</p>
              <p className="text-sm text-slate-300 mt-3 leading-relaxed">
                High-performance async Tokio runtime handling framed binary streams, bounded chunk slicing, and hardware-accelerated Ed25519 cryptography.
              </p>
              <ul className="mt-4 space-y-2 text-xs text-slate-400 font-mono">
                <li>• 1MB bounded chunk streaming</li>
                <li>• Automatic flow-control backpressure</li>
                <li>• PathSanitizer directory defenses</li>
              </ul>
            </div>

            <div className="p-6 rounded-2xl bg-[#17243A]/80 border border-slate-700">
              <div className="w-12 h-12 rounded-xl bg-[#3978F6]/15 text-[#3978F6] flex items-center justify-center mb-4">
                <Database className="w-6 h-6" />
              </div>
              <h3 className="text-white font-bold text-lg">Persistence Layer</h3>
              <p className="text-xs text-[#39C6B0] font-mono mt-1">Local SQLite Database</p>
              <p className="text-sm text-slate-300 mt-3 leading-relaxed">
                Versioned schema migrations managing transfer history, trusted public-key fingerprints, and chunk checkpoints on-device without remote calls.
              </p>
              <ul className="mt-4 space-y-2 text-xs text-slate-400 font-mono">
                <li>• Zero telemetry and zero cloud storage</li>
                <li>• User-revocable trusted devices</li>
                <li>• Crash-resilient SQLite WAL journaling</li>
              </ul>
            </div>
          </div>
        )}

        {/* Tab 2: Wire Protocol & Framing */}
        {activeTab === 'framing' && (
          <div className="p-8 rounded-3xl bg-[#14243B]/60 border border-slate-700/80">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
              <div className="lg:col-span-5 space-y-4">
                <h3 className="text-2xl font-extrabold text-white">4-Byte Big-Endian Framing</h3>
                <p className="text-sm text-slate-300 leading-relaxed">
                  Every message and stream chunk is framed with a standard 4-byte big-endian length prefix. To protect against malicious memory allocation attacks, NEXORA enforces a strict 5MB frame ceiling, instantly dropping any socket that transmits an oversized header.
                </p>
                <div className="space-y-2 text-xs text-slate-400 font-mono">
                  <div className="p-3 bg-[#0D1420] rounded-xl border border-slate-800">
                    <span className="text-[#3978F6] font-bold">Length Prefix:</span> 4 Bytes (Uint32 Big-Endian)
                  </div>
                  <div className="p-3 bg-[#0D1420] rounded-xl border border-slate-800">
                    <span className="text-[#39C6B0] font-bold">Payload:</span> JSON Control Frames or Binary Chunk
                  </div>
                  <div className="p-3 bg-[#0D1420] rounded-xl border border-slate-800">
                    <span className="text-rose-400 font-bold">Hard Ceiling:</span> 5 MB max frame size
                  </div>
                </div>
              </div>

              <div className="lg:col-span-7 bg-[#0D1420] p-6 rounded-2xl border border-slate-800 font-mono text-xs overflow-x-auto">
                <div className="text-slate-500 mb-2">// Wire Protocol Frame Layout</div>
                <div className="flex border border-slate-700 rounded-lg overflow-hidden text-center text-[11px] mb-4">
                  <div className="w-32 bg-[#3978F6]/20 border-r border-slate-700 p-2 text-[#3978F6] font-bold">
                    [0..4] Length
                  </div>
                  <div className="flex-1 bg-[#39C6B0]/15 p-2 text-[#39C6B0] font-bold">
                    [4..4+N] JSON / Binary Chunk Payload
                  </div>
                </div>

                <div className="text-slate-400 space-y-1">
                  <p className="text-[#3978F6]">// Handshake Sequence:</p>
                  <p>1. Hello(protocol_version, device_id, fingerprint)</p>
                  <p>2. TransferOffer(transfer_id, total_bytes, manifest)</p>
                  <p>3. TransferAccept / TransferReject (Receiver explicit consent)</p>
                  <p>4. ChunkStream(index, offset, size, sha256_hash)</p>
                  <p>5. TransferComplete(verified_hash)</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Tab 3: Verified Checkpoint Resumption */}
        {activeTab === 'resume' && (
          <div className="p-8 rounded-3xl bg-[#14243B]/60 border border-slate-700/80">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
              <div className="lg:col-span-6 space-y-4">
                <h3 className="text-2xl font-extrabold text-white">Resilience Against Drops</h3>
                <p className="text-sm text-slate-300 leading-relaxed">
                  When transferring a 10GB file over Wi-Fi, a brief signal drop should not force you to restart from 0%. NEXORA's verified resume engine tracks every verified 1MB chunk in SQLite.
                </p>
                <div className="space-y-3 pt-2">
                  <div className="flex items-start gap-3">
                    <ShieldCheck className="w-5 h-5 text-[#39C6B0] shrink-0 mt-0.5" />
                    <p className="text-xs text-slate-300">
                      <strong className="text-white">Chunk-Level SHA-256:</strong> Each chunk is verified immediately before being committed to disk.
                    </p>
                  </div>
                  <div className="flex items-start gap-3">
                    <ShieldCheck className="w-5 h-5 text-[#39C6B0] shrink-0 mt-0.5" />
                    <p className="text-xs text-slate-300">
                      <strong className="text-white">Persistent Checkpoints:</strong> State survives unexpected app closures, reboots, and network switching.
                    </p>
                  </div>
                  <div className="flex items-start gap-3">
                    <ShieldCheck className="w-5 h-5 text-[#39C6B0] shrink-0 mt-0.5" />
                    <p className="text-xs text-slate-300">
                      <strong className="text-white">Zero Re-transmission:</strong> Receiver signals highest verified offset; sender begins streaming from that exact byte.
                    </p>
                  </div>
                </div>
              </div>

              <div className="lg:col-span-6 bg-[#0D1420] p-6 rounded-2xl border border-slate-800 font-mono text-xs">
                <div className="text-slate-500 mb-3">// SQLite Checkpoint Schema</div>
                <div className="p-4 bg-[#14243B]/50 rounded-xl border border-slate-700/70 text-slate-300 space-y-1">
                  <p><span className="text-[#3978F6]">CREATE TABLE</span> resume_chunks (</p>
                  <p className="pl-4">transfer_id <span className="text-[#39C6B0]">TEXT</span>,</p>
                  <p className="pl-4">file_id <span className="text-[#39C6B0]">TEXT</span>,</p>
                  <p className="pl-4">chunk_index <span className="text-[#39C6B0]">INTEGER</span>,</p>
                  <p className="pl-4">chunk_offset <span className="text-[#39C6B0]">INTEGER</span>,</p>
                  <p className="pl-4">chunk_size <span className="text-[#39C6B0]">INTEGER</span>,</p>
                  <p className="pl-4">chunk_sha256 <span className="text-[#39C6B0]">TEXT</span>,</p>
                  <p className="pl-4">verified_at <span className="text-[#39C6B0]">TEXT</span>,</p>
                  <p className="pl-4"><span className="text-[#3978F6]">PRIMARY KEY</span> (transfer_id, file_id, chunk_index)</p>
                  <p>);</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </section>
  );
};
