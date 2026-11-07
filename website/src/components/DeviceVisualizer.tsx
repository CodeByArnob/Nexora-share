import { useState } from 'react';
import { Smartphone, Laptop, ArrowRightLeft, ShieldCheck, Radio, ServerOff } from 'lucide-react';

export const DeviceVisualizer = () => {
  const [networkMode, setNetworkMode] = useState<'wifi' | 'hotspot' | 'direct'>('wifi');

  return (
    <div className="relative w-full max-w-4xl mx-auto p-6 md:p-8 rounded-3xl bg-[#14243B]/60 border border-slate-700/80 backdrop-blur-xl shadow-2xl shadow-[#3978F6]/10">
      {/* Visualizer Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-6 border-b border-slate-700/60 gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-[#39C6B0] animate-ping" />
            <h4 className="text-white font-bold text-base tracking-wide flex items-center gap-2">
              Interactive P2P Mesh Visualizer
            </h4>
          </div>
          <p className="text-xs text-slate-400 mt-1">
            Real-time representation of NEXORA's UDP Multicast discovery & TCP 1MB bounded streaming.
          </p>
        </div>

        {/* Network Mode Selector */}
        <div className="flex items-center bg-[#0D1420] p-1 rounded-xl border border-slate-800 text-xs font-semibold">
          <button
            onClick={() => setNetworkMode('wifi')}
            className={`px-3 py-1.5 rounded-lg transition-all ${
              networkMode === 'wifi'
                ? 'bg-[#3978F6] text-white shadow'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            Local Wi-Fi
          </button>
          <button
            onClick={() => setNetworkMode('hotspot')}
            className={`px-3 py-1.5 rounded-lg transition-all ${
              networkMode === 'hotspot'
                ? 'bg-[#3978F6] text-white shadow'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            Mobile Hotspot
          </button>
          <button
            onClick={() => setNetworkMode('direct')}
            className={`px-3 py-1.5 rounded-lg transition-all ${
              networkMode === 'direct'
                ? 'bg-[#3978F6] text-white shadow'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            Direct IP
          </button>
        </div>
      </div>

      {/* Interactive Simulation Graphic */}
      <div className="relative py-12 px-4 flex flex-col md:flex-row items-center justify-between gap-8 md:gap-4 overflow-hidden">
        {/* Device 1: Sender (Phone) */}
        <div className="relative flex flex-col items-center text-center z-10">
          <div className="relative">
            {/* Animated Discovery Radar Wave */}
            <div className="absolute inset-0 rounded-2xl bg-[#3978F6]/30 animate-radar-pulse pointer-events-none" />
            <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-[#17243A] to-[#0D1420] border-2 border-[#3978F6] flex items-center justify-center shadow-xl shadow-[#3978F6]/20 relative z-10">
              <Smartphone className="w-10 h-10 text-[#3978F6]" />
            </div>
          </div>
          <span className="text-white font-bold text-sm mt-3">Realme RMX3085</span>
          <span className="text-[11px] font-mono text-[#39C6B0] mt-0.5">
            {networkMode === 'hotspot' ? '192.168.43.1' : '192.168.1.105'}:48842
          </span>
          <span className="text-[10px] text-slate-400 mt-1 bg-slate-800/80 px-2 py-0.5 rounded-full border border-slate-700">
            Sender (Active)
          </span>
        </div>

        {/* Central Data Stream & Zero-Cloud Badge */}
        <div className="flex-1 w-full max-w-xs flex flex-col items-center justify-center px-2 z-10">
          <div className="flex items-center gap-2 text-xs font-mono text-slate-300 bg-[#0D1420]/90 px-3 py-1.5 rounded-full border border-slate-700 shadow-md">
            <ServerOff className="w-4 h-4 text-[#39C6B0]" />
            <span>0% Cloud • 100% Direct P2P</span>
          </div>

          {/* Animated Flow Line */}
          <div className="relative w-full my-4 flex items-center justify-center">
            <div className="h-0.5 w-full bg-gradient-to-r from-[#3978F6] via-[#39C6B0] to-[#3978F6] rounded-full relative overflow-hidden">
              <div className="absolute inset-0 bg-white/60 w-12 animate-[marquee_2s_linear_infinite]" />
            </div>
            <div className="absolute bg-[#14243B] p-2 rounded-full border border-[#39C6B0] text-[#39C6B0] shadow-md">
              <ArrowRightLeft className="w-4 h-4" />
            </div>
          </div>

          <div className="flex items-center gap-3 text-[11px] font-mono text-slate-400">
            <span className="flex items-center gap-1 text-[#3978F6]">
              <Radio className="w-3.5 h-3.5" />
              UDP: 48843
            </span>
            <span>•</span>
            <span className="flex items-center gap-1 text-[#39C6B0]">
              <ShieldCheck className="w-3.5 h-3.5" />
              SHA-256 Verified
            </span>
          </div>
        </div>

        {/* Device 2: Receiver (Phone / Desktop) */}
        <div className="relative flex flex-col items-center text-center z-10">
          <div className="relative">
            <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-[#17243A] to-[#0D1420] border-2 border-[#39C6B0] flex items-center justify-center shadow-xl shadow-[#39C6B0]/20 relative z-10">
              <Laptop className="w-10 h-10 text-[#39C6B0]" />
            </div>
          </div>
          <span className="text-white font-bold text-sm mt-3">Pixel 9 / Workstation</span>
          <span className="text-[11px] font-mono text-[#39C6B0] mt-0.5">
            {networkMode === 'hotspot' ? '192.168.43.142' : '192.168.1.188'}:48842
          </span>
          <span className="text-[10px] text-slate-400 mt-1 bg-slate-800/80 px-2 py-0.5 rounded-full border border-slate-700">
            Receiver (Approved)
          </span>
        </div>
      </div>

      {/* Visualizer Metrics Strip */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-6 border-t border-slate-700/60 text-center">
        <div className="bg-[#0D1420]/60 p-3 rounded-xl border border-slate-800">
          <span className="text-[10px] uppercase font-mono text-slate-400 block">Discovery Protocol</span>
          <span className="text-xs font-bold text-white mt-1 block">Multicast + Subnet</span>
        </div>
        <div className="bg-[#0D1420]/60 p-3 rounded-xl border border-slate-800">
          <span className="text-[10px] uppercase font-mono text-slate-400 block">Streaming Buffer</span>
          <span className="text-xs font-bold text-[#39C6B0] mt-1 block">1 MB Bounded RAM</span>
        </div>
        <div className="bg-[#0D1420]/60 p-3 rounded-xl border border-slate-800">
          <span className="text-[10px] uppercase font-mono text-slate-400 block">Background State</span>
          <span className="text-xs font-bold text-[#3978F6] mt-1 block">Foreground Service</span>
        </div>
        <div className="bg-[#0D1420]/60 p-3 rounded-xl border border-slate-800">
          <span className="text-[10px] uppercase font-mono text-slate-400 block">Integrity Engine</span>
          <span className="text-xs font-bold text-white mt-1 block">SHA-256 Checkpoints</span>
        </div>
      </div>
    </div>
  );
};
